
DECLARE
  -- Parametrico: scegli quante righe totali generare
  c_year_from     CONSTANT PLS_INTEGER := 2021;
  c_year_to       CONSTANT PLS_INTEGER := 2024;              -- incluso
  c_months_total  CONSTANT PLS_INTEGER := (c_year_to - c_year_from + 1) * 12;
  c_total_rows    CONSTANT PLS_INTEGER := 200000;            -- ⟵ cambia (es. 1_000_000)
  c_base_per_mon  CONSTANT PLS_INTEGER := FLOOR(c_total_rows / c_months_total);
  c_remainder     CONSTANT PLS_INTEGER := c_total_rows - c_base_per_mon*c_months_total;

  c_product       CONSTANT VARCHAR2(50) := 'PROD_POC';
  c_commit_every  CONSTANT PLS_INTEGER := 20000;

  c_base          CONSTANT NUMBER := 320;    -- livello base
  c_trend_yoy     CONSTANT NUMBER := 1.05;   -- +5%/anno

  TYPE t_row IS RECORD (
    product   VARCHAR2(50),
    year_val  PLS_INTEGER,
    month_val PLS_INTEGER,
    units     NUMBER
  );
  TYPE t_tab IS TABLE OF t_row;
  v_rows t_tab := t_tab();

  v_month_idx PLS_INTEGER := 0;
  v_units     NUMBER;

  FUNCTION seasonal_factor(p_month PLS_INTEGER) RETURN NUMBER IS
    v_step NUMBER;
    v_sine NUMBER;
  BEGIN
    v_step :=
      CASE p_month
        WHEN 12 THEN 0.75
        WHEN  1 THEN 0.75
        WHEN  2 THEN 0.80
        WHEN  3 THEN 0.90
        WHEN  4 THEN 0.95
        WHEN  5 THEN 1.05
        WHEN  6 THEN 1.25
        WHEN  7 THEN 1.30
        WHEN  8 THEN 1.20
        WHEN  9 THEN 1.05
        WHEN 10 THEN 0.95
        WHEN 11 THEN 0.85
      END;
    v_sine := 1 + 0.08 * SIN(2*ACOS(-1) * p_month/12);
    RETURN v_step * v_sine;
  END;

  FUNCTION clamp(p NUMBER, pmin NUMBER, pmax NUMBER) RETURN NUMBER IS
  BEGIN
    IF p < pmin THEN RETURN pmin; END IF;
    IF p > pmax THEN RETURN pmax; END IF;
    RETURN p;
  END;
BEGIN
  DBMS_RANDOM.SEED(42);

  FOR y IN c_year_from .. c_year_to LOOP
    FOR m IN 1 .. 12 LOOP
      v_month_idx := v_month_idx + 1;

      DECLARE
        v_rows_this_month PLS_INTEGER :=
          c_base_per_mon + CASE WHEN v_month_idx <= c_remainder THEN 1 ELSE 0 END;
      BEGIN
        FOR i IN 1 .. v_rows_this_month LOOP
          v_units :=
            c_base
            * seasonal_factor(m)
            * POWER(c_trend_yoy, y - c_year_from)
            + DBMS_RANDOM.NORMAL * 30;

          v_units := ROUND(clamp(v_units, 0, 1e9), 2);

          v_rows.EXTEND;
          v_rows(v_rows.LAST).product   := c_product;
          v_rows(v_rows.LAST).year_val  := y;
          v_rows(v_rows.LAST).month_val := m;
          v_rows(v_rows.LAST).units     := v_units;

          IF v_rows.COUNT >= c_commit_every THEN
            FORALL idx IN v_rows.FIRST .. v_rows.LAST
              INSERT /*+ APPEND */ INTO POCOML.SALES_RAW
                (product, year_val, month_val, units)
              VALUES
                (v_rows(idx).product, v_rows(idx).year_val, v_rows(idx).month_val, v_rows(idx).units);
            COMMIT;
            v_rows.DELETE;
          END IF;
        END LOOP;
      END;
    END LOOP;
  END LOOP;

  IF v_rows.COUNT > 0 THEN
    FORALL idx IN v_rows.FIRST .. v_rows.LAST
      INSERT /*+ APPEND */ INTO POCOML.SALES_RAW
        (product, year_val, month_val, units)
      VALUES
        (v_rows(idx).product, v_rows(idx).year_val, v_rows(idx).month_val, v_rows(idx).units);
    COMMIT;
    v_rows.DELETE;
  END IF;
END;
/
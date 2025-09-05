
CREATE TABLE POCOML.SALES_MTH AS
SELECT
  product,
  TO_DATE(year_val||LPAD(month_val,2,'0')||'01','YYYYMMDD') AS period_dt,
  SUM(units) AS units_month
FROM POCOML.SALES_RAW
GROUP BY product, year_val, month_val;

CREATE INDEX POCOML.X_SALES_MTH_DT ON POCOML.SALES_MTH(period_dt);

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst(DBMS_DATA_MINING.ALGO_NAME)          := DBMS_DATA_MINING.ALGO_EXPONENTIAL_SMOOTHING;
  v_setlst('EXSM_INTERVAL')                     := 'EXSM_INTERVAL_MONTH';  --  CASE_ID DATE mandatory
  v_setlst('EXSM_SEASONALITY')                  := '12';
  v_setlst('EXSM_PREDICTION_STEP')              := '24'; -- 2 years of prediction
  v_setlst('EXSM_CONFIDENCE_LEVEL')             := TO_CHAR(0.95);
  v_setlst('EXSM_MODEL')                        := 'EXSM_WINTERS';         -- trend add., season mul.

  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name           => 'SALES_ESM',
    mining_function      => DBMS_DATA_MINING.TIME_SERIES,
    data_query           => q'[
      SELECT
        product,
        period_dt,
        units_month
      FROM   POCOML.SALES_MTH
      WHERE  product = 'PROD_POC'
      AND    period_dt BETWEEN DATE '2021-01-01' AND DATE '2023-12-01'
      ORDER  BY period_dt
    ]',
    case_id_column_name  => 'PERIOD_DT',        -- CASE_ID = data
    target_column_name   => 'UNITS_MONTH',      -- target 
    set_list             => v_setlst
  );
END;
/





-- Check Model
SELECT setting_name, setting_value
FROM   USER_MINING_MODEL_SETTINGS
WHERE  model_name = 'SALES_ESM'
ORDER  BY 1;

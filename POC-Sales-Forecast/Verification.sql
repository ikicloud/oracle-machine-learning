
-- Verification query:
WITH preds AS (
  SELECT
    CASE_ID    AS period_dt,
    PREDICTION AS yhat,
    LOWER      AS yhat_lo,
    UPPER      AS yhat_hi
  FROM DM$VPSALES_ESM
  WHERE CASE_ID BETWEEN DATE '2024-01-01' AND DATE '2024-12-01'
),
actual AS (
  SELECT period_dt, units_month AS y
  FROM   POCOML.SALES_MTH
  WHERE  product = 'PROD_POC'
  AND    period_dt BETWEEN DATE '2024-01-01' AND DATE '2024-12-01'
),
mean_y AS (                      -- <-- media calcolata a parte (nessuna window)
  SELECT AVG(y) AS v FROM actual
)
SELECT
  ROUND( SQRT( AVG( POWER(p.yhat - a.y, 2) ) ), 2 )                           AS rmse,
  ROUND( AVG( ABS(p.yhat - a.y) ), 2 )                                        AS mae,
  ROUND( 1 - ( SUM( POWER(p.yhat - a.y, 2) )
            / SUM( POWER(a.y - m.v, 2) ) ), 4 )                               AS r2
FROM preds p
JOIN actual a USING(period_dt)
CROSS JOIN mean_y m;           

      RMSE	  MAE	      R2
---------- ---------- ----------
   7879.13    7487.21	    .999

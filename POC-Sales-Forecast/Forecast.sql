
-- forecast: 

SELECT TO_CHAR(CASE_ID,'YYYY-MM') AS ym,
       ROUND(PREDICTION,2)        AS forecast_units,
       ROUND(LOWER,2)             AS lo_95,
       ROUND(UPPER,2)             AS hi_95
FROM DM$VPSALES_ESM
WHERE CASE_ID BETWEEN DATE '2025-01-01' AND DATE '2025-12-01'
ORDER BY CASE_ID;

--DATA QUALITY CHECK FOR THE SILVER LAYER
--********************************************
--Cheching if there is any Duplicate in the 'prd_id' column of the silver layer
--Excpectation = no result
SELECT 
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Checking umwanted space int hte prd_nm
--Excpectation = no result

SELECT 
prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)
   
--Check if there is NULL or Negative Number in the 'prd_cost' column
--Excpectation = no result
   
SELECT 
prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0

-- Data Standardization and Consistancy check on 'prd_line' column
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Checking for Invalid date order
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt


SELECT *
FROM silver.crm_prd_info

/*
SELECT *, flag_last
FROM (
    SELECT *,
        ROW_NUMBER () OVER (PARTITION BY prd_id ORDER BY prd_start_dt) AS flag_last 
        FROM silver.crm_prd_info
        where prd_id IS NOT NULL
)t WHERE flag_last != 1

*/
-- Checking the second column ''prd_key', need to be splitted int to two
-- it needs SUBSTRING Function
-- REPACE the '-' with '_'

SELECT 
    prd_id
    ,prd_key,
    REPLACE(SUBSTRING(prd_key, 1,5), '-', '_') AS cat_id,
    SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key
    ,prd_nm
    ,ISNULL(prd_cost, 0) AS prd_cos,
    CASE UPPER(TRIM(prd_line))    
        WHEN 'M' THEN 'Mountain' 
        WHEN 'R' THEN 'Road'  
        WHEN 'S' THEN 'Other Sale'  
        WHEN 'T' THEN 'Touring'  
        ELSE 'n/a'
END AS prd_cost
    ,CAST(prd_start_dt AS DATE) AS prd_start_dt
    ,CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info




-- Checking for Invalid date order
SELECT *
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt -- the result imply that all the end date is less tham the begining date
                                   --which is wrong data
                                -- to fix this LEED Window function is used
LEAD(prd_start_date) OVER (PARTITION BY prd_key ORDER BY prd_start_date) - 1 AS prd_end_date_test

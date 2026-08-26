INSERT INTO silver.crm_cust_info (
     cst_id
    ,cst_key
    ,cst_firstname
    ,cst_lastname
    ,cst_marital_status
    ,cst_gndr
    ,cst_create_date)
SELECT  
     cst_id,
     cst_key,
     TRIM(cst_firstname) AS cst_firstname,
     TRIM(cst_lastname) AS cst_lastname,
      
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' 
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END cst_marital_status, --Normalize Marital Statuse values to readable format
     
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Femel' 
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END cst_gndr, --Normalize Gender values to readable format
    cst_create_date
FROM (
    SELECT *,
        ROW_NUMBER () OVER (PARTITION BY cst_id ORDER BY cst_create_date) AS flag_last 
        FROM bronze.crm_cust_info
        where cst_id IS NOT NULL
)t WHERE flag_last = 1

-- Data Cleansing 'crm_sales_details' The Sales table in the bronze layer
INSERT INTO silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,CASE 
            WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)
            END sls_order_dt
      ,CASE 
            WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE)
            END sls_ship_dt
      ,CASE 
            WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE)
            END sls_due_dt
,
       CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,
               sls_quantity,
    
       CASE WHEN sls_price IS NULL OR sls_price <= 0
           THEN sls_sales / NULLIF(sls_quantity, 0)
           ELSE sls_price
        END AS sls_price
  FROM bronze.crm_sales_details

  --*******************************************************************

--1) Duplica in the key column
--******************************************** SO55367
SELECT 
sls_ord_num,
COUNT(*)
FROM bronze.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1 OR sls_ord_num IS NULL  -- pleanty of reslulted => not good data
                                            -- needs a serious cleansing

SELECT 
sls_prd_key,
COUNT(*)
FROM bronze.crm_sales_details
GROUP BY sls_prd_key
HAVING COUNT(*) > 1 OR sls_prd_key IS NULL

SELECT 
sls_cust_id,
COUNT(*)
FROM bronze.crm_sales_details
GROUP BY sls_cust_id
HAVING COUNT(*) > 1 OR sls_cust_id IS NULL

SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num = 'SO55367'

  --2) Unwanted spaces in the key 'sls_ord_num' column
  SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM bronze.crm_sales_details
  WHERE sls_ord_num != TRIM (sls_ord_num)  -- nothing reslulted => good data

  --3) checking integrity of this table with other two tables in the silver layer
        -- with silver.crm_prd_info
  SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM bronze.crm_sales_details
  WHERE sls_prd_key  NOT IN (SELECT prd_key FROM silver.crm_prd_info) 
          -- with silver.crm_cust_info
  SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM bronze.crm_sales_details
  WHERE sls_cust_id  NOT IN (SELECT cst_id FROM silver.crm_cst_info) 

  --4) checking the dates
        -- these dates in the bronze layer are seen to look integers, so needs to be changed int date 
SELECT sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 -- SINCE THERE ARE MANY O VALUES, NEED TO BE REPLCASE BY null


--==>>
SELECT 
NULLIF (sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0


-- The length of these date values must be 8

SELECT NULLIF (sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
       OR LEN(sls_order_dt) != 8
       OR sls_order_dt > 20500101
       OR sls_order_dt < 19000101

-- same way - check validity of the 'sls_ship_dt' 
SELECT NULLIF (sls_ship_dt, 0) AS sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101


-- same way - check validity of the 'sls_due_dt' 
SELECT NULLIF (sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101

-- sls_order_dt SHOULD ALWAYS BE EARLIER THAN sls_ship_dt OR sls_due_dt
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

--5) Check data consistency: Between Sales, Quantity and Price
    -->> Sales = Quantity * Price
    -->> Value must not be NULL, ZERO OR NEGATIVE

  SELECT    
       sls_sales AS old_sls_sales
      ,sls_price AS old_sls_price
      ,sls_quantity,
       CASE WHEN sls_sales IS NULL OR sls_sales < = 0 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,
    
      CASE WHEN sls_price IS NULL OR sls_price <= 0
           THEN sls_sales / NULLIF(sls_quantity, 0)
           ELSE sls_price
        END AS sls_price

  FROM bronze.crm_sales_details
  WHERE sls_sales !=  sls_quantity * sls_price
  OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
  OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
  ORDER BY  sls_sales ,sls_quantity ,sls_price

  /*--This check is resulting in plenty of bad data
  to do the transformation, follow the very rull that says:
  1) if sale is negative, zero or null, derive it using quantity and price
  2) if price is zero or null, calculate it using qantty and sales
  3) if price is negative, convert it to a positive value*/

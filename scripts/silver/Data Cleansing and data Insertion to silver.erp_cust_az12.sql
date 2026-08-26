INSERT INTO silver.erp_cust_az12 (	
		cid,
		bdate,
		gen
		)
SELECT 
CASE WHEN cid LIKE 'NAS%' 
	 THEN SUBSTRING (cid, 4, LEN(cid))
ELSE cid
END cid,
CASE WHEN bdate > GETDATE()  THEN NULL
	ELSE bdate
	END bdate,
CASE WHEN gen = '' or gen IS NULL THEN 'n/a'
	 WHEN UPPER(TRIM(gen)) IN ('F',  'FEMALE') THEN 'Femail'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Mail'
	 ELSE 'n/a'
END gen
FROM bronze.erp_cust_az12
/*---------------------------------------------------------*/
/*---------------------------------------------------------*/
/*---------------------------------------------------------*/
/* DDDDDDATA QUALITY CHECK IN THE silver LAYER
1) Identiry out or range dates*/
SELECT 
bdate
FROM silver.erp_cust_az12 
WHERE bdate > GETDATE() OR bdate < '1926-01-01'

/*2) Data Standardization and Consstancy*/
SELECT DISTINCT
gen
FROM silver.erp_cust_az12 
-- 3)TO SEE HOW THE OVERALL DATA LOOKS
SELECT DISTINCT
*
FROM silver.erp_cust_az12  
/*---------------------------------------------------------*/
/*---------------------------------------------------------*/
/*---------------------------------------------------------*/


/*
/*In this table erp_cust_ax12, will do the data transformation:
check first the integrity with other tables like 'silcer.crm_cust_info'
*/
SELECT 
cid,
CASE WHEN cid LIKE 'NAS%' 
	 THEN SUBSTRING (cid, 4, LEN(cid))
ELSE cid
END cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' 
	 THEN SUBSTRING (cid, 4, LEN(cid))
ELSE cid
END NOT IN (SELECT cst_key FROM silver.crm_cust_info)

/*next we cleanse the bdate colunm
in here we check customers with 100 and above years of age and also
whose birth day is latest than today 
*/
SELECT 
bdate
FROM bronze.erp_cust_az12
WHERE bdate >= '1926-01-01' OR bdate > GETDATE()  --With birth date like today/this current year - showing bad data

SELECT 
bdate
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE()  /*hence needs to exclude those whose birthday is later than today - impossible
							THE RIGHT TRANSFORMATION WILL BE:
							*/
SELECT 
bdate,
CASE WHEN bdate > GETDATE()  THEN NULL
	ELSE bdate
	END bdate
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE()

SELECT 
bdate
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE()
/* In cleansing the geb colunm 
we will do DATA NOTMALIZATION AND STANDARDIZATION*/

SELECT DISTINCT
gen
FROM bronze.erp_cust_az12  -->> Shows there are 6 distict values 

SELECT DISTINCT
gen,
CASE WHEN gen = '' or gen IS NULL THEN 'n/a'
	 WHEN UPPER(TRIM(gen)) IN ('F',  'FEMALE') THEN 'Femail'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Mail'
	 ELSE gen
END gen
FROM bronze.erp_cust_az12

*/

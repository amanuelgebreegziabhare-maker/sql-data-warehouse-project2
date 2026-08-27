CREATE VIEW gold.dim_customers AS
SELECT 
ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
ci.cst_id AS customer_id, 
ci.cst_key AS customer_number, 
ci.cst_firstname AS first_name, 
ci.cst_lastname AS last_name, 
la.cntry AS  country,
ci.cst_marital_status AS marital_status, 
CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- crm is the master for the gender information
	ELSE COALESCE(ca.gen, 'n/a')
END AS gender,
ca.bdate AS birthdate,
ci.cst_create_date AS create_date 

FROM silver.crm_cust_info AS ci

LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid


-->>---------------------------------------------------------------
SELECT*
FROM silver.erp_cust_az12
SELECT*
FROM silver.erp_loc_a101
-->>-------------------------------------------------------------<<--
-->>-------------------------------------------------------------<<--
-->>----------------data validity quick checks ------------------<<--
-->>-------------------------------------------------------------<<--
-->>-------------------------------------------------------------<<--
/*
After getting the right data from the tables via LEFT JOIN, 
a quick check for duplicates is achieved through the following: 
*/
SELECT cst_id, COUNT(*)
FROM(
	SELECT 
	ci.cst_id, 
	ci.cst_key, 
	ci.cst_firstname, 
	ci.cst_lastname, 
	ci.cst_marital_status, 
	ci.cst_gndr, 
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
	FROM silver.crm_cust_info AS ci

	LEFT JOIN silver.erp_cust_az12 AS ca
	ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 AS la
	ON ci.cst_key = la.cid
	)t 
GROUP BY cst_id
HAVING COUNT(*) > 1

/*
the other thing to check is:
there are two column sources that deal with gender
	*	ci.cst_gndr -> from - silver.crm_cust_info and
	*    ca.gen -> FROM -> silver.erp_cust_az12 joing with LEFT JOIN

TO check if the information obtaind via these two tables are same or not:
*/

SELECT DISTINCT
ci.cst_gndr,	
ca.gen,
CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- crm is the master for the gender information
	ELSE COALESCE(ca.gen, 'n/a')
END AS new_gen
	
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON ci.cst_key = la.cid
ORDER BY ci.cst_gndr, ca.gen

*/******************************************************************/
 /* 
 to chek validity of the Customer View in the Gold Layer
 */
 SELECT *
FROM gold.dim_customers

--CHECK DISTINCT of the gender column
SELECT DISTINCT gender
FROM gold.dim_customers

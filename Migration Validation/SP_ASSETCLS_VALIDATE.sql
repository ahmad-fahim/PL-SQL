CREATE OR REPLACE PROCEDURE SP_ASSETCLS_VALIDATE(P_BRANCH_CODE IN NUMBER,
                                              P_START_DATE  IN DATE) IS

  W_ROWCOUNT NUMBER := 0;

BEGIN
  DELETE FROM ERRORLOG WHERE TEMPLATE_NAME = 'MIG_ASSETCLS';
  COMMIT;

  -- checking all ASSETCLS_ACNUM exists in MIG_ACNTS loan account   

  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ASSETCLS
   WHERE ASSETCLS_ACNUM NOT IN
         (SELECT ACNTS_ACNUM
            FROM MIG_ACNTS
           WHERE ACNTS_PROD_CODE IN
                 (SELECT PRODUCT_CODE
                    FROM PRODUCTS
                   WHERE PRODUCT_FOR_LOANS = 1));

  IF W_ROWCOUNT > 0 THEN
  
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ASSETCLS',
       'ASSETCLS_ACNUM',
       W_ROWCOUNT,
       'ASSETCLS_ACNUM SHOULD BE EXISTS IN LOAN ACCOUNT OF MIG_ACNTS',
       'SELECT *  FROM MIG_ASSETCLS WHERE (ASSETCLS_ACNUM) NOT IN 
     (SELECT ACNTS_ACNUM FROM MIG_ACNTS WHERE ACNTS_PROD_CODE IN 
     (SELECT PRODUCT_CODE FROM PRODUCTS WHERE PRODUCT_FOR_LOANS = 1));');
  
  END IF;

  --- checking all A/C are in correct ASSETCLSH_ASSET_CODE code

  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ASSETCLS
   WHERE NVL(ASSETCLSH_ASSET_CODE, ' ') NOT IN
         (SELECT ASSETCD_CODE FROM ASSETCD);

  IF W_ROWCOUNT > 0 THEN
  
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ASSETCLS',
       'ASSETCLSH_ASSET_CODE',
       W_ROWCOUNT,
       'ASSETCLSH_ASSET_CODE SHOULD BE IN ASSETCD_CODE FROM ASSETCD',
       'SELECT * FROM MIG_ASSETCLS 
     WHERE NVL(ASSETCLSH_ASSET_CODE, '' '' ) NOT IN (SELECT ASSETCD_CODE FROM ASSETCD);');
  
  END IF;

  --- ASSETCLSH_NPA_DATE null checking for UC loan 

  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ASSETCLS
   WHERE ASSETCLSH_ASSET_CODE IN ('UC', 'SM')
     AND ASSETCLSH_NPA_DATE IS NOT NULL;

  IF W_ROWCOUNT > 0 THEN
  
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ASSETCLS',
       'ASSETCLSH_NPA_DATE',
       W_ROWCOUNT,
       'ASSETCLSH_NPA_DATE SHOULD BE NULL FOR UC LOAN ',
       'SELECT * FROM MIG_ASSETCLS 
     WHERE ASSETCLSH_ASSET_CODE IN( ''UC'',''SM'')  AND ASSETCLSH_NPA_DATE IS NOT NULL;');
  
  END IF;

  --- ASSETCLSH_NPA_DATE null checking for BL loan

  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ASSETCLS
   WHERE ASSETCLSH_ASSET_CODE NOT IN ('UC', 'SM', 'ST')
     AND ASSETCLSH_NPA_DATE IS NULL;

  IF W_ROWCOUNT > 0 THEN
  
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ASSETCLS',
       'ASSETCLSH_NPA_DATE',
       W_ROWCOUNT,
       'ASSETCLSH_NPA_DATE SHOULD NOT BE NULL FOR BL LOAN ',
       'SELECT *  FROM MIG_ASSETCLS WHERE ASSETCLSH_ASSET_CODE 
     NOT IN ( ''UC'',''SM'', ''ST'') AND ASSETCLSH_NPA_DATE IS  NULL;');
  
  END IF;

  --- checking  ASSETCLSH_NPA_DATE is greater than mig date 

  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ASSETCLS
   WHERE ASSETCLSH_NPA_DATE > P_START_DATE;

  IF W_ROWCOUNT > 0 THEN
  
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ASSETCLS',
       'ASSETCLSH_NPA_DATE',
       W_ROWCOUNT,
       'ASSETCLSH_NPA_DATE SHOULD NOT BE GREATER THAN MIG DATE',
       'SELECT * FROM MIG_ASSETCLS WHERE ASSETCLSH_NPA_DATE > ''' ||
       P_START_DATE || ''' ;');
  
  END IF;
  
  
---  checking if ASSETCLS_EFF_DATE null or greater than mig date


  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ASSETCLS
   WHERE (NVL(ASSETCLS_EFF_DATE, '31-DEC-1899') NOT BETWEEN '01-JAN-1900' AND
         '31-DEC-2050') OR ASSETCLS_EFF_DATE > P_START_DATE;

  IF W_ROWCOUNT > 0 THEN
  
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ASSETCLS',
       'ASSETCLS_EFF_DATE',
       W_ROWCOUNT,
       'ASSETCLS_EFF_DATE SHOULD NOT BE  NULL OR GREATER THAN MIG DATE',
       ' SELECT * FROM MIG_ASSETCLS WHERE (NVL(ASSETCLS_EFF_DATE, '' 31 - DEC - 1899 '') not between ''
       01 - jan - 1900 '' and '' 31 - dec - 2050 '') OR ASSETCLS_EFF_DATE > ''' || P_START_DATE || ''';'
    );
  END IF;

END SP_ASSETCLS_VALIDATE;
/
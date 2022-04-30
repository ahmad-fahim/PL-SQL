CREATE OR REPLACE PROCEDURE SP_LNACNT_VALIDATE (
   P_BRANCH_CODE   IN NUMBER,
   P_START_DATE    IN DATE)
IS
   W_ROWCOUNT   NUMBER := 0;
BEGIN
   DELETE FROM ERRORLOG
         WHERE TEMPLATE_NAME = 'MIG_LNACNT';

   COMMIT;

   UPDATE MIG_LNACNT
      SET LNACNT_LIMIT_CURR_DISB_MADE = NVL (LNACNT_LIMIT_CURR_DISB_MADE, 0),
          LNACNT_BSR_ACT_OCC_CODE = NVL (LNACNT_BSR_ACT_OCC_CODE, 0),
          LNACNT_NATURE_BORROWAL_AC = NVL (LNACNT_NATURE_BORROWAL_AC, 0),
          LNACNT_OUTSTANDING_BALANCE = NVL (LNACNT_OUTSTANDING_BALANCE, 0),
          LNACNT_PRIN_OS = NVL (LNACNT_PRIN_OS, 0),
          LNACNT_INT_OS = NVL (LNACNT_INT_OS, 0),
          LNACNT_CHG_OS = NVL (LNACNT_CHG_OS, 0),
          LNACNT_TOT_SUSPENSE_BALANCE = NVL (LNACNT_TOT_SUSPENSE_BALANCE, 0),
          LNACNT_INT_SUSP_BALANCE = NVL (LNACNT_INT_SUSP_BALANCE, 0),
          LNACNT_CHG_SUSP_BALANCE = NVL (LNACNT_CHG_SUSP_BALANCE, 0),
          LNACNT_WRITTEN_OFF_AMT = NVL (LNACNT_WRITTEN_OFF_AMT, 0);

   COMMIT;

   --- branch code checking

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE NVL (LNACNT_BRN_CODE, 0) <> P_BRANCH_CODE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_BRN_CODE',
                     W_ROWCOUNT,
                     'ACNTS_BRN_CODE SHOULD BE ' || P_BRANCH_CODE,
                        'SELECT * FROM MIG_LNACNT  WHERE NVL(LNACNT_BRN_CODE, 0)  <> '
                     || P_BRANCH_CODE);
   END IF;

   ---- account number checking

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE LNACNT_ACNUM NOT IN
             (SELECT ACNTS_ACNUM
                FROM MIG_ACNTS
               WHERE ACNTS_PROD_CODE IN (SELECT PRODUCT_CODE
                                           FROM PRODUCTS
                                          WHERE PRODUCT_FOR_LOANS = 1));

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_LNACNT',
                   'LNACNT_ACNUM',
                   W_ROWCOUNT,
                   'LNACNT_ACNUM NOT FOUND IN MIG_ACNTS',
                   'SELECT *
  FROM MIG_LNACNT ML
 WHERE ML.LNACNT_ACNUM NOT IN
       (SELECT MIG_ACNTS.ACNTS_ACNUM
          FROM MIG_ACNTS
         WHERE MIG_ACNTS.ACNTS_PROD_CODE IN
               (SELECT PRODUCTS.PRODUCT_CODE
                  FROM PRODUCTS
                 WHERE PRODUCTS.PRODUCT_FOR_LOANS = 1));');
   END IF;

   --- client code checking

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE NVL (LNACNT_CLIENT_NUM, 0) NOT IN
             (SELECT CLIENTS_CODE FROM MIG_CLIENTS
              UNION ALL
              SELECT JNTCL_JCL_SL FROM MIG_JOINTCLIENTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_LNACNT',
                   'LNACNT_CLIENT_NUM',
                   W_ROWCOUNT,
                   'LNACNT_CLIENT_NUM NOT FOUND IN MAIN CLIENTS',
                   'SELECT *
  FROM MIG_LNACNT
  WHERE NVL(LNACNT_CLIENT_NUM, 0) NOT IN
        (SELECT CLIENTS_CODE
           FROM MIG_CLIENTS
         UNION ALL
         SELECT JNTCL_JCL_SL
           FROM MIG_JOINTCLIENTS);');
   END IF;

   --- checking all A/C are in correct LNACNT_ASSET_STAT code

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE NVL (LNACNT_ASSET_STAT, ' ') NOT IN
             (SELECT ASSETCD_CODE FROM ASSETCD);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_ASSET_STAT',
                     W_ROWCOUNT,
                     'LNACNT_ASSET_STAT SHOULD BE IN ASSETCD_CODE FROM ASSETCD',
                     'SELECT LNACNT_ACNUM , LNACNT_ASSET_STAT FROM MIG_LNACNT 
     WHERE NVL(LNACNT_ASSET_STAT, '' '' ) NOT IN (SELECT ASSETCD_CODE FROM ASSETCD);');
   END IF;

   --- checking outstanding balance

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE LNACNT_OUTSTANDING_BALANCE <>
             LNACNT_PRIN_OS + LNACNT_INT_OS + LNACNT_CHG_OS;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_OUTSTANDING_BALANCE',
                     W_ROWCOUNT,
                     'LNACNT_OUTSTANDING_BALANCE SHOULD BE EQUAL TO LNACNT_PRIN_OS + LNACNT_INT_OS + LNACNT_CHG_OS',
                     'SELECT LNACNT_ACNUM, LNACNT_OUTSTANDING_BALANCE, LNACNT_PRIN_OS, LNACNT_INT_OS, LNACNT_CHG_OS
        FROM MIG_LNACNT
   WHERE LNACNT_OUTSTANDING_BALANCE <>
         LNACNT_PRIN_OS + LNACNT_INT_OS + LNACNT_CHG_OS;');
   END IF;

   --- checking suspense balance

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE LNACNT_TOT_SUSPENSE_BALANCE <>
             LNACNT_INT_SUSP_BALANCE + LNACNT_CHG_SUSP_BALANCE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_TOT_SUSPENSE_BALANCE',
                     W_ROWCOUNT,
                     'LNACNT_TOT_SUSPENSE_BALANCE SHOULD BE EQUAL TO LNACNT_INT_SUSP_BALANCE + LNACNT_CHG_SUSP_BALANCE',
                     'SELECT LNACNT_ACNUM, LNACNT_TOT_SUSPENSE_BALANCE, LNACNT_INT_SUSP_BALANCE, LNACNT_CHG_SUSP_BALANCE
        FROM MIG_LNACNT
   WHERE LNACNT_TOT_SUSPENSE_BALANCE <>
         LNACNT_INT_SUSP_BALANCE + LNACNT_CHG_SUSP_BALANCE;');
   END IF;

   --- checking outstanding interest and suspense balance

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE LNACNT_INT_OS > LNACNT_TOT_SUSPENSE_BALANCE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_INT_OS',
                     W_ROWCOUNT,
                     'LNACNT_INT_OS SHOULD NOT BE GREATER THAN LNACNT_TOT_SUSPENSE_BALANCE',
                     'SELECT LNACNT_ACNUM, LNACNT_INT_OS, LNACNT_TOT_SUSPENSE_BALANCE
        FROM MIG_LNACNT WHERE LNACNT_INT_OS > LNACNT_TOT_SUSPENSE_BALANCE;');
   END IF;

   ---LNACNT_SANCTION_AMT cannot be null or zero

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE NVL (LNACNT_SANCTION_AMT, 0) = 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_SANCTION_AMT',
                     W_ROWCOUNT,
                     'LNACNT_SANCTION_AMT SHOULD NOT BE NULL OR ZERO',
                     'SELECT SELECT LNACNT_ACNUM,
       LNACNT_INT_ACCR_UPTO,
       LNACNT_INT_APPLIED_UPTO_DATE,
       LNACNT_LIMIT_SANCTION_DATE,
       LNACNT_SANCTION_AMT
       FROM MIG_LNACNT  WHERE NVL(LNACNT_SANCTION_AMT, 0)  = 0;');
   END IF;

   ------------------------------------- date validation  --------------------------------------

   --- LNACNT_DATE_OF_NPA null checking for UC loan

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE     LNACNT_ASSET_STAT IN ('UC', 'SM', 'ST')
          AND LNACNT_DATE_OF_NPA IS NOT NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_DATE_OF_NPA',
                     W_ROWCOUNT,
                     'LNACNT_DATE_OF_NPA SHOULD BE NULL FOR UC LOAN ',
                     'SELECT LNACNT_ACNUM, LNACNT_ASSET_STAT, LNACNT_DATE_OF_NPA FROM MIG_LNACNT 
     WHERE LNACNT_ASSET_STAT IN( ''UC'',''SM'', ''ST'')  AND LNACNT_DATE_OF_NPA IS NOT NULL;');
   END IF;

   --- LNACNT_DATE_OF_NPA null checking for BL loan

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE     LNACNT_ASSET_STAT NOT IN ('UC', 'SM', 'ST')
          AND LNACNT_DATE_OF_NPA IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_DATE_OF_NPA',
                     W_ROWCOUNT,
                     'LNACNT_DATE_OF_NPA SHOULD NOT BE NULL FOR BL LOAN ',
                     'SELECT LNACNT_ACNUM, LNACNT_ASSET_STAT, LNACNT_DATE_OF_NPA FROM MIG_LNACNT 
       WHERE LNACNT_ASSET_STAT 
     NOT IN ( ''UC'',''SM'', ''ST'') AND LNACNT_DATE_OF_NPA IS  NULL;');
   END IF;

   --- checking  LNACNT_DATE_OF_NPA is greater than mig date

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE LNACNT_DATE_OF_NPA > P_START_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_DATE_OF_NPA',
                     W_ROWCOUNT,
                     'LNACNT_DATE_OF_NPA SHOULD NOT BE GREATER THAN MIG DATE',
                        'SELECT LNACNT_ACNUM, LNACNT_ASSET_STAT, LNACNT_DATE_OF_NPA FROM MIG_LNACNT 
       WHERE LNACNT_DATE_OF_NPA > '''
                     || P_START_DATE
                     || ''' ;');
   END IF;

   ----   checking if accru upto date is null or greater than mig date

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT, MIG_ACNTS
    WHERE        ACNTS_ACNUM = LNACNT_ACNUM
             AND ACNTS_PROD_CODE NOT IN (2042, 2107, 2029)
             AND (NVL (LNACNT_INT_ACCR_UPTO, '31-DEC-1899') NOT BETWEEN '01-JAN-1900'
                                                                    AND '31-DEC-2050')
          OR LNACNT_INT_ACCR_UPTO > P_START_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_INT_ACCR_UPTO',
                     W_ROWCOUNT,
                     'LNACNT_INT_ACCR_UPTO SHOULD NOT BE NULL OR GREATER THAN MIG DATE',
                        'SELECT LNACNT_ACNUM,
       LNACNT_INT_ACCR_UPTO,
       LNACNT_INT_APPLIED_UPTO_DATE,
       LNACNT_LIMIT_SANCTION_DATE,
       LNACNT_LIMIT_EFF_DATE,
       LNACNT_DATE_OF_NPA
  FROM MIG_LNACNT
 WHERE (NVL(LNACNT_INT_ACCR_UPTO, ''31-DEC-1899'') NOT BETWEEN ''01-JAN-1900'' AND
       ''31-DEC-2050'')
    OR LNACNT_INT_ACCR_UPTO > '''
                     || P_START_DATE
                     || ''';');
   END IF;

   ----   checking if limit sanction date is null or greater than mig date

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE    (NVL (LNACNT_LIMIT_SANCTION_DATE, '31-DEC-1899') NOT BETWEEN '01-JAN-1900'
                                                                      AND '31-DEC-2050')
          OR LNACNT_LIMIT_SANCTION_DATE > P_START_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_LIMIT_SANCTION_DATE',
                     W_ROWCOUNT,
                     'LNACNT_LIMIT_SANCTION_DATE SHOULD NOT BE NULL OR GREATER THAN MIG DATE',
                        'SELECT LNACNT_ACNUM,
       LNACNT_INT_ACCR_UPTO,
       LNACNT_INT_APPLIED_UPTO_DATE,
       LNACNT_LIMIT_SANCTION_DATE,
       LNACNT_LIMIT_EFF_DATE,
       LNACNT_DATE_OF_NPA
  FROM MIG_LNACNT
 WHERE NVL(LNACNT_LIMIT_SANCTION_DATE, ''31-DEC-1899'') NOT BETWEEN ''01-JAN-1900'' AND
       ''31-DEC-2050'')
    OR LNACNT_LIMIT_SANCTION_DATE > '''
                     || P_START_DATE
                     || ''';');
   END IF;

   ----   checking if effective date is null or greater than mig date

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE    (NVL (LNACNT_LIMIT_EFF_DATE, '31-DEC-1899') NOT BETWEEN '01-JAN-1900'
                                                                 AND '31-DEC-2050')
          OR LNACNT_LIMIT_EFF_DATE > P_START_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_LIMIT_EFF_DATE',
                     W_ROWCOUNT,
                     'LNACNT_LIMIT_EFF_DATE SHOULD NOT BE NULL OR GREATER THAN MIG DATE',
                        'SELECT LNACNT_ACNUM,
       LNACNT_INT_ACCR_UPTO,
       LNACNT_INT_APPLIED_UPTO_DATE,
       LNACNT_LIMIT_SANCTION_DATE,
       LNACNT_LIMIT_EFF_DATE,
       LNACNT_DATE_OF_NPA
  FROM MIG_LNACNT
 WHERE NVL(LNACNT_LIMIT_EFF_DATE, ''31-DEC-1899'') NOT BETWEEN ''01-JAN-1900'' AND
       ''31-DEC-2050'')
    OR LNACNT_LIMIT_EFF_DATE > '''
                     || P_START_DATE
                     || ''';');
   END IF;

   ---- checking  interest applied upto date if greater than mig date

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE    (LNACNT_INT_APPLIED_UPTO_DATE NOT BETWEEN '01-JAN-1900'
                                                   AND '31-DEC-2050')
          OR LNACNT_INT_APPLIED_UPTO_DATE > P_START_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_INT_APPLIED_UPTO_DATE',
                     W_ROWCOUNT,
                     'LNACNT_INT_APPLIED_UPTO_DATE SHOULD NOT BE GREATER THAN MIG DATE',
                        'SELECT LNACNT_ACNUM,
       LNACNT_INT_ACCR_UPTO,
       LNACNT_INT_APPLIED_UPTO_DATE,
       LNACNT_LIMIT_SANCTION_DATE,
       LNACNT_LIMIT_EFF_DATE,
       LNACNT_DATE_OF_NPA
  FROM MIG_LNACNT
 WHERE (LNACNT_INT_APPLIED_UPTO_DATE NOT BETWEEN ''01-JAN-1900'' AND
       ''31-DEC-2050'')
    OR LNACNT_INT_APPLIED_UPTO_DATE > '''
                     || P_START_DATE
                     || ''';');
   END IF;

   ---LNACNT_LIMIT_EXPIRY_DATE null checking

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE NVL (LNACNT_LIMIT_EXPIRY_DATE, '31-DEC-1899') NOT BETWEEN '01-JAN-1900'
                                                                AND '31-DEC-2050';

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNACNT',
                     'LNACNT_LIMIT_EXPIRY_DATE',
                     W_ROWCOUNT,
                     'LNACNT_LIMIT_EXPIRY_DATE SHOULD NOT BE NULL',
                     'SELECT LNACNT_ACNUM,
       LNACNT_INT_ACCR_UPTO,
       LNACNT_INT_APPLIED_UPTO_DATE,
       LNACNT_LIMIT_SANCTION_DATE,
       LNACNT_LIMIT_EFF_DATE,
       LNACNT_LIMIT_EXPIRY_DATE
  FROM MIG_LNACNT
 WHERE NVLLNACNT_LIMIT_EXPIRY_DATE, ''31-DEC-1899'') NOT BETWEEN ''01-JAN-1900'' AND
       ''31-DEC-2050'' ;');
   END IF;
---LNACNT_LIMIT_AVL_ON_DATE null checking


END SP_LNACNT_VALIDATE;
/
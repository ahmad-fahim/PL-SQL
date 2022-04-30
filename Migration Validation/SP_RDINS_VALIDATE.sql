CREATE OR REPLACE PROCEDURE SP_RDINS_VALIDATE (
   P_START_DATE IN DATE)
IS
   W_SQL        VARCHAR2 (3000);
   W_MIG_DATE   DATE := P_START_DATE;
   W_ROWCOUNT   NUMBER := 0;
BEGIN
   DELETE FROM ERRORLOG
         WHERE TEMPLATE_NAME = 'MIG_RDINS';

   UPDATE MIG_RDINS
      SET RDINS_ENTRY_DATE = P_START_DATE;

   COMMIT;


   --- matching account no with acnts


   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_RDINS
    WHERE NVL (RDINS_RD_AC_NUM, 0) NOT IN
             (SELECT MIG_ACNTS.ACNTS_ACNUM FROM MIG_ACNTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_RDINS',
                     'RDINS_RD_AC_NUM',
                     W_ROWCOUNT,
                     'ACCOUNT NUMBER IS NOT IN MIG_ACNTS',
                     'SELECT RDINS_RD_AC_NUM
        FROM MIG_RDINS
       WHERE NVL(RDINS_RD_AC_NUM, 0) NOT IN
                (SELECT MIG_ACNTS.ACNTS_ACNUM FROM MIG_ACNTS);');
   END IF;



   --- RDINS_AMT_OF_PYMT checking


   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_RDINS
    WHERE RDINS_AMT_OF_PYMT <>
               RDINS_TWDS_INSTLMNT
             + NVL (RDINS_TWDS_PENAL_CHGS, 0)
             + RDINS_TWDS_INT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_RDINS',
                     'RDINS_AMT_OF_PYMT',
                     W_ROWCOUNT,
                     'RDINS_AMT_OF_PYMT SHOULD BE SUM OF RDINS_TWDS_INSTLMNT, RDINS_TWDS_PENAL_CHGS AND RDINS_TWDS_INT',
                     'SELECT RDINS_RD_AC_NUM,
       RDINS_AMT_OF_PYMT,
       RDINS_TWDS_INSTLMNT,
       RDINS_TWDS_PENAL_CHGS,
       RDINS_TWDS_INT
  FROM MIG_RDINS
  WHERE RDINS_AMT_OF_PYMT <>
             RDINS_TWDS_INSTLMNT + NVL(RDINS_TWDS_PENAL_CHGS, 0) +
             RDINS_TWDS_INT;');
   END IF;



   --- Effective date is greater than migration date

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_RDINS
    WHERE RDINS_EFF_DATE > P_START_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_RDINS',
                     'RDINS_EFF_DATE',
                     W_ROWCOUNT,
                     'RDINS_EFF_DATE CAN NOT BE GREATER THAN MIGRATION DATE',
                        'SELECT RDINS_RD_AC_NUM, RDINS_EFF_DATE
  FROM MIG_RDINS
 WHERE RDINS_EFF_DATE > '''
                     || P_START_DATE
                     || '''');
   END IF;



   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_ACNTS
    WHERE     ACNTS_PROD_CODE IN
                 (SELECT PRODUCT_CODE
                    FROM PRODUCTS
                   WHERE     PRODUCT_FOR_DEPOSITS = 1
                         AND PRODUCT_FOR_RUN_ACS = 0
                         AND PRODUCT_CONTRACT_ALLOWED = 0)
          AND ACNTS_ACNUM NOT IN (SELECT RDINS_RD_AC_NUM FROM MIG_RDINS)
          AND ACNTS_ACNUM IN (SELECT ACOP_AC_NUM
                                FROM MIG_ACOP_BAL
                               WHERE ACOP_BALANCE <> 0);


   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_RDINS',
                     'RDINS_RD_AC_NUM',
                     W_ROWCOUNT,
                     'NO RECORD FOUND FOR RD ACCOUNT IN MIG_RDINS',
                     'SELECT ACNTS_ACNUM,
       ACNTS_PROD_CODE,
       ACNTS_AC_TYPE,
       ACNTS_OPENING_DATE,
       (SELECT ACOP_BALANCE
          FROM MIG_ACOP_BAL
         WHERE ACOP_AC_NUM = ACNTS_ACNUM)
          ACOP_BALANCE
  FROM MIG_ACNTS
 WHERE     ACNTS_PROD_CODE IN
              (SELECT PRODUCT_CODE
                 FROM PRODUCTS
                WHERE     PRODUCT_FOR_DEPOSITS = 1
                      AND PRODUCT_FOR_RUN_ACS = 0
                      AND PRODUCT_CONTRACT_ALLOWED = 0)
       AND ACNTS_ACNUM NOT IN (SELECT RDINS_RD_AC_NUM FROM MIG_RDINS)
       AND ACNTS_ACNUM IN (SELECT ACOP_AC_NUM
                             FROM MIG_ACOP_BAL
                            WHERE ACOP_BALANCE <> 0) ;');
   END IF;
END SP_RDINS_VALIDATE;
/
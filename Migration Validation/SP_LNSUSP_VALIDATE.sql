CREATE OR REPLACE PROCEDURE SP_LNSUSP_VALIDATE (
   P_BRANCH_CODE   IN NUMBER,
   P_START_DATE    IN DATE)
-- P_PREVIOUS_VENDOR VARCHAR2)
IS
   W_SQL        VARCHAR2 (3000);
   -- W_BRN_CODE          NUMBER (5) := P_BRANCH_CODE;
   W_MIG_DATE   DATE := P_START_DATE;
   --W_PREVIOUS_VENDOR VARCHAR2(255) := P_PREVIOUS_VENDOR;
   W_ROWCOUNT   NUMBER := 0;
BEGIN
   DELETE FROM ERRORLOG
         WHERE TEMPLATE_NAME = 'MIG_LNSUSP';

   COMMIT;

   --- matching account no with acnts

   UPDATE MIG_LNSUSP
      SET LNSUSP_TRAN_DATE = FN_FIND_QUARTER_END_DATE (W_MIG_DATE)
    WHERE LNSUSP_TRAN_DATE IS NULL;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNSUSP
    WHERE NVL (LNSUSP_ACNUM, 0) NOT IN
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
           VALUES ('MIG_LNSUSP',
                   'LNSUSP_ACNUM',
                   W_ROWCOUNT,
                   'ACCOUNT NUMBER IS NOT IN MIG_ACNTS',
                   'SELECT *
 FROM MIG_LNSUSP
WHERE NVL(LNSUSP_ACNUM, 0 ) NOT IN
      (SELECT ACNTS_ACNUM
         FROM MIG_ACNTS
        WHERE ACNTS_PROD_CODE IN
              (SELECT PRODUCT_CODE
                 FROM PRODUCTS
                WHERE PRODUCT_FOR_LOANS = 1));');
   END IF;



   --- last trnasaction date is null or greater than migration date

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNSUSP
    WHERE    (NVL (LNSUSP_TRAN_DATE, '31-DEC-1899') NOT BETWEEN '01-JAN-1900'
                                                            AND '31-DEC-2050')
          OR LNSUSP_TRAN_DATE > P_START_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_LNSUSP',
                     'LNSUSP_TRAN_DATE',
                     W_ROWCOUNT,
                     'ERROR IN LAST TRANSACTION DATE',
                        'SELECT *
  FROM MIG_LNSUSP
 WHERE (NVL(LNSUSP_TRAN_DATE, ''31-DEC-1899'') NOT BETWEEN
                      ''01-JAN-1900'' AND ''31-DEC-2050'') OR
                      LNSUSP_TRAN_DATE > '''
                     || P_START_DATE
                     || '''');
   END IF;


   ---- checking suspense amount is null or zero

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNSUSP
    WHERE LNSUSP_AMOUNT = 0 OR LNSUSP_AMOUNT IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_LNSUSP',
                   'LNSUSP_AMOUNT',
                   W_ROWCOUNT,
                   'LNSUSP_AMOUNT CANNOT BE NULL OR ZERO',
                   'SELECT *
    FROM MIG_LNSUSP
    WHERE LNSUSP_AMOUNT = 0 OR LNSUSP_AMOUNT IS NULL;');
   END IF;
END SP_LNSUSP_VALIDATE;
/
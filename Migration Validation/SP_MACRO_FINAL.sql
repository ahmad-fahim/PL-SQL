CREATE OR REPLACE PROCEDURE SP_MACRO_FINAL
IS
   W_BRN_CODE                NUMBER (5);
   W_ROWCOUNT                NUMBER := 0;
   W_MIG_DATE                DATE;
   V_INST                    NUMBER;
   V_GL_BAL                  NUMBER;
   V_BALACE_FROM_WRITEOFF    NUMBER := 0;
   V_BALACE_FROM_WRECOVERY   NUMBER := 0;
   V_BAL_FROM_GL             NUMBER := 0;
BEGIN
   DELETE FROM ERRORLOG
         WHERE TEMPLATE_NAME = 'FINAL_VALIDATION';

   UPDATE TEMP_LOANIA T
      SET T.LOANIA_ACCRUAL_DATE =
             (SELECT L.LNACNT_INT_ACCR_UPTO
                FROM MIG_LNACNT L
               WHERE T.LOANIA_ACNT_NUM = L.LNACNT_ACNUM),
          T.LOANIA_VALUE_DATE =
             (SELECT L.LNACNT_INT_ACCR_UPTO
                FROM MIG_LNACNT L
               WHERE T.LOANIA_ACNT_NUM = L.LNACNT_ACNUM)
    WHERE T.LOANIA_ACCRUAL_DATE IS NULL;

   DELETE FROM MIG_GLOP_BAL
         WHERE GLOP_BALANCE IS NULL OR GLOP_BALANCE = 0;

   COMMIT;
   
   Delete From Mig_Blloania B 
          Where B.MIG_BLLOANIA_AMOUNT = 0;
   Commit;


   SELECT DISTINCT ACOP_BRANCH_CODE INTO W_BRN_CODE FROM MIG_ACOP_BAL;

   SELECT DISTINCT ACOP_BAL_DATE INTO W_MIG_DATE FROM MIG_ACOP_BAL;

   UPDATE MIG_GLOP_BAL G
      SET G.GLOP_BRANCH_CODE = W_BRN_CODE,
          G.GLOP_BAL_DATE = W_MIG_DATE,
          GLOP_GL_HEAD = TRIM (GLOP_GL_HEAD);

   COMMIT;
 
   ---UPDATE MIG_LNACRSDTL_TEMP
   UPDATE MIG_LNACRSDTL_TEMP
      SET LNACRS_REPH_ON_AMT = ABS (LNACRS_REPH_ON_AMT),
          LNACRSDTL_REPAY_AMT = ABS (LNACRSDTL_REPAY_AMT),
          LNACRSDTL_REPAY_FREQ = UPPER (LNACRSDTL_REPAY_FREQ);

   COMMIT;

   ---UPDATE MIG_LNACRSDTL

   UPDATE MIG_LNACRSDTL
      SET LNACRS_REPH_ON_AMT = ABS (LNACRS_REPH_ON_AMT),
          LNACRSDTL_REPAY_AMT = ABS (LNACRSDTL_REPAY_AMT),
          LNACRSDTL_REPAY_FREQ = UPPER (LNACRSDTL_REPAY_FREQ);

   COMMIT;

   --- GL head null or not existing in extgl for acop_bal

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_ACOP_BAL
    WHERE NVL (ACOP_GL_HEAD, 0) NOT IN (SELECT EXTGL_ACCESS_CODE FROM EXTGL);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACOP_BAL',
                     W_ROWCOUNT,
                     'GL HEAD NULL OR NOT EXISTING IN EXTGL',
                     'SELECT  * FROM MIG_ACOP_BAL
                  WHERE NVL(ACOP_GL_HEAD, 0) NOT IN (SELECT EXTGL_ACCESS_CODE FROM EXTGL);');
   END IF;

   --- GL head null or not existing in extgl for glop_bal

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_GLOP_BAL
    WHERE NVL (GLOP_GL_HEAD, 0) NOT IN (SELECT EXTGL_ACCESS_CODE FROM EXTGL);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_GLOP_BAL',
                     W_ROWCOUNT,
                     'GL HEAD NULL OR NOT EXISTING IN EXTGL',
                     'SELECT  * FROM MIG_GLOP_BAL
                  WHERE NVL(GLOP_GL_HEAD, 0) NOT IN (SELECT EXTGL_ACCESS_CODE FROM EXTGL);');
   END IF;

   -------------- GL head mismatch for mig_acnts , mig_acop_bal  with products' gl

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM (SELECT *
             FROM MIG_ACOP_BAL, PRODUCTS, MIG_ACNTS
            WHERE     MIG_ACOP_BAL.ACOP_AC_NUM = MIG_ACNTS.ACNTS_ACNUM
                  AND PRODUCTS.PRODUCT_CODE = MIG_ACNTS.ACNTS_PROD_CODE)
    WHERE    ACOP_GL_HEAD <> PRODUCT_GLACC_CODE
          OR ACNTS_GLACC_CODE <> PRODUCT_GLACC_CODE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACOP_BAL, MIG_ACNTS',
                     W_ROWCOUNT,
                     'GL HEAD MISMATCH FOR MIG_ACNTS, MIG_ACOP_BAL WITH PRODUCTS'' GL',
                     'SELECT *
  FROM (SELECT ACOP_AC_NUM,
               ACOP_GL_HEAD,
               M.ACNTS_GLACC_CODE,
               PRODUCTS.PRODUCT_CODE,
               PRODUCTS.PRODUCT_GLACC_CODE,
               (ACOP_GL_HEAD - PRODUCTS.PRODUCT_GLACC_CODE) PRODUCT_ACCOUNTBAL,
               (M.ACNTS_GLACC_CODE - PRODUCTS.PRODUCT_GLACC_CODE) PRODUCT_MIG_ACNTS
          FROM MIG_ACOP_BAL , PRODUCTS, MIG_ACNTS M
         WHERE ACOP_AC_NUM = M.ACNTS_ACNUM
           AND PRODUCTS.PRODUCT_CODE = ACNTS_PROD_CODE)
 WHERE PRODUCT_ACCOUNTBAL <> 0
    OR PRODUCT_MIG_ACNTS <> 0; 
    
    -----update----------
    BEGIN
  FOR IDX
     IN (SELECT *
           FROM (SELECT ACOP_AC_NUM,
                        ACOP_GL_HEAD,
                        M.ACNTS_GLACC_CODE,
                        PRODUCTS.PRODUCT_CODE,
                        PRODUCTS.PRODUCT_GLACC_CODE,
                        (ACOP_GL_HEAD - PRODUCTS.PRODUCT_GLACC_CODE)
                           PRODUCT_ACCOUNTBAL,
                        (M.ACNTS_GLACC_CODE - PRODUCTS.PRODUCT_GLACC_CODE)
                           PRODUCT_MIG_ACNTS
                   FROM MIG_ACOP_BAL, PRODUCTS, MIG_ACNTS M
                  WHERE     ACOP_AC_NUM = M.ACNTS_ACNUM
                        AND PRODUCTS.PRODUCT_CODE = ACNTS_PROD_CODE)
          WHERE PRODUCT_ACCOUNTBAL <> 0 OR PRODUCT_MIG_ACNTS <> 0)
  LOOP
     UPDATE MIG_ACOP_BAL AC
        SET AC.ACOP_GL_HEAD = IDX.PRODUCT_GLACC_CODE
      WHERE AC.ACOP_AC_NUM = IDX.ACOP_AC_NUM;

     UPDATE MIG_ACNTS A
        SET A.ACNTS_GLACC_CODE = IDX.PRODUCT_GLACC_CODE
      WHERE A.ACNTS_ACNUM = IDX.ACOP_AC_NUM
      AND A.ACNTS_PROD_CODE=IDX.PRODUCT_CODE;
  END LOOP;
END;');
   END IF;

   ------- gl balance & gl account sum balance mismatch

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM (SELECT T1.GLOP_GL_HEAD,
                  T1.T1_SUM,
                  T2.SAMT,
                  T1.T1_SUM - T2.SAMT TEMP_BAL
             FROM (  SELECT G.GLOP_GL_HEAD, SUM (G.GLOP_BALANCE) T1_SUM
                       FROM EXTGL E, MIG_GLOP_BAL G, GLMAST GM
                      WHERE     GM.GL_NUMBER = E.EXTGL_GL_HEAD
                            AND GM.GL_CUST_AC_ALLOWED = 1
                            AND E.EXTGL_ACCESS_CODE = G.GLOP_GL_HEAD
                   GROUP BY G.GLOP_GL_HEAD) T1
                  LEFT JOIN (  SELECT ACOP_GL_HEAD, SUM (ACOP_BALANCE) SAMT
                                 FROM MIG_ACOP_BAL
                             GROUP BY ACOP_GL_HEAD) T2
                     ON (T1.GLOP_GL_HEAD = T2.ACOP_GL_HEAD)
           UNION ALL
           SELECT T2.GLOP_GL_HEAD,
                  T2.T1_SUM,
                  T1.SAMT,
                  T2.T1_SUM - T1.SAMT TEMP_BAL
             FROM (  SELECT ACOP_GL_HEAD, SUM (ACOP_BALANCE) SAMT
                       FROM MIG_ACOP_BAL
                   GROUP BY ACOP_GL_HEAD) T1
                  LEFT JOIN
                  (  SELECT G.GLOP_GL_HEAD, SUM (G.GLOP_BALANCE) T1_SUM
                       FROM EXTGL E, MIG_GLOP_BAL G, GLMAST GM
                      WHERE     GM.GL_NUMBER = E.EXTGL_GL_HEAD
                            AND GM.GL_CUST_AC_ALLOWED = 1
                            AND E.EXTGL_ACCESS_CODE = G.GLOP_GL_HEAD
                   GROUP BY G.GLOP_GL_HEAD) T2
                     ON (T2.GLOP_GL_HEAD = T1.ACOP_GL_HEAD)) FINAL_BAL
    WHERE TEMP_BAL <> 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACOP_BAL, MIG_GLOP_BAL',
                     W_ROWCOUNT,
                     'GL BALANCE & GL ACCOUNT SUM BALANCE MISMATCH',
                     'SELECT *
  FROM (SELECT T1.GLOP_GL_HEAD,
               T1.T1_SUM,
               T2.SAMT,
               T1.T1_SUM - T2.SAMT TEMP_BAL
          FROM (SELECT G.GLOP_GL_HEAD, SUM(G.GLOP_BALANCE) T1_SUM
                  FROM EXTGL E, MIG_GLOP_BAL G, GLMAST GM
                 WHERE GM.GL_NUMBER = E.EXTGL_GL_HEAD
                   AND GM.GL_CUST_AC_ALLOWED = 1
                   AND E.EXTGL_ACCESS_CODE = G.GLOP_GL_HEAD
                 GROUP BY G.GLOP_GL_HEAD) T1
          LEFT JOIN (SELECT ACOP_GL_HEAD, SUM(ACOP_BALANCE) SAMT
                      FROM MIG_ACOP_BAL
                     GROUP BY ACOP_GL_HEAD) T2
            ON (T1.GLOP_GL_HEAD = T2.ACOP_GL_HEAD)
        UNION ALL
        SELECT T2.GLOP_GL_HEAD,
               T2.T1_SUM,
               T1.SAMT,
               T2.T1_SUM - T1.SAMT TEMP_BAL
          FROM (SELECT ACOP_GL_HEAD, SUM(ACOP_BALANCE) SAMT
                  FROM MIG_ACOP_BAL
                 GROUP BY ACOP_GL_HEAD) T1
          LEFT JOIN (SELECT G.GLOP_GL_HEAD, SUM(G.GLOP_BALANCE) T1_SUM
                      FROM EXTGL E, MIG_GLOP_BAL G, GLMAST GM
                     WHERE GM.GL_NUMBER = E.EXTGL_GL_HEAD
                       AND GM.GL_CUST_AC_ALLOWED = 1
                       AND E.EXTGL_ACCESS_CODE = G.GLOP_GL_HEAD
                     GROUP BY G.GLOP_GL_HEAD) T2
            ON (T2.GLOP_GL_HEAD = T1.ACOP_GL_HEAD)) FINAL_BAL
 WHERE TEMP_BAL <> 0;');
   END IF;

   ---- asset liablility -----

   SELECT SUM (TOTAL)
     INTO W_ROWCOUNT
     FROM (  SELECT DRCR, SUM (BAL) TOTAL
               FROM (SELECT GLOP_GL_HEAD,
                            GLOP_BALANCE BAL,
                            DECODE (SIGN (GLOP_BALANCE), 1, 'C', 'D') DRCR
                       FROM MIG_GLOP_BAL
                      WHERE GLOP_GL_HEAD IN
                               (SELECT EXTGL.EXTGL_ACCESS_CODE
                                  FROM EXTGL
                                 WHERE EXTGL.EXTGL_GL_HEAD IN
                                          (SELECT GLMAST.GL_NUMBER
                                             FROM GLMAST
                                            WHERE GLMAST.GL_CUST_AC_ALLOWED = 0))
                     UNION
                     SELECT ACOP_AC_NUM,
                            ACOP_BALANCE BAL,
                            DECODE (SIGN (ACOP_BALANCE), 1, 'C', 'D') DRCR
                       FROM MIG_ACOP_BAL
                      WHERE ACOP_BALANCE <> 0)
           GROUP BY DRCR);

   IF W_ROWCOUNT <> 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACOP_BAL, MIG_GLOP_BAL',
                     W_ROWCOUNT,
                     'ASSET LIABILITY MISMATCH',
                     'SELECT DRCR, SUM(BAL) 
   FROM (SELECT GLOP_GL_HEAD,
                ABS(GLOP_BALANCE) BAL,
                DECODE(SIGN(GLOP_BALANCE), 1, ''C'', ''D'') DRCR
           FROM MIG_GLOP_BAL
          WHERE GLOP_GL_HEAD IN
                (SELECT EXTGL.EXTGL_ACCESS_CODE
                   FROM EXTGL
                  WHERE EXTGL.EXTGL_GL_HEAD IN
                        (SELECT GLMAST.GL_NUMBER
                           FROM GLMAST
                          WHERE GLMAST.GL_CUST_AC_ALLOWED = 0))
         UNION
         SELECT ACOP_AC_NUM,
                ABS(ACOP_BALANCE) BAL,
                DECODE(SIGN(ACOP_BALANCE), 1, ''C'', ''D'') DRCR
         
           FROM MIG_ACOP_BAL
          WHERE ACOP_BALANCE <> 0)
  GROUP BY DRCR;');
   END IF;

   -----customer gl not found in mig_acop_bal

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM EXTGL E, GLMAST G, MIG_GLOP_BAL M
    WHERE     E.EXTGL_GL_HEAD = G.GL_NUMBER
          AND M.GLOP_GL_HEAD = E.EXTGL_ACCESS_CODE
          AND M.GLOP_GL_HEAD NOT IN
                 (SELECT MIG_ACOP_BAL.ACOP_GL_HEAD FROM MIG_ACOP_BAL)
          AND G.GL_CUST_AC_ALLOWED <> 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_GLOP_BAL',
                     W_ROWCOUNT,
                     'CUSTOMER GL NOT FOUND IN MIG_ACOP_BAL',
                     'SELECT DISTINCT M.GLOP_GL_HEAD,
                E.EXTGL_EXT_HEAD_DESCN,
                E.EXTGL_ACCESS_CODE,
                E.EXTGL_GL_HEAD,
                G.GL_CUST_AC_ALLOWED
  FROM EXTGL E, GLMAST G, MIG_GLOP_BAL M
 WHERE E.EXTGL_GL_HEAD = G.GL_NUMBER
   AND M.GLOP_GL_HEAD = E.EXTGL_ACCESS_CODE
   AND M.GLOP_GL_HEAD NOT IN
       (SELECT MIG_ACOP_BAL.ACOP_GL_HEAD FROM MIG_ACOP_BAL)
   AND G.GL_CUST_AC_ALLOWED <> 0;');
   END IF;

   ------ Customer GL marked as non customer gl but having accounts & balance

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM EXTGL E, GLMAST G, MIG_ACOP_BAL M
    WHERE     E.EXTGL_GL_HEAD = G.GL_NUMBER
          AND M.ACOP_GL_HEAD = E.EXTGL_ACCESS_CODE
          AND G.GL_CUST_AC_ALLOWED <> 1;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACOP_BAL',
                     W_ROWCOUNT,
                     'CUSTOMER GL MARKED AS NON CUSTOMER GL BUT HAVING ACCOUNTS & BALANCE',
                     'SELECT DISTINCT M.ACOP_GL_HEAD, E.EXTGL_ACCESS_CODE, G.GL_CUST_AC_ALLOWED
  FROM EXTGL E, GLMAST G, MIG_ACOP_BAL M
 WHERE E.EXTGL_GL_HEAD = G.GL_NUMBER
   AND M.ACOP_GL_HEAD = E.EXTGL_ACCESS_CODE
   AND G.GL_CUST_AC_ALLOWED <> 1;');
   END IF;

   --- checking if loan accrual accounts in main account

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM TEMP_LOANIA T
    WHERE NVL (T.LOANIA_ACNT_NUM, 0) NOT IN
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
           VALUES (
                     'FINAL_VALIDATION',
                     'TEMP_LOANIA',
                     W_ROWCOUNT,
                     'LOAN ACCRUAL ACCOUNTS MUST BE IN MAIN LOAN ACCOUNT',
                     'SELECT * FROM TEMP_LOANIA T
 WHERE NVL(T.LOANIA_ACNT_NUM, 0) NOT IN
       (SELECT ACNTS_ACNUM
          FROM MIG_ACNTS
         WHERE ACNTS_PROD_CODE IN
               (SELECT PRODUCT_CODE FROM PRODUCTS WHERE PRODUCT_FOR_LOANS = 1));');
   END IF;

   --- checking duplicate loania accounts

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM TEMP_LOANIA T
    WHERE T.LOANIA_ACNT_NUM IN (  SELECT LOANIA_ACNT_NUM
                                    FROM TEMP_LOANIA
                                GROUP BY LOANIA_ACNT_NUM
                                  HAVING COUNT (*) > 1);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'TEMP_LOANIA',
                   W_ROWCOUNT,
                   'DUPLICATE LOAN ACCRUAL ACCOUNTS',
                   'SELECT *
  FROM TEMP_LOANIA T
 WHERE T.LOANIA_ACNT_NUM IN (SELECT LOANIA_ACNT_NUM
                               FROM TEMP_LOANIA
                              GROUP BY LOANIA_ACNT_NUM
                             HAVING COUNT(*) > 1);');
   END IF;

   --- checking if loan accrual is BL loan

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM TEMP_LOANIA T
    WHERE T.LOANIA_ACNT_NUM IN (SELECT L.LNACNT_ACNUM
                                  FROM MIG_LNACNT L
                                 WHERE L.LNACNT_ASSET_STAT = 'BL');

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'TEMP_LOANIA',
                   W_ROWCOUNT,
                   'LOAN ACCRUAL CANNOT BE A BL LOAN',
                   'SELECT *
  FROM TEMP_LOANIA T
 WHERE T.LOANIA_ACNT_NUM IN
       (SELECT L.LNACNT_ACNUM
          FROM MIG_LNACNT L
         WHERE L.LNACNT_ASSET_STAT = ''BL'') ;');
   END IF;

   ----------------------------- accrual  matching -----------------------

   ---- deposit accrual matching

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM ( (SELECT 'GL' SL, N.GLOP_GL_HEAD, N.GLOP_BALANCE GL_BALANCE
               FROM MIG_GLOP_BAL N
              WHERE     N.GLOP_GL_HEAD IN
                           (SELECT DISTINCT D.DEPPRCUR_INT_ACCR_GLACC
                              FROM DEPPRODCUR D)
                    AND N.GLOP_BALANCE <> 0
             MINUS
             SELECT 'GL' SL, DEPPRCUR_INT_ACCR_GLACC, INTEREST_PAYABLE
               FROM (SELECT DISTINCT
                            D.DEPPRCUR_PROD_CODE, D.DEPPRCUR_INT_ACCR_GLACC
                       FROM DEPPRODCUR D) DEPGL,
                    (  SELECT SUM (
                                   NVL (P.MIGDEP_AC_INT_ACCR_AMT, 0)
                                 - NVL (P.MIGDEP_AC_INT_PAY_AMT, 0))
                                 INTEREST_PAYABLE,
                              P.MIGDEP_PROD_CODE
                         FROM MIG_PBDCONTRACT P
                     GROUP BY P.MIGDEP_PROD_CODE) SUMDEP
              WHERE     DEPGL.DEPPRCUR_PROD_CODE = SUMDEP.MIGDEP_PROD_CODE
                    AND SUMDEP.INTEREST_PAYABLE <> 0)
           UNION
           (SELECT 'DEP' SL, DEPPRCUR_INT_ACCR_GLACC, INTEREST_PAYABLE
              FROM (SELECT DISTINCT
                           D.DEPPRCUR_PROD_CODE, D.DEPPRCUR_INT_ACCR_GLACC
                      FROM DEPPRODCUR D) DEPGL,
                   (  SELECT SUM (
                                  NVL (P.MIGDEP_AC_INT_ACCR_AMT, 0)
                                - NVL (P.MIGDEP_AC_INT_PAY_AMT, 0))
                                INTEREST_PAYABLE,
                             P.MIGDEP_PROD_CODE
                        FROM MIG_PBDCONTRACT P
                    GROUP BY P.MIGDEP_PROD_CODE) SUMDEP
             WHERE     DEPGL.DEPPRCUR_PROD_CODE = SUMDEP.MIGDEP_PROD_CODE
                   AND SUMDEP.INTEREST_PAYABLE <> 0
            MINUS
            SELECT 'DEP' SL, N.GLOP_GL_HEAD, N.GLOP_BALANCE
              FROM MIG_GLOP_BAL N
             WHERE     N.GLOP_GL_HEAD IN
                          (SELECT DISTINCT D.DEPPRCUR_INT_ACCR_GLACC
                             FROM DEPPRODCUR D)
                   AND N.GLOP_BALANCE <> 0));

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_PBDCONTRACT, MIG_GLOP_BAL',
                     W_ROWCOUNT,
                     'DEPOSIT ACCRUAL MISMATCH',
                     'SELECT *
  FROM (SELECT ''GL'' SL, N.GLOP_GL_HEAD, N.GLOP_BALANCE GL_BALANCE
          FROM MIG_GLOP_BAL N
         WHERE N.GLOP_GL_HEAD IN
               (SELECT DISTINCT D.DEPPRCUR_INT_ACCR_GLACC FROM DEPPRODCUR D)
           AND N.GLOP_BALANCE <> 0
        MINUS
        SELECT ''GL'' SL, DEPPRCUR_INT_ACCR_GLACC, INTEREST_PAYABLE
          FROM (SELECT DISTINCT D.DEPPRCUR_PROD_CODE,
                                D.DEPPRCUR_INT_ACCR_GLACC
                  FROM DEPPRODCUR D) DEPGL,
               (SELECT SUM(NVL(P.MIGDEP_AC_INT_ACCR_AMT, 0) -
                           NVL(P.MIGDEP_AC_INT_PAY_AMT, 0)) INTEREST_PAYABLE,
                       P.MIGDEP_PROD_CODE
                  FROM MIG_PBDCONTRACT P
                 GROUP BY P.MIGDEP_PROD_CODE) SUMDEP
         WHERE DEPGL.DEPPRCUR_PROD_CODE = SUMDEP.MIGDEP_PROD_CODE
           AND SUMDEP.INTEREST_PAYABLE <> 0)
UNION (SELECT ''DEP'' SL, DEPPRCUR_INT_ACCR_GLACC, INTEREST_PAYABLE
         FROM (SELECT DISTINCT D.DEPPRCUR_PROD_CODE,
                               D.DEPPRCUR_INT_ACCR_GLACC
                 FROM DEPPRODCUR D) DEPGL,
              (SELECT SUM(NVL(P.MIGDEP_AC_INT_ACCR_AMT, 0) -
                          NVL(P.MIGDEP_AC_INT_PAY_AMT, 0)) INTEREST_PAYABLE,
                      P.MIGDEP_PROD_CODE
                 FROM MIG_PBDCONTRACT P
                GROUP BY P.MIGDEP_PROD_CODE) SUMDEP
        WHERE DEPGL.DEPPRCUR_PROD_CODE = SUMDEP.MIGDEP_PROD_CODE
          AND SUMDEP.INTEREST_PAYABLE <> 0
       MINUS
       SELECT ''DEP'' SL, N.GLOP_GL_HEAD, N.GLOP_BALANCE
         FROM MIG_GLOP_BAL N
        WHERE N.GLOP_GL_HEAD IN
              (SELECT DISTINCT D.DEPPRCUR_INT_ACCR_GLACC FROM DEPPRODCUR D)
          AND N.GLOP_BALANCE <> 0);');
   END IF;

   ---- loan accrual matching

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM (SELECT *
             FROM ( (  SELECT 'GL' SL,
                              N.GLOP_GL_HEAD,
                              SUM (N.GLOP_BALANCE) TOTAL_SUM_GL
                         FROM MIG_GLOP_BAL N
                        WHERE N.GLOP_GL_HEAD IN
                                 (SELECT DISTINCT
                                         LNPRODACPM.LNPRDAC_INT_ACCR_GL
                                    FROM LNPRODACPM)
                     GROUP BY N.GLOP_GL_HEAD
                     MINUS
                       SELECT 'GL' SL,
                              LNPRO.LNPRDAC_INT_ACCR_GL,
                              (-1) * ABS (SUM (AC.TOTAL)) TOTAL_SUM_ACC
                         FROM (SELECT DISTINCT
                                      LNP.LNPRDAC_PROD_CODE,
                                      LNP.LNPRDAC_INT_ACCR_GL
                                 FROM LNPRODACPM LNP) LNPRO,
                              (  SELECT A.ACNTS_PROD_CODE,
                                        SUM (L.LOANIA_INT_ON_AMT) TOTAL
                                   FROM MIG_ACNTS A, TEMP_LOANIA L
                                  WHERE     L.LOANIA_ACNT_NUM = A.ACNTS_ACNUM
                                        AND L.LOANIA_ACNT_NUM IN
                                               (SELECT LL.LNACNT_ACNUM
                                                  FROM MIG_LNACNT LL
                                                 WHERE LL.LNACNT_ASSET_STAT IN
                                                          ('UC', 'SM'))
                               GROUP BY A.ACNTS_PROD_CODE) AC
                        WHERE AC.ACNTS_PROD_CODE = LNPRO.LNPRDAC_PROD_CODE
                     GROUP BY LNPRO.LNPRDAC_INT_ACCR_GL)
                   UNION
                   (  SELECT 'LOAN' SL,
                             LNPRO.LNPRDAC_INT_ACCR_GL,
                             (-1) * ABS (SUM (AC.TOTAL)) TOTAL_SUM_ACC
                        FROM (SELECT DISTINCT
                                     LNP.LNPRDAC_PROD_CODE,
                                     LNP.LNPRDAC_INT_ACCR_GL
                                FROM LNPRODACPM LNP) LNPRO,
                             (  SELECT A.ACNTS_PROD_CODE,
                                       SUM (L.LOANIA_INT_ON_AMT) TOTAL
                                  FROM MIG_ACNTS A, TEMP_LOANIA L
                                 WHERE     L.LOANIA_ACNT_NUM = A.ACNTS_ACNUM
                                       AND L.LOANIA_ACNT_NUM IN
                                              (SELECT LL.LNACNT_ACNUM
                                                 FROM MIG_LNACNT LL
                                                WHERE LL.LNACNT_ASSET_STAT IN
                                                         ('UC', 'SM'))
                              GROUP BY A.ACNTS_PROD_CODE) AC
                       WHERE AC.ACNTS_PROD_CODE = LNPRO.LNPRDAC_PROD_CODE
                    GROUP BY LNPRO.LNPRDAC_INT_ACCR_GL
                    MINUS
                      SELECT 'LOAN' SL,
                             N.GLOP_GL_HEAD,
                             SUM (N.GLOP_BALANCE) TOTAL_SUM_GL
                        FROM MIG_GLOP_BAL N
                       WHERE N.GLOP_GL_HEAD IN
                                (SELECT DISTINCT LNPRODACPM.LNPRDAC_INT_ACCR_GL
                                   FROM LNPRODACPM)
                    GROUP BY N.GLOP_GL_HEAD)))
    WHERE TOTAL_SUM_GL <> 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'TEMP_LOANIA, MIG_GLOP_BAL',
                     W_ROWCOUNT,
                     'LOAN ACCRUAL MISMATCH',
                     '(SELECT ''GL'' SL, N.GLOP_GL_HEAD, SUM(N.GLOP_BALANCE) TOTAL_SUM_GL
           FROM MIG_GLOP_BAL N
          WHERE N.GLOP_GL_HEAD IN (SELECT DISTINCT LNPRODACPM.LNPRDAC_INT_ACCR_GL
                                     FROM LNPRODACPM)
          GROUP BY N.GLOP_GL_HEAD
         
         MINUS
         
         SELECT ''GL'' SL,
                LNPRO.LNPRDAC_INT_ACCR_GL,
                (-1) * ABS(SUM(AC.TOTAL)) TOTAL_SUM_ACC
           FROM (SELECT DISTINCT LNP.LNPRDAC_PROD_CODE,
                                 LNP.LNPRDAC_INT_ACCR_GL
                   FROM LNPRODACPM LNP) LNPRO,
                (SELECT A.ACNTS_PROD_CODE, SUM(L.LOANIA_INT_ON_AMT) TOTAL
                   FROM MIG_ACNTS A, TEMP_LOANIA L
                  WHERE L.LOANIA_ACNT_NUM = A.ACNTS_ACNUM
                    AND L.LOANIA_ACNT_NUM IN
                        (SELECT LL.LNACNT_ACNUM
                           FROM MIG_LNACNT LL
                          WHERE LL.LNACNT_ASSET_STAT IN (''UC'', ''SM''))
                  GROUP BY A.ACNTS_PROD_CODE) AC
          WHERE AC.ACNTS_PROD_CODE = LNPRO.LNPRDAC_PROD_CODE
          GROUP BY LNPRO.LNPRDAC_INT_ACCR_GL)
       
        UNION
       
        (SELECT ''LOAN'' SL,
                LNPRO.LNPRDAC_INT_ACCR_GL,
                (-1) * ABS(SUM(AC.TOTAL)) TOTAL_SUM_ACC
           FROM (SELECT DISTINCT LNP.LNPRDAC_PROD_CODE,
                                 LNP.LNPRDAC_INT_ACCR_GL
                   FROM LNPRODACPM LNP) LNPRO,
                (SELECT A.ACNTS_PROD_CODE, SUM(L.LOANIA_INT_ON_AMT) TOTAL
                   FROM MIG_ACNTS A, TEMP_LOANIA L
                  WHERE L.LOANIA_ACNT_NUM = A.ACNTS_ACNUM
                    AND L.LOANIA_ACNT_NUM IN
                        (SELECT LL.LNACNT_ACNUM
                           FROM MIG_LNACNT LL
                          WHERE LL.LNACNT_ASSET_STAT IN (''UC'', ''SM''))
                  GROUP BY A.ACNTS_PROD_CODE) AC
          WHERE AC.ACNTS_PROD_CODE = LNPRO.LNPRDAC_PROD_CODE
          GROUP BY LNPRO.LNPRDAC_INT_ACCR_GL
         
         MINUS
         
         SELECT ''LOAN'' SL, N.GLOP_GL_HEAD, SUM(N.GLOP_BALANCE) TOTAL_SUM_GL
           FROM MIG_GLOP_BAL N
          WHERE N.GLOP_GL_HEAD IN (SELECT DISTINCT LNPRODACPM.LNPRDAC_INT_ACCR_GL
                                     FROM LNPRODACPM)
          GROUP BY N.GLOP_GL_HEAD );');
   END IF;

   --- savings accrual matching
   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM (SELECT *
             FROM ( (  SELECT 'SAVINGS' SL,
                              RAPARAM_CRINT_ACCRUAL_GL,
                              SUM (SBCAIA_AC_INT_ACCR_AMT)
                                 TOTAL_SAVINGS_ACCR_AMOUNT
                         FROM (SELECT T.SBCAIA_INTERNAL_ACNUM,
                                      A.ACNTS_AC_TYPE,
                                      RA.RAPARAM_CRINT_ACCRUAL_GL,
                                      T.SBCAIA_AC_INT_ACCR_AMT
                                 FROM TEMP_SBCAIA T, MIG_ACNTS A, RAPARAM RA
                                WHERE     T.SBCAIA_INTERNAL_ACNUM =
                                             A.ACNTS_ACNUM
                                      AND RA.RAPARAM_AC_TYPE = A.ACNTS_AC_TYPE)
                     GROUP BY RAPARAM_CRINT_ACCRUAL_GL
                     MINUS
                       SELECT 'SAVINGS' SL,
                              N.GLOP_GL_HEAD,
                              SUM (N.GLOP_BALANCE) GL_BALANCE
                         FROM MIG_GLOP_BAL N
                        WHERE N.GLOP_GL_HEAD IN
                                 (SELECT DISTINCT RA.RAPARAM_CRINT_ACCRUAL_GL
                                    FROM RAPARAM RA
                                   WHERE RA.RAPARAM_CRINT_ACCRUAL_GL
                                            IS NOT NULL)
                     GROUP BY N.GLOP_GL_HEAD)
                   UNION
                   (  SELECT 'GL' SL,
                             N.GLOP_GL_HEAD,
                             SUM (N.GLOP_BALANCE) GL_BALANCE
                        FROM MIG_GLOP_BAL N
                       WHERE N.GLOP_GL_HEAD IN
                                (SELECT DISTINCT RA.RAPARAM_CRINT_ACCRUAL_GL
                                   FROM RAPARAM RA
                                  WHERE RA.RAPARAM_CRINT_ACCRUAL_GL IS NOT NULL)
                    GROUP BY N.GLOP_GL_HEAD
                    MINUS
                      SELECT 'GL' SL,
                             RAPARAM_CRINT_ACCRUAL_GL,
                             SUM (SBCAIA_AC_INT_ACCR_AMT)
                                TOTAL_SAVINGS_ACCR_AMOUNT
                        FROM (SELECT T.SBCAIA_INTERNAL_ACNUM,
                                     A.ACNTS_AC_TYPE,
                                     RA.RAPARAM_CRINT_ACCRUAL_GL,
                                     T.SBCAIA_AC_INT_ACCR_AMT
                                FROM TEMP_SBCAIA T, MIG_ACNTS A, RAPARAM RA
                               WHERE     T.SBCAIA_INTERNAL_ACNUM =
                                            A.ACNTS_ACNUM
                                     AND RA.RAPARAM_AC_TYPE = A.ACNTS_AC_TYPE)
                    GROUP BY RAPARAM_CRINT_ACCRUAL_GL)))
    WHERE TOTAL_SAVINGS_ACCR_AMOUNT <> 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'TEMP_SBCAIA, MIG_GLOP_BAL',
                     W_ROWCOUNT,
                     'SAVINGS ACCRUAL MISMATCH',
                     '(SELECT ''SAVINGS'' SL, RAPARAM_CRINT_ACCRUAL_GL,
                       SUM(SBCAIA_AC_INT_ACCR_AMT) TOTAL_SAVINGS_ACCR_AMOUNT
                  FROM (SELECT T.SBCAIA_INTERNAL_ACNUM,
                               A.ACNTS_AC_TYPE,
                               RA.RAPARAM_CRINT_ACCRUAL_GL,
                               T.SBCAIA_AC_INT_ACCR_AMT
                          FROM TEMP_SBCAIA T, MIG_ACNTS A, RAPARAM RA
                         WHERE T.SBCAIA_INTERNAL_ACNUM = A.ACNTS_ACNUM
                           AND RA.RAPARAM_AC_TYPE = A.ACNTS_AC_TYPE)
                 GROUP BY RAPARAM_CRINT_ACCRUAL_GL
        
        MINUS
        
      SELECT ''SAVINGS'' SL,  N.GLOP_GL_HEAD, SUM(N.GLOP_BALANCE) GL_BALANCE
           FROM MIG_GLOP_BAL N
          WHERE N.GLOP_GL_HEAD IN
                (SELECT DISTINCT RA.RAPARAM_CRINT_ACCRUAL_GL
                   FROM RAPARAM RA
                  WHERE RA.RAPARAM_CRINT_ACCRUAL_GL IS NOT NULL)
          GROUP BY N.GLOP_GL_HEAD
         )

UNION

(SELECT ''GL'' SL, N.GLOP_GL_HEAD, SUM(N.GLOP_BALANCE) GL_BALANCE
           FROM MIG_GLOP_BAL N
          WHERE N.GLOP_GL_HEAD IN
                (SELECT DISTINCT RA.RAPARAM_CRINT_ACCRUAL_GL
                   FROM RAPARAM RA
                  WHERE RA.RAPARAM_CRINT_ACCRUAL_GL IS NOT NULL)
          GROUP BY N.GLOP_GL_HEAD
          
        MINUS
        
      SELECT ''GL'' SL,  RAPARAM_CRINT_ACCRUAL_GL,
                       SUM(SBCAIA_AC_INT_ACCR_AMT) TOTAL_SAVINGS_ACCR_AMOUNT
                  FROM (SELECT T.SBCAIA_INTERNAL_ACNUM,
                               A.ACNTS_AC_TYPE,
                               RA.RAPARAM_CRINT_ACCRUAL_GL,
                               T.SBCAIA_AC_INT_ACCR_AMT
                          FROM TEMP_SBCAIA T, MIG_ACNTS A, RAPARAM RA
                         WHERE T.SBCAIA_INTERNAL_ACNUM = A.ACNTS_ACNUM
                           AND RA.RAPARAM_AC_TYPE = A.ACNTS_AC_TYPE)
                 GROUP BY RAPARAM_CRINT_ACCRUAL_GL );');
   END IF;

   ----------------------------------------------------------------------------------------

   --- PO BALANCE CHECKING

   --  V_INST NUMBER ;
   --  V_GL_BAL NUMBER ;
   SELECT NVL (SUM (D.DDPOISS_INST_AMT), 0)
     INTO V_INST
     FROM MIG_DDPO D
    WHERE D.DDPOISS_REMIT_CODE = '1';

   BEGIN
        SELECT NVL (SUM (GLOP_BALANCE), 0)
          INTO V_GL_BAL
          FROM MIG_GLOP_BAL
         WHERE GLOP_GL_HEAD = '134104101'
      GROUP BY GLOP_GL_HEAD;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_GL_BAL := 0;
   END;

   IF V_INST - V_GL_BAL <> 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'MIG_DDPO, MIG_GLOP_BAL',
                   ABS (V_INST - V_GL_BAL),
                   'PO BALANCE MISMATCH WITH GL BALANCE',
                   'select ''Balance_from_PO'', sum(d.ddpoiss_inst_amt)
  from mig_ddpo d
 where d.ddpoiss_remit_code = ''1''
union
select ''Balance_from_GL'', g.glop_balance
  from mig_glop_bal g
 where g.glop_gl_head = ''134104101'';
');
   END IF;

   --- DD BALANCE CHECKING
   SELECT NVL (SUM (D.DDPOISS_INST_AMT), 0)
     INTO V_INST
     FROM MIG_DDPO D
    WHERE D.DDPOISS_REMIT_CODE = '2';

   BEGIN
        SELECT NVL (SUM (GLOP_BALANCE), 0)
          INTO V_GL_BAL
          FROM MIG_GLOP_BAL
         WHERE GLOP_GL_HEAD = '134101101'
      GROUP BY GLOP_GL_HEAD;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_GL_BAL := 0;
   END;

   IF V_INST - V_GL_BAL <> 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'MIG_DDPO, MIG_GLOP_BAL',
                   ABS (V_INST - V_GL_BAL),
                   'DD BALANCE MISMATCH WITH GL BALANCE',
                   'select ''Balance_from_DD'', sum(d.ddpoiss_inst_amt)
  from mig_ddpo d
 where d.ddpoiss_remit_code = ''2''
union
select ''Balance_from_GL'', g.glop_balance
  from mig_glop_bal g
 where g.glop_gl_head = ''134101101'';');
   END IF;


  ---GOVT DD BALANCE CHECKING ADDED BY SABUJ
   SELECT NVL (SUM (D.DDPOISS_INST_AMT), 0)
     INTO V_INST
     FROM MIG_DDPO D
    WHERE D.DDPOISS_REMIT_CODE = '3';

   BEGIN
        SELECT NVL (SUM (GLOP_BALANCE), 0)
          INTO V_GL_BAL
          FROM MIG_GLOP_BAL
         WHERE GLOP_GL_HEAD = '134101104'
      GROUP BY GLOP_GL_HEAD;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_GL_BAL := 0;
   END;

   IF V_INST - V_GL_BAL <> 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'MIG_DDPO, MIG_GLOP_BAL',
                   ABS (V_INST - V_GL_BAL),
                   'GOVT DD BALANCE MISMATCH WITH GL BALANCE',
                   'select ''Balance_from_DD'', sum(d.ddpoiss_inst_amt)
  from mig_ddpo d
 where d.ddpoiss_remit_code = ''3''
union
select ''Balance_from_GL'', g.glop_balance
  from mig_glop_bal g
 where g.glop_gl_head = ''134101104'';');
   END IF;
   
   --- DDX BALANCE CHECKING

   SELECT NVL (SUM (D.DDPOISS_INST_AMT), 0)
     INTO V_INST
     FROM MIG_DDPO D
    WHERE D.DDPOISS_REMIT_CODE = '2' AND D.DDPOISS_PAYMENT_DATE IS NOT NULL;

   BEGIN
        SELECT NVL (SUM (GLOP_BALANCE), 0)
          INTO V_GL_BAL
          FROM MIG_GLOP_BAL
         WHERE GLOP_GL_HEAD = '225107101'
      GROUP BY GLOP_GL_HEAD;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_GL_BAL := 0;
   END;

   IF V_INST - V_GL_BAL <> 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'MIG_DDPO, MIG_GLOP_BAL',
                   ABS (V_INST - V_GL_BAL),
                   'DD BALANCE MISMATCH WITH GL BALANCE',
                   'select ''Balance_from_DDX'', sum(d.ddpoiss_inst_amt)
  from mig_ddpo d
 where d.ddpoiss_remit_code = ''2''
   and d.ddpoiss_payment_date is not null
union
select ''Balance_from_GL'', g.glop_balance
  from mig_glop_bal g
 where g.glop_gl_head = ''225107101'';');
   END IF;

   --- CALL DEPOSIT BALANCE CHECKING

   SELECT NVL (SUM (D.DDPOISS_INST_AMT), 0)
     INTO V_INST
     FROM MIG_DDPO D
    WHERE D.DDPOISS_REMIT_CODE = '10';

   BEGIN
        SELECT NVL (SUM (GLOP_BALANCE), 0)
          INTO V_GL_BAL
          FROM MIG_GLOP_BAL
         WHERE GLOP_GL_HEAD = '125101101'
      GROUP BY GLOP_GL_HEAD;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_GL_BAL := 0;
   END;

   IF V_INST - V_GL_BAL <> 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_DDPO, MIG_GLOP_BAL',
                     ABS (V_INST - V_GL_BAL),
                     'CALL DEPOSIT BALANCE MISMATCH WITH GL BALANCE',
                     'select ''Balance_from_call_depostite'', sum(d.ddpoiss_inst_amt)
  from mig_ddpo d
 where d.ddpoiss_remit_code = ''10''
union
select ''Balance_from_GL'', g.glop_balance
  from mig_glop_bal g
 where g.glop_gl_head = ''125101101'';');
   END IF;

   --- LOAN SUSPENSE BALANCE CHECKING

   SELECT NVL (SUM (GLOP_BALANCE), 0)
     INTO V_GL_BAL
     FROM MIG_GLOP_BAL
    WHERE GLOP_GL_HEAD = '140107101';

   SELECT NVL (SUM (LNSUSP_AMOUNT), 0) INTO V_INST FROM MIG_LNSUSP;

   IF V_INST - V_GL_BAL <> 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_LNSUSP, MIG_GLOP_BAL',
                     ABS (V_INST - V_GL_BAL),
                     'LOAN SUSPENSE BALANCE MISMATCH WITH GL BALANCE',
                     'SELECT GLOP_BALANCE, SUSPENSE_AMOUNT, GLOP_BALANCE - SUSPENSE_AMOUNT
  FROM (SELECT GLOP_BALANCE
          FROM MIG_GLOP_BAL
         WHERE GLOP_GL_HEAD = ''140107101''),
       (SELECT nvl(SUM(LNSUSP_AMOUNT), 0) SUSPENSE_AMOUNT FROM MIG_LNSUSP)
 WHERE GLOP_BALANCE <> SUSPENSE_AMOUNT ;');
   END IF;

   ---- WRITE-OFF BALANCE CHECK

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_WRITEOFF W
    WHERE W.LNWRTOFF_ACNT_NUM NOT IN
             (SELECT MIG_ACNTS.ACNTS_ACNUM FROM MIG_ACNTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'MIG_WRITEOFF',
                   W_ROWCOUNT,
                   'MIG_WRITEOFF ACCOUNT NUMBER NOT PRESENT IN MIG_ACNTS',
                   'SELECT *
  FROM MIG_WRITEOFF W
 WHERE W.LNWRTOFF_ACNT_NUM NOT IN
       (SELECT MIG_ACNTS.ACNTS_ACNUM FROM MIG_ACNTS);');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_WRITEOFF_RECOV W
    WHERE W.LNWRTOFFREC_LN_ACNUM NOT IN
             (SELECT MIG_ACNTS.ACNTS_ACNUM FROM MIG_ACNTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_WRITEOFF_RECOV',
                     W_ROWCOUNT,
                     'MIG_WRITEOFF_RECOV ACCOUNT NUMBER NOT PRESENT IN MIG_ACNTS',
                     'SELECT *
  FROM MIG_WRITEOFF_RECOV W
 WHERE W.LNWRTOFFREC_LN_ACNUM NOT IN
       (SELECT MIG_ACNTS.ACNTS_ACNUM FROM MIG_ACNTS);');
   END IF;

   SELECT NVL (SUM (W.LNWRTOFF_WRTOFF_AMT), 0)
     INTO V_BALACE_FROM_WRITEOFF
     FROM MIG_WRITEOFF W;

   SELECT NVL (SUM (W.LNWRTOFFREC_RECOV_AMT), 0)
     INTO V_BALACE_FROM_WRECOVERY
     FROM MIG_WRITEOFF_RECOV W;

   SELECT NVL (SUM (G.GLOP_BALANCE), 0)
     INTO V_BAL_FROM_GL
     FROM MIG_GLOP_BAL G
    WHERE G.GLOP_GL_HEAD = '516101101';

   IF V_BALACE_FROM_WRITEOFF - V_BALACE_FROM_WRECOVERY <> V_BAL_FROM_GL
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'WRITEOFF',
                     ABS (
                          (V_BALACE_FROM_WRITEOFF - V_BALACE_FROM_WRECOVERY)
                        - V_BAL_FROM_GL),
                     'WRITE-OFF balance did not match with A/C and GL',
                     'select ''ACC'' id,
       (select sum(r.lnwrtoff_wrtoff_amt) from mig_writeoff r) -
       (select nvl(sum(r.lnwrtoffrec_recov_amt),0) from mig_writeoff_recov r)
  from dual
union all
select ''GL'' id, sum(g.glop_balance)
  From mig_glop_bal g
 where g.glop_gl_head = ''516101101'';');
   END IF;

   --- cheque insert

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_STOPCHQ S
    WHERE (S.STOPCHQ_ACNUM, S.STOPCHQ_FROM_CHQ_NUM) NOT IN
             (SELECT C.CBISS_ACNUM, C.CBISS_FROM_LEAF_NUM
                FROM MIG_CHEQUE C);

   IF W_ROWCOUNT > 0
   THEN
      BEGIN
         SP_CHEQUE_INSERT;
      END;
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE LNACNT_OUTSTANDING_BALANCE < 0 AND LNACNT_PRIN_OS > 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_LNACNT',
                     W_ROWCOUNT,
                     'LNACNT_PRIN_OS MUST BE LESS THAN OR EQUAL TO 0',
                     'SELECT LNACNT_ACNUM ,LNACNT_OUTSTANDING_BALANCE, LNACNT_PRIN_OS FROM MIG_LNACNT WHERE LNACNT_OUTSTANDING_BALANCE < 0
AND LNACNT_PRIN_OS > 0;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE LNACNT_OUTSTANDING_BALANCE < 0 AND LNACNT_INT_OS > 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_LNACNT',
                     W_ROWCOUNT,
                     'LNACNT_INT_OS MUST BE LESS THAN OR EQUAL TO 0',
                     'SELECT LNACNT_ACNUM ,LNACNT_OUTSTANDING_BALANCE, LNACNT_INT_OS FROM MIG_LNACNT WHERE LNACNT_OUTSTANDING_BALANCE < 0
AND LNACNT_INT_OS > 0;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT
    WHERE LNACNT_OUTSTANDING_BALANCE < 0 AND LNACNT_CHG_OS > 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_LNACNT',
                     W_ROWCOUNT,
                     'LNACNT_CHG_OS MUST BE LESS THAN OR EQUAL TO 0',
                     'SELECT LNACNT_ACNUM ,LNACNT_OUTSTANDING_BALANCE, LNACNT_CHG_OS FROM MIG_LNACNT WHERE LNACNT_OUTSTANDING_BALANCE < 0
AND LNACNT_CHG_OS > 0;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_SEC_REGIS_TEMP S, MIG_ACNTS A
    WHERE     S.SECRCPT_SEC_TYPE = 76
          AND S.SECRCPT_CLIENT_NUM = A.ACNTS_CLIENT_NUM
          AND S.SECRCPT_CLIENT_NUM NOT IN
                 (SELECT LL.LNACNT_CLIENT_NUM
                    FROM MIG_LNACGUAR L, MIG_LNACNT LL
                   WHERE L.LNACGUAR_ACNUM = LL.LNACNT_ACNUM);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_LNACGUAR',
                     W_ROWCOUNT,
                     'THERE SHOULD BE A GURRENTOR FOR SECURITY CODE 76',
                     'SELECT ACNTS_ACNUM,
       ACNTS_PROD_CODE,
       ACNTS_AC_TYPE,
       ACNTS_OPENING_DATE,
       SECRCPT_SEC_TYPE
  FROM MIG_SEC_REGIS_TEMP S, MIG_ACNTS A
 WHERE     S.SECRCPT_SEC_TYPE = 76
       AND S.SECRCPT_CLIENT_NUM = A.ACNTS_CLIENT_NUM
       AND S.SECRCPT_CLIENT_NUM NOT IN
              (SELECT LL.LNACNT_CLIENT_NUM
                 FROM MIG_LNACGUAR L, MIG_LNACNT LL
                WHERE L.LNACGUAR_ACNUM = LL.LNACNT_ACNUM);
                
                
  UPDATE MIG_SEC_REGIS_TEMP S
   SET S.SECRCPT_SEC_TYPE = ''79''
 WHERE S.SECRCPT_CLIENT_NUM IN
       (SELECT A.ACNTS_CLIENT_NUM
          FROM MIG_SEC_REGIS_TEMP S, MIG_ACNTS A
         WHERE S.SECRCPT_SEC_TYPE = 76
           AND S.SECRCPT_CLIENT_NUM = A.ACNTS_CLIENT_NUM
           AND S.SECRCPT_CLIENT_NUM NOT IN
               (SELECT LL.LNACNT_CLIENT_NUM
                  FROM MIG_LNACGUAR L, MIG_LNACNT LL
                 WHERE L.LNACGUAR_ACNUM = LL.LNACNT_ACNUM));

                
  ');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT M, MIG_ACNTS A
    WHERE     M.LNACNT_ASSET_STAT = 'BL'
          AND M.LNACNT_ACNUM = A.ACNTS_ACNUM
          AND M.LNACNT_ACNUM NOT IN (SELECT B.MIG_BLLOANIA_ACNUM
                                       FROM MIG_BLLOANIA B
                                      WHERE B.MIG_BLLOANIA_AMOUNT <> 0);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_BLLOANIA',
                     W_ROWCOUNT,
                     'THERE SHOULD BE AN UNAPPLIED INTEREST FOR BL LOAN',
                     'SELECT ACNTS_ACNUM,
       ACNTS_PROD_CODE,
       ACNTS_AC_TYPE,
       ACNTS_OPENING_DATE
  FROM MIG_LNACNT M, MIG_ACNTS A
 WHERE     M.LNACNT_ASSET_STAT = ''BL''
       AND M.LNACNT_ACNUM = A.ACNTS_ACNUM
       AND M.LNACNT_ACNUM NOT IN (SELECT B.MIG_BLLOANIA_ACNUM
                                    FROM MIG_BLLOANIA B);');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_ACNTS A, MIG_LNACNT L, LNPRODPM LP
    WHERE     A.ACNTS_ACNUM = L.LNACNT_ACNUM
          AND LP.LNPRD_PROD_CODE = A.ACNTS_PROD_CODE
          AND LP.LNPRD_INT_APPL_FREQ = 'Q'
          AND A.ACNTS_OPENING_DATE < FN_FIND_QUARTER_END_DATE (W_MIG_DATE)
          AND NVL (L.TOTAL_INT_DEBIT, 0) = 0
          AND A.ACNTS_PROD_CODE IN
                 (SELECT P.PRODUCT_CODE
                    FROM PRODUCTS P
                   WHERE     P.PRODUCT_FOR_LOANS = 1
                         AND P.PRODUCT_FOR_RUN_ACS = 0);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_LNACNT',
                     W_ROWCOUNT,
                     'THERE SHOULD BE A TOTAL INTEREST DEBIT FOR QUARTARLY LOAN ACCOUNT THAT IS OPENED BEFORE THIS QUARTER END DATE',
                        'SELECT A.ACNTS_ACNUM,
       A.ACNTS_OPENING_DATE,
       A.ACNTS_PROD_CODE,
       A.ACNTS_AC_TYPE,
       L.TOTAL_INT_DEBIT
  FROM MIG_ACNTS A, MIG_LNACNT L, LNPRODPM LP
 WHERE A.ACNTS_ACNUM = L.LNACNT_ACNUM
 AND LP.LNPRD_PROD_CODE = A.ACNTS_PROD_CODE
 AND LP.LNPRD_INT_APPL_FREQ = ''Q''
 AND A.ACNTS_OPENING_DATE < FN_FIND_QUARTER_END_DATE('
                     || ''''
                     || W_MIG_DATE
                     || ''''
                     || ')
   AND NVL(L.TOTAL_INT_DEBIT, 0) = 0
   AND A.ACNTS_PROD_CODE IN
       (SELECT P.PRODUCT_CODE
          FROM PRODUCTS P
         WHERE P.PRODUCT_FOR_LOANS = 1
           AND P.PRODUCT_FOR_RUN_ACS = 0);');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_ACNTS A, MIG_LNACNT L, LNPRODPM LP
    WHERE     A.ACNTS_ACNUM = L.LNACNT_ACNUM
          AND LP.LNPRD_PROD_CODE = A.ACNTS_PROD_CODE
          AND LP.LNPRD_INT_APPL_FREQ = 'Y'
          AND A.ACNTS_OPENING_DATE < TRUNC (TO_DATE (W_MIG_DATE), 'Y')
          --TRUNC(TO_DATE(W_MIG_DATE), 'Y')
          AND NVL (L.TOTAL_INT_DEBIT, 0) = 0
          AND A.ACNTS_PROD_CODE IN
                 (SELECT P.PRODUCT_CODE
                    FROM PRODUCTS P
                   WHERE     P.PRODUCT_FOR_LOANS = 1
                         AND P.PRODUCT_FOR_RUN_ACS = 0);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_LNACNT',
                     W_ROWCOUNT,
                     'THERE SHOULD BE A TOTAL INTEREST DEBIT FOR YEARLY LOAN ACCOUNT THAT IS OPENED BEFORE THIS YEAR',
                        'SELECT A.ACNTS_ACNUM,
       A.ACNTS_OPENING_DATE,
       A.ACNTS_PROD_CODE,
       A.ACNTS_AC_TYPE,
       L.TOTAL_INT_DEBIT
  FROM MIG_ACNTS A, MIG_LNACNT L, LNPRODPM LP
 WHERE A.ACNTS_ACNUM = L.LNACNT_ACNUM
 AND LP.LNPRD_PROD_CODE = A.ACNTS_PROD_CODE
 AND LP.LNPRD_INT_APPL_FREQ = ''Y''
 AND A.ACNTS_OPENING_DATE < TRUNC(TO_DATE('
                     || ''''
                     || W_MIG_DATE
                     || ''''
                     || '), ''Y'')
   AND NVL(L.TOTAL_INT_DEBIT, 0) = 0
   AND A.ACNTS_PROD_CODE IN
       (SELECT P.PRODUCT_CODE
          FROM PRODUCTS P
         WHERE P.PRODUCT_FOR_LOANS = 1
           AND P.PRODUCT_FOR_RUN_ACS = 0);');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_GLOP_BAL G
    WHERE     G.GLOP_GL_HEAD IN (SELECT D.DEPPRCUR_INT_ACCR_GLACC
                                   FROM DEPPRODCUR D
                                 UNION ALL
                                 SELECT R.RAPARAM_CRINT_ACCRUAL_GL
                                   FROM RAPARAM R)
          AND G.GLOP_BALANCE < 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'GLOP_BALANCE',
                     W_ROWCOUNT,
                     'GLOP_BALANCE BALANCE MUST BE POSETIVE',
                     'SELECT *
  FROM MIG_GLOP_BAL G
 WHERE G.GLOP_GL_HEAD IN (SELECT D.DEPPRCUR_INT_ACCR_GLACC
                            FROM DEPPRODCUR D
                          UNION ALL
                          SELECT R.RAPARAM_CRINT_ACCRUAL_GL
                            FROM RAPARAM R)
   AND G.GLOP_BALANCE < 0;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_GLOP_BAL G
    WHERE     G.GLOP_GL_HEAD IN (SELECT L.LNPRDAC_INT_ACCR_GL
                                   FROM LNPRODACPM L)
          AND G.GLOP_BALANCE > 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'GLOP_BALANCE',
                     W_ROWCOUNT,
                     'GLOP_BALANCE BALANCE MUST BE NEGATIVE',
                     'SELECT *
  FROM MIG_GLOP_BAL G
 WHERE G.GLOP_GL_HEAD IN (SELECT L.LNPRDAC_INT_ACCR_GL FROM LNPRODACPM L)
   AND G.GLOP_BALANCE > 0;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACRSDTL_TEMP L
    WHERE L.LNACRSDTL_ACNUM NOT IN (SELECT LL.LNACNT_ACNUM
                                      FROM MIG_LNACNT LL);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'LNACRSDTL_ACNUM',
                     W_ROWCOUNT,
                     'LNACRSDTL_ACNUM NOT FOUND IN MIG_LNACNT',
                     'SELECT L.LNACRSDTL_ACNUM,L.LNACRS_EFF_DATE,L.LNACRSDTL_NUM_OF_INSTALLMENT
  FROM MIG_LNACRSDTL_TEMP L
 WHERE L.LNACRSDTL_ACNUM NOT IN (SELECT LL.LNACNT_ACNUM FROM MIG_LNACNT LL);');
   END IF;

   -----------------------------rechedule loan checking------------------

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT L, MIG_LNACRSDTL_TEMP LL, MIG_ACNTS A
    WHERE     L.LNACNT_ACNUM = LL.LNACRSDTL_ACNUM
          AND L.LNACNT_ACNUM = A.ACNTS_ACNUM
          AND L.LNACNT_ASSET_STAT NOT IN ( 'UC', 'ST');

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'LNACNT_ASSET_STAT',
                   W_ROWCOUNT,
                   ' RESCHEDULE LOAN SHOULD BE UC',
                   'SELECT LL.LNACRSDTL_ACNUM,
       L.LNACNT_ASSET_STAT,
       A.ACNTS_PROD_CODE,
       A.ACNTS_AC_TYPE
  From MIG_LNACNT L, MIG_LNACRSDTL_TEMP LL, MIG_ACNTS A
 Where L.LNACNT_ACNUM = LL.LNACRSDTL_ACNUM
   AND l.lnacnt_acnum = A.ACNTS_ACNUM
   And L.LNACNT_ASSET_STAT NOT IN ( ''UC'', ''ST'');
 ');
   END IF;

   ------ACOP_BALANCE AND LNACNT_OUTSTANDING_BALANCE MISMATCH------

   SELECT COUNT (*)
     INTO W_RowCount
     FROM MIG_ACOP_BAL A, MIG_LNACNT L
    WHERE     A.ACOP_AC_NUM = L.LNACNT_ACNUM
          AND A.ACOP_BALANCE <> L.LNACNT_OUTSTANDING_BALANCE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'LNACNT_OUTSTANDING_BALANCE',
                     W_ROWCOUNT,
                     'ACOP_BALANCE AND LNACNT_OUTSTANDING_BALANCE SHOULD BE EQUAL',
                     'SELECT A.ACOP_AC_NUM,A.ACOP_BALANCE,L.LNACNT_OUTSTANDING_BALANCE
  FROM MIG_ACOP_BAL A, MIG_LNACNT L
 WHERE A.ACOP_AC_NUM = L.LNACNT_ACNUM
   AND A.ACOP_BALANCE <> L.LNACNT_OUTSTANDING_BALANCE;
 ');
   END IF;

   --------MONTHS TO BL check for  Reschedule ---------------

   SELECT COUNT (*)
     INTO W_RowCount
     FROM MIG_LNACRSDTL_TEMP L, LNPRODPM LL, MIG_ACNTS A
    WHERE     A.ACNTS_ACNUM = L.LNACRSDTL_ACNUM
          AND A.ACNTS_PROD_CODE = LL.LNPRD_PROD_CODE
          AND LL.LNPRD_PROD_FOR_RESCHEDULE = 1
          AND NVL (L.LNACRSDTL_MONTHS_TO_BL, 0) = 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'LNACRSDTL_MONTHS_TO_BL',
                     W_ROWCOUNT,
                     'THERE SHOULD BE VALUE IN LNACRSDTL_MONTHS_TO_BL FOR RESCHEDULE LOAN',
                     'SELECT A.ACNTS_ACNUM, LL.LNPRD_PROD_CODE, A.ACNTS_AC_TYPE
  FROM MIG_LNACRSDTL_TEMP L, LNPRODPM LL, MIG_ACNTS A
 WHERE A.ACNTS_ACNUM = L.LNACRSDTL_ACNUM
   AND A.ACNTS_PROD_CODE = LL.LNPRD_PROD_CODE
   AND LL.LNPRD_PROD_FOR_RESCHEDULE = 1
   AND NVL(L.LNACRSDTL_MONTHS_TO_BL, 0) = 0;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_ACNTS, MIG_LNACRSDTL_TEMP
    WHERE     ACNTS_ACNUM = LNACRSDTL_ACNUM
          AND ACNTS_PROD_CODE IN
                 (SELECT PRODUCT_CODE
                    FROM PRODUCTS
                   WHERE PRODUCT_FOR_LOANS = 1 AND PRODUCT_FOR_RUN_ACS = 1);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'ACNTS_PROD_CODE',
                     W_ROWCOUNT,
                     'RESCHEDULE LOAN SHOULD BE A TERM LOAN',
                     'SELECT ACNTS_ACNUM,
       ACNTS_BRN_CODE,
       ACNTS_PROD_CODE,
       ACNTS_AC_TYPE,
       ACNTS_OPENING_DATE,
       LNACRS_REPH_ON_AMT,
       LNACRSDTL_REPAY_FREQ,
       LNACRSDTL_REPAY_FROM_DATE,
       LNACRSDTL_NUM_OF_INSTALLMENT
  FROM MIG_ACNTS, MIG_LNACRSDTL_TEMP
 WHERE     ACNTS_ACNUM = LNACRSDTL_ACNUM
       AND ACNTS_PROD_CODE IN
              (SELECT PRODUCT_CODE
                 FROM PRODUCTS
                WHERE PRODUCT_FOR_LOANS = 1 AND PRODUCT_FOR_RUN_ACS = 1) ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_ACNTS
    WHERE     ACNTS_PROD_CODE IN (SELECT LNPRD_PROD_CODE
                                    FROM LNPRODPM
                                   WHERE LNPRD_DRAWING_POWER_REQ = 1)
          AND ACNTS_ACNUM NOT IN (SELECT LNDP_ACNUM FROM MIG_LNDP);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'LNDP_ACNUM',
                     W_ROWCOUNT,
                     'DP DATA MISSING',
                     'SELECT ACNTS_ACNUM, ACNTS_PROD_CODE, ACNTS_AC_TYPE
  FROM MIG_ACNTS
 WHERE     ACNTS_PROD_CODE IN (SELECT LNPRD_PROD_CODE
                                 FROM LNPRODPM
                                WHERE LNPRD_DRAWING_POWER_REQ = 1)
       AND ACNTS_ACNUM NOT IN (SELECT LNDP_ACNUM FROM MIG_LNDP);
       
       INSERT INTO MIG_LNDP               
SELECT L.LNACNT_ACNUM               LNDP_ACNUM,
       MIG_ACNTS.ACNTS_OPENING_DATE LNDP_EFF_DATE,
       MIG_ACNTS.ACNTS_CURR_CODE    LNDP_DP_CURR,
       0                            LNDP_DP_AMT,
       0                            LNDP_DP_AMT_AS_PER_SEC,
       L.LNACNT_LIMIT_EXPIRY_DATE   LNDP_DP_VALID_UPTO_DATE,
       L.LNACNT_LIMIT_EXPIRY_DATE   LNDP_DP_REVIEW_DUE_DATE
  FROM MIG_ACNTS, MIG_LNACNT L
 WHERE ACNTS_PROD_CODE IN
       (SELECT LNPRD_PROD_CODE
          FROM LNPRODPM
         WHERE LNPRD_DRAWING_POWER_REQ = 1)
   AND ACNTS_ACNUM NOT IN (SELECT LNDP_ACNUM FROM MIG_LNDP)
   AND MIG_ACNTS.ACNTS_ACNUM = L.LNACNT_ACNUM;
       
       
       
       
       
       ');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_ACNTS A, MIG_LNACNT L
    WHERE     A.ACNTS_ACNUM = L.LNACNT_ACNUM
          AND A.ACNTS_PROD_CODE = 2038
          AND L.LNACNT_SANCTION_AMT > 30000;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('FINAL_VALIDATION',
                   'LNACNT_SANCTION_AMT',
                   W_ROWCOUNT,
                   'LIMIT AMOUNT IS MAXIMUM 30000 FOR 2038 PRODUCT',
                   'SELECT A.ACNTS_ACNUM,
      A.ACNTS_BRN_CODE,
      A.ACNTS_PROD_CODE,
      A.ACNTS_AC_TYPE,
      A.ACNTS_OPENING_DATE,
      L.LNACNT_SANCTION_AMT
 FROM MIG_ACNTS A, MIG_LNACNT L
WHERE A.ACNTS_ACNUM = L.LNACNT_ACNUM
  AND A.ACNTS_PROD_CODE = 2038
  AND L.LNACNT_SANCTION_AMT > 30000;');
   END IF;

   ----mig_reschedule EXPIRY_DATE CHECK

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT L, MIG_LNACRSDTL_TEMP LL
    WHERE     LNACRSDTL_ACNUM = LNACNT_ACNUM
          AND LNACRSDTL_REPAY_FROM_DATE <> LNACNT_LIMIT_EXPIRY_DATE
          AND LNACRSDTL_REPAY_FREQ = 'X';

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'LNACRSDTL_REPAY_FROM_DATE',
                     W_ROWCOUNT,
                     'LNACRSDTL_REPAY_FROM_DATE AND LNACNT_LIMIT_EXPIRY_DATE MISMATCH',
                     'SELECT LNACRSDTL_ACNUM, LNACRSDTL_REPAY_FROM_DATE, LNACNT_LIMIT_EXPIRY_DATE
FROM MIG_LNACNT L, MIG_LNACRSDTL_TEMP LL
WHERE     LNACRSDTL_ACNUM = LNACNT_ACNUM
     AND LNACRSDTL_REPAY_FROM_DATE <> LNACNT_LIMIT_EXPIRY_DATE
     AND LNACRSDTL_REPAY_FREQ = ''X'' ;');
   END IF;

   ----mig_reschedule EXPIRY_DATE CHECK

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNACNT L, MONTH_FREQUENCY F, MIG_LNACRSDTL_TEMP T
    WHERE     L.LNACNT_ACNUM = T.LNACRSDTL_ACNUM
          AND F.FREQ = T.LNACRSDTL_REPAY_FREQ
          AND L.LNACNT_LIMIT_EXPIRY_DATE <>
                 ADD_MONTHS (T.LNACRSDTL_REPAY_FROM_DATE,
                             F.NO_OF_MONTH * T.LNACRSDTL_NUM_OF_INSTALLMENT)
          AND T.LNACRSDTL_REPAY_FREQ <> 'X';

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'LNACRSDTL_REPAY_FROM_DATE',
                     W_ROWCOUNT,
                     'LNACRSDTL_REPAY_FROM_DATE AND LNACNT_LIMIT_EXPIRY_DATE MISMATCH',
                     '  
SELECT LNACRSDTL_ACNUM,
     LNACRSDTL_REPAY_FREQ,
     LNACRSDTL_NUM_OF_INSTALLMENT,
     LNACRSDTL_REPAY_FROM_DATE,
     ADD_MONTHS (T.LNACRSDTL_REPAY_FROM_DATE,
                 F.NO_OF_MONTH * T.LNACRSDTL_NUM_OF_INSTALLMENT)
        EXPIRY_SHOULD_BE,
     LNACNT_LIMIT_EXPIRY_DATE,
     LNACNT_LIMIT_EXPIRY_DATE - LNACRSDTL_REPAY_FROM_DATE DAY_DIFF
FROM MIG_LNACNT L, MONTH_FREQUENCY F, MIG_LNACRSDTL_TEMP T
WHERE     L.LNACNT_ACNUM = T.LNACRSDTL_ACNUM
     AND F.FREQ = T.LNACRSDTL_REPAY_FREQ
     AND L.LNACNT_LIMIT_EXPIRY_DATE <>
            ADD_MONTHS (T.LNACRSDTL_REPAY_FROM_DATE,
                        F.NO_OF_MONTH * T.LNACRSDTL_NUM_OF_INSTALLMENT)
                        AND T.LNACRSDTL_REPAY_FREQ <>''X'';');
   END IF;

   ---MIG_ABB_CHECK checking abb allowed or not

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_ABB_CHECK C
    WHERE C.MAC_ACNUM NOT IN (SELECT M.ACNTS_ACNUM
                                FROM MIG_ACNTS M);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_ABB_CHECK',
                     'MAC_ACNUM',
                     W_ROWCOUNT,
                     'MAC_ACNUM NOT FOUND IN MIG_ACNTS ACOUNT NUMBER',
                     '  SELECT *
    FROM MIG_ABB_CHECK C
   where c.mac_acnum not in (SELECT ACNTS_ACNUM FROM MIG_ACNTS)');
   END IF;

   ---WRITE ACCOUNT CHECK
   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_WRITEOFF_RECOV R
    WHERE R.LNWRTOFFREC_LN_ACNUM NOT IN
             (SELECT LNWRTOFF_ACNT_NUM FROM MIG_WRITEOFF);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_WRITEOF',
                     'MAC_ACNUM',
                     W_ROWCOUNT,
                     'WRITEOFF RECOVERY ACCOUNT NUMBER NOT FOUND IN MIG_WRITEOFF',
                     ' SELECT * FROM MIG_WRITEOFF_RECOV R
WHERE R.LNWRTOFFREC_LN_ACNUM NOT IN (SELECT LNWRTOFF_ACNT_NUM FROM MIG_WRITEOFF)');
   END IF;

   ----END WRITE OFF CHECK
   ----WRITE OFF AND LOAN SUSPEN CHECK
   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_LNSUSP L, MIG_WRITEOFF W
    WHERE L.LNSUSP_ACNUM = W.LNWRTOFF_ACNT_NUM;

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
                   'WRITEOFF ACCOUNT BUT PRESENT  IN MIG_LNSUSP',
                   ' SELECT L.LNSUSP_ACNUM
FROM MIG_LNSUSP L,MIG_WRITEOFF W
WHERE L.LNSUSP_ACNUM=W.LNWRTOFF_ACNT_NUM');
   END IF;
  
------Mig_Blloania table only contain BL Loans

 SELECT COUNT(*)
   INTO W_ROWCOUNT
   FROM MIG_LNACNT L, MIG_BLLOANIA BL
  WHERE L.LNACNT_ACNUM = BL.MIG_BLLOANIA_ACNUM
    AND L.LNACNT_ASSET_STAT <> 'BL';
   
  IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_BLLOANIA',
                   'BLLOANIA_ACNUM',
                   W_ROWCOUNT,
                   'MIG_BLLOANIA TABLE ONLY CONTAIN BL LOANS',
                   'SELECT BL.MIG_BLLOANIA_ACNUM,L.LNACNT_ASSET_STAT
  FROM MIG_LNACNT L, MIG_BLLOANIA BL
 WHERE L.LNACNT_ACNUM = BL.MIG_BLLOANIA_ACNUM
 AND L.LNACNT_ASSET_STAT <> ''BL'';');
   END IF; 
    
   SELECT COUNT(*) INTO W_ROWCOUNT
  FROM MIG_ACNTS A, PRODUCTS P, MIG_ACOP_BAL AC
 WHERE     A.ACNTS_PROD_CODE = P.PRODUCT_CODE
       AND P.PRODUCT_FOR_DEPOSITS = 1
       AND AC.ACOP_AC_NUM = A.ACNTS_ACNUM
       AND A.ACNTS_AC_TYPE <> 'CAOD'
       AND AC.ACOP_BALANCE < 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACOP_BAL',
                     W_ROWCOUNT,
                     'DEPOSITE BALANCE SHOULD BE POSITIVE ',
                     'SELECT *
  FROM MIG_ACNTS A, PRODUCTS P, MIG_ACOP_BAL AC
 WHERE     A.ACNTS_PROD_CODE = P.PRODUCT_CODE
       AND P.PRODUCT_FOR_DEPOSITS = 1
       AND AC.ACOP_AC_NUM = A.ACNTS_ACNUM
       AND A.ACNTS_AC_TYPE <> ''CAOD''
       AND AC.ACOP_BALANCE < 0;');
   END IF;
   
   
   
   
   SELECT COUNT(*) INTO W_ROWCOUNT
  FROM PRODUCTS, LNPRODPM, MIG_ACNTS
 WHERE     PRODUCT_CODE = LNPRD_PROD_CODE
       AND LNPRD_DEPOSIT_LOAN = '1'
       AND PRODUCT_CODE = ACNTS_PROD_CODE
       AND ACNTS_ACNUM NOT IN
              (SELECT ACNTLIEN_LIEN_TO_ACNUM FROM MIG_ACNTLIEN) ;
              
  IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACNTS',
                     W_ROWCOUNT,
                     'SOD loan. But No link deposite account is given for the account',
                     'SELECT ACNTS_ACNUM,
       ACNTS_PROD_CODE,
       PRODUCT_NAME,
       ACNTS_AC_TYPE,
       ACNTS_AC_SUB_TYPE,
       ACNTS_AC_NAME1
  FROM PRODUCTS, LNPRODPM, MIG_ACNTS
 WHERE     PRODUCT_CODE = LNPRD_PROD_CODE
       AND LNPRD_DEPOSIT_LOAN = ''1''
       AND PRODUCT_CODE = ACNTS_PROD_CODE
       AND ACNTS_ACNUM NOT IN
              (SELECT ACNTLIEN_LIEN_TO_ACNUM FROM MIG_ACNTLIEN);');
   END IF;
   ---------------tp--------------------
   SELECT count(*) into W_ROWCOUNT
  FROM MIG_ACNTRNPR
 WHERE ACTP_ACNT_NUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS)

  ;
              
  IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACNTRNPR',
                     W_ROWCOUNT,
                     'TP ACCOUNT NOT PRESENT IN MAIN ACCOUNT',
                     ' SELECT ACTP_ACNT_NUM
  FROM MIG_ACNTRNPR
 WHERE ACTP_ACNT_NUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);');
   END IF;
   
   -----------TP EFFEECTIVE DATE CHECKING------------
   
 SELECT count(*) into W_ROWCOUNT
  FROM MIG_ACNTRNPR
 WHERE  MIG_ACNTRNPR.ACTP_LATEST_EFF_DATE > W_MIG_DATE;
 
 IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'FINAL_VALIDATION',
                     'MIG_ACNTRNPR',
                     W_ROWCOUNT,
                     'EFFECTIVE DATE IS GREATER THAN MIGRATION DATE FOR TP',
                     'SELECT *
  FROM MIG_ACNTRNPR
 WHERE  MIG_ACNTRNPR.ACTP_LATEST_EFF_DATE > ''' || W_MIG_DATE || ''' ;');
   END IF;
   
END SP_MACRO_FINAL;
/
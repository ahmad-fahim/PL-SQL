CREATE OR REPLACE PROCEDURE SP_PBDCONTRACT_VALIDATE (
   P_BRANCH_CODE   IN NUMBER,
   P_START_DATE    IN DATE)
IS
   W_SQL        VARCHAR2 (3000);
   W_BRN_CODE   NUMBER (5) := P_BRANCH_CODE;
   W_MIG_DATE   DATE := P_START_DATE;
   W_ROWCOUNT   NUMBER := 0;
BEGIN
   DELETE FROM ERRORLOG
         WHERE TEMPLATE_NAME = 'MIG_PBDCONTRACT';

   COMMIT;


   UPDATE MIG_PBDCONTRACT
      SET MIGDEP_INT_CR_AC_NUM =
             SUBSTR (LPAD (W_BRN_CODE, 5, 0), 1, 4) || MIGDEP_INT_CR_AC_NUM
    WHERE LENGTH (MIGDEP_INT_CR_AC_NUM) = 9;

   UPDATE MIG_PBDCONTRACT
      SET MIGDEP_INT_CR_AC_NUM =
             SUBSTR (LPAD (W_BRN_CODE, 5, 0), 1, 5) || MIGDEP_INT_CR_AC_NUM
    WHERE LENGTH (MIGDEP_INT_CR_AC_NUM) = 8;



   UPDATE MIG_PBDCONTRACT A
      SET A.MIGDEP_PROD_CODE = 1072
    WHERE A.MIGDEP_PROD_CODE = 1070 AND A.MIGDEP_EFF_DATE > '01-JAN-2014';

   COMMIT;



   UPDATE MIG_PBDCONTRACT A
      SET A.MIGDEP_PROD_CODE = 1070
    WHERE A.MIGDEP_PROD_CODE = 1072 AND A.MIGDEP_EFF_DATE < '01-JAN-2014';

   COMMIT;



   UPDATE MIG_PBDCONTRACT P
      SET P.MIGDEP_AC_INT_ACCR_AMT = 0
    WHERE P.MIGDEP_AC_INT_ACCR_AMT IS NULL;

   COMMIT;

   UPDATE MIG_PBDCONTRACT P
      SET P.MIGDEP_BC_INT_ACCR_AMT = 0
    WHERE P.MIGDEP_BC_INT_ACCR_AMT IS NULL;

   COMMIT;

   UPDATE MIG_PBDCONTRACT P
      SET P.MIGDEP_AC_INT_PAY_AMT = 0
    WHERE P.MIGDEP_AC_INT_PAY_AMT IS NULL;

   COMMIT;

   UPDATE MIG_PBDCONTRACT P
      SET P.MIGDEP_BC_INT_PAY_AMT = 0
    WHERE P.MIGDEP_BC_INT_PAY_AMT IS NULL;

   COMMIT;

   /*
   MIGDEP_INT_ACCR_UPTO, MIGDEP_INT_PAID_UPTO
   MIGDEP_MAT_DATE
   W_MIG_DATE
   */

   UPDATE MIG_PBDCONTRACT
      SET MIGDEP_INT_ACCR_UPTO = MIGDEP_MAT_DATE
    WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
          AND MIGDEP_MAT_DATE < W_MIG_DATE;

   COMMIT;

   UPDATE MIG_PBDCONTRACT
      SET MIGDEP_INT_PAID_UPTO = MIGDEP_MAT_DATE
    WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
          AND MIGDEP_MAT_DATE < W_MIG_DATE;

   COMMIT;



   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_DEP_AC_NUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_DEP_AC_NUM',
                     W_ROWCOUNT,
                     'MIGDEP_DEP_AC_NUM IS NOT PRESENT IN MIG_ACNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_DEP_AC_NUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS)');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_CR_AC_NUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_CR_AC_NUM',
                     W_ROWCOUNT,
                     'MIGDEP_INT_CR_AC_NUM IS NOT PRESENT IN MIG_ACNTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_INT_CR_AC_NUM,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_CR_AC_NUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS)');
   END IF;

   ---- checking  if MIGDEP_INT_CR_AC_NUM  in settlement accounts

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT P
    WHERE P.MIGDEP_INT_CR_AC_NUM IN
             (SELECT A.ACNTS_ACNUM
                FROM MIG_ACNTS A
               WHERE A.ACNTS_PROD_CODE IN
                        (SELECT P.PRODUCT_CODE
                           FROM PRODUCTS P
                          WHERE     P.PRODUCT_FOR_DEPOSITS = 1
                                AND P.PRODUCT_FOR_RUN_ACS = 0));

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_CR_AC_NUM',
                     W_ROWCOUNT,
                     'MIGDEP_INT_CR_AC_NUM CANNOT BE  IN SETTLEMENT ACCOUNTS',
                     ' SELECT P.MIGDEP_DEP_AC_NUM, P.MIGDEP_PROD_CODE , P.MIGDEP_INT_CR_AC_NUM
   FROM MIG_PBDCONTRACT P
  WHERE P.MIGDEP_INT_CR_AC_NUM IN
        (SELECT A.ACNTS_ACNUM
           FROM MIG_ACNTS A
          WHERE A.ACNTS_PROD_CODE IN
                (SELECT P.PRODUCT_CODE
                   FROM PRODUCTS P
                  WHERE P.PRODUCT_FOR_DEPOSITS = 1
                    AND P.PRODUCT_FOR_RUN_ACS = 0));');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_LIEN_TO_ACNUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_LIEN_TO_ACNUM',
                     W_ROWCOUNT,
                     'MIGDEP_LIEN_TO_ACNUM IS NOT PRESENT IN MIG_ACNTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_LIEN_TO_ACNUM,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_LIEN_TO_ACNUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS)');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_TRF_DEP_AC_NUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_TRF_DEP_AC_NUM',
                     W_ROWCOUNT,
                     'MIGDEP_TRF_DEP_AC_NUM IS NOT PRESENT IN MIG_ACNTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_TRF_DEP_AC_NUM,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_TRF_DEP_AC_NUM NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS)');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_CUST_CODE NOT IN (SELECT CLIENTS_CODE FROM MIG_CLIENTS
                                   UNION ALL
                                   SELECT JNTCL_JCL_SL FROM MIG_JOINTCLIENTS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_CUST_CODE',
                     W_ROWCOUNT,
                     'MIGDEP_CUST_CODE IS NOT PRESENT IN MIG_CLIENTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_CUST_CODE,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_CUST_CODE NOT IN (SELECT CLIENTS_CODE FROM MIG_CLIENTS
                                   UNION ALL
                                   SELECT JNTCL_JCL_SL FROM MIG_JOINTCLIENTS);');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_BRN_CODE <> W_BRN_CODE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_BRN_CODE',
                     W_ROWCOUNT,
                     'MIGDEP_BRN_CODE IS NOT THE MIGRATION BRANCH',
                        'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_BRN_CODE,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_BRN_CODE <>'
                     || W_BRN_CODE
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_TRF_FROM_BRN <> W_BRN_CODE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_TRF_FROM_BRN',
                     W_ROWCOUNT,
                     'MIGDEP_TRF_FROM_BRN IS NOT THE MIGRATION BRANCH',
                        'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_TRF_FROM_BRN,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_TRF_FROM_BRN <>'
                     || W_BRN_CODE
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_LIEN_TO_BRN <> W_BRN_CODE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_LIEN_TO_BRN',
                     W_ROWCOUNT,
                     'MIGDEP_LIEN_TO_BRN IS NOT THE MIGRATION BRANCH',
                        'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_LIEN_TO_BRN,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_LIEN_TO_BRN <>'
                     || W_BRN_CODE
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_CONT_NUM = 0 AND MIGDEP_FREQ_OF_DEP IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_FREQ_OF_DEP',
                     W_ROWCOUNT,
                     'RD ACCOUNT, SO MIGDEP_FREQ_OF_DEP  CAN NOT BE NULL',
                     'SELECT MIGDEP_DEP_AC_NUM,
                    MIGDEP_CONT_NUM,
                    MIGDEP_PROD_CODE,
                    MIGDEP_FREQ_OF_DEP
                FROM MIG_PBDCONTRACT
                    WHERE MIGDEP_CONT_NUM = 0 AND MIGDEP_FREQ_OF_DEP IS NULL ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_CONT_NUM = 0 AND MIGDEP_INST_PAY_OPTION IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INST_PAY_OPTION',
                     W_ROWCOUNT,
                     'RD ACCOUNT, SO MIGDEP_INST_PAY_OPTION  CAN NOT BE NULL',
                     'SELECT MIGDEP_DEP_AC_NUM,
                    MIGDEP_CONT_NUM,
                    MIGDEP_PROD_CODE,
                    MIGDEP_INST_PAY_OPTION
                FROM MIG_PBDCONTRACT
                    WHERE MIGDEP_CONT_NUM = 0 AND MIGDEP_INST_PAY_OPTION IS NULL ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_CONT_NUM = 0 AND MIGDEP_AUTO_INST_REC_REQD IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_AUTO_INST_REC_REQD',
                     W_ROWCOUNT,
                     'RD ACCOUNT, SO MIGDEP_AUTO_INST_REC_REQD  CAN NOT BE NULL',
                     'SELECT MIGDEP_DEP_AC_NUM,
                    MIGDEP_CONT_NUM,
                    MIGDEP_PROD_CODE,
                    MIGDEP_AUTO_INST_REC_REQD
                FROM MIG_PBDCONTRACT
                    WHERE MIGDEP_CONT_NUM = 0 AND MIGDEP_AUTO_INST_REC_REQD IS NULL ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_CONT_NUM = 0 AND MIGDEP_INST_REC_DAY IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INST_REC_DAY',
                     W_ROWCOUNT,
                     'RD ACCOUNT, SO MIGDEP_INST_REC_DAY  CAN NOT BE NULL',
                     'SELECT MIGDEP_DEP_AC_NUM,
                    MIGDEP_CONT_NUM,
                    MIGDEP_PROD_CODE,
                    MIGDEP_INST_REC_DAY
                FROM MIG_PBDCONTRACT
                    WHERE MIGDEP_CONT_NUM = 0 AND MIGDEP_INST_REC_DAY IS NULL ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_AC_DEP_AMT <> ROUND (MIGDEP_AC_DEP_AMT, 0)
          AND MIGDEP_PROD_CODE <> 1050;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_AC_DEP_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_AC_DEP_AMT CAN NOT BE A FRACTIONAL VALUE',
                     'SELECT MIGDEP_DEP_AC_NUM,MIGDEP_PROD_CODE, MIGDEP_AC_DEP_AMT FROM MIG_PBDCONTRACT WHERE MIGDEP_AC_DEP_AMT <> ROUND(MIGDEP_AC_DEP_AMT,0)  AND MIGDEP_PROD_CODE <> 1050  ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_BC_DEP_AMT <> ROUND (MIGDEP_BC_DEP_AMT, 0)
          AND MIGDEP_PROD_CODE <> 1050;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_BC_DEP_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_BC_DEP_AMT CAN NOT BE A FRACTIONAL VALUE',
                     'SELECT MIGDEP_DEP_AC_NUM,MIGDEP_PROD_CODE, MIGDEP_BC_DEP_AMT FROM MIG_PBDCONTRACT WHERE MIGDEP_BC_DEP_AMT <> ROUND(MIGDEP_BC_DEP_AMT,0) AND MIGDEP_PROD_CODE <> 1050 ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_MAT_VALUE <> ROUND (MIGDEP_MAT_VALUE, 0)
    AND MIGDEP_PROD_CODE <> 1050;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_MAT_VALUE',
                     W_ROWCOUNT,
                     'MIGDEP_MAT_VALUE CAN NOT BE A FRACTIONAL VALUE',
                     'SELECT MIGDEP_DEP_AC_NUM,MIGDEP_PROD_CODE, MIGDEP_MAT_VALUE FROM MIG_PBDCONTRACT WHERE MIGDEP_MAT_VALUE <> ROUND(MIGDEP_MAT_VALUE,0) ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_PERIODICAL_INT_AMT <> ROUND (MIGDEP_PERIODICAL_INT_AMT, 0)
    AND MIGDEP_PROD_CODE <> 1050;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT CAN NOT BE A FRACTIONAL VALUE',
                     'SELECT MIGDEP_DEP_AC_NUM,MIGDEP_PROD_CODE, MIGDEP_PERIODICAL_INT_AMT FROM MIG_PBDCONTRACT WHERE MIGDEP_PERIODICAL_INT_AMT <> ROUND(MIGDEP_PERIODICAL_INT_AMT,0) ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN
                 (SELECT PRODUCT_CODE
                    FROM PRODUCTS
                   WHERE     PRODUCT_FOR_DEPOSITS = '1'
                         AND PRODUCT_FOR_RUN_ACS = '0'
                         AND PRODUCT_CONTRACT_ALLOWED = '0')
          AND MIGDEP_INT_PAY_FREQ <> 'X';

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_PAY_FREQ',
                     W_ROWCOUNT,
                     'MIGDEP_INT_PAY_FREQ SHOULD BE ''''X'''' FOR RD ACCOUNT',
                     'SELECT MIGDEP_DEP_AC_NUM , MIGDEP_PROD_CODE, MIGDEP_INT_PAY_FREQ
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_PROD_CODE IN
             (SELECT PRODUCT_CODE
                FROM PRODUCTS
               WHERE     PRODUCT_FOR_DEPOSITS = ''1''
                     AND PRODUCT_FOR_RUN_ACS = ''0''
                     AND PRODUCT_CONTRACT_ALLOWED = ''0'')
          AND MIGDEP_INT_PAY_FREQ <> ''X'';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1050, 1075, 1078)
          AND MIGDEP_INT_PAY_FREQ <> 'X';

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_PAY_FREQ',
                     W_ROWCOUNT,
                     'MIGDEP_INT_PAY_FREQ SHOULD BE ''''X'''' FOR FDR,DBS,TBS ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM ,MIGDEP_PROD_CODE, MIGDEP_INT_PAY_FREQ  FROM MIG_PBDCONTRACT
                     WHERE MIGDEP_PROD_CODE IN (1050,1075,1078) AND MIGDEP_INT_PAY_FREQ <> ''X'';  ');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1050, 1075, 1078)
          AND MIGDEP_MAT_VALUE - MIGDEP_BC_DEP_AMT <>
                 MIGDEP_PERIODICAL_INT_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT SHOULD BE  MIGDEP_MAT_VALUE - MIGDEP_BC_DEP_AMT FOR FDR,DBS,TBS ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
                            MIGDEP_PROD_CODE,
                            MIGDEP_BC_DEP_AMT,
                            MIGDEP_MAT_VALUE,
                            MIGDEP_PERIODICAL_INT_AMT,
                            ABS (
                                (MIGDEP_MAT_VALUE - MIGDEP_BC_DEP_AMT) - MIGDEP_PERIODICAL_INT_AMT)
                            AS DIFFERENCE
                            FROM MIG_PBDCONTRACT
                            WHERE     MIGDEP_PROD_CODE IN (1050, 1075, 1078)
                            AND MIGDEP_MAT_VALUE - MIGDEP_BC_DEP_AMT <> MIGDEP_PERIODICAL_INT_AMT;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
          AND MIGDEP_INT_PAY_FREQ <> 'M';

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_PAY_FREQ',
                     W_ROWCOUNT,
                     'MIGDEP_INT_PAY_FREQ SHOULD BE ''M'' FOR MES ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM , MIGDEP_PROD_CODE , MIGDEP_INT_PAY_FREQ
                            FROM MIG_PBDCONTRACT
                            WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
                            AND MIGDEP_INT_PAY_FREQ <> ''M'' ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
          AND MIGDEP_INT_PAY_FREQ = 'M'
          AND ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 1200) <>
                 MIGDEP_PERIODICAL_INT_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT SHOULD BE ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 1200) FOR MES ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM , MIGDEP_BC_DEP_AMT, MIGDEP_ACTUAL_INT_RATE , MIGDEP_INT_PAY_FREQ , MIGDEP_PERIODICAL_INT_AMT
                            FROM MIG_PBDCONTRACT
                            WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
                            AND MIGDEP_INT_PAY_FREQ = ''M''
                            AND ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 1200) <>
                            MIGDEP_PERIODICAL_INT_AMT;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
          AND MIGDEP_INT_PAY_FREQ = 'Q'
          AND ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 400) <>
                 MIGDEP_PERIODICAL_INT_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT SHOULD BE ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 400) FOR MES ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM , MIGDEP_BC_DEP_AMT, MIGDEP_ACTUAL_INT_RATE , MIGDEP_INT_PAY_FREQ , MIGDEP_PERIODICAL_INT_AMT
                            FROM MIG_PBDCONTRACT
                            WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
                            AND MIGDEP_INT_PAY_FREQ = ''M''
                            AND ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 400) <>
                            MIGDEP_PERIODICAL_INT_AMT;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
          AND MIGDEP_INT_PAY_FREQ = 'H'
          AND ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 200) <>
                 MIGDEP_PERIODICAL_INT_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT SHOULD BE ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 200) FOR MES ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM , MIGDEP_BC_DEP_AMT, MIGDEP_ACTUAL_INT_RATE , MIGDEP_INT_PAY_FREQ , MIGDEP_PERIODICAL_INT_AMT
                            FROM MIG_PBDCONTRACT
                            WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
                            AND MIGDEP_INT_PAY_FREQ = ''M''
                            AND ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 200) <>
                            MIGDEP_PERIODICAL_INT_AMT;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
          AND MIGDEP_INT_PAY_FREQ = 'Y'
          AND ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 100) <>
                 MIGDEP_PERIODICAL_INT_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT SHOULD BE ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 100) FOR MES ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM , MIGDEP_BC_DEP_AMT, MIGDEP_ACTUAL_INT_RATE , MIGDEP_INT_PAY_FREQ , MIGDEP_PERIODICAL_INT_AMT
                            FROM MIG_PBDCONTRACT
                            WHERE     MIGDEP_PROD_CODE IN (1070, 1063, 1065, 1072)
                            AND MIGDEP_INT_PAY_FREQ = ''M''
                            AND ROUND ( (MIGDEP_BC_DEP_AMT * MIGDEP_ACTUAL_INT_RATE) / 100) <>
                            MIGDEP_PERIODICAL_INT_AMT;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN
                 (SELECT PRODUCT_CODE
                    FROM PRODUCTS
                   WHERE     PRODUCT_FOR_DEPOSITS = 1
                         AND PRODUCT_FOR_RUN_ACS = 0
                         AND PRODUCT_CONTRACT_ALLOWED = 0
                         AND PRODUCT_CODE <> 1098)
          AND MIGDEP_BC_DEP_AMT > 10000;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_BC_DEP_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_BC_DEP_AMT CAN NOT BE GREATER THAN 10000 FOR RD ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_BC_DEP_AMT
  FROM MIG_PBDCONTRACT
 WHERE     MIGDEP_PROD_CODE IN
              (SELECT PRODUCT_CODE
                 FROM PRODUCTS
                WHERE     PRODUCT_FOR_DEPOSITS = 1
                      AND PRODUCT_FOR_RUN_ACS = 0
                      AND PRODUCT_CONTRACT_ALLOWED = 0
                      AND PRODUCT_CODE <> 1098)
       AND MIGDEP_BC_DEP_AMT > 10000;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE = 1075
          AND MIGDEP_MAT_VALUE <> 2 * MIGDEP_BC_DEP_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_MAT_VALUE',
                     W_ROWCOUNT,
                     'MIGDEP_MAT_VALUE SHOULD BE 2*MIGDEP_BC_DEP_AMT FOR DBS ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_BC_DEP_AMT, MIGDEP_MAT_VALUE
  FROM MIG_PBDCONTRACT
 WHERE     MIGDEP_PROD_CODE = 1075
 AND MIGDEP_MAT_VALUE <> 2*MIGDEP_BC_DEP_AMT ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE = 1078
          AND MIGDEP_MAT_VALUE <> 3 * MIGDEP_BC_DEP_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_MAT_VALUE',
                     W_ROWCOUNT,
                     'MIGDEP_MAT_VALUE SHOULD BE 3*MIGDEP_BC_DEP_AMT FOR TBS ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_BC_DEP_AMT, MIGDEP_MAT_VALUE
  FROM MIG_PBDCONTRACT
 WHERE     MIGDEP_PROD_CODE = 1078
 AND MIGDEP_MAT_VALUE <> 3*MIGDEP_BC_DEP_AMT ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE = 1075
          AND MIGDEP_PERIODICAL_INT_AMT <> MIGDEP_BC_DEP_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT SHOULD BE MIGDEP_BC_DEP_AMT FOR DBS ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_BC_DEP_AMT, MIGDEP_PERIODICAL_INT_AMT
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_PROD_CODE = 1075
   AND MIGDEP_PERIODICAL_INT_AMT <> MIGDEP_BC_DEP_AMT;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE = 1078
          AND MIGDEP_PERIODICAL_INT_AMT <> 2 * MIGDEP_BC_DEP_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT SHOULD BE 2*MIGDEP_BC_DEP_AMT FOR DBS ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_BC_DEP_AMT, MIGDEP_PERIODICAL_INT_AMT
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_PROD_CODE = 1078
   AND MIGDEP_PERIODICAL_INT_AMT <> 2 * MIGDEP_BC_DEP_AMT;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_BC_DEP_AMT > MIGDEP_MAT_VALUE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_BC_DEP_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_BC_DEP_AMT CAN NOT BE GREATER THAN MIGDEP_MAT_VALUE FOR DEPOSITE ACCOUNTS',
                     'SELECT
                        MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_BC_DEP_AMT ,MIGDEP_MAT_VALUE
                        FROM MIG_PBDCONTRACT WHERE MIGDEP_BC_DEP_AMT > MIGDEP_MAT_VALUE ;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_PERIODICAL_INT_AMT > MIGDEP_MAT_VALUE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PERIODICAL_INT_AMT',
                     W_ROWCOUNT,
                     'MIGDEP_PERIODICAL_INT_AMT CAN NOT BE GREATER THAN MIGDEP_MAT_VALUE FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_PERIODICAL_INT_AMT,
       MIGDEP_MAT_VALUE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_PERIODICAL_INT_AMT > MIGDEP_MAT_VALUE;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_BC_INT_PAY_AMT > MIGDEP_BC_INT_ACCR_AMT;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_EFF_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_BC_INT_PAY_AMT CAN NOT BE GREATER THAN MIGDEP_BC_INT_ACCR_AMT FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_BC_INT_ACCR_AMT,
       MIGDEP_BC_INT_PAY_AMT
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_BC_INT_PAY_AMT > MIGDEP_BC_INT_ACCR_AMT;');
   END IF;

   ----------checking the contract accounts for the contract number

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT MP
    WHERE     MP.MIGDEP_PROD_CODE IN
                 (SELECT ACNTS_PROD_CODE
                    FROM MIG_ACNTS
                   WHERE ACNTS_PROD_CODE IN
                            (SELECT PRODUCT_CODE
                               FROM PRODUCTS
                              WHERE PRODUCT_CONTRACT_ALLOWED = '1'))
          AND MIGDEP_CONT_NUM = 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PROD_CODE',
                     W_ROWCOUNT,
                     'FD PRODUCT BUT THERE IS NO CONTRACT NUMBER',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_EFF_DATE, MIGDEP_PROD_CODE, MIGDEP_CONT_NUM
  FROM MIG_PBDCONTRACT MP
 WHERE MP.MIGDEP_PROD_CODE IN
       (SELECT ACNTS_PROD_CODE
          FROM MIG_ACNTS
         WHERE ACNTS_PROD_CODE IN
               (SELECT PRODUCT_CODE
                  FROM PRODUCTS
                 WHERE PRODUCT_CONTRACT_ALLOWED = ''1''))
   AND MIGDEP_CONT_NUM = 0;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_DEP_CURR <> 'BDT';

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_PBDCONTRACT',
                   'MIGDEP_DEP_CURR',
                   W_ROWCOUNT,
                   'MIGDEP_DEP_CURR IS NOT THE MIGRATION BRANCH',
                   'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_DEP_CURR,
       MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_DEP_CURR <> ''BDT'' ;');
   END IF;

   --------------------------------------------------------------------------------------------------------------

   ----IA in PBDCONTRACT but not in DEPIA

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_DEP_AC_NUM NOT IN
                 (SELECT MIG_DEPIA.DEPIA_ACCOUNTNUM FROM MIG_DEPIA)
          AND NVL (MIGDEP_AC_INT_ACCR_AMT, 0) > 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_DEP_AC_NUM',
                     W_ROWCOUNT,
                     'IA in PBDCONTRACT but not in DEPIA',
                     'SELECT MIGDEP_DEP_AC_NUM, NVL(P.MIGDEP_AC_INT_ACCR_AMT, 0)
  FROM MIG_PBDCONTRACT P
 WHERE P.MIGDEP_DEP_AC_NUM NOT IN
       (SELECT MIG_DEPIA.DEPIA_ACCOUNTNUM FROM MIG_DEPIA)
   AND NVL(P.MIGDEP_AC_INT_ACCR_AMT, 0) > 0;');
   END IF;

   -------- IP in PBDCONTRACT but not in depia

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_DEP_AC_NUM NOT IN
                 (SELECT MIG_DEPIA.DEPIA_ACCOUNTNUM FROM MIG_DEPIA)
          AND NVL (MIGDEP_AC_INT_PAY_AMT, 0) > 0;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_DEP_AC_NUM',
                     W_ROWCOUNT,
                     'IP in PBDCONTRACT but not in DEPIA',
                     'SELECT MIGDEP_DEP_AC_NUM, P.MIGDEP_AC_INT_PAY_AMT
  FROM MIG_PBDCONTRACT P
 WHERE P.MIGDEP_DEP_AC_NUM NOT IN
       (SELECT MIG_DEPIA.DEPIA_ACCOUNTNUM FROM MIG_DEPIA)
   AND NVL(P.MIGDEP_AC_INT_PAY_AMT, 0) > 0;');
   END IF;

   ------- Checking Interest_accrued_amount_(IA)_should_not_be_less_than_Interest_pay_amount

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE NVL (MIGDEP_AC_INT_ACCR_AMT, 0) < NVL (MIGDEP_AC_INT_PAY_AMT, 0);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_AC_INT_ACCR_AMT',
                     W_ROWCOUNT,
                     'INTEREST ACCRUED AMOUNT SHOULD NOT BE LESS THAN INTEREST PAY AMOUNT',
                     'SELECT MIGDEP_DEP_AC_NUM,
       P.MIGDEP_DEP_OPEN_DATE,
       P.MIGDEP_EFF_DATE,
       P.MIGDEP_EFF_DATE,
       P.MIGDEP_AC_INT_ACCR_AMT,
       MIGDEP_AC_INT_PAY_AMT
  FROM MIG_PBDCONTRACT P
 WHERE NVL(P.MIGDEP_AC_INT_ACCR_AMT, 0) < NVL(P.MIGDEP_AC_INT_PAY_AMT, 0);');
   END IF;

   ------------------- date validations -------------------------

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1072, 1070, 1063, 1065)
          AND FN_PAID_UPTO_DATE_FINDING (MIGDEP_EFF_DATE, P_START_DATE) <>
                 MIGDEP_INT_PAID_UPTO
                 AND MIGDEP_MAT_DATE >= W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_PAID_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_PAID_UPTO SHOULD BE 1 DAYS LESS THAN OPEN DATE BEFORE MIGRATION FOR MES ACCOUNTS',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_EFF_DATE,
       FN_PAID_UPTO_DATE_FINDING(MIGDEP_EFF_DATE, '
                     || ''''
                     || TO_CHAR (P_START_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ' ) PAID_UPTO_SHOULD_BE,
       MIGDEP_INT_PAID_UPTO,
       ABS(FN_PAID_UPTO_DATE_FINDING(MIGDEP_EFF_DATE,'
                     || ''''
                     || TO_CHAR (P_START_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ') - MIGDEP_INT_PAID_UPTO) DIFFERENCE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_PROD_CODE IN (1072, 1070, 1063, 1065)
 AND FN_PAID_UPTO_DATE_FINDING(MIGDEP_EFF_DATE, '
                     || ''''
                     || TO_CHAR (P_START_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ' ) <> MIGDEP_INT_PAID_UPTO;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1050, 1075, 1078)
          AND MONTHS_BETWEEN (P_START_DATE, MIGDEP_EFF_DATE) > 12
          AND MIGDEP_INT_PAID_UPTO IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_PAID_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_PAID_UPTO IS REQUIRED FOR 1 YEAR LONG FOR FDR, DBS, TBS ACCOUNTS',
                        'SELECT  MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_EFF_DATE, MIGDEP_BC_DEP_AMT, MIGDEP_INT_PAID_UPTO
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1050, 1075, 1078)
          AND MONTHS_BETWEEN ('
                     || ''''
                     || TO_CHAR (P_START_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ', MIGDEP_EFF_DATE) > 12
          AND MIGDEP_INT_PAID_UPTO IS NULL;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1050, 1075, 1078)
          AND MONTHS_BETWEEN (P_START_DATE, MIGDEP_EFF_DATE) > 12
          AND MIGDEP_INT_ACCR_UPTO IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_ACCR_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_ACCR_UPTO IS REQUIRED FOR 1 YEAR LONG FOR FDR, DBS, TBS ACCOUNTS',
                        'SELECT  MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_EFF_DATE, MIGDEP_BC_DEP_AMT, MIGDEP_INT_ACCR_UPTO
     FROM MIG_PBDCONTRACT
    WHERE     MIGDEP_PROD_CODE IN (1050, 1075, 1078)
          AND MONTHS_BETWEEN ('
                     || ''''
                     || TO_CHAR (P_START_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ', MIGDEP_EFF_DATE) > 12
          AND MIGDEP_INT_ACCR_UPTO IS NULL;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_MAT_DATE <>
             ADD_MONTHS (MIGDEP_EFF_DATE, MIGDEP_DEP_PRD_MONTHS);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_MAT_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_MAT_DATE SHOULD BE MIGDEP_EFF_DATE + MIGDEP_DEP_PRD_MONTHS FOR DEPOSITE ACCOUNTS',
                     'SELECT  MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_EFF_DATE, MIGDEP_DEP_PRD_MONTHS, MIGDEP_MAT_DATE
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_MAT_DATE <>
             ADD_MONTHS (MIGDEP_EFF_DATE, MIGDEP_DEP_PRD_MONTHS);');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_PAID_UPTO > MIGDEP_INT_ACCR_UPTO;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_PAID_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_PAID_UPTO CAN NOT BE GREATER THAN MIGDEP_INT_ACCR_UPTO FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_ACCR_UPTO,
       MIGDEP_INT_PAID_UPTO
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_PAID_UPTO > MIGDEP_INT_ACCR_UPTO;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_CLOSURE_DATE > MIGDEP_EFF_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_CLOSURE_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_CLOSURE_DATE CAN NOT BE GREATER THAN MIGDEP_EFF_DATE FOR DEPOSITE ACCOUNTS',
                     'SELECT
MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_EFF_DATE , MIGDEP_CLOSURE_DATE
 FROM MIG_PBDCONTRACT WHERE MIGDEP_CLOSURE_DATE > MIGDEP_EFF_DATE;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_EFF_DATE > MIGDEP_MAT_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_EFF_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_EFF_DATE CAN NOT BE GREATER THAN MIGDEP_MAT_DATE FOR DEPOSITE ACCOUNTS',
                     'SELECT
MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_EFF_DATE , MIGDEP_MAT_DATE
 FROM MIG_PBDCONTRACT WHERE MIGDEP_EFF_DATE > MIGDEP_MAT_DATE;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_EFF_DATE > MIGDEP_INT_ACCR_UPTO;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_EFF_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_EFF_DATE CAN NOT BE GREATER THAN MIGDEP_INT_ACCR_UPTO FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_EFF_DATE,
       MIGDEP_INT_ACCR_UPTO
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_EFF_DATE > MIGDEP_INT_ACCR_UPTO;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_EFF_DATE > MIGDEP_INT_PAID_UPTO;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_EFF_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_EFF_DATE CAN NOT BE GREATER THAN MIGDEP_INT_PAID_UPTO FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_EFF_DATE,
       MIGDEP_INT_PAID_UPTO
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_EFF_DATE > MIGDEP_INT_PAID_UPTO;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_EFF_DATE > MIGDEP_INT_CALC_UPTO;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_EFF_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_EFF_DATE CAN NOT BE GREATER THAN MIGDEP_INT_CALC_UPTO FOR DEPOSITE ACCOUNTS',
                     'SELECT
MIGDEP_DEP_AC_NUM, MIGDEP_PROD_CODE, MIGDEP_EFF_DATE , MIGDEP_INT_CALC_UPTO
 FROM MIG_PBDCONTRACT WHERE MIGDEP_EFF_DATE > MIGDEP_INT_CALC_UPTO;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_EFF_DATE > MIGDEP_INT_CALC_PAYABLE_UPTO;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_EFF_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_EFF_DATE CAN NOT BE GREATER THAN MIGDEP_INT_CALC_PAYABLE_UPTO FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_EFF_DATE,
       MIGDEP_INT_CALC_PAYABLE_UPTO
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_EFF_DATE > MIGDEP_INT_CALC_PAYABLE_UPTO;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_ACCR_UPTO > MIGDEP_MAT_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_ACCR_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_ACCR_UPTO CAN NOT BE GREATER THAN MIGDEP_MAT_DATE FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_ACCR_UPTO,
       MIGDEP_MAT_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_ACCR_UPTO > MIGDEP_MAT_DATE;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_PAID_UPTO > MIGDEP_MAT_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_PAID_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_PAID_UPTO CAN NOT BE GREATER THAN MIGDEP_MAT_DATE FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_PAID_UPTO,
       MIGDEP_MAT_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_PAID_UPTO > MIGDEP_MAT_DATE;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_CALC_UPTO > MIGDEP_MAT_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_CALC_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_CALC_UPTO CAN NOT BE GREATER THAN MIGDEP_MAT_DATE FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_CALC_UPTO,
       MIGDEP_MAT_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_CALC_UPTO > MIGDEP_MAT_DATE;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_CALC_PAYABLE_UPTO > MIGDEP_MAT_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_CALC_PAYABLE_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_CALC_PAYABLE_UPTO CAN NOT BE GREATER THAN MIGDEP_MAT_DATE FOR DEPOSITE ACCOUNTS',
                     'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_CALC_PAYABLE_UPTO,
       MIGDEP_MAT_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_CALC_PAYABLE_UPTO > MIGDEP_MAT_DATE;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_EFF_DATE >= '01-JAN-2014' AND MIGDEP_PROD_CODE = 1070;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_PROD_CODE',
                     W_ROWCOUNT,
                     'MIGDEP_PROD_CODE CAN NOT BE 1070 FOR MES ACCOUNTS WHICH ARE OPEN GREATER THAN 1ST JANUARY, 2105',
                     'SELECT MIGDEP_DEP_AC_NUM, MIGDEP_EFF_DATE, MIGDEP_PROD_CODE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_EFF_DATE >= ''01-JAN-2014'' AND MIGDEP_PROD_CODE = 1070;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_MAT_DATE IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_PBDCONTRACT',
                   'MIGDEP_MAT_DATE',
                   W_ROWCOUNT,
                   'MIGDEP_MAT_DATE CAN NOT BE NULL',
                   'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_MAT_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_MAT_DATE IS NULL;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_DEP_OPEN_DATE IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_PBDCONTRACT',
                   'MIGDEP_DEP_OPEN_DATE',
                   W_ROWCOUNT,
                   'MIGDEP_MAT_DATE CAN NOT BE NULL',
                   'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE
       MIGDEP_MAT_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_DEP_OPEN_DATE IS NULL;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_EFF_DATE IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_PBDCONTRACT',
                   'MIGDEP_EFF_DATE',
                   W_ROWCOUNT,
                   'MIGDEP_EFF_DATE CAN NOT BE NULL',
                   'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_EFF_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_EFF_DATE IS NULL;');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_DEP_OPEN_DATE > W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_DEP_OPEN_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_DEP_OPEN_DATE CAN NOT BE GREATER THAN MIG_DATE',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_DEP_OPEN_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_DEP_OPEN_DATE >'
                     || ''''
                     || TO_CHAR (W_MIG_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_EFF_DATE > W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_EFF_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_EFF_DATE CAN NOT BE GREATER THAN MIG_DATE',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_EFF_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_EFF_DATE >'
                     || ''''
                     || TO_CHAR (W_MIG_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_ACCR_UPTO > W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_ACCR_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_ACCR_UPTO CAN NOT BE GREATER THAN MIG_DATE',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_ACCR_UPTO
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_ACCR_UPTO >'
                     || ''''
                     || TO_CHAR (W_MIG_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_CLOSURE_DATE > W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_CLOSURE_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_CLOSURE_DATE CAN NOT BE GREATER THAN MIG_DATE',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_CLOSURE_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_CLOSURE_DATE >'
                     || ''''
                     || TO_CHAR (W_MIG_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_PAID_UPTO > W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_PAID_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_PAID_UPTO CAN NOT BE GREATER THAN MIG_DATE',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_PAID_UPTO
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_PAID_UPTO >'
                     || ''''
                     || TO_CHAR (W_MIG_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_CALC_UPTO > W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_CALC_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_CALC_UPTO CAN NOT BE GREATER THAN MIG_DATE',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_CALC_UPTO
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_CALC_UPTO >'
                     || ''''
                     || TO_CHAR (W_MIG_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_INT_CALC_PAYABLE_UPTO > W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_INT_CALC_PAYABLE_UPTO',
                     W_ROWCOUNT,
                     'MIGDEP_INT_CALC_PAYABLE_UPTO CAN NOT BE GREATER THAN MIG_DATE',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_INT_CALC_PAYABLE_UPTO
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_INT_CALC_PAYABLE_UPTO >'
                     || ''''
                     || TO_CHAR (W_MIG_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_LIEN_DATE > W_MIG_DATE;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_LIEN_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_LIEN_DATE CAN NOT BE GREATER THAN MIG_DATE',
                        'SELECT MIGDEP_DEP_AC_NUM,
       MIGDEP_PROD_CODE,
       MIGDEP_LIEN_DATE
  FROM MIG_PBDCONTRACT
 WHERE MIGDEP_LIEN_DATE >'
                     || ''''
                     || TO_CHAR (W_MIG_DATE, 'DD-MON-YYYY')
                     || ''''
                     || ';');
   END IF;

   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_PBDCONTRACT
    WHERE MIGDEP_CONT_NUM = 1 AND MIGDEP_REG_DATE IS NULL;

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_PBDCONTRACT',
                     'MIGDEP_REG_DATE',
                     W_ROWCOUNT,
                     'MIGDEP_NOMINATION_REQD IS TRUE, SO MIGDEP_REG_DATE  CAN NOT BE NULL',
                     'SELECT MIGDEP_DEP_AC_NUM,
                    MIGDEP_CONT_NUM,
                    MIGDEP_PROD_CODE,
                    MIGDEP_REG_DATE
                FROM MIG_PBDCONTRACT
                    WHERE MIGDEP_NOMINATION_REQD = 1 AND MIGDEP_REG_DATE IS NULL ;');
   END IF;
END SP_PBDCONTRACT_VALIDATE;
/
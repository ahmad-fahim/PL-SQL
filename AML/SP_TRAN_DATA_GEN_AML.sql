CREATE OR REPLACE PROCEDURE SP_TRAN_DATA_GEN_AML (P_FROM_BRN    NUMBER,
                                                  P_TO_BRN      NUMBER)
IS
   V_SQL   CLOB;
BEGIN
   FOR IDX
      IN (  SELECT *
              FROM (  SELECT BRANCH_CODE, ROWNUM BRANCH_SL
                        FROM MIG_DETAIL
                    ORDER BY BRANCH_CODE)
             WHERE     BRANCH_SL BETWEEN P_FROM_BRN AND P_TO_BRN
                   AND BRANCH_CODE NOT IN
                          (SELECT BRANCH_CODE FROM AML_CLIENT_INSERT_LOG)
          ORDER BY BRANCH_CODE)
   LOOP
      FOR FIN_YEAR IN 2014 .. 2018
      LOOP
         V_SQL :=
               '
         INSERT INTO AML_TRANSACTIONS
            SELECT TR.ACCOUNTORREFERENCENO,
                   TR.TRANSACTIONNO,
                   TR.TRANSACTIONTYPE,
                   TR.TRANSACTIONMEDIA,
                   TR.AMOUNT,
                   TR.BALANCE,
                   TR.CURRENCY,
                   TR.BENEFICIARYNAME,
                   TR.TELLERID,
                   TR.TRANSACTIONDATE,
                   TR.TRANSACTIONTIMESTAMP,
                   TR.CBSBRANCHCODE,
                   TR.GEOLOCATION,
                   TR.COMMENTS,
                   TR.BENIFICIARYACNO,
                   TR.BENIFICIARYBRANCHNAME,
                   TR.BENIFICIARYBANKNAME,
                   CT_PERSON_NAME DEPOSITORNAME
              FROM (SELECT FACNO (TRAN_ENTITY_NUM, TRAN_INTERNAL_ACNUM)
                              ACCOUNTORREFERENCENO,
                              TRAN_BRN_CODE
                           || ''/''
                           || TRAN_DATE_OF_TRAN
                           || ''/''
                           || TRAN_BATCH_NUMBER
                              TRANSACTIONNO,
                           CASE
                              WHEN TRAN_DB_CR_FLG = ''D'' THEN ''DR''
                              ELSE ''CR''
                           END
                              TRANSACTIONTYPE,
                           CASE
                              WHEN TRAN_TYPE_OF_TRAN = 1 THEN ''TRANSFER''
                              WHEN TRAN_TYPE_OF_TRAN = 2 THEN ''CLEARING''
                              WHEN TRAN_TYPE_OF_TRAN = 3 THEN ''CASH''
                           END
                              TRANSACTIONMEDIA,
                           TRAN_AMOUNT AMOUNT,
                           TRAN_AVAILABLE_AC_BAL BALANCE,
                           TRAN_CURR_CODE CURRENCY,
                           ACNTS_AC_NAME1 || ACNTS_AC_NAME2 BENEFICIARYNAME,
                           TRAN_ENTD_BY TELLERID,
                           TRAN_DATE_OF_TRAN TRANSACTIONDATE,
                           TRAN_ENTD_ON TRANSACTIONTIMESTAMP,
                           --TO_CHAR(TRAN_ENTD_ON, ''HH24:MI:SS'') TRANSACTIONTIMESTAMP,
                           TRAN_BRN_CODE CBSBRANCHCODE,
                           NULL GEOLOCATION,
                           CASE
                              WHEN TRIM (
                                         TRAN_NARR_DTL1
                                      || TRAN_NARR_DTL2
                                      || TRAN_NARR_DTL3)
                                      IS NOT NULL
                              THEN
                                 TRIM (
                                       TRAN_NARR_DTL1
                                    || TRAN_NARR_DTL2
                                    || TRAN_NARR_DTL3)
                              ELSE
                                 TRIM (
                                       TRANBAT_NARR_DTL1
                                    || TRANBAT_NARR_DTL2
                                    || TRANBAT_NARR_DTL3)
                           END
                              COMMENTS,
                           FACNO (TRAN_ENTITY_NUM, TRAN_INTERNAL_ACNUM)
                              BENIFICIARYACNO,
                           MBRN_NAME BENIFICIARYBRANCHNAME,
                           (SELECT INS_NAME_OF_BANK FROM INSTALL)
                              BENIFICIARYBANKNAME,
                           TRAN_BATCH_NUMBER
                      FROM TRAN'
            || FIN_YEAR
            || ',
                           TRANBAT'
            || FIN_YEAR
            || ',
                           ACNTS,
                           MBRN
                     WHERE     TRAN_ENTITY_NUM = 1
                           AND TRANBAT_ENTITY_NUM = TRAN_ENTITY_NUM
                           AND TRANBAT_BRN_CODE = TRAN_BRN_CODE
                           AND TRANBAT_DATE_OF_TRAN = TRAN_DATE_OF_TRAN
                           AND TRANBAT_BATCH_NUMBER = TRAN_BATCH_NUMBER
                           AND TRAN_INTERNAL_ACNUM <> 0
                           AND TRAN_AUTH_BY IS NOT NULL
                           AND ACNTS_ENTITY_NUM = TRAN_ENTITY_NUM
                           AND ACNTS_INTERNAL_ACNUM = TRAN_INTERNAL_ACNUM
                           AND MBRN_ENTITY_NUM = 1
                           AND MBRN_CODE = TRAN_BRN_CODE
                           AND TRAN_BRN_CODE = '
            || IDX.BRANCH_CODE
            || ') TR
                   LEFT OUTER JOIN
                   CTRAN'
            || FIN_YEAR
            || '
                      ON (    CTRAN_ENTITY_NUM = 1
                          AND CT_BRN_CODE = POST_TRAN_BRN
                          AND CT_TRAN_DATE = POST_TRAN_DATE
                          AND CT_CASHIER_ID = TR.TELLERID
                          AND POST_TRAN_BRN = TR.CBSBRANCHCODE
                          AND POST_TRAN_DATE = TR.TRANSACTIONDATE
                          AND POST_TRAN_BATCH_NUM = TR.TRAN_BATCH_NUMBER
                          AND POST_TRAN_BRN = '
            || IDX.BRANCH_CODE
            || ') ';


         EXECUTE IMMEDIATE V_SQL;
      END LOOP;

      INSERT INTO AML_CLIENT_INSERT_LOG (BRANCH_CODE, MESSAGE, FINISHTIME)
           VALUES (IDX.BRANCH_CODE, 'SUCCESSFUL', SYSDATE);

      COMMIT;
   END LOOP;
END SP_TRAN_DATA_GEN_AML;
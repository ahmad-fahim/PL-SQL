/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE PKG_MULTI_TASK
IS 

   PROCEDURE EXCISE_DUTY_DATA_GEN (P_ENTITY_CODE    NUMBER,
                                   P_BRANCH_CODE    NUMBER);

   PROCEDURE AVERAGE_BALANCE_DATA_GENERATE (P_ENTITY_CODE    NUMBER,P_BRANCH_CODE    NUMBER,
                                            P_TO_DATE        DATE);
END PKG_MULTI_TASK;
/






/*<TOAD_FILE_CHUNK>*/
/* Formatted on 12/15/2015 11:41:50 AM (QP5 v5.227.12220.39754) */
CREATE OR REPLACE PACKAGE BODY PKG_MULTI_TASK
IS
   TYPE REC_EXCISE_TEMP_DATA IS RECORD
   (
      EXCISE_ENTITY_NUM       EXCISE_DUTY_TEMP_DATA.EXCISE_ENTITY_NUM%TYPE,
      EXCISE_BRN_CODE         EXCISE_DUTY_TEMP_DATA.EXCISE_BRN_CODE%TYPE,
      EXCISE_INTERNAL_ACNUM   EXCISE_DUTY_TEMP_DATA.EXCISE_INTERNAL_ACNUM%TYPE,
      EXCISE_PROD_CODE        EXCISE_DUTY_TEMP_DATA.EXCISE_PROD_CODE%TYPE,
      EXCISE_AC_TYPE          EXCISE_DUTY_TEMP_DATA.EXCISE_AC_TYPE%TYPE,
      EXCISE_CURR_CODE        EXCISE_DUTY_TEMP_DATA.EXCISE_CURR_CODE%TYPE,
      EXCISE_MAX_BALANCE      EXCISE_DUTY_TEMP_DATA.EXCISE_MAX_BALANCE%TYPE
   );

   TYPE TT_REC_EXCISE_TEMP_DATA IS TABLE OF REC_EXCISE_TEMP_DATA
      INDEX BY PLS_INTEGER;

   T_REC_EXCISE_TEMP_DATA   TT_REC_EXCISE_TEMP_DATA;
   V_ASON_DATE              DATE;
   W_ERROR_MESSAGE          VARCHAR2 (1000);

   W_MYEXCEPTION            EXCEPTION;


   PROCEDURE EXCISE_DUTY_DATA_GEN (P_ENTITY_CODE    NUMBER,
                                   P_BRANCH_CODE    NUMBER)
   IS
      V_SQL_QUERY        CLOB;

      V_FIN_YEAR_START   DATE;
      EX_DML_ERRORS      EXCEPTION;
      W_BULK_COUNT       NUMBER (10);
      W_ERROR            VARCHAR2 (1000);



      TYPE RECORD_CURSOR IS REF CURSOR;

      CURSOR_EXCISE      RECORD_CURSOR;
   BEGIN
   V_FIN_YEAR_START:= PKG_PB_GLOBAL.SP_GET_FIN_YEAR_START(P_ENTITY_CODE);
   V_ASON_DATE:= PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE(P_ENTITY_CODE);
      V_SQL_QUERY :=
            'SELECT ACNTS_ENTITY_NUM,
         ACNTS_BRN_CODE,
         ACNTS_INTERNAL_ACNUM,
         ACNTS_PROD_CODE,
         ACNTS_AC_TYPE,
         ACNTS_CURR_CODE,
         MAX (ABS(BALANCE)) MAX_TRAN_BALANCE
    FROM (SELECT ACNTS_ENTITY_NUM,
                 ACNTS_BRN_CODE,
                 ACNTS_INTERNAL_ACNUM,
                 ACNTS_PROD_CODE,
                 ACNTS_AC_TYPE,
                 ACNTS_CURR_CODE,
                 ACBALH_ASON_DATE,
                 SUM (CREDIT_AMOUNT - DEBIT_AMOUNT)
                    OVER (PARTITION BY ACNTS_ENTITY_NUM, ACNTS_INTERNAL_ACNUM
                          ORDER BY ACNTS_ENTITY_NUM,
                                   ACNTS_INTERNAL_ACNUM,
                                   ACBALH_ASON_DATE,
                                   TRAN_BATCH_NUMBER,
                                   TRAN_BATCH_SL_NUM)
                    BALANCE
            FROM (SELECT ACNTS_ENTITY_NUM,
                         ACNTS_BRN_CODE,
                         ACNTS_INTERNAL_ACNUM,
                         ACNTS_PROD_CODE,
                         ACNTS_AC_TYPE,
                         ACNTS_CURR_CODE,
                         ACBALH_ASON_DATE,
                         (CASE WHEN ACBALH_AC_BAL < 0 THEN ''D'' ELSE ''C'' END)
                            TRAN_DB_CR_FLG,
                         (CASE
                             WHEN ACBALH_AC_BAL < 0 THEN ABS (ACBALH_AC_BAL)
                             ELSE 0
                          END)
                            DEBIT_AMOUNT,
                         (CASE
                             WHEN ACBALH_AC_BAL > 0 THEN ABS (ACBALH_AC_BAL)
                             ELSE 0
                          END)
                            CREDIT_AMOUNT,
                         0 TRAN_BATCH_NUMBER,
                         0 TRAN_BATCH_SL_NUM
                    FROM (SELECT ACBALH_ENTITY_NUM,
                                 ACBALH_INTERNAL_ACNUM,
                                 ACBALH_ASON_DATE,
                                 ACBALH_AC_BAL,
                                 ACBALH_BC_BAL,
                                 SERIAL,
                                 ACNTS_ENTITY_NUM,
                                 ACNTS_BRN_CODE,
                                 ACNTS_INTERNAL_ACNUM,
                                 ACNTS_PROD_CODE,
                                 ACNTS_AC_TYPE,
                                 ACNTS_CURR_CODE
                            FROM (SELECT ACBALH_ENTITY_NUM,
                                         ACBALH_INTERNAL_ACNUM,
                                         ACBALH_ASON_DATE,
                                         ACBALH_AC_BAL,
                                         ACBALH_BC_BAL,
                                         ROW_NUMBER ()
                                         OVER (
                                            PARTITION BY ACBALH_ENTITY_NUM,
                                                         ACBALH_INTERNAL_ACNUM
                                            ORDER BY
                                               ACBALH_ENTITY_NUM,
                                               ACBALH_INTERNAL_ACNUM,
                                               ACBALH_ASON_DATE DESC NULLS LAST)
                                            SERIAL
                                    FROM ACBALASONHIST
                                   WHERE ACBALH_ASON_DATE <= :FROM_DAT) ACH,
                                 (SELECT ACNTS_ENTITY_NUM,
                                         ACNTS_BRN_CODE,
                                         ACNTS_INTERNAL_ACNUM,
                                         ACNTS_PROD_CODE,
                                         ACNTS_AC_TYPE,
                                         ACNTS_CURR_CODE
                                    FROM ACNTS A,
                                         (SELECT DISTINCT EDUTY_PROD_CODE
                                            FROM EDUTY
                                           WHERE EDUTY_EXCDUTY_APPL = ''1'') E
                                   WHERE E.EDUTY_PROD_CODE = A.ACNTS_PROD_CODE
                                         AND ACNTS_ENTITY_NUM = :ENTITY_CODE
                                         AND ACNTS_INOP_ACNT = 0
                                         AND ACNTS_CLOSURE_DATE IS NULL
                                  AND ACNTS_AC_TYPE NOT IN (SELECT EDUTY_AC_TYPE
                                     FROM EDUTY
                                    WHERE EDUTY_EXCDUTY_APPL = ''0'')) ACN
                           WHERE ACH.ACBALH_ENTITY_NUM = ACN.ACNTS_ENTITY_NUM
                                 AND ACN.ACNTS_INTERNAL_ACNUM =
                                        ACH.ACBALH_INTERNAL_ACNUM)
                   WHERE SERIAL = 1
                  UNION ALL
                  (SELECT ACNTS_ENTITY_NUM,
                          ACNTS_BRN_CODE,
                          ACNTS_INTERNAL_ACNUM,
                          ACNTS_PROD_CODE,
                          ACNTS_AC_TYPE,
                          ACNTS_CURR_CODE,
                          TRAN_VALUE_DATE,
                          TRAN_DB_CR_FLG,
                          (CASE
                              WHEN TRAN_DB_CR_FLG = ''D'' THEN TRAN_AMOUNT
                              ELSE 0
                           END)
                             DEBIT_AMOUNT,
                          (CASE
                              WHEN TRAN_DB_CR_FLG = ''C'' THEN TRAN_AMOUNT
                              ELSE 0
                           END)
                             CREDIT_AMOUNT,
                          TRAN_BATCH_NUMBER,
                          TRAN_BATCH_SL_NUM
                     FROM TRAN'
         || TO_CHAR (V_ASON_DATE, 'YYYY')
         || ' T,
                          (SELECT ACNTS_ENTITY_NUM,
                                  ACNTS_BRN_CODE,
                                  ACNTS_INTERNAL_ACNUM,
                                  ACNTS_PROD_CODE,
                                  ACNTS_AC_TYPE,
                                  ACNTS_CURR_CODE
                             FROM ACNTS A,
                                  (SELECT DISTINCT EDUTY_PROD_CODE
                                     FROM EDUTY
                                    WHERE EDUTY_EXCDUTY_APPL = ''1'') E
                            WHERE     E.EDUTY_PROD_CODE = A.ACNTS_PROD_CODE
                                  AND ACNTS_ENTITY_NUM = :ENTITY_CODE
                                  AND ACNTS_INOP_ACNT = 0
                                  AND ACNTS_CLOSURE_DATE IS NULL
                                  AND ACNTS_AC_TYPE NOT IN (SELECT EDUTY_AC_TYPE
                                     FROM EDUTY
                                  WHERE EDUTY_EXCDUTY_APPL = ''0'')
                                    ) A
                    WHERE     A.ACNTS_ENTITY_NUM = T.TRAN_ENTITY_NUM
                          AND A.ACNTS_INTERNAL_ACNUM = T.TRAN_INTERNAL_ACNUM
                          AND T.TRAN_VALUE_DATE BETWEEN :FROM_DAT AND :TO_DAT
                          AND TRAN_INTERNAL_ACNUM <> ''0''
                          AND TRAN_AUTH_ON IS NOT NULL)))
GROUP BY ACNTS_ENTITY_NUM,
         ACNTS_BRN_CODE,
         ACNTS_INTERNAL_ACNUM,
         ACNTS_PROD_CODE,
         ACNTS_AC_TYPE,
         ACNTS_CURR_CODE';

      BEGIN
         EXECUTE IMMEDIATE 'TRUNCATE TABLE EXCISE_DUTY_TEMP_DATA';

         OPEN CURSOR_EXCISE FOR V_SQL_QUERY
            USING V_FIN_YEAR_START,
                  P_ENTITY_CODE,
                  P_ENTITY_CODE,
                  V_FIN_YEAR_START,
                  V_ASON_DATE;

         LOOP
            BEGIN
               FETCH CURSOR_EXCISE
                  BULK COLLECT INTO T_REC_EXCISE_TEMP_DATA
                  LIMIT 100000;

               FORALL INDX
                   IN T_REC_EXCISE_TEMP_DATA.FIRST ..
                      T_REC_EXCISE_TEMP_DATA.LAST
                  INSERT INTO EXCISE_DUTY_TEMP_DATA (EXCISE_ENTITY_NUM,
                                                     EXCISE_BRN_CODE,
                                                     EXCISE_INTERNAL_ACNUM,
                                                     EXCISE_PROD_CODE,
                                                     EXCISE_AC_TYPE,
                                                     EXCISE_CURR_CODE,
                                                     EXCISE_MAX_BALANCE)
                       VALUES (
                                 T_REC_EXCISE_TEMP_DATA (INDX).EXCISE_ENTITY_NUM,
                                 T_REC_EXCISE_TEMP_DATA (INDX).EXCISE_BRN_CODE,
                                 T_REC_EXCISE_TEMP_DATA (INDX).EXCISE_INTERNAL_ACNUM,
                                 T_REC_EXCISE_TEMP_DATA (INDX).EXCISE_PROD_CODE,
                                 T_REC_EXCISE_TEMP_DATA (INDX).EXCISE_AC_TYPE,
                                 T_REC_EXCISE_TEMP_DATA (INDX).EXCISE_CURR_CODE,
                                 T_REC_EXCISE_TEMP_DATA (INDX).EXCISE_MAX_BALANCE);

               EXIT WHEN CURSOR_EXCISE%NOTFOUND;
            EXCEPTION
               WHEN EX_DML_ERRORS
               THEN
                  W_BULK_COUNT := SQL%BULK_EXCEPTIONS.COUNT;
                  W_ERROR :=
                        W_BULK_COUNT
                     || ' ROWS FAILED IN INSERT EXCISE_DUTY_TEMP_DATA ';

                  FOR I IN 1 .. W_BULK_COUNT
                  LOOP
                     DBMS_OUTPUT.PUT_LINE (
                           'Error: '
                        || I
                        || ' Array Index: '
                        || SQL%BULK_EXCEPTIONS (I).ERROR_INDEX
                        || ' Message: '
                        || SQLERRM (-SQL%BULK_EXCEPTIONS (I).ERROR_CODE));
                  END LOOP;
            END;
         END LOOP;

         T_REC_EXCISE_TEMP_DATA.DELETE;
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR_MESSAGE := SQLERRM;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (P_ENTITY_CODE,
                                         'X',
                                         W_ERROR_MESSAGE,
                                         ' ',
                                         0);
            RAISE W_MYEXCEPTION;
      END;
   END;


   PROCEDURE AVERAGE_BALANCE_DATA_GENERATE (P_ENTITY_CODE    NUMBER,
                                            P_BRANCH_CODE    NUMBER,
                                            P_TO_DATE        DATE)
   IS
      TYPE TEMP_MAINTCHAVGBAL IS RECORD
      (
         MAINTCHAVGBAL_ENTITY_NUM       MAINTCHAVGBAL.MAINTCHAVGBAL_ENTITY_NUM%TYPE,
         MAINTCHAVGBAL_INTERNAL_ACNUM   MAINTCHAVGBAL.MAINTCHAVGBAL_INTERNAL_ACNUM%TYPE,
         MAINTCHAVGBAL_BRN_CODE         MAINTCHAVGBAL.MAINTCHAVGBAL_BRN_CODE%TYPE,
         MAINTCHAVGBAL_OPENING_DATE     MAINTCHAVGBAL.MAINTCHAVGBAL_OPENING_DATE%TYPE,
         MAINTCHAVGBAL_PROD_CODE        MAINTCHAVGBAL.MAINTCHAVGBAL_PROD_CODE%TYPE,
         MAINTCHAVGBAL_MIG_DATE         MAINTCHAVGBAL.MAINTCHAVGBAL_MIG_DATE%TYPE,
         MAINTCHAVGBAL_MIG_AVG_BAL      MAINTCHAVGBAL.MAINTCHAVGBAL_MIG_AVG_BAL%TYPE,
         MAINTCHAVGBAL_LCHG_DEDDATE     MAINTCHAVGBAL.MAINTCHAVGBAL_LCHG_DEDDATE%TYPE,
         MAINTCHAVGBAL_LTRAN_DATE       MAINTCHAVGBAL.MAINTCHAVGBAL_LTRAN_DATE%TYPE,
         MAINTCHAVGBAL_CHG_EFE_DATE     MAINTCHAVGBAL.MAINTCHAVGBAL_CHG_EFE_DATE%TYPE,
         MAINTCHAVGBAL_CHARGE_CODE      MAINTCHAVGBAL.MAINTCHAVGBAL_CHARGE_CODE%TYPE,
         MAINTCHAVGBAL_CURR_CODE        MAINTCHAVGBAL.MAINTCHAVGBAL_CURR_CODE%TYPE,
         MAINTCHAVGBAL_CHG_TYPE         MAINTCHAVGBAL.MAINTCHAVGBAL_CHG_TYPE%TYPE,
         MAINTCHAVGBAL_GLACCESS_CD      MAINTCHAVGBAL.MAINTCHAVGBAL_GLACCESS_CD%TYPE,
         MAINTCHAVGBAL_STAX_RCVD_HEAD   MAINTCHAVGBAL.MAINTCHAVGBAL_STAX_RCVD_HEAD%TYPE
      );

      TYPE TT_MAINTCHAVGBAL IS TABLE OF TEMP_MAINTCHAVGBAL
         INDEX BY PLS_INTEGER;

      T_MAINTCHAVGBAL      TT_MAINTCHAVGBAL;

      V_SQL                CLOB;
      V_ERRM               VARCHAR2 (4000);

      TYPE RECORD_CURSOR IS REF CURSOR;

      CURSOR_DATA_INS      RECORD_CURSOR;
      CURSOR_DATA_UPDATE   RECORD_CURSOR;
      V_FROM_DATE          DATE;
      V_START_DATE         DATE;
   BEGIN
      V_START_DATE := PKG_PB_GLOBAL.SP_FORM_START_DATE (1, P_TO_DATE, 'H');

      DELETE FROM MAINTCHAVGBAL;
      
      COMMIT ;

      V_SQL :=
         'SELECT ACNTS_ENTITY_NUM,
       ACNTS_INTERNAL_ACNUM,
       ACNTS_BRN_CODE,
       ACNTS_OPENING_DATE,
       ACNTS_PROD_CODE,
       MIGRATION_DATE,
       MIGRATION_BALANCE,
       LAST_CHARG_DED_DATE,
       MAX_TRANSACTION_DATE,
  (CASE
           WHEN LAST_CHARG_DED_DATE IS NOT NULL
           THEN
              LAST_CHARG_DED_DATE + 1
           ELSE
              (CASE
                  WHEN ACNTS_OPENING_DATE >=
                          NVL (MIGRATION_DATE, ACNTS_OPENING_DATE)
                  THEN
                     ACNTS_OPENING_DATE
                  ELSE
                     (CASE
                         WHEN ACNTS_OPENING_DATE > :FROM_DATE
                         THEN
                            ACNTS_OPENING_DATE
                         ELSE
                            :FROM_DATE
                      END)
               END)
        END)
          CHARGE_EFECTIVE_DATE,
       MAINCHARGE_CHARGE_CODE,
       ACNTS_CURR_CODE,
       CHGCD_CHG_TYPE,
       CHGCD_GLACCESS_CD,
       STAXACPM_STAX_RCVD_HEAD
  FROM    (SELECT ACNTS_ENTITY_NUM,
                  ACNTS_INTERNAL_ACNUM,
                  ACNTS_BRN_CODE,
                  ACNTS_OPENING_DATE,
                  ACNTS_PROD_CODE,
                  MAINCHARGE_CHARGE_CODE,
                  ACNTS_CURR_CODE,
                  CHGCD_CHG_TYPE,
                  CHGCD_GLACCESS_CD,
                  STAXACPM_STAX_RCVD_HEAD,
                  AC_MIG.ACBALH_ASON_DATE MIGRATION_DATE,
                  NVL (AC_MIG.ACBALH_AC_BAL, 0) MIGRATION_BALANCE,
                  MAX_TRANSACTION_DATE
             FROM    (SELECT ACNTS_ENTITY_NUM,
                             ACNTS_INTERNAL_ACNUM,
                             ACNTS_BRN_CODE,
                             ACNTS_OPENING_DATE,
                             ACNTS_PROD_CODE,
                             MAINCHARGE_CHARGE_CODE,
                             ACNTS_CURR_CODE,
                             CHGCD_CHG_TYPE,
                             CHGCD_GLACCESS_CD,
                             STAXACPM_STAX_RCVD_HEAD,
                             MAX_TRANSACTION_DATE
                        FROM    (SELECT ACNTS_ENTITY_NUM,
                                        ACNTS_INTERNAL_ACNUM,
                                        ACNTS_BRN_CODE,
                                        ACNTS_OPENING_DATE,
                                        ACNTS_PROD_CODE,
                                        MAINCHARGE_CHARGE_CODE,
                                        ACNTS_CURR_CODE,
                                        CHGCD_CHG_TYPE,
                                        DECODE (CHGCD_STAT_ALLOWED_FLG,
                                                1, CHGCD_STAT_TYPE,
                                                0, CHGCD_DB_REFUND_HEAD)
                                           CHGCD_GLACCESS_CD,
                                        STAXACPM_STAX_RCVD_HEAD
                                   FROM ACNTS A,
                                        MAINCHARGE M,
                                        CHGCD C,
                                        STAXACPM V
                                  WHERE M.MAINCHARGE_PROD_CODE =
                                           A.ACNTS_PROD_CODE
                                        AND M.MAINCHARGE_AC_TYPE =
                                               A.ACNTS_AC_TYPE
                                        AND M.MAINCHARGE_ENTITY_NUM = :1
                                        AND A.ACNTS_ENTITY_NUM = :1
                                        AND M.MAINCHARGE_CURR_CODE =
                                               A.ACNTS_CURR_CODE
                                        AND V.STAXACPM_TAX_CODE =
                                               C.CHGCD_SERVICE_TAX_CODE
                                        AND C.CHGCD_CHARGE_CODE =
                                               M.MAINCHARGE_CHARGE_CODE
                                        AND A.ACNTS_BRN_CODE =
                                               DECODE (:BRANCH_CODE,
                                                       0, ACNTS_BRN_CODE,
                                                       :BRANCH_CODE)
                                        AND A.ACNTS_CLOSURE_DATE IS NULL
                                        AND A.ACNTS_INOP_ACNT = 0
                                        AND M.MAINCHARGE_CHARGE_APPL = ''1'') ACH
                             LEFT OUTER JOIN
                                (  SELECT ACBALH_INTERNAL_ACNUM,
                                          MAX (ACBALH_ASON_DATE)
                                             MAX_TRANSACTION_DATE
                                     FROM ACBALASONHIST
                                    WHERE ACBALH_ASON_DATE <= :FROM_DATE
                                    AND ACBALH_ENTITY_NUM = :1
                                 GROUP BY ACBALH_INTERNAL_ACNUM) HIST
                             ON (HIST.ACBALH_INTERNAL_ACNUM =
                                    ACH.ACNTS_INTERNAL_ACNUM)) A
                  LEFT OUTER JOIN
                     ACBALASONHIST_AVGBAL AC_MIG
                  ON A.ACNTS_INTERNAL_ACNUM = AC_MIG.ACBALH_INTERNAL_ACNUM
                  AND AC_MIG.ACBALH_ENTITY_NUM = :1) ACCOUNTS
       LEFT OUTER JOIN
          (  SELECT ACNTCHGAMT_INTERNAL_ACNUM,
                    MAX (ACNTCHGAMT_PROCESS_DATE) LAST_CHARG_DED_DATE
               FROM ACNTCHARGEAMT
              WHERE ACNTCHGAMT_BRN_CODE =
                       DECODE (:BRANCH_CODE,
                               0, ACNTCHGAMT_BRN_CODE,
                               :BRANCH_CODE)
           GROUP BY ACNTCHGAMT_INTERNAL_ACNUM) LAST_CHARGE
       ON ACCOUNTS.ACNTS_INTERNAL_ACNUM =
             LAST_CHARGE.ACNTCHGAMT_INTERNAL_ACNUM';

      BEGIN
         OPEN CURSOR_DATA_INS FOR V_SQL
            USING V_START_DATE,
                  V_START_DATE,
                  P_ENTITY_CODE,
                  P_ENTITY_CODE,
                  P_BRANCH_CODE,
                  P_BRANCH_CODE,
                  V_START_DATE,
                  P_ENTITY_CODE,
                  P_ENTITY_CODE,
                  P_BRANCH_CODE,
                  P_BRANCH_CODE;

         LOOP
            FETCH CURSOR_DATA_INS
               BULK COLLECT INTO T_MAINTCHAVGBAL
               LIMIT 100000;

            FORALL INDX IN T_MAINTCHAVGBAL.FIRST .. T_MAINTCHAVGBAL.LAST
               INSERT INTO MAINTCHAVGBAL (MAINTCHAVGBAL_ENTITY_NUM,
                                          MAINTCHAVGBAL_INTERNAL_ACNUM,
                                          MAINTCHAVGBAL_BRN_CODE,
                                          MAINTCHAVGBAL_OPENING_DATE,
                                          MAINTCHAVGBAL_PROD_CODE,
                                          MAINTCHAVGBAL_MIG_DATE,
                                          MAINTCHAVGBAL_MIG_AVG_BAL,
                                          MAINTCHAVGBAL_LCHG_DEDDATE,
                                          MAINTCHAVGBAL_LTRAN_DATE,
                                          MAINTCHAVGBAL_CHG_EFE_DATE,
                                          MAINTCHAVGBAL_CHARGE_CODE,
                                          MAINTCHAVGBAL_CURR_CODE,
                                          MAINTCHAVGBAL_CHG_TYPE,
                                          MAINTCHAVGBAL_GLACCESS_CD,
                                          MAINTCHAVGBAL_STAX_RCVD_HEAD)
                    VALUES (
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_ENTITY_NUM,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_INTERNAL_ACNUM,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_BRN_CODE,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_OPENING_DATE,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_PROD_CODE,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_MIG_DATE,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_MIG_AVG_BAL,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_LCHG_DEDDATE,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_LTRAN_DATE,
                              (CASE
                                  WHEN T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_CHG_EFE_DATE =
                                          V_ASON_DATE
                                  THEN
                                       T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_CHG_EFE_DATE
                                     - 1
                                  ELSE
                                     T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_CHG_EFE_DATE
                               END),
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_CHARGE_CODE,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_CURR_CODE,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_CHG_TYPE,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_GLACCESS_CD,
                              T_MAINTCHAVGBAL (INDX).MAINTCHAVGBAL_STAX_RCVD_HEAD);

            EXIT WHEN CURSOR_DATA_INS%NOTFOUND;
         END LOOP;

         T_MAINTCHAVGBAL.DELETE;
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR_MESSAGE := SQLERRM;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (P_ENTITY_CODE,
                                         'X',
                                         W_ERROR_MESSAGE,
                                         ' ',
                                         0);
            RAISE W_MYEXCEPTION;
      END;
   END;
END PKG_MULTI_TASK;
/
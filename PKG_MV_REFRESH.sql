CREATE OR REPLACE PACKAGE PKG_MV_REFRESH
IS
   -- Materialized view replacement into table(table names are same as Materialized view )... This procedure will be called in the EOD...
   -- In the month starting date the table will be truncated and new data will be inserted .. And every normal day, new data will be inserted.
   -- Previous Materialized views were :  MV_LOAN_ACCOUNT_BAL, MV_DAY_ACCOUNT_BAL, MV_LOAN_ACCOUNT_BAL_OD, MV_SB_ACCOUNT_PERSENT, MV_MMB_WEEK_TRANSACTION
   -- New tables are : MV_LOAN_ACCOUNT_BAL, MV_DAY_ACCOUNT_BAL, MV_LOAN_ACCOUNT_BAL_OD, MV_SB_ACCOUNT_PERSENT, MV_MMB_WEEK_TRANSACTION
   PROCEDURE SP_PROCESS_DAY (P_ENTITY_NUM IN NUMBER );
   PROCEDURE SP_PROCESS_DAY_MANUAL_LOAN (P_ENTITY_NUM IN NUMBER, P_PROCESS_DAY IN DATE );
END PKG_MV_REFRESH;
/

CREATE OR REPLACE PACKAGE BODY PKG_MV_REFRESH
IS
   -- Materialized view replacement into table(table names are same as Materialized view )... This procedure will be called in the EOD...
   -- In the month starting date the table will be truncated and new data will be inserted .. And every normal day, new data will be inserted.
   -- Previous Materialized views were :  MV_LOAN_ACCOUNT_BAL, MV_DAY_ACCOUNT_BAL, MV_LOAN_ACCOUNT_BAL_OD, MV_SB_ACCOUNT_PERSENT, MV_MMB_WEEK_TRANSACTION
   -- New tables are : MV_LOAN_ACCOUNT_BAL, MV_DAY_ACCOUNT_BAL, MV_LOAN_ACCOUNT_BAL_OD, MV_SB_ACCOUNT_PERSENT, MV_MMB_WEEK_TRANSACTION

   V_CBD                DATE;
   V_ASON_DATE          DATE;

   V_MONTH_START_DATE   DATE;
   V_MONTH_LAST_DATE    DATE;
   V_SQL                CLOB;
   V_SQL_TRUNCATE       CLOB;
   V_FIN_YEAR           NUMBER;

   W_ERROR_MESSAGE      VARCHAR2 (1000);
   V_GLOB_ENTITY_NUM    NUMBER (6);
   --W_ERROR_MSG          VARCHAR2(2000);
   W_MYEXCEPTION        EXCEPTION;

   V_LAST_DATE          EOD_BALANCE_INVENTORY.LAST_UPDATE_DATE%TYPE;
   V_ENTITY_NUM         INSTALL.INS_ENTITY_NUM%TYPE;

   PROCEDURE SP_MV_LOAN_ACCOUNT_BAL (P_ASON_DATE DATE, P_ERROR OUT VARCHAR2)
   IS
   BEGIN
      V_ASON_DATE := P_ASON_DATE;
      V_MONTH_START_DATE := TRUNC (V_ASON_DATE, 'MONTH');
      V_FIN_YEAR := TO_CHAR (V_ASON_DATE, 'YYYY');

      IF V_MONTH_START_DATE BETWEEN V_LAST_DATE + 1 AND V_CBD
      THEN
         V_SQL_TRUNCATE := 'TRUNCATE TABLE MV_LOAN_ACCOUNT_BAL ';

         EXECUTE IMMEDIATE V_SQL_TRUNCATE;
      END IF;

      IF V_ASON_DATE = V_MONTH_START_DATE
      THEN
      
         V_SQL_TRUNCATE := 'TRUNCATE TABLE MV_LOAN_ACCOUNT_BAL ';
         EXECUTE IMMEDIATE V_SQL_TRUNCATE;
         
         FOR FIN_YEAR IN 2014 .. V_FIN_YEAR
         LOOP
            V_SQL :=
                  'INSERT INTO MV_LOAN_ACCOUNT_BAL
         SELECT /*+ USE_MERGE(TR,T) PARALLEL(16) */
      A.ACNTS_ENTITY_NUM,
       A.ACNTS_BRN_CODE,
       TRAN_INTERNAL_ACNUM,
       TRAN_AMOUNT,
       TRANADV_INTRD_AC_AMT,
       TRANADV_INTRD_BC_AMT,
       TRANADV_CHARGE_BC_AMT,
       TRAN_DB_CR_FLG,
       TRAN_DATE_OF_TRAN,
       TRAN_VALUE_DATE,TRANADV_PRIN_AC_AMT, TRANADV_PRIN_BC_AMT
  FROM TRANADV'
               || FIN_YEAR
               || ' T,
       TRAN'
               || FIN_YEAR
               || ' TR,
       LOANACNTS L,
       ACNTS A
 WHERE     TRANADV_BRN_CODE = TRAN_BRN_CODE
       AND TRAN_DATE_OF_TRAN = TRANADV_DATE_OF_TRAN
       AND TRANADV_BATCH_NUMBER = TRAN_BATCH_NUMBER
       AND TRANADV_BATCH_SL_NUM = TRAN_BATCH_SL_NUM
       --AND ACNTS_GLACC_CODE = TRAN_GLACC_CODE
       AND L.LNACNT_INTERNAL_ACNUM = TR.TRAN_INTERNAL_ACNUM
       AND L.LNACNT_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
       AND A.ACNTS_INTERNAL_ACNUM = TR.TRAN_INTERNAL_ACNUM
       AND TR.TRAN_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND TRANADV_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND L.LNACNT_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND TRAN_VALUE_DATE >=
              TRUNC (NVL (L.LNACNT_INT_ACCR_UPTO, A.ACNTS_OPENING_DATE),
                     ''MM'')
       AND TRAN_DATE_OF_TRAN <= '
               || ''''
               || V_ASON_DATE
               || ''''
               || '
       AND TRAN_AUTH_ON IS NOT NULL
       AND (A.ACNTS_CLOSURE_DATE IS NULL OR A.ACNTS_CLOSURE_DATE = TRAN_DATE_OF_TRAN)';

            EXECUTE IMMEDIATE V_SQL;
         END LOOP;
      ELSE
         V_SQL :=
               'INSERT INTO MV_LOAN_ACCOUNT_BAL
         SELECT /*+ USE_MERGE(TR,T) PARALLEL(16) */
      A.ACNTS_ENTITY_NUM,
       A.ACNTS_BRN_CODE,
       TRAN_INTERNAL_ACNUM,
       TRAN_AMOUNT,
       TRANADV_INTRD_AC_AMT,
       TRANADV_INTRD_BC_AMT,
       TRANADV_CHARGE_BC_AMT,
       TRAN_DB_CR_FLG,
       TRAN_DATE_OF_TRAN,
       TRAN_VALUE_DATE,TRANADV_PRIN_AC_AMT, TRANADV_PRIN_BC_AMT
  FROM TRANADV'
            || V_FIN_YEAR
            || ' T,
       TRAN'
            || V_FIN_YEAR
            || ' TR,
       LOANACNTS L,
       ACNTS A
 WHERE     TRANADV_BRN_CODE = TRAN_BRN_CODE
       AND TRAN_DATE_OF_TRAN = TRANADV_DATE_OF_TRAN
       AND TRANADV_BATCH_NUMBER = TRAN_BATCH_NUMBER
       AND TRANADV_BATCH_SL_NUM = TRAN_BATCH_SL_NUM
       --AND ACNTS_GLACC_CODE = TRAN_GLACC_CODE
       AND L.LNACNT_INTERNAL_ACNUM = TR.TRAN_INTERNAL_ACNUM
       AND L.LNACNT_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
       AND A.ACNTS_INTERNAL_ACNUM = TR.TRAN_INTERNAL_ACNUM
       AND TR.TRAN_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND TRANADV_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND L.LNACNT_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND TRAN_VALUE_DATE >=
              TRUNC (NVL (L.LNACNT_INT_ACCR_UPTO, A.ACNTS_OPENING_DATE),
                     ''MM'')
       AND TRAN_DATE_OF_TRAN = '
            || ''''
            || V_ASON_DATE
            || ''''
            || '
       AND TRAN_AUTH_ON IS NOT NULL
       AND (A.ACNTS_CLOSURE_DATE IS NULL OR A.ACNTS_CLOSURE_DATE = TRAN_DATE_OF_TRAN)';


         EXECUTE IMMEDIATE V_SQL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR_MESSAGE := SQLERRM;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                      'X',
                                      W_ERROR_MESSAGE,
                                      ' ',
                                      0);
         RAISE W_MYEXCEPTION;
   END SP_MV_LOAN_ACCOUNT_BAL;



   PROCEDURE SP_MV_DAY_ACCOUNT_BAL (P_ASON_DATE DATE, P_ERROR OUT VARCHAR2)
   IS
   BEGIN
      V_ASON_DATE := P_ASON_DATE;
      V_MONTH_START_DATE := TRUNC (V_ASON_DATE, 'MONTH');
      V_FIN_YEAR := TO_CHAR (V_ASON_DATE, 'YYYY');


      IF V_MONTH_START_DATE BETWEEN V_LAST_DATE + 1 AND V_CBD
      THEN
         V_SQL_TRUNCATE := 'TRUNCATE TABLE MV_DAY_ACCOUNT_BAL ';

         EXECUTE IMMEDIATE V_SQL_TRUNCATE;
      END IF;

      IF V_ASON_DATE = V_MONTH_START_DATE
      THEN
         V_SQL :=
               'INSERT INTO MV_DAY_ACCOUNT_BAL
         SELECT /*+PARALLEL(16) */
        ACNTS_ENTITY_NUM,
         ACNTS_BRN_CODE,
         TRAN_INTERNAL_ACNUM,
         TRAN_DATE_OF_TRAN,
         SUM (DECODE (TRAN_DB_CR_FLG, ''C'', TRAN_AMOUNT, -TRAN_AMOUNT))
            TRAN_AMOUNT,
         COUNT (
            *)
         OVER (
            PARTITION BY ACNTS_ENTITY_NUM,
                         ACNTS_BRN_CODE,
                         TRAN_INTERNAL_ACNUM,
                         TRAN_DATE_OF_TRAN)
            NUMBER_OF_TRAN
    FROM (SELECT P.ACNTS_ENTITY_NUM,
                 P.ACNTS_BRN_CODE,
                 T.TRAN_INTERNAL_ACNUM,
                 TRAN_DATE_OF_TRAN AS TRAN_DATE_OF_TRAN,
                 TRAN_DB_CR_FLG AS TRAN_DB_CR_FLG,
                 TRAN_AMOUNT AS TRAN_AMOUNT
            FROM TRAN'
            || V_FIN_YEAR
            || ' T, ACNTS P, RAPARAM R
           WHERE     P.ACNTS_INTERNAL_ACNUM = T.TRAN_INTERNAL_ACNUM
                 AND P.ACNTS_AC_TYPE = R.RAPARAM_AC_TYPE
                 AND P.ACNTS_ENTITY_NUM = T.TRAN_ENTITY_NUM
                 AND P.ACNTS_BRN_CODE = T.TRAN_ACING_BRN_CODE
                 AND P.ACNTS_GLACC_CODE = T.TRAN_GLACC_CODE
                 AND P.ACNTS_CLOSURE_DATE IS NULL
                 AND T.TRAN_DATE_OF_TRAN <= TO_DATE(('
            || ''''
            || V_ASON_DATE
            || ''''
            || '))
                 AND R.RAPARAM_INT_FOR_CR_BAL = ''1''
                 AND (   R.RAPARAM_CRINT_PROD_BASIS = ''1''
                      OR R.RAPARAM_CRINT_PROD_BASIS = ''2'')
                 AND R.RAPARAM_CRINT_BASIS = ''M''
                 AND (RAPARAM_CRINT_ACCR_FREQ = ''M'')
                 AND (TRAN_AMOUNT > 0 OR TRAN_BASE_CURR_EQ_AMT > 0)
                 AND TRAN_AUTH_ON IS NOT NULL
                 AND TRAN_ENTD_BY <> ''MIG''
                 AND TRAN_DATE_OF_TRAN BETWEEN (CASE
                                                 WHEN P.ACNTS_MMB_INT_ACCR_UPTO
                                                         IS NOT NULL
                                                 THEN
                                                      P.ACNTS_MMB_INT_ACCR_UPTO
                                                    + 1
                                                 WHEN P.ACNTS_BASE_DATE IS NULL
                                                 THEN
                                                    P.ACNTS_OPENING_DATE
                                                 WHEN P.ACNTS_OPENING_DATE >=
                                                         P.ACNTS_BASE_DATE
                                                 THEN
                                                    P.ACNTS_BASE_DATE
                                                 ELSE
                                                    P.ACNTS_OPENING_DATE
                                              END)
                                         AND TO_DATE('
            || ''''
            || V_ASON_DATE
            || ''''
            || '))
GROUP BY ACNTS_ENTITY_NUM,
         ACNTS_BRN_CODE,
         TRAN_INTERNAL_ACNUM,
         TRAN_DATE_OF_TRAN';

         --INSERT INTO SBS2_DATA_CLOB VALUES(V_SQL) ;
         --COMMIT ;


         --DBMS_OUTPUT.PUT_LINE (V_SQL) ;
         EXECUTE IMMEDIATE V_SQL;
      ELSE
         V_SQL :=
               'INSERT INTO MV_DAY_ACCOUNT_BAL
         SELECT /*+PARALLEL(16) */
        ACNTS_ENTITY_NUM,
         ACNTS_BRN_CODE,
         TRAN_INTERNAL_ACNUM,
         TRAN_DATE_OF_TRAN,
         SUM (DECODE (TRAN_DB_CR_FLG, ''C'', TRAN_AMOUNT, -TRAN_AMOUNT))
            TRAN_AMOUNT,
         COUNT (
            *)
         OVER (
            PARTITION BY ACNTS_ENTITY_NUM,
                         ACNTS_BRN_CODE,
                         TRAN_INTERNAL_ACNUM,
                         TRAN_DATE_OF_TRAN)
            NUMBER_OF_TRAN
    FROM (SELECT P.ACNTS_ENTITY_NUM,
                 P.ACNTS_BRN_CODE,
                 T.TRAN_INTERNAL_ACNUM,
                 TRAN_DATE_OF_TRAN AS TRAN_DATE_OF_TRAN,
                 TRAN_DB_CR_FLG AS TRAN_DB_CR_FLG,
                 TRAN_AMOUNT AS TRAN_AMOUNT
            FROM TRAN'
            || V_FIN_YEAR
            || ' T, ACNTS P, RAPARAM R
           WHERE     P.ACNTS_INTERNAL_ACNUM = T.TRAN_INTERNAL_ACNUM
                 AND P.ACNTS_AC_TYPE = R.RAPARAM_AC_TYPE
                 AND P.ACNTS_ENTITY_NUM = T.TRAN_ENTITY_NUM
                 AND P.ACNTS_BRN_CODE = T.TRAN_ACING_BRN_CODE
                 AND P.ACNTS_GLACC_CODE = T.TRAN_GLACC_CODE
                 AND P.ACNTS_CLOSURE_DATE IS NULL
                 AND T.TRAN_DATE_OF_TRAN ='
            || ''''
            || V_ASON_DATE
            || ''''
            || '
                 AND R.RAPARAM_INT_FOR_CR_BAL = ''1''
                 AND TO_CHAR(T.TRAN_DATE_OF_TRAN, ''YYYY'') =  '
            || V_FIN_YEAR
            || '
                 AND (   R.RAPARAM_CRINT_PROD_BASIS = ''1''
                      OR R.RAPARAM_CRINT_PROD_BASIS = ''2'')
                 AND R.RAPARAM_CRINT_BASIS = ''M''
                 AND (RAPARAM_CRINT_ACCR_FREQ = ''M'')
                 AND (TRAN_AMOUNT > 0 OR TRAN_BASE_CURR_EQ_AMT > 0)
                 AND TRAN_AUTH_ON IS NOT NULL
                 AND TRAN_ENTD_BY <> ''MIG'')
GROUP BY ACNTS_ENTITY_NUM,
         ACNTS_BRN_CODE,
         TRAN_INTERNAL_ACNUM,
         TRAN_DATE_OF_TRAN';

         --INSERT INTO SBS2_DATA_CLOB VALUES(V_SQL) ;
         --COMMIT ;

         --DBMS_OUTPUT.PUT_LINE (V_SQL) ;
         EXECUTE IMMEDIATE V_SQL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR_MESSAGE := SQLERRM;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                      'X',
                                      W_ERROR_MESSAGE,
                                      ' ',
                                      0);
         RAISE W_MYEXCEPTION;
   END SP_MV_DAY_ACCOUNT_BAL;



   PROCEDURE SP_MV_LOAN_ACCOUNT_BAL_OD (P_ASON_DATE       DATE,
                                        P_ERROR       OUT VARCHAR2)
   IS
   BEGIN
      V_ASON_DATE := P_ASON_DATE;
      V_MONTH_START_DATE := TRUNC (V_ASON_DATE, 'MONTH');
      V_FIN_YEAR := TO_CHAR (V_ASON_DATE, 'YYYY');


      IF V_MONTH_START_DATE BETWEEN V_LAST_DATE + 1 AND V_CBD
      THEN
         V_SQL_TRUNCATE := 'TRUNCATE TABLE MV_LOAN_ACCOUNT_BAL_OD ';

         EXECUTE IMMEDIATE V_SQL_TRUNCATE;
      END IF;

      IF V_ASON_DATE = V_MONTH_START_DATE
      THEN
         V_SQL_TRUNCATE := 'TRUNCATE TABLE MV_LOAN_ACCOUNT_BAL_OD ';
         EXECUTE IMMEDIATE V_SQL_TRUNCATE;
         
         
         FOR FIN_YEAR IN 2014 .. V_FIN_YEAR
         LOOP
                V_SQL :=
                      'INSERT INTO MV_LOAN_ACCOUNT_BAL_OD
                    SELECT /*+PARALLEL(16) */
           '
                   || FIN_YEAR
                   || ' VALUE_YEAR,
           TRAN_INTERNAL_ACNUM,
           TRANADV_INTRD_BC_AMT,
           TRANADV_CHARGE_BC_AMT,
           TRAN_DB_CR_FLG,
           TRAN_DATE_OF_TRAN
      FROM LOANACNTS L,
           ACNTS A,
           TRANADV'
                   || FIN_YEAR
                   || ' T,
           TRAN'
                   || FIN_YEAR
                   || ' TR
     WHERE     TR.TRAN_ENTITY_NUM = A.ACNTS_ENTITY_NUM
           AND TRANADV_ENTITY_NUM = A.ACNTS_ENTITY_NUM
           AND TRANADV_BRN_CODE = TRAN_BRN_CODE
           AND TRAN_DATE_OF_TRAN = TRANADV_DATE_OF_TRAN
           AND TRANADV_BATCH_NUMBER = TRAN_BATCH_NUMBER
           AND TRANADV_BATCH_SL_NUM = TRAN_BATCH_SL_NUM
           AND L.LNACNT_INTERNAL_ACNUM = TR.TRAN_INTERNAL_ACNUM
           AND L.LNACNT_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
           AND A.ACNTS_INTERNAL_ACNUM = TR.TRAN_INTERNAL_ACNUM
           AND TRAN_DATE_OF_TRAN <= '
                   || ''''
                   || V_ASON_DATE
                   || ''''
                   || '
           AND TRAN_AUTH_ON IS NOT NULL
           AND (TRANADV_INTRD_BC_AMT <> 0 OR TRANADV_CHARGE_BC_AMT <> 0)';

                EXECUTE IMMEDIATE V_SQL;
         END LOOP;
      ELSE
         V_SQL :=
               'INSERT INTO MV_LOAN_ACCOUNT_BAL_OD
                SELECT /*+PARALLEL(16) */
       '
            || V_FIN_YEAR
            || ' VALUE_YEAR,
       TRAN_INTERNAL_ACNUM,
       TRANADV_INTRD_BC_AMT,
       TRANADV_CHARGE_BC_AMT,
       TRAN_DB_CR_FLG,
       TRAN_DATE_OF_TRAN
  FROM LOANACNTS L,
       ACNTS A,
       TRANADV'
            || V_FIN_YEAR
            || ' T,
       TRAN'
            || V_FIN_YEAR
            || ' TR
 WHERE     TR.TRAN_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND TRANADV_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND TRANADV_BRN_CODE = TRAN_BRN_CODE
       AND TRAN_DATE_OF_TRAN = TRANADV_DATE_OF_TRAN
       AND TRANADV_BATCH_NUMBER = TRAN_BATCH_NUMBER
       AND TRANADV_BATCH_SL_NUM = TRAN_BATCH_SL_NUM
       AND L.LNACNT_INTERNAL_ACNUM = TR.TRAN_INTERNAL_ACNUM
       AND L.LNACNT_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
       AND A.ACNTS_INTERNAL_ACNUM = TR.TRAN_INTERNAL_ACNUM
       AND TRAN_DATE_OF_TRAN = '
            || ''''
            || V_ASON_DATE
            || ''''
            || '
       AND TRAN_AUTH_ON IS NOT NULL
       AND (TRANADV_INTRD_BC_AMT <> 0 OR TRANADV_CHARGE_BC_AMT <> 0)';

         EXECUTE IMMEDIATE V_SQL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR_MESSAGE := SQLERRM;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                      'X',
                                      W_ERROR_MESSAGE,
                                      ' ',
                                      0);
         RAISE W_MYEXCEPTION;
   END SP_MV_LOAN_ACCOUNT_BAL_OD;



   PROCEDURE SP_MV_SB_ACCOUNT_PERSENT (P_ASON_DATE       DATE,
                                       P_ERROR       OUT VARCHAR2)
   IS
   BEGIN
      V_ASON_DATE := P_ASON_DATE;
      V_MONTH_START_DATE := TRUNC (V_ASON_DATE, 'MONTH');
      V_MONTH_LAST_DATE := LAST_DAY (V_ASON_DATE);
      V_FIN_YEAR := TO_CHAR (V_ASON_DATE, 'YYYY');


      IF V_MONTH_START_DATE BETWEEN V_LAST_DATE + 1 AND V_CBD
      THEN
         V_SQL_TRUNCATE := 'TRUNCATE TABLE MV_SB_ACCOUNT_PERSENT ';

         EXECUTE IMMEDIATE V_SQL_TRUNCATE;
      END IF;

      IF V_ASON_DATE = V_MONTH_LAST_DATE
      THEN
         V_SQL :=
               'INSERT INTO MV_SB_ACCOUNT_PERSENT
                SELECT /*+PARALLEL(16) */
      ACBALH_ENTITY_NUM SB_ENTITY_NUM,
       ACBALH_INTERNAL_ACNUM SB_INTERNAL_ACNUM,
       ACNTS_BRN_CODE SB_BRN_CODE,
       TO_CHAR (TRAN_DATE_OF_TRAN, ''MM'') TRAN_MONTH,
       WITHWRAL_PERSENT,
       RAOPERPARAM_PERCENT_WITHDRAW,
       DEBIT_AMOUNT,
       PREVIOUS_TRAN_BAL
  FROM (SELECT ACBALH_ENTITY_NUM,
               ACBALH_INTERNAL_ACNUM,
               RAOPERPARAM_PERCENT_WITHDRAW,
               ACNTS_BRN_CODE,
               TRAN_DATE_OF_TRAN,
               CREDIT_AMOUNT,
               DEBIT_AMOUNT,
               ACCOUNT_BALANCE,
               PREVIOUS_TRAN_BAL,
               ROUND (
                  (CASE
                      WHEN DEBIT_AMOUNT > 0 AND PREVIOUS_TRAN_BAL > 0
                      THEN
                         (DEBIT_AMOUNT / PREVIOUS_TRAN_BAL) * 100
                      ELSE
                         0
                   END))
                  WITHWRAL_PERSENT
          FROM (SELECT ACBALH_ENTITY_NUM,
                       ACBALH_INTERNAL_ACNUM,
                       RAOPERPARAM_PERCENT_WITHDRAW,
                       ACNTS_BRN_CODE,
                       TRAN_DATE_OF_TRAN,
                       CREDIT_AMOUNT,
                       DEBIT_AMOUNT,
                       ACCOUNT_BALANCE,
                       LAG (
                          ACCOUNT_BALANCE)
                       OVER (PARTITION BY ACBALH_INTERNAL_ACNUM
                             ORDER BY TRAN_DATE_OF_TRAN)
                          PREVIOUS_TRAN_BAL
                  FROM (SELECT ACBALH_ENTITY_NUM,
                               ACBALH_INTERNAL_ACNUM,
                               RAOPERPARAM_PERCENT_WITHDRAW,
                               ACNTS_BRN_CODE,
                               TRAN_DATE_OF_TRAN,
                               CREDIT_AMOUNT,
                               DEBIT_AMOUNT,
                               SUM (CREDIT_AMOUNT - DEBIT_AMOUNT)
                                  OVER (PARTITION BY ACBALH_INTERNAL_ACNUM
                                        ORDER BY
                                           ACBALH_INTERNAL_ACNUM,
                                           TRAN_DATE_OF_TRAN,
                                           TRAN_AUTH_ON,
                                           TRAN_BATCH_NUMBER,
                                           TRAN_BATCH_SL_NUM)
                                  ACCOUNT_BALANCE
                          FROM (SELECT ACBALH_ENTITY_NUM,
                                       ACBALH_INTERNAL_ACNUM,
                                       RAOPERPARAM_PERCENT_WITHDRAW,
                                       ACNTS_BRN_CODE,
                                       ACBALH_ASON_DATE TRAN_DATE_OF_TRAN,
                                       0 TRAN_BATCH_NUMBER,
                                       0 TRAN_BATCH_SL_NUM,
                                       ACBALH_ASON_DATE TRAN_AUTH_ON,
                                       (CASE
                                           WHEN ACBALH_AC_BAL <= 0
                                           THEN
                                              ABS (ACBALH_AC_BAL)
                                           ELSE
                                              0
                                        END)
                                          DEBIT_AMOUNT,
                                       (CASE
                                           WHEN ACBALH_AC_BAL >= 0
                                           THEN
                                              ACBALH_AC_BAL
                                           ELSE
                                              0
                                        END)
                                          CREDIT_AMOUNT
                                  FROM (SELECT ACBALH_ENTITY_NUM,
                                               ACBALH_INTERNAL_ACNUM,
                                               RAOPERPARAM_PERCENT_WITHDRAW,
                                               ACNTS_BRN_CODE,
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
                                          FROM ACBALASONHIST BAL,
                                               RAPARAM R,
                                               ACNTS A,
                                               RAOPERPARAM RR
                                         WHERE     A.ACNTS_AC_TYPE =
                                                      R.RAPARAM_AC_TYPE
                                               AND BAL.ACBALH_ENTITY_NUM =
                                                      A.ACNTS_ENTITY_NUM
                                               AND BAL.ACBALH_INTERNAL_ACNUM =
                                                      A.ACNTS_INTERNAL_ACNUM
                                               AND RR.RAOPER_AC_TYPE =
                                                      A.ACNTS_AC_TYPE
                                               AND RR.RAOPER_AC_SUB_TYPE =
                                                      A.ACNTS_AC_SUB_TYPE
                                               AND RR.RAOPER_CURR_CODE =
                                                      A.ACNTS_CURR_CODE
                                               AND RR.RAOPERPARAM_AMT_RESTRIC =
                                                      ''1''
                                               AND R.RAPARAM_INT_FOR_CR_BAL =
                                                      ''1''
                                               AND (   R.RAPARAM_CRINT_PROD_BASIS =
                                                          ''1''
                                                    OR R.RAPARAM_CRINT_PROD_BASIS =
                                                          ''2'')
                                               AND R.RAPARAM_CRINT_BASIS =
                                                      ''M''
                                               AND (RAPARAM_CRINT_ACCR_FREQ =
                                                       ''M'')
                                               AND ACBALH_ASON_DATE <
                                                      (CASE
                                                          WHEN A.ACNTS_MMB_INT_ACCR_UPTO
                                                                  IS NOT NULL
                                                          THEN
                                                               A.ACNTS_MMB_INT_ACCR_UPTO
                                                             + 1
                                                          WHEN A.ACNTS_BASE_DATE
                                                                  IS NULL
                                                          THEN
                                                             A.ACNTS_OPENING_DATE
                                                          WHEN A.ACNTS_OPENING_DATE >=
                                                                  A.ACNTS_BASE_DATE
                                                          THEN
                                                             A.ACNTS_BASE_DATE
                                                          ELSE
                                                             A.ACNTS_OPENING_DATE
                                                       END))
                                 WHERE SERIAL = 1
                                UNION ALL
                                SELECT A.ACNTS_ENTITY_NUM,
                                       T.TRAN_INTERNAL_ACNUM,
                                       RAOPERPARAM_PERCENT_WITHDRAW,
                                       A.ACNTS_BRN_CODE,
                                       TRAN_DATE_OF_TRAN AS TRAN_DATE_OF_TRAN,
                                       TRAN_BATCH_NUMBER,
                                       TRAN_BATCH_SL_NUM,
                                       TRAN_AUTH_ON,
                                       (CASE
                                           WHEN TRAN_DB_CR_FLG = ''D''
                                           THEN
                                              NVL (TRAN_AMOUNT, 0)
                                           ELSE
                                              0
                                        END)
                                          DEBIT_AMOUNT,
                                       (CASE
                                           WHEN TRAN_DB_CR_FLG = ''C''
                                           THEN
                                              NVL (TRAN_AMOUNT, 0)
                                           ELSE
                                              0
                                        END)
                                          CREDIT_AMOUNT
                                  FROM TRAN'
            || V_FIN_YEAR
            || ' T,
                                       ACNTS A,
                                       RAPARAM R,
                                       RAOPERPARAM RR
                                 WHERE     A.ACNTS_INTERNAL_ACNUM =
                                              T.TRAN_INTERNAL_ACNUM
                                       AND A.ACNTS_AC_TYPE =
                                              R.RAPARAM_AC_TYPE
                                       AND RR.RAOPER_AC_TYPE =
                                              A.ACNTS_AC_TYPE
                                       AND RR.RAOPER_AC_SUB_TYPE =
                                              A.ACNTS_AC_SUB_TYPE
                                       AND RR.RAOPER_CURR_CODE =
                                              A.ACNTS_CURR_CODE
                                       AND RR.RAOPERPARAM_AMT_RESTRIC = ''1''
                                       AND A.ACNTS_ENTITY_NUM =
                                              T.TRAN_ENTITY_NUM
                                       AND A.ACNTS_CLOSURE_DATE IS NULL
                                       AND TRAN_DATE_OF_TRAN <= '
            || ''''
            || V_ASON_DATE
            || ''''
            || '
                                       AND R.RAPARAM_INT_FOR_CR_BAL = ''1''
                                       AND (   R.RAPARAM_CRINT_PROD_BASIS =
                                                  ''1''
                                            OR R.RAPARAM_CRINT_PROD_BASIS =
                                                  ''2'')
                                       AND R.RAPARAM_CRINT_BASIS = ''M''
                                       AND (RAPARAM_CRINT_ACCR_FREQ = ''M'')
                                       AND (   TRAN_AMOUNT > 0
                                            OR TRAN_BASE_CURR_EQ_AMT > 0)
                                       AND TRAN_AUTH_ON IS NOT NULL
                                       AND TRAN_DATE_OF_TRAN BETWEEN (CASE
                                                                         WHEN A.ACNTS_MMB_INT_ACCR_UPTO
                                                                                 IS NOT NULL
                                                                         THEN
                                                                              A.ACNTS_MMB_INT_ACCR_UPTO
                                                                            + 1
                                                                         WHEN A.ACNTS_BASE_DATE
                                                                                 IS NULL
                                                                         THEN
                                                                            A.ACNTS_OPENING_DATE
                                                                         WHEN A.ACNTS_OPENING_DATE >=
                                                                                 A.ACNTS_BASE_DATE
                                                                         THEN
                                                                            A.ACNTS_BASE_DATE
                                                                         ELSE
                                                                            A.ACNTS_OPENING_DATE
                                                                      END)
                                                                 AND '
            || ''''
            || V_ASON_DATE
            || ''''
            || '))))
 WHERE WITHWRAL_PERSENT > RAOPERPARAM_PERCENT_WITHDRAW';

         EXECUTE IMMEDIATE V_SQL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR_MESSAGE := SQLERRM;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                      'X',
                                      W_ERROR_MESSAGE,
                                      ' ',
                                      0);
         RAISE W_MYEXCEPTION;
   END SP_MV_SB_ACCOUNT_PERSENT;



   PROCEDURE SP_MV_MMB_WEEK_TRANSACTION (P_ASON_DATE       DATE,
                                         P_ERROR       OUT VARCHAR2)
   IS
      V_ERR_MSG           VARCHAR2 (200);
      V_WEEK_LAST_DAY     NUMBER;
      V_MONTH_LAST_DATE   DATE;
      V_WEEK_DAY          NUMBER;

      V_FROM_DATE         DATE;

      V_UPTO_DATE         DATE;
      V_LAST_DAY          NUMBER (2);
   BEGIN
      V_ASON_DATE := P_ASON_DATE;

      V_MONTH_START_DATE := TRUNC (V_ASON_DATE, 'MONTH');

      V_FIN_YEAR := TO_CHAR (V_ASON_DATE, 'YYYY');

      V_MONTH_LAST_DATE := LAST_DAY (V_ASON_DATE);



      IF V_MONTH_START_DATE BETWEEN V_LAST_DATE + 1 AND V_CBD
      THEN
         V_SQL_TRUNCATE := 'TRUNCATE TABLE MV_MMB_WEEK_TRANSACTION ';

         EXECUTE IMMEDIATE V_SQL_TRUNCATE;
      END IF;

      IF V_MONTH_LAST_DATE = V_ASON_DATE
      THEN
         V_SQL :=
               'INSERT INTO MV_MMB_WEEK_TRANSACTION
         SELECT /*+PARALLEL(16) */
        ACNTS_ENTITY_NUM,
         ACNTS_BRN_CODE,
         ACNTS_INTERNAL_ACNUM,
         TRAN_WEEK,
         TRAN_MONTH_YEAR,
         SUM (NUMBER_OF_TRAN) NUMBER_OF_TRAN,
         MAX (MAX_WITHWRAL) MAX_WITHWRAL
    FROM (  SELECT ACNTS_ENTITY_NUM,
                   ACNTS_BRN_CODE,
                   ACNTS_INTERNAL_ACNUM,
                   TO_NUMBER (TO_CHAR (T.TRAN_DATE_OF_TRAN, ''DD''))
                      TRAN_DAY_NUMBER,
                   TO_CHAR (T.TRAN_DATE_OF_TRAN, ''MON-YYYY'') TRAN_MONTH_YEAR,
                   COUNT (TRAN_INTERNAL_ACNUM) NUMBER_OF_TRAN,
                   SUM (TRAN_AMOUNT) TRAN_AMOUNT,
                   MAX (TRAN_AMOUNT) MAX_WITHWRAL,
                   (CASE
                       WHEN TO_NUMBER (TO_CHAR (T.TRAN_DATE_OF_TRAN, ''DD'')) BETWEEN 1
                                                                                AND 7
                       THEN
                          ''1''
                       WHEN TO_NUMBER (TO_CHAR (T.TRAN_DATE_OF_TRAN, ''DD'')) BETWEEN 8
                                                                                AND 14
                       THEN
                          ''2''
                       WHEN TO_NUMBER (TO_CHAR (T.TRAN_DATE_OF_TRAN, ''DD'')) BETWEEN 15
                                                                                AND 21
                       THEN
                          ''3''
                       WHEN TO_NUMBER (TO_CHAR (T.TRAN_DATE_OF_TRAN, ''DD'')) BETWEEN 22
                                                                                AND 28
                       THEN
                          ''4''
                       ELSE
                          ''5''
                    END)
                      TRAN_WEEK
              FROM TRAN'
            || V_FIN_YEAR
            || ' T, ACNTS A, RAPARAM R
             WHERE     A.ACNTS_INTERNAL_ACNUM = T.TRAN_INTERNAL_ACNUM
                   AND A.ACNTS_AC_TYPE = R.RAPARAM_AC_TYPE
                   AND A.ACNTS_ENTITY_NUM = T.TRAN_ENTITY_NUM
                   AND A.ACNTS_CLOSURE_DATE IS NULL
                   AND T.TRAN_DATE_OF_TRAN <= '
            || ''''
            || V_ASON_DATE
            || ''''
            || '
                   AND R.RAPARAM_INT_FOR_CR_BAL = ''1''
                   AND (   R.RAPARAM_CRINT_PROD_BASIS = ''1''
                        OR R.RAPARAM_CRINT_PROD_BASIS = ''2'')
                   AND R.RAPARAM_CRINT_BASIS = ''M''
                   AND (RAPARAM_CRINT_ACCR_FREQ = ''M'')
                   AND T.TRAN_DB_CR_FLG = ''D''
                   AND T.TRAN_SYSTEM_POSTED_TRAN = ''0''
                   AND T.TRAN_AUTH_ON IS NOT NULL
                   AND (   TRIM (T.TRAN_NOTICE_REF_NUM) IS NULL )
                   AND (T.TRAN_AMOUNT > 0 OR T.TRAN_BASE_CURR_EQ_AMT > 0)
                   AND T.TRAN_AUTH_ON IS NOT NULL
                   AND T.TRAN_ENTD_BY <> ''MIG''
                   AND TRAN_DATE_OF_TRAN BETWEEN (CASE
                                                   WHEN A.ACNTS_MMB_INT_ACCR_UPTO
                                                           IS NOT NULL
                                                   THEN
                                                        A.ACNTS_MMB_INT_ACCR_UPTO
                                                      + 1
                                                   WHEN A.ACNTS_BASE_DATE IS NULL
                                                   THEN
                                                      A.ACNTS_OPENING_DATE
                                                   WHEN A.ACNTS_OPENING_DATE >=
                                                           A.ACNTS_BASE_DATE
                                                   THEN
                                                      A.ACNTS_BASE_DATE
                                                   ELSE
                                                      A.ACNTS_OPENING_DATE
                                                END)
                                           AND '
            || ''''
            || V_ASON_DATE
            || ''''
            || '
          GROUP BY ACNTS_ENTITY_NUM,
                   ACNTS_BRN_CODE,
                   ACNTS_INTERNAL_ACNUM,
                   TO_NUMBER (TO_CHAR (T.TRAN_DATE_OF_TRAN, ''DD'')),
                   TO_CHAR (T.TRAN_DATE_OF_TRAN, ''MON-YYYY'')
          ORDER BY 1, 2)
GROUP BY ACNTS_ENTITY_NUM,
         ACNTS_BRN_CODE,
         ACNTS_INTERNAL_ACNUM,
         TRAN_WEEK,
         TRAN_MONTH_YEAR';

         --INSERT INTO SBS2_DATA_CLOB VALUES(V_SQL) ;
         --COMMIT ;
         --DBMS_OUTPUT.PUT_LINE (V_SQL);
         EXECUTE IMMEDIATE V_SQL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR_MESSAGE := SQLERRM;
         P_ERROR := SQLERRM;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                      'X',
                                      W_ERROR_MESSAGE,
                                      ' ',
                                      0);
         RAISE W_MYEXCEPTION;
   END SP_MV_MMB_WEEK_TRANSACTION;

   PROCEDURE SP_PROCESS_DAY (P_ENTITY_NUM IN NUMBER)
   IS
      --V_CBD               MAINCONT.MN_CURR_BUSINESS_DATE%TYPE;
      V_ERROR             VARCHAR2 (100);
      V_OD_PROCESS_FREQ   VARCHAR2 (1);
   BEGIN
      V_ENTITY_NUM := P_ENTITY_NUM;

      SELECT LAST_UPDATE_DATE INTO V_LAST_DATE FROM EOD_BALANCE_INVENTORY;

      V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_ENTITY_NUM);

      WHILE V_LAST_DATE < V_CBD
      LOOP
         SP_MV_LOAN_ACCOUNT_BAL (V_LAST_DATE + 1, V_ERROR);

         SP_MV_DAY_ACCOUNT_BAL (V_LAST_DATE + 1, V_ERROR);

         SP_MV_LOAN_ACCOUNT_BAL_OD (V_LAST_DATE + 1, V_ERROR);

         SP_MV_SB_ACCOUNT_PERSENT (V_LAST_DATE + 1, V_ERROR);

         SP_MV_MMB_WEEK_TRANSACTION (V_LAST_DATE + 1, V_ERROR);

         IF V_ERROR IS NULL
         THEN
            INSERT INTO EODSODPROCBRN (EODSODPROCBRN_ENTITY_NUM,
                                       PROC_TYPE,
                                       PROC_NAME,
                                       PROC_DATE,
                                       PROC_BRN_CODE,
                                       PROC_PROD_CODE)
                 VALUES (V_ENTITY_NUM,
                         'E',
                         'PKG_MV_REFRESH.SP_PROCESS_DAY',
                         V_LAST_DATE + 1,
                         0,
                         0);
         END IF;

         UPDATE EOD_BALANCE_INVENTORY
            SET LAST_UPDATE_DATE = V_LAST_DATE + 1;

         V_LAST_DATE := V_LAST_DATE + 1;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := V_ERROR;

         IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NOT NULL
         THEN
            EXIT;
         END IF;
      END LOOP;

      IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
      THEN
         PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (V_ENTITY_NUM);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR_MESSAGE := V_ERROR || '  ' || SQLERRM;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                      'X',
                                      W_ERROR_MESSAGE,
                                      ' ',
                                      0);
         RAISE W_MYEXCEPTION;
   END SP_PROCESS_DAY;


   PROCEDURE SP_PROCESS_DAY_MANUAL_LOAN (P_ENTITY_NUM    IN NUMBER,
                                         P_PROCESS_DAY   IN DATE)
   IS
      V_ERROR   VARCHAR2 (100);
   BEGIN
      V_ENTITY_NUM := P_ENTITY_NUM;

      V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_ENTITY_NUM);

      DELETE FROM MV_LOAN_ACCOUNT_BAL
            WHERE TRAN_DATE_OF_TRAN = P_PROCESS_DAY;

      SP_MV_LOAN_ACCOUNT_BAL (P_PROCESS_DAY, V_ERROR);

      DELETE FROM MV_LOAN_ACCOUNT_BAL_OD
            WHERE TRAN_DATE_OF_TRAN = P_PROCESS_DAY;

      SP_MV_LOAN_ACCOUNT_BAL_OD (P_PROCESS_DAY, V_ERROR);
   END SP_PROCESS_DAY_MANUAL_LOAN;
END PKG_MV_REFRESH;
/
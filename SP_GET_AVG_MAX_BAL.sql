CREATE OR REPLACE PROCEDURE SP_GET_AVG_MAX_BAL (
   P_ENTITY_NUM      IN     NUMBER,
   P_DEP_PROD_CODE   IN     NUMBER,
   P_AC_NUMBER       IN     NUMBER,
   P_CURR_CODE       IN     CHAR,
   P_AVG_BAL            OUT FLOAT,
   P_MAX_BAL            OUT FLOAT,
   P_ERR_MSG            OUT VARCHAR2)
IS
   V_ACBALH_AC_BAL         NUMBER (18, 3);
   V_ERR_MSG               VARCHAR2 (2300);
   V_CURR_DATE             DATE;
   V_AVG_BAL               NUMBER (18, 3);
   W_MAX_BAL               NUMBER (18, 3);
   W_ACNTS_BRN_CODE        ACNTS.ACNTS_BRN_CODE%TYPE;
   W_ACNTS_OPENING_DATE    ACNTS.ACNTS_OPENING_DATE%TYPE;
   W_MIG_END_DATE          MIG_DETAIL.MIG_END_DATE%TYPE;
   W_LAST_CHARG_DED_DATE   ACNTCHARGEAMT.ACNTCHGAMT_PROCESS_DATE%TYPE;
   W_CHARGE_FROM_DATE      DATE;

   V_AVG_START_DATE        DATE;
   V_MIG_ACCOUNT           VARCHAR2 (1) := 'N';
   W_LAST_TRAN_DATE        DATE;

   FUNCTION CHECK_INPUT_VALUES
      RETURN BOOLEAN
   IS
   BEGIN
      IF TRIM (P_AC_NUMBER) IS NULL
      THEN
         V_ERR_MSG := 'Account Number should be specified';
         RETURN FALSE;
      END IF;

      IF TRIM (P_DEP_PROD_CODE) IS NULL
      THEN
         V_ERR_MSG := 'Product Code should be specified';
         RETURN FALSE;
      END IF;

      IF TRIM (P_CURR_CODE) IS NULL
      THEN
         V_ERR_MSG := 'Currency Code Should be Specified';
         RETURN FALSE;
      END IF;

      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_ERR_MSG := 'Error in CHECK_INPUT_VALUES';
         RETURN FALSE;
   END CHECK_INPUT_VALUES;

   PROCEDURE SP_GENERAT_ACCOUNT_INFORMATION (P_ACCOUNT_NUMBER NUMBER)
   IS
      V_SQL_STATEMENT   VARCHAR2 (4000);
   BEGIN
      V_SQL_STATEMENT :=
         'SELECT ACNTS_BRN_CODE,ACNTS_OPENING_DATE, MIG_END_DATE, ACNTS_LAST_TRAN_DATE
                  FROM MIG_DETAIL M, ACNTS A
                 WHERE     BRANCH_CODE = ACNTS_BRN_CODE
                       AND ACNTS_ENTITY_NUM = :ENTITY_NUMBER
                       AND ACNTS_INTERNAL_ACNUM = :ACCOUNT_NUMBER';

      EXECUTE IMMEDIATE V_SQL_STATEMENT
         INTO W_ACNTS_BRN_CODE,
              W_ACNTS_OPENING_DATE,
              W_MIG_END_DATE,
              W_LAST_TRAN_DATE
         USING P_ENTITY_NUM, P_ACCOUNT_NUMBER;

      BEGIN
         SELECT MAX (ACNTCHGAMT_PROCESS_DATE) LAST_CHARG_DED_DATE
           INTO W_LAST_CHARG_DED_DATE
           FROM ACNTCHARGEAMT
          WHERE     ACNTCHGAMT_ENTITY_NUM = P_ENTITY_NUM
                AND ACNTCHGAMT_BRN_CODE = W_ACNTS_BRN_CODE
                AND ACNTCHGAMT_INTERNAL_ACNUM = P_ACCOUNT_NUMBER;
      END;

      IF W_LAST_CHARG_DED_DATE IS NULL AND W_MIG_END_DATE IS NULL
      THEN
         W_CHARGE_FROM_DATE := W_ACNTS_OPENING_DATE;
      ELSIF W_LAST_CHARG_DED_DATE IS NULL AND W_MIG_END_DATE IS NOT NULL
      THEN                                                         -- MIGRATED
         W_CHARGE_FROM_DATE :=
            GREATEST (W_ACNTS_OPENING_DATE, (W_MIG_END_DATE + 1));
      ELSE
         W_CHARGE_FROM_DATE :=
            GREATEST ( (W_LAST_CHARG_DED_DATE + 1),
                      W_ACNTS_OPENING_DATE,
                      (W_MIG_END_DATE + 1));
      END IF;

      ---- CHECKING HALF YEAR START DATE .... WHEN CURR BUSINESS DAATE IS LESS THEN 30 JUN THEN START DATE SHOULD BE FIRST JANUARY ELSE FIRST JUL

      IF V_CURR_DATE <= (ADD_MONTHS (TRUNC ( (V_CURR_DATE), 'Y'), 6) - 1)
      THEN
         V_AVG_START_DATE := TRUNC ( (V_CURR_DATE), 'Y');
      ELSE
         V_AVG_START_DATE := (ADD_MONTHS (TRUNC ( (V_CURR_DATE), 'Y'), 6));
      END IF;
   END;

   PROCEDURE GET_AVGBAL
   IS
      V_AVG_SQL   CLOB;
   BEGIN
      IF W_MIG_END_DATE >= W_CHARGE_FROM_DATE
      THEN
         V_MIG_ACCOUNT := 'Y';
      END IF;

      V_AVG_SQL :=
         'SELECT ROUND (
            (  (  SUM (AVERAGE_BALANCE)
                + (MIG_DIFF_DAY * MAINTCHAVGBAL_MIG_AVG_BAL))
             / ( DECODE(SUM(TOTAL_DAYS) ,0,1,SUM(TOTAL_DAYS)))),
            2)
            AVERAGE_BALANCE
    FROM (SELECT ASON_TRAN_DATE,
                 NEXT_TRAN_DATE,
                 ACBALH_AC_BAL,
                 NVL (NEXT_TRAN_DATE - ASON_TRAN_DATE, 0) TOTAL_DAYS,
                 (ACBALH_AC_BAL * (NEXT_TRAN_DATE - ASON_TRAN_DATE))
                    AVERAGE_BALANCE,
                 MAINTCHAVGBAL_INTERNAL_ACNUM,
                 MAINTCHAVGBAL_BRN_CODE,
                 MAINTCHAVGBAL_MIG_AVG_BAL,
                 MAINTCHAVGBAL_CHG_EFE_DATE,
                 NVL (
                    (CASE
                        WHEN MAINTCHAVGBAL_MIG_DATE >= :P_HALF_START_DATE
                        THEN
                           (CASE
                               WHEN MAINTCHAVGBAL_OPENING_DATE >
                                       :P_HALF_START_DATE
                               THEN
                                    MAINTCHAVGBAL_MIG_DATE
                                  - MAINTCHAVGBAL_OPENING_DATE
                               ELSE
                                    MAINTCHAVGBAL_MIG_DATE
                                  - :P_HALF_START_DATE
                            END)
                     END),
                    0)
                    MIG_DIFF_DAY
            FROM (SELECT ACBALH_ASON_DATE,
                         (CASE
                             WHEN ACBALH_ASON_DATE < :P_HALF_START_DATE
                             THEN
                                :P_HALF_START_DATE
                             ELSE
                                ACBALH_ASON_DATE
                          END)
                            ASON_TRAN_DATE,
                         (NVL (
                             LEAD (
                                ACBALH_ASON_DATE)
                             OVER (
                                PARTITION BY ACBALH_INTERNAL_ACNUM
                                ORDER BY
                                   ACBALH_INTERNAL_ACNUM,
                                   ACBALH_ASON_DATE NULLS LAST),
                            :P_ASON_DATE))
                            NEXT_TRAN_DATE,
                         ACBALH_AC_BAL,
                         MAINTCHAVGBAL_INTERNAL_ACNUM,
                         MAINTCHAVGBAL_BRN_CODE,
                         MAINTCHAVGBAL_OPENING_DATE,
                         MAINTCHAVGBAL_MIG_DATE,
                         (CASE
                             WHEN MAINTCHAVGBAL_MIG_AVG_BAL < 0 THEN 0
                             ELSE MAINTCHAVGBAL_MIG_AVG_BAL
                          END)
                            MAINTCHAVGBAL_MIG_AVG_BAL,
                         (CASE
                             WHEN MAINTCHAVGBAL_CHG_EFE_DATE >
                                     :P_HALF_START_DATE
                             THEN
                                MAINTCHAVGBAL_CHG_EFE_DATE
                             ELSE
                                :P_HALF_START_DATE
                          END)
                            MAINTCHAVGBAL_CHG_EFE_DATE
                    FROM (SELECT ACNTS_INTERNAL_ACNUM
                                    MAINTCHAVGBAL_INTERNAL_ACNUM,
                                 ACNTS_BRN_CODE MAINTCHAVGBAL_BRN_CODE,
                                 ACNTS_OPENING_DATE MAINTCHAVGBAL_OPENING_DATE,
                                 MIGRATION_DATE MAINTCHAVGBAL_MIG_DATE,
                                 MIGRATION_BALANCE MAINTCHAVGBAL_MIG_AVG_BAL,
                                 MAX_TRANSACTION_DATE MAINTCHAVGBAL_LTRAN_DATE,
                                 (CASE
                                     WHEN LAST_CHARG_DED_DATE IS NOT NULL
                                     THEN
                                        LAST_CHARG_DED_DATE + 1
                                     ELSE
                                        (CASE
                                            WHEN ACNTS_OPENING_DATE >=
                                                    NVL (MIGRATION_DATE,
                                                         ACNTS_OPENING_DATE)
                                            THEN
                                               ACNTS_OPENING_DATE
                                            ELSE
                                               (CASE
                                                   WHEN ACNTS_OPENING_DATE >
                                                           :P_HALF_START_DATE
                                                   THEN
                                                      ACNTS_OPENING_DATE
                                                   ELSE
                                                      :P_HALF_START_DATE
                                                END)
                                         END)
                                  END)
                                    MAINTCHAVGBAL_CHG_EFE_DATE
                            FROM (SELECT ACNTS_ENTITY_NUM,
                                         ACNTS_INTERNAL_ACNUM,
                                         ACNTS_BRN_CODE,
                                         ACNTS_OPENING_DATE,
                                         ACNTS_PROD_CODE,
                                         ACNTS_CURR_CODE,
                                         AC_MIG.ACBALH_ASON_DATE MIGRATION_DATE,
                                         NVL (AC_MIG.ACBALH_AC_BAL, 0)
                                            MIGRATION_BALANCE,
                                         MAX_TRANSACTION_DATE
                                    FROM (SELECT ACNTS_ENTITY_NUM,
                                                 ACNTS_INTERNAL_ACNUM,
                                                 ACNTS_BRN_CODE,
                                                 ACNTS_OPENING_DATE,
                                                 ACNTS_PROD_CODE,
                                                 ACNTS_CURR_CODE,
                                                 MAX_TRANSACTION_DATE
                                            FROM (SELECT ACNTS_ENTITY_NUM,
                                                         ACNTS_INTERNAL_ACNUM,
                                                         ACNTS_BRN_CODE,
                                                         ACNTS_OPENING_DATE,
                                                         ACNTS_PROD_CODE,
                                                         ACNTS_CURR_CODE
                                                    FROM ACNTS A
                                                   WHERE     A.ACNTS_ENTITY_NUM = :ENTITY_CODE
                                                         AND A.ACNTS_INTERNAL_ACNUM = :P_AC_NUM)
                                                 ACH
                                                 LEFT OUTER JOIN
                                                 (  SELECT ACBALH_INTERNAL_ACNUM,
                                                           MAX (ACBALH_ASON_DATE)
                                                              MAX_TRANSACTION_DATE
                                                      FROM ACBALASONHIST
                                                     WHERE   ACBALH_ENTITY_NUM = :ENTITY_CODE
                                                     AND  ACBALH_ASON_DATE <= :P_HALF_START_DATE
                                                           AND ACBALH_INTERNAL_ACNUM =:P_AC_NUM
                                                  GROUP BY ACBALH_INTERNAL_ACNUM)
                                                 HIST
                                                    ON (HIST.ACBALH_INTERNAL_ACNUM =
                                                           ACH.ACNTS_INTERNAL_ACNUM))
                                         A
                                         LEFT OUTER JOIN
                                         ACBALASONHIST_AVGBAL AC_MIG
                                            ON     A.ACNTS_INTERNAL_ACNUM =
                                                      AC_MIG.ACBALH_INTERNAL_ACNUM
                                               AND AC_MIG.ACBALH_ENTITY_NUM = :ENTITY_CODE)
                                 ACCOUNTS
                                 LEFT OUTER JOIN
                                 (  SELECT ACNTCHGAMT_INTERNAL_ACNUM,
                                           MAX (ACNTCHGAMT_PROCESS_DATE)
                                              LAST_CHARG_DED_DATE
                                      FROM ACNTCHARGEAMT
                                     WHERE     ACNTCHGAMT_ENTITY_NUM = :ENTITY_CODE
                                           AND ACNTCHGAMT_INTERNAL_ACNUM =:P_AC_NUM
                                  GROUP BY ACNTCHGAMT_INTERNAL_ACNUM)
                                 LAST_CHARGE
                                    ON ACCOUNTS.ACNTS_INTERNAL_ACNUM =
                                          LAST_CHARGE.ACNTCHGAMT_INTERNAL_ACNUM)
                         A,
                         ACBALASONHIST ACHIST
                   WHERE    ACBALH_ENTITY_NUM = :ENTITY_CODE
                   AND A.MAINTCHAVGBAL_INTERNAL_ACNUM =
                                ACHIST.ACBALH_INTERNAL_ACNUM
                         AND MAINTCHAVGBAL_INTERNAL_ACNUM = :P_AC_NUM
                         AND ACBALH_ASON_DATE >=
                                NVL (MAINTCHAVGBAL_LTRAN_DATE,
                                     :P_HALF_START_DATE)))
GROUP BY MAINTCHAVGBAL_INTERNAL_ACNUM,
         MAINTCHAVGBAL_BRN_CODE,
         MAINTCHAVGBAL_CHG_EFE_DATE,
         MIG_DIFF_DAY,
         MAINTCHAVGBAL_MIG_AVG_BAL';

      EXECUTE IMMEDIATE V_AVG_SQL
         INTO V_AVG_BAL
         USING V_AVG_START_DATE,
               V_AVG_START_DATE,
               V_AVG_START_DATE,
               V_AVG_START_DATE,
               V_AVG_START_DATE,
               V_CURR_DATE,
               V_AVG_START_DATE,
               V_AVG_START_DATE,
               V_AVG_START_DATE,
               V_AVG_START_DATE,
               P_ENTITY_NUM,
               P_AC_NUMBER,
               P_ENTITY_NUM,
               V_AVG_START_DATE,
               P_AC_NUMBER,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_AC_NUMBER,
               P_ENTITY_NUM,
               P_AC_NUMBER,
               V_AVG_START_DATE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_ERR_MSG := 'No balance on that day';
      WHEN OTHERS
      THEN
         V_ERR_MSG := SQLERRM || 'Error in Getting Average Balance';
         DBMS_OUTPUT.PUT_LINE (V_ERR_MSG);
   END GET_AVGBAL;

   PROCEDURE GET_MAX_BAL
   IS
      V_CURR_FIN_DATE   DATE;
      V_MAX_SQL         CLOB;
   BEGIN
      V_CURR_FIN_DATE := PKG_PB_GLOBAL.SP_GET_FIN_YEAR_START (P_ENTITY_NUM);

      V_MAX_SQL :=
         'SELECT
       (CASE
           WHEN ABS(NVL (ACBALH_AC_BAL, 0)) > ABS(EXCISE_MAX_BALANCE)
           THEN
              ABS(NVL (ACBALH_AC_BAL, 0))
           ELSE
              ABS(EXCISE_MAX_BALANCE)
        END)
          EXCISE_MAX_BALANCE
  FROM (SELECT EXCISE_ENTITY_NUM,
               EXCISE_BRN_CODE,
               EXCISE_INTERNAL_ACNUM,
               EXCISE_PROD_CODE,
               EXCISE_AC_TYPE,
               EXCISE_MAX_BALANCE,
               EXCISE_CURR_CODE,
               PRODUCT_FOR_DEPOSITS,
               PRODUCT_FOR_LOANS,
               PRODUCT_CONTRACT_ALLOWED,
               PRODUCT_FOR_RUN_ACS,
               ACNTBAL_AC_BAL
          FROM PRODUCTS,
               (WITH EDUTY_ACNTS
                     AS (SELECT ACNTS_ENTITY_NUM,
                                ACNTS_BRN_CODE,
                                ACNTS_INTERNAL_ACNUM,
                                ACNTS_PROD_CODE,
                                ACNTS_AC_TYPE,
                                ACNTS_CURR_CODE,
                                ACNTS_LAST_TRAN_DATE
                           FROM ACNTS A
                          WHERE     ACNTS_ENTITY_NUM = :ENTITY_CODE
                                AND ACNTS_INTERNAL_ACNUM = :P_AC_NUM)
                  SELECT ACNTS_ENTITY_NUM EXCISE_ENTITY_NUM,
                         ACNTS_BRN_CODE EXCISE_BRN_CODE,
                         ACNTS_INTERNAL_ACNUM EXCISE_INTERNAL_ACNUM,
                         ACNTS_PROD_CODE EXCISE_PROD_CODE,
                         ACNTS_AC_TYPE EXCISE_AC_TYPE,
                         ACNTS_CURR_CODE EXCISE_CURR_CODE,
                         MAX (MAX_TRAN_BALANCE) EXCISE_MAX_BALANCE
                    FROM (
                    SELECT ACNTS_ENTITY_NUM,
                                 ACNTS_BRN_CODE,
                                 ACNTS_INTERNAL_ACNUM,
                                 ACNTS_PROD_CODE,
                                 ACNTS_AC_TYPE,
                                 ACNTS_CURR_CODE,
                                 ABS(FN_BIS_GET_ASON_ACBAL(ACNTS_ENTITY_NUM, ACNTS_INTERNAL_ACNUM, ACNTS_CURR_CODE, : FROM_DATE - 1, :UPTO_DATE)) MAX_TRAN_BALANCE
                            FROM EDUTY_ACNTS
                           WHERE     ACNTS_ENTITY_NUM = :ENTITY_CODE
                                 AND ACNTS_INTERNAL_ACNUM = :P_AC_NUM
                          UNION ALL
                          SELECT ACNTS_ENTITY_NUM,
                                 ACNTS_BRN_CODE,
                                 ACNTS_INTERNAL_ACNUM,
                                 ACNTS_PROD_CODE,
                                 ACNTS_AC_TYPE,
                                 ACNTS_CURR_CODE,
                                 ABS (ACBALH_AC_BAL) MAX_TRAN_BALANCE
                            FROM EDUTY_ACNTS, ACBALASONHIST
                           WHERE     ACNTS_ENTITY_NUM = ACBALH_ENTITY_NUM
                                 AND ACNTS_INTERNAL_ACNUM =
                                        ACBALH_INTERNAL_ACNUM
                                 AND ACNTS_INTERNAL_ACNUM = :P_AC_NUM
                                 AND ACBALH_ASON_DATE = ACNTS_LAST_TRAN_DATE
                                 AND ACNTS_LAST_TRAN_DATE > :FROM_DATE
                          UNION ALL
                          SELECT ACNTS_ENTITY_NUM,
                                 ACNTS_BRN_CODE,
                                 ACNTS_INTERNAL_ACNUM,
                                 ACNTS_PROD_CODE,
                                 ACNTS_AC_TYPE,
                                 ACNTS_CURR_CODE,
                                 MAX_TRAN_BALANCE
                            FROM EDUTY_ACNTS A,
                                 (  SELECT ACBALH_ENTITY_NUM,
                                           ACBALH_INTERNAL_ACNUM,
                                           MAX (ABS (ACBALH_AC_BAL))
                                              MAX_TRAN_BALANCE
                                      FROM ACBALASONHIST_MAX_TRAN
                                     WHERE     ACBALH_ENTITY_NUM = :ENTITY_CODE
                                           AND ACBALH_ASON_DATE BETWEEN :FROM_DATE
                                                                    AND :UPTO_DATE
                                           AND ACBALH_INTERNAL_ACNUM = :P_AC_NUM
                                  GROUP BY ACBALH_ENTITY_NUM,
                                           ACBALH_INTERNAL_ACNUM) B
                           WHERE     A.ACNTS_ENTITY_NUM = B.ACBALH_ENTITY_NUM
                                 AND A.ACNTS_INTERNAL_ACNUM =
                                        B.ACBALH_INTERNAL_ACNUM)
                GROUP BY ACNTS_ENTITY_NUM,
                         ACNTS_BRN_CODE,
                         ACNTS_INTERNAL_ACNUM,
                         ACNTS_PROD_CODE,
                         ACNTS_AC_TYPE,
                         ACNTS_CURR_CODE),
               ACNTBAL
         WHERE     EXCISE_ENTITY_NUM = :ENTITY_CODE
               AND ACNTBAL_INTERNAL_ACNUM = :P_AC_NUM
               AND PRODUCT_CODE = EXCISE_PROD_CODE
               AND EXCISE_INTERNAL_ACNUM = ACNTBAL_INTERNAL_ACNUM
                                                                 ) A
       LEFT OUTER JOIN
       (  SELECT MAX (ABS(ACBALH_AC_BAL)) ACBALH_AC_BAL, ACBALH_INTERNAL_ACNUM
            FROM ACBALASONHIST_MAX
           WHERE     ACBALH_ENTITY_NUM = :ENTITY_CODE
                 AND ACBALH_INTERNAL_ACNUM = :P_AC_NUM
                 AND ACBALH_ASON_DATE > :FROM_DATE
        GROUP BY ACBALH_INTERNAL_ACNUM) MIG_DATA
          ON (A.EXCISE_INTERNAL_ACNUM = MIG_DATA.ACBALH_INTERNAL_ACNUM)';



      EXECUTE IMMEDIATE V_MAX_SQL
         INTO W_MAX_BAL
         USING P_ENTITY_NUM,
               P_AC_NUMBER,
               V_CURR_FIN_DATE,
               V_CURR_DATE,
               P_ENTITY_NUM,
               P_AC_NUMBER,
               P_AC_NUMBER,
               V_CURR_FIN_DATE,
               P_ENTITY_NUM,
               V_CURR_FIN_DATE,
               V_CURR_DATE,
               P_AC_NUMBER,
               P_ENTITY_NUM,
               P_AC_NUMBER,
               P_ENTITY_NUM,
               P_AC_NUMBER,
               V_CURR_FIN_DATE;

      W_MAX_BAL := NVL (W_MAX_BAL, 0);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.put_line(V_MAX_SQL);
         V_ERR_MSG := 'No balance on that day';
         W_MAX_BAL := 0;
      WHEN OTHERS
      THEN
         V_ERR_MSG := SQLERRM || 'Error in Getting Maximum Balance';
         W_MAX_BAL := 0;
   END GET_MAX_BAL;

BEGIN
   PKG_ENTITY.SP_SET_ENTITY_CODE (P_ENTITY_NUM);

  <<GETAVGBAL>>
   BEGIN
      IF CHECK_INPUT_VALUES = TRUE
      THEN
         V_CURR_DATE := FN_GET_CURRBUSS_DATE (P_ENTITY_NUM, P_CURR_CODE);
         SP_GENERAT_ACCOUNT_INFORMATION (P_AC_NUMBER);


         IF W_LAST_TRAN_DATE < V_AVG_START_DATE
         THEN
            BEGIN
               SELECT ACBALH_AC_BAL
                 INTO V_ACBALH_AC_BAL
                 FROM ACBALASONHIST
                WHERE     ACBALH_ENTITY_NUM = P_ENTITY_NUM
                      AND ACBALH_INTERNAL_ACNUM = P_AC_NUMBER
                      AND ACBALH_ASON_DATE =
                             (SELECT MAX (ACBALH_ASON_DATE)
                                FROM ACBALASONHIST
                               WHERE     ACBALH_ENTITY_NUM = P_ENTITY_NUM
                                     AND ACBALH_INTERNAL_ACNUM = P_AC_NUMBER);
            END;

            V_AVG_BAL := V_ACBALH_AC_BAL;
            W_MAX_BAL := V_ACBALH_AC_BAL;
         ELSE
            GET_AVGBAL;
            GET_MAX_BAL;
         END IF;
      ELSE
         V_ERR_MSG := 'Error in Input Values';
         P_ERR_MSG := V_ERR_MSG;
         V_AVG_BAL := 0;
         W_MAX_BAL := 0;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_ERR_MSG := 'Error in Balance Calculation';
         P_ERR_MSG := V_ERR_MSG;
         V_AVG_BAL := 0;
         W_MAX_BAL := 0;
   END GETAVGBAL;

   P_ERR_MSG := V_ERR_MSG;

   P_AVG_BAL := V_AVG_BAL;
   P_MAX_BAL := W_MAX_BAL;
END;
/
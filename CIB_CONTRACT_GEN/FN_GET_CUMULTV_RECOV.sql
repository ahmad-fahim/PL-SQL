CREATE OR REPLACE FUNCTION FN_GET_CUMULTV_RECOV (P_AC_NUM           NUMBER,
                                                 P_RUN_CONT_FLAG    NUMBER,
                                                 P_FROM_DATE        DATE,
                                                 P_TO_DATE          DATE,
                                                 P_EXP_DATE         DATE)
   RETURN NUMBER
AS
   V_SQL                    VARCHAR2 (2000);
   V_CUMULTV_RECOV_AMOUNT   NUMBER := 0;
   V_CREDIT_BEFORE_EXPIRY   NUMBER;
   W_YEAR                   NUMBER;
BEGIN
   IF P_RUN_CONT_FLAG = 1
   THEN
      IF P_EXP_DATE > P_TO_DATE
      THEN
         V_SQL :=
            'SELECT   (SELECT NVL (
                            (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) CR
                               FROM ACNTBBAL
                              WHERE     ACNTBBAL_ENTITY_NUM = 1
                                    AND ACNTBBAL_INTERNAL_ACNUM = :1
                                    AND ACNTBBAL_YEAR =
                                           TO_NUMBER (TO_CHAR (:2 + 1, ''YYYY''))
                                    AND ACNTBBAL_MONTH =
                                           TO_NUMBER (TO_CHAR (:3 + 1, ''MM''))),
                            0)
                    FROM DUAL)
               - (SELECT NVL (
                            (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) CR
                               FROM ACNTBBAL
                              WHERE     ACNTBBAL_ENTITY_NUM = 1
                                    AND ACNTBBAL_INTERNAL_ACNUM = :4
                                    AND ACNTBBAL_YEAR =
                                           TO_NUMBER (TO_CHAR (:5, ''YYYY''))
                                    AND ACNTBBAL_MONTH =
                                           TO_NUMBER (TO_CHAR (:6, ''MM''))),
                            0)
                    FROM DUAL)
                  TOTAL_RECOVERY_BALANCE
          FROM DUAL';

         EXECUTE IMMEDIATE V_SQL
            INTO V_CUMULTV_RECOV_AMOUNT
            USING P_AC_NUM,
                  P_TO_DATE,
                  P_TO_DATE,
                  P_AC_NUM,
                  P_EXP_DATE,
                  P_EXP_DATE;

         BEGIN
            W_YEAR := TO_NUMBER (TO_CHAR (P_EXP_DATE, 'YYYY'));
            V_SQL :=
                  'SELECT NVL( SUM(TRAN_AMOUNT), 0) FROM TRAN'
               || W_YEAR
               || ' WHERE TRAN_ENTITY_NUM = 1
        AND TRAN_INTERNAL_ACNUM = :1
        AND TRAN_DATE_OF_TRAN BETWEEN TRUNC( :2, ''MM'') AND :3
        AND TRAN_DB_CR_FLG = ''C''';

            EXECUTE IMMEDIATE V_SQL
               INTO V_CREDIT_BEFORE_EXPIRY
               USING P_AC_NUM, P_EXP_DATE, P_EXP_DATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               V_CREDIT_BEFORE_EXPIRY := 0;
         END;

         V_CUMULTV_RECOV_AMOUNT :=
            V_CUMULTV_RECOV_AMOUNT - V_CREDIT_BEFORE_EXPIRY;
      END IF;
   ELSE
      V_SQL :=
         'SELECT NVL (
          (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) FROM_DATE_BALANCE
             FROM ACNTBBAL
            WHERE     ACNTBBAL_ENTITY_NUM = 1
                  AND ACNTBBAL_INTERNAL_ACNUM = :1
                  AND ACNTBBAL_YEAR = TO_NUMBER (TO_CHAR (:2 + 1, ''YYYY''))
                  AND ACNTBBAL_MONTH = TO_NUMBER (TO_CHAR (:3 + 1, ''MM''))),
          0)
          TOTAL_CREDIT
  FROM DUAL';

      EXECUTE IMMEDIATE V_SQL
         INTO V_CUMULTV_RECOV_AMOUNT
         USING P_AC_NUM, P_TO_DATE, P_TO_DATE;
   END IF;

   RETURN ABS (V_CUMULTV_RECOV_AMOUNT);
END FN_GET_CUMULTV_RECOV;

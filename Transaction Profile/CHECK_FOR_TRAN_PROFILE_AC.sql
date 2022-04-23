CREATE OR REPLACE PROCEDURE CHECK_FOR_TRAN_PROFILE_AC (
   V_ENTITY_NUM         IN     NUMBER,
   V_TRAN_DATE          IN     DATE,
   V_INTERNAL_ACNUM     IN     NUMBER,
   V_DB_CR_FLG          IN     VARCHAR2,
   V_TRAN_CAT           IN     VARCHAR2,
   V_TRAN_BASE_AMOUNT   IN     NUMBER,
   V_ALERT_REQ             OUT NUMBER,
   W_ERR_MSG               OUT VARCHAR2)
IS
   TYPE TRAN_VALUES IS RECORD
   (
      TRAN_FLAG     CHAR (1),
      TRAN_TYPE     CHAR (1),
      TRAN_AMOUNT   NUMBER (18, 3),
      TRAN_BC_AMT   NUMBER (18, 3)
   );


   TYPE T_TRAN_VALUES IS TABLE OF TRAN_VALUES
      INDEX BY PLS_INTEGER;

   W_TRAN_VALUES              T_TRAN_VALUES;

   W_TRAN_DB_AMT              NUMBER (18, 3) := 0;
   W_TRAN_CR_AMT              NUMBER (18, 3) := 0;
   W_CASH_DB_AMT              NUMBER (18, 3) := 0;
   W_CASH_CR_AMT              NUMBER (18, 3) := 0;
   W_CLG_DB_AMT               NUMBER (18, 3) := 0;
   W_CLG_CR_AMT               NUMBER (18, 3) := 0;
   W_TRADE_DB_AMT             NUMBER (18, 3) := 0;
   W_TRADE_CR_AMT             NUMBER (18, 3) := 0;
   W_TRAN_DB_COUNT            NUMBER (8) := 0;
   W_TRAN_CR_COUNT            NUMBER (8) := 0;
   W_CASH_DB_COUNT            NUMBER (8) := 0;
   W_CASH_CR_COUNT            NUMBER (8) := 0;
   W_CLG_DB_COUNT             NUMBER (8) := 0;
   W_CLG_CR_COUNT             NUMBER (8) := 0;
   W_TRADE_DB_COUNT           NUMBER (8) := 0;
   W_TRADE_CR_COUNT           NUMBER (8) := 0;
   W_SQL_3                    VARCHAR2 (4000) := '';
   W_SQL_2                    VARCHAR2 (4000) := '';
   W_SQL_1                    VARCHAR2 (2000) := '';
   W_MONTH                    VARCHAR2 (6);
   W_YEAR                     NUMBER (4) ;


   W_TRAN_DB_AMT_OLD          NUMBER (18, 3) := 0;
   W_TRAN_CR_AMT_OLD          NUMBER (18, 3) := 0;
   W_CASH_DB_AMT_OLD          NUMBER (18, 3) := 0;
   W_CASH_CR_AMT_OLD          NUMBER (18, 3) := 0;
   W_CLG_DB_AMT_OLD           NUMBER (18, 3) := 0;
   W_CLG_CR_AMT_OLD           NUMBER (18, 3) := 0;
   W_TRADE_DB_AMT_OLD         NUMBER (18, 3) := 0;
   W_TRADE_CR_AMT_OLD         NUMBER (18, 3) := 0;
   W_TRAN_DB_COUNT_OLD        NUMBER (8) := 0;
   W_TRAN_CR_COUNT_OLD        NUMBER (8) := 0;
   W_CASH_DB_COUNT_OLD        NUMBER (8) := 0;
   W_CASH_CR_COUNT_OLD        NUMBER (8) := 0;
   W_CLG_DB_COUNT_OLD         NUMBER (8) := 0;
   W_CLG_CR_COUNT_OLD         NUMBER (8) := 0;
   W_TRADE_DB_COUNT_OLD       NUMBER (8) := 0;
   W_TRADE_CR_COUNT_OLD       NUMBER (8) := 0;

   W_TRAN_BASE_AMOUNT         NUMBER (18, 3);
   P_ALERT_REQ                NUMBER (2) DEFAULT 0;
   W_DATA_FOUND               NUMBER (2) DEFAULT 0;
   W_TRAN_DATE                DATE;
   W_INTERNAL_ACNUM           NUMBER (14);
   W_DB_CR_FLG                VARCHAR2 (1);
   W_TRAN_CAT                 VARCHAR2 (1);
   E_USERERROR                EXCEPTION;
   W_TRAN_DB_AMT_PARAM        NUMBER (18, 3) := 0;
   W_TRAN_CR_AMT_PARAM        NUMBER (18, 3) := 0;
   W_CASH_DB_AMT_PARAM        NUMBER (18, 3) := 0;
   W_CASH_CR_AMT_PARAM        NUMBER (18, 3) := 0;
   W_CLG_DB_AMT_PARAM         NUMBER (18, 3) := 0;
   W_CLG_CR_AMT_PARAM         NUMBER (18, 3) := 0;
   W_TRADE_DB_AMT_PARAM       NUMBER (18, 3) := 0;
   W_TRADE_CR_AMT_PARAM       NUMBER (18, 3) := 0;
   W_CUT_TRAN_DB_AMT_PARAM    NUMBER (18, 3) := 0;
   W_CUT_TRAN_CR_AMT_PARAM    NUMBER (18, 3) := 0;
   W_CUT_CASH_DB_AMT_PARAM    NUMBER (18, 3) := 0;
   W_CUT_CASH_CR_AMT_PARAM    NUMBER (18, 3) := 0;
   W_CUT_CLG_DB_AMT_PARAM     NUMBER (18, 3) := 0;
   W_CUT_CLG_CR_AMT_PARAM     NUMBER (18, 3) := 0;
   W_CUT_TRADE_DB_AMT_PARAM   NUMBER (18, 3) := 0;
   W_CUT_TRADE_CR_AMT_PARAM   NUMBER (18, 3) := 0;
   W_TRAN_DB_COUNT_PARAM      NUMBER (8) := 0;
   W_TRAN_CR_COUNT_PARAM      NUMBER (8) := 0;
   W_CASH_DB_COUNT_PARAM      NUMBER (8) := 0;
   W_CASH_CR_COUNT_PARAM      NUMBER (8) := 0;
   W_CLG_DB_COUNT_PARAM       NUMBER (8) := 0;
   W_CLG_CR_COUNT_PARAM       NUMBER (8) := 0;
   W_TRADE_DB_COUNT_PARAM     NUMBER (8) := 0;
   W_TRADE_CR_COUNT_PARAM     NUMBER (8) := 0;

   W_BRN_CODE                 IACLINK.IACLINK_BRN_CODE%TYPE := 0;
BEGIN
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);
      W_TRAN_DATE := V_TRAN_DATE;
      W_INTERNAL_ACNUM := NVL (V_INTERNAL_ACNUM, 0);
      W_TRAN_BASE_AMOUNT := NVL (V_TRAN_BASE_AMOUNT, 0);
      W_DB_CR_FLG := V_DB_CR_FLG;
      W_TRAN_CAT := V_TRAN_CAT;

      SELECT TO_CHAR (W_TRAN_DATE, 'MON') INTO W_MONTH FROM DUAL;
      
      SELECT TO_NUMBER(TO_CHAR (W_TRAN_DATE, 'YYYY')) INTO W_YEAR FROM DUAL;

      BEGIN
         SELECT IACLINK_BRN_CODE
           INTO W_BRN_CODE
           FROM IACLINK
          WHERE     IACLINK_ENTITY_NUM = V_ENTITY_NUM
                AND IACLINK_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      IF (W_INTERNAL_ACNUM <> 0)
      THEN
         BEGIN
            W_SQL_1 :=
                  'SELECT     A.ACNTTRANPAMT_TRANSFER_DB_AMT,
                          A.ACNTTRANPAMT_TRANSFER_DB_COUNT,
                          A.ACNTTRANPAMT_TRANSFER_CR_AMT,
                          A.ACNTTRANPAMT_TRANSFER_CR_COUNT,
                          A.ACNTTRANPAMT_CASH_DB_AMT,
                          A.ACNTTRANPAMT_CASH_DB_COUNT,
                          A.ACNTTRANPAMT_CASH_CR_AMT,
                          A.ACNTTRANPAMT_CASH_CR_COUNT,
                          A.ACNTTRANPAMT_CLEARING_DB_AMT,
                          A.ACNTTRANPAMT_CLEARING_DB_COUNT,
                          A.ACNTTRANPAMT_CLEARING_CR_COUNT,
                          A.ACNTTRANPAMT_CLEARING_CR_AMT,
                          A.ACNTTRANPAMT_TRADE_DB_AMT,
                          A.ACNTTRANPAMT_TRADE_DB_COUNT,
                          A.ACNTTRANPAMT_TRADE_CR_AMT,
                          A.ACNTTRANPAMT_TRADE_CR_COUNT FROM ACNTTRANPROFAMT A
                          WHERE A.ACNTTRANPAMT_ENTITY_NUM = '
               || CHR (39)
               || PKG_ENTITY.FN_GET_ENTITY_CODE
               || CHR (39)
               || '
                          AND A.ACNTTRANPAMT_INTERNAL_ACNUM = '
               || CHR (39)
               || W_INTERNAL_ACNUM
               || CHR (39)
               || '
                          AND A.ACNTTRANPAMT_MONTH = '
               || CHR (39)
               || W_MONTH
               || CHR (39)
               || '
                          AND A.ACNTTRANPAMT_PROCESS_YEAR = '
               || CHR (39)
               || W_YEAR
               || CHR (39)
               || '
               ';

            EXECUTE IMMEDIATE W_SQL_1
               INTO W_TRAN_DB_AMT,
                    W_TRAN_DB_COUNT,
                    W_TRAN_CR_AMT,
                    W_TRAN_CR_COUNT,
                    W_CASH_DB_AMT,
                    W_CASH_DB_COUNT,
                    W_CASH_CR_AMT,
                    W_CASH_CR_COUNT,
                    W_CLG_DB_AMT,
                    W_CLG_DB_COUNT,
                    W_CLG_CR_COUNT,
                    W_CLG_CR_AMT,
                    W_TRADE_DB_AMT,
                    W_TRADE_DB_COUNT,
                    W_TRADE_CR_AMT,
                    W_TRADE_CR_COUNT;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               W_DATA_FOUND := 1;
         END;

         BEGIN
            W_SQL_2 :=
                  ' SELECT ACTP_MAXAMT_NCASHP,
                         ACTP_NOT_NONCASHP,
                         ACTP_MAXAMT_NCASHR,
                         ACTP_NOT_NONCASHR,
                         ACTP_MAXAMT_CASHP,
                         ACTP_NOT_CASHP,
                         ACTP_MAXAMT_CASHR,
                         ACTP_NOT_CASHR,
                         ACTP_MAXAMT_NONTFREMP,
                         ACTP_NOT_NONTFREMP,
                         ACTP_MAXAMT_NONTFREMR,
                         ACTP_NOT_NONTFREMR,
                         ACTP_MAXAMT_TFREMP,
                         ACTP_NOT_TFREMP,
                         ACTP_MAXAMT_TFREMR,
                         ACTP_NOT_TFREMR,
                         ACTP_CUTOFF_LMT_NONCASHP,
                         ACTP_CUTOFF_LMT_NONCASHR,
                         ACTP_CUTOFF_LMT_CASHP,
                         ACTP_CUTOFF_LMT_CASHR,
                         ACTP_CUTOFF_LMT_NONTFREMP,
                         ACTP_CUTOFF_LMT_NONTFREMR,
                         ACTP_CUTOFF_LMT_TFREMP,
                         ACTP_CUTOFF_LMT_TFREMR FROM ACNTRNPR
                         WHERE ACTP_ACNT_NUM ='
               || CHR (39)
               || W_INTERNAL_ACNUM
               || CHR (39)
               || '
                         AND ACTP_LATEST_EFF_DATE = (SELECT MAX(ACTP_LATEST_EFF_DATE)
                                                                      FROM ACNTRNPR CT
                                                                      WHERE CT.ACTP_ACNT_NUM = '
               || W_INTERNAL_ACNUM
               || ')';

            EXECUTE IMMEDIATE W_SQL_2
               INTO W_TRAN_DB_AMT_PARAM,
                    W_TRAN_DB_COUNT_PARAM,
                    W_TRAN_CR_AMT_PARAM,
                    W_TRAN_CR_COUNT_PARAM,
                    W_CASH_DB_AMT_PARAM,
                    W_CASH_DB_COUNT_PARAM,
                    W_CASH_CR_AMT_PARAM,
                    W_CASH_CR_COUNT_PARAM,
                    W_CLG_DB_AMT_PARAM,
                    W_CLG_DB_COUNT_PARAM,
                    W_CLG_CR_AMT_PARAM,
                    W_CLG_CR_COUNT_PARAM,
                    W_TRADE_DB_AMT_PARAM,
                    W_TRADE_DB_COUNT_PARAM,
                    W_TRADE_CR_AMT_PARAM,
                    W_TRADE_CR_COUNT_PARAM,
                    W_CUT_TRAN_DB_AMT_PARAM,
                    W_CUT_TRAN_CR_AMT_PARAM,
                    W_CUT_CASH_DB_AMT_PARAM,
                    W_CUT_CASH_CR_AMT_PARAM,
                    W_CUT_CLG_DB_AMT_PARAM,
                    W_CUT_CLG_CR_AMT_PARAM,
                    W_CUT_TRADE_DB_AMT_PARAM,
                    W_CUT_TRADE_CR_AMT_PARAM;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               W_DATA_FOUND := 2;
         END;

         BEGIN
            W_SQL_3 :=
                  ' SELECT TRAN_DB_CR_FLG,TRAN_TYPE_OF_TRAN,TRAN_AMOUNT,TRAN_BASE_CURR_EQ_AMT
        FROM TRAN'
               || TO_NUMBER (TO_CHAR (W_TRAN_DATE, 'YYYY'))
               || '
        WHERE TRAN_ENTITY_NUM = '
               || V_ENTITY_NUM
               || 'AND TRAN_BRN_CODE = '
               || W_BRN_CODE
               || '       
        AND TRAN_DATE_OF_TRAN =  '
               || CHR (39)
               || W_TRAN_DATE
               || CHR (39)
               || '
        AND TRAN_INTERNAL_ACNUM = '
               || CHR (39)
               || W_INTERNAL_ACNUM
               || CHR (39)
               || '
        AND TRAN_SYSTEM_POSTED_TRAN = ''0''
        AND TRAN_AUTH_ON IS NOT NULL';

            EXECUTE IMMEDIATE W_SQL_3 BULK COLLECT INTO W_TRAN_VALUES;

            FOR IDX IN 1 .. W_TRAN_VALUES.COUNT
            LOOP
               IF W_TRAN_VALUES (IDX).TRAN_TYPE = '1'
               THEN
                  IF W_TRAN_VALUES (IDX).TRAN_FLAG = 'D'
                  THEN
                     W_TRAN_DB_AMT_OLD :=
                        W_TRAN_DB_AMT_OLD + W_TRAN_VALUES (IDX).TRAN_BC_AMT;
                     W_TRAN_DB_COUNT_OLD := W_TRAN_DB_COUNT_OLD + 1;
                  ELSE
                     W_TRAN_CR_AMT_OLD :=
                        W_TRAN_CR_AMT_OLD + W_TRAN_VALUES (IDX).TRAN_BC_AMT;
                     W_TRAN_CR_COUNT_OLD := W_TRAN_CR_COUNT_OLD + 1;
                  END IF;
               ELSIF W_TRAN_VALUES (IDX).TRAN_TYPE = '3'
               THEN
                  IF W_TRAN_VALUES (IDX).TRAN_FLAG = 'D'
                  THEN
                     W_CASH_DB_AMT_OLD :=
                        W_CASH_DB_AMT_OLD + W_TRAN_VALUES (IDX).TRAN_BC_AMT;
                     W_CASH_DB_COUNT_OLD := W_CASH_DB_COUNT_OLD + 1;
                  ELSE
                     W_CASH_CR_AMT_OLD :=
                        W_CASH_CR_AMT_OLD + W_TRAN_VALUES (IDX).TRAN_BC_AMT;
                     W_CASH_CR_COUNT_OLD := W_CASH_CR_COUNT_OLD + 1;
                  END IF;
               ELSIF W_TRAN_VALUES (IDX).TRAN_TYPE = '2'
               THEN
                  IF W_TRAN_VALUES (IDX).TRAN_FLAG = 'D'
                  THEN
                     W_CLG_DB_AMT_OLD :=
                        W_CLG_DB_AMT_OLD + W_TRAN_VALUES (IDX).TRAN_BC_AMT;
                     W_CLG_DB_COUNT_OLD := W_CLG_DB_COUNT_OLD + 1;
                  ELSE
                     W_CLG_CR_AMT_OLD :=
                        W_CLG_CR_AMT_OLD + W_TRAN_VALUES (IDX).TRAN_BC_AMT;
                     W_CLG_CR_COUNT_OLD := W_CLG_CR_COUNT_OLD + 1;
                  END IF;
               ELSE
                  IF W_TRAN_VALUES (IDX).TRAN_FLAG = 'D'
                  THEN
                     W_TRADE_DB_AMT_OLD :=
                        W_TRADE_DB_AMT_OLD + W_TRAN_VALUES (IDX).TRAN_BC_AMT;
                     W_TRADE_DB_COUNT_OLD := W_TRADE_DB_COUNT_OLD + 1;
                  ELSE
                     W_TRADE_CR_AMT_OLD :=
                        W_TRADE_CR_AMT_OLD + W_TRAN_VALUES (IDX).TRAN_BC_AMT;
                     W_TRADE_CR_COUNT_OLD := W_TRADE_CR_COUNT_OLD + 1;
                  END IF;
               END IF;
            END LOOP;
         END;

         IF W_DATA_FOUND <> 2
         THEN
            IF W_TRAN_CAT = '1'
            THEN
               IF W_DB_CR_FLG = 'D'
               THEN
                  W_TRAN_DB_AMT := W_TRAN_DB_AMT + W_TRAN_BASE_AMOUNT;
                  W_TRAN_DB_COUNT := W_TRAN_DB_COUNT + 1;

                  IF W_CUT_TRAN_DB_AMT_PARAM < W_TRAN_BASE_AMOUNT
                  THEN
                     P_ALERT_REQ := 1;
                  END IF;

                  IF W_TRAN_DB_AMT_PARAM < W_TRAN_DB_AMT + W_TRAN_DB_AMT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 4;
                  END IF;

                  IF W_TRAN_DB_COUNT_PARAM <
                        W_TRAN_DB_COUNT + W_TRAN_DB_COUNT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 7;
                  END IF;
               ELSE
                  W_TRAN_CR_AMT := W_TRAN_CR_AMT + W_TRAN_BASE_AMOUNT;
                  W_TRAN_CR_COUNT := W_TRAN_CR_COUNT + 1;

                  IF W_CUT_TRAN_CR_AMT_PARAM < W_TRAN_BASE_AMOUNT
                  THEN
                     P_ALERT_REQ := 1;
                  END IF;

                  IF W_TRAN_CR_AMT_PARAM < W_TRAN_CR_AMT + W_TRAN_CR_AMT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 4;
                  END IF;

                  IF W_TRAN_CR_COUNT_PARAM <
                        W_TRAN_CR_COUNT + W_TRAN_CR_COUNT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 7;
                  END IF;
               END IF;
            ELSIF W_TRAN_CAT = '3'
            THEN
               IF W_DB_CR_FLG = 'D'
               THEN
                  W_CASH_DB_AMT := W_CASH_DB_AMT + W_TRAN_BASE_AMOUNT;
                  W_CASH_DB_COUNT := W_CASH_DB_COUNT + 1;

                  IF W_CUT_CASH_DB_AMT_PARAM < W_TRAN_BASE_AMOUNT
                  THEN
                     P_ALERT_REQ := 1;
                  END IF;

                  IF W_CASH_DB_AMT_PARAM < W_CASH_DB_AMT + W_CASH_DB_AMT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 4;
                  END IF;

                  IF W_CASH_DB_COUNT_PARAM <
                        W_CASH_DB_COUNT + W_CASH_DB_COUNT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 7;
                  END IF;
               ELSE
                  W_CASH_CR_AMT := W_CASH_CR_AMT + W_TRAN_BASE_AMOUNT;
                  W_CASH_CR_COUNT := W_CASH_CR_COUNT + 1;

                  IF W_CUT_CASH_CR_AMT_PARAM < W_TRAN_BASE_AMOUNT
                  THEN
                     P_ALERT_REQ := 1;
                  END IF;

                  IF W_CASH_CR_AMT_PARAM < W_CASH_CR_AMT + W_CASH_CR_AMT_OLD
                  THEN 
                     P_ALERT_REQ := P_ALERT_REQ + 4;
                  END IF;

                  IF W_CASH_CR_COUNT_PARAM <
                        W_CASH_CR_COUNT + W_CASH_CR_COUNT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 7;
                  END IF;
               END IF;
            ELSIF W_TRAN_CAT = '2'
            THEN
               IF W_DB_CR_FLG = 'D'
               THEN
                  W_CLG_DB_AMT := W_CLG_DB_AMT + W_TRAN_BASE_AMOUNT;
                  W_CLG_DB_COUNT := W_CLG_DB_COUNT + 1;

                  IF W_CUT_CLG_DB_AMT_PARAM < W_TRAN_BASE_AMOUNT
                  THEN
                     P_ALERT_REQ := 1;
                  END IF;

                  IF W_CLG_DB_AMT_PARAM < W_CLG_DB_AMT + W_CLG_DB_AMT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 4;
                  END IF;

                  IF W_CLG_DB_COUNT_PARAM <
                        W_CLG_DB_COUNT + W_CLG_DB_COUNT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 7;
                  END IF;
               ELSE
                  W_CLG_CR_AMT := W_CLG_CR_AMT + W_TRAN_BASE_AMOUNT;
                  W_CLG_CR_COUNT := W_CLG_CR_COUNT + 1;

                  IF W_CUT_CLG_CR_AMT_PARAM < W_TRAN_BASE_AMOUNT
                  THEN
                     P_ALERT_REQ := 1;
                  END IF;

                  IF W_CLG_CR_AMT_PARAM < W_CLG_CR_AMT + W_CLG_CR_AMT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 4;
                  END IF;

                  IF W_CLG_CR_COUNT_PARAM <
                        W_CLG_CR_COUNT + W_CLG_CR_COUNT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 7;
                  END IF;
               END IF;
            ELSE
               IF W_DB_CR_FLG = 'D'
               THEN
                  W_TRADE_DB_AMT := W_TRADE_DB_AMT + W_TRAN_BASE_AMOUNT;
                  W_TRADE_DB_COUNT := W_TRADE_DB_COUNT + 1;

                  IF W_CUT_TRADE_DB_AMT_PARAM < W_TRAN_BASE_AMOUNT
                  THEN
                     P_ALERT_REQ := 1;
                  END IF;

                  IF W_TRADE_DB_AMT_PARAM <
                        W_TRADE_DB_AMT + W_TRADE_DB_AMT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 4;
                  END IF;

                  IF W_TRADE_DB_COUNT_PARAM <
                        W_TRADE_DB_COUNT + W_TRADE_DB_COUNT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 7;
                  END IF;
               ELSE
                  W_TRADE_CR_AMT := W_TRADE_CR_AMT + W_TRAN_BASE_AMOUNT;
                  W_TRADE_CR_COUNT := W_TRADE_CR_COUNT + 1;

                  IF W_CUT_TRADE_CR_AMT_PARAM < W_TRAN_BASE_AMOUNT
                  THEN
                     P_ALERT_REQ := 1;
                  END IF;

                  IF W_TRADE_CR_AMT_PARAM <
                        W_TRADE_CR_AMT + W_TRADE_CR_AMT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 4;
                  END IF;

                  IF W_TRADE_CR_COUNT_PARAM <
                        W_TRADE_CR_COUNT + W_TRADE_CR_COUNT_OLD
                  THEN
                     P_ALERT_REQ := P_ALERT_REQ + 7;
                  END IF;
               END IF;
            END IF;
         END IF;
      END IF;
   EXCEPTION
      WHEN E_USERERROR
      THEN
         IF TRIM (W_ERR_MSG) IS NULL
         THEN
            W_ERR_MSG := 'Error in Transaction Amount Processing';
            LOG_ERROR (SQLCODE,
                       'A/C' || V_INTERNAL_ACNUM || 'Dr/Cr: ' || V_DB_CR_FLG);
         END IF;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE (SQLERRM);
         DBMS_OUTPUT.PUT_LINE (W_SQL_1);
         W_ERR_MSG := 'Error in Transaction Amount Processing';
         LOG_ERROR (SQLCODE,
                    'A/C' || V_INTERNAL_ACNUM || 'Dr/Cr: ' || V_DB_CR_FLG);
   END;

   V_ALERT_REQ := NVL (P_ALERT_REQ, 0);
END;
/
/
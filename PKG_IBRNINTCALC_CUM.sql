CREATE OR REPLACE PACKAGE PKG_IBRNINTCALC_CUM
AS
   PROCEDURE SP_INTERBRNINTCALC (
      P_ENTITY_NUM     IN ENTITYNUM.ENTITYNUM_NUMBER%TYPE,
      P_BRN_CODE       IN MBRN.MBRN_CODE%TYPE DEFAULT 0,
      P_PROCESS_DATE      PKG_COMMON_TYPES.DATE_T DEFAULT NULL,
      P_USER_ID        IN USERS.USER_ID%TYPE DEFAULT '');
END;
/


CREATE OR REPLACE PACKAGE BODY PKG_IBRNINTCALC_CUM
AS
   PROCEDURE SP_INTERBRNINTCALC (
      P_ENTITY_NUM     IN ENTITYNUM.ENTITYNUM_NUMBER%TYPE,
      P_BRN_CODE       IN MBRN.MBRN_CODE%TYPE DEFAULT 0,
      P_PROCESS_DATE      PKG_COMMON_TYPES.DATE_T DEFAULT NULL,
      P_USER_ID        IN USERS.USER_ID%TYPE DEFAULT '')
   IS
      V_BRN_CODE       MBRN.MBRN_CODE%TYPE := NVL (P_BRN_CODE, 0);
      V_ENTITY_NUM     ENTITYNUM.ENTITYNUM_NUMBER%TYPE := NVL (P_ENTITY_NUM, 1);
      V_CBD            MAINCONT.MN_CURR_BUSINESS_DATE%TYPE;
      V_PROCESS_DATE   PKG_COMMON_TYPES.DATE_T := P_PROCESS_DATE;
      V_USER_ID        USERS.USER_ID%TYPE := TRIM (P_USER_ID);
      V_FIN_YEAR       PKG_COMMON_TYPES.NUMBER_T;
      V_BASE_CURR      INSTALL.INS_BASE_CURR_CODE%TYPE;
      V_RUN_NUMBER     PKG_COMMON_TYPES.NUMBER_T := 1;

      TYPE TY_GL_PM_REC IS RECORD
      (
         T_GLINTHIST_GLACC_CODE        GLINTHIST.GLINTHIST_GLACC_CODE%TYPE,
         T_GLINTHIST_CURR_CODE         GLINTHIST.GLINTHIST_CURR_CODE%TYPE,
         T_GLINTHIST_EFF_DATE          GLINTHIST.GLINTHIST_EFF_DATE%TYPE,
         T_GLINTHIST_INT_RATE_CR_BAL   GLINTHIST.GLINTHIST_INT_RATE_CR_BAL%TYPE,
         T_GLINTHIST_INT_RATE_DB_BAL   GLINTHIST.GLINTHIST_INT_RATE_DB_BAL%TYPE 
      );

      TYPE TAB_GL_PM_REC IS TABLE OF TY_GL_PM_REC
         INDEX BY PLS_INTEGER;

      GL_PM_REC        TAB_GL_PM_REC;

      V_ERR_MSG        VARCHAR2 (1000);
      MYEXCEPTION      EXCEPTION;


      FUNCTION FN_GET_RUNNO
         RETURN NUMBER
      IS
         W_RUN_NUMBER   PKG_COMMON_TYPES.NUMBER_T := 1;

         PROCEDURE SP_DEL_TEMP_TABLE (
            W_DEL_RUN_NO   IN PKG_COMMON_TYPES.NUMBER_T)
         IS
         BEGIN
            DELETE FROM IBRNINTCALC
                  WHERE     IBRNINTCALC_ENTITY_NUM = V_ENTITY_NUM
                        AND IBRNINTCALC_RUN_NUMBER = W_DEL_RUN_NO;

            DELETE FROM IBRNINTCALCDTL
                  WHERE     IBRNICDTL_ENTITY_NUM = V_ENTITY_NUM
                        AND IBRNICDTL_RUN_NUMBER = W_DEL_RUN_NO;

            DELETE FROM IBRINTPOSTCTL
                  WHERE     IBRINTPOSTCTL_ENTITY_NUM = V_ENTITY_NUM
                        AND IBRINTPOSTCTL_RUN_NUMBER = W_DEL_RUN_NO;
         END SP_DEL_TEMP_TABLE;
      BEGIN
         SELECT GENRUNNUM.NEXTVAL INTO W_RUN_NUMBER FROM DUAL;
         /* same run number can be generated for any other branch and previous month's data can be deleted.
         Start date calculation can be affected for the delete */
         --SP_DEL_TEMP_TABLE (W_RUN_NUMBER);
         RETURN NVL (W_RUN_NUMBER, 1);
      END FN_GET_RUNNO;


      PROCEDURE PROCESS_BRN_WISE (BRN_CODE IN MBRN.MBRN_CODE%TYPE)
      IS
         V_DR_BAL_INT_REQ      GLIBRINTPMHIST.GLIBRIPMH_DB_BAL_INT_REQD%TYPE;
         V_CR_BAL_INT_REQ      GLIBRINTPMHIST.GLIBRIPMH_CR_BAL_INT_REQD%TYPE;
         V_INCOME_HEAD         GLIBRINTPMHIST.GLIBRIPMH_INCOME_HEAD%TYPE;
         V_RECV_HEAD           GLIBRINTPMHIST.GLIBRIPMH_INT_RECVRY_GL_HEAD%TYPE;
         V_EXPENSE_HEAD        GLIBRINTPMHIST.GLIBRIPMH_EXPENSE_HEAD%TYPE;
         V_PAYABLE_HEAD        GLIBRINTPMHIST.GLIBRIPMH_INT_PAY_GL_HEAD%TYPE;
         V_RNDOFF_CHOICE       GLIBRINTPMHIST.GLIBRIPMH_RNDOFF_CHOICE%TYPE;
         V_RNDOFF_FACTOR       GLIBRINTPMHIST.GLIBRIPMH_RNDOFF_FACTOR%TYPE;
         V_INT_CALC_DENOM      PKG_COMMON_TYPES.NUMBER_T;

         V_BRN_MIG_DATE        MBRN_CORE.MIG_DATE%TYPE;
         INTCALCDTL_INDX       PKG_COMMON_TYPES.NUMBER_T := 1;

         FUNCTION FN_GET_GLIBRINTPM_ROW (P_GLACC_CODE      VARCHAR2,
                                         P_CURR_CODE       VARCHAR2 )
            RETURN VARCHAR2
         IS
            V_DUMMY   VARCHAR2 (100);
         BEGIN
            BEGIN
               SELECT    GLIBRIPMH_INTER_GL_HEAD
                      || ' '
                      || GLIBRIPMH_CURR_CODE
                      || ' '
                      || GLIBRIPMH_EFF_DATE
                 INTO V_DUMMY
                 FROM GLIBRINTPMHIST
                WHERE     GLIBRIPMH_CURR_CODE = P_CURR_CODE
                      AND (   NVL (TRIM (GLIBRIPMH_CR_BAL_INT_REQD), '0') =
                                 '1'
                           OR NVL (TRIM (GLIBRIPMH_DB_BAL_INT_REQD), '0') =
                                 '1')
                      AND GLIBRIPMH_INTER_GL_HEAD = P_GLACC_CODE
                      AND GLIBRIPMH_EFF_DATE =
                             (SELECT MAX (GLIBRIPMH_EFF_DATE)
                                FROM GLIBRINTPMHIST
                               WHERE     GLIBRIPMH_EFF_DATE <= V_PROCESS_DATE
                                     AND GLIBRIPMH_CURR_CODE = P_CURR_CODE
                                     AND (   NVL (
                                                TRIM (
                                                   GLIBRIPMH_CR_BAL_INT_REQD),
                                                '0') = '1'
                                          OR NVL (
                                                TRIM (
                                                   GLIBRIPMH_DB_BAL_INT_REQD),
                                                '0') = '1'));
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  SELECT    GLIBRIPMH_INTER_GL_HEAD
                         || ' '
                         || GLIBRIPMH_CURR_CODE
                         || ' '
                         || GLIBRIPMH_EFF_DATE
                    INTO V_DUMMY
                    FROM GLIBRINTPMHIST
                   WHERE     GLIBRIPMH_CURR_CODE = P_CURR_CODE
                         AND (   NVL (TRIM (GLIBRIPMH_CR_BAL_INT_REQD), '0') =
                                    '1'
                              OR NVL (TRIM (GLIBRIPMH_DB_BAL_INT_REQD), '0') =
                                    '1')
                         --AND GLIBRIPMH_INTER_GL_HEAD =  P_GLACC_CODE
                         AND GLIBRIPMH_EFF_DATE =
                                (SELECT MAX (GLIBRIPMH_EFF_DATE)
                                   FROM GLIBRINTPMHIST
                                  WHERE     GLIBRIPMH_EFF_DATE <=
                                               V_PROCESS_DATE
                                        AND GLIBRIPMH_CURR_CODE = P_CURR_CODE
                                        AND (   NVL (
                                                   TRIM (
                                                      GLIBRIPMH_CR_BAL_INT_REQD),
                                                   '0') = '1'
                                             OR NVL (
                                                   TRIM (
                                                      GLIBRIPMH_DB_BAL_INT_REQD),
                                                   '0') = '1')
                                        AND TRIM (GLIBRIPMH_INTER_GL_HEAD)
                                               IS NULL);
            END;

            RETURN V_DUMMY;
         END FN_GET_GLIBRINTPM_ROW;

         PROCEDURE POPULATE_GLINTPM
         IS
         BEGIN
            WITH GL_SUMMARY
                 AS (SELECT *
                       FROM GLINTHIST G
                      WHERE     G.GLINTHIST_ENTITY_NUM = V_ENTITY_NUM
                            AND G.GLINTHIST_BRN_CODE IN (0, BRN_CODE)
                            AND G.GLINTHIST_CURR_CODE = V_BASE_CURR
                            AND (G.GLINTHIST_GLACC_CODE, G.GLINTHIST_EFF_DATE) IN (  SELECT GLINTHIST_GLACC_CODE,
                                                                                            MAX (
                                                                                               GLINTHIST_EFF_DATE)
                                                                                               GLINTHIST_EFF_DATE
                                                                                       FROM GLINTHIST
                                                                                      WHERE     GLINTHIST_ENTITY_NUM =
                                                                                                   V_ENTITY_NUM
                                                                                            AND GLINTHIST_BRN_CODE IN (0,
                                                                                                                       BRN_CODE)
                                                                                            AND GLINTHIST_CURR_CODE =
                                                                                                   V_BASE_CURR
                                                                                            AND GLINTHIST_EFF_DATE <=
                                                                                                   V_PROCESS_DATE
                                                                                            AND GLINTHIST_AUTH_ON
                                                                                                   IS NOT NULL
                                                                                   GROUP BY GLINTHIST_GLACC_CODE))
            SELECT GLINTHIST_GLACC_CODE,
                   GLINTHIST_CURR_CODE,
                   GLINTHIST_EFF_DATE,
                   GLINTHIST_INT_RATE_CR_BAL,
                   GLINTHIST_INT_RATE_DB_BAL
              BULK COLLECT INTO GL_PM_REC
              FROM GL_SUMMARY S
             WHERE S.GLINTHIST_BRN_CODE =
                      (SELECT MAX (G.GLINTHIST_BRN_CODE)
                         FROM GL_SUMMARY G
                        WHERE     G.GLINTHIST_ENTITY_NUM = V_ENTITY_NUM
                              AND S.GLINTHIST_GLACC_CODE =
                                     G.GLINTHIST_GLACC_CODE
                              AND S.GLINTHIST_EFF_DATE = G.GLINTHIST_EFF_DATE);
         END POPULATE_GLINTPM;

         PROCEDURE GET_BRN_MIG_DATE
         IS
         BEGIN
            BEGIN
               SELECT MIG_DATE
                 INTO V_BRN_MIG_DATE
                 FROM MBRN_CORE
                WHERE MBRN_CODE = BRN_CODE AND NONCORE = '0';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
            END;
         END GET_BRN_MIG_DATE;

         PROCEDURE PROCESS_BRANCH
         IS
            TYPE GLHIST_BAL_RT IS RECORD
            (
               GL_CODE         EXTGL.EXTGL_ACCESS_CODE%TYPE,
               START_DATE      GLBALASONHIST.GLBALH_ASON_DATE%TYPE,
               END_DATE        GLBALASONHIST.GLBALH_ASON_DATE%TYPE,
               GLBALH_BC_BAL   GLBALASONHIST.GLBALH_BC_BAL%TYPE,
               NO_OF_DAYS      PKG_COMMON_TYPES.NUMBER_T
            );

            TYPE GLHIST_BAL_TT IS TABLE OF GLHIST_BAL_RT
               INDEX BY PLS_INTEGER;

            GLHIST_BAL         GLHIST_BAL_TT;
            GLVALDATED_TX      GLHIST_BAL_TT;

            TYPE INTCALCDTL_TT IS TABLE OF IBRNINTCALCDTL%ROWTYPE
               INDEX BY PLS_INTEGER;

            INTCALCDTL         INTCALCDTL_TT;

            INTCALC_R          IBRNINTCALC%ROWTYPE := NULL;

            V_TOT_CR_BAL       PKG_COMMON_TYPES.AMOUNT_T := 0;
            V_TOT_CR_BAL_INT   PKG_COMMON_TYPES.AMOUNT_T := 0;
            V_TOT_DR_BAL       PKG_COMMON_TYPES.AMOUNT_T := 0;
            V_TOT_DR_BAL_INT   PKG_COMMON_TYPES.AMOUNT_T := 0;
            V_NET_INT_AMT      PKG_COMMON_TYPES.AMOUNT_T := 0;

            V_BAL_START_DATE   PKG_COMMON_TYPES.DATE_T;

            FUNCTION GET_RNDOFF_AMT (
               ENTITY_NUM          ENTITYNUM.ENTITYNUM_NUMBER%TYPE,
               AMT              IN PKG_COMMON_TYPES.AMOUNT_T,
               RNDOFF_CHOICHE   IN GLIBRINTPM.GLIBRIPM_RNDOFF_CHOICE%TYPE,
               RNDOFF_FACTOR    IN GLIBRINTPM.GLIBRIPM_RNDOFF_FACTOR%TYPE)
               RETURN PKG_COMMON_TYPES.AMOUNT_T
            IS
               V_RNDOFF_AMT   PKG_COMMON_TYPES.AMOUNT_T := 0;
            BEGIN
               V_RNDOFF_AMT :=
                  FN_ROUNDOFF (ENTITY_NUM,
                               ABS (AMT),
                               RNDOFF_CHOICHE,
                               RNDOFF_FACTOR);
               V_RNDOFF_AMT :=
                  CASE
                     WHEN AMT < 0 THEN (-1 * V_RNDOFF_AMT)
                     ELSE V_RNDOFF_AMT
                  END;
               RETURN V_RNDOFF_AMT;
            END;

            PROCEDURE POPULATE_CALC_DETAIL_COL (
               HIST_BAL        IN GLHIST_BAL_RT,
               P_CR_INT_RATE   IN NUMBER,
               P_DB_INT_RATE   IN NUMBER,
               HIST_BAL_TYPE   IN PKG_COMMON_TYPES.SINGLE_CHAR DEFAULT 'N')
            IS
               V_AMOUNT        PKG_COMMON_TYPES.AMOUNT_T
                                  := NVL (HIST_BAL.GLBALH_BC_BAL, 0);
               V_FROM_DATE     PKG_COMMON_TYPES.DATE_T := HIST_BAL.START_DATE;
               V_UPTO_DATE     PKG_COMMON_TYPES.DATE_T := HIST_BAL.END_DATE;
               V_NO_OF_DAYS    PKG_COMMON_TYPES.NUMBER_T
                                  := HIST_BAL.NO_OF_DAYS;
               V_AMT_PRODUCT   PKG_COMMON_TYPES.NUMBER_T := 0;
               V_INT_AMT       PKG_COMMON_TYPES.AMOUNT_T := 0;
               V_COL_TYPE      PKG_COMMON_TYPES.SINGLE_CHAR
                                  := NVL (TRIM (HIST_BAL_TYPE), 'N');
               W_DUMMY         VARCHAR2 (100);
            BEGIN
               W_DUMMY :=
                  FN_GET_GLIBRINTPM_ROW (HIST_BAL.GL_CODE,
                                         V_BASE_CURR );

               SELECT NVL (TRIM (GLIBRIPMH_DB_BAL_INT_REQD), '0'),
                      TRIM (GLIBRIPMH_INCOME_HEAD),
                      TRIM (GLIBRIPMH_INT_RECVRY_GL_HEAD),
                      NVL (TRIM (GLIBRIPMH_CR_BAL_INT_REQD), '0'),
                      TRIM (GLIBRIPMH_EXPENSE_HEAD),
                      TRIM (GLIBRIPMH_INT_PAY_GL_HEAD),
                      NVL (TRIM (GLIBRIPMH_RNDOFF_CHOICE), 'N'),
                      DECODE (GLIBRIPMH_INT_CALC_DENOM,
                              '1', 360,
                              '2', 365,
                              '3', 366,
                              360),
                      NVL (GLIBRIPMH_RNDOFF_FACTOR, 1)
                 INTO V_DR_BAL_INT_REQ,
                      V_INCOME_HEAD,
                      V_RECV_HEAD,
                      V_CR_BAL_INT_REQ,
                      V_EXPENSE_HEAD,
                      V_PAYABLE_HEAD,
                      V_RNDOFF_CHOICE,
                      V_INT_CALC_DENOM,
                      V_RNDOFF_FACTOR
                 FROM GLIBRINTPMHIST
                WHERE    GLIBRIPMH_INTER_GL_HEAD
                      || ' '
                      || GLIBRIPMH_CURR_CODE
                      || ' '
                      || GLIBRIPMH_EFF_DATE = W_DUMMY;

               IF    (ABS (V_AMOUNT) > 0 AND V_COL_TYPE = 'V')
                  OR (V_AMOUNT > 0 AND V_CR_BAL_INT_REQ = '1')
                  OR (V_AMOUNT < 0 AND V_DR_BAL_INT_REQ = '1')
               THEN
                  V_AMT_PRODUCT := V_AMOUNT * V_NO_OF_DAYS;

                  IF V_AMT_PRODUCT > 0
                  THEN
                     V_TOT_CR_BAL := V_TOT_CR_BAL + ABS (V_AMT_PRODUCT);
                     V_INT_AMT :=
                          (V_AMT_PRODUCT * (P_CR_INT_RATE / 100))
                        / V_INT_CALC_DENOM;
                  ELSIF V_AMT_PRODUCT < 0
                  THEN
                     V_TOT_DR_BAL := V_TOT_DR_BAL + ABS (V_AMT_PRODUCT);
                     V_INT_AMT :=
                          (V_AMT_PRODUCT * (P_DB_INT_RATE / 100))
                        / V_INT_CALC_DENOM;
                  END IF;

                  IF ABS (V_INT_AMT) > 0
                  THEN
                     V_INT_AMT :=
                        GET_RNDOFF_AMT (V_ENTITY_NUM,
                                        V_INT_AMT,
                                        V_RNDOFF_CHOICE,
                                        V_RNDOFF_FACTOR);

                     IF V_INT_AMT > 0
                     THEN
                        V_TOT_CR_BAL_INT := V_TOT_CR_BAL_INT + ABS (V_INT_AMT);
                     ELSIF V_INT_AMT < 0
                     THEN
                        V_TOT_DR_BAL_INT := V_TOT_DR_BAL_INT + ABS (V_INT_AMT);
                     END IF;
                  END IF;
               ELSE
                  V_INT_AMT := 0;
               END IF;

               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_ENTITY_NUM :=
                  V_ENTITY_NUM;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_RUN_NUMBER :=
                  V_RUN_NUMBER;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_BRN_CODE := BRN_CODE;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_GLACC_CODE :=
                  HIST_BAL.GL_CODE;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_CURR_CODE := V_BASE_CURR;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_PROC_DATE :=
                  V_PROCESS_DATE;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_DTL_SL_NUM :=
                  INTCALCDTL_INDX;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_FROM_DATE := V_FROM_DATE;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_UPTO_DATE := V_UPTO_DATE;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_BALANCE := V_AMOUNT;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_CR_INT_RATE :=
                  CASE WHEN V_INT_AMT > 0 THEN P_CR_INT_RATE ELSE 0 END;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_DB_INT_RATE :=
                  CASE WHEN V_INT_AMT < 0 THEN P_DB_INT_RATE ELSE 0 END;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_NUM_OF_DAYS :=
                  ABS (V_NO_OF_DAYS);
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_DB_PRODUCT :=
                  CASE
                     WHEN V_AMT_PRODUCT < 0 THEN ABS (V_AMT_PRODUCT)
                     ELSE 0
                  END;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_CR_PRODUCT :=
                  CASE
                     WHEN V_AMT_PRODUCT > 0 THEN ABS (V_AMT_PRODUCT)
                     ELSE 0
                  END;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_CR_INT_AMOUNT :=
                  CASE WHEN V_INT_AMT > 0 THEN ABS (V_INT_AMT) ELSE 0 END;
               INTCALCDTL (INTCALCDTL_INDX).IBRNICDTL_DB_INT_AMOUNT :=
                  CASE WHEN V_INT_AMT < 0 THEN ABS (V_INT_AMT) ELSE 0 END;

               INTCALCDTL_INDX := INTCALCDTL_INDX + 1;
            END;

            PROCEDURE POPULATE_CALC_SUM
            IS
            BEGIN
               INTCALC_R.IBRNINTCALC_ENTITY_NUM := V_ENTITY_NUM;
               INTCALC_R.IBRNINTCALC_RUN_NUMBER := V_RUN_NUMBER;
               INTCALC_R.IBRNINTCALC_BRN_CODE := BRN_CODE;
               INTCALC_R.IBRNINTCALC_GLACC_CODE := ' ';
               INTCALC_R.IBRNINTCALC_CURR_CODE := V_BASE_CURR;
               INTCALC_R.IBRNINTCALC_PROC_DATE := V_PROCESS_DATE;
               INTCALC_R.IBRNINTCALC_INT_FROM_DATE := V_BAL_START_DATE;
               INTCALC_R.IBRNINTCALC_INT_UPTO_DATE := V_PROCESS_DATE;
               INTCALC_R.IBRNINTCALC_CR_BAL_INT :=
                  CASE
                     WHEN V_NET_INT_AMT > 0 THEN ABS (V_NET_INT_AMT)
                     ELSE 0
                  END;
               INTCALC_R.IBRNINTCALC_DB_BAL_INT :=
                  CASE
                     WHEN V_NET_INT_AMT < 0 THEN ABS (V_NET_INT_AMT)
                     ELSE 0
                  END;
               INTCALC_R.IBRNINTCALC_CR_BAL_INT_RND :=
                  CASE
                     WHEN V_NET_INT_AMT > 0 THEN ABS (V_NET_INT_AMT)
                     ELSE 0
                  END;
               INTCALC_R.IBRNINTCALC_DB_BAL_INT_RND :=
                  CASE
                     WHEN V_NET_INT_AMT < 0 THEN ABS (V_NET_INT_AMT)
                     ELSE 0
                  END;
               INTCALC_R.IBRNINTCALC_POSTED_FLG := '0';
               INTCALC_R.IBRNINTCALC_PROC_BY := V_USER_ID;
               INTCALC_R.IBRNINTCALC_PROC_ON := V_CBD;
               INTCALC_R.IBRNINTCALC_POSTED_BY := V_USER_ID;
               INTCALC_R.IBRNINTCALC_POSTED_ON := V_CBD;
               INTCALC_R.POST_TRAN_BRN := BRN_CODE;
               INTCALC_R.POST_TRAN_DATE := V_CBD;
               INTCALC_R.POST_TRAN_BATCH_NUM := 0;
            END;

            PROCEDURE POPULATE_HIST_BAL
            IS
               GLHISTBAL_REC                GLHIST_BAL_RT;
               LAST_DAY_HISTBAL             GLBALASONHIST.GLBALH_BC_BAL%TYPE := 0;
               LAST_HISTBAL_CONT_FOR_DAYS   PKG_COMMON_TYPES.NUMBER_T := 0;
               LAST_DAY_BAL                 GLBBAL.GLBBAL_BC_BAL%TYPE := 0;
               HIST_BAL_LAST_INDEX          PLS_INTEGER := 0;
               V_GL_CODE                    VARCHAR2 (15);
            BEGIN
               IF GL_PM_REC.COUNT > 0
               THEN
                  FOR IND IN GL_PM_REC.FIRST .. GL_PM_REC.LAST
                  LOOP
                     V_GL_CODE := GL_PM_REC (IND).T_GLINTHIST_GLACC_CODE;

                       SELECT GLBALH_GLACC_CODE,
                              MIN (H.GLBALH_ASON_DATE) START_DATE,
                              MAX (H.GLBALH_ASON_DATE) END_DATE,
                              H.GLBALH_BC_BAL,
                              (  MAX (H.GLBALH_ASON_DATE)
                               - MIN (H.GLBALH_ASON_DATE)
                               + 1)
                                 NO_OF_DAYS
                         BULK COLLECT INTO GLHIST_BAL
                         FROM (SELECT G.*,
                                      (  ROW_NUMBER ()
                                            OVER (ORDER BY G.GLBALH_ASON_DATE)
                                       - ROW_NUMBER ()
                                         OVER (PARTITION BY G.GLBALH_BC_BAL
                                               ORDER BY G.GLBALH_ASON_DATE))
                                         GRP
                                 FROM (  SELECT GLBALH_GLACC_CODE,
                                                GLBALH_ASON_DATE,
                                                SUM (GLBALH_BC_BAL) GLBALH_BC_BAL
                                           FROM GLBALASONHIST
                                          WHERE     GLBALH_ENTITY_NUM =
                                                       V_ENTITY_NUM
                                                AND GLBALH_BRN_CODE = BRN_CODE
                                                AND GLBALH_GLACC_CODE =
                                                       GL_PM_REC (IND).T_GLINTHIST_GLACC_CODE
                                                AND GLBALH_ASON_DATE BETWEEN V_BAL_START_DATE
                                                                         AND V_PROCESS_DATE
                                       GROUP BY GLBALH_ASON_DATE,
                                                GLBALH_GLACC_CODE) G) H
                     GROUP BY H.GRP, H.GLBALH_BC_BAL, GLBALH_GLACC_CODE
                     ORDER BY MIN (H.GLBALH_ASON_DATE);

                     -- GLBALASONHIST DOESN'T CONTAIN THE LAST DAY BALANCE
                     -- SO THE PROCESS DATE BALANCE HAS TO BE CALCULATED SEPARATELY
                     IF (GLHIST_BAL.COUNT > 0)
                     THEN
                        GLHISTBAL_REC := GLHIST_BAL (GLHIST_BAL.LAST);
                        HIST_BAL_LAST_INDEX := GLHIST_BAL.LAST;

                        IF (    V_PROCESS_DATE > GLHISTBAL_REC.END_DATE
                            AND ABS (V_PROCESS_DATE - GLHISTBAL_REC.END_DATE) =
                                   1
                            AND HIST_BAL_LAST_INDEX > 0)
                        THEN
                           LAST_DAY_HISTBAL := GLHISTBAL_REC.GLBALH_BC_BAL;
                           LAST_HISTBAL_CONT_FOR_DAYS :=
                              GLHISTBAL_REC.NO_OF_DAYS;

                           BEGIN
                              SELECT SUM (GLBBAL_BC_BAL)
                                INTO LAST_DAY_BAL
                                FROM GLBBAL
                               WHERE     GLBBAL_ENTITY_NUM = V_ENTITY_NUM
                                     AND GLBBAL_BRANCH_CODE = BRN_CODE
                                     AND GLBBAL_GLACC_CODE =
                                            GL_PM_REC (IND).T_GLINTHIST_GLACC_CODE
                                     AND GLBBAL_YEAR =
                                            TO_NUMBER (
                                               TO_CHAR (V_PROCESS_DATE,
                                                        'YYYY'));
                           EXCEPTION
                              WHEN NO_DATA_FOUND
                              THEN
                                 LAST_DAY_BAL := 0;
                           END;

                           IF LAST_DAY_BAL <> 0
                           THEN
                              IF LAST_DAY_BAL = LAST_DAY_HISTBAL
                              THEN
                                 LAST_HISTBAL_CONT_FOR_DAYS :=
                                    LAST_HISTBAL_CONT_FOR_DAYS + 1;
                                 GLHIST_BAL (HIST_BAL_LAST_INDEX).NO_OF_DAYS :=
                                    LAST_HISTBAL_CONT_FOR_DAYS;
                                 GLHIST_BAL (HIST_BAL_LAST_INDEX).END_DATE :=
                                    V_PROCESS_DATE;
                              ELSE
                                 GLHIST_BAL (HIST_BAL_LAST_INDEX + 1).START_DATE :=
                                    GLHIST_BAL (HIST_BAL_LAST_INDEX).END_DATE;
                                 GLHIST_BAL (HIST_BAL_LAST_INDEX + 1).END_DATE :=
                                    V_PROCESS_DATE;
                                 GLHIST_BAL (HIST_BAL_LAST_INDEX + 1).GLBALH_BC_BAL :=
                                    LAST_DAY_BAL;
                                 GLHIST_BAL (HIST_BAL_LAST_INDEX + 1).NO_OF_DAYS :=
                                    1;
                              END IF;
                           END IF;
                        END IF;
                     END IF;



                     -- THEN, NORMAL GL BALANCE CALCULATION
                     IF GLHIST_BAL.COUNT > 0
                     THEN
                        FOR HISTINDX IN GLHIST_BAL.FIRST .. GLHIST_BAL.LAST
                        LOOP
                           POPULATE_CALC_DETAIL_COL (
                              GLHIST_BAL (HISTINDX),
                              GL_PM_REC (IND).T_GLINTHIST_INT_RATE_CR_BAL,
                              GL_PM_REC (IND).T_GLINTHIST_INT_RATE_DB_BAL);
                        END LOOP;
                     END IF;
                  END LOOP;
               END IF;
            END POPULATE_HIST_BAL;

            PROCEDURE POPULATE_VAL_DATED_TX
            IS
               W_SQL   PKG_COMMON_TYPES.STRING_T;
            BEGIN
               IF GL_PM_REC.COUNT > 0
               THEN
                  FOR IND IN GL_PM_REC.FIRST .. GL_PM_REC.LAST
                  LOOP
                     W_SQL :=
                           'SELECT Q.TRAN_GLACC_CODE,
                                    Q.FROM_DATE,
                        Q.UPTO_DATE,
                        SUM (Q.NET_AMOUNT) OVER (ORDER BY Q.FROM_DATE ASC)
                           AMOUNT,
                        ABS(Q.UPTO_DATE - Q.FROM_DATE + 1) NO_OF_DAYS
                   FROM (SELECT P.TRAN_GLACC_CODE,
                                P.TRAN_VALUE_DATE FROM_DATE,
                                (P.CR_SUM - P.DR_SUM) NET_AMOUNT,
                                CASE
                                   WHEN (P.CR_SUM - P.DR_SUM) > 0 THEN ''C''
                                   ELSE ''D''
                                END
                                   DR_CR,
                                LEAD (P.TRAN_VALUE_DATE - 1, 1, P.TRAN_DATE_OF_TRAN - 1)
                                   OVER (ORDER BY P.TRAN_VALUE_DATE ASC)
                                   UPTO_DATE
                           FROM (  SELECT O.TRAN_GLACC_CODE,
                                          O.TRAN_DATE_OF_TRAN,
                                          O.TRAN_VALUE_DATE,
                                          SUM (
                                             CASE
                                                WHEN O.TRAN_DB_CR_FLG = ''D''
                                                THEN
                                                   O.TRAN_AMOUNT
                                                ELSE
                                                   0
                                             END)
                                             DR_SUM,
                                          SUM (
                                             CASE
                                                WHEN O.TRAN_DB_CR_FLG = ''C''
                                                THEN
                                                   O.TRAN_AMOUNT
                                                ELSE
                                                   0
                                             END)
                                             CR_SUM
                                     FROM (SELECT TRAN_GLACC_CODE,
                                                  TRAN_DATE_OF_TRAN,
                                                  TRAN_VALUE_DATE,
                                                  TRAN_DB_CR_FLG,
                                                  CASE
                                                     WHEN NVL (
                                                             TRAN_BASE_CURR_EQ_AMT,
                                                             0) <> 0
                                                     THEN
                                                        NVL (
                                                           TRAN_BASE_CURR_EQ_AMT,
                                                           0)
                                                     ELSE
                                                        NVL (TRAN_AMOUNT, 0)
                                                  END
                                                     TRAN_AMOUNT
                                             FROM TRAN'
                        || V_FIN_YEAR
                        || ' WHERE TRAN_ENTITY_NUM = :1
                                                  AND TRAN_ACING_BRN_CODE = :2
                                                  AND TRAN_DATE_OF_TRAN BETWEEN :3 AND :4
                                                  AND TRAN_GLACC_CODE = :5
                                                  AND TRAN_AMOUNT <> 0
                                                  AND (TRAN_AC_CANCEL_AMT = 0 OR TRAN_BC_CANCEL_AMT = 0)
                                                  AND TRAN_DATE_OF_TRAN <>
                                                         TRAN_VALUE_DATE
                                                  AND TRAN_AUTH_ON IS NOT NULL) O
                                 GROUP BY O.TRAN_DATE_OF_TRAN, O.TRAN_VALUE_DATE, O.TRAN_GLACC_CODE ) P
                          WHERE (P.CR_SUM - P.DR_SUM) <> 0) Q
               ORDER BY Q.FROM_DATE';

                     --DBMS_OUTPUT.PUT_LINE(W_SQL);
                     EXECUTE IMMEDIATE W_SQL
                        BULK COLLECT INTO GLVALDATED_TX
                        USING V_ENTITY_NUM,
                              BRN_CODE,
                              V_BAL_START_DATE,
                              V_PROCESS_DATE,
                              GL_PM_REC (IND).T_GLINTHIST_GLACC_CODE;



                     -- FIRST, PROCESS VALUE DATED TX
                     IF GLVALDATED_TX.COUNT > 0
                     THEN
                        FOR VALINDX IN GLVALDATED_TX.FIRST ..
                                       GLVALDATED_TX.LAST
                        LOOP
                           POPULATE_CALC_DETAIL_COL (
                              GLVALDATED_TX (VALINDX),
                              GL_PM_REC (IND).T_GLINTHIST_INT_RATE_CR_BAL,
                              GL_PM_REC (IND).T_GLINTHIST_INT_RATE_DB_BAL,
                              'V');
                        END LOOP;
                     END IF;
                  END LOOP;
               END IF;
            END POPULATE_VAL_DATED_TX;

            PROCEDURE GET_CALC_START_DATE
            IS
               LAST_PROC_DATE   PKG_COMMON_TYPES.DATE_T;

               FUNCTION GET_LAST_PROCESS_DATE
                  RETURN PKG_COMMON_TYPES.DATE_T
               IS
                  V_LAST_PROCESS_DATE   PKG_COMMON_TYPES.DATE_T;
               BEGIN
                  BEGIN
                     SELECT MAX (IBRNINTCALC_PROC_DATE)
                       INTO V_LAST_PROCESS_DATE
                       FROM IBRNINTCALC
                      WHERE     IBRNINTCALC_ENTITY_NUM = V_ENTITY_NUM
                            AND IBRNINTCALC_BRN_CODE = BRN_CODE;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        NULL;
                  END;

                  RETURN V_LAST_PROCESS_DATE;
               END GET_LAST_PROCESS_DATE;
            BEGIN
               LAST_PROC_DATE := GET_LAST_PROCESS_DATE;

               IF LAST_PROC_DATE IS NOT NULL
               THEN
                  V_BAL_START_DATE := LAST_PROC_DATE + 1;
               ELSE
                  V_BAL_START_DATE := V_BRN_MIG_DATE + 1;
               END IF;
            END GET_CALC_START_DATE;

            PROCEDURE POST_PROCESS
            IS
               W_ERR_CODE       VARCHAR2 (6) := NULL;
               V_BATCH_NUMBER   IBRNINTCALC.POST_TRAN_BATCH_NUM%TYPE;
               W_IND            PKG_COMMON_TYPES.NUMBER_T := 0;

               PROCEDURE SET_VOUCHER
               IS
               BEGIN
                  W_IND := W_IND + 1;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_ACING_BRN_CODE :=
                     BRN_CODE;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_INTERNAL_ACNUM := 0;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_GLACC_CODE :=
                     CASE
                        WHEN V_NET_INT_AMT > 0 THEN V_EXPENSE_HEAD
                        ELSE V_RECV_HEAD
                     END;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_DB_CR_FLG := 'D';
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_TYPE_OF_TRAN := '1';
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_AMOUNT :=
                     ABS (V_NET_INT_AMT);
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_CURR_CODE :=
                     V_BASE_CURR;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_NARR_DTL1 :=
                     'Interest for all ';
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_NARR_DTL2 :=
                     'interest bearing IBR GL';

                  W_IND := W_IND + 1;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_ACING_BRN_CODE :=
                     BRN_CODE;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_INTERNAL_ACNUM := 0;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_GLACC_CODE :=
                     CASE
                        WHEN V_NET_INT_AMT > 0 THEN V_PAYABLE_HEAD
                        ELSE V_INCOME_HEAD
                     END;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_DB_CR_FLG := 'C';
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_TYPE_OF_TRAN := '1';
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_AMOUNT :=
                     ABS (V_NET_INT_AMT);
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_CURR_CODE :=
                     V_BASE_CURR;
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_NARR_DTL1 :=
                     'Interest for all ';
                  PKG_AUTOPOST.PV_TRAN_REC (W_IND).TRAN_NARR_DTL2 :=
                     'interest bearing IBR GL';
               END;

               PROCEDURE SET_TRAN_KEY_VALUES
               IS
               BEGIN
                  PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := BRN_CODE;
                  PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := V_CBD;
                  PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
                  PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;
               END;

               PROCEDURE SET_TRANBAT_VALUES
               IS
               BEGIN
                  PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE :=
                     'IBRNINTCALC';

                  PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY :=
                        V_ENTITY_NUM
                     || '|'
                     || BRN_CODE
                     || '|'
                     || '0'
                     || '|'
                     || V_BASE_CURR
                     || '|'
                     || V_CBD;

                  PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 :=
                     'IBR Interest Posting';
               END;

               PROCEDURE UPDATE_IBRCALCTABLES
               IS
                  PROCEDURE UPDATE_IBRINTCALC
                  IS
                  BEGIN
                     INTCALC_R.IBRNINTCALC_POSTED_FLG := '1';
                     INTCALC_R.POST_TRAN_BATCH_NUM := V_BATCH_NUMBER;

                     INSERT INTO IBRNINTCALC
                          VALUES INTCALC_R;
                  END;

                  PROCEDURE UPDATE_IBRINTCALCDTL
                  IS
                  BEGIN
                     FORALL I IN INTCALCDTL.FIRST .. INTCALCDTL.LAST
                        INSERT INTO IBRNINTCALCDTL
                             VALUES INTCALCDTL (I);
                  END;

                  PROCEDURE UPDATE_IBRINTPOSTCTL
                  IS
                  BEGIN
                     INSERT INTO IBRINTPOSTCTL (IBRINTPOSTCTL_ENTITY_NUM,
                                                IBRINTPOSTCTL_RUN_NUMBER,
                                                IBRINTPOSTCTL_BRN_CODE,
                                                IBRINTPOSTCTL_GLACC_CODE,
                                                IBRINTPOSTCTL_CURR_CODE,
                                                IBRINTPOSTCTL_PROC_DATE,
                                                IBRINTPOSTCTL_POSTED_BY,
                                                IBRINTPOSTCTL_POSTED_ON)
                          VALUES (V_ENTITY_NUM,
                                  V_RUN_NUMBER,
                                  BRN_CODE,
                                  ' ',
                                  V_BASE_CURR,
                                  V_PROCESS_DATE,
                                  V_USER_ID,
                                  V_CBD);
                  END;
               BEGIN
                  UPDATE_IBRINTCALC;
                  UPDATE_IBRINTCALCDTL;
                  UPDATE_IBRINTPOSTCTL;
               END;
            BEGIN
               SET_VOUCHER;

               PKG_POST_INTERFACE.G_PGM_NAME :=
                  PKG_EODSOD_FLAGS.PV_PROCESS_NAME;

               SET_TRAN_KEY_VALUES;
               SET_TRANBAT_VALUES;

               PKG_APOST_INTERFACE.SP_POST_SODEOD_BATCH (V_ENTITY_NUM,
                                                         'A',
                                                         W_IND,
                                                         0,
                                                         W_ERR_CODE,
                                                         V_ERR_MSG,
                                                         V_BATCH_NUMBER);

               IF (W_ERR_CODE <> '0000')
               THEN
                  V_ERR_MSG := FN_GET_AUTOPOST_ERR_MSG (V_ENTITY_NUM);
                  RAISE MYEXCEPTION;
               END IF;

               PKG_APOST_INTERFACE.SP_POSTING_END (V_ENTITY_NUM);
               UPDATE_IBRCALCTABLES;
            END;
         BEGIN
            GET_CALC_START_DATE;
            POPULATE_HIST_BAL;
            POPULATE_VAL_DATED_TX;



            IF ABS (V_TOT_CR_BAL_INT) > 0 OR ABS (V_TOT_DR_BAL_INT) > 0
            THEN
               V_NET_INT_AMT :=
                  ABS (V_TOT_CR_BAL_INT) - ABS (V_TOT_DR_BAL_INT);

               POPULATE_CALC_SUM;

               IF ABS (V_NET_INT_AMT) > 0
               THEN
                  POST_PROCESS;
               END IF;
            END IF;
         END;
      BEGIN
         BEGIN
            GET_BRN_MIG_DATE;
            POPULATE_GLINTPM;
            PROCESS_BRANCH;
         EXCEPTION
            WHEN OTHERS
            THEN
               V_ERR_MSG :=
                  SUBSTR (
                        'Error in processing branch: '
                     || BRN_CODE
                     || ', Msg: '
                     || SQLERRM,
                     1,
                     1000);
               PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                            'E',
                                            V_ERR_MSG,
                                            ' ',
                                            0);
         END;
      END;
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);
      V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_ENTITY_NUM);

      IF V_USER_ID IS NULL
      THEN
         V_USER_ID := TRIM (PKG_EODSOD_FLAGS.PV_USER_ID);
      END IF;

      IF V_PROCESS_DATE IS NULL
      THEN
         V_PROCESS_DATE := V_CBD;
      END IF;

      V_FIN_YEAR := SP_GETFINYEAR (V_ENTITY_NUM, V_PROCESS_DATE);
      V_RUN_NUMBER := FN_GET_RUNNO;
      V_BASE_CURR := PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR (V_ENTITY_NUM);

      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (V_ENTITY_NUM, V_BRN_CODE);

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         V_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

         IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (V_ENTITY_NUM,
                                                         V_BRN_CODE) = FALSE
         THEN
            PROCESS_BRN_WISE (V_BRN_CODE);
            PKG_EODSOD_FLAGS.PV_ERROR_MSG := V_ERR_MSG ;
            IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
            THEN
               PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (V_ENTITY_NUM,
                                                                V_BRN_CODE);
            END IF;

            PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (V_ENTITY_NUM);
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (V_ERR_MSG) IS NULL
         THEN
            V_ERR_MSG :=
               SUBSTR ('Error in SP_INTERBRNINTCALC: ' || SQLERRM, 1, 1000);
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := V_ERR_MSG;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                      'E',
                                      PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                      ' ',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_NUM,
                                      'E',
                                      SUBSTR (SQLERRM, 1, 1000),
                                      ' ',
                                      0);
   END;
END;
/

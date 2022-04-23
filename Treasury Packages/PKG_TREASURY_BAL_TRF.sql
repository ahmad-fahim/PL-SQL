CREATE OR REPLACE PACKAGE PKG_TREASURY_BAL_TRF
IS
   PROCEDURE SP_BAL_TRANSFER (P_ENTITY_NUM IN NUMBER);
END PKG_TREASURY_BAL_TRF;
/

CREATE OR REPLACE PACKAGE BODY PKG_TREASURY_BAL_TRF
IS
   W_POST_ARRAY_INDEX      NUMBER (14) DEFAULT 0;
   W_ERROR                 VARCHAR2 (3000);
   V_USER_EXCEPTION        EXCEPTION;
   IDX1                    NUMBER DEFAULT 0;
   W_CURRENT_DATE          DATE;
   W_ERROR_CODE            VARCHAR2 (10);
   W_BATCH_NUM             NUMBER;
   V_NUMBER_OF_TRAN        NUMBER;
   W_ERR_CODE              VARCHAR2 (300);


   V_USER_ID               VARCHAR2 (8);
   V_ENTITY_NUM            NUMBER;
   V_BRN_CODE              NUMBER;
   V_FROM_GL               VARCHAR2 (15);
   V_TO_GL                 VARCHAR2 (15);
   V_GL_FOR_DEBIT_ENTRY    VARCHAR2 (15);
   V_GL_FOR_CREDIT_ENTRY   VARCHAR2 (15);
   V_GL_BORROW_NBFI        VARCHAR2 (15);
   V_GL_BORROW_BANK        VARCHAR2 (15);
   V_GL_LANDING_NBFI       VARCHAR2 (15);
   V_GL_LANDING_BANK       VARCHAR2 (15);
   V_FIN_YEAR              VARCHAR2 (4);
   V_TRANBAT_NARR          VARCHAR2 (105);


   TYPE TYP_REC IS RECORD
   (
      TRAN_BATCH_NUMBER       NUMBER (7),
      TRAN_DB_CR_FLG          VARCHAR2 (1),
      TRAN_CURR_CODE          VARCHAR2 (3),
      TRAN_AMOUNT             NUMBER (18, 3),
      TRAN_BASE_CURR_EQ_AMT   NUMBER (18, 3),
      TRAN_NARR_DTL1          VARCHAR2 (35),
      TRAN_NARR_DTL2          VARCHAR2 (35),
      TRAN_NARR_DTL3          VARCHAR2 (35),
      TRANBAT_NARR_DTL        VARCHAR2 (105)
   );

   TYPE TT_TRAN IS TABLE OF TYP_REC
      INDEX BY PLS_INTEGER;

   T_TRAN                  TT_TRAN;


   TYPE TYP_DEAL_REC IS RECORD
   (
      DEAL_REF_NUM   VARCHAR2 (35),
      DEAL_AMOUNT    NUMBER,
      PROD_NAME      VARCHAR2 (100),
      PROD_TYPE      TB_PRODUCT.PROD_TYPE%TYPE ,
      PROD_CODE      TB_PRODUCT.PROD_CODE%TYPE
   );

   TYPE TT_DEAL_TRAN IS TABLE OF TYP_DEAL_REC
      INDEX BY PLS_INTEGER;

   T_DEAL_TRAN             TT_DEAL_TRAN;



   TYPE TT_DEAL_REF_NUM IS TABLE OF VARCHAR2 (35)
      INDEX BY PLS_INTEGER;

   TYPE TT_PARENT_DEAL_REF_NUM IS TABLE OF VARCHAR2 (35)
      INDEX BY PLS_INTEGER;

   TYPE TT_YEAR_END_ED_FLG IS TABLE OF VARCHAR2 (1)
      INDEX BY PLS_INTEGER;

   TYPE TT_ED_ADJUSTMENT_FLG IS TABLE OF VARCHAR2 (1)
      INDEX BY PLS_INTEGER;

   TYPE TT_ED_DEDUCTION_YEAR IS TABLE OF NUMBER (4)
      INDEX BY PLS_INTEGER;

   TYPE TT_ED_DEDUCTION_DATE IS TABLE OF DATE
      INDEX BY PLS_INTEGER;

   TYPE TT_ED_DEDUCTION_AMOUNT IS TABLE OF NUMBER (18, 3)
      INDEX BY PLS_INTEGER;



   T_DEAL_REF_NUM          TT_DEAL_REF_NUM;
   T_PARENT_DEAL_REF_NUM   TT_PARENT_DEAL_REF_NUM;
   T_YEAR_END_ED_FLG       TT_YEAR_END_ED_FLG;
   T_ED_ADJUSTMENT_FLG     TT_ED_ADJUSTMENT_FLG;
   T_ED_DEDUCTION_YEAR     TT_ED_DEDUCTION_YEAR;
   T_ED_DEDUCTION_DATE     TT_ED_DEDUCTION_DATE;
   T_ED_DEDUCTION_AMOUNT   TT_ED_DEDUCTION_AMOUNT;



   PROCEDURE SP_UPDATE_DEAL_ED_DETAILS
   IS
      V_COUNT   NUMBER := 0;
   BEGIN
      V_COUNT := T_DEAL_REF_NUM.COUNT;

      IF T_DEAL_REF_NUM.COUNT > 0
      THEN
         FORALL M_INDEX IN 1 .. T_DEAL_REF_NUM.COUNT
            INSERT INTO DEAL_ED_DETAILS (ED_ENTITY_NUM,
                                         ED_DEAL_REF_NUM,
                                         ED_PARENT_DEAL_REF_NUM,
                                         ED_YEAR_END_ED_FLG,
                                         ED_ADJUSTMENT_FLG,
                                         ED_DEDUCTION_YEAR,
                                         ED_DEDUCTION_DATE,
                                         ED_DEDUCTION_AMOUNT,
                                         ED_POST_TRAN_DATE,
                                         ED_POST_TRAN_BRN,
                                         ED_POST_TRAN_BATCH,
                                         ED_DEDUCTION_ENTD_BY,
                                         ED_DEDUCTION_ENTD_ON,
                                         ED_DEDUCTION_AUTH_BY,
                                         ED_DEDUCTION_AUTH_ON)
                 VALUES (V_ENTITY_NUM,
                         T_DEAL_REF_NUM (M_INDEX),
                         T_PARENT_DEAL_REF_NUM (M_INDEX),
                         T_YEAR_END_ED_FLG (M_INDEX),
                         T_ED_ADJUSTMENT_FLG (M_INDEX),
                         T_ED_DEDUCTION_YEAR (M_INDEX),
                         T_ED_DEDUCTION_DATE (M_INDEX),
                         T_ED_DEDUCTION_AMOUNT (M_INDEX),
                         W_CURRENT_DATE,
                         V_BRN_CODE,
                         W_BATCH_NUM,
                         PKG_EODSOD_FLAGS.PV_USER_ID,
                         SYSDATE,
                         PKG_EODSOD_FLAGS.PV_USER_ID,
                         SYSDATE);
      END IF;

      T_DEAL_REF_NUM.DELETE;
      T_PARENT_DEAL_REF_NUM.DELETE;
      T_YEAR_END_ED_FLG.DELETE;
      T_ED_ADJUSTMENT_FLG.DELETE;
      T_ED_DEDUCTION_YEAR.DELETE;
      T_ED_DEDUCTION_DATE.DELETE;
      T_ED_DEDUCTION_AMOUNT.DELETE;
   END SP_UPDATE_DEAL_ED_DETAILS;


   FUNCTION FN_GET_EXCIES_DUTYAMOUNT (P_AMOUNT NUMBER)
      RETURN NUMBER
   IS
      V_EXCISEDUTY_AMT   NUMBER (18, 3);
   BEGIN
      SELECT CHGAMT_FIXED_CHGS
        INTO V_EXCISEDUTY_AMT
        FROM (SELECT CHGAMT_AMT_SL,
                     LAG (CHGAMT_UPTO_AMT + 1, 1, 0)
                        OVER (ORDER BY CHGAMT_UPTO_AMT)
                        AS PREVIOUS_CHGAMT_UPTO_AMT,
                     CHGAMT_UPTO_AMT,
                     CHGAMT_FIXED_CHGS
                FROM CHGSTENORAMT
               WHERE     CHGAMT_ENTITY_NUM = 1
                     AND CHGAMT_CHG_CODE = 'ED'
                     AND CHGAMT_CHG_TYPE = 'A'
                     AND CHGAMT_CHG_CURR = 'BDT'
                     AND CHGAMT_TENOR_SL = 1)
       WHERE P_AMOUNT BETWEEN PREVIOUS_CHGAMT_UPTO_AMT AND CHGAMT_UPTO_AMT;

      RETURN V_EXCISEDUTY_AMT;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_EXCISEDUTY_AMT := 0;
         RETURN V_EXCISEDUTY_AMT;
   END FN_GET_EXCIES_DUTYAMOUNT;


   PROCEDURE INITILIZE_TRANSACTION
   IS
   BEGIN
      PKG_AUTOPOST.PV_USERID := V_USER_ID;
      PKG_AUTOPOST.PV_BOPAUTHQ_REQ := FALSE;
      PKG_AUTOPOST.PV_AUTH_DTLS_UPDATE_REQ := FALSE;
      PKG_AUTOPOST.PV_CALLED_BY_EOD_SOD := 1;
      PKG_AUTOPOST.PV_EXCEP_CHECK_NOT_REQD := FALSE;
      PKG_AUTOPOST.PV_OVERDRAFT_CHK_REQD := FALSE;
      PKG_AUTOPOST.PV_ALLOW_ZERO_TRANAMT := FALSE;
      PKG_PROCESS_BOPAUTHQ.V_BOPAUTHQ_UPD := FALSE;
      PKG_AUTOPOST.pv_cancel_flag := FALSE;
      PKG_AUTOPOST.pv_post_as_unauth_mod := FALSE;
      PKG_AUTOPOST.pv_clg_batch_closure := FALSE;
      PKG_AUTOPOST.pv_authorized_record_cancel := FALSE;
      PKG_AUTOPOST.PV_BACKDATED_TRAN_REQUIRED := 0;
      PKG_AUTOPOST.PV_CLG_REGN_POSTING := FALSE;
      PKG_AUTOPOST.pv_fresh_batch_sl := FALSE;
      PKG_AUTOPOST.pv_tran_key.Tran_Brn_Code := V_BRN_CODE;
      PKG_AUTOPOST.pv_tran_key.Tran_Date_Of_Tran := W_CURRENT_DATE;
      PKG_AUTOPOST.pv_tran_key.Tran_Batch_Number := 0;
      PKG_AUTOPOST.pv_tran_key.Tran_Batch_Sl_Num := 0;
      PKG_AUTOPOST.PV_AUTO_AUTHORISE := TRUE;
      --PKG_PB_GLOBAL.G_TERMINAL_ID := '10.10.7.149';
      PKG_POST_INTERFACE.G_BATCH_NUMBER_UPDATE_REQ := FALSE;
      PKG_POST_INTERFACE.G_SRC_TABLE_AUTH_REJ_REQ := FALSE;
      PKG_AUTOPOST.PV_TRAN_ONLY_UNDO := FALSE;
      PKG_AUTOPOST.PV_OCLG_POSTING_FLG := FALSE;
      PKG_POST_INTERFACE.G_IBR_REQUIRED := 0;
      -- PKG_PB_test.G_FORM_NAME                             := 'ETRAN';
      --PKG_POST_INTERFACE.G_PGM_NAME := 'ETRAN';
      PKG_AUTOPOST.PV_USER_ROLE_CODE := '';
      PKG_AUTOPOST.PV_SUPP_TRAN_POST := FALSE;
      PKG_AUTOPOST.PV_FUTURE_TRANSACTION_ALLOWED := FALSE;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_BRN_CODE := V_BRN_CODE;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_DATE_OF_TRAN := W_CURRENT_DATE;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_BATCH_NUMBER := 0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_ENTRY_BRN_CODE := V_BRN_CODE;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_WITHDRAW_SLIP := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_TOKEN_ISSUED := 0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_BACKOFF_SYS_CODE := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_DEVICE_CODE := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_DEVICE_UNIT_NUM := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_CHANNEL_DT_TIME := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_CHANNEL_UNIQ_NUM := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_COST_CNTR_CODE := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SUB_COST_CNTR := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_PROFIT_CNTR_CODE := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SUB_PROFIT_CNTR := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_NUM_TRANS := V_NUMBER_OF_TRAN;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_BASE_CURR_TOT_CR := 0.0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_BASE_CURR_TOT_DB := 0.0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_CANCEL_BY := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_CANCEL_ON := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_CANCEL_REM1 := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_CANCEL_REM2 := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_CANCEL_REM3 := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SOURCE_TABLE := 'TRAN';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SOURCE_KEY :=
         V_BRN_CODE || W_CURRENT_DATE || '|0';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_NARR_DTL1 := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_NARR_DTL2 := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_NARR_DTL3 := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_AUTH_BY := V_USER_ID;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_AUTH_ON := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SHIFT_TO_TRAN_DATE := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SHIFT_TO_BAT_NUM := 0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SHIFT_FROM_TRAN_DATE := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SHIFT_FROM_BAT_NUM := 0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_REV_TO_TRAN_DATE := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_REV_TO_BAT_NUM := 0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_REV_FROM_TRAN_DATE := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_REV_FROM_BAT_NUM := 0;
   END;

   PROCEDURE SET_TRANBAT_VALUES (P_BRN_CODE       IN NUMBER,
                                 P_TRANBAT_NARR   IN VARCHAR2)
   IS
   BEGIN
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'TRAN';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY := P_BRN_CODE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 := P_TRANBAT_NARR;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_AUTH_BY := V_USER_ID;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_AUTH_ON := SYSDATE;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN SET_TRANBAT_VALUES '
            || P_BRN_CODE
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END SET_TRANBAT_VALUES;



   PROCEDURE POST_TRANSACTION
   IS
   BEGIN
      PKG_APOST_INTERFACE.SP_POST_SODEOD_BATCH ( (V_ENTITY_NUM),
                                                'A',
                                                W_POST_ARRAY_INDEX,
                                                0,
                                                W_ERR_CODE,
                                                W_ERROR,
                                                W_BATCH_NUM);

      PKG_AUTOPOST.PV_TRAN_REC.DELETE;

      IF (W_ERR_CODE <> '0000')
      THEN
         W_ERROR :=
               'ERROR IN POST_TRANSACTION for Excise Duty-  '
            || FN_GET_AUTOPOST_ERR_MSG (PKG_ENTITY.FN_GET_ENTITY_CODE);
         RAISE V_USER_EXCEPTION;
      END IF;
   END POST_TRANSACTION;



   PROCEDURE AUTOPOST_ENTRIES
   IS
   BEGIN
      IF W_POST_ARRAY_INDEX > 0
      THEN
         POST_TRANSACTION;
      END IF;

      W_POST_ARRAY_INDEX := 0;
      IDX1 := 0;
   END AUTOPOST_ENTRIES;

   PROCEDURE SET_TRAN_KEY_VALUES (P_BRN_CODE NUMBER)
   IS
   BEGIN
      PKG_AUTOPOST.PV_SYSTEM_POSTED_TRANSACTION := TRUE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := P_BRN_CODE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := W_CURRENT_DATE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;

      PKG_AUTOPOST.PV_USERID := V_USER_ID;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN SET_TRAN_KEY_VALUES '
            || '-'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END SET_TRAN_KEY_VALUES;

   PROCEDURE MOVE_TO_TRANREC_GL (P_BRN_CODE       IN NUMBER,
                                 P_DEBIT_CREDIT      VARCHAR2,
                                 P_GL                VARCHAR2,
                                 P_TRAN_AC_AMT    IN NUMBER,
                                 P_TRAN_BC_AMT    IN NUMBER,
                                 P_CURRENCY       IN VARCHAR2,
                                 P_NARR1          IN VARCHAR2,
                                 P_NARR2          IN VARCHAR2,
                                 P_NARR3          IN VARCHAR2)
   IS
   BEGIN
      V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
      W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_BRN_CODE :=
         P_BRN_CODE;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN :=
         W_CURRENT_DATE;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_GLACC_CODE := P_GL;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_DB_CR_FLG :=
         P_DEBIT_CREDIT;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_BASE_CURR_CODE :=
         'BDT';
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_CURR_CODE :=
         P_CURRENCY;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_AMOUNT :=
         P_TRAN_AC_AMT;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_BASE_CURR_EQ_AMT :=
         P_TRAN_BC_AMT;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_VALUE_DATE :=
         W_CURRENT_DATE;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL1 := P_NARR1;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL2 := P_NARR2;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL3 := P_NARR3;

      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_AUTH_BY := V_USER_ID;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_AUTH_ON := SYSDATE;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
            'ERROR IN MOVE_TO_TRANREC ' || '-' || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END MOVE_TO_TRANREC_GL;


   FUNCTION FN_GET_PARENT_DEAL (P_CHILD_DEAL VARCHAR2)
      RETURN VARCHAR2
   IS
      V_PARENT_DEAL_REF_NUMBER   VARCHAR2 (16);
   BEGIN
      BEGIN
         SELECT REF_NUM
           INTO V_PARENT_DEAL_REF_NUMBER
           FROM (    SELECT LEVEL LB, REF_NUM, A.ROLOVR_CHLD_REF_NUM
                       FROM TB_MMBACKOFFICE A
                 CONNECT BY PRIOR REF_NUM = ROLOVR_CHLD_REF_NUM
                 START WITH ROLOVR_CHLD_REF_NUM = P_CHILD_DEAL) AA
          WHERE AA.LB = (    SELECT MAX (LEVEL)
                               FROM TB_MMBACKOFFICE A
                         CONNECT BY PRIOR REF_NUM = ROLOVR_CHLD_REF_NUM
                         START WITH ROLOVR_CHLD_REF_NUM = P_CHILD_DEAL);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_PARENT_DEAL_REF_NUMBER := P_CHILD_DEAL;
      END;

      RETURN V_PARENT_DEAL_REF_NUMBER;
   END FN_GET_PARENT_DEAL;



   PROCEDURE ED_ADJUSTMENT_MAT_CLOSURE
   IS
      V_SQL                     VARCHAR2 (1000);
      V_EXCISEDUTY_AMT          NUMBER (18, 3);
      V_PARENT_DEAL             VARCHAR2 (35);
      V_ED_DEDUCTED_PREV_YEAR   NUMBER (18, 3);

      V_ED_PAYABLE_GL           VARCHAR2 (15);
      V_ED_RECEIVABLE_GL        VARCHAR2 (15);
      V_ED_PROVISION_GL         VARCHAR2 (15);

      V_INDEX_NUMBER            NUMBER := 0;
   BEGIN
      SELECT ED_PAYABLE_GL, ED_RECEIVABLE_GL, ED_PROVISION_GL
        INTO V_ED_PAYABLE_GL, V_ED_RECEIVABLE_GL, V_ED_PROVISION_GL
        FROM DEAL_ED_DEDUC_GL;


      V_SQL :=
            'SELECT DISTINCT TRAN_NARR_DTL2 , AMOUNT  , PROD_NAME, TB_PRODUCT.PROD_TYPE, TB_PRODUCT.PROD_CODE
            FROM TRAN'
         || V_FIN_YEAR
         || ', TB_MMBACKOFFICE, TB_PRODUCT
           WHERE     TRAN_ENTITY_NUM = :1
                 AND TRAN_BRN_CODE = :BRN_CODE
                 AND TRAN_DATE_OF_TRAN = :W_CURRENT_DATE
                 AND TRAN_GLACC_CODE = :V_FROM_GL
                 AND TRAN_AMOUNT <> 0
                 AND TRAN_NARR_DTL3 = ''CLOSER_MATURITY''
                 AND TRAN_AUTH_BY IS NOT NULL
                 AND TRAN_NARR_DTL2 = REF_NUM
				 AND TB_MMBACKOFFICE.PROD_TYPE = TB_PRODUCT.PROD_TYPE
                 AND TB_MMBACKOFFICE.PROD_CODE = TB_PRODUCT.PROD_CODE';

      EXECUTE IMMEDIATE V_SQL
         BULK COLLECT INTO T_DEAL_TRAN
         USING V_ENTITY_NUM,
               V_BRN_CODE,
               W_CURRENT_DATE,
               V_FROM_GL;

      IF T_DEAL_TRAN.COUNT > 0
      THEN
         FOR IDX IN T_DEAL_TRAN.FIRST .. T_DEAL_TRAN.LAST
         LOOP
            V_EXCISEDUTY_AMT :=
               FN_GET_EXCIES_DUTYAMOUNT (T_DEAL_TRAN (IDX).DEAL_AMOUNT);
            V_PARENT_DEAL :=
               FN_GET_PARENT_DEAL (T_DEAL_TRAN (IDX).DEAL_REF_NUM);

           <<ED_DEDUCTED_PREV_YEAR>>
            BEGIN
               SELECT NVL (SUM (YEAR_END_ED), 0) - NVL (SUM (ADJUSTED_ED), 0)
                 INTO V_ED_DEDUCTED_PREV_YEAR
                 FROM (SELECT CASE
                                 WHEN ED_YEAR_END_ED_FLG = '1'
                                 THEN
                                    ED_DEDUCTION_AMOUNT
                                 ELSE
                                    0
                              END
                                 YEAR_END_ED,
                              CASE
                                 WHEN ED_ADJUSTMENT_FLG = '1'
                                 THEN
                                    ED_DEDUCTION_AMOUNT
                                 ELSE
                                    0
                              END
                                 ADJUSTED_ED
                         FROM DEAL_ED_DETAILS
                        WHERE     ED_ENTITY_NUM = V_ENTITY_NUM
                              AND ED_PARENT_DEAL_REF_NUM = V_PARENT_DEAL);
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_ED_DEDUCTED_PREV_YEAR := 0;
            END ED_DEDUCTED_PREV_YEAR;

            IF V_EXCISEDUTY_AMT > 0
            THEN
               IF T_DEAL_TRAN (IDX).PROD_TYPE = 'MM' AND T_DEAL_TRAN (IDX).PROD_CODE = '204'
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     'D',
                     V_ED_PAYABLE_GL,
                     V_EXCISEDUTY_AMT,
                     V_EXCISEDUTY_AMT,
                     'BDT',
                     'ED Deduction for maturity',
                     'Parent deal :' || V_PARENT_DEAL,
                     'Child deal :' || T_DEAL_TRAN (IDX).DEAL_REF_NUM);

                  V_INDEX_NUMBER := V_INDEX_NUMBER + 1;

                  T_DEAL_REF_NUM (V_INDEX_NUMBER) :=
                     T_DEAL_TRAN (IDX).DEAL_REF_NUM;
                  T_PARENT_DEAL_REF_NUM (V_INDEX_NUMBER) := V_PARENT_DEAL;
                  T_YEAR_END_ED_FLG (V_INDEX_NUMBER) := '1';
                  T_ED_ADJUSTMENT_FLG (V_INDEX_NUMBER) := '0';
                  T_ED_DEDUCTION_YEAR (V_INDEX_NUMBER) :=
                     TO_NUMBER (TO_CHAR (W_CURRENT_DATE, 'YYYY'));
                  T_ED_DEDUCTION_DATE (V_INDEX_NUMBER) := W_CURRENT_DATE;
                  T_ED_DEDUCTION_AMOUNT (V_INDEX_NUMBER) := V_EXCISEDUTY_AMT;
               ELSIF T_DEAL_TRAN (IDX).PROD_TYPE = 'MM' AND T_DEAL_TRAN (IDX).PROD_CODE = '101'
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     'C',
                     V_ED_RECEIVABLE_GL,
                     V_EXCISEDUTY_AMT,
                     V_EXCISEDUTY_AMT,
                     'BDT',
                     'ED Deduction for maturity',
                     'Parent deal :' || V_PARENT_DEAL,
                     'Child deal :' || T_DEAL_TRAN (IDX).DEAL_REF_NUM);

                  V_INDEX_NUMBER := V_INDEX_NUMBER + 1;

                  T_DEAL_REF_NUM (V_INDEX_NUMBER) :=
                     T_DEAL_TRAN (IDX).DEAL_REF_NUM;
                  T_PARENT_DEAL_REF_NUM (V_INDEX_NUMBER) := V_PARENT_DEAL;
                  T_YEAR_END_ED_FLG (V_INDEX_NUMBER) := '1';
                  T_ED_ADJUSTMENT_FLG (V_INDEX_NUMBER) := '0';
                  T_ED_DEDUCTION_YEAR (V_INDEX_NUMBER) :=
                     TO_NUMBER (TO_CHAR (W_CURRENT_DATE, 'YYYY'));
                  T_ED_DEDUCTION_DATE (V_INDEX_NUMBER) := W_CURRENT_DATE;
                  T_ED_DEDUCTION_AMOUNT (V_INDEX_NUMBER) := V_EXCISEDUTY_AMT;
               END IF;
            END IF;

            IF V_ED_DEDUCTED_PREV_YEAR > 0
            THEN
               IF T_DEAL_TRAN (IDX).PROD_TYPE = 'MM' AND T_DEAL_TRAN (IDX).PROD_CODE = '204'
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     'D',
                     V_ED_PROVISION_GL,
                     V_ED_DEDUCTED_PREV_YEAR,
                     V_ED_DEDUCTED_PREV_YEAR,
                     'BDT',
                     'ED Adjustment for previous year',
                     'Parent deal :' || V_PARENT_DEAL,
                     'Child deal :' || T_DEAL_TRAN (IDX).DEAL_REF_NUM);
               ELSIF T_DEAL_TRAN (IDX).PROD_TYPE = 'MM' AND T_DEAL_TRAN (IDX).PROD_CODE = '101'
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     'C',
                     V_ED_PROVISION_GL,
                     V_ED_DEDUCTED_PREV_YEAR,
                     V_ED_DEDUCTED_PREV_YEAR,
                     'BDT',
                     'ED Adjustment for previous year',
                     'Parent deal :' || V_PARENT_DEAL,
                     'Child deal :' || T_DEAL_TRAN (IDX).DEAL_REF_NUM);
               END IF;
            END IF;



            IF NVL (V_EXCISEDUTY_AMT, 0) + NVL (V_ED_DEDUCTED_PREV_YEAR, 0) >
                  0
            THEN
               IF T_DEAL_TRAN (IDX).PROD_TYPE = 'MM' AND T_DEAL_TRAN (IDX).PROD_CODE = '204'
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     'C',
                     V_FROM_GL,
                       NVL (V_EXCISEDUTY_AMT, 0)
                     + NVL (V_ED_DEDUCTED_PREV_YEAR, 0),
                       NVL (V_EXCISEDUTY_AMT, 0)
                     + NVL (V_ED_DEDUCTED_PREV_YEAR, 0),
                     'BDT',
                     V_PARENT_DEAL,
                     T_DEAL_TRAN (IDX).DEAL_REF_NUM,
                     'CLOSER_MATURITY');

                  V_INDEX_NUMBER := V_INDEX_NUMBER + 1;

                  T_DEAL_REF_NUM (V_INDEX_NUMBER) :=
                     T_DEAL_TRAN (IDX).DEAL_REF_NUM;
                  T_PARENT_DEAL_REF_NUM (V_INDEX_NUMBER) := V_PARENT_DEAL;
                  T_YEAR_END_ED_FLG (V_INDEX_NUMBER) := '0';
                  T_ED_ADJUSTMENT_FLG (V_INDEX_NUMBER) := '1';
                  T_ED_DEDUCTION_YEAR (V_INDEX_NUMBER) :=
                     TO_NUMBER (TO_CHAR (W_CURRENT_DATE, 'YYYY'));
                  T_ED_DEDUCTION_DATE (V_INDEX_NUMBER) := W_CURRENT_DATE;
                  T_ED_DEDUCTION_AMOUNT (V_INDEX_NUMBER) :=
                       NVL (V_EXCISEDUTY_AMT, 0)
                     + NVL (V_ED_DEDUCTED_PREV_YEAR, 0);
               ELSIF T_DEAL_TRAN (IDX).PROD_TYPE = 'MM' AND T_DEAL_TRAN (IDX).PROD_CODE = '101'
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     'D',
                     V_FROM_GL,
                       NVL (V_EXCISEDUTY_AMT, 0)
                     + NVL (V_ED_DEDUCTED_PREV_YEAR, 0),
                       NVL (V_EXCISEDUTY_AMT, 0)
                     + NVL (V_ED_DEDUCTED_PREV_YEAR, 0),
                     'BDT',
                     V_PARENT_DEAL,
                     T_DEAL_TRAN (IDX).DEAL_REF_NUM,
                     'CLOSER_MATURITY');

                  V_INDEX_NUMBER := V_INDEX_NUMBER + 1;

                  T_DEAL_REF_NUM (V_INDEX_NUMBER) :=
                     T_DEAL_TRAN (IDX).DEAL_REF_NUM;
                  T_PARENT_DEAL_REF_NUM (V_INDEX_NUMBER) := V_PARENT_DEAL;
                  T_YEAR_END_ED_FLG (V_INDEX_NUMBER) := '0';
                  T_ED_ADJUSTMENT_FLG (V_INDEX_NUMBER) := '1';
                  T_ED_DEDUCTION_YEAR (V_INDEX_NUMBER) :=
                     TO_NUMBER (TO_CHAR (W_CURRENT_DATE, 'YYYY'));
                  T_ED_DEDUCTION_DATE (V_INDEX_NUMBER) := W_CURRENT_DATE;
                  T_ED_DEDUCTION_AMOUNT (V_INDEX_NUMBER) :=
                       NVL (V_EXCISEDUTY_AMT, 0)
                     + NVL (V_ED_DEDUCTED_PREV_YEAR, 0);
               END IF;
            END IF;
         END LOOP;


         BEGIN
            SET_TRAN_KEY_VALUES (V_BRN_CODE);
            SET_TRANBAT_VALUES (V_BRN_CODE, 'Deal ED Adjustment');

            AUTOPOST_ENTRIES;


            W_POST_ARRAY_INDEX := 0;

            V_NUMBER_OF_TRAN := 0;
            PKG_AUTOPOST.PV_TRAN_REC.DELETE;
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE_APPLICATION_ERROR (-20100, 'ERROR AUTOPOST ' || W_ERROR);
         END;

         BEGIN
            SP_UPDATE_DEAL_ED_DETAILS;
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE_APPLICATION_ERROR (
                  -20100,
                  'ERROR IN UPDATE DEAL_ED_DETAILS ' || SQLERRM);
         END;
      END IF;
   END ED_ADJUSTMENT_MAT_CLOSURE;



   PROCEDURE ED_ADJUSTMENT_RENEW_MAT
   IS
      V_SQL                     VARCHAR2 (1000);

      V_PARENT_DEAL             VARCHAR2 (35);
      V_ED_DEDUCTED_PREV_YEAR   NUMBER (18, 3);
      V_ED_PAYABLE_GL           VARCHAR2 (15);
      V_ED_RECEIVABLE_GL        VARCHAR2 (15);
      V_ED_PROVISION_GL         VARCHAR2 (15);

      V_INDEX_NUMBER            NUMBER := 0;
   BEGIN
      SELECT ED_PAYABLE_GL, ED_RECEIVABLE_GL, ED_PROVISION_GL
        INTO V_ED_PAYABLE_GL, V_ED_RECEIVABLE_GL, V_ED_PROVISION_GL
        FROM DEAL_ED_DEDUC_GL;

      V_SQL :=
            'SELECT DISTINCT TRAN_NARR_DTL2 , AMOUNT  , PROD_NAME, TB_PRODUCT.PROD_TYPE, TB_PRODUCT.PROD_CODE
            FROM TRAN'
         || V_FIN_YEAR
         || ', TB_MMBACKOFFICE, TB_PRODUCT
           WHERE     TRAN_ENTITY_NUM = :1
                 AND TRAN_BRN_CODE = :BRN_CODE
                 AND TRAN_DATE_OF_TRAN = :W_CURRENT_DATE
                 AND TRAN_GLACC_CODE = :V_FROM_GL
                 AND TRAN_AMOUNT <> 0
                 AND TRAN_NARR_DTL3 IN (''REISSUE'',''ROLLOVER_MATURITY'')
                 AND TRAN_AUTH_BY IS NOT NULL
                 AND TRAN_NARR_DTL2 = REF_NUM
				 AND TB_MMBACKOFFICE.PROD_TYPE = TB_PRODUCT.PROD_TYPE
                 AND TB_MMBACKOFFICE.PROD_CODE = TB_PRODUCT.PROD_CODE';

      EXECUTE IMMEDIATE V_SQL
         BULK COLLECT INTO T_DEAL_TRAN
         USING V_ENTITY_NUM,
               V_BRN_CODE,
               W_CURRENT_DATE,
               V_FROM_GL;


      IF T_DEAL_TRAN.COUNT > 0
      THEN
         FOR IDX IN T_DEAL_TRAN.FIRST .. T_DEAL_TRAN.LAST
         LOOP
            V_PARENT_DEAL :=
               FN_GET_PARENT_DEAL (T_DEAL_TRAN (IDX).DEAL_REF_NUM);

           <<ED_DEDUCTED_PREV_YEAR>>
            BEGIN
               SELECT NVL (SUM (YEAR_END_ED), 0) - NVL (SUM (ADJUSTED_ED), 0)
                 INTO V_ED_DEDUCTED_PREV_YEAR
                 FROM (SELECT CASE
                                 WHEN ED_YEAR_END_ED_FLG = '1'
                                 THEN
                                    ED_DEDUCTION_AMOUNT
                                 ELSE
                                    0
                              END
                                 YEAR_END_ED,
                              CASE
                                 WHEN ED_ADJUSTMENT_FLG = '1'
                                 THEN
                                    ED_DEDUCTION_AMOUNT
                                 ELSE
                                    0
                              END
                                 ADJUSTED_ED
                         FROM DEAL_ED_DETAILS
                        WHERE     ED_ENTITY_NUM = V_ENTITY_NUM
                              AND ED_PARENT_DEAL_REF_NUM = V_PARENT_DEAL);
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_ED_DEDUCTED_PREV_YEAR := 0;
            END ED_DEDUCTED_PREV_YEAR;

            IF V_ED_DEDUCTED_PREV_YEAR > 0
            THEN
               IF T_DEAL_TRAN (IDX).PROD_TYPE = 'MM' AND T_DEAL_TRAN (IDX).PROD_CODE = '204'
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     'D',
                     V_ED_PROVISION_GL,
                     V_ED_DEDUCTED_PREV_YEAR,
                     V_ED_DEDUCTED_PREV_YEAR,
                     'BDT',
                     'ED Adjustment for previous year',
                     'Parent deal :' || V_PARENT_DEAL,
                     'Child deal :' || T_DEAL_TRAN (IDX).DEAL_REF_NUM);



                  MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                      'C',
                                      V_FROM_GL,
                                      NVL (V_ED_DEDUCTED_PREV_YEAR, 0),
                                      NVL (V_ED_DEDUCTED_PREV_YEAR, 0),
                                      'BDT',
                                      V_PARENT_DEAL,
                                      T_DEAL_TRAN (IDX).DEAL_REF_NUM,
                                      'REISSUE');

                  V_INDEX_NUMBER := V_INDEX_NUMBER + 1;

                  T_DEAL_REF_NUM (V_INDEX_NUMBER) :=
                     T_DEAL_TRAN (IDX).DEAL_REF_NUM;
                  T_PARENT_DEAL_REF_NUM (V_INDEX_NUMBER) := V_PARENT_DEAL;
                  T_YEAR_END_ED_FLG (V_INDEX_NUMBER) := '0';
                  T_ED_ADJUSTMENT_FLG (V_INDEX_NUMBER) := '1';
                  T_ED_DEDUCTION_YEAR (V_INDEX_NUMBER) :=
                     TO_NUMBER (TO_CHAR (W_CURRENT_DATE, 'YYYY'));
                  T_ED_DEDUCTION_DATE (V_INDEX_NUMBER) := W_CURRENT_DATE;
                  T_ED_DEDUCTION_AMOUNT (V_INDEX_NUMBER) :=
                     NVL (V_ED_DEDUCTED_PREV_YEAR, 0);
               ELSIF T_DEAL_TRAN (IDX).PROD_TYPE = 'MM' AND T_DEAL_TRAN (IDX).PROD_CODE = '101'
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     'C',
                     V_ED_PROVISION_GL,
                     V_ED_DEDUCTED_PREV_YEAR,
                     V_ED_DEDUCTED_PREV_YEAR,
                     'BDT',
                     'ED Adjustment for previous year',
                     'Parent deal :' || V_PARENT_DEAL,
                     'Child deal :' || T_DEAL_TRAN (IDX).DEAL_REF_NUM);


                  MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                      'D',
                                      V_FROM_GL,
                                      NVL (V_ED_DEDUCTED_PREV_YEAR, 0),
                                      NVL (V_ED_DEDUCTED_PREV_YEAR, 0),
                                      'BDT',
                                      V_PARENT_DEAL,
                                      T_DEAL_TRAN (IDX).DEAL_REF_NUM,
                                      'REISSUE');

                  V_INDEX_NUMBER := V_INDEX_NUMBER + 1;

                  T_DEAL_REF_NUM (V_INDEX_NUMBER) :=
                     T_DEAL_TRAN (IDX).DEAL_REF_NUM;
                  T_PARENT_DEAL_REF_NUM (V_INDEX_NUMBER) := V_PARENT_DEAL;
                  T_YEAR_END_ED_FLG (V_INDEX_NUMBER) := '0';
                  T_ED_ADJUSTMENT_FLG (V_INDEX_NUMBER) := '1';
                  T_ED_DEDUCTION_YEAR (V_INDEX_NUMBER) :=
                     TO_NUMBER (TO_CHAR (W_CURRENT_DATE, 'YYYY'));
                  T_ED_DEDUCTION_DATE (V_INDEX_NUMBER) := W_CURRENT_DATE;
                  T_ED_DEDUCTION_AMOUNT (V_INDEX_NUMBER) :=
                     NVL (V_ED_DEDUCTED_PREV_YEAR, 0);
               END IF;
            END IF;
         END LOOP;

         BEGIN
            SET_TRAN_KEY_VALUES (V_BRN_CODE);
            SET_TRANBAT_VALUES (V_BRN_CODE, 'Deal ED Adjustment');

            AUTOPOST_ENTRIES;


            W_POST_ARRAY_INDEX := 0;

            V_NUMBER_OF_TRAN := 0;
            PKG_AUTOPOST.PV_TRAN_REC.DELETE;
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE_APPLICATION_ERROR (-20100, 'ERROR AUTOPOST ' || W_ERROR);
         END;



         BEGIN
            SP_UPDATE_DEAL_ED_DETAILS;
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE_APPLICATION_ERROR (
                  -20100,
                  'ERROR IN UPDATE DEAL_ED_DETAILS ' || SQLERRM);
         END;
      END IF;
   END ED_ADJUSTMENT_RENEW_MAT;



   PROCEDURE GEN_TRAN_DATA_FOR_ISSUE
   IS
      V_SQL              VARCHAR2 (2000);
      V_TO_GL_DR_CR      VARCHAR2 (1);
      V_PREVIOUS_BATCH   VARCHAR2 (7) := 0;
   BEGIN
      V_SQL :=
            'SELECT  TRAN_BATCH_NUMBER,
                     TRAN_DB_CR_FLG,
                     TRAN_CURR_CODE,
                     TRAN_AMOUNT,
                     TRAN_BASE_CURR_EQ_AMT,
                     TRAN_NARR_DTL1,
                     TRAN_NARR_DTL2,
                     TRAN_NARR_DTL3,
                     (SELECT TRANBAT_NARR_DTL1 || TRANBAT_NARR_DTL2 || TRANBAT_NARR_DTL3
                        FROM TRANBAT'
         || V_FIN_YEAR
         || '
                       WHERE     TRANBAT_ENTITY_NUM = TRAN_ENTITY_NUM
                             AND TRANBAT_BRN_CODE = TRAN_BRN_CODE
                             AND TRANBAT_DATE_OF_TRAN = TRAN_DATE_OF_TRAN
                             AND TRANBAT_BATCH_NUMBER = TRAN_BATCH_NUMBER)
                        TRANBAT_NARR_DTL
                FROM TRAN'
         || V_FIN_YEAR
         || '
               WHERE     TRAN_ENTITY_NUM = :1
                     AND TRAN_BRN_CODE = :BRN_CODE
                     AND TRAN_DATE_OF_TRAN = :W_CURRENT_DATE
                     AND TRAN_GLACC_CODE = :V_FROM_GL
                     AND TRAN_AMOUNT <> 0
                     AND TRAN_NARR_DTL3 = ''ISSUE''
                     AND TRAN_AUTH_BY IS NOT NULL
            ORDER BY TRAN_BRN_CODE, TRAN_DATE_OF_TRAN, TRAN_BATCH_NUMBER';

      EXECUTE IMMEDIATE V_SQL
         BULK COLLECT INTO T_TRAN
         USING V_ENTITY_NUM,
               V_BRN_CODE,
               W_CURRENT_DATE,
               V_FROM_GL;


      FOR IDX IN 1 .. T_TRAN.COUNT
      LOOP
         IF IDX <> 1 AND V_PREVIOUS_BATCH <> T_TRAN (IDX).TRAN_BATCH_NUMBER
         THEN
            BEGIN
               SET_TRAN_KEY_VALUES (V_BRN_CODE);
               SET_TRANBAT_VALUES (V_BRN_CODE, V_TRANBAT_NARR);

               AUTOPOST_ENTRIES;

               W_POST_ARRAY_INDEX := 0;
               IDX1 := 0;
               PKG_AUTOPOST.PV_TRAN_REC.DELETE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  RAISE_APPLICATION_ERROR (-20100,
                                           'ERROR AUTOPOST ' || W_ERROR);
            END;
         END IF;

         V_NUMBER_OF_TRAN := 0;
         V_TRANBAT_NARR := T_TRAN (IDX).TRANBAT_NARR_DTL;

         IF T_TRAN (IDX).TRAN_DB_CR_FLG = 'C'
         THEN
            V_TO_GL_DR_CR := 'D';
         ELSE
            V_TO_GL_DR_CR := 'C';
         END IF;

         MOVE_TO_TRANREC_GL (V_BRN_CODE,
                             V_TO_GL_DR_CR,
                             V_FROM_GL,
                             T_TRAN (IDX).TRAN_AMOUNT,
                             T_TRAN (IDX).TRAN_BASE_CURR_EQ_AMT,
                             T_TRAN (IDX).TRAN_CURR_CODE,
                             T_TRAN (IDX).TRAN_NARR_DTL1,
                             T_TRAN (IDX).TRAN_NARR_DTL2,
                             T_TRAN (IDX).TRAN_NARR_DTL3);

         MOVE_TO_TRANREC_GL (V_BRN_CODE,
                             T_TRAN (IDX).TRAN_DB_CR_FLG,
                             V_TO_GL,
                             T_TRAN (IDX).TRAN_AMOUNT,
                             T_TRAN (IDX).TRAN_BASE_CURR_EQ_AMT,
                             T_TRAN (IDX).TRAN_CURR_CODE,
                             T_TRAN (IDX).TRAN_NARR_DTL1,
                             T_TRAN (IDX).TRAN_NARR_DTL2,
                             T_TRAN (IDX).TRAN_NARR_DTL3);
         V_PREVIOUS_BATCH := T_TRAN (IDX).TRAN_BATCH_NUMBER;
      END LOOP;

      IF T_TRAN.COUNT > 0
      THEN
         BEGIN
            SET_TRAN_KEY_VALUES (V_BRN_CODE);
            SET_TRANBAT_VALUES (V_BRN_CODE, V_TRANBAT_NARR);

            AUTOPOST_ENTRIES;

            W_POST_ARRAY_INDEX := 0;
            IDX1 := 0;
            PKG_AUTOPOST.PV_TRAN_REC.DELETE;
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE_APPLICATION_ERROR (-20100, 'ERROR AUTOPOST ' || W_ERROR);
         END;
      END IF;

      T_TRAN.DELETE;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN GEN_TRAN_DATA_FOR_ISSUE '
            || '-'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END GEN_TRAN_DATA_FOR_ISSUE;



   PROCEDURE GEN_TRAN_DATA_FOR_MAT_CLOSURE
   IS
      V_SQL                      VARCHAR2 (2000);
      V_TO_GL_DR_CR              VARCHAR2 (1);

      V_TO_GL_ACTION             VARCHAR2 (1);

      V_PREVIOUS_NARR_DTL2       VARCHAR2 (35) := NULL;

      V_CONSOLIDATED_AC_AMOUNT   NUMBER (18, 3) := 0;
      V_CONSOLIDATED_BC_AMOUNT   NUMBER (18, 3) := 0;

      --V_EXCISEDUTY_AMT           NUMBER (18, 3);
      --V_CONSOLIDATED_ED_AMT      NUMBER (18, 3);

      --V_GL_DRCR_FOR_ED           VARCHAR2 (1);
      --V_GL_AMT_FOR_ED            NUMBER (18, 3);
      V_BATCH_NUM                NUMBER;

      V_TRAN_CURR                VARCHAR2 (3);
      V_TRAN_NARR1               VARCHAR2 (35);
      V_TRAN_NARR2               VARCHAR2 (35);
      V_TRAN_NARR3               VARCHAR2 (35);
   BEGIN
      V_SQL :=
            'SELECT TRAN_BATCH_NUMBER,
         TRAN_DB_CR_FLG,
         TRAN_CURR_CODE,
         SUM (TRAN_AMOUNT) TRAN_AMOUNT,
         SUM (TRAN_BASE_CURR_EQ_AMT) TRAN_BASE_CURR_EQ_AMT,
         TRAN_NARR_DTL1,
         TRAN_NARR_DTL2,
         TRAN_NARR_DTL3,
         TRANBAT_NARR_DTL
    FROM (SELECT TRAN_BATCH_NUMBER,
                 TRAN_DB_CR_FLG,
                 TRAN_CURR_CODE,
                 TRAN_AMOUNT,
                 TRAN_BASE_CURR_EQ_AMT,
                 TRAN_NARR_DTL1,
                 TRAN_NARR_DTL2,
                 TRAN_NARR_DTL3,
                 (SELECT    TRANBAT_NARR_DTL1
                         || TRANBAT_NARR_DTL2
                         || TRANBAT_NARR_DTL3
                    FROM TRANBAT'
         || V_FIN_YEAR
         || '
                   WHERE     TRANBAT_ENTITY_NUM = TRAN_ENTITY_NUM
                         AND TRANBAT_BRN_CODE = TRAN_BRN_CODE
                         AND TRANBAT_DATE_OF_TRAN = TRAN_DATE_OF_TRAN
                         AND TRANBAT_BATCH_NUMBER = TRAN_BATCH_NUMBER)
                    TRANBAT_NARR_DTL
            FROM TRAN'
         || V_FIN_YEAR
         || '
           WHERE     TRAN_ENTITY_NUM = :1
                 AND TRAN_BRN_CODE = :BRN_CODE
                 AND TRAN_DATE_OF_TRAN = :W_CURRENT_DATE
                 AND TRAN_GLACC_CODE = :V_FROM_GL
                 AND TRAN_AMOUNT <> 0
                 AND TRAN_NARR_DTL3 = ''CLOSER_MATURITY''
                 AND TRAN_AUTH_BY IS NOT NULL)
GROUP BY TRAN_BATCH_NUMBER, TRAN_DB_CR_FLG, TRAN_CURR_CODE, TRAN_NARR_DTL1, TRAN_NARR_DTL2, TRAN_NARR_DTL3, TRANBAT_NARR_DTL
ORDER BY TRAN_NARR_DTL2 ASC, TRAN_BATCH_NUMBER DESC';

      EXECUTE IMMEDIATE V_SQL
         BULK COLLECT INTO T_TRAN
         USING V_ENTITY_NUM,
               V_BRN_CODE,
               W_CURRENT_DATE,
               V_FROM_GL;


      FOR IDX IN 1 .. T_TRAN.COUNT
      LOOP
         IF IDX <> 1 AND V_PREVIOUS_NARR_DTL2 <> T_TRAN (IDX).TRAN_NARR_DTL2
         THEN
            BEGIN
               IF V_CONSOLIDATED_AC_AMOUNT > 0
               THEN
                  V_TO_GL_ACTION := 'C';
               ELSIF V_CONSOLIDATED_AC_AMOUNT < 0
               THEN
                  V_TO_GL_ACTION := 'D';
               END IF;


-- ED Settlement already done in ED_ADJUSTMENT_MAT_CLOSURE
/*
               V_SQL :=
                     'SELECT TRAN_DB_CR_FLG, TRAN_AMOUNT
                          FROM TRAN'
                  || V_FIN_YEAR
                  || '
                         WHERE     TRAN_ENTITY_NUM = :1
                               AND TRAN_BRN_CODE = :BRN_CODE
                               AND TRAN_DATE_OF_TRAN = :W_CURRENT_DATE
                               AND TRAN_BATCH_NUMBER = :BATCH_NUMBER
                               AND TRAN_GLACC_CODE IN
                               ( '''
                  || V_GL_BORROW_NBFI
                  || ''', '''
                  || V_GL_BORROW_BANK
                  || ''', '''
                  || V_GL_LANDING_NBFI
                  || ''', '''
                  || V_GL_LANDING_BANK
                  || ''')';

               EXECUTE IMMEDIATE V_SQL
                  INTO V_GL_DRCR_FOR_ED, V_GL_AMT_FOR_ED
                  USING V_ENTITY_NUM,
                        V_BRN_CODE,
                        W_CURRENT_DATE,
                        T_TRAN (IDX - 1).TRAN_BATCH_NUMBER;


               V_EXCISEDUTY_AMT :=
                  NVL (FN_GET_EXCIES_DUTYAMOUNT (V_GL_AMT_FOR_ED), 0);
*/

               IF V_CONSOLIDATED_AC_AMOUNT <> 0
               THEN
                  MOVE_TO_TRANREC_GL (
                     V_BRN_CODE,
                     V_TO_GL_ACTION,
                     V_TO_GL,
                     ABS (V_CONSOLIDATED_AC_AMOUNT) , ---   - V_EXCISEDUTY_AMT,
                     ABS (V_CONSOLIDATED_BC_AMOUNT) , ---   - V_EXCISEDUTY_AMT,
                     T_TRAN (IDX - 1).TRAN_CURR_CODE,
                     T_TRAN (IDX - 1).TRAN_NARR_DTL1,
                     T_TRAN (IDX - 1).TRAN_NARR_DTL2,
                     T_TRAN (IDX - 1).TRAN_NARR_DTL3);

-- ED Settlement already done in ED_ADJUSTMENT_MAT_CLOSURE
/*
                  IF V_GL_DRCR_FOR_ED = 'D'
                  THEN
                     MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                         V_TO_GL_ACTION,
                                         V_GL_FOR_DEBIT_ENTRY,
                                         V_EXCISEDUTY_AMT,
                                         V_EXCISEDUTY_AMT,
                                         T_TRAN (IDX - 1).TRAN_CURR_CODE,
                                         T_TRAN (IDX - 1).TRAN_NARR_DTL1,
                                         T_TRAN (IDX - 1).TRAN_NARR_DTL2,
                                         T_TRAN (IDX - 1).TRAN_NARR_DTL3);
                  ELSE
                     MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                         V_TO_GL_ACTION,
                                         V_GL_FOR_CREDIT_ENTRY,
                                         V_EXCISEDUTY_AMT,
                                         V_EXCISEDUTY_AMT,
                                         T_TRAN (IDX - 1).TRAN_CURR_CODE,
                                         T_TRAN (IDX - 1).TRAN_NARR_DTL1,
                                         T_TRAN (IDX - 1).TRAN_NARR_DTL2,
                                         T_TRAN (IDX - 1).TRAN_NARR_DTL3);
                  END IF;
                  */
               END IF;

               SET_TRAN_KEY_VALUES (V_BRN_CODE);
               SET_TRANBAT_VALUES (V_BRN_CODE, V_TRANBAT_NARR);

               AUTOPOST_ENTRIES;

               W_POST_ARRAY_INDEX := 0;
               IDX1 := 0;

               PKG_AUTOPOST.PV_TRAN_REC.DELETE;

               V_CONSOLIDATED_AC_AMOUNT := 0;
               V_CONSOLIDATED_BC_AMOUNT := 0;
            EXCEPTION
               WHEN OTHERS
               THEN
                  RAISE_APPLICATION_ERROR (-20100,
                                           'ERROR AUTOPOST ' || W_ERROR);
            END;
         END IF;

         V_TRANBAT_NARR := T_TRAN (IDX).TRANBAT_NARR_DTL;



         IF T_TRAN (IDX).TRAN_DB_CR_FLG = 'C'
         THEN
            V_TO_GL_DR_CR := 'D';
            V_CONSOLIDATED_AC_AMOUNT :=
               V_CONSOLIDATED_AC_AMOUNT + T_TRAN (IDX).TRAN_AMOUNT;
            V_CONSOLIDATED_BC_AMOUNT :=
               V_CONSOLIDATED_BC_AMOUNT + T_TRAN (IDX).TRAN_BASE_CURR_EQ_AMT;
         --V_CONSOLIDATED_ED_AMT := V_CONSOLIDATED_ED_AMT + V_EXCISEDUTY_AMT;
         ELSE
            V_TO_GL_DR_CR := 'C';
            V_CONSOLIDATED_AC_AMOUNT :=
               V_CONSOLIDATED_AC_AMOUNT - T_TRAN (IDX).TRAN_AMOUNT;
            V_CONSOLIDATED_BC_AMOUNT :=
               V_CONSOLIDATED_BC_AMOUNT - T_TRAN (IDX).TRAN_BASE_CURR_EQ_AMT;
         --V_CONSOLIDATED_ED_AMT := V_CONSOLIDATED_ED_AMT - V_EXCISEDUTY_AMT;
         END IF;


         MOVE_TO_TRANREC_GL (V_BRN_CODE,
                             V_TO_GL_DR_CR,
                             V_FROM_GL,
                             T_TRAN (IDX).TRAN_AMOUNT,
                             T_TRAN (IDX).TRAN_BASE_CURR_EQ_AMT,
                             T_TRAN (IDX).TRAN_CURR_CODE,
                             T_TRAN (IDX).TRAN_NARR_DTL1,
                             T_TRAN (IDX).TRAN_NARR_DTL2,
                             T_TRAN (IDX).TRAN_NARR_DTL3);


         V_PREVIOUS_NARR_DTL2 := T_TRAN (IDX).TRAN_NARR_DTL2;


         V_BATCH_NUM := T_TRAN (IDX).TRAN_BATCH_NUMBER;
         V_TRAN_CURR := T_TRAN (IDX).TRAN_CURR_CODE;
         V_TRAN_NARR1 := T_TRAN (IDX).TRAN_NARR_DTL1;
         V_TRAN_NARR2 := T_TRAN (IDX).TRAN_NARR_DTL2;
         V_TRAN_NARR3 := T_TRAN (IDX).TRAN_NARR_DTL3;
      END LOOP;



      IF T_TRAN.COUNT > 0
      THEN
         BEGIN
            IF V_CONSOLIDATED_AC_AMOUNT > 0
            THEN
               V_TO_GL_ACTION := 'C';
            ELSIF V_CONSOLIDATED_AC_AMOUNT < 0
            THEN
               V_TO_GL_ACTION := 'D';
            END IF;


-- ED Settlement already done in ED_ADJUSTMENT_MAT_CLOSURE
/*
            V_SQL :=
                  'SELECT TRAN_DB_CR_FLG, TRAN_AMOUNT
                          FROM TRAN'
               || V_FIN_YEAR
               || '
                         WHERE     TRAN_ENTITY_NUM = :1
                               AND TRAN_BRN_CODE = :BRN_CODE
                               AND TRAN_DATE_OF_TRAN = :W_CURRENT_DATE
                               AND TRAN_BATCH_NUMBER = :BATCH_NUMBER
                               AND TRAN_GLACC_CODE IN
                               ( '''
               || V_GL_BORROW_NBFI
               || ''', '''
               || V_GL_BORROW_BANK
               || ''', '''
               || V_GL_LANDING_NBFI
               || ''', '''
               || V_GL_LANDING_BANK
               || ''')';

            EXECUTE IMMEDIATE V_SQL
               INTO V_GL_DRCR_FOR_ED, V_GL_AMT_FOR_ED
               USING V_ENTITY_NUM,
                     V_BRN_CODE,
                     W_CURRENT_DATE,
                     V_BATCH_NUM;


            V_EXCISEDUTY_AMT := FN_GET_EXCIES_DUTYAMOUNT (V_GL_AMT_FOR_ED);

*/

            IF V_CONSOLIDATED_AC_AMOUNT <> 0
            THEN
               MOVE_TO_TRANREC_GL (
                  V_BRN_CODE,
                  V_TO_GL_ACTION,
                  V_TO_GL,
                  ABS (V_CONSOLIDATED_AC_AMOUNT) , ---   - V_EXCISEDUTY_AMT,
                  ABS (V_CONSOLIDATED_BC_AMOUNT) , ---   - V_EXCISEDUTY_AMT,
                  V_TRAN_CURR,
                  V_TRAN_NARR1,
                  V_TRAN_NARR2,
                  V_TRAN_NARR3);

-- ED Settlement already done in ED_ADJUSTMENT_MAT_CLOSURE
/*
               IF V_GL_DRCR_FOR_ED = 'D'
               THEN
                  MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                      V_TO_GL_ACTION,
                                      V_GL_FOR_DEBIT_ENTRY,
                                      V_EXCISEDUTY_AMT,
                                      V_EXCISEDUTY_AMT,
                                      V_TRAN_CURR,
                                      V_TRAN_NARR1,
                                      V_TRAN_NARR2,
                                      V_TRAN_NARR3);
               ELSE
                  MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                      V_TO_GL_ACTION,
                                      V_GL_FOR_CREDIT_ENTRY,
                                      V_EXCISEDUTY_AMT,
                                      V_EXCISEDUTY_AMT,
                                      V_TRAN_CURR,
                                      V_TRAN_NARR1,
                                      V_TRAN_NARR2,
                                      V_TRAN_NARR3);
               END IF;
               */
            END IF;



            SET_TRAN_KEY_VALUES (V_BRN_CODE);
            SET_TRANBAT_VALUES (V_BRN_CODE, V_TRANBAT_NARR);

            AUTOPOST_ENTRIES;

            W_POST_ARRAY_INDEX := 0;
            IDX1 := 0;
            PKG_AUTOPOST.PV_TRAN_REC.DELETE;
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE_APPLICATION_ERROR (-20100, 'ERROR AUTOPOST ' || W_ERROR);
         END;
      END IF;

      T_TRAN.DELETE;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN GEN_TRAN_DATA_FOR_MAT_CLOSURE '
            || '-'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END GEN_TRAN_DATA_FOR_MAT_CLOSURE;

   PROCEDURE GEN_TRAN_DATA_FOR_RENEW_MAT
   IS
      V_SQL                      VARCHAR2 (2000);
      V_TO_GL_DR_CR              VARCHAR2 (1);
      V_TO_GL_ACTION             VARCHAR2 (1);
      V_PREVIOUS_REF             VARCHAR2 (35);
      V_CONSOLIDATED_AC_AMOUNT   NUMBER (18, 3) := 0;
      V_CONSOLIDATED_BC_AMOUNT   NUMBER (18, 3) := 0;
      V_TRAN_CURR                VARCHAR2 (3);
      V_TRAN_NARR1               VARCHAR2 (35);
      V_TRAN_NARR2               VARCHAR2 (35);
      V_TRAN_NARR3               VARCHAR2 (35);
   BEGIN
      V_SQL :=
            'SELECT  TRAN_BATCH_NUMBER,
                     TRAN_DB_CR_FLG,
                     TRAN_CURR_CODE,
                     TRAN_AMOUNT,
                     TRAN_BASE_CURR_EQ_AMT,
                     TRAN_NARR_DTL1,
                     TRAN_NARR_DTL2,
                     TRAN_NARR_DTL3,
                     (SELECT TRANBAT_NARR_DTL1 || TRANBAT_NARR_DTL2 || TRANBAT_NARR_DTL3
                        FROM TRANBAT'
         || V_FIN_YEAR
         || '
                       WHERE     TRANBAT_ENTITY_NUM = TRAN_ENTITY_NUM
                             AND TRANBAT_BRN_CODE = TRAN_BRN_CODE
                             AND TRANBAT_DATE_OF_TRAN = TRAN_DATE_OF_TRAN
                             AND TRANBAT_BATCH_NUMBER = TRAN_BATCH_NUMBER)
                        TRANBAT_NARR_DTL
                FROM TRAN'
         || V_FIN_YEAR
         || '
               WHERE     TRAN_ENTITY_NUM = :1
                     AND TRAN_BRN_CODE = :BRN_CODE
                     AND TRAN_DATE_OF_TRAN = :W_CURRENT_DATE
                     AND TRAN_GLACC_CODE = :V_FROM_GL
                     AND TRAN_AMOUNT <> 0
                     AND TRAN_NARR_DTL3 IN (''REISSUE'',''ROLLOVER_MATURITY'')
                     AND TRAN_AUTH_BY IS NOT NULL
            ORDER BY TRAN_BRN_CODE, TRAN_DATE_OF_TRAN, TRAN_NARR_DTL2';

      EXECUTE IMMEDIATE V_SQL
         BULK COLLECT INTO T_TRAN
         USING V_ENTITY_NUM,
               V_BRN_CODE,
               W_CURRENT_DATE,
               V_FROM_GL;

      FOR IDX IN 1 .. T_TRAN.COUNT
      LOOP
         IF IDX <> 1 AND V_PREVIOUS_REF <> T_TRAN (IDX).TRAN_NARR_DTL2
         THEN
            BEGIN
               IF V_CONSOLIDATED_AC_AMOUNT > 0
               THEN
                  V_TO_GL_ACTION := 'C';
               ELSIF V_CONSOLIDATED_AC_AMOUNT < 0
               THEN
                  V_TO_GL_ACTION := 'D';
               END IF;

               MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                   V_TO_GL_ACTION,
                                   V_TO_GL,
                                   ABS (V_CONSOLIDATED_AC_AMOUNT),
                                   ABS (V_CONSOLIDATED_BC_AMOUNT),
                                   T_TRAN (IDX).TRAN_CURR_CODE,
                                   T_TRAN (IDX).TRAN_NARR_DTL1,
                                   T_TRAN (IDX).TRAN_NARR_DTL2,
                                   T_TRAN (IDX).TRAN_NARR_DTL3);



               SET_TRAN_KEY_VALUES (V_BRN_CODE);
               SET_TRANBAT_VALUES (V_BRN_CODE, V_TRANBAT_NARR);

               AUTOPOST_ENTRIES;

               W_POST_ARRAY_INDEX := 0;
               IDX1 := 0;
               PKG_AUTOPOST.PV_TRAN_REC.DELETE;
               V_CONSOLIDATED_AC_AMOUNT := 0;
               V_CONSOLIDATED_BC_AMOUNT := 0;
            EXCEPTION
               WHEN OTHERS
               THEN
                  RAISE_APPLICATION_ERROR (-20100,
                                           'ERROR AUTOPOST ' || W_ERROR);
            END;
         END IF;

         V_NUMBER_OF_TRAN := 0;
         V_TRANBAT_NARR := T_TRAN (IDX).TRANBAT_NARR_DTL;

         IF T_TRAN (IDX).TRAN_DB_CR_FLG = 'C'
         THEN
            V_TO_GL_DR_CR := 'D';
            V_CONSOLIDATED_AC_AMOUNT :=
               V_CONSOLIDATED_AC_AMOUNT + T_TRAN (IDX).TRAN_AMOUNT;
            V_CONSOLIDATED_BC_AMOUNT :=
               V_CONSOLIDATED_BC_AMOUNT + T_TRAN (IDX).TRAN_BASE_CURR_EQ_AMT;
         ELSE
            V_TO_GL_DR_CR := 'C';
            V_CONSOLIDATED_AC_AMOUNT :=
               V_CONSOLIDATED_AC_AMOUNT - T_TRAN (IDX).TRAN_AMOUNT;
            V_CONSOLIDATED_BC_AMOUNT :=
               V_CONSOLIDATED_BC_AMOUNT - T_TRAN (IDX).TRAN_BASE_CURR_EQ_AMT;
         END IF;

         MOVE_TO_TRANREC_GL (V_BRN_CODE,
                             V_TO_GL_DR_CR,
                             V_FROM_GL,
                             T_TRAN (IDX).TRAN_AMOUNT,
                             T_TRAN (IDX).TRAN_BASE_CURR_EQ_AMT,
                             T_TRAN (IDX).TRAN_CURR_CODE,
                             T_TRAN (IDX).TRAN_NARR_DTL1,
                             T_TRAN (IDX).TRAN_NARR_DTL2,
                             T_TRAN (IDX).TRAN_NARR_DTL3);



         V_PREVIOUS_REF := T_TRAN (IDX).TRAN_NARR_DTL2;
         V_TRAN_CURR := T_TRAN (IDX).TRAN_CURR_CODE;
         V_TRAN_NARR1 := T_TRAN (IDX).TRAN_NARR_DTL1;
         V_TRAN_NARR2 := T_TRAN (IDX).TRAN_NARR_DTL2;
         V_TRAN_NARR3 := T_TRAN (IDX).TRAN_NARR_DTL3;
      END LOOP;



      IF T_TRAN.COUNT > 0
      THEN
         BEGIN
            IF V_CONSOLIDATED_AC_AMOUNT > 0
            THEN
               V_TO_GL_ACTION := 'C';
            ELSIF V_CONSOLIDATED_AC_AMOUNT < 0
            THEN
               V_TO_GL_ACTION := 'D';
            END IF;

            MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                V_TO_GL_ACTION,
                                V_TO_GL,
                                ABS (V_CONSOLIDATED_AC_AMOUNT),
                                ABS (V_CONSOLIDATED_BC_AMOUNT),
                                V_TRAN_CURR,
                                V_TRAN_NARR1,
                                V_TRAN_NARR2,
                                V_TRAN_NARR3);



            SET_TRAN_KEY_VALUES (V_BRN_CODE);
            SET_TRANBAT_VALUES (V_BRN_CODE, V_TRANBAT_NARR);

            AUTOPOST_ENTRIES;

            W_POST_ARRAY_INDEX := 0;
            IDX1 := 0;
            PKG_AUTOPOST.PV_TRAN_REC.DELETE;
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE_APPLICATION_ERROR (-20100, 'ERROR AUTOPOST ' || W_ERROR);
         END;
      END IF;



      T_TRAN.DELETE;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN GEN_TRAN_DATA_FOR_RENEW_MAT '
            || '-'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END GEN_TRAN_DATA_FOR_RENEW_MAT;



   PROCEDURE SP_BAL_TRANSFER (P_ENTITY_NUM IN NUMBER)
   IS
   BEGIN
      V_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;
      V_ENTITY_NUM := P_ENTITY_NUM;
      --V_BRN_CODE := 99;
      W_CURRENT_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      V_FIN_YEAR := TO_CHAR (W_CURRENT_DATE, 'YYYY');
      SELECT TO_NUMBER (I.PARAMETER_VALUE)
        INTO V_BRN_CODE
        FROM TB_INTERNAL_INFO I
       WHERE I.PARAMETER_NAME = 'HOST_BRN_CODE';

      INITILIZE_TRANSACTION;

      SELECT FROM_GL,
             TO_GL,
             EDGL_FOR_DEBIT,
             EDGL_FOR_CREDIT,
             BORROW_NBFI,
             BORROW_BANK,
             LANDING_NBFI,
             LANDING_BANK
        INTO V_FROM_GL,
             V_TO_GL,
             V_GL_FOR_DEBIT_ENTRY,
             V_GL_FOR_CREDIT_ENTRY,
             V_GL_BORROW_NBFI,
             V_GL_BORROW_BANK,
             V_GL_LANDING_NBFI,
             V_GL_LANDING_BANK
        FROM BALTRFGLMAPPING;

      IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (P_ENTITY_NUM,
                                                      V_BRN_CODE) = FALSE
      THEN

         ED_ADJUSTMENT_MAT_CLOSURE ;
         ED_ADJUSTMENT_RENEW_MAT ;

         GEN_TRAN_DATA_FOR_ISSUE;
         GEN_TRAN_DATA_FOR_RENEW_MAT;
         GEN_TRAN_DATA_FOR_MAT_CLOSURE;


         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;

         IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
         THEN
            PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (P_ENTITY_NUM,
                                                             V_BRN_CODE);
         END IF;

         PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (P_ENTITY_NUM);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (W_ERROR) IS NULL
         THEN
            W_ERROR :=
               SUBSTR ('Error in SP_BAL_TRANSFER ' || SQLERRM, 1, 1000);
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (P_ENTITY_NUM,
                                      'E',
                                      PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                      ' ',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (P_ENTITY_NUM,
                                      'E',
                                      SUBSTR (SQLERRM, 1, 1000),
                                      ' ',
                                      0);
   END SP_BAL_TRANSFER;
END PKG_TREASURY_BAL_TRF;
/
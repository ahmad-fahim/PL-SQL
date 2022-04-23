CREATE OR REPLACE PACKAGE PKG_DEAL_ED_DEDUCTION  is

   procedure SP_ED_DEDUCTION (V_ENTITY_NUM IN NUMBER) ;
   
  end PKG_DEAL_ED_DEDUCTION ;
/

CREATE OR REPLACE PACKAGE BODY PKG_DEAL_ED_DEDUCTION
IS
   V_SQL                   VARCHAR2 (3000);
   V_CBD                   DATE;
   V_BRN_CODE              NUMBER;
   V_GLOB_ENTITY_NUM       NUMBER;


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


   TYPE DEAL_DATA IS RECORD
   (
      T_PROD_NAME   TB_PRODUCT.PROD_NAME%TYPE,
      T_REF_NUM     TB_MMBACKOFFICE.REF_NUM%TYPE,
      T_AMOUNT      TB_MMBACKOFFICE.AMOUNT%TYPE
   );

   TYPE TT_DEAL_DATA IS TABLE OF DEAL_DATA
      INDEX BY PLS_INTEGER;

   T_DEAL_DATA             TT_DEAL_DATA;



   V_NUMBER_OF_TRAN        NUMBER;
   W_ERR_CODE              VARCHAR2 (300);
   W_ERROR                 VARCHAR2 (3000);
   W_BATCH_NUM             NUMBER;
   V_USER_EXCEPTION        EXCEPTION;
   W_POST_ARRAY_INDEX      NUMBER (14) DEFAULT 0;
   V_USER_ID               VARCHAR2 (8);



   PROCEDURE POST_TRANSACTION
   IS
   BEGIN
      --PKG_PB_AUTOPOST.G_FORM_NAME := 'AUTORENEWAL';
      PKG_PB_AUTOPOST.G_FORM_NAME := 'ETRAN';

      -- Calling AUTOPOST --
      PKG_POST_INTERFACE.SP_AUTOPOSTTRAN ('1',                 --Entity Number
                                          'A',                     --User Mode
                                          V_NUMBER_OF_TRAN, --No of transactions
                                          0,
                                          0,
                                          0,
                                          0,
                                          'N',
                                          W_ERR_CODE,
                                          W_ERROR,
                                          W_BATCH_NUM);

      DBMS_OUTPUT.PUT_LINE (
         W_ERR_CODE || ' >> ' || W_ERROR || ' >> ' || W_BATCH_NUM);

      IF (W_ERR_CODE <> '0000')
      THEN
         W_ERROR :=
            'ERROR IN POST_TRANSACTION ' || FN_GET_AUTOPOST_ERR_MSG (1);
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
   END AUTOPOST_ENTRIES;

   PROCEDURE SET_TRAN_KEY_VALUES
   IS
   BEGIN
      PKG_AUTOPOST.PV_SYSTEM_POSTED_TRANSACTION := TRUE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := V_BRN_CODE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := V_CBD;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN SET_TRAN_KEY_VALUES '
            || '-'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END SET_TRAN_KEY_VALUES;

   PROCEDURE SET_TRANBAT_VALUES
   IS
   BEGIN
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'TRAN';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY := V_BRN_CODE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 := 'Revaluation Process';
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN SET_TRANBAT_VALUES '
            || V_BRN_CODE
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END SET_TRANBAT_VALUES;

   PROCEDURE INITILIZE_TRANSACTION
   IS
   BEGIN
      PKG_AUTOPOST.PV_USERID := V_USER_ID;
      PKG_AUTOPOST.PV_BOPAUTHQ_REQ := FALSE;
      PKG_AUTOPOST.PV_AUTH_DTLS_UPDATE_REQ := FALSE;
      PKG_AUTOPOST.PV_CALLED_BY_EOD_SOD := 0;
      PKG_AUTOPOST.PV_EXCEP_CHECK_NOT_REQD := FALSE;
      PKG_AUTOPOST.PV_OVERDRAFT_CHK_REQD := FALSE;
      PKG_AUTOPOST.PV_ALLOW_ZERO_TRANAMT := FALSE;
      PKG_PROCESS_BOPAUTHQ.V_BOPAUTHQ_UPD := FALSE;
      PKG_AUTOPOST.PV_CANCEL_FLAG := FALSE;
      PKG_AUTOPOST.PV_POST_AS_UNAUTH_MOD := FALSE;
      PKG_AUTOPOST.PV_CLG_BATCH_CLOSURE := FALSE;
      PKG_AUTOPOST.PV_AUTHORIZED_RECORD_CANCEL := FALSE;
      PKG_AUTOPOST.PV_BACKDATED_TRAN_REQUIRED := 0;
      PKG_AUTOPOST.PV_CLG_REGN_POSTING := FALSE;
      PKG_AUTOPOST.PV_FRESH_BATCH_SL := FALSE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := V_BRN_CODE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := V_CBD;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;
      PKG_AUTOPOST.PV_AUTO_AUTHORISE := TRUE;
      --PKG_PB_GLOBAL.G_TERMINAL_ID := '10.10.7.149';
      PKG_POST_INTERFACE.G_BATCH_NUMBER_UPDATE_REQ := FALSE;
      PKG_POST_INTERFACE.G_SRC_TABLE_AUTH_REJ_REQ := FALSE;
      PKG_AUTOPOST.PV_TRAN_ONLY_UNDO := FALSE;
      PKG_AUTOPOST.PV_OCLG_POSTING_FLG := FALSE;
      PKG_POST_INTERFACE.G_IBR_REQUIRED := 0;
      -- PKG_PB_test.G_FORM_NAME                             := 'ETRAN';
      PKG_POST_INTERFACE.G_PGM_NAME := 'ETRAN';
      PKG_AUTOPOST.PV_USER_ROLE_CODE := '';
      PKG_AUTOPOST.PV_SUPP_TRAN_POST := FALSE;
      PKG_AUTOPOST.PV_FUTURE_TRANSACTION_ALLOWED := FALSE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_BRN_CODE := V_BRN_CODE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_DATE_OF_TRAN := V_CBD;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_BATCH_NUMBER := 0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_ENTRY_BRN_CODE := V_BRN_CODE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_WITHDRAW_SLIP := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_TOKEN_ISSUED := 0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_BACKOFF_SYS_CODE := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_DEVICE_CODE := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_DEVICE_UNIT_NUM := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_CHANNEL_DT_TIME := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_CHANNEL_UNIQ_NUM := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_COST_CNTR_CODE := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SUB_COST_CNTR := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_PROFIT_CNTR_CODE := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SUB_PROFIT_CNTR := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NUM_TRANS := V_NUMBER_OF_TRAN;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_BASE_CURR_TOT_CR := 0.0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_BASE_CURR_TOT_DB := 0.0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_CANCEL_BY := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_CANCEL_ON := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_CANCEL_REM1 := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_CANCEL_REM2 := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_CANCEL_REM3 := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'REVAL';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY :=
         V_BRN_CODE || V_CBD || '|0';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL2 := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL3 := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_AUTH_BY := V_USER_ID;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_AUTH_ON := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SHIFT_TO_TRAN_DATE := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SHIFT_TO_BAT_NUM := 0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SHIFT_FROM_TRAN_DATE := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SHIFT_FROM_BAT_NUM := 0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_REV_TO_TRAN_DATE := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_REV_TO_BAT_NUM := 0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_REV_FROM_TRAN_DATE := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_REV_FROM_BAT_NUM := 0;
   END INITILIZE_TRANSACTION;

   PROCEDURE MOVE_TO_TRANREC_GL (P_BRN_CODE       IN NUMBER,
                                 P_DEBIT_CREDIT      VARCHAR2,
                                 P_CREDIT_GL         VARCHAR2,
                                 P_TRAN_AC_AMT    IN NUMBER,
                                 P_TRAN_BC_AMT    IN NUMBER,
                                 P_CURRENCY       IN VARCHAR2,
                                 P_NARR1          IN VARCHAR2,
                                 P_NARR2          IN VARCHAR2,
                                 P_NARR3          IN VARCHAR2)
   IS
   BEGIN
      W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_BRN_CODE :=
         P_BRN_CODE;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN := V_CBD;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_GLACC_CODE :=
         P_CREDIT_GL;
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
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_VALUE_DATE := V_CBD;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL1 := P_NARR1;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL2 := P_NARR2;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL3 := P_NARR3;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN MOVE_TO_TRANREC'
            || '-'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END MOVE_TO_TRANREC_GL;



   PROCEDURE SP_UPDATE_DEAL_ED_DETAILS
   IS
   V_COUNT NUMBER := 0;
   BEGIN
      V_COUNT := T_DEAL_REF_NUM.COUNT ;
      
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
                 VALUES (V_GLOB_ENTITY_NUM,
                         T_DEAL_REF_NUM (M_INDEX),
                         T_PARENT_DEAL_REF_NUM (M_INDEX),
                         T_YEAR_END_ED_FLG (M_INDEX),
                         T_ED_ADJUSTMENT_FLG (M_INDEX),
                         T_ED_DEDUCTION_YEAR (M_INDEX),
                         T_ED_DEDUCTION_DATE (M_INDEX),
                         T_ED_DEDUCTION_AMOUNT (M_INDEX),
                         V_CBD,
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



   FUNCTION FN_GET_ED_AMOUNT (P_AMOUNT NUMBER)
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
   END FN_GET_ED_AMOUNT;


   PROCEDURE SP_ED_DEDUCTION (V_ENTITY_NUM IN NUMBER)
   IS
      V_ED_AMOUNT          NUMBER (18, 3);
      V_ED_PAYABLE_GL      DEAL_ED_DEDUC_GL.ED_PAYABLE_GL%TYPE;
      V_ED_RECEIVABLE_GL   DEAL_ED_DEDUC_GL.ED_RECEIVABLE_GL%TYPE;
      V_ED_PROVISION_GL    DEAL_ED_DEDUC_GL.ED_PROVISION_GL%TYPE;
      V_INDEX_NUMBER       NUMBER := 0;
   BEGIN
      V_NUMBER_OF_TRAN := 0;
      V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_ENTITY_NUM);
      V_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;
      V_GLOB_ENTITY_NUM := V_ENTITY_NUM;

      SELECT TO_NUMBER (I.PARAMETER_VALUE)
        INTO V_BRN_CODE
        FROM TB_INTERNAL_INFO I
       WHERE I.PARAMETER_NAME = 'HOST_BRN_CODE';


      SELECT ED_PAYABLE_GL, ED_RECEIVABLE_GL, ED_PROVISION_GL
        INTO V_ED_PAYABLE_GL, V_ED_RECEIVABLE_GL, V_ED_PROVISION_GL
        FROM DEAL_ED_DEDUC_GL;

      INITILIZE_TRANSACTION;

      V_SQL :=
         'SELECT PROD_NAME, REF_NUM, AMOUNT
                  FROM TB_MMBACKOFFICE, TB_PRODUCT
                 WHERE     TB_MMBACKOFFICE.PROD_TYPE = TB_PRODUCT.PROD_TYPE
                       AND TB_MMBACKOFFICE.PROD_CODE = TB_PRODUCT.PROD_CODE
                       AND :CBD BETWEEN MM_FROM_DATE AND MM_TO_DATE
                       AND BACK_CHECKER_ID IS NOT NULL
                       AND PURPOSE = ''BO AUTH''
                       AND PROD_NAME IN (''FDR LENDING'', ''FDR BORROWING'')   ';

      EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO T_DEAL_DATA USING V_CBD;


      FOR IDX IN T_DEAL_DATA.FIRST .. T_DEAL_DATA.LAST
      LOOP
         V_ED_AMOUNT := FN_GET_ED_AMOUNT (T_DEAL_DATA (IDX).T_AMOUNT);

         DBMS_OUTPUT.PUT_LINE (
               V_BRN_CODE
            || '  '
            || T_DEAL_DATA (IDX).T_PROD_NAME
            || '  '
            || T_DEAL_DATA (IDX).T_REF_NUM
            || '  '
            || T_DEAL_DATA (IDX).T_AMOUNT
            || '  '
            || V_ED_AMOUNT);


         IF T_DEAL_DATA (IDX).T_PROD_NAME = 'FDR LENDING'
         THEN
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                'D',
                                V_ED_PAYABLE_GL,
                                V_ED_AMOUNT,
                                V_ED_AMOUNT,
                                'BDT',
                                'ED Deduction for deal',
                                T_DEAL_DATA (IDX).T_REF_NUM,
                                FN_GET_PARENT_DEAL (T_DEAL_DATA (IDX).T_REF_NUM));
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                'C',
                                V_ED_PROVISION_GL,
                                V_ED_AMOUNT,
                                V_ED_AMOUNT,
                                'BDT',
                                'ED Deduction for deal',
                                T_DEAL_DATA (IDX).T_REF_NUM,
                                FN_GET_PARENT_DEAL (T_DEAL_DATA (IDX).T_REF_NUM));

            V_INDEX_NUMBER := V_INDEX_NUMBER + 1;

            T_DEAL_REF_NUM (V_INDEX_NUMBER) := T_DEAL_DATA (IDX).T_REF_NUM;
            T_PARENT_DEAL_REF_NUM (V_INDEX_NUMBER) :=
               FN_GET_PARENT_DEAL (T_DEAL_DATA (IDX).T_REF_NUM);
            T_YEAR_END_ED_FLG (V_INDEX_NUMBER) := '1';
            T_ED_ADJUSTMENT_FLG (V_INDEX_NUMBER) := '0';
            T_ED_DEDUCTION_YEAR (V_INDEX_NUMBER) :=
               TO_NUMBER (TO_CHAR (V_CBD, 'YYYY'));
            T_ED_DEDUCTION_DATE (V_INDEX_NUMBER) := V_CBD;
            T_ED_DEDUCTION_AMOUNT (V_INDEX_NUMBER) := V_ED_AMOUNT;
         ELSE
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                'C',
                                V_ED_RECEIVABLE_GL,
                                V_ED_AMOUNT,
                                V_ED_AMOUNT,
                                'BDT',
                                'ED Deduction for deal',
                                T_DEAL_DATA (IDX).T_REF_NUM,
                                FN_GET_PARENT_DEAL (T_DEAL_DATA (IDX).T_REF_NUM));
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (V_BRN_CODE,
                                'D',
                                V_ED_PROVISION_GL,
                                V_ED_AMOUNT,
                                V_ED_AMOUNT,
                                'BDT',
                                'ED Deduction for deal',
                                T_DEAL_DATA (IDX).T_REF_NUM,
                                FN_GET_PARENT_DEAL (T_DEAL_DATA (IDX).T_REF_NUM));

            V_INDEX_NUMBER := V_INDEX_NUMBER + 1;

            T_DEAL_REF_NUM (V_INDEX_NUMBER) := T_DEAL_DATA (IDX).T_REF_NUM;
            T_PARENT_DEAL_REF_NUM (V_INDEX_NUMBER) :=
               FN_GET_PARENT_DEAL (T_DEAL_DATA (IDX).T_REF_NUM);
            T_YEAR_END_ED_FLG (V_INDEX_NUMBER) := '1';
            T_ED_ADJUSTMENT_FLG (V_INDEX_NUMBER) := '0';
            T_ED_DEDUCTION_YEAR (V_INDEX_NUMBER) :=
               TO_NUMBER (TO_CHAR (V_CBD, 'YYYY'));
            T_ED_DEDUCTION_DATE (V_INDEX_NUMBER) := V_CBD;
            T_ED_DEDUCTION_AMOUNT (V_INDEX_NUMBER) := V_ED_AMOUNT;
         END IF;
      END LOOP;


      BEGIN
         SET_TRAN_KEY_VALUES;
         SET_TRANBAT_VALUES;

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
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (W_ERROR) IS NULL
         THEN
            W_ERROR := SUBSTR (SQLERRM, 1, 1000);
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;

         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_GLOB_ENTITY_NUM,
                                      'E',
                                      W_ERROR,
                                      ' ',
                                      0);
   END SP_ED_DEDUCTION;
END PKG_DEAL_ED_DEDUCTION;
/
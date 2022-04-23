CREATE OR REPLACE PACKAGE PKG_REVALUATION
IS
/*

Author : Fahim Ahmad
Created : 10/17/2016 4:19:11 PM
Purpose : Revaluation process for all account and GLs under foreign currency

*/
   PROCEDURE START_BRNWISE (
      P_ENTITY_NUM   IN ENTITYNUM.ENTITYNUM_NUMBER%TYPE,
      P_BRN_CODE     IN MBRN.MBRN_CODE%TYPE DEFAULT 0);

END;
/

CREATE OR REPLACE PACKAGE BODY PKG_REVALUATION
IS
   /*

   Author : Fahim Ahmad
   Created : 10/17/2016 4:19:11 PM
   Purpose : Revaluation process for all account and GLs under foreign currency

   */

   V_ASON_DATE          DATE;
   W_USER_ID            VARCHAR2 (8);
   L_BRN_CODE           NUMBER (6);
   V_NUMBER_OF_TRAN     NUMBER;
   W_POST_ARRAY_INDEX   NUMBER (14) DEFAULT 0;
   IDX1                 NUMBER DEFAULT 0;
   W_ERROR              VARCHAR2 (3000);
   W_ERR_CODE           VARCHAR2 (300);
   W_BATCH_NUM          NUMBER;
   W_ERROR_CODE         VARCHAR2 (10);
   V_USER_EXCEPTION     EXCEPTION;
   PKG_ERR_MSG          VARCHAR2 (2300);
   V_EXCHANGE_GL        EXTGL.EXTGL_ACCESS_CODE%TYPE;

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

      IF (W_ERROR_CODE <> '0000')
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
      IDX1 := 0;
   END AUTOPOST_ENTRIES;

   PROCEDURE SET_TRAN_KEY_VALUES
   IS
   BEGIN
      PKG_AUTOPOST.PV_SYSTEM_POSTED_TRANSACTION := TRUE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := L_BRN_CODE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := V_ASON_DATE;
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
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY := L_BRN_CODE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 := 'Revaluation Process';
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN SET_TRANBAT_VALUES '
            || L_BRN_CODE
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END SET_TRANBAT_VALUES;

   PROCEDURE GET_EXCHANGE_RATE (V_INPUT NUMBER, V_EXCHANGE_RATE OUT NUMBER)
   IS
      P_NEW_AMT   NUMBER;
   BEGIN
      SELECT DECODE (SIGN (LENGTH (TRUNC (V_INPUT)) - 5),
                     -1, 0,
                     LENGTH (TRUNC (V_INPUT)) - 5)
        INTO P_NEW_AMT
        FROM DUAL;

      V_EXCHANGE_RATE := POWER (10, P_NEW_AMT);
   END GET_EXCHANGE_RATE;

   PROCEDURE INITILIZE_TRANSACTION
   IS
   BEGIN
      PKG_AUTOPOST.pv_userid := W_USER_ID;
      PKG_AUTOPOST.PV_BOPAUTHQ_REQ := FALSE;
      PKG_AUTOPOST.PV_AUTH_DTLS_UPDATE_REQ := FALSE;
      PKG_AUTOPOST.PV_CALLED_BY_EOD_SOD := 0;
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
      PKG_AUTOPOST.pv_tran_key.Tran_Brn_Code := L_BRN_CODE;
      PKG_AUTOPOST.pv_tran_key.Tran_Date_Of_Tran := V_ASON_DATE;
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
      PKG_POST_INTERFACE.G_PGM_NAME := 'ETRAN';
      PKG_AUTOPOST.PV_USER_ROLE_CODE := '';
      PKG_AUTOPOST.PV_SUPP_TRAN_POST := FALSE;
      PKG_AUTOPOST.PV_FUTURE_TRANSACTION_ALLOWED := FALSE;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_BRN_CODE := L_BRN_CODE;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_DATE_OF_TRAN := V_ASON_DATE;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_BATCH_NUMBER := 0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_ENTRY_BRN_CODE := L_BRN_CODE;
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
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SOURCE_TABLE := 'REVAL';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SOURCE_KEY :=
         L_BRN_CODE || V_ASON_DATE || '|0';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_NARR_DTL1 := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_NARR_DTL2 := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_NARR_DTL3 := '';
      PKG_AUTOPOST.pv_tranbat.TRANBAT_AUTH_BY := W_USER_ID;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_AUTH_ON := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SHIFT_TO_TRAN_DATE := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SHIFT_TO_BAT_NUM := 0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SHIFT_FROM_TRAN_DATE := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_SHIFT_FROM_BAT_NUM := 0;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_REV_TO_TRAN_DATE := NULL;
      PKG_AUTOPOST.pv_tranbat.TRANBAT_REV_TO_BAT_NUM := 0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_REV_FROM_TRAN_DATE := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_REV_FROM_BAT_NUM := 0;
   END INITILIZE_TRANSACTION;


   PROCEDURE MOVE_TO_TRANREC_ACC (P_AC_NUM         IN NUMBER,
                                  P_DEBIT_CREDIT      VARCHAR2,
                                  P_CONT_NUM       IN NUMBER,
                                  P_TRAN_AC_AMT    IN NUMBER,
                                  P_TRAN_BC_AMT    IN NUMBER,
                                  P_CURRENCY       IN VARCHAR2,
                                  W_CURRENT_DATE   IN DATE,
                                  P_NARR1          IN VARCHAR2,
                                  P_NARR2          IN VARCHAR2,
                                  P_NARR3          IN VARCHAR2)
   IS
   BEGIN
      --DEBIT/CREDIT ACCOUNT

      W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN :=
         W_CURRENT_DATE;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_INTERNAL_ACNUM :=
         P_AC_NUM;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_CONTRACT_NUM :=
         P_CONT_NUM;
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
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN MOVE_TO_TRANREC_DEBIT '
            || '-'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END MOVE_TO_TRANREC_ACC;



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
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN :=
         V_ASON_DATE;
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
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_VALUE_DATE :=
         V_ASON_DATE;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL1 := P_NARR1;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL2 := P_NARR2;
      PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL3 := P_NARR3;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
               'ERROR IN MOVE_TO_TRANREC_CREDIT '
            || '-'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE V_USER_EXCEPTION;
   END MOVE_TO_TRANREC_GL;


   PROCEDURE SP_REVALUATION_ACCOUNT (P_ENTITY_CODE   IN NUMBER,
                                     P_BRN_CODE      IN NUMBER,
                                     P_EXCHANGE_GL   IN VARCHAR2)
   IS
      V_AC_NUM            ACNTS.ACNTS_INTERNAL_ACNUM%TYPE := 0;
      V_BASE_CURR         CURRENCY.CURR_CODE%TYPE;
      V_ENTITY_NUMBER     INSTALL.INS_ENTITY_NUM%TYPE := P_ENTITY_CODE;
      V_ACBAL             ACNTBAL.ACNTBAL_AC_BAL%TYPE;
      V_BCBAL             ACNTBAL.ACNTBAL_BC_BAL%TYPE;
      V_CBD               MAINCONT.MN_CURR_BUSINESS_DATE%TYPE;
      V_ERR_MSG           VARCHAR2 (1000);
      V_CONVERSION_RATE   TRAN2016.TRAN_BASE_CURR_CONV_RATE%TYPE;
      V_BCBAL_SHOULD_BE   ACNTBAL.ACNTBAL_AC_BAL%TYPE;
      V_BASE_CURR_EQUV    ACNTBAL.ACNTBAL_AC_BAL%TYPE;
      V_DR_CR_FLAG        TRAN2016.TRAN_DB_CR_FLG%TYPE;
      V_GAIN_LOSS         NUMBER (18, 3);
      P_NEW_AMT           NUMBER (18, 3);             ----ADDED IN 25-APR-2017
      P_EXCHANGE_VALUE    NUMBER := 0;                 ---ADDED IN 25-APR-2017
   BEGIN
      V_BASE_CURR := PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR (V_ENTITY_NUMBER);
      V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_ENTITY_NUMBER);

      W_POST_ARRAY_INDEX := 0;
      IDX1 := 0;
      V_NUMBER_OF_TRAN := 0;

      INITILIZE_TRANSACTION;


      FOR IDX
         IN (SELECT ACNTS_INTERNAL_ACNUM,
                    ACNTS_CURR_CODE,
                    ACNTS_BRN_CODE,
                    NVL (
                       (SELECT NVL (MAX (PBDCONT_CONT_NUM), 0)
                          FROM PBDCONTRACT
                         WHERE     PBDCONT_ENTITY_NUM = V_ENTITY_NUMBER
                               AND PBDCONT_BRN_CODE = P_BRN_CODE
                               AND PBDCONT_DEP_AC_NUM =
                                      ACNTBAL_INTERNAL_ACNUM),
                       0)
                       CONTRACT_NUMBER
               FROM ACNTS,
                    ACNTBAL,
                    GAIN_LOSS_RATE,
                    PROD_FOR_REVALUATION
              WHERE     ACNTS_ENTITY_NUM = V_ENTITY_NUMBER
                    AND ACNTBAL_ENTITY_NUM = V_ENTITY_NUMBER
                    AND ACNTS_INTERNAL_ACNUM = ACNTBAL_INTERNAL_ACNUM
                    AND ACNTS_BRN_CODE = P_BRN_CODE
                    AND ACNTBAL_CURR_CODE = ACNTS_CURR_CODE
                    AND ACNTS_PROD_CODE = PRODUCT_CODE
                    AND ACNTS_CURR_CODE <> V_BASE_CURR
                    AND ACNTS_CURR_CODE = CURRENCY_CODE
                    AND ROUND (ACNTBAL_BC_BAL, 2) <>
                           ROUND (ACNTBAL_AC_BAL * CONVERSION_RATE, 2)
                    AND ACNTS_CLOSURE_DATE IS NULL
                    AND (ACNTBAL_AC_BAL <> 0 OR ACNTBAL_BC_BAL <> 0))
      LOOP
         V_AC_NUM := IDX.ACNTS_INTERNAL_ACNUM;

         GET_ASON_ACBAL (V_ENTITY_NUMBER,
                         IDX.ACNTS_INTERNAL_ACNUM,
                         IDX.ACNTS_CURR_CODE,
                         V_CBD,
                         V_CBD,
                         V_ACBAL,
                         V_BCBAL,
                         V_ERR_MSG);

         BEGIN
            SELECT CONVERSION_RATE
              INTO V_CONVERSION_RATE
              FROM GAIN_LOSS_RATE
             WHERE CURRENCY_CODE = IDX.ACNTS_CURR_CODE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               PKG_PB_GLOBAL.DETAIL_ERRLOG (
                  V_ENTITY_NUMBER,
                  'E',
                     'Currency conversion Rate is not defined for currency '
                  || IDX.ACNTS_CURR_CODE,
                  ' ',
                  IDX.ACNTS_INTERNAL_ACNUM);
               CONTINUE;
         END;



         IF V_ACBAL = V_BCBAL
         THEN
            V_GAIN_LOSS :=
               ABS (ABS (V_BCBAL) * V_CONVERSION_RATE - ABS (V_BCBAL));

            GET_EXCHANGE_RATE (ROUND (V_GAIN_LOSS + V_CONVERSION_RATE, 2),
                               P_EXCHANGE_VALUE);      ---ADDED IN 26-APR-2017

            IF V_ACBAL > 0
            THEN
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_ACC (
                  IDX.ACNTS_INTERNAL_ACNUM,
                  'C',
                  IDX.CONTRACT_NUMBER,
                  P_EXCHANGE_VALUE,
                  ROUND (V_GAIN_LOSS + V_CONVERSION_RATE, 2),
                  IDX.ACNTS_CURR_CODE,
                  V_CBD,
                  'Revaluation account adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.ACNTS_BRN_CODE,
                  'D',
                  P_EXCHANGE_GL,
                  ROUND (V_GAIN_LOSS, 2),
                  ROUND (V_GAIN_LOSS, 2),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate 1');
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_ACC (
                  IDX.ACNTS_INTERNAL_ACNUM,
                  'D',
                  IDX.CONTRACT_NUMBER,
                  P_EXCHANGE_VALUE,
                  ROUND (V_CONVERSION_RATE, 2),
                  IDX.ACNTS_CURR_CODE,
                  V_CBD,
                  'Revaluation account adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);
            ELSE
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_ACC (
                  IDX.ACNTS_INTERNAL_ACNUM,
                  'D',
                  IDX.CONTRACT_NUMBER,
                  P_EXCHANGE_VALUE,
                  ROUND (V_GAIN_LOSS + V_CONVERSION_RATE, 2),
                  IDX.ACNTS_CURR_CODE,
                  V_CBD,
                  'Revaluation account adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.ACNTS_BRN_CODE,
                  'C',
                  P_EXCHANGE_GL,
                  ROUND (V_GAIN_LOSS, 2),
                  ROUND (V_GAIN_LOSS, 2),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate 1');
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_ACC (
                  IDX.ACNTS_INTERNAL_ACNUM,
                  'C',
                  IDX.CONTRACT_NUMBER,
                  P_EXCHANGE_VALUE,
                  ROUND (V_CONVERSION_RATE, 2),
                  IDX.ACNTS_CURR_CODE,
                  V_CBD,
                  'Revaluation account adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);
            END IF;
         ELSIF     V_ACBAL > 0
               AND V_BCBAL > 0
               AND V_BCBAL <> ROUND (V_ACBAL * V_CONVERSION_RATE, 3)
         THEN
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'D',
               IDX.CONTRACT_NUMBER,
               ROUND (V_ACBAL, 2),
               ROUND (V_BCBAL, 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               '');
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'C',
               IDX.CONTRACT_NUMBER,
               ROUND (V_ACBAL, 2),
               ROUND (V_ACBAL * V_CONVERSION_RATE, 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);

            IF V_BCBAL < V_ACBAL * V_CONVERSION_RATE
            THEN
               V_DR_CR_FLAG := 'D';
            ELSE
               V_DR_CR_FLAG := 'C';
            END IF;

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.ACNTS_BRN_CODE,
               V_DR_CR_FLAG,
               P_EXCHANGE_GL,
               ROUND (ABS (V_ACBAL * V_CONVERSION_RATE - V_BCBAL), 2),
               ROUND (ABS (V_ACBAL * V_CONVERSION_RATE - V_BCBAL), 2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate 1');
         ELSIF     V_ACBAL < 0
               AND V_BCBAL < 0
               AND V_BCBAL <> V_ACBAL * V_CONVERSION_RATE
         THEN
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'C',
               IDX.CONTRACT_NUMBER,
               ROUND (ABS (V_ACBAL), 2),
               ROUND (ABS (V_BCBAL), 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               '');
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'D',
               IDX.CONTRACT_NUMBER,
               ROUND (ABS (V_ACBAL), 2),
               ROUND (ABS (V_ACBAL * V_CONVERSION_RATE), 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);

            IF V_BCBAL > V_ACBAL * V_CONVERSION_RATE
            THEN
               V_DR_CR_FLAG := 'C';
            ELSE
               V_DR_CR_FLAG := 'D';
            END IF;

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.ACNTS_BRN_CODE,
               V_DR_CR_FLAG,
               P_EXCHANGE_GL,
               ROUND (ABS (V_ACBAL * V_CONVERSION_RATE - V_BCBAL), 2),
               ROUND (ABS (V_ACBAL * V_CONVERSION_RATE - V_BCBAL), 2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate 1');
         ELSIF     V_ACBAL = 0
               AND V_BCBAL > 0
               AND V_BCBAL <> V_ACBAL * V_CONVERSION_RATE
         THEN
            GET_EXCHANGE_RATE (
               ROUND (ABS (V_BCBAL) + ABS (V_CONVERSION_RATE), 2),
               P_EXCHANGE_VALUE);                      ---ADDED IN 26-APR-2017

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'C',
               IDX.CONTRACT_NUMBER,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_CONVERSION_RATE), 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.ACNTS_BRN_CODE,
               'C',
               P_EXCHANGE_GL,
               ROUND (ABS (V_BCBAL), 2),
               ROUND (ABS (V_BCBAL), 2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate 1');
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'D',
               IDX.CONTRACT_NUMBER,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_BCBAL) + ABS (V_CONVERSION_RATE), 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
         ELSIF     V_ACBAL < 0
               AND V_BCBAL = 0
               AND V_BCBAL <> V_ACBAL * V_CONVERSION_RATE
         THEN
            GET_EXCHANGE_RATE (
               ROUND (
                    ABS (V_BCBAL)
                  + ABS (V_ACBAL * V_CONVERSION_RATE)
                  + V_CONVERSION_RATE,
                  2),
               P_EXCHANGE_VALUE);                      ---ADDED IN 26-APR-2017

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'D',
               IDX.CONTRACT_NUMBER,
               P_EXCHANGE_VALUE,
               ROUND (
                    ABS (V_BCBAL)
                  + ABS (V_ACBAL * V_CONVERSION_RATE)
                  + V_CONVERSION_RATE,
                  2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.ACNTS_BRN_CODE,
               'C',
               P_EXCHANGE_GL,
               ROUND (ABS (V_BCBAL) + ABS (V_ACBAL * V_CONVERSION_RATE), 2),
               ROUND (ABS (V_BCBAL) + ABS (V_ACBAL * V_CONVERSION_RATE), 2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate 1');
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'C',
               IDX.CONTRACT_NUMBER,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_CONVERSION_RATE), 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
         ELSIF     V_ACBAL > 0
               AND V_BCBAL = 0
               AND V_BCBAL <> V_ACBAL * V_CONVERSION_RATE
         THEN
            GET_EXCHANGE_RATE (
               ROUND (
                    ABS (V_BCBAL)
                  + ABS (V_ACBAL * V_CONVERSION_RATE)
                  + V_CONVERSION_RATE,
                  2),
               P_EXCHANGE_VALUE);                       --ADDED IN 26-APR-2017

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'C',
               IDX.CONTRACT_NUMBER,
               P_EXCHANGE_VALUE,
               ROUND (
                    ABS (V_BCBAL)
                  + ABS (V_ACBAL * V_CONVERSION_RATE)
                  + V_CONVERSION_RATE,
                  2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.ACNTS_BRN_CODE,
               'D',
               P_EXCHANGE_GL,
               ROUND (ABS (V_BCBAL) + ABS (V_ACBAL * V_CONVERSION_RATE), 2),
               ROUND (ABS (V_BCBAL) + ABS (V_ACBAL * V_CONVERSION_RATE), 2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate 1');
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'D',
               IDX.CONTRACT_NUMBER,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_CONVERSION_RATE), 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
         ELSIF     V_ACBAL = 0
               AND V_BCBAL < 0
               AND V_BCBAL <> V_ACBAL * V_CONVERSION_RATE
         THEN
            GET_EXCHANGE_RATE (
               ROUND (ABS (V_BCBAL) + ABS (V_CONVERSION_RATE), 2),
               P_EXCHANGE_VALUE);                       --ADDED IN 26-APR-2017

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'C',
               IDX.CONTRACT_NUMBER,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_BCBAL) + ABS (V_CONVERSION_RATE), 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.ACNTS_BRN_CODE,
               'D',
               P_EXCHANGE_GL,
               ROUND (ABS (V_BCBAL), 2),
               ROUND (ABS (V_BCBAL), 2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate 1');
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_ACC (
               IDX.ACNTS_INTERNAL_ACNUM,
               'D',
               IDX.CONTRACT_NUMBER,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_CONVERSION_RATE), 2),
               IDX.ACNTS_CURR_CODE,
               V_CBD,
               'Revaluation account adjustment',
                  'For A/C'
               || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
               || ' Currency '
               || IDX.ACNTS_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
         ELSE
            V_BCBAL_SHOULD_BE := V_ACBAL * V_CONVERSION_RATE;
            V_BASE_CURR_EQUV := V_BCBAL_SHOULD_BE - V_BCBAL;

            DBMS_OUTPUT.PUT_LINE (
                  IDX.ACNTS_INTERNAL_ACNUM
               || ' ---- '
               || IDX.ACNTS_CURR_CODE
               || ' ---- '
               || V_ACBAL
               || ' ---- '
               || V_BCBAL
               || ' ---- '
               || V_BCBAL_SHOULD_BE
               || ' ---- '
               || V_BASE_CURR_EQUV);

            IF V_BASE_CURR_EQUV > 0
            THEN
               GET_EXCHANGE_RATE (
                  ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2),
                  P_EXCHANGE_VALUE);                    --ADDED IN 26-APR-2017


               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_ACC (
                  IDX.ACNTS_INTERNAL_ACNUM,
                  'C',
                  IDX.CONTRACT_NUMBER,
                  P_EXCHANGE_VALUE,
                  ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2),
                  IDX.ACNTS_CURR_CODE,
                  V_CBD,
                  'Revaluation account adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                     'Transaction rate '
                  ||   ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2)
                     / P_EXCHANGE_VALUE);
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.ACNTS_BRN_CODE,
                  'D',
                  P_EXCHANGE_GL,
                  ROUND (V_BASE_CURR_EQUV + V_CONVERSION_RATE, 2),
                  ROUND (V_BASE_CURR_EQUV + V_CONVERSION_RATE, 2),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate 1');

               ------ Reverse transaction

               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_ACC (
                  IDX.ACNTS_INTERNAL_ACNUM,
                  'D',
                  IDX.CONTRACT_NUMBER,
                  P_EXCHANGE_VALUE,
                  ROUND (V_CONVERSION_RATE, 2),
                  IDX.ACNTS_CURR_CODE,
                  V_CBD,
                  'Revaluation account adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.ACNTS_BRN_CODE,
                  'C',
                  P_EXCHANGE_GL,
                  ROUND (V_CONVERSION_RATE, 2),
                  ROUND (V_CONVERSION_RATE, 2),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate 1');
            ------------- LOSS
            ------------- GL 300119109
            --NULL;
            ELSIF V_BASE_CURR_EQUV < 0
            THEN
               GET_EXCHANGE_RATE (
                  ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2),
                  P_EXCHANGE_VALUE);                    --ADDED IN 26-APR-2017

               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_ACC (
                  IDX.ACNTS_INTERNAL_ACNUM,
                  'D',
                  IDX.CONTRACT_NUMBER,
                  P_EXCHANGE_VALUE,
                  ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2),
                  IDX.ACNTS_CURR_CODE,
                  V_CBD,
                  'Revaluation account adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                     'Transaction rate '
                  ||   ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2)
                     / P_EXCHANGE_VALUE);
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.ACNTS_BRN_CODE,
                  'C',
                  P_EXCHANGE_GL,
                  ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2),
                  ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate 1');



               ---- Reverse transaction

               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_ACC (
                  IDX.ACNTS_INTERNAL_ACNUM,
                  'C',
                  IDX.CONTRACT_NUMBER,
                  P_EXCHANGE_VALUE,
                  ROUND (V_CONVERSION_RATE, 2),
                  IDX.ACNTS_CURR_CODE,
                  V_CBD,
                  'Revaluation account adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);


               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.ACNTS_BRN_CODE,
                  'D',
                  P_EXCHANGE_GL,
                  ROUND (V_CONVERSION_RATE, 2),
                  ROUND (V_CONVERSION_RATE, 2),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For A/C'
                  || FACNO (V_ENTITY_NUMBER, IDX.ACNTS_INTERNAL_ACNUM)
                  || ' Currency '
                  || IDX.ACNTS_CURR_CODE,
                  'Transaction rate 1');
            ------------- INCOME
            ------------- GL 300119109
            --NULL;
            END IF;
         END IF;
      END LOOP;


      BEGIN
         SET_TRAN_KEY_VALUES;
         SET_TRANBAT_VALUES;

         AUTOPOST_ENTRIES;


         W_POST_ARRAY_INDEX := 0;
         IDX1 := 0;
         V_NUMBER_OF_TRAN := 0;
         PKG_AUTOPOST.PV_TRAN_REC.DELETE;
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE_APPLICATION_ERROR (-20100, 'ERROR AUTOPOST ' || W_ERROR);
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (PKG_ERR_MSG) IS NULL
         THEN
            PKG_ERR_MSG :=
                  'Error in PKG_REVALUATION.SP_REVALUATION_ACCOUNT PROCEDURE. For account: '
               || V_AC_NUM
               || 'Error Msg: '
               || SQLERRM;
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := PKG_ERR_MSG;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                      'E',
                                      PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                      ' ',
                                      0);
   END SP_REVALUATION_ACCOUNT;


   PROCEDURE SP_REVALUATION_GL (P_ENTITY_CODE   IN NUMBER,
                                P_BRN_CODE      IN NUMBER,
                                P_EXCHANGE_GL   IN VARCHAR2)
   IS
      V_BASE_CURR         CURRENCY.CURR_CODE%TYPE;
      V_ENTITY_NUMBER     INSTALL.INS_ENTITY_NUM%TYPE := P_ENTITY_CODE;
      V_ACBAL             ACNTBAL.ACNTBAL_AC_BAL%TYPE;
      V_BCBAL             ACNTBAL.ACNTBAL_BC_BAL%TYPE;
      V_CBD               MAINCONT.MN_CURR_BUSINESS_DATE%TYPE;
      V_ERR_MSG           VARCHAR2 (1000);
      V_CONVERSION_RATE   TRAN2016.TRAN_BASE_CURR_CONV_RATE%TYPE;
      V_DR_CR_FLAG        TRAN2016.TRAN_DB_CR_FLG%TYPE;
      V_BCBAL_SHOULD_BE   ACNTBAL.ACNTBAL_AC_BAL%TYPE;
      V_BASE_CURR_EQUV    ACNTBAL.ACNTBAL_AC_BAL%TYPE;
      V_GL_CODE           GLBBAL.GLBBAL_GLACC_CODE%TYPE;
      V_BRN_CODE          MBRN.MBRN_CODE%TYPE;
      V_GL_GAIN_LOSS      NUMBER (18, 3);              ---ADDED IN 25-APR-2017
      P_NEW_AMT           NUMBER (18, 3);              ---ADDED IN 25-APR-2017
      P_EXCHANGE_VALUE    NUMBER := 0;                 ---ADDED IN 25-APR-2017
   BEGIN
      V_NUMBER_OF_TRAN := 0;
      V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_ENTITY_NUMBER);
      V_BASE_CURR := PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR (V_ENTITY_NUMBER);
      INITILIZE_TRANSACTION;



      W_POST_ARRAY_INDEX := 0;
      IDX1 := 0;



      FOR IDX
         IN (SELECT GLBBAL_BRANCH_CODE,
                    GLBBAL_GLACC_CODE,
                    GLBBAL_CURR_CODE,
                    GLBBAL_AC_BAL,
                    GLBBAL_BC_BAL
               FROM GLBBAL,
                    EXTGL,
                    GLMAST,
                    GL_FOR_REVALUATION
              WHERE     GLBBAL_ENTITY_NUM = V_ENTITY_NUMBER
                    AND EXTGL_ACCESS_CODE = GLBBAL_GLACC_CODE
                    AND EXTGL_GL_HEAD = GL_NUMBER
                    AND GL_CUST_AC_ALLOWED = '0'
                    AND GLBBAL_BRANCH_CODE = P_BRN_CODE
                    AND GLBBAL_GLACC_CODE = GL_CODE
                    AND GLBBAL_CURR_CODE <> V_BASE_CURR
                    AND GL_INTER_BRN_GL <> '1'
                    AND GLBBAL_YEAR = TO_CHAR (V_CBD, 'YYYY')
                    AND (GLBBAL_AC_BAL <> 0 OR GLBBAL_BC_BAL <> 0))
      LOOP
         V_GL_CODE := IDX.GLBBAL_GLACC_CODE;
         V_BRN_CODE := IDX.GLBBAL_BRANCH_CODE;

         BEGIN
            SELECT CONVERSION_RATE
              INTO V_CONVERSION_RATE
              FROM GAIN_LOSS_RATE
             WHERE CURRENCY_CODE = IDX.GLBBAL_CURR_CODE;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               PKG_PB_GLOBAL.DETAIL_ERRLOG (
                  V_ENTITY_NUMBER,
                  'E',
                     'Currency conversion Rate is not defined for currency '
                  || IDX.GLBBAL_CURR_CODE,
                  IDX.GLBBAL_GLACC_CODE,
                  0);
               CONTINUE;
         END;


         IF IDX.GLBBAL_AC_BAL = IDX.GLBBAL_BC_BAL      ---ADDED IN 25-APR-2017
         THEN
            V_GL_GAIN_LOSS :=
               ABS (
                    ABS (IDX.GLBBAL_BC_BAL) * V_CONVERSION_RATE
                  - ABS (IDX.GLBBAL_BC_BAL));

            GET_EXCHANGE_RATE (ROUND (V_GL_GAIN_LOSS + V_CONVERSION_RATE, 2),
                               P_EXCHANGE_VALUE);    -----ADDED IN 26-APR-2017

            IF IDX.GLBBAL_AC_BAL > 0
            THEN
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'C',
                  IDX.GLBBAL_GLACC_CODE,
                  P_EXCHANGE_VALUE,
                  ROUND (V_GL_GAIN_LOSS + V_CONVERSION_RATE, 2),
                  IDX.GLBBAL_CURR_CODE,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);

               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'D',
                  P_EXCHANGE_GL,
                  ROUND (V_GL_GAIN_LOSS, 2),
                  ROUND (V_GL_GAIN_LOSS, 2),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate 1');

               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'D',
                  IDX.GLBBAL_GLACC_CODE,
                  P_EXCHANGE_VALUE,
                  ROUND (V_CONVERSION_RATE, 2),
                  IDX.GLBBAL_CURR_CODE,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);
            ELSE
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'D',
                  IDX.GLBBAL_GLACC_CODE,
                  P_EXCHANGE_VALUE,
                  ROUND (V_GL_GAIN_LOSS + V_CONVERSION_RATE, 2),
                  IDX.GLBBAL_CURR_CODE,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);

               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'C',
                  P_EXCHANGE_GL,
                  ROUND (V_GL_GAIN_LOSS, 2),
                  ROUND (V_GL_GAIN_LOSS, 2),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate 1');

               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'C',
                  IDX.GLBBAL_GLACC_CODE,
                  P_EXCHANGE_GL,
                  ROUND (V_CONVERSION_RATE, 2),
                  IDX.GLBBAL_CURR_CODE,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate ' || V_CONVERSION_RATE);
            END IF;
         ELSIF     IDX.GLBBAL_AC_BAL > 0
               AND IDX.GLBBAL_BC_BAL > 0
               AND IDX.GLBBAL_BC_BAL <>
                      ROUND (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE, 2)
         THEN
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'D',
               IDX.GLBBAL_GLACC_CODE,
               ABS (IDX.GLBBAL_AC_BAL),
               ABS (IDX.GLBBAL_BC_BAL),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate '
               || ROUND (IDX.GLBBAL_BC_BAL / IDX.GLBBAL_AC_BAL, 2));
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'C',
               IDX.GLBBAL_GLACC_CODE,
               ABS (IDX.GLBBAL_AC_BAL),
               ABS (ROUND (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE, 2)),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);

            IF IDX.GLBBAL_BC_BAL < IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE
            THEN
               V_DR_CR_FLAG := 'D';
            ELSE
               V_DR_CR_FLAG := 'C';
            END IF;

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               V_DR_CR_FLAG,
               P_EXCHANGE_GL,
               ROUND (
                  ABS (
                       IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE
                     - IDX.GLBBAL_BC_BAL),
                  2),
               ROUND (
                  ABS (
                       IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE
                     - IDX.GLBBAL_BC_BAL),
                  2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate 1');
         ELSIF     IDX.GLBBAL_AC_BAL = 0               ---ADDED IN 25-APR-2017
               AND IDX.GLBBAL_BC_BAL < 0
               AND IDX.GLBBAL_BC_BAL <>
                      ROUND (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE, 2)
         THEN
            GET_EXCHANGE_RATE (
               ROUND (ABS (IDX.GLBBAL_BC_BAL) + ABS (V_CONVERSION_RATE), 2),
               P_EXCHANGE_VALUE);

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'C',
               IDX.GLBBAL_GLACC_CODE,
               P_EXCHANGE_VALUE,
               ROUND (ABS (IDX.GLBBAL_BC_BAL) + ABS (V_CONVERSION_RATE), 2),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'D',
               P_EXCHANGE_GL,
               ROUND (ABS (IDX.GLBBAL_BC_BAL), 2),
               ROUND (ABS (IDX.GLBBAL_BC_BAL), 2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate 1');

            ----- Reverse transaction

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'D',
               IDX.GLBBAL_GLACC_CODE,
               P_EXCHANGE_VALUE,
               ABS (ROUND (V_CONVERSION_RATE, 2)),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
         ELSIF     IDX.GLBBAL_AC_BAL = 0               ---ADDED IN 25-APR-2017
               AND IDX.GLBBAL_BC_BAL > 0
               AND IDX.GLBBAL_BC_BAL <>
                      ROUND (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE, 2)
         THEN
            GET_EXCHANGE_RATE (
               ROUND (ABS (IDX.GLBBAL_BC_BAL) + ABS (V_CONVERSION_RATE), 2),
               P_EXCHANGE_VALUE);


            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'C',
               IDX.GLBBAL_GLACC_CODE,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_CONVERSION_RATE), 2),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'C',
               P_EXCHANGE_GL,
               ROUND (ABS (IDX.GLBBAL_BC_BAL), 2),
               ROUND (ABS (IDX.GLBBAL_BC_BAL), 2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate 1');

            ----- Reverse transaction

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'D',
               IDX.GLBBAL_GLACC_CODE,
               P_EXCHANGE_VALUE,
               ROUND (ABS (IDX.GLBBAL_BC_BAL) + ABS (V_CONVERSION_RATE), 2),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
         ELSIF     IDX.GLBBAL_AC_BAL > 0               ---ADDED IN 25-APR-2017
               AND IDX.GLBBAL_BC_BAL = 0
               AND IDX.GLBBAL_BC_BAL <>
                      ROUND (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE, 2)
         THEN
            GET_EXCHANGE_RATE (
               ROUND (
                    ABS (IDX.GLBBAL_BC_BAL)
                  + ABS (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE)
                  + V_CONVERSION_RATE,
                  2),
               P_EXCHANGE_VALUE);

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'C',
               IDX.GLBBAL_GLACC_CODE,
               P_EXCHANGE_VALUE,
               ROUND (
                    ABS (IDX.GLBBAL_BC_BAL)
                  + ABS (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE)
                  + V_CONVERSION_RATE,
                  2),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'D',
               P_EXCHANGE_GL,
               ROUND (
                    ABS (IDX.GLBBAL_BC_BAL)
                  + ABS (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE),
                  2),
               ROUND (
                    ABS (IDX.GLBBAL_BC_BAL)
                  + ABS (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE),
                  2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate 1');

            ----- Reverse transaction

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'D',
               IDX.GLBBAL_GLACC_CODE,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_CONVERSION_RATE), 2),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
         ELSIF     IDX.GLBBAL_AC_BAL < 0               ---ADDED IN 25-APR-2017
               AND IDX.GLBBAL_BC_BAL = 0
               AND IDX.GLBBAL_BC_BAL <>
                      ROUND (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE, 2)
         THEN
            GET_EXCHANGE_RATE (
               ROUND (
                    ABS (IDX.GLBBAL_BC_BAL)
                  + ABS (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE)
                  + V_CONVERSION_RATE,
                  2),
               P_EXCHANGE_VALUE);

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'D',
               IDX.GLBBAL_GLACC_CODE,
               P_EXCHANGE_VALUE,
               ROUND (
                    ABS (IDX.GLBBAL_BC_BAL)
                  + ABS (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE)
                  + V_CONVERSION_RATE,
                  2),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'C',
               P_EXCHANGE_GL,
               ROUND (
                    ABS (IDX.GLBBAL_BC_BAL)
                  + ABS (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE),
                  2),
               ROUND (
                    ABS (IDX.GLBBAL_BC_BAL)
                  + ABS (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE),
                  2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate 1');


            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'C',
               IDX.GLBBAL_GLACC_CODE,
               P_EXCHANGE_VALUE,
               ROUND (ABS (V_CONVERSION_RATE), 2),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);
         ELSIF     IDX.GLBBAL_AC_BAL < 0
               AND IDX.GLBBAL_BC_BAL < 0
               AND IDX.GLBBAL_BC_BAL <>
                      ROUND (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE, 2)
         THEN
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'C',
               IDX.GLBBAL_GLACC_CODE,
               ABS (IDX.GLBBAL_AC_BAL),
               ABS (IDX.GLBBAL_BC_BAL),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate '
               || ROUND (IDX.GLBBAL_BC_BAL / IDX.GLBBAL_AC_BAL, 2));
            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               'D',
               IDX.GLBBAL_GLACC_CODE,
               ABS (IDX.GLBBAL_AC_BAL),
               ABS (ROUND (IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE, 2)),
               IDX.GLBBAL_CURR_CODE,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate ' || V_CONVERSION_RATE);

            IF IDX.GLBBAL_BC_BAL > IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE
            THEN
               V_DR_CR_FLAG := 'C';
            ELSE
               V_DR_CR_FLAG := 'D';
            END IF;

            V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
            MOVE_TO_TRANREC_GL (
               IDX.GLBBAL_BRANCH_CODE,
               V_DR_CR_FLAG,
               P_EXCHANGE_GL,
               ROUND (
                  ABS (
                       IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE
                     - IDX.GLBBAL_BC_BAL),
                  2),
               ROUND (
                  ABS (
                       IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE
                     - IDX.GLBBAL_BC_BAL),
                  2),
               V_BASE_CURR,
               'Revaluation GL adjustment',
                  'For GL '
               || IDX.GLBBAL_GLACC_CODE
               || ' Currency '
               || IDX.GLBBAL_CURR_CODE,
               'Transaction rate 1');
         ELSE
            V_BCBAL_SHOULD_BE := IDX.GLBBAL_AC_BAL * V_CONVERSION_RATE;
            V_BASE_CURR_EQUV := V_BCBAL_SHOULD_BE - IDX.GLBBAL_BC_BAL;

            IF V_BASE_CURR_EQUV > 0
            THEN
               GET_EXCHANGE_RATE (
                  ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2),
                  P_EXCHANGE_VALUE);                ------ADDED IN 26-APR-2017


               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'C',
                  IDX.GLBBAL_GLACC_CODE,
                  P_EXCHANGE_VALUE,
                  ROUND (
                       ABS (IDX.GLBBAL_BC_BAL)
                     + ABS (V_BCBAL_SHOULD_BE)
                     + V_CONVERSION_RATE,
                     2),
                  IDX.GLBBAL_CURR_CODE,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                     'Transaction rate '
                  ||   ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2)
                     / P_EXCHANGE_VALUE);
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'D',
                  P_EXCHANGE_GL,
                  ABS (
                     ROUND (ABS (V_BCBAL_SHOULD_BE) + IDX.GLBBAL_BC_BAL, 2)),
                  ABS (
                     ROUND (ABS (V_BCBAL_SHOULD_BE) + IDX.GLBBAL_BC_BAL, 2)),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate 1');

               ----- Reverse transaction
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'D',
                  IDX.GLBBAL_GLACC_CODE,
                  P_EXCHANGE_VALUE,
                  ABS (ROUND (V_CONVERSION_RATE, 2)),
                  IDX.GLBBAL_CURR_CODE,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                     'Transaction rate '
                  ||   ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2)
                     / P_EXCHANGE_VALUE);
            /*
         V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
         MOVE_TO_TRANREC_GL (
            IDX.GLBBAL_BRANCH_CODE,
            'C',
            P_EXCHANGE_GL,
            ABS (ROUND (V_CONVERSION_RATE, 3)),
            ABS (ROUND (V_CONVERSION_RATE, 3)),
            V_BASE_CURR,
            'Revaluation GL adjustment',
               'For GL '
            || IDX.GLBBAL_GLACC_CODE
            || ' Currency '
            || IDX.GLBBAL_CURR_CODE,
            'Transaction rate 1');
            */
            ------------- LOSS
            ------------- GL 300119109

            ELSIF V_BASE_CURR_EQUV < 0
            THEN
               GET_EXCHANGE_RATE (
                  ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2),
                  P_EXCHANGE_VALUE);                   ---ADDED IN 25-APR-2017

               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'D',
                  IDX.GLBBAL_GLACC_CODE,
                  P_EXCHANGE_VALUE,
                  ROUND (
                       ABS (IDX.GLBBAL_BC_BAL)
                     + ABS (V_BCBAL_SHOULD_BE)
                     + V_CONVERSION_RATE,
                     2),
                  IDX.GLBBAL_CURR_CODE,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                     'Transaction rate '
                  ||   ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2)
                     / P_EXCHANGE_VALUE);
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'C',
                  P_EXCHANGE_GL,
                  ABS (
                     ROUND (ABS (V_BCBAL_SHOULD_BE) + IDX.GLBBAL_BC_BAL, 2)),
                  ABS (
                     ROUND (ABS (V_BCBAL_SHOULD_BE) + IDX.GLBBAL_BC_BAL, 2)),
                  V_BASE_CURR,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                  'Transaction rate 1');

               ----- Reverse transaction
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  IDX.GLBBAL_BRANCH_CODE,
                  'C',
                  IDX.GLBBAL_GLACC_CODE,
                  P_EXCHANGE_VALUE,
                  ABS (ROUND (V_CONVERSION_RATE, 2)),
                  IDX.GLBBAL_CURR_CODE,
                  'Revaluation GL adjustment',
                     'For GL '
                  || IDX.GLBBAL_GLACC_CODE
                  || ' Currency '
                  || IDX.GLBBAL_CURR_CODE,
                     'Transaction rate '
                  ||   ROUND (ABS (V_BASE_CURR_EQUV) + V_CONVERSION_RATE, 2)
                     / P_EXCHANGE_VALUE);
            /*
         V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
         MOVE_TO_TRANREC_GL (
            IDX.GLBBAL_BRANCH_CODE,
            'D',
            P_EXCHANGE_GL,
            ABS (ROUND (V_CONVERSION_RATE, 3)),
            ABS (ROUND (V_CONVERSION_RATE, 3)),
            V_BASE_CURR,
            'Revaluation GL adjustment',
               'For GL '
            || IDX.GLBBAL_GLACC_CODE
            || ' Currency '
            || IDX.GLBBAL_CURR_CODE,
            'Transaction rate 1');
            */
            END IF;
         END IF;
      END LOOP;


      BEGIN
         SET_TRAN_KEY_VALUES;
         SET_TRANBAT_VALUES;

         AUTOPOST_ENTRIES;


         W_POST_ARRAY_INDEX := 0;
         IDX1 := 0;
         V_NUMBER_OF_TRAN := 0;
         PKG_AUTOPOST.PV_TRAN_REC.DELETE;
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE_APPLICATION_ERROR (-20100, 'ERROR AUTOPOST ' || W_ERROR);
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (PKG_ERR_MSG) IS NULL
         THEN
            PKG_ERR_MSG :=
                  'Error in PKG_REVALUATION.SP_REVALUATION_ACCOUNT PROCEDURE. For branch code : '
               || V_BRN_CODE
               || 'GL code :'
               || V_GL_CODE
               || 'Error Msg: '
               || SQLERRM;
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := PKG_ERR_MSG;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (
            PKG_ENTITY.FN_GET_ENTITY_CODE,
            'E',
            SQLERRM || ' --- ' || PKG_EODSOD_FLAGS.PV_ERROR_MSG,
            ' ',
            0);
   END SP_REVALUATION_GL;



   PROCEDURE START_BRNWISE (
      P_ENTITY_NUM   IN ENTITYNUM.ENTITYNUM_NUMBER%TYPE,
      P_BRN_CODE     IN MBRN.MBRN_CODE%TYPE DEFAULT 0)
   IS
      V_ENTITY_NUM   NUMBER := P_ENTITY_NUM;
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

      BEGIN
         SELECT REVALGL_CODE INTO V_EXCHANGE_GL FROM REVALGL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_EXCHANGE_GL := '300119109';
      END;

      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (V_ENTITY_NUM, P_BRN_CODE);
      V_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      W_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

         IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (V_ENTITY_NUM,
                                                         L_BRN_CODE) = FALSE
         THEN
            SP_REVALUATION_ACCOUNT (V_ENTITY_NUM, L_BRN_CODE, V_EXCHANGE_GL);

            W_ERROR_CODE := PKG_EODSOD_FLAGS.PV_ERROR_MSG;

            IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
            THEN
               SP_REVALUATION_GL (V_ENTITY_NUM, L_BRN_CODE, V_EXCHANGE_GL);
            END IF;

            PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (V_ENTITY_NUM);

            IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
            THEN
               PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (V_ENTITY_NUM,
                                                                L_BRN_CODE);
            END IF;
         END IF;
      END LOOP;
   --PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (V_ENTITY_NUM);
   END START_BRNWISE;
END PKG_REVALUATION;
/
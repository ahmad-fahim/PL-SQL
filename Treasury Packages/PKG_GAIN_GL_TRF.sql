CREATE OR REPLACE PACKAGE PKG_GAIN_GL_TRF
  /*

   Author :Kazi Sabuj
   Created : 09/30/2019 4:19:11 PM
   Purpose : Gain loss GL adjustment

   */
IS
   TYPE TY_TRANRECDTL IS RECORD
   (
      VV_BRN_CODE    MBRN.MBRN_CODE%TYPE,
      VV_DB_CR_FLG    TRAN2019.TRAN_DB_CR_FLG%TYPE,
       VV_GLACC_CODE   TRAN2019.TRAN_GLACC_CODE%TYPE,
       VV_FROM_GL     TRAN2019.TRAN_GLACC_CODE%TYPE,
       VV_TO_DRGL       TRAN2019.TRAN_GLACC_CODE%TYPE,
       VV_TO_CRGL       TRAN2019.TRAN_GLACC_CODE%TYPE,
      VV_CURR_CODE    TRAN2019.TRAN_CURR_CODE%TYPE,
      VV_AC_AMOUNT    TRAN2019.TRAN_AMOUNT%TYPE,
      VV_BC_AMT       TRAN2019.TRAN_BASE_CURR_EQ_AMT%TYPE
   );


   TYPE TY_TY_TRANREC IS TABLE OF TY_TRANRECDTL;


   PROCEDURE START_BRNWISE (
      P_ENTITY_NUM   IN ENTITYNUM.ENTITYNUM_NUMBER%TYPE);
END;
/

CREATE OR REPLACE PACKAGE BODY PKG_GAIN_GL_TRF
/*

  Author :Kazi Sabuj
  Created : 09/30/2019 4:19:11 PM
  Purpose : Gain loss GL adjustment

  */
IS
   V_ASON_DATE          DATE;
   W_USER_ID            VARCHAR2 (8);
   W_SQL                VARCHAR2 (4000);
   L_BRN_CODE           NUMBER (6);
   V_NUMBER_OF_TRAN     NUMBER;
   W_POST_ARRAY_INDEX   NUMBER (14) DEFAULT 0;
   IDX1                 NUMBER DEFAULT 0;
   W_ERROR              VARCHAR2 (3000);
   W_ERR_CODE           VARCHAR2 (300);
   W_BATCH_NUM          NUMBER;
   W_ERROR_CODE         VARCHAR2 (400);
   V_USER_EXCEPTION     EXCEPTION;
   PKG_ERR_MSG          VARCHAR2 (2300);
   V_EXCHANGE_GL        EXTGL.EXTGL_ACCESS_CODE%TYPE;

   TYPE TY_TRANREC IS RECORD
   (
      V_BRN_CODE     MBRN.MBRN_CODE%TYPE,
      V_DB_CR_FLG    TRAN2019.TRAN_DB_CR_FLG%TYPE,
      V_GLACC_CODE   TRAN2019.TRAN_GLACC_CODE%TYPE,
      V_CURR_CODE    TRAN2019.TRAN_CURR_CODE%TYPE,
      V_AC_AMOUNT    TRAN2019.TRAN_AMOUNT%TYPE,
      V_BC_AMOUNT    TRAN2019.TRAN_BASE_CURR_EQ_AMT%TYPE
   );

   TYPE TTY_TRANREC IS TABLE OF TY_TRANREC
      INDEX BY PLS_INTEGER;

   V_TTY_TRANREC        TTY_TRANREC;


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
            'ERROR IN POST_TRANSACTION ' || W_ERR_CODE || ' ' || W_ERROR;
         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;

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

   PROCEDURE INITILIZE_TRANSACTION
   IS
   BEGIN
      PKG_AUTOPOST.PV_USERID := W_USER_ID;
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
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := L_BRN_CODE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := V_ASON_DATE;
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
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_BRN_CODE := L_BRN_CODE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_DATE_OF_TRAN := V_ASON_DATE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_BATCH_NUMBER := 0;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_ENTRY_BRN_CODE := L_BRN_CODE;
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
         L_BRN_CODE || V_ASON_DATE || '|0';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 := NULL;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL2 := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL3 := '';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_AUTH_BY := W_USER_ID;
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
         DBMS_OUTPUT.PUT_LINE ('step1');
   END MOVE_TO_TRANREC_GL;


   PROCEDURE SP_REVARSE_GL (P_ENTITY_CODE IN NUMBER, P_BRN_CODE IN NUMBER)
   IS
      V_BASE_CURR         CURRENCY.CURR_CODE%TYPE;
      V_ENTITY_NUMBER     INSTALL.INS_ENTITY_NUM%TYPE := P_ENTITY_CODE;
      V_TO_CRGL           GLBBAL.GLBBAL_GLACC_CODE%TYPE;
      V_TO_DRGL           GLBBAL.GLBBAL_GLACC_CODE%TYPE;
      P_EXCHANGE_GL       GLBBAL.GLBBAL_GLACC_CODE%TYPE;
      V_BCBAL             ACNTBAL.ACNTBAL_BC_BAL%TYPE;
      V_CBD               MAINCONT.MN_CURR_BUSINESS_DATE%TYPE;
      V_ERR_MSG           VARCHAR2 (1000);
      V_CONVERSION_RATE   TRAN2019.TRAN_BASE_CURR_CONV_RATE%TYPE;
      V_DR_CR_FLAG        TRAN2019.TRAN_DB_CR_FLG%TYPE;
      V_BCBAL_SHOULD_BE   ACNTBAL.ACNTBAL_AC_BAL%TYPE;
      V_BASE_CURR_EQUV    ACNTBAL.ACNTBAL_AC_BAL%TYPE;
      V_GL_CODE           GLBBAL.GLBBAL_GLACC_CODE%TYPE;
      V_BRN_CODE          MBRN.MBRN_CODE%TYPE;
      V_GL_GAIN_LOSS      NUMBER (18, 3);
      P_NEW_AMT           NUMBER (18, 3);
      V_CONS_AC_AMT       NUMBER (18, 3);
      V_CONS_BC_AMT       NUMBER (18, 3);
      P_EXCHANGE_VALUE    NUMBER := 0;
      V_FIN_YEAR          NUMBER;

      V_CURR_CODE         CURRENCY.CURR_CODE%TYPE;
      V_DUMMY             VARCHAR2 (13);
   BEGIN
      V_NUMBER_OF_TRAN := 0;
      V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_ENTITY_NUMBER);
      V_BASE_CURR := PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR (V_ENTITY_NUMBER);
      INITILIZE_TRANSACTION;

      V_FIN_YEAR := EXTRACT (YEAR FROM V_CBD);
      V_CONS_AC_AMT := 0;
      V_CONS_BC_AMT := 0;

      W_POST_ARRAY_INDEX := 0;
      IDX1 := 0;

      --      SELECT FROM_GL, TO_CRGL, TO_DRGL
      --        INTO P_EXCHANGE_GL, V_TO_CRGL, V_TO_DRGL
      --        FROM GLBALTRANS;


      FOR IDXZ IN (SELECT * FROM GLBALTRANS)
      LOOP
         V_DUMMY := IDXZ.FROM_GL;
         W_SQL :=
               'SELECT TRAN_ACING_BRN_CODE,
                    TRAN_DB_CR_FLG,
                    TRAN_GLACC_CODE,
                    TRAN_CURR_CODE,
                    TRAN_AMOUNT, 
                    TRAN_BASE_CURR_EQ_AMT
               FROM TRAN'
            || V_FIN_YEAR
            || '
              WHERE     TRAN_ENTITY_NUM = :1
                    AND TRAN_ACING_BRN_CODE = :2
                    AND TRAN_DATE_OF_TRAN= :3
                    AND TRAN_GLACC_CODE = :4
                    AND TRAN_AUTH_BY IS NOT NULL ';
         DBMS_OUTPUT.PUT_LINE (W_SQL);

         EXECUTE IMMEDIATE W_SQL
            BULK COLLECT INTO V_TTY_TRANREC
            USING P_ENTITY_CODE,
                  P_BRN_CODE,
                  V_CBD,
                  IDXZ.FROM_GL;

         IF V_TTY_TRANREC.COUNT > 0
         THEN
            FOR IDX IN V_TTY_TRANREC.FIRST .. V_TTY_TRANREC.LAST
            LOOP
               IF     V_TTY_TRANREC (IDX).V_AC_AMOUNT > 0
                  AND V_TTY_TRANREC (IDX).V_DB_CR_FLG = 'D'
               THEN
                  V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
                  MOVE_TO_TRANREC_GL (
                     V_TTY_TRANREC (IDX).V_BRN_CODE,
                     'D',
                     IDXZ.TO_DRGL,
                     V_TTY_TRANREC (IDX).V_AC_AMOUNT,
                     V_TTY_TRANREC (IDX).V_BC_AMOUNT,
                     V_TTY_TRANREC (IDX).V_CURR_CODE,
                     'Gain loss GL adjustment',
                        'For GL '
                     || IDXZ.TO_DRGL
                     || ' Currency '
                     || V_TTY_TRANREC (IDX).V_CURR_CODE,
                     'Transaction rate 1');
                  V_CONS_AC_AMT :=
                     V_CONS_AC_AMT + V_TTY_TRANREC (IDX).V_AC_AMOUNT;
                  V_CONS_BC_AMT :=
                     V_CONS_BC_AMT + V_TTY_TRANREC (IDX).V_BC_AMOUNT;
               ELSIF     V_TTY_TRANREC (IDX).V_AC_AMOUNT > 0
                     AND V_TTY_TRANREC (IDX).V_DB_CR_FLG = 'C'
               THEN
                  V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
                  MOVE_TO_TRANREC_GL (
                     V_TTY_TRANREC (IDX).V_BRN_CODE,
                     'C',
                     IDXZ.TO_CRGL,
                     V_TTY_TRANREC (IDX).V_AC_AMOUNT,
                     V_TTY_TRANREC (IDX).V_BC_AMOUNT,
                     V_TTY_TRANREC (IDX).V_CURR_CODE,
                     'Gain loss GL adjustment',
                        'For GL '
                     || IDXZ.TO_CRGL
                     || ' Currency '
                     || V_TTY_TRANREC (IDX).V_CURR_CODE,
                     'Transaction rate ');
                  V_CONS_AC_AMT :=
                     V_CONS_AC_AMT - V_TTY_TRANREC (IDX).V_AC_AMOUNT;
                  V_CONS_BC_AMT :=
                     V_CONS_BC_AMT - V_TTY_TRANREC (IDX).V_BC_AMOUNT;
               END IF;

               V_CURR_CODE := V_TTY_TRANREC (IDX).V_CURR_CODE;
               DBMS_OUTPUT.PUT_LINE (V_CONS_AC_AMT || ' ' || V_CONS_BC_AMT);
            END LOOP;

            IF V_CONS_AC_AMT < 0
            THEN
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;

               MOVE_TO_TRANREC_GL (
                  P_BRN_CODE,
                  'D',
                  IDXZ.FROM_GL,
                  ABS (V_CONS_AC_AMT),
                  ABS (V_CONS_BC_AMT),
                  V_CURR_CODE,
                  'Gain loss GL adjustment',
                  'For GL ' || IDXZ.FROM_GL || ' Currency ' || V_CURR_CODE,
                  'Transaction rate');
            ELSIF V_CONS_AC_AMT > 0
            THEN
               V_NUMBER_OF_TRAN := V_NUMBER_OF_TRAN + 1;
               MOVE_TO_TRANREC_GL (
                  P_BRN_CODE,
                  'C',
                  IDXZ.FROM_GL,
                  ABS (V_CONS_AC_AMT),
                  ABS (V_CONS_BC_AMT),
                  V_CURR_CODE,
                  'Gain loss GL adjustment',
                  'For GL ' || IDXZ.FROM_GL || ' Currency ' || V_CURR_CODE,
                  'Transaction rate ');
            END IF;

            IF V_CONS_AC_AMT <> 0
            THEN
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
                     RAISE_APPLICATION_ERROR (-20100,
                                              'ERROR AUTOPOST ' || W_ERROR);
               END;
            ELSE
               W_POST_ARRAY_INDEX := 0;
               IDX1 := 0;
               V_NUMBER_OF_TRAN := 0;
               PKG_AUTOPOST.PV_TRAN_REC.DELETE;
            END IF;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (PKG_ERR_MSG) IS NULL
         THEN
            PKG_ERR_MSG :=
                  'Error in PKG_GAIN_GL_TRF.SP_REVARSE_GL PROCEDURE. For branch code : '
               || V_BRN_CODE
               || 'GL code :'
               || V_GL_CODE
               || 'Error Msg: '
               || SQLERRM;
            PKG_EODSOD_FLAGS.PV_ERROR_MSG := PKG_ERR_MSG;
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := PKG_ERR_MSG;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (
            PKG_ENTITY.FN_GET_ENTITY_CODE,
            'E',
            SQLERRM || ' --- ' || PKG_EODSOD_FLAGS.PV_ERROR_MSG,
            ' ',
            0);
         DBMS_OUTPUT.PUT_LINE ('step2');
   END SP_REVARSE_GL;



   PROCEDURE START_BRNWISE (P_ENTITY_NUM IN ENTITYNUM.ENTITYNUM_NUMBER%TYPE)
   IS
      V_ENTITY_NUM   NUMBER := P_ENTITY_NUM;
      P_BRN_CODE     MBRN.MBRN_CODE%TYPE;
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

      SELECT TO_NUMBER (I.PARAMETER_VALUE)
        INTO P_BRN_CODE
        FROM TB_INTERNAL_INFO I
       WHERE I.PARAMETER_NAME = 'HOST_BRN_CODE';

      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (V_ENTITY_NUM, P_BRN_CODE);
      V_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      W_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

         IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (V_ENTITY_NUM,
                                                         L_BRN_CODE) = FALSE
         THEN
            SP_REVARSE_GL (V_ENTITY_NUM, L_BRN_CODE);

            W_ERROR_CODE := PKG_EODSOD_FLAGS.PV_ERROR_MSG;

            IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
            THEN
               PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (V_ENTITY_NUM,
                                                                L_BRN_CODE);
               PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (V_ENTITY_NUM);
            END IF;
         END IF;
      END LOOP;
   --PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (V_ENTITY_NUM);
   END START_BRNWISE;
END PKG_GAIN_GL_TRF;
/
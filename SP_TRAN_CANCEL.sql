CREATE OR REPLACE PROCEDURE SP_TRAN_CANCEL (P_ENTITY_NUM         NUMBER,
                                            P_BRANCH_CODE        NUMBER,
                                            P_TRAN_DATE          DATE,
                                            P_BATCH_NUMBER       NUMBER,
                                            P_USER_ID            VARCHAR2,
                                            P_ERROR_MSG      OUT VARCHAR2)
IS
   V_SQL              VARCHAR2 (4000);
   W_ERR_CODE         VARCHAR2 (4000);
   W_ERROR            VARCHAR2 (4000);
   W_BATCH_NUM        NUMBER;
   V_USER_EXCEPTION   EXCEPTION;
   ERROR_MSG          VARCHAR2 (4000);
BEGIN
   BEGIN
     <<INIT_TRAN>>
      PKG_AUTOPOST.pv_userid := P_USER_ID;
      PKG_AUTOPOST.PV_BOPAUTHQ_REQ := FALSE;
      PKG_AUTOPOST.PV_AUTH_DTLS_UPDATE_REQ := FALSE;
      PKG_AUTOPOST.PV_CALLED_BY_EOD_SOD := '0';
      PKG_AUTOPOST.PV_EXCEP_CHECK_NOT_REQD := FALSE;
      PKG_AUTOPOST.PV_OVERDRAFT_CHK_REQD := FALSE;
      PKG_AUTOPOST.PV_ALLOW_ZERO_TRANAMT := FALSE;
      PKG_PROCESS_BOPAUTHQ.V_BOPAUTHQ_UPD := FALSE;
      PKG_AUTOPOST.PV_CANCEL_FLAG := TRUE;
      PKG_AUTOPOST.pv_post_as_unauth_mod := FALSE;
      PKG_AUTOPOST.pv_clg_batch_closure := FALSE;
      PKG_AUTOPOST.pv_authorized_record_cancel := TRUE;
      PKG_AUTOPOST.PV_BACKDATED_TRAN_REQUIRED := 1;
      PKG_AUTOPOST.PV_CLG_REGN_POSTING := FALSE;
      PKG_AUTOPOST.pv_fresh_batch_sl := FALSE;
      PKG_AUTOPOST.pv_tran_key.Tran_Brn_Code := P_BRANCH_CODE;
      PKG_AUTOPOST.pv_tran_key.Tran_Date_Of_Tran := P_TRAN_DATE;
      PKG_AUTOPOST.pv_tran_key.Tran_Batch_Number := P_BATCH_NUMBER;
      --PKG_AUTOPOST.pv_tran_key.Tran_Batch_Sl_Num  :=
      PKG_AUTOPOST.PV_AUTO_AUTHORISE := TRUE;
      PKG_PB_GLOBAL.G_TERMINAL_ID := '127.0.0.1';
      --PKG_PB_GLOBAL.G_USER_OPTION := 'M';
      PKG_POST_INTERFACE.G_BATCH_NUMBER_UPDATE_REQ := FALSE;
      PKG_POST_INTERFACE.G_SRC_TABLE_AUTH_REJ_REQ := TRUE;
      PKG_AUTOPOST.PV_TRAN_ONLY_UNDO := FALSE;
      PKG_AUTOPOST.PV_OCLG_POSTING_FLG := FALSE;
      PKG_POST_INTERFACE.G_IBR_REQUIRED := 1;
      PKG_PB_AUTOPOST.G_FORM_NAME := 'ETRAN';
      PKG_POST_INTERFACE.G_PGM_NAME := 'ETRAN';
      PKG_AUTOPOST.PV_USER_ROLE_CODE := '';
      --PKG_AUTOPOST.PV_TRANBAT.TRANBAT_CANCEL_REM1 := 'Wrong Voucher';
      PKG_AUTOPOST.PV_SUPP_TRAN_POST := FALSE;
      PKG_AUTOPOST.PV_FUTURE_TRANSACTION_ALLOWED := FALSE;
   END INIT_TRAN;

  <<TRAN_POSTING>>
   BEGIN
      PKG_POST_INTERFACE.SP_AUTOPOSTTRAN (P_ENTITY_NUM,        --Entity Number
                                          'M',                     --User Mode
                                          0,              --No of transactions
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



      IF    (TRIM (W_ERR_CODE) IS NOT NULL AND TRIM (W_ERR_CODE) <> '0000')
         OR TRIM (W_ERROR) IS NOT NULL
         OR W_BATCH_NUM <> P_BATCH_NUMBER
      THEN
         ERROR_MSG :=
               CASE
                  WHEN     TRIM (W_ERR_CODE) IS NOT NULL
                       AND TRIM (W_ERR_CODE) <> '0000'
                  THEN
                     TRIM (W_ERR_CODE)
                  ELSE
                     ''
               END
            || CASE
                  WHEN (    TRIM (W_ERR_CODE) IS NOT NULL
                        AND TRIM (W_ERR_CODE) <> '0000'
                        AND TRIM (W_ERROR) IS NOT NULL)
                  THEN
                     '|' || TRIM (W_ERROR)
                  ELSE
                     ''
               END
            || '|'
            || SQLERRM;

         IF TRIM (FN_GET_AUTOPOST_ERR_MSG (P_ENTITY_NUM)) IS NOT NULL
         THEN
            ERROR_MSG :=
               TRIM (
                  FN_GET_AUTOPOST_ERR_MSG (P_ENTITY_NUM) || '|' || ERROR_MSG);
         END IF;
      END IF;



      IF ERROR_MSG IS NOT NULL
      THEN
         P_ERROR_MSG := ERROR_MSG;

         ROLLBACK;

   --      RAISE V_USER_EXCEPTION;
      ELSE
         BEGIN
           <<UPDATE_BOPAUTHQ>>
            V_SQL :=
                  'UPDATE BOPAUTHQ SET BOPAUTHQ_ENTRY_STATUS = ''R'', 
                                      BOPAUTHQ_FINAL_AUTH_REJ_BY='''
               || P_USER_ID
               || ''', BOPAUTHQ_FINAL_AUTH_REJ_ON = SYSDATE, 
                                      BOPAUTHQ_FINAL_AUTH_STATUS=''R'' 
                     WHERE BOPAUTHQ_ENTITY_NUM =  '
               || P_ENTITY_NUM
               || ' AND  BOPAUTHQ_TRAN_BRN_CODE='
               || P_BRANCH_CODE
               || ' AND BOPAUTHQ_TRAN_DATE_OF_TRAN= '''
               || P_TRAN_DATE
               || ''' AND BOPAUTHQ_TRAN_BATCH_NUMBER ='
               || P_BATCH_NUMBER;
            DBMS_OUTPUT.PUT_LINE (V_SQL);

            EXECUTE IMMEDIATE V_SQL;
         END UPDATE_BOPAUTHQ;

         BEGIN
           <<UPDATE_TRANBAT>>
            V_SQL :=
                  'UPDATE TRANBAT2019 SET TRANBAT_CANCEL_REM1 = ''transaction reversal'', TRANBAT_CANCEL_REM2 ='''', TRANBAT_CANCEL_REM3=''''
                    WHERE  TRANBAT_ENTITY_NUM ='
               || P_ENTITY_NUM
               || ' AND  TRANBAT_BRN_CODE='
               || P_BRANCH_CODE
               || ' AND TRANBAT_DATE_OF_TRAN= '''
               || P_TRAN_DATE
               || ''' AND TRANBAT_BATCH_NUMBER ='
               || P_BATCH_NUMBER;
            DBMS_OUTPUT.PUT_LINE (V_SQL);

            EXECUTE IMMEDIATE V_SQL;
         END UPDATE_TRANBAT;

         P_ERROR_MSG := ERROR_MSG;

         COMMIT;
      END IF;
   END TRAN_POSTING;
EXCEPTION
   WHEN OTHERS
   THEN
      IF ERROR_MSG IS NULL
      THEN
         P_ERROR_MSG := ERROR_MSG || ' | ' || SQLERRM;
      END IF;

      ROLLBACK;

--      RAISE V_USER_EXCEPTION;
END SP_TRAN_CANCEL;
/

CREATE OR REPLACE PACKAGE PKG_LNINSTRECOV
IS
   PROCEDURE SP_LNINSTRECOV (V_ENTITY_NUM       IN NUMBER,
                             P_BRN_CODE         IN NUMBER DEFAULT 0,
                             P_PROD_CODE        IN NUMBER DEFAULT 0,
                             P_INTERNAL_ACNUM   IN NUMBER DEFAULT 0);

   PROCEDURE START_BRNWISE (V_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0);
END PKG_LNINSTRECOV;
/
CREATE OR REPLACE PACKAGE BODY PKG_LNINSTRECOV
IS
   E_USEREXCEP                      EXCEPTION;

   TYPE TY_LNP_REC IS RECORD
   (
      V_BRN_CODE              NUMBER (6),
      V_PROD_CODE             NUMBER (4),
      V_INTERNAL_ACNUM        NUMBER (14),
      V_ACNTS_CLIENT_NUM      CLIENTS.CLIENTS_CODE%TYPE,
      V_ACNTS_CURR_CODE       VARCHAR2 (6),
      V_RECOV_ACNT_NUM        NUMBER (14),
      V_HOVERING_REQD         CHAR (1),
      V_HOVERING_TYPE         VARCHAR2 (6),
      V_HOVER_START_DAYS      NUMBER (2),
      V_INT_RECOVERY_OPTION   CHAR (1),
      V_LMTLINE_NUM           LIMITLINE.LMTLINE_NUM%TYPE,
      V_LMT_EXPIRY_DATE       DATE,
      V_MIG_DATE              DATE,
      V_CLOSURE_DATE          DATE,
      V_REC_PROD_CODE         PRODUCTS.PRODUCT_CODE%TYPE,
      V_REC_CURR_CODE         CURRENCY.CURR_CODE%TYPE,
      V_PRODUCT_FOR_LOANS     PRODUCTS.PRODUCT_FOR_LOANS%TYPE
   );



   TYPE TAB_LNP_REC IS TABLE OF TY_LNP_REC
      INDEX BY PLS_INTEGER;

   LNP_REC                          TAB_LNP_REC;

   TYPE TY_TEMP_REC IS RECORD
   (
      V_INSTRECV_TMP_SER             NUMBER (6),
      V_INSTRECV_LOAN_ACNT_NUM       NUMBER (14),
      V_INSTRECV_ACNTS_BRN_CODE      NUMBER (6),
      V_INSTRECV_REPAY_CURR          VARCHAR2 (3),
      V_INSTRECV_INSTALLMENT_AMT     NUMBER (18, 3),
      V_INSTRECV_REPAY_AMOUNT        NUMBER (18, 3),
      V_INSTRECV_RECOV_ACNT_NUM      NUMBER (14),
      V_INSTRECV_RECOV_AC_LOAN_FLG   CHAR (1),
      V_INSTRECV_LOAN_BAL            NUMBER (18, 3),
      V_INSTRECV_PRIN_OS_BAL         NUMBER (18, 3),
      V_INSTRECV_INT_OS_BAL          NUMBER (18, 3),
      V_INSTRECV_CHG_OS_BAL          NUMBER (18, 3),
      V_INSTRECV_EQU_INST_FLG        CHAR (1),
      V_INSTRECV_REPAY_DATE          DATE,
      V_INSTRECV_PRIN_RECOV_AMT      NUMBER (18, 3),
      V_INSTRECV_INT_RECOV_AMT       NUMBER (18, 3),
      V_INSTRECV_CHG_RECOV_AMT       NUMBER (18, 3)
   );

   TYPE TAB_TEMP_REC IS TABLE OF TY_TEMP_REC
      INDEX BY PLS_INTEGER;

   TEMP_REC                         TAB_TEMP_REC;

   V_TEMP_INDX                      NUMBER := 0;
   V_TEMPDTL_INDX                   NUMBER := 0;
   W_ENTITY_CODE                    NUMBER;

   TYPE TY_TEMPDTL_REC IS RECORD
   (
      V_INSTRECVDT_TMP_SER          NUMBER (6),
      V_INSTRECVDT_INTERNAL_ACNUM   NUMBER (14),
      V_INSTRECVDT_SL_NUM           NUMBER (3),
      V_INSTRECVDT_RECOV_ACNUM      NUMBER (14),
      V_INSTRECVDT_RECOV_AMT        NUMBER (18, 3)
   );

   TYPE TAB_TEMPDTL_REC IS TABLE OF TY_TEMPDTL_REC
      INDEX BY PLS_INTEGER;

   TEMPDTL_REC                      TAB_TEMPDTL_REC;



   TYPE TY_CRS_REC IS RECORD
   (
      V_DTL_REPAY_AMT_CURR       VARCHAR2 (3),
      V_DTL_REPAY_AMT            NUMBER (18, 3),
      V_DTL_REPAY_FREQ           CHAR (1),
      V_DTL_REPAY_FROM_DATE      DATE,
      V_DTL_NUM_OF_INSTALLMENT   NUMBER (5)
   );

   TYPE TAB_CRS_REC IS TABLE OF TY_CRS_REC
      INDEX BY PLS_INTEGER;

   CRS_REC                          TAB_CRS_REC;

   TYPE TY_RECOV_REC IS RECORD
   (
      V_RECOV_ACNT_NUM   NUMBER (14),
      V_REPAY_AMT        NUMBER (18, 3)
   );

   TYPE TAB_RECOV_REC IS TABLE OF TY_RECOV_REC
      INDEX BY PLS_INTEGER;

   RECOV_REC                        TAB_RECOV_REC;
   V_ASON_DATE                      DATE;
   W_ERR_MSG                        VARCHAR2 (1000);
   L_BRN_CODE                       NUMBER (6);


   PROCEDURE CHECK_ACNT;

   PROCEDURE CHECK_REPAY_DTL;

   --PROCEDURE CHECK_REPAY_DATE_NEXT;
   --PROCEDURE CHECK_REPAY_DATE_SUB;
   --PROCEDURE CHECK_REPAY_DATE_ACT;
   --PROCEDURE CHECK_PROC_DATE;

   PROCEDURE UPD_LNINSTRECV_ERR;

   PROCEDURE PROCEED_RECOV_SUB;

   PROCEDURE CHECK_LOAN_BALANCE;

   PROCEDURE CHECK_RECOV_ACNT_BALANCE;

   PROCEDURE UPDATE_RTMPINSTRECV;

   PROCEDURE POST_TRAN;

   PROCEDURE POST_PARA;

   PROCEDURE AUTOPOST_ARRAY_ASSIGN;

   PROCEDURE SET_CREDIT_VOUCHER;

   PROCEDURE UPDATE_LNINSTRECV;

   PROCEDURE UPDATE_LNINSTRECVDTL;

   PROCEDURE SET_TRAN_KEY_VALUES;

   PROCEDURE SET_TRANBAT_VALUES;

   PROCEDURE GET_TRAN_BREAKUP;

   PROCEDURE GET_TRAN_BREAKUP_3;

   PROCEDURE GET_TRAN_BREAKUP_2;

   PROCEDURE GET_TRAN_BREAKUP_1;

   PROCEDURE CHECK_RECOV_BRKUP;

   PROCEDURE MARK_HOVERING;

   --PROCEDURE CHECK_OTHER_ACNTS;

   PROCEDURE CALL_SP_AVLBAL (L_REC_ACNT_NUM IN NUMBER);

   PROCEDURE SET_DEBIT_VOUCHER_NEW;

   W_CBD                            DATE;
   W_ERROR                          VARCHAR2 (1300);
   W_BRN_CODE                       NUMBER (6);
   W_PROD_CODE                      NUMBER (4);
   W_INTERNAL_ACNUM                 NUMBER (14);
   W_PROC_DATE                      DATE;
   --W_STORE_PROC_DATE                DATE;
   --W_PROC_BY                        VARCHAR2 (8);
   W_SQL                            VARCHAR2 (4300);
   W_RECOV_ACNT_NUM                 NUMBER (14);
   W_HOVERING_REQD                  CHAR (1);
   W_HOVERING_TYPE                  VARCHAR2 (6);
   W_HOVER_START_DAYS               NUMBER (2);
   W_ASSET_CLASS                    CHAR (1);
   W_AUTO_RECOV                     CHAR (1);
   W_REPAY_AMOUNT                   NUMBER (18, 3);
   W_QUIT                           CHAR (1);
   W_EXIT                           CHAR (1);
   W_REPAY_AMT_CURR                 VARCHAR2 (3);
   W_ERR_MESSAGE                    VARCHAR2 (100);
   W_TMP_PROC_DATE                  DATE;
   W_REPAY_START_DATE               DATE;
   W_REPAY_FREQ                     CHAR (1);
   W_NOF_INSTALL                    NUMBER;
   W_ADD_NOF_MON                    NUMBER;
   W_REPAY_END_DATE                 DATE;
   W_PROC_MON                       NUMBER;
   W_REPAY_MON                      NUMBER;
   W_FACTOR                         NUMBER;
   W_DIFF                           NUMBER;
   W_REM                            NUMBER;
   W_USER_ID                        VARCHAR2 (8);
   W_CBD_TIME                       VARCHAR2 (20);
   W_DUMMY_D                        DATE;
   W_EQU_INST_FLG                   CHAR (1);
   W_CLOSURE_DATE                   DATE;
   W_DUMMY_V                        VARCHAR2 (10);
   W_DUMMY_N                        NUMBER;
   W_AC_AUTH_BAL                    NUMBER;
   W_AC_BAL                         NUMBER;
   W_PRIN_AC_BAL                    NUMBER;
   W_INT_AC_BAL                     NUMBER;
   W_CHG_AC_BAL                     NUMBER;
   W_TOT_LOAN_BAL                   NUMBER;
   W_REC_PROD_CODE                  NUMBER;
   W_FOR_LOANS                      CHAR (1);
   W_TEMP_SER                       NUMBER;
   W_PREV_BRN_CODE                  NUMBER;
   W_RTMPINSTRECV_LOAN_ACNT_NUM     NUMBER (14);
   W_RTMPINSTRECV_ACNTS_BRN_CODE    NUMBER (6);
   W_RTMPINSTRECV_REPAY_CURR        VARCHAR2 (3);
   W_RTMPINSTRECV_REPAY_AMOUNT      NUMBER (18, 3);
   W_RTMPINSTRECV_RECOV_ACNT_NUM    NUMBER (14);
   W_RTMPINSTRECV_AC_LOAN_FLG       CHAR (1);
   W_RTMPINSTRECV_LOAN_BAL          NUMBER (18, 3);
   W_RTMPINSTRECV_PRIN_OS_BAL       NUMBER (18, 3);
   W_RTMPINSTRECV_INT_OS_BAL        NUMBER (18, 3);
   W_RTMPINSTRECV_CHG_OS_BAL        NUMBER (18, 3);
   W_RTMPINSTRECV_EQU_INST_FLG      CHAR (1);
   W_RTMPINSTRECV_REPAY_DATE        DATE;
   W_RTMPINSTRECV_PRIN_RECOV_AMT    NUMBER;
   W_RTMPINSTRECV_INT_RECOV_AMT     NUMBER;
   W_RTMPINSTRECV_CHG_RECOV_AMT     NUMBER;
   IDX                              NUMBER;
   IDX1                             NUMBER;
   W_ERR_CODE                       VARCHAR2 (10);
   W_BATCH_NUMBER                   NUMBER (7);
   W_INT_RECOVERY_OPTION            CHAR (1);
   W_PRIN_REC_AMT                   NUMBER;
   W_INT_REC_AMT                    NUMBER;
   W_CHG_REC_AMT                    NUMBER;
   W_INT_NOT_DUE_AMT                NUMBER;
   W_HOVER_BRN_CODE                 NUMBER;
   W_HOVER_YEAR                     NUMBER;
   W_HOVER_SL_NUM                   NUMBER;
   W_REC_CURR_CODE                  VARCHAR2 (3);
   W_PRODUCT_FOR_LOAN               PRODUCTS.PRODUCT_FOR_LOANS%TYPE;
   W_AMT_OD                         NUMBER (18, 3);
   W_SUS_BAL                        NUMBER (18, 3);
   W_REC_AC_AVL_BAL                 NUMBER (18, 3);
   REC_IDX                          NUMBER;
   W_CHK_REC_AVAL_BAL               NUMBER (18, 3);
   W_REC_AC_AUTH_BAL                NUMBER (18, 3);
   W_REQD_BAL                       NUMBER (18, 3);

   W_INSTALLMENT_AMT                NUMBER (18, 3);
   w_hovering_amt                   NUMBER (18, 3);
   w_partial_recovery               NUMBER (18, 3);
   W_RTMPINSTRECV_INSTALLMENT_AMT   NUMBER (18, 3);

   W_BREAKUP_ERR                    NUMBER (1);
   W_LMT_EXPIRY_DATE                DATE;
   W_MIG_DATE                       DATE;
   W_ACNTS_CLIENT_NUM               CLIENTS.CLIENTS_CODE%TYPE;
   W_LMTLINE_NUM                    LIMITLINE.LMTLINE_NUM%TYPE;


   PROCEDURE INIT_PARA
   IS
   BEGIN
      W_CBD := NULL;
      W_ERROR := '';
      W_BRN_CODE := 0;
      W_PROD_CODE := 0;
      W_INTERNAL_ACNUM := 0;
      W_PROC_DATE := NULL;
      --W_STORE_PROC_DATE := NULL;
      --W_PROC_BY := '';
      W_SQL := '';
      W_RECOV_ACNT_NUM := 0;
      W_HOVERING_REQD := '';
      W_HOVERING_TYPE := '';
      W_HOVER_START_DAYS := 0;
      W_ASSET_CLASS := '';
      W_AUTO_RECOV := '0';
      W_REPAY_AMOUNT := 0;
      W_QUIT := '0';
      W_EXIT := '0';
      W_REPAY_AMT_CURR := '';
      W_ERR_MESSAGE := '';
      W_TMP_PROC_DATE := NULL;
      W_REPAY_START_DATE := NULL;
      W_REPAY_FREQ := '';
      W_NOF_INSTALL := 0;
      W_ADD_NOF_MON := 0;
      W_REPAY_END_DATE := NULL;
      W_PROC_MON := 0;
      W_REPAY_MON := 0;
      W_FACTOR := 0;
      W_DIFF := 0;
      W_PRODUCT_FOR_LOAN := 0;
      W_REM := 0;
      W_DUMMY_D := NULL;
      W_EQU_INST_FLG := '';
      W_CLOSURE_DATE := NULL;
      W_DUMMY_V := '';
      W_DUMMY_N := 0;
      W_AC_AUTH_BAL := 0;
      W_AC_BAL := 0;
      W_PRIN_AC_BAL := 0;
      W_INT_AC_BAL := 0;
      W_CHG_AC_BAL := 0;
      W_TOT_LOAN_BAL := 0;
      W_REC_PROD_CODE := 0;
      W_FOR_LOANS := 0;
      W_TEMP_SER := 0;
      W_PREV_BRN_CODE := 0;
      W_RTMPINSTRECV_LOAN_ACNT_NUM := 0;
      W_RTMPINSTRECV_ACNTS_BRN_CODE := 0;
      W_RTMPINSTRECV_REPAY_CURR := '';
      W_RTMPINSTRECV_REPAY_AMOUNT := 0;
      W_RTMPINSTRECV_RECOV_ACNT_NUM := 0;
      W_RTMPINSTRECV_AC_LOAN_FLG := '';
      W_RTMPINSTRECV_LOAN_BAL := 0;
      W_RTMPINSTRECV_PRIN_OS_BAL := 0;
      W_RTMPINSTRECV_INT_OS_BAL := 0;
      W_RTMPINSTRECV_CHG_OS_BAL := 0;
      W_RTMPINSTRECV_EQU_INST_FLG := 0;
      W_RTMPINSTRECV_REPAY_DATE := NULL;
      W_RTMPINSTRECV_PRIN_RECOV_AMT := 0;
      W_RTMPINSTRECV_INT_RECOV_AMT := 0;
      W_RTMPINSTRECV_CHG_RECOV_AMT := 0;
      IDX := 0;
      IDX1 := 0;
      W_ERR_CODE := '';
      W_BATCH_NUMBER := 0;
      W_INT_RECOVERY_OPTION := '';
      W_PRIN_REC_AMT := 0;
      W_INT_REC_AMT := 0;
      W_CHG_REC_AMT := 0;
      W_INT_NOT_DUE_AMT := 0;
      W_HOVER_BRN_CODE := 0;
      W_HOVER_YEAR := 0;
      W_HOVER_SL_NUM := 0;
      W_REC_CURR_CODE := '';

      W_REC_AC_AVL_BAL := 0;
      REC_IDX := 0;
      W_CHK_REC_AVAL_BAL := 0;
      W_REC_AC_AUTH_BAL := 0;
      W_AMT_OD := 0;
      W_SUS_BAL := 0;
      W_INSTALLMENT_AMT := 0;
      w_partial_recovery := 0;
      w_hovering_amt := 0;
      W_RTMPINSTRECV_INSTALLMENT_AMT := 0;
      W_BREAKUP_ERR := 0;
      W_LMT_EXPIRY_DATE := NULL;
      W_MIG_DATE := NULL;
      W_ACNTS_CLIENT_NUM := 0;
      W_LMTLINE_NUM := 0;
      V_TEMP_INDX := 0;
      V_TEMPDTL_INDX := 0;
   END;


   PROCEDURE READ_RECOVERY_LOANS
   IS
   BEGIN
      W_SQL :=
         'SELECT ACNTS_BRN_CODE,ACNTS_PROD_CODE,ACNTS_INTERNAL_ACNUM,ACNTS_CLIENT_NUM,ACNTS_CURR_CODE,LNACNT_RECOV_ACNT_NUM,LNPRD_HOVERING_REQD,
        LNPRD_HOVERING_TYPE,LNPRD_HOVER_START_DAYS,LNPRD_INT_RECOVERY_OPTION,LMTLINE_NUM,LMTLINE_LIMIT_EXPIRY_DATE,MIG_END_DATE,
        (SELECT ACNTS_CLOSURE_DATE FROM ACNTS WHERE ACNTS_ENTITY_NUM = :1 AND ACNTS_INTERNAL_ACNUM = LNACNT_RECOV_ACNT_NUM ) ACNTS_CLOSURE_DATE,
        NULL PRODUCT_CODE ,
        (SELECT ACNTS_CURR_CODE FROM ACNTS WHERE ACNTS_ENTITY_NUM = :2 AND ACNTS_INTERNAL_ACNUM = LNACNT_RECOV_ACNT_NUM ) ACNTS_CURR_CODE,
        (SELECT PRODUCT_FOR_LOANS FROM ACNTS, PRODUCTS WHERE ACNTS_ENTITY_NUM = :2 AND ACNTS_INTERNAL_ACNUM = LNACNT_RECOV_ACNT_NUM AND ACNTS_PROD_CODE = PRODUCT_CODE) PRODUCT_FOR_LOANS
        FROM LOANACNTS,ACNTS,LNPRODPM,PRODUCTS,ACASLLDTL,LIMITLINE,MIG_DETAIL
         WHERE ACNTS_ENTITY_NUM = :3
         AND ACASLLDTL_ENTITY_NUM = :4
         AND LMTLINE_ENTITY_NUM = :5
         AND ACASLLDTL_INTERNAL_ACNUM = ACNTS_INTERNAL_ACNUM
         AND BRANCH_CODE = ACNTS_BRN_CODE
         AND ACASLLDTL_CLIENT_NUM = LMTLINE_CLIENT_CODE
         AND LMTLINE_NUM = ACASLLDTL_LIMIT_LINE_NUM
         AND LNACNT_ENTITY_NUM = :6 AND  ACNTS_CLOSURE_DATE IS NULL AND ACNTS_PROD_CODE = PRODUCT_CODE AND ACNTS_PROD_CODE = LNPRD_PROD_CODE
        AND ACNTS_INTERNAL_ACNUM = LNACNT_INTERNAL_ACNUM AND PRODUCT_FOR_RUN_ACS <> ''1'' AND LNPRD_TERM_LOAN = ''1''
        AND LNACNT_AUTO_INSTALL_RECOV_REQD = ''1'' AND LNACNT_RECOV_ACNT_NUM > 0';

      IF (W_BRN_CODE > 0)
      THEN
         W_SQL := W_SQL || ' AND ACNTS_BRN_CODE = ' || W_BRN_CODE;
      END IF;

      IF (W_PROD_CODE > 0)
      THEN
         W_SQL := W_SQL || ' AND ACNTS_PROD_CODE = ' || W_PROD_CODE;
      END IF;

      IF (W_INTERNAL_ACNUM > 0)
      THEN
         W_SQL := W_SQL || ' AND ACNTS_INTERNAL_ACNUM = ' || W_INTERNAL_ACNUM;
      END IF;

      W_SQL := W_SQL || '
      ORDER BY ACNTS_INTERNAL_ACNUM';


      EXECUTE IMMEDIATE W_SQL
         BULK COLLECT INTO LNP_REC
         USING W_ENTITY_CODE,
               W_ENTITY_CODE,
               W_ENTITY_CODE,
               W_ENTITY_CODE,
               W_ENTITY_CODE,
               W_ENTITY_CODE,
               W_ENTITY_CODE;

      IF LNP_REC.FIRST IS NOT NULL
      THEN
         FOR J IN LNP_REC.FIRST .. LNP_REC.LAST
         LOOP
            W_BRN_CODE := LNP_REC (J).V_BRN_CODE;
            W_PROD_CODE := LNP_REC (J).V_PROD_CODE;
            W_INTERNAL_ACNUM := LNP_REC (J).V_INTERNAL_ACNUM;
            W_REPAY_AMT_CURR := LNP_REC (J).V_ACNTS_CURR_CODE;
            W_RECOV_ACNT_NUM := LNP_REC (J).V_RECOV_ACNT_NUM;
            W_HOVERING_REQD := LNP_REC (J).V_HOVERING_REQD;
            W_HOVERING_TYPE := LNP_REC (J).V_HOVERING_TYPE;
            W_HOVER_START_DAYS := LNP_REC (J).V_HOVER_START_DAYS;
            W_INT_RECOVERY_OPTION := LNP_REC (J).V_INT_RECOVERY_OPTION;
            W_LMT_EXPIRY_DATE := LNP_REC (J).V_LMT_EXPIRY_DATE;
            W_MIG_DATE := LNP_REC (J).V_MIG_DATE;
            W_ACNTS_CLIENT_NUM := LNP_REC (J).V_ACNTS_CLIENT_NUM;
            W_LMTLINE_NUM := LNP_REC (J).V_LMTLINE_NUM;

            W_HOVER_BRN_CODE := 0;
            W_HOVER_YEAR := 0;
            W_HOVER_SL_NUM := 0;
            W_CLOSURE_DATE := LNP_REC (J).V_CLOSURE_DATE;
            W_REC_PROD_CODE := LNP_REC (J).V_REC_PROD_CODE;
            W_REC_CURR_CODE := LNP_REC (J).V_REC_CURR_CODE;
            W_PRODUCT_FOR_LOAN := LNP_REC (J).V_PRODUCT_FOR_LOANS;
            CHECK_ACNT;
         END LOOP;
      END IF;

      POST_TRAN;
   END;

   PROCEDURE CHECK_ACNT
   IS
   BEGIN
      -- Check For Suspense Balance
      PKG_LNSUSPASON.SP_LNSUSPASON (W_ENTITY_CODE,
                                    W_INTERNAL_ACNUM,
                                    W_REPAY_AMT_CURR,
                                    TO_CHAR (W_CBD, 'DD-MON-YYYY'),
                                    W_ERROR,
                                    W_DUMMY_N,
                                    W_DUMMY_N,
                                    W_SUS_BAL,
                                    W_DUMMY_N,
                                    W_DUMMY_N,
                                    W_DUMMY_N,
                                    W_DUMMY_N,
                                    W_DUMMY_N,
                                    W_DUMMY_N,
                                    W_DUMMY_N,
                                    W_DUMMY_N);

      IF (W_SUS_BAL = 0)
      THEN
         CHECK_REPAY_DTL;
         PROCEED_RECOV_SUB;
      END IF;
   END;

   PROCEDURE CHECK_REPAY_DTL
   IS
   BEGIN
      W_AUTO_RECOV := 0;
      W_REPAY_AMOUNT := 0;
      W_QUIT := 0;
      W_EXIT := 0;
      W_PROC_DATE := W_CBD;

      W_SQL :=
            'SELECT LNACRSDTL_REPAY_AMT_CURR, LNACRSDTL_REPAY_AMT,LNACRSDTL_REPAY_FREQ,LNACRSDTL_REPAY_FROM_DATE,LNACRSDTL_NUM_OF_INSTALLMENT FROM LNACRSDTL WHERE LNACRSDTL_ENTITY_NUM = :1 AND  LNACRSDTL_INTERNAL_ACNUM = '
         || W_INTERNAL_ACNUM
         || ' AND LNACRSDTL_REPAY_FREQ <> ''X''
         ORDER BY LNACRSDTL_SL_NUM';

      EXECUTE IMMEDIATE W_SQL BULK COLLECT INTO CRS_REC USING W_ENTITY_CODE;


      IF CRS_REC.FIRST IS NOT NULL
      THEN
         FOR J IN CRS_REC.FIRST .. CRS_REC.LAST
         LOOP
            W_REPAY_AMT_CURR := CRS_REC (J).V_DTL_REPAY_AMT_CURR;
            W_REPAY_FREQ := CRS_REC (J).V_DTL_REPAY_FREQ;
            W_REPAY_AMOUNT := CRS_REC (J).V_DTL_REPAY_AMT;
            W_REPAY_START_DATE := CRS_REC (J).V_DTL_REPAY_FROM_DATE;
            W_INSTALLMENT_AMT := CRS_REC (J).V_DTL_REPAY_AMT;
            W_NOF_INSTALL := CRS_REC (J).V_DTL_NUM_OF_INSTALLMENT;
         END LOOP;
      ELSE
         W_REPAY_AMOUNT := 0;
         W_REPAY_AMT_CURR := '';
         W_ERR_MESSAGE := 'Repayment Schedule Not Defined ';
         --UPD_LNINSTRECV_ERR;
         W_EXIT := 1;
      END IF;
   END;

   FUNCTION FN_GET_DUE_AMT
      RETURN NUMBER
   AS
      V_PAYABLE_AMT   NUMBER (18, 3);
      V_OS_BALANCE    NUMBER (18, 3);
      V_DISB_AMT      NUMBER (18, 3);
      V_INT_DB_MIG    NUMBER (18, 3);
      V_INT_DB_CBS    NUMBER (18, 3);
      V_CHG_DB_CBS    NUMBER (18, 3);
      V_DUE_AMOUNT    NUMBER (18, 3);
   BEGIN
      V_PAYABLE_AMT := 0;
      V_OS_BALANCE := 0;
      V_DISB_AMT := 0;
      V_INT_DB_MIG := 0;
      V_INT_DB_CBS := 0;
      V_CHG_DB_CBS := 0;
      V_DUE_AMOUNT := 0;

      IF W_REPAY_START_DATE > W_CBD
      THEN
         V_DUE_AMOUNT := 0;
         RETURN V_DUE_AMOUNT;
      END IF;

      SELECT ABS (SUM (LLACNTOS_LIMIT_CURR_DISB_MADE)), SUM (ACNTBAL_AC_BAL)
        INTO V_DISB_AMT, V_OS_BALANCE
        FROM LLACNTOS L, ACNTBAL A
       WHERE     L.LLACNTOS_ENTITY_NUM = 1
             AND L.LLACNTOS_CLIENT_CODE = W_ACNTS_CLIENT_NUM
             AND L.LLACNTOS_LIMIT_LINE_NUM = W_LMTLINE_NUM
             AND L.LLACNTOS_CLIENT_ACNUM = W_INTERNAL_ACNUM
             AND A.ACNTBAL_INTERNAL_ACNUM = L.LLACNTOS_CLIENT_ACNUM;


      SELECT SUM (NVL (L.LNTOTINTDB_TOT_INT_DB_AMT, 0))
        INTO V_INT_DB_MIG
        FROM LNTOTINTDBMIG L
       WHERE     L.LNTOTINTDB_ENTITY_NUM = 1
             AND L.LNTOTINTDB_INTERNAL_ACNUM = W_INTERNAL_ACNUM;

      IF V_INT_DB_MIG IS NULL
      THEN
         V_INT_DB_MIG := 0;
      END IF;

      IF V_OS_BALANCE > 0
      THEN
         V_DUE_AMOUNT := 0;
      ELSIF W_LMT_EXPIRY_DATE <= W_CBD
      THEN
         V_DUE_AMOUNT := ABS (V_OS_BALANCE);
      ELSE
         V_PAYABLE_AMT :=
            (  FLOOR ( (MONTHS_BETWEEN (W_CBD, W_REPAY_START_DATE) + 1))
             * W_REPAY_AMOUNT);

         SELECT SUM (M.TRANADV_INTRD_BC_AMT), SUM (M.TRANADV_CHARGE_BC_AMT)
           INTO V_INT_DB_CBS, V_CHG_DB_CBS
           FROM MV_LOAN_ACCOUNT_BAL_OD M
          WHERE     M.TRAN_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND M.TRAN_DATE_OF_TRAN > W_MIG_DATE
                AND M.TRAN_DB_CR_FLG = 'D';

         IF V_INT_DB_CBS IS NULL
         THEN
            V_INT_DB_CBS := 0;
         END IF;

         IF V_CHG_DB_CBS IS NULL
         THEN
            V_CHG_DB_CBS := 0;
         END IF;

         V_DUE_AMOUNT :=
              V_PAYABLE_AMT
            - (  V_DISB_AMT
               + V_INT_DB_MIG
               + V_INT_DB_CBS
               + V_CHG_DB_CBS
               - ABS (V_OS_BALANCE));

         IF V_DUE_AMOUNT < 0
         THEN
            V_DUE_AMOUNT := 0;
         END IF;
      END IF;

      RETURN CEIL (V_DUE_AMOUNT);
   END FN_GET_DUE_AMT;

   /*
      PROCEDURE CHECK_REPAY_DATE_NEXT
      IS
      BEGIN
         CHECK_REPAY_DATE_SUB;

         W_TMP_PROC_DATE := W_PROC_DATE + 1;

         IF (W_TMP_PROC_DATE > W_CBD OR W_AUTO_RECOV = '1')
         THEN
            W_EXIT := 1;
         ELSE
            W_PROC_DATE := W_PROC_DATE + 1;
         END IF;
      END;

      PROCEDURE CHECK_REPAY_DATE_SUB
      IS
      BEGIN
         W_QUIT := 0;

         WHILE (W_QUIT = 0)
         LOOP
            IF CRS_REC.FIRST IS NOT NULL
            THEN
               FOR J IN CRS_REC.FIRST .. CRS_REC.LAST
               LOOP
                  IF (W_QUIT <> 0)
                  THEN
                     EXIT;
                  END IF;

                  W_REPAY_AMT_CURR := CRS_REC (J).V_DTL_REPAY_AMT_CURR;
                  W_REPAY_AMOUNT := CRS_REC (J).V_DTL_REPAY_AMT;
                  W_INSTALLMENT_AMT := CRS_REC (J).V_DTL_REPAY_AMT;
                  W_REPAY_START_DATE := CRS_REC (J).V_DTL_REPAY_FROM_DATE;
                  W_REPAY_FREQ := CRS_REC (J).V_DTL_REPAY_FREQ;
                  W_NOF_INSTALL := CRS_REC (J).V_DTL_NUM_OF_INSTALLMENT;

                  IF (W_QUIT = 0)
                  THEN
                     CHECK_REPAY_DATE_ACT;
                  END IF;
               END LOOP;

               W_QUIT := 1;
            END IF;
         END LOOP;
      END;

      PROCEDURE CHECK_REPAY_DATE_ACT
      IS
      BEGIN
         W_ADD_NOF_MON := 0;

         IF (W_REPAY_FREQ = 'M')
         THEN
            W_ADD_NOF_MON := (W_NOF_INSTALL - 1) * 1;
         ELSIF (W_REPAY_FREQ = 'Q')
         THEN
            W_ADD_NOF_MON := (W_NOF_INSTALL - 1) * 3;
         ELSIF (W_REPAY_FREQ = 'H')
         THEN
            W_ADD_NOF_MON := (W_NOF_INSTALL - 1) * 6;
         ELSIF (W_REPAY_FREQ = 'Y')
         THEN
            W_ADD_NOF_MON := (W_NOF_INSTALL - 1) * 12;
         END IF;


         W_REPAY_END_DATE := ADD_MONTHS (W_REPAY_START_DATE, W_ADD_NOF_MON);



         W_PROC_MON := TO_CHAR (W_PROC_DATE, 'MM');
         W_REPAY_MON := TO_CHAR (W_REPAY_START_DATE, 'MM');



         IF (    W_PROC_DATE >= W_REPAY_START_DATE
             AND W_PROC_DATE <= W_REPAY_END_DATE)
         THEN
            W_QUIT := 1;

            IF (TO_CHAR (W_REPAY_START_DATE, 'DD') = TO_CHAR (W_PROC_DATE, 'DD'))
            THEN
               IF (W_PROC_MON = W_REPAY_MON) OR (W_REPAY_FREQ = 'M')
               THEN
                  W_AUTO_RECOV := 1;
               ELSE
                  IF (W_REPAY_FREQ = 'Q' OR W_REPAY_FREQ = 'H')
                  THEN
                     CHECK_PROC_DATE;
                  END IF;
               END IF;
            END IF;
         END IF;
      END;

      PROCEDURE CHECK_PROC_DATE
      IS
      BEGIN
         IF (W_REPAY_FREQ = 'Q')
         THEN
            W_FACTOR := 3;
         ELSIF (W_REPAY_FREQ = 'H')
         THEN
            W_FACTOR := 6;
         END IF;

         IF (W_PROC_MON > W_REPAY_MON)
         THEN
            W_DIFF := W_PROC_MON - W_REPAY_MON;
         ELSE
            W_DIFF := W_REPAY_MON - W_PROC_MON;
         END IF;

         W_REM := MOD (W_DIFF, W_FACTOR);

         IF (W_REM = 0)
         THEN
            W_AUTO_RECOV := 1;
         END IF;
      END;
     */
   PROCEDURE UPD_LNINSTRECV_ERR
   IS
   BEGIN
      INSERT INTO LNINSTRECV (LNINSTRECV_ENTITY_NUM,
                              LNINSTRECV_INTERNAL_ACNUM,
                              LNINSTRECV_REPAY_DATE,
                              LNINSTRECV_ACNT_BRN_CODE,
                              LNINSTRECV_REPAY_CURR,
                              LNINSTRECV_INSTALLMENT_AMT,
                              LNINSTRECV_REPAY_AMT,
                              LNINSTRECV_BAL_OS_BEF_RECOV,
                              LNINSTRECV_PRIN_OS_BEF_RECOV,
                              LNINSTRECV_INT_OS_BEF_RECOV,
                              LNINSTRECV_CHG_OS_BEF_RECOV,
                              LNINSTRECV_RECOV_FROM_ACNT,
                              LNINSTRECV_RECOVERED_DATE,
                              LNINSTRECV_PRIN_RECOV_AMT,
                              LNINSTRECV_INT_RECOV_AMT,
                              LNINSTRECV_CHG_RECOV_AMT,
                              LNINSTRECV_ERR_FLAG,
                              LNINSTRECV_ERR_MSG,
                              LNINSTRECV_HOVER_BRN_CODE,
                              LNINSTRECV_HOVER_YEAR,
                              LNINSTRECV_HOVER_SL_NUM,
                              LNINSTRECV_PROC_BY,
                              LNINSTRECV_PROC_ON,
                              POST_TRAN_BRN,
                              POST_TRAN_DATE,
                              POST_TRAN_BATCH_NUM)
           VALUES (W_ENTITY_CODE,
                   W_INTERNAL_ACNUM,
                   W_PROC_DATE,
                   W_BRN_CODE,
                   W_REPAY_AMT_CURR,
                   W_INSTALLMENT_AMT,
                   W_REPAY_AMOUNT,
                   0,
                   0,
                   0,
                   0,
                   W_RECOV_ACNT_NUM,
                   W_CBD,
                   DECODE (W_BREAKUP_ERR, 1, W_PRIN_REC_AMT, 0),
                   DECODE (W_BREAKUP_ERR, 1, W_INT_REC_AMT, 0),
                   DECODE (W_BREAKUP_ERR, 1, W_CHG_REC_AMT, 0),
                   '1',
                   SUBSTR (TRIM (W_ERR_MESSAGE), 1, 50),
                   W_HOVER_BRN_CODE,
                   W_HOVER_YEAR,
                   W_HOVER_SL_NUM,
                   W_USER_ID,
                   TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'),
                   0,
                   NULL,
                   0);
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
            'Error in Creating LNINSTRECV ' || SUBSTR (SQLERRM, 1, 200);
         RAISE E_USEREXCEP;
   END;


   PROCEDURE PROCEED_RECOV_SUB
   IS
   BEGIN
      w_partial_recovery := '0';
      W_EQU_INST_FLG := 0;
      W_ERR_MESSAGE := '';

      /*   No use of the variable W_EQU_INST_FLG.
            BEGIN
               SELECT LNACRS_EQU_INSTALLMENT
                 INTO W_EQU_INST_FLG
                 FROM LNACRS
                WHERE     LNACRS_ENTITY_NUM = W_ENTITY_CODE
                      AND LNACRS_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  W_EQU_INST_FLG := 0;
            END;
      */
      BEGIN
         IF (W_CLOSURE_DATE IS NOT NULL)
         THEN
            W_ERR_MESSAGE := ' Recovery Account is closed';
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_ERROR := '';
      END;

      IF (TRIM (W_ERR_MESSAGE) IS NULL)
      THEN
         CHECK_LOAN_BALANCE;                          -- LOAN AACCOUNT BALANCE
      END IF;

      IF (TRIM (W_ERR_MESSAGE) IS NULL)
      THEN
         CHECK_RECOV_ACNT_BALANCE;                    -- SB/CA ACCOUNT BALANCE
      END IF;

      W_BREAKUP_ERR := 0;

      IF (TRIM (W_ERR_MESSAGE) IS NULL OR w_partial_recovery = '1')
      THEN
         GET_TRAN_BREAKUP;

         IF ( (  ABS (W_PRIN_REC_AMT)
               + ABS (W_INT_REC_AMT)
               + ABS (W_CHG_REC_AMT)) <> W_REPAY_AMOUNT)
         THEN
            W_BREAKUP_ERR := 1;
            W_ERR_MESSAGE :=
               'Recovery Breakup Amount Not tallying with Installment Amount';
         END IF;
      END IF;

      IF (TRIM (W_ERR_MESSAGE) IS NOT NULL AND w_partial_recovery <> '1')
      THEN
         --UPD_LNINSTRECV_ERR;
         NULL;
      END IF;

      IF (TRIM (W_ERR_MESSAGE) IS NULL OR w_partial_recovery = '1')
      THEN
         UPDATE_RTMPINSTRECV;
      END IF;
   END;

   PROCEDURE CHECK_LOAN_BALANCE
   IS
   BEGIN
      SP_AVLBAL (W_ENTITY_CODE,
                 W_INTERNAL_ACNUM,
                 W_DUMMY_V,
                 W_AC_AUTH_BAL,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_AC_BAL,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_D,
                 W_DUMMY_V,
                 W_DUMMY_D,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_ERROR,
                 W_DUMMY_V,
                 W_DUMMY_N,
                 W_PRIN_AC_BAL,
                 W_INT_AC_BAL,
                 W_CHG_AC_BAL,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 1);

      IF (TRIM (W_ERROR) IS NOT NULL)
      THEN
         RAISE E_USEREXCEP;
      END IF;

      W_TOT_LOAN_BAL := W_PRIN_AC_BAL + W_INT_AC_BAL + W_CHG_AC_BAL;

      IF (W_TOT_LOAN_BAL <> W_AC_AUTH_BAL)
      THEN
         W_ERR_MESSAGE := 'Account Balance Breakup Not Tallied';
      -- ELSIF (W_TOT_LOAN_BAL > 0) THEN
      --   W_ERR_MESSAGE := 'Account Has No Outstanding Balance for Recovery';
      -- ELSIF (ABS(W_TOT_LOAN_BAL) < W_REPAY_AMOUNT) THEN
      --   W_ERR_MESSAGE := 'Loan Account Balance is Less than Repayment Amount';
      -- ELSIF (ABS(W_PRIN_AC_BAL + W_INT_AC_BAL) < W_REPAY_AMOUNT) THEN
      --   W_ERR_MESSAGE := 'Principal+Interest O/s is Less Than Repayment Amt';
      END IF;
   END;

   PROCEDURE CHECK_USED_AMOUNT (W_USED_AMOUNT IN OUT NUMBER)
   AS
   BEGIN
      W_SQL :=
         'SELECT NVL(SUM(RTMPINSTRECVDT_RECOV_AMT),0)  FROM RTMPINSTRECVDTL WHERE
                     RTMPINSTRECVDT_TMP_SER = :1 AND
                     RTMPINSTRECVDT_RECOV_ACNUM = :2';

      EXECUTE IMMEDIATE W_SQL
         INTO W_USED_AMOUNT
         USING W_TEMP_SER, W_RECOV_ACNT_NUM;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         W_USED_AMOUNT := 0;
      WHEN OTHERS
      THEN
         IF TRIM (W_ERROR) IS NULL
         THEN
            W_ERROR :=
               'Error in CHECK_USED_AMOUNT' || SUBSTR (SQLERRM, 1, 100);
         END IF;

         RAISE E_USEREXCEP;
   END;

   PROCEDURE CHECK_RECOV_ACNT_BALANCE
   IS
      W_USED_AMOUNT                 NUMBER (18, 3) := 0;


      V_ACNTS_CURR_CODE             VARCHAR2 (3);
      W_OPENING_DATE                DATE;
      W_MIG_DATE                    DATE;
      V_ACNTS_PROD_CODE             NUMBER (4);
      V_LNPRD_INT_RECOVERY_OPTION   CHAR (1);
      W_PRODUCT_FOR_RUN_ACS         VARCHAR (1);
      W_LIMIT_EXPIRY_DATE           DATE;
      W_ACASLL_CLINET_NUM           NUMBER (12);
      W_ACASLL_LIMITLINE_NUM        NUMBER (12);
   BEGIN
      W_REC_AC_AVL_BAL := 0;
      REC_IDX := 0;
      W_CHK_REC_AVAL_BAL := 0;
      W_REC_AC_AUTH_BAL := 0;
      --W_REPAY_AMOUNT := 0;
      W_USED_AMOUNT := 0;
      CALL_SP_AVLBAL (W_RECOV_ACNT_NUM);
      W_AUTO_RECOV := 1;

      ---CALCULATE DUE AMT

      W_REPAY_AMOUNT := FN_GET_DUE_AMT;


      --*****


      CHECK_USED_AMOUNT (W_USED_AMOUNT);

      IF (W_REC_AC_AVL_BAL > W_USED_AMOUNT)
      THEN
         W_REC_AC_AVL_BAL := W_REC_AC_AVL_BAL - W_USED_AMOUNT;
      ELSE
         W_REC_AC_AVL_BAL := 0;
      END IF;

      RECOV_REC.DELETE;

      IF (W_REPAY_AMOUNT > 0 AND W_REC_AC_AVL_BAL >= W_REPAY_AMOUNT)
      THEN
         REC_IDX := REC_IDX + 1;
         RECOV_REC (REC_IDX).V_RECOV_ACNT_NUM := W_RECOV_ACNT_NUM;
         RECOV_REC (REC_IDX).V_REPAY_AMT := W_REPAY_AMOUNT;
      ELSIF (W_REC_AC_AVL_BAL < W_REPAY_AMOUNT)
      THEN
         REC_IDX := REC_IDX + 1;
         RECOV_REC (REC_IDX).V_RECOV_ACNT_NUM := W_RECOV_ACNT_NUM;
         RECOV_REC (REC_IDX).V_REPAY_AMT := W_REC_AC_AVL_BAL;
         W_CHK_REC_AVAL_BAL := W_REC_AC_AVL_BAL;
      --CHECK_OTHER_ACNTS;
      END IF;

      W_HOVERING_AMT := 0;
      W_PARTIAL_RECOVERY := '0';

      IF (W_REC_AC_AVL_BAL > 0)
      THEN
         IF (W_REC_AC_AVL_BAL < W_REPAY_AMOUNT)
         THEN
            W_HOVERING_AMT := W_REPAY_AMOUNT - W_REC_AC_AVL_BAL;
            W_REPAY_AMOUNT := W_REC_AC_AVL_BAL;
            W_ERR_MESSAGE := 'Partial Loan Recovery';
            W_PARTIAL_RECOVERY := '1';
         END IF;
      ELSE
         W_HOVERING_AMT := W_REPAY_AMOUNT;
      END IF;

      IF (W_REC_AC_AVL_BAL < W_REPAY_AMOUNT)
      THEN
         IF (W_RECOV_ACNT_NUM > 0 AND W_HOVERING_REQD = '1')
         THEN
            MARK_HOVERING;
         END IF;

         W_ERR_MESSAGE := 'Balance Not Available in Recovery Account';
      END IF;
   /*
         W_PARTIAL_RECOVERY := '0';

         IF (W_REC_AC_AVL_BAL > 0)
         THEN
            IF (W_REC_AC_AVL_BAL < W_REPAY_AMOUNT)
            THEN
               W_REPAY_AMOUNT := W_REC_AC_AVL_BAL;
               W_ERR_MESSAGE := 'Partial Loan Recovery';
               W_PARTIAL_RECOVERY := '1';
            END IF;
         ELSE
            W_HOVERING_AMT := W_REPAY_AMOUNT;
         END IF;
   */
   END;

   PROCEDURE CALL_SP_AVLBAL (L_REC_ACNT_NUM IN NUMBER)
   IS
   BEGIN
      SP_AVLBAL (W_ENTITY_CODE,
                 L_REC_ACNT_NUM,
                 W_DUMMY_V,
                 W_REC_AC_AUTH_BAL,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_REC_AC_AVL_BAL,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_D,
                 W_DUMMY_V,
                 W_DUMMY_D,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_ERROR,
                 W_DUMMY_V,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 1);

      IF (TRIM (W_ERROR) IS NOT NULL)
      THEN
         RAISE E_USEREXCEP;
      END IF;
	  W_REC_AC_AVL_BAL := FLOOR(W_REC_AC_AVL_BAL);
   END;

   /*
      PROCEDURE CHECK_OTHER_ACNTS
      IS
      BEGIN
         FOR IDZ
            IN (SELECT LNACDTL_RECOV_ACNUM
                  FROM LOANACDTL
                 WHERE     LNACDTL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                       AND LNACDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                       AND LNACDTL_RECOV_SL_NUM > 1)
         LOOP
            CALL_SP_AVLBAL (IDZ.LNACDTL_RECOV_ACNUM);

            W_REQD_BAL := W_REPAY_AMOUNT - W_CHK_REC_AVAL_BAL;

            IF W_REC_AC_AVL_BAL > 0
            THEN
               IF W_REC_AC_AVL_BAL > W_REQD_BAL
               THEN
                  REC_IDX := REC_IDX + 1;
                  RECOV_REC (REC_IDX).V_RECOV_ACNT_NUM := IDZ.LNACDTL_RECOV_ACNUM;
                  RECOV_REC (REC_IDX).V_REPAY_AMT := W_REQD_BAL;
                  DBMS_OUTPUT.PUT_LINE (
                     IDZ.LNACDTL_RECOV_ACNUM || ' ' || W_REQD_BAL);
               ELSE
                  REC_IDX := REC_IDX + 1;
                  RECOV_REC (REC_IDX).V_RECOV_ACNT_NUM := IDZ.LNACDTL_RECOV_ACNUM;
                  RECOV_REC (REC_IDX).V_REPAY_AMT := W_REC_AC_AVL_BAL;
                  DBMS_OUTPUT.PUT_LINE (
                     IDZ.LNACDTL_RECOV_ACNUM || ' ' || W_REC_AC_AVL_BAL);
               END IF;

               W_CHK_REC_AVAL_BAL := W_CHK_REC_AVAL_BAL + W_REC_AC_AVL_BAL;

               IF W_CHK_REC_AVAL_BAL >= W_REPAY_AMOUNT
               THEN
                  EXIT;
               END IF;
            END IF;
         END LOOP;

         W_REC_AC_AVL_BAL := W_CHK_REC_AVAL_BAL;
      END;
   */
   PROCEDURE MARK_HOVERING
   IS
   BEGIN
      IF (TRIM (W_HOVER_START_DAYS) IS NULL)
      THEN
         W_HOVER_START_DAYS := 0;
      END IF;

      PKG_HOVERMARK.PV_HOVERBRK_REC (1).HOVERBRK_BRK_SL := 1;
      PKG_HOVERMARK.PV_HOVERBRK_REC (1).HOVERBRK_INTERNAL_ACNUM :=
         W_INTERNAL_ACNUM;
      PKG_HOVERMARK.PV_HOVERBRK_REC (1).HOVERBRK_GLACC_CODE := '';
      PKG_HOVERMARK.PV_HOVERBRK_REC (1).HOVERBRK_CURR_CODE := W_REC_CURR_CODE;
      PKG_HOVERMARK.PV_HOVERBRK_REC (1).HOVERBRK_RECOVERY_AMT :=
         w_hovering_amt;

      PKG_HOVERMARK.SP_HOVERMARK (
         W_ENTITY_CODE,
         W_RECOV_ACNT_NUM,
         W_INTERNAL_ACNUM,
         '',
         W_CBD,
         TRIM (W_HOVERING_TYPE),
         'LPCS',
         W_REC_CURR_CODE,
         w_hovering_amt,
         (W_PROC_DATE + W_HOVER_START_DAYS),
         NULL,
         'Hovering Process',
         'Loan Installment Recovery',
         '',
         'LNINSTRECV',
            W_ENTITY_CODE
         || '|'
         || W_INTERNAL_ACNUM
         || '|'
         || TO_CHAR (W_PROC_DATE, 'DD-MM-YYYY'),
         W_USER_ID,
         w_hovering_amt,
         0,
         w_hovering_amt,
         W_ERROR,
         W_HOVER_BRN_CODE,
         W_HOVER_YEAR,
         W_HOVER_SL_NUM);

      IF (TRIM (W_ERROR) IS NOT NULL)
      THEN
         RAISE E_USEREXCEP;
      END IF;
   END;

   PROCEDURE UPDATE_RTMPINSTRECV
   IS
      W_AC_LOAN_FLG   CHAR (1);
      W_SL_NUM        NUMBER;
   BEGIN
      IF W_FOR_LOANS = '1'
      THEN
         W_AC_LOAN_FLG := 'L';
      ELSE
         W_AC_LOAN_FLG := ' ';
      END IF;

      IF (W_TEMP_SER = 0)
      THEN
         W_TEMP_SER := PKG_PB_GLOBAL.SP_GET_REPORT_SL (W_ENTITY_CODE);
      END IF;

      IF W_EXIT = 0
      THEN
         IF ABS(W_PRIN_REC_AMT) + ABS(W_INT_REC_AMT) + ABS(W_CHG_REC_AMT) > 0
         THEN
            V_TEMP_INDX := V_TEMP_INDX + 1;

            TEMP_REC (V_TEMP_INDX).V_INSTRECV_TMP_SER := W_TEMP_SER;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_LOAN_ACNT_NUM :=
               W_INTERNAL_ACNUM;

            IF    TEMP_REC (V_TEMP_INDX).V_INSTRECV_LOAN_ACNT_NUM IS NULL
               OR W_INTERNAL_ACNUM IS NULL
            THEN
               NULL;
            END IF;


            TEMP_REC (V_TEMP_INDX).V_INSTRECV_ACNTS_BRN_CODE := W_BRN_CODE;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_REPAY_CURR := W_REPAY_AMT_CURR;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_INSTALLMENT_AMT :=
               W_INSTALLMENT_AMT;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_REPAY_AMOUNT := W_REPAY_AMOUNT;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_RECOV_ACNT_NUM :=
               W_RECOV_ACNT_NUM;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_RECOV_AC_LOAN_FLG :=
               W_AC_LOAN_FLG;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_LOAN_BAL := W_TOT_LOAN_BAL;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_PRIN_OS_BAL := W_PRIN_AC_BAL;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_INT_OS_BAL := W_INT_AC_BAL;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_CHG_OS_BAL := W_CHG_AC_BAL;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_EQU_INST_FLG := W_EQU_INST_FLG;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_REPAY_DATE := W_PROC_DATE;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_PRIN_RECOV_AMT := W_PRIN_REC_AMT;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_INT_RECOV_AMT := W_INT_REC_AMT;
            TEMP_REC (V_TEMP_INDX).V_INSTRECV_CHG_RECOV_AMT := W_CHG_REC_AMT;


            W_SL_NUM := 0;

            IF RECOV_REC.FIRST IS NOT NULL
            THEN
               FOR J IN RECOV_REC.FIRST .. RECOV_REC.LAST
               LOOP
                  W_SL_NUM := W_SL_NUM + 1;

                  V_TEMPDTL_INDX := V_TEMPDTL_INDX + 1;

                  TEMPDTL_REC (V_TEMPDTL_INDX).V_INSTRECVDT_TMP_SER :=
                     W_TEMP_SER;
                  TEMPDTL_REC (V_TEMPDTL_INDX).V_INSTRECVDT_INTERNAL_ACNUM :=
                     W_INTERNAL_ACNUM;
                  TEMPDTL_REC (V_TEMPDTL_INDX).V_INSTRECVDT_SL_NUM := W_SL_NUM;
                  TEMPDTL_REC (V_TEMPDTL_INDX).V_INSTRECVDT_RECOV_ACNUM :=
                     RECOV_REC (J).V_RECOV_ACNT_NUM;
                  TEMPDTL_REC (V_TEMPDTL_INDX).V_INSTRECVDT_RECOV_AMT :=
                     RECOV_REC (J).V_REPAY_AMT;

                  INSERT INTO RTMPINSTRECVDTL (RTMPINSTRECVDT_TMP_SER,
                                               RTMPINSTRECVDT_INTERNAL_ACNUM,
                                               RTMPINSTRECVDT_SL_NUM,
                                               RTMPINSTRECVDT_RECOV_ACNUM,
                                               RTMPINSTRECVDT_RECOV_AMT)
                       VALUES (W_TEMP_SER,
                               W_INTERNAL_ACNUM,
                               W_SL_NUM,
                               RECOV_REC (J).V_RECOV_ACNT_NUM,
                               RECOV_REC (J).V_REPAY_AMT);
               END LOOP;
            END IF;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
            'Error in Creating RTMPINSTRECVDTL ' || SUBSTR (SQLERRM, 1, 200);
         RAISE E_USEREXCEP;
   END;

   PROCEDURE GET_TRAN_BREAKUP
   IS
   BEGIN
      W_PRIN_REC_AMT := 0;
      W_INT_REC_AMT := 0;
      W_CHG_REC_AMT := 0;

      IF (W_INT_RECOVERY_OPTION = '3')
      THEN
         GET_TRAN_BREAKUP_3;
      ELSIF (W_INT_RECOVERY_OPTION = '2')
      THEN
         GET_TRAN_BREAKUP_2;
      ELSE
         GET_TRAN_BREAKUP_1;
      END IF;

      CHECK_RECOV_BRKUP;
   END;

   PROCEDURE GET_TRAN_BREAKUP_3
   IS
   BEGIN
      BEGIN
         SELECT NVL (SUM (LNINTAPPL_ACT_INT_AMT), 0)
           INTO W_INT_NOT_DUE_AMT
           FROM LNINTAPPL
          WHERE     LNINTAPPL_ENTITY_NUM = W_ENTITY_CODE
                AND LNINTAPPL_ACNT_NUM = W_INTERNAL_ACNUM
                AND LNINTAPPL_APPL_DATE <= W_CBD
                AND LNINTAPPL_INT_DUE_DATE > W_CBD;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_INT_NOT_DUE_AMT := 0;
      END;

      IF (ABS (W_INT_NOT_DUE_AMT) > ABS (W_INT_AC_BAL))
      THEN
         W_INT_REC_AMT := 0;
      ELSE
         W_INT_REC_AMT := ABS (W_INT_AC_BAL) - ABS (W_INT_NOT_DUE_AMT);
      END IF;

      IF (W_INT_REC_AMT > W_REPAY_AMOUNT)
      THEN
         W_INT_REC_AMT := W_REPAY_AMOUNT;
      END IF;

      W_PRIN_REC_AMT := W_REPAY_AMOUNT - W_INT_REC_AMT;
   END;

   PROCEDURE GET_TRAN_BREAKUP_2
   IS
   BEGIN
      IF (ABS (W_PRIN_AC_BAL) >= W_REPAY_AMOUNT)
      THEN
         W_PRIN_REC_AMT := W_REPAY_AMOUNT;
      ELSE
         W_PRIN_REC_AMT := ABS (W_PRIN_AC_BAL);
         W_INT_REC_AMT := W_REPAY_AMOUNT - W_PRIN_REC_AMT;
      END IF;
   END;

   PROCEDURE GET_TRAN_BREAKUP_1
   IS
   BEGIN
      W_INT_REC_AMT := ABS (W_INT_AC_BAL);

      IF (W_INT_REC_AMT > W_REPAY_AMOUNT)
      THEN
         W_INT_REC_AMT := W_REPAY_AMOUNT;
      END IF;

      W_PRIN_REC_AMT := W_REPAY_AMOUNT - W_INT_REC_AMT;
   END;

   PROCEDURE CHECK_RECOV_BRKUP
   IS
      P_REPAY_PRIN_AMT      NUMBER (18, 3);
      P_REPAY_INT_AMT       NUMBER (18, 3);
      P_REPAY_CHG_AMT       NUMBER (18, 3);
      P_OD_REPAY_PRIN_AMT   NUMBER (18, 3);
      P_OD_REPAY_INT_AMT    NUMBER (18, 3);
      P_OD_REPAY_CHG_AMT    NUMBER (18, 3);
      P_TOT_PRIN_AMT        NUMBER (18, 3);
      P_TOT_INT_AMT         NUMBER (18, 3);
      P_TOT_CHG_AMT         NUMBER (18, 3);
      P_ERR_MSG             VARCHAR2 (1000);
      P_PARTIAL_REC_REQ     CHAR (1);
   BEGIN
      PKG_LNOVERDUE.V_OVERDUE_EOD_PROC := TRUE;
      GET_LN_REPAY_DTLS (W_ENTITY_CODE,
                         W_INTERNAL_ACNUM,
                         W_REPAY_AMOUNT,
                         P_REPAY_PRIN_AMT,
                         P_REPAY_INT_AMT,
                         P_REPAY_CHG_AMT,
                         P_OD_REPAY_PRIN_AMT,
                         P_OD_REPAY_INT_AMT,
                         P_OD_REPAY_CHG_AMT,
                         P_TOT_PRIN_AMT,
                         P_TOT_INT_AMT,
                         P_TOT_CHG_AMT,
                         P_ERR_MSG,
                         P_PARTIAL_REC_REQ);

      W_PRIN_REC_AMT := ABS (P_TOT_PRIN_AMT);
      W_INT_REC_AMT := ABS (P_TOT_INT_AMT);
      W_CHG_REC_AMT := ABS (P_TOT_CHG_AMT);
   /*
   IF (W_PRIN_REC_AMT > ABS(W_PRIN_AC_BAL)) THEN
     W_PRIN_REC_AMT := ABS(W_PRIN_AC_BAL);
   END IF;

   IF (W_INT_REC_AMT > ABS(W_INT_AC_BAL)) THEN
     W_INT_REC_AMT := ABS(W_INT_AC_BAL);
   END IF;
   */
   END;

   PROCEDURE POST_TRAN
   IS
   BEGIN
      W_PREV_BRN_CODE := 0;

      IF TEMP_REC.COUNT > 0
      THEN
         FOR REC_TMP IN TEMP_REC.FIRST .. TEMP_REC.LAST
         LOOP
            W_BRN_CODE := L_BRN_CODE;
            W_RTMPINSTRECV_LOAN_ACNT_NUM :=
               TEMP_REC (REC_TMP).V_INSTRECV_LOAN_ACNT_NUM;
            W_RTMPINSTRECV_ACNTS_BRN_CODE :=
               TEMP_REC (REC_TMP).V_INSTRECV_ACNTS_BRN_CODE;
            W_RTMPINSTRECV_REPAY_CURR :=
               TEMP_REC (REC_TMP).V_INSTRECV_REPAY_CURR;
            W_RTMPINSTRECV_INSTALLMENT_AMT :=
               TEMP_REC (REC_TMP).V_INSTRECV_INSTALLMENT_AMT;
            W_RTMPINSTRECV_REPAY_AMOUNT :=
               TEMP_REC (REC_TMP).V_INSTRECV_REPAY_AMOUNT;
            W_RTMPINSTRECV_RECOV_ACNT_NUM :=
               TEMP_REC (REC_TMP).V_INSTRECV_RECOV_ACNT_NUM;
            W_RTMPINSTRECV_AC_LOAN_FLG :=
               TEMP_REC (REC_TMP).V_INSTRECV_RECOV_AC_LOAN_FLG;
            W_RTMPINSTRECV_LOAN_BAL := TEMP_REC (REC_TMP).V_INSTRECV_LOAN_BAL;
            W_RTMPINSTRECV_PRIN_OS_BAL :=
               TEMP_REC (REC_TMP).V_INSTRECV_PRIN_OS_BAL;
            W_RTMPINSTRECV_INT_OS_BAL :=
               TEMP_REC (REC_TMP).V_INSTRECV_INT_OS_BAL;
            W_RTMPINSTRECV_CHG_OS_BAL :=
               TEMP_REC (REC_TMP).V_INSTRECV_CHG_OS_BAL;
            W_RTMPINSTRECV_EQU_INST_FLG :=
               TEMP_REC (REC_TMP).V_INSTRECV_EQU_INST_FLG;
            W_RTMPINSTRECV_REPAY_DATE :=
               TEMP_REC (REC_TMP).V_INSTRECV_REPAY_DATE;
            W_RTMPINSTRECV_PRIN_RECOV_AMT :=
               TEMP_REC (REC_TMP).V_INSTRECV_PRIN_RECOV_AMT;
            W_RTMPINSTRECV_INT_RECOV_AMT :=
               TEMP_REC (REC_TMP).V_INSTRECV_INT_RECOV_AMT;
            W_RTMPINSTRECV_CHG_RECOV_AMT :=
               TEMP_REC (REC_TMP).V_INSTRECV_CHG_RECOV_AMT;


            IF (W_RTMPINSTRECV_REPAY_AMOUNT <> 0)
            THEN
               AUTOPOST_ARRAY_ASSIGN;
            END IF;
         END LOOP;
      END IF;

      UPDATE_LNINSTRECV;
      UPDATE_LNINSTRECVDTL;
      POST_PARA;
   END;

   PROCEDURE AUTOPOST_ARRAY_ASSIGN
   IS
   BEGIN
      SET_CREDIT_VOUCHER;
      SET_DEBIT_VOUCHER_NEW;
   END;

   PROCEDURE UPDATE_LNINSTRECV
   IS
      V_AC_NUM             NUMBER;
      V_PREV_AC_NUM        NUMBER;
      M_INDEX_1            NUMBER;
      V_COLLECTION_COUNT   NUMBER := 0;
   BEGIN
      V_COLLECTION_COUNT := TEMP_REC.COUNT;

      IF TEMP_REC.COUNT > 0
      THEN
         /*
           IF TEMP_REC (1).V_INSTRECV_LOAN_ACNT_NUM IS NULL THEN
               NULL ;
           END IF ;
            V_AC_NUM := TEMP_REC (1).V_INSTRECV_LOAN_ACNT_NUM ;
            */
         FORALL M_INDEX IN 1 .. TEMP_REC.COUNT
            --LOOP
            --V_AC_NUM := TEMP_REC (M_INDEX).V_INSTRECV_LOAN_ACNT_NUM;

            INSERT INTO LNINSTRECV (LNINSTRECV_ENTITY_NUM,
                                    LNINSTRECV_INTERNAL_ACNUM,
                                    LNINSTRECV_REPAY_DATE,
                                    LNINSTRECV_ACNT_BRN_CODE,
                                    LNINSTRECV_REPAY_CURR,
                                    LNINSTRECV_INSTALLMENT_AMT,
                                    LNINSTRECV_REPAY_AMT,
                                    LNINSTRECV_BAL_OS_BEF_RECOV,
                                    LNINSTRECV_PRIN_OS_BEF_RECOV,
                                    LNINSTRECV_INT_OS_BEF_RECOV,
                                    LNINSTRECV_CHG_OS_BEF_RECOV,
                                    LNINSTRECV_RECOV_FROM_ACNT,
                                    LNINSTRECV_RECOVERED_DATE,
                                    LNINSTRECV_PRIN_RECOV_AMT,
                                    LNINSTRECV_INT_RECOV_AMT,
                                    LNINSTRECV_CHG_RECOV_AMT,
                                    LNINSTRECV_ERR_FLAG,
                                    LNINSTRECV_ERR_MSG,
                                    LNINSTRECV_PROC_BY,
                                    LNINSTRECV_PROC_ON,
                                    POST_TRAN_BRN,
                                    POST_TRAN_DATE,
                                    POST_TRAN_BATCH_NUM)
                 VALUES (W_ENTITY_CODE,
                         TEMP_REC (M_INDEX).V_INSTRECV_LOAN_ACNT_NUM,
                         TEMP_REC (M_INDEX).V_INSTRECV_REPAY_DATE,
                         L_BRN_CODE,
                         TEMP_REC (M_INDEX).V_INSTRECV_REPAY_CURR,
                         TEMP_REC (M_INDEX).V_INSTRECV_INSTALLMENT_AMT,
                         TEMP_REC (M_INDEX).V_INSTRECV_REPAY_AMOUNT,
                         TEMP_REC (M_INDEX).V_INSTRECV_LOAN_BAL,
                         TEMP_REC (M_INDEX).V_INSTRECV_PRIN_OS_BAL,
                         TEMP_REC (M_INDEX).V_INSTRECV_INT_OS_BAL,
                         TEMP_REC (M_INDEX).V_INSTRECV_CHG_OS_BAL,
                         TEMP_REC (M_INDEX).V_INSTRECV_RECOV_ACNT_NUM,
                         W_CBD,
                         TEMP_REC (M_INDEX).V_INSTRECV_PRIN_RECOV_AMT,
                         TEMP_REC (M_INDEX).V_INSTRECV_INT_RECOV_AMT,
                         TEMP_REC (M_INDEX).V_INSTRECV_CHG_RECOV_AMT,
                         '0',
                         '',
                         W_USER_ID,
                         TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'),
                         0,
                         NULL,
                         0);
      --V_PREV_AC_NUM := TEMP_REC (M_INDEX).V_INSTRECV_LOAN_ACNT_NUM ;
      --END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         /*
            --DBMS_OUTPUT.PUT_LINE (TEMP_REC (M_INDEX_1).V_INSTRECV_LOAN_ACNT_NUM);

            FOR M_INDEX_1 IN 1 .. TEMP_REC.COUNT
            LOOP
               IF V_AC_NUM = TEMP_REC (M_INDEX_1).V_INSTRECV_LOAN_ACNT_NUM
               THEN
                  DBMS_OUTPUT.PUT_LINE (
                        TEMP_REC (M_INDEX_1).V_INSTRECV_LOAN_ACNT_NUM
                     || ' -- '
                     || TEMP_REC (M_INDEX_1).V_INSTRECV_REPAY_DATE
                     || ' -- '
                     || TEMP_REC (M_INDEX_1).V_INSTRECV_RECOV_ACNT_NUM);
               END IF;
            END LOOP;

   */
         W_ERROR :=
            'Error in Creating LNINSTRECV ' || SUBSTR (SQLERRM, 1, 200);
         RAISE E_USEREXCEP;
   END;

   PROCEDURE UPDATE_LNINSTRECVDTL
   IS
   BEGIN
      IF TEMPDTL_REC.COUNT > 0
      THEN
         FORALL M_INDEX IN 1 ..TEMPDTL_REC.COUNT

            INSERT INTO LNINSTRECVDTL (LNINSTRECVDT_ENTITY_NUM,
                                       LNINSTRECVDT_INTERNAL_ACNUM,
                                       LNINSTRECVDT_REPAY_DATE,
                                       LNINSTRECVDT_SL_NUM,
                                       LNINSTRECVDT_RECOV_ACNUM,
                                       LNINSTRECVDT_RECOV_AMT)
                 VALUES (W_ENTITY_CODE,
                         TEMPDTL_REC (M_INDEX).V_INSTRECVDT_INTERNAL_ACNUM,
                         W_CBD,
                         1,
                         TEMPDTL_REC (M_INDEX).V_INSTRECVDT_RECOV_ACNUM,
                         TEMPDTL_REC (M_INDEX).V_INSTRECVDT_RECOV_AMT);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR :=
            'Error in Creating LNINSTRECVDTL ' || SUBSTR (SQLERRM, 1, 200);
         RAISE E_USEREXCEP;
   END;

   PROCEDURE SET_CREDIT_VOUCHER
   IS
   BEGIN
      IDX := IDX + 1;
      PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_INTERNAL_ACNUM :=
         W_RTMPINSTRECV_LOAN_ACNT_NUM;
      PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
      PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
         ABS (W_RTMPINSTRECV_REPAY_AMOUNT);
      PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMT_BRKUP := '1';

      IDX1 := IDX1 + 1;
      PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_BATCH_SL_NUM := IDX;
      PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_PRIN_AC_AMT :=
         ABS (W_RTMPINSTRECV_PRIN_RECOV_AMT);
      PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_INTRD_AC_AMT :=
         ABS (W_RTMPINSTRECV_INT_RECOV_AMT);
      PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_CHARGE_AC_AMT :=
         ABS (W_RTMPINSTRECV_CHG_RECOV_AMT);
   END;


   PROCEDURE SET_DEBIT_VOUCHER_NEW
   IS
   BEGIN
      FOR IDY
         IN (SELECT RTMPINSTRECVDT_RECOV_ACNUM INSTRECVDTL_RECOV_ACNUM,
                    RTMPINSTRECVDT_RECOV_AMT INSTRECVDTL_RECOV_AMT
               FROM RTMPINSTRECVDTL
              WHERE     RTMPINSTRECVDT_TMP_SER = W_TEMP_SER
                    AND RTMPINSTRECVDT_INTERNAL_ACNUM =
                           W_RTMPINSTRECV_LOAN_ACNT_NUM)
      LOOP
         IDX := IDX + 1;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_INTERNAL_ACNUM :=
            IDY.INSTRECVDTL_RECOV_ACNUM;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
            ABS (IDY.INSTRECVDTL_RECOV_AMT);

         IF (W_PRODUCT_FOR_LOAN = '1')
         THEN
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMT_BRKUP := '1';
            IDX1 := IDX1 + 1;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_BATCH_SL_NUM := IDX;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_PRIN_AC_AMT :=
               ABS (IDY.INSTRECVDTL_RECOV_AMT);
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_INTRD_AC_AMT := 0;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_CHARGE_AC_AMT := 0;
         END IF;
      END LOOP;
   END;

   PROCEDURE POST_PARA
   IS
   BEGIN
      SET_TRAN_KEY_VALUES;
      SET_TRANBAT_VALUES;

      IF IDX > 0
      THEN
         PKG_APOST_INTERFACE.SP_POST_SODEOD_BATCH (W_ENTITY_CODE,
                                                   'A',
                                                   IDX,
                                                   IDX1,
                                                   W_ERR_CODE,
                                                   W_ERROR,
                                                   W_BATCH_NUMBER);

         IF (W_ERR_CODE <> '0000')
         THEN
            W_ERROR := FN_GET_AUTOPOST_ERR_MSG (W_ENTITY_CODE);
            RAISE E_USEREXCEP;
         END IF;

         UPDATE LNINSTRECV
            SET POST_TRAN_BRN = L_BRN_CODE,
                POST_TRAN_DATE = W_CBD,
                POST_TRAN_BATCH_NUM = W_BATCH_NUMBER
          WHERE     LNINSTRECV_ENTITY_NUM = W_ENTITY_CODE
                AND POST_TRAN_DATE IS NULL
                AND LNINSTRECV_ACNT_BRN_CODE = L_BRN_CODE
                AND LNINSTRECV_RECOVERED_DATE = W_CBD
                AND LNINSTRECV_ERR_FLAG <> '1'
                AND LNINSTRECV_REPAY_AMT <> 0
                AND TRIM (LNINSTRECV_ERR_MSG) IS NULL;
      END IF;

      IDX := 0;
      IDX1 := 0;
      W_PREV_BRN_CODE := 0;
      PKG_APOST_INTERFACE.SP_POSTING_END (W_ENTITY_CODE);
   END;

   PROCEDURE SET_TRAN_KEY_VALUES
   IS
   BEGIN
      PKG_AUTOPOST.PV_SYSTEM_POSTED_TRANSACTION := FALSE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := L_BRN_CODE;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := W_CBD;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;
   END;

   PROCEDURE SET_TRANBAT_VALUES
   IS
   BEGIN
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'LNINSTRECV';
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY := L_BRN_CODE;
      PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 :=
         'Auto Loan Installment Recovery';
   END;


   PROCEDURE SP_LNINSTRECOV (V_ENTITY_NUM       IN NUMBER,
                             P_BRN_CODE         IN NUMBER DEFAULT 0,
                             P_PROD_CODE        IN NUMBER DEFAULT 0,
                             P_INTERNAL_ACNUM   IN NUMBER DEFAULT 0)
   IS
      V_CBD   DATE;
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

      BEGIN
         INIT_PARA;

         IF (P_BRN_CODE IS NULL)
         THEN
            W_BRN_CODE := 0;
         ELSE
            W_BRN_CODE := P_BRN_CODE;
         END IF;

         IF (P_PROD_CODE IS NULL)
         THEN
            W_PROD_CODE := 0;
         ELSE
            W_PROD_CODE := P_PROD_CODE;
         END IF;

         IF (P_INTERNAL_ACNUM IS NULL)
         THEN
            W_INTERNAL_ACNUM := 0;
         ELSE
            W_INTERNAL_ACNUM := P_INTERNAL_ACNUM;
         END IF;

         W_CBD := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

         W_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;

         IF (W_CBD IS NULL)
         THEN
            W_ERROR := 'Current Business Date Should be Specified';
            RAISE E_USEREXCEP;
         END IF;

         IF (TRIM (W_USER_ID) IS NULL)
         THEN
            W_ERROR := 'User Id Should be Specified';
            RAISE E_USEREXCEP;
         END IF;

         PKG_APOST_INTERFACE.SP_POSTING_BEGIN (W_ENTITY_CODE);

         W_CBD_TIME :=
               W_CBD
            || ' '
            || PKG_PB_GLOBAL.FN_GET_CURR_BUS_TIME (W_ENTITY_CODE);

         READ_RECOVERY_LOANS;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF TRIM (W_ERROR) IS NULL
            THEN
               W_ERROR :=
                  'Error in SP_LNINSTRECOV ' || SUBSTR (SQLERRM, 1, 200);
            END IF;

            PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                         'E',
                                         PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                         ' ',
                                         0);
            PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                         'E',
                                         SUBSTR (SQLERRM, 1, 1000),
                                         ' ',
                                         0);
      END;
   END;


   PROCEDURE START_BRNWISE (V_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0)
   IS
      V_PROCESS_ALL               CHAR (1) := 'N';

      V_NUMBER_OF_CORE_BRN        NUMBER;
      V_NUMBER_OF_PROCESSED_BRN   NUMBER;
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);



      W_ENTITY_CODE := V_ENTITY_NUM;
      W_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;
      W_CBD := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

      PKG_MV_REFRESH.SP_PROCESS_DAY_MANUAL_LOAN (
         V_ENTITY_NUM,
         PKG_EODSOD_FLAGS.PV_PREVIOUS_DATE);
      COMMIT;

      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (W_ENTITY_CODE, P_BRN_CODE);


      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

         IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (W_ENTITY_CODE,
                                                         L_BRN_CODE) = FALSE
         THEN
            SP_LNINSTRECOV (W_ENTITY_CODE, L_BRN_CODE);


            IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
            THEN
               PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (
                  W_ENTITY_CODE,
                  L_BRN_CODE);
            END IF;

            PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (W_ENTITY_CODE);


            TEMP_REC.DELETE;

            TEMPDTL_REC.DELETE;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (W_ERR_MSG) IS NULL
         THEN
            W_ERR_MSG := SUBSTR (SQLERRM, 1, 900);
         END IF;

         IF L_BRN_CODE <> 0
         THEN
            W_ERR_MSG :=
                  W_ERR_MSG
               || ' Process Brn Code '
               || L_BRN_CODE
               || ' '
               || SUBSTR (SQLERRM, 1, 200);
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERR_MSG;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                      'E',
                                      W_ERR_MSG,
                                      ' ',
                                      0);
   END START_BRNWISE;
END PKG_LNINSTRECOV;
/

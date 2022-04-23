CREATE OR REPLACE PACKAGE PKG_LNINTAPPLY IS

  -- AUTHOR  : PRASANTH NS
  -- CREATED : 9/25/2007 3:17:09 PM
  -- PURPOSE : PROCEDURE FOR LOAN INTEREST APPLICATION (FOR ACCRUAL BASED ON DAILY PRODUCTS)


  PROCEDURE START_BRNWISE(V_ENTITY_NUM            IN NUMBER,
                        P_BRN_CODE              IN NUMBER DEFAULT 0) ;


  PROCEDURE SP_INTAPPLY(V_ENTITY_NUM            IN NUMBER,
                        P_BRN_CODE              IN NUMBER DEFAULT 0,
                        P_PROD_CODE             IN NUMBER DEFAULT 0,
                        P_CURR_CODE             IN VARCHAR2 DEFAULT NULL,
                        P_INTERNAL_ACNUM        IN NUMBER DEFAULT 0,
                        P_INT_ON_RECOVERY_LOANS IN NUMBER DEFAULT 0,
                        P_INT_RECOV_AC_AMT      IN NUMBER DEFAULT 0,
                        P_INT_RECOV_BC_AMT      IN NUMBER DEFAULT 0,
                        P_NPA_INT_RECOV_AC_AMT  IN NUMBER DEFAULT 0,
                        P_NPA_INT_RECOV_BC_AMT  IN NUMBER DEFAULT 0,
                        P_INT_UPTO_DATE         IN DATE DEFAULT NULL);
END PKG_LNINTAPPLY;
/


CREATE OR REPLACE PACKAGE BODY PKG_LNINTAPPLY
IS
   /*
    Modification History
     -----------------------------------------------------------------------------------------
    Sl.            Description                              Mod By             Mod on
    -----------------------------------------------------------------------------------------
     1   Changes for Nepal Social Development Bank
     Need to chek LIMIT_CHECK_REQ                         K Neelakantan        10-NOV-2010   -- NEELS-MDS-10-NOV-2010
    2   Changes for Nepal Social Development Bank
         Unrealized Int Accounted in Income is changed to
         Unrealized Int Accounted in Suspense
         Label Changes done in ILNPRODPM
         Default 0 Changed from Default 1                 K Neelakantan        30-NOV-2010   -- NEELS-MDS-30-NOV-2010
  3  Changes for Sonali Bank        Avinash K     21-AUG-2012   -- Avinash-SONALI-21AUG2012
      For NPA accounts also, Interest should be applied to the accounts from interest accrual GL head.
   For NPA accounts, updation of LNSUSPLED and LNSUSPBAL tables is removed as they are updated in Interest Accrual process itself.
   Adjustment to care of round off difference is done into Interest Income GL itself for NPA Accounts also (instead of Interest Suspense GL)
   -----------------------------------------------------------------------------------------

    */
   W_INT_RECOV_AC_AMT       NUMBER (18, 3);
   W_INT_RECOV_BC_AMT       NUMBER (18, 3);
   W_INT_UPTO_DATE          DATE;
   W_NPA_INT_RECOV_AC_AMT   NUMBER (18, 3);
   W_NPA_INT_RECOV_BC_AMT   NUMBER (18, 3);
   W_ENTITY_CODE            NUMBER (5) := 0;
   V_ASON_DATE              DATE;
   W_USER_ID                VARCHAR2 (8);

   W_LOAN_INT_ON_RECOVERY   BOOLEAN;


   PROCEDURE SP_INTAPPLY (V_ENTITY_NUM              IN NUMBER,
                          P_BRN_CODE                IN NUMBER DEFAULT 0,
                          P_PROD_CODE               IN NUMBER DEFAULT 0,
                          P_CURR_CODE               IN VARCHAR2 DEFAULT NULL,
                          P_INTERNAL_ACNUM          IN NUMBER DEFAULT 0,
                          P_INT_ON_RECOVERY_LOANS   IN NUMBER DEFAULT 0,
                          P_INT_RECOV_AC_AMT        IN NUMBER DEFAULT 0,
                          P_INT_RECOV_BC_AMT        IN NUMBER DEFAULT 0,
                          P_NPA_INT_RECOV_AC_AMT    IN NUMBER DEFAULT 0,
                          P_NPA_INT_RECOV_BC_AMT    IN NUMBER DEFAULT 0,
                          P_INT_UPTO_DATE           IN DATE DEFAULT NULL)
   IS
      E_USEREXCEP                      EXCEPTION;
      E_SKP                            EXCEPTION;

      TYPE TY_LNP_REC IS RECORD
      (
         V_PROD_CURR_CODE              VARCHAR2 (7),
         V_INT_INCOME_GL               VARCHAR2 (15),
         -- Added by Avinash-SONALI-21AUG2012 (begin)
         V_INT_SUSP_GL                 VARCHAR2 (15),
         -- Added by Avinash-SONALI-21AUG2012 (end)
         V_INT_ACCR_GL                 VARCHAR2 (15),
         V_LNPRDAC_ACCRINT_SUSP_HEAD   VARCHAR2 (15)
      );

      TYPE TAB_LNP_REC IS TABLE OF TY_LNP_REC
         INDEX BY PLS_INTEGER;

      LNP_REC                          TAB_LNP_REC;

      --16-08-2010-beg
      TYPE TY_LNPRD_ACPM IS RECORD
      (
         V_LNPRD_UNREAL_INT_INCOME_REQD   CHAR (1),
         V_LNPRD_INT_APPL_FREQ            CHAR (1)
      );

      TYPE TAB_LNPRD_ACPM IS TABLE OF TY_LNPRD_ACPM
         INDEX BY VARCHAR (4);

      LNPRD_ACPM                       TAB_LNPRD_ACPM;

      --16-08-2010-end

      TYPE TY_LPC_REC IS RECORD
      (
         V_INT_INCOME_GL               VARCHAR2 (15),
         -- Added by Avinash-SONALI-21AUG2012 (begin)
         V_INT_SUSP_GL                 VARCHAR2 (15),
         -- Added by Avinash-SONALI-21AUG2012 (end)
         V_INT_ACCR_GL                 VARCHAR2 (15),
         V_LNPRDAC_ACCRINT_SUSP_HEAD   VARCHAR2 (15)
      );

      TYPE TAB_LPC_REC IS TABLE OF TY_LPC_REC
         INDEX BY VARCHAR2 (7);

      LPC_REC                          TAB_LPC_REC;

      TYPE TY_STS_REC IS RECORD
      (
         V_BRN_CODE              NUMBER (6),
         V_PROD_CODE             NUMBER (4),
         V_SCHEME_CODE           VARCHAR2 (6),
         V_CURR_CODE             VARCHAR2 (3),
         V_INTERNAL_ACNUM        NUMBER (14),
         V_PA_ACCR_UPTO          DATE,
         V_INT_APPL_UPTO_DATE    DATE,
         V_SCHEME_REQD           CHAR (1),
         V_INT_APPL_FREQ         CHAR (1),
         V_OPENING_DATE          DATE,
         V_INT_RECOVERY_OPTION   CHAR (1),
         V_LIMIT_CHECK_REQ       CHAR (1)             -- NEELS-MDS-10-NOV-2010
      );

      TYPE TAB_STS_REC IS TABLE OF TY_STS_REC
         INDEX BY PLS_INTEGER;

      STS_REC                          TAB_STS_REC;

      TYPE TY_IAMT_REC IS RECORD
      (
         V_CURR     VARCHAR2 (3),
         V_GLACC    VARCHAR2 (15),
         V_AMOUNT   NUMBER
      );

      TYPE TAB_IAMT_REC IS TABLE OF TY_IAMT_REC
         INDEX BY PLS_INTEGER;

      IAMT_REC                         TAB_IAMT_REC;

      TYPE TY_AAMT_REC IS RECORD
      (
         V_CURR            VARCHAR2 (3),
         V_INT_ACCR_GL     VARCHAR2 (15),
         V_INT_INCOME_GL   VARCHAR2 (15),
         V_AMOUNT          NUMBER
      );

      TYPE TAB_AAMT_REC IS TABLE OF TY_AAMT_REC
         INDEX BY PLS_INTEGER;

      AAMT_REC                         TAB_AAMT_REC;

      PROCEDURE PROCEED_PARA;

      PROCEDURE GET_INT_ACCRUED;

      PROCEDURE GET_CURR_SPECIFIC_PARAM;

      PROCEDURE GET_ROUNDED_AMT;

      PROCEDURE UPDATE_RTMPINTAPPL;

      PROCEDURE POST_NPA;

      PROCEDURE CHECK_CURR_NPA_STAT;

      PROCEDURE POST_NPA_SUB;

      PROCEDURE UPDATE_LNSUSPLED;

      PROCEDURE UPDATE_LNSUSPBAL;

      PROCEDURE UPDATE_LNINTAPPL_NPA;

      PROCEDURE POST_INTEREST;

      PROCEDURE POST_PARA;

      PROCEDURE AUTOPOST_ARRAY_ASSIGN;

      PROCEDURE GET_LOAN_ACNTNG_PARAM;

      PROCEDURE UPDATE_LNINTAPPL;

      PROCEDURE SET_CREDIT_VOUCHER;

      PROCEDURE ADJ_INT_RNDOFF;

      PROCEDURE SET_TRAN_KEY_VALUES;

      PROCEDURE SET_TRANBAT_VALUES;

      PROCEDURE APPEND_CONS_INTAMT_ARRAY;

      PROCEDURE APPEND_CONS_ADJAMT_ARRAY;

      PROCEDURE GET_NEXT_INSTALL_DUE_DATE;

      PROCEDURE PROC_REPAY;

      PROCEDURE PROC_REPAY_SUB;

      PROCEDURE GET_NEXT_REPAY_DATE;

      PROCEDURE GET_NEXT_REPAY_DATE_SUB;

      PROCEDURE UPDATE_LNINTPEND (P_ACT_LIMIT_AMT   IN NUMBER,
                                  P_ACT_INT_AMT     IN NUMBER,
                                  P_DIFF_AMOUNT     IN NUMBER); -- NEELS-MDS-10-NOV-2010 Add

      W_CBD                            DATE;
      W_PREV_CBD                       DATE; --ARUNMUGESH.J CHE 27-12-2007 ADD
      W_ERROR                          VARCHAR2 (1300);
      W_EOD_MQHY_FLG                   CHAR (1);
      W_BRN_CODE                       NUMBER (6);
      W_PROD_CODE                      NUMBER (4);
      W_CURR_CODE                      VARCHAR2 (3);
      W_INTERNAL_ACNUM                 NUMBER (14);
      W_USER_ID                        VARCHAR2 (8);
      W_SQL                            VARCHAR2 (4300);
      W_SCHEME_CODE                    VARCHAR2 (6);
      W_PA_ACCR_UPTO                   DATE;
      W_INT_APPL_UPTO_DATE             DATE;
      W_SCHEME_REQD                    CHAR (1);
      W_INT_APPL_FREQ                  CHAR (1);
      W_TOT_INT_AMT                    NUMBER;
      W_TOT_INT_AMT_RND                NUMBER;
      W_TOT_OD_INT_AMT_RND             NUMBER;
      W_TOT_OD_INT_AMT                 NUMBER;
      W_SUM_TOT_INT_AMT                NUMBER;
      W_SUM_TOT_INT_AMT_RND            NUMBER;
      W_INT_RNDOFF_PARAM               CHAR (1);
      W_INT_RNDOFF_PRECISION           NUMBER;
      W_MIN_INT_AMT                    NUMBER;
      W_AMT                            NUMBER;
      W_ACT_INT_AMT                    NUMBER;
      W_AMT_RND                        NUMBER;
      W_RNDOFF_DIFF                    NUMBER;
      W_OPENING_DATE                   DATE;
      W_TEMP_SER                       NUMBER;
      W_NPA_TOT_INT_AMT                NUMBER;
      W_NPA_TOT_OD_INT_AMT             NUMBER;
      W_NPA_INT_FROM_DATE              DATE;
      W_NPA_INT_UPTO_DATE              DATE;
      W_NPA_SUM_TOT_INT_AMT            NUMBER;
      W_NPA_ACT_INT_AMT                NUMBER;
      W_NPA_ACNT                       CHAR (1);
      W_ASSET_CLASS                    CHAR (1);
      W_MAX_SL                         NUMBER;
      DUMMY                            NUMBER;
      W_DUMMY_STR                      VARCHAR2 (500);
      W_PREV_BRN_CODE                  NUMBER (6);
      W_RTMPINTAPPL_ACT_INT_AMT        NUMBER;
      W_RTMPINTAPPL_ACCR_INT_AMT       NUMBER;
      --21-10-2009-beg
      W_RTMPINTAPPL_NPA_ACCR_INT_AMT   NUMBER;
      --21-10-2009-end
      W_RTMPINTAPPL_RND_DIFF           NUMBER;
      W_RTMPINTAPPL_FROM_DATE          DATE;
      W_RTMPINTAPPL_UPTO_DATE          DATE;
      W_RTMPINTAPPL_INT_DUE_DATE       DATE;
      W_INT_INCOME_GL                  VARCHAR2 (15);
      -- Added by Avinash-SONALI-21AUG2012 (begin)
      W_INT_SUSP_GL                    VARCHAR2 (15);
      -- Added by Avinash-SONALI-21AUG2012 (end)
      W_INT_ACCR_GL                    VARCHAR2 (15);
      --16-08-2010-beg
      W_INT_ACCRU_SUSP_HEAD            VARCHAR2 (15);
      --16-08-2010-end
      IDX                              NUMBER;
      IDX1                             NUMBER;
      W_ERR_CODE                       VARCHAR2 (10);
      W_BATCH_NUMBER                   NUMBER (7);
      W_NPA_INT_AMT_POSTED             NUMBER;
      TMP_COUNT                        NUMBER;
      TMP_COUNT1                       NUMBER;
      W_INT_RECOVERY_OPTION            CHAR (1);
      W_REPAY_AMT                      NUMBER;
      W_REPAY_FREQ                     CHAR (1);
      W_REPAY_FROM_DATE                DATE;
      W_NOF_INSTALL                    NUMBER;
      W_REPAY_EXIT                     CHAR (1);
      W_NEXT_INSTALL_DATE              DATE;
      W_REPAY_END_DATE                 DATE;
      W_REPAY_DATE                     DATE;
      W_CHK_NOF_INSTALL                NUMBER;
      -- R.Senthil Kumar - 11-June-2010 - Begin
      W_IGNORE                         CHAR (1);
      W_COUNT                          NUMBER;
      -- R.Senthil Kumar - 11-June-2010 - End
      -- Add Guna 19/07/2010 start
      W_NPA_INT_AMT_RND                NUMBER (18, 3);
      W_NPA_OD_INT_AMT_RND             NUMBER (18, 3);
      W_ACCR_NPA_INT_AMT_RND           NUMBER (18, 3);
      -- Add Guna 19/07/2010 end
      W_LIMIT_CHECK_REQ                CHAR (1) := '0'; -- NEELS-MDS-10-NOV-2010 ADD

      FUNCTION GET_UNUSED_LIMIT (P_ENTITY_NUM IN NUMBER, P_ACNUM IN NUMBER)
         RETURN NUMBER
      AS
         W_AC_CURR_CODE           CHAR (3);
         W_AC_AUTH_BAL            NUMBER (18, 3);
         W_AC_UNAUTH_DBS          NUMBER (18, 3);
         W_AC_UNAUTH_CRS          NUMBER (18, 3);
         W_AC_FWDVAL_DBS          NUMBER (18, 3);
         W_AC_FWDVAL_CRS          NUMBER (18, 3);
         W_AC_TOT_BAL             NUMBER (18, 3);
         W_AC_LIEN_AMT            NUMBER (18, 3);
         W_HOLD_AMT               NUMBER (18, 3);
         W_MIN_BAL                NUMBER (18, 3);
         W_AC_AVLBAL              NUMBER (18, 3);
         W_AC_EFFBAL              NUMBER (18, 3);
         W_UNUSED_LIMIT           NUMBER (18, 3);
         W_BC_AUTH_BAL            NUMBER (18, 3);
         W_BC_UNAUTH_DBS          NUMBER (18, 3);
         W_BC_UNAUTH_CRS          NUMBER (18, 3);
         W_BC_FWDVAL_DBS          NUMBER (18, 3);
         W_BC_FWDVAL_CRS          NUMBER (18, 3);
         W_BC_TOT_BAL             NUMBER (18, 3);
         W_BC_LIEN_AMT            NUMBER (18, 3);
         W_AC_CLGVAL_DBS          NUMBER (18, 3);
         W_AC_CLGVAL_CRS          NUMBER (18, 3);
         W_AC_CLOSURE_DT          DATE;
         W_AC_ACNT_FREEZED        VARCHAR2 (1);
         W_AC_ACNT_AUTH_ON        DATE;
         W_AC_ACNT_DORMANT_ACNT   CHAR (1);
         W_AC_ACNT_INOP_ACNT      CHAR (1);
         W_AC_ACNT_DB_FREEZED     CHAR (1);
         W_AC_ACNT_CR_FREEZED     CHAR (1);
         W_TOT_LMT_AMT            NUMBER (18, 3);
         W_EFF_BAL_WOT_LMT        NUMBER (18, 3);
         W_ERR_MSG                VARCHAR2 (1000);
         W_CALLED_FROM_QUERY      VARCHAR2 (100);
         W_CONTRACT_NUM           NUMBER (6);
         W_ADV_PRIN_AC_BAL        NUMBER (18, 3);
         W_ADV_INTRD_AC_BAL       NUMBER (18, 3);
         W_ADV_CHARGE_AC_BAL      NUMBER (18, 3);
         W_ADV_PRIN_BC_BAL        NUMBER (18, 3);
         W_ADV_INTRD_BC_BAL       NUMBER (18, 3);
         W_ADV_CHARGE_BC_BAL      NUMBER (18, 3);
         W_MIN_BAL_ADD_REQ        NUMBER (1);
         W_SHADOW_BAL_REQ         NUMBER (1);
      BEGIN
         SP_AVLBAL (P_ENTITY_NUM,
                    P_ACNUM,
                    W_AC_CURR_CODE,
                    W_AC_AUTH_BAL,
                    W_AC_UNAUTH_DBS,
                    W_AC_UNAUTH_CRS,
                    W_AC_FWDVAL_DBS,
                    W_AC_FWDVAL_CRS,
                    W_AC_TOT_BAL,
                    W_AC_LIEN_AMT,
                    W_HOLD_AMT,
                    W_MIN_BAL,
                    W_AC_AVLBAL,
                    W_AC_EFFBAL,
                    W_UNUSED_LIMIT,
                    W_BC_AUTH_BAL,
                    W_BC_UNAUTH_DBS,
                    W_BC_UNAUTH_CRS,
                    W_BC_FWDVAL_DBS,
                    W_BC_FWDVAL_CRS,
                    W_BC_TOT_BAL,
                    W_BC_LIEN_AMT,
                    W_AC_CLGVAL_DBS,
                    W_AC_CLGVAL_CRS,
                    W_AC_CLOSURE_DT,
                    W_AC_ACNT_FREEZED,
                    W_AC_ACNT_AUTH_ON,
                    W_AC_ACNT_DORMANT_ACNT,
                    W_AC_ACNT_INOP_ACNT,
                    W_AC_ACNT_DB_FREEZED,
                    W_AC_ACNT_CR_FREEZED,
                    W_TOT_LMT_AMT,
                    W_EFF_BAL_WOT_LMT,
                    W_ERR_MSG,
                    W_CALLED_FROM_QUERY,
                    W_CONTRACT_NUM,
                    W_ADV_PRIN_AC_BAL,
                    W_ADV_INTRD_AC_BAL,
                    W_ADV_CHARGE_AC_BAL,
                    W_ADV_PRIN_BC_BAL,
                    W_ADV_INTRD_BC_BAL,
                    W_ADV_CHARGE_BC_BAL,
                    W_MIN_BAL_ADD_REQ,
                    W_SHADOW_BAL_REQ);
         RETURN W_AC_AVLBAL;
      END GET_UNUSED_LIMIT;

      PROCEDURE INIT_PARA
      IS
      BEGIN
         W_CBD := NULL;
         W_PREV_CBD := NULL;                     --ARUNMUGESH J 27-12-2007 ADD
         W_ERROR := '';
         W_EOD_MQHY_FLG := '';
         W_BRN_CODE := 0;
         W_PROD_CODE := 0;
         W_CURR_CODE := '';
         W_INTERNAL_ACNUM := 0;
         W_USER_ID := '';
         W_SQL := '';
         W_SCHEME_CODE := '';
         W_PA_ACCR_UPTO := NULL;
         W_INT_APPL_UPTO_DATE := NULL;
         W_SCHEME_REQD := '';
         W_INT_APPL_FREQ := '';
         W_TOT_INT_AMT := 0;
         W_TOT_INT_AMT_RND := 0;
         W_TOT_OD_INT_AMT_RND := 0;
         W_TOT_OD_INT_AMT := 0;
         W_SUM_TOT_INT_AMT := 0;
         W_SUM_TOT_INT_AMT_RND := 0;
         W_INT_RNDOFF_PARAM := '';
         W_INT_RNDOFF_PRECISION := '';
         W_MIN_INT_AMT := '';
         W_AMT := 0;
         W_ACT_INT_AMT := 0;
         W_AMT_RND := 0;
         W_RNDOFF_DIFF := 0;
         W_OPENING_DATE := NULL;
         W_TEMP_SER := 0;
         W_NPA_TOT_INT_AMT := 0;
         W_NPA_TOT_OD_INT_AMT := 0;
         W_NPA_INT_FROM_DATE := NULL;
         W_NPA_INT_UPTO_DATE := NULL;
         W_NPA_SUM_TOT_INT_AMT := 0;
         W_NPA_ACT_INT_AMT := 0;
         W_NPA_ACNT := '';
         W_ASSET_CLASS := '';
         W_MAX_SL := 0;
         DUMMY := 0;
         W_PREV_BRN_CODE := 0;
         W_RTMPINTAPPL_ACT_INT_AMT := 0;
         W_RTMPINTAPPL_ACCR_INT_AMT := 0;
         W_RTMPINTAPPL_RND_DIFF := 0;
         W_RTMPINTAPPL_FROM_DATE := NULL;
         W_RTMPINTAPPL_UPTO_DATE := NULL;
         W_RTMPINTAPPL_INT_DUE_DATE := NULL;
         W_INT_INCOME_GL := '';
         -- Added by Avinash-SONALI-21AUG2012 (begin)
         W_INT_SUSP_GL := '';
         -- Added by Avinash-SONALI-21AUG2012 (end)
         W_INT_ACCR_GL := '';
         IDX := 0;
         IDX1 := 0;
         W_ERR_CODE := '';
         W_BATCH_NUMBER := 0;
         W_NPA_INT_AMT_POSTED := 0;
         TMP_COUNT := 0;
         TMP_COUNT1 := 0;
         W_INT_RECOVERY_OPTION := '';
         W_REPAY_AMT := 0;
         W_REPAY_FREQ := '';
         W_REPAY_FROM_DATE := NULL;
         W_NOF_INSTALL := 0;
         W_REPAY_EXIT := '';
         W_NEXT_INSTALL_DATE := NULL;
         W_REPAY_END_DATE := NULL;
         W_REPAY_DATE := NULL;
         W_CHK_NOF_INSTALL := 0;
         -- R.Senthil Kumar - 11-June-2010 - Begin
         W_IGNORE := '0';
         W_COUNT := 0;
         -- R.Senthil Kumar - 11-June-2010 - End
         -- Add Guna 19/07/2010 start
         W_NPA_INT_AMT_RND := 0;
         W_NPA_OD_INT_AMT_RND := 0;
         W_ACCR_NPA_INT_AMT_RND := 0;
         -- Add Guna 19/07/2010 end
         W_LIMIT_CHECK_REQ := '0';                -- NEELS-MDS-10-NOV-2010 ADD
      END INIT_PARA;

      PROCEDURE READ_LNPRODACPM
      IS
      BEGIN
         W_SQL :=
            'SELECT LNPRDAC_PROD_CODE||LNPRDAC_CURR_CODE, LNPRDAC_INT_INCOME_GL, LNPRDAC_INT_SUSP_GL, LNPRDAC_INT_ACCR_GL,LNPRDAC_ACCRINT_SUSP_HEAD FROM LNPRODACPM'; -- Added LNPRDAC_INT_SUSP_GL also in the query to fetch it Avinash-SONALI-21AUG2012

         EXECUTE IMMEDIATE W_SQL BULK COLLECT INTO LNP_REC;

         IF LNP_REC.FIRST IS NOT NULL
         THEN
            FOR J IN LNP_REC.FIRST .. LNP_REC.LAST
            LOOP
               LPC_REC (LNP_REC (J).V_PROD_CURR_CODE).V_INT_INCOME_GL :=
                  LNP_REC (J).V_INT_INCOME_GL;
               -- Added by Avinash-SONALI-21AUG2012 (begin)
               LPC_REC (LNP_REC (J).V_PROD_CURR_CODE).V_INT_SUSP_GL :=
                  LNP_REC (J).V_INT_SUSP_GL;
               -- Added by Avinash-SONALI-21AUG2012 (end)
               LPC_REC (LNP_REC (J).V_PROD_CURR_CODE).V_INT_ACCR_GL :=
                  LNP_REC (J).V_INT_ACCR_GL;

               --16-08-2010-beg
               LPC_REC (LNP_REC (J).V_PROD_CURR_CODE).V_LNPRDAC_ACCRINT_SUSP_HEAD :=
                  LNP_REC (J).V_LNPRDAC_ACCRINT_SUSP_HEAD;
            --16-08-2010-end
            END LOOP;
         END IF;

         --16-08-2010-beg
         -- THIS IS FOR HANDLING NEPAL LOANS
         -- NEELS-MDS-30-NOV-2010 NVL Changed to 0 from 1
         FOR IDX
            IN (SELECT L.LNPRD_PROD_CODE,
                       NVL (L.LNPRD_UNREAL_INT_INCOME_REQD, 0)
                          LNPRD_UNREAL_INT_INCOME_REQD,
                       NVL (L.LNPRD_INT_APPL_FREQ, 0) LNPRD_INT_APPL_FREQ
                  FROM LNPRODPM L)
         LOOP
            LNPRD_ACPM (IDX.LNPRD_PROD_CODE).V_LNPRD_UNREAL_INT_INCOME_REQD :=
               IDX.LNPRD_UNREAL_INT_INCOME_REQD;
            LNPRD_ACPM (IDX.LNPRD_PROD_CODE).V_LNPRD_INT_APPL_FREQ :=
               IDX.LNPRD_INT_APPL_FREQ;
         END LOOP;
      --16-08-2010-end
      END READ_LNPRODACPM;

      PROCEDURE READ_ACNT
      IS
         V_ACCOUNT_COUNT   NUMBER (6);
      BEGIN
         W_SQL :=
               'SELECT ACNTS_BRN_CODE, ACNTS_PROD_CODE, ACNTS_SCHEME_CODE, ACNTS_CURR_CODE, ACNTS_INTERNAL_ACNUM, LNACNT_PA_ACCR_POSTED_UPTO, LNACNT_INT_APPLIED_UPTO_DATE, LNPRD_SCHEME_REQD, LNPRD_INT_APPL_FREQ,ACNTS_OPENING_DATE, LNPRD_INT_RECOVERY_OPTION,NVL(LNPRD_LIMIT_CHK_REQD,''0'')
                    FROM LOANACNTS,ACNTS,LNPRODPM,PRODUCTS,ASSETCLS, ASSETCD WHERE ACNTS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND LNACNT_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND  LNACNT_INTERNAL_ACNUM = ACNTS_INTERNAL_ACNUM AND ACNTS_CLOSURE_DATE IS NULL AND LNPRD_INT_PROD_BASIS ='
            || CHR (39)
            || 'D'
            || CHR (39)
            || ' AND LNPRD_PROD_CODE = ACNTS_PROD_CODE AND PRODUCT_CODE = ACNTS_PROD_CODE AND ACNTS_INTERNAL_ACNUM = ASSETCLS_INTERNAL_ACNUM AND ASSETCLS_ASSET_CODE = ASSETCD_CODE AND NVL(ASSETCD_NONPERF_CAT, 0) <> ''3''';

         --09-09-2009-beg
         IF W_INT_RECOV_AC_AMT <> 0 OR W_NPA_INT_RECOV_AC_AMT <> 0
         THEN
            W_SQL := W_SQL || ' AND LNPRD_INT_APPL_FREQ = ''I''';
         END IF;

         --09-09-2009-end

         -- AGK -26-DEC-2007 (ACNUM CONDITION ADDED)
         IF W_INTERNAL_ACNUM = 0
         THEN
            W_SQL :=
                  W_SQL
               || ' AND LNPRD_INT_APPL_FREQ <>'
               || CHR (39)
               || 'X'
               || CHR (39);
         END IF;

         IF (W_PROD_CODE > 0)
         THEN
            W_SQL := W_SQL || ' AND ACNTS_PROD_CODE = ' || W_PROD_CODE;
         END IF;

         IF (W_INTERNAL_ACNUM > 0)
         THEN
            W_SQL :=
               W_SQL || ' AND LNACNT_INTERNAL_ACNUM = ' || W_INTERNAL_ACNUM;
         END IF;

         IF (W_BRN_CODE > 0)
         THEN
            W_SQL := W_SQL || ' AND ACNTS_BRN_CODE = ' || W_BRN_CODE;
         END IF;

         IF (TRIM (W_CURR_CODE) IS NOT NULL)
         THEN
            W_SQL :=
                  W_SQL
               || ' AND ACNTS_CURR_CODE = '
               || CHR (39)
               || W_CURR_CODE
               || CHR (39);
         END IF;

         -- AGK -26-DEC-2007 (ACNUM CONDITION ADDED)
         IF W_INTERNAL_ACNUM = 0
         THEN
            IF W_EOD_MQHY_FLG = 'Y'
            THEN
               W_DUMMY_STR :=
                  ' AND ( LNPRD_INT_APPL_FREQ = ''Y'' OR LNPRD_INT_APPL_FREQ = ''H'' OR LNPRD_INT_APPL_FREQ = ''Q'' OR LNPRD_INT_APPL_FREQ = ''M'' ) ';
            ELSIF W_EOD_MQHY_FLG = 'H'
            THEN
               W_DUMMY_STR :=
                  ' AND ( LNPRD_INT_APPL_FREQ = ''H'' OR LNPRD_INT_APPL_FREQ = ''Q'' OR LNPRD_INT_APPL_FREQ = ''M'' ) ';
            ELSIF W_EOD_MQHY_FLG = 'Q'
            THEN
               W_DUMMY_STR :=
                  ' AND ( LNPRD_INT_APPL_FREQ = ''Q'' OR LNPRD_INT_APPL_FREQ = ''M'' ) ';
            ELSIF W_EOD_MQHY_FLG = 'M'
            THEN
               W_DUMMY_STR := ' AND ( LNPRD_INT_APPL_FREQ = ''M'' ) ';
            END IF;

            W_SQL := W_SQL || W_DUMMY_STR;
         END IF;

         -- R.Senthil Kumar - 11-June-2010 - Removed - Begin
         /*   -- R.Senthil Kumar - 07-June-2010 - Begin
         W_SQL := W_SQL ||
                  ' AND ACNTS_INTERNAL_ACNUM NOT IN (SELECT LNACINTCTL_INTERNAL_ACNUM FROM LNACINTCTL WHERE LNACINTCTL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND LNACINTCTL_INTERNAL_ACNUM = ACNTS_INTERNAL_ACNUM AND LNACINTCTL_INT_APPL_REQD <> ''1'')';
         -- R.Senthil Kumar - 07-June-2010 - End*/
         -- R.Senthil Kumar - 11-June-2010 - Removed - End

         W_SQL := W_SQL || ' ORDER BY ACNTS_INTERNAL_ACNUM';


         --DBMS_OUTPUT.PUT_LINE(W_SQL);



         EXECUTE IMMEDIATE W_SQL BULK COLLECT INTO STS_REC;

         IF STS_REC.FIRST IS NOT NULL
         THEN
            FOR J IN STS_REC.FIRST .. STS_REC.LAST
            LOOP
               W_BRN_CODE := STS_REC (J).V_BRN_CODE;
               W_PROD_CODE := STS_REC (J).V_PROD_CODE;
               W_SCHEME_CODE := STS_REC (J).V_SCHEME_CODE;
               W_CURR_CODE := STS_REC (J).V_CURR_CODE;
               W_INTERNAL_ACNUM := STS_REC (J).V_INTERNAL_ACNUM;
               W_PA_ACCR_UPTO := STS_REC (J).V_PA_ACCR_UPTO;
               W_INT_APPL_UPTO_DATE := STS_REC (J).V_INT_APPL_UPTO_DATE;
               W_SCHEME_REQD := STS_REC (J).V_SCHEME_REQD;
               W_INT_APPL_FREQ := STS_REC (J).V_INT_APPL_FREQ;
               W_OPENING_DATE := STS_REC (J).V_OPENING_DATE;
               W_INT_RECOVERY_OPTION := STS_REC (J).V_INT_RECOVERY_OPTION;
               W_LIMIT_CHECK_REQ := STS_REC (J).V_LIMIT_CHECK_REQ; -- NEELS-MDS-10-NOV-2010 ADD

               --Prasanth NS-CHN-26-03-2009-added
               IF PKG_PROCESS_CHECK.FN_IGNORE_ACNUM (
                     PKG_ENTITY.FN_GET_ENTITY_CODE,
                     W_INTERNAL_ACNUM) = FALSE
               THEN
                  -- R.Senthil Kumar - 11-June-2010 - Begin
                  W_IGNORE := '0';
                  W_COUNT := 0;
                  V_ACCOUNT_COUNT := 0;

                 <<CHECK_INT_DISABLED>>
                  BEGIN
                     SELECT COUNT (0)
                       INTO W_COUNT
                       FROM LNACINTCTL
                      WHERE     LNACINTCTL_ENTITY_NUM =
                                   PKG_ENTITY.FN_GET_ENTITY_CODE
                            AND LNACINTCTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                            AND LNACINTCTL_INT_APPL_REQD <> '1';

                     IF W_COUNT > 0
                     THEN
                        W_IGNORE := '1';
                     END IF;
                  END CHECK_INT_DISABLED;

                 <<SKIP_INTEREST_NOT_ACCRU>> ---- Added by rajib.pradhan for skip accounts which has no accrual.
                  BEGIN
                     SELECT COUNT (LOANIA_ACNT_NUM)
                       INTO V_ACCOUNT_COUNT
                       FROM LOANIA
                      WHERE     LOANIA_ENTITY_NUM =
                                   PKG_ENTITY.FN_GET_ENTITY_CODE
                            AND LOANIA_ACNT_NUM = W_INTERNAL_ACNUM
                            AND (   W_INT_APPL_UPTO_DATE IS NULL
                                 OR LOANIA_ACCRUAL_DATE >
                                       W_INT_APPL_UPTO_DATE)
                            AND LOANIA_ACCRUAL_DATE <= W_CBD
                            AND LOANIA_BRN_CODE = W_BRN_CODE;
                  END SKIP_INTEREST_NOT_ACCRU;

                  IF V_ACCOUNT_COUNT = 0
                  THEN
                     W_IGNORE := '1';
                  END IF;

                  ---- Added by rajib.pradhan for skip accounts which has no accrual.

                  IF W_IGNORE = '0'
                  THEN
                     -- R.Senthil Kumar - 11-June-2010 - End
                     PROCEED_PARA;
                  END IF;
               END IF;
            END LOOP;
         END IF;

         POST_INTEREST;
      END READ_ACNT;

      PROCEDURE PROCEED_PARA
      IS
      BEGIN
         GET_INT_ACCRUED;
      --22-10-2009-beg
      -- Commented by Avinash-SONALI-21AUG2012 (begin) to remove updation of LNSUSPLED and LNSUSPBAL in interest Application process
      /*
            IF W_LOAN_INT_ON_RECOVERY = FALSE THEN
              --22-10-2009-end
              POST_NPA;
            END IF;
      */
      -- Commented by Avinash-SONALI-21AUG2012 (end) to remove updation of LNSUSPLED and LNSUSPBAL in interest Application process
      END PROCEED_PARA;

      PROCEDURE GET_INT_ACCRUED
      IS
      BEGIN
         IF W_LOAN_INT_ON_RECOVERY = FALSE
         THEN
            SELECT NVL (SUM (LOANIA_INT_AMT), 0),
                   NVL (SUM (LOANIA_INT_AMT_RND), 0),
                   NVL (SUM (LOANIA_OD_INT_AMT_RND), 0),
                   NVL (SUM (LOANIA_OD_INT_AMT), 0),
                   NVL (SUM (LOANIA_NPA_INT_POSTED_AMT), 0)
              INTO W_TOT_INT_AMT,
                   W_TOT_INT_AMT_RND,
                   W_TOT_OD_INT_AMT_RND,
                   W_TOT_OD_INT_AMT,
                   W_NPA_INT_AMT_POSTED
              FROM LOANIA
             WHERE     LOANIA_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND LOANIA_ACNT_NUM = W_INTERNAL_ACNUM
                   AND (   W_INT_APPL_UPTO_DATE IS NULL
                        OR LOANIA_ACCRUAL_DATE > W_INT_APPL_UPTO_DATE)
                   AND LOANIA_ACCRUAL_DATE <= W_CBD
                   AND LOANIA_BRN_CODE = W_BRN_CODE;
         --AND LOANIA_NPA_STATUS <> '1'; -- Commented by Avinash-SONALI-21AUG2012 to include all accounts for posting.
         ELSE
            SELECT W_INT_RECOV_AC_AMT,
                   W_INT_RECOV_AC_AMT,
                   0,
                   0,
                   W_NPA_INT_RECOV_AC_AMT
              INTO W_TOT_INT_AMT,
                   W_TOT_INT_AMT_RND,
                   W_TOT_OD_INT_AMT_RND,
                   W_TOT_OD_INT_AMT,
                   W_NPA_INT_AMT_POSTED
              FROM DUAL;
         END IF;

         --16-10-2008-beg
         /*      W_SUM_TOT_INT_AMT     := W_TOT_INT_AMT + W_TOT_OD_INT_AMT +
                                        W_NPA_INT_AMT_POSTED;
               W_SUM_TOT_INT_AMT_RND := W_TOT_INT_AMT_RND + W_TOT_OD_INT_AMT_RND +
                                        W_NPA_INT_AMT_POSTED;
         */
         W_SUM_TOT_INT_AMT := W_TOT_INT_AMT + W_TOT_OD_INT_AMT;

         W_SUM_TOT_INT_AMT_RND := W_TOT_INT_AMT_RND + W_TOT_OD_INT_AMT_RND;

         --16-10-2008-end

         GET_CURR_SPECIFIC_PARAM;

         W_AMT := W_SUM_TOT_INT_AMT;
         W_AMT := ABS (W_AMT);
         GET_ROUNDED_AMT;
         W_ACT_INT_AMT := W_AMT_RND;

         IF (W_SUM_TOT_INT_AMT < 0)
         THEN
            W_ACT_INT_AMT := W_ACT_INT_AMT * -1;
         END IF;

         W_RNDOFF_DIFF := ABS (W_SUM_TOT_INT_AMT_RND) - ABS (W_ACT_INT_AMT);
         --   02-12-2007-rem   W_RNDOFF_DIFF := SP_GETFORMAT(W_CURR_CODE,W_RNDOFF_DIFF);

         -- FORMAT REVERSE CONDITION ADDED
         W_RNDOFF_DIFF :=
            SP_GETFORMAT (PKG_ENTITY.FN_GET_ENTITY_CODE,
                          W_CURR_CODE,
                          W_RNDOFF_DIFF,
                          1);

         IF (W_INT_RECOVERY_OPTION = '3')
         THEN
            GET_NEXT_INSTALL_DUE_DATE;
         END IF;

         UPDATE_RTMPINTAPPL;

         --22-10-2009-beg
         IF W_LOAN_INT_ON_RECOVERY = FALSE
         THEN
            IF W_NPA_INT_RECOV_AC_AMT <> 0
            THEN
               W_NPA_ACT_INT_AMT := ABS (W_NPA_INT_RECOV_AC_AMT) * -1;
               W_NPA_INT_FROM_DATE := W_INT_UPTO_DATE;
               W_NPA_INT_UPTO_DATE := W_INT_UPTO_DATE;
               UPDATE_LNSUSPLED;
               UPDATE_LNSUSPBAL;
               W_NPA_ACT_INT_AMT := ABS (W_NPA_INT_RECOV_AC_AMT);
               W_NPA_INT_FROM_DATE := W_INT_UPTO_DATE;
               W_NPA_INT_UPTO_DATE := W_INT_UPTO_DATE;
               UPDATE_LNSUSPLED;
               UPDATE_LNSUSPBAL;
            END IF;
         END IF;
      --22-10-2009-end

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_ERROR := '';
      END GET_INT_ACCRUED;

      PROCEDURE GET_CURR_SPECIFIC_PARAM
      IS
      BEGIN
         SELECT DECODE (TRIM (LNCUR_INT_RNDOFF_PARAM),
                        NULL, 'T',
                        LNCUR_INT_RNDOFF_PARAM),
                LNCUR_INT_RNDOFF_PRECISION,
                LNCUR_MIN_INT_AMT
           INTO W_INT_RNDOFF_PARAM, W_INT_RNDOFF_PRECISION, W_MIN_INT_AMT
           FROM LNCURPM
          WHERE     LNCUR_PROD_CODE = W_PROD_CODE
                AND LNCUR_SCHEME_CODE =
                       DECODE (W_SCHEME_REQD, '1', W_SCHEME_CODE, ' ')
                AND LNCUR_CURR_CODE = W_CURR_CODE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_INT_RNDOFF_PARAM := 'T';
            W_INT_RNDOFF_PRECISION := 0;
            W_MIN_INT_AMT := 0;
      END GET_CURR_SPECIFIC_PARAM;

      PROCEDURE GET_ROUNDED_AMT
      IS
      BEGIN
         W_AMT_RND :=
            FN_ROUNDOFF (PKG_ENTITY.FN_GET_ENTITY_CODE,
                         W_AMT,
                         W_INT_RNDOFF_PARAM,
                         W_INT_RNDOFF_PRECISION);
      END GET_ROUNDED_AMT;

      PROCEDURE GET_NEXT_INSTALL_DUE_DATE
      IS
      BEGIN
         W_REPAY_EXIT := '0';
         W_NEXT_INSTALL_DATE := NULL;

         FOR CRS_REC
            IN (SELECT LNACRSDTL_REPAY_AMT,
                       LNACRSDTL_REPAY_FREQ,
                       LNACRSDTL_REPAY_FROM_DATE,
                       LNACRSDTL_NUM_OF_INSTALLMENT
                  FROM LNACRSDTL
                 WHERE     LNACRSDTL_ENTITY_NUM =
                              PKG_ENTITY.FN_GET_ENTITY_CODE
                       AND LNACRSDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM)
         LOOP
            W_REPAY_AMT := CRS_REC.LNACRSDTL_REPAY_AMT;
            W_REPAY_FREQ := CRS_REC.LNACRSDTL_REPAY_FREQ;
            W_REPAY_FROM_DATE := CRS_REC.LNACRSDTL_REPAY_FROM_DATE;
            W_NOF_INSTALL := CRS_REC.LNACRSDTL_NUM_OF_INSTALLMENT;

            IF W_REPAY_EXIT = 0
            THEN
               PROC_REPAY;
            END IF;
         END LOOP;
      END GET_NEXT_INSTALL_DUE_DATE;

      PROCEDURE PROC_REPAY
      IS
      BEGIN
         IF (W_REPAY_FREQ = 'M')
         THEN
            W_REPAY_END_DATE :=
               ADD_MONTHS (W_REPAY_FROM_DATE, ( (W_NOF_INSTALL - 1) * 1));
         ELSIF (W_REPAY_FREQ = 'Q')
         THEN
            W_REPAY_END_DATE :=
               ADD_MONTHS (W_REPAY_FROM_DATE, ( (W_NOF_INSTALL - 1) * 3));
         ELSIF (W_REPAY_FREQ = 'H')
         THEN
            W_REPAY_END_DATE :=
               ADD_MONTHS (W_REPAY_FROM_DATE, ( (W_NOF_INSTALL - 1) * 6));
         ELSIF (W_REPAY_FREQ = 'Y')
         THEN
            W_REPAY_END_DATE :=
               ADD_MONTHS (W_REPAY_FROM_DATE, ( (W_NOF_INSTALL - 1) * 12));
         ELSE
            W_REPAY_END_DATE := W_REPAY_FROM_DATE;
         END IF;

         -- Karthik-chn-30-oct-2007-rem      WHILE (W_REPAY_EXIT = 0) LOOP
         PROC_REPAY_SUB;
      -- Karthik-chn-30-oct-2007-rem      END LOOP;
      END PROC_REPAY;

      PROCEDURE PROC_REPAY_SUB
      IS
      BEGIN
         IF (W_REPAY_FREQ = 'X')
         THEN
            W_NEXT_INSTALL_DATE := W_REPAY_END_DATE;
            W_REPAY_EXIT := 1;
         ELSIF (W_REPAY_FROM_DATE > W_CBD)
         THEN
            W_NEXT_INSTALL_DATE := W_REPAY_FROM_DATE;
            W_REPAY_EXIT := 1;
         ELSIF (W_REPAY_END_DATE <= W_CBD)
         THEN
            W_NEXT_INSTALL_DATE := W_REPAY_END_DATE;
         ELSE
            GET_NEXT_REPAY_DATE;
         END IF;
      END PROC_REPAY_SUB;

      PROCEDURE GET_NEXT_REPAY_DATE
      IS
      BEGIN
         W_REPAY_DATE := W_REPAY_FROM_DATE;
         W_CHK_NOF_INSTALL := W_NOF_INSTALL;

         WHILE (W_REPAY_DATE < W_CBD AND W_CHK_NOF_INSTALL > 0)
         LOOP
            GET_NEXT_REPAY_DATE_SUB;
         END LOOP;

         W_NEXT_INSTALL_DATE := W_REPAY_DATE;

         IF (W_NEXT_INSTALL_DATE > W_CBD)
         THEN
            W_REPAY_EXIT := 1;
         END IF;
      END GET_NEXT_REPAY_DATE;

      PROCEDURE GET_NEXT_REPAY_DATE_SUB
      IS
      BEGIN
         IF (W_REPAY_FREQ = 'M')
         THEN
            W_REPAY_DATE := ADD_MONTHS (W_REPAY_DATE, 1);
         ELSIF (W_REPAY_FREQ = 'Q')
         THEN
            W_REPAY_END_DATE := ADD_MONTHS (W_REPAY_DATE, 3);
         ELSIF (W_REPAY_FREQ = 'H')
         THEN
            W_REPAY_END_DATE := ADD_MONTHS (W_REPAY_DATE, 6);
         ELSIF (W_REPAY_FREQ = 'Y')
         THEN
            W_REPAY_END_DATE := ADD_MONTHS (W_REPAY_DATE, 12);
         END IF;

         W_CHK_NOF_INSTALL := W_CHK_NOF_INSTALL - 1;
      END GET_NEXT_REPAY_DATE_SUB;

      PROCEDURE UPDATE_RTMPINTAPPL
      IS
         W_FROM_DATE      DATE;
         W_INT_DUE_DATE   DATE;
      BEGIN
         IF (W_TEMP_SER = 0)
         THEN
            W_TEMP_SER :=
               PKG_PB_GLOBAL.SP_GET_REPORT_SL (PKG_ENTITY.FN_GET_ENTITY_CODE);
         END IF;

         IF (W_INT_APPL_UPTO_DATE IS NULL)
         THEN
            W_FROM_DATE := W_OPENING_DATE;
         ELSE
            W_FROM_DATE := W_INT_APPL_UPTO_DATE + 1;
         END IF;

         IF (W_INT_RECOVERY_OPTION = '3')
         THEN
            W_INT_DUE_DATE := W_NEXT_INSTALL_DATE;
         ELSE
            W_INT_DUE_DATE := NULL;
         END IF;

         INSERT INTO RTMPINTAPPL (RTMPINTAPPL_TMP_SER,
                                  RTMPINTAPPL_BRN_CODE,
                                  RTMPINTAPPL_ACNT_NUM,
                                  RTMPINTAPPL_ACT_INT_AMT,
                                  RTMPINTAPPL_ACCR_INT_AMT,
                                  RTMPINTAPPL_RND_DIFF,
                                  RTMPINTAPPL_FROM_DATE,
                                  RTMPINTAPPL_UPTO_DATE,
                                  RTMPINTAPPL_INT_DUE_DATE,
                                  RTMPINTAPPL_NPA_ACCR_INT_AMT)
              VALUES (
                        W_TEMP_SER,
                        W_BRN_CODE,
                        W_INTERNAL_ACNUM,
                        W_ACT_INT_AMT,
                        W_SUM_TOT_INT_AMT_RND,
                        W_RNDOFF_DIFF,
                        W_FROM_DATE,
                        --natarajan.a-chn-18-06-2008-beg
                        CASE
                           WHEN W_PA_ACCR_UPTO < W_FROM_DATE THEN W_FROM_DATE
                           ELSE W_PA_ACCR_UPTO
                        END,
                        --natarajan.a-chn-18-06-2008-end
                        W_INT_DUE_DATE,
                        W_NPA_INT_RECOV_AC_AMT);
      END UPDATE_RTMPINTAPPL;

      -- NEELS-MDS-10-NOV-2010 BEG

      PROCEDURE UPDATE_LNINTPEND (P_ACT_LIMIT_AMT   IN NUMBER,
                                  P_ACT_INT_AMT     IN NUMBER,
                                  P_DIFF_AMOUNT     IN NUMBER)
      IS
         W_FROM_DATE   DATE;
      BEGIN
         IF (W_INT_APPL_UPTO_DATE IS NULL)
         THEN
            W_FROM_DATE := W_OPENING_DATE;
         ELSE
            W_FROM_DATE := W_INT_APPL_UPTO_DATE + 1;
         END IF;

         INSERT INTO LNINTPEND (LNINTP_ENTITY_NUMBER,
                                LNINTP_INTERNAL_ACNUM,
                                LNINTP_INTAPPL_DATE,
                                LNINTP_ACT_INT_AMOUNT,
                                LNINTP_ACT_LIMIT,
                                LNINTP_PENDING_AMT,
                                LNINTP_FROM_DATE,
                                LNINTP_UPTO_DATE,
                                LNINTP_TOBE_REC)
              VALUES (
                        PKG_ENTITY.FN_GET_ENTITY_CODE,
                        W_INTERNAL_ACNUM,
                        W_CBD,
                        P_ACT_INT_AMT,
                        P_ACT_LIMIT_AMT,
                        P_DIFF_AMOUNT,
                        W_FROM_DATE,
                        CASE
                           WHEN W_PA_ACCR_UPTO < W_FROM_DATE THEN W_FROM_DATE
                           ELSE W_PA_ACCR_UPTO
                        END,
                        P_DIFF_AMOUNT);
      END UPDATE_LNINTPEND;

      -- NEELS-MDS-10-NOV-2010 END
      PROCEDURE POST_NPA
      IS
      BEGIN
         -- CHN  Guna 19/07/2010 begin
         W_NPA_TOT_INT_AMT := 0;
         W_NPA_TOT_OD_INT_AMT := 0;
         W_NPA_INT_AMT_RND := 0;
         W_NPA_OD_INT_AMT_RND := 0;

         -- CHN  Guna 19/07/2010 END
         SELECT NVL (SUM (LOANIA_INT_AMT), 0),
                NVL (SUM (LOANIA_OD_INT_AMT), 0),
                -- CHN  Guna 19/07/2010 begin
                NVL (SUM (LOANIA_INT_AMT_RND), 0),
                NVL (SUM (LOANIA_OD_INT_AMT_RND), 0)
           -- CHN  Guna 19/07/2010 end
           INTO W_NPA_TOT_INT_AMT,
                W_NPA_TOT_OD_INT_AMT,
                -- CHN  Guna 19/07/2010 begin
                W_NPA_INT_AMT_RND,
                W_NPA_OD_INT_AMT_RND
           -- CHN  Guna 19/07/2010 end
           FROM LOANIA
          WHERE     LOANIA_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND LOANIA_ACNT_NUM = W_INTERNAL_ACNUM
                AND (   W_INT_APPL_UPTO_DATE IS NULL
                     OR LOANIA_ACCRUAL_DATE > W_INT_APPL_UPTO_DATE)
                AND (   LOANIA_ACCRUAL_DATE > W_PA_ACCR_UPTO
                     OR W_PA_ACCR_UPTO IS NULL)
                AND LOANIA_BRN_CODE = W_BRN_CODE
                AND LOANIA_NPA_STATUS = '1';

         SELECT MIN (LOANIA_ACCRUAL_DATE)
           INTO W_NPA_INT_FROM_DATE
           FROM LOANIA
          WHERE     LOANIA_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND LOANIA_ACNT_NUM = W_INTERNAL_ACNUM
                AND (   LOANIA_ACCRUAL_DATE > W_INT_APPL_UPTO_DATE
                     OR W_INT_APPL_UPTO_DATE IS NULL)
                AND (   LOANIA_ACCRUAL_DATE > W_PA_ACCR_UPTO
                     OR W_PA_ACCR_UPTO IS NULL)
                AND LOANIA_BRN_CODE = W_BRN_CODE
                AND LOANIA_NPA_STATUS = '1';

         W_NPA_INT_UPTO_DATE := W_CBD;
         W_NPA_SUM_TOT_INT_AMT := W_NPA_TOT_INT_AMT + W_NPA_TOT_OD_INT_AMT;
         W_ACCR_NPA_INT_AMT_RND := W_NPA_INT_AMT_RND + W_NPA_OD_INT_AMT_RND; -- Add Guna 19/07/2010
         W_AMT := W_NPA_SUM_TOT_INT_AMT;
         W_AMT := ABS (W_AMT);
         GET_ROUNDED_AMT;
         W_NPA_ACT_INT_AMT := W_AMT_RND;

         IF (W_NPA_SUM_TOT_INT_AMT < 0)
         THEN
            W_NPA_ACT_INT_AMT := W_NPA_ACT_INT_AMT * -1;
         END IF;

         CHECK_CURR_NPA_STAT;

         IF (W_NPA_ACNT = '1')
         THEN
            POST_NPA_SUB;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_ERROR := '';
      END POST_NPA;

      PROCEDURE CHECK_CURR_NPA_STAT
      IS
      BEGIN
         W_NPA_ACNT := 0;

         SELECT ASSETCD_ASSET_CLASS
           INTO W_ASSET_CLASS
           FROM ASSETCLS, ASSETCD
          WHERE     ASSETCLS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND ASSETCLS_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND ASSETCLS_ASSET_CODE = ASSETCD_CODE;

         IF (W_ASSET_CLASS = 'N')
         THEN
            W_NPA_ACNT := 1;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_NPA_ACNT := 0;
      END CHECK_CURR_NPA_STAT;

      PROCEDURE POST_NPA_SUB
      IS
      BEGIN
         IF (W_NPA_ACT_INT_AMT <> 0)
         THEN
            UPDATE_LNSUSPLED;
            UPDATE_LNSUSPBAL;
         END IF;

         UPDATE_LNINTAPPL_NPA;

         IF (P_INTERNAL_ACNUM IS NULL OR P_INTERNAL_ACNUM = 0)
         THEN
            --CHG ARUNMUGESH J 27-12-2007 BEG
            UPDATE LOANACNTS
               SET LNACNT_INT_APPLIED_UPTO_DATE = W_CBD
             WHERE     LNACNT_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND LNACNT_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
         ELSE
            UPDATE LOANACNTS
               SET LNACNT_INT_APPLIED_UPTO_DATE = W_PREV_CBD
             WHERE     LNACNT_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND LNACNT_INTERNAL_ACNUM = W_INTERNAL_ACNUM; --CHG ARUNMUGESH J 27-12-2007 BEG
         END IF;

         W_MAX_SL := 0;
      END POST_NPA_SUB;

      PROCEDURE UPDATE_LNSUSPLED
      IS
         W_CRDB_FLG   CHAR (1);
         W_CBD_TIME   VARCHAR2 (20);
      BEGIN
         SELECT NVL (MAX (LNSUSP_SL_NUM), 0) + 1
           INTO W_MAX_SL
           FROM LNSUSPLED
          WHERE     LNSUSP_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND LNSUSP_ACNT_NUM = W_INTERNAL_ACNUM
                AND LNSUSP_TRAN_DATE = W_CBD;

         IF (W_NPA_ACT_INT_AMT > 0)
         THEN
            W_CRDB_FLG := 'C';
         ELSE
            W_CRDB_FLG := 'D';
         END IF;

         W_CBD_TIME :=
               W_CBD
            || ' '
            || PKG_PB_GLOBAL.FN_GET_CURR_BUS_TIME (
                  PKG_ENTITY.FN_GET_ENTITY_CODE);

         INSERT INTO LNSUSPLED (LNSUSP_ENTITY_NUM,
                                LNSUSP_ACNT_NUM,
                                LNSUSP_TRAN_DATE,
                                LNSUSP_SL_NUM,
                                LNSUSP_VALUE_DATE,
                                LNSUSP_ENTRY_TYPE,
                                LNSUSP_DB_CR_FLG,
                                LNSUSP_CURR_CODE,
                                LNSUSP_AMOUNT,
                                LNSUSP_INT_AMT,
                                LNSUSP_CHGS_AMT,
                                LNSUSP_INT_FROM_DATE,
                                LNSUSP_INT_UPTO_DATE,
                                LNSUSP_REMARKS1,
                                LNSUSP_REMARKS2,
                                LNSUSP_REMARKS3,
                                LNSUSP_AUTO_MANUAL,
                                LNSUSP_ENTD_BY,
                                LNSUSP_ENTD_ON,
                                LNSUSP_LAST_MOD_BY,
                                LNSUSP_LAST_MOD_ON,
                                LNSUSP_AUTH_BY,
                                LNSUSP_AUTH_ON,
                                TBA_MAIN_KEY)
              VALUES (PKG_ENTITY.FN_GET_ENTITY_CODE,
                      W_INTERNAL_ACNUM,
                      W_CBD,
                      W_MAX_SL,
                      W_CBD,
                      '2',
                      W_CRDB_FLG,
                      W_CURR_CODE,
                      ABS (W_NPA_ACT_INT_AMT),
                      ABS (W_NPA_ACT_INT_AMT),
                      0,
                      W_NPA_INT_FROM_DATE,
                      W_NPA_INT_UPTO_DATE,
                      'By Interest Applicaton',
                      '',
                      '',
                      'A',
                      W_USER_ID,
                      TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'),
                      '',
                      NULL,
                      W_USER_ID,
                      TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'),
                      '');
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR := 'Error in Creating LNSUSPLED';
            RAISE E_USEREXCEP;
      END UPDATE_LNSUSPLED;

      PROCEDURE UPDATE_LNSUSPBAL
      IS
         W_DB_SUM   NUMBER;
         W_CR_SUM   NUMBER;
      BEGIN
         SELECT LNSUSPBAL_SUSP_BAL
           INTO DUMMY
           FROM LNSUSPBAL
          WHERE     LNSUSPBAL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND LNSUSPBAL_ACNT_NUM = W_INTERNAL_ACNUM
                AND LNSUSPBAL_CURR_CODE = W_CURR_CODE;

         IF (W_NPA_ACT_INT_AMT > 0)
         THEN
            UPDATE LNSUSPBAL
               SET LNSUSPBAL_SUSP_BAL = LNSUSPBAL_SUSP_BAL + W_NPA_ACT_INT_AMT,
                   LNSUSPBAL_SUSP_CR_SUM =
                      LNSUSPBAL_SUSP_CR_SUM + W_NPA_ACT_INT_AMT,
                   LNSUSPBAL_INT_BAL = LNSUSPBAL_INT_BAL + W_NPA_ACT_INT_AMT
             WHERE     LNSUSPBAL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND LNSUSPBAL_ACNT_NUM = W_INTERNAL_ACNUM
                   AND LNSUSPBAL_CURR_CODE = W_CURR_CODE;
         ELSE
            IF (W_NPA_ACT_INT_AMT < 0)
            THEN
               UPDATE LNSUSPBAL
                  SET LNSUSPBAL_SUSP_BAL =
                         LNSUSPBAL_SUSP_BAL - ABS (W_NPA_ACT_INT_AMT),
                      LNSUSPBAL_SUSP_DB_SUM =
                         LNSUSPBAL_SUSP_DB_SUM + ABS (W_NPA_ACT_INT_AMT),
                      LNSUSPBAL_INT_BAL =
                         LNSUSPBAL_INT_BAL - ABS (W_NPA_ACT_INT_AMT)
                WHERE     LNSUSPBAL_ENTITY_NUM =
                             PKG_ENTITY.FN_GET_ENTITY_CODE
                      AND LNSUSPBAL_ACNT_NUM = W_INTERNAL_ACNUM
                      AND LNSUSPBAL_CURR_CODE = W_CURR_CODE;
            END IF;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            IF (W_NPA_ACT_INT_AMT > 0)
            THEN
               W_CR_SUM := W_NPA_ACT_INT_AMT;
               W_DB_SUM := 0;
            ELSE
               IF (W_NPA_ACT_INT_AMT < 0)
               THEN
                  W_DB_SUM := ABS (W_NPA_ACT_INT_AMT);
                  W_CR_SUM := 0;
               END IF;
            END IF;

           <<ADD_LNSUSPBAL>>
            BEGIN
               INSERT INTO LNSUSPBAL (LNSUSPBAL_ENTITY_NUM,
                                      LNSUSPBAL_ACNT_NUM,
                                      LNSUSPBAL_CURR_CODE,
                                      LNSUSPBAL_SUSP_BAL,
                                      LNSUSPBAL_SUSP_DB_SUM,
                                      LNSUSPBAL_SUSP_CR_SUM,
                                      LNSUSPBAL_PRIN_BAL,
                                      LNSUSPBAL_INT_BAL,
                                      LNSUSPBAL_CHG_BAL,
                                      LNSUSPBAL_WRTOFF_AMT,
                                      LNSUSPBAL_WRTOFF_RECOV,
                                      LNSUSPBAL_PROV_HELD,
                                      LNSUSPBAL_BC_PROV_HELD)
                    VALUES (PKG_ENTITY.FN_GET_ENTITY_CODE,
                            W_INTERNAL_ACNUM,
                            W_CURR_CODE,
                            W_NPA_ACT_INT_AMT,
                            W_DB_SUM,
                            W_CR_SUM,
                            0,
                            W_NPA_ACT_INT_AMT,
                            0,
                            0,
                            0,
                            0,
                            0);
            EXCEPTION
               WHEN OTHERS
               THEN
                  W_ERROR := 'Error in Creating LNSUSPBAL';
                  RAISE E_USEREXCEP;
            END ADD_LNSUSPBAL;
      END UPDATE_LNSUSPBAL;

      PROCEDURE UPDATE_LNINTAPPL_NPA
      IS
         W_CBD_TIME   VARCHAR2 (20);
      BEGIN
         W_CBD_TIME :=
               W_CBD
            || ' '
            || PKG_PB_GLOBAL.FN_GET_CURR_BUS_TIME (
                  PKG_ENTITY.FN_GET_ENTITY_CODE);

         SELECT LNINTAPPL_ACT_INT_AMT
           INTO DUMMY
           FROM LNINTAPPL
          WHERE     LNINTAPPL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND LNINTAPPL_BRN_CODE = W_BRN_CODE
                AND LNINTAPPL_ACNT_NUM = W_INTERNAL_ACNUM
                AND LNINTAPPL_APPL_DATE = W_CBD;

         UPDATE LNINTAPPL
            SET LNINTAPPL_NPA_INT_AMT =
                   LNINTAPPL_NPA_INT_AMT + W_NPA_ACT_INT_AMT,
                LNINTAPPL_NPA_INT_FROM_DATE = W_NPA_INT_FROM_DATE,
                LNINTAPPL_NPA_INT_UPTO_DATE = W_NPA_INT_UPTO_DATE,
                LNINTAPPL_LNSUSPLED_SL_NUM = W_MAX_SL,
                LNINTAPPL_PROC_BY = W_USER_ID,
                LNINTAPPL_PROC_ON =
                   TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'),
                LNINTAPPL_ACCR_NPA_INTAMT_RND = W_ACCR_NPA_INT_AMT_RND -- Add Guna 19/07/2010
          WHERE     LNINTAPPL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND LNINTAPPL_BRN_CODE = W_BRN_CODE
                AND LNINTAPPL_ACNT_NUM = W_INTERNAL_ACNUM
                AND LNINTAPPL_APPL_DATE = W_CBD;

        <<INSERTLNINTAPPLDTLS>>
         BEGIN
            INSERT INTO LNINTAPPLDTLS (LNINTAPPLD_ENTITY_NUM,
                                       LNINTAPPLD_BRN_CODE,
                                       LNINTAPPLD_ACNT_NUM,
                                       LNINTAPPLD_APPL_DATE,
                                       LNINTAPPLD_APPL_SL,
                                       LNINTAPPLD_ACT_INT_AMT,
                                       LNINTAPPLD_ACCR_INT_AMT,
                                       LNINTAPPLD_RNDOFF_DIFF,
                                       LNINTAPPLD_INT_FROM_DATE,
                                       LNINTAPPLD_INT_UPTO_DATE,
                                       POST_TRAN_BRN,
                                       POST_TRAN_DATE,
                                       POST_TRAN_BATCH_NUM,
                                       LNINTAPPLD_NPA_INT_AMT,
                                       LNINTAPPLD_NPA_INT_FROM_DATE,
                                       LNINTAPPLD_NPA_INT_UPTO_DATE,
                                       LNINTAPPLD_LNSUSPLED_SL_NUM,
                                       LNINTAPPLD_INT_DUE_DATE,
                                       LNINTAPPLD_PROC_BY,
                                       LNINTAPPLD_PROC_ON,
                                       LNINTAPPLD_ACCR_NPA_INTAMT_RND) -- Add Guna 19/07/2010
                 VALUES (
                           PKG_ENTITY.FN_GET_ENTITY_CODE,
                           W_BRN_CODE,
                           W_INTERNAL_ACNUM,
                           W_CBD,
                           (SELECT NVL (MAX (A.LNINTAPPLD_APPL_SL), 1) + 1
                              FROM LNINTAPPLDTLS A
                             WHERE     LNINTAPPLD_ENTITY_NUM =
                                          PKG_ENTITY.FN_GET_ENTITY_CODE
                                   AND A.LNINTAPPLD_BRN_CODE = W_BRN_CODE
                                   AND A.LNINTAPPLD_ACNT_NUM =
                                          W_INTERNAL_ACNUM
                                   AND A.LNINTAPPLD_APPL_DATE = W_CBD),
                           W_RTMPINTAPPL_ACT_INT_AMT,
                           W_RTMPINTAPPL_ACCR_INT_AMT,
                           W_RTMPINTAPPL_RND_DIFF,
                           W_RTMPINTAPPL_FROM_DATE,
                           W_RTMPINTAPPL_UPTO_DATE,
                           0,
                           NULL,
                           0,
                           0,
                           NULL,
                           NULL,
                           0,
                           W_RTMPINTAPPL_INT_DUE_DATE,
                           W_USER_ID,
                           TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'),
                           W_ACCR_NPA_INT_AMT_RND);     -- Add Guna 19/07/2010
         END INSERTLNINTAPPLDTLS;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
           <<ADD_LNINTAPPL>>
            BEGIN
               INSERT INTO LNINTAPPL (LNINTAPPL_ENTITY_NUM,
                                      LNINTAPPL_BRN_CODE,
                                      LNINTAPPL_ACNT_NUM,
                                      LNINTAPPL_APPL_DATE,
                                      LNINTAPPL_ACT_INT_AMT,
                                      LNINTAPPL_ACCR_INT_AMT,
                                      LNINTAPPL_RNDOFF_DIFF,
                                      LNINTAPPL_INT_FROM_DATE,
                                      LNINTAPPL_INT_UPTO_DATE,
                                      POST_TRAN_BRN,
                                      POST_TRAN_DATE,
                                      POST_TRAN_BATCH_NUM,
                                      LNINTAPPL_NPA_INT_AMT,
                                      LNINTAPPL_NPA_INT_FROM_DATE,
                                      LNINTAPPL_NPA_INT_UPTO_DATE,
                                      LNINTAPPL_LNSUSPLED_SL_NUM,
                                      LNINTAPPL_INT_DUE_DATE,
                                      LNINTAPPL_PROC_BY,
                                      LNINTAPPL_PROC_ON,
                                      LNINTAPPL_ACCR_NPA_INTAMT_RND) -- Add Guna 19/07/2010
                    VALUES (PKG_ENTITY.FN_GET_ENTITY_CODE,
                            W_BRN_CODE,
                            W_INTERNAL_ACNUM,
                            W_CBD,
                            0,
                            0,
                            0,
                            NULL,
                            NULL,
                            0,
                            NULL,
                            0,
                            W_NPA_ACT_INT_AMT,
                            W_NPA_INT_FROM_DATE,
                            W_NPA_INT_UPTO_DATE,
                            W_MAX_SL,
                            NULL,
                            W_USER_ID,
                            TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'),
                            W_ACCR_NPA_INT_AMT_RND);    -- Add Guna 19/07/2010

              <<INSERTLNINTAPPLDTLS>>
               BEGIN
                  INSERT INTO LNINTAPPLDTLS (LNINTAPPLD_ENTITY_NUM,
                                             LNINTAPPLD_BRN_CODE,
                                             LNINTAPPLD_ACNT_NUM,
                                             LNINTAPPLD_APPL_DATE,
                                             LNINTAPPLD_APPL_SL,
                                             LNINTAPPLD_ACT_INT_AMT,
                                             LNINTAPPLD_ACCR_INT_AMT,
                                             LNINTAPPLD_RNDOFF_DIFF,
                                             LNINTAPPLD_INT_FROM_DATE,
                                             LNINTAPPLD_INT_UPTO_DATE,
                                             POST_TRAN_BRN,
                                             POST_TRAN_DATE,
                                             POST_TRAN_BATCH_NUM,
                                             LNINTAPPLD_NPA_INT_AMT,
                                             LNINTAPPLD_NPA_INT_FROM_DATE,
                                             LNINTAPPLD_NPA_INT_UPTO_DATE,
                                             LNINTAPPLD_LNSUSPLED_SL_NUM,
                                             LNINTAPPLD_INT_DUE_DATE,
                                             LNINTAPPLD_PROC_BY,
                                             LNINTAPPLD_PROC_ON,
                                             LNINTAPPLD_ACCR_NPA_INTAMT_RND) -- Add Guna 19/07/2010
                       VALUES (
                                 PKG_ENTITY.FN_GET_ENTITY_CODE,
                                 W_BRN_CODE,
                                 W_INTERNAL_ACNUM,
                                 W_CBD,
                                 (SELECT NVL (MAX (A.LNINTAPPLD_APPL_SL), 1)
                                    FROM LNINTAPPLDTLS A
                                   WHERE     LNINTAPPLD_ENTITY_NUM =
                                                PKG_ENTITY.FN_GET_ENTITY_CODE
                                         AND A.LNINTAPPLD_BRN_CODE =
                                                W_BRN_CODE
                                         AND A.LNINTAPPLD_ACNT_NUM =
                                                W_INTERNAL_ACNUM
                                         AND A.LNINTAPPLD_APPL_DATE = W_CBD),
                                 W_RTMPINTAPPL_ACT_INT_AMT,
                                 W_RTMPINTAPPL_ACCR_INT_AMT,
                                 W_RTMPINTAPPL_RND_DIFF,
                                 W_RTMPINTAPPL_FROM_DATE,
                                 W_RTMPINTAPPL_UPTO_DATE,
                                 0,
                                 NULL,
                                 0,
                                 0,
                                 NULL,
                                 NULL,
                                 0,
                                 W_RTMPINTAPPL_INT_DUE_DATE,
                                 W_USER_ID,
                                 TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'),
                                 W_ACCR_NPA_INT_AMT_RND); -- Add Guna 19/07/2010
               END INSERTLNINTAPPLDTLS;
            EXCEPTION
               WHEN OTHERS
               THEN
                  W_ERROR := 'Error in Creating LNINTAPPL';
                  RAISE E_USEREXCEP;
            END ADD_LNINTAPPL;
      END UPDATE_LNINTAPPL_NPA;

      PROCEDURE POST_INTEREST
      IS
         --09-06-2008-beg
         W_INT_FOUND   NUMBER (1);
      --09-06-2008-end
      BEGIN
         --09-06-2008-beg
         W_INT_FOUND := 0;
         --09-06-2008-end

         W_PREV_BRN_CODE := 0;

         FOR REC_TMP
            IN (  SELECT ACNTS_BRN_CODE,
                         ACNTS_PROD_CODE,
                         ACNTS_CURR_CODE,
                         RTMPINTAPPL_ACNT_NUM,
                         RTMPINTAPPL_ACT_INT_AMT,
                         RTMPINTAPPL_ACCR_INT_AMT,
                         RTMPINTAPPL_RND_DIFF,
                         RTMPINTAPPL_FROM_DATE,
                         RTMPINTAPPL_UPTO_DATE,
                         RTMPINTAPPL_INT_DUE_DATE,
                         RTMPINTAPPL_NPA_ACCR_INT_AMT,
                         LNPRD_LIMIT_CHK_REQD           -- Add Guna 11/01/2011
                    FROM RTMPINTAPPL, ACNTS, LNPRODPM -- Add  LNPRODPM Guna 11/01/2011
                   WHERE     ACNTS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                         AND RTMPINTAPPL_TMP_SER = W_TEMP_SER
                         AND ACNTS_INTERNAL_ACNUM = RTMPINTAPPL_ACNT_NUM
                         AND LNPRD_PROD_CODE = ACNTS_PROD_CODE
                --10-06-2008-rem                                                          AND RTMPINTAPPL_ACT_INT_AMT <> 0
                ORDER BY ACNTS_BRN_CODE, ACNTS_PROD_CODE, ACNTS_CURR_CODE)
         LOOP
            W_BRN_CODE := REC_TMP.ACNTS_BRN_CODE;
            W_PROD_CODE := REC_TMP.ACNTS_PROD_CODE;
            W_CURR_CODE := REC_TMP.ACNTS_CURR_CODE;
            W_INTERNAL_ACNUM := REC_TMP.RTMPINTAPPL_ACNT_NUM;
            W_RTMPINTAPPL_ACT_INT_AMT := REC_TMP.RTMPINTAPPL_ACT_INT_AMT;
            W_RTMPINTAPPL_ACCR_INT_AMT := REC_TMP.RTMPINTAPPL_ACCR_INT_AMT;
            W_RTMPINTAPPL_RND_DIFF := REC_TMP.RTMPINTAPPL_RND_DIFF;
            W_RTMPINTAPPL_FROM_DATE := REC_TMP.RTMPINTAPPL_FROM_DATE;
            W_RTMPINTAPPL_UPTO_DATE := REC_TMP.RTMPINTAPPL_UPTO_DATE;
            W_RTMPINTAPPL_INT_DUE_DATE := REC_TMP.RTMPINTAPPL_INT_DUE_DATE;
            --21-10-2009-beg
            W_RTMPINTAPPL_NPA_ACCR_INT_AMT := 0;
            W_RTMPINTAPPL_NPA_ACCR_INT_AMT :=
               REC_TMP.RTMPINTAPPL_NPA_ACCR_INT_AMT;
            --21-10-2009-end
            W_LIMIT_CHECK_REQ := REC_TMP.LNPRD_LIMIT_CHK_REQD; -- Add Guna 11/01/2011

            --natarajan.a-chn-09-06-2008-rem        IF ((W_PREV_BRN_CODE <> W_BRN_CODE AND W_PREV_BRN_CODE > 0)) THEN
            IF (    ( (W_PREV_BRN_CODE <> W_BRN_CODE AND W_PREV_BRN_CODE > 0))
                AND W_INT_FOUND = 1)
            THEN
               W_INT_FOUND := 0;
               POST_PARA;
            END IF;

           /*09-06-2008-rem        IF (W_RTMPINTAPPL_ACT_INT_AMT <> 0) THEN
                     <<BEGIN_POSTING>>
                     BEGIN
                       AUTOPOST_ARRAY_ASSIGN;
                       UPDATE_LNINTAPPL;
                       W_PREV_BRN_CODE := W_BRN_CODE;
                     EXCEPTION
                       WHEN E_SKP THEN
                         W_ERROR := '';
                     END BEGIN_POSTING;
                   END IF;
           */
           --natarajan.a-chn-09-06-2008-beg
           <<BEGIN_POSTING>>
            BEGIN
               -- Rem Guna 17/01/2011         IF (W_RTMPINTAPPL_ACT_INT_AMT <> 0) THEN
               -- CHN Guna 17/01/2011 start
               IF (   W_RTMPINTAPPL_ACT_INT_AMT <> 0
                   OR W_RTMPINTAPPL_RND_DIFF <> 0)
               THEN
                  -- CHN Guna 17/01/2011 end
                  AUTOPOST_ARRAY_ASSIGN;
                  W_INT_FOUND := 1;
               END IF;

               UPDATE_LNINTAPPL;

               W_PREV_BRN_CODE := W_BRN_CODE;
            EXCEPTION
               WHEN E_SKP
               THEN
                  W_ERROR := '';
            END BEGIN_POSTING;
         --natarajan.a-chn-09-06-2008-end
         END LOOP;

         --natarajan.a-chn-10-06-2008-rem      IF ((W_PREV_BRN_CODE > 0)) THEN
         IF ( ( (W_PREV_BRN_CODE > 0)) AND W_INT_FOUND = 1)
         THEN
            W_INT_FOUND := 0;
            POST_PARA;
         END IF;
      END POST_INTEREST;

      --16-08-2010-beg
      PROCEDURE PROC_FOR_IBASED_UNREAL_INC
      IS
      BEGIN
         -- FOR INCOME VOUCHER
         IDX := IDX + 1;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_INTERNAL_ACNUM := 0;

         IF (W_RTMPINTAPPL_ACT_INT_AMT < 0)
         THEN
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
         ELSE
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
         END IF;

         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_CURR_CODE := W_CURR_CODE;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_ACING_BRN_CODE := W_PREV_BRN_CODE;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_GLACC_CODE := W_INT_INCOME_GL;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
            ABS (W_RTMPINTAPPL_ACT_INT_AMT);
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_NARR_DTL1 :=
            'For Account Number :';
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_NARR_DTL2 :=
            FACNO (PKG_ENTITY.FN_GET_ENTITY_CODE, W_INTERNAL_ACNUM);
         -- FOR SUSPENSE VOUCHER
         -- reversing the suspense voucher
         IDX := IDX + 1;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_INTERNAL_ACNUM := 0;

         IF (W_RTMPINTAPPL_ACT_INT_AMT < 0)
         THEN
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
         ELSE
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
         END IF;

         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_CURR_CODE := W_CURR_CODE;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_ACING_BRN_CODE := W_PREV_BRN_CODE;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_GLACC_CODE :=
            W_INT_ACCRU_SUSP_HEAD;
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
            ABS (W_RTMPINTAPPL_ACT_INT_AMT);
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_NARR_DTL1 :=
            'For Account Number :';
         PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_NARR_DTL2 :=
            FACNO (PKG_ENTITY.FN_GET_ENTITY_CODE, W_INTERNAL_ACNUM);
      END PROC_FOR_IBASED_UNREAL_INC;

      --16-08-2010-end

      PROCEDURE AUTOPOST_ARRAY_ASSIGN
      IS
         W_LIMIT_AMT       NUMBER (18, 3);
         W_ACT_LIMIT_AMT   NUMBER (18, 3);
         W_DP_AMT          NUMBER (18, 3);
         W_ERROR           VARCHAR2 (100);
         W_TEMP_AMOUNT     NUMBER (18, 3);
      BEGIN
         GET_LOAN_ACNTNG_PARAM;

         -- NEELS-MDS-10-NOV-2010 beg
         W_TEMP_AMOUNT := W_RTMPINTAPPL_ACT_INT_AMT;

         IF W_LIMIT_CHECK_REQ = '1'
         THEN
            W_LIMIT_AMT :=
               GET_UNUSED_LIMIT (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                 W_INTERNAL_ACNUM);

            IF W_LIMIT_AMT < ABS (W_RTMPINTAPPL_ACT_INT_AMT)
            THEN
               W_RTMPINTAPPL_ACT_INT_AMT :=
                  ABS (W_LIMIT_AMT) * SIGN (W_TEMP_AMOUNT);
               UPDATE_LNINTPEND (W_LIMIT_AMT,
                                 (W_TEMP_AMOUNT),
                                 (W_TEMP_AMOUNT) + ABS (W_LIMIT_AMT));
            END IF;
         END IF;

         IF W_RTMPINTAPPL_ACT_INT_AMT <> 0
         THEN
            --- IF AMOUNT IS 0 AUTOPOST WILL GIVE ERROR 6015
            -- NEELS-MDS-10-NOV-2010 End

            IDX := IDX + 1;
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_INTERNAL_ACNUM :=
               W_INTERNAL_ACNUM;

            IF (W_RTMPINTAPPL_ACT_INT_AMT < 0)
            THEN
               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
            ELSE
               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
            END IF;

            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
               ABS (W_RTMPINTAPPL_ACT_INT_AMT);
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMT_BRKUP := '1';

            IDX1 := IDX1 + 1;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_BATCH_SL_NUM := IDX;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_PRIN_AC_AMT := 0;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_INTRD_AC_AMT :=
               ABS (W_RTMPINTAPPL_ACT_INT_AMT);
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_CHARGE_AC_AMT := 0;

            --16-08-2010-beg
            -- this is for handling ibased loans
            IF (LNPRD_ACPM.EXISTS (W_PROD_CODE))
            THEN
               /*  IF LNPRD_ACPM(W_PROD_CODE).V_LNPRD_INT_APPL_FREQ = 'I' AND LNPRD_ACPM(W_PROD_CODE)
               .V_LNPRD_UNREAL_INT_INCOME_REQD = '0' THEN*/
               -- NEELS-MDS-10-NOV-2010 Need to chek Need not check LNPRD_INT_APPL_FREQ = 'I'.
               -- only V_LNPRD_UNREAL_INT_INCOME_REQD is Required
               -- NEELS-MDS-30-NOV-2010 IF LNPRD_ACPM(W_PROD_CODE).V_LNPRD_UNREAL_INT_INCOME_REQD = '0' THEN
               IF LNPRD_ACPM (W_PROD_CODE).V_LNPRD_UNREAL_INT_INCOME_REQD =
                     '1'
               THEN
                  -- NEELS-MDS-30-NOV-2010
                  PROC_FOR_IBASED_UNREAL_INC;
               END IF;
            END IF;

            --16-08-2010-end

            APPEND_CONS_INTAMT_ARRAY;
         END IF;

         APPEND_CONS_ADJAMT_ARRAY;

         W_RTMPINTAPPL_ACT_INT_AMT := W_TEMP_AMOUNT; -- NEELS-MDS-10-NOV-2010 ADD

         --22-10-2009-beg
         IF W_RTMPINTAPPL_NPA_ACCR_INT_AMT <> 0
         THEN
            IDX := IDX + 1;
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_INTERNAL_ACNUM :=
               W_INTERNAL_ACNUM;

            IF (W_RTMPINTAPPL_NPA_ACCR_INT_AMT < 0)
            THEN
               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
            ELSE
               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
            END IF;

            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
               ABS (W_RTMPINTAPPL_NPA_ACCR_INT_AMT);
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMT_BRKUP := '1';

            IDX1 := IDX1 + 1;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_BATCH_SL_NUM := IDX;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_PRIN_AC_AMT := 0;
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_INTRD_AC_AMT :=
               ABS (W_RTMPINTAPPL_NPA_ACCR_INT_AMT);
            PKG_AUTOPOST.PV_TRAN_ADV_REC (IDX1).TRANADV_CHARGE_AC_AMT := 0;

            IDX1 := IDX1 + 1;

            IF (W_RTMPINTAPPL_NPA_ACCR_INT_AMT < 0)
            THEN
               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
            ELSE
               IF (W_RTMPINTAPPL_NPA_ACCR_INT_AMT > 0)
               THEN
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
               END IF;
            END IF;

            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_CURR_CODE := W_CURR_CODE;
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_ACING_BRN_CODE := W_BRN_CODE;
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_GLACC_CODE := W_INT_INCOME_GL;
            PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
               ABS (W_RTMPINTAPPL_NPA_ACCR_INT_AMT);
         END IF;
      --22-10-2009-end

      END AUTOPOST_ARRAY_ASSIGN;

      PROCEDURE GET_LOAN_ACNTNG_PARAM
      IS
      BEGIN
         IF (LPC_REC.EXISTS (W_PROD_CODE || W_CURR_CODE))
         THEN
            IF (TRIM (LPC_REC (W_PROD_CODE || W_CURR_CODE).V_INT_ACCR_GL)
                   IS NULL)
            THEN
               W_ERROR :=
                     'Interest Accrual GL Access Code Not Defined for Product Code = '
                  || W_PROD_CODE
                  || ' and Curr Code = '
                  || W_CURR_CODE;
               PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
               PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                            'X',
                                            PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                            ' ',
                                            0);
               RAISE E_SKP;
            ELSE
               W_INT_ACCR_GL :=
                  LPC_REC (W_PROD_CODE || W_CURR_CODE).V_INT_ACCR_GL;
            END IF;

            IF (TRIM (LPC_REC (W_PROD_CODE || W_CURR_CODE).V_INT_INCOME_GL)
                   IS NULL)
            THEN
               W_ERROR :=
                     'Interest Income GL Access Code Not Defined for Product Code = '
                  || W_PROD_CODE
                  || ' and Curr Code = '
                  || W_CURR_CODE;
               PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
               PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                            'X',
                                            PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                            ' ',
                                            0);
               RAISE E_SKP;
            ELSE
               W_INT_INCOME_GL :=
                  LPC_REC (W_PROD_CODE || W_CURR_CODE).V_INT_INCOME_GL;
            END IF;

            -- Added by Avinash-SONALI-21AUG2012 (begin)
            IF (TRIM (LPC_REC (W_PROD_CODE || W_CURR_CODE).V_INT_SUSP_GL)
                   IS NULL)
            THEN
               W_ERROR :=
                     'Interest Suspense GL Access Code Not Defined for Product Code = '
                  || W_PROD_CODE
                  || ' and Curr Code = '
                  || W_CURR_CODE;
               PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
               PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                            'X',
                                            PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                            ' ',
                                            0);
               RAISE E_SKP;
            ELSE
               W_INT_SUSP_GL :=
                  LPC_REC (W_PROD_CODE || W_CURR_CODE).V_INT_SUSP_GL;
            END IF;

            -- Added by Avinash-SONALI-21AUG2012 (end)

            --16-08-2010-beg
            IF (LNPRD_ACPM.EXISTS (W_PROD_CODE))
            THEN
               /*IF LNPRD_ACPM(W_PROD_CODE).V_LNPRD_INT_APPL_FREQ = 'I' AND LNPRD_ACPM(W_PROD_CODE)
               .V_LNPRD_UNREAL_INT_INCOME_REQD = '0' THEN*/
               -- NEELS-MDS-10-NOV-2010 Need to chek Need not check LNPRD_INT_APPL_FREQ = 'I'.
               -- only V_LNPRD_UNREAL_INT_INCOME_REQD is Required
               -- NEELS-MDS-30-NOV-2010 IF LNPRD_ACPM(W_PROD_CODE).V_LNPRD_UNREAL_INT_INCOME_REQD = '0' THEN
               IF LNPRD_ACPM (W_PROD_CODE).V_LNPRD_UNREAL_INT_INCOME_REQD =
                     '1'
               THEN
                  -- NEELS-MDS-30-NOV-2010
                  IF (TRIM (
                         LPC_REC (W_PROD_CODE || W_CURR_CODE).V_LNPRDAC_ACCRINT_SUSP_HEAD)
                         IS NULL)
                  THEN
                     W_ERROR :=
                           'Interest income ( I-based ) suspense head GL Access Code Not Defined for Product Code = '
                        || W_PROD_CODE
                        || ' and Curr Code = '
                        || W_CURR_CODE;
                     PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
                     PKG_PB_GLOBAL.DETAIL_ERRLOG (
                        PKG_ENTITY.FN_GET_ENTITY_CODE,
                        'X',
                        PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                        ' ',
                        0);
                     RAISE E_SKP;
                  ELSE
                     W_INT_ACCRU_SUSP_HEAD :=
                        LPC_REC (W_PROD_CODE || W_CURR_CODE).V_LNPRDAC_ACCRINT_SUSP_HEAD;
                  END IF;
               END IF;
            END IF;
         --16-08-2010-end
         ELSE
            W_ERROR :=
                  'Loan Accounting Parameters not defined for Product Code = '
               || W_PROD_CODE
               || ' and Curr Code = '
               || W_CURR_CODE;
            PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                         'X',
                                         PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                         ' ',
                                         0);
            RAISE E_SKP;
         END IF;
      END GET_LOAN_ACNTNG_PARAM;

      PROCEDURE APPEND_CONS_INTAMT_ARRAY
      IS
         TMP_FLG   NUMBER;
      BEGIN
         TMP_FLG := 0;

         IF (TMP_COUNT > 0)
         THEN
            FOR J IN IAMT_REC.FIRST .. IAMT_REC.LAST
            LOOP
               IF (    IAMT_REC (J).V_CURR = W_CURR_CODE
                   AND IAMT_REC (J).V_GLACC = W_INT_ACCR_GL)
               THEN
                  TMP_FLG := 1;
                  IAMT_REC (J).V_AMOUNT :=
                     IAMT_REC (J).V_AMOUNT + W_RTMPINTAPPL_ACT_INT_AMT;
               END IF;
            END LOOP;
         END IF;

         IF (TMP_FLG = 0)
         THEN
            TMP_COUNT := TMP_COUNT + 1;
            IAMT_REC (TMP_COUNT).V_GLACC := W_INT_ACCR_GL;
            IAMT_REC (TMP_COUNT).V_CURR := W_CURR_CODE;
            IAMT_REC (TMP_COUNT).V_AMOUNT := W_RTMPINTAPPL_ACT_INT_AMT;
         END IF;
      END APPEND_CONS_INTAMT_ARRAY;

      PROCEDURE APPEND_CONS_ADJAMT_ARRAY
      IS
         TMP_FLG   NUMBER;
      BEGIN
         TMP_FLG := 0;

         IF (TMP_COUNT1 > 0)
         THEN
            FOR J IN AAMT_REC.FIRST .. AAMT_REC.LAST
            LOOP
               IF (    AAMT_REC (J).V_CURR = W_CURR_CODE
                   AND AAMT_REC (J).V_INT_ACCR_GL = W_INT_ACCR_GL
                   AND AAMT_REC (J).V_INT_INCOME_GL = W_INT_INCOME_GL)
               THEN
                  TMP_FLG := 1;
                  AAMT_REC (J).V_AMOUNT :=
                     AAMT_REC (J).V_AMOUNT + W_RTMPINTAPPL_RND_DIFF;
               END IF;
            END LOOP;
         END IF;

         IF (TMP_FLG = 0)
         THEN
            TMP_COUNT1 := TMP_COUNT1 + 1;
            AAMT_REC (TMP_COUNT1).V_CURR := W_CURR_CODE;
            AAMT_REC (TMP_COUNT1).V_INT_ACCR_GL := W_INT_ACCR_GL;
            AAMT_REC (TMP_COUNT1).V_INT_INCOME_GL := W_INT_INCOME_GL;
            AAMT_REC (TMP_COUNT1).V_AMOUNT := W_RTMPINTAPPL_RND_DIFF;
         END IF;
      END APPEND_CONS_ADJAMT_ARRAY;

      PROCEDURE UPDATE_LNINTAPPL
      IS
         W_CBD_TIME   VARCHAR2 (20);
      BEGIN
        <<FETCH_LNINTAPPL>>
         BEGIN
            W_CBD_TIME :=
                  W_CBD
               || ' '
               || PKG_PB_GLOBAL.FN_GET_CURR_BUS_TIME (
                     PKG_ENTITY.FN_GET_ENTITY_CODE);

            SELECT LNINTAPPL_ACT_INT_AMT
              INTO DUMMY
              FROM LNINTAPPL
             WHERE     LNINTAPPL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND LNINTAPPL_BRN_CODE = W_BRN_CODE
                   AND LNINTAPPL_ACNT_NUM = W_INTERNAL_ACNUM
                   AND LNINTAPPL_APPL_DATE = W_CBD;

            UPDATE LNINTAPPL
               SET LNINTAPPL_ACT_INT_AMT =
                      LNINTAPPL_ACT_INT_AMT + W_RTMPINTAPPL_ACT_INT_AMT,
                   LNINTAPPL_ACCR_INT_AMT =
                      LNINTAPPL_ACCR_INT_AMT + W_RTMPINTAPPL_ACCR_INT_AMT,
                   LNINTAPPL_RNDOFF_DIFF =
                      LNINTAPPL_RNDOFF_DIFF + W_RTMPINTAPPL_RND_DIFF,
                   LNINTAPPL_INT_FROM_DATE = W_RTMPINTAPPL_FROM_DATE,
                   LNINTAPPL_INT_UPTO_DATE = W_RTMPINTAPPL_UPTO_DATE,
                   LNINTAPPL_PROC_BY = W_USER_ID,
                   LNINTAPPL_PROC_ON =
                      TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS')
             WHERE     LNINTAPPL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND LNINTAPPL_BRN_CODE = W_BRN_CODE
                   AND LNINTAPPL_ACNT_NUM = W_INTERNAL_ACNUM
                   AND LNINTAPPL_APPL_DATE = W_CBD;

           <<INSERTLNINTAPPLDTLS>>
            BEGIN
               INSERT INTO LNINTAPPLDTLS (LNINTAPPLD_ENTITY_NUM,
                                          LNINTAPPLD_BRN_CODE,
                                          LNINTAPPLD_ACNT_NUM,
                                          LNINTAPPLD_APPL_DATE,
                                          LNINTAPPLD_APPL_SL,
                                          LNINTAPPLD_ACT_INT_AMT,
                                          LNINTAPPLD_ACCR_INT_AMT,
                                          LNINTAPPLD_RNDOFF_DIFF,
                                          LNINTAPPLD_INT_FROM_DATE,
                                          LNINTAPPLD_INT_UPTO_DATE,
                                          POST_TRAN_BRN,
                                          POST_TRAN_DATE,
                                          POST_TRAN_BATCH_NUM,
                                          LNINTAPPLD_NPA_INT_AMT,
                                          LNINTAPPLD_NPA_INT_FROM_DATE,
                                          LNINTAPPLD_NPA_INT_UPTO_DATE,
                                          LNINTAPPLD_LNSUSPLED_SL_NUM,
                                          LNINTAPPLD_INT_DUE_DATE,
                                          LNINTAPPLD_PROC_BY,
                                          LNINTAPPLD_PROC_ON)
                    VALUES (
                              PKG_ENTITY.FN_GET_ENTITY_CODE,
                              W_BRN_CODE,
                              W_INTERNAL_ACNUM,
                              W_CBD,
                              (SELECT NVL (MAX (A.LNINTAPPLD_APPL_SL), 1) + 1
                                 FROM LNINTAPPLDTLS A
                                WHERE     LNINTAPPLD_ENTITY_NUM =
                                             PKG_ENTITY.FN_GET_ENTITY_CODE
                                      AND A.LNINTAPPLD_BRN_CODE = W_BRN_CODE
                                      AND A.LNINTAPPLD_ACNT_NUM =
                                             W_INTERNAL_ACNUM
                                      AND A.LNINTAPPLD_APPL_DATE = W_CBD),
                              W_RTMPINTAPPL_ACT_INT_AMT,
                              W_RTMPINTAPPL_ACCR_INT_AMT,
                              W_RTMPINTAPPL_RND_DIFF,
                              W_RTMPINTAPPL_FROM_DATE,
                              W_RTMPINTAPPL_UPTO_DATE,
                              0,
                              NULL,
                              0,
                              0,
                              NULL,
                              NULL,
                              0,
                              W_RTMPINTAPPL_INT_DUE_DATE,
                              W_USER_ID,
                              TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'));
            END INSERTLNINTAPPLDTLS;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
              <<ADD_LNINTAPPL>>
               BEGIN
                  INSERT INTO LNINTAPPL (LNINTAPPL_ENTITY_NUM,
                                         LNINTAPPL_BRN_CODE,
                                         LNINTAPPL_ACNT_NUM,
                                         LNINTAPPL_APPL_DATE,
                                         LNINTAPPL_ACT_INT_AMT,
                                         LNINTAPPL_ACCR_INT_AMT,
                                         LNINTAPPL_RNDOFF_DIFF,
                                         LNINTAPPL_INT_FROM_DATE,
                                         LNINTAPPL_INT_UPTO_DATE,
                                         POST_TRAN_BRN,
                                         POST_TRAN_DATE,
                                         POST_TRAN_BATCH_NUM,
                                         LNINTAPPL_NPA_INT_AMT,
                                         LNINTAPPL_NPA_INT_FROM_DATE,
                                         LNINTAPPL_NPA_INT_UPTO_DATE,
                                         LNINTAPPL_LNSUSPLED_SL_NUM,
                                         LNINTAPPL_INT_DUE_DATE,
                                         LNINTAPPL_PROC_BY,
                                         LNINTAPPL_PROC_ON)
                       VALUES (PKG_ENTITY.FN_GET_ENTITY_CODE,
                               W_BRN_CODE,
                               W_INTERNAL_ACNUM,
                               W_CBD,
                               W_RTMPINTAPPL_ACT_INT_AMT,
                               W_RTMPINTAPPL_ACCR_INT_AMT,
                               W_RTMPINTAPPL_RND_DIFF,
                               W_RTMPINTAPPL_FROM_DATE,
                               W_RTMPINTAPPL_UPTO_DATE,
                               0,
                               NULL,
                               0,
                               0,
                               NULL,
                               NULL,
                               0,
                               W_RTMPINTAPPL_INT_DUE_DATE,
                               W_USER_ID,
                               TO_DATE (W_CBD_TIME, 'DD-MON-YY HH24:MI:SS'));

                 <<INSERTLNINTAPPLDTLS>>
                  BEGIN
                     INSERT INTO LNINTAPPLDTLS (LNINTAPPLD_ENTITY_NUM,
                                                LNINTAPPLD_BRN_CODE,
                                                LNINTAPPLD_ACNT_NUM,
                                                LNINTAPPLD_APPL_DATE,
                                                LNINTAPPLD_APPL_SL,
                                                LNINTAPPLD_ACT_INT_AMT,
                                                LNINTAPPLD_ACCR_INT_AMT,
                                                LNINTAPPLD_RNDOFF_DIFF,
                                                LNINTAPPLD_INT_FROM_DATE,
                                                LNINTAPPLD_INT_UPTO_DATE,
                                                POST_TRAN_BRN,
                                                POST_TRAN_DATE,
                                                POST_TRAN_BATCH_NUM,
                                                LNINTAPPLD_NPA_INT_AMT,
                                                LNINTAPPLD_NPA_INT_FROM_DATE,
                                                LNINTAPPLD_NPA_INT_UPTO_DATE,
                                                LNINTAPPLD_LNSUSPLED_SL_NUM,
                                                LNINTAPPLD_INT_DUE_DATE,
                                                LNINTAPPLD_PROC_BY,
                                                LNINTAPPLD_PROC_ON)
                          VALUES (
                                    PKG_ENTITY.FN_GET_ENTITY_CODE,
                                    W_BRN_CODE,
                                    W_INTERNAL_ACNUM,
                                    W_CBD,
                                    1,
                                    W_RTMPINTAPPL_ACT_INT_AMT,
                                    W_RTMPINTAPPL_ACCR_INT_AMT,
                                    W_RTMPINTAPPL_RND_DIFF,
                                    W_RTMPINTAPPL_FROM_DATE,
                                    W_RTMPINTAPPL_UPTO_DATE,
                                    0,
                                    NULL,
                                    0,
                                    0,
                                    NULL,
                                    NULL,
                                    0,
                                    W_RTMPINTAPPL_INT_DUE_DATE,
                                    W_USER_ID,
                                    TO_DATE (W_CBD_TIME,
                                             'DD-MON-YY HH24:MI:SS'));
                  END INSERTLNINTAPPLDTLS;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     W_ERROR := 'Error in Creating LNINTAPPL';
                     RAISE E_USEREXCEP;
               END ADD_LNINTAPPL;
         END FETCH_LNINTAPPL;        -- R.Senthil Kumar - 07-June-2010 - Added

         IF (P_INTERNAL_ACNUM IS NULL OR P_INTERNAL_ACNUM = 0)
         THEN
            --CHG ARUNMUGESH J 27-12-2007 BEG
            UPDATE LOANACNTS
               SET LNACNT_INT_APPLIED_UPTO_DATE = W_CBD
             WHERE     LNACNT_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND LNACNT_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
         ELSE
            UPDATE LOANACNTS
               SET LNACNT_INT_APPLIED_UPTO_DATE = W_PREV_CBD
             WHERE     LNACNT_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND LNACNT_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
         END IF;                             --CHG ARUNMUGESH J 27-12-2007 END
      --END FETCH_LNINTAPPL; -- R.Senthil Kumar - 07-June-2010 - Removed
      END UPDATE_LNINTAPPL;

      PROCEDURE POST_PARA
      IS
      BEGIN
         SET_CREDIT_VOUCHER;
         ADJ_INT_RNDOFF;

         SET_TRAN_KEY_VALUES;
         SET_TRANBAT_VALUES;

         PKG_APOST_INTERFACE.SP_POST_SODEOD_BATCH (
            PKG_ENTITY.FN_GET_ENTITY_CODE,
            'A',
            IDX,
            IDX1,
            W_ERR_CODE,
            W_ERROR,
            W_BATCH_NUMBER);

         IF (W_ERR_CODE <> '0000')
         THEN
            W_ERROR := FN_GET_AUTOPOST_ERR_MSG (PKG_ENTITY.FN_GET_ENTITY_CODE);
            RAISE E_USEREXCEP;
         END IF;

         UPDATE LNINTAPPL
            SET POST_TRAN_BRN = W_PREV_BRN_CODE,
                POST_TRAN_DATE = W_CBD,
                POST_TRAN_BATCH_NUM = W_BATCH_NUMBER
          WHERE     LNINTAPPL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND POST_TRAN_DATE IS NULL
                AND LNINTAPPL_BRN_CODE = W_PREV_BRN_CODE
                AND LNINTAPPL_APPL_DATE = W_CBD
                AND LNINTAPPL_ACT_INT_AMT <> 0;

         IDX := 0;
         IDX1 := 0;
         W_PREV_BRN_CODE := 0;
         IAMT_REC.DELETE;
         AAMT_REC.DELETE;
         TMP_COUNT := 0;
         TMP_COUNT1 := 0;
         PKG_APOST_INTERFACE.SP_POSTING_END (PKG_ENTITY.FN_GET_ENTITY_CODE);
      END POST_PARA;

      PROCEDURE SET_CREDIT_VOUCHER
      IS
      BEGIN
         IF (TMP_COUNT > 0)
         THEN
            FOR J IN IAMT_REC.FIRST .. IAMT_REC.LAST
            LOOP
               IDX := IDX + 1;

               IF (IAMT_REC (J).V_AMOUNT < 0)
               THEN
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
               ELSE
                  IF (IAMT_REC (J).V_AMOUNT > 0)
                  THEN
                     PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
                  END IF;
               END IF;

               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_CURR_CODE :=
                  IAMT_REC (J).V_CURR;
               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_ACING_BRN_CODE :=
                  W_PREV_BRN_CODE;
               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_GLACC_CODE :=
                  IAMT_REC (J).V_GLACC;
               PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
                  ABS (IAMT_REC (J).V_AMOUNT);
            END LOOP;
         END IF;
      END SET_CREDIT_VOUCHER;

      PROCEDURE ADJ_INT_RNDOFF
      IS
      BEGIN
         IF (TMP_COUNT1 > 0)
         THEN
            FOR J IN AAMT_REC.FIRST .. AAMT_REC.LAST
            LOOP
               IF (AAMT_REC (J).V_AMOUNT > 0)
               THEN
                  IDX := IDX + 1;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_CURR_CODE :=
                     AAMT_REC (J).V_CURR;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_ACING_BRN_CODE :=
                     W_PREV_BRN_CODE;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_GLACC_CODE :=
                     AAMT_REC (J).V_INT_ACCR_GL;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
                     ABS (AAMT_REC (J).V_AMOUNT);

                  IDX := IDX + 1;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_CURR_CODE :=
                     AAMT_REC (J).V_CURR;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_ACING_BRN_CODE :=
                     W_PREV_BRN_CODE;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_GLACC_CODE :=
                     AAMT_REC (J).V_INT_INCOME_GL;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
                     ABS (AAMT_REC (J).V_AMOUNT);
               ELSIF (AAMT_REC (J).V_AMOUNT < 0)
               THEN
                  IDX := IDX + 1;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'C';
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_CURR_CODE :=
                     AAMT_REC (J).V_CURR;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_ACING_BRN_CODE :=
                     W_PREV_BRN_CODE;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_GLACC_CODE :=
                     AAMT_REC (J).V_INT_INCOME_GL;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
                     ABS (AAMT_REC (J).V_AMOUNT);

                  IDX := IDX + 1;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_DB_CR_FLG := 'D';
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_CURR_CODE :=
                     AAMT_REC (J).V_CURR;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_ACING_BRN_CODE :=
                     W_PREV_BRN_CODE;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_GLACC_CODE :=
                     AAMT_REC (J).V_INT_ACCR_GL;
                  PKG_AUTOPOST.PV_TRAN_REC (IDX).TRAN_AMOUNT :=
                     ABS (AAMT_REC (J).V_AMOUNT);
               END IF;
            END LOOP;
         END IF;
      END ADJ_INT_RNDOFF;

      PROCEDURE SET_TRAN_KEY_VALUES
      IS
      BEGIN
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := W_PREV_BRN_CODE;
         --02-12-2008-rem      PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := W_CBD;
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN :=
            PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (
               PKG_ENTITY.FN_GET_ENTITY_CODE);
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;
      END SET_TRAN_KEY_VALUES;

      PROCEDURE SET_TRANBAT_VALUES
      IS
      BEGIN
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'LNINTAPPL';
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY := W_PREV_BRN_CODE;
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 := 'Interest Applied ';
      END SET_TRANBAT_VALUES;

   BEGIN
      --ENTITY CODE COMMONLY ADDED - 06-11-2009  - BEG
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

     --ENTITY CODE COMMONLY ADDED - 06-11-2009  - END
     <<START_PROC>>
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

         IF (P_CURR_CODE IS NULL)
         THEN
            W_CURR_CODE := ' ';
         ELSE
            W_CURR_CODE := P_CURR_CODE;
         END IF;

         IF (P_INTERNAL_ACNUM IS NULL)
         THEN
            W_INTERNAL_ACNUM := 0;
         ELSE
            W_INTERNAL_ACNUM := P_INTERNAL_ACNUM;
         END IF;

         W_LOAN_INT_ON_RECOVERY := FALSE;
         W_INT_RECOV_AC_AMT := 0;
         W_INT_RECOV_BC_AMT := 0;

         W_NPA_INT_RECOV_AC_AMT := 0;
         W_NPA_INT_RECOV_BC_AMT := 0;

         W_INT_UPTO_DATE := NULL;

         IF P_INT_ON_RECOVERY_LOANS = 1
         THEN
            W_LOAN_INT_ON_RECOVERY := TRUE;
         END IF;

         IF    NVL (P_INT_RECOV_AC_AMT, 0) <> 0
            OR NVL (P_NPA_INT_RECOV_AC_AMT, 0) <> 0
         THEN
            W_INT_RECOV_AC_AMT := P_INT_RECOV_AC_AMT;
            W_INT_RECOV_BC_AMT := P_INT_RECOV_BC_AMT;
            W_NPA_INT_RECOV_AC_AMT := P_NPA_INT_RECOV_AC_AMT;
            W_NPA_INT_RECOV_BC_AMT := P_NPA_INT_RECOV_BC_AMT;
            W_INT_UPTO_DATE := P_INT_UPTO_DATE;
         END IF;

         W_CBD := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

         W_PREV_CBD := PKG_EODSOD_FLAGS.PV_PREVIOUS_DATE; --ARUNMUGESH J 27-12-2007 ADD

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

         --ARUNMUGESH J 27-12-2007 BEG
         IF (W_INTERNAL_ACNUM <> 0 AND W_PREV_CBD IS NULL)
         THEN
            W_ERROR := 'Previous Business Date Should be Specified';
            RAISE E_USEREXCEP;
         END IF;

         --ARUNMUGESH J 27-12-2007 END

         PKG_APOST_INTERFACE.SP_POSTING_BEGIN (PKG_ENTITY.FN_GET_ENTITY_CODE);

         IF (GET_MQHY_MON (PKG_ENTITY.FN_GET_ENTITY_CODE, W_CBD, 'Y') = 1)
         THEN
            W_EOD_MQHY_FLG := 'Y';
         ELSE
            IF (GET_MQHY_MON (PKG_ENTITY.FN_GET_ENTITY_CODE, W_CBD, 'H') = 1)
            THEN
               W_EOD_MQHY_FLG := 'H';
            ELSE
               IF (GET_MQHY_MON (PKG_ENTITY.FN_GET_ENTITY_CODE, W_CBD, 'Q') =
                      1)
               THEN
                  W_EOD_MQHY_FLG := 'Q';
               ELSE
                  IF (GET_MQHY_MON (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                    W_CBD,
                                    'M') = 1)
                  THEN
                     W_EOD_MQHY_FLG := 'M';
                  ELSE
                     W_EOD_MQHY_FLG := 'D';
                  END IF;
               END IF;
            END IF;
         END IF;

         -- AGK -26-DEC-2007 (ACNUM CONDITION ADDED)
         IF W_INTERNAL_ACNUM > 0 OR (W_EOD_MQHY_FLG <> 'D')
         THEN
            READ_LNPRODACPM;
            READ_ACNT;
         END IF;

         --AGK-CHN-20-AUG-2009-BEG
         IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NOT NULL
         THEN
            ROLLBACK;
         END IF;
      --AGK-CHN-20-AUG-2009-END
      EXCEPTION
         WHEN OTHERS
         THEN
            IF TRIM (W_ERROR) IS NULL
            THEN
               W_ERROR := 'Error in SP_INTAPPLY ';
            END IF;

            PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                         'E',
                                         PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                         ' ',
                                         0);
            PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                         'E',
                                         SUBSTR (SQLERRM, 1, 1000),
                                         ' ',
                                         0);
            --AGK-CHN-20-AUG-2009-ADD
            ROLLBACK;
      END START_PROC;
   END SP_INTAPPLY;


   PROCEDURE START_BRNWISE (V_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0)
   IS
      L_BRN_CODE      NUMBER (6);
      V_PROCESS_ALL   CHAR (1) := 'N';
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

      W_ENTITY_CODE := V_ENTITY_NUM;
      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (W_ENTITY_CODE, P_BRN_CODE);
      V_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      W_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

         IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (W_ENTITY_CODE,
                                                         L_BRN_CODE) = FALSE
         THEN
            SP_INTAPPLY (W_ENTITY_CODE, L_BRN_CODE);

            PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (W_ENTITY_CODE);
         END IF;


         IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
         THEN
            PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (W_ENTITY_CODE,
                                                             L_BRN_CODE);
         END IF;
      END LOOP;

      PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (W_ENTITY_CODE);
   END START_BRNWISE;
END PKG_LNINTAPPLY;
/

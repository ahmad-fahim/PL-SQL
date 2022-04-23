CREATE OR REPLACE PACKAGE PKG_LOAN_INT_CALC_PROCESS IS
   V_OVERDUR_LOAN_ACC   BOOLEAN := FALSE;

   PROCEDURE PROC_INT_CALC (V_ENTITY_NUM       IN NUMBER,
                            V_BRN_CODE         IN NUMBER DEFAULT 0,
                            V_ACCOUNT_NUMBER   IN NUMBER DEFAULT 0);

   --29-07-2008-added
   PROCEDURE PROC_BRN_WISE (V_ENTITY_NUM   IN NUMBER,
                            V_BRN_CODE     IN NUMBER DEFAULT 0);

   PROCEDURE LAP (V_ENTITY_NUM       IN     NUMBER,
                  V_BRN_CODE         IN     NUMBER DEFAULT 0,
                  V_PROCESS_STATUS      OUT NUMBER);
END PKG_LOAN_INT_CALC_PROCESS;
/
CREATE OR REPLACE PACKAGE BODY PKG_LOAN_INT_CALC_PROCESS IS
   V_GLOB_ENTITY_NUM             NUMBER (6);
   V_CTR                         NUMBER (10) := 0;
   V_MIG_END_DATE                DATE;


   --- Added by rajib.pradhan to reduce latch contention

    TYPE TT_RTMPLNND_INTERNAL_ACNUM IS TABLE OF RTMPLNNOTDUE.RTMPLNND_INTERNAL_ACNUM%TYPE INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNND_GRACE_END_DATE IS TABLE OF RTMPLNNOTDUE.RTMPLNND_GRACE_END_DATE%TYPE INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNND_NOT_DUE_AMT IS TABLE OF RTMPLNNOTDUE.RTMPLNND_NOT_DUE_AMT%TYPE INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNND_ENTRY_TYPE IS TABLE OF RTMPLNNOTDUE.RTMPLNND_ENTRY_TYPE%TYPE INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNND_ACTUAL_DUE_DATE IS TABLE OF RTMPLNNOTDUE.RTMPLNND_ACTUAL_DUE_DATE%TYPE INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNND_FINAL_DUE_AMT IS TABLE OF RTMPLNNOTDUE.RTMPLNND_FINAL_DUE_AMT%TYPE INDEX BY PLS_INTEGER;

   TYPE T_APP_FREQ_STR IS TABLE OF VARCHAR2 (1)
      INDEX BY VARCHAR2 (1);

   V_APP_FREQ_STR                T_APP_FREQ_STR;

   T_RTMPLNND_INTERNAL_ACNUM     TT_RTMPLNND_INTERNAL_ACNUM;
   T_RTMPLNND_GRACE_END_DATE     TT_RTMPLNND_GRACE_END_DATE;
   T_RTMPLNND_NOT_DUE_AMT        TT_RTMPLNND_NOT_DUE_AMT;
   T_RTMPLNND_ENTRY_TYPE         TT_RTMPLNND_ENTRY_TYPE;
   T_RTMPLNND_ACTUAL_DUE_DATE    TT_RTMPLNND_ACTUAL_DUE_DATE;
   T_RTMPLNND_FINAL_DUE_AMT      TT_RTMPLNND_FINAL_DUE_AMT;

   W_INDEX_NUMBER                NUMBER DEFAULT 0;

   W_RTMPLNNOTDUE_DATA_EXIST     BOOLEAN DEFAULT FALSE;


   PROCEDURE GET_PENDING_AMOUNT;

   /*
    Modification History
     -----------------------------------------------------------------------------------------
    Sl.            Description                              Mod By             Mod on
    -----------------------------------------------------------------------------------------
     1   Changes for Nepal Social Development Bank
     Need to chek LNPRD_UNREAL_INT_INCOME_REQD INSTEAD OF
          LNPRD_INT_APPL_FREQ = 'I'                        K Neelakantan        08-NOV-2010   -- NEELS-MDS-08-NOV-2010
   2   Changes for Nepal Social Development Bank
         Unrealized Int Accounted in Income is changed to
         Unrealized Int Accounted in Suspense
         Label Changes done in ILNPRODPM
         Default 0 Changed from Default 1 K Neelakantan        30-NOV-2010   -- NEELS-MDS-30-NOV-2010
     3  Changes for Sonali Bank
        For NPA Loss Assets of category 3 Interest Calculation is stopped      16-AUG-2012   -- Avinash K 16-AUG-2012
        Since Account Balance consists of Suspense Amount after
        changes in loan interest accrual and application process
        while calculating compounding interest suspense balance
        should not be added to account balance.            Avinash K            22-AUG-2012  -- Avinash-SONALI-22AUG2012
   -----------------------------------------------------------------------------------------
    */

   W_PROC_BRN_CODE               NUMBER (6);
   W_OD_PENDING_PRODUCT          NUMBER (18, 3);
   W_ARR_OD_INT_AMT              NUMBER (18, 3);
   W_IS_MIG_MONTH                VARCHAR2 (10) := '';
   W_LAT_EFF_DATE                DATE;
   W_LOANIAMRR_MAX_VALUE_DATE    DATE;
   W_LN_TRAN_FROM_DATE           DATE;

   PROCEDURE INSERT_RTMPLNNOTDUE (ACNUM             IN NUMBER,
                                  GRACE_DUE_DATE    IN DATE,
                                  AMOUNT            IN NUMBER,
                                  ACTUAL_DUE_DATE      DATE,
                                  ENTRY_TYPE           VARCHAR2);

   W_MIN_PROC_DATE               DATE;
   W_ACTUAL_OVERDUE_AMT          NUMBER (18, 3);
   W_PROCESS_ACT_AMT             NUMBER (18, 3);
   W_PROC_YEAR                   NUMBER;
   W_UPTO_YEAR                   NUMBER;

  TYPE TY_TRAN_REC IS RECORD(
      V_INTRD_BC_AMT    NUMBER (18, 3),
      V_CHARGE_BC_AMT   NUMBER (18, 3),
      V_DB_CR_FLG       VARCHAR2 (1),
    V_DATE_OF_TRAN  DATE);

  TYPE TAB_TRAN_REC IS TABLE OF TY_TRAN_REC INDEX BY PLS_INTEGER;

   TRAN_REC                      TAB_TRAN_REC;

  TYPE REC_TRAN_FILTER_DATE IS RECORD(
      TRAN_INTERNAL_ACNUM   NUMBER (14),
    TRAN_FILTER_DATE    DATE);

  TYPE TT_TRAN_FILTER_DATE IS TABLE OF REC_TRAN_FILTER_DATE INDEX BY PLS_INTEGER;

   T_TRAN_FILTER_DATE            TT_TRAN_FILTER_DATE;

   EX_DML_ERRORS                 EXCEPTION;
   PRAGMA EXCEPTION_INIT (EX_DML_ERRORS, -24381);
   W_BULK_COUNT                  NUMBER (10);

   W_GRACE_DAYS                  NUMBER (3);

   W_PRIN_OD_AMT                 NUMBER (18, 3);

   W_NPA_OD_INT_REQD             NUMBER (1);

   W_INT_ON_RECOVERY             BOOLEAN;

   W_IGNORE                      CHAR (1);
   W_COUNT                       NUMBER;

   W_PENDING_AMOUNT              NUMBER (18, 3) := 0;

   PROCEDURE DESTROY_BRN_WISE_ARRAYS;

   W_LAP_RUN_NUMBER              NUMBER (6);
   W_OD_FOUND                    CHAR (1);
   W_SIMPLE_COMP_INT             CHAR (1);
   W_LIMIT_EXPIRY_DATE           DATE;
   W_LIMIT_SANC_AMT              NUMBER (18, 3);
   W_REPAY_START_DATE            DATE;
   W_FINAL_DUE_DATE              DATE;
   W_DAY_END_STR                 VARCHAR2 (100);
   W_MONTH_END_STR               VARCHAR (200);
   W_QUARTER_END_STR             VARCHAR (300);
   W_HALF_YEAR_END_STR           VARCHAR (400);
   W_YEAR_END_STR                VARCHAR (500);
   W_FINAL_WHERE_STR             VARCHAR2 (800);
   W_DMQHY                       CHAR (1);

   TYPE RC IS REF CURSOR;

   E_USEREXCEP                   EXCEPTION;
   W_SUSPENSE_BAL                NUMBER (18, 3);
   W_RUN_NUMBER                  NUMBER (6);
   W_FACTOR                      NUMBER (3);
   W_SINGLE_INT_RATE             NUMBER (8, 5);
   W_ASSETCD_ASSET_CLASS         CHAR (1);
   W_ASSETCLS_ASSET_CODE         VARCHAR2 (2);
   W_ASSETCLS_NPA_DATE           DATE;
   W_MULTI_INT_RATE              VARCHAR2 (500);
   W_AMOUNT_STR                  VARCHAR2 (500);
   W_INTERNAL_ACNUM              NUMBER (14);
   W_ACNTS_CURR_CODE             VARCHAR2 (3);
   W_ACNTS_PROD_CODE             NUMBER (4);
   W_INT_ACCR_UPTO_DATE          DATE;
   W_MIN_VAUE_DATE               DATE;
   W_SCAN_FROM_DATE              DATE;
   W_ASON_DATE                   DATE;
   W_ACCRUAL_UPTO_DATE           DATE;
   W_SQL                         VARCHAR2 (4300);
   W_VALUE_BALANCE               NUMBER (18, 3);
   W_VALUE_INT_BALANCE           NUMBER (18, 3);
   W_VALUE_CHG_BALANCE           NUMBER (18, 3);
   W_PREV_YR_VALUE_DATE          BOOLEAN;
   W_FIN_START_MONTH             NUMBER (2);
   W_PROCESS_DATE                DATE;
   W_INT_DEB_UPTO_DATE           DATE;
   W_OPENING_BALANCE             NUMBER (18, 3);
   W_TRAN_BALANCE_SUM            NUMBER (18, 3);
   W_TRAN_INT_BAL_SUM            NUMBER (18, 3);
   W_TRAN_CHG_BAL_SUM            NUMBER (18, 3);
   W_TRAN_BAL                    NUMBER (18, 3);
   W_TRAN_INT_BAL                NUMBER (18, 3);
   W_TRAN_CHG_BAL                NUMBER (18, 3);
   W_REDUCE_AMOUNT               NUMBER (18, 3);
   V_BREAK_SL                    NUMBER (5);
   W_INT_ON_AMT                  NUMBER (18, 3);
   W_SANC_LIMIT                  NUMBER (18, 3);
   W_DP_AMT                      NUMBER (18, 3);
   W_OD_AMT                      NUMBER (18, 3);
   W_MAIN_INDEX                  NUMBER (8);
   W_OD_DATE                     DATE;
   W_ERR_MSG                     VARCHAR2 (1300);
   W_PENAL_FOR_OVERDUE           NUMBER (8, 5);
   W_ACT_AC_INT_AMT              NUMBER (18, 9);
   W_ACT_BC_INT_AMT              NUMBER (18, 9);
   W_NPA_STATUS                  NUMBER (1);
   W_NPA_AMT                     NUMBER (18, 3);
   W_OD_AC_INT_AMT               NUMBER (18, 9);
   W_OD_BC_INT_AMT               NUMBER (18, 9);
   W_PRODCODE_CURRCODE           VARCHAR (13);
   W_SCHEME_CODE                 VARCHAR2 (6);
   W_CBD                         DATE;
   W_LAP_PROCESS                 BOOLEAN DEFAULT FALSE;
   W_PENAL_INT_APPLICABLE        CHAR (1) := '0';
   W_SIMP                        CHAR (2);
   W_SHORT_TERM_LOAN             CHAR (1);
   W_DISB_AMT                    NUMBER (18, 3);
   W_CAL_INT_AMT                 NUMBER (18, 9);
   W_MIG_INT_AMT                 NUMBER (18, 9);
   W_APP_INT_AMT                 NUMBER (18, 9);
   W_LNIA_MRR_INT_AMT            NUMBER (18, 9);
   W_INT_APP_UPTO_DATE           DATE;
   W_ACNTS_OPENING_DATE          DATE;

   V_COUNT_LOANIAPS              NUMBER;
   W_LOANIAPS_COUNT              NUMBER;

   FUNCTION GET_QHY_MON (P_PROC_MON        IN NUMBER,
                         P_FIN_START_MON   IN NUMBER,
                       P_QHY_TYPE      IN CHAR) RETURN NUMBER;

   PROCEDURE UPDATE_RTMPLNIADTL (W_INTEREST_RATE   IN NUMBER,
                                 W_AMOUNT          IN NUMBER,
                                 W_INT_AMOUNT      IN NUMBER);

   PROCEDURE UPDATE_RTMPLNIA (P_ACTION_FLAG BOOLEAN);

  TYPE T_INTERNAL_ACNUM IS TABLE OF NUMBER(14) INDEX BY PLS_INTEGER;

   V_INTERNAL_ACNUM              T_INTERNAL_ACNUM;

  TYPE R_ACCOUNT_LIST IS RECORD(
      ACNTS_INTERNAL_ACNUM   NUMBER (14),
    LNPRD_INT_ACCR_REQD  CHAR(1));

  TYPE T_ACCOUNT_LIST IS TABLE OF R_ACCOUNT_LIST INDEX BY BINARY_INTEGER;

   V_DUMMY_INTERNAL_ACNUM        T_ACCOUNT_LIST;

   -- Note: Changes made to Contain Asset Related Information
   TYPE REC_ACNTS IS RECORD(
      ACNTS_INTERNAL_ACNUM           NUMBER (14),
      ACNTS_PROD_CODE                NUMBER (4),
      ACNTS_CURR_CODE                VARCHAR2 (3),
      ACNTS_INT_ACCR_UPTO            DATE,
      ACNTS_OPENING_DATE             DATE,
      ACNTS_CLIENTS_CODE             NUMBER,
      ACNTS_SCHEME_CODE              VARCHAR2 (6),
      ACNTS_INT_CALC_UPTO            DATE,
      LNACNT_INT_ACCR_UPTO           LOANACNTS.LNACNT_INT_ACCR_UPTO%TYPE,
      LNACNT_ENTD_ON                 LOANACNTS.LNACNT_ENTD_ON%TYPE,
      LNPRD_PENAL_INT_APPLICABLE     LNPRODPM.LNPRD_PENAL_INT_APPLICABLE%TYPE,
      TRAN_VAL_DATE                  DATE,
      -- Note: Following 6 field newly added here
      LOANIAMRR_MAX_VALUE_DATE       DATE,
      LNACRS_REPHASEMENT_ENTRY       LNACRS.LNACRS_REPHASEMENT_ENTRY%TYPE,
      ASSETCD_ASSET_CLASS            ASSETCD.ASSETCD_ASSET_CLASS%TYPE,
      ASSETCLS_ASSET_CODE            ASSETCLS.ASSETCLS_ASSET_CODE%TYPE,
      ASSETCLS_NPA_DATE              ASSETCLS.ASSETCLS_NPA_DATE%TYPE,
      ASSETCD_OD_INT_REQD            ASSETCD.ASSETCD_OD_INT_REQD%TYPE,
      LN_FINAL_DUE_DATE              PROCACNUM.LN_FINAL_DUE_DATE%TYPE,
      LN_OVERDUE_FROM_DATE           PROCACNUM.LN_OVERDUE_FROM_DATE%TYPE,
      LN_TRAN_FROM_DATE              PROCACNUM.LN_TRAN_FROM_DATE%TYPE,
      --Short term loan identifier
      LNPRD_SHORT_TERM_LOAN          LNPRODPM.LNPRD_SHORT_TERM_LOAN%TYPE,
      LNACNT_INT_APPLIED_UPTO_DATE   LOANACNTS.LNACNT_INT_APPLIED_UPTO_DATE%TYPE,
      APP_INT_AMT                    PROCACNUM.APP_INT_AMT%TYPE,
      LNACDISB_DISB_AMT              PROCACNUM.APP_INT_AMT%TYPE,
      MIG_INT_AMT                    PROCACNUM.APP_INT_AMT%TYPE,
      LNIA_MRR_INT_AMT               PROCACNUM.APP_INT_AMT%TYPE,
      LNACDTL_GRACE_END_DATE         LNACDTLS.LNACDTL_GRACE_END_DATE%TYPE,
      LNACNT_RTMP_ACCURED_UPTO       LOANACNTS.LNACNT_RTMP_ACCURED_UPTO%TYPE,
      LNACNT_RTMP_PROCESS_DATE       LOANACNTS.LNACNT_RTMP_PROCESS_DATE%TYPE,
      LNPRD_INT_APPL_FREQ            LNPRODPM.LNPRD_INT_APPL_FREQ%TYPE,
      COUNT_LOANIAPS                 NUMBER,
      MIRROR_APPLICABLE              NUMBER
   );


  TYPE TT_ACNTS IS TABLE OF REC_ACNTS INDEX BY PLS_INTEGER;

   T_ACNTS                       TT_ACNTS;

    TYPE TT_RTMPLNIA_RUN_NUMBER       IS TABLE OF NUMBER(6)        INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_ACNT_NUM         IS TABLE OF NUMBER(14)       INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_VALUE_DATE       IS TABLE OF DATE             INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_ACCRUAL_DATE     IS TABLE OF DATE             INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_ACNT_CURR        IS TABLE OF VARCHAR2(3)      INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_ACNT_BAL         IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_INT_ON_AMT       IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_OD_PORTION       IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_INT_RATE         IS TABLE OF NUMBER(8,5)      INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_SLAB_AMT         IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_OD_INT_RATE      IS TABLE OF NUMBER(8,5)      INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_LIMIT            IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_DP               IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_INT_AMT          IS TABLE OF NUMBER(18,9)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_INT_AMT_RND      IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_OD_INT_AMT       IS TABLE OF NUMBER(18,9)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_OD_INT_AMT_RND   IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_NPA_STATUS       IS TABLE OF NUMBER(1)        INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_NPA_AMT          IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_ARR_OD_INT_AMT   IS TABLE OF NUMBER(18,3)     INDEX BY PLS_INTEGER;

    TYPE TT_RTMPLNIA_MAX_ACCRUAL_DATE IS TABLE OF DATE             INDEX BY PLS_INTEGER;

   TYPE TT_RTMPLNIA_LNIA_INSERT_FROM IS TABLE OF VARCHAR2 (1)
      INDEX BY PLS_INTEGER;

   TYPE TT_RTMPLNIA_BRN_CODE IS TABLE OF NUMBER (5)
      INDEX BY PLS_INTEGER;

   T_RTMPLNIA_RUN_NUMBER         TT_RTMPLNIA_RUN_NUMBER;
   T_RTMPLNIA_ACNT_NUM           TT_RTMPLNIA_ACNT_NUM;
   T_RTMPLNIA_VALUE_DATE         TT_RTMPLNIA_VALUE_DATE;
   T_RTMPLNIA_ACCRUAL_DATE       TT_RTMPLNIA_ACCRUAL_DATE;
   T_RTMPLNIA_ACNT_CURR          TT_RTMPLNIA_ACNT_CURR;
   T_RTMPLNIA_ACNT_BAL           TT_RTMPLNIA_ACNT_BAL;
   T_RTMPLNIA_INT_ON_AMT         TT_RTMPLNIA_INT_ON_AMT;
   T_RTMPLNIA_OD_PORTION         TT_RTMPLNIA_OD_PORTION;
   T_RTMPLNIA_INT_RATE           TT_RTMPLNIA_INT_RATE;
   T_RTMPLNIA_SLAB_AMT           TT_RTMPLNIA_SLAB_AMT;
   T_RTMPLNIA_OD_INT_RATE        TT_RTMPLNIA_OD_INT_RATE;
   T_RTMPLNIA_LIMIT              TT_RTMPLNIA_LIMIT;
   T_RTMPLNIA_DP                 TT_RTMPLNIA_DP;
   T_RTMPLNIA_INT_AMT            TT_RTMPLNIA_INT_AMT;
   T_RTMPLNIA_INT_AMT_RND        TT_RTMPLNIA_INT_AMT_RND;
   T_RTMPLNIA_OD_INT_AMT         TT_RTMPLNIA_OD_INT_AMT;
   T_RTMPLNIA_OD_INT_AMT_RND     TT_RTMPLNIA_OD_INT_AMT_RND;
   T_RTMPLNIA_NPA_STATUS         TT_RTMPLNIA_NPA_STATUS;
   T_RTMPLNIA_NPA_AMT            TT_RTMPLNIA_NPA_AMT;
   T_RTMPLNIA_ARR_OD_INT_AMT     TT_RTMPLNIA_ARR_OD_INT_AMT;
   T_RTMPLNIA_MAX_ACCRUAL_DATE   TT_RTMPLNIA_MAX_ACCRUAL_DATE;

   T_RTMPLNIA_LNIA_INSERT_FROM   TT_RTMPLNIA_LNIA_INSERT_FROM;
   T_RTMPLNIA_BRN_CODE           TT_RTMPLNIA_BRN_CODE;

   V_RTMPLNIA_INDX               NUMBER := 0;

   WW_FINYEAR_OB                 NUMBER (4);
   WW_MONTH_OB                   NUMBER (2);
   WW_MONTH_PREV_OB              NUMBER (2);
   W_OPENING_BAL_OB              NUMBER (18, 3);

   WW_FINYEAR_OI                 NUMBER (4);
   WW_MONTH_OI                   NUMBER (2);
   WW_MONTH_PREV_OI              NUMBER (2);
   W_OPENING_INT_BAL_IO          NUMBER (18, 3);
   W_OPENING_CHG_BAL_IO          NUMBER (18, 3);

  TYPE REC_MIN_TRNDATE IS RECORD(
      TRAN_INTERNAL_ACNUM   NUMBER (14),
    TRAN_VAL_DATE       DATE);

  TYPE TT_MIN_TRNDATE IS TABLE OF REC_MIN_TRNDATE INDEX BY PLS_INTEGER;

   T_MIN_TRNDATE                 TT_MIN_TRNDATE;

  TYPE REC_TRAN_BALANCE IS RECORD(
      VALUE_YEAR            NUMBER (6),
      TRAN_INTERNAL_ACNUM   NUMBER (14),
      TRAN_VALUE_DATE       DATE,
      TRANBALANCE           NUMBER (18, 3),
      TRANINTBALANCE        NUMBER (18, 3),
    TRANCHGBALANCE      NUMBER(18, 3));

  TYPE TT_TRAN_BALANCE IS TABLE OF REC_TRAN_BALANCE INDEX BY PLS_INTEGER;

   T_TRAN_BALANCE                TT_TRAN_BALANCE;

  TYPE REC_INT_FROMDAT IS RECORD(
      TRAN_INTERNAL_ACNUM   NUMBER (14),
    INT_FROM_DATE       DATE);

  TYPE TT_INT_FROMDAT IS TABLE OF REC_INT_FROMDAT INDEX BY PLS_INTEGER;

   T_INT_FROMDAT                 TT_INT_FROMDAT;

  TYPE REC_TRAN_OVERDUE IS RECORD(
      VALUE_YEAR              NUMBER (6),
      TRAN_INTERNAL_ACNUM     NUMBER (14),
      TRANADV_INTRD_BC_AMT    NUMBER (18, 3),
      TRANADV_CHARGE_BC_AMT   NUMBER (18, 3),
      TRAN_DB_CR_FLG          VARCHAR2 (10),
    TRAN_DATE_OF_TRAN     DATE);

  TYPE TT_TRAN_OVERDUE IS TABLE OF REC_TRAN_OVERDUE INDEX BY PLS_INTEGER;

   T_TRAN_OVERDUE                TT_TRAN_OVERDUE;

  TYPE LN_ACNTROW IS RECORD(
      ACNTS_PROD_CODE       NUMBER (4),
      ACNTS_CURR_CODE       VARCHAR2 (3),
      ACNTS_INT_ACCR_UPTO   DATE,
      ACNTS_OPENING_DATE    DATE,
      ACNTS_CLIENTS_CODE    NUMBER,
      ACNTS_SCHEME_CODE     VARCHAR2 (6),
    ACNTS_INT_CALC_UPTO DATE);

  TYPE T_LN_ACNTROW IS TABLE OF LN_ACNTROW INDEX BY PLS_INTEGER;

   V_LN_ACNTROW                  T_LN_ACNTROW;

  TYPE LN_LNPRODPM IS RECORD(
      LNPRD_SIMPLE_COMP_INT          CHAR (1),
      LNPRD_INT_PROD_BASIS           CHAR (1),
      LNPRD_INT_RECOVERY_OPTION      CHAR (1),
      LNPRD_INT_APPL_FREQ            CHAR (1),
      LNPRD_INT_ACCR_FREQ            CHAR (1),
      PRODUCT_EXEMPT_FROM_NPA        CHAR (1),
      LNPRD_SCHEME_REQD              CHAR (1),
      LNPRD_TERM_LOAN                CHAR (1),
      PRODUCT_FOR_RUN_ACS            CHAR (1),
      LNPRD_EDUCATIONAL_LOAN         CHAR (1),
      LNPRD_INT_RECOV_GRACE_DAYS     NUMBER (2),
      LNPRD_PENAL_INT_APPLICABLE     CHAR (1),
      LNPRD_PENALTY_GRACE_DAYS       NUMBER (2),
      LNPRD_PENAL_INT_APPL_FROM      CHAR (1),
      LNPRD_UNREAL_INT_INCOME_REQD   CHAR (1),
      INT_CAL_BYNDDUE_DATE           CHAR (1),
      LNPRD_GRACE_PRD_CHK_REQ        CHAR (1),
    LNPRD_GRACE_PRD_ACCR_ALLOW   CHAR(1));

  TYPE T_LN_LNPRODPM IS TABLE OF LN_LNPRODPM INDEX BY VARCHAR2(4);

   V_LN_LNPRODPM                 T_LN_LNPRODPM;

  TYPE LN_LNCURRPM IS RECORD(
      LNCUR_INT_CALCN_BASIS        NUMBER (3),
      LNCUR_INT_RNDOFF_PARAM       CHAR (1),
      LNCUR_INT_RNDOFF_PRECISION   NUMBER (7, 3),
    LNCUR_MIN_INT_AMT          NUMBER(18, 3));

  TYPE T_LN_LNCURRPM IS TABLE OF LN_LNCURRPM INDEX BY VARCHAR2(13);

   V_LN_LNCURRPM                 T_LN_LNCURRPM;
   W_SKIP_FLAG                   BOOLEAN;

  TYPE LN_LNACRSDTL IS RECORD(
      V_REPAY_FROM_DATE      DATE,
      V_NUM_OF_INSTALLMENT   NUMBER (5),
      V_REPAY_AMT            NUMBER (18, 3),
    V_REPAY_FREQ         CHAR(1));

  TYPE IN_LN_LNACRSDTL IS TABLE OF LN_LNACRSDTL INDEX BY PLS_INTEGER;

   V_LN_LNACRSDTL                IN_LN_LNACRSDTL;

   PROCEDURE SET_MIN_TRAN_DATA (P_TRAN_YEAR NUMBER);

   PROCEDURE SET_TRAN_BALANCE (P_TRAN_YEAR NUMBER);

   PROCEDURE SET_OVERDUE_BALANCE;

  PROCEDURE DESTROY_ARRAYS IS
   BEGIN
      V_LN_LNPRODPM.DELETE;
      V_LN_LNCURRPM.DELETE;
      V_LN_ACNTROW.DELETE;
      T_ACNTS.DELETE;
      DESTROY_BRN_WISE_ARRAYS;
   END DESTROY_ARRAYS;

   PROCEDURE CHECK_HOLIDAY_PERIOD;

   PROCEDURE CHECK_EXPIRY;

   PROCEDURE GET_LIMIT_EXPIRY;

   PROCEDURE FETCH_REPAY_END_DATE;

   PROCEDURE RECORD_EXCEPTION (W_EXCEPTION_DESC IN VARCHAR2)
   IS
   BEGIN
      PKG_PB_GLOBAL.DETAIL_ERRLOG (V_GLOB_ENTITY_NUM,
         'X',
                                W_EXCEPTION_DESC || ' ' ||
                                ' Process Date =' || W_PROCESS_DATE,
         ' ',
         W_INTERNAL_ACNUM);
   END RECORD_EXCEPTION;

  FUNCTION SP_FORM_END_DATE(W_DATE IN DATE, P_QHY_TYPE IN CHAR) RETURN DATE IS
      W_PROC_MON               NUMBER (2);
      W_DUMMY_NUM              NUMBER (1);
      W_FINANCIAL_START_DATE   DATE;
      W_FINALCIAL_YEAR         NUMBER (4);
      W_SP_FORM_START_DATE     DATE;
   BEGIN
      W_DUMMY_NUM := 0;
      W_FINALCIAL_YEAR := 0;

      IF W_FIN_START_MONTH > EXTRACT (MONTH FROM W_DATE)
      THEN
         W_FINALCIAL_YEAR := EXTRACT (YEAR FROM W_DATE) - 1;
      ELSE
         W_FINALCIAL_YEAR := EXTRACT (YEAR FROM W_DATE);
      END IF;

      W_FINANCIAL_START_DATE :=
         TO_DATE (
            '01-' || TO_CHAR (W_FIN_START_MONTH) || '-' || W_FINALCIAL_YEAR,
            'DD-MM-YYYY');
      W_PROC_MON := EXTRACT (MONTH FROM W_DATE);

      IF P_QHY_TYPE <> 'Y'
      THEN
         W_DUMMY_NUM :=
            GET_QHY_MON (W_PROC_MON, W_FIN_START_MONTH, P_QHY_TYPE);
      END IF;

      IF P_QHY_TYPE = 'Q' THEN
      W_SP_FORM_START_DATE := ADD_MONTHS(W_FINANCIAL_START_DATE,
                                         (W_DUMMY_NUM - 1) * 3);
    ELSIF P_QHY_TYPE = 'H' THEN
      W_SP_FORM_START_DATE := ADD_MONTHS(W_FINANCIAL_START_DATE,
                                         (W_DUMMY_NUM - 1) * 6);
    ELSIF P_QHY_TYPE = 'Y' THEN
         W_SP_FORM_START_DATE := W_FINANCIAL_START_DATE;
      END IF;

      RETURN W_SP_FORM_START_DATE;
   END SP_FORM_END_DATE;

   -- THIS IS FOR FINDING OUT THE QUARTER
   FUNCTION GET_QHY_MON (P_PROC_MON        IN NUMBER,
                         P_FIN_START_MON   IN NUMBER,
                       P_QHY_TYPE      IN CHAR) RETURN NUMBER IS
      V_QHY_MON   NUMBER (2);
   BEGIN
    IF P_PROC_MON < P_FIN_START_MON THEN
         V_QHY_MON := 12 + P_PROC_MON - P_FIN_START_MON + 1;
      ELSE
         V_QHY_MON := P_PROC_MON - P_FIN_START_MON + 1;
      END IF;

    IF P_QHY_TYPE = 'Q' THEN
         V_QHY_MON := V_QHY_MON MOD 3;

      IF V_QHY_MON = 0 THEN
            V_QHY_MON := 3;
         END IF;
    ELSIF P_QHY_TYPE = 'H' THEN
         V_QHY_MON := V_QHY_MON MOD 6;

      IF V_QHY_MON = 0 THEN
            V_QHY_MON := 6;
         END IF;
      END IF;

      RETURN V_QHY_MON;
   EXCEPTION
    WHEN OTHERS THEN
         RETURN 0;
   END GET_QHY_MON;

   PROCEDURE GET_CURR_SPECIFIC_PARAM
   IS
      TYPE D_LN_LNCURRPM IS RECORD
      (
         LNCUR_PROD_SCHEME_CURR       VARCHAR (13),
         LNCUR_INT_CALCN_BASIS        CHAR (1),
         LNCUR_INT_RNDOFF_PARAM       CHAR (1),
         LNCUR_INT_RNDOFF_PRECISION   NUMBER (9, 3),
         LNCUR_MIN_INT_AMT            NUMBER (18, 3));

    TYPE D_T_LN_LNCURRPM IS TABLE OF D_LN_LNCURRPM INDEX BY PLS_INTEGER;

      D_V_LN_LNCURRPM           D_T_LN_LNCURRPM;
      V_PROD_SEGMENT_CURR_KEY   VARCHAR2 (13);
   BEGIN
    SELECT LPAD(LNCUR_PROD_CODE, 4, 0) ||
           DECODE(LNCUR_SCHEME_CODE,
                  ' ',
                  '000000',
                  LPAD(TRIM(LNCUR_SCHEME_CODE), 6, '0')) || LNCUR_CURR_CODE,
             LNCUR_INT_CALCN_BASIS,
             LNCUR_INT_RNDOFF_PARAM,
             LNCUR_INT_RNDOFF_PRECISION,
           LNCUR_MIN_INT_AMT BULK COLLECT
      INTO D_V_LN_LNCURRPM
        FROM LNCURPM;

    IF D_V_LN_LNCURRPM.COUNT > 0 THEN
      FOR IDX IN 1 .. D_V_LN_LNCURRPM.COUNT LOOP
        IF D_V_LN_LNCURRPM(IDX).LNCUR_INT_CALCN_BASIS = '1' THEN
          V_LN_LNCURRPM(D_V_LN_LNCURRPM(IDX).LNCUR_PROD_SCHEME_CURR).LNCUR_INT_CALCN_BASIS := 365;
        ELSIF D_V_LN_LNCURRPM(IDX).LNCUR_INT_CALCN_BASIS = '2' THEN
          V_LN_LNCURRPM(D_V_LN_LNCURRPM(IDX).LNCUR_PROD_SCHEME_CURR).LNCUR_INT_CALCN_BASIS := 360;
        ELSIF D_V_LN_LNCURRPM(IDX).LNCUR_INT_CALCN_BASIS = '3' THEN
          V_LN_LNCURRPM(D_V_LN_LNCURRPM(IDX).LNCUR_PROD_SCHEME_CURR).LNCUR_INT_CALCN_BASIS := 366;
            ELSE
          V_LN_LNCURRPM(D_V_LN_LNCURRPM(IDX).LNCUR_PROD_SCHEME_CURR).LNCUR_INT_CALCN_BASIS := 365;
            END IF;

        V_LN_LNCURRPM(D_V_LN_LNCURRPM(IDX).LNCUR_PROD_SCHEME_CURR).LNCUR_INT_RNDOFF_PARAM := D_V_LN_LNCURRPM(IDX)
                                                                                             .LNCUR_INT_RNDOFF_PARAM;
        V_LN_LNCURRPM(D_V_LN_LNCURRPM(IDX).LNCUR_PROD_SCHEME_CURR).LNCUR_INT_RNDOFF_PRECISION := D_V_LN_LNCURRPM(IDX)
                                                                                                 .LNCUR_INT_RNDOFF_PRECISION;
        V_LN_LNCURRPM(D_V_LN_LNCURRPM(IDX).LNCUR_PROD_SCHEME_CURR).LNCUR_MIN_INT_AMT := D_V_LN_LNCURRPM(IDX)
                                                                                        .LNCUR_MIN_INT_AMT;
         END LOOP;
      END IF;

      D_V_LN_LNCURRPM.DELETE;
   END GET_CURR_SPECIFIC_PARAM;

  PROCEDURE GET_LNPRODPM_PARAM IS
    TYPE T_LN_LNPRODPM IS RECORD(
         LNPRD_PROD_CODE                NUMBER (4),
         LNPRD_SIMPLE_COMP_INT          CHAR (1),
         LNPRD_INT_PROD_BASIS           CHAR (1),
         LNPRD_INT_RECOVERY_OPTION      CHAR (1),
         LNPRD_INT_APPL_FREQ            CHAR (1),
         LNPRD_INT_ACCR_FREQ            CHAR (1),
         PRODUCT_EXEMPT_FROM_NPA        CHAR (1),
         LNPRD_SCHEME_REQD              CHAR (1),
         LNPRD_TERM_LOAN                CHAR (1),
         PRODUCT_FOR_RUN_ACS            CHAR (1),
         LNPRD_EDUCATIONAL_LOAN         CHAR (1),
         LNPRD_INT_RECOV_GRACE_DAYS     NUMBER (2),
         LNPRD_PENAL_INT_APPLICABLE     CHAR (1),
         LNPRD_PENALTY_GRACE_DAYS       NUMBER (2),
         LNPRD_PENAL_INT_APPL_FROM      CHAR (1),
         LNPRD_UNREAL_INT_INCOME_REQD   CHAR (1),
         INT_CAL_BYNDDUE_DATE           CHAR (1),
         LNPRD_GRACE_PRD_CHK_REQ        CHAR (1),
      LNPRD_GRACE_PRD_ACCR_ALLOW   CHAR(1));

    TYPE T_LNPRODPM IS TABLE OF T_LN_LNPRODPM INDEX BY PLS_INTEGER;

      TT_LN_LNPRODPM   T_LNPRODPM;
   BEGIN
      SELECT LNPRD_PROD_CODE,
             LNPRD_SIMPLE_COMP_INT,
             LNPRD_INT_PROD_BASIS,
             LNPRD_INT_RECOVERY_OPTION,
             LNPRD_INT_APPL_FREQ,
             LNPRD_INT_ACCR_FREQ,
             PRODUCT_EXEMPT_FROM_NPA,
             LNPRD_SCHEME_REQD,
             LNPRD_TERM_LOAN,
             PRODUCT_FOR_RUN_ACS,
             LNPRD_EDUCATIONAL_LOAN,
             LNPRD_INT_RECOV_GRACE_DAYS,
             LNPRD_PENAL_INT_APPLICABLE,
             LNPRD_PENALTY_GRACE_DAYS,
           LNPRD_PENAL_INT_APPL_FROM --09-08-2010-added
          ,
           LNPRD_UNREAL_INT_INCOME_REQD -- NEELS-MDS-08-NOV-2010 ADD
          ,
             INT_CAL_BYNDDUE_DATE,
             LNPRD_GRACE_PRD_CHK_REQ,
             LNPRD_GRACE_PRD_ACCR_ALLOW
           BULK COLLECT
      INTO TT_LN_LNPRODPM
        FROM LNPRODPM L, PRODUCTS P
       WHERE P.PRODUCT_CODE = L.LNPRD_PROD_CODE;

      IF TT_LN_LNPRODPM.COUNT > 0 THEN
      FOR IDX IN 1 .. TT_LN_LNPRODPM.COUNT LOOP
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_SIMPLE_COMP_INT := TT_LN_LNPRODPM(IDX)
                                                                                    .LNPRD_SIMPLE_COMP_INT;
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_INT_PROD_BASIS := TT_LN_LNPRODPM(IDX)
                                                                                   .LNPRD_INT_PROD_BASIS;
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_INT_RECOVERY_OPTION := TT_LN_LNPRODPM(IDX)
                                                                                        .LNPRD_INT_RECOVERY_OPTION;
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_INT_APPL_FREQ := TT_LN_LNPRODPM(IDX)
                                                                                  .LNPRD_INT_APPL_FREQ;
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_INT_ACCR_FREQ := TT_LN_LNPRODPM(IDX)
                                                                                  .LNPRD_INT_ACCR_FREQ;
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).PRODUCT_EXEMPT_FROM_NPA := TT_LN_LNPRODPM(IDX)
                                                                                      .PRODUCT_EXEMPT_FROM_NPA;

        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_SCHEME_REQD := TT_LN_LNPRODPM(IDX)
                                                                                .LNPRD_SCHEME_REQD;

        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_TERM_LOAN := TT_LN_LNPRODPM(IDX)
                                                                              .LNPRD_TERM_LOAN;
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).PRODUCT_FOR_RUN_ACS := TT_LN_LNPRODPM(IDX)
                                                                                  .PRODUCT_FOR_RUN_ACS;
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_EDUCATIONAL_LOAN := TT_LN_LNPRODPM(IDX)
                                                                                     .LNPRD_EDUCATIONAL_LOAN;

        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_INT_RECOV_GRACE_DAYS := TT_LN_LNPRODPM(IDX)
                                                                                         .LNPRD_INT_RECOV_GRACE_DAYS;

        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_PENAL_INT_APPLICABLE := TT_LN_LNPRODPM(IDX)
                                                                                         .LNPRD_PENAL_INT_APPLICABLE;
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_PENALTY_GRACE_DAYS := TT_LN_LNPRODPM(IDX)
                                                                                       .LNPRD_PENALTY_GRACE_DAYS;

        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_PENAL_INT_APPL_FROM := NVL(TT_LN_LNPRODPM(IDX)
                                                                                            .LNPRD_PENAL_INT_APPL_FROM,
                                                                                            0);
        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_UNREAL_INT_INCOME_REQD := NVL(TT_LN_LNPRODPM(IDX)
                                                                                               .LNPRD_UNREAL_INT_INCOME_REQD,
                                                                                               '0'); -- NEELS-MDS-08-NOV-2010 ADD

        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).INT_CAL_BYNDDUE_DATE := TT_LN_LNPRODPM(IDX)
                                                                                   .INT_CAL_BYNDDUE_DATE;

        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_GRACE_PRD_CHK_REQ := TT_LN_LNPRODPM(IDX)
                                                                                      .LNPRD_GRACE_PRD_CHK_REQ;

        V_LN_LNPRODPM(TT_LN_LNPRODPM(IDX).LNPRD_PROD_CODE).LNPRD_GRACE_PRD_ACCR_ALLOW := TT_LN_LNPRODPM(IDX)
                                                                                      .LNPRD_GRACE_PRD_ACCR_ALLOW;
         END LOOP;
      END IF;

      TT_LN_LNPRODPM.DELETE;
   END GET_LNPRODPM_PARAM;

  FUNCTION GET_MIN_VALUE_DATE_FROM_TRAN(P_SCAN_FROM_DATE IN DATE) RETURN DATE IS
      W_DUMMY_DATE   DATE;
   BEGIN
    W_SQL := 'SELECT MIN(TRAN_VALUE_DATE) FROM  TRAN' ||
             SP_GETFINYEAR(V_GLOB_ENTITY_NUM, P_SCAN_FROM_DATE) ||
             ' WHERE TRAN_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND  TRAN_DATE_OF_TRAN >= :1
                             AND TRAN_INTERNAL_ACNUM       = :2 AND TRAN_AUTH_ON IS NOT NULL';

      EXECUTE IMMEDIATE W_SQL
         INTO W_DUMMY_DATE
         USING W_SCAN_FROM_DATE, W_INTERNAL_ACNUM;

      RETURN W_DUMMY_DATE;
   END GET_MIN_VALUE_DATE_FROM_TRAN;

  FUNCTION GET_LOANACNTS_ACCR_DATE(W_ACNUM IN NUMBER) RETURN DATE IS
      W_DUMMY_DATE   DATE;
   BEGIN
     <<READLOANACNT>>
      BEGIN
         SELECT L.LNACNT_INT_ACCR_UPTO
           INTO W_DUMMY_DATE
           FROM LOANACNTS L
          WHERE     LNACNT_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND L.LNACNT_INTERNAL_ACNUM = W_ACNUM;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_DUMMY_DATE := NULL;
      END READLOANACNT;

      RETURN W_DUMMY_DATE;
   END GET_LOANACNTS_ACCR_DATE;

  FUNCTION GET_MIN_VALUE_DATE(W_ACNUM IN NUMBER) RETURN DATE IS
      W_DUMMY_MIN_VAUE_DATE   DATE;
   BEGIN
      W_SCAN_FROM_DATE := NULL;

    IF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
     .LNPRD_INT_ACCR_FREQ = 'D' THEN
         W_SCAN_FROM_DATE := W_ASON_DATE;
      /*     comments by rajib.pradhan as on 02-aug-2015 for optimization

          ELSIF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
           .LNPRD_INT_ACCR_FREQ = 'M' THEN
            W_SCAN_FROM_DATE :=PKG_PB_GLOBAL.SP_FORM_START_DATE(V_GLOB_ENTITY_NUM,
                                                                 W_ASON_DATE,
                                                                 'M');
          ELSIF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
           .LNPRD_INT_ACCR_FREQ = 'Q' THEN
            W_SCAN_FROM_DATE := PKG_PB_GLOBAL.SP_FORM_START_DATE(V_GLOB_ENTITY_NUM,
                                                                 W_ASON_DATE,
                                                                 'Q');
          ELSIF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
           .LNPRD_INT_ACCR_FREQ = 'H' THEN
            W_SCAN_FROM_DATE := PKG_PB_GLOBAL.SP_FORM_START_DATE(V_GLOB_ENTITY_NUM,
                                                                 W_ASON_DATE,
                                                                 'H');
          ELSIF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
           .LNPRD_INT_ACCR_FREQ = 'Y' THEN
            W_SCAN_FROM_DATE := PKG_PB_GLOBAL.SP_FORM_START_DATE(V_GLOB_ENTITY_NUM,
                                                                 W_ASON_DATE,
                                                                 'Y');
        */
      ELSE
         W_SCAN_FROM_DATE :=
            PKG_PB_GLOBAL_EOD_SOD.FN_FORM_START_DATE (
               P_ENTITY_NUM             => V_GLOB_ENTITY_NUM,
               P_DATE                   => W_ASON_DATE,
               P_FIN_YEAR_START_MONTH   => W_FIN_START_MONTH,
               P_MQHY_TYPE              => V_LN_LNPRODPM (
                                             T_ACNTS (V_CTR).ACNTS_PROD_CODE).LNPRD_INT_ACCR_FREQ);
      END IF;

      W_DUMMY_MIN_VAUE_DATE := GET_MIN_VALUE_DATE_FROM_TRAN (W_SCAN_FROM_DATE);
      RETURN W_DUMMY_MIN_VAUE_DATE;
   END GET_MIN_VALUE_DATE;

  PROCEDURE READ_ACNTS_ROW IS
    TYPE D_LN_ACNTROW IS RECORD(
         ACNTS_INTERNAL_ACNUM   NUMBER (14),
         ACNTS_PROD_CODE        NUMBER (4),
         ACNTS_CURR_CODE        VARCHAR2 (3),
         ACNTS_INT_ACCR_UPTO    DATE,
         ACNTS_OPENING_DATE     DATE,
         ACNTS_CLIENTS_CODE     NUMBER,
         ACNTS_SCHEME_CODE      VARCHAR2 (6),
      ACNTS_INT_CALC_UPTO  DATE);

    TYPE D_T_LN_ACNTROW IS TABLE OF D_LN_ACNTROW INDEX BY PLS_INTEGER;

      D_V_LN_ACNTROW   D_T_LN_ACNTROW;
   BEGIN
      W_NPA_OD_INT_REQD := '0';

      SELECT A.ACNTS_INTERNAL_ACNUM,
             A.ACNTS_PROD_CODE,
             A.ACNTS_CURR_CODE,
             A.ACNTS_INT_ACCR_UPTO,
             A.ACNTS_OPENING_DATE,
             A.ACNTS_CLIENT_NUM,
             A.ACNTS_SCHEME_CODE,
           A.ACNTS_INT_CALC_UPTO BULK COLLECT
      INTO D_V_LN_ACNTROW
        FROM ACNTS A
       WHERE     ACNTS_ENTITY_NUM = V_GLOB_ENTITY_NUM
             AND A.ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACNUM;

      -- R.Senthil Kumar - 11-June-2010 - Removed - Begin
      /*    -- CHN Guna 04/06/2010 start Add LNACINTCTL
      AND A.ACNTS_INTERNAL_ACNUM NOT IN (
        SELECT LNACINTCTL_INTERNAL_ACNUM
          FROM LNACINTCTL
         WHERE LNACINTCTL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
           AND LNACINTCTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
           AND LNACINTCTL_INT_ACCRUAL_REQD <> '1');
      -- CHN Guna 04/06/2010 end*/
      -- R.Senthil Kumar - 11-June-2010 - Removed - End

    IF D_V_LN_ACNTROW.COUNT > 0 THEN
      FOR IDX IN 1 .. D_V_LN_ACNTROW.COUNT LOOP
        V_LN_ACNTROW(IDX).ACNTS_PROD_CODE := D_V_LN_ACNTROW(IDX)
                                             .ACNTS_PROD_CODE;
        V_LN_ACNTROW(IDX).ACNTS_CURR_CODE := D_V_LN_ACNTROW(IDX)
                                             .ACNTS_CURR_CODE;
        V_LN_ACNTROW(IDX).ACNTS_INT_ACCR_UPTO := D_V_LN_ACNTROW(IDX)
                                                 .ACNTS_INT_ACCR_UPTO;
        V_LN_ACNTROW(IDX).ACNTS_OPENING_DATE := D_V_LN_ACNTROW(IDX)
                                                .ACNTS_OPENING_DATE;
        V_LN_ACNTROW(IDX).ACNTS_CLIENTS_CODE := D_V_LN_ACNTROW(IDX)
                                                .ACNTS_CLIENTS_CODE;
        V_LN_ACNTROW(IDX).ACNTS_SCHEME_CODE := D_V_LN_ACNTROW(IDX)
                                               .ACNTS_SCHEME_CODE;
        V_LN_ACNTROW(IDX).ACNTS_INT_CALC_UPTO := D_V_LN_ACNTROW(IDX)
                                                 .ACNTS_INT_CALC_UPTO;
         END LOOP;
      END IF;

      D_V_LN_ACNTROW.DELETE;
   END READ_ACNTS_ROW;

  PROCEDURE CHECK_PREV_YR_VALUE_DATE IS
      RC_ACNTBBAL                     RC;
      V_ACNTBBAL_AC_OPNG_CLG_CR_SUM   NUMBER (18, 3);
      V_ACNTBBAL_AC_OPNG_CLG_DB_SUM   NUMBER (18, 3);
   BEGIN
      SELECT ACNTBBAL_AC_OPNG_CLG_CR_SUM, ACNTBBAL_AC_OPNG_CLG_DB_SUM
        INTO V_ACNTBBAL_AC_OPNG_CLG_CR_SUM, V_ACNTBBAL_AC_OPNG_CLG_DB_SUM
        FROM ACNTBBAL
       WHERE     ACNTBBAL_ENTITY_NUM = V_GLOB_ENTITY_NUM
             AND ACNTBBAL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
             AND ACNTBBAL_CURR_CODE = W_ACNTS_CURR_CODE
       AND ACNTBBAL_YEAR = PKG_PB_GLOBAL_EOD_SOD.FN_GETFINYEAR(V_GLOB_ENTITY_NUM, W_PROCESS_DATE)
             AND ACNTBBAL_MONTH = 1;

      OPEN RC_ACNTBBAL FOR W_SQL;

      FETCH RC_ACNTBBAL
         INTO V_ACNTBBAL_AC_OPNG_CLG_CR_SUM, V_ACNTBBAL_AC_OPNG_CLG_DB_SUM;

    IF RC_ACNTBBAL%FOUND THEN
      IF V_ACNTBBAL_AC_OPNG_CLG_CR_SUM > 0 OR
         V_ACNTBBAL_AC_OPNG_CLG_DB_SUM > 0 THEN
            W_PREV_YR_VALUE_DATE := TRUE;
         END IF;
      END IF;
   END CHECK_PREV_YR_VALUE_DATE;

  FUNCTION GET_MONTH_OPENING_BALANCE(P_PROCESS_DATE IN DATE) RETURN NUMBER IS

   BEGIN
      WW_MONTH_OB := TO_CHAR (P_PROCESS_DATE, 'MM');

    IF WW_MONTH_OB=WW_MONTH_PREV_OB THEN
         RETURN NVL (W_OPENING_BAL_OB, 0);
      END IF;


      WW_FINYEAR_OB := 0;
      WW_MONTH_OB := 0;
    WW_FINYEAR_OB := PKG_PB_GLOBAL_EOD_SOD.FN_GETFINYEAR(V_GLOB_ENTITY_NUM, P_PROCESS_DATE);
      WW_MONTH_OB := TO_CHAR (P_PROCESS_DATE, 'MM');
      WW_MONTH_PREV_OB := TO_CHAR (P_PROCESS_DATE, 'MM');

      W_OPENING_BAL_OB := 0;
      W_PREV_YR_VALUE_DATE := FALSE;

     <<READACNTVDBBAL>>
      BEGIN
         /*30-06-2009               SELECT NVL(AVD.ACNTVBBAL_AC_OPNG_CR_SUM,
                                   0) - NVL(AVD.ACNTVBBAL_AC_OPNG_DB_SUM,
                                            0)
                        INTO   W_OPENING_BAL
                        FROM   ACNTVDBBAL AVD
                        WHERE  AVD.ACNTVBBAL_INTERNAL_ACNUM = W_INTERNAL_ACNUM AND
                               AVD.ACNTVBBAL_CURR_CODE = V_LN_ACNTROW(W_MAIN_INDEX)
                         .ACNTS_CURR_CODE AND
                               AVD.ACNTVBBAL_YEAR = SP_GETFINYEAR(P_PROCESS_DATE) AND
                               AVD.ACNTVBBAL_MONTH =
                               (EXTRACT(MONTH FROM P_PROCESS_DATE));
         */

      SELECT NVL(AVD.ACNTVBBAL_AC_OPNG_CR_SUM, 0) -
             NVL(AVD.ACNTVBBAL_AC_OPNG_DB_SUM, 0)
           INTO W_OPENING_BAL_OB
           FROM ACNTVDBBAL AVD
          WHERE     ACNTVBBAL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND AVD.ACNTVBBAL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND AVD.ACNTVBBAL_CURR_CODE = T_ACNTS (V_CTR).ACNTS_CURR_CODE
                AND AVD.ACNTVBBAL_YEAR = WW_FINYEAR_OB
                AND AVD.ACNTVBBAL_MONTH = WW_MONTH_OB;
      -- FIN YEAR AND MONTH CONDITION ADDED
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_OPENING_BAL_OB := 0;
      END READACNTVDBBAL;

      RETURN NVL (W_OPENING_BAL_OB, 0);
   END GET_MONTH_OPENING_BALANCE;

   FUNCTION GET_MONTH_INT_OPENING_BALANCE (P_PROCESS_DATE IN DATE)
    RETURN NUMBER IS
   BEGIN
      WW_MONTH_OI := TO_CHAR (P_PROCESS_DATE, 'MM');

    IF WW_MONTH_OI=WW_MONTH_PREV_OI THEN
         RETURN NVL (W_OPENING_INT_BAL_IO, 0);
      END IF;

      W_OPENING_INT_BAL_IO := 0;

      WW_FINYEAR_OI := 0;
      WW_MONTH_OI := 0;
    WW_FINYEAR_OI := PKG_PB_GLOBAL_EOD_SOD.FN_GETFINYEAR(V_GLOB_ENTITY_NUM, P_PROCESS_DATE);
      WW_MONTH_OI := TO_CHAR (P_PROCESS_DATE, 'MM');
      WW_MONTH_PREV_OI := TO_CHAR (P_PROCESS_DATE, 'MM');

     <<READADVBBAL>>
      BEGIN
         --             SELECT NVL(ABS(NVL(ADVVDBBAL_INTRD_AC_OPBAL,
         /*30-06-2009               SELECT NVL((NVL(ADVVDBBAL_INTRD_AC_OPBAL,
                                           0)),
                                   0)
                        INTO   W_OPENING_INT_BAL
                        FROM   ADVVDBBAL AVD
                        WHERE  AVD.ADVVDBBAL_INTERNAL_ACNUM = W_INTERNAL_ACNUM AND
                               AVD.ADVVDBBAL_CURR_CODE = V_LN_ACNTROW(W_MAIN_INDEX)
                         .ACNTS_CURR_CODE AND
                               AVD.ADVVDBBAL_YEAR = SP_GETFINYEAR(P_PROCESS_DATE) AND
                               AVD.ADVVDBBAL_MONTH =
                               (EXTRACT(MONTH FROM P_PROCESS_DATE));
         */

         SELECT NVL ( (NVL (ADVVDBBAL_INTRD_AC_OPBAL, 0)), 0)
           INTO W_OPENING_INT_BAL_IO
           FROM ADVVDBBAL AVD
          WHERE     ADVVDBBAL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND AVD.ADVVDBBAL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND AVD.ADVVDBBAL_CURR_CODE = T_ACNTS (V_CTR).ACNTS_CURR_CODE
                AND AVD.ADVVDBBAL_YEAR = WW_FINYEAR_OI
                AND AVD.ADVVDBBAL_MONTH = WW_MONTH_OI;
      -- FIN YEAR AND MONTH CONDITION ADDED
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_OPENING_INT_BAL_IO := 0;
      END READADVBBAL;

      RETURN NVL (W_OPENING_INT_BAL_IO, 0);
   END GET_MONTH_INT_OPENING_BALANCE;


   FUNCTION GET_MONTH_CHG_OPENING_BALANCE (P_PROCESS_DATE IN DATE)
    RETURN NUMBER IS
   BEGIN
      WW_MONTH_OI := TO_CHAR (P_PROCESS_DATE, 'MM');

    IF WW_MONTH_OI=WW_MONTH_PREV_OI THEN
         RETURN NVL (W_OPENING_CHG_BAL_IO, 0);
      END IF;

      W_OPENING_CHG_BAL_IO := 0;

      WW_FINYEAR_OI := 0;
      WW_MONTH_OI := 0;
    WW_FINYEAR_OI := PKG_PB_GLOBAL_EOD_SOD.FN_GETFINYEAR(V_GLOB_ENTITY_NUM, P_PROCESS_DATE);
      WW_MONTH_OI := TO_CHAR (P_PROCESS_DATE, 'MM');
      WW_MONTH_PREV_OI := TO_CHAR (P_PROCESS_DATE, 'MM');

     <<READADVBBAL>>
      BEGIN
         SELECT NVL ( (NVL (ADVVDBBAL_CHARGE_AC_OPBAL, 0)), 0)
           INTO W_OPENING_CHG_BAL_IO
           FROM ADVVDBBAL AVD
          WHERE     ADVVDBBAL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND AVD.ADVVDBBAL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND AVD.ADVVDBBAL_CURR_CODE = T_ACNTS (V_CTR).ACNTS_CURR_CODE
                AND AVD.ADVVDBBAL_YEAR = WW_FINYEAR_OI
                AND AVD.ADVVDBBAL_MONTH = WW_MONTH_OI;
      -- FIN YEAR AND MONTH CONDITION ADDED
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_OPENING_CHG_BAL_IO := 0;
      END READADVBBAL;

      RETURN NVL (W_OPENING_CHG_BAL_IO, 0);
   END GET_MONTH_CHG_OPENING_BALANCE;

  PROCEDURE GET_TRAN_BALANCE(W_YEAR IN NUMBER) IS
      W_FROM_DATE   DATE;
   BEGIN
      W_TRAN_BAL := 0;
      W_TRAN_INT_BAL := 0;
      W_TRAN_CHG_BAL := 0;
      -- W_FROM_DATE    := W_PROCESS_DATE -TO_NUMBER(TO_CHAR(W_PROCESS_DATE, 'DD')) + 1;
      W_FROM_DATE := TRUNC (W_PROCESS_DATE, 'MM');
      --    W_SQL          := 'select NVL(SUM(DECODE(TRAN_DB_CR_FLG,' || CHR(39) || 'C' ||
      --                      CHR(39) ||
      --                      ',TRAN_AMOUNT,0))- SUM(DECODE(TRAN_DB_CR_FLG,' ||
      --                      CHR(39) || 'D' || CHR(39) ||
      --                      ',TRAN_AMOUNT,0)),0)
      --                 tranbalance, NVL(SUM(DECODE(TRAN_DB_CR_FLG,' ||
      --                      CHR(39) || 'C' || CHR(39) ||
      --                      ',TRANADV_INTRD_AC_AMT,0))- SUM(DECODE(TRAN_DB_CR_FLG,' ||
      --                      CHR(39) || 'D' || CHR(39) ||
      --                      ',TRANADV_INTRD_AC_AMT,0)),0)
      --                 tranintbalance from TRANADV' ||
      --                      W_YEAR || ', TRAN' || W_YEAR ||
      --                      ' where Tran_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND TRANADV_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE aND  TRAN_VAlue_date >= :3 and Tran_value_date <= :4 and TRAN_INTERNAL_ACNUM = :5
      --                      and TRAN_DATE_OF_TRAN <= :6 and TRAN_AUTH_ON is not null AND
      --                       TRANADV_BRN_CODE     =  TRAN_BRN_CODE AND TRAN_DATE_OF_TRAN  = TRANADV_DATE_OF_TRAN AND
      --                       TRANADV_BATCH_NUMBER  = TRAN_BATCH_NUMBER AND TRANADV_BATCH_SL_NUM = TRAN_BATCH_SL_NUM';

    W_SQL := 'SELECT NVL(SUM(TRANBALANCE),0), NVL(SUM(TRANINTBALANCE),0),NVL(SUM(TRANCHGBALANCE),0) FROM TEMP_LOAN_TRAN_BAL WHERE  TRAN_VALUE_DATE >= :1 AND TRAN_VALUE_DATE<= :2 AND TRAN_INTERNAL_ACNUM=:3';

      EXECUTE IMMEDIATE W_SQL
         INTO W_TRAN_BAL, W_TRAN_INT_BAL, W_TRAN_CHG_BAL
         USING W_FROM_DATE, W_PROCESS_DATE, W_INTERNAL_ACNUM;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERR_MSG := 'Balance not found in tran';
         RAISE E_USEREXCEP;
   END GET_TRAN_BALANCE;

  PROCEDURE GET_INT_REDUCE_AMT_SIMPLE IS
   BEGIN
      --27-02-2008-REM          W_REDUCE_AMOUNT := ABS(W_TRAN_INT_BAL_SUM);
      W_REDUCE_AMOUNT := ABS (W_VALUE_INT_BALANCE) + ABS (W_VALUE_CHG_BALANCE);
   END GET_INT_REDUCE_AMT_SIMPLE;

  PROCEDURE GET_INT_REDUCE_AMT_COMP IS
   BEGIN
      W_REDUCE_AMOUNT := 0;
      -- NEELS-MDS-08-NOV-2010 BEG ;
      GET_PENDING_AMOUNT;
      -- W_Value Balance is Always in Negative (Loan Balance) and W Pending Amount is NEGATIVE
      W_VALUE_BALANCE := W_VALUE_BALANCE + W_PENDING_AMOUNT;
   -- NEELS-MDS-08-NOV-2010 END;

   END GET_INT_REDUCE_AMT_COMP;

  PROCEDURE GET_VALUE_DATE_BALANCE(P_PROCESS_DATE IN DATE) IS
      W_OPENING_BALANCE       NUMBER (18, 3);
      W_OPENING_INT_BALANCE   NUMBER (18, 3);
      W_OPENING_CHG_BALANCE   NUMBER (18, 3);
      W_YEAR                  NUMBER (4);
   BEGIN
      W_OPENING_BALANCE := 0;
      W_TRAN_BALANCE_SUM := 0;
      W_TRAN_INT_BAL_SUM := 0;
      W_TRAN_CHG_BAL_SUM := 0;
      W_VALUE_BALANCE := 0;
      W_VALUE_INT_BALANCE := 0;
      W_VALUE_CHG_BALANCE := 0;
      W_ACT_AC_INT_AMT := 0;
      W_ACT_BC_INT_AMT := 0;
      -- AGK-26-FEB-2008-REM          W_YEAR              := SP_GETFINYEAR(P_PROCESS_DATE);
    W_YEAR                := PKG_PB_GLOBAL_EOD_SOD.FN_GETFINYEAR(V_GLOB_ENTITY_NUM, W_ASON_DATE);
      W_OPENING_BALANCE := GET_MONTH_OPENING_BALANCE (P_PROCESS_DATE);
      W_OPENING_INT_BALANCE := GET_MONTH_INT_OPENING_BALANCE (P_PROCESS_DATE);
      W_OPENING_CHG_BALANCE := GET_MONTH_CHG_OPENING_BALANCE (P_PROCESS_DATE);

    IF W_LN_TRAN_FROM_DATE IS NOT NULL THEN
         GET_TRAN_BALANCE (W_YEAR);
      ELSE
         W_TRAN_BAL := 0;
         W_TRAN_INT_BAL := 0;
         W_TRAN_CHG_BAL := 0;
      END IF;

      W_TRAN_BALANCE_SUM := W_TRAN_BAL;
      W_TRAN_INT_BAL_SUM := W_TRAN_INT_BAL;
      W_TRAN_CHG_BAL_SUM := W_TRAN_CHG_BAL;
      -- AGK-26-FEB-2008-REM          IF W_PREV_YR_VALUE_DATE = TRUE THEN
      --GET_TRAN_BALANCE(W_YEAR - 1); RAJIB ON 15/05/2014
      ---W_TRAN_BALANCE_SUM := W_TRAN_BALANCE_SUM + W_TRAN_BAL; RAJIB ON 15/05/2014
      -- W_TRAN_INT_BAL_SUM := W_TRAN_INT_BAL_SUM + W_TRAN_INT_BAL; RAJIB ON 15/05/2014
      -- AGK-26-FEB-2008-REM          END IF;

      W_VALUE_BALANCE := W_OPENING_BALANCE + W_TRAN_BALANCE_SUM;
      W_VALUE_INT_BALANCE := W_OPENING_INT_BALANCE + W_TRAN_INT_BAL_SUM;
      W_VALUE_CHG_BALANCE := W_OPENING_CHG_BALANCE + W_TRAN_CHG_BAL_SUM;
   END GET_VALUE_DATE_BALANCE;

  PROCEDURE GET_INT_DEB_UPTO_DATE IS
   BEGIN
      W_REDUCE_AMOUNT := 0;

      /*          IF V_LN_LNPRODPM(W_ACNTS_PROD_CODE) .LNPRD_SIMPLE_COMP_INT = 'S' THEN
                     W_INT_DEB_UPTO_DATE := W_ASON_DATE;
                ELSIF V_LN_LNPRODPM(W_ACNTS_PROD_CODE)
                 .LNPRD_SIMPLE_COMP_INT = 'C' THEN
                     IF V_LN_LNPRODPM(W_ACNTS_PROD_CODE)
                      .LNPRD_INT_APPL_FREQ = 'M' THEN
                          W_INT_DEB_UPTO_DATE := LAST_DAY(ADD_MONTHS(W_ASON_DATE,
                                                                     -1));
                     ELSIF V_LN_LNPRODPM(W_ACNTS_PROD_CODE)
                      .LNPRD_INT_APPL_FREQ = 'Q' THEN
                          W_INT_DEB_UPTO_DATE := LAST_DAY(ADD_MONTHS(SP_FORM_END_DATE(W_ASON_DATE,
                                                                                      'Q'),
                                                                     -1));
                     ELSIF V_LN_LNPRODPM(W_ACNTS_PROD_CODE)
                      .LNPRD_INT_APPL_FREQ = 'H' THEN
                          W_INT_DEB_UPTO_DATE := LAST_DAY(ADD_MONTHS(SP_FORM_END_DATE(W_ASON_DATE,
                                                                                      'H'),
                                                                     -1));
                     ELSIF V_LN_LNPRODPM(W_ACNTS_PROD_CODE)
                      .LNPRD_INT_APPL_FREQ = 'Y' THEN
                          W_INT_DEB_UPTO_DATE := LAST_DAY(ADD_MONTHS(SP_FORM_END_DATE(W_ASON_DATE,
                                                                                      'Y'),
                                                                     -1));
                     END IF;
                END IF;
      */
      /*27-02-2008-rem          IF V_LN_LNPRODPM(W_ACNTS_PROD_CODE) .LNPRD_SIMPLE_COMP_INT = 'S' THEN
                     GET_INT_REDUCE_AMT_SIMPLE;
                ELSIF V_LN_LNPRODPM(W_ACNTS_PROD_CODE)
                 .LNPRD_SIMPLE_COMP_INT = 'C' THEN
                     GET_INT_REDUCE_AMT_COMP;
                END IF;
      */
    IF W_SIMPLE_COMP_INT = 'S' THEN
         GET_INT_REDUCE_AMT_SIMPLE;
    ELSIF W_SIMPLE_COMP_INT = 'C' THEN
         GET_INT_REDUCE_AMT_COMP;
      END IF;
   END GET_INT_DEB_UPTO_DATE;

  PROCEDURE PROCESS_FOR_GETTING_OVERDUE IS
      W_IN_ERR_MSG    VARCHAR2 (1000);
      W_DUMMY_AMT     NUMBER (18, 3);
      W_DUMMY_VAR     VARCHAR2 (100);
      W_OD_DATE_VAR   VARCHAR2 (20);
   BEGIN
     <<GETODAMT>>
      BEGIN
         PKG_LNOVERDUE.SP_LNOVERDUE (V_GLOB_ENTITY_NUM,
                                     W_INTERNAL_ACNUM,
                                     TO_CHAR (W_PROCESS_DATE, 'DD-MM-YYYY'),
                                     TO_CHAR (W_ASON_DATE, 'DD-MM-YYYY'),
                                     W_IN_ERR_MSG,
                                     W_DUMMY_AMT,
                                     W_DUMMY_AMT,
                                     W_DP_AMT,
                                     W_SANC_LIMIT,
                                     W_OD_AMT,
                                     W_OD_DATE_VAR,
                                     W_DUMMY_AMT,
                                     W_DUMMY_VAR,
                                     W_DUMMY_AMT,
                                     W_DUMMY_VAR,
                                     W_DUMMY_AMT,
                                     W_DUMMY_VAR);

         --AGK-04-SEP-2008-BEG
      IF TRIM(W_IN_ERR_MSG) IS NOT NULL THEN
            RAISE E_USEREXCEP;
         END IF;

         --AGK-04-SEP-2008-END
      IF TRIM(W_OD_DATE_VAR) IS NOT NULL THEN
            W_OD_DATE := TO_DATE (W_OD_DATE_VAR, 'DD-MM-YYYY');
         END IF;

         W_OD_AMT := NVL (W_OD_AMT, 0);
         --05-08-2010-beg
         W_ACTUAL_OVERDUE_AMT := PKG_LNOVERDUE.P_ACTUAL_OD_AMT;
         --05-08-2010-end
         --Karthik-chn-19-Feb-2008-Add
         W_OD_AMT := -1 * ABS (W_OD_AMT);
         W_DP_AMT := NVL (W_DP_AMT, 0);
         W_SANC_LIMIT := NVL (W_SANC_LIMIT, 0);
      EXCEPTION
      WHEN OTHERS THEN
            W_ERR_MSG := 'Error in Overdue Amount Getting ' || W_IN_ERR_MSG;
            RAISE E_USEREXCEP;
      END GETODAMT;
   END PROCESS_FOR_GETTING_OVERDUE;

  PROCEDURE GET_OVERDUE_AMT IS
      W_LNOD_SANC_LIMIT   NUMBER (18, 3);
      W_LNOD_DP_AMT       NUMBER (18, 3);
      W_LNOD_OD_AMT       NUMBER (18, 3);
      W_LNOD_OD_DATE      DATE;
      W_LNOD_EFF_DATE     DATE;
   BEGIN
      W_ACTUAL_OVERDUE_AMT := 0;
      W_PROCESS_ACT_AMT := 0;

      W_SANC_LIMIT := 0;
      W_DP_AMT := 0;
      W_OD_AMT := 0;
      W_OD_FOUND := '0';
      W_OD_DATE := NULL;

      W_LNOD_SANC_LIMIT := 0;
      W_LNOD_DP_AMT := 0;
      W_LNOD_OD_AMT := 0;
      W_LNOD_OD_DATE := NULL;
      W_LNOD_EFF_DATE := NULL;

     <<READLNODHIST>>
      BEGIN
         SELECT L.LNODHIST_SANC_LIMIT_AMT,
                L.LNODHIST_DP_AMT,
                L.LNODHIST_OD_AMT,
                L.LNODHIST_OD_DATE,
                L.LNODHIST_ACTUAL_DUE_AMT
           INTO W_SANC_LIMIT,
                W_DP_AMT,
                W_OD_AMT,
                W_OD_DATE,
                W_ACTUAL_OVERDUE_AMT
           FROM TEMP_LNODHIST_DATA L
          WHERE     LNODHIST_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND L.LNODHIST_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND L.LNODHIST_EFF_DATE =
                       (SELECT MAX (LL.LNODHIST_EFF_DATE)
                          FROM TEMP_LNODHIST_DATA LL
                         WHERE     LNODHIST_ENTITY_NUM = V_GLOB_ENTITY_NUM
                 AND LL.LNODHIST_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                               AND LL.LNODHIST_EFF_DATE <= W_PROCESS_DATE);

         --AGK-17-FEB-08 REMOVED (LL.LNODHIST_OD_DATE IS NOT NULL AND) ---AGK-17-FEB-08 REMOVED

         W_OD_AMT := -1 * ABS (W_OD_AMT);
      /* BELOW CONDITION COMMENTED, BECAUSE IT IS HANDLED IN OVERDUE UPDATION PROCEDURE (AGK-28-APR-2008-REM-BEG)
      --23-04-2008-added-beg
                    <<CHECKLONOD>>
                    BEGIN
                         SELECT L.LNOD_LATEST_EFF_DATE,  L.LNOD_SANC_LIMIT_AMT, L.LNOD_DP_AMT, L.LNOD_OD_AMT, L.LNOD_OD_DATE INTO
                         W_LNOD_EFF_DATE, W_LNOD_SANC_LIMIT, W_LNOD_DP_AMT, W_LNOD_OD_AMT, W_LNOD_OD_DATE FROM LNOD L WHERE L.LNOD_INTERNAL_ACNUM = W_INTERNAL_ACNUM;

                         W_OD_FOUND  := '1';

                         IF W_LNOD_OD_DATE IS NOT NULL THEN
                           IF W_LNOD_EFF_DATE = W_ASON_DATE THEN
                              IF W_LNOD_OD_DATE  <= W_PROCESS_DATE THEN
                                  W_SANC_LIMIT := W_LNOD_SANC_LIMIT;
                                  W_DP_AMT     := W_LNOD_DP_AMT;
                                  W_OD_AMT     := W_LNOD_OD_AMT;
                                  W_OD_DATE    := W_LNOD_OD_DATE;

                                  W_OD_AMT := -1 * ABS(W_OD_AMT);
                              END IF;
                           END IF;
                         END IF;
                    EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                              PROCESS_FOR_GETTING_OVERDUE;
                    END CHECKLONOD;       */
      --23-04-2008-added-end

      EXCEPTION
      WHEN NO_DATA_FOUND THEN

            BEGIN
               SELECT MAX (LNACRSH_EFF_DATE)
                 INTO W_LAT_EFF_DATE
                 FROM LNACRSHIST
                WHERE     LNACRSH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND LNACRSH_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                      AND LNACRSH_EFF_DATE <= W_ASON_DATE;
            END;
      /* Note: Will Remove This Comment
       IF W_LAT_EFF_DATE IS NOT NULL THEN
        PROCESS_FOR_GETTING_OVERDUE;
      END IF; */

      END READLNODHIST;

    IF W_OD_DATE IS NULL THEN
         W_OD_AMT := 0;
      END IF;
   END GET_OVERDUE_AMT;

  FUNCTION GET_OD_INTER_TYPE RETURN NUMBER IS
      P_SEGMENT_CODE            VARCHAR2 (6);
      P_PROD_CODE               NUMBER (4);
      W_PENALIR_OD_INT_CHOICE   NUMBER (1);
   BEGIN
      P_PROD_CODE := T_ACNTS (V_CTR).ACNTS_PROD_CODE;
      W_PENALIR_OD_INT_CHOICE := 0;

     <<READ_PENALIRHIST>>
      BEGIN
         SELECT P.PENALIRH_OD_INT_CHOICE
           INTO W_PENALIR_OD_INT_CHOICE
           FROM PENALIRHIST P
          WHERE     PENALIRH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND P.PENALIRH_PROD_CODE = P_PROD_CODE
                AND P.PENALIRH_CLIENT_SEG_CODE = P_SEGMENT_CODE
                AND P.PENALIRH_EFF_DATE =
                       (SELECT MAX (PP.PENALIRH_EFF_DATE)
                          FROM PENALIRHIST PP
                         WHERE     PENALIRH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                               AND PP.PENALIRH_PROD_CODE = P_PROD_CODE
                 AND PP.PENALIRH_CLIENT_SEG_CODE = P_SEGMENT_CODE
                               AND PP.PENALIRH_EFF_DATE <= W_PROCESS_DATE);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           <<READ_PENALIRHIST_SEGSPACE>>
            BEGIN
               SELECT P.PENALIRH_OD_INT_CHOICE
                 INTO W_PENALIR_OD_INT_CHOICE
                 FROM PENALIRHIST P
                WHERE     PENALIRH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND P.PENALIRH_PROD_CODE = P_PROD_CODE
                      AND TRIM (P.PENALIRH_CLIENT_SEG_CODE) IS NULL
                      AND P.PENALIRH_EFF_DATE =
                             (SELECT MAX (PP.PENALIRH_EFF_DATE)
                                FROM PENALIRHIST PP
                   WHERE PENALIRH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                                     AND PP.PENALIRH_PROD_CODE = P_PROD_CODE
                     AND TRIM(PP.PENALIRH_CLIENT_SEG_CODE) IS NULL
                     AND PP.PENALIRH_EFF_DATE <= W_PROCESS_DATE);
            EXCEPTION
          WHEN NO_DATA_FOUND THEN
                 <<READ_PENALIRHIST_NEXT>>
                  BEGIN
                     SELECT P.PENALIRH_OD_INT_CHOICE
                       INTO W_PENALIR_OD_INT_CHOICE
                       FROM PENALIRHIST P
                      WHERE     PENALIRH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                            AND P.PENALIRH_PROD_CODE = 0
                            AND TRIM (P.PENALIRH_CLIENT_SEG_CODE) IS NULL
                            AND P.PENALIRH_EFF_DATE =
                                   (SELECT MAX (PP.PENALIRH_EFF_DATE)
                                      FROM PENALIRHIST PP
                       WHERE PENALIRH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                                           AND PP.PENALIRH_PROD_CODE = 0
                         AND TRIM(PP.PENALIRH_CLIENT_SEG_CODE) IS NULL
                         AND PP.PENALIRH_EFF_DATE <= W_PROCESS_DATE);
                  EXCEPTION
              WHEN NO_DATA_FOUND THEN
                        W_PENALIR_OD_INT_CHOICE := 0;
                  END READ_PENALIRHIST_NEXT;
            END READ_PENALIRHIST_SEGSPACE;
      END READ_PENALIRHIST;

      RETURN W_PENALIR_OD_INT_CHOICE;
   END GET_OD_INTER_TYPE;

  FUNCTION GET_CLIENTS_SEGMENTS(W_CLIENTS_CODE IN NUMBER) RETURN VARCHAR2 IS
      W_SEGMENT_CODE   VARCHAR2 (6);
   BEGIN
     <<READCLIENTS>>
      BEGIN
         SELECT C.CLIENTS_SEGMENT_CODE
           INTO W_SEGMENT_CODE
           FROM CLIENTS C
          WHERE C.CLIENTS_CODE = W_CLIENTS_CODE;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_SEGMENT_CODE := '';
      END READCLIENTS;

      RETURN W_SEGMENT_CODE;
   END GET_CLIENTS_SEGMENTS;

  FUNCTION CEHCK_OVERDUE_REQ(P_PROCESS_DATE IN DATE) RETURN BOOLEAN IS
      V_OD_INT_CALC_REQ   CHAR;
   BEGIN
      V_OD_INT_CALC_REQ := '1';

     <<READLNACIRS>>
      BEGIN
      IF P_PROCESS_DATE = W_ASON_DATE THEN
            SELECT NVL (L.LNACIRS_OVERDUE_INT_APPLICABLE, '1')
              INTO V_OD_INT_CALC_REQ
              FROM LNACIRS L
             WHERE     LNACIRS_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND L.LNACIRS_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
         ELSE
            SELECT NVL (L.LNACIRSH_OD_INT_APPLICABLE, '1')
              INTO V_OD_INT_CALC_REQ
              FROM LNACIRSHIST L
             WHERE     LNACIRSH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND L.LNACIRSH_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                   AND L.LNACIRSH_EFF_DATE =
                          (SELECT MAX (L.LNACIRSH_EFF_DATE)
                             FROM LNACIRSHIST L
                            WHERE     LNACIRSH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND L.LNACIRSH_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                                  AND L.LNACIRSH_EFF_DATE <= W_PROCESS_DATE);
         END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            V_OD_INT_CALC_REQ := '1';
      END READLNACIRS;

    IF W_NPA_STATUS = '1' THEN
      IF NVL(W_NPA_OD_INT_REQD, '0') = '0' THEN
            RETURN FALSE;
         END IF;
      END IF;

    IF V_OD_INT_CALC_REQ = '1' THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END CEHCK_OVERDUE_REQ;

  PROCEDURE GET_OVERDUE_INT_RATE IS
      W_DUMMY_INT_RATE   NUMBER (7, 5);
      W_CLINT_SEG        VARCHAR2 (400);
   BEGIN
     <<GETPENALRATE>>
      BEGIN
         W_DUMMY_INT_RATE := 0;
         W_PENAL_FOR_OVERDUE := 0;
         PKG_LOANINTRATEASON.PV_ERR_MSG := NULL;

      IF CEHCK_OVERDUE_REQ(W_PROCESS_DATE) = TRUE THEN
            -- Condition Added By Manoj 30-03-2012
            --   IF W_PENAL_INT_APPLICABLE <> '0' THEN
        SP_PENALINTRATE(V_GLOB_ENTITY_NUM,
               T_ACNTS (V_CTR).ACNTS_PROD_CODE,
                        GET_CLIENTS_SEGMENTS(T_ACNTS(V_CTR)
                                             .ACNTS_CLIENTS_CODE),
               W_PROCESS_DATE,
               W_PENAL_FOR_OVERDUE,
               W_DUMMY_INT_RATE,
               W_DUMMY_INT_RATE,
               W_DUMMY_INT_RATE,
               W_DUMMY_INT_RATE,
               W_ERR_MSG,
               W_INTERNAL_ACNUM);                   --ADDED BY MANOJ 28OCT2012
            --  END IF;
        W_CLINT_SEG := GET_CLIENTS_SEGMENTS(T_ACNTS(V_CTR)
                                            .ACNTS_CLIENTS_CODE);

        IF TRIM(PKG_LOANINTRATEASON.PV_ERR_MSG) IS NOT NULL THEN
          PKG_PB_GLOBAL.DETAIL_ERRLOG(V_GLOB_ENTITY_NUM,
                  'X',
                                      PKG_LOANINTRATEASON.PV_ERR_MSG || ' ' ||
                                      ' Process Date =' || W_PROCESS_DATE,
                  ' ',
                  W_INTERNAL_ACNUM);
               W_SKIP_FLAG := TRUE;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERR_MSG :=
                  'Error in Penal Interest Rate Getting '
               || ' '
               || SUBSTR (SQLERRM, 1, 900);
            RAISE E_USEREXCEP;
      END GETPENALRATE;
   END GET_OVERDUE_INT_RATE;

  PROCEDURE GETFACTOR IS
   BEGIN
     <<GETFACT>>
      BEGIN
         W_FACTOR := V_LN_LNCURRPM (W_PRODCODE_CURRCODE).LNCUR_INT_CALCN_BASIS;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        W_ERR_MSG := 'Denomination Factor Not Defined  - ' ||
                     ' Product Code - ' || W_ACNTS_PROD_CODE ||
                     ' scheme code - ' || SUBSTR(W_PRODCODE_CURRCODE, 5, 6) ||
                     ' Curr Code - ' || W_ACNTS_CURR_CODE;
            RAISE E_USEREXCEP;
      END GETFACT;
   END GETFACTOR;

  PROCEDURE CALC_SINGLE_INT_RATE IS
   BEGIN
      GETFACTOR;
    W_ACT_AC_INT_AMT := W_VALUE_BALANCE * 1 * W_SINGLE_INT_RATE /
                        (100 * W_FACTOR);
      UPDATE_RTMPLNIADTL (W_SINGLE_INT_RATE,
                          W_VALUE_BALANCE,
                          W_ACT_AC_INT_AMT);
   END CALC_SINGLE_INT_RATE;

  PROCEDURE CALC_SLAB_INT_RATE IS
      W_BREAK_BALANCE         NUMBER (18, 3);
      W_SLAB_CHOICE           NUMBER (1);
      W_BALANCE               NUMBER (18, 3);
      V_UPTOAMT               NUMBER (18, 3);
      V_SLAB_INT_RATE         NUMBER (7, 5);
      W_INTEREST_AMOUNT       NUMBER (18, 9);
      W_PREV_SLAB_AMOUNT      NUMBER (18, 3);
      W_IND_INTEREST_AMOUNT   NUMBER (18, 9);
   BEGIN
      W_INTEREST_AMOUNT := 0;
      W_BALANCE := ABS (W_VALUE_BALANCE);
      W_BREAK_BALANCE := W_BALANCE;
    W_FACTOR           := V_LN_LNCURRPM(W_PRODCODE_CURRCODE)
                          .LNCUR_INT_CALCN_BASIS;
      W_SLAB_CHOICE := PKG_LOANINTRATEASON.V_LNACIR_SLAB_APPL_CHOICE;
      W_PREV_SLAB_AMOUNT := 0;

     <<BREAKLOOP>>
    FOR IDX IN 1 .. PKG_LOANINTRATEASON.V_SLAB_INIT_AMT_RATE.COUNT LOOP
      V_UPTOAMT := PKG_LOANINTRATEASON.V_SLAB_INIT_AMT_RATE(IDX).SLAB_AMOUNT;
         --DBMS_OUTPUT.PUT_LINE(V_UPTOAMT);
      V_SLAB_INT_RATE := PKG_LOANINTRATEASON.V_SLAB_INIT_AMT_RATE(IDX)
                         .SLAB_INIT_RATE;

      IF W_SLAB_CHOICE = 1 THEN
            --natarajan.a-chn-08-07-2008-rem                    IF (V_UPTOAMT > W_BALANCE) THEN
        IF (V_UPTOAMT >= W_BALANCE) THEN
          W_INTEREST_AMOUNT := ((W_BALANCE * (V_SLAB_INT_RATE) * 1) /
                               (W_FACTOR * 100));
          UPDATE_RTMPLNIADTL(V_SLAB_INT_RATE, W_BALANCE, W_INTEREST_AMOUNT);
               EXIT BREAKLOOP;
            END IF;
         ELSE
        IF V_UPTOAMT >= W_BALANCE THEN
          W_IND_INTEREST_AMOUNT := ((W_BREAK_BALANCE * (V_SLAB_INT_RATE) * 1) /
                                   (W_FACTOR * 100));
          W_INTEREST_AMOUNT     := W_INTEREST_AMOUNT +
                                   W_IND_INTEREST_AMOUNT;
               UPDATE_RTMPLNIADTL (V_SLAB_INT_RATE,
                                   W_BREAK_BALANCE,
                                   W_IND_INTEREST_AMOUNT);
               EXIT BREAKLOOP;
            ELSE
          W_IND_INTEREST_AMOUNT := (((V_UPTOAMT - W_PREV_SLAB_AMOUNT) *
                                   (V_SLAB_INT_RATE) * 1) /
                                   (W_FACTOR * 100));
          W_INTEREST_AMOUNT     := W_INTEREST_AMOUNT +
                                   W_IND_INTEREST_AMOUNT;
               W_BREAK_BALANCE := W_BALANCE - V_UPTOAMT;
               W_PREV_SLAB_AMOUNT := V_UPTOAMT;
               UPDATE_RTMPLNIADTL (V_SLAB_INT_RATE,
                                   V_UPTOAMT,
                                   W_IND_INTEREST_AMOUNT);
            END IF;
         END IF;
      END LOOP;

      W_ACT_AC_INT_AMT := W_INTEREST_AMOUNT * -1;
   END CALC_SLAB_INT_RATE;

  PROCEDURE CALC_INTEREST_AMOUNT IS
   BEGIN
      W_SINGLE_INT_RATE := PKG_LOANINTRATEASON.V_SINGLE_INT_RATE;

    IF W_SINGLE_INT_RATE <> 0 THEN
         CALC_SINGLE_INT_RATE;
      ELSE
         CALC_SLAB_INT_RATE;
      END IF;
   END CALC_INTEREST_AMOUNT;

  PROCEDURE GET_INTEREST_RATE IS
   BEGIN
     <<GETINTERESTRATE>>
      BEGIN
         PKG_LOANINTRATEASON.PV_ERR_MSG := NULL;
         PKG_LOANINTRATEASON.V_INTEREST_RATE_AVAILABLE := 0;
         PKG_LOANINTRATEASON.SP_LOANINTRATEASON (V_GLOB_ENTITY_NUM,
                                                 W_INTERNAL_ACNUM,
                                                 W_PROCESS_DATE,
                                                 1);

      IF TRIM(PKG_LOANINTRATEASON.PV_ERR_MSG) IS NOT NULL THEN
        PKG_PB_GLOBAL.DETAIL_ERRLOG(V_GLOB_ENTITY_NUM,
               'X',
                                    PKG_LOANINTRATEASON.PV_ERR_MSG || ' ' ||
                                    ' Process Date =' || W_PROCESS_DATE,
               ' ',
               W_INTERNAL_ACNUM);
            W_SKIP_FLAG := TRUE;
         ELSE
        IF PKG_LOANINTRATEASON.V_INTEREST_RATE_AVAILABLE = 0 THEN
          RECORD_EXCEPTION(FACNO(V_GLOB_ENTITY_NUM, W_INTERNAL_ACNUM) ||
                           ' - Interest Rate Not Available');
               W_SKIP_FLAG := TRUE;
            END IF;
         END IF;
      EXCEPTION
      WHEN OTHERS THEN
        W_ERR_MSG := 'Error in Loan Interest Ason Date Calculation' || ' ' ||
                     SUBSTR(SQLERRM, 1, 900);
            RAISE E_USEREXCEP;
      END GETINTERESTRATE;
   END GET_INTEREST_RATE;

  PROCEDURE CALC_OD_INT IS
   BEGIN
      W_OD_AC_INT_AMT := 0;
      W_OD_BC_INT_AMT := 0;
    W_FACTOR        := V_LN_LNCURRPM(W_PRODCODE_CURRCODE)
                       .LNCUR_INT_CALCN_BASIS;
    W_OD_AC_INT_AMT := (W_OD_AMT * 1 * W_PENAL_FOR_OVERDUE) /
                       (100 * W_FACTOR);
   END CALC_OD_INT;

  PROCEDURE INIT_LOANPKG_VALUES IS
   BEGIN
      PKG_LOANINTRATEASON.V_SINGLE_INT_RATE := 0;
      PKG_LOANINTRATEASON.V_LNACIR_SLAB_APPL_CHOICE := 0;
      PKG_LOANINTRATEASON.V_INTEREST_RATE_AVAILABLE := 0;
      PKG_LOANINTRATEASON.V_SLAB_INIT_AMT_RATE.DELETE;
   END INIT_LOANPKG_VALUES;


   PROCEDURE SP_CLEAR_RTMPLNNOTDUE
   IS
   BEGIN
      T_RTMPLNND_INTERNAL_ACNUM.DELETE;
      T_RTMPLNND_GRACE_END_DATE.DELETE;
      T_RTMPLNND_NOT_DUE_AMT.DELETE;
      T_RTMPLNND_ENTRY_TYPE.DELETE;
      T_RTMPLNND_ACTUAL_DUE_DATE.DELETE;
      T_RTMPLNND_FINAL_DUE_AMT.DELETE;
   END SP_CLEAR_RTMPLNNOTDUE;


   PROCEDURE SP_INSERT_RTMPLNNOTDUE
   IS
   BEGIN
      IF T_RTMPLNND_INTERNAL_ACNUM.COUNT>1 THEN

         W_RTMPLNNOTDUE_DATA_EXIST := TRUE;

         FORALL IDX
             IN T_RTMPLNND_INTERNAL_ACNUM.FIRST ..
                T_RTMPLNND_INTERNAL_ACNUM.LAST
            INSERT INTO RTMPLNNOTDUE (RTMPLNND_INTERNAL_ACNUM,
                                      RTMPLNND_GRACE_END_DATE,
                                      RTMPLNND_NOT_DUE_AMT,
                                      RTMPLNND_ENTRY_TYPE,
                                      RTMPLNND_ACTUAL_DUE_DATE,
                                      RTMPLNND_FINAL_DUE_AMT)
                 VALUES (T_RTMPLNND_INTERNAL_ACNUM (IDX),
                         T_RTMPLNND_GRACE_END_DATE (IDX),
                         T_RTMPLNND_NOT_DUE_AMT (IDX),
                         T_RTMPLNND_ENTRY_TYPE (IDX),
                         T_RTMPLNND_ACTUAL_DUE_DATE (IDX),
                         T_RTMPLNND_FINAL_DUE_AMT (IDX));

         SP_CLEAR_RTMPLNNOTDUE;
      END IF;
   END SP_INSERT_RTMPLNNOTDUE;


  PROCEDURE PROCESS_FOR_OD_REUPDATE IS
      W_DUMMY_ACTUAL_OD   NUMBER (18, 3);
      W_FINAL_DUE_AMT     NUMBER (18, 3);
   BEGIN
      W_DUMMY_ACTUAL_OD := ABS (W_ACTUAL_OVERDUE_AMT);
      W_FINAL_DUE_AMT := 0;

    IF W_RTMPLNNOTDUE_DATA_EXIST THEN --- Added by rajib.pradhan for reduce latch contention

         FOR IDX IN (  SELECT *
                         FROM RTMPLNNOTDUE C
                     ORDER BY C.RTMPLNND_GRACE_END_DATE DESC) LOOP
          IF IDX.RTMPLNND_NOT_DUE_AMT > W_DUMMY_ACTUAL_OD THEN
               W_FINAL_DUE_AMT := W_DUMMY_ACTUAL_OD;
               W_DUMMY_ACTUAL_OD := 0;
            ELSE
               W_FINAL_DUE_AMT := IDX.RTMPLNND_NOT_DUE_AMT;
            W_DUMMY_ACTUAL_OD := W_DUMMY_ACTUAL_OD -
                                 ABS(IDX.RTMPLNND_NOT_DUE_AMT);
            END IF;

            UPDATE RTMPLNNOTDUE C
               SET C.RTMPLNND_FINAL_DUE_AMT = W_FINAL_DUE_AMT
           WHERE C.RTMPLNND_INTERNAL_ACNUM = IDX.RTMPLNND_INTERNAL_ACNUM
             AND C.RTMPLNND_GRACE_END_DATE = IDX.RTMPLNND_GRACE_END_DATE
                   AND C.RTMPLNND_NOT_DUE_AMT = IDX.RTMPLNND_NOT_DUE_AMT
                   AND C.RTMPLNND_ENTRY_TYPE = IDX.RTMPLNND_ENTRY_TYPE
             AND C.RTMPLNND_ACTUAL_DUE_DATE = IDX.RTMPLNND_ACTUAL_DUE_DATE;
         END LOOP;
      END IF;
   END PROCESS_FOR_OD_REUPDATE;

  PROCEDURE PROCESS_FOR_LOAIAPA IS
      W_ARR_NOD      NUMBER (3);
      W_ARR_INT      NUMBER (18, 3);
      W_ARR_OD_INT   NUMBER (18, 3);
   BEGIN
      W_ARR_NOD := 0;
      W_ARR_INT := 0;
      W_ARR_OD_INT := 0;
      W_OD_PENDING_PRODUCT := 0;

     <<READLOANIAPS>>
      BEGIN
         IF W_LOANIAPS_COUNT > 0 OR V_COUNT_LOANIAPS = 1
         THEN
            FOR IDX
               IN (SELECT *
                     FROM LOANIAPS L
                    WHERE     L.LOANIAPS_ENTITY_NUM = V_GLOB_ENTITY_NUM
                          AND L.LOANIAPS_BRN_CODE = W_PROC_BRN_CODE
                          AND L.LOANIAPS_ACNT_NUM = W_INTERNAL_ACNUM
                          AND L.LOANIAPS_GRACE_END_DATE = W_PROCESS_DATE - 1
                          AND L.LOANIAPS_ACCRUAL_DATE =
                                 (SELECT MAX (L.LOANIAPS_ACCRUAL_DATE)
                                    FROM LOANIAPS L
                           WHERE L.LOANIAPS_ENTITY_NUM = V_GLOB_ENTITY_NUM
                             AND L.LOANIAPS_BRN_CODE = W_PROC_BRN_CODE
                             AND L.LOANIAPS_ACNT_NUM = W_INTERNAL_ACNUM
                                         AND L.LOANIAPS_GRACE_END_DATE =
                                 W_PROCESS_DATE - 1)) LOOP
               DELETE FROM LOANIAPSHIST C
                     WHERE     C.LOANIAPSH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                           AND C.LOANIAPSH_BRN_CODE = W_PROC_BRN_CODE
                           AND C.LOANIAPSH_ACNT_NUM = W_INTERNAL_ACNUM
           AND C.LOANIAPSH_GRACE_END_DATE = W_PROCESS_DATE - 1;

        INSERT INTO LOANIAPSHIST
          (LOANIAPSH_ENTITY_NUM,
                                         LOANIAPSH_BRN_CODE,
                                         LOANIAPSH_ACNT_NUM,
                                         LOANIAPSH_GRACE_END_DATE,
                                         LOANIAPSH_ACCRUAL_DATE,
                                         LOANIAPSH_PS_SERIAL,
                                         LOANIAPSH_NOT_DUE_AMT,
                                         LOANIAPSH_ENTRY_TYPE,
                                         LOANIAPSH_ACTUAL_DUE_DATE,
                                         LOANIAPSH_FINAL_DUE_AMT)
        VALUES
          (IDX.LOANIAPS_ENTITY_NUM,
                            IDX.LOANIAPS_BRN_CODE,
                            IDX.LOANIAPS_ACNT_NUM,
                            IDX.LOANIAPS_GRACE_END_DATE,
                            IDX.LOANIAPS_ACCRUAL_DATE,
                            IDX.LOANIAPS_PS_SERIAL,
                            IDX.LOANIAPS_NOT_DUE_AMT,
                            IDX.LOANIAPS_ENTRY_TYPE,
                            IDX.LOANIAPS_ACTUAL_DUE_DATE,
                            IDX.LOANIAPS_FINAL_DUE_AMT);

        W_ARR_NOD            := IDX.LOANIAPS_GRACE_END_DATE -
                                IDX.LOANIAPS_ACTUAL_DUE_DATE;
               W_ARR_INT := (IDX.LOANIAPS_FINAL_DUE_AMT * W_ARR_NOD);
               W_OD_PENDING_PRODUCT := W_OD_PENDING_PRODUCT + W_ARR_INT;

               V_COUNT_LOANIAPS := 0;
            END LOOP;
         END IF;
      END READLOANIAPS;
   END PROCESS_FOR_LOAIAPA;

  PROCEDURE PROCESS_LOANIAPS IS
   BEGIN
      DELETE FROM LOANIAPS C
            WHERE     C.LOANIAPS_ENTITY_NUM = V_GLOB_ENTITY_NUM
                  AND C.LOANIAPS_BRN_CODE = W_PROC_BRN_CODE
                  AND C.LOANIAPS_ACNT_NUM = W_INTERNAL_ACNUM;

      IF W_RTMPLNNOTDUE_DATA_EXIST
      THEN              --- Added by rajib.pradhan for reduce latch contention
         V_COUNT_LOANIAPS := 1;

         INSERT INTO LOANIAPS (LOANIAPS_ENTITY_NUM,
                               LOANIAPS_BRN_CODE,
                               LOANIAPS_ACNT_NUM,
                               LOANIAPS_GRACE_END_DATE,
                               LOANIAPS_ACCRUAL_DATE,
                               LOANIAPS_PS_SERIAL,
                               LOANIAPS_NOT_DUE_AMT,
                               LOANIAPS_ENTRY_TYPE,
                               LOANIAPS_ACTUAL_DUE_DATE,
                               LOANIAPS_FINAL_DUE_AMT)
            (SELECT V_GLOB_ENTITY_NUM,
                    W_PROC_BRN_CODE,
                    C.RTMPLNND_INTERNAL_ACNUM,
                    C.RTMPLNND_GRACE_END_DATE,
                    W_PROCESS_DATE,
                    ROWNUM,
                    C.RTMPLNND_NOT_DUE_AMT,
                    C.RTMPLNND_ENTRY_TYPE,
                    C.RTMPLNND_ACTUAL_DUE_DATE,
                    C.RTMPLNND_FINAL_DUE_AMT
               FROM RTMPLNNOTDUE C
              WHERE C.RTMPLNND_INTERNAL_ACNUM = W_INTERNAL_ACNUM);

         DELETE FROM RTMPLNNOTDUE
               WHERE RTMPLNND_INTERNAL_ACNUM = W_INTERNAL_ACNUM;

         W_RTMPLNNOTDUE_DATA_EXIST := FALSE;
      END IF;
   END PROCESS_LOANIAPS;

  PROCEDURE PROCESS_CHKPENALAPPLICABILITY IS
   BEGIN
      SELECT LNPRD_PENAL_INT_APPLICABLE
        INTO W_PENAL_INT_APPLICABLE
        FROM LNPRODPM
       WHERE LNPRD_PROD_CODE = W_ACNTS_PROD_CODE;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
         W_PENAL_INT_APPLICABLE := '0';
   END PROCESS_CHKPENALAPPLICABILITY;

   -- 30-03-2012 ADDED BY MANOJ PRABHAKAR
   PROCEDURE CALC_INTEREST_AMT
   IS
      V_TEMP_INTEREST_AMT   NUMBER (18, 3);
   BEGIN
      INIT_LOANPKG_VALUES;
      --07-08-201-0-beg
      W_OD_PENDING_PRODUCT := 0;
      PROCESS_FOR_LOAIAPA;
      SP_INSERT_RTMPLNNOTDUE; --- added by rajib.pradhan for Bulk data insert rather than the single insert statement
      PROCESS_FOR_OD_REUPDATE;
      PROCESS_LOANIAPS;
      --07-08-201-0-end
      --30-03-2012 beg Added by Manoj Prabhkar
      --PROCESS_CHKPENALAPPLICABILITY;
    W_PENAL_INT_APPLICABLE := NVL(T_ACNTS(V_CTR).LNPRD_PENAL_INT_APPLICABLE,
                                  0);

    IF W_VALUE_BALANCE <> 0 THEN
         GET_INTEREST_RATE;
      END IF;

      --07-08-2010-rem    IF W_OD_AMT <> 0 THEN
    IF W_OD_AMT <> 0 OR W_OD_PENDING_PRODUCT <> 0 THEN
      IF W_PENAL_INT_APPLICABLE <> '0' THEN
            GET_OVERDUE_INT_RATE;
         END IF;
      END IF;

    IF W_SKIP_FLAG = FALSE THEN
      IF W_VALUE_BALANCE <> 0 THEN
            CALC_INTEREST_AMOUNT;
         ELSE
            W_ACT_AC_INT_AMT := 0;
            W_SINGLE_INT_RATE := 0;
         END IF;

      IF W_OD_AMT <> 0 THEN
            CALC_OD_INT;
         ELSE
            W_OD_AC_INT_AMT := 0;
         END IF;

         W_ARR_OD_INT_AMT := 0;

      IF W_OD_PENDING_PRODUCT <> 0 THEN
        IF NVL(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
               .LNPRD_PENAL_INT_APPL_FROM,
               0) = '1' THEN
               W_ARR_OD_INT_AMT := 0;
          W_FACTOR         := V_LN_LNCURRPM(W_PRODCODE_CURRCODE)
                              .LNCUR_INT_CALCN_BASIS;
          W_ARR_OD_INT_AMT := (W_OD_PENDING_PRODUCT * 1 *
                              W_PENAL_FOR_OVERDUE) / (100 * W_FACTOR);
          W_OD_AC_INT_AMT  := W_OD_AC_INT_AMT +
                              (-1 * ABS(W_ARR_OD_INT_AMT));
            END IF;
         END IF;

         -- Start: Added For Short Term Loan Customization
         IF W_SHORT_TERM_LOAN = '1'
         THEN
            SELECT NVL (SUM (RTMPLNIA_INT_AMT_RND), 0)
              INTO V_TEMP_INTEREST_AMT
              FROM LOANIADLY
             WHERE     RTMPLNIA_ACNT_NUM = W_INTERNAL_ACNUM
                   AND RTMPLNIA_BRN_CODE = W_PROC_BRN_CODE
                   AND TO_CHAR (RTMPLNIA_ACCRUAL_DATE, 'MM-YYYY') =
                          TO_CHAR (W_CBD, 'MM-YYYY')
                   AND RTMPLNIA_INSERT_FROM IS NOT NULL;

            W_CAL_INT_AMT := W_CAL_INT_AMT + ABS (W_ACT_AC_INT_AMT);
            W_CAL_INT_AMT := W_CAL_INT_AMT + V_TEMP_INTEREST_AMT;

            IF ABS (W_LIMIT_SANC_AMT) > 0
            THEN
               IF ( (ABS (W_VALUE_BALANCE) + ABS (W_REDUCE_AMOUNT)) >=
                      (W_LIMIT_SANC_AMT * 2))
               THEN
                  W_SKIP_FLAG := TRUE;
               END IF;
            END IF;

            IF (    (W_CAL_INT_AMT >= NVL (W_DISB_AMT, 0))
                AND (V_LN_LNPRODPM (W_ACNTS_PROD_CODE).PRODUCT_FOR_RUN_ACS <>
                        '1'))
            THEN
               W_SKIP_FLAG := TRUE;
            END IF;

        IF W_SKIP_FLAG = TRUE THEN
               RETURN;
            END IF;
         END IF;

         -- End: Added For Short Term Loan Customization

         UPDATE_RTMPLNIA (FALSE);
      END IF;
   END CALC_INTEREST_AMT;
   
  FUNCTION GET_ALREADY_EXPIRIED_OR_NOT (P_AC_NUM NUMBER, P_PROCESS_DATE DATE)
   RETURN NUMBER
    IS
       V_RETURN_VALUE   NUMBER (1);
       V_EXPIRY_DATE    DATE;
  BEGIN
       SELECT LMTLINE_LIMIT_EXPIRY_DATE
         INTO V_EXPIRY_DATE
         FROM ACASLLDTL, LIMITLINE
        WHERE     ACASLLDTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
              AND LMTLINE_ENTITY_NUM = V_GLOB_ENTITY_NUM
              AND ACASLLDTL_CLIENT_NUM = LMTLINE_CLIENT_CODE
              AND ACASLLDTL_LIMIT_LINE_NUM = LMTLINE_NUM
              AND ACASLLDTL_INTERNAL_ACNUM = P_AC_NUM;

       IF V_EXPIRY_DATE >= P_PROCESS_DATE
       THEN
          V_RETURN_VALUE := 0;
       ELSE
          V_RETURN_VALUE := 1;
       END IF;
       RETURN V_RETURN_VALUE ;
END GET_ALREADY_EXPIRIED_OR_NOT;

  PROCEDURE UPDATE_RTMPLNIA(P_ACTION_FLAG BOOLEAN) IS
   BEGIN
     <<INSERTRTMPLNIA>>
      BEGIN
      IF P_ACTION_FLAG = FALSE THEN
            BEGIN
               V_RTMPLNIA_INDX := V_RTMPLNIA_INDX + 1;

               T_RTMPLNIA_RUN_NUMBER (V_RTMPLNIA_INDX) := W_RUN_NUMBER;
               T_RTMPLNIA_ACNT_NUM (V_RTMPLNIA_INDX) := W_INTERNAL_ACNUM;
               T_RTMPLNIA_VALUE_DATE (V_RTMPLNIA_INDX) := W_PROCESS_DATE;
               T_RTMPLNIA_ACCRUAL_DATE (V_RTMPLNIA_INDX) := W_ASON_DATE;
               T_RTMPLNIA_ACNT_CURR (V_RTMPLNIA_INDX) := W_ACNTS_CURR_CODE;
               T_RTMPLNIA_ACNT_BAL         (V_RTMPLNIA_INDX):= W_VALUE_BALANCE + (-1)*W_REDUCE_AMOUNT;
               T_RTMPLNIA_INT_ON_AMT (V_RTMPLNIA_INDX) := W_VALUE_BALANCE;
               T_RTMPLNIA_OD_PORTION (V_RTMPLNIA_INDX) := W_OD_AMT;
               T_RTMPLNIA_INT_RATE (V_RTMPLNIA_INDX) := W_SINGLE_INT_RATE;
               T_RTMPLNIA_SLAB_AMT (V_RTMPLNIA_INDX) := 0;
               T_RTMPLNIA_OD_INT_RATE (V_RTMPLNIA_INDX) := W_PENAL_FOR_OVERDUE;
               T_RTMPLNIA_LIMIT (V_RTMPLNIA_INDX) := W_SANC_LIMIT;
               T_RTMPLNIA_DP (V_RTMPLNIA_INDX) := W_DP_AMT;
               T_RTMPLNIA_INT_AMT (V_RTMPLNIA_INDX) := W_ACT_AC_INT_AMT;
               T_RTMPLNIA_INT_AMT_RND (V_RTMPLNIA_INDX) := W_ACT_AC_INT_AMT;
               T_RTMPLNIA_OD_INT_AMT (V_RTMPLNIA_INDX) := W_OD_AC_INT_AMT;
               T_RTMPLNIA_OD_INT_AMT_RND (V_RTMPLNIA_INDX) := W_OD_AC_INT_AMT;
               /*
               T_RTMPLNIA_NPA_STATUS (V_RTMPLNIA_INDX) := W_NPA_STATUS;
               */
               T_RTMPLNIA_NPA_STATUS (V_RTMPLNIA_INDX) := GET_ALREADY_EXPIRIED_OR_NOT(W_INTERNAL_ACNUM, W_PROCESS_DATE);
               T_RTMPLNIA_NPA_AMT (V_RTMPLNIA_INDX) := W_NPA_AMT;
               T_RTMPLNIA_ARR_OD_INT_AMT (V_RTMPLNIA_INDX) := W_ARR_OD_INT_AMT;

               T_RTMPLNIA_BRN_CODE (V_RTMPLNIA_INDX) := W_PROC_BRN_CODE;


               IF V_APP_FREQ_STR.EXISTS (T_ACNTS (V_CTR).LNPRD_INT_APPL_FREQ) =
                     TRUE
               THEN
                  T_RTMPLNIA_LNIA_INSERT_FROM (V_RTMPLNIA_INDX) := 'A';
               ELSE
                  IF T_ACNTS (V_CTR).MIRROR_APPLICABLE = 0
                  THEN
                     T_RTMPLNIA_LNIA_INSERT_FROM (V_RTMPLNIA_INDX) := 'A';
                  ELSE
                     T_RTMPLNIA_LNIA_INSERT_FROM (V_RTMPLNIA_INDX) := 'M';
                  END IF;
               END IF;
            END;
         ELSE
            FORALL V_RTMPLNIA_INDX IN 1 .. T_RTMPLNIA_ACNT_NUM.COUNT
                            INSERT INTO RTMPLNIA
                                    (RTMPLNIA_RUN_NUMBER,
                                     RTMPLNIA_ACNT_NUM,
                                     RTMPLNIA_VALUE_DATE,
                                     RTMPLNIA_ACCRUAL_DATE,
                                     RTMPLNIA_ACNT_CURR,
                                     RTMPLNIA_ACNT_BAL,
                                     RTMPLNIA_INT_ON_AMT,
                                     RTMPLNIA_OD_PORTION,
                                     RTMPLNIA_INT_RATE,
                                     RTMPLNIA_SLAB_AMT,
                                     RTMPLNIA_OD_INT_RATE,
                                     RTMPLNIA_LIMIT,
                                     RTMPLNIA_DP,
                                     RTMPLNIA_INT_AMT,
                                     RTMPLNIA_INT_AMT_RND,
                                     RTMPLNIA_OD_INT_AMT,
                                     RTMPLNIA_OD_INT_AMT_RND,
                                     RTMPLNIA_NPA_STATUS,
                                     RTMPLNIA_NPA_AMT,
                                     RTMPLNIA_ARR_OD_INT_AMT,
                                     RTMPLNIA_INSERT_FROM,
                                     RTMPLNIA_BRN_CODE)
                    VALUES (T_RTMPLNIA_RUN_NUMBER (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_ACNT_NUM (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_VALUE_DATE (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_ACCRUAL_DATE (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_ACNT_CURR (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_ACNT_BAL (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_INT_ON_AMT (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_OD_PORTION (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_INT_RATE (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_SLAB_AMT (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_OD_INT_RATE (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_LIMIT (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_DP (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_INT_AMT (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_INT_AMT_RND (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_OD_INT_AMT (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_OD_INT_AMT_RND (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_NPA_STATUS (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_NPA_AMT (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_ARR_OD_INT_AMT (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_LNIA_INSERT_FROM (V_RTMPLNIA_INDX),
                            T_RTMPLNIA_BRN_CODE (V_RTMPLNIA_INDX));


            V_RTMPLNIA_INDX := 0;
            T_RTMPLNIA_RUN_NUMBER.DELETE;
            T_RTMPLNIA_ACNT_NUM.DELETE;
            T_RTMPLNIA_VALUE_DATE.DELETE;
            T_RTMPLNIA_ACCRUAL_DATE.DELETE;
            T_RTMPLNIA_ACNT_CURR.DELETE;
            T_RTMPLNIA_ACNT_BAL.DELETE;
            T_RTMPLNIA_INT_ON_AMT.DELETE;
            T_RTMPLNIA_OD_PORTION.DELETE;
            T_RTMPLNIA_INT_RATE.DELETE;
            T_RTMPLNIA_SLAB_AMT.DELETE;
            T_RTMPLNIA_OD_INT_RATE.DELETE;
            T_RTMPLNIA_LIMIT.DELETE;
            T_RTMPLNIA_DP.DELETE;
            T_RTMPLNIA_INT_AMT.DELETE;
            T_RTMPLNIA_INT_AMT_RND.DELETE;
            T_RTMPLNIA_OD_INT_AMT.DELETE;
            T_RTMPLNIA_OD_INT_AMT_RND.DELETE;
            T_RTMPLNIA_NPA_STATUS.DELETE;
            T_RTMPLNIA_NPA_AMT.DELETE;
            T_RTMPLNIA_ARR_OD_INT_AMT.DELETE;
            T_RTMPLNIA_LNIA_INSERT_FROM.DELETE;
            T_RTMPLNIA_BRN_CODE.DELETE;
         END IF;
      EXCEPTION
      WHEN OTHERS THEN
        W_ERR_MSG := FACNO(V_GLOB_ENTITY_NUM, W_INTERNAL_ACNUM) ||
                     SUBSTR(SQLERRM, 1, 900);
            RAISE E_USEREXCEP;
      END INSERTRTMPLNIA;
   -- SLAB AMT
   -- ROUND OFF
   END UPDATE_RTMPLNIA;

   PROCEDURE UPDATE_RTMPLNIADTL (W_INTEREST_RATE   IN NUMBER,
                                 W_AMOUNT          IN NUMBER,
                               W_INT_AMOUNT    IN NUMBER) IS
   BEGIN
     <<INSERTRTMPLNIADTL>>
      BEGIN
         V_BREAK_SL := V_BREAK_SL + 1;

      INSERT INTO RTMPLNIADTL
        (RTMPLNIADTL_RUN_NUMBER,
                                  RTMPLNIADTL_ACNT_NUM,
                                  RTMPLNIADTL_VALUE_DATE,
                                  RTMPLNIADTL_ACCRUAL_DATE,
                                  RTMPLNIADTL_SL_NUM,
                                  RTMPLNIADTL_INT_RATE,
                                  RTMPLNIADTL_UPTO_AMT,
                                  RTMPLNIADTL_INT_AMT,
                                  RTMPLNIADTL_INT_AMT_RND)
      VALUES
        (W_RUN_NUMBER,
                      W_INTERNAL_ACNUM,
                      W_PROCESS_DATE,
                      W_ASON_DATE,
                      V_BREAK_SL,
                      W_INTEREST_RATE,
                      W_AMOUNT,
                      W_INT_AMOUNT,
                      W_INT_AMOUNT);
      EXCEPTION
      WHEN OTHERS THEN
        W_ERR_MSG := 'Error in rtmplniadtl Updatetion ' ||
                     FACNO(V_GLOB_ENTITY_NUM, W_INTERNAL_ACNUM) ||
                     SUBSTR(SQLERRM, 1, 900);
            RAISE E_USEREXCEP;
      END INSERTRTMPLNIADTL;
   END UPDATE_RTMPLNIADTL;

  PROCEDURE GET_ASSET_STATUS IS
   BEGIN
     -- Note: Few lines are commented here to Accrue on Latest Status.
     /* IF W_PROCESS_DATE = W_ASON_DATE
     THEN*/
     <<READASSET>>
      BEGIN
         SELECT ASSETCD_ASSET_CLASS,
                ASSETCLS_ASSET_CODE,
                ASSETCLS_NPA_DATE,
                ASSETCD_OD_INT_REQD
           INTO W_ASSETCD_ASSET_CLASS,
                W_ASSETCLS_ASSET_CODE,
                W_ASSETCLS_NPA_DATE,
                W_NPA_OD_INT_REQD
           FROM ASSETCLS, ASSETCD
          WHERE     ASSETCLS_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND ASSETCLS_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND ASSETCLS_ASSET_CODE = ASSETCD_CODE;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_ASSETCD_ASSET_CLASS := '';
            W_ASSETCLS_ASSET_CODE := '';
            W_ASSETCLS_NPA_DATE := NULL;
      END READASSET;
   /* ELSE
     <<READASSETHIST>>
      BEGIN
           --11-01-2010-added ASSETCD_OD_INT_REQD
         SELECT CA.ASSETCD_ASSET_CLASS,
                A.ASSETCLSH_ASSET_CODE,
                A.ASSETCLSH_NPA_DATE,
                CA.ASSETCD_OD_INT_REQD
           INTO W_ASSETCD_ASSET_CLASS,
                W_ASSETCLS_ASSET_CODE,
                W_ASSETCLS_NPA_DATE,
                W_NPA_OD_INT_REQD
           FROM ASSETCLSHIST A, ASSETCD CA
          WHERE     ASSETCLSH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND A.ASSETCLSH_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND A.ASSETCLSH_ASSET_CODE = ASSETCD_CODE
                AND A.ASSETCLSH_EFF_DATE =
                       (SELECT MAX (AA.ASSETCLSH_EFF_DATE)
                          FROM ASSETCLSHIST AA
                         WHERE     ASSETCLSH_ENTITY_NUM =
                                      V_GLOB_ENTITY_NUM
                               AND AA.ASSETCLSH_INTERNAL_ACNUM =
                                      W_INTERNAL_ACNUM
                               AND AA.ASSETCLSH_EFF_DATE <= W_PROCESS_DATE);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_ASSETCD_ASSET_CLASS := '';
            W_ASSETCLS_ASSET_CODE := '';
            W_ASSETCLS_NPA_DATE := NULL;
      END READASSETHIST;
   END IF;*/
   END GET_ASSET_STATUS;

  PROCEDURE PROCESS_FOR_ASONSUSPBAL IS
      W_SUSP_ERR_MSG     VARCHAR2 (100);
      W_DUMMY_BAL        NUMBER (18, 3);
      W_DUMMY_SUSP_BAL   NUMBER (18, 3);
      W_DUMMY_DATE       VARCHAR2 (10);
   BEGIN
      W_DUMMY_BAL := 0;
      W_DUMMY_SUSP_BAL := 0;
      W_DUMMY_DATE := TO_CHAR (W_PROCESS_DATE, 'DD-MM-YYYY');
      PKG_LNSUSPASON.SP_LNSUSPASON (V_GLOB_ENTITY_NUM,
                                    W_INTERNAL_ACNUM,
                                    W_ACNTS_CURR_CODE,
                                    W_DUMMY_DATE,
                                    W_SUSP_ERR_MSG,
                                    W_DUMMY_BAL,
                                    W_DUMMY_BAL,
                                    W_DUMMY_SUSP_BAL,
                                    W_DUMMY_BAL,
                                    W_DUMMY_BAL,
                                    W_DUMMY_BAL,
                                    W_DUMMY_BAL,
                                    W_DUMMY_BAL,
                                    W_DUMMY_BAL,
                                    W_DUMMY_BAL,
                                    W_DUMMY_BAL);

    IF TRIM(W_SUSP_ERR_MSG) IS NOT NULL THEN
      W_ERR_MSG := 'Error in Loan Suspense balance Calculation ' ||
                   FACNO(V_GLOB_ENTITY_NUM, W_INTERNAL_ACNUM);
         RAISE E_USEREXCEP;
      END IF;

      W_SUSPENSE_BAL := NVL (W_DUMMY_SUSP_BAL, 0);
   END PROCESS_FOR_ASONSUSPBAL;

  PROCEDURE CHECK_GRACE_PERIOD(W_PROC_DATE IN DATE, W_GRACE_DAYS IN NUMBER) IS
      W_GRACE_OD_INT      NUMBER (18, 3);
      W_ERROR_MSG         VARCHAR2 (100);
      W_GRACE_FROM_DATE   DATE;
      P_TOT_PRIN_DB_AC    NUMBER (18, 3);
      P_TOT_PRIN_CR_AC    NUMBER (18, 3);
      P_TOT_PRIN_DB_BC    NUMBER (18, 3);
      P_TOT_PRIN_CR_BC    NUMBER (18, 3);
      P_TOT_INT_DB_AC     NUMBER (18, 3);
      P_TOT_INT_CR_AC     NUMBER (18, 3);
      P_TOT_INT_DB_BC     NUMBER (18, 3);
      P_TOT_INT_CR_BC     NUMBER (18, 3);
      P_TOT_CHG_DB_AC     NUMBER (18, 3);
      P_TOT_CHG_CR_AC     NUMBER (18, 3);
      P_TOT_CHG_DB_BC     NUMBER (18, 3);
      P_TOT_CHG_CR_BC     NUMBER (18, 3);

      W_SUSP_NON_OD_INT   NUMBER (18, 3);
   BEGIN
      P_TOT_PRIN_DB_AC := 0;
      P_TOT_PRIN_CR_AC := 0;
      P_TOT_PRIN_DB_BC := 0;
      P_TOT_PRIN_CR_BC := 0;
      P_TOT_INT_DB_AC := 0;
      P_TOT_INT_CR_AC := 0;
      P_TOT_INT_DB_BC := 0;
      P_TOT_INT_CR_BC := 0;
      P_TOT_CHG_DB_AC := 0;
      P_TOT_CHG_CR_AC := 0;
      P_TOT_CHG_DB_BC := 0;
      P_TOT_CHG_CR_BC := 0;

      W_GRACE_OD_INT := 0;
      W_GRACE_FROM_DATE := NULL;
      --  W_GRACE_FROM_DATE := (W_PROCESS_DATE - W_GRACE_DAYS + 1); Rem Guna 08/06/2010
      W_GRACE_FROM_DATE := (W_PROCESS_DATE - W_GRACE_DAYS);

     <<CHECK_LNTRANSUM>>
      BEGIN
         SP_LNTRANSUM (V_GLOB_ENTITY_NUM,
                       W_INTERNAL_ACNUM,
                       NULL,
                       W_ASON_DATE,
                       W_GRACE_FROM_DATE,
                       W_PROC_DATE,
                       W_ERROR_MSG,
                       P_TOT_PRIN_DB_AC,
                       P_TOT_PRIN_CR_AC,
                       P_TOT_PRIN_DB_BC,
                       P_TOT_PRIN_CR_BC,
                       P_TOT_INT_DB_AC,
                       P_TOT_INT_CR_AC,
                       P_TOT_INT_DB_BC,
                       P_TOT_INT_CR_BC,
                       P_TOT_CHG_DB_AC,
                       P_TOT_CHG_CR_AC,
                       P_TOT_CHG_DB_BC,
                       P_TOT_CHG_CR_BC);
      EXCEPTION
      WHEN OTHERS THEN
            P_TOT_PRIN_DB_AC := 0;
            P_TOT_PRIN_CR_AC := 0;
            P_TOT_PRIN_DB_BC := 0;
            P_TOT_PRIN_CR_BC := 0;
            P_TOT_INT_DB_AC := 0;
            P_TOT_INT_CR_AC := 0;
            P_TOT_INT_DB_BC := 0;
            P_TOT_INT_CR_BC := 0;
            P_TOT_CHG_DB_AC := 0;
            P_TOT_CHG_CR_AC := 0;
            P_TOT_CHG_DB_BC := 0;
            P_TOT_CHG_CR_BC := 0;
      END CHECK_LNTRANSUM;

      P_TOT_INT_DB_AC := -1 * ABS (P_TOT_INT_DB_AC);

    IF P_TOT_INT_DB_AC <> 0 THEN
      IF ABS(W_OD_AMT) > ABS(P_TOT_INT_DB_AC) THEN
            --07-05-2010-rem        W_OD_AMT := W_OD_AMT - ABS(P_TOT_INT_DB_AC);
            -- w_od_amt always in - sign
            W_OD_AMT := W_OD_AMT + ABS (P_TOT_INT_DB_AC);
         ELSE
            W_OD_AMT := 0;
         END IF;
      END IF;

      --07-05-2010-beg
    IF W_NPA_STATUS = '1' THEN
        <<CHECK_NPA_NON_OD_INT>>
         BEGIN
            W_SUSP_NON_OD_INT := 0;

            SELECT NVL (SUM (LNSUSP_INT_AMT), 0) -- R.Senthil Kumar - 02-July-2010 - Modified
              INTO W_SUSP_NON_OD_INT
              FROM LNSUSPLED
             WHERE     LNSUSP_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND LNSUSP_ACNT_NUM = W_INTERNAL_ACNUM
                   AND LNSUSP_VALUE_DATE >= W_GRACE_FROM_DATE
                   AND LNSUSP_VALUE_DATE <= W_PROC_DATE
                   AND LNSUSP_DB_CR_FLG = 'D';

        IF ABS(W_OD_AMT) >= ABS(W_SUSP_NON_OD_INT) THEN
               -- w_od_amt always in - sign
               W_OD_AMT := W_OD_AMT + ABS (W_SUSP_NON_OD_INT);
            ELSE
               W_OD_AMT := 0;
            END IF;
         END CHECK_NPA_NON_OD_INT;
      END IF;
   --07-05-2010-end
   END CHECK_GRACE_PERIOD;

   --26-06-2009-end

   --21-oct-2009-beg
  FUNCTION READ_LOAN_PRIN_OD_AMT RETURN NUMBER IS
   BEGIN
      W_PRIN_OD_AMT := 0;

     <<READLNODHIST>>
      BEGIN
         SELECT NVL (L.LNODHIST_PRIN_OD_AMT, 0)
           INTO W_PRIN_OD_AMT
           FROM LNODHIST L
          WHERE     LNODHIST_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND L.LNODHIST_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND L.LNODHIST_EFF_DATE =
                       (SELECT MAX (LL.LNODHIST_EFF_DATE)
                          FROM LNODHIST LL
                         WHERE     LNODHIST_ENTITY_NUM = V_GLOB_ENTITY_NUM
                 AND LL.LNODHIST_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                               AND LL.LNODHIST_EFF_DATE <= W_PROCESS_DATE);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_PRIN_OD_AMT := 0;
      END READLNODHIST;

      RETURN W_PRIN_OD_AMT;
   END READ_LOAN_PRIN_OD_AMT;

   --21-oct-2009-end

  PROCEDURE GET_NPA_BAL IS
   BEGIN
    IF W_PROCESS_DATE = W_ASON_DATE THEN
        <<READSUSPBAL>>
         BEGIN
            SELECT LNSUSPBAL_SUSP_BAL
              INTO W_SUSPENSE_BAL
              FROM LNSUSPBAL L
             WHERE     LNSUSPBAL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND L.LNSUSPBAL_ACNT_NUM = W_INTERNAL_ACNUM
                   AND L.LNSUSPBAL_CURR_CODE = W_ACNTS_CURR_CODE;
         EXCEPTION
        WHEN NO_DATA_FOUND THEN
               W_SUSPENSE_BAL := 0;
         END READSUSPBAL;
      ELSE
         PROCESS_FOR_ASONSUSPBAL;
      END IF;
   END GET_NPA_BAL;

  PROCEDURE GET_NPA_AMOUNT IS
   BEGIN
      W_NPA_STATUS := 0;

    IF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
     .PRODUCT_EXEMPT_FROM_NPA <> '1' THEN
         --Note: Retrieve the Asset Related info for once.
         --GET_ASSET_STATUS;
         W_ASSETCD_ASSET_CLASS := T_ACNTS (V_CTR).ASSETCD_ASSET_CLASS;
         W_ASSETCLS_ASSET_CODE := T_ACNTS (V_CTR).ASSETCLS_ASSET_CODE;
         W_ASSETCLS_NPA_DATE := T_ACNTS (V_CTR).ASSETCLS_NPA_DATE;
         W_NPA_OD_INT_REQD := T_ACNTS (V_CTR).ASSETCD_OD_INT_REQD;

      IF W_ASSETCD_ASSET_CLASS = 'N' THEN
            W_NPA_STATUS := 1;
         END IF;
      END IF;
   END GET_NPA_AMOUNT;

   PROCEDURE GET_INSTALL_NOT_DUE_AMT (V_ENTITY_NUM            IN     NUMBER,
                                      W_INSTALL_GRACE_DATE    IN     DATE,
                                    W_INSTALL_NOT_OVERDUE IN OUT NUMBER) AS
      W_INST_PROC_DATE   DATE;
      W_CHK_NOI          NUMBER (5);
   BEGIN
        SELECT LNACRSDTL_REPAY_FROM_DATE,
               LNACRSDTL_NUM_OF_INSTALLMENT,
               LNACRSDTL_REPAY_AMT,
           LNACRSDTL_REPAY_FREQ BULK COLLECT
      INTO V_LN_LNACRSDTL
          FROM LNACRSDTL
         WHERE     LNACRSDTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
               AND LNACRSDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
      ORDER BY LNACRSDTL_SL_NUM;

    IF V_LN_LNACRSDTL.FIRST IS NOT NULL THEN
      FOR IDX IN V_LN_LNACRSDTL.FIRST .. V_LN_LNACRSDTL.LAST LOOP
            W_INST_PROC_DATE := V_LN_LNACRSDTL (IDX).V_REPAY_FROM_DATE;
            W_CHK_NOI := 1;

        WHILE (W_INST_PROC_DATE <= W_PROCESS_DATE) LOOP
               --12-08-2010-rem          IF (W_INST_PROC_DATE > W_INSTALL_GRACE_DATE) THEN
          IF (W_INST_PROC_DATE >= W_INSTALL_GRACE_DATE) THEN
            W_INSTALL_NOT_OVERDUE := W_INSTALL_NOT_OVERDUE + V_LN_LNACRSDTL(IDX)
                                    .V_REPAY_AMT;
            --07-08-2010-beg
            W_GRACE_DAYS := NVL(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
                                .LNPRD_PENALTY_GRACE_DAYS,
                        0);
                  INSERT_RTMPLNNOTDUE (W_INTERNAL_ACNUM,
                                       W_INST_PROC_DATE + W_GRACE_DAYS,
                                       V_LN_LNACRSDTL (IDX).V_REPAY_AMT,
                                       W_INST_PROC_DATE,
                                       2);
               END IF;

               W_CHK_NOI := W_CHK_NOI + 1;

          IF (W_CHK_NOI > V_LN_LNACRSDTL(IDX).V_NUM_OF_INSTALLMENT) THEN
                  EXIT;
               END IF;

          IF (V_LN_LNACRSDTL(IDX).V_REPAY_FREQ = 'X') THEN
                  EXIT;
               END IF;

          IF (V_LN_LNACRSDTL(IDX).V_REPAY_FREQ = 'M') THEN
                  W_INST_PROC_DATE := ADD_MONTHS (W_INST_PROC_DATE, 1);
          ELSIF (V_LN_LNACRSDTL(IDX).V_REPAY_FREQ = 'Q') THEN
                  W_INST_PROC_DATE := ADD_MONTHS (W_INST_PROC_DATE, 3);
          ELSIF (V_LN_LNACRSDTL(IDX).V_REPAY_FREQ = 'H') THEN
                  W_INST_PROC_DATE := ADD_MONTHS (W_INST_PROC_DATE, 6);
          ELSIF (V_LN_LNACRSDTL(IDX).V_REPAY_FREQ = 'Y') THEN
                  W_INST_PROC_DATE := ADD_MONTHS (W_INST_PROC_DATE, 12);
               END IF;
            END LOOP;
         END LOOP;
      END IF;
   END GET_INSTALL_NOT_DUE_AMT;

  PROCEDURE CHECK_INSTALLMENT_GRACE_PERIOD(V_ENTITY_NUM               IN NUMBER,
                                           V_LNPRD_PENALTY_GRACE_DAYS NUMBER) AS
      W_INSTALL_GRACE_DATE    DATE := NULL;
      W_INSTALL_NOT_OVERDUE   NUMBER (18, 3) := 0;
   BEGIN
      W_INSTALL_GRACE_DATE := W_PROCESS_DATE - V_LNPRD_PENALTY_GRACE_DAYS;
      W_INSTALL_NOT_OVERDUE := 0;

      GET_INSTALL_NOT_DUE_AMT (V_GLOB_ENTITY_NUM,
                               W_INSTALL_GRACE_DATE,
                               W_INSTALL_NOT_OVERDUE);

    IF (ABS(W_OD_AMT) > W_INSTALL_NOT_OVERDUE) THEN
         W_OD_AMT := (ABS (W_OD_AMT) - W_INSTALL_NOT_OVERDUE) * (-1);
      ELSE
         W_OD_AMT := 0;
      END IF;
   EXCEPTION
    WHEN OTHERS THEN
      W_ERR_MSG := 'Error in CHECK_INSTALLMENT_GRACE_PERIOD ' ||
                   FACNO(V_GLOB_ENTITY_NUM, W_INTERNAL_ACNUM) ||
                   SUBSTR(SQLERRM, 1, 900);
         RAISE E_USEREXCEP;
   END CHECK_INSTALLMENT_GRACE_PERIOD;

   /* remove by rajib.pradhan as on May-2016

   PROCEDURE INSERT_RTMPLNNOTDUE(ACNUM           IN NUMBER,
                                 GRACE_DUE_DATE  IN DATE,
                                 AMOUNT          IN NUMBER,
                                 ACTUAL_DUE_DATE DATE,
                                 ENTRY_TYPE      VARCHAR2) IS
   BEGIN
     INSERT INTO RTMPLNNOTDUE
       (RTMPLNND_INTERNAL_ACNUM,
        RTMPLNND_GRACE_END_DATE,
        RTMPLNND_NOT_DUE_AMT,
        RTMPLNND_ENTRY_TYPE,
        RTMPLNND_ACTUAL_DUE_DATE,
        RTMPLNND_FINAL_DUE_AMT)
     VALUES
       (ACNUM, GRACE_DUE_DATE, AMOUNT, ENTRY_TYPE, ACTUAL_DUE_DATE, 0);
   END INSERT_RTMPLNNOTDUE;

   */

   PROCEDURE INSERT_RTMPLNNOTDUE (ACNUM             IN NUMBER,
                                  GRACE_DUE_DATE    IN DATE,
                                  AMOUNT            IN NUMBER,
                                  ACTUAL_DUE_DATE      DATE,
                                  ENTRY_TYPE           VARCHAR2)
   IS
   BEGIN
      W_INDEX_NUMBER := W_INDEX_NUMBER + 1;

      T_RTMPLNND_INTERNAL_ACNUM (W_INDEX_NUMBER) := ACNUM;
      T_RTMPLNND_GRACE_END_DATE (W_INDEX_NUMBER) := GRACE_DUE_DATE;
      T_RTMPLNND_NOT_DUE_AMT (W_INDEX_NUMBER) := AMOUNT;
      T_RTMPLNND_ENTRY_TYPE (W_INDEX_NUMBER) := ENTRY_TYPE;
      T_RTMPLNND_ACTUAL_DUE_DATE (W_INDEX_NUMBER) := ACTUAL_DUE_DATE;
      T_RTMPLNND_FINAL_DUE_AMT (W_INDEX_NUMBER) := 0;
   END INSERT_RTMPLNNOTDUE;

  PROCEDURE TRANADV_PROC IS
      J                 NUMBER (6);
      W_SQL_IND         VARCHAR2 (4000);
      W_INTRD_BC_AMT    NUMBER (18, 3);
      W_CHARGE_BC_AMT   NUMBER (18, 3);
      W_INT_IGN         VARCHAR2 (1);
      W_DB_CR_FLG       VARCHAR2 (1);
      W_DATE_OF_TRAN    DATE;
   BEGIN
     <<READLNINTAPPL>>
      BEGIN
      W_SQL_IND := 'SELECT TRANADV_INTRD_BC_AMT, TRANADV_CHARGE_BC_AMT,TRAN_DB_CR_FLG,TRAN_DATE_OF_TRAN FROM TEMP_LOAN_OVERDUE
        WHERE VALUE_YEAR=:1 AND TRAN_INTERNAL_ACNUM=:2 AND TRAN_DATE_OF_TRAN <=:3  AND TRAN_DATE_OF_TRAN >=:4';

      EXECUTE IMMEDIATE W_SQL_IND BULK COLLECT
        INTO TRAN_REC
        USING W_PROC_YEAR, W_INTERNAL_ACNUM, W_PROCESS_DATE, W_MIN_PROC_DATE;

         --      W_SQL_IND := 'SELECT TRANADV_INTRD_BC_AMT, TRANADV_CHARGE_BC_AMT,TRAN_DB_CR_FLG,TRAN_DATE_OF_TRAN FROM TRANADV' ||
         --                   W_PROC_YEAR || ', TRAN' || W_PROC_YEAR ||
         --                   ' WHERE TRAN_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND TRANADV_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND
         --                 TRAN_DATE_OF_TRAN <= ' || CHR(39) ||
         --                   W_PROCESS_DATE || CHR(39) ||
         --                   ' AND TRAN_DATE_OF_TRAN >= ' || CHR(39) ||
         --                   W_MIN_PROC_DATE || CHR(39) ||
         --                   ' AND TRAN_INTERNAL_ACNUM = ' || W_INTERNAL_ACNUM ||
         --                   ' AND TRAN_AUTH_ON IS NOT NULL AND
         --                 TRANADV_BRN_CODE = TRAN_BRN_CODE AND TRANADV_DATE_OF_TRAN = TRAN_DATE_OF_TRAN AND TRAN_DB_CR_FLG =''D'' AND TRANADV_INTRD_AC_AMT <> 0 AND
         --                 TRANADV_BATCH_NUMBER = TRAN_BATCH_NUMBER AND TRANADV_BATCH_SL_NUM = TRAN_BATCH_SL_NUM ORDER BY TRAN_DATE_OF_TRAN DESC,TRAN_AUTH_ON DESC';
         --
         --      EXECUTE IMMEDIATE W_SQL_IND BULK COLLECT
         --        INTO TRAN_REC;

         J := 0;

      IF TRAN_REC.FIRST IS NOT NULL THEN
        FOR J IN TRAN_REC.FIRST .. TRAN_REC.LAST LOOP
          W_GRACE_DAYS := NVL(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
                              .LNPRD_INT_RECOV_GRACE_DAYS,
                     0);
          INSERT_RTMPLNNOTDUE(W_INTERNAL_ACNUM,
                              TRAN_REC        (J)
                              .V_DATE_OF_TRAN + W_GRACE_DAYS,
                  TRAN_REC (J).V_INTRD_BC_AMT,
                  TRAN_REC (J).V_DATE_OF_TRAN,
                  '1');
            END LOOP;
         END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            NULL;
      END READLNINTAPPL;
   END TRANADV_PROC;

   -- NEELS-MDS-08-NOV-2010 BEG
  PROCEDURE GET_PENDING_AMOUNT IS
   BEGIN
      W_PENDING_AMOUNT := 0;

      SELECT NVL (SUM (LP.LNINTP_TOBE_REC), 0)
        INTO W_PENDING_AMOUNT
        FROM LNINTPEND LP
       WHERE     LP.LNINTP_ENTITY_NUMBER = V_GLOB_ENTITY_NUM
             AND LP.LNINTP_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
   END GET_PENDING_AMOUNT;

   -- NEELS-MDS-08-NOV-2010 END

  PROCEDURE PROCESS_FOR_GRACE_EXECUTION IS
      IND   NUMBER (6);
   BEGIN
      --DELETE FROM RTMPLNNOTDUE; -- GLOBAL TEMP TABLE

      SP_CLEAR_RTMPLNNOTDUE;

      W_GRACE_DAYS := 0;
    W_GRACE_DAYS    := NVL(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
                           .LNPRD_INT_RECOV_GRACE_DAYS,
            0);
    W_MIN_PROC_DATE := W_PROCESS_DATE - NVL(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
                                            .LNPRD_INT_RECOV_GRACE_DAYS,
              0);
      IND := 0;
    W_PROC_YEAR     := PKG_PB_GLOBAL_EOD_SOD.FN_GETFINYEAR(V_GLOB_ENTITY_NUM, W_MIN_PROC_DATE);
    W_UPTO_YEAR     := PKG_PB_GLOBAL_EOD_SOD.FN_GETFINYEAR(V_GLOB_ENTITY_NUM, W_PROCESS_DATE);

    WHILE (W_PROC_YEAR <= W_UPTO_YEAR) LOOP
         -- REMOVE BY RAJIB NO NEED TO ACCESS THIS FUNCTION
         --      IF SP_TABLEAVAIL(V_GLOB_ENTITY_NUM,
         --                       'TRANADV' || W_PROC_YEAR) = 1 THEN
         --        TRANADV_PROC;
         --      END IF;

         TRANADV_PROC;

         W_PROC_YEAR := W_PROC_YEAR + 1;
      END LOOP;

     <<READSUSPLED>>
      BEGIN
      FOR IDX IN (SELECT *
                  FROM LNSUSPLED C
                 WHERE     C.LNSUSP_ENTITY_NUM = V_GLOB_ENTITY_NUM
                       AND C.LNSUSP_ACNT_NUM = W_INTERNAL_ACNUM
                       AND C.LNSUSP_VALUE_DATE >= W_MIN_PROC_DATE
                       AND C.LNSUSP_VALUE_DATE <= W_PROCESS_DATE
                       AND C.LNSUSP_DB_CR_FLG = 'D'
                       AND C.LNSUSP_AUTO_MANUAL = 'A'
                     AND C.LNSUSP_ENTRY_TYPE = '2') LOOP
            INSERT_RTMPLNNOTDUE (W_INTERNAL_ACNUM,
                                 IDX.LNSUSP_VALUE_DATE + W_GRACE_DAYS,
                                 IDX.LNSUSP_INT_AMT,
                                 IDX.LNSUSP_VALUE_DATE,
                                 '1');
         END LOOP;
      END READSUSPLED;
   END PROCESS_FOR_GRACE_EXECUTION;

   PROCEDURE PROCESS_FOR_TRANSACTION
   IS
      V_LNACNT_ENTD_ON         DATE;
      V_LN_OVERDUE_FROM_DATE   DATE;
      V_GRACE_END_DATE         DATE;
      V_GRACE_PRD_CHK_REQ      CHAR (1);
      V_GRACE_PRD_ACCR_ALLOW   CHAR (1);
      V_TEMP_INTEREST_AMT      NUMBER (18, 3);
   BEGIN
      W_INT_ON_RECOVERY := FALSE;
      V_LN_OVERDUE_FROM_DATE := T_ACNTS (V_CTR).LN_OVERDUE_FROM_DATE;

    IF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
     .LNPRD_INT_APPL_FREQ = 'I' THEN
         W_INT_ON_RECOVERY := TRUE;
      END IF;

      -- Note: Retrieve Asset Related Information.
      -- Note: To Get the NPA Status From This Position. (Now disable)
      GET_NPA_AMOUNT;

    IF W_INT_ACCR_UPTO_DATE IS NULL THEN
         W_PROCESS_DATE := T_ACNTS (V_CTR).ACNTS_OPENING_DATE;
      ELSE
         W_PROCESS_DATE := W_INT_ACCR_UPTO_DATE + 1;
      END IF;

    IF W_PROCESS_DATE<V_MIG_END_DATE THEN
         W_PROCESS_DATE := V_MIG_END_DATE + 1;
      END IF;

      V_LNACNT_ENTD_ON := T_ACNTS (V_CTR).LNACNT_ENTD_ON;

      IF V_LNACNT_ENTD_ON IS NOT NULL
      THEN
         IF V_LNACNT_ENTD_ON > W_PROCESS_DATE
         THEN
            W_PROCESS_DATE := V_LNACNT_ENTD_ON;
         END IF;
      END IF;

      -- Note: Compare The Max value Date From LOANIAMRR Table with Process Date
      IF     (W_LOANIAMRR_MAX_VALUE_DATE IS NOT NULL)
         AND W_LOANIAMRR_MAX_VALUE_DATE >= W_PROCESS_DATE
      THEN
         W_PROCESS_DATE := W_LOANIAMRR_MAX_VALUE_DATE + 1;
      END IF;

      /*
      IF (W_MIN_VAUE_DATE IS NOT NULL) AND W_MIN_VAUE_DATE < W_PROCESS_DATE THEN
        W_PROCESS_DATE := W_MIN_VAUE_DATE;
      END IF;
      */

      V_GRACE_END_DATE := T_ACNTS (V_CTR).LNACDTL_GRACE_END_DATE;
    V_GRACE_PRD_CHK_REQ := V_LN_LNPRODPM(W_ACNTS_PROD_CODE).LNPRD_GRACE_PRD_CHK_REQ;
    V_GRACE_PRD_ACCR_ALLOW := V_LN_LNPRODPM(W_ACNTS_PROD_CODE).LNPRD_GRACE_PRD_ACCR_ALLOW;

    IF V_GRACE_PRD_CHK_REQ = '1' AND V_GRACE_PRD_ACCR_ALLOW <> '1' AND (V_GRACE_END_DATE IS NOT NULL) AND V_GRACE_END_DATE > W_ASON_DATE THEN
         W_PROCESS_DATE := V_GRACE_END_DATE + 1;
      END IF;



      IF     T_ACNTS (V_CTR).LNACNT_RTMP_PROCESS_DATE IS NOT NULL
         AND TO_CHAR (T_ACNTS (V_CTR).LNACNT_RTMP_PROCESS_DATE, 'MON-YYYY') =
                TO_CHAR (W_ASON_DATE, 'MON-YYYY')
         AND T_ACNTS (V_CTR).LNACNT_RTMP_ACCURED_UPTO >= W_PROCESS_DATE
      THEN
         W_PROCESS_DATE := T_ACNTS (V_CTR).LNACNT_RTMP_ACCURED_UPTO + 1;
      END IF;


      -- Start: Added For Short Term Loan Customization
    IF W_SHORT_TERM_LOAN = '1' THEN
         W_CAL_INT_AMT := 0;

         SELECT NVL (SUM (RTMPLNIA_INT_AMT_RND), 0)
           INTO V_TEMP_INTEREST_AMT
           FROM LOANIADLY
          WHERE     RTMPLNIA_ACNT_NUM = W_INTERNAL_ACNUM
                AND RTMPLNIA_BRN_CODE = W_PROC_BRN_CODE
                AND TO_CHAR (RTMPLNIA_ACCRUAL_DATE, 'MM-YYYY') =
                       TO_CHAR (W_CBD, 'MM-YYYY')
                AND RTMPLNIA_INSERT_FROM IS NOT NULL;

         W_DISB_AMT := NVL (T_ACNTS (V_CTR).LNACDISB_DISB_AMT, 0);
         W_MIG_INT_AMT := NVL (T_ACNTS (V_CTR).MIG_INT_AMT, 0);
         W_APP_INT_AMT := NVL (T_ACNTS (V_CTR).APP_INT_AMT, 0);
         W_LNIA_MRR_INT_AMT := NVL (T_ACNTS (V_CTR).LNIA_MRR_INT_AMT, 0);

         W_CAL_INT_AMT :=
              ABS (NVL (W_MIG_INT_AMT, 0))
            + ABS (NVL (W_APP_INT_AMT, 0))
            + ABS (NVL (W_LNIA_MRR_INT_AMT, 0));
         W_CAL_INT_AMT := W_CAL_INT_AMT + V_TEMP_INTEREST_AMT;

      IF ((W_CAL_INT_AMT >= W_DISB_AMT ) AND (V_LN_LNPRODPM(W_ACNTS_PROD_CODE).PRODUCT_FOR_RUN_ACS <> '1')) THEN
            RETURN;
         END IF;
      END IF;

      -- END: Added For Short Term Loan Customization

      WW_FINYEAR_OB := NULL;
      WW_MONTH_OB := NULL;
      WW_MONTH_PREV_OB := NULL;


      WW_FINYEAR_OI := NULL;
      WW_MONTH_OI := NULL;
      WW_MONTH_PREV_OI := NULL;

     <<WLOOP>>
    WHILE W_PROCESS_DATE <= W_ASON_DATE LOOP
         W_VALUE_BALANCE := 0;
         V_BREAK_SL := 0;
         W_REDUCE_AMOUNT := 0;
         W_NPA_AMT := 0;
         W_SUSPENSE_BAL := 0;
         W_PENAL_FOR_OVERDUE := 0;
         W_OD_FOUND := '0';

      W_SIMPLE_COMP_INT := V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
                           .LNPRD_SIMPLE_COMP_INT;

      IF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
       .LNPRD_TERM_LOAN = '1' AND V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
         .LNPRD_EDUCATIONAL_LOAN = '1' THEN
            CHECK_HOLIDAY_PERIOD;
         END IF;

      IF W_SIMPLE_COMP_INT = 'S' THEN
            CHECK_EXPIRY;
         END IF;

         GET_VALUE_DATE_BALANCE (W_PROCESS_DATE);
         GET_INT_DEB_UPTO_DATE;

         W_INT_ON_AMT := W_VALUE_BALANCE + ABS (W_REDUCE_AMOUNT);
         W_VALUE_BALANCE := W_INT_ON_AMT;

         IF W_NPA_STATUS = 1
         THEN
            GET_NPA_BAL;        -- Note: Calling has changed based on business

            IF W_SIMPLE_COMP_INT = 'C'
            THEN
               W_VALUE_BALANCE := W_VALUE_BALANCE;
               W_NPA_AMT := W_SUSPENSE_BAL;
            END IF;
         END IF;

         W_PRIN_OD_AMT := 0;

      IF W_INT_ON_RECOVERY = TRUE THEN
        IF GET_OD_INTER_TYPE = 2 THEN
               W_PRIN_OD_AMT := READ_LOAN_PRIN_OD_AMT;
               W_VALUE_BALANCE := W_VALUE_BALANCE + ABS (W_PRIN_OD_AMT);
            END IF;
         END IF;

         IF W_INT_ON_RECOVERY = FALSE AND V_LN_OVERDUE_FROM_DATE IS NOT NULL
         THEN
            GET_OVERDUE_AMT;
         ELSE
            W_SANC_LIMIT := 0;
            W_DP_AMT := 0;
            W_OD_AMT := 0;
            W_OD_FOUND := '0';
            W_OD_DATE := NULL;
         END IF;

         --DELETE FROM RTMPLNNOTDUE; -- GLOBAL TEMP TABLE
         SP_CLEAR_RTMPLNNOTDUE;

      IF NVL(W_OD_AMT, 0) <> 0 THEN
        IF NVL(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
               .LNPRD_INT_RECOV_GRACE_DAYS,
               0) > 0 AND V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
          .LNPRD_INT_RECOVERY_OPTION = '1' AND V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
          .PRODUCT_FOR_RUN_ACS = '1' THEN
          CHECK_GRACE_PERIOD(W_PROCESS_DATE,
                             NVL(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
                                 .LNPRD_INT_RECOV_GRACE_DAYS,
                     0));
            END IF;

            PROCESS_FOR_GRACE_EXECUTION;
         END IF;

      IF (V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
         .PRODUCT_FOR_RUN_ACS <> '1' AND V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
         .LNPRD_PENAL_INT_APPLICABLE = '1' AND
          NVL(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
              .LNPRD_PENALTY_GRACE_DAYS,
              0) > 0) THEN
        CHECK_INSTALLMENT_GRACE_PERIOD(V_GLOB_ENTITY_NUM,
                                       V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
                                       .LNPRD_PENALTY_GRACE_DAYS);
         END IF;

      IF W_VALUE_BALANCE > 0 THEN
            W_VALUE_BALANCE := 0;
         END IF;

         CALC_INTEREST_AMT;


      IF W_SKIP_FLAG = TRUE THEN
            EXIT WLOOP;
         END IF;

         W_PROCESS_DATE := W_PROCESS_DATE + 1;
      END LOOP;
   END PROCESS_FOR_TRANSACTION;

  PROCEDURE CHECK_HOLIDAY_PERIOD IS
   BEGIN
      W_REPAY_START_DATE := NULL;

     <<READLNACRSDTL>>
      BEGIN
         SELECT LL.LNACRSHDTL_REPAY_FROM_DATE
           INTO W_REPAY_START_DATE
           FROM LNACRSHDTL LL
          WHERE     LNACRSHDTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND LL.LNACRSHDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                AND LL.LNACRSHDTL_EFF_DATE =
                       (SELECT MAX (LM.LNACRSHDTL_EFF_DATE)
                          FROM LNACRSHDTL LM
                         WHERE     LNACRSHDTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                 AND LM.LNACRSHDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                               AND LM.LNACRSHDTL_EFF_DATE <= W_PROCESS_DATE
                               AND LM.LNACRSHDTL_SL_NUM = 1)
                AND LL.LNACRSHDTL_SL_NUM = 1;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_REPAY_START_DATE := NULL;
      END READLNACRSDTL;

    IF (W_REPAY_START_DATE >= W_PROCESS_DATE) AND
       W_REPAY_START_DATE IS NOT NULL THEN
         W_SIMPLE_COMP_INT := 'S';
      END IF;
   END CHECK_HOLIDAY_PERIOD;

  PROCEDURE CHECK_EXPIRY IS
   BEGIN
      W_SIMP := NULL;
      W_LIMIT_EXPIRY_DATE := NULL;
      W_LIMIT_SANC_AMT := 0;
      W_FINAL_DUE_DATE := NULL;
      GET_LIMIT_EXPIRY;

    IF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
     .PRODUCT_FOR_RUN_ACS <> '1' THEN
         FETCH_REPAY_END_DATE;
      END IF;

      /*         IF ((W_LIMIT_EXPIRY_DATE IS NOT NULL AND (W_LIMIT_EXPIRY_DATE < W_PROCESS_DATE))
                  OR (W_FINAL_DUE_DATE IS NOT NULL AND (W_FINAL_DUE_DATE < W_PROCESS_DATE ))) THEN
                  W_SIMPLE_COMP_INT  := 'C';
               END IF;
      */
    IF W_FINAL_DUE_DATE IS NULL THEN
      IF ((W_LIMIT_EXPIRY_DATE IS NOT NULL) AND
         (W_LIMIT_EXPIRY_DATE < W_PROCESS_DATE)) THEN
            --Changed By Suganthi Begin for Calcualting Simple Interest for Overdue Accounts
            /*  IF  (NVL(V_LN_LNPRODPM(V_LN_ACNTROW(W_MAIN_INDEX)
                          .ACNTS_PROD_CODE)
            .LNPRD_INT_CAL_BYNDDUE_DATE,
            'C'))='C' THEN*/
            --   IF (V_LN_LNPRODPM(V_LN_ACNTROW(W_MAIN_INDEX).ACNTS_PROD_CODE)
            -- .INT_CAL_BYNDDUE_DATE ='C' OR (V_LN_LNPRODPM(V_LN_ACNTROW(W_MAIN_INDEX).ACNTS_PROD_CODE).INT_CAL_BYNDDUE_DATE is NULL THEN
            /*  IF((V_LN_LNPRODPM(V_LN_ACNTROW(W_MAIN_INDEX).ACNTS_PROD_CODE)
            .INT_CAL_BYNDDUE_DATE ='C' OR (V_LN_LNPRODPM(V_LN_ACNTROW(W_MAIN_INDEX).ACNTS_PROD_CODE)
            .INT_CAL_BYNDDUE_DATE IS NULL)) THEN*/

        IF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
         .INT_CAL_BYNDDUE_DATE = 'C' OR V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
           .INT_CAL_BYNDDUE_DATE IS NULL THEN
               W_SIMPLE_COMP_INT := 'C';
            ELSE
               W_SIMPLE_COMP_INT := 'S';
            END IF;
         --End
         END IF;
      END IF;

    IF W_FINAL_DUE_DATE IS NOT NULL THEN
      IF ((W_FINAL_DUE_DATE < W_PROCESS_DATE) AND
         (W_LIMIT_EXPIRY_DATE < W_PROCESS_DATE)) THEN
            --        W_SIMPLE_COMP_INT := 'C';
            --Changed By Suganthi Begin for Calcualting Simple Interest for Overdue Accounts
            /*   IF  (NVL(V_LN_LNPRODPM(V_LN_ACNTROW(W_MAIN_INDEX)
                          .ACNTS_PROD_CODE)
            .LNPRD_INT_CAL_BYNDDUE_DATE,
            'C'))='C' THEN*/

        W_SIMP := V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
                  .INT_CAL_BYNDDUE_DATE;

            --  dbms_output.put_line(V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
            --   .INT_CAL_BYNDDUE_DATE);
        IF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
         .INT_CAL_BYNDDUE_DATE = 'C' OR V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
           .INT_CAL_BYNDDUE_DATE IS NULL THEN
               W_SIMPLE_COMP_INT := 'C';
            ELSE
               W_SIMPLE_COMP_INT := 'S';
            END IF;
         --End
         END IF;
      END IF;
   END CHECK_EXPIRY;

  PROCEDURE GET_LIMIT_EXPIRY IS
   BEGIN
      W_LIMIT_EXPIRY_DATE := NULL;
      W_LIMIT_SANC_AMT := 0;

     <<GETLIMITLINE>>
      BEGIN
         SELECT L.LMTLINE_LIMIT_EXPIRY_DATE, NVL (L.LMTLINE_SANCTION_AMT, 0)
           INTO W_LIMIT_EXPIRY_DATE, W_LIMIT_SANC_AMT
           FROM ACASLLDTL A, LIMITLINE L
          WHERE     LMTLINE_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND ACASLLDTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND L.LMTLINE_CLIENT_CODE = A.ACASLLDTL_CLIENT_NUM
                AND L.LMTLINE_NUM = A.ACASLLDTL_LIMIT_LINE_NUM
                AND A.ACASLLDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            W_LIMIT_EXPIRY_DATE := NULL;
            W_LIMIT_SANC_AMT := 0;
      END GETLIMITLINE;
   END GET_LIMIT_EXPIRY;

  PROCEDURE FETCH_REPAY_END_DATE IS
      W_LAT_EFF_DATE      DATE;
      W_NOOF_INSTALLEMT   NUMBER (4);
      W_REPAY_DATE        DATE;
      W_MULTI_FREQ        NUMBER (2);
   BEGIN
      W_LAT_EFF_DATE := NULL;
      W_NOOF_INSTALLEMT := 0;
      W_REPAY_DATE := NULL;
      W_MULTI_FREQ := 0;

      W_FINAL_DUE_DATE := T_ACNTS (V_CTR).LN_FINAL_DUE_DATE;

    IF W_FINAL_DUE_DATE IS NULL THEN

         BEGIN
            SELECT FINAL_DUE_DATE
              INTO W_FINAL_DUE_DATE
              FROM TEMP_LOAN_FDUEDATE
      WHERE LNACRSH_EFF_DATE=(SELECT MAX(LNACRSH_EFF_DATE)
                             FROM TEMP_LOAN_FDUEDATE
                            WHERE     LNACRSH_EFF_DATE <= W_PROCESS_DATE
                              AND LNACRSHDTL_ENTITY_NUM=V_GLOB_ENTITY_NUM
                              AND LNACRSHDTL_INTERNAL_ACNUM=W_INTERNAL_ACNUM)
                   AND LNACRSHDTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND LNACRSHDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
               W_FINAL_DUE_DATE := NULL;
         END;
      END IF;
   /* remove by rajib.pradhan as on 09/08/2015
    SELECT MAX(LNACRSH_EFF_DATE)
      INTO W_LAT_EFF_DATE
      FROM LNACRSHIST L
     WHERE LNACRSH_ENTITY_NUM = V_GLOB_ENTITY_NUM
       AND L.LNACRSH_INTERNAL_ACNUM = W_INTERNAL_ACNUM
       AND L.LNACRSH_EFF_DATE <= W_PROCESS_DATE;

    IF W_LAT_EFF_DATE IS NOT NULL THEN
      FOR IDX IN (SELECT *
                    FROM LNACRSHDTL LL
                   WHERE LNACRSHDTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                     AND LL.LNACRSHDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                     AND LL.LNACRSHDTL_EFF_DATE = W_LAT_EFF_DATE
                   ORDER BY LL.LNACRSHDTL_SL_NUM) LOOP
        IF IDX.LNACRSHDTL_REPAY_FREQ = 'M' THEN
          W_MULTI_FREQ := 1;
        ELSIF IDX.LNACRSHDTL_REPAY_FREQ = 'Q' THEN
          W_MULTI_FREQ := 3;
        ELSIF IDX.LNACRSHDTL_REPAY_FREQ = 'H' THEN
          W_MULTI_FREQ := 6;
        ELSIF IDX.LNACRSHDTL_REPAY_FREQ = 'Y' THEN
          W_MULTI_FREQ := 12;
        ELSIF IDX.LNACRSHDTL_REPAY_FREQ = 'X' THEN
          W_MULTI_FREQ := 0;
        END IF;

        W_REPAY_DATE     := IDX.LNACRSHDTL_REPAY_FROM_DATE;
        W_FINAL_DUE_DATE := ADD_MONTHS(W_REPAY_DATE,
                                       (IDX.LNACRSHDTL_NUM_OF_INSTALLMENT - 1) *
                                       W_MULTI_FREQ);
      END LOOP;
    END IF;

     remove by rajib.pradhan as on 09/08/2015 */
   END FETCH_REPAY_END_DATE;

  PROCEDURE PROCESS_ACCOUNT IS
   BEGIN
     <<PROCESSINTEREST>>
      BEGIN
         -- READ_ACNTS_ROW; RAJIB ON 11/05/2014
         -- R.Senthil Kumar - 11-June-2010 - Begin
         W_IGNORE := '0';
         W_COUNT := 0;

         /* DISABLE BY RAJIB CAUSE ALREDY MINUS FROM FIRST QUERY
             <<CHECK_INT_DISABLED>>
             BEGIN
               SELECT COUNT(0)
                 INTO W_COUNT
                 FROM LNACINTCTL
                WHERE LNACINTCTL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                  AND LNACINTCTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                  AND LNACINTCTL_INT_ACCRUAL_REQD <> '1';
               IF W_COUNT > 0 THEN
                 W_IGNORE := '1';
               END IF;
             END CHECK_INT_DISABLED;
         */
      IF W_IGNORE = '0' THEN
            -- R.Senthil Kumar - 11-June-2010 - End
            W_MAIN_INDEX := 1;

        IF T_ACNTS(V_CTR).ACNTS_INT_CALC_UPTO = W_CBD THEN
               INSERT INTO RTMPLNIA
                  (SELECT W_RUN_NUMBER,
                          RTMPLNIA_ACNT_NUM,
                          RTMPLNIA_VALUE_DATE,
                          RTMPLNIA_ACCRUAL_DATE,
                          RTMPLNIA_ACNT_CURR,
                          RTMPLNIA_ACNT_BAL,
                          RTMPLNIA_INT_ON_AMT,
                          RTMPLNIA_OD_PORTION,
                          RTMPLNIA_INT_RATE,
                          RTMPLNIA_SLAB_AMT,
                          RTMPLNIA_OD_INT_RATE,
                          RTMPLNIA_LIMIT,
                          RTMPLNIA_DP,
                          RTMPLNIA_INT_AMT,
                          RTMPLNIA_INT_AMT_RND,
                          RTMPLNIA_OD_INT_AMT,
                          RTMPLNIA_OD_INT_AMT_RND,
                          RTMPLNIA_NPA_STATUS,
                          RTMPLNIA_NPA_AMT,
                          RTMPLNIA_ARR_OD_INT_AMT,
                          RTMPLNIA_MAX_ACCRUAL_DATE,
                          RTMPLNIA_INSERT_FROM,
                          RTMPLNIA_BRN_CODE
                     FROM RTMPLNIA
                    WHERE     RTMPLNIA_RUN_NUMBER = W_LAP_RUN_NUMBER
                          AND RTMPLNIA_ACNT_NUM = W_INTERNAL_ACNUM);

               INSERT INTO RTMPLNIADTL
                  (SELECT W_RUN_NUMBER,
                          RTMPLNIADTL_ACNT_NUM,
                          RTMPLNIADTL_VALUE_DATE,
                          RTMPLNIADTL_ACCRUAL_DATE,
                          RTMPLNIADTL_SL_NUM,
                          RTMPLNIADTL_INT_RATE,
                          RTMPLNIADTL_UPTO_AMT,
                          RTMPLNIADTL_INT_AMT,
                          RTMPLNIADTL_INT_AMT_RND
                     FROM RTMPLNIADTL
                    WHERE     RTMPLNIADTL_RUN_NUMBER = W_LAP_RUN_NUMBER
                          AND RTMPLNIADTL_ACNT_NUM = W_INTERNAL_ACNUM);
            ELSE
               W_ACNTS_CURR_CODE := T_ACNTS (V_CTR).ACNTS_CURR_CODE;
               W_ACNTS_PROD_CODE := T_ACNTS (V_CTR).ACNTS_PROD_CODE;

               --SELECT LNPRD_INT_APPL_FREQ INTO V_INT_APPL_FREQ  FROM LNPRODPM WHERE LNPRD_PROD_CODE = W_ACNTS_PROD_CODE ;

          IF TRIM(T_ACNTS(V_CTR).ACNTS_SCHEME_CODE) IS NULL THEN
                  W_SCHEME_CODE := '000000';
               ELSE
                  --05-12-2007-added
            IF V_LN_LNPRODPM(T_ACNTS(V_CTR).ACNTS_PROD_CODE)
             .LNPRD_SCHEME_REQD = '1' THEN
              W_SCHEME_CODE := LPAD(TRIM(T_ACNTS(V_CTR).ACNTS_SCHEME_CODE),
                                    6,
                                    0);
                  ELSE
                     W_SCHEME_CODE := '000000';
                  END IF;
               END IF;

          W_PRODCODE_CURRCODE := LPAD(W_ACNTS_PROD_CODE, 4, 0) ||
                                 W_SCHEME_CODE || W_ACNTS_CURR_CODE;
               -- W_INT_ACCR_UPTO_DATE := GET_LOANACNTS_ACCR_DATE(W_INTERNAL_ACNUM);
               W_INT_ACCR_UPTO_DATE := T_ACNTS (V_CTR).LNACNT_INT_ACCR_UPTO;
               W_MIN_VAUE_DATE := T_ACNTS (V_CTR).TRAN_VAL_DATE;
               -- W_MIN_VAUE_DATE      := GET_MIN_VALUE_DATE(W_INTERNAL_ACNUM);
               W_SKIP_FLAG := FALSE;
               PROCESS_FOR_TRANSACTION;
            END IF;
         END IF;                     -- R.Senthil Kumar - 11-June-2010 - Added
      EXCEPTION
      WHEN OTHERS THEN
        IF TRIM(W_ERR_MSG) IS NULL THEN
               W_ERR_MSG := SUBSTR (SQLERRM, 1, 900);
            END IF;

        IF NVL(W_INTERNAL_ACNUM, 0) <> 0 THEN
          W_ERR_MSG := W_ERR_MSG || ' ' || ' Account Number - ' ||
                       FACNO(V_GLOB_ENTITY_NUM, W_INTERNAL_ACNUM);
            END IF;

            PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERR_MSG;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (V_GLOB_ENTITY_NUM,
                                         'E',
                                         W_ERR_MSG,
                                         ' ',
                                         0);
            RAISE;
      END PROCESSINTEREST;
   END PROCESS_ACCOUNT;

  PROCEDURE DELETE_TEMP_TABLE IS
   BEGIN
    DELETE FROM RTMPLNIA L WHERE L.RTMPLNIA_RUN_NUMBER = W_RUN_NUMBER;

      DELETE FROM RTMPLNIADTL LL
            WHERE LL.RTMPLNIADTL_RUN_NUMBER = W_RUN_NUMBER;

      DELETE FROM LOANCALCCTL LLL
            WHERE     LOANCTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                  AND LLL.LOANCTL_RUN_NUMBER = W_RUN_NUMBER;
   END DELETE_TEMP_TABLE;

  PROCEDURE GET_RUN_NUMBER IS
   BEGIN
     <<READNUM>>
      BEGIN
         SELECT GENRUNNUM.NEXTVAL INTO W_RUN_NUMBER FROM DUAL;
      END READNUM;

      /*
          <<DELETETEMPREC>>
          BEGIN
            DELETE_TEMP_TABLE;
          END DELETETEMPREC;
      */


      DELETE FROM LOANCALCCTL LLL
            WHERE     LOANCTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                  AND LLL.LOANCTL_RUN_NUMBER = W_RUN_NUMBER;

      INSERT INTO LOANCALCCTL L (LOANCTL_ENTITY_NUM,
                                 LOANCTL_RUN_NUMBER,
                                 LOANCTL_PROD_CODE,
                                 LOANCTL_INTERNAL_ACNUM,
                                 LOANCTL_RUN_DATE,
                                 LOANCTL_ACCRUAL_UPTO_DATE,
                                 LOANCTL_RUN_BY,
                                 LOANCTL_RUN_ON,
                                 LOANCTL_POSTED_BY,
                                 LOANCTL_POSTED_ON,
                                 LOANCTL_POSTED_TO_BATCH_NUM,
                                 LOANCTL_POSTED_TO_BRANCH)
           VALUES (V_GLOB_ENTITY_NUM,
                   W_RUN_NUMBER,
                   0,
                   W_INTERNAL_ACNUM,
                   W_ASON_DATE,
                   W_ASON_DATE,
                   PKG_EODSOD_FLAGS.PV_USER_ID,
                   SYSDATE,
                   ' ',
                   NULL,
                   0,
                   0);
   END GET_RUN_NUMBER;

   --Prasanth NS-CHN-07-10-2008-beg
   FUNCTION FN_READ_SODEODPROCRUN (L_PROCESS_NAME   IN VARCHAR2,
                                 L_PROCESS_DATE IN DATE) RETURN NUMBER IS
      L_RUN_NUMBER   NUMBER DEFAULT 0;
   BEGIN
     <<FETCH_SODEODPROCRUN>>
      BEGIN
         SELECT SODEODPROCRUN_RUN_NUMBER
           INTO L_RUN_NUMBER
           FROM SODEODPROCRUN
          WHERE     SODEODPROCRUN_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND SODEODPROCRUN_PACKAGE_NAME = L_PROCESS_NAME
                AND SODEODPROCRUN_DATE = L_PROCESS_DATE;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
            GET_RUN_NUMBER;
            L_RUN_NUMBER := W_RUN_NUMBER;

        INSERT INTO SODEODPROCRUN
          (SODEODPROCRUN_ENTITY_NUM,
                                       SODEODPROCRUN_PACKAGE_NAME,
                                       SODEODPROCRUN_DATE,
                                       SODEODPROCRUN_RUN_NUMBER)
        VALUES
          (V_GLOB_ENTITY_NUM, L_PROCESS_NAME, L_PROCESS_DATE, L_RUN_NUMBER);
      END FETCH_SODEODPROCRUN;

      W_LAP_RUN_NUMBER := L_RUN_NUMBER;
      RETURN L_RUN_NUMBER;
   END FN_READ_SODEODPROCRUN;

   --Prasanth NS-CHN-07-10-2008-end

  PROCEDURE SET_MIN_TRAN_DATA(P_TRAN_YEAR NUMBER) IS
      V_MIN_TRN_SQL   VARCHAR2 (3000);
      V_TRNFILT_SQL   VARCHAR2 (3000);
   BEGIN
      BEGIN
      V_TRNFILT_SQL := 'SELECT  P.PROC_INTERNAL_ACNUM, (CASE  WHEN DECODE(:W_IS_MIG_MONTH,''Y'',''D'',P.RAOPERPARAM_AMT_RESTRIC)=''D'' THEN :ASON_DATE ELSE SF_FORM_START_DATE(P.RAOPERPARAM_AMT_RESTRIC,:ENTITY_NUM,:ASON_DATE) END) TRN_FILTER_DATE
                              FROM PROCACNUM P';

      EXECUTE IMMEDIATE V_TRNFILT_SQL BULK COLLECT
        INTO T_TRAN_FILTER_DATE
        USING W_IS_MIG_MONTH, W_ASON_DATE, V_GLOB_ENTITY_NUM, W_ASON_DATE;

         FORALL IND IN T_TRAN_FILTER_DATE.FIRST .. T_TRAN_FILTER_DATE.LAST
            UPDATE PROCACNUM
           SET TRAN_FILTER_DATE = T_TRAN_FILTER_DATE(IND).TRAN_FILTER_DATE
         WHERE PROC_INTERNAL_ACNUM = T_TRAN_FILTER_DATE(IND)
              .TRAN_INTERNAL_ACNUM
                   AND PROCACNUM_ENTITY_NUM = V_GLOB_ENTITY_NUM;

         T_TRAN_FILTER_DATE.DELETE;
      EXCEPTION
      WHEN EX_DML_ERRORS THEN
            W_BULK_COUNT := SQL%BULK_EXCEPTIONS.COUNT;
            W_ERR_MSG := W_BULK_COUNT || ' ROWS FAILED IN INSERT PROCACNUM ';
        DBMS_OUTPUT.PUT_LINE(W_BULK_COUNT ||
                             ' ROWS FAILED IN INSERT PROCACNUM ');

        FOR I IN 1 .. W_BULK_COUNT LOOP
          DBMS_OUTPUT.PUT_LINE('Error: ' || I || ' Array Index: ' || SQL%BULK_EXCEPTIONS(I)
                               .ERROR_INDEX || ' Message: ' ||
                               SQLERRM(-SQL%BULK_EXCEPTIONS(I).ERROR_CODE));
            END LOOP;

            RAISE E_USEREXCEP;
      END;

      BEGIN
      V_MIN_TRN_SQL := 'SELECT TRAN_INTERNAL_ACNUM, MIN (TRAN_VALUE_DATE)
                                  FROM MV_LOAN_ACCOUNT_BAL T, PROCACNUM P
                                 WHERE  P.PROC_INTERNAL_ACNUM=T.TRAN_INTERNAL_ACNUM
                                       AND ACNTS_ENTITY_NUM = :1
                                           AND TRAN_DATE_OF_TRAN >= TRAN_FILTER_DATE
                                GROUP BY TRAN_INTERNAL_ACNUM';

      EXECUTE IMMEDIATE V_MIN_TRN_SQL BULK COLLECT
        INTO T_MIN_TRNDATE
            USING V_GLOB_ENTITY_NUM;

         FORALL IND IN T_MIN_TRNDATE.FIRST .. T_MIN_TRNDATE.LAST
            UPDATE PROCACNUM
               SET TRAN_VALUE_DT = T_MIN_TRNDATE (IND).TRAN_VAL_DATE
         WHERE PROC_INTERNAL_ACNUM = T_MIN_TRNDATE(IND).TRAN_INTERNAL_ACNUM;

         T_MIN_TRNDATE.DELETE;
      EXCEPTION
      WHEN OTHERS THEN
            W_ERR_MSG := 'Error in set minimum transaction date.';
            RAISE E_USEREXCEP;
      END;
   END;

  PROCEDURE SET_TRAN_BALANCE(P_TRAN_YEAR NUMBER) IS
      V_TRAN_BAL_SQL       VARCHAR2 (3000);
      W_FROM_DATE_BAL      DATE;
      V_SQL                VARCHAR2 (3000);

      TYPE REC_LN_OVERDUE_DATE IS RECORD
      (
         LNODHIST_ENTITY_NUM       TEMP_LNODHIST_DATA.LNODHIST_ENTITY_NUM%TYPE,
         LNODHIST_INTERNAL_ACNUM   TEMP_LNODHIST_DATA.LNODHIST_INTERNAL_ACNUM%TYPE,
         LNODHIST_EFF_DATE         TEMP_LNODHIST_DATA.LNODHIST_EFF_DATE%TYPE
      );

      TYPE TT_LN_OVERDUE_DATE IS TABLE OF REC_LN_OVERDUE_DATE
         INDEX BY PLS_INTEGER;

      T_LN_OVERDUE_DATE    TT_LN_OVERDUE_DATE;

      TYPE REC_LN_MIN_TRAN_DATE IS RECORD
      (
         PROC_INTERNAL_ACNUM   PROCACNUM.PROC_INTERNAL_ACNUM%TYPE,
         MIN_TRAN_VALUE_DATE   DATE
      );

      TYPE TT_LN_MIN_TRAN_DATE IS TABLE OF REC_LN_MIN_TRAN_DATE
         INDEX BY PLS_INTEGER;

      T_LN_MIN_TRAN_DATE   TT_LN_MIN_TRAN_DATE;
   BEGIN
      BEGIN
         V_SQL :=
            'SELECT P.PROC_INTERNAL_ACNUM,
               TRUNC (NVL (L.LNACNT_INT_ACCR_UPTO, A.ACNTS_OPENING_DATE), ''MM'')
                  INT_FROM_DATE
              FROM PROCACNUM P, LOANACNTS L, ACNTS A
             WHERE     P.PROCACNUM_ENTITY_NUM = A.ACNTS_ENTITY_NUM
                   AND P.PROC_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
                   AND P.PROC_INTERNAL_ACNUM = L.LNACNT_INTERNAL_ACNUM
                   AND P.PROCACNUM_ENTITY_NUM=L.LNACNT_ENTITY_NUM';

      EXECUTE IMMEDIATE V_SQL BULK COLLECT
        INTO T_INT_FROMDAT;

         FORALL IND IN T_INT_FROMDAT.FIRST .. T_INT_FROMDAT.LAST
            UPDATE PROCACNUM
               SET INT_FROM_DATE = T_INT_FROMDAT (IND).INT_FROM_DATE
         WHERE PROC_INTERNAL_ACNUM = T_INT_FROMDAT(IND).TRAN_INTERNAL_ACNUM;
      END;

      T_INT_FROMDAT.DELETE;

    W_FROM_DATE_BAL := W_ASON_DATE - TO_NUMBER(TO_CHAR(W_ASON_DATE, 'DD')) + 1;
    V_TRAN_BAL_SQL  := 'SELECT TO_NUMBER(TO_CHAR(TRAN_DATE_OF_TRAN,''YYYY'')) TRAN_YEAR, TRAN_INTERNAL_ACNUM,TRAN_VALUE_DATE, NVL (
          SUM (DECODE (TRAN_DB_CR_FLG, ''C'', TRAN_AMOUNT, 0))
          - SUM (DECODE (TRAN_DB_CR_FLG, ''D'', TRAN_AMOUNT, 0)),
          0)
          TRANBALANCE,
       NVL (
          SUM (DECODE (TRAN_DB_CR_FLG, ''C'', TRANADV_INTRD_AC_AMT, 0))
          - SUM (DECODE (TRAN_DB_CR_FLG, ''D'', TRANADV_INTRD_AC_AMT, 0)),
          0)
          TRANINTBALANCE,
       NVL (
          SUM (DECODE (TRAN_DB_CR_FLG, ''C'', TRANADV_CHARGE_BC_AMT, 0))
          - SUM (DECODE (TRAN_DB_CR_FLG, ''D'', TRANADV_CHARGE_BC_AMT, 0)),
          0)
          TRANCHGBALANCE
    FROM MV_LOAN_ACCOUNT_BAL T,PROCACNUM P
    WHERE  P.PROC_INTERNAL_ACNUM=T.TRAN_INTERNAL_ACNUM
       AND  T.ACNTS_ENTITY_NUM=P.PROCACNUM_ENTITY_NUM
       AND TRAN_VALUE_DATE >= P.INT_FROM_DATE
       AND T.ACNTS_ENTITY_NUM=:1
        AND TRAN_VALUE_DATE <= :2
        AND TRAN_DATE_OF_TRAN <= :3
    GROUP BY TO_NUMBER(TO_CHAR(TRAN_DATE_OF_TRAN,''YYYY'')),TRAN_INTERNAL_ACNUM,TRAN_VALUE_DATE';

    EXECUTE IMMEDIATE V_TRAN_BAL_SQL BULK COLLECT
      INTO T_TRAN_BALANCE
         USING V_GLOB_ENTITY_NUM, W_ASON_DATE, W_ASON_DATE;

      FORALL IND IN T_TRAN_BALANCE.FIRST .. T_TRAN_BALANCE.LAST
      INSERT INTO TEMP_LOAN_TRAN_BAL
        (VALUE_YEAR,
                                         TRAN_INTERNAL_ACNUM,
                                         TRAN_VALUE_DATE,
                                         TRANBALANCE,
                                         TRANINTBALANCE,
                                         TRANCHGBALANCE)
      VALUES
        (T_TRAN_BALANCE(IND).VALUE_YEAR,
                      T_TRAN_BALANCE (IND).TRAN_INTERNAL_ACNUM,
                      T_TRAN_BALANCE (IND).TRAN_VALUE_DATE,
                      T_TRAN_BALANCE (IND).TRANBALANCE,
                      T_TRAN_BALANCE (IND).TRANINTBALANCE,
                      T_TRAN_BALANCE (IND).TRANCHGBALANCE);

      T_TRAN_BALANCE.DELETE;

      BEGIN
        V_SQL :='SELECT TRAN_INTERNAL_ACNUM, MIN(TRAN_VALUE_DATE) MIN_TRAN_VALUE_DATE
            FROM TEMP_LOAN_TRAN_BAL
            GROUP BY TRAN_INTERNAL_ACNUM';

         EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO T_LN_MIN_TRAN_DATE;

         FORALL IND IN T_LN_MIN_TRAN_DATE.FIRST .. T_LN_MIN_TRAN_DATE.LAST
            UPDATE PROCACNUM
                SET LN_TRAN_FROM_DATE = T_LN_MIN_TRAN_DATE (IND).MIN_TRAN_VALUE_DATE
             WHERE     PROCACNUM_ENTITY_NUM = V_GLOB_ENTITY_NUM
                 AND PROC_INTERNAL_ACNUM =T_LN_MIN_TRAN_DATE (IND).PROC_INTERNAL_ACNUM;

         V_SQL := '';
         T_LN_MIN_TRAN_DATE.DELETE;
      END;

      ---- set loan overdue amount

      BEGIN
         V_SQL:='INSERT INTO TEMP_LNODHIST_DATA
            SELECT L.LNODHIST_ENTITY_NUM,
                   L.LNODHIST_INTERNAL_ACNUM,
                   L.LNODHIST_SANC_LIMIT_AMT,
                   L.LNODHIST_DP_AMT,
                   L.LNODHIST_OD_AMT,
                   L.LNODHIST_OD_DATE,
                   L.LNODHIST_ACTUAL_DUE_AMT,
                   L.LNODHIST_EFF_DATE
              FROM LNODHIST L, PROCACNUM P
             WHERE     L.LNODHIST_ENTITY_NUM = P.PROCACNUM_ENTITY_NUM
                   AND L.LNODHIST_INTERNAL_ACNUM = P.PROC_INTERNAL_ACNUM
                   AND L.LNODHIST_EFF_DATE <= :PROCESS_DATE';

         EXECUTE IMMEDIATE V_SQL USING W_ASON_DATE;
      END;

      BEGIN
        V_SQL:='SELECT LNODHIST_ENTITY_NUM,
                 LNODHIST_INTERNAL_ACNUM,
                 MAX (LNODHIST_EFF_DATE) LNODHIST_EFF_DATE
            FROM TEMP_LNODHIST_DATA
            GROUP BY LNODHIST_ENTITY_NUM, LNODHIST_INTERNAL_ACNUM';

         EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO T_LN_OVERDUE_DATE;

         FORALL IND IN T_LN_OVERDUE_DATE.FIRST .. T_LN_OVERDUE_DATE.LAST
            UPDATE PROCACNUM
            SET LN_OVERDUE_FROM_DATE = T_LN_OVERDUE_DATE (IND).LNODHIST_EFF_DATE
            WHERE PROCACNUM_ENTITY_NUM =T_LN_OVERDUE_DATE (IND).LNODHIST_ENTITY_NUM
             AND PROC_INTERNAL_ACNUM =T_LN_OVERDUE_DATE (IND).LNODHIST_INTERNAL_ACNUM;

         V_SQL := '';
         T_LN_OVERDUE_DATE.DELETE;
      END;
   EXCEPTION
    WHEN OTHERS THEN
         W_ERR_MSG := 'Error in set transactioninformation ' || SQLERRM;
         RAISE E_USEREXCEP;
   END;

  PROCEDURE SET_OVERDUE_BALANCE IS
      V_SQL         VARCHAR2 (4000);
      V_DATE        DATE;
      V_FROM_YEAR   NUMBER;
      V_TO_YEAR     NUMBER;
      W_PROC_YEAR   NUMBER;
   BEGIN
      BEGIN
      V_SQL := 'SELECT VALUE_YEAR, TRAN_INTERNAL_ACNUM, TRANADV_INTRD_BC_AMT, TRANADV_CHARGE_BC_AMT,TRAN_DB_CR_FLG,TRAN_DATE_OF_TRAN
                        FROM MV_LOAN_ACCOUNT_BAL_OD T, PROCACNUM P
                         WHERE P.PROC_INTERNAL_ACNUM=T.TRAN_INTERNAL_ACNUM
                         AND PROCACNUM_ENTITY_NUM = :ENTITY_NUMBER
                         AND TRAN_DATE_OF_TRAN <=:TRAN_DATE';

      EXECUTE IMMEDIATE V_SQL BULK COLLECT
        INTO T_TRAN_OVERDUE
            USING V_GLOB_ENTITY_NUM, W_ASON_DATE;

         FORALL IND IN T_TRAN_OVERDUE.FIRST .. T_TRAN_OVERDUE.LAST
        INSERT INTO TEMP_LOAN_OVERDUE
          (VALUE_YEAR,
                                           TRAN_INTERNAL_ACNUM,
                                           TRANADV_INTRD_BC_AMT,
                                           TRANADV_CHARGE_BC_AMT,
                                           TRAN_DB_CR_FLG,
                                           TRAN_DATE_OF_TRAN)
        VALUES
          (T_TRAN_OVERDUE(IND).VALUE_YEAR,
                         T_TRAN_OVERDUE (IND).TRAN_INTERNAL_ACNUM,
                         T_TRAN_OVERDUE (IND).TRANADV_INTRD_BC_AMT,
                         T_TRAN_OVERDUE (IND).TRANADV_CHARGE_BC_AMT,
                         T_TRAN_OVERDUE (IND).TRAN_DB_CR_FLG,
                         T_TRAN_OVERDUE (IND).TRAN_DATE_OF_TRAN);

         T_TRAN_OVERDUE.DELETE;
      EXCEPTION
      WHEN OTHERS THEN
            W_ERR_MSG := 'Error in set overdue balance ' || SQLERRM;
            RAISE E_USEREXCEP;
      END;

      PKG_LOAN_INT_CALC_PROCESS.V_OVERDUR_LOAN_ACC := TRUE;
   END;


   PROCEDURE SP_GEN_DUE_DATE_DATA
   IS
      V_SQL_DATA         VARCHAR2 (4000);

      TYPE REC_FINAL_DUE_DATE IS RECORD
      (
         LNACRSHDTL_ENTITY_NUM       TEMP_LOAN_FDUEDATE.LNACRSHDTL_ENTITY_NUM%TYPE,
         LNACRSHDTL_INTERNAL_ACNUM   TEMP_LOAN_FDUEDATE.LNACRSHDTL_INTERNAL_ACNUM%TYPE,
         FINAL_DUE_DATE              TEMP_LOAN_FDUEDATE.FINAL_DUE_DATE%TYPE
      );

      TYPE TT_FINAL_DUE_DATE IS TABLE OF REC_FINAL_DUE_DATE
         INDEX BY PLS_INTEGER;

      T_FINAL_DUE_DATE   TT_FINAL_DUE_DATE;
   BEGIN
      V_SQL_DATA :=
         'INSERT INTO TEMP_LOAN_FDUEDATE
    SELECT LL.LNACRSHDTL_ENTITY_NUM,
         LL.LNACRSHDTL_INTERNAL_ACNUM,
         LNACRSH_EFF_DATE,
         ADD_MONTHS (
            LL.LNACRSHDTL_REPAY_FROM_DATE,
              (LL.LNACRSHDTL_NUM_OF_INSTALLMENT - 1)
            * ( (CASE
                    WHEN LNACRSHDTL_REPAY_FREQ = ''M'' THEN 1
                    WHEN LNACRSHDTL_REPAY_FREQ = ''Q'' THEN 3
                    WHEN LNACRSHDTL_REPAY_FREQ = ''H'' THEN 6
                    WHEN LNACRSHDTL_REPAY_FREQ = ''Y'' THEN 12
                    WHEN LNACRSHDTL_REPAY_FREQ = ''X'' THEN 0
                 END)))
            FINAL_DUE_DATE, COUNT(1) OVER (PARTITION BY LL.LNACRSHDTL_ENTITY_NUM,
         LL.LNACRSHDTL_INTERNAL_ACNUM) NUMBER_OF_HIST
    FROM (SELECT LNACRSH_ENTITY_NUM, LNACRSH_INTERNAL_ACNUM, LNACRSH_EFF_DATE
            FROM LNACRSHIST L, PROCACNUM P
           WHERE     P.PROCACNUM_ENTITY_NUM = L.LNACRSH_ENTITY_NUM
                 AND P.PROC_INTERNAL_ACNUM = L.LNACRSH_INTERNAL_ACNUM
                 AND L.LNACRSH_EFF_DATE >=
                        (SELECT MAX (LNACRSH_EFF_DATE)
                           FROM LNACRSHIST H
                          WHERE     H.LNACRSH_ENTITY_NUM = P.PROCACNUM_ENTITY_NUM
                                AND H.LNACRSH_INTERNAL_ACNUM =P.PROC_INTERNAL_ACNUM
                                AND H.LNACRSH_EFF_DATE <= P.INT_FROM_DATE)) HIST,
         LNACRSHDTL LL
    WHERE     LL.LNACRSHDTL_ENTITY_NUM = LNACRSH_ENTITY_NUM
         AND LL.LNACRSHDTL_INTERNAL_ACNUM = LNACRSH_INTERNAL_ACNUM
         AND LL.LNACRSHDTL_EFF_DATE = LNACRSH_EFF_DATE';

      EXECUTE IMMEDIATE V_SQL_DATA;

      SELECT LNACRSHDTL_ENTITY_NUM, LNACRSHDTL_INTERNAL_ACNUM, FINAL_DUE_DATE
        BULK COLLECT INTO T_FINAL_DUE_DATE
        FROM TEMP_LOAN_FDUEDATE
       WHERE NUMBER_OF_HIST = 1;

      FORALL IND IN T_FINAL_DUE_DATE.FIRST .. T_FINAL_DUE_DATE.LAST
         UPDATE PROCACNUM
            SET LN_FINAL_DUE_DATE = T_FINAL_DUE_DATE (IND).FINAL_DUE_DATE
          WHERE     PROCACNUM_ENTITY_NUM =
                       T_FINAL_DUE_DATE (IND).LNACRSHDTL_ENTITY_NUM
                AND PROC_INTERNAL_ACNUM =
                       T_FINAL_DUE_DATE (IND).LNACRSHDTL_INTERNAL_ACNUM;

      DELETE FROM TEMP_LOAN_FDUEDATE
            WHERE NUMBER_OF_HIST = 1;
   END;

   PROCEDURE SP_GEN_SHORT_TERM_LOAN_DATA (P_BRANCH_CODE NUMBER)
   IS
      V_SQL_DATA          CLOB;

      TYPE REC_SHORT_TERM_LOAN IS RECORD
      (
         PROCACNUM_ENTITY_NUM   PROCACNUM.PROCACNUM_ENTITY_NUM%TYPE,
         PROC_INTERNAL_ACNUM    PROCACNUM.PROC_INTERNAL_ACNUM%TYPE,
         APP_INT_AMT            PROCACNUM.APP_INT_AMT%TYPE,
         LNACDISB_DISB_AMT      PROCACNUM.APP_INT_AMT%TYPE,
         MIG_INT_AMT            PROCACNUM.APP_INT_AMT%TYPE,
         LNIA_MRR_INT_AMT       PROCACNUM.APP_INT_AMT%TYPE
      );

      TYPE TT_SHORT_TERM_LOAN IS TABLE OF REC_SHORT_TERM_LOAN
         INDEX BY PLS_INTEGER;

      T_SHORT_TERM_LOAN   TT_SHORT_TERM_LOAN;
   BEGIN
      V_SQL_DATA :=
         'WITH DATA_PROCACNUM
     AS (SELECT P.PROCACNUM_ENTITY_NUM,
                P.PROC_INTERNAL_ACNUM,
                NVL (LNACNT_INT_APPLIED_UPTO_DATE, ACNTS_OPENING_DATE - 1)
                   VALUE_DATE
           FROM LNPRODPM L,
                PROCACNUM P,
                ACNTS A,
                LOANACNTS L
          WHERE     P.PROCACNUM_ENTITY_NUM = A.ACNTS_ENTITY_NUM
                AND P.PROC_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
                AND P.PROCACNUM_ENTITY_NUM = L.LNACNT_ENTITY_NUM
                AND P.PROC_INTERNAL_ACNUM = L.LNACNT_INTERNAL_ACNUM
                AND A.ACNTS_PROD_CODE = L.LNPRD_PROD_CODE
                AND LNPRD_SHORT_TERM_LOAN = ''1''),
     DATA_LNINTAPPL
     AS (  SELECT P.PROCACNUM_ENTITY_NUM,
                  P.PROC_INTERNAL_ACNUM,
                  NVL (SUM (LA.LNINTAPPL_ACT_INT_AMT), 0) APP_INT_AMT
             FROM DATA_PROCACNUM P
                  LEFT OUTER JOIN
                  LNINTAPPL LA
                     ON     (    LA.LNINTAPPL_ENTITY_NUM =
                                    P.PROCACNUM_ENTITY_NUM
                             AND LA.LNINTAPPL_ACNT_NUM = P.PROC_INTERNAL_ACNUM)
                        AND LA.LNINTAPPL_BRN_CODE = :BRANCH_CODE
         GROUP BY P.PROCACNUM_ENTITY_NUM, P.PROC_INTERNAL_ACNUM),
     DATA_LNACDISB
     AS (  SELECT P.PROCACNUM_ENTITY_NUM,
                  P.PROC_INTERNAL_ACNUM,
                  NVL (SUM (LD.LNACDISB_DISB_AMT), 0) LNACDISB_DISB_AMT
             FROM DATA_PROCACNUM P
                  LEFT OUTER JOIN
                  LNACDISB LD
                     ON (    LD.LNACDISB_ENTITY_NUM = P.PROCACNUM_ENTITY_NUM
                         AND LD.LNACDISB_INTERNAL_ACNUM = P.PROC_INTERNAL_ACNUM)
         GROUP BY P.PROCACNUM_ENTITY_NUM, P.PROC_INTERNAL_ACNUM),
     DATA_LNTOTINTDBMIG
     AS (  SELECT P.PROCACNUM_ENTITY_NUM,
                  P.PROC_INTERNAL_ACNUM,
                  NVL (SUM (LM.LNTOTINTDB_TOT_INT_DB_AMT), 0)
                     MIG_INT_AMT
             FROM DATA_PROCACNUM P
                  LEFT OUTER JOIN
                  LNTOTINTDBMIG LM
                     ON (    LM.LNTOTINTDB_ENTITY_NUM = P.PROCACNUM_ENTITY_NUM
                         AND LM.LNTOTINTDB_INTERNAL_ACNUM =
                                P.PROC_INTERNAL_ACNUM)
         GROUP BY P.PROCACNUM_ENTITY_NUM, P.PROC_INTERNAL_ACNUM),
     DATA_LOANIAMRR
     AS (  SELECT P.PROCACNUM_ENTITY_NUM,
                  P.PROC_INTERNAL_ACNUM,
                  NVL (SUM (LMR.LOANIAMRR_INT_AMT_RND), 0)
                     LNIA_MRR_INT_AMT
             FROM DATA_PROCACNUM P
                  LEFT OUTER JOIN
                  LOANIAMRR LMR
                     ON (    LMR.LOANIAMRR_ENTITY_NUM = P.PROCACNUM_ENTITY_NUM
                         AND LMR.LOANIAMRR_ACNT_NUM =P.PROC_INTERNAL_ACNUM)
                  AND LMR.LOANIAMRR_BRN_CODE=:BRANCH_CODE
                  AND LMR.LOANIAMRR_VALUE_DATE>P.VALUE_DATE
         GROUP BY P.PROCACNUM_ENTITY_NUM, P.PROC_INTERNAL_ACNUM)
        SELECT LA.PROCACNUM_ENTITY_NUM,
               LA.PROC_INTERNAL_ACNUM,
               LA.APP_INT_AMT,
               LDA.LNACDISB_DISB_AMT,
               LMIG.MIG_INT_AMT,
               LIM.LNIA_MRR_INT_AMT
          FROM DATA_LNINTAPPL LA, DATA_LNACDISB LDA, DATA_LNTOTINTDBMIG LMIG, DATA_LOANIAMRR LIM
         WHERE     LA.PROCACNUM_ENTITY_NUM = LDA.PROCACNUM_ENTITY_NUM
               AND LA.PROC_INTERNAL_ACNUM = LDA.PROC_INTERNAL_ACNUM
               AND LA.PROCACNUM_ENTITY_NUM = LMIG.PROCACNUM_ENTITY_NUM
               AND LA.PROC_INTERNAL_ACNUM = LMIG.PROC_INTERNAL_ACNUM
               AND LIM.PROCACNUM_ENTITY_NUM = LMIG.PROCACNUM_ENTITY_NUM
               AND LIM.PROC_INTERNAL_ACNUM = LMIG.PROC_INTERNAL_ACNUM ';

      EXECUTE IMMEDIATE V_SQL_DATA
         BULK COLLECT INTO T_SHORT_TERM_LOAN
         USING P_BRANCH_CODE, P_BRANCH_CODE;

      FORALL IND IN T_SHORT_TERM_LOAN.FIRST .. T_SHORT_TERM_LOAN.LAST
         UPDATE PROCACNUM
            SET APP_INT_AMT = T_SHORT_TERM_LOAN (IND).APP_INT_AMT,
                LNACDISB_DISB_AMT = T_SHORT_TERM_LOAN (IND).LNACDISB_DISB_AMT,
                MIG_INT_AMT = T_SHORT_TERM_LOAN (IND).MIG_INT_AMT,
                LNIA_MRR_INT_AMT = T_SHORT_TERM_LOAN (IND).LNIA_MRR_INT_AMT
           WHERE     PROCACNUM_ENTITY_NUM =T_SHORT_TERM_LOAN (IND).PROCACNUM_ENTITY_NUM
                 AND PROC_INTERNAL_ACNUM =T_SHORT_TERM_LOAN (IND).PROC_INTERNAL_ACNUM;

      T_SHORT_TERM_LOAN.DELETE;
   END SP_GEN_SHORT_TERM_LOAN_DATA;

   PROCEDURE PROC_INT_CALC (V_ENTITY_NUM       IN NUMBER,
                            V_BRN_CODE         IN NUMBER,
                          V_ACCOUNT_NUMBER IN NUMBER) IS
    --== MIG ==
      W_MIG_M_Y                      VARCHAR2 (20) := '';

      W_SODEODPROCRUN_PACKAGE_NAME   VARCHAR2 (300);
      V_SQL                          VARCHAR2 (3000);
   BEGIN
      W_PROC_BRN_CODE := V_BRN_CODE;
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);
      V_GLOB_ENTITY_NUM := V_ENTITY_NUM;
      PKG_PB_GLOBAL_EOD_SOD.SET_INSTALL_CONFIG (V_ENTITY_NUM); -- Added by rajib.pradhan for initializing all parameter value

      --- W_FIN_START_MONTH := PKG_PB_GLOBAL.FN_GET_FIN_YEAR_MONTH(V_GLOB_ENTITY_NUM);
      W_FIN_START_MONTH:=PKG_PB_GLOBAL_EOD_SOD.T_INSTALL(V_ENTITY_NUM).INS_FIN_YEAR_START_MONTH;

     <<READLOANACNTS>>
      W_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

      W_CBD := W_ASON_DATE;

      W_MIG_M_Y := '';

    IF (NOT (W_IS_MIG_MONTH = 'Y') AND (NOT (W_IS_MIG_MONTH = 'N'))) THEN
         SELECT TO_CHAR (MIG_END_DATE, 'MON-YYYY'), MIG_END_DATE
           INTO W_MIG_M_Y, V_MIG_END_DATE
           FROM MIG_DETAIL
          WHERE BRANCH_CODE = W_PROC_BRN_CODE;

      IF W_MIG_M_Y = TO_CHAR(W_CBD, 'MON-YYYY') THEN
            W_IS_MIG_MONTH := 'Y';
         ELSE
            W_IS_MIG_MONTH := 'N';
         END IF;
      END IF;

      W_INT_ON_RECOVERY := FALSE;

    IF (W_LAP_PROCESS = TRUE) THEN
      W_RUN_NUMBER := FN_READ_SODEODPROCRUN(PKG_EODSOD_FLAGS.PV_PROCESS_NAME,
                                   PKG_EODSOD_FLAGS.PV_CURRENT_DATE);
      ELSE
         GET_RUN_NUMBER;

        <<FETCH_SODEODPROCRUN>>
         BEGIN
        W_SODEODPROCRUN_PACKAGE_NAME := PKG_SYSMONITOR.FN_GET_PROCESS_NAME(V_GLOB_ENTITY_NUM,
                  PKG_EODSOD_FLAGS.PV_PROCESS_NAME);

            SELECT SODEODPROCRUN_RUN_NUMBER
              INTO W_LAP_RUN_NUMBER
              FROM SODEODPROCRUN
             WHERE     SODEODPROCRUN_ENTITY_NUM = V_GLOB_ENTITY_NUM
           AND SODEODPROCRUN_PACKAGE_NAME = W_SODEODPROCRUN_PACKAGE_NAME
                   AND SODEODPROCRUN_DATE = PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
         EXCEPTION
        WHEN NO_DATA_FOUND THEN
               W_LAP_RUN_NUMBER := 0;
         END SODEODPROCRUN;
      --Prasanth NS-CHN-09-10-2008-end
      END IF;

      --AGK-CHN-04-SEP-2008-REM          GET_LNPRODPM_PARAM;
      --AGK-CHN-04-SEP-2008-REM          GET_CURR_SPECIFIC_PARAM;
      W_DAY_END_STR := ' LL.LNPRD_INT_ACCR_FREQ = ''D'' ';
    W_MONTH_END_STR     := W_DAY_END_STR || ' OR ' ||
                           ' LL.LNPRD_INT_ACCR_FREQ = ''M'' ';
    W_QUARTER_END_STR   := W_MONTH_END_STR || ' OR ' ||
                           ' LL.LNPRD_INT_ACCR_FREQ = ''Q'' ';
    W_HALF_YEAR_END_STR := W_QUARTER_END_STR || ' OR ' ||
                           ' LL.LNPRD_INT_ACCR_FREQ = ''H'' ';
    W_YEAR_END_STR      := W_HALF_YEAR_END_STR || ' OR ' ||
                           ' LL.LNPRD_INT_ACCR_FREQ = ''Y'' ';
      W_DMQHY := 'D';
      W_FINAL_WHERE_STR := W_DAY_END_STR;

    IF GET_MQHY_MON(V_GLOB_ENTITY_NUM, W_ASON_DATE, 'M') = 1 THEN
         W_DMQHY := 'M';
         W_FINAL_WHERE_STR := W_MONTH_END_STR;

      IF GET_MQHY_MON(V_GLOB_ENTITY_NUM, W_ASON_DATE, 'Q') = 1 THEN
            W_DMQHY := 'Q';
            W_FINAL_WHERE_STR := W_QUARTER_END_STR;

        IF GET_MQHY_MON(V_GLOB_ENTITY_NUM, W_ASON_DATE, 'H') = 1 THEN
               W_DMQHY := 'H';
               W_FINAL_WHERE_STR := W_HALF_YEAR_END_STR;
            END IF;

        IF GET_MQHY_MON(V_GLOB_ENTITY_NUM, W_ASON_DATE, 'Y') = 1 THEN
               W_DMQHY := 'Y';
               W_FINAL_WHERE_STR := W_YEAR_END_STR;
            END IF;
         END IF;
      END IF;

      BEGIN
         --AGK-CHN-30-08-2008-CHANGES
      IF V_ACCOUNT_NUMBER <> 0 THEN
            DELETE FROM PROCACNUM
                  WHERE PROCACNUM_ENTITY_NUM = V_GLOB_ENTITY_NUM;

        V_SQL := 'SELECT AP.ACNTS_INTERNAL_ACNUM, LL.LNPRD_INT_ACCR_FREQ
                  FROM LNPRODPM LL, ACNTS AP
                  WHERE AP.ACNTS_PROD_CODE = LL.LNPRD_PROD_CODE
                  AND AP.ACNTS_INTERNAL_ACNUM=:1';

        EXECUTE IMMEDIATE V_SQL BULK COLLECT
          INTO V_DUMMY_INTERNAL_ACNUM
               USING V_ACCOUNT_NUMBER;

        FORALL i IN V_DUMMY_INTERNAL_ACNUM.FIRST .. V_DUMMY_INTERNAL_ACNUM.LAST
          INSERT INTO PROCACNUM
            (PROCACNUM_ENTITY_NUM,
                                 PROC_INTERNAL_ACNUM,
                                 RAOPERPARAM_AMT_RESTRIC)
          VALUES
            (V_GLOB_ENTITY_NUM,
                         V_DUMMY_INTERNAL_ACNUM (I).ACNTS_INTERNAL_ACNUM,
                         V_DUMMY_INTERNAL_ACNUM (I).LNPRD_INT_ACCR_REQD);

            GET_LNPRODPM_PARAM;
            GET_CURR_SPECIFIC_PARAM;
         END IF;

         SET_MIN_TRAN_DATA (TO_CHAR (W_ASON_DATE, 'YYYY'));
         SET_TRAN_BALANCE (TO_CHAR (W_ASON_DATE, 'YYYY'));
         SET_OVERDUE_BALANCE;
         SP_GEN_DUE_DATE_DATA ();
         SP_GEN_SHORT_TERM_LOAN_DATA (V_BRN_CODE);

         T_ACNTS.DELETE;

         --Note: Query changed to get Asset Info / For Asset Status Related Info....
         --  AND ACLS.ASSETCLS_INTERNAL_ACNUM = 11606300001172
         W_SQL :=
            'SELECT A.ACNTS_INTERNAL_ACNUM,A.ACNTS_PROD_CODE,A.ACNTS_CURR_CODE,A.ACNTS_INT_ACCR_UPTO,
                A.ACNTS_OPENING_DATE,A.ACNTS_CLIENT_NUM,A.ACNTS_SCHEME_CODE,A.ACNTS_INT_CALC_UPTO,
                L.LNACNT_INT_ACCR_UPTO,TRUNC(LNACNT_ENTD_ON),LL.LNPRD_PENAL_INT_APPLICABLE, P.TRAN_VALUE_DT,
                (SELECT MAX(LOANIAMRR_VALUE_DATE) FROM LOANIAMRR  WHERE LOANIAMRR_ENTITY_NUM = A.ACNTS_ENTITY_NUM
                AND LOANIAMRR_BRN_CODE = A.ACNTS_BRN_CODE AND LOANIAMRR_ACNT_NUM = L.LNACNT_INTERNAL_ACNUM) LOANIAMRR_MAX_VALUE_DATE,
               (SELECT LNACRS_REPHASEMENT_ENTRY FROM LNACRS WHERE LNACRS_ENTITY_NUM = A.ACNTS_ENTITY_NUM AND
                LNACRS_INTERNAL_ACNUM = L.LNACNT_INTERNAL_ACNUM) LNACRS_REPHASEMENT_ENTRY,
                ACD.ASSETCD_ASSET_CLASS,ACLS.ASSETCLS_ASSET_CODE,ACLS.ASSETCLS_NPA_DATE,ACD.ASSETCD_OD_INT_REQD,P.LN_FINAL_DUE_DATE,P.LN_OVERDUE_FROM_DATE,
                P.LN_TRAN_FROM_DATE,LL.LNPRD_SHORT_TERM_LOAN,L.LNACNT_INT_APPLIED_UPTO_DATE, P.APP_INT_AMT, P.LNACDISB_DISB_AMT, P.MIG_INT_AMT, P.LNIA_MRR_INT_AMT,
                (SELECT LNACDTL_GRACE_END_DATE FROM LNACDTLS LD WHERE LD.LNACDTL_ENTITY_NUM = A.ACNTS_ENTITY_NUM AND LD.LNACDTL_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM),
                L.LNACNT_RTMP_ACCURED_UPTO, L.LNACNT_RTMP_PROCESS_DATE, LL.LNPRD_INT_APPL_FREQ, (SELECT COUNT(*) FROM LOANIAPS PP WHERE PP.LOANIAPS_ENTITY_NUM = A.ACNTS_ENTITY_NUM
                AND PP.LOANIAPS_BRN_CODE = A.ACNTS_BRN_CODE AND PP.LOANIAPS_ACNT_NUM=A.ACNTS_INTERNAL_ACNUM) COUNT_LOANIAPS,
				BANKCD_MIRROR_APPL MIRROR_APPLICABLE
                FROM PROCACNUM P, ACNTS A , LOANACNTS L, LNPRODPM LL, ASSETCLS ACLS, ASSETCD ACD,INSTALL,BANKCD
                WHERE L.LNACNT_ENTITY_NUM = :LN_ENTITY_CODE AND A.ACNTS_ENTITY_NUM = :ACNTS_ENTITY_CODE AND
                P.PROCACNUM_ENTITY_NUM = :PROC_ENTITY_CODE AND  LL.LNPRD_INT_PROD_BASIS = ''D'' AND
                A.ACNTS_PROD_CODE = LL.LNPRD_PROD_CODE AND NVL(LL.LNPRD_INT_FREE_LOANS,0) <> ''1'' AND
                A.ACNTS_INTERNAL_aCNUM = L.LNACNT_INTERNAL_ACNUM AND P.PROC_INTERNAL_ACNUM = A.ACNTS_INTERNAL_aCNUM AND
                A.ACNTS_AUTH_ON IS NOT NULL AND A.ACNTS_CLOSURE_DATE IS NULL AND
                ACLS.ASSETCLS_INTERNAL_ACNUM = L.LNACNT_INTERNAL_ACNUM
                AND ACLS.ASSETCLS_ASSET_CODE = ACD.ASSETCD_CODE AND NVL(ACD.ASSETCD_NONPERF_CAT,0) <> ''3''
				AND INS_OUR_BANK_CODE = BANKCD_CODE
				--AND LL.LNPRD_INT_APPL_FREQ <> ''X''
                AND L.LNACNT_AUTH_ON IS NOT NULL AND ( L.LNACNT_INT_ACCR_UPTO IS  NULL OR L.LNACNT_INT_ACCR_UPTO < :1)';

         IF V_BRN_CODE <> 0
         THEN
            W_SQL := W_SQL || ' AND A.ACNTS_BRN_CODE = ' || V_BRN_CODE;
         END IF;

         IF V_ACCOUNT_NUMBER <> 0
         THEN
            W_SQL :=
               W_SQL || ' AND A.ACNTS_INTERNAL_aCNUM = ' || V_ACCOUNT_NUMBER;
         END IF;

         IF V_ACCOUNT_NUMBER = 0
         THEN
            --W_SQL := W_SQL || V_APP_FREQ_STR; -- Note: Application Frequency
            W_SQL :=
                  W_SQL
               || ' AND ( '
               || W_FINAL_WHERE_STR
               || ' ) AND LL.LNPRD_INT_ACCR_REQD = ''1''';
         END IF;

         --W_SQL := W_SQL || ' AND A.ACNTS_INTERNAL_aCNUM IN (10204800011429,10204800011428,10204800012260,10204800012258 )  ' ;
         EXECUTE IMMEDIATE W_SQL
            BULK COLLECT INTO T_ACNTS
            USING V_GLOB_ENTITY_NUM,
                  V_GLOB_ENTITY_NUM,
                  V_GLOB_ENTITY_NUM,
                  W_ASON_DATE;
                  
                  
                  
            INSERT INTO SBS2_DATA_CLOB VALUES (W_SQL);
            COMMIT ;

         FOR IDX IN 1 .. T_ACNTS.COUNT
         LOOP
            V_CTR := IDX;

            W_INTERNAL_ACNUM := T_ACNTS (V_CTR).ACNTS_INTERNAL_ACNUM;
            W_LOANIAMRR_MAX_VALUE_DATE :=
               T_ACNTS (V_CTR).LOANIAMRR_MAX_VALUE_DATE;
            W_LN_TRAN_FROM_DATE := T_ACNTS (V_CTR).LN_TRAN_FROM_DATE;
            W_ACNTS_OPENING_DATE := T_ACNTS (V_CTR).ACNTS_OPENING_DATE;
            W_SHORT_TERM_LOAN := T_ACNTS (V_CTR).LNPRD_SHORT_TERM_LOAN;
            W_INT_APP_UPTO_DATE :=
               T_ACNTS (V_CTR).LNACNT_INT_APPLIED_UPTO_DATE;
            W_LOANIAPS_COUNT := T_ACNTS (V_CTR).COUNT_LOANIAPS;
            V_COUNT_LOANIAPS := 0;


            /*
                    IF W_LAP_PROCESS = TRUE THEN
                      DELETE FROM RTMPLNIA
                       WHERE RTMPLNIA_RUN_NUMBER = W_LAP_RUN_NUMBER
                         AND RTMPLNIA_ACNT_NUM = W_INTERNAL_ACNUM;

                      DELETE FROM RTMPLNIADTL
                       WHERE RTMPLNIADTL_RUN_NUMBER = W_LAP_RUN_NUMBER
                         AND RTMPLNIADTL_ACNT_NUM = W_INTERNAL_ACNUM;

                    END IF;
                    */

            PROCESS_ACCOUNT;

            UPDATE LOANACNTS L
               SET L.LNACNT_RTMP_ACCURED_UPTO = W_PROCESS_DATE - 1, --,    --W_PROCESS_DATE,
                   L.LNACNT_RTMP_PROCESS_DATE = W_ASON_DATE
             --L.LNACNT_PA_ACCR_POSTED_UPTO = MLNACNT_PA_ACCR_POSTED_UPTO(M_INDEX)
             WHERE     LNACNT_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND L.LNACNT_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
         END LOOP;


         IF V_RTMPLNIA_INDX > 0
         THEN
            UPDATE_RTMPLNIA (TRUE);
         END IF;

         --Note: Update ACNTS_INT_CALC_UPTO field at ACNTS Table. Not Necessary Now. Reversal Process will update it
         /*BEGIN
           FORALL IND IN T_ACNTS.FIRST .. T_ACNTS.LAST
             UPDATE ACNTS
                SET ACNTS_INT_CALC_UPTO = W_CBD
              WHERE ACNTS_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND ACNTS_INTERNAL_ACNUM = T_ACNTS(IND).ACNTS_INTERNAL_ACNUM;
         EXCEPTION
           WHEN OTHERS THEN
             DESTROY_ARRAYS;

             IF TRIM(W_ERR_MSG) IS NULL THEN
               W_ERR_MSG := SUBSTR(SQLERRM, 1, 900);
             END IF;

             PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERR_MSG;
             PKG_PB_GLOBAL.DETAIL_ERRLOG(V_GLOB_ENTITY_NUM,
                                         'E',
                                         W_ERR_MSG,
                                         ' ',
                                         0);
         END;*/



         IF (W_LAP_PROCESS = FALSE)
         THEN
            IF TRIM (PKG_EODSOD_FLAGS.GET_ERROR_MSG (V_GLOB_ENTITY_NUM))
                  IS NULL
            THEN
               PKG_EODSOD_FLAGS.PV_RUN_NUMBER := W_RUN_NUMBER;

               IF W_CBD = LAST_DAY (W_CBD)
               THEN
               /*
                  --IF W_CBD = '05-FEB-2017' THEN
                  IF T_ACNTS (V_CTR).MIRROR_APPLICABLE = 1
                  THEN
                     PKG_LOANDAILYACCRPOST_MRR.SP_LOANACCRPOST (
                        V_GLOB_ENTITY_NUM,
                        2,
                        V_BRN_CODE,
                        NVL (V_ACCOUNT_NUMBER, 0)); -- Note: 2 Means CALL FROM EoD.
                  END IF;
              */ 
              -- In Islamic Banking there will no Mirror concept
              
                  PKG_LOANDAILYACCRPOST.SP_LOANACCRPOST (V_GLOB_ENTITY_NUM,
                                                         V_BRN_CODE);
               END IF;
            END IF;
         END IF;


         -- AGK-CHN-24-SEP-2008-ADD
      IF V_ACCOUNT_NUMBER <> 0 THEN
            DESTROY_ARRAYS;
         END IF;
      EXCEPTION
      WHEN OTHERS THEN
            DESTROY_ARRAYS;

        IF TRIM(W_ERR_MSG) IS NULL THEN
               W_ERR_MSG := SUBSTR (SQLERRM, 1, 900);
            END IF;

            PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERR_MSG;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (V_GLOB_ENTITY_NUM,
                                         'E',
                                         W_ERR_MSG,
                                         ' ',
                                         0);
      END READLOANACNTS;
   END PROC_INT_CALC;

  PROCEDURE DESTROY_BRN_WISE_ARRAYS IS
   BEGIN
      T_ACNTS.DELETE;
   END DESTROY_BRN_WISE_ARRAYS;

   -- Note: Process Start from here
   PROCEDURE PROC_BRN_WISE (V_ENTITY_NUM   IN NUMBER,
                          V_BRN_CODE   IN NUMBER DEFAULT 0) IS
      W_BRN_CODE        NUMBER (6);

      W_ACCOUNT_COUNT   NUMBER (10);
      V_SQL             VARCHAR2 (4000);
      W_IGNOR_ACCOUNT   VARCHAR2 (4000);
      C1                RC;

      W_MIG_M_Y         VARCHAR2 (20) := '';
      V_RECORD_COUNT    NUMBER ;
   BEGIN
      PKG_EODSOD_FLAGS.PV_ERROR_MSG := NULL;

      V_GLOB_ENTITY_NUM := V_ENTITY_NUM;
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

      PKG_PB_GLOBAL_EOD_SOD.SET_INSTALL_CONFIG (V_ENTITY_NUM); -- Added by rajib.pradhan for initializing all parameter value

      --W_FIN_START_MONTH := PKG_PB_GLOBAL.FN_GET_FIN_YEAR_MONTH(V_GLOB_ENTITY_NUM);

    W_FIN_START_MONTH:=PKG_PB_GLOBAL_EOD_SOD.T_INSTALL(V_ENTITY_NUM).INS_FIN_YEAR_START_MONTH;

     <<PROCESSBRNWISE>>
      BEGIN
         W_BRN_CODE := 0;
         W_CBD := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

         -- Note: Check Quarter  End... (This Portion completed, commented for execution Reason)

         W_ASON_DATE := W_CBD;
         --W_ASON_DATE :=  TO_DATE('28-FEB-2015', 'DD-MON-YYYY');
         DBMS_OUTPUT.PUT_LINE (' PROCESS DATE = ' || W_ASON_DATE);

         IF (GET_MQHY_MON (V_GLOB_ENTITY_NUM, LAST_DAY (W_ASON_DATE), 'Y') =
                1)
         THEN
            V_APP_FREQ_STR ('M') := 'M';
            V_APP_FREQ_STR ('Q') := 'Q';
            V_APP_FREQ_STR ('H') := 'H';
            V_APP_FREQ_STR ('Y') := 'Y';
         ELSIF (GET_MQHY_MON (V_GLOB_ENTITY_NUM, LAST_DAY (W_ASON_DATE), 'H') =
                   1)
         THEN
            V_APP_FREQ_STR ('M') := 'M';
            V_APP_FREQ_STR ('Q') := 'Q';
            V_APP_FREQ_STR ('H') := 'H';
         ELSIF (GET_MQHY_MON (V_GLOB_ENTITY_NUM, LAST_DAY (W_ASON_DATE), 'Q') =
                   1)
         THEN
            V_APP_FREQ_STR ('Q') := 'Q';
            V_APP_FREQ_STR ('M') := 'M';
         ELSIF (GET_MQHY_MON (V_GLOB_ENTITY_NUM, LAST_DAY (W_ASON_DATE), 'M') =
                   1)
         THEN
            V_APP_FREQ_STR ('M') := 'M';
         END IF;

         -- Note: Commented Temporary for work smoothly....
         --DBMS_MVIEW.REFRESH('MV_LOAN_ACCOUNT_BAL');
         --DBMS_MVIEW.REFRESH('MV_LOAN_ACCOUNT_BAL_OD');
         --COMMIT;

         GET_LNPRODPM_PARAM;
         GET_CURR_SPECIFIC_PARAM;

         PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (V_GLOB_ENTITY_NUM, V_BRN_CODE);

         V_DUMMY_INTERNAL_ACNUM.DELETE;

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT LOOP
            W_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

        IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED(V_GLOB_ENTITY_NUM,
                                                       W_BRN_CODE) = FALSE THEN
          --31-08-2008-CHANGES
               W_ACCOUNT_COUNT := 0;

               W_MIG_M_Y := '';
               W_IS_MIG_MONTH := '';
               V_MIG_END_DATE := NULL;

               BEGIN
                  SELECT TO_CHAR (MIG_END_DATE, 'MON-YYYY'), MIG_END_DATE
                    INTO W_MIG_M_Y, V_MIG_END_DATE
                    FROM MIG_DETAIL
                   WHERE BRANCH_CODE = W_BRN_CODE;

            IF W_MIG_M_Y = TO_CHAR(W_CBD, 'MON-YYYY') THEN
                     W_IS_MIG_MONTH := 'Y';
                  ELSE
                     W_IS_MIG_MONTH := 'N';
                  END IF;
               EXCEPTION
            WHEN NO_DATA_FOUND THEN
                     W_IS_MIG_MONTH := 'N';
               END;

               IF W_LAP_PROCESS = TRUE
               THEN
                  V_SQL :=
                     'SELECT AP.ACNTS_INTERNAL_ACNUM, LL.LNPRD_INT_ACCR_FREQ
                          FROM LNPRODPM LL,
                               ( (SELECT A.ACNTS_INTERNAL_ACNUM, A.ACNTS_PROD_CODE
                                    FROM ACNTS A,
                                         LOANACNTS L,
                                         ASSETCLS ACLS,
                                         ASSETCD ACD
                                   WHERE    L.LNACNT_INTERNAL_ACNUM= A.ACNTS_INTERNAL_ACNUM
                                         AND ACLS.ASSETCLS_INTERNAL_ACNUM = L.LNACNT_INTERNAL_ACNUM
                                         AND ACLS.ASSETCLS_ASSET_CODE = ACD.ASSETCD_CODE
                                         AND L.LNACNT_ENTITY_NUM = :LN_ENTITY_NUM
                                         AND A.ACNTS_ENTITY_NUM = :ACNT_ENTITY_NUM
                                         AND A.ACNTS_CLOSURE_DATE IS NULL
                                         AND NVL (ACD.ASSETCD_NONPERF_CAT, 0) <> ''3''
                                         AND A.ACNTS_BRN_CODE =  :W_BRN_CODE
                                         AND (A.ACNTS_INT_CALC_UPTO IS NULL
                                              OR A.ACNTS_INT_CALC_UPTO < :W_CBD))
                                MINUS
                                ((SELECT LNACINTCTL_INTERNAL_ACNUM, ACNTS.ACNTS_PROD_CODE
                                   FROM LNACINTCTL, ACNTS
                                  WHERE LNACINTCTL_ENTITY_NUM = :LNAC_ENTITY_NUM
                                        AND LNACINTCTL_INT_ACCRUAL_REQD <> ''1''
                                        AND LNACINTCTL.LNACINTCTL_INTERNAL_ACNUM =
                                               ACNTS.ACNTS_INTERNAL_ACNUM
                                        AND ACNTS.ACNTS_ENTITY_NUM=:ACNT_ENTITY_NUM)
                                MINUS
                                (SELECT PROC_INTERNAL_ACNUM, ACNTS.ACNTS_PROD_CODE
                                   FROM EODSODIGACNT, ACNTS
                                  WHERE     PROC_ENTITY_NUM =  :3
                                        AND PROC_TYPE = :4
                                        AND PROC_NAME = :5
                                        AND PROC_DATE = :6
                                        AND PROC_CONTRACT_NUM = 0
                                        AND ACNTS.ACNTS_ENTITY_NUM=:ACNT_ENTITY_NUM
                                        AND EODSODIGACNT.PROC_INTERNAL_ACNUM =
                                               ACNTS.ACNTS_INTERNAL_ACNUM))) AP
                         WHERE AP.ACNTS_PROD_CODE = LL.LNPRD_PROD_CODE';
                         --AND LL.LNPRD_ISLAMIC_BANKING = ''1''';
               ELSE
            V_SQL := 'SELECT AP.ACNTS_INTERNAL_ACNUM, LL.LNPRD_INT_ACCR_FREQ
                          FROM LNPRODPM LL,
                               ( (SELECT A.ACNTS_INTERNAL_ACNUM, A.ACNTS_PROD_CODE
                                    FROM ACNTS A,
                                         LOANACNTS L,
                                         ASSETCLS ACLS,
                                         ASSETCD ACD
                                   WHERE    L.LNACNT_INTERNAL_ACNUM= A.ACNTS_INTERNAL_ACNUM
                                         AND ACLS.ASSETCLS_INTERNAL_ACNUM = L.LNACNT_INTERNAL_ACNUM
                                         AND ACLS.ASSETCLS_ASSET_CODE = ACD.ASSETCD_CODE
                                         AND L.LNACNT_ENTITY_NUM = :LN_ENTITY_NUM
                                         AND A.ACNTS_ENTITY_NUM = :ACNT_ENTITY_NUM
                                         AND A.ACNTS_CLOSURE_DATE IS NULL
                                         AND NVL (ACD.ASSETCD_NONPERF_CAT, 0) <> ''3''
                                         AND A.ACNTS_BRN_CODE =  :W_BRN_CODE
                                         AND (A.ACNTS_INT_CALC_UPTO IS NULL
                                              OR A.ACNTS_INT_CALC_UPTO <= :W_CBD))
                                MINUS
                                ((SELECT LNACINTCTL_INTERNAL_ACNUM, ACNTS.ACNTS_PROD_CODE
                                   FROM LNACINTCTL, ACNTS
                                  WHERE LNACINTCTL_ENTITY_NUM = :LNAC_ENTITY_NUM
                                        AND LNACINTCTL_INT_ACCRUAL_REQD <> ''1''
                                        AND LNACINTCTL.LNACINTCTL_INTERNAL_ACNUM =
                                               ACNTS.ACNTS_INTERNAL_ACNUM
                                               AND ACNTS.ACNTS_ENTITY_NUM=:ACNT_ENTITY_NUM)
                                MINUS
                                (SELECT PROC_INTERNAL_ACNUM, ACNTS.ACNTS_PROD_CODE
                                   FROM EODSODIGACNT, ACNTS
                                  WHERE     PROC_ENTITY_NUM =  :3
                                        AND PROC_TYPE = :4
                                        AND PROC_NAME = :5
                                        AND PROC_DATE = :6
                                        AND PROC_CONTRACT_NUM = 0
                                        AND ACNTS.ACNTS_ENTITY_NUM=:ACNT_ENTITY_NUM
                                        AND EODSODIGACNT.PROC_INTERNAL_ACNUM =
                                               ACNTS.ACNTS_INTERNAL_ACNUM))) AP
                         WHERE AP.ACNTS_PROD_CODE = LL.LNPRD_PROD_CODE';
                         --AND LL.LNPRD_ISLAMIC_BANKING = ''1''';
               END IF;


          IF (W_LAP_PROCESS = TRUE) THEN
            PKG_PROCESS_CHECK.W_ACCOUNT_LIMIT := PKG_EODSOD_FLAGS.PV_INTERVAL_COUNT;
               END IF;

               --V_SQL := V_SQL || V_APP_FREQ_STR; -- Note: Application Frequency

               OPEN C1 FOR V_SQL
                  USING V_GLOB_ENTITY_NUM,
                        V_GLOB_ENTITY_NUM,
                        W_BRN_CODE,
                        W_CBD,
                        V_GLOB_ENTITY_NUM,
                        V_GLOB_ENTITY_NUM,
                        V_GLOB_ENTITY_NUM,
                        PKG_EODSOD_FLAGS.PV_EODSODFLAG,
                        PKG_EODSOD_FLAGS.PV_PROCESS_NAME,
                        W_CBD,
                        V_GLOB_ENTITY_NUM;

               LOOP
            IF PKG_PROCESS_CHECK.W_ACCOUNT_LIMIT > 0 THEN
              FETCH C1 BULK COLLECT
                INTO V_DUMMY_INTERNAL_ACNUM LIMIT W_ACCOUNT_COUNT;
                  ELSE
              FETCH C1 BULK COLLECT
                INTO V_DUMMY_INTERNAL_ACNUM LIMIT 20000;
                  END IF;

            FORALL i IN V_DUMMY_INTERNAL_ACNUM.FIRST .. V_DUMMY_INTERNAL_ACNUM.LAST
              INSERT INTO PROCACNUM
                (PROCACNUM_ENTITY_NUM,
                                       PROC_INTERNAL_ACNUM,
                                       RAOPERPARAM_AMT_RESTRIC)
              VALUES
                (V_GLOB_ENTITY_NUM,
                               V_DUMMY_INTERNAL_ACNUM (I).ACNTS_INTERNAL_ACNUM,
                               V_DUMMY_INTERNAL_ACNUM (I).LNPRD_INT_ACCR_REQD);
                               
           V_RECORD_COUNT := V_DUMMY_INTERNAL_ACNUM.COUNT ;

                  PROC_INT_CALC (V_GLOB_ENTITY_NUM, W_BRN_CODE);

            IF TRIM(W_ERR_MSG) IS NOT NULL THEN
                     PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERR_MSG;
                  END IF;

            PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS(V_GLOB_ENTITY_NUM);

                  EXIT WHEN C1%NOTFOUND;

                  CLOSE C1;

                  V_DUMMY_INTERNAL_ACNUM.DELETE;
                  T_ACNTS.DELETE;
               END LOOP;

               DESTROY_BRN_WISE_ARRAYS;
               V_DUMMY_INTERNAL_ACNUM.DELETE;

               IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
               THEN
                  PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (
                     V_GLOB_ENTITY_NUM,
                     W_BRN_CODE);
               END IF;
               
            W_ERR_MSG := TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) ;
            
          PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS(V_GLOB_ENTITY_NUM);
               DESTROY_BRN_WISE_ARRAYS;
            END IF;
         END LOOP;

         DESTROY_ARRAYS;
         PKG_PROCESS_CHECK.DESTROY_BRN_WISE (V_GLOB_ENTITY_NUM);
      EXCEPTION
      WHEN PKG_PROCESS_CHECK.LAP_SLEEP_EXCEPTION THEN
            RAISE PKG_PROCESS_CHECK.LAP_SLEEP_EXCEPTION;
      WHEN PKG_PROCESS_CHECK.LAP_EXIT_EXCEPTION THEN
            RAISE PKG_PROCESS_CHECK.LAP_EXIT_EXCEPTION;
      WHEN OTHERS THEN
            PKG_PROCESS_CHECK.DESTROY_BRN_WISE (V_GLOB_ENTITY_NUM);
            DESTROY_ARRAYS;

            IF TRIM (W_ERR_MSG) IS NULL
            THEN
               W_ERR_MSG := W_BRN_CODE || ' ' || SUBSTR (SQLERRM, 1, 900);
            END IF;

            PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERR_MSG;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (V_GLOB_ENTITY_NUM,
                                         'E',
                                         W_ERR_MSG,
                                         ' ',
                                         0);
      END PROCESSBRNWISE;
   END PROC_BRN_WISE;

   PROCEDURE LAP (V_ENTITY_NUM       IN     NUMBER,
                  V_BRN_CODE         IN     NUMBER DEFAULT 0,
                V_PROCESS_STATUS OUT NUMBER) IS
      W_PROCESS_STS   NUMBER;
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);
      V_GLOB_ENTITY_NUM := V_ENTITY_NUM;
      PKG_PB_GLOBAL_EOD_SOD.SET_INSTALL_CONFIG (V_ENTITY_NUM); -- Added by rajib.pradhan for initializing all parameter value

      --- W_FIN_START_MONTH := PKG_PB_GLOBAL.FN_GET_FIN_YEAR_MONTH(V_GLOB_ENTITY_NUM);
      W_FIN_START_MONTH :=
         PKG_PB_GLOBAL_EOD_SOD.T_INSTALL (V_ENTITY_NUM).INS_FIN_YEAR_START_MONTH;

     <<START_PROC>>
      BEGIN
         W_PROCESS_STS := 0;
         W_LAP_PROCESS := TRUE;

      PKG_SYSPROCLIST.SYSPROCLIST_ENDTIME(V_GLOB_ENTITY_NUM,
            'L',
            PKG_EODSOD_FLAGS.PV_PROCESS_NAME,
            W_ERR_MSG);

      IF TRIM(W_ERR_MSG) IS NOT NULL THEN
            RAISE E_USEREXCEP;
         END IF;

         W_PROCESS_STS := 3;
      EXCEPTION
      WHEN PKG_PROCESS_CHECK.LAP_SLEEP_EXCEPTION THEN
            W_PROCESS_STS := 0;
      WHEN PKG_PROCESS_CHECK.LAP_EXIT_EXCEPTION THEN
            W_PROCESS_STS := 2;
      WHEN OTHERS THEN
            PKG_PROCESS_CHECK.DESTROY_BRN_WISE (V_GLOB_ENTITY_NUM);
            DESTROY_ARRAYS;

        IF TRIM(W_ERR_MSG) IS NULL THEN
          W_ERR_MSG := SUBSTR('Error in PROC_BRN_WISE_LAP ' || SQLERRM,
                              1,
                              900);
            END IF;

            PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERR_MSG;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (V_GLOB_ENTITY_NUM,
                                         'E',
                                         W_ERR_MSG,
                                         ' ',
                                         0);
      END START_PROC;

      V_PROCESS_STATUS := W_PROCESS_STS;
   END LAP;
END PKG_LOAN_INT_CALC_PROCESS;
/

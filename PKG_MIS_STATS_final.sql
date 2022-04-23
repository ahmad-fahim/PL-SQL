CREATE OR REPLACE PACKAGE PKG_MIS_STATS IS

  TYPE REC_TYPE IS RECORD(
    SL_NO                 NUMBER(10),
    REPORTING_DATE        DATE,
    BRN_SBS_CODE          VARCHAR2(6),
    ACC_NO                VARCHAR2(20),
    ACC_NAME              VARCHAR2(100),
    CLIENT_OCCUP          VARCHAR2(35),
    SEGMENT_CODE          VARCHAR2(20), -- 7
    PROD_NAME             VARCHAR2(100),
    LOAN_CODE             VARCHAR2(10), -- (9)
    PROD_CODE             ACNTS.ACNTS_PROD_CODE%TYPE,
    SME_CODE              LNACMIS.LNACMIS_NATURE_BORROWAL_AC%TYPE,
    INT_RATE              LNACIR.LNACIR_APPL_INT_RATE%TYPE, -- (12)
    ECO_PURP_CODE         VARCHAR2(20), -- (13)
    SEC_CODE              VARCHAR2(1000),
    CLASSIFICATION_CODE   ASSETCD.ASSETCD_BSR_CODE%TYPE,
    SANC_RESCHE_AMT       LIMITLINE.LMTLINE_SANCTION_AMT%TYPE,
    SANC_RESCHE_DATE      VARCHAR2(20),
    EXPIRY_DATE           VARCHAR2(20),
    NO_OF_INSTALLMENT     LNACRSDTL.LNACRSDTL_NUM_OF_INSTALLMENT%TYPE,
    REPAY_FREQ            CHAR(1),
    INSTALL_AMT           NUMBER(18, 3),
    DEBIT_CASH            NUMBER(18, 3), --- (22)
    DEBIT_INT             NUMBER(18, 3), --- (23)
    DEBIT_OTHERS          NUMBER(18, 3), --- (24)
    CREDIT_CASH           NUMBER(18, 3), --- (25)
    CREDIT_INT            NUMBER(18, 3), --- (26)
    CREDIT_OTHERS         NUMBER(18, 3), --- (27)
    OD_AMOUNT             NUMBER(18, 3), --- (28)
    OUTSTANDING_BAL       NUMBER(18, 3),
    HO_DIVISION_NAME      VARCHAR2(100), -- (30)
    LN_SANC_AUTH          VARCHAR2(100), -- (31)
    BORROWER_FIS_CODE     VARCHAR2(10), -- (32)
    WOEMEN_ENTPRNURS      CHAR(1), -- (33)
    SISTER_CONCERN        CHAR(1), -- (34)
    NAME_OF_GROUP         VARCHAR2(100), -- (35)
    SYNDICATE_LOAN        CHAR(1), -- (36)
    BRIDGE_FINANCE        CHAR(1), -- (37)
    CONSORTIUM_LOAN       CHAR(1), -- (38)
    BORROWER_EQUITY       VARCHAR2(100), -- (39)
    LOAN_SCHEME_CODE      VARCHAR2(10), -- (40)
    CL_FORM_NO            VARCHAR2(10), -- (41)
    FIRST_SANC_DATE       VARCHAR2(20), -- (42)
    FIRST_SANC_LIMIT      NUMBER(18, 3), -- (43)
    NEXT_INSTL_DATE       VARCHAR2(20), -- (44)
    NEXT_INSTL_AMT        NUMBER(18, 3), -- (45)
    REMAINING_INSTALLMENT LNACRSDTL.LNACRSDTL_NUM_OF_INSTALLMENT%TYPE, -- (46)
    NO_OF_OD_INSTLMNT     LNACRSDTL.LNACRSDTL_NUM_OF_INSTALLMENT%TYPE, -- (47)
    LAST_PAY_DATE         VARCHAR2(20), -- (48)
    SUBSIDIZED_CREDIT     CHAR(1), -- (49)
    PRE_FINANCE_OF_LOAN   CHAR(1), -- (50)
    
    --- SECURITY ---
    ELIGIBLE_SEC_VAL    NUMBER(18, 3), -- 51
    PRIM_MKT_VAL        NUMBER(18, 3), -- 52
    PRIM_SALE_VAL       NUMBER(18, 3), --53
    LAND_MKT_VAL        NUMBER(18, 3), -- 54
    LAND_SALE_VAL       NUMBER(18, 3), -- 55
    OTH_MKT_VAL         NUMBER(18, 3), -- 56
    OTH_SALE_VALE       NUMBER(18, 3), -- 57
    THIRD_PRTY_GUAR_TYP VARCHAR2(50), -- 58
    THIRD_PRTY_GUAR_AMT NUMBER(18, 3), -- 59
    --
    
    CL_DATE        VARCHAR2(20), -- (60)
    DEFAULT_STS    CHAR(1), -- 61
    QUALIT_JUDGMNT CHAR(1), -- 62
    
    --- RESCHEDULE ---
    RESCH_APPROV_AUTH VARCHAR2(50), -- 63
    RESCH_DATE        VARCHAR2(20), -- 64
    RESCH_TIME        VARCHAR2(20), -- 65
    --
    
    --- RENEWAL ---
    RENW_APPROV_AUTH VARCHAR2(50), -- 66
    RENW_DATE        VARCHAR2(20), -- 67
    RENW_TIME        VARCHAR2(20), -- 68
    --
    
    --- ENHANCEMENT ---
    RENW_WITH_ENHNC   NUMBER, -- 69
    ENHNC_APPROV_AUTH VARCHAR2(50), -- 70
    ENHNC_DATE        VARCHAR2(20), -- 71
    ENHNC_PORSION     VARCHAR2(20), -- 72
    --
    
    ---  INTEREST WAIVE  ---
    IW_APPROV_AUTH VARCHAR2(50), -- 73
    IW_DATE        VARCHAR2(20), -- 74
    IW_DB_INCM_AMT NUMBER(18, 3), -- 75
    IW_DB_INT_SUSP NUMBER(18, 3), -- 76
    IW_UNCHRGD_AMT NUMBER(18, 3), -- 77
    --
    
    BLOCK_LN_DATE      VARCHAR2(20), -- 78
    BLOCK_LN_WITH_INT  CHAR(1), -- 79
    LAWSUIT_DATE       VARCHAR2(20), -- 80
    TYP_OF_LAWSUIT     VARCHAR2(20), -- 81
    WRTOFF_APPROV_AUTH VARCHAR2(20), -- 82
    WRTOFF_DATE        VARCHAR2(20), --  83
    
    --- ACQUISITION  ---
    ACQ_APPROV_AUTH VARCHAR2(20), -- 84
    ACQ_BNK         VARCHAR2(20), -- 85
    ACQ_DATE        VARCHAR2(20), -- 86
    --
    
    PAYMENT_METHOD        VARCHAR2(20), -- 87
    TOTAL_DISBURSE        NUMBER(18, 3), -- 88
    DISBURSE_FORMULA      NUMBER(18, 3), -- 89
    RECOV_FORMULA         NUMBER(18, 3), -- 90
    CUMULTV_RECOV         NUMBER(18, 3), -- 91
    INT_SUSP              NUMBER(18, 3), -- 92
    INT_RECV              NUMBER(18, 3), -- 93
    PRINCIPAL_BAL         NUMBER(18, 3), -- 94
    INT_BAL               NUMBER(18, 3), -- 95
    OTHER_BAL             NUMBER(18, 3), -- 96
    DEFAULTED_OUTSTANDING NUMBER(18, 3), -- 97
    PERIOD_OF_AREARS      NUMBER(3), -- 98
    FIRST_REPAY_DUE_DATE  VARCHAR2(20), -- 99
    AMT_PAID_SINCE_SANC   NUMBER(18, 3), -- 100
    TIME_EQUIV_AMT_PAID   NUMBER(3), -- 101
    
    --- PERSONAL INFORMATION ---
    FATHER_NAME      VARCHAR2(100), -- 102
    MOTHER_NAME      VARCHAR2(100), -- 103
    SPOUSE_NAME      VARCHAR2(100), -- 104
    CLIENTS_GENDER   CHAR(1), -- 105
    DATE_OF_BIRTH    VARCHAR2(100), -- 106
    BIRTH_PLACE      VARCHAR2(100), -- 107
    BIRTH_COUNTRY    VARCHAR2(100), -- 108
    NID_NO           VARCHAR2(30), -- 109
    TIN_NO           VARCHAR2(30), -- 110
    OTHER_DOCU_TYP   VARCHAR2(30), -- 111
    OTHER_DOCU_NO    VARCHAR2(30), -- 112
    OTHER_DOCU_DATE  VARCHAR2(30), -- 113
    OTHER_DOCU_CNTRY VARCHAR2(30), -- 114
    --
    
    --- PERMANENT ADDRESS ---
    PERM_VILLAGE VARCHAR2(30), -- 115
    PERM_PS      VARCHAR2(30), -- 116
    PERM_PC      VARCHAR2(30), -- 117
    PERM_DIST    VARCHAR2(30), -- 118
    PERM_CNTRY   VARCHAR2(30), -- 119
    --
    
    --- PRESENT ADDRESS ---
    PRES_VILLAGE VARCHAR2(30), -- 120
    PRES_PS      VARCHAR2(30), -- 121
    PRES_PC      VARCHAR2(30), -- 122
    PRES_DIST    VARCHAR2(30), -- 123
    PRES_CNTRY   VARCHAR2(30), -- 124
    --
    
    --- BUSINESS ADDRESS ---
    BUSI_VILLAGE VARCHAR2(30), -- 125
    BUSI_PS      VARCHAR2(30), -- 126
    BUSI_PC      VARCHAR2(30), -- 127
    BUSI_DIST    VARCHAR2(30), -- 128
    BUSI_CNTRY   VARCHAR2(30), -- 129
    --
    
    LEGAL_FORM            VARCHAR2(30), -- 130
    RJSC_REG_NO           VARCHAR2(30), -- 131
    RJSC_DATE             VARCHAR2(20), -- 132
    SEC_DESC              VARCHAR2(100), -- 133
    EMP_NO                VARCHAR2(30), -- 134
    TELE_NO               VARCHAR2(20), -- 135
    CLIENT_CODE           NUMBER(12), -- 136
    DEFAULT_IN_LIFE       VARCHAR(5), -- 137
    START_DATE            VARCHAR2(20), -- 138
    CLOSED_DATE           VARCHAR2(20),
    BRANCH_CODE           NUMBER,
    NUMBER_OF_ENHANCEMENT NUMBER); -- 139

  /*   DISBURSE_DATE VARCHAR2(20),
      DISBURSE_AMT  NUMBER(18, 3),
  
      REPAY_START_DATE VARCHAR2(20),
  
      SEC_NUM VARCHAR2(1000));
  */
  TYPE REC_TAB IS TABLE OF REC_TYPE;

  FUNCTION GET_BRANCH_WISE(P_ENTITY_NUM NUMBER,
                           P_BRN_CODE   NUMBER,
                           P_FROM_DATE  DATE,
                           P_TO_DATE    DATE) RETURN REC_TAB
    PIPELINED;
  ---RETURN VARCHAR2;

END PKG_MIS_STATS;
/



CREATE OR REPLACE PACKAGE BODY PKG_MIS_STATS
IS
   TEMP_DATA                PKG_MIS_STATS.REC_TYPE;

   TYPE TEMP_RECORD IS RECORD
   (
      T_AC_NUM                ACNTS.ACNTS_INTERNAL_ACNUM%TYPE,
      T_CLIENT_CODE           ACNTS.ACNTS_CLIENT_NUM%TYPE,
      T_AC_NAME               VARCHAR2 (200),
      T_CURR_CODE             ACNTS.ACNTS_CURR_CODE%TYPE,
      T_SECTOR_CODE           CLIENTS.CLIENTS_SEGMENT_CODE%TYPE,
      T_PROD_NAME             PRODUCTS.PRODUCT_NAME%TYPE,
      T_LOAN_CODE             RPTHEADGLDTL.RPTHDGLDTL_CODE%TYPE,
      T_PROD_CODE             PRODUCTS.PRODUCT_CODE%TYPE,
      T_INT_RATE              NUMBER (8, 5),
      T_SECURITY_CODE         VARCHAR2 (100),
      T_DB_CR_TOTAL           VARCHAR2 (1000),
      T_OD_AMT                NUMBER (18, 3),
      --T_OUTSTANDING_BAL       NUMBER (18, 3),
      T_BORROWER_CODE         CLIENTS.CLIENTS_BORROWER_CODE%TYPE,
      T_FIS_CODE              CLIENTS.CLIENTS_FIS_CODE%TYPE,
      T_PRODUCT_FOR_RUN_ACS   NUMBER,
      T_ACNTS_CLOSURE_DATE    DATE
   );

   TYPE TABLEA IS TABLE OF TEMP_RECORD
      INDEX BY PLS_INTEGER;

   T_TEMP_REC               TABLEA;

   V_EXP_DATE               DATE;
   V_LIMIT_RESCH_DATE       DATE;
   V_LIMIT_RESCH_AMT        NUMBER (18, 3);
   V_DISB_AMT               NUMBER (18, 3);
   V_LIMIT_LINE_NUM         NUMBER (8);
   W_LIM_CLIENT             NUMBER (8);
   V_LIMIT_SAUTH_CODE       LIMITLINE.LMTLINE_SAUTH_CODE%TYPE;
   V_EFF_DATE               LIMITLINE.LMTLINE_LIMIT_EFF_DATE%TYPE;
   V_FIRST_SANC_LIMIT       NUMBER (18, 3);
   V_FIRST_SANC_DATE        VARCHAR2 (20);
   V_ENHNC_AMT              NUMBER (18, 3);
   W_COUNTER                NUMBER (4);
   V_APPROVAL_AUTH          VARCHAR2 (100);
   V_TEMP_FLAG              CHAR (1);
   V_NEWEAL_TIME            NUMBER (4);
   V_CBD                    DATE;
   V_GLOB_ENTITY_NUM        NUMBER;
   W_BRN_CODE               NUMBER (6);

   --Reschedule Account.
   V_IS_RESCHEDULE_ACC      CHAR (1);
   V_RESCHEDULE_AMT         NUMBER (18, 3);
   V_RESCHEDULE_SANC_DATE   DATE;
   V_DISBURSE_DATE          DATE;
   ---    LAD
   V_IS_LAD_ACC             BOOLEAN;
   W_INTERNAL_ACNUM         VARCHAR2 (20);
   W_ASON_DATE              DATE;
   W_TOT_SEC_AMT_AC         NUMBER (18, 3);
   W_TOT_SEC_AMT_BC         NUMBER (18, 3);
   W_SEC_NUM                VARCHAR2 (1000);
   W_SEC_AMT_ACNT_CURR      NUMBER (18, 3);

   W_SEC_TYPE               SECRCPT.SECRCPT_SEC_TYPE%TYPE;
   W_SEC_CURR_CODE          SECRCPT.SECRCPT_CURR_CODE%TYPE;
   W_SECURED_VALUE          SECRCPT.SECRCPT_SECURED_VALUE%TYPE;

   W_SEC_TYPE_STR           VARCHAR2 (1000);
   W_SEC_NUM_STR            VARCHAR2 (1000);
   W_REMARKS                VARCHAR2 (500);

   -- ALAM
   FUNCTION GET_LAD_SECURED_VALUE
      RETURN NUMBER
   IS
      W_PROD_CODE        VARCHAR2 (10) := '';

      W_DEP_ACC          VARCHAR2 (20) := '';
      W_ACC_BAL          NUMBER (18, 3) := 0;
      W_CNT              NUMBER := 0;
      W_BASE_CURR_CODE   VARCHAR2 (4);
   BEGIN
      V_IS_LAD_ACC := FALSE;
      W_CNT := 0;
      W_BASE_CURR_CODE := 'BDT';

      SELECT ACNTS_PROD_CODE
        INTO W_PROD_CODE
        FROM ACNTS A
       WHERE A.ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACNUM;

      SELECT COUNT (*)
        INTO W_CNT
        FROM LADPRODMAP LNMAP
       WHERE LNMAP.LADPRODMAP_PROD_CODE = W_PROD_CODE;

      --DBMS_OUTPUT.PUT_LINE(W_PROD_CODE || '  W_CNT = ' || W_CNT);

      IF W_CNT > 0
      THEN
         V_IS_LAD_ACC := TRUE;

        <<DEP_ACC_AMT>>
         BEGIN
            FOR DEP_ACC
               IN (SELECT LADDTL_DEP_ACNT_NUM
                     FROM LADACNTDTL LNDTL
                    WHERE LNDTL.LADDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM)
            LOOP
               W_ACC_BAL :=
                    W_ACC_BAL
                  + FN_GET_ASON_ACBAL (1,
                                       DEP_ACC.LADDTL_DEP_ACNT_NUM,
                                       W_BASE_CURR_CODE,
                                       W_ASON_DATE,         -- NEEDS TO CHANGE
                                       V_CBD);              -- NEEDS TO CHANGE
            END LOOP;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               W_DEP_ACC := 0;
         END DEP_ACC_AMT;
      ELSE
         W_ACC_BAL := 0;
         V_IS_LAD_ACC := FALSE;
      END IF;

      RETURN W_ACC_BAL;
   END GET_LAD_SECURED_VALUE;

   --*****


   FUNCTION GET_CL_DATE (P_ACCOUNT_NUMBER NUMBER, P_TO_DATE DATE)
      RETURN DATE
   AS
      V_CL_DATE   DATE;
   BEGIN
      SELECT NVL (MIN (ASSETCLSH_NPA_DATE), NULL)
        INTO V_CL_DATE
        FROM ASSETCLSHIST A
       WHERE     A.ASSETCLSH_ENTITY_NUM = 1
             AND A.ASSETCLSH_INTERNAL_ACNUM = P_ACCOUNT_NUMBER
             AND A.ASSETCLSH_EFF_DATE >
                    (SELECT NVL (MAX (ASSETCLSH_EFF_DATE), '01-JAN-1000')
                       FROM ASSETCLSHIST
                      WHERE     ASSETCLSH_ENTITY_NUM = 1
                            AND ASSETCLSH_INTERNAL_ACNUM = P_ACCOUNT_NUMBER
                            AND ASSETCLSH_EFF_DATE <= P_TO_DATE
                            AND ASSETCLSH_ASSET_CODE IN ('UC', 'SM'))
             AND A.ASSETCLSH_EFF_DATE <= P_TO_DATE;

      RETURN V_CL_DATE;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CL_DATE;


   FUNCTION GET_METHOD_OF_PAYMENT (P_ACCOUNT_NUMBER NUMBER)
      RETURN NUMBER
   AS
      V_MODE_OF_PAYMENT      NUMBER := 3;
      V_ACCOUNT_CREATED_BY   VARCHAR2 (8);
      V_OPENING_DATE         DATE;
      V_FIN_YEAR             NUMBER (4);
      V_SQL                  VARCHAR2 (2000);
   BEGIN
      SELECT ACNTS_OPENING_DATE, ACNTS_ENTD_BY
        INTO V_OPENING_DATE, V_ACCOUNT_CREATED_BY
        FROM ACNTS
       WHERE ACNTS_ENTITY_NUM = 1 AND ACNTS_INTERNAL_ACNUM = P_ACCOUNT_NUMBER;

      IF V_ACCOUNT_CREATED_BY = 'MIG'
      THEN
         V_MODE_OF_PAYMENT := 3;
      ELSE
         V_FIN_YEAR := TO_CHAR (V_OPENING_DATE, 'YYYY');

         BEGIN
            V_SQL :=
                  'SELECT T.TRAN_TYPE_OF_TRAN
  FROM TRAN'
               || V_FIN_YEAR
               || ' T, TRANADV'
               || V_FIN_YEAR
               || ' TT
 WHERE     T.TRAN_ENTITY_NUM = TT.TRANADV_ENTITY_NUM
       AND T.TRAN_BRN_CODE = TT.TRANADV_BRN_CODE
       AND T.TRAN_DATE_OF_TRAN = TT.TRANADV_DATE_OF_TRAN
       AND T.TRAN_BATCH_NUMBER = TT.TRANADV_BATCH_NUMBER
       AND T.TRAN_BATCH_SL_NUM = TT.TRANADV_BATCH_SL_NUM
       AND T.TRAN_ENTITY_NUM = 1
       AND T.TRAN_INTERNAL_ACNUM = :1
       AND (T.TRAN_DATE_OF_TRAN, T.TRAN_BATCH_NUMBER) IN
              (SELECT MIN (T1.TRAN_DATE_OF_TRAN), MIN (T1.TRAN_BATCH_NUMBER)
                 FROM TRAN'
               || V_FIN_YEAR
               || ' T1
                WHERE     T1.TRAN_ENTITY_NUM = 1
                      AND T1.TRAN_INTERNAL_ACNUM = :2
                      AND T1.TRAN_DB_CR_FLG = ''D'')
       AND T.TRAN_DB_CR_FLG = ''D''
       AND TT.TRANADV_PRIN_AC_AMT > 0';

            EXECUTE IMMEDIATE V_SQL
               INTO V_MODE_OF_PAYMENT
               USING P_ACCOUNT_NUMBER, P_ACCOUNT_NUMBER;
         EXCEPTION
            WHEN OTHERS
            THEN
               V_MODE_OF_PAYMENT := 3;
         END;
      END IF;

      RETURN V_MODE_OF_PAYMENT;
   END GET_METHOD_OF_PAYMENT;



   FUNCTION FN_GET_RUN_PRINCIPLE_ACBAL (V_ENTITY_NUM       IN NUMBER,
                                        P_INTERNAL_ACNUM   IN NUMBER,
                                        P_ASON_DATE        IN DATE)
      RETURN NUMBER
   IS
      V_ASON_AC_BAL   NUMBER (18, 3) := 0;
      W_MONTH         NUMBER (2);
      W_MON           CHAR (3);
      W_YEAR          NUMBER (4);
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);
      W_MONTH := TO_NUMBER (TO_CHAR (P_ASON_DATE + 1, 'mm'));
      W_YEAR := SP_GETFINYEAR (V_ENTITY_NUM, P_ASON_DATE + 1);


      SELECT ABS (ADVVDBBAL_PRIN_AC_OPBAL)
        INTO V_ASON_AC_BAL
        FROM ADVVDBBAL
       WHERE     ADVVDBBAL_ENTITY_NUM = 1
             AND ADVVDBBAL_INTERNAL_ACNUM = P_INTERNAL_ACNUM
             AND ADVVDBBAL_YEAR = W_YEAR
             AND ADVVDBBAL_MONTH = W_MONTH;

      RETURN V_ASON_AC_BAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END FN_GET_RUN_PRINCIPLE_ACBAL;


   FUNCTION GET_DISB_AMT (P_AC_NUM           NUMBER,
                          P_RUN_CONT_FLAG    NUMBER,
                          P_FROM_DATE        DATE,
                          P_TO_DATE          DATE)
      RETURN NUMBER
   AS
      V_SQL                 VARCHAR2 (2000);
      V_TOTAL_DISB_AMOUNT   NUMBER;
   BEGIN
      IF P_RUN_CONT_FLAG = 1
      THEN
         --EXECUTE IMMEDIATE V_SQL INTO V_TOTAL_DISB_AMOUNT USING P_AC_NUM,P_TO_DATE, P_TO_DATE,P_AC_NUM,P_FROM_DATE, P_FROM_DATE ;
         V_TOTAL_DISB_AMOUNT :=
            FN_GET_RUN_PRINCIPLE_ACBAL (1, P_AC_NUM, P_TO_DATE);
      ELSE
         SELECT SUM (LNACDISB_DISB_AMT)
           INTO V_TOTAL_DISB_AMOUNT
           FROM LNACDISB
          WHERE     LNACDISB_ENTITY_NUM = 1
                AND LNACDISB_INTERNAL_ACNUM = P_AC_NUM
                AND LNACDISB_DISB_ON <= P_TO_DATE
                AND LNACDISB_AUTH_BY IS NOT NULL;
      END IF;

      RETURN V_TOTAL_DISB_AMOUNT;
   END GET_DISB_AMT;


   FUNCTION GET_DEFAULT_IN_LIFE (P_AC_NUM NUMBER)
      RETURN VARCHAR2
   AS
      V_DEFAULT_IN_LIFE   VARCHAR2 (5);
   BEGIN
      BEGIN
         SELECT CASE WHEN COUNTER >= 1 THEN 'YES' ELSE 'NO' END DEFAULTER
           INTO V_DEFAULT_IN_LIFE
           FROM (SELECT COUNT (1) COUNTER
                   FROM ASSETCLSHIST AH
                  WHERE     AH.ASSETCLSH_INTERNAL_ACNUM = P_AC_NUM
                        AND AH.ASSETCLSH_NPA_DATE IS NOT NULL);
      EXCEPTION
         WHEN OTHERS
         THEN
            V_DEFAULT_IN_LIFE := 'NO';
      END;

      RETURN V_DEFAULT_IN_LIFE;
   END GET_DEFAULT_IN_LIFE;


   FUNCTION GET_CUMULTV_RECOV (P_AC_NUM           NUMBER,
                               P_RUN_CONT_FLAG    NUMBER,
                               P_FROM_DATE        DATE,
                               P_TO_DATE          DATE,
                               P_EXP_DATE         DATE)
      RETURN NUMBER
   AS
      V_SQL                    VARCHAR2 (2000);
      V_CUMULTV_RECOV_AMOUNT   NUMBER := 0;
      V_CREDIT_BEFORE_EXPIRY   NUMBER;
      W_YEAR                   NUMBER;
   BEGIN
      IF P_RUN_CONT_FLAG = 1
      THEN
         V_SQL :=
            'SELECT   (SELECT NVL (
                    (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) CR
                       FROM ACNTBBAL
                      WHERE     ACNTBBAL_ENTITY_NUM = 1
                            AND ACNTBBAL_INTERNAL_ACNUM = :1
                            AND ACNTBBAL_YEAR =
                                   TO_NUMBER (TO_CHAR (:2 + 1, ''YYYY''))
                            AND ACNTBBAL_MONTH =
                                   TO_NUMBER (TO_CHAR (:3 + 1, ''MM''))),
                    0)
            FROM DUAL)
       - (SELECT NVL (
                    (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) CR
                       FROM ACNTBBAL
                      WHERE     ACNTBBAL_ENTITY_NUM = 1
                            AND ACNTBBAL_INTERNAL_ACNUM = :4
                            AND ACNTBBAL_YEAR =
                                   TO_NUMBER (TO_CHAR (:5, ''YYYY''))
                            AND ACNTBBAL_MONTH =
                                   TO_NUMBER (TO_CHAR (:6, ''MM''))),
                    0)
            FROM DUAL)
          TOTAL_RECOVERY_BALANCE
  FROM DUAL';

         EXECUTE IMMEDIATE V_SQL
            INTO V_CUMULTV_RECOV_AMOUNT
            USING P_AC_NUM,
                  P_TO_DATE,
                  P_TO_DATE,
                  P_AC_NUM,
                  P_EXP_DATE,
                  P_EXP_DATE;

         BEGIN
            W_YEAR := TO_NUMBER (TO_CHAR (P_EXP_DATE, 'YYYY'));
            V_SQL :=
                  'SELECT NVL( SUM(TRAN_AMOUNT), 0) FROM TRAN'
               || W_YEAR
               || ' WHERE TRAN_ENTITY_NUM = 1
AND TRAN_INTERNAL_ACNUM = :1
AND TRAN_DATE_OF_TRAN BETWEEN TRUNC( :2, ''MM'') AND :3
AND TRAN_DB_CR_FLG = ''C''';

            EXECUTE IMMEDIATE V_SQL
               INTO V_CREDIT_BEFORE_EXPIRY
               USING P_AC_NUM, P_EXP_DATE, P_EXP_DATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               V_CREDIT_BEFORE_EXPIRY := 0;
         END;

         V_CUMULTV_RECOV_AMOUNT :=
            V_CUMULTV_RECOV_AMOUNT - V_CREDIT_BEFORE_EXPIRY;
      ELSE
         V_SQL :=
            'SELECT NVL (
          (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) FROM_DATE_BALANCE
             FROM ACNTBBAL
            WHERE     ACNTBBAL_ENTITY_NUM = 1
                  AND ACNTBBAL_INTERNAL_ACNUM = :1
                  AND ACNTBBAL_YEAR = TO_NUMBER (TO_CHAR (:2 + 1, ''YYYY''))
                  AND ACNTBBAL_MONTH = TO_NUMBER (TO_CHAR (:3 + 1, ''MM''))),
          0)
          TOTAL_CREDIT
  FROM DUAL';

         EXECUTE IMMEDIATE V_SQL
            INTO V_CUMULTV_RECOV_AMOUNT
            USING P_AC_NUM, P_TO_DATE, P_TO_DATE;
      END IF;

      RETURN V_CUMULTV_RECOV_AMOUNT;
   END GET_CUMULTV_RECOV;

   FUNCTION GET_OUTSTANDING_BALANCE (P_AC_NUM NUMBER, P_FIN_YEAR NUMBER , P_FIN_MONTH NUMBER ) RETURN NUMBER 
   AS
   V_OUTSTANDING_BAL NUMBER(18,3);
   BEGIN
   BEGIN
   
   SELECT 
        ABS(NVL(NVL(ACNTBBAL_AC_OPNG_CR_SUM, 0) -
               NVL(ACNTBBAL_BC_OPNG_DB_SUM, 0),
               0)) INTO V_OUTSTANDING_BAL
               FROM ACNTBBAL WHERE ACNTBBAL_ENTITY_NUM = 1
               AND ACNTBBAL_INTERNAL_ACNUM = P_AC_NUM
               AND ACNTBBAL_YEAR = P_FIN_YEAR
               AND ACNTBBAL_MONTH = P_FIN_MONTH; 
   EXCEPTION WHEN OTHERS THEN 
       V_OUTSTANDING_BAL := 0;
   END ;
   RETURN V_OUTSTANDING_BAL;
   END GET_OUTSTANDING_BALANCE ;
   

   FUNCTION GET_RECOVERY_FORMULA (P_AC_NUM           NUMBER,
                                  P_RUN_CONT_FLAG    NUMBER,
                                  P_FROM_DATE        DATE,
                                  P_TO_DATE          DATE,
                                  P_EXP_DATE         DATE)
      RETURN NUMBER
   AS
      V_SQL                    VARCHAR2 (2000);
      V_TOTAL_PRIN_DB_AMOUNT   NUMBER := 0;
      W_YEAR                   NUMBER (4);
      V_CREDIT_BEFORE_EXPIRY   NUMBER;
   BEGIN
      IF P_RUN_CONT_FLAG = 1
      THEN
         IF P_TO_DATE < P_EXP_DATE
         THEN                        --- --- continious before expiry date----
            V_SQL :=
               'SELECT   (SELECT NVL (
                    (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) - NVL (ACNTBBAL_BC_OPNG_DB_SUM, 0) FROM_DATE_BALANCE
                       FROM ACNTBBAL
                      WHERE     ACNTBBAL_ENTITY_NUM = 1
                            AND ACNTBBAL_INTERNAL_ACNUM = :1
                            AND ACNTBBAL_YEAR =
                                   TO_NUMBER (TO_CHAR (:2, ''YYYY''))
                            AND ACNTBBAL_MONTH =
                                   TO_NUMBER (TO_CHAR (:3, ''MM''))),
                    0)
            FROM DUAL)
       - (SELECT NVL (
                    (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) - NVL (ACNTBBAL_BC_OPNG_DB_SUM, 0) TO_DATE_BALANCE
                       FROM ACNTBBAL
                      WHERE     ACNTBBAL_ENTITY_NUM = 1
                            AND ACNTBBAL_INTERNAL_ACNUM = :4
                            AND ACNTBBAL_YEAR =
                                   TO_NUMBER (TO_CHAR (:5 + 1, ''YYYY''))
                            AND ACNTBBAL_MONTH =
                                   TO_NUMBER (TO_CHAR (:6 + 1, ''MM''))),
                    0)
            FROM DUAL)
          TOTAL_RECOVERY_BALANCE
  FROM DUAL';

            EXECUTE IMMEDIATE V_SQL
               INTO V_TOTAL_PRIN_DB_AMOUNT
               USING P_AC_NUM,
                     P_FROM_DATE,
                     P_FROM_DATE,
                     P_AC_NUM,
                     P_TO_DATE,
                     P_TO_DATE;

            V_TOTAL_PRIN_DB_AMOUNT := (-1) * V_TOTAL_PRIN_DB_AMOUNT;

            IF V_TOTAL_PRIN_DB_AMOUNT < 0
            THEN
               V_TOTAL_PRIN_DB_AMOUNT := 0;
            END IF;
         ELSE                             --- continious after expiry date----
            V_SQL :=
               'SELECT   (SELECT NVL (
                    (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) CR
                       FROM ACNTBBAL
                      WHERE     ACNTBBAL_ENTITY_NUM = 1
                            AND ACNTBBAL_INTERNAL_ACNUM = :1
                            AND ACNTBBAL_YEAR =
                                   TO_NUMBER (TO_CHAR (:2 + 1, ''YYYY''))
                            AND ACNTBBAL_MONTH =
                                   TO_NUMBER (TO_CHAR (:3 + 1, ''MM''))),
                    0)
            FROM DUAL)
       - (SELECT NVL (
                    (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) CR
                       FROM ACNTBBAL
                      WHERE     ACNTBBAL_ENTITY_NUM = 1
                            AND ACNTBBAL_INTERNAL_ACNUM = :4
                            AND ACNTBBAL_YEAR =
                                   TO_NUMBER (TO_CHAR (:5, ''YYYY''))
                            AND ACNTBBAL_MONTH =
                                   TO_NUMBER (TO_CHAR (:6, ''MM''))),
                    0)
            FROM DUAL)
          TOTAL_RECOVERY_BALANCE
  FROM DUAL';

            EXECUTE IMMEDIATE V_SQL
               INTO V_TOTAL_PRIN_DB_AMOUNT
               USING P_AC_NUM,
                     P_TO_DATE,
                     P_TO_DATE,
                     P_AC_NUM,
                     P_EXP_DATE,
                     P_EXP_DATE;

            BEGIN
               W_YEAR := TO_NUMBER (TO_CHAR (P_EXP_DATE, 'YYYY'));
               V_SQL :=
                     'SELECT NVL( SUM(TRAN_AMOUNT), 0) FROM TRAN'
                  || W_YEAR
                  || ' WHERE TRAN_ENTITY_NUM = 1
AND TRAN_INTERNAL_ACNUM = :1
AND TRAN_DATE_OF_TRAN BETWEEN TRUNC( :2, ''MM'') AND :3
AND TRAN_DB_CR_FLG = ''C''';

               EXECUTE IMMEDIATE V_SQL
                  INTO V_CREDIT_BEFORE_EXPIRY
                  USING P_AC_NUM, P_EXP_DATE, P_EXP_DATE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_CREDIT_BEFORE_EXPIRY := 0;
            END;

            V_TOTAL_PRIN_DB_AMOUNT :=
               V_TOTAL_PRIN_DB_AMOUNT - V_CREDIT_BEFORE_EXPIRY;
         END IF;
      ELSE                                                       --- term loan
         V_SQL :=
            'SELECT   (SELECT NVL (
                    (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) CR
                       FROM ACNTBBAL
                      WHERE     ACNTBBAL_ENTITY_NUM = 1
                            AND ACNTBBAL_INTERNAL_ACNUM = :1
                            AND ACNTBBAL_YEAR =
                                   TO_NUMBER (TO_CHAR (:2 + 1, ''YYYY''))
                            AND ACNTBBAL_MONTH =
                                   TO_NUMBER (TO_CHAR (:3 + 1, ''MM''))),
                    0)
            FROM DUAL)
       - (SELECT NVL (
                    (SELECT NVL (ACNTBBAL_BC_OPNG_CR_SUM, 0) CR
                       FROM ACNTBBAL
                      WHERE     ACNTBBAL_ENTITY_NUM = 1
                            AND ACNTBBAL_INTERNAL_ACNUM = :4
                            AND ACNTBBAL_YEAR =
                                   TO_NUMBER (TO_CHAR (:5, ''YYYY''))
                            AND ACNTBBAL_MONTH =
                                   TO_NUMBER (TO_CHAR (:6, ''MM''))),
                    0)
            FROM DUAL)
          TOTAL_RECOVERY_BALANCE
  FROM DUAL';

         EXECUTE IMMEDIATE V_SQL
            INTO V_TOTAL_PRIN_DB_AMOUNT
            USING P_AC_NUM,
                  P_TO_DATE,
                  P_TO_DATE,
                  P_AC_NUM,
                  P_FROM_DATE,
                  P_FROM_DATE;
      END IF;

      RETURN V_TOTAL_PRIN_DB_AMOUNT;
   END GET_RECOVERY_FORMULA;



   FUNCTION GET_PRIN_DB_AMT (P_AC_NUM           NUMBER,
                             P_RUN_CONT_FLAG    NUMBER,
                             P_FROM_DATE        DATE,
                             P_TO_DATE          DATE)
      RETURN NUMBER
   AS
      V_SQL                    VARCHAR2 (2000);
      V_TOTAL_PRIN_DB_AMOUNT   NUMBER;
   BEGIN
      IF P_RUN_CONT_FLAG = 1
      THEN
         V_TOTAL_PRIN_DB_AMOUNT := 0;
      ELSE
         V_SQL :=
            'SELECT 
        (SELECT NVL(
        (SELECT NVL(ADVBBAL_PRIN_AC_DB_OPBAL,0) CR FROM ADVBBAL 
        WHERE ADVBBAL_ENTITY_NUM =1  
        AND ADVBBAL_INTERNAL_ACNUM = :1
        AND ADVBBAL_YEAR = TO_NUMBER(TO_CHAR (:2+1,''YYYY''))
        AND ADVBBAL_MONTH = TO_NUMBER(TO_CHAR(:3+1,''MM'')) ),0) FROM DUAL ) - 
        (SELECT NVL(
        (SELECT NVL(ADVBBAL_PRIN_AC_DB_OPBAL,0) CR FROM ADVBBAL 
        WHERE ADVBBAL_ENTITY_NUM =1  
        AND ADVBBAL_INTERNAL_ACNUM = :4
        AND ADVBBAL_YEAR = TO_NUMBER(TO_CHAR (:5,''YYYY''))
        AND ADVBBAL_MONTH = TO_NUMBER(TO_CHAR(:6,''MM'')) ),0) FROM DUAL) TOTAL_DEBIT_BALANCE FROM DUAL ';

         EXECUTE IMMEDIATE V_SQL
            INTO V_TOTAL_PRIN_DB_AMOUNT
            USING P_AC_NUM,
                  P_TO_DATE,
                  P_TO_DATE,
                  P_AC_NUM,
                  P_FROM_DATE,
                  P_FROM_DATE;
      END IF;

      RETURN V_TOTAL_PRIN_DB_AMOUNT;
   END GET_PRIN_DB_AMT;



   PROCEDURE GET_TOT_SEC_AMT_CBD
   IS
      V_LAD_SEC_AMT   NUMBER (18, 3);
   BEGIN
      W_SEC_TYPE_STR := '';
      W_SEC_NUM_STR := '';
      W_TOT_SEC_AMT_AC := 0;
      V_LAD_SEC_AMT := GET_LAD_SECURED_VALUE;

      IF V_IS_LAD_ACC
      THEN
         W_SEC_TYPE_STR := 'LAD';
         W_TOT_SEC_AMT_AC := V_LAD_SEC_AMT;
      ELSE
         FOR IDX_REC_SECBAL
            IN (SELECT SECAGMTBAL_ASSIGN_PERC, SECAGMTBAL_SEC_NUM
                  FROM SECASSIGNMTBAL
                 WHERE     SECAGMTBAL_ENTITY_NUM = 1
                       AND SECAGMTBAL_CLIENT_NUM = W_LIM_CLIENT
                       AND SECAGMTBAL_LIMIT_LINE_NUM = V_LIMIT_LINE_NUM)
         LOOP
            W_SEC_NUM := IDX_REC_SECBAL.SECAGMTBAL_SEC_NUM;

           <<FETCH_SECRCPT>>
            BEGIN
               SELECT SECRCPT_SEC_TYPE,
                      SECRCPT_CURR_CODE,
                      SECRCPT_SECURED_VALUE
                 INTO W_SEC_TYPE, W_SEC_CURR_CODE, W_SECURED_VALUE
                 FROM SECRCPT
                WHERE     SECRCPT_ENTITY_NUM = 1
                      AND SECRCPT_SECURITY_NUM = W_SEC_NUM;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  W_SECURED_VALUE := 0;
            END FETCH_SECRCPT;

            W_SEC_AMT_ACNT_CURR := W_SECURED_VALUE;
            W_TOT_SEC_AMT_AC := W_TOT_SEC_AMT_AC + W_SEC_AMT_ACNT_CURR;
            W_SEC_TYPE_STR := W_SEC_TYPE_STR || '  ' || W_SEC_TYPE || ' , ';
            W_SEC_NUM_STR := W_SEC_NUM_STR     --|| '  ' || W_SEC_NUM || ' , '
                                          ;
         END LOOP;
      END IF;
   END GET_TOT_SEC_AMT_CBD;

   FUNCTION GET_BRANCH_WISE (P_ENTITY_NUM    NUMBER,
                             P_BRN_CODE      NUMBER,
                             P_FROM_DATE     DATE,
                             P_TO_DATE       DATE)
      RETURN REC_TAB
      PIPELINED
   IS
      ---RETURN VARCHAR2 IS
      V_WRTOFF_DATE                    DATE;
      V_WRTOFF_APPROVAL_AUTH           VARCHAR2 (100);
      W_SL_NO                          NUMBER := 0;
      V_CL_MIS_CODE                    VARCHAR2 (20);
      V_CL_ECO_CODE                    VARCHAR2 (20);
      V_CL_SME_CODE                    VARCHAR2 (20);
      V_CL_SEG_CODE                    VARCHAR2 (20);

      V_LNACRSDTL_REPAY_FROM_DATE      DATE;
      V_LNACRSDTL_REPAY_FREQ           CHAR (1);
      V_LNACRSDTL_REPAY_AMT            NUMBER (18, 3);
      V_LNACRSDTL_NUM_OF_INSTALLMENT   NUMBER (5);
      V_NEXT_INSTLMNT_DATE             DATE;
      V_LAST_INSTLMNT_DATE             DATE;
      V_INSTLMNT_LEFT                  NUMBER (5);
      CN                               INTEGER;
      V_PREV_BRN_CODE                  MBRN.MBRN_CODE%TYPE;
      V_BRN_SBS_CODE                   MBRN.MBRN_BSR_CODE%TYPE;
      V_HO_DIVISION_NAME               MBRN.MBRN_NAME%TYPE;
      W_SQL_QUERY                      CLOB;
      V_FIN_YEAR                       NUMBER;
      V_FIN_MONTH                      NUMBER;
      V_FROM_DATE                      DATE;
      V_TO_DATE                        DATE;
      V_DEBIT_CASH                     NUMBER (18, 3);
      V_DEBIT_INT                      NUMBER (18, 3);
      V_DEBIT_OTHERS                   NUMBER (18, 3);
      V_CREDIT_CASH                    NUMBER (18, 3);
      V_CREDIT_INT                     NUMBER (18, 3);
      V_CREDIT_OTHERS                  NUMBER (18, 3);
      V_FIN_YEAR_TRAN                  NUMBER;
      V_FATHER_NAME                    VARCHAR2 (100);
      V_MOTHER_NAME                    VARCHAR2 (100);
      V_SPOUSE_NAME                    VARCHAR2 (100);
      V_CLIENTS_GENDER                 CHAR (1);
      V_DATE_OF_BIRTH                  VARCHAR2 (100);
      V_BIRTH_PLACE                    VARCHAR2 (100);
      V_CNTRY_CODE                     VARCHAR2 (10);
      V_BIRTH_COUNTRY                  VARCHAR2 (100);
      V_NID_NO                         VARCHAR2 (30);
      V_TIN_NO                         VARCHAR2 (30);
      V_OTHER_DOCU_TYP                 VARCHAR2 (30);
      V_OTHER_DOCU_NO                  VARCHAR2 (30);
      V_OTHER_DOCU_DATE                VARCHAR2 (30);
      V_OTHER_DOCU_CNTRY               VARCHAR2 (30);
      V_OCCUPN_CODE                    VARCHAR2 (6);
      V_EMPLOYEE_NUM                   VARCHAR2 (15);
      V_CLIENT_OCCUP                   VARCHAR2 (35);
      V_CNTRY_NAME                     VARCHAR2 (35);
      V_ADDR_TYPE                      VARCHAR2 (5);
      V_POST_CODE                      VARCHAR2 (6);
      V_MOBILE_NUM                     VARCHAR2 (15);
      V_LOC_NAME                       VARCHAR2 (50);
      V_DIST_NAME                      VARCHAR2 (50);
      V_CLASSIFICTN_CODE               ASSETCD.ASSETCD_BSR_CODE%TYPE;
      V_SCHEME_CODE                    LOANACNTS.LNACNT_PURPOSE_CODE%TYPE;
      V_PR_BAL                         NUMBER (18, 3);
      V_INT_BAL                        NUMBER (18, 3);
      V_OTH_BAL                        NUMBER (18, 3);
      V_NO_ENC                         NUMBER;
      V_ERROR                          VARCHAR2 (100);
      V_CLOSURE_DATE                   DATE ;
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (P_ENTITY_NUM);
      V_GLOB_ENTITY_NUM := PKG_ENTITY.FN_GET_ENTITY_CODE;
      V_PREV_BRN_CODE := 0;
      V_FROM_DATE := TO_DATE (P_FROM_DATE, 'DD-MM-YYYY');
      V_TO_DATE := TO_DATE (P_TO_DATE, 'DD-MM-YYYY');
      W_ASON_DATE := TO_DATE (P_TO_DATE, 'DD-MM-YYYY');
      W_BRN_CODE := NVL (TRIM (P_BRN_CODE), 0);

      V_FIN_YEAR_TRAN := TO_CHAR (P_TO_DATE, 'YYYY');
      V_FIN_YEAR := TO_NUMBER (TO_CHAR (P_TO_DATE + 1, 'YYYY'));
      V_FIN_MONTH := TO_NUMBER (TO_CHAR (P_TO_DATE + 1, 'MM'));

      SELECT MN_CURR_BUSINESS_DATE INTO V_CBD FROM MAINCONT;

      SELECT SUBSTR (M.MBRN_BSR_CODE, 3),
             (SELECT TRIM (B.MBRN_NAME)
                FROM MBRN B
               WHERE B.MBRN_CODE = M.MBRN_PARENT_ADMIN_CODE)
        INTO V_BRN_SBS_CODE, V_HO_DIVISION_NAME
        FROM MBRN M
       WHERE M.MBRN_CODE = W_BRN_CODE;

      T_TEMP_REC.DELETE;
      W_SQL_QUERY :=
            ' SELECT A.ACNTS_INTERNAL_ACNUM,
       A.ACNTS_CLIENT_NUM,
       NVL(TRIM(REGEXP_REPLACE(A.ACNTS_AC_NAME1 || A.ACNTS_AC_NAME2,
                               ''[^[:print:]]'',
                               '' '')),
           '' ''),
           NVL(ACNTS_CURR_CODE, ''BDT''),
       NVL(CLIENTS_SEGMENT_CODE, '' ''),
       NVL(P.PRODUCT_NAME, '' ''),
       NVL((SELECT RPTHDGLDTL_CODE
             FROM RPTHEAD H, RPTLAYOUTDTL, RPTHEADGLDTL D
            WHERE H.RPTHEAD_CODE = RPTLAYOUTDTL_RPT_HEAD_CODE
              AND D.RPTHDGLDTL_CODE = RPTLAYOUTDTL_RPT_HEAD_CODE
              AND D.RPTHDGLDTL_GLACC_CODE = ACNTS_GLACC_CODE
              AND RPTLAYOUTDTL_RPT_CODE = ''F12''
              AND H.RPTHEAD_CLASSIFICATION = ''A''),
           ''0''),
       NVL(PRODUCT_CODE, ''0''),
       NVL(CASE
             WHEN (SELECT LNACIRS_AC_LEVEL_INT_REQD
                     FROM LNACIRS
                    WHERE LNACIRS_ENTITY_NUM = :V_ENTITY_NUM
                      AND LNACIRS_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM) = ''1'' THEN
              (SELECT LNACIR_APPL_INT_RATE
                 FROM LNACIR
                WHERE LNACIR_ENTITY_NUM = :V_ENTITY_NUM
                  AND LNACIR_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM)
             ELSE
              (SELECT LL.LNPRODIRDTL_INT_RATE
                 FROM LNPRODIRDTL LL
                WHERE LNPRODIRDTL_ENTITY_NUM = :V_ENTITY_NUM
                  AND LL.LNPRODIRDTL_PROD_CODE = A.ACNTS_PROD_CODE
                  AND LL.LNPRODIRDTL_CURR_CODE = A.ACNTS_CURR_CODE
                  AND LL.LNPRODIRDTL_AC_TYPE = A.ACNTS_AC_TYPE
                  AND LL.LNPRODIRDTL_AC_SUB_TYPE = A.ACNTS_AC_SUB_TYPE)
           END,
           0),
       NVL(TRIM(FN_GET_SECURITY_CODE(:V_ENTITY_NUM,
                                             A.ACNTS_CLIENT_NUM,
                                             A.ACNTS_BRN_CODE,
                                             A.ACNTS_INTERNAL_ACNUM,
                                             A.ACNTS_PROD_CODE)),
           '' ''),
       
      (SELECT TO_CHAR(NVL(SUM(CASE
                         WHEN TR.TRAN_DB_cR_FLG = ''D'' AND TR.TRAN_TYPE_OF_TRAN = 3 THEN
                          TRA.TRANADV_PRIN_AC_AMT
                         ELSE
                          0
                       END),
                   0)) || ''A'' ||
               
               TO_CHAR(NVL(SUM(CASE
                         WHEN TR.TRAN_DB_cR_FLG = ''D'' THEN
                          TRA.TRANADV_INTRD_AC_AMT
                         ELSE
                          0
                       END),
                   0)) || ''B'' ||
               TO_CHAR(NVL((SUM(CASE
                          WHEN TR.TRAN_DB_cR_FLG = ''D'' THEN
                           TRA.TRANADV_CHARGE_AC_AMT
                          ELSE
                           0
                        END) + SUM(CASE
                                      WHEN TR.TRAN_DB_cR_FLG = ''D'' THEN
                                       TRA.TRANADV_PRIN_AC_AMT
                                      ELSE
                                       0
                                    END) -
                   SUM(CASE
                          WHEN TR.TRAN_DB_cR_FLG = ''D'' AND TR.TRAN_TYPE_OF_TRAN = 3 THEN
                           TRA.TRANADV_PRIN_AC_AMT
                          ELSE
                           0
                        END)),
                   0)) || ''C'' || TO_CHAR(NVL(SUM(CASE
                                          WHEN TR.TRAN_DB_cR_FLG = ''C'' AND TR.TRAN_TYPE_OF_TRAN = 3 THEN
                                           TRA.TRANADV_PRIN_AC_AMT
                                          ELSE
                                           0
                                        END),
                                    0)) || ''D'' ||
               TO_CHAR(NVL(SUM(CASE
                         WHEN TR.TRAN_DB_cR_FLG = ''C'' THEN
                          TRA.TRANADV_INTRD_AC_AMT
                         ELSE
                          0
                       END),
                   0)) || ''E'' || TO_CHAR(NVL((SUM(CASE
                                           WHEN TR.TRAN_DB_cR_FLG = ''C'' THEN
                                            TRA.TRANADV_CHARGE_AC_AMT
                                           ELSE
                                            0
                                         END) + SUM(CASE
                                                       WHEN TR.TRAN_DB_cR_FLG = ''C'' THEN
                                                        TRA.TRANADV_PRIN_AC_AMT
                                                       ELSE
                                                        0
                                                     END) -
                                    SUM(CASE
                                           WHEN TR.TRAN_DB_cR_FLG = ''C'' AND TR.TRAN_TYPE_OF_TRAN = 3 THEN
                                            TRA.TRANADV_PRIN_AC_AMT
                                           ELSE
                                            0
                                         END)),
                                    0)) || ''F''
              FROM TRANADV'
         || V_FIN_YEAR_TRAN
         || ' TRA , TRAN'
         || V_FIN_YEAR_TRAN
         || '  TR 
         WHERE TRA.TRANADV_ENTITY_NUM = :V_ENTITY_NUM
        AND TR.TRAN_ENTITY_NUM = :V_ENTITY_NUM
           AND TRA.TRANADV_BRN_CODE = TR.TRAN_ACING_BRN_CODE
           AND TRA.TRANADV_DATE_OF_TRAN = TR.TRAN_DATE_OF_TRAN
           AND TRA.TRANADV_BATCH_NUMBER = TR.TRAN_BATCH_NUMBER
           AND TRA.TRANADV_BATCH_SL_NUM = TR.TRAN_BATCH_SL_NUM
           AND TRA.TRANADV_BRN_CODE = A.ACNTS_BRN_CODE
           AND TR.TRAN_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
           AND TR.TRAN_DATE_OF_TRAN BETWEEN :V_FROM_DATE AND :V_TO_DATE
           AND TR.TRAN_AUTH_ON IS NOT NULL
           AND (NVL(TR.TRAN_AC_CANCEL_AMT, 0) = 0 OR
               NVL(TR.TRAN_BC_CANCEL_AMT, 0) = 0)),
       NVL((SELECT LNOD_OD_AMT
             FROM LNOD
            WHERE LNOD_ENTITY_NUM = :V_ENTITY_NUM
              AND LNOD_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM),
           0),
       --ABS(NVL(NVL(ACNTBBAL_AC_OPNG_CR_SUM, 0) -
               --NVL(ACNTBBAL_BC_OPNG_DB_SUM, 0),
               --0)),
       NVL(C.CLIENTS_BORROWER_CODE, 0),
       NVL(C.CLIENTS_FIS_CODE, 0),
       PRODUCT_FOR_RUN_ACS,
       A.ACNTS_CLOSURE_DATE
  FROM PRODUCTS P, ACNTS A, CLIENTS C--, ACNTBBAL Q
 WHERE A.ACNTS_ENTITY_NUM = :V_ENTITY_NUM
   --AND Q.ACNTBBAL_ENTITY_NUM = :V_ENTITY_NUM
   --AND Q.ACNTBBAL_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
   --AND A.ACNTS_INTERNAL_ACNUM = 10111500007742 
   AND P.PRODUCT_CODE = A.ACNTS_PROD_CODE
   AND P.PRODUCT_FOR_LOANS = ''1''
   AND C.CLIENTS_CODE = A.ACNTS_CLIENT_NUM
   AND A.ACNTS_AUTH_ON IS NOT NULL
   AND (A.ACNTS_CLOSURE_DATE IS NULL OR A.ACNTS_CLOSURE_DATE >= :V_FROM_DATE)
   --AND ACNTBBAL_CURR_CODE = A.ACNTS_CURR_CODE
   --AND ACNTBBAL_YEAR = :V_FIN_YEAR 
   --AND ACNTBBAL_MONTH = :V_FIN_MONTH
   --AND ABS(NVL(NVL(ACNTBBAL_AC_OPNG_CR_SUM, 0) -
               --NVL(ACNTBBAL_BC_OPNG_DB_SUM, 0),
               --0)) <> 0 
               ';

      IF W_BRN_CODE <> 0
      THEN
         W_SQL_QUERY :=
            W_SQL_QUERY || TO_CLOB (' AND A.ACNTS_BRN_CODE = ' || W_BRN_CODE);
      END IF;


      W_SQL_QUERY :=
            W_SQL_QUERY
         || TO_CLOB (
               ' ORDER BY A.ACNTS_BRN_CODE, A.ACNTS_INTERNAL_ACNUM , P.PRODUCT_CODE ');
               
      --dbms_output.put_line (W_SQL_QUERY);

      EXECUTE IMMEDIATE W_SQL_QUERY
         BULK COLLECT INTO T_TEMP_REC
         USING V_GLOB_ENTITY_NUM,
               V_GLOB_ENTITY_NUM,
               V_GLOB_ENTITY_NUM,
               V_GLOB_ENTITY_NUM,
               V_GLOB_ENTITY_NUM,
               V_GLOB_ENTITY_NUM,
               P_FROM_DATE,
               P_TO_DATE,
               V_GLOB_ENTITY_NUM,
               V_GLOB_ENTITY_NUM,
               P_FROM_DATE;

      IF T_TEMP_REC.FIRST IS NOT NULL
      THEN
         FOR REC IN T_TEMP_REC.FIRST .. T_TEMP_REC.LAST
         LOOP
            /*        IF V_PREV_BRN_CODE <> W_BRN_CODE THEN
              TEMP_DATA.BRN_SBS_CODE := '';
              TEMP_DATA.PROD_CODE    := '';
              TEMP_DATA.PROD_NAME    := '';
              TEMP_DATA.ACC_NO       := '';
              TEMP_DATA.ACC_NAME     := '';
              --  TEMP_DATA.REPAY_START_DATE  := '';
              TEMP_DATA.REPAY_FREQ        := '';
              TEMP_DATA.INSTALL_AMT       := '';
              TEMP_DATA.NO_OF_INSTALLMENT := '';
              TEMP_DATA.SANC_RESCHE_DATE  := '';
              TEMP_DATA.SANC_RESCHE_AMT   := '';
              --   TEMP_DATA.DISBURSE_DATE     := '';
              TEMP_DATA.TOTAL_DISBURSE := '';
              TEMP_DATA.EXPIRY_DATE    := '';
              TEMP_DATA.SEC_CODE       := '';
              TEMP_DATA.ECO_PURP_CODE  := '';
              TEMP_DATA.SME_CODE       := '';
              TEMP_DATA.SEGMENT_CODE   := '';
              TEMP_DATA.CL_CODE        := '';

              --  TEMP_DATA.SEC_NUM         := '';
              TEMP_DATA.OUTSTANDING_BAL := '';
              TEMP_DATA.CLOSED_DATE     := '';
              TEMP_DATA.CLIENT_CODE     := '';

              V_PREV_BRN_CODE := T_TEMP_REC(REC).ACNTS_BRN_CODE;

              --    TEMP_DATA.BRN_CODE_TITLE := '';
              --     TEMP_DATA.BRN_NAME_TITLE := '';

            END IF;*/

            CN := 0;
            V_CLOSURE_DATE := '' ;

            /* SELECT COUNT(*)
               INTO CN
               FROM LNWRTOFF
              WHERE LNWRTOFF_ACNT_NUM = T_TEMP_REC(REC).T_AC_NUM;

             IF CN > 0 THEN
              CONTINUE;
             END IF;*/

            V_LIMIT_SAUTH_CODE := NULL;
            V_APPROVAL_AUTH := NULL;
            W_SL_NO := W_SL_NO + 1;
            W_LIM_CLIENT := T_TEMP_REC (REC).T_CLIENT_CODE;
            W_INTERNAL_ACNUM := T_TEMP_REC (REC).T_AC_NUM;
            V_CLOSURE_DATE := T_TEMP_REC (REC).T_ACNTS_CLOSURE_DATE ;

            TEMP_DATA.SL_NO := W_SL_NO;
            TEMP_DATA.REPORTING_DATE := V_TO_DATE;
            TEMP_DATA.BRN_SBS_CODE := V_BRN_SBS_CODE;
            TEMP_DATA.HO_DIVISION_NAME := V_HO_DIVISION_NAME;
            TEMP_DATA.PROD_CODE := T_TEMP_REC (REC).T_PROD_CODE;
            TEMP_DATA.PROD_NAME := T_TEMP_REC (REC).T_PROD_NAME;
            TEMP_DATA.CLIENT_CODE := T_TEMP_REC (REC).T_CLIENT_CODE;
            TEMP_DATA.ACC_NO := FACNO (1, W_INTERNAL_ACNUM);
            TEMP_DATA.ACC_NAME := T_TEMP_REC (REC).T_AC_NAME;
            TEMP_DATA.SEGMENT_CODE := T_TEMP_REC (REC).T_SECTOR_CODE;
            TEMP_DATA.LOAN_CODE := T_TEMP_REC (REC).T_LOAN_CODE;
            TEMP_DATA.INT_RATE := T_TEMP_REC (REC).T_INT_RATE;
            TEMP_DATA.SEC_CODE := T_TEMP_REC (REC).T_SECURITY_CODE;
            TEMP_DATA.OD_AMOUNT := T_TEMP_REC (REC).T_OD_AMT;
            TEMP_DATA.OUTSTANDING_BAL := GET_OUTSTANDING_BALANCE(W_INTERNAL_ACNUM,V_FIN_YEAR, V_FIN_MONTH);--T_TEMP_REC (REC).T_OUTSTANDING_BAL;

            IF T_TEMP_REC (REC).T_BORROWER_CODE <> 0
            THEN
               TEMP_DATA.BORROWER_FIS_CODE := T_TEMP_REC (REC).T_BORROWER_CODE;
            ELSE
               TEMP_DATA.BORROWER_FIS_CODE := T_TEMP_REC (REC).T_FIS_CODE;
            END IF;

            SELECT SUBSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL,
                           1,
                           INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'A') - 1),
                   SUBSTR (
                      T_TEMP_REC (REC).T_DB_CR_TOTAL,
                      INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'A') + 1,
                        INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'B')
                      - INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'A')
                      - 1),
                   SUBSTR (
                      T_TEMP_REC (REC).T_DB_CR_TOTAL,
                      INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'B') + 1,
                        INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'C')
                      - INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'B')
                      - 1),
                   SUBSTR (
                      T_TEMP_REC (REC).T_DB_CR_TOTAL,
                      INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'C') + 1,
                        INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'D')
                      - INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'C')
                      - 1),
                   SUBSTR (
                      T_TEMP_REC (REC).T_DB_CR_TOTAL,
                      INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'D') + 1,
                        INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'E')
                      - INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'D')
                      - 1),
                   SUBSTR (
                      T_TEMP_REC (REC).T_DB_CR_TOTAL,
                      INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'E') + 1,
                        INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'F')
                      - INSTR (T_TEMP_REC (REC).T_DB_CR_TOTAL, 'E')
                      - 1)
              INTO V_DEBIT_CASH,
                   V_DEBIT_INT,
                   V_DEBIT_OTHERS,
                   V_CREDIT_CASH,
                   V_CREDIT_INT,
                   V_CREDIT_OTHERS
              FROM DUAL;

            TEMP_DATA.DEBIT_CASH := V_DEBIT_CASH;
            TEMP_DATA.DEBIT_INT := V_DEBIT_INT;
            TEMP_DATA.DEBIT_OTHERS := V_DEBIT_OTHERS;
            TEMP_DATA.CREDIT_CASH := V_CREDIT_CASH;
            TEMP_DATA.CREDIT_INT := V_CREDIT_INT;
            TEMP_DATA.CREDIT_OTHERS := V_CREDIT_OTHERS;

            -- LIMIT LINE
            BEGIN
               SELECT LMTLINE_DATE_OF_SANCTION,
                      LMTLINE_SANCTION_AMT,
                      LMTLINE_LIMIT_EXPIRY_DATE,
                      LMTLINE_NUM,
                      LMTLINE_SAUTH_CODE
                 INTO V_LIMIT_RESCH_DATE,
                      V_LIMIT_RESCH_AMT,
                      V_EXP_DATE,
                      V_LIMIT_LINE_NUM,
                      V_LIMIT_SAUTH_CODE
                 FROM LIMITLINE
                WHERE     LMTLINE_CLIENT_CODE =
                             T_TEMP_REC (REC).T_CLIENT_CODE
                      AND LIMITLINE.LMTLINE_NUM =
                             (SELECT ACASLLDTL.ACASLLDTL_LIMIT_LINE_NUM
                                FROM ACASLLDTL
                               WHERE ACASLLDTL_INTERNAL_ACNUM =
                                        W_INTERNAL_ACNUM);

               TEMP_DATA.EXPIRY_DATE := TO_CHAR (V_EXP_DATE, 'MM/DD/YYYY');
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  TEMP_DATA.EXPIRY_DATE := ' ';
                  V_LIMIT_RESCH_DATE := NULL;
                  V_LIMIT_RESCH_AMT := 0;
                  V_EXP_DATE := NULL;
                  V_LIMIT_LINE_NUM := NULL;
            END;

            BEGIN
               SELECT SAUTH_NAME
                 INTO V_APPROVAL_AUTH
                 FROM SAUTH
                WHERE     SAUTH_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND SAUTH_CODE = V_LIMIT_SAUTH_CODE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_APPROVAL_AUTH := NULL;
            END;

            TEMP_DATA.LN_SANC_AUTH := V_APPROVAL_AUTH;
            V_APPROVAL_AUTH := NULL;
            V_LIMIT_SAUTH_CODE := NULL;

            -- END

            -- LIMITLINEHIST
            BEGIN
               SELECT COUNT (1)
                 INTO W_COUNTER
                 FROM LIMITLINEHIST
                WHERE     LIMLNEHIST_CLIENT_CODE =
                             T_TEMP_REC (REC).T_CLIENT_CODE
                      AND LIMLNEHIST_LIMIT_LINE_NUM =
                             (SELECT ACASLLDTL.ACASLLDTL_LIMIT_LINE_NUM
                                FROM ACASLLDTL
                               WHERE ACASLLDTL_INTERNAL_ACNUM =
                                        W_INTERNAL_ACNUM)
                      AND LIMLNEHIST_EFF_DATE <= P_TO_DATE;

               IF W_COUNTER > 1
               THEN
                  V_NEWEAL_TIME := W_COUNTER - 1;

                  SELECT LIMLNEHIST_SAUTH_CODE,
                         LIMLNEHIST_EFF_DATE,
                         MIN_SANC_AMT,
                         MIN_SANC_DATE,
                         ENHANCEMENT
                    INTO V_LIMIT_SAUTH_CODE,
                         V_EFF_DATE,
                         V_FIRST_SANC_LIMIT,
                         V_FIRST_SANC_DATE,
                         V_ENHNC_AMT
                    FROM (  SELECT L.LIMLNEHIST_SAUTH_CODE,
                                   L.LIMLNEHIST_EFF_DATE,
                                   LEAD (LIMLNEHIST_SANCTION_AMT,
                                         V_NEWEAL_TIME)
                                   OVER (ORDER BY LIMLNEHIST_EFF_DATE DESC)
                                      MIN_SANC_AMT,
                                   LEAD (LIMLNEHIST_DATE_OF_SANCTION,
                                         V_NEWEAL_TIME)
                                   OVER (ORDER BY LIMLNEHIST_EFF_DATE DESC)
                                      MIN_SANC_DATE,
                                     LIMLNEHIST_SANCTION_AMT
                                   - LEAD (LIMLNEHIST_SANCTION_AMT, 1)
                                     OVER (ORDER BY LIMLNEHIST_EFF_DATE DESC)
                                      ENHANCEMENT
                              FROM LIMITLINEHIST L
                             WHERE     LIMLNEHIST_CLIENT_CODE =
                                          T_TEMP_REC (REC).T_CLIENT_CODE
                                   AND LIMLNEHIST_LIMIT_LINE_NUM =
                                          (SELECT ACASLLDTL.ACASLLDTL_LIMIT_LINE_NUM
                                             FROM ACASLLDTL
                                            WHERE ACASLLDTL_INTERNAL_ACNUM =
                                                     W_INTERNAL_ACNUM)
                                   AND LIMLNEHIST_EFF_DATE <= P_TO_DATE
                          ORDER BY LIMLNEHIST_EFF_DATE DESC) A
                   WHERE A.MIN_SANC_DATE IS NOT NULL;

                  BEGIN
                     SELECT SAUTH_NAME
                       INTO V_APPROVAL_AUTH
                       FROM SAUTH
                      WHERE     SAUTH_ENTITY_NUM = 1
                            AND SAUTH_CODE = V_LIMIT_SAUTH_CODE;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        V_APPROVAL_AUTH := NULL;
                  END;
               ELSIF W_COUNTER = 1
               THEN
                  SELECT LIMLNEHIST_DATE_OF_SANCTION, LIMLNEHIST_SANCTION_AMT
                    INTO V_FIRST_SANC_DATE, V_FIRST_SANC_LIMIT
                    FROM LIMITLINEHIST
                   WHERE     LIMLNEHIST_CLIENT_CODE =
                                T_TEMP_REC (REC).T_CLIENT_CODE
                         AND LIMLNEHIST_EFF_DATE =
                                (SELECT MIN (
                                           LIMITLINEHIST.LIMLNEHIST_EFF_DATE)
                                   FROM LIMITLINEHIST
                                  WHERE     LIMLNEHIST_CLIENT_CODE =
                                               T_TEMP_REC (REC).T_CLIENT_CODE
                                        AND LIMITLINEHIST.LIMLNEHIST_LIMIT_LINE_NUM =
                                               (SELECT ACASLLDTL.ACASLLDTL_LIMIT_LINE_NUM
                                                  FROM ACASLLDTL
                                                 WHERE ACASLLDTL_INTERNAL_ACNUM =
                                                          W_INTERNAL_ACNUM))
                         AND LIMITLINEHIST.LIMLNEHIST_LIMIT_LINE_NUM =
                                (SELECT ACASLLDTL.ACASLLDTL_LIMIT_LINE_NUM
                                   FROM ACASLLDTL
                                  WHERE ACASLLDTL_INTERNAL_ACNUM =
                                           W_INTERNAL_ACNUM);

                  V_LIMIT_SAUTH_CODE := NULL;
                  V_EFF_DATE := NULL;
                  V_ENHNC_AMT := NULL;
                  V_APPROVAL_AUTH := NULL;
                  V_NEWEAL_TIME := 0;
               ELSE
                  V_FIRST_SANC_LIMIT := NULL;
                  V_FIRST_SANC_DATE := NULL;
                  V_LIMIT_SAUTH_CODE := NULL;
                  V_APPROVAL_AUTH := NULL;
                  V_EFF_DATE := NULL;
                  V_ENHNC_AMT := NULL;
                  V_NEWEAL_TIME := 0;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_FIRST_SANC_LIMIT := NULL;
                  V_FIRST_SANC_DATE := NULL;
                  V_LIMIT_SAUTH_CODE := NULL;
                  V_APPROVAL_AUTH := NULL;
                  V_EFF_DATE := NULL;
                  V_ENHNC_AMT := NULL;
                  V_NEWEAL_TIME := NULL;
            END;

            TEMP_DATA.FIRST_SANC_DATE := V_FIRST_SANC_DATE;
            TEMP_DATA.FIRST_SANC_LIMIT := V_FIRST_SANC_LIMIT;
            TEMP_DATA.RENW_APPROV_AUTH := V_APPROVAL_AUTH;
            TEMP_DATA.RENW_DATE := V_EFF_DATE;
            TEMP_DATA.RENW_TIME := V_NEWEAL_TIME;

            IF V_ENHNC_AMT > 0 AND T_TEMP_REC (REC).T_PRODUCT_FOR_RUN_ACS = 1
            THEN
               TEMP_DATA.RENW_WITH_ENHNC := '1';
               TEMP_DATA.ENHNC_APPROV_AUTH := V_APPROVAL_AUTH;
               TEMP_DATA.ENHNC_DATE := V_EFF_DATE;
               TEMP_DATA.ENHNC_PORSION := V_ENHNC_AMT;
            ELSE
               TEMP_DATA.RENW_WITH_ENHNC := '0';
               TEMP_DATA.ENHNC_APPROV_AUTH := NULL;
               TEMP_DATA.ENHNC_DATE := NULL;
               TEMP_DATA.ENHNC_PORSION := NULL;
            END IF;

            ---- CLASSIFICATION_CODE  assetcls
            BEGIN
               SELECT NVL (TRIM (ASSETCD_BSR_CODE), ' ')
                 INTO V_CLASSIFICTN_CODE
                 FROM ASSETCLS, ASSETCD
                WHERE     ASSETCLS_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND ASSETCLS_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                      AND ASSETCD_CODE = ASSETCLS_ASSET_CODE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_CLASSIFICTN_CODE := NULL;
            END;

            TEMP_DATA.CLASSIFICATION_CODE := V_CLASSIFICTN_CODE;

            ---

            -- SCHEME CODE

            BEGIN
               SELECT NVL (TRIM (LNACNT_PURPOSE_CODE), ' ')
                 INTO V_SCHEME_CODE
                 FROM LOANACNTS
                WHERE     LNACNT_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND LNACNT_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_SCHEME_CODE := NULL;
            END;

            TEMP_DATA.LOAN_SCHEME_CODE := V_SCHEME_CODE;

            -- SANC
            BEGIN
               SELECT LNACRS_REPH_ON_AMT,
                      LNACRS_REPHASEMENT_ENTRY,
                      LNACRS_SANC_DATE
                 INTO V_RESCHEDULE_AMT,
                      V_IS_RESCHEDULE_ACC,
                      V_RESCHEDULE_SANC_DATE
                 FROM LNACRS
                WHERE LNACRS_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_RESCHEDULE_AMT := NULL;
                  V_IS_RESCHEDULE_ACC := NULL;
                  V_RESCHEDULE_SANC_DATE := NULL;
            END;

            -- DISBURSE
            --FN_GET_RUN_PRINCIPLE_ACBAL
            V_DISB_AMT :=
               GET_DISB_AMT (W_INTERNAL_ACNUM,
                             T_TEMP_REC (REC).T_PRODUCT_FOR_RUN_ACS,
                             P_FROM_DATE,
                             P_TO_DATE);

            SELECT MIN (D.LNACDISB_DISB_ON)
              INTO V_DISBURSE_DATE
              FROM LNACDISB D
             WHERE D.LNACDISB_INTERNAL_ACNUM = W_INTERNAL_ACNUM;

            IF V_DISBURSE_DATE IS NULL
            THEN
               BEGIN
                  SELECT A.ACNTINWTRF_DATE_OF_TRANSFR
                    INTO V_DISBURSE_DATE
                    FROM ACNTINWTRF A
                   WHERE A.ACNTINWTRF_DEP_AC_NUM = W_INTERNAL_ACNUM;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     V_DISBURSE_DATE := NULL;
               END;
            END IF;

            TEMP_DATA.PAYMENT_METHOD :=
               GET_METHOD_OF_PAYMENT (W_INTERNAL_ACNUM);

            --T_TEMP_REC (REC).PRODUCT_FOR_RUN_ACS

            IF V_IS_RESCHEDULE_ACC = 1
            THEN
               TEMP_DATA.SANC_RESCHE_AMT := V_RESCHEDULE_AMT;
               TEMP_DATA.SANC_RESCHE_DATE :=
                  TO_CHAR (V_RESCHEDULE_SANC_DATE, 'MM/DD/YYYY');
               TEMP_DATA.TOTAL_DISBURSE := V_RESCHEDULE_AMT;
               W_REMARKS := 'Reschedule on INTELECT';
            ELSE
               TEMP_DATA.SANC_RESCHE_AMT := V_LIMIT_RESCH_AMT;
               TEMP_DATA.SANC_RESCHE_DATE :=
                  TO_CHAR (V_LIMIT_RESCH_DATE, 'MM/DD/YYYY');

               --       TEMP_DATA.DISBURSE_DATE := TO_CHAR(V_DISBURSE_DATE, 'MM/DD/YYYY');

               TEMP_DATA.TOTAL_DISBURSE := V_DISB_AMT;
            END IF;

            --=
            TEMP_DATA.DISBURSE_FORMULA :=
               GET_PRIN_DB_AMT (W_INTERNAL_ACNUM,
                                T_TEMP_REC (REC).T_PRODUCT_FOR_RUN_ACS,
                                P_FROM_DATE,
                                P_TO_DATE);


            TEMP_DATA.RECOV_FORMULA :=
               GET_RECOVERY_FORMULA (W_INTERNAL_ACNUM,
                                     T_TEMP_REC (REC).T_PRODUCT_FOR_RUN_ACS,
                                     P_FROM_DATE,
                                     P_TO_DATE,
                                     V_EXP_DATE);

            TEMP_DATA.CUMULTV_RECOV :=
               GET_CUMULTV_RECOV (W_INTERNAL_ACNUM,
                                  T_TEMP_REC (REC).T_PRODUCT_FOR_RUN_ACS,
                                  P_FROM_DATE,
                                  P_TO_DATE,
                                  V_EXP_DATE);

            SP_GET_LNACRS_DETAIL (V_GLOB_ENTITY_NUM,
                                  W_INTERNAL_ACNUM,
                                  V_LNACRSDTL_REPAY_FROM_DATE,
                                  V_LNACRSDTL_REPAY_FREQ,
                                  V_LNACRSDTL_REPAY_AMT,
                                  V_LNACRSDTL_NUM_OF_INSTALLMENT,
                                  V_NEXT_INSTLMNT_DATE,
                                  V_INSTLMNT_LEFT,
                                  V_LAST_INSTLMNT_DATE);
            --  TEMP_DATA.REPAY_START_DATE  := TO_CHAR(V_LNACRSDTL_REPAY_FROM_DATE, 'MM/DD/YYYY');
            TEMP_DATA.REPAY_FREQ := V_LNACRSDTL_REPAY_FREQ;
            TEMP_DATA.INSTALL_AMT := V_LNACRSDTL_REPAY_AMT;
            TEMP_DATA.NO_OF_INSTALLMENT := V_LNACRSDTL_NUM_OF_INSTALLMENT;
            TEMP_DATA.NEXT_INSTL_DATE :=
               TO_CHAR (V_NEXT_INSTLMNT_DATE, 'MM/DD/YYYY');
            TEMP_DATA.REMAINING_INSTALLMENT := V_INSTLMNT_LEFT;
            TEMP_DATA.LAST_PAY_DATE :=
               TO_CHAR (V_LAST_INSTLMNT_DATE, 'MM/DD/YYYY');

            IF NVL (V_INSTLMNT_LEFT, 0) > 0
            THEN
               TEMP_DATA.NEXT_INSTL_AMT := V_LNACRSDTL_REPAY_AMT;
            ELSE
               TEMP_DATA.NEXT_INSTL_AMT := NULL;
            END IF;

            --

            --- advbal balance
            BEGIN
               SELECT NVL (ADVBAL_PRIN_AC_BAL, 0),
                      NVL (ADVBAL_INTRD_AC_BAL, 0),
                      NVL (ADVBAL_CHARGE_AC_BAL, 0)
                 INTO V_PR_BAL, V_INT_BAL, V_OTH_BAL
                 FROM ADVBAL
                WHERE     ADVBAL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND ADVBAL_INTERNAL_ACNUM = W_INTERNAL_ACNUM
                      AND ADVBAL_CURR_CODE = T_TEMP_REC (REC).T_CURR_CODE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_PR_BAL := NULL;
                  V_INT_BAL := NULL;
                  V_OTH_BAL := NULL;
            END;

            TEMP_DATA.PRINCIPAL_BAL := V_PR_BAL;
            TEMP_DATA.INT_BAL := V_INT_BAL;
            TEMP_DATA.OTHER_BAL := V_OTH_BAL;

            --

            GET_TOT_SEC_AMT_CBD;

            TEMP_DATA.ELIGIBLE_SEC_VAL := W_TOT_SEC_AMT_AC;
            TEMP_DATA.PRIM_MKT_VAL := W_TOT_SEC_AMT_AC;
            TEMP_DATA.PRIM_SALE_VAL := W_TOT_SEC_AMT_AC;
            TEMP_DATA.LAND_MKT_VAL := 0;
            TEMP_DATA.LAND_SALE_VAL := 0;
            TEMP_DATA.OTH_MKT_VAL := 0;
            TEMP_DATA.OTH_SALE_VALE := 0;
            TEMP_DATA.THIRD_PRTY_GUAR_TYP := NULL;
            TEMP_DATA.THIRD_PRTY_GUAR_AMT := NULL;

            TEMP_DATA.CL_DATE := GET_CL_DATE (W_INTERNAL_ACNUM, P_TO_DATE);

            --     TEMP_DATA.SEC_CODE := W_SEC_TYPE_STR;
            /*
              TEMP_DATA.SEC_AMT  := W_TOT_SEC_AMT_AC;
              TEMP_DATA.SEC_NUM  := W_SEC_NUM_STR;
            */
            --   BB CODE
            BEGIN
               SELECT LNACMIS_HO_DEPT_CODE,
                      LNACMIS.LNACMIS_SEGMENT_CODE,
                      LNACMIS_SUB_INDUS_CODE,
                      LNACMIS_NATURE_BORROWAL_AC
                 INTO V_CL_MIS_CODE,
                      V_CL_SEG_CODE,
                      V_CL_ECO_CODE,
                      V_CL_SME_CODE
                 FROM LNACMIS
                WHERE LNACMIS_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_CL_MIS_CODE := '';
                  V_CL_SEG_CODE := '';
                  V_CL_ECO_CODE := '';
                  V_CL_SME_CODE := '';
            END;

            TEMP_DATA.ECO_PURP_CODE := V_CL_ECO_CODE;
            TEMP_DATA.SME_CODE := V_CL_SME_CODE;
            --      TEMP_DATA.SEGMENT_CODE  := V_CL_SEG_CODE;
            TEMP_DATA.CL_FORM_NO := V_CL_MIS_CODE;

            --
            --WRITE-OFF
            BEGIN
               SELECT LNWRTOFF_AUTH_BY, LNWRTOFF_WRTOFF_DATE
                 INTO V_WRTOFF_APPROVAL_AUTH, V_WRTOFF_DATE
                 FROM LNWRTOFF, ACNTS
                WHERE     ACNTS_ENTITY_NUM = 1
                      AND LNWRTOFF_ENTITY_NUM = 1
                      AND ACNTS_INTERNAL_ACNUM = LNWRTOFF_ACNT_NUM
                      AND LNWRTOFF_ACNT_NUM = W_INTERNAL_ACNUM
                      AND ACNTS.ACNTS_CLOSURE_DATE IS NULL
                      AND LNWRTOFF_SL_NUM =
                             (SELECT MAX (LNWRTOFF_SL_NUM)
                                FROM LNWRTOFF
                               WHERE     LNWRTOFF_ENTITY_NUM = 1
                                     AND LNWRTOFF_ACNT_NUM =
                                            ACNTS_INTERNAL_ACNUM);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_WRTOFF_APPROVAL_AUTH := '';
                  V_WRTOFF_DATE := NULL;
            END;

            TEMP_DATA.WRTOFF_APPROV_AUTH := V_WRTOFF_APPROVAL_AUTH;
            TEMP_DATA.WRTOFF_DATE := V_WRTOFF_DATE;

            --END WRITE-OFF


            -- --- PERSONAL INFORMATION ---
            BEGIN
               SELECT TRIM (INDCLIENT_FATHER_NAME),
                      TRIM (INDCLIENT_MOTHER_NAME),
                      TRIM (INDCLIENT_SEX),
                      TRIM (INDCLIENT_BIRTH_DATE),
                      TRIM (INDCLIENT_BIRTH_PLACE_NAME),
                      TRIM (INDCLIENT_EMPLOYEE_NUM),
                      TRIM (INDCLIENT_OCCUPN_CODE),
                      TRIM (INDCLIENT_TEL_RES)
                 INTO V_FATHER_NAME,
                      V_MOTHER_NAME,
                      V_CLIENTS_GENDER,
                      V_DATE_OF_BIRTH,
                      V_BIRTH_PLACE,
                      V_EMPLOYEE_NUM,
                      V_OCCUPN_CODE,
                      V_MOBILE_NUM
                 FROM INDCLIENTS
                WHERE INDCLIENT_CODE = T_TEMP_REC (REC).T_CLIENT_CODE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_FATHER_NAME := NULL;
                  V_MOTHER_NAME := NULL;
                  V_CLIENTS_GENDER := NULL;
                  V_DATE_OF_BIRTH := NULL;
                  V_BIRTH_PLACE := NULL;
                  V_EMPLOYEE_NUM := NULL;
                  V_OCCUPN_CODE := NULL;
                  V_MOBILE_NUM := NULL;
            END;

            TEMP_DATA.FATHER_NAME := V_FATHER_NAME;
            TEMP_DATA.MOTHER_NAME := V_MOTHER_NAME;
            TEMP_DATA.CLIENTS_GENDER := V_CLIENTS_GENDER;
            TEMP_DATA.DATE_OF_BIRTH := TO_CHAR (V_DATE_OF_BIRTH);
            TEMP_DATA.BIRTH_PLACE := V_BIRTH_PLACE;
            TEMP_DATA.EMP_NO := V_EMPLOYEE_NUM;
            TEMP_DATA.TELE_NO := V_MOBILE_NUM;

            BEGIN
               SELECT TRIM (OCCUPATIONS_DESCN)
                 INTO V_CLIENT_OCCUP
                 FROM OCCUPATIONS
                WHERE OCCUPATIONS_CODE = V_OCCUPN_CODE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_CLIENT_OCCUP := NULL;
            END;

            TEMP_DATA.CLIENT_OCCUP := V_CLIENT_OCCUP;

            BEGIN
               SELECT TRIM (INDSPOUSE_SPOUSE_NAME)
                 INTO V_SPOUSE_NAME
                 FROM INDCLIENTSPOUSE
                WHERE INDSPOUSE_CLIENT_CODE = T_TEMP_REC (REC).T_CLIENT_CODE;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_SPOUSE_NAME := NULL;
            END;

            TEMP_DATA.SPOUSE_NAME := V_SPOUSE_NAME;

            BEGIN
               SELECT UPPER (TRIM (PIDDOCS_PID_TYPE)),
                      TRIM (PIDDOCS_DOCID_NUM),
                      TRIM (PIDDOCS_ISSUE_DATE),
                      TRIM (PIDDOCS_ISSUE_CNTRY)
                 INTO V_OTHER_DOCU_TYP,
                      V_OTHER_DOCU_NO,
                      V_OTHER_DOCU_DATE,
                      V_CNTRY_CODE
                 FROM PIDDOCS P
                WHERE P.PIDDOCS_SOURCE_KEY =
                         TO_CHAR (T_TEMP_REC (REC).T_CLIENT_CODE);

               IF V_OTHER_DOCU_TYP = 'NID'
               THEN
                  TEMP_DATA.NID_NO := V_OTHER_DOCU_NO;
                  TEMP_DATA.TIN_NO := NULL;
                  TEMP_DATA.OTHER_DOCU_TYP := NULL;
                  TEMP_DATA.OTHER_DOCU_NO := NULL;
                  TEMP_DATA.OTHER_DOCU_DATE := NULL;
                  TEMP_DATA.OTHER_DOCU_CNTRY := NULL;
               ELSIF V_OTHER_DOCU_TYP = 'TIN'
               THEN
                  TEMP_DATA.NID_NO := NULL;
                  TEMP_DATA.TIN_NO := V_OTHER_DOCU_NO;
                  TEMP_DATA.OTHER_DOCU_TYP := NULL;
                  TEMP_DATA.OTHER_DOCU_NO := NULL;
                  TEMP_DATA.OTHER_DOCU_DATE := NULL;
                  TEMP_DATA.OTHER_DOCU_CNTRY := NULL;
               ELSE
                  BEGIN
                     SELECT TRIM (CNTRY_NAME)
                       INTO V_OTHER_DOCU_CNTRY
                       FROM CNTRY
                      WHERE CNTRY_CODE = V_CNTRY_CODE;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        V_OTHER_DOCU_CNTRY := NULL;
                        V_CNTRY_CODE := NULL;
                  END;

                  TEMP_DATA.NID_NO := NULL;
                  TEMP_DATA.TIN_NO := NULL;
                  TEMP_DATA.OTHER_DOCU_TYP := V_OTHER_DOCU_TYP;
                  TEMP_DATA.OTHER_DOCU_NO := V_OTHER_DOCU_NO;
                  TEMP_DATA.OTHER_DOCU_DATE := V_OTHER_DOCU_DATE;
                  TEMP_DATA.OTHER_DOCU_CNTRY := V_OTHER_DOCU_CNTRY;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  TEMP_DATA.NID_NO := NULL;
                  TEMP_DATA.TIN_NO := NULL;
                  TEMP_DATA.OTHER_DOCU_TYP := NULL;
                  TEMP_DATA.OTHER_DOCU_NO := NULL;
                  TEMP_DATA.OTHER_DOCU_DATE := NULL;
                  TEMP_DATA.OTHER_DOCU_CNTRY := NULL;
                  V_CNTRY_CODE := NULL;
            END;

              
            TEMP_DATA.DEFAULT_IN_LIFE :=
               GET_DEFAULT_IN_LIFE (W_INTERNAL_ACNUM);
            TEMP_DATA.START_DATE := P_FROM_DATE;
            
            TEMP_DATA.CLOSED_DATE := NULL ;
            
            IF V_CLOSURE_DATE BETWEEN P_FROM_DATE AND P_TO_DATE
            THEN
               TEMP_DATA.CLOSED_DATE := V_CLOSURE_DATE;
            END IF;

            TEMP_DATA.BRANCH_CODE := P_BRN_CODE;

            BEGIN
               SELECT COUNT (*)
                 INTO V_NO_ENC
                 FROM (  SELECT LIMLNEHIST_CLIENT_CODE,
                                LIMLNEHIST_LIMIT_LINE_NUM,
                                LIMLNEHIST_EFF_DATE,
                                LIMLNEHIST_DATE_OF_SANCTION,
                                LIMLNEHIST_SANCTION_AMT,
                                LEAD (LIMLNEHIST_SANCTION_AMT, 1)
                                   OVER (ORDER BY LIMLNEHIST_EFF_DATE DESC)
                                   ENHANCEMENT
                           FROM LIMITLINEHIST
                          WHERE     LIMLNEHIST_ENTITY_NUM = 1
                                AND LIMLNEHIST_CLIENT_CODE =
                                       T_TEMP_REC (REC).T_CLIENT_CODE
                                AND LIMLNEHIST_LIMIT_LINE_NUM =
                                       (SELECT ACASLLDTL.ACASLLDTL_LIMIT_LINE_NUM
                                          FROM ACASLLDTL
                                         WHERE ACASLLDTL_INTERNAL_ACNUM =
                                                  W_INTERNAL_ACNUM)
                                AND LIMLNEHIST_EFF_DATE <= P_TO_DATE
                                AND LIMLNEHIST_AUTH_BY IS NOT NULL
                       ORDER BY LIMLNEHIST_EFF_DATE DESC) AA
                WHERE NVL (LIMLNEHIST_SANCTION_AMT - ENHANCEMENT, 0) > 0;
            EXCEPTION
               WHEN OTHERS
               THEN
                  V_NO_ENC := 0;
            END;

            TEMP_DATA.NUMBER_OF_ENHANCEMENT := V_NO_ENC;
            PIPE ROW (TEMP_DATA);
            W_REMARKS := '';
            V_CLOSURE_DATE := '' ;
         END LOOP;
      END IF;
   END GET_BRANCH_WISE;
BEGIN
   NULL;
END PKG_MIS_STATS;
/
CREATE OR REPLACE PACKAGE PKG_DEP_INT_APPLY
IS
   -- Author: Masud Ikbal
   -- Created: 12/01/2017 11:52:PM
   -- Purpose: Deposit (FDR/RIP) Interest Posting

   -- Public function and procedure declarations
   PROCEDURE START_DEPINT_PAY (P_ENTITY_NUM     IN NUMBER,
                               P_AS_ON_DATE        DATE DEFAULT NULL,
                               P_BRANCH            NUMBER DEFAULT 0,
                               P_DEP_AC_NUM        NUMBER DEFAULT 0,
                               P_CONTRACT_REF      NUMBER DEFAULT 0);

   PROCEDURE START_ACCR_BRNWISE (P_ENTITY_NUM   IN NUMBER,
                                 P_BRN_CODE     IN NUMBER DEFAULT 0);
END PKG_DEP_INT_APPLY;
/

CREATE OR REPLACE PACKAGE BODY PKG_DEP_INT_APPLY
IS
   V_PBDCONTDSA_STLMNT_CHOICE       PBDCONTDSA.PBDCONTDSA_STLMNT_CHOICE%TYPE;
   V_PBDCONTDSA_REMIT_CODE          PBDCONTDSA.PBDCONTDSA_REMIT_CODE%TYPE;
   V_PBDCONTDSA_BENEF_NAME1         PBDCONTDSA.PBDCONTDSA_BENEF_NAME1%TYPE;
   V_PBDCONTDSA_BENEF_NAME2         PBDCONTDSA.PBDCONTDSA_BENEF_NAME2%TYPE;
   V_PBDCONTDSA_ON_AC_OF            PBDCONTDSA.PBDCONTDSA_ON_AC_OF%TYPE;
   V_PBDCONTDSA_ECS_AC_BANK_CD      PBDCONTDSA.PBDCONTDSA_ECS_AC_BANK_CD%TYPE;
   V_PBDCONTDSA_ECS_AC_BRANCH_CD    PBDCONTDSA.PBDCONTDSA_ECS_AC_BRANCH_CD%TYPE;
   V_PBDCONTDSA_ECS_CREDIT_AC_NUM   PBDCONTDSA.PBDCONTDSA_ECS_CREDIT_AC_NUM%TYPE;
   V_ECSFILEGENPARAM_CUT_OFF_DAY    ECSFILEGENPARAM.ECSFILEGENPARAM_CUT_OFF_DAY%TYPE;
   V_ECSFILEGENPARAM_ECS_CR_GL      ECSFILEGENPARAM.ECSFILEGENPARAM_ECS_CREDIT_GL%TYPE;
   V_REMACPM_ISS_CR_GL              VARCHAR2 (15);

   W_DDPOKEY                        VARCHAR2 (35);
   W_CBD                            DATE;
   W_DDPO_BATCH_NUM                 NUMBER (7) := 0;
   V_ECS_CTL_FLAG                   NUMBER DEFAULT 0;
   V_PO_CTL_FLAG                    NUMBER DEFAULT 0;
   V_ECSPO_ASON_DATE                DATE;
   V_CUTOFF_FLAG                    NUMBER DEFAULT 0;
   V_PRINCIPAL_ADJUSTMENT           NUMBER (18, 3);
   V_ACCBAL_ADJ                     NUMBER (18, 3);
   V_ASON_BUSI_DATE                 DATE;

   L_PROD_CODE                      NUMBER (6);
   L_TDS_APPL                       CHAR;
   L_ACT_DEP_AMT                    NUMBER (18, 3);
   L_NOT_DEP_AMT                    NUMBER (18, 3);
   L_NOT_INT_AMT                    NUMBER (18, 3);
   L_TENOR_MONTHS                   NUMBER (6);
   L_CLIENT_CODE                    NUMBER (16);
   L_TDS_AMT                        NUMBER (18, 3);
   L_SUR_CHG                        NUMBER (18, 3);
   L_OTH_CHG                        NUMBER (18, 3);
   L_TDS_RATE                       NUMBER (18, 3);
   L_SUR_RATE                       NUMBER (18, 3);
   L_OTH_RATE                       NUMBER (18, 3);
   L_ERR_MSG                        VARCHAR2 (2000);
   L_BONUS_AMT                      NUMBER (18, 3);
   L_COMBINED_TDS                   NUMBER (18, 3);
   L_DTL_SL                         NUMBER;
   L_BON_APPL                       CHAR;
   L_TDS_GLACC_CODE                 VARCHAR2 (20);
   L_TAX_ON_BONUS                   NUMBER (18, 3);
   L_BONUS_GLACC_CODE               VARCHAR2 (20);
   L_CLOSURE_SL                     NUMBER;
   W_PARTYAC_CR_APPL                CHAR (1) DEFAULT 0;
   W_PARTY_CR_AC                    VARCHAR2 (22);
   L_STL_AMT                        NUMBER (18, 3);
   PKG_ERR_MSG                      VARCHAR2 (2300);
   IDX                              NUMBER;
   E_USER_EXCEP                     EXCEPTION;
   W_EXEMP_TDS_PER                  CLIENTS.CLIENTS_EXEMP_TDS_PER%TYPE;
   W_TDS_EXEMP_AMT                  NUMBER (18, 3);
   TOTAL_TDS_AMT                    NUMBER (18, 3);

   w_max_accr_from_date             DATE DEFAULT NULL;
   IS_ELIGIBLE                      NUMBER (1) DEFAULT 1;
   V_GLOB_ENTITY_NUM                NUMBER (6);


   TYPE DEPCONT IS RECORD
   (
      PBDCONT_BRN_CODE                NUMBER (6),
      PBDCONT_DEP_AC_NUM              NUMBER (14),
      PBDCONT_CONT_NUM                NUMBER (8),
      PBDCONT_AC_DEP_AMT              NUMBER (18, 3),
      PBDCONT_DEP_CURR                VARCHAR2 (3),
      PBDCONT_INT_ACCR_UPTO           DATE,
      PBDCONT_INT_PAID_UPTO           DATE,
      PBDCONT_COMPLETED_ROLLOVERS     NUMBER (3),
      PBDCONT_EFF_DATE                DATE,
      DEPPR_INT_CR_FREQ               DEPPROD.DEPPR_INT_CR_FREQ%TYPE,
      DEPPR_INT_PAY_FREQ              DEPPROD.DEPPR_INT_PAY_FREQ%TYPE,
      PBDCONT_INT_CR_TO_ACNT          CHAR,
      DEPPR_PROD_CODE                 NUMBER (4),
      PBDCONT_AC_INT_PAY_AMT          NUMBER (18, 3),
      PBDCONT_BC_INT_PAY_AMT          NUMBER (18, 3),
      PBDCONT_MAT_DATE                DATE,
      ACNTS_CLIENT_NUM                VARCHAR2 (12),
      ACNTS_NAME1                     VARCHAR2 (50),
      ACNTS_NAME2                     VARCHAR2 (50),
      PBDCONT_INT_CALC_PAYABLE_UPTO   DATE,
      PWGENPARAM_MES_APP              PWGENPARAM.PWGENPARAM_MES_APP%TYPE,
      DEPPR_TYPE_OF_DEP               DEPPROD.DEPPR_TYPE_OF_DEP%TYPE
   );

   TYPE TY_TAB_DEPCONT IS TABLE OF DEPCONT
      INDEX BY PLS_INTEGER;

   TYPE DEP_PROD_CURR_REC IS RECORD
   (
      PROD_CURR_INDEX           VARCHAR2 (7),
      DEPPRCUR_INT_ACCR_GLACC   VARCHAR2 (15)
   );

   TYPE TDEP_PROD_CURR_REC IS TABLE OF DEP_PROD_CURR_REC
      INDEX BY PLS_INTEGER;

   MDEP_PROD_CURR_REC               TDEP_PROD_CURR_REC;

   TYPE DEP_PROD_CURR_INDEX_GL
      IS RECORD (DEPPRCUR_INT_ACCR_GLACC VARCHAR2 (15));

   TYPE TDEP_PROD_CURR_INDEX_GL IS TABLE OF DEP_PROD_CURR_INDEX_GL
      INDEX BY VARCHAR2 (7);

   MTDEP_PROD_CURR_INDEX_GL         TDEP_PROD_CURR_INDEX_GL;

   TYPE DEPINTPAY IS RECORD
   (
      PBDCONT_BRN_CODE              NUMBER (6),
      PBDCONT_DEP_AC_NUM            NUMBER (14),
      PBDCONT_CONT_NUM              NUMBER (8),
      PBDCONT_AC_DEP_AMT            NUMBER (18, 3),
      PBDCONT_DEP_CURR              VARCHAR2 (3),
      DEP_PROD_CODE                 NUMBER (4),
      AC_INT_PAY_AMT                NUMBER (18, 3),
      BC_INT_PAY_AMT                NUMBER (18, 3),
      AC_PREV_INT_PAY_AMT           NUMBER (18, 3),
      BC_PREV_INT_PAY_AMT           NUMBER (18, 3),
      INT_PAY_FROM_DATE             DATE,
      INT_PAY_UPTO_DATE             DATE,
      PBDCONT_INT_CR_TO_ACNT        NUMBER (14),
      DEPPR_INT_ACCR_GLACC          VARCHAR2 (15),
      DEPIA_SRC_KEY                 VARCHAR2 (80),
      DEPINTPAY_MODE_OF_PAY         CHAR (1),
      DEPINTPAY_ECS_PO_DTLS         VARCHAR2 (35),
      ACNTS_CLIENT_NUM              VARCHAR2 (12),
      ACNTS_NAME1                   VARCHAR2 (50),
      ACNTS_NAME2                   VARCHAR2 (50),
      PBDCONTDSA_REMIT_CODE         VARCHAR2 (6),
      PBDCONTDSA_ECS_AC_BANK_CD     VARCHAR2 (6),
      PBDCONTDSA_ECS_AC_BRANCH_CD   VARCHAR2 (6),
      PBDCONTDSA_ON_AC_OF           VARCHAR2 (35),
      PWGENPARAM_MES_APP            PWGENPARAM.PWGENPARAM_MES_APP%TYPE,
      DEPPR_INT_PAY_FREQ            DEPPROD.DEPPR_INT_PAY_FREQ%TYPE
   );

   TYPE DEP_INT_PAY_IDX IS TABLE OF DEPINTPAY
      INDEX BY PLS_INTEGER;

   DEP_INT_PAY_COLL                 DEP_INT_PAY_IDX;

   TYPE ECS_INT_PAY IS RECORD
   (
      ENTITY_NUM     NUMBER (4),
      CUT_OFF_DATE   DATE,
      BRN_CODE       VARCHAR2 (6),
      DEP_AC_NUM     VARCHAR2 (14),
      CONTRACT_NUM   VARCHAR2 (8)
   );

   TYPE ECS_INT_PAY_TY IS TABLE OF ECS_INT_PAY
      INDEX BY PLS_INTEGER;

   ECS_INT_PAY_COLL                 ECS_INT_PAY_TY;

   TYPE DEPINTPAYMNT_IDX IS TABLE OF DEPINTPAYMENT%ROWTYPE
      INDEX BY PLS_INTEGER;

   TYPE DEPINTPAYMNTDTL_IDX IS TABLE OF DEPINTPAYMENTDTL%ROWTYPE
      INDEX BY PLS_INTEGER;

   TYPE DEPIA_IDX IS TABLE OF DEPIA%ROWTYPE
      INDEX BY PLS_INTEGER;

   V_DEPINTPAYMNT_COLL              DEPINTPAYMNT_IDX;
   V_DEPINTPAYMNTDTL_COLL           DEPINTPAYMNTDTL_IDX;
   V_DEPIA_COLL                     DEPIA_IDX;

   TYPE DEPINT_ACCR_GL IS RECORD
   (
      DEP_PROD_CODE   NUMBER (4),
      DEP_CURR        VARCHAR2 (3),
      INT_ACCR_GL     VARCHAR2 (15),
      AC_AMT          NUMBER (18, 3),
      BC_AMT          NUMBER (18, 3)
   );

   TYPE DEPINT_ACCR_GL_IDX IS TABLE OF DEPINT_ACCR_GL
      INDEX BY VARCHAR2 (22);

   DEPINT_ACCR_GL_COLL              DEPINT_ACCR_GL_IDX;


   FUNCTION INT_PAYABLE (p_branch           IN     NUMBER,
                         p_dep_acnum        IN     NUMBER,
                         p_contract_ref     IN     NUMBER,
                         p_ason_date        IN     DATE,
                         p_end_date         IN     DATE,
                         p_comp_rollovers   IN     NUMBER,
                         p_int_bal             OUT NUMBER)
      RETURN BOOLEAN
   IS
   BEGIN
      --gkash chn 28-feb-2011 beg for getting correct interest paid from date
      w_max_accr_from_date := NULL;

      FOR each_depia
         IN (  SELECT DEPIA_AC_INT_ACCR_AMT,
                      DEPIA_INT_ACCR_DB_CR,
                      DEPIA_ACCR_UPTO_DATE,
                      DEPIA_ACCR_FROM_DATE
                 FROM DEPIA
                WHERE     DEPIA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND DEPIA_BRN_CODE = p_branch
                      AND DEPIA_INTERNAL_ACNUM = p_dep_acnum
                      AND DEPIA_CONTRACT_NUM = p_contract_ref
                      --Sriram B - 10-nov-2008 AND DEPIA_AUTO_ROLLOVER_SL = p_comp_rollovers
                      AND DEPIA_ACCR_UPTO_DATE <= p_ASON_date
             ORDER BY DEPIA_ACCR_UPTO_DATE)
      LOOP
         IF each_depia.DEPIA_ACCR_UPTO_DATE <= p_ASON_date
         THEN
            IF each_depia.DEPIA_INT_ACCR_DB_CR = 'C'
            THEN
               p_int_bal :=
                  NVL (p_int_bal, 0) + each_depia.DEPIA_AC_INT_ACCR_AMT;
            --gkash chn 28-feb-2011 beg for identifying the correct start date to put for IP entry
               w_max_accr_from_date := each_depia.DEPIA_ACCR_FROM_DATE;
            --gkash chn 28-feb-2011 end for identifying the correct start date to put for IP entry
            ELSIF each_depia.DEPIA_INT_ACCR_DB_CR = 'D'
            THEN
               p_int_bal :=
                  NVL (p_int_bal, 0) - each_depia.DEPIA_AC_INT_ACCR_AMT;
            END IF;
         END IF;
      END LOOP;

      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         pkg_err_msg :=
               'Error inside int_payable function-when others'
            || p_branch
            || '/'
            || facno (V_GLOB_ENTITY_NUM, p_DEP_acnum)
            || '/'
            || p_contract_ref;
         /* PKG_EODSOD_FLAGS.PV_ERROR_MSG :=  pkg_err_msg ;
         PKG_PB_GLOBAL.DETAIL_ERRLOG ('E',pkg_err_msg,' ',p_dep_acnum);*/

         RETURN FALSE;
   END INT_PAYABLE;

   -----------------------------------------------
   PROCEDURE GET_CONVERTED_VALUE (P_DEP_CURR         IN     VARCHAR2,
                                  P_AMT_TO_CONVERT   IN     NUMBER,
                                  P_CONV_RATE        IN     NUMBER,
                                  P_CONVERTED_AMT       OUT NUMBER,
                                  P_ERR_CODE            OUT NUMBER)
   IS
   BEGIN
      SP_CALCAGNSTVALUE (
         V_GLOB_ENTITY_NUM,
         P_DEP_CURR,
         PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR (V_GLOB_ENTITY_NUM),
         P_AMT_TO_CONVERT,
         P_CONV_RATE,
         '0',
         P_CONVERTED_AMT,
         P_ERR_CODE);

      IF P_ERR_CODE <> 0
      THEN
         PKG_ERR_MSG := 'Error occured in SP_CALCAGNSTVALUE';
         PKG_EODSOD_FLAGS.PV_ERROR_MSG := PKG_ERR_MSG;
         RAISE E_USER_EXCEP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         P_ERR_CODE := 1;
         PKG_ERR_MSG :=
               'Error occured in get_converted_value.Error:'
            || SUBSTR (SQLERRM, 1, 500);
         RAISE E_USER_EXCEP;
   END GET_CONVERTED_VALUE;

   -----------------------------------------------
   FUNCTION STLMNT_AC_OK (P_DEP_ACNUM      IN     NUMBER,
                          P_CONTRACT_REF   IN     NUMBER,
                          W_PARTY_CR_AC       OUT NUMBER)
      RETURN BOOLEAN
   IS
      STLMNT_AC   NUMBER (14);
   BEGIN
     <<PBDCONTDSA_BEGIN>>
      BEGIN
         SELECT PBDCONTDSA_STLMNT_CHOICE
           INTO V_PBDCONTDSA_STLMNT_CHOICE
           FROM PBDCONTDSA
          WHERE     PBDCONTDSA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND PBDCONTDSA_DEP_AC_NUM = P_DEP_ACNUM
                AND PBDCONTDSA_CONT_NUM = P_CONTRACT_REF;

         IF V_PBDCONTDSA_STLMNT_CHOICE = 'A'
         THEN
            SELECT PBDCONTDSA_INT_CR_AC_NUM,
                   PBDCONTDSA_STLMNT_CHOICE,
                   PBDCONTDSA_REMIT_CODE,
                   PBDCONTDSA_BENEF_NAME1,
                   PBDCONTDSA_BENEF_NAME2,
                   PBDCONTDSA_ON_AC_OF,
                   PBDCONTDSA_ECS_AC_BANK_CD,
                   PBDCONTDSA_ECS_AC_BRANCH_CD,
                   PBDCONTDSA_ECS_CREDIT_AC_NUM
              INTO STLMNT_AC,
                   V_PBDCONTDSA_STLMNT_CHOICE,
                   V_PBDCONTDSA_REMIT_CODE,
                   V_PBDCONTDSA_BENEF_NAME1,
                   V_PBDCONTDSA_BENEF_NAME2,
                   V_PBDCONTDSA_ON_AC_OF,
                   V_PBDCONTDSA_ECS_AC_BANK_CD,
                   V_PBDCONTDSA_ECS_AC_BRANCH_CD,
                   V_PBDCONTDSA_ECS_CREDIT_AC_NUM
              FROM PBDCONTDSA
             WHERE     PBDCONTDSA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND PBDCONTDSA_DEP_AC_NUM = P_DEP_ACNUM
                   AND PBDCONTDSA_CONT_NUM = P_CONTRACT_REF
                   AND PBDCONTDSA_INT_CR_AC_NUM <> 0;
         ELSE
            SELECT PBDCONTDSA_INT_CR_AC_NUM,
                   PBDCONTDSA_STLMNT_CHOICE,
                   PBDCONTDSA_REMIT_CODE,
                   PBDCONTDSA_BENEF_NAME1,
                   PBDCONTDSA_BENEF_NAME2,
                   PBDCONTDSA_ON_AC_OF,
                   PBDCONTDSA_ECS_AC_BANK_CD,
                   PBDCONTDSA_ECS_AC_BRANCH_CD,
                   PBDCONTDSA_ECS_CREDIT_AC_NUM
              INTO STLMNT_AC,
                   V_PBDCONTDSA_STLMNT_CHOICE,
                   V_PBDCONTDSA_REMIT_CODE,
                   V_PBDCONTDSA_BENEF_NAME1,
                   V_PBDCONTDSA_BENEF_NAME2,
                   V_PBDCONTDSA_ON_AC_OF,
                   V_PBDCONTDSA_ECS_AC_BANK_CD,
                   V_PBDCONTDSA_ECS_AC_BRANCH_CD,
                   V_PBDCONTDSA_ECS_CREDIT_AC_NUM
              FROM PBDCONTDSA
             WHERE     PBDCONTDSA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND PBDCONTDSA_DEP_AC_NUM = P_DEP_ACNUM
                   AND PBDCONTDSA_CONT_NUM = P_CONTRACT_REF;
         END IF;

         W_PARTY_CR_AC := STLMNT_AC;
         RETURN TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
           <<PBDCONTDSA1_BEGIN>>
            BEGIN
               SELECT PBDCONTDSA_STLMNT_CHOICE
                 INTO V_PBDCONTDSA_STLMNT_CHOICE
                 FROM PBDCONTDSA
                WHERE     PBDCONTDSA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND PBDCONTDSA_DEP_AC_NUM = P_DEP_ACNUM
                      AND PBDCONTDSA_CONT_NUM = 0;

               IF V_PBDCONTDSA_STLMNT_CHOICE = 'A'
               THEN
                  SELECT PBDCONTDSA_INT_CR_AC_NUM,
                         PBDCONTDSA_STLMNT_CHOICE,
                         PBDCONTDSA_REMIT_CODE,
                         PBDCONTDSA_BENEF_NAME1,
                         PBDCONTDSA_BENEF_NAME2,
                         PBDCONTDSA_ON_AC_OF,
                         PBDCONTDSA_ECS_AC_BANK_CD,
                         PBDCONTDSA_ECS_AC_BRANCH_CD,
                         PBDCONTDSA_ECS_CREDIT_AC_NUM
                    INTO STLMNT_AC,
                         V_PBDCONTDSA_STLMNT_CHOICE,
                         V_PBDCONTDSA_REMIT_CODE,
                         V_PBDCONTDSA_BENEF_NAME1,
                         V_PBDCONTDSA_BENEF_NAME2,
                         V_PBDCONTDSA_ON_AC_OF,
                         V_PBDCONTDSA_ECS_AC_BANK_CD,
                         V_PBDCONTDSA_ECS_AC_BRANCH_CD,
                         V_PBDCONTDSA_ECS_CREDIT_AC_NUM
                    FROM PBDCONTDSA
                   WHERE     PBDCONTDSA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                         AND PBDCONTDSA_DEP_AC_NUM = P_DEP_ACNUM
                         AND PBDCONTDSA_CONT_NUM = 0
                         AND PBDCONTDSA_INT_CR_AC_NUM <> 0;
               ELSE
                  SELECT PBDCONTDSA_INT_CR_AC_NUM,
                         PBDCONTDSA_STLMNT_CHOICE,
                         PBDCONTDSA_REMIT_CODE,
                         PBDCONTDSA_BENEF_NAME1,
                         PBDCONTDSA_BENEF_NAME2,
                         PBDCONTDSA_ON_AC_OF,
                         PBDCONTDSA_ECS_AC_BANK_CD,
                         PBDCONTDSA_ECS_AC_BRANCH_CD,
                         PBDCONTDSA_ECS_CREDIT_AC_NUM
                    INTO STLMNT_AC,
                         V_PBDCONTDSA_STLMNT_CHOICE,
                         V_PBDCONTDSA_REMIT_CODE,
                         V_PBDCONTDSA_BENEF_NAME1,
                         V_PBDCONTDSA_BENEF_NAME2,
                         V_PBDCONTDSA_ON_AC_OF,
                         V_PBDCONTDSA_ECS_AC_BANK_CD,
                         V_PBDCONTDSA_ECS_AC_BRANCH_CD,
                         V_PBDCONTDSA_ECS_CREDIT_AC_NUM
                    FROM PBDCONTDSA
                   WHERE     PBDCONTDSA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                         AND PBDCONTDSA_DEP_AC_NUM = P_DEP_ACNUM
                         AND PBDCONTDSA_CONT_NUM = 0;
               END IF;

               W_PARTY_CR_AC := STLMNT_AC;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  W_PARTY_CR_AC := 0;
                  RETURN TRUE;
            END PBDCONTDSA1_BEGIN;

            RETURN TRUE;
      END PBDCONTDSA_BEGIN;

      W_PARTY_CR_AC := STLMNT_AC;
   END STLMNT_AC_OK;

   -----------------------------------------------
   FUNCTION CHECK_CUTOFF_DATE (P_ASON_DATE       IN     DATE,
                               P_ECS_ASON_DATE      OUT DATE,
                               P_PO_ASON_DATE       OUT DATE)
      RETURN BOOLEAN
   IS
      V_DATE_COUNT                NUMBER DEFAULT 0;
      V_PREV_BUSINESS_DATE        DATE;
      W_CUTOFF_ASON_DATE          DATE;
      V_DEPECSPOINTPAYCTL_DATE    DATE;
      V_ECSFILEGENPARAM_PAY_OPT   CHAR;
      W_ORIGINAL_DATE             DATE;
      W_ASSIGN_FLG                BOOLEAN;
   BEGIN
      V_DATE_COUNT := 0;
      W_CUTOFF_ASON_DATE := P_ASON_DATE;

      SELECT MN_PREV_BUSINESS_DATE INTO V_PREV_BUSINESS_DATE FROM MAINCONT;

      IF (W_CUTOFF_ASON_DATE - V_PREV_BUSINESS_DATE) > 1
      THEN
         V_DATE_COUNT := (W_CUTOFF_ASON_DATE - V_PREV_BUSINESS_DATE) + 1;
         W_CUTOFF_ASON_DATE := V_PREV_BUSINESS_DATE;                   -- + 1;
      ELSE
         V_DATE_COUNT := 2;
         W_CUTOFF_ASON_DATE := V_PREV_BUSINESS_DATE;
      END IF;

      W_ORIGINAL_DATE := W_CUTOFF_ASON_DATE;
      W_ASSIGN_FLG := FALSE;

      FOR J IN (  SELECT ECSFILEGENPARAM_CUT_OFF_DAY, ECSFILEGENPARAM_PAY_OPT
                    FROM ECSFILEGENPARAM
                   WHERE ECSFILEGENPARAM_ENTITY_NUM = V_GLOB_ENTITY_NUM
                ORDER BY ECSFILEGENPARAM_PAY_OPT)
      LOOP
         W_CUTOFF_ASON_DATE := W_ORIGINAL_DATE;
         W_ASSIGN_FLG := FALSE;

         FOR I IN 1 .. V_DATE_COUNT
         LOOP
            IF I > 1
            THEN
               W_CUTOFF_ASON_DATE := W_CUTOFF_ASON_DATE + 1;
            END IF;

           <<ECSPOCTL>>
            BEGIN
               SELECT DISTINCT DEPECSPOINTPAYCTL_DATE
                 INTO V_DEPECSPOINTPAYCTL_DATE
                 FROM DEPECSPOINTPAYCTL
                WHERE     DEPECSPOINTPAYCTL_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND DEPECSPOINTPAYCTL_DATE = W_CUTOFF_ASON_DATE;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_DEPECSPOINTPAYCTL_DATE := NULL;
               WHEN OTHERS
               THEN
                  NULL;
            END ECSPOCTL;

            IF V_DEPECSPOINTPAYCTL_DATE IS NULL
            THEN
               IF J.ECSFILEGENPARAM_CUT_OFF_DAY = 99
               THEN
                  W_CUTOFF_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
                  V_CUTOFF_FLAG := 1;
                  W_ASSIGN_FLG := TRUE;
                  GOTO CUTOFFEXIT;
               ELSIF J.ECSFILEGENPARAM_CUT_OFF_DAY = 0
               THEN
                  IF W_CUTOFF_ASON_DATE = LAST_DAY (W_CUTOFF_ASON_DATE)
                  THEN
                     V_CUTOFF_FLAG := 1;
                     W_ASSIGN_FLG := TRUE;
                     GOTO CUTOFFEXIT;
                  ELSE
                     GOTO NEXT_LOOP;
                  END IF;
               ELSIF W_CUTOFF_ASON_DATE =
                        TO_DATE (
                              REPLACE (SUBSTR (W_CUTOFF_ASON_DATE, 1, 2),
                                       SUBSTR (W_CUTOFF_ASON_DATE, 1, 2),
                                       J.ECSFILEGENPARAM_CUT_OFF_DAY)
                           || SUBSTR (W_CUTOFF_ASON_DATE, 3))
               THEN
                  W_ASSIGN_FLG := TRUE;
                  V_CUTOFF_FLAG := 1;
                  GOTO CUTOFFEXIT;
               ELSE
                  GOTO NEXT_LOOP;
               END IF;

              <<NEXT_LOOP>>
               NULL;
            END IF;
         END LOOP;

        <<CUTOFFEXIT>>
         IF W_ASSIGN_FLG = TRUE
         THEN
            IF J.ECSFILEGENPARAM_PAY_OPT = 'E'
            THEN
               P_ECS_ASON_DATE := W_CUTOFF_ASON_DATE;
            ELSE
               P_PO_ASON_DATE := W_CUTOFF_ASON_DATE;
            END IF;
         END IF;
      END LOOP;

      RETURN TRUE;
   END CHECK_CUTOFF_DATE;

   --------------------------------------------------------------
   FUNCTION GET_DEP_PROD_CURR_ARRAY (P_DEP_CURR             IN     VARCHAR2,
                                     P_DEP_PROD             IN     NUMBER,
                                     P_DEP_INT_ACCR_GLACC      OUT NUMBER)
      RETURN BOOLEAN
   IS
      DEP_PROD_CURR_IDX   VARCHAR2 (7);
   BEGIN
      DEP_PROD_CURR_IDX := LPAD (P_DEP_PROD, 4, 0) || P_DEP_CURR;

      IF (MTDEP_PROD_CURR_INDEX_GL.EXISTS (DEP_PROD_CURR_IDX))
      THEN
         IF (TRIM (
                MTDEP_PROD_CURR_INDEX_GL (DEP_PROD_CURR_IDX).DEPPRCUR_INT_ACCR_GLACC)
                IS NULL)
         THEN
            PKG_ERR_MSG :=
                  'Interest Accrual GL Access Code Not Defined for Product Code = '
               || P_DEP_PROD
               || ' and Curr Code = '
               || P_DEP_CURR;
            RETURN FALSE;
         ELSE
            P_DEP_INT_ACCR_GLACC :=
               MTDEP_PROD_CURR_INDEX_GL (DEP_PROD_CURR_IDX).DEPPRCUR_INT_ACCR_GLACC;
            RETURN TRUE;
         END IF;
      END IF;
   END GET_DEP_PROD_CURR_ARRAY;

   --------------------------------------------------------------
   FUNCTION SET_DEP_PROD_CURR_ARRAY
      RETURN BOOLEAN
   IS
   BEGIN
      SELECT LPAD (D.DEPPRCUR_PROD_CODE, 4, 0) || D.DEPPRCUR_CURR_CODE,
             D.DEPPRCUR_INT_ACCR_GLACC
        BULK COLLECT INTO MDEP_PROD_CURR_REC
        FROM DEPPRODCUR D;

      IF MDEP_PROD_CURR_REC.COUNT > 0
      THEN
         FOR IDX IN 1 .. MDEP_PROD_CURR_REC.COUNT
         LOOP
            MTDEP_PROD_CURR_INDEX_GL (
               MDEP_PROD_CURR_REC (IDX).PROD_CURR_INDEX).DEPPRCUR_INT_ACCR_GLACC :=
               MDEP_PROD_CURR_REC (IDX).DEPPRCUR_INT_ACCR_GLACC;
         END LOOP;
      END IF;

      MDEP_PROD_CURR_REC.DELETE;
      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         PKG_ERR_MSG := 'Error in set_dep_prod_curr_Array() function ';
         RETURN FALSE;
   END SET_DEP_PROD_CURR_ARRAY;

   -----------------------------------------------
   FUNCTION AUTOPOSTINT
      RETURN BOOLEAN
   IS
      W_ERR_CODE       NUMBER;
      W_BATCH_NUM      NUMBER (7);
      E_AUTOPOST_EXP   EXCEPTION;
      IDX              NUMBER (8);
      TRAN_IDX         NUMBER (8) := 0;

      PROCEDURE SET_TRAN_KEY_VALUES
      IS
      BEGIN
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE :=
            DEP_INT_PAY_COLL (1).PBDCONT_BRN_CODE;
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN :=
            PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_GLOB_ENTITY_NUM);
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;
      END SET_TRAN_KEY_VALUES;

      PROCEDURE SET_TRANBAT_VALUES
      IS
      BEGIN
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'PKG_DEP_INT_APPLY';
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY := 'PKG_DEP_INT_APPLY';
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 :=
            'Deposit Interest Payment for ';
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL2 :=
            DEP_INT_PAY_COLL (1).DEP_PROD_CODE;
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL3 :=
               'from '
            || DEP_INT_PAY_COLL (1).INT_PAY_FROM_DATE
            || ' to '
            || DEP_INT_PAY_COLL (1).INT_PAY_UPTO_DATE;
      END SET_TRANBAT_VALUES;

      PROCEDURE CLEARVALUES
      IS
      BEGIN
         L_PROD_CODE := 0;
         L_TDS_APPL := 0;
         L_ACT_DEP_AMT := 0;
         L_TENOR_MONTHS := 0;
         L_CLIENT_CODE := 0;
         L_TDS_AMT := 0;
         L_SUR_CHG := 0;
         L_OTH_CHG := 0;
         L_TDS_RATE := 0;
         L_SUR_RATE := 0;
         L_OTH_RATE := 0;
         L_ERR_MSG := 0;
         L_BONUS_AMT := 0;
         L_BON_APPL := 0;
         L_TAX_ON_BONUS := 0;
         L_DTL_SL := 0;
         L_TDS_GLACC_CODE := '';
         L_BONUS_GLACC_CODE := '';
         L_CLOSURE_SL := 0;
         L_STL_AMT := 0;
         L_COMBINED_TDS := 0;
         TOTAL_TDS_AMT := 0;
         W_EXEMP_TDS_PER := 0;
         W_TDS_EXEMP_AMT := 0;
      END CLEARVALUES;

      PROCEDURE MOVE_TO_TRAN_REC (P_TRAN_ACING_BRN_CODE   IN NUMBER,
                                  P_TRAN_INTERNAL_ACNUM   IN NUMBER,
                                  P_TRAN_CONTRACT_NUM     IN NUMBER,
                                  P_TRAN_GLACC_CODE       IN VARCHAR2,
                                  P_TRAN_DB_CR_FLG        IN VARCHAR2,
                                  P_TRAN_CURR_CODE        IN VARCHAR2,
                                  P_TRAN_AMOUNT           IN NUMBER,
                                  P_TRAN_VALUE_DATE       IN DATE,
                                  P_TRAN_NARR_DTL1        IN VARCHAR2,
                                  P_TRAN_NARR_DTL2        IN VARCHAR2,
                                  P_TRAN_NARR_DTL3        IN VARCHAR2)
      IS
      BEGIN
         IF P_TRAN_AMOUNT > 0
         THEN
            TRAN_IDX := TRAN_IDX + 1;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
               P_TRAN_ACING_BRN_CODE;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_INTERNAL_ACNUM :=
               P_TRAN_INTERNAL_ACNUM;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CONTRACT_NUM :=
               P_TRAN_CONTRACT_NUM;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_GLACC_CODE :=
               P_TRAN_GLACC_CODE;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG :=
               P_TRAN_DB_CR_FLG;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
               P_TRAN_CURR_CODE;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT := P_TRAN_AMOUNT;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
               P_TRAN_VALUE_DATE;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
               P_TRAN_NARR_DTL1;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
               P_TRAN_NARR_DTL2;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL3 :=
               P_TRAN_NARR_DTL3;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            PKG_ERR_MSG :=
                  'ERROR IN MOVE_TO_TRAN_REC '
               || '-'
               || SUBSTR (SQLERRM, 1, 500);
            RAISE E_USER_EXCEP;
      END MOVE_TO_TRAN_REC;


      PROCEDURE SET_TRAN_VALUES
      IS
         W_DEP_INT_ACCR_GL_KEY   VARCHAR2 (22);
         W_BRN_CODE              NUMBER (6);
         W_TRAN_ACING_BRN_CODE   TRAN.TRAN_ACING_BRN_CODE%TYPE;
         W_TRAN_INTERNAL_ACNUM   TRAN.TRAN_INTERNAL_ACNUM%TYPE;
         W_TRAN_CONTRACT_NUM     TRAN.TRAN_CONTRACT_NUM%TYPE;
         W_TRAN_GLACC_CODE       TRAN.TRAN_GLACC_CODE%TYPE;
         W_TRAN_DB_CR_FLG        TRAN.TRAN_DB_CR_FLG%TYPE;
         W_TRAN_CURR_CODE        TRAN.TRAN_CURR_CODE%TYPE;
         W_TRAN_AMOUNT           TRAN.TRAN_AMOUNT%TYPE;
         W_TRAN_VALUE_DATE       TRAN.TRAN_VALUE_DATE%TYPE;
         W_TRAN_NARR_DTL1        TRAN.TRAN_NARR_DTL1%TYPE;
         W_TRAN_NARR_DTL2        TRAN.TRAN_NARR_DTL2%TYPE;
         W_TRAN_NARR_DTL3        TRAN.TRAN_NARR_DTL3%TYPE;

         PROCEDURE INIT_VARIABLE
         IS
         BEGIN
            W_DEP_INT_ACCR_GL_KEY := NULL;
            W_BRN_CODE := 0;
            W_TRAN_ACING_BRN_CODE := 0;
            W_TRAN_INTERNAL_ACNUM := 0;
            W_TRAN_CONTRACT_NUM := 0;
            W_TRAN_GLACC_CODE := NULL;
            W_TRAN_DB_CR_FLG := '';
            W_TRAN_CURR_CODE := NULL;
            W_TRAN_AMOUNT := 0;
            W_TRAN_VALUE_DATE := NULL;
            W_TRAN_NARR_DTL1 := NULL;
            W_TRAN_NARR_DTL2 := NULL;
            W_TRAN_NARR_DTL3 := NULL;
         END;

      BEGIN
         FOR IDX IN 1 .. DEP_INT_PAY_COLL.COUNT
         LOOP
            CLEARVALUES;
            INIT_VARIABLE;

            IF DEP_INT_PAY_COLL (IDX).DEPINTPAY_MODE_OF_PAY <> 'P'
            THEN
               TRAN_IDX := TRAN_IDX + 1;

               --Credit voucher into account.
               IF DEP_INT_PAY_COLL (IDX).DEPINTPAY_MODE_OF_PAY = 'E'
               THEN
                  PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_GLACC_CODE :=
                     V_ECSFILEGENPARAM_ECS_CR_GL;
               ELSIF DEP_INT_PAY_COLL (IDX).DEPINTPAY_MODE_OF_PAY = 'A'
               THEN
                  PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_INTERNAL_ACNUM :=
                     DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM;
                  PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CONTRACT_NUM :=
                     DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
               END IF;

               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG := 'C';
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
                  DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
                  DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
               W_BRN_CODE := DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
                  PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT :=
                  DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT;
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
                  'Interest Applied' || 'For ';
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
                     FACNO (V_GLOB_ENTITY_NUM,
                            DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM)
                  || ' / '
                  || DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL3 :=
                     ' From '
                  || DEP_INT_PAY_COLL (IDX).INT_PAY_FROM_DATE
                  || 'upto '
                  || DEP_INT_PAY_COLL (IDX).INT_PAY_UPTO_DATE;



              <<CHECK_TDS_BONUS_APPL>>
               BEGIN
                  BEGIN
                     SELECT NVL (A.ACNTS_PROD_CODE, 0),
                            NVL (A.ACNTS_CLIENT_NUM, 0),
                            NVL (PB.PBDCONT_BONUS_AMT, 0),
                            PB.PDBCONT_DEP_PRD_MONTHS,
                            NVL (PB.PBDCONT_AC_DEP_AMT, 0)
                       INTO L_PROD_CODE,
                            L_CLIENT_CODE,
                            L_BONUS_AMT,
                            L_TENOR_MONTHS,
                            L_ACT_DEP_AMT
                       FROM ACNTS A, PBDCONTRACT PB
                      WHERE     A.ACNTS_ENTITY_NUM = V_GLOB_ENTITY_NUM
                            AND A.ACNTS_INTERNAL_ACNUM =
                                   PB.PBDCONT_DEP_AC_NUM
                            AND A.ACNTS_INTERNAL_ACNUM =
                                   DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
                            AND PB.PBDCONT_CONT_NUM =
                                   DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM
                            AND A.ACNTS_BRN_CODE =
                                   DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        L_PROD_CODE := 0;
                  END;

                  IF DEP_INT_PAY_COLL (IDX).PWGENPARAM_MES_APP = '1'
                  THEN
                     BEGIN
                        SELECT NVL (PL.PWGENPARAMD_DEP_AMT, 0),
                               NVL (PL.PWGENPARAMD_NOT_INT_AMT, 0)
                          INTO L_NOT_DEP_AMT, L_NOT_INT_AMT
                          FROM PWGENPARAMDTL PL
                         WHERE     PL.PWGENPARAMD_ENTITY_NUM =
                                      PKG_ENTITY.FN_GET_ENTITY_CODE
                               AND PL.PWGENPARAMD_PROD_CODE = L_PROD_CODE
                               AND PL.PWGENPARAMD_TENOR_CHOICE =
                                      L_TENOR_MONTHS
                               AND PL.PWGENPARAMD_EFF_DATE =
                                      (SELECT MAX (PL.PWGENPARAMD_EFF_DATE)
                                         FROM PWGENPARAMDTL PL
                                        WHERE     PL.PWGENPARAMD_ENTITY_NUM =
                                                     PKG_ENTITY.FN_GET_ENTITY_CODE
                                              AND PL.PWGENPARAMD_PROD_CODE =
                                                     L_PROD_CODE
                                              AND PL.PWGENPARAMD_TENOR_CHOICE =
                                                     L_TENOR_MONTHS);

                        IF L_NOT_DEP_AMT > 0 AND L_NOT_INT_AMT > 0
                        THEN
                           L_BONUS_AMT :=
                              ROUND (
                                 (    (  (L_ACT_DEP_AMT / L_NOT_DEP_AMT)
                                       * L_NOT_INT_AMT)
                                    * (100 / 90)
                                  - DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT),
                                 0);
                        ELSE
                           L_BONUS_AMT := 0;
                        END IF;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           L_BONUS_AMT := 0;
                     END;
                  END IF;


                  IF L_PROD_CODE <> 0
                  THEN
                     SELECT NVL (DEPPR_TDS_FOR_INT, 0)
                       INTO L_TDS_APPL
                       FROM DEPPROD
                      WHERE DEPPR_PROD_CODE = L_PROD_CODE;

                     --TDS Start...
                     IF L_TDS_APPL = '1'
                     THEN
                        BEGIN
                           SELECT MAX (DEPIA_DAY_SL)
                             INTO L_DTL_SL
                             FROM DEPIA
                            WHERE     DEPIA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                                  AND DEPIA_BRN_CODE =
                                         DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE
                                  AND DEPIA_INTERNAL_ACNUM =
                                         DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
                                  AND DEPIA_CONTRACT_NUM =
                                         DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM
                                  AND DEPIA_AUTO_ROLLOVER_SL = 0
                                  AND DEPIA_DATE_OF_ENTRY =
                                         PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

                           L_DTL_SL := NVL (L_DTL_SL, 0) + 1;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              L_DTL_SL := 1;
                        END;

                        BEGIN
                           SELECT TDSPM_PAYABLE_GLACC_CODE
                             INTO L_TDS_GLACC_CODE
                             FROM TDSPARAM
                            WHERE TDSPM_INT_CURR_CODE =
                                     DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              PKG_ERR_MSG :=
                                    'GL Access Code For TDS not Specified for Currency Code'
                                 || DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
                           WHEN OTHERS
                           THEN
                              PKG_ERR_MSG :=
                                    'ERROR IN TDS GL FETCH'
                                 || SUBSTR (SQLERRM, 1, 500);
                              RAISE E_USER_EXCEP;
                        END;

                        PKG_TDS.SP_TDS_ACCWISE (
                           V_GLOB_ENTITY_NUM,
                           DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE,
                           L_PROD_CODE,
                           L_CLIENT_CODE,
                           DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM,
                           DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT,
                           DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM,
                           0,
                           PKG_EODSOD_FLAGS.PV_CURRENT_DATE,    --In value end
                           L_TDS_RATE,
                           L_SUR_RATE,
                           L_TDS_AMT,
                           L_SUR_CHG,
                           TOTAL_TDS_AMT,
                           W_EXEMP_TDS_PER,
                           W_TDS_EXEMP_AMT,
                           L_ERR_MSG,
                           'P',
                           'N');

                        IF L_TDS_AMT > 0
                        THEN
                           -- Remove voucher for L_TDS_AMT
                           --================================================================================================================
                           --TDS ENTRY IN DEPIA
                           --================================================================================================================
                           INSERT INTO DEPIA (DEPIA_ENTITY_NUM,
                                              DEPIA_BRN_CODE,
                                              DEPIA_INTERNAL_ACNUM,
                                              DEPIA_CONTRACT_NUM,
                                              DEPIA_AUTO_ROLLOVER_SL,
                                              DEPIA_DATE_OF_ENTRY,
                                              DEPIA_DAY_SL,
                                              DEPIA_AC_INT_ACCR_AMT,
                                              DEPIA_INT_ACCR_DB_CR,
                                              DEPIA_BC_INT_ACCR_AMT,
                                              DEPIA_AC_FULL_INT_ACCR_AMT,
                                              DEPIA_BC_FULL_INT_ACCR_AMT,
                                              DEPIA_AC_PREV_INT_ACCR_AMT,
                                              DEPIA_BC_PREV_INT_ACCR_AMT,
                                              DEPIA_ACCR_FROM_DATE,
                                              DEPIA_ACCR_UPTO_DATE,
                                              DEPIA_ENTRY_TYPE,
                                              DEPIA_ACCR_POSTED_BY,
                                              DEPIA_ACCR_POSTED_ON,
                                              DEPIA_LAST_MOD_BY,
                                              DEPIA_LAST_MOD_ON,
                                              DEPIA_SOURCE_TABLE,
                                              DEPIA_SOURCE_KEY,
                                              DEPIA_PREV_YR_INT_ACCR)
                                VALUES (
                                          V_GLOB_ENTITY_NUM,
                                          DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE,
                                          DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM,
                                          DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM,
                                          0,
                                          PKG_EODSOD_FLAGS.PV_CURRENT_DATE,
                                          L_DTL_SL,
                                          L_TDS_AMT,
                                          'D',
                                          L_TDS_AMT,
                                          0.000,
                                          0.000,
                                          0.000,
                                          0.000,
                                          DEP_INT_PAY_COLL (IDX).INT_PAY_FROM_DATE,
                                          DEP_INT_PAY_COLL (IDX).INT_PAY_UPTO_DATE,
                                          'TD',
                                          PKG_EODSOD_FLAGS.PV_USER_ID,
                                          PKG_EODSOD_FLAGS.PV_CURRENT_DATE,
                                          '',
                                          NULL,
                                          'PKG_DEP_INT_APPLY',
                                          DEP_INT_PAY_COLL (IDX).DEPIA_SRC_KEY,
                                          0.000);

                           --================================================================================================================
                           --TDS UPDATION
                           --================================================================================================================
                           SP_TDSUPDATION (
                              V_GLOB_ENTITY_NUM,
                              'PKG_DEP_INT_APPLY',
                              'ADD',
                              DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE,
                              L_CLIENT_CODE,
                              L_PROD_CODE,
                              DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR,
                              sp_GetFinYear (
                                 PKG_ENTITY.FN_GET_ENTITY_CODE,
                                 PKG_EODSOD_FLAGS.PV_CURRENT_DATE),
                              DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT,
                              DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM,
                              DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM,
                              0,
                              L_TDS_AMT,
                              L_SUR_CHG,
                              L_OTH_CHG,
                              L_TDS_RATE,
                              L_SUR_RATE,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              PKG_EODSOD_FLAGS.PV_CURRENT_DATE,
                              'PKG_DEP_INT_APPLY',
                              DEP_INT_PAY_COLL (IDX).DEPIA_SRC_KEY,
                              L_ERR_MSG);
                        END IF;
                     END IF;

                     ---Bonus start..
                     IF L_BONUS_AMT > 0
                     THEN
                        BEGIN
                           SELECT NVL (E.EDUTY_GLACC_CODE, 0),
                                  NVL (E.EDUTY_BON_APPL, 0)
                             INTO L_BONUS_GLACC_CODE, L_BON_APPL
                             FROM EDUTY E
                            WHERE     E.EDUTY_ENTITY_NUM = V_GLOB_ENTITY_NUM
                                  AND E.EDUTY_PROD_CODE = L_PROD_CODE;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              L_BONUS_GLACC_CODE := 0;
                              L_BON_APPL := 0;
                        END;

                        IF L_BON_APPL = '1' AND L_BONUS_GLACC_CODE <> 0
                        THEN
                           BEGIN
                              SELECT MAX (AC.ACNTSEXCISE_CLOSURE_SL)
                                INTO L_CLOSURE_SL
                                FROM ACNTSEXCISEBONUS AC
                               WHERE     AC.ACNTSEXCISE_ENTITY_NUM =
                                            V_GLOB_ENTITY_NUM
                                     AND AC.ACNTSEXCISE_INTERNAL_ACNUM =
                                            DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
                                     AND AC.ACNTSEXCISE_BRN_CODE =
                                            DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE
                                     AND AC.ACNTSEXCISE_CONT_NUM =
                                            DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
                           EXCEPTION
                              WHEN NO_DATA_FOUND
                              THEN
                                 L_CLOSURE_SL := 0;
                           END;

                           IF L_CLOSURE_SL <> 0 AND L_CLOSURE_SL > 0
                           THEN
                              L_CLOSURE_SL := L_CLOSURE_SL + 1;
                           ELSE
                              L_CLOSURE_SL := 1;
                           END IF;

                           IF L_TDS_APPL = '1'
                           THEN
                              PKG_TDS.SP_TDS_ACCWISE (
                                 V_GLOB_ENTITY_NUM,
                                 DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE,
                                 L_PROD_CODE,
                                 L_CLIENT_CODE,
                                 DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM,
                                 L_BONUS_AMT,
                                 DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM,
                                 0,
                                 PKG_EODSOD_FLAGS.PV_CURRENT_DATE, --In value end
                                 L_TDS_RATE,
                                 L_SUR_RATE,
                                 L_TAX_ON_BONUS,
                                 L_SUR_CHG,
                                 TOTAL_TDS_AMT,
                                 W_EXEMP_TDS_PER,
                                 W_TDS_EXEMP_AMT,
                                 L_ERR_MSG,
                                 'P',
                                 'N');
                           END IF;

                           TRAN_IDX := TRAN_IDX + 1;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_INTERNAL_ACNUM :=
                              DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CONTRACT_NUM :=
                              DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG :=
                              'C';
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
                              DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
                              DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
                              PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT :=
                              L_BONUS_AMT;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
                              'BONUS CREDIT ' || 'FOR ';
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
                                 FACNO (
                                    V_GLOB_ENTITY_NUM,
                                    DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM)
                              || ' / '
                              || DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
                           TRAN_IDX := TRAN_IDX + 1;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_GLACC_CODE :=
                              L_BONUS_GLACC_CODE;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG :=
                              'D';
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
                              DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
                              DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
                              PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT :=
                              L_BONUS_AMT;
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
                              'BONUS DEBIT' || 'FROM ';
                           PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
                              ' ' || L_BONUS_GLACC_CODE;

                           IF L_TAX_ON_BONUS > 0
                           THEN
                              -- Remove voucher for L_TAX_ON_BONUS
                              SP_TDSUPDATION (
                                 V_GLOB_ENTITY_NUM,
                                 'PKG_FD_PAY',
                                 'ADD',
                                 DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE,
                                 L_CLIENT_CODE,
                                 L_PROD_CODE,
                                 DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR,
                                 SP_GETFINYEAR (
                                    V_GLOB_ENTITY_NUM,
                                    PKG_EODSOD_FLAGS.PV_CURRENT_DATE),
                                 L_BONUS_AMT,
                                 DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM,
                                 DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM,
                                 0,
                                 L_TAX_ON_BONUS,
                                 L_SUR_CHG,
                                 L_OTH_CHG,
                                 L_TDS_RATE,
                                 L_SUR_RATE,
                                 0,
                                 0,
                                 0,
                                 0,
                                 0,
                                 0,
                                 PKG_EODSOD_FLAGS.PV_CURRENT_DATE,
                                 'PKG_FD_PAY',
                                 DEP_INT_PAY_COLL (IDX).DEPIA_SRC_KEY,
                                 L_ERR_MSG);
                           END IF;

                           INSERT
                             INTO ACNTSEXCISEBONUS (
                                     ACNTSEXCISE_ENTITY_NUM,
                                     ACNTSEXCISE_BRN_CODE,
                                     ACNTSEXCISE_INTERNAL_ACNUM,
                                     ACNTSEXCISE_CONT_NUM,
                                     ACNTSEXCISE_CLOSURE_SL,
                                     ACNTSEXCISE_CLOSURE_DATE,
                                     ACNTSEXCISE_FIN_YEAR,
                                     ACNTSEXCISE_EXCISE_AMT,
                                     ACNTSEXCISE_BONUS_AMT,
                                     POST_TRAN_BRN,
                                     POST_TRAN_DATE,
                                     POST_TRAN_BATCH_NUM,
                                     ACNTSEXCISE_ENTD_BY,
                                     ACNTSEXCISE_ENTD_ON,
                                     ACNTSEXCISE_LAST_MOD_BY,
                                     ACNTSEXCISE_LAST_MOD_ON,
                                     ACNTSEXCISE_AUTH_BY,
                                     ACNTSEXCISE_AUTH_ON,
                                     ACNTSEXCISE_REJ_BY,
                                     ACNTSEXCISE_REJ_ON,
                                     ACNTSEXCISE_BONUS_ENTRY_TYPE,
                                     ACNTSEXCISE_EXCISE_ON_AMT,
                                     ACNTSEXCISE_TAX_ON_BONUS)
                           VALUES (
                                     V_GLOB_ENTITY_NUM,
                                     DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE,
                                     DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM,
                                     DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM,
                                     L_CLOSURE_SL,
                                     PKG_EODSOD_FLAGS.PV_CURRENT_DATE,
                                     sp_GetFinYear (
                                        V_GLOB_ENTITY_NUM,
                                        PKG_EODSOD_FLAGS.PV_CURRENT_DATE),
                                     0.000,
                                     L_BONUS_AMT,
                                     '',
                                     NULL,
                                     '',
                                     PKG_EODSOD_FLAGS.PV_USER_ID,
                                     PKG_EODSOD_FLAGS.PV_CURRENT_DATE,
                                     '',
                                     NULL,
                                     '',
                                     NULL,
                                     '',
                                     NULL,
                                     'BP',
                                     '',
                                     L_TAX_ON_BONUS);
                        ELSE
                           L_BONUS_AMT := 0;
                           L_TAX_ON_BONUS := 0;
                        END IF;
                     ELSE
                        L_BONUS_AMT := 0;
                        L_TAX_ON_BONUS := 0;
                     END IF;

                     --TDS Posting start...
                     L_COMBINED_TDS :=
                        NVL (L_TDS_AMT, 0) + NVL (L_TAX_ON_BONUS, 0);

                     IF L_TDS_APPL = '1' AND L_COMBINED_TDS > 0
                     THEN
                        TRAN_IDX := TRAN_IDX + 1;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_GLACC_CODE :=
                           L_TDS_GLACC_CODE;
                        --PKG_AUTOPOST.PV_TRAN_REC(TRAN_IDX).TRAN_CONTRACT_NUM := DEP_INT_PAY_COLL(IDX).PBDCONT_CONT_NUM;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG :=
                           'C';
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
                           DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
                           DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
                           PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT :=
                           L_COMBINED_TDS;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
                           'TDS ON BONUS+INT T0 ';
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
                           ' ' || L_TDS_GLACC_CODE;
                        TRAN_IDX := TRAN_IDX + 1;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_INTERNAL_ACNUM :=
                           DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CONTRACT_NUM :=
                           DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG :=
                           'D';
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
                           DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
                           DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
                           PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT :=
                           L_COMBINED_TDS;
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
                           'TDS ON BONUS+INT FOR ';
                        PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
                              FACNO (
                                 V_GLOB_ENTITY_NUM,
                                 DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM)
                           || ' / '
                           || DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
                     END IF;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     PKG_ERR_MSG := SUBSTR (SQLERRM, 1, 500);
                     RAISE E_USER_EXCEP;
               END CHECK_TDS_BONUS_APPL;

               V_PRINCIPAL_ADJUSTMENT := 0;

               IF     DEP_INT_PAY_COLL (IDX).PBDCONT_INT_CR_TO_ACNT <> 0
                  AND DEP_INT_PAY_COLL (IDX).DEPPR_INT_PAY_FREQ <> 'X'
               THEN
                  BEGIN
                     GET_ASON_CONTBAL (
                        V_GLOB_ENTITY_NUM,
                        DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM,
                        DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR,
                        DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM,
                        V_ASON_BUSI_DATE,
                        V_ASON_BUSI_DATE,
                        V_ACCBAL_ADJ,
                        V_ACCBAL_ADJ,
                        PKG_ERR_MSG);

                     IF DEP_INT_PAY_COLL (IDX).PBDCONT_AC_DEP_AMT >
                           V_ACCBAL_ADJ
                     THEN
                        V_PRINCIPAL_ADJUSTMENT :=
                             DEP_INT_PAY_COLL (IDX).PBDCONT_AC_DEP_AMT
                           - V_ACCBAL_ADJ;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        PKG_ERR_MSG :=
                              'Error in adjustment prencipal amount '
                           || DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
                           || SQLERRM;
                  END;

                  IF   DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT
                     + L_BONUS_AMT
                     - L_TDS_AMT
                     - L_TAX_ON_BONUS <= V_PRINCIPAL_ADJUSTMENT
                  THEN
                     V_PRINCIPAL_ADJUSTMENT :=
                          DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT
                        + L_BONUS_AMT
                        - L_TDS_AMT
                        - L_TAX_ON_BONUS;
                  ELSE
                     L_STL_AMT :=
                          DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT
                        + L_BONUS_AMT
                        - L_TDS_AMT
                        - L_TAX_ON_BONUS
                        - V_PRINCIPAL_ADJUSTMENT;
                     TRAN_IDX := TRAN_IDX + 1;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_INTERNAL_ACNUM :=
                        DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CONTRACT_NUM :=
                        DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG := 'D';
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
                        DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
                        DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
                        PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT :=
                        L_STL_AMT;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
                        'INTEREST PAYMENT DEDUCTION' || 'FOR ';
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
                           FACNO (V_GLOB_ENTITY_NUM,
                                  DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM)
                        || ' / '
                        || DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL3 :=
                           ' From '
                        || DEP_INT_PAY_COLL (IDX).INT_PAY_FROM_DATE
                        || 'upto '
                        || DEP_INT_PAY_COLL (IDX).INT_PAY_UPTO_DATE;
                     TRAN_IDX := TRAN_IDX + 1;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_INTERNAL_ACNUM :=
                        DEP_INT_PAY_COLL (IDX).PBDCONT_INT_CR_TO_ACNT;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG := 'C';
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
                        DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
                        DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
                        PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT :=
                        L_STL_AMT;
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
                        'INTEREST APPLIED To STL A/c';
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
                           ' '
                        || FACNO (
                              V_GLOB_ENTITY_NUM,
                              DEP_INT_PAY_COLL (IDX).PBDCONT_INT_CR_TO_ACNT)
                        || ' ';
                     PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL3 :=
                           ' From '
                        || DEP_INT_PAY_COLL (IDX).INT_PAY_FROM_DATE
                        || 'upto '
                        || DEP_INT_PAY_COLL (IDX).INT_PAY_UPTO_DATE;
                  END IF;
               END IF;

               IF L_TDS_AMT > 0 OR V_PRINCIPAL_ADJUSTMENT > 0
               THEN
                  DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT :=
                     DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT - L_TDS_AMT;
               END IF;
            ELSIF DEP_INT_PAY_COLL (IDX).DEPINTPAY_MODE_OF_PAY = 'P'
            THEN
               TRAN_IDX := TRAN_IDX + 1;
               PKG_DDPO_CREDIT_POST.SP_DDPO_CREDIT_POST (
                  V_GLOB_ENTITY_NUM,
                  DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE,
                  DEP_INT_PAY_COLL (IDX).PBDCONTDSA_REMIT_CODE,
                  DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR,
                  DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT,
                  PKG_EODSOD_FLAGS.PV_CURRENT_DATE);

               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL1 :=
                  'Interest Credited To Deposit A/c ' || 'For ';
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL2 :=
                     FACNO (V_GLOB_ENTITY_NUM,
                            DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM)
                  || ' / '
                  || DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
               PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_NARR_DTL3 :=
                     ' From '
                  || DEP_INT_PAY_COLL (IDX).INT_PAY_FROM_DATE
                  || 'upto '
                  || DEP_INT_PAY_COLL (IDX).INT_PAY_UPTO_DATE;
               TRAN_IDX := PKG_AUTOPOST.PV_TRAN_REC.COUNT;
            -------
            END IF;
         --------
         END LOOP;

         W_DEP_INT_ACCR_GL_KEY := DEPINT_ACCR_GL_COLL.FIRST;

         WHILE W_DEP_INT_ACCR_GL_KEY IS NOT NULL
         LOOP
            TRAN_IDX := TRAN_IDX + 1;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_DB_CR_FLG := 'D';
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_CURR_CODE :=
               DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).DEP_CURR;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_ACING_BRN_CODE :=
               W_BRN_CODE;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_GLACC_CODE :=
               DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).INT_ACCR_GL;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_AMOUNT :=
               DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).AC_AMT;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_BASE_CURR_EQ_AMT :=
               DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).BC_AMT;
            PKG_AUTOPOST.PV_TRAN_REC (TRAN_IDX).TRAN_VALUE_DATE :=
               PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
            W_DEP_INT_ACCR_GL_KEY :=
               DEPINT_ACCR_GL_COLL.NEXT (W_DEP_INT_ACCR_GL_KEY);
         END LOOP;
      END SET_TRAN_VALUES;

   BEGIN
      W_CBD := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      SET_TRAN_KEY_VALUES;
      SET_TRANBAT_VALUES;
      SET_TRAN_VALUES;

      PKG_APOST_INTERFACE.SP_POST_SODEOD_BATCH (V_GLOB_ENTITY_NUM,
                                                'A',
                                                TRAN_IDX,
                                                0,
                                                W_ERR_CODE,
                                                PKG_ERR_MSG,
                                                W_BATCH_NUM);

      IF (W_ERR_CODE <> '0000')
      THEN
         PKG_ERR_MSG := 'Autopost Error Code:' || W_ERR_CODE;
         PKG_ERR_MSG :=
               PKG_ERR_MSG
            || '. Message:'
            || FN_GET_AUTOPOST_ERR_MSG (V_GLOB_ENTITY_NUM);
         RAISE E_AUTOPOST_EXP;
      END IF;

      W_DDPO_BATCH_NUM := W_BATCH_NUM;
      PKG_APOST_INTERFACE.SP_POSTING_END (V_GLOB_ENTITY_NUM);
      RETURN TRUE;
   EXCEPTION
      WHEN E_AUTOPOST_EXP
      THEN
         RETURN FALSE;
      WHEN OTHERS
      THEN
         PKG_ERR_MSG :=
               PKG_ERR_MSG
            || 'Error in AutoPostInt-when others. '
            || SQLERRM
            || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
         RETURN FALSE;
   END AUTOPOSTINT;

   -----------------------------------------------
   PROCEDURE DDPOUPDATE (L IN NUMBER)
   IS
      W_ACNTS_AC_NAME1   VARCHAR (50);
   BEGIN
      PKG_DDPOUPDATE.DDPOISS_REC.DDPOISS_BRN_CODE :=
         DEP_INT_PAY_COLL (L).PBDCONT_BRN_CODE;
      PKG_DDPOUPDATE.DDPOISS_REC.DDPOISS_REMIT_CODE :=
         DEP_INT_PAY_COLL (L).PBDCONTDSA_REMIT_CODE;
      PKG_DDPOUPDATE.DDPOISS_REC.DDPOISS_ISSUE_DATE := W_CBD;
      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_PUR_ACNT :=
         DEP_INT_PAY_COLL (L).PBDCONT_DEP_AC_NUM;
      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_PUR_CLIENT_NUM :=
         DEP_INT_PAY_COLL (L).ACNTS_CLIENT_NUM;
      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_PUR_NAME :=
         DEP_INT_PAY_COLL (L).ACNTS_NAME1;
      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_INST_CURRENCY :=
         DEP_INT_PAY_COLL (L).PBDCONT_DEP_CURR;
      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_TOT_INST_AMT :=
         DEP_INT_PAY_COLL (L).AC_INT_PAY_AMT;
      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_TOT_ACTUAL_COMM := 0;
      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_TOT_STAX_AMT := 0;
      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_TOT_DB_AMT :=
         DEP_INT_PAY_COLL (L).AC_INT_PAY_AMT;

      IF (W_DDPO_BATCH_NUM <> 0)
      THEN
         PKG_DDPOUPDATE.DDPOISS_VALREC.POST_TRAN_BRN :=
            DEP_INT_PAY_COLL (L).PBDCONT_BRN_CODE;
         PKG_DDPOUPDATE.DDPOISS_VALREC.POST_TRAN_DATE := W_CBD;
         PKG_DDPOUPDATE.DDPOISS_VALREC.POST_TRAN_BATCH_NUM := W_DDPO_BATCH_NUM;
      END IF;

      PKG_DDPOUPDATE.DDPOISS_VALREC.DDPOISS_USER_ID :=
         PKG_EODSOD_FLAGS.PV_USER_ID;
      PKG_DDPOUPDATE.DDPOISSDTL_VALREC.DDPOISSDTL_INST_BANK :=
         PKG_PB_GLOBAL.FN_GET_INSBANK_CODE (V_GLOB_ENTITY_NUM);
      PKG_DDPOUPDATE.DDPOISSDTL_VALREC.DDPOISSDTL_INST_BRN :=
         DEP_INT_PAY_COLL (L).PBDCONT_BRN_CODE;
      PKG_DDPOUPDATE.DDPOISSDTL_VALREC.DDPOISSDTL_BENEF_CODE := ' ';
      PKG_DDPOUPDATE.DDPOISSDTL_VALREC.DDPOISSDTL_BENEF_NAME1 :=
         DEP_INT_PAY_COLL (L).ACNTS_NAME1;
      PKG_DDPOUPDATE.DDPOISSDTL_VALREC.DDPOISSDTL_BENEF_NAME2 :=
         DEP_INT_PAY_COLL (L).ACNTS_NAME2;
      PKG_DDPOUPDATE.DDPOISSDTL_VALREC.DDPOISSDTL_ON_AC_OF :=
         DEP_INT_PAY_COLL (L).PBDCONTDSA_ON_AC_OF;
      PKG_DDPOUPDATE.SP_DDPOUPDATE (V_GLOB_ENTITY_NUM);       --ENTITY CHANGES
      W_DDPOKEY := PKG_DDPOUPDATE.DDPO_KEY;

      IF (TRIM (PKG_DDPOUPDATE.DDPO_ERR_MSG) IS NOT NULL)
      THEN
         PKG_ERR_MSG := PKG_DDPOUPDATE.DDPO_ERR_MSG;
         RAISE E_USER_EXCEP;
      END IF;
   END DDPOUPDATE;

   -----------------------------------------------
   FUNCTION WRITEDEPINTPAYMENT
      RETURN BOOLEAN
   IS
      IDX                         NUMBER (8);
      P_DEPINTPAY_INT_PAY_SL      NUMBER (3);
      P_DEPINTPAYDTL_INT_PAY_SL   NUMBER (3);
      P_DEPINTPAYDTL_INT_DTL_SL   NUMBER (3);
   BEGIN
      FOR IDX IN 1 .. DEP_INT_PAY_COLL.COUNT
      LOOP
         SELECT MAX (DEPINTPAY_INT_PAY_SL)
           INTO P_DEPINTPAY_INT_PAY_SL
           FROM DEPINTPAYMENT
          WHERE     DEPINTPAY_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND DEPINTPAY_BRN_CODE =
                       DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE
                AND DEPINTPAY_DEP_AC_NUM =
                       DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
                AND DEPINTPAY_CONT_NUM =
                       DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;

         P_DEPINTPAY_INT_PAY_SL := NVL (P_DEPINTPAY_INT_PAY_SL, 0) + 1;

         SELECT MAX (DL.DEPINTPAYDT_INT_PAY_SL), MAX (DL.DEPINTPAYDT_DTL_SL)
           INTO P_DEPINTPAYDTL_INT_PAY_SL, P_DEPINTPAYDTL_INT_DTL_SL
           FROM DEPINTPAYMENTDTL DL
          WHERE     DL.DEPINTPAYDT_ENTITY_NUM = V_GLOB_ENTITY_NUM
                AND DL.DEPINTPAYDT_BRN_CODE =
                       DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE
                AND DL.DEPINTPAYDT_DEP_AC_NUM =
                       DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
                AND DL.DEPINTPAYDT_CONT_NUM =
                       DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;

         P_DEPINTPAYDTL_INT_PAY_SL := NVL (P_DEPINTPAYDTL_INT_PAY_SL, 0) + 1;
         P_DEPINTPAYDTL_INT_DTL_SL := NVL (P_DEPINTPAYDTL_INT_DTL_SL, 0) + 1;

         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_BRN_CODE :=
            DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_DEP_AC_NUM :=
            DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_CONT_NUM :=
            DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_INT_PAY_SL :=
            P_DEPINTPAY_INT_PAY_SL;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_AUTO_MANUAL := 'A';
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_INT_PAID_UPTO_DATE :=
            DEP_INT_PAY_COLL (IDX).INT_PAY_UPTO_DATE;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_PAYMENT_CURR :=
            DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_CURR;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_PAYMENT_AMT :=
            DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_ENTD_BY :=
            PKG_EODSOD_FLAGS.PV_USER_ID;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_ENTD_ON :=
            PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_LAST_MOD_BY := NULL;
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_LAST_MOD_ON := NULL;
         V_DEPINTPAYMNT_COLL (IDX).POST_TRAN_BRN := 0;
         V_DEPINTPAYMNT_COLL (IDX).POST_TRAN_DATE := NULL;
         V_DEPINTPAYMNT_COLL (IDX).POST_TRAN_BATCH_NUM := 0;
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_BRN_CODE :=
            DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_DEP_AC_NUM :=
            DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM;
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_CONT_NUM :=
            DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_INT_PAY_SL :=
            P_DEPINTPAYDTL_INT_PAY_SL;
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_DTL_SL :=
            P_DEPINTPAYDTL_INT_DTL_SL;
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_STLMNT_AC_NUM :=
            DEP_INT_PAY_COLL (IDX).PBDCONT_INT_CR_TO_ACNT;
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_TYPE_OF_CR := 'F';
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_AMT_OF_CR :=
            DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT;
         DEP_INT_PAY_COLL (IDX).DEPIA_SRC_KEY :=
               DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE
            || '|'
            || DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
            || '|'
            || DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM
            || '|'
            || P_DEPINTPAY_INT_PAY_SL;

         IF DEP_INT_PAY_COLL (IDX).DEPINTPAY_MODE_OF_PAY = 'P'
         THEN
            DDPOUPDATE (IDX);
         END IF;

         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_MODE_OF_PAY :=
            DEP_INT_PAY_COLL (IDX).DEPINTPAY_MODE_OF_PAY;

         IF DEP_INT_PAY_COLL (IDX).DEPINTPAY_MODE_OF_PAY = 'E'
         THEN
            V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_ECS_PO_DTLS :=
               DEP_INT_PAY_COLL (IDX).DEPINTPAY_ECS_PO_DTLS;
         ELSIF DEP_INT_PAY_COLL (IDX).DEPINTPAY_MODE_OF_PAY = 'P'
         THEN
            V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_ECS_PO_DTLS := W_DDPOKEY;
         END IF;
      END LOOP;

      FOR IDX IN 1 .. V_DEPINTPAYMNT_COLL.COUNT
      LOOP
         V_DEPINTPAYMNT_COLL (IDX).DEPINTPAY_ENTITY_NUM := V_GLOB_ENTITY_NUM;
      END LOOP;

      FORALL IDX IN 1 .. V_DEPINTPAYMNT_COLL.COUNT
         INSERT INTO DEPINTPAYMENT
              VALUES V_DEPINTPAYMNT_COLL (IDX);

      FOR IDX IN 1 .. V_DEPINTPAYMNTDTL_COLL.COUNT
      LOOP
         V_DEPINTPAYMNTDTL_COLL (IDX).DEPINTPAYDT_ENTITY_NUM :=
            V_GLOB_ENTITY_NUM;
      END LOOP;

      FORALL IDX IN 1 .. V_DEPINTPAYMNTDTL_COLL.COUNT
         INSERT INTO DEPINTPAYMENTDTL
              VALUES V_DEPINTPAYMNTDTL_COLL (IDX);

      V_DEPINTPAYMNT_COLL.DELETE;
      V_DEPINTPAYMNTDTL_COLL.DELETE;
      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         PKG_ERR_MSG := SUBSTR (SQLERRM, 1, 500);
         RETURN FALSE;
   END WRITEDEPINTPAYMENT;

   -----------------------------------------------
   FUNCTION WRITEDEPIA
      RETURN BOOLEAN
   IS
      W_DEPIA_DAY_SL   NUMBER (5) := 0;
      IDX              NUMBER (8) := 0;
   BEGIN
      BEGIN
         FOR IDX IN 1 .. DEP_INT_PAY_COLL.COUNT
         LOOP
            SELECT MAX (DEPIA_DAY_SL)
              INTO W_DEPIA_DAY_SL
              FROM DEPIA
             WHERE     DEPIA_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND DEPIA_BRN_CODE =
                          DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE
                   AND DEPIA_INTERNAL_ACNUM =
                          DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
                   AND DEPIA_CONTRACT_NUM =
                          DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM
                   AND DEPIA_AUTO_ROLLOVER_SL = 0
                   AND DEPIA_DATE_OF_ENTRY = PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

            W_DEPIA_DAY_SL := NVL (W_DEPIA_DAY_SL, 0) + 1;

            V_DEPIA_COLL (IDX).DEPIA_BRN_CODE :=
               DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE;
            V_DEPIA_COLL (IDX).DEPIA_INTERNAL_ACNUM :=
               DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM;
            V_DEPIA_COLL (IDX).DEPIA_CONTRACT_NUM :=
               DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
            V_DEPIA_COLL (IDX).DEPIA_AUTO_ROLLOVER_SL := 0;
            V_DEPIA_COLL (IDX).DEPIA_DATE_OF_ENTRY :=
               PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
            V_DEPIA_COLL (IDX).DEPIA_DAY_SL := W_DEPIA_DAY_SL;
            V_DEPIA_COLL (IDX).DEPIA_AC_INT_ACCR_AMT :=
               DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT;
            V_DEPIA_COLL (IDX).DEPIA_INT_ACCR_DB_CR := 'D';
            V_DEPIA_COLL (IDX).DEPIA_BC_INT_ACCR_AMT :=
               DEP_INT_PAY_COLL (IDX).BC_INT_PAY_AMT;
            V_DEPIA_COLL (IDX).DEPIA_AC_FULL_INT_ACCR_AMT :=
                 DEP_INT_PAY_COLL (IDX).AC_PREV_INT_PAY_AMT
               + DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT;
            V_DEPIA_COLL (IDX).DEPIA_BC_FULL_INT_ACCR_AMT :=
                 DEP_INT_PAY_COLL (IDX).BC_PREV_INT_PAY_AMT
               + DEP_INT_PAY_COLL (IDX).BC_INT_PAY_AMT;
            V_DEPIA_COLL (IDX).DEPIA_AC_PREV_INT_ACCR_AMT :=
               DEP_INT_PAY_COLL (IDX).AC_PREV_INT_PAY_AMT;
            V_DEPIA_COLL (IDX).DEPIA_BC_PREV_INT_ACCR_AMT :=
               DEP_INT_PAY_COLL (IDX).BC_PREV_INT_PAY_AMT;
            V_DEPIA_COLL (IDX).DEPIA_ACCR_FROM_DATE :=
               DEP_INT_PAY_COLL (IDX).INT_PAY_FROM_DATE;
            V_DEPIA_COLL (IDX).DEPIA_ACCR_UPTO_DATE :=
               DEP_INT_PAY_COLL (IDX).INT_PAY_UPTO_DATE;
            V_DEPIA_COLL (IDX).DEPIA_ENTRY_TYPE := 'IP';
            V_DEPIA_COLL (IDX).DEPIA_ACCR_POSTED_BY :=
               PKG_EODSOD_FLAGS.PV_USER_ID;
            V_DEPIA_COLL (IDX).DEPIA_ACCR_POSTED_ON :=
               PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
            V_DEPIA_COLL (IDX).DEPIA_LAST_MOD_BY := NULL;
            V_DEPIA_COLL (IDX).DEPIA_LAST_MOD_ON := NULL;
            V_DEPIA_COLL (IDX).DEPIA_SOURCE_TABLE := 'PKG_DEP_INT_APPLY';
            V_DEPIA_COLL (IDX).DEPIA_SOURCE_KEY :=
               DEP_INT_PAY_COLL (IDX).DEPIA_SRC_KEY;
         END LOOP;

         FOR IDX IN 1 .. V_DEPIA_COLL.COUNT
         LOOP
            V_DEPIA_COLL (IDX).DEPIA_ENTITY_NUM := V_GLOB_ENTITY_NUM;
         END LOOP;

         FORALL IDX IN 1 .. V_DEPIA_COLL.COUNT
            INSERT INTO DEPIA
                 VALUES V_DEPIA_COLL (IDX);

         V_DEPIA_COLL.DELETE;

         RETURN TRUE;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         PKG_ERR_MSG := SUBSTR (SQLERRM, 1, 500);
         RETURN FALSE;
   END WRITEDEPIA;

   -----------------------------------------------
   FUNCTION WRITE_DEPECSQ
      RETURN BOOLEAN
   IS
   BEGIN
      FORALL IDX IN 1 .. ECS_INT_PAY_COLL.COUNT
         INSERT INTO DEPECSQ
              VALUES ECS_INT_PAY_COLL (IDX);

      ECS_INT_PAY_COLL.DELETE;
      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         PKG_ERR_MSG := SUBSTR (SQLERRM, 1, 500);
         RETURN FALSE;
   END WRITE_DEPECSQ;

   -----------------------------------------------
   PROCEDURE UPDATE_PARA
   IS
   BEGIN
      IF NOT AUTOPOSTINT
      THEN
         RAISE E_USER_EXCEP;
      END IF;

      IF NOT WRITEDEPINTPAYMENT
      THEN
         RAISE E_USER_EXCEP;
      END IF;

      IF NOT WRITEDEPIA
      THEN
         RAISE E_USER_EXCEP;
      END IF;

      IF NOT WRITE_DEPECSQ
      THEN
         RAISE E_USER_EXCEP;
      END IF;

      BEGIN
         FOR IDX IN 1 .. DEP_INT_PAY_COLL.COUNT
         LOOP
            UPDATE PBDCONTRACT
               SET PBDCONT_INT_PAID_UPTO =
                      DEP_INT_PAY_COLL (IDX).INT_PAY_UPTO_DATE,
                   PBDCONT_AC_INT_PAY_AMT =
                        NVL (PBDCONT_AC_INT_PAY_AMT, 0)
                      + DEP_INT_PAY_COLL (IDX).AC_INT_PAY_AMT,
                   PBDCONT_BC_INT_PAY_AMT =
                        NVL (PBDCONT_BC_INT_PAY_AMT, 0)
                      + DEP_INT_PAY_COLL (IDX).BC_INT_PAY_AMT
             WHERE     PBDCONT_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND PBDCONT_BRN_CODE =
                          DEP_INT_PAY_COLL (IDX).PBDCONT_BRN_CODE
                   AND PBDCONT_DEP_AC_NUM =
                          DEP_INT_PAY_COLL (IDX).PBDCONT_DEP_AC_NUM
                   AND PBDCONT_CONT_NUM =
                          DEP_INT_PAY_COLL (IDX).PBDCONT_CONT_NUM;
         END LOOP;
      END;
   END UPDATE_PARA;

   -----------------------------------------------
   PROCEDURE INIT_PARA
   IS
   BEGIN
      IS_ELIGIBLE := 1;
   END INIT_PARA;

   FUNCTION GET_END_DATE (P_DATE        IN DATE,
                                          P_FREQUENCE   IN CHAR)
   RETURN DATE
IS
   W_SQL        VARCHAR2 (10000);
   FINAL_DATE   DATE;
BEGIN
   IF P_FREQUENCE = 'M'
   THEN
      SELECT LAST_DAY (ADD_MONTHS (P_DATE + 1, -1)) INTO FINAL_DATE FROM DUAL;
   ELSIF P_FREQUENCE = 'Q'
   THEN
      SELECT TRUNC (P_DATE + 1, P_FREQUENCE) - 1 INTO FINAL_DATE FROM DUAL;
   ELSIF P_FREQUENCE = 'H'
   THEN
      SELECT CASE
                WHEN    TO_NUMBER (TO_CHAR (P_DATE, 'MM')) > 6
                     OR TO_CHAR (P_DATE, 'DD-MON') = '30-JUN'
                THEN
                   CASE
                      WHEN TO_CHAR (P_DATE, 'DD-MON') = '31-DEC'
                      THEN
                         TO_DATE (
                               '31-DEC-'
                            || TO_CHAR (TO_NUMBER (TO_CHAR (P_DATE, 'YYYY'))))
                      ELSE
                         TO_DATE ('30-JUN-' || TO_CHAR (P_DATE, 'YYYY'))
                   END
                ELSE
                   TO_DATE (
                         '31-DEC-'
                      || TO_CHAR (TO_NUMBER (TO_CHAR (P_DATE, 'YYYY')) - 1))
             END
        INTO FINAL_DATE
        FROM DUAL;
   ELSIF P_FREQUENCE = 'Y'
   THEN
      SELECT TRUNC (P_DATE + 1, P_FREQUENCE) - 1 INTO FINAL_DATE FROM DUAL;
   END IF;


   RETURN FINAL_DATE;
END GET_END_DATE;

   PROCEDURE START_DEPINT_PAY (P_ENTITY_NUM     IN NUMBER,
                               P_AS_ON_DATE        DATE DEFAULT NULL,
                               P_BRANCH            NUMBER DEFAULT 0,
                               P_DEP_AC_NUM        NUMBER DEFAULT 0,
                               P_CONTRACT_REF      NUMBER DEFAULT 0)
   IS
      W_NEW_UPTO_DATE          DATE;
      W_AS_ON_DATE             DATE;
      W_QRY_STRING             VARCHAR2 (4300);
      W_BAL                    NUMBER (18, 3);
      P_ASON_BC_BAL            NUMBER (18, 3);
      W_INT_BAL                NUMBER (18, 3);
      W_START_DATE             DATE;
      W_END_DATE               DATE;
      W_ACT_END_DATE           DATE;
      W_COMPARE_DATE           DATE;
      W_STLMNT_AC              NUMBER (14) DEFAULT 0;
      W_DEPINTPAY_INT_PAY_SL   NUMBER (6);
      W_FREQ                   NUMBER (3);
      L_PREV_BRN               NUMBER (6);
      INTCOLL_IDX              NUMBER (8) := 0;
      ECS_IDX                  NUMBER (8) := 0;
      W_INT_BAL_BC             NUMBER (18, 3);
      PKG_CONV_RATE            NUMBER (14, 9);
      L_ERR_CODE               NUMBER;
      L_ERR_MSG                VARCHAR2 (10);
      P_CONV_ERR_CODE          NUMBER;
      W_DEP_INT_ACCR_GLACC     NUMBER (15);
      W_DEP_INT_ACCR_GL_KEY    VARCHAR2 (22);
      W_NOM                    INTEGER;
      W_NOOF_FREQ              INTEGER;
      V_MONTHS_BETN            INTEGER;
      W_FIN_YR                 NUMBER (6);
      W_CBD                    DATE;
      W_DIFF                   NUMBER (4);
      W_PREV_BUS_DATE          DATE;
      W_DUMMY_DATE             DATE;
      W_PROCESS_DEP            NUMBER (1);
      W_DMQHY                  CHAR (1);
      W_INT_RNDOFF_CHOICE      CHAR (1);
      W_INT_RNDOFF_FACTOR      NUMBER (9, 3);
      V_ORG_AC_AMT             NUMBER (18, 3);
      V_ACT_INT_RATE           NUMBER (7, 5);
      V_CALC_CHOICE            CHAR (1);
      V_CALC_DENOM             CHAR (1);
      V_PRD_CHOICE             CHAR (1);
      V_DENOM                  NUMBER (14);
      V_CALC_INT_AMT           NUMBER (18, 3);
      W_ECS_ASON_DATE          DATE;
      W_PO_ASON_DATE           DATE;
      V_NOD                    NUMBER (6);
      L_TABDEPCONT             TY_TAB_DEPCONT;
      V_FACTOR                 NUMBER ;
   -----------------------------------------------

   -----------------------------------------------
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (P_ENTITY_NUM);
      V_GLOB_ENTITY_NUM := P_ENTITY_NUM;
      PKG_APOST_INTERFACE.SP_POSTING_BEGIN (V_GLOB_ENTITY_NUM);

      IF NOT SET_DEP_PROD_CURR_ARRAY ()
      THEN
         PKG_ERR_MSG := 'Error in setting Deposit Product currency Array';
         RAISE E_USER_EXCEP;
      END IF;

      IDX := 0;
      L_PREV_BRN := 0;

      IF P_AS_ON_DATE IS NOT NULL
      THEN
         W_AS_ON_DATE := P_AS_ON_DATE;
      ELSE
         W_AS_ON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      END IF;

      V_ASON_BUSI_DATE := W_AS_ON_DATE;

      IF NOT CHECK_CUTOFF_DATE (W_AS_ON_DATE,
                                W_ECS_ASON_DATE,
                                W_PO_ASON_DATE)
      THEN
         PKG_ERR_MSG := 'Error in Checking Cut Off Date';
         RAISE E_USER_EXCEP;
      END IF;

      W_QRY_STRING :=
            'SELECT T1.PBDCONT_BRN_CODE,
                 T1.PBDCONT_DEP_AC_NUM,
                 T1.PBDCONT_CONT_NUM,
                 T1.PBDCONT_AC_DEP_AMT,
                 T1.PBDCONT_DEP_CURR,
                 T1.PBDCONT_INT_ACCR_UPTO,
                 T1.PBDCONT_INT_PAID_UPTO,
                 T1.PBDCONT_COMPLETED_ROLLOVERS,
                 T1.PBDCONT_EFF_DATE,
                 DECODE(T3.DEPPR_INT_CR_FREQ,''N'',T3.DEPPR_INT_PAY_FREQ,T3.DEPPR_INT_CR_FREQ) DEPPR_INT_CR_FREQ,
                 T3.DEPPR_INT_PAY_FREQ,
                 T1.PBDCONT_INT_CR_TO_ACNT,
                 T3.DEPPR_PROD_CODE,
                 T1.PBDCONT_AC_INT_PAY_AMT,
                 T1.PBDCONT_BC_INT_PAY_AMT,
                 T1.PBDCONT_MAT_DATE,
                 T2.ACNTS_CLIENT_NUM,
                 T2.ACNTS_AC_NAME1,
                 T2.ACNTS_AC_NAME2,
                 T1.PBDCONT_INT_CALC_PAYABLE_UPTO,
                 NVL(T4.PWGENPARAM_MES_APP, ''0'') PWGENPARAM_MES_APP,
                 T3.DEPPR_TYPE_OF_DEP
                 FROM PBDCONTRACT T1, ACNTS T2 , DEPPROD T3
                 LEFT JOIN PWGENPARAM T4 ON T3.DEPPR_PROD_CODE = T4.PWGENPARAM_PROD_CODE
                 WHERE
                 ACNTS_ENTITY_NUM = :ENTITY_CODE AND PBDCONT_ENTITY_NUM = :ENTITY_CODE '
         || ' AND PBDCONT_AUTH_ON IS NOT NULL AND PBDCONT_EFF_DATE <= '
         || CHR (39)
         || W_AS_ON_DATE
         || CHR (39)
         || ' AND PBDCONT_AC_DEP_AMT > 0  ';

      IF P_DEP_AC_NUM = 0
      THEN
         W_QRY_STRING :=
               W_QRY_STRING
            || ' AND PBDCONT_MAT_DATE >= '
            || CHR (39)
            || W_AS_ON_DATE
            || CHR (39);
      --|| AND PBDCONT_INT_PAY_FREQ <> '|| CHR(39)||'X'||CHR(39) ;
      END IF;

      W_QRY_STRING :=
            W_QRY_STRING
         || ' AND T2.ACNTS_INTERNAL_ACNUM=T1.PBDCONT_DEP_AC_NUM
                 AND T2.ACNTS_PROD_CODE=T3.DEPPR_PROD_CODE AND T1.PBDCONT_CLOSURE_DATE IS NULL
                 AND DEPPR_TYPE_OF_DEP in ('
         || CHR (39)
         || '1'
         || CHR (39)
         || ','
         || CHR (39)
         || '2'
         || CHR (39)
         || ')';

      IF P_BRANCH <> 0
      THEN
         W_QRY_STRING := W_QRY_STRING || ' AND PBDCONT_BRN_CODE=' || P_BRANCH;
      END IF;

      IF P_CONTRACT_REF <> 0
      THEN
         W_QRY_STRING :=
            W_QRY_STRING || ' AND PBDCONT_CONT_NUM=' || P_CONTRACT_REF;
      END IF;

      IF P_DEP_AC_NUM <> 0
      THEN
         W_QRY_STRING :=
            W_QRY_STRING || ' AND PBDCONT_DEP_AC_NUM=' || P_DEP_AC_NUM;
      END IF;

      --W_QRY_STRING := W_QRY_STRING || ' AND PBDCONT_DEP_AC_NUM= 10007500004185 ';

      W_QRY_STRING :=
            W_QRY_STRING
         || ' ORDER BY PBDCONT_BRN_CODE, DEPPR_TYPE_OF_DEP, DEPPR_PROD_CODE';

      --DBMS_OUTPUT.PUT_LINE(W_QRY_STRING);
      --SP_DISP(V_GLOB_ENTITY_NUM, W_QRY_STRING);

      EXECUTE IMMEDIATE W_QRY_STRING
         BULK COLLECT INTO L_TABDEPCONT
         USING V_GLOB_ENTITY_NUM, V_GLOB_ENTITY_NUM;

      --DBMS_OUTPUT.PUT_LINE(L_TABDEPCONT.COUNT);

      FOR I IN 1 .. L_TABDEPCONT.COUNT
      LOOP
         INIT_PARA;

         IF P_AS_ON_DATE IS NOT NULL
         THEN
            W_AS_ON_DATE := P_AS_ON_DATE;
         ELSE
            W_AS_ON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
         END IF;

         IF L_TABDEPCONT (I).DEPPR_TYPE_OF_DEP = '1'
         THEN
            GET_ASON_CONTBAL (
               V_GLOB_ENTITY_NUM,
               L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM,
               L_TABDEPCONT (I).PBDCONT_DEP_CURR,
               L_TABDEPCONT (I).PBDCONT_CONT_NUM,
               W_AS_ON_DATE,
               PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_GLOB_ENTITY_NUM),
               P_ASON_BC_BAL,
               P_ASON_BC_BAL,
               PKG_ERR_MSG);
         ELSIF L_TABDEPCONT (I).DEPPR_TYPE_OF_DEP = '2'
         THEN
            GET_ASON_ACBAL (
               V_GLOB_ENTITY_NUM,
               L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM,
               L_TABDEPCONT (I).PBDCONT_DEP_CURR,
               W_AS_ON_DATE,
               PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (V_GLOB_ENTITY_NUM),
               W_BAL,
               P_ASON_BC_BAL,
               PKG_ERR_MSG);
         END IF;

         IF W_BAL <= 0
         THEN
            GOTO NEXT_PBDCONTRACT;
         END IF;

         IF NOT STLMNT_AC_OK (L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM,
                              L_TABDEPCONT (I).PBDCONT_CONT_NUM,
                              W_PARTY_CR_AC)
         THEN
            GOTO NEXT_PBDCONTRACT;
         ELSE
            IF W_PARTY_CR_AC <> 0
            THEN
               IF PKG_ACNTS_VALID.SP_CHECK_ACNT_STATUS (V_GLOB_ENTITY_NUM,
                                                        W_PARTY_CR_AC,
                                                        'C') = TRUE
               THEN
                  W_PARTYAC_CR_APPL := 1;
                  W_STLMNT_AC := W_PARTY_CR_AC;
               ELSE
                  W_PARTYAC_CR_APPL := 0;
                  W_STLMNT_AC := 0;
               END IF;
            ELSE
               W_PARTYAC_CR_APPL := 0;
               W_STLMNT_AC := 0;
            END IF;
         END IF;

         V_PBDCONTDSA_STLMNT_CHOICE := 'A';

        <<ECSPARAM>>
         BEGIN
            IF V_PBDCONTDSA_STLMNT_CHOICE = 'E'
            THEN
               SELECT ECSFILEGENPARAM_CUT_OFF_DAY,
                      ECSFILEGENPARAM_ECS_CREDIT_GL
                 INTO V_ECSFILEGENPARAM_CUT_OFF_DAY,
                      V_ECSFILEGENPARAM_ECS_CR_GL
                 FROM ECSFILEGENPARAM
                WHERE     ECSFILEGENPARAM_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND ECSFILEGENPARAM_PAY_OPT = 'E';
            ELSIF V_PBDCONTDSA_STLMNT_CHOICE = 'P'
            THEN
               SELECT ECSFILEGENPARAM_CUT_OFF_DAY
                 INTO V_ECSFILEGENPARAM_CUT_OFF_DAY
                 FROM ECSFILEGENPARAM
                WHERE     ECSFILEGENPARAM_ENTITY_NUM = V_GLOB_ENTITY_NUM
                      AND ECSFILEGENPARAM_PAY_OPT = 'P';
            END IF;

            IF V_PBDCONTDSA_STLMNT_CHOICE <> 'A'
            THEN
               IF V_CUTOFF_FLAG = 0
               THEN
                  GOTO NEXT_PBDCONTRACT;
               ELSE
                  IF V_PBDCONTDSA_STLMNT_CHOICE = 'E'
                  THEN
                     IF W_ECS_ASON_DATE IS NOT NULL
                     THEN
                        W_AS_ON_DATE := W_ECS_ASON_DATE;
                     ELSE
                        GOTO NEXT_PBDCONTRACT;
                     END IF;
                  END IF;

                  IF V_PBDCONTDSA_STLMNT_CHOICE = 'P'
                  THEN
                     IF W_PO_ASON_DATE IS NOT NULL
                     THEN
                        W_AS_ON_DATE := W_PO_ASON_DATE;
                     ELSE
                        GOTO NEXT_PBDCONTRACT;
                     END IF;
                  END IF;

                  IF V_ECS_CTL_FLAG = 0
                  THEN
                     V_ECS_CTL_FLAG := 1;
                     V_ECSPO_ASON_DATE := W_AS_ON_DATE;
                  END IF;

                  IF V_PO_CTL_FLAG = 0
                  THEN
                     V_PO_CTL_FLAG := 1;
                     V_ECSPO_ASON_DATE := W_AS_ON_DATE;
                  END IF;
               END IF;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END ECSPARAM;

         IF L_TABDEPCONT (I).PBDCONT_INT_PAID_UPTO IS NULL
         THEN
            W_START_DATE := L_TABDEPCONT (I).PBDCONT_EFF_DATE;
         ELSE
            W_START_DATE := L_TABDEPCONT (I).PBDCONT_INT_PAID_UPTO + 1;
         END IF;

         IF W_START_DATE >= L_TABDEPCONT (I).PBDCONT_MAT_DATE
         THEN
            GOTO NEXT_PBDCONTRACT;
         END IF;

         IF L_TABDEPCONT (I).DEPPR_INT_CR_FREQ = 'M'
         THEN
            W_FREQ := 1;
         ELSIF L_TABDEPCONT (I).DEPPR_INT_CR_FREQ = 'Q'
         THEN
            W_FREQ := 3;
         ELSIF L_TABDEPCONT (I).DEPPR_INT_CR_FREQ = 'H'
         THEN
            W_FREQ := 6;
         ELSIF L_TABDEPCONT (I).DEPPR_INT_CR_FREQ = 'Y'
         THEN
            W_FREQ := 12;
         ELSIF L_TABDEPCONT (I).DEPPR_INT_CR_FREQ = 'A'
         THEN
            W_FREQ := TRUNC (MONTHS_BETWEEN (W_AS_ON_DATE, W_START_DATE));
         END IF;

         IF W_AS_ON_DATE >= L_TABDEPCONT (I).PBDCONT_MAT_DATE
         THEN
            W_END_DATE := L_TABDEPCONT (I).PBDCONT_MAT_DATE - 1;
            W_ACT_END_DATE := L_TABDEPCONT (I).PBDCONT_MAT_DATE;
         ELSE
            IF L_TABDEPCONT (I).DEPPR_INT_CR_FREQ <> 'A'
            THEN
               W_NOM := TRUNC (MONTHS_BETWEEN (W_AS_ON_DATE, W_START_DATE));
               --W_NOM := W_FREQ ;
               --W_FREQ := W_NOM ;

               IF W_NOM > W_FREQ
               THEN
                  W_NOOF_FREQ := TRUNC (W_NOM / W_FREQ);
                  W_END_DATE :=
                     FN_MONTH_ADD (W_START_DATE, W_FREQ * W_NOOF_FREQ) - 1;
                  W_ACT_END_DATE :=
                     FN_MONTH_ADD (W_START_DATE, W_FREQ * W_NOOF_FREQ);
               ELSE
                  --W_END_DATE := FN_MONTH_ADD (W_START_DATE, W_NOM) - 1;
                  --W_ACT_END_DATE := FN_MONTH_ADD (W_START_DATE, W_NOM);
                  IF L_TABDEPCONT (I).DEPPR_INT_PAY_FREQ <> 'X' THEN
                      V_FACTOR := TRUNC(MONTHS_BETWEEN (W_AS_ON_DATE , L_TABDEPCONT (I).PBDCONT_EFF_DATE) / W_FREQ );
                      W_END_DATE := FN_MONTH_ADD (L_TABDEPCONT (I).PBDCONT_EFF_DATE , V_FACTOR * W_FREQ ) - 1;
                      W_ACT_END_DATE := W_END_DATE + 1 ;
                  ELSE
                      W_END_DATE := GET_END_DATE(W_AS_ON_DATE, L_TABDEPCONT (I).DEPPR_INT_CR_FREQ) - 1;
                      W_ACT_END_DATE := W_END_DATE + 1 ;
                  END IF ;
               END IF;
            ELSE                           --In case of yearly anniversary - A
               IF W_FREQ >= 12
               THEN
                  W_NEW_UPTO_DATE := ADD_MONTHS (W_START_DATE, 12);
                  W_END_DATE := W_NEW_UPTO_DATE - 1;
                  W_ACT_END_DATE := W_NEW_UPTO_DATE;
               ELSE
                  IS_ELIGIBLE := 0;
               END IF;
            END IF;
         END IF;

         IF IS_ELIGIBLE = 0
         THEN
            GOTO NEXT_PBDCONTRACT;
         END IF;

         IF W_ACT_END_DATE > W_AS_ON_DATE
         THEN
            GOTO NEXT_PBDCONTRACT;
         END IF;

         IF GET_MQHY_MON(V_GLOB_ENTITY_NUM, W_AS_ON_DATE, L_TABDEPCONT (I).DEPPR_INT_CR_FREQ) <> '1'
            AND L_TABDEPCONT (I).DEPPR_INT_CR_FREQ IN ('M', 'Q', 'H', 'Y')
            AND L_TABDEPCONT (I).DEPPR_INT_PAY_FREQ = 'X' THEN
            GOTO NEXT_PBDCONTRACT;
         END IF ;

         IF L_PREV_BRN = 0
         THEN
            L_PREV_BRN := L_TABDEPCONT (I).PBDCONT_BRN_CODE;
            DEP_INT_PAY_COLL.DELETE;
            DEPINT_ACCR_GL_COLL.DELETE;
         ELSIF L_PREV_BRN <> L_TABDEPCONT (I).PBDCONT_BRN_CODE
         THEN
            IF DEP_INT_PAY_COLL.COUNT > 0
            THEN
               NULL;                                            --UPDATE_PARA;
            END IF;

            L_PREV_BRN := L_TABDEPCONT (I).PBDCONT_BRN_CODE;
            DEP_INT_PAY_COLL.DELETE;
            DEPINT_ACCR_GL_COLL.DELETE;
            INTCOLL_IDX := 0;
            ECS_IDX := 0;
         END IF;

         /*IF L_TABDEPCONT(I).DEPPR_TYPE_OF_DEP = '1' THEN
           W_COMPARE_DATE := W_END_DATE;
         ELSIF L_TABDEPCONT(I).DEPPR_TYPE_OF_DEP = '2' THEN
           W_COMPARE_DATE := W_ACT_END_DATE;
         END IF;  */

         IF NVL (L_TABDEPCONT (I).PBDCONT_INT_ACCR_UPTO, W_END_DATE - 1) <
               W_END_DATE
         THEN
            PKG_DEP_INT_ACCRUAL.START_DEP_ACCRUAL (
               V_GLOB_ENTITY_NUM,
               L_TABDEPCONT (I).PBDCONT_BRN_CODE,
               L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM,
               L_TABDEPCONT (I).PBDCONT_CONT_NUM,
               W_END_DATE);

            IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NOT NULL
            THEN
               PKG_ERR_MSG :=
                     'Error occured when calling Interest accrual posting for  '
                  || FACNO (V_GLOB_ENTITY_NUM,
                            L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM)
                  || '/'
                  || L_TABDEPCONT (I).PBDCONT_CONT_NUM;
               RAISE E_USER_EXCEP;
            END IF;
         END IF;

         IF NOT INT_PAYABLE (L_TABDEPCONT (I).PBDCONT_BRN_CODE,
                             L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM,
                             L_TABDEPCONT (I).PBDCONT_CONT_NUM,
                             W_ACT_END_DATE,
                             W_END_DATE,
                             L_TABDEPCONT (I).PBDCONT_COMPLETED_ROLLOVERS,
                             W_INT_BAL)
         THEN
            PKG_ERR_MSG :=
                  'Error in Calculating Interest payable amount for '
               || FACNO (V_GLOB_ENTITY_NUM,
                         L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM)
               || '-'
               || L_TABDEPCONT (I).PBDCONT_CONT_NUM;
            RAISE E_USER_EXCEP;
         END IF;

        <<GET_ACTUAL_INT>>
         BEGIN
            SELECT P.PBDCONT_AC_DEP_AMT,
                   P.PBDCONT_ACTUAL_INT_RATE,
                   D.DEPPR_INT_CALC_CHOICE,
                   D.DEPPR_INT_CALC_DENOM,
                   D.DEPPR_INT_PRD_CALC_CHOICE
              INTO V_ORG_AC_AMT,
                   V_ACT_INT_RATE,
                   V_CALC_CHOICE,
                   V_CALC_DENOM,
                   V_PRD_CHOICE
              FROM PBDCONTRACT P, DEPPROD D
             WHERE     P.PBDCONT_ENTITY_NUM = V_GLOB_ENTITY_NUM
                   AND P.PBDCONT_DEP_AC_NUM =
                          l_tabdepCont (i).PBDCONT_DEP_AC_NUM
                   AND P.PBDCONT_CONT_NUM = l_tabdepCont (i).PBDCONT_CONT_NUM
                   AND P.PBDCONT_BRN_CODE = l_tabdepCont (i).PBDCONT_BRN_CODE
                   AND P.PBDCONT_PROD_CODE = D.DEPPR_PROD_CODE;
         EXCEPTION
            WHEN OTHERS
            THEN
               PKG_ERR_MSG := SUBSTR (SQLERRM, 1, 500);
               RAISE E_USER_EXCEP;
         END GET_ACTUAL_INT;

         W_INT_RNDOFF_CHOICE := '';

        <<GET_CURR_PM>>
         BEGIN
            SELECT DR.DEPPRCUR_INT_RND_OFF_CHOICE,
                   DR.DEPPRCUR_INT_RND_OFF_FACTOR
              INTO W_INT_RNDOFF_CHOICE, W_INT_RNDOFF_FACTOR
              FROM DEPPRODCUR DR
             WHERE     DR.DEPPRCUR_PROD_CODE =
                          l_tabdepCont (i).DEPPR_PROD_CODE
                   AND DR.DEPPRCUR_CURR_CODE =
                          l_tabdepCont (i).PBDCONT_DEP_CURR
                   AND DR.DEPPRCUR_LATEST_EFF_DATE =
                          (SELECT MAX (DR.DEPPRCUR_LATEST_EFF_DATE)
                             FROM DEPPRODCUR DR
                            WHERE     DR.DEPPRCUR_PROD_CODE =
                                         l_tabdepCont (i).DEPPR_PROD_CODE
                                  AND DR.DEPPRCUR_CURR_CODE =
                                         l_tabdepCont (i).PBDCONT_DEP_CURR);
         EXCEPTION
            WHEN OTHERS
            THEN
               PKG_ERR_MSG := SUBSTR (SQLERRM, 1, 500);
               RAISE E_USER_EXCEP;
         END GET_CURR_PM;

         IF V_CALC_CHOICE = '' OR V_CALC_DENOM = '' OR V_CALC_DENOM = ''
         THEN
            PKG_ERR_MSG :=
                  'CALCULATION PARAMETERS NOT DEFINED FOR PROD CODE '
               || L_TABDEPCONT (I).DEPPR_PROD_CODE;
            RAISE E_USER_EXCEP;
         END IF;

         IF V_CALC_CHOICE = 'D'
         THEN
            V_NOD := W_END_DATE - W_START_DATE + 1;

            IF V_CALC_DENOM = '1'
            THEN
               V_DENOM := 36000;
            ELSIF V_CALC_DENOM = '2'
            THEN
               V_DENOM := 36500;
            ELSIF V_CALC_DENOM = '3'
            THEN
               V_DENOM := 36600;
            END IF;

            V_CALC_INT_AMT :=
               (V_ORG_AC_AMT * V_ACT_INT_RATE * V_NOD) / V_DENOM;
         ELSIF V_CALC_CHOICE = 'M'
         THEN
            V_MONTHS_BETN :=
               TRUNC (MONTHS_BETWEEN (W_ACT_END_DATE, W_START_DATE));
            V_NOD := V_MONTHS_BETN * 30;

            IF V_CALC_DENOM = '1'
            THEN
               V_DENOM := 36000;
            ELSIF V_CALC_DENOM = '2'
            THEN
               V_DENOM := 36500;
            ELSIF V_CALC_DENOM = '3'
            THEN
               V_DENOM := 36600;
            END IF;

            IF V_PRD_CHOICE = '1'
            THEN
               V_NOD := w_end_date - w_start_date + 1;
            ELSIF V_PRD_CHOICE = '2'
            THEN
               IF V_MONTHS_BETN <> 0
               THEN
                  V_NOD := V_MONTHS_BETN * 30;
               ELSE
                  V_NOD := w_end_date - w_start_date + 1;
               END IF;
            ELSIF V_PRD_CHOICE = '3'
            THEN
               V_NOD := w_end_date - w_start_date + 1;
            END IF;

            V_CALC_INT_AMT :=
               (V_ORG_AC_AMT * V_ACT_INT_RATE * V_NOD) / V_DENOM;
         END IF;

         IF     L_TABDEPCONT (I).PWGENPARAM_MES_APP <> '1'
            AND L_TABDEPCONT (I).DEPPR_TYPE_OF_DEP <> '2'
            AND W_INT_BAL > V_CALC_INT_AMT
         THEN
            W_INT_BAL := V_CALC_INT_AMT;
         END IF;

         IF W_INT_RNDOFF_CHOICE IS NOT NULL
         THEN
            W_INT_BAL :=
               FN_ROUNDOFF (V_GLOB_ENTITY_NUM,
                            W_INT_BAL,
                            W_INT_RNDOFF_CHOICE,
                            W_INT_RNDOFF_FACTOR);
         END IF;

         IF W_INT_BAL > 0
         THEN
            IF L_TABDEPCONT (I).PBDCONT_DEP_CURR <>
                  PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR (V_GLOB_ENTITY_NUM)
            THEN
               SP_GETCRATES (
                  V_GLOB_ENTITY_NUM,
                  L_TABDEPCONT (I).PBDCONT_DEP_CURR,
                  PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR (V_GLOB_ENTITY_NUM),
                  PKG_EODSOD_FLAGS.PV_CURRENT_DATE,
                  'TT',
                  'M',
                  L_ERR_CODE,
                  L_ERR_MSG,
                  PKG_CONV_RATE);

               IF TRIM (L_ERR_MSG) IS NOT NULL
               THEN
                  PKG_ERR_MSG :=
                        'Error occured while getting exchange rates For '
                     || FACNO (V_GLOB_ENTITY_NUM,
                               L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM)
                     || '/'
                     || L_TABDEPCONT (I).PBDCONT_CONT_NUM;
                  RAISE E_USER_EXCEP;
               END IF;

               GET_CONVERTED_VALUE (L_TABDEPCONT (I).PBDCONT_DEP_CURR,
                                    W_INT_BAL,
                                    PKG_CONV_RATE,
                                    W_INT_BAL_BC,
                                    P_CONV_ERR_CODE);
            ELSE
               W_INT_BAL_BC := W_INT_BAL;
            END IF;

           <<ADD_TO_INT_COLL>>
            BEGIN
               INTCOLL_IDX := INTCOLL_IDX + 1;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONT_BRN_CODE :=
                  L_TABDEPCONT (I).PBDCONT_BRN_CODE;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONT_DEP_AC_NUM :=
                  L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONT_CONT_NUM :=
                  L_TABDEPCONT (I).PBDCONT_CONT_NUM;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONT_AC_DEP_AMT :=
                  L_TABDEPCONT (I).PBDCONT_AC_DEP_AMT;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONT_DEP_CURR :=
                  L_TABDEPCONT (I).PBDCONT_DEP_CURR;
               DEP_INT_PAY_COLL (INTCOLL_IDX).AC_INT_PAY_AMT := W_INT_BAL;
               DEP_INT_PAY_COLL (INTCOLL_IDX).BC_INT_PAY_AMT := W_INT_BAL_BC;
               /*IF L_TABDEPCONT(I).DEPPR_TYPE_OF_DEP = '1' THEN --Corrected start date in case of IP
                     IF W_MAX_ACCR_FROM_DATE IS NOT NULL THEN
                        IF W_MAX_ACCR_FROM_DATE > W_START_DATE
                        THEN
                           W_START_DATE := W_MAX_ACCR_FROM_DATE;
                           W_MAX_ACCR_FROM_DATE := NULL;
                        END IF;
                     END IF;
                   END IF;*/
               DEP_INT_PAY_COLL (INTCOLL_IDX).INT_PAY_FROM_DATE :=
                  W_START_DATE;
               DEP_INT_PAY_COLL (INTCOLL_IDX).INT_PAY_UPTO_DATE := W_END_DATE;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONT_INT_CR_TO_ACNT :=
                  NVL (W_STLMNT_AC, 0);
               DEP_INT_PAY_COLL (INTCOLL_IDX).AC_PREV_INT_PAY_AMT :=
                  L_TABDEPCONT (I).PBDCONT_AC_INT_PAY_AMT;
               DEP_INT_PAY_COLL (INTCOLL_IDX).BC_PREV_INT_PAY_AMT :=
                  L_TABDEPCONT (I).PBDCONT_BC_INT_PAY_AMT;
               DEP_INT_PAY_COLL (INTCOLL_IDX).ACNTS_CLIENT_NUM :=
                  L_TABDEPCONT (I).ACNTS_CLIENT_NUM;
               DEP_INT_PAY_COLL (INTCOLL_IDX).ACNTS_NAME1 :=
                  L_TABDEPCONT (I).ACNTS_NAME1;
               DEP_INT_PAY_COLL (INTCOLL_IDX).ACNTS_NAME2 :=
                  L_TABDEPCONT (I).ACNTS_NAME2;
               DEP_INT_PAY_COLL (INTCOLL_IDX).DEPINTPAY_MODE_OF_PAY :=
                  V_PBDCONTDSA_STLMNT_CHOICE;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONTDSA_ECS_AC_BANK_CD :=
                  NULL;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONTDSA_ECS_AC_BRANCH_CD :=
                  NULL;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONTDSA_ON_AC_OF := NULL;
               DEP_INT_PAY_COLL (INTCOLL_IDX).PBDCONTDSA_REMIT_CODE := NULL;

               IF DEP_INT_PAY_COLL (INTCOLL_IDX).DEPINTPAY_MODE_OF_PAY = 'E'
               THEN
                  ECS_IDX := ECS_IDX + 1;
                  DEP_INT_PAY_COLL (INTCOLL_IDX).DEPINTPAY_ECS_PO_DTLS :=
                     V_PBDCONTDSA_ECS_CREDIT_AC_NUM;
                  ECS_INT_PAY_COLL (ECS_IDX).ENTITY_NUM := V_GLOB_ENTITY_NUM;
                  ECS_INT_PAY_COLL (ECS_IDX).CUT_OFF_DATE := W_AS_ON_DATE;
                  ECS_INT_PAY_COLL (ECS_IDX).BRN_CODE :=
                     L_TABDEPCONT (I).PBDCONT_BRN_CODE;
                  ECS_INT_PAY_COLL (ECS_IDX).DEP_AC_NUM :=
                     L_TABDEPCONT (I).PBDCONT_DEP_AC_NUM;
                  ECS_INT_PAY_COLL (ECS_IDX).CONTRACT_NUM :=
                     L_TABDEPCONT (I).PBDCONT_CONT_NUM;
               ELSIF DEP_INT_PAY_COLL (INTCOLL_IDX).DEPINTPAY_MODE_OF_PAY =
                        'P'
               THEN
                  DEP_INT_PAY_COLL (INTCOLL_IDX).DEPINTPAY_ECS_PO_DTLS := 0;
               END IF;

               DEP_INT_PAY_COLL (INTCOLL_IDX).PWGENPARAM_MES_APP :=
                  L_TABDEPCONT (I).PWGENPARAM_MES_APP;
               DEP_INT_PAY_COLL (INTCOLL_IDX).DEPPR_INT_PAY_FREQ :=
                  L_TABDEPCONT (I).DEPPR_INT_PAY_FREQ;
            END ADD_TO_INT_COLL;

           <<ADD_INT_ACCR_GL>>
            BEGIN
               IF NOT GET_DEP_PROD_CURR_ARRAY (
                         L_TABDEPCONT (I).PBDCONT_DEP_CURR,
                         L_TABDEPCONT (I).DEPPR_PROD_CODE,
                         W_DEP_INT_ACCR_GLACC)
               THEN
                  PKG_ERR_MSG :=
                     'Error in Getting Details from Deposit Product currency collection';
                  RAISE E_USER_EXCEP;
               END IF;

               W_DEP_INT_ACCR_GL_KEY :=
                     LPAD (L_TABDEPCONT (I).DEPPR_PROD_CODE, 4, 0)
                  || TRIM (L_TABDEPCONT (I).PBDCONT_DEP_CURR)
                  || TRIM (W_DEP_INT_ACCR_GLACC);

               IF DEPINT_ACCR_GL_COLL.EXISTS (W_DEP_INT_ACCR_GL_KEY)
               THEN
                  DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).AC_AMT :=
                       DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).AC_AMT
                     + W_INT_BAL;
                  DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).BC_AMT :=
                       DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).BC_AMT
                     + W_INT_BAL_BC;
               ELSE
                  DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).DEP_PROD_CODE :=
                     L_TABDEPCONT (I).DEPPR_PROD_CODE;
                  DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).DEP_CURR :=
                     TRIM (L_TABDEPCONT (I).PBDCONT_DEP_CURR);
                  DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).INT_ACCR_GL :=
                     TRIM (W_DEP_INT_ACCR_GLACC);
                  DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).AC_AMT :=
                     W_INT_BAL;
                  DEPINT_ACCR_GL_COLL (W_DEP_INT_ACCR_GL_KEY).BC_AMT :=
                     W_INT_BAL_BC;
               END IF;
            END ADD_INT_ACCR_GL;
         -------
         END IF;

        ---------------------------------------------------------------------------------
        <<NEXT_PBDCONTRACT>>
         NULL;
      END LOOP;

      ---------End iteration of account
      IF DEP_INT_PAY_COLL.COUNT > 0
      THEN
         UPDATE_PARA;
         DEP_INT_PAY_COLL.DELETE;
         DEPINT_ACCR_GL_COLL.DELETE;
      END IF;
   EXCEPTION
      WHEN E_USER_EXCEP
      THEN
         IF TRIM (PKG_ERR_MSG) IS NULL
         THEN
            PKG_ERR_MSG := 'user defined exception in interest payment';
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := PKG_ERR_MSG;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_GLOB_ENTITY_NUM, 'E', PKG_ERR_MSG);
      WHEN OTHERS
      THEN
         PKG_ERR_MSG :=
            'Error in start_depint_pay when others. Error: ' || SQLERRM;
         PKG_EODSOD_FLAGS.PV_ERROR_MSG := PKG_ERR_MSG;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_GLOB_ENTITY_NUM,
                                      'E',
                                      PKG_EODSOD_FLAGS.PV_ERROR_MSG);
   END START_DEPINT_PAY;


   PROCEDURE START_ACCR_BRNWISE (P_ENTITY_NUM   IN NUMBER,
                                 P_BRN_CODE     IN NUMBER DEFAULT 0)
   IS
      L_BRN_CODE   NUMBER (6);
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (P_ENTITY_NUM);
      PKG_ERR_MSG := '';
      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (P_ENTITY_NUM, P_BRN_CODE);

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

         IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (P_ENTITY_NUM,
                                                         L_BRN_CODE) = FALSE
         THEN
            START_DEPINT_PAY (P_ENTITY_NUM, NULL, L_BRN_CODE);

            IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
            THEN
               PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (P_ENTITY_NUM,
                                                                L_BRN_CODE);
            END IF;

            PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (P_ENTITY_NUM);
         END IF;
      END LOOP;

      IF V_ECS_CTL_FLAG = 1
      THEN
         INSERT
           INTO DEPECSPOINTPAYCTL (DEPECSPOINTPAYCTL_ENTITY_NUM,
                                   DEPECSPOINTPAYCTL_DATE,
                                   DEPECSPOINTPAYCTL_ECS)
         VALUES (V_GLOB_ENTITY_NUM, V_ECSPO_ASON_DATE, 'E');
      END IF;

      IF V_PO_CTL_FLAG = 1
      THEN
         INSERT
           INTO DEPECSPOINTPAYCTL (DEPECSPOINTPAYCTL_ENTITY_NUM,
                                   DEPECSPOINTPAYCTL_DATE,
                                   DEPECSPOINTPAYCTL_PO)
         VALUES (V_GLOB_ENTITY_NUM, V_ECSPO_ASON_DATE, 'P');
      END IF;
   END START_ACCR_BRNWISE;
BEGIN
   NULL;
END PKG_DEP_INT_APPLY;
/
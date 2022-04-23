CREATE OR REPLACE PACKAGE PKG_LNACCRUE_REV_PROC IS

  PROCEDURE PROC_BRN_WISE(P_ENTITY_NUM IN NUMBER,
                          P_BRN_CODE   IN NUMBER DEFAULT 0);

  PROCEDURE PROC_INT_CALC(V_ENTITY_NUM     IN NUMBER,
                          V_BRN_CODE       IN NUMBER DEFAULT 0,
                          V_ACCOUNT_NUMBER IN NUMBER DEFAULT 0,
                          V_AS_ON_DATE     IN DATE DEFAULT NULL,
                          V_USER_ID        IN VARCHAR2 DEFAULT NULL,
                          V_PROD_CODE      IN NUMBER DEFAULT 0,
                          V_PROCESS_TYPE   IN NUMBER DEFAULT 0); -- Value 3 Means Interest applicable to BL Loan

END PKG_LNACCRUE_REV_PROC;
/
CREATE OR REPLACE PACKAGE BODY PKG_LNACCRUE_REV_PROC
IS
   W_BRANCH_CODE             NUMBER;
   V_PROC_BRANCH             NUMBER;
   W_ENTITY_NUMBER           NUMBER;
   W_ERROR_MESSAGE           VARCHAR2 (1000);
   W_PROCESS_DATE            DATE;
   W_POST_ARRAY_INDEX        NUMBER;
   W_INTERNAL_ACNUM          NUMBER;
   W_PROD_CODE               NUMBER;
   W_RUN_NUMBER              NUMBER (6);
   W_CURRBUSS_DATE           DATE;
   W_FROM_DATE               DATE;
   W_MIG_DATE                DATE;
   W_MAX_LOANIA_VALUE_DATE   DATE;
   W_IS_REV_COPY             BOOLEAN;
   W_NPA_STATUS              CHAR (1);
   W_SQL                     CLOB;
   V_SQL                     VARCHAR2 (2000);
   E_USEREXCEP               EXCEPTION;
   W_PROCESS_TYPE            NUMBER;
   V_PROD_CODE               ACNTS.ACNTS_PROD_CODE%TYPE;
   V_NEXT_PROD               VARCHAR2 (1);
   V_FIRST_ACCOUNT           NUMBER;
   V_INCOME_GL               VARCHAR2(15);
   V_ACCRU_GL                VARCHAR2(15);




   TYPE TY_REV_DETAIL_REC IS RECORD
   (
      V_ASSETCLS_ENTITY_NUM            ASSETCLS.ASSETCLS_ENTITY_NUM%TYPE,
      V_ACNTS_BRN_CODE                 ACNTS.ACNTS_BRN_CODE%TYPE,
      V_ACNTS_PROD_CODE                ACNTS.ACNTS_PROD_CODE%TYPE,
      V_ACNTS_INTERNAL_ACNUM           ACNTS.ACNTS_INTERNAL_ACNUM%TYPE,
      V_ASSETCLS_LATEST_EFF_DATE       ASSETCLS.ASSETCLS_LATEST_EFF_DATE%TYPE,
      V_ASSETCLS_ASSET_CODE            ASSETCLS.ASSETCLS_ASSET_CODE%TYPE,
      V_ASSETCLS_NPA_DATE              ASSETCLS.ASSETCLS_NPA_DATE%TYPE,
      V_ACNTS_INT_CALC_UPTO            ACNTS.ACNTS_INT_CALC_UPTO%TYPE,
      V_LNACNT_INT_APPLIED_UPTO_DATE   LOANACNTS.LNACNT_INT_APPLIED_UPTO_DATE%TYPE,
      V_LNACNT_INT_ACCR_UPTO           LOANACNTS.LNACNT_INT_ACCR_UPTO%TYPE,
      V_ACNTS_OPENING_DATE             ACNTS.ACNTS_OPENING_DATE%TYPE,
      V_NPA_FLAG                       LOANIA.LOANIA_NPA_STATUS%TYPE,
      V_ASSETCD_NONPERF_CAT            ASSETCD.ASSETCD_NONPERF_CAT%TYPE,
      V_LNPRDAC_PROD_CODE              LNPRODACPM.LNPRDAC_PROD_CODE%TYPE,
      V_LNPRDAC_INT_INCOME_GL          LNPRODACPM.LNPRDAC_INT_INCOME_GL%TYPE,
      V_LNPRDAC_INT_SUSP_GL            LNPRODACPM.LNPRDAC_INT_SUSP_GL%TYPE,
      V_LNPRDAC_INT_ACCR_GL            LNPRODACPM.LNPRDAC_INT_ACCR_GL%TYPE,
      V_LNPRDAC_ACCRINT_SUSP_HEAD      LNPRODACPM.LNPRDAC_ACCRINT_SUSP_HEAD%TYPE,
      V_MAX_LOANIA_VALUE_DATE          LOANIA.LOANIA_VALUE_DATE%TYPE
   );


   TYPE TAB_REV_DETAIL_REC IS TABLE OF TY_REV_DETAIL_REC;

   REV_DETAIL_REC            TAB_REV_DETAIL_REC;



   TYPE TY_LOANIA_REC IS RECORD
   (
      LOANIA_ENTITY_NUM             LOANIA.LOANIA_ENTITY_NUM%TYPE,
      LOANIA_BRN_CODE               LOANIA.LOANIA_BRN_CODE%TYPE,
      LOANIA_ACNT_NUM               LOANIA.LOANIA_ACNT_NUM%TYPE,
      LOANIA_VALUE_DATE             LOANIA.LOANIA_VALUE_DATE%TYPE,
      LOANIA_ACCRUAL_DATE           LOANIA.LOANIA_ACCRUAL_DATE%TYPE,
      LOANIA_PREV_ACCR_DATE         LOANIA.LOANIA_PREV_ACCR_DATE%TYPE,
      LOANIA_ACNT_CURR              LOANIA.LOANIA_ACNT_CURR%TYPE,
      LOANIA_ACNT_BAL               LOANIA.LOANIA_ACNT_BAL%TYPE,
      LOANIA_TOTAL_NEW_INT_AMT      LOANIA.LOANIA_TOTAL_NEW_INT_AMT%TYPE,
      LOANIA_INT_ON_AMT             LOANIA.LOANIA_INT_ON_AMT%TYPE,
      LOANIA_OD_PORTION             LOANIA.LOANIA_OD_PORTION%TYPE,
      LOANIA_TOTAL_NEW_OD_INT_AMT   LOANIA.LOANIA_TOTAL_NEW_OD_INT_AMT%TYPE,
      LOANIA_INT_RATE               LOANIA.LOANIA_INT_RATE%TYPE,
      LOANIA_SLAB_AMT               LOANIA.LOANIA_SLAB_AMT%TYPE,
      LOANIA_OD_INT_RATE            LOANIA.LOANIA_OD_INT_RATE%TYPE,
      LOANIA_LIMIT                  LOANIA.LOANIA_LIMIT%TYPE,
      LOANIA_DP                     LOANIA.LOANIA_DP%TYPE,
      LOANIA_INT_AMT                LOANIA.LOANIA_INT_AMT%TYPE,
      LOANIA_INT_AMT_RND            LOANIA.LOANIA_INT_AMT_RND%TYPE,
      LOANIA_OD_INT_AMT             LOANIA.LOANIA_OD_INT_AMT%TYPE,
      LOANIA_OD_INT_AMT_RND         LOANIA.LOANIA_OD_INT_AMT_RND%TYPE,
      LOANIA_NPA_STATUS             LOANIA.LOANIA_NPA_STATUS%TYPE,
      LOANIA_NPA_AMT                LOANIA.LOANIA_NPA_AMT%TYPE,
      LOANIA_NPA_INT_POSTED_AMT     LOANIA.LOANIA_NPA_INT_POSTED_AMT%TYPE,
      LOANIA_ARR_INT_AMT            LOANIA.LOANIA_ARR_INT_AMT%TYPE
   );

   TYPE TAB_LOANIA_REC IS TABLE OF TY_LOANIA_REC;

   LOANIA_REC                TAB_LOANIA_REC;

   PROCEDURE GET_MIG_DETAILS
   IS
   BEGIN
      BEGIN
         SELECT M.MIG_END_DATE
           INTO W_MIG_DATE
           FROM MIG_DETAIL M
          WHERE M.BRANCH_CODE = V_PROC_BRANCH;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_MIG_DATE := NULL;
      END;
   END GET_MIG_DETAILS;

   PROCEDURE PROC_BRANCH (P_ENTITY_NUMBER    IN NUMBER,
                          P_BRANCH_CODE         NUMBER,
                          P_INTERNAL_ACNUM      NUMBER DEFAULT 0)
   IS
      W_TOT_INT_AMT           NUMBER (18, 3);
      W_TOT_INT_AMT_RND       NUMBER (18, 3);
      W_TOT_OD_INT_AMT_RND    NUMBER (18, 3);
      W_TOT_OD_INT_AMT        NUMBER (18, 3);
      W_NPA_INT_AMT_POSTED    NUMBER (18, 3);
      W_SUM_TOT_INT_AMT       NUMBER (18, 3);
      W_SUM_TOT_INT_AMT_RND   NUMBER (18, 3);
      W_LNSUSP_BAL            NUMBER (18, 3);
      W_LN_TOT_INT_AMT        NUMBER (18, 3);
      W_LNSUSP_BAL_SUM        NUMBER (18, 3) := 0;
      W_LN_TOT_INT_AMT_SUM    NUMBER (18, 3) := 0;
      V_BATCH_NUMBER          NUMBER;

      PROCEDURE GET_RUN_NUMBER
      IS
      BEGIN
         SELECT GENRUNNUM.NEXTVAL INTO W_RUN_NUMBER FROM DUAL;
      END GET_RUN_NUMBER;

      PROCEDURE DELETE_FROM_MIRROR (P_ACCOUNT_NUM NUMBER)
      IS
      BEGIN
         DELETE FROM LOANIAMRR L
               WHERE     L.LOANIAMRR_ENTITY_NUM = P_ENTITY_NUMBER
                     AND L.LOANIAMRR_BRN_CODE = P_BRANCH_CODE
                     AND L.LOANIAMRR_ACNT_NUM = P_ACCOUNT_NUM
                     AND L.LOANIAMRR_VALUE_DATE >= W_FROM_DATE;

         DELETE FROM LOANIAMRRDTL L
               WHERE     L.LOANIAMRRDTL_ENTITY_NUM = P_ENTITY_NUMBER
                     AND L.LOANIAMRRDTL_BRN_CODE = P_BRANCH_CODE
                     AND L.LOANIAMRRDTL_ACNT_NUM = P_ACCOUNT_NUM
                     AND L.LOANIAMRRDTL_VALUE_DATE >= W_FROM_DATE;
      END DELETE_FROM_MIRROR;

      PROCEDURE COPY_FROM_MIRROR (P_ENTITY_NUMBER    NUMBER,
                                  P_ACCOUNT_NUM      NUMBER,
                                  P_BRN_CODE         NUMBER,
                                  NPA_FLAG           CHAR)
      IS
      BEGIN
         INSERT INTO RTMPLNIA (RTMPLNIA_RUN_NUMBER,
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
                               RTMPLNIA_MAX_ACCRUAL_DATE)
            (SELECT W_RUN_NUMBER,
                    LOANIAMRR_ACNT_NUM,
                    LOANIAMRR_VALUE_DATE,
                    LOANIAMRR_ACCRUAL_DATE,
                    LOANIAMRR_ACNT_CURR,
                    LOANIAMRR_ACNT_BAL,
                    LOANIAMRR_INT_ON_AMT,
                    LOANIAMRR_OD_PORTION,
                    LOANIAMRR_INT_RATE,
                    LOANIAMRR_SLAB_AMT,
                    LOANIAMRR_OD_INT_RATE,
                    LOANIAMRR_LIMIT,
                    LOANIAMRR_DP,
                    LOANIAMRR_INT_AMT,
                    LOANIAMRR_INT_AMT_RND,
                    LOANIAMRR_OD_INT_AMT,
                    LOANIAMRR_OD_INT_AMT_RND,
                    W_NPA_STATUS,     --LOANIA_REC(M_INDEX).LOANIA_NPA_STATUS,
                    LOANIAMRR_NPA_AMT,
                    LOANIAMRR_ARR_INT_AMT,
                    (SELECT MAX (LOANIAMRR_VALUE_DATE)
                       FROM LOANIAMRR
                      WHERE     LOANIAMRR_ENTITY_NUM = P_ENTITY_NUMBER
                            AND LOANIAMRR_BRN_CODE = P_BRN_CODE
                            AND LOANIAMRR_ACNT_NUM = P_ACCOUNT_NUM)
               FROM LOANIAMRR L
              WHERE     L.LOANIAMRR_ENTITY_NUM = P_ENTITY_NUMBER
                    AND L.LOANIAMRR_ACNT_NUM = P_ACCOUNT_NUM
                    AND LOANIAMRR_BRN_CODE = P_BRN_CODE
                    AND L.LOANIAMRR_VALUE_DATE >= W_FROM_DATE);
                    
      --------- Data will be inserted from RTMPLNIA ---- Fahim
      /*
               INSERT INTO RTMPLNIADTL (RTMPLNIADTL_RUN_NUMBER,
                                        RTMPLNIADTL_ACNT_NUM,
                                        RTMPLNIADTL_VALUE_DATE,
                                        RTMPLNIADTL_ACCRUAL_DATE,
                                        RTMPLNIADTL_SL_NUM,
                                        RTMPLNIADTL_INT_RATE,
                                        RTMPLNIADTL_UPTO_AMT,
                                        RTMPLNIADTL_INT_AMT,
                                        RTMPLNIADTL_INT_AMT_RND)
                  (SELECT W_RUN_NUMBER,
                          LOANIAMRRDTL_ACNT_NUM,
                          LOANIAMRRDTL_VALUE_DATE,
                          LOANIAMRRDTL_ACCRUAL_DATE,
                          LOANIAMRRDTL_SL_NUM,
                          LOANIAMRRDTL_INT_RATE,
                          LOANIAMRRDTL_UPTO_AMT,
                          LOANIAMRRDTL_INT_AMT,
                          LOANIAMRRDTL_INT_AMT_RND
                     FROM LOANIAMRRDTL L
                    WHERE     L.LOANIAMRRDTL_ENTITY_NUM = P_ENTITY_NUMBER
                          AND L.LOANIAMRRDTL_ACNT_NUM = P_ACCOUNT_NUM
                          AND L.LOANIAMRRDTL_VALUE_DATE >= W_FROM_DATE
                          AND L.LOANIAMRRDTL_BRN_CODE = P_BRN_CODE);
                          */
      END COPY_FROM_MIRROR;

      ------------------------------- for voucher posting -----------------------------

      PROCEDURE SET_TRAN_KEY_VALUES (P_ACCOUNT_BRANCH   IN NUMBER,
                                     P_BUSINESS_DATE       DATE)
      IS
      BEGIN
         PKG_AUTOPOST.PV_SYSTEM_POSTED_TRANSACTION := TRUE;
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE := P_ACCOUNT_BRANCH;
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := P_BUSINESS_DATE;
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
         PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;
      END SET_TRAN_KEY_VALUES;

      PROCEDURE SET_TRANBAT_VALUES
      IS
      BEGIN
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'LOANIA';
         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY := W_PROCESS_DATE;

         PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1 := 'Loan Accrual Reversal';
      END SET_TRANBAT_VALUES;

      PROCEDURE MOVE_POST_ARRAY_VALUES (P_DB_CR_FLG     IN CHAR,
                                        P_CURR_CODE     IN VARCHAR2,
                                        P_TRAN_AMOUNT   IN NUMBER,
                                        P_AC_BRN_CODE   IN NUMBER,
                                        P_GL_CODE       IN VARCHAR2,
                                        P_PROD_CODE     IN NUMBER)
      IS
      BEGIN
         W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
         PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_DB_CR_FLG :=
            P_DB_CR_FLG;
         PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_CURR_CODE :=
            P_CURR_CODE;
         PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_AMOUNT :=
            P_TRAN_AMOUNT;
         PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_ACING_BRN_CODE :=
            P_AC_BRN_CODE;
         PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_GLACC_CODE :=
            P_GL_CODE;
         PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL1 :=
            'Loan Accrual Reversal ';
         PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL2 :=
            'Prod Code - ' || P_PROD_CODE;
         PKG_AUTOPOST.PV_TRAN_REC (W_POST_ARRAY_INDEX).TRAN_NARR_DTL3 :=
            'Curr Code - ' || P_CURR_CODE;
      END MOVE_POST_ARRAY_VALUES;

      PROCEDURE POST_TRANSACTION (P_ACCOUNT_BRANCH NUMBER)
      IS
         W_ERROR_CODE   VARCHAR2 (100);
         W_ERROR        VARCHAR2 (1000);
         W_BATCH_NUM    NUMBER;
      BEGIN
         PKG_APOST_INTERFACE.SP_POST_SODEOD_BATCH (W_ENTITY_NUMBER,
                                                   'A',
                                                   W_POST_ARRAY_INDEX,
                                                   0,
                                                   W_ERROR_CODE,
                                                   W_ERROR,
                                                   W_BATCH_NUM);
         PKG_AUTOPOST.PV_TRAN_REC.DELETE;

         IF (W_ERROR_CODE <> '0000')
         THEN
            W_ERROR_MESSAGE :=
               SUBSTR (
                     'Process Brn Code -  '
                  || W_ERROR_CODE
                  || ' '
                  || P_ACCOUNT_BRANCH
                  || ' '
                  || FN_GET_AUTOPOST_ERR_MSG (W_ENTITY_NUMBER),
                  1,
                  1000);
         END IF;
      END POST_TRANSACTION;

      PROCEDURE POST_BRN_WISE_TRANSACTION (P_ACCOUNT_BRANCH IN NUMBER)
      IS
      BEGIN
         SET_TRAN_KEY_VALUES (P_ACCOUNT_BRANCH, W_CURRBUSS_DATE);
         SET_TRANBAT_VALUES;

         IF W_POST_ARRAY_INDEX > 0
         THEN
            POST_TRANSACTION (P_ACCOUNT_BRANCH);
         END IF;

         PKG_APOST_INTERFACE.SP_POSTING_END (W_ENTITY_NUMBER);
         W_POST_ARRAY_INDEX := 0;
      END POST_BRN_WISE_TRANSACTION;



      PROCEDURE VOUCHER_PREPARATION (P_LN_TOT_INT_AMT_SUM   IN NUMBER,
                                     P_INCOME_GL               VARCHAR2,
                                     P_ACCR_GL                 VARCHAR2,
                                     P_PRODUCT_CODE            NUMBER)
      IS
      BEGIN
         IF P_LN_TOT_INT_AMT_SUM > 0
         THEN
            BEGIN
               ------------ MOVE TO DEBIT TRANSACTION
               MOVE_POST_ARRAY_VALUES (
                  P_DB_CR_FLG     => 'D',
                  P_CURR_CODE     => 'BDT',
                  P_TRAN_AMOUNT   => P_LN_TOT_INT_AMT_SUM,
                  P_AC_BRN_CODE   => P_BRANCH_CODE,
                  P_GL_CODE       => P_INCOME_GL,
                  P_PROD_CODE     => P_PRODUCT_CODE);
            END;

            BEGIN
               ------------ MOVE TO CREDIT TRANSACTION
               MOVE_POST_ARRAY_VALUES (
                  P_DB_CR_FLG     => 'C',
                  P_CURR_CODE     => 'BDT',
                  P_TRAN_AMOUNT   => P_LN_TOT_INT_AMT_SUM,
                  P_AC_BRN_CODE   => P_BRANCH_CODE,
                  P_GL_CODE       => P_ACCR_GL,
                  P_PROD_CODE     => P_PRODUCT_CODE);
            END;
         END IF;
      END VOUCHER_PREPARATION;

   ------------------------------- for voucher posting -----------------------------

   BEGIN
      ------------- START FROM HERE .... COLLECT CURRENT BL ACCOUNT LIST -----------------
      W_INTERNAL_ACNUM := P_INTERNAL_ACNUM;
      W_CURRBUSS_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      GET_MIG_DETAILS;
      --SP_LN_ACCOUNT_GL;
      GET_RUN_NUMBER;



      W_SQL :=
            'SELECT ASSETCLS_ENTITY_NUM,
       A.ACNTS_BRN_CODE,
       ACNTS_PROD_CODE,
       A.ACNTS_INTERNAL_ACNUM,
       ASSETCLS_LATEST_EFF_DATE,
       ASSETCLS_ASSET_CODE,
       ASSETCLS_NPA_DATE,
       ACNTS_INT_CALC_UPTO,
       LNACNT_INT_APPLIED_UPTO_DATE,
       L.LNACNT_INT_ACCR_UPTO,
       A.ACNTS_OPENING_DATE,
       DECODE (ASSETCD_ASSET_CLASS,  ''N'', ''1'',  ''P'', ''0'') NPA_FLAG,
       AC.ASSETCD_NONPERF_CAT,
       LNPRDAC_PROD_CODE,
       LNPRDAC_INT_INCOME_GL,
       LNPRDAC_INT_SUSP_GL,
       LNPRDAC_INT_ACCR_GL,
       LNPRDAC_ACCRINT_SUSP_HEAD,
       (SELECT MAX (LOANIA_VALUE_DATE)  
                    FROM LOANIA 
                   WHERE     LOANIA_ENTITY_NUM = '
         || W_ENTITY_NUMBER
         || '
                         AND LOANIA_BRN_CODE = A.ACNTS_BRN_CODE
                         AND LOANIA_ACNT_NUM = A.ACNTS_INTERNAL_ACNUM)
  FROM ASSETCLS ASS,
       ACNTS A,
       LOANACNTS L,
       ASSETCD AC,
       LNPRODACPM,
       LNPRODPM
 WHERE     A.ACNTS_INTERNAL_ACNUM = ASS.ASSETCLS_INTERNAL_ACNUM
       AND L.LNACNT_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
       AND A.ACNTS_ENTITY_NUM = '
         || W_ENTITY_NUMBER
         || '
         AND ASS.ASSETCLS_ENTITY_NUM = '
         || W_ENTITY_NUMBER
         || '
         AND L.LNACNT_ENTITY_NUM = '
         || W_ENTITY_NUMBER
         || '
         AND AC.ASSETCD_CODE = ASSETCLS_ASSET_CODE
         AND A.ACNTS_BRN_CODE = '
         || P_BRANCH_CODE
         || '
         AND LNPRDAC_PROD_CODE = LNPRD_PROD_CODE 
         ';

      IF W_INTERNAL_ACNUM > 0
      THEN
         W_SQL := W_SQL || ' AND LNPRDAC_PROD_CODE  =  ' || W_PROD_CODE;
      ELSIF GET_MQHY_MON (1, W_CURRBUSS_DATE, 'Y') = 1
      THEN
         W_SQL :=
               W_SQL
            || ' AND LNPRD_INT_APPL_FREQ  IN (''Y'',''H'',''Q'',''M'' )';
      ELSIF GET_MQHY_MON (1, W_CURRBUSS_DATE, 'H') = 1
      THEN
         W_SQL :=
            W_SQL || ' AND  LNPRD_INT_APPL_FREQ  IN (''H'',''Q'',''M'' )';
      ELSIF GET_MQHY_MON (1, W_CURRBUSS_DATE, 'Q') = 1
      THEN
         W_SQL := W_SQL || '  AND LNPRD_INT_APPL_FREQ  IN (''Q'',''M'' )';
      ELSIF GET_MQHY_MON (1, W_CURRBUSS_DATE, 'M') = 1
      THEN
         W_SQL := W_SQL || ' AND  LNPRD_INT_APPL_FREQ  IN (''M'' )';
      END IF;

      IF W_INTERNAL_ACNUM > 0
      THEN
         W_SQL :=
            W_SQL || 'AND L.LNACNT_INTERNAL_ACNUM = ' || W_INTERNAL_ACNUM;
      END IF;

      W_SQL :=
            W_SQL
         || '
         AND A.ACNTS_PROD_CODE = LNPRDAC_PROD_CODE
       AND ASSETCLS_ASSET_CODE NOT IN
              (SELECT ASSETCD_CODE
                 FROM ASSETCD
                WHERE     ASSETCD_ASSET_CLASS = ''N''
                      AND ASSETCD_NONPERF_CAT LIKE
                             (CASE
                                 WHEN (    '
         || W_INTERNAL_ACNUM
         || ' > 0
                                       AND '
         || W_PROCESS_TYPE
         || ' <> 3)
                                 THEN    -- W_PROCESS_TYPE is 3 for BL Closure
                                    3 -- Note: At Closure, BL Loan will not consider.
                                 WHEN '
         || W_INTERNAL_ACNUM
         || ' = 0
                                 THEN
                                    99
                              END))
       AND ACNTS_CLOSURE_DATE IS NULL
       ORDER BY A.ACNTS_PROD_CODE ';


      ---------- Query changed (Maximum data will be found from the query) -- Changed by Fahim
      --INSERT INTO TEMP_DATA VALUES (W_SQL);
      --COMMIT ;


      EXECUTE IMMEDIATE W_SQL BULK COLLECT INTO REV_DETAIL_REC;


      V_PROD_CODE := 0;
      V_NEXT_PROD := '0';
      V_FIRST_ACCOUNT := 1;


      FOR IND IN 1 .. REV_DETAIL_REC.COUNT
      LOOP
         IF V_PROD_CODE <> REV_DETAIL_REC (IND).V_ACNTS_PROD_CODE
         THEN
            V_PROD_CODE := REV_DETAIL_REC (IND).V_ACNTS_PROD_CODE;
            V_NEXT_PROD := '1';
         END IF;

         IF V_NEXT_PROD = '1'
         THEN
            IF V_FIRST_ACCOUNT = 0 AND W_LN_TOT_INT_AMT_SUM <> 0
            THEN
               VOUCHER_PREPARATION (
                  W_LN_TOT_INT_AMT_SUM,
                  REV_DETAIL_REC (IND - 1).V_LNPRDAC_INT_INCOME_GL,
                  REV_DETAIL_REC (IND - 1).V_LNPRDAC_INT_ACCR_GL,
                  REV_DETAIL_REC (IND - 1).V_LNPRDAC_PROD_CODE);
            END IF;

            V_FIRST_ACCOUNT := 0;
            W_LNSUSP_BAL_SUM := 0;
            W_LN_TOT_INT_AMT_SUM := 0;
         END IF;

         --V_PROD_CODE := REV_DETAIL_REC(IND).V_ACNTS_PROD_CODE ;


         ------------- LAST INTEREST ACCRU AMOUNT -----------------
         W_NPA_STATUS := REV_DETAIL_REC (IND).V_NPA_FLAG;

         -- Note: Start From Date depend on MIG_DATE, Last Accrual Date. If MIG_DATE and Last Accrual Date are Same
         -- then we need to consider migration dated amount. However, MIG_DATE and Last Acrual Date can be null for
         -- newly oppend account. So, openning date need to consider......
         -- Comditions are changed by Fahim

         IF W_MIG_DATE IS NOT NULL
         THEN
            IF (REV_DETAIL_REC (IND).V_LNACNT_INT_ACCR_UPTO IS NOT NULL)
            THEN
               IF (W_MIG_DATE = REV_DETAIL_REC (IND).V_LNACNT_INT_ACCR_UPTO)
               THEN
                  IF REV_DETAIL_REC (IND).V_MAX_LOANIA_VALUE_DATE <=
                        W_MIG_DATE
                  THEN
                     W_FROM_DATE := W_MIG_DATE + 1;
                  ELSIF REV_DETAIL_REC (IND).V_MAX_LOANIA_VALUE_DATE >=
                           W_MIG_DATE
                  THEN
                     W_FROM_DATE :=
                        REV_DETAIL_REC (IND).V_MAX_LOANIA_VALUE_DATE + 1;
                  ELSE
                     W_FROM_DATE := W_MIG_DATE;
                  END IF;
               ELSE
                  W_FROM_DATE :=
                     REV_DETAIL_REC (IND).V_LNACNT_INT_ACCR_UPTO + 1;
               END IF;
            ELSE
               W_FROM_DATE :=
                  GREATEST (W_MIG_DATE,
                            REV_DETAIL_REC (IND).V_ACNTS_OPENING_DATE);
            END IF;
         ELSE
            IF (REV_DETAIL_REC (IND).V_LNACNT_INT_ACCR_UPTO IS NOT NULL)
            THEN
               W_FROM_DATE := REV_DETAIL_REC (IND).V_LNACNT_INT_ACCR_UPTO + 1;
            ELSE
               W_FROM_DATE := REV_DETAIL_REC (IND).V_ACNTS_OPENING_DATE;
            END IF;
         END IF;

         IF     (REV_DETAIL_REC (IND).V_ASSETCD_NONPERF_CAT = '3')
            AND (W_FROM_DATE = W_MIG_DATE)
            AND (W_PROCESS_TYPE <> 3)
         THEN
            W_FROM_DATE := W_FROM_DATE + 1;
         END IF;


         BEGIN
            SELECT NVL (SUM (ABS (LOANIAMRR_INT_AMT)), 0),
                   NVL (SUM (ABS (LOANIAMRR_INT_AMT_RND)), 0),
                   NVL (SUM (ABS (LOANIAMRR_OD_INT_AMT_RND)), 0),
                   NVL (SUM (ABS (LOANIAMRR_OD_INT_AMT)), 0),
                   NVL (SUM (ABS (LOANIAMRR_NPA_INT_POSTED_AMT)), 0)
              INTO W_TOT_INT_AMT,
                   W_TOT_INT_AMT_RND,
                   W_TOT_OD_INT_AMT_RND,
                   W_TOT_OD_INT_AMT,
                   W_NPA_INT_AMT_POSTED
              FROM LOANIAMRR
             WHERE     LOANIAMRR_ENTITY_NUM = P_ENTITY_NUMBER
                   AND LOANIAMRR_ACNT_NUM =
                          REV_DETAIL_REC (IND).V_ACNTS_INTERNAL_ACNUM
                   AND LOANIAMRR_NPA_STATUS = 0
                   AND LOANIAMRR_VALUE_DATE >= W_FROM_DATE
                   AND LOANIAMRR_BRN_CODE = P_BRANCH_CODE;

            W_SUM_TOT_INT_AMT := W_TOT_INT_AMT_RND;

            W_SUM_TOT_INT_AMT_RND := W_TOT_INT_AMT_RND + W_TOT_OD_INT_AMT_RND;
         EXCEPTION
            WHEN OTHERS
            THEN
               W_ERROR_MESSAGE := 'ERROR IN FINDING ACCRUAL AMOUNT' || SQLERRM;
         END;

         IF W_SUM_TOT_INT_AMT > 0
         THEN
            W_LN_TOT_INT_AMT := W_SUM_TOT_INT_AMT;
            W_LN_TOT_INT_AMT_SUM := W_LN_TOT_INT_AMT_SUM + W_LN_TOT_INT_AMT;
         END IF;

         IF (    REV_DETAIL_REC (IND).V_ASSETCD_NONPERF_CAT = '3'
             AND W_PROCESS_TYPE <> 3)
         THEN
            DELETE_FROM_MIRROR (REV_DETAIL_REC (IND).V_ACNTS_INTERNAL_ACNUM);
         ELSE
            COPY_FROM_MIRROR (P_ENTITY_NUMBER,
                              REV_DETAIL_REC (IND).V_ACNTS_INTERNAL_ACNUM,
                              REV_DETAIL_REC (IND).V_ACNTS_BRN_CODE,
                              REV_DETAIL_REC (IND).V_NPA_FLAG);
         END IF;

         IF TRIM (W_ERROR_MESSAGE) IS NOT NULL
         THEN
            RAISE E_USEREXCEP;
         END IF;

         --

         -- Note: This Condition Added For work only One Account .. .. .
         IF (W_INTERNAL_ACNUM > 0)
         THEN
            EXIT;
         END IF;

         V_NEXT_PROD := '0';
         
         V_INCOME_GL  := REV_DETAIL_REC (IND).V_LNPRDAC_INT_INCOME_GL;
         V_ACCRU_GL := REV_DETAIL_REC (IND).V_LNPRDAC_INT_ACCR_GL ;
      END LOOP;
      
      VOUCHER_PREPARATION (
                  W_LN_TOT_INT_AMT_SUM,
                  V_INCOME_GL,
                  V_ACCRU_GL,
                  V_PROD_CODE);


      BEGIN
         POST_BRN_WISE_TRANSACTION (P_BRANCH_CODE);
      END;

      IF TRIM (W_ERROR_MESSAGE) IS NULL
      THEN
         PKG_EODSOD_FLAGS.PV_RUN_NUMBER := W_RUN_NUMBER;
         PKG_LOANDAILYACCRPOST_MRR.SP_LOANACCRPOST (W_ENTITY_NUMBER, 1); --Note: 1 Means CALL FROM CLOSURE / REVERSAL
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         PKG_AUTOPOST.PV_TRAN_REC.DELETE;
         REV_DETAIL_REC.DELETE;
         W_POST_ARRAY_INDEX := 0;
         W_ERROR_MESSAGE :=
            'Error in Processing of Branch ' || '' || P_BRANCH_CODE;
   END PROC_BRANCH;

   PROCEDURE PROC_INT_CALC (V_ENTITY_NUM       IN NUMBER,
                            V_BRN_CODE         IN NUMBER DEFAULT 0,
                            V_ACCOUNT_NUMBER   IN NUMBER DEFAULT 0,
                            V_AS_ON_DATE       IN DATE DEFAULT NULL,
                            V_USER_ID          IN VARCHAR2 DEFAULT NULL,
                            V_PROD_CODE        IN NUMBER DEFAULT 0,
                            V_PROCESS_TYPE     IN NUMBER DEFAULT 0)
   IS
   BEGIN
      W_POST_ARRAY_INDEX := 0;
      W_ENTITY_NUMBER := V_ENTITY_NUM;
      V_PROC_BRANCH := V_BRN_CODE;
      W_PROCESS_DATE := V_AS_ON_DATE;
      W_ERROR_MESSAGE := NULL;
      PKG_EODSOD_FLAGS.PV_PROCESS_NAME :=
         'PKG_LNACCRUE_REV_PROC.PROC_BRN_WISE';
      PKG_EODSOD_FLAGS.PV_USER_ID := V_USER_ID;
      PKG_EODSOD_FLAGS.PV_CALLED_BY_EOD_SOD := 1;
      PKG_EODSOD_FLAGS.PV_EODSODFLAG := 'E';
      PKG_EODSOD_FLAGS.PV_PREVIOUS_DATE := W_PROCESS_DATE - 1;
      PKG_EODSOD_FLAGS.PV_CURRENT_DATE := W_PROCESS_DATE;
      PKG_EODSOD_FLAGS.PV_ERROR_MSG := NULL;
      W_PROCESS_TYPE := V_PROCESS_TYPE;

      SELECT A.ACNTS_PROD_CODE
        INTO W_PROD_CODE
        FROM ACNTS A
       WHERE     A.ACNTS_ENTITY_NUM = V_ENTITY_NUM
             AND A.ACNTS_BRN_CODE = V_BRN_CODE
             AND A.ACNTS_INTERNAL_ACNUM = V_ACCOUNT_NUMBER;

      -- Note:
      PROC_BRANCH (V_ENTITY_NUM, V_BRN_CODE, V_ACCOUNT_NUMBER);

      -- Note: Create Batch For Copied LOANIA values

      IF TRIM (W_ERROR_MESSAGE) IS NOT NULL
      THEN
         RAISE E_USEREXCEP;
      END IF;
   -- Commit / Rollback is now Set Under One Transaction
   --PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS(W_ENTITY_NUMBER);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF PKG_EODSOD_FLAGS.PV_ERROR_MSG IS NULL
         THEN
            W_ERROR_MESSAGE :=
               SUBSTR (
                     'ERROR IN REVERSAL FOR A/C '
                  || facno (V_ENTITY_NUM, V_ACCOUNT_NUMBER)
                  || ' '
                  || SQLERRM,
                  1,
                  1000);
         ELSE
            W_ERROR_MESSAGE := PKG_EODSOD_FLAGS.PV_ERROR_MSG;
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR_MESSAGE;

         PKG_AUTOPOST.PV_TRAN_REC.DELETE;
         W_POST_ARRAY_INDEX := 0;
         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR_MESSAGE;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_NUMBER,
                                      'E',
                                      W_ERROR_MESSAGE,
                                      ' ',
                                      0);
   END PROC_INT_CALC;

   PROCEDURE PROC_BRN_WISE (P_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0)
   IS
   BEGIN
      W_ENTITY_NUMBER := P_ENTITY_NUM;
      W_BRANCH_CODE := P_BRN_CODE;
      W_PROCESS_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (W_ENTITY_NUMBER, W_BRANCH_CODE);

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         BEGIN
            V_PROC_BRANCH := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

            IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (W_ENTITY_NUMBER,
                                                            V_PROC_BRANCH) =
                  FALSE
            THEN
               W_ERROR_MESSAGE := NULL;
               W_POST_ARRAY_INDEX := 0;
               W_PROCESS_TYPE := 0;
               PROC_BRANCH (W_ENTITY_NUMBER, V_PROC_BRANCH, 0);

               IF TRIM (W_ERROR_MESSAGE) IS NOT NULL
               THEN
                  PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR_MESSAGE;
               END IF;

               IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
               THEN
                  PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (
                     W_ENTITY_NUMBER,
                     V_PROC_BRANCH);
               END IF;

               PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (
                  W_ENTITY_NUMBER);
            END IF;
         -- DBMS_OUTPUT.PUT_LINE('ERROR = ' || PKG_EODSOD_FLAGS.PV_ERROR_MSG);

         EXCEPTION
            WHEN OTHERS
            THEN
               IF PKG_EODSOD_FLAGS.PV_ERROR_MSG IS NULL
               THEN
                  W_ERROR_MESSAGE :=
                     SUBSTR (
                           'ERROR IN REVERSAL FOR BRANCH '
                        || ' '
                        || V_PROC_BRANCH
                        || SQLERRM,
                        1,
                        1000);
               ELSE
                  W_ERROR_MESSAGE := PKG_EODSOD_FLAGS.PV_ERROR_MSG;
               END IF;

               PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR_MESSAGE;
               PKG_AUTOPOST.PV_TRAN_REC.DELETE;
               W_POST_ARRAY_INDEX := 0;
               PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_NUMBER,
                                            'E',
                                            W_ERROR_MESSAGE,
                                            ' ',
                                            0);
               RAISE E_USEREXCEP;
         END;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF PKG_EODSOD_FLAGS.PV_ERROR_MSG IS NULL
         THEN
            W_ERROR_MESSAGE :=
               SUBSTR (
                     'ERROR IN REVERSAL FOR BRANCH '
                  || ' '
                  || V_PROC_BRANCH
                  || SQLERRM,
                  1,
                  1000);
         ELSE
            W_ERROR_MESSAGE :=
                  PKG_EODSOD_FLAGS.PV_ERROR_MSG
               || ' FOR BRANCH '
               || V_PROC_BRANCH;
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR_MESSAGE;
         PKG_AUTOPOST.PV_TRAN_REC.DELETE;
         W_POST_ARRAY_INDEX := 0;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_NUMBER,
                                      'E',
                                      W_ERROR_MESSAGE,
                                      ' ',
                                      0);
   END PROC_BRN_WISE;
END PKG_LNACCRUE_REV_PROC;
/

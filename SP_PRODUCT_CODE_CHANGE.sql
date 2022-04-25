CREATE OR REPLACE PROCEDURE SP_PRODUCT_CODE_CHANGE (
   P_BRANCH_CODE                 IN     NUMBER,
   P_ACCTUAL_ACCOUNT_NUMBER      IN     VARCHAR2,
   P_PREVIOUS_ACCOUNT_TYPE       IN     VARCHAR2,
   P_NEW_ACCOUNT_TYPE            IN     VARCHAR2,
   P_PREVIOUS_ACCOUNT_SUB_TYPE   IN     VARCHAR2,
   P_NEW_ACCOUNT_SUB_TYPE        IN     VARCHAR2,
   P_PREVIOUS_PRODUCT_CODE       IN     NUMBER,
   P_NEW_PRODUCT_CODE            IN     NUMBER,
   P_NARRATION                   IN     VARCHAR2,
   W_BATCH                          OUT NUMBER,
   W_PREVIOUS_ACCRUAL_BATCH         OUT NUMBER,
   W_NEW_ACCRUAL_BATCH              OUT NUMBER,
   W_ERR                            OUT VARCHAR2)
IS
   W_SQL                            VARCHAR2 (3000);
   W_BRANCH_CODE                    NUMBER (5) := P_BRANCH_CODE;
   W_ACCTUAL_ACCOUNT_NUMBER         VARCHAR2 (25) := P_ACCTUAL_ACCOUNT_NUMBER;
   W_PREVIOUS_ACCOUNT_TYPE          VARCHAR2 (5) := P_PREVIOUS_ACCOUNT_TYPE;
   W_NEW_ACCOUNT_TYPE               VARCHAR2 (5) := P_NEW_ACCOUNT_TYPE;
   W_PREVIOUS_ACCOUNT_SUB_TYPE      VARCHAR2 (5) := P_PREVIOUS_ACCOUNT_SUB_TYPE;
   W_NEW_ACCOUNT_SUB_TYPE           VARCHAR2 (5) := P_NEW_ACCOUNT_SUB_TYPE;
   W_PREVIOUS_PRODUCT_CODE          NUMBER (4) := P_PREVIOUS_PRODUCT_CODE;
   W_NEW_PRODUCT_CODE               NUMBER (4) := P_NEW_PRODUCT_CODE;
   W_NARRATION                      VARCHAR2 (200) := P_NARRATION;
   W_INTERNAL_ACCOUNT_NUMBER        NUMBER (14);
   W_SUBTYPE_REQURED                VARCHAR2 (1);
   W_ACSUB_ACTYPE_CODE              VARCHAR2 (5);
   W_ENTITY_NUMBER                  NUMBER (3) := GET_OTN.ENTITY_NUMBER;

   W_PREVIOUS_GL                    VARCHAR2 (15);
   W_NEW_GL                         VARCHAR2 (15);

   W_PREVIOUS_ACCRUAL_GL            VARCHAR2 (15);
   W_PREVIOUS_INCOME_GL             VARCHAR2 (15);

   W_NEW_ACCRUAL_GL                 VARCHAR2 (15);
   W_NEW_INCOME_GL                  VARCHAR2 (15);
   W_ACSEQ_NUMBER                   NUMBER (6);
   W_PRE_PROD_AC_NUMBER             NUMBER (20);
   W_NEW_PROD_AC_NUMBER             NUMBER (20);

   W_CURR_BAL                       NUMBER (18, 3);

   W_TOT_IA_FROM_LOANIA             NUMBER (18, 3);
   W_TOT_IA_FROM_LOANIAMRR          NUMBER (18, 3);
   W_LATEST_ACC_DATE_FROM_LOANIA    DATE;
   W_TOT_IA                         NUMBER (18, 3);
   W_COUNTER                        NUMBER;
   W_CBD                            DATE;
   W_PREVIOUS_PRODUCT_FOR_RUN_ACS   NUMBER;
   W_NEW_PRODUCT_FOR_RUN_ACS        NUMBER;
   V_COUNT_LNACRSDTL                NUMBER;
   V_COUNT_LNACDSDTL                NUMBER;
   V_LNACDSDTL_DISB_DATE            DATE;
   V_LNACDSDTL_DISB_AMOUNT          NUMBER (18, 3);
   V_LNACDSDTLH_EFF_DATE            DATE;
   V_LNACRSDTL_REPAY_AMT            NUMBER (18, 3);
   V_LNACRSDTL_REPAY_FROM_DATE      DATE;
   V_LNACRSDTL_NUM_OF_INSTALLMENT   NUMBER;
   V_LNACRS_SANC_REF_NUM            NUMBER;
   V_LNACRS_SANC_DATE               DATE;
   V_LNACRSDTL_REPAY_FREQ           VARCHAR2(1);
   V_LNACRS_REPH_ON_AMT             NUMBER(18,3);
   V_LNACRS_EQU_INSTALLMENT         NUMBER;
BEGIN
   IF W_PREVIOUS_ACCOUNT_SUB_TYPE IS NULL
   THEN
      W_PREVIOUS_ACCOUNT_SUB_TYPE := '0';
   END IF;

   IF W_NEW_ACCOUNT_SUB_TYPE IS NULL
   THEN
      W_NEW_ACCOUNT_SUB_TYPE := '0';
   END IF;

  <<ACCOUNT_VALIDATE>>
   BEGIN
      SELECT IACLINK_INTERNAL_ACNUM
        INTO W_INTERNAL_ACCOUNT_NUMBER
        FROM IACLINK
       WHERE     IACLINK_ENTITY_NUM = W_ENTITY_NUMBER
             AND IACLINK_ACTUAL_ACNUM = W_ACCTUAL_ACCOUNT_NUMBER
             AND IACLINK_BRN_CODE = W_BRANCH_CODE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         W_ERR :=
            'INVALID ACCOUNT NUMBER OR THIS ACCOUNT NUMBER IS NOT ASSIGNED IN THIS BRANCH';
         RETURN;
   END ACCOUNT_VALIDATE;


   ------------------- CONTINOUUS TO TERM LOAN VALIDATOR -------------------



   SELECT PRODUCT_FOR_RUN_ACS
     INTO W_PREVIOUS_PRODUCT_FOR_RUN_ACS
     FROM PRODUCTS P
    WHERE P.PRODUCT_CODE = W_PREVIOUS_PRODUCT_CODE
    AND P.PRODUCT_FOR_LOANS =1;

   SELECT PRODUCT_FOR_RUN_ACS
     INTO W_NEW_PRODUCT_FOR_RUN_ACS
     FROM PRODUCTS P
    WHERE P.PRODUCT_CODE = W_NEW_PRODUCT_CODE
    AND P.PRODUCT_FOR_LOANS =1;



   IF (W_PREVIOUS_PRODUCT_FOR_RUN_ACS = 1 AND W_NEW_PRODUCT_FOR_RUN_ACS = 0)
   THEN
      SELECT COUNT (*)
        INTO V_COUNT_LNACRSDTL
        FROM MIG_LNACRSDTL L
       WHERE L.LNACRSDTL_ACNUM = W_ACCTUAL_ACCOUNT_NUMBER;

      SELECT COUNT (*)
        INTO V_COUNT_LNACDSDTL
        FROM MIG_LNACDSDTL LL
       WHERE LL.LNACDSDTL_INTERNAL_ACNUM = W_ACCTUAL_ACCOUNT_NUMBER;

      IF V_COUNT_LNACRSDTL = 0
      THEN
         W_ERR := 'NO DATA FOUND FOR REPAYMENT DETAIL. Provide the repayment data in MIG_LNACRSDTL table ';
         RETURN;
      END IF;

      IF V_COUNT_LNACDSDTL = 0
      THEN
         W_ERR := 'NO DATA FOUND FOR DISBURSMENT DETAIL. Provide the disbursment data in MIG_LNACDSDTL table ';
         RETURN;
      END IF;



      ---LNACDSDTL---


      SELECT LNACDSDTL_DISB_DATE, LNACDSDTL_DISB_AMOUNT
        INTO V_LNACDSDTL_DISB_DATE, V_LNACDSDTL_DISB_AMOUNT
        FROM MIG_LNACDSDTL
       WHERE LNACDSDTL_INTERNAL_ACNUM = W_ACCTUAL_ACCOUNT_NUMBER;



      INSERT INTO LNACDSDTL (LNACDSDTL_ENTITY_NUM,
                             LNACDSDTL_INTERNAL_ACNUM,
                             LNACDSDTL_SL_NUM,
                             LNACDSDTL_STAGE_DESCN,
                             LNACDSDTL_DISB_CURR,
                             LNACDSDTL_DISB_DATE,
                             LNACDSDTL_DISB_AMOUNT)
           VALUES (W_ENTITY_NUMBER,
                   W_INTERNAL_ACCOUNT_NUMBER,
                   1,
                   'PRODUCT_CODE_CHANGE',
                   'BDT',
                   V_LNACDSDTL_DISB_DATE,
                   V_LNACDSDTL_DISB_AMOUNT);


      -- LNACDISB----



      INSERT INTO LNACDISB (LNACDISB_ENTITY_NUM,
                            LNACDISB_INTERNAL_ACNUM,
                            LNACDISB_DISB_SL_NUM,
                            LNACDISB_DISB_ON,
                            LNACDISB_STAGE_SERIAL,
                            LNACDISB_DISB_AMT_CURR,
                            LNACDISB_DISB_AMT,
                            LNACDISB_TRANSTL_INV_NUM,
                            LNACDISB_REMARKS1,
                            POST_TRAN_BRN,
                            POST_TRAN_DATE,
                            LNACDISB_ENTD_BY,
                            LNACDISB_ENTD_ON,
                            LNACDISB_AUTH_BY,
                            LNACDISB_AUTH_ON,
                            AMORT_DAY_SL,
                            LNACDISB_CASH_MARGIN_AMT,
                            LNACDISB_BORR_MARG_AMT,
                            LNACDISB_PRINCIPAL_AMT,
                            LNACDISB_INT_AMT)
           VALUES (W_ENTITY_NUMBER,
                   W_INTERNAL_ACCOUNT_NUMBER,
                   1,
                   V_LNACDSDTL_DISB_DATE,
                   1,
                   'BDT',
                   V_LNACDSDTL_DISB_AMOUNT,
                   0,
                   'PRODUCT CODE CHANGE',
                   2,
                   V_LNACDSDTL_DISB_DATE,
                   'MIG',
                   TRUNC (SYSDATE),
                   'MIG',
                   TRUNC (SYSDATE),
                   0,
                   0,
                   0,
                   0,
                   0);

      --- LNACDSDTLHIST

      SELECT ACNTS_OPENING_DATE
        INTO V_LNACDSDTLH_EFF_DATE
        FROM ACNTS
       WHERE ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER;

      INSERT INTO LNACDSDTLHIST (LNACDSDTLH_ENTITY_NUM,
                                 LNACDSDTLH_INTERNAL_ACNUM,
                                 LNACDSDTLH_EFF_DATE,
                                 LNACDSDTLH_SL_NUM,
                                 LNACDSDTLH_STAGE_DESCN,
                                 LNACDSDTLH_DISB_CURR,
                                 LNACDSDTLH_DISB_DATE,
                                 LNACDSDTLH_DISB_AMOUNT)
           VALUES (W_ENTITY_NUMBER,
                   W_INTERNAL_ACCOUNT_NUMBER,
                   V_LNACDSDTLH_EFF_DATE,
                   1,
                   'PRODUCT CODE CHANGE',
                   'BDT',
                   V_LNACDSDTL_DISB_DATE,
                   V_LNACDSDTL_DISB_AMOUNT);


      ----LLACNTOS--------

      UPDATE LLACNTOS LL
         SET LL.LLACNTOS_LIMIT_CURR_DISB_MADE = (-1)* ABS(V_LNACDSDTL_DISB_AMOUNT)
       WHERE     LL.LLACNTOS_CLIENT_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
             AND LL.LLACNTOS_ENTITY_NUM = W_ENTITY_NUMBER;

      ------ LNACRSDTL-----

      SELECT LNACRSDTL_REPAY_AMT,
             LNACRSDTL_REPAY_FROM_DATE,
             LNACRSDTL_NUM_OF_INSTALLMENT,
             LNACRS_SANC_REF_NUM,
             LNACRS_SANC_DATE   ,
             LNACRSDTL_REPAY_FREQ  ,
             LNACRS_REPH_ON_AMT,
             LNACRS_EQU_INSTALLMENT
        INTO V_LNACRSDTL_REPAY_AMT,
             V_LNACRSDTL_REPAY_FROM_DATE,
             V_LNACRSDTL_NUM_OF_INSTALLMENT,
             V_LNACRS_SANC_REF_NUM,
             V_LNACRS_SANC_DATE,
             V_LNACRSDTL_REPAY_FREQ,
             V_LNACRS_REPH_ON_AMT,
             V_LNACRS_EQU_INSTALLMENT
        FROM MIG_LNACRSDTL
       WHERE LNACRSDTL_ACNUM = W_ACCTUAL_ACCOUNT_NUMBER;

      INSERT INTO LNACRSDTL (LNACRSDTL_ENTITY_NUM,
                             LNACRSDTL_INTERNAL_ACNUM,
                             LNACRSDTL_SL_NUM,
                             LNACRSDTL_REPAY_AMT_CURR,
                             LNACRSDTL_REPAY_AMT,
                             LNACRSDTL_REPAY_FREQ,
                             LNACRSDTL_REPAY_FROM_DATE,
                             LNACRSDTL_NUM_OF_INSTALLMENT,
                             LNACRSDTL_TOT_REPAY_AMT)
           VALUES (W_ENTITY_NUMBER,
                   W_INTERNAL_ACCOUNT_NUMBER,
                   1,
                   'BDT',
                   V_LNACRSDTL_REPAY_AMT,
                   V_LNACRSDTL_REPAY_FREQ,
                   V_LNACRSDTL_REPAY_FROM_DATE,
                   V_LNACRSDTL_NUM_OF_INSTALLMENT,
                   V_LNACRS_REPH_ON_AMT);

      --- LNACRSHIST----



      INSERT INTO LNACRSHIST (LNACRSH_ENTITY_NUM,
                              LNACRSH_INTERNAL_ACNUM,
                              LNACRSH_EFF_DATE,
                              LNACRSH_EQU_INSTALLMENT,
                              LNACRSH_REPH_ON_AMT,
                              LNACRSH_SANC_BY,
                              LNACRSH_SANC_REF_NUM,
                              LNACRSH_SANC_DATE,
                              LNACRSH_CLIENT_REF_DATE,
                              LNACRSH_REMARKS1,
                              LNACRSH_ENTD_BY,
                              LNACRSH_ENTD_ON,
                              LNACRSH_AUTH_BY,
                              LNACRSH_AUTH_ON,
                              LNACRSH_RS_NO,
                              LNACRSH_PRINCIPAL_BAL,
                              LNACRSH_INTEREST_BAL,
                              LNACRSH_CHARGE_BAL)
           VALUES (W_ENTITY_NUMBER,
                   W_INTERNAL_ACCOUNT_NUMBER,
                   V_LNACDSDTLH_EFF_DATE,
                   V_LNACRS_EQU_INSTALLMENT,--- FLAG
                   V_LNACRS_REPH_ON_AMT,
                   '01',
                   V_LNACRS_SANC_REF_NUM,
                   V_LNACRS_SANC_DATE,
                   NULL,
                   'PRODUCT CODE CHANGE',
                   'MIG',
                   TRUNC (SYSDATE),
                   'MIG',
                   TRUNC (SYSDATE),
                   0,
                   0,
                   0,
                   0);

      --------LNACRS ---------

      INSERT INTO LNACRS (LNACRS_ENTITY_NUM,
                          LNACRS_INTERNAL_ACNUM,
                          LNACRS_LATEST_EFF_DATE,
                          LNACRS_EQU_INSTALLMENT,
                          LNACRS_REPH_ON_AMT,
                          LNACRS_SANC_BY,
                          LNACRS_SANC_REF_NUM,
                          LNACRS_SANC_DATE,
                          LNACRS_REMARKS1,
                          LNACRS_RS_NO,
                          LNACRS_PRINCIPAL_BAL,
                          LNACRS_INTEREST_BAL,
                          LNACRS_CHARGE_BAL)
           VALUES (W_ENTITY_NUMBER,
                   W_INTERNAL_ACCOUNT_NUMBER,
                   V_LNACDSDTLH_EFF_DATE,
                   V_LNACRS_EQU_INSTALLMENT,--- FLAG
                   V_LNACRSDTL_REPAY_AMT,
                   '01',
                   V_LNACRS_SANC_REF_NUM,
                   V_LNACRS_SANC_DATE,
                   'PRODUCT CODE CHANGE',
                   0,
                   0,
                   0,
                   0);


      -- LNACRSHDTL-----

      INSERT INTO LNACRSHDTL (LNACRSHDTL_ENTITY_NUM,
                              LNACRSHDTL_INTERNAL_ACNUM,
                              LNACRSHDTL_EFF_DATE,
                              LNACRSHDTL_SL_NUM,
                              LNACRSHDTL_REPAY_AMT_CURR,
                              LNACRSHDTL_REPAY_AMT,
                              LNACRSHDTL_REPAY_FREQ,
                              LNACRSHDTL_REPAY_FROM_DATE,
                              LNACRSHDTL_NUM_OF_INSTALLMENT,
                              LNACRSHDTL_TOT_REPAY_AMT)
           VALUES (W_ENTITY_NUMBER,
                   W_INTERNAL_ACCOUNT_NUMBER,
                   V_LNACDSDTLH_EFF_DATE,
                   1,
                   'BDT',
                   V_LNACRSDTL_REPAY_AMT,
                   V_LNACRSDTL_REPAY_FREQ,
                   V_LNACRSDTL_REPAY_FROM_DATE,
                   V_LNACRSDTL_NUM_OF_INSTALLMENT,
                   V_LNACRS_REPH_ON_AMT);
   END IF;



  ------------------- CONTINOUUS TO TERM LOAN VALIDATOR ------------------- END



  <<ACCOUNT_TYPE_VALIDATE>>
   BEGIN
      SELECT ACNTS_INTERNAL_ACNUM
        INTO W_INTERNAL_ACCOUNT_NUMBER
        FROM ACNTS A
       WHERE     ACNTS_ENTITY_NUM = W_ENTITY_NUMBER
             AND ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
             AND ACNTS_AC_TYPE = W_PREVIOUS_ACCOUNT_TYPE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         W_ERR := 'THE ACCOUNT TYPE IS NOT ASSIGNED IN THIS ACCOUNT';
         RETURN;
   END ACCOUNT_TYPE_VALIDATE;

  <<ACCOUNT_SUBTYPE_VALIDATE>>
   BEGIN
      SELECT ACNTS_INTERNAL_ACNUM
        INTO W_INTERNAL_ACCOUNT_NUMBER
        FROM ACNTS A
       WHERE     ACNTS_ENTITY_NUM = W_ENTITY_NUMBER
             AND ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
             AND ACNTS_AC_SUB_TYPE = W_PREVIOUS_ACCOUNT_SUB_TYPE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         W_ERR := 'THE ACCOUNT SUB TYPE IS NOT ASSIGNED IN THIS ACCOUNT';

         RETURN;
   END ACCOUNT_SUBTYPE_VALIDATE;

  <<ACCOUNT_PRODUCT_VALIDATE>>
   BEGIN
      SELECT ACNTS_INTERNAL_ACNUM
        INTO W_INTERNAL_ACCOUNT_NUMBER
        FROM ACNTS A
       WHERE     ACNTS_ENTITY_NUM = W_ENTITY_NUMBER
             AND ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
             AND ACNTS_PROD_CODE = W_PREVIOUS_PRODUCT_CODE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         W_ERR := 'THE PRODUCT CODE IS NOT ASSIGNED IN THIS ACCOUNT';

         RETURN;
   END ACCOUNT_PRODUCT_VALIDATE;

  <<NEW_ACCOUNT_INFO_VALIDATE>>
   BEGIN
      SELECT ACTYPE_SUB_TYPE_REQD
        INTO W_SUBTYPE_REQURED
        FROM ACTYPES A
       WHERE     ACTYPE_CODE = W_NEW_ACCOUNT_TYPE
             AND ACTYPE_PROD_CODE = W_NEW_PRODUCT_CODE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         W_ERR := 'THE PRODUCT CODE IS NOT ASSIGNED IN THIS ACCOUNT TYPE';
         RETURN;
   END NEW_ACCOUNT_INFO_VALIDATE;

   IF W_SUBTYPE_REQURED = '1' AND W_NEW_ACCOUNT_SUB_TYPE = '0'
   THEN
      W_ERR := 'SUBTYPE IS REQUIRED. BUT IT CAN NOT BE EMPTY OR ZERO';
      RETURN;
   END IF;

   IF W_SUBTYPE_REQURED <> '0'
   THEN
     <<NEW_ACSUBTYPE_VALIDATE>>
      BEGIN
         SELECT ACSUB_ACTYPE_CODE
           INTO W_NEW_ACCOUNT_TYPE
           FROM ACSUBTYPES A
          WHERE     ACSUB_ACTYPE_CODE = W_NEW_ACCOUNT_TYPE
                AND ACSUB_SUBTYPE_CODE = W_NEW_ACCOUNT_SUB_TYPE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_ERR :=
               'THE ACCOUNT SUBTYPE IS NOT ASSIGNED IN THIS ACCOUNT TYPE';

            RETURN;
      END NEW_ACSUBTYPE_VALIDATE;
   END IF;

  <<NEW_ACTYPE_SUBTYPE_VALIDATION>>
   BEGIN
      IF W_NEW_ACCOUNT_SUB_TYPE <> '0'
      THEN
         SELECT ACSUB_ACTYPE_CODE
           INTO W_ACSUB_ACTYPE_CODE
           FROM ACSUBTYPES
          WHERE     ACSUB_ACTYPE_CODE = W_NEW_ACCOUNT_TYPE
                AND ACSUB_SUBTYPE_CODE = W_NEW_ACCOUNT_SUB_TYPE;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         W_ERR :=
            'THE NEW ACCOUNT SUBTYPE IS NOT ASSIGNED IN THIS ACCOUNT TYPE';

         RETURN;
   END NEW_ACTYPE_SUBTYPE_VALIDATION;

   SELECT PRODUCT_GLACC_CODE
     INTO W_PREVIOUS_GL
     FROM PRODUCTS
    WHERE PRODUCT_CODE = W_PREVIOUS_PRODUCT_CODE;

   SELECT PRODUCT_GLACC_CODE
     INTO W_NEW_GL
     FROM PRODUCTS
    WHERE PRODUCT_CODE = W_NEW_PRODUCT_CODE;


  <<LOAN_AC_DETAIL_INFO>>
   BEGIN
      BEGIN
         SELECT LNPRDAC_INT_ACCR_GL, LNPRDAC_INT_INCOME_GL
           INTO W_PREVIOUS_ACCRUAL_GL, W_PREVIOUS_INCOME_GL
           FROM LNPRODACPM
          WHERE LNPRDAC_PROD_CODE = W_PREVIOUS_PRODUCT_CODE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_PREVIOUS_ACCRUAL_GL := 0;
            W_PREVIOUS_INCOME_GL := 0;
      END;

      BEGIN
         SELECT LNPRDAC_INT_ACCR_GL, LNPRDAC_INT_INCOME_GL
           INTO W_NEW_ACCRUAL_GL, W_NEW_INCOME_GL
           FROM LNPRODACPM
          WHERE LNPRDAC_PROD_CODE = W_NEW_PRODUCT_CODE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_NEW_ACCRUAL_GL := 0;
            W_NEW_INCOME_GL := 0;
      END;
   END LOAN_AC_DETAIL_INFO;

  -------------------- ACNTLINK ---------------------

  <<UPDATE_ACNTLINK>>
   BEGIN
      UPDATE ACNTLINK
         SET ACNTLINK_AC_SEQ_NUM =
                   LPAD (W_NEW_PRODUCT_CODE, 4, 0)
                || SUBSTR (ACNTLINK_AC_SEQ_NUM, -2, 2),
             ACNTLINK_ACCOUNT_NUMBER =
                   SUBSTR (ACNTLINK_ACCOUNT_NUMBER, 1, 17)
                || LPAD (W_NEW_PRODUCT_CODE, 4, 0)
                || SUBSTR (ACNTLINK_ACCOUNT_NUMBER, -2, 2)
       WHERE     ACNTLINK_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
             AND ACNTLINK_ENTITY_NUM = W_ENTITY_NUMBER;
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         UPDATE ACNTLINK
            SET ACNTLINK_AC_SEQ_NUM =
                        LPAD (W_NEW_PRODUCT_CODE, 4, 0)
                     || SUBSTR (ACNTLINK_AC_SEQ_NUM, -2, 1)
                     || SUBSTR (ACNTLINK_AC_SEQ_NUM, -1, 1)
                   + 1,
                ACNTLINK_ACCOUNT_NUMBER =
                      SUBSTR (ACNTLINK_ACCOUNT_NUMBER, 1, 17)
                   || LPAD (W_NEW_PRODUCT_CODE, 4, 0)
                   || SUBSTR (ACNTLINK_ACCOUNT_NUMBER, -2, 2)
          WHERE     ACNTLINK_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
                AND ACNTLINK_ENTITY_NUM = W_ENTITY_NUMBER;
   END UPDATE_ACNTLINK;

   SELECT ACNTLINK_AC_SEQ_NUM
     INTO W_ACSEQ_NUMBER
     FROM ACNTLINK
    WHERE     ACNTLINK_ENTITY_NUM = 1
          AND ACNTLINK_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER;

   ------------------ IACLINK -----------------------------

   UPDATE IACLINK
      SET IACLINK_ACCOUNT_NUMBER =
                SUBSTR (IACLINK_ACCOUNT_NUMBER, 1, 17)
             || LPAD (W_NEW_PRODUCT_CODE, 4, 0)
             || SUBSTR (IACLINK_ACCOUNT_NUMBER, -2, 2),
          IACLINK_PROD_CODE = W_NEW_PRODUCT_CODE,
          IACLINK_AC_SEQ_NUM = W_ACSEQ_NUMBER
    WHERE     IACLINK_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
          AND IACLINK_ENTITY_NUM = W_ENTITY_NUMBER;

   UPDATE ACNTS
      SET ACNTS_ACCOUNT_NUMBER =
                SUBSTR (ACNTS_ACCOUNT_NUMBER, 1, 17)
             || LPAD (W_NEW_PRODUCT_CODE, 4, 0)
             || SUBSTR (ACNTS_ACCOUNT_NUMBER, -2, 2),
          ACNTS_PROD_CODE = W_NEW_PRODUCT_CODE,
          ACNTS_AC_TYPE = W_NEW_ACCOUNT_TYPE,
          ACNTS_AC_SUB_TYPE = W_NEW_ACCOUNT_SUB_TYPE,
          ACNTS_GLACC_CODE = W_NEW_GL,
          ACNTS_AC_SEQ_NUM = W_ACSEQ_NUMBER
    WHERE     ACNTS_ENTITY_NUM = W_ENTITY_NUMBER
          AND ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER;



   UPDATE LIMITLINE
      SET LMTLINE_PROD_CODE = W_NEW_PRODUCT_CODE
    WHERE (LMTLINE_ENTITY_NUM, LMTLINE_CLIENT_CODE, LMTLINE_NUM) IN
             (SELECT ACASLLDTL_ENTITY_NUM,
                     ACASLLDTL_CLIENT_NUM,
                     ACASLLDTL_LIMIT_LINE_NUM
                FROM ACASLLDTL
               WHERE     ACASLLDTL_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
                     AND ACASLLDTL_ENTITY_NUM = W_ENTITY_NUMBER);



  <<ACSEQGEN_UPDATE>>
   BEGIN
      UPDATE ACSEQGEN
         SET ACSEQGEN_LAST_NUM_USED = ACSEQGEN_LAST_NUM_USED
       WHERE     ACSEQGEN_BRN_CODE = W_BRANCH_CODE
             AND ACSEQGEN_PROD_CODE = W_PREVIOUS_PRODUCT_CODE;

      SELECT COUNT (*)
        INTO W_COUNTER
        FROM ACSEQGEN
       WHERE     ACSEQGEN_BRN_CODE = W_BRANCH_CODE
             AND ACSEQGEN_PROD_CODE = W_NEW_PRODUCT_CODE;

      IF W_COUNTER > 0
      THEN
         UPDATE ACSEQGEN
            SET ACSEQGEN_LAST_NUM_USED = ACSEQGEN_LAST_NUM_USED + 1
          WHERE     ACSEQGEN_BRN_CODE = W_BRANCH_CODE
                AND ACSEQGEN_PROD_CODE = W_NEW_PRODUCT_CODE;
      ELSE
         INSERT INTO ACSEQGEN (ACSEQGEN_ENTITY_NUM,
                               ACSEQGEN_BRN_CODE,
                               ACSEQGEN_CIF_NUMBER,
                               ACSEQGEN_PROD_CODE,
                               ACSEQGEN_SEQ_NUMBER,
                               ACSEQGEN_LAST_NUM_USED)
              VALUES (W_ENTITY_NUMBER,
                      W_BRANCH_CODE,
                      0,
                      W_NEW_PRODUCT_CODE,
                      0,
                      1);
      END IF;
   END ACSEQGEN_UPDATE;

   SELECT ACNTBAL_BC_BAL
     INTO W_CURR_BAL
     FROM ACNTBAL
    WHERE     ACNTBAL_ENTITY_NUM = W_ENTITY_NUMBER
          AND ACNTBAL_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER;

   IF W_NEW_GL <> W_PREVIOUS_GL
   THEN
   
      --SP_GLMAST_UPDATE_TO_0 (W_NEW_GL, W_PREVIOUS_GL);
      
      
   UPDATE GLMAST
      SET GL_CUST_AC_ALLOWED = 0
    WHERE GL_NUMBER IN (SELECT EXTGL_GL_HEAD
                          FROM EXTGL
                         WHERE EXTGL_ACCESS_CODE = W_NEW_GL
                        UNION ALL
                        SELECT EXTGL_GL_HEAD
                          FROM EXTGL
                         WHERE EXTGL_ACCESS_CODE = W_PREVIOUS_GL) ;

      IF W_CURR_BAL < 0
      THEN
         DECLARE
            V_BATCH_NUMBER   NUMBER;
         BEGIN
            SP_AUTOPOST_TRANSACTION_MANUAL (
               W_BRANCH_CODE,                                   -- branch code
               W_NEW_GL,                                           -- debit gl
               W_PREVIOUS_GL,                                     -- credit gl
               ABS (W_CURR_BAL),                               -- debit amount
               ABS (W_CURR_BAL),                              -- credit amount
               0,                                             -- debit account
               0,                                        -- DR contract number
               0,                                        -- CR contract number
               0,                                            -- credit account
               0,                                          -- advice num debit
               NULL,                                      -- advice date debit
               0,                                         -- advice num credit
               NULL,                                     -- advice date credit
               'BDT',                                              -- currency
               '127.0.0.1',                                     -- terminal id
               'INTELECT',                                             -- user
                  'PRODUCT CODE CHANGE...  '
               || W_NARRATION
               || W_ACCTUAL_ACCOUNT_NUMBER,                       -- narration
               V_BATCH_NUMBER                                  -- BATCH NUMBER
                             );
            W_BATCH := V_BATCH_NUMBER;
         END;
      ELSIF W_CURR_BAL > 0
      THEN
         DECLARE
            V_BATCH_NUMBER   NUMBER;
         BEGIN
            SP_AUTOPOST_TRANSACTION_MANUAL (
               W_BRANCH_CODE,                                   -- branch code
               W_PREVIOUS_GL,                                      -- debit gl
               W_NEW_GL,                                          -- credit gl
               ABS (W_CURR_BAL),                               -- debit amount
               ABS (W_CURR_BAL),                              -- credit amount
               0,                                             -- debit account
               0,                                        -- DR contract number
               0,                                        -- CR contract number
               0,                                            -- credit account
               0,                                          -- advice num debit
               NULL,                                      -- advice date debit
               0,                                         -- advice num credit
               NULL,                                     -- advice date credit
               'BDT',                                              -- currency
               '127.0.0.1',                                     -- terminal id
               'INTELECT',                                             -- user
                  'PRODUCT CODE CHANGE...  '
               || W_NARRATION
               || W_ACCTUAL_ACCOUNT_NUMBER,                       -- narration
               V_BATCH_NUMBER                                  -- BATCH NUMBER
                             );

            W_BATCH := V_BATCH_NUMBER;
         END;
      END IF;

      --SP_GLMAST_UPDATE_TO_1 (W_NEW_GL, W_PREVIOUS_GL);
      
    UPDATE GLMAST
      SET GL_CUST_AC_ALLOWED = 1
    WHERE GL_NUMBER IN (SELECT EXTGL_GL_HEAD
                          FROM EXTGL
                         WHERE EXTGL_ACCESS_CODE = W_NEW_GL
                        UNION ALL
                        SELECT EXTGL_GL_HEAD
                          FROM EXTGL
                         WHERE EXTGL_ACCESS_CODE = W_PREVIOUS_GL) ;
                         COMMIT ;
   ELSE
      W_ERR := 'THE GLS ARE SAME... SO NO TRANSACTION IS NEEDED';
   END IF;



   ---- W_TOT_IA_FROM_LOANIA


   IF W_PREVIOUS_ACCRUAL_GL <> W_NEW_ACCRUAL_GL
   THEN
     <<ACCRUAL_FROM_LOANIA>>
      BEGIN
           SELECT NVL (ROUND (ABS (SUM (LOANIA_TOTAL_NEW_INT_AMT)), 2), 0),
                  MAX (LOANIA_VALUE_DATE)
             INTO W_TOT_IA_FROM_LOANIA, W_LATEST_ACC_DATE_FROM_LOANIA
             FROM LOANIA, LOANACNTS
            WHERE     LNACNT_ENTITY_NUM = W_ENTITY_NUMBER
                  AND LNACNT_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER
                  AND LOANIA_ENTITY_NUM = W_ENTITY_NUMBER
                  AND LOANIA_BRN_CODE = W_BRANCH_CODE
                  AND LOANIA_ACNT_NUM = W_INTERNAL_ACCOUNT_NUMBER
                  AND LOANIA_ACNT_NUM = LNACNT_INTERNAL_ACNUM
                  AND LOANIA_VALUE_DATE > LNACNT_INT_APPLIED_UPTO_DATE
                  AND LOANIA_NPA_STATUS = 0
         GROUP BY LOANIA_BRN_CODE, LOANIA_ACNT_NUM;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_TOT_IA_FROM_LOANIA := 0;

            SELECT ACNTS_OPENING_DATE
              INTO W_LATEST_ACC_DATE_FROM_LOANIA
              FROM ACNTS
             WHERE     ACNTS_ENTITY_NUM = W_ENTITY_NUMBER
                   AND ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACCOUNT_NUMBER;
      END ACCRUAL_FROM_LOANIA;

     <<ACCRUAL_FROM_LOANIAMRR>>
      BEGIN
           SELECT NVL (ROUND (ABS (SUM (LOANIAMRR_TOTAL_NEW_INT_AMT)), 2), 0)
             INTO W_TOT_IA_FROM_LOANIAMRR
             FROM LOANIAMRR
            WHERE     LOANIAMRR_ENTITY_NUM = W_ENTITY_NUMBER
                  AND LOANIAMRR_BRN_CODE = W_BRANCH_CODE
                  AND LOANIAMRR_ACNT_NUM = W_INTERNAL_ACCOUNT_NUMBER
                  AND LOANIAMRR_VALUE_DATE > W_LATEST_ACC_DATE_FROM_LOANIA
                  AND LOANIAMRR_NPA_STATUS = 0
         GROUP BY LOANIAMRR_ACNT_NUM;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            W_TOT_IA_FROM_LOANIAMRR := 0;
      END ACCRUAL_FROM_LOANIAMRR;

      W_TOT_IA := W_TOT_IA_FROM_LOANIA + W_TOT_IA_FROM_LOANIAMRR;


      IF W_TOT_IA <> 0
      THEN
         DECLARE
            V_BATCH_NUMBER   NUMBER;
         BEGIN
            SP_AUTOPOST_TRANSACTION_MANUAL (
               W_BRANCH_CODE,                                   -- branch code
               W_PREVIOUS_INCOME_GL,                               -- debit gl
               W_PREVIOUS_ACCRUAL_GL,                             -- credit gl
               W_TOT_IA,                                       -- debit amount
               W_TOT_IA,                                      -- credit amount
               0,                                             -- debit account
               0,                                        -- DR contract number
               0,                                        -- CR contract number
               0,                                            -- credit account
               0,                                          -- advice num debit
               NULL,                                      -- advice date debit
               0,                                         -- advice num credit
               NULL,                                     -- advice date credit
               'BDT',                                              -- currency
               '127.0.0.1',                                     -- terminal id
               'INTELECT',                                             -- user
                  'PRODUCT CODE CHANGE....ACCRUAL REVARSAL OF ACCOUNT '
               || W_ACCTUAL_ACCOUNT_NUMBER,                       -- narration
               V_BATCH_NUMBER                                  -- BATCH NUMBER
                             );

            W_PREVIOUS_ACCRUAL_BATCH := V_BATCH_NUMBER;
         END;



         DECLARE
            V_BATCH_NUMBER   NUMBER;
         BEGIN
            SP_AUTOPOST_TRANSACTION_MANUAL (
               W_BRANCH_CODE,                                   -- branch code
               W_NEW_ACCRUAL_GL,                                   -- debit gl
               W_NEW_INCOME_GL,                                   -- credit gl
               W_TOT_IA,                                       -- debit amount
               W_TOT_IA,                                      -- credit amount
               0,                                             -- debit account
               0,                                        -- DR contract number
               0,                                        -- CR contract number
               0,                                            -- credit account
               0,                                          -- advice num debit
               NULL,                                      -- advice date debit
               0,                                         -- advice num credit
               NULL,                                     -- advice date credit
               'BDT',                                              -- currency
               '127.0.0.1',                                     -- terminal id
               'INTELECT',                                             -- user
                  'PRODUCT CODE CHANGE....ACCRUAL REVARSAL OF ACCOUNT '
               || W_ACCTUAL_ACCOUNT_NUMBER,                       -- narration
               V_BATCH_NUMBER                                  -- BATCH NUMBER
                             );

            W_NEW_ACCRUAL_BATCH := V_BATCH_NUMBER;
         END;
      END IF;
   END IF;


   SELECT COUNT (*) + 1
     INTO W_COUNTER
     FROM PRODUCT_CHANGE_HIST
    WHERE ACCTUAL_ACCOUNT_NUMBER = W_ACCTUAL_ACCOUNT_NUMBER;

   SELECT MN_CURR_BUSINESS_DATE INTO W_CBD FROM MAINCONT;


  <<INSERT_HIST_TABLE>>
   BEGIN
      INSERT INTO PRODUCT_CHANGE_HIST (BRANCH_CODE,
                                       ACCTUAL_ACCOUNT_NUMBER,
                                       INTERNAL_ACCOUNT_NUMBER,
                                       ACCOUNT_PRODUCT_CHANGE_SL,
                                       PREVIOUS_ACCOUNT_TYPE,
                                       NEW_ACCOUNT_TYPE,
                                       PREVIOUS_ACCOUNT_SUB_TYPE,
                                       NEW_ACCOUNT_SUB_TYPE,
                                       PREVIOUS_PRODUCT_CODE,
                                       NEW_PRODUCT_CODE,
                                       DATE_OF_CHANGE,
                                       CURRENT_BUSINESS_DATE,
                                       BALANCE_TRANSFER_BATCH,
                                       PREVIOUS_ACCRUAL_BATCH,
                                       NEW_ACCRUAL_BATCH,
                                       REMARKS)
           VALUES (W_BRANCH_CODE,
                   W_ACCTUAL_ACCOUNT_NUMBER,
                   W_INTERNAL_ACCOUNT_NUMBER,
                   W_COUNTER,
                   W_PREVIOUS_ACCOUNT_TYPE,
                   W_NEW_ACCOUNT_TYPE,
                   W_PREVIOUS_ACCOUNT_SUB_TYPE,
                   W_NEW_ACCOUNT_SUB_TYPE,
                   W_PREVIOUS_PRODUCT_CODE,
                   W_NEW_PRODUCT_CODE,
                   SYSDATE,
                   W_CBD,
                   W_BATCH,
                   W_PREVIOUS_ACCRUAL_BATCH,
                   W_NEW_ACCRUAL_BATCH,
                   W_NARRATION);
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         DBMS_OUTPUT.PUT_LINE (
            'THIS ACCOUNT''S PRODUCT CODE IS ALREADY CHANGED');
   END;


  <<BREAK_POINT>>
   NULL;
END SP_PRODUCT_CODE_CHANGE;
/
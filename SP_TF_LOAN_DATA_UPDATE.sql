DROP TABLE TF_LOAN_DATA_UPDATE CASCADE CONSTRAINTS;

CREATE TABLE TF_LOAN_DATA_UPDATE
(
  BRANCH_CODE                    NUMBER(5),
  CLIENT_NUMBER                  NUMBER(12),
  CUSTOMER_NAME                  VARCHAR2(200 BYTE),
  LNACNT_ACNUM                   VARCHAR2(13 BYTE),
  PRODUCT_CODE                   NUMBER(4),
  ACCOUNT_TYPE                   VARCHAR2(5 BYTE),
  ACCOUNT_SUB_TYPE               NUMBER(3),
  CURRENCY                       VARCHAR2(3 BYTE),
  LNACNT_DISB_TYPE               VARCHAR2(1 BYTE),
  LNACIRS_APPL_INT_RATE          NUMBER(7,5),
  LNACNT_SANCTION_AMT            NUMBER(18,3),
  LNACNT_DP_REQD                 VARCHAR2(1 BYTE),
  DP_DATE                        DATE,
  DP_AMOUNT                      NUMBER(18,3),
  LNACNT_OPENING_DATE            DATE,
  LNACNT_LIMIT_SANCTION_DATE     DATE,
  LNACDSDTL_DISB_AMOUNT          NUMBER(18,3),
  LNACDSDTL_DISB_DATE            DATE,
  LNACNT_OUTSTANDING_BALANCE     NUMBER(18,3),
  LNACNT_PRIN_OS                 NUMBER(18,3),
  LNACNT_INT_OS                  NUMBER(18,3),
  LNACNT_CHG_OS                  NUMBER(18,3),
  LNACNT_INT_ACCR_UPTO           DATE,
  LNACNT_INT_APPLIED_UPTO_DATE   DATE,
  LNACNT_REVOLVING_LIMIT         NUMBER(18,3),
  LNACNT_SEC_AMT_REQD            VARCHAR2(1 BYTE),
  LNACNT_DATE_OF_NPA             DATE,
  ASSETCLSH_ASSET_CODE           VARCHAR2(2 BYTE),
  LNACNT_TOT_SUSP_BALANCE        NUMBER(18,3),
  LNACNT_INT_SUSP_BALANCE        NUMBER(18,3),
  LNACNT_CHG_SUSP_BALANCE        NUMBER(18,3),
  REPAYMENT_SCHEDULE_REQUIRED    VARCHAR2(1 BYTE),
  TOTAL_INT_DEBIT                NUMBER(18,3),
  LNACNT_SEGMENT_CODE            VARCHAR2(6 BYTE),
  LNACNT_PURPOSE_CODE            VARCHAR2(6 BYTE),
  LNACNT_INDUS_CODE              VARCHAR2(6 BYTE),
  LNACNT_SUB_INDUS_CODE          VARCHAR2(6 BYTE),
  LNACRSDTL_REPAY_FREQ           VARCHAR2(1 BYTE),
  LNACRSDTL_REPAY_FROM_DATE      DATE,
  TOTAL_NUMBER_INSTALLEMNT       NUMBER,
  LNACRSDTL_REPAY_AMT            NUMBER(18,3),
  ECONOMIC_PURPOSE_CODE          VARCHAR2(6 BYTE),
  LNACNT_LIMIT_AVL_ON_DATE       NUMBER(18,3),
  EQUAL_INSTALLMENT              VARCHAR2(1 BYTE),
  LNACNT_CL_REPORT_CODE          VARCHAR2(6 BYTE),
  LONIA_INTEREST_ACCRUED_AMOUNT  NUMBER(18,3),
  TOTAL_RECOVERY_AMOUNT          NUMBER(18,3),
  PRINCIPAL_RECOVERY_AMOUNT      NUMBER(18,3),
  INTEREST_RECOVERY_AMOUNT       NUMBER(18,3),
  CHARGES_RECOVERY_AMOUNT        NUMBER(18,3),
  LC_AMOUNT                      NUMBER(18,3),
  LC_NUMBER                      VARCHAR2(50 BYTE),
  LC_CURRENCY                    VARCHAR2(3 BYTE),
  LC_DATE                        DATE,
  LNACNT_EXPIRY_DATE             DATE,
  REMARKS                        VARCHAR2(200 BYTE)
)
TABLESPACE TBFES
RESULT_CACHE (MODE DEFAULT)
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;










CREATE OR REPLACE PROCEDURE SP_TF_DATA_UPDATE (
   P_BRANCH_CODE                     NUMBER,
   P_CLIENT_NUMBER                   NUMBER,
   P_CUSTOMER_NAME                   VARCHAR2,
   P_LNACNT_ACNUM                    VARCHAR2,
   P_PRODUCT_CODE                    NUMBER,
   P_ACCOUNT_TYPE                    VARCHAR2,
   P_ACCOUNT_SUB_TYPE                NUMBER,
   P_CURRENCY                        VARCHAR2,
   P_LNACNT_DISB_TYPE                VARCHAR2,
   P_LNACIRS_APPL_INT_RATE           NUMBER,
   P_LNACNT_SANCTION_AMT             NUMBER,
   P_LNACNT_DP_REQD                  VARCHAR2,
   P_DP_DATE                         DATE,
   P_DP_AMOUNT                       NUMBER,
   P_LNACNT_OPENING_DATE             DATE,
   P_LNACNT_LIMIT_SANCTION_DATE      DATE,
   P_LNACDSDTL_DISB_AMOUNT           NUMBER,
   P_LNACDSDTL_DISB_DATE             DATE,
   P_LNACNT_OUTSTANDING_BALANCE      NUMBER,
   P_LNACNT_PRIN_OS                  NUMBER,
   P_LNACNT_INT_OS                   NUMBER,
   P_LNACNT_CHG_OS                   NUMBER,
   P_LNACNT_INT_ACCR_UPTO            DATE,
   P_LNACNT_INT_APPLIED_UPTO_DATE    DATE,
   P_LNACNT_REVOLVING_LIMIT          NUMBER,
   P_LNACNT_SEC_AMT_REQD             VARCHAR2,
   P_LNACNT_DATE_OF_NPA              DATE,
   P_ASSETCLSH_ASSET_CODE            VARCHAR2,
   P_LNACNT_TOT_SUSP_BALANCE         NUMBER,
   P_LNACNT_INT_SUSP_BALANCE         NUMBER,
   P_LNACNT_CHG_SUSP_BALANCE         NUMBER,
   P_REPAYMENT_SCHEDULE_REQUIRED     VARCHAR2,
   P_TOTAL_INT_DEBIT                 NUMBER,
   P_LNACNT_SEGMENT_CODE             VARCHAR2,
   P_LNACNT_PURPOSE_CODE             VARCHAR2,
   P_LNACNT_INDUS_CODE               VARCHAR2,
   P_LNACNT_SUB_INDUS_CODE           VARCHAR2,
   P_LNACRSDTL_REPAY_FREQ            VARCHAR2,
   P_LNACRSDTL_REPAY_FROM_DATE       DATE,
   P_TOTAL_NUMBER_INSTALLEMNT        NUMBER,
   P_LNACRSDTL_REPAY_AMT             NUMBER,
   P_ECONOMIC_PURPOSE_CODE           VARCHAR2,
   P_LNACNT_LIMIT_AVL_ON_DATE        NUMBER,
   P_EQUAL_INSTALLMENT               VARCHAR2,
   P_LNACNT_CL_REPORT_CODE           VARCHAR2,
   P_LONIA_INT_ACCRUED_AMOUNT        NUMBER,
   P_TOTAL_RECOVERY_AMOUNT           NUMBER,
   P_PRINCIPAL_RECOVERY_AMOUNT       NUMBER,
   P_INTEREST_RECOVERY_AMOUNT        NUMBER,
   P_CHARGES_RECOVERY_AMOUNT         NUMBER,
   P_LC_AMOUNT                       NUMBER,
   P_LC_NUMBER                       VARCHAR2,
   P_LC_CURRENCY                     VARCHAR2,
   P_LC_DATE                         DATE,
   P_LNACNT_EXPIRY_DATE              DATE)
AS
   V_INTERNAL_AC_NUM            IACLINK.IACLINK_INTERNAL_ACNUM%TYPE;
   V_CLIENT_NUM                 IACLINK.IACLINK_CIF_NUMBER%TYPE;
   V_PRODUCT_CODE               IACLINK.IACLINK_PROD_CODE%TYPE;
   V_ROW_COUNT                  NUMBER;
   V_LIMITLINE_NUMBER           NUMBER;
   V_CONT_LOAN                  NUMBER (1);
   V_OUTSTANDING_BAL            NUMBER (18, 3);


   V_SEGMENT_CODE               VARCHAR2 (6) := NULL;
   V_INDUSTRY_CODE              VARCHAR2 (6);
   V_PURPOSE_CODE               VARCHAR2 (6);


   V_CURRENCY                   VARCHAR2 (3) := P_CURRENCY;
   V_TOTAL_REPAY_AMOUNT         NUMBER (18, 3);

   V_ACCRU_GL                   VARCHAR2 (15);
   V_INCOME_GL                  VARCHAR2 (15);
   V_ACCRU_AMOUNT               NUMBER (18, 3);

   V_BATCH_NUMBER               NUMBER;

   V_LONIA_INT_ACCRUED_AMOUNT   NUMBER (18, 3) := P_LONIA_INT_ACCRUED_AMOUNT;
BEGIN
  <<INFO_FROM_IACLINK>>
   BEGIN
      SELECT IACLINK_INTERNAL_ACNUM, IACLINK_CIF_NUMBER, IACLINK_PROD_CODE
        INTO V_INTERNAL_AC_NUM, V_CLIENT_NUM, V_PRODUCT_CODE
        FROM IACLINK
       WHERE IACLINK_ENTITY_NUM = 1 AND IACLINK_ACTUAL_ACNUM = P_LNACNT_ACNUM;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         UPDATE TF_LOAN_DATA_UPDATE
            SET REMARKS = 'INVALID ACCOUNT NUMBER';

         COMMIT;
   END INFO_FROM_IACLINK;

   SELECT PRODUCT_FOR_RUN_ACS
     INTO V_CONT_LOAN
     FROM PRODUCTS
    WHERE PRODUCT_CODE = V_PRODUCT_CODE;

   SELECT ACNTBAL_BC_BAL
     INTO V_OUTSTANDING_BAL
     FROM ACNTBAL
    WHERE     ACNTBAL_ENTITY_NUM = 1
          AND ACNTBAL_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

   BEGIN
      SELECT ACASLLDTL_CLIENT_NUM, ACASLLDTL_LIMIT_LINE_NUM
        INTO V_CLIENT_NUM, V_LIMITLINE_NUMBER
        FROM ACASLLDTL
       WHERE ACASLLDTL_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_LIMITLINE_NUMBER := 0;
   END;

  --Updating acnts opening date
  <<UPDATE_ACNTS_OPENING_DATE>>
   BEGIN
      UPDATE ACNTS A
         SET ACNTS_OPENING_DATE = P_LNACNT_OPENING_DATE
       WHERE     ACNTS_ENTITY_NUM = 1
             AND ACNTS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
   END UPDATE_ACNTS_OPENING_DATE;

  <<INSERT_UPDATE_ASSETCLS>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM ASSETCLS
       WHERE     ASSETCLS_ENTITY_NUM = 1
             AND ASSETCLS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;


      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO ASSETCLS (ASSETCLS_ENTITY_NUM,
                               ASSETCLS_INTERNAL_ACNUM,
                               ASSETCLS_LATEST_EFF_DATE,
                               ASSETCLS_ASSET_CODE,
                               ASSETCLS_NPA_DATE,
                               ASSETCLS_AUTO_MAN_FLG,
                               ASSETCLS_REMARKS)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_OPENING_DATE,
                      P_ASSETCLSH_ASSET_CODE,
                      P_LNACNT_DATE_OF_NPA,
                      'A',
                      'MIGRATION');
      ELSE
         UPDATE ASSETCLS
            SET ASSETCLS_LATEST_EFF_DATE = P_LNACNT_OPENING_DATE,
                ASSETCLS_ASSET_CODE = P_ASSETCLSH_ASSET_CODE,
                ASSETCLS_NPA_DATE = P_LNACNT_DATE_OF_NPA
          WHERE     ASSETCLS_ENTITY_NUM = 1
                AND ASSETCLS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_ASSETCLS;

  --ASSETCLS

  <<INSERT_UPDATE_ASSETCLSHIST>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM ASSETCLSHIST
       WHERE     ASSETCLSH_ENTITY_NUM = 1
             AND ASSETCLSH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO ASSETCLSHIST (ASSETCLSH_ENTITY_NUM,
                                   ASSETCLSH_INTERNAL_ACNUM,
                                   ASSETCLSH_EFF_DATE,
                                   ASSETCLSH_ASSET_CODE,
                                   ASSETCLSH_NPA_DATE,
                                   ASSETCLSH_AUTO_MAN_FLG,
                                   ASSETCLSH_REMARKS,
                                   ASSETCLSH_ENTD_BY,
                                   ASSETCLSH_ENTD_ON,
                                   ASSETCLSH_AUTH_BY,
                                   ASSETCLSH_AUTH_ON)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_OPENING_DATE,
                      P_ASSETCLSH_ASSET_CODE,
                      P_LNACNT_DATE_OF_NPA,
                      'A',
                      'MIGRATION',
                      'MIG',
                      TRUNC (SYSDATE),
                      'MIG',
                      TRUNC (SYSDATE));
      ELSE
         UPDATE ASSETCLSHIST
            SET ASSETCLSH_EFF_DATE = P_LNACNT_OPENING_DATE,
                ASSETCLSH_ASSET_CODE = P_ASSETCLSH_ASSET_CODE,
                ASSETCLSH_NPA_DATE = P_LNACNT_DATE_OF_NPA
          WHERE     ASSETCLSH_ENTITY_NUM = 1
                AND ASSETCLSH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_ASSETCLSHIST;



  -- LNACNT_SANCTION_AMT, LNACNT_OPENING_DATE, LNACNT_LIMIT_SANCTION_DATE


  <<UPDATE_INSERT_LIMITLINE>>
   BEGIN
      UPDATE LIMITLINE
         SET LMTLINE_CREATION_DATE = P_LNACNT_OPENING_DATE,
             LMTLINE_DATE_OF_SANCTION = P_LNACNT_LIMIT_SANCTION_DATE,
             LMTLINE_LIMIT_EFF_DATE = P_LNACNT_OPENING_DATE,
             LMTLINE_LIMIT_EXPIRY_DATE = P_LNACNT_EXPIRY_DATE,
             LMTLINE_SANCTION_AMT = P_LNACNT_SANCTION_AMT,
             LMTLINE_LIMIT_AVL_ON_DATE = P_LNACNT_SANCTION_AMT
       WHERE     LMTLINE_ENTITY_NUM = 1
             AND LMTLINE_CLIENT_CODE = V_CLIENT_NUM
             AND LMTLINE_NUM = V_LIMITLINE_NUMBER;

      UPDATE LIMITLINEHIST
         SET LIMLNEHIST_EFF_DATE = P_LNACNT_OPENING_DATE,
             LIMLNEHIST_DATE_OF_SANCTION = P_LNACNT_LIMIT_SANCTION_DATE,
             LIMLNEHIST_SANCTION_AMT = P_LNACNT_SANCTION_AMT,
             LIMLNEHIST_LIMIT_EXPIRY_DATE = P_LNACNT_EXPIRY_DATE,
             LIMLNEHIST_LIMIT_AVL_ON_DATE = P_LNACNT_SANCTION_AMT
       WHERE     LIMLNEHIST_ENTITY_NUM = 1
             AND LIMLNEHIST_CLIENT_CODE = V_CLIENT_NUM
             AND LIMLNEHIST_LIMIT_LINE_NUM = V_LIMITLINE_NUMBER;
   END UPDATE_INSERT_LIMITLINE;


   UPDATE LOANACNTS
      SET LNACNT_DISB_TYPE = P_LNACNT_DISB_TYPE,
          LNACNT_INT_ACCR_UPTO = P_LNACNT_INT_ACCR_UPTO - 1,
          LNACNT_INT_APPLIED_UPTO_DATE = P_LNACNT_INT_APPLIED_UPTO_DATE,
          LNACNT_LC_NUM = P_LC_NUMBER,
          LNACNT_LC_OPEN_DATE = P_LC_DATE,
          LNACNT_LC_AMT = P_LC_AMOUNT
    WHERE LNACNT_ENTITY_NUM = 1 AND LNACNT_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

   SELECT COUNT (*)
     INTO V_ROW_COUNT
     FROM LOANACHIST
    WHERE LNACH_ENTITY_NUM = 1 AND LNACH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

   IF V_ROW_COUNT = 0
   THEN
      INSERT INTO LOANACHIST (LNACH_ENTITY_NUM,
                              LNACH_INTERNAL_ACNUM,
                              LNACH_EFF_DATE,
                              LNACH_AUTO_INSTALL_RECOV_REQD,
                              LNACH_ENTD_BY,
                              LNACH_ENTD_ON,
                              LNACH_AUTH_BY,
                              LNACH_AUTH_ON,
                              LNACH_MICR_CITY_CODE,
                              LNACH_MICR_BANK_CODE,
                              LNACH_MICR_BRN_CODE)
           VALUES (1,
                   V_INTERNAL_AC_NUM,
                   P_LNACNT_OPENING_DATE,
                   '0',
                   'MIG',
                   P_LNACNT_OPENING_DATE,
                   'MIG',
                   P_LNACNT_OPENING_DATE,
                   0,
                   0,
                   0);
   ELSE
      UPDATE LOANACHIST
         SET LNACH_EFF_DATE = P_LNACNT_OPENING_DATE
       WHERE     LNACH_ENTITY_NUM = 1
             AND LNACH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
   END IF;

   SELECT COUNT (*)
     INTO V_ROW_COUNT
     FROM LLACNTOS
    WHERE     LLACNTOS_ENTITY_NUM = 1
          AND LLACNTOS_CLIENT_CODE = V_CLIENT_NUM
          AND LLACNTOS_LIMIT_LINE_NUM = V_LIMITLINE_NUMBER
          AND LLACNTOS_CLIENT_ACNUM = V_INTERNAL_AC_NUM;



   IF V_ROW_COUNT = 0
   THEN
      IF V_CONT_LOAN = 1
      THEN
         INSERT INTO LLACNTOS (LLACNTOS_ENTITY_NUM,
                               LLACNTOS_CLIENT_CODE,
                               LLACNTOS_LIMIT_LINE_NUM,
                               LLACNTOS_CLIENT_ACNUM,
                               LLACNTOS_LIMIT_CURR_OS_AMT,
                               LLACNTOS_LIMIT_CURR_DISB_MADE)
              VALUES (1,
                      V_CLIENT_NUM,
                      V_LIMITLINE_NUMBER,
                      V_INTERNAL_AC_NUM,
                      V_OUTSTANDING_BAL,
                      0);
      ELSE
         INSERT INTO LLACNTOS (LLACNTOS_ENTITY_NUM,
                               LLACNTOS_CLIENT_CODE,
                               LLACNTOS_LIMIT_LINE_NUM,
                               LLACNTOS_CLIENT_ACNUM,
                               LLACNTOS_LIMIT_CURR_OS_AMT,
                               LLACNTOS_LIMIT_CURR_DISB_MADE)
              VALUES (1,
                      V_CLIENT_NUM,
                      V_LIMITLINE_NUMBER,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_SANCTION_AMT - P_LNACDSDTL_DISB_AMOUNT,
                      (-1) * P_LNACDSDTL_DISB_AMOUNT);
      END IF;
   ELSE
      IF V_CONT_LOAN = 1
      THEN
         NULL;

         UPDATE LLACNTOS
            SET LLACNTOS_LIMIT_CURR_OS_AMT = V_OUTSTANDING_BAL,
                LLACNTOS_LIMIT_CURR_DISB_MADE = 0
          WHERE     LLACNTOS_ENTITY_NUM = 1
                AND LLACNTOS_CLIENT_CODE = V_CLIENT_NUM
                AND LLACNTOS_LIMIT_LINE_NUM = V_LIMITLINE_NUMBER
                AND LLACNTOS_CLIENT_ACNUM = V_INTERNAL_AC_NUM;
      ELSE
         UPDATE LLACNTOS
            SET LLACNTOS_LIMIT_CURR_OS_AMT =
                   P_LNACNT_SANCTION_AMT - P_LNACDSDTL_DISB_AMOUNT,
                LLACNTOS_LIMIT_CURR_DISB_MADE =
                   (-1) * P_LNACDSDTL_DISB_AMOUNT
          WHERE     LLACNTOS_ENTITY_NUM = 1
                AND LLACNTOS_CLIENT_CODE = V_CLIENT_NUM
                AND LLACNTOS_LIMIT_LINE_NUM = V_LIMITLINE_NUMBER
                AND LLACNTOS_CLIENT_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END IF;



  ---- Moin-----



  <<INSERT_UPDATE_LNACDSDTL>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACDSDTL
       WHERE     LNACDSDTL_ENTITY_NUM = 1
             AND LNACDSDTL_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;


      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACDSDTL (LNACDSDTL_ENTITY_NUM,
                                LNACDSDTL_INTERNAL_ACNUM,
                                LNACDSDTL_SL_NUM,
                                LNACDSDTL_STAGE_DESCN,
                                LNACDSDTL_DISB_CURR,
                                LNACDSDTL_DISB_DATE,
                                LNACDSDTL_DISB_AMOUNT)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      1,
                      'MIGRATION',
                      NVL (P_CURRENCY, 'BDT'),
                      P_LNACDSDTL_DISB_DATE,
                      P_LNACDSDTL_DISB_AMOUNT);
      ELSE
         UPDATE LNACDSDTL
            SET LNACDSDTL_DISB_DATE = P_LNACDSDTL_DISB_DATE,
                LNACDSDTL_DISB_AMOUNT = P_LNACDSDTL_DISB_AMOUNT
          WHERE     LNACDSDTL_ENTITY_NUM = 1
                AND LNACDSDTL_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACDSDTL;


  <<INSERT_UPDATE_LNACDISB>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACDISB
       WHERE     LNACDISB_ENTITY_NUM = 1
             AND LNACDISB_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
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
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      1,
                      P_LNACDSDTL_DISB_DATE,
                      1,
                      'BDT',
                      P_LNACDSDTL_DISB_AMOUNT,
                      0,
                      'MIGRATION',
                      2,
                      TRUNC (SYSDATE),
                      'MIG',
                      TRUNC (SYSDATE),
                      'MIG',
                      TRUNC (SYSDATE),
                      0,
                      0,
                      0,
                      0,
                      0);
      ELSE
         UPDATE LNACDISB
            SET LNACDISB_DISB_ON = P_LNACDSDTL_DISB_DATE,
                LNACDISB_DISB_AMT = P_LNACDSDTL_DISB_AMOUNT
          WHERE     LNACDISB_ENTITY_NUM = 1
                AND LNACDISB_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACDISB;


  <<INSERT_UPDATE_LNACDSDTLHIST>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACDSDTLHIST
       WHERE     LNACDSDTLH_ENTITY_NUM = 1
             AND LNACDSDTLH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACDSDTLHIST (LNACDSDTLH_ENTITY_NUM,
                                    LNACDSDTLH_INTERNAL_ACNUM,
                                    LNACDSDTLH_EFF_DATE,
                                    LNACDSDTLH_SL_NUM,
                                    LNACDSDTLH_STAGE_DESCN,
                                    LNACDSDTLH_DISB_CURR,
                                    LNACDSDTLH_DISB_DATE,
                                    LNACDSDTLH_DISB_AMOUNT)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_OPENING_DATE,
                      1,
                      'MIGRATION',
                      'BDT',
                      P_LNACDSDTL_DISB_DATE,
                      P_LNACDSDTL_DISB_AMOUNT);
      ELSE
         UPDATE LNACDSDTLHIST
            SET LNACDSDTLH_EFF_DATE = P_LNACNT_OPENING_DATE,
                LNACDSDTLH_DISB_DATE = P_LNACDSDTL_DISB_DATE,
                LNACDSDTLH_DISB_AMOUNT = P_LNACDSDTL_DISB_AMOUNT
          WHERE     LNACDSDTLH_ENTITY_NUM = 1
                AND LNACDSDTLH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACDSDTLHIST;



  --------------- Pollab vai-----------------



  --LNACRIS AC_LEVEL_INT_REQ =1
  <<INSERT_UPDATE_LNACRIS>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACIRS
       WHERE     LNACIRS_ENTITY_NUM = 1
             AND LNACIRS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACIRS (LNACIRS_ENTITY_NUM,
                              LNACIRS_INTERNAL_ACNUM,
                              LNACIRS_LATEST_EFF_DATE,
                              LNACIRS_AC_LEVEL_INT_REQD,
                              LNACIRS_FIXED_FLOATING_RATE,
                              LNACIRS_OVERDUE_INT_APPLICABLE,
                              LNACIRS_REMARKS1,
                              LNACIRS_PENAL_INT_RATE)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      TRUNC (SYSDATE),
                      1,
                      1,
                      1,
                      'MIGRATION',
                      0);
      ELSE
         UPDATE LNACIRS
            SET LNACIRS_LATEST_EFF_DATE = TRUNC (SYSDATE),
                LNACIRS_AC_LEVEL_INT_REQD = 1,
                LNACIRS_FIXED_FLOATING_RATE = 1
          WHERE     LNACIRS_ENTITY_NUM = 1
                AND LNACIRS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACRIS;



  --LNACIRSHIST
  <<INSERT_UPDATE_LNACIRSHIST>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACIRSHIST
       WHERE     LNACIRSH_ENTITY_NUM = 1
             AND LNACIRSH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACIRSHIST (LNACIRSH_ENTITY_NUM,
                                  LNACIRSH_INTERNAL_ACNUM,
                                  LNACIRSH_EFF_DATE,
                                  LNACIRSH_AC_LEVEL_INT_REQD,
                                  LNACIRSH_FIXED_FLOATING_RATE,
                                  LNACIRSH_OD_INT_APPLICABLE,
                                  LNACIRSH_ENTD_BY,
                                  LNACIRSH_ENTD_ON,
                                  LNACIRSH_AUTH_BY,
                                  LNACIRSH_AUTH_ON,
                                  LNACIRSH_PENAL_INT_RATE)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      TRUNC (SYSDATE),
                      '1',
                      '1',
                      '1',
                      'MIG',
                      TRUNC (SYSDATE),
                      'MIG',
                      TRUNC (SYSDATE),
                      0);
      ELSE
         UPDATE LNACIRSHIST
            SET LNACIRSH_EFF_DATE = TRUNC (SYSDATE),
                LNACIRSH_AC_LEVEL_INT_REQD = 1,
                LNACIRSH_FIXED_FLOATING_RATE = 1
          WHERE     LNACIRSH_ENTITY_NUM = 1
                AND LNACIRSH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACIRSHIST;



  --LNACIR
  <<INSERT_UPDATE_LNACIR>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACIR
       WHERE     LNACIR_ENTITY_NUM = 1
             AND LNACIR_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACIR (LNACIR_ENTITY_NUM,
                             LNACIR_INTERNAL_ACNUM,
                             LNACIR_LATEST_EFF_DATE,
                             LNACIR_AMT_SLABS_REQD,
                             LNACIR_SLAB_APPL_CHOICE,
                             LNACIR_APPL_INT_RATE,
                             LNACIR_REMARKS1)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      TRUNC (SYSDATE),
                      '0',
                      '1',
                      P_LNACIRS_APPL_INT_RATE,
                      'MIGRATION');
      ELSE
         UPDATE LNACIR
            SET LNACIR_LATEST_EFF_DATE = TRUNC (SYSDATE),
                LNACIR_APPL_INT_RATE = P_LNACIRS_APPL_INT_RATE
          WHERE     LNACIR_ENTITY_NUM = 1
                AND LNACIR_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACIR;



  --LNACIRHIST
  <<INSERT_UPDATE_LNACIRHIST>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACIRHIST
       WHERE     LNACIRH_ENTITY_NUM = 1
             AND LNACIRH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACIRHIST (LNACIRH_ENTITY_NUM,
                                 LNACIRH_INTERNAL_ACNUM,
                                 LNACIRH_EFF_DATE,
                                 LNACIRH_AMT_SLABS_REQD,
                                 LNACIRH_SLAB_APPL_CHOICE,
                                 LNACIRH_APPL_INT_RATE,
                                 LNACIRH_REMARKS1,
                                 LNACIRH_ENTD_BY,
                                 LNACIRH_ENTD_ON,
                                 LNACIRH_AUTH_BY,
                                 LNACIRH_AUTH_ON)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      TRUNC (SYSDATE),
                      '0',
                      '1',
                      P_LNACIRS_APPL_INT_RATE,
                      'MIGRATION',
                      'MIG',
                      TRUNC (SYSDATE),
                      'MIG',
                      TRUNC (SYSDATE));
      ELSE
         UPDATE LNACIRHIST
            SET LNACIRH_EFF_DATE = TRUNC (SYSDATE),
                LNACIRH_APPL_INT_RATE = P_LNACIRS_APPL_INT_RATE
          WHERE     LNACIRH_ENTITY_NUM = 1
                AND LNACIRH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACIRHIST;



   IF NVL (P_LNACNT_TOT_SUSP_BALANCE, 0) <> 0
   THEN
     --LNSUSPBAL
     <<INSERT_UPDATE_LNSUSPBAL>>
      BEGIN
         SELECT COUNT (*)
           INTO V_ROW_COUNT
           FROM LNSUSPBAL
          WHERE     LNSUSPBAL_ENTITY_NUM = 1
                AND LNSUSPBAL_ACNT_NUM = V_INTERNAL_AC_NUM;

         IF V_ROW_COUNT = 0
         THEN
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
                 VALUES (1,
                         V_INTERNAL_AC_NUM,
                         P_CURRENCY,
                         P_LNACNT_TOT_SUSP_BALANCE,
                         0,
                         P_LNACNT_TOT_SUSP_BALANCE,
                         0,
                         P_LNACNT_INT_SUSP_BALANCE,
                         P_LNACNT_CHG_SUSP_BALANCE,
                         0,
                         0,
                         0,
                         0);
         ELSE
            UPDATE LNSUSPBAL
               SET LNSUSPBAL_SUSP_BAL =
                      LNSUSPBAL_SUSP_BAL + ABS (P_LNACNT_TOT_SUSP_BALANCE),
                   LNSUSPBAL_PRIN_BAL = 0,
                   LNSUSPBAL_INT_BAL =
                      LNSUSPBAL_INT_BAL + ABS (P_LNACNT_INT_SUSP_BALANCE),
                   LNSUSPBAL_CHG_BAL =
                      LNSUSPBAL_CHG_BAL + ABS (P_LNACNT_CHG_SUSP_BALANCE),
                   LNSUSPBAL_SUSP_CR_SUM = P_LNACNT_CHG_SUSP_BALANCE
             WHERE     LNSUSPBAL_ENTITY_NUM = 1
                   AND LNSUSPBAL_ACNT_NUM = V_INTERNAL_AC_NUM;
         END IF;
      END INSERT_UPDATE_LNSUSPBAL;



     --LNSUSPLED
     <<INSERT_UPDATE_LNSUSPLED>>
      BEGIN
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
                                LNSUSP_AUTO_MANUAL,
                                LNSUSP_ENTD_BY,
                                LNSUSP_ENTD_ON,
                                LNSUSP_AUTH_BY,
                                LNSUSP_AUTH_ON)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      TRUNC (SYSDATE),
                      1,
                      TRUNC (SYSDATE),
                      '2',
                      'C',
                      'BDT',
                      P_LNACNT_TOT_SUSP_BALANCE,
                      P_LNACNT_TOT_SUSP_BALANCE,
                      0,
                      'M',
                      'MIG',
                      TRUNC (SYSDATE),
                      'MIG',
                      TRUNC (SYSDATE));
      END INSERT_UPDATE_LNSUSPLED;
   END IF;


  ------ Wahid --------------



  <<INSERT_UPDATE_LNACMIS>>
   BEGIN
      BEGIN
         SELECT SEGMENTS_CODE
           INTO V_SEGMENT_CODE
           FROM SEGMENTS
          WHERE SEGMENTS_CODE = P_LNACNT_SEGMENT_CODE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_SEGMENT_CODE := NULL;
      END;

      BEGIN
         SELECT INDUSTRY_CODE
           INTO V_INDUSTRY_CODE
           FROM INDUSTRIES
          WHERE INDUSTRY_CODE = P_LNACNT_INDUS_CODE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_INDUSTRY_CODE := NULL;
      END;

      BEGIN
         SELECT PURP_CODE
           INTO V_PURPOSE_CODE
           FROM PURPCODES
          WHERE PURP_CODE = P_LNACNT_PURPOSE_CODE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_PURPOSE_CODE := NULL;
      END;


      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACMIS
       WHERE     LNACMIS_ENTITY_NUM = 1
             AND LNACMIS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACMIS (LNACMIS_ENTITY_NUM,
                              LNACMIS_INTERNAL_ACNUM,
                              LNACMIS_LATEST_EFF_DATE,
                              LNACMIS_SEGMENT_CODE,
                              LNACMIS_HO_DEPT_CODE,
                              LNACMIS_INDUS_CODE,
                              LNACMIS_SUB_INDUS_CODE,
                              LNACMIS_BSR_MAIN_ORG_CODE,
                              LNACMIS_BSR_SUB_ORG_CODE,
                              LNACMIS_BSR_STATE_CODE,
                              LNACMIS_BSR_DISTRICT_CODE,
                              LNACMIS_NATURE_BORROWAL_AC,
                              LNACMIS_PURPOSE_CODE)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_OPENING_DATE,
                      P_LNACNT_SEGMENT_CODE,
                      P_LNACNT_CL_REPORT_CODE,
                      P_LNACNT_INDUS_CODE,
                      P_LNACNT_SUB_INDUS_CODE,
                      '1000',
                      '1001',
                      1,
                      101,
                      99,
                      P_LNACNT_PURPOSE_CODE);
      ELSE
         UPDATE LNACMIS
            SET LNACMIS_LATEST_EFF_DATE = P_LNACNT_OPENING_DATE,
                LNACMIS_SUB_INDUS_CODE = P_LNACNT_SUB_INDUS_CODE,
                LNACMIS_SEGMENT_CODE =
                   NVL (V_SEGMENT_CODE, LNACMIS_SEGMENT_CODE),
                LNACMIS_INDUS_CODE = NVL (V_INDUSTRY_CODE, LNACMIS_INDUS_CODE),
                LNACMIS_PURPOSE_CODE =
                   NVL (V_PURPOSE_CODE, LNACMIS_PURPOSE_CODE),
                LNACMIS_HO_DEPT_CODE = P_LNACNT_CL_REPORT_CODE
          WHERE LNACMIS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACMIS;


  <<INSERT_UPDATE_LNACMISHIST>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACMISHIST
       WHERE     LNACMISH_ENTITY_NUM = 1
             AND LNACMISH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;


      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACMISHIST (LNACMISH_ENTITY_NUM,
                                  LNACMISH_INTERNAL_ACNUM,
                                  LNACMISH_EFF_DATE,
                                  LNACMISH_SEGMENT_CODE,
                                  LNACMISH_HO_DEPT_CODE,
                                  LNACMISH_SUB_INDUS_CODE,
                                  LNACMISH_BSR_MAIN_ORG_CODE,
                                  LNACMISH_BSR_SUB_ORG_CODE,
                                  LNACMISH_BSR_STATE_CODE,
                                  LNACMISH_BSR_DISTRICT_CODE,
                                  LNACMISH_NATURE_BORROWAL_AC,
                                  LNACMISH_ENTD_BY,
                                  LNACMISH_ENTD_ON,
                                  LNACMISH_AUTH_BY,
                                  LNACMISH_AUTH_ON,
                                  LNACMISH_PURPOSE_CODE)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_OPENING_DATE,
                      P_LNACNT_SEGMENT_CODE,
                      P_LNACNT_CL_REPORT_CODE,
                      P_LNACNT_SUB_INDUS_CODE,
                      '1000',
                      '1001',
                      1,
                      101,
                      99,
                      'MIG',
                      TRUNC (SYSDATE),
                      'MIG',
                      TRUNC (SYSDATE),
                      P_LNACNT_PURPOSE_CODE);
      ELSE
         UPDATE LNACMISHIST
            SET LNACMISH_EFF_DATE = P_LNACNT_OPENING_DATE,
                LNACMISH_SEGMENT_CODE =
                   NVL (V_SEGMENT_CODE, LNACMISH_SEGMENT_CODE),
                LNACMISH_SUB_INDUS_CODE = P_LNACNT_SUB_INDUS_CODE,
                LNACMISH_PURPOSE_CODE =
                   NVL (V_PURPOSE_CODE, LNACMISH_PURPOSE_CODE),
                LNACMISH_HO_DEPT_CODE = P_LNACNT_CL_REPORT_CODE
          WHERE LNACMISH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACMISHIST;



   ---- Sayeed -----------------



   IF V_CURRENCY IS NULL
   THEN
      V_CURRENCY := 'BDT';
   END IF;

   IF P_LNACRSDTL_REPAY_FREQ = 'M'
   THEN
      V_TOTAL_REPAY_AMOUNT :=
         P_LNACRSDTL_REPAY_AMT * P_TOTAL_NUMBER_INSTALLEMNT;
   ELSIF P_LNACRSDTL_REPAY_FREQ = 'Q'
   THEN
      V_TOTAL_REPAY_AMOUNT :=
         P_LNACRSDTL_REPAY_AMT * P_TOTAL_NUMBER_INSTALLEMNT * 3;
   ELSIF P_LNACRSDTL_REPAY_FREQ = 'H'
   THEN
      V_TOTAL_REPAY_AMOUNT :=
         P_LNACRSDTL_REPAY_AMT * P_TOTAL_NUMBER_INSTALLEMNT * 6;
   ELSIF P_LNACRSDTL_REPAY_FREQ = 'Y'
   THEN
      V_TOTAL_REPAY_AMOUNT :=
         P_LNACRSDTL_REPAY_AMT * P_TOTAL_NUMBER_INSTALLEMNT * 12;
   ELSE
      V_TOTAL_REPAY_AMOUNT := P_LNACRSDTL_REPAY_AMT;
   END IF;


  ---------------------------------------------
  <<INSERT_UPDATE_LNACRSDTL>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACRSDTL
       WHERE     LNACRSDTL_ENTITY_NUM = 1
             AND LNACRSDTL_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;


      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNACRSDTL (LNACRSDTL_ENTITY_NUM,
                                LNACRSDTL_INTERNAL_ACNUM,
                                LNACRSDTL_SL_NUM,
                                LNACRSDTL_REPAY_AMT_CURR,
                                LNACRSDTL_REPAY_AMT,
                                LNACRSDTL_REPAY_FREQ,
                                LNACRSDTL_REPAY_FROM_DATE,
                                LNACRSDTL_NUM_OF_INSTALLMENT,
                                LNACRSDTL_TOT_REPAY_AMT)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      1,
                      V_CURRENCY,
                      P_LNACRSDTL_REPAY_AMT,
                      P_LNACRSDTL_REPAY_FREQ,
                      P_LNACRSDTL_REPAY_FROM_DATE,
                      P_TOTAL_NUMBER_INSTALLEMNT,
                      V_TOTAL_REPAY_AMOUNT);
      ELSE
         UPDATE LNACRSDTL
            SET LNACRSDTL_REPAY_AMT = P_LNACRSDTL_REPAY_AMT,
                LNACRSDTL_REPAY_FREQ = P_LNACRSDTL_REPAY_FREQ,
                LNACRSDTL_REPAY_FROM_DATE = P_LNACRSDTL_REPAY_FROM_DATE,
                LNACRSDTL_NUM_OF_INSTALLMENT = P_TOTAL_NUMBER_INSTALLEMNT,
                LNACRSDTL_TOT_REPAY_AMT = V_TOTAL_REPAY_AMOUNT
          WHERE     LNACRSDTL_ENTITY_NUM = 1
                AND LNACRSDTL_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACRSDTL;



  -------------------------------------
  <<INSERT_UPDATE_LNACRSHIST>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACRSHIST
       WHERE     LNACRSH_ENTITY_NUM = 1
             AND LNACRSH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;

      IF V_ROW_COUNT = 0
      THEN
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
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_OPENING_DATE,
                      P_EQUAL_INSTALLMENT,
                      V_TOTAL_REPAY_AMOUNT,
                      '01',
                      '37',
                      P_LNACNT_LIMIT_SANCTION_DATE,
                      NULL,
                      'MIGRATION',
                      'MIG_R',
                      P_LNACNT_OPENING_DATE,
                      'MIG_R',
                      P_LNACNT_OPENING_DATE,
                      0,
                      0,
                      0,
                      0);
      ELSE
         UPDATE LNACRSHIST
            SET LNACRSH_EFF_DATE = P_LNACNT_OPENING_DATE,
                LNACRSH_EQU_INSTALLMENT = P_EQUAL_INSTALLMENT,
                LNACRSH_REPH_ON_AMT = V_TOTAL_REPAY_AMOUNT
          WHERE     LNACRSH_ENTITY_NUM = 1
                AND LNACRSH_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_ASSETCLSHIST;

  --------------------------------------

  <<INSERT_UPDATE_LNACRS>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACRS
       WHERE     LNACRS_ENTITY_NUM = 1
             AND LNACRS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;


      IF V_ROW_COUNT = 0
      THEN
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
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_OPENING_DATE,
                      P_EQUAL_INSTALLMENT,
                      V_TOTAL_REPAY_AMOUNT,
                      '01',
                      '37',
                      P_LNACNT_LIMIT_SANCTION_DATE,
                      'MIGRATION',
                      0,
                      0,
                      0,
                      0);
      ELSE
         UPDATE LNACRS
            SET LNACRS_LATEST_EFF_DATE = P_LNACNT_OPENING_DATE,
                LNACRS_EQU_INSTALLMENT = P_EQUAL_INSTALLMENT,
                LNACRS_REPH_ON_AMT = V_TOTAL_REPAY_AMOUNT,
                LNACRS_SANC_DATE = P_LNACNT_LIMIT_SANCTION_DATE
          WHERE     LNACRS_ENTITY_NUM = 1
                AND LNACRS_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END INSERT_UPDATE_LNACRS;

  -----------------------

  <<INSERT_UPDATE_LNACRSHDTL>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNACRSHDTL
       WHERE     LNACRSHDTL_ENTITY_NUM = 1
             AND LNACRSHDTL_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;


      IF V_ROW_COUNT = 0
      THEN
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
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_LNACNT_OPENING_DATE,
                      1,
                      V_CURRENCY,
                      P_LNACRSDTL_REPAY_AMT,
                      P_LNACRSDTL_REPAY_FREQ,
                      P_LNACRSDTL_REPAY_FROM_DATE,
                      P_TOTAL_NUMBER_INSTALLEMNT,
                      V_TOTAL_REPAY_AMOUNT);
      ELSE
         UPDATE LNACRSHDTL
            SET LNACRSHDTL_EFF_DATE = P_LNACNT_OPENING_DATE,
                LNACRSHDTL_REPAY_AMT = P_LNACRSDTL_REPAY_AMT,
                LNACRSHDTL_REPAY_FROM_DATE = P_LNACRSDTL_REPAY_FROM_DATE,
                LNACRSHDTL_REPAY_FREQ = P_LNACRSDTL_REPAY_FREQ,
                LNACRSHDTL_NUM_OF_INSTALLMENT = P_TOTAL_NUMBER_INSTALLEMNT,
                LNACRSHDTL_TOT_REPAY_AMT = V_TOTAL_REPAY_AMOUNT
          WHERE     LNACRSHDTL_ENTITY_NUM = 1
                AND LNACRSHDTL_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      --LNACRSHDTL_EFF_DATE, LNACRSHDTL_REPAY_AMT, LNACRSHDTL_REPAY_FREQ, LNACRSHDTL_REPAY_FROM_DATE, LNACRSHDTL_NUM_OF_INSTALLMENT, LNACRSHDTL_TOT_REPAY_AMT
      END IF;
   END INSERT_UPDATE_LNACRSHDTL;



  <<LNTOTINTDBMIG_INSERT>>
   BEGIN
      SELECT COUNT (*)
        INTO V_ROW_COUNT
        FROM LNTOTINTDBMIG
       WHERE     LNTOTINTDB_ENTITY_NUM = 1
             AND LNTOTINTDB_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;


      IF V_ROW_COUNT = 0
      THEN
         INSERT INTO LNTOTINTDBMIG (LNTOTINTDB_ENTITY_NUM,
                                    LNTOTINTDB_INTERNAL_ACNUM,
                                    LNTOTINTDB_TOT_INT_DB_AMT,
                                    LNTOTINTDB_TOT_PRIN_DB_AMT)
              VALUES (1,
                      V_INTERNAL_AC_NUM,
                      P_TOTAL_INT_DEBIT,
                      0);
      ELSE
         UPDATE LNTOTINTDBMIG
            SET LNTOTINTDB_TOT_INT_DB_AMT = P_TOTAL_INT_DEBIT
          WHERE     LNTOTINTDB_ENTITY_NUM = 1
                AND LNTOTINTDB_INTERNAL_ACNUM = V_INTERNAL_AC_NUM;
      END IF;
   END LNTOTINTDBMIG_INSERT;

   IF V_LONIA_INT_ACCRUED_AMOUNT IS NULL
   THEN
      V_LONIA_INT_ACCRUED_AMOUNT := 0;
   END IF;

   IF V_LONIA_INT_ACCRUED_AMOUNT <> 0
   THEN
     <<LOANIAMRR_DETAIL_UPDATE>>
      BEGIN
         --P_LONIA_INT_ACCRUED_AMOUNT
         --P_LNACNT_INT_ACCR_UPTO

         --- LOANIAMRR
         --- LOANIAMRRDTL


         SELECT COUNT (*)
           INTO V_ROW_COUNT
           FROM LOANIAMRR
          WHERE     LOANIAMRR_ENTITY_NUM = 1
                AND LOANIAMRR_BRN_CODE = P_BRANCH_CODE
                AND LOANIAMRR_ACNT_NUM = V_INTERNAL_AC_NUM
                AND LOANIAMRR_VALUE_DATE = P_LNACNT_INT_ACCR_UPTO;

         IF V_ROW_COUNT = 0
         THEN
            INSERT INTO LOANIAMRR (LOANIAMRR_ENTITY_NUM,
                                   LOANIAMRR_BRN_CODE,
                                   LOANIAMRR_ACNT_NUM,
                                   LOANIAMRR_VALUE_DATE,
                                   LOANIAMRR_ACCRUAL_DATE,
                                   LOANIAMRR_ACNT_CURR,
                                   LOANIAMRR_ACNT_BAL,
                                   LOANIAMRR_TOTAL_NEW_INT_AMT,
                                   LOANIAMRR_INT_ON_AMT,
                                   LOANIAMRR_OD_PORTION,
                                   LOANIAMRR_TOTAL_NEW_OD_INT_AMT,
                                   LOANIAMRR_INT_RATE,
                                   LOANIAMRR_SLAB_AMT,
                                   LOANIAMRR_OD_INT_RATE,
                                   LOANIAMRR_LIMIT,
                                   LOANIAMRR_DP,
                                   LOANIAMRR_INT_AMT,
                                   LOANIAMRR_INT_AMT_RND,
                                   LOANIAMRR_OD_INT_AMT,
                                   LOANIAMRR_OD_INT_AMT_RND,
                                   LOANIAMRR_NPA_STATUS,
                                   LOANIAMRR_NPA_AMT,
                                   LOANIAMRR_NPA_INT_POSTED_AMT,
                                   LOANIAMRR_ARR_INT_AMT)
                 VALUES (1,
                         P_BRANCH_CODE,
                         V_INTERNAL_AC_NUM,
                         P_LNACNT_INT_ACCR_UPTO,
                         P_LNACNT_INT_ACCR_UPTO,
                         'BDT',
                         0,
                         (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                         0,
                         0,
                         0,
                         P_LNACIRS_APPL_INT_RATE,
                         0,
                         0,
                         0,
                         0,
                         (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                         (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                         0,
                         0,
                         0,
                         0,
                         0,
                         0);
         ELSE
            UPDATE LOANIAMRR
               SET LOANIAMRR_TOTAL_NEW_INT_AMT =
                      (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                   LOANIAMRR_INT_AMT =
                      (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                   LOANIAMRR_INT_AMT_RND =
                      (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                   LOANIAMRR_INT_RATE = P_LNACIRS_APPL_INT_RATE
             WHERE     LOANIAMRR_ENTITY_NUM = 1
                   AND LOANIAMRR_BRN_CODE = P_BRANCH_CODE
                   AND LOANIAMRR_ACNT_NUM = V_INTERNAL_AC_NUM
                   AND LOANIAMRR_VALUE_DATE = P_LNACNT_INT_ACCR_UPTO;
         END IF;



         SELECT COUNT (*)
           INTO V_ROW_COUNT
           FROM LOANIAMRRDTL
          WHERE     LOANIAMRRDTL_ENTITY_NUM = 1
                AND LOANIAMRRDTL_BRN_CODE = P_BRANCH_CODE
                AND LOANIAMRRDTL_ACNT_NUM = V_INTERNAL_AC_NUM
                AND LOANIAMRRDTL_VALUE_DATE = P_LNACNT_INT_ACCR_UPTO;

         IF V_ROW_COUNT = 0
         THEN
            INSERT INTO LOANIAMRRDTL (LOANIAMRRDTL_ENTITY_NUM,
                                      LOANIAMRRDTL_BRN_CODE,
                                      LOANIAMRRDTL_ACNT_NUM,
                                      LOANIAMRRDTL_VALUE_DATE,
                                      LOANIAMRRDTL_ACCRUAL_DATE,
                                      LOANIAMRRDTL_SL_NUM,
                                      LOANIAMRRDTL_INT_RATE,
                                      LOANIAMRRDTL_UPTO_AMT,
                                      LOANIAMRRDTL_INT_AMT,
                                      LOANIAMRRDTL_INT_AMT_RND)
                 VALUES (1,
                         P_BRANCH_CODE,
                         V_INTERNAL_AC_NUM,
                         P_LNACNT_INT_ACCR_UPTO,
                         P_LNACNT_INT_ACCR_UPTO,
                         1,
                         P_LNACIRS_APPL_INT_RATE,
                         (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                         (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                         (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT));

            V_ACCRU_AMOUNT := (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT);
         ELSE
            UPDATE LOANIAMRRDTL
               SET LOANIAMRRDTL_UPTO_AMT =
                      (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                   LOANIAMRRDTL_INT_AMT =
                      (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                   LOANIAMRRDTL_INT_AMT_RND =
                      (-1) * ABS (V_LONIA_INT_ACCRUED_AMOUNT),
                   LOANIAMRRDTL_INT_RATE = P_LNACIRS_APPL_INT_RATE
             WHERE     LOANIAMRRDTL_ENTITY_NUM = 1
                   AND LOANIAMRRDTL_BRN_CODE = P_BRANCH_CODE
                   AND LOANIAMRRDTL_ACNT_NUM = V_INTERNAL_AC_NUM
                   AND LOANIAMRRDTL_VALUE_DATE = P_LNACNT_INT_ACCR_UPTO;


            SELECT LOANIAMRRDTL_INT_AMT_RND
              INTO V_ACCRU_AMOUNT
              FROM LOANIAMRRDTL
             WHERE     LOANIAMRRDTL_ENTITY_NUM = 1
                   AND LOANIAMRRDTL_BRN_CODE = P_BRANCH_CODE
                   AND LOANIAMRRDTL_ACNT_NUM = V_INTERNAL_AC_NUM
                   AND LOANIAMRRDTL_VALUE_DATE = P_LNACNT_INT_ACCR_UPTO;

            V_ACCRU_AMOUNT :=
               ABS (V_ACCRU_AMOUNT) - (V_LONIA_INT_ACCRUED_AMOUNT);
         END IF;
      END LOANIAMRR_DETAIL_UPDATE;
   END IF;

   SELECT LNPRDAC_INT_INCOME_GL, LNPRDAC_INT_ACCR_GL
     INTO V_INCOME_GL, V_ACCRU_GL
     FROM LNPRODACPM
    WHERE LNPRDAC_PROD_CODE = V_PRODUCT_CODE;


   IF V_ACCRU_AMOUNT < 0
   THEN
      BEGIN
         SP_AUTOPOST_TRANSACTION_MANUAL (
            P_BRANCH_CODE,                                      -- branch code
            V_ACCRU_GL,                                            -- debit gl
            V_INCOME_GL,                                          -- credit gl
            ABS (V_ACCRU_AMOUNT),                              -- debit amount
            ABS (V_ACCRU_AMOUNT),                             -- credit amount
            0,                                                -- debit account
            0,                                           -- DR contract number
            0,                                           -- CR contract number
            0,                                               -- credit account
            0,                                             -- advice num debit
            NULL,                                         -- advice date debit
            0,                                            -- advice num credit
            NULL,                                        -- advice date credit
            'BDT',                                                 -- currency
            '127.0.0.1',                                        -- terminal id
            'INTELECT',                                                -- user
            'ACCRUAL AMOUNT INSERT FOR ACCOUNT...  ' || P_LNACNT_ACNUM, -- narration
            V_BATCH_NUMBER                                     -- BATCH NUMBER
                          );
      END;
   ELSE
      BEGIN
         SP_AUTOPOST_TRANSACTION_MANUAL (
            P_BRANCH_CODE,                                      -- branch code
            V_INCOME_GL,                                          --  debit gl
            V_ACCRU_GL,                                            --credit gl
            ABS (V_ACCRU_AMOUNT),                              -- debit amount
            ABS (V_ACCRU_AMOUNT),                             -- credit amount
            0,                                                -- debit account
            0,                                           -- DR contract number
            0,                                           -- CR contract number
            0,                                               -- credit account
            0,                                             -- advice num debit
            NULL,                                         -- advice date debit
            0,                                            -- advice num credit
            NULL,                                        -- advice date credit
            'BDT',                                                 -- currency
            '127.0.0.1',                                        -- terminal id
            'INTELECT',                                                -- user
            'ACCRUAL AMOUNT INSERT FOR ACCOUNT...  ' || P_LNACNT_ACNUM, -- narration
            V_BATCH_NUMBER                                     -- BATCH NUMBER
                          );
      END;
   END IF;

   UPDATE TF_LOAN_DATA_UPDATE
      SET REMARKS = 'ACCRUAL BATCH ' || V_BATCH_NUMBER
    WHERE LNACNT_ACNUM = P_LNACNT_ACNUM;
END SP_TF_DATA_UPDATE;
/








CREATE OR REPLACE PROCEDURE SP_TF_LOAN_DATA_UPDATE
AS
BEGIN
   FOR IDX IN (SELECT BRANCH_CODE,
                      CLIENT_NUMBER,
                      CUSTOMER_NAME,
                      LNACNT_ACNUM,
                      PRODUCT_CODE,
                      ACCOUNT_TYPE,
                      ACCOUNT_SUB_TYPE,
                      CURRENCY,
                      LNACNT_DISB_TYPE,
                      LNACIRS_APPL_INT_RATE,
                      LNACNT_SANCTION_AMT,
                      LNACNT_DP_REQD,
                      DP_DATE,
                      DP_AMOUNT,
                      LNACNT_OPENING_DATE,
                      LNACNT_LIMIT_SANCTION_DATE,
                      LNACDSDTL_DISB_AMOUNT,
                      LNACDSDTL_DISB_DATE,
                      LNACNT_OUTSTANDING_BALANCE,
                      LNACNT_PRIN_OS,
                      LNACNT_INT_OS,
                      LNACNT_CHG_OS,
                      LNACNT_INT_ACCR_UPTO,
                      LNACNT_INT_APPLIED_UPTO_DATE,
                      LNACNT_REVOLVING_LIMIT,
                      LNACNT_SEC_AMT_REQD,
                      LNACNT_DATE_OF_NPA,
                      ASSETCLSH_ASSET_CODE,
                      LNACNT_TOT_SUSP_BALANCE,
                      LNACNT_INT_SUSP_BALANCE,
                      LNACNT_CHG_SUSP_BALANCE,
                      REPAYMENT_SCHEDULE_REQUIRED,
                      TOTAL_INT_DEBIT,
                      LNACNT_SEGMENT_CODE,
                      LNACNT_PURPOSE_CODE,
                      LNACNT_INDUS_CODE,
                      LNACNT_SUB_INDUS_CODE,
                      LNACRSDTL_REPAY_FREQ,
                      LNACRSDTL_REPAY_FROM_DATE,
                      TOTAL_NUMBER_INSTALLEMNT,
                      LNACRSDTL_REPAY_AMT,
                      ECONOMIC_PURPOSE_CODE,
                      LNACNT_LIMIT_AVL_ON_DATE,
                      EQUAL_INSTALLMENT,
                      LNACNT_CL_REPORT_CODE,
                      LONIA_INTEREST_ACCRUED_AMOUNT,
                      TOTAL_RECOVERY_AMOUNT,
                      PRINCIPAL_RECOVERY_AMOUNT,
                      INTEREST_RECOVERY_AMOUNT,
                      CHARGES_RECOVERY_AMOUNT,
                      LC_AMOUNT,
                      LC_NUMBER,
                      LC_CURRENCY,
                      LC_DATE,
                      LNACNT_EXPIRY_DATE
                 FROM TF_LOAN_DATA_UPDATE
                WHERE REMARKS IS NULL)
   LOOP
      SP_TF_DATA_UPDATE (IDX.BRANCH_CODE,
                         IDX.CLIENT_NUMBER,
                         IDX.CUSTOMER_NAME,
                         IDX.LNACNT_ACNUM,
                         IDX.PRODUCT_CODE,
                         IDX.ACCOUNT_TYPE,
                         IDX.ACCOUNT_SUB_TYPE,
                         IDX.CURRENCY,
                         IDX.LNACNT_DISB_TYPE,
                         IDX.LNACIRS_APPL_INT_RATE,
                         IDX.LNACNT_SANCTION_AMT,
                         IDX.LNACNT_DP_REQD,
                         IDX.DP_DATE,
                         IDX.DP_AMOUNT,
                         IDX.LNACNT_OPENING_DATE,
                         IDX.LNACNT_LIMIT_SANCTION_DATE,
                         IDX.LNACDSDTL_DISB_AMOUNT,
                         IDX.LNACDSDTL_DISB_DATE,
                         IDX.LNACNT_OUTSTANDING_BALANCE,
                         IDX.LNACNT_PRIN_OS,
                         IDX.LNACNT_INT_OS,
                         IDX.LNACNT_CHG_OS,
                         IDX.LNACNT_INT_ACCR_UPTO,
                         IDX.LNACNT_INT_APPLIED_UPTO_DATE,
                         IDX.LNACNT_REVOLVING_LIMIT,
                         IDX.LNACNT_SEC_AMT_REQD,
                         IDX.LNACNT_DATE_OF_NPA,
                         IDX.ASSETCLSH_ASSET_CODE,
                         IDX.LNACNT_TOT_SUSP_BALANCE,
                         IDX.LNACNT_INT_SUSP_BALANCE,
                         IDX.LNACNT_CHG_SUSP_BALANCE,
                         IDX.REPAYMENT_SCHEDULE_REQUIRED,
                         IDX.TOTAL_INT_DEBIT,
                         IDX.LNACNT_SEGMENT_CODE,
                         IDX.LNACNT_PURPOSE_CODE,
                         IDX.LNACNT_INDUS_CODE,
                         IDX.LNACNT_SUB_INDUS_CODE,
                         IDX.LNACRSDTL_REPAY_FREQ,
                         IDX.LNACRSDTL_REPAY_FROM_DATE,
                         IDX.TOTAL_NUMBER_INSTALLEMNT,
                         IDX.LNACRSDTL_REPAY_AMT,
                         IDX.ECONOMIC_PURPOSE_CODE,
                         IDX.LNACNT_LIMIT_AVL_ON_DATE,
                         IDX.EQUAL_INSTALLMENT,
                         IDX.LNACNT_CL_REPORT_CODE,
                         IDX.LONIA_INTEREST_ACCRUED_AMOUNT,
                         IDX.TOTAL_RECOVERY_AMOUNT,
                         IDX.PRINCIPAL_RECOVERY_AMOUNT,
                         IDX.INTEREST_RECOVERY_AMOUNT,
                         IDX.CHARGES_RECOVERY_AMOUNT,
                         IDX.LC_AMOUNT,
                         IDX.LC_NUMBER,
                         IDX.LC_CURRENCY,
                         IDX.LC_DATE,
                         IDX.LNACNT_EXPIRY_DATE);

      UPDATE TF_LOAN_DATA_UPDATE
         SET REMARKS = REMARKS ||  '   DONE'
       WHERE LNACNT_ACNUM = IDX.LNACNT_ACNUM;

      COMMIT;
   END LOOP;
END SP_TF_LOAN_DATA_UPDATE;
/








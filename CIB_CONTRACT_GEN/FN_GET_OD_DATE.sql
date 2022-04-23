CREATE OR REPLACE FUNCTION FN_GET_OD_DATE (V_ENTITY_NUM       IN NUMBER,
                                          P_INTERNAL_ACNUM   IN NUMBER,
                                          P_ASON_DATE        IN DATE,
                                          P_CURR_BUS_DATE    IN DATE)
   RETURN DATE
IS
   W_DUMMY_V                     VARCHAR2 (10);
   W_DUMMY_W                     VARCHAR2(10);
   W_DUMMY_N                     NUMBER;
   W_AMT_OD                      NUMBER (18, 3);
   W_OD_DATE                     DATE ;
   W_ERR_MSG                     VARCHAR2 (100);

   V_ACNTS_CURR_CODE             VARCHAR2 (3) ;
   W_OPENING_DATE                DATE;
   W_MIG_DATE                    DATE;
   V_ACNTS_PROD_CODE             NUMBER (4);
   V_LNPRD_INT_RECOVERY_OPTION   CHAR (1);
   W_PRODUCT_FOR_RUN_ACS         VARCHAR (1) ;
   W_LIMIT_EXPIRY_DATE           DATE;
   W_ACASLL_CLINET_NUM           NUMBER (12);
   W_ACASLL_LIMITLINE_NUM        NUMBER (12);
   V_SQL_ERROR VARCHAR2(1000);
   C_ASON_DATE VARCHAR2(100);
   C_CURR_BUS_DATE VARCHAR2(100);

BEGIN
   SELECT ACNTS_CURR_CODE,
          ACNTS_OPENING_DATE,
          MIG_END_DATE,
          ACNTS_PROD_CODE,
          LNPRD_INT_RECOVERY_OPTION,
          PRODUCT_FOR_RUN_ACS,
          (SELECT LMTLINE_LIMIT_EXPIRY_DATE
             FROM LIMITLINE, ACASLLDTL
            WHERE     LMTLINE_ENTITY_NUM = V_ENTITY_NUM
                  AND ACASLLDTL_ENTITY_NUM = V_ENTITY_NUM
                  AND LMTLINE_CLIENT_CODE = ACASLLDTL_CLIENT_NUM
                  AND LMTLINE_NUM = ACASLLDTL_LIMIT_LINE_NUM
                  AND ACASLLDTL_INTERNAL_ACNUM = ACNTS_INTERNAL_ACNUM),
          ACNTS_CLIENT_NUM,
          NVL((SELECT ACASLLDTL_LIMIT_LINE_NUM
             FROM ACASLLDTL
            WHERE     ACASLLDTL_ENTITY_NUM = 1
                  AND ACASLLDTL_INTERNAL_ACNUM = ACNTS_INTERNAL_ACNUM), 0)
     INTO V_ACNTS_CURR_CODE,
          W_OPENING_DATE,
          W_MIG_DATE,
          V_ACNTS_PROD_CODE,
          V_LNPRD_INT_RECOVERY_OPTION,
          W_PRODUCT_FOR_RUN_ACS,
          W_LIMIT_EXPIRY_DATE,
          W_ACASLL_CLINET_NUM,
          W_ACASLL_LIMITLINE_NUM
     FROM ACNTS,
          PRODUCTS,
          LNPRODPM,
          MIG_DETAIL
    WHERE     ACNTS_ENTITY_NUM = V_ENTITY_NUM
          AND ACNTS_INTERNAL_ACNUM = P_INTERNAL_ACNUM
          AND ACNTS_PROD_CODE = PRODUCT_CODE
          AND LNPRD_PROD_CODE = PRODUCT_CODE
          AND BRANCH_CODE = ACNTS_BRN_CODE;
          
          
          C_ASON_DATE:= TO_CHAR(P_ASON_DATE, 'DD-MM-YYYY');
          C_CURR_BUS_DATE := TO_CHAR(P_CURR_BUS_DATE,'DD-MM-YYYY') ;

   PKG_LNOVERDUE.SP_LNOVERDUE (V_ENTITY_NUM,
                               P_INTERNAL_ACNUM,
                               C_ASON_DATE,
                               C_CURR_BUS_DATE,
                               W_ERR_MSG,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_AMT_OD,
                               W_DUMMY_W,
                               W_DUMMY_N,
                               W_DUMMY_V,
                               W_DUMMY_N,
                               W_DUMMY_V,
                               W_DUMMY_N,
                               W_DUMMY_V,
                               --- Extra added
                               V_ACNTS_CURR_CODE,
                               W_OPENING_DATE,
                               W_MIG_DATE,
                               V_ACNTS_PROD_CODE,
                               V_LNPRD_INT_RECOVERY_OPTION,
                               W_PRODUCT_FOR_RUN_ACS,
                               W_LIMIT_EXPIRY_DATE,
                               W_ACASLL_CLINET_NUM,
                               W_ACASLL_LIMITLINE_NUM,
                               1);
   W_OD_DATE:= TO_DATE(W_DUMMY_W, 'DD-MM-YYYY');
   RETURN W_OD_DATE;
EXCEPTION
   WHEN OTHERS
   THEN V_SQL_ERROR := SQLERRM ;
      RETURN NULL;
END FN_GET_OD_DATE;
/

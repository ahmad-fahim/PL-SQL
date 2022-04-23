CREATE OR REPLACE PACKAGE PKG_CL_DATE_VERIFY IS

  TYPE REC_TYPE4 IS RECORD(
    BRN_CODE_TITLE VARCHAR2(5),
    BRN_NAME_TITLE VARCHAR2(100),
    BRN_CODE           VARCHAR2(5),
    BRN_NAME           VARCHAR2(100),
    PROD_CODE          VARCHAR2(10),
    PROD_NAME          VARCHAR2(100),
    AC_TYPE            ACNTS.ACNTS_AC_TYPE%TYPE,
    AC_SUB_TYPE        ACNTS.ACNTS_AC_SUB_TYPE%TYPE,
    ACC_NO             VARCHAR2(20),
    ACC_NAME           VARCHAR2(100),
    B_MIG_INT_DEBT     NUMBER(18, 3),
    B_MIG_CHG_DEBT     NUMBER(18, 3),
    ACNTS_OPENING_DATE VARCHAR2(20),
    SANC_RESCHE_DATE   VARCHAR2(20),
    SANC_RESCHE_AMT    NUMBER(18, 3),
    DISBURSE_DATE VARCHAR2(20),
    DISBURSE_AMT  NUMBER(18, 3),
    REPAY_START_DATE  VARCHAR2(20),
    REPAY_FREQ        CHAR(1),
    INSTALL_SIZE      NUMBER(18, 3),
    NO_OF_INSTALLMENT NUMBER,
    EXPIRY_DATE     VARCHAR2(20),
    SEC_AMT         NUMBER(18, 3),
    SEC_CODE        VARCHAR2(1000),
    CL_CODE         VARCHAR2(7),
    SEGMENT_CODE    VARCHAR2(20),
    ECO_PURP_CODE   VARCHAR2(20),
    SME_CODE        VARCHAR2(20),
    SEC_NUM         VARCHAR2(1000),
    REMARKS         VARCHAR2(1000),
    OUTSTANDING_BAL NUMBER(18, 3));

  TYPE REC_TAB4 IS TABLE OF REC_TYPE4;

  FUNCTION GET_BRANCH_WISE(P_BRN_CODE  NUMBER,
                           P_LOAN_TYPE PRODUCTS.PRODUCT_FOR_RUN_ACS%TYPE,
                           P_ASON_DATE DATE ) ---- 1 for continious loan, 0 for term loan
   RETURN REC_TAB4
    PIPELINED;
  --RETURN VARCHAR2;

END PKG_CL_DATE_VERIFY;
/






CREATE OR REPLACE PACKAGE BODY PKG_CL_DATE_VERIFY IS
  TEMP_DATA4         PKG_CL_DATE_VERIFY.REC_TYPE4;
  V_EXP_DATE         DATE;
  V_LIMIT_RESCH_DATE DATE;
  V_LIMIT_RESCH_AMT  NUMBER(18, 3);
  V_DISB_AMT         NUMBER(18, 3);
  V_LIMIT_LINE_NUM   NUMBER(8);
  W_LIM_CLIENT       NUMBER(8);

  --Reschedule Account.
  V_IS_RESCHEDULE_ACC    CHAR(1);
  V_RESCHEDULE_AMT       NUMBER(18, 3);
  V_RESCHEDULE_SANC_DATE DATE;
  V_DISBURSE_DATE        DATE;
  ---    LAD
  V_IS_LAD_ACC        BOOLEAN;
  W_INTERNAL_ACNUM    VARCHAR2(20);
  W_ASON_DATE         DATE := '09-SEP-2015';
  W_CBD               DATE := '09-SEP-2015';
  W_TOT_SEC_AMT_AC    NUMBER(18, 3);
  W_TOT_SEC_AMT_BC    NUMBER(18, 3);
  W_SEC_NUM           VARCHAR2(1000);
  W_SEC_AMT_ACNT_CURR NUMBER(18, 3);

  W_SEC_TYPE      SECRCPT.SECRCPT_SEC_TYPE%TYPE;
  W_SEC_CURR_CODE SECRCPT.SECRCPT_CURR_CODE%TYPE;
  W_SECURED_VALUE SECRCPT.SECRCPT_SECURED_VALUE%TYPE;

  W_SEC_TYPE_STR VARCHAR2(1000);
  W_SEC_NUM_STR  VARCHAR2(1000);
  W_REMARKS      VARCHAR2(500);

  TYPE REC_BRN_WISE_TEMP IS RECORD(
    ACNTS_BRN_CODE       ACNTS.ACNTS_BRN_CODE%TYPE,
    MBRN_NAME            MBRN.MBRN_NAME%TYPE,
    PRODUCT_CODE         PRODUCTS.PRODUCT_CODE%TYPE,
    PRODUCT_NAME         PRODUCTS.PRODUCT_NAME%TYPE,
    ACNTS_AC_TYPE        ACNTS.ACNTS_AC_TYPE%TYPE,
    ACNTS_AC_SUB_TYPE    ACNTS.ACNTS_AC_SUB_TYPE%TYPE,
    ACNTS_INTERNAL_ACNUM ACNTS.ACNTS_INTERNAL_ACNUM%TYPE,
    ACNTS_AC_NAME1       ACNTS.ACNTS_AC_NAME1%TYPE,
    ACNTS_CURR_CODE      ACNTS.ACNTS_CURR_CODE%TYPE ,
    ACNTS_OPENING_DATE   ACNTS.ACNTS_OPENING_DATE%TYPE,
    ACNTS_CLIENT_NUM     ACNTS.ACNTS_CLIENT_NUM%TYPE,
    BEF_MIG_CHG_DEBIT    LNTOTINTDBMIG.LNTOTINTDB_TOT_INT_DB_AMT%TYPE,
    BEF_MIG_INT_DEBIT    LNTOTINTDBMIG.LNTOTINTDB_TOT_INT_DB_AMT%TYPE);

  TYPE REC_BRN_WISE IS TABLE OF REC_BRN_WISE_TEMP INDEX BY PLS_INTEGER;

  T_REC_BRN_WISE REC_BRN_WISE;

  -- ALAM
  FUNCTION GET_LAD_SECURED_VALUE RETURN NUMBER IS
    W_PROD_CODE VARCHAR2(10) := '';
  
    W_DEP_ACC        VARCHAR2(20) := '';
    W_ACC_BAL        NUMBER(18, 3) := 0;
    W_SEC_VALUE      NUMBER(18, 3) := 0;
    W_CLIENT_NUM     VARCHAR2(10) := '';
    W_LIMIT_LINE_NO  NUMBER := 0;
    W_CNT            NUMBER := 0;
    W_ASSIGN_PERC    NUMBER;
    W_SEC_NUM        NUMBER;
    W_BASE_CURR_CODE VARCHAR2(4);
  BEGIN
    V_IS_LAD_ACC     := FALSE;
    W_CNT            := 0;
    W_BASE_CURR_CODE := 'BDT';
  
    SELECT ACNTS_PROD_CODE
      INTO W_PROD_CODE
      FROM ACNTS A
     WHERE A.ACNTS_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
  
    SELECT COUNT(*)
      INTO W_CNT
      FROM LADPRODMAP LNMAP
     WHERE LNMAP.LADPRODMAP_PROD_CODE = W_PROD_CODE;
  
    --DBMS_OUTPUT.PUT_LINE(W_PROD_CODE || '  W_CNT = ' || W_CNT);
  
    IF W_CNT > 0 THEN
      V_IS_LAD_ACC := TRUE;
      <<DEP_ACC_AMT>>
      BEGIN
      
        FOR DEP_ACC IN (SELECT LADDTL_DEP_ACNT_NUM
                          FROM LADACNTDTL LNDTL
                         WHERE LNDTL.LADDTL_INTERNAL_ACNUM =
                               W_INTERNAL_ACNUM) LOOP
          W_ACC_BAL := W_ACC_BAL + FN_GET_ASON_ACBAL(1,
                                                     DEP_ACC.LADDTL_DEP_ACNT_NUM,
                                                     W_BASE_CURR_CODE,
                                                     W_ASON_DATE,
                                                     W_CBD);
        END LOOP;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          W_DEP_ACC := 0;
      END DEP_ACC_AMT;
    
    ELSE
      W_ACC_BAL    := 0;
      V_IS_LAD_ACC := FALSE;
    END IF;
    RETURN W_ACC_BAL;
  END GET_LAD_SECURED_VALUE;
  --*****

  PROCEDURE GET_TOT_SEC_AMT_CBD IS
    V_LAD_SEC_AMT NUMBER(18, 3);
  BEGIN
    W_SEC_TYPE_STR   := '';
    W_SEC_NUM_STR    := '';
    W_TOT_SEC_AMT_AC := 0;
    V_LAD_SEC_AMT    := GET_LAD_SECURED_VALUE;
    IF V_IS_LAD_ACC THEN
      W_SEC_TYPE_STR   := 'LAD';
      W_TOT_SEC_AMT_AC := V_LAD_SEC_AMT;
    
    ELSE
    
      FOR IDX_REC_SECBAL IN (SELECT SECAGMTBAL_ASSIGN_PERC,
                                    SECAGMTBAL_SEC_NUM
                               FROM SECASSIGNMTBAL
                              WHERE SECAGMTBAL_ENTITY_NUM = 1
                                AND SECAGMTBAL_CLIENT_NUM = W_LIM_CLIENT
                                AND SECAGMTBAL_LIMIT_LINE_NUM =
                                    V_LIMIT_LINE_NUM) LOOP
      
        W_SEC_NUM := IDX_REC_SECBAL.SECAGMTBAL_SEC_NUM;
      
        <<FETCH_SECRCPT>>
        BEGIN
          SELECT SECRCPT_SEC_TYPE, SECRCPT_CURR_CODE, SECRCPT_SECURED_VALUE
            INTO W_SEC_TYPE, W_SEC_CURR_CODE, W_SECURED_VALUE
            FROM SECRCPT
           WHERE SECRCPT_ENTITY_NUM = 1
             AND SECRCPT_SECURITY_NUM = W_SEC_NUM;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            W_SECURED_VALUE := 0;
        END FETCH_SECRCPT;
      
        W_SEC_AMT_ACNT_CURR := W_SECURED_VALUE;
        W_TOT_SEC_AMT_AC    := W_TOT_SEC_AMT_AC + W_SEC_AMT_ACNT_CURR;
        W_SEC_TYPE_STR      := W_SEC_TYPE_STR || '  ' || W_SEC_TYPE ||
                               ' , ';
        W_SEC_NUM_STR       := W_SEC_NUM_STR --|| '  ' || W_SEC_NUM || ' , '
         ;
      
      END LOOP;
    END IF;
  END GET_TOT_SEC_AMT_CBD;

  --

  FUNCTION GET_BRANCH_WISE(P_BRN_CODE  NUMBER,
                           P_LOAN_TYPE PRODUCTS.PRODUCT_FOR_RUN_ACS%TYPE,
                           P_ASON_DATE DATE ) ---- 1 for continious loan, 0 for term loan
   RETURN REC_TAB4
    PIPELINED
  --RETURN VARCHAR2
   IS
    V_CL_MIS_CODE VARCHAR2(20);
    V_CL_ECO_CODE VARCHAR2(20);
    V_CL_SME_CODE VARCHAR2(20);
    V_CL_SEG_CODE VARCHAR2(20);
  
    V_LNACRSDTL_REPAY_FROM_DATE    LNACRSDTL.LNACRSDTL_REPAY_FROM_DATE%TYPE;
    V_LNACRSDTL_REPAY_FREQ         LNACRSDTL.LNACRSDTL_REPAY_FREQ%TYPE;
    V_LNACRSDTL_REPAY_AMT          LNACRSDTL.LNACRSDTL_REPAY_AMT%TYPE;
    V_LNACRSDTL_NUM_OF_INSTALLMENT LNACRSDTL.LNACRSDTL_NUM_OF_INSTALLMENT%TYPE;
    CN                             INTEGER;
    V_PREV_BRN_CODE                MBRN.MBRN_CODE%TYPE;
  
    V_SQL VARCHAR2(2000);
    V_CBD DATE ;
  
  BEGIN
  SELECT MN_CURR_BUSINESS_DATE  INTO V_CBD FROM MAINCONT ;
    V_PREV_BRN_CODE := 0;
  
    V_SQL := 'SELECT 
       A.ACNTS_BRN_CODE,
       M.MBRN_NAME,
       P.PRODUCT_CODE,
       P.PRODUCT_NAME,
       A.ACNTS_AC_TYPE,
       A.ACNTS_AC_SUB_TYPE,
       A.ACNTS_INTERNAL_ACNUM,
       A.ACNTS_AC_NAME1,
       A.ACNTS_CURR_CODE,
       A.ACNTS_OPENING_DATE,
       A.ACNTS_CLIENT_NUM,
       0 BEF_MIG_CHG_DEBIT,
       (SELECT ABS(NVL(L.LNTOTINTDB_TOT_INT_DB_AMT, 0))
          FROM LNTOTINTDBMIG L
         WHERE L.LNTOTINTDB_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM) BEF_MIG_INT_DEBIT
  FROM LOANACNTS L, ACNTS A, PRODUCTS P, MBRN M, MIG_DETAIL M1
 WHERE L.LNACNT_ENTITY_NUM = A.ACNTS_ENTITY_NUM
   AND A.ACNTS_ENTITY_NUM = 1
   AND M.MBRN_CODE = M1.BRANCH_CODE
   AND L.LNACNT_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
   AND M.MBRN_CODE = A.ACNTS_BRN_CODE
   AND P.PRODUCT_CODE = A.ACNTS_PROD_CODE';
  
    IF P_BRN_CODE <> 0 THEN
      V_SQL := V_SQL || ' AND A.ACNTS_BRN_CODE = '||  P_BRN_CODE;
    END IF;
  
    V_SQL := V_SQL || '
  AND P.PRODUCT_FOR_LOANS = 1
   AND P.PRODUCT_FOR_RUN_ACS = ' || P_LOAN_TYPE  || '
   AND A.ACNTS_CLOSURE_DATE IS NULL
 ORDER BY A.ACNTS_BRN_CODE, P.PRODUCT_CODE';
 
 
 --INSERT INTO DATA_TEST VALUES(V_SQL);
--COMMIT ;
  
    EXECUTE IMMEDIATE V_SQL BULK COLLECT
      INTO T_REC_BRN_WISE;
  
    FOR RPT IN 1 .. T_REC_BRN_WISE.COUNT LOOP
    
      IF V_PREV_BRN_CODE <> T_REC_BRN_WISE(RPT).ACNTS_BRN_CODE THEN
        --DBMS_OUTPUT.PUT_LINE(RPT.ACNTS_BRN_CODE);
        -- Note: Reset
      
        TEMP_DATA4.BRN_CODE           := '';
        TEMP_DATA4.BRN_NAME           := '';
        TEMP_DATA4.PROD_CODE          := '';
        TEMP_DATA4.PROD_NAME          := '';
        TEMP_DATA4.AC_TYPE            := '';
        TEMP_DATA4.AC_SUB_TYPE        := '';
        TEMP_DATA4.ACC_NO             := '';
        TEMP_DATA4.ACC_NAME           := '';
        TEMP_DATA4.B_MIG_INT_DEBT     := '';
        TEMP_DATA4.B_MIG_CHG_DEBT     := '';
        TEMP_DATA4.ACNTS_OPENING_DATE := '';
        TEMP_DATA4.REPAY_START_DATE   := '';
        TEMP_DATA4.REPAY_FREQ         := '';
        TEMP_DATA4.INSTALL_SIZE       := '';
        TEMP_DATA4.NO_OF_INSTALLMENT  := '';
        TEMP_DATA4.SANC_RESCHE_DATE   := '';
        TEMP_DATA4.SANC_RESCHE_AMT    := '';
        TEMP_DATA4.DISBURSE_DATE      := '';
        TEMP_DATA4.DISBURSE_AMT       := '';
        TEMP_DATA4.EXPIRY_DATE        := '';
        TEMP_DATA4.SEC_AMT            := '';
        TEMP_DATA4.SEC_CODE           := '';
        TEMP_DATA4.ECO_PURP_CODE      := '';
        TEMP_DATA4.SME_CODE           := '';
        TEMP_DATA4.SEGMENT_CODE       := '';
        TEMP_DATA4.CL_CODE            := '';
      
        TEMP_DATA4.SEC_NUM         := '';
        TEMP_DATA4.REMARKS         := '';
        TEMP_DATA4.OUTSTANDING_BAL := '';
        /* Not Necessary For Extra Space*/
        /* IF V_PREV_BRN_CODE > 0 THEN
          FOR I IN 1 .. 20 LOOP
            PIPE ROW(TEMP_DATA4);
          END LOOP;
        END IF;*/
      
        --TEMP_DATA4.BRN_CODE_TITLE := RPT.ACNTS_BRN_CODE;
        --  TEMP_DATA4.BRN_NAME_TITLE := RPT.MBRN_NAME;
      
        -- PIPE ROW(TEMP_DATA4);
        V_PREV_BRN_CODE := T_REC_BRN_WISE(RPT).ACNTS_BRN_CODE;
      
        TEMP_DATA4.BRN_CODE_TITLE := '';
        TEMP_DATA4.BRN_NAME_TITLE := '';
      
      END IF;
      CN := 0;
      SELECT COUNT(*)
        INTO CN
        FROM LNWRTOFF
       WHERE LNWRTOFF_ACNT_NUM = T_REC_BRN_WISE(RPT).ACNTS_INTERNAL_ACNUM;
    
      IF CN > 0 THEN
        CONTINUE;
      END IF;
    
      W_LIM_CLIENT     := T_REC_BRN_WISE(RPT).ACNTS_CLIENT_NUM;
      W_INTERNAL_ACNUM := T_REC_BRN_WISE(RPT).ACNTS_INTERNAL_ACNUM;
    
      TEMP_DATA4.BRN_CODE    := T_REC_BRN_WISE(RPT).ACNTS_BRN_CODE;
      TEMP_DATA4.BRN_NAME    := T_REC_BRN_WISE(RPT).MBRN_NAME;
      TEMP_DATA4.PROD_CODE   := T_REC_BRN_WISE(RPT).PRODUCT_CODE;
      TEMP_DATA4.PROD_NAME   := T_REC_BRN_WISE(RPT).PRODUCT_NAME;
      TEMP_DATA4.AC_TYPE     := T_REC_BRN_WISE(RPT).ACNTS_AC_TYPE;
      TEMP_DATA4.AC_SUB_TYPE := T_REC_BRN_WISE(RPT).ACNTS_AC_SUB_TYPE;
    
      TEMP_DATA4.ACC_NO             := FACNO(1,
                                             T_REC_BRN_WISE(RPT)
                                             .ACNTS_INTERNAL_ACNUM);
      TEMP_DATA4.ACC_NAME           := T_REC_BRN_WISE(RPT).ACNTS_AC_NAME1;
      TEMP_DATA4.ACNTS_OPENING_DATE := T_REC_BRN_WISE(RPT)
                                       .ACNTS_OPENING_DATE;
      TEMP_DATA4.B_MIG_INT_DEBT     := T_REC_BRN_WISE(RPT).BEF_MIG_INT_DEBIT;
      TEMP_DATA4.B_MIG_CHG_DEBT     := 0;
    
      -- LIMIT LINE
      BEGIN
        SELECT LMTLINE_DATE_OF_SANCTION,
               LMTLINE_SANCTION_AMT,
               LMTLINE_LIMIT_EXPIRY_DATE,
               LMTLINE_NUM
          INTO V_LIMIT_RESCH_DATE,
               V_LIMIT_RESCH_AMT,
               V_EXP_DATE,
               V_LIMIT_LINE_NUM
          FROM LIMITLINE
         WHERE LMTLINE_CLIENT_CODE = T_REC_BRN_WISE(RPT).ACNTS_CLIENT_NUM
           AND LIMITLINE.LMTLINE_NUM =
               (SELECT ACASLLDTL.ACASLLDTL_LIMIT_LINE_NUM
                  FROM ACASLLDTL
                 WHERE ACASLLDTL_INTERNAL_ACNUM = T_REC_BRN_WISE(RPT)
                      .ACNTS_INTERNAL_ACNUM);
      
        TEMP_DATA4.EXPIRY_DATE := TO_CHAR(V_EXP_DATE, 'MM/DD/YYYY');
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          TEMP_DATA4.EXPIRY_DATE := ' ';
          V_LIMIT_RESCH_DATE     := NULL;
          V_LIMIT_RESCH_AMT      := 0;
          V_EXP_DATE             := NULL;
          V_LIMIT_LINE_NUM       := NULL;
      END;
      -- END
      -- SANC
      BEGIN
        SELECT LNACRS_REPH_ON_AMT,
               LNACRS_REPHASEMENT_ENTRY,
               LNACRS_SANC_DATE
          INTO V_RESCHEDULE_AMT,
               V_IS_RESCHEDULE_ACC,
               V_RESCHEDULE_SANC_DATE
          FROM LNACRS
         WHERE LNACRS.LNACRS_INTERNAL_ACNUM = T_REC_BRN_WISE(RPT)
              .ACNTS_INTERNAL_ACNUM;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_RESCHEDULE_AMT       := NULL;
          V_IS_RESCHEDULE_ACC    := NULL;
          V_RESCHEDULE_SANC_DATE := NULL;
      END;
      -- DISBURSE
      BEGIN
        SELECT LLACNTOS_LIMIT_CURR_DISB_MADE
          INTO V_DISB_AMT
          FROM LLACNTOS
         WHERE LLACNTOS_ENTITY_NUM = 1
           AND LLACNTOS_CLIENT_CODE = T_REC_BRN_WISE(RPT).ACNTS_CLIENT_NUM
           AND LLACNTOS_LIMIT_LINE_NUM = V_LIMIT_LINE_NUM
           AND LLACNTOS_CLIENT_ACNUM = T_REC_BRN_WISE(RPT)
              .ACNTS_INTERNAL_ACNUM;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_DISB_AMT := NULL;
      END;
    
      SELECT MIN(D.LNACDISB_DISB_ON)
        INTO V_DISBURSE_DATE
        FROM LNACDISB D
       WHERE --D.LNACDISB_AUTH_BY LIKE '%MIG%' AND
       D.LNACDISB_INTERNAL_ACNUM = T_REC_BRN_WISE(RPT).ACNTS_INTERNAL_ACNUM;
    
      IF V_DISBURSE_DATE IS NULL THEN
        BEGIN
          --DBMS_OUTPUT.PUT_LINE('Inside Exception.');
          SELECT A.ACNTINWTRF_DATE_OF_TRANSFR
            INTO V_DISBURSE_DATE
            FROM ACNTINWTRF A
           WHERE A.ACNTINWTRF_DEP_AC_NUM = T_REC_BRN_WISE(RPT)
                .ACNTS_INTERNAL_ACNUM;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            V_DISBURSE_DATE := NULL;
        END;
      END IF;
    
      IF V_IS_RESCHEDULE_ACC = 1 THEN
        TEMP_DATA4.SANC_RESCHE_AMT  := V_RESCHEDULE_AMT;
        TEMP_DATA4.SANC_RESCHE_DATE := TO_CHAR(V_RESCHEDULE_SANC_DATE,
                                               'MM/DD/YYYY');
        TEMP_DATA4.DISBURSE_AMT     := V_RESCHEDULE_AMT;
        W_REMARKS                   := 'Reschedule on INTELECT';
      ELSE
        TEMP_DATA4.SANC_RESCHE_AMT  := V_LIMIT_RESCH_AMT;
        TEMP_DATA4.SANC_RESCHE_DATE := TO_CHAR(V_LIMIT_RESCH_DATE,
                                               'MM/DD/YYYY');
      
        TEMP_DATA4.DISBURSE_DATE := TO_CHAR(V_DISBURSE_DATE, 'MM/DD/YYYY');
      
        TEMP_DATA4.DISBURSE_AMT := V_DISB_AMT;
      
        -- DBMS_OUTPUT.PUT_LINE(RPT.ACNTS_INTERNAL_ACNUM  || ' = ' || V_DISB_AMT);
      
      END IF;
    
      --=
    
      BEGIN
        SELECT LNACRSDTL_REPAY_FROM_DATE,
               LNACRSDTL_REPAY_FREQ,
               LNACRSDTL_REPAY_AMT,
               LNACRSDTL_NUM_OF_INSTALLMENT
          INTO V_LNACRSDTL_REPAY_FROM_DATE,
               V_LNACRSDTL_REPAY_FREQ,
               V_LNACRSDTL_REPAY_AMT,
               V_LNACRSDTL_NUM_OF_INSTALLMENT
          FROM LNACRSDTL
         WHERE LNACRSDTL.LNACRSDTL_INTERNAL_ACNUM = W_INTERNAL_ACNUM;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_LNACRSDTL_REPAY_FROM_DATE    := NULL;
          V_LNACRSDTL_REPAY_FREQ         := NULL;
          V_LNACRSDTL_REPAY_AMT          := NULL;
          V_LNACRSDTL_NUM_OF_INSTALLMENT := NULL;
      END;
    
      TEMP_DATA4.REPAY_START_DATE  := TO_CHAR(V_LNACRSDTL_REPAY_FROM_DATE,
                                              'MM/DD/YYYY');
      TEMP_DATA4.REPAY_FREQ        := V_LNACRSDTL_REPAY_FREQ;
      TEMP_DATA4.INSTALL_SIZE      := V_LNACRSDTL_REPAY_AMT;
      TEMP_DATA4.NO_OF_INSTALLMENT := V_LNACRSDTL_NUM_OF_INSTALLMENT;
      --
    
      GET_TOT_SEC_AMT_CBD;
      TEMP_DATA4.SEC_AMT  := W_TOT_SEC_AMT_AC;
      TEMP_DATA4.SEC_CODE := W_SEC_TYPE_STR;
      TEMP_DATA4.SEC_NUM  := W_SEC_NUM_STR;
      TEMP_DATA4.REMARKS  := W_REMARKS;
    
      --   BB CODE
      BEGIN
        SELECT LNACMIS_HO_DEPT_CODE,
               LNACMIS.LNACMIS_SEGMENT_CODE,
               LNACMIS_SUB_INDUS_CODE,
               LNACMIS_NATURE_BORROWAL_AC
        
          INTO V_CL_MIS_CODE, V_CL_SEG_CODE, V_CL_ECO_CODE, V_CL_SME_CODE
          FROM LNACMIS
         WHERE LNACMIS_INTERNAL_ACNUM = T_REC_BRN_WISE(RPT)
              .ACNTS_INTERNAL_ACNUM;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_CL_MIS_CODE := '';
          V_CL_SEG_CODE := '';
          V_CL_ECO_CODE := '';
          V_CL_SME_CODE := '';
      END;
      -- CHECK WHETHER CODE IS NULL
      /* IF V_CL_MIS_CODE IS NOT NULL OR V_CL_MIS_CODE <> '' OR
          V_CL_SME_CODE IS NOT NULL OR V_CL_SME_CODE <> '' THEN
         CONTINUE;
       END IF;
      */
      TEMP_DATA4.ECO_PURP_CODE := V_CL_ECO_CODE;
      TEMP_DATA4.SME_CODE      := V_CL_SME_CODE;
      TEMP_DATA4.SEGMENT_CODE  := V_CL_SEG_CODE;
      TEMP_DATA4.CL_CODE       := V_CL_MIS_CODE;
      --
      --Note : OS Bal
    
      TEMP_DATA4.OUTSTANDING_BAL := fn_get_ason_acbal(1,
                                                      W_INTERNAL_ACNUM,
                                                      T_REC_BRN_WISE(RPT).ACNTS_CURR_CODE,
                                                      P_ASON_DATE,
                                                      V_CBD);
    
      PIPE ROW(TEMP_DATA4);
      W_REMARKS := '';
    END LOOP;
  END GET_BRANCH_WISE;
BEGIN
  NULL;
END PKG_CL_DATE_VERIFY;
/





--- Term Loan ------





SELECT BRN_CODE_TITLE,
       BRN_NAME_TITLE,
       BRN_CODE,
       BRN_NAME,
       PROD_CODE,
       PROD_NAME,
       ACC_NO,
       ACC_NAME,
       SANC_RESCHE_DATE,
       SANC_RESCHE_AMT,
       EXPIRY_DATE,
       SEC_AMT           SECURITY_AMOUNT,
       SEC_CODE          SECURITY_CODE,
       CL_CODE,
       SEGMENT_CODE      SECTOR_CODE,
       ECO_PURP_CODE     Economic_Purpose_Code,
       SME_CODE,
       OUTSTANDING_BAL,
	   B_MIG_INT_DEBT    TOTAL_INT_DEBIT_BEFORE_MIG,
       B_MIG_CHG_DEBT    TOTAL_CHG_DEBIT_BEFORE_MIG,
	   DISBURSE_DATE     FIRST_DISBURSE_DATE,
       DISBURSE_AMT      TOTAL_DISBURSE_AMOUNT,
	   REPAY_START_DATE,
       REPAY_FREQ,
       INSTALL_SIZE,
       NO_OF_INSTALLMENT
  FROM TABLE(PKG_CL_DATE_VERIFY.GET_BRANCH_WISE(0, 0, '23-NOV-2016'))  ;  --- 1st parameter branch code ,  2nd parameter 0 term loan , 1 continious loan
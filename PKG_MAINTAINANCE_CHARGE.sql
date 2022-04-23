CREATE OR REPLACE PACKAGE PKG_MAINTAINANCE_CHARGE IS

  -- AUTHOR  : Pratik das
  -- CREATED : 29-oct-2012
  -- PURPOSE : Maintainance charge for Savings account
  -- Maintainance charge for Parameterised  is calculated
  -- for the Average Balance for the Financial Year
  -- Newly created by rajib.pradhan on nov-24-2014 for improve performance and consider all issue

  PROCEDURE START_BRNWISE(V_ENTITY_NUM IN NUMBER,
                          P_BRN_CODE IN NUMBER DEFAULT 0);

END PKG_MAINTAINANCE_CHARGE;
/

CREATE OR REPLACE PACKAGE BODY PKG_MAINTAINANCE_CHARGE IS

  /*
   Modification History
    -----------------------------------------------------------------------------------------
   Sl.            Description                             Mod By             Mod on
  -----------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------------
   */
  TYPE MAINTAIN_CHARGE IS RECORD(
    BRN_CODE     NUMBER(6),
    ACCOUNT_NUM  NUMBER(14),
    PRODUCT_CODE NUMBER(4),
    ACTYPE       VARCHAR2(5),
    CURR_CODE    VARCHAR2(3),
    ACT_OPEN_DATE DATE);--ADDED BY PRATIK 18-DEC-2013

  TYPE T_MAINTAIN_CHARGE IS TABLE OF MAINTAIN_CHARGE INDEX BY PLS_INTEGER;
  W_MAINTAIN_CHARGE T_MAINTAIN_CHARGE;

  V_GLOB_ENTITY_NUM NUMBER;
  V_START_DATE DATE;
  V_INDEX_NUMBER NUMBER(20) :=0;
 ----- added by rajib.pradhan on 12/11/2014 
 V_PREVIOUS_CHARGE_GL VARCHAR2(20);
 V_PREVIOUS_VAT_PAY_GL VARCHAR2(20);
 W_AVG_BAL NUMBER(25,3);
 W_CHG_CODE  MAINTCHAVGBAL.MAINTCHAVGBAL_CURR_CODE%TYPE;
 W_CHG_TYPE MAINTCHAVGBAL.MAINTCHAVGBAL_CHG_TYPE%TYPE;
 W_CHARGE_CURR_CODE  MAINTCHAVGBAL.MAINTCHAVGBAL_CURR_CODE%TYPE;
 W_CHARGE_AMOUNT ACNTCHARGEAMT.ACNTCHGAMT_CHARGE_AMT%TYPE:=0;
 W_SERVICE_AMOUNT ACNTCHARGEAMT.ACNTCHGAMT_CHARGE_AMT%TYPE:=0;
 W_SERV_TAX_AMOUNT ACNTCHARGEAMT.ACNTCHGAMT_CHARGE_AMT%TYPE:=0;
 W_SERVICE_ADDN_AMOUNT ACNTCHARGEAMT.ACNTCHGAMT_CHARGE_AMT%TYPE:=0;
 W_SERVICE_CESS_AMOUNT ACNTCHARGEAMT.ACNTCHGAMT_CHARGE_AMT%TYPE:=0;
 W_TOTAL_SERV_TAX_AMT  ACNTCHARGEAMT.ACNTCHGAMT_CHARGE_AMT%TYPE:=0;
 W_POST_TRAN_BRN ACNTCHARGEAMT.ACNTCHGAMT_POST_TRAN_BRN%TYPE;
 W_TRAN_POST_FLAG  BOOLEAN DEFAULT FALSE;


       TYPE  TT_CHGAMT_ENTITY_NUM  IS TABLE OF NUMBER(4) INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_BRN_CODE  IS TABLE OF NUMBER(6)  INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_INTERNAL_ACNUM  IS TABLE OF NUMBER(14)   INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_PROCESS_DATE  IS TABLE OF DATE INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_FIN_YEAR  IS TABLE OF NUMBER(5) INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_CHARGE_AMT  IS TABLE OF NUMBER(24,3) INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_POST_TRAN_BRN  IS TABLE OF NUMBER(6)  INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_POST_TRAN_DATE  IS TABLE OF DATE INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_POST_TRAN_BATCH_NUM  IS TABLE OF NUMBER(10) INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_ENTD_BY  IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_ENTD_ON  IS TABLE OF DATE INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_LAST_MOD_BY  IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_LAST_MOD_ON  IS TABLE OF DATE INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_AUTH_BY  IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_AUTH_ON  IS TABLE OF DATE  INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_REJ_BY  IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_REJ_ON  IS TABLE OF DATE INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_AVG_BAL  IS TABLE OF NUMBER(24,3)  INDEX BY PLS_INTEGER;
       TYPE  TT_CHGAMT_SERV_TAX_AMT  IS TABLE OF NUMBER(24,3)  INDEX BY PLS_INTEGER;
            
        T_CHGAMT_ENTITY_NUM TT_CHGAMT_ENTITY_NUM;
        T_CHGAMT_BRN_CODE TT_CHGAMT_BRN_CODE;
        T_CHGAMT_INTERNAL_ACNUM TT_CHGAMT_INTERNAL_ACNUM;  
        T_CHGAMT_PROCESS_DATE TT_CHGAMT_PROCESS_DATE;
        T_CHGAMT_FIN_YEAR TT_CHGAMT_FIN_YEAR;
        T_CHGAMT_CHARGE_AMT TT_CHGAMT_CHARGE_AMT;  
        T_CHGAMT_POST_TRAN_BRN TT_CHGAMT_POST_TRAN_BRN;  
        T_CHGAMT_POST_TRAN_DATE TT_CHGAMT_POST_TRAN_DATE;  
        T_CHGAMT_POST_TRAN_BATCH_NUM TT_CHGAMT_POST_TRAN_BATCH_NUM;  
        T_CHGAMT_ENTD_BY TT_CHGAMT_ENTD_BY;
        T_CHGAMT_ENTD_ON TT_CHGAMT_ENTD_ON;
        T_CHGAMT_LAST_MOD_BY TT_CHGAMT_LAST_MOD_BY; 
        T_CHGAMT_LAST_MOD_ON TT_CHGAMT_LAST_MOD_ON; 
        T_CHGAMT_AUTH_BY TT_CHGAMT_AUTH_BY;
        T_CHGAMT_AUTH_ON TT_CHGAMT_AUTH_ON; 
        T_CHGAMT_REJ_BY TT_CHGAMT_REJ_BY;
        T_CHGAMT_REJ_ON TT_CHGAMT_REJ_ON; 
        T_CHGAMT_AVG_BAL TT_CHGAMT_AVG_BAL; 
        T_CHGAMT_SERV_TAX_AMT TT_CHGAMT_SERV_TAX_AMT; 
        
 W_PREV_CURR_CODE     VARCHAR2(3);
 TYPE TYP_AVG_BAL IS RECORD(
       AVG_BALANCE NUMBER(25,3),
       MAINTCHAVGBAL_ENTITY_NUM  MAINTCHAVGBAL.MAINTCHAVGBAL_ENTITY_NUM%TYPE,
       MAINTCHAVGBAL_INTERNAL_ACNUM MAINTCHAVGBAL.MAINTCHAVGBAL_INTERNAL_ACNUM%TYPE,
       MAINTCHAVGBAL_BRN_CODE MAINTCHAVGBAL.MAINTCHAVGBAL_BRN_CODE%TYPE,
       MAINTCHAVGBAL_PROD_CODE MAINTCHAVGBAL.MAINTCHAVGBAL_PROD_CODE%TYPE,
       MAINTCHAVGBAL_CHG_EFE_DATE MAINTCHAVGBAL.MAINTCHAVGBAL_CHG_EFE_DATE%TYPE,
       MAINTCHAVGBAL_CHARGE_CODE MAINTCHAVGBAL.MAINTCHAVGBAL_CHARGE_CODE%TYPE ,
       MAINTCHAVGBAL_CURR_CODE MAINTCHAVGBAL.MAINTCHAVGBAL_CURR_CODE%TYPE,
       MAINTCHAVGBAL_CHG_TYPE MAINTCHAVGBAL.MAINTCHAVGBAL_CHG_TYPE%TYPE,
       MAINTCHAVGBAL_GLACCESS_CD MAINTCHAVGBAL.MAINTCHAVGBAL_GLACCESS_CD%TYPE,
       MAINTCHAVGBAL_STAX_RCVD_HEAD MAINTCHAVGBAL.MAINTCHAVGBAL_STAX_RCVD_HEAD%TYPE);
       
       TYPE TT_AVG_BAL IS TABLE OF TYP_AVG_BAL INDEX BY PLS_INTEGER; 
       T_AVG_BAL TT_AVG_BAL;
 ----- added by rajib.pradhan on 12/11/2014 
  --W_POST_ARRAY_INDEX NUMBER(6) DEFAULT 0;
  W_POST_ARRAY_INDEX NUMBER(6):= 0;
  W_ERROR_CODE       VARCHAR2(10);
  W_ERROR            VARCHAR2(4000);
  W_BATCH_NUM        NUMBER(7);
  V_ASON_DATE        DATE;
  V_NARR1            VARCHAR2(35);
  V_NARR2            VARCHAR2(35);
  V_NARR3            VARCHAR2(35);
  W_ERROR_FLAG BOOLEAN;
  V_CHG_CODE   VARCHAR2(6);
  V_CHG_TYPE   CHAR(1);
  W_CHARGE_APPL     CHAR(1);
  W_NEW_VAT     NUMBER(18,3) := 0;
  W_NEW_CHARGE_AMT NUMBER(18,3) := 0;
  V_CURR_CODE        VARCHAR2(3);
  V_ACT_OPEN_DATE DATE;
  W_ACT_OPEN_DATE VARCHAR2(35);
  W_OPENING_DATE  VARCHAR2(35);
  V_OPEN_DATE DATE;
  W_BRN_CODE NUMBER(6);
  V_AC_BAL     NUMBER;
  V_AC_BAL1    NUMBER;
  W_CHARGE_AMT  NUMBER(18, 3) := 0;
  W_TOTAL_CHARGE_AMT NUMBER(18, 3) := 0;
  V_TRAN_FLAG     VARCHAR2(15);

  V_VAT_CODE VARCHAR2(6);
  V_VAT_PAY_GL         VARCHAR2(15) := '';
  W_SERV_TAX_AMT       NUMBER(18,3):= 0;

  V_CHARGE_GL        VARCHAR2(15) := '';
  W_ENTITY_CODE      NUMBER(5) := 0;

  V_SQL_STRING       VARCHAR2(1000) := '';
  W_SQL              VARCHAR2(1000) := '';
  W_SQL_1              VARCHAR2(1000) := '';
  V_SQL                VARCHAR2(1000):= '';
  W_PROD_CODE        NUMBER(6);
  W_CURR_CODE        VARCHAR2(3);
  W_AC_NUMBER        NUMBER(14);
  DEPOSIT_CONTRACT_NUM NUMBER(8);
  W_USER_ID        VARCHAR2(8);
  W_AC_TYPE          VARCHAR2(5);
  I                  NUMBER(4);
  V_USER_EXCEPTION EXCEPTION;
  V_BC_BAL         NUMBER(18,3) DEFAULT 0; -- ADDED BY BIBHU ON 20-12-2012
  V_AC_BALANCE     NUMBER(18,3);
  V_BC_BALANCE     NUMBER(18,3) DEFAULT 0;
  V_COUNT NUMBER(6);
  W_BASE_CURR      INSTALL.INS_BASE_CURR_CODE%TYPE;
  W_HALF_YEAR      VARCHAR2(1);
  W_TOTAL_VAT_NARATION VARCHAR2(100);
  
  
  W_DUMMY_V                VARCHAR2 (10);
  W_DUMMY_N                NUMBER;
  W_DUMMY_D                DATE;
  W_AC_AUTH_BAL        NUMBER (18, 3);

---- added by rajib.pradhan as on 12/11/2014 for generat charge applicable data . If it toke long time generat independent sp and call this sp before calling this package ....
PROCEDURE UPDATE_ACNTEXCISEAMT(P_ACTION BOOLEAN) IS
BEGIN

    IF P_ACTION=FALSE THEN
       BEGIN
         
       V_INDEX_NUMBER:=NVL(V_INDEX_NUMBER,0)+1;

        T_CHGAMT_ENTITY_NUM(V_INDEX_NUMBER):=W_ENTITY_CODE;
        T_CHGAMT_BRN_CODE(V_INDEX_NUMBER):=W_BRN_CODE;
        T_CHGAMT_INTERNAL_ACNUM(V_INDEX_NUMBER):=W_AC_NUMBER;
        T_CHGAMT_PROCESS_DATE(V_INDEX_NUMBER):=V_ASON_DATE;
        T_CHGAMT_FIN_YEAR(V_INDEX_NUMBER):=TO_NUMBER(TO_CHAR(V_ASON_DATE, 'YYYY'));
        T_CHGAMT_CHARGE_AMT(V_INDEX_NUMBER):=W_CHARGE_AMT;
        T_CHGAMT_POST_TRAN_BRN(V_INDEX_NUMBER):=W_POST_TRAN_BRN;
        T_CHGAMT_POST_TRAN_DATE(V_INDEX_NUMBER):=V_ASON_DATE;
        T_CHGAMT_POST_TRAN_BATCH_NUM(V_INDEX_NUMBER):=9999;
        T_CHGAMT_ENTD_BY(V_INDEX_NUMBER):=W_USER_ID;
        T_CHGAMT_ENTD_ON(V_INDEX_NUMBER):=V_ASON_DATE;
        T_CHGAMT_LAST_MOD_BY(V_INDEX_NUMBER):='';
        T_CHGAMT_LAST_MOD_ON(V_INDEX_NUMBER):='';
        T_CHGAMT_AUTH_BY(V_INDEX_NUMBER):='';
        T_CHGAMT_AUTH_ON(V_INDEX_NUMBER):='';
        T_CHGAMT_REJ_BY(V_INDEX_NUMBER):='';
        T_CHGAMT_REJ_ON(V_INDEX_NUMBER):='';
        T_CHGAMT_AVG_BAL(V_INDEX_NUMBER):=W_AVG_BAL;
        T_CHGAMT_SERV_TAX_AMT(V_INDEX_NUMBER):=W_SERV_TAX_AMT;
        
       END;
    ELSE
    FORALL IDX IN T_CHGAMT_ENTITY_NUM.FIRST .. T_CHGAMT_ENTITY_NUM.LAST
      INSERT INTO ACNTCHARGEAMT (ACNTCHGAMT_ENTITY_NUM,
                                 ACNTCHGAMT_BRN_CODE,
                                 ACNTCHGAMT_INTERNAL_ACNUM,
                                 ACNTCHGAMT_PROCESS_DATE,
                                 ACNTCHGAMT_FIN_YEAR,
                                 ACNTCHGAMT_CHARGE_AMT,
                                 ACNTCHGAMT_POST_TRAN_BRN,
                                 ACNTCHGAMT_POST_TRAN_DATE,
                                 ACNTCHGAMT_POST_TRAN_BATCH_NUM,
                                 ACNTCHGAMT_ENTD_BY,
                                 ACNTCHGAMT_ENTD_ON,
                                 ACNTCHGAMT_LAST_MOD_BY,
                                 ACNTCHGAMT_LAST_MOD_ON,
                                 ACNTCHGAMT_AUTH_BY,
                                 ACNTCHGAMT_AUTH_ON,
                                 ACNTCHGAMT_REJ_BY,
                                 ACNTCHGAMT_REJ_ON,
                                 ACNTCHGAMT_AVG_BAL,
                                 ACNTCHGAMT_SERV_TAX_AMT)
           VALUES (T_CHGAMT_ENTITY_NUM(IDX),
                   T_CHGAMT_BRN_CODE(IDX),
                   T_CHGAMT_INTERNAL_ACNUM(IDX),
                   T_CHGAMT_PROCESS_DATE(IDX),
                   T_CHGAMT_FIN_YEAR(IDX),
                   T_CHGAMT_CHARGE_AMT(IDX),
                   T_CHGAMT_POST_TRAN_BRN (IDX),
                   T_CHGAMT_POST_TRAN_DATE (IDX),
                   W_BATCH_NUM,
                   T_CHGAMT_ENTD_BY (IDX),
                   T_CHGAMT_ENTD_ON (IDX),
                   T_CHGAMT_LAST_MOD_BY (IDX),
                   T_CHGAMT_LAST_MOD_ON (IDX),
                   T_CHGAMT_AUTH_BY (IDX),
                   T_CHGAMT_AUTH_ON (IDX),
                   T_CHGAMT_REJ_BY (IDX),
                   T_CHGAMT_REJ_ON (IDX),
                   T_CHGAMT_AVG_BAL (IDX),
                   T_CHGAMT_SERV_TAX_AMT (IDX));            
       
        T_CHGAMT_ENTITY_NUM.DELETE; 
        T_CHGAMT_BRN_CODE.DELETE; 
        T_CHGAMT_INTERNAL_ACNUM.DELETE; 
        T_CHGAMT_PROCESS_DATE.DELETE; 
        T_CHGAMT_FIN_YEAR.DELETE; 
        T_CHGAMT_CHARGE_AMT.DELETE; 
        T_CHGAMT_POST_TRAN_BRN.DELETE; 
        T_CHGAMT_POST_TRAN_DATE.DELETE;  
        T_CHGAMT_POST_TRAN_BATCH_NUM.DELETE; 
        T_CHGAMT_ENTD_BY.DELETE; 
        T_CHGAMT_ENTD_ON.DELETE; 
        T_CHGAMT_LAST_MOD_BY.DELETE; 
        T_CHGAMT_LAST_MOD_ON.DELETE; 
        T_CHGAMT_AUTH_BY.DELETE; 
        T_CHGAMT_AUTH_ON.DELETE; 
        T_CHGAMT_REJ_BY.DELETE; 
        T_CHGAMT_REJ_ON.DELETE; 
        T_CHGAMT_AVG_BAL.DELETE; 
        T_CHGAMT_SERV_TAX_AMT.DELETE; 
    END IF;
 
END UPDATE_ACNTEXCISEAMT;

  FUNCTION FN_BASE_CURR_CONV_RATE(P_CURR_CODE IN VARCHAR2)
  RETURN NUMBER
  IS 
  
  V_RETURN_RATE NUMBER(18,3);
  V_SQL_DATA VARCHAR2(4000);
  
  TYPE REC_MAINCHARGECURR IS RECORD
  (
  T_MAINCHARG_BASE_CURR_AMT MAINCHARGECURR.MAINCHARG_BASE_CURR_AMT%TYPE
  );
  
  TYPE TT_MAINCHARGECURR IS TABLE OF REC_MAINCHARGECURR INDEX BY VARCHAR2(100);
  
  T_MAINCHARGECURR TT_MAINCHARGECURR;
  
  BEGIN
  
    IF T_MAINCHARGECURR.EXISTS(P_CURR_CODE)= TRUE THEN
      RETURN T_MAINCHARGECURR(P_CURR_CODE).T_MAINCHARG_BASE_CURR_AMT;
    ELSE
      BEGIN

       V_SQL_DATA :='SELECT MAINCHARG_BASE_CURR_AMT
                    FROM MAINCHARGECURR
                    WHERE UPPER(MAINCHARG_CURR_CODE)=UPPER(:1)';
                    
          EXECUTE IMMEDIATE V_SQL_DATA INTO V_RETURN_RATE USING P_CURR_CODE;
      EXCEPTION
           WHEN OTHERS THEN 
           RETURN 1;

      T_MAINCHARGECURR(P_CURR_CODE).T_MAINCHARG_BASE_CURR_AMT:=V_RETURN_RATE;

     END;
   END IF;
   
   RETURN V_RETURN_RATE;
   
  END FN_BASE_CURR_CONV_RATE;

  PROCEDURE MOVE_TO_TRANREC_CREDIT_VAT(P_BRN_CODE  IN NUMBER,
                                   P_CURR_CODE IN VARCHAR2,
                                   P_TRAN_AMT  IN NUMBER,
                                   P_ASON_DATE DATE,
                                   P_NARR1     IN VARCHAR2,
                                   P_NARR2     IN VARCHAR2,
                                   P_NARR3     IN VARCHAR2) IS
                                   
  V_BASE_CURR_CONV_RATE NUMBER(18,3):=1;
  
  BEGIN
  
    IF W_BASE_CURR<>P_CURR_CODE THEN 
     V_BASE_CURR_CONV_RATE:=FN_BASE_CURR_CONV_RATE(P_CURR_CODE);
     ELSE
     V_BASE_CURR_CONV_RATE:=1;
    END IF;
    
    
    IF P_TRAN_AMT > 0 THEN
    W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
    
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BRN_CODE := P_BRN_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_GLACC_CODE := V_VAT_PAY_GL;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DB_CR_FLG := 'C';
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_CURR_CODE := P_CURR_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BASE_CURR_CODE := W_BASE_CURR;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_AMOUNT := CEIL(P_TRAN_AMT);
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BASE_CURR_EQ_AMT := CEIL((V_BASE_CURR_CONV_RATE*P_TRAN_AMT));
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_VALUE_DATE := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL1 := P_NARR1;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL2 := P_NARR2;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL3 := P_NARR3;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      W_ERROR := 'ERROR IN MOVE_TO_TRANREC_CREDIT ' || '-' ||
                   SUBSTR(SQLERRM, 1, 500);
      RAISE V_USER_EXCEPTION;
  END MOVE_TO_TRANREC_CREDIT_VAT;

  PROCEDURE MOVE_TO_TRANREC_CREDIT(P_BRN_CODE IN NUMBER,
                                   P_CURR_CODE IN VARCHAR2,
                                   P_TRAN_AMT IN NUMBER, 
                                   P_ASON_DATE DATE,
                                   P_NARR1 IN VARCHAR2, 
                                   P_NARR2 IN VARCHAR2,
                                   P_NARR3 IN VARCHAR2) IS
                                   
   V_BASE_CURR_CONV_RATE NUMBER(18,3):=1;
   
  BEGIN
    --CREDIT EXCISE PYABLE GL
    W_TRAN_POST_FLAG:=TRUE;

    W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
    
    IF W_BASE_CURR<>P_CURR_CODE THEN 
     V_BASE_CURR_CONV_RATE:=FN_BASE_CURR_CONV_RATE(P_CURR_CODE);
     ELSE
     V_BASE_CURR_CONV_RATE:=1;
    END IF;
    
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BRN_CODE := P_BRN_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_GLACC_CODE := V_CHARGE_GL;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DB_CR_FLG := 'C';
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_CURR_CODE := P_CURR_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BASE_CURR_CODE := W_BASE_CURR;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_AMOUNT := P_TRAN_AMT;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BASE_CURR_EQ_AMT := (V_BASE_CURR_CONV_RATE*P_TRAN_AMT);
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_VALUE_DATE := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL1 := P_NARR1;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL2 := P_NARR2;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL3 := P_NARR3;

  EXCEPTION
    WHEN OTHERS THEN
      W_ERROR := 'ERROR IN MOVE_TO_TRANREC_CREDIT ' || '-' ||
                 SUBSTR(SQLERRM, 1, 500);
      RAISE V_USER_EXCEPTION;
  END MOVE_TO_TRANREC_CREDIT;

  ---------------------------------------------------------------------------------------------------------
  PROCEDURE MOVE_TO_TRANREC_DEBIT(P_AC_NUM IN NUMBER,
                                  P_CURR_CODE IN VARCHAR2,
                                  P_TRAN_AMT IN NUMBER, P_ASON_DATE IN DATE,
                                  P_NARR1 IN VARCHAR2, P_NARR2 IN VARCHAR2,
                                  P_NARR3 IN VARCHAR2) IS

  V_BASE_CURR_CONV_RATE NUMBER(18,3):=1;
  
  BEGIN
    --DEBIT ACCOUNT FOR CHARGE
   
    W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
    
    IF W_BASE_CURR<>P_CURR_CODE THEN 
     V_BASE_CURR_CONV_RATE:=FN_BASE_CURR_CONV_RATE(P_CURR_CODE);
     ELSE
     V_BASE_CURR_CONV_RATE:=1;
    END IF;
    
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_INTERNAL_ACNUM := P_AC_NUM;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DB_CR_FLG := 'D';
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_CURR_CODE := P_CURR_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BASE_CURR_CODE := W_BASE_CURR;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_AMOUNT := P_TRAN_AMT;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BASE_CURR_EQ_AMT := (V_BASE_CURR_CONV_RATE*P_TRAN_AMT);
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_VALUE_DATE := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL1 := P_NARR1;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL2 := P_NARR2;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL3 := P_NARR3;

  EXCEPTION
    WHEN OTHERS THEN
      W_ERROR := 'ERROR IN MOVE_TO_TRANREC_DEBIT ' || '-' ||
                 SUBSTR(SQLERRM, 1, 500);
      RAISE V_USER_EXCEPTION;
  END MOVE_TO_TRANREC_DEBIT;


  PROCEDURE MOVE_TO_TRAVAT_DEBIT(P_AC_NUM IN NUMBER,
                                  P_CURR_CODE IN VARCHAR2,
                                  P_TRAN_AMT IN NUMBER, P_ASON_DATE IN DATE,
                                  P_NARR1 IN VARCHAR2, P_NARR2 IN VARCHAR2,
                                  P_NARR3 IN VARCHAR2) IS

  V_BASE_CURR_CONV_RATE NUMBER(18,3):=1;
  
  BEGIN
    --DEBIT ACCOUNT FOR VAT
   
    W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
    
    IF W_BASE_CURR<>P_CURR_CODE THEN 
     V_BASE_CURR_CONV_RATE:=FN_BASE_CURR_CONV_RATE(P_CURR_CODE);
     ELSE
     V_BASE_CURR_CONV_RATE:=1;
    END IF;
    
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_INTERNAL_ACNUM := P_AC_NUM;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DB_CR_FLG := 'D';
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_CURR_CODE := P_CURR_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BASE_CURR_CODE := W_BASE_CURR;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_AMOUNT := P_TRAN_AMT;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BASE_CURR_EQ_AMT := CEIL(V_BASE_CURR_CONV_RATE*P_TRAN_AMT);
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_VALUE_DATE := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL1 := P_NARR1;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL2 := P_NARR2;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_NARR_DTL3 := P_NARR3;

  EXCEPTION
    WHEN OTHERS THEN
      W_ERROR := 'ERROR IN MOVE_TO_TRAVAT_DEBIT ' || '-' ||
                 SUBSTR(SQLERRM, 1, 500);
      RAISE V_USER_EXCEPTION;
  END MOVE_TO_TRAVAT_DEBIT;

 ---------------------------------------------------------------------------------------------------------
  PROCEDURE INIT_VALUES IS
  BEGIN

    W_CHARGE_AMT  := 0;
    W_SERV_TAX_AMT := 0;
    V_SQL_STRING       := '';
    W_SQL              := '';
    DEPOSIT_CONTRACT_NUM := 0;
    I := 0;
    W_CHARGE_AMOUNT:=0;
    W_SERV_TAX_AMOUNT:=0;
  END;
  ------------------------------------------------------------------------------------------------------
  PROCEDURE SET_TRAN_KEY_VALUES(P_BRN_CODE IN NUMBER) IS
  BEGIN
    PKG_AUTOPOST.PV_SYSTEM_POSTED_TRANSACTION  := TRUE;
    PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BRN_CODE     := P_BRN_CODE;
    PKG_AUTOPOST.PV_TRAN_KEY.TRAN_DATE_OF_TRAN := V_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_NUMBER := 0;
    PKG_AUTOPOST.PV_TRAN_KEY.TRAN_BATCH_SL_NUM := 0;
  EXCEPTION
    WHEN OTHERS THEN
      W_ERROR := 'ERROR IN SET_TRAN_KEY_VALUES ' || '-' ||
                 SUBSTR(SQLERRM, 1, 500);
      RAISE V_USER_EXCEPTION;
  END SET_TRAN_KEY_VALUES;
  ------------------------------------------------------------------------------------------------------
  PROCEDURE SET_TRANBAT_VALUES(P_BRN_CODE IN NUMBER) IS
  BEGIN
    PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'Charge';
    PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY   := P_BRN_CODE;
    PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1    := 'Maintenance Charge';

  EXCEPTION
    WHEN OTHERS THEN
      W_ERROR := 'ERROR IN SET_TRANBAT_VALUES ' || P_BRN_CODE ||
                 SUBSTR(SQLERRM, 1, 500);
      RAISE V_USER_EXCEPTION;
  END SET_TRANBAT_VALUES;

  ---------------------------------------------------------------------------------------------------------
  PROCEDURE POST_TRANSACTION IS
  BEGIN
    PKG_APOST_INTERFACE.SP_POST_SODEOD_BATCH((V_GLOB_ENTITY_NUM),
                                             'A', W_POST_ARRAY_INDEX, 0,
                                             W_ERROR_CODE, W_ERROR,
                                             W_BATCH_NUM);

  PKG_AUTOPOST.PV_TRAN_REC.DELETE;

    IF (W_ERROR_CODE <> '0000') THEN
      W_ERROR := 'ERROR IN POST_TRANSACTION for Maintenance Charge-  '||W_ERROR_CODE||W_ERROR||FN_GET_AUTOPOST_ERR_MSG(V_GLOB_ENTITY_NUM);
      RAISE V_USER_EXCEPTION;
      ELSE 
    UPDATE_ACNTEXCISEAMT(TRUE);
    END IF;

  END POST_TRANSACTION;
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE AUTOPOST_ENTRIES IS
  BEGIN

    IF W_POST_ARRAY_INDEX > 0 THEN
    W_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;
      POST_TRANSACTION;
    END IF;

    W_POST_ARRAY_INDEX := 0;

  END AUTOPOST_ENTRIES;
  
  PROCEDURE SP_GET_VAT_NARATION (P_GL_CODE IN VARCHAR2) IS 
  BEGIN
   SELECT 'VAT ON '||EXTGL_EXT_HEAD_DESCN
   INTO W_TOTAL_VAT_NARATION
   FROM EXTGL
   WHERE EXTGL_ACCESS_CODE = P_GL_CODE;
  END;

  ------------------------------------------------------------------------------------------------------------
  PROCEDURE PROCESS_MAINTAINANCE_CHARGE(W_ENTITY_CODE IN NUMBER,
                                V_BRN_CODE IN NUMBER) IS
 V_SQL_AVG_BAL CLOB;
  TYPE REC_AVG_BAL IS REF CURSOR;
   C_AVG_BAL      REC_AVG_BAL;
  BEGIN
  W_BRN_CODE := V_BRN_CODE;

    V_SQL_AVG_BAL:='SELECT ROUND (
                                    ( (SUM (AVERAGE_BALANCE) + (MIG_DIFF_DAY * MAINTCHAVGBAL_MIG_AVG_BAL))
                                     / (:CURR_DATE - MAINTCHAVGBAL_CHG_EFE_DATE)),
                                    2)
                                 AVERAGE_BALANCE,
                                 MAINTCHAVGBAL_ENTITY_NUM,
                                 MAINTCHAVGBAL_INTERNAL_ACNUM,
                                 MAINTCHAVGBAL_BRN_CODE,
                                 MAINTCHAVGBAL_PROD_CODE,
                                 MAINTCHAVGBAL_CHG_EFE_DATE,
                                 MAINTCHAVGBAL_CHARGE_CODE,
                                 MAINTCHAVGBAL_CURR_CODE,
                                 MAINTCHAVGBAL_CHG_TYPE,
                                 MAINTCHAVGBAL_GLACCESS_CD,
                                 MAINTCHAVGBAL_STAX_RCVD_HEAD
                            FROM (SELECT ASON_TRAN_DATE,
                                         NEXT_TRAN_DATE,
                                         ACBALH_AC_BAL,
                                         NVL (NEXT_TRAN_DATE - ASON_TRAN_DATE, 0) TOTAL_DAYS,
                                         (ACBALH_AC_BAL * (NEXT_TRAN_DATE - ASON_TRAN_DATE))
                                         AVERAGE_BALANCE,
                                         MAINTCHAVGBAL_ENTITY_NUM,
                                         MAINTCHAVGBAL_INTERNAL_ACNUM,
                                         MAINTCHAVGBAL_BRN_CODE,
                                         MAINTCHAVGBAL_OPENING_DATE,
                                         MAINTCHAVGBAL_PROD_CODE,
                                         MAINTCHAVGBAL_MIG_DATE,
                                         MAINTCHAVGBAL_MIG_AVG_BAL,
                                         MAINTCHAVGBAL_LCHG_DEDDATE,
                                         MAINTCHAVGBAL_LTRAN_DATE,
                                         MAINTCHAVGBAL_CHG_EFE_DATE,
                                         MAINTCHAVGBAL_CHARGE_CODE,
                                         MAINTCHAVGBAL_CURR_CODE,
                                         MAINTCHAVGBAL_CHG_TYPE,
                                         MAINTCHAVGBAL_GLACCESS_CD,
                                         MAINTCHAVGBAL_STAX_RCVD_HEAD,
                                         NVL (
                                            (CASE
                                                WHEN MAINTCHAVGBAL_MIG_DATE >= :FROM_DATE
                                                THEN
                                                   (CASE
                                                       WHEN MAINTCHAVGBAL_OPENING_DATE > :FROM_DATE
                                                       THEN
                                                          MAINTCHAVGBAL_MIG_DATE - MAINTCHAVGBAL_OPENING_DATE
                                                       ELSE
                                                          MAINTCHAVGBAL_MIG_DATE - :FROM_DATE
                                                    END)
                                             END),
                                            0)
                                            MIG_DIFF_DAY
                                    FROM (SELECT ACBALH_ASON_DATE,
                                                 ROW_NUMBER ()
                                                 OVER (
                                                    PARTITION BY ACBALH_INTERNAL_ACNUM
                                                    ORDER BY
                                                       ACBALH_INTERNAL_ACNUM,
                                                       ACBALH_ASON_DATE NULLS LAST)
                                                    SERIAL_NUMBER,
                                                 (CASE
                                                     WHEN ACBALH_ASON_DATE < :FROM_DATE THEN :FROM_DATE
                                                     ELSE ACBALH_ASON_DATE
                                                  END)
                                                    ASON_TRAN_DATE,
                                                 (NVL (
                                                     LEAD (
                                                        ACBALH_ASON_DATE)
                                                     OVER (
                                                        PARTITION BY ACBALH_INTERNAL_ACNUM
                                                        ORDER BY
                                                           ACBALH_INTERNAL_ACNUM,
                                                           ACBALH_ASON_DATE NULLS LAST),
                                                     :CURR_DATE))
                                                    NEXT_TRAN_DATE,
                                                 ACBALH_AC_BAL,
                                                 MAINTCHAVGBAL_ENTITY_NUM,
                                                 MAINTCHAVGBAL_INTERNAL_ACNUM,
                                                 MAINTCHAVGBAL_BRN_CODE,
                                                 MAINTCHAVGBAL_OPENING_DATE,
                                                 MAINTCHAVGBAL_PROD_CODE,
                                                 MAINTCHAVGBAL_MIG_DATE,
                                                 MAINTCHAVGBAL_CHARGE_CODE,
                                                 MAINTCHAVGBAL_CURR_CODE,
                                                 MAINTCHAVGBAL_CHG_TYPE,
                                                 MAINTCHAVGBAL_GLACCESS_CD,
                                                 MAINTCHAVGBAL_STAX_RCVD_HEAD,
                                                 (CASE
                                                     WHEN MAINTCHAVGBAL_MIG_AVG_BAL < 0 THEN 0
                                                     ELSE MAINTCHAVGBAL_MIG_AVG_BAL
                                                  END)
                                                    MAINTCHAVGBAL_MIG_AVG_BAL,
                                                 MAINTCHAVGBAL_LCHG_DEDDATE,
                                                 MAINTCHAVGBAL_LTRAN_DATE,
                                                 (CASE
                                                     WHEN MAINTCHAVGBAL_CHG_EFE_DATE > :FROM_DATE
                                                     THEN
                                                        MAINTCHAVGBAL_CHG_EFE_DATE
                                                     ELSE
                                                        :FROM_DATE
                                                  END)
                                                    MAINTCHAVGBAL_CHG_EFE_DATE
                                            FROM MAINTCHAVGBAL A, ACBALASONHIST ACHIST
                                           WHERE A.MAINTCHAVGBAL_INTERNAL_ACNUM = ACHIST.ACBALH_INTERNAL_ACNUM
                                                 AND MAINTCHAVGBAL_BRN_CODE=DECODE(:BRANCH_CODE,0,MAINTCHAVGBAL_BRN_CODE,:BRANCH_CODE)
                                                 AND ACBALH_ASON_DATE >=
                                                        NVL (MAINTCHAVGBAL_LTRAN_DATE, :FROM_DATE)))
                        GROUP BY MAINTCHAVGBAL_ENTITY_NUM,
                                 MAINTCHAVGBAL_INTERNAL_ACNUM,
                                 MAINTCHAVGBAL_BRN_CODE,
                                 MAINTCHAVGBAL_PROD_CODE,
                                 MAINTCHAVGBAL_CHG_EFE_DATE,
                                 MIG_DIFF_DAY,
                                 MAINTCHAVGBAL_MIG_AVG_BAL,
                                 MAINTCHAVGBAL_CHARGE_CODE,
                                 MAINTCHAVGBAL_CURR_CODE,
                                 MAINTCHAVGBAL_CHG_TYPE,
                                 MAINTCHAVGBAL_GLACCESS_CD,
                                 MAINTCHAVGBAL_STAX_RCVD_HEAD
                       ORDER BY MAINTCHAVGBAL_CURR_CODE, MAINTCHAVGBAL_GLACCESS_CD';
  BEGIN
   OPEN C_AVG_BAL FOR V_SQL_AVG_BAL
   USING V_ASON_DATE,V_START_DATE,V_START_DATE,V_START_DATE,V_START_DATE,V_START_DATE,V_ASON_DATE,V_START_DATE,V_START_DATE,W_BRN_CODE,W_BRN_CODE,V_START_DATE;

      LOOP
         FETCH C_AVG_BAL
         BULK COLLECT INTO T_AVG_BAL
         LIMIT 50000;
         
         FOR IND_AVG_BAL IN 1 .. T_AVG_BAL.COUNT LOOP
         
         INIT_VALUES;

        IF IND_AVG_BAL = 1 THEN
         W_PREV_CURR_CODE := T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_CURR_CODE;
         V_PREVIOUS_VAT_PAY_GL:=T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_STAX_RCVD_HEAD;
         V_PREVIOUS_CHARGE_GL:=T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_GLACCESS_CD;
        END IF;
        ----  Credit transaction for vat and charge GL
           
         IF W_TOTAL_CHARGE_AMT<>0 AND T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_GLACCESS_CD<>V_PREVIOUS_CHARGE_GL THEN
                  V_PREVIOUS_CHARGE_GL:=T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_GLACCESS_CD;
                  V_NARR1 := 'Maintenance charge ';
                  V_NARR2 := NULL;
                  V_NARR3 := NULL;
                              
                  MOVE_TO_TRANREC_CREDIT(W_BRN_CODE, 
                                         W_CURR_CODE,
                                         W_TOTAL_CHARGE_AMT, 
                                         V_ASON_DATE, 
                                         V_NARR1,
                                         V_NARR2, 
                                         V_NARR3);
                 W_TOTAL_CHARGE_AMT:=0;
                             
             ---IF W_TOTAL_SERV_TAX_AMT <> 0 AND T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_STAX_RCVD_HEAD<>V_PREVIOUS_VAT_PAY_GL THEN
             
             ------ Move vat credit transaction
             
              V_PREVIOUS_VAT_PAY_GL:=T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_STAX_RCVD_HEAD;
              SP_GET_VAT_NARATION(V_CHARGE_GL);
              V_NARR1 := SUBSTR(W_TOTAL_VAT_NARATION,1,35);
              V_NARR2 := SUBSTR(W_TOTAL_VAT_NARATION,36,35);
              V_NARR3 := SUBSTR(W_TOTAL_VAT_NARATION,71,35);
              MOVE_TO_TRANREC_CREDIT_VAT(W_BRN_CODE, 
                                                                 W_BASE_CURR,
                                                                 W_TOTAL_SERV_TAX_AMT, 
                                                                 V_ASON_DATE, 
                                                                 V_NARR1,
                                                                 V_NARR2, 
                                                                 V_NARR3);
               W_TOTAL_SERV_TAX_AMT:=0;
         END IF;
         
        W_PROD_CODE    := T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_PROD_CODE;
        W_AC_NUMBER    := T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_INTERNAL_ACNUM;
        W_CURR_CODE    := T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_CURR_CODE;
        W_AVG_BAL      := T_AVG_BAL(IND_AVG_BAL).AVG_BALANCE;
        W_CHG_CODE     := T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_CHARGE_CODE;
        W_CHG_TYPE     := T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_CHG_TYPE;
        V_VAT_PAY_GL   := T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_STAX_RCVD_HEAD;
        V_CHARGE_GL    := T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_GLACCESS_CD;
        W_CHARGE_APPL  := '1';

         ---- get charge amount using average balance 
             BEGIN
                PKG_CHARGES.SP_GET_CHARGES(T_AVG_BAL(IND_AVG_BAL).MAINTCHAVGBAL_ENTITY_NUM,
                     W_AC_NUMBER,
                     W_CURR_CODE,
                     W_AVG_BAL,
                     W_CHG_CODE,
                     W_CHG_TYPE,
                     W_CHARGE_CURR_CODE,
                     W_CHARGE_AMOUNT,
                     W_SERVICE_AMOUNT,
                     W_SERV_TAX_AMOUNT,
                     W_SERVICE_ADDN_AMOUNT,
                     W_SERVICE_CESS_AMOUNT,
                     W_ERROR);
             END;
             
             W_CHARGE_AMT:=W_CHARGE_AMOUNT;
             W_SERV_TAX_AMT := W_SERV_TAX_AMOUNT;
             
            IF W_CURR_CODE<>W_BASE_CURR AND W_HALF_YEAR='1' THEN 
               W_CHARGE_AMT:=0;
               W_CHARGE_AMOUNT:=0;
               W_SERV_TAX_AMOUNT:=0;
               W_SERV_TAX_AMT:=0;
            END IF;
             
            IF W_CURR_CODE<>W_BASE_CURR THEN 
               W_SERV_TAX_AMT:=W_CHARGE_AMT*.15;
            END IF;

             BEGIN
                V_AC_BALANCE:= 0;
                V_BC_BALANCE:= 0;
                
                BEGIN

                  /*
                    GET_ASON_ACBAL(W_ENTITY_CODE,
                                     W_AC_NUMBER,
                                     W_CURR_CODE,
                                     V_ASON_DATE,
                                     V_ASON_DATE,
                                     V_AC_BALANCE,
                                     V_BC_BALANCE,
                                     W_ERROR,
                                     V_TRAN_FLAG);
                  */                   

                 BEGIN
                    SP_AVLBAL (W_ENTITY_CODE,
                               W_AC_NUMBER,
                               W_DUMMY_V,
                               W_AC_AUTH_BAL,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               W_DUMMY_N,
                               V_AC_BALANCE,
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
                       V_AC_BALANCE:=0;
                    END IF;
                 END;
                 
                END;
                                 
                 IF V_AC_BALANCE <= 0 THEN
                   GOTO SKIPACCOUNT;
                   END IF;
                   
                    IF V_AC_BALANCE < (W_CHARGE_AMT + W_SERV_TAX_AMT) THEN
                       --Masud@spftl 01-JAN-2014
                        IF V_AC_BALANCE > 1 THEN
                         
                          IF W_CURR_CODE=W_BASE_CURR THEN 
                         
                           W_NEW_VAT := CEIL((W_SERV_TAX_AMT/(W_CHARGE_AMT+W_SERV_TAX_AMT)) * V_AC_BALANCE);
                           W_NEW_CHARGE_AMT := V_AC_BALANCE - W_NEW_VAT;
                           
                           ELSE
                           --W_NEW_VAT := ((W_SERV_TAX_AMT/(W_CHARGE_AMT+W_SERV_TAX_AMT)) * V_AC_BALANCE);
                           W_NEW_VAT := TRUNC(((W_SERV_TAX_AMT/(W_CHARGE_AMT+W_SERV_TAX_AMT)) * V_AC_BALANCE),2);
                           W_NEW_CHARGE_AMT := V_AC_BALANCE - W_NEW_VAT;
                          END IF;

                            IF V_AC_BALANCE < (W_NEW_CHARGE_AMT + W_NEW_VAT) THEN
                              GOTO SKIPACCOUNT;
                            ELSE
                               W_CHARGE_AMT :=  W_NEW_CHARGE_AMT;
                               W_SERV_TAX_AMT := W_NEW_VAT;
                            END IF;
                         ELSE
                          GOTO SKIPACCOUNT;
                        END IF;
                    END IF;

                   IF W_CURR_CODE = W_PREV_CURR_CODE THEN

                     IF W_CHARGE_APPL = 0 THEN
                       GOTO SKIPACCOUNT;
                     END IF;

                    IF W_CHARGE_AMT > 0 THEN
                    W_TOTAL_CHARGE_AMT := W_TOTAL_CHARGE_AMT + W_CHARGE_AMT;
                    V_NARR1 := 'Maintenance charge ';
                    V_NARR2 := NULL;
                    V_NARR3 := NULL;
                    MOVE_TO_TRANREC_DEBIT(W_AC_NUMBER,
                                          W_CURR_CODE,
                                          W_CHARGE_AMT, V_ASON_DATE, V_NARR1,
                                          V_NARR2, V_NARR3);
                    END IF;

                    IF W_SERV_TAX_AMT > 0 THEN
                    V_CURR_CODE        := W_CURR_CODE;
                    W_TOTAL_SERV_TAX_AMT := W_TOTAL_SERV_TAX_AMT + CEIL(FN_BASE_CURR_CONV_RATE(W_CURR_CODE)*W_SERV_TAX_AMT);
                    V_NARR1 := 'VAT on Maintenance charge';
                    V_NARR2 := 'For Product '||W_PROD_CODE;
                    MOVE_TO_TRAVAT_DEBIT (W_AC_NUMBER,
                                          V_CURR_CODE,
                                          W_SERV_TAX_AMT, V_ASON_DATE, V_NARR1,
                                          V_NARR2, V_NARR3);
                    END IF;

                    ELSE

                      SET_TRAN_KEY_VALUES(W_BRN_CODE);
                      SET_TRANBAT_VALUES(W_BRN_CODE);
                      V_NARR1 := 'Maintenance charge  ';
                      V_NARR2 := NULL;
                      V_NARR3 := NULL;
                      V_CURR_CODE := W_PREV_CURR_CODE;
                      W_PREV_CURR_CODE:=W_CURR_CODE;
                      IF W_TOTAL_CHARGE_AMT <> 0 THEN
                      MOVE_TO_TRANREC_CREDIT(W_BRN_CODE, V_CURR_CODE,
                                             W_TOTAL_CHARGE_AMT, V_ASON_DATE, V_NARR1,
                                             V_NARR2, V_NARR3);
                      --ADDED BY PRATIK BEGIN 27-03-2013
                          IF W_TOTAL_SERV_TAX_AMT <> 0 THEN
                          SP_GET_VAT_NARATION(V_CHARGE_GL);
                          V_NARR1 := SUBSTR(W_TOTAL_VAT_NARATION,1,35);
                          V_NARR2 := SUBSTR(W_TOTAL_VAT_NARATION,36,35);
                          V_NARR3 := SUBSTR(W_TOTAL_VAT_NARATION,71,35);
                          MOVE_TO_TRANREC_CREDIT_VAT(W_BRN_CODE, W_BASE_CURR,
                                                 W_TOTAL_SERV_TAX_AMT, V_ASON_DATE, V_NARR1,
                                                 V_NARR2, V_NARR3);

                          END IF;
                      --ADDED BY PRATIK END 27-03-2013
                      AUTOPOST_ENTRIES;
                      UPDATE_ACNTEXCISEAMT(TRUE);
                      ---V_CHARGE_GL       := '';

                      W_BATCH_NUM := '';
                      END IF;
                      W_TOTAL_CHARGE_AMT := 0;
                      W_TOTAL_SERV_TAX_AMT := 0;--ADDED BY PRATIK 27-03-13

                      --W_TOTAL_SERV_TAX_AMT := W_TOTAL_SERV_TAX_AMT + W_SERV_TAX_AMT;--ADDED BY PRATIK BEGIN 27-03-2013

                     IF W_CHARGE_AMT > 0 THEN
                       V_CURR_CODE        := W_CURR_CODE;
                       W_TOTAL_CHARGE_AMT := W_TOTAL_CHARGE_AMT + W_CHARGE_AMT;
                       V_NARR1 := 'Maintenance charge';
                       V_NARR2 := NULL;
                       V_NARR3 := NULL;
                      MOVE_TO_TRANREC_DEBIT(W_AC_NUMBER,
                                            W_CURR_CODE,
                                            W_CHARGE_AMT, V_ASON_DATE, V_NARR1,
                                            V_NARR2, V_NARR3);
                      END IF;
                    --ADDED BY PRATIK BEGIN 27-03-13
                        IF W_SERV_TAX_AMT > 0 THEN
                        V_CURR_CODE        :=W_CURR_CODE;
                        W_TOTAL_SERV_TAX_AMT := W_TOTAL_SERV_TAX_AMT + FN_BASE_CURR_CONV_RATE(W_CURR_CODE)*W_SERV_TAX_AMT;
                        V_NARR1 := 'VAT on Maintenance charge';
                        V_NARR2 := 'For Product '||W_PROD_CODE;
                        MOVE_TO_TRAVAT_DEBIT(W_AC_NUMBER,
                                              V_CURR_CODE,
                                              W_SERV_TAX_AMT, V_ASON_DATE, V_NARR1,
                                              V_NARR2, V_NARR3);
                        END IF;
                        --ADDED BY PRATIK END 27-03-13
                  END IF;

                  UPDATE_ACNTEXCISEAMT(FALSE);
                 <<SKIPACCOUNT>>
                    BEGIN
                      NULL;
                    END SKIPACCOUNT;

                  IF IND_AVG_BAL = T_AVG_BAL.COUNT THEN

                  -- FOR THE LAST CURRENCY CODE CREDIT LEG IS HANDLED HERE
                  SET_TRAN_KEY_VALUES(W_BRN_CODE);
                  SET_TRANBAT_VALUES(W_BRN_CODE);
                  V_NARR1 := 'Maintenance charge ';
                  V_NARR2 := NULL;
                  V_NARR3 := NULL;
                  V_CURR_CODE := W_PREV_CURR_CODE;
                  IF W_TOTAL_CHARGE_AMT <> 0 THEN
                  MOVE_TO_TRANREC_CREDIT(W_BRN_CODE, V_CURR_CODE,
                                         W_TOTAL_CHARGE_AMT, V_ASON_DATE, V_NARR1,
                                         V_NARR2, V_NARR3);
                  --ADDED BY PRATIK BEGIN 27-03-2013
                      IF W_TOTAL_SERV_TAX_AMT <> 0 THEN
                      SP_GET_VAT_NARATION(V_CHARGE_GL);
                      V_NARR1 := SUBSTR(W_TOTAL_VAT_NARATION,1,35);
                      V_NARR2 := SUBSTR(W_TOTAL_VAT_NARATION,36,35);
                      V_NARR3 := SUBSTR(W_TOTAL_VAT_NARATION,71,35);
                      MOVE_TO_TRANREC_CREDIT_VAT(W_BRN_CODE, W_BASE_CURR,
                                             W_TOTAL_SERV_TAX_AMT, V_ASON_DATE, V_NARR1,
                                             V_NARR2, V_NARR3);

                      END IF;
                      
                          W_TOTAL_CHARGE_AMT := 0;
                          W_TOTAL_SERV_TAX_AMT := 0;
                    END IF;
                    IF W_TRAN_POST_FLAG THEN
                      AUTOPOST_ENTRIES;
                      ---V_CHARGE_GL        := '';
                      W_BATCH_NUM := '';
                      --PREV_CURR_CODE := '';
                      W_PREV_CURR_CODE := W_CURR_CODE;
                    END IF;

                  END IF;
             END;
       END LOOP;
       
         EXIT WHEN C_AVG_BAL%NOTFOUND;
      END LOOP;
      T_AVG_BAL.DELETE;
  END;

  EXCEPTION
    WHEN OTHERS THEN

      IF TRIM(W_ERROR) IS NULL THEN
        W_ERROR := SUBSTR('ERROR IN PKG_MAINTAINANCE_CHARGE ' || SQLERRM, 1, 500)||FACNO(W_ENTITY_CODE,W_AC_NUMBER)||W_CHARGE_AMT||W_TOTAL_CHARGE_AMT;
      END IF;
    
      PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
      PKG_PB_GLOBAL.DETAIL_ERRLOG(W_ENTITY_CODE, 'E',PKG_EODSOD_FLAGS.PV_ERROR_MSG, ' ', 0);
      PKG_PB_GLOBAL.DETAIL_ERRLOG(W_ENTITY_CODE, 'E',SUBSTR(SQLERRM, 1, 1000), ' ', 0);
      PKG_PB_GLOBAL.DETAIL_ERRLOG(W_ENTITY_CODE, 'X', W_ENTITY_CODE, ' ', 0);
      RAISE V_USER_EXCEPTION;
  END PROCESS_MAINTAINANCE_CHARGE;
  ---------------------------------------------------------------------------------------------------------
 PROCEDURE START_BRNWISE(V_ENTITY_NUM IN NUMBER,
                          P_BRN_CODE IN NUMBER DEFAULT 0) IS
    L_BRN_CODE       NUMBER(6);

  BEGIN
    PKG_ENTITY.SP_SET_ENTITY_CODE(V_ENTITY_NUM);
    V_GLOB_ENTITY_NUM:=V_ENTITY_NUM;
    W_ENTITY_CODE := V_GLOB_ENTITY_NUM;
    PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE(W_ENTITY_CODE, P_BRN_CODE);
    V_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
    V_START_DATE:=PKG_PB_GLOBAL.SP_FORM_START_DATE(1,V_ASON_DATE,'H');
    W_USER_ID :=  PKG_EODSOD_FLAGS.PV_USER_ID  ;
    W_POST_TRAN_BRN:=PKG_PB_GLOBAL.FN_GET_USER_BRN_CODE(V_GLOB_ENTITY_NUM,W_USER_ID) ;
    W_BASE_CURR    :=PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR(V_GLOB_ENTITY_NUM);
    
    IF UPPER(TO_CHAR(V_ASON_DATE,'MON')) = 'JUN' THEN
     W_HALF_YEAR:='1';
     ELSE
     W_HALF_YEAR:='0';
    END IF;

    --- AVERAGE_BALANCE_DATA_GENERATE(P_BRN_CODE,V_START_DATE,V_ASON_DATE); --- added by rajib.pradhan for generat average balance data

    FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT LOOP
      L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN(IDX).LN_BRN_CODE;
      W_TRAN_POST_FLAG:=FALSE;
      IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED(W_ENTITY_CODE,
                                                     L_BRN_CODE) = FALSE THEN
       W_TOTAL_CHARGE_AMT := 0;
       
       PKG_AUTOPOST.PV_TRAN_REC.DELETE;
       
        PROCESS_MAINTAINANCE_CHARGE(W_ENTITY_CODE, L_BRN_CODE);

        IF TRIM(PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL THEN
          PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN(V_GLOB_ENTITY_NUM,
                                                          L_BRN_CODE);
        END IF;
        PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS(V_GLOB_ENTITY_NUM);
      END IF;
    END LOOP;
    
  END START_BRNWISE;

END PKG_MAINTAINANCE_CHARGE;

/
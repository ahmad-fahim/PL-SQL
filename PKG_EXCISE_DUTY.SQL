CREATE OR REPLACE PACKAGE PKG_EXCISE_DUTY IS

  -- AUTHOR  : K. NEELAKANTAN
  -- CREATED : 23-JAN-2012
  -- PURPOSE : EXCISE DUTY FOR the Branches
  -- Excise Duty for Parameterised  is calculated
  -- for the Highest Balance for the Financial Year

  PROCEDURE START_BRNWISE(V_ENTITY_NUM IN NUMBER,
                          P_BRN_CODE IN NUMBER DEFAULT 0);

END PKG_EXCISE_DUTY;
/

CREATE OR REPLACE PACKAGE BODY PKG_EXCISE_DUTY IS

  /*
   Modification History
    -----------------------------------------------------------------------------------------
   Sl.            Description                             Mod By             Mod on
   -----------------------------------------------------------------------------------------
    Modified by rajib.pradhan on 25/11/2014 for improve performance and correction business logic.
  -----------------------------------------------------------------------------------------
   */

--- added by rajib.pradhan begin

TYPE REC_ACCOUNTS IS RECORD (
EXCISE_ENTITY_NUM EXCISE_DUTY_TEMP_DATA.EXCISE_ENTITY_NUM%TYPE,
EXCISE_BRN_CODE EXCISE_DUTY_TEMP_DATA.EXCISE_BRN_CODE%TYPE,
EXCISE_INTERNAL_ACNUM EXCISE_DUTY_TEMP_DATA.EXCISE_INTERNAL_ACNUM%TYPE,
EXCISE_PROD_CODE EXCISE_DUTY_TEMP_DATA.EXCISE_PROD_CODE%TYPE,
EXCISE_AC_TYPE EXCISE_DUTY_TEMP_DATA.EXCISE_AC_TYPE%TYPE,
EXCISE_MAX_BALANCE EXCISE_DUTY_TEMP_DATA.EXCISE_MAX_BALANCE%TYPE,
EXCISE_CURR_CODE EXCISE_DUTY_TEMP_DATA.EXCISE_CURR_CODE%TYPE,
PRODUCT_FOR_DEPOSITS PRODUCTS.PRODUCT_FOR_DEPOSITS%TYPE,
PRODUCT_FOR_LOANS PRODUCTS.PRODUCT_FOR_LOANS%TYPE,
PRODUCT_CONTRACT_ALLOWED PRODUCTS.PRODUCT_CONTRACT_ALLOWED%TYPE,
PRODUCT_FOR_RUN_ACS PRODUCTS.PRODUCT_FOR_RUN_ACS%TYPE,
ACNTBAL_AC_BAL ACNTBAL.ACNTBAL_AC_BAL%TYPE
);

TYPE TT_ACCOUNTS IS TABLE OF REC_ACCOUNTS INDEX BY PLS_INTEGER;

T_ACCOUNTS TT_ACCOUNTS;

TYPE REC_EDUTYVALUES IS RECORD(
EDUTY_CHARGE_CODE EDUTY.EDUTY_CHARGE_CODE%TYPE,
EDUTY_EXCDUTY_APPL EDUTY.EDUTY_EXCDUTY_APPL%TYPE,
EDUTY_BON_APPL EDUTY.EDUTY_BON_APPL%TYPE,
EDUTY_GLACC_CODE EDUTY.EDUTY_GLACC_CODE%TYPE,
CHGCD_CHG_TYPE CHGCD.CHGCD_CHG_TYPE%TYPE,
CHGCD_GLACCESS_CD CHGCD.CHGCD_DB_REFUND_HEAD%TYPE
);

TYPE TT_EDUTYVALUES IS TABLE OF REC_EDUTYVALUES INDEX BY VARCHAR2(100);

T_EDUTYVALUES TT_EDUTYVALUES;

W_EDUTY_CHARGE_CODE EDUTY.EDUTY_CHARGE_CODE%TYPE;
W_EDUTY_EXCDUTY_APPL EDUTY.EDUTY_EXCDUTY_APPL%TYPE;
W_EDUTY_BON_APPL EDUTY.EDUTY_BON_APPL%TYPE;
W_EDUTY_GLACC_CODE EDUTY.EDUTY_GLACC_CODE%TYPE;
W_CHGCD_CHG_TYPE CHGCD.CHGCD_CHG_TYPE%TYPE;
W_CHGCD_GLACCESS_CD CHGCD.CHGCD_DB_REFUND_HEAD%TYPE;

TYPE  TT_ACNTEXCAMT_ENTITY_NUM IS TABLE OF NUMBER(4) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_BRN_CODE IS TABLE OF NUMBER(6) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_INTERNAL_ACNUM IS TABLE OF NUMBER(14) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_PROCESS_DATE IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_FIN_YEAR IS TABLE OF NUMBER(4) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_EXCISE_AMT IS TABLE OF NUMBER(25,3) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_POST_TRAN_BRN IS TABLE OF NUMBER(6) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_POST_TRAN_DATE IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_POST_TRAN_BATCH IS TABLE OF NUMBER(7) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_ENTD_BY IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_ENTD_ON IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_LAST_MOD_BY IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_LAST_MOD_ON IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_AUTH_BY IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_AUTH_ON IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_REJ_BY IS TABLE OF VARCHAR2(10) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTEXCAMT_REJ_ON IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE  TT_ACNTSEXCISE_CONT_NUM IS TABLE OF NUMBER(19,2) INDEX BY PLS_INTEGER;
TYPE  TT_ACNTSEXCISE_MAX_BAL IS TABLE OF NUMBER(25,3) INDEX BY PLS_INTEGER;

T_ACNTEXCAMT_ENTITY_NUM TT_ACNTEXCAMT_ENTITY_NUM;
T_ACNTEXCAMT_BRN_CODE TT_ACNTEXCAMT_BRN_CODE;
T_ACNTEXCAMT_INTERNAL_ACNUM TT_ACNTEXCAMT_INTERNAL_ACNUM;
T_ACNTEXCAMT_PROCESS_DATE TT_ACNTEXCAMT_PROCESS_DATE;
T_ACNTEXCAMT_FIN_YEAR TT_ACNTEXCAMT_FIN_YEAR;
T_ACNTEXCAMT_EXCISE_AMT TT_ACNTEXCAMT_EXCISE_AMT;
T_ACNTEXCAMT_POST_TRAN_BRN TT_ACNTEXCAMT_POST_TRAN_BRN;
T_ACNTEXCAMT_POST_TRAN_DATE TT_ACNTEXCAMT_POST_TRAN_DATE;
T_ACNTEXCAMT_POST_TRAN_BATCH TT_ACNTEXCAMT_POST_TRAN_BATCH;
T_ACNTEXCAMT_ENTD_BY TT_ACNTEXCAMT_ENTD_BY;
T_ACNTEXCAMT_ENTD_ON TT_ACNTEXCAMT_ENTD_ON;
T_ACNTEXCAMT_LAST_MOD_BY TT_ACNTEXCAMT_LAST_MOD_BY;
T_ACNTEXCAMT_LAST_MOD_ON TT_ACNTEXCAMT_LAST_MOD_ON;
T_ACNTEXCAMT_AUTH_BY TT_ACNTEXCAMT_AUTH_BY;
T_ACNTEXCAMT_AUTH_ON TT_ACNTEXCAMT_AUTH_ON;
T_ACNTEXCAMT_REJ_BY TT_ACNTEXCAMT_REJ_BY;
T_ACNTEXCAMT_REJ_ON TT_ACNTEXCAMT_REJ_ON;
T_ACNTSEXCISE_CONT_NUM TT_ACNTSEXCISE_CONT_NUM;
T_ACNTSEXCISE_MAX_BAL TT_ACNTSEXCISE_MAX_BAL;


TYPE REC_EXCISE_TEMP_DATA IS RECORD(
EXCISE_ENTITY_NUM EXCISE_DUTY_TEMP_DATA.EXCISE_ENTITY_NUM%TYPE,
EXCISE_BRN_CODE EXCISE_DUTY_TEMP_DATA.EXCISE_BRN_CODE%TYPE,
EXCISE_INTERNAL_ACNUM EXCISE_DUTY_TEMP_DATA.EXCISE_INTERNAL_ACNUM%TYPE,
EXCISE_PROD_CODE EXCISE_DUTY_TEMP_DATA.EXCISE_PROD_CODE%TYPE,
EXCISE_AC_TYPE EXCISE_DUTY_TEMP_DATA.EXCISE_AC_TYPE%TYPE,
EXCISE_CURR_CODE EXCISE_DUTY_TEMP_DATA.EXCISE_CURR_CODE%TYPE,
EXCISE_MAX_BALANCE EXCISE_DUTY_TEMP_DATA.EXCISE_MAX_BALANCE%TYPE
);

TYPE TT_REC_EXCISE_TEMP_DATA IS TABLE OF REC_EXCISE_TEMP_DATA INDEX BY PLS_INTEGER;

T_REC_EXCISE_TEMP_DATA TT_REC_EXCISE_TEMP_DATA;

V_FIN_YEAR_START DATE;

V_SQL_STAT CLOB;

W_AC_MAX_BAL NUMBER(25,3);

W_AC_CURR_BAL NUMBER(25,3);

W_INDEX_NUMBER NUMBER(10):=0;

W_FIN_YEAR NUMBER(5);

W_USER_BRANCH VARCHAR2(15);

EX_DML_ERRORS            EXCEPTION;
PRAGMA EXCEPTION_INIT (EX_DML_ERRORS, -24381);
W_BULK_COUNT             NUMBER (10);
--- added by rajib.pradhan begin

  TYPE EXCISE_DUTY IS RECORD(
    BRN_CODE     NUMBER(6),
    ACCOUNT_NUM  NUMBER(14),
    PRODUCT_CODE NUMBER(4),
    ACTYPE       VARCHAR2(5),
    CURR_CODE    VARCHAR2(3));

  TYPE T_EXCISE_DUTY IS TABLE OF EXCISE_DUTY INDEX BY PLS_INTEGER;
  ---- W_EXCISE_DUTY T_EXCISE_DUTY;

  TYPE CONT_NUM IS RECORD(
    CONTRACT_NUM   NUMBER(8));

  TYPE T_CONT_NUM IS TABLE OF CONT_NUM INDEX BY PLS_INTEGER;
  W_CONT_NUM T_CONT_NUM;

  W_POST_ARRAY_INDEX NUMBER(8) DEFAULT 0;
  IDX1               NUMBER(8) DEFAULT 0; --ADDED BY MANOJ
  W_ERROR_CODE       VARCHAR2(10);
  W_ERROR            VARCHAR2(1000);
  W_BATCH_NUM        NUMBER(7);
  --V_TRAN_AMT         NUMBER(18, 3);
  V_ASON_DATE        DATE;
  SP_INTPUT_STRING   VARCHAR2(60) default 0;
  V_NARR1            VARCHAR2(35);
  V_NARR2            VARCHAR2(35);
  V_NARR3            VARCHAR2(35);
  LOANACNT           NUMBER(2); --ADDED BY MANOJ
  V_CURR_CODE        VARCHAR2(3);
  W_EXCISE_DUTY_AMT  NUMBER(18, 3) := 0;
  W_TOTAL_EXCISE_AMT NUMBER(18, 3) := 0;
  W_TOT_CONT_EXCISE_AMT NUMBER(18, 3) := 0;
  V_EXCISE_GL        VARCHAR2(15) := '';
  W_ENTITY_CODE      NUMBER(5) := 0;
  --V_COUNT            NUMBER(5) := 0;
  V_SQL_STRING       VARCHAR2(1000) := '';
  W_SQL              VARCHAR2(1000) := '';
  W_PROD_CODE        NUMBER(6);
  W_CURR_CODE        VARCHAR2(3);
  W_AC_NUMBER        NUMBER(14);
  DEPOSIT_CONTRACT_NUM NUMBER(8);
  W_USER_ID        VARCHAR2(8);
  W_AC_TYPE          VARCHAR2(5);
  PREV_CURR_CODE     VARCHAR2(3);
  I                  NUMBER(4);
  V_USER_EXCEPTION EXCEPTION;
  V_DEP_PROD       CHAR(1) := '';
  V_CONT_PROD      CHAR(1) := '';
  V_SKIPAC         CHAR(1) := '';
  ---------------------------------------------------------------------------------------------------------
  
  W_DUMMY_V                VARCHAR2 (10);
  W_DUMMY_N                NUMBER;
  W_DUMMY_D                DATE;
  W_AC_AUTH_BAL        NUMBER (18, 3);
  W_SHADOW_BAL_AVAILABLE NUMBER (18, 3) := 0;

  --To update the values in excise_amt

--- added by rajib.pradhan for get excise duty parameter value

PROCEDURE GET_EDUTYVALUES(P_ENTITY_NUM NUMBER, P_PROD_CODE NUMBER, P_AC_TYPE VARCHAR2 , P_CURR_CODE VARCHAR2) IS
V_INDEX VARCHAR2(100);
W_SQL VARCHAR2(3000);
BEGIN
  V_INDEX:=P_ENTITY_NUM||TRIM(P_PROD_CODE)||TRIM(P_AC_TYPE)||TRIM(P_CURR_CODE);

        IF T_EDUTYVALUES.EXISTS(V_INDEX)= TRUE THEN

            W_EDUTY_CHARGE_CODE:=T_EDUTYVALUES(V_INDEX).EDUTY_CHARGE_CODE;
            W_EDUTY_EXCDUTY_APPL :=T_EDUTYVALUES(V_INDEX).EDUTY_EXCDUTY_APPL;
            W_EDUTY_BON_APPL :=T_EDUTYVALUES(V_INDEX).EDUTY_BON_APPL;
            W_EDUTY_GLACC_CODE :=T_EDUTYVALUES(V_INDEX).EDUTY_GLACC_CODE;
            W_CHGCD_CHG_TYPE:= T_EDUTYVALUES(V_INDEX).CHGCD_CHG_TYPE;
            W_CHGCD_GLACCESS_CD:= T_EDUTYVALUES(V_INDEX).CHGCD_GLACCESS_CD;
        ELSE
         BEGIN
            W_SQL := 'SELECT E.EDUTY_CHARGE_CODE,E.EDUTY_EXCDUTY_APPL,E.EDUTY_BON_APPL,E.EDUTY_GLACC_CODE,
                             CHGCD_CHG_TYPE,DECODE(CHGCD_STAT_ALLOWED_FLG,1,CHGCD_STAT_TYPE,0,CHGCD_DB_REFUND_HEAD) CHGCD_GLACCESS_CD
                                FROM EDUTY E, CHGCD C
                              WHERE  C.CHGCD_CHARGE_CODE=E.EDUTY_CHARGE_CODE
                              AND E.EDUTY_ENTITY_NUM = :1
                              AND E.EDUTY_PROD_CODE = :2
                              AND E.EDUTY_AC_TYPE = :3
                              AND E.EDUTY_CURR_CODE = :4';
            EXECUTE IMMEDIATE W_SQL
              INTO W_EDUTY_CHARGE_CODE, W_EDUTY_EXCDUTY_APPL, W_EDUTY_BON_APPL, W_EDUTY_GLACC_CODE,W_CHGCD_CHG_TYPE,W_CHGCD_GLACCESS_CD
              USING P_ENTITY_NUM, P_PROD_CODE, P_AC_TYPE, P_CURR_CODE;
           EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 BEGIN
                    W_SQL := 'SELECT E.EDUTY_CHARGE_CODE,E.EDUTY_EXCDUTY_APPL,E.EDUTY_BON_APPL,E.EDUTY_GLACC_CODE,
                                     CHGCD_CHG_TYPE,DECODE(CHGCD_STAT_ALLOWED_FLG,1,CHGCD_STAT_TYPE,0,CHGCD_DB_REFUND_HEAD) CHGCD_GLACCESS_CD
                                    FROM EDUTY E, CHGCD C
                              WHERE  C.CHGCD_CHARGE_CODE=E.EDUTY_CHARGE_CODE
                                    AND E.EDUTY_ENTITY_NUM = :1
                                    AND EDUTY_PROD_CODE = :2
                                    AND EDUTY_AC_TYPE = :3 ';
                    EXECUTE IMMEDIATE W_SQL
                      INTO W_EDUTY_CHARGE_CODE, W_EDUTY_EXCDUTY_APPL, W_EDUTY_BON_APPL, W_EDUTY_GLACC_CODE,W_CHGCD_CHG_TYPE,W_CHGCD_GLACCESS_CD
                      USING P_ENTITY_NUM, P_PROD_CODE, P_AC_TYPE;
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                           BEGIN
                                W_SQL := 'SELECT E.EDUTY_CHARGE_CODE,E.EDUTY_EXCDUTY_APPL,E.EDUTY_BON_APPL,E.EDUTY_GLACC_CODE,
                                                 CHGCD_CHG_TYPE,DECODE(CHGCD_STAT_ALLOWED_FLG,1,CHGCD_STAT_TYPE,0,CHGCD_DB_REFUND_HEAD) CHGCD_GLACCESS_CD
                                                 FROM EDUTY E, CHGCD C
                                            WHERE  C.CHGCD_CHARGE_CODE=E.EDUTY_CHARGE_CODE
                                                 AND E.EDUTY_ENTITY_NUM = :1
                                                 AND  EDUTY_PROD_CODE = :2
                                                 AND EDUTY_CURR_CODE = :3
                                                 AND EDUTY_AC_TYPE = '||chr(39)||' '||chr(39)||'';

                                EXECUTE IMMEDIATE W_SQL
                                  INTO W_EDUTY_CHARGE_CODE, W_EDUTY_EXCDUTY_APPL, W_EDUTY_BON_APPL, W_EDUTY_GLACC_CODE,W_CHGCD_CHG_TYPE,W_CHGCD_GLACCESS_CD
                                  USING P_ENTITY_NUM, P_PROD_CODE, P_CURR_CODE;
                              EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                  BEGIN
                                    W_SQL := 'SELECT E.EDUTY_CHARGE_CODE,E.EDUTY_EXCDUTY_APPL,E.EDUTY_BON_APPL,E.EDUTY_GLACC_CODE,
                                                    CHGCD_CHG_TYPE,DECODE(CHGCD_STAT_ALLOWED_FLG,1,CHGCD_STAT_TYPE,0,CHGCD_DB_REFUND_HEAD) CHGCD_GLACCESS_CD
                                                    FROM EDUTY E, CHGCD C
                                                  WHERE  C.CHGCD_CHARGE_CODE=E.EDUTY_CHARGE_CODE
                                                    AND  E.EDUTY_ENTITY_NUM = :1
                                                    AND  EDUTY_PROD_CODE = :2
                                                    AND EDUTY_CURR_CODE = '||chr(39)||' '||chr(39)||'
                                                    AND EDUTY_AC_TYPE = '||chr(39)||' '||chr(39)||'';

                                    EXECUTE IMMEDIATE W_SQL
                                      INTO W_EDUTY_CHARGE_CODE, W_EDUTY_EXCDUTY_APPL, W_EDUTY_BON_APPL, W_EDUTY_GLACC_CODE,W_CHGCD_CHG_TYPE,W_CHGCD_GLACCESS_CD
                                      USING P_ENTITY_NUM, P_PROD_CODE;
                                    EXCEPTION
                                     WHEN NO_DATA_FOUND THEN
                                            W_ERROR    := 'Error in getting Excise duty values';
                                END;
                         END;
                    END;
           END;

            T_EDUTYVALUES(V_INDEX).EDUTY_CHARGE_CODE:= W_EDUTY_CHARGE_CODE;
            T_EDUTYVALUES(V_INDEX).EDUTY_EXCDUTY_APPL:=W_EDUTY_EXCDUTY_APPL;
            T_EDUTYVALUES(V_INDEX).EDUTY_BON_APPL:=W_EDUTY_BON_APPL;
            T_EDUTYVALUES(V_INDEX).EDUTY_GLACC_CODE:=W_EDUTY_GLACC_CODE;
            T_EDUTYVALUES(V_INDEX).CHGCD_CHG_TYPE:=W_CHGCD_CHG_TYPE;
            T_EDUTYVALUES(V_INDEX).CHGCD_GLACCESS_CD:=W_CHGCD_GLACCESS_CD;
       END IF;
END;



   PROCEDURE UPDATE_ACNTEXCISEAMT_VALUES(W_ENTITY_CODE IN NUMBER,
                                W_BRN_CODE IN NUMBER,P_ACTION BOOLEAN) IS
            BEGIN

                IF P_ACTION=FALSE THEN
                   BEGIN
                        W_INDEX_NUMBER:=W_INDEX_NUMBER+1;

                        T_ACNTEXCAMT_ENTITY_NUM(W_INDEX_NUMBER):=W_ENTITY_CODE;
                        T_ACNTEXCAMT_BRN_CODE(W_INDEX_NUMBER):=W_BRN_CODE;
                        T_ACNTEXCAMT_INTERNAL_ACNUM(W_INDEX_NUMBER):=W_AC_NUMBER;
                        T_ACNTEXCAMT_PROCESS_DATE(W_INDEX_NUMBER):=V_ASON_DATE;
                        T_ACNTEXCAMT_FIN_YEAR(W_INDEX_NUMBER):=W_FIN_YEAR;
                        T_ACNTEXCAMT_EXCISE_AMT(W_INDEX_NUMBER):=W_TOT_CONT_EXCISE_AMT;
                        T_ACNTEXCAMT_POST_TRAN_BRN(W_INDEX_NUMBER):=W_USER_BRANCH;
                        T_ACNTEXCAMT_POST_TRAN_DATE(W_INDEX_NUMBER):=V_ASON_DATE;
                        T_ACNTEXCAMT_ENTD_BY(W_INDEX_NUMBER):=W_USER_ID;
                        T_ACNTEXCAMT_ENTD_ON(W_INDEX_NUMBER):=V_ASON_DATE;
                        T_ACNTSEXCISE_MAX_BAL(W_INDEX_NUMBER):=W_AC_MAX_BAL;

                       EXCEPTION
                            WHEN OTHERS THEN
                                    W_ERROR:='ERROR IN VALUE ASSIGN '||SUBSTR(SQLERRM,1,100)||'ACCOUNT '||W_AC_NUMBER;
                    END;

                  ELSE
                      FORALL IND IN T_ACNTEXCAMT_INTERNAL_ACNUM.FIRST .. T_ACNTEXCAMT_INTERNAL_ACNUM.LAST
                          INSERT INTO ACNTEXCISEAMT
                                                    (ACNTEXCAMT_ENTITY_NUM,
                                                    ACNTEXCAMT_BRN_CODE,
                                                    ACNTEXCAMT_INTERNAL_ACNUM,
                                                    ACNTEXCAMT_PROCESS_DATE,
                                                    ACNTEXCAMT_FIN_YEAR,
                                                    ACNTEXCAMT_EXCISE_AMT,
                                                    ACNTEXCAMT_POST_TRAN_BRN,
                                                    ACNTEXCAMT_POST_TRAN_DATE,
                                                    ACNTEXCAMT_POST_TRAN_BATCH_NUM,
                                                    ACNTEXCAMT_ENTD_BY,
                                                    ACNTEXCAMT_ENTD_ON,
                                                    ACNTEXCAMT_LAST_MOD_BY,
                                                    ACNTEXCAMT_LAST_MOD_ON,
                                                    ACNTEXCAMT_AUTH_BY,
                                                    ACNTEXCAMT_AUTH_ON,
                                                    ACNTEXCAMT_REJ_BY,
                                                    ACNTEXCAMT_REJ_ON,
                                                    ACNTSEXCISE_MAX_BAL)
                                     VALUES
                                    ( T_ACNTEXCAMT_ENTITY_NUM(IND) ,
                                      T_ACNTEXCAMT_BRN_CODE(IND),
                                      T_ACNTEXCAMT_INTERNAL_ACNUM(IND),
                                      T_ACNTEXCAMT_PROCESS_DATE(IND),
                                      T_ACNTEXCAMT_FIN_YEAR(IND),
                                      T_ACNTEXCAMT_EXCISE_AMT(IND),
                                      T_ACNTEXCAMT_POST_TRAN_BRN(IND),
                                      T_ACNTEXCAMT_POST_TRAN_DATE(IND),
                                      W_BATCH_NUM,
                                      W_USER_ID,
                                      V_ASON_DATE,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      T_ACNTSEXCISE_MAX_BAL(IND));
                   T_ACNTEXCAMT_ENTITY_NUM.DELETE;
                   T_ACNTEXCAMT_BRN_CODE.DELETE;
                   T_ACNTEXCAMT_INTERNAL_ACNUM.DELETE;
                   T_ACNTEXCAMT_PROCESS_DATE.DELETE;
                   T_ACNTEXCAMT_FIN_YEAR.DELETE;
                   T_ACNTEXCAMT_EXCISE_AMT.DELETE;
                   T_ACNTEXCAMT_POST_TRAN_BRN.DELETE;
                   T_ACNTEXCAMT_POST_TRAN_DATE.DELETE;
                   T_ACNTSEXCISE_MAX_BAL.DELETE;
                END IF;

       END UPDATE_ACNTEXCISEAMT_VALUES;
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE UPDATE_ACNTEXCISEAMT_BATCHNUM(W_ENTITY_CODE IN NUMBER,
                                W_BRN_CODE IN NUMBER,W_BATCH_NUM IN NUMBER) IS
       BEGIN

                      UPDATE ACNTEXCISEAMT
            SET ACNTEXCAMT_POST_TRAN_BATCH_NUM = W_BATCH_NUM
            WHERE
            ACNTEXCAMT_ENTITY_NUM = W_ENTITY_CODE AND
            ACNTEXCAMT_BRN_CODE = W_BRN_CODE AND
            ACNTEXCAMT_POST_TRAN_DATE = V_ASON_DATE AND
            ACNTEXCAMT_POST_TRAN_BRN = PKG_PB_GLOBAL.FN_GET_USER_BRN_CODE(PKG_ENTITY.FN_GET_ENTITY_CODE,W_USER_ID) AND
            ACNTEXCAMT_POST_TRAN_BATCH_NUM IS NULL;

       END UPDATE_ACNTEXCISEAMT_BATCHNUM;
  ---------------------------------------------------------------------------------------------------------

  PROCEDURE MOVE_TO_TRANREC_CREDIT(P_BRN_CODE IN NUMBER,
                                   P_CURR_CODE IN VARCHAR2,
                                   P_TRAN_AMT IN NUMBER, P_ASON_DATE DATE,
                                   P_NARR1 IN VARCHAR2, P_NARR2 IN VARCHAR2,
                                   P_NARR3 IN VARCHAR2) IS

  BEGIN

    --CREDIT EXCISE PYABLE GL

    W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_BRN_CODE := P_BRN_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_GLACC_CODE := V_EXCISE_GL;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DB_CR_FLG := 'C';
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_CURR_CODE := P_CURR_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_AMOUNT := P_TRAN_AMT;
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
                                  P_CONT_NUM IN NUMBER,
                                  P_CURR_CODE IN VARCHAR2,
                                  P_TRAN_AMT IN NUMBER, P_ASON_DATE IN DATE,
                                  P_NARR1 IN VARCHAR2, P_NARR2 IN VARCHAR2,
                                  P_NARR3 IN VARCHAR2) IS


 BEGIN

    --DEBIT ACCOUNT

    W_POST_ARRAY_INDEX := W_POST_ARRAY_INDEX + 1;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DATE_OF_TRAN := P_ASON_DATE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_INTERNAL_ACNUM := P_AC_NUM;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_CONTRACT_NUM := P_CONT_NUM;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_DB_CR_FLG := 'D';
  --Added by Manoj 17dec2013 beg
   IF LOANACNT <> 0 THEN
        PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_AMT_BRKUP := '1';
        IDX1 := IDX1 + 1;
        PKG_AUTOPOST.PV_TRAN_ADV_REC(IDX1).TRANADV_BATCH_SL_NUM := W_POST_ARRAY_INDEX;
        PKG_AUTOPOST.PV_TRAN_ADV_REC(IDX1).TRANADV_PRIN_AC_AMT := 0;
        PKG_AUTOPOST.PV_TRAN_ADV_REC(IDX1).TRANADV_INTRD_AC_AMT := 0;
        PKG_AUTOPOST.PV_TRAN_ADV_REC(IDX1).TRANADV_CHARGE_AC_AMT := P_TRAN_AMT;
   END IF;
   --Added by Manoj 17dec2013 end
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_CURR_CODE := P_CURR_CODE;
    PKG_AUTOPOST.PV_TRAN_REC(W_POST_ARRAY_INDEX).TRAN_AMOUNT := P_TRAN_AMT;
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
    PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_TABLE := 'EXCISE';
    PKG_AUTOPOST.PV_TRANBAT.TRANBAT_SOURCE_KEY   := P_BRN_CODE;
    PKG_AUTOPOST.PV_TRANBAT.TRANBAT_NARR_DTL1    := 'Excise Duty';

  EXCEPTION
    WHEN OTHERS THEN
      W_ERROR := 'ERROR IN SET_TRANBAT_VALUES ' || P_BRN_CODE ||
                 SUBSTR(SQLERRM, 1, 500);
      RAISE V_USER_EXCEPTION;
  END SET_TRANBAT_VALUES;

  ---------------------------------------------------------------------------------------------------------
  PROCEDURE POST_TRANSACTION IS
  BEGIN
    PKG_APOST_INTERFACE.SP_POST_SODEOD_BATCH((PKG_ENTITY.FN_GET_ENTITY_CODE),
                                             'A', W_POST_ARRAY_INDEX,IDX1, --Added tranadv details Manoj 17dec2013
                                             W_ERROR_CODE, W_ERROR,
                                             W_BATCH_NUM);

    PKG_AUTOPOST.PV_TRAN_REC.DELETE;

    IF (W_ERROR_CODE <> '0000') THEN
      W_ERROR := 'ERROR IN POST_TRANSACTION for Excise Duty-  '||W_AC_NUMBER ||
                 FN_GET_AUTOPOST_ERR_MSG(PKG_ENTITY.FN_GET_ENTITY_CODE);
      RAISE V_USER_EXCEPTION;
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
    IDX1 := 0; -- Added by Manoj 19/dec/2013
  END AUTOPOST_ENTRIES;
  ---------------------------------------------------------------------------------------------------------

  PROCEDURE INIT_VALUES IS
  BEGIN

    W_EXCISE_DUTY_AMT  := 0;
    --W_TOTAL_EXCISE_AMT := 0;
    --V_EXCISE_GL        := '';
    V_SQL_STRING       := '';
    W_SQL              := '';
    DEPOSIT_CONTRACT_NUM := 0;
    I := 1;
    LOANACNT:=0;
    W_CONT_NUM.DELETE;

  END;
  ------------------------------------------------------------------------------------------------------------
  PROCEDURE GET_EXCISE_DUTY_VALUES(P_ENTITY_NUM NUMBER, P_AC_NUMBER NUMBER,P_CURR_CODE VARCHAR2,P_AC_BAL NUMBER, P_CHG_CODE VARCHAR2,P_CHG_TYPE VARCHAR2 ) IS
    W_EXCDUTY_APPL     CHAR(1);
    W_BONUS_APPL       CHAR(1);
    W_BONUS_GLACC_CODE VARCHAR2(15);
    W_CHARGE_AMOUNT    NUMBER(18, 3);
    W_ERR_MSG          VARCHAR2(1000);
    W_CHARGE_CURR_CODE VARCHAR2(100);
    --W_CHARGE_AMOUNT NUMBER(25,3);
    W_SERVICE_AMOUNT NUMBER(25,3);
    W_SERVICE_STAX_AMOUNT  NUMBER(25,3);
     W_SERVICE_ADDN_AMOUNT  NUMBER(25,3);
     W_SERVICE_CESS_AMOUNT  NUMBER(25,3);
  BEGIN
   -- LOANACNT:=0;
    /* remove by rajib.pradhan for geting excise dity amount .......
    SP_INTPUT_STRING := W_AC_NUMBER||' '||W_PROD_CODE||'$$'||W_AC_TYPE||'$$'||W_CURR_CODE;
    SP_GET_EXDUTY(W_ENTITY_CODE, W_PROD_CODE, W_CURR_CODE, W_AC_NUMBER,
                  W_AC_TYPE, W_EXCDUTY_APPL, W_BONUS_APPL, V_EXCISE_GL,
                  W_BONUS_GLACC_CODE, W_CHARGE_AMOUNT, W_ERR_MSG,DEPOSIT_CONTRACT_NUM);
    remove by rajib.pradhan for geting excise dity amount ....... */

    ---- added by rajib.pradhan for get excise duty amount
     IF W_EDUTY_EXCDUTY_APPL='1' THEN
        PKG_CHARGES.SP_GET_CHARGES(P_ENTITY_NUM,
                                         P_AC_NUMBER,
                                         P_CURR_CODE,
                                         P_AC_BAL,
                                         P_CHG_CODE,
                                         P_CHG_TYPE,
                                         W_CHARGE_CURR_CODE,
                                         W_CHARGE_AMOUNT,
                                         W_SERVICE_AMOUNT,
                                         W_SERVICE_STAX_AMOUNT,
                                         W_SERVICE_ADDN_AMOUNT,
                                         W_SERVICE_CESS_AMOUNT,
                                         W_ERR_MSG);

       IF W_CHARGE_AMOUNT<=W_AC_CURR_BAL OR LOANACNT='1' THEN   ------ When account current balance is less the ED amount or account is Loan.
       V_EXCISE_GL:=W_CHGCD_GLACCESS_CD;
       W_EXCISE_DUTY_AMT:=W_CHARGE_AMOUNT;
       ELSE
       W_EXCISE_DUTY_AMT:=0;
       END IF;
      ELSE
        W_CHARGE_AMOUNT:=0;
    END IF;
    ---- added by rajib.pradhan for get excise duty amount
        --
        --    IF W_EXCDUTY_APPL = '1' THEN
        --      W_EXCISE_DUTY_AMT := W_CHARGE_AMOUNT;
        --    ELSE
        --      W_EXCISE_DUTY_AMT := 0;
        --    END IF;

  END GET_EXCISE_DUTY_VALUES;

  PROCEDURE PROCESS_EXCISE_DUTY(W_ENTITY_CODE IN NUMBER,
                                W_BRN_CODE IN NUMBER) IS
TYPE RECORD_CURSOR IS REF CURSOR;

CURSOR_ACCOUNTS    RECORD_CURSOR;

V_MIG_BRANCH NUMBER(8);
  BEGIN

    --- FOR MIGRATION MAXIMUM BALANCE CHECKING

    BEGIN
            SELECT COUNT(BRANCH_CODE)
            INTO V_MIG_BRANCH
            FROM MIG_DETAIL
            WHERE BRANCH_CODE=W_BRN_CODE
            AND MIG_END_DATE BETWEEN V_FIN_YEAR_START AND V_ASON_DATE;

            IF V_MIG_BRANCH>=1 THEN

              ----- CHECKING MIGRATION MAXIMUM BALANCE IS GRATTER THEN TRANSACTION MAXIMUM BALANCE OR NOT

               V_SQL_STAT:='SELECT EXCISE_ENTITY_NUM,
                                 EXCISE_BRN_CODE,
                                 EXCISE_INTERNAL_ACNUM,
                                 EXCISE_PROD_CODE,
                                 EXCISE_AC_TYPE,
                                 (CASE WHEN NVL(ACBALH_AC_BAL,0)>EXCISE_MAX_BALANCE THEN ACBALH_AC_BAL ELSE EXCISE_MAX_BALANCE END) EXCISE_MAX_BALANCE,
                                 EXCISE_CURR_CODE,
                                 PRODUCT_FOR_DEPOSITS,
                                 PRODUCT_FOR_LOANS,
                                 PRODUCT_CONTRACT_ALLOWED,
                                 PRODUCT_FOR_RUN_ACS,
                                 ABS(ACNTBAL_AC_BAL)
                                 FROM(
                        SELECT EXCISE_ENTITY_NUM,
                                 EXCISE_BRN_CODE,
                                 EXCISE_INTERNAL_ACNUM,
                                 EXCISE_PROD_CODE,
                                 EXCISE_AC_TYPE,
                                 EXCISE_MAX_BALANCE,
                                 EXCISE_CURR_CODE,
                                 PRODUCT_FOR_DEPOSITS,
                                 PRODUCT_FOR_LOANS,
                                 PRODUCT_CONTRACT_ALLOWED,
                                 PRODUCT_FOR_RUN_ACS,
                                 ACNTBAL_AC_BAL
                            FROM PRODUCTS, EXCISE_DUTY_TEMP_DATA, ACNTBAL
                            WHERE EXCISE_BRN_CODE=:P_BRANCH_CODE
                                 AND EXCISE_ENTITY_NUM=:P_ENTITY_NUMBER
                                 AND PRODUCT_CODE = EXCISE_PROD_CODE
                                 AND EXCISE_INTERNAL_ACNUM = ACNTBAL_INTERNAL_ACNUM
                                 --AND ACNTBAL_AC_BAL<>0
                                 ) A LEFT OUTER JOIN (SELECT MAX(ACBALH_AC_BAL) ACBALH_AC_BAL, ACBALH_INTERNAL_ACNUM
                        FROM ACBALASONHIST_MAX
                        GROUP BY ACBALH_INTERNAL_ACNUM) MIG_DATA
                        ON (A.EXCISE_INTERNAL_ACNUM=MIG_DATA.ACBALH_INTERNAL_ACNUM)';
               ELSE

                V_SQL_STAT:='SELECT EXCISE_ENTITY_NUM,
                                         EXCISE_BRN_CODE,
                                         EXCISE_INTERNAL_ACNUM,
                                         EXCISE_PROD_CODE,
                                         EXCISE_AC_TYPE,
                                         EXCISE_MAX_BALANCE,
                                         EXCISE_CURR_CODE,
                                         PRODUCT_FOR_DEPOSITS,
                                         PRODUCT_FOR_LOANS,
                                         PRODUCT_CONTRACT_ALLOWED,
                                         PRODUCT_FOR_RUN_ACS,
                                         ABS(ACNTBAL_AC_BAL)
                                    FROM PRODUCTS, EXCISE_DUTY_TEMP_DATA, ACNTBAL
                                    WHERE EXCISE_BRN_CODE=:P_BRANCH_CODE
                                         AND EXCISE_ENTITY_NUM=:P_ENTITY_NUMBER
                                         AND PRODUCT_CODE = EXCISE_PROD_CODE
                                         AND EXCISE_INTERNAL_ACNUM = ACNTBAL_INTERNAL_ACNUM
                                         --AND ACNTBAL_AC_BAL<>0
                                    ORDER BY EXCISE_CURR_CODE';
            END IF;

    END;

       OPEN CURSOR_ACCOUNTS FOR V_SQL_STAT USING  W_BRN_CODE,W_ENTITY_CODE;

         LOOP
         FETCH CURSOR_ACCOUNTS
         BULK COLLECT INTO T_ACCOUNTS LIMIT 100000;
            IF T_ACCOUNTS.COUNT > 0 THEN
                FOR IDX IN T_ACCOUNTS.FIRST .. T_ACCOUNTS.LAST LOOP

                    INIT_VALUES;

                   IF T_ACCOUNTS(IDX).PRODUCT_FOR_LOANS ='1' AND T_ACCOUNTS(IDX).PRODUCT_FOR_DEPOSITS<>'1' THEN
                    LOANACNT:='1';
                   END IF;

                    IF  T_ACCOUNTS(IDX).PRODUCT_FOR_DEPOSITS='1' AND T_ACCOUNTS(IDX).PRODUCT_FOR_LOANS ='0' AND T_ACCOUNTS(IDX).PRODUCT_CONTRACT_ALLOWED='1' AND
                    T_ACCOUNTS(IDX).PRODUCT_FOR_RUN_ACS='0' THEN
                       BEGIN
                            W_SQL := ' SELECT P.PBDCONT_CONT_NUM
                            FROM PBDCONTRACT P
                            WHERE P.PBDCONT_ENTITY_NUM = :1 AND P.PBDCONT_DEP_AC_NUM = :2 AND P.PBDCONT_DEP_CURR = :3
                            AND P.PBDCONT_AUTH_ON IS NOT NULL AND  P.PBDCONT_CLOSURE_DATE IS NULL' ;

                            EXECUTE IMMEDIATE W_SQL BULK COLLECT
                            INTO W_CONT_NUM
                            USING  W_ENTITY_CODE,T_ACCOUNTS(IDX).EXCISE_INTERNAL_ACNUM, T_ACCOUNTS(IDX).EXCISE_CURR_CODE ;

                            IF W_CONT_NUM.COUNT=0 THEN
                                GOTO SKIP_ACCOUNT ;
                               ELSE
                               I := W_CONT_NUM.COUNT;
                            END IF;

                       END;

                    END IF;

                IF IDX = 1 THEN
                       PREV_CURR_CODE := T_ACCOUNTS(IDX).EXCISE_CURR_CODE;
                    ELSE
                       PREV_CURR_CODE := W_CURR_CODE;
                END IF;

                W_PROD_CODE    := T_ACCOUNTS(IDX).EXCISE_PROD_CODE;
                W_AC_NUMBER    := T_ACCOUNTS(IDX).EXCISE_INTERNAL_ACNUM;
                W_AC_TYPE         := T_ACCOUNTS(IDX).EXCISE_AC_TYPE;
                W_CURR_CODE    := T_ACCOUNTS(IDX).EXCISE_CURR_CODE;
                W_AC_MAX_BAL   :=T_ACCOUNTS(IDX).EXCISE_MAX_BALANCE;
                W_AC_CURR_BAL :=T_ACCOUNTS(IDX).ACNTBAL_AC_BAL;
                
                  BEGIN
                     SELECT 1
                       INTO W_SHADOW_BAL_AVAILABLE
                       FROM SHBAL S
                      WHERE     S.SHBAL_ENTITY_NUM = W_ENTITY_CODE
                            AND S.SHBAL_INTERNAL_ACNUM = W_AC_NUMBER
                            AND S.SHBAL_ACCT_CCY = W_CURR_CODE
                            AND SHBAL_BAL <> 0;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        W_SHADOW_BAL_AVAILABLE := 0;
                  END;

                  IF W_SHADOW_BAL_AVAILABLE = 1 THEN
                
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
                                   W_AC_CURR_BAL,
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
                           W_AC_CURR_BAL:=0;
                        END IF;
                     END;
                 
                 END IF;
                 
                
                GET_EDUTYVALUES(W_ENTITY_CODE,W_PROD_CODE,W_AC_TYPE,W_CURR_CODE);

                         IF W_CURR_CODE = PREV_CURR_CODE THEN
                             FOR J IN 1 .. I LOOP
                                    IF W_CONT_NUM.COUNT <> 0 THEN
                                         DEPOSIT_CONTRACT_NUM := W_CONT_NUM(J).CONTRACT_NUM;
                                         GET_EXCISE_DUTY_VALUES(W_ENTITY_CODE,W_AC_NUMBER,W_CURR_CODE,W_AC_MAX_BAL,W_EDUTY_CHARGE_CODE,W_CHGCD_CHG_TYPE);
                                    --IF W_CONT_NUM(J).CONTRACT_NUM <> 0 THEN   -- Processing is required for RD Accounts also Avinash K 08OCT2012
                                          IF W_EXCISE_DUTY_AMT <> 0 AND (W_AC_CURR_BAL >=W_EXCISE_DUTY_AMT OR LOANACNT='1') THEN
                                            --V_CURR_CODE        := W_EXCISE_DUTY(IDX).EXCISE_CURR_CODE;
                                            W_TOTAL_EXCISE_AMT := W_TOTAL_EXCISE_AMT + W_EXCISE_DUTY_AMT;
                                            W_TOT_CONT_EXCISE_AMT := W_TOT_CONT_EXCISE_AMT + W_EXCISE_DUTY_AMT;
                                            MOVE_TO_TRANREC_DEBIT(W_AC_NUMBER,
                                                                  DEPOSIT_CONTRACT_NUM,
                                                                  W_CURR_CODE,
                                                                  W_EXCISE_DUTY_AMT, V_ASON_DATE, V_NARR1,
                                                                  V_NARR2, V_NARR3);

                                           ---UPDATE_ACNTEXCISEAMT_VALUES(W_ENTITY_CODE ,W_BRN_CODE,FALSE);
                                           END IF;
                                    --END IF; -- Processing is required for RD Accounts also Avinash K 08OCT2012
                                    ELSE
                                        GET_EXCISE_DUTY_VALUES(W_ENTITY_CODE,W_AC_NUMBER,W_CURR_CODE,W_AC_MAX_BAL,W_EDUTY_CHARGE_CODE,W_CHGCD_CHG_TYPE);
                                            IF W_EXCISE_DUTY_AMT <> 0 AND (W_AC_CURR_BAL >=W_EXCISE_DUTY_AMT OR LOANACNT='1') THEN
                                            --V_CURR_CODE        := W_EXCISE_DUTY(IDX).CURR_CODE;
                                            W_TOTAL_EXCISE_AMT := W_TOTAL_EXCISE_AMT + W_EXCISE_DUTY_AMT;
                                            W_TOT_CONT_EXCISE_AMT := W_TOT_CONT_EXCISE_AMT + W_EXCISE_DUTY_AMT;
                                            MOVE_TO_TRANREC_DEBIT(W_AC_NUMBER,
                                                                  DEPOSIT_CONTRACT_NUM,
                                                                  W_CURR_CODE,
                                                                  W_EXCISE_DUTY_AMT, V_ASON_DATE, V_NARR1,
                                                                  V_NARR2, V_NARR3);
                                            END IF;
                                    END IF;
                            END LOOP;
                        ELSE

                          SET_TRAN_KEY_VALUES(W_BRN_CODE);
                          SET_TRANBAT_VALUES(W_BRN_CODE);
                          V_NARR1 := 'Excise Duty ';
                          V_NARR2 := NULL;
                          V_NARR3 := NULL;
                         --  V_CURR_CODE    := W_EXCISE_DUTY(IDX).CURR_CODE;
                          --V_CURR_CODE := PREV_CURR_CODE;
                          W_CURR_CODE:= PREV_CURR_CODE;
                          IF W_TOTAL_EXCISE_AMT <> 0 THEN
                          MOVE_TO_TRANREC_CREDIT(W_BRN_CODE, W_CURR_CODE,
                                                 W_TOTAL_EXCISE_AMT, V_ASON_DATE, V_NARR1,
                                                 V_NARR2, V_NARR3);
                          AUTOPOST_ENTRIES;
                          V_EXCISE_GL        := '';
                          UPDATE_ACNTEXCISEAMT_VALUES(W_ENTITY_CODE,W_BRN_CODE,TRUE);
                          W_BATCH_NUM := '';
                          END IF;
                              W_TOTAL_EXCISE_AMT := 0;
                          --UPDATE_ACNTEXCISEAMT_VALUES(W_ENTITY_CODE ,W_BRN_CODE,W_BATCH_NUM,FALSE);
                        FOR J IN 1 .. I LOOP
                        IF V_SKIPAC <> '1' THEN
                        IF W_CONT_NUM.COUNT <> 0 THEN
                        DEPOSIT_CONTRACT_NUM := W_CONT_NUM(J).CONTRACT_NUM;
                        GET_EXCISE_DUTY_VALUES(W_ENTITY_CODE,W_AC_NUMBER,W_CURR_CODE,W_AC_MAX_BAL,W_EDUTY_CHARGE_CODE,W_CHGCD_CHG_TYPE);
                        --IF W_CONT_NUM(J).CONTRACT_NUM <> 0 THEN -- Processing is required for RD Accounts also Avinash K 08OCT2012
                          W_TOTAL_EXCISE_AMT := W_TOTAL_EXCISE_AMT + W_EXCISE_DUTY_AMT;
                          W_TOT_CONT_EXCISE_AMT := W_TOT_CONT_EXCISE_AMT + W_EXCISE_DUTY_AMT;
                         IF W_EXCISE_DUTY_AMT <> 0 AND (W_AC_CURR_BAL >=W_EXCISE_DUTY_AMT OR LOANACNT='1') THEN
                          MOVE_TO_TRANREC_DEBIT(W_AC_NUMBER,
                                                 DEPOSIT_CONTRACT_NUM ,
                                                W_CURR_CODE,
                                                W_EXCISE_DUTY_AMT, V_ASON_DATE, V_NARR1,
                                                V_NARR2, V_NARR3);
                          END IF;
                          --END IF; -- Processing is required for RD Accounts also Avinash K 08OCT2012
                          ELSE
                          GET_EXCISE_DUTY_VALUES(W_ENTITY_CODE,W_AC_NUMBER,W_CURR_CODE,W_AC_MAX_BAL,W_EDUTY_CHARGE_CODE,W_CHGCD_CHG_TYPE);
                          W_TOTAL_EXCISE_AMT := W_TOTAL_EXCISE_AMT + W_EXCISE_DUTY_AMT;
                          W_TOT_CONT_EXCISE_AMT := W_TOT_CONT_EXCISE_AMT + W_EXCISE_DUTY_AMT;
                         IF W_EXCISE_DUTY_AMT <> 0 AND (W_AC_CURR_BAL >=W_EXCISE_DUTY_AMT OR LOANACNT='1') THEN
                          MOVE_TO_TRANREC_DEBIT(W_AC_NUMBER,
                                                 DEPOSIT_CONTRACT_NUM ,
                                                W_CURR_CODE,
                                                W_EXCISE_DUTY_AMT, V_ASON_DATE, V_NARR1,
                                                V_NARR2, V_NARR3);
                          END IF;
                          END IF;
                          END IF;
                          END LOOP;
                       END IF;

                          IF V_SKIPAC <> '1' THEN -- ADDED BY MANOJ
                           UPDATE_ACNTEXCISEAMT_VALUES(W_ENTITY_CODE ,W_BRN_CODE,FALSE);
                          END IF; --ADDED BY MANOJ
                            W_TOT_CONT_EXCISE_AMT := 0;

                          IF IDX = T_ACCOUNTS.COUNT THEN
                          -- FOR THE LAST CURRENCY CODE CREDIT LEG IS HANDLED HERE
                          SET_TRAN_KEY_VALUES(W_BRN_CODE);
                          SET_TRANBAT_VALUES(W_BRN_CODE);
                          V_NARR1 := 'Excise Duty ';
                          V_NARR2 := NULL;
                          V_NARR3 := NULL;
                          --V_CURR_CODE := PREV_CURR_CODE;
                                  IF W_TOTAL_EXCISE_AMT <> 0 THEN
                                  MOVE_TO_TRANREC_CREDIT(W_BRN_CODE, PREV_CURR_CODE,
                                                         W_TOTAL_EXCISE_AMT, V_ASON_DATE, V_NARR1,
                                                         V_NARR2, V_NARR3);
                                  AUTOPOST_ENTRIES;
                                  V_EXCISE_GL        := '';
                                  UPDATE_ACNTEXCISEAMT_VALUES(W_ENTITY_CODE,W_BRN_CODE,TRUE);
                                  W_BATCH_NUM := '';
                                  PREV_CURR_CODE := '';
                                  W_TOTAL_EXCISE_AMT := 0;
                                  END IF;
                          END IF;
                      <<SKIP_ACCOUNT>>
                      V_SKIPAC := '';
                      V_DEP_PROD := '';
                      V_CONT_PROD := '';
               END LOOP;
            END IF ;
         EXIT WHEN CURSOR_ACCOUNTS%NOTFOUND;
         END LOOP;

         T_ACCOUNTS.DELETE;
    EXCEPTION
    WHEN OTHERS THEN
      IF TRIM(W_ERROR) IS NULL THEN
        W_ERROR := SUBSTR('ERROR IN PKG_EXCISE DUTY '||SP_INTPUT_STRING|| SQLERRM, 1, 100)||'ACCOUNT '||W_AC_NUMBER;
      END IF;
      PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
      PKG_PB_GLOBAL.DETAIL_ERRLOG(W_ENTITY_CODE, 'E',
                                  PKG_EODSOD_FLAGS.PV_ERROR_MSG, ' ', 0);
      PKG_PB_GLOBAL.DETAIL_ERRLOG(W_ENTITY_CODE, 'E',
                                  SUBSTR(SQLERRM, 1, 1000), ' ', 0);
      PKG_PB_GLOBAL.DETAIL_ERRLOG(W_ENTITY_CODE, 'X', W_ENTITY_CODE, ' ', 0);

  END PROCESS_EXCISE_DUTY;

  PROCEDURE START_BRNWISE(V_ENTITY_NUM IN NUMBER,
                          P_BRN_CODE IN NUMBER DEFAULT 0) IS
    L_BRN_CODE       NUMBER(6);

  BEGIN
    PKG_ENTITY.SP_SET_ENTITY_CODE(V_ENTITY_NUM);
    W_ENTITY_CODE := PKG_ENTITY.FN_GET_ENTITY_CODE;
    PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE(W_ENTITY_CODE, P_BRN_CODE);
    V_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
    W_USER_ID :=  PKG_EODSOD_FLAGS.PV_USER_ID  ;
    V_FIN_YEAR_START:= PKG_PB_GLOBAL.SP_GET_FIN_YEAR_START(V_ENTITY_NUM);
    W_USER_BRANCH:=PKG_PB_GLOBAL.FN_GET_USER_BRN_CODE(V_ENTITY_NUM,W_USER_ID);
    W_FIN_YEAR:=GETFINYEAR(V_ASON_DATE);
    FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT LOOP
     BEGIN
      L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN(IDX).LN_BRN_CODE;
      IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED(W_ENTITY_CODE,
                                                     L_BRN_CODE) = FALSE THEN
       W_TOTAL_EXCISE_AMT := 0;
        PROCESS_EXCISE_DUTY(W_ENTITY_CODE, L_BRN_CODE);
        DBMS_OUTPUT.PUT_LINE ('ERROR '||PKG_EODSOD_FLAGS.PV_ERROR_MSG);
        IF TRIM(PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL THEN
          PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN(PKG_ENTITY.FN_GET_ENTITY_CODE,
                                                          L_BRN_CODE);
        END IF;
        PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS(PKG_ENTITY.FN_GET_ENTITY_CODE);
      END IF;

      END;
    END LOOP;
      EXCEPTION
            WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(-20100,'ERROR IN EXCIESE DUTY FOR BRANCH '||L_BRN_CODE||SQLERRM);
  END START_BRNWISE;

END PKG_EXCISE_DUTY;
/

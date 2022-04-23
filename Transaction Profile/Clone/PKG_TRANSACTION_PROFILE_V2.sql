/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE PKG_TRANSACTION_PROFILE_V2
IS
   PROCEDURE START_BRNWISE (V_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0);
END PKG_TRANSACTION_PROFILE_V2;
/

/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE BODY PKG_TRANSACTION_PROFILE_V2
IS
   TYPE TRAN_VALUES IS RECORD
   (
      ACCOUNT_NUM    NUMBER (14),
      CONTRACT_NUM   NUMBER (6),
      PRODUCT_CODE   NUMBER (4),
      CURR_CODE      VARCHAR2 (3),
      TRAN_FLAG      CHAR (1),
      TRAN_TYPE      CHAR (1),
      TRAN_AMOUNT    NUMBER (18, 3),
      TRAN_BC_AMT    NUMBER (18, 3)
   );

   TYPE T_TRAN_VALUES IS TABLE OF TRAN_VALUES
      INDEX BY PLS_INTEGER;

   W_TRAN_VALUES             T_TRAN_VALUES;

   TYPE RC IS REF CURSOR;

   TYPE ACCOUNTS IS RECORD (ACCOUNT_NO NUMBER (14));

   TYPE T_ACCOUNTS IS TABLE OF ACCOUNTS
      INDEX BY PLS_INTEGER;

   W_ACCOUNTS                T_ACCOUNTS;

   TYPE ACNT_TABLE IS RECORD
   (
      ACNTTRANPAMT_ENTITY_NUM          NUMBER (4),
      ACNTTRANPAMT_BRN_CODE            NUMBER (6),
      ACNTTRANPAMT_INTERNAL_ACNUM      NUMBER (14),
      ACNTTRANPAMT_MONTH               VARCHAR2 (8),
      ACNTTRANPAMT_PROCESS_YEAR        NUMBER (4),
      ACNTTRANPAMT_TRANSFER_DB_AMT     NUMBER (18, 3),
      ACNTTRANPAMT_TRANSFER_DB_COUNT   NUMBER (5),
      ACNTTRANPAMT_TRANSFER_CR_AMT     NUMBER (18, 3),
      ACNTTRANPAMT_TRANSFER_CR_COUNT   NUMBER (5),
      ACNTTRANPAMT_CASH_DB_AMT         NUMBER (18, 3),
      ACNTTRANPAMT_CASH_DB_COUNT       NUMBER (5),
      ACNTTRANPAMT_CASH_CR_AMT         NUMBER (18, 3),
      ACNTTRANPAMT_CASH_CR_COUNT       NUMBER (5),
      ACNTTRANPAMT_CLEARING_DB_AMT     NUMBER (18, 3),
      ACNTTRANPAMT_CLEARING_DB_COUNT   NUMBER (5),
      ACNTTRANPAMT_CLEARING_CR_AMT     NUMBER (18, 3),
      ACNTTRANPAMT_CLEARING_CR_COUNT   NUMBER (5),
      ACNTTRANPAMT_TRADE_DB_AMT        NUMBER (18, 3),
      ACNTTRANPAMT_TRADE_DB_COUNT      NUMBER (5),
      ACNTTRANPAMT_TRADE_CR_AMT        NUMBER (18, 3),
      ACNTTRANPAMT_TRADE_CR_COUNT      NUMBER (5),
      ACNTTRANPAMT_ENTD_BY             VARCHAR2 (8),
      ACNTTRANPAMT_ENTD_ON             DATE,
      ACNTTRANPAMT_LAST_MOD_BY         VARCHAR2 (8),
      ACNTTRANPAMT_LAST_MOD_ON         DATE,
      ACNTTRANPAMT_AUTH_BY             VARCHAR2 (8),
      ACNTTRANPAMT_AUTH_ON             DATE,
      ACNTTRANPAMT_REJ_BY              VARCHAR2 (8),
      ACNTTRANPAMT_REJ_ON              DATE
   );

   TYPE T_ACNT_TABLE IS TABLE OF ACNT_TABLE
      INDEX BY PLS_INTEGER;

   W_NEW_TABLE               T_ACNT_TABLE;

   TYPE TT_ACBALH_ENTITY_NUM IS TABLE OF NUMBER (4)
      INDEX BY PLS_INTEGER;

   TYPE TT_ACBALH_INTERNAL_ACNUM IS TABLE OF NUMBER (14)
      INDEX BY PLS_INTEGER;

   TYPE TT_ACBALH_ASON_DATE IS TABLE OF DATE
      INDEX BY PLS_INTEGER;

   TYPE TT_ACBALH_AC_BAL IS TABLE OF NUMBER (18, 3)
      INDEX BY PLS_INTEGER;

   TYPE TT_ACBALH_BC_BAL IS TABLE OF NUMBER (18, 3)
      INDEX BY PLS_INTEGER;


   T_ACBALH_ENTITY_NUM       TT_ACBALH_ENTITY_NUM;
   T_ACBALH_INTERNAL_ACNUM   TT_ACBALH_INTERNAL_ACNUM;
   T_ACBALH_ASON_DATE        TT_ACBALH_ASON_DATE;
   T_ACBALH_AC_BAL           TT_ACBALH_AC_BAL;
   T_ACBALH_BC_BAL           TT_ACBALH_BC_BAL;
   V_TABLE_RECORD            NUMBER := 0;

   W_ERROR                   VARCHAR2 (1000);
   V_ASON_DATE               DATE;
   W_TRAN_DB_AMT             NUMBER (18, 3) := 0;
   W_TRAN_CR_AMT             NUMBER (18, 3) := 0;
   W_CASH_DB_AMT             NUMBER (18, 3) := 0;
   W_CASH_CR_AMT             NUMBER (18, 3) := 0;
   W_CLG_DB_AMT              NUMBER (18, 3) := 0;
   W_CLG_CR_AMT              NUMBER (18, 3) := 0;
   W_TRADE_DB_AMT            NUMBER (18, 3) := 0;
   W_TRADE_CR_AMT            NUMBER (18, 3) := 0;
   W_ENTITY_CODE             NUMBER (5) := 0;
   W_TRAN_DB_COUNT           NUMBER (5) := 0;
   W_TRAN_CR_COUNT           NUMBER (5) := 0;
   W_CASH_DB_COUNT           NUMBER (5) := 0;
   W_CASH_CR_COUNT           NUMBER (5) := 0;
   W_CLG_DB_COUNT            NUMBER (5) := 0;
   W_CLG_CR_COUNT            NUMBER (5) := 0;
   W_TRADE_DB_COUNT          NUMBER (5) := 0;
   W_TRADE_CR_COUNT          NUMBER (5) := 0;
   W_MONTH                   VARCHAR2 (6);
   V_SQL_STRING              VARCHAR2 (1000) := '';
   W_SQL                     VARCHAR2 (1000) := '';
   W_SQL_1                   VARCHAR2 (4000) := '';
   W_SQL_2                   VARCHAR2 (4000) := '';
   W_COUNT                   NUMBER (8);
   W_PROD_CODE               NUMBER (6);
   W_CURR_CODE               VARCHAR2 (3);
   W_AC_NUMBER               NUMBER (14);
   W_USER_ID                 VARCHAR2 (8);
   V_USER_EXCEPTION          EXCEPTION;
   V_PREV_DATE               DATE;
   V_TRAN_FLAG               VARCHAR2 (15);
   V_MAX_BAL                 NUMBER (18, 3) := 0;
   V_AC_BAL1                 NUMBER (18, 3) := 0;
   W_AC_BAL                  NUMBER (18, 3) := 0;
   V_AC_BAL                  NUMBER (18, 3) := 0;

   PROCEDURE INIT_VALUES
   IS
   BEGIN
      V_SQL_STRING := '';
      W_SQL := '';
   END INIT_VALUES;

   PROCEDURE PROCESS_TRANSACTION_PROFILE (W_ENTITY_CODE   IN NUMBER,
                                          W_BRN_CODE      IN NUMBER)
   IS
      V_ASON_YEAR   NUMBER (6) := TO_NUMBER (TO_CHAR (V_ASON_DATE, 'YYYY'));
      V_SQLSTRING   VARCHAR2 (4000);
      V_SQL         VARCHAR2 (4000);
      C1            RC;
   BEGIN
      V_SQL :=
         'SELECT TRAN_ENTITY_NUM ACNTTRANPAMT_ENTITY_NUM, TRAN_ACING_BRN_CODE  ACNTTRANPAMT_BRN_CODE, TRAN_INTERNAL_ACNUM ACNTTRANPAMT_INTERNAL_ACNUM,
        TO_CHAR(:V_ASON_DATE,''MON'') ACNTTRANPAMT_MONTH, :V_ASON_YEAR ACNTTRANPAMT_PROCESS_YEAR,
        SUM(NVL(ACNTTRANPAMT_TRANSFER_DB_AMT,0)) ACNTTRANPAMT_TRANSFER_DB_AMT,
        SUM(NVL(ACNTTRANPAMT_TRANSFER_DB_COUNT,0))  ACNTTRANPAMT_TRANSFER_DB_COUNT,
        SUM(NVL(ACNTTRANPAMT_TRANSFER_CR_AMT,0))  ACNTTRANPAMT_TRANSFER_CR_AMT ,
        SUM(NVL(ACNTTRANPAMT_TRANSFER_CR_COUNT,0))  ACNTTRANPAMT_TRANSFER_CR_COUNT ,
        SUM(NVL(ACNTTRANPAMT_CASH_DB_AMT,0))  ACNTTRANPAMT_CASH_DB_AMT ,
        SUM(NVL(ACNTTRANPAMT_CASH_DB_COUNT,0))  ACNTTRANPAMT_CASH_DB_COUNT ,
        SUM(NVL(ACNTTRANPAMT_CASH_CR_AMT,0))  ACNTTRANPAMT_CASH_CR_AMT ,
        SUM(NVL(ACNTTRANPAMT_CASH_CR_COUNT,0))  ACNTTRANPAMT_CASH_CR_COUNT,
        SUM(NVL(ACNTTRANPAMT_CLEARING_DB_AMT,0))  ACNTTRANPAMT_CLEARING_DB_AMT ,
        SUM(NVL(ACNTTRANPAMT_CLEARING_DB_COUNT,0))  ACNTTRANPAMT_CLEARING_DB_COUNT  ,
        SUM(NVL(ACNTTRANPAMT_CLEARING_CR_AMT,0))  ACNTTRANPAMT_CLEARING_CR_AMT  ,
        SUM(NVL(ACNTTRANPAMT_CLEARING_CR_COUNT,0))  ACNTTRANPAMT_CLEARING_CR_COUNT,
        SUM(NVL(ACNTTRANPAMT_TRADE_DB_AMT,0))  ACNTTRANPAMT_TRADE_DB_AMT ,
        SUM(NVL(ACNTTRANPAMT_TRADE_DB_COUNT,0))  ACNTTRANPAMT_TRADE_DB_COUNT  ,
        SUM(NVL(ACNTTRANPAMT_TRADE_CR_AMT,0))  ACNTTRANPAMT_TRADE_CR_AMT ,
        SUM(NVL(ACNTTRANPAMT_TRADE_CR_COUNT,0))  ACNTTRANPAMT_TRADE_CR_COUNT,
        :W_USER_ID ACNTTRANPAMT_ENTD_BY, :V_ASON_DATE ACNTTRANPAMT_ENTD_ON, NULL ACNTTRANPAMT_LAST_MOD_BY,  NULL ACNTTRANPAMT_LAST_MOD_ON, NULL  ACNTTRANPAMT_AUTH_BY,  NULL ACNTTRANPAMT_AUTH_ON,
         NULL ACNTTRANPAMT_REJ_BY,  NULL ACNTTRANPAMT_REJ_ON
        FROM';
      V_SQLSTRING :=
            ' (
        SELECT TRAN_ENTITY_NUM ,TRAN_ACING_BRN_CODE,  TRAN_INTERNAL_ACNUM,
           TRAN_TYPE_OF_TRAN,
           DECODE (TRAN_TYPE_OF_TRAN,1,DECODE(TRAN_DB_CR_FLG,''D'',SUM(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_TRANSFER_DB_AMT,
           DECODE (TRAN_TYPE_OF_TRAN,1,DECODE(TRAN_DB_CR_FLG,''D'',COUNT(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_TRANSFER_DB_COUNT,
           DECODE (TRAN_TYPE_OF_TRAN,1,DECODE(TRAN_DB_CR_FLG,''C'',SUM(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_TRANSFER_CR_AMT,
           DECODE (TRAN_TYPE_OF_TRAN,1,DECODE(TRAN_DB_CR_FLG,''C'',COUNT(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_TRANSFER_CR_COUNT,
           DECODE (TRAN_TYPE_OF_TRAN,3,DECODE(TRAN_DB_CR_FLG,''D'',SUM(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_CASH_DB_AMT,
           DECODE (TRAN_TYPE_OF_TRAN,3,DECODE(TRAN_DB_CR_FLG,''D'',COUNT(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_CASH_DB_COUNT,
           DECODE (TRAN_TYPE_OF_TRAN,3,DECODE(TRAN_DB_CR_FLG,''C'',SUM(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_CASH_CR_AMT,
           DECODE (TRAN_TYPE_OF_TRAN,3,DECODE(TRAN_DB_CR_FLG,''C'',COUNT(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_CASH_CR_COUNT,
           DECODE (TRAN_TYPE_OF_TRAN,2,DECODE(TRAN_DB_CR_FLG,''D'',SUM(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_CLEARING_DB_AMT,
           DECODE (TRAN_TYPE_OF_TRAN,2,DECODE(TRAN_DB_CR_FLG,''D'',COUNT(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_CLEARING_DB_COUNT,
           DECODE (TRAN_TYPE_OF_TRAN,2,DECODE(TRAN_DB_CR_FLG,''C'',SUM(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_CLEARING_CR_AMT,
           DECODE (TRAN_TYPE_OF_TRAN,2,DECODE(TRAN_DB_CR_FLG,''C'',COUNT(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_CLEARING_CR_COUNT,
           DECODE (TRAN_TYPE_OF_TRAN,NULL,DECODE(TRAN_DB_CR_FLG,''D'',SUM(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_TRADE_DB_AMT,
           DECODE (TRAN_TYPE_OF_TRAN,NULL,DECODE(TRAN_DB_CR_FLG,''D'',COUNT(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_TRADE_DB_COUNT,
           DECODE (TRAN_TYPE_OF_TRAN,NULL,DECODE(TRAN_DB_CR_FLG,''C'',SUM(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_TRADE_CR_AMT,
           DECODE (TRAN_TYPE_OF_TRAN,NULL,DECODE(TRAN_DB_CR_FLG,''C'',COUNT(NVL(TRAN_BASE_CURR_EQ_AMT,0)))) ACNTTRANPAMT_TRADE_CR_COUNT
        FROM PRODUCTS, TRAN'
         || V_ASON_YEAR
         || '
        WHERE  PRODUCT_CODE = TRAN_PROD_CODE
           AND TRAN_ENTITY_NUM = :W_ENTITY_CODE
           AND TRAN_ACING_BRN_CODE = :W_BRN_CODE 
           AND TRAN_DATE_OF_TRAN =:V_ASON_DATE
           AND PRODUCT_FOR_RUN_ACS = ''1''
           AND TRAN_SYSTEM_POSTED_TRAN = ''0''
           AND TRAN_AUTH_ON IS NOT NULL
        GROUP BY TRAN_ENTITY_NUM ,TRAN_ACING_BRN_CODE, TRAN_INTERNAL_ACNUM,
           TRAN_TYPE_OF_TRAN, TRAN_DB_CR_FLG)
        GROUP BY TRAN_ENTITY_NUM, TRAN_ACING_BRN_CODE, TRAN_INTERNAL_ACNUM';

      OPEN C1 FOR V_SQL || V_SQLSTRING
         USING V_ASON_DATE,
               V_ASON_YEAR,
               W_USER_ID,
               V_ASON_DATE,
               W_ENTITY_CODE,
               W_BRN_CODE,
               V_ASON_DATE;

      LOOP
         FETCH C1
            BULK COLLECT INTO W_NEW_TABLE
            LIMIT 200;

         FORALL I IN W_NEW_TABLE.FIRST .. W_NEW_TABLE.LAST
            MERGE INTO ACNTTRANPROFAMT_CLONE A
                 USING (SELECT W_NEW_TABLE (I).ACNTTRANPAMT_ENTITY_NUM
                                  ACNTTRANPAMT_ENTITY_NUM,
                               W_NEW_TABLE (I).ACNTTRANPAMT_BRN_CODE
                                  ACNTTRANPAMT_BRN_CODE,
                               W_NEW_TABLE (I).ACNTTRANPAMT_INTERNAL_ACNUM
                                  ACNTTRANPAMT_INTERNAL_ACNUM,
                               W_NEW_TABLE (I).ACNTTRANPAMT_MONTH
                                  ACNTTRANPAMT_MONTH,
                               W_NEW_TABLE (I).ACNTTRANPAMT_PROCESS_YEAR
                                  ACNTTRANPAMT_PROCESS_YEAR,
                               W_NEW_TABLE (I).ACNTTRANPAMT_TRANSFER_DB_AMT
                                  ACNTTRANPAMT_TRANSFER_DB_AMT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_TRANSFER_DB_COUNT
                                  ACNTTRANPAMT_TRANSFER_DB_COUNT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_TRANSFER_CR_AMT
                                  ACNTTRANPAMT_TRANSFER_CR_AMT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_TRANSFER_CR_COUNT
                                  ACNTTRANPAMT_TRANSFER_CR_COUNT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_CASH_DB_AMT
                                  ACNTTRANPAMT_CASH_DB_AMT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_CASH_DB_COUNT
                                  ACNTTRANPAMT_CASH_DB_COUNT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_CASH_CR_AMT
                                  ACNTTRANPAMT_CASH_CR_AMT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_CASH_CR_COUNT
                                  ACNTTRANPAMT_CASH_CR_COUNT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_CLEARING_DB_AMT
                                  ACNTTRANPAMT_CLEARING_DB_AMT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_CLEARING_DB_COUNT
                                  ACNTTRANPAMT_CLEARING_DB_COUNT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_CLEARING_CR_AMT
                                  ACNTTRANPAMT_CLEARING_CR_AMT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_CLEARING_CR_COUNT
                                  ACNTTRANPAMT_CLEARING_CR_COUNT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_TRADE_DB_AMT
                                  ACNTTRANPAMT_TRADE_DB_AMT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_TRADE_DB_COUNT
                                  ACNTTRANPAMT_TRADE_DB_COUNT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_TRADE_CR_AMT
                                  ACNTTRANPAMT_TRADE_CR_AMT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_TRADE_CR_COUNT
                                  ACNTTRANPAMT_TRADE_CR_COUNT,
                               W_NEW_TABLE (I).ACNTTRANPAMT_ENTD_BY
                                  ACNTTRANPAMT_ENTD_BY,
                               W_NEW_TABLE (I).ACNTTRANPAMT_ENTD_ON
                                  ACNTTRANPAMT_ENTD_ON,
                               W_NEW_TABLE (I).ACNTTRANPAMT_LAST_MOD_BY
                                  ACNTTRANPAMT_LAST_MOD_BY,
                               W_NEW_TABLE (I).ACNTTRANPAMT_LAST_MOD_ON
                                  ACNTTRANPAMT_LAST_MOD_ON,
                               W_NEW_TABLE (I).ACNTTRANPAMT_AUTH_BY
                                  ACNTTRANPAMT_AUTH_BY,
                               W_NEW_TABLE (I).ACNTTRANPAMT_AUTH_ON
                                  ACNTTRANPAMT_AUTH_ON,
                               W_NEW_TABLE (I).ACNTTRANPAMT_REJ_BY
                                  ACNTTRANPAMT_REJ_BY,
                               W_NEW_TABLE (I).ACNTTRANPAMT_REJ_ON
                                  ACNTTRANPAMT_REJ_ON
                          FROM DUAL) B
                    ON (    A.ACNTTRANPAMT_ENTITY_NUM =
                               B.ACNTTRANPAMT_ENTITY_NUM
                        AND A.ACNTTRANPAMT_BRN_CODE = B.ACNTTRANPAMT_BRN_CODE
                        AND A.ACNTTRANPAMT_INTERNAL_ACNUM =
                               B.ACNTTRANPAMT_INTERNAL_ACNUM
                        AND A.ACNTTRANPAMT_MONTH = B.ACNTTRANPAMT_MONTH
                        AND A.ACNTTRANPAMT_PROCESS_YEAR = B.ACNTTRANPAMT_PROCESS_YEAR )
            WHEN MATCHED
            THEN
               UPDATE SET
                  A.ACNTTRANPAMT_TRANSFER_DB_AMT =
                       NVL (A.ACNTTRANPAMT_TRANSFER_DB_AMT, 0)
                     + NVL (B.ACNTTRANPAMT_TRANSFER_DB_AMT, 0),
                  A.ACNTTRANPAMT_TRANSFER_DB_COUNT =
                       NVL (A.ACNTTRANPAMT_TRANSFER_DB_COUNT, 0)
                     + NVL (B.ACNTTRANPAMT_TRANSFER_DB_COUNT, 0),
                  A.ACNTTRANPAMT_TRANSFER_CR_AMT =
                       NVL (A.ACNTTRANPAMT_TRANSFER_CR_AMT, 0)
                     + NVL (B.ACNTTRANPAMT_TRANSFER_CR_AMT, 0),
                  A.ACNTTRANPAMT_TRANSFER_CR_COUNT =
                       NVL (A.ACNTTRANPAMT_TRANSFER_CR_COUNT, 0)
                     + NVL (B.ACNTTRANPAMT_TRANSFER_CR_COUNT, 0),
                  A.ACNTTRANPAMT_CASH_DB_AMT =
                       NVL (A.ACNTTRANPAMT_CASH_DB_AMT, 0)
                     + NVL (B.ACNTTRANPAMT_CASH_DB_AMT, 0),
                  A.ACNTTRANPAMT_CASH_DB_COUNT =
                       NVL (A.ACNTTRANPAMT_CASH_DB_COUNT, 0)
                     + NVL (B.ACNTTRANPAMT_CASH_DB_COUNT, 0),
                  A.ACNTTRANPAMT_CASH_CR_AMT =
                       NVL (A.ACNTTRANPAMT_CASH_CR_AMT, 0)
                     + NVL (B.ACNTTRANPAMT_CASH_CR_AMT, 0),
                  A.ACNTTRANPAMT_CASH_CR_COUNT =
                       NVL (A.ACNTTRANPAMT_CASH_CR_COUNT, 0)
                     + NVL (B.ACNTTRANPAMT_CASH_CR_COUNT, 0),
                  A.ACNTTRANPAMT_CLEARING_DB_AMT =
                       NVL (A.ACNTTRANPAMT_CLEARING_DB_AMT, 0)
                     + NVL (B.ACNTTRANPAMT_CLEARING_DB_AMT, 0),
                  A.ACNTTRANPAMT_CLEARING_DB_COUNT =
                       NVL (A.ACNTTRANPAMT_CLEARING_DB_COUNT, 0)
                     + NVL (B.ACNTTRANPAMT_CLEARING_DB_COUNT, 0),
                  A.ACNTTRANPAMT_CLEARING_CR_AMT =
                       NVL (A.ACNTTRANPAMT_CLEARING_CR_AMT, 0)
                     + NVL (B.ACNTTRANPAMT_CLEARING_CR_AMT, 0),
                  A.ACNTTRANPAMT_CLEARING_CR_COUNT =
                       NVL (A.ACNTTRANPAMT_CLEARING_CR_COUNT, 0)
                     + NVL (B.ACNTTRANPAMT_CLEARING_CR_COUNT, 0),
                  A.ACNTTRANPAMT_TRADE_DB_AMT =
                       NVL (A.ACNTTRANPAMT_TRADE_DB_AMT, 0)
                     + NVL (B.ACNTTRANPAMT_TRADE_DB_AMT, 0),
                  A.ACNTTRANPAMT_TRADE_DB_COUNT =
                       NVL (A.ACNTTRANPAMT_TRADE_DB_COUNT, 0)
                     + NVL (B.ACNTTRANPAMT_TRADE_DB_COUNT, 0),
                  A.ACNTTRANPAMT_TRADE_CR_AMT =
                       NVL (A.ACNTTRANPAMT_TRADE_CR_AMT, 0)
                     + NVL (B.ACNTTRANPAMT_TRADE_CR_AMT, 0),
                  A.ACNTTRANPAMT_TRADE_CR_COUNT =
                       NVL (A.ACNTTRANPAMT_TRADE_CR_COUNT, 0)
                     + NVL (B.ACNTTRANPAMT_TRADE_CR_COUNT, 0)
                       WHERE     A.ACNTTRANPAMT_ENTITY_NUM =
                                    B.ACNTTRANPAMT_ENTITY_NUM
                             AND A.ACNTTRANPAMT_BRN_CODE =
                                    B.ACNTTRANPAMT_BRN_CODE
                             AND A.ACNTTRANPAMT_INTERNAL_ACNUM =
                                    B.ACNTTRANPAMT_INTERNAL_ACNUM
                             AND A.ACNTTRANPAMT_MONTH = B.ACNTTRANPAMT_MONTH
                             AND A.ACNTTRANPAMT_PROCESS_YEAR = B.ACNTTRANPAMT_PROCESS_YEAR 
            WHEN NOT MATCHED
            THEN
               INSERT     (ACNTTRANPAMT_ENTITY_NUM,
                           ACNTTRANPAMT_BRN_CODE,
                           ACNTTRANPAMT_INTERNAL_ACNUM,
                           ACNTTRANPAMT_MONTH,
                           ACNTTRANPAMT_PROCESS_YEAR,
                           ACNTTRANPAMT_TRANSFER_DB_AMT,
                           ACNTTRANPAMT_TRANSFER_DB_COUNT,
                           ACNTTRANPAMT_TRANSFER_CR_AMT,
                           ACNTTRANPAMT_TRANSFER_CR_COUNT,
                           ACNTTRANPAMT_CASH_DB_AMT,
                           ACNTTRANPAMT_CASH_DB_COUNT,
                           ACNTTRANPAMT_CASH_CR_AMT,
                           ACNTTRANPAMT_CASH_CR_COUNT,
                           ACNTTRANPAMT_CLEARING_DB_AMT,
                           ACNTTRANPAMT_CLEARING_DB_COUNT,
                           ACNTTRANPAMT_CLEARING_CR_AMT,
                           ACNTTRANPAMT_CLEARING_CR_COUNT,
                           ACNTTRANPAMT_TRADE_DB_AMT,
                           ACNTTRANPAMT_TRADE_DB_COUNT,
                           ACNTTRANPAMT_TRADE_CR_AMT,
                           ACNTTRANPAMT_TRADE_CR_COUNT,
                           ACNTTRANPAMT_ENTD_BY,
                           ACNTTRANPAMT_ENTD_ON,
                           ACNTTRANPAMT_LAST_MOD_BY,
                           ACNTTRANPAMT_LAST_MOD_ON,
                           ACNTTRANPAMT_AUTH_BY,
                           ACNTTRANPAMT_AUTH_ON,
                           ACNTTRANPAMT_REJ_BY,
                           ACNTTRANPAMT_REJ_ON)
                   VALUES (B.ACNTTRANPAMT_ENTITY_NUM,
                           B.ACNTTRANPAMT_BRN_CODE,
                           B.ACNTTRANPAMT_INTERNAL_ACNUM,
                           B.ACNTTRANPAMT_MONTH,
                           B.ACNTTRANPAMT_PROCESS_YEAR,
                           B.ACNTTRANPAMT_TRANSFER_DB_AMT,
                           B.ACNTTRANPAMT_TRANSFER_DB_COUNT,
                           B.ACNTTRANPAMT_TRANSFER_CR_AMT,
                           B.ACNTTRANPAMT_TRANSFER_CR_COUNT,
                           B.ACNTTRANPAMT_CASH_DB_AMT,
                           B.ACNTTRANPAMT_CASH_DB_COUNT,
                           B.ACNTTRANPAMT_CASH_CR_AMT,
                           B.ACNTTRANPAMT_CASH_CR_COUNT,
                           B.ACNTTRANPAMT_CLEARING_DB_AMT,
                           B.ACNTTRANPAMT_CLEARING_DB_COUNT,
                           B.ACNTTRANPAMT_CLEARING_CR_AMT,
                           B.ACNTTRANPAMT_CLEARING_CR_COUNT,
                           B.ACNTTRANPAMT_TRADE_DB_AMT,
                           B.ACNTTRANPAMT_TRADE_DB_COUNT,
                           B.ACNTTRANPAMT_TRADE_CR_AMT,
                           B.ACNTTRANPAMT_TRADE_CR_COUNT,
                           B.ACNTTRANPAMT_ENTD_BY,
                           B.ACNTTRANPAMT_ENTD_ON,
                           B.ACNTTRANPAMT_LAST_MOD_BY,
                           B.ACNTTRANPAMT_LAST_MOD_ON,
                           B.ACNTTRANPAMT_AUTH_BY,
                           B.ACNTTRANPAMT_AUTH_ON,
                           B.ACNTTRANPAMT_REJ_BY,
                           B.ACNTTRANPAMT_REJ_ON);

         EXIT WHEN C1%NOTFOUND;
      END LOOP;

      CLOSE C1;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (W_ERROR) IS NULL
         THEN
            W_ERROR :=
                  'ERROR IN PROCESS_TRANSACTION_PROFILE '
               || SUBSTR (SQLERRM, 1, 500)
               || W_AC_NUMBER
               || W_PROD_CODE
               || W_CURR_CODE;
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                      'E',
                                      PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                      ' ',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                      'E',
                                      SUBSTR (SQLERRM, 1, 1000),
                                      ' ',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                      'X',
                                      W_ENTITY_CODE,
                                      ' ',
                                      0);
   END PROCESS_TRANSACTION_PROFILE;

   PROCEDURE PROCESS_MAX_TRAN_BAL (W_ENTITY_CODE   IN NUMBER,
                                   W_BRN_CODE      IN NUMBER)
   IS
      V_ASON_YEAR       NUMBER (6) := TO_NUMBER (TO_CHAR (V_ASON_DATE, 'YYYY'));
      V_BASE_CURR       ACNTS.ACNTS_CURR_CODE%TYPE;
      V_RECORD_NUM      NUMBER (6) := 1;
      W_OLD_AC_NUMBER   NUMBER;
      W_SQL_DATA        CLOB;
   BEGIN
      BEGIN
         V_BASE_CURR := PKG_PB_GLOBAL.FN_GET_INS_BASE_CURR (W_ENTITY_CODE);

         W_SQL_DATA :=
               'INSERT INTO DAILY_TRAN_DATA
                SELECT TRAN_ENTITY_NUM,
           TRAN_INTERNAL_ACNUM,
           (CASE WHEN TRAN_DB_CR_FLG = ''C'' THEN TRAN_AMOUNT ELSE 0 END)
              CREDIT_AMOUNT,
           (CASE WHEN TRAN_DB_CR_FLG = ''D'' THEN TRAN_AMOUNT ELSE 0 END)
              DEBIT_AMOUNT,
           TRAN_BATCH_NUMBER,
           TRAN_BATCH_SL_NUM,
           TRAN_AUTH_ON
      FROM TRAN'
            || V_ASON_YEAR
            || '
     WHERE     TRAN_ENTITY_NUM = :1
           AND TRAN_DATE_OF_TRAN = :2
           AND TRAN_ACING_BRN_CODE = :3
           AND TRAN_INTERNAL_ACNUM <> 0
           AND TRAN_BASE_CURR_CODE = :4
           AND TRAN_AUTH_ON IS NOT NULL';

         EXECUTE IMMEDIATE W_SQL_DATA
            USING W_ENTITY_CODE,
                  V_ASON_DATE,
                  W_BRN_CODE,
                  V_BASE_CURR;

         W_SQL_DATA :=
            'INSERT INTO DAILY_TRAN_DATA
                  SELECT H.ACBALH_ENTITY_NUM,
           H.ACBALH_INTERNAL_ACNUM,
           (CASE WHEN H.ACBALH_AC_BAL > 0 THEN H.ACBALH_AC_BAL ELSE 0 END)
              CREDIT_AMOUNT,
           (CASE WHEN H.ACBALH_AC_BAL < 0 THEN ABS(H.ACBALH_AC_BAL) ELSE 0 END)
              DEBIT_AMOUNT,
           0 TRAN_BATCH_NUMBER,
           0 TRAN_BATCH_SL_NUM,
           A.ACBALH_ASON_DATE
      FROM (  SELECT ACBALH_ENTITY_NUM,
                     ACBALH_INTERNAL_ACNUM,
                     MAX (ACBALH_ASON_DATE) ACBALH_ASON_DATE
                FROM ACBALASONHIST, DAILY_TRAN_DATA
               WHERE     ACBALH_ENTITY_NUM = TRAN_ENTITY_NUM
                     AND ACBALH_INTERNAL_ACNUM = TRAN_INTERNAL_ACNUM
                     AND ACBALH_ASON_DATE < :1
            GROUP BY ACBALH_ENTITY_NUM, ACBALH_INTERNAL_ACNUM) A,
           ACBALASONHIST H
     WHERE     H.ACBALH_ENTITY_NUM = A.ACBALH_ENTITY_NUM
           AND H.ACBALH_INTERNAL_ACNUM = A.ACBALH_INTERNAL_ACNUM
           AND H.ACBALH_ASON_DATE = A.ACBALH_ASON_DATE';

         EXECUTE IMMEDIATE W_SQL_DATA USING V_ASON_DATE;

         W_SQL_DATA :=
            'INSERT INTO ACBALASONHIST_MAX_TRAN_CLONE (ACBALH_ENTITY_NUM,
                                    ACBALH_INTERNAL_ACNUM,
                                    ACBALH_ASON_DATE,
                                    ACBALH_AC_BAL,
                                    ACBALH_BC_BAL,
                                    ACBALH_BRN_CODE,
                                    ACBALH_ASON_AC_BAL,
                                    ACBALH_ASON_BC_BAL)
   SELECT A.TRAN_ENTITY_NUM,
          A.TRAN_INTERNAL_ACNUM,
          A.ASON_DATE,
          A.MAX_BALANCE,
          A.MAX_BALANCE,
          :BRN_CODE BRN_CODE,
          B.ACNTBAL_AC_BAL,
          B.ACNTBAL_BC_BAL
     FROM (  SELECT TRAN_ENTITY_NUM,
                    TRAN_INTERNAL_ACNUM,
                    :ASON_DATE ASON_DATE,
                    MAX (BALANCE) MAX_BALANCE
               FROM (SELECT TRAN_ENTITY_NUM,
                            TRAN_INTERNAL_ACNUM,
                            SUM (
                               CREDIT_AMOUNT - DEBIT_AMOUNT)
                            OVER (
                               PARTITION BY TRAN_ENTITY_NUM,
                                            TRAN_INTERNAL_ACNUM
                               ORDER BY
                                  TRAN_ENTITY_NUM,
                                  TRAN_INTERNAL_ACNUM,
                                  TRAN_AUTH_ON,
                                  TRAN_BATCH_SL_NUM)
                               BALANCE
                       FROM DAILY_TRAN_DATA)
           GROUP BY TRAN_ENTITY_NUM, TRAN_INTERNAL_ACNUM) A,
          ACNTBAL B
    WHERE     B.ACNTBAL_ENTITY_NUM = A.TRAN_ENTITY_NUM
          AND B.ACNTBAL_INTERNAL_ACNUM = A.TRAN_INTERNAL_ACNUM';

         EXECUTE IMMEDIATE W_SQL_DATA USING W_BRN_CODE,V_ASON_DATE;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (W_ERROR) IS NULL
         THEN
            W_ERROR :=
                  'ERROR IN PROCESS_MAX_TRAN_BAL'
               || SUBSTR (SQLERRM, 1, 500)
               || W_AC_NUMBER
               || W_PROD_CODE;
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                      'E',
                                      PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                      ' ',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                      'E',
                                      SUBSTR (SQLERRM, 1, 1000),
                                      ' ',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (W_ENTITY_CODE,
                                      'X',
                                      W_ENTITY_CODE,
                                      ' ',
                                      0);
   END PROCESS_MAX_TRAN_BAL;

   PROCEDURE INITPARA
   IS
   BEGIN
      W_TRAN_DB_AMT := 0;
      W_TRAN_CR_AMT := 0;
      W_CASH_DB_AMT := 0;
      W_CASH_CR_AMT := 0;
      W_CLG_DB_AMT := 0;
      W_CLG_CR_AMT := 0;
      W_TRADE_DB_AMT := 0;
      W_TRADE_CR_AMT := 0;
      W_ENTITY_CODE := 0;
      W_TRAN_DB_COUNT := 0;
      W_TRAN_CR_COUNT := 0;
      W_CASH_DB_COUNT := 0;
      W_CASH_CR_COUNT := 0;
      W_CLG_DB_COUNT := 0;
      W_CLG_CR_COUNT := 0;
      W_TRADE_DB_COUNT := 0;
      W_TRADE_CR_COUNT := 0;
   END INITPARA;

   PROCEDURE START_BRNWISE (V_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0)
   IS
      L_BRN_CODE      NUMBER (6);
      V_PROCESS_ALL   CHAR (1) := 'N';
      V_ERROR_LOG     VARCHAR2 (2000);
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

      W_ENTITY_CODE := V_ENTITY_NUM;
      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (W_ENTITY_CODE, P_BRN_CODE);
      V_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      W_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

         IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (W_ENTITY_CODE,
                                                         L_BRN_CODE) = FALSE
         THEN
            --PROCESS_TRANSACTION_PROFILE (W_ENTITY_CODE, L_BRN_CODE);

            IF TRIM (W_ERROR) IS NULL
            THEN
                NULL ;
               PROCESS_MAX_TRAN_BAL (W_ENTITY_CODE, L_BRN_CODE);
            END IF;

            PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (W_ENTITY_CODE);

            IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
            THEN
               V_ERROR_LOG := PKG_EODSOD_FLAGS.PV_ERROR_MSG;

               PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (
                  W_ENTITY_CODE,
                  L_BRN_CODE);
            END IF;
         END IF;
      END LOOP;

      PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (W_ENTITY_CODE);

      IF V_ASON_DATE = LAST_DAY (V_ASON_DATE)
      THEN
         PKG_EEOD.SP_MONTHLY_VIEW_REFRESHED;
      END IF;
   END START_BRNWISE;
END PKG_TRANSACTION_PROFILE_V2;
/
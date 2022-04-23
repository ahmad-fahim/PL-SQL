CREATE OR REPLACE PROCEDURE SP_GET_MIN_BAL (
   V_ENTITY_NUM      IN     NUMBER,
   P_DEP_PROD_CODE   IN     NUMBER,
   P_AC_NUMBER       IN     NUMBER,
   P_CURR_CODE       IN     CHAR,
   P_CLS_DATE        IN     DATE,
   P_MIN_BAL            OUT FLOAT,
   P_ERR_MSG            OUT VARCHAR2)
IS
   TYPE NOF_RECORDS IS RECORD
   (
      ACBALH_ASON_DATE   DATE,
      ACBALH_AC_BAL      NUMBER
   );

   TYPE T_NOF_RECORDS IS TABLE OF NOF_RECORDS
      INDEX BY PLS_INTEGER;

   V_NOF_RECORDS          T_NOF_RECORDS;

   TYPE ACBAL_HIST IS RECORD
   (
      ACBALH_DATE   DATE,
      AVBALH_BAL    NUMBER (18, 3)
   );

   TYPE T_ACBAL_HIST IS TABLE OF ACBAL_HIST
      INDEX BY PLS_INTEGER;

   W_ACBAL_HIST           T_ACBAL_HIST;


   TYPE TRAN_VALUES IS RECORD
   (
      ACCOUNT_NUM    NUMBER (14),
      PRODUCT_CODE   NUMBER (4),
      CURR_CODE      VARCHAR2 (3),
      TRAN_FLAG      CHAR (1),
      TRAN_TYPE      CHAR (1),
      TRAN_AMOUNT    NUMBER (18, 3),
      TRAN_BC_AMT    NUMBER (18, 3)
   );

   TYPE T_TRAN_VALUES IS TABLE OF TRAN_VALUES
      INDEX BY PLS_INTEGER;

   W_TRAN_VALUES          T_TRAN_VALUES;



   V_ERR_MSG              VARCHAR2 (2300);
   V_CURR_DATE            DATE;
   V_OPEN_DATE            DATE;
   V_CURRMON_START_DATE   DATE;
   -- V_NOF_RECORDS    VARCHAR2(35) :=0;
   V_NOF_RECORDS1         DATE;
   V_NOF_RECORDS2         DATE;
   V_TOTAL_AMT            VARCHAR2 (35) := 0;
   V_NOF_DAYS             VARCHAR2 (35) := 0;
   V_NOF_DAY1             VARCHAR2 (35);
   V_SQL1                 VARCHAR2 (2000);

   V_SQL2                 VARCHAR2 (2000);                               --end
   V_LAST_MIG_DATE        VARCHAR2 (35);
   W_SQL                  VARCHAR2 (4000);
   V_SQL                  VARCHAR2 (4000);
   P_SQL                  VARCHAR2 (4000);
   W_BAL                  NUMBER (18, 3);
   V_BAL                  NUMBER (18, 3);
   V_MIN_BAL              NUMBER (18, 3) := 0;
   V_AC_BAL               NUMBER (18, 3);
   V_TOTAC_BAL            NUMBER (18, 3);
   n                      NUMBER (6) := 0;
   IDX                    NUMBER (6) := 0;
   V_AFTR_BAL1            NUMBER (18, 3) := 0;
   V_PREV_DATE            DATE;
   V_CAL_BAL              NUMBER (18, 3) := 0;
   W_MIN_BAL              NUMBER (18, 3);
   W_ACBAL_MINDATE        DATE;
   W_BATCH                NUMBER (7);

   --------------------CHECKING INPUT VALUES----------------
   FUNCTION CHECK_INPUT_VALUES
      RETURN BOOLEAN
   IS
   BEGIN
      IF TRIM (P_AC_NUMBER) IS NULL
      THEN
         V_ERR_MSG := 'Account Number should be specified';
         RETURN FALSE;
      END IF;

      IF TRIM (P_AC_NUMBER) IS NULL
      THEN
         V_ERR_MSG := 'Account Number should be specified';
         RETURN FALSE;
      END IF;

      IF TRIM (P_DEP_PROD_CODE) IS NULL
      THEN
         V_ERR_MSG := 'Product Code should be specified';
         RETURN FALSE;
      END IF;

      IF TRIM (P_CURR_CODE) IS NULL
      THEN
         V_ERR_MSG := 'Currency Code Should be Specified';
         RETURN FALSE;
      END IF;


      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_ERR_MSG := 'Error in CHECK_INPUT_VALUES';
         RETURN FALSE;
   END CHECK_INPUT_VALUES;

   -------------------------------------------------------------


   -------------------------------------------------------------
   PROCEDURE GET_MIN_BAL
   IS
      V_CURR_FIN_DATE    DATE;
      V_CURR_DATE        DATE;
      V_TRAN_FLAG        VARCHAR2 (15);
      V_MIN_ACBAL_DATE   DATE;
      V_AC_OPEN_DATE     DATE;
   BEGIN
      --V_CURR_FIN_DATE
      V_CURR_DATE := FN_GET_CURRBUSS_DATE (V_ENTITY_NUM, P_CURR_CODE);
      V_CURRMON_START_DATE :=
         PKG_PB_GLOBAL.GET_CURR_MONTH_STARTDATE (V_ENTITY_NUM, P_CLS_DATE);

      SELECT ACNTS_OPENING_DATE
        INTO V_AC_OPEN_DATE
        FROM ACNTS
       WHERE     ACNTS_ENTITY_NUM = V_ENTITY_NUM
             AND ACNTS_INTERNAL_ACNUM = P_AC_NUMBER;

      W_SQL :=
            'SELECT MIN(ABS(ACBALH_AC_BAL)), MIN(ACBALH_ASON_DATE) FROM ACBALASONHIST_MIN WHERE ACBALH_ENTITY_NUM = '
         || CHR (39)
         || PKG_ENTITY.FN_GET_ENTITY_CODE
         || CHR (39)
         || '
            AND ACBALH_INTERNAL_ACNUM ='
         || CHR (39)
         || P_AC_NUMBER
         || CHR (39)
         || ' AND ACBALH_ASON_DATE >= '
         || CHR (39)
         || V_CURRMON_START_DATE
         || CHR (39);

      EXECUTE IMMEDIATE W_SQL INTO W_MIN_BAL, W_ACBAL_MINDATE;


      W_SQL := 'SELECT MIN(ACBALH_BC_BAL) MIN_BALANCE FROM 
( ';

      IF TO_CHAR (V_AC_OPEN_DATE, 'MM-YYYY') <>
            TO_CHAR (V_CURRMON_START_DATE, 'MM-YYYY')
      THEN
         W_SQL :=
               W_SQL
            || 'SELECT TO_NUMBER ( :P_ACCOUNT_NUMBER) ACBALH_INTERNAL_ACNUM,
       TO_DATE ( :P_FROM_DATE - 1) ACBALH_ASON_DATE,
       FN_BIS_GET_ASON_ACBAL ( :ENTITY_NUM,
                              :P_ACCOUNT_NUMBER,
                              ''BDT'',
                              :P_FROM_DATE,
                              :P_TO_DATE)
          ACBALH_BC_BAL
  FROM DUAL
        UNION ALL
         ';
      END IF;

      W_SQL :=
            W_SQL
         || 'SELECT ACBALH_INTERNAL_ACNUM, ACBALH_ASON_DATE, ACBALH_BC_BAL
  FROM ACBALASONHIST, ACNTS
 WHERE     ACBALH_ENTITY_NUM = :ENTITY_NUM
       AND ACBALH_INTERNAL_ACNUM = :P_ACCOUNT_NUMBER
       AND ACBALH_ASON_DATE BETWEEN GREATEST ( :P_FROM_DATE,
                                              ACNTS_OPENING_DATE)
                                AND :P_TO_DATE
       AND ACNTS_ENTITY_NUM = :ENTITY_NUM
       AND ACNTS_INTERNAL_ACNUM = ACBALH_INTERNAL_ACNUM)';

      IF TO_CHAR (V_AC_OPEN_DATE, 'MM-YYYY') <>
            TO_CHAR (V_CURRMON_START_DATE, 'MM-YYYY')
      THEN
         EXECUTE IMMEDIATE W_SQL
            INTO V_MIN_BAL
            USING P_AC_NUMBER,
                  V_CURRMON_START_DATE,
                  V_ENTITY_NUM,
                  P_AC_NUMBER,
                  V_CURRMON_START_DATE,
                  P_CLS_DATE,
                  V_ENTITY_NUM,
                  P_AC_NUMBER,
                  V_CURRMON_START_DATE,
                  P_CLS_DATE,
                  V_ENTITY_NUM;
      ELSE
         EXECUTE IMMEDIATE W_SQL
            INTO V_MIN_BAL
            USING V_ENTITY_NUM,
                  P_AC_NUMBER,
                  V_CURRMON_START_DATE,
                  P_CLS_DATE,
                  V_ENTITY_NUM;
      END IF;

      IF W_MIN_BAL IS NOT NULL
      THEN
         IF W_MIN_BAL < V_MIN_BAL
         THEN
            V_MIN_BAL := W_MIN_BAL;
         END IF;
      END IF;

      DBMS_OUTPUT.put_line (W_SQL);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_ERR_MSG := 'No balance on that day ' || SQLERRM;
      WHEN OTHERS
      THEN
         V_ERR_MSG := 'Error in Getting Minimum Balance ' || SQLERRM;
   END GET_MIN_BAL;
BEGIN
   PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

  <<GETMINBAL>>
   BEGIN
      IF CHECK_INPUT_VALUES = TRUE
      THEN
         GET_MIN_BAL;
      ELSE
         V_ERR_MSG := 'Error in Input Values';
         P_ERR_MSG := V_ERR_MSG;
         V_MIN_BAL := 0;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_ERR_MSG := 'Error in Balance Calculation';
         P_ERR_MSG := V_ERR_MSG;
         V_MIN_BAL := 0;
   END GETMINBAL;

   P_ERR_MSG := V_ERR_MSG;
   P_MIN_BAL := V_MIN_BAL;
END SP_GET_MIN_BAL;
/
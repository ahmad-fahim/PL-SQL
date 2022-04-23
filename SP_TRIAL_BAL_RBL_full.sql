CREATE OR REPLACE PROCEDURE SP_TRIAL_BAL(V_ENTITY_NUM  NUMBER,
                                         P_BRN_CODE    NUMBER,
                                         P_DEMAND_DATE DATE) IS
PRAGMA AUTONOMOUS_TRANSACTION;
  V_CBD                     DATE;
  V_CR_SUM_FROM_DEMAND_DATE NUMBER;
  V_DR_SUM_FROM_DEMAND_DATE NUMBER;
  V_CR_BAL                  NUMBER;
  V_DR_BAL                  NUMBER;
BEGIN
  SELECT MN_CURR_BUSINESS_DATE INTO V_CBD FROM MAINCONT;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DAILYGENERALLEDGER';

  ------------------------ Basic data preperation -------------------------

  IF TO_CHAR(TO_DATE(V_CBD), 'YYYY') =
     TO_CHAR(TO_DATE(P_DEMAND_DATE - 1), 'YYYY') THEN
    BEGIN
      FOR IDX IN (SELECT TRIM(ACCOUNTCODE) ACCOUNT_CODE,
                         TRIM(BRANCHGLCODE) BRANCHGLCODE,
                         ACCOUNTHEAD
                    FROM ACCOUNTCODE
                   WHERE ACNTCD_BRN_CODE = P_BRN_CODE) LOOP
        -- DEBIT, CREDIT, PREVIOUSDEBIT, PREVIOUSCREDIT
      
        SELECT SUM(PREVIOUSCREDIT + CREDIT), SUM(PREVIOUSDEBIT + DEBIT)
          INTO V_CR_BAL, V_DR_BAL
          FROM ACCOUNTCODE
         WHERE TRIM(ACCOUNTCODE) = IDX.ACCOUNT_CODE
           AND ACNTCD_BRN_CODE = P_BRN_CODE;
      
        V_CR_SUM_FROM_DEMAND_DATE := GETGLSUMCR(V_ENTITY_NUM,
                                                   P_BRN_CODE,
                                                   IDX.ACCOUNT_CODE,
                                                   TO_DATE(P_DEMAND_DATE - 1));
        V_DR_SUM_FROM_DEMAND_DATE := GETGLSUMDR(V_ENTITY_NUM,
                                                   P_BRN_CODE,
                                                   IDX.ACCOUNT_CODE,
                                                   TO_DATE(P_DEMAND_DATE - 1));
      
        V_CR_BAL := V_CR_BAL - V_CR_SUM_FROM_DEMAND_DATE;
        V_DR_BAL := V_DR_BAL - V_DR_SUM_FROM_DEMAND_DATE;
      
        INSERT INTO DAILYGENERALLEDGER
          (BRANCH_CODE,
           DEMAND_DATE,
           FIRSTHEAD,
           BRANCHGLCODE,
           SECONDEHEAD,
           OPENINGBAL,
           TOTAL_NO_OF_DEBIT,
           DEBIT,
           TOTAL_NO_OF_CREDIT,
           CREDIT,
           CLOSINGBAL)
        VALUES
          (P_BRN_CODE,
           P_DEMAND_DATE,
           NULL,
           IDX.BRANCHGLCODE,
           IDX.ACCOUNTHEAD,
           V_CR_BAL - V_DR_BAL,
           0,
           0,
           0,
           0,
           0);
      END LOOP;
    END;
  ELSE
    BEGIN
      FOR IDX IN (SELECT TRIM(ACCOUNTCODE) ACCOUNT_CODE,
                         TRIM(BRANCHGLCODE) BRANCHGLCODE,
                         ACCOUNTHEAD
                    FROM ACCOUNTCODE
                   WHERE ACNTCD_BRN_CODE = P_BRN_CODE) LOOP
        V_CR_BAL := GETYGLSUMCR(V_ENTITY_NUM,
                                   P_BRN_CODE,
                                   IDX.ACCOUNT_CODE);
        V_DR_BAL := GETYGLSUMDR(V_ENTITY_NUM,
                                   P_BRN_CODE,
                                   IDX.ACCOUNT_CODE);
      
        V_CR_SUM_FROM_DEMAND_DATE := GETGLSUMCR(V_ENTITY_NUM,
                                                   P_BRN_CODE,
                                                   IDX.ACCOUNT_CODE,
                                                   TO_DATE(P_DEMAND_DATE - 1));
        V_DR_SUM_FROM_DEMAND_DATE := GETGLSUMDR(V_ENTITY_NUM,
                                                   P_BRN_CODE,
                                                   IDX.ACCOUNT_CODE,
                                                   TO_DATE(P_DEMAND_DATE - 1));
      
        V_CR_BAL := V_CR_BAL - V_CR_SUM_FROM_DEMAND_DATE;
        V_DR_BAL := V_DR_BAL - V_DR_SUM_FROM_DEMAND_DATE;
      
        INSERT INTO DAILYGENERALLEDGER
          (BRANCH_CODE,
           DEMAND_DATE,
           FIRSTHEAD,
           BRANCHGLCODE,
           SECONDEHEAD,
           OPENINGBAL,
           TOTAL_NO_OF_DEBIT,
           DEBIT,
           TOTAL_NO_OF_CREDIT,
           CREDIT,
           CLOSINGBAL)
        VALUES
          (P_BRN_CODE,
           P_DEMAND_DATE,
           NULL,
           IDX.BRANCHGLCODE,
           IDX.ACCOUNTHEAD,
           V_CR_BAL - V_DR_BAL,
           0,
           0,
           0,
           0,
           0);
      END LOOP;
    END;
  END IF;

  ------------------------ Basic data preperation END -------------------------

  -------------------  Update debit & credit amount for that particular date----------------------

  BEGIN
    FOR IDX IN (SELECT ACCOUNTCODE.ACCOUNTHEAD,
                       TRIM(ACCOUNTCODE.BRANCHGLCODE) BRANCHGLCODE,
                       MASTER_VOUCHER.ACCOUNTCODE ACCOUNT_CODE,
                       MASTER_VOUCHER.DAY_NO_OF_DEBIT,
                       MASTER_VOUCHER.DAY_DEBIT,
                       MASTER_VOUCHER.DAY_NO_OF_CREDIT,
                       MASTER_VOUCHER.DAY_CREDIT
                  FROM ACCOUNTCODE,
                       (SELECT BRN_CODE,
                               TRIM(ACCOUNTCODE) ACCOUNTCODE,
                               SUM(NOOFDEBIT) DAY_NO_OF_DEBIT,
                               SUM(DEBIT) DAY_DEBIT,
                               SUM(NOOFCREDIT) DAY_NO_OF_CREDIT,
                               SUM(CREDIT) DAY_CREDIT
                          FROM MASTERVOUCHER
                         WHERE TRANSDATE = P_DEMAND_DATE
                           AND BRN_CODE = P_BRN_CODE
                        -- AND TRIM (Description) <> 'Closing Voucher after Initialize.'
                         GROUP BY BRN_CODE, TRIM(ACCOUNTCODE)
                         ORDER BY ACCOUNTCODE) MASTER_VOUCHER
                 WHERE TRIM(ACCOUNTCODE.ACCOUNTCODE) =
                       TRIM(MASTER_VOUCHER.ACCOUNTCODE)
                   AND MASTER_VOUCHER.BRN_CODE = ACCOUNTCODE.ACNTCD_BRN_CODE) LOOP
      UPDATE DAILYGENERALLEDGER
         SET DEBIT              = IDX.DAY_DEBIT,
             CREDIT             = IDX.DAY_CREDIT,
             TOTAL_NO_OF_DEBIT  = IDX.DAY_NO_OF_DEBIT,
             TOTAL_NO_OF_CREDIT = IDX.DAY_NO_OF_CREDIT
       WHERE BRANCHGLCODE = IDX.BRANCHGLCODE;
    END LOOP;
  END;

  UPDATE DAILYGENERALLEDGER SET CLOSINGBAL = OPENINGBAL + CREDIT - DEBIT;

  DELETE FROM DAILYGENERALLEDGER
   WHERE OPENINGBAL = 0
     AND CREDIT = 0
     AND DEBIT = 0
     AND CLOSINGBAL = 0;

  -------------------  Update debit & credit amount for that particular date end----------------------

  -------------------- First head update ------------------

  BEGIN
    FOR IDX IN (SELECT TRIM(ACCOUNTCODE_2.ACCOUNTCODE),
                       ACCOUNTCODE_2.ACCOUNTHEAD ACCOUNTHEAD_FIRST,
                       ACCOUNTCODE_1.*
                  FROM ACCOUNTCODE ACCOUNTCODE_2,
                       (SELECT ACCOUNTCODE.ACNTCD_BRN_CODE ACNTCD_BRN_CODE,
                               TRIM(ACCOUNTCODE.ACCOUNTHEAD) ACCOUNTHEAD_SECOND,
                               TRIM(ACCOUNTCODE.FIRSTLEVEL) FIRSTLEVEL,
                               TRIM(ACCOUNTCODE.BRANCHGLCODE) BRANCHGLCODE,
                               TRIM(ACCOUNTCODE.SECONDLEVEL) SECONDLEVEL
                          FROM ACCOUNTCODE, DAILYGENERALLEDGER
                         WHERE DAILYGENERALLEDGER.BRANCHGLCODE =
                               TRIM(ACCOUNTCODE.BRANCHGLCODE)
                           AND ACCOUNTCODE.ACCOUNTHEAD =
                               DAILYGENERALLEDGER.SECONDEHEAD
                           AND ACCOUNTCODE.ACNTCD_BRN_CODE = P_BRN_CODE) ACCOUNTCODE_1
                 WHERE TRIM(ACCOUNTCODE_2.ACCOUNTCODE) =
                       ACCOUNTCODE_1.FIRSTLEVEL
                   AND ACCOUNTCODE_1.ACNTCD_BRN_CODE =
                       ACCOUNTCODE_2.ACNTCD_BRN_CODE) LOOP
      UPDATE DAILYGENERALLEDGER D
         SET D.FIRSTHEAD = IDX.ACCOUNTHEAD_FIRST
       WHERE D.BRANCHGLCODE = IDX.BRANCHGLCODE
         AND D.SECONDEHEAD = IDX.ACCOUNTHEAD_SECOND;
    END LOOP;
  END;
  COMMIT ;
  -------------------- First head update END ------------------
END SP_TRIAL_BAL;
/










CREATE OR REPLACE PACKAGE PKG_TRIAL_BAL IS
  
  TYPE TY_TEMP_TRIAL_BAL IS RECORD(
    BRANCHGLCODE DAILYGENERALLEDGER.BRANCHGLCODE%TYPE,
    FIRSTHEAD DAILYGENERALLEDGER.FIRSTHEAD%TYPE,
    SECONDEHEAD DAILYGENERALLEDGER.SECONDEHEAD%TYPE,
    TOTAL_NO_OF_DEBIT DAILYGENERALLEDGER.TOTAL_NO_OF_DEBIT%TYPE,
    DEBIT DAILYGENERALLEDGER.DEBIT%TYPE,
    TOTAL_NO_OF_CREDIT DAILYGENERALLEDGER.TOTAL_NO_OF_CREDIT%TYPE,
    CREDIT DAILYGENERALLEDGER.CREDIT%TYPE);

  TYPE TY_TEMP_TRIALBAL IS TABLE OF TY_TEMP_TRIAL_BAL;

  FUNCTION FN_TRIAL_BAL(V_ENTITY_NUM  NUMBER,
                             P_BRN_CODE    NUMBER,
                             p_demand_date date) RETURN TY_TEMP_TRIALBAL
    PIPELINED;

END PKG_TRIAL_BAL;
/






CREATE OR REPLACE PACKAGE BODY PKG_TRIAL_BAL
IS
   TEMP_TY_TRIAL_BAL   PKG_TRIAL_BAL.TY_TEMP_TRIAL_BAL;
   V_SQL               VARCHAR2 (500);

   FUNCTION FN_TRIAL_BAL (V_ENTITY_NUM     NUMBER,
                          P_BRN_CODE       NUMBER,
                          P_DEMAND_DATE    DATE)
      RETURN TY_TEMP_TRIALBAL
      PIPELINED
   -- RETURN VARCHAR2
   IS
      TYPE TEMP_TRIAL_BAL IS RECORD
      (
         T_BRANCHGLCODE         DAILYGENERALLEDGER.BRANCHGLCODE%TYPE,
         T_FIRSTHEAD            DAILYGENERALLEDGER.FIRSTHEAD%TYPE,
         T_SECONDEHEAD          DAILYGENERALLEDGER.SECONDEHEAD%TYPE,
         T_TOTAL_NO_OF_DEBIT    DAILYGENERALLEDGER.TOTAL_NO_OF_DEBIT%TYPE,
         T_DEBIT                DAILYGENERALLEDGER.DEBIT%TYPE,
         T_TOTAL_NO_OF_CREDIT   DAILYGENERALLEDGER.TOTAL_NO_OF_CREDIT%TYPE,
         T_CREDIT               DAILYGENERALLEDGER.CREDIT%TYPE
      );

      TYPE TY_TRIALBAL IS TABLE OF TEMP_TRIAL_BAL;

      V_TEMP_TRIALBAL   TY_TRIALBAL;
   BEGIN
      SP_TRIAL_BAL (V_ENTITY_NUM, P_BRN_CODE, P_DEMAND_DATE);
      V_SQL :=
         'SELECT BRANCHGLCODE, FIRSTHEAD , SECONDEHEAD, TOTAL_NO_OF_DEBIT , DEBIT , TOTAL_NO_OF_CREDIT , CREDIT FROM DAILYGENERALLEDGER  WHERE TOTAL_NO_OF_DEBIT <> 0 OR TOTAL_NO_OF_CREDIT <> 0';

      EXECUTE IMMEDIATE  V_SQL BULK COLLECT INTO V_TEMP_TRIALBAL;

      IF (V_TEMP_TRIALBAL.FIRST IS NOT NULL)
      THEN
         FOR INI IN V_TEMP_TRIALBAL.FIRST .. V_TEMP_TRIALBAL.LAST
         LOOP
            TEMP_TY_TRIAL_BAL.BRANCHGLCODE :=
               V_TEMP_TRIALBAL (INI).T_BRANCHGLCODE;
            TEMP_TY_TRIAL_BAL.FIRSTHEAD := V_TEMP_TRIALBAL (INI).T_FIRSTHEAD;
            TEMP_TY_TRIAL_BAL.SECONDEHEAD :=
               V_TEMP_TRIALBAL (INI).T_SECONDEHEAD;
            TEMP_TY_TRIAL_BAL.TOTAL_NO_OF_DEBIT :=
               V_TEMP_TRIALBAL (INI).T_TOTAL_NO_OF_DEBIT;
            TEMP_TY_TRIAL_BAL.DEBIT := V_TEMP_TRIALBAL (INI).T_DEBIT;
            TEMP_TY_TRIAL_BAL.TOTAL_NO_OF_CREDIT :=
               V_TEMP_TRIALBAL (INI).T_TOTAL_NO_OF_CREDIT;
            TEMP_TY_TRIAL_BAL.CREDIT := V_TEMP_TRIALBAL (INI).T_CREDIT;

            PIPE ROW (TEMP_TY_TRIAL_BAL);
         END LOOP;
      --  DBMS_OUTPUT.put_line(V_TEMP_TABLEA.COUNT);
      END IF;
   END FN_TRIAL_BAL;
END PKG_TRIAL_BAL;
/
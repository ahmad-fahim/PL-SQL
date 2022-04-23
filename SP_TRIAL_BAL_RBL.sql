CREATE INDEX IND_ACCOUNTCODE ON ACCOUNTCODE(TRIM (ACCOUNTCODE)) ;

CREATE INDEX IND_MASTERVOUCHER_1 ON MASTERVOUCHER(TRIM(ACCOUNTCODE) , TRANSDATE , TRIM(DESCRIPTION));



CREATE TABLE DAILYGENERALLEDGER
(
  BRANCH_CODE         NUMBER(5),
  DEMAND_DATE         DATE,
  FIRSTHEAD           VARCHAR2(150 BYTE),
  BRANCHGLCODE        VARCHAR2(15 BYTE),
  SECONDEHEAD         VARCHAR2(150 BYTE),
  OPENINGBAL          NUMBER(18,2),
  TOTAL_NO_OF_DEBIT   NUMBER,
  DEBIT               NUMBER(18,2),
  TOTAL_NO_OF_CREDIT  NUMBER,
  CREDIT              NUMBER(18,2),
  CLOSINGBAL          NUMBER(18,2)
)



CREATE OR REPLACE PROCEDURE SP_TRIAL_BAL (V_ENTITY_NUM     NUMBER,
                                          P_BRN_CODE       NUMBER,
                                          P_DEMAND_DATE    DATE)
IS
   V_CBD                       DATE;
   V_CR_SUM_FROM_DEMAND_DATE   NUMBER;
   V_DR_SUM_FROM_DEMAND_DATE   NUMBER;
   V_CR_BAL                    NUMBER;
   V_DR_BAL                    NUMBER;
BEGIN
   SELECT MN_CURR_BUSINESS_DATE INTO V_CBD FROM MAINCONT;

   EXECUTE IMMEDIATE 'TRUNCATE TABLE DAILYGENERALLEDGER';


   ------------------------ Basic data preperation -------------------------


   IF TO_CHAR (TO_DATE (V_CBD), 'YYYY') =
         TO_CHAR (TO_DATE (P_DEMAND_DATE - 1), 'YYYY')
   THEN
      BEGIN
         FOR IDX
            IN (SELECT TRIM (ACCOUNTCODE) ACCOUNT_CODE,
                       TRIM (BRANCHGLCODE) BRANCHGLCODE,
                       ACCOUNTHEAD
                  FROM ACCOUNTCODE
                  WHERE ACNTCD_BRN_CODE = P_BRN_CODE)
         LOOP
            -- DEBIT, CREDIT, PREVIOUSDEBIT, PREVIOUSCREDIT

            SELECT SUM (PREVIOUSCREDIT + CREDIT), SUM (PREVIOUSDEBIT + DEBIT)
              INTO V_CR_BAL, V_DR_BAL
              FROM ACCOUNTCODE
             WHERE TRIM (ACCOUNTCODE) = IDX.ACCOUNT_CODE
             AND ACNTCD_BRN_CODE = P_BRN_CODE;

            V_CR_SUM_FROM_DEMAND_DATE :=
               GETGLSUMCR_TB (V_ENTITY_NUM,
                           P_BRN_CODE,
                           IDX.ACCOUNT_CODE,
                           TO_DATE (P_DEMAND_DATE - 1));
            V_DR_SUM_FROM_DEMAND_DATE :=
               GETGLSUMDR_TB (V_ENTITY_NUM,
                           P_BRN_CODE,
                           IDX.ACCOUNT_CODE,
                           TO_DATE (P_DEMAND_DATE - 1));

            V_CR_BAL := V_CR_BAL - V_CR_SUM_FROM_DEMAND_DATE;
            V_DR_BAL := V_DR_BAL - V_DR_SUM_FROM_DEMAND_DATE;

            INSERT INTO DAILYGENERALLEDGER (BRANCH_CODE  ,
                                            DEMAND_DATE ,
                                            FIRSTHEAD,
                                            BRANCHGLCODE,
                                            SECONDEHEAD,
                                            OPENINGBAL,
                                            TOTAL_NO_OF_DEBIT,
                                            DEBIT,
                                            TOTAL_NO_OF_CREDIT,
                                            CREDIT,
                                            CLOSINGBAL)
                 VALUES (P_BRN_CODE ,
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
         FOR IDX
            IN (SELECT TRIM (ACCOUNTCODE) ACCOUNT_CODE,
                       TRIM (BRANCHGLCODE) BRANCHGLCODE,
                       ACCOUNTHEAD
                  FROM ACCOUNTCODE
                  WHERE ACNTCD_BRN_CODE = P_BRN_CODE)
         LOOP
            V_CR_BAL :=
               GetYGLSumCr_TB (V_ENTITY_NUM, P_BRN_CODE, IDX.ACCOUNT_CODE);
            V_DR_BAL :=
               GetYGLSumDr_TB (V_ENTITY_NUM, P_BRN_CODE, IDX.ACCOUNT_CODE);


            V_CR_SUM_FROM_DEMAND_DATE :=
               GETGLSUMCR_TB (V_ENTITY_NUM,
                           P_BRN_CODE,
                           IDX.ACCOUNT_CODE,
                           TO_DATE (P_DEMAND_DATE - 1));
            V_DR_SUM_FROM_DEMAND_DATE :=
               GETGLSUMDR_TB (V_ENTITY_NUM,
                           P_BRN_CODE,
                           IDX.ACCOUNT_CODE,
                           TO_DATE (P_DEMAND_DATE - 1));

            V_CR_BAL := V_CR_BAL - V_CR_SUM_FROM_DEMAND_DATE;
            V_DR_BAL := V_DR_BAL - V_DR_SUM_FROM_DEMAND_DATE;

            INSERT INTO DAILYGENERALLEDGER (BRANCH_CODE  ,
                                            DEMAND_DATE ,
                                            FIRSTHEAD,
                                            BRANCHGLCODE,
                                            SECONDEHEAD,
                                            OPENINGBAL,
                                            TOTAL_NO_OF_DEBIT,
                                            DEBIT,
                                            TOTAL_NO_OF_CREDIT,
                                            CREDIT,
                                            CLOSINGBAL)
                 VALUES (P_BRN_CODE ,
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
      FOR IDX
         IN (SELECT ACCOUNTCODE.ACCOUNTHEAD,
                    TRIM (ACCOUNTCODE.BRANCHGLCODE) BRANCHGLCODE,
                    MASTER_VOUCHER.ACCOUNTCODE ACCOUNT_CODE,
                    MASTER_VOUCHER.DAY_NO_OF_DEBIT,
                    MASTER_VOUCHER.DAY_DEBIT,
                    MASTER_VOUCHER.DAY_NO_OF_CREDIT,
                    MASTER_VOUCHER.DAY_CREDIT
               FROM ACCOUNTCODE,
                    (  SELECT BRN_CODE,
                              TRIM (ACCOUNTCODE) ACCOUNTCODE,
                              SUM (NOOFDEBIT) DAY_NO_OF_DEBIT,
                              SUM (DEBIT) DAY_DEBIT,
                              SUM (NOOFCREDIT) DAY_NO_OF_CREDIT,
                              SUM (CREDIT) DAY_CREDIT
                         FROM MASTERVOUCHER
                        WHERE TRANSDATE = P_DEMAND_DATE
                        AND BRN_CODE = P_BRN_CODE 
                             -- AND TRIM (Description) <> 'Closing Voucher after Initialize.'
                     GROUP BY BRN_CODE, TRIM (ACCOUNTCODE)
                     ORDER BY ACCOUNTCODE) MASTER_VOUCHER
              WHERE TRIM (ACCOUNTCODE.ACCOUNTCODE) = TRIM (MASTER_VOUCHER.ACCOUNTCODE)
              AND MASTER_VOUCHER.BRN_CODE = ACCOUNTCODE.ACNTCD_BRN_CODE)
      LOOP
         UPDATE DAILYGENERALLEDGER
            SET DEBIT = IDX.DAY_DEBIT,
                CREDIT = IDX.DAY_CREDIT,
                TOTAL_NO_OF_DEBIT = IDX.DAY_NO_OF_DEBIT,
                TOTAL_NO_OF_CREDIT = IDX.DAY_NO_OF_CREDIT
          WHERE BRANCHGLCODE = IDX.BRANCHGLCODE;
      END LOOP;
   END;


   UPDATE DAILYGENERALLEDGER
      SET CLOSINGBAL = OPENINGBAL + CREDIT - DEBIT;


   DELETE FROM DAILYGENERALLEDGER
         WHERE OPENINGBAL = 0 AND CREDIT = 0 AND DEBIT = 0 AND CLOSINGBAL = 0;


   -------------------  Update debit & credit amount for that particular date end----------------------


   -------------------- First head update ------------------

   BEGIN
      FOR IDX
         IN (SELECT TRIM (ACCOUNTCODE_2.ACCOUNTCODE),
                    ACCOUNTCODE_2.ACCOUNTHEAD ACCOUNTHEAD_FIRST,
                    ACCOUNTCODE_1.*
               FROM ACCOUNTCODE ACCOUNTCODE_2,
                    (SELECT ACCOUNTCODE.ACNTCD_BRN_CODE ACNTCD_BRN_CODE,
                            TRIM (ACCOUNTCODE.ACCOUNTHEAD) ACCOUNTHEAD_SECOND,
                            TRIM (ACCOUNTCODE.FIRSTLEVEL) FIRSTLEVEL,
                            TRIM (ACCOUNTCODE.BRANCHGLCODE) BRANCHGLCODE,
                            TRIM (ACCOUNTCODE.SECONDLEVEL) SECONDLEVEL
                       FROM ACCOUNTCODE, DAILYGENERALLEDGER
                      WHERE     DAILYGENERALLEDGER.BRANCHGLCODE =
                                   TRIM (ACCOUNTCODE.BRANCHGLCODE)
                            AND ACCOUNTCODE.ACCOUNTHEAD =
                                   DAILYGENERALLEDGER.SECONDEHEAD
                            AND ACCOUNTCODE.ACNTCD_BRN_CODE = P_BRN_CODE) ACCOUNTCODE_1
              WHERE TRIM (ACCOUNTCODE_2.ACCOUNTCODE) = ACCOUNTCODE_1.FIRSTLEVEL
              AND ACCOUNTCODE_1.ACNTCD_BRN_CODE = ACCOUNTCODE_2.ACNTCD_BRN_CODE )
      LOOP
         UPDATE DAILYGENERALLEDGER D
            SET D.FIRSTHEAD = IDX.ACCOUNTHEAD_FIRST
          WHERE     D.BRANCHGLCODE = IDX.BRANCHGLCODE
                AND D.SECONDEHEAD = IDX.ACCOUNTHEAD_SECOND;
      END LOOP;
   END;
-------------------- First head update END ------------------
END SP_TRIAL_BAL;
/


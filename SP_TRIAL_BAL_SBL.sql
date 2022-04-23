CREATE INDEX IND_ACCOUNTCODE ON ACCOUNTCODE(TRIM (ACCOUNTCODE)) ;

CREATE INDEX IND_MASTERVOUCHER_1 ON MASTERVOUCHER(TRIM(ACCOUNTCODE) , TRANSDATE , TRIM(DESCRIPTION));





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
                  FROM ACCOUNTCODE)
         LOOP
            -- DEBIT, CREDIT, PREVIOUSDEBIT, PREVIOUSCREDIT

            SELECT SUM (PREVIOUSCREDIT + CREDIT), SUM (PREVIOUSDEBIT + DEBIT)
              INTO V_CR_BAL, V_DR_BAL
              FROM ACCOUNTCODE
             WHERE TRIM (ACCOUNTCODE) = IDX.ACCOUNT_CODE;

            V_CR_SUM_FROM_DEMAND_DATE :=
               GETGLSUMCR (V_ENTITY_NUM,
                           P_BRN_CODE,
                           IDX.ACCOUNT_CODE,
                           TO_DATE (P_DEMAND_DATE - 1));
            V_DR_SUM_FROM_DEMAND_DATE :=
               GETGLSUMDR (V_ENTITY_NUM,
                           P_BRN_CODE,
                           IDX.ACCOUNT_CODE,
                           TO_DATE (P_DEMAND_DATE - 1));

            V_CR_BAL := V_CR_BAL - V_CR_SUM_FROM_DEMAND_DATE;
            V_DR_BAL := V_DR_BAL - V_DR_SUM_FROM_DEMAND_DATE;

            INSERT INTO DAILYGENERALLEDGER (FIRSTHEAD,
                                            BRANCHGLCODE,
                                            SECONDEHEAD,
                                            OPENINGBAL,
                                            DEBIT,
                                            CREDIT,
                                            CLOSINGBAL)
                 VALUES (NULL,
                         IDX.BRANCHGLCODE,
                         IDX.ACCOUNTHEAD,
                         V_CR_BAL - V_DR_BAL,
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
                  FROM ACCOUNTCODE)
         LOOP
            V_CR_BAL :=
               GetYGLSumCr (V_ENTITY_NUM, P_BRN_CODE, IDX.ACCOUNT_CODE);
            V_DR_BAL :=
               GetYGLSumDr (V_ENTITY_NUM, P_BRN_CODE, IDX.ACCOUNT_CODE);


            V_CR_SUM_FROM_DEMAND_DATE :=
               GETGLSUMCR (V_ENTITY_NUM,
                           P_BRN_CODE,
                           IDX.ACCOUNT_CODE,
                           TO_DATE (P_DEMAND_DATE - 1));
            V_DR_SUM_FROM_DEMAND_DATE :=
               GETGLSUMDR (V_ENTITY_NUM,
                           P_BRN_CODE,
                           IDX.ACCOUNT_CODE,
                           TO_DATE (P_DEMAND_DATE - 1));

            V_CR_BAL := V_CR_BAL - V_CR_SUM_FROM_DEMAND_DATE;
            V_DR_BAL := V_DR_BAL - V_DR_SUM_FROM_DEMAND_DATE;

            INSERT INTO DAILYGENERALLEDGER (FIRSTHEAD,
                                            BRANCHGLCODE,
                                            SECONDEHEAD,
                                            OPENINGBAL,
                                            DEBIT,
                                            CREDIT,
                                            CLOSINGBAL)
                 VALUES (NULL,
                         IDX.BRANCHGLCODE,
                         IDX.ACCOUNTHEAD,
                         V_CR_BAL - V_DR_BAL,
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
                    MASTER_VOUCHER.DAY_DEBIT,
                    MASTER_VOUCHER.DAY_CREDIT
               FROM ACCOUNTCODE,
                    (  SELECT TRIM (ACCOUNTCODE) ACCOUNTCODE,
                              SUM (DEBIT) DAY_DEBIT,
                              SUM (CREDIT) DAY_CREDIT
                         FROM MASTERVOUCHER
                        WHERE     TRANSDATE = P_DEMAND_DATE
                              AND TRIM (Description) <>
                                     'Closing Voucher after Initialize.'
                     GROUP BY TRIM (ACCOUNTCODE)
                     ORDER BY ACCOUNTCODE) MASTER_VOUCHER
              WHERE TRIM (ACCOUNTCODE.ACCOUNTCODE) =
                       TRIM (MASTER_VOUCHER.ACCOUNTCODE))
      LOOP
         UPDATE DAILYGENERALLEDGER
            SET DEBIT = IDX.DAY_DEBIT, CREDIT = IDX.DAY_CREDIT
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
                    (SELECT TRIM (ACCOUNTCODE.ACCOUNTHEAD) ACCOUNTHEAD_SECOND,
                            TRIM (ACCOUNTCODE.FIRSTLEVEL) FIRSTLEVEL,
                            TRIM (ACCOUNTCODE.BRANCHGLCODE) BRANCHGLCODE,
                            TRIM (ACCOUNTCODE.SECONDLEVEL) SECONDLEVEL
                       FROM ACCOUNTCODE, DAILYGENERALLEDGER
                      WHERE     DAILYGENERALLEDGER.BRANCHGLCODE =
                                   TRIM (ACCOUNTCODE.BRANCHGLCODE)
                            AND ACCOUNTCODE.ACCOUNTHEAD =
                                   DAILYGENERALLEDGER.SECONDEHEAD) ACCOUNTCODE_1
              WHERE TRIM (ACCOUNTCODE_2.ACCOUNTCODE) =
                       ACCOUNTCODE_1.FIRSTLEVEL)
      LOOP
         UPDATE DAILYGENERALLEDGER D
            SET D.FIRSTHEAD = IDX.ACCOUNTHEAD_FIRST
          WHERE     D.BRANCHGLCODE = IDX.BRANCHGLCODE
                AND D.SECONDEHEAD = IDX.ACCOUNTHEAD_SECOND;
      END LOOP;
   END;
-------------------- First head update ------------------
END SP_TRIAL_BAL;
/
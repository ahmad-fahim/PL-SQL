CREATE OR REPLACE PROCEDURE SP_MIG_LOAN_ACCRU_CORRECTION (
   P_NARATION VARCHAR2)
IS
   V_BATCH_NUMBER   NUMBER;
BEGIN
   INSERT INTO NEW_LOAN_ACCRU
      SELECT AA.LOANIA_ACNT_NUM,
             AA.LOANIA_INT_ON_AMT - LL.LOANIAMRR_INT_AMT DIFF,
             NULL
        FROM IACLINK I,
             LOANIAMRR LL,
             MIG_DETAIL M,
             TEMP_LOANIA AA
       WHERE     I.IACLINK_ACTUAL_ACNUM = AA.LOANIA_ACNT_NUM
             AND LL.LOANIAMRR_ACNT_NUM = I.IACLINK_INTERNAL_ACNUM
             AND I.IACLINK_BRN_CODE = M.BRANCH_CODE
             AND LL.LOANIAMRR_VALUE_DATE = M.MIG_END_DATE
             AND I.IACLINK_ENTITY_NUM = 1
             AND LL.LOANIAMRR_ENTITY_NUM = 1
             AND LL.LOANIAMRR_ACCRUAL_DATE = M.MIG_END_DATE
             AND LL.LOANIAMRR_BRN_CODE = M.BRANCH_CODE;

   COMMIT;

   BEGIN
      FOR IDX
         IN (SELECT I.IACLINK_INTERNAL_ACNUM,
                    A.NEW_ACCRUAL,
                    M.MIG_END_DATE,
                    I.IACLINK_BRN_CODE
               FROM NEW_LOAN_ACCRU A,
                    IACLINK I,
                    LOANACNTS L,
                    MIG_DETAIL M
              WHERE     I.IACLINK_ENTITY_NUM = 1
                    AND L.LNACNT_ENTITY_NUM = 1
                    AND I.IACLINK_ACTUAL_ACNUM = A.ACCOUNT_NO
                    AND L.LNACNT_INTERNAL_ACNUM = I.IACLINK_INTERNAL_ACNUM
                    AND I.IACLINK_BRN_CODE = M.BRANCH_CODE
                    AND L.LNACNT_INT_APPLIED_UPTO_DATE <= M.MIG_END_DATE
                    AND A.REMARKS IS NULL)
      LOOP
         UPDATE LOANIAMRR LL
            SET LL.LOANIAMRR_TOTAL_NEW_INT_AMT =
                   LL.LOANIAMRR_TOTAL_NEW_INT_AMT + IDX.NEW_ACCRUAL,
                LL.LOANIAMRR_INT_AMT = LL.LOANIAMRR_INT_AMT + IDX.NEW_ACCRUAL,
                LL.LOANIAMRR_INT_AMT_RND =
                   LL.LOANIAMRR_INT_AMT_RND + IDX.NEW_ACCRUAL
          WHERE     LL.LOANIAMRR_ENTITY_NUM = 1
                AND LL.LOANIAMRR_BRN_CODE = IDX.IACLINK_BRN_CODE
                AND LL.LOANIAMRR_ACNT_NUM = IDX.IACLINK_INTERNAL_ACNUM
                AND LL.LOANIAMRR_VALUE_DATE = IDX.MIG_END_DATE
                AND LL.LOANIAMRR_ACCRUAL_DATE = IDX.MIG_END_DATE;

         -----------UPDATE LOANIAMRRDTL ----------

         UPDATE LOANIAMRRDTL LL
            SET LL.LOANIAMRRDTL_UPTO_AMT =
                   LL.LOANIAMRRDTL_UPTO_AMT + IDX.NEW_ACCRUAL,
                LL.LOANIAMRRDTL_INT_AMT =
                   LL.LOANIAMRRDTL_INT_AMT + IDX.NEW_ACCRUAL,
                LL.LOANIAMRRDTL_INT_AMT_RND =
                   LL.LOANIAMRRDTL_INT_AMT_RND + IDX.NEW_ACCRUAL
          WHERE     LL.LOANIAMRRDTL_ENTITY_NUM = 1
                AND LL.LOANIAMRRDTL_BRN_CODE = IDX.IACLINK_BRN_CODE
                AND LL.LOANIAMRRDTL_ACNT_NUM = IDX.IACLINK_INTERNAL_ACNUM
                AND LL.LOANIAMRRDTL_VALUE_DATE = IDX.MIG_END_DATE
                AND LL.LOANIAMRRDTL_ACCRUAL_DATE = IDX.MIG_END_DATE;

         UPDATE NEW_LOAN_ACCRU
            SET REMARKS = 'SUCCESSFUL WITH BATCH : '
          WHERE ACCOUNT_NO =
                   (SELECT IACLINK_ACTUAL_ACNUM
                      FROM IACLINK
                     WHERE IACLINK_INTERNAL_ACNUM =
                              IDX.IACLINK_INTERNAL_ACNUM);
      END LOOP;
   END;


   -----------------POST VOUCHER------------------------

   BEGIN
      FOR IDX
         IN (  SELECT I.IACLINK_BRN_CODE,
                      LP.LNPRDAC_INT_INCOME_GL,
                      LP.LNPRDAC_INT_ACCR_GL,
                      SUM (A.NEW_ACCRUAL) AMOUNT,
                      I.IACLINK_PROD_CODE
                 FROM IACLINK I,
                      LOANACNTS L,
                      LNPRODACPM LP,
                      MIG_DETAIL M,
                      NEW_LOAN_ACCRU A
                WHERE     I.IACLINK_ENTITY_NUM = 1
                      AND L.LNACNT_ENTITY_NUM = 1
                      AND I.IACLINK_ACTUAL_ACNUM = A.ACCOUNT_NO
                      AND L.LNACNT_INTERNAL_ACNUM = I.IACLINK_INTERNAL_ACNUM
                      AND I.IACLINK_BRN_CODE = M.BRANCH_CODE
                      AND L.LNACNT_INT_APPLIED_UPTO_DATE <= M.MIG_END_DATE
                      AND LP.LNPRDAC_PROD_CODE = I.IACLINK_PROD_CODE
                      AND A.REMARKS = 'SUCCESSFUL WITH BATCH : '
             GROUP BY I.IACLINK_BRN_CODE,
                      LP.LNPRDAC_INT_ACCR_GL,
                      LP.LNPRDAC_INT_INCOME_GL,
                      I.IACLINK_PROD_CODE)
      LOOP
         IF IDX.AMOUNT > 0
         THEN
            SP_AUTOPOST_TRANSACTION_MANUAL (
               IDX.IACLINK_BRN_CODE,
               IDX.LNPRDAC_INT_INCOME_GL,
               IDX.LNPRDAC_INT_ACCR_GL,
               ABS (IDX.AMOUNT),
               ABS (IDX.AMOUNT),
               0,
               0,
               0,
               0,
               0,
               NULL,
               0,
               NULL,
               'BDT',
               '127.0.0.1',                                     -- terminal id
               'INTELECT',                                             -- user
               'Loan Accrual Correction | ' || P_NARATION,
               V_BATCH_NUMBER);
         END IF;

         IF IDX.AMOUNT < 0
         THEN
            SP_AUTOPOST_TRANSACTION_MANUAL (
               IDX.IACLINK_BRN_CODE,
               IDX.LNPRDAC_INT_ACCR_GL,
               IDX.LNPRDAC_INT_INCOME_GL,
               ABS (IDX.AMOUNT),
               ABS (IDX.AMOUNT),
               0,
               0,
               0,
               0,
               0,
               NULL,
               0,
               NULL,
               'BDT',
               '127.0.0.1',                                     -- terminal id
               'INTELECT',                                             -- user
               'Loan Accrual Correction | ' || P_NARATION,
               V_BATCH_NUMBER);
         END IF;

         DBMS_OUTPUT.PUT_LINE (V_BATCH_NUMBER);

         UPDATE NEW_LOAN_ACCRU
            SET REMARKS = REMARKS || V_BATCH_NUMBER
          WHERE     ACCOUNT_NO IN
                       (SELECT IACLINK_ACTUAL_ACNUM
                          FROM IACLINK, NEW_LOAN_ACCRU
                         WHERE     IACLINK_ACTUAL_ACNUM = ACCOUNT_NO
                               AND IACLINK_PROD_CODE = IDX.IACLINK_PROD_CODE)
                AND REMARKS = 'SUCCESSFUL WITH BATCH : ';
      END LOOP;
   END;


   UPDATE NEW_LOAN_ACCRU
      SET REMARKS = 'NOT DONE'
    WHERE REMARKS IS NULL;
END SP_MIG_LOAN_ACCRU_CORRECTION;
/
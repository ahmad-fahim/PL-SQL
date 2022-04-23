CREATE OR REPLACE PROCEDURE SP_GEN_CL_DATA (
   P_FROM_BRN     NUMBER,
   P_TO_BRN       NUMBER,
   P_ASON_DATE    DATE)
IS
   V_ASON_DATE   DATE;
BEGIN
   V_ASON_DATE := P_ASON_DATE;

   FOR IDX
      IN (SELECT *
            FROM (SELECT BRANCH_CODE, ROWNUM BRANCH_SL
                    FROM (  SELECT BRANCH_CODE
                              FROM MIG_DETAIL
                             WHERE BRANCH_CODE NOT IN
                                      (SELECT BRN_CODE
                                         FROM CL_TMP_DATA_INV
                                        WHERE ASON_DATE = V_ASON_DATE)
                          ORDER BY BRANCH_CODE))
           WHERE BRANCH_SL BETWEEN P_FROM_BRN AND P_TO_BRN)
   LOOP
      SP_CL_INSERT_DATA (1,
                         V_ASON_DATE,
                         V_ASON_DATE,
                         IDX.BRANCH_CODE);
      COMMIT;
   END LOOP;
END SP_GEN_CL_DATA;
/
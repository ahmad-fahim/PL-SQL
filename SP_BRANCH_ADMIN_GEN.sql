CREATE OR REPLACE PROCEDURE SP_BRANCH_ADMIN_GEN
IS
V_LIST_ID NUMBER ;
V_RETURN NUMBER ;
BEGIN
V_LIST_ID := 12 ;
   BEGIN
      FOR IDX
         IN (  SELECT DISTINCT MBRN_PARENT_ADMIN_CODE
                 FROM MBRN M
                WHERE     MBRN_PARENT_ADMIN_CODE NOT IN (0, 18)
                      AND M.MBRN_CODE IN (SELECT BRANCH_CODE FROM MIG_DETAIL)
             ORDER BY MBRN_PARENT_ADMIN_CODE)
      LOOP
         V_RETURN := FN_GET_BRN_CODE(IDX.MBRN_PARENT_ADMIN_CODE, 0, V_LIST_ID );
         
         UPDATE BRANCH_ADMIN SET ADMIN_CODE = IDX.MBRN_PARENT_ADMIN_CODE WHERE LIST_ID = V_LIST_ID ;
         
         V_LIST_ID := V_LIST_ID + 1 ;
      END LOOP;
   END;
END;

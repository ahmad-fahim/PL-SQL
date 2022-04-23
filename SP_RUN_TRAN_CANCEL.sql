CREATE OR REPLACE PROCEDURE SP_RUN_TRAN_CANCEL
IS 
   P_ERROR_MESSAGE   VARCHAR2 (4000);
BEGIN
   BEGIN
      FOR IDX IN (  SELECT *
                      FROM BATCH_CANCEL
                  WHERE ERROR_MESSAGE IS NULL OR ERROR_MESSAGE <> 'SUCCESSFUL'
                  ORDER BY BRANCH_CODE, TRAN_DATE, BATCH_NUMBER)
      LOOP
         SP_TRAN_CANCEL (IDX.ENTITY_NUM,
                         IDX.BRANCH_CODE,
                         IDX.TRAN_DATE,
                         IDX.BATCH_NUMBER,
                         IDX.USER_ID,
                         P_ERROR_MESSAGE);

         IF P_ERROR_MESSAGE IS NOT NULL
         THEN
            UPDATE BATCH_CANCEL
               SET PROCESSED = '1', ERROR_MESSAGE = 'FAILED |' || P_ERROR_MESSAGE
             WHERE     ENTITY_NUM = IDX.ENTITY_NUM
                   AND BRANCH_CODE = IDX.BRANCH_CODE
                   AND TRAN_DATE = IDX.TRAN_DATE
                   AND BATCH_NUMBER = IDX.BATCH_NUMBER;
         ELSE
            UPDATE BATCH_CANCEL
               SET PROCESSED = '1', ERROR_MESSAGE = 'SUCCESSFUL'
             WHERE     ENTITY_NUM = IDX.ENTITY_NUM
                   AND BRANCH_CODE = IDX.BRANCH_CODE
                   AND TRAN_DATE = IDX.TRAN_DATE
                   AND BATCH_NUMBER = IDX.BATCH_NUMBER;
         END IF;
         COMMIT ;
      END LOOP;
   END;
END;
/

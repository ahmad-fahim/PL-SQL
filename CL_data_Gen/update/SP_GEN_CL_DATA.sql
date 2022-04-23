CREATE OR REPLACE PROCEDURE SP_GEN_CL_DATA (P_ASON_DATE    DATE,
                                            V_BRNLIST      VARCHAR2)
IS
   V_ASON_DATE       DATE;
   V_CBD             DATE;
   W_THREAD_NUMBER   NUMBER;
   W_BRANCH_CODE     NUMBER;
BEGIN
   V_ASON_DATE := P_ASON_DATE;

   SELECT MN_CURR_BUSINESS_DATE INTO V_CBD FROM MAINCONT;

   FOR IDX IN (    SELECT DISTINCT TRIM (REGEXP_SUBSTR (V_BRNLIST,
                                                        '[^,]+',
                                                        1,
                                                        LEVEL))
                                      AS BRNCODE
                     FROM DUAL
               CONNECT BY REGEXP_SUBSTR (V_BRNLIST,
                                         '[^,]+',
                                         1,
                                         LEVEL)
                             IS NOT NULL)
   LOOP      
      SP_CL_INSERT_DATA (1,
                         V_ASON_DATE,
                         V_CBD,
                         TO_NUMBER(IDX.BRNCODE));
                         
      COMMIT;
   END LOOP;
END SP_GEN_CL_DATA;
/
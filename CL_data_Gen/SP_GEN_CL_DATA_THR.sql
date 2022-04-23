CREATE OR REPLACE PROCEDURE SP_GEN_CL_DATA_THR (V_NUMBER_OF_THREAD    NUMBER,
                                                P_ASON_DATE           DATE)
IS
   V_TOTAL_BRANCH   NUMBER;
   V_PER_PORTION    NUMBER;
   V_TO_BRANCH      NUMBER := 0;
   V_ASON_DATE      DATE;
   LN_DUMMY         NUMBER;
BEGIN
   V_ASON_DATE := P_ASON_DATE;


   DELETE FROM CL_TMP_DATA_INV  WHERE ASON_DATE = V_ASON_DATE;

   DELETE FROM CL_TMP_DATA WHERE ASON_DATE = V_ASON_DATE;

   SELECT COUNT (*)
     INTO V_TOTAL_BRANCH
     FROM (  SELECT BRANCH_CODE, ROWNUM BRANCH_SL
               FROM MIG_DETAIL
           ORDER BY BRANCH_CODE)
    WHERE BRANCH_CODE NOT IN (SELECT BRN_CODE
                                FROM CL_TMP_DATA_INV
                               WHERE ASON_DATE = V_ASON_DATE);

   V_PER_PORTION := CEIL (V_TOTAL_BRANCH / V_NUMBER_OF_THREAD);
   DBMS_OUTPUT.PUT_LINE (V_PER_PORTION);


   FOR IDX IN 1 .. V_NUMBER_OF_THREAD
   LOOP
      V_TO_BRANCH := V_TO_BRANCH + V_PER_PORTION;
      DBMS_JOB.SUBMIT (
         LN_DUMMY,
            'begin SP_GEN_CL_DATA('
         || TO_CHAR (V_TO_BRANCH - V_PER_PORTION + 1)
         || ', '
         || TO_CHAR (V_TO_BRANCH)
         || ','''
         || V_ASON_DATE
         || ''' ); end;');
   END LOOP;

   COMMIT;
END SP_GEN_CL_DATA_THR;
/
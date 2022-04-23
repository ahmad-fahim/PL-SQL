CREATE OR REPLACE PROCEDURE SP_GEN_CL_DATA_THR (
   P_NUMBER_OF_THREAD    NUMBER,
   P_ASON_DATE           DATE,
   P_RE_GENERATE_FLAG    VARCHAR2)
IS
   V_PER_PORTION    NUMBER;
   V_TO_BRANCH      NUMBER := 0;
   V_ASON_DATE      DATE;
   V_LN_DUMMY         NUMBER;
   V_BRNLIST        VARCHAR2(4000);
  
   TYPE TY_BRNLIST IS RECORD
   (
      V_BRANCH_CODE     NUMBER,
      V_THREAD_NUMBER   NUMBER
   );

   TYPE TAB_BRNLIST IS TABLE OF TY_BRNLIST
      INDEX BY PLS_INTEGER;

   BRNLIST_REC   TAB_BRNLIST;
   
   
   PROCEDURE INIT_BRANCH_THREAD (V_NUMBER_OF_THREAD NUMBER, P_ASON_DATE DATE)
   IS
      V_TOTAL_BRANCH   NUMBER;
      V_PER_PORTION    NUMBER;
      V_TO_BRANCH      NUMBER := 0;
      V_ASON_DATE      DATE;
      LN_DUMMY         NUMBER;
      V_SQL            VARCHAR2 (3000);
      V_ERROR          VARCHAR2 (1000);
   BEGIN
      V_ASON_DATE := P_ASON_DATE;

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


      V_SQL :=
         'SELECT BRANCH_CODE , CEIL(ROWNUM / :V_PER_PORTION)  NUM_ROW
     FROM (  SELECT BRANCH_CODE, ROWNUM BRANCH_SL
               FROM MIG_DETAIL
           ORDER BY BRANCH_CODE)
    WHERE BRANCH_CODE NOT IN (SELECT BRN_CODE
                                FROM CL_TMP_DATA_INV
                               WHERE ASON_DATE = :V_ASON_DATE) ';

      EXECUTE IMMEDIATE V_SQL
         BULK COLLECT INTO BRNLIST_REC
         USING V_PER_PORTION, V_ASON_DATE;
   END INIT_BRANCH_THREAD;
   
   
BEGIN

   V_ASON_DATE := P_ASON_DATE;
   
   IF P_RE_GENERATE_FLAG = '1' THEN 
       DELETE FROM CL_TMP_DATA_INV  WHERE ASON_DATE = V_ASON_DATE;
       DELETE FROM CL_TMP_DATA WHERE ASON_DATE = V_ASON_DATE;
   END IF ;
   
   INIT_BRANCH_THREAD(P_NUMBER_OF_THREAD, V_ASON_DATE);
   FOR IDX IN 1 .. P_NUMBER_OF_THREAD
   LOOP
       V_BRNLIST := '' ;
       FOR BRN IN 1 .. BRNLIST_REC.COUNT
       LOOP

        IF BRNLIST_REC(BRN).V_THREAD_NUMBER = IDX THEN
            V_BRNLIST := V_BRNLIST || ',' || BRNLIST_REC(BRN).V_BRANCH_CODE ;
        END IF ;
        
       END LOOP;
       
       V_BRNLIST := SUBSTR(V_BRNLIST,2,LENGTH(V_BRNLIST)) ;
       V_BRNLIST :=  CHR(39) || V_BRNLIST || CHR(39);
       
      DBMS_OUTPUT.PUT_LINE(        'BEGIN SP_GEN_CL_DATA(''' || V_ASON_DATE || ''', ' || V_BRNLIST || ' ); END;');
      DBMS_JOB.SUBMIT ( V_LN_DUMMY, 'BEGIN SP_GEN_CL_DATA(''' || V_ASON_DATE || ''', ' || V_BRNLIST || ' ); END;');
   END LOOP;
   
   COMMIT;
END SP_GEN_CL_DATA_THR;
/

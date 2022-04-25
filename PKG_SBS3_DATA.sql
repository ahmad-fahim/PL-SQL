CREATE OR REPLACE PACKAGE PKG_SBS3_DATA IS

  TYPE TY_TEMP_SBS3_DATA IS RECORD(
    TOTAL_DATA VARCHAR2(1000) );

  TYPE TTY_TEMP_SBS3DATA IS TABLE OF TY_TEMP_SBS3_DATA;

  FUNCTION FN_SBS3_DATA(P_ENTITY_NUM NUMBER , P_BRANCH_CODE NUMBER, P_FROM_DATE DATE , P_TO_DATE DATE) RETURN TTY_TEMP_SBS3DATA
    PIPELINED;

END;
/

CREATE OR REPLACE PACKAGE BODY PKG_SBS3_DATA
IS
   TEMP_TY_SBS3_DATA   PKG_SBS3_DATA.TY_TEMP_SBS3_DATA;

   TYPE SBSDATA IS RECORD (TEMP_DATA CLOB);

   TYPE IN_SBSDATA IS TABLE OF SBSDATA
      INDEX BY PLS_INTEGER;

   V_IN_SBSDATA        IN_SBSDATA;
   l_start             NUMBER;

   V_SL                NUMBER := 0;
   ---V_FILE_DATA    CLOB;
   V_DATA              VARCHAR2 (3000);

   FUNCTION FN_SBS3_DATA (P_ENTITY_NUM     NUMBER,
                          P_BRANCH_CODE    NUMBER,
                          P_FROM_DATE      DATE,
                          P_TO_DATE        DATE)
      RETURN TTY_TEMP_SBS3DATA
      PIPELINED
   --RETURN VARCHAR2
   IS
      TYPE TEMP_SBS3_DATA IS RECORD (TOTAL_DATA CLOB);

      TYPE TY_SBS3_DATA IS TABLE OF TEMP_SBS3_DATA;

      V_TY_SBS3_DATA   TY_SBS3_DATA;
      V_DATA_QUERY     CLOB;
      
      V_CBD         DATE ;
   BEGIN
      -- l_start := DBMS_UTILITY.get_time;
      V_SL := 0;
      
      SELECT MN_CURR_BUSINESS_DATE INTO V_CBD FROM MAINCONT ; 
      SP_SBS3_DATA_QUERY (P_FROM_DATE ,
                          V_DATA_QUERY);
                          
                          
                          

      EXECUTE IMMEDIATE V_DATA_QUERY
         BULK COLLECT INTO V_IN_SBSDATA
         USING P_TO_DATE,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_FROM_DATE,
               P_TO_DATE,
               P_ENTITY_NUM,
               P_ENTITY_NUM,
               P_TO_DATE,
               V_CBD,
               --P_BRANCH_CODE,
               P_ENTITY_NUM,
               P_TO_DATE,
               P_ENTITY_NUM,
               P_TO_DATE,
               V_CBD;

      --DBMS_OUTPUT.put_line('Query Exeecution Time' || (DBMS_UTILITY.get_time - l_start) || ' hsecs');
      --l_start := DBMS_UTILITY.get_time;

      IF V_IN_SBSDATA.COUNT > 0
      THEN
         FOR I IN V_IN_SBSDATA.FIRST .. V_IN_SBSDATA.LAST
         LOOP
            V_SL := V_SL + 1;
            V_DATA := LPAD (V_SL, 6, '0') || V_IN_SBSDATA (I).TEMP_DATA;



            TEMP_TY_SBS3_DATA.TOTAL_DATA := TO_CHAR (V_DATA);

            --DBMS_OUTPUT.PUT_LINE(TO_CHAR(V_DATA));

            PIPE ROW (TEMP_TY_SBS3_DATA);
         --V_FILE_DATA := V_FILE_DATA || (CASE WHEN V_FILE_DATA IS NOT NULL THEN CHR (10) END) || V_DATA;
         --UTL_FILE.PUT (V_FILE, V_DATA);
         --UTL_FILE.NEW_LINE (V_FILE, 1);
         --DBMS_OUTPUT.PUT_LINE(V_IN_SBSDATA.COUNT);
         END LOOP;

         --DBMS_OUTPUT.put_line('Result Time' || (DBMS_UTILITY.get_time - l_start) || ' hsecs');
         V_IN_SBSDATA.DELETE;
      END IF;
   END;
END;
/
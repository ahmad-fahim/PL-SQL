CREATE OR REPLACE FUNCTION FN_GET_INSIDE_DATA (P_ROW_DATA        VARCHAR2,
                                               P_FIRST_COLUMN    VARCHAR2,
                                               P_LAST_COLUMN     VARCHAR2) 
   RETURN VARCHAR2
IS
   V_RETURN_DATA   VARCHAR2 (1000);
BEGIN
   SELECT SUBSTR (
             INDCLIENTS_ROW_DATA,
               INSTR (INDCLIENTS_ROW_DATA, P_FIRST_COLUMN)
             + LENGTH (P_FIRST_COLUMN),
               DECODE (INSTR (INDCLIENTS_ROW_DATA, P_LAST_COLUMN),
                       0, LENGTH (INDCLIENTS_ROW_DATA) + 1,
                       INSTR (INDCLIENTS_ROW_DATA, P_LAST_COLUMN))
             - (  INSTR (INDCLIENTS_ROW_DATA, P_FIRST_COLUMN)
                + LENGTH (P_FIRST_COLUMN)))
     INTO V_RETURN_DATA
     FROM (SELECT P_ROW_DATA
                     INDCLIENTS_ROW_DATA
             FROM DUAL);

   RETURN V_RETURN_DATA;
EXCEPTION
    WHEN OTHERS THEN 
    RETURN '';
    
END FN_GET_INSIDE_DATA;
/

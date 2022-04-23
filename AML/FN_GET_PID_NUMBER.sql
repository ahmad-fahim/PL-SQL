CREATE OR REPLACE FUNCTION FN_GET_PID_NUMBER (P_CLIENT_CODE    NUMBER,
                                              P_PID_TYPE       VARCHAR2)
   RETURN VARCHAR2
IS
   V_OTHER_DOCU_TYP    VARCHAR2 (1000);
   V_OTHER_DOCU_NO     VARCHAR2 (1000);
   V_OTHER_DOCU_DATE   VARCHAR2 (1000);
   V_CNTRY_CODE        VARCHAR2 (1000);
   --NID_NO              VARCHAR2 (1000);
BEGIN
   BEGIN
      IF P_PID_TYPE IN ('NID', 'VID', 'SC')
      THEN
         SELECT TO_CHAR (WM_CONCAT (UPPER (TRIM (PIDDOCS_PID_TYPE)))),
                TO_CHAR (WM_CONCAT (TRIM (PIDDOCS_DOCID_NUM))),
                TO_CHAR (WM_CONCAT (TRIM (PIDDOCS_ISSUE_DATE))),
                TO_CHAR (WM_CONCAT (TRIM (PIDDOCS_ISSUE_CNTRY)))
           INTO V_OTHER_DOCU_TYP,
                V_OTHER_DOCU_NO,
                V_OTHER_DOCU_DATE,
                V_CNTRY_CODE
           FROM PIDDOCS P
          WHERE     P.PIDDOCS_SOURCE_KEY = TO_CHAR (P_CLIENT_CODE)
                AND P.PIDDOCS_PID_TYPE IN ('NID', 'VID', 'SC');
      ELSE
         SELECT TO_CHAR (WM_CONCAT (UPPER (TRIM (PIDDOCS_PID_TYPE)))),
                TO_CHAR (WM_CONCAT (TRIM (PIDDOCS_DOCID_NUM))),
                TO_CHAR (WM_CONCAT (TRIM (PIDDOCS_ISSUE_DATE))),
                TO_CHAR (WM_CONCAT (TRIM (PIDDOCS_ISSUE_CNTRY)))
           INTO V_OTHER_DOCU_TYP,
                V_OTHER_DOCU_NO,
                V_OTHER_DOCU_DATE,
                V_CNTRY_CODE
           FROM PIDDOCS P
          WHERE     P.PIDDOCS_SOURCE_KEY = TO_CHAR (P_CLIENT_CODE)
                AND P.PIDDOCS_PID_TYPE = P_PID_TYPE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_OTHER_DOCU_TYP := NULL;
         V_OTHER_DOCU_NO := NULL;
         V_OTHER_DOCU_DATE := NULL;
         V_CNTRY_CODE := NULL;
   END;
    
   RETURN V_OTHER_DOCU_NO;
END FN_GET_PID_NUMBER;
/

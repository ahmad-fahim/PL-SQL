CREATE OR REPLACE FUNCTION GET_NID_NUMBER (
   P_CLIENT_CODE    NUMBER,
   P_PID_TYPE       VARCHAR2)
   RETURN VARCHAR2
IS
   V_OTHER_DOCU_TYP    VARCHAR2 (1000);
   V_OTHER_DOCU_NO     VARCHAR2 (1000);
   V_OTHER_DOCU_DATE   VARCHAR2 (1000);
   V_CNTRY_CODE        VARCHAR2 (1000);
   NID_NO              VARCHAR2 (1000);
BEGIN
   BEGIN
      SELECT UPPER (TRIM (PIDDOCS_PID_TYPE)),
             TRIM (PIDDOCS_DOCID_NUM),
             TRIM (PIDDOCS_ISSUE_DATE),
             TRIM (PIDDOCS_ISSUE_CNTRY)
        INTO V_OTHER_DOCU_TYP,
             V_OTHER_DOCU_NO,
             V_OTHER_DOCU_DATE,
             V_CNTRY_CODE
        FROM PIDDOCS P
       WHERE     P.PIDDOCS_SOURCE_KEY = TO_CHAR (P_CLIENT_CODE)
             AND PIDDOCS_DOC_SL = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            SELECT UPPER (TRIM (PIDDOCS_PID_TYPE)),
                   TRIM (PIDDOCS_DOCID_NUM),
                   TRIM (PIDDOCS_ISSUE_DATE),
                   TRIM (PIDDOCS_ISSUE_CNTRY)
              INTO V_OTHER_DOCU_TYP,
                   V_OTHER_DOCU_NO,
                   V_OTHER_DOCU_DATE,
                   V_CNTRY_CODE
              FROM PIDDOCS P
             WHERE     P.PIDDOCS_SOURCE_KEY = TO_CHAR (P_CLIENT_CODE)
                   AND PIDDOCS_DOC_SL = 1
                   AND PIDDOCS_PID_TYPE = 'NID';
         EXCEPTION
            WHEN OTHERS
            THEN
               BEGIN
                  SELECT UPPER (TRIM (PIDDOCS_PID_TYPE)),
                         TRIM (PIDDOCS_DOCID_NUM),
                         TRIM (PIDDOCS_ISSUE_DATE),
                         TRIM (PIDDOCS_ISSUE_CNTRY)
                    INTO V_OTHER_DOCU_TYP,
                         V_OTHER_DOCU_NO,
                         V_OTHER_DOCU_DATE,
                         V_CNTRY_CODE
                    FROM PIDDOCS P
                   WHERE     P.PIDDOCS_SOURCE_KEY = TO_CHAR (P_CLIENT_CODE)
                         AND PIDDOCS_DOC_SL = 1
                         AND PIDDOCS_PID_TYPE = 'NID'
                         AND PIDDOCS_SOURCE_TABLE = 'INDCLIENTS';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     SELECT MIN (TRIM (PIDDOCS_DOCID_NUM)), 'NID'
                       INTO V_OTHER_DOCU_NO, V_OTHER_DOCU_TYP
                       FROM PIDDOCS P
                      WHERE     P.PIDDOCS_SOURCE_KEY =
                                   TO_CHAR (P_CLIENT_CODE)
                            AND PIDDOCS_DOC_SL = 1
                            AND PIDDOCS_PID_TYPE = 'NID'
                            AND PIDDOCS_SOURCE_TABLE = 'INDCLIENTS';
               END;
         END;
   END;

   IF P_PID_TYPE = 'NID' AND V_OTHER_DOCU_TYP IN ('NID', 'NIN')
   THEN
      NID_NO := V_OTHER_DOCU_NO;
   ELSIF P_PID_TYPE = 'TIN' AND V_OTHER_DOCU_TYP IN ('TIN')
   THEN
      NID_NO := V_OTHER_DOCU_NO;
   ELSE
      NID_NO := NULL;
   END IF;

   RETURN NID_NO;
END GET_NID_NUMBER;
/

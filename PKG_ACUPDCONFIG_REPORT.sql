CREATE OR REPLACE PACKAGE PKG_ACUPDCONFIG_REPORT
IS
   TYPE TY_AC_VALUE IS RECORD
   (
      ACC_NO            VARCHAR2 (1000),
      BRN_CODE          NUMBER,
      PROD_CODE         NUMBER,
      AC_TYPE           VARCHAR2 (10),
      ACC_HOLDER_NAME   VARCHAR2 (1000),
      COLUMN_SL         NUMBER,
      COLUMN_NAME       VARCHAR2 (50),
      COLUMN_VAL        VARCHAR2 (10)
   );

   TYPE TY_AC_VALUE_DTL IS TABLE OF TY_AC_VALUE;


   FUNCTION AC_VALUE_DTL (P_ENTITYNUM     IN NUMBER,
                          P_BRANCH_CODE      NUMBER,
                          P_PROD_CODE        NUMBER,
                          P_ACTYPE           VARCHAR2)
      --RETURN VARCHAR2 ;
      RETURN TY_AC_VALUE_DTL
      PIPELINED;
END PKG_ACUPDCONFIG_REPORT;
/

CREATE OR REPLACE PACKAGE BODY PKG_ACUPDCONFIG_REPORT
IS
   TABLE2              PKG_ACUPDCONFIG_REPORT.TY_AC_VALUE;

   V_SQL               VARCHAR2 (32767)
      := 'SELECT TT.*,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_STATE_CODE END)),NULL,''0'',''1'') CURR_STATECODE,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_DISTRICT_CODE END)),NULL,''0'',''1'') CURR_DISTCODE,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_POSTAL_CODE END)),NULL,''0'',''1'') CURR_POSTALCODE,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_LOCN_CODE END)),NULL,''0'',''1'') CURR_LOCNCODE,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_POSTOFFC_NAME END)),NULL,''0'',''1'') CURR_POSTOFFC_NAME,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_ADDR2||ADDRDTLS_ADDR1 END)),NULL,''0'',''1'') CURR_ADDR,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN ADDRDTLS_PERM_ADDR END)),NULL,''0'',TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN ADDRDTLS_PERM_ADDR END))) CURRADD_PERM_FLAG,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' AND ADDRDTLS_PERM_ADDR = ''1'' THEN ''1'' ELSE ''0'' END)), ''1'' , DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_STATE_CODE END)),NULL,''0'',''1''), DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''02'' THEN  ADDRDTLS_STATE_CODE END)),NULL,''0'',''1'')) PERM_STATECODE,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' AND ADDRDTLS_PERM_ADDR = ''1'' THEN ''1'' ELSE ''0'' END)), ''1'' , DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_DISTRICT_CODE END)),NULL,''0'',''1''), DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''02'' THEN  ADDRDTLS_DISTRICT_CODE END)),NULL,''0'',''1'')) PERM_DISTCODE,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' AND ADDRDTLS_PERM_ADDR = ''1'' THEN ''1'' ELSE ''0'' END)), ''1'' , DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_POSTAL_CODE END)),NULL,''0'',''1''), DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''02'' THEN  ADDRDTLS_POSTAL_CODE END)),NULL,''0'',''1'')) PERM_POSTALCODE,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' AND ADDRDTLS_PERM_ADDR = ''1'' THEN ''1'' ELSE ''0'' END)), ''1'' , DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_LOCN_CODE END)),NULL,''0'',''1''), DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''02'' THEN  ADDRDTLS_LOCN_CODE END)),NULL,''0'',''1'')) PERM_LOCNCODE,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' AND ADDRDTLS_PERM_ADDR = ''1'' THEN ''1'' ELSE ''0'' END)), ''1'' , DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_POSTOFFC_NAME END)),NULL,''0'',''1''), DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''02'' THEN  ADDRDTLS_POSTOFFC_NAME END)),NULL,''0'',''1'')) PERM_POSTOFFC_NAME,
       DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' AND ADDRDTLS_PERM_ADDR = ''1'' THEN ''1'' ELSE ''0'' END)), ''1'' , DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''01'' THEN  ADDRDTLS_ADDR2||ADDRDTLS_ADDR1 END)),NULL,''0'',''1''), DECODE(TO_CHAR(WM_CONCAT(CASE WHEN ADDRDTLS_ADDR_TYPE = ''02'' THEN  ADDRDTLS_ADDR2||ADDRDTLS_ADDR1 END)),NULL,''0'',''1'')) PERM_ADDR 
               FROM (SELECT 
                    FACNO (1, ACNTS_INTERNAL_ACNUM) ACC_NO,
                    ACNTS_BRN_CODE,
                    ACNTS_PROD_CODE,
                    ACNTS_AC_TYPE,
               TRIM (ACNTS_AC_NAME1 || ACNTS_AC_NAME2) ACC_HOLDER_NAME, 
               DECODE(TRIM(ACNTS_AC_NAME1 || ACNTS_AC_NAME2), NULL, ''0'', ''1'') ACC_NAME,
               DECODE(TRIM(INDCLIENT_FIRST_NAME), NULL, ''0'', ''1'') FIRST_NAME,
               DECODE(TRIM(INDCLIENT_LAST_NAME), NULL, ''0'', ''1'') MIDDLE_NAME,
               DECODE(TRIM(INDCLIENT_SUR_NAME), NULL, ''0'', ''1'') LAST_NAME,
               DECODE(TRIM(INDCLIENT_FATHER_NAME), NULL, ''0'', ''1'') FATHER_NAME,
               DECODE(TRIM(INDCLIENT_MOTHER_NAME), NULL, ''0'', ''1'') MOTHER_NAME,
               DECODE(TRIM(INDCLIENT_BIRTH_DATE), NULL, ''0'', ''1'') BIRTH_DATE,
               DECODE(TRIM(INDCLIENT_SEX), NULL, ''0'', ''1'') GENDER,
               DECODE(TRIM(INDCLIENT_OCCUPN_CODE), NULL, ''0'', ''1'') OCCUPN_CODE,
               DECODE((SELECT TRIM(ACTP_SRC_FUND)
                        FROM ACNTRNPR
                       WHERE ACTP_ACNT_NUM = ACNTS_INTERNAL_ACNUM
                         AND ACTP_LATEST_EFF_DATE =
                             (SELECT MAX(ACTP_LATEST_EFF_DATE)
                                FROM ACNTRNPR
                               WHERE ACTP_ACNT_NUM = ACNTS_INTERNAL_ACNUM)),
                      NULL,
                      ''0'',
                      ''1'') SRC_FUND,
               DECODE(TRIM(INDCLIENT_TEL_GSM || INDCLIENT_TEL_RES),
                      NULL,
                      ''0'',
                      ''1'') CONTACT_NO,
               (SELECT DECODE(TRIM(TO_CHAR(WM_CONCAT(PIDDOCS_DOCID_NUM))),
                              NULL,
                              ''0'',
                              ''1'')
                  FROM PIDDOCS
                 WHERE PIDDOCS_INV_NUM = INDCLIENT_PID_INV_NUM
                   AND PIDDOCS_PID_TYPE IN (''NID'', ''SC'', ''BC'', ''PP'')) PID_DETAIL,
               CLIENTS_ADDR_INV_NUM
          FROM ACNTS, INDCLIENTS, CLIENTS
         WHERE ACNTS_ENTITY_NUM = :ENTITY_NUM
           AND ACNTS_BRN_CODE = :BRANCH_CODE
           AND ACNTS_PROD_CODE = :PROD_CODE
           AND ACNTS_AC_TYPE = :ACTYPE
           AND CLIENTS_CODE = ACNTS_CLIENT_NUM
           AND INDCLIENT_CODE = ACNTS_CLIENT_NUM
           AND ACNTS_CLOSURE_DATE IS NULL) TT
  LEFT OUTER JOIN ADDRDTLS
    ON (ADDRDTLS_INV_NUM = CLIENTS_ADDR_INV_NUM)
 GROUP BY ACC_NO,
          ACNTS_BRN_CODE,
          ACNTS_PROD_CODE,
          ACNTS_AC_TYPE,
          ACC_HOLDER_NAME,
          ACC_NAME,
          FIRST_NAME,
          MIDDLE_NAME,
          LAST_NAME,
          FATHER_NAME,
          MOTHER_NAME,
          BIRTH_DATE,
          GENDER,
          OCCUPN_CODE,
          SRC_FUND,
          CONTACT_NO,
          CLIENTS_ADDR_INV_NUM,
          PID_DETAIL
 ORDER BY ACC_NO';

   v_cursor_id         INTEGER;
   v_col_cnt           INTEGER;
   v_columns           DBMS_SQL.desc_tab;


   TYPE R_AC_VALUE_DTL IS RECORD
   (
      TM_ACC_NO            VARCHAR2 (1000),
      TM_BRN_CODE          NUMBER,
      TM_PROD_CODE         NUMBER,
      TM_AC_TYPE           VARCHAR2 (10),
      TM_ACC_HOLDER_NAME   VARCHAR2 (1000),
      TM_CLOUMN_NAME       VARCHAR2 (50),
      TM_COLUMN_VAL        VARCHAR2 (10)
   );


   TYPE TTY_AC_VALUE_DTL IS TABLE OF R_AC_VALUE_DTL
      INDEX BY PLS_INTEGER;

   V_TY_AC_VALUE_DTL   TTY_AC_VALUE_DTL;

   TYPE FULL_DATA IS RECORD
   (
      ACC_NO                 VARCHAR2 (1000),
      ACNTS_BRN_CODE         NUMBER,
      ACNTS_PROD_CODE        NUMBER,
      ACNTS_AC_TYPE          VARCHAR2 (10),
      ACC_HOLDER_NAME        VARCHAR2 (1000),
      ACC_NAME               VARCHAR2 (1),
      FIRST_NAME             VARCHAR2 (1),
      MIDDLE_NAME            VARCHAR2 (1),
      LAST_NAME              VARCHAR2 (1),
      FATHER_NAME            VARCHAR2 (1),
      MOTHER_NAME            VARCHAR2 (1),
      BIRTH_DATE             VARCHAR2 (1),
      GENDER                 VARCHAR2 (1),
      OCCUPN_CODE            VARCHAR2 (1),
      SRC_FUND               VARCHAR2 (1),
      CONTACT_NO             VARCHAR2 (1),
      PID_DETAIL             VARCHAR2 (1),
      CLIENTS_ADDR_INV_NUM   NUMBER,
      CURR_STATECODE         VARCHAR2 (1),
      CURR_DISTCODE          VARCHAR2 (1),
      CURR_POSTALCODE        VARCHAR2 (1),
      CURR_LOCNCODE          VARCHAR2 (1),
      CURR_POSTOFFC_NAME     VARCHAR2 (1),
      CURR_ADDR              VARCHAR2 (1),
      CURRADD_PERM_FLAG      VARCHAR2 (1),
      PERM_STATECODE         VARCHAR2 (1),
      PERM_DISTCODE          VARCHAR2 (1),
      PERM_POSTALCODE        VARCHAR2 (1),
      PERM_LOCNCODE          VARCHAR2 (1),
      PERM_POSTOFFC_NAME     VARCHAR2 (1),
      PERM_ADDR              VARCHAR2 (1)
   );

   TYPE TTY_FULL_DATA IS TABLE OF FULL_DATA
      INDEX BY PLS_INTEGER;

   V_TTY_FULL_DATA     TTY_FULL_DATA;

   FUNCTION AC_VALUE_DTL (P_ENTITYNUM     IN NUMBER,
                          P_BRANCH_CODE      NUMBER,
                          P_PROD_CODE        NUMBER,
                          P_ACTYPE           VARCHAR2)
      RETURN TY_AC_VALUE_DTL
      PIPELINED
   --RETURN VARCHAR2
   IS
      E_USEREXCEP   EXCEPTION;
      W_ERROR_MSG   VARCHAR2 (60);
      V_COL_SL      NUMBER ;
   BEGIN
      v_cursor_id := DBMS_SQL.open_cursor;
      DBMS_SQL.parse (v_cursor_id, v_sql, DBMS_SQL.native);
      DBMS_SQL.describe_columns (v_cursor_id, v_col_cnt, v_columns);

      EXECUTE IMMEDIATE v_sql
         BULK COLLECT INTO V_TTY_FULL_DATA
         USING P_ENTITYNUM,
               P_BRANCH_CODE,
               P_PROD_CODE,
               P_ACTYPE;

      IF V_TTY_FULL_DATA.COUNT > 0
      THEN
         FOR IND IN V_TTY_FULL_DATA.FIRST .. V_TTY_FULL_DATA.LAST
         LOOP
            V_COL_SL := 1 ;
            FOR i IN 1 .. v_columns.COUNT
            LOOP
               IF v_columns (i).col_name NOT IN ('ACC_NO',
                                                 'ACNTS_BRN_CODE',
                                                 'ACNTS_PROD_CODE',
                                                 'ACNTS_AC_TYPE',
                                                 'ACC_HOLDER_NAME',
                                                 'CLIENTS_ADDR_INV_NUM')
               THEN
                  TABLE2.ACC_NO := V_TTY_FULL_DATA (IND).ACC_NO;
                  TABLE2.BRN_CODE := V_TTY_FULL_DATA (IND).ACNTS_BRN_CODE;
                  TABLE2.PROD_CODE := V_TTY_FULL_DATA (IND).ACNTS_PROD_CODE;
                  TABLE2.AC_TYPE := V_TTY_FULL_DATA (IND).ACNTS_AC_TYPE;
                  TABLE2.ACC_HOLDER_NAME :=
                     V_TTY_FULL_DATA (IND).ACC_HOLDER_NAME;
                  TABLE2.COLUMN_SL := V_COL_SL ;
                  TABLE2.COLUMN_NAME := v_columns (i).col_name;

                  IF v_columns (i).col_name = 'ACC_NAME'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).ACC_NAME;
                  ELSIF v_columns (i).col_name = 'FIRST_NAME'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).FIRST_NAME;
                  ELSIF v_columns (i).col_name = 'MIDDLE_NAME'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).MIDDLE_NAME;
                  ELSIF v_columns (i).col_name = 'LAST_NAME'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).LAST_NAME;
                  ELSIF v_columns (i).col_name = 'FATHER_NAME'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).FATHER_NAME;
                  ELSIF v_columns (i).col_name = 'MOTHER_NAME'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).MOTHER_NAME;
                  ELSIF v_columns (i).col_name = 'BIRTH_DATE'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).BIRTH_DATE;
                  ELSIF v_columns (i).col_name = 'GENDER'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).GENDER;
                  ELSIF v_columns (i).col_name = 'OCCUPN_CODE'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).OCCUPN_CODE;
                  ELSIF v_columns (i).col_name = 'SRC_FUND'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).SRC_FUND;
                  ELSIF v_columns (i).col_name = 'CONTACT_NO'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).CONTACT_NO;
                  ELSIF v_columns (i).col_name = 'PID_DETAIL'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).PID_DETAIL;
                  ELSIF v_columns (i).col_name = 'CURR_STATECODE'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).CURR_STATECODE;
                  ELSIF v_columns (i).col_name = 'CURR_DISTCODE'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).CURR_DISTCODE;
                  ELSIF v_columns (i).col_name = 'CURR_POSTALCODE'
                  THEN
                     TABLE2.COLUMN_VAL :=
                        V_TTY_FULL_DATA (IND).CURR_POSTALCODE;
                  ELSIF v_columns (i).col_name = 'CURR_LOCNCODE'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).CURR_LOCNCODE;
                  ELSIF v_columns (i).col_name = 'CURR_POSTOFFC_NAME'
                  THEN
                     TABLE2.COLUMN_VAL :=
                        V_TTY_FULL_DATA (IND).CURR_POSTOFFC_NAME;
                  ELSIF v_columns (i).col_name = 'CURR_ADDR'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).CURR_ADDR;
                  ELSIF v_columns (i).col_name = 'CURRADD_PERM_FLAG'
                  THEN
                     TABLE2.COLUMN_VAL :=
                        V_TTY_FULL_DATA (IND).CURRADD_PERM_FLAG;
                  ELSIF v_columns (i).col_name = 'PERM_STATECODE'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).PERM_STATECODE;
                  ELSIF v_columns (i).col_name = 'PERM_DISTCODE'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).PERM_DISTCODE;
                  ELSIF v_columns (i).col_name = 'PERM_POSTALCODE'
                  THEN
                     TABLE2.COLUMN_VAL :=
                        V_TTY_FULL_DATA (IND).PERM_POSTALCODE;
                  ELSIF v_columns (i).col_name = 'PERM_LOCNCODE'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).PERM_LOCNCODE;
                  ELSIF v_columns (i).col_name = 'PERM_POSTOFFC_NAME'
                  THEN
                     TABLE2.COLUMN_VAL :=
                        V_TTY_FULL_DATA (IND).PERM_POSTOFFC_NAME;
                  ELSIF v_columns (i).col_name = 'PERM_ADDR'
                  THEN
                     TABLE2.COLUMN_VAL := V_TTY_FULL_DATA (IND).PERM_ADDR;
                  ELSE
                     TABLE2.COLUMN_VAL := 'TEMP_DATA';
                  END IF;

                  PIPE ROW (TABLE2);
                  V_COL_SL := V_COL_SL + 1 ;
               END IF;
            --DBMS_OUTPUT.put_line (v_columns (i).col_name);
            END LOOP;
         END LOOP;
      END IF;


      DBMS_SQL.close_cursor (v_cursor_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         --CLOSE v_cursor_id;
         DBMS_SQL.close_cursor (v_cursor_id);

         RAISE;

         W_ERROR_MSG := SUBSTR (SQLERRM, 1, 50);
   END;
END PKG_ACUPDCONFIG_REPORT;
/
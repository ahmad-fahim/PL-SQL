CREATE OR REPLACE PROCEDURE SP_GEN_AML_FULLDATA (P_FROM_BRN    NUMBER,
                                                 P_TO_BRN      NUMBER)
IS
   V_ERROR_MSG   VARCHAR2 (3000);
   V_SQL         CLOB;

   V_CBD         DATE;
   V_FIN_YEAR    VARCHAR2 (4);
BEGIN
   SELECT MN_CURR_BUSINESS_DATE INTO V_CBD FROM MAINCONT;

   V_FIN_YEAR := TO_NUMBER (TO_CHAR (V_CBD, 'YYYY'));

   FOR IDX
      IN (  SELECT *
              FROM (  SELECT BRANCH_CODE, ROWNUM BRANCH_SL
                        FROM MIG_DETAIL
                    ORDER BY BRANCH_CODE)
             WHERE     BRANCH_SL BETWEEN P_FROM_BRN AND P_TO_BRN
                   AND BRANCH_CODE NOT IN (SELECT BRANCH_CODE
                                             FROM AML_CLIENT_INSERT_LOG)
          ORDER BY BRANCH_CODE)
   LOOP
      BEGIN
         INSERT INTO AML_CUSTOMERS
            SELECT CLIENTS_CODE CUSTOMERNO,
                   CLIENTS_CODE CUSTUNIQTRACKNO,
                   LPAD (CLIENTS_HOME_BRN_CODE, 4, '0') CBSBRANCHCODE,
                   'CBS' SERVICETYPE,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I' THEN 'Individual'
                      ELSE 'Entity'
                   END
                      SCRCUSTOMERTYPE,
                   (SELECT CLIENTCATS_DESCN
                      FROM CLIENTCATS_TYPE
                     WHERE CLIENTCATS_CATG_CODE = CLIENTS_CUST_CATG)
                      CUSTOMERCATEGORY,
                   FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                       'INDCLIENT_SUR_NAME',
                                       'INDCLIENT_OCCUPN_CODE')
                      SHORTNAME,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         (SELECT TITLES_DESCN
                            FROM TITLES
                           WHERE TITLES_CODE = CLIENTS_TITLE_CODE)
                   END
                      SALUTATION,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_FIRST_NAME',
                                             'INDCLIENT_LAST_NAME')
                      ELSE
                         CLIENTS_NAME
                   END
                      FIRSTNAME,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_MIDDLE_NAME',
                                             'INDCLIENT_FIRST_NAME')
                   END
                      MIDDLENAME,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         DECODE (
                            TRIM (
                               FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                                   'INDCLIENT_LAST_NAME',
                                                   'INDCLIENT_SUR_NAME')),
                            NULL, TRIM (
                                     FN_GET_INSIDE_DATA (
                                        INDCLIENTS_ROW_DATA,
                                        'INDCLIENT_SUR_NAME',
                                        'INDCLIENT_OCCUPN_CODE')),
                            TRIM (
                               FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                                   'INDCLIENT_LAST_NAME',
                                                   'INDCLIENT_SUR_NAME')))
                   END
                      LASTNAME,
                   NVL (
                      TRIM (
                         (SELECT CNTRY_NAME
                            FROM LOCATION, CNTRY
                           WHERE     LOCN_CODE = CLIENTS_LOCN_CODE
                                 AND LOCN_CNTRY_CODE = CNTRY_CODE)),
                      'Bangladesh')
                      COUNTRY,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         --GET_NID_NUMBER (CLIENTS_CODE, 'NID')
                         FN_GET_PID_NUMBER (CLIENTS_CODE, 'NID')
                   END
                      NID,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_FATHER_NAME',
                                             'INDCLIENT_MOTHER_NAME')
                   END
                      FATHERNAME,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_MOTHER_NAME',
                                             'INDCLIENT_SEX')
                   END
                      MOTHERNAME,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         CASE
                            WHEN FN_GET_INSIDE_DATA (
                                    INDCLIENTS_ROW_DATA,
                                    'INDCLIENT_SEX',
                                    'INDCLIENT_BIRTH_PLACE_NAME') = 'M'
                            THEN
                               'M'
                            ELSE
                               'F'
                         END
                   END
                      GENDER,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         CASE
                            WHEN FN_GET_INSIDE_DATA (
                                    INDCLIENTS_ROW_DATA,
                                    'INDCLIENT_MARITAL_STATUS',
                                    'INDCLIENT_MIDDLE_NAME') = 'S'
                            THEN
                               'S'
                            ELSE
                               'M'
                         END
                   END
                      MARITALSTATUS,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         (SELECT INDSPOUSE_SPOUSE_NAME
                            FROM INDCLIENTSPOUSE
                           WHERE INDSPOUSE_CLIENT_CODE = CLIENTS_CODE)
                   END
                      SPOUSENAME,
                   NULL EDUCATIONALSTATUS,
                   SUBSTR (
                         FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                             'ADDRDTLS_ADDR1',
                                             'ADDRDTLS_ADDR2')
                      || ' '
                      || FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                             'ADDRDTLS_ADDR2',
                                             'ADDRDTLS_ADDR3')
                      || ' '
                      || FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                             'ADDRDTLS_ADDR3',
                                             'ADDRDTLS_ADDR4')
                      || ' '
                      || FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                             'ADDRDTLS_ADDR4',
                                             'ADDRDTLS_ADDR5')
                      || ' '
                      || FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                             'ADDRDTLS_ADDR5',
                                             'ADDRDTLS_LOCN_CODE'),
                      1,
                      120)
                      PRESENTADDRESS1,
                   NULL PRESENTADDRESS2,
                   NULL PRESENTADDRESS3,
                   FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                       'ADDRDTLS_POSTAL_CODE',
                                       'ADDRDTLS_ADDR_SL')
                      PRESENTPOSTCODE,
                   (SELECT UPPER (STATE_NAME)
                      FROM LOCATION, STATE
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = STATE_CNTRY_CODE
                           AND LOCN_STATE_CODE = STATE_CODE)
                      PRESENTSTATE,
                   (SELECT UPPER (DISTRICT_NAME)
                      FROM LOCATION, DISTRICT
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = DISTRICT_CNTRY_CODE
                           AND LOCN_STATE_CODE = DISTRICT_STATE_CODE
                           AND LOCN_DISTRICT_CODE = DISTRICT_CODE)
                      PRESENTCITY,
                   NVL (
                      TRIM (
                         (SELECT CNTRY_CODE
                            FROM LOCATION, CNTRY
                           WHERE     LOCN_CODE =
                                        FN_GET_INSIDE_DATA (
                                           ADDRDTLS_PRES_ROW_DATA,
                                           'ADDRDTLS_LOCN_CODE',
                                           'ADDRDTLS_CNTRY_CODE')
                                 AND LOCN_CNTRY_CODE = CNTRY_CODE)),
                      'BD')
                      PRESENTCOUNTRY,
                   SUBSTR (
                         FN_GET_INSIDE_DATA (ADDRDTLS_PERM_ROW_DATA,
                                             'ADDRDTLS_ADDR1',
                                             'ADDRDTLS_ADDR2')
                      || ' '
                      || FN_GET_INSIDE_DATA (ADDRDTLS_PERM_ROW_DATA,
                                             'ADDRDTLS_ADDR2',
                                             'ADDRDTLS_ADDR3')
                      || ' '
                      || FN_GET_INSIDE_DATA (ADDRDTLS_PERM_ROW_DATA,
                                             'ADDRDTLS_ADDR3',
                                             'ADDRDTLS_ADDR4')
                      || ' '
                      || FN_GET_INSIDE_DATA (ADDRDTLS_PERM_ROW_DATA,
                                             'ADDRDTLS_ADDR4',
                                             'ADDRDTLS_ADDR5')
                      || ' '
                      || FN_GET_INSIDE_DATA (ADDRDTLS_PERM_ROW_DATA,
                                             'ADDRDTLS_ADDR5',
                                             'ADDRDTLS_LOCN_CODE'),
                      1,
                      120)
                      PERMANENTADDRESS1,
                   NULL PERMANENTADDRESS2,
                   NULL PERMANENTADDRESS3,
                   FN_GET_INSIDE_DATA (ADDRDTLS_PERM_ROW_DATA,
                                       'ADDRDTLS_POSTAL_CODE',
                                       'ADDRDTLS_ADDR_SL')
                      PERMANENTPOSTCODE,
                   (SELECT UPPER (STATE_NAME)
                      FROM LOCATION, STATE
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_PERM_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = STATE_CNTRY_CODE
                           AND LOCN_STATE_CODE = STATE_CODE)
                      PERMANENTSTATE,
                   (SELECT UPPER (DISTRICT_NAME)
                      FROM LOCATION, DISTRICT
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_PERM_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = DISTRICT_CNTRY_CODE
                           AND LOCN_STATE_CODE = DISTRICT_STATE_CODE
                           AND LOCN_DISTRICT_CODE = DISTRICT_CODE)
                      PERMANENTCITY,
                   NVL (
                      TRIM (
                         (SELECT LOCN_CNTRY_CODE
                            FROM LOCATION, CNTRY
                           WHERE     LOCN_CODE =
                                        FN_GET_INSIDE_DATA (
                                           ADDRDTLS_PERM_ROW_DATA,
                                           'ADDRDTLS_LOCN_CODE',
                                           'ADDRDTLS_CNTRY_CODE')
                                 AND LOCN_CNTRY_CODE = CNTRY_CODE)),
                      'BD')
                      PERMANENTCOUNTRY,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         (SELECT CNTRY_CODE
                            FROM CNTRY
                           WHERE CNTRY_CODE =
                                    FN_GET_INSIDE_DATA (
                                       INDCLIENTS_ROW_DATA,
                                       'INDCLIENT_NATNL_CODE',
                                       'INDCLIENT_RESIDENT_STATUS'))
                   END
                      NATIONALITY,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         TO_DATE (
                            FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                                'INDCLIENT_BIRTH_DATE',
                                                'INDCLIENT_NATNL_CODE'))
                   END
                      DOB,
                      FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                          'ADDRDTLS_PHONE_NUM1',
                                          'ADDRDTLS_PHONE_NUM2')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                          'ADDRDTLS_PHONE_NUM2',
                                          'ADDRDTLS_MOBILE_NUM')
                      PHONE,
                   FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                       'ADDRDTLS_MOBILE_NUM',
                                       'ADDRDTLS_MOBILE_NUM_999')
                      MOBILE,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                            FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                                'INDCLIENT_EMAIL_ADDR1',
                                                'INDCLIENT_EMAIL_ADDR2')
                         || ' '
                         || FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                                'INDCLIENT_EMAIL_ADDR2',
                                                'INDCLIENT_FATHER_NAME')
                      ELSE
                         ''
                   END
                      EMAIL,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_TEL_RES',
                                             'INDCLIENT_MARITAL_STATUS')
                      ELSE
                         ''
                   END
                      HOMEPHONE,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_TEL_OFF',
                                             'INDCLIENT_TEL_RES')
                      ELSE
                         ''
                   END
                      WORKPHONE,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_TEL_FAX',
                                             'INDCLIENT_TEL_OFF')
                      ELSE
                         ''
                   END
                      FAX,
                   NVL (
                      TRIM (
                         CASE
                            WHEN CLIENTS_TYPE_FLG = 'I'
                            THEN
                               FN_GET_INSIDE_DATA (
                                  INDCLIENTS_ROW_DATA,
                                  'INDCLIENT_RESIDENT_STATUS',
                                  'INDCLIENT_EMAIL_ADDR1')
                         END),
                      'R')
                      RESIDENTSTATUS,
                   NULL COMMUNICATIONMODE,
                   FN_GET_PID_NUMBER (CLIENTS_CODE, 'BC') BIRTHCRETIFICATENO,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         (SELECT LOCN_NAME
                            FROM LOCATION
                           WHERE LOCN_CODE =
                                    FN_GET_INSIDE_DATA (
                                       INDCLIENTS_ROW_DATA,
                                       'INDCLIENT_BIRTH_PLACE_CODE',
                                       'INDCLIENT_BIRTH_PLACE_CODE_999'))
                   END
                      BIRTHPLACE,
                   NVL (
                      CASE
                         WHEN CLIENTS_TYPE_FLG = 'I'
                         THEN
                            (SELECT CNTRY_CODE
                               FROM LOCATION, CNTRY
                              WHERE     LOCN_CODE =
                                           FN_GET_INSIDE_DATA (
                                              INDCLIENTS_ROW_DATA,
                                              'INDCLIENT_BIRTH_PLACE_CODE',
                                              'INDCLIENT_BIRTH_PLACE_CODE_999')
                                    AND CNTRY_CODE = LOCN_CNTRY_CODE)
                      END,
                      'BD')
                      BIRTHCOUNTRY,
                   NVL (
                      CASE
                         WHEN CLIENTS_TYPE_FLG = 'I'
                         THEN
                            (SELECT LANGUAGE_NAME
                               FROM LANGUAGES
                              WHERE LANGUAGE_CODE =
                                       FN_GET_INSIDE_DATA (
                                          INDCLIENTS_ROW_DATA,
                                          'INDCLIENT_LANG_CODE',
                                          'INDCLIENT_TEL_FAX'))
                      END,
                      'Bengali')
                      LANGUAGE,
                   FN_GET_PID_NUMBER (CLIENTS_CODE, 'TIN') TIN,
                   NULL VATREGNO,
                   FN_GET_INSIDE_DATA (CORPCLIENTS_ROW_DATA,
                                       'CORPCL_REG_NUM',
                                       'CORPCL_NATURE_OF_BUS1')
                      REGISTRATIONNO,
                   FN_GET_PID_NUMBER (CLIENTS_CODE, 'PP') PASSPORTNO,
                   (SELECT CNTRY_NAME
                      FROM CNTRY
                     WHERE CNTRY_CODE =
                              (CASE
                                  WHEN CLIENTS_TYPE_FLG = 'I'
                                  THEN
                                     FN_GET_PP_CNTRY (CLIENTS_CODE)
                                  ELSE
                                     'BD'
                               END))
                      PASSPORTISSUECOUNTRY,
                   FN_GET_PP_ISSUE_EXP_DATE (CLIENTS_CODE, 'I')
                      PASSPORTISSUEDATE,
                   FN_GET_PP_ISSUE_EXP_DATE (CLIENTS_CODE, 'E')
                      PASSPORTEXPIRYDATE,
                   NULL VISANO,
                   NULL EXPIRYDATEOFVISA,
                   CASE
                      WHEN     FN_GET_INSIDE_DATA (
                                  INDCLIENTS_ROW_DATA,
                                  'INDCLIENT_RESIDENT_STATUS',
                                  'INDCLIENT_EMAIL_ADDR1') = 'N'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_ADDR_SL',
                                                   'ADDRDTLS_CURR_ADDR') =
                                  '1'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_CURR_ADDR',
                                                   'ADDRDTLS_ADDR1') = '1'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_CNTRY_CODE',
                                                   'ADDRDTLS_PERM_ADDR') =
                                  'US'
                      THEN
                         '1'
                      ELSE
                         '0'
                   END
                      ISUSCITIZEN,
                   CASE
                      WHEN     FN_GET_INSIDE_DATA (
                                  INDCLIENTS_ROW_DATA,
                                  'INDCLIENT_RESIDENT_STATUS',
                                  'INDCLIENT_EMAIL_ADDR1') = 'N'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_ADDR_SL',
                                                   'ADDRDTLS_CURR_ADDR') =
                                  '1'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_CURR_ADDR',
                                                   'ADDRDTLS_ADDR1') = '1'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_CNTRY_CODE',
                                                   'ADDRDTLS_PERM_ADDR') =
                                  'US'
                      THEN
                         '1'
                      ELSE
                         '0'
                   END
                      ISGREENCARDHOLDER,
                   CASE
                      WHEN     FN_GET_INSIDE_DATA (
                                  INDCLIENTS_ROW_DATA,
                                  'INDCLIENT_RESIDENT_STATUS',
                                  'INDCLIENT_EMAIL_ADDR1') = 'N'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_ADDR_SL',
                                                   'ADDRDTLS_CURR_ADDR') =
                                  '1'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_CURR_ADDR',
                                                   'ADDRDTLS_ADDR1') = '1'
                           AND FN_GET_INSIDE_DATA (ADDRDTLS_PRES_ROW_DATA,
                                                   'ADDRDTLS_CNTRY_CODE',
                                                   'ADDRDTLS_PERM_ADDR') =
                                  'US'
                      THEN
                         '1'
                      ELSE
                         '0'
                   END
                      ISUSOWNERSHIP,
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I'
                      THEN
                         (SELECT DESIG_DESCN
                            FROM DESIGNATIONS
                           WHERE DESIG_CODE =
                                    FN_GET_INSIDE_DATA (
                                       INDCLIENTS_ROW_DATA,
                                       'INDCLIENT_DESIG_CODE',
                                       'INDCLIENT_EMP_CMP_ADDR1'))
                   END
                      DESIGNATION,
                   FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                       'INDCLIENT_EMP_CMP_NAME',
                                       'INDCLIENT_LANG_CODE')
                      NAMEOFEMPLOYER,
                   SUBSTR (
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_EMP_CMP_ADDR1',
                                             'INDCLIENT_EMP_CMP_ADDR2')
                      || FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_EMP_CMP_ADDR2',
                                             'INDCLIENT_EMP_CMP_ADDR3')
                      || FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_EMP_CMP_ADDR3',
                                             'INDCLIENT_EMP_CMP_ADDR4')
                      || FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_EMP_CMP_ADDR4',
                                             'INDCLIENT_EMP_CMP_ADDR5')
                      || FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_EMP_CMP_ADDR5',
                                             'INDCLIENT_EMP_CMP_NAME'),
                      1,
                      50)
                      EMPLOYERADDRESS1,
                   NULL EMPLOYERADDRESS3,
                   NULL EMPLOYERADDRESS2,
                   NULL SOURCEOFFUND,
                   NULL SOURCEOFINCOME,
                   NULL INTRODUCERNAME,
                   NULL INTRODUCERACCNO,
                   NULL ACCOUNTOPENINGOFFICER,
                   NULL ACCOUNTOPENINGPURPOSE,
                   NULL ACCOUNTOPENINGWAY,
                   CLIENTS_OPENING_DATE CUSTOMERCREATIONDATE,
                   NVL(CLIENTS_LAST_MOD_ON, CLIENTS_AUTH_ON) LASTUPDATEDATE,
                   CLIENTS_ENTD_ON ENTRYDATE,
                   CASE WHEN CLIENTS_TYPE_FLG = 'I' THEN 'I' ELSE 'C' END
                      CUSTOMERTYPE,
                   NULL PERMANENTADDRESS4,
                   NULL PRESENTADDRESS4,
                   /*
                               CASE
                                  WHEN NVL (
                                          TO_NUMBER (
                                             FN_GET_INSIDE_DATA (CORPCLIENTS_ROW_DATA,
                                                                 'CORPCL_NETWORTH_AMT',
                                                                 'CORPCL_INCORP_CNTRY')),
                                          0) BETWEEN 0
                                                 AND 10000000
                                  THEN
                                     '2505'
                                  WHEN NVL (
                                          TO_NUMBER (
                                             FN_GET_INSIDE_DATA (CORPCLIENTS_ROW_DATA,
                                                                 'CORPCL_NETWORTH_AMT',
                                                                 'CORPCL_INCORP_CNTRY')),
                                          0) BETWEEN 10000001
                                                 AND 30000000
                                  THEN
                                     '2506'
                                  ELSE
                                     '2507'
                               END*/
                   NVL (
                      TO_NUMBER (
                         FN_GET_INSIDE_DATA (CORPCLIENTS_ROW_DATA,
                                             'CORPCL_NETWORTH_AMT',
                                             'CORPCL_INCORP_CNTRY')),
                      0)
                      NETWORTH,
                   NULL KYCSTATUS,
                   NULL KYCREFNO,
                   NULL ENVRISK,
                   NULL SECT,
                   NULL SME,
                   NULL SUBMITAGEPROOF,
                   1 ISACTIVE
              FROM (SELECT CLIENTS_CODE,
                           CLIENTS_TYPE_FLG,
                           CLIENTS_NAME,
                           CLIENTS_CUST_CATG,
                           CLIENTS_OPENING_DATE,
                           CLIENTS_HOME_BRN_CODE,
                           CLIENTS_TITLE_CODE,
                           CLIENTS_LOCN_CODE,
                           CLIENTS_LAST_MOD_ON,
                           CLIENTS_ENTD_ON,
						   CLIENTS_AUTH_ON,
                           (SELECT    'INDCLIENT_DESIG_CODE'
                                   || INDCLIENT_DESIG_CODE
                                   || 'INDCLIENT_EMP_CMP_ADDR1'
                                   || INDCLIENT_EMP_CMP_ADDR1
                                   || 'INDCLIENT_EMP_CMP_ADDR2'
                                   || INDCLIENT_EMP_CMP_ADDR2
                                   || 'INDCLIENT_EMP_CMP_ADDR3'
                                   || INDCLIENT_EMP_CMP_ADDR3
                                   || 'INDCLIENT_EMP_CMP_ADDR4'
                                   || INDCLIENT_EMP_CMP_ADDR4
                                   || 'INDCLIENT_EMP_CMP_ADDR5'
                                   || INDCLIENT_EMP_CMP_ADDR5
                                   || 'INDCLIENT_EMP_CMP_NAME'
                                   || INDCLIENT_EMP_CMP_NAME
                                   || 'INDCLIENT_LANG_CODE'
                                   || INDCLIENT_LANG_CODE
                                   || 'INDCLIENT_TEL_FAX'
                                   || INDCLIENT_TEL_FAX
                                   || 'INDCLIENT_TEL_OFF'
                                   || INDCLIENT_TEL_OFF
                                   || 'INDCLIENT_TEL_RES'
                                   || INDCLIENT_TEL_RES
                                   || 'INDCLIENT_MARITAL_STATUS'
                                   || INDCLIENT_MARITAL_STATUS
                                   || 'INDCLIENT_MIDDLE_NAME'
                                   || INDCLIENT_MIDDLE_NAME
                                   || 'INDCLIENT_FIRST_NAME'
                                   || INDCLIENT_FIRST_NAME
                                   || 'INDCLIENT_LAST_NAME'
                                   || INDCLIENT_LAST_NAME
                                   || 'INDCLIENT_SUR_NAME'
                                   || INDCLIENT_SUR_NAME
                                   || 'INDCLIENT_OCCUPN_CODE'
                                   || INDCLIENT_OCCUPN_CODE
                                   || 'INDCLIENT_BC_ANNUAL_INCOME'
                                   || INDCLIENT_BC_ANNUAL_INCOME
                                   || 'INDCLIENT_BIRTH_DATE'
                                   || INDCLIENT_BIRTH_DATE
                                   || 'INDCLIENT_NATNL_CODE'
                                   || INDCLIENT_NATNL_CODE
                                   || 'INDCLIENT_RESIDENT_STATUS'
                                   || INDCLIENT_RESIDENT_STATUS
                                   || 'INDCLIENT_EMAIL_ADDR1'
                                   || INDCLIENT_EMAIL_ADDR1
                                   || 'INDCLIENT_EMAIL_ADDR2'
                                   || INDCLIENT_EMAIL_ADDR2
                                   || 'INDCLIENT_FATHER_NAME'
                                   || INDCLIENT_FATHER_NAME
                                   || 'INDCLIENT_MOTHER_NAME'
                                   || INDCLIENT_MOTHER_NAME
                                   || 'INDCLIENT_SEX'
                                   || INDCLIENT_SEX
                                   || 'INDCLIENT_BIRTH_PLACE_NAME'
                                   || INDCLIENT_BIRTH_PLACE_NAME
                                   || 'INDCLIENT_BIRTH_PLACE_CODE'
                                   || INDCLIENT_BIRTH_PLACE_CODE
                              FROM INDCLIENTS
                             WHERE INDCLIENT_CODE = CLIENTS_CODE)
                              INDCLIENTS_ROW_DATA,
                           (SELECT    'ADDRDTLS_POSTAL_CODE'
                                   || ADDRDTLS_POSTAL_CODE
                                   || 'ADDRDTLS_ADDR_SL'
                                   || ADDRDTLS_ADDR_SL
                                   || 'ADDRDTLS_CURR_ADDR'
                                   || ADDRDTLS_CURR_ADDR
                                   || 'ADDRDTLS_ADDR1'
                                   || ADDRDTLS_ADDR1
                                   || 'ADDRDTLS_ADDR2'
                                   || ADDRDTLS_ADDR2
                                   || 'ADDRDTLS_ADDR3'
                                   || ADDRDTLS_ADDR3
                                   || 'ADDRDTLS_ADDR4'
                                   || ADDRDTLS_ADDR4
                                   || 'ADDRDTLS_ADDR5'
                                   || ADDRDTLS_ADDR5
                                   || 'ADDRDTLS_LOCN_CODE'
                                   || ADDRDTLS_LOCN_CODE
                                   || 'ADDRDTLS_CNTRY_CODE'
                                   || ADDRDTLS_CNTRY_CODE
                                   || 'ADDRDTLS_PERM_ADDR'
                                   || ADDRDTLS_PERM_ADDR
                                   || 'ADDRDTLS_PHONE_NUM1'
                                   || ADDRDTLS_PHONE_NUM1
                                   || 'ADDRDTLS_PHONE_NUM2'
                                   || ADDRDTLS_PHONE_NUM2
                                   || 'ADDRDTLS_MOBILE_NUM'
                                   || ADDRDTLS_MOBILE_NUM
                              FROM ADDRDTLS
                             WHERE     ADDRDTLS_INV_NUM =
                                          CLIENTS_ADDR_INV_NUM
                                   AND ADDRDTLS_ADDR_TYPE = '01')
                              ADDRDTLS_PRES_ROW_DATA,
                           (SELECT    'ADDRDTLS_ADDR_SL'
                                   || ADDRDTLS_ADDR_SL
                                   || 'ADDRDTLS_CURR_ADDR'
                                   || ADDRDTLS_CURR_ADDR
                                   || 'ADDRDTLS_ADDR1'
                                   || ADDRDTLS_ADDR1
                                   || 'ADDRDTLS_ADDR2'
                                   || ADDRDTLS_ADDR2
                                   || 'ADDRDTLS_ADDR3'
                                   || ADDRDTLS_ADDR3
                                   || 'ADDRDTLS_ADDR4'
                                   || ADDRDTLS_ADDR4
                                   || 'ADDRDTLS_ADDR5'
                                   || ADDRDTLS_ADDR5
                                   || 'ADDRDTLS_LOCN_CODE'
                                   || ADDRDTLS_LOCN_CODE
                                   || 'ADDRDTLS_CNTRY_CODE'
                                   || ADDRDTLS_CNTRY_CODE
                                   || 'ADDRDTLS_PERM_ADDR'
                                   || ADDRDTLS_PERM_ADDR
                                   || 'ADDRDTLS_PHONE_NUM1'
                                   || ADDRDTLS_PHONE_NUM1
                                   || 'ADDRDTLS_PHONE_NUM2'
                                   || ADDRDTLS_PHONE_NUM2
                                   || 'ADDRDTLS_MOBILE_NUM'
                                   || ADDRDTLS_MOBILE_NUM
                              FROM ADDRDTLS
                             WHERE     ADDRDTLS_INV_NUM =
                                          CLIENTS_ADDR_INV_NUM
                                   AND ADDRDTLS_ADDR_TYPE = '02')
                              ADDRDTLS_PERM_ROW_DATA,
                           (SELECT    'CORPCL_REG_NUM'
                                   || CORPCL_REG_NUM
                                   || 'CORPCL_NATURE_OF_BUS1'
                                   || CORPCL_NATURE_OF_BUS1
                                   || 'CORPCL_NATURE_OF_BUS2'
                                   || CORPCL_NATURE_OF_BUS2
                                   || 'CORPCL_NATURE_OF_BUS3'
                                   || CORPCL_NATURE_OF_BUS3
                                   || 'CORPCL_NETWORTH_AMT'
                                   || CORPCL_NETWORTH_AMT
                                   || 'CORPCL_INCORP_CNTRY'
                                   || CORPCL_INCORP_CNTRY
                                   || 'CORPCL_RESIDENT_STATUS'
                                   || CORPCL_RESIDENT_STATUS
                              FROM CORPCLIENTS
                             WHERE CORPCL_CLIENT_CODE = CLIENTS_CODE)
                              CORPCLIENTS_ROW_DATA
                      FROM CLIENTS
                     WHERE     CLIENTS_TYPE_FLG IN ('I', 'C')
                           AND CLIENTS_HOME_BRN_CODE = IDX.BRANCH_CODE);



         INSERT INTO AML_ACCOUNTINFORMATIONS
            SELECT FACNO (ACNTS_ENTITY_NUM, ACNTS_INTERNAL_ACNUM)
                      ACCOUNTNUMBER,
                   ACNTS_AC_NAME1 || ACNTS_AC_NAME2 ACCOUNTTITLE,
                   ACNTS_AC_TYPE /*(SELECT PRODUCT_NAME
                      FROM PRODUCTS
                     WHERE PRODUCT_CODE = ACNTS_PROD_CODE)*/
                                PRODUCTNAME,
                   ACNTS_CLIENT_NUM CUSTOMERNO,
                   (SELECT CASE
                              WHEN PRODUCT_FOR_DEPOSITS = '1'
                              THEN
                                 CASE
                                    WHEN PRODUCT_FOR_RUN_ACS = '1'
                                    THEN
                                       CASE
                                          WHEN PRODUCT_CODE = 20
                                          THEN
                                             'Current'
                                          ELSE
                                             'Savings'
                                       END
                                    ELSE
                                       CASE
                                          WHEN PRODUCT_CONTRACT_ALLOWED = '1'
                                          THEN
                                             'Fixed'
                                          ELSE
                                             'Recurring'
                                       END
                                 END
                              ELSE
                                 'Loan'
                           END
                              PRODUCT_TYPE
                      FROM PRODUCTS
                     WHERE PRODUCT_CODE = ACNTS_PROD_CODE)
                      PRODUCTCATEGORY,
                   CASE
                      WHEN (SELECT CLIENTS_TYPE_FLG
                              FROM CLIENTS
                             WHERE CLIENTS_CODE = ACNTS_CLIENT_NUM) = 'I'
                      THEN
                         'Individual'
                      ELSE
                         'Entity'
                   END
                      OWNERSHIPTYPE,
                   ACNTS.ACNTS_CURR_CODE CURRENCY,
                   ACNTS.ACNTS_OPENING_DATE OPENINGDATE,
                   ACNTS.ACNTS_BRN_CODE CBSBRANCHCODE,
                   ACNTS.ACNTS_ENTD_ON ACCOUNTCREATIONDATE,
                   TRANPROFILE.ACTPH_SRC_FUND TYPEOFBUSINESSORSOURCEOFINCOME,
                   TRANPROFILE.ACTPH_NOT_CASHR DTRNOCASH,                 ----
                   TRANPROFILE.ACTPH_CUTOFF_LMT_CASHR DMAXTRAMOUNTCASH,
                   TRANPROFILE.ACTPH_MAXAMT_CASHR DMONTHLYTOTALAMOUNTCASH,
                   TRANPROFILE.ACTPH_NOT_NONCASHR DTRNOTRANSFER,
                   TRANPROFILE.ACTPH_CUTOFF_LMT_NONCASHR DMAXTRAMOUNTTRANSFER,
                   TRANPROFILE.ACTPH_MAXAMT_NCASHR
                      DMONTHLYTOTALAMOUNTTRANSFER,
                   TRANPROFILE.ACTPH_NOT_TFREMR DTRNOREMITANCE,
                   TRANPROFILE.ACTPH_CUTOFF_LMT_TFREMR DMAXTRAMOUNTREMITTANCE,
                   TRANPROFILE.ACTPH_MAXAMT_TFREMR
                      DMONTHLYTOTALAMOUNTREMITTANCE,
                   NULL DTRNOEXPORT,
                   NULL DMAXTRAMOUNTEXPORT,
                   NULL DMONTHLYTOTALAMOUNTEXPORT,
                   TRANPROFILE.ACTPH_NOT_NONTFREMR DTRNOOTHERS,
                   TRANPROFILE.ACTPH_CUTOFF_LMT_NONTFREMR DMAXTRAMOUNTOTHERS,
                   TRANPROFILE.ACTPH_MAXAMT_NONTFREMR
                      DMONTHLYTOTALAMOUNTOTHERS,
                     ACTPH_MAXAMT_CASHR
                   + ACTPH_MAXAMT_NCASHR
                   + ACTPH_MAXAMT_TFREMR
                   + ACTPH_MAXAMT_NONTFREMR
                      TOTALMONTHLYDEPOSOIT,                                ---
                   TRANPROFILE.ACTPH_NOT_CASHP WTRNOCASH,
                   TRANPROFILE.ACTPH_CUTOFF_LMT_CASHP WMAXTRAMOUNTCASH,
                   TRANPROFILE.ACTPH_MAXAMT_CASHP WMONTHLYTOTALAMOUNTCASH,
                   TRANPROFILE.ACTPH_NOT_NONCASHP WTRNOTRANSFER,
                   TRANPROFILE.ACTPH_CUTOFF_LMT_NONCASHP WMAXTRAMOUNTTRANSFER,
                   TRANPROFILE.ACTPH_MAXAMT_NCASHP
                      WMONTHLYTOTALAMOUNTTRANSFER,
                   TRANPROFILE.ACTPH_NOT_TFREMP WTRNOREMITANCE,
                   TRANPROFILE.ACTPH_CUTOFF_LMT_TFREMP WMAXTRAMOUNTREMITANCE,
                   TRANPROFILE.ACTPH_MAXAMT_TFREMP
                      WMONTHLYTOTALAMOUNTREMITANCE,
                   NULL WTRNOIMPORT,
                   NULL WMAXTRAMOUNTIMPORT,
                   NULL WMONTHLYTOTALAMOUNTIMPORT,
                   TRANPROFILE.ACTPH_NOT_NONTFREMP WTRNOOTHERS,
                   TRANPROFILE.ACTPH_CUTOFF_LMT_NONTFREMP WMAXTRAMOUNTOTHERS,
                   TRANPROFILE.ACTPH_MAXAMT_NONTFREMP
                      WMONTHLYTOTALAMOUNTOTHERS,
                     ACTPH_MAXAMT_CASHP
                   + ACTPH_MAXAMT_NCASHP
                   + ACTPH_MAXAMT_TFREMP
                   + ACTPH_MAXAMT_NONTFREMP
                      TOTALMONTHLYWITHDRAWAL,
                   NVL(ACNTS_LAST_MOD_ON,ACNTS_AUTH_ON) ACCOUNTUPDATEDATE,
                   CASE
                      WHEN ACNTS_INOP_ACNT = 1 OR ACNTS_DORMANT_ACNT = 1
                      THEN
                         1
                      ELSE
                         0
                   END
                      ISDORMANT,
                   NULL ISSIGNATORY,
                   NULL TRAKINGNO,
                   CASE WHEN ACNTS_CLOSURE_DATE IS NULL THEN 1 ELSE 0 END
                      ISACTIVE,
                   ACNTS_CLOSURE_DATE ACCCLOSINGDATE
              FROM ACNTS
                   LEFT OUTER JOIN
                   (SELECT ACNTRNPRHIST.*
                      FROM ACNTRNPRHIST,
                           (  SELECT ACTPH_ACNT_NUM,
                                     MAX (ACTPH_LATEST_EFF_DATE)
                                        ACTPH_LATEST_EFF_DATE
                                FROM ACNTRNPRHIST
                            GROUP BY ACTPH_ACNT_NUM) MAXACNTRNPR
                     WHERE     ACNTRNPRHIST.ACTPH_ACNT_NUM =
                                  MAXACNTRNPR.ACTPH_ACNT_NUM
                           AND ACNTRNPRHIST.ACTPH_LATEST_EFF_DATE =
                                  MAXACNTRNPR.ACTPH_LATEST_EFF_DATE)
                   TRANPROFILE
                      ON (ACNTS.ACNTS_INTERNAL_ACNUM =
                             TRANPROFILE.ACTPH_ACNT_NUM)
             WHERE ACNTS_ENTITY_NUM = 1 AND ACNTS_BRN_CODE = IDX.BRANCH_CODE;

         FOR FIN_YEAR IN 2014 .. V_FIN_YEAR
         LOOP
            V_SQL :=
                  '
         INSERT INTO AML_TRANSACTIONS
            SELECT TR.ACCOUNTORREFERENCENO,
                   TR.TRANSACTIONNO,
                   TR.TRANSACTIONTYPE,
                   TR.TRANSACTIONMEDIA,
                   TR.AMOUNT,
                   TR.BALANCE,
                   TR.CURRENCY,
                   TR.BENEFICIARYNAME,
                   TR.TELLERID,
                   TR.TRANSACTIONDATE,
                   TR.TRANSACTIONTIMESTAMP,
                   LPAD(TR.CBSBRANCHCODE, 4, ''0''),
                   TR.GEOLOCATION,
                   TR.COMMENTS,
                   TR.BENIFICIARYACNO,
                   TR.BENIFICIARYBRANCHNAME,
                   TR.BENIFICIARYBANKNAME,
                   CT_PERSON_NAME DEPOSITORNAME
              FROM (SELECT FACNO (TRAN_ENTITY_NUM, TRAN_INTERNAL_ACNUM)
                              ACCOUNTORREFERENCENO,
                              TRAN_BRN_CODE
                           || ''/''
                           || TRAN_DATE_OF_TRAN
                           || ''/''
                           || TRAN_BATCH_NUMBER
                           || ''/''
                           || TRAN_BATCH_SL_NUM
                              TRANSACTIONNO,
                           CASE
                              WHEN TRAN_DB_CR_FLG = ''D'' THEN ''DR''
                              ELSE ''CR''
                           END
                              TRANSACTIONTYPE,
                           CASE WHEN TRAN_ENTD_BY = ''CBSATM'' THEN ''ATM''
                           WHEN TRAN_ENTD_BY = ''CBSRMS'' THEN ''RMS''
                           WHEN TRAN_ENTD_BY = ''CBSRTGS'' THEN ''RTGS''
                           WHEN TRAN_ENTD_BY = ''INCENTIV'' THEN ''INCENTIV''
                           ELSE
                                CASE WHEN TRAN_TYPE_OF_TRAN = 1 THEN 
                                    CASE WHEN TRAN_DB_CR_FLG = ''D'' THEN 
                                        ''TRFD''
                                    ELSE
                                        ''TRFC''
                                    END 
                                WHEN TRAN_TYPE_OF_TRAN = 2 THEN 
                                    CASE WHEN TRAN_DB_CR_FLG = ''D'' THEN 
                                        ''CLRD''
                                    ELSE
                                        ''CLRC''
                                    END 
                                WHEN TRAN_TYPE_OF_TRAN = 3 THEN 
                                    CASE WHEN TRAN_DB_CR_FLG = ''D'' THEN 
                                        ''CSHD''
                                    ELSE
                                        ''CSHC''
                                    END 
                                END 
                           END TRANSACTIONMEDIA,
                           TRAN_AMOUNT AMOUNT,
                           TRAN_AVAILABLE_AC_BAL BALANCE,
                           TRAN_CURR_CODE CURRENCY,
                           ACNTS_AC_NAME1 || ACNTS_AC_NAME2 BENEFICIARYNAME,
                           TRAN_ENTD_BY TELLERID,
                           TRAN_DATE_OF_TRAN TRANSACTIONDATE,
                           TRAN_ENTD_ON TRANSACTIONTIMESTAMP,
                           --TO_CHAR(TRAN_ENTD_ON, ''HH24:MI:SS'') TRANSACTIONTIMESTAMP,
                           TRAN_BRN_CODE CBSBRANCHCODE,
                           NULL GEOLOCATION,
                           CASE
                              WHEN TRIM (
                                         TRAN_NARR_DTL1
                                      || TRAN_NARR_DTL2
                                      || TRAN_NARR_DTL3)
                                      IS NOT NULL
                              THEN
                                 TRIM (
                                       TRAN_NARR_DTL1
                                    || TRAN_NARR_DTL2
                                    || TRAN_NARR_DTL3)
                              ELSE
                                 TRIM (
                                       TRANBAT_NARR_DTL1
                                    || TRANBAT_NARR_DTL2
                                    || TRANBAT_NARR_DTL3)
                           END
                              COMMENTS,
                           FACNO (TRAN_ENTITY_NUM, TRAN_INTERNAL_ACNUM)
                              BENIFICIARYACNO,
                           MBRN_NAME BENIFICIARYBRANCHNAME,
                           (SELECT INS_NAME_OF_BANK FROM INSTALL)
                              BENIFICIARYBANKNAME,
                           TRAN_BATCH_NUMBER
                      FROM TRAN'
               || FIN_YEAR
               || ',
                           TRANBAT'
               || FIN_YEAR
               || ',
                           ACNTS,
                           MBRN
                     WHERE     TRAN_ENTITY_NUM = 1
                           AND TRANBAT_ENTITY_NUM = TRAN_ENTITY_NUM
                           AND TRANBAT_BRN_CODE = TRAN_BRN_CODE
                           AND TRANBAT_DATE_OF_TRAN = TRAN_DATE_OF_TRAN
                           AND TRANBAT_BATCH_NUMBER = TRAN_BATCH_NUMBER
                           AND TRAN_INTERNAL_ACNUM <> 0
                           AND TRAN_AUTH_BY IS NOT NULL
                           AND ACNTS_ENTITY_NUM = TRAN_ENTITY_NUM
                           AND ACNTS_INTERNAL_ACNUM = TRAN_INTERNAL_ACNUM
                           AND MBRN_ENTITY_NUM = 1
                           AND MBRN_CODE = TRAN_BRN_CODE
                           AND TRAN_BRN_CODE = '
               || IDX.BRANCH_CODE
               || ') TR
                   LEFT OUTER JOIN
                   CTRAN'
               || FIN_YEAR
               || '
                      ON (    CTRAN_ENTITY_NUM = 1
                          AND CT_BRN_CODE = POST_TRAN_BRN
                          AND CT_TRAN_DATE = POST_TRAN_DATE
                          AND CT_CASHIER_ID = TR.TELLERID
                          AND POST_TRAN_BRN = TR.CBSBRANCHCODE
                          AND POST_TRAN_DATE = TR.TRANSACTIONDATE
                          AND POST_TRAN_BATCH_NUM = TR.TRAN_BATCH_NUMBER
                          AND POST_TRAN_BRN = '
               || IDX.BRANCH_CODE
               || ') ';


            EXECUTE IMMEDIATE V_SQL;
         END LOOP;

         INSERT INTO AML_CLIENT_INSERT_LOG (BRANCH_CODE, MESSAGE, FINISHTIME)
              VALUES (IDX.BRANCH_CODE, 'SUCCESSFUL', SYSDATE);

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            V_ERROR_MSG := SUBSTR (SQLERRM, 1, 3000);

            INSERT
              INTO AML_CLIENT_INSERT_LOG (BRANCH_CODE, MESSAGE, FINISHTIME)
            VALUES (IDX.BRANCH_CODE, V_ERROR_MSG, SYSDATE);
      END;
   END LOOP;
END SP_GEN_AML_FULLDATA;
/
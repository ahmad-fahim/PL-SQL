CREATE OR REPLACE PROCEDURE SP_GEN_AML_CLIENT_DATA (
   P_FROM_BRN    NUMBER,
   P_TO_BRN      NUMBER)
IS
BEGIN
   FOR IDX IN (  SELECT *
              FROM (  SELECT BRANCH_CODE, ROWNUM BRANCH_SL
                        FROM MIG_DETAIL
                    ORDER BY BRANCH_CODE)
             WHERE     BRANCH_SL BETWEEN P_FROM_BRN AND P_TO_BRN
                   AND BRANCH_CODE NOT IN (SELECT CBS_BRANCH_CODE
                                             FROM AML_CLIENT_DATA )
          ORDER BY BRANCH_CODE)
   LOOP
   INSERT INTO AML_CLIENT_DATA
      SELECT CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                       'INDCLIENT_FIRST_NAME',
                                       'INDCLIENT_LAST_NAME')
                ELSE
                   CLIENTS_NAME
             END
                FIRST_NAME,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   DECODE (
                      TRIM (
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_LAST_NAME',
                                             'INDCLIENT_SUR_NAME')),
                      NULL, TRIM (
                               FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                                   'INDCLIENT_SUR_NAME',
                                                   'INDCLIENT_OCCUPN_CODE')),
                      TRIM (
                         FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_LAST_NAME',
                                             'INDCLIENT_SUR_NAME')))
             END
                LAST_NAME,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                THEN
                      FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR1',
                                          'ADDRDTLS_ADDR2')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR2',
                                          'ADDRDTLS_ADDR3')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR3',
                                          'ADDRDTLS_ADDR4')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR4',
                                          'ADDRDTLS_ADDR5')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR5',
                                          'ADDRDTLS_LOCN_CODE')
             END
                PRESENT_ADDRESS,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                THEN
                   (SELECT DISTRICT_NAME
                      FROM LOCATION, DISTRICT
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = DISTRICT_CNTRY_CODE
                           AND LOCN_STATE_CODE = DISTRICT_STATE_CODE
                           AND LOCN_DISTRICT_CODE = DISTRICT_CODE)
             END
                PRESENT_CITY,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                THEN
                   (SELECT CNTRY_NAME
                      FROM LOCATION, CNTRY
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = CNTRY_CODE)
             END
                PRESENT_COUNTRY,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   (SELECT PROFESSION_CODE
                      FROM OCCUPATIONS_MAPPING
                     WHERE OCCUPATIONS_CODE =
                              FN_GET_INSIDE_DATA (
                                 INDCLIENTS_ROW_DATA,
                                 'INDCLIENT_OCCUPN_CODE',
                                 'INDCLIENT_BC_ANNUAL_INCOME'))
             END
                CUSTOMER_PROFESSION,
             --CASE
             --   WHEN CLIENTS_TYPE_FLG = 'I'
             --   THEN
             CASE
                WHEN    (SELECT SUM (NVL (ACNTS_MKT_BY_BRN, 0))
                           FROM ACNTS
                          WHERE     ACNTS_ENTITY_NUM = 1
                                AND ACNTS_CLIENT_NUM = CLIENTS_CODE) <> 0
                     OR (SELECT TO_CHAR (
                                   WM_CONCAT (TRIM (ACNTS_MKT_BY_STAFF)))
                           FROM ACNTS
                          WHERE     ACNTS_ENTITY_NUM = 1
                                AND ACNTS_CLIENT_NUM = CLIENTS_CODE)
                           IS NOT NULL
                THEN
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I' THEN '2001'
                      WHEN CLIENTS_TYPE_FLG = 'C' THEN '2501'
                   END
                WHEN (SELECT TO_CHAR (WM_CONCAT (TRIM (ACNTS_DSA_CODE)))
                        FROM ACNTS
                       WHERE     ACNTS_ENTITY_NUM = 1
                             AND ACNTS_CLIENT_NUM = CLIENTS_CODE)
                        IS NOT NULL
                THEN
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I' THEN '2002'
                      WHEN CLIENTS_TYPE_FLG = 'C' THEN '2502'
                   END
                WHEN (SELECT TO_CHAR (WM_CONCAT (TRIM (ACNTS_DCHANNEL_CODE)))
                        FROM ACNTS
                       WHERE     ACNTS_ENTITY_NUM = 1
                             AND ACNTS_CLIENT_NUM = CLIENTS_CODE
                             AND ACNTS_DCHANNEL_CODE IN
                                    (SELECT DCHANNEL_CODE
                                       FROM DCHANNELS
                                      WHERE DCHANNEL_FOR_IBANK = '1'))
                        IS NOT NULL
                THEN
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I' THEN '2003'
                      WHEN CLIENTS_TYPE_FLG = 'C' THEN '2503'
                   END
                ELSE
                   CASE
                      WHEN CLIENTS_TYPE_FLG = 'I' THEN '2004'
                      WHEN CLIENTS_TYPE_FLG = 'C' THEN '2504'
                   END
             END
                ACCOUNT_OPENING_WAY,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   CASE NVL (
                           TRIM (
                              FN_GET_INSIDE_DATA (
                                 INDCLIENTS_ROW_DATA,
                                 'INDCLIENT_BC_ANNUAL_INCOME',
                                 'INDCLIENT_BIRTH_DATE')),
                           '1')
                      WHEN '1'
                      THEN
                         '3001'
                      WHEN '2'
                      THEN
                         '3002'
                      ELSE
                         '3003'
                   END
             END
                NET_INCOME,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'C'
                THEN
                   TRIM (
                         FN_GET_INSIDE_DATA (CORPCLIENTS_ROW_DATA,
                                             'CORPCL_NATURE_OF_BUS1',
                                             'CORPCL_NATURE_OF_BUS2')
                      || FN_GET_INSIDE_DATA (CORPCLIENTS_ROW_DATA,
                                             'CORPCL_NATURE_OF_BUS2',
                                             'CORPCL_NATURE_OF_BUS3')
                      || FN_GET_INSIDE_DATA (CORPCLIENTS_ROW_DATA,
                                             'CORPCL_NATURE_OF_BUS3',
                                             'CORPCL_NETWORTH_AMT'))
             END
                NATURE_OF_BUSINESS,
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
             END
                NET_WORTH,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   GET_NID_NUMBER (CLIENTS_CODE, 'NID')
             END
                NID,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   TO_DATE (
                      FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                          'INDCLIENT_BIRTH_DATE',
                                          'INDCLIENT_NATNL_CODE'))
             END
                DATE_OF_BIRTH,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_PERM_ADDR',
                                             'ADDRDTLS_PHONE_NUM1') = '1'
                THEN
                      FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR1',
                                          'ADDRDTLS_ADDR2')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR2',
                                          'ADDRDTLS_ADDR3')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR3',
                                          'ADDRDTLS_ADDR4')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR4',
                                          'ADDRDTLS_ADDR5')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_ADDR5',
                                          'ADDRDTLS_LOCN_CODE')
             END
                PERMANENT_ADDRESS,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_PERM_ADDR',
                                             'ADDRDTLS_PHONE_NUM1') = '1'
                THEN
                   (SELECT CNTRY_NAME
                      FROM LOCATION, CNTRY
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = CNTRY_CODE)
             END
                PERMANENT_COUNTRY,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_PERM_ADDR',
                                             'ADDRDTLS_PHONE_NUM1') = '1'
                THEN
                   (SELECT DISTRICT_NAME
                      FROM LOCATION, DISTRICT
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = DISTRICT_CNTRY_CODE
                           AND LOCN_STATE_CODE = DISTRICT_STATE_CODE
                           AND LOCN_DISTRICT_CODE = DISTRICT_CODE)
             END
                PERMANENT_CITY,
             CASE
                WHEN (SELECT CLIENTCATS_GOVT_FLAG
                        FROM CLIENTCATS_TYPE
                       WHERE CLIENTCATS_CATG_CODE = CLIENTS_CUST_CATG) = '1'
                THEN
                   '1'
                ELSE
                   '0'
             END
                IS_GOVERNMENT_CUSTOMER,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   (SELECT CNTRY_NAME
                      FROM CNTRY
                     WHERE CNTRY_CODE =
                              FN_GET_INSIDE_DATA (
                                 INDCLIENTS_ROW_DATA,
                                 'INDCLIENT_NATNL_CODE',
                                 'INDCLIENT_RESIDENT_STATUS'))
             END
                NATIONALITY,
             (SELECT CNTRY_NAME
                FROM CNTRY
               WHERE CNTRY_CODE =
                        (CASE
                            WHEN CLIENTS_TYPE_FLG = 'I'
                            THEN
                               FN_GET_PP_CNTRY (
                                  CLIENTS_CODE,
                                  (SELECT PMLPIDMAP_PID_CODE
                                     FROM PMLPIDMAP
                                    WHERE PMLPIDMAP_PML_PID_TYPE = 'A'))
                            ELSE
                               'BD'
                         END))
                PASSPORT_ISSUE_COUNTRY,
             CASE
                WHEN     FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_RESIDENT_STATUS',
                                             'INDCLIENT_EMAIL_ADDR1') = 'N'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CNTRY_CODE',
                                             'ADDRDTLS_PERM_ADDR') = 'US'
                THEN
                   '1'
                ELSE
                   '0'
             END
                IS_GREEN_CARD_HOLDER,
             CASE
                WHEN     FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_RESIDENT_STATUS',
                                             'INDCLIENT_EMAIL_ADDR1') = 'N'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CNTRY_CODE',
                                             'ADDRDTLS_PERM_ADDR') = 'US'
                THEN
                   '1'
                ELSE
                   '0'
             END
                IS_US_OWNERSHIP,
             CASE
                WHEN     FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                             'INDCLIENT_RESIDENT_STATUS',
                                             'INDCLIENT_EMAIL_ADDR1') = 'N'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CNTRY_CODE',
                                             'ADDRDTLS_PERM_ADDR') = 'US'
                THEN
                   '1'
                ELSE
                   '0'
             END
                IS_US_CITIZEN,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                THEN
                   (SELECT STATE_NAME
                      FROM LOCATION, DISTRICT, STATE
                     WHERE     LOCN_CODE =
                                  FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                                      'ADDRDTLS_LOCN_CODE',
                                                      'ADDRDTLS_CNTRY_CODE')
                           AND LOCN_CNTRY_CODE = DISTRICT_CNTRY_CODE
                           AND LOCN_STATE_CODE = DISTRICT_STATE_CODE
                           AND LOCN_DISTRICT_CODE = DISTRICT_CODE
                           AND STATE_CODE = LOCN_STATE_CODE)
             END
                PRESENT_STATE,
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
                                       'INDCLIENT_FATHER_NAME',
                                       'INDCLIENT_MOTHER_NAME')
             END
                FATHER_NAME,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                       'INDCLIENT_MOTHER_NAME',
                                       'INDCLIENT_SEX')
             END
                MOTHER_NAME,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I'
                THEN
                   CASE
                      WHEN FN_GET_INSIDE_DATA (INDCLIENTS_ROW_DATA,
                                               'INDCLIENT_SEX',
                                               'INDCLIENT_BIRTH_PLACE_NAME') =
                              'M'
                      THEN
                         'Male'
                      ELSE
                         'Female'
                   END
             END
                GENDER,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                THEN
                      FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_PHONE_NUM1',
                                          'ADDRDTLS_PHONE_NUM2')
                   || ' '
                   || FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                          'ADDRDTLS_PHONE_NUM2',
                                          'ADDRDTLS_MOBILE_NUM')
             END
                PHONE,
             CASE
                WHEN     FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_ADDR_SL',
                                             'ADDRDTLS_CURR_ADDR') = '1'
                     AND FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                             'ADDRDTLS_CURR_ADDR',
                                             'ADDRDTLS_ADDR1') = '1'
                THEN
                   FN_GET_INSIDE_DATA (ADDRDTLS_ROW_DATA,
                                       'ADDRDTLS_MOBILE_NUM',
                                       'ADDRDTLS_MOBILE_NUM_999')
             END
                MOBILE,
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
                BIRTH_PLACE,
             CASE
                WHEN CLIENTS_TYPE_FLG = 'I' THEN 'Individual'
                ELSE 'Entity'
             END
                CUSTOMER_TYPE,
             CLIENTS_OPENING_DATE CUSTOMER_CREATION_DATE,
             CLIENTS_CODE CUSTOMER_NO,
             CLIENTS_HOME_BRN_CODE CBS_BRANCH_CODE
        FROM (SELECT CLIENTS_CODE,
                     CLIENTS_TYPE_FLG,
                     CLIENTS_NAME,
                     CLIENTS_CUST_CATG,
                     CLIENTS_OPENING_DATE,
                     CLIENTS_HOME_BRN_CODE,
                     (SELECT    'INDCLIENT_FIRST_NAME'
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
                       WHERE     ADDRDTLS_INV_NUM = CLIENTS_ADDR_INV_NUM
                             AND ADDRDTLS_ADDR_SL = 1)
                        ADDRDTLS_ROW_DATA,
                     (SELECT    'CORPCL_NATURE_OF_BUS1'
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

      COMMIT;
   END LOOP;
END;

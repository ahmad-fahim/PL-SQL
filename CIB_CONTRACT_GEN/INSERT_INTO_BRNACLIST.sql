BEGIN
   FOR IDX IN (  SELECT *
                   FROM MIG_DETAIL
               ORDER BY BRANCH_CODE)
   LOOP
      INSERT INTO BRNACLIST
         SELECT BR_CODE,
                CLIENT_ID,
                ACCOUNT_NO,
                ACC_TITLE,
                PRODUCT_CODE,
                PRODUCT_NAME,
                ACTYPE_CODE,
                ACTYPE_DESCN,
                ACSUB_SUBTYPE_CODE,
                ACSUB_DESCN,
                ACSUB_DESCN,
                SUBSTR (TABLE_TEMP.INDCLIENTS_DATA,
                        1,
                        INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (194)) - 1)
                   INDCLIENT_FATHER_NAME,
                SUBSTR (
                   TABLE_TEMP.INDCLIENTS_DATA,
                   INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (194)) + 1,
                     INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (195))
                   - 1
                   - INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (194)))
                   INDCLIENT_MOTHER_NAME,
                SPOUSE_NAME,
                PERMANENT_ADDRESS,
                PRESENT_ADDRESS,
                BUSINESS_ADDRESS,
                (SELECT LOCN_NAME
                   FROM LOCATION
                  WHERE LOCATION.LOCN_CODE =
                           SUBSTR (
                              TABLE_TEMP.INDCLIENTS_DATA,
                                INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (199))
                              + 1,
                                INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (200))
                              - 1
                              - INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (199))))
                   BIRTH_PLACE,
                SUBSTR (
                   TABLE_TEMP.INDCLIENTS_DATA,
                   INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (195)) + 1,
                     INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (196))
                   - 1
                   - INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (195)))
                   INDCLIENT_SEX,
                SUBSTR (
                   TABLE_TEMP.INDCLIENTS_DATA,
                   INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (196)) + 1,
                     INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (197))
                   - 1
                   - INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (196)))
                   INDCLIENT_BIRTH_DATE,
                (SELECT PIDDOCS_DOCID_NUM
                   FROM PIDDOCS, INDCLIENTS
                  WHERE     INDCLIENT_PID_INV_NUM = PIDDOCS_INV_NUM
                        AND PIDDOCS_PID_TYPE IN ('NID', 'NIN')
                        AND PIDDOCS_DOC_SL = 1
                        AND INDCLIENT_CODE = CLIENT_ID)
                   NID,
                SUBSTR (
                   TABLE_TEMP.INDCLIENTS_DATA,
                   INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (197)) + 1,
                     INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (198))
                   - 1
                   - INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (197)))
                   INDCLIENT_TEL_RES,
                SUBSTR (
                   TABLE_TEMP.INDCLIENTS_DATA,
                   INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (198)) + 1,
                     INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (199))
                   - 1
                   - INSTR (TABLE_TEMP.INDCLIENTS_DATA, CHR (198)))
                   INDCLIENT_TEL_GSM,
                CLIENTS_PAN_GIR_NUM TIN,
                '                                   ' ETIN,
                (SELECT PIDDOCS_DOCID_NUM
                   FROM PIDDOCS, INDCLIENTS
                  WHERE     INDCLIENT_PID_INV_NUM = PIDDOCS_INV_NUM
                        AND PIDDOCS_PID_TYPE = 'PP'
                        AND PIDDOCS_DOC_SL = 1
                        AND INDCLIENT_CODE = CLIENT_ID)
                   PASSPORT,
                (SELECT PIDDOCS_DOCID_NUM
                   FROM PIDDOCS, INDCLIENTS
                  WHERE     INDCLIENT_PID_INV_NUM = PIDDOCS_INV_NUM
                        AND PIDDOCS_PID_TYPE = 'DL'
                        AND PIDDOCS_DOC_SL = 1
                        AND INDCLIENT_CODE = CLIENT_ID)
                   DRIVING_LICENCE,
				   NULL TRADE_LICENCE_NO	,
				   NULL BIRTH_REG_NO	,
				   NULL BUSINESS_ID_NO, 
				   0 OUTSTANDING
           FROM (SELECT ACNTS.ACNTS_BRN_CODE BR_CODE,
                        ACNTS.ACNTS_CLIENT_NUM CLIENT_ID,
                        IACLINK.IACLINK_ACTUAL_ACNUM ACCOUNT_NO,
                        ACNTS.ACNTS_AC_NAME1 || ACNTS.ACNTS_AC_NAME2
                           ACC_TITLE,
                        ACNTS.ACNTS_PROD_CODE PRODUCT_CODE,
                        PRODUCTS.PRODUCT_NAME PRODUCT_NAME,
                        ACNTS.ACNTS_AC_TYPE ACTYPE_CODE,
                        ACTYPES.ACTYPE_DESCN ACTYPE_DESCN,
                        ACNTS.ACNTS_AC_SUB_TYPE ACSUB_SUBTYPE_CODE,
                        --acsubtypes.acsub_descn acsub_descn,
                        NVL (
                           (SELECT ACSUB_DESCN
                              FROM ACSUBTYPES
                             WHERE     ACSUB_ACTYPE_CODE =
                                          ACNTS.ACNTS_AC_TYPE
                                   AND ACSUB_SUBTYPE_CODE =
                                          ACNTS.ACNTS_AC_SUB_TYPE),
                           'N/A')
                           ACSUB_DESCN,
                        (SELECT INDSPOUSE_SPOUSE_NAME
                           FROM INDCLIENTSPOUSE
                          WHERE     INDSPOUSE_CLIENT_CODE =
                                       CLIENTS.CLIENTS_CODE
                                AND INDSPOUSE_SL = 1)
                           SPOUSE_NAME,
                        FN_GET_ADDRESS (CLIENTS.CLIENTS_CODE, '02')
                           PERMANENT_ADDRESS,
                        FN_GET_ADDRESS (CLIENTS.CLIENTS_CODE, '01')
                           PRESENT_ADDRESS,
                        FN_GET_ADDRESS (CLIENTS.CLIENTS_CODE, '04')
                           BUSINESS_ADDRESS,
                        (SELECT    INDCLIENTS.INDCLIENT_FATHER_NAME
                                || CHR (194)
                                || INDCLIENTS.INDCLIENT_MOTHER_NAME
                                || CHR (195)
                                || INDCLIENTS.INDCLIENT_SEX
                                || CHR (196)
                                || INDCLIENTS.INDCLIENT_BIRTH_DATE
                                || CHR (197)
                                || INDCLIENTS.INDCLIENT_TEL_RES
                                || CHR (198)
                                || INDCLIENTS.INDCLIENT_TEL_GSM
                                || CHR (199)
                                || INDCLIENTS.INDCLIENT_BIRTH_PLACE_CODE
                                || CHR (200)
                           FROM INDCLIENTS
                          WHERE INDCLIENTS.INDCLIENT_CODE =
                                   CLIENTS.CLIENTS_CODE)
                           INDCLIENTS_DATA,
                        CLIENTS.CLIENTS_PAN_GIR_NUM
                   FROM ACNTS,
                        IACLINK,
                        PRODUCTS,
                        ACTYPES,
                        CLIENTS
                  WHERE     ACNTS.ACNTS_ENTITY_NUM = 1
                        AND IACLINK.IACLINK_ENTITY_NUM = 1
                        AND ACNTS.ACNTS_BRN_CODE = IDX.BRANCH_CODE
                        AND ACNTS.ACNTS_INTERNAL_ACNUM =
                               IACLINK.IACLINK_INTERNAL_ACNUM
                        AND ACNTS.ACNTS_PROD_CODE = PRODUCTS.PRODUCT_CODE
                        AND ACNTS.ACNTS_AC_TYPE = ACTYPES.ACTYPE_CODE
                        AND ACNTS.ACNTS_CLIENT_NUM = CLIENTS.CLIENTS_CODE) TABLE_TEMP;

      COMMIT;
   END LOOP;
END;

/



SELECT count(DISTINCT  BR_CODE) FROM BRNACLIST ;  



CREATE TABLE CIB_GUARANTOR
(
   PERIOD           DATE,
   BRCODE           VARCHAR2 (6),
   BCODE            VARCHAR2 (1000),
   SFI_CODE         VARCHAR2 (1000),
   GFI_CODE         VARCHAR2 (1000),
   ACCOUNT_NUMBER   VARCHAR2 (13),
   G_TITLE          VARCHAR2 (10),
   G_BNAME          VARCHAR2 (1000),
   G_FTITLE         VARCHAR2 (10),
   G_FNAME          VARCHAR2 (1000),
   G_MTITLE         VARCHAR2 (10),
   G_MNAME          VARCHAR2 (1000),
   G_STITLE         VARCHAR2 (10),
   G_SNAME          VARCHAR2 (1000),
   SECTORTYPE       VARCHAR2 (100),
   SECTORCODE       VARCHAR2 (10),
   GENDER           VARCHAR2 (10),
   DOB              DATE,
   BIRTH_PLACE      VARCHAR2 (1000),
   BCNTY_CODE       VARCHAR2 (10),
   NID_NO           VARCHAR2 (1000),
   NID_NO_AIV       VARCHAR2 (1),
   TIN              VARCHAR2 (1000),
   E_TIN            VARCHAR2 (1000),
   PADDRESS         VARCHAR2 (1000),
   PPOSTCODE        VARCHAR2 (1000),
   PDISTNAME        VARCHAR2 (1000),
   PCNTY_CODE       VARCHAR2 (2),
   CADDRESS         VARCHAR2 (1000),
   CPOSTCODE        VARCHAR2 (1000),
   CDISTNAME        VARCHAR2 (1000),
   CCNTY_CODE       VARCHAR2 (2),
   BADDRESS         VARCHAR2 (1000),
   BPOSTCODE        VARCHAR2 (1000),
   BDISTNAME        VARCHAR2 (1000),
   BSCNTY_CODE      VARCHAR2 (2),
   ID_TYPE          VARCHAR2 (1000),
   ID_NO            VARCHAR2 (1000),
   ID_DATE          DATE,
   ID_CNTY          VARCHAR2 (2),
   PHONE_NO         VARCHAR2 (20),
   USER_ID          VARCHAR2 (1000),
   MACHINE_NAME     VARCHAR2 (1000),
   ENTRY_DATE       VARCHAR2 (1000),
   CHK              VARCHAR2 (1000),
   REMARKS          VARCHAR2 (1000)
);








INSERT INTO CIB_GUARANTOR 
   SELECT NULL PERIOD,
          SUBSTR (MBRN_BSR_CODE, 3, 4) BRCODE,
          NULL BCODE,
          NULL SFI_CODE,
          NULL GFI_CODE,
          FACNO (1, LNGUAR_INTERNAL_ACNUM) Account_Number,
          (SELECT TITLES_DESCN
             FROM TITLES
            WHERE TITLES_CODE = CLIENTS_TITLE_CODE)
             G_TITLE,
          CLIENTS_NAME G_NAME,
          NULL G_FTITLE,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDCLIENT_FATHER_NAME
                   FROM INDCLIENTS
                  WHERE INDCLIENT_CODE = CLIENTS_CODE)
          END
             G_FNAME,
          NULL G_MTITLE,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDCLIENT_MOTHER_NAME
                   FROM INDCLIENTS
                  WHERE INDCLIENT_CODE = CLIENTS_CODE)
          END
             G_MNAME,
          NULL G_STITLE,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDSPOUSE_SPOUSE_NAME
                   FROM INDCLIENTSPOUSE
                  WHERE INDSPOUSE_CLIENT_CODE = CLIENTS_CODE)
          END
             G_SNAME,
          DECODE (FN_GET_SECTORTYPE (CLIENTS_SEGMENT_CODE), '1', '1', '9')
             SECTORTYPE,
          CLIENTS_SEGMENT_CODE SECTORCODE,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDCLIENT_SEX
                   FROM INDCLIENTS
                  WHERE INDCLIENT_CODE = CLIENTS_CODE)
          END
             GENDER,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDCLIENT_BIRTH_DATE
                   FROM INDCLIENTS
                  WHERE INDCLIENT_CODE = CLIENTS_CODE)
          END
             DOB,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT LOCN_NAME
                   FROM INDCLIENTS, LOCATION
                  WHERE     INDCLIENT_CODE = CLIENTS_CODE
                        AND LOCN_CODE = INDCLIENT_BIRTH_PLACE_CODE)
          END
             BIRTH_PLACE,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT LOCN_CNTRY_CODE
                   FROM INDCLIENTS, LOCATION
                  WHERE     INDCLIENT_CODE = CLIENTS_CODE
                        AND LOCN_CODE = INDCLIENT_BIRTH_PLACE_CODE)
          END
             BCNTY_CODE,
          GET_NID_NUMBER (CLIENTS_CODE, 'NID') NID_NO,
          DECODE (GET_NID_NUMBER (CLIENTS_CODE, 'NID'), NULL, '0', '1')
             NID_NO_AIV,
          GET_NID_NUMBER (CLIENTS_CODE, 'TIN') TIN,
          NULL E_TIN,
          FN_GET_ADDRESS (CLIENTS_CODE, '02') PADDRESS,
          NULL PPOSTCODE,
          NULL PDISTNAME,
          'BD' PCNTY_CODE,
          FN_GET_ADDRESS (CLIENTS_CODE, '01') CADDRESS,
          NULL CPOSTCODE,
          NULL CDISTNAME,
          'BD' CCNTY_CODE,
          FN_GET_ADDRESS (CLIENTS_CODE, '04') BADDRESS,
          NULL BPOSTCODE,
          NULL BDISTNAME,
          'BD' BSCNTY_CODE,
          NULL ID_TYPE,
          NULL ID_NO,
          NULL ID_DATE,
          NULL ID_CNTY,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDCLIENT_TEL_GSM
                   FROM INDCLIENTS
                  WHERE INDCLIENT_CODE = CLIENTS_CODE)
          END
             PHONE_NO,
          NULL USER_ID,
          NULL MACHINE_NAME,
          NULL ENTRY_DATE,
          NULL CHK,
          NULL REMARKS
     FROM MBRN, CLIENTS, LNACGUAR
    WHERE     MBRN_ENTITY_NUM = 1
          AND LNGUAR_ENTITY_NUM = 1
          AND CLIENTS_CODE = LNGUAR_GUAR_CLIENT_CODE
          AND MBRN_CODE = CLIENTS_HOME_BRN_CODE
--AND CLIENTS_HOME_BRN_CODE = 1065
ORDER BY CLIENTS_HOME_BRN_CODE;

COMMIT ;


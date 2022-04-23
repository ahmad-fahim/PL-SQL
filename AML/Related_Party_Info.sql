CREATE TABLE AML_RELATEDPARTY
(
  RELATED_PARTY_TYPE  VARCHAR2(35 BYTE),
  SALUTATION          VARCHAR2(15 BYTE),
  FIRST_NAME          VARCHAR2(100 BYTE),
  LAST_NAME           VARCHAR2(24 BYTE),
  FATHER_NAME         VARCHAR2(50 BYTE),
  MOTHER_NAME         VARCHAR2(50 BYTE),
  CREATION_DATE       DATE,
  DOB                 DATE,
  BIRTH_PLACE         VARCHAR2(50 BYTE),
  GENDER              VARCHAR2(6 BYTE),
  ID_TYPE             VARCHAR2(1000 BYTE),
  ID_VALUE            VARCHAR2(4000 BYTE),
  ISSUE_COUNTRY       VARCHAR2(4000 BYTE),
  ADDRESSTYPE         VARCHAR2(1 BYTE),
  PRESENTADDRESS      VARCHAR2(4000 BYTE),
  PRESENT_CITY        VARCHAR2(50 BYTE),
  PRESENT_COUNTRY     VARCHAR2(50 BYTE),
  PERMANENT_ADDRESS   VARCHAR2(4000 BYTE),
  PERMANENT_CITY      VARCHAR2(50 BYTE),
  PERMANENT_COUNTRY   VARCHAR2(50 BYTE),
  NATIONALITY         VARCHAR2(50 BYTE),
  RESIDENCE           VARCHAR2(4000 BYTE),
  OCCUPATION          VARCHAR2(50 BYTE),
  PHONE               VARCHAR2(30 BYTE),
  MOBILE              VARCHAR2(15 BYTE),
  IS_SIGNATORY        VARCHAR2(1 BYTE),
  EMAIL               VARCHAR2(4000 BYTE),
  ACCOUNT_NUMBER      VARCHAR2(30 BYTE),
  CUSTOMERNUMBER      NUMBER(12)
)
TABLESPACE TBFES
RESULT_CACHE (MODE DEFAULT)
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


TRUNCATE TABLE AML_RELATEDPARTY ;

insert into AML_RELATEDPARTY
SELECT (SELECT CONNROLE_DESCN
          FROM CONNROLE
         WHERE CONNP_CONN_ROLE = CONNROLE_CODE)
          "Related Party Type",
       (SELECT TITLES_DESCN
          FROM TITLES
         WHERE TITLES_CODE = CLIENTS_TITLE_CODE)
          "Salutation",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT INDCLIENT_FIRST_NAME
                FROM INDCLIENTS
               WHERE INDCLIENT_CODE = CLIENTS_CODE)
          ELSE
             CLIENTS_NAME
       END
          "First Name",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT INDCLIENT_LAST_NAME
                FROM INDCLIENTS
               WHERE INDCLIENT_CODE = CLIENTS_CODE)
          ELSE
             NULL
       END
          "Last Name",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT INDCLIENT_FATHER_NAME
                FROM INDCLIENTS
               WHERE INDCLIENT_CODE = CLIENTS_CODE)
          ELSE
             NULL
       END
          "Father Name",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT INDCLIENT_MOTHER_NAME
                FROM INDCLIENTS
               WHERE INDCLIENT_CODE = CLIENTS_CODE)
          ELSE
             NULL
       END
          "Mother Name",
       CLIENTS_OPENING_DATE "Creation Date",
       CONNP_DATE_OF_BIRTH "DOB",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT LOCN_NAME
                FROM LOCATION
               WHERE LOCN_CODE = (SELECT INDCLIENT_BIRTH_PLACE_CODE
                                    FROM INDCLIENTS
                                   WHERE INDCLIENT_CODE = CLIENTS_CODE))
          ELSE
             NULL
       END
          "Birth Place",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             CASE
                WHEN (SELECT INDCLIENT_SEX
                        FROM INDCLIENTS
                       WHERE INDCLIENT_CODE = CLIENTS_CODE) = 'M'
                THEN
                   'Male'
                ELSE
                   'Female'
             END
          ELSE
             NULL
       END
          "Gender",
       TO_CHAR (
          (SELECT WM_CONCAT (UPPER (TRIM (PIDDOCS_PID_TYPE)))
             FROM PIDDOCS P
            WHERE     P.PIDDOCS_SOURCE_KEY = TO_CHAR (CLIENTS_CODE)
                  AND PIDDOCS_DOC_SL = 1))
          "Id Type",
       GET_NID_NUMBER (CLIENTS_CODE, 'NID') "Id Value",
       TO_CHAR (
          (SELECT WM_CONCAT (
                     (SELECT CNTRY_CODE
                        FROM CNTRY
                       WHERE CNTRY_CODE =
                                UPPER (
                                   TRIM (
                                      NVL (TRIM (PIDDOCS_ISSUE_CNTRY), 'BD')))))
             FROM PIDDOCS P
            WHERE     P.PIDDOCS_SOURCE_KEY = TO_CHAR (CLIENTS_CODE)
                  AND PIDDOCS_DOC_SL = 1))
          "Issue Country",
        "Present" "AddressType",
       (SELECT   SUBSTR( ADDRDTLS_ADDR1
               || ADDRDTLS_ADDR2
               || ADDRDTLS_ADDR3
               || ADDRDTLS_ADDR4
               || ADDRDTLS_ADDR5, 1,140)
          FROM ADDRDTLS
         WHERE     ADDRDTLS_INV_NUM = CLIENTS_ADDR_INV_NUM
               AND ADDRDTLS_ADDR_TYPE = '01')
          "PresentAddress",
       (SELECT LOCN_NAME
          FROM LOCATION
         WHERE LOCN_CODE =
                  (SELECT ADDRDTLS_LOCN_CODE
                     FROM ADDRDTLS
                    WHERE     ADDRDTLS_INV_NUM = CLIENTS_ADDR_INV_NUM
                          AND ADDRDTLS_ADDR_TYPE = '01'))
          "Present City",
       (SELECT CNTRY_CODE
          FROM CNTRY
         WHERE CNTRY_CODE =
                  (SELECT ADDRDTLS_CNTRY_CODE
                     FROM ADDRDTLS
                    WHERE     ADDRDTLS_INV_NUM = CLIENTS_ADDR_INV_NUM
                          AND ADDRDTLS_ADDR_TYPE = '01'))
          "Present Country",
       (SELECT  SUBSTR(  ADDRDTLS_ADDR1
               || ADDRDTLS_ADDR2
               || ADDRDTLS_ADDR3
               || ADDRDTLS_ADDR4
               || ADDRDTLS_ADDR5, 1,140)
          FROM ADDRDTLS
         WHERE     ADDRDTLS_INV_NUM = CLIENTS_ADDR_INV_NUM
               AND ADDRDTLS_ADDR_TYPE = '02')
          "Permanent Address",
       (SELECT LOCN_NAME
          FROM LOCATION
         WHERE LOCN_CODE =
                  (SELECT ADDRDTLS_LOCN_CODE
                     FROM ADDRDTLS
                    WHERE     ADDRDTLS_INV_NUM = CLIENTS_ADDR_INV_NUM
                          AND ADDRDTLS_ADDR_TYPE = '02'))
          "Permanent City",
       (SELECT CNTRY_NAME
          FROM CNTRY
         WHERE CNTRY_CODE =
                  (SELECT ADDRDTLS_CNTRY_CODE
                     FROM ADDRDTLS
                    WHERE     ADDRDTLS_INV_NUM = CLIENTS_ADDR_INV_NUM
                          AND ADDRDTLS_ADDR_TYPE = '02'))
          "Permanent Country",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT CNTRY_CODE
                FROM CNTRY
               WHERE CNTRY_CODE = (SELECT INDCLIENT_NATNL_CODE
                                     FROM INDCLIENTS
                                    WHERE INDCLIENT_CODE = CLIENTS_CODE))
          ELSE
             NULL
       END
          "Nationality",
       NULL "Residence",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT OCCUPATIONS_DESCN
                FROM OCCUPATIONS
               WHERE OCCUPATIONS_CODE =
                        (SELECT INDCLIENT_OCCUPN_CODE
                           FROM INDCLIENTS
                          WHERE INDCLIENT_CODE = CLIENTS_CODE))
          ELSE
             NULL
       END
          "Occupation",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT INDCLIENT_TEL_RES
                FROM INDCLIENTS
               WHERE INDCLIENT_CODE = CLIENTS_CODE)
          ELSE
             NULL
       END
          "Phone",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT INDCLIENT_TEL_GSM
                FROM INDCLIENTS
               WHERE INDCLIENT_CODE = CLIENTS_CODE)
          ELSE
             NULL
       END
          "Mobile",
       CONNROLE_FOR_AUTH_SIG "Is Signatory",
       CASE
          WHEN CLIENTS_TYPE_FLG = 'I'
          THEN
             (SELECT INDCLIENT_EMAIL_ADDR1 || INDCLIENT_EMAIL_ADDR2
                FROM INDCLIENTS
               WHERE INDCLIENT_CODE = CLIENTS_CODE)
          ELSE
             NULL
       END
          "Email",
       FACNO(ACNTS_ENTITY_NUM, ACNTS_INTERNAL_ACNUM) 
          "Account Number" ,
       ACNTS_CLIENT_NUM "CustomerNumber" 
  FROM CONNPINFO, CLIENTS, CONNROLE, ACNTS
 WHERE     CONNP_CLIENT_NUM = CLIENTS_CODE
       AND CONNROLE_CODE = CONNP_CONN_ROLE
       AND ACNTS_ENTITY_NUM = 1
       AND ACNTS_CONNP_INV_NUM = CONNP_INV_NUM ; 
       
	   
	   
insert into AML_RELATEDPARTY
SELECT (SELECT CONNROLE_DESCN
          FROM CONNROLE
         WHERE CONNP_CONN_ROLE = CONNROLE_CODE)
          "Related Party Type",
       NULL "Salutation",
       CONNP_CLIENT_NAME "First Name",
       NULL "Last Name",
       CONNP_NOMINEE_FATHER_NAME "Father Name",
       CONNP_NOMINEE_MOTHER_NAME "Mother Name",
       NULL "Creation Date",
       CONNP_DATE_OF_BIRTH "DOB",
       NULL "Birth Place",
       NULL "Gender",
       TO_CHAR (
          (SELECT WM_CONCAT (UPPER (TRIM (PIDDOCS_PID_TYPE)))
             FROM PIDDOCS P
            WHERE     P.PIDDOCS_INV_NUM = CONNP_PID_INV_NUM
                  AND PIDDOCS_DOC_SL = 1))
          "Id Type",
       TO_CHAR (
          (SELECT WM_CONCAT (UPPER (TRIM (PIDDOCS_DOCID_NUM)))
             FROM PIDDOCS P
            WHERE     P.PIDDOCS_INV_NUM = CONNP_PID_INV_NUM
                  AND PIDDOCS_DOC_SL = 1))
          "Id Value",
       TO_CHAR (
          (SELECT WM_CONCAT (
                     (SELECT CNTRY_NAME
                        FROM CNTRY
                       WHERE CNTRY_CODE =
                                UPPER (
                                   TRIM (
                                      NVL (TRIM (PIDDOCS_ISSUE_CNTRY), 'BD')))))
             FROM PIDDOCS P
            WHERE     P.PIDDOCS_INV_NUM = CONNP_PID_INV_NUM
                  AND PIDDOCS_DOC_SL = 1))
          "Issue Country",
          1 "AddressType",
         SUBSTR( CONNP_CLIENT_ADDR1
       || CONNP_CLIENT_ADDR2
       || CONNP_CLIENT_ADDR3
       || CONNP_CLIENT_ADDR4
       || CONNP_CLIENT_ADDR5, 1, 140)
          "PresentAddress",
       NULL "Present City",
       (SELECT CNTRY_NAME
          FROM CNTRY
         WHERE CNTRY_CODE = CONNP_CLIENT_CNTRY)
          "Present Country",
       NULL "Permanent Address",
       NULL "Permanent City",
       NULL "Permanent Country",
       (SELECT CNTRY_NAME
          FROM CNTRY
         WHERE CNTRY_CODE = CONNP_CLIENT_CNTRY)
          "Nationality",
       NULL "Residence",
       NULL "Occupation",
       CONNP_RES_TEL || CONNP_OFF_TEL "Phone",
       CONNP_GSM_NUM "Mobile",
       CONNROLE_FOR_AUTH_SIG "Is Signatory",
       CONNP_EMAIL_ADDR "Email",
       FACNO(ACNTS_ENTITY_NUM, ACNTS_INTERNAL_ACNUM) 
          "Account Number" ,
       ACNTS_CLIENT_NUM "CustomerNumber"
  FROM CONNPINFO, CONNROLE, ACNTS
 WHERE     CONNROLE_CODE = CONNP_CONN_ROLE
       AND NVL (CONNP_CLIENT_NUM, 0) = 0
       AND NVL (CONNP_INTERNAL_ACNUM, 0) = 0
       AND ACNTS_ENTITY_NUM = 1
       AND ACNTS_CONNP_INV_NUM = CONNP_INV_NUM;
	   
	   
	   
insert into AML_RELATEDPARTY
SELECT (SELECT CONNROLE_DESCN
          FROM CONNROLE
         WHERE CONNP_CONN_ROLE = CONNROLE_CODE)
          "Related Party Type",
       NULL "Salutation",
       CONNP_CLIENT_NAME "First Name",
       NULL "Last Name",
       CONNP_NOMINEE_FATHER_NAME "Father Name",
       CONNP_NOMINEE_MOTHER_NAME "Mother Name",
       NULL "Creation Date",
       CONNP_DATE_OF_BIRTH "DOB",
       NULL "Birth Place",
       NULL "Gender",
       TO_CHAR (
          (SELECT WM_CONCAT (UPPER (TRIM (PIDDOCS_PID_TYPE)))
             FROM PIDDOCS P
            WHERE     P.PIDDOCS_INV_NUM = CONNP_PID_INV_NUM
                  AND PIDDOCS_DOC_SL = 1))
          "Id Type",
       TO_CHAR (
          (SELECT WM_CONCAT (UPPER (TRIM (PIDDOCS_DOCID_NUM)))
             FROM PIDDOCS P
            WHERE     P.PIDDOCS_INV_NUM = CONNP_PID_INV_NUM
                  AND PIDDOCS_DOC_SL = 1))
          "Id Value",
       TO_CHAR (
          (SELECT WM_CONCAT (
                     (SELECT CNTRY_NAME
                        FROM CNTRY
                       WHERE CNTRY_CODE =
                                UPPER (
                                   TRIM (
                                      NVL (TRIM (PIDDOCS_ISSUE_CNTRY), 'BD')))))
             FROM PIDDOCS P
            WHERE     P.PIDDOCS_INV_NUM = CONNP_PID_INV_NUM
                  AND PIDDOCS_DOC_SL = 1))
          "Issue Country",
          1 "AddressType",
         SUBSTR( CONNP_CLIENT_ADDR1
       || CONNP_CLIENT_ADDR2
       || CONNP_CLIENT_ADDR3
       || CONNP_CLIENT_ADDR4
       || CONNP_CLIENT_ADDR5, 1, 140)
          "PresentAddress",
       NULL "Present City",
       (SELECT CNTRY_NAME
          FROM CNTRY
         WHERE CNTRY_CODE = CONNP_CLIENT_CNTRY)
          "Present Country",
       NULL "Permanent Address",
       NULL "Permanent City",
       NULL "Permanent Country",
       (SELECT CNTRY_NAME
          FROM CNTRY
         WHERE CNTRY_CODE = CONNP_CLIENT_CNTRY)
          "Nationality",
       NULL "Residence",
       NULL "Occupation",
       CONNP_RES_TEL || CONNP_OFF_TEL "Phone",
       CONNP_GSM_NUM "Mobile",
       CONNROLE_FOR_AUTH_SIG "Is Signatory",
       CONNP_EMAIL_ADDR "Email",
       FACNO(ACNTS_ENTITY_NUM, ACNTS_INTERNAL_ACNUM) 
          "Account Number" ,
       ACNTS_CLIENT_NUM "CustomerNumber"
  FROM CONNPINFO, CONNROLE, ACNTS
 WHERE     CONNROLE_CODE = CONNP_CONN_ROLE
       AND NVL (CONNP_CLIENT_NUM, 0) = 0
       AND NVL (CONNP_INTERNAL_ACNUM, 0) <> 0
       AND ACNTS_ENTITY_NUM = 1
       AND ACNTS_CONNP_INV_NUM = CONNP_INV_NUM ;
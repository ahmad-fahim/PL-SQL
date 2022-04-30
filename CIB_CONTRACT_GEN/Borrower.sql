CREATE TABLE CIB_BORROWER
(
   PERIOD           DATE,
   BRCODE           VARCHAR2 (6),
   SUB_TYPE         VARCHAR2 (1),
   INS_TYPE         VARCHAR2 (2),
   BCODE            VARCHAR2 (1000),
   SFI_CODE         VARCHAR2 (1000),
   ACCOUNT_NUMBER   VARCHAR2 (13),
   TITLE            VARCHAR2 (10),
   BNAME            VARCHAR2 (1000),
   FTITLE           VARCHAR2 (10),
   FNAME            VARCHAR2 (1000),
   MTITLE           VARCHAR2 (10),
   MNAME            VARCHAR2 (1000),
   STITLE           VARCHAR2 (10),
   SNAME            VARCHAR2 (1000),
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
   FADDRESS         VARCHAR2 (1000),
   FPOSTCODE        VARCHAR2 (1000),
   FDISTNAME        VARCHAR2 (1000),
   FCNTY_CODE       VARCHAR2 (2),
   ID_TYPE          VARCHAR2 (1000),
   ID_NO            VARCHAR2 (1000),
   ID_DATE          DATE,
   ID_CNTY          VARCHAR2 (2),
   PHONE_NO         VARCHAR2 (20),
   REG_NO           VARCHAR2 (1000),
   REG_DATE         DATE,
   SISTER_CON       VARCHAR2 (1000),
   GROUP_NAME       VARCHAR2 (1000),
   CRG_SCORE        VARCHAR2 (1000),
   CREDIT_RATE      NUMBER (18, 3),
   USER_ID          VARCHAR2 (1000),
   MACHINE_NAME     VARCHAR2 (1000),
   ENTRY_DATE       VARCHAR2 (1000),
   STAY_ORDER       VARCHAR2 (1000),
   BSCN             VARCHAR2 (1000),
   CHK              VARCHAR2 (1000),
   REMARKS          VARCHAR2 (1000),
   SUBJECT          VARCHAR2 (1000)
);




INSERT INTO CIB_BORROWER 
   SELECT NULL PERIOD,
          SUBSTR (MBRN_BSR_CODE, 3, 4) BRCODE,
          DECODE (CLIENTS_TYPE_FLG,  'C', 'C',  'J', 'I',  'I', 'P') SUB_TYPE,
          DECODE (CLIENTS_TYPE_FLG,  'C', '2',  'J', '1',  'I', '10')
             INS_TYPE,
          NULL BCODE,
          NULL SFI_CODE,
          IACLINK_ACTUAL_ACNUM Account_Number,
          (SELECT TITLES_DESCN
             FROM TITLES
            WHERE TITLES_CODE = CLIENTS_TITLE_CODE)
             TITLE,
          CLIENTS_NAME BNAME,
          NULL FTITLE,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDCLIENT_FATHER_NAME
                   FROM INDCLIENTS
                  WHERE INDCLIENT_CODE = CLIENTS_CODE)
          END
             FNAME,
          NULL MTITLE,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDCLIENT_MOTHER_NAME
                   FROM INDCLIENTS
                  WHERE INDCLIENT_CODE = CLIENTS_CODE)
          END
             MNAME,
          NULL STITLE,
          CASE
             WHEN CLIENTS_TYPE_FLG = 'I'
             THEN
                (SELECT INDSPOUSE_SPOUSE_NAME
                   FROM INDCLIENTSPOUSE
                  WHERE INDSPOUSE_CLIENT_CODE = CLIENTS_CODE)
          END
             SNAME,
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
          FN_GET_ADDRESS (CLIENTS_CODE, '04') FADDRESS,
          NULL FPOSTCODE,
          NULL FDISTNAME,
          'BD' FCNTY_CODE,
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
          NULL REG_NO,
          NULL REG_DATE,
          NULL SISTER_CON,
          NULL GROUP_NAME,
          NULL CRG_SCORE,
          NULL CREDIT_RATE,
          NULL USER_ID,
          NULL MACHINE_NAME,
          NULL ENTRY_DATE,
          NULL STAY_ORDER,
          NULL BSCN,
          NULL CHK,
          NULL REMARKS,
          NULL SUBJECT
     FROM ACNTS,
          IACLINK,
          PRODUCTS,
          MBRN,
          CLIENTS
    WHERE     IACLINK_ENTITY_NUM = 1
          AND IACLINK_INTERNAL_ACNUM = ACNTS_INTERNAL_ACNUM
          AND ACNTS_ENTITY_NUM = 1
          --AND ACNTS_BRN_CODE = 1065
          AND PRODUCT_CODE = ACNTS_PROD_CODE
          AND PRODUCT_FOR_LOANS = 1
          AND MBRN_ENTITY_NUM = 1
          AND MBRN_CODE = ACNTS_BRN_CODE
          AND ACNTS_CLIENT_NUM = CLIENTS_CODE
          ORDER BY ACNTS_BRN_CODE;



CREATE OR REPLACE FUNCTION FN_GET_SECTORTYPE (P_SECTOR VARCHAR2)
   RETURN VARCHAR2
IS
   V_RETURN_SECTYPE   VARCHAR2 (100);
   V_PARENT_SECTYPE   VARCHAR2 (100);
BEGIN
   IF P_SECTOR IN ('1', '2')
   THEN
      RETURN P_SECTOR;
   ELSE
      SELECT SEGMENTS_PARENT_SEC_CODE
        INTO V_PARENT_SECTYPE
        FROM SEGMENTS
       WHERE SEGMENTS_CODE = P_SECTOR;

      V_RETURN_SECTYPE := FN_GET_SECTORTYPE (V_PARENT_SECTYPE);
   END IF;

   RETURN V_RETURN_SECTYPE;
END FN_GET_SECTORTYPE;



CREATE OR REPLACE FUNCTION GET_NID_NUMBER (P_CLIENT_CODE    NUMBER,
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
/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE "PKG_RIBRADV"
IS
   TYPE TY_TEMP IS RECORD
   (
      ORIG_TRAN_FIRST_AUTH_BY     VARCHAR2 (150),
      IBRADVICES_RESP_ON_DATE     DATE,
      RESP_ENTRY                  VARCHAR2 (150),
      RESP_AUTHER                 VARCHAR2 (150),
      RESP_TRAN_FIRST_AUTH_BY     VARCHAR2 (150),
      ORG_DD_DATE                 DATE,
      ORG_DD_PFX                  VARCHAR2 (6),
      ORG_DD_NUM                  NUMBER (15),
      TRAN_ENTD_BY1               VARCHAR2 (150),
      TRAN_AUTH_BY                VARCHAR2 (150),
      TTMTISS_REMIT_CODE          VARCHAR2 (6),
      TTMTISSDTL_BENEF_NAME       VARCHAR2 (50),
      TTMTISSDTL_BENEF_AC_NUM     VARCHAR2 (100),
      DDPOISS_REMITCODE           VARCHAR2 (6),
      DDPOISSDTL_BENEFNAME1       VARCHAR2 (50),
      DDPOISSDTL_BENEFNAME2       VARCHAR2 (50),
      DDPOISSDTL_ON_ACOF          VARCHAR2 (100),
      DDPOISSDTL_INST_NUMPFX      VARCHAR2 (6),
      DDPOISSDTL_INST_NUM         NUMBER (15),
      IBRADVICES_ORIG_BRNCODE     NUMBER (6),
      IBRADVICES_IBRCODE          VARCHAR2 (2),
      IBRADVICES_YEAR             NUMBER (4),
      IBRADVICES_ADVICENUM        NUMBER (6),
      IBRADVICES_CONTRA_BRNCODE   NUMBER (6),
      IBRADVICES_ADVICEDATE       DATE,
      IBRADVICES_PARTICLRS        VARCHAR2 (35),
      IBRADVICES_SOURCE_REFNUM    VARCHAR2 (100),
      IBRADVICES_TRAN_CURRCODE    VARCHAR2 (3),
      IBRADVICES_TRAN_AMOUNT      NUMBER (18, 3),
      IBRADVICES_TRAN_BATCH_NUM   NUMBER (7),
      IBRADVICES_TRAN_AMOUNT1     VARCHAR2 (100),
      WORD                        VARCHAR2 (1000),
      TRANBAT_SOURCEKEY           VARCHAR2 (100),
      TRAN_ENTDBY                 VARCHAR2 (8),
      TRANBATCH_NUMBER            NUMBER (7),
      TRANBATCH_SL_NUM            NUMBER (6),
      TRAN_DBCR_FLG               CHAR (1),
      TRANGLACC_CODE              VARCHAR2 (15),
      TRANNARR_DTL1               VARCHAR2 (35),
      TRANNARR_DTL2               VARCHAR2 (35),
      TRANNARR_DTL3               VARCHAR2 (35),
      TRANBATNARR_DTL1            VARCHAR2 (35),
      TRANBATNARR_DTL2            VARCHAR2 (35),
      TRANBATNARR_DTL3            VARCHAR2 (35),
      IBTRAN_CODE                 VARCHAR2 (2),
      IBTRAN_CONCDESCN            VARCHAR2 (15),
      IBTRAN_ADV_PRINTREQD        CHAR (1),
      MBRNNAME                    VARCHAR2 (50),
      originatin_branchname       VARCHAR2 (50),
      responding_branchname       VARCHAR2 (50),
      INS_NAME_OFBANK             VARCHAR2 (100),
      EXTGL_EXT_HEADDESCN         VARCHAR2 (50)
   );

   TYPE TY_TMP IS TABLE OF TY_TEMP;

   FUNCTION FN_GETIBRADV (P_BRN_CODE      IN NUMBER,
                          P_TRAN_DATE     IN VARCHAR2,
                          P_TRANBAT_NUM   IN NUMBER,
                          P_ADV_ON_BRN    IN NUMBER,
                          RTYPE           IN VARCHAR2,
                          whereClause     IN VARCHAR2)
        --RETURN VARCHAR2;
      RETURN TY_TMP PIPELINED;
END PKG_RIBRADV;
/


/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE BODY "PKG_RIBRADV"
IS
   PRINT          PKG_RIBRADV.TY_TEMP;
   W_SQL          VARCHAR2 (32000);
   W_SQL3         VARCHAR2 (32000);
   SELECT_QUERY   VARCHAR2 (32000);
   W_YEAR         NUMBER (10);
   W_FOR_DATE     DATE;
   EDDPOCAN       VARCHAR (200);
   WHERE_CLAUSE_TYPE VARCHAR (200);
   WHERE_CLAUSE   VARCHAR2 (32000);
   FUNCTION GET_SQL_QUERY (WHERE_CLAUSE VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION FN_GETIBRADV (P_BRN_CODE      IN NUMBER,
                          P_TRAN_DATE     IN VARCHAR2,
                          P_TRANBAT_NUM   IN NUMBER,
                          P_ADV_ON_BRN    IN NUMBER,
                          RTYPE           IN VARCHAR2,
                          whereClause     IN VARCHAR2)
      RETURN TY_TMP       PIPELINED
   --RETURN VARCHAR2
   IS
      TYPE RR_TABLEA IS RECORD
      (
         TMP_ORIG_TRAN_FIRST_AUTH_BY    VARCHAR2 (150),
         TMP_IBRADVICES_RESP_ON_DATE DATE,
         TMP_RESP_ENTRY               VARCHAR2 (150),
         TMP_RESP_AUTHER               VARCHAR2 (150),
         TMP_TRAN_FIRST_AUTH_BY               VARCHAR2 (150),         
         TMP_ORG_DD_DATE                 DATE,
         TMP_ORG_DD_PFX                  VARCHAR2 (6),
         TMP_ORG_DD_NUM                  NUMBER (15),
         TMP_TRAN_ENTD_BY1               VARCHAR2 (150),
         TMP_TRAN_AUTH_BY                VARCHAR2 (150),
         
         TMP_TTMTISS_REMIT_CODE          VARCHAR2 (6),
         TMP_TTMTISSDTL_BENEF_NAME       VARCHAR2 (50),
         TMP_TTMTISSDTL_BENEF_AC_NUM     VARCHAR2 (100),
         TMP_DDPOISS_REMITCODE           VARCHAR2 (6),
         TMP_DDPOISSDTL_BENEFNAME1       VARCHAR2 (50),
         TMP_DDPOISSDTL_BENEFNAME2       VARCHAR2 (65),
         TMP_DDPOISSDTL_ON_ACOF          VARCHAR2 (100),
         TMP_DDPOISSDTL_INST_NUMPFX      VARCHAR2 (6),
         TMP_DDPOISSDTL_INST_NUM         NUMBER (15),
         TMP_IBRADVICES_ORIG_BRNCODE     NUMBER (6),
         TMP_IBRADVICES_IBRCODE          VARCHAR2 (2),
         TMP_IBRADVICES_YEAR             NUMBER (4),
         TMP_IBRADVICES_ADVICENUM        NUMBER (6),
         TMP_IBRADVICES_CONTRA_BRNCODE   NUMBER (6),
         TMP_IBRADVICES_ADVICEDATE       DATE,
         TMP_IBRADVICES_PARTICLRS        VARCHAR2 (50),
         TMP_IBRADVICES_SOURCE_REFNUM    VARCHAR2 (100),
         TMP_IBRADVICES_TRAN_CURRCODE    VARCHAR2 (3),
         TMP_IBRADVICES_TRAN_AMOUNT      NUMBER (18, 3),
         TMP_IBRADVICES_TRAN_BATCH_NUM   NUMBER (7),
         TMP_IBRADVICES_TRAN_AMOUNT1     VARCHAR2 (100),
         TMP_WORD                        VARCHAR2 (1000),
         TMP_TRANBAT_SOURCEKEY           VARCHAR2 (200),
         TMP_TRAN_ENTDBY                 VARCHAR2 (8),
         TMP_TRANBATCH_NUMBER            NUMBER (7),
         TMP_TRANBATCH_SL_NUM            NUMBER (6),
         TMP_TRAN_DBCR_FLG               CHAR (1),
         TMP_TRANGLACC_CODE              VARCHAR2 (15),
         TMP_TRANNARR_DTL1               VARCHAR2 (35),
         TMP_TRANNARR_DTL2               VARCHAR2 (35),
         TMP_TRANNARR_DTL3               VARCHAR2 (35),
         TMP_TRANBATNARR_DTL1            VARCHAR2 (35),
         TMP_TRANBATNARR_DTL2            VARCHAR2 (35),
         TMP_TRANBATNARR_DTL3            VARCHAR2 (35),
         TMP_IBTRAN_CODE                 VARCHAR2 (2),
         TMP_IBTRAN_CONCDESCN            VARCHAR2 (15),
         TMP_IBTRAN_ADV_PRINTREQD        CHAR (1),
         TMP_MBRNNAME                    VARCHAR2 (50),
         TMP_originatin_branchname       VARCHAR2 (50),
         TMP_responding_branchname       VARCHAR2 (50),
         TMP_INS_NAME_OFBANK             VARCHAR2 (100),
         TMP_EXTGL_EXT_HEADDESCN         VARCHAR2 (50)
      );

      TYPE TABLEA IS TABLE OF RR_TABLEA
         INDEX BY PLS_INTEGER;

      
      
      V_TEMP_TABLEA   TABLEA;
   BEGIN
      WHERE_CLAUSE_TYPE:='''';
      WHERE_CLAUSE:= whereClause;
      IF WHERE_CLAUSE != 'NODATA'
      THEN        
        WHERE_CLAUSE_TYPE:= SUBSTR (WHERE_CLAUSE, 1, 4);
        
        WHERE_CLAUSE:= SUBSTR (WHERE_CLAUSE, 6, LENGTH(WHERE_CLAUSE));   
        W_SQL3 := GET_SQL_QUERY (WHERE_CLAUSE);                                   
      END IF;



      W_FOR_DATE := TO_DATE (P_TRAN_DATE, 'DD-MM-YYYY');
      W_YEAR := TO_NUMBER (TO_CHAR (W_FOR_DATE, 'YYYY'));

      EDDPOCAN := 'EDDPOCAN';
      W_SQL :=
            'SELECT ORIG_TRAN_FIRST_AUTH_BY,IBRADVICES_RESP_ON_DATE,
FN_GET_USER_NAME(IBRADVICES_ORIG_BRN_CODE,IBRADVICES_CONTRA_BRN_CODE,IBRADVICES_RESP_ON_DATE,IBRADVICES_RESP_IN_BATCH_NUM,IBRADVICES_RESP_IN_BATCH_SL,''TRAN_ENTD_BY'') as RESP_ENTRY,
FN_GET_USER_NAME(IBRADVICES_ORIG_BRN_CODE,IBRADVICES_CONTRA_BRN_CODE,IBRADVICES_RESP_ON_DATE,IBRADVICES_RESP_IN_BATCH_NUM,IBRADVICES_RESP_IN_BATCH_SL,''TRAN_AUTH_BY'') as RESP_AUTHER,
FN_GET_USER_NAME(IBRADVICES_ORIG_BRN_CODE,IBRADVICES_CONTRA_BRN_CODE,IBRADVICES_RESP_ON_DATE,IBRADVICES_RESP_IN_BATCH_NUM,IBRADVICES_RESP_IN_BATCH_SL,''TRAN_FIRST_AUTH_BY'') as TRAN_FIRST_AUTH_BY,
ORG_DD_DATE,ORG_DD_PFX, ORG_DD_NUM,TRAN_ENTD_BY1,TRAN_AUTH_BY,TTMTISS_REMIT_CODE,TTMTISSDTL_BENEF_NAME,TTMTISSDTL_BENEF_AC_NUM,
       DDPOISS_REMIT_CODE,DDPOISSDTL_BENEF_NAME1,DDPOISSDTL_BENEF_NAME2,DDPOISSDTL_ON_AC_OF,DDPOISSDTL_INST_NUM_PFX,
           DECODE(DDPOISSDTL_INST_NUM,null,0,DDPOISSDTL_INST_NUM)DDPOISSDTL_INST_NUM,IBRADVICES_ORIG_BRN_CODE,IBRADVICES_IBR_CODE,IBRADVICES_YEAR,IBRADVICES_ADVICE_NUM,IBRADVICES_CONTRA_BRN_CODE,
           IBRADVICES_ADVICE_DATE,IBRADVICES_PARTICULARS,IBRADVICES_SOURCE_REF_NUM,IBRADVICES_TRAN_CURR_CODE,IBRADVICES_TRAN_AMOUNT,
           IBRADVICES_TRAN_BATCH_NUM,IBRADVICES_TRAN_AMOUNT1,WORD,TRANBAT_SOURCE_KEY,TRAN_ENTD_BY,a.TRAN_BATCH_NUMBER,a.TRAN_BATCH_SL_NUM ,
           TRAN_DB_CR_FLG,TRAN_GLACC_CODE,TRAN_NARR_DTL1,TRAN_NARR_DTL2,TRAN_NARR_DTL3,TRANBAT_NARR_DTL1,TRANBAT_NARR_DTL2,TRANBAT_NARR_DTL3,
           IBTRAN_CODE,IBTRAN_CONC_DESCN,IBTRAN_ADV_PRINT_REQD,MBRN_NAME,originatin_branch_name,responding_branch_name,
           INS_NAME_OF_BANK,EXTGL_EXT_HEAD_DESCN
         FROM
         (SELECT IBRADVICES_RESP_IN_BATCH_NUM,IBRADVICES_RESP_ON_DATE,IBRADVICES_RESP_IN_BATCH_SL,
         tran_date_of_tran,TRAN_brn_code,IBRADVICES_ORIG_BRN_CODE,IBRADVICES_IBR_CODE,IBRADVICES_YEAR,IBRADVICES_ADVICE_NUM,IBRADVICES_CONTRA_BRN_CODE,
          
          IBRADVICES_ADVICE_DATE,IBRADVICES_PARTICULARS,IBRADVICES_SOURCE_REF_NUM,
          IBRADVICES_TRAN_CURR_CODE,IBRADVICES_TRAN_AMOUNT,IBRADVICES_TRAN_BATCH_NUM,sp_getFormat( PKG_ENTITY.FN_GET_ENTITY_CODE,IBRADVICES_TRAN_CURR_CODE,IBRADVICES_TRAN_AMOUNT) AS IBRADVICES_TRAN_AMOUNT1,
          SUBSTR(SP_AMOUNTTOWORD.SP_AMOUNT_TO_WORD( PKG_ENTITY.FN_GET_ENTITY_CODE,IBRADVICES_TRAN_CURR_CODE,IBRADVICES_TRAN_AMOUNT), LENGTH(IBRADVICES_TRAN_CURR_CODE) + 2) AS WORD,
          DECODE(IBRADVICES_TRAN_BATCH_NUM,0,'
         || CHR (39)
         || CHR (39)
         || ',TRANBAT_SOURCE_KEY) TRANBAT_SOURCE_KEY,TRAN_ENTD_BY,TRAN_BATCH_NUMBER,TRAN_BATCH_SL_NUM ,TRAN_DB_CR_FLG,
          TRAN_GLACC_CODE,TRAN_NARR_DTL1,TRAN_NARR_DTL2,TRAN_NARR_DTL3,TRANBAT_NARR_DTL1,TRANBAT_NARR_DTL2,TRANBAT_NARR_DTL3,IBTRAN_CODE TRAN_CODE,
          IBTRAN_CONC_DESCN,IBTRAN_CODE,IBTRAN_ADV_PRINT_REQD,
          (SELECT USER_NAME FROM USERS WHERE USER_ID=TRAN_ENTD_BY) AS TRAN_ENTD_BY1,
          (SELECT USER_NAME FROM USERS WHERE USER_ID=TRAN_AUTH_BY) AS TRAN_AUTH_BY,
          (SELECT USER_NAME FROM USERS WHERE USER_ID=TRAN_FIRST_AUTH_BY) AS ORIG_TRAN_FIRST_AUTH_BY,
          (SELECT MBRN_NAME FROM mbrn WHERE MBRN_CODE=IBRADVICES_ORIG_BRN_CODE) AS MBRN_NAME,
          (SELECT MBRN_NAME FROM mbrn WHERE MBRN_CODE=IBRADVICES_ORIG_BRN_CODE) AS originatin_branch_name,
          (SELECT MBRN_NAME FROM mbrn WHERE MBRN_CODE=IBRADVICES_CONTRA_BRN_CODE) AS responding_branch_name,
          ( SELECT INS_NAME_OF_BANK FROM INSTALL WHERE INS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE ) AS INS_NAME_OF_BANK,
          (SELECT EXTGL_EXT_HEAD_DESCN FROM EXTGL WHERE EXTGL_ACCESS_CODE =TRAN_GLACC_CODE) AS EXTGL_EXT_HEAD_DESCN
          FROM tran'
         || W_YEAR
         || ' TRAN
          INNER JOIN IBRADVICES i';
          IF ((WHERE_CLAUSE = 'NODATA') or (WHERE_CLAUSE_TYPE = 'ORIG' )) THEN 
             W_SQL :=      W_SQL || ' ON tran.TRAN_BATCH_NUMBER =i.ibradvices_tran_batch_num
                           AND tran.tran_date_of_tran=i.ibradvices_advice_date
                           AND tran.TRAN_BATCH_SL_NUM=i.IBRADVICES_TRAN_BATCH_SL
                           and tran.tran_brn_code=i.IBRADVICES_ORIG_BRN_CODE';
          ELSE IF ((WHERE_CLAUSE = 'NODATA') or (WHERE_CLAUSE_TYPE = 'RESP' )) THEN 
            W_SQL :=        W_SQL || '  ON tran.TRAN_BATCH_NUMBER = i.IBRADVICES_RESP_IN_BATCH_NUM  
                            AND tran.tran_date_of_tran = i.IBRADVICES_RESP_ON_DATE
                            AND tran.TRAN_BATCH_SL_NUM = i.IBRADVICES_RESP_IN_BATCH_SL 
                            AND tran.tran_brn_code = i.IBRADVICES_CONTRA_BRN_CODE';
          ELSE
            W_SQL :=        W_SQL || '  ON ((tran.TRAN_BATCH_NUMBER =i.ibradvices_tran_batch_num
                           AND tran.tran_date_of_tran=i.ibradvices_advice_date
                           AND tran.TRAN_BATCH_SL_NUM=i.IBRADVICES_TRAN_BATCH_SL
                           and tran.tran_brn_code=i.IBRADVICES_ORIG_BRN_CODE)
               or (tran.TRAN_BATCH_NUMBER = i.IBRADVICES_RESP_IN_BATCH_NUM  
                            AND tran.tran_date_of_tran = i.IBRADVICES_RESP_ON_DATE
                            AND tran.TRAN_BATCH_SL_NUM = i.IBRADVICES_RESP_IN_BATCH_SL 
                            AND tran.tran_brn_code = i.IBRADVICES_CONTRA_BRN_CODE ) )';
          END IF;
          END IF;
          
          
           W_SQL := W_SQL || ' 
          INNER JOIN TRANBAT'
         || W_YEAR
         || ' tb
          ON tran.TRAN_BATCH_NUMBER =tb.tranbat_batch_number
          AND tran.tran_date_of_tran=tb.tranbat_date_of_tran
          and tran.tran_brn_code=tb.TRANBAT_BRN_CODE
          AND tran.TRAN_ENTITY_NUM=TB.TRANBAT_ENTITY_NUM  
          INNER JOIN IBTRANCD IBTRANCD
          ON IBRADVICES_IBR_CODE      = IBTRAN_CODE
          WHERE tran.tran_date_of_tran='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39)
         || '
          AND IBTRAN_ADV_PRINT_REQD=''1''
          AND IBRADVICES_ENTITY_NUM   = 1 
          AND TRAN_ENTITY_NUM         = 1
          AND TRANBAT_ENTITY_NUM      = 1';
      
      W_SQL :=
            W_SQL || 'AND tran_brn_code = ' || P_BRN_CODE ;
    

      IF P_ADV_ON_BRN IS NOT NULL
      THEN
         W_SQL :=
            W_SQL || ' AND i.IBRADVICES_CONTRA_BRN_CODE= ' || P_ADV_ON_BRN;
      END IF;

      W_SQL :=
            W_SQL
         || ' ) a
          INNER JOIN
          (SELECT IBRADVICES_RESP_IN_BATCH_NUM as IBRADVICES_RESP_IN_BATCH_NUM1,IBRADVICES_RESP_ON_DATE as res_date,IBRADVICES_RESP_IN_BATCH_SL as resp_sl,TRAN_BATCH_NUMBER,tran_date_of_tran,TRAN_BATCH_SL_NUM,TRAN_brn_code,DDPOISS_REMIT_CODE,DDPOISSDTL_BENEF_NAME1, DDPOISSDTL_BENEF_NAME2,
           DDPOISSDTL_ON_AC_OF,DDPOISSDTL_INST_NUM_PFX,DDPOISSDTL_INST_NUM,

  null AS ORG_DD_DATE,
'
         || CHR (39)
         || CHR (39)
         || ' AS ORG_DD_PFX,  
0 AS ORG_DD_NUM  
           
           
           FROM tran'
         || W_YEAR
         || ' TRAN
           LEFT JOIN IBRADVICES i';
           IF ((WHERE_CLAUSE = 'NODATA') or (WHERE_CLAUSE_TYPE = 'ORIG' )) THEN 
             W_SQL :=      W_SQL || ' ON tran.TRAN_BATCH_NUMBER =i.ibradvices_tran_batch_num
                           AND tran.tran_date_of_tran=i.ibradvices_advice_date
                           AND tran.TRAN_BATCH_SL_NUM=i.IBRADVICES_TRAN_BATCH_SL
                           and tran.tran_brn_code=i.IBRADVICES_ORIG_BRN_CODE';
          ELSE IF ((WHERE_CLAUSE = 'NODATA') or (WHERE_CLAUSE_TYPE = 'RESP' )) THEN 
            W_SQL :=        W_SQL || '  ON tran.TRAN_BATCH_NUMBER = i.IBRADVICES_RESP_IN_BATCH_NUM  
                            AND tran.tran_date_of_tran = i.IBRADVICES_RESP_ON_DATE
                            AND tran.TRAN_BATCH_SL_NUM = i.IBRADVICES_RESP_IN_BATCH_SL 
                            AND tran.tran_brn_code = i.IBRADVICES_CONTRA_BRN_CODE';
          ELSE
            W_SQL :=        W_SQL || '  ON ((tran.TRAN_BATCH_NUMBER =i.ibradvices_tran_batch_num
                           AND tran.tran_date_of_tran=i.ibradvices_advice_date
                           AND tran.TRAN_BATCH_SL_NUM=i.IBRADVICES_TRAN_BATCH_SL
                           and tran.tran_brn_code=i.IBRADVICES_ORIG_BRN_CODE)
               or (tran.TRAN_BATCH_NUMBER = i.IBRADVICES_RESP_IN_BATCH_NUM  
                            AND tran.tran_date_of_tran = i.IBRADVICES_RESP_ON_DATE
                            AND tran.TRAN_BATCH_SL_NUM = i.IBRADVICES_RESP_IN_BATCH_SL 
                            AND tran.tran_brn_code = i.IBRADVICES_CONTRA_BRN_CODE ) )';
          END IF;
          END IF;
          
           W_SQL :=        W_SQL || '   LEFT JOIN DDPOISS
           ON DDPOISS.POST_TRAN_BATCH_NUM=i.IBRADVICES_TRAN_BATCH_NUM
           AND i.IBRADVICES_ADVICE_DATE  =DDPOISS_ISSUE_DATE
           LEFT JOIN DDPOISSDTL
           ON DDPOISS_REMIT_CODE         =DDPOISSDTL_REMIT_CODE
           AND DDPOISS_ENTITY_NUM        =DDPOISSDTL_ENTITY_NUM
           AND DDPOISS_BRN_CODE          =DDPOISSDTL_BRN_CODE
           AND DDPOISS_REMIT_CODE        =DDPOISSDTL_REMIT_CODE
           AND DDPOISS_ISSUE_DATE        =DDPOISSDTL_ISSUE_DATE
           AND DDPOISS_DAY_SL            =DDPOISSDTL_DAY_SL';
          
           IF ((WHERE_CLAUSE = 'NODATA') OR (WHERE_CLAUSE_TYPE = 'ORIG' ))
          THEN
             W_SQL :=      W_SQL || ' WHERE (i.IBRADVICES_ADVICE_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
            ELSE  IF ((WHERE_CLAUSE = 'NODATA') OR (WHERE_CLAUSE_TYPE = 'RESP' ))
          THEN
             W_SQL :=      W_SQL || ' WHERE (i.IBRADVICES_RESP_ON_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
            ELSE
            W_SQL :=        W_SQL || '  WHERE (i.IBRADVICES_ADVICE_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
           W_SQL :=        W_SQL || '  or i.IBRADVICES_RESP_ON_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
          
          END IF;
            END IF;
            
          W_SQL :=      W_SQL || ' ) and i.IBRADVICES_PARTICULARS <> '
         || CHR (39)
         || EDDPOCAN
         || CHR (39)
         
         || '
            AND tran_brn_code = ' || P_BRN_CODE || '
                     
           union all
           
            SELECT  IBRADVICES_RESP_IN_BATCH_NUM,IBRADVICES_RESP_ON_DATE,IBRADVICES_RESP_IN_BATCH_SL,TRAN_BATCH_NUMBER,tran_date_of_tran,TRAN_BATCH_SL_NUM,TRAN_brn_code ,DDPOCAN.DDPOCAN_REMIT_CODE AS CAN_REMIT_CODE,
            FN_GET_BENEF(DDPOcan_ENTITY_NUM,DDPOcan_BRN_CODE,DDPOcan_REMIT_CODE,
            DECODE(DDPOcan_ISS_DATE,NULL,DDPODUPISS_ISSUE_DATE,DDPOcan_ISS_DATE),
            DECODE(DDPODUPISS_ORIGINAL_LEAF_PFX,NULL,ddpocan_leaf_pfx,DDPODUPISS_ORIGINAL_LEAF_PFX),
            DECODE(DDPODUPISS_ORIGINAL_LEAF_NUM,NULL,DDPOCAN_LEAF_NUMBER,DDPODUPISS_ORIGINAL_LEAF_NUM)
            ) AS BENF1,'
         || CHR (39)
         || CHR (39)
         || ' as BENF2, 
            '
         || CHR (39)
         || CHR (39)
         || ' AS CAN_AC_NUM,
            DDPOcan.ddpocan_leaf_pfx AS CAN_DD_PFX,DDPOCAN.DDPOCAN_LEAF_NUMBER AS CAN_DD_NUM, 
            DDPODUPISS_ISSUE_DATE AS ORG_DD_DATE,
            DDPODUPISS_ORIGINAL_LEAF_PFX AS ORG_DD_PFX,  
            DDPODUPISS_ORIGINAL_LEAF_NUM AS ORG_DD_NUM  
            FROM tran'
         || W_YEAR
         || '  TRAN1
           inner JOIN IBRADVICES ibr ';
            IF ((WHERE_CLAUSE = 'NODATA') or (WHERE_CLAUSE_TYPE = 'ORIG' )) THEN 
             W_SQL :=      W_SQL || ' ON TRAN1.TRAN_BATCH_NUMBER =ibr.ibradvices_tran_batch_num
                           AND TRAN1.tran_date_of_tran=ibr.ibradvices_advice_date
                           AND TRAN1.TRAN_BATCH_SL_NUM=ibr.IBRADVICES_TRAN_BATCH_SL
                           and TRAN1.tran_brn_code=ibr.IBRADVICES_ORIG_BRN_CODE';
          ELSE IF ((WHERE_CLAUSE = 'NODATA') or (WHERE_CLAUSE_TYPE = 'RESP' )) THEN 
            W_SQL :=        W_SQL || '  ON TRAN1.TRAN_BATCH_NUMBER = ibr.IBRADVICES_RESP_IN_BATCH_NUM  
                            AND TRAN1.tran_date_of_tran = ibr.IBRADVICES_RESP_ON_DATE
                            AND TRAN1.TRAN_BATCH_SL_NUM = ibr.IBRADVICES_RESP_IN_BATCH_SL 
                            AND TRAN1.tran_brn_code = ibr.IBRADVICES_CONTRA_BRN_CODE';
          ELSE
            W_SQL :=        W_SQL || '  ON ((TRAN1.TRAN_BATCH_NUMBER =ibr.ibradvices_tran_batch_num
                           AND TRAN1.tran_date_of_tran=ibr.ibradvices_advice_date
                           AND TRAN1.TRAN_BATCH_SL_NUM=ibr.IBRADVICES_TRAN_BATCH_SL
                           and TRAN1.tran_brn_code=ibr.IBRADVICES_ORIG_BRN_CODE)
               or (TRAN1.TRAN_BATCH_NUMBER = ibr.IBRADVICES_RESP_IN_BATCH_NUM  
                            AND TRAN1.tran_date_of_tran = ibr.IBRADVICES_RESP_ON_DATE
                            AND TRAN1.TRAN_BATCH_SL_NUM = ibr.IBRADVICES_RESP_IN_BATCH_SL 
                            AND TRAN1.tran_brn_code = ibr.IBRADVICES_CONTRA_BRN_CODE ) )';
          END IF;
          END IF;
           
           W_SQL :=        W_SQL || '   
           inner JOIN DDPOcan DDPOcan
           ON 
           DDPOcan.POST_TRAN_BATCH_NUM=ibr.IBRADVICES_TRAN_BATCH_NUM
           AND 
           ibr.IBRADVICES_ADVICE_DATE  =DDPOcan_CANC_DATE
           left JOIN DDPODUPISS
           ON DDPOcan_REMIT_CODE         =DDPODUPISS_REMIT_CODE
           AND DDPOcan_ENTITY_NUM        =DDPODUPISS_ENTITY_NUM
           AND DDPOcan_BRN_CODE          =DDPODUPISS_BRN_CODE
           and DDPOcan.ddpocan_leaf_pfx=DDPODUPISS_INST_NUM_pfx
           and DDPOCAN_LEAF_NUMBER  = DDPODUPISS_INST_NUM';
           
           IF ((WHERE_CLAUSE = 'NODATA') OR (WHERE_CLAUSE_TYPE = 'ORIG' ))
          THEN
             W_SQL :=      W_SQL || ' WHERE (ibr.IBRADVICES_ADVICE_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
            ELSE  IF ((WHERE_CLAUSE = 'NODATA') OR (WHERE_CLAUSE_TYPE = 'RESP' ))
          THEN
             W_SQL :=      W_SQL || ' WHERE (ibr.IBRADVICES_RESP_ON_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
            ELSE
            W_SQL :=        W_SQL || '  WHERE (ibr.IBRADVICES_ADVICE_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
           W_SQL :=        W_SQL || '  or ibr.IBRADVICES_RESP_ON_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
          
          END IF;
            END IF;
           
         W_SQL :=
            W_SQL || 'AND tran_brn_code = ' || P_BRN_CODE ;
          
          W_SQL :=      W_SQL || '  )) t ON (t.TRAN_BATCH_NUMBER    =a.TRAN_BATCH_NUMBER
           AND t.tran_date_of_tran         =a.tran_date_of_tran
           AND t.TRAN_BATCH_SL_NUM         =a.TRAN_BATCH_SL_NUM
           AND t.TRAN_brn_code             =a.TRAN_brn_code)
         INNER JOIN
          (SELECT TRAN_BATCH_NUMBER,tran_date_of_tran,TRAN_BATCH_SL_NUM,TRAN_brn_code,TTMTISS_REMIT_CODE,TTMTISSDTL_BENEF_NAME, 
           TTMTISSDTL_BENEF_AC_NUM FROM tran'
         || W_YEAR
         || ' TRAN
           LEFT JOIN IBRADVICES i';
           
           IF ((WHERE_CLAUSE = 'NODATA') or (WHERE_CLAUSE_TYPE = 'ORIG' )) THEN 
             W_SQL :=      W_SQL || ' ON tran.TRAN_BATCH_NUMBER =i.ibradvices_tran_batch_num
                           AND tran.tran_date_of_tran=i.ibradvices_advice_date
                           AND tran.TRAN_BATCH_SL_NUM=i.IBRADVICES_TRAN_BATCH_SL
                           and tran.tran_brn_code=i.IBRADVICES_ORIG_BRN_CODE
                           AND tran.TRAN_ENTITY_NUM = 1';
          ELSE IF ((WHERE_CLAUSE = 'NODATA') or (WHERE_CLAUSE_TYPE = 'RESP' )) THEN 
            W_SQL :=        W_SQL || '  ON tran.TRAN_BATCH_NUMBER = i.IBRADVICES_RESP_IN_BATCH_NUM  
                            AND tran.tran_date_of_tran = i.IBRADVICES_RESP_ON_DATE
                            AND tran.TRAN_BATCH_SL_NUM = i.IBRADVICES_RESP_IN_BATCH_SL 
                            AND tran.tran_brn_code = i.IBRADVICES_CONTRA_BRN_CODE
                            AND tran.TRAN_ENTITY_NUM = 1';
          ELSE
            W_SQL :=        W_SQL || '  ON ((tran.TRAN_BATCH_NUMBER =i.ibradvices_tran_batch_num
                           AND tran.tran_date_of_tran=i.ibradvices_advice_date
                           AND tran.TRAN_BATCH_SL_NUM=i.IBRADVICES_TRAN_BATCH_SL
                           and tran.tran_brn_code=i.IBRADVICES_ORIG_BRN_CODE
                           AND tran.TRAN_ENTITY_NUM = 1)
               or (tran.TRAN_BATCH_NUMBER = i.IBRADVICES_RESP_IN_BATCH_NUM  
                            AND tran.tran_date_of_tran = i.IBRADVICES_RESP_ON_DATE
                            AND tran.TRAN_BATCH_SL_NUM = i.IBRADVICES_RESP_IN_BATCH_SL 
                            AND tran.tran_brn_code = i.IBRADVICES_CONTRA_BRN_CODE 
                            AND tran.TRAN_ENTITY_NUM = 1) )';
          END IF;
          END IF;
          
           W_SQL :=        W_SQL || '  
           LEFT JOIN TTMTISS
           ON TTMTISS.POST_TRAN_BATCH_NUM=i.IBRADVICES_TRAN_BATCH_NUM
           AND i.IBRADVICES_ADVICE_DATE  =TTMTISS_ISSUE_DATE
           LEFT JOIN TTMTISSDTL
           ON TTMTISS_REMIT_CODE         =TTMTISSDTL_REMIT_CODE
           AND TTMTISS_ENTITY_NUM        =TTMTISSDTL_ENTITY_NUM
           AND TTMTISS_BRN_CODE          =TTMTISSDTL_BRN_CODE
           AND TTMTISS_REMIT_CODE        =TTMTISSDTL_REMIT_CODE
           AND TTMTISS_ISSUE_DATE        =TTMTISSDTL_ISSUE_DATE
           AND TTMTISS_DAY_SL            =TTMTISSDTL_DAY_SL';
            
           IF ((WHERE_CLAUSE = 'NODATA') OR (WHERE_CLAUSE_TYPE = 'ORIG' ))
          THEN
             W_SQL :=      W_SQL || ' WHERE (i.IBRADVICES_ADVICE_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
            ELSE  IF ((WHERE_CLAUSE = 'NODATA') OR (WHERE_CLAUSE_TYPE = 'RESP' ))
          THEN
             W_SQL :=      W_SQL || ' WHERE (i.IBRADVICES_RESP_ON_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
            ELSE
            W_SQL :=        W_SQL || '  WHERE (i.IBRADVICES_ADVICE_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
           W_SQL :=        W_SQL || '  or i.IBRADVICES_RESP_ON_DATE='
         || CHR (39)
         || W_FOR_DATE
         || CHR (39);
          
          END IF;
            END IF;
            
          W_SQL :=
            W_SQL || 'AND tran_brn_code = ' || P_BRN_CODE ;
            
          W_SQL :=      W_SQL || ' ) ) mt ON (mt.TRAN_BATCH_NUMBER    =a.TRAN_BATCH_NUMBER
           AND mt.tran_date_of_tran         =a.tran_date_of_tran
           AND mt.TRAN_BATCH_SL_NUM         =a.TRAN_BATCH_SL_NUM
           AND mt.TRAN_brn_code             =a.TRAN_brn_code) where ';

      IF WHERE_CLAUSE != 'NODATA'
      THEN
         W_SQL := W_SQL || W_SQL3 ;
      ELSE
         IF P_BRN_CODE IS NOT NULL
         THEN
            W_SQL := W_SQL || ' t.tran_brn_code=' || P_BRN_CODE || ' AND ';
         END IF;

         IF P_TRANBAT_NUM IS NOT NULL
         THEN
            W_SQL :=
               W_SQL || '  t.TRAN_BATCH_NUMBER= ' || P_TRANBAT_NUM || 'AND ';
         END IF;
      END IF;

      --           IF P_ADV_ON_BRN IS NOT NULL THEN
      --                W_SQL:= W_SQL||' AND i.IBRADVICES_CONTRA_BRN_CODE= '||P_ADV_ON_BRN;
      --           END IF;
      IF ((WHERE_CLAUSE = 'NODATA')) THEN
          IF UPPER (RTYPE) = 'RIBRADV' THEN
             W_SQL := W_SQL  || '    not exists (SELECT * FROM ibradvprnt WHERE  IBRADVPRNT_ENTITY_NUM = 1 AND  IBRADVPRNT_ORIG_BRN_CODE = IBRADVICES_ORIG_BRN_CODE AND IBRADVPRNT_IBR_CODE =IBRADVICES_IBR_CODE AND IBRADVPRNT_YEAR=IBRADVICES_YEAR AND IBRADVPRNT_ADVICE_NUM= IBRADVICES_ADVICE_NUM)';
          ELSE
             W_SQL := W_SQL || '    exists (SELECT * FROM ibradvprnt WHERE  IBRADVPRNT_ENTITY_NUM = 1 AND  IBRADVPRNT_ORIG_BRN_CODE = IBRADVICES_ORIG_BRN_CODE AND IBRADVPRNT_IBR_CODE =IBRADVICES_IBR_CODE AND IBRADVPRNT_YEAR=IBRADVICES_YEAR AND IBRADVPRNT_ADVICE_NUM= IBRADVICES_ADVICE_NUM)';
          END IF;                                                 --ADDED BY TITLI
      END IF;

      DBMS_OUTPUT.PUT_LINE(W_SQL);

      EXECUTE IMMEDIATE W_SQL BULK COLLECT INTO V_TEMP_TABLEA;

      IF (V_TEMP_TABLEA.FIRST IS NOT NULL)
      THEN
         FOR INI IN V_TEMP_TABLEA.FIRST .. V_TEMP_TABLEA.LAST
         LOOP
            PRINT.ORIG_TRAN_FIRST_AUTH_BY := V_TEMP_TABLEA (INI).TMP_ORIG_TRAN_FIRST_AUTH_BY;
            PRINT.IBRADVICES_RESP_ON_DATE := V_TEMP_TABLEA (INI).TMP_IBRADVICES_RESP_ON_DATE;          
            PRINT.RESP_ENTRY := V_TEMP_TABLEA (INI).TMP_RESP_ENTRY;
            PRINT.RESP_AUTHER := V_TEMP_TABLEA (INI).TMP_RESP_AUTHER;
            PRINT.RESP_TRAN_FIRST_AUTH_BY := V_TEMP_TABLEA (INI).TMP_TRAN_FIRST_AUTH_BY;            
            PRINT.ORG_DD_DATE := V_TEMP_TABLEA (INI).TMP_ORG_DD_DATE;
            PRINT.ORG_DD_PFX := V_TEMP_TABLEA (INI).TMP_ORG_DD_PFX;
            PRINT.ORG_DD_NUM := V_TEMP_TABLEA (INI).TMP_ORG_DD_NUM;
            PRINT.TRAN_ENTD_BY1 := V_TEMP_TABLEA (INI).TMP_TRAN_ENTD_BY1;
            PRINT.TRAN_AUTH_BY := V_TEMP_TABLEA (INI).TMP_TRAN_AUTH_BY;
            

            PRINT.TTMTISS_REMIT_CODE :=
               V_TEMP_TABLEA (INI).TMP_TTMTISS_REMIT_CODE;
            PRINT.TTMTISSDTL_BENEF_NAME :=
               V_TEMP_TABLEA (INI).TMP_TTMTISSDTL_BENEF_NAME;
            PRINT.TTMTISSDTL_BENEF_AC_NUM :=
               V_TEMP_TABLEA (INI).TMP_TTMTISSDTL_BENEF_AC_NUM;
            PRINT.DDPOISS_REMITCODE :=
               V_TEMP_TABLEA (INI).TMP_DDPOISS_REMITCODE;
            PRINT.DDPOISSDTL_BENEFNAME1 :=
               V_TEMP_TABLEA (INI).TMP_DDPOISSDTL_BENEFNAME1;
            PRINT.DDPOISSDTL_BENEFNAME2 :=
               V_TEMP_TABLEA (INI).TMP_DDPOISSDTL_BENEFNAME2;
            PRINT.DDPOISSDTL_ON_ACOF :=
               V_TEMP_TABLEA (INI).TMP_DDPOISSDTL_ON_ACOF;
            PRINT.DDPOISSDTL_INST_NUMPFX :=
               V_TEMP_TABLEA (INI).TMP_DDPOISSDTL_INST_NUMPFX;
            PRINT.DDPOISSDTL_INST_NUM :=
               V_TEMP_TABLEA (INI).TMP_DDPOISSDTL_INST_NUM;
            PRINT.IBRADVICES_ORIG_BRNCODE :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_ORIG_BRNCODE;
            PRINT.IBRADVICES_IBRCODE :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_IBRCODE;
            PRINT.IBRADVICES_YEAR := V_TEMP_TABLEA (INI).TMP_IBRADVICES_YEAR;
            PRINT.IBRADVICES_ADVICENUM :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_ADVICENUM;
            PRINT.IBRADVICES_CONTRA_BRNCODE :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_CONTRA_BRNCODE;
            PRINT.IBRADVICES_ADVICEDATE :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_ADVICEDATE;
            --PRINT.IBRADVICES_ADVICEDATE1:= V_TEMP_TABLEA(INI).TMP_IBRADVICES_ADVICEDATE1;
            PRINT.IBRADVICES_PARTICLRS :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_PARTICLRS;
            PRINT.IBRADVICES_SOURCE_REFNUM :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_SOURCE_REFNUM;
            PRINT.IBRADVICES_TRAN_CURRCODE :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_TRAN_CURRCODE;
            PRINT.IBRADVICES_TRAN_AMOUNT :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_TRAN_AMOUNT;
            PRINT.IBRADVICES_TRAN_BATCH_NUM :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_TRAN_BATCH_NUM;
            PRINT.IBRADVICES_TRAN_AMOUNT1 :=
               V_TEMP_TABLEA (INI).TMP_IBRADVICES_TRAN_AMOUNT1;
            PRINT.WORD := V_TEMP_TABLEA (INI).TMP_WORD;
            PRINT.TRANBAT_SOURCEKEY :=
               V_TEMP_TABLEA (INI).TMP_TRANBAT_SOURCEKEY;
            PRINT.TRAN_ENTDBY := V_TEMP_TABLEA (INI).TMP_TRAN_ENTDBY;
            PRINT.TRANBATCH_NUMBER := V_TEMP_TABLEA (INI).TMP_TRANBATCH_NUMBER;
            PRINT.TRANBATCH_SL_NUM := V_TEMP_TABLEA (INI).TMP_TRANBATCH_SL_NUM;
            PRINT.TRAN_DBCR_FLG := V_TEMP_TABLEA (INI).TMP_TRAN_DBCR_FLG;
            PRINT.TRANGLACC_CODE := V_TEMP_TABLEA (INI).TMP_TRANGLACC_CODE;
            PRINT.TRANNARR_DTL1 := V_TEMP_TABLEA (INI).TMP_TRANNARR_DTL1;
            PRINT.TRANNARR_DTL2 := V_TEMP_TABLEA (INI).TMP_TRANNARR_DTL2;
            PRINT.TRANNARR_DTL3 := V_TEMP_TABLEA (INI).TMP_TRANNARR_DTL3;
            PRINT.TRANBATNARR_DTL1 := V_TEMP_TABLEA (INI).TMP_TRANBATNARR_DTL1;
            PRINT.TRANBATNARR_DTL2 := V_TEMP_TABLEA (INI).TMP_TRANBATNARR_DTL2;
            PRINT.TRANBATNARR_DTL3 := V_TEMP_TABLEA (INI).TMP_TRANBATNARR_DTL3;
            PRINT.IBTRAN_CODE := V_TEMP_TABLEA (INI).TMP_IBTRAN_CODE;
            PRINT.IBTRAN_CONCDESCN := V_TEMP_TABLEA (INI).TMP_IBTRAN_CONCDESCN;
            PRINT.IBTRAN_ADV_PRINTREQD :=
               V_TEMP_TABLEA (INI).TMP_IBTRAN_ADV_PRINTREQD;
            PRINT.MBRNNAME := V_TEMP_TABLEA (INI).TMP_MBRNNAME;
            PRINT.originatin_branchname :=
               V_TEMP_TABLEA (INI).TMP_originatin_branchname;
            PRINT.responding_branchname :=
               V_TEMP_TABLEA (INI).TMP_responding_branchname;
            PRINT.INS_NAME_OFBANK := V_TEMP_TABLEA (INI).TMP_INS_NAME_OFBANK;
            PRINT.EXTGL_EXT_HEADDESCN :=
               V_TEMP_TABLEA (INI).TMP_EXTGL_EXT_HEADDESCN;
            PIPE ROW (PRINT);
         END LOOP;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.PUT_LINE ('EXCEPTION' || SQLERRM);
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE (SQLERRM);
   END FN_GETIBRADV;

   FUNCTION GET_SQL_QUERY (WHERE_CLAUSE VARCHAR2)
      RETURN VARCHAR2
   IS
      SQL_STRING   VARCHAR2 (32000);
   BEGIN
      SELECT_QUERY := '';
      W_SQL :=
            '  SELECT SUBSTR (R, 0, LENGTH (R) - 5)
FROM
  (SELECT ''(''
    || RTRIM ( XMLAGG (XMLELEMENT (e, T
    || '') or ('')).EXTRACT ( ''//text()''), '','') AS R
  FROM
    (SELECT REPLACE (''t.tran_brn_code=''
      || split, ''|'', '' and t.TRAN_BATCH_NUMBER='') AS T
    FROM
      (WITH test AS
      (SELECT '
         || CHR (39)
         || WHERE_CLAUSE
         || CHR (39)
         || '   AS str
      FROM DUAL
      )
    SELECT REGEXP_SUBSTR (str, ''[^,]+'', 1, ROWNUM) split
    FROM test
      CONNECT BY LEVEL <= LENGTH ( REGEXP_REPLACE (str, ''[^,]+'')) + 1
      )
    )
  ) ';
      DBMS_OUTPUT.PUT_LINE ('W_SQL=' || W_SQL);

      EXECUTE IMMEDIATE W_SQL INTO SELECT_QUERY;


      RETURN SELECT_QUERY;
   END GET_SQL_QUERY;
BEGIN
   NULL;
END PKG_RIBRADV;
/
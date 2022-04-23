CREATE OR REPLACE PROCEDURE SP_RESCHEDULE_LOAN (
   P_ACCTUAL_ACCOUNT              MIG_LNACRSDTL_TEMP.LNACRSDTL_ACNUM%TYPE,
   P_EFFECTIVE_DATE               MIG_LNACRSDTL_TEMP.LNACRS_EFF_DATE%TYPE,
   P_REPH_ON_AMT                  MIG_LNACRSDTL_TEMP.LNACRS_REPH_ON_AMT%TYPE,
   P_NUM_OF_INSTALLMENT           MIG_LNACRSDTL_TEMP.LNACRSDTL_NUM_OF_INSTALLMENT%TYPE,
   p_LNACRS_SANC_BY               MIG_LNACRSDTL_TEMP.LNACRS_SANC_BY%TYPE,
   p_LNACRS_SANC_REF_NUM          MIG_LNACRSDTL_TEMP.LNACRS_SANC_REF_NUM%TYPE,
   P_LNACRS_SANC_DATE             MIG_LNACRSDTL_TEMP.LNACRS_SANC_DATE%TYPE,
   P_LNACRSDTL_RS_NO              MIG_LNACRSDTL_TEMP.LNACRSDTL_RS_NO%TYPE,
   P_LNACRSDTL_REPAY_FREQ         MIG_LNACRSDTL_TEMP.LNACRSDTL_REPAY_FREQ%TYPE,
   P_LNACRSDTL_REPAY_FROM_DATE    MIG_LNACRSDTL_TEMP.LNACRSDTL_REPAY_FROM_DATE%TYPE,
   P_LNACRSDTL_LIMIT_EXP_DATE     MIG_LNACRSDTL_TEMP.LNACRSDTL_LIMIT_EXP_DATE%TYPE)
IS
   V_ACCTUAL_ACCOUNT         VARCHAR2 (25) := P_ACCTUAL_ACCOUNT;
   V_EFFECTIVE_DATE          DATE := P_EFFECTIVE_DATE;
   V_REPH_ON_AMT             NUMBER := P_REPH_ON_AMT;
   V_NUM_OF_INSTALLMENT      NUMBER := P_NUM_OF_INSTALLMENT;
   V_INTERNAL_ACCOUNT        NUMBER (14);
   V_ERR                     VARCHAR2 (100);
   V_LATEST_EFFECTIVE_DATE   DATE;
   V_COUNT                   NUMBER;
BEGIN
  <<INTERNAL_ACCOUNT_FINDING>>
   BEGIN
      SELECT IACLINK_INTERNAL_ACNUM
        INTO V_INTERNAL_ACCOUNT
        FROM IACLINK
       WHERE     IACLINK_ENTITY_NUM = 1
             AND IACLINK_ACTUAL_ACNUM = V_ACCTUAL_ACCOUNT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         V_ERR := 'INVALID ACCOUNT NUMBER';

         UPDATE MIG_LNACRSDTL_TEMP
            SET UPDATE_REMARKS = V_ERR
          WHERE LNACRSDTL_ACNUM = V_ACCTUAL_ACCOUNT;

         COMMIT;

         RETURN;
   END INTERNAL_ACCOUNT_FINDING;



  <<RECORD_FINDING_FROM_LNACRS>>
   BEGIN
      SELECT COUNT (*)
        INTO V_COUNT
        FROM LNACRS
       WHERE     LNACRS_ENTITY_NUM = 1
             AND LNACRS_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;

      IF V_COUNT = 0
      THEN
         V_ERR := 'ACCOUNT NUMBER NOT FOUND IN LNACRS';


         INSERT INTO LNACRS (LNACRS_ENTITY_NUM,
                             LNACRS_INTERNAL_ACNUM,
                             LNACRS_LATEST_EFF_DATE,
                             LNACRS_EQU_INSTALLMENT,
                             LNACRS_REPH_ON_AMT,
                             LNACRS_REPHASEMENT_ENTRY,
                             LNACRS_AUTO_REPHASED_FLG,
                             LNACRS_SANC_BY,
                             LNACRS_SANC_REF_NUM,
                             LNACRS_SANC_DATE,
                             LNACRS_CLIENT_REF_NUM,
                             LNACRS_CLIENT_REF_DATE,
                             LNACRS_REMARKS1,
                             LNACRS_REMARKS2,
                             LNACRS_REMARKS3,
                             LNACRS_REDISB_DATE,
                             LNACRS_INTR_CAPTL,
                             LNACRS_PURPOSE,
                             LNACRS_RS_NO)
              VALUES (1,
                      V_INTERNAL_ACCOUNT,
                      V_EFFECTIVE_DATE,
                      '1',
                      P_REPH_ON_AMT,
                      '1',
                      NULL,
                      p_LNACRS_SANC_BY,
                      p_LNACRS_SANC_REF_NUM,
                      P_LNACRS_SANC_DATE,
                      NULL,
                      NULL,
                      'MIGRATION',
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      'R',
                      P_LNACRSDTL_RS_NO);

         COMMIT;
      END IF;
   END RECORD_FINDING_FROM_LNACRS;



  <<RECORD_FINDING_FROM_LNACRSDTL>>
   BEGIN
      SELECT COUNT (*)
        INTO V_COUNT
        FROM LNACRSDTL
       WHERE     LNACRSDTL_ENTITY_NUM = 1
             AND LNACRSDTL_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;

      IF V_COUNT = 0
      THEN
         V_ERR := 'ACCOUNT NUMBER NOT FOUND IN LNACRSDTL';


         INSERT INTO LNACRSDTL (LNACRSDTL_ENTITY_NUM,
                                LNACRSDTL_INTERNAL_ACNUM,
                                LNACRSDTL_SL_NUM,
                                LNACRSDTL_REPAY_AMT_CURR,
                                LNACRSDTL_REPAY_AMT,
                                LNACRSDTL_REPAY_FREQ,
                                LNACRSDTL_REPAY_FROM_DATE,
                                LNACRSDTL_NUM_OF_INSTALLMENT,
                                LNACRSDTL_TOT_REPAY_AMT,
                                LNACRSDTL_LIMIT_EXP_DATE)
              VALUES (1,
                      V_INTERNAL_ACCOUNT,
                      1,
                      'BDT',
                      P_REPH_ON_AMT,
                      P_LNACRSDTL_REPAY_FREQ,
                      P_LNACRSDTL_REPAY_FROM_DATE,
                      P_NUM_OF_INSTALLMENT,
                      V_REPH_ON_AMT * P_NUM_OF_INSTALLMENT,
                      P_LNACRSDTL_LIMIT_EXP_DATE);

         COMMIT;
      END IF;
   END RECORD_FINDING_FROM_LNACRSDTL;



  <<RECORD_FINDING_FROM_LNACRSHDTL>>
   BEGIN
      SELECT COUNT (*)
        INTO V_COUNT
        FROM LNACRSHDTL
       WHERE     LNACRSHDTL_ENTITY_NUM = 1
             AND LNACRSHDTL_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;

      IF V_COUNT = 0
      THEN
         V_ERR := 'ACCOUNT NUMBER NOT FOUND IN LNACRSHDTL';


         INSERT INTO LNACRSHDTL (LNACRSHDTL_ENTITY_NUM,
                                 LNACRSHDTL_INTERNAL_ACNUM,
                                 LNACRSHDTL_EFF_DATE,
                                 LNACRSHDTL_SL_NUM,
                                 LNACRSHDTL_REPAY_AMT_CURR,
                                 LNACRSHDTL_REPAY_AMT,
                                 LNACRSHDTL_REPAY_FREQ,
                                 LNACRSHDTL_REPAY_FROM_DATE,
                                 LNACRSHDTL_NUM_OF_INSTALLMENT,
                                 LNACRSHDTL_TOT_REPAY_AMT,
                                 LNACRSHDTL_LIMIT_EXP_DATE)
              VALUES (1,
                      V_INTERNAL_ACCOUNT,
                      V_EFFECTIVE_DATE,
                      1,
                      'BDT',
                      V_REPH_ON_AMT,
                      P_LNACRSDTL_REPAY_FREQ,
                      P_LNACRSDTL_REPAY_FROM_DATE,
                      P_NUM_OF_INSTALLMENT,
                      V_REPH_ON_AMT * P_NUM_OF_INSTALLMENT,
                      P_LNACRSDTL_LIMIT_EXP_DATE);

         COMMIT;
      END IF;
   END RECORD_FINDING_FROM_LNACRSHDTL;



  <<RECORD_FINDING_FROM_LNACRSHIST>>
   BEGIN
      SELECT COUNT (*)
        INTO V_COUNT
        FROM LNACRSHIST
       WHERE     LNACRSH_ENTITY_NUM = 1
             AND LNACRSH_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;

      IF V_COUNT = 0
      THEN
         V_ERR := 'ACCOUNT NUMBER NOT FOUND IN LNACRSHIST';


         INSERT INTO LNACRSHIST (LNACRSH_ENTITY_NUM,
                                 LNACRSH_INTERNAL_ACNUM,
                                 LNACRSH_EFF_DATE,
                                 LNACRSH_EQU_INSTALLMENT,
                                 LNACRSH_REPH_ON_AMT,
                                 LNACRSH_REPHASEMENT_ENTRY,
                                 LNACRSH_AUTO_REPHASED_FLG,
                                 LNACRSH_SANC_BY,
                                 LNACRSH_SANC_REF_NUM,
                                 LNACRSH_SANC_DATE,
                                 LNACRSH_CLIENT_REF_NUM,
                                 LNACRSH_CLIENT_REF_DATE,
                                 LNACRSH_REMARKS1,
                                 LNACRSH_REMARKS2,
                                 LNACRSH_REMARKS3,
                                 LNACRSH_ENTD_BY,
                                 LNACRSH_ENTD_ON,
                                 LNACRSH_LAST_MOD_BY,
                                 LNACRSH_LAST_MOD_ON,
                                 LNACRSH_AUTH_BY,
                                 LNACRSH_AUTH_ON,
                                 TBA_MAIN_KEY,
                                 LNACRSH_REDISB_DATE,
                                 LNACIRSH_INTR_CAPTL,
                                 LNACRSH_PURPOSE,
                                 LNACRSH_RS_NO)
              VALUES (1,
                      V_INTERNAL_ACCOUNT,
                      V_EFFECTIVE_DATE,
                      '1',
                      V_REPH_ON_AMT,
                      '1',
                      NULL,
                      p_LNACRS_SANC_BY,
                      p_LNACRS_SANC_REF_NUM,
                      P_LNACRS_SANC_DATE,
                      NULL,
                      NULL,
                      'MIGRATION',
                      NULL,
                      NULL,
                      'MIG',
                      SYSDATE,
                      NULL,
                      NULL,
                      'MIG',
                      SYSDATE,
                      NULL,
                      NULL,
                      NULL,
                      'R',
                      P_LNACRSDTL_RS_NO);

         COMMIT;
      END IF;
   END RECORD_FINDING_FROM_LNACRSHIST;



   SELECT LNACRS_LATEST_EFF_DATE
     INTO V_LATEST_EFFECTIVE_DATE
     FROM LNACRS
    WHERE     LNACRS_ENTITY_NUM = 1
          AND LNACRS_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;


   IF V_LATEST_EFFECTIVE_DATE = V_EFFECTIVE_DATE
   THEN
      UPDATE LNACRS
         SET LNACRS_REPHASEMENT_ENTRY = 1,
             LNACRS_REPH_ON_AMT = V_REPH_ON_AMT,
             LNACRS_PURPOSE = 'R',
             LNACRS_RS_NO = P_LNACRSDTL_RS_NO
       WHERE     LNACRS_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT
             AND LNACRS_ENTITY_NUM = 1
             AND LNACRS_LATEST_EFF_DATE = V_EFFECTIVE_DATE;

      UPDATE LNACRSHIST
         SET LNACRSH_REPHASEMENT_ENTRY = 1,
             LNACRSH_REPH_ON_AMT = V_REPH_ON_AMT,
             LNACRSH_PURPOSE = 'R',
             LNACRSH_RS_NO = P_LNACRSDTL_RS_NO
       WHERE     LNACRSH_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT
             AND LNACRSH_ENTITY_NUM = 1
             AND LNACRSH_EFF_DATE = V_EFFECTIVE_DATE;

      UPDATE LNACRSDTL
         SET LNACRSDTL_LIMIT_EXP_DATE = P_LNACRSDTL_LIMIT_EXP_DATE
       WHERE     LNACRSDTL_ENTITY_NUM = 1
             AND LNACRSDTL_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;


      UPDATE LNACRSHDTL
         SET LNACRSHDTL_LIMIT_EXP_DATE = P_LNACRSDTL_LIMIT_EXP_DATE
       WHERE     LNACRSHDTL_ENTITY_NUM = 1
             AND LNACRSHDTL_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;
       /*
LNACRS
LNACRSDTL
LNACRSHDTL
LNACRSHIST
    */
   END IF;


   IF V_LATEST_EFFECTIVE_DATE < V_EFFECTIVE_DATE
   THEN
      UPDATE LNACRS
         SET LNACRS_REPHASEMENT_ENTRY = 1,
             LNACRS_REPH_ON_AMT = V_REPH_ON_AMT,
             LNACRS_PURPOSE = 'R',
             LNACRS_RS_NO = P_LNACRSDTL_RS_NO,
             LNACRS_LATEST_EFF_DATE = V_EFFECTIVE_DATE
       WHERE     LNACRS_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT
             AND LNACRS_ENTITY_NUM = 1;

      UPDATE LNACRSDTL
         SET LNACRSDTL_LIMIT_EXP_DATE = P_LNACRSDTL_LIMIT_EXP_DATE
       WHERE     LNACRSDTL_ENTITY_NUM = 1
             AND LNACRSDTL_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;

      INSERT INTO LNACRSHIST (LNACRSH_ENTITY_NUM,
                              LNACRSH_INTERNAL_ACNUM,
                              LNACRSH_EFF_DATE,
                              LNACRSH_EQU_INSTALLMENT,
                              LNACRSH_REPH_ON_AMT,
                              LNACRSH_REPHASEMENT_ENTRY,
                              LNACRSH_AUTO_REPHASED_FLG,
                              LNACRSH_SANC_BY,
                              LNACRSH_SANC_REF_NUM,
                              LNACRSH_SANC_DATE,
                              LNACRSH_CLIENT_REF_NUM,
                              LNACRSH_CLIENT_REF_DATE,
                              LNACRSH_REMARKS1,
                              LNACRSH_REMARKS2,
                              LNACRSH_REMARKS3,
                              LNACRSH_ENTD_BY,
                              LNACRSH_ENTD_ON,
                              LNACRSH_LAST_MOD_BY,
                              LNACRSH_LAST_MOD_ON,
                              LNACRSH_AUTH_BY,
                              LNACRSH_AUTH_ON,
                              TBA_MAIN_KEY,
                              LNACRSH_REDISB_DATE,
                              LNACIRSH_INTR_CAPTL,
                              LNACRSH_PURPOSE,
                              LNACRSH_RS_NO)
           VALUES (1,
                   V_INTERNAL_ACCOUNT,
                   V_EFFECTIVE_DATE,
                   '1',
                   V_REPH_ON_AMT,
                   '1',
                   NULL,
                   p_LNACRS_SANC_BY,
                   p_LNACRS_SANC_REF_NUM,
                   P_LNACRS_SANC_DATE,
                   NULL,
                   NULL,
                   'MIGRATION',
                   NULL,
                   NULL,
                   'MIG',
                   SYSDATE,
                   NULL,
                   NULL,
                   'MIG',
                   SYSDATE,
                   NULL,
                   NULL,
                   NULL,
                   'R',
                   P_LNACRSDTL_RS_NO);


      INSERT INTO LNACRSHDTL (LNACRSHDTL_ENTITY_NUM,
                              LNACRSHDTL_INTERNAL_ACNUM,
                              LNACRSHDTL_EFF_DATE,
                              LNACRSHDTL_SL_NUM,
                              LNACRSHDTL_REPAY_AMT_CURR,
                              LNACRSHDTL_REPAY_AMT,
                              LNACRSHDTL_REPAY_FREQ,
                              LNACRSHDTL_REPAY_FROM_DATE,
                              LNACRSHDTL_NUM_OF_INSTALLMENT,
                              LNACRSHDTL_TOT_REPAY_AMT,
                              LNACRSHDTL_LIMIT_EXP_DATE)
           VALUES (1,
                   V_INTERNAL_ACCOUNT,
                   V_EFFECTIVE_DATE,
                   1,
                   'BDT',
                   V_REPH_ON_AMT,
                   P_LNACRSDTL_REPAY_FREQ,
                   P_LNACRSDTL_REPAY_FROM_DATE,
                   P_NUM_OF_INSTALLMENT,
                   V_REPH_ON_AMT * P_NUM_OF_INSTALLMENT,
                   P_LNACRSDTL_LIMIT_EXP_DATE);
   END IF;


   IF V_LATEST_EFFECTIVE_DATE > V_EFFECTIVE_DATE
   THEN
      UPDATE LNACRS
         SET LNACRS_REPHASEMENT_ENTRY = 1,
             LNACRS_REPH_ON_AMT = V_REPH_ON_AMT,
             LNACRS_PURPOSE = 'R',
             LNACRS_RS_NO = P_LNACRSDTL_RS_NO
       WHERE     LNACRS_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT
             AND LNACRS_ENTITY_NUM = 1;

      UPDATE LNACRSDTL
         SET LNACRSDTL_LIMIT_EXP_DATE = P_LNACRSDTL_LIMIT_EXP_DATE
       WHERE     LNACRSDTL_ENTITY_NUM = 1
             AND LNACRSDTL_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT;

      UPDATE LNACRSHIST
         SET LNACRSH_REPHASEMENT_ENTRY = 1,
             LNACRSH_REPH_ON_AMT = V_REPH_ON_AMT,
             LNACRSH_PURPOSE = 'R',
             LNACRSH_RS_NO = P_LNACRSDTL_RS_NO
       WHERE     LNACRSH_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT
             AND LNACRSH_ENTITY_NUM = 1
             AND LNACRSH_EFF_DATE > V_EFFECTIVE_DATE;

      UPDATE LNACRSHDTL
         SET LNACRSHDTL_LIMIT_EXP_DATE = P_LNACRSDTL_LIMIT_EXP_DATE
       WHERE     LNACRSHDTL_ENTITY_NUM = 1
             AND LNACRSHDTL_INTERNAL_ACNUM = V_INTERNAL_ACCOUNT
             AND LNACRSHDTL_EFF_DATE > V_EFFECTIVE_DATE;
   END IF;


   UPDATE MIG_LNACRSDTL_TEMP
      SET UPDATE_REMARKS = 'SUCCESSSFUL'
    WHERE LNACRSDTL_ACNUM = V_ACCTUAL_ACCOUNT;

   COMMIT;
END;
/























CREATE OR REPLACE PROCEDURE SP_TEST_RESCHEDULE
IS
BEGIN

   UPDATE MIG_LNACRSDTL_TEMP
      SET LNACRSDTL_LIMIT_EXP_DATE =
             ADD_MONTHS (LNACRSDTL_REPAY_FROM_DATE,
                         LNACRSDTL_NUM_OF_INSTALLMENT)
    WHERE LNACRSDTL_REPAY_FREQ = 'M';



   UPDATE MIG_LNACRSDTL_TEMP
      SET LNACRSDTL_LIMIT_EXP_DATE =
             ADD_MONTHS (LNACRSDTL_REPAY_FROM_DATE,
                         LNACRSDTL_NUM_OF_INSTALLMENT * 3)
    WHERE LNACRSDTL_REPAY_FREQ = 'Q';



   UPDATE MIG_LNACRSDTL_TEMP
      SET LNACRSDTL_LIMIT_EXP_DATE =
             ADD_MONTHS (LNACRSDTL_REPAY_FROM_DATE,
                         LNACRSDTL_NUM_OF_INSTALLMENT * 6)
    WHERE LNACRSDTL_REPAY_FREQ = 'H';



   UPDATE MIG_LNACRSDTL_TEMP
      SET LNACRSDTL_LIMIT_EXP_DATE =
             ADD_MONTHS (LNACRSDTL_REPAY_FROM_DATE,
                         LNACRSDTL_NUM_OF_INSTALLMENT * 12)
    WHERE LNACRSDTL_REPAY_FREQ = 'Y';


   BEGIN
      FOR IDX
         IN (SELECT LNACRSDTL_ACNUM,
                    IACLINK_INTERNAL_ACNUM,
                    LMTLINE_LIMIT_EXPIRY_DATE
               FROM MIG_LNACRSDTL_TEMP,
                    IACLINK,
                    LIMITLINE,
                    ACASLLDTL
              WHERE     IACLINK_ENTITY_NUM = 1
                    AND LMTLINE_ENTITY_NUM = 1
                    AND ACASLLDTL_ENTITY_NUM = 1
                    AND ACASLLDTL_INTERNAL_ACNUM = IACLINK_INTERNAL_ACNUM
                    AND ACASLLDTL_CLIENT_NUM = LMTLINE_CLIENT_CODE
                    AND LMTLINE_NUM = ACASLLDTL_LIMIT_LINE_NUM
                    AND LNACRSDTL_ACNUM = IACLINK_ACTUAL_ACNUM
                    AND LNACRSDTL_REPAY_FREQ = 'X')
      LOOP
         UPDATE MIG_LNACRSDTL_TEMP
            SET LNACRSDTL_LIMIT_EXP_DATE = IDX.LMTLINE_LIMIT_EXPIRY_DATE
          WHERE LNACRSDTL_ACNUM = IDX.LNACRSDTL_ACNUM;
      END LOOP;
   END;



   BEGIN
      FOR IDX
         IN (SELECT LNACRSDTL_ACNUM,
                    IACLINK_INTERNAL_ACNUM,
                    LMTLINE_LIMIT_EXPIRY_DATE
               FROM MIG_LNACRSDTL_TEMP,
                    IACLINK,
                    LIMITLINE,
                    ACASLLDTL
              WHERE     IACLINK_ENTITY_NUM = 1
                    AND LMTLINE_ENTITY_NUM = 1
                    AND ACASLLDTL_ENTITY_NUM = 1
                    AND ACASLLDTL_INTERNAL_ACNUM = IACLINK_INTERNAL_ACNUM
                    AND ACASLLDTL_CLIENT_NUM = LMTLINE_CLIENT_CODE
                    AND LMTLINE_NUM = ACASLLDTL_LIMIT_LINE_NUM
                    AND LNACRSDTL_ACNUM = IACLINK_ACTUAL_ACNUM
                    AND LNACRSDTL_REPAY_FREQ IS NULL)
      LOOP
         UPDATE MIG_LNACRSDTL_TEMP
            SET LNACRSDTL_LIMIT_EXP_DATE = IDX.LMTLINE_LIMIT_EXPIRY_DATE,
                LNACRSDTL_REPAY_FREQ = 'X'
          WHERE LNACRSDTL_ACNUM = IDX.LNACRSDTL_ACNUM;
      END LOOP;
   END;

   COMMIT;

   FOR IDX IN (SELECT LNACRSDTL_ACNUM,
                      LNACRS_EFF_DATE,
                      LNACRS_REPH_ON_AMT,
                      LNACRSDTL_NUM_OF_INSTALLMENT,
                      LNACRS_SANC_BY,
                      LNACRS_SANC_REF_NUM,
                      LNACRS_SANC_DATE,
                      LNACRSDTL_RS_NO,
                      LNACRSDTL_REPAY_FREQ,
                      LNACRSDTL_REPAY_FROM_DATE,
                      LNACRSDTL_LIMIT_EXP_DATE
                 FROM MIG_LNACRSDTL_TEMP
                 WHERE UPDATE_REMARKS IS NULL
                 OR UPDATE_REMARKS = 'INVALID ACCOUNT NUMBER')
   LOOP
      SP_RESCHEDULE_LOAN (IDX.LNACRSDTL_ACNUM,
                          IDX.LNACRS_EFF_DATE,
                          IDX.LNACRS_REPH_ON_AMT,
                          IDX.LNACRSDTL_NUM_OF_INSTALLMENT,
                          IDX.LNACRS_SANC_BY,
                          IDX.LNACRS_SANC_REF_NUM,
                          IDX.LNACRS_SANC_DATE,
                          IDX.LNACRSDTL_RS_NO,
                          IDX.LNACRSDTL_REPAY_FREQ,
                          IDX.LNACRSDTL_REPAY_FROM_DATE,
                          IDX.LNACRSDTL_LIMIT_EXP_DATE);
   END LOOP;
END;
/
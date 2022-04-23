CREATE OR REPLACE PACKAGE BODY PKG_RD_ACNT_FRZ
IS
   /*
    Modification History
     -----------------------------------------------------------------------------------------
    Sl.            Description                             Mod By             Mod on
    -----------------------------------------------------------------------------------------

   -----------------------------------------------------------------------------------------
    */
   TYPE TT_UPDATE_DATA
      IS RECORD (V_PBDCONT_DEP_AC_NUM PBDCONTRACT.PBDCONT_DEP_AC_NUM%TYPE);

   TYPE T_UPDATE_DATA IS TABLE OF TT_UPDATE_DATA
      INDEX BY PLS_INTEGER;

   V_UPDATE_DATA              T_UPDATE_DATA;

   TYPE RDODPENALDEFDTL IS RECORD
   (
      RDODPENALDEFDTL_RUN_PERIOD       NUMBER (5),
      RDODPENALDEFDTL_INCLUDE_FLG      CHAR (1),
      RDODPENALDEFDTL_PENAL_APPL       CHAR (1),
      RDODPENALDEFDTL_MAX_DEF_ALWD     NUMBER (3),
      RDODPENALDEFDTL_PENAL_INT_RATE   NUMBER (9, 6)
   );

   TYPE TABRDODPENDEFDTL IS TABLE OF RDODPENALDEFDTL
      INDEX BY PLS_INTEGER;

   V_RDODPENDEFDTL            TABRDODPENDEFDTL;

   V_ENTITY_CODE              NUMBER (5);
   V_USER_ID                  VARCHAR2 (8);
   L_BRN_CODE                 NUMBER (6);
   V_PENALTY_BSD_ON_PEN_DEF   CHAR (1);
   V_PROD_CODE                NUMBER (4);
   V_AC_TYPE                  VARCHAR2 (5);
   V_AC_SUB_TYPE              NUMBER (3);
   V_RUN_PERIOD               NUMBER (4);
   V_ERROR                    VARCHAR2 (1000);
   V_SQL                      VARCHAR2 (2300);
   V_LATEST_PAYMENT_DATE      DATE;
   V_NOM_DEFAULTED            NUMBER (4);
   V_AC_FRZ                   NUMBER;
   V_CBD                      DATE;
   V_ACNTFRZ_FLG              NUMBER;

   --Added by Keerthana on 2 Apr 2012 Begins
   V_RD_RUN_PERIOD            NUMBER (3);
   V_AMT_TWDS_INSTLMNT        NUMBER (18, 3);
   V_AMT_TOBE_PAID            NUMBER (18, 3);
   V_REQD_AMT                 NUMBER (18, 3);

   --Added by Keerthana on 2 Apr 2012 Ends

   PROCEDURE RD_ACC_FRZ
   IS
   BEGIN
      FOR IDX IN V_UPDATE_DATA.FIRST .. V_UPDATE_DATA.LAST
      LOOP
         UPDATE ACNTS
            SET ACNTS_DB_FREEZED = '1', ACNTS_CR_FREEZED = '1'
          WHERE     ACNTS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                AND ACNTS_INTERNAL_ACNUM =
                       V_UPDATE_DATA (IDX).V_PBDCONT_DEP_AC_NUM;
      END LOOP;



      FORALL IDX IN V_UPDATE_DATA.FIRST .. V_UPDATE_DATA.LAST
         MERGE INTO ACNTFRZ A
              USING (SELECT V_UPDATE_DATA (IDX).V_PBDCONT_DEP_AC_NUM
                               V_PBDCONT_DEP_AC_NUM
                       FROM DUAL) B
                 ON (    A.ACNTFRZ_INTERNAL_ACNUM = B.V_PBDCONT_DEP_AC_NUM
                     AND A.ACNTFRZ_ENTITY_NUM = 1)
         WHEN MATCHED
         THEN
            UPDATE SET
               A.ACNTFRZ_STOP_DB = '1',
               A.ACNTFRZ_STOP_CR = '1',
               A.ACNTFRZ_FREEZED_ON = V_CBD,
               A.ACNTFRZ_REASON1 = 'Account Credit Freezed due to',
               A.ACNTFRZ_REASON2 = 'RD Max Defaulted value is Breached',
               A.ACNTFRZ_LAST_MOD_BY = V_USER_ID,
               A.ACNTFRZ_LAST_MOD_ON = V_CBD,
               A.ACNTFRZ_AUTH_BY = V_USER_ID,
               A.ACNTFRZ_AUTH_ON = V_CBD
                    WHERE     A.ACNTFRZ_ENTITY_NUM = 1
                          AND A.ACNTFRZ_INTERNAL_ACNUM =
                                 B.V_PBDCONT_DEP_AC_NUM
         WHEN NOT MATCHED
         THEN
            INSERT     (ACNTFRZ_ENTITY_NUM,
                        ACNTFRZ_INTERNAL_ACNUM,
                        ACNTFRZ_FREEZED_ON,
                        ACNTFRZ_STOP_DB,
                        ACNTFRZ_STOP_CR,
                        ACNTFRZ_FREEZE_REQ_BY1,
                        ACNTFRZ_FREEZE_REQ_BY2,
                        ACNTFRZ_FREEZE_REQ_BY3,
                        ACNTFRZ_FREEZE_REQ_BY4,
                        ACNTFRZ_REASON1,
                        ACNTFRZ_REASON2,
                        ACNTFRZ_REASON3,
                        ACNTFRZ_REASON4,
                        ACNTFRZ_ENTD_BY,
                        ACNTFRZ_ENTD_ON,
                        ACNTFRZ_LAST_MOD_BY,
                        ACNTFRZ_LAST_MOD_ON,
                        ACNTFRZ_AUTH_BY,
                        ACNTFRZ_AUTH_ON,
                        TBA_MAIN_KEY)
                VALUES (PKG_ENTITY.FN_GET_ENTITY_CODE,
                        V_UPDATE_DATA (IDX).V_PBDCONT_DEP_AC_NUM,
                        V_CBD,
                        '1',
                        '1',
                        '',
                        '',
                        '',
                        '',
                        'Account Credit Freezed due to',
                        'RD Max Defaulted value is Breached',
                        '',
                        '',
                        V_USER_ID,
                        V_CBD,
                        '',
                        NULL,
                        V_USER_ID,
                        V_CBD,
                        '');


      FORALL IDX IN V_UPDATE_DATA.FIRST .. V_UPDATE_DATA.LAST
         INSERT INTO RDFRZ (RDFRZ_ENTITY_NUM,
                            RDFRZ_BRANCH_CODE,
                            RDFRZ_AC_NUM,
                            RDFRZ_PROCESS_DATE,
                            RDFRZ_UNFRZD_ON,
                            RDFRZ_REMARKS)
              VALUES (
                        PKG_ENTITY.FN_GET_ENTITY_CODE,
                        L_BRN_CODE,
                        V_UPDATE_DATA (IDX).V_PBDCONT_DEP_AC_NUM,
                        V_CBD,
                        NULL,
                        --TT_TT_DDPO (IDX).V_DDPO_PROGRAMM_ID,
                        'Account Credit Freezed due to RD Max Defaulted value is Breached');
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         V_ERROR := 'Entry already exists for account:';
      WHEN OTHERS
      THEN
         V_ERROR := SQLERRM;
   END RD_ACC_FRZ;

   PROCEDURE PROCESS_RD_ACNT_FRZ
   IS
      V_COUNTER   NUMBER := 0;
   BEGIN
      FOR IDX_REC_PBDCONT
         IN (  SELECT PBD_RDINS.*, COUNT (RDFRZ.RDFRZ_AC_NUM) EXISTS_FLAG
                 FROM (  SELECT PBDCONT_EFF_DATE,
                                PBDCONT_DEP_AC_NUM,
                                DEPPR_PENALTY_BSD_ON_PEN_DEF,
                                ACNTS_AC_TYPE,
                                ACNTS_AC_SUB_TYPE,
                                PBDCONT_DEP_CURR,
                                ACNTS_PROD_CODE,
                                PBDCONT_AC_DEP_AMT,
                                TRUNC (
                                   MONTHS_BETWEEN (SYSDATE,
                                                   MIN (RDINS_ENTRY_DATE)))
                                   RD_RUN_PERIOD,
                                NVL (SUM (RDINS_TWDS_INSTLMNT), 0)
                                   AMT_TWDS_INSTLMNT
                           FROM PBDCONTRACT,
                                DEPPROD,
                                ACNTS,
                                RDINS
                          WHERE     PBDCONT_ENTITY_NUM =
                                       PKG_ENTITY.FN_GET_ENTITY_CODE
                                AND ACNTS_ENTITY_NUM =
                                       PKG_ENTITY.FN_GET_ENTITY_CODE
                                AND PBDCONT_CLOSURE_DATE IS NULL
                                AND PBDCONT_AUTH_ON IS NOT NULL
                                AND PBDCONT_REJ_ON IS NULL
                                AND DEPPR_PROD_CODE = ACNTS_PROD_CODE
                                AND ACNTS_INTERNAL_ACNUM = PBDCONT_DEP_AC_NUM
                                AND DEPPR_TYPE_OF_DEP = '3'
                                AND PBDCONT_BRN_CODE = L_BRN_CODE
                                AND RDINS_ENTITY_NUM =
                                       PKG_ENTITY.FN_GET_ENTITY_CODE
                                AND RDINS_RD_AC_NUM = PBDCONT_DEP_AC_NUM
                       GROUP BY PBDCONT_EFF_DATE,
                                PBDCONT_DEP_AC_NUM,
                                DEPPR_PENALTY_BSD_ON_PEN_DEF,
                                ACNTS_AC_TYPE,
                                ACNTS_AC_SUB_TYPE,
                                PBDCONT_DEP_CURR,
                                ACNTS_PROD_CODE,
                                PBDCONT_AC_DEP_AMT) PBD_RDINS
                      LEFT OUTER JOIN
                      RDFRZ
                         ON (    RDFRZ_AC_NUM = PBDCONT_DEP_AC_NUM
                             AND RDFRZ_ENTITY_NUM =
                                    PKG_ENTITY.FN_GET_ENTITY_CODE)
             GROUP BY PBD_RDINS.PBDCONT_EFF_DATE,
                      PBD_RDINS.PBDCONT_DEP_AC_NUM,
                      PBD_RDINS.DEPPR_PENALTY_BSD_ON_PEN_DEF,
                      PBD_RDINS.ACNTS_AC_TYPE,
                      PBD_RDINS.ACNTS_AC_SUB_TYPE,
                      PBD_RDINS.PBDCONT_DEP_CURR,
                      PBD_RDINS.ACNTS_PROD_CODE,
                      PBD_RDINS.PBDCONT_AC_DEP_AMT,
                      PBD_RDINS.RD_RUN_PERIOD,
                      PBD_RDINS.AMT_TWDS_INSTLMNT)
      LOOP
         V_PROD_CODE := IDX_REC_PBDCONT.ACNTS_PROD_CODE;
         V_PENALTY_BSD_ON_PEN_DEF :=
            IDX_REC_PBDCONT.DEPPR_PENALTY_BSD_ON_PEN_DEF;
         V_AC_TYPE := IDX_REC_PBDCONT.ACNTS_AC_TYPE;
         V_AC_SUB_TYPE := IDX_REC_PBDCONT.ACNTS_AC_SUB_TYPE;


         IF V_PENALTY_BSD_ON_PEN_DEF = '1'
         THEN
            IF IDX_REC_PBDCONT.EXISTS_FLAG = 0
            THEN
               SELECT TRUNC (
                         MONTHS_BETWEEN (V_CBD,
                                         IDX_REC_PBDCONT.PBDCONT_EFF_DATE))
                 INTO V_RUN_PERIOD
                 FROM DUAL;

               --Changes by Keerthana on 2 Apr 2012 Begin
               --SELECT DISTINCT RDINS_EFF_DATE INTO V_LATEST_PAYMENT_DATE FROM RDINS WHERE RDINS_RD_AC_NUM = IDX_REC_PBDCONT.PBDCONT_DEP_AC_NUM AND RDINS_EFF_DATE =
               --(SELECT MAX(RDINS_EFF_DATE) FROM RDINS WHERE RDINS_RD_AC_NUM = IDX_REC_PBDCONT.PBDCONT_DEP_AC_NUM);


               --SELECT TRUNC(MONTHS_BETWEEN (V_CBD,V_LATEST_PAYMENT_DATE )) INTO V_NOM_DEFAULTED FROM DUAL;

               --SELECT TRUNC(MONTHS_BETWEEN(V_CBD,MIN(RDINS_ENTRY_DATE))) ,NVL(SUM(RDINS_TWDS_INSTLMNT),0) INTO V_RD_RUN_PERIOD,V_AMT_TWDS_INSTLMNT FROM RDINS WHERE  RDINS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE  AND  RDINS_RD_AC_NUM=IDX_REC_PBDCONT.PBDCONT_DEP_AC_NUM;

               V_RD_RUN_PERIOD := IDX_REC_PBDCONT.RD_RUN_PERIOD;

               V_AMT_TWDS_INSTLMNT := IDX_REC_PBDCONT.AMT_TWDS_INSTLMNT;

               V_AMT_TOBE_PAID :=
                  V_RD_RUN_PERIOD * IDX_REC_PBDCONT.PBDCONT_AC_DEP_AMT;

               V_REQD_AMT := V_AMT_TOBE_PAID - V_AMT_TWDS_INSTLMNT;

               V_NOM_DEFAULTED :=
                  V_REQD_AMT / IDX_REC_PBDCONT.PBDCONT_AC_DEP_AMT;

               --Changes by Keerthana on 2 Apr 2012 End

               IF V_NOM_DEFAULTED IS NOT NULL
               THEN
                  V_SQL :=
                     'SELECT RDODPENALDEFDTL_RUN_PERIOD,RDODPENALDEFDTL_INCLUDE_FLG,RDODPENALDEFDTL_PENAL_APPL,
                            RDODPENALDEFDTL_MAX_DF_ST_CHG,RDODPENALDEFDTL_PENAL_INT_RATE FROM RDODPENALDEFDTL
                            WHERE RDODPENALDEFDTL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                            AND RDODPENALDEFDTL_PROD_CODE = :1
                            AND RDODPENALDEFDTL_AC_TYPE = :2
                            AND RDODPENALDEFDTL_ACSUB_TYPE = :3
                            AND RDODPENALDEFDTL_CURR_CODE = :4';

                  EXECUTE IMMEDIATE V_SQL
                     BULK COLLECT INTO V_RDODPENDEFDTL
                     USING V_PROD_CODE,
                           V_AC_TYPE,
                           V_AC_SUB_TYPE,
                           IDX_REC_PBDCONT.PBDCONT_DEP_CURR;

                  FOR I IN 1 .. V_RDODPENDEFDTL.COUNT
                  LOOP
                     IF V_RDODPENDEFDTL (I).RDODPENALDEFDTL_INCLUDE_FLG = 'I'
                     THEN
                        IF V_RUN_PERIOD <=
                              V_RDODPENDEFDTL (I).RDODPENALDEFDTL_RUN_PERIOD
                        THEN
                           IF V_NOM_DEFAULTED >=
                                 V_RDODPENDEFDTL (I).RDODPENALDEFDTL_MAX_DEF_ALWD
                           THEN
                              V_COUNTER := V_COUNTER + 1;
                              V_UPDATE_DATA (V_COUNTER).V_PBDCONT_DEP_AC_NUM :=
                                 IDX_REC_PBDCONT.PBDCONT_DEP_AC_NUM;
                           --RD_ACC_FRZ (IDX_REC_PBDCONT.PBDCONT_DEP_AC_NUM);
                           END IF;
                        END IF;
                     ELSIF V_RDODPENDEFDTL (I).RDODPENALDEFDTL_INCLUDE_FLG =
                              'E'
                     THEN
                        IF V_RUN_PERIOD <
                              V_RDODPENDEFDTL (I).RDODPENALDEFDTL_RUN_PERIOD
                        THEN
                           IF V_NOM_DEFAULTED >=
                                 V_RDODPENDEFDTL (I).RDODPENALDEFDTL_MAX_DEF_ALWD
                           THEN
                              V_COUNTER := V_COUNTER + 1;
                              V_UPDATE_DATA (V_COUNTER).V_PBDCONT_DEP_AC_NUM :=
                                 IDX_REC_PBDCONT.PBDCONT_DEP_AC_NUM;
                           --RD_ACC_FRZ (IDX_REC_PBDCONT.PBDCONT_DEP_AC_NUM);
                           END IF;
                        END IF;
                     END IF;
                  END LOOP;
               END IF;
            END IF;
         END IF;
      END LOOP;

      RD_ACC_FRZ;
      V_UPDATE_DATA.DELETE;
      
   END PROCESS_RD_ACNT_FRZ;

   PROCEDURE INIT_PARA
   IS
   BEGIN
      V_ENTITY_CODE := 0;
      V_USER_ID := '';
      L_BRN_CODE := 0;
      V_PENALTY_BSD_ON_PEN_DEF := '0';
      V_PROD_CODE := 0;
      V_AC_TYPE := '';
      V_AC_SUB_TYPE := 0;
      V_RUN_PERIOD := 0;
      V_ERROR := '';
      V_SQL := '';
      V_LATEST_PAYMENT_DATE := NULL;
      V_NOM_DEFAULTED := 0;
      V_AC_FRZ := 0;
      V_CBD := NULL;
      V_ACNTFRZ_FLG := 0;
   END INIT_PARA;

   PROCEDURE CHECK_INPUT_VALUES
   IS
   BEGIN
      IF V_ENTITY_CODE = 0
      THEN
         V_ERROR := 'Entity Number is not specified';
      END IF;

      IF V_USER_ID IS NULL
      THEN
         V_ERROR := 'User ID is not specified';
      END IF;

      IF V_CBD IS NULL
      THEN
         V_ERROR := 'Current Business Date is not specified';
      END IF;
   END CHECK_INPUT_VALUES;

   PROCEDURE START_BRNWISE (V_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0)
   IS
   BEGIN
      INIT_PARA;

      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);
      V_ENTITY_CODE := PKG_ENTITY.FN_GET_ENTITY_CODE;
      V_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;
      V_CBD := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

      CHECK_INPUT_VALUES;

      IF V_ERROR IS NULL
      THEN
         PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (V_ENTITY_CODE, P_BRN_CODE);

         FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
         LOOP
            L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

            IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (V_ENTITY_CODE,
                                                            L_BRN_CODE) =
                  FALSE
            THEN
               PROCESS_RD_ACNT_FRZ ();

               IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
               THEN
                  PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (
                     PKG_ENTITY.FN_GET_ENTITY_CODE,
                     L_BRN_CODE);
               END IF;

               PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (
                  PKG_ENTITY.FN_GET_ENTITY_CODE);
            END IF;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         IF V_ERROR IS NOT NULL
         THEN
            V_ERROR := SUBSTR ('ERROR IN PKG_RD_FRZ ' || SQLERRM, 1, 500);
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := V_ERROR;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_CODE,
                                      'E',
                                      PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                      ' ',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_CODE,
                                      'E',
                                      SUBSTR (SQLERRM, 1, 1000),
                                      ' ',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (V_ENTITY_CODE,
                                      'X',
                                      V_ENTITY_CODE,
                                      ' ',
                                      0);
   END START_BRNWISE;
END PKG_RD_ACNT_FRZ;
/
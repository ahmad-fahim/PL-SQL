CREATE OR REPLACE PACKAGE BODY PKG_DORINOPMARK
IS
   PROCEDURE SP_DORINOPMARK (V_ENTITY_NUM IN NUMBER)
   IS
      TYPE R_RAPARAM_ACNT_INOP IS RECORD
      (
         INTERNAL_ACNUM        NUMBER (14),
         DORMANT_INOP_DATE     DATE,
         DORMANT_ACNT          CHAR (1),
         INOP_ACNT             CHAR (1),
         AC_TYPE               VARCHAR2 (5),
         DORMANT_CUTOFF_DATE   DATE,
         INOP_CUTOFF_DATE      DATE
      );

      TYPE R_ACNT_STATUS_CHECK IS RECORD
      (
         INTERNAL_ACNUM   NUMBER (14),
         STATUS           VARCHAR2 (1)
      );


      TYPE IT_RAPARAM_ACNT_INOP IS TABLE OF R_RAPARAM_ACNT_INOP
         INDEX BY PLS_INTEGER;

      TYPE IT_ACNTS IS TABLE OF NUMBER
         INDEX BY PLS_INTEGER;

      TYPE IT_ACNTS_STATUS IS TABLE OF VARCHAR2 (1)
         INDEX BY PLS_INTEGER;

      TYPE IT_DORMANT_ACNT IS TABLE OF VARCHAR2 (1)
         INDEX BY PLS_INTEGER;

      TYPE IT_INOP_ACNT IS TABLE OF VARCHAR2 (1)
         INDEX BY PLS_INTEGER;

      TYPE IT_ACNT_STATUS_CHECK IS TABLE OF R_ACNT_STATUS_CHECK
         INDEX BY VARCHAR2 (14);

      T_RAPARAM_ACNT_INOP            IT_RAPARAM_ACNT_INOP;
      T_ACNTS                        IT_ACNTS;
      T_ACNTS_STATUS                 IT_ACNTS_STATUS;
      T_DORMANT_ACNT                 IT_DORMANT_ACNT;
      T_INOP_ACNT                    IT_INOP_ACNT;
      T_ACNTS_STATUS_CHECK           IT_ACNT_STATUS_CHECK;
      T_ACNTS_STATUS_INSERT_STATUS   IT_ACNTS_STATUS;
      T_ACNTS_STATUS_UPDATE_STATUS   IT_ACNTS_STATUS;
      T_ACNTS_STATUS_INSERT_ACNO     IT_ACNTS;
      T_ACNTS_STATUS_UPDATE_ACNO     IT_ACNTS;
      V_ACNTSTATUS_INSERT_IND        NUMBER;
      V_ACNTSTATUS_UPDATE_IND        NUMBER;
      V_CBD                          DATE;
      V_USERID                       VARCHAR2 (8);
      V_SQL                          VARCHAR2 (4300);
      V_IND                          NUMBER;
      V_ERR_MSG                      VARCHAR2 (1000);
      --Added by Suganthi for Dormant Non-Marking
      W_INTERNAL_ACNUM               VARCHAR2 (18);
      V_MAJ_AGE                      NUMBER (3);
      V_DIFF                         NUMBER (20);
      V_CORP_QUAL                    VARCHAR2 (5);
      V_STATUS                       NUMBER (5);
      V_CLIENT_DATE                  VARCHAR2 (35);
      V_AGE                          NUMBER (7);
      V_CURR_DATE                    DATE;
      V_CUR_DATE                     VARCHAR2 (20);
      V_DOR_CUTOFF_DATE              VARCHAR2 (20);
      V_INOP_CUTOFF_DATE             VARCHAR2 (20);
      --End by Suganthi

      V_COUNT                        NUMBER := 0;

      E_USEREXCEP                    EXCEPTION;
   BEGIN
      --ENTITY CODE COMMONLY ADDED - 06-11-2009  - BEG
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);
      --ENTITY CODE COMMONLY ADDED - 06-11-2009  - END
      V_CBD := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      V_USERID := PKG_EODSOD_FLAGS.PV_USER_ID;

      V_SQL :=
         'SELECT ACNTSTATUS_INTERNAL_ACNUM  FROM ACNTSTATUS
                         WHERE ACNTSTATUS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND  ACNTSTATUS_EFF_DATE =:1 AND ACNTSTATUS_FLG = ''O'' ';

      EXECUTE IMMEDIATE V_SQL BULK COLLECT INTO t_acnts USING V_CBD;


      IF t_acnts.EXISTS (1) = TRUE
      THEN
         FOR idx IN 1 .. t_acnts.COUNT
         LOOP
            t_acnts_status_check (t_acnts (idx)).internal_acnum :=
               t_acnts (idx);
            t_acnts_status_check (t_acnts (idx)).status := 'O';
         END LOOP;

         t_acnts.DELETE;
      END IF;

      -- fetch raparam details for a account type

      V_SQL :=
         'SELECT acnts_internal_acnum,
       CASE
          WHEN acnts_nonsys_last_date IS NULL THEN acnts_opening_date
          ELSE acnts_nonsys_last_date
       END
          dormant_date,
       NVL (acnts_dormant_acnt, ''0''),
       NVL (acnts_inop_acnt, ''0''),
       AC_TYPE,
       DORMANT_CUTOFF_DATE,
       INOP_CUTOFF_DATE
  FROM ACNTS,
       (SELECT raparam_ac_type AC_TYPE,
               CASE raparam_dormant_ac_prd_flg
                  WHEN ''D''
                  THEN
                     (TO_DATE (:1, ''DD-MON-YYYY'') - raparam_dormant_ac_prd)
                  WHEN ''M''
                  THEN
                     ADD_MONTHS (:2, -1 * raparam_dormant_ac_prd)
                  ELSE
                     NULL
               END
                  DORMANT_CUTOFF_DATE,
               CASE raparam_inop_ac_prd_flg
                  WHEN ''D''
                  THEN
                     (TO_DATE (:3, ''DD-MON-YYYY'') - raparam_inop_ac_prd)
                  WHEN ''M''
                  THEN
                     ADD_MONTHS (:4, -1 * raparam_inop_ac_prd)
                  ELSE
                     NULL
               END
                  INOP_CUTOFF_DATE
          FROM RAPARAM) T_RAPARAM
 WHERE        ACNTS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
          AND (    acnts_ac_type = T_RAPARAM.AC_TYPE
               AND acnts_dormant_acnt <> ''1''
               AND (   (    acnts_nonsys_last_date IS NULL
                        AND acnts_opening_date <
                               T_RAPARAM.DORMANT_CUTOFF_DATE)
                    OR (    acnts_nonsys_last_date IS NOT NULL
                        AND acnts_nonsys_last_date <
                               T_RAPARAM.DORMANT_CUTOFF_DATE)))
       OR     (    acnts_ac_type = T_RAPARAM.AC_TYPE
               AND acnts_inop_acnt <> ''1''
               AND (   (    acnts_nonsys_last_date IS NULL
                        AND acnts_opening_date < T_RAPARAM.INOP_CUTOFF_DATE)
                    OR (    acnts_nonsys_last_date IS NOT NULL
                        AND acnts_nonsys_last_date <
                               T_RAPARAM.INOP_CUTOFF_DATE)))
          AND acnts_closure_date IS NULL';

      EXECUTE IMMEDIATE V_SQL
         BULK COLLECT INTO T_RAPARAM_ACNT_INOP
         USING V_CBD,
               V_CBD,
               V_CBD,
               V_CBD;

      -- fetch all accounts satisfying the dormant and inop condition for an account type
      -- into the accounts collection

      V_IND := 1;
      V_ACNTSTATUS_INSERT_IND := 1;
      V_ACNTSTATUS_UPDATE_IND := 1;

      FOR IDX IN 1 .. T_RAPARAM_ACNT_INOP.COUNT
      LOOP
         V_DOR_CUTOFF_DATE :=
            TO_DATE (T_RAPARAM_ACNT_INOP (IDX).DORMANT_CUTOFF_DATE, 'DD-MON-YYYY'); --ADDED BY PRATIK 28-08-2013
         V_INOP_CUTOFF_DATE :=
            TO_DATE (T_RAPARAM_ACNT_INOP (IDX).INOP_CUTOFF_DATE, 'DD-MON-YYYY'); --ADDED BY PRATIK 28-08-2013

         IF    T_RAPARAM_ACNT_INOP (IDX).DORMANT_CUTOFF_DATE < V_CBD
            OR T_RAPARAM_ACNT_INOP (IDX).INOP_CUTOFF_DATE < V_CBD
         THEN
            --Mohan - added the above condition to handle if cutoff prd is not specified
            -- CHN Guna 28/07/2011 start
            /*   v_sql := 'Select acnts_internal_acnum,
                CASE acnts_nonsys_last_date
                WHEN NULL THEN acnts_opening_date
                ELSE acnts_nonsys_last_date
                END dormant_date,
                Nvl(acnts_dormant_acnt,''0''), Nvl(acnts_inop_acnt,''0'')
            FROM ACNTS
             WHERE ACNTS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND  ( acnts_ac_type = :1
                        AND acnts_dormant_acnt <> ''1''
                      AND ((acnts_nonsys_last_date IS NULL AND acnts_opening_date < :2) OR
                        (acnts_nonsys_last_date IS NOT NULL AND acnts_nonsys_last_date < :3)))
                OR
                  ( acnts_ac_type = :4
                      AND acnts_inop_acnt <> ''1''
                    AND ((acnts_nonsys_last_date IS NULL AND acnts_opening_date < :5 ) OR
                           (acnts_nonsys_last_date IS NOT NULL AND acnts_nonsys_last_date < :6)))
                AND acnts_closure_date IS NULL'; */



            V_STATUS := 0;
            V_AGE := '';
            V_CURR_DATE :=
               PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (
                  PKG_ENTITY.FN_GET_ENTITY_CODE);



            V_CUR_DATE := TO_CHAR (V_CURR_DATE, 'DD-MON-YYYY');

            --Added By Suganthi
            --Loan Accounts non-marking
            BEGIN
               SELECT LNACNT_INTERNAL_ACNUM
                 INTO W_INTERNAL_ACNUM
                 FROM LOANACNTS
                WHERE     LNACNT_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                      AND LNACNT_INTERNAL_ACNUM =
                             T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM;

               V_STATUS := 1;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_STATUS := 0;
            END;

            --Minor Accounts non-marking
            BEGIN
               IF V_STATUS <> 1
               THEN
                  SELECT MAJAGE_MAJ_AGE
                    INTO V_MAJ_AGE
                    FROM MAJAGE
                   WHERE MAJAGE_EFF_DATE =
                            (SELECT MAX (MAJAGE_EFF_DATE) FROM MAJAGE);



                  SELECT MAX (TO_CHAR (INDCLIENT_BIRTH_DATE, 'DD-MON-YYYY'))
                    INTO V_CLIENT_DATE
                    FROM ACNTS, INDCLIENTS C
                   WHERE     ACNTS_CLIENT_NUM = INDCLIENT_CODE
                         AND ACNTS_INTERNAL_ACNUM =
                                T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM
                         AND ACNTS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE;

                  --dbms_output.put_line('V_CLIENT_DATE'||V_CLIENT_DATE);


                  SELECT (  TO_DATE (V_CUR_DATE, 'DD-MON-YYYY')
                          - TO_DATE (V_CLIENT_DATE, 'DD-MON-YYYY'))
                    INTO V_DIFF
                    FROM DUAL;


                  --dbms_output.put_line('V_AGE'||V_AGE);
                  V_AGE := V_DIFF / 365;

                  -- IF V_AGE <18 THEN
                  IF V_AGE < V_MAJ_AGE
                  THEN                --Modified By venugopal.M on 04-Jun-2013
                     V_STATUS := 1;
                  END IF;

                  IF V_CLIENT_DATE IS NULL
                  THEN
                     V_STATUS := 0;
                  END IF;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_STATUS := 0;
            END;

            --Corp Clients Non-Marking
            BEGIN
               IF V_STATUS <> 1
               THEN
                  SELECT CORPCL_ORGN_QUALIFIER
                    INTO V_CORP_QUAL
                    FROM CORPCLIENTS, ACNTS
                   WHERE     ACNTS_CLIENT_NUM = CORPCL_CLIENT_CODE
                         AND ACNTS_INTERNAL_ACNUM =
                                T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM
                         AND ACNTS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE;

                  IF V_CORP_QUAL <> 'O'
                  THEN
                     V_STATUS := 1;
                  ELSE
                     V_STATUS := 0;
                  END IF;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  V_STATUS := 0;
            END;

            --End
            IF V_STATUS <> 1
            THEN                                  --Added By Suganthi Begin If
               --Mohan-Rem     IF p_Markinop = 1 THEN
               IF T_RAPARAM_ACNT_INOP (IDX).INOP_ACNT <> '1'
               THEN
                  IF T_RAPARAM_ACNT_INOP (IDX).INOP_CUTOFF_DATE < V_CBD
                  THEN
                     --Mohan-add to handle if cutoff prd is not specified
                     IF     T_RAPARAM_ACNT_INOP (IDX).DORMANT_INOP_DATE <
                               V_INOP_CUTOFF_DATE
                        AND (   (V_DOR_CUTOFF_DATE IS NULL)
                             OR (    V_DOR_CUTOFF_DATE <= V_CBD
                                 AND T_RAPARAM_ACNT_INOP (IDX).DORMANT_INOP_DATE <=
                                        V_DOR_CUTOFF_DATE))
                     THEN
                        T_ACNTS (V_IND) := T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM;
                        T_INOP_ACNT (V_IND) := '1';

                        IF T_ACNTS_STATUS_CHECK.EXISTS (
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM) = TRUE
                        THEN
                           T_ACNTS_STATUS_UPDATE_ACNO (
                              V_ACNTSTATUS_UPDATE_IND) :=
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM;
                           T_ACNTS_STATUS_UPDATE_STATUS (
                              V_ACNTSTATUS_UPDATE_IND) :=
                              'I';
                           V_ACNTSTATUS_UPDATE_IND :=
                              V_ACNTSTATUS_UPDATE_IND + 1;
                        ELSE
                           T_ACNTS_STATUS_INSERT_ACNO (
                              V_ACNTSTATUS_INSERT_IND) :=
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM;
                           T_ACNTS_STATUS_INSERT_STATUS (
                              V_ACNTSTATUS_INSERT_IND) :=
                              'I';
                           V_ACNTSTATUS_INSERT_IND :=
                              V_ACNTSTATUS_INSERT_IND + 1;
                        END IF;
                     /*ELSE
                     v_inop_acnt(v_ind) :='0' ;  */
                     END IF;
                  END IF;
               END IF;
            END IF;                                          --End By Suganthi

            IF V_STATUS <> 1
            THEN                                  --Added By Suganthi Begin If
               --Mohan-Rem      IF P_MarkDormant = 1  THEN
               IF T_RAPARAM_ACNT_INOP (IDX).DORMANT_ACNT <> '1'
               THEN
                  IF T_RAPARAM_ACNT_INOP (IDX).DORMANT_CUTOFF_DATE < V_CBD
                  THEN
                     --Mohan-add to handle if cutoff prd is not specified
                     IF T_RAPARAM_ACNT_INOP (IDX).DORMANT_INOP_DATE < V_DOR_CUTOFF_DATE
                     THEN
                        T_ACNTS (V_IND) := T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM;
                        T_DORMANT_ACNT (V_IND) := '1';

                        IF T_ACNTS_STATUS_CHECK.EXISTS (
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM) = TRUE
                        THEN
                           T_ACNTS_STATUS_UPDATE_ACNO (
                              V_ACNTSTATUS_UPDATE_IND) :=
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM;
                           T_ACNTS_STATUS_UPDATE_STATUS (
                              V_ACNTSTATUS_UPDATE_IND) :=
                              'D';
                           V_ACNTSTATUS_UPDATE_IND :=
                              V_ACNTSTATUS_UPDATE_IND + 1;
                        ELSE
                           T_ACNTS_STATUS_CHECK (
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM).INTERNAL_ACNUM :=
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM;
                           T_ACNTS_STATUS_CHECK (
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM).STATUS :=
                              'D';
                           T_ACNTS_STATUS_INSERT_ACNO (
                              V_ACNTSTATUS_INSERT_IND) :=
                              T_RAPARAM_ACNT_INOP (IDX).INTERNAL_ACNUM;
                           T_ACNTS_STATUS_INSERT_STATUS (
                              V_ACNTSTATUS_INSERT_IND) :=
                              'D';
                           V_ACNTSTATUS_INSERT_IND :=
                              V_ACNTSTATUS_INSERT_IND + 1;
                        END IF;
                     /* ELSE
                     v_dormant_acnt(v_ind) :='0' ; */
                     END IF;
                  END IF;
               END IF;
            END IF;                                          --End By Suganthi


            IF T_ACNTS.EXISTS (V_IND)
            THEN
               IF T_DORMANT_ACNT.EXISTS (V_IND) = FALSE
               THEN
                  T_DORMANT_ACNT (V_IND) := T_RAPARAM_ACNT_INOP (IDX).DORMANT_ACNT;
               ELSIF T_INOP_ACNT.EXISTS (V_IND) = FALSE
               THEN
                  T_INOP_ACNT (V_IND) := T_RAPARAM_ACNT_INOP (IDX).INOP_ACNT;
               END IF;

               V_IND := V_IND + 1;
            END IF;
         END IF;                                                -- Mohan added
      END LOOP;

      -- update acnts and acntsstatus tables
      IF T_ACNTS.COUNT > 0
      THEN
         FORALL IDXACNTS IN 1 .. T_ACNTS.COUNT
            UPDATE ACNTS
               SET ACNTS_DORMANT_ACNT = T_DORMANT_ACNT (IDXACNTS),
                   ACNTS_INOP_ACNT = T_INOP_ACNT (IDXACNTS)
             WHERE     ACNTS_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                   AND ACNTS_INTERNAL_ACNUM = T_ACNTS (IDXACNTS);

         IF T_ACNTS_STATUS_INSERT_ACNO.EXISTS (1) = TRUE
         THEN
            FORALL IDXACNTS IN 1 .. T_ACNTS_STATUS_INSERT_ACNO.COUNT
               INSERT INTO ACNTSTATUS (ACNTSTATUS_ENTITY_NUM,
                                       ACNTSTATUS_INTERNAL_ACNUM,
                                       ACNTSTATUS_EFF_DATE,
                                       ACNTSTATUS_FLG,
                                       ACNTSTATUS_REMARKS1,
                                       ACNTSTATUS_REMARKS2,
                                       ACNTSTATUS_REMARKS3,
                                       ACNTSTATUS_ENTD_BY,
                                       ACNTSTATUS_ENTD_ON)
                    VALUES (PKG_ENTITY.FN_GET_ENTITY_CODE,
                            T_ACNTS_STATUS_INSERT_ACNO (IDXACNTS),
                            V_CBD,
                            T_ACNTS_STATUS_INSERT_STATUS (IDXACNTS),
                            'Auto Classification ',
                            ' ',
                            ' ',
                            V_USERID,
                            SYSDATE);
         END IF;

         IF T_ACNTS_STATUS_UPDATE_ACNO.EXISTS (1) = TRUE
         THEN
            FORALL IDXACNTS IN 1 .. T_ACNTS_STATUS_UPDATE_ACNO.COUNT
               UPDATE ACNTSTATUS
                  SET ACNTSTATUS_INTERNAL_ACNUM =
                         T_ACNTS_STATUS_UPDATE_ACNO (IDXACNTS),
                      ACNTSTATUS_FLG = T_ACNTS_STATUS_UPDATE_STATUS (IDXACNTS),
                      ACNTSTATUS_REMARKS1 = 'Auto Classification',
                      ACNTSTATUS_LAST_MOD_BY = V_USERID,
                      ACNTSTATUS_LAST_MOD_ON = SYSDATE
                WHERE     ACNTSTATUS_ENTITY_NUM =
                             PKG_ENTITY.FN_GET_ENTITY_CODE
                      AND ACNTSTATUS_INTERNAL_ACNUM =
                             T_ACNTS_STATUS_UPDATE_ACNO (IDXACNTS)
                      AND ACNTSTATUS_EFF_DATE = V_CBD;
         END IF;
      END IF;

      T_DORMANT_ACNT.DELETE;
      T_INOP_ACNT.DELETE;
      T_ACNTS.DELETE;
      T_ACNTS_STATUS.DELETE;
      T_RAPARAM_ACNT_INOP.DELETE;
      T_ACNTS_STATUS_CHECK.DELETE;
      T_ACNTS_STATUS_INSERT_ACNO.DELETE;
      T_ACNTS_STATUS_UPDATE_ACNO.DELETE;
      T_ACNTS_STATUS_INSERT_STATUS.DELETE;
      T_ACNTS_STATUS_UPDATE_ACNO.DELETE;

      UPDATE ACC
         SET RATE = V_COUNT
       WHERE ACC_NO = 'ACNTS';
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (V_ERR_MSG) IS NULL
         THEN
            V_ERR_MSG := 'ERROR IN SP_DORINOPMARK';
            DBMS_OUTPUT.PUT_LINE (SQLERRM);
         END IF;

         PKG_EODSOD_FLAGS.PV_ERROR_MSG := V_ERR_MSG;
         PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                      'E',
                                      PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                      '',
                                      0);
         PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                      'E',
                                      SUBSTR (SQLERRM, 1, 1000),
                                      ' ',
                                      0);
   -- RAISE E_USEREXCEP;  -- REM Guna 28/07/2011
   END SP_DORINOPMARK;
END PKG_DORINOPMARK;
/
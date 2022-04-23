CREATE OR REPLACE PACKAGE PKG_CLCHGWAIVERHIST_REPORT
IS
   TYPE TY_AC_VALUE IS RECORD
   (
      CLCHGWAIVHIST_CLIENT_NUM       NUMBER,
      CLCHGWAIV_ACNUM                VARCHAR2 (15),
      ACC_CLIENT_NAME                VARCHAR2 (150),
      AC_TYPE                        VARCHAR2 (150),
      CLCHGWAIVHIST_EFF_DATE         DATE,
      CLCHGWAIVHIST_APPROVAL_BY      VARCHAR2 (15),
      CLCHGWAIVHIST_REF_NUM          VARCHAR2 (150),
      CLCHGWAIVHIST_DATED            DATE,
      CLCHGWAIVHIST_NOTES            VARCHAR2 (105),
      CLCHGWAIVHIST_WAIVE_REQD       VARCHAR2 (10),
      CLCHGWAIVDTHIST_CHARGE_CODE    VARCHAR2 (150),
      CHG_CODE_DESC                  VARCHAR2 (50),
      CLCHGWAIVDTHIST_WAIVER_TYPE    VARCHAR2 (1),
      CLCHGWAIVDTHIST_DISCOUNT_PER   NUMBER (4, 2),
      CLCHGWAIVDTHIST_USER_ID        VARCHAR2 (8),
      CLCHGWAIVDTHIST_BRN_CODE       NUMBER
   );

   TYPE TY_AC_VALUE_DTL IS TABLE OF TY_AC_VALUE;


   FUNCTION AC_VALUE_DTL (P_ENTITYNUM   IN NUMBER,
                          P_BRN_CODE       NUMBER,
                          P_RPT_TYPE       VARCHAR2,
                          P_FROM_DATE      DATE,
                          P_TO_DATE        DATE)
      --RETURN VARCHAR2 ;
      RETURN TY_AC_VALUE_DTL
      PIPELINED;
END PKG_CLCHGWAIVERHIST_REPORT;
/


CREATE OR REPLACE PACKAGE BODY PKG_CLCHGWAIVERHIST_REPORT
IS
   TABLE2              PKG_CLCHGWAIVERHIST_REPORT.TY_AC_VALUE;

   V_SQL_1_1           VARCHAR2 (32767);
   V_SQL_1_2           VARCHAR2 (32767);
   V_SQL_1_3           VARCHAR2 (32767);
   V_SQL_1_4           VARCHAR2 (32767);
   V_SQL1              VARCHAR2 (32767);
   V_SQL2              VARCHAR2 (32767);

   TYPE R_AC_VALUE_DTL IS RECORD
   (
      TM_CLCHGWAIVHIST_CLIENT_NUM      NUMBER,
      TM_CLCHGWAIV_ACNUM               VARCHAR2 (15),
      TM_ACC_CLIENT_NAME               VARCHAR2 (150),
      TM_AC_TYPE                       VARCHAR2 (150),
      TM_CLCHGWAIVHIST_EFF_DATE        DATE,
      TM_CLCHGWAIVHIST_APPROVAL_BY     VARCHAR2 (15),
      TM_CLCHGWAIVHIST_REF_NUM         VARCHAR2 (150),
      TM_CLCHGWAIVHIST_DATED           DATE,
      TM_CLCHGWAIVHIST_NOTES           VARCHAR2 (105),
      TM_CLCHGWAIVHIST_WAIVE_REQD      VARCHAR2 (10),
      TM_CLCHGWAIVDTHIST_CHARGE_CODE   VARCHAR2 (150),
      TM_CHG_CODE_DESC                 VARCHAR2 (50),
      TM_CLCHGWAIVDTHIST_WAIVER_TYPE   VARCHAR2 (1),
      TM_CLCHGWAIVDTHIST_DISCOUNT_PE   NUMBER (4, 2),
      TM_CLCHGWAIVDTHIST_USER_ID       VARCHAR2 (8),
      TM_CLCHGWAIVDTHIST_BRN_CODE      NUMBER
   );


   TYPE TTY_AC_VALUE_DTL IS TABLE OF R_AC_VALUE_DTL
      INDEX BY PLS_INTEGER;

   V_TY_AC_VALUE_DTL   TTY_AC_VALUE_DTL;


   TYPE R_DIST_VALUE IS RECORD
   (
      T_CLCHGWAIVHIST_CLIENT_NUM   NUMBER,
      T_CLCHGWAIV_ACNUM            VARCHAR2 (15),
      T_CLCHGWAIVHIST_EFF_DATE     DATE,
      T_CLCHGWAIVHIST_WAIVE_REQD   VARCHAR2 (10)
   );


   TYPE TTY_DIST_VALUE IS TABLE OF R_DIST_VALUE
      INDEX BY PLS_INTEGER;

   V_TY_DIST_VALUE     TTY_DIST_VALUE;



   FUNCTION AC_VALUE_DTL (P_ENTITYNUM   IN NUMBER,
                          P_BRN_CODE    IN NUMBER,
                          P_RPT_TYPE    IN VARCHAR2,
                          P_FROM_DATE   IN DATE,
                          P_TO_DATE     IN DATE)
      RETURN TY_AC_VALUE_DTL
      PIPELINED
   --RETURN VARCHAR2
   IS
      E_USEREXCEP               EXCEPTION;
      W_ERROR_MSG               VARCHAR2 (60);
      V_COL_SL                  NUMBER;
      V_CLIENT_NUM              NUMBER;
      V_NAME                    VARCHAR2 (100);
      V_AC_TYPE                 VARCHAR2 (100);
      V_APP_BY                  CLCHGWAIVERHIST.CLCHGWAIVHIST_APPROVAL_BY%TYPE;
      V_REF_NUM                 CLCHGWAIVERHIST.CLCHGWAIVHIST_REF_NUM%TYPE;
      V_DATED                   DATE;
      V_NOTES                   VARCHAR2 (1000);
      V_ENTERED_BY              CLCHGWAIVERHIST.CLCHGWAIVHIST_ENTD_BY%TYPE;
      V_BRN_CODE                CLIENTS.CLIENTS_HOME_BRN_CODE%TYPE;
      V_CHGCD_CHARGE_DESCN      VARCHAR2 (1000);
      V_SQL_CLI_AC              VARCHAR2 (32767);
      V_LATEST_EFFECTIVE_DATE   DATE;
      V_NUM_OF_RECORDS          NUMBER;
      W_BRN_CODE                NUMBER;
   BEGIN
      W_BRN_CODE := NVL (P_BRN_CODE, 0);


      V_SQL_1_1 :=
         'SELECT CLCHGWAIVHIST_CLIENT_NUM,
      CLCHGWAIVHIST_INT_ACNUM CLCHGWAIV_ACNUM,
      CLIENTS_NAME ACC_CLIENT_NAME,
      NULL AC_TYPE,
      CLCHGWAIVHIST_EFF_DATE,
      CLCHGWAIVHIST_APPROVAL_BY,
      CLCHGWAIVHIST_REF_NUM,
      CLCHGWAIVHIST_DATED,
      CLCHGWAIVHIST_NOTES1 || CLCHGWAIVHIST_NOTES2 || CLCHGWAIVHIST_NOTES3
      CLCHGWAIVHIST_NOTES,
      CLCHGWAIVHIST_WAIVE_REQD,
      CLCHGWAIVDTHIST_CHARGE_CODE,
      (SELECT CHGCD_CHARGE_DESCN
         FROM CHGCD
        WHERE CHGCD_CHARGE_CODE = CLCHGWAIVDTHIST_CHARGE_CODE)
         CHG_CODE_DESC,
      CLCHGWAIVDTHIST_WAIVER_TYPE,
      CLCHGWAIVDTHIST_DISCOUNT_PER,
      CLCHGWAIVHIST_ENTD_BY,
      CLIENTS_HOME_BRN_CODE
 FROM CLCHGWAIVERHIST, CLCHGWAIVEDTLHIST, CLIENTS
WHERE     CLCHGWAIVHIST_ENTITY_NUM = CLCHGWAIVDTHIST_ENTITY_NUM
      AND CLCHGWAIVHIST_ENTITY_NUM = :ENTITY_NUM
      AND CLCHGWAIVHIST_CLIENT_NUM = CLCHGWAIVDTHIST_CLIENT_NUM
      AND CLCHGWAIVHIST_INT_ACNUM = CLCHGWAIVDTHIST_INT_ACNUM
      AND CLCHGWAIVHIST_EFF_DATE = CLCHGWAIVDTHIST_EFF_DATE
      AND CLCHGWAIVHIST_WAIVE_REQD = ''1''
      AND CLIENTS_CODE = CLCHGWAIVHIST_CLIENT_NUM
      AND NVL (CLCHGWAIVHIST_CLIENT_NUM, 0) <> 0
      AND NVL (CLCHGWAIVDTHIST_INT_ACNUM, 0) = 0';

      IF W_BRN_CODE <> 0
      THEN
         V_SQL_1_1 :=
               V_SQL_1_1
            || '
              AND CLIENTS_HOME_BRN_CODE IN (  SELECT MBRN_CODE
              FROM MBRN
        START WITH MBRN_CODE = :P_BRN_CODE
        CONNECT BY PRIOR MBRN_CODE = MBRN_PARENT_ADMIN_CODE)';
      END IF;

      V_SQL_1_2 :=
         'SELECT ACNTS_CLIENT_NUM CLCHGWAIVHIST_CLIENT_NUM,
      CLCHGWAIVHIST_INT_ACNUM CLCHGWAIV_ACNUM,
      ACNTS_AC_NAME1 || ACNTS_AC_NAME2 ACC_CLIENT_NAME,
      (SELECT ACTYPE_CODE || '' - '' || ACTYPE_DESCN
         FROM ACTYPES
        WHERE ACTYPE_CODE = ACNTS_AC_TYPE)
         AC_TYPE,
      CLCHGWAIVHIST_EFF_DATE,
      CLCHGWAIVHIST_APPROVAL_BY,
      CLCHGWAIVHIST_REF_NUM,
      CLCHGWAIVHIST_DATED,
      CLCHGWAIVHIST_NOTES1 || CLCHGWAIVHIST_NOTES2 || CLCHGWAIVHIST_NOTES3
         CLCHGWAIVHIST_NOTES,
      CLCHGWAIVHIST_WAIVE_REQD,
      CLCHGWAIVDTHIST_CHARGE_CODE,
      (SELECT CHGCD_CHARGE_DESCN
         FROM CHGCD
        WHERE CHGCD_CHARGE_CODE = CLCHGWAIVDTHIST_CHARGE_CODE)
         CHG_CODE_DESC,
      CLCHGWAIVDTHIST_WAIVER_TYPE,
      CLCHGWAIVDTHIST_DISCOUNT_PER,
      CLCHGWAIVHIST_ENTD_BY,
      ACNTS_BRN_CODE CLIENTS_HOME_BRN_CODE
 FROM CLCHGWAIVERHIST, CLCHGWAIVEDTLHIST, ACNTS
WHERE     CLCHGWAIVHIST_ENTITY_NUM = CLCHGWAIVDTHIST_ENTITY_NUM
      AND CLCHGWAIVHIST_ENTITY_NUM = :ENTITY_NUM
      AND CLCHGWAIVHIST_CLIENT_NUM = CLCHGWAIVDTHIST_CLIENT_NUM
      AND CLCHGWAIVHIST_INT_ACNUM = CLCHGWAIVDTHIST_INT_ACNUM
       AND CLCHGWAIVHIST_EFF_DATE = CLCHGWAIVDTHIST_EFF_DATE
      AND CLCHGWAIVHIST_WAIVE_REQD = ''1''
      AND ACNTS_ENTITY_NUM = :ENTITY_NUM 
      AND NVL (CLCHGWAIVDTHIST_INT_ACNUM, 0) <> 0
      AND NVL (CLCHGWAIVHIST_CLIENT_NUM, 0) = 0
      AND ACNTS_INTERNAL_ACNUM = CLCHGWAIVDTHIST_INT_ACNUM ';

      IF W_BRN_CODE <> 0
      THEN
         V_SQL_1_2 :=
               V_SQL_1_2
            || '
              AND ACNTS_BRN_CODE IN (  SELECT MBRN_CODE
      FROM MBRN
START WITH MBRN_CODE = :P_BRN_CODE
CONNECT BY PRIOR MBRN_CODE = MBRN_PARENT_ADMIN_CODE)';
      END IF;


      V_SQL_1_3 :=
         'SELECT CLCHGWAIVHIST_CLIENT_NUM,
       CLCHGWAIVHIST_INT_ACNUM CLCHGWAIV_ACNUM,
       CLIENTS_NAME ACC_CLIENT_NAME,
       NULL AC_TYPE,
       CLCHGWAIVHIST_EFF_DATE,
       CLCHGWAIVHIST_APPROVAL_BY,
       CLCHGWAIVHIST_REF_NUM,
       CLCHGWAIVHIST_DATED,
       CLCHGWAIVHIST_NOTES1 || CLCHGWAIVHIST_NOTES2 || CLCHGWAIVHIST_NOTES3
          CLCHGWAIVHIST_NOTES,
       CLCHGWAIVHIST_WAIVE_REQD,
       '''' CLCHGWAIVDTHIST_CHARGE_CODE,
       '''' CHG_CODE_DESC,
       '''' CLCHGWAIVDTHIST_WAIVER_TYPE,
       0 CLCHGWAIVDTHIST_DISCOUNT_PER,
       CLCHGWAIVHIST_ENTD_BY,
       CLIENTS_HOME_BRN_CODE
  FROM CLCHGWAIVERHIST, CLIENTS
 WHERE     CLCHGWAIVHIST_ENTITY_NUM = :ENTITY_NUM
       AND CLCHGWAIVHIST_WAIVE_REQD = ''0''
       AND CLIENTS_CODE = CLCHGWAIVHIST_CLIENT_NUM
       AND NVL (CLCHGWAIVHIST_CLIENT_NUM, 0) <> 0
       AND NVL (CLCHGWAIVHIST_INT_ACNUM, 0) = 0';


      IF W_BRN_CODE <> 0
      THEN
         V_SQL_1_3 :=
               V_SQL_1_3
            || '
              AND CLIENTS_HOME_BRN_CODE IN (  SELECT MBRN_CODE
      FROM MBRN
START WITH MBRN_CODE = :P_BRN_CODE
CONNECT BY PRIOR MBRN_CODE = MBRN_PARENT_ADMIN_CODE) ';
      END IF;


      V_SQL_1_4 :=
         'SELECT ACNTS_CLIENT_NUM CLCHGWAIVHIST_CLIENT_NUM,
       CLCHGWAIVHIST_INT_ACNUM CLCHGWAIV_ACNUM,
       ACNTS_AC_NAME1 || ACNTS_AC_NAME2 ACC_CLIENT_NAME,
       (SELECT ACTYPE_CODE || '' - '' || ACTYPE_DESCN
         FROM ACTYPES
        WHERE ACTYPE_CODE = ACNTS_AC_TYPE)
          AC_TYPE,
       CLCHGWAIVHIST_EFF_DATE,
       CLCHGWAIVHIST_APPROVAL_BY,
       CLCHGWAIVHIST_REF_NUM,
       CLCHGWAIVHIST_DATED,
       CLCHGWAIVHIST_NOTES1 || CLCHGWAIVHIST_NOTES1 || CLCHGWAIVHIST_NOTES1
          CLCHGWAIVHIST_NOTES,
       CLCHGWAIVHIST_WAIVE_REQD,
       '''' CHG_CODE,
       '''' CHG_CODE_DESC,
       '''' CLCHGWAIVDTHIST_WAIVER_TYPE,
       0 CLCHGWAIVDTHIST_DISCOUNT_PER,
       CLCHGWAIVHIST_ENTD_BY,
       ACNTS_BRN_CODE CLIENTS_HOME_BRN_CODE
  FROM CLCHGWAIVERHIST, ACNTS
 WHERE     CLCHGWAIVHIST_ENTITY_NUM = :ENTITY_NUM
       AND ACNTS_ENTITY_NUM = :ENTITY_NUM
       AND CLCHGWAIVHIST_WAIVE_REQD = ''0''
       AND NVL (CLCHGWAIVHIST_INT_ACNUM, 0) <> 0
       AND NVL (CLCHGWAIVHIST_CLIENT_NUM, 0) = 0
       AND ACNTS_INTERNAL_ACNUM = CLCHGWAIVHIST_INT_ACNUM ';


      IF W_BRN_CODE <> 0
      THEN
         V_SQL_1_4 :=
               V_SQL_1_4
            || '
              AND ACNTS_BRN_CODE IN (  SELECT MBRN_CODE
      FROM MBRN
START WITH MBRN_CODE = :P_BRN_CODE
CONNECT BY PRIOR MBRN_CODE = MBRN_PARENT_ADMIN_CODE)';
      END IF;


      IF P_RPT_TYPE = '1'
      THEN
         V_SQL1 :=
               V_SQL_1_1
            || '
            AND CLCHGWAIVHIST_EFF_DATE BETWEEN :P_FROM_DATE AND :P_TO_DATE
               UNION ALL
            '
            || V_SQL_1_2
            || '
            AND CLCHGWAIVHIST_EFF_DATE BETWEEN :P_FROM_DATE AND :P_TO_DATE
            ';
      ELSIF P_RPT_TYPE = '2'
      THEN
         V_SQL1 :=
               V_SQL_1_3
            || '
            AND CLCHGWAIVHIST_EFF_DATE BETWEEN :P_FROM_DATE AND :P_TO_DATE
               UNION ALL
            '
            || V_SQL_1_4
            || '
            AND CLCHGWAIVHIST_EFF_DATE BETWEEN :P_FROM_DATE AND :P_TO_DATE
            ';
      ELSE
         V_SQL1 :=
               V_SQL_1_1
            || '
            AND CLCHGWAIVHIST_EFF_DATE BETWEEN :P_FROM_DATE AND :P_TO_DATE
               UNION ALL
            '
            || V_SQL_1_2
            || '
            AND CLCHGWAIVHIST_EFF_DATE BETWEEN :P_FROM_DATE AND :P_TO_DATE
               UNION ALL
            '
            || V_SQL_1_3
            || '
            AND CLCHGWAIVHIST_EFF_DATE BETWEEN :P_FROM_DATE AND :P_TO_DATE
               UNION ALL
            '
            || V_SQL_1_4
            || '
            AND CLCHGWAIVHIST_EFF_DATE BETWEEN :P_FROM_DATE AND :P_TO_DATE
            ';
      END IF;

      V_SQL2 :=
            ' SELECT DISTINCT CLCHGWAIVHIST_CLIENT_NUM, CLCHGWAIV_ACNUM, CLCHGWAIVHIST_EFF_DATE, CLCHGWAIVHIST_WAIVE_REQD FROM (
'
         || V_SQL1
         || ')
      ORDER BY CLCHGWAIVHIST_CLIENT_NUM, CLCHGWAIV_ACNUM, CLCHGWAIVHIST_EFF_DATE ';

      DBMS_OUTPUT.PUT_LINE (V_SQL2);


      IF P_RPT_TYPE = '1' OR P_RPT_TYPE = '2'
      THEN
         IF W_BRN_CODE <> 0
         THEN
            EXECUTE IMMEDIATE V_SQL2
               BULK COLLECT INTO V_TY_DIST_VALUE
               USING P_ENTITYNUM,
                     W_BRN_CODE,
                     P_FROM_DATE,
                     P_TO_DATE,
                     P_ENTITYNUM,
                     P_ENTITYNUM,
                     W_BRN_CODE,
                     P_FROM_DATE,
                     P_TO_DATE;
         ELSE
            EXECUTE IMMEDIATE V_SQL2
               BULK COLLECT INTO V_TY_DIST_VALUE
               USING P_ENTITYNUM,
                     P_FROM_DATE,
                     P_TO_DATE,
                     P_ENTITYNUM,
                     P_ENTITYNUM,
                     P_FROM_DATE,
                     P_TO_DATE;
         END IF;
      ELSE
         IF W_BRN_CODE <> 0
         THEN
            EXECUTE IMMEDIATE V_SQL2
               BULK COLLECT INTO V_TY_DIST_VALUE
               USING P_ENTITYNUM,
                     W_BRN_CODE,
                     P_FROM_DATE,
                     P_TO_DATE,
                     P_ENTITYNUM,
                     P_ENTITYNUM,
                     W_BRN_CODE,
                     P_FROM_DATE,
                     P_TO_DATE,
                     P_ENTITYNUM,
                     W_BRN_CODE,
                     P_FROM_DATE,
                     P_TO_DATE,
                     P_ENTITYNUM,
                     P_ENTITYNUM,
                     W_BRN_CODE,
                     P_FROM_DATE,
                     P_TO_DATE;
         ELSE
            EXECUTE IMMEDIATE V_SQL2
               BULK COLLECT INTO V_TY_DIST_VALUE
               USING P_ENTITYNUM,
                     P_FROM_DATE,
                     P_TO_DATE,
                     P_ENTITYNUM,
                     P_ENTITYNUM,
                     P_FROM_DATE,
                     P_TO_DATE,
                     P_ENTITYNUM,
                     P_FROM_DATE,
                     P_TO_DATE,
                     P_ENTITYNUM,
                     P_ENTITYNUM,
                     P_FROM_DATE,
                     P_TO_DATE;
         END IF;
      END IF;

      V_NUM_OF_RECORDS := V_TY_DIST_VALUE.COUNT;

      IF V_TY_DIST_VALUE.COUNT > 0
      THEN
         FOR IDX IN V_TY_DIST_VALUE.FIRST .. V_TY_DIST_VALUE.LAST
         LOOP
            IF     V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_CLIENT_NUM <> 1000
               AND V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM = 11909100007378
            THEN
               NULL;
            END IF;

            IF V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_WAIVE_REQD = '1'
            THEN
               IF V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM <> 0
               THEN
                  V_SQL_CLI_AC :=
                        V_SQL_1_2
                     || '   AND CLCHGWAIVHIST_EFF_DATE = :EFFECTIVE_DATE
                            AND ACNTS_INTERNAL_ACNUM = '
                     || V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM;

                  IF W_BRN_CODE <> 0
                  THEN
                     EXECUTE IMMEDIATE V_SQL_CLI_AC
                        BULK COLLECT INTO V_TY_AC_VALUE_DTL
                        USING P_ENTITYNUM,
                              P_ENTITYNUM,
                              W_BRN_CODE,
                              V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                  ELSE
                     EXECUTE IMMEDIATE V_SQL_CLI_AC
                        BULK COLLECT INTO V_TY_AC_VALUE_DTL
                        USING P_ENTITYNUM,
                              P_ENTITYNUM,
                              V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                  END IF;
               ELSE
                  V_SQL_CLI_AC :=
                        V_SQL_1_1
                     || '   AND CLCHGWAIVHIST_EFF_DATE = :EFFECTIVE_DATE
                            AND CLIENTS_CODE = '
                     || V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_CLIENT_NUM;

                  IF W_BRN_CODE <> 0
                  THEN
                     EXECUTE IMMEDIATE V_SQL_CLI_AC
                        BULK COLLECT INTO V_TY_AC_VALUE_DTL
                        USING P_ENTITYNUM,
                              W_BRN_CODE,
                              V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                  ELSE
                     EXECUTE IMMEDIATE V_SQL_CLI_AC
                        BULK COLLECT INTO V_TY_AC_VALUE_DTL
                        USING P_ENTITYNUM,
                              V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                  END IF;
               END IF;


               IF V_TY_AC_VALUE_DTL.COUNT > 0
               THEN
                  FOR INX IN V_TY_AC_VALUE_DTL.FIRST ..
                             V_TY_AC_VALUE_DTL.LAST
                  LOOP
                     TABLE2.CLCHGWAIVHIST_CLIENT_NUM :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVHIST_CLIENT_NUM;
                     TABLE2.CLCHGWAIV_ACNUM :=
                        FACNO (P_ENTITYNUM,
                               V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIV_ACNUM);
                     TABLE2.ACC_CLIENT_NAME :=
                        V_TY_AC_VALUE_DTL (INX).TM_ACC_CLIENT_NAME;
                     TABLE2.AC_TYPE := V_TY_AC_VALUE_DTL (INX).TM_AC_TYPE;
                     TABLE2.CLCHGWAIVHIST_EFF_DATE :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVHIST_EFF_DATE;
                     TABLE2.CLCHGWAIVHIST_APPROVAL_BY :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVHIST_APPROVAL_BY;
                     TABLE2.CLCHGWAIVHIST_REF_NUM :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVHIST_REF_NUM;
                     TABLE2.CLCHGWAIVHIST_DATED :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVHIST_DATED;
                     TABLE2.CLCHGWAIVHIST_NOTES :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVHIST_NOTES;
                     TABLE2.CLCHGWAIVHIST_WAIVE_REQD :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVHIST_WAIVE_REQD;
                     TABLE2.CLCHGWAIVDTHIST_CHARGE_CODE :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_CHARGE_CODE;
                     TABLE2.CHG_CODE_DESC :=
                        V_TY_AC_VALUE_DTL (INX).TM_CHG_CODE_DESC;
                     TABLE2.CLCHGWAIVDTHIST_WAIVER_TYPE :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_WAIVER_TYPE;
                     TABLE2.CLCHGWAIVDTHIST_DISCOUNT_PER :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_DISCOUNT_PE;
                     TABLE2.CLCHGWAIVDTHIST_USER_ID :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_USER_ID;
                     TABLE2.CLCHGWAIVDTHIST_BRN_CODE :=
                        V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_BRN_CODE;

                     PIPE ROW (TABLE2);
                  END LOOP;
               END IF;
            ELSE
               IF V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM <> '0'
               THEN
                  SELECT MAX (CLCHGWAIVHIST_EFF_DATE)
                    INTO V_LATEST_EFFECTIVE_DATE
                    FROM CLCHGWAIVERHIST
                   WHERE     CLCHGWAIVHIST_ENTITY_NUM = P_ENTITYNUM
                         AND CLCHGWAIVHIST_INT_ACNUM =
                                V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM
                         AND CLCHGWAIVHIST_EFF_DATE <
                                V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE
                         AND CLCHGWAIVHIST_WAIVE_REQD = '1';

                  BEGIN
                     IF W_BRN_CODE <> 0
                     THEN
                        EXECUTE IMMEDIATE
                              'SELECT
                  DISTINCT CLCHGWAIVHIST_CLIENT_NUM,
                  ACC_CLIENT_NAME,
                  AC_TYPE,
                  CLCHGWAIVHIST_APPROVAL_BY,
                  CLCHGWAIVHIST_REF_NUM,
                  CLCHGWAIVHIST_DATED,
                  CLCHGWAIVHIST_NOTES,
                  CLCHGWAIVHIST_ENTD_BY,
                  CLIENTS_HOME_BRN_CODE
                   FROM ( '
                           || V_SQL_1_4
                           || ' AND CLCHGWAIVHIST_EFF_DATE = :EFFECTIVE_DATE
                          AND ACNTS_INTERNAL_ACNUM = '
                           || V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM
                           || ')'
                           INTO V_CLIENT_NUM,
                                V_NAME,
                                V_AC_TYPE,
                                V_APP_BY,
                                V_REF_NUM,
                                V_DATED,
                                V_NOTES,
                                V_ENTERED_BY,
                                V_BRN_CODE
                           USING P_ENTITYNUM,
                                 P_ENTITYNUM,
                                 W_BRN_CODE,
                                 V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                     ELSE
                        EXECUTE IMMEDIATE
                              'SELECT
                  DISTINCT CLCHGWAIVHIST_CLIENT_NUM,
                  ACC_CLIENT_NAME,
                  AC_TYPE,
                  CLCHGWAIVHIST_APPROVAL_BY,
                  CLCHGWAIVHIST_REF_NUM,
                  CLCHGWAIVHIST_DATED,
                  CLCHGWAIVHIST_NOTES,
                  CLCHGWAIVHIST_ENTD_BY,
                  CLIENTS_HOME_BRN_CODE
                   FROM ( '
                           || V_SQL_1_4
                           || ' AND CLCHGWAIVHIST_EFF_DATE = :EFFECTIVE_DATE
                          AND ACNTS_INTERNAL_ACNUM = '
                           || V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM
                           || ')'
                           INTO V_CLIENT_NUM,
                                V_NAME,
                                V_AC_TYPE,
                                V_APP_BY,
                                V_REF_NUM,
                                V_DATED,
                                V_NOTES,
                                V_ENTERED_BY,
                                V_BRN_CODE
                           USING P_ENTITYNUM,
                                 P_ENTITYNUM,
                                 V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        V_CLIENT_NUM := NULL;
                        V_NAME := NULL;
                        V_AC_TYPE := NULL;
                        V_APP_BY := NULL;
                        V_REF_NUM := NULL;
                        V_DATED := NULL;
                        V_NOTES := NULL;
                        V_ENTERED_BY := NULL;
                        V_BRN_CODE := NULL;
                  END;

                  IF V_LATEST_EFFECTIVE_DATE IS NULL
                  THEN
                     V_LATEST_EFFECTIVE_DATE :=
                        V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;


                     TABLE2.CLCHGWAIVHIST_CLIENT_NUM := V_CLIENT_NUM;
                     TABLE2.CLCHGWAIV_ACNUM :=
                        FACNO (P_ENTITYNUM,
                               V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM);
                     TABLE2.ACC_CLIENT_NAME := V_NAME;
                     TABLE2.AC_TYPE := V_AC_TYPE;
                     TABLE2.CLCHGWAIVHIST_EFF_DATE := V_LATEST_EFFECTIVE_DATE;
                     TABLE2.CLCHGWAIVHIST_APPROVAL_BY := V_APP_BY;
                     TABLE2.CLCHGWAIVHIST_REF_NUM := V_REF_NUM;
                     TABLE2.CLCHGWAIVHIST_DATED := V_DATED;
                     TABLE2.CLCHGWAIVHIST_NOTES := V_NOTES;
                     TABLE2.CLCHGWAIVHIST_WAIVE_REQD := 0;
                     TABLE2.CLCHGWAIVDTHIST_CHARGE_CODE := '';
                     TABLE2.CHG_CODE_DESC := '';
                     TABLE2.CLCHGWAIVDTHIST_WAIVER_TYPE := '';
                     TABLE2.CLCHGWAIVDTHIST_DISCOUNT_PER := '';
                     TABLE2.CLCHGWAIVDTHIST_USER_ID := V_ENTERED_BY;
                     TABLE2.CLCHGWAIVDTHIST_BRN_CODE := V_BRN_CODE;
                     --V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_USER_ID;
                     PIPE ROW (TABLE2);
                  END IF;



                  FOR INX
                     IN (SELECT *
                           FROM CLCHGWAIVEDTLHIST
                          WHERE     CLCHGWAIVDTHIST_ENTITY_NUM = P_ENTITYNUM
                                AND CLCHGWAIVDTHIST_EFF_DATE =
                                       V_LATEST_EFFECTIVE_DATE
                                AND CLCHGWAIVDTHIST_INT_ACNUM =
                                       V_TY_DIST_VALUE (IDX).T_CLCHGWAIV_ACNUM)
                  LOOP
                     SELECT CHGCD_CHARGE_DESCN
                       INTO V_CHGCD_CHARGE_DESCN
                       FROM CHGCD
                      WHERE CHGCD_CHARGE_CODE =
                               INX.CLCHGWAIVDTHIST_CHARGE_CODE;

                     TABLE2.CLCHGWAIVHIST_CLIENT_NUM := V_CLIENT_NUM;
                     TABLE2.CLCHGWAIV_ACNUM :=
                        FACNO (P_ENTITYNUM, INX.CLCHGWAIVDTHIST_INT_ACNUM);
                     TABLE2.ACC_CLIENT_NAME := V_NAME;
                     TABLE2.AC_TYPE := V_AC_TYPE;
                     TABLE2.CLCHGWAIVHIST_EFF_DATE :=
                        V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                     TABLE2.CLCHGWAIVHIST_APPROVAL_BY := V_APP_BY;
                     TABLE2.CLCHGWAIVHIST_REF_NUM := V_REF_NUM;
                     TABLE2.CLCHGWAIVHIST_DATED := V_DATED;
                     TABLE2.CLCHGWAIVHIST_NOTES := V_NOTES;
                     TABLE2.CLCHGWAIVHIST_WAIVE_REQD := 0;
                     TABLE2.CLCHGWAIVDTHIST_CHARGE_CODE :=
                        INX.CLCHGWAIVDTHIST_CHARGE_CODE;
                     TABLE2.CHG_CODE_DESC := V_CHGCD_CHARGE_DESCN;
                     TABLE2.CLCHGWAIVDTHIST_WAIVER_TYPE :=
                        INX.CLCHGWAIVDTHIST_WAIVER_TYPE;
                     TABLE2.CLCHGWAIVDTHIST_DISCOUNT_PER :=
                        INX.CLCHGWAIVDTHIST_DISCOUNT_PER;
                     TABLE2.CLCHGWAIVDTHIST_USER_ID := V_ENTERED_BY;
                     TABLE2.CLCHGWAIVDTHIST_BRN_CODE := V_BRN_CODE;
                     --V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_USER_ID;
                     PIPE ROW (TABLE2);
                  END LOOP;
               ELSE
                  SELECT MAX (CLCHGWAIVHIST_EFF_DATE)
                    INTO V_LATEST_EFFECTIVE_DATE
                    FROM CLCHGWAIVERHIST
                   WHERE     CLCHGWAIVHIST_ENTITY_NUM = P_ENTITYNUM
                         AND CLCHGWAIVHIST_CLIENT_NUM =
                                V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_CLIENT_NUM
                         AND CLCHGWAIVHIST_EFF_DATE <
                                V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE
                         AND CLCHGWAIVHIST_WAIVE_REQD = '1'
                         AND CLCHGWAIVHIST_INT_ACNUM = 0;

                  BEGIN
                     IF W_BRN_CODE <> 0
                     THEN
                        EXECUTE IMMEDIATE
                              'SELECT
                  DISTINCT CLCHGWAIVHIST_CLIENT_NUM,
                  ACC_CLIENT_NAME,
                  AC_TYPE,
                  CLCHGWAIVHIST_APPROVAL_BY,
                  CLCHGWAIVHIST_REF_NUM,
                  CLCHGWAIVHIST_DATED,
                  CLCHGWAIVHIST_NOTES,
                  CLCHGWAIVHIST_ENTD_BY,
                  CLIENTS_HOME_BRN_CODE
                   FROM ( '
                           || V_SQL_1_3
                           || ' AND CLCHGWAIVHIST_EFF_DATE = :EFFECTIVE_DATE
                          AND CLIENTS_CODE = '
                           || V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_CLIENT_NUM
                           || ')'
                           INTO V_CLIENT_NUM,
                                V_NAME,
                                V_AC_TYPE,
                                V_APP_BY,
                                V_REF_NUM,
                                V_DATED,
                                V_NOTES,
                                V_ENTERED_BY,
                                V_BRN_CODE
                           USING P_ENTITYNUM,
                                 W_BRN_CODE,
                                 V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                     ELSE
                        EXECUTE IMMEDIATE
                              'SELECT
                  DISTINCT CLCHGWAIVHIST_CLIENT_NUM,
                  ACC_CLIENT_NAME,
                  AC_TYPE,
                  CLCHGWAIVHIST_APPROVAL_BY,
                  CLCHGWAIVHIST_REF_NUM,
                  CLCHGWAIVHIST_DATED,
                  CLCHGWAIVHIST_NOTES,
                  CLCHGWAIVHIST_ENTD_BY,
                  CLIENTS_HOME_BRN_CODE
                   FROM ( '
                           || V_SQL_1_3
                           || ' AND CLCHGWAIVHIST_EFF_DATE = :EFFECTIVE_DATE
                          AND CLIENTS_CODE = '
                           || V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_CLIENT_NUM
                           || ')'
                           INTO V_CLIENT_NUM,
                                V_NAME,
                                V_AC_TYPE,
                                V_APP_BY,
                                V_REF_NUM,
                                V_DATED,
                                V_NOTES,
                                V_ENTERED_BY,
                                V_BRN_CODE
                           USING P_ENTITYNUM,
                                 V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        V_CLIENT_NUM := NULL;
                        V_NAME := NULL;
                        V_AC_TYPE := NULL;
                        V_APP_BY := NULL;
                        V_REF_NUM := NULL;
                        V_DATED := NULL;
                        V_NOTES := NULL;
                        V_ENTERED_BY := NULL;
                        V_BRN_CODE := NULL;
                  END;

                  IF V_LATEST_EFFECTIVE_DATE IS NULL
                  THEN
                     V_LATEST_EFFECTIVE_DATE :=
                        V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;


                     TABLE2.CLCHGWAIVHIST_CLIENT_NUM := V_CLIENT_NUM;
                     TABLE2.CLCHGWAIV_ACNUM := 0;
                     TABLE2.ACC_CLIENT_NAME := V_NAME;
                     TABLE2.AC_TYPE := V_AC_TYPE;
                     TABLE2.CLCHGWAIVHIST_EFF_DATE := V_LATEST_EFFECTIVE_DATE;
                     TABLE2.CLCHGWAIVHIST_APPROVAL_BY := V_APP_BY;
                     TABLE2.CLCHGWAIVHIST_REF_NUM := V_REF_NUM;
                     TABLE2.CLCHGWAIVHIST_DATED := V_DATED;
                     TABLE2.CLCHGWAIVHIST_NOTES := V_NOTES;
                     TABLE2.CLCHGWAIVHIST_WAIVE_REQD := 0;
                     TABLE2.CLCHGWAIVDTHIST_CHARGE_CODE := '';
                     TABLE2.CHG_CODE_DESC := '';
                     TABLE2.CLCHGWAIVDTHIST_WAIVER_TYPE := '';
                     TABLE2.CLCHGWAIVDTHIST_DISCOUNT_PER := '';
                     TABLE2.CLCHGWAIVDTHIST_USER_ID := V_ENTERED_BY;
                     TABLE2.CLCHGWAIVDTHIST_BRN_CODE := V_BRN_CODE;
                     --V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_USER_ID;
                     PIPE ROW (TABLE2);
                  END IF;


                  FOR INX
                     IN (SELECT *
                           FROM CLCHGWAIVEDTLHIST
                          WHERE     CLCHGWAIVDTHIST_ENTITY_NUM = P_ENTITYNUM
                                AND CLCHGWAIVDTHIST_EFF_DATE =
                                       V_LATEST_EFFECTIVE_DATE
                                AND CLCHGWAIVDTHIST_CLIENT_NUM =
                                       V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_CLIENT_NUM
                                AND CLCHGWAIVDTHIST_INT_ACNUM = 0)
                  LOOP
                     SELECT CHGCD_CHARGE_DESCN
                       INTO V_CHGCD_CHARGE_DESCN
                       FROM CHGCD
                      WHERE CHGCD_CHARGE_CODE =
                               INX.CLCHGWAIVDTHIST_CHARGE_CODE;

                     TABLE2.CLCHGWAIVHIST_CLIENT_NUM := V_CLIENT_NUM;
                     TABLE2.CLCHGWAIV_ACNUM :=
                        FACNO (P_ENTITYNUM, INX.CLCHGWAIVDTHIST_INT_ACNUM);
                     TABLE2.ACC_CLIENT_NAME := V_NAME;
                     TABLE2.AC_TYPE := V_AC_TYPE;
                     TABLE2.CLCHGWAIVHIST_EFF_DATE :=
                        V_TY_DIST_VALUE (IDX).T_CLCHGWAIVHIST_EFF_DATE;
                     TABLE2.CLCHGWAIVHIST_APPROVAL_BY := V_APP_BY;
                     TABLE2.CLCHGWAIVHIST_REF_NUM := V_REF_NUM;
                     TABLE2.CLCHGWAIVHIST_DATED := V_DATED;
                     TABLE2.CLCHGWAIVHIST_NOTES := V_NOTES;
                     TABLE2.CLCHGWAIVHIST_WAIVE_REQD := 0;
                     TABLE2.CLCHGWAIVDTHIST_CHARGE_CODE :=
                        INX.CLCHGWAIVDTHIST_CHARGE_CODE;
                     TABLE2.CHG_CODE_DESC := V_CHGCD_CHARGE_DESCN;
                     TABLE2.CLCHGWAIVDTHIST_WAIVER_TYPE :=
                        INX.CLCHGWAIVDTHIST_WAIVER_TYPE;
                     TABLE2.CLCHGWAIVDTHIST_DISCOUNT_PER :=
                        INX.CLCHGWAIVDTHIST_DISCOUNT_PER;
                     TABLE2.CLCHGWAIVDTHIST_USER_ID := V_ENTERED_BY;
                     TABLE2.CLCHGWAIVDTHIST_BRN_CODE := V_BRN_CODE;
                     --V_TY_AC_VALUE_DTL (INX).TM_CLCHGWAIVDTHIST_USER_ID;
                     PIPE ROW (TABLE2);
                  END LOOP;
               END IF;
            END IF;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         W_ERROR_MSG := SUBSTR (SQLERRM, 1, 50);
         RAISE;
   END;
END PKG_CLCHGWAIVERHIST_REPORT;
/

CREATE OR REPLACE PROCEDURE SP_CL_INSERT_DATA(P_ENTITY_NUM IN NUMBER,
                                              P_ASON_DATE  IN DATE,
                                              P_CBD        IN DATE,
                                              V_BRN_CODE   IN NUMBER) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  W_DATA_SQL CLOB;
  W_DATA_EXIST NUMBER:=0;
  P_BRN_CODE NUMBER;
  W_LOCK NUMBER;
BEGIN

 PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE(P_ENTITY_NUM,V_BRN_CODE);

 FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
  LOOP
      P_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN(IDX).LN_BRN_CODE;

    BEGIN

         BEGIN
         SELECT COUNT(*)
         INTO W_DATA_EXIST
         FROM CL_TMP_DATA_INV
         WHERE ENTITY_NUM=P_ENTITY_NUM
         AND   ASON_DATE=P_ASON_DATE
         AND   BRN_CODE=P_BRN_CODE;
        END;

        IF W_DATA_EXIST=0 THEN

         INSERT INTO CL_TMP_DATA_INV(ENTITY_NUM, ASON_DATE, BRN_CODE)
         VALUES (P_ENTITY_NUM, P_ASON_DATE, P_BRN_CODE);

         COMMIT;

             BEGIN
                SELECT 1
                INTO W_LOCK
                  FROM CL_TMP_DATA_INV
                 WHERE     ENTITY_NUM = P_ENTITY_NUM
                       AND ASON_DATE = P_ASON_DATE
                       AND BRN_CODE = P_BRN_CODE
                FOR UPDATE NOWAIT;
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
             END;

          IF NVL(P_BRN_CODE, 0) <> 0 THEN
           W_DATA_SQL := 'DELETE FROM CL_TMP_DATA CLS WHERE CLS.ACNTS_BRN_CODE = :1 AND ASON_DATE=:W_ASON_DATE';
            EXECUTE IMMEDIATE W_DATA_SQL
                USING P_BRN_CODE, P_ASON_DATE ;
          END IF ;

        W_DATA_SQL := 'INSERT INTO CL_TMP_DATA
            WITH ACCOUNT_LIST
                AS (SELECT ACA_BAL1.*,
                           NVL (LS.LNSUSPBAL_SUSP_BAL, 0) INT_SUSPENSE_AMT
                      FROM (SELECT ACNTS_ENTITY_NUM,
                                   A.ACNTS_BRN_CODE,
                                   A.ACNTS_INTERNAL_ACNUM,
                                   CASE
                                   WHEN FN_GET_RESHEDULE_LOAN_STATUS(A.ACNTS_INTERNAL_ACNUM,:P_BRN_CODE) = 1 THEN
                                   ''UC''
                                   ELSE
                                   AD.ASSETCD_CONC_DESCN
                                   END AS ASSETCD_CONC_DESCN,
                                   LN.LNACMIS_HO_DEPT_CODE,
                                   CL.REPORT_DESC,
                                    CASE
                                   WHEN FN_GET_RESHEDULE_LOAN_STATUS(A.ACNTS_INTERNAL_ACNUM,:P_BRN_CODE) = 1 THEN
                                   ''P''
                                   ELSE
                                   AD.ASSETCD_ASSET_CLASS
                                   END AS ASSETCD_ASSET_CLASS,
                                     CASE
                                   WHEN FN_GET_RESHEDULE_LOAN_STATUS(A.ACNTS_INTERNAL_ACNUM,:P_BRN_CODE) = 1 THEN
                                   ''1''
                                   ELSE
                                   AD.ASSETCD_PERF_CAT
                                   END AS ASSETCD_PERF_CAT,
                                     CASE
                                   WHEN FN_GET_RESHEDULE_LOAN_STATUS(A.ACNTS_INTERNAL_ACNUM,:P_BRN_CODE) = 1 THEN
                                   '' ''
                                   ELSE
                                   AD.ASSETCD_NONPERF_CAT
                                   END AS ASSETCD_NONPERF_CAT,
                                   FN_GET_ASON_DR_OR_CR_BAL (A.ACNTS_ENTITY_NUM,
                                                             A.ACNTS_INTERNAL_ACNUM,
                                                             A.ACNTS_CURR_CODE,
                                                             :P_ASON_DATE,
                                                             :W_CBD,
                                                             ''D'',
                                                             0)
                                      ACBAL,
                                   PKG_CLREPORT.GET_SECURED_VALUE (
                                      ACNTS_INTERNAL_ACNUM,
                                      :P_ASON_DATE,
                                      :W_CBD,
                                      ''BDT'')
                                      SECURITY_AMOUNT,
                                   --CL21
                                   PROVLED_BC_PROV_AMT BC_PROV_AMT                 --,
                              -- NVL (LS.LNSUSPBAL_SUSP_BAL, 0) INT_SUSPENSE_AMT
                              FROM ASSETCLSHIST ACLSH,
                                   ASSETCD AD,
                                   ACNTS A,
                                   LNACMIS LN,
                                   CLREPORT CL,
                                   (  SELECT PROVLED_ENTITY_NUM,
                                             PROVLED_ACNT_NUM,
                                             SUM (
                                                NVL (
                                                   (CASE
                                                       WHEN PR.PROVLED_ENTRY_TYPE = ''P''
                                                       THEN
                                                          PR.PROVLED_BC_PROV_AMT
                                                       ELSE
                                                          (-1) * PR.PROVLED_BC_PROV_AMT
                                                    END),
                                                   0))
                                                PROVLED_BC_PROV_AMT
                                        FROM PROVLED PR
                                    GROUP BY PROVLED_ENTITY_NUM, PROVLED_ACNT_NUM) P
                             WHERE     ACNTS_ENTITY_NUM = 1
                                   AND LNACMIS_ENTITY_NUM = 1
                                   AND ASSETCLSH_ENTITY_NUM = 1
                                   AND ACNTS_BRN_CODE = DECODE(:P_BRN_CODE, 0, ACNTS_BRN_CODE, :P_BRN_CODE)
                                   AND ACLSH.ASSETCLSH_ASSET_CODE = AD.ASSETCD_CODE
                                   AND ACLSH.ASSETCLSH_INTERNAL_ACNUM =
                                          A.ACNTS_INTERNAL_ACNUM
                                   AND ACLSH.ASSETCLSH_INTERNAL_ACNUM NOT IN
                                          (SELECT L.LNWRTOFF_ACNT_NUM
                                             FROM LNWRTOFF L)
                                   AND A.ACNTS_OPENING_DATE <= :P_ASON_DATE
                                   AND (   A.ACNTS_CLOSURE_DATE IS NULL
                                        OR A.ACNTS_CLOSURE_DATE > :P_ASON_DATE)
                                   AND A.ACNTS_AUTH_ON IS NOT NULL
                                   AND LN.LNACMIS_INTERNAL_ACNUM =
                                          A.ACNTS_INTERNAL_ACNUM
                                   AND ACLSH.ASSETCLSH_EFF_DATE =
                                          (SELECT MAX (H.ASSETCLSH_EFF_DATE)
                                             FROM ASSETCLSHIST H
                                            WHERE     H.ASSETCLSH_INTERNAL_ACNUM =
                                                         A.ACNTS_INTERNAL_ACNUM
                                                  AND H.ASSETCLSH_EFF_DATE <=
                                                         :P_ASON_DATE)
                                   AND CL.REPORT_CODE = LNACMIS_HO_DEPT_CODE
                                   AND LN.LNACMIS_ENTITY_NUM =
                                          P.PROVLED_ENTITY_NUM(+)
                                   AND LN.LNACMIS_INTERNAL_ACNUM =
                                          P.PROVLED_ACNT_NUM(+)) ACA_BAL1,
                           LNSUSPBAL LS
                     WHERE     ACA_BAL1.ACNTS_INTERNAL_ACNUM =
                                  LS.LNSUSPBAL_ACNT_NUM(+)
                           AND ACA_BAL1.ACNTS_ENTITY_NUM = LS.LNSUSPBAL_ENTITY_NUM(+)),
                PROVCALC_DATA
                AS (SELECT PROVC_INTERNAL_ACNUM,
                           PROVC_ENTITY_NUM,
                           PROVC_PROV_ON_BAL_BC,
                           PROVC_PROC_DATE
                      FROM PROVCALC
                     WHERE PROVC_PROC_DATE = :P_ASON_DATE)
           SELECT DD.*, FN_GET_DEFAULT_AMT(DD.ACNTS_ENTITY_NUM,DD.ACNTS_INTERNAL_ACNUM,:P_ASON_DATE) DEAFAULT_AMT FROM (SELECT *
             FROM ACCOUNT_LIST, PROVCALC_DATA, (SELECT :P_ASON_DATE ASON_DATE FROM DUAL )
            WHERE     ACCOUNT_LIST.ACNTS_INTERNAL_ACNUM =
                         PROVCALC_DATA.PROVC_INTERNAL_ACNUM(+)
                  AND ACCOUNT_LIST.ACNTS_ENTITY_NUM =
                         PROVCALC_DATA.PROVC_ENTITY_NUM(+)
                  AND ACCOUNT_LIST.ACNTS_BRN_CODE =  DECODE(:P_BRN_CODE, 0, ACCOUNT_LIST.ACNTS_BRN_CODE, :P_BRN_CODE))DD';

        EXECUTE IMMEDIATE W_DATA_SQL
        USING  NVL(P_BRN_CODE, 0), NVL(P_BRN_CODE, 0), NVL(P_BRN_CODE, 0), NVL(P_BRN_CODE, 0),P_ASON_DATE, P_CBD, P_ASON_DATE, P_CBD, NVL(P_BRN_CODE, 0), NVL(P_BRN_CODE, 0), P_ASON_DATE, P_ASON_DATE, P_ASON_DATE,
        P_ASON_DATE,P_ASON_DATE,P_ASON_DATE, NVL(P_BRN_CODE, 0), NVL(P_BRN_CODE, 0);

        COMMIT;
        END IF;

    EXCEPTION
       WHEN OTHERS THEN
       DELETE   FROM CL_TMP_DATA_INV
         WHERE     ENTITY_NUM = P_ENTITY_NUM
               AND ASON_DATE = P_ASON_DATE
               AND BRN_CODE = P_BRN_CODE;

           W_DATA_SQL := 'DELETE FROM CL_TMP_DATA CLS WHERE CLS.ACNTS_BRN_CODE = :1 AND ASON_DATE=:W_ASON_DATE';
            EXECUTE IMMEDIATE W_DATA_SQL
                USING P_BRN_CODE, P_ASON_DATE ;
       COMMIT;

    END;

  END LOOP;

 COMMIT;

END;
/

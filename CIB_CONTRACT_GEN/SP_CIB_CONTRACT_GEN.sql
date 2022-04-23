CREATE OR REPLACE PROCEDURE SP_CIB_CONTRACT_GEN (P_BRN_CODE NUMBER, P_FROM_DATE DATE , P_TO_DATE DATE )
AS
   V_ERROR_MSG   VARCHAR2 (1000);
BEGIN
   BEGIN
      
         BEGIN
            INSERT INTO CIB_CONTRACT
               SELECT P_BRN_CODE BRANCH_CODE,
                      NULL PERIOD,
                      MBRN_BSR_CODE BRCODE,
                      CASE
                         WHEN PRODUCT_FOR_RUN_ACS = 0 THEN '2'
                         WHEN PRODUCT_FOR_RUN_ACS = 1 THEN '1'
                      END
                         "RECORD",
                      NULL BCODE,
                      NULL SFI_CODE,
                      NULL CONT_CODE,
                      FACNO (1, ACNTS_INTERNAL_ACNUM) ACC_NO,
                      --ACNTS_INTERNAL_ACNUM,
                      ACNTS_PROD_CODE PRODUCT_CODE,
                      PRODUCT_NAME,
                      ACNTS_AC_TYPE ACTYPE_CODE,
                      (SELECT ACTYPE_DESCN
                         FROM ACTYPES
                        WHERE ACTYPE_CODE = ACNTS_AC_TYPE)
                         ACTYPE_DESCN,
                      ACNTS_AC_SUB_TYPE ACSUB_SUBTYPE_CODE,
                      (SELECT ACSUB_DESCN
                         FROM ACSUBTYPES
                        WHERE     ACSUB_ACTYPE_CODE = ACNTS_AC_TYPE
                              AND ACSUB_SUBTYPE_CODE = ACNTS_AC_SUB_TYPE)
                         ACSUB_DESCN,
                      NULL CONT_TYPE,
                      CASE
                         WHEN (   ACNTS_CLOSURE_DATE IS NULL
                               OR ACNTS_CLOSURE_DATE > P_TO_DATE)
                         THEN
                            'LV'
                         ELSE
                            CASE
                               WHEN LMTLINE_LIMIT_EXPIRY_DATE >
                                       ACNTS_CLOSURE_DATE
                               THEN
                                  'TA'
                               ELSE
                                  'TM'
                            END
                      END
                         CONT_PHASE,
                      CASE NVL (
                              CASE
                                 WHEN (SELECT 1
                                         FROM LNWRTOFF
                                        WHERE     LNWRTOFF_ENTITY_NUM = 1
                                              AND LNWRTOFF_ACNT_NUM =
                                                     ACNTS_INTERNAL_ACNUM) =
                                         1
                                 THEN
                                    'WR'
                                 ELSE
                                    (SELECT ASSETCLSH_ASSET_CODE
                                       FROM ASSETCLSHIST AC
                                      WHERE     AC.ASSETCLSH_ENTITY_NUM = 1
                                            AND AC.ASSETCLSH_INTERNAL_ACNUM =
                                                   ACNTS_INTERNAL_ACNUM
                                            AND AC.ASSETCLSH_EFF_DATE =
                                                   (SELECT MAX (
                                                              ASSETCLSH_EFF_DATE)
                                                      FROM ASSETCLSHIST
                                                     WHERE     ASSETCLSH_ENTITY_NUM =
                                                                  1
                                                           AND ASSETCLSH_INTERNAL_ACNUM =
                                                                  ACNTS_INTERNAL_ACNUM
                                                           AND ASSETCLSH_EFF_DATE <=
                                                                  P_TO_DATE))
                              END,
                              'UC')
                         WHEN 'UC'
                         THEN
                            ''
                         WHEN 'SM'
                         THEN
                            'M'
                         WHEN 'SS'
                         THEN
                            'S'
                         WHEN 'DF'
                         THEN
                            'D'
                         WHEN 'BL'
                         THEN
                            'B'
                         ELSE
                            'W'
                      END
                         CONT_STATUS,
                      ACNTS_CURR_CODE CURR_CODE,
                      TO_CHAR (LMTLINE_DATE_OF_SANCTION, 'DDMMYYYY')
                         SANC_DATE,                     ------ Need to improve
                      TO_CHAR (LMTLINE_DATE_OF_SANCTION, 'DDMMYYYY') REQ_DATE,
                      TO_CHAR (LMTLINE_LIMIT_EXPIRY_DATE, 'DDMMYYYY')
                         PLAN_END_DATE,
                      CASE
                         WHEN ACNTS_CLOSURE_DATE BETWEEN P_FROM_DATE
                                                     AND P_TO_DATE
                         THEN
                            TO_CHAR (ACNTS_CLOSURE_DATE, 'DDMMYYYY')
                         ELSE
                            NULL
                      END
                         AC_END_DATE,
                      NULL DEFAULTER,
                      TO_CHAR (
                         (SELECT MAX (LNREPAY_ENTRY_DATE)
                            FROM LNREPAY
                           WHERE     LNREPAY_ENTITY_NUM = 1
                                 AND LNREPAY_INTERNAL_ACNUM =
                                        ACNTS_INTERNAL_ACNUM),
                         'DDMMYYYY')
                         LAST_PMT_DATE,
                      'N' SUBSIDIZED_CR,
                      'N' PRE_FINANCE,
                      CASE
                         WHEN (SELECT COUNT (*) ENH
                                 FROM LIMITLINEHIST, ACASLLDTL
                                WHERE     LIMLNEHIST_ENTITY_NUM = 1
                                      AND LIMLNEHIST_CLIENT_CODE =
                                             ACASLLDTL_CLIENT_NUM
                                      AND LIMLNEHIST_LIMIT_LINE_NUM =
                                             ACASLLDTL_LIMIT_LINE_NUM
                                      AND ACASLLDTL_ENTITY_NUM = 1
                                      AND ACASLLDTL_INTERNAL_ACNUM =
                                             ACNTS_INTERNAL_ACNUM
                                      AND LIMLNEHIST_EFF_DATE BETWEEN P_FROM_DATE
                                                                  AND P_TO_DATE
                                      AND (SELECT COUNT (*)
                                             FROM LIMITLINEHIST LL,
                                                  ACASLLDTL AA
                                            WHERE     LL.LIMLNEHIST_ENTITY_NUM =
                                                         1
                                                  AND LL.LIMLNEHIST_CLIENT_CODE =
                                                         AA.ACASLLDTL_CLIENT_NUM
                                                  AND LL.LIMLNEHIST_LIMIT_LINE_NUM =
                                                         AA.ACASLLDTL_LIMIT_LINE_NUM
                                                  AND ACASLLDTL_ENTITY_NUM =
                                                         1
                                                  AND ACASLLDTL_INTERNAL_ACNUM =
                                                         ACNTS_INTERNAL_ACNUM) >
                                             1) >= 1
                         THEN
                            '2'
                         ELSE
                            '0'
                      END
                         REORGANIZE_CR,
                      NULL "THIRD_GUAR_TYPE(2.2)",
                      NVL (
                         (SELECT SECRCPT_SEC_TYPE
                            FROM SECASSIGNMTBAL, ACASLLDTL, SECRCPT
                           WHERE     SECAGMTBAL_ENTITY_NUM = 1
                                 AND SECAGMTBAL_CLIENT_NUM =
                                        ACASLLDTL_CLIENT_NUM
                                 AND SECAGMTBAL_LIMIT_LINE_NUM =
                                        ACASLLDTL_LIMIT_LINE_NUM
                                 AND ACASLLDTL_ENTITY_NUM = 1
                                 AND ACASLLDTL_INTERNAL_ACNUM =
                                        ACNTS_INTERNAL_ACNUM
                                 AND SECRCPT_ENTITY_NUM = 1
                                 AND SECRCPT_SECURITY_NUM =
                                        SECAGMTBAL_SEC_NUM),
                         (SELECT LNACMIS_SEC_TYPE
                            FROM LNACMIS
                           WHERE     LNACMIS_ENTITY_NUM = 1
                                 AND LNACMIS_INTERNAL_ACNUM =
                                        ACNTS_INTERNAL_ACNUM))
                         SECURITY_TYPE,
                      0 THIRD_GUAR_AMT,
                      NVL (
                         (SELECT SUM (SECRCPT_VALUE_OF_SECURITY)
                            FROM SECASSIGNMTBAL, ACASLLDTL, SECRCPT
                           WHERE     SECAGMTBAL_ENTITY_NUM = 1
                                 AND SECAGMTBAL_CLIENT_NUM =
                                        ACASLLDTL_CLIENT_NUM
                                 AND SECAGMTBAL_LIMIT_LINE_NUM =
                                        ACASLLDTL_LIMIT_LINE_NUM
                                 AND ACASLLDTL_ENTITY_NUM = 1
                                 AND ACASLLDTL_INTERNAL_ACNUM =
                                        ACNTS_INTERNAL_ACNUM
                                 AND SECRCPT_ENTITY_NUM = 1
                                 AND SECRCPT_SECURITY_NUM =
                                        SECAGMTBAL_SEC_NUM),
                         0)
                         SECURITY_AMT,
                      'N' BASE_FOR_CL,
                      LMTLINE_SANCTION_AMT SANCTION_LIMIT,
                      CASE
                         WHEN PRODUCT_FOR_RUN_ACS = 0
                         THEN
                            NVL (
                               (SELECT SUM (LNACDISB_DISB_AMT)
                                  FROM LNACDISB
                                 WHERE     LNACDISB_ENTITY_NUM = 1
                                       AND LNACDISB_INTERNAL_ACNUM =
                                              ACNTS_INTERNAL_ACNUM
                                       AND LNACDISB_AUTH_BY IS NOT NULL
                                       AND LNACDISB_DISB_ON <= P_TO_DATE),
                               0)
                         ELSE
                            0
                      END
                         TOTAL_DISBURSE,
                      FN_BIS_GET_ASON_ACBAL (
                         1,
                         ACNTS_INTERNAL_ACNUM,
                         ACNTS_CURR_CODE,
                         P_TO_DATE,
                         PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (1))
                         OUTSTANDING,
                      NVL (
                         (SELECT ADVBBAL_PRIN_BC_OPBAL
                            FROM ADVBBAL
                           WHERE     ADVBBAL_ENTITY_NUM = 1
                                 AND ADVBBAL_INTERNAL_ACNUM =
                                        ACNTS_INTERNAL_ACNUM
                                 AND ADVBBAL_CURR_CODE = ACNTS_CURR_CODE
                                 AND ADVBBAL_YEAR =
                                        TO_NUMBER (
                                           TO_CHAR (P_TO_DATE + 1, 'YYYY'))
                                 AND ADVBBAL_MONTH =
                                        TO_NUMBER (
                                           TO_CHAR (P_TO_DATE + 1, 'MM'))),
                         0)
                         Principle,
                      NVL (
                         (SELECT ADVBBAL_INTRD_BC_OPBAL
                            FROM ADVBBAL
                           WHERE     ADVBBAL_ENTITY_NUM = 1
                                 AND ADVBBAL_INTERNAL_ACNUM =
                                        ACNTS_INTERNAL_ACNUM
                                 AND ADVBBAL_CURR_CODE = ACNTS_CURR_CODE
                                 AND ADVBBAL_YEAR =
                                        TO_NUMBER (
                                           TO_CHAR (P_TO_DATE + 1, 'YYYY'))
                                 AND ADVBBAL_MONTH =
                                        TO_NUMBER (
                                           TO_CHAR (P_TO_DATE + 1, 'MM'))),
                         0)
                         Interest,
                      NVL (
                         (SELECT ADVBBAL_CHARGE_BC_OPBAL
                            FROM ADVBBAL
                           WHERE     ADVBBAL_ENTITY_NUM = 1
                                 AND ADVBBAL_INTERNAL_ACNUM =
                                        ACNTS_INTERNAL_ACNUM
                                 AND ADVBBAL_CURR_CODE = ACNTS_CURR_CODE
                                 AND ADVBBAL_YEAR =
                                        TO_NUMBER (
                                           TO_CHAR (P_TO_DATE + 1, 'YYYY'))
                                 AND ADVBBAL_MONTH =
                                        TO_NUMBER (
                                           TO_CHAR (P_TO_DATE + 1, 'MM'))),
                         0)
                         Charge,
                      CASE
                         WHEN PRODUCT_FOR_RUN_ACS = 0
                         THEN
                            NVL (
                               (SELECT LNACRSHDTL_NUM_OF_INSTALLMENT
                                  FROM LNACRSHDTL LL
                                 WHERE     LL.LNACRSHDTL_ENTITY_NUM = 1
                                       AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                              ACNTS_INTERNAL_ACNUM
                                       AND LL.LNACRSHDTL_EFF_DATE =
                                              (SELECT MAX (
                                                         LNACRSHDTL_EFF_DATE)
                                                 FROM LNACRSHDTL
                                                WHERE     LNACRSHDTL_ENTITY_NUM =
                                                             1
                                                      AND LNACRSHDTL_INTERNAL_ACNUM =
                                                             ACNTS_INTERNAL_ACNUM
                                                      AND LNACRSHDTL_EFF_DATE <=
                                                             P_TO_DATE)),
                               0)
                         ELSE
                            0
                      END
                         NOINSTALMENT,
                      CASE
                         WHEN PRODUCT_FOR_RUN_ACS = 0
                         THEN
                            NVL (
                               (SELECT LNACRSHDTL_REPAY_FREQ
                                  FROM LNACRSHDTL LL
                                 WHERE     LL.LNACRSHDTL_ENTITY_NUM = 1
                                       AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                              ACNTS_INTERNAL_ACNUM
                                       AND LL.LNACRSHDTL_EFF_DATE =
                                              (SELECT MAX (
                                                         LNACRSHDTL_EFF_DATE)
                                                 FROM LNACRSHDTL
                                                WHERE     LNACRSHDTL_ENTITY_NUM =
                                                             1
                                                      AND LNACRSHDTL_INTERNAL_ACNUM =
                                                             ACNTS_INTERNAL_ACNUM
                                                      AND LNACRSHDTL_EFF_DATE <=
                                                             P_TO_DATE)),
                               'M')
                         ELSE
                            NULL
                      END
                         PERIOD_CODE,
                      CASE
                         WHEN PRODUCT_FOR_RUN_ACS = 0 THEN 'CAS'
                         ELSE NULL
                      END
                         METHOD_CODE,
                      CASE
                         WHEN PRODUCT_FOR_RUN_ACS = 0
                         THEN
                            NVL (
                               (SELECT LNACRSHDTL_REPAY_AMT
                                  FROM LNACRSHDTL LL
                                 WHERE     LL.LNACRSHDTL_ENTITY_NUM = 1
                                       AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                              ACNTS_INTERNAL_ACNUM
                                       AND LL.LNACRSHDTL_EFF_DATE =
                                              (SELECT MAX (
                                                         LNACRSHDTL_EFF_DATE)
                                                 FROM LNACRSHDTL
                                                WHERE     LNACRSHDTL_ENTITY_NUM =
                                                             1
                                                      AND LNACRSHDTL_INTERNAL_ACNUM =
                                                             ACNTS_INTERNAL_ACNUM
                                                      AND LNACRSHDTL_EFF_DATE <=
                                                             P_TO_DATE)),
                               0)
                         ELSE
                            0
                      END
                         INSTALLAMT,
                      NULL NXT_INST_EXP_DATE, ------ Next Repayment date
                      NULL NXT_EX_INST_AMT, ------ Installment size (not the overdue amount)
                      CASE
                         WHEN PRODUCT_FOR_RUN_ACS = 0
                         THEN
                            CASE
                               WHEN FN_BIS_GET_ASON_ACBAL (
                                       1,
                                       ACNTS_INTERNAL_ACNUM,
                                       ACNTS_CURR_CODE,
                                       P_TO_DATE,
                                       PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (1)) >=
                                       0
                               THEN
                                  0
                               WHEN MONTHS_BETWEEN (
                                       LMTLINE_LIMIT_EXPIRY_DATE,
                                       P_TO_DATE) > 0
                               THEN
                                  ROUND (
                                     MONTHS_BETWEEN (
                                        LMTLINE_LIMIT_EXPIRY_DATE,
                                        P_TO_DATE),
                                     0)
                               ELSE
                                  0
                            END
                         ELSE
                            0
                      END
                         REMAIN_INST_NO,
                        ABS (
                           FN_BIS_GET_ASON_ACBAL (
                              1,
                              ACNTS_INTERNAL_ACNUM,
                              ACNTS_CURR_CODE,
                              P_TO_DATE,
                              PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (1)))
                      - ABS (
                           FN_GET_OD_AMT (
                              1,
                              ACNTS_INTERNAL_ACNUM,
                              P_TO_DATE,
                              PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (1)))
                         REMAIN_AMT,
                      FLOOR (
                         CASE
                            WHEN PRODUCT_FOR_RUN_ACS = 0
                            THEN
                                 (ABS (
                                     FN_GET_OD_AMT (
                                        1,
                                        ACNTS_INTERNAL_ACNUM,
                                        P_TO_DATE,
                                        PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (
                                           1))))
                               / (CASE (SELECT LNACRSHDTL_REPAY_FREQ
                                          FROM LNACRSHDTL LL
                                         WHERE     LL.LNACRSHDTL_ENTITY_NUM =
                                                      1
                                               AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                                      ACNTS_INTERNAL_ACNUM
                                               AND LL.LNACRSHDTL_EFF_DATE =
                                                      (SELECT MAX (
                                                                 LNACRSHDTL_EFF_DATE)
                                                         FROM LNACRSHDTL
                                                        WHERE     LNACRSHDTL_ENTITY_NUM =
                                                                     1
                                                              AND LNACRSHDTL_INTERNAL_ACNUM =
                                                                     ACNTS_INTERNAL_ACNUM
                                                              AND LNACRSHDTL_EFF_DATE <=
                                                                     P_TO_DATE))
                                     WHEN 'M'
                                     THEN
                                          1
                                        * (SELECT LNACRSHDTL_REPAY_AMT
                                             FROM LNACRSHDTL LL
                                            WHERE     LL.LNACRSHDTL_ENTITY_NUM =
                                                         1
                                                  AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                                         ACNTS_INTERNAL_ACNUM
                                                  AND LL.LNACRSHDTL_EFF_DATE =
                                                         (SELECT MAX (
                                                                    LNACRSHDTL_EFF_DATE)
                                                            FROM LNACRSHDTL
                                                           WHERE     LNACRSHDTL_ENTITY_NUM =
                                                                        1
                                                                 AND LNACRSHDTL_INTERNAL_ACNUM =
                                                                        ACNTS_INTERNAL_ACNUM
                                                                 AND LNACRSHDTL_EFF_DATE <=
                                                                        P_TO_DATE))
                                     WHEN 'Q'
                                     THEN
                                          3
                                        * (SELECT LNACRSHDTL_REPAY_AMT
                                             FROM LNACRSHDTL LL
                                            WHERE     LL.LNACRSHDTL_ENTITY_NUM =
                                                         1
                                                  AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                                         ACNTS_INTERNAL_ACNUM
                                                  AND LL.LNACRSHDTL_EFF_DATE =
                                                         (SELECT MAX (
                                                                    LNACRSHDTL_EFF_DATE)
                                                            FROM LNACRSHDTL
                                                           WHERE     LNACRSHDTL_ENTITY_NUM =
                                                                        1
                                                                 AND LNACRSHDTL_INTERNAL_ACNUM =
                                                                        ACNTS_INTERNAL_ACNUM
                                                                 AND LNACRSHDTL_EFF_DATE <=
                                                                        P_TO_DATE))
                                     WHEN 'H'
                                     THEN
                                          6
                                        * (SELECT LNACRSHDTL_REPAY_AMT
                                             FROM LNACRSHDTL LL
                                            WHERE     LL.LNACRSHDTL_ENTITY_NUM =
                                                         1
                                                  AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                                         ACNTS_INTERNAL_ACNUM
                                                  AND LL.LNACRSHDTL_EFF_DATE =
                                                         (SELECT MAX (
                                                                    LNACRSHDTL_EFF_DATE)
                                                            FROM LNACRSHDTL
                                                           WHERE     LNACRSHDTL_ENTITY_NUM =
                                                                        1
                                                                 AND LNACRSHDTL_INTERNAL_ACNUM =
                                                                        ACNTS_INTERNAL_ACNUM
                                                                 AND LNACRSHDTL_EFF_DATE <=
                                                                        P_TO_DATE))
                                     WHEN 'Y'
                                     THEN
                                          12
                                        * (SELECT LNACRSHDTL_REPAY_AMT
                                             FROM LNACRSHDTL LL
                                            WHERE     LL.LNACRSHDTL_ENTITY_NUM =
                                                         1
                                                  AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                                         ACNTS_INTERNAL_ACNUM
                                                  AND LL.LNACRSHDTL_EFF_DATE =
                                                         (SELECT MAX (
                                                                    LNACRSHDTL_EFF_DATE)
                                                            FROM LNACRSHDTL
                                                           WHERE     LNACRSHDTL_ENTITY_NUM =
                                                                        1
                                                                 AND LNACRSHDTL_INTERNAL_ACNUM =
                                                                        ACNTS_INTERNAL_ACNUM
                                                                 AND LNACRSHDTL_EFF_DATE <=
                                                                        P_TO_DATE))
                                     ELSE
                                          1
                                        * (SELECT LNACRSHDTL_REPAY_AMT
                                             FROM LNACRSHDTL LL
                                            WHERE     LL.LNACRSHDTL_ENTITY_NUM =
                                                         1
                                                  AND LL.LNACRSHDTL_INTERNAL_ACNUM =
                                                         ACNTS_INTERNAL_ACNUM
                                                  AND LL.LNACRSHDTL_EFF_DATE =
                                                         (SELECT MAX (
                                                                    LNACRSHDTL_EFF_DATE)
                                                            FROM LNACRSHDTL
                                                           WHERE     LNACRSHDTL_ENTITY_NUM =
                                                                        1
                                                                 AND LNACRSHDTL_INTERNAL_ACNUM =
                                                                        ACNTS_INTERNAL_ACNUM
                                                                 AND LNACRSHDTL_EFF_DATE <=
                                                                        P_TO_DATE))
                                  END)
                            ELSE
                               0
                         END)
                         NOOVERDUE,
                      ABS (
                         FN_GET_OD_AMT (
                            1,
                            ACNTS_INTERNAL_ACNUM,
                            P_TO_DATE,
                            PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (1)))
                         OVERDUE,
                      CASE ROUND (
                                (CASE
                                    WHEN PRODUCT_FOR_RUN_ACS = 0
                                    THEN
                                       CASE
                                          WHEN    FN_BIS_GET_ASON_ACBAL (
                                                     1,
                                                     ACNTS_INTERNAL_ACNUM,
                                                     ACNTS_CURR_CODE,
                                                     P_TO_DATE,
                                                     PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (
                                                        1)) >= 0
                                               OR FN_GET_OD_AMT (
                                                     1,
                                                     ACNTS_INTERNAL_ACNUM,
                                                     P_TO_DATE,
                                                     PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (
                                                        1)) = 0
                                          THEN
                                             0
                                          WHEN MONTHS_BETWEEN (
                                                  LMTLINE_LIMIT_EXPIRY_DATE,
                                                  P_TO_DATE) > 0
                                          THEN
                                               PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (
                                                  1)
                                             - FN_GET_OD_DATE (
                                                  1,
                                                  ACNTS_INTERNAL_ACNUM,
                                                  P_TO_DATE,
                                                  PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (
                                                     1))
                                          ELSE
                                             0
                                       END
                                    ELSE
                                       P_TO_DATE - LMTLINE_LIMIT_EXPIRY_DATE
                                 END)
                              / 30,
                              0)
                         WHEN 0
                         THEN
                            '000'
                         WHEN 1
                         THEN
                            '030'
                         WHEN 2
                         THEN
                            '060'
                         WHEN 3
                         THEN
                            '090'
                         WHEN 4
                         THEN
                            '120'
                         WHEN 5
                         THEN
                            '150'
                         WHEN 6 - 100000000
                         THEN
                            '180'
                         ELSE
                            NULL
                      END
                         PAYMENT_DELAYNO,
                      NULL LEASED_TYPE,
                      NULL LEASED_VALUE,
                      NULL REGISTRATION_NO,
                      NULL MANUFACTURE_DATE,
                        FN_GET_OD_AMT (
                           1,
                           ACNTS_INTERNAL_ACNUM,
                           ADD_MONTHS (P_TO_DATE, -1),
                           PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (1))
                      + (SELECT ACNTBBAL_BC_OPNG_CR_SUM
                           FROM ACNTBBAL
                          WHERE     ACNTBBAL_ENTITY_NUM = 1
                                AND ACNTBBAL_INTERNAL_ACNUM =
                                       ACNTS_INTERNAL_ACNUM
                                AND ACNTBBAL_YEAR =
                                       TO_NUMBER (
                                          TO_CHAR (P_TO_DATE + 1, 'YYYY'))
                                AND ACNTBBAL_MONTH =
                                       TO_NUMBER (
                                          TO_CHAR (P_TO_DATE + 1, 'MM')))
                      - (SELECT ACNTBBAL_BC_OPNG_CR_SUM
                           FROM ACNTBBAL
                          WHERE     ACNTBBAL_ENTITY_NUM = 1
                                AND ACNTBBAL_INTERNAL_ACNUM =
                                       ACNTS_INTERNAL_ACNUM
                                AND ACNTBBAL_YEAR =
                                       TO_NUMBER (
                                          TO_CHAR (P_TO_DATE, 'YYYY'))
                                AND ACNTBBAL_MONTH =
                                       TO_NUMBER (TO_CHAR (P_TO_DATE, 'MM')))
                         DUERECOVERY,
                        (SELECT ACNTBBAL_BC_OPNG_CR_SUM
                           FROM ACNTBBAL
                          WHERE     ACNTBBAL_ENTITY_NUM = 1
                                AND ACNTBBAL_INTERNAL_ACNUM =
                                       ACNTS_INTERNAL_ACNUM
                                AND ACNTBBAL_YEAR =
                                       TO_NUMBER (
                                          TO_CHAR (P_TO_DATE + 1, 'YYYY'))
                                AND ACNTBBAL_MONTH =
                                       TO_NUMBER (
                                          TO_CHAR (P_TO_DATE + 1, 'MM')))
                      - (SELECT ACNTBBAL_BC_OPNG_CR_SUM
                           FROM ACNTBBAL
                          WHERE     ACNTBBAL_ENTITY_NUM = 1
                                AND ACNTBBAL_INTERNAL_ACNUM =
                                       ACNTS_INTERNAL_ACNUM
                                AND ACNTBBAL_YEAR =
                                       TO_NUMBER (
                                          TO_CHAR (P_TO_DATE, 'YYYY'))
                                AND ACNTBBAL_MONTH =
                                       TO_NUMBER (TO_CHAR (P_TO_DATE, 'MM')))
                         RECOVERY,
                      FN_GET_CUMULTV_RECOV (ACNTS_INTERNAL_ACNUM,
                                            PRODUCT_FOR_RUN_ACS,
                                            P_FROM_DATE,
                                            P_TO_DATE,
                                            LMTLINE_LIMIT_EXPIRY_DATE)
                         CUMRECOVERY,
                      NULL LAWSUIT_DATE, -------- Dite hobe
                      TO_CHAR (
                         (SELECT ASSETCLSH_NPA_DATE
                            FROM ASSETCLSHIST AA
                           WHERE     AA.ASSETCLSH_ENTITY_NUM = 1
                                 AND AA.ASSETCLSH_INTERNAL_ACNUM =
                                        ACNTS_INTERNAL_ACNUM
                                 AND AA.ASSETCLSH_EFF_DATE =
                                        (SELECT MAX (ASSETCLSH_EFF_DATE)
                                           FROM ASSETCLSHIST
                                          WHERE     ASSETCLSH_ENTITY_NUM = 1
                                                AND ASSETCLSH_INTERNAL_ACNUM =
                                                       ACNTS_INTERNAL_ACNUM
                                                AND ASSETCLSH_EFF_DATE <=
                                                       P_TO_DATE)),
                         'DDMMYYYY')
                         CL_DATE,
                      CASE
                         WHEN (SELECT NVL (LNACRS_RS_NO, 0)
                                 FROM LNACRS
                                WHERE     LNACRS_ENTITY_NUM = 1
                                      AND LNACRS_INTERNAL_ACNUM =
                                             ACNTS_INTERNAL_ACNUM) > 0
                         THEN
                               'RS-'
                            || (SELECT NVL (LNACRS_RS_NO, 0)
                                  FROM LNACRS
                                 WHERE     LNACRS_ENTITY_NUM = 1
                                       AND LNACRS_INTERNAL_ACNUM =
                                              ACNTS_INTERNAL_ACNUM)
                         ELSE
                            NULL
                      END
                         RESCHEDULE_NO,
                      CASE
                         WHEN (SELECT NVL (LNACRS_RS_NO, 0)
                                 FROM LNACRS
                                WHERE     LNACRS_ENTITY_NUM = 1
                                      AND LNACRS_INTERNAL_ACNUM =
                                             ACNTS_INTERNAL_ACNUM) > 0
                         THEN
                            TO_CHAR (
                               (SELECT LNACRS_LATEST_EFF_DATE
                                  FROM LNACRS
                                 WHERE     LNACRS_ENTITY_NUM = 1
                                       AND LNACRS_INTERNAL_ACNUM =
                                              ACNTS_INTERNAL_ACNUM),
                               'DDMMYYYY')
                         ELSE
                            NULL
                      END
                         LAST_RESCH_DATE,
                      (SELECT LNACMIS_SUB_INDUS_CODE
                         FROM LNACMIS
                        WHERE     LNACMIS_ENTITY_NUM = 1
                              AND LNACMIS_INTERNAL_ACNUM =
                                     ACNTS_INTERNAL_ACNUM)
                         ECOCODE,
                      CASE (SELECT SUBSTR (LNACMIS_HO_DEPT_CODE, 1, 3)
                              FROM LNACMIS
                             WHERE     LNACMIS_ENTITY_NUM = 1
                                   AND LNACMIS_INTERNAL_ACNUM =
                                          ACNTS_INTERNAL_ACNUM)
                         WHEN 'CL2'
                         THEN
                            'Y'
                         WHEN 'CL3'
                         THEN
                            'Y'
                         WHEN 'CL4'
                         THEN
                            'Y'
                         ELSE
                            'N'
                      END
                         SME,
                      (SELECT LNACMIS_NATURE_BORROWAL_AC
                         FROM LNACMIS
                        WHERE     LNACMIS_ENTITY_NUM = 1
                              AND LNACMIS_INTERNAL_ACNUM =
                                     ACNTS_INTERNAL_ACNUM)
                         ENTERPRISE,
                      NULL LAST_CHARGE_DATE,
                      NULL INSTALL_TYPE,
                      NULL MARK,
                      NULL "USER",
                      NULL ENTRY_DATE
                 FROM ACNTS,
                      MBRN,
                      PRODUCTS,
                      LIMITLINE,
                      ACASLLDTL
                WHERE     ACNTS_ENTITY_NUM = 1
                      AND ACNTS_BRN_CODE = P_BRN_CODE
                      AND MBRN_ENTITY_NUM = 1
                      AND MBRN_CODE = ACNTS_BRN_CODE
                      AND PRODUCT_CODE = ACNTS_PROD_CODE
                      AND PRODUCT_FOR_LOANS = 1
                      AND ACASLLDTL_ENTITY_NUM = 1
                      AND ACASLLDTL_INTERNAL_ACNUM = ACNTS_INTERNAL_ACNUM
                      AND LMTLINE_ENTITY_NUM = 1
                      AND LMTLINE_CLIENT_CODE = ACASLLDTL_CLIENT_NUM
                      AND LMTLINE_NUM = ACASLLDTL_LIMIT_LINE_NUM
                      AND (   ACNTS_CLOSURE_DATE IS NULL
                           OR ACNTS_CLOSURE_DATE > P_TO_DATE);
         EXCEPTION
            WHEN OTHERS
            THEN
               V_ERROR_MSG := SQLERRM;
         END;
         COMMIT ;
   END;
END SP_CIB_CONTRACT_GEN;
/

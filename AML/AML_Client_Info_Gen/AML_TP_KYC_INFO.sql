/* Formatted on 10/30/2019 6:01:33 PM (QP5 v5.252.13127.32867) */
BEGIN
   FOR IDX IN (SELECT * FROM MIG_DETAIL ORDER BY BRANCH_CODE)
   LOOP
      INSERT INTO AML_KYCINFO
         SELECT ACNTS_CLIENT_NUM CUSTOMERNO,
                CASE
                   WHEN CLIENTS_TYPE_FLG = 'I' THEN 'INDIVIDUAL'
                   WHEN CLIENTS_TYPE_FLG = 'C' THEN 'ENTITY'
                --ELSE 'OTHERS'
                END
                   SCRCUSTOMERTYPE,
                (SELECT ACTP_SRC_FUND
                   FROM ACNTRNPR
                  WHERE     ACTP_ACNT_NUM = ACNTS_INTERNAL_ACNUM
                        AND ACTP_LATEST_EFF_DATE =
                               (SELECT MAX (ACTP_LATEST_EFF_DATE)
                                  FROM ACNTRNPR
                                 WHERE ACTP_ACNT_NUM = ACNTS_INTERNAL_ACNUM))
                   SOURCEOFFUND,
                (SELECT ACTP_SRC_FUND
                   FROM ACNTRNPR
                  WHERE     ACTP_ACNT_NUM = ACNTS_INTERNAL_ACNUM
                        AND ACTP_LATEST_EFF_DATE =
                               (SELECT MAX (ACTP_LATEST_EFF_DATE)
                                  FROM ACNTRNPR
                                 WHERE ACTP_ACNT_NUM = ACNTS_INTERNAL_ACNUM))
                   SOURCEOFINCOME,
                (SELECT USER_NAME
                   FROM USERS
                  WHERE USER_ID = ACNTS_ENTD_BY)
                   ACCOUNTOPENINGOFFICER,
                NULL ACCOUNTOPENINGPURPOSE,
                NVL (
                   (SELECT OCCUPATIONS_DESCN
                      FROM OCCUPATIONS, INDCLIENTS
                     WHERE     INDCLIENT_CODE = CLIENTS_CODE
                           AND OCCUPATIONS_CODE = INDCLIENT_OCCUPN_CODE),
                   'OTHER')
                   CUSTOMERPROFESSION,
                ROUND (
                     (SELECT CASE
                                WHEN NVL (INDCLIENT_BC_ANNUAL_INCOME, 0) <> 0
                                THEN
                                   INDCLIENT_BC_ANNUAL_INCOME
                                WHEN (    NVL (INDCLIENT_BC_ANNUAL_INCOME, 0) =
                                             0
                                      AND INDCLIENT_ANNUAL_INCOME_SLAB
                                             IS NULL)
                                THEN
                                   100000
                                WHEN INDCLIENT_ANNUAL_INCOME_SLAB = 1
                                THEN
                                   100000
                                WHEN INDCLIENT_ANNUAL_INCOME_SLAB = 2
                                THEN
                                   250000
                                WHEN INDCLIENT_ANNUAL_INCOME_SLAB = 3
                                THEN
                                   500000
                                WHEN INDCLIENT_ANNUAL_INCOME_SLAB = 4
                                THEN
                                   500000
                                ELSE
                                   100000
                             END
                        FROM INDCLIENTS
                       WHERE INDCLIENT_CODE = CLIENTS_CODE)
                   / 12)
                   NETWORTH,
                CASE
                   WHEN ACNTS_MKT_CHANNEL_CODE = 1
                   THEN
                      'BY RELATIONSHIP MANAGER'
                   WHEN ACNTS_MKT_CHANNEL_CODE = 2
                   THEN
                      'WALK IN CUSTOMER'
                   WHEN ACNTS_MKT_CHANNEL_CODE = 3
                   THEN
                      'OTHERS MARKETING CHANNEL'
                   ELSE
                      'OTHERS MARKETING CHANNEL'
                END
                   ACCOUNTOPENINGWAY
           FROM ACNTS, CLIENTS
          WHERE     ACNTS_ENTITY_NUM = 1
                AND ACNTS_CLIENT_NUM = CLIENTS_CODE
                AND ACNTS_CLOSURE_DATE IS NULL
                AND CLIENTS_TYPE_FLG IN ('I', 'C')
                AND ACNTS_BRN_CODE = IDX.BRANCH_CODE;



      INSERT INTO AML_TPINFO
         SELECT ACNTS_BRN_CODE "BRANCHCODE",
                MBRN_NAME "BRANCHNAME",
                IACLINK_ACTUAL_ACNUM "ACCOUNTNUMBER",
                ACNTS_AC_NAME1 || ACNTS_AC_NAME2 "ACCOUNTNAME",
                ACTP_SRC_FUND "SOURCEOFFUND",
                ACTP_NOT_CASHR "NO_OF_CASH_WITHDRAWAL",
                ACTP_CUTOFF_LMT_CASHR "MAXIMIM_WIDR_OF_A_SIN_TRAN",
                ACTP_MAXAMT_CASHR "CASH_TOTAL_MONTHLY_WITHDRAL",
                ACTP_NOT_NONCASHR "NO_OF_TRF_WITHDRAL",
                ACTP_CUTOFF_LMT_NONCASHR "MAX_TRF_OF_A_SIN_TRAN_WITHDRAL",
                ACTP_MAXAMT_NCASHR "TOTAL_MONTHLY_TRF_WITHDRAL",
                ACTP_NOT_TFREMR "NO_OF_REMITANCE_WITHDRAL",
                ACTP_CUTOFF_LMT_TFREMR "MAX_REMIT_OF_A_SIN_TRAN_WITHDR",
                ACTP_MAXAMT_TFREMR "TOTAL_MONTHLY_REMIT_WITHDRAL",
                ACTP_NOT_CASHP "NO_OF_MONTHLY_DEPOSIT",
                ACTP_CUTOFF_LMT_CASHP "MAXIMUM_AMT_OF_A_SINGLE_DEP",
                ACTP_MAXAMT_CASHP "TOTAL_MONTHLY_DEP",
                ACTP_NOT_NONCASHP "NO_OF_MONTHLY_TRF_DEP",
                ACTP_CUTOFF_LMT_NONCASHP "MAXIMUM_DEP_OF_A_SINGLE_TRF",
                ACTP_MAXAMT_NCASHP "TOTAL_MONTHLY_TRF_DEP",
                ACTP_NOT_TFREMP "NO_OF_MONTHLY_REMIT_DEP",
                ACTP_CUTOFF_LMT_TFREMP "MAX_AMT_DEP_OF_A_SINGLE_REMIT",
                ACTP_MAXAMT_TFREMP "TOTAL_MONTHLY_REMIT_DEP"
           FROM MBRN,
                ACNTRNPR,
                ACNTS,
                IACLINK
          WHERE     ACTP_ACNT_NUM = ACNTS_INTERNAL_ACNUM
                AND ACNTS_ENTITY_NUM = 1
                AND ACNTS_BRN_CODE = MBRN_CODE
                AND IACLINK_ENTITY_NUM = 1
                AND ACNTS_BRN_CODE = IDX.BRANCH_CODE
                AND ACNTS_INTERNAL_ACNUM = IACLINK_INTERNAL_ACNUM;
                
           COMMIT ;
           
   END LOOP;
END;
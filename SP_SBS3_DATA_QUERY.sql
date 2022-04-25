CREATE OR REPLACE PROCEDURE SP_SBS3_DATA_QUERY (P_FROM_DATE       DATE,
                                                P_DATA        OUT CLOB)
IS
   V_DATA       CLOB;
   V_FIN_YEAR   NUMBER;
BEGIN
   V_FIN_YEAR := TO_CHAR (P_FROM_DATE, 'YYYY');
   V_DATA :=
         'SELECT  TO_CHAR (:V_TO_DATE, ''DDMMYYYY'')
       || SUBSTR (MBRN_BSR_CODE, 3)
       || CASE
             WHEN LENGTH (IACLINK_ACTUAL_ACNUM) > 12
             THEN
                SUBSTR (IACLINK_ACTUAL_ACNUM, -12, 12)
             ELSE
                LPAD (IACLINK_ACTUAL_ACNUM, 12, ''0'')
          END
       || RPAD (
             NVL (
                TRIM (
                   REGEXP_REPLACE (A.ACNTS_AC_NAME1 || A.ACNTS_AC_NAME2,
                                   ''[^[:print:]]'',
                                   '' '')),
                '' ''),
             100,
             '' '')
       || RPAD (
             NVL (
                NVL (
                   (SELECT OCCUPATIONS_DESCN
                      FROM OCCUPATIONS, INDCLIENTS
                     WHERE     OCCUPATIONS_CODE = INDCLIENT_OCCUPN_CODE
                           AND INDCLIENT_CODE = IACLINK_CIF_NUMBER),
                   '' ''),
                '' ''),
             50,
             '' '')
       || RPAD (NVL (CLIENTS_SEGMENT_CODE, '' ''), 6, ''0'')
       || RPAD (NVL (PRODUCT_NAME, '' ''), 100, '' '')
       || LPAD (
             NVL (
                (SELECT RPTHDGLDTL_CODE
                   FROM RPTHEAD H, RPTLAYOUTDTL, RPTHEADGLDTL D
                  WHERE     H.RPTHEAD_CODE = RPTLAYOUTDTL_RPT_HEAD_CODE
                        AND D.RPTHDGLDTL_CODE = RPTLAYOUTDTL_RPT_HEAD_CODE
                        AND D.RPTHDGLDTL_GLACC_CODE = ACNTS_GLACC_CODE
                        AND RPTLAYOUTDTL_RPT_CODE = ''F12''
                        AND H.RPTHEAD_CLASSIFICATION = ''A''),
                ''0''),
             5,
             ''0'')
       || LPAD (NVL (PRODUCT_CODE, ''0''), 5, ''0'')
       || LPAD (
             NVL (
                (SELECT LNACMIS_NATURE_BORROWAL_AC
                   FROM LNACMIS
                  WHERE     LNACMIS_ENTITY_NUM = :V_ENTITY_NUM
                        AND LNACMIS_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM),
                ''0''),
             2,
             ''0'')
       || TRIM (
             TO_CHAR (
                NVL (
                   CASE
                      WHEN (SELECT LNACIRS_AC_LEVEL_INT_REQD
                              FROM LNACIRS
                             WHERE     LNACIRS_ENTITY_NUM = :V_ENTITY_NUM
                                   AND LNACIRS_INTERNAL_ACNUM =
                                          A.ACNTS_INTERNAL_ACNUM) = ''1''
                      THEN
                         (SELECT LNACIR_APPL_INT_RATE
                            FROM LNACIR
                           WHERE     LNACIR_ENTITY_NUM = :V_ENTITY_NUM
                                 AND LNACIR_INTERNAL_ACNUM =
                                        A.ACNTS_INTERNAL_ACNUM)
                      ELSE
                         (SELECT LL.LNPRODIRDTL_INT_RATE
                            FROM LNPRODIRDTL LL
                           WHERE     LNPRODIRDTL_ENTITY_NUM = :V_ENTITY_NUM
                                 AND LL.LNPRODIRDTL_PROD_CODE =
                                        A.ACNTS_PROD_CODE
                                 AND LL.LNPRODIRDTL_CURR_CODE =
                                        A.ACNTS_CURR_CODE
                                 AND LL.LNPRODIRDTL_AC_TYPE = A.ACNTS_AC_TYPE
                                 AND LL.LNPRODIRDTL_AC_SUB_TYPE =
                                        A.ACNTS_AC_SUB_TYPE)
                   END,
                   0),
                ''00.00''))
       || LPAD (
             NVL (
                TRIM (
                   (SELECT LNACMIS_SUB_INDUS_CODE
                      FROM LNACMIS
                     WHERE     LNACMIS_ENTITY_NUM = :V_ENTITY_NUM
                           AND LNACMIS_INTERNAL_ACNUM =
                                  A.ACNTS_INTERNAL_ACNUM)),
                ''0''),
             4,
             ''0'')
       || LPAD (NVL (TRIM (TO_CHAR ( FN_GET_SECURITY_CODE(:V_ENTITY_NUM,I.IACLINK_CIF_NUMBER, A.ACNTS_BRN_CODE,A.ACNTS_INTERNAL_ACNUM, I.IACLINK_PROD_CODE) )), '' ''), 2, '' '')
       || NVL((SELECT ASSETCD_BSR_CODE
             FROM ASSETCLS , ASSETCD
            WHERE     ASSETCLS_ENTITY_NUM = :V_ENTITY_NUM
                  AND ASSETCLS_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
                  AND ASSETCD_CODE = ASSETCLS_ASSET_CODE), ''  '') -- have confusion
       || NVL( (SELECT    TRIM (
                        TO_CHAR (NVL (LMTLINE_SANCTION_AMT, 0),
                                 ''0000000000000000000000.00''))
                  || LPAD (
                        NVL (
                           TO_CHAR (TO_DATE (LMTLINE_DATE_OF_SANCTION),
                                    ''DDMMYYYY''),
                           '' ''),
                        8,
                        '' '')
                  || LPAD (
                        NVL (
                           TO_CHAR (TO_DATE (LMTLINE_LIMIT_EXPIRY_DATE),
                                    ''DDMMYYYY''),
                           '' ''),
                        8,
                        '' '')
             FROM LIMITLINE, ACASLLDTL
            WHERE     LMTLINE_ENTITY_NUM = :V_ENTITY_NUM
                  AND LMTLINE_CLIENT_CODE = ACASLLDTL_CLIENT_NUM
                  AND LMTLINE_NUM = ACASLLDTL_LIMIT_LINE_NUM
                  AND ACASLLDTL_ENTITY_NUM = :V_ENTITY_NUM
                  AND ACASLLDTL_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM), ''0000000000000000000000.00                '' )
       || NVL( (SELECT    LPAD (NVL (LNACRSHDTL_NUM_OF_INSTALLMENT, ''0''), 3, ''0'')
                  || NVL (LNACRSHDTL_REPAY_FREQ, '' '')
                  || TRIM (
                        TO_CHAR (NVL (LNACRSHDTL_REPAY_AMT, 0),
                                 ''000000000000.00''))
             FROM LNACRSHDTL LN
            WHERE     LN.LNACRSHDTL_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
                  AND LN.LNACRSHDTL_ENTITY_NUM = :V_ENTITY_NUM
                  AND LN.LNACRSHDTL_EFF_DATE =
                         (SELECT MAX (LNACRSHDTL_EFF_DATE)
                            FROM LNACRSHDTL
                           WHERE     LNACRSHDTL_INTERNAL_ACNUM =
                                        A.ACNTS_INTERNAL_ACNUM
                                 AND LNACRSHDTL_ENTITY_NUM = :V_ENTITY_NUM)) , ''000 000000000000.00'' )
                   || (SELECT  TRIM(TO_CHAR(NVL(NVL(SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''D'' AND T.TRAN_TYPE_OF_TRAN = 3 THEN A.TRANADV_PRIN_AC_AMT ELSE 0 END), 0) , 0),''0000000000000000000000.00''))
                            || TRIM(TO_CHAR(NVL(NVL(SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''D'' THEN A.TRANADV_INTRD_AC_AMT ELSE 0 END), 0) , 0),''0000000000000000000000.00''))
                            || TRIM(TO_CHAR(NVL(NVL(
                                    (SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''D'' THEN A.TRANADV_CHARGE_AC_AMT ELSE 0 END)
                                                    +
                                     SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''D'' THEN A.TRANADV_PRIN_AC_AMT ELSE 0 END)
                                                    -
                                     SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''D'' AND T.TRAN_TYPE_OF_TRAN = 3 THEN A.TRANADV_PRIN_AC_AMT ELSE 0 END)), 0), 0),''0000000000000000000000.00''))
                            || TRIM(TO_CHAR(NVL(NVL(SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''C'' AND T.TRAN_TYPE_OF_TRAN = 3 THEN A.TRANADV_PRIN_AC_AMT ELSE 0 END), 0) , 0),''0000000000000000000000.00''))
                            || TRIM(TO_CHAR(NVL(NVL(SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''C'' THEN A.TRANADV_INTRD_AC_AMT ELSE 0 END), 0) , 0),''0000000000000000000000.00''))
                            || TRIM(TO_CHAR(NVL(NVL(
                                    (SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''C'' THEN A.TRANADV_CHARGE_AC_AMT ELSE 0 END)
                                                    +
                                     SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''C'' THEN A.TRANADV_PRIN_AC_AMT ELSE 0 END)
                                                    -
                                     SUM(CASE WHEN T.TRAN_DB_cR_FLG = ''C'' AND T.TRAN_TYPE_OF_TRAN = 3 THEN A.TRANADV_PRIN_AC_AMT ELSE 0 END)), 0), 0),''0000000000000000000000.00''))
                             FROM TRANADV'
      || V_FIN_YEAR
      || ' A, TRAN'
      || V_FIN_YEAR
      || ' T
        WHERE  A.TRANADV_ENTITY_NUM = T.TRAN_ENTITY_NUM
                AND A.TRANADV_BRN_CODE = T.TRAN_ACING_BRN_CODE
                AND A.TRANADV_DATE_OF_TRAN = T.TRAN_DATE_OF_TRAN
                AND A.TRANADV_BATCH_NUMBER = T.TRAN_BATCH_NUMBER
                AND A.TRANADV_BATCH_SL_NUM = T.TRAN_BATCH_SL_NUM
                AND A.TRANADV_BRN_CODE = A.ACNTS_BRN_CODE
                AND T.TRAN_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
                AND T.TRAN_DATE_OF_TRAN BETWEEN :V_FROM_DATE AND :V_TO_DATE
                AND T.TRAN_AUTH_ON IS NOT NULL AND (NVL(T.TRAN_AC_CANCEL_AMT, 0) = 0 OR NVL(T.TRAN_BC_CANCEL_AMT, 0) = 0))
                || TRIM(TO_CHAR(NVL( (SELECT LNOD_OD_AMT  FROM LNOD WHERE LNOD_ENTITY_NUM = :V_ENTITY_NUM AND LNOD_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM) , 0),''0000000000000000000000.00''))
                || TRIM(TO_CHAR(NVL((SELECT ABS ( NVL (
                                     NVL (ACNTBBAL_AC_OPNG_CR_SUM, 0)
                                   - NVL (ACNTBBAL_BC_OPNG_DB_SUM, 0),
                                   0))
                           FROM ACNTBBAL
                          WHERE     ACNTBBAL_ENTITY_NUM = :V_ENTITY_NUM
                                AND ACNTBBAL_INTERNAL_ACNUM =A.ACNTS_INTERNAL_ACNUM
                                AND ACNTBBAL_CURR_CODE = A.ACNTS_CURR_CODE
                                AND ACNTBBAL_YEAR =
                                       TO_NUMBER (
                                          TO_CHAR (:V_TO_DATE + 1, ''YYYY''))
                                AND ACNTBBAL_MONTH =
                                       TO_NUMBER (
                                          TO_CHAR (:V_TO_DATE + 1, ''MM''))), 0),''0000000000000000000000.00''))
          TOTAL_DATA
  FROM PRODUCTS P,
       IACLINK I,
       ACNTS A,
       ACTYPES T,
       MBRN M,
       CLIENTS C
 WHERE     P.PRODUCT_CODE = I.IACLINK_PROD_CODE
       AND I.IACLINK_PROD_CODE = A.ACNTS_PROD_CODE
       AND I.IACLINK_ENTITY_NUM = A.ACNTS_ENTITY_NUM
       AND I.IACLINK_BRN_CODE = A.ACNTS_BRN_CODE
       AND I.IACLINK_INTERNAL_ACNUM = A.ACNTS_INTERNAL_ACNUM
       AND I.IACLINK_CIF_NUMBER = A.ACNTS_CLIENT_NUM
       AND A.ACNTS_AC_TYPE = T.ACTYPE_CODE
       AND NVL (P.PRODUCT_FOR_LOANS, ''0'') = ''1''
       AND I.IACLINK_BRN_CODE = :V_BRN_CODE
       AND M.MBRN_ENTITY_NUM = :V_ENTITY_NUM
       AND M.MBRN_CODE = I.IACLINK_BRN_CODE
       AND C.CLIENTS_CODE = I.IACLINK_CIF_NUMBER
       AND A.ACNTS_AUTH_ON IS NOT NULL
       AND (   A.ACNTS_CLOSURE_DATE IS NULL
            OR A.ACNTS_CLOSURE_DATE >= :V_TO_DATE)
       AND (SELECT ABS ( NVL (
                                     NVL (ACNTBBAL_AC_OPNG_CR_SUM, 0)
                                   - NVL (ACNTBBAL_BC_OPNG_DB_SUM, 0),
                                   0))
                           FROM ACNTBBAL
                          WHERE     ACNTBBAL_ENTITY_NUM = :V_ENTITY_NUM
                                AND ACNTBBAL_INTERNAL_ACNUM =A.ACNTS_INTERNAL_ACNUM
                                AND ACNTBBAL_CURR_CODE = A.ACNTS_CURR_CODE
                                AND ACNTBBAL_YEAR =
                                       TO_NUMBER (
                                          TO_CHAR (:V_TO_DATE + 1, ''YYYY''))
                                AND ACNTBBAL_MONTH =
                                       TO_NUMBER (
                                          TO_CHAR (:V_TO_DATE + 1, ''MM''))) <> 0';


   --INSERT INTO SBS2_DATA_CLOB VALUES (V_DATA);
   --COMMIT ;

   P_DATA := V_DATA;
END;
/
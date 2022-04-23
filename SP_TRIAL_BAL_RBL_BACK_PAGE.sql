SELECT TOT_DATA.*  FROM 
(SELECT NVL(IDEN,'3') IDEN,
         NVL (DESCRIPTION, 'Scroll Grand Total') DESCRIPTION,
         SUM (TOTAL_NO_CREDIT) TOTAL_NO_CREDIT,
         SUM (TOTAL_CREDIT) TOTAL_CREDIT,
         SUM (TOTAL_NO_DEBIT) TOTAL_NO_DEBIT,
         SUM (TOTAL_DEBIT) TOTAL_DEBIT
    FROM (  SELECT '1' IDEN,
                   'Cash' DESCRIPTION,
                   SUM (NOOFCREDIT) TOTAL_NO_CREDIT,
                   SUM (CREDIT) TOTAL_CREDIT,
                   SUM (NOOFDEBIT) TOTAL_NO_DEBIT,
                   SUM (DEBIT) TOTAL_DEBIT
              FROM MASTERVOUCHER
             WHERE     TRANSDATE = :P_DEMAND_DATE
                   AND MASTERVOUCHER.TRANSACTIONMODE = 1
                   AND MASTERVOUCHER.ACCOUNTCODE = '301001'
                   AND BRN_CODE = :P_BRN_CODE
          GROUP BY MASTERVOUCHER.TRANSACTIONMODE
          UNION ALL
          SELECT '2' IDEN,
                 'Transfer And TD' DESCRIPTION,
                 SUM (NOOFCREDIT) TOTAL_NO_CREDIT,
                 SUM (CREDIT) TOTAL_CREDIT,
                 SUM (NOOFDEBIT) TOTAL_NO_DEBIT,
                 SUM (DEBIT) TOTAL_DEBIT
            FROM MASTERVOUCHER
           WHERE     TRANSDATE = :P_DEMAND_DATE
                 AND MASTERVOUCHER.TRANSACTIONMODE > 2
                 AND BRN_CODE = :P_BRN_CODE) T
GROUP BY GROUPING SETS (
            (IDEN,
             DESCRIPTION,
             TOTAL_NO_CREDIT,
             TOTAL_CREDIT,
             TOTAL_NO_DEBIT,
             TOTAL_DEBIT),
            ())
UNION ALL
  SELECT '4' IDEN,
         'Contra Cash Receipt(+)' DESCRIPTION,
         0 TOTAL_NO_CREDIT,
         SUM (DEBIT) TOTAL_CREDIT,
         0 TOTAL_NO_DEBIT,
         0 TOTAL_DEBIT
    FROM MASTERVOUCHER
   WHERE     TRANSDATE = :P_DEMAND_DATE
         AND MASTERVOUCHER.TRANSACTIONMODE = 1
         AND MASTERVOUCHER.ACCOUNTCODE = '301001'
         AND BRN_CODE = :P_BRN_CODE
GROUP BY MASTERVOUCHER.TRANSACTIONMODE
UNION ALL
  SELECT '5' IDEN,
         'Contra Cash Payment(+)' DESCRIPTION,
         0 TOTAL_NO_CREDIT,
         0 TOTAL_CREDIT,
         0 TOTAL_NO_DEBIT,
         SUM (CREDIT) TOTAL_DEBIT
    FROM MASTERVOUCHER
   WHERE     TRANSDATE = :P_DEMAND_DATE
         AND MASTERVOUCHER.TRANSACTIONMODE = 1
         AND MASTERVOUCHER.ACCOUNTCODE = '301001'
         AND BRN_CODE = :P_BRN_CODE
GROUP BY MASTERVOUCHER.TRANSACTIONMODE) TOT_DATA
UNION ALL
(select '6', 'Grand Total: ', SUM(TOTAL_NO_CREDIT), SUM(TOTAL_CREDIT), SUM(TOTAL_NO_DEBIT), SUM(TOTAL_DEBIT)  from (SELECT TOT_DATA.*, ROWNUM row_num FROM 
(SELECT IDEN,
         NVL (DESCRIPTION, 'Scroll Grand Total') DESCRIPTION,
         SUM (TOTAL_NO_CREDIT) TOTAL_NO_CREDIT,
         SUM (TOTAL_CREDIT) TOTAL_CREDIT,
         SUM (TOTAL_NO_DEBIT) TOTAL_NO_DEBIT,
         SUM (TOTAL_DEBIT) TOTAL_DEBIT
    FROM (  SELECT '1' IDEN,
                   'Cash' DESCRIPTION,
                   SUM (NOOFCREDIT) TOTAL_NO_CREDIT,
                   SUM (CREDIT) TOTAL_CREDIT,
                   SUM (NOOFDEBIT) TOTAL_NO_DEBIT,
                   SUM (DEBIT) TOTAL_DEBIT
              FROM MASTERVOUCHER
             WHERE     TRANSDATE = :P_DEMAND_DATE
                   AND MASTERVOUCHER.TRANSACTIONMODE = 1
                   AND MASTERVOUCHER.ACCOUNTCODE = '301001'
                   AND BRN_CODE = :P_BRN_CODE
          GROUP BY MASTERVOUCHER.TRANSACTIONMODE
          UNION ALL
          SELECT '3' IDEN,
                 'Transfer And TD' DESCRIPTION,
                 SUM (NOOFCREDIT) TOTAL_NO_CREDIT,
                 SUM (CREDIT) TOTAL_CREDIT,
                 SUM (NOOFDEBIT) TOTAL_NO_DEBIT,
                 SUM (DEBIT) TOTAL_DEBIT
            FROM MASTERVOUCHER
           WHERE     TRANSDATE = :P_DEMAND_DATE
                 AND MASTERVOUCHER.TRANSACTIONMODE > 2
                 AND BRN_CODE = :P_BRN_CODE) T
GROUP BY GROUPING SETS (
            (IDEN,
             DESCRIPTION,
             TOTAL_NO_CREDIT,
             TOTAL_CREDIT,
             TOTAL_NO_DEBIT,
             TOTAL_DEBIT),
            ())
UNION ALL
  SELECT NULL IDEN,
         'Contra Cash Receipt(+)' DESCRIPTION,
         0 TOTAL_NO_CREDIT,
         SUM (DEBIT) TOTAL_CREDIT,
         0 TOTAL_NO_DEBIT,
         0 TOTAL_DEBIT
    FROM MASTERVOUCHER
   WHERE     TRANSDATE = :P_DEMAND_DATE
         AND MASTERVOUCHER.TRANSACTIONMODE = 1
         AND MASTERVOUCHER.ACCOUNTCODE = '301001'
         AND BRN_CODE = :P_BRN_CODE
GROUP BY MASTERVOUCHER.TRANSACTIONMODE
UNION ALL
  SELECT NULL IDEN,
         'Contra Cash Payment(+)' DESCRIPTION,
         0 TOTAL_NO_CREDIT,
         0 TOTAL_CREDIT,
         0 TOTAL_NO_DEBIT,
         SUM (CREDIT) TOTAL_DEBIT
    FROM MASTERVOUCHER
   WHERE     TRANSDATE = :P_DEMAND_DATE
         AND MASTERVOUCHER.TRANSACTIONMODE = 1
         AND MASTERVOUCHER.ACCOUNTCODE = '301001'
         AND BRN_CODE = :P_BRN_CODE
GROUP BY MASTERVOUCHER.TRANSACTIONMODE) TOT_DATA
 ) where ROW_NUM >= 3)
 
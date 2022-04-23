CREATE OR REPLACE PROCEDURE GET_LN_REPAY_DTLS (
   V_ENTITY_NUM          IN     NUMBER,
   P_INTERNAL_ACNUM      IN     NUMBER,
   P_RECOVERY_AMT        IN     NUMBER,
   P_REPAY_PRIN_AMT         OUT NUMBER,
   P_REPAY_INT_AMT          OUT NUMBER,
   P_REPAY_CHG_AMT          OUT NUMBER,
   P_OD_REPAY_PRIN_AMT      OUT NUMBER,
   P_OD_REPAY_INT_AMT       OUT NUMBER,
   P_OD_REPAY_CHG_AMT       OUT NUMBER,
   P_TOT_PRIN_AMT           OUT NUMBER,
   P_TOT_INT_AMT            OUT NUMBER,
   P_TOT_CHG_AMT            OUT NUMBER,
   P_ERR_MSG                OUT VARCHAR2,
   P_PARTIAL_REC_REQ        OUT CHAR)
IS
   ----Repay  Output  start---------
   W_REPAY_PRIN_AMT      NUMBER (18, 3) := 0;
   W_REPAY_INT_AMT       NUMBER (18, 3) := 0;
   W_REPAY_CHG_AMT       NUMBER (18, 3) := 0;
   ----Repay  Output  end ---------
   ----Repay OverDue Output  start---------
   W_OD_REPAY_PRIN_AMT   NUMBER (18, 3) := 0;
   W_OD_REPAY_INT_AMT    NUMBER (18, 3) := 0;
   W_OD_REPAY_CHG_AMT    NUMBER (18, 3) := 0;
   ----Repay OverDue Output  end ---------
   E_USEREXCEP           EXCEPTION;
   V_RECOVERY_AMT        NUMBER (18, 3) := 0;
   ----Outstanding  start---------
   W_PRIN_AMT            NUMBER (18, 3) := 0;
   W_INT_AMT             NUMBER (18, 3) := 0;
   W_CHG_AMT             NUMBER (18, 3) := 0;
   ----Outstanding end---------

   ----OverDue Outstanding  start---------
   W_OD_TOT_AMT          NUMBER (18, 3) := 0;
   W_OD_PRIN_AMT         NUMBER (18, 3) := 0;
   W_OD_INT_AMT          NUMBER (18, 3) := 0;
   W_OD_CHG_AMT          NUMBER (18, 3) := 0;
   ----Overdue Outstanding  end---------

   W_TOT_LOAN_BAL        NUMBER (18, 3) := 0;
   OS_PRIN_AMOUNT        NUMBER (18, 3) := 0;
   OS_INT_AMOUNT         NUMBER (18, 3) := 0;
   OS_CHG_AMOUNT         NUMBER (18, 3) := 0;
   TOT_SEG_AMOUNT        NUMBER (18, 3) := 0;
   W_SQL                 VARCHAR2 (2300);
   V_ERR_MSG             VARCHAR2 (1300);
   W_ASSET_CODE          VARCHAR2 (5);
   W_BRN_CODE            NUMBER (6);
   W_PROD_CODE           NUMBER (6);
   W_CURR_CODE           VARCHAR2 (5);
   W_CBD                 DATE;
   PRIORITY              CHAR (2);
   V_STR1                VARCHAR2 (100);
   V_COMMA_POS           NUMBER := 0;
   V_START_POS           NUMBER := 1;
   W_PRIORITY1           VARCHAR2 (50);
   W_REPAY_PERCENT       NUMBER (18, 3) := 0;
   W_PARTIAL_REC_REQ     CHAR (1) := '0';

   V_DEFAULT_PRIORITY    VARCHAR2 (100) := 'C,I,P,G';

   TYPE STR_ARRAY IS VARRAY (4) OF VARCHAR2 (50);

   W_PRIORITY            STR_ARRAY;

   LEN                   NUMBER (3);


   PROCEDURE PROCESS_FOR_REPAY
   IS
      W_ACCR_AMT         NUMBER (18, 3);
      V_RECOV_ACCR_AMT   NUMBER (18, 3);
      TOTAL_ACCR_AMT     NUMBER (18, 3);
   BEGIN
      SELECT NVL (SUM (MARKUPPROFLED_AMOUNT), 0)
        INTO W_ACCR_AMT
        FROM MARKUPPROFLED
       WHERE     MARKUPPROFLED_ENTITY_NUM = V_ENTITY_NUM
             AND MARKUPPROFLED_ACNT_NUM = P_INTERNAL_ACNUM
             AND MARKUPPROFLED_VALUE_DATE <= W_CBD
             AND MARKUPPROFLED_DB_CR_FLG = 'D'
             AND MARKUPPROFLED_AUTH_BY IS NOT NULL;

      BEGIN
         SELECT NVL (SUM (MARKUPPROFRECOV_INT_RECOV_AMT), 0)
           INTO V_RECOV_ACCR_AMT
           FROM MARKUPPROFRECOV
          WHERE     MARKUPPROFRECOV_ENTITY_NUM = V_ENTITY_NUM
                AND MARKUPPROFRECOV_INTERNAL_ACNUM = P_INTERNAL_ACNUM
                AND MARKUPPROFRECOV_AUTH_BY IS NOT NULL;
                
                
      EXCEPTION
         WHEN OTHERS
         THEN
            V_RECOV_ACCR_AMT := 0;
      END;

      TOTAL_ACCR_AMT := W_ACCR_AMT - V_RECOV_ACCR_AMT;

      IF P_RECOVERY_AMT > TOTAL_ACCR_AMT
      THEN
         P_REPAY_PRIN_AMT := P_RECOVERY_AMT - TOTAL_ACCR_AMT;

         P_TOT_PRIN_AMT := P_REPAY_PRIN_AMT;

         P_REPAY_INT_AMT := TOTAL_ACCR_AMT;

         P_TOT_INT_AMT := P_REPAY_INT_AMT;

         P_REPAY_CHG_AMT := 0;

         P_TOT_CHG_AMT := P_REPAY_CHG_AMT;
      END IF;

      IF P_RECOVERY_AMT <= TOTAL_ACCR_AMT
      THEN
         P_REPAY_PRIN_AMT := 0;

         P_TOT_PRIN_AMT := P_REPAY_PRIN_AMT;

         P_REPAY_INT_AMT := P_RECOVERY_AMT;

         P_TOT_INT_AMT := P_REPAY_INT_AMT;

         P_REPAY_CHG_AMT := 0;

         P_TOT_CHG_AMT := P_REPAY_CHG_AMT;
      END IF;
   END;


   PROCEDURE READ_ACNTS
   IS
   BEGIN
      W_SQL :=
         'SELECT ASSETCLS_ASSET_CODE,ACNTS_BRN_CODE,ACNTS_PROD_CODE,ACNTS_CURR_CODE FROM ACNTS,ASSETCLS
                WHERE ACNTS_ENTITY_NUM=ASSETCLS_ENTITY_NUM AND ACNTS_INTERNAL_ACNUM = ASSETCLS_INTERNAL_ACNUM  AND ACNTS_INTERNAL_ACNUM = :1';

      EXECUTE IMMEDIATE W_SQL
         INTO W_ASSET_CODE, W_BRN_CODE, W_PROD_CODE, W_CURR_CODE
         USING P_INTERNAL_ACNUM;
   END;

   PROCEDURE GET_LOAN_BALANCE
   IS
      W_DUMMY_D   DATE := NULL;
      W_DUMMY_V   VARCHAR2 (10) := '';
      W_DUMMY_N   NUMBER := 0;
   BEGIN
      SP_AVLBAL (PKG_ENTITY.FN_GET_ENTITY_CODE,
                 P_INTERNAL_ACNUM,
                 W_DUMMY_V,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_D,
                 W_DUMMY_V,
                 W_DUMMY_D,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_V,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 V_ERR_MSG,
                 W_DUMMY_V,
                 W_DUMMY_N,
                 W_PRIN_AMT,
                 W_INT_AMT,
                 W_CHG_AMT,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 W_DUMMY_N,
                 1);
      W_TOT_LOAN_BAL := W_PRIN_AMT + W_INT_AMT + W_CHG_AMT;
   END;

   PROCEDURE PROCESS_FOR_GETTING_OVERDUE
   IS
      W_DUMMY_V   VARCHAR2 (10) := '';
      W_DUMMY_N   NUMBER := 0;
   BEGIN
      PKG_LNOVERDUE.SP_LNOVERDUE (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                  P_INTERNAL_ACNUM,
                                  TO_CHAR (W_CBD, 'DD-MM-YYYY'),
                                  TO_CHAR (W_CBD, 'DD-MM-YYYY'),
                                  V_ERR_MSG,
                                  W_DUMMY_N,
                                  W_DUMMY_N,
                                  W_DUMMY_N,
                                  W_DUMMY_N,
                                  W_OD_TOT_AMT,
                                  W_DUMMY_V,
                                  W_OD_PRIN_AMT,
                                  W_DUMMY_V,
                                  W_OD_INT_AMT,
                                  W_DUMMY_V,
                                  W_OD_CHG_AMT,
                                  W_DUMMY_V);
      W_OD_TOT_AMT := NVL (W_OD_TOT_AMT, 0);
      W_OD_PRIN_AMT := NVL (W_OD_PRIN_AMT, 0);
      W_OD_INT_AMT := NVL (W_OD_INT_AMT, 0);
      W_OD_CHG_AMT := NVL (W_OD_CHG_AMT, 0);
   END;

   PROCEDURE CHECK_FOR_PARTIAL_REPAY
   IS
   BEGIN
      BEGIN
         W_SQL :=
            'SELECT NVL(LNRECPRIPMH_PARTIAL_REC_REQ,0)
     FROM LNRECPRIPMHIST H WHERE H.LNRECPRIPMH_ENTITY_NUM =PKG_ENTITY.FN_GET_ENTITY_CODE AND H.LNRECPRIPMH_PROD_CODE = :1 AND H.LNRECPRIPMH_CURR_CODE = :2
     AND H.LNRECPRIPMH_ASSET_CODE = :3 AND H.LNRECPRIPMH_EFFECTIVE_DATE = ( SELECT MAX (H.LNRECPRIPMH_EFFECTIVE_DATE)
     FROM LNRECPRIPMHIST H WHERE H.LNRECPRIPMH_ENTITY_NUM =PKG_ENTITY.FN_GET_ENTITY_CODE  AND H.LNRECPRIPMH_PROD_CODE = :4
     AND H.LNRECPRIPMH_CURR_CODE = :5 AND H.LNRECPRIPMH_ASSET_CODE = :6 AND H.LNRECPRIPMH_EFFECTIVE_DATE <= :7)';

         EXECUTE IMMEDIATE W_SQL
            INTO W_PARTIAL_REC_REQ
            USING W_PROD_CODE,
                  W_CURR_CODE,
                  W_ASSET_CODE,
                  W_PROD_CODE,
                  W_CURR_CODE,
                  W_ASSET_CODE,
                  W_CBD;

         P_PARTIAL_REC_REQ := W_PARTIAL_REC_REQ;
      EXCEPTION
         WHEN OTHERS
         THEN
            P_PARTIAL_REC_REQ := '0';
            W_PARTIAL_REC_REQ := '0';
      END;
   END;


   PROCEDURE PROCESS_FOR_PARTIAL_REPAY_DTL
   IS
      V_PRINCIPLE_PORTION   NUMBER (18, 3) := 0;
      V_INTEREST_PORTION    NUMBER (18, 3) := 0;
   BEGIN
      W_SQL :=
         'SELECT LISTAGG(M.PRI_TYPE, '','') WITHIN GROUP (ORDER BY M.PRI) REC_PRI FROM ( SELECT DECODE(I.L, 1, ''P'' || ''-'' || H.LNRECPRIPMH_RECPRI_PRIN_PER, 2, ''I'' || ''-'' || H.LNRECPRIPMH_RECPRI_INT_PER, 3, ''C'', 4, ''G'') PRI_TYPE,
 DECODE(I.L, 1, H.LNRECPRIPMH_RECPRI_PRINCIPAL, 2, H.LNRECPRIPMH_RECPRI_INTEREST,3, H.LNRECPRIPMH_RECPRI_CHGS, 4, H.LNRECPRIPMH_RECPRI_CHGSQ_GEN) PRI
 FROM LNRECPRIPMHIST H, (SELECT LEVEL L FROM DUAL CONNECT BY LEVEL <= 6) I
 WHERE H.LNRECPRIPMH_ENTITY_NUM =PKG_ENTITY.FN_GET_ENTITY_CODE AND H.LNRECPRIPMH_PROD_CODE = :1 AND H.LNRECPRIPMH_CURR_CODE = :2
 AND H.LNRECPRIPMH_ASSET_CODE = :3 AND H.LNRECPRIPMH_EFFECTIVE_DATE = ( SELECT MAX (H.LNRECPRIPMH_EFFECTIVE_DATE)
 FROM LNRECPRIPMHIST H WHERE H.LNRECPRIPMH_ENTITY_NUM =PKG_ENTITY.FN_GET_ENTITY_CODE  AND H.LNRECPRIPMH_PROD_CODE = :4
 AND H.LNRECPRIPMH_CURR_CODE = :5 AND H.LNRECPRIPMH_ASSET_CODE = :6 AND H.LNRECPRIPMH_EFFECTIVE_DATE <= :7)) M';

      EXECUTE IMMEDIATE W_SQL
         INTO W_PRIORITY1
         USING W_PROD_CODE,
               W_CURR_CODE,
               W_ASSET_CODE,
               W_PROD_CODE,
               W_CURR_CODE,
               W_ASSET_CODE,
               W_CBD;

      V_RECOVERY_AMT := P_RECOVERY_AMT;

      IF W_OD_TOT_AMT > 0
      THEN
         IF ABS (W_INT_AMT) >= V_RECOVERY_AMT
         THEN
            P_REPAY_INT_AMT := V_RECOVERY_AMT;
            V_RECOVERY_AMT := 0;
         ELSE
            P_REPAY_INT_AMT := ABS (W_INT_AMT);
            V_RECOVERY_AMT := V_RECOVERY_AMT - P_REPAY_INT_AMT;
         END IF;

         P_REPAY_PRIN_AMT := V_RECOVERY_AMT;
         RETURN;
      END IF;

      IF TRIM (W_PRIORITY1) IS NOT NULL
      THEN
         LOOP
            V_COMMA_POS := INSTR (W_PRIORITY1, ',', V_START_POS);
            V_STR1 :=
               SUBSTR (W_PRIORITY1, V_START_POS, (V_COMMA_POS - V_START_POS));

            IF V_COMMA_POS = 0
            THEN
               V_STR1 := SUBSTR (W_PRIORITY1, V_START_POS);
               EXIT;
            END IF;

            V_START_POS := V_COMMA_POS + 1;

            IF V_COMMA_POS = 0
            THEN
               EXIT;
            END IF;

            V_COMMA_POS := INSTR (V_STR1, '-');
            W_REPAY_PERCENT := 0;

            IF V_COMMA_POS > 0
            THEN
               W_REPAY_PERCENT := SUBSTR (V_STR1, (INSTR (V_STR1, '-') + 1));
               V_STR1 := SUBSTR (V_STR1, 0, (INSTR (V_STR1, '-') - 1));
            END IF;

            PRIORITY := V_STR1;

            CASE PRIORITY
               WHEN 'P'
               THEN
                  V_PRINCIPLE_PORTION :=
                     (P_RECOVERY_AMT * W_REPAY_PERCENT) / 100;

                  IF (V_PRINCIPLE_PORTION > 0)
                  THEN
                     IF (W_OD_PRIN_AMT > 0)
                     THEN
                        IF (V_PRINCIPLE_PORTION >= W_OD_PRIN_AMT)
                        THEN
                           W_OD_REPAY_PRIN_AMT := W_OD_PRIN_AMT;
                        ELSE
                           W_OD_REPAY_PRIN_AMT := V_PRINCIPLE_PORTION;
                        END IF;

                        V_PRINCIPLE_PORTION :=
                           V_PRINCIPLE_PORTION - W_OD_REPAY_PRIN_AMT;
                     END IF;

                     OS_PRIN_AMOUNT := ABS (W_PRIN_AMT) - W_OD_REPAY_PRIN_AMT;

                     IF (    (W_PRIN_AMT < 0)
                         AND (OS_PRIN_AMOUNT > 0)
                         AND (V_PRINCIPLE_PORTION > 0))
                     THEN
                        IF (V_PRINCIPLE_PORTION >= OS_PRIN_AMOUNT)
                        THEN
                           W_REPAY_PRIN_AMT := OS_PRIN_AMOUNT;
                        ELSE
                           W_REPAY_PRIN_AMT := V_PRINCIPLE_PORTION;
                        END IF;

                        V_PRINCIPLE_PORTION :=
                           V_PRINCIPLE_PORTION - W_REPAY_PRIN_AMT;
                     END IF;
                  END IF;
               WHEN 'I'
               THEN
                  V_INTEREST_PORTION :=
                     (P_RECOVERY_AMT * W_REPAY_PERCENT) / 100;

                  IF (V_INTEREST_PORTION > 0)
                  THEN
                     IF (W_OD_INT_AMT > 0)
                     THEN
                        IF (V_INTEREST_PORTION >= W_OD_INT_AMT)
                        THEN
                           W_OD_REPAY_INT_AMT := W_OD_INT_AMT;
                        ELSE
                           W_OD_REPAY_INT_AMT := V_INTEREST_PORTION;
                        END IF;

                        V_INTEREST_PORTION :=
                           (V_INTEREST_PORTION - W_OD_REPAY_INT_AMT);
                     END IF;

                     OS_INT_AMOUNT := ABS (W_INT_AMT) - W_OD_REPAY_INT_AMT;

                     IF (    (W_INT_AMT < 0)
                         AND (OS_INT_AMOUNT > 0)
                         AND (V_INTEREST_PORTION > 0))
                     THEN
                        IF (V_INTEREST_PORTION >= OS_INT_AMOUNT)
                        THEN
                           W_REPAY_INT_AMT := OS_INT_AMOUNT;
                        ELSE
                           W_REPAY_INT_AMT := V_INTEREST_PORTION;
                        END IF;

                        V_INTEREST_PORTION :=
                           V_INTEREST_PORTION - W_REPAY_INT_AMT;
                     END IF;
                  END IF;
               WHEN 'C'
               THEN
                  DBMS_OUTPUT.PUT_LINE ('  ');
            END CASE;
         END LOOP;

         P_TOT_PRIN_AMT := W_REPAY_PRIN_AMT + W_OD_REPAY_PRIN_AMT;
         P_TOT_INT_AMT := W_REPAY_INT_AMT + W_OD_REPAY_INT_AMT;
         P_TOT_CHG_AMT := W_REPAY_CHG_AMT + W_OD_REPAY_CHG_AMT;

         TOT_SEG_AMOUNT := P_TOT_PRIN_AMT + (P_TOT_INT_AMT) + (P_TOT_CHG_AMT);

         IF (P_RECOVERY_AMT <> TOT_SEG_AMOUNT)
         THEN
            W_REPAY_PRIN_AMT :=
               (W_REPAY_PRIN_AMT + (P_RECOVERY_AMT - TOT_SEG_AMOUNT));
            P_TOT_PRIN_AMT := W_REPAY_PRIN_AMT + (W_OD_REPAY_PRIN_AMT);
         END IF;


         P_REPAY_PRIN_AMT := W_REPAY_PRIN_AMT;
         P_REPAY_INT_AMT := W_REPAY_INT_AMT;
         P_REPAY_CHG_AMT := W_REPAY_CHG_AMT;
         P_OD_REPAY_PRIN_AMT := W_OD_REPAY_PRIN_AMT;
         P_OD_REPAY_INT_AMT := W_OD_REPAY_INT_AMT;
         P_OD_REPAY_CHG_AMT := W_OD_REPAY_CHG_AMT;
      ELSE
         V_ERR_MSG := 'Recovery Priority Parameter not defined ';
      END IF;
   END;

   PROCEDURE PROCESS_FOR_REPAY_DTL
   IS
   BEGIN
      W_SQL :=
         'SELECT LISTAGG(M.PRI_TYPE, '','') WITHIN GROUP (ORDER BY M.PRI) REC_PRI FROM ( SELECT DECODE(I.L, 1, ''P'', 2, ''I'', 3, ''C'', 4, ''G'') PRI_TYPE,
 DECODE(I.L, 1, H.LNRECPRIPMH_RECPRI_PRINCIPAL, 2, H.LNRECPRIPMH_RECPRI_INTEREST,3, H.LNRECPRIPMH_RECPRI_CHGS, 4, H.LNRECPRIPMH_RECPRI_CHGSQ_GEN) PRI
 FROM LNRECPRIPMHIST H, (SELECT LEVEL L FROM DUAL CONNECT BY LEVEL <= 6) I
 WHERE H.LNRECPRIPMH_ENTITY_NUM =PKG_ENTITY.FN_GET_ENTITY_CODE AND H.LNRECPRIPMH_PROD_CODE = :1 AND H.LNRECPRIPMH_CURR_CODE = :2
 AND H.LNRECPRIPMH_ASSET_CODE = :3 AND H.LNRECPRIPMH_EFFECTIVE_DATE = ( SELECT MAX (H.LNRECPRIPMH_EFFECTIVE_DATE)
 FROM LNRECPRIPMHIST H WHERE H.LNRECPRIPMH_ENTITY_NUM =PKG_ENTITY.FN_GET_ENTITY_CODE  AND H.LNRECPRIPMH_PROD_CODE = :4
 AND H.LNRECPRIPMH_CURR_CODE = :5 AND H.LNRECPRIPMH_ASSET_CODE = :6 AND H.LNRECPRIPMH_EFFECTIVE_DATE <= :7)) M';

      EXECUTE IMMEDIATE W_SQL
         INTO W_PRIORITY1
         USING W_PROD_CODE,
               W_CURR_CODE,
               W_ASSET_CODE,
               W_PROD_CODE,
               W_CURR_CODE,
               W_ASSET_CODE,
               W_CBD;

      IF TRIM (W_PRIORITY1) IS NULL
      THEN
         W_PRIORITY1 := V_DEFAULT_PRIORITY;
      END IF;

      V_RECOVERY_AMT := P_RECOVERY_AMT;

      LOOP
         V_COMMA_POS := INSTR (W_PRIORITY1, ',', V_START_POS);
         V_STR1 :=
            SUBSTR (W_PRIORITY1, V_START_POS, (V_COMMA_POS - V_START_POS));

         IF V_COMMA_POS = 0
         THEN
            V_STR1 := SUBSTR (W_PRIORITY1, V_START_POS);
            EXIT;
         END IF;

         V_START_POS := V_COMMA_POS + 1;

         IF V_COMMA_POS = 0
         THEN
            EXIT;
         END IF;

         PRIORITY := V_STR1;

         CASE PRIORITY
            WHEN 'C'
            THEN
               IF (V_RECOVERY_AMT > 0)
               THEN
                  IF (W_OD_CHG_AMT > 0)
                  THEN
                     IF (V_RECOVERY_AMT >= W_OD_CHG_AMT)
                     THEN
                        W_OD_REPAY_CHG_AMT := W_OD_CHG_AMT;
                     ELSE
                        W_OD_REPAY_CHG_AMT := V_RECOVERY_AMT;
                     END IF;

                     V_RECOVERY_AMT := (V_RECOVERY_AMT - W_OD_REPAY_CHG_AMT);
                  END IF;

                  OS_CHG_AMOUNT := ABS (W_CHG_AMT) - W_OD_REPAY_CHG_AMT;

                  IF (    (W_CHG_AMT < 0)
                      AND (OS_CHG_AMOUNT > 0)
                      AND (V_RECOVERY_AMT > 0))
                  THEN
                     IF (V_RECOVERY_AMT >= OS_CHG_AMOUNT)
                     THEN
                        W_REPAY_CHG_AMT := OS_CHG_AMOUNT;
                     ELSE
                        W_REPAY_CHG_AMT := V_RECOVERY_AMT;
                     END IF;

                     V_RECOVERY_AMT := (V_RECOVERY_AMT - W_REPAY_CHG_AMT);
                  END IF;
               END IF;
            WHEN 'P'
            THEN
               IF (V_RECOVERY_AMT > 0)
               THEN
                  IF (W_OD_PRIN_AMT > 0)
                  THEN
                     IF (V_RECOVERY_AMT >= W_OD_PRIN_AMT)
                     THEN
                        W_OD_REPAY_PRIN_AMT := W_OD_PRIN_AMT;
                     ELSE
                        W_OD_REPAY_PRIN_AMT := V_RECOVERY_AMT;
                     END IF;

                     V_RECOVERY_AMT := V_RECOVERY_AMT - W_OD_REPAY_PRIN_AMT;
                  END IF;

                  OS_PRIN_AMOUNT := ABS (W_PRIN_AMT) - W_OD_REPAY_PRIN_AMT;

                  IF (    (W_PRIN_AMT < 0)
                      AND (OS_PRIN_AMOUNT > 0)
                      AND (V_RECOVERY_AMT > 0))
                  THEN
                     IF (V_RECOVERY_AMT >= OS_PRIN_AMOUNT)
                     THEN
                        W_REPAY_PRIN_AMT := OS_PRIN_AMOUNT;
                     ELSE
                        W_REPAY_PRIN_AMT := V_RECOVERY_AMT;
                     END IF;

                     V_RECOVERY_AMT := V_RECOVERY_AMT - W_REPAY_PRIN_AMT;
                  END IF;
               END IF;
            WHEN 'I'
            THEN
               IF (V_RECOVERY_AMT > 0)
               THEN
                  IF (W_OD_INT_AMT > 0)
                  THEN
                     IF (V_RECOVERY_AMT >= W_OD_INT_AMT)
                     THEN
                        W_OD_REPAY_INT_AMT := W_OD_INT_AMT;
                     ELSE
                        W_OD_REPAY_INT_AMT := V_RECOVERY_AMT;
                     END IF;

                     V_RECOVERY_AMT := (V_RECOVERY_AMT - W_OD_REPAY_INT_AMT);
                  END IF;

                  OS_INT_AMOUNT := ABS (W_INT_AMT) - W_OD_REPAY_INT_AMT;

                  IF (    (W_INT_AMT < 0)
                      AND (OS_INT_AMOUNT > 0)
                      AND (V_RECOVERY_AMT > 0))
                  THEN
                     IF (V_RECOVERY_AMT >= OS_INT_AMOUNT)
                     THEN
                        W_REPAY_INT_AMT := OS_INT_AMOUNT;
                     ELSE
                        W_REPAY_INT_AMT := V_RECOVERY_AMT;
                     END IF;

                     V_RECOVERY_AMT := V_RECOVERY_AMT - W_REPAY_INT_AMT;
                  END IF;
               END IF;
         END CASE;
      END LOOP;

      P_TOT_PRIN_AMT := W_REPAY_PRIN_AMT + W_OD_REPAY_PRIN_AMT;
      P_TOT_INT_AMT := W_REPAY_INT_AMT + W_OD_REPAY_INT_AMT;
      P_TOT_CHG_AMT := W_REPAY_CHG_AMT + W_OD_REPAY_CHG_AMT;

      TOT_SEG_AMOUNT := P_TOT_PRIN_AMT + (P_TOT_INT_AMT) + (P_TOT_CHG_AMT);

      IF (P_RECOVERY_AMT <> TOT_SEG_AMOUNT)
      THEN
         W_REPAY_PRIN_AMT :=
            (W_REPAY_PRIN_AMT + (P_RECOVERY_AMT - TOT_SEG_AMOUNT));
         P_TOT_PRIN_AMT := W_REPAY_PRIN_AMT + (W_OD_REPAY_PRIN_AMT);
      END IF;

      P_REPAY_PRIN_AMT := W_REPAY_PRIN_AMT;
      P_REPAY_INT_AMT := W_REPAY_INT_AMT;
      P_REPAY_CHG_AMT := W_REPAY_CHG_AMT;
      P_OD_REPAY_PRIN_AMT := W_OD_REPAY_PRIN_AMT;
      P_OD_REPAY_INT_AMT := W_OD_REPAY_INT_AMT;
      P_OD_REPAY_CHG_AMT := W_OD_REPAY_CHG_AMT;
   END;

BEGIN
   PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

   SELECT MN_CURR_BUSINESS_DATE
     INTO W_CBD
     FROM MAINCONT
    WHERE MN_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE;

   BEGIN
      READ_ACNTS;
      --GET_LOAN_BALANCE;
      --PROCESS_FOR_GETTING_OVERDUE;
      --CHECK_FOR_PARTIAL_REPAY;

      --PROCESS_FOR_REPAY_DTL;

      PROCESS_FOR_REPAY;

      P_OD_REPAY_PRIN_AMT := 0;

      P_OD_REPAY_INT_AMT := 0;

      P_OD_REPAY_CHG_AMT := 0;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF TRIM (V_ERR_MSG) IS NULL
         THEN
            V_ERR_MSG := SUBSTR (SQLERRM, 1, 1000);
         END IF;
   END;

   IF TRIM (V_ERR_MSG) IS NULL
   THEN
      P_ERR_MSG := V_ERR_MSG;
   END IF;
END GET_LN_REPAY_DTLS;
/

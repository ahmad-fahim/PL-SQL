CREATE OR REPLACE PROCEDURE SP_GEN_TP_DATA (P_FROM_BRANCH    NUMBER,
                                             P_TO_BRANCH      NUMBER)
IS
   V_ASON_DATE   DATE;
   V_CBD         DATE;
BEGIN
   PKG_EODSOD_FLAGS.PV_PROCESS_NAME :=
      'PKG_TRANSACTION_PROFILE.START_BRN_CLONE';
   PKG_EODSOD_FLAGS.PV_USER_ID := 'INTELECT';
   PKG_EODSOD_FLAGS.PV_CALLED_BY_EOD_SOD := 1;
   PKG_EODSOD_FLAGS.PV_EODSODFLAG := 'E';

   FOR IDX IN (  SELECT *
                   FROM (SELECT T.*, ROWNUM BRANCH_SL
                           FROM (  SELECT *
                                     FROM MIG_DETAIL
                                 ORDER BY BRANCH_CODE) T)
                  WHERE BRANCH_SL BETWEEN P_FROM_BRANCH AND P_TO_BRANCH
               ORDER BY BRANCH_CODE)
   LOOP
      V_ASON_DATE := IDX.MIG_END_DATE;

      SELECT MN_CURR_BUSINESS_DATE INTO V_CBD FROM MAINCONT;

      BEGIN
         WHILE V_ASON_DATE < V_CBD
         LOOP
            PKG_EODSOD_FLAGS.PV_PREVIOUS_DATE := V_ASON_DATE - 1;
            PKG_EODSOD_FLAGS.PV_CURRENT_DATE := V_ASON_DATE;

            BEGIN
               PKG_TRANSACTION_PROFILE_V2.START_BRNWISE (1, IDX.BRANCH_CODE);
               DBMS_OUTPUT.PUT_LINE (PKG_EODSOD_FLAGS.PV_ERROR_MSG);

               INSERT INTO DATE_LOG
                    VALUES (V_ASON_DATE, IDX.BRANCH_CODE);

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            V_ASON_DATE := V_ASON_DATE + 1;
         END LOOP;
      END;
   END LOOP;
END SP_GEN_TP_DATA;
/

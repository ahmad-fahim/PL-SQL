CREATE OR REPLACE PACKAGE PKG_EODBAL_UPD IS

  -- AUTHOR  : PRASANTH NS
  -- CREATED : 8/23/2007 11:21:23 AM
  -- PURPOSE :

  PROCEDURE START_BRNWISE(V_ENTITY_NUM            IN NUMBER,
                        P_BRN_CODE              IN NUMBER DEFAULT 0) ;


  PROCEDURE SP_EODBAL_UPD(V_ENTITY_NUM IN NUMBER,P_BRN_CODE                IN NUMBER DEFAULT 0);


END PKG_EODBAL_UPD;
/


CREATE OR REPLACE PACKAGE BODY PKG_EODBAL_UPD
IS
   W_ENTITY_CODE   NUMBER (5) := 0;
   V_ASON_DATE     DATE;
   W_USER_ID       VARCHAR2 (8);

   PROCEDURE SP_EODBAL_UPD (V_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0)
   IS
      W_CBD         DATE;
      W_ERROR       VARCHAR2 (1300);

      E_USEREXCEP   EXCEPTION;

      PROCEDURE MOVETO_DENOMDBAL (W_BRN_CODE NUMBER)
      IS
      BEGIN
         INSERT INTO DENOMDBAL (DENOMDBAL_ENTITY_NUM,
                                DENOMDBAL_BRN_CODE,
                                DENOMDBAL_VAULT_NUMBER,
                                DENOMDBAL_CURR_CODE,
                                DENOMDBAL_COIN_NOTE,
                                DENOMDBAL_DENOM,
                                DENOMDBAL_DATE,
                                DENOMDBAL_CUR_GOOD_STOCK,
                                DENOMDBAL_CUR_SOILED_STOCK,
                                DENOMDBAL_CUR_CUT_STOCK)
            (SELECT PKG_ENTITY.FN_GET_ENTITY_CODE,
                    DENOMBAL_BRN_CODE,
                    DENOMBAL_VAULT_NUMBER,
                    DENOMBAL_CURR_CODE,
                    DENOMBAL_COIN_NOTE,
                    DENOMBAL_DENOM,
                    W_CBD,
                    DENOMBAL_CUR_GOOD_STOCK,
                    DENOMBAL_CUR_SOILED_STOCK,
                    DENOMBAL_CUR_CUT_STOCK
               FROM DENOMBAL
              WHERE     DENOMBAL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                    AND DENOMBAL_YEAR =
                           SP_GETFINYEAR (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                          W_CBD)
                    AND DENOMBAL_MONTH = TO_CHAR (W_CBD, 'MM')
                    AND DENOMBAL_BRN_CODE = W_BRN_CODE);
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR := 'Error in Creating DENOMDBAL';
            RAISE E_USEREXCEP;
      END MOVETO_DENOMDBAL;

      PROCEDURE MOVETO_SECASSIGNMTDBAL (W_BRN_CODE NUMBER)
      IS
      BEGIN
         INSERT INTO SECASSIGNMTDBAL (SECAGMTDBAL_ENTITY_NUM,
                                      SECAGMTDBAL_CLIENT_NUM,
                                      SECAGMTDBAL_LIMIT_LINE_NUM,
                                      SECAGMTDBAL_EFF_DATE,
                                      SECAGMTDBAL_SEC_NUM,
                                      SECAGMTDBAL_ASSIGN_PERC,
                                      -- Added Guna 31/07/2009 start
                                      SECAGMTDBAL_SEC_NATURE-- Added Guna 31/07/2009 end
                                      )
            (SELECT PKG_ENTITY.FN_GET_ENTITY_CODE,
                    SECAGMTBAL_CLIENT_NUM,
                    SECAGMTBAL_LIMIT_LINE_NUM,
                    W_CBD,
                    SECAGMTBAL_SEC_NUM,
                    SECAGMTBAL_ASSIGN_PERC,
                    -- Added Guna 31/07/2009 start
                    SECAGMTBAL_SEC_NATURE
               -- Added Guna 31/07/2009 end
               FROM SECASSIGNMTBAL, SECRCPT
              WHERE     SECAGMTBAL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                    AND SECRCPT_ENTITY_NUM = SECAGMTBAL_ENTITY_NUM
                    AND SECRCPT_CLIENT_NUM = SECAGMTBAL_CLIENT_NUM
                    AND SECRCPT_CREATED_BY_BRN = W_BRN_CODE);
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR := 'Error in Creating SECASSIGNMTDBAL';
            RAISE E_USEREXCEP;
      END MOVETO_SECASSIGNMTDBAL;

      PROCEDURE MOVETO_TELDBAL (W_BRN_CODE NUMBER)
      IS
      BEGIN
         INSERT INTO TELDBAL (TELDBAL_ENTITY_NUM,
                              TELDBAL_BRN_CODE,
                              TELDBAL_CT_ID,
                              TELDBAL_CURR_CODE,
                              TELDBAL_DATE,
                              TELDBAL_GOOD_BALANCE,
                              TELDBAL_SOILED_BALANCE,
                              TELDBAL_CUT_BALANCE,
                              TELDBAL_DEMONETIZED_BAL)
            (SELECT PKG_ENTITY.FN_GET_ENTITY_CODE,
                    TELBAL_BRN_CODE,
                    TELBAL_CT_ID,
                    TELBAL_CURR_CODE,
                    W_CBD,
                    TELBAL_GOOD_BALANCE,
                    TELBAL_SOILED_BALANCE,
                    TELBAL_CUT_BALANCE,
                    TELBAL_DEMONETIZED_BAL
               FROM TELBAL
              WHERE     TELBAL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                    AND TELBAL_BRN_CODE = W_BRN_CODE);
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR := 'Error in Creating TELDBAL';
            RAISE E_USEREXCEP;
      END MOVETO_TELDBAL;

      PROCEDURE MOVETO_TELDENOMDBAL (W_BRN_CODE NUMBER)
      IS
      BEGIN
         INSERT INTO TELDENOMDBAL (TDDB_ENTITY_NUM,
                                   TDDB_BRN_CODE,
                                   TDDB_CT_ID,
                                   TDDB_CURR_CODE,
                                   TDDB_COIN_NOTE,
                                   TDDB_DENOM,
                                   TDDB_DATE,
                                   TDDB_GOOD_BAL,
                                   TDDB_SOILED_BAL,
                                   TDDB_CUT_BAL,
                                   TDDB_DEMONETIZED_BAL)
            (SELECT PKG_ENTITY.FN_GET_ENTITY_CODE,
                    TDB_BRN_CODE,
                    TDB_CT_ID,
                    TDB_CURR_CODE,
                    TDB_COIN_NOTE,
                    TDB_DENOM,
                    W_CBD,
                    TDB_GOOD_BAL,
                    TDB_SOILED_BAL,
                    TDB_CUT_BAL,
                    TDB_DEMONETIZED_BAL
               FROM TELDENOMBAL
              WHERE     TDB_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                    AND TDB_BRN_CODE = W_BRN_CODE);
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR := 'Error in Creating TELDENOMDBAL';
            RAISE E_USEREXCEP;
      END MOVETO_TELDENOMDBAL;

      PROCEDURE MOVETO_VAULTDBAL (W_BRN_CODE NUMBER)
      IS
      BEGIN
         INSERT INTO VAULTDBAL (VAULTDBAL_ENTITY_NUM,
                                VAULTDBAL_BRN_CODE,
                                VAULTDBAL_VAULT_NUMBER,
                                VAULTDBAL_CURR_CODE,
                                VAULTDBAL_DATE,
                                VAULTDBAL_CUR_GOOD_BAL,
                                VAULTDBAL_CUR_SOILED_BAL,
                                VAULTDBAL_CUR_CUT_BAL)
            (SELECT PKG_ENTITY.FN_GET_ENTITY_CODE,
                    VAULTBAL_BRN_CODE,
                    VAULTBAL_VAULT_NUMBER,
                    VAULTBAL_CURR_CODE,
                    W_CBD,
                    VAULTBAL_CUR_GOOD_BAL,
                    VAULTBAL_CUR_SOILED_BAL,
                    VAULTBAL_CUR_CUT_BAL
               FROM VAULTBAL
              WHERE     VAULTBAL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                    AND VAULTBAL_YEAR =
                           SP_GETFINYEAR (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                          W_CBD)
                    AND VAULTBAL_MONTH = TO_CHAR (W_CBD, 'MM')
                    AND VAULTBAL_BRN_CODE = W_BRN_CODE);
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR := 'Error in Creating VAULTDBAL';
            RAISE E_USEREXCEP;
      END MOVETO_VAULTDBAL;

      --10-11-2010-beg
      PROCEDURE MOVETO_CICDENOMDBAL (W_BRN_CODE NUMBER)
      IS
      BEGIN
         INSERT INTO CICDENOMDBAL (CICDDBAL_ENTITY_NUM,
                                   CICDDBAL_BRN_CODE,
                                   CICDDBAL_CURR_CODE,
                                   CICDDBAL_COIN_NOTE,
                                   CICDDBAL_DENOM,
                                   CICDDBAL_DATE,
                                   CICDDBAL_BALANCE)
            (SELECT C.CICDBAL_ENTITY_NUM,
                    C.CICDBAL_BRN_CODE,
                    C.CICDBAL_CURR_CODE,
                    C.CICDBAL_COIN_NOTE,
                    C.CICDBAL_DENOM,
                    W_CBD,
                    C.CICDBAL_BALANCE
               FROM CICDENOMBAL C
              WHERE     C.CICDBAL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
                    AND C.CICDBAL_BRN_CODE = W_BRN_CODE);
      EXCEPTION
         WHEN OTHERS
         THEN
            W_ERROR := 'Error in Creating CICDENOMDBAL';
            RAISE E_USEREXCEP;
      END MOVETO_CICDENOMDBAL;

   --10-11-2010-end


   BEGIN
      --ENTITY CODE COMMONLY ADDED - 21-11-2009  - BEG
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

     --ENTITY CODE COMMONLY ADDED - 21-11-2009  - END
     <<START_PROC>>
      BEGIN
         W_ERROR := '';
         W_CBD := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;

         IF (W_CBD IS NULL)
         THEN
            W_ERROR := 'Current Business Date Should be Specified';
            RAISE E_USEREXCEP;
         END IF;

         MOVETO_DENOMDBAL (P_BRN_CODE);
         -- CHN Guna 12/11/2009 Romoved . B'z SECASSIGNMTDBAL updated in SECURITY Assignment Authorization
         --   MOVETO_SECASSIGNMTDBAL;

         MOVETO_TELDBAL (P_BRN_CODE);

         MOVETO_TELDENOMDBAL (P_BRN_CODE);

         MOVETO_VAULTDBAL (P_BRN_CODE);

         --10-11-2010-beg
         MOVETO_CICDENOMDBAL (P_BRN_CODE);
      --10-11-2010-end


      EXCEPTION
         WHEN OTHERS
         THEN
            IF TRIM (W_ERROR) IS NULL
            THEN
               W_ERROR := 'Error in SP_EODBAL_UPD ';
            END IF;

            PKG_EODSOD_FLAGS.PV_ERROR_MSG := W_ERROR;
            PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                         'E',
                                         PKG_EODSOD_FLAGS.PV_ERROR_MSG,
                                         ' ',
                                         0);
            PKG_PB_GLOBAL.DETAIL_ERRLOG (PKG_ENTITY.FN_GET_ENTITY_CODE,
                                         'E',
                                         SUBSTR (SQLERRM, 1, 1000),
                                         ' ',
                                         0);
      END START_PROC;
   END SP_EODBAL_UPD;



   PROCEDURE START_BRNWISE (V_ENTITY_NUM   IN NUMBER,
                            P_BRN_CODE     IN NUMBER DEFAULT 0)
   IS
      L_BRN_CODE   NUMBER (6);
   BEGIN
      PKG_ENTITY.SP_SET_ENTITY_CODE (V_ENTITY_NUM);

      W_ENTITY_CODE := V_ENTITY_NUM;
      PKG_PROCESS_CHECK.INIT_PROC_BRN_WISE (W_ENTITY_CODE, P_BRN_CODE);
      V_ASON_DATE := PKG_EODSOD_FLAGS.PV_CURRENT_DATE;
      W_USER_ID := PKG_EODSOD_FLAGS.PV_USER_ID;

      FOR IDX IN 1 .. PKG_PROCESS_CHECK.V_ACNTBRN.COUNT
      LOOP
         L_BRN_CODE := PKG_PROCESS_CHECK.V_ACNTBRN (IDX).LN_BRN_CODE;

         IF PKG_PROCESS_CHECK.CHK_BRN_ALREADY_PROCESSED (W_ENTITY_CODE,
                                                         L_BRN_CODE) = FALSE
         THEN
            SP_EODBAL_UPD (W_ENTITY_CODE, L_BRN_CODE);


            PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (W_ENTITY_CODE);
         END IF;


         IF TRIM (PKG_EODSOD_FLAGS.PV_ERROR_MSG) IS NULL
         THEN
            PKG_PROCESS_CHECK.INSERT_ROW_INTO_EODSODPROCBRN (W_ENTITY_CODE,
                                                             L_BRN_CODE);
         END IF;
      END LOOP;

      PKG_PROCESS_CHECK.CHECK_COMMIT_ROLLBACK_STATUS (W_ENTITY_CODE);
   END START_BRNWISE;
END PKG_EODBAL_UPD;
/
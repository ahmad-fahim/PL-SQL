CREATE OR REPLACE PROCEDURE  SP_GEN_BRNSEQ_NUM(V_ENTITY_NUM     IN NUMBER,
                                              P_BRN_CODE       IN NUMBER,
                                              P_CIF_NUM        IN NUMBER,
                                              P_PROD_CODE      IN NUMBER,
                                              P_CURR_CODE      IN CHAR,
                                              P_INTERNAL_ACNUM IN NUMBER,
                                              P_SEQ_NUM_IN     IN NUMBER,
                                              P_SEQ_NUM_OUT    OUT NUMBER,
                                              P_ACCOUNT_NUMBER OUT VARCHAR2,
                                              P_ERR_MSG        OUT VARCHAR2,
                                              P_UPD_REQD       IN NUMBER DEFAULT 1) IS
  TYPE RC IS REF CURSOR;

  V_PROCESS_OVER BOOLEAN DEFAULT FALSE;

  TYPE FROM_TO_NUM IS RECORD(
    V_FROM_NUM NUMBER(6),
    V_UPTO_NUM NUMBER(6));

  TYPE V_FROM_TO_NUM IS TABLE OF FROM_TO_NUM INDEX BY BINARY_INTEGER;

  PV_FROM_TO_NUM V_FROM_TO_NUM;

  V_BRN_CODE       ACNTLINK.ACNTLINK_BRN_CODE%TYPE;
  V_CIF_CODE       ACNTLINK.ACNTLINK_CIF_NUMBER%TYPE;
  V_SEQ_NUM        ACNTLINK.ACNTLINK_AC_SEQ_NUM%TYPE;
  V_PROD_CODE      ACNTS.ACNTS_PROD_CODE%TYPE;
  V_CURR_CODE      ACNTS.ACNTS_CURR_CODE%TYPE;
  V_ERR_MSG        VARCHAR2(2300);
  V_FROM_NUM       ACSEQDTL.ACSEQDTL_FROM_SEQ_NUM%TYPE;
  V_UPTO_NUM       ACSEQDTL.ACSEQDTL_UPTO_SEQ_NUM%TYPE;
  V_INTERNAL_AC    NUMBER;
  V_ACCOUNT_NUMBER VARCHAR2(25);
  V_UPD_REQD       NUMBER(1);
  --W_BANK_CODE1     VARCHAR2(6);

  PROCEDURE GET_SEQ_DTLSL IS
  BEGIN
    PV_FROM_TO_NUM.DELETE;
    BEGIN
      SELECT ACSEQDTL_FROM_SEQ_NUM, ACSEQDTL_UPTO_SEQ_NUM BULK COLLECT
        INTO PV_FROM_TO_NUM
        FROM ACSEQDTL
       WHERE ACSEQDTL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
         AND ACSEQDTL_PRODUCT_CODE = V_PROD_CODE
         AND ACSEQDTL_CURR_CODE = V_CURR_CODE
       ORDER BY ACSEQDTL_DTL_SL ASC;

      IF PV_FROM_TO_NUM.COUNT = 0 THEN
        BEGIN
          SELECT ACSEQDTL_FROM_SEQ_NUM, ACSEQDTL_UPTO_SEQ_NUM BULK COLLECT
            INTO PV_FROM_TO_NUM
            FROM ACSEQDTL
           WHERE ACSEQDTL_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
             AND ACSEQDTL_PRODUCT_CODE = V_PROD_CODE
             AND TRIM(ACSEQDTL_CURR_CODE) IS NULL
           ORDER BY ACSEQDTL_DTL_SL ASC;

          IF PV_FROM_TO_NUM.COUNT = 0 THEN
            V_FROM_NUM := 0;
            V_UPTO_NUM := 0;
          END IF;
        END;
      END IF;
    END;
  END;

  PROCEDURE CHECK_IN_ACNTLINK IS
    RC_SEQ  RC;
    V_SQL   VARCHAR2(2300);
    V_COUNT NUMBER;
    V_FOUND BOOLEAN;
  BEGIN
    V_COUNT := V_FROM_NUM;
    V_FOUND := FALSE;
    LOOP
      V_SQL := 'SELECT ACNTLINK_AC_SEQ_NUM FROM ACNTLINK WHERE ACNTLINK_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE AND  ' ||
               ' ACNTLINK_BRN_CODE = ' || V_BRN_CODE ||
               ' AND ACNTLINK_CIF_NUMBER = ' || V_CIF_CODE ||
               ' AND ACNTLINK_AC_SEQ_NUM = ' || V_COUNT;

      OPEN RC_SEQ FOR V_SQL;

      FETCH RC_SEQ
        INTO V_COUNT;

      IF RC_SEQ%FOUND THEN
        V_FOUND := FALSE;
      ELSE
        V_FOUND := TRUE;
      END IF;

      CLOSE RC_SEQ;

      V_SEQ_NUM := V_COUNT;
      V_COUNT   := V_COUNT + 1;

      IF V_FOUND = TRUE THEN
        EXIT;
      END IF;
    END LOOP;
  END;

  FUNCTION IS_SEQ_EXISTS RETURN BOOLEAN IS
    V_AC_SEQ NUMBER;
  BEGIN
    SELECT ACNTLINK_AC_SEQ_NUM
      INTO V_AC_SEQ
      FROM ACNTLINK
     WHERE ACNTLINK_ENTITY_NUM = PKG_ENTITY.FN_GET_ENTITY_CODE
       AND ACNTLINK_BRN_CODE = V_BRN_CODE
       AND ACNTLINK_CIF_NUMBER = V_CIF_CODE
       AND ACNTLINK_AC_SEQ_NUM = V_SEQ_NUM;

    IF SQL%FOUND THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END;

  PROCEDURE UPDATE_ACNTLINK IS
  BEGIN
    BEGIN
          SELECT TRIM(TO_CHAR(LPAD(V_BRN_CODE, (CASE WHEN NVL(C.ACNUMC_BRN_NUM_DIGITS,0)<4 THEN 4 ELSE C.ACNUMC_BRN_NUM_DIGITS END), '0')))

             || TRIM(TO_CHAR(V_CIF_CODE, '000000000000')) ||
             TRIM(TO_CHAR(V_SEQ_NUM, '000000'))
        INTO V_ACCOUNT_NUMBER

        FROM ACNUMCONFIG C;



    EXCEPTION
      WHEN OTHERS THEN
        V_ERR_MSG := 'Error in CBS_IMP Account Generation Parameter';
    END;

    IF TRIM(V_ACCOUNT_NUMBER) IS NOT NULL THEN
      INSERT INTO ACNTLINK
        (ACNTLINK_ENTITY_NUM,
         ACNTLINK_BRN_CODE,
         ACNTLINK_CIF_NUMBER,
         ACNTLINK_AC_SEQ_NUM,
         ACNTLINK_INTERNAL_ACNUM,
         ACNTLINK_ACCOUNT_NUMBER)
      VALUES
        (PKG_ENTITY.FN_GET_ENTITY_CODE,
         V_BRN_CODE,
         V_CIF_CODE,
         V_SEQ_NUM,
         NVL(V_INTERNAL_AC, 0),
         NVL(V_ACCOUNT_NUMBER, 0));
    ELSE
      V_ERR_MSG := 'Error in Account Number Updation';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      V_ERR_MSG := 'Error in Acntlink Updation';
  END;

  PROCEDURE UPDATE_IACLINK IS
  BEGIN
    INSERT INTO IACLINK
      (IACLINK_ENTITY_NUM,
       IACLINK_INTERNAL_ACNUM,
       IACLINK_BRN_CODE,
       IACLINK_CIF_NUMBER,
       IACLINK_AC_SEQ_NUM,
       IACLINK_ACCOUNT_NUMBER,
       IACLINK_PROD_CODE)
    VALUES
      (PKG_ENTITY.FN_GET_ENTITY_CODE,
       NVL(V_INTERNAL_AC, 0),
       V_BRN_CODE,
       V_CIF_CODE,
       V_SEQ_NUM,
       NVL(V_ACCOUNT_NUMBER, 0),
       NVL(V_PROD_CODE, 0));
  EXCEPTION
    WHEN OTHERS THEN
      V_ERR_MSG := 'Error in Iaclink Updation';
  END;

BEGIN
  PKG_ENTITY.SP_SET_ENTITY_CODE(V_ENTITY_NUM);
  V_BRN_CODE       := P_BRN_CODE;
  V_CIF_CODE       := P_CIF_NUM;
  V_SEQ_NUM        := 0;
  V_PROD_CODE      := P_PROD_CODE;
  V_CURR_CODE      := P_CURR_CODE;
  V_ERR_MSG        := ' ';
  V_FROM_NUM       := 0;
  V_UPTO_NUM       := 0;
  V_SEQ_NUM        := P_SEQ_NUM_IN;
  V_INTERNAL_AC    := 0;
  V_INTERNAL_AC    := P_INTERNAL_ACNUM;
  V_ACCOUNT_NUMBER := '';
  V_UPD_REQD       := NVL(P_UPD_REQD, 1);

  IF NVL(V_SEQ_NUM, 0) = 0 THEN
    V_SEQ_NUM := 0;
  END IF;

  IF V_SEQ_NUM <> 0 THEN
    IF IS_SEQ_EXISTS = TRUE THEN
      V_ERR_MSG := 'Account Sequence Number Already Exceeds';
      P_ERR_MSG := V_ERR_MSG;
      RETURN;
    END IF;
  END IF;

  IF V_SEQ_NUM = 0 THEN
    GET_SEQ_DTLSL;

    DBMS_OUTPUT.PUT_LINE(PV_FROM_TO_NUM.COUNT);

    IF PV_FROM_TO_NUM.COUNT > 0 THEN
      WHILE V_PROCESS_OVER = FALSE LOOP
        FOR IDX IN 1 .. PV_FROM_TO_NUM.COUNT LOOP
          V_FROM_NUM := PV_FROM_TO_NUM(IDX).V_FROM_NUM;
          V_UPTO_NUM := PV_FROM_TO_NUM(IDX).V_UPTO_NUM;

          IF NVL(V_FROM_NUM, 0) <> 0 THEN
            V_FROM_NUM := (V_PROD_CODE * 100) + V_FROM_NUM;
            V_UPTO_NUM := (V_PROD_CODE * 100) + V_UPTO_NUM;
          END IF;

          IF NVL(V_FROM_NUM, 0) <> 0 THEN
            CHECK_IN_ACNTLINK;

            IF V_SEQ_NUM <= V_UPTO_NUM THEN
              V_PROCESS_OVER := TRUE;
              EXIT;
            ELSE
              V_SEQ_NUM := 0;
            END IF;
          ELSE
            V_SEQ_NUM      := 0;
            V_ERR_MSG      := 'Account Sequence Number Generation Details not Defined';
            V_PROCESS_OVER := TRUE;
          END IF;
        END LOOP;

        V_PROCESS_OVER := TRUE;
      END LOOP;
    ELSE
      V_SEQ_NUM := 0;
      V_ERR_MSG := 'Account Sequence Number Generation Details not Defined';
    END IF;
  END IF;

  PV_FROM_TO_NUM.DELETE;

  IF V_SEQ_NUM <> 0 THEN
    UPDATE_ACNTLINK;
    IF V_UPD_REQD = 1 THEN
      UPDATE_IACLINK;
    END IF;
  ELSE
    V_ERR_MSG := 'Error in Sequence Number Generation ';
  END IF;

  P_SEQ_NUM_OUT    := V_SEQ_NUM;
  P_ERR_MSG        := V_ERR_MSG;
  P_ACCOUNT_NUMBER := V_ACCOUNT_NUMBER;
END;
/
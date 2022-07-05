CREATE OR REPLACE TRIGGER TRG_NEW_ACNT_OPEN_LOANS
   BEFORE INSERT OR UPDATE
   ON LOANACNTS
   FOR EACH ROW
DECLARE
   V_AC_NUM              NUMBER;
   V_PROD_CODE           NUMBER;
   V_AUTH_DATE_TIME      DATE;
   V_BRN_CODE            NUMBER;
   V_CBD                 DATE;
   V_OLD_AUTH_DATE       DATE;
   V_PRODUCT_FOR_LOANS   VARCHAR2 (1);
   V_LAD_ACNT            VARCHAR2 (1);
BEGIN
   V_AC_NUM := :NEW.LNACNT_INTERNAL_ACNUM;
   V_OLD_AUTH_DATE := :OLD.LNACNT_AUTH_ON;
   V_AUTH_DATE_TIME := :NEW.LNACNT_AUTH_ON;
   V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (:NEW.LNACNT_ENTITY_NUM);

   BEGIN
      SELECT ACNTS_BRN_CODE, ACNTS_PROD_CODE
        INTO V_BRN_CODE, V_PROD_CODE
        FROM ACNTS
       WHERE     ACNTS_ENTITY_NUM = :NEW.LNACNT_ENTITY_NUM
             AND ACNTS_INTERNAL_ACNUM = :NEW.LNACNT_INTERNAL_ACNUM;
   END;

   IF V_AUTH_DATE_TIME IS NOT NULL
   THEN
      SELECT PRODUCT_FOR_LOANS
        INTO V_PRODUCT_FOR_LOANS
        FROM PRODUCTS
       WHERE PRODUCT_CODE = V_PROD_CODE;

      IF V_PRODUCT_FOR_LOANS = '1'
      THEN
         BEGIN
            SELECT LNPRD_DEPOSIT_LOAN
              INTO V_LAD_ACNT
              FROM LNPRODPM
             WHERE LNPRD_PROD_CODE = V_PROD_CODE;
         END;

         IF V_OLD_AUTH_DATE IS NULL
         THEN
            IF V_LAD_ACNT = '1'
            THEN
               INSERT INTO SMSALERTQ (SMSALERTQ_ENTITY_NUM,
                                      SMSALERTQ_TYPE,
                                      SMSALERTQ_BRN_CODE,
                                      SMSALERTQ_DATE_OF_TRAN,
                                      SMSALERTQ_BATCH_NUMBER,
                                      SMSALERTQ_BATCH_SL_NUM,
                                      SMSALERTQ_SRC_TABLE,
                                      SMSALERTQ_SRC_KEY,
                                      SMSALERTQ_DISP_TEXT,
                                      SMSALERTQ_REQ_TIME)
                    VALUES (:NEW.LNACNT_ENTITY_NUM,
                            'AC',
                            V_BRN_CODE,
                            V_CBD,
                            0,
                            0,
                            'LADACNTS',
                            V_AC_NUM,
                            ' ',
                            SYSDATE);
            ELSE
               INSERT INTO SMSALERTQ (SMSALERTQ_ENTITY_NUM,
                                      SMSALERTQ_TYPE,
                                      SMSALERTQ_BRN_CODE,
                                      SMSALERTQ_DATE_OF_TRAN,
                                      SMSALERTQ_BATCH_NUMBER,
                                      SMSALERTQ_BATCH_SL_NUM,
                                      SMSALERTQ_SRC_TABLE,
                                      SMSALERTQ_SRC_KEY,
                                      SMSALERTQ_DISP_TEXT,
                                      SMSALERTQ_REQ_TIME)
                    VALUES (:NEW.LNACNT_ENTITY_NUM,
                            'AC',
                            V_BRN_CODE,
                            V_CBD,
                            0,
                            0,
                            'LOANACNTS',
                            V_AC_NUM,
                            ' ',
                            SYSDATE);
            END IF;
         END IF;
      END IF;
   END IF;
END TRG_NEW_ACNT_OPEN_LOANS;
/

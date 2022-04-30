CREATE OR REPLACE TRIGGER TRG_NEW_ACNT_OPEN_CASA 
   BEFORE INSERT OR UPDATE
   ON ACNTS
   FOR EACH ROW
DECLARE
   V_AC_NUM                 NUMBER;
   V_PROD_CODE              NUMBER;
   V_AUTH_DATE_TIME         DATE;
   V_PRODUCT_FOR_DEPOSITS   VARCHAR2 (1);
   V_PRODUCT_FOR_RUN_ACS    VARCHAR2 (1);
   V_BRN_CODE               NUMBER;
   V_CBD                    DATE;
   V_OLD_AUTH_DATE          DATE;
BEGIN
   V_AC_NUM := :NEW.ACNTS_INTERNAL_ACNUM;
   V_PROD_CODE := :NEW.ACNTS_PROD_CODE;
   V_OLD_AUTH_DATE := :OLD.ACNTS_AUTH_ON;
   V_AUTH_DATE_TIME := :NEW.ACNTS_AUTH_ON;
   V_BRN_CODE := :NEW.ACNTS_BRN_CODE;
   V_CBD := PKG_PB_GLOBAL.FN_GET_CURR_BUS_DATE (:NEW.ACNTS_ENTITY_NUM);

   IF V_AUTH_DATE_TIME IS NOT NULL
   THEN
      SELECT PRODUCT_FOR_DEPOSITS, PRODUCT_FOR_RUN_ACS
        INTO V_PRODUCT_FOR_DEPOSITS, V_PRODUCT_FOR_RUN_ACS
        FROM PRODUCTS
       WHERE PRODUCT_CODE = V_PROD_CODE;

      IF V_PRODUCT_FOR_DEPOSITS = '1' AND V_PRODUCT_FOR_RUN_ACS = '1'
      THEN
         IF V_OLD_AUTH_DATE IS NULL
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
                 VALUES (:NEW.ACNTS_ENTITY_NUM,
                         'AC',
                         V_BRN_CODE,
                         V_CBD,
                         0,
                         0,
                         'ACNTS',
                         V_AC_NUM,
                         ' ',
                         SYSDATE);
         END IF;
      END IF;
   END IF;
END TRG_NEW_ACNT_OPEN_CASA;
/
CREATE OR REPLACE TRIGGER UPDATE_CHECK_MIG_LNAC_ACCRU
  AFTER UPDATE OF LNACNT_INT_ACCR_UPTO ON MIG_LNACNT
  FOR EACH ROW
DECLARE
  V_SQL VARCHAR2(100);
  PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_ACNTS_ACCRUAL DISABLE';
  EXECUTE IMMEDIATE V_SQL;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_ACNTS_PAID DISABLE';
  EXECUTE IMMEDIATE V_SQL;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_LNAC_APPLIED DISABLE';
  EXECUTE IMMEDIATE V_SQL;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_PBDCONT_ACCRU DISABLE';
  EXECUTE IMMEDIATE V_SQL;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_PBDCONT_PAID DISABLE';
  EXECUTE IMMEDIATE V_SQL;

  UPDATE MIG_ACNTS
     SET ACNTS_INT_ACCR_UPTO = :NEW.LNACNT_INT_ACCR_UPTO,
         ACNTS_INT_CALC_UPTO = :NEW.LNACNT_INT_ACCR_UPTO
   WHERE ACNTS_ACNUM = :OLD.LNACNT_ACNUM;

  UPDATE TEMP_LOANIA
     SET LOANIA_VALUE_DATE   = :NEW.LNACNT_INT_ACCR_UPTO,
         LOANIA_ACCRUAL_DATE = :NEW.LNACNT_INT_ACCR_UPTO
   WHERE LOANIA_ACNT_NUM = :OLD.LNACNT_ACNUM;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_ACNTS_ACCRUAL ENABLE';
  EXECUTE IMMEDIATE V_SQL;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_ACNTS_PAID ENABLE';
  EXECUTE IMMEDIATE V_SQL;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_LNAC_APPLIED ENABLE';
  EXECUTE IMMEDIATE V_SQL;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_PBDCONT_ACCRU ENABLE';
  EXECUTE IMMEDIATE V_SQL;

  V_SQL := 'ALTER TRIGGER UPDATE_CHECK_MIG_PBDCONT_PAID ENABLE';
  EXECUTE IMMEDIATE V_SQL;

END UPDATE_CHECK_MIG_LNAC_ACCRU;
/
SHOW ERRORS;
/
CREATE OR REPLACE PROCEDURE SP_MACRO_CLIENTS

 IS

  W_MIG_DATE DATE;
  W_BRN_CODE NUMBER(5);
  W_ROWCOUNT NUMBER := 0;

BEGIN


  DELETE FROM ERRORLOG WHERE TEMPLATE_NAME = 'MIG_PIDDOCS';
  COMMIT;
  
  
  SELECT DISTINCT ACOP_BRANCH_CODE INTO W_BRN_CODE FROM MIG_ACOP_BAL;
  SELECT DISTINCT ACOP_BAL_DATE INTO W_MIG_DATE FROM MIG_ACOP_BAL;

  BEGIN
    SP_CLIENTS_VALIDATE(W_BRN_CODE, W_MIG_DATE);
  END;

  BEGIN
    SP_JOINTCLIENTS_VALIDATE(W_BRN_CODE, W_MIG_DATE);
  END;



  ----  checking piddocs client code

  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_PIDDOCS
   WHERE PIDDOCS_CLIENTS_CODE NOT IN
         (SELECT CLIENTS_CODE
            FROM MIG_CLIENTS
          UNION ALL
          SELECT JNTCL_JCL_SL
            FROM MIG_JOINTCLIENTS );

  IF W_ROWCOUNT > 0 THEN

    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_PIDDOCS',
       'PIDDOCS_CLIENTS_CODE',
       W_ROWCOUNT,
       'PIDDOCS_CLIENTS_CODE NOT FOUND IN MAIN CLIENT CODE',
       'SELECT *  FROM MIG_PIDDOCS C
               WHERE C.PIDDOCS_CLIENTS_CODE NOT IN
       (SELECT CC.CLIENTS_CODE
          FROM MIG_CLIENTS CC
        UNION ALL
        SELECT J.JNTCL_JCL_SL
          FROM MIG_JOINTCLIENTS J);');

  END IF;
  
  
  ----SECURITY VALIDATION 
  
  SELECT COUNT(*) INTO W_ROWCOUNT
  FROM MIG_SEC_REGIS_TEMP
 WHERE SECRCPT_CLIENT_NUM NOT IN (SELECT CLIENTS_CODE
            FROM MIG_CLIENTS
          UNION ALL
          SELECT JNTCL_JCL_SL
            FROM MIG_JOINTCLIENTS );

  IF W_ROWCOUNT > 0 THEN

    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_SEC_REGIS_TEMP',
       'SECRCPT_CLIENT_NUM',
       W_ROWCOUNT,
       'SECRCPT_CLIENT_NUM NOT FOUND IN MAIN CLIENT CODE',
       'SELECT SECRCPT_SECURITY_NUM,
       SECRCPT_CREATED_BY_BRN,
       SECRCPT_CLIENT_NUM,
       SECRCPT_SEC_TYPE
  FROM MIG_SEC_REGIS_TEMP
 WHERE SECRCPT_CLIENT_NUM NOT IN (SELECT CLIENTS_CODE FROM MIG_CLIENTS);');

  END IF;
  
 ---MORT VALIDATION
  SELECT COUNT(*) INTO  W_ROWCOUNT
  FROM MIG_SECMORT
 WHERE SECMORT_CLIENT_NUM NOT IN (SELECT CLIENTS_CODE
            FROM MIG_CLIENTS
          UNION ALL
          SELECT JNTCL_JCL_SL
            FROM MIG_JOINTCLIENTS);

  IF W_ROWCOUNT > 0 THEN

    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_SECMORT',
       'SECMORT_CLIENT_NUM',
       W_ROWCOUNT,
       'SECMORT_CLIENT_NUM NOT FOUND IN MAIN CLIENT CODE',
       'SELECT SECMORT_BRN_CODE, 
SECMORT_SEC_SL_NUM,
SECMORT_CLIENT_NUM
  FROM MIG_SECMORT
 WHERE SECMORT_CLIENT_NUM NOT IN (SELECT CLIENTS_CODE FROM MIG_CLIENTS);');

  END IF;
  

END SP_MACRO_CLIENTS;
/
CREATE OR REPLACE PROCEDURE SP_CLIENTS_VALIDATE (
   P_BRANCH_CODE       IN NUMBER,
   P_START_DATE        IN DATE)
  -- P_PREVIOUS_VENDOR      VARCHAR2)
IS
   W_BRN_CODE          NUMBER (5) := P_BRANCH_CODE;
  -- W_MIG_DATE          DATE := P_START_DATE;
  -- W_PREVIOUS_VENDOR   VARCHAR2 (255) := P_PREVIOUS_VENDOR;
   W_ROWCOUNT NUMBER := 0;
 --  W_CLIENT_NUMBER     NUMBER (12);
-- W_VAR NUMBER(1):= 2;


BEGIN
  DELETE FROM ERRORLOG WHERE TEMPLATE_NAME = 'MIG_CLIENTS';
  COMMIT;


   UPDATE MIG_CLIENTS
      SET CLIENTS_SEGMENT_CODE = '915051'
    WHERE CLIENTS_SEGMENT_CODE NOT IN (SELECT SEGMENTS_CODE FROM SEGMENTS);
    COMMIT;
    
    UPDATE MIG_CLIENTS
      SET CLIENTS_SEGMENT_CODE = '915051'
    WHERE CLIENTS_SEGMENT_CODE IS NULL ;
    COMMIT;

   UPDATE MIG_CLIENTS
      SET CLIENTS_INDUS_CODE = 'G'
    WHERE CLIENTS_INDUS_CODE NOT IN (SELECT INDUSTRY_CODE FROM INDUSTRIES);
    COMMIT;

   UPDATE MIG_CLIENTS
      SET CLIENTS_SUB_INDUS_CODE = '9909'
    WHERE CLIENTS_SUB_INDUS_CODE NOT IN
             (SELECT SUBINDUS_CODE FROM SUBINDUSTRIES);
             COMMIT;

    UPDATE MIG_CLIENTS
       SET CLIENTS_ENTD_ON = CLIENTS_OPENING_DATE
       WHERE CLIENTS_ENTD_ON < CLIENTS_OPENING_DATE ;
       COMMIT;


--- checking clients branch code


SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_CLIENTS
   WHERE NVL(CLIENTS_HOME_BRN_CODE, 0 ) <> W_BRN_CODE;

  IF W_ROWCOUNT > 0
    THEN

    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_CLIENTS',
       'CLIENTS_HOME_BRN_CODE',
       W_ROWCOUNT,
       'CLIENTS BRANCH SHOULD BE ' || W_BRN_CODE,
       'SELECT * FROM MIG_CLIENTS  WHERE NVL(CLIENTS_HOME_BRN_CODE, 0 ) <> ' || W_BRN_CODE);

  END IF;


--- checking if client name is null

SELECT COUNT(*)
  INTO W_ROWCOUNT
  FROM MIG_CLIENTS
 WHERE CLIENTS_NAME IS NULL
   AND CLIENT_FIRST_NAME IS NULL;

  IF W_ROWCOUNT > 0
    THEN
INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_CLIENTS',
       'CLIENTS_NAME',
       W_ROWCOUNT,
       'CLIENTS NAME CAN NOT BE EMPTY',
       'SELECT * FROM MIG_CLIENTS WHERE CLIENTS_NAME IS NULL AND CLIENT_FIRST_NAME IS NULL;'  );


END IF;


--checking CLIENTS_OPENING_DATE


   SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_CLIENTS
   WHERE ( NVL(CLIENTS_OPENING_DATE, '31-DEC-1899') NOT BETWEEN
                      '01-JAN-1900' AND '31-DEC-2050') OR
                      CLIENTS_OPENING_DATE > P_START_DATE;

  IF W_ROWCOUNT > 0
    THEN

INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_CLIENTS',
       'CLIENTS_OPENING_DATE',
       W_ROWCOUNT,
       'ERROR IN CLIENTS OPENING DATE',
       'SELECT CLIENTS_CODE, CLIENTS_TYPE_FLG, CLIENTS_OPENING_DATE  FROM MIG_CLIENTS WHERE (NVL(CLIENTS_OPENING_DATE, ''31-DEC-1899'') not between
                      ''01-jan-1900'' and ''31-dec-2050'') or
                      CLIENTS_OPENING_DATE > ''' || P_START_DATE || ''';'  );

  END IF;



--- checking clients birthdate


   SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_CLIENTS
   WHERE ( CLIENTS_BIRTH_DATE NOT BETWEEN
                      '01-JAN-1900' AND '31-DEC-2050') OR
                      CLIENTS_BIRTH_DATE > P_START_DATE;

  IF W_ROWCOUNT > 0
    THEN

INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_CLIENTS',
       'CLIENTS_BIRTH_DATE',
       W_ROWCOUNT,
       'CLIENTS_BIRTH_DATE IS GREATER THAN MIGRATION DATE',
       'SELECT CLIENTS_CODE, CLIENTS_TYPE_FLG, CLIENTS_OPENING_DATE, CLIENTS_BIRTH_DATE
        FROM MIG_CLIENTS WHERE (CLIENTS_BIRTH_DATE NOT BETWEEN
                      ''01-JAN-1900'' AND ''31-DEC-2050'') OR
                      CLIENTS_BIRTH_DATE > ''' || P_START_DATE || ''';
                      
                      
------------------------- UPDATE ------------------------- 


update MIG_CLIENTS c
   SET c.clients_birth_date = ADD_MONTHS(clients_birth_date, -1200)
 WHERE (CLIENTS_BIRTH_DATE NOT BETWEEN 
        ''01 - JAN - 1900'' AND ''31 - DEC - 2050'') OR
        CLIENTS_BIRTH_DATE > ''' || P_START_DATE || ''';

 ');

  END IF;


--- checking CLIENTS_ENTD_ON


   SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_CLIENTS
   WHERE ( CLIENTS_ENTD_ON NOT BETWEEN
                      '01-JAN-1900' AND '31-DEC-2050') OR
                      CLIENTS_ENTD_ON > P_START_DATE;

  IF W_ROWCOUNT > 0
    THEN

INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_CLIENTS',
       'CLIENTS_ENTD_ON',
       W_ROWCOUNT,
       'CLIENTS_ENTD_ON IS GREATER THAN MIGRATION DATE',
       'SELECT CLIENTS_CODE, CLIENTS_TYPE_FLG, CLIENTS_OPENING_DATE,CLIENTS_ENTD_ON
        FROM MIG_CLIENTS WHERE (CLIENTS_ENTD_ON NOT BETWEEN
                      ''01-JAN-1900'' AND ''31-DEC-2050'') OR
                      CLIENTS_ENTD_ON > ''' || P_START_DATE || ''';'  );

  END IF;

END SP_CLIENTS_VALIDATE;
/
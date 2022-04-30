CREATE OR REPLACE PROCEDURE SP_ACNTLIEN_VALIDATE(P_BRANCH_CODE     IN NUMBER,
                                              P_START_DATE      IN DATE)
                                            --  P_PREVIOUS_VENDOR VARCHAR2) 
                                              
                                              
 IS
  W_ROWCOUNT NUMBER := 0;

BEGIN
  DELETE FROM ERRORLOG WHERE TEMPLATE_NAME = 'MIG_ACNTLIEN';
  COMMIT;


  --- branch code checking 
  
  
  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ACNTLIEN
   WHERE NVL(ACNTLIEN_LIEN_TO_BRN, 0) <> P_BRANCH_CODE;
   
IF W_ROWCOUNT > 0 THEN
  INSERT INTO ERRORLOG
    (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
  VALUES
    ('MIG_ACNTLIEN',
     'ACNTLIEN_LIEN_TO_BRN',
     W_ROWCOUNT,
     'ACNTLIEN_LIEN_TO_BRN SHOULD BE ' || P_BRANCH_CODE,
     'SELECT ACNTLIEN_ACNUM, ACNTLIEN_LIEN_TO_BRN FROM MIG_ACNTLIEN  WHERE  NVL(ACNTLIEN_LIEN_TO_BRN, 0) <>' ||
     P_BRANCH_CODE || ';');
      END IF;


-- Same ACNTLIEN_LIEN_TO_ACNUM checking
  
  
  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ACNTLIEN
   WHERE ACNTLIEN_ACNUM = ACNTLIEN_LIEN_TO_ACNUM;

  IF W_ROWCOUNT > 0 THEN
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ACNTLIEN',
       'ACNTLIEN_LIEN_TO_ACNUM',
       W_ROWCOUNT,
       'ACNTLIEN_ACNUM and ACNTLIEN_LIEN_TO_ACNUM should not be same',
       'SELECT ACNTLIEN_ACNUM, ACNTLIEN_LIEN_TO_ACNUM FROM MIG_ACNTLIEN WHERE ACNTLIEN_ACNUM = ACNTLIEN_LIEN_TO_ACNUM;');
  END IF;


--- Checking ACNTLIEN_ACNUM in main account of  MIG_ACNTS
  
  
  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ACNTLIEN
   WHERE NVL(ACNTLIEN_ACNUM, 0) NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);

  IF W_ROWCOUNT > 0 THEN
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ACNTLIEN',
       'ACNTLIEN_ACNUM',
       W_ROWCOUNT,
       'ACNTLIEN_ACNUM NOT FOUND IN MAIN ACCOUNT OF MIG_ACNTS',
       'SELECT * FROM MIG_ACNTLIEN WHERE NVL(ACNTLIEN_ACNUM, 0) NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);');
  END IF;


--- checking ACNTLIEN_LIEN_TO_ACNUM in MIG_ACNTS


  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ACNTLIEN
   WHERE NVL(ACNTLIEN_LIEN_TO_ACNUM, 0) NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);

  IF W_ROWCOUNT > 0 THEN
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ACNTLIEN',
       'ACNTLIEN_LIEN_TO_ACNUM',
       W_ROWCOUNT,
       'ACNTLIEN_LIEN_TO_ACNUM NOT FOUND IN MAIN ACCOUNT OF MIG_ACNTS',
       'SELECT * FROM MIG_ACNTLIEN WHERE NVL(ACNTLIEN_LIEN_TO_ACNUM, 0) NOT IN (SELECT ACNTS_ACNUM FROM MIG_ACNTS);');
  END IF;
  
  
  -- Checking acntlien_lien_date is not greater than migration date
 
  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ACNTLIEN
   WHERE (NVL(ACNTLIEN_LIEN_DATE, '31-DEC-1899') not between
                      '01-jan-1900' and '31-dec-2050') or
                      ACNTLIEN_LIEN_DATE > P_START_DATE;

  IF W_ROWCOUNT > 0 THEN
    INSERT INTO ERRORLOG
      (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
    VALUES
      ('MIG_ACNTLIEN',
       'ACNTLIEN_LIEN_DATE',
       W_ROWCOUNT,
       'LIEN DATE CANNOT BE GGREATER THAN MIGRATION DATE',
       'SELECT ACNTLIEN_ACNUM, ACNTLIEN_LIEN_DATE
  FROM MIG_ACNTLIEN
 WHERE (NVL(ACNTLIEN_LIEN_DATE, ''31-DEC-1899'') NOT BETWEEN
                      ''01-JAN-1900'' AND ''31-DEC-2050'') OR
                      ACNTLIEN_LIEN_DATE > ''' || P_START_DATE || ''';');
  END IF;
  
  
---- checking if lien amount is null
  
  SELECT COUNT(*)
    INTO W_ROWCOUNT
    FROM MIG_ACNTLIEN
   WHERE ACNTLIEN_LIEN_AMOUNT IS NULL;
   
IF W_ROWCOUNT > 0 THEN
  INSERT INTO ERRORLOG
    (TEMPLATE_NAME, COLUMN_NAME, ROW_COUNT, SUGGESTION, QUERY)
  VALUES
    ('MIG_ACNTLIEN',
     'ACNTLIEN_LIEN_TO_BRN',
     W_ROWCOUNT,
     'LIEN AMOUNT CANNOT BE NULL',
     'SELECT * FROM MIG_ACNTLIEN  WHERE  ACNTLIEN_LIEN_AMOUNT IS NULL;'
     )
     ;
     
      END IF;

END SP_ACNTLIEN_VALIDATE;
/
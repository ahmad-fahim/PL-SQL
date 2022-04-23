CREATE OR REPLACE PROCEDURE SP_GEN_CL_DATA_THREAD(P_ASON_DATE DATE ) AS
  LN_DUMMY NUMBER;
BEGIN

DELETE FROM CL_TMP_DATA_INV WHERE ASON_DATE = P_ASON_DATE ;
DELETE FROM CL_TMP_DATA WHERE ASON_DATE= P_ASON_DATE ;
COMMIT ;

  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(1,100,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(101,200,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(201,300,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(301,400,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(401,500,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(501,600,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(601,700,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(701,800,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(801,900,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(901,1000,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(1001,1100,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(1101,1200,''' || P_ASON_DATE || ''' ); end;',instance=>1);
  DBMS_JOB.SUBMIT(LN_DUMMY, 'begin SP_GEN_CL_DATA(1201,1300,''' || P_ASON_DATE || ''' ); end;',instance=>1); 
  COMMIT;
END SP_GEN_CL_DATA_THREAD;
/

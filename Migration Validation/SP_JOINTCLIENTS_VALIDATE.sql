CREATE OR REPLACE PROCEDURE SP_JOINTCLIENTS_VALIDATE (
   P_BRANCH_CODE   IN NUMBER,
   P_START_DATE    IN DATE)
IS
   W_BRN_CODE   NUMBER (5) NOT NULL := P_BRANCH_CODE;
   -- W_MIG_DATE          DATE := P_START_DATE;
   W_ROWCOUNT   NUMBER := 0;
BEGIN
   DELETE FROM ERRORLOG
         WHERE TEMPLATE_NAME = 'MIG_JOINTCLIENTS';

   COMMIT;

   /* branch code checking */
   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_JOINTCLIENTS
    WHERE JNTCL_BRN_CODE <> W_BRN_CODE;


   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_JOINTCLIENTS',
                     'JNTCL_BRN_CODE',
                     W_ROWCOUNT,
                     'JNTCL_BRN_CODE SHOULD BE ' || W_BRN_CODE,
                        'SELECT JNTCL_JCL_SL, JNTCL_BRN_CODE FROM MIG_JOINTCLIENTS  WHERE JNTCL_BRN_CODE <>'
                     || W_BRN_CODE);
   END IF;

   ---Duplicate JNTCL_INDIV_CLIENT_CODE1 checking


   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM (WITH TABLE_DATA AS (SELECT * FROM MIG_JOINTCLIENTS),
                DATA
                AS (    SELECT LEVEL UQID
                          FROM DUAL
                    CONNECT BY LEVEL <= 6),
                T_DATA
                AS (  SELECT UQID,
                             JNTCL_JCL_SL,
                             JNTCL_INDIV_CLIENT_CODE1,
                             JNTCL_INDIV_CLIENT_CODE2,
                             NVL (JNTCL_INDIV_CLIENT_CODE3, -3)
                                JNTCL_INDIV_CLIENT_CODE3,
                             NVL (JNTCL_INDIV_CLIENT_CODE4, -4)
                                JNTCL_INDIV_CLIENT_CODE4,
                             NVL (JNTCL_INDIV_CLIENT_CODE5, -5)
                                JNTCL_INDIV_CLIENT_CODE5,
                             NVL (JNTCL_INDIV_CLIENT_CODE6, -6)
                                JNTCL_INDIV_CLIENT_CODE6
                        FROM TABLE_DATA, DATA
                    ORDER BY JNTCL_JCL_SL),
                FINAL_DATA
                AS (SELECT JNTCL_JCL_SL,
                           (SELECT (CASE
                                       WHEN F.UQID = 1
                                       THEN
                                          JNTCL_INDIV_CLIENT_CODE1
                                       WHEN F.UQID = 2
                                       THEN
                                          JNTCL_INDIV_CLIENT_CODE2
                                       WHEN F.UQID = 3
                                       THEN
                                          JNTCL_INDIV_CLIENT_CODE3
                                       WHEN F.UQID = 4
                                       THEN
                                          JNTCL_INDIV_CLIENT_CODE4
                                       WHEN F.UQID = 5
                                       THEN
                                          JNTCL_INDIV_CLIENT_CODE5
                                       WHEN F.UQID = 6
                                       THEN
                                          JNTCL_INDIV_CLIENT_CODE6
                                       ELSE
                                          NULL
                                    END)
                              FROM T_DATA F
                             WHERE     F.JNTCL_JCL_SL = T.JNTCL_JCL_SL
                                   AND F.UQID = T.UQID)
                              ROW_VALUE
                      FROM T_DATA T)
             SELECT JNTCL_JCL_SL, ROW_VALUE, COUNT (*)
               FROM FINAL_DATA
           GROUP BY JNTCL_JCL_SL, ROW_VALUE
             HAVING COUNT (*) > 1);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES (
                     'MIG_JOINTCLIENTS',
                     'JNTCL_JCL_SL',
                     W_ROWCOUNT,
                     'DUPLICATE RECORD PRESENT IN SAME ROW',
                     'WITH TABLE_DATA AS (SELECT * FROM MIG_JOINTCLIENTS),
    DATA
    AS (    SELECT LEVEL UQID
              FROM DUAL
        CONNECT BY LEVEL <= 6),
    T_DATA
    AS (  SELECT UQID,
                 JNTCL_JCL_SL,
                 JNTCL_INDIV_CLIENT_CODE1,
                 JNTCL_INDIV_CLIENT_CODE2,
                 NVL (JNTCL_INDIV_CLIENT_CODE3, -3) JNTCL_INDIV_CLIENT_CODE3,
                 NVL (JNTCL_INDIV_CLIENT_CODE4, -4) JNTCL_INDIV_CLIENT_CODE4,
                 NVL (JNTCL_INDIV_CLIENT_CODE5, -5) JNTCL_INDIV_CLIENT_CODE5,
                 NVL (JNTCL_INDIV_CLIENT_CODE6, -6) JNTCL_INDIV_CLIENT_CODE6
            FROM TABLE_DATA, DATA
        ORDER BY JNTCL_JCL_SL),
    FINAL_DATA
    AS (SELECT JNTCL_JCL_SL,
               (SELECT (CASE
                           WHEN F.UQID = 1 THEN JNTCL_INDIV_CLIENT_CODE1
                           WHEN F.UQID = 2 THEN JNTCL_INDIV_CLIENT_CODE2
                           WHEN F.UQID = 3 THEN JNTCL_INDIV_CLIENT_CODE3
                           WHEN F.UQID = 4 THEN JNTCL_INDIV_CLIENT_CODE4
                           WHEN F.UQID = 5 THEN JNTCL_INDIV_CLIENT_CODE5
                           WHEN F.UQID = 6 THEN JNTCL_INDIV_CLIENT_CODE6
                           ELSE NULL
                        END)
                  FROM T_DATA F
                 WHERE F.JNTCL_JCL_SL = T.JNTCL_JCL_SL AND F.UQID = T.UQID)
                  ROW_VALUE
          FROM T_DATA T)
 SELECT JNTCL_JCL_SL, ROW_VALUE, COUNT (*)
   FROM FINAL_DATA
GROUP BY JNTCL_JCL_SL, ROW_VALUE
 HAVING COUNT (*) > 1');
   END IF;



   SELECT COUNT (*)
     INTO W_ROWCOUNT
     FROM MIG_JOINTCLIENTS J
    WHERE    J.JNTCL_INDIV_CLIENT_CODE1 NOT IN (SELECT C.CLIENTS_CODE
                                                  FROM MIG_CLIENTS C)
          OR JNTCL_INDIV_CLIENT_CODE2 NOT IN (SELECT C.CLIENTS_CODE
                                                FROM MIG_CLIENTS C)
          OR JNTCL_INDIV_CLIENT_CODE3 NOT IN (SELECT C.CLIENTS_CODE
                                                FROM MIG_CLIENTS C)
          OR JNTCL_INDIV_CLIENT_CODE4 NOT IN (SELECT C.CLIENTS_CODE
                                                FROM MIG_CLIENTS C)
          OR JNTCL_INDIV_CLIENT_CODE5 NOT IN (SELECT C.CLIENTS_CODE
                                                FROM MIG_CLIENTS C)
          OR JNTCL_INDIV_CLIENT_CODE6 NOT IN (SELECT C.CLIENTS_CODE
                                                FROM MIG_CLIENTS C);

   IF W_ROWCOUNT > 0
   THEN
      INSERT INTO ERRORLOG (TEMPLATE_NAME,
                            COLUMN_NAME,
                            ROW_COUNT,
                            SUGGESTION,
                            QUERY)
           VALUES ('MIG_JOINTCLIENTS',
                   'JNTCL_INDIV_CLIENT_CODE',
                   W_ROWCOUNT,
                   'JOINT CLIENT CODE NOT IN MAIN CLIENTS',
                   'select *  
  from MIG_JOINTCLIENTS j
 where j.jntcl_indiv_client_code1 not in
       (select c.clients_code from mig_clients c)
      or 

     jntcl_indiv_client_code2 not in
       (select c.clients_code from mig_clients c) 
          or 

     jntcl_indiv_client_code3 not in
       (select c.clients_code from mig_clients c) 
          or 

     jntcl_indiv_client_code4 not in
       (select c.clients_code from mig_clients c) 
          or 

     jntcl_indiv_client_code5 not in
       (select c.clients_code from mig_clients c) 
          or 

     jntcl_indiv_client_code6 not in
       (select c.clients_code from mig_clients c)');
   END IF;
END SP_JOINTCLIENTS_VALIDATE;
/
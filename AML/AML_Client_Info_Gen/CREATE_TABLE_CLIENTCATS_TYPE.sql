/* Formatted on 3/6/2019 12:50:38 PM (QP5 v5.227.12220.39754) */
CREATE TABLE CLIENTCATS_TYPE
(
   CLIENTCATS_CATG_CODE   VARCHAR2 (6 BYTE) NOT NULL,
   CLIENTCATS_DESCN       VARCHAR2 (50 BYTE),
   CLIENTCATS_GOVT_FLAG   VARCHAR2 (1 BYTE)
);

INSERT INTO CLIENTCATS_TYPE 
SELECT CLIENTCATS_CATG_CODE, CLIENTCATS_DESCN, '0'  FROM CLIENTCATS
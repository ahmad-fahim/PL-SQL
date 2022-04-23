DROP TABLE ACNTTRANPROFAMT_CLONE ;

CREATE TABLE ACNTTRANPROFAMT_CLONE
(
  ACNTTRANPAMT_ENTITY_NUM         NUMBER(4)     NOT NULL,
  ACNTTRANPAMT_BRN_CODE           NUMBER(6)     NOT NULL,
  ACNTTRANPAMT_INTERNAL_ACNUM     NUMBER(14)    NOT NULL,
  ACNTTRANPAMT_MONTH              VARCHAR2(8 BYTE) NOT NULL,
  ACNTTRANPAMT_PROCESS_YEAR       NUMBER(4)          NOT NULL,
  ACNTTRANPAMT_TRANSFER_DB_AMT    NUMBER(18,3),
  ACNTTRANPAMT_TRANSFER_DB_COUNT  NUMBER(8),
  ACNTTRANPAMT_TRANSFER_CR_AMT    NUMBER(18,3),
  ACNTTRANPAMT_TRANSFER_CR_COUNT  NUMBER(8),
  ACNTTRANPAMT_CASH_DB_AMT        NUMBER(18,3),
  ACNTTRANPAMT_CASH_DB_COUNT      NUMBER(8),
  ACNTTRANPAMT_CASH_CR_AMT        NUMBER(18,3),
  ACNTTRANPAMT_CASH_CR_COUNT      NUMBER(8),
  ACNTTRANPAMT_CLEARING_DB_AMT    NUMBER(18,3),
  ACNTTRANPAMT_CLEARING_DB_COUNT  NUMBER(8),
  ACNTTRANPAMT_CLEARING_CR_AMT    NUMBER(18,3),
  ACNTTRANPAMT_CLEARING_CR_COUNT  NUMBER(8),
  ACNTTRANPAMT_TRADE_DB_AMT       NUMBER(18,3),
  ACNTTRANPAMT_TRADE_DB_COUNT     NUMBER(8),
  ACNTTRANPAMT_TRADE_CR_AMT       NUMBER(18,3),
  ACNTTRANPAMT_TRADE_CR_COUNT     NUMBER(8),
  ACNTTRANPAMT_ENTD_BY            VARCHAR2(8 BYTE),
  ACNTTRANPAMT_ENTD_ON            DATE,
  ACNTTRANPAMT_LAST_MOD_BY        VARCHAR2(8 BYTE),
  ACNTTRANPAMT_LAST_MOD_ON        DATE,
  ACNTTRANPAMT_AUTH_BY            VARCHAR2(8 BYTE),
  ACNTTRANPAMT_AUTH_ON            DATE,
  ACNTTRANPAMT_REJ_BY             VARCHAR2(8 BYTE),
  ACNTTRANPAMT_REJ_ON             DATE
)
TABLESPACE DATA
RESULT_CACHE (MODE DEFAULT)
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE UNIQUE INDEX PK_ACNTTRANPROFAMT_CLONE ON ACNTTRANPROFAMT_CLONE
(ACNTTRANPAMT_ENTITY_NUM, ACNTTRANPAMT_BRN_CODE, ACNTTRANPAMT_INTERNAL_ACNUM, ACNTTRANPAMT_MONTH, ACNTTRANPAMT_PROCESS_YEAR)
LOGGING
TABLESPACE CBSINDEX
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOPARALLEL;


ALTER TABLE ACNTTRANPROFAMT_CLONE ADD (
  CONSTRAINT PK_ACNTTRANPROFAMT_CLONE
  PRIMARY KEY
  (ACNTTRANPAMT_ENTITY_NUM, ACNTTRANPAMT_BRN_CODE, ACNTTRANPAMT_INTERNAL_ACNUM, ACNTTRANPAMT_MONTH, ACNTTRANPAMT_PROCESS_YEAR)
  USING INDEX PK_ACNTTRANPROFAMT_CLONE
  ENABLE VALIDATE);
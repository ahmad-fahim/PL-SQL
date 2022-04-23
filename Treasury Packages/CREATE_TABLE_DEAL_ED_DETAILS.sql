CREATE TABLE DEAL_ED_DETAILS
(
  ED_ENTITY_NUM             NUMBER,
  ED_DEAL_REF_NUM           VARCHAR2(35 BYTE),
  ED_PARENT_DEAL_REF_NUM    VARCHAR2(35 BYTE),
  ED_YEAR_END_ED_FLG        VARCHAR2(1 BYTE),
  ED_ADJUSTMENT_FLG         VARCHAR2(1 BYTE),
  ED_DEDUCTION_YEAR         NUMBER(4),
  ED_DEDUCTION_DATE         DATE,
  ED_DEDUCTION_AMOUNT       NUMBER(18,3),
  ED_POST_TRAN_DATE         DATE,
  ED_POST_TRAN_BRN          NUMBER(6),
  ED_POST_TRAN_BATCH        NUMBER(6),
  ED_DEDUCTION_ENTD_BY      VARCHAR2(8 BYTE),
  ED_DEDUCTION_ENTD_ON      DATE,
  ED_DEDUCTION_MODIFIED_BY  VARCHAR2(8 BYTE),
  ED_DEDUCTION_MODIFIED_ON  DATE,
  ED_DEDUCTION_AUTH_BY      VARCHAR2(8 BYTE),
  ED_DEDUCTION_AUTH_ON      DATE
)
TABLESPACE TBFES
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
CREATE TABLE BALTRFGLMAPPING
(
  FROM_GL          VARCHAR2(15 BYTE),
  TO_GL            VARCHAR2(15 BYTE),
  EDGL_FOR_DEBIT   VARCHAR2(15 BYTE),
  EDGL_FOR_CREDIT  VARCHAR2(15 BYTE),
  BORROW_NBFI      VARCHAR2(15 BYTE),
  BORROW_BANK      VARCHAR2(15 BYTE),
  LANDING_NBFI     VARCHAR2(15 BYTE),
  LANDING_BANK     VARCHAR2(15 BYTE)
) ;
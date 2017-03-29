CREATE OR REPLACE FUNCTION BANINST1.F_NEW_STATUS_CAE
(
  CODE IN VARCHAR2
, DESCRIPTION IN VARCHAR2
) RETURN VARCHAR2 AS

 consecutivo NUMBER;
 comodin VARCHAR2(4);
 codigo varchar2(4);

BEGIN

  comodin := CODE || '%';

  SELECT MAX(TO_NUMBER( SUBSTR(TWVCAES_CODE,2)))   INTO consecutivo
    FROM TAISMGR.TWVCAES
    WHERE TWVCAES_CODE LIKE comodin;

    consecutivo := consecutivo + 1;
    codigo := CODE || consecutivo;

    INSERT INTO TAISMGR.TWVCAES VALUES(codigo, DESCRIPTION, 'BANSECR', SYSDATE, null);

    COMMIT;

  RETURN codigo;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      consecutivo := 1;
      INSERT INTO TAISMGR.TWVCAES VALUES(CODE || consecutivo, DESCRIPTION, 'BANSECR', SYSDATE, null);

END F_NEW_STATUS_CAE;
/

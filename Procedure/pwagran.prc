DROP PROCEDURE BANINST1.PWAGRAN;

CREATE OR REPLACE PROCEDURE BANINST1.PWAGRAN(psObject VARCHAR2) AUTHID DEFINER IS
/*
         Tarea: Realiza la asignación del "GRANT EXECUTE" al usuario WEB_BAN_....
         Autor: MAC
         Fecha: 03/02/2010

  Modificacion: 03/12/2010
                GEPC
                * Se comprueba que el sinonimo publico exista no importa si esta valido o invalido.

*/

  vsPrilg VARCHAR2(20) := NULL;
  vsOwner VARCHAR2(32) := NULL;

  csVALID     CONSTANT VARCHAR2(5) := 'VALID';
  csPUBLIC    CONSTANT VARCHAR2(6) := 'PUBLIC';
  csINVALID   CONSTANT VARCHAR2(7) := 'INVALID';
  csSYNONYM   CONSTANT VARCHAR2(7) := 'SYNONYM';
  csEXECUTE   CONSTANT VARCHAR2(7) := 'EXECUTE';
  csBANINST1  CONSTANT VARCHAR2(8) := 'BANINST1';
  csWWW2_USER CONSTANT VARCHAR2(9) := 'WWW2_USER';
  cn1         CONSTANT NUMBER(1)   := 1;

  -- Asigna el permiso de ejecución para el usuario WEB
  -- grantExecute
  procedure grantExecute(psUser varchar2) is

  vnCursor integer := null;

  begin
      vnCursor := dbms_sql.open_cursor;

      dbms_sql.parse(vnCursor, 'GRANT EXECUTE ON BANINST1.'||psObject||' TO '||psUser, dbms_sql.v7);

      dbms_sql.close_cursor(vncursor);

  exception
      when others then
           dbms_sql.close_cursor(vnCursor);

           RAISE;

  end grantExecute;

  -- Crea el sinonimo publico para la aplicación WEB
  -- publicSynonym
  procedure publicSynonym is

  vnCursor integer := null;

  begin
      vnCursor := dbms_sql.open_cursor;

      dbms_sql.parse(vnCursor, 'CREATE PUBLIC SYNONYM '||psObject||' FOR BANINST1.'||psObject, dbms_sql.v7);

      dbms_sql.close_cursor(vncursor);

  exception
      when others then
           dbms_sql.close_cursor(vnCursor);

           RAISE;

  end publicSynonym;

  BEGIN
      --Revisa si el objeto ya puede ser ejecutado por los usuarios WEB_BAN
      BEGIN
          SELECT PRIVILEGE
            INTO vsPrilg
            FROM DBA_TAB_PRIVS
           WHERE TABLE_NAME = psObject
             AND PRIVILEGE  = csEXECUTE
             AND GRANTOR    = csBANINST1
             AND GRANTEE    = csWWW2_USER
          HAVING COUNT(cn1) = cn1
           GROUP BY PRIVILEGE;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               grantExecute('WWW2_USER');

      END;

      BEGIN
          SELECT OWNER
            INTO vsOwner
            FROM DBA_OBJECTS
           WHERE OWNER        = csPUBLIC
             AND OBJECT_TYPE  = csSYNONYM
             AND OBJECT_NAME  = psObject;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               publicSynonym;
      END;

  EXCEPTION
      WHEN OTHERS THEN
           RAISE;

  END PWAGRAN;
/


DROP PUBLIC SYNONYM PWAGRAN;

CREATE PUBLIC SYNONYM PWAGRAN FOR BANINST1.PWAGRAN;


GRANT EXECUTE ON BANINST1.PWAGRAN TO BANSECR;

GRANT EXECUTE ON BANINST1.PWAGRAN TO WWW_USER;

CREATE OR REPLACE procedure BANSECR.pwaalus(psUser   IN     VARCHAR2,
                                            psAccion IN     VARCHAR2,
                                            psAudit  IN     VARCHAR2,
                                            psError  IN OUT VARCHAR2,
                                            psPasswd IN     VARCHAR2 DEFAULT NULL                                            
                                           ) is

  /*
     TAREA: 1. Activa a un usuario                (U - ACCOUNT UNLOCK)
            2. Inavilita a un usuaro              (L - ACCOUNT LOCK)
            3. Expira la contraseña de un usuario (E - PASSWORD EXPIRE)
            4. Cambi la contraseña                (I - IDENTIFIED BY)
     FECHA: 04/04/2013
     AUTOR: GEPC
    MODULO: GENERAL
            Es usado por el procedimiento "PWAALTR"
  
  */


  vnCursor INTEGER      := NULL;
  vsAccion VARCHAR2(16) := NULL;
  
  csL              CONSTANT VARCHAR2(1)  := 'L';
  csU              CONSTANT VARCHAR2(1)  := 'U';
  csE              CONSTANT VARCHAR2(1)  := 'E';
  csI              CONSTANT VARCHAR2(1)  := 'I';
  csAlterUser      CONSTANT VARCHAR2(11) := 'ALTER USER ';
  csAccountLock    CONSTANT VARCHAR2(13) := ' ACCOUNT LOCK';
  csAccountUnlock  CONSTANT VARCHAR2(15) := ' ACCOUNT UNLOCK';
  csIdentifiedBy   CONSTANT VARCHAR2(15) := ' IDENTIFIED BY ';
  csPasswordExpire CONSTANT VARCHAR2(16) := ' PASSWORD EXPIRE';
  csUser           CONSTANT VARCHAR2(32) := psUser;
  csPassword       CONSTANT VARCHAR2(32) := psPasswd;
  
  BEGIN
      SELECT DECODE(psAccion,csL,csAccountLock,
                             csU,csAccountUnlock,
                             csE,csPasswordExpire,
                             csI,csIdentifiedBy,
                             NULL
                   )
        INTO vsAccion
        FROM DUAL;
  
      vnCursor := DBMS_SQL.OPEN_CURSOR;

      DBMS_SQL.PARSE(vnCursor, csAlterUser||csUser||vsAccion||csPassword, DBMS_SQL.V7);     

      DBMS_SQL.CLOSE_CURSOR(vncursor);
      
      psError := 'Operación existosa'; 
      
      BEGIN
          INSERT INTO GURSQLL 
          (GURSQLL_SEQ, 
           GURSQLL_ACTIVITY_DATE, 
           GURSQLL_CMD, 
           GURSQLL_USER_ID,
           GURSQLL_DATA_ORIGIN
          )
          VALUES 
          (GUBOSEQ.NEXTVAL, 
           SYSDATE, 
           csAlterUser||csUser||vsAccion||csPassword, 
           psAudit,
           'KWAREST'
          );
      EXCEPTION 
          WHEN OTHERS THEN
               psError := SQLERRM;
      END;

  EXCEPTION
      WHEN OTHERS THEN
           psError := SQLERRM; 
           
           DBMS_SQL.CLOSE_CURSOR(vnCursor);  

  END pwaalus;
/
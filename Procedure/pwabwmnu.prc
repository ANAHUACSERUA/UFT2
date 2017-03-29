DROP PROCEDURE BANINST1.PWABWMNU;

CREATE OR REPLACE PROCEDURE BANINST1.PWABWMNU(psName    VARCHAR2,
                                              psTitle   VARCHAR2 DEFAULT NULL,
                                              psBackURL VARCHAR2 DEFAULT NULL,
                                              psRoles   VARCHAR2 DEFAULT NULL
                                             ) IS

/*
          TAREA: Registrar las aplicaciones WEB en el SSB
          AUTOR: GEPC
          FECHA: 03/02/2010

   Modificacion: 11/02/2010
                 GEPC
                 * Se agrego la variable "vsProceso" por que no se obtenia correctamente el nombre
                   del proceso del parametro "psName" en el caso de que un objeto sea un "procedure"

   Modificacion: 15/02/2010
                 GEPC
                 * Se actualizo que la "validación de acceso" no este en comentarios.


*/

  TYPE reg_Colum IS RECORD(Text VARCHAR2(4000));

  TYPE tableRows IS TABLE OF reg_Colum INDEX BY BINARY_INTEGER;

  tabText    tableRows;
  vnRows     INTEGER        := 0;
  vnLine     INTEGER        := NULL;
  vsError    VARCHAR2(4000) := NULL;
  vsProceso  VARCHAR2(100)  := NULL;
  vsOwner    VARCHAR2(32)   := NULL;
  vsBKP      VARCHAR2(10)   := NULL;
  vsBackLink VARCHAR2(20)   := 'Regresar al Menú';
  vsBackInd  VARCHAR2(1)    := 'Y';
  vsRoles    VARCHAR2(500)  := psRoles;
  vsRol      VARCHAR2(30)   := NULL;

  cdSysdate CONSTANT DATE        := SYSDATE;
  csN       CONSTANT VARCHAR2(1) := 'N';
  csL       CONSTANT VARCHAR2(1) := 'L';
  csY       CONSTANT VARCHAR2(1) := 'Y';
  csS       CONSTANT VARCHAR2(1) := 'S';
  csOK      CONSTANT VARCHAR2(2) := 'OK';

  vbSinCmnr BOOLEAN        := TRUE;

  CURSOR cuComentario(vnLinea INTEGER) IS
         SELECT TEXT
            FROM DBA_SOURCE
           WHERE TYPE IN ('PROCEDURE','PACKAGE BODY')
             AND NAME  = vsProceso
             AND OWNER = 'BANINST1'
             AND LINE  < vnLinea;

  procedure RegistraEtapa(psAccion varchar2 default null) is

  begin

      update gwrasgr
         set gwrasgr_accion = psAccion,
             gwrasgr_error  = vsError
       where gwrasgr_new   = vsProceso
         and gwrasgr_old   = psName
         and gwrasgr_etapa = 'Registro en SSB';

      commit;

  end RegistraEtapa;

  BEGIN
      IF psBackURL IS NULL THEN
         vsBackLink := NULL;
         vsBackInd  := csN;
      END IF;

      SELECT UPPER(SUBSTR(psName,1,DECODE(INSTR(psName,'.')-1,-1,LENGTH(psName),INSTR(psName,'.')-1)))
        INTO vsProceso
        FROM DUAL;

      vsBKP := 'BK001';
      --Verifica que el proceso este valido
      BEGIN
          SELECT OWNER
            INTO vsOwner
            FROM DBA_OBJECTS
           WHERE OWNER        = 'BANINST1'
             AND OBJECT_TYPE IN ('PROCEDURE','PACKAGE BODY')
             AND STATUS       = 'VALID'
             AND OBJECT_NAME  = vsProceso;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               RAISE_APPLICATION_ERROR(-20091, 'OPERACIÓn INTERRUMPIDA: Tu aplicación causo un error en la compilación.');
               RETURN;
      END;

      vsBKP := 'BK002';
      --Verifica que el proceso se una aplicación WEB
      BEGIN
          SELECT LINE
            INTO vnLine
            FROM DBA_SOURCE
           WHERE (   REPLACE(UPPER(LTRIM(TEXT)),' ',NULL) LIKE 'IFPK_LOGIN.F_VALIDACIONDEACCESO(VGSUSR)THENRETURN;ENDIF;%'
                  OR REPLACE(UPPER(LTRIM(TEXT)),' ',NULL) LIKE 'IFPK_LOGIN.F_VALIDACIONDEACCESO(PK_LOGIN.VGSUSR)THENRETURN;ENDIF;%'
                  OR REPLACE(UPPER(LTRIM(TEXT)),' ',NULL) LIKE 'IFNOTTWBKWBIS.F_VALIDUSER(GLOBAL_PIDM)THENRETURN;ENDIF;%'
                 )
             AND TYPE IN ('PROCEDURE','PACKAGE BODY')
             AND NAME  = vsProceso
             AND OWNER = 'BANINST1';
      EXCEPTION
          WHEN TOO_MANY_ROWS THEN
               NULL;
          WHEN NO_DATA_FOUND THEN
               RAISE_APPLICATION_ERROR(-20091, 'OPERACIÓN INTERRUMPIDA: No estas validando el acceso del usuario.');
               RETURN;
      END;

      vsBKP := 'BK003';
      -- Se busca que la validación de acceso no este comentada
      FOR regCom IN cuComentario(vnLine) LOOP
          vnRows := vnRows + 1;

          tabText(vnRows).Text := regCom.Text;
      END LOOP;

      vsBKP := 'BK004';
      WHILE vbSinCmnr LOOP
            IF    vnRows = 0 THEN
                  vbSinCmnr := FALSE;
            ELSIF INSTR(tabText(vnRows).Text,'*/') > 0 THEN
                  vbSinCmnr := FALSE;
            ELSIF INSTR(tabText(vnRows).Text,'/*') > 0 THEN
                  vbSinCmnr := FALSE;

                  RAISE_APPLICATION_ERROR(-20091, 'OPERACIÓN INTERRUMPIDA: No estas validando el aecceso del usuario.');
                  RETURN;
            END IF;

            vnRows := vnRows - 1;
      END LOOP;

      vsBKP := 'BK005';
      --registro del nombre del procedimiento o paquete en el SSB
      BEGIN
          INSERT INTO GWRASGR(GWRASGR_NEW,
                              GWRASGR_OLD,
                              GWRASGR_ETAPA
                             )
                       VALUES(vsProceso,
                              psName,
                              'Registro en SSB'
                              );

          COMMIT;

          INSERT INTO TWGBWMNU
          (
           TWGBWMNU_NAME,           TWGBWMNU_DESC,               TWGBWMNU_BACK_MENU_IND,
           TWGBWMNU_MODULE,         TWGBWMNU_ENABLED_IND,        TWGBWMNU_INSECURE_ALLOWED_IND,
           TWGBWMNU_ACTIVITY_DATE,  TWGBWMNU_CACHE_OVERRIDE,     TWGBWMNU_SOURCE_IND,
           TWGBWMNU_ADM_ACCESS_IND, TWGBWMNU_PAGE_TITLE,         TWGBWMNU_HEADER,
           TWGBWMNU_BACK_URL,       TWGBWMNU_BACK_LINK,          TWGBWMNU_MAP_TITLE
          )
          VALUES
          (
           psName,                 NVL(psTitle,'Grupo integer'), vsBackInd,
           'AGS',                  csY,                          csN,
           cdSysdate,              csS,                          csL,
           csN,                    psTitle,                      psTitle,
           psBackURL,              vsBackLink,                   psTitle
          );

          vsBKP := 'BK006';
          RegistraEtapa(csOK);

      EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
               vsError := SQLERRM;

               RegistraEtapa;

          WHEN OTHERS THEN
               vsError := SQLERRM;

               RegistraEtapa;
      END;

      --Registro de roles asociados
      WHILE INSTR(vsRoles,',') >0 LOOP
            vsRol := SUBSTR(vsRoles,1, INSTR(vsRoles,',')-1);

            BEGIN
                INSERT INTO TWGRWMRL
                (TWGRWMRL_NAME,          TWGRWMRL_ROLE,
                 TWGRWMRL_ACTIVITY_DATE, TWGRWMRL_SOURCE_IND
                )
                VALUES
                (psName,                 vsRol,
                 cdSysdate,              csL
                );

                vsBKP := 'BK007';
                RegistraEtapa(csOK);
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                     vsError := SQLERRM;

                     RegistraEtapa;

                WHEN OTHERS THEN
                     vsError := SQLERRM;

                     RegistraEtapa;
            END;

            vsRoles := SUBSTR(vsRoles,INSTR(vsRoles,',')+1);
      END LOOP;

      vsBKP := 'BK008';
      --Realiza la asignación del "GRANT EXECUTE" al usuario WEB_BAN_....
      PWAGRAN(vsProceso);

  EXCEPTION
      WHEN OTHERS THEN
           RAISE_APPLICATION_ERROR(-20091, vsBKP||' - '||SQLERRM);
  END PWABWMNU;
/


DROP PUBLIC SYNONYM PWABWMNU;

CREATE PUBLIC SYNONYM PWABWMNU FOR BANINST1.PWABWMNU;


GRANT EXECUTE ON BANINST1.PWABWMNU TO BANSECR;

GRANT EXECUTE ON BANINST1.PWABWMNU TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWABWMNU TO WWW2_USER;

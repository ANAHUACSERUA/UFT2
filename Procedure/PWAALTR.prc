CREATE OR REPLACE PROCEDURE BANINST1.PWAALTR(psUser   IN     VARCHAR2,
                                             psAccion IN     VARCHAR2,
                                             psAudit  IN     VARCHAR2,
                                             psError  IN OUT VARCHAR2,
                                             psPasswd IN     VARCHAR2 DEFAULT NULL
                                            ) IS

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
  
  vsPassword VARCHAR2(32) := psPasswd;
  
  BEGIN
      IF psAccion IN ('U','L','E') THEN
         vsPassword := NULL;
      END IF;
      
      pwaalus(psUser, psAccion, psAudit, psError, vsPassword);
  END PWAALTR;
/

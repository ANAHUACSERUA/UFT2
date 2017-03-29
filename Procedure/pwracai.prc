DROP PROCEDURE BANINST1.PWRACAI;

CREATE OR REPLACE PROCEDURE BANINST1.PWRACAI(psReclDesc VARCHAR2) IS

/**************************************************************
           tarea:  genera el reporte de acta de alumnos de intercambios
         módulo:  consulta al registro de calificaciones
           autor:  horacio martínez ramírez - hmr
           fecha:  12/oct/2010
**************************************************************/
   vgsUSR        VARCHAR2(500);

 BEGIN

   /* check/update the user's web session */
   IF Pk_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

    BEGIN
         PWRCRCF(psReclDesc ,'PK_RegcaliCoCalF.P_IntercambioCalF');
    END PWRACAI;
 END;
/


DROP PUBLIC SYNONYM PWRACAI;

CREATE PUBLIC SYNONYM PWRACAI FOR BANINST1.PWRACAI;


GRANT EXECUTE ON BANINST1.PWRACAI TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWRACAI TO WWW2_USER;

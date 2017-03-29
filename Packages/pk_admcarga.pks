DROP PACKAGE BANINST1.PK_ADMCARGA;

CREATE OR REPLACE PACKAGE BANINST1.pk_AdmCarga IS
/******************************************************************************
PAQUETE:            BANINST1.pk_pk_AdmCarga
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la generaci�n de archivos CRM, para amd.
AUTOR:              Gilberto Velazquez Hernandez
FECHA:              20110704
******************************************************************************/

/******************************************************************************
PROCEDIMIENTO:      p_Main
OBJETIVO:           Pagina principal de la aplicaci�n
******************************************************************************/
PROCEDURE p_Main(
    psParametro         VARCHAR2 DEFAULT NULL);

/******************************************************************************
PROCEDIMIENTO:      p_JSONObtToken
OBJETIVO:           Devuelve un token para la autorizaci�n de la ejecuci�n
                    del jsp de carga de archivos
PARAMETROS:
psApp:              Nombre de la aplicaci�n a ejecutar
psUser:             Nombre del usuario que solicita autorizaci�n
******************************************************************************/
PROCEDURE p_JSONObtToken(
    psApp               VARCHAR2
    ,psUser             VARCHAR2
);


END pk_AdmCarga;
/


DROP PUBLIC SYNONYM PK_ADMCARGA;

CREATE PUBLIC SYNONYM PK_ADMCARGA FOR BANINST1.PK_ADMCARGA;


GRANT EXECUTE ON BANINST1.PK_ADMCARGA TO ADM_ADMISION;

GRANT EXECUTE ON BANINST1.PK_ADMCARGA TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ADMCARGA TO WWW2_USER;

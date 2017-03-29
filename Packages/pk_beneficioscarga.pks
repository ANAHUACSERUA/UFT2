DROP PACKAGE BANINST1.PK_BENEFICIOSCARGA;

CREATE OR REPLACE PACKAGE BANINST1.pk_BeneficiosCarga  IS
/******************************************************************************
PAQUETE:            BANINST1.pk_BeneficiosCarga
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la generación de archivos CRM, para amd.
AUTOR:              Gilberto Velazquez Hernandez
FECHA:              20110704
******************************************************************************/

/******************************************************************************
PROCEDIMIENTO:      p_Main
OBJETIVO:           Pagina principal de la aplicación
******************************************************************************/
PROCEDURE p_Main(
    psParametro         VARCHAR2 DEFAULT NULL);

/******************************************************************************
PROCEDIMIENTO:      p_JSONObtToken
OBJETIVO:           Devuelve un token para la autorización de la ejecución
                    del jsp de carga de archivos
PARAMETROS:
psApp:              Nombre de la aplicación a ejecutar
psUser:             Nombre del usuario que solicita autorización
******************************************************************************/
PROCEDURE p_JSONObtToken(
    psApp               VARCHAR2
    ,psUser             VARCHAR2
);


END pk_BeneficiosCarga ;
/


DROP PUBLIC SYNONYM PK_BENEFICIOSCARGA;

CREATE PUBLIC SYNONYM PK_BENEFICIOSCARGA FOR BANINST1.PK_BENEFICIOSCARGA;


GRANT EXECUTE ON BANINST1.PK_BENEFICIOSCARGA TO WWW2_USER;

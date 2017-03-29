DROP PACKAGE BANINST1.PK_ADMEJECUCION;

CREATE OR REPLACE PACKAGE BANINST1.pk_AdmEjecucion IS
/******************************************************************************
PAQUETE:            BANINST1.pk_AdmEjecucion
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de de archivos en la tabla SORTEST
AUTOR:              Pablo Serratos Vazquez
FECHA:              29112011
******************************************************************************/

/******************************************************************************
PROCEDIMIENTO:      p_Main
OBJETIVO:           Pagina principal de la aplicación y ejecucion de carga en SORTEST
******************************************************************************/
PROCEDURE p_Main(
    psParametro         VARCHAR2 DEFAULT NULL,
    psBandAlmacenados VARCHAR2 DEFAULT '0'
);

/******************************************************************************
PROCEDIMIENTO:      p_Inserta
OBJETIVO:           Reporte para los registros inertados en SORTEST
******************************************************************************/

--PROCEDURE p_Inserta;
PROCEDURE InsertaSortest(psRecarga IN VARCHAR2 DEFAULT '0', psEstatusJob IN VARCHAR2 DEFAULT '0' );

PROCEDURE InsertaEventos;
/******************************************************************************
PROCEDIMIENTO:      p_Detalle
OBJETIVO:           Reporte para los registros que seran inertados en SORTEST

******************************************************************************/
--PROCEDURE p_Detalle;

END pk_AdmEjecucion;
/


DROP PUBLIC SYNONYM PK_ADMEJECUCION;

CREATE PUBLIC SYNONYM PK_ADMEJECUCION FOR BANINST1.PK_ADMEJECUCION;


GRANT EXECUTE ON BANINST1.PK_ADMEJECUCION TO ADM_ADMISION;

GRANT EXECUTE ON BANINST1.PK_ADMEJECUCION TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ADMEJECUCION TO WWW2_USER;

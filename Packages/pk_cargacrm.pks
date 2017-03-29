DROP PACKAGE BANINST1.PK_CARGACRM;

CREATE OR REPLACE PACKAGE BANINST1.pk_CargaCRM IS
/******************************************************************************
PAQUETE:			BANINST1.pk_CargaCRM
OBJETIVO:			Contiene los procedimientos, funciones y variables
					requeridos para la carga de archivos de rendición PAT
AUTOR:				Marcela Altamirano Chan
FECHA:				20100922
******************************************************************************/
/******************************************************************************
PROCEDIMIENTO:		p_Carga
OBJETIVO:			Procesa un archivo de CRM
PARAMETROS:
psArchivo			Nombre con que fue guardado el archivo cargado
					por el usuario. Este nombre es proveido por la base de
					datos con el que el archivo puede ser extraido de la tabla
					indicada por la configuración del DAD.
******************************************************************************/
PROCEDURE p_Carga(
	psArchivo			VARCHAR2
	,psUser				VARCHAR2 DEFAULT USER
);

END pk_CargaCRM;
/


DROP PUBLIC SYNONYM PK_CARGACRM;

CREATE PUBLIC SYNONYM PK_CARGACRM FOR BANINST1.PK_CARGACRM;


GRANT EXECUTE ON BANINST1.PK_CARGACRM TO ADM_ADMISION;

GRANT EXECUTE ON BANINST1.PK_CARGACRM TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_CARGACRM TO WWW2_USER;

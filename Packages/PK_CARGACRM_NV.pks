CREATE OR REPLACE PACKAGE BANINST1.pk_CargaCRM_NV IS
/******************************************************************************
PAQUETE:			BANINST1.pk_CargaCRM_NV
OBJETIVO:			Contiene los procedimientos, funciones y variables
					requeridos para la carga de archivos de rendici�n PAT
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
					indicada por la configuraci�n del DAD.
******************************************************************************/
PROCEDURE p_Carga(
	psArchivo			VARCHAR2
	,psUser				VARCHAR2 DEFAULT USER
);

END pk_CargaCRM_NV;
/


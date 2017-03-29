CREATE OR REPLACE PACKAGE BANINST1.pk_CargaBCI_NV IS
/******************************************************************************
PAQUETE:			BANINST1.pk_CargaBCI_NV
OBJETIVO:			Contiene los procedimientos, funciones y variables
					requeridos para la carga de archivos de rendición del
					Banco de Chile
AUTOR:				Gilberto Velazquez Hernandez
FECHA:				20111222
******************************************************************************/

/******************************************************************************
PROCEDIMIENTO:		p_Carga
OBJETIVO:			Procesa un archivo de rendición del Banco de Chile para que
					los pagos indicados en el mismo sean transferidos al estado
					de cuenta de los alumnos
PARAMETROS:
psArchivo			Nombre con que fue guardado el archivo cargado
					por el usuario. Este nombre es proveido por la base de
					datos con el que el archivo puede ser extraido de la tabla
					indicada por la configuración de la aplicación web de
					carga
psUser				Usuario con el que fue cargado el archivo.
******************************************************************************/
PROCEDURE p_Carga(
	psArchivo			VARCHAR2
	,psUser				VARCHAR2 DEFAULT USER
);

END pk_CargaBCI_NV;
/


CREATE OR REPLACE PACKAGE BANINST1.pk_CargaCCP_Nv IS
/******************************************************************************
PAQUETE:            BANINST1.pk_CargaCCP
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos de colegios de procedencia
AUTOR:              Marcela Altamirano Chan
FECHA:              20100922
******************************************************************************/

    /******************************************************************************
    PROCEDIMIENTO:      p_Carga
    OBJETIVO:           Procesa un archivo de CCP
    PARAMETROS:
    psArchivo           Nombre con que fue guardado el archivo cargado
                        por el usuario. Este nombre es proveido por la base de
                        datos con el que el archivo puede ser extraido de la tabla
                        indicada por la configuración del DAD.
    ******************************************************************************/
    PROCEDURE p_Carga(
        psArchivo           VARCHAR2
       ,psUser             VARCHAR2 DEFAULT USER
    );

FUNCTION  isdate
          (p_inDate VARCHAR2)
RETURN DATE;

END pk_CargaCCP_Nv;
/


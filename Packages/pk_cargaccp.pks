DROP PACKAGE BANINST1.PK_CARGACCP;

CREATE OR REPLACE PACKAGE BANINST1.pk_CargaCCP IS
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

END pk_CargaCCP;
/


DROP PUBLIC SYNONYM PK_CARGACCP;

CREATE PUBLIC SYNONYM PK_CARGACCP FOR BANINST1.PK_CARGACCP;


GRANT EXECUTE ON BANINST1.PK_CARGACCP TO ADM_ADMISION;

GRANT EXECUTE ON BANINST1.PK_CARGACCP TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_CARGACCP TO WWW2_USER;

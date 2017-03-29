CREATE OR REPLACE PACKAGE BANINST1.pkCaeCargaFianzaOficialIngresa IS
/******************************************************************************
PAQUETE:            BANINST1.pk_CaeCargaFianzasOficialIngresa
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos de fianzas del sistema Ingresa
AUTOR:              Roman Ruiz
FECHA:              26 may 2014
******************************************************************************/

    /******************************************************************************
    PROCEDIMIENTO:      p_Carga
    OBJETIVO:           Procesa un archivo CAE
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



END pkCaeCargaFianzaOficialIngresa;
/
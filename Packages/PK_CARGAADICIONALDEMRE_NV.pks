CREATE OR REPLACE PACKAGE BANINST1.pk_CargaAdicionalDemre_NV IS
/******************************************************************************
PAQUETE:            BANINST1.pk_CargaAdicionalDemre_NV
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos de colegios de procedencia
AUTOR:              Marcela Altamirano Chan
FECHA:              20100922
++++++++++++++++++++++++++++++++
modificacion        md-01
descripcion         se toma como base el paquete pk_CargaPE  y se hace adecucion
                    para carga de archivo Demre
Autor               roman ruiz
fecha               05-sep-2014
******************************************************************************/

    /******************************************************************************
    PROCEDIMIENTO:      p_Carga
    OBJETIVO:           Procesa un archivo de CargaPE
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

--    FUNCTION  isdate
--              (p_inDate VARCHAR2)
--    RETURN DATE;



END pk_CargaAdicionalDemre_NV;
/


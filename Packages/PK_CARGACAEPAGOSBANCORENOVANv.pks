CREATE OR REPLACE PACKAGE BANINST1.pk_CargaCaePagosBancoRenovaNv IS
/******************************************************************************
PAQUETE:            BANINST1.pk_CargaCaePagosBancoRenova
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos de Pagos Bancos
AUTOR:              Roman Ruiz
FECHA:              22 oct 2014
******************************************************************************/

    /******************************************************************************
    PROCEDIMIENTO:      p_Carga
    OBJETIVO:           Procesa un archivo CAE de pago Bancos
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

END pk_CargaCaePagosBancoRenovaNv;
/


CREATE OR REPLACE PACKAGE BANINST1.pk_FotoBalanceFinal IS 
/******************************************************************************
PAQUETE:            BANINST1.pk_FotoBalanceFinal
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la generación de archivos pk_FotoBalanceFinal
AUTOR:              Roman Ruiz
FECHA:              27-oct-2014
******************************************************************************/



/******************************************************************************
PROCEDIMIENTO:  p_Genera
OBJETIVO:   Generar los registros contables para su posterior reporte.
PARAMETROS:
pnNumArch:   Parámetro de salida para indicar el número de archivo.
     Nulo si no hubo registro alguno a reportar.
pnNumRegs:   Número registros procesados / reportados. Nulo si no hubo
     registro alguno a procesar
pdFecha    Fecha de Corte (ultimo dia de operaciones)
psUser:    Usuario que invoco el proceso, si no se especifica se toma
     el ID de oracle de la conexión.
******************************************************************************/
PROCEDURE p_Genera(
 pnNumArch OUT  PLS_INTEGER
 ,pnNumRegs OUT  PLS_INTEGER
 ,pdFecha IN  DATE DEFAULT SYSDATE
 ,psUser  IN  VARCHAR2 DEFAULT USER
);

/******************************************************************************
PROCEDIMIENTO:  p_ObtArchivoNuevo
OBJETIVO:   Genera un archivo separado por comas (csv), que contiene el
     reporte de contabilidad para todas las transacciones no
     reportadas y lo envia al usuario
******************************************************************************/
PROCEDURE p_ObtArchivoNuevo(psFecha VARCHAR2);

/******************************************************************************
PROCEDIMIENTO:  p_ReimprimeArchivo
OBJETIVO:   Regenera un archivo csv con anterioridad. La salida
     HTTP, entregará un archivo csv con nombre identico al
     original
PARAMETROS:
psSecuencia:  Numero original del archivo.
******************************************************************************/
PROCEDURE p_ReimprimeArchivo(
 psNumArch   VARCHAR2
);

/******************************************************************************
PROCEDIMIENTO:  p_JSONListaArchivos
OBJETIVO:   Devuelve el listado de archivos generados con anterioridad
     filtrados en base a los parametros
     La lista es en formato JSON, Arreglo Bidimensional
     [ ["numLectura", "nombreArchivo"] ... ]
PARAMETROS:
psYear:    Año en que se generaron los archivos
psMonth:   Mes en que se generaron los archivos
******************************************************************************/
PROCEDURE p_JSONListaArchivos(
 psYear    VARCHAR2
 ,psMonth   VARCHAR2
);

/******************************************************************************
PROCEDIMIENTO:  p_Main
OBJETIVO:   Pagina principal de la aplicación
******************************************************************************/
PROCEDURE p_Main (psParametro IN VARCHAR2 DEFAULT NULL);


END pk_FotoBalanceFinal;
/

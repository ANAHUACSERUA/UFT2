DROP PACKAGE BANINST1.PK_ARCHEVNT;

CREATE OR REPLACE PACKAGE BANINST1.PK_ARCHEVNT AS

  /******************************************************************************
  PAQUETE:            BANINST1.PK_ARCHEVNT
  OBJETIVO:            Contiene los procedimientos, funciones y variables
                requeridos para la generación de archivos de Eventos
  AUTOR:                Alejandro Gómez Mondragón
  FECHA:                20131005
  ******************************************************************************/


  /* TODO enter package declarations (types, exceptions, methods etc) here */


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
  PROCEDURE p_ObtArchivoNuevo(psFecha varchar2);

  /******************************************************************************
  PROCEDIMIENTO:  p_ReimprimeArchivo
  OBJETIVO:       Regenera un archivo csv con anterioridad. La salida
                  HTTP, entregará un archivo csv con nombre identico al
                  original
  PARAMETROS:
  psSecuencia:    Numero original del archivo.
  ******************************************************************************/
  PROCEDURE p_ReimprimeArchivo(
   psNumArch   VARCHAR2
  );

  /******************************************************************************
  PROCEDIMIENTO:  p_JSONListaArchivos
  OBJETIVO:       Devuelve el listado de archivos generados con anterioridad
                  filtrados en base a los parametros
                  La lista es en formato JSON, Arreglo Bidimensional
                  [ ["numLectura", "nombreArchivo"] ... ]
  PARAMETROS:
  psYear:         Año en que se generaron los archivos
  psMonth:        Mes en que se generaron los archivos
  ******************************************************************************/
  PROCEDURE p_JSONListaArchivos(
   psYear    VARCHAR2
   ,psMonth   VARCHAR2
  );
  /******************************************************************************
  PROCEDIMIENTO:  p_Main
  OBJETIVO:       Pagina principal de la aplicación
  ******************************************************************************/
  PROCEDURE p_Main (psParametro IN VARCHAR2 DEFAULT NULL);


END PK_ARCHEVNT;
/


DROP SYNONYM BANSECR.PK_ARCHEVNT;

CREATE SYNONYM BANSECR.PK_ARCHEVNT FOR BANINST1.PK_ARCHEVNT;


DROP PUBLIC SYNONYM PK_ARCHEVNT;

CREATE PUBLIC SYNONYM PK_ARCHEVNT FOR BANINST1.PK_ARCHEVNT;


GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO CARGAPORTAL;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO WWW2_USER;

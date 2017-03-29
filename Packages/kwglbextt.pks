CREATE OR REPLACE PACKAGE BANINST1.KWGLBEXTT IS
/*
          Tarea: Registra una selecci�n de poblaci�n para ser usada en una ecuesta.
          Fecha: 11/02/2010
          Autor: GEPC
         Modulo: General

   Modificaci�n: Consultar el historico de modificaciones en el PACKAGEBODY
*/

  --codigo javascript
  PROCEDURE JS;

  -- Se capturan los parametros para la selecci�n de poblacion
  PROCEDURE CapturaAlumnos(psParametro VARCHAR2);

  -- Se registran la selecci�n de poblacion
  PROCEDURE RegistroAlumnos(psAppli        VARCHAR2 DEFAULT NULL,
                            psSelec        VARCHAR2 DEFAULT NULL,
                            psCreat        VARCHAR2 DEFAULT NULL,
                            psEncuesta     VARCHAR2 DEFAULT NULL,
                            psHold         VARCHAR2 DEFAULT NULL,
                            psNmRfE        VARCHAR2 DEFAULT NULL,
                            psBegDate      VARCHAR2 DEFAULT NULL,
                            psEndDate      VARCHAR2 DEFAULT NULL,
                            psAccion       VARCHAR2 DEFAULT NULL,
                            psListaAlumnos VARCHAR2 DEFAULT NULL
                           );

END KWGLBEXTT;
/


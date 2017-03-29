CREATE OR REPLACE PACKAGE BANINST1.KWAREST IS
  /*
              TAREA: Mostrar el nombre de una persona.
              FECHA: 06/06/2013

             MODULO: General.

     MODIFICACIONES: Consultar el historial de modificaciones en el PAKAGE BODY
       MODIFY V 1.0
       Glovicx@06.05.2014

  */

  PROCEDURE Inicio (psParametro VARCHAR2 DEFAULT NULL);

  PROCEDURE detalleUsuario(psUsuario VARCHAR2);

  procedure cambioStatus (psUser  VARCHAR2,
                         psAccion VARCHAR2,
                         psPasswd VARCHAR2
                         );


END KWAREST;
/


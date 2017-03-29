CREATE OR REPLACE PACKAGE BANINST1.kwasfar IS

/*
          TAREA: Capturar un expediente y quitar la marca de incripción de cursos
          FECHA: 13/01/2011
          AUTOR: GEPC
         MODULO: General

   MODIFICACION: Consultar el historico de modificación en el "PACKAGE BODY"

*/

  PROCEDURE JS;

  PROCEDURE obtieneNombre(psId VARCHAR2);

  PROCEDURE expediente(psParametro VARCHAR2);

  --quitarBloqueo
  PROCEDURE quitarBloqueo(psId   VARCHAR2,
                          psTerm VARCHAR2
                         );

END kwasfar;
/
CREATE OR REPLACE PACKAGE BANINST1.kwaacta IS
/*
   Tarea: Generaci�n de actas de calificaci�n
   Fecha: 01/12/2010
   Autor: GEPC


*/

  PROCEDURE js;

  --Genera el acta de calificaciones
  PROCEDURE actaDeCalificaciones;

  -- GENERA EL ACTA DE CALIFICACIONES
  PROCEDURE generaActa(psTerm VARCHAR2,
                                   psCrnn VARCHAR2
                      );

  ---  REIMPRESION DE ACTAS VIA BANNER
  PROCEDURE imprimeActa(psReclDesc VARCHAR2) ;

END kwaacta;
/
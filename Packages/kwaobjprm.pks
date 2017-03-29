CREATE OR REPLACE PACKAGE BANINST1.kwaObjPrm IS
/*
           tarea: sistema de reportes red de universidades anahuac (rua)
                  genera las opciones de parametros para los reportes
          modulo: general
           fecha: 25/01/2006.
           autor: gepc

    modificacion: para consultar el historico de cambios consulte el "package body"

*/

  --en el procedimiento se determina que proceso sera ejecutado.
  PROCEDURE Selcct(psParametro VARCHAR2,
                   pnTabIndex  INTEGER,
                   pnSiu       NUMBER   DEFAULT NULL,
                   pnDire      NUMBER   DEFAULT NULL,
                   pnSicc      NUMBER   DEFAULT NULL,
                   psReporte   VARCHAR2 DEFAULT NULL,
                   psCollCode  VARCHAR2 DEFAULT NULL,
                   psTipo      VARCHAR2 DEFAULT NULL,
                   psCondicio1 VARCHAR2 DEFAULT NULL,
                   psCondicio2 VARCHAR2 DEFAULT NULL,
                   psCondicio3 VARCHAR2 DEFAULT NULL,
                   psObjClean  VARCHAR2 DEFAULT NULL,
                   psOptionAll VARCHAR2 DEFAULT NULL,
                   psOptionDfl VARCHAR2 DEFAULT NULL
                  );

  --presenta la pagina html para asignar valores a otros objetos
  PROCEDURE returnValor(psReporte    VARCHAR2,
                        psParametro1 VARCHAR2,
                        psParametro2 VARCHAR2 DEFAULT NULL,
                        psFiltro1    VARCHAR2 DEFAULT NULL,
                        psFiltro2    VARCHAR2 DEFAULT NULL,
                        psFiltro3    VARCHAR2 DEFAULT NULL,
                        psFiltro4    VARCHAR2 DEFAULT NULL,
                        psFiltro5    VARCHAR2 DEFAULT NULL,
                        psFiltro6    VARCHAR2 DEFAULT NULL,
                        psFiltro7    VARCHAR2 DEFAULT NULL,
                        psFiltro8    VARCHAR2 DEFAULT NULL,
                        psFiltro9    VARCHAR2 DEFAULT NULL,
                        psFiltro10   VARCHAR2 DEFAULT NULL,
                        psFiltro11   VARCHAR2 DEFAULT NULL,
                        psForma      VARCHAR2 DEFAULT 'frmDatos',
                        psALL        VARCHAR2 DEFAULT NULL,
                        pnSiu        NUMBER   DEFAULT NULL,
                        pnDire       NUMBER   DEFAULT NULL,
                        pnSicc       NUMBER   DEFAULT NULL
                       );

  --en el procedimiento se determina que proceso sera ejecutado.
  PROCEDURE Text(psParametro VARCHAR2,
                 pnTabIndex  INTEGER,
                 psReporte   VARCHAR2,
                 psCondicion VARCHAR2
                );
   --en el procedimiento se determina que proceso sera ejecutado.
  PROCEDURE Hora(psParametro VARCHAR2,
                 pnTabIndex  INTEGER,
                 psReporte   VARCHAR2,
                 psCondicion VARCHAR2
                );


END kwaObjPrm;
/
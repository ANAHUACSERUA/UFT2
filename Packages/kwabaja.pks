CREATE OR REPLACE PACKAGE BANINST1.KWABAJA IS
/*
         AUTOR: GEPC
         FECHA: 28/05/2010
         TAREA: Reporte de Bajas
        MODULO: Historia academica

  MODIFICACI?N: Consulte el historico de modificaciones en el "PACKAGE BODY"

*/

  --realiza le registro de bajas academicas
  Procedure proceso(psTerm   VARCHAR2,
                    psMode   VARCHAR2,
                    pnPidm   NUMBER DEFAULT NULL,
                    psLevl   VARCHAR2,
                    psBaja   VARCHAR2,
                    psPBaja  VARCHAR2,
                    psTipo      VARCHAR2 DEFAULT NULL,
                    psCondicion VARCHAR2 DEFAULT NULL
                   );

  PROCEDURE reporte(psReclDesc VARCHAR2,
                    psTerm     VARCHAR2,
                    pnPidm     NUMBER DEFAULT NULL,
                    psBaja     VARCHAR2,
                    psPBaja    VARCHAR2
                   );


END KWABAJA;
/
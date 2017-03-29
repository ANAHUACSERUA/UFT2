CREATE OR REPLACE PACKAGE BANINST1.KWACIERRE
IS
   /*
            AUTOR: JCCR
            FECHA: 29/11/2010
            TAREA: Cierre de semestre  UFT
           MODULO: Historia academica

     MODIFICACI?N: Consulte el historico de modificaciones en el "PACKAGE BODY"

   */
   procedure splitChain ( lcadena in  varchar2);



   PROCEDURE Proceso (psTerm         VARCHAR2,
                      psMode         VARCHAR2,
                      pnPidm         NUMBER DEFAULT NULL,
                      psLevl         VARCHAR2,
                      psAtributo     VARCHAR2,
                      psTipo         VARCHAR2 DEFAULT NULL,
                      psCondicion    VARCHAR2 DEFAULT NULL,
                      psValIng       VARCHAR2);

   PROCEDURE P_DetToolTip (pnPidm NUMBER, psLevel VARCHAR, psTerm VARCHAR2);

 PROCEDURE P_DetToolTipA (pnPidm NUMBER, psTerm VARCHAR2);

   PROCEDURE reporte (psReclDesc    VARCHAR2,
                      psTerm        VARCHAR2,
                      pnPidm        NUMBER DEFAULT NULL,
                      psLevl        VARCHAR2,
                      psAtributo    VARCHAR2,
                      psValIng      VARCHAR2);

   PROCEDURE Menu_Reporte (psReclDesc    VARCHAR2
                           --psProgr        VARCHAR2,
                           --psPerio        VARCHAR2
                           --,
--                           psPerio        VARCHAR2,
--                           pnPidm        NUMBER DEFAULT NULL,
--                           psProgr        VARCHAR2,
--                           psAtributo    VARCHAR2,
--                           psValIng      VARCHAR2
                           );

   FUNCTION Mat_aprobadas (psTerm VARCHAR2 DEFAULT NULL, pnPidm NUMBER, psLevl VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION Mat_inscritas (psTerm VARCHAR2 DEFAULT NULL,    -- mac 15 jun 2011
                                                        pnPidm NUMBER)
      RETURN VARCHAR2;

   FUNCTION Mat_aprobadasGral (pnPidm NUMBER, psTerm VARCHAR, psLevl        VARCHAR2)
      RETURN VARCHAR2;
 FUNCTION Porcentaje_Mat_aprobadas(psTerm VARCHAR2 DEFAULT NULL,
                                                        pnPidm NUMBER, psLevl VARCHAR2)
      RETURN VARCHAR2;
      
  PROCEDURE pwranking   (psperiodo  varchar2, psnivel varchar2);    
      
END KWACIERRE;
/
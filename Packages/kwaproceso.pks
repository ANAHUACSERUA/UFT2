CREATE OR REPLACE PACKAGE BANINST1.KWAPROCESO IS

  --controlAvance
  procedure controlAvance(psAccion    varchar2,
                          pnSecuencia number,
                          psError     varchar2 default null
                         );

  PROCEDURE Inicio;

  PROCEDURE proceso(pnSecuencia NUMBER DEFAULT NULL);

  PROCEDURE ejecutaProceso(pnSecuencia NUMBER);

  --inserta
  PROCEDURE inserta(pnSecuencia NUMBER);

 procedure Bitacora(p_nombre_file varchar2 ) ;

END KWAPROCESO;
/


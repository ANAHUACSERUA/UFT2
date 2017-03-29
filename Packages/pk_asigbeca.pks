DROP PACKAGE BANINST1.PK_ASIGBECA;

CREATE OR REPLACE PACKAGE BANINST1.PK_ASIGBECA AS
/******************************************************************************
   NAME:       PK_ASIGBECA
   PURPOSE:    PAQUETE PARA LA UTILERIA DE ASIGNACION DE BECAS DE INSCRIPCIONES

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        03/11/2010             1. Created this package.
******************************************************************************/

-- DECLARACION DE TYPE
-- TYPE PARA LAS ASIGNACION DE BECAS
TYPE ty_becas IS RECORD (
    bterm         TWRBPSU.TWRBPSU_TERM_CODE%TYPE,
    bprog         TWRBPSU.TWRBPSU_PROGRAM%TYPE,
    beca          TWRBPSU.TWRBPSU_EXPT_CODE%TYPE,
    dbeca         TBBEXPT.TBBEXPT_DESC%TYPE
    ) ;

TYPE ty_asbe IS RECORD (
    bterm         TWRBPSU.TWRBPSU_TERM_CODE%TYPE,
    bprog         TWRBPSU.TWRBPSU_PROGRAM%TYPE,
    beca          TWRBPSU.TWRBPSU_EXPT_CODE%TYPE,
    dbeca         TBBEXPT.TBBEXPT_DESC%TYPE
    ) ;

TYPE ty_desic IS RECORD (
    pimd         SARADAP.SARADAP_PIDM%TYPE,
    temp         SARADAP.SARADAP_TERM_CODE_ENTRY%TYPE,
    appl         SARADAP.SARADAP_APPL_NO%TYPE,
    pref         SARADAP.SARADAP_APPL_PREFERENCE%TYPE,
    prog         SARADAP.SARADAP_PROGRAM_1%TYPE,
    apst         SARADAP.SARADAP_APST_CODE%TYPE,
    dapst        SARADAP.SARADAP_APST_DATE%TYPE,
    apdc         SARAPPD.SARAPPD_APDC_CODE%TYPE,
    tess         SWBPRCT.SWBPRCT_TESC_CODE_POND%TYPE,
    desi         NUMBER(2),
    tadm         SARADAP.SARADAP_ADMT_CODE%TYPE
    ) ;

-- GENERACION DE CURSORES PARA ASIGNACION DE BECAS
TYPE rc_becas IS REF CURSOR
    RETURN ty_becas;

TYPE rc_asbe IS REF CURSOR
    RETURN ty_asbe;

-- GENERACION DE CURSORES PARA SOLICITUDES ACEPTADAS O ADMITIDAS
TYPE rc_desic IS REF CURSOR
    RETURN ty_desic;

TYPE tty_desic
    IS TABLE OF ty_desic
    INDEX BY BINARY_INTEGER ;


  -- PROCESO DE CARGA DE INFORMACION DE LA PANTALLA DE SWADCRV DE ASIGNACION DE BECAS AUTOMATICAS
  PROCEDURE p_selbecaut(
      pTerm          IN     TWRBPSU.TWRBPSU_TERM_CODE%TYPE,
      pProg          IN     TWRBPSU.TWRBPSU_PROGRAM%TYPE,
      pSgbi          IN     TWRBCOL.TWRBCOL_SGBI_CODE%TYPE,
      pTest          IN     SORTEST.SORTEST_TEST_SCORE%TYPE,
      pPidm          IN     SPRIDEN.SPRIDEN_PIDM%TYPE,
      pBeca          IN OUT rc_becas
      );

  -- PROCESO DE CARGA DE INFORMACION DE SOLICITUD
  PROCEDURE p_seldesic(
      pPidm          IN     SARADAP.SARADAP_PIDM%TYPE,
      pTerm          IN     TWRBPSU.TWRBPSU_TERM_CODE%TYPE,
      pDesi          IN OUT rc_desic
      );

  -- PROCESO DE BLOQUEDAO PARA ACTUALIZA NO NOS SIRVE PERO DEBE TENERLO
  PROCEDURE p_lockdesic (
      pDesi          IN OUT tty_desic
      );

  -- PROCESO DE ACTUALIZACION EL QUE GENERA EL INSERT DE TOMA DE DISICION
  PROCEDURE p_upddesic(
      pDesi          IN OUT tty_desic
      );


  -- PROCESO DE CARGA DE INFORMACION DE LA PANTALLA DE SWADCRV DE ASIGNACION DE BECAS AUTOMATICAS
  PROCEDURE p_selasibec(
      pTerm          IN     TWRBPSU.TWRBPSU_TERM_CODE%TYPE,
      pProg          IN     TWRBPSU.TWRBPSU_PROGRAM%TYPE,
      pSgbi          IN     TWRBCOL.TWRBCOL_SGBI_CODE%TYPE,
      pTest          IN     SORTEST.SORTEST_TEST_SCORE%TYPE,
      pPidm          IN     TBBESTU.TBBESTU_PIDM%TYPE,
      pBeca          IN OUT rc_asbe
      );


END PK_ASIGBECA;
/


DROP PUBLIC SYNONYM PK_ASIGBECA;

CREATE PUBLIC SYNONYM PK_ASIGBECA FOR BANINST1.PK_ASIGBECA;


GRANT EXECUTE ON BANINST1.PK_ASIGBECA TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ASIGBECA TO WWW2_USER;

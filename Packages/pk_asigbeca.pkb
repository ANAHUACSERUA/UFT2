DROP PACKAGE BODY BANINST1.PK_ASIGBECA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PK_ASIGBECA  AS
/******************************************************************************
   NAME:       PK_ASIGBECA
   PURPOSE:    PAQUETE PARA LA UTILERIA DE ASIGNACION DE BECAS DE INSCRIPCIONES

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        03/11/2010             1. Created this package.
******************************************************************************/

  -- PROCESO DE CARGA DE INFORMACION DE LA PANTALLA DE SWADCRV DE ASIGNACION DE BECAS AUTOMATICAS
  PROCEDURE p_selbecaut(
      pTerm          IN     TWRBPSU.TWRBPSU_TERM_CODE%TYPE,
      pProg          IN     TWRBPSU.TWRBPSU_PROGRAM%TYPE,
      pSgbi          IN     TWRBCOL.TWRBCOL_SGBI_CODE%TYPE,
      pTest          IN     SORTEST.SORTEST_TEST_SCORE%TYPE,
      pPidm          IN     SPRIDEN.SPRIDEN_PIDM%TYPE,
      pBeca          IN OUT rc_becas
      )  IS
  BEGIN
    OPEN pBeca FOR
        SELECT TWRBPSU_TERM_CODE, TWRBPSU_PROGRAM, TWRBPSU_EXPT_CODE, TBBEXPT_DESC
          FROM TWRBPSU,
               TBBEXPT
         WHERE TBBEXPT_EXEMPTION_CODE = TWRBPSU_EXPT_CODE
           AND TBBEXPT_TERM_CODE = TWRBPSU_TERM_CODE
           AND TWRBPSU_TERM_CODE = pTerm
           AND TWRBPSU_PROGRAM = pProg
           AND TWRBPSU_MIN_SCORE <= replace(pTest,',','.')
           AND TWRBPSU_MAX_SCORE >=  replace(pTest,',','.')
        UNION ALL
        SELECT TWRBCOL_TERM_CODE, TWRBCOL_PROGRAM, TWRBCOL_EXPT_CODE, TBBEXPT_DESC
          FROM TWRBCOL,
               TBBEXPT
         WHERE TBBEXPT_EXEMPTION_CODE = TWRBCOL_EXPT_CODE
           AND TBBEXPT_TERM_CODE = TWRBCOL_TERM_CODE
           AND TWRBCOL_TERM_CODE = pTerm
           AND TWRBCOL_PROGRAM = pProg
           AND TWRBCOL_SGBI_CODE = pSgbi
        UNION ALL
          SELECT TWRBREG_TERM_CODE,  '',TWRBREG_EXPT_CODE, TBBEXPT_DESC
          FROM TWRBREG,
               TBBEXPT,
               SOBSBGI
         WHERE TBBEXPT_EXEMPTION_CODE = TWRBREG_EXPT_CODE
           AND TBBEXPT_TERM_CODE = TWRBREG_TERM_CODE
           AND SOBSBGI_STAT_CODE = TWRBREG_STAT_CODE
           AND TWRBREG_TERM_CODE = pTerm
           AND SOBSBGI_SBGI_CODE = pSgbi
         UNION ALL
             SELECT TWRBPOS_TERM_CODE, TWRBPOS_PROGRAM, TWRBPOS_EXPT_CODE, TBBEXPT_DESC
          FROM TWRBPOS,
               TBBEXPT,
               SARADAP
         WHERE TBBEXPT_EXEMPTION_CODE = TWRBPOS_EXPT_CODE
           AND TBBEXPT_TERM_CODE = TWRBPOS_TERM_CODE
           AND TWRBPOS_TERM_CODE = pTerm
           AND SARADAP_TERM_CODE_ENTRY = pTerm
           AND TWRBPOS_PROGRAM = pProg
           AND SARADAP_PROGRAM_1 = TWRBPOS_PROGRAM
           AND SARADAP_TERM_CODE_ENTRY = TWRBPOS_TERM_CODE
           AND  SARADAP_APPL_PREFERENCE BETWEEN TWRBPOS_MIN_SCORE AND TWRBPOS_MAX_SCORE
           AND TBBEXPT_TERM_CODE = TWRBPOS_TERM_CODE
           AND SARADAP_APPL_PREFERENCE IS NOT NULL
           AND SARADAP_PIDM = pPidm;

  END p_selbecaut;

  -- PROCESO DE CARGA DE INFORMACION DE SOLICITUD
  PROCEDURE p_seldesic(
      pPidm          IN     SARADAP.SARADAP_PIDM%TYPE,
      pTerm          IN     TWRBPSU.TWRBPSU_TERM_CODE%TYPE,
      pDesi          IN OUT rc_desic
      ) IS
  BEGIN
      OPEN pDesi FOR
        SELECT SARADAP_PIDM, SARADAP_TERM_CODE_ENTRY, SARADAP_APPL_NO, SARADAP_APPL_PREFERENCE,
           SARADAP_PROGRAM_1, SARADAP_APST_CODE, SARAPPD_APDC_DATE,
           SARAPPD_APDC_CODE, SWBPRCT_TESC_CODE_POND,
           NVL(
            (SELECT
            	1
            FROM
            	STVAPDC
            WHERE
            	STVAPDC_CODE = SARAPPD_APDC_CODE
            	AND STVAPDC_STDN_ACC_IND = 'Y'
            )
            ,0
            )
		   , SARADAP_ADMT_CODE
        FROM SARADAP,
           SARAPPD,
           SWBPRCT
        WHERE SARAPPD_PIDM = SARADAP_PIDM
        AND SARAPPD_TERM_CODE_ENTRY = SARADAP_TERM_CODE_ENTRY
        AND SARAPPD_APPL_NO = SARADAP_APPL_NO
        AND SWBPRCT_PROGRAM = SARADAP_PROGRAM_1
        AND SARADAP_PIDM =  pPidm
        AND SARADAP_TERM_CODE_ENTRY = pTerm
        AND SARAPPD_SEQ_NO = (
                SELECT MAX(A.SARAPPD_SEQ_NO)
                  FROM SARAPPD A
                 WHERE A.SARAPPD_PIDM = SARAPPD.SARAPPD_PIDM
                   AND A.SARAPPD_TERM_CODE_ENTRY = SARAPPD.SARAPPD_TERM_CODE_ENTRY
                   AND A.SARAPPD_APPL_NO = SARAPPD.SARAPPD_APPL_NO)
        UNION
        SELECT SARADAP_PIDM, SARADAP_TERM_CODE_ENTRY, SARADAP_APPL_NO, SARADAP_APPL_PREFERENCE,
           SARADAP_PROGRAM_1, SARADAP_APST_CODE, SARAPPD_APDC_DATE,
           SARAPPD_APDC_CODE, SWBPRCT_TESC_CODE_POND, 0, SARADAP_ADMT_CODE
        FROM SARADAP,
           SARAPPD,
           SWBPRCT
        WHERE SARAPPD_PIDM(+) = SARADAP_PIDM
        AND SARAPPD_TERM_CODE_ENTRY(+) = SARADAP_TERM_CODE_ENTRY
        AND SARAPPD_APPL_NO(+) = SARADAP_APPL_NO
        AND SWBPRCT_PROGRAM = SARADAP_PROGRAM_1
        AND SARADAP_PIDM = pPidm
        AND SARADAP_TERM_CODE_ENTRY = pTerm
        AND 0  = (
                SELECT COUNT(*)
                  FROM SARAPPD A
                 WHERE A.SARAPPD_PIDM = SARAPPD.SARAPPD_PIDM
                   AND A.SARAPPD_TERM_CODE_ENTRY = SARAPPD.SARAPPD_TERM_CODE_ENTRY
                   AND A.SARAPPD_APPL_NO = SARAPPD.SARAPPD_APPL_NO)
        ORDER BY SARADAP_APPL_NO;

  END p_seldesic;

  -- PROCESO DE BLOQUEDAO PARA ACTUALIZA NO NOS SIRVE PERO DEBE TENERLO
  PROCEDURE p_lockdesic (
      pDesi          IN OUT tty_desic
      ) IS
  BEGIN
      -- SOLO SE PONE PARA PODER REGRESAR UN CORRECTO EN LA PANTALLA
      NULL;
  END p_lockdesic;

  -- PROCESO DE ACTUALIZACION EL QUE GENERA EL INSERT DE TOMA DE DISICION
  PROCEDURE p_upddesic (
      pDesi          IN OUT tty_desic
      ) IS
      -- DECLARACION DE VARIABLE LOCALES
      lv_msg_type   VARCHAR2(2);
      lv_msg        VARCHAR2(2000);
      lv_batch_msg  VARCHAR2(50);
      lv_sec        NUMBER:=1;
  BEGIN
       FOR vlDes IN 1..pDesi.COUNT LOOP
           -- valor que genero el nuevo desicion
           IF (pDesi(vlDes).desi = 1) THEN
               BEGIN
               -- BUSCA EL NUMERO MAS GRANDE
               SELECT MAX(SARAPPD_SEQ_NO) + 1
                 INTO lv_sec
                 FROM SATURN.SARAPPD
                WHERE SARAPPD_PIDM = pDesi(vlDes).pimd
                  AND SARAPPD_TERM_CODE_ENTRY = pDesi(vlDes).TEMP
                  AND SARAPPD_APPL_NO = pDesi(vlDes).APPL;
               IF (lv_sec IS NULL OR lv_sec = 0) THEN
                   lv_sec := 1;
               END IF;
              EXCEPTION
                  WHEN OTHERS THEN
                      lv_sec := 1;
              END;
              -- VALIDA LA INFORMACION DE LA PANTALLA ANTES DE SALBAR LA INOFMACION
              -- INSERTA EN DECISION DE ACEPTACION DEL ALUMNO
              BEGIN

              INSERT INTO SATURN.SARAPPD
                  (SARAPPD_PIDM, SARAPPD_TERM_CODE_ENTRY, SARAPPD_APPL_NO, SARAPPD_SEQ_NO, SARAPPD_APDC_DATE, SARAPPD_APDC_CODE, SARAPPD_MAINT_IND, SARAPPD_ACTIVITY_DATE, SARAPPD_USER, SARAPPD_DATA_ORIGIN)
              VALUES
                  ( pDesi(vlDes).pimd, pDesi(vlDes).TEMP, pDesi(vlDes).APPL, lv_sec, SYSDATE, 'IN', 'U', SYSDATE, USER, 'SWADCRV');
              EXCEPTION
                  WHEN OTHERS THEN
                      RAISE;
              END;
              COMMIT;
          END IF;
       END LOOP;
  END p_upddesic;

  PROCEDURE p_selasibec(
      pTerm          IN     TWRBPSU.TWRBPSU_TERM_CODE%TYPE,
      pProg          IN     TWRBPSU.TWRBPSU_PROGRAM%TYPE,
      pSgbi          IN     TWRBCOL.TWRBCOL_SGBI_CODE%TYPE,
      pTest          IN     SORTEST.SORTEST_TEST_SCORE%TYPE,
      pPidm          IN     TBBESTU.TBBESTU_PIDM%TYPE,
      pBeca          IN OUT rc_asbe
      )  IS
  BEGIN
    OPEN pBeca FOR
        SELECT TWRBPSU_TERM_CODE, TWRBPSU_PROGRAM, TWRBPSU_EXPT_CODE, TBBEXPT_DESC
          FROM TWRBPSU,
               TBBEXPT
         WHERE TBBEXPT_EXEMPTION_CODE = TWRBPSU_EXPT_CODE
           AND TBBEXPT_TERM_CODE = TWRBPSU_TERM_CODE
           AND TWRBPSU_TERM_CODE = pTerm
           AND TWRBPSU_PROGRAM = pProg
           AND TWRBPSU_MIN_SCORE <= replace(pTest,',','.')
           AND TWRBPSU_MAX_SCORE >= replace(pTest,',','.')
           AND 0 = (
                    SELECT COUNT(*)
                      FROM TBBESTU
                     WHERE TBBESTU_EXEMPTION_CODE = TWRBPSU_EXPT_CODE
                       AND TBBESTU_PIDM = pPidm
                       and TBBESTU_TERM_CODE = pTerm)
        UNION ALL
        SELECT TWRBCOL_TERM_CODE, TWRBCOL_PROGRAM, TWRBCOL_EXPT_CODE, TBBEXPT_DESC
          FROM TWRBCOL,
               TBBEXPT
         WHERE TBBEXPT_EXEMPTION_CODE = TWRBCOL_EXPT_CODE
           AND TBBEXPT_TERM_CODE = TWRBCOL_TERM_CODE
           AND TWRBCOL_TERM_CODE = pTerm
           AND TWRBCOL_PROGRAM = pProg
           AND TWRBCOL_SGBI_CODE = pSgbi
           AND 0 = (
                    SELECT COUNT(*)
                      FROM TBBESTU
                     WHERE TBBESTU_EXEMPTION_CODE = TWRBCOL_EXPT_CODE
                       AND TBBESTU_PIDM = pPidm
                       and TBBESTU_TERM_CODE = pTerm)
        UNION ALL
        SELECT TWRBPRA_TERM_CODE, NULL, TWRBPRA_EXPT_CODE, TBBEXPT_DESC
          FROM TWRBPRA,
               TBBEXPT
         WHERE TBBEXPT_EXEMPTION_CODE = TWRBPRA_EXPT_CODE
           AND TBBEXPT_TERM_CODE = TWRBPRA_TERM_CODE
           AND TWRBPRA_PIDM = pPidm
           AND TWRBPRA_TERM_CODE = pTerm
           AND 0 = (
                    SELECT COUNT(*)
                      FROM TBBESTU
                     WHERE TBBESTU_EXEMPTION_CODE = TWRBPRA_EXPT_CODE
                       AND TBBESTU_PIDM = pPidm
                       and TBBESTU_TERM_CODE = pTerm);


  END p_selasibec;


END PK_ASIGBECA;
/


DROP PUBLIC SYNONYM PK_ASIGBECA;

CREATE PUBLIC SYNONYM PK_ASIGBECA FOR BANINST1.PK_ASIGBECA;


GRANT EXECUTE ON BANINST1.PK_ASIGBECA TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ASIGBECA TO WWW2_USER;

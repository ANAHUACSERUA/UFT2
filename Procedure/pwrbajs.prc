DROP PROCEDURE BANINST1.PWRBAJS;

CREATE OR REPLACE PROCEDURE BANINST1.PWRBAJS
IS
    -- DECLARACION DE VARIABLES LOCALES
    curr_release        CONSTANT VARCHAR2 (10)             := '8.1.1';
    global_pidm            spriden.spriden_pidm%TYPE;
    -- DECLARACION DE CURSORES LOCALES
    -- CURSOR QUE CARGA PERIODOS
    CURSOR cTerm IS
        SELECT DISTINCT SFRSTCR_TERM_CODE AS TERM, PK_CATALOGO.PERIODO(SFRSTCR_TERM_CODE) AS TDESC
        FROM SFRSTCR
        WHERE SFRSTCR_PIDM = global_pidm
        AND SFRSTCR_RSTS_CODE IN ('RE','RW')
        AND EXISTS (SELECT 1 FROM SFRRSTS
        			WHERE SFRRSTS_RSTS_CODE = 'RS'
                    AND SFRRSTS_TERM_CODE = SFRSTCR_TERM_CODE
                    AND TRUNC(SFRRSTS_END_DATE)>= TRUNC(SYSDATE));
    -- CURSOR QUE CARGA LOS PROGRAMAS DEL ESTUDIANTE



    -- CURSOR QUE CARGA LOS TIPOS DE CERTIFICADOS
BEGIN
    IF NOT twbkwbis.f_validuser (global_pidm) THEN  RETURN; END IF;
    -- INICIALIZA LA PAGUINA
    bwckfrmt.p_open_doc ('PWRBAJS');
    twbkwbis.p_dispinfo ('PWRBAJS');

     HTP.formopen ('PWRABAJ', 'post');
     twbkfrmt.p_tableopen (
        'DATAENTRY',
        cattributes   => 'SUMMARY="' ||
                            g$_nls.get ('BWSKOTR1-0001',
                               'SQL',
                               'This entry table is used to request
                               transcript type and level'
                            ) ||
                            '."'
     );
    -- INICIAL LA TABLA PARA PONER LOS PARAMETROS QUE SE VAN A SOLICITAR
    twbkfrmt.p_tablerowopen;
    --
    -- SOLICITA EL PARAMETRO DE PERIODO
    twbkfrmt.p_tabledataopen;
    htp.formSelectOpen('psPerio', 'Periodo:   ');
    FOR x IN cTerm LOOP
        twbkwbis.p_formselectoption(x.TDESC, x.TERM);
    END LOOP;
    htp.formSelectClose;
    twbkfrmt.p_tabledataclose;
    twbkfrmt.p_tablerowclose;
    --
     twbkfrmt.p_tablerowopen ();
     twbkfrmt.p_tabledataseparator (' ', ccolspan => 11);
     twbkfrmt.p_tablerowclose;
     twbkfrmt.p_tableclose;
     HTP.formsubmit (NULL, g$_nls.get ('BWSKOTR1-0007', 'SQL', 'Submit'));
     HTP.formclose;

  twbkwbis.p_closedoc (curr_release);
  COMMIT;
END PWRBAJS;
/


DROP PUBLIC SYNONYM PWRBAJS;

CREATE PUBLIC SYNONYM PWRBAJS FOR BANINST1.PWRBAJS;


GRANT EXECUTE ON BANINST1.PWRBAJS TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWRBAJS TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWRBAJS TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWRBAJS TO WWW2_USER;

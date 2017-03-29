CREATE OR REPLACE PROCEDURE BANINST1.PWRAEST( psTerm    IN  VARCHAR2,
                                                                             psNRC      IN  VARCHAR2)  IS
vsreprobada   number:=0;
vshistacadem  number:=0;
vscuenta         number:=0;
vscuentaRs       number := 0;
vnCuentaHold     number := 0;
vdinicio date;
vdfinal date;
vnCode  SCBCRSE.SCBCRSE_SUBJ_CODE%TYPE;
vnNumb SCBCRSE.SCBCRSE_CRSE_NUMB%TYPE;

global_pidm            spriden.spriden_pidm%TYPE;
curr_release        CONSTANT VARCHAR2 (10)             := '8.1.1';


 CURSOR materiaSeleccionada  (     psTerm        VARCHAR2  DEFAULT NULL,
                                                psPidm        VARCHAR2  DEFAULT NULL,
                                                psNRC        VARCHAR2  DEFAULT NULL) IS
                        SELECT  SCBCRSE_SUBJ_CODE,
                                    SCBCRSE_CRSE_NUMB
                            FROM SFRSTCR, SSBSECT, SCBCRSE A
                        WHERE SFRSTCR_CRN = SSBSECT_CRN
                            AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                            AND SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
                            AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
                            AND SFRSTCR_PIDM = psPidm
                            AND SFRSTCR_TERM_CODE = psTerm
                            AND SFRSTCR_CRN=psNRC
                            AND SFRSTCR_RSTS_CODE IN ('RE','RW')
                            AND A.SCBCRSE_EFF_TERM = (SELECT MAX(B.SCBCRSE_EFF_TERM) FROM SCBCRSE B
                                                                        WHERE A.SCBCRSE_SUBJ_CODE = B.SCBCRSE_SUBJ_CODE
                                                                            AND A.SCBCRSE_CRSE_NUMB = B.SCBCRSE_CRSE_NUMB);

BEGIN

    IF NOT twbkwbis.f_validuser (global_pidm) THEN  RETURN; END IF;

    bwckfrmt.p_open_doc ('PWRAEST');
    twbkwbis.p_dispinfo ('PWRAEST');

   OPEN materiaSeleccionada (psTerm,global_pidm,psNRC);
   FETCH materiaSeleccionada  INTO vnCode,vnNumb;
   CLOSE materiaSeleccionada ;

select TRUNC(SFRRSTS_START_DATE), TRUNC(SFRRSTS_END_DATE) INTO vdinicio, vdfinal FROM SFRRSTS
    where SFRRSTS_TERM_CODE = psTerm
    and SFRRSTS_RSTS_CODE = 'RS'
    and rownum = 1;


IF TRUNC(SYSDATE) BETWEEN vdinicio AND vdfinal then

SELECT COUNT(1) INTO vnCuentaHold FROM SPRHOLD, STVHLDD
WHERE SPRHOLD_HLDD_CODE = STVHLDD_CODE
AND STVHLDD_REG_HOLD_IND ='Y'
AND SPRHOLD_PIDM = global_pidm;

IF vnCuentaHold = 0 then
        select count(*) into vsreprobada
              FROM SHRTCKN N, SHRTCKG G, SGBSTDN S, SPRIDEN, SPBPERS
             WHERE S.SGBSTDN_PIDM = N.SHRTCKN_PIDM
               AND S.SGBSTDN_PIDM = SPRIDEN_PIDM
               AND n.shrtckn_pidm = global_pidm
               --and n.shrtckn_TERM_CODE = psTerm
               and shrtckn_SUBJ_CODE=vnCode
               and shrtckn_CRSE_NUMB=vnNumb
               AND S.SGBSTDN_TERM_CODE_EFF =
                                      (SELECT MAX (SS.SGBSTDN_TERM_CODE_EFF)
                                         FROM SGBSTDN SS
                                        WHERE SGBSTDN_PIDM = N.SHRTCKN_PIDM)
               AND G.SHRTCKG_PIDM = N.SHRTCKN_PIDM
               AND G.SHRTCKG_TERM_CODE = N.SHRTCKN_TERM_CODE
               AND G.SHRTCKG_TCKN_SEQ_NO = N.SHRTCKN_SEQ_NO
               AND G.SHRTCKG_SEQ_NO =
                      (SELECT MAX (G1.SHRTCKG_SEQ_NO)
                         FROM SHRTCKG G1
                        WHERE G1.SHRTCKG_PIDM = G.SHRTCKG_PIDM
                          AND G1.SHRTCKG_TERM_CODE = G.SHRTCKG_TERM_CODE
                          AND G1.SHRTCKG_TCKN_SEQ_NO = G.SHRTCKG_TCKN_SEQ_NO)
                          AND SPRIDEN_CHANGE_IND IS NULL
               AND G.SHRTCKG_GRDE_CODE_FINAL<'4,0';

        select count(*) into vshistacadem
          from   SHRTCKN
        WHERE  shrtckn_SUBJ_CODE        =vnCode
        and shrtckn_CRSE_NUMB             =vnNumb
        AND SHRTCKN_PIDM                 = global_pidm;

        select count(*) into vscuenta
          from   SFRSTCR
        WHERE  SFRSTCR_PIDM                 = global_pidm
        AND SFRSTCR_TERM_CODE       = psTerm;   
        
        select count(1) into vscuentaRs
          from   SFRSTCR
        WHERE  SFRSTCR_PIDM                 = global_pidm
        AND SFRSTCR_TERM_CODE       = psTerm
        and SFRSTCR_RSTS_CODE            = 'RS';   
        

        if vsreprobada=0 and vshistacadem=0 and vscuentaRs = 0 then
                UPDATE SFRSTCR
                SET SFRSTCR_RSTS_CODE            = 'RS'
                WHERE SFRSTCR_CRN                  = psNRC
                    AND SFRSTCR_PIDM                = global_pidm
                    AND SFRSTCR_TERM_CODE      = psTerm;
                htp.p('<script type="text/javascript"> alert("La materia ha sido dada de baja"); location.href="PWRBAJS";</script>');
                --HTP.P('La materia '||psNRC||' del periodo '||psTerm||' ha sido dada de baja');
               COMMIT;
        end if;
        if vsreprobada<>0 or vshistacadem<>0 then
          if vsreprobada<>0 then
                htp.p('<script type="text/javascript"> alert("Esta materia no se puede dar de baja: Ya ha sido reprobada"); location.href="PWRBAJS";</script>');
            else
                htp.p('<script type="text/javascript"> alert("Esta materia no se puede dar de baja: Tiene historia académica"); location.href="PWRBAJS";</script>');
          end if;
        end if;
else
  htp.p('<script type="text/javascript"> alert("No esta permitido por hold dar de baja"); location.href="PWRBAJS";</script>');
end if;
ELSE
  htp.p('<script type="text/javascript"> alert("No esta permitido por fecha dar de baja"); location.href="PWRBAJS";</script>');

end if;
        twbkwbis.p_closedoc (curr_release);

END PWRAEST;
/
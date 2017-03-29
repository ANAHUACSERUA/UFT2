DROP PROCEDURE BANINST1.PWRABAJ;

CREATE OR REPLACE PROCEDURE BANINST1.PWRABAJ(psPerio VARCHAR2)   IS

/*******************************************************************************
         tarea: procedimiento que genera el reporte de articulo 29
        módulo: admisiones - uft.

*******************************************************************************/

  -- declaración de variables:

  vsTerm        SARAPPD.SARAPPD_TERM_CODE_ENTRY%TYPE	DEFAULT NULL;
  vsExped       SPRIDEN.SPRIDEN_ID%TYPE		DEFAULT NULL;
  vsPidm         SPRIDEN.SPRIDEN_PIDM%TYPE        DEFAULT NULL;
  vsPerioAnt    STVTERM.STVTERM_CODE%TYPE;
  vsPcheckBox   VARCHAR2 (10)             := '';

    global_pidm         spriden.spriden_pidm%TYPE;
    curr_release        CONSTANT VARCHAR2 (10)             := '8.1.1';
    vsCheckBox          CONSTANT VARCHAR2 (10)             := 'disabled';
  -- obtiene la información de los alumnos:
  CURSOR cuReporte (	psTerm		VARCHAR2  DEFAULT NULL,
                                  psPidm		VARCHAR2  DEFAULT NULL ) IS
                SELECT  SFRSTCR_CRN NRC,
                            SCBCRSE_SUBJ_CODE||''||SCBCRSE_CRSE_NUMB CLAVE_MATERIA,
                            SCBCRSE_TITLE NOMBRE_MATERIA
                            FROM SFRSTCR, SSBSECT, SCBCRSE A
                        WHERE SFRSTCR_CRN = SSBSECT_CRN
                            AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                            AND SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
                            AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
                            AND SFRSTCR_PIDM = psPidm
                            AND SFRSTCR_TERM_CODE = psTerm
                            AND SFRSTCR_RSTS_CODE IN ('RE','RW') --CODIGO MATERIAS ACTIVAS
                            AND A.SCBCRSE_EFF_TERM = (SELECT MAX(B.SCBCRSE_EFF_TERM) FROM SCBCRSE B
                                                                        WHERE A.SCBCRSE_SUBJ_CODE = B.SCBCRSE_SUBJ_CODE
                                                                            AND A.SCBCRSE_CRSE_NUMB = B.SCBCRSE_CRSE_NUMB);

   CURSOR primerIngreso (     psTerm        VARCHAR2  DEFAULT NULL,
                                         psPidm        VARCHAR2  DEFAULT NULL ) IS
                            SELECT count(*) FROM SARADAP, TWBCNTR, SGBSTDN
                                WHERE SARADAP_PIDM = TWBCNTR_PIDM
                                    AND SARADAP_TERM_CODE_ENTRY = TWBCNTR_TERM_CODE
                                    AND SGBSTDN_PIDM = SARADAP_PIDM
                                    AND SARADAP_TERM_CODE_ENTRY = SGBSTDN_TERM_CODE_EFF
                                    AND SGBSTDN_STYP_CODE = 'N'
                                    AND SGBSTDN_STST_CODE  <> 'AL'
                                    AND SARADAP_TERM_CODE_ENTRY =psTerm
                                    AND SARADAP_PIDM = psPidm;

  CURSOR bajaMaterias (     psTerm       VARCHAR2  DEFAULT NULL,
                                      psPidm        VARCHAR2  DEFAULT NULL ) IS
                           select count(*) from SFRSTCR
                             WHERE SFRSTCR_RSTS_CODE       = 'RS'
                                 AND SFRSTCR_PIDM                = psPidm
                                 AND SFRSTCR_TERM_CODE      = psTerm;

    vnConteo      PLS_INTEGER;
    vnBajas        PLS_INTEGER;
    vnConteoActual PLS_INTEGER;

---------------------------------------------------
-- bloque principal para la generación del reporte
--------------------------------------------------

BEGIN

    IF NOT twbkwbis.f_validuser (global_pidm) THEN  RETURN; END IF;

    bwckfrmt.p_open_doc ('PWRABAJ');
    twbkwbis.p_dispinfo ('PWRABAJ');

htp.p('
        <form name="f" method="get">
            <table>');








   FOR regRep IN cuReporte (psPerio,global_pidm) LOOP

      BEGIN
      SELECT vsCheckbox
        INTO vsPcheckBox
        FROM SHRTCKN
       WHERE SHRTCKN_PIDM = global_pidm
         AND SHRTCKN_CRN = regRep.NRC
         AND SHRTCKN_TERM_CODE = psPerio;
        EXCEPTION WHEN NO_DATA_FOUND THEN vsPcheckBox := '';
        END;

       -- muestra los valores para cada registro:
       HTP.P('   <tr>
                    <td><input name="p1" type="checkbox" value="'||regRep.NRC||'" '||vsPcheckBox||' /></td>
                    <td>'||regRep.NRC||'</td>
                    <td>'||regRep.CLAVE_MATERIA||'</td>
                    <td>'||regRep.NOMBRE_MATERIA||'</td>
                    </tr>');

   END LOOP;

    --obtenemos el resultado del cursor de cuantas materias están dadas de baja

   OPEN bajaMaterias(psPerio,global_pidm);
   FETCH bajaMaterias INTO vnBajas;
   CLOSE bajaMaterias;


   --obtenemos el resultado del cursor de primer ingreso
   --periodo anterior
     SELECT max(STVTERM_CODE) INTO vsPerioAnt
       FROM STVTERM
       where STVTERM_CODE<psPerio
     ORDER BY STVTERM_CODE;

   OPEN primerIngreso(vsPerioAnt,global_pidm);
   FETCH primerIngreso INTO vnConteo;
   CLOSE primerIngreso;
   --periodo actual
   vsPerioAnt:=psPerio;
   OPEN primerIngreso(vsPerioAnt,global_pidm);
   FETCH primerIngreso INTO vnConteoActual;
   CLOSE primerIngreso;


    vnConteo:=vnConteo+vnConteoActual;


      HTP.P('</table>
                <input type="button" name="cmdEnvia" value="Enviar">
                </form>
                <form name=g method="post" action="PWRAEST">
                  <input type="hidden" name="psTerm" value="'||psPerio||'">
                  <input type="hidden" name="psNRC">
                </form>
                  <script type="text/javascript">
                        var f = document.f;
                        var g = document.g;

                        var conteo = '||vnConteo||';
                        var baja = '||vnBajas||';

                        f.cmdEnvia.onclick=Enviar;

                         function UnaSeleccion(){
                                    var seleccion=0;
                            for(var i=0; i<f.elements.length; i++){
                                   if( f.elements[i].type=="checkbox" && f.elements[i].checked ){
                                     seleccion = seleccion+1;
                                }

                            }
                                 if (seleccion>1) {
                                    alert("Revisar la seleccion de informacion:Solo se puede elegir una materia");
                                    return false;
                                 }
                                if (seleccion==0) {
                                    alert("Revisar la seleccion de informacion:Es necesario elegir una materia");
                                    return false;
                                 }

                                 return true;
                        }

                     function NCRSeleccionado(){
                                    var vseleccionado;
                            for(var i=0; i<f.elements.length; i++){
                                   if( f.elements[i].type=="checkbox" && f.elements[i].checked ){
                                      vseleccionado=f.elements[i].value;
                                }
                            }
                            return(vseleccionado);
                        }


                     function Enviar(){
                     //alert("aqui vamos");
                        //si no hubo un solo checkbox seleccionado nos salimos
                        if(! UnaSeleccion() ) return;

                        if(conteo>0){
                            alert("No es posible dar de baja materias para este alumno ya que es de primer ingreso");
                            return;
                        }
                        if(baja>=1){
                            alert("Ya existen materias dadas de baja para este período:No es posible cancelar esta materia");
                            return;
                        }

                        //guardamos el nrc seleccionado
                        g.psNRC.value = NCRSeleccionado();

                        //hago que la informacion se envie al servidor
                        g.submit();

                     }
                    </script>');
  twbkwbis.p_closedoc (curr_release);

EXCEPTION
   WHEN OTHERS THEN
        htp.p(SQLERRM);

END PWRABAJ;
/


DROP PUBLIC SYNONYM PWRABAJ;

CREATE PUBLIC SYNONYM PWRABAJ FOR BANINST1.PWRABAJ;


GRANT EXECUTE ON BANINST1.PWRABAJ TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWRABAJ TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWRABAJ TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWRABAJ TO WWW2_USER;

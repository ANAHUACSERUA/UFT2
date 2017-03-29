DROP PROCEDURE BANINST1.PWRAPIN;

CREATE OR REPLACE PROCEDURE BANINST1.PWRAPIN(psReclDesc VARCHAR2) IS
/*
          TAREA: Reporte de alumnos que han pagado inscripci?n
         MODULO: Registro Estudiantil
          AUTOR: GEPC
          FECHA: 03/08/2007

   MODIFICACION: 20/02/2008
                 MCC
                 * Se incluye la columna de majr en el reporte, adem?s
                   de excluir todos los alumnos que tengan nivel PL

                 * Se tiene que considerar que este reporte se toma como base comparativa
                   entre cifras con el reporte de avance de matricula del modulo de admisiones.

   MODIFICACION: 15/09/2009
                 CCR
                 * Se cambio el paquete pk_EstudiantePagoInscripcion y se
                   Creo el proceso PWRAPIN con la misma estructura.
                 * Se agrega el campo "Tipo de Alumno".

   MODIFICACION: 29/01/2010
                 GEPC
                 * Fue agregado el parametro SITE

   MODIFICACION: 10/06/2010
                 CCR
                 * Se le agrega un ' al id en el curso en caso de que el reporte
                   sea ejecutado por el parametro excel para evitar que quite los
                   ceros a la izquierda

*/


  vsInicoPag    VARCHAR2(10)           := NULL;
--  vsInicoPag    VARCHAR2(10)           := NULL;

  vnRow         INTEGER                            := 0;
  vnExists      INTEGER                            := 0;
  vnColumnas    INTEGER                            := 13;
  tabColumna    Pk_Sisrepimp.tipoTabla             := Pk_Sisrepimp.tipoTabla(1);
  vsPerio       SIBINST.SIBINST_TERM_CODE_EFF%TYPE := NULL;
  vsUniv        VARCHAR2(20)                       := NULL;
  vsSstst       STVSTST.STVSTST_CODE%TYPE          := NULL;
  vsProgr       SMRPRLE.SMRPRLE_PROGRAM_DESC%TYPE  := NULL;
  vsPrepa       STVSBGI.STVSBGI_DESC%TYPE          := NULL;
  vsSeccion     VARCHAR2(3)                        := NULL;
  vsPeriodo     VARCHAR2(20)                       := NULL;
  vsUnivers     VARCHAR2(20)                       := NULL;
  vsNivel       VARCHAR2(20)                       := NULL;
  vsRate        VARCHAR2(8)                        := NULL;
  vsEscu        VARCHAR2(20)                       := NULL;
  vsEnca        VARCHAR2(5)                        := NULL;
  vbEnca        BOOLEAN                            := TRUE;
  vsExcel       VARCHAR2(20)                       := NULL;
  --vsId          SPRIDEN.SPRIDEN_ID%TYPE            := NULL;


  CURSOR cuBecas (pnPidm NUMERIC,
                  psTerm VARCHAR2) IS
         SELECT TBBEXPT_DESC BecaDesc
           FROM TBBESTU,
                TBBEXPT
          WHERE TBBESTU_PIDM           = pnPidm
            AND TBBESTU_TERM_CODE      = psTerm
            AND TBBEXPT_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
            AND TBBEXPT_TERM_CODE      = TBBESTU_TERM_CODE
            AND TBBESTU_DEL_IND IS NULL;

  CURSOR cuReporte(psUniv  VARCHAR2 DEFAULT NULL,
                   psPerio VARCHAR2 DEFAULT NULL,
                   psProgr VARCHAR2 DEFAULT NULL,
                   psNivel VARCHAR2 DEFAULT NULL,
                   psEscu  VARCHAR2 DEFAULT NULL,
                   psRate  VARCHAR2 DEFAULT NULL
                  ) IS
         SELECT sgbstdn_camp_code                                                            cveuniversidad,
                psperio                                                                      periodo,
                sgbstdn_coll_code_1                                                          escuela,
                sgbstdn_majr_code_1                                                          cvemajr,
                pk_catalogo.carrera(sgbstdn_majr_code_1)                                     majr,
                sgbstdn_program_1                                                            cveprograma,
                pk_catalogo.programa(sg.sgbstdn_program_1)                                   descprograma,
                sg.sgbstdn_levl_code                                                         cvenivel,
                sgbstdn_pidm                                                                 pidm,
                decode(vsExcel,'EXCELL',''''||spriden_id,spriden_id)                         id,
                REPLACE(spriden_last_name||' '||spriden_first_name,'*',' ')                  alumno,
                pk_catalogo.stastst(sgbstdn_stst_code)                                       status,
               -- f_esinscrito(sgbstdn_pidm,psperio,sg.sgbstdn_levl_code,sgbstdn_camp_code)     inscrito,
                --f_esreinscrito(sgbstdn_pidm,psperio,sg.sgbstdn_levl_code,sgbstdn_camp_code)   reinscrito,
                (SELECT 'X'
                   FROM sfbetrm
                  WHERE sfbetrm_pidm      = sgbstdn_pidm
                    AND sfbetrm_term_code = psperio
                    AND sfbetrm_ests_code = 'EL'
                    AND EXISTS (SELECT NULL
                                  FROM sfrstcr
                                 WHERE sfrstcr_term_code  = psperio
                                   AND sfrstcr_pidm       = sfbetrm_pidm
                                   AND sfrstcr_rsts_code IN ('RE','RW')
                               )
                )                                                                            seleccion,
                (SELECT tbbcont_desc
                   FROM tbbcont
                  WHERE (tbbcont_contract_number,
                         tbbcont_term_code,
                         tbbcont_pidm) = (SELECT tbbcstu_contract_number,tbbcstu_term_code,tbbcstu_contract_pidm
                                            FROM tbbcstu a
                                           WHERE a.tbbcstu_stu_pidm          = sgbstdn_pidm
                                             AND a.tbbcstu_term_code         = psperio
                                             AND a.tbbcstu_contract_priority = (SELECT MAX (tbbcstu_contract_priority)
                                                                                  FROM tbbcstu b
                                                                                 WHERE b.tbbcstu_stu_pidm  = sgbstdn_pidm
                                                                                   AND b.tbbcstu_term_code = psperio
                                                                                )
                                         )
                )                                                                            CreditoAcademico,
                (SELECT DECODE(COUNT(1),0,NULL,'CA')
                   FROM sfrstcr
                  WHERE sfrstcr_term_code = psPerio
                    AND sfrstcr_ptrm_code = 'CA'
                    AND sfrstcr_pidm      = sgbstdn_pidm
                )                                                                            Observacion1,
                (SELECT DECODE(COUNT(1),0,NULL,'Inglés')
                   FROM sfrstcr,ssbsect
                  WHERE ssbsect_subj_code in ('ENG','INMA','CLIN')
                    AND sfrstcr_credit_hr  = 0
                    AND sfrstcr_term_code  = ssbsect_term_code
                    AND sfrstcr_crn        = ssbsect_crn
                    AND sfrstcr_term_code  = psperio
                    AND sfrstcr_pidm       = sgbstdn_pidm
                )                                                                            Observacion2,
                (SELECT stvstyp_desc
                   FROM stvstyp
                  WHERE stvstyp_code  = sg.sgbstdn_styp_code
                )                                                                            Tipo_alumno,
                SGBSTDN_RATE_code                                                            Site
           FROM sgbstdn sg,
                spriden
          WHERE sgbstdn_term_code_eff     = (SELECT MAX(sg2.sgbstdn_term_code_eff)
                                               FROM sgbstdn sg2
                                              WHERE sg2.sgbstdn_pidm           = sg.sgbstdn_pidm
                                                AND sg2.sgbstdn_term_code_eff <= psperio
                                            )
            AND sg.sgbstdn_stst_code    = 'AS'
            AND sg.sgbstdn_levl_code    NOT IN 'PL'
            AND sg.sgbstdn_pidm         = spriden_pidm
            AND spriden_change_ind      IS NULL
            AND (sg.sgbstdn_camp_code   = psuniv  OR psuniv   IS NULL)
            AND (sg.sgbstdn_program_1   = psprogr OR psprogr  IS NULL)
            AND (sg.sgbstdn_levl_code   = psnivel OR psnivel IS NULL)
            AND (sg.sgbstdn_coll_code_1 = psescu  OR psescu  IS NULL)
            AND (sg.SGBSTDN_RATE_code   = psRate  OR psRate  IS NULL)
          ORDER BY periodo DESC, cveuniversidad, cveprograma, majr,alumno;

  BEGIN
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      --son buscadas los valores de las cookies para asignar los valores del filtro del query.
      vsUniv    := pk_objHTML.getValueCookie('psUnive');
      vsPerio   := pk_objHTML.getValueCookie('psPerio');
      vsProgr   := pk_objHTML.getValueCookie('psProgr');
      vsNivel   := pk_objHTML.getValueCookie('psNivel');
      vsEscu    := pk_objHTML.getValueCookie('psEscu');
      vsEnca    := pk_objHTML.getValueCookie('psEnca');
      vsRate    := pk_objHTML.getValueCookie('psRate');
      vsSeccion := pk_objHTML.getValueCookie('cookSeccion');
      vsExcel   := pk_objHTML.getValueCookie('reporteEnExcel');--=EXCELL

      -- las instrucciones determinan el largo de la tabla
      FOR vnI IN 1..vnColumnas LOOP
          tabColumna.EXTEND(vnI);
          tabColumna(vnI) := NULL;
      END LOOP;

      tabColumna(1)  := 'Escuela';
      tabColumna(2)  := 'Carrera';
      tabColumna(3)  := 'Programa';
      tabColumna(4)  := 'Descripci&oacute;n';
      tabColumna(5)  := 'ID';
      tabColumna(6)  := 'Nombre';
      tabColumna(7)  := 'Pago inscripci&oacute;n';
      tabColumna(8)  := 'Pago reinscripci&oacute;n';
      tabColumna(9)  := 'Selecci&oacute;n de cursos';
      tabColumna(10) := 'Beca asignada';
      tabColumna(11) := 'Cr&eacute;dito educativo';
      tabColumna(12) := 'Observaciones';
      tabColumna(13) := 'Tipo de Alumno';


      FOR regRep IN cuReporte(vsUniv, vsPerio, vsProgr, vsNivel, vsEscu, vsRate) LOOP
          IF (vsPeriodo IS NULL OR vsPeriodo <> regRep.Periodo OR
              vsUnivers IS NULL OR vsUnivers <> regRep.CveUniversidad OR
              vnRow = 30) AND vbEnca THEN

              Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicoPag,'1',psSubtitulo=>'Periodo '||regRep.Periodo||'<br/>'||pk_Catalogo.fStvSite(regRep.SITE),psUsuario=>pk_login.vgsUSR,psSeccion=>vsSeccion,psUniversidad=>regRep.CveUniversidad);
                            vsInicoPag := 'SALTO';

              vnRow  := 0;
          END IF;

          IF vsEnca = 'N' THEN
             vbEnca := FALSE;
          END IF;

          vsUnivers := regRep.CveUniversidad;
          vsPeriodo := regRep.Periodo;




          --IF regRep.Inscrito   IS NULL AND
            -- regRep.ReInscrito IS NULL AND
             --regRep.Seleccion  IS NULL THEN
             --NULL;
          --ELSE
             --htp.p('<tr>--
             --<td valign="top" align="left">'  ||regRep.Escuela     ||'</td>
             --<td valign="top" align="left">'  ||regRep.CveMajr||'-'||regRep.Majr ||'</td>
             --<td valign="top" align="center">'||regRep.CvePrograma ||'</td>
             --<td valign="top" align="left">'  ||regRep.DescPrograma||'</td>
             --<td valign="top" align="left">'  ||regRep.ID          ||'</td>
             --<td valign="top" align="left">'  ||regRep.Alumno      ||'</td>
             --<td valign="top" align="center">'||regRep.Inscrito    ||'</td>
             --<td valign="top" align="center">'||regRep.ReInscrito  ||'</td>
             --<td valign="top" align="center">'||regRep.Seleccion   ||'</td>
             --<td valign="top">');

             FOR regBeca IN cuBecas(regRep.PIDM,regRep.PERIODO) LOOP
                 htp.p(regBeca.BecaDesc||'<br>');
             END LOOP;

             IF    regRep.Observacion1 IS NOT NULL AND regRep.Observacion2 IS NOT NULL THEN
                   regRep.Observacion1 := regRep.Observacion1||'/'||regRep.Observacion2;
             ELSIF regRep.Observacion1 IS NULL AND regRep.Observacion2 IS NOT NULL THEN
                   regRep.Observacion1 := regRep.Observacion2;
             END IF;

              htp.p('</td>
                     <td valign="top">'||regRep.CreditoAcademico||'</td>
                     <td valign="top">'||regRep.Observacion1    ||'</td>
                     <td valign="top">'||regRep.Tipo_alumno     ||'</td>
                     </tr>');

             vnExists := 1;
             vnRow    := vnRow + 1;
          --END IF;
      END LOOP;

      IF vnExists = 0 THEN
         htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
      ELSE
         -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de pagina para impresion
         Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

         -- es omitido el encabezado del reporte pero se agrega el salto de pagina
         Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR, psSeccion=>vsSeccion);
      END IF;

      htp.p('</table></body></html>');

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);


  END PWRAPIN;
/

DROP PROCEDURE BANINST1.PWRAIMR;

CREATE OR REPLACE PROCEDURE BANINST1.PWRAIMR(psReclDesc VARCHAR2) IS

/**************************************************************
           tarea:  procedimiento para el reporte de alumnos inscritos a materias aprobadas
         módulo:  selección de cursos
           autor:  horacio martínez ramírez - hmr
           fecha:  05/sep/2010
**************************************************************/

  vnRow      INTEGER                            := 0;
  vnExists   INTEGER                            := 0;
  vnColumnas INTEGER                            := 11;
  tabColumna Pk_Sisrepimp.tipoTabla             := Pk_Sisrepimp.tipoTabla(1);
  vsPerio    SIBINST.SIBINST_TERM_CODE_EFF%TYPE := NULL;
  vsUniv     STVCAMP.STVCAMP_CODE%TYPE          := NULL;
  vsFacu     STVSBGI.STVSBGI_DESC%TYPE          := NULL;
  vsProgr    SMRPRLE.SMRPRLE_PROGRAM_DESC%TYPE  := NULL;
  vsSeccion  VARCHAR2(3)                        := NULL;
  vsTermCode VARCHAR2(6)                        := NULL;
  vsCampCode VARCHAR2(6)                        := NULL;
  vsID       VARCHAR2(10)                       := NULL;
  vsID2      VARCHAR2(10)                       := NULL;
  vsStyle    VARCHAR2(50)                       := NULL;
  vsInicoPag VARCHAR2(10)                       := NULL;

  CURSOR cuReporte(psUniv  VARCHAR2 DEFAULT NULL,
                             psPerio VARCHAR2 DEFAULT NULL,
                             psFacu  VARCHAR2 DEFAULT NULL,
                             psProgr VARCHAR2 DEFAULT NULL) IS
         SELECT SGBSTDN_CAMP_CODE                                           campCode,
                SFRSTCR_TERM_CODE                                           termCode,
                SGBSTDN_COLL_CODE_1                                         collCode,
                Pk_Catalogo.COLEGIO(SGBSTDN_COLL_CODE_1)                    collDesc,
                SGBSTDN_PROGRAM_1                                           prgmCode,
                Pk_Catalogo.PROGRAMA(SGBSTDN_PROGRAM_1)                     prgmDesc,
                SGBSTDN_PIDM                                                PIDM,
                SPRIDEN_ID                                                  Id,
                SPBPERS_NAME_SUFFIX                                         Rut,
                REPLACE(SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME,'*',' ') Nombre,
                (SELECT SGBUSER_SUDA_CODE
                   FROM SGBUSER
                  WHERE SGBUSER_TERM_CODE = SFRSTCR_TERM_CODE
                    AND SGBUSER_PIDM      = SFRSTCR_PIDM
                )                                                           Semestre,
               FWATELE(SGBSTDN_PIDM)                                        Telefono,
               SSBSECT_SUBJ_CODE                                            Subj,
               SSBSECT_CRSE_NUMB                                            Crse
          FROM SFRSTCR,
               SGBSTDN A,
               SPRIDEN,
               SSBSECT,
               SPBPERS
         WHERE A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                            FROM SGBSTDN B
                                           WHERE B.SGBSTDN_PIDM            = A.SGBSTDN_PIDM
                                             AND B.SGBSTDN_TERM_CODE_EFF  <= SFRSTCR_TERM_CODE
                                         )
               AND A.SGBSTDN_PIDM          = SFRSTCR_PIDM
               AND SPRIDEN_CHANGE_IND     IS NULL
               AND A.SGBSTDN_PIDM          = SPRIDEN_PIDM
               AND A.SGBSTDN_STST_CODE     = 'AS'
               AND SSBSECT_TERM_CODE       = SFRSTCR_TERM_CODE
               AND SSBSECT_CRN             = SFRSTCR_CRN
               AND SGBSTDN_PIDM            = SPBPERS_PIDM
               AND SFRSTCR_RSTS_CODE      IN (SELECT STVRSTS_CODE FROM STVRSTS WHERE STVRSTS_INCL_SECT_ENRL = 'Y')
               AND EXISTS (SELECT NULL
                                    FROM SWVHIAC
                                  WHERE SWVHIAC_PIDM       = SFRSTCR_PIDM
                                      AND SWVHIAC_SUBJ       = SSBSECT_SUBJ_CODE
                                      AND SWVHIAC_CRSE       = SSBSECT_CRSE_NUMB
                                      AND SWVHIAC_PASSED_IND = 'Y'
                                      AND SWVHIAC_CALIF     <> 'RM'
                      )
               AND NOT EXISTS (SELECT NULL
                                           FROM SPRHOLD,STVHLDD
                                          WHERE SPRHOLD_pidm              = SFRSTCR_PIDM
                                              AND TRUNC(SPRHOLD_FROM_DATE) <= TRUNC(SYSDATE)
                                              AND TRUNC(SPRHOLD_TO_DATE)   >= TRUNC(SYSDATE)
                                              AND STVHLDD_CODE              = SPRHOLD_HLDD_CODE
                                              AND STVHLDD_REG_HOLD_IND      = 'Y'
                      )
               AND (SGBSTDN_CAMP_CODE   = psUniv  OR psUniv  IS NULL)
               AND (SFRSTCR_TERM_CODE   = psPerio OR psPerio IS NULL)
               AND (SGBSTDN_COLL_CODE_1 = psFacu  OR psFacu  IS NULL)
               AND (SGBSTDN_PROGRAM_1   = psProgr OR psProgr IS NULL)
            ORDER BY campCode, termCode DESC, prgmCode, Nombre;

  -- obtiene el correo electrónico del alumno
  CURSOR cuGoremal (pnPidm NUMBER) IS
         SELECT GOREMAL_EMAIL_ADDRESS
           FROM GOREMAL
          WHERE GOREMAL_PIDM           = pnPidm
              AND GOREMAL_EMAL_CODE      = 'PR'
              AND GOREMAL_STATUS_IND     = 'A'
              AND GOREMAL_EMAIL_ADDRESS IS NOT NULL;

  function detalle return varchar2 is

  BEGIN
      return '<tr bgcolor="#efefef"><td colspan="5"></td><th colspan="4">Materias aprobadas</th><td colspan="2"></td></tr>';

  END detalle;

  BEGIN
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      -- son buscadas los valores de las cookies para asignar los valores del filtro del query.
      vsPerio   := pk_ObjHtml.getValueCookie('psPerio');
      vsUniv    := pk_ObjHtml.getValueCookie('psUnive');
      vsFacu    := pk_ObjHtml.getValueCookie('psFacu');
      vsProgr   := pk_ObjHtml.getValueCookie('psProgr');
      vsSeccion := pk_ObjHtml.getValueCookie('cookSeccion');

      -- las instrucciones determinan el largo de la tabla
      FOR vnI IN 1..vnColumnas LOOP
            tabColumna.EXTEND(vnI);
            tabColumna(vnI) := NULL;
      END LOOP;

     tabColumna(1)  := 'Escuela';
     tabColumna(2)  := 'Programa';
     tabColumna(3)  := 'Descripci&oacute;n';
     tabColumna(4)  := 'Id';
     tabColumna(5)  := 'Rut';
     tabColumna(6)  := 'Alumno';
     tabColumna(7)  := 'Materia';
     tabColumna(8)  := 'Curso';
     tabColumna(9)  := 'Semestre';
     tabColumna(10) := 'Tel&eacute;fono';
     tabColumna(11) := 'Correo electr&oacute;nico';

     -- materias aprobadas
     FOR regRep IN cuReporte(vsUniv, vsPerio, vsFacu, vsProgr) LOOP
         IF vsTermCode IS NULL OR vsTermCode <> regRep.termCode OR
             vsCampCode IS NULL OR vsCampCode <> regRep.campCode OR vnRow = 18 THEN

             Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicoPag,'1',psSubtitulo=>'<br>Periodo '||regRep.termCode,psUsuario=>pk_login.vgsUSR,psSeccion=>vsSeccion,psUniversidad=>regRep.campCode, psDetalle=>detalle);

             vsInicoPag := 'SALTO';
             vnRow := 0;

         END IF;

         vsID2 := regRep.Id;

         IF vsID = regRep.Id THEN
             regRep.collDesc := NULL;
             regRep.prgmCode := NULL;
             regRep.prgmDesc := NULL;
             regRep.Id       := NULL;
             regRep.Nombre   := NULL;
             regRep.Semestre := NULL;
             regRep.Telefono := NULL;
             vsStyle := 'style="border-top:none;"';
         ELSE
             vsStyle := 'style="border-bottom:none;"';
         END IF;

         htp.p('<tr><td valign="top" '||vsStyle||'>'||regRep.collDesc||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.prgmCode||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.prgmDesc||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.Id||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.Rut||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.Nombre||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.Subj||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.Crse||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.Semestre||'</td>
                        <td valign="top" '||vsStyle||'>'||regRep.Telefono||'</td>
                        <td valign="top" '||vsStyle||'>' );

         regRep.Id := vsID2;

         IF vsID IS NULL OR vsID <> regRep.Id THEN
             FOR regGrm IN cuGoremal(regRep.PIDM)  LOOP
                   htp.p(regGrm.GOREMAL_EMAIL_ADDRESS||'<BR>');
             END LOOP;
         END IF;

         htp.p('</td></tr>');

         vnExists       := 1;
         vnRow         := vnRow + 1;
         vsTermCode  := regRep.termCode;
         vsCampCode := regRep.campCode;
         vsID            := regRep.Id;
     END LOOP;

     IF vnExists = 0 THEN
         htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
     ELSE
        -- la variable es una bandera que al tener el valor "imprime" no colocará el salto de página para impresión
        Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

        -- es omitido el encabezado del reporte pero se agrega el salto de página
        Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR, psSeccion=>vsSeccion);
     END IF;

     htp.p('</table><br><br></body></html>');

  EXCEPTION
       WHEN OTHERS THEN
                HTP.P(SQLERRM);

  END PWRAIMR;
/


DROP PUBLIC SYNONYM PWRAIMR;

CREATE PUBLIC SYNONYM PWRAIMR FOR BANINST1.PWRAIMR;


GRANT EXECUTE ON BANINST1.PWRAIMR TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWRAIMR TO WWW2_USER;

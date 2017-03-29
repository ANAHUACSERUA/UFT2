DROP PROCEDURE BANINST1.PWRACLI;

CREATE OR REPLACE PROCEDURE BANINST1.PWRACLI(psReclDesc VARCHAR2) IS

/**************************************************************
           tarea:  genera el reporte de actas liberadas
         módulo:  consulta al registro de calificaciones
           autor:  horacio martínez ramírez - hmr
           fecha:  12/oct/2010
**************************************************************/

  ckNombres    owa_cookie.vc_arr;
  ckValores    owa_cookie.vc_arr;
  ckCount      INTEGER;
  vgsInicoPag  VARCHAR2(10) := NULL; -- la variable es una bandera que al tener el valor "imprime" no colocará el salto de página para impresión
  vgsUSR       VARCHAR2(500);

  vnRow      INTEGER                            := 0;
  vnExists   INTEGER                            := 0;
  vnColumnas INTEGER                            := 9;
  tabColumna PK_sisRepImp.tipoTabla             := PK_sisRepImp.tipoTabla(1);
  vsPerio    SIBINST.SIBINST_TERM_CODE_EFF%TYPE := NULL;
  vsUniv     VARCHAR2(20)                       := NULL;
  vsSstst    STVSTST.STVSTST_CODE%TYPE          := NULL;
  vsProgr    SMRPRLE.SMRPRLE_PROGRAM_DESC%TYPE  := NULL;
  vsEscu     STVSBGI.STVSBGI_DESC%TYPE          := NULL;
  vsSeccion  VARCHAR2(3)                        := NULL;
  vsTermCode VARCHAR2(6)                        := NULL;
  vsCampCode VARCHAR2(6)                        := NULL;
  vsFechamax VARCHAR2(10)                       := NULL;

  CURSOR cuReporte(pPerio   VARCHAR2 DEFAULT NULL,
                   pUniv    VARCHAR2 DEFAULT NULL,
                   pEscu    VARCHAR2 DEFAULT NULL) IS
         SELECT SWRFOLI_TERM_CODE                termCode,
                SSBSECT_CAMP_CODE                campCode,
                SWRFOLI_CRN                      NRC,
                SCBCRSE_SUBJ_CODE                SUBJ,
                SCBCRSE_CRSE_NUMB                CRSE,
                SCBCRSE_TITLE                    TITULO,
                SPRIDEN_ID                       EXPEDIENTE,
                REPLACE(REPLACE(SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME||' '||SPRIDEN_MI,'ñ','&ntilde;'),'*',' ') NOMBRE,
                SWRFOLI_TEXT                     FOLIO,
                SWRFOLI_ROLPROF_DATE             LIBERACION
           FROM SWRFOLI,
                SSBSECT SS,
                SCBCRSE SC,
                SIRASGN,
                SPRIDEN,
                SSBOVRR SR
          WHERE SWRFOLI_TERM_CODE    = SSBSECT_TERM_CODE
            AND SWRFOLI_CRN          = SSBSECT_CRN
            AND SSBSECT_SUBJ_CODE    = SC.SCBCRSE_SUBJ_CODE
            AND SSBSECT_CRSE_NUMB    = SC.SCBCRSE_CRSE_NUMB
            AND SC.SCBCRSE_EFF_TERM  = (SELECT MAX(C2.SCBCRSE_EFF_TERM)
                                          FROM SCBCRSE C2
                                         WHERE SC.SCBCRSE_SUBJ_CODE = C2.SCBCRSE_SUBJ_CODE
                                           AND SC.SCBCRSE_CRSE_NUMB = C2.SCBCRSE_CRSE_NUMB
                                           AND C2.SCBCRSE_EFF_TERM <= SSBSECT_TERM_CODE
                                       )
           AND SWRFOLI_TERM_CODE    = SIRASGN_TERM_CODE
           AND SWRFOLI_CRN          = SIRASGN_CRN
           AND SS.SSBSECT_CRN       = SR.SSBOVRR_CRN (+)
           AND SS.SSBSECT_TERM_CODE = SR.SSBOVRR_TERM_CODE (+)
           AND SIRASGN_PRIMARY_IND  = 'Y'
           AND SPRIDEN_PIDM         = SIRASGN_PIDM
           AND SPRIDEN_CHANGE_IND   IS NULL
           AND (SWRFOLI_TERM_CODE   = pPerio OR pPerio IS NULL)
           AND (SSBSECT_CAMP_CODE   = pUniv  OR pUniv  IS NULL)
           AND (DECODE(SR.SSBOVRR_COLL_CODE ,NULL,SCBCRSE_COLL_CODE,SR.SSBOVRR_COLL_CODE ) = pEscu  OR pEscu  IS NULL)
         ORDER BY FOLIO;

  function fechaMaxima(pnCrn      number,
                                psTermCode varchar2) return varchar2 is

  vsFecha varchar2(11) := null;

  begin
      select to_char(max(sfrstcr_grde_date),'dd/mm/yyyy')
        into vsFecha
        from sfrstcr
       where sfrstcr_crn        = pnCrn
         and sfrstcr_term_code  = psTermCode
         and sfrstcr_grde_date is not null
         and sfrstcr_rsts_code in (select stvrsts_code
                                              from stvrsts
                                            where stvrsts_gradable_ind = 'Y');

     return vsFecha;

  exception
      when no_data_found then
           return null;

  end fechaMaxima;


  BEGIN
      /* check/update the user's web session */
      IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

      -- son buscadas los valores de las cookies para asignar los valores del filtro del query
      ckCount := 0;
      owa_cookie.get_all(ckNombres,ckValores,ckCount);

      IF ckCount != 0 THEN
          FOR vnCOKIES IN 1..ckCount LOOP
              IF ckNOMBRES(vnCOKIES)    = 'psPerio' THEN
                   vsPerio := ckValores(vnCOKIES);

              ELSIF ckNOMBRES(vnCOKIES) = 'psUnive' THEN
                   vsUniv  := ckValores(vnCOKIES);

              ELSIF ckNOMBRES(vnCOKIES) = 'psEscu' THEN
                   vsEscu := ckValores(vnCOKIES);

              ELSIF ckNOMBRES(vnCOKIES) = 'cookSeccion' THEN
                   vsSeccion := ckValores(vnCOKIES);

              END IF;
          END LOOP;
      END IF;

      -- las instrucciones determinan el largo de la tabla
      FOR vnI IN 1..vnColumnas LOOP
          tabColumna.EXTEND(vnI);
          tabColumna(vnI) := NULL;
      END LOOP;

      tabColumna(1) := 'No.';
      tabColumna(2) := 'NRC';
      tabColumna(3) := 'Subj';
      tabColumna(4) := 'Crse';
      tabColumna(5) := 'Título';
      tabColumna(6) := 'Expediente';
      tabColumna(7) := 'Nombre';
      tabColumna(8) := 'Folio';
      tabColumna(9) := 'Fecha de rolado';

      FOR regRep IN cuReporte(vsPerio, vsUniv, vsEscu) LOOP
          IF vsTermCode IS NULL OR vsTermCode <> regRep.termCode OR
             vsCampCode IS NULL OR vsCampCode <> regRep.campCode OR vnRow = 30 THEN

              PK_sisRepImp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vgsInicoPag,'0','#000000',psSubtitulo=>'Periodo '||regRep.termCode,psUsuario=>vgsUSR,psSeccion=>vsSeccion,psUniversidad=>regRep.campCode);
              vgsInicoPag := 'SALTO';

              vnRow  := 0;
          END IF;

          vnRow := vnRow + 1;

          htp.p('<tr>
          <td valign="top">'||vnRow            ||'</td>
          <td valign="top">'||regRep.NRC       ||'</td>
          <td valign="top">'||regRep.Subj      ||'</td>
          <td valign="top">'||regRep.Crse      ||'</td>
          <td valign="top">'||regRep.Titulo    ||'</td>
          <td valign="top">'||regRep.Expediente||'</td>
          <td valign="top">'||regRep.Nombre    ||'</td>
          <td valign="top">'||regRep.Folio     ||'</td>
          <td valign="top">'||fechaMaxima(regRep.NRC, regRep.termCode)||'</td>
          </tr>');

          vnExists   := 1;
          vsTermCode := regRep.termCode;
          vsCampCode := regRep.campCode;
      END LOOP;


      IF vnExists = 0 THEN
         htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||PK_sisRepImp.vgsResultado||'</font></th></tr>');
      ELSE
         -- la variable es una bandera que al tener el valor "imprime" no colocará el salto de página para impresión
         PK_sisRepImp.vgsSaltoImp := 'Imprime';

         -- es omitido el encabezado del reporte pero se agrega el salto de pagina
         PK_sisRepImp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>vgsUSR, psSeccion=>vsSeccion);
      END IF;

      htp.p('</table></body></html>');

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);

  END PWRACLI;
/


DROP PUBLIC SYNONYM PWRACLI;

CREATE PUBLIC SYNONYM PWRACLI FOR BANINST1.PWRACLI;


GRANT EXECUTE ON BANINST1.PWRACLI TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWRACLI TO WWW2_USER;

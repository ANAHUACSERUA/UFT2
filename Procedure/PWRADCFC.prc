CREATE OR REPLACE PROCEDURE BANINST1.PWRADCFC ( psReclDesc  VARCHAR2 ) IS
/*******************************************************************************
         tarea: procedimiento que genera el reporte de
                registro admisiones del cfc
        módulo:  admisiones cfc
         autor: Glovicx
         fecha: 26/05/2014

     se modifica con ajustes el dia 12-06-jun

     modify: 30.06.2014  se actualizan los filtro psprog x psProg1    y se añade el filtro psnivl1
     by glovicx:30-06-2014


*******************************************************************************/

  vnRow       INTEGER                := 0;
  vnExists    INTEGER                := 0;
  vnColumnas  INTEGER                := 11;
  tabColumna  Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla(1);
  vsPerio     VARCHAR2(16)            := NULL;
  vsYear      VARCHAR2(4)           := NULL;
  vsProgr     VARCHAR2(12)           := NULL;
  vsescu   VARCHAR2(30)            := NULL;
   vsSeccion   VARCHAR2(3)            := NULL;
   vsnivel     VARCHAR2(12)           := NULL;
  --vsTermCode  VARCHAR2(6)            := NULL;
  --vsCampCode  VARCHAR2(6)            := NULL;
  ---vsRateCode  VARCHAR2(10)           := NULL;
  --vsNrc       VARCHAR2(4000)         := NULL;
  ---vsID        VARCHAR2(20)           := NULL;
  ---vsMajr      VARCHAR2(30)           := NULL;
  ----vsPtrm      VARCHAR2(10)           := NULL;
--  vssede      varchar2(10)           := null;
  vsInicoPag  VARCHAR2(10)           := NULL;

  CURSOR cuReporte    IS
           SELECT DISTINCT SPRIDEN_ID                         ID_alumno,
SPRIDEN_LAST_NAME                                        APELLIDOS,
SPRIDEN_FIRST_NAME                                       NOMBRE,
SPBPERS_NAME_SUFFIX                                      RUT,
A.SGBSTDN_TERM_CODE_ADMIT                                PERIODO_ADMISION,
A.SGBSTDN_PROGRAM_1                                      PROGRAMA,
SARADAP_ADMT_CODE                                        TIPO_ADMISION,
TWBCNTR_NUM                                              CONTRATO,
TWBCNTR_TERM_CODE                                        PERIODO_CONTRATO,
 CN.TWBCNTR_ISSUE_DATE                                   fecha_contrato,
  CN.TWBCNTR_ISSUE_USER                                  usuario_contato
FROM SPRIDEN, SPBPERS, SGBSTDN A, SARADAP, (SELECT * FROM TWBCNTR
WHERE TWBCNTR_STATUS_IND = 'A'
AND (TWBCNTR_TERM_CODE = vsPerio OR vsPerio is null))  cn
WHERE SPRIDEN_PIDM = SPBPERS_PIDM
AND SPRIDEN_PIDM = SGBSTDN_PIDM
AND SPRIDEN_PIDM = SARADAP_PIDM
AND SPRIDEN_PIDM = TWBCNTR_PIDM(+)
--AND A.SGBSTDN_LEVL_CODE IN ('MG', 'DI', 'PT')  se cambia para usar nuevo filtro
AND (A.SGBSTDN_LEVL_CODE like (vsnivel|| '%') or vsnivel  is null)
--AND A.SGBSTDN_PIDM = 60084
and (A.SGBSTDN_TERM_CODE_ADMIT    like (vsYear||'%') or vsYear is null)
and  (A.SGBSTDN_TERM_CODE_ADMIT    = vsPerio or vsPerio is null)
and  (SARADAP_TERM_CODE_ENTRY  = vsPerio or vsPerio is null)
AND   (cn.twbcntr_ori_program      = vsProgr or vsProgr is null)
and  (SGBSTDN_COLL_CODE_1   = vsescu or vsescu is null)
and SARADAP_PROGRAM_1    = TWBCNTR_ORI_PROGRAM
 and a.sgbstdn_term_code_eff = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF) FROM SGBSTDN B
                                          WHERE A.SGBSTDN_PIDM = B.SGBSTDN_PIDM)
AND SPRIDEN_CHANGE_IND IS NULL
 ORDER BY  SPRIDEN_LAST_NAME ;



  BEGIN
      -- valida que el usuario pertenezca a la base de datos:
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      -- son buscados los valores de las cookies para asignar los valores del filtro del query:
      vsPerio   := substr( pk_ObjHtml.getValueCookie('psPerio') ,1,6) ;       ----periodo
      vsYear    := pk_ObjHtml.getValueCookie('psYear');        ---- año
      vsProgr   := pk_ObjHtml.getValueCookie('psProg1');       ---programa  SE ACTUALIZA EL NUEVO  FILTRO vic..
      vsescu     := pk_ObjHtml.getValueCookie('psEscu');      ---escuela
        vsSeccion := pk_ObjHtml.getValueCookie('cookSeccion');   ---secccion
        vsnivel := pk_ObjHtml.getValueCookie('psNivl1');  ----nivel   nuevo nivel

----htp.p(' periodo  '|| vsPerio ||'  año '||vsYear|| '  programa ' || vsProgr|| ' escuela ' || vsescu);
      -- se determina el largo de la tabla:
      FOR vnI IN 1..vnColumnas LOOP
          tabColumna.EXTEND(vnI);
          tabColumna(vnI) := NULL;
      END LOOP;

      tabColumna(1) := '<center> ID Alumno';
      tabColumna(2) := '<center> Apellidos ';
       tabColumna(3) := '<center> Nombre ';
      tabColumna(4) := '<center> RUT';
      tabColumna(5) := '<center> Periodo Admisión';
      tabColumna(6) := '<center> Programa';
      tabColumna(7) := '<center> Tipo Admisión';
      tabColumna(8) := '<center> Contrato';
      tabColumna(9) := '<center> Periodo de Contrato';
      tabColumna(10) := '<center> Fecha de Contrato';
      tabColumna(11) := '<center> Usuario ';
     ---tabcolumna(11):= '<center> Escuela';

--      for regrep in cureporte(vsperio, vsuniv, vsprogr, vsid, vsmajr,vsptrm,vssede) loop


             vnRow  := 0;

      FOR regRep IN cuReporte  LOOP

        if  vnrow = 0  then
          Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, vsInicoPag, '1', psSubtitulo=>'Año: '||vsYear ||' - Periodo '||Pk_Catalogo.PERIODO(vsPerio), psUsuario=>pk_login.vgsUSR, psSeccion=>vsSeccion);
             vsInicoPag := 'SALTO';
          end if;

         /*
          IF vsTermCode IS NULL OR vsTermCode <> regRep.termCode OR
                 vsCampCode IS NULL OR vsCampCode <> regRep.campCode  THEN
            -- vsratecode is null or vsratecode <> regrep.ratecode or vnrow = 10 then

            -- pk_sisrepimp.p_encabezadodereporte(psrecldesc, vncolumnas, tabcolumna, vsinicopag, '1', pssubtitulo=>'sede: '||nvl(pk_catalogo.fstvrate(regrep.ratecode),'sin sede')||'<br>periodo: '||regrep.termcode||' - '||pk_catalogo.periodo(regrep.termcode), psusuario=>pk_login.vgsusr, psseccion=>vsseccion, psuniversidad=>regrep.campcode);
                Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, vsInicoPag, '1', psSubtitulo=>'Periodo: '||regrep.termcode||' - '||Pk_Catalogo.PERIODO(regrep.termcode), psUsuario=>pk_login.vgsUSR, psSeccion=>vsSeccion, psUniversidad=>regRep.campCode);
             vsInicoPag := 'SALTO';
             vnRow  := 0;
          END IF;
          */
         ----    Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, vsInicoPag, '1', psSubtitulo=>'Periodo: '||regrep.termcode||' - '||Pk_Catalogo.PERIODO(regrep.termcode), psUsuario=>pk_login.vgsUSR, psSeccion=>vsSeccion, psUniversidad=>regRep.campCode);

          htp.p('<tr> <td valign="top">'||regRep.ID_alumno ||'</td>
                         <td valign="top">'||regRep.APELLIDOS ||'</td>
                     <td valign="top">'||regRep.nombre ||'</td>
                     <td valign="top">'||regRep.rut ||'</td>
                    <td valign="top">'||regRep.PERIODO_ADMISION ||'</td>
                     <td valign="top">'||regRep.PROGRAMA ||'</td>
                     <td valign="top">'||regRep.tipo_admision ||'</td>
                     <td valign="top">'||regRep.contrato ||'</td>
                      <td valign="top">'||regRep.PERIODO_CONTRATO ||'</td>
                    <td valign="top">'||regRep.fecha_contrato ||'</td>
                        <td valign="top">'||regRep.usuario_contato ||'</td>
                     ');

          vnExists   := 1;
          vnRow      := vnRow + 1;

      END LOOP;

      IF vnExists = 0 THEN
         htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
      ELSE
         -- la variable es una bandera que al tener el valor "imprime" no colocará el salto de página para impresión:
         Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

         -- es omitido el encabezado del reporte pero se agrega el salto de página:
         Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, 'PIE', '0', psUsuario=>pk_login.vgsUSR, psSeccion=>vsSeccion);
      END IF;

      htp.p('</table><br><br>No Registros ' || vnrow ||'</body></html>');

  EXCEPTION
     WHEN OTHERS THEN
          HTP.P(SQLERRM);

  END PWRADCFC;
/
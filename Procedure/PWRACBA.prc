CREATE OR REPLACE PROCEDURE BANINST1.pwracba(psReclDesc VARCHAR2) IS
/*
         Tarea: Generar ACTA de calificaciones para Bachillerato.
         Fecha: 22/12/2015.
         Autor: JCMB

  MODIFICACION: 15/02/2016
                GEPC

Modificacion inc 7536
Autor:VDJ
Fecha: 26/oct/2016 
Descripción: Se ajusta el paquete para que no permita mostrar calificaciones vacias


*/
  TYPE regALUM IS RECORD (rPidm    NUMBER(9),
                          rNombre  VARCHAR2(300),
                          rCalif   VARCHAR2(6),
                          rLevl    VARCHAR2(6),
                          rAutoGrd VARCHAR2(6)
                         );

  TYPE tableAlum IS TABLE OF regAlum INDEX BY BINARY_INTEGER;

  global_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;

  vsEstilo    VARCHAR(100) := 'style="border-bottom:none;border-top:none;border-left:none;border-right:none"';
  vnHoja      INTEGER      := 1;
  vnRegsxHoja INTEGER      := 30;
  vnRows      INTEGER      := 0;
  vnRenglon   INTEGER      := 0;
  vnTotHojas  INTEGER      := 0;
  tabAlum     tableAlum;

  cn1         CONSTANT NUMBER(1)   := 1;
  csY         CONSTANT VARCHAR2(1) := 'Y';
  csN         CONSTANT VARCHAR2(1) := 'N';
  csRE        CONSTANT VARCHAR2(2) := 'RE';
  csRW        CONSTANT VARCHAR2(2) := 'RW';
  csZZ        CONSTANT VARCHAR2(2) := 'ZZ';
  csAS        CONSTANT VARCHAR2(2) := 'AS';
  csCamp      CONSTANT VARCHAR2(6) := F_CONTEXTO(); --modificación realizada por GEPC para resolver los problemas de la UAS
  csOrdinario CONSTANT VARCHAR2(9) := 'Ordinario';
  csBA        CONSTANT VARCHAR2(2) := 'BA';
  csML        CONSTANT VARCHAR2(2) := 'ML';


  vdFecRola  DATE        := NULL;
  vsTerm     VARCHAR2(6) := NULL;
  vsCol      VARCHAR2(6) := NULL;
  vsCrnI     VARCHAR2(6) := NULL;
  vsCrnF     VARCHAR2(6) := NULL;
  vsNivel     VARCHAR2(6) := NULL;

  vsActaRoll VARCHAR2(1) := NULL;
  viRows     INTEGER     := 0;
  --cuCRN
  
  viFlag INTEGER := 0;
  
  CURSOR cuCRN(psTerm VARCHAR2,
               psEscu VARCHAR2,
               psCRNI VARCHAR2,
               psCRNF VARCHAR2,
               psNivel VARCHAR2
              ) is
         SELECT SSBSECT_CRN       AS CRN,
                SCBCRSE_COLL_CODE AS COL
           FROM SCBCRSE A,
                SSBSECT SS,
                SIRASGN
          WHERE A.SCBCRSE_SUBJ_CODE  = SS.SSBSECT_SUBJ_CODE
            AND A.SCBCRSE_CRSE_NUMB  = SS.SSBSECT_CRSE_NUMB
            AND A.SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                          FROM SCBCRSE SC
                                         WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                           AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                           AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                       )
            AND SIRASGN_TERM_CODE    = SS.SSBSECT_TERM_CODE
            AND SIRASGN_CRN          = SS.SSBSECT_CRN
            AND SIRASGN_PRIMARY_IND  = csY
            AND SS.SSBSECT_CAMP_CODE = csCamp
            AND EXISTS                 (SELECT NULL
                                          FROM SFRSTCR
                                         WHERE SFRSTCR_TERM_CODE  = SIRASGN_TERM_CODE
                                           AND SFRSTCR_CRN        = SIRASGN_CRN
                                           AND SFRSTCR_RSTS_CODE IN (SELECT STVRSTS_CODE FROM STVRSTS WHERE STVRSTS_GRADABLE_IND = csY)
                                           AND SFRSTCR_LEVL_CODE = psNivel
                                       )
            AND (A.SCBCRSE_COLL_CODE = psESCU OR psESCU is null)
            AND ((SS.SSBSECT_CRN       BETWEEN psCRNI AND psCRNF)  or (SS.SSBSECT_CRN > psCRNI and psCRNF is null ) or(SS.SSBSECT_CRN < psCRNF  and psCRNI is null) or (psCRNI is null AND psCRNF is null))
            AND SS.SSBSECT_TERM_CODE = psTERM
          ORDER BY CRN;

  --cuAlumnos
  CURSOR cuAlumnos(psTerm VARCHAR2,
                   psCRN  VARCHAR2
                  ) IS
         SELECT SFRSTCR_PIDM                     AS PIDM,
                PK_CATALOGO.NOMBRE(SFRSTCR_PIDM) AS NOMBRE,
                SFRSTCR_GRDE_CODE                AS FINAL,
                TRUNC(SFRSTCR_GRDE_DATE)         AS FECROLA,
                SFRSTCR_LEVL_CODE                AS LEVL,
                DECODE(SFRSTCR_RSTS_CODE,csRE,csN,
                                         csRW,csN,
                                         csY
                      ) as rAutoGrd
           FROM SFRSTCR
          WHERE SFRSTCR_RSTS_CODE IN (csRE, csRW)
            AND SFRSTCR_CRN        = psCRN
            AND SFRSTCR_TERM_CODE  = psTerm
       ORDER BY NOMBRE;
FUNCTION tiene_cal_vacias(psTerm VARCHAR2,
                   psCRN  VARCHAR2
                  ) return integer
                  
                  is
   vnCount integer:= 0;               
                  
begin
SELECT count(1) into vnCount
 FROM SFRSTCR
          WHERE SFRSTCR_RSTS_CODE IN (csRE, csRW)
            AND SFRSTCR_CRN        = psCRN
            AND SFRSTCR_TERM_CODE  = psTerm
            and SFRSTCR_GRDE_CODE is null;
return vnCount;
  EXCEPTION
      WHEN OTHERS THEN
           RETURN -1;
  END tiene_cal_vacias;
FUNCTION tiene_cal_tipo_p(psTerm VARCHAR2,
                   psCRN  VARCHAR2
                  ) return integer
                  
                  is
   vnCount integer:= 0;               
                  
begin
SELECT count(1) into vnCount
 FROM SFRSTCR
          WHERE SFRSTCR_RSTS_CODE IN (csRE, csRW)
            AND SFRSTCR_CRN        = psCRN
            AND SFRSTCR_TERM_CODE  = psTerm
            and SFRSTCR_RSTS_CODE = 'P';
return vnCount;
  EXCEPTION
      WHEN OTHERS THEN
           RETURN -1;
  
  
  END tiene_cal_tipo_p;                
  --VALIDA SI EL CRN TIENE TODOS SUS ALUMNOS CALIFICADOS Y ROLADOS PARA IMPRIMIR EL ACTA
  --getActaRoladaHA
  FUNCTION getActaRoladaHA(psCRN  VARCHAR2,
                           psTerm VARCHAR2
                          ) RETURN VARCHAR2 IS

  vnAlumsRol     INTEGER     := 0;
  vnAlumnos      INTEGER     := 0;
  vsActaCompleta VARCHAR2(1) := 'N';

  BEGIN
      -- CUANTOS ALUMNOS HAY
      SELECT COUNT(cn1)
        INTO vnAlumnos
        FROM SFRSTCR
       WHERE EXISTS (SELECT STVRSTS_CODE FROM STVRSTS WHERE STVRSTS_GRADABLE_IND = csY AND STVRSTS_CODE = SFRSTCR_RSTS_CODE)
         AND SFRSTCR_CRN       = psCRN
         AND SFRSTCR_TERM_CODE = psTerm;

      -- CUANTOS ALUMNOS ESTAN ROLADOS
      SELECT COUNT(cn1)
        INTO vnAlumsRol
        FROM SFRSTCR
       WHERE EXISTS (SELECT STVRSTS_CODE FROM STVRSTS WHERE STVRSTS_GRADABLE_IND = csY AND STVRSTS_CODE = SFRSTCR_RSTS_CODE)
         AND SFRSTCR_GRDE_DATE IS NOT NULL
         AND SFRSTCR_CRN        = psCRN
         AND SFRSTCR_TERM_CODE  = psTerm;


      -- si el total de alumnos calificados son el total de rolados se muestra el acta
      IF vnAlumnos = vnAlumsRol AND vnAlumnos > 0 THEN
         vsActaCompleta := 'S';
      END IF;

      RETURN vsActaCompleta;
  EXCEPTION
      WHEN OTHERS THEN
           RETURN 'N';
  END getActaRoladaHA;

  ---  OBTIENE FOLIO DEL ACTA
  --F_FOLIO_ACTA
FUNCTION f_get_programaposgrado
(pidm          number,
term_code     varchar)
return varchar2
IS
-- fuente: f_get_programa.sql.
-- Autor : Alfonso Moreno.
-- Uso   : Vistas para Discoverer.
-- Area  : Finanzas.
-- Fecha : 14-enero-2003.
--modify  by Glovicx@  26.04.2014--- se puso lel filtro de level_code = LC
i_programa     varchar2(11) := NULL;
CURSOR chk_sgbstdn IS
SELECT SGBSTDN_PROGRAM_1
FROM SGBSTDN S1
WHERE SGBSTDN_PIDM = pidm
and sgbstdn_levl_code not in( 'LC','LI')
AND SGBSTDN_TERM_CODE_EFF =
                  (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                  FROM SGBSTDN
                  WHERE SGBSTDN_PIDM = S1.SGBSTDN_PIDM
                  AND SGBSTDN_TERM_CODE_EFF <= term_code
                  and sgbstdn_levl_code  not in( 'LC','LI')
                  );
BEGIN
OPEN chk_sgbstdn;
FETCH chk_sgbstdn
INTO i_programa;
IF chk_sgbstdn%NOTFOUND THEN
i_programa := NULL;
END IF;
CLOSE chk_sgbstdn;
return i_programa;
END f_get_programaposgrado;

  FUNCTION F_FOLIO_ACTA(psTermCode VARCHAR2, psCRN VARCHAR2) RETURN VARCHAR2 IS

  vsFolio SWRFOLI.SWRFOLI_TEXT%TYPE DEFAULT NULL;

  BEGIN
      SELECT SWRFOLI_TEXT
        INTO vsFolio
        FROM SWRFOLI
       WHERE SWRFOLI_TERM_CODE = psTermCode
         AND SWRFOLI_CRN       = psCRN;

      RETURN vsFolio;

  EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
  END F_FOLIO_ACTA;

  --encabezado de impresion
  --setEncabezadoPrint
  PROCEDURE setEncabezadoPrint(psOrigen VARCHAR DEFAULT 'B') IS
  BEGIN
      htp.p('<html><head><title>Acta de calificaci&oacute;n final</title>');

      -- la aplicaci;n no se guarda en el cache de la maquina.k
      PK_ObjRuaHTML.P_NoCache;
      htp.p(
      '<style type="text/css">
      <!--
      br.brNuevaPag   {page-break-before:always}
      -->
      </style>'
      );

      --c;digo css
      PK_ObjRuaHTML.P_CssTabs;

      htp.p(
      '<script type="text/javascript">
      <!--
      function fImprimeReporte() {
        window.focus()
      print();
      }

      function fCarga(vbInd){');

      IF psOrigen = 'W' THEN
         null;
      ELSE
         htp.p(
         '
         if (vbInd==0) {
         parent.document.frmTerm.psImprimir.disabled= false;
         } else{
         parent.document.frmTerm.psImprimir.disabled= true;
         }
         parent.abreAacta();
         ');
      END IF;

      htp.p(
      '}

      function DerechosReservados() {
      if (event.button==2) {
      alert("La operación no esta permitida");
      }
      }
      document.onmousedown=DerechosReservados;

      -->
      </script>'
      );
  END setEncabezadoPrint;

  --cuerpo del acta
  --setBodyActa
  PROCEDURE setBodyActa(psTerm    VARCHAR2,
                        psCrn     VARCHAR2,
                        pdFecRola DATE DEFAULT NULL
                       ) IS
  vnRenCorte  INTEGER    :=0;
  vsColorBco  VARCHAR(8) := '#FFFFFF';
  vsColorGris VARCHAR(8) := '#EEEEEE';
  vsColor     VARCHAR(8) := '';

  --ENCABEZADO DEL REPORTE
  --setEncabezadoActa
  PROCEDURE setEncabezadoActa(psTerm    VARCHAR2,
                              psCrn     VARCHAR2,
                              pdFecRola DATE DEFAULT NULL
                             ) IS

  vsPidmProf SIRASGN.sirasgn_pidm%TYPE      := NULL; -- NOMBRE DEL CRN
  vsCollCode STVCOLL.STVCOLL_CODE%TYPE      := NULL; -- CLAVE DE LA FACULTAD
  vsCollDesc STVCOLL.STVCOLL_DESC%TYPE      := NULL; -- NOMBRE DE LA FACULTAD
  vsTitulo   SCBCRSE.SCBCRSE_TITLE%TYPE     := NULL; -- Nombre de la materia
  vsSeccion  SSBSECT.SSBSECT_SEQ_NUMB%TYPE  := NULL; -- seccion
  vsSubj     SSBSECT.SSBSECT_SUBJ_CODE%TYPE := NULL; -- subject
  vsCurso    SSBSECT.SSBSECT_CRSE_NUMB%TYPE := NULL; -- curso
  vsTipo     SSBSECT.SSBSECT_GMOD_CODE%TYPE := NULL; -- tipo
  vsDescTipo STVGMOD.STVGMOD_DESC%TYPE      := NULL; -- descrpcion del tipo

  ---  OBTIENE EL PIDM DEL DIRECTRO DE LA ESCUELA
  --getPidmDirector
  function getPidmDirector(psColl varchar2,
                           psTerm varchar2
                          ) return number is

  vnPidmDire number := 0;

  csDIRE Constant varchar2(4) := 'DIRE';

  begin
      select sirnist_pidm
        into vnPidmDire
        from sirnist
       where sirnist_coll_code = psColl
         and sirnist_term_code = psTerm
         and sirnist_nist_code = csDIRE;

      return vnPidmDire;

  exception
      when others then
           return vnPidmDire;
  end getPidmDirector;

  --LA FUNCION RETORNA EL NOMBRE DEL PERIODO
  --getTermDesc
  function getTermDesc(psTermCode varchar2) return varchar2 is

  vsTermDesc stvterm.stvterm_desc%type := null;

  begin
      select stvterm_desc
        into vsTermDesc
        from stvterm
       where stvterm_code = psTermCode;

      return vsTermDesc;

  exception
      when others then
           return null;
  end getTermDesc;

  BEGIN
      SELECT NVL(SSBOVRR_COLL_CODE,A.SCBCRSE_COLL_CODE),
             pk_catalogo.colegio(NVL(SSBOVRR_COLL_CODE,A.SCBCRSE_COLL_CODE)),
              A.SCBCRSE_TITLE,
             SIRASGN_PIDM,
             SSBSECT_SUBJ_CODE,
             SSBSECT_CRSE_NUMB,
             SSBSECT_SEQ_NUMB,
             SSBSECT_GMOD_CODE,
             DECODE(SSBSECT_GMOD_CODE,csN,csOrdinario,PK_CATALOGO.GRADEMODE(SSBSECT_GMOD_CODE))
        INTO vsCollCode,
             vsCollDesc,
             vsTitulo,
             vsPidmProf,
             vsSubj,
             vsCurso,
             vsSeccion,
             vsTipo,
             vsDescTipo
        FROM SCBCRSE A,
             SSBSECT SS,
             SIRASGN,
             SSBOVRR
       WHERE A.SCBCRSE_SUBJ_CODE  = SS.SSBSECT_SUBJ_CODE
         AND A.SCBCRSE_CRSE_NUMB  = SS.SSBSECT_CRSE_NUMB
         AND A.SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                       FROM SCBCRSE SC
                                      WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                        AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                        AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                    )

         AND SIRASGN_TERM_CODE    = SS.SSBSECT_TERM_CODE
         AND SIRASGN_CRN          = SS.SSBSECT_CRN
         AND SS.SSBSECT_TERM_CODE = SSBOVRR_TERM_CODE(+)
         AND SS.SSBSECT_CRN       = SSBOVRR_CRN(+)
         AND SIRASGN_PRIMARY_IND  = csY
         AND SS.SSBSECT_CRN       = psCRN
         AND SS.SSBSECT_TERM_CODE = psTerm;


      htp.p(
      '<table width="80%" border="1" cellpadding="2" cellspacing="0" align="center">
       <tr class="trTabSepara">'
      );
/*
      IF    pk_ConfigRegistroElectronico.vgsContxAnt = 'UAN' THEN
            htp.p(' <td width="40%" rowspan="6" align="center" valign="top" '||vsEstilo||'><img src="/imagenes/log_anahuac_inst.GIF" width="100" height="90" border="0"></td>');
      ELSIF pk_ConfigRegistroElectronico.vgsContxAnt = 'UAM' THEN
            htp.p(' <td width="40%" rowspan="6" align="center" valign="top" '||vsEstilo||'><img src="/imagenes/'||F_Logotipo||'" width="170" height="90"  border="0"></td>');
      ELSE
            htp.p(' <td width="40%" rowspan="6" align="center" valign="top" '||vsEstilo||'><img src="/imagenes/'||F_Logotipo||'" width="100" height="90" border="0"></td>');
      END IF;
      */
      htp.p(' <td width="40%" rowspan="6" align="center" valign="top" '||vsEstilo||'><img style="height: 1cm;" src="https://ufte.lcred.net/imagenes/Logo_FINIS_Horizontal_escalada.jpg" border="0">');

      htp.p(
      '<td class="tdFont8" width="03%" rowspan="14" '||vsEstilo||'></td>
       <td colspan="3" '||vsEstilo||'><table width="100%" border="0" cellpadding="0" cellspacing="0" >
       <tr><td class="tdFont8" width="80%" align="left"><B>ACTA DE CALIFICACI&Oacute;N FINAL</B></td>
           <td class="tdFont8" width="20%" align="right">
               Hoja'||vnHoja||' de '||vnTotHojas||
               '</td>
               </tr>
           </table>
           </td></tr>
       <tr class="trTabSepara">
           <td class="tdFont8" colspan="3" height="08" '||vsEstilo||'></td></tr>

       <tr class="trTabSepara"><td class="tdFont8" width="57%" colspan="3" >TIPO: '||vsDescTipo||'&nbsp;&nbsp;&nbsp;PERIODO: '||getTermDesc(psTerm)||'</td></tr>
       <tr class="trTabSepara"><td class="tdFont8" colspan="3" height="08" '||vsEstilo||'></td></tr>
       <tr class="trTabSepara"><td class="tdFont8" colspan="3">ESCUELA O DEPARTAMENTO RESPONSABLE: '||vsCollDesc||'</td></tr>
       <tr class="trTabSepara"><td class="tdFont8" colspan="3" height="13" '||vsEstilo||'></td></tr>
       <tr class="trTabSepara">
       <td class="tdFont8" >FOLIO: '||F_FOLIO_ACTA(psTerm, psCRN )||'</td>
       <td class="tdFont8" colspan="3" >PROFESOR : '||pk_catalogo.nombre(vsPidmProf)||'</td></tr>
       <tr class="trTabSepara">
       <td class="tdFont8" colspan="4" height="08" '||vsEstilo||' ></td></tr>
       <tr class="trTabSepara">
       <td class="tdFont8" >FECHA DE IMPRESI&Oacute;N : '||TO_CHAR(SYSDATE,'DD/MM/YYYY')||'</td>
       <td class="tdFont8" colspan="3" >ASIGNATURA : '||vsTitulo||'</td></tr>
       <tr class="trTabSepara">
       <td class="tdFont8" colspan="4" height="08" '||vsEstilo||'></td></tr>
       <tr class="trTabSepara">
       <td class="tdFont8">FECHA DE EMISI&Oacute;N : '||TO_CHAR(pdFecRola,'DD/MM/YYYY')||'</td>
       <td class="tdFont8" colspan="3" >CRN: '||psCrn||'&nbsp;&nbsp;CLAVE:&nbsp;'||vsSubj||' '||vsCurso||'&nbsp;&nbsp;SECCI&Oacute;N:&nbsp;'||vsSeccion||'</td></tr>
       <tr class="trTabSepara"><td class="tdFont8" colspan="3" height="08" '||vsEstilo||'></td></tr>
       <tr class="trTabSepara">
       <td class="tdFont8" style="border-bottom:none;" height="40" valign="top" align="left">SINODAL: '||pk_catalogo.nombre(vsPidmProf)||'</td>
       <td class="tdFont8" style="border-bottom:none;" valign="top" align="left" width="200">SINODAL</td>
       <td class="tdFont8" width="10" '||vsEstilo||'></td>
       <td class="tdFont8" style="border-bottom:none;" valign="top" align="left" width="200">DIRECTOR : '||pk_catalogo.nombre(getPidmDirector(vsCollCode, psTerm))||'</td></tr>
       <tr class="trTabSepara">
       <td class="tdFont7" style="border-top:none;" align="center" height="21">FIRMA</td>
       <td class="tdFont7" style="border-top:none;" align="center">FIRMA</td>
       <td class="tdFont7" '||vsEstilo||'></td>
       <td class="tdFont7" style="border-top:none;" align="center">FIRMA</td> </tr>
       </table><br/>'
       );

       --- ENCABEZADO DE LA LISTA DE ALUMNOS
       htp.p(
       '<table width="80%" border="1" cellpadding="2" cellspacing="0" align="center">
        <tr class="trTabSepara">
            <td class="tdFont8" width="05%" bgcolor="#CCCCCC" align="center"><b>No.</b></td>
            <td class="tdFont8" width="20%" bgcolor="#CCCCCC" align="center"><b>Expediente</b></td>
            <td class="tdFont8" width="35%" bgcolor="#CCCCCC" align="center"><b>Nombre</b></td>
            <td class="tdFont8" width="25%" bgcolor="#CCCCCC" align="center"><b>Programa</b></td>
            <td class="tdFont8" width="15%" bgcolor="#CCCCCC" align="center"><b>Calificaci&oacute;n Final</b></td>
            </tr>'
       );
  END setEncabezadoActa;

  --  PIE DEL DOCUMENTO - FIRMAS DEL ACTA
  --setPieActa
  PROCEDURE setPieActa IS

  BEGIN
      IF vnRenglon = vnRows THEN
         htp.p(
         '<tr class="trTabSepara">
         <td colspan="5" align="center" class="tdFont7" '||vsEstilo||'>**********NADA V&Aacute;LIDO DESPU&Eacute;S DE ESTA L&Iacute;NEA**********</td></tr>'
         );
      END IF;

      htp.p(
      '</table>

      <table width="50%" border="0" cellpadding="0" cellspacing="0" align="center">
      <tr class="trTabSepara" >
          <td class="tdFont8" width="45%" align="center" height="120" valign="bottom">__________________________</td>
          <td class="tdFont8" width="10%"></td>
          <td class="tdFont8" width="45%" align="center" valign="bottom">__________________________</td></tr>

      <tr class="trTabSepara">
          <td class="tdFont7" width="45%" align="center">Sello de la escuela o departamento</td>
          <td class="tdFont7" width="10%"></td>
          <td class="tdFont7" width="45%" align="center">Sello de Administraci&oacute;n Escolar</td></tr>
      </table>'
      );
  END setPieActa;

  BEGIN
      -- INFORMACION ENCABEZADO
      htp.p('</head><body bgcolor="#ffffff" class="bodyCeroR" onLoad="fCarga(0);"><br/>');

      setEncabezadoActa(psTerm , psCrn, pdFecRola);

      vnRenglon  := 0;
      vnRenCorte := 0;

      -- CUERPO DEL REPORTE
      FOR vnC IN 1..vnRows  LOOP
          vnRenglon  := vnRenglon  + 1;
          vnRenCorte := vnRenCorte + 1;

          IF MOD(vnRenglon,2) = 0 THEN
             vsColor := vsColorGris;
          ELSE
             vsColor := vsColorBco;
          END IF;

          htp.p(
          '<tr class="trTabSepara" bgcolor="'||vsColor||'">'||
          '<td class="tdFont8" align="center">'||vnRenglon                                 ||'</td>'||
          '<td class="tdFont8" align="center">'||F_GET_ID(tabAlum(vnC).rPidm )             ||'</td>'||
          '<td class="tdFont8" align="left">'  ||tabAlum(vnC).rNombre                      ||'</td>'||
          '<td class="tdFont8" align="center">'||F_GET_PROGRAMAPOSGRADO (tabAlum(vnC).rPidm,psTerm)||'</td>'||
          '<td class="tdFont8" align="center">'||tabAlum(vnC).rCalif                       ||'</td>'||
          '</tr>'
          );

          IF vnRenCorte = vnRegsxHoja THEN
             setPieActa; ------------ PIE DEL DOCUMENTO - FIRMAS DEL ACTA

             IF vnRows > vnRenglon THEN
                htp.p('<br class="brNuevaPag"/>');
                vnHoja := vnHoja +1 ;
                setEncabezadoActa(psTerm , psCrn, pdFecRola);
             END IF;

             vnRenCorte := 0;
          END IF;
      END LOOP;

      -- PIE DEL DOCUMENTO - FIRMAS DEL ACTA
      IF (vnRegsxHoja -vnRenCorte)  <  vnRegsxHoja THEN
         setPieActa;
      END IF;

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P('ERROR EN setBodyActa '||SQLERRM);
  END setBodyActa;

  ---  REIMPRESION DE ACTAS VIA BANNER
  --printActa

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      ----encabezado de impresion
      setEncabezadoPrint('W');

      vsTerm := pk_objRuaHtml.getValueCookie('psPePos');
      vsCol  := pk_objRuaHtml.getValueCookie('psEscu');
      vsCrnI := pk_objRuaHtml.getValueCookie('psTCrnI');
      vsCrnF := pk_objRuaHtml.getValueCookie('psTCrnF');
      vsNivel := pk_objRuaHtml.getValueCookie('psNivPo');

      FOR regCRN IN cuCRN(vsTerm,vsCol, vsCrnI, vsCrnF,vsNivel) LOOP
            -- inc 7536
            if tiene_cal_vacias(vsTerm, regCRN.crn) > 0 then
             htp.p('<font size="3" color="red">El CRN '|| regCRN.crn || ' tiene calificaciones vacias</font></br>');             
              viFlag:=1;
             end if;
             
             if tiene_cal_tipo_p(vsTerm, regCRN.crn) > 0 then
             htp.p('<font size="3" color="red">El CRN '|| regCRN.crn || ' tiene calificaciones tipo P</font>');
             viFlag:=1;
             end if;
           
          vsActaRoll := getActaRoladaHA(regCRN.crn, vsTerm);
          IF vsActaRoll = 'N' and viFlag = 0 THEN
             SHKROLS.P_DO_GRADEROLL(vsTerm,regCRN.crn,USER,'1','1','O','','','','');
             COMMIT;
          END IF;

          vsActaRoll := getActaRoladaHA(regCRN.crn, vsTerm);

          IF  vsActaRoll = 'S' THEN
              viRows := viRows + 1;
         
         if (viFlag=0) then
         
              FOR regAlu IN cuAlumnos(vsTerm, regCRN.crn) LOOP
                  vnRows  := vnRows  + 1;
                  tabAlum(vnRows).rPidm   := regAlu.Pidm;
                  tabAlum(vnRows).rNombre := regAlu.Nombre;
                  tabAlum(vnRows).rCalif  := regAlu.Final;
                  vdFecRola               := regAlu.FecRola;
              END LOOP;

              vnTotHojas := TRUNC(vnRows /vnRegsxHoja);

              IF vnTotHojas = 0 THEN
                 vnTotHojas := 1;
              END IF;

              IF MOD(vnRows , vnRegsxHoja) > 0 AND vnRows > vnRegsxHoja THEN
                  vnTotHojas :=  vnTotHojas +1;
              END IF;

              setBodyActa(vsTerm ,regCRN.crn, vdFecRola);

              htp.p('<br class="brNuevaPag"/>');

              tabAlum.DELETE();
              vnRows     := 0;
              vnTotHojas := 0 ;
              vnHoja     := 1;
          END IF;

      

      
      end if;
      END LOOP;
/*
      IF viRows = 0 THEN
          IF vsActaRoll = 'N' THEN
              htp.p(
              '</head><body bgcolor="#ffffff">
              <font color="#0000ff" size="4">
                    Las calificaciones no han sido roladas a Historia Académica.</font>
              </body></html>'
              );
          ELSE
             htp.p(
             '</head><body bgcolor="#ffffff">
              <font color="#00aa00" size="4">
                    Esta consulta no ha arrojado datos.</font>
              </body></html>'
              );
          END IF;
      END IF;
      */
      htp.p('<script language="javascript" src="kwacnls.js"></script>');
    EXCEPTION
      WHEN OTHERS THEN
           htp.p('Error '||sqlerrm);
END PWRACBA;
/
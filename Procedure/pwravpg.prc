DROP PROCEDURE BANINST1.PWRAVPG;

CREATE OR REPLACE PROCEDURE BANINST1.pwravpg (psReclDesc VARCHAR2, psSiu VARCHAR2 DEFAULT NULL)
IS
   /*
            TAREA: Avance de captura de programas magisteriales
            FECHA: 09/08/2010
            AUTOR: GEPC
           MODULO: Programación Academica

     MODIFICACIÓN: 07/12/2010
                   CCR
                   Se le agrego la instrucción para que termine la imagen load del reporte

     MODIFICACIÓN: 08/02/2011
                   GEPC
                   * Se cambio el valor del parametro "ps2" a "NULL" del procedimiento "PWAINGD"
                     para mostrar todas la materias

     MODIFICACION: 21/09/2011
                   JCCR
                   * Se Ajustan Totales INGRESADOS - NO INGRESADOS y sus Detalles , se Agrega Temporal TWRPRMG
                     para control de estas cifras


   */

   global_pidm       spriden.spriden_pidm%TYPE;

   vsPeriodoDesc     STVTERM.STVTERM_DESC%TYPE := NULL;
   vsEscuelaDesc     STVCOLL.STVCOLL_DESC%TYPE := NULL;
   vnTermYs          NUMBER (5) := 0;
   vnTermNo          NUMBER (5) := 0;
   vnCursos          NUMBER (5) := 0;
   vnCursosEnd       NUMBER (5) := 0;
   vnCursosNot       NUMBER (5) := 0;
   vnCursosSolVoBo   NUMBER (5) := 0;
   vnTotalM          NUMBER := 0;
   vnTotalC          NUMBER := 0;
   vnTotalCno        NUMBER := 0;
   vnPorcentajeP     NUMBER := 0;
   vnTotalCrs        NUMBER (5) := 0;
   vnTotalEnd        NUMBER (5) := 0;
   vnTotalNot        NUMBER (5) := 0;
   vnTotalSolVoBo    NUMBER (5) := 0;
   vsCamp            VARCHAR2 (6) := NULL;
   vsSede            VARCHAR2 (10) := NULL;
   vsTerm            VARCHAR2 (10) := NULL;
   vsColl            VARCHAR2 (10) := NULL;

   csC      CONSTANT VARCHAR2 (1) := 'C';
   csY      CONSTANT VARCHAR2 (1) := 'Y';
   csS      CONSTANT VARCHAR2 (1) := 'S';
   cn0      CONSTANT NUMBER (1) := 0;
   cn1      CONSTANT NUMBER (1) := 1;


   vnPaso            INTEGER := 0;

   --cuProfesore
   CURSOR cuProfesore
   IS
        SELECT FWRSIRG_COLL_CODE AS collCode,
               COUNT (DISTINCT FWRSIRG_PIDM) AS sirgPidm
          FROM FWRSIRG B
      GROUP BY FWRSIRG_COLL_CODE
      ORDER BY FWRSIRG_COLL_CODE;

   --programasTerminados
   FUNCTION programasTerminados (psCollCode VARCHAR2)
      RETURN NUMBER
   IS
      vnTerminaron      NUMBER (5) := 0;
      vnTerminds        NUMBER (5) := NULL;
      vnMaterias        NUMBER (5) := NULL;

      csTerm   CONSTANT VARCHAR2 (6) := vsTerm;
      cnCero   CONSTANT NUMBER (1) := 0;

      CURSOR cuMaterias
      IS
           SELECT c.fwrsirg_pidm AS sirgPidm, COUNT (c.fwrsirg_crn) AS sirgCrnn
             FROM fwrsirg c
            WHERE c.fwrsirg_coll_code = psCollCode
                  AND c.fwrsirg_pidm IN (SELECT pidmok
                                           FROM (SELECT orig.twrprmg_pidm
                                                           pidmok,
                                                        reg,
                                                        noreg
                                                   FROM (SELECT DISTINCT
                                                                twrprmg_pidm
                                                           FROM twrprmg) orig,
                                                        (  SELECT twrprmg_pidm,
                                                                  COUNT (
                                                                     twrprmg_crn)
                                                                     reg
                                                             FROM twrprmg
                                                            WHERE twrprmg_registrado !=
                                                                     cn0
                                                         GROUP BY twrprmg_pidm) regisrados,
                                                        (  SELECT twrprmg_pidm,
                                                                  COUNT (
                                                                     twrprmg_crn)
                                                                     noreg
                                                             FROM twrprmg
                                                            WHERE twrprmg_registrado =
                                                                     cn0
                                                         GROUP BY twrprmg_pidm) noregistrados
                                                  WHERE orig.twrprmg_pidm =
                                                           regisrados.
                                                            twrprmg_pidm(+)
                                                        AND orig.twrprmg_pidm =
                                                               noregistrados.
                                                                twrprmg_pidm(+))
                                          WHERE noreg IS NULL)
         GROUP BY c.fwrsirg_pidm;
   BEGIN
      FOR regMat IN cuMaterias
      LOOP
         vnTerminaron := vnTerminaron + 1;
      END LOOP;

      RETURN vnTerminaron;
   END programasTerminados;

   --programasNoTerminados
   FUNCTION programasNoTerminados (psCollCode VARCHAR2)
      RETURN NUMBER
   IS
      vnTerminaron      NUMBER (5) := 0;
      vnTerminds        NUMBER (5) := NULL;
      vnMaterias        NUMBER (5) := NULL;

      csTerm   CONSTANT VARCHAR2 (6) := vsTerm;
      cnCero   CONSTANT NUMBER (1) := 0;

      CURSOR cuMaterias
      IS
           SELECT c.fwrsirg_pidm AS sirgPidm, COUNT (c.fwrsirg_crn) AS sirgCrnn
             FROM fwrsirg c
            WHERE c.fwrsirg_coll_code = psCollCode
                  AND c.fwrsirg_pidm IN (SELECT pidmok
                                           FROM (SELECT orig.twrprmg_pidm
                                                           pidmok,
                                                        reg,
                                                        noreg
                                                   FROM (SELECT DISTINCT
                                                                twrprmg_pidm
                                                           FROM twrprmg) orig,
                                                        (  SELECT twrprmg_pidm,
                                                                  COUNT (
                                                                     twrprmg_crn)
                                                                     reg
                                                             FROM twrprmg
                                                            WHERE twrprmg_registrado !=
                                                                     cn0
                                                         GROUP BY twrprmg_pidm) regisrados,
                                                        (  SELECT twrprmg_pidm,
                                                                  COUNT (
                                                                     twrprmg_crn)
                                                                     noreg
                                                             FROM twrprmg
                                                            WHERE twrprmg_registrado =
                                                                     cn0
                                                         GROUP BY twrprmg_pidm) noregistrados
                                                  WHERE orig.twrprmg_pidm =
                                                           regisrados.
                                                            twrprmg_pidm(+)
                                                        AND orig.twrprmg_pidm =
                                                               noregistrados.
                                                                twrprmg_pidm(+))
                                          WHERE noreg IS NOT NULL)
         GROUP BY c.fwrsirg_pidm;
   BEGIN
      FOR regMat IN cuMaterias
      LOOP
         vnTerminaron := vnTerminaron + 1;
      END LOOP;

      RETURN vnTerminaron;
   END programasNoTerminados;

   --cursos
   FUNCTION cursos (psCollCode VARCHAR2)
      RETURN NUMBER
   IS
      vnCantidad   NUMBER (5) := 0;
   BEGIN
      SELECT COUNT (DISTINCT swrpgac_crn)
        INTO vnCantidad
        FROM swrpgac
       WHERE EXISTS
                (SELECT NULL
                   FROM fwrsirg
                  WHERE fwrsirg_crn = swrpgac_crn
                        AND fwrsirg_term_code = swrpgac_term_code)
             AND swrpgac_coll_code = psCollCode;

      RETURN vnCantidad;
   END cursos;

   --cursosTerminados
   FUNCTION cursosTerminados (psCollCode VARCHAR2)
      RETURN NUMBER
   IS
      vnCantidad   NUMBER (5) := 0;
   BEGIN
      SELECT COUNT (DISTINCT swrpgac_crn)
        INTO vnCantidad
        FROM swrpgac, fwrsirg
       WHERE swrpgac_crn = fwrsirg_crn
             AND swrpgac_term_code = fwrsirg_term_code
             AND EXISTS
                    (SELECT NULL
                       FROM fwrpblc
                      WHERE     fwrpblc_publicar = csY
                            AND fwrpblc_crn = swrpgac_crn
                            AND fwrpblc_term_code = swrpgac_term_code)
             AND swrpgac_coll_code = psCollCode;

      RETURN vnCantidad;
   END cursosTerminados;

   --cursosNoTerminados
   FUNCTION cursosNoTerminados (psCollCode VARCHAR2)
      RETURN NUMBER
   IS
      vnCantidad   NUMBER (5) := 0;
   BEGIN
      SELECT COUNT (swrpgac_crn)
        INTO vnCantidad
        FROM swrpgac
       WHERE NOT EXISTS
                    (SELECT NULL
                       FROM fwrpblc
                      WHERE     fwrpblc_solc_vobo = csY
                            AND fwrpblc_crn = swrpgac_crn
                            AND fwrpblc_term_code = swrpgac_term_code)
             AND EXISTS
                    (SELECT NULL
                       FROM fwrsirg
                      WHERE fwrsirg_crn = swrpgac_crn
                            AND fwrsirg_coll_code = psCollCode)
             AND swrpgac_coll_code = psCollCode;

      RETURN vnCantidad;
   END cursosNoTerminados;

   --cursosSolVoBo
   FUNCTION cursosSolVoBo (psCollCode VARCHAR2)
      RETURN NUMBER
   IS
      vnCantidad   NUMBER (5) := 0;
   BEGIN
      SELECT COUNT (swrpgac_crn)
        INTO vnCantidad
        FROM swrpgac, fwrsirg
       WHERE swrpgac_term_code = fwrsirg_term_code
             AND swrpgac_crn = fwrsirg_crn
             AND EXISTS
                    (SELECT NULL
                       FROM fwrpblc
                      WHERE     fwrpblc_solc_vobo = csY
                            AND fwrpblc_publicar IS NULL
                            AND fwrpblc_crn = swrpgac_crn
                            AND fwrpblc_term_code = swrpgac_term_code)
             AND fwrsirg_coll_code = psCollCode;

      RETURN vnCantidad;
   END cursosSolVoBo;
BEGIN
   -- valida que el usuario pertenezca a la base de datos.
   IF psSiu IS NULL
   THEN
      IF PK_Login.F_ValidacionDeAcceso (PK_Login.vgsUSR) THEN RETURN; END IF;


      vsCamp := pk_objHtml.getValueCookie ('psUnive');
   ELSIF psSiu IS NOT NULL
   THEN
      IF NOT twbkwbis.F_ValidUser (global_pidm)
      THEN
         RETURN;
      END IF;

      vsCamp := 'UFT';
   END IF;

   vsTerm := pk_objHtml.getValueCookie ('psPerio');
   vsColl := pk_objHtml.getValueCookie ('psEscu');
   vsSede := pk_objhtml.getValueCookie ('psDept');

   --Llena tablas de paso para mejorar la velocidad en el reporte
   PWAAVPG (vsCamp,
            vsTerm,
            vsColl,
            vsSede);

   vsPeriodoDesc := pk_Catalogo.Periodo (vsTerm);

   HTP.
    p (
         '<html><head><title>'
      || CHR (38)
      || 'nbsp;</title>
      <script language="javascript" src="kwacnls.js"></script>
      ');

   -- la aplicacioacute;n no se guarda en el cache de la maquina.
   PK_ObjHTML.P_NoCache;

   --coacute;digo css
   PK_ObjHTML.P_CssTabs;

   HTP.p ('<script language="JavaScript"><!--');

   --fEjecuta
   HTP.
    p (
      'function fEjecuta(psCOLL,pnVAL) {
         document.frmAction.psColl.value = psCOLL;

                if(pnVAL == 1) {
                   document.frmAction.action = "kwaprmg2.siIngresoPrograma";

         } else if(pnVAL == 2) {
                   document.frmAction.action = "kwaprmg2.noIngresoPrograma";

         } else if(pnVAL == 3) {
                   document.frmAction.action = "kwaprmg2.asignaturaPublicada";

         } else if(pnVAL == 4) {
                   document.frmAction.action = "kwaprmg2.asignaturaVoBo";

         } else if(pnVAL == 5) {
                   document.frmAction.action = "kwaprmg2.asignaturaFaltante";

         }
         document.frmAction.submit();

      }');

   --fImprimeReporte
   HTP.p ('function fImprimeReporte() {
      window.focus();
      print();
      }');

   HTP.p ('--></script>');

   HTP.
    p (
      '</head><body bgcolor="#ffffff">
      <table width="1085" border="0" cellpadding="0" cellspacing="0" align="center" bordercolor="#cccccc">
             <tr><td width="145px" rowspan="4">
                     <img src="/imagenes/'
      || 'logouft.gif'
      || '" tabindex="-1" border="0" width="100pt">
                     </td>
                 <td width="'
      || (1085 - 145)
      || 'px">
                     Avance de captura de programas magisteriales</td></tr>
             <tr><td>
                     '
      || vsTerm
      || ' '
      || vsPERIODODESC
      || '</td></tr>
             <tr><td>
                     '
      || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS')
      || '</td></tr>
             <tr><td>'
      || CHR (38)
      || 'nbsp;</td></tr>
             <tr><td colspan="2">'
      || CHR (38)
      || 'nbsp;</td></tr>
      </table>

      <table width="1085px" border="1" cellpadding="2" cellspacing="1" align="center" bordercolor="#cccccc">
             <tr bgcolor="#efefef">
                 <th width="205px" valign="top">
                     Escuela o Facultad</th>
                 <th width="110px" valign="top">
                     Total de Maestros
                     </th>
                 <th width="110px" valign="top">
                     Maestros con programa terminado
                     </th>
                 <th width="110px" valign="top">
                     Maestros Faltantes de terminar programa
                     </th>
                 <th width="110px" valign="top">
                     % de profesores que capturaron programa
                     </th>
                 <th width="110px" valign="top">
                     Asignaturas Totales
                     </th>
                 <th width="110px" valign="top">
                     Asignaturas Publicadas
                     </th>
                 <th width="110px" valign="top">
                     Asignaturas con solicitud de Vo.Bo.
                     </th>
                 <th width="110px" valign="top">
                     Asignaturas Faltantes
                     </th>
                     </tr>');

   FOR regPrf IN cuProfesore
   LOOP
      vnPorcentajeP := 0;
      vsEscuelaDesc := pk_catalogo.colegio (regPrf.collCode);

      --- Temporal Adicional para Validar REGISTRADOS - NO REGISTRADOS
      DELETE twrprmg;

      INSERT INTO twrprmg
           SELECT fwrsirg_pidm AS sirgPidm,
                  fwrsirg_crn AS sirgCrnn,
                  NVL (
                     (SELECT cn1
                        FROM fwrpblc
                       WHERE     fwrpblc_publicar = csY
                             AND fwrpblc_crn = fwrsirg_crn
                             AND fwrpblc_term_code = vsTerm),
                     cn0)
                     esRegistrado
             FROM fwrsirg
            WHERE fwrsirg_coll_code = regPrf.collCode
         ORDER BY fwrsirg_pidm;

      vnTermYs := programasTerminados (regPrf.collCode);
      vnTermNo := programasNoTerminados (regPrf.collCode);
      vnCursos := cursos (regPrf.collCode);
      vnCursosEnd := cursosTerminados (regPrf.collCode);
      vnCursosNot := cursosNoTerminados (regPrf.collCode);
      vnCursosSolVoBo := cursosSolVoBo (regPrf.collCode);

      vnTotalEnd := vnCursosEnd + vnTotalEnd;
      vnTotalNot := vnCursosNot + vnTotalNot;
      vnTotalSolVoBo := vnCursosSolVoBo + vnTotalSolVoBo;
      vnTotalCrs := vnCursos + vnTotalCrs;

      IF vnTermYs <> 0 AND regPrf.sirgPidm <> 0
      THEN
         vnPorcentajeP := ROUND ( (vnTermYs / regPrf.sirgPidm) * 100, 2);
      END IF;

      HTP.
       p (
            '<tr '
         || PK_ObjHTML.vgsRenglon
         || '>
          <td align="left">'
         || vsEscuelaDesc
         || '</td>
          <td align="right">'
         || regPrf.sirgPidm
         || '</td>
          <td align="right">
              <a href="javascript:fEjecuta('''
         || regPrf.collCode
         || ''',1);" onMouseOver="window.status='''
         || vsEscuelaDesc
         || ' '
         || vnTermYs
         || '''; return true;" onMouseOut="window.status=''''; return true;">
              '
         || vnTermYs
         || '
              </a></td>
          <td align="right">
              <a href="javascript:fEjecuta('''
         || regPrf.collCode
         || ''',2);" onMouseOver="window.status='''
         || vsEscuelaDesc
         || ' '
         || vnTermNo
         || '''; return true;" onMouseOut="window.status=''''; return true;">
              '
         || vnTermNo
         || '
              </a></td>
          <td align="right">'
         || vnPorcentajeP
         || '%</td>
          <td align="right">'
         || vnCursos
         || '</td>
          <td align="right">
              <a href="javascript:fEjecuta('''
         || regPrf.collCode
         || ''',3);" onMouseOver="window.status='''
         || vsEscuelaDesc
         || ' '
         || vnCursosEnd
         || '''; return true;" onMouseOut="window.status=''''; return true;">
              '
         || vnCursosEnd
         || '
              </a></td>
          <td align="right">
              <a href="javascript:fEjecuta('''
         || regPrf.collCode
         || ''',4);" onMouseOver="window.status='''
         || vsEscuelaDesc
         || ' '
         || vnCursosEnd
         || '''; return true;" onMouseOut="window.status=''''; return true;">
              '
         || vnCursosSolVoBo
         || '
              </a></td>
          <td align="right">
              <a href="javascript:fEjecuta('''
         || regPrf.collCode
         || ''',5);" onMouseOver="window.status='''
         || vsEscuelaDesc
         || ' '
         || vnCursosNot
         || '''; return true;" onMouseOut="window.status=''''; return true;">
              '
         || vnCursosNot
         || '
              </a></td>
          </tr>');

      vnTotalCno := vnTotalCno + vnTermNo;
      vnTotalM := vnTotalM + regPrf.sirgPidm;
      vnTotalC := vnTotalC + vnTermYs;
   END LOOP;

   vnPorcentajeP := 0;

   IF vnTotalM <> 0 AND vnTotalC <> 0
   THEN
      vnPorcentajeP := ROUND ( (vnTotalC / vnTotalM) * 100, 2);
   END IF;

   HTP.
    p (
         '<tr bgcolor="#efefef">
      <th align="center">Total</th>
      <th align="right">'
      || vnTotalM
      || '</th>
      <th align="right">'
      || vnTotalC
      || '</th>
      <th align="right">'
      || vnTotalCno
      || '</th>
      <th align="right">'
      || vnPorcentajeP
      || '%</th>

      <th align="right">'
      || vnTotalCrs
      || '</th>
      <th align="right">'
      || vnTotalEnd
      || '</th>
      <th align="right">'
      || vnTotalSolVoBo
      || '</th>
      <th align="right">'
      || vnTotalNot
      || '</th>
      </tr></table><br/>

      <form name="frmAction" method="post">
      <input type="hidden" name="psCamp" value="'
      || vsCamp
      || '">
      <input type="hidden" name="psTerm" value="'
      || vsTerm
      || '">
      <input type="hidden" name="psColl" >
      <input type="hidden" name="psSede" >
      <input type="hidden" name="psSiu" value="'
      || psSiu
      || '">
      </form>

      </html></body>');

   ROLLBACK;
EXCEPTION
   WHEN OTHERS
   THEN
      HTP.p (SQLERRM);
END PWRAVPG;
/


DROP PUBLIC SYNONYM PWRAVPG;

CREATE PUBLIC SYNONYM PWRAVPG FOR BANINST1.PWRAVPG;


GRANT EXECUTE ON BANINST1.PWRAVPG TO WWW_USER;

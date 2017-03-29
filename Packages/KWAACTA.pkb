CREATE OR REPLACE PACKAGE BODY BANINST1.KWAACTA IS
/*
--   Tarea: Generación de actas de calificación
   Fecha: 01/12/2010
   Autor: GEPC

Modifica   : 11/01/2011
             JCCR
             * Se Modifica el Detalle del cursor U_ESTUDIANTE, a Igualarlo al de Reporte de CAlificaciones
               PK_refcaliReporteCalif, ya que no estaba igual y mostrana lo de la tabla SFRSTCR
               Se modifico
             * Se Ajusta Que el Calculo de CAlif Final Cuadre con Acta y Registro en tabla y Campo  SFRSTCR_GRDE_CODE

        modificacion   :  se modifica el scope a solo RE,RW
                          y que solo actualice donde SFRSTCR_GRDE_CODE  =  NULL
            fecha      :  2-ago-2013
            autor      :  Roman Ruiz
         codigo mod    :  md-01


        modificacion   :  se deshabilita el uso de botton (imprimr) y solo se activa
                          hasta que cumpla con los requisitos.
            fecha      :  26-nov-2014
            autor      :  Roman Ruiz
         codigo mod    :  md-02

--


*/

  TYPE regALUM IS RECORD (rPidm   SPRIDEN.SPRIDEN_PIDM%TYPE,
                          rId     SPRIDEN.SPRIDEN_ID%TYPE,
                          rNombre VARCHAR2(300),
                          rCalif  SFRSTCR.SFRSTCR_GRDE_CODE%TYPE
                         );

  TYPE tableAlum IS TABLE OF regAlum INDEX BY BINARY_INTEGER;

  global_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;
  vgsTerm     VARCHAR2(6);
  vgsCrnn     VARCHAR2(6);

  vsEstilo     VARCHAR(100) := 'style="border-bottom:none;border-top:none;border-left:none;border-right:none"';
  vnHoja       INTEGER      := 1;
  vnRegsxHoja  INTEGER      := 25;
  vnRows        INTEGER      := 0;
  vnRenglon    INTEGER      := 0;
  vnTotHojas   INTEGER      := 0;
  tabAlum      tableAlum;

  csY         CONSTANT VARCHAR2(1) := 'Y';
  csN         CONSTANT VARCHAR2(1) := 'N';
  csEsp       CONSTANT VARCHAR2(1) := ' ';
  csEne       CONSTANT VARCHAR2(1) := 'ñ';
  csAst       CONSTANT VARCHAR2(1) := '*';
  csTilde     CONSTANT VARCHAR2(8) := '&ntilde;';
  csOrdinario CONSTANT VARCHAR2(9) := 'Ordinario';

  --ALUMNOS QUE SERAN MOSTRADOS EN EL ACTA DE CALIFICACIONES
  --cuAlumnos
  CURSOR cuAlumnos(psTerm VARCHAR2,
                   psCRN  VARCHAR2
                  ) IS
         SELECT SFRSTCR_PIDM                          AS idemPm,
                SPRIDEN_ID                            AS idenId,
                REPLACE(REPLACE(SPRIDEN_LAST_NAME ||csEsp||
                                SPRIDEN_FIRST_NAME||csEsp||
                                SPRIDEN_MI,csEne,csTilde
                               ),  csAst,csEsp  )     AS idenNm,
                SFRSTCR_GRDE_CODE                     AS gradeC,
                TRUNC(SFRSTCR_GRDE_DATE)              AS gradeD
           FROM SFRSTCR INNER JOIN SPRIDEN ON SFRSTCR_PIDM = SPRIDEN_PIDM
          WHERE SPRIDEN_CHANGE_IND IS NULL
            AND SFRSTCR_RSTS_CODE  IN (SELECT STVRSTS_CODE FROM STVRSTS WHERE STVRSTS_GRADABLE_IND = csY)
            AND SFRSTCR_CRN         = psCRN
            AND SFRSTCR_TERM_CODE   = psTerm
          ORDER BY idenNm;

  -- VALIDA SI EL CRN TIENE TODOS SUS ALUMNOS CALIFICADOS Y ROLADOS PARA IMPRIMIR EL ACTA
  FUNCTION actaRolada(psCRN  VARCHAR2,
                      psTerm VARCHAR2
                     ) RETURN BOOLEAN;

  -- OBTIENE FOLIO DEL ACTA
  FUNCTION obtieneFolioActa(psTermCode VARCHAR2, psCRN VARCHAR2) RETURN VARCHAR2;

  -- OBTIENE EL PIDM DEL DIRECTRO DE LA ESCUELA
  FUNCTION pidmDire(psColl VARCHAR2,psTerm VARCHAR2) RETURN NUMBER;

  --EL PROCEDIMIENTO GENERA LOS FRAIMS DE LA APLICACIÓN
  PROCEDURE consulta;

  -- *Antes de generar el acta y rolar las calificaciones a "HA"
  --  las calificaciones en null se les asigna la calificación "P"
  PROCEDURE gradeP(psTerm VARCHAR2,
                   psCrnn VARCHAR2
                  );

  -- *Antes de generar el acta y rolar las calificaciones a "HA"
  --  las calificaciones en null se les asigna la calificación "P"
  PROCEDURE gradeP(psTerm VARCHAR2,
                   psCrnn VARCHAR2
                  ) IS

  csP       CONSTANT VARCHAR2(1) := 'P';
  csRE      CONSTANT VARCHAR2(2) := 'RE';
  csRW      CONSTANT VARCHAR2(2) := 'RW';
  csKWAACTA CONSTANT VARCHAR2(7) := 'KWAACTA';

  BEGIN
      DELETE FROM SHRCMRK
       WHERE SHRCMRK_PIDM      IN (SELECT SFRSTCR_PIDM
                                     FROM SFRSTCR
                                    WHERE (
                                              SFRSTCR_GRDE_CODE     IS NULL
                                    /*  md-01 start
                                           OR
                                              SFRSTCR_GRDE_CODE_MID IS NULL
                                              md-01 end
                                      */
                                          )
                                      AND SFRSTCR_RSTS_CODE IN (csRE, csRW)
                                      AND SFRSTCR_GRDE_DATE IS NULL
                                      AND SFRSTCR_CRN        = psCrnn
                                      AND SFRSTCR_TERM_CODE  = psTerm
                                  )
         AND SHRCMRK_CRN        = psCrnn
         AND SHRCMRK_TERM_CODE  = psTerm;


  --  md-01 start
--    UPDATE SFRSTCR
--         SET  SFRSTCR_GRDE_CODE_MID = csP,
--             SFRSTCR_USER          = csKWAACTA,
--             SFRSTCR_DATA_ORIGIN   = csKWAACTA
--       WHERE SFRSTCR_GRDE_CODE_MID IS NULL
--         AND SFRSTCR_RSTS_CODE IN (csRE, csRW)
--         AND SFRSTCR_GRDE_DATE IS NULL
--         AND SFRSTCR_CRN        = psCrnn
--         AND SFRSTCR_TERM_CODE  = psTerm;
  -- md-01 end

      UPDATE SFRSTCR
         SET SFRSTCR_GRDE_CODE     = csP,
     --        SFRSTCR_GRDE_CODE_MID = csP,   --md-01
             SFRSTCR_USER          = csKWAACTA,
             SFRSTCR_DATA_ORIGIN   = csKWAACTA
       WHERE (
                 SFRSTCR_GRDE_CODE     IS NULL
              OR
                 SFRSTCR_GRDE_CODE_MID IS NULL
             )
         AND SFRSTCR_RSTS_CODE IN (csRE, csRW)
         AND SFRSTCR_GRDE_DATE IS NULL
         AND SFRSTCR_CRN        = psCrnn
         AND SFRSTCR_TERM_CODE  = psTerm;

      COMMIT;

  END gradeP;

  --procesaActa
  PROCEDURE procesaActa(psTerm    VARCHAR2,
                        psCrn     VARCHAR2,
                        pdFecRola DATE
                       );

  ---  OBTIENE FOLIO DEL ACTA
  FUNCTION obtieneFolioActa(psTermCode VARCHAR2, psCRN VARCHAR2) RETURN VARCHAR2 IS

  vsFolio SWRFOLI.SWRFOLI_TEXT%TYPE DEFAULT NULL;

  BEGIN
      SELECT SWRFOLI_TEXT
        INTO vsFolio
        FROM SWRFOLI
       WHERE SWRFOLI_TERM_CODE = psTermCode
         AND SWRFOLI_CRN       = psCRN;

      RETURN vsFolio;
  exception
      WHEN OTHERS THEN
           RETURN NULL;
  END obtieneFolioActa;

  -- OBTIENE EL PIDM DEL DIRECTRO DE LA ESCUELA
  FUNCTION pidmDire(psColl VARCHAR2,psTerm VARCHAR2) RETURN NUMBER IS

  vnPidmDire NUMBER := 0;

  csDIRE CONSTANT VARCHAR2(4) := 'DIRE';

  BEGIN
     SELECT SIRNIST_PIDM   into vnPidmDire
       FROM SIRNIST
      WHERE SIRNIST_COLL_CODE = psColl
        AND SIRNIST_TERM_CODE = psTerm
        AND SIRNIST_NIST_CODE = csDIRE;

      RETURN vnPidmDire;
  EXCEPTION
      WHEN OTHERS THEN
              RETURN vnPidmDire;
  END pidmDire;

  -- VALIDA SI EL CRN TIENE TODOS SUS ALUMNOS CALIFICADOS Y ROLADOS PARA IMPRIMIR EL ACTA
  FUNCTION actaRolada(psCRN  VARCHAR2,
                      psTerm VARCHAR2
                     ) RETURN BOOLEAN IS

  vnAlumsRo INTEGER     := 0;
  vnAlumnos INTEGER     := 0;

  cn1 CONSTANT NUMBER(1)   := 1;

  BEGIN
      -- CUANTOS ALUMNOS HAY
      SELECT COUNT(cn1)   INTO vnAlumnos
      FROM SFRSTCR
      WHERE EXISTS (SELECT STVRSTS_CODE
                    FROM STVRSTS
                    WHERE STVRSTS_GRADABLE_IND = csY
                    AND SFRSTCR_RSTS_CODE    = STVRSTS_CODE   )
      AND SFRSTCR_CRN       = psCRN
      AND SFRSTCR_TERM_CODE = psTerm;

         -- CUANTOS ALUMNOS ESTAN ROLADOS
      SELECT COUNT(cn1)    INTO vnAlumsRo
      FROM SFRSTCR
      WHERE EXISTS (SELECT STVRSTS_CODE
                    FROM STVRSTS
                    WHERE STVRSTS_GRADABLE_IND = csY
                    AND SFRSTCR_RSTS_CODE    = STVRSTS_CODE   )
      AND SFRSTCR_GRDE_DATE IS NULL
      AND SFRSTCR_CRN       = psCRN
      AND SFRSTCR_TERM_CODE = psTerm;

     RETURN (vnAlumnos = vnAlumsRo);

  END actaRolada;

  -- VALIDA SI EL CRN TIENE TODOS SUS ALUMNOS CALIFICADOS Y ROLADOS PARA IMPRIMIR EL ACTA
  FUNCTION actaSinCalif(psCRN  VARCHAR2,
                        psTerm VARCHAR2   ) RETURN NUMBER IS

  vnAlumsSn INTEGER     := 0;
  vnAlumnos INTEGER     := 0;
  vnCriteriosF INTEGER   := 0;
  vnCriteriosM INTEGER   := 0;
  vnDiferencia INTEGER  := 0;
  cn1   CONSTANT NUMBER(1)   := 1;
  csRE  CONSTANT VARCHAR2(2)   := 'RE';
  csRW  CONSTANT VARCHAR2(2)   := 'RW';

  BEGIN

  -- Cuenta los criterios de evaluación si solo se tiene un criterio de evaluación solo cuenta calificaciones finales y no parciales

      SELECT COUNT(cn1)
            INTO vnCriteriosF
      FROM SHRGCOM
      WHERE SHRGCOM_TERM_CODE = psTerm
      AND SHRGCOM_CRN = psCRN
      and SHRGCOM_INCL_IND = 'F';

      SELECT COUNT(cn1)
            INTO vnCriteriosM
      FROM SHRGCOM
      WHERE SHRGCOM_TERM_CODE = psTerm
      AND SHRGCOM_CRN = psCRN
      and SHRGCOM_INCL_IND = 'M';


      -- CUANTOS ALUMNOS HAY
      SELECT COUNT(cn1)
        INTO vnAlumnos
      FROM SFRSTCR
      /* md-01 start
       WHERE EXISTS (SELECT STVRSTS_CODE
                     FROM STVRSTS
                    WHERE STVRSTS_GRADABLE_IND = csY
                    AND SFRSTCR_RSTS_CODE    = STVRSTS_CODE
               )
     md-01 end */
      where SFRSTCR_RSTS_CODE IN (csRE, csRW)   --md-01
      AND SFRSTCR_CRN       = psCRN
      AND SFRSTCR_TERM_CODE = psTerm;

    IF vnCriteriosM > 0 THEN
         -- CUANTOS ALUMNOS NO ESTAN tienen calficacion final o parcial
      SELECT COUNT(cn1)
           INTO vnAlumsSn
      FROM SFRSTCR
           --/* md-01 start
       WHERE (
                 SFRSTCR_GRDE_CODE     IS NULL
              OR
                 SFRSTCR_GRDE_CODE_MID IS NULL
             )
        AND SFRSTCR_RSTS_CODE   IN (csRE, csRW)
       -- AND SFRSTCR_GRDE_DATE   IS NULL --cambio MRC 1412
        AND SFRSTCR_CRN         = psCRN
        AND SFRSTCR_TERM_CODE   = psTerm;
--INSERT INTO PASO (CAMPO1, CAMPO2) VALUES('ALUMNO', vnAlumnsSn);
    END IF;

   IF vnCriteriosF > 1  and vnCriteriosM = 0 THEN
         -- CUANTOS ALUMNOS NO ESTAN tienen calficacion final o parcial
      SELECT COUNT(cn1)
           INTO vnAlumsSn
      FROM SFRSTCR
           --/* md-01 start
       WHERE (
                 SFRSTCR_GRDE_CODE     IS NULL
             )
        AND SFRSTCR_RSTS_CODE   IN (csRE, csRW)
       -- AND SFRSTCR_GRDE_DATE   IS NULL --cambio MRC 1412
        AND SFRSTCR_CRN         = psCRN
        AND SFRSTCR_TERM_CODE   = psTerm;

    END IF;

--INSERT INTO PASO (CAMPO1, CAMPO2) VALUES('alumnos', vnAlumnos);
--INSERT INTO PASO (CAMPO1, CAMPO2) VALUES('alumnos', vnAlumsSn);
    -- cambia a P aquellos alumnos que su calificacion final es nula
    --md-01 IF vnAlumnos > vnAlumsSn AND vnAlumsSn > 0 THEN
      IF vnAlumnos >= vnAlumsSn AND vnAlumsSn <= 5 THEN
        vnDiferencia := 1; --ROLA CON P
      END IF;

     -- si todos los alumnos tienen calificacin final del curso
      --md-01 IF vnAlumnos > vnAlumsSn AND vnAlumsSn = 0 THEN
      IF vnAlumnos >= vnAlumsSn AND vnAlumsSn = 0 THEN
         vnDiferencia := 0;--SE ROLA
      --INSERT INTO PASO (CAMPO1, CAMPO2) VALUES('aqui', vnAlumsSn);
      END IF;
       -- si el numero de alumnos inscritos es menor o igual a 5 y mayor a 1 se rola con p si estan evaluados total -1 
       IF vnAlumnos <= 5 and vnAlumnos > 1 AND vnAlumsSn >=vnAlumnos-1 THEN
        vnDiferencia := 2;--no se rola 
      END IF;
      
      IF vnAlumnos =1 and vnAlumsSn =1 THEN
        vnDiferencia := 2; 
      END IF;

     -- IF vnAlumsSn = 0 THEN
       --  vnDiferencia := 0;--SE ROLA
        -- INSERT INTO PASO (CAMPO1, CAMPO2) VALUES('aca', vnAlumsSn);
      --END IF;

    -- solo se da cuando no se ha dado calificacion final a ningun alumno del curso
      IF vnAlumsSn >= 5 THEN
         vnDiferencia :=2; --NO SE ROLA
         --INSERT INTO PASO (CAMPO1, CAMPO2) VALUES('yyy', vnAlumsSn);
      END IF;

      --IF vnAlumnos <= 5 and vnAlumsSn > 1 then
       -- vnDiferencia :=2; --NO SE ROLA
        --INSERT INTO PASO (CAMPO1, CAMPO2) VALUES('zzzz', vnAlumsSn);
      --END IF;
    RETURN vnDiferencia;

  END actaSinCalif;


  procedure js is

  begin
       htp.p('
           var objFrmTerm = document.frmTerm;
           var objFrmGenr = document.frmGeneraActa;
           cargaSelectCall("kwactlg.catalogo", "psCatalogo=STVTRAC&psFiltro1="+vgnPidm, objFrmTerm.psTerm, "ALL", "buscaCrn()");
           ');

      --crnPorTerm
      htp.p(
            'function crnPorTerm(){
             vgsTerm = objFrmTerm.psTerm.options[objFrmTerm.psTerm.selectedIndex].value;
             buscaCrn();
             } //crnPorTerm
            ');

      --buscaCrn
      htp.p('
            function buscaCrn() {
            cargaSelectCall("kwactlg.catalogo", "psCatalogo=SSBCRNN&psFiltro1=" + vgsTerm + "&psFiltro2="+vgnPidm, objFrmTerm.psCrnn, "ALL", "inicializaValores()");
            } //buscaCrn
           ');

      --inicializaValores
      htp.p(
            'function inicializaValores(){
            objFrmTerm.psTerm.value = vgsTerm;
            objFrmTerm.psCrnn.value = vgsCrnn;

            objFrmTerm.psCrnn.focus();

            if(vgsTerm != "" && vgsCrnn != ""){
               generaActa();
            } else {
               //la función es llama de la pagina "kwatime.js"
              closeWindowTime();
            }
            } //inicializaValores
            ');

      --generaActa
      htp.p(
            'function generaActa() {
            vgsTerm = objFrmTerm.psTerm.options[objFrmTerm.psTerm.selectedIndex].value;
            vgsCrnn = objFrmTerm.psCrnn.options[objFrmTerm.psCrnn.selectedIndex].value;

            objFrmGenr.psTerm.value = vgsTerm;
            objFrmGenr.psCrnn.value = vgsCrnn;

            if(vgsTerm != "" && vgsCrnn != ""){
              //la función es llama de la pagina "kwatime.js"
              iniciaVentana();

              //md-02
              objFrmTerm.psImprimir.disabled = true;

              objFrmGenr.submit();
            }
           } //generaActa
           ');
  end js;

  --inicio de la pagina
  PROCEDURE  inicioPagina IS

  BEGIN
      htp.p('<html><head><title>Acta de calificaci&oacute;n final</title>');
      -- la aplicaci;n no se guarda en el cache de la maquina
         PK_ObjHTML.P_NoCache;

      htp.p('<style type="text/css"><!--');
      htp.p('  br.brNuevaPag   {page-break-before:always}');
      htp.p(' --></style>');

      --c;digo css
      PK_ObjHTML.P_CssTabs;

      htp.p('<script language="JavaScript"><!--');
      htp.p('function fImprimeReporte() {
              window.focus()
              print();
              }
      ');

      htp.p('//--></script>
      </head><body bgcolor="#ffffff" class="bodyCeroR"  ><br/>
      ');
      htp.p('<script language="javascript" src="kwacnls.js"></script> <br/>');
  END inicioPagina;

  --Genera el acta de calificaciones
  PROCEDURE actaDeCalificaciones IS

  BEGIN

      IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;

      -- devuelve el periodo seleccionado en el sistema de webTailor
      --vgsTerm := TWBKWBIS.F_GetParam(global_pidm,'TERM');

      -- devuelve el crn seleccionado en el sistema de webTailor
      --vgsCrnn := twbkwbis.F_GetParam(global_pidm,'CRN');

      bwckfrmt.p_open_doc('kwaacta.actaDeCalificaciones');

      htp.p('<script language="javascript" src="kwacnls.js"></script>');
      consulta;

      twbkwbis.p_closeDoc;

  END actaDeCalificaciones;

  --EL PROCEDIMIENTO GENERA LOS FRAIMS DE LA APLICACIÓN
  PROCEDURE consulta IS

  BEGIN
      htp.p('
      <form name="frmTerm">
      <table border="1" cellpadding="2" cellspacing="1" width="100%" bordercolor="#ffffff" bgcolor="#ffffff">
             <tr><td width="10%" class="delabel">Periodo:</td>
                 <td width="30%" bgcolor="#efefef">
                     <select name="psTerm" id="psTerm" style="width:100%" onChange="crnPorTerm();"><option value=""></option>
                     </select>
                     </td>
                    <td width="60%" rowspan="3">
                     </td>
                 </td>
                 </tr>
             <tr><td class="delabel">CRN:</td>
                    <td bgcolor="#efefef">
                           <select name="psCrnn" id="psCrnn" style="width:100%" onChange="fDisabled();"><option value=""></option>
                           </select>
                     </td>
                 </tr>
             <tr><td></td>
                       <td align="center">
                     <input type="button" name="psgeneraActa" id="psgeneraActa" tabindex="2" style="width:80%" onClick="generaActa();" value="Genera Acta"  DISABLED/>
                     </td>
                 <td></td>
                       </tr>

             <tr><td></td>
                       <td align="center">
                     <input type="button" name="psImprimir" id="psImprimir" tabindex="2" style="width:80%" onClick="parent.fraCrit03.fImprimeReporte();" value="Oprima para imprimir el acta" DISABLED />
                     </td>
                 <td></td>
                       </tr>
         </table>
      </form>

      <form name="frmGeneraActa" action="kwaacta.generaActa" target="fraCrit03" method="post">
         <input type="hidden" name="psTerm" />
         <input type="hidden" name="psCrnn" />
         </form>
      <br/>
      <iframe src="aboutBlank" name="fraCrit03" frameborder="0" scrolling="YES"  width="100%" height="600px" >
      </iframe>
      <br/><br/><br/><br/>

      <script language="javascript" type="text/javascript">
      <!--
      var vgnPidm = ' ||global_pidm||';
      var vgsTerm = "'||vgsTerm    ||'";
      var vgsCrnn = "'||vgsCrnn    ||'";

            function fDisabled() {
           objFrmTerm.psgeneraActa.disabled = false;
      }

      -->
      </script>

      <script language="javascript" src="kwaslct.js"></script>
      <script language="javascript" src="kwatime.js?psMensaje=Se está generando el Acta de calificación final."></script>
      <script language="javascript" src="kwaacta.js"></script>
      ');

  END consulta;


  -- GENERA EL ACTA DE CALIFICACIONES
  PROCEDURE generaActa(psTerm VARCHAR2,
                                   psCrnn VARCHAR2
                      ) IS

  vsMensaje     VARCHAR(100)   := NULL;
  vsError       VARCHAR2(9000) := NULL;
  vnError       NUMBER         := 0;

  cdSysDate CONSTANT DATE := TRUNC(SYSDATE);

  BEGIN
     IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;

      -- *Antes de generar el acta y rolar las calificaciones a "HA"
      --  las calificaciones en null se les asigna la calificación "P"
     IF actaSinCalif (psCrnn, psTerm) = 2 THEN
       vsMensaje := 'No puede cerrar el acta, tiene 5 ó más notas en blanco';
       vsError := 1;
     END IF;

     IF  actaSinCalif (psCrnn, psTerm) = 1 THEN
       gradeP(psTerm, psCrnn);
     END IF;



      IF  vsMensaje IS NULL THEN
           FOR regAlu IN cuAlumnos(psTerm, psCrnn) LOOP
              vnRows := vnRows  + 1;

              tabAlum(vnRows).rPidm   := regAlu.idemPm;
              tabAlum(vnRows).rId     := regAlu.idenId;
              tabAlum(vnRows).rNombre := regAlu.idenNm;
              tabAlum(vnRows).rCalif  := regAlu.gradeC;
         END LOOP;

      IF actaRolada(psCrnn, psTerm) THEN
         -- rolar acta
         BEGIN
             SHKROLS.P_DO_GRADEROLL(psTerm,psCRNn,USER,'1','1','O','','','','');
         EXCEPTION
             WHEN OTHERS THEN
                  vsError   := SUBSTR(SQLERRM,1,2000) ;
                  vnError   := SQLCODE;
                  vsMensaje := 'Favor de comunicarse a servicios escolares.';

                  ROLLBACK;

                  UPDATE SWRFOLI
                     SET SWRFOLI_ERROR       = vnError,
                         SWRFOLI_DESCRIPCION = vsError
                   WHERE SWRFOLI_TERM_CODE = psTerm
                     AND SWRFOLI_CRN       = psCRNn;

                  COMMIT;
         END;
      END IF;
ELSE
    inicioPagina;
  htp.p(
          '<p><font size="5" color="#FF0000">Ocurrieron errores al intentar generar el acta:</font></p>
          <table width="100%" border="1" cellpadding="2" cellspacing="0" align="center">
                 <tr><th width="100%" class="thTitulo" valign="bottom" align="left" '||vsEstilo||'>
                         '||vsMensaje||'
                         </th>
                     </tr>
          </table>

          </body></html>
          ');
      RETURN;

     END IF;

         -- SI NO HUBO ERRORES SE GENREA EL ACTA
      IF vnError = 0 THEN
         vnTotHojas := TRUNC(vnRows /vnRegsxHoja);

        IF vnTotHojas = 0 THEN
           vnTotHojas := 1;
        END IF;

        IF MOD(vnRows , vnRegsxHoja) > 0 AND vnRows > vnRegsxHoja THEN
           vnTotHojas :=  vnTotHojas +1;
        END IF;
      END IF;

      --inicio de la pagina
      inicioPagina;

      IF vsMensaje IS NOT NULL THEN
          htp.p(
          '<p><font size="5" color="#FF0000">Ocurrieron errores al intentar generar el acta:</font></p>
          <table width="100%" border="1" cellpadding="2" cellspacing="0" align="center">
                 <tr><th width="100%" class="thTitulo" valign="bottom" align="left" '||vsEstilo||'>
                         '||vsMensaje||'
                         </th>
                     </tr>
          </table>

          </body></html>
          ');

          RETURN;
      -- md-02 start
      else
          htp.p(
          '
          <table width="100%" border="1" cellpadding="2" cellspacing="0" align="center">
                 <tr><th width="100%" class="thTitulo" valign="bottom" align="left" '||vsEstilo||'>
                         '||vsMensaje||'
                         </th>
                     </tr>
          </table>

          <script language="javascript" type="text/javascript">
             function f(){

             parent.frmTerm.psImprimir.disabled = false;

              // frmTerm.psgeneraActa.disabled = true;
             }

             f();

          </script>

          </body></html>
          ');
      -- md-02 end
      END IF;


      procesaActa(psTerm , psCrnn, cdSysDate);

      htp.p(
      '<br><br>
      <script language="javascript" type="text/javascript">
      <!--
      parent.closeWindowTime();
      -->
      </script>
      </body></html>
      ');
   --END IF;
  END generaActa;

  --procesaActa
  PROCEDURE procesaActa(psTerm    VARCHAR2,
                        psCrn     VARCHAR2,
                        pdFecRola DATE
                       ) IS

  vsPidmProf SIRASGN.sirasgn_pidm%TYPE      := NULL; -- NOMBRE DEL CRN
  vsCollCode STVCOLL.STVCOLL_CODE%TYPE      := NULL; -- CLAVE DE LA FACULTAD
  vsCollDesc STVCOLL.STVCOLL_DESC%TYPE      := NULL; -- NOMBRE DE LA FACULTAD
  vsTitulo   SCBCRSE.SCBCRSE_TITLE%TYPE     := NULL; -- Nombre de la materia
  vsSeccion  SSBSECT.SSBSECT_SEQ_NUMB%TYPE  := NULL; -- seccion
  vsSubj           SSBSECT.SSBSECT_SUBJ_CODE%TYPE := NULL; -- subject
  vsCurso          SSBSECT.SSBSECT_CRSE_NUMB%TYPE := NULL; -- curso
  vsTipo           SSBSECT.SSBSECT_GMOD_CODE%TYPE := NULL; -- tipo
  vsDescTipo STVGMOD.STVGMOD_DESC%TYPE      := NULL; -- descrpcion del tipo
  vnRenCorte INTEGER                        := 0;
  vsColor    VARCHAR(8)                     := '';

  vsColorBco   CONSTANT VARCHAR(8)   := '#FFFFFF';
  vsColorGris  CONSTANT VARCHAR(8)   := '#EEEEEE';

  --obtien datos de encabezado del reporte
  procedure datosEncabezado is

  begin
      select nvl(ssbovrr_coll_code,a.scbcrse_coll_code),
             sc.stvcoll_desc,
             a.scbcrse_title,
             sirasgn_pidm,
             ssbsect_subj_code,
             ssbsect_crse_numb,
             ssbsect_seq_numb,
             ssbsect_gmod_code
        into vsCollCode,
             vsCollDesc,
             vsTitulo,
             vsPidmProf,
             vsSubj,
             vsCurso,
             vsSeccion,
             vsTipo
        from scbcrse a,
             ssbsect ss,
             stvcoll sc,
             sirasgn,
             ssbovrr
       where sc.stvcoll_code      = nvl(ssbovrr_coll_code, a.scbcrse_coll_code)
         and a.scbcrse_subj_code  = ss.ssbsect_subj_code
         and a.scbcrse_crse_numb  = ss.ssbsect_crse_numb
         and a.scbcrse_eff_term   = (select max(sc.scbcrse_eff_term)
                                       from scbcrse sc
                                      where sc.scbcrse_eff_term <= ss.ssbsect_term_code
                                        and sc.scbcrse_subj_code = ss.ssbsect_subj_code
                                        and sc.scbcrse_crse_numb = ss.ssbsect_crse_numb
                                    )
         and ss.ssbsect_crn       = psCRN
         and ss.ssbsect_term_code = psTerm
         and sirasgn_term_code    = ss.ssbsect_term_code
         and sirasgn_crn          = ss.ssbsect_crn
         and ss.ssbsect_term_code = ssbovrr_term_code(+)
         and ss.ssbsect_crn       = ssbovrr_crn(+)
         and sirasgn_primary_ind  = csY;

      select decode(vsTipo,csN,csOrdinario,pk_catalogo.grademode(vsTipo))
        into vsDescTipo
        from dual;

  end datosEncabezado;

  --ENCABEZADO DEL REPORTE
  PROCEDURE encabezadoReporte IS

  BEGIN

      htp.p('<table width="80%" border="1" cellpadding="2" cellspacing="0" align="center">
      <tr class="trTabSepara">');
      htp.p(' <td width="40%" rowspan="6" align="center" valign="top" '||vsEstilo||'><img src="/imagenes/logo_uft.jpg" width="170" height="70"  border="0"></td>');

      htp.p('<td class="tdFont8" width="03%" rowspan="14" '||vsEstilo||'></td>
      <td colspan="3" '||vsEstilo||'><table width="100%" border="0" cellpadding="0" cellspacing="0" >
      <tr><td class="tdFont8" width="80%" align="left"><B>ACTA DE CALIFICACI&Oacute;N FINAL</B></td>
      <td class="tdFont8" width="20%" align="right">Hoja'||vnHoja||' de '||vnTotHojas||'</td></tr>
      </table></td></tr>
      <tr class="trTabSepara"><td class="tdFont8" colspan="3" height="08" '||vsEstilo||'></td></tr>');

      htp.p('<tr class="trTabSepara"><td class="tdFont8" width="57%" colspan="3" >TIPO: '||vsDescTipo||'&nbsp;&nbsp;&nbsp;PERIODO: '||pk_Catalogo.periodo(psTerm)||'</td></tr>
      <tr class="trTabSepara"><td class="tdFont8" colspan="3" height="08" '||vsEstilo||'></td></tr>
      <tr class="trTabSepara"><td class="tdFont8" colspan="3">ESCUELA O DEPARTAMENTO RESPONSABLE: '||vsCollDesc||'</td></tr>
      <tr class="trTabSepara"><td class="tdFont8" colspan="3" height="13" '||vsEstilo||'></td></tr>
      <tr class="trTabSepara">
      <td class="tdFont8" >FOLIO: '||obtieneFolioActa(psTerm, psCRN )||'</td>
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
      <td class="tdFont8" style="border-bottom:none;" valign="top" align="left" width="200">DIRECTOR : '||pk_catalogo.nombre(pidmDire(vsCollCode, psTerm))||'</td></tr>
      <tr class="trTabSepara">
      <td class="tdFont7" style="border-top:none;" align="center" height="21">FIRMA</td>
      <td class="tdFont7" style="border-top:none;" align="center">FIRMA</td>
      <td class="tdFont7" '||vsEstilo||'></td>
      <td class="tdFont7" style="border-top:none;" align="center">FIRMA</td> </tr>
      </table><br/>');
      --- ENCABEZADO DE LA LISTA DE ALUMNOS
      htp.p('<table width="80%" border="1" cellpadding="2" cellspacing="0" align="center">');
      HTP.P('<tr class="trTabSepara">
      <td class="tdFont8" width="05%" bgcolor="#CCCCCC" align="center"><b>No.</b></td>
      <td class="tdFont8" width="20%" bgcolor="#CCCCCC" align="center"><b>Expediente</b></td>
      <td class="tdFont8" width="35%" bgcolor="#CCCCCC" align="center"><b>Nombre</b></td>
      <td class="tdFont8" width="25%" bgcolor="#CCCCCC" align="center"><b>Programa</b></td>
      <td class="tdFont8" width="15%" bgcolor="#CCCCCC" align="center"><b>Calificaci&oacute;n Final</b></td></tr>');
  END encabezadoReporte;

  --pie del reporte
  procedure pieActa is

  begin
      if vnRenglon = vnRows then
         htp.p('<tr class="trTabSepara">
         <td colspan="5" align="center" class="tdFont7" '||vsEstilo||'>**********NADA V&Aacute;LIDO DESPU&Eacute;S DE ESTA L&Iacute;NEA**********</td></tr>');
      end if;

      htp.p('</table>');
      htp.p('<table width="50%" border="0" cellpadding="0" cellspacing="0" align="center">');
      htp.p('<tr class="trTabSepara" >
      <td class="tdFont8" width="45%" align="center" height="120" valign="bottom">__________________________</td>
      <td class="tdFont8" width="10%"></td>
      <td class="tdFont8" width="45%" align="center" valign="bottom">__________________________</td></tr>
      ');

      htp.p('<tr class="trTabSepara">
      <td class="tdFont7" width="45%" align="center">Sello de la escuela o departamento</td>
      <td class="tdFont7" width="10%"></td>
      <td class="tdFont7" width="45%" align="center">Sello de Administraci&oacute;n Escolar</td></tr>
      ');

      htp.p('</table>');
  end pieActa;

  BEGIN
      --obtien datos de encabezado del reporte
      datosEncabezado;

      --Informacion encabezado
      encabezadoReporte;

      vnRenglon  := 0;
      vnRenCorte := 0;

      ------------- CUERPO DEL REPORTE
      FOR vnC IN 1..vnRows  LOOP
          vnRenglon  := vnRenglon  + 1;
          vnRenCorte := vnRenCorte + 1;

          IF MOD(vnRenglon,2) = 0 THEN
             vsColor :=  vsColorGris;
          ELSE
             vsColor :=  vsColorBco;
          END IF;

          htp.p(
          '<tr class="trTabSepara" bgcolor="' ||vsColor                                  ||'">
                <td class="tdFont8" align="center">'||vnRenglon                                ||'</td>
                <td class="tdFont8" align="center">'||tabAlum(vnC).rId                         ||'</td>
                <td class="tdFont8" align="left">'  ||tabAlum(vnC).rNombre                     ||'</td>
                <td class="tdFont8" align="center">'||F_GET_PROGRAMA(tabAlum(vnC).rPidm,psTerm)||'</td>
                <td class="tdFont8" align="center">'||tabAlum(vnC).rCalif                      ||'</td></tr>'
          );

                IF vnRenCorte = vnRegsxHoja THEN
                   pieActa; ------------ PIE DEL DOCUMENTO - FIRMAS DEL ACTA

                   IF vnRows > vnRenglon THEN
                      htp.p('<br class="brNuevaPag"/>');
                      vnHoja := vnHoja +1 ;

                      encabezadoReporte;
                   END IF;

             --vnRenCorte := 0;
                END IF;
      END LOOP;

      ------------ PIE DEL DOCUMENTO - FIRMAS DEL ACTA
      IF (vnRegsxHoja -vnRenCorte)  <  vnRegsxHoja THEN
           pieActa;
      END if;

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P('ERROR EN P_PROCESA_ACTA '||SQLERRM);
  END procesaActa;


  --REIMPRESION DE ACTAS VIA BANNER
  PROCEDURE imprimeActa(psReclDesc VARCHAR2) IS

  vdFecRola  DATE        := NULL;
  vsTerm     VARCHAR2(6) := NULL;
  vsCol      VARCHAR2(6) := NULL;
  vsCrnI     VARCHAR2(6) := NULL;
  vsCrnF     VARCHAR2(6) := NULL;
  viRows     INTEGER     := 0;
  viTRows    INTEGER     := 0;
  viTOTAL    INTEGER     := 0;
  vbRollGrde BOOLEAN     := FALSE;

  csZZ CONSTANT VARCHAR2(2) := 'ZZ';

  CURSOR cuCRN(psTerm VARCHAR2,
               psEscu VARCHAR2,
               psCRNI VARCHAR2 DEFAULT NULL,
               psCRNF VARCHAR2 DEFAULT NULL
              ) is
         SELECT SSBSECT_CRN       AS CRN,
                SCBCRSE_COLL_CODE AS Col
           FROM SCBCRSE A,
                SSBSECT SS
         WHERE A.SCBCRSE_SUBJ_CODE  = SS.SSBSECT_SUBJ_CODE
           AND A.SCBCRSE_CRSE_NUMB  = SS.SSBSECT_CRSE_NUMB
           AND A.SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                         FROM SCBCRSE SC
                                        WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                          AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                          AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB
                                      )
            AND EXISTS (SELECT NULL
                          FROM SFRSTCR
                         WHERE SFRSTCR_TERM_CODE  = SSBSECT_TERM_CODE
                           AND SFRSTCR_CRN        = SSBSECT_CRN
                           AND SFRSTCR_RSTS_CODE IN (SELECT STVRSTS_CODE
                                                     FROM STVRSTS
                                                     WHERE STVRSTS_GRADABLE_IND = csY )
                      )
            AND EXISTS (SELECT NULL
                          FROM SIRASGN
                         WHERE SIRASGN_TERM_CODE   = SSBSECT_TERM_CODE
                           AND SIRASGN_CRN         = SSBSECT_CRN
                           AND SIRASGN_PRIMARY_IND = csY  )
           AND (
                (SS.SSBSECT_CRN BETWEEN psCRNI AND psCRNF)
                OR
                 psCRNI||psCRNF IS NULL
                )
           AND (A.SCBCRSE_COLL_CODE = psEscu OR psEscu = csZZ)
           AND SS.SSBSECT_TERM_CODE = psTerm
          ORDER BY CRN;

       CURSOR cuTOT(psTerm VARCHAR2,
               psEscu VARCHAR2,
               psCRNI VARCHAR2 DEFAULT NULL,
               psCRNF VARCHAR2 DEFAULT NULL
              ) is
         SELECT count(*) as total_registros
           FROM SCBCRSE A,
                SSBSECT SS
          WHERE A.SCBCRSE_SUBJ_CODE  = SS.SSBSECT_SUBJ_CODE
            AND A.SCBCRSE_CRSE_NUMB  = SS.SSBSECT_CRSE_NUMB
            AND A.SCBCRSE_EFF_TERM   = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                          FROM SCBCRSE SC
                                         WHERE SC.SCBCRSE_EFF_TERM <= SS.SSBSECT_TERM_CODE
                                           AND SC.SCBCRSE_SUBJ_CODE = SS.SSBSECT_SUBJ_CODE
                                           AND SC.SCBCRSE_CRSE_NUMB = SS.SSBSECT_CRSE_NUMB  )
            AND EXISTS (SELECT NULL
                          FROM SFRSTCR
                         WHERE SFRSTCR_TERM_CODE  = SSBSECT_TERM_CODE
                           AND SFRSTCR_CRN        = SSBSECT_CRN
                           AND SFRSTCR_RSTS_CODE IN (SELECT STVRSTS_CODE
                                                     FROM STVRSTS
                                                     WHERE STVRSTS_GRADABLE_IND = csY  )
                       )
           AND EXISTS (SELECT NULL
                         FROM SIRASGN
                        WHERE SIRASGN_TERM_CODE   = SSBSECT_TERM_CODE
                          AND SIRASGN_CRN         = SSBSECT_CRN
                          AND SIRASGN_PRIMARY_IND = csY   )
           AND (
                   (SS.SSBSECT_CRN BETWEEN psCRNI AND psCRNF)
                OR
                   psCRNI||psCRNF IS NULL
                )
           AND (A.SCBCRSE_COLL_CODE = psEscu OR psEscu = csZZ)
           AND SS.SSBSECT_TERM_CODE = psTerm;

  BEGIN
     vsTerm := pk_objHtml.getValueCookie('psPerio');
     vsCol  := pk_objHtml.getValueCookie('psEscu');
     vsCrnI := pk_objHtml.getValueCookie('psTCrnI');
     vsCrnF := pk_objHtml.getValueCookie('psTCrnF');

     inicioPagina;
     FOR regTOT IN cuTOT(vsTerm,vsCol, vsCrnI, vsCrnF) LOOP
         viTOTAL:=regTOT.total_registros;
     END LOOP;

     FOR regCRN IN cuCRN(vsTerm,vsCol, vsCrnI, vsCrnF) LOOP
         viTRows := viTRows +1;
         vbRollGrde := actaRolada(regCRN.crn ,vsTerm);

         IF vbRollGrde THEN
            gradeP(vsTerm, regCRN.crn);

            SHKROLS.P_DO_GRADEROLL(vsTerm,regCRN.crn,USER,'1','1','O','','','','');
         END IF;

         vbRollGrde := actaRolada(regCRN.crn ,vsTerm);

         IF NOT vbRollGrde THEN
            viRows := viRows + 1;

           FOR regAlu IN cuAlumnos(vsTerm, regCRN.crn) LOOP
               vnRows  := vnRows  + 1;

               tabAlum(vnRows).rPidm   := regAlu.idemPm;
               tabAlum(vnRows).rId     := regAlu.idenId;
               tabAlum(vnRows).rNombre := regAlu.idenNm;

               tabAlum(vnRows).rCalif  := regAlu.gradeC;
               vdFecRola               := regAlu.gradeD;
           END LOOP;

           vnTotHojas := TRUNC(vnRows /vnRegsxHoja);

           IF vnTotHojas = 0 THEN
              vnTotHojas := 1;
           END IF;

           IF MOD(vnRows , vnRegsxHoja) > 0 AND vnRows > vnRegsxHoja THEN
              vnTotHojas :=  vnTotHojas +1;
           END IF;

           procesaActa(vsTerm ,regCRN.crn, vdFecRola  );
           if viTRows < viTOTAL then
              htp.p('<br class="brNuevaPag"/>');
              tabAlum.DELETE();
              vnRows := 0;
              vnTotHojas := 0 ;
              vnHoja := 1;
           end if;
         END IF;

     END LOOP;

     IF viRows = 0 THEN
        htp.p('<center><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></center>');
     END IF;

EXCEPTION
        WHEN OTHERS THEN
            HTP.P(SQLERRM);

END imprimeActa;

END kwaacta;
/
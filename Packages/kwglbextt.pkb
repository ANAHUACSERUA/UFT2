CREATE OR REPLACE PACKAGE BODY BANINST1.KWGLBEXTT IS
/*
          Tarea: Registra una selección de población para ser usada en una ecuesta.
          Fecha: 11/02/2010
          Autor: GEPC
         Modulo: General

  MODIFICACION: 06/06/2013
                JMS
                Se adiciono parámetro de HOLD de la tabla: STVHLDD
                
modificacion   :  mod-01
descripcion    :  permitir que encueesta y num de ref sean nulos y aplicar al scope.
                  adicional n los valores de los parametros encuesta y num de ref 
                  se cambia a no requeridos.
                  -- adicional los sig 2 parametros se cambian a NO requeridos en la bd. 
                              and SWRRECL_NOMBRE_PAR = 'psNmRfE'
                              and SWRRECL_NOMBRE = 'PWRMTRE';

                              and  SWRRECL_NOMBRE = 'PWRMTRE'
                              AND SWRRECL_NOMBRE_PAR = 'psEncst'; 
autor          :  roman ruiz
dia            :  24-nov-2014

---------------------------------

modificacion   :  md-02
descripcion    :  se cambia a N  el release_indicator..  
autor          :  roman ruiz
dia            :  18-di-2014


*/

  --codigo javascript
  PROCEDURE JS IS

  BEGIN
      htp.p(
      '
      var objSelect = document.frmDatos.psEncuesta;
      var objHoldS  = document.frmDatos.psHold;
      var vgsAccion = "";
      ');

      --setValue
      htp.p(
      '
      function setValue(pnValue) {
        var vdTF    = false;
        var vsClass = "";

        vgsAccion = pnValue;

               if(pnValue == 0) {
                  vdTF = false;

                  document.frmDatos.psListaAlumnos.className = "bkg02ar";
                  document.frmDatos.psEncuesta.className     = "txtDisab";
                  document.frmDatos.psNmRfE.className        = "txtDisab";
                  document.frmDatos.psHold.className         = "txtDisab";
                  document.frmDatos.psBegDate.className      = "txtDisab";
                  document.frmDatos.psEndDate.className      = "txtDisab";
        } else if(pnValue == 1) {
                  vdTF = true;

                  document.frmDatos.psListaAlumnos.className = "txtDisab";
                  document.frmDatos.psEncuesta.className     = "";
                  document.frmDatos.psNmRfE.className        = "";
                  document.frmDatos.psHold.className         = "";
                  document.frmDatos.psBegDate.className      = "bkg02";
                  document.frmDatos.psEndDate.className      = "bkg02";
        }

        document.frmDatos.psListaAlumnos.disabled = vdTF;
        document.frmDatos.psEncuesta.disabled     = !vdTF;
        document.frmDatos.psNmRfE.disabled        = !vdTF;
        document.frmDatos.psHold.disabled         = !vdTF;
        document.frmDatos.psBegDate.disabled      = !vdTF;
        document.frmDatos.psEndDate.disabled      = !vdTF;

        document.frmDatos.psAccion.value = pnValue;

      } //setValue
      ');

      --validaFecha
      htp.p('function validaFecha(objFecha) {
      caja = objFecha.value;

      if (caja) {
      borrar = caja;

      if ((caja.substr(2,1) == "/") && (caja.substr(5,1) == "/") ) {
      for (i=0; i<10; i++) {
      if (((caja.substr(i,1)<"0") || (caja.substr(i,1)>"9")) && (i != 2) && (i != 5)) {
      borrar = "";
      break;
      }
      }

      if (borrar) {
      a = caja.substr(6,4);
      m = caja.substr(3,2);
      d = caja.substr(0,2);

      if ((a < 1900) || (a > 2050) || (m < 1) || (m > 12) || (d < 1) || (d > 31))
      borrar = "";
      else {
      if((a%4 != 0) && (m == 2) && (d > 28))
      borrar = ""; // Año no viciesto y es febrero y el dia es mayor a 28
      else {
      if ((((m == 4) || (m == 6) || (m == 9) || (m==11)) && (d>30)) || ((m==2) && (d>29)))
       borrar = "";
      }  // else
      } // fin else
      } // if (error)
      } // if ((caja.substr(2,1) == \"/\") && (caja.substr(5,1) == \"/\"))

      else
      borrar = "";

      if (borrar == "") {
      alert("La fecha que introdujo es incorrecta.");
      objFecha.value = "";
      objFecha.focus();
      return false;
      }
      } // if (caja)

      return false;
      } // validaFecha');

      ----fColorFondo
      htp.p('function fColorFondo(Objeto,psColor) {
      Objeto.className=psColor;
      }');

      --Guardar
      htp.p(
      'function f_Guardar() {
        var vbTF = false;

               if(vgsAccion == ""){
                  alert("Seleccione la actividad a realizar.");

        } else if(vgsAccion == "0") {
                  vbTF = seleccionPoblacion();

        } else if(vgsAccion == "1") {
                  vbTF = candadoEP();

        }

        if(vbTF) {
           iniciaVentana();

           document.frmDatos.submit();
        }


      } //f_Guardar'
      );

      --seleccionPoblacion()
      htp.p(
      'function seleccionPoblacion() {
        var vsAppli = document.frmDatos.psAppli.value;
        var vsSelec = document.frmDatos.psSelec.value;
        var vsCreat = document.frmDatos.psCreat.value;

        if(vsAppli == "") {
           alert("Introduzca la aplicación del la selección");
           document.frmDatos.psAppli.focus();

           return false;
        }

        if(vsSelec == "") {
           alert("Introduzca la descripción de la selección");
           document.frmDatos.psSelec.focus();

           return false;
        }

        if(vsCreat == "") {
           alert("Introduzca el usuario creador de la encuesta");
           document.frmDatos.psCreat.focus();

           return false;
        }

        iniciaVentana();

        return true;

      } //seleccionPoblacion'
      );

      --candadoEP
      htp.p(
      'function candadoEP() {
        var vsEncuesta = '||pk_objHTML.selectIndex('frmDatos','psEncuesta')||';
        var vsNumrefer = '||pk_objHTML.selectIndex('frmDatos','psNmRfE')||';
        var vsHold     = '||pk_objHTML.selectIndex('frmDatos','psHold')||';
        var vsDesde    = document.frmDatos.psBegDate.value;
        var vsHasta    = document.frmDatos.psEndDate.value;
        
        //md-01 se quito la validadción fisica para campo de encuesta y num ref
        
        if(vsHold == "") {
           alert("Seleccione un Hold");
           document.frmDatos.psHold.focus();

           return false;
        }

        if(vsDesde == "") {
           alert("Seleccione la fecha DESDE");
           document.frmDatos.psBegDate.focus();

           return false;
        }

        if(vsHasta == "") {
           alert("Seleccione la fecha HASTA");
           document.frmDatos.psEndDate.focus();

           return false;
        }

        iniciaVentana();

        return true;

      } //candadoEP
      ');

      --cancelaStatusTiempo
      htp.p('
      function cancelaStatusTiempo() {
        closeWindowTime();
      } //cancelaStatusTiempo
      ');

      --//CargaHold  JMSM 06/06/2013
      htp.p(
      'function CargaHold(){
           cargaSelectCall("kwactlg.catalogo", "psCatalogo=STVHLDD", objHoldS, "ALL", "cancelaStatusTiempo();");
      }//CargaHold
      ');

      --f_ChangeCode
      htp.p(
      'function f_ChangeCode(psValue) {
        var vsValue2 = "";
        var vsValue3 = "";
        var vsValue4 = "";

        iniciaVentana();

        var vsURL = "kwaObjPrm.returnValor?psReporte=PWRMTRE&psParametro1=psNmRfE&psParametro2=&psFiltro1="+psValue+"&psFiltro2="+vsValue2+"&psFiltro3="+vsValue3+"&psFiltro4="+vsValue4+"&psForma=frmDatos";

        document.getElementById("fraCondicion").src = vsURL;

      } //f_ChangeCode

      cargaSelectCall("kwactlg.catalogo", "psCatalogo=GVVGSRC", objSelect, "ALL", "CargaHold();");

      ');

  END JS;

  -- Se capturan los parametros para la selección de poblacion
  PROCEDURE CapturaAlumnos(psParametro VARCHAR2) IS

  csImagenes     CONSTANT VARCHAR2(60)  := '"menu","sali","save",';
  csAcciones     CONSTANT VARCHAR2(100) := 'pk_MenuAplicacion.p_MenuAplicacion,javascript:paginaSalir();,javascript:f_Guardar();,';
  csOpciones     CONSTANT VARCHAR2(60)  := '"Men&uacute;","Salir","Guardar",';
  vgsOnBlurFocuA CONSTANT VARCHAR2(200) := 'onBlur="fColorFondo(this,''bkg02ar'');" onFocus="fColorFondo(this,''bkg01ar'');"';

  BEGIN
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      kwatitl.Titulo(
      'Registrar una selección de población a una encuesta',
      csImagenes,
      csAcciones,
      csOpciones,
      psCancelMnu=>'A',
      psImgMovil=>NULL
      );

      htp.p('
      <style type="text/css">
      <!--
      //input.txtDisab    {background-color:#dddddd;}
      select.txtDisab   {background-color:#dddddd;}
      textarea.txtDisab {background-color:#dddddd;}
      -->
      </style>
      ');

      pk_objHTML.calendarioJavaScript;

      htp.p('
      <script language="javascript" src="kwatime.js?psMensaje=La p&aacute;gina se est&aacute; cargando.<br/>Espere un momento por favor..."></script>
      <script language="javascript" src="kwaslct.js"></script>

      <script type="text/javascript"><!--
      javascript:window.history.forward(1);
      -->
      </script>

      <table border="0" width="26%" cellpadding="0" cellspacing="0" bordercolor="#ffffff" bgcolor="#ffffff" align="center">
             <tr><td colspan="3">
                     <center>
                     <img src="/wtlgifs/web_required.gif" border="0" />&nbsp;<font size="3">valores requeridos</font>
                     </center>

                 </td>
             <tr><td colspan="3">&nbsp;</td></tR>
             <tr><td width="1%" rowspan="2"><br/><img src="/wtlgifs/web_required.gif" border="0" /></td>
                 <td width="5%" align="center" bgcolor="#efefef">
                     <input type="radio" name="rdAccion" class="chkA" onClick="setValue(''0'');" />
                     </td>
                 <td width="20%"  bgcolor="#efefef">Seleccion de poblacion</td>
                 </tr>
             <tr><td align="center"  bgcolor="#efefef">
                     <input type="radio" name="rdAccion" class="chkA" onClick="setValue(''1'');" />
                     </td>
                 <td bgcolor="#efefef">Candado</td>
              </tr>
      </table>
      <br/>

      <form name="frmDatos" target="_top" method="post" action="KWGLBEXTT.RegistroAlumnos">
      <table border="0" width="80%" height="270px" cellpadding="0" cellspacing="0" bordercolor="#ffffff" bgcolor="#ffffff" align="center">

      <tr><td width="40%" height="60%" bgcolor="#ffffff" valign="bottom">
              <table border="0" width="100%" cellpadding="2" cellspacing="1" bgcolor="#ffffff" bordercolor="#ffffff">
                     <tr><td colspan="3">
                         <b>Registrar una selección de población</b>

                         </td></tr>
                     <tr><td colspan="3">&nbsp;</td></tr>
                     <tr><td width="40%" class="delabel">Application</td>
                         <td width="1%"><img src="/wtlgifs/web_required.gif" border="0" /></td>
                         <td width="59%" bgcolor="#efefef">
                             <input type="text" name="psAppli" value="BANSTU_SAMPLE" onFocus="this.className=''bkg01'';" onBlur="this.className=''bkg02'';" />
                             </td>
                             </tr>
                     <tr><td class="delabel">Selection</td>
                         <td><img src="/wtlgifs/web_required.gif" border="0" /></td>
                         <td bgcolor="#efefef">
                             <input type="text" name="psSelec" onFocus="this.className=''bkg01'';" onBlur="this.className=''bkg02'';" />
                             </td>
                             </tr>
                     <tr><td class="delabel">Creator</td>
                         <td><img src="/wtlgifs/web_required.gif" border="0" /></td>
                         <td bgcolor="#efefef">
                             <input type="text" name="psCreat" value="'||PK_Login.vgsUSR||'" onFocus="this.className=''bkg01'';" onBlur="this.className=''bkg02'';" />
                             </td>
                     </tr>
                     <tr><td colspan="3"></td></tr>
                     <tr><td colspan="3"></td></tr>
                     </table>
               </td>
               <td width="5%">&nbsp;</td>
               <td width="35%" rowspan="6">
                     <table border="0" width="100%" cellpadding="2" cellspacing="1" bgcolor="#ffffff" bordercolor="#ffffff">
                     <tr><td colspan="3">
                         <b>Registrar candado (HOLD).</b>
                         </td></tr>

                     <tr><td colspan="3">&nbsp;</td></tr>
                     <tr><td width="40%" class="delabel">Encuesta</td>
                         <td></td>    
                         <td width="59%" bgcolor="#efefef">
                         <select name="psEncuesta" class="txtDisab" onChange="f_ChangeCode(this.value);" DISABLED><option value=""></option>
                         </select>
                     <tr><td class="delabel">Núm. Ref. Enc.</td>
                         <td></td>  
                         <td bgcolor="#efefef">
                         <select name="psNmRfE" id="psNmRfE" class="txtDisab" DISABLED><option value=""></option>
                         </select>
                         </td>
                         </tr>
                     <tr><td class="delabel">HOLD</td>
                         <td><img src="/wtlgifs/web_required.gif" border="0" /></td>
                         <td bgcolor="#efefef">
                         <select name="psHold" id="psHold" class="txtDisab" DISABLED><option value=""></option>
                         </select>
                         </td>
                         </tr>
                     <tr><td class="delabel">
                             Desde</th>
                         <td><img src="/wtlgifs/web_required.gif" border="0" /></td>
                         <td bgcolor="#efefef">
                         '||pk_objHTML.F_INPUT('CALENDARIO','psBegDate', psEvento=>'DISABLED', psClass=>'txtDisab', psFormCalendar=>'frmDatos')||'
                         </td></tr>
                     <tr><td class="delabel">
                             Hasta</th>
                         <td><img src="/wtlgifs/web_required.gif" border="0" /></td>
                         <td bgcolor="#efefef">
                         '||pk_objHTML.F_INPUT('CALENDARIO','psEndDate', psEvento=>'DISABLED', psClass=>'txtDisab', psFormCalendar=>'frmDatos')||'
                         </td></tr>
                     <tr><td colspan="3"><input type="hidden" name="psAccion" /></td></tr>


              </table>

              </td>

          </tr>
      <tr><td width="20%" height="20px" class="delabel">
              Introduzca la selecci&oacute;n de poblaci&oacute;n
              </td>
          <td></td>
          </tr>
      <tr><td height="250px" bgcolor="#efefef">
              <textarea name="psListaAlumnos" style="width:100%;height:100%" '||vgsOnBlurFocuA||' DISABLED class="txtDisab"></textarea>
                 </td>
          <td></td>
              </tr>

      </table>
      </form>


      <form name="frmSalir" method="post" target="_top">
      </form>

      <iframe name="fraCondicion" id="fraCondicion" src="aboutBlank" width="100%" height="0pt" frameborder="0" tabindex="-1">
      </iframe>

      <script language="javascript" src="KWGLBEXTT.js"></script>
      ');

      titulomovil.JavaScriptMovil;

      pk_objHTML.closed;

  END CapturaAlumnos;

  -- Se registran la selección de poblacion
  PROCEDURE RegistroAlumnos(psAppli        VARCHAR2 DEFAULT NULL,
                            psSelec        VARCHAR2 DEFAULT NULL,
                            psCreat        VARCHAR2 DEFAULT NULL,
                            psEncuesta     VARCHAR2 DEFAULT NULL,
                            psHold         VARCHAR2 DEFAULT NULL,
                            psNmRfE        VARCHAR2 DEFAULT NULL,
                            psBegDate      VARCHAR2 DEFAULT NULL,
                            psEndDate      VARCHAR2 DEFAULT NULL,
                            psAccion       VARCHAR2 DEFAULT NULL,
                            psListaAlumnos VARCHAR2 DEFAULT NULL
                           ) IS

  TYPE reg_Colum IS RECORD(rPidm SPRIDEN.SPRIDEN_PIDM%TYPE,
                           rIddd SPRIDEN.SPRIDEN_ID%TYPE,
                           rMesg VARCHAR2(10),
                           rEror VARCHAR2(4000)
                          );

  TYPE tablePidm IS TABLE OF reg_Colum INDEX BY BINARY_INTEGER;

  tabPidm  tablePidm;
  vsLista  VARCHAR2(32000) := psListaAlumnos;
  vsBkPon  VARCHAR2(10)    := NULL;
  vnRows   INTEGER         := 0;
  vnAlum   INTEGER         := NULL;
  vnInsert INTEGER         := 0;

  csDDMMYYY   CONSTANT VARCHAR2(10) := 'DD/MM/YYYY';
  csEP        CONSTANT VARCHAR2(2)  := psHold;
  csEPhold    CONSTANT VARCHAR2(7)  := psHold||'_HOLD';
  csP         CONSTANT VARCHAR2(1)  := 'P';
  csY         CONSTANT VARCHAR2(1)  := 'Y';
  csS         CONSTANT VARCHAR2(1)  := 'S';
  csN         CONSTANT VARCHAR2(1)  := 'N';
  csC         CONSTANT VARCHAR2(1)  := 'C';
  csEspP      CONSTANT VARCHAR2(4)  := ' (P)';
  csCampus    CONSTANT VARCHAR2(6)  := f_contexto();
  csKWGLBEXTT CONSTANT VARCHAR2(9)  := 'KWGLBEXTT';
  csImagenes  CONSTANT VARCHAR2(60)  := '"back",';
  csAcciones  CONSTANT VARCHAR2(100) := 'javascript:f_Regresar();,';
  csOpciones  CONSTANT VARCHAR2(60)  := '"Regresar",';
  csUser      CONSTANT VARCHAR2(32)  := USER;
  cdSysDate   CONSTANT DATE          := SYSDATE;

  --cuGlbslct
  CURSOR cuGlbslct IS
         SELECT GLBSLCT_APPLICATION Appli,
                GLBSLCT_SELECTION   Selec,
                GLBSLCT_CREATOR_ID  Creat
           FROM GLBSLCT
          WHERE GLBSLCT_APPLICATION = psAppli
            AND GLBSLCT_SELECTION   = psSelec
            AND GLBSLCT_CREATOR_ID  = psCreat;

  --generaSeleccion
  procedure generaSeleccion is

  begin
  
      IF    psAccion = '0' THEN
            -- Se obtienen los expedinetes de los alumnos
            WHILE INSTR(vsLista,CHR(13)||CHR(10)) > 0 LOOP
                  vnRows := vnRows + 1;

                  tabPidm(vnRows).rIddd := REPLACE(REPLACE(SUBSTR(vsLista, 1, INSTR(vsLista,CHR(13)||CHR(10)) - 1), CHR(13)),CHR(10));

                  vsLista := SUBSTR(vsLista, INSTR(vsLista,CHR(13)||CHR(10)) + 1);
            END LOOP;

            vnAlum := vnRows;

            vsBkPon := 'BK002';

            -- Se busca el pidn que le corresponde al expediente
            FOR vnI IN 1..vnRows LOOP
                tabPidm(vnI).rMesg := 'Yes';

                BEGIN
                    SELECT SPRIDEN_PIDM
                      INTO tabPidm(vnI).rPidm
                      FROM SPRIDEN
                     WHERE SPRIDEN_ID          = tabPidm(vnI).rIddd
                       AND SPRIDEN_CHANGE_IND IS NULL;
                EXCEPTION
                    WHEN OTHERS THEN
                         tabPidm(vnI).rMesg := 'No';
                END;
            END LOOP;

            vsBkPon := 'BK003';

            BEGIN          -- insertar selección PRUEBAHOLD
                INSERT INTO GLBSLCT
                 (GLBSLCT_APPLICATION, GLBSLCT_SELECTION, GLBSLCT_CREATOR_ID, GLBSLCT_DESC, GLBSLCT_LOCK_IND, GLBSLCT_ACTIVITY_DATE)
                VALUES
                 (psAppli,             psSelec,           psCreat,            psSelec,      csN,              cdSysDate);
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                     NULL;
            END;

            vsBkPon := 'BK004';

            --Es insertada la selección de población
            FOR vnI IN 1..vnRows LOOP
                BEGIN
                    INSERT INTO GLBEXTR
                    (GLBEXTR_APPLICATION, GLBEXTR_SELECTION, GLBEXTR_CREATOR_ID, GLBEXTR_USER_ID, GLBEXTR_KEY,        GLBEXTR_ACTIVITY_DATE, GLBEXTR_SYS_IND)
                    VALUES
                    (psAppli,             psSelec,           psCreat,            psCreat,         tabPidm(vnI).rPidm, cdSysDate,             csS);

                EXCEPTION
                    WHEN OTHERS THEN
                         tabPidm(vnI).rEror := SQLERRM;
                         vnAlum             := vnAlum - 1;
                END;
            END LOOP; 
      ELSIF psAccion = '1' THEN
            BEGIN            
            -- md-01 start
            
              if psEncuesta is null then   -- encuesta sin valor
              
                 INSERT INTO SPRHOLD (SPRHOLD_PIDM,                 SPRHOLD_HLDD_CODE,            SPRHOLD_USER,
                                      SPRHOLD_FROM_DATE,            SPRHOLD_TO_DATE,              SPRHOLD_RELEASE_IND,
                                      SPRHOLD_ACTIVITY_DATE,        SPRHOLD_REASON,               SPRHOLD_DATA_ORIGIN  )
                 select a.SGBSTDN_PIDM,     csEP,                         csUser,
                         TO_DATE(psBegDate,csDDMMYYY), TO_DATE(psEndDate,csDDMMYYY),  csN,    -- csY,   -- md-02
                             SYSDATE,         GLBEXTR_SELECTION||csEspP,    csKWGLBEXTT
                 from SGBSTDN a, GLBEXTR x 
                 where a.SGBSTDN_PIDM = x.GLBEXTR_KEY 
                 AND a.SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                 FROM SGBSTDN B
                                                 WHERE B.SGBSTDN_PIDM = a.SGBSTDN_PIDM  )
                 and  x.GLBEXTR_SELECTION = psSelec 
                 AND NOT EXISTS (SELECT NULL              -- que no hayan sido insertados previamente
                                 FROM SPRHOLD
                                 WHERE SPRHOLD_FROM_DATE = TO_DATE(psBegDate,csDDMMYYY)
                                 AND SPRHOLD_TO_DATE   =  TO_DATE(psEndDate,csDDMMYYY)
                                 AND SPRHOLD_HLDD_CODE = csEP
                                 AND SPRHOLD_PIDM      = a.SGBSTDN_PIDM ); 
              else
                 -- ecuesta tiene valor
                 if psNmRfE is null then 
                    
                    INSERT INTO SPRHOLD (SPRHOLD_PIDM,                 SPRHOLD_HLDD_CODE,            SPRHOLD_USER,
                                      SPRHOLD_FROM_DATE,            SPRHOLD_TO_DATE,              SPRHOLD_RELEASE_IND,
                                      SPRHOLD_ACTIVITY_DATE,        SPRHOLD_REASON,               SPRHOLD_DATA_ORIGIN  )
                    select a.SGBSTDN_PIDM,     csEP,                         csUser,
                           TO_DATE(psBegDate,csDDMMYYY), TO_DATE(psEndDate,csDDMMYYY),  csN,    -- csY,   -- md-02
                           SYSDATE,         GLBEXTR_SELECTION||csEspP,    csKWGLBEXTT
                    from SGBSTDN a, GLBEXTR x 
                    where a.SGBSTDN_PIDM = x.GLBEXTR_KEY 
                    AND a.SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                    FROM SGBSTDN B
                                                    WHERE B.SGBSTDN_PIDM = a.SGBSTDN_PIDM  )
                    and  x.GLBEXTR_SELECTION = psSelec 
                    AND NOT EXISTS (SELECT NULL              -- que no hayan sido insertados previamente
                                    FROM SPRHOLD
                                    WHERE SPRHOLD_FROM_DATE = TO_DATE(psBegDate,csDDMMYYY)
                                    AND SPRHOLD_TO_DATE   =  TO_DATE(psEndDate,csDDMMYYY)
                                    AND SPRHOLD_HLDD_CODE = csEP
                                    AND SPRHOLD_PIDM      = a.SGBSTDN_PIDM )
                    and exists ( select * 
                                 from GVRSRAS
                                 where GVRSRAS_SRN in (select GVRSRVY_SRN    
                                                       from GVRSRVY
                                                       where  GVRSRVY_GSRC_CODE = psEncuesta) -- encuesta
                                 and GVRSRAS_SPIDM =  a.SGBSTDN_PIDM 
                                 and GVRSRAS_STATUS_IND <> 'C'); 
                                 
                 else
                    --solo los de la ref
                    
                    INSERT INTO SPRHOLD (SPRHOLD_PIDM,                 SPRHOLD_HLDD_CODE,            SPRHOLD_USER,
                                      SPRHOLD_FROM_DATE,            SPRHOLD_TO_DATE,              SPRHOLD_RELEASE_IND,
                                      SPRHOLD_ACTIVITY_DATE,        SPRHOLD_REASON,               SPRHOLD_DATA_ORIGIN  )
                    select a.SGBSTDN_PIDM,     csEP,                         csUser,
                           TO_DATE(psBegDate,csDDMMYYY), TO_DATE(psEndDate,csDDMMYYY),  csN,    -- csY,   -- md-02
                           SYSDATE,         GLBEXTR_SELECTION||csEspP,    csKWGLBEXTT
                    from SGBSTDN a, GLBEXTR x 
                    where a.SGBSTDN_PIDM = x.GLBEXTR_KEY 
                    AND a.SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                    FROM SGBSTDN B
                                                    WHERE B.SGBSTDN_PIDM = a.SGBSTDN_PIDM  )
                    and  x.GLBEXTR_SELECTION = psSelec 
                    AND NOT EXISTS (SELECT NULL              -- que no hayan sido insertados previamente
                                    FROM SPRHOLD
                                    WHERE SPRHOLD_FROM_DATE = TO_DATE(psBegDate,csDDMMYYY)
                                    AND SPRHOLD_TO_DATE   =  TO_DATE(psEndDate,csDDMMYYY)
                                    AND SPRHOLD_HLDD_CODE = csEP
                                    AND SPRHOLD_PIDM      = a.SGBSTDN_PIDM )
                    and exists ( select * 
                                 from GVRSRAS
                                 where GVRSRAS_SRN = psNmRfE
                                 and GVRSRAS_SPIDM =  a.SGBSTDN_PIDM 
                                 and GVRSRAS_STATUS_IND <> 'C');                                    
                    
                 end if;
              end if;
            
                 /*
                 INSERT INTO SPRHOLD (SPRHOLD_PIDM,                 SPRHOLD_HLDD_CODE,            SPRHOLD_USER,
                                      SPRHOLD_FROM_DATE,            SPRHOLD_TO_DATE,              SPRHOLD_RELEASE_IND,
                                      SPRHOLD_ACTIVITY_DATE,        SPRHOLD_REASON,               SPRHOLD_DATA_ORIGIN  )
                 SELECT
                  GLBEXTR_KEY,                  csEP,                         csUser,
                  TO_DATE(psBegDate,csDDMMYYY), TO_DATE(psEndDate,csDDMMYYY), csY,
                  SYSDATE,                      GLBEXTR_SELECTION||csEspP,    csKWGLBEXTT
                    FROM SGBSTDN A,
                         GLBEXTR,
                         (SELECT GVRSRAS_STATUS_IND Stats,
                                 GVRSRAS_SPIDM      Piddm
                            FROM GVRSRAS
                           WHERE GVRSRAS_SRN = psNmRfE
                         ) GVRSRA
                   WHERE A.SGBSTDN_TERM_CODE_EFF                  = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                                       FROM SGBSTDN B
                                                                      WHERE B.SGBSTDN_PIDM = A.SGBSTDN_PIDM  )
                     AND A.SGBSTDN_PIDM                           = GLBEXTR_KEY
                     AND (GLBEXTR_APPLICATION,GLBEXTR_SELECTION) IN (SELECT GVRSRVY_PS_APPLICATION_ID,GVRSRVY_PS_SELECTION_ID
                                                                       FROM GVRSRVY
                                                                      WHERE GVRSRVY_SRN = psNmRfE  )
                     AND A.SGBSTDN_PIDM                           = GVRSRA.PIDDM(+)
                     AND NVL(GVRSRA.Stats,csP)                   <> csC
                     AND A.SGBSTDN_CAMP_CODE                      = csCampus
                     AND NOT EXISTS (SELECT NULL
                                       FROM SPRHOLD
                                      WHERE SPRHOLD_FROM_DATE = TO_DATE(psBegDate,csDDMMYYY)
                                        AND SPRHOLD_TO_DATE   = TO_DATE(psEndDate,csDDMMYYY)
                                        AND SPRHOLD_HLDD_CODE = csEP
                                        AND SPRHOLD_PIDM      = A.SGBSTDN_PIDM  );
                   */                     
                                        
                --md-01 end
                
                vnInsert := SQL%ROWCOuNT;
                
            END;
      END IF;

      COMMIT;

  end generaSeleccion;

  BEGIN
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      vsBkPon := 'BK001';

      generaSeleccion;

      --GLAEXTR
      --GVASRVY
      --GLISLCT

      IF    psAccion = '0' THEN
            kwatitl.Titulo(
            'Registrar una selección de población a una ecuesta',
            csImagenes,
            csAcciones,
            csOpciones,
            psCancelMnu=>'A',
            psImgMovil=>NULL
            );
      ELSIF psAccion = '1' THEN
            kwatitl.Titulo(
            'Registrar candado "'||csEP||'"',
            csImagenes,
            csAcciones,
            csOpciones,
            psCancelMnu=>'A',
            psImgMovil=>NULL
            );
      END IF;


      htp.p('
      <script type="text/javascript">
      <!--
      javascript:window.history.forward(1);

      function f_Regresar() {
      document.frmRegresar.submit();
      } //f_Regresar

      -->
      </script>

      <br/>
      <table border="1" width="100%" bordercolor="#cccccc">
      ');

      IF    psAccion = '0' THEN
            FOR regPha IN cuGlbslct LOOP
                htp.p('
                <tr>
                <th bgcolor="#efefef" align="right">Application</th><td colspan="2">'||regPha.Appli||'</td></tr>
                <th bgcolor="#efefef" align="right">Selection  </th><td colspan="2">'||regPha.Selec||'</td></tr>
                <th bgcolor="#efefef" align="right">Creator    </th><td colspan="2">'||regPha.Creat||'</td>
                </tr>');
            END LOOP;

            htp.p('
            <tr bgcolor="#efefef" >
                <th width="10%">Expediente</th>
                <th width="10%">Existe    </th>
                <th width="80%">Error     </th>
                </tr>'
            );

            FOR vnI IN 1..vnRows LOOP
                htp.p(
                '<tr>'||
                '<td>'||tabPidm(vnI).rIddd||'</td>'||
                '<td>'||tabPidm(vnI).rMesg||'</td>'||
                '<td>'||tabPidm(vnI).rEror||'</td>'||
                '</tr>'
                );
            END LOOP;

            htp.p('
            <tr bgcolor="#efefef" >
            <th colspan="3">'||vnAlum||' alumnos registrados de '||vnRows||'</th>
            </tr>
            </table>
            ');
      ELSIF psAccion = '1' THEN
            htp.p('
            <tr bgcolor="#efefef" >
            <th colspan="3">'||vnInsert||' alumnos registrados con el candado "'||csEP||'"</th>
            </tr>
            </table>
            ');
      END IF;

      htp.p('

      <br/>
      <form name="frmRegresar" method="post" target="_top" action="KWGLBEXTT.CapturaAlumnos">
      <input type="hidden" name="psParametro" value="'||TO_CHAR(cdSYSDATE,'DD/MM/YYYY HH24:MI:SS')||'">
      </form>
      ');

      titulomovil.JavaScriptMovil;

      pk_objHTML.closed;

  EXCEPTION
     WHEN OTHERS THEN
          htp.p(vsBkPon||'<br/>'||SQLERRM||'<br/>');
  END RegistroAlumnos;


  END KWGLBEXTT;
/

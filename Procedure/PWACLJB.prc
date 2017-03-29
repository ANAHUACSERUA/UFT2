CREATE OR REPLACE PROCEDURE BANINST1.pwacljb(psAccion VARCHAR2 DEFAULT NULL,
                                            psProces VARCHAR2 DEFAULT NULL,
                                            psAudJob VARCHAR2 DEFAULT NULL,
                                            psTermCd VARCHAR2 DEFAULT NULL,
                                            psCampCd VARCHAR2 DEFAULT NULL,
                                            psCasosY VARCHAR2 DEFAULT NULL,
                                            psCasosN VARCHAR2 DEFAULT NULL,
                                            psFecha  VARCHAR2 DEFAULT NULL
                                           ) IS

  csSysdate  CONSTANT DATE          := SYSDATE;
  csTysdate  CONSTANT DATE          := TRUNC(SYSDATE);
  csY        CONSTANT VARCHAR2(1)   := 'Y';
  csN        CONSTANT VARCHAR2(1)   := 'N';
  csTiempo   CONSTANT VARCHAR2(13)  := 'HH24:MI:SS am';
  csUser     CONSTANT VARCHAR2(32)  := USER;
  csImagenes CONSTANT VARCHAR2(100) := '"limpiar","save","buscar","ejecutar",';
  csAcciones CONSTANT VARCHAR2(200) := 'javascript:Limpia();,javascript:setCambios();,javascript:verificaJob();,javascript:configuraTerm();,';
  csOpciones CONSTANT VARCHAR2(100) := '"Limpiar","Guardar","Auditoria","Configura periodo",';


  --ejecución de procesos
  --cuProcesos
  cursor cuProcesos is
         select swbproc_code     as procCode,
                swbproc_exec_ind as procExec
           from swbproc;

  --pagina para procesos de JOB
  --inicioJob
  procedure inicioJob is

  begin
      htp.p(
      '<table border="0" width="100%" cellpadding="2" cellspacing="2">'||
      '<tr>'||
      '<td width="100%" colspan="2" class="delabel">Habilitar auditoria de la ejecución del "JOB":</td>'||
      '</tr>'||
       '<tr>'||
           '<td width="10%" bgcolor="#efefef" align="center">'||
               '<input type="checkbox" name="chkAudiJ" id="chkAudiJ" class="chkA" />'||
               '</td>'||
           '<td width="90%" bgcolor="#efefef" colspan="2">Habilita auditoria.'||
               '</td>'||
           '</tr>'||
      '</table>'
      );
  end inicioJob;

  --registra usuario ALL
  --setUserALL
--  procedure setUserALL(psIndOper varchar2
--                      ) is
--
--  begin
--      if csUser = 'BANSECR' then
--         return;
--      end if;
--
--      if    upper(psIndOper) = 'I' then
--            begin
--                 --la instrucción convierte al usuario como "ALL"
--                 --puede ver a todas las VPDI
--                 insert into sysvpdi
--                 (sysvpdi_userid,
--                  sysvpdi_activity_date,
--                  sysvpdi_user
--                 )
--                 values
--                 (csUser,
--                  csSysdate,
--                  csUser
--                 );
--            exception
--                when dup_val_on_index then
--                     null;
--            end;
--
--      elsif upper(psindoper) = 'D' then
--            --se asigna la VPDI por default
--            g$_vpdi_security.g$_vpdi_set_home_context('LOGON');
--
--            delete sysvpdi
--             where sysvpdi_userid = csUser;
--      end if;
--
--  end setUserALL;


  --pagina principal de parametros
  --parametros
  procedure parametros is

  begin
      htp.p(
      '
      <style type="text/css">
      <!--
      div.DIVtitulo {width:100%;
                    height:17pt;
                    overflow-x:hidden;
                    overflow-y:scroll;
                    margin:0px;
                    padding:0px;
                   }
      div.DIVdetalle {width:100%;
                    height:100pt;
                    overflow-x:hidden;
                    overflow-y:scroll;
                    margin:0px;
                    padding:0px;
                   }
      -->
      </style>
      ');

      htp.p(
      '<script language="javascript" src="kwatime.js?psMensaje=La pagina se est&aacute; cargando.<br/>Espera un momento por favor..."></script>
      <script language="javascript" src="kwaslct.js"></script>
      <script language="javascript" src="kwacalendario.js"></script>

      <form name="frmCupo" id="frmCupo" onSubmit="return false;">'||
      '<table border="1" cellpadding="5" cellspacing="5" width="60%" align="center">'||
      '<tr><td style="border:solid 2.0pt #FCB656;">'
      );

      --pagina para procesos de JOB
      inicioJob();

      htp.p(
      '<div id="divJob"></div>
      </td></tr></table>'||
      '</form>

      <form name="frmChang" id="frmChang"  action="PWACLJB" target="fraCupo">
      <input type="hidden" name="psAccion" id="psAccion" value="CHANGE" />
      <input type="hidden" name="psProces" id="psProces" value="" />
      <input type="hidden" name="psAudJob" id="psAudJob" value="" />
      </form>

      <form name="frmHabilita" id="frmHabilita"  action="PWACLJB" target="fraCupo">
      <input type="hidden" name="psAccion" id="psAccion" value="HABILITA" />
      <input type="hidden" name="psTermCd" id="psTermCd" value="" />
      <input type="hidden" name="psCampCd" id="psCampCd" value="" />
      <input type="hidden" name="psCasosY" id="psCasosY" value="" />
      <input type="hidden" name="psCasosN" id="psCasosN" value="" />
      </form>

      <br>
      <form name="frmElimina" id="frmElimina" action="PWACLJB" target="fraCupo">
      <input type="hidden" name="psAccion" id="psAccion" value="ELIMINA" />
      <table border="0" cellpadding="3" cellspacing="3" width="50%" align="center" >
      <tr><td width="20%" class="delabel">
      Elimina bitacora:<img src="/wtlgifs/web_required.gif" border="0" /></td>
      <td width="20%" bgcolor="#efefef">
      '||
      PK_ObjHTML.F_INPUT('CALENDARIO', 'psFecha',5,psFormCalendar=>'frmElimina')||

     '</td>
     <td width="10%" bgcolor="#efefef">
     <input type="button" name="btnElimina" id="btnElimina" value="Elimina Bitacora" class="btnAA" onClick="eliminaBitacora(document.frmElimina.psFecha);" />
     </td></tr></table>
      </form>
      <iframe name="fraCupo" id="fraCupo" hspace="0" vspace="0" frameborder="0" width="0%" height="0pt" tabindex="-1" src="aboutBlank" scrolling="no">
      </iframe>

      '
      );
  end parametros;

  --cambio de procesos para control de cupos
  --setChange
  procedure setChange is

  vsExecJob varchar2(1) := 'N';
  vsExceCol varchar2(1) := 'N';
  vsAudiJob varchar2(1) := 'N';
  vsAudiCol varchar2(1) := 'N';

  csProces constant varchar(1) := psProces;
  csAudJob constant varchar(1) := psAudJob;
  csJOB    constant varchar(3) := 'JOB';
  csCOLA   constant varchar(4) := 'COLA';
  csAUDC   constant varchar(4) := 'AUDC';
  csAJOB   constant varchar(4) := 'AJOB';

  begin
      --CONFIGURACIÓN DE AUDITORIA DE JOB
      if csAudJob = csY then
         update swbproc
            set swbproc_exec_ind = csY
          where swbproc_code = csAJOB;
      else
         update swbproc
            set swbproc_exec_ind = csN
          where swbproc_code = csAJOB;
      end if;

      update swbproc
         set swbproc_exec_ind = csY
       where swbproc_code = csJOB;

      commit;

      for regPrc in cuProcesos loop
             if regPrc.procCode = 'JOB'  then --ejecución de job  Y o N
                vsExecJob := regPrc.procExec;

          elsif regPrc.procCode = 'AJOB' then --auditoria de cola Y o N
                vsAudiJob := regPrc.procExec;

          end if;
      end loop;

      htp.p(
      '<script type="text/javascript">
      <!--
      var vgsExecJob = "'||vsExecJob||'";
      var vgsExceCol = "'||vsExceCol||'";
      var vgsAudiJob = "'||vsAudiJob||'";
      var vgsAudiCol = "'||vsAudiCol||'";
      '
      );

      --inicializaPagina
      htp.p(
      'function inicializaPagina() {

         parent.desHasbilitaObjetos(false);

         parent.inicializaVariable(vgsExecJob, vgsExceCol, vgsAudiJob, vgsAudiCol);

         parent.registraValores();

         setTimeout("parent.procesoTerminado()",2000);
      } //inicializaPagina
      ');


      htp.p(
      '
      inicializaPagina();
      -->
      </script>
      '
      );
  end setChange;

  --código java script
  --js
  procedure js is

  vsExecJob varchar2(1) := 'N';
  vsExceCol varchar2(1) := 'N';
  vsAudiJob varchar2(1) := 'N';
  vsAudiCol varchar2(1) := 'N';

  begin
      for regPrc in cuProcesos loop
             if regPrc.procCode = 'JOB'  then --ejecución de job  Y o N
                vsExecJob := regPrc.procExec;

          elsif regPrc.procCode = 'AJOB' then --auditoria de cola Y o N
                vsAudiJob := regPrc.procExec;

          end if;
      end loop;

      htp.p(
      '<script type="text/javascript">
      <!--
      var vsExecJob = "";
      var vsExceCol = "";
      var vsAudiJob = "";
      var vsAudiCol = "";
      var vsTermCod = "";
      var vsCampCod = "";
      var objFrmHab = document.frmHabilita;
      var objFrmChg = document.frmChang;
      var objFrmCup = document.frmCupo;
      var objChkJob = document.frmCupo.chkAudiJ;
      var objBtnJob = document.frmCupo.btnJob;
      var objProc   = document.frmChang.psProces;
      var objAudJ   = document.frmChang.psAudJob;
      var objAccion = document.frmHabilita.psAccion;
      var objTermCd = document.frmHabilita.psTermCd;
      var objCampCd = document.frmHabilita.psCampCd;
      var objCasosY = document.frmHabilita.psCasosY;
      var objCasosN = document.frmHabilita.psCasosN;
      var vgnHora   = 0;
      var vgnMint   = 0;
      var vgnSegn   = 0;
      '
      );

      --setTiempo
      htp.p(
      'function setTiempo() {
         vgnHora = document.frmCupo.psHora.value;
         vgnMint = document.frmCupo.psMint.value;
         vgnSegn = document.frmCupo.psSegd.value;

         vgnHora = parseInt(vgnHora) + 0;
         vgnMint = parseInt(vgnMint) + 0;
         vgnSegn = parseInt(vgnSegn) + 0;

         showTime();
      } //setTiempo
      '
      );

      --showTime
      htp.p(
      'function showTime(){
         var vsHora    = "";
         var vsMint    = "";
         var vsSegn    = "";
         var vsMensaje = "";

         vgnSegn--;

         if(vgnSegn <= -1) {
            if(vgnMint>0){
               vgnSegn = 59;
               vgnMint--;
            } else {
               vgnSegn = 0;
            }
         }

         if(vgnMint <= -1) {
            if(vgnHora>0) {
               vgnMint = 59;
               vgnHora--;
            } else {
               vgnMint = 0;
            }
         }

         if(vgnHora < 10 ) { vsHora =  "0" + vgnHora; } else {vsHora =  vgnHora;}
         if(vgnMint < 10 ) { vsMint =  "0" + vgnMint; } else {vsMint =  vgnMint;}
         if(vgnSegn < 10 ) { vsSegn =  "0" + vgnSegn; } else {vsSegn =  vgnSegn;}

         vsMensaje = "(Tiempo restante: <font color=''#0000aa''><b>" + vsHora + ":" + vsMint + ":" + vsSegn + "<\/b><\/font>)";

         if(vgnMint == 0 && vgnSegn < 10){
            vsMensaje = "(Tiempo restante: <font color=''#aa0000''><b>" + vsHora + ":" + vsMint + ":" + vsSegn + "<\/b><\/font>)";
         }

         try{
             document.getElementById("divTiempo").innerHTML = vsMensaje;
         } catch(e){return;}

         if(vsHora == "00" && vsMint == "00" && vsSegn == "00"){
            setTimeout("setEjecutando()",1000);
            return;
         }

         setTimeout("showTime()",1000);
      } //showTime'
      );

      --setEjecutando
      htp.p(
      'function setEjecutando() {
          document.getElementById("divTiempo").innerHTML = "<img src=''\/imagenes\/large_loading.gif'' width=''15pt''>";

          setTimeout("verificaJob()",8000)
      } //setEjecutando
      ');

      --La función valida si la fecha fue introducida correctamente.
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
      } // FUNCION');

      --fColorFondo
      htp.p(
      'function fColorFondo(Objeto,psColor) {
         Objeto.className=psColor;
      } //fColorFondo
      ');

      --inicializaVariable
      htp.p(
      'function inicializaVariable(psExecJob, psExceCol, psAudiJob, psAudiCol) {
         vsExecJob = psExecJob;
         vsExceCol = psExceCol;
         vsAudiJob = psAudiJob;
         vsAudiCol = psAudiCol;
      } //inicializaVariable
      ');

      --registraValores
      htp.p(
      'function registraValores() {

        if(vsAudiJob == "Y") {
           objChkJob.checked = true;
        }


      } //registraValores
      '
      );

      --inicializaParametros
      htp.p(
      'function inicializaParametros() {
        inicializaVariable("'||vsExecJob||'","'||vsExceCol||'","'||vsAudiJob||'","'||vsAudiCol||'");

        registraValores();

        setTimeout("procesoTerminado()",2000);
      } //inicializaParametros
      '
      );

      -- procesoTerminado
      htp.p(
      'function procesoTerminado(){

         //la funcion esta definida en "kwatime.js"
         closeWindowTime();

         try {
              setTiempo();
         } catch(e){}

       }//procesoTerminado
      ');

      --setCambios
      htp.p(
      'function setCambios() {
         objProc.value = "";
         objAudJ.value = "N";

         if(objChkJob.checked){
            objAudJ.value = "Y";
         }

         alert("A efectuado cambios en la configuración.");

         if( !confirm("Desea continuar?") ){
            objFrmChg.reset();
            objFrmCup.reset();
            objFrmHab.reset();

            registraValores();
            return;
         }

         document.getElementById("fontMsgTIme").innerHTML = "Cambiando la configuraci&oacute;n.<br>Espera un momento por favor...";

         //la funcion esta definida en "kwatime.js"
         iniciaVentana();

         objChkJob.checked = false;

         desHasbilitaObjetos(true);

         setTimeout("objFrmChg.submit()",2000);

      } //setCambios
      '
      );

      --desHasbilitaObjetos
      htp.p(
      'function desHasbilitaObjetos(psTF) {
         objChkJob.disabled = psTF;
         objBtnJob.disabled = psTF;
      } //desHasbilitaObjetos
      '
      );

      --Limpia
      htp.p(
      'function Limpia() {
         objFrmChg.reset();
         objFrmCup.reset();
         objFrmHab.reset();

         registraValores();

         vsTermCod = "";
         document.getElementById("divJOB").innerHTML = "";
      }//Limpia
      '
      );

      --verificaJob
      htp.p(
      'function verificaJob() {

         document.getElementById("fontMsgTIme").innerHTML = "Verificando la ejecución del JOB.<br>Espera un momento por favor...";

         //la funcion esta definida en "kwatime.js"
         iniciaVentana();

         getMensaje("PWACLJB","psAccion=VERIFICAJOB", "divJob");

      }//verificaJob
      '
      );

      --configuraTerm
      htp.p(
      'function configuraTerm() {

         document.getElementById("fontMsgTIme").innerHTML = "Buscando periodos a configurar.<br>Espera un momento por favor...";

         //la funcion esta definida en "kwatime.js"
         iniciaVentana();

         getMensaje("PWACLJB","psAccion=CONFIGURATERM", "divJob");

      }//configuraTerm
      '
      );

      --periodoHabilitados
      htp.p(
      'function periodoHabilitados(psValue) {
         vsTermCod = psValue;

         document.getElementById("fontMsgTIme").innerHTML = "Buscando configuraci&oacute;n.<br>Espera un momento por favor...";

         //la funcion esta definida en "kwatime.js"
         iniciaVentana();

         getMensaje("PWACLJB","psAccion=CONFIGURADOS&psTermCd="+psValue, "divTerms");

      }//periodoHabilitados
      '
      );

      --periodoCampHabilitados
      htp.p(
      'function periodoCampHabilitados(psValue) {
         vsCampCod = psValue;

         document.getElementById("fontMsgTIme").innerHTML = "Buscando configuraci&oacute;n.<br>Espera un momento por favor...";

         //la funcion esta definida en "kwatime.js"
         iniciaVentana();

         getMensaje("PWACLJB","psAccion=CONFIGURADOS&psTermCd="+vsTermCod+"&psCampCd="+psValue, "divTerms");

      }//periodoCampHabilitados
      '
      );

      --selectALL()
      htp.p(
      'function selectALL(pbChecked) {
        var vsValor  = document.frmCupo.txtObj.value;
        var vnIndice = 0;
        var objChk   = null;
        var arrObjs  = new Array();

        while(vsValor.indexOf(",") > 0) {
              arrObjs[vnIndice] = vsValor.substring(0, vsValor.indexOf(","));
              vsValor           = vsValor.substring(vsValor.indexOf(",")+1, vsValor.length);

              vnIndice++;
        }

        for(var vnI=0; vnI<arrObjs.length; vnI++){
            objChk = eval("objFrmCup." + arrObjs[vnI]);

            if (pbChecked == false) {
                objChk.checked = false;
            } else {
                objChk.checked = true;
            }

            objChk = null;
        }

      } //selectALL()
      '
      );

      --guardaTerms()
      htp.p(
      'function guardaTerms() {
        var vsValor   = document.frmCupo.txtObj.value;
        var vnIndice  = 0;
        var objChk    = null;
        var vsObjectY = "";
        var vsObjectN = "";
        var arrObjs   = new Array();

        while(vsValor.indexOf(",") > 0) {
              arrObjs[vnIndice] = vsValor.substring(0, vsValor.indexOf(","));
              vsValor           = vsValor.substring(vsValor.indexOf(",")+1, vsValor.length);

              vnIndice++;
        }

        for(var vnI=0; vnI<arrObjs.length; vnI++){
            objChk = eval("objFrmCup." + arrObjs[vnI]);

                   if (objChk.checked == true) {
                       vsObjectY = vsObjectY + objChk.name + ",";
            } else if (objChk.checked == false) {
                       vsObjectN = vsObjectN + objChk.name + ",";
            }

            objChk = null;
        }

        objAccion.value = "HABILITA";
        objCasosY.value = vsObjectY;
        objCasosN.value = vsObjectN;
        objTermCd.value = vsTermCod;
        objCampCd.value = vsCampCod;

        alert("A efectuado cambios en la configuración.");

         if( !confirm("Desea continuar?") ){
            objFrmHab.reset();

            return;
         }

        document.getElementById("fontMsgTIme").innerHTML = "Habilita configuraci&oacute;n para calculo de cupos de inscripci&oacute;n.<br>Espera un momento por favor...";

        //la funcion esta definida en "kwatime.js"
        iniciaVentana();

        objFrmCup.slcTerm.disabled   = true;
        objFrmCup.slcCamp.disabled   = true;
        objFrmCup.chkALL.disabled    = true;
        objFrmCup.btnGuarda.disabled = true;
        objFrmCup.btnNewCas.disabled = true;

        for(var vnI=0; vnI<arrObjs.length; vnI++){
            objChk = eval("objFrmCup." + arrObjs[vnI]);

            objChk.disabled = true;

            objChk = null;
        }

        setTimeout("objFrmHab.submit()",2000);

      } //guardaTerms()
      '
      );

      --setPeriodo()
      htp.p(
      'function setPeriodo() {

        objAccion.value = "NEWTERM";
        objTermCd.value = vsTermCod;
        objCampCd.value = vsCampCod;

        alert("Se agregaran nuevos valores para el calculo de cupos de inscripción.");

         if( !confirm("Desea continuar?") ){
            objFrmHab.reset();

            return;
         }

        document.getElementById("fontMsgTIme").innerHTML = "Nueva configuraci&oacute;n para calculo de cupos de inscripci&oacute;n.<br>Espera un momento por favor...";

        //la funcion esta definida en "kwatime.js"
        iniciaVentana();

        objFrmCup.slcTerm.disabled   = true;
        objFrmCup.slcCamp.disabled   = true;
        objFrmCup.btnGuarda.disabled = true;

        setTimeout("objFrmHab.submit()",2000);

      } //setPeriodo()
      '
      );

      --eliminaBitacora
      htp.p(
      'function eliminaBitacora(objFecha) {
         var vsFecha = objFecha.value;

         if(vsFecha == "") {
            alert("Seleccione la fecha a elimina.");
            objFecha.focus();
            return;
         }

         alert("Se eliminara la bitacora de inscripción de cupos.");

         if( !confirm("Desea continuar?") ){
            document.frmElimina.reset();

            return;
         }

         document.frmElimina.submit();

      } //eliminaBitacora
      '
      );

      --deleteTerm
      htp.p(
      'function deleteTerm() {

         alert("Se eliminara la configuración del periodo.");

         if( !confirm("Desea continuar?") ){
            document.frmElimina.reset();

            return;
         }

         objAccion.value = "ELIMINATERM";
         objTermCd.value = vsTermCod;
         objCampCd.value = vsCampCod;

         document.getElementById("fontMsgTIme").innerHTML = "Eliminando el periodo "+vsTermCod+" de la configuración.<br>Espera un momento por favor...";

        //la funcion esta definida en "kwatime.js"
        iniciaVentana();

        objFrmCup.slcTerm.disabled   = true;
        objFrmCup.slcCamp.disabled   = true;
        objFrmCup.btnGuarda.disabled = true;
        objFrmCup.btnNewCas.disabled = true;
        objFrmCup.btnDelete.disabled = true;

        setTimeout("objFrmHab.submit()",2000);

      } //deleteTerm
      '
      );

      htp.p(
      '-->
      </script>
      '
      );
  end js;

  --verifica la ejecución de la cola
  --verificaJob
  procedure verificaJob is

  vnInscritos number       := 0;
  vnRegistros number       := 0;
  vnNumEjec   number(5)    := 0;
  vdCupoDate  date         := null;
  vdStcrDate  date         := null;
  vsHora      varchar2(2)  := null;
  vsMint      varchar2(2)  := null;
  vsSegd      varchar2(2)  := null;
  vsHoraActu  varchar2(13) := null;
  vsHoraNext  varchar2(13) := null;
  vsTimeRest  varchar2(13) := null;
  vsInterval  varchar2(31) := null;
  vsCupoFech  varchar2(31) := null;
  vsStcrFech  varchar2(31) := null;
  vsTiempoUl  varchar2(31) := null;
  vsTimpUltI  varchar2(31) := null;

  csGui     constant varchar2(1)  := '-';
  csT       constant varchar2(1)  := 'T';
  csRE      constant varchar2(2)  := 'RE';
  csRW      constant varchar2(2)  := 'RW';
  csPWJENRL constant varchar2(7)  := 'PWJENRL';
  csFecha   constant varchar2(31) := 'DD/MM/YYYY HH24:MI:SS am';

  --intervalo de ejecución
  --cuProcesos
  cursor cuProcesos is
         select to_char(swrcupo_begin,csTiempo)     as cupoTime,
                fwainter(swrcupo_begin,swrcupo_end) as cupoIntr
           from swrcupo
          where trunc(swrcupo_activity_date) = csTysdate
            and swrcupo_proceso              = csPWJENRL
          order by swrcupo_seqn_numb;

  begin
      begin
          select to_char(next_date,csTiempo),
                 to_char(csSysdate,csTiempo),
                 fwainter(csSysdate,next_date, csT)
            into vsHoraNext,
                 vsHoraActu,
                 vsTimeRest
            from dba_jobs
           where what like 'PWJENRL%';
      exception
          when others then
               null;
      end;

      vsHora := substr(vsTimeRest, 1, 2);
      vsMint := substr(vsTimeRest, 4, 2);
      vsSegd := substr(vsTimeRest, 7, 2);

      begin
          select fwainter(swrcupo_begin,swrcupo_end),
                 to_char(swrcupo_activity_date,csTiempo)
            into vsTiempoUl,
                 vsCupoFech
            from swrcupo
           where swrcupo_seqn_numb            = (select max(b.swrcupo_seqn_numb)
                                                   from swrcupo b
                                                  where trunc(swrcupo_activity_date) = csTysdate
                                                    and swrcupo_proceso              = csPWJENRL
                                                )
             and trunc(swrcupo_activity_date) = csTysdate
             and swrcupo_proceso              = csPWJENRL;
      exception
          when others then
               null;
      end;

      --registra al uaurio como ALL
      --setUserALL('I');

      select count(distinct inscritos),
             count(registros),
             to_char(max(fecha),csTiempo)
        into vnInscritos,
             vnRegistros,
             vsTimpUltI
        from (
              select decode(sfrstcr_rsts_code,csRE,sfrstcr_pidm,csRW,sfrstcr_pidm,null) as inscritos,
                     sfrstcr_pidm                                                       as registros,
                     sfrstcr_activity_date                                              as fecha
                from sfrstcr
               where trunc(sfrstcr_activity_date) = csTysdate
             ) sfrstc;

      --quita al usuario como ALL
    --  setUserALL('D');

      htp.p(
      '<br>'||
      '<table border="1" cellpadding="2" cellspacing="2" width="100%" style="border:solid 1.0pt #ffffff;">'||
      '<td colspan="2" class="delabel">Auditoria del "JOB" que realliza el cálculo de cupos de inscripción:</td>'||
      '<tr>'||
           '<td width="60%" style="border:solid 1.0pt #ffffff;" align="right" bgcolor="#efefef"><b>Fecha de hoy: </b></td>'||
           '<td width="40%" style="border:solid 1.0pt #efefef;">&nbsp;'||to_char(csSysdate, 'DD - MON - YYYY')||'</td>'||
          '</tr>'||

       '<tr>'||
            '<td style="border:solid 1.0pt #ffffff;" align="right" bgcolor="#efefef"><b>Intervalo de ejecuci&oacute;n del "JOB": </b></td>'||
            '<td style="border:solid 1.0pt #efefef;">&nbsp;'||fwainter(csSysdate,(csSysdate+1/680), 'T')||'</td>'||
           '</tr>'||
       '<tr><td colspan="2" style="border:solid 1.0pt #ffffff;" bgcolor="#ffffff">&nbsp;</td></tr>'||
       '<tr>'||
           '<td style="border:solid 1.0pt #ffffff;" align="right" bgcolor="#efefef"><b>Hora actual: </b></td>'||
           '<td style="border:solid 1.0pt #efefef;">&nbsp;'||vsHoraActu||'</td>'||
          '</tr>'||

       '<tr>'||
           '<td style="border:solid 1.0pt #ffffff;"  align="right" bgcolor="#efefef"><b>Proxima ejecuci&oacute;n del "JOB": </b></td>'||
           '<td style="border:solid 1.0pt #efefef;" >'||
           '<table border="0" cellpadding="0" cellspacing="0" width="100%">'||
           '<tr>'||
           '<td width="30%">&nbsp;'||vsHoraNext||'</td>'||
           '<td width="70%" id="divTiempo">(Tiempo restante: '||vsTimeRest||')</td>'||
           '</tr>'||
           '</table>'||
           '</td>'||
           '</tr>'||
      '<tr><td colspan="2" style="border:solid 1.0pt #ffffff;" bgcolor="#ffffff">&nbsp;</td></tr>'||
      '<tr>'||
           '<td style="border:solid 1.0pt #ffffff;" align="right" bgcolor="#efefef"><b>Hora de ultima ejecución del "JOB": </b></td>'||
           '<td style="border:solid 1.0pt #efefef;" colspan="2">&nbsp;'||vsCupoFech||'</td>'||
          '</tr>'||

      '<tr>'||
           '<td style="border:solid 1.0pt #ffffff;" align="right" bgcolor="#efefef"><b>Tiempo de duración de la ultima ejecuci&oacute;n del "JOB": </b></td>'||
           '<td style="border:solid 1.0pt #efefef;">&nbsp;'||vsTiempoUl||'</td>'||
          '</tr>'||
      '<tr><td colspan="2" style="border:solid 1.0pt #ffffff;" bgcolor="#ffffff">&nbsp;</td></tr>'||
      '<tr>'||
           '<td style="border:solid 1.0pt #ffffff;" align="right" bgcolor="#efefef"><b>Hora de ultima inscripción: </b></td>'||
           '<td style="border:solid 1.0pt #efefef;">&nbsp;'||vsTimpUltI||'</td>'||
          '</tr>'||

      '<tr>'||
           '<td style="border:solid 1.0pt #ffffff;" align="right" bgcolor="#efefef"><b>Número de inscritos: </b></td>'||
           '<td style="border:solid 1.0pt #efefef;">&nbsp;'||to_char(vnInscritos,'999,999,999')||'</td>'||
          '</tr>'||
      '<tr>'||
           '<td style="border:solid 1.0pt #ffffff;" align="right" bgcolor="#efefef"><b>Número de registros: </b></td>'||
           '<td style="border:solid 1.0pt #efefef;">&nbsp;'||to_char(vnRegistros,'999,999,999')||'</td>'||
          '</tr>'||
      '<tr><td colspan="2" style="border:solid 1.0pt #ffffff;" bgcolor="#ffffff">&nbsp;</td></tr></table>'
      );

      for regPro in cuProcesos loop
          if vnNumEjec = 0 then
             htp.p(
             '<div id="divTitulo" class="DIVtitulo">'||
             '<table border="0" cellpadding="0" cellspacing="0" width="100%">'||
             '<tr >'||
                 '<td width="10%"></td>'||
                 '<th width="10%" align="left" bgcolor="#efefef">#</th>'||
                 '<th width="20%" align="left" bgcolor="#efefef">Inicio ejecuci&oacute;n</th>'||
                 '<th width="60%" align="left" bgcolor="#efefef">Tiempo ejecuci&oacute;n</th>'||
                 '</tr>'||
             '</table></div>'||
             '<div id="divDetalle" class="DIVdetalle">'||
             '<table border="0" cellpadding="0" cellspacing="0" width="100%">'
             );
          end if;

          vnNumEjec := vnNumEjec + 1;

          htp.p(
          '<tr '||pk_objhtml.vgsRenglon||'>'||
          '<td width="10%" bgcolor="#ffffff"></td>'||
          '<td width="10%">'||vnNumEjec||'.</td>'||
          '<td width="20%">'||regPro.cupoTime||'</td>'||
          '<td width="60%">'||substr(regPro.cupoIntr,1,(instr(regPro.cupoIntr,'-')-2))||'</td></tr>'
          );
      end loop;

      if vnNumEjec > 0 then
         htp.p(
         '</table></div>'
         );
      end if;

      htp.p(
      '
      <input type="hidden" name="psHora" id="psHora" value="'||vsHora||'" />
      <input type="hidden" name="psMint" id="psMint" value="'||vsMint||'" />
      <input type="hidden" name="psSegd" id="psSegd" value="'||vsSegd||'" />
      '
      );

  exception
      when others then
           htp.p(sqlerrm);

           --quita al usuario como ALL
 --          setUserALL('D');
  end verificaJob;

  --configurar nuevo periodo para calculo de cupos
  --setNewTerm
  procedure setNewTerm is

  cn0       constant number(1)   := 0;
  cn1       constant number(1)   := 1;
  csn       constant varchar2(1) := 'n';
  csYearNow constant varchar2(4) := to_char(sysdate,'YYYY');
  cnYear    constant number(4)   := to_number(csYearNow,'9999');
  csYearBef constant varchar2(4) := (cnYear+1);
  csYearAft constant varchar2(4) := (cnYear-1);

  --Periodos
  --cuTerms
  cursor cuTerms is
         select stvterm_code as termCode,
                stvterm_desc as termDesc,
                (select decode(count(cn1),cn0,csn,csY)
                   from swbtrmj
                  where swbtrmj_term_code = stvterm_code
                ) as conf
           from stvterm
          where (   stvterm_acyr_code = csYearBef
                 or stvterm_acyr_code = csYearNow
                 or stvterm_acyr_code = csYearAft
                )
            and exists     (select null
                              from ssbsect
                             where ssbsect_term_code = stvterm_code
                            )
          order by stvterm_code desc;

  --cuCamps
  cursor cuCamps is
         select stvcamp_code as campCode,
                stvcamp_desc as campDesc
           from stvcamp
          where stvcamp_code <> 'UAT'
            and stvcamp_code <> 'A'
            and stvcamp_code <> '000';

  begin
      htp.p(
      '<table border="0" cellpadding="2" cellspacing="2" width="100%">'||
      '<tr><td colspan="3">&nbsp;</td></tr>'||
      '<tr>'||
      '<td width="10%"></td>'||
      '<td width="30%" class="delabel">Selecciona periodo:<img src="/wtlgifs/web_required.gif" border="0" /> </td>'||
      '<td width="60%" bgcolor="#efefef">'||
      '<select name="slcTerm" id="slcTerm" onChange="periodoHabilitados(this.value)"><option value=""></option>'
      );

      for regTer in cuTerms loop

          htp.p(
          '<option value="'||regTer.termCode||'">'||regTer.conf||'  '||regTer.termCode||' - '||regTer.termDesc||'</option>'
          );
      end loop;

      htp.p(
      '</select></td></tr>'
      );

      --seleciona campus
      htp.p(
      '<tr>'||
      '<td width="10%"></td>'||
      '<td width="30%" class="delabel">Selecciona campus: </td>'||
      '<td width="60%" bgcolor="#efefef">'||
      '<select name="slcCamp" id="slcCamp" onChange="periodoCampHabilitados(this.value)"><option value=""></option>'
      );

      for regCmp in cuCamps loop
          htp.p(
          '<option value="'||regCmp.campCode||'">'||regCmp.campCode||' - '||regCmp.campDesc||'</option>'
          );
      end loop;

      htp.p(
      '</select></td></tr>'
      );

      htp.p(
      '</table><div id="divTerms"></div>'
      );
  end setNewTerm;

  --configurar nuevo periodo para calculo de cupos
  --setCnfTerm
  procedure setCnfTerm is

  vnExists  number(1)      := 0;
  vnRows    number(4)      := 0;
  vsObjetos varchar2(5000) := null;

  csGui     constant varchar2(3)  := ' - ';
  csCHECKED constant varchar2(7)  := 'CHECKED';
  csFecha   constant varchar2(11) := 'DD/MON/YYYY';

  --Periodos
  --cuTerms
  cursor cuTerms is
         select swbtrmj_vpdi_code                            as campCode,
                swbtrmj_ptrm_code                            as ptrmCode,
                decode(swbtrmj_exec_ind,csY,csCHECKED,null)  as execIndc,
                to_char(sobptrm_start_date,csFecha)||
                csGui||
                to_char(sobptrm_end_date,csFecha)            as fechas,
                sobptrm_start_date
           from swbtrmj,
                sobptrm
          where swbtrmj_ptrm_code = sobptrm_ptrm_code(+)
            and swbtrmj_term_code = sobptrm_term_code(+)
            and swbtrmj_term_code = psTermCd
            and (swbtrmj_vpdi_code = psCampCd or psCampCd is null)
          order by swbtrmj_vpdi_code,sobptrm_start_date;

  begin
      for regTer in cuTerms loop
          if vnExists = 0 then
             htp.p(
             '<br>'||
             '<table border="0" cellpadding="2" cellspacing="2" width="100%">
              <tr><td width="85%" align="right"><b>Selecciona todos:</b></td>
                  <td width="15%" bgcolor="#efefef" align="center">
                  <input type="checkbox" name="chkALL" id="chkALL" class="chkA" onClick="selectALL(this.checked);"/>
                  </td>
              <tr>
              </table>'||
             '<div id="divTitulo" class="DIVtitulo">'||
             '<table border="0" cellpadding="0" cellspacing="1" width="100%">'||
             '<tr>'||
             '<th width="10%"></th>'||
             '<th width="6%" bgcolor="#efefef">#</th>'||
             '<th width="12%" bgcolor="#efefef">Campus</th>'||
             '<th width="60%" bgcolor="#efefef">Parte de periodo</th>'||
             '<th width="12%" bgcolor="#efefef">Habilitado</th>'||
             '</tr>'||
             '</table>'||
             '</div>'||
             '<div id="divDetalle" class="DIVdetalle">'||
             '<table border="0" cellpadding="0" cellspacing="1" width="100%">'
             );
          end if;

          vnRows := vnRows + 1;

          htp.p(
          '<tr '||pk_objhtml.vgsRenglon||'>'||
          '<th width="10%" bgcolor="#ffffff"></th>'||
          '<td width="6%" align="center" style="border:solid 1.pt #dddddd;">'||vnRows||'.</td>'||
          '<td width="12%" align="center" style="border:solid 1.pt #dddddd;">'||regTer.campCode||'</td>'||
          '<td width="10%" align="center" style="border-left:solid 1.pt #dddddd;border-rigth:solid 1.pt #ffffff;border-top:solid 1.pt #dddddd;border-bottom:solid 1.pt #dddddd;">'||regTer.ptrmCode||'</td>'||
          '<td width="50%" align="left"   style="border-left:solid 1.pt #ffffff;border-rigth:solid 1.pt #dddddd;border-top:solid 1.pt #dddddd;border-bottom:solid 1.pt #dddddd;">'||regTer.fechas  ||'</td>'||
          '<td width="12%" align="center" style="border:solid 1.pt #dddddd;" bgcolor="#efefef"><input type="checkbox" name="chk'||regTer.campCode||'_'||regTer.ptrmCode||'" id="chk'||regTer.campCode||'_'||regTer.ptrmCode||'" class="chkA" '||regTer.execIndc||' /></td>'||
          '</tr>'
          );

          vsObjetos := vsObjetos||'chk'||regTer.campCode||'_'||regTer.ptrmCode||',';

          vnExists := 1;
      end loop;

      if vnExists = 1 then
         htp.p(
         '</table>'||
         '</div>'||
         '<table border="0" cellpadding="2" cellspacing="2" width="100%">
             <tr><td width="85%"></td>
                 <td width="15%" bgcolor="#efefef" align="center">
                 <input type="button" name="btnGuarda" id="btnGuarda" class="btnAA" value="Guarda" onClick="guardaTerms();"/>
                 </td>
             <tr>
             <tr><td width="85%"></td>
                 <td width="15%" bgcolor="#efefef" align="center">
                 <input type="button" name="btnNewCas" id="btnNewCas" class="btnAA" value="Nuevo PTRM" onClick="setPeriodo();"/>
                 </td>
             <tr>
             <tr><td width="85%"></td>
                 <td width="15%" bgcolor="#efefef" align="center">
                 <input type="button" name="btnDelete" id="btnDelete" class="btnAA" value="Elimina TERM" onClick="deleteTerm();"/>
                 </td>
             <tr>
             </table>'||
         '<br/>
         <input type="hidden" name="txtObj" id="txtObj" value="'||vsObjetos||'" />'
         );
      else
         htp.p(
         '<br><center><br/><font color="#ff0000"><b>No existen datos con los criteerios de busqueda.</b></font><br/><br/></center>'||
          '<table border="0" cellpadding="4" cellspacing="4" width="130pt" align="center">'||
             '<tr><td bgcolor="#efefef" align="center">'||
                 '<input type="button" name="btnGuarda" id="btnGuarda" class="btnAA" style="width:120pt;" value="Registra periodo" onClick="setPeriodo('''||psTermCd||''');"/>'||
                 '</td>'||
             '<tr>'||
             '</table>'||
         '<br/>'
         );
      end if;
  end setCnfTerm;

  --habilita o deshabilita periodos
  --setHABILITA
  procedure setHABILITA is

  vsCamp   varchar2(6)    := null;
  vsPtrm   varchar2(6)    := null;
  vsCaso   varchar2(10)   := null;
  vsCasosY varchar2(4000) := replace(psCasosY, 'chk',null);
  vsCasosN varchar2(4000) := replace(psCasosN, 'chk',null);
  --
  begin

      while ( instr(vsCasosY,',') > 0 ) loop
             vsCaso := substr(vsCasosY, 1, instr(vsCasosY,',')-1);

             vsCamp := substr(vsCaso, 1, instr(vsCaso,'_')-1);
             vsPtrm := substr(vsCaso,    instr(vsCaso,'_')+1);

             update swbtrmj
                set swbtrmj_exec_ind      = csY,
                    swbtrmj_activity_date = csSysdate,
                    swbtrmj_user          = csUser
              where swbtrmj_exec_ind  <> csY
                and swbtrmj_ptrm_code  = vsPtrm
                and swbtrmj_vpdi_code  = vsCamp
                and swbtrmj_term_code  = psTermCd;

             vsCasosY := substr(vsCasosY, instr(vsCasosY,',')+1);
      end loop;

      vsCaso := null;
      vsCamp := null;
      vsPtrm := null;

      while ( instr(vsCasosN,',') > 0 ) loop
             vsCaso := substr(vsCasosN, 1, instr(vsCasosN,',')-1);

             vsCamp := substr(vsCaso, 1, instr(vsCaso,'_')-1);
             vsPtrm := substr(vsCaso,    instr(vsCaso,'_')+1);

             update swbtrmj
                set swbtrmj_exec_ind      = csN,
                    swbtrmj_activity_date = csSysdate,
                    swbtrmj_user          = csUser
              where swbtrmj_exec_ind  <> csN
                and swbtrmj_ptrm_code  = vsPtrm
                and swbtrmj_vpdi_code  = vsCamp
                and swbtrmj_term_code  = psTermCd;

             vsCasosN := substr(vsCasosN, instr(vsCasosN,',')+1);
      end loop;

      commit;

      htp.p(
      '<script type="text/javascript">
      <!--
      var vsCamp = "'||psCampCd||'";

      function cambioRealizado() {
        parent.objFrmCup.slcTerm.disabled   = false;
        parent.objFrmCup.slcCamp.disabled   = false;

        parent.periodoCampHabilitados(vsCamp);
      } //cambioRealizado

      setTimeout("cambioRealizado()",2000);
      -->
      </script>
      '
      );


  end setHABILITA;

  --registra un nuevo periodo
  --setPeriodo
  procedure setPeriodo is

  csTerm constant varchar2(6) := psTermCd;
  csCamp constant varchar2(6) := psCampCd;

  begin
      begin
          insert into swbtrmj
          (swbtrmj_term_code, swbtrmj_ptrm_code, swbtrmj_vpdi_code, swbtrmj_exec_ind)
          select
           ssbsect_term_code, ssbsect_ptrm_code, ssbsect_camp_code, csY
            from ssbsect
           where not exists          (select null
                                        from swbtrmj
                                       where swbtrmj_vpdi_code = ssbsect_camp_code
                                         and swbtrmj_ptrm_code = ssbsect_ptrm_code
                                         and swbtrmj_term_code = ssbsect_term_code
                                      )
             and (ssbsect_camp_code = csCamp or csCamp is null)
             and ssbsect_term_code = csTerm
           group by ssbsect_term_code,ssbsect_camp_code,ssbsect_ptrm_code
           order by ssbsect_term_code,ssbsect_camp_code,ssbsect_ptrm_code;
      exception
          when others then
               null;
      end;

      commit;

      htp.p(
      '<script type="text/javascript">
      <!--
      var vsCamp = "'||psCampCd||'";

      function cambioRealizado() {
        parent.objFrmCup.slcTerm.disabled   = false;
        parent.objFrmCup.slcCamp.disabled   = false;

        parent.periodoCampHabilitados(vsCamp);
      } //cambioRealizado

      setTimeout("cambioRealizado()",2000);
      -->
      </script>
      '
      );

  end setPeriodo;

  --elimina la bitacora de cupos de inscripción
  --deleteBitacora
  procedure deleteBitacora is

  cdFecha constant date := to_date(psFecha,'DD/MM/YYYY');

  begin
      delete swrcupo
       where trunc(swrcupo_activity_date) < cdFecha;

      commit;

      htp.p(
      '<script type="text/javascript">
      <!--

      function cambioRealizado() {

        parent.verificaJob();
      } //cambioRealizado

      setTimeout("cambioRealizado()",2000);
      -->
      </script>
      '
      );

  end deleteBitacora;

  --elimina un periodo de la configuración de ejecución
  --deleteTerm
  procedure deleteTerm is

  csTerm constant varchar2(6) := psTermCd;
  csCamp constant varchar2(6) := psCampCd;

  begin
      delete swbtrmj
       where (swbtrmj_vpdi_code = csCamp or csCamp is null)
         and trunc(swbtrmj_term_code) = csTerm;

      commit;

      htp.p(
      '<script type="text/javascript">
      <!--
      var vsCamp = "'||psCampCd||'";

      function cambioRealizado() {
        parent.objFrmCup.slcTerm.disabled   = false;
        parent.objFrmCup.slcCamp.disabled   = false;

        parent.periodoCampHabilitados(vsCamp);
      } //cambioRealizado

      setTimeout("cambioRealizado()",2000);
      -->
      </script>
      '
      );

  end deleteTerm;


  --SEGURIDAD
  procedure seguridad is

  begin
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
  end seguridad;

  BEGIN
      --cambio de procesos para control de cupos
      IF psAccion = 'CHANGE' THEN
         setChange();
         RETURN;
      END IF;

      --verifica la ejecución de la cola
      IF psAccion = 'VERIFICAJOB' THEN
         verificaJob();
         RETURN;
      END IF;

      --verifica la ejecución de la cola
      IF psAccion = 'CONFIGURATERM' THEN
         setNewTerm();
         RETURN;
      END IF;

      --configurar nuevo periodo para calculo de cupos
      IF psAccion = 'CONFIGURADOS' THEN
         setCnfTerm();
         RETURN;
      END IF;

      --habilita o deshabilita periodos
      IF psAccion = 'HABILITA' THEN
         setHABILITA();
         RETURN;
      END IF;

      --registra un nuevo periodo
      IF psAccion = 'NEWTERM' THEN
         setPeriodo();
         RETURN;
      END IF;

      --elimina la bitacora de cupos de inscripción
      IF psAccion = 'ELIMINA' THEN
         deleteBitacora();
         RETURN;
      END IF;

      --elimina periodo
      IF psAccion = 'ELIMINATERM' THEN
         deleteTerm();
         RETURN;
      END IF;


      kwatitl.titulo(
      'Cálculo de cupos de inscripción',
      csImagenes,
      csAcciones,
      csOpciones,
      psCancelMnu=>'Y',
      psEventBody=>'onLoad="inicializaParametros();"'
      );

      PWAINFO('PWACLJB','INFORMACION');

      --pagina principal de parametros
      parametros;

      --código java script
      js();


      pk_objHTML.closed;
  END PWACLJB;
/
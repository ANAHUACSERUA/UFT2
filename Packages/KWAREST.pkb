CREATE OR REPLACE PACKAGE BODY BANINST1.kwarest IS
  
  /*
              TAREA: Mostrar el nombre de una persona. 
              FECHA: 08/04/2014
              AUTOR: ENBM
             MODULO: ADMINISTRACION (2).
     
     MODIFICACIONES: 
     modify Glovicx@06.05.2014  
     
  
  */

  PROCEDURE Inicio (psParametro VARCHAR2 DEFAULT NULL) IS

  csImagenes  CONSTANT VARCHAR2(100) := '"buscar","limpiar","save","menu","sali",';
  csAcciones  CONSTANT VARCHAR2(200) := 'javascript:setDetalleUsr();,javascript:Limpiar();,javascript:actualizaStatusUsr();,pk_MenuAplicacion.p_MenuAplicacion, javascript:paginaSalir();,';
  csOpciones  CONSTANT VARCHAR2(100) := '"Buscar","Limpiar","Ejecutar","Men&uacute;","Salir",';

  --parametros
  procedure parametros is

  begin

      htp.p(
      '<script language="javascript" src="kwatime.js?psMensaje=La pagina se est&aacute; cargando.<br/>Espera un momento por favor..."></script>
      <script language="javascript" src="kwaslct.js"></script>
            
      <br>    
      <form name="frmReset" id="frmReset" onSubmit="return false;" autocomplete="off">
            <table border="1" cellpadding="2" cellspacing="1" width="60%" align="center">
                   <tr><td colspan="2" style="border:solid 1.0pt #ffffff;" align="center">
                       <img src="/wtlgifs/web_required.gif" border="0" />&nbsp;
                       <font size="3">Valor requerido</font>
                       </td>
                   </tr>
                   <tr><td colspan="2" style="border:solid 1.0pt #ffffff;">&nbsp;</td>
                   </tr>
                   <tr>
                       <td width="20%" class="delabel" style="border:solid 1.0pt #ffffff;">
                           Ingresa Usuario:<img src="/wtlgifs/web_required.gif" border="0" />
                           </td>
                  
                       <td width="40%" bgcolor="#efefef" style="border:solid 1.0pt #ffffff;">
                           <input type="text" name="psUser" id="psUser" onBlur="colorFondo(this,''bkg02'');" onFocus="colorFondo(this,''bkg01'');" onKeyUp="cleanUserVacio(event);"/> 
                           </td>
                           </tr>
            </table>

      <div id="divStatusUser"></div>
      </form>
      
      <form name="frmOpciones" id="frmOpciones" method="post">
            <table border="0" cellpadding="2" cellspacing="1" width="60%" align="center">
                  <tr bgcolor="#efefef";>
                      <td width="2%">
                          <input type="radio" name="opcion" id="targetRadio1" value="L" class="chkA" onClick="validaRadioButton(this.value);">
                          </td>
                      <td width="13%" id="tdBlabel" style="font-size:10pt;">
                          Bloquear
                          </td>
                      <td width="2%">
                          <input type="radio" name="opcion" id="targetRadio2" value="U" class="chkA" onClick="validaRadioButton(this.value);">
                          </td>
                      <td width="13%" id="tdDlabel" style="font-size:10pt;">
                          Desbloquear
                          </td>                      
                      <td width="2%">
                          <input type="radio" name="opcion" id="targetRadio3" value="E" class="chkA" onClick="validaRadioButton(this.value);">
                          </td>
                      <td width="13%" id="tdFlabel" style="font-size:10pt;">
                          Exp. Contraseña
                          </td>                      
                      <td width="2%">
                          <input type="radio" name="opcion" id="targetRadio4" value="R" class="chkA" onClick="validaRadioButton(this.value);">
                          </td>
                      <td width="13%" id="tdRlabel" style="font-size:10pt;">
                          Cambiar Contraseña
                          </td>                       
                      </tr>
            </table>
            <br/>
            
            <div id="divMsgOper"></div>            
            
            <div id="divPassw"  >
            <table border="0" cellpadding="2" cellspacing="1" width="60%" align="center">  
                   <tr><td colspan="2">
            ');
            
           PWAINFO('kwarest.Inicio','PASSWORD');    
            
            htp.p('</br>
                       </td>
                       </tr>                         
                   <tr><td width="20%" class="delabel" style="border:solid 1.0pt #ffffff;">
                           Contraseña:<img src="/wtlgifs/web_required.gif" border="0" />
                           </td>
                       <td width="40%" bgcolor="#efefef" style="border:solid 1.0pt #ffffff;">
                           <input type="password" name="psPass" id="psPass" maxLength="15" onBlur="colorFondo(this,''bkg02'');" onFocus="colorFondo(this,''bkg01'');" onKeyPress="return validaTextPass(event);"/> 
                           </td>
                           </tr>
                   <tr><td  class="delabel" style="border:solid 1.0pt #ffffff;">
                           Confirma Contraseña:<img src="/wtlgifs/web_required.gif" border="0" />
                           </td>
                       <td  bgcolor="#efefef" style="border:solid 1.0pt #ffffff;">
                           <input type="password" name="psConfPass" id="psConfPass" maxLength="15" onBlur="colorFondo(this,''bkg02'');" onFocus="colorFondo(this,''bkg01'');" onKeyPress="return validaTextPass(event);"/> 
                           </td>
                           </tr>
            </table>
            </div>
            
      </form>
      
      <iframe name="fraDisabled" id="fraDisabled" hspace="0" vspace="0" width="0%" height="0pt" frameborder="0" tabindex="-1" src="aboutBlank" scrolling="no">
      </iframe>
      '
      ); 

  
  end parametros;
  
  --js
  procedure js is
    
  begin

      htp.p(
      '<script type="text/javascript">
      <!--
      window.history.forward(1);

      var objTextUser      = document.frmReset.psUser;
      var objRadioBtnBloq  = document.getElementById("targetRadio1");
      var objRadioBtnDesq  = document.getElementById("targetRadio2");
      var objRadioBtnExFch = document.getElementById("targetRadio3");
      var objRadioBtnReset = document.getElementById("targetRadio4");
      var objpsPass        = document.getElementById("psPass");
      var objpsConfPass    = document.getElementById("psConfPass");
      var objfrmReset      = document.frmReset;
      var objfrmOpciones   = document.frmOpciones;
      var objfraDisabled   = document.getElementById("fraDisabled");
      var rbOpcion         = "";            
      '
      );
      
      --setDetalleUsr
      htp.p( 
      'function setDetalleUsr(){
      
      var vsUser = objTextUser.value; 
       
       if(vsUser == "") {
          alert("Capture el Usuario.");
          objTextUser.focus();
          return;
       }
      //  alert("Estoy en el Usuario.");
       
       document.getElementById("divMsgOper").innerHTML = "";
        //  se comentaron estas 2 lineas del codigo Vic..
     //  document.getElementById("fontMsgTIme").innerHTML = "Buscando status del usuario.<br/>Espere un momento por favor...";
    
  
  
       //la funcion esta declarada en kwatime.js
  
    
     iniciaVentana();
  
  //      alert("ya pase el Usuario.");
       setTimeout("getStatus(''" + vsUser + "'')", 2000);
      
      } //setDetalleUsr
      ');
      
      --getStatus
      htp.p(
      '
      function getStatus(psUsr) {
        //la funcion esta declarada en kwaslct.js
                   //nombre pagina, parametros, identificador que recibe resultado          
         getMensaje("kwarest.detalleUsuario", "psUsuario=" + psUsr, "divStatusUser");
      }//getStatus
      '
      );
      
      --validaRadioButton
      htp.p(
      'function validaRadioButton(psValue) {
        
        if(psValue == "R") { 
           document.getElementById("divPassw").style.display = "";    
           document.frmOpciones.psPass.focus();    
        } else {
           document.getElementById("divPassw").style.display = "none"; 
        }
        
        document.getElementById("divMsgOper").innerHTML = "";
      
      } //validaRadioButton
      ');
      
      --disabledRadio
      htp.p(
      'function disabledRadio(pnHabilitar) {

      objRadioBtnBloq.disabled  = pnHabilitar; 
      objRadioBtnDesq.disabled  = pnHabilitar;
      objRadioBtnExFch.disabled = pnHabilitar;
      objRadioBtnReset.disabled = pnHabilitar; 
      
      objRadioBtnBloq.checked  = false;
      objRadioBtnDesq.checked  = false;
      objRadioBtnExFch.checked = false;
      objRadioBtnReset.checked = false;
      
      if (pnHabilitar) {
          
          document.getElementById("tdBlabel").innerHTML = "<font color=\"#aaaaaa\">Bloquear</font>";
          document.getElementById("tdDlabel").innerHTML = "<font color=\"#aaaaaa\">Desbloquear</font>";
          document.getElementById("tdFlabel").innerHTML = "<font color=\"#aaaaaa\">Exp. Contraseña</font>";
          document.getElementById("tdRlabel").innerHTML = "<font color=\"#aaaaaa\">Cambiar Contraseña</font>";
          
      } else {
          document.getElementById("tdBlabel").innerHTML = "<b>Bloquear</b>";
          document.getElementById("tdDlabel").innerHTML = "<b>Desbloquear</b>";
          document.getElementById("tdFlabel").innerHTML = "<b>Exp. Contraseña</b>";
          document.getElementById("tdRlabel").innerHTML = "<b>Cambiar Contraseña</b>";
      }
           
      document.getElementById("divPassw").style.display = "none"; 
      
      }//disabledRadio 
      ');
      
      --disabledStatusUsuario
      htp.p(
      'function disabledStatusUsuario(psStatUsr)
      {
      
      if(psStatUsr == "OPEN") { 
       
         objRadioBtnBloq.disabled  = false; 
         objRadioBtnDesq.disabled  = true;
         objRadioBtnExFch.disabled = false;
         objRadioBtnReset.disabled = false;
          
         document.getElementById("tdDlabel").innerHTML = "<font color=\"#aaaaaa\">Desbloquear</font>";
          
      } else if(psStatUsr == "LOCKED") {
      
         objRadioBtnBloq.disabled  = true; 
         objRadioBtnDesq.disabled  = false;
         objRadioBtnExFch.disabled = true;
         objRadioBtnReset.disabled = true;
         
         document.getElementById("tdBlabel").innerHTML = "<font color=\"#aaaaaa\">Bloquear</font>";
         document.getElementById("tdFlabel").innerHTML = "<font color=\"#aaaaaa\">Exp. Contraseña</font>";
         document.getElementById("tdRlabel").innerHTML = "<font color=\"#aaaaaa\">Cambiar Contraseña</font>";
      
      } else if(psStatUsr == "LOCKED(TIMED)") {
      
         objRadioBtnBloq.disabled  = true; 
         objRadioBtnDesq.disabled  = false;
         objRadioBtnExFch.disabled = true;
         objRadioBtnReset.disabled = true;
         
         document.getElementById("tdBlabel").innerHTML = "<font color=\"#aaaaaa\">Bloquear</font>";
         document.getElementById("tdFlabel").innerHTML = "<font color=\"#aaaaaa\">Exp. Contraseña</font>";
         document.getElementById("tdRlabel").innerHTML = "<font color=\"#aaaaaa\">Cambiar Contraseña</font>";
      
      } else if(psStatUsr == "EXPIRED") {
      
         objRadioBtnBloq.disabled  = true; 
         objRadioBtnDesq.disabled  = true;
         objRadioBtnExFch.disabled = true;
         objRadioBtnReset.disabled = false;
         
         document.getElementById("tdBlabel").innerHTML = "<font color=\"#aaaaaa\">Bloquear</font>";
         document.getElementById("tdDlabel").innerHTML = "<font color=\"#aaaaaa\">Desbloquear</font>";
         document.getElementById("tdFlabel").innerHTML = "<font color=\"#aaaaaa\">Exp. Contraseña</font>";
      
      } else if(psStatUsr == "EXPIRED(GRACE)") {
      
         objRadioBtnBloq.disabled  = true; 
         objRadioBtnDesq.disabled  = true;
         objRadioBtnExFch.disabled = true;
         objRadioBtnReset.disabled = false;
         
         document.getElementById("tdBlabel").innerHTML = "<font color=\"#aaaaaa\">Bloquear</font>";
         document.getElementById("tdDlabel").innerHTML = "<font color=\"#aaaaaa\">Desbloquear</font>";
         document.getElementById("tdFlabel").innerHTML = "<font color=\"#aaaaaa\">Exp. Contraseña</font>";
      
      } else if(psStatUsr == "EXPIRED & LOCKED") {
      
         objRadioBtnBloq.disabled  = true; 
         objRadioBtnDesq.disabled  = false;
         objRadioBtnExFch.disabled = true;
         objRadioBtnReset.disabled = false;
         
         document.getElementById("tdBlabel").innerHTML = "<font color=\"#aaaaaa\">Bloquear</font>";
         document.getElementById("tdFlabel").innerHTML = "<font color=\"#aaaaaa\">Exp. Contraseña</font>";
      
      } else {
       
         objRadioBtnBloq.disabled  = true; 
         objRadioBtnDesq.disabled  = true;
         objRadioBtnExFch.disabled = true;
         objRadioBtnReset.disabled = true;
       
         document.getElementById("tdBlabel").innerHTML = "<font color=\"#aaaaaa\">Bloquear</font>";
         document.getElementById("tdDlabel").innerHTML = "<font color=\"#aaaaaa\">Desbloquear</font>";
         document.getElementById("tdFlabel").innerHTML = "<font color=\"#aaaaaa\">Exp. Contraseña</font>";
         document.getElementById("tdRlabel").innerHTML = "<font color=\"#aaaaaa\">Cambiar Contraseña</font>";
      }

      }//disabledStatusUsuario
      ');
      --actualizaStatusUsr
      htp.p( 
      'function actualizaStatusUsr(){
      
         var vsUser     = objTextUser.value;
         var vsPass     = objpsPass.value;
         var vsConfPass = objpsConfPass.value;
         
       //   alert("Capture la CTA VIC.");
                if (objRadioBtnBloq.checked) {
                    rbOpcion = objRadioBtnBloq.value;
         
         } else if (objRadioBtnDesq.checked) {     
                    rbOpcion = objRadioBtnDesq.value;
                  //   alert("Capture la CTA VIC. 2.2  ");
             
         } else if (objRadioBtnExFch.checked) {
                    rbOpcion = objRadioBtnExFch.value;
            
         } else if (objRadioBtnReset.checked) { 
                    rbOpcion = objRadioBtnReset.value;
            
         } else {
             rbOpcion = "";
         }  
         
       //   alert("Capture la CTA VIC. 3--3 ");
          
         if(vsUser == "") {
            alert("Capture la cuenta del usuario.");
            
            
            objTextUser.focus();
            return;
          }         
      
         if(rbOpcion == "") {
            alert("Seleccione la operación a realizar.");
           //  alert("Capture la CTA VIC. RBOPTION ");
            return;
           }  
         
         if(rbOpcion == "R") {         
            if(vsPass == "") {
               alert("Introduce la contraseña");
               objpsPass.focus();
               return;
            } 
            
            if (vsPass.length < 6) {
                alert("La contraseña debe contener minimo 6 caracteres y maximo 15 caracteres");
                objpsPass.focus();
                return;
            }
            
            if (vsPass != vsConfPass) {
                alert("Las contraseñas no coinciden"); 
                objpsConfPass.focus();
                return;
            }  
            
          //   alert("Capture la CTA VIC. 7.7 ");
          } 
          ///------SE COMENTO ESTA COLUMNA VIC...
        //  document.getElementById("fontMsgTIme").innerHTML = "Actualizando status de usuario.<br/>Espere un momento por favor...";
      // alert("Capture la CTA VIC. 9.9 ");
          //la funcion esta declarada en kwatime.js
          iniciaVentana();

        
         
         setTimeout("setActualizaStatusUsr(''" + vsUser + "'',''" +  rbOpcion + "'',''" + vsPass + "'')", 2000);

      } //actualizaStatusUsr
      ');
      
      --setActualizaStatusUsr
      htp.p(
      'function setActualizaStatusUsr(psUsr, psOption,psPass)
      {
        document.getElementById("fraDisabled").src = "kwarest.cambioStatus?psUser=" + psUsr + 
                                                     "&psAccion=" + psOption +  
                                                     "&psPasswd=" + psPass; 
      }//setActualizaStatusUsr
      '
      );
      
      --setMensaje
      htp.p(
      '
      function setMensaje(vsMsg){
      
      document.getElementById("divMsgOper").innerHTML = "<br/><center><font color=\"#bb0000\"><b>" + vsMsg + "</b></font></center><br/>";
      
      //alert(vsMsg);
      alert(vsMsg+"vic"); // la puso vic
      }
      '
      );
      
      --procesoTerminado
      htp.p(
      'function procesoTerminado()
      {        
        var vsExist   = document.frmReset.txtUser.value;   
        var vsStatUsr = document.frmReset.txtStatUsr.value;   

        if(vsExist == 1) {
           disabledRadio(false);
        } else {
           disabledRadio(true);
        }
        
        disabledStatusUsuario(vsStatUsr);
        
        objpsPass.value = "";
        objpsConfPass.value = "";
        
        // la funcion esta declarada en kwatime.js     
        closeWindowTime();
 
      } //procesoTerminado'
      );
      
      --inicializaPagina
      htp.p(
      'function inicializaPagina()
      {
      objTextUser.focus();
      
      document.getElementById("divPassw").style.display = "none";
      
      document.getElementById("fraDisabled").style.display = "";
      
      
      disabledRadio(true);
      
      // la funcion esta declarada en kwatime.js     
      closeWindowTime();
      
      }//inicializaPagina
      
      inicializaPagina();
      ');
         
      --validaTextPass
      htp.p(
      '
      function validaTextPass(e){
        key    = e.keyCode || e.which;
        tecla  = String.fromCharCode(key).toLowerCase();
        letras = "abcdefghijklmnñopqrstuvwxyz0123456789";
        
        if(letras.indexOf(tecla)==-1){
           return false;
           objpsPass.focus();
        }
      } //validaTextPass    
      '
      );

      --cleanUserVacio
      htp.p(
      ' 
      function cleanUserVacio(e) {
        key = e.keyCode || e.which;
        
        if (objTextUser.value == "") {
            Limpiar();
        }
       
        if(key==13){
           setDetalleUsr(); 
        } 
      }//cleanUserVacio
      '
      );
      
       --Limpiar
      htp.p(
      'function Limpiar() 
      {  
      
      objfrmReset.reset();
      objfrmOpciones.reset();
      
      document.getElementById("divStatusUser").innerHTML = "";
      
      document.getElementById("divMsgOper").innerHTML = "";
  
      objRadioBtnBloq.disabled  = true; 
      objRadioBtnDesq.disabled  = true;
      objRadioBtnExFch.disabled = true;
      objRadioBtnReset.disabled = true;
      
      objRadioBtnBloq.checked  = false;
      objRadioBtnDesq.checked  = false;
      objRadioBtnExFch.checked = false;
      objRadioBtnReset.checked = false;

      document.getElementById("tdBlabel").innerHTML = "<font color=\"#aaaaaa\">Bloquear</font>";
      document.getElementById("tdDlabel").innerHTML = "<font color=\"#aaaaaa\">Desbloquear</font>";
      document.getElementById("tdFlabel").innerHTML = "<font color=\"#aaaaaa\">Exp. Contraseña</font>";
      document.getElementById("tdRlabel").innerHTML = "<font color=\"#aaaaaa\">Cambiar Contraseña</font>";
        
      document.getElementById("divPassw").style.display = "none";
      
      objpsPass.value = "";
      objpsConfPass.value = "";
      
      
      objTextUser.focus();
      } //Limpiar
      ');
      
      htp.p('
      -->
      </script>'
      );
  
  end js;
  
    
  BEGIN
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
     
      kwatitl.titulo(
      '',
      csImagenes,
      csAcciones,
      csOpciones,
      psCancelMnu=>'Y'
      );
      
  ---    htp.p( ' alert("Estoy en el debug 1 .")    '  );
    PWAINFO('kwarest.Inicio','INSTRUCCIONES');   
      
     

      parametros();
    ---   htp.p( ' alert("Estoy en el debug 2 .")    '  );
      
      --código javascript
      js;
      
      pk_objHTML.closed;

  end Inicio;
  
  procedure cambioStatus(psUser  VARCHAR2, 
                         psAccion VARCHAR2,
                         psPasswd VARCHAR2
                         ) IS
                         
  vsAccion VARCHAR2(1)    := psAccion; 
  vsError  VARCHAR2(4000) := NULL;
  vnExist  INTEGER        := 0;
  
  csI CONSTANT VARCHAR2(1)  := 'I'; 
  csR CONSTANT VARCHAR2(1)  := 'R';
   
                          
  begin
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
      
      IF vsAccion = csR THEN
         vsAccion := csI;           
      END IF;
      
      PWAALTR(psUser,vsAccion,pk_login.vgsUSR, vsError,psPasswd);   
      

         htp.p(
         '
         <script type="text/javascript">
         <!--
         var vsMsg = "'||vsError||'";
         ');
           
         --setDetalle
         htp.p(
         'function setDetalle() {
             
            parent.setDetalleUsr() 
            setTimeout("Mensaje()", 500);
        
         } //setDetalle
         ');
         
         --Mensaje
         htp.p(
         'function Mensaje() {
             
           parent.setMensaje(vsMsg);
        
         } //Mensaje
         ');
         
         --sMensaje
         htp.p(
         '        
         setDetalle();
         -->
         </script>
         '
         );
 
                          
  end cambioStatus;
  
  procedure detalleUsuario(psUsuario VARCHAR2) is
  
  vsStatus      varchar2(200) := NULL;
  vsStatUsr     varchar2(18) := NULL;
  vsFechBloqueo varchar2(20) := NULL;
  vsFechExpira  varchar2(20) := NULL;
  vsNameUser    varchar2(40) := NULL;
  
  csCampCode                    CONSTANT VARCHAR2(6)  := f_context();
  csUserName                    CONSTANT VARCHAR2(32) := UPPER(psUsuario);
  csOPEN                        CONSTANT VARCHAR2(4)  := 'OPEN';
  csLOCKED                      CONSTANT VARCHAR2(6)  := 'LOCKED';
  csLOCKEDTIMED                 CONSTANT VARCHAR2(14) := 'LOCKED(TIMED)';
  csEXPIRED                     CONSTANT VARCHAR2(7)  := 'EXPIRED';
  csEXPIREDGRACE                CONSTANT VARCHAR2(15) := 'EXPIRED(GRACE)';
  csEXPIREDLOCKED               CONSTANT VARCHAR2(17) := 'EXPIRED & LOCKED';
  csActivo                      CONSTANT VARCHAR2(6)  := 'Activo';
  csInactivo                    CONSTANT VARCHAR2(8)  := 'Inactivo';
  csVigenciaContVencida         CONSTANT VARCHAR2(31) := 'Vigencia de contraseña vencida';
  csVigenciaContConcluir        CONSTANT VARCHAR2(47) := 'Vigencia de contraseña por concluir o vencida';
  csVigenciaContVencidaInactiva CONSTANT VARCHAR2(44) := 'Vigencia de contraseña vencida e inactiva';
  csDDMONYY                     CONSTANT VARCHAR2(22) := 'DD-MON-YYY HH24:MI:SS';
  csFont                        CONSTANT VARCHAR2(30) := '</b></font>';
  csFont00ff00                  CONSTANT VARCHAR2(30) := '<font color="#00dd00"><b>';
  csFontff0000                  CONSTANT VARCHAR2(30) := '<font color="#ff0000"><b>';
  
  --cuUsuario
  CURSOR csUsuario is
         SELECT DECODE(ACCOUNT_STATUS,csOPEN,          csFont00ff00||csActivo                     ||csFont,
                                      csLOCKED,        csFontff0000||csInactivo                   ||csFont,
                                      csLOCKEDTIMED,   csFontff0000||csInactivo                   ||csFont,
                                      csEXPIRED,       csFontff0000||csVigenciaContVencida        ||csFont,
                                      csEXPIREDGRACE,  csFontff0000||csVigenciaContConcluir       ||csFont,
                                      csEXPIREDLOCKED, csFontff0000||csVigenciaContVencidaInactiva||csFont
                                      )        AS accoStat,
                ACCOUNT_STATUS                 AS statUser,
                TO_CHAR(LOCK_DATE  ,csDDMONYY) AS dateLock,
                TO_CHAR(EXPIRY_DATE,csDDMONYY) AS exprDate,
                GURIDEN_DESC                   AS idenDesc
           FROM DBA_USERS,
                GURIDEN
          WHERE USERNAME = GURIDEN_USER_ID
            AND USERNAME = csUserName;   
  
  BEGIN
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;           
      
      FOR regRep IN csUsuario LOOP
           vsStatus      := regRep.accoStat; 
           vsStatUsr     := regRep.statUser; 
           vsFechBloqueo := regRep.dateLock;
           vsFechExpira  := regRep.exprDate;
           vsNameUser    := regRep.idenDesc;
      END LOOP;      
       
      IF vsStatus||vsFechBloqueo||vsFechExpira IS NULL THEN
         vsStatUsr := NULL;
         
         htp.p(
         '<center>'||
         'El usuario "'||csUserName||'" no existe.'||
         '</center>'||
         
         '<input type="hidden" name="txtUser" id="txtUser" value="0">'||
         
         '<input type="hidden" name="txtStatUsr" id="txtStatUsr" value="'||vsStatUsr||'">'
         );
         
      ELSE
         htp.p( 
         '<table width="60%" border="0" cellpadding="2" cellspacing="1" align="center">'||
         '<tr>'||
         '<th width="20%" align="right"><font size="2">Nombre Usuario:</font></th>'||
         '<td width="40%"><font size="2">'||vsNameUser||'</font></td>'||
         '</tr>'||
         '<tr>'||
         '<th  align="right"><font size="2">Status Usuario:</font></th>'||
         '<td ><font size="2">'||vsStatus||'</font></td>'||
         '</tr>'||
         '<tr>'||
         '<th align="right"><font size="2">Fecha Bloqueo:</font></th>'||
         '<td ><font size="2">'||vsFechBloqueo||'</font></td>'||
         '</tr>'||
         '<tr>'||
         '<th align="right"><font size="2">Fecha Expiraci&oacute;n:</font></th>'||
         '<td ><font size="2">'||vsFechExpira||'</font></td>'||
         '</tr>'||
         '</table>'||
         
         '<input type="hidden" name="txtUser" id="txtUser" value="1">'||

         '<input type="hidden" name="txtStatUsr" id="txtStatUsr" value="'||vsStatUsr||'">'
         
         );

      END IF;
             
  end detalleUsuario;
  
END KWAREST;
/


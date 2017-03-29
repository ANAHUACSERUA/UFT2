CREATE OR REPLACE PACKAGE BODY BANINST1.kwatime IS
/*
            TAREA: Presentar una ventana de tiempo en lo que termina de ejecutarse una página WEB
            FECHA: 13/10/2010
            AUTOR: MAC
           MODULO: General

   MODIFICACIONES: CONSULTE EL "PACKAGE BODY" PARA VER EL DETALLE DE LAS MODIFICACIONES
*/


  PROCEDURE js(psMensaje VARCHAR2 DEFAULT 'El reporte se est&aacute; generando.<br/>Espere un momento por favor...'
              ) IS


 procedure VALIDACION is
 global_pidm spriden.spriden_pidm%type;
 begin
      IF NOT twbkwbis.F_ValidUser(global_pidm) THEN RETURN; END IF;
 end VALIDACION;

  BEGIN


      htp.p(
      '
            var y1       = 100;   // change the # on the left to adjuct the Y co-ordinate
      var vbgActiv = false;

      (document.getElementById) ? dom = true : dom = false;

      window.onUnLoad = function(){
        closeWindowTime();
      }

      function closeWindowTime() {

        if (dom) {
            document.getElementById("pleasewaitScreen").style.visibility=''hidden'';
        }

        if (document.layers) {
            document.layers["pleasewaitScreen"].visibility=''hide'';
        }

        vbgActiv = false;

        document.body.className = "";
      } //closeWindowTime

      function iniciaVentana(){

        if(!vbgActiv) {
           cambiaPosicion();
        }

        vbgActiv = true;

      } //iniciaVentana

      //cambiaPosicion
      function cambiaPosicion() {

        if (dom) {
            document.getElementById("pleasewaitScreen").style.visibility=''visible'';
        }

        if (document.layers) {
            document.layers["pleasewaitScreen"].visibility=''show'';
        }

        document.getElementById("pleasewaitScreen").style.left = (document.body.clientWidth/2) -200;

        moverVentana();
      } //cambiaPosicion

      //moverVentana
      function moverVentana() {

        if (dom && !document.all) {
            document.getElementById("pleasewaitScreen").style.top = window.pageYOffset + (window.innerHeight - (window.innerHeight-y1))
        }

        if (document.layers) {
            document.layers["pleasewaitScreen"].top = window.pageYOffset + (window.innerHeight - (window.innerHeight-y1))
        }

        if (document.all) {
            document.all["pleasewaitScreen"].style.top = document.body.scrollTop + (document.body.clientHeight - (document.body.clientHeight-y1));
        }

        window.setTimeout("moverVentana()", 10);
      }


      document.write(
      ''<div id="pleasewaitScreen" ''+
      ''style="position:absolute;z-index:5;top:30%;left:42%;visibility:visible">''+
      ''<table border="1" bordercolor="#5992be" cellpadding="0" cellspacing="0" height="100" width="350" id="Table1">''+
      ''<tr>''+
      ''<td width="100%" height="100%" bgcolor="#b1c9e1" align="center" valign="middle"><br/>''+
      ''<font style="color: black;font-family: Verdana, Arial Narrow, helvetica, sans-serif; font-weight: normal;font-size: 100%; font-style: normal;" id="fontMsgTIme">''+
      '''||psMensaje||'</font><br/><br/><img src="/imagenes/large_loading.gif"><br/>''+
      ''</font><br><br/></td></tr></table></div>''
      );

      '
      );
  END js;

END kwatime;
/
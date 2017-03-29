CREATE OR REPLACE PACKAGE BODY BANINST1.kwasfar IS

/*
          TAREA: Capturar un expediente y quitar la marca de incripción de cursos
          FECHA: 13/01/2011
          AUTOR: GEPC
         MODULO: General

   MODIFICACION:

*/

  PROCEDURE capturarExpediente;

  PROCEDURE JS IS

  BEGIN
      htp.p('
      <!--
      var vgsId   = "";
      var vgsTerm = "";
      ');

      --inicializaValores
      htp.p(
      'function inicializaValores() {
         document.frmExp.psId.focus();
      } //inicializaValores
      '
      );

      --Limpiar
      htp.p(
      'function Limpiar() {
         vgsId = "";

         document.getElementById("divNombre").innerHTML = "";
         document.getElementById("divBlokeo").innerHTML = "";

         document.frmExp.reset();

         document.frmExp.psTerm.disabled = true;

         document.frmExp.psId.focus();
      }//Limpiar
      '
      );

      --buscaNombre
      htp.p('
      function buscaNombre() {
        vgsId = document.frmExp.psId.value;

        if(vgsId == "") {
           alert("Captura el expediente del alumno");
           document.frmExp.psId.focus();
           return;
        }

        document.frmExp.psTerm.disabled = false;

        //la función es llamada de la página "kwaslct.js"
        getMensaje("kwasfar.obtieneNombre","psId=" + vgsId,"divNombre");

        cargaSelect("kwactlg.catalogo", "psCatalogo=STVTERM&psFiltro1=BLOQUEOS&psFiltro2=" + vgsId, document.frmExp.psTerm,"ALL");
      } //buscaNombre
      ');

      --abrirArchivo
      htp.p('
      function quitarBloqueo() {
        if(vgsTerm=="") {
           alert("Seleccione el periodo a desbloquear.");
           document.frmExp.psTerm.focus();
           return;
        }

        //la función es llamada de la página "kwaslct.js"
        getMensaje("kwasfar.quitarBloqueo","psId=" + vgsId + "&psTerm=" + vgsTerm,"divBlokeo");

      } //quitarBloqueo
      ');

      --procesoTerminado
      htp.p('
      //La función es llamado por el proceso "getMensaje"
      function procesoTerminado() {

      } //procesoTerminado
      ');
      
      --colorFondo
      htp.p(
      'function colorFondo(Objeto,psColor) {
         Objeto.className=psColor;
      } //colorFondo
      ');


      --inicializaValores
      htp.p(
      'function changeSelect(psValue) {
         vgsTerm = psValue;
      } //changeSelect

      -->
      ');
  END JS;

  --capturarExpediente
  PROCEDURE capturarExpediente IS

  BEGIN
      htp.p('
      <script language="javascript" src="kwaslct.js"></script>

      </head><body bgcolor="#ffffff">

      <center>
      <br/>
      <img src="/wtlgifs/web_required.gif" />Indica un valor obligatorio.
      </center>
      <br/>

      <form name="frmExp" method="POST" autocomplete="OFF" onSubmit="return false;">
      <table border="1" cellpadding="2" cellspacing="1" width="100%" bordercolor="#ffffff" bgcolor="#ffffff">
             <tr><td width="20%"></td>
                 <td width="30%" class="delabel">
                     Captura el expediente del alumno
                     <img src="/wtlgifs/web_required.gif" />
                     </td>
                 <td width="30%" bgcolor="#efefef">
                     <input type="text" name="psId" id="psId" maxlength="10" onBlur="colorFondo(this,''bkg02'');" onFocus="colorFondo(this,''bkg01'');" style="width:100%" />
                     </td>
                 <td width="20%"></td>
                 </tr>
             <tr><td></td>
                 <td class="delabel">
                     Seleccione el periodo
                     <img src="/wtlgifs/web_required.gif" />
                     </td>
                 <td bgcolor="#efefef">
                     <select name="psTerm" onChange="changeSelect(this.value);" DISABLED><option value=""></option>
                     </select>
                     </td>
                 <td></td>
                 </tr>
      </table>
      </form>

      <div id="divNombre"></div>
      <div id="divBlokeo"></div>

      <script language="javascript" src="kwasfar.js"></script>
      '
      );
  END capturarExpediente;

  --obtieneNombre
  PROCEDURE obtieneNombre(psId VARCHAR2) IS

  vsNombre   VARCHAR2(300) := 'NO SE ENCONTRO EL NOMBRE DEL ALUMNO';
  vsDisabled VARCHAR2(8)   := 'DISABLED';

  csEsp CONSTANT VARCHAR2(1) := ' ';
  csAst CONSTANT VARCHAR2(1) := '*';

  CURSOR cuName IS
         SELECT REPLACE(SPRIDEN_LAST_NAME||csEsp||SPRIDEN_FIRST_NAME,csAst,csEsp) AS Nombre
           FROM SPRIDEN
          WHERE EXISTS (SELECT NULL
                          FROM SGBSTDN A
                         WHERE A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                            FROM SGBSTDN B
                                                           WHERE B.SGBSTDN_PIDM = A.SGBSTDN_PIDM
                                                         )
                           AND A.SGBSTDN_PIDM          = SPRIDEN_PIDM
                       )
            AND SPRIDEN_CHANGE_IND IS NULL
            AND SPRIDEN_ID          = psId;

  BEGIN
      IF pk_login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      FOR regNam IN cuName LOOP
          vsNombre   := regNam.Nombre;
          vsDisabled := NULL;
      END LOOP;

      htp.p(
      '
      <table border="1" cellpadding="2" cellspacing="1" width="100%" bordercolor="#ffffff" bgcolor="#ffffff">
             <tr>
             <td width="45%"></td>
             <td width="20%" align="center"><b>'||vsNombre||'</b>
                 </td>
             <td width="10%">
                 <input type="button" onClick="quitarBloqueo();" class="btnAA" value="Quitar Bloqueo" '||vsDisabled||'>
                 </td>
             <td width="25%"></td>
                 </tr>
      </table>
      '
      );

  END obtieneNombre;

  PROCEDURE expediente(psParametro VARCHAR2) IS

  csImagenes CONSTANT VARCHAR2(300) := '"buscar","limpiar","menu","sali",';
  csAcciones CONSTANT VARCHAR2(300) := 'javascript:buscaNombre();,javascript:Limpiar();,pk_MenuAplicacion.p_MenuAplicacion,javascript:paginaSalir();,';
  csOpciones CONSTANT VARCHAR2(300) := '"Buscar","Limpiar","Men&uacute;","Salir",';

  BEGIN
      IF pk_login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      kwatitl.titulo(
      'Quitar el bloqueo de inscripción de cursos.',
      csImagenes,
      csAcciones,
      csOpciones,
      psCancelMnu=>'A',
      psEventBody=>'onLoad="javascript:inicializaValores();"'
      );

      capturarExpediente;

      pk_objHtml.closed;
  END expediente;

  --quitarBloqueo
  PROCEDURE quitarBloqueo(psId   VARCHAR2,
                          psTerm VARCHAR2
                         ) IS

  vnUpdate NUMBER(2)    := NULL;
  vsAccion VARCHAR2(65) := NULL;

  csNull   CONSTANT VARCHAR2(1)  := NULL;
  csFalla  CONSTANT VARCHAR2(65) := '<img src="/wtlgifs/web_stop.gif" border="0" width="15pt" /><br/>';
  csDone   CONSTANT VARCHAR2(65) := '<img src="/stugifs/hwsgchek.gif" border="0" width="15pt" /><br/>';

  BEGIN
      IF pk_login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      BEGIN
          UPDATE SFRRACL
             SET SFRRACL_SOURCE_CDE         = csNull,
                 SFRRACL_REG_ACCESS_ID      = csNull,
                 SFRRACL_LAST_ACTIVITY_DATE = csNull
           WHERE SFRRACL_PIDM      = f_get_pidm(psId)
             AND SFRRACL_TERM_CODE = psTerm;

          vnUpdate := SQL%ROWCOUNT;
      END;

      IF vnUpdate > 0 THEN
         vsAccion := csDone;
      ELSE
         vsAccion := csFalla;
      END IF;

      htp.p(
      '<br/><br/><center>'||
      '<div style="border: 1pt SOLID #FCB656; width:50%">'||
      vnUpdate||' Registros actualizados '||vsAccion||
      '</center></div>'
      );

  END quitarBloqueo;

END kwasfar;
/
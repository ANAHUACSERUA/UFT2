DROP PACKAGE BODY BANINST1.PK_ASIGNAAPLICACION;

CREATE OR REPLACE PACKAGE BODY BANINST1.pk_AsignaAplicacion IS
/*
  Objetivo              : Aplicación para asiganar escuelas y periodos a modificar
  Fecha de creación     : 10/05/2006
  Autor                 : GEPC

  modificación: 27/07/2011
                RZL
                Look and feel de "Aplicacion Asignada a usuarios"
                Procedure:P_Aplicacion
                Derivado del Look and feel se elimino el Proceso P_Usuarios
*/


  --EL PROCEDIMIENTO GENERA LOS FRAIMS DE LA APLICACIÓN
  PROCEDURE P_Aplicacion(psParametro VARCHAR2 DEFAULT NULL) IS

  csImagenes     CONSTANT VARCHAR2(60)  := '"menu","sali",';
  csAcciones     CONSTANT VARCHAR2(100) := 'pk_MenuAplicacion.p_MenuAplicacion, javascript:paginaSalir();,';
  csOpciones     CONSTANT VARCHAR2(60)  := '"Regresar al menu de aplicaciones","Salir",';

  BEGIN
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      kwatitl.titulo(
      'Asignar aplicaciones a usuarios',
      csImagenes,
      csAcciones,
      csOpciones,
      psHeight=>'100',
      psWidth=>'200',
      psCancelMnu=>'Y',
      psEventBody=>'onLoad="javascript:cargaCombos();"',
      pnTamCell=>20
      );

      --RZ
      htp.p( '
      <script src="kwatime.js" language="javascript"></script>
      <script src="kwaslct.js" language="javascript"></script>

      <form name="frmConsulta">
      <table border="0" width="50%" align="center" cellpadding="1" cellspacing="1" bgcolor="#ffffff" bordercolor="#ffffff">
             <tr>
                 <td width="20%" class="delabel">
                     Usuario Banner
                     </td>
                 <td width="30%" bgcolor="#efefef">
                     <select name="psUser" id="psUser" tabindex="1" onChange="fCambiaNombre();"></select>
                     </td>
                 </tr>
             <tr>
                 <td class="delabel">
                     Modulo
                     </td>
                 <td bgcolor="#efefef">
                     <select name="psModulo" id="psModulo" tabindex="2" onChange="fCambiaNombre();"></select>
                     </td>
                 </tr>
      </table>
      </form>


      <div id="divDatos"></div>


                  <iframe name="fraAsigna04" id="fraAsigna04" width="100%" height="0px" frameborder="0" tabindex="-1" src="aboutBlank" scrolling="NO">
      </iframe>
      ');

      js;

      pk_objHTML.closed;

  END P_Aplicacion;


  --GENERA LAPAGINA HTML EN LA APLICACION QUE ASIGNA LA APLICACION
  PROCEDURE p_AsignandoModulo(psMsg    VARCHAR2,
                              pbAccion BOOLEAN,
                              psAccion VARCHAR2,
                              pnModulo NUMBER DEFAULT NULL) IS

  BEGIN
      --se genera una página para informar al usuario y retornar a la aplicación
      htp.p('<html><head><title>&nbsp;</title>');

      -- la aplicación no se guarda en el cache de la maquina.
      PK_ObjHTML.P_NoCache;

      htp.p('<script language="JavaScript"><!--');
      htp.p('function fHabilitaObjetos() {
             alert("'||psMsg||'");
      ');

      IF pbAccion THEN
         htp.p('parent.fraAsigna01.fCambiaNombre();');
      END IF;

      IF psAccion = 'true' AND NOT pbAccion THEN
         htp.p('parent.fraAsigna02.fraAplicaA.fVisualizaAplicaciones('||pnModulo||');');
      END IF;

      htp.p('}');
      htp.p('//--></script>');

      htp.p('</head><body class="bodyCeroR" onLoad="fHabilitaObjetos();">
      </body></html>');
  END p_AsignandoModulo;

  --PAGINA PREVIA PARA PRESENTAR LA ASIGNACION DE APLICACIONES
  PROCEDURE p_AplicacionAsignada(psUsuario VARCHAR2,
                                 psModulo  VARCHAR2) IS

  BEGIN


      htp.p('

   <table border="1" width="50%" align="center" cellpadding="1" cellspacing="1" bgcolor="#ffffff" bordercolor="#ffffff">

                 <td valign="bottom">
                     <table border="0" width="100%" cellpadding="0" cellspacing="0" bgcolor="#ffffff" bordercolor="#ffffff">
                            <tr><td width="100%" class="delabel">Aplicaciones asignadas a :'||psUsuario||' </td></tr>
                        </table>
                 </td>
    </tr>
        <tr><td colspan="2">
             <iframe name="fraAplicaB" frameborder="0" scrolling="AUTO" src="pk_AsignaAplicacion.p_AplicacionAsignada?psUsuario='||psUsuario||'&psModulo='||psModulo||'&psAplicacion=0" style="border:inset 0; height:160pt; width:100%;" tabindex="-1"></iframe>
            </td>
     </tr>
             <tr class="trSeparador"><td colspan="2"></td></tr>
      </table>');


  END p_AplicacionAsignada;

  --PRESENTA EL LISTADO DE APLICACIONES
  PROCEDURE p_AplicacionAsignada(psUsuario    VARCHAR2,
                                 psModulo     VARCHAR2,
       psAplicacion VARCHAR2) IS

  vnChk     INTEGER       := 0;
  vsModulo  VARCHAR2(500) := NULL;

  CURSOR cuApli IS
         SELECT SWRSMDL_CODE                            smdlCode,
                SWRSMDL_DESC                            smdlDesc,
                   DECODE(musr.smdlCode,NULL,'','CHECKED') Checked
           FROM SWRSMDL,
                (SELECT SWRMUSR_MODL_CODE modlCode,
                        SWRMUSR_SMDL_CODE smdlCode
                   FROM SWRMUSR
                  WHERE SWRMUSR_USER = psUsuario) musr
          WHERE SWRSMDL_MODL_CODE = psModulo
            AND SWRSMDL_MODL_CODE = musr.modlCode(+)
            AND SWRSMDL_CODE      = musr.smdlCode(+)
          ORDER BY SWRSMDL_CODE;

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      htp.p('<html><head><title>Asignar aplicaciones a usuarios</title>');

      -- la aplicación no se guarda en el cache de la maquina.
      PK_ObjHTML.P_NoCache;

      --código css
      PK_ObjHTML.P_CssTabs;

      PK_ObjHTML.P_Toggle('frmAsigana');

      htp.p('<script language="JavaScript"><!--');
      --la función asigana el modulo al usuario
      htp.p('function fAsignaModulo(objCheck) {
      var vsValor = objCheck.value;
      var vsCheck = objCheck.checked;

      document.frmModulo.pnAplicacion.value = vsValor;
      document.frmModulo.psAccion.value     = vsCheck;
      document.frmModulo.submit();
      }');
      htp.p('//--></script>');

      htp.p('</head><body bgcolor="#ffffff" class="bodyCero">');

      htp.p('<table border="1" width="100%" cellpadding="1" cellspacing="1" align="center" bgcolor="#ffffff" bordercolor="#ffffff">
      <form name="frmAsigana" onSubmit="return false;">');

      FOR regApli IN cuApli LOOP
          IF regApli.Checked IS NOT NULL THEN
             vsModulo := '<b>'||regApli.smdlDesc||'</b>';
          ELSE
             vsModulo := regApli.smdlDesc;
          END IF;

          vnChk := vnChk + 1;

          htp.p('  <tr> <td width="50%">
                       <table border="1" width="100%" cellpadding="1" cellspacing="1" bordercolor="#efefef" bgcolor="#ffffff" '||PK_ObjHTML.vgsRenglon||'>
                                <tr><td width="10%" bgcolor="#efefef" align="center">
                                        <input type="checkbox" name="chkBox'||vnChk||'" class="chkA" value="'||regApli.smdlCode||'" '||regApli.Checked||' onClick="Toggle(this); fAsignaModulo(this);"></td>
                                    <td width="90%" >'||vsModulo||'</td>
                               </tr></table>
                     </td>
                 </tr>');

      END LOOP;

      htp.p('</form></table>');

      htp.p('
      <form name="frmModulo" action="pk_AsignaAplicacion.p_AsignandoAplicacion" method="post" target="fraAsigna04">
      <input type="hidden" name="psUsuario" value="'||psUsuario||'">
      <input type="hidden" name="pnModulo"  value="'||psModulo||'">
      <input type="hidden" name="pnAplicacion">
      <input type="hidden" name="psAccion">
      </form>
      ');

      htp.p('</body></html>');
  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(psUsuario||' - '||psModulo);
  END p_AplicacionAsignada;

  --REGISTRA LA APLICACIÓN AL USUARIO
  PROCEDURE p_AsignandoAplicacion(psUsuario    VARCHAR2,

                                  pnModulo     NUMBER,
                                  pnAplicacion NUMBER,
                                  psAccion     VARCHAR2) IS

  vsMsg   VARCHAR2(4000) := 'La aplicación ha sido asignada al usuario: '||psUsuario||'.';
  vbError BOOLEAN        := FALSE;

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      IF psAccion = 'true' THEN
         BEGIN
             INSERT INTO SWRMUSR(SWRMUSR_MODL_CODE, SWRMUSR_SMDL_CODE, SWRMUSR_USER)
                          VALUES(pnModulo,          pnAplicacion,      psUsuario);
         EXCEPTION
             WHEN DUP_VAL_ON_INDEX THEN
                  vsMsg   := 'ERROR: '||SQLERRM;
                  vbError := TRUE;
             WHEN OTHERS THEN
                  vsMsg   := SQLERRM;--'ERROR: Antes de asignar esta aplicación, registre el modulo al que pertenece.';
                  vbError := TRUE;
         END;
      ELSE
         DELETE SWRMUSR
          WHERE SWRMUSR_MODL_CODE = pnModulo
            AND SWRMUSR_SMDL_CODE = pnAplicacion
            AND SWRMUSR_USER      = psUsuario;

         vsMsg := 'El registro a sido eliminado';
      END IF;

      COMMIT;

      p_AsignandoModulo(vsMsg,vbError,'');

 EXCEPTION
      WHEN OTHERS THEN
           IF SQLCODE = -2291 THEN
              vsMsg := 'Antes de asignar esta aplicación, registre el modulo al que pertenece.';
           ELSE
              vsMsg  := SQLERRM;
           END IF;

           p_AsignandoModulo('ERROR: '||vsMsg,TRUE,'');
  END p_AsignandoAplicacion;

  PROCEDURE js IS
  BEGIN
      htp.p('
      <script type="text/javascript">
       <!--

       var objUser = document.frmConsulta.psUser;
       var objModl = document.frmConsulta.psModulo;
       var vgsUser = "'||PK_Login.vgsUSR||'";

       function cargaCombos() {

         cargaSelectCall("kwactlg.catalogo", "psCatalogo=GURIDEN", objUser, "ALL", "llenaModulo();");


       } //cargaCombos


       function llenaModulo() {

         cargaSelectCall("kwactlg.catalogo", "psCatalogo=SWBMODL", objModl, "ALL", "inicializaValores();");


       } //llenaModulo

       function inicializaValores() {
         objUser.value = vgsUser;

         objUser.focus();

         closeWindowTime();
       } //inicializaValores


       function fCambiaNombre() {
         var vsUsuario    = objUser.options[objUser.selectedIndex].value;
         var vsModulo     = objModl.options[objModl.selectedIndex].value;
         var vsPagina     = "pk_AsignaAplicacion.p_AplicacionAsignada";
         var vsParametros = "psUsuario=" + vsUsuario + "&psModulo=" + vsModulo;;


         if(vsUsuario == "" || vsModulo == "") {
               return;
            }

         iniciaVentana();


         document.getElementById("divDatos").innerHTML = "";


         getMensaje(vsPagina, vsParametros, "divDatos");


       } //fCambiaNombre

       function procesoTerminado(){
         closeWindowTime();

       }//procesoTerminado


       -->
       </script>
       ');

  END js;

END pk_AsignaAplicacion;
/


DROP PUBLIC SYNONYM PK_ASIGNAAPLICACION;

CREATE PUBLIC SYNONYM PK_ASIGNAAPLICACION FOR BANINST1.PK_ASIGNAAPLICACION;


GRANT EXECUTE ON BANINST1.PK_ASIGNAAPLICACION TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ASIGNAAPLICACION TO WWW2_USER;

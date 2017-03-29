DROP PROCEDURE BANINST1.PWAREG9;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG9(pnBuscar VARCHAR2,
 pnProc INTEGER DEFAULT NULL,
 psLevl VARCHAR2 DEFAULT NULL) IS

 vgsUSR VARCHAR2(500);

 CURSOR cuRegla IS
 SELECT SWNTCKA_TERM_CODE Term,
 SWNTCKA_LEVL_CODE Levl,
 SWNTCKA_USER Usrr,
 SWNTCKA_SEQ Proc
 FROM SWNTCKA
 WHERE SWNTCKA_PROCEDURE = 'PWAREG1'
 ORDER BY SWNTCKA_SEQ DESC, SWNTCKA_LEVL_CODE;

 procedure p_Cantidad is

 vnCantidad INTEGER := 0;
 vnIndex INTEGER := 0;
 vnLnght INTEGER := 1;

 cursor cuMaterias is
 select substr(swntckn_subj_code,1,1) Subj,
 count(1) Cantidad
 from swntckn
 where swntckn_seq = pnProc
 and swntckn_levl_code = psLevl
 group by substr(swntckn_subj_code,1,1)
 order by substr(swntckn_subj_code,1,1);

 begin
 select count(1)
 into vnCantidad
 from swntckn
 where swntckn_seq = pnProc
 and swntckn_levl_code = psLevl;

 htp.p('<html><head><title>&nbsp;</title>

 <script language="JavaScript"><!--
 function f_Cantidad() {
 opener.document.frmRegla.psLetra.length = 0;
 opener.document.frmRegla.psLetra.length = '||vnLnght||';
 opener.document.frmRegla.psLetra['||vnIndex||'].text = "";
 opener.document.frmRegla.psLetra['||vnIndex||'].value = "";
 ');

 for regMat in cuMaterias loop
 vnLnght := vnLnght + 1;
 vnIndex := vnIndex + 1;

 htp.p('
 opener.document.frmRegla.psLetra.length = '||vnLnght||';
 opener.document.frmRegla.psLetra['||vnIndex||'].text = "'||regMat.Subj||' - '||regMat.Cantidad||'";
 opener.document.frmRegla.psLetra['||vnIndex||'].value = "'||regMat.Subj||'";
 ');
 end loop;

 htp.p('
 opener.document.frmRegla.txtRegs.value = "'||vnCantidad||'";
 opener.document.frmRegla.psLetra.className = "";
 opener.document.frmRegla.txtRegs.className = "";
 opener.document.frmRegla.psLetr1.className = "";
 opener.document.frmRegla.txtReg1.className = "";
 opener.document.body.className = ""
 close();
	 }
 //--></script>
	 </head><body onLoad="f_Cantidad();">
 </body></html>
 ');

 end p_Cantidad;

 BEGIN
 -- valida que el usuario pertenezca a la base de datos.
 IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

 IF pnProc IS NOT NULL THEN
 p_Cantidad;

 RETURN;
 END IF;

 htp.p('
 <html><head><title></title>
 ');

 PK_ObjHTML.P_NoCache;

 htp.p(PK_ObjHTML.vgsCssBanner);

 pK_ObjHTML.P_CssTabs;

 htp.p('
 <style type="text/css"><!--
 select.oculta {font-size:1.0pt;width:0%;}
 --></style>
 <script language=''JavaScript''><!--
 javascript:window.history.forward(1);
 var vgsBuscar = true;
 ');

 ----
 htp.p('function f_Buscar() {
 if(!vgsBuscar) { return; }

 document.frmLimpia.submit();
 document.body.className = "bodyCursorW";

 var vsTerm = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].alt;
 var vsLevl = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].title;
 var vsSeqc = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].value;
 var vsLetr = document.frmRegla.psLetra.options[document.frmRegla.psLetra.selectedIndex].value;

 document.frmBuscar.psTerm.value = vsTerm;
 document.frmBuscar.psLevl.value = vsLevl;
 document.frmBuscar.pnSeqc.value = vsSeqc;
 document.frmBuscar.psLett.value = vsLetr;

 vgsBuscar = false;

 document.frmBuscar.submit();
 } //f_Buscar');

 ----
 htp.p('function f_Registros() {
 if(!vgsBuscar) { return; }

 document.frmRegla.psLetra.className = "oculta";
 document.frmRegla.txtRegs.className = "oculto";
 document.frmRegla.psLetr1.className = "oculto";
 document.frmRegla.txtReg1.className = "oculto";

 var vsSeqc = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].value;
 var vsLevl = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].title;

 frmLOV = open("about:blank", "winMateria", "toolbar=no,directories=no,status=no,resizable=yes,location=no,titlebar=no,scrollbars=yes");

 if(navigator.appVersion.charAt(0) >=4) {
		 frmLOV.resizeTo(10,10);
		 frmLOV.moveTo(0,0);
	 }

 if(frmLOV.opener == null) {
 frmLOV.opener = self;
 }

 document.frmMateria.pnProc.value = vsSeqc;
 document.frmMateria.psLevl.value = vsLevl;
 document.body.className = "bodyCursorW";

 setTimeout("document.frmMateria.submit()",1000);

 } //f_Registros');

 ----
 htp.p('function f_Ejecutar() {
 if(!vgsBuscar) { return; }

 var vsTerm = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].alt;
 var vsLevl = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].title;
 var vsSeqc = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].value;
 var vsLetr = document.frmRegla.psLetra.options[document.frmRegla.psLetra.selectedIndex].value;

 if( vsLetr != "") {

 }

 } //f_Ejecutar');

 htp.p('function f_ReiniciarOperacioes() {
 vgsBuscar = true;

 } //f_ReiniciarOperacioes');

 htp.p('function f_LimpiarFrame() {
 if(!vgsBuscar) { return; }

 document.frmLimpia.submit();
 } //f_LimpiarFrame');

 htp.p('function f_QuitarReloj() {
 document.body.className = "";
 vgsBuscar = true;
 } //f_QuitarReloj');

 htp.p('//--></script>');

 htp.p('
 </head><body bgcolor="#ffffff"><br/><br/><br/><br/><br/>
 <table border="0" width="100%" cellpadding="0" cellspacing="0">
 <form name="frmRegla" onSubmit="return false;">
 <tr><th width="60%" class="thTitulo" valign="bottom" align="left">
 <br>Reporte de reglas de repetici&oacute;n
 </th><td width="40%">
 ');

 pk_MenuAplicacion.P_MenuSalir('PWAREGL?psParametro=PWAREGL');

 htp.p('</td></tr></table>
 <hr size="1" width="100%">

 <table border="0" cellpadding="2" cellspacing="1" width="100%" bgcolor="#ffffff">
 <tr>
 <th width="10%" valign="top" align="right" bgcolor="#FCB654">Regla</th>
 <td width="40%" valign="top" bgcolor="#efefef" colspan="2">
 <select name="psTermCode" onChange="f_Registros();"><option value=""></option>
 ');

 FOR regRgl IN cuRegla LOOP
 htp.p('<option value="'||regRgl.Proc||'" alt="'||regRgl.Term||'" title="'||regRgl.Levl||'">'||regRgl.Term||' - '||regRgl.Levl||' - '||regRgl.Usrr||' - '||regRgl.Proc||'</option>');
 END LOOP;

 htp.p('
 </select>
 </td>
 <td valign="top" rowspan="3" width="20%">
 ');

 --pk_MenuAplicacion.P_MenuDinamico('"Buscar","Ejecutar",','javascript:f_Buscar();,javascript:f_Ejecutar();,','"Buscar","Desaplicar",');
 pk_MenuAplicacion.P_MenuDinamico('"buscar",','javascript:f_Buscar();,','"Buscar",');

 htp.p('
 </td>
 <td valign="top" rowspan="3" width="30%"></td></tr>
 <tr><td><input type="text" name="txtReg1" class="oculto" tabindex="-1" style="border:outset 0;text-align:right" readonly value="Cantidad de registros:" /></td>
 <td colspan="2">
 <input type="text" name="txtRegs" class="oculto" tabindex="-1" style="border:outset 0;" readonly/></td>
 </tr>
 <tr><td><input type="text" name="psLetr1" class="oculto" tabindex="-1" style="border:outset 0;text-align:right" readonly value="Inicial de la materia" /></td>
 <td width="20%"><select name="psLetra" class="oculta" onChange="f_LimpiarFrame();" />
 </select></td>
 <td width="20%"></td>
 </tr>
 ');

 htp.p('

 <tr><td colspan="5">
 <iframe name="fraBusca" id="fraBusca" src="about:blank" width="100%" height="300px" frameborder="1">
 </iframe>
 </td>

 </form>
 </table>
 </br></br>
 <hr size="1" width="100%">
 </br>

 <form name="frmBuscar" action="PWRREGL" target="fraBusca" method="post">
 <input type="hidden" name="psTerm" />
 <input type="hidden" name="psLevl" />
 <input type="hidden" name="pnSeqc" />
 <input type="hidden" name="psExlS" />
 <input type="hidden" name="psLett" />
 </form>

 <form name="frmMateria" action="PWAREG9" target="winMateria" method="get">
 <input type="hidden" name="pnBuscar" value="B"/>
 <input type="hidden" name="pnProc" />
 <input type="hidden" name="psLevl" />
 </form>

 <form name="frmLimpia" action="about:blank" target="fraBusca">
 </form>

 </body>
 </html>');
 END PWAREG9;
/


DROP PUBLIC SYNONYM PWAREG9;

CREATE PUBLIC SYNONYM PWAREG9 FOR BANINST1.PWAREG9;


GRANT EXECUTE ON BANINST1.PWAREG9 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG9 TO WWW2_USER;

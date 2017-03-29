DROP PROCEDURE BANINST1.PWALVRS;

CREATE OR REPLACE PROCEDURE BANINST1.PWALVRS(psCatalogo VARCHAR2 DEFAULT NULL,
 psVisible VARCHAR2 DEFAULT NULL,
 psFiltroA VARCHAR2 DEFAULT NULL,
 psFiltroB VARCHAR2 DEFAULT NULL,
 psFiltroC VARCHAR2 DEFAULT NULL,
 psFiltroD VARCHAR2 DEFAULT NULL,
 psFiltroE VARCHAR2 DEFAULT NULL,
 psObjectA VARCHAR2 DEFAULT NULL,
 psObjectB VARCHAR2 DEFAULT NULL,
 psObjectC VARCHAR2 DEFAULT NULL,
 psObjectD VARCHAR2 DEFAULT NULL,
 psObjectE VARCHAR2 DEFAULT NULL,
 psTitulo VARCHAR2 DEFAULT NULL) IS

/*
 AUTOR: GEPC
 FECHA: 30/03/2009
 TAREA: Presenta la ventana para hacer una lista de valores
 MODULO: Reportes

*/

 vsOpciones VARCHAR2(50) := '"limpiar","buscar","sali",';
 vsTraduccn VARCHAR2(50) := '"Limpiar","Buscar","Salir",';
 vsAcciones VARCHAR2(200) := 'javascript:f_Limpia();,javascript:f_Busca();,javascript:f_Salir(),';
 vsFiltroA VARCHAR2(400) := '<input type="text" name="psFiltroA" value="'||psFiltroA||'" />';
 vsFiltroB VARCHAR2(400) := '<input type="hidden" name="psFiltroB" value="'||psFiltroB||'" />';
 vsFiltroC VARCHAR2(400) := '<input type="hidden" name="psFiltroC" value="'||psFiltroC||'" />';
 vsFiltroD VARCHAR2(400) := '<input type="hidden" name="psFiltroD" value="'||psFiltroD||'" />';
 vsFiltroE VARCHAR2(400) := '<input type="hidden" name="psFiltroE" value="'||psFiltroE||'" />';
 vsTitulo VARCHAR2(400) := NULL;

 -- El procedimiento realiza la consulta del catalogo
 procedure p_Query is

 TYPE regDato IS RECORD (valDatoA VARCHAR2(300),
 valDatoB VARCHAR2(300),
 valDatoC VARCHAR2(300),
 valDatoD VARCHAR2(300),
 valDatoE VARCHAR2(300),
 valDatoF VARCHAR2(300),
 valDatoG VARCHAR2(300),
 valDatoH VARCHAR2(300)
 );

 TYPE tableDato IS TABLE OF regDato INDEX BY BINARY_INTEGER;

 tabDato tableDato;
 cuCatalogo LOV.t_ListaDeValores;
 vnRow integer := 1;
 vnExists integer := 0;

 begin
 cuCatalogo := LOV.Consulta(psCatalogo, psFiltroA, psFiltroB, psFiltroC, psFiltroD, psFiltroE);

 loop
 exit when cuCatalogo%notfound;
 fetch cuCatalogo into tabDato(vnRow).valDatoA,
 tabDato(vnRow).valDatoB,
 tabDato(vnRow).valDatoC,
 tabDato(vnRow).valDatoD,
 tabDato(vnRow).valDatoE,
 tabDato(vnRow).valDatoF,
 tabDato(vnRow).valDatoG,
 tabDato(vnRow).valDatoH;
 exit when cuCatalogo%notfound;

 vnRow := vnRow + 1;

 end loop;
 close cuCatalogo;

 vnRow := vnRow - 1;

 htp.p('function f_ClockNormal() {
 document.body.className = "bodyCero2";
 parent.f_Clock();
 }//f_Limpia
 ');

 htp.p('
 //--></script>

 <style type="text/css"><!--
 body.bodyCero1 {margin-left: 0pt; margin-right: 0pt; margin-top: 0pt;margin-bottom: 0pt; cursor:wait;}
 body.bodyCero2 {margin-left: 0pt; margin-right: 0pt; margin-top: 0pt;margin-bottom: 0pt;}
 --></style>

 <head><body bgcolor="#ffffff" class="bodyCero1" onLoad="f_ClockNormal();">
 <form name="frmPast" onSubmit="return false;">
 <table border="0" cellpadding="2" cellspacing="1" width="100%" bgcolor="#ffffff">
 ');

 for vnI in 1..vnRow loop
 htp.p('<tr>
 <td>'||
 PK_ObjHTML.f_a(tabDato(vnI).valDatoA,
 'javascript:parent.f_pastValue('''||tabDato(vnI).valDatoA||''',document.frmPast.psCodeA'||vnI||'.value)',
 vnI,
 1
 )||
 '</td>
 <td>'||tabDato(vnI).valDatoB||'</td>
 <td>'||tabDato(vnI).valDatoC||'</td>
 <td>'||tabDato(vnI).valDatoD||'</td>
 <td>'||tabDato(vnI).valDatoE||'</td>
 <td>'||tabDato(vnI).valDatoF||'</td>
 <td>'||tabDato(vnI).valDatoG||'</td>
 <td>'||tabDato(vnI).valDatoH||'</td>
 <td>
 <input type="text" name="psCodeA'||vnI||'" class="oculto" value="'||tabDato(vnI).valDatoA||'" tabindex="-1" />
 </td>
 </tr>');
 --
 vnExists := 1;
 end loop;

 htp.p('
 </form>
 </table>
 ');

 if vnExists = 0 then
 htp.p('
 <br/>
 <p align="center">
 <font color="#aa0000" size="4">No existen valores con el filtro de busqueda</font>
 </p>
 ');
 end if;

 htp.p('
 </body>
 </html>
 ');

 exception
 when others then
 htp.p(sqlerrm);
 end p_Query;

 BEGIN
 SELECT DECODE(psFiltroB,NULL,psFiltroB,' ('||psFiltroB||')')
 INTO vsTitulo
 FROM DUAL;

 htp.p('<html><head><title>'||psTitulo||vsTitulo||'</title>');

 PK_ObjHTML.P_NoCache;

 pK_ObjHTML.P_CssTabs;

 htp.p('<script language=''JavaScript''><!--
 javascript:window.history.forward(1);
 ');

 IF psVisible IS NOT NULL THEN
 p_Query;

 RETURN;
 END IF;

 ----
 htp.p('function f_Limpia() {
 document.frmBusca.reset();

 document.frmBusca.psFiltroA.value = "";
 }//f_Limpia
 ');

 ----
 htp.p('function f_Salir() {
 window.close();
 }//f_Limpia
 ');

 ----
 htp.p('function f_Busca() {
 document.body.className = "bodyCursorW";
 document.frmBusca.submit();

 window.status = "Espere un momento por favor...";
 }//f_Limpia
 ');

 ----
 htp.p('function f_Clock() {
 document.body.className="";
 }//f_Limpia
 ');

 ----
 htp.p('function f_pastValue(psValueA, psValueB, psValueC, psValueD, psValueE) {
 ');

 IF psObjectA IS NOT NULL THEN
 htp.p('opener.'||psObjectA||'.value = psValueA;'); -- Antes opener.frmdatos 02/07/2009
 END IF;

 IF psObjectB IS NOT NULL THEN
 htp.p('opener.'||psObjectB||'.value = psValueB;');
 END IF;

 IF psObjectC IS NOT NULL THEN
 htp.p('opener.'||psObjectC||'.value = psValueC;');
 END IF;

 IF psObjectD IS NOT NULL THEN
 htp.p('opener.'||psObjectD||'.value = psValueD;');
 END IF;

 IF psObjectE IS NOT NULL THEN
 htp.p('opener.'||psObjectE||'.value = psValueE;');
 END IF;

 htp.p('
 f_Salir();
 }//f_pastValue
 ');

 htp.p('//--></script>');

 htp.p('
 </head><body bgcolor="#F48D00" onLoad="document.frmBusca.psFiltroA.focus();">
 <table border="0" cellpadding="2" cellspacing="1" width="100%" height="100%" bgcolor="#dedede">
 <form name="frmBusca" action=BANINST1."PWALVRS" method="post" target="fraFind">
 <tr height="0%">
 <td height="0%" colspan="2">'||psTitulo||vsTitulo||'</td>
 <td width="20%" height="0%" rowspan="3">
 ');

 pk_MenuAplicacion.P_MenuDinamico(vsOpciones, vsAcciones, vsTraduccn);

 htp.p('
 </td>
 </tr>
 <tr height="0%">
 <td height="0%"></td>
 <td height="0%"></td>
 </tr>
 <tr height="0%">
 <th width="10%" height="0%" align="right">Buscar</th>
 <td width="70%" height="0%">
 <input type="hidden" name="psCatalogo" value="'||psCatalogo||'" />
 <input type="hidden" name="psVisible" value="true" />
 '||vsFiltroA||
 vsFiltroB||'
 <input type="hidden" name="psTitulo" value="'||psTitulo||'" />
 </td>
 </tr>
 <tr height="90%">
 <td height="95%" colspan="3" valign="top">
 <iframe name="fraFind" id="fraFind" src="about:blank" width="100%" height="100%" frameborder="0">
 </iframe>
 </td>
 </tr>
 <tr height="5%">
 <td height="5%" colspan="3">
 </td>
 </tr>

 </form>
 </table>
 ');

 IF (psFiltroA IS NOT NULL OR psFiltroB IS NOT NULL) AND psVisible IS NULL THEN
 htp.p('<script language=''JavaScript''><!--
 f_Busca()
 //--></script>');
 END IF;

 htp.p('
 </body>
 </html>
 ');

 EXCEPTION
 WHEN OTHERS THEN
 htp.p(SQLERRM);
 END PWALVRS;
/


DROP PUBLIC SYNONYM PWALVRS;

CREATE PUBLIC SYNONYM PWALVRS FOR BANINST1.PWALVRS;

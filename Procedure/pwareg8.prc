DROP PROCEDURE BANINST1.PWAREG8;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG8(pnSeq INTEGER,
 psExl VARCHAR2 DEFAULT NULL) IS

/*
 Tarea: REPORTE DE REGLAS DE REPETICI?N
 Fecha: 07/07/2011

 Modulo: Historia academica

*/

 vnRow INTEGER := 0;
 vsOpciones VARCHAR2(50) := '"imprimir","excel",';
 vsAcciones VARCHAR2(200) := 'javascript:f_Imprimir();,javascript:f_Excel(),';
 vgsUSR VARCHAR2(500);
 vsError SWNTCKA.SWNTCKA_ERROR%TYPE := NULL;

 cursor cuReglas IS
 SELECT SWNTCKA_SEQ Seqn,
 SWNTCKA_TERM_CODE Term,
 SWNTCKA_LEVL_CODE Levl,
 DECODE(SWNTCKA_PROCEDURE,
 'PWAREG1',
 '1. Identificar materias repetidas por los alumnos',
 'PWAREG2',
 '2. Respaldo de las materias de historia acad?mica',
 'PWAREG3',
 '3. Actualizar a "NULL" los campos SHRTCKN_REPEAT_COURSE_IND y SHRTCKN_REPEAT_SYS_IND',
 'PWAREG4',
 '4. Actualizar las materias repetidas con "I, E"'
 ) Etpa,
 SWNTCKA_ERROR Erro
 FROM SWNTCKA
 WHERE SWNTCKA_SEQ = pnSeq
 ORDER BY SWNTCKA_BEGIN;

 BEGIN
 -- valida que el usuario pertenezca a la base de datos.
 IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

 IF psExl IS NOT NULL THEN
 owa_util.mime_header('application/ms-excel',true);
 END IF;

 htp.p('
 <html><head><title>&nbsp;</title>
 ');

 pK_ObjHTML.P_CssTabs;

 PK_ObjHTML.P_NoCache;

 htp.p('<script language=''JavaScript''><!--
 javascript:window.history.forward(1);
 ');
 ----
 htp.p('function f_Imprimir() {
	 window.focus()
		 print();
 } //f_Imprimir;
 ');

 ----
 htp.p('function f_Excel(){
 window.status = "Excel...";
 document.frmReporte.submit();
 } //f_Excel');

 htp.p('
 //--></script>
 </head><body bgcolor="#ffffff" class="bodyCeroR">
 <table border="0" cellpadding="0" cellspacing="0" width="20%">
 <tr><td>');

 pk_MenuAplicacion.P_MenuDinamico(vsOpciones, vsAcciones, vsOpciones);

 htp.p('
 </td></tr></table>
 <br/>
 <table border="1" cellpadding="2" cellspacing="1" width="100%" bordercolor="#eeeeee">
 <tr><td colspan="5" bgcolor="#dddddd" align="center">
 En caso de ocurrir un error favor de reportar a
 <a href="mailto:soportesiu@caesc.mx"><font color="#ff8500">HELP DESK</font></a>
 </td>
 </tr>
 <tr><th width="10%" bgcolor="#efefef">Proceso</th>
 <th width="10%" bgcolor="#efefef">Periodo</th>
 <th width="10%" bgcolor="#efefef">Nivel </th>
 <th width="40%" bgcolor="#efefef">Etapa </th>
 <th width="30%" bgcolor="#efefef"><font color="#ff0000">Error</font></th>
 </tr>
 ');

 FOR regRgl IN cuReglas LOOP
 IF vnRow = 1 THEN
 regRgl.Seqn := NULL;
 END IF;

 IF vsError IS NULL THEN
 vsError := regRgl.Erro;
 END IF;

 htp.p('
 <tr>
 <td valign="top" align="center">'||regRgl.Seqn||'</td>
 <td valign="top" align="center">'||regRgl.Term||'</td>
 <td valign="top" align="center">'||regRgl.Levl||'</td>
 <td valign="top">'||regRgl.Etpa||'</td>
 <td valign="top">'||regRgl.Erro||'</td>
 </tr>
 ');

 vnRow := 1;
 END LOOP;

 htp.p('
 <tr><td colspan="5" bgcolor="#dddddd" align="center">
 En caso de ocurrir un error favor de reportar a
 <a href="mailto:soportesiu@caesc.mx"><font color="#ff8500">HELP DESK</font></a>
 </td>
 </tr>
 </table>
 <br/>
 <br/>

 <form name="frmReporte" action=BANINST1."PWAREG8" method="post">
 <input type="hidden" name="pnSeq" value="'||pnSeq||'"/>
 <input type="hidden" name="psExl" value="'||pnSeq||'" />
 </form>

 </body>
 </html>
 ');
 END PWAREG8;
/


DROP PUBLIC SYNONYM PWAREG8;

CREATE PUBLIC SYNONYM PWAREG8 FOR BANINST1.PWAREG8;


GRANT EXECUTE ON BANINST1.PWAREG8 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG8 TO WWW2_USER;

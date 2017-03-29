DROP PROCEDURE BANINST1.PWAREGL;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREGL(psParametro VARCHAR2) IS
/*
    Tarea: Aplicaci?n principal para aplicar las reglas de repetici?n.
    Fecha: 08/07/2011
    Autor: MAC
   Modulo: Historia academica


*/

  vgsUSR VARCHAR2(500);

  CURSOR cuStvLevl IS
         SELECT STVLEVL_CODE levlCode,
                STVLEVL_DESC levlDesc
           FROM STVLEVL
          WHERE STVLEVL_CODE <> '00'
          ORDER BY levlCode;

  CURSOR cuStvTerm IS
         SELECT STVTERM_CODE termCode,
                STVTERM_DESC termDesc
           FROM STVTERM
          WHERE (STVTERM_ACYR_CODE = TO_CHAR(SYSDATE,'YYYY')
             OR STVTERM_ACYR_CODE = TO_CHAR(SYSDATE,'YYYY')+1
             OR STVTERM_ACYR_CODE = TO_CHAR(SYSDATE,'YYYY')-1
             )
          ORDER BY termCode DESC;

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

      htp.p('
      <html><head><title></title>
      ');

      PK_ObjHTML.P_NoCache;

      htp.p(PK_ObjHTML.vgsCssBanner);

      pK_ObjHTML.P_CssTabs;

      htp.p('<script language=''JavaScript''><!--
      javascript:window.history.forward(1);

      vgsEjecuta = false;
      vgsLevel   = "";
      vgsComa    = "";
      ');

      ----
      htp.p('function f_Limpia() {
        if(vgsEjecuta) { return; }

        document.frmRegla.reset();
      } //f_Limpia
      ');

      ----
      htp.p('function f_Ejecutar() {
        if(vgsEjecuta) { return; }

        var vsTerm   = document.frmRegla.psTermCode.options[document.frmRegla.psTermCode.selectedIndex].value;
        var objLista = document.frmRegla.psLevlCode;
        var vnLength = objLista.length;
        var vsLevl   = "";
        var vnSeqc   = document.frmEjecutar.pnSeqc.value;

        document.frmRegla.txtPen1.value = "Nivel pendiente:";
        document.frmRegla.txtCon1.value = "Nivel concluido:";
        document.frmRegla.txtConc.value = "";

        for(var vnI=0; vnI<vnLength; vnI++) {
            if(objLista.options[vnI].selected == true) {
               vsLevl = vsLevl + objLista.options[vnI].value + ",";
            }
        }

               if(vsTerm == "") {
                  alert("Por favor selecciona el periodo.");
                  document.frmRegla.psTermCode.focus();
        } else if(vsLevl == "") {
                  alert("Por favor selecciona el nivel.");
                  document.frmRegla.psLevlCode.focus();
        }

        if(vsTerm!="" && vsLevl!="") {
           document.frmEjecutar.psTerm.value = vsTerm;
           vgsLevel                          = vsLevl;
           vgsEjecuta                        = true;
           document.body.className           = "bodyCursorW";

           if(vnSeqc == null || vnSeqc == "") {
              vnSeqc = 0;
           }

           f_Enviar(vnSeqc,"");
        }
      } //f_Ejecutar
      ');

      ----
      htp.p('function f_Enviar(pnSeqc,psLevel) {

      if(vgsLevel.length == 0) {

         vgsEjecuta                        = false;
         document.body.className           = "";
         vgsComa                           = "";
         document.frmRegla.txtPen1.value   = "";
         document.frmRegla.txtPend.value   = vgsLevel;
         document.frmRegla.txtConc.value   = document.frmRegla.txtConc.value + psLevel;
         document.frmEjecutar.pnSeqc.value = pnSeqc
         document.frmReporte.pnSeq.value   = document.frmEjecutar.pnSeqc.value;

         setTimeout("document.frmReporte.submit();",2000);

         return;
      }

      document.frmRegla.txtPend.value = vgsLevel;
      document.frmRegla.txtConc.value = document.frmRegla.txtConc.value + psLevel + vgsComa;

      var vsLevl = vgsLevel.substr(0, 2);

      document.frmEjecutar.pnSeqc.value = pnSeqc;
      document.frmEjecutar.psLevl.value = vsLevl;
      document.frmEjecutar.submit();

      vgsLevel = vgsLevel.substr(3);
      vgsComa  = ", ";
      } //f_Enviar
      ');

      ----
      htp.p('function f_InicializarValores() {
        if(vgsEjecuta) { return; }

        document.frmEjecutar.psTerm.value = "";
        document.frmEjecutar.psLevl.value = "";
        document.frmEjecutar.pnSeqc.value = "";
        document.frmRegla.txtPend.value   = "";
        document.frmRegla.txtConc.value   = "";
        document.frmRegla.txtPen1.value   = "";
        document.frmRegla.txtCon1.value   = "";
      } //f_InicializarValores ');

      ----
      htp.p('function f_Buscar() {
        if(vgsEjecuta) { return; }

        document.frmBuscar.submit();
      } //f_Buscar');

      htp.p('//--></script>');

      htp.p('
      </head><body bgcolor="#ffffff"><br/><br/><br/><br/><br/>
      <table border="0" width="100%" cellpadding="0" cellspacing="0">
      <form name="frmRegla" onSubmit="return false;">
      <tr><th width="60%" class="thTitulo" valign="bottom" align="left">
      <br>Reglas de repetici&oacute;n
      </th><td width="40%">
      ');

      pk_MenuAplicacion.P_MenuSalir('pk_MenuAplicacion.p_MenuAplicacion');

      htp.p('</td></tr></table>
      <hr size="1" width="100%">

      <table border="0" cellpadding="2" cellspacing="1" width="100%" bgcolor="#ffffff">
      <tr>
          <th width="10%" valign="top" align="right" bgcolor="#efefef">Periodo</th>
          <td width="40%" valign="top" bgcolor="#efefef">
              <select name="psTermCode" onChange="f_InicializarValores();"><option value=""></option>
      ');

      FOR regTerm IN cuStvTerm LOOP
          htp.p('<option value="'||regTerm.termCode||'">'||regTerm.termCode||' '||regTerm.termDesc||'</option>');
      END LOOP;

      htp.p('
      </select>
      </td>
      <td valign="top" rowspan="12">
          <iframe name="fraRegla" id="fraRegla" src="about:blank" width="100%" height="300px" frameborder="0">
          </iframe>
          </td>
          </tr>
      <tr>
          <th valign="top" align="right" bgcolor="#efefef">Nivel</th>
          <td valign="top" bgcolor="#efefef">
              <select name="psLevlCode" multiple size="10" onChange="f_InicializarValores();">
      ');

      FOR regLevl IN cuStvLevl LOOP
          htp.p('<option value="'||regLevl.levlCode||'">'||regLevl.levlCode||' - '||regLevl.levlDesc||'</option>');
      END LOOP;

      htp.p('
       </select>
      </td></tr>
      <tr><td></td>
          <td rowspan="3">
      ');

      pk_MenuAplicacion.P_MenuDinamico('"limpiar","ejecutar","buscar",','javascript:f_Limpia();,javascript:f_Ejecutar();,javascript:f_Buscar();,','"Limpiar","Ejecutar","Reporte",');

      htp.p('
          </td>
          </tr>
      <tr><td></td></tr>
      <tr><td></td></tr>

      <tr><td><input type="text" name="txtPen1" tabindex="-1" style="border:outset 0;text-align:right" readonly />
              </td>
          <td><input type="text" name="txtPend" tabindex="-1" style="border:outset 0;" readonly />
              </td>
          </tr>
      <tr><td><input type="text" name="txtCon1" tabindex="-1" style="border:outset 0;text-align:right" readonly />
              </td>
          <td><input type="text" name="txtConc" tabindex="-1" style="border:outset 0;" readonly />
              </td>
          </tr>
      <tr><td colspan="2"></td></tr>
      <tr><td colspan="2"></td></tr>
      <tr><td colspan="2"></td></tr>
      <tr><td colspan="2"></td></tr>
      <tr><td colspan="2"></td></tr>
      </form>
      </table>
      </br></br>
      <hr size="1" width="100%">
      </br>

      <form name="frmEjecutar" action="PWAREG5" target="fraRegla" method="post">
      <input type="hidden" name="psTerm" />
      <input type="hidden" name="psLevl" />
      <input type="hidden" name="pnSeqc" />
      </form>

      <form name="frmReporte" action="PWAREG8" target="fraRegla" method="post">
      <input type="hidden" name="pnSeq" />
      </form>

      <form name="frmBuscar" action="PWAREG9" target="_top" method="post">
      <input type="hidden" name="pnBuscar" value="FIND" />
      </form>

      </body>
      </html>');
  END PWAREGL;
/


DROP PUBLIC SYNONYM PWAREGL;

CREATE PUBLIC SYNONYM PWAREGL FOR BANINST1.PWAREGL;


GRANT EXECUTE ON BANINST1.PWAREGL TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREGL TO WWW2_USER;

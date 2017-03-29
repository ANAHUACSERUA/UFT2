DROP PROCEDURE BANINST1.PWATABS;

CREATE OR REPLACE PROCEDURE BANINST1.PWATABS(psTitulos VARCHAR2,
                                             psNames   VARCHAR2
                                            ) IS

/*
   AUTOR: GEPC
   FECHA: 22/03/2010
   TAREA: Objeto para crear pestañas dinamicas.
  MODULO: GENERAL

*/

  vsTitulos VARCHAR2(500) := psTitulos;
  vsTitle   VARCHAR2(30)  := NULL;
  vnTab     INTEGER       := 0;
  vnTabSup  INTEGER       := 0;
  vnTabInf  INTEGER       := NULL;
  vnColumna INTEGER       := 2;
  vnWidTabl NUMBER        := 100;
  vnWdhTab  NUMBER        := 20;

  BEGIN
      WHILE INSTR(vsTitulos,',') > 0 LOOP
            vnTabSup  := vnTabSup + 1;
            vsTitulos := SUBSTR(vsTitulos,INSTR(vsTitulos,',') + 1);
      END LOOP;

      IF vnTabSup > 4 THEN
         vnWdhTab := ROUND(vnWidTabl/vnTabSup,2);
         vnWdhTab := vnWdhTab - 2;
      END IF;

      FOR vnI IN 1..vnTabSup LOOP
          vnWidTabl := vnWidTabl - (vnWdhTab+2);
      END LOOP;

      vsTitulos := psTitulos;
      vnTabInf  := vnTabSup;

      IF vnWidTabl > 0 THEN
         vnColumna := (vnColumna * vnTabSup) + 1;
      ELSE
         vnColumna := vnColumna * vnTabSup;
      END IF;

      htp.p('
      <script language="JavaScript"><!--
      function setTime() {
        setTimeout("f_AplicacionMenu('''||vsTitle||''')",1500);
      } //setTime

      function f_AplicacionMenu(psApliDesc) {
      f_Linea3(document.frmTab.chk1,document.frmTab.chk'||(vnTabInf+1)||');
      f_tab(1);

      window.status = psApliDesc;

      } //f_AplicacionMenu
      //--></script>
      ');

      ---###################3
      htp.p('<table border="0" cellpadding="0" cellspacing="0" width="100%">
      <form name="frmTab">
      <tr>');

      WHILE INSTR(vsTitulos,',') > 0 LOOP
            vsTitle  := SUBSTR(vsTitulos,1, INSTR(vsTitulos,',') - 1);
            vnTab    := vnTab + 1;
            vnTabInf := vnTabInf + 1;

            htp.p('
            <td width="'||vnWdhTab||'%">
                <table border="0" cellpadding="0" cellspacing="0" width="100%">
                      <tr onMouseOver="f_ClassTab(this)" onMouseOut="f_ClassTab(this)" onClick="javascript:f_Linea3(document.frmTab.chk'||vnTab||',document.frmTab.chk'||vnTabInf||'); f_tab('||vnTab||'); f_ClassTab(this); eventoTAB('||vnTab||'); displeyTitle('''||vsTitle||''')" class="CEL2r"><td width="5%">
                              <img src="/imagenes/SupIzq2.gif" /></td>
                          <td width="90%">
                              <input type="hidden" name="chk'||vnTab||'" tabindex="-1" />
                              '||vsTitle||'
                              </td>
                          <td width="5%">
                              <img src="/imagenes/SupDer2.gif" /></td>
                          </tr>
                </table>
            </td>
            <td width="2%"></td>
            ');

            vsTitulos := SUBSTR(vsTitulos,INSTR(vsTitulos,',') + 1);
      END LOOP;

      vsTitulos := psTitulos;

      IF vnWidTabl > 0 THEN
         htp.p('
         <td width="'||vnWidTabl||'%"></td>
         ');
      END IF;

      htp.p('
      </tr>
      <tr class="CEL0Height08">
      ');

      WHILE INSTR(vsTitulos,',') > 0 LOOP
            vnTabSup := vnTabSup + 1;

            htp.p('
            <td class="td03">
                <table border="0" cellpadding="0" cellspacing="0" width="100%">
                    <tr class="CEL2s">
                        <td class="td03"><input type="hidden" name="chk'||vnTabSup||'" tabindex="-1" />
                        </td></tr>
                </table>
            </td>
            <td class="td03"></td>
            ');

            vsTitulos := SUBSTR(vsTitulos,INSTR(vsTitulos,',') + 1);
      END LOOP;

      IF vnWidTabl > 0 THEN
         htp.p('
         <td class="td03"></td>
         ');
      END IF;

      htp.p('
      </tr>
      <tr class="CELHeightr20">
          <td colspan="'||vnColumna||'"></td>
         </tr>
      </form>
      </table>
      ');
      ---###################
      vsTitulos := psTitulos;
      vsTitle   := SUBSTR(vsTitulos,1, INSTR(vsTitulos,',') - 1);

      PK_ObjHTML.P_JavaTabsV2(psNames=>psNames);
      htp.p(
      '<script language="JavaScript"><!--
      setTime();
      //--></script>'
      );

  EXCEPTION
      WHEN OTHERS THEN
           htp.p(sqlerrm);
  END PWATABS;
/


DROP PUBLIC SYNONYM PWATABS;

CREATE PUBLIC SYNONYM PWATABS FOR BANINST1.PWATABS;

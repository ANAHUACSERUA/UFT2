DROP PROCEDURE BANINST1.PWAREG5;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG5(psTerm VARCHAR2,
                                             psLevl VARCHAR2,
                                             pnSeqc INTEGER DEFAULT 0) IS

  vnEtapa    INTEGER        := 4;
  vnSeq      INTEGER        := pnSeqc;
  vsEatapa1  VARCHAR2(200)  := 'Identificar materias repetidas por los alumnos.';
  vsEatapa2  VARCHAR2(200)  := 'Respaldo de las materias de historia acad?mica';
  vsEatapa3  VARCHAR2(200)  := 'Actualizar a \"NULL\" los campos SHRTCKN_REPEAT_COURSE_IND y SHRTCKN_REPEAT_SYS_IND';
  vsEatapa4  VARCHAR2(200)  := 'Actualizar las materias repetidas con \"I, E\"';
  vsUser     VARCHAR2(500);
vgsUSR VARCHAR2(500);
  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      --IF PK_Login.F_ValidacionDeAcceso(vsUser) THEN RETURN; END IF;
   IF Pk_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

      IF vnSeq = 0 THEN
         SELECT SQC_SWNTCKA.NEXTVAL
           INTO vnSeq
           FROM DUAL;
      END IF;

      htp.p('
      <html><head><title></title>
      ');

      pK_ObjHTML.P_CssTabs;

      PK_ObjHTML.P_NoCache;

      htp.p('<script language=''JavaScript''><!--
      javascript:window.history.forward(1);

      var vgsEatapa1 = "'||vsEatapa1||'";
      var vgsEatapa2 = "'||vsEatapa2||'";
      var vgsEatapa3 = "'||vsEatapa3||'";
      var vgsEatapa4 = "'||vsEatapa4||'";
      ');

      ----
      htp.p('function f_Etapa(pnEtapa) {
        switch(pnEtapa) {
          case 1: document.frmDescEtp1.txtEtapa1.value = vgsEatapa1;
                  break;
          case 2: document.frmDescEtp2.txtEtapa2.value = vgsEatapa2;
                  break;
          case 3: document.frmDescEtp3.txtEtapa3.value = vgsEatapa3;
                  break;
          case 4: document.frmDescEtp4.txtEtapa4.value = vgsEatapa4;
                  break;
        }

      } //f_Etapa
      ');

      ----
      htp.p('function f_Ejecucion(pnEtapa, psLevel) {
        if(pnEtapa==5) {
           vgnEjecucion = false;

           f_CompletaProgreso(pnEtapa-2);

           parent.f_Enviar('||vnSeq||',psLevel);

           return;
        }

        vgnEtapa     = (pnEtapa - 1);
        vgnObjProces = 0;

        f_Etapa(pnEtapa);

               if(pnEtapa == 1) {
                  f_Intervalo();
        } else if(pnEtapa > 1) {
                  f_CompletaProgreso(pnEtapa-2);
        }

        document.frmExecut.psLevl.value = psLevel;
        document.frmExecut.psStat.value = pnEtapa;
        document.frmExecut.submit();

        f_Ciclo();
      } //f_Ejecucion
      ');

      ----
      htp.p('function f_Ciclo() {
      setTimeout("document.frmExecut.submit()",100000);
      } //f_Ciclo
      ');

      htp.p('//--></script>');
      --
      htp.p('
      </head><body bgcolor="#ffffff" class="bodyCursorW" onLoad="f_Ejecucion(1,'''||psLevl||''');">

      <table border="0" cellpadding="1" cellspacing="1" width="100%" bordercolor="#000000" bgcolor="#ffffff">

      <tr bgcolor="#efefef">
          <th align="right">Periodo:</th>
          <td colspan="2">'||psTerm||' - '||pk_Catalogo.Periodo(psTerm)||'</td></tr>
      <tr bgcolor="#efefef">
          <th align="right" >Nivel:</th>
          <td colspan="2">'||psLevl||' - '||pk_Catalogo.Nivel(psLevl)  ||'</td></tr>
      ');

      FOR vnI IN 1..vnEtapa LOOP
          htp.p('
          <tr>
          <th width="20%" align="right">Etapa '||vnI||'</th>
          <td width="15%">
          ');

          PWAPRSS((vnI-1),6);

          htp.p('</td>
          <form name="frmDescEtp'||vnI||'" onSubmit="return false;">
          <td width="65%">
              <input type="text" name="txtEtapa'||vnI||'" tabindex="-1" style="border:outset 0;" readonly />
              </td></form></tr>
          ');
      END LOOP;

      htp.p('
      <tr><td></td>
          <td colspan="2">
               <iframe name="fraExecut" id="fraExecut" src="about:blank" width="100%" height="100px" frameborder="0">
               </iframe>
          </td></tr>
      </table>

      <form name="frmExecut" action="PWAREG6" method="post" target="fraExecut">
      <input type="hidden" name="psLevl" value="'||psLevl||'" />
      <input type="hidden" name="psTerm" value="'||psTerm||'" />
      <input type="hidden" name="pnSeq"  value="'||vnSeq ||'" />
      <input type="hidden" name="psUser" value="'||vgsUSR||'" />
      <input type="hidden" name="psStat" />
      </form>



      </body>
      </html>
      ');

  END PWAREG5;
/


DROP PUBLIC SYNONYM PWAREG5;

CREATE PUBLIC SYNONYM PWAREG5 FOR BANINST1.PWAREG5;


GRANT EXECUTE ON BANINST1.PWAREG5 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG5 TO WWW2_USER;

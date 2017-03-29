DROP PROCEDURE BANINST1.PWAPRSS;

CREATE OR REPLACE PROCEDURE BANINST1.PWAPRSS(pnPrss  INTEGER,
                                  pnBarra INTEGER DEFAULT 10) IS

  BEGIN
      IF pnPrss = 0 THEN
         htp.p('<style type="text/css"><!--
         .proceso0 {background-color:#ffffff;}
         .proceso1 {background-color:#5992BE;}
         .proceso2 {background-color:#FFFFE5;}
         --></style>

         <script language=''JavaScript''><!--
         var vgnObjProces = 0;
         var vgnEtapa     = 0;
         var vgnEjecucion = true;

         function f_ColorProgreso(object, pnAccion) {
           var objNode = object.parentNode;

           if(pnAccion==1){
              objNode.className = "proceso2";
              return;
           }

           if (objNode.className == "proceso0") {
               objNode.className = "proceso1";
           } else {
               objNode.className = "proceso0";
           }

         } //f_ColorProgreso

         function f_Intervalo() {
           setTimeout("f_Progreso()",200);
         }//f_Intervalo

         function f_Progreso() {
           var objTxt = null;

           if(!vgnEjecucion) { return false; }

           if(vgnObjProces < '||pnBarra||') {
              objTxt = eval("document.frmObjeto" + vgnEtapa + ".proceso" + vgnObjProces);
              f_ColorProgreso(objTxt,0);
           }

           vgnObjProces++;

           if(vgnObjProces > '||(pnBarra+1)||') {
              vgnObjProces = 0;

              for(vnI=0; vnI<'||pnBarra||'; vnI++) {
                  objTxt = eval("document.frmObjeto" + vgnEtapa + ".proceso"+vnI);
                  f_ColorProgreso(objTxt,0);
              }
           }

           f_Intervalo();
         } //f_Progreso

         function f_CompletaProgreso(pnEtapa) {

           for(vnI=0; vnI<'||pnBarra||'; vnI++) {
               objTxt = eval("document.frmObjeto" + pnEtapa + ".proceso"+vnI);
               f_ColorProgreso(objTxt,1);
           }

         } //f_CompletaProgreso

         //--></script>
          ');
      END IF;

      htp.p('
      <table border="0" cellpadding="0" cellspacing="0" width="100%">
      <form name="frmObjeto'||pnPrss||'">
        <tr>
      ');

      FOR vnI IN 0..(pnBarra-1) LOOP
          htp.p('
          <td width="10%" class="proceso0" align="right">
              <img src="/imagenes/progreso.gif" border="0" /><input type="hidden" name="proceso'||vnI||'"/></td>
          ');
      END LOOP;

      htp.p('
        </tr>
      </form>
      </table>
      ');


  END PWAPRSS;
/


DROP PUBLIC SYNONYM PWAPRSS;

CREATE PUBLIC SYNONYM PWAPRSS FOR BANINST1.PWAPRSS;

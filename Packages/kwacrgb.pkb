CREATE OR REPLACE PACKAGE BODY BANINST1.KWACRGB IS

/*
modificaicon     md-01
                       se corrige para que muestre la bitacora correcta
autor                roman ruiz
fecha                05-feb-2016

----------------------------------------
modificaicon     md-02
                     se adiciona la fecha de ejecucion para que solo pase vacia 
                     y quede  con el cambio de de kwacrgm
autor                roman ruiz
fecha                31-oct-2016

*/


  csImagenes     CONSTANT VARCHAR2(60)  := '"menu","sali",';
  csAcciones     CONSTANT VARCHAR2(200) := 'pk_MenuAplicacion.p_MenuAplicacion, javascript:paginaSalir();,';
  csOpciones     CONSTANT VARCHAR2(60)  := '"Menu Aplicaciones","Salir",';





  --controlAvance
  procedure controlAvance(psAccion    varchar2,
                          pnSecuencia number,
                          psError     varchar2 default null
                         ) IS

  csError     constant varchar2(4000) := psError;
  cnSecuencia constant number         := pnSecuencia;

  begin
      if    psAccion = 'I' then
            insert into GWRPROC
            (GWRPROC_seqn_numb, GWRPROC_proceso)
            values
            (cnSecuencia,       'PROCESO');

      elsif psAccion = 'U' then
            update GWRPROC
               set GWRPROC_date_end  = sysdate,
                   GWRPROC_error     = csError
             where GWRPROC_seqn_numb = cnSecuencia;

      end if;

      commit;

  end controlAvance;

  --Inicio
  PROCEDURE Inicio(psParametro VARCHAR2 DEFAULT NULL  ) IS


  procedure seguridad is

  begin
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
  end seguridad;

  --código java script
  --js
  procedure js is

  begin
      htp.p(
      '
      <!-- <script language="javascript" src="kwatime.js?psMensaje=La pagina se est&aacute; cargando.<br/>Espera un momento por favor..."></script> -->
      <script language="javascript" src="kwatime.js?psMensaje=Cargando..."></script>
      <script type="text/javascript">
      <!--
      javascript:window.history.forward(1);
      ');

      --ejecutaDepuracion
      htp.p(
      'function ejecutaProceso() {

       document.getElementById("fontMsgTIme").innerHTML = "Ejecutando proceso...";

       //la función esta declarada en "kwatime.js"
       iniciaVentana();

       document.frmProceso.submit();

      } //ejecutaProceso
      '
      );

      --cicloVerificador
      htp.p(
      'function cicloVerificador(pnSecuencia) {
        document.frmProceso.pnSecuencia.value = pnSecuencia;

        setTimeout("document.frmProceso.submit();",10000);

      } //cicloVerificador
      ');

      -- cicloTerminado
      htp.p(
      'function cicloTerminado(){
         vgsTime = "";

         document.getElementById("divOculta").className  = "tamW0";
         document.getElementById("fraProceso").className = "tamW1"

           document.getElementById("fraProceso").src       = "KWACRGB.proceso";

           document.getElementById("divMensaje").innerHTML = "<CENTER><B><FONT COLOR=''#0000AA''>CARGA DE ARCHIVO CONCLUIDA ---</FONT></B></CENTER>";

         procesoTerminado();

          //  alert(document.getElementById("p_nombre_file").value);
           document.frmbitacora.submit(); //  aca en el submit ya se va el pkt a ejecutar ya con el valor del parametro p_nombre_file

         return;
       }//cicloTerminado
      ');

      --procesoTerminado
      htp.p(
      'function procesoTerminado()
      {

        //la función esta declarada en "kwatime.js"
        setTimeout("closeWindowTime();",1000);

        return;

         }//procesoTerminado

      ');

      --loadArchivo
      htp.p(
      'function loadArchivo(pnSecuencia, psText) {

          document.frmInserta.pnSecuencia.value = pnSecuencia;

          document.getElementById("fraProceso").className = "tamW0";
          document.getElementById("divOculta").className  = "tamW1";

          document.getElementById("divMensaje").innerHTML   = "";
          document.getElementById("fontMsgTIme").innerHTML  = "Realizando la carga del archivo: "+psText;
          //la funcion esta definida en "kwatime.js"
          iniciaVentana();

          document.frmInserta.submit();

      } //loadArchivo'
      );


      htp.p('

      setTimeout("procesoTerminado()",2000);
      -->
      </script>'
      );
  end js;

  --parametros
  procedure parametros is

  begin

     --pk_MenuAplicacion.P_MenuSalir('pk_MenuAplicacion.p_MenuAplicacion');
  --style="position:absolute;z-index:5;top:30%;left:42%;visibility:visible"
      htp.p('
     <style type="text/css">
     <!--
      div.tamW0 {visibility:hidden;}
      div.tamW1 {visibility:visible;}
     -->
     </style>

      <iframe name="fraProceso" id="fraProceso" src="KWACRGB.proceso" class="tamW1" frameborder="0" tabindex="-1" scrolling="no">
      </iframe>

      <div id="divOculta" class="tamW0" >
         <table width="40%" border="0" cellpadding="2" cellspacing="1" align="center">
              <tr><td width="100%" bgcolor="efefef">
                      <input type="file" name="name" id="fileName" style="width:100%;" DISABLED/>
                  </td>
              </tr>
              <tr><td align="right">
                      <input type="button" value="Carga ArchivoA" class="btnAA" style="width:100pt;" tabindex="-1" DISABLED/>
                  </td>
               </tr>
         </table>
      </div>

      <div id="divMensaje"></div>

      <form name="frmInserta" id="frmInserta" onSubmit="false" method="post" target="fraInserta" action="KWACRGB.inserta">

         <input type="hidden" name="pnSecuencia" id="pnSecuencia" value=+psText>
      </form>

      <form name="frmProceso" id="frmProceso" onSubmit="false" method="post" target="fraInserta" action="KWACRGB.proceso">
         <input type="hidden" name="pnSecuencia" id="pnSecuencia" value="">
      </form>

      <iframe name="fraInserta" id="fraInserta" src="aboutBlank" width="0pt" height="0pt" frameborder="0" tabindex="-1" scrolling="no">
      </iframe>

  <!--aaca mando ejecutar el proceso bitacora y el campo p_nombre_file es su parametro que al nicio va vacio-->

    <form name="frmbitacora" id="frmbitacora" onSubmit="false" method="post" target="_self" action="KWACRGB.Bitacora">
       <input type="hidden" name="p_nombre_file" id="p_nombre_file" value="" >
    </form>

      '
      );
  end parametros;

  BEGIN
      kwatitl.titulo(
      'Carga de archivos CAE',
      csImagenes,
      csAcciones,
      csOpciones,
      psCancelMnu=>'Y',
      psHeight   =>'50pt',
      psWidth    =>'100%'
      --psEventBody=>'onLoad="javascript:inicializaPagina();"'
      );

      --código java script
      js();

      parametros();

      pk_objhtml.CLOSED;  --MD-01

  END Inicio;

  ---proceso
  PROCEDURE proceso(pnSecuencia NUMBER DEFAULT NULL) IS

  vdTimeIni   DATE   := NULL;
  vdTimeFin   DATE   := NULL;
  vnSecuencia NUMBER := 0;

  cnSecuencia constant number := pnSecuencia;

  --Página que ejecuta el siguiente proceso o lo finaliza
  --finProceso
  procedure finProceso is



  begin

     htp.p('
      <html><head><title>SiguienteEtapa</title>

      <script type="text/javascript">
      <!--
      javascript:window.history.forward(1);
      ');

      htp.p('
      -->
      </script>

      <style type="text/css">
      <!--
      body.bodyCero    {margin-left: 0pt; margin-right: 0pt; margin-top: 0pt;margin-bottom: 0pt;}
      -->
      </style>

      </head>
      <body bgcolor="#ffffff" class="bodyCero" onLoad="parent.cicloTerminado();">
      <center>

      EL PROCESO A TERMINADO DE EJECUTARSE.<br/>
      return;
      </center>
      </body>
      </html>
      ');



  end finProceso;

  --Pagina que se presenta durante la ejecución del proceso
  --Ciclo
  procedure Ciclo is

  begin
      htp.p('
      <html><head><title>Ciclo</title>

      <script type="text/javascript">
      <!--
      javascript:window.history.forward(1);
      -->
      </script>

      </head>
      <body bgcolor="#ffffff" onLoad="parent.cicloVerificador('||cnSecuencia||');">
      Ciclo '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')||'

      </body>
      </html>
      ');

  end Ciclo;



  --Página que se presenta al inicio del proceso
  --Inicio
  procedure Inicio is

  csCamp      CONSTANT VARCHAR2(6) := F_CONTEXTO();
  csUrlDestin CONSTANT VARCHAR2(300) := FWAURLL('DESTINO');
  csUrlOrigen CONSTANT VARCHAR2(300) := FWAURLL('ORIGEN');

  begin

      htp.p('
      <html><head><title>Inicio</title>
      <link rel="stylesheet" href="kwtabcss.css" type="text/css">

      </head>
      <body bgcolor="#ffffff" class="bodyCero">
      ');
      --pk_MenuAplicacion.P_MenuSalir('pk_MenuAplicacion.p_MenuAplicacion');
      -- md-02 se adiciona pstxtfecha   
       htp.p('
      <form name="frmEjecutaProceso" id="frmEjecutaProceso" method="post" target="fraProceso" enctype="multipart/form-data">
      <table width="80%" border="0" cellpadding="1" cellspacing="1" align="center">
      <tr>
         <input type="hidden" name="pstxtFecha"  id="pstxtFecha"  value="">
      </tr>
      <tr>
          <td class="etiqueta" valign="middle" style="font-size:12px" width="30%">
              Seleccione Tipo de Carga :
          </td width="30%">
          <td class="etiqueta" valign="left" >
              <select name="psAplicacion" style="width:300px" id="psAplicacion">

                     <OPTION VALUE="loadK">Carga CAE Fuas</OPTION>
                     <OPTION VALUE="loadL">Carga CAE Preseleccionados</OPTION>
                     <OPTION VALUE="loadM">Carga CAE Renovantes Historicos</OPTION>
                     <OPTION VALUE="loadN">Carga CAE Oficial Ingresa</OPTION>
                     <OPTION VALUE="loadO">Carga CAE Fianza Bancos</OPTION>
                     <OPTION VALUE="loadP">Carga CAE Pagos Bancos</OPTION>
              </select>
           </td>
        </tr>
        <tr>
            <td class="etiqueta" valign="middle" style="font-size:12px" width="30%">
              Seleccione el Archivo a cargar:
            </td width="30%">
           <td>
             <input type="file" name="name" id="fileName" style="width:400px" />
           </td>

           <td align="right">

              <input type="button" value="Carga ArchivoB" onClick="cargaArchivo();" class="btnAA" style="width:100pt;" />

          </td>

        </tr>
        <tr>

               <!--       <input type="file" name="name" id="fileName" style="width:100%;" />  -->
              <input type="hidden" name="psCamp"       id="psCamp"       value="'||csCamp||'">
              <input type="hidden" name="psUrl"        id="psUrl"        value="">
              <input type="hidden" name="psUser"       id="psUser"       value="'||user||'">
              <input type="hidden" name="pnSecuencia"  id="pnSecuencia"  value="">

        </tr>

         <!--     <input type="hidden" name="psAplicacion" id="psAplicacion" value="CARGA">  -->



      </table>

      </form>



      <script type="text/javascript">
      <!--
      javascript:window.history.forward(1);

      var objSecuencia = document.frmEjecutaProceso.pnSecuencia;
      var objFile      = document.frmEjecutaProceso.name;
      var vgnSecuencia = "'||vnSecuencia||'";

      ');

      --cargaArchivo
      htp.p('
      function cargaArchivo() {
        var vsText = objFile.value;

        objSecuencia.value = vgnSecuencia;

        document.frmEjecutaProceso.action       = "'||csUrlDestin||'";
        document.frmEjecutaProceso.psUrl.value  = "'||csUrlOrigen||'";
     parent.loadArchivo(vgnSecuencia, vsText);

   //child.document.frmbitacora.p_nombre_file.value    =vsText;
         parent.document.getElementById("p_nombre_file").value=vsText;   //  ESTA ES LA LINEA CORRECTA PASA EL VALOR AL PARAMETRO DE BITACORA
     //  alert(parent.document.getElementById("p_nombre_file").value);
      //  alert(document.getElementById("fileName").value);

      } //cargaArchivo
      ');

      --ejecutaCargaArchivo
      htp.p('
      function ejecutaCargaArchivo() {
        document.frmEjecutaProceso.submit();

        parent.cicloVerificador(vgnSecuencia);
      } //ejecutaCargaArchivo

      -->
      </script>
      </body>
      </html>
      ');

  end Inicio;

  BEGIN




      BEGIN

          SELECT GWRPROC_DATE_BEGIN,
                 GWRPROC_DATE_END
            INTO vdTimeIni,
                 vdTimeFin
            FROM GWRPROC
           WHERE GWRPROC_SEQN_NUMB = cnSecuencia;

      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               vdTimeIni := NULL;
               vdTimeFin := NULL;
          WHEN OTHERS THEN
               vdTimeIni := NULL;
               vdTimeFin := NULL;
      END;

      IF vdTimeFin IS NOT NULL THEN



          finProceso();


         RETURN;
      END IF;

      IF vdTimeIni IS NOT NULL AND vdTimeFin IS NULL THEN
         ciclo();

         RETURN;
      END IF;

      IF vdTimeFin IS NULL THEN
         SELECT SEQ_GWRPROC.NEXTVAL
           INTO vnSecuencia
           FROM DUAL;

         inicio();
      END IF;

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);
  END proceso;

  PROCEDURE ejecutaProceso(pnSecuencia NUMBER) IS

  BEGIN
      htp.p('EJECUTANDO PROCESO: '||TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));

      controlAvance('U', pnSecuencia);
  END ejecutaProceso;

  --inserta
  PROCEDURE inserta(pnSecuencia NUMBER) IS

  BEGIN
      controlAvance('I', pnSecuencia);
       htp.p('
      <html><head><title>Inicio</title>
      <script type="text/javascript">
      <!--
      javascript:window.history.forward(1);

      parent.fraProceso.ejecutaCargaArchivo();

      -->
      </script>

      </head>
      <body>
      </body>
      </html>
      ');
  END inserta;

 procedure Bitacora(p_nombre_file varchar2 )  is
 /*
 este es el procedimiento que se encarga de cargar la bitacora de carga al finalizar todo el procedimiento de carga
*/

-- md-01 start
/*
cursor cu_datos1( vnombre  varchar2)   is
select distinct(GWBAACR_NOMBRE_ARCHIVO) nombre,
           GWBAACR_NUM_REGISTROS  numreg,
           GWBAACR_TAMANO              tam,
           substr(GWBAACR_HASH_SHA1,1,100)       firma,
           GW.GWBAACR_NUM_PROCESO  numfile,
           GW.GWBAACR_TIPO            typefile,
           max(gw.gwbaacr_activity_date)          fecha_carga
FROM   GWBAACR gw
where   gwbaacr_Nombre_archivo  LIKE ('%'|| vnombre||'%')
 and  trunc(gwbaacr_activity_date) = trunc(sysdate)
 group by GWBAACR_NOMBRE_ARCHIVO,  GWBAACR_NUM_REGISTROS,  GWBAACR_TAMANO  ,  GWBAACR_HASH_SHA1, GW.GWBAACR_NUM_PROCESO ,  GW.GWBAACR_TIPO
 ;
 */

    cursor cu_datos1( vnombre  varchar2)   is
          select  GWBAACR_NOMBRE_ARCHIVO      nombre,
                     GWBAACR_NUM_REGISTROS    numreg,
                     GWBAACR_TAMANO           tam,
                     GWBAACR_HASH_SHA1        firma,
                     GW.GWBAACR_NUM_PROCESO   numfile,
                     GW.GWBAACR_TIPO          typefile,
                     gw.gwbaacr_activity_date fecha_carga
          FROM   GWBAACR gw
          where   gwbaacr_Nombre_archivo LIKE ('%'|| vnombre||'%')
          order by gwbaacr_activity_date   desc ;

 --md-01 end

--cursor  cu_registros( numfile  number, typefile  varchar2  ) is
--select COUNT(TWRAACP_RESULT) CUENTA, DECODE(TWRAACP_RESULT, 'A','Aprobado','R','Rechazado','E','Error','W', 'inconsistente','U','Alumno no es UFT') as  tipo
--FROM   TWRAACP
--where twraacp_file_num = numfile
--and  twraacp_file_type = typefile
--GROUP BY TWRAACP_RESULT
--order by 1;

   cursor  cu_registros( numfile  number, typefile  varchar2  ) is
         select COUNT(TWRAACP_RESULT) CUENTA, DECODE(TWRAACP_RESULT, 'A','Aprobado','R','Rechazado','E','Error','W', 'inconsistente','U','NoUft',   'X', 'Repetido') as  tipo
         FROM   TWRAACP
         where twraacp_file_num = numfile
         and  twraacp_file_type = typefile
         GROUP BY TWRAACP_RESULT
         order by 1;

CURSOR CU_ERROR (pscoderr  varchar2) is
select  GWRERRO_NOMBRE_ARCHIVO conomar, GWRERRO_CODE  coerro, GWRERRO_MENSAJE  mesgerro ,max(GWRERRO_ACTIVITY_DATE) fecheero
from GWRERRO
WHERE  GWRERRO_NOMBRE_ARCHIVO like  ('%'|| pscoderr ||'%')
AND trunc(GWRERRO_activity_date) = trunc(sysdate)
group by GWRERRO_NOMBRE_ARCHIVO, GWRERRO_CODE, GWRERRO_MENSAJE;

vserrcode   varchar2(4);
vsmenerr   varchar2(800);
vsconomar   varchar2(200);
vsnombre   varchar2(200);
vsnumreg    number;
vstama      number;
vsfirma      varchar2(100);
vsnumfile   number;
vstipfile   varchar2(4);
vscontador    number;
vsdetalle   varchar2(100);
vsfechcarga  varchar2(100);

varpaso    varchar2(1):= 'S';

 psArchivo       varchar2(100);
vsNameArchivo  varchar2(100);
 vsalida      varchar2(3000);
vmensajerr  varchar2(500);


function recorta(psnombre  varchar2)  return varchar2  is

  l_frase VARCHAR2 (32766) ;
  lpos    number:=0;
lpos2    number :=0;
conta   number := 1;
tamcan  number;

begin

l_frase  :=  psnombre;
  tamcan :=  length(l_frase);
 ------me trae la posicion donde encuentra el simbolo"\" o el que le ponga
   ---  DBMS_OUTPUT.put_line ('primer posicion encontrar  | '||lpos);
 --DBMS_OUTPUT.put_line ('tamaño  | '||tamcan);

FOR x IN  1..tamcan LOOP
  lpos := (INSTR(l_frase, '\'));
      -- Instrucciones
 --  DBMS_OUTPUT.put_line ('la posicion es ; '|| lpos);


 --DBMS_OUTPUT.put_line ('AA '|| SUBSTR(l_frase,1, lpos-1));

 IF  lpos  < 1  then
  exit;
  else

 --DBMS_OUTPUT.put_line ('AA '||SUBSTR(l_frase,conta,4 )||'--'|| conta );
 --DBMS_OUTPUT.put_line ('AA '||SUBSTR(l_frase,conta,lpos )||'--'|| conta );
     l_frase := SUBSTR(l_frase,lpos+1,tamcan );
   --  DBMS_OUTPUT.put_line ('RR '||l_frase||'--'|| conta);
   --  DBMS_OUTPUT.put_line ('el contador es:  '||conta);
    -- DBMS_OUTPUT.put_line ('-----------------------------------------');
 --insert into Swrpaso values(conta, (SUBSTR(l_frase,conta,4 )));
 conta := conta +lpos ;
 -- lpos := lpos + 5;
 end if;
    END LOOP;

    return(l_frase);

end recorta;



  begin

   kwatitl.titulo(
      'Bitacora de Carga',
      NULL,
      NULL,
      NULL,
      psCancelMnu=>'Y',
      psHeight   =>'50pt',
      psWidth    =>'100%'

      );
 ---IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

  --- vmensajerr  := 'PROBLEMAS AL CARGAR EL ARCHIVO PUEDE QUE ESTE DUPLICADO';

 htp.p('
      <html><head><title>Bitacora de Carga</title>
         <center>
         <BODY BGCOLOR="#ff0000">
      ');

     ---  insert into swrpaso values ('bitacora', p_nombre_file );  commit;
  ----      insert into swrpaso values ('bitacora mejorada ANTES DE RECORTA   ', p_nombre_file );  commit;
     vsNameArchivo := recorta(p_nombre_file);
   ----    insert into swrpaso values ('bitacora mejorada    ', vsNameArchivo );  commit;


          ------curosr  de tipo de alumno
          --md-01 start
--      OPEN cu_datos1(vsNameArchivo );
--      FETCH cu_datos1
--       INTO vsnombre,vsnumreg,vstama, vsfirma,vsnumfile, vstipfile,vsfechcarga  ;
--      IF cu_datos1%NOTFOUND THEN
--         null;
--         varpaso := 'N';
--         insert into swrpaso values ('bitacora DATOS 1', varpaso );  commit;
--         --EXIT;
--      END IF;

         varpaso := 'N';
         for curArch in cu_datos1(vsNameArchivo ) loop
             vsnombre := curArch.nombre;
             vsnumreg := curArch.numreg;
             vstama := curArch.tam;
             vsfirma := curArch.firma;
             vsnumfile := curArch.numfile;
             vstipfile := curArch.typefile;
             vsfechcarga := curArch.fecha_carga;
            varpaso := 'S';
            exit;
         end loop;

     --md-01 end


  --- insert into swrpaso values ('bitacora DATOS2  ', varpaso );  commit;

          IF  varpaso = 'S' THEN
            /*         md-01 start
             htp.p(' <TABLE BORDER=3 BORDERCOLOR="#0099CC" CELLPADDING=5>
                      <TR><td>Nombre Archivo:  '||'<td>'|| vsnombre || ' <br><tr>
                              <td>Numero de registros: '||'<td>'||  vsnumreg || ' <br> <tr>
                              <td>Tamaño: '||'<td>'||  vstama || ' <br><tr>
                              <td>Firma: '||'<td>'||  vsfirma || ' <br><tr>
                              <td>Fecha Carga: '||'<td>'||   vsfechcarga || ' <br><tr>
                       </tr></td>
                        </tr> ');
              */
              htp.p(' <TABLE BORDER=3 BORDERCOLOR="#0099CC" CELLPADDING=5>
                         <tr> <td>Nombre Archivo:  </td> <td>'|| vsnombre || ' </td> </tr>
                         <tr> <td>Numero de registros: </td> <td>'||  vsnumreg || ' </td> </tr>
                         <tr> <td>Tamaño: </td> <td>'|| vstama || ' </td> </tr>
                         <tr> <td>Firma:  </td> <td>'|| vsfirma || ' </td> </tr>
                         <tr> <td>Fecha Carga: </td> <td>'||   vsfechcarga || ' </td> <tr>
                       </TABLE>
                       ');

          ELSE
            htp.p(' <H5> PROBLEMAS AL CARGAR EL ARCHIVO FAVOR DE REVISAR <H5> ');

                    for regerr  in   CU_ERROR(vsnombre)  loop
                        vserrcode    :=   regerr.coerro ;
                        vsmenerr    :=   regerr.mesgerro ;
                        vsconomar  :=  regerr.conomar;
                    end loop;
            htp.p(' <tr> <td>Mensaje de Error :  </td> <td> '||vsconomar||' </td> <td>  '||vserrcode||' </td> <td> '||vsmenerr||' </td></tr> ');

          END IF;

          htp.p(' <TABLE BORDER=3 BORDERCOLOR="#0099CC" CELLPADDING=5> ');
          for regcount  in   cu_registros(vsnumfile,vstipfile)  loop
             vscontador    :=   regcount.cuenta ;
             vsdetalle      :=  regcount.tipo ;
             htp.p('<tr> <td> Numero de Registros: </td> <td>'||vsdetalle||'</td> <td>'||vscontador||'</td></tr>');
          end loop;
          htp.p('</table> ');

        --          htp.p(' <TABLE BORDER=3 BORDERCOLOR="#0099CC" CELLPADDING=5> ');
        --          for DetReg in cur_DetReg(vsnumfile,vstipfile)  loop
        --             htp.p('<tr> <td> ' || DetReg.reg  || ' : ' ||  DetReg.msg  || ' </td> </tr>');
        --          end loop;
        --          htp.p('</table> ');



     --htp.p(' </TD></TR>            </TABLE>');


    --md-01 end

     htp.p(' <P> <A HREF="KWACRGB.Inicio"> REGRESA MENU </A> </p>
             </center>
             </body>
             </html> ');

    pk_objhtml.CLOSED;  --MD-01


  exception
      when others then
                vsalida := ('Error: '||vmensajerr || '. ' || (sqlerrm));
        RAISE;
  end Bitacora;
END KWACRGB;
/

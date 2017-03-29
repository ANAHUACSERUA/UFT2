CREATE OR REPLACE PACKAGE BODY BANINST1.kwasmrbcmp is

/*
           TAREA: Verifica la ejecución del proceso de CAAP masivo (SMRBCMP)
          MODULO: Cierre de semestre
           FECHA: 01/08/2013
           AUTOR: GEPC

    MODIFICACION: 26/09/2013
                  GEPC
                  * Se quita el filtro "and STATUS  = csACTIVE" del cursor "cuProcesos" y de la función "ejecucionProceso"

                    Por que durante la ejecución del CAPP la sesión cambia a "INACTIVE" y
                    esto causa problemas en la verificación del proceso.


*/

  cn0          CONSTANT NUMBER(1)    := 0;
  cn1          CONSTANT NUMBER(1)    := 1;
  cn4000       CONSTANT NUMBER(4)    := 4000;
  csEsp        CONSTANT VARCHAR2(1)  := ' ';
  csCampCode   CONSTANT VARCHAR2(6)  := f_contexto();
  csSMRBCMP    CONSTANT VARCHAR2(7)  := 'SMRBCMP';
  csSMRCMPL    CONSTANT varchar2(7)  := 'SMRCMPL';
  csDDMMYYYY24 CONSTANT VARCHAR2(21) := 'DD/MM/YYYY HH24:MI:SS';

  --REGISTRA EL AVANCE DEL PROCESO
  PROCEDURE ControlAvance(psOneu   VARCHAR2,
                          psUser   VARCHAR2,
                          psDate   VARCHAR2,
                          psAccion VARCHAR2,
                          psUserID VARCHAR2,
                          pnAudSid NUMBER,
                          psCodErr VARCHAR2 DEFAULT NULL
                         );

  --Inicio
  PROCEDURE Inicio(psParametro VARCHAR2 DEFAULT NULL,
                   pnBusca     NUMBER   DEFAULT 0
                  ) IS

  csImagenes  CONSTANT VARCHAR2(100) := '"ejecutar","menu","sali",';
  csAcciones  CONSTANT VARCHAR2(200) := 'javascript:f_Ejecutar();,pk_MenuAplicacion.p_MenuAplicacion, javascript:paginaSalir();,';
  csOpciones  CONSTANT VARCHAR2(100) := '"Consultar","Men&uacute; de aplicaciones","Salir",';

  --parametros
  procedure parametros is

  vnExists INTEGER       := 0;

  csAst       constant varchar2(1)  := '*';
  cs01        constant varchar2(2)  := '01';
  csTysDate   constant date         := TRUNC(SYSDATE);
  csTysDate_1 constant date         := TRUNC(SYSDATE-1);

  --cuProcesos
  cursor cuProcesos is
         select c.gwbprun_one_up_no                                as prunOneu,
                c.gwbprun_user                                     as prunUser,
                a.guriden_desc                                     as idenDesc,
                c.gwbprun_audsid                                   as prunAuds,
                (select decode(count(cn1),cn0,null,csAst)
                   from gv$session
                  where audsid     = c.gwbprun_audsid
                    and schemaname = c.gwbprun_user
                    and module     = csSMRBCMP
                )                                                  as gvSessin,
                max(to_char(c.gwbprun_activity_date,csDDMMYYYY24)) as prunDate
           from gwbprun c,
                guriden a
          where not exists                        (select null
                                                     from gwbprua
                                                    where gwbprua_one_up_no  = gwbprun_one_up_no
                                                      and gwbprua_end       is not null
                                                  )
            and not exists                        (select null
                                                     from gwbprua
                                                    where gwbprua_audsid     = gwbprun_audsid
                                                      and gwbprua_end       is not null
                                                  )
            and a.guriden_activity_date         = (select max(b.guriden_activity_date)
                                                     from guriden b
                                                    where b.guriden_user_id = a.guriden_user_id
                                                  )
            and trunc(c.gwbprun_activity_date) >= csTysDate_1
            and c.gwbprun_user                  = a.guriden_user_id
            and c.gwbprun_camp_code             = csCampCode
            and c.gwbprun_number                = cs01
            and c.gwbprun_audsid               is not null
            and c.gwbprun_job                   = csSMRCMPL
          group by c.gwbprun_one_up_no,
                   c.gwbprun_user,
                   a.guriden_desc,
                   c.gwbprun_audsid
          order by c.gwbprun_one_up_no;



  begin
      htp.p(
      '
      <script type="text/javascript">
      <!--
      var vgnBusca = '||pnBusca||';
      -->
      </script>
      <script src="kwatime.js?psMensaje=La p&aacute;gina se est&aacute; generando.<br/>Espere un momento por favor..." language="javascript"></script>
      <script language="javascript" src="kwaslct.js"></script>

      <style type="text/css">
      <!--

      div.DIVtamW0 {width:0pt;
                    height:0pt;
                    overflow-x:hidden;
                    overflow-y:hidden;
                    margin:0px;
                    padding:0px;
                   }
      div.DIVtamW1 {width:100%;
                    height:180pt;
                    overflow-x:hidden;
                    overflow-y:scroll;
                    margin:0px;
                    padding:0px;
                   }
      div.DIVtamW2 {width:100%;
                    height:17pt;
                    overflow-x:hidden;
                    overflow-y:scroll;
                    margin:0px;
                    padding:0px;
                   }
      -->
      </style>

      <p>
      <table border="0" cellpadding="2" cellspacing="1" width="100%">
             <tr><td align="right">
                     <a href="javascript:Verifica();" '||
                                 'onMouseover="window.status=''Verificar status de PIPEs y gurJobs''; return true" '||
                                 'onMouseout="window.status=''; return true" '||
                                    'OnFocus="window.status=''Verificar status de PIPEs y gurJobs''; return true" '||
                                     'onBlur="window.status=''; return true" class="submenulinktext2">
                      Verificar status de PIPEs y gurJobs
                      </a>
                 </td>
                 </tr>
      </table>
      </p>

      <div id="divMonitoreo" class="DIVtamW0"></div>

      <form name="frmProcesos" id="frmEgre" onSubmit="return false;">
      <table border="0" cellpadding="2" cellspacing="1" width="100%">
      ');

      for regPrc in cuProcesos loop
          if vnExists = 0 then
             htp.p(
             '<tr bgcolor="#efefef">
             <td bgcolor="#ffffff" style="border-bottom:Solid 1px #ffffff;border-top:Solid 1px #ffffff;border-left:Solid 1px #ffffff;border-right:Solid 1px #ffffff;"></td>
             <th style="border:Solid 1px #dddddd;" colspan="2"># Proceso</th>
             <th style="border:Solid 1px #dddddd;" ># Sesion</th>
             <th style="border:Solid 1px #dddddd;" colspan="2">Usuario        </th>
             <th style="border:Solid 1px #dddddd;">Fecha y hora de inicio</th>
             <th style="border:Solid 1px #dddddd;">Fecha y hora de termino</th>
             </tr>'
             );

             vnExists := 1;
          end if;


          htp.p(
          '<tr bgcolor="#ffffff">'||
          '<td width="5%" style="border-bottom:Solid 1px #ffffff;border-top:Solid 1px #ffffff;border-left:Solid 1px #ffffff;border-right:Solid 1px #dddddd;" align="center">'||
          '<img src="/imagenes/cursando.jpg" name="imgProceso'||regPrc.prunOneu||'" value="0" border="0" >'||
          '</td>'||
          '<td width="5%" style="border-bottom:Solid 1px #dddddd;border-top:Solid 1px #dddddd;border-left:Solid 1px #ffffff;border-right:Solid 1px #ffffff;" bgcolor="#efefef" align="center">
          <input type="radio" name="psProceso" id="psProceso'||regPrc.prunOneu||'" class="chkA" onClick="setValores('||regPrc.prunOneu||','''||regPrc.prunUser||''','''||regPrc.prunDate||''','||regPrc.prunAuds||',this)" />
          </td>'||
          '<td width="10%" style="border-bottom:Solid 1px #dddddd;border-top:Solid 1px #dddddd;border-left:Solid 1px #ffffff;border-right:Solid 1px #dddddd;">'||regPrc.prunOneu||'</td>'||
          '<td width="10%" style="border-bottom:Solid 1px #dddddd;border-top:Solid 1px #dddddd;border-left:Solid 1px #ffffff;border-right:Solid 1px #dddddd;">'||regPrc.prunAuds||regPrc.gvSessin||'</td>'||
          '<td width="16%" style="border-bottom:Solid 1px #dddddd;border-top:Solid 1px #dddddd;border-left:Solid 1px #dddddd;border-right:Solid 1px #ffffff;">'||regPrc.prunUser||'</td>'||
          '<td width="24%" style="border-bottom:Solid 1px #dddddd;border-top:Solid 1px #dddddd;border-left:Solid 1px #ffffff;border-right:Solid 1px #dddddd;">'||regPrc.idenDesc||'</td>'||
          '<td width="15%" style="border:Solid 1px #dddddd;" align="center">'||regPrc.prunDate||'</td>'||
          '<th width="15%" style="border:Solid 1px #dddddd;" align="center" id="tdDateEnd'||regPrc.prunOneu||'"></th>'||
          '</tr>'
          );
      end loop;

      htp.p('
      </table>

      </form>
      <iframe name="fraVerifica" id="fraVerifica" hspace="0" vspace="0" class="tamW0" frameborder="0" tabindex="-1" src="aboutBlank" scrolling="auto">
      </iframe>



      <form name="frmVerifica" id="frmVerifica" action="kwasmrbcmp.Verifica" target="fraVerifica" method="post">
      <input type="hidden" name="psOneu" />
      <input type="hidden" name="psUser" />
      <input type="hidden" name="psDate" />
      <input type="hidden" name="pnAudSid" />
      </form>

      <form name="frmBuscaProceso" id="frmBuscaProceso" action="kwasmrbcmp.Inicio" target="_top" method="post">
      <input type="hidden" name="psParametro" />
      <input type="hidden" name="pnBusca" />
      </form>

      <script language="javascript" src="kwasmrbcmp.js"></script>'
      );

      if vnExists = 0 then
         htp.p(
         '<center>
         <b>No existen procesos para verificar su finalizaci&oacute;n.</b>
         </center>
         ');

         IF pnBusca < 5 THEN
            htp.p(
            '<center>
            <br/><br/>
            <img src="/imagenes/large_loading.gif"><br/>
            <font color="#aa0000">
            La aplicación esta buscando la existencia de procesos.<br/>
            Espere un momento por favor...
            </font>
            </center>

            <script type="text/javascript">
            <!--
            setTimeout("buscaProceso()",40000);
            -->
            </script>

            ');
         END IF;
      end if;

  end parametros;

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      kwatitl.titulo(
      '',
      csImagenes,
      csAcciones,
      csOpciones,
      psCancelMnu=>'Y',
      psEventBody=>'onLoad="javascript:inicializaPagina();"',
      psHeight   =>'40pt',
      psWidth    =>'100%'
      );

      PWAINFO('kwasmrbcmp.Inicio','INFORMACION');

      parametros;

      pk_objRuaHTML.closed;

  EXCEPTION
      WHEN OTHERS THEN
           htp.p(sqlerrm);
  END Inicio;

  --CÓDIGO JavaScript
  PROCEDURE JS IS

  BEGIN
      htp.p(
      '
      javascript:window.history.forward(1);

      var vgsEjecuta     = false;
      var vgsVerifica    = false;
      var vgsOneu        = "";
      var vgsUser        = "";
      var vgsDate        = "";
      var objFrmProcesos = document.frmProcesos;
      var objFrmVerifica = document.frmVerifica;
      var objVerifica    = null;

      imgFinaalizado     = new Image();
      imgFinaalizado.src = "/imagenes/acreditado.jpg";
      ');

      --inicializaVuelta
      htp.p(
      'function inicializaPagina() {

         setTimeout("procesoTerminado();",1500);
      } //inicializaVuelta
      ');

      -- procesoTerminado
      htp.p(
      'function procesoTerminado(){
         vgsEjecuta = false;


         if(vgsVerifica == true) {
            document.getElementById("divMonitoreo").className = "DIVtamW1";
         }

         vgsVerifica = false;

         //la funcion esta definida en "kwatime.js"
         closeWindowTime();
       }//procesoTerminado
      ');

      -- cicloTerminado
      htp.p(
      'function cicloTerminado(psDate, psOneu){
         document.getElementById("tdDateEnd" + psOneu).innerHTML = psDate;

         document["imgProceso" + psOneu].src                     = imgFinaalizado.src;

         document.getElementById("fraVerifica").className        = "tamW1";

         objVerifica.disabled = true;

         procesoTerminado();
       }//cicloTerminado
      ');

      -- setValores
      htp.p(
      'function setValores(psOneu, psUser, psDate, psAudSid, objRadio){
         vgsOneu     = psOneu;
         vgsUser     = psUser;
         vgsDate     = psDate;
         vgsAudSid   = psAudSid;
         objVerifica = objRadio;
       }//setValores
      ');

      --f_Ejecutar
      htp.p(
      'function f_Ejecutar() {
        if(vgsEjecuta) { return; }

        if(vgsOneu == "" ) {
           alert("Seleccione el proceso a verificar.");
           return;
        }

        vgsEjecuta     = true;

        document.getElementById("divMonitoreo").className = "DIVtamW0";
        document.getElementById("divMonitoreo").innerHTML = "";
        document.getElementById("fontMsgTIme").innerHTML  = "Verificando la ejecuci&oacute;n del proceso de CAAP masivo \(SMRBCMP\)";

        document.getElementById("fraVerifica").className = "tamW0";

        //la funcion esta definida en "kwatime.js"
        iniciaVentana();

        objFrmVerifica.psOneu.value   = vgsOneu;
        objFrmVerifica.psUser.value   = vgsUser;
        objFrmVerifica.psDate.value   = vgsDate;
        objFrmVerifica.pnAudSid.value = vgsAudSid;
        objFrmVerifica.submit();

      } //f_Ejecutar
      ');

      --cicloVerificador
      htp.p(
      'function cicloVerificador() {

        setTimeout("objFrmVerifica.submit();",20000);

      } //cicloVerificador
      ');

      --buscaProceso
      htp.p(
      'function buscaProceso() {
         vgnBusca = vgnBusca + 1;

         document.frmBuscaProceso.pnBusca.value = vgnBusca;
         document.frmBuscaProceso.submit();
      } //buscaProceso
      ');

      --Verifica()
      htp.p(
      'function Verifica() {
         if(vgsEjecuta) { return; }

         vgsVerifica = true;

         document.getElementById("divMonitoreo").className = "DIVtamW0";
         document.getElementById("divMonitoreo").innerHTML = "";
         document.getElementById("fontMsgTIme").innerHTML  = "Verificando status de PIPEs y gurJobs";

         //la función esta declarada en "kwatime.js"
         iniciaVentana();

         //la declaraciòn de la funciòn se encuenra en "kwaslct.js"
         getMensaje("PWAVPPG","","divMonitoreo");

      } //Verifica
      '
      );

      --closeVerifica()
      htp.p(
      'function closeVerifica() {
        document.getElementById("divMonitoreo").className = "DIVtamW0";
        document.getElementById("divMonitoreo").innerHTML = "";

        window.status="";

      } //closeVerifica
      '
      );

  END JS;

  --asignaVuelta
  PROCEDURE Verifica(psOneu   VARCHAR2,
                     psUser   VARCHAR2,
                     psDate   VARCHAR2,
                     pnAudSid NUMBER
                    ) IS

  vsError VARCHAR2(4000) := NULL;
  vdEnd     DATE         := NULL;
  vdBegin   DATE         := NULL;

  --ejecucionProceso
  function ejecucionProceso return boolean is

  vnExiste  number(4) := 0;

  begin
      select count(cn1)
        into vnExiste
        from gv$session
       where audsid     = pnAudSid
         and schemaname = psUser
         and module     = csSMRBCMP;

      return (vnExiste > cn0);

  exception
      when others then
           return true;

  end ejecucionProceso;

  --Página que ejecuta el siguiente proceso o lo finaliza
  --SiguienteEtapa
  procedure SiguienteEtapa(psDate date) is

  csArchivos constant varchar2(200) := 'smrbcmp_'||psOneu||'.lis y smrbcmp_'||psOneu||'.log';

  begin
      htp.p('
      <html><head><title>SiguienteEtapa</title>

      <script type="text/javascript">
      <!--
      javascript:window.history.forward(1);

      -->
      </script>

      <style type="text/css">
      <!--
      body.bodyCero    {margin-left: 0pt; margin-right: 0pt; margin-top: 0pt;margin-bottom: 0pt;}
      -->
      </style>

      </head>
      <body bgcolor="#ffffff" class="bodyCero" onLoad="parent.cicloTerminado('''||to_char(psDate,csDDMMYYYY24)||''','||psOneu||');">
      <center>
      EL PROCESO A TERMINADO DE EJECUTARSE.<br/>
      Solicite los archivos "'||csArchivos||'" a <a href="mailto:apoyosiu@arcol.ogr?subject=Archivos '||csArchivos||'">Apoyo SIU</a>
      </center>
      </body>
      </html>
      ');

  end SiguienteEtapa;

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
      <body bgcolor="#ffffff" onLoad="parent.cicloVerificador();">
      Ciclo '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')||'
      </body>
      </html>
      ');

  end Ciclo;

  --Página que se presenta al inicio del proceso
  --Inicio
  procedure Inicio is

  begin
      htp.p('
      <html><head><title>Inicio</title>

      <script type="text/javascript">
      <!--
      javascript:window.history.forward(1);

      parent.cicloVerificador();
      -->
      </script>

      </head>
      <body bgcolor="#ffffff">
      Inicio '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')||'
      </body>
      </html>
      ');

  end Inicio;


  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

      -- se busca si el proceso ya termino
      BEGIN
          SELECT GWBPRUA_BEGIN,GWBPRUA_END
            INTO vdBegin,      vdEnd
            FROM GWBPRUA
           WHERE GWBPRUA_ONE_UP_NO = psOneu
             AND GWBPRUA_CAMP_CODE = csCampCode
             AND GWBPRUA_USER      = psUser
             AND GWBPRUA_USER_ID   = pk_login.vgsUSR;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               vdEnd := NULL;
          WHEN OTHERS THEN
               vdEnd := NULL;
      END;

      IF NOT ejecucionProceso THEN
         controlAvance(psOneu, psUser, psDate, 'U', PK_Login.vgsUSR, pnAudSid);
      END IF;

      IF    vdEnd IS NOT NULL THEN
            --Página que ejecuta el siguiente proceso o lo finaliza
            SiguienteEtapa(vdEnd);

            RETURN;
      ELSIF vdBegin IS NOT NULL AND vdEnd IS NULL THEN
            --Pagina que se presenta durante la ejecución del proceso

            Ciclo;

            RETURN;
      END IF;

      --Página que se presenta al inicio del proceso
      Inicio;

      IF vdBegin IS NULL THEN
         controlAvance(psOneu, psUser, psDate, 'I', PK_Login.vgsUSR, pnAudSid);

      END IF;

  EXCEPTION
      WHEN OTHERS THEN
           vsError := SQLERRM;

           controlAvance(psOneu, psUser, psDate, 'O', PK_Login.vgsUSR, pnAudSid, vsError);
  END Verifica;

  --REGISTRA EL AVANCE DEL PROCESO
  PROCEDURE ControlAvance(psOneu   VARCHAR2,
                          psUser   VARCHAR2,
                          psDate   VARCHAR2,
                          psAccion VARCHAR2,
                          psUserID VARCHAR2,
                          pnAudSid NUMBER,
                          psCodErr VARCHAR2 DEFAULT NULL
                         ) IS

  BEGIN

      IF    psAccion = 'I' THEN
            INSERT INTO GWBPRUA
            (GWBPRUA_ONE_UP_NO,
             GWBPRUA_CAMP_CODE,
             GWBPRUA_USER,
             GWBPRUA_BEGIN,
             GWBPRUA_USER_ID,
             GWBPRUA_AUDSID
             )
             VALUES
             (psOneu,
              csCampCode,
              psUser,
              TO_DATE(psDate, csDDMMYYYY24),
              psUserID,
              pnAudSid
             );
      ELSIF psAccion = 'U' THEN
            UPDATE GWBPRUA
               SET GWBPRUA_END       = (SELECT MAX(SMRRQCM_COMPLY_DATE)
                                          FROM SMRRQCM
                                         WHERE SMRRQCM_USER      = psUser
                                           AND SMRRQCM_SESSIONID = pnAudSid
                                       ),
                   GWBPRUA_ERROR     = SUBSTR(GWBPRUA_ERROR||csEsp||psCodErr,cn1,cn4000)
             WHERE GWBPRUA_AUDSID    = pnAudSid
               AND GWBPRUA_ONE_UP_NO = psOneu
               AND GWBPRUA_CAMP_CODE = csCampCode
               AND GWBPRUA_USER      = psUser
               AND GWBPRUA_USER_ID   = psUserID;

      ELSIF psAccion = 'O' THEN
            UPDATE GWBPRUA
               SET GWBPRUA_END       = SYSDATE,
                   GWBPRUA_ERROR     = SUBSTR(GWBPRUA_ERROR||csEsp||psCodErr,cn1,cn4000)
             WHERE GWBPRUA_AUDSID    = pnAudSid
               AND GWBPRUA_ONE_UP_NO = psOneu
               AND GWBPRUA_CAMP_CODE = csCampCode
               AND GWBPRUA_USER      = psUser
               AND GWBPRUA_USER_ID   = psUserID;

      END IF;

      COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);

  END ControlAvance;

END kwasmrbcmp;
/
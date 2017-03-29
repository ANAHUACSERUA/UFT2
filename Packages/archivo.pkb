CREATE OR REPLACE PACKAGE BODY BANINST1.archivo IS
/*
        Tarea: Almacenar las fotos de los alumnos en (SWRFOTO)
       Modulo: General
        Fecha: 23/08/2011
        Autor: RZL

---------------------------
 Modificación:  md-01
 cambio         se hacen adecuaciones para ejecucion en UTF
 autor          Roman Ruiz
 fecha          09-jul-2014
 --------------------------
  Modificación:  md-02
 cambio         se agrega ejecucion de carga CRM
 autor          Roman Ruiz
 fecha          12-dic-2014
  --------------------------
  Modificación:  md-03
 cambio         Cambio de nombre de cargas CAE terminacion NV
 autor          Roman Ruiz
 fecha          27-ene-2016
   --------------------------
  Modificación:  md-04
 cambio         se Agrega nueva carga de movimeintos pagado Arqueo
 autor          Roman Ruiz
 fecha          13-jun-2016
 --------------------------
  Modificación:  md-05
 cambio         paso de parametro de fecha.
 autor          Roman Ruiz
 fecha          26-oct-2016
 
*/

  vgsID   VARCHAR2(2000) := NULL;
  vgnExis INTEGER        := 0;

  csCamp    CONSTANT VARCHAR2(6) := F_CONTEXTO();
  csFOTO    CONSTANT VARCHAR2(4) := 'FOTO';
  csD       CONSTANT VARCHAR2(1) := 'D';
  csI       CONSTANT VARCHAR2(1) := 'I';
  cn1       CONSTANT NUMBER(1)   := 1;
  csSysDate CONSTANT DATE        := TRUNC(SYSDATE);

  PROCEDURE BLOB_TO_CLOB_DARWIN(psArchivo VARCHAR2
                        ) IS

  vnA        NUMBER          := 0;
  vnB        NUMBER          := 0;
  vnC        NUMBER          := 1000;
  vnD        NUMBER          := 0;
  vnOffset   NUMBER          := 1;
  vClob      CLOB            := NULL;
  vrBuffer1  RAW(32000)      := NULL;
  vsBuffer2  VARCHAR2(1000)  := NULL;
  vsFila     VARCHAR2(1000)  := NULL;

  --cuBlob
  CURSOR cuBlob IS
         SELECT BLOB_CONTENT,
                ROWID
           FROM SWBFOTO
          WHERE BLOB_CONTENT   IS NOT NULL
            AND NAME         LIKE psArchivo;
  BEGIN
      FOR regBlob IN cuBlob LOOP
          SELECT PLAIN_TEXT
            INTO vClob
            FROM SWBFOTO
           WHERE ROWID = regBlob.ROWID;-- FOR UPDATE;

          vnA := DBMS_LOB.GETLENGTH(regBlob.BLOB_CONTENT);
          vnB := CEIL(vnA/vnC);

          FOR vnJ in 1..vnB LOOP
              IF (vnC*vnJ <= vnA) THEN
                  vnD := vnC;
              ELSE
                  vnD := vnA - vnC*(vnJ-1);
              END IF;

              DBMS_LOB.READ(regBlob.BLOB_CONTENT, vnD, vnOffset, vrBuffer1);

              vClob := UTL_RAW.CAST_TO_VARCHAR2(vrBuffer1);

              UPDATE SWBFOTO
                 SET PLAIN_TEXT = PLAIN_TEXT||vClob
               WHERE ROWID      = regBlob.ROWID;

              --DBMS_LOB.WRITEAPPEND(vClob, vnD, vsFila);
              vClob    := NULL;
              vnOffset := vnOffset + vnC;
          END LOOP;

          vnOffset := 1;

      END LOOP;

      COMMIT;

  END BLOB_TO_CLOB_DARWIN;
  
  PROCEDURE insertaEnTemporal(psName VARCHAR2
                             ) IS

  BEGIN
      INSERT INTO GWRARCH
      (NAME,
       MIME_TYPE,
       DOC_SIZE,
       DAD_CHARSET,
       LAST_UPDATED,
       CONTENT_TYPE,
       BLOB_CONTENT,
       PLAIN_TEXT,
       NOT_READ
      )
      SELECT
       NAME,
       MIME_TYPE,
       DOC_SIZE,
       DAD_CHARSET,
       LAST_UPDATED,
       CONTENT_TYPE,
       BLOB_CONTENT,
       PLAIN_TEXT,
       NOT_READ
        FROM SWBFOTO
       WHERE BLOB_CONTENT IS NOT NULL
         AND NAME          = psName;
  END insertaEnTemporal;
  
  PROCEDURE copiaDeTemporal(psName VARCHAR2,
                            psType VARCHAR2
                           ) IS

  BEGIN

      --IF psCamp <> csCamp THEN
        -- aplicaContextoUAN(psCamp);

         insertaEnTemporal(psName);

         --cambiaContexto(psCamp);

         INSERT INTO SWBFOTO
         (NAME,         MIME_TYPE,         DOC_SIZE,
          DAD_CHARSET,  LAST_UPDATED,      CONTENT_TYPE,
          BLOB_CONTENT, PLAIN_TEXT,        NOT_READ
         )
         SELECT
          NAME,         MIME_TYPE,         DOC_SIZE,
          DAD_CHARSET,  LAST_UPDATED,      CONTENT_TYPE,
          BLOB_CONTENT, PLAIN_TEXT,        NOT_READ
           FROM GWRARCH;

         DELETE FROM GWRARCH;
     -- END IF;

      UPDATE SWBFOTO
         SET PLAIN_TEXT   = EMPTY_CLOB(),
             SWBFOTO_TYPE = psType,
             NOT_READ     = cn1
       WHERE BLOB_CONTENT IS NOT NULL
         AND NAME          = psName;

      COMMIT;

  END copiaDeTemporal;
  PROCEDURE paginaGrde(psMnj     VARCHAR2
                      ) IS

  BEGIN
      --IF pk_login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      htp.p(
      '
      <script type="text/javascript">
      <!--
      var vsMnj = "'||psMnj||'";

      function Espera() {
        setTimeout("Time()",4000);
      } //Espera

      function Time() {
        parent.procesoConcluido(vsMnj);
      } //Time
      Espera();
      --></script>

      <center>
        <b>Espere un momento...</b>
      </center>

      ');


  END paginaGrde;
  
 PROCEDURE procesarGRDE(psName VARCHAR2,
                         psCamp VARCHAR2,
                         psUser VARCHAR2,
                         psFile VARCHAR2,
                         psUrl  VARCHAR2,
                         psType VARCHAR2
                        ) IS

  csCITA CONSTANT VARCHAR2(4)   := psType;
  csFile CONSTANT VARCHAR2(100) := '%'||psFile;

  vsError VARCHAR2(4000) := NULL;

  --busca si el archivo existe en el campus destino
  --existeArchivo
  function existeArchivo return boolean is

  vnCantidad INTEGER := 0;

  begin
      --cambiaContexto(psCamp);

      select count(cn1)
        into vnCantidad
        from swbfoto
       where upper(name)  like upper(csFile)
         and swbfoto_type    = csCITA;

      return (vnCantidad >= cn1);

  end existeArchivo;

  BEGIN
      --busca si el archivo existe en el campus destino
      IF existeArchivo() THEN
         --si existe el archivo es eliminado del campus origen
         --aplicaContextoUAN(psCamp);

         DELETE FROM SWBFOTO
           WHERE NAME         LIKE csFile
             AND LAST_UPDATED    = (SELECT MAX(LAST_UPDATED)
                                      FROM SWBFOTO
                                     WHERE NAME     LIKE csFile
                                       AND NOT_READ IS NULL
                                   )
          AND NOT_READ          IS NULL;

         COMMIT;

         paginaGrde('El archivo que intenta cargar ya fue procesado\ny no es posible cargarlo nuevamente.');

         RETURN;
      ELSE
         copiaDeTemporal(psName, csCITA);

      END IF;

      -- pasar el contenido del campo blob_content de psTipo blob de la tabla de SWBEMP1 al campo PLAIN_TEXT de tipo clob
      BLOB_TO_CLOB_DARWIN('%'||psName||'%');

    --  aplicaContextoUAN(psCamp);

      paginaGrde(NULL);

  EXCEPTION
      WHEN OTHERS THEN
           vsError := SQLERRM;

           paginaGrde(vsError);
  END procesarGRDE;

  PROCEDURE paginaFoto(psID  VARCHAR2,
                       psUrl VARCHAR2
                      );

  --OBTIENE LAS FOTOS DE LOS ALUMNOS
  PROCEDURE Foto(psID   VARCHAR2
                );

  --CODIGO JS PARA OBTENER EL URL DE LA PAGINA
  PROCEDURE Pathh;

  PROCEDURE procesarFoto(psCamp    VARCHAR2,
                         pdDate    DATE,
                         psUser    VARCHAR2,
                         psListaId OUT VARCHAR2
                        );

  --CODIGO JS PARA OBTENER EL URL DE LA PAGINA
  PROCEDURE Pathh IS

  csUrlDestin CONSTANT VARCHAR2(600) := FWAURLL('DESTINO');
  csUrlOrigen CONSTANT VARCHAR2(600) := FWAURLL('ORIGEN');

  BEGIN
      htp.p('
      <script language="JavaScript"><!--
      var vgbGuarda = true;
      javascript:window.history.forward(1);

      function f_Path() {

      if(!vgbGuarda) {
         alert(document.frmGuarda.action);
         document.frmGuarda.submit();
         return;
      }


      vgbGuarda = false;

      document.body.className         = "bodyCursorW";
      document.frmGuarda.action       = "'||csUrlDestin||'";
      document.frmGuarda.psUrl.value  = "'||csUrlOrigen||'";

      document.frmGuarda.submit();
      //alert("csUrlDestino: " + "'||csUrlDestin||'" );
      }//f_Path

      --></script>
      ');
  END Pathh;

  --APLICACIÓN PARA REGISTRAR FOTOGRAFIAS DE ALUMNOS
  PROCEDURE TeleCharger(psParametro VARCHAR2 DEFAULT NULL  ) IS

  --RZ
  csImagenes     CONSTANT VARCHAR2(60)  := '"save","menu","sali",';
  csAcciones     CONSTANT VARCHAR2(200) := 'javascript:f_Path();, pk_MenuAplicacion.p_MenuAplicacion, javascript:paginaSalir();,';
  csOpciones     CONSTANT VARCHAR2(60)  := '"Salvar","Menu Aplicaciones","Salir",';

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF; --md-01

      --RZ
      kwatitl.titulo(
     -- 'L''archiviazione di foto degli studenti ',   --md-01
      'Guarda Archivos de Fotos del Estudiante ',     --md-01
      csImagenes,
      csAcciones,
      csOpciones,
      psCancelMnu=>'Y'
      );

      htp.p('
      <script src="archivo.js"  language="javascript"></script>
      <link rel="stylesheet" href="archivo.css" type="text/css">


      <style type="text/css"><!--
      img {
        float: none;
        margin: 0;
      }

      input.archTYPE {
        font-size:9.0pt;
            float: left;
           border: inset 0;
      }
      --></style>
      ');

      --código JS
      Pathh;

      htp.p('
      </head><body>

      <table border="0" width="100%" cellpadding="0" cellspacing="0">

      </table>
      <font size="2">
      <!--Il tipo di file JPG è consentito e il nome del file deve avere il nome del file dello studente  -md-01 -->
      Tipo de Archivo JPG y el nombre del archivo tendra el ID del estudiante
      </font><br/><br/>

      <table border="0" cellpadding="0" cellpadding="0" width="90%" align="center">
      <tr><td width="50%">
              <div id="Main">
              <form name="frmGuarda" method="post" target="_top" enctype="multipart/form-data" >
              <p>
                  <input class="wwIconified" type="file" name="name" />
              </p>
              <input type="hidden" name="psCamp"       value="'||csCamp||'" />
              <input type="hidden" name="psUrl" />
              <input type="hidden" name="psUser"       value="'||pk_login.vgsUSR||'" />
              <input type="hidden" name="psAplicacion" value="'||csFOTO||'" />
              </form>
              </div>
          </td>
      </tr></table>

      <table border="0" cellpadding="0" cellpadding="0" width="90%" align="center">
      <form name="frmFotos" onSubmit="return false;">
      <tr><td width="30%"><b>Agregue Foto del Estudiante</b></td>
          <td width="60%" align="left" valign="top"><input type="text" name="txtFotos" class="archTYPE" tabindex="-1" readonly /></td>
      </tr>
      <tr><td colspan="2">(Puedes subir 20 Fotos a la vez).</td>
          </td>
      </tr>
      </form>
      </table>

      <iframe name="fraFoto" id="fraFoto" tabindex="-1" frameborder="0" width="0px" height="0px" src="about:blank" align="center" >
      </iframe>
      <br />
      ');

      --kwNotRefresh.script;

      -- PK_ObjAteneoHTML.closed;  --md-01
      pk_objhtml.CLOSED;           --md-01

  EXCEPTION
      WHEN OTHERS THEN
           htp.p(SQLERRM);

  END TeleCharger;


/*
  PROCEDURE guardaFoto(name         OWA_UTIL.ident_arr,
                       psCamp       VARCHAR2,
                       psUrl        VARCHAR2,
                       psUser       VARCHAR2,
                       psAplicacion VARCHAR2,
                       pnSecuencia  NUMBER DEFAULT NULL 
                      ) IS

  vsListaId VARCHAR2(100) := NULL;
  vnError   INTEGER       := 0;
  ---md-05 start
  vnBandera number(3)     := 0;    
  vsApliacion   varchar2(1000); 
  vdFecha   date;
  vsOverFecha varchar2(10); 
  
  --md-05 end  

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      --IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
      
      -- md-05 start
--      vnBandera :=  instr(psAplicacion, '|');      
--      if vnBandera >= 1 then 
--         vsApliacion := substr(psAplicacion, 1, vnBandera - 1 ); 
--         vdFecha     := substr(psAplicacion ,  vnBandera + 1 );   
--      else 
--        vsApliacion := psAplicacion;       
--      end if; 
      -- md-05 end; 
      

      if    psAplicacion = 'loadB' then
            htp.p('Carga colegios procedencia');
            BEGIN
                 pk_CargaCCP_NV.p_Carga(name(1),psUser);
                  KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
            EXCEPTION
                WHEN OTHERS THEN
                     HTP.P('*ERROR* colegio procedencia');
            END;

      ELSif psAplicacion = 'CARGA' then
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
      elsif psAplicacion = 'loadA' then
         begin
            pk_CargaCRM_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR Carga CRM');
         end;
      elsif psAplicacion = 'loadB' then
         begin
            pk_CargaCCP_NV.p_Carga(name(1),psUser);
               KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR Carga Colegios de procedencia');
         end;
      elsif psAplicacion = 'loadC' then
         begin
             pk_CargaPSU_NV.p_Carga(name(1),psUser);
             KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR Carga PSU');
         end;
      elsif psAplicacion = 'loadD' then
         begin
            pk_CargaPE_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR Carga Postulaciones Efectivas');
         end;
      elsif psAplicacion = 'loadE' then
         begin
            pkCargaNombreLegal_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR Carga Nombre Legal');
         end;
      elsif psAplicacion = 'loadF' then
         begin
           --pk_CargaPEC.p_Carga( name(1), psUser);
             pk_CargaPEC_NV.p_Carga( name(1), psUser);
           --  insert into swrpaso values ( 'carga PEC', psCamp ||'-*-'||psUrl||'-*-'|| psUser||'-*-'|| psAplicacion|| '-*-' ||  pnSecuencia ); commit;
           KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR* carga Pec');
         end;
      elsif psAplicacion = 'loadG' then
         begin
             --pk_CargaBChile.p_Carga( name(1), psUser);
              pk_CargaBChile_NV.p_Carga( name(1), psUser);
              KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* carga Banco Chile');
         end;
      elsif psAplicacion = 'loadH' then
         begin
           --pk_CargaPAC.p_Carga( name(1), psUser);
             pk_CargaPAC_NV.p_Carga( name(1), psUser);
           --  insert into swrpaso values ( 'carga PAC', psCamp ||'-*-'||psUrl||'-*-'|| psUser||'-*-'|| psAplicacion|| '-*-' ||  pnSecuencia ); commit;
           KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR* carga PAC');
         end;
      elsif psAplicacion = 'loadI' then
         begin
            -- insert into swrpaso values ( 'carga PAT', psCamp ||'-*-'||psUrl||'-*-'|| psUser||'-*-'|| psAplicacion|| '-*-' ||  pnSecuencia ); commit;
             -- pk_CargaPAT.p_Carga( name(1), psUser);
             pk_CargaPAT_NV.p_Carga( name(1), psUser);
             KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR* carga PAT');
         end;
      elsif psAplicacion = 'loadJ' then
         begin
             -- insert into swrpaso values ( 'carga factoring ', psCamp ||'-*-'||psUrl||'-*-'|| psUser||'-*-'|| psAplicacion|| '-*-' ||  pnSecuencia ); commit;
             -- pk_CargaFactoring.p_Carga( name(1), psUser);
             pk_CargaFactoring_NV.p_Carga( name(1), psUser, vsOverFecha );
             KWAPROCESO.ejecutaProceso(pnSecuencia);
             RETURN;
         exception
            when others then
             HTP.P('*ERROR* carga Factoring');
         end;
      elsif psAplicacion = 'loadK' then       -- cae 1.1
         begin
           --pk_Carga_CAE_Supr.p_Carga( name(1), psUser);  -- md-03
           pk_Carga_CAE_Supr_Nv.p_Carga( name(1), psUser);    --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
          exception
            when others then
             HTP.P('*ERROR* cae Fuas');
         end;
      elsif psAplicacion = 'loadL' then       -- cae 1.2
         begin
            --pk_Carga_CAE_Post.p_Carga( name(1), psUser);   --md-03
            pk_Carga_CAE_Post_Nv.p_Carga( name(1), psUser);  --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* cae Preseleccion');
         end;
      elsif psAplicacion = 'loadM' then       -- cae 1.3
         begin
            --pk_Carga_CAE_RenovaHistorico.p_Carga( name(1), psUser);  --md-03
            pk_Carga_CAE_RenovaHistoricoNv.p_Carga( name(1), psUser);   --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* cae Historico');
         end;
      elsif psAplicacion = 'loadN' then       -- cae 2.1
         begin
           --pkCaeCargaFianzaOficialIngresa.p_Carga(name(1),psUser);  --md-03
           pk_CargaCaeFianzaOfIngresaNv.p_Carga(name(1),psUser);  --md-03
           KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR* Carga Cae FOI');
         end;
      elsif psAplicacion = 'loadO' then       -- cae 2.1
         begin
            --pk_CargaCaeFianzaBancoRenova.p_Carga(name(1),psUser);  --md-03
            pk_CargaCaeFianzaBancoRenovaNv.p_Carga(name(1),psUser);  --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* cae Fianza Banco R');
         end;
      elsif psAplicacion = 'loadP' then       -- cae 1.3
         begin
            --pk_CargaCaePagosBancoRenova.p_Carga( name(1), psUser);  --md-03
            pk_CargaCaePagosBancoRenovaNv.p_Carga( name(1), psUser);  --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* cae Pagos Banco R');
         end;
      elsif psAplicacion = 'loadQ' then       -- cae 2.1
         begin
            pk_CargaAdicionalDemre_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* Carga Adicional Demrre');
         end;
      elsif psAplicacion = 'loadR' then       -- cae 2.1
         begin
            -- pk_CargaBCI.p_Carga(name(1),psUser);
            pk_CargaBCI_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* Carga Banco BCI');
         end;
      elsif psAplicacion = 'loadS' then       -- nva conta   --md-04
         begin
            -- pk_CargaBCI.p_Carga(name(1),psUser);
            pk_cargaPagosArqueo.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* Carga Pagos de Arqueo');
         end;
       ELSIF psAplicacion IN ('grdA','grdU') THEN
       begin
            procesarGRDE(name(1),psCamp,psUser,null,psUrl,psAplicacion);
       end;
         KWAPROCESO.ejecutaProceso(pnSecuencia);

         htp.p('YA TERMINE');
         return;

      end if;

      procesarFoto(psCamp, csSysDate, psUser, vsListaId);

     paginaFoto(vsListaId, psUrl);

  EXCEPTION
      WHEN OTHERS THEN
           htp.p(SQLERRM);

           paginaFoto(vsListaId, psUrl);

  END guardaFoto;
  
  */

-- md-05 start

  PROCEDURE guardaFoto(name         OWA_UTIL.ident_arr,
                       psCamp       VARCHAR2,
                       psUrl        VARCHAR2,
                       psUser       VARCHAR2,
                       psAplicacion VARCHAR2,
                       pnSecuencia  NUMBER DEFAULT NULL ,
                       pstxtFecha   varchar2 
                      ) IS

  vsListaId VARCHAR2(100) := NULL;
  vnError   INTEGER       := 0;
  ---md-05 start
  vnBandera number(3)     := 0;    
  vsApliacion   varchar2(1000); 
  vdFecha   date;
  vsOverFecha varchar2(10); 
  
  --md-05 end  

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      --IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
      
      -- md-05 start
--      vnBandera :=  instr(psAplicacion, '|');      
--      if vnBandera >= 1 then 
--         vsApliacion := substr(psAplicacion, 1, vnBandera - 1 ); 
--         vdFecha     := substr(psAplicacion ,  vnBandera + 1 );   
--      else 
--        vsApliacion := psAplicacion;       
--      end if; 
      -- md-05 end; 
      
      if pstxtFecha is not null then
       vsOverFecha :=  pstxtFecha;
      ELSE
       vsOverFecha := NULL; 
      end if;

      if    psAplicacion = 'loadB' then
            htp.p('Carga colegios procedencia');
            BEGIN
                 pk_CargaCCP_NV.p_Carga(name(1),psUser);
                  KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
            EXCEPTION
                WHEN OTHERS THEN
                     HTP.P('*ERROR* colegio procedencia');
            END;

      ELSif psAplicacion = 'CARGA' then
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
      elsif psAplicacion = 'loadA' then
         begin
            pk_CargaCRM_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR Carga CRM');
         end;
      elsif psAplicacion = 'loadB' then
         begin
            pk_CargaCCP_NV.p_Carga(name(1),psUser);
               KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR Carga Colegios de procedencia');
         end;
      elsif psAplicacion = 'loadC' then
         begin
             pk_CargaPSU_NV.p_Carga(name(1),psUser);
             KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR Carga PSU');
         end;
      elsif psAplicacion = 'loadD' then
         begin
            pk_CargaPE_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR Carga Postulaciones Efectivas');
         end;
      elsif psAplicacion = 'loadE' then
         begin
            pkCargaNombreLegal_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR Carga Nombre Legal');
         end;
      elsif psAplicacion = 'loadF' then
         begin
           --pk_CargaPEC.p_Carga( name(1), psUser);
             pk_CargaPEC_NV.p_Carga( name(1), psUser , vsOverFecha );    -- md-05
           --  insert into swrpaso values ( 'carga PEC', psCamp ||'-*-'||psUrl||'-*-'|| psUser||'-*-'|| psAplicacion|| '-*-' ||  pnSecuencia ); commit;
           KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR* carga Pec');
         end;
      elsif psAplicacion = 'loadG' then
         begin
             --pk_CargaBChile.p_Carga( name(1), psUser);
              pk_CargaBChile_NV.p_Carga( name(1), psUser , vsOverFecha);  --md-05
              KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* carga Banco Chile');
         end;
      elsif psAplicacion = 'loadH' then
         begin
           --pk_CargaPAC.p_Carga( name(1), psUser);
             pk_CargaPAC_NV.p_Carga( name(1), psUser, vsOverFecha);    -- md-05
           --  insert into swrpaso values ( 'carga PAC', psCamp ||'-*-'||psUrl||'-*-'|| psUser||'-*-'|| psAplicacion|| '-*-' ||  pnSecuencia ); commit;
           KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR* carga PAC');
         end;
      elsif psAplicacion = 'loadI' then
         begin
            -- insert into swrpaso values ( 'carga PAT', psCamp ||'-*-'||psUrl||'-*-'|| psUser||'-*-'|| psAplicacion|| '-*-' ||  pnSecuencia ); commit;
             -- pk_CargaPAT.p_Carga( name(1), psUser);
             pk_CargaPAT_NV.p_Carga( name(1), psUser , vsOverFecha );   --md-05
             KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR* carga PAT');
         end;
      elsif psAplicacion = 'loadJ' then
         begin
             -- insert into swrpaso values ( 'carga factoring ', psCamp ||'-*-'||psUrl||'-*-'|| psUser||'-*-'|| psAplicacion|| '-*-' ||  pnSecuencia ); commit;
             -- pk_CargaFactoring.p_Carga( name(1), psUser);
             pk_CargaFactoring_NV.p_Carga( name(1), psUser, vsOverFecha );   -- md-05
             KWAPROCESO.ejecutaProceso(pnSecuencia);
             RETURN;
         exception
            when others then
             HTP.P('*ERROR* carga Factoring');
         end;
      elsif psAplicacion = 'loadK' then       -- cae 1.1
         begin
           --pk_Carga_CAE_Supr.p_Carga( name(1), psUser);  -- md-03
           pk_Carga_CAE_Supr_Nv.p_Carga( name(1), psUser);    --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
          exception
            when others then
             HTP.P('*ERROR* cae Fuas');
         end;
      elsif psAplicacion = 'loadL' then       -- cae 1.2
         begin
            --pk_Carga_CAE_Post.p_Carga( name(1), psUser);   --md-03
            pk_Carga_CAE_Post_Nv.p_Carga( name(1), psUser);  --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* cae Preseleccion');
         end;
      elsif psAplicacion = 'loadM' then       -- cae 1.3
         begin
            --pk_Carga_CAE_RenovaHistorico.p_Carga( name(1), psUser);  --md-03
            pk_Carga_CAE_RenovaHistoricoNv.p_Carga( name(1), psUser);   --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* cae Historico');
         end;
      elsif psAplicacion = 'loadN' then       -- cae 2.1
         begin
           --pkCaeCargaFianzaOficialIngresa.p_Carga(name(1),psUser);  --md-03
           pk_CargaCaeFianzaOfIngresaNv.p_Carga(name(1),psUser);  --md-03
           KWAPROCESO.ejecutaProceso(pnSecuencia);
           return;
         exception
            when others then
             HTP.P('*ERROR* Carga Cae FOI');
         end;
      elsif psAplicacion = 'loadO' then       -- cae 2.1
         begin
            --pk_CargaCaeFianzaBancoRenova.p_Carga(name(1),psUser);  --md-03
            pk_CargaCaeFianzaBancoRenovaNv.p_Carga(name(1),psUser);  --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* cae Fianza Banco R');
         end;
      elsif psAplicacion = 'loadP' then       -- cae 1.3
         begin
            --pk_CargaCaePagosBancoRenova.p_Carga( name(1), psUser);  --md-03
            pk_CargaCaePagosBancoRenovaNv.p_Carga( name(1), psUser);  --md-03
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* cae Pagos Banco R');
         end;
      elsif psAplicacion = 'loadQ' then       -- cae 2.1
         begin
            pk_CargaAdicionalDemre_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* Carga Adicional Demrre');
         end;
      elsif psAplicacion = 'loadR' then       -- cae 2.1
         begin
            -- pk_CargaBCI.p_Carga(name(1),psUser);
            pk_CargaBCI_NV.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* Carga Banco BCI');
         end;
      elsif psAplicacion = 'loadS' then       -- nva conta   --md-04
         begin
            -- pk_CargaBCI.p_Carga(name(1),psUser);
            pk_cargaPagosArqueo.p_Carga(name(1),psUser);
            KWAPROCESO.ejecutaProceso(pnSecuencia);
            RETURN;
         exception
            when others then
             HTP.P('*ERROR* Carga Pagos de Arqueo');
         end;
       ELSIF psAplicacion IN ('grdA','grdU') THEN
       begin
            procesarGRDE(name(1),psCamp,psUser,null,psUrl,psAplicacion);
       end;
         KWAPROCESO.ejecutaProceso(pnSecuencia);

         htp.p('YA TERMINE');
         return;

      end if;

      procesarFoto(psCamp, csSysDate, psUser, vsListaId);

     paginaFoto(vsListaId, psUrl);

  EXCEPTION
      WHEN OTHERS THEN
           htp.p(SQLERRM);

           paginaFoto(vsListaId, psUrl);

  END guardaFoto;

 -- md-05 end

  PROCEDURE procesarFoto(psCamp        VARCHAR2,
                         pdDate        DATE,
                         psUser        VARCHAR2,
                         psListaId OUT VARCHAR2
                        ) IS

  vsId      SWBFOTO.NAME%TYPE := NULL;
  vsArchivo SWBFOTO.NAME%TYPE := NULL;
  vnPidm    NUMBER(9)         := NULL;

  csJPG   CONSTANT VARCHAR2(5) := '%JPG%';
  csShl   CONSTANT VARCHAR2(1) := '/';
  csPoint CONSTANT VARCHAR2(1) := '.';
  csComa  CONSTANT VARCHAR2(1) := ',';

  CURSOR cuFoto IS
         SELECT NAME AS fotoName
           FROM SWBFOTO
          WHERE UPPER(NAME) LIKE csJPG;

  BEGIN
      FOR regFot IN cuFoto LOOP
          vsArchivo := regFot.fotoName;
          vsId      := vsArchivo;
          vsId      := SUBSTR(vsId,  INSTR(vsId,csShl)   + 1);
          vsId      := SUBSTR(vsId,1,INSTR(vsId,csPoint) - 1);
          psListaId := psListaId||vsId||csComa;
          vnPidm    := F_GET_PIDM(vsId);

          DELETE SWRFOTO WHERE SWRFOTO_PIDM = vnPidm;

          BEGIN
              INSERT INTO SWRFOTO(SWRFOTO_FOTO, SWRFOTO_PIDM, SWRFOTO_USER)
                           SELECT BLOB_CONTENT, vnPidm,       psUser
                             FROM SWBFOTO
                            WHERE NAME = vsArchivo;

          EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                   NULL;
              WHEN OTHERS THEN
                   NULL;
          END;

          DELETE SWBFOTO WHERE NAME = vsArchivo;
      END LOOP;

      COMMIT;

  END procesarFoto;

  PROCEDURE paginaFoto(psID  VARCHAR2,
                       psUrl VARCHAR2
                      ) IS



  BEGIN
      kwatitl.titulo(
      'Guandando la foto del Estudiante ',
      NULL,
      NULL,
      NULL,
      psCancelMnu=>'Y',
      psEventBody=> 'onLoad="f_Espera();"'
      );


      htp.p('
      <script type="text/javascript">
      <!--
      function f_Espera() {
        f_Intervalo();
        setTimeout("f_Time()",4000);
      } //f_Espera

      function f_Time() {
        document.frmDocente.submit();
      } //f_Time

      function f_ImprimeReporte() {
        null;
      }
      -->
      </script>


      <center>
        <b>Espera mientras se Guarda...</b>
      </center>
      <table border="0" width="40%" align="center">
      <tr><td>
      ');

      --debe hacerce la llama a la función f_Intervalo();
      PWAPRSS(0,40);

      htp.p('
      </td></tr></table>

      <form name="frmDocente" action="'||psUrl||'archivo.Lista" method="post" target="_top">
      <input type="hidden" name="psID" value="'||psID||'" />
      </form>
      ');

      kwNotRefresh.script;

      --PK_ObjAteneoHTML.closed;  --md-01
      pk_objhtml.closed;    --md-01

  END paginaFoto;

  --LEE EL ARCHIVO2 BLOB PARA SER PRESENTADO EN HTML
  PROCEDURE jpg(pnPidm NUMBER
               ) IS

  vlFile      BLOB       := NULL;
--  buffer      RAW(32000) := NULL;
--  buffer_size INTEGER    := 32000;
--  offset      INTEGER    := 1;
--  vnLength    NUMBER     := NULL;

  BEGIN
      SELECT SWRFOTO_FOTO
        INTO vlFile
        FROM SWRFOTO
       WHERE SWRFOTO_PIDM = pnPidm;

      owa_util.mime_header('image/jpeg', true);
      wpg_docload.download_file( vlFile );

    EXCEPTION
        WHEN OTHERS THEN
             htp.p(SQLERRM);

  END jpg;

  --GENERA LA PAGINA PARA PRESENTAR EL LISTADO DE LAS FOTOS REGISTRADAS
  PROCEDURE Lista(psID VARCHAR2
                 ) IS

  csImagenes     CONSTANT VARCHAR2(60)  := '"menu","sali","back",';
  csAcciones     CONSTANT VARCHAR2(100) := 'pk_MenuAplicacion.p_MenuAplicacion,javascript:paginaSalir();,archivo.TeleCharger,';
  csOpciones     CONSTANT VARCHAR2(60)  := '"Menu Aplicacion","Salir","Retorno",';

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      htp.p('
      <html><head>
      <title>Foto del Estudiante Inscrito</title>');

      --RZ
       kwatitl.titulo(
      'Foto del Estudiante Inscrito',
      csImagenes,
      csAcciones,
      csOpciones,
      psCancelMnu=>'Y'
      );

      htp.p('
      <script language="JavaScript"><!--
      javascript:window.history.forward(1);
      --></script>

      </head><body>

      <table border="0" width="100%" cellpadding="0" cellspacing="0">
      <tr><th width="60%" class="thTitulo" valign="bottom" align="left">

      </th><td width="40%">

      </td></tr></table>
      ');

      --obtiene las fotos de los alumnos
      Foto(psID);

      htp.p('
      <br/>

      <p>'||vgnExis||' Foto Guardada</p>
      ');

      IF vgsID IS NOT NULL THEN
         htp.p('Registro de alumno no encontrado ('||vgsID||').');
      END IF;

      kwNotRefresh.script;

    --PK_ObjAteneoHTML.closed;  --md-01
      pk_objhtml.closed;    --md-01

      vgnExis := NULL;
      vgsID   := NULL;

  END Lista;

  --OBTIENE LAS FOTOS DE LOS ALUMNOS
  PROCEDURE Foto(psID   VARCHAR2
                ) IS

  vsId   VARCHAR2(32000) := psID;
  vsIdd  VARCHAR2(10)    := NULL;
  vnPidm NUMBER(10)      := NULL;

  BEGIN
      htp.p('
      <style type="text/css"><!--
      ul.wwIconified{
             width: 100%;
          overflow: hidden;
        list-style: none;
            margin: 10px 0;
           padding: 10px;
            border: 1px dotted #ffffff;
      }

      ul.wwIconified li{
          margin: 10px 8px;
          border: 1px dotted #ffffff;
           float: left;
           width: 100px;
        position: relative;
        overflow: hidden;
      }

      ul.wwIconified li div.Wide{
        width: 100px;
       height: 160px;
       margin: 0;
      padding: 0px 0 0 0;
      }

      ul.wwIconified li div.Wide img{
        display: block;
          width: 100px;
         margin: 0;
        padding: 0 0px 0px 0px;
      }
      --></style>

      <ul class="wwIconified"><div class="Wide">
      ');

      WHILE INSTR(vsId,',') > 0 LOOP
            vsIdd  := SUBSTR(vsId,1, INSTR(vsId,',') - 1);
            vnPidm := f_get_pidm(vsIdd);

            IF vnPidm IS NOT NULL THEN
               vgnExis := vgnExis + 1;
            ELSE
               vgsID   := vgsID || vsIdd ||', ';
            END IF;

            htp.p('<li>');

            IF vnPidm IS NOT NULL THEN
               htp.p('<img src="archivo.jpg?pnPidm='||vnPidm||'" width="100" height="130">');
            END IF;

            htp.p(vsIdd|| ' ' || vnPidm || '</li>');

            vsId   := SUBSTR(vsId, INSTR(vsId,',') + 1);
            vnPidm := NULL;
            vsIdd  := NULL;
      END LOOP;

      htp.p('</div></ul>');

      vgsID := SUBSTR(vgsID,1,LENGTH(vgsID)-2);

     EXCEPTION
         WHEN OTHERS THEN
              htp.p(SQLERRM);

  END Foto;

  PROCEDURE css IS

  BEGIN

      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      htp.p('

      <style type="text/css"><!--
      form{
           width: 100%;
        overflow: auto;
          margin: 0;
         padding: 0;
      }

      input {
        float: right;
      }

      input.wwIconified{
        float: left;
      }

      ul.wwIconified{
             width: 100%;
            height: 350px;
          overflow: auto;
        list-style: none;
            margin: 10px 0;
           padding: 10px;
            border: 1px solid #53081a;
      }

      ul.wwIconified li{
          margin: 10px 8px;
           float: left;
           width: 110px;
        position: relative;
        overflow: hidden;
      }

      ul.wwIconified li div.Wide{
          width: 100px;
         height: 160px;
         margin: 0;
        padding: 0px 0 0 0;
      }

      ul.wwIconified li div.Wide img{
        display: block;
          width: 100px;
         margin: 0;
        padding: 0 0px 0px 0px;
      }

      ul.wwIconified li p{
        font-family: verdana, sans-serif;
          font-size: 12px;
        line-height: 12px;
           position: absolute;
                top: 125px;
             margin: 0 0 0 5px;
              color: #E28B1A;
      }

      ul.wwIconified li input.File{
        display: none;
      }


      ul.wwIconified li button.RemoveButton{
          position: absolute;
               top: 100px;
             width: 40px;
            height: 40px;
            border: none;
        background: url(/imagenes/borrarFoto.gif) no-repeat;
            margin: 0 0 0 70px;
            cursor: pointer;
      }

      ul.wwIconified li button.RemoveButton span{
        display: none;
      }

      ul.wwIconified li div{
               width: 100px;
              height: 160px;
         margin-left: auto;
        margin-right: auto;
          background: url(/imagenes/icon-default.gif) no-repeat;
      }

       --></style>
      ');

  END css;

  PROCEDURE js IS

  BEGIN

      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      htp.p('
      var vgnFoto = 0;


      // From Quirksmode - http://www.quirksmode.org/js/events_properties.html
      // (slightly modified)
      function GetTarget(Event){
        var Target;

        if(!Event)
           var Event = window.event;

             if(Event.target)
                Target = Event.target;
        else if(Event.srcElement)
                Target = Event.srcElement;


        if(Target.nodeType == 3) // defeat Safari bug
        Target = Target.parentNode;

        return Target;
      } //fin de GetTarget



      if(!Array.indexOf){
         Array.prototype.indexOf = function(obj) {
                                                  for(var i=0; i<this.length; i++){
                                                      if(this[i]==obj){
                                                         return i;
                                                      }
                                                  }
                                                  return -1;
                                                 }
      } //fin de if(!Array.indexOf)



      function RemoveIcon(Event){
        var RemoveButton = GetTarget(Event);
        var Icon         = RemoveButton.parentNode;

        // If the first icon is removed, set the next icon as first.
        if(Icon.className == "First" && Icon.nextSibling)
           Icon.nextSibling.className = "First";

        // Remove
        fotoMen();

        Icon.parentNode.removeChild(RemoveButton.parentNode);
      } //fin de RemoveIcon


      function GetForm(Field){
        var TheForm = Field.parentNode;

        while(TheForm.tagName.toLowerCase() != "form"){
              TheForm = TheForm.parentNode;
        }

        return TheForm;
      } //fin de GetForm

      function SetWideOrTall(Icon){
        Icon.parentNode.className = (Icon.height/Icon.width > 0.75) ? "Tall" : "Wide"; // I define "Tall" as having an aspect ratio that is taller than 3/4. It is a pretty arbitrarily value, though.
      } //fin de SetWideOrTall

      function wwIconifiedOnChange(Event){
        // Get the field with the new file.
        var Field = GetTarget(Event);

        // Find the place where to put the file icon.
        var Container = getElementsByClassName(GetForm(Field), "ul", "wwIconified").pop();

        // Create the icon base node.
        var Base = document.createElement("li");

        if(!Container.hasChildNodes())
           Base.className = "First"; // Makes styling a bit easier.

           // Create the actual icon.
        var IconFrame = document.createElement("div");

        Base.appendChild(IconFrame);

        var ImageFileTypes = ["jpeg", "jpg", "JPEG", "JPG"];
        var Matches        = /([^\/\\]*[\/\\])*([^\/\\]+)\.(\w+)/.exec(Field.value);
        var FileType       = (Matches!=null ? Matches[3].toLowerCase() : "");

        if( fotoMas() ) { //limita la cantidad de fotos

            if(ImageFileTypes.indexOf(FileType) >= 0){
               // Create a thumbnail of the local image.
               var Icon = document.createElement("img");

               IconFrame.appendChild(Icon);
               Listen(Icon, "load", function(){SetWideOrTall(Icon);});  // Icon.width is not available until it is loaded, but It is useful for the styling to know if the image is wide or tall.
               Icon.src = "file:///"+Field.value; // Must be done after we add the event listenerand put the icon into the DOM structure, or the onload event might not be triggered after we set the initial values.
               Icon.width = "100px";
               /*}else{
               // Let the styling take care of the icons for other file types.
               IconFrame.className = FileType;
               }
               */
               // The file name.
               var FileName   = document.createElement("p");
               var FileText   = /([^\/\\]*[\/\\])*([^\/\\]+)/.exec(Field.value)[2];
               var TextLength = 16;

               if(FileText.length > (TextLength+2))
                  FileText = FileText.substr(0, TextLength)+"...";

               FileName.innerHTML = FileText;
               Base.appendChild(FileName);

               // Add a "remove" button.
               var RemoveButton = document.createElement("button");
               RemoveButton.setAttribute("type", "button");
               RemoveButton.className = "RemoveButton";

               var Label       = document.createElement("span");
               Label.innerHTML = "Remove";
               RemoveButton.appendChild(Label);
               Listen(RemoveButton, "click", RemoveIcon);
               Base.appendChild(RemoveButton);

               // Make a copy of the visible file field, sans the value.
               var BlankField       = document.createElement("input");
               BlankField.type      = "file";
               BlankField.name      = Field.name;
               BlankField.id        = Field.id;
               BlankField.className = Field.className;
               Listen(BlankField, "change", wwIconifiedOnChange);
               Field.parentNode.insertBefore(BlankField, Field);

               // Move the file upload field to the icon area, so the file can get uploaded. (You probably want to hide it with a "display: none;" in your stylesheet, since it makes no sense to have it visible.)
               Field.className = "File";
               Base.appendChild(Field);

               //   Base.insertBefore(Field, RemoveButton);

               // Show it all to the world!
               Container.appendChild(Base);
            } else {
               alert("El tipo de archivo no es valido.");
            }

        } else {
            alert("No puedes enviar mas de " + vgnCantidad + " fotos.");

            fotoMen();
        }

      } //fin de la función wwIconifiedOnChange



      function getElementsByClassName(oElm, strTagName, strClassName){
        var arrElements       = (strTagName == "*" && oElm.all)? oElm.all : oElm.getElementsByTagName(strTagName);
        var arrReturnElements = new Array();

        strClassName = strClassName.replace(/-/g, "\-");

        var oRegExp = new RegExp("(^|\s)" + strClassName + "(\s|$)");
        var oElement;

        for(var i=0; i<arrElements.length; i++){
         oElement = arrElements[i];

         if(oRegExp.test(oElement.className)){
         arrReturnElements.push(oElement);
         }
        }

        return (arrReturnElements)
      } //fin de getElementsByClassName



      function wwIconifyFileUploadInit(){
        // For all instances of the wwIconify file upload field.
        var Fields = getElementsByClassName(document, "input", "wwIconified");

        for(var i=0; i<Fields.length; i++){
            // Add the event listener.
            Listen(Fields[i], "change", wwIconifiedOnChange); // The main action.

            // Make sure there is a place to put the icons.
            var Container = getElementsByClassName(GetForm(Fields[i]), "ul", "wwIconified").pop();

         if(!Container){
               // Someone was too lazy to make a container for the icons, so lets create one now, and insert it just before the file-field.
               Container = document.createElement("ul");
               Container.className = "wwIconified";
               Fields[i].parentNode.insertBefore(Container, Fields[i]);
            }
        }
      } //fin de wwIconifyFileUploadInit()



      // From Ajax Cookbook - http://ajaxcookbook.org/event-handling-memory-leaks/
      // (Slightly modified.)
      function Listen(instance, eventName, listener) {
               if(instance.addEventListener) {
                  instance.addEventListener(eventName, listener, false);
        } else if(instance.attachEvent) {
                  var f = listener;

         listener = function() {
                               f(window.event);
                             }

         instance.attachEvent("on" + eventName, listener);
        } else {
               throw new Error("Event registration not supported");
        }
      }// fin de Listen()

      function fotoMas() {
        vgnFoto++;

        document.frmFotos.txtFotos.value = vgnFoto;

        if( vgnFoto < 21 ){
           return true;
        }

        return false;


      } //fin de fotoMas

      function fotoMen() {
        vgnFoto--;

        document.frmFotos.txtFotos.value = vgnFoto;
      } //fin de fotoMen

      Listen(window, "load", wwIconifyFileUploadInit);
      ');
END js;

END archivo;
/

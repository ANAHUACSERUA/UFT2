DROP PACKAGE BODY BANINST1.PK_ADMEJECUCION;

CREATE OR REPLACE PACKAGE BODY BANINST1.pk_AdmEjecucion IS
/******************************************************************************
PAQUETE:            BANINST1.pk_AdmEjecucion
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de de archivos en la tabla SORTEST
AUTOR:              Pablo Serratos Vazquez
FECHA:              29112011
******************************************************************************/

    --Variables globales
    vgsUsr              VARCHAR2(30);

/******************************************************************************
PROCEDIMIENTO:      p_Main
OBJETIVO:           Pagina principal de la aplicación
******************************************************************************/
PROCEDURE p_Main(
    psParametro         VARCHAR2 DEFAULT NULL,
    psBandAlmacenados VARCHAR2 DEFAULT '0'
    ) IS

    vnBanderaA      NUMBER(2);
    vsMensaje       VARCHAR2(500);

    --Cursor para obtener los nombres y codigos de aplicaciones


    /** Entity record type*/
     TYPE ADV_CBP_REC IS RECORD (
      R_CODE    VARCHAR2(100),
      R_DESC    VARCHAR2(100));


    /** Entity cursor variable type*/
    TYPE ADV_CBP_SET IS TABLE OF  ADV_CBP_REC;
    ADV_CBP_ITEMS ADV_CBP_SET;

    --contador comun y corriente
    vni PLS_INTEGER := 0;

    csImagenes CONSTANT VARCHAR2(50)  := '"ejecutar","menu","sali",';
    csAcciones CONSTANT VARCHAR2(500) := 'javascript:fTermEncuesta();,pk_MenuAplicacion.p_MenuAplicacion,javascript:paginaSalir();,';
    csOpciones CONSTANT VARCHAR2(300) := '"Ejecutar Proceso","Men&uacute;","Salir",';

    BEGIN

    --Seguridad de aplicacion GWAMNUA
    --IF PK_Login.F_ValidacionDeAcceso(vgsUsr) THEN RETURN; END IF;
    vnBanderaA := psBandAlmacenados;

     IF vnBanderaA IS NULL THEN
        vnBanderaA := '0';
     END IF;

     IF vnBanderaA = '' THEN
        vnBanderaA := '0';
     END IF;

    IF vnBanderaA IS NOT NULL THEN
            DELETE FROM  SWRSRTM WHERE SWRSRTM_USUARIO = USER;
            COMMIT;
    END IF ;



   --Comienza a imprimir header de HTML
    HTP.P('
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
    <HTML>
        <HEAD>
            <TITLE> Ejecucion Procesos Admision. </TITLE>'
    );

    -- META tags de Banner
    -- la aplicación no se guarda en el cache de la maquina.
    pk_ObjHTML.P_NoCache;

    --hoja de estilos de wtailor
   -- HTP.P(pk_ObjHTML.vgsCssBanner);
    HTP.P('
    <script type="text/javascript" src="pk_ObjHTML.js"></script>
    <script language="javascript" src="kwaslct.js"></script>
    <script language="javascript">

        function fTermEncuesta(){
            if (frmDatos.cboApp.value == "uft_cpsu")
                window.open("pk_AdmEjecucion.InsertaSortest","DocumentoID","toolbar=no,status=no,scrollbars=yes,top=50,left=50,height=300,width=550");

            if (frmDatos.cboApp.value == "uft_ceve")
                window.open("pk_AdmEjecucion.InsertaEventos","DocumentoID","toolbar=no,status=no,scrollbars=yes,top=50,left=50,height=300,width=550");


            if (frmDatos.cboApp.value == "uft_cpon")
                window.open("pk_AdmEjecucion.CalculaPonderado","DocumentoID","toolbar=no,status=no,scrollbars=yes,top=50,left=50,height=300,width=550");
        }
    </script>
    <style>
      a.boton{
            font-size:5px;
            font-family:Verdana,Helvetica;
            font-weight:bold;
            color:white;
            background:#638cb5;
            border:0px;
            width:40px;
            height:19px;
           }
         a:hover.button{
         color:#638c11;
        }
    </style>
    ');
    HTP.P('
    </HEAD>'
    );
    --Fin del encabezado

    HTP.P('
    <BODY BGCOLOR="#ffffff" CLASS="bodyCeroR">
    ');

    kwatitl.titulo
        ('EJECUCI&Oacute;N PROCESOS DE ADMISI&Oacute;N.',
        csImagenes,
        csAcciones,
        csOpciones,
        psCancelMnu=>'Y'
        );
      htp.p('
        <form name="frmDatos" method="post">
            <div style="height:50px;"> </div>
            <table border="0" cellpadding="0" cellspacing="0" width="80%" bgcolor="#efefef" >
                <tr>
                    <td class="etiqueta" valign="middle" style="font-size:12px" width="50%">
                        Seleccione el proceso a ejecutar:
                    </td width="60%">
                    <td class="etiqueta" valign="left" >
                    <select name="cboApp" style="width:250px">
                       <option value=""></option>
                    ');
                        EXECUTE IMMEDIATE  ' SELECT  IdApp, DescApp FROM( '||
                                            ' SELECT '||CHR(39)||'uft_cpsu'||CHR(39)||' AS IdApp ,'||CHR(39)||'CARGA RESULTADOS PSU'||CHR(39)||' AS DescApp '||
                                            ' FROM DUAL  '||
                                            ' UNION ALL '||
                                            ' SELECT '||CHR(39)||'uft_ceve'||CHR(39)||' AS IdApp ,'||CHR(39)||'EJECUTA EVENTOS'||CHR(39)||' AS DescApp '||
                                            ' FROM DUAL  '||
                                            ' UNION ALL '||
                                            ' SELECT '||CHR(39)||'uft_cpon'||CHR(39)||' AS IdApp ,'||CHR(39)||'CALCULO PONDERADOS'||CHR(39)||' AS DescApp '||
                                            ' FROM DUAL) ORDER BY DescApp ' BULK COLLECT
                        INTO ADV_CBP_ITEMS;
                          IF ADV_CBP_ITEMS IS NOT NULL THEN
                            IF ADV_CBP_ITEMS.COUNT > 0 THEN
                                FOR I IN ADV_CBP_ITEMS.FIRST..ADV_CBP_ITEMS.LAST LOOP
                                        HTP.P(' <option value="'||ADV_CBP_ITEMS(I).R_CODE||'" ');
                                        HTP.P('>'||ADV_CBP_ITEMS(I).R_DESC||'</option> ');
                                END LOOP;
                            END IF;
                          END IF;
                    HTP.P('
                       </select>


                    </td>
                </tr>
            </table>
        </form>

        <form method="get" name="frmPuntaje" target="_top" action="pk_AdmEjecucion.p_Main">
            <input type="hidden" name="psBandera" />
            <input type="hidden" name="psBandAlmacenados" />
            <input type="hidden" name="psParametro" />
        </form>
    </BODY>

    </HTML> ');
    EXCEPTION
    WHEN OTHERS THEN
        pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),'pk_AdmEjecucion.p_Main', NULL);
END p_Main;





PROCEDURE InsertaEventos IS

    BEGIN

    --Seguridad de aplicacion GWAMNUR
    --IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

    IF PK_Login.F_ValidacionDeAcceso(vgsUsr) THEN RETURN; END IF;

    -- META tags de Banner
    -- la aplicación no se guarda en el cache de la maquina.
    PK_ObjHTML.P_NoCache;


    BANINST1.PK_EVENTOS.p_Beca_Procedencia;

    --Comienza a imprimir header de HTML
    HTP.P('
        <html>
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
                <LINK REL="stylesheet" HREF="/css/web_defaultapp.css" TYPE="text/css">

             <style>
                    body.bodyCeroR { margin-left: 2pt; margin-right: 2pt; margin-top: 0pt; margin-bottom: 0pt;}
                    td.Estilo2 { font-family: Arial, Helvetica, sans-serif; font-size: 10px; text-align: justify;}
                    tr.Estilo3 { font-family: Arial, Helvetica, sans-serif; font-size: 12px; text-align: center;}
                        tr.Estilo4 { font-family: Arial, Helvetica, sans-serif; font-size: 12px; text-align: justify}
                    tr.Estilo5 { font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 1; text-align: justify;}
                    td.Estilo6 { font-family: Arial, Helvetica, sans-serif; line-height: 1; font-size: 12px; text-align: right;}
                        td.Estilo11 { border-color: black; border-style: inset; border-width: 12px; font-family: Arial, Helvetica, sans-serif; font-size: 10px; text-align: justify;}
                    td.Estilo12 { border-color: black; border-style: inset; border-width: 2px; font-family: Arial, Helvetica, sans-serif; font-size: 10px; text-align: right;}
                    tr.Estilo21 { font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 1; text-align: justify;}
                    td.Estilo22 { font-family: Arial, Helvetica, sans-serif; font-size: 10px; text-align: right;}
                    td.Estilo61{ font-family: Arial, Helvetica, sans-serif; line-height: 1; font-size: 15px; text-align: justify;}
                    H1.SaltoDePagina  { PAGE-BREAK-BEFORE: always }
                    td.tdLabel  {font-size:11pt; background-color:#FFBA6B; font-weight:bold;}

                      a.boton{
                            font-size:10px;
                            font-family:Verdana,Helvetica;
                            font-weight:bold;
                            color:white;
                            background:#638cb5;
                            border:0px;
                            width:80px;
                            height:19px;
                           }
                     a:hover.button{
                     color:#638c11;
                     }

                </style>

    </head>

         <body>
        <br><br><br><br><br><br>
            <div class="headerwrapperdiv">
                <form name="forma">
                    <table align = "center">
                        <tr><td class="delabel" align="center" colspan="4">
                         PROCESO TERMINADO  EVENTOS.
                        </td><tr>
                    <table>
                    <table align="center">
                        <tr>
                            <td scope="col">
                                <input type="button" value="Cerrar" class="boton" onclick="window.close();">
                            </td>
                        </tr>
                    </table>
                </form>
            </div>
         <form method="get" name="frmCandidato" target="_top" action="pk_AdmEjecucion.InsertaSortest">
        <input type="hidden" name="psRecarga"    value="1"  />
        <input type="hidden" name="psSesion" />
        <input type="hidden" name="psEstatusJob" />
        </form>
        </div>
        </body>

    </html>
    ');

  END;


-- PROCESO QUE SE INSERTO PARA CALCULO DE ISERTA SORTEST Y FALTA OTRO DE PONDERADO
PROCEDURE InsertaSortest(psRecarga IN VARCHAR2 DEFAULT '0',psEstatusJob IN VARCHAR2 DEFAULT '0' ) IS



    vsRecarga VARCHAR2(20);
    vsEstatusJob NUMBER := 0;
    vsexisteJob NUMBER := 0;
    vsTerminoJob NUMBER := 0;
    vsPasoJob NUMBER := 0;
    vsError VARCHAR2(100);
    vsErrorN NUMBER := 0;
    ln_dummy number;


    pnTermCode VARCHAR2(6) := '201210';
    pnPidm NUMBER(8) := 6824;
        vsAnteri        VARCHAR2(6):=   '201125';

    BEGIN

        --Seguridad de aplicacion GWAMNUR
        --IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

        --IF PK_Login.F_ValidacionDeAcceso(vgsUsr) THEN RETURN; END IF;

        -- META tags de Banner
        -- la aplicación no se guarda en el cache de la maquina.
        PK_ObjHTML.P_NoCache;

          IF psRecarga IS NULL THEN
            vsRecarga := '0';
        ELSE
            vsRecarga := psRecarga;
        END IF;


        IF psEstatusJob IS NULL THEN
            vsEstatusJob := '0';
        ELSE
            vsEstatusJob := psEstatusJob;
        END IF;

        BEGIN

            IF vsRecarga = '0' THEN

                    SELECT BANSECR.SEQ_SORTEST.NEXTVAL INTO vsEstatusJob FROM DUAL;

                    dbms_job.submit(job  => ln_dummy,
                    what => 'BEGIN pk_CargaPSU.p_InsertaSortest('||TO_CHAR(vsEstatusJob)||');END;');
                    dbms_job.run(ln_dummy);

--
--                    DBMS_SCHEDULER.CREATE_JOB (
--                         job_name => 'PSU1'
--                        ,job_type => 'PLSQL_BLOCK'
--                        ,job_action => 'BEGIN pk_CargaPSU.p_InsertaSortest('||TO_CHAR(vsEstatusJob)||');END;'
--                        ,start_date => sysdate
--                        ,repeat_interval => 'FREQ=MINUTELY; INTERVAL=1000'
--                        ,enabled => TRUE
--                        ,comments => 'Refreshes the GWREVNT table every 1000 minutes'
--                    );


                   -- pk_CargaPSU.p_InsertaSortest(TO_CHAR(vsEstatusJob));

                    INSERT INTO GWVTJOB VALUES(TO_NUMBER(vsEstatusJob),0,0 ); COMMIT;
            END IF;
        EXCEPTION

        WHEN OTHERS THEN
            vsError := SUBSTR(sqlerrm,1,99);
            vsErrorN := SQLCODE;

            vsexisteJob := 1;
            pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),'pk_AdmEjecucion.InsertaSortest', NULL);
            HTP.P(SQLERRM||'ejectua 1');
            --dbms_scheduler.drop_job('PSU1', TRUE);
            --dbms_scheduler.drop_job(vsSesion, TRUE);
        END;


        SELECT COUNT(*) INTO vsTerminoJob FROM GWVTJOB WHERE GWVTJOB_ID = vsEstatusJob AND  GWVTJOB_ESTADO= 1;

        IF  vsTerminoJob = 1 THEN
            --dbms_scheduler.drop_job('PSU1', TRUE);
            SELECT COUNT(*) INTO vsTerminoJob FROM GWVTJOB WHERE GWVTJOB_ID = vsEstatusJob AND  GWVTJOB_ESTADO= 1;
        ELSE
            SELECT GWVTJOB_PROCESO INTO vsPasoJob FROM GWVTJOB WHERE GWVTJOB_ID = vsEstatusJob;
        END IF;


    --Comienza a imprimir header de HTML
    HTP.P('
        <html>
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
                <LINK REL="stylesheet" HREF="/css/web_defaultapp.css" TYPE="text/css">

             <style>
                    body.bodyCeroR { margin-left: 2pt; margin-right: 2pt; margin-top: 0pt; margin-bottom: 0pt;}
                    td.Estilo2 { font-family: Arial, Helvetica, sans-serif; font-size: 10px; text-align: justify;}
                    tr.Estilo3 { font-family: Arial, Helvetica, sans-serif; font-size: 12px; text-align: center;}
                        tr.Estilo4 { font-family: Arial, Helvetica, sans-serif; font-size: 12px; text-align: justify}
                    tr.Estilo5 { font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 1; text-align: justify;}
                    td.Estilo6 { font-family: Arial, Helvetica, sans-serif; line-height: 1; font-size: 12px; text-align: right;}
                        td.Estilo11 { border-color: black; border-style: inset; border-width: 12px; font-family: Arial, Helvetica, sans-serif; font-size: 10px; text-align: justify;}
                    td.Estilo12 { border-color: black; border-style: inset; border-width: 2px; font-family: Arial, Helvetica, sans-serif; font-size: 10px; text-align: right;}
                    tr.Estilo21 { font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 1; text-align: justify;}
                    td.Estilo22 { font-family: Arial, Helvetica, sans-serif; font-size: 10px; text-align: right;}
                    td.Estilo61{ font-family: Arial, Helvetica, sans-serif; line-height: 1; font-size: 15px; text-align: justify;}
                    H1.SaltoDePagina  { PAGE-BREAK-BEFORE: always }
                    td.tdLabel  {font-size:11pt; background-color:#FFBA6B; font-weight:bold;}

                      a.boton{
                            font-size:10px;
                            font-family:Verdana,Helvetica;
                            font-weight:bold;
                            color:white;
                            background:#638cb5;
                            border:0px;
                            width:80px;
                            height:19px;
                           }
                     a:hover.button{
                     color:#638c11;
                     }

                </style>


                <script language="javascript">
                    function wait(){
                    document.frmCandidato.psRecarga.value=  "1";

                    document.frmCandidato.psEstatusJob.value=  "'||vsEstatusJob||'";
                    string="document.frmCandidato.submit();";
                    setInterval(string,60000);
                    }
                </script>

    </head>

         <body
           ');

           IF vsTerminoJob = 0 THEN
                HTP.P(' onload=wait() ');
           END IF;

           HTP.P(' >
        <br><br><br><br><br><br>
            <div class="headerwrapperdiv">
                <form name="forma">
                    <table align = "center">
                        <tr><td class="delabel" align="center" colspan="4">
                         ');

                           IF vsTerminoJob = 0 THEN
                                HTP.P(' ESPERE POR FAVOR... LINEA '||vsPasoJob||'.');

                           ELSE
                                HTP.P(' PROCESO TERMINADO.');
                           END IF;

                        HTP.P('
                        </td><tr>
                    <table>
                    <table align="center">
                        <tr>
                            <td scope="col">
                                <input type="button" value="Cerrar" class="boton" onclick="window.close();">
                            </td>
                        </tr>
                    </table>
                </form>
            </div>
         <form method="get" name="frmCandidato" target="_top" action="pk_AdmEjecucion.InsertaSortest">
        <input type="hidden" name="psRecarga"    value="1"  />
        <input type="hidden" name="psSesion" />
        <input type="hidden" name="psEstatusJob" />
        </form>
        </div>
        </body>

    </html>
    ');

    END;

END;
/


DROP PUBLIC SYNONYM PK_ADMEJECUCION;

CREATE PUBLIC SYNONYM PK_ADMEJECUCION FOR BANINST1.PK_ADMEJECUCION;


GRANT EXECUTE ON BANINST1.PK_ADMEJECUCION TO ADM_ADMISION;

GRANT EXECUTE ON BANINST1.PK_ADMEJECUCION TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ADMEJECUCION TO WWW2_USER;

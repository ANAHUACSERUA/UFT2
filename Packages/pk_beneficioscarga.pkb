CREATE OR REPLACE PACKAGE BODY BANINST1.pk_BeneficiosCarga IS
/******************************************************************************
PAQUETE:            BANINST1.pk_BeneficiosCarga
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la generación de archivos CRM, para amd.
AUTOR:              Gilberto Velazquez Hernandez
FECHA:              20110704
**************************************************
mod       :         md-01
objetivo  :         se agrea subir archivo CAE-postulantes Y CAE-Superior
autor     :         Roman Ruiz
fecha     :         20-ago-2013
**************************************************
mod       :         md-02
objetivo  :         se agrea Carga de archivo Renovantes Historicos
autor     :         Roman Ruiz
fecha     :         03-mar-2014
******************************************************************************/

    --Mensajes de Error
    cgsErr20081         CONSTANT VARCHAR2(4000) :=
        'No se pudo determinar el nombre de la instancia';
    cgsErr20082         CONSTANT VARCHAR2(4000) :=
        'No se pudo determinar la liga de la instancia';

    --Variables globales
    vgsUsr              VARCHAR2(30);


/******************************************************************************
PROCEDIMIENTO:      p_Main
OBJETIVO:           Pagina principal de la aplicación
******************************************************************************/
PROCEDURE p_Main(
    psParametro         VARCHAR2 DEFAULT NULL) IS
    --Nombre de la instancia
    vsNomInst           VARCHAR2(30);
    --Liga base
    vsUrlBase           VARCHAR2(256);
    --Liga definitiva
    vsUrl               VARCHAR2(256);
    --Constante con la ruta relativa de la aplicacion de carga de archivos
    csRutaApp           CONSTANT VARCHAR2(128) := 'cargaarchivo';
    --Constante con la pagina
    csPagina            CONSTANT VARCHAR2(128) := 'entrada.jsp';


    --cursor para obtener el nombre de la instancia
    CURSOR cuNomInst IS SELECT UNIQUE NAME FROM GV$DATABASE;

    --Cursor para obtener la url base de la instancia
    CURSOR cuLiga(psNomInst VARCHAR2) IS
        SELECT
            TWRBASE_LIGA
        FROM
            TWRBASE
        WHERE
            TWRBASE_INSTANCIA = psNomInst;

    --Cursor para obtener los nombres y codigos de aplicaciones
    CURSOR cuApps IS
        SELECT
            'uft_caep'              AS IdApp
            ,'Carga Preseleccionados CAE' AS DescApp
        FROM DUAL
        UNION ALL
        SELECT
            'uft_caes'              AS IdApp
            ,'Carga Fuas' AS DescApp
        FROM DUAL      -- md-01 fin
        union all      -- md-02 ini
        SELECT
            'uft_carh'              AS IdApp
            ,'Carga Renovantes Historicos CAE' AS DescApp
        FROM DUAL      -- md-02 fin
        ORDER BY DescApp;

    --contador comun y corriente
    vni                 PLS_INTEGER := 0;

     csImagenes CONSTANT VARCHAR2(50)  := '"menu","sali",';
     csAcciones CONSTANT VARCHAR2(500) := 'pk_MenuAplicacion.p_MenuAplicacion,javascript:paginaSalir();,';
     csOpciones CONSTANT VARCHAR2(300) := '"Men&uacute;","Salir",';


BEGIN

    --Seguridad de aplicacion GWAMNUA
    IF PK_Login.F_ValidacionDeAcceso(vgsUsr) THEN RETURN; END IF;

    --Obtengo el nombre de la instancia
    OPEN cuNomInst;
    FETCH cuNomInst INTO vsNomInst;
    CLOSE cuNomInst;

    --si la instancia es nula
    IF vsNomInst IS NULL THEN
        -- a la alver!!!!
        RAISE_APPLICATION_ERROR(-20081, cgsErr20081);
    END IF;

    --Obtengo la url de SSB de la instancia la que estamos corriendo
    OPEN cuLiga(vsNomInst);
    FETCH cuLiga into vsUrlBase;
    CLOSE cuLiga;

    --si la liga es nula
    IF vsUrlBase IS NULL THEN
        -- a la alver!!!!
        RAISE_APPLICATION_ERROR(-20082, cgsErr20082);
    END IF;

    --Si estoy aqui calculo cual es la url raiz del servidor
    -- y las expresiones regulares son la neta :D
    vsUrl := REGEXP_SUBSTR(vsUrlBase
        ,'(https?://)?[A-Za-z0-9\:\.]+\.[A-Za-z0-9\:\.]+(/|$)');

    --si el ultimo caracter no es la diagonal la agrego
    IF SUBSTR(vsUrl, -1) <> '/' THEN
        vsUrl := vsUrl || '/';
    END IF;

    --Anexo la ruta relativa de la aplicacion
    vsUrl := vsUrl || csRutaApp;

    --Verifico si es intancia de pruebas o no
    IF INSTR(UPPER(vsNomInst), '_P') > 0 THEN
        vsUrl := vsUrl || '_p'; --Ojo con la minuscula
    END IF;

    --agrego la pagina de entrada
    vsUrl := vsUrl || '/' || csPagina;

    --ya que tengo la URL comienzo el despliegue de la aplicación web
   --Comienza a imprimir header de HTML
    HTP.P('
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
    <HEAD>
        <TITLE> Carga de archivos de admisi&oacute;n. </TITLE>'
    );

    -- META tags de Banner
    -- la aplicación no se guarda en el cache de la maquina.
    pk_ObjHTML.P_NoCache;

    --hoja de estilos de wtailor
    HTP.P(pk_ObjHTML.vgsCssBanner);
 HTP.P('
    <script type="text/javascript" src="pk_ObjHTML.js"></script>
     <script language="javascript" src="kwaslct.js"></script>
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

    --Body Completo, sin alteraciones ni nada jejejeje :)
    HTP.P('
    <body bgcolor="#ffffff" class="bodyCeroR" >
  ');

            kwatitl.titulo
      ('CARGAS CREDITO AVAL DEL ESTADO',
       csImagenes,
       csAcciones,
       csOpciones,
       psCancelMnu=>'Y'
      );
      htp.p('
        <div style="height:50px;"> </div>
        <h2>
            Carga de archivos Beneficios.
        </h2>
        <hr/>
        <br/>
        <table border="0" cellpadding="0" cellspacing="0" width="100%" bgcolor="#efefef" >

            <form name="frmDatos" method="post">
                <tr>
                    <td class="etiqueta" valign="middle" style="font-size:12px" width="50%">
                        Seleccione el portal del archivo que desea cargar:
                    </td width="50%">
                    <td class="etiqueta" valign="left" >
                        <select name="cboApp" style="width:300px"> </select>
                        <input type="button" style="width:30px" name="cmdOK" value="Ir" />
                    </td>
                </tr>
            </form>
        </table>
        <form name="frmParams" method="post">
            <input type="hidden" name="nomApp" />
            <input type="hidden" name="token" />
        </form>
    </BODY>'
    );

    --Invocacion del archivo js de funciones comunes
    HTP.P('
    <script type="text/javascript" src="pk_ObjHTML.js"></script>
    ');

    -- Inicio de javascript
    HTP.P('
    <script type="text/javascript">
        //valores obtenidos de la base de datos'
    );

    HTP.P('
        var User="'||vgsUsr||'";
        var Liga="'||vsUrl||'";
        '
    );

    HTP.P('
        var Servicios = [');

    FOR regApp IN cuApps LOOP
        IF vni > 0 THEN HTP.P(','); END IF;
        HTP.PRN('["'|| regApp.IdApp ||'","' || regApp.DescApp|| '"]');
        vni := 1;
    END LOOP;

    HTP.PRN('];');


    HTP.P('
        //variables para los formularios
        var frmDatos = document.frmDatos;
        var frmParams = document.frmParams;

        function LlenaComboApp(){
            for (var i=0; i< Servicios.length; i++){
                AgregaElementoCombo(frmDatos.cboApp,
                    Servicios[i][0], Servicios[i][1]);
            }
        }

        function Valida(){
            if(frmDatos.cboApp.value==""){
                alert("Seleccione una aplicacion");
                frmDatos.cboApp.focus();
                return false;
            }
            return true;
        }

        function RecibeToken(str){

            var arr;
            eval("arr = " + str);
            if (arr.length != 1){
                alert("No se recibio la respuesta esperada");
                return;
            }

            if(arr[0] == ""){
                alert("No se recibio la respuesta esperada");
                return;
            }

            //asignamos el token
            frmParams.token.value = arr[0];

            //enviamos la forma
            frmParams.submit();
        }

        function Ejecuta(){


            if(!Valida()) return;

            frmParams.nomApp.value = frmDatos.cboApp.value;

            //creo el arreglo de parametros
            var prms = [
                ["psApp",frmDatos.cboApp.value]
                ,["psUser",User]
            ];

            //obtengo el token de ejecucion
            ObtenerDatosBD("pk_AdmCarga.p_JSONObtToken",prms,RecibeToken);

        }

        //carga los datos en la ventana
        function InicializarPagina(){

            //cargo los servicios en el combobox
            LlenaComboApp();

            //asigno el destino de la forma
            frmParams.action = Liga;
        }InicializarPagina();

        function AsignarEventos(){

            //asigno los eventos a los controles de la pagina
            //que lo requieran

            //bloqueo de click derecho
            //BloquearMenuContxt();

            //boton de generar archivo
            frmDatos.cmdOK.onclick=Ejecuta;

        }AsignarEventos();

    </script>'
    );
    --Fin de javascript

    --Fin de la pagina
    HTP.P('
</HTML>'
    );
EXCEPTION
    WHEN OTHERS THEN
        --pantallazo de error.
        pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),
            'pk_BeneficiosCarga.p_Main', NULL);

END p_Main;

/******************************************************************************
PROCEDIMIENTO:      p_JSONObtToken
OBJETIVO:           Devuelve un token para la autorización de la ejecución
                    del jsp de carga de archivos
PARAMETROS:
psApp:              Nombre de la aplicación a ejecutar
psUser:             Nombre del usuario que solicita autorización
******************************************************************************/
PROCEDURE p_JSONObtToken(
    psApp               VARCHAR2
    ,psUser             VARCHAR2
) IS
    vsToken             GWBATET.GWBATET_AUTH_TOKEN%TYPE;
BEGIN
    --verifico la seguridad de gwamnua
    --IF PK_Login.F_ValidacionDeAcceso(vgsUsr) THEN RETURN; END IF;

    --obtengo el token
    vsToken := pk_SeguridadExt.f_ObtToken(psApp, psUser);

    --si no hubo token regreso nulo
    IF vsToken IS NULL THEN RETURN; END IF;

    --envio el token
    HTP.PRN('["'||vsToken||'"]');

END p_JSONObtToken;

END pk_BeneficiosCarga;
/
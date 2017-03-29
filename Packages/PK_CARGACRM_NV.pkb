CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaCRM_NV IS
/******************************************************************************
PAQUETE:            BANINST1.pk_CargaCRM_NV
OBJETIVO:            Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos de rendición CRM
AUTOR:                Marcela Altamirano Chan
FECHA:                20100922

-------------
modificaion     md-02
objetivo          unificar metodo de carga archivo
autor              roman ruiz
fecha              04-feb-2016

******************************************************************************/

 cgsCodApp           CONSTANT VARCHAR2(4) := 'CRM';

    global_aidm            SABNSTU.SABNSTU_AIDM%TYPE;
    --global_id            SABNSTU.SABNSTU_ID%TYPE;
    vgsUsr                VARCHAR2(30) := NULL;

    --Constantes optimizacion de PL/SQL
    --Despues de un año me doy cuenta que estas $%& constantes sirven pa' dos
    --cosas
    cgsN                CONSTANT VARCHAR2(1) := 'N';
    cgsY                CONSTANT VARCHAR2(1) := 'Y';
    cgsA                CONSTANT VARCHAR2(1) := 'A';
    cgsR                CONSTANT VARCHAR2(1) := 'R';
    cgsE                CONSTANT VARCHAR2(1) := 'E';
    cgsM                CONSTANT VARCHAR2(1) := 'M';
    cgsOK                CONSTANT VARCHAR2(2) := 'OK';
    cgsS                CONSTANT VARCHAR2(1) := 'S';
    cgsU                CONSTANT VARCHAR2(1) := 'U';
    cgsNull                CONSTANT VARCHAR2(1) := NULL;

    cgsADDITIONAL        CONSTANT VARCHAR2(12) := 'ADDITIONAL';
    cgsWEB                CONSTANT VARCHAR2(5) := '*WEB*';
    cgsWB                CONSTANT VARCHAR2(2) := 'WB';
    cgsMDC                CONSTANT VARCHAR2(3) := 'MDC';
    cgsHS                CONSTANT VARCHAR2(2) := 'HS';
    cgsPR                CONSTANT VARCHAR2(2) :='PR';
    cgs0101                CONSTANT VARCHAR2(6) := '01/01/';
    cgsPregunta1        CONSTANT VARCHAR2(55) := 'Origen de la postulación:WEB / Presencial UFT / BD';
    cgsPregunta2        CONSTANT VARCHAR2(30) := 'Bachillerato Desconocido';
    cgsMMDDYYYY            CONSTANT VARCHAR2(10) := 'MM/DD/YYYY';

    vnSarhead            NUMBER;
    cgn1                CONSTANT PLS_INTEGER := 1;
    cgn2                CONSTANT PLS_INTEGER := 2;
    cgn3                CONSTANT PLS_INTEGER := 3;
    cgn4                CONSTANT PLS_INTEGER := 4;
    cgn5                CONSTANT PLS_INTEGER := 5;

    cgsMsg1001            CONSTANT VARCHAR2(2000) :=
        'El rut ya tiene 3 programas registrados';
    cgsMsg1002            CONSTANT VARCHAR2(2000) :=
        'El rut ya tiene varios AIDM''s';
    cgsMsg1003            CONSTANT VARCHAR2(2000) :=
        'Este programa ya habia sido registrado para este rut';

    --Variables globales
    --Tipo para la lista de rut, contra aidm, el aidm es un entero
    TYPE t_ArrRutAidm IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(20);
    --lista de rut's vs. aidms
    vtListaAidms        t_ArrRutAidm;

    --Tipo de registro programa y tipo de admision
    TYPE t_RegProgAd IS RECORD(
        Programa        VARCHAR2(20)
        ,TipoAd            VARCHAR2(4)
        ,Periodo        VARCHAR2(6)
    );

    --Tipo para la lista de programa y vias de admision
    TYPE t_ArrProgs IS TABLE OF t_RegProgAd;
    --Tipo para la lista de rut's contra programas
    TYPE t_ArrRutProgs IS TABLE OF t_ArrProgs INDEX BY VARCHAR2(20);
    --Lista de Rut's vs Programas
    vtListaProgs        t_ArrRutProgs;

    -- Tipo de datos de tabla temporal
    TYPE t_RegSWBTCRM IS RECORD (
        SWBTCRM_AIDM                    NUMBER(8),
        SWBTCRM_RUT                        VARCHAR2(35),
        SWBTCRM_TERM_CODE                VARCHAR2(6),
        SWBTCRM_SARHEAD_CODE            VARCHAR2(2),
        SWBTCRM_SARHEAD_APLS_CODE        VARCHAR2(4),
        SWBTCRM_SARHEAD_ADD_DATE        DATE,
        SWBTCRM_SARETRY_PROGRAMA        VARCHAR2(12),
        SWBTCRM_SARETRY_APPL_SEQNO        NUMBER(3),
        SWBTCRM_SARETRY_PRIORITY_NO        NUMBER(4),
        SWBTCRM_SARADDR_STREET_LINE1    VARCHAR2(35),
        SWBTCRM_SARADDR_STREET_LINE2    VARCHAR2(35),
        SWBTCRM_SARADDR_STREET_LINE3    VARCHAR2(30),
        SWBTCRM_SARADDR_CITY            VARCHAR2(30),
        SWBTCRM_SARADDR_STAT_CDE        VARCHAR2(3),
        SWBTCRM_SARADDR_CNTY_CDE        VARCHAR2(20),
        SWBTCRM_SARADDR_ZIP                VARCHAR2(15),
        SWBTCRM_SARADDR_NATN_CDE        VARCHAR2(5),
        SWBTCRM_SARPHON_PQLF_CDE1        VARCHAR2(2),
        SWBTCRM_SARPHON_PHONE1            VARCHAR2(80),
        SWBTCRM_SARPHON_PQLF_CDE2        VARCHAR2(2),
        SWBTCRM_SARPHON_PHONE2            VARCHAR2(80),
        SWBTCRM_SARPHON_PQLF_CDE3        VARCHAR2(2),
        SWBTCRM_SARPHON_PHONE3            VARCHAR2(80),
        SWBTCRM_SARPERS_FIRST_NAME        VARCHAR2(35),
        SWBTCRM_SARPERS_LAST_NAME        VARCHAR2(60),
        SWBTCRM_SARPERS_MIDDLE_NAME1 VARCHAR2(35),
        SWBTCRM_SARPERS_BIRTH_DATE        DATE,
        SWBTCRM_SARPERS_GENDER            VARCHAR2(1),
        SWBTCRM_SARPERS_CITZ_CDE        VARCHAR2(2),
        SWBTCRM_SARHSCH_IDEN_CDE        VARCHAR2(20),
        SWBTCRM_SARHSCH_HSGR_DATE        VARCHAR2(35),
        SWBTCRM_SARPCOL_IDEN_CDE        VARCHAR2(40),
        SWBTCRM_SARRQST_ANSR_DESC        VARCHAR2(500),
        SWBTCRM_SARRQST_ANSR_DESC2        VARCHAR2(500)
    );

----prototipos de Funciones y procedimientos privados
----veasé el cuerpo del procedimiento/funcion para mayor info


PROCEDURE p_ImprimeLineaResultado(
    psLinea                VARCHAR2
);

PROCEDURE p_DesglosaRegistro(
    psLinea        IN        VARCHAR2
    ,psRes        IN OUT    VARCHAR2
    ,psMsg        IN OUT    VARCHAR2
);
PROCEDURE p_ProcesaRegistro (
    vtRegTemp IN OUT NOCOPY t_RegSWBTCRM
    ,psRes        IN OUT    VARCHAR2
    ,psMsg        IN OUT    VARCHAR2
);

----fin de prototipos privados

/******************************************************************************
PROCEDIMIENTO:        p_Carga
OBJETIVO:            Procesa un archivo de carga proveniente del CRM
PARAMETROS:
psArchivo            Nombre con que fue guardado el archivo cargado
                    por el usuario. Este nombre es proveido por la base de
                    datos con el que el archivo puede ser extraido de la tabla
                    indicada por la configuración del DAD.
******************************************************************************/
PROCEDURE p_Carga(
    psArchivo            VARCHAR2
    ,psUser                VARCHAR2 DEFAULT USER
) IS

    --Guarda la Firma SHA1 del archivo
    vrDigestionSHA1        RAW(20);
    --Guarda el tamaño del archivo
    vnTamano            NUMBER(10);
    --El archivo en sí, formato BLOB:
    vrArchivoBLOB        BLOB;
    --El archivo en sí, formato CLOB:
    vsArchivoCLOB        CLOB;
    --Variable para verificar que exista el archivo
    vbExiste            BOOLEAN;
    --Variable de contador para ver en que posicion estamos del archivo
    vni                    PLS_INTEGER;
    --Variable de contador de lineas
    vnNumLineas            PLS_INTEGER;
    --Variable AAAA para ver cual es el tamaño de la linea
    vnTamLinea            PLS_INTEGER;
    --Variable para guardar la linea en si
    vsLinea                VARCHAR2(4000);
    --Variable de resultado del proceso del registro
    vsStatus            VARCHAR2(1);
    --Variable de resultado del proceso del registro
    vsMensajeProc        VARCHAR2(4000);
    --Variable para guardar el numero de proceso de carga de archivo
    vnNumProcCarga        PLS_INTEGER;
    --variable para el usuario que habia cargado este archivo previamente
    vsUserAnt            GWBAACR.GWBAACR_USER%TYPE;
    --variable para la fecha en que se habia cargado este archivo previamente
    vdFechaAnt            GWBAACR.GWBAACR_ACTIVITY_DATE%TYPE;
--  vsalida    VARCHAR2(3000);                  --md-02
vsNombreArchivoCorto VARCHAR2(10);


    vsalida             VARCHAR2(3000);      --md-02  start
    vsNameArchivo       varchar2(300);   
    vsArchExitente     varchar2(300);    
    vsArchExSize       number(10):= 0;
    vrArchivoExBlob   BLOB;
    viArchVivo           number(4) := 0;    --md-02  end


    --Cursor para obtener el archivo
    CURSOR cuArch(psArchivo VARCHAR2) IS
        SELECT
            DOC_SIZE                    AS Tamaño
            ,BLOB_CONTENT                AS Contenido
        FROM
            GWBDOCS
        WHERE
            NAME = psArchivo;

    --Cursor para verificar que el archivo no se haya cargado antes
    CURSOR cuExiste(
        pnTamano        NUMBER
        ,prDigSHA1        RAW
    ) IS
        SELECT
            GWBAACR_ACTIVITY_DATE        AS Fecha
            ,GWBAACR_USER                AS Usuario
        FROM
            GWBAACR
        WHERE
            GWBAACR_TAMANO = pnTamano
            AND GWBAACR_HASH_SHA1 = prDigSHA1;
            
     --md-02 start     
     cursor ArchExistente   is 
                  SELECT   NAME  ,    DOC_SIZE    , BLOB_CONTENT
                  -- from SWBFOTO   --md-x
                  from   GWBDOCS
                  WHERE NAME like  vsNameArchivo
                  order by LAST_UPDATED desc;
     
     --md-02 end            

BEGIN    

     vsNameArchivo := '%'||substr(psArchivo,instr(psArchivo,'/') + 1)||'%';
     
     -- vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');
     -- Obtengo Numero de secuencia de archivo
     vnNumProcCarga := pk_Util.f_NumSec('CARGA_CRM');
     --vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);
     vgsUsr := NVL(vgsUSR,USER);

      for cAExiste in ArchExistente loop
          vsArchExitente   :=  cAExiste.NAME; 
          vsArchExSize     := cAExiste.DOC_SIZE;
          vrArchivoExBlob := cAExiste.BLOB_CONTENT;
          exit;  
      end loop; 

      if vsArchExSize  > 0 then
         select count(1) into viArchVivo
         from  GWBDOCS
         where  DOC_SIZE = vsArchExSize
         and NAME like vsNameArchivo; 
      end if;
      
      -- existe archivo , se marca en bitacora de error y se para el proceso.      
      if viArchVivo > 0 then
   
          INSERT INTO GWRERRO VALUES (cgsCodApp,psArchivo ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);
          
           insert into twraacp values ( cgsCodApp, vnNumProcCarga, 1, 'Arch Repetido ' || vsNameArchivo , 'X' , 'Archivo_Repetido' , sysdate, vgsUSR); 
           
           for  cur_hast in (select GWBAACR_HASH_SHA1  has
                                   from GWBAACR
                                   where GWBAACR_NOMBRE_ARCHIVO = psArchivo
                                   and GWBAACR_TAMANO = vsArchExSize
                                   order by GWBAACR_ACTIVITY_DATE desc ) loop 
                 vrDigestionSHA1 :=  cur_hast.has; 
                 exit       ;
           end loop;             
           
          INSERT INTO GWBAACR ( GWBAACR_NOMBRE_ARCHIVO  ,GWBAACR_TIPO    ,GWBAACR_NUM_REGISTROS  ,GWBAACR_TAMANO
                                                ,GWBAACR_HASH_SHA1  ,GWBAACR_NUM_PROCESO   ,GWBAACR_ACTIVITY_DATE                      ,GWBAACR_USER
                                 )VALUES(  psArchivo  ,cgsCodApp   ,1   ,vsArchExSize
                                                ,vrDigestionSHA1                ,vnNumProcCarga                      ,SYSDATE                      ,vgsUSR                 );
                                                
          delete  from swbfoto
          where name like  vsNameArchivo;                                                
                       
         COMMIT;
         RETURN;              --md-x           
      end if;
      
      -- aqui ya se valido el achivo y se puede copiar. de foto a gwbdocs 
     INSERT INTO  GWBDOCS( SELECT   x.NAME          ,  x.MIME_TYPE     ,
                                                         x.DOC_SIZE      , x.DAD_CHARSET   ,
                                                         x.LAST_UPDATED  , x.CONTENT_TYPE  ,
                                                         NULL          , x.BLOB_CONTENT  ,
                                                         x.PLAIN_TEXT    , x.NOT_READ
                                            from SWBFOTO  x
                                            WHERE x.NAME like  vsNameArchivo );
                 
     delete  from swbfoto
     where name like  vsNameArchivo;
     
     commit;     

     for cur_doc in (SELECT DOC_SIZE ,BLOB_CONTENT
                            FROM GWBDOCS
                            WHERE NAME like  vsNameArchivo
                            order by last_updated desc ) loop

        vnTamano      := cur_doc.DOC_SIZE;
        vrArchivoBLOB := cur_doc.BLOB_CONTENT;
        exit;

     end loop;     


--vsNombreArchivoCorto:= SUBSTR(REPLACE(psArchivo,' ',''),1,10);
---------------------------SE PONE ESTAS INSTRUCCIONES que envio Roman  para la nueva carga de archivos     md.vic 30.12.2014
--INSERT INTO  GWBDOCS(
--                 SELECT   vsNombreArchivoCorto           ,  x.MIME_TYPE     ,
--                          x.DOC_SIZE      , x.DAD_CHARSET   ,
--                          x.LAST_UPDATED  , x.CONTENT_TYPE  ,
--                          NULL          , x.BLOB_CONTENT  ,
--                          x.PLAIN_TEXT    , x.NOT_READ
--                 from SWBFOTO  x
--                 WHERE x.NAME = psArchivo );
--     insert into swrpaso values ( 'carga pk-CRM-virgil-1' ,  psArchivo);
--       Commit;
--
-- -- vsNameArchivo := '%'||substr(psArchivo,instr(psArchivo,'/') + 1)||'%';
--
-- delete from SWBFOTO
-- where name = psArchivo;
--
--commit;

    --obtengo los datos del archivo
--    OPEN cuArch(vsNombreArchivoCorto);
--        FETCH cuArch INTO vnTamano ,vrArchivoBLOB;
--    CLOSE cuArch;

    --calculo la firma SHA1 del archivo
    vrDigestionSHA1 := DBMS_CRYPTO.HASH(vrArchivoBLOB,DBMS_CRYPTO.HASH_SH1);

--    --Muestro los datos del archivo
--    p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
--    p_ImprimeLineaResultado ('Tamaño de archivo: ' || vnTamano);
--    p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);

    --busco que no se haya subido antes este mismo archivo
--    OPEN cuExiste(vnTamano, vrDigestionSHA1);
--    FETCH cuExiste INTO vdFechaAnt ,vsUserAnt;
--    vbExiste := cuExiste%FOUND;
--    CLOSE cuExiste;

    --Si existió el archivo indico que no se puede volver a subir este mismo
    --archivo
    --    IF vbExiste THEN
    --        --Elimino el archivo recien subido
    --        DELETE GWBDOCS
    --        WHERE NAME = psArchivo;
    --
    --        COMMIT;
    --        /*
    --        INSERT INTO GWRERRO
    --        VALUES (
    --        cgsCodApp,
    --        psArchivo,
    --        'Este archivo ya se había subido anteriormente.',
    --         SYSDATE,
    --         user);
    --        commit;
    --        */
    --        INSERT INTO GWRERRO
    --        VALUES(cgsCodApp,psArchivo, vsalida, SYSDATE, user   );
    --        commit;
    --        --Informo al usuario.
    --      --  p_ImprimeLineaResultado (
    --      --      'Este archivo ya se había subido anteriormente.');
    --       -- p_ImprimeLineaResultado (
    --       --     'Usuario: '||vsUserAnt||'. Fecha y Hora: '
    --      --      ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.'
    --       --     );
    --      --  p_ImprimeLineaResultado ('No se procesará.');
    --
    --        --No tiene mucho caso seguir aqui adentro :p
    --        RETURN;
    --    END IF;

    --Obtengo Numero de secuencia de archivo
    --vnNumProcCarga := pk_Util.f_NumSec('CARGA_CRM');

    --Imprimo el numero de proceso
    --p_ImprimeLineaResultado ('Número de proceso: ' || vnNumProcCarga);

    --Si sigo aqui es que el archivo existe, procedo a convertir BLOB a CLOB
    vsArchivoCLOB := pk_UtilCrgEnvArch.f_BLOBaCLOB(vrArchivoBLOB);

    --Convierto los saltos de linea de unix a dos
    pk_UtilCrgEnvArch.p_ConvSaltoLineaUnixDos(vsArchivoCLOB);

    --comienzo a extraer las lineas del archivo
    vni := 1;
    vnNumLineas := 0;

    WHILE vni <= vnTamano LOOP
        vsLinea := pk_UtilCrgEnvArch.f_ExtraeLineaCLOB(vsArchivoCLOB, vni);

        --verificamos que no se haya regresado null
        IF vsLinea IS NOT NULL THEN
            --Incremento mi contador de lineas
            vnNumLineas := vnNumLineas + 1;
            --Obtengo el tamaño de la linea
            vnTamLinea := LENGTH(vsLinea);
            --Incremento la posicion actual
            vni := vni + vnTamLinea;
            --Linea de depuracion
            --si no es la primera linea forzosamente es un registro
            p_DesglosaRegistro(vsLinea, vsStatus, vsMensajeProc);

            --En base al estatus mando el mensaje de error
            CASE vsStatus
                WHEN 'A' THEN
                    vsMensajeProc := 'Registro Correcto: '  || vsMensajeProc; 
                    -- p_ImprimeLineaResultado('Registro Correcto: '  || vsMensajeProc);
                WHEN 'W' THEN
                   vsMensajeProc :=  'Advertencia: '  || vsMensajeProc ; 
                    -- p_ImprimeLineaResultado('Advertencia: '  || vsMensajeProc);
                WHEN 'R' THEN
                   vsMensajeProc := 'Registro no procesado: ' || vsMensajeProc; 
                    --p_ImprimeLineaResultado('Registro no procesado: ' || vsMensajeProc);
                WHEN 'E' THEN
                   vsMensajeProc := 'Error : ' || vsMensajeProc;
                    --p_ImprimeLineaResultado('Error: ' || vsMensajeProc);
                ELSE
                    vsMensajeProc := 'Error  no codificado : ' || vsMensajeProc;
                    --p_ImprimeLineaResultado(vsMensajeProc);
            END CASE;

            --Guardar registro en tabla de auditoria
            INSERT INTO SWRRCRM(
                SWRRCRM_NOMBRE_ARCHIVO
                ,SWRRCRM_NUM_PROCESO
                ,SWRRCRM_NUM_LINEA
                ,SWRRCRM_CONTENIDO
                ,SWRRCRM_RESULTADO
                ,SWRRCRM_MENSAJE
                ,SWRRCRM_ACTIVITY_DATE
                ,SWRRCRM_USER
            )VALUES(
                psArchivo
                ,vnNumProcCarga
                ,vnNumLineas
                ,vsLinea
                ,vsStatus
                ,vsMensajeProc
                ,SYSDATE
                ,psUser
            );

        END IF;

        --agrego a la posicion el tanaño del salto de linea \r\n
        --caso paranoico, ver como podriamos ajustar esto para
        --que no quedara en codigo duro y aceptara saltos de linea al estilo
        --unix \n puro.
        vni := vni + 2;
        -- lo puse afuera para evitar ciclos infinitos, pero podría tener
        -- efectos secundarios :s :s :s

    END LOOP;

    --si llegamos aqui todo debería estar nice :)
    --Guardo los datos del archivo en la tabla de auditoria
    INSERT INTO GWBAACR (
        GWBAACR_NOMBRE_ARCHIVO
        ,GWBAACR_TIPO
        ,GWBAACR_NUM_REGISTROS
        ,GWBAACR_TAMANO
        ,GWBAACR_HASH_SHA1
        ,GWBAACR_NUM_PROCESO
        ,GWBAACR_ACTIVITY_DATE
        ,GWBAACR_USER
    )VALUES(
        psArchivo
        ,'CRM'
        ,vnNumLineas
        ,vnTamano
        ,vrDigestionSHA1
        ,vnNumProcCarga
        ,SYSDATE
        ,psUser
    );

    --MANDO A TABLAS DEFINITIVAS;
    COMMIT;

    --Indico al usuario que ya termine
  --  p_ImprimeLineaResultado('Procesamiento del archivo terminado.');


EXCEPTION
    WHEN OTHERS THEN
        --si llega a pasar algo cucho :'(
        ROLLBACK;
vsalida := sqlerrm||'+++'||sqlcode;
        --Indico el error.
        /*
        p_ImprimeLineaResultado('Error: '||sqlcode || '. '
            || replace(sqlerrm,'"','\"'));
            */
 INSERT INTO GWRERRO
        VALUES(cgsCodApp,psArchivo, vsalida, SYSDATE, user   );
        commit;

END p_Carga;

/******************************************************************************
PROCEDIMIENTO:        p_DesglosaRegistro
OBJETIVO:            Verifica un registro de pago. Si es correcto el formato
                    ejecuta el proceso de aplicación de pagos, así mismo
                    guarda el registro en la tabla de bitácora
PARAMETROS:
psLinea:            Linea de texto a procesar como registro de pago
psRes:                Parametro de salida, guarda el resultado del procesamiento:
                    A - Aprobado/Aplicado, R - Rechazado
                    W - Aplicado con advertencias, E - Error
psMsg:                Parametro de salida, Mensaje de resultado de la operacion
******************************************************************************/
PROCEDURE p_DesglosaRegistro(
    psLinea        IN        VARCHAR2
    ,psRes        IN OUT VARCHAR2
    ,psMsg        IN OUT VARCHAR2
) IS

    --Variable para guardar el estutos de la operacion
    vsResultado            VARCHAR2(1);
    --Variable para guardar el mensaje de salida (resultado del procesamiento)
    vsMensaje            VARCHAR2(4000);
    --Rut del alumno
    vsRutAlumno            VARCHAR2(20):= NULL;
    --Codigo de Carrera
    vsPrograma            VARCHAR2(30);
    vsHSGR_DATE            VARCHAR2(30);
    --Tipo registro de la tabla temporal
    vtRegTemp            t_RegSWBTCRM;
    --Fecha de Nacimiento
    vsFecha                VARCHAR2(30);

BEGIN

    --obtengo el RUT del alumno
    vsRutAlumno := pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 1);

    --si la cadena esta vacia
    IF vsRutAlumno IS NULL THEN
        vsResultado := cgsR; --Rechazado
        vsMensaje := 'No se encontró el RUT del alumno';
        psRes := vsResultado;
        psMsg := vsMensaje;
        RETURN;
    END IF;

    --obtengo el programa
    vsPrograma := pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 6);
    IF vsPrograma IS NULL THEN
        vsResultado := cgsR; --Rechazado
        vsMensaje := 'No se encontró el Programa del alumno';
        psRes := vsResultado;
        psMsg := vsMensaje;
        RETURN;

    END IF;

    --Obtengo todos los valores


    vtRegTemp.SWBTCRM_RUT := vsRutAlumno;
    vtRegTemp.SWBTCRM_TERM_CODE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 2);
    vtRegTemp.SWBTCRM_SARHEAD_CODE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 3);
    vtRegTemp.SWBTCRM_SARHEAD_APLS_CODE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 4);
    vtRegTemp.SWBTCRM_SARHEAD_ADD_DATE :=
        TRUNC(SYSDATE);
    vtRegTemp.SWBTCRM_SARETRY_PROGRAMA := vsPrograma;
    vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 7);
    vtRegTemp.SWBTCRM_SARETRY_PRIORITY_NO :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 8);
    vtRegTemp.SWBTCRM_SARADDR_STREET_LINE1 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 9);
    vtRegTemp.SWBTCRM_SARADDR_STREET_LINE2 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 10);
    vtRegTemp.SWBTCRM_SARADDR_STREET_LINE3 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 11);
    vtRegTemp.SWBTCRM_SARADDR_CITY :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 12);
    vtRegTemp.SWBTCRM_SARADDR_STAT_CDE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 13);
    vtRegTemp.SWBTCRM_SARADDR_CNTY_CDE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 14);
    vtRegTemp.SWBTCRM_SARADDR_ZIP :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 15);
    vtRegTemp.SWBTCRM_SARADDR_NATN_CDE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 16);
    vtRegTemp.SWBTCRM_SARPHON_PQLF_CDE1 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 17);
    vtRegTemp.SWBTCRM_SARPHON_PHONE1 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 18);
    vtRegTemp.SWBTCRM_SARPHON_PQLF_CDE2 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 19);
    vtRegTemp.SWBTCRM_SARPHON_PHONE2 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 20);
    vtRegTemp.SWBTCRM_SARPHON_PQLF_CDE3 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 21);
    vtRegTemp.SWBTCRM_SARPHON_PHONE3 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 22);
    vtRegTemp.SWBTCRM_SARPERS_FIRST_NAME :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 23);
    vtRegTemp.SWBTCRM_SARPERS_LAST_NAME :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 24);
    vtRegTemp.SWBTCRM_SARPERS_MIDDLE_NAME1 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 25);

    vsFecha := TRIM(pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 26));
    --Si la fecha es nula o igual a '', lo caul creo que en PL es redundante...
    IF vsFecha IS NULL OR LENGTH(vsFecha) < 1 THEN
        vtRegTemp.SWBTCRM_SARPERS_BIRTH_DATE := NULL;
    ELSE
        vtRegTemp.SWBTCRM_SARPERS_BIRTH_DATE := TO_DATE(vsFecha,'DD/MM/YYYY');
    END IF;

    vtRegTemp.SWBTCRM_SARPERS_GENDER :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 27);
    vtRegTemp.SWBTCRM_SARPERS_CITZ_CDE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 28);
    vtRegTemp.SWBTCRM_SARHSCH_IDEN_CDE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 29);

    vsHSGR_DATE := pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 30);
    IF vsHSGR_DATE IS NULL OR LENGTH(TRIM(vsHSGR_DATE)) < 1  THEN
        vtRegTemp.SWBTCRM_SARHSCH_HSGR_DATE := TO_CHAR(SYSDATE,'YYYY');
    ELSE
        vtRegTemp.SWBTCRM_SARHSCH_HSGR_DATE := vsHSGR_DATE;
    END IF;

    vtRegTemp.SWBTCRM_SARPCOL_IDEN_CDE :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 31);
    vtRegTemp.SWBTCRM_SARRQST_ANSR_DESC :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 32);
    vtRegTemp.SWBTCRM_SARRQST_ANSR_DESC2 :=
        pk_UtilCrgEnvArch.f_ExtraeCampo(psLinea, 33);


    --p_AplicaArchivo devuelve el estatus y el mensaje de la operación
    p_ProcesaRegistro (vtRegTemp ,psRes ,psMsg );


EXCEPTION
    WHEN OTHERS THEN
        psRes := 'E';
        psMsg := 'Rut: '||vsRutAlumno||'. Programa: '||vsPrograma ||'. '
            ||'Error! Codigo: ' ||sqlcode || '. Descripcion: ' || sqlerrm;
        RETURN;
END p_DesglosaRegistro;

PROCEDURE p_ProcesaRegistro (
    vtRegTemp IN OUT NOCOPY t_RegSWBTCRM
    ,psRes        IN OUT VARCHAR2
    ,psMsg        IN OUT VARCHAR2
) IS

    --Variable para guardar el estutos de la operacion
    vsResultado            VARCHAR2(1);
    --Variable para guardar el mensaje de salida (resultado del procesamiento)
    vsMensaje            VARCHAR2(4000);

    --Rut actual
    vsRut                VARCHAR2(20);
    --Aidm actual
    vsAidm                VARCHAR2(20);
    --Numero de carreras actual
    vnNumProgs            PLS_INTEGER;

    --Bandera para aidm encontrado
    vsAidmEnc            VARCHAR2(1) := NULL;

    --Id global
    vnId                PLS_INTEGER;
    --Contador comun y corriente
    vni                    PLS_INTEGER;
    --variable para guardar la regla de curriculum
    vsRegla                SOBCURR.SOBCURR_CURR_RULE%TYPE;
    vsRegla1            SOBCURR.SOBCURR_CURR_RULE%TYPE;
    vsSABNSTU            NUMBER(8);



BEGIN

    --Obtengo el Rut actual, le quito el guion, antes que cualquier cosa
    vsRut := REPLACE(vtRegTemp.SWBTCRM_RUT,'-','');

    --Marca el registro de prueba PSU de la persona para que se vuelva a
    --calcular
    UPDATE
        SWBEPSU
    SET
        SWBEPSU_IND = NULL
    WHERE
        SWBEPSU_RUT = vtRegTemp.SWBTCRM_RUT;

    --Verifico si existe el aidm en nuestra lista temporal
    IF vtListaAidms.EXISTS(vsRut) THEN
        --Si existio verifico que el numero de carreras no sea 3
        --IF vtListaProgs(vsRut).COUNT >= 3 THEN
            --Indico que ya tiene mas de tres programas registrados y salimos
          --  psRes := cgsR;
            --psMsg := cgsMsg1001;
            --RETURN; --Terminamos
        --END IF;

        --Marcamos el aidm actual como el que esta en el rut
        vsAidm := vtListaAidms(vsRut);

    ELSE
        --si no existió el rut en nuestra lista temporal
        BEGIN
            --Busco el aidm
            SELECT UNIQUE
                SABNSTU_AIDM
                ,cgsY
            INTO
                vsAidm
                ,vsAidmEnc
            FROM
                SABNSTU
            WHERE
                SABNSTU_ID = vsRut;

        EXCEPTION
            WHEN TOO_MANY_ROWS THEN
                --Caso que no debería suceder, varios aidm's para un mismo
                --rut
                psRes := cgsR;
                psMsg := 'Rut: '||vtRegTemp.SWBTCRM_RUT
                    ||'. Programa: '||vtRegTemp.SWBTCRM_SARETRY_PROGRAMA
                    ||'. '||cgsMsg1002;
                RETURN; --Terminamos
            WHEN NO_DATA_FOUND THEN
                --Si no encontramos el aidm marco una bandera
                vsAidmEnc := cgsN;
        END;

        --Si existe el aidm
        IF vsAidmEnc = cgsY THEN
            --Guardamos el AIDM en la lista de rut's vs. aidm's
            vtListaAidms(vsRut) := vsAidm;

            --Guardamos la lista de programa
            BEGIN
                SELECT
                    SOBCURR_PROGRAM
                    ,SARHEAD_WAPP_CODE
                    ,SARHEAD_TERM_CODE_ENTRY
                BULK COLLECT INTO
                    vtListaProgs(vsRut)
                FROM
                    SOBCURR
                    ,SARETRY
                    ,SARHEAD
                WHERE
                    SOBCURR_CURR_RULE = SARETRY_CURR_RULE
                    AND SARHEAD_AIDM = SARETRY_AIDM
                    AND SARHEAD_APPL_SEQNO = SARETRY_APPL_SEQNO
                    AND SARETRY_AIDM = vsAidm;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    --Si no hubo datos, caso extraño, inicializo en ceros
                    vtListaProgs(vsRut) := t_ArrProgs();
            END;

        ELSE
            --si no existio el AIDM, lo creamos
            --SELECT SATURN.SABASEQ.NEXTVAL INTO global_aidm FROM DUAL;
            global_aidm := SATURN.SABASEQ.NEXTVAL;
            vsAidm :=  global_aidm;
            vtRegTemp.SWBTCRM_AIDM := vsAidm;

            --Insertamos en sabnstu
            INSERT INTO SABNSTU (
                SABNSTU_ID
                ,SABNSTU_AIDM
                ,SABNSTU_LOCKED_IND
                ,SABNSTU_ACTIVITY_DATE
            )VALUES(
                vsRut
                ,vtRegTemp.SWBTCRM_AIDM
                ,cgsN
                ,SYSDATE
            );

            --Actualizamos la lista de rut's vs aidms:
            vtListaAidms(vsRut) := vsAidm;
            --Creo la lista de programas para el rut
            vtListaProgs(vsRut) := t_ArrProgs();

        END IF;

    END IF;

    --Verifico que esta carrera no haya sido solicitada
    FOR vni IN 1..vtListaProgs(vsRut).COUNT LOOP
        IF vtListaProgs(vsRut)(vni).Programa =
            vtRegTemp.SWBTCRM_SARETRY_PROGRAMA
            AND vtListaProgs(vsRut)(vni).TipoAd =
            vtRegTemp.SWBTCRM_SARHEAD_CODE
            AND vtListaProgs(vsRut)(vni).Periodo
            = vtRegTemp.SWBTCRM_TERM_CODE
        THEN
            --si la carrera ya estaba con la via de admision ...
            --marco como rechazado con el mensaje de error apropiado
            psRes := cgsR;
            psMsg := 'Rut: '||vtRegTemp.SWBTCRM_RUT
                ||'. Programa: '
                ||vtRegTemp.SWBTCRM_SARETRY_PROGRAMA||'. '
                ||cgsMsg1003;
            RETURN;
        END IF;
    END LOOP;


    vtRegTemp.SWBTCRM_AIDM := vsAidm;
    --Insertamos en la tabla SARHEAD

    --Marce!!! y este select pa que rayos es?
    --Bueno ya vi pa que es, es para solo insertar una vez sarhead. Gil :P
    SELECT COUNT(1) INTO vnSarhead FROM SARHEAD
    WHERE SARHEAD_AIDM = vtRegTemp.SWBTCRM_AIDM
    AND SARHEAD_APPL_SEQNO = vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO;

    --Valido que no exista sarhead
    IF vnSarhead < 1 THEN
        INSERT INTO SARHEAD VALUES(
            vtRegTemp.SWBTCRM_AIDM
            ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
            ,cgsY
            ,vtRegTemp.SWBTCRM_SARHEAD_ADD_DATE
            ,cgsN, cgsN, cgsN ,cgsU ,SYSDATE
            ,vtRegTemp.SWBTCRM_TERM_CODE ,vtRegTemp.SWBTCRM_SARHEAD_CODE
            ,vtRegTemp.SWBTCRM_SARHEAD_APLS_CODE
            ,cgsNull ,cgsNull ,cgsNull ,cgsNull ,cgsNull ,cgsNull
            ,cgsNull ,cgsNull,cgsNull ,cgsNull ,cgsNull ,cgsADDITIONAL
            ,cgsNull,cgsNull,cgsNull  ,vtRegTemp.SWBTCRM_SARETRY_PRIORITY_NO
        );
    END IF;
    --insertamos en al tabla saraddr
    INSERT INTO SARADDR (
        SARADDR_AIDM
        ,SARADDR_APPL_SEQNO ,SARADDR_PERS_SEQNO
        ,SARADDR_SEQNO ,SARADDR_LOAD_IND
        ,SARADDR_ACTIVITY_DATE ,SARADDR_STREET_LINE1
        ,SARADDR_STREET_LINE2 ,SARADDR_CITY
        ,SARADDR_STAT_CDE ,SARADDR_ZIP
        ,SARADDR_NATN_CDE,SARADDR_STREET_LINE3
        ,SARADDR_LCQL_CDE,SARADDR_CNTY_CDE
    )VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1,cgn1,cgsN ,SYSDATE
        ,vtRegTemp.SWBTCRM_SARADDR_STREET_LINE1
        ,vtRegTemp.SWBTCRM_SARADDR_STREET_LINE2
        ,vtRegTemp.SWBTCRM_SARADDR_CITY
        ,vtRegTemp.SWBTCRM_SARADDR_STAT_CDE
        ,vtRegTemp.SWBTCRM_SARADDR_ZIP
        ,vtRegTemp.SWBTCRM_SARADDR_NATN_CDE
        ,vtRegTemp.SWBTCRM_SARADDR_STREET_LINE3
        ,cgsPR
        ,vtRegTemp.SWBTCRM_SARADDR_CNTY_CDE
    );

    --Insertamos en saretry
    --Primero buscamos la regla de curriculum
    BEGIN
        SELECT
            SOBCURR_CURR_RULE, SORCMJR_CMJR_RULE
        INTO
            vsRegla, vsRegla1
        FROM
            SOBCURR, SORCMJR A
        WHERE
            SOBCURR_CURR_RULE = SORCMJR_CURR_RULE
            AND A.SORCMJR_TERM_CODE_EFF = (SELECT MAX(B.SORCMJR_TERM_CODE_EFF) FROM SORCMJR B
                                            WHERE B.SORCMJR_Curr_RULE =SOBCURR_CURR_RULE
                                            AND B.SORCMJR_TERM_CODE_EFF <= '201310')
            AND SOBCURR_PROGRAM = vtRegTemp.SWBTCRM_SARETRY_PROGRAMA
            AND SORCMJR_MAJR_CODE = SUBSTR(vtRegTemp.SWBTCRM_SARETRY_PROGRAMA,4,4);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            --Aqui tengo mis dudas...
            vsRegla := cgsNull;
    END;

    INSERT INTO SARETRY (
        SARETRY_AIDM
        ,SARETRY_APPL_SEQNO
        ,SARETRY_SEQNO
        ,SARETRY_LOAD_IND
        ,SARETRY_ACTIVITY_DATE
        ,SARETRY_PRIORITY
        ,SARETRY_CURR_RULE
    )VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1,cgsN,SYSDATE ,cgn1,vsRegla
    );

    --Insertamos en tabla SAREFOS
    INSERT INTO SAREFOS VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1 ,cgn1 ,cgsN ,SYSDATE ,cgsM ,cgsNull ,cgsNull
        ,cgsNull ,cgsNull ,vsRegla1
    );

    --Insertamos en la tabla SARPHON
    INSERT INTO SARPHON (
        SARPHON_AIDM
        ,SARPHON_APPL_SEQNO
        ,SARPHON_PERS_SEQNO
        ,SARPHON_SEQNO
        ,SARPHON_LOAD_IND
        ,SARPHON_ACTIVITY_DATE
        ,SARPHON_PQLF_CDE
        ,SARPHON_PHONE
    )VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1 ,cgn1 ,cgsN ,SYSDATE
        ,vtRegTemp.SWBTCRM_SARPHON_PQLF_CDE1
        ,RPAD(cgsWEB||vtRegTemp.SWBTCRM_SARPHON_PHONE1,53,' ')
    );

    --Insertamos en la tabla SARPHON, telefono 2
    INSERT INTO SARPHON (
        SARPHON_AIDM
        ,SARPHON_APPL_SEQNO
        ,SARPHON_PERS_SEQNO
        ,SARPHON_SEQNO
        ,SARPHON_LOAD_IND
        ,SARPHON_ACTIVITY_DATE
        ,SARPHON_PQLF_CDE
        ,SARPHON_PHONE
    )VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1 ,cgn2 ,cgsN ,SYSDATE
        ,vtRegTemp.SWBTCRM_SARPHON_PQLF_CDE2
        ,RPAD(cgsWEB||vtRegTemp.SWBTCRM_SARPHON_PHONE2,53, ' ')
    );

    --Telefono 3
    INSERT INTO SARPHON (
        SARPHON_AIDM
        ,SARPHON_APPL_SEQNO
        ,SARPHON_PERS_SEQNO
        ,SARPHON_SEQNO
        ,SARPHON_LOAD_IND
        ,SARPHON_ACTIVITY_DATE
        ,SARPHON_PQLF_CDE
        ,SARPHON_PHONE
    )VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1 ,cgn3 ,cgsN ,SYSDATE
        ,vtRegTemp.SWBTCRM_SARPHON_PQLF_CDE3
        ,vtRegTemp.SWBTCRM_SARPHON_PHONE3
    );

    --Insertamos en SARHSCH
    INSERT INTO SARHSCH (
        SARHSCH_AIDM
        ,SARHSCH_APPL_SEQNO
        ,SARHSCH_SEQNO
        ,SARHSCH_LOAD_IND
        ,SARHSCH_ACTIVITY_DATE
        ,SARHSCH_IDQL_CDE1
        ,SARHSCH_IDEN_CDE1
        ,SARHSCH_DFMT_CDE_HSGR
        ,SARHSCH_ENTY_CDE1
        ,SARHSCH_HSGR_DTE
    )VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1 ,cgsN ,SYSDATE ,cgsWB
        ,vtRegTemp.SWBTCRM_SARHSCH_IDEN_CDE
        ,cgsMDC ,cgsHS
        ,cgs0101||vtRegTemp.SWBTCRM_SARHSCH_HSGR_DATE
    );

    --Insertamos en sarpcol
    INSERT INTO SARPCOL(
        SARPCOL_AIDM
        ,SARPCOL_APPL_SEQNO
        ,SARPCOL_SEQNO
        ,SARPCOL_LOAD_IND
        ,SARPCOL_ACTIVITY_DATE
        ,SARPCOL_IDQL_CDE
        ,SARPCOL_IDEN_CDE
        ,SARPCOL_INST_NAME
    )VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1 ,cgsN ,SYSDATE ,cgsWB
        ,vtRegTemp.SWBTCRM_SARPCOL_IDEN_CDE ,cgsNull
    );

    --Doble insert en sarrqst
    INSERT INTO SARRQST (
        SARRQST_AIDM
        ,SARRQST_APPL_SEQNO
        ,SARRQST_SEQNO
        ,SARRQST_LOAD_IND
        ,SARRQST_ACTIVITY_DATE
        ,SARRQST_QSTN_DESC
        ,SARRQST_ANSR_DESC
        ,SARRQST_WUDQ_NO
    )VALUES (
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1 ,cgsN ,SYSDATE ,cgsPregunta1
        ,vtRegTemp.SWBTCRM_SARRQST_ANSR_DESC ,cgn5
    );

    INSERT INTO SARRQST (
        SARRQST_AIDM
        ,SARRQST_APPL_SEQNO
        ,SARRQST_SEQNO
        ,SARRQST_LOAD_IND
        ,SARRQST_ACTIVITY_DATE
        ,SARRQST_QSTN_DESC
        ,SARRQST_ANSR_DESC
        ,SARRQST_WUDQ_NO
    )VALUES (
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn2 ,cgsN ,SYSDATE ,cgsPregunta2
        ,vtRegTemp.SWBTCRM_SARRQST_ANSR_DESC2 ,cgn5
    );

    --insertamos en sarpers
    INSERT INTO SARPERS (
        SARPERS_AIDM
        ,SARPERS_APPL_SEQNO
        ,SARPERS_SEQNO
        ,SARPERS_LOAD_IND
        ,SARPERS_ACTIVITY_DATE
        ,SARPERS_FIRST_NAME
        ,SARPERS_LAST_NAME
        ,SARPERS_SUFFIX
        ,SARPERS_DFMT_CDE_BIRTH
        ,SARPERS_BIRTH_DTE
        ,SARPERS_MIDDLE_NAME1
        ,SARPERS_GENDER
        ,SARPERS_CITZ_CDE
    )VALUES(
        vtRegTemp.SWBTCRM_AIDM
        ,vtRegTemp.SWBTCRM_SARETRY_APPL_SEQNO
        ,cgn1 ,cgsN ,SYSDATE
        ,vtRegTemp.SWBTCRM_SARPERS_FIRST_NAME
        ,vtRegTemp.SWBTCRM_SARPERS_LAST_NAME
        ,vtRegTemp.SWBTCRM_RUT ,cgsMDC
        ,TO_CHAR(vtRegTemp.SWBTCRM_SARPERS_BIRTH_DATE, cgsMMDDYYYY)
        ,vtRegTemp.SWBTCRM_SARPERS_MIDDLE_NAME1
        ,vtRegTemp.SWBTCRM_SARPERS_GENDER
        ,vtRegTemp.SWBTCRM_SARPERS_CITZ_CDE
    );

    --Insertamos el programa del registro en la lista de programas vs rut
    vtListaProgs(vsRut).EXTEND(1);
    vtListaProgs(vsRut)(vtListaProgs(vsRut).COUNT).Programa :=
        vtRegTemp.SWBTCRM_SARETRY_PROGRAMA;
    vtListaProgs(vsRut)(vtListaProgs(vsRut).COUNT).TipoAd :=
        vtRegTemp.SWBTCRM_SARHEAD_CODE;

    --Indico que la operacion salio OK
    psRes := 'A';
    psMsg := 'Rut: '||vtRegTemp.SWBTCRM_RUT||'. Programa: '
            ||vtRegTemp.SWBTCRM_SARETRY_PROGRAMA||'. OK';


EXCEPTION
    WHEN OTHERS THEN
        psRes := 'E';
        psMsg := 'Rut: '||vtRegTemp.SWBTCRM_RUT||'. Programa: '
            ||vtRegTemp.SWBTCRM_SARETRY_PROGRAMA||'. '||'Error! Codigo: '
            ||sqlcode || '. Descripcion: ' || sqlerrm;
        RETURN;

END p_ProcesaRegistro;


/******************************************************************************
PROCEDIMIENTO:        p_ImprimeLineaResultado
OBJETIVO:            Genera una linea con el mensaje y/o HTML indicado en la
                    pagina de resultados
PARAMETROS:
psLinea                Mensaje y/o HTML a mostrar
******************************************************************************/
PROCEDURE p_ImprimeLineaResultado(
    psLinea                VARCHAR2
) IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(psLinea);

END p_ImprimeLineaResultado;

END pk_CargaCRM_NV;
/
CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaAdicionalDemre_NV  IS
--CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaAdicionalDemre_NV IS


/******************************************************************************
PAQUETE:           BANINST1.pk_CargaAdicionalDemre_NV
OBJETIVO:          Contiene los procedimientos, funciones y variables
                         requeridos para la carga de archivos DEMRE
AUTOR:              Roman Ruiz
FECHA:              30 jun 2014
--------------------------------------------
modificacion        md-01
objetivo              cambio de paqute de carga de archivos (kwaproceso)
autor                  roman ruiz
fecha                 26-feb-2014
--------------------------------------------
modificacion        md-02
objetivo            correccion en errores de duplicidad
autor               roman ruiz
fecha               26-ene-2016
--------------------------------------------
modificacion        md-03
objetivo            unificar metodo de carga
autor               roman ruiz
fecha               8-feb-2016
--------------------------------------------
modificacion      md-04
objetivo            correcion de duplicidad y agregar campo de colegio 
autor               roman ruiz
fecha               15-feb-2016
******************************************************************************/

    --variable para seguridad GWAMNUR
    vgsUSR              VARCHAR2(500);
    global_aidm         SABNSTU.SABNSTU_AIDM%TYPE;
    global_id           SABNSTU.SABNSTU_ID%TYPE;
    cgsCodApp           CONSTANT VARCHAR2(4) := 'CADD';   -- CARGA ADICIONAL Datos DEMRE
    vsNomSeq            VARCHAR2(50);
    cgsErr20408         CONSTANT VARCHAR2(200) := 'No esta configurado el Año para proceso CAE';
    cnRoundNum          constant number(1) := 4;     -- decimales a redondear
    csSepara            constant char(1) := ',';

    vsAnioActual          varchar2(6);
    vsPerActual           varchar2(10);
    vsPerPrevio           varchar2(10);
    vdFecActual           date;
    vdFecPrev             date;


----prototipos de Funciones y procedimientos privados

PROCEDURE p_ImprimeLineaResultado(psLinea        VARCHAR2);

----ACTUALIZA SORTEST
PROCEDURE P_ActualizaSortest(piPidm      number
                            ,psAcad      varchar2
                            ,psTipo      varchar2
                            ,psValor     varchar2 );

----fin de prototipos privados

/******************************************************************************
PROCEDIMIENTO:      p_Carga
OBJETIVO:           Procesa un archivo
PARAMETROS:
psArchivo           Nombre con que fue guardado el archivo cargado
                    por el usuario. Este nombre se provee por la base de
                    datos con el que el archivo puede ser extraido de la tabla
                    indicada por la configuración del DAD.
******************************************************************************/

PROCEDURE p_Carga(  psArchivo      VARCHAR2
                   ,psUser         VARCHAR2 DEFAULT USER ) IS

    --Guarda la Firma SHA1 del archivo
    vrDigestionSHA1     RAW(20);
    --Guarda el tamaño del archivo
    vnTamano            NUMBER(10);
    --El archivo en sí, formato BLOB:
    vrArchivoBLOB       BLOB;
    --El archivo en sí, formato CLOB:
    vsArchivoCLOB       CLOB;
    --Variable para verificar que exista el archivo
    vsExiste            CHAR(1);
    --Variable de contador para ver en que posicion estamos del archivo
    vni                 PLS_INTEGER;
    --Variable de contador de lineas
    vnNumLineas         PLS_INTEGER;
    --Variable AAAA para ver cual es el tamaño de la linea
    vnTamLinea          PLS_INTEGER;
    --Variable para guardar la linea en si
    vsLinea             VARCHAR2(4000);
    --Variable de resultado del proceso del registro
    vsStatus            CHAR(1);
    --Variable de resultado del proceso del registro
    vsMensajeProc       VARCHAR2(4000);
    --Variable para guardar el numero de proceso de carga de archivo
    vnNumProcCarga      PLS_INTEGER;
    --Variable para guardar el numero secuencial del bitacora del CAES
    vnBitacoraSeq       PLS_INTEGER;
    --variable para el usuario que habia cargado este archivo previamente
    vsUserAnt           GWBAACR.GWBAACR_USER%TYPE;
    --variable para la fecha en que se habia cargado este archivo previamente
    vdFechaAnt          GWBAACR.GWBAACR_ACTIVITY_DATE%TYPE;

    --manejo de errores
    err_num1   NUMBER;
    err_msg1   VARCHAR2 (1999);

    vnExiste   NUMBER:= 0;
    vnSEQ      VARCHAR2(6);
    vsCODE     VARCHAR2(6);
    vsCODECNTY VARCHAR2(6);
    vnSEQCMT   VARCHAR2(10);

    vsCampo    VARCHAR2(200);
    viNumReg    number;
    vsYEAR                varchar2(4);
    vsFileSeq             number(6);
    vsSeqNum              number(6);
    vsRut                 varchar2(15);
    vsDv                  varchar2(5);
    vsApellido            varchar2(200);
    vsNombre              varchar2(200);
    vsComunaR             varchar2(50);
    vsRegionR             varchar2(50);
    vsPrograma            varchar2(50);
    vsViaAdmin            varchar2(50);
    vsViaAdminDesc        varchar2(200);
    vsPem                 varchar2(50);
    vsNeme                varchar2(50);
    vsPSCI_a              varchar2(50);
    vsPSHC_a              varchar2(50);
    vsPSLC_a              varchar2(50);
    vsPSMA_a              varchar2(50);
    vsPRAN_a              varchar2(50);
    vsPETE_a              varchar2(50);
    vsPSU_a               varchar2(50);
    vsPonderado_a         varchar2(50);
    vsPuntPond            varchar2(50);
    vsColegioCod          varchar2(15);
    vsColegio             varchar2(200);
    viPidm                spriden.spriden_pidm%type;
    
    vsCodBanerCol     varchar2(6); 

    vsError         char(1);
    vsLoad_stat     varchar2(100);
    vsStatusCaeJ    varchar2(4);
    vsStatusCaeH    varchar2(4);

 -------------
     vsTIdentificacion VARCHAR2(1);
    vsNDocumento      VARCHAR2(10);
    vsAProceso        VARCHAR2(4);
    vsPaterno         VARCHAR2(25);
    vsMaterno         VARCHAR2(25);
    vsNombre          VARCHAR2(25);
    vsNacionalidad    VARCHAR2(1);
    vsSexo            VARCHAR2(1);
    vsPreferencia     VARCHAR2(2);
    vsCodigo          VARCHAR2(5);
    vsEstadoP         VARCHAR2(2);
    vsPuntajeP        VARCHAR2(5);
    vsLugarL          VARCHAR2(5);
    vsBEA             VARCHAR2(3);
    vsSEE             VARCHAR2(1);
    vsLocalE          VARCHAR2(4);
    vsUnidadE         VARCHAR2(2);
    vsRBD             VARCHAR2(6);
    vsRamaEducacional VARCHAR2(2);
    vsGrupoD          VARCHAR2(1);
    vsCodigoR         VARCHAR2(2);
    vsCodigoProvincia VARCHAR2(3);
    vsAEgreso         VARCHAR2(4);
    vsPromedioN     VARCHAR2(3);
    vsPuntajeNEM    VARCHAR2(3);
    vsPuntajeRAN    VARCHAR2(3);
    vsLenguajeC     VARCHAR2(3);
    vsMatematicas   VARCHAR2(3);
    vsHistoria      VARCHAR2(3);
    vsCiencias      VARCHAR2(3);
    vsModulo        VARCHAR2(3);
    vsPromMLM       VARCHAR2(4);
    vsFechaN        VARCHAR2(8);
    vsIngresoBF     VARCHAR2(2);
    vsCoberturaS    VARCHAR2(1);
    vsRUTpadre      VARCHAR2(9);
    vsRUTmadre      VARCHAR2(9);
    vsDomicilio     VARCHAR2(174);
    vsStreet        varchar2(75);
    viSequencia     number(5);
    vsPsuYr         varchar2(6);

    vsCalleD        varchar2(40);
    vsNumeroD       varchar2( 7);
    vsBockD         varchar2( 7);
    vsDeptoD        varchar2( 7);
    vsVillaD        varchar2( 40);
    vsRegion        varchar2( 2);
    vsProvincia     varchar2( 3);
    vsComuna        varchar2( 5);
    vsNProvincia    varchar2( 15);
    vsNComuna       varchar2( 15);
    vsCiudad        varchar2( 15);
    vsCodArea       varchar2( 2);
    vsTelefono      varchar2( 8);
    vsPCel          varchar2( 2);
    vsNCel          varchar2( 8);
    vs_ComunaBan    varchar2(10);
    vs_RegionBan    varchar2(10);
    vs_TelOK        varchar2(1);

    vsEmail         VARCHAR2(60);
    vsNTM           VARCHAR2(10);
    vsCodigoIES     VARCHAR2(4);
    vsPondAA        VARCHAR2(1);
    vsPIDM          NUMBER(8);
    vsID            NUMBER(15);
    vs_TESC         VARCHAR2(6);


    --vsNameArchivo varchar2(300);
    
    vsalida                 VARCHAR2(3000);      --md-03  start
    vsNameArchivo     varchar2(300);   
    vsArchExitente      varchar2(300);    
     vsArchExSize       number(10):= 0;
     vrArchivoExBlob   BLOB;
     viArchVivo           number(4) := 0;   
     
     viCuenta            number(6);
     viBitacora          number(6) := 0;  
     vdPrepa            date; 
     
     vdAnioPrepa      date; 
     vsAnio              varchar2(4); 
     vsCarrera        varchar2(5);
     vsProgramaN   varchar2(20);  
     vnPidmst          number(6); 
     
        
     cursor ArchExistente   is 
                  SELECT   NAME  ,    DOC_SIZE    , BLOB_CONTENT
                  -- from SWBFOTO   --md-x
                  from   GWBDOCS
                  WHERE NAME like  vsNameArchivo
                  order by LAST_UPDATED desc;
     
     --md-03 end        

 -------------

   cursor cuPidm is
                   SELECT SPBPERS_PIDM as pidm
                   FROM SPBPERS
                   WHERE SPBPERS_NAME_SUFFIX = vsRut
                     AND SPBPERS_ACTIVITY_DATE = (SELECT MAX(SPBPERS_ACTIVITY_DATE)
                                                                       FROM SPBPERS
                                                                       WHERE SPBPERS_NAME_SUFFIX = vsRut) 
                   ORDER BY  SPBPERS_PIDM desc;


    cursor cuAnioProceso is
                  select SWVCPSU_ACYR_CODE anio,
                         SWVCPSU_TERM_CODE_PRESENT  presente,
                         SWVCPSU_TERM_CODE_PREVIOUS previo ,
                         SWVCPSU_APPL_DATE_PRESENT  fecha_act,
                         SWVCPSU_APPL_DATE_PREVIOUS fecha_ant
                  from SWVCPSU
                  where SWVCPSU_ACYR_CODE = vsPsuYr;

BEGIN

-- Seguridad de GWAMNUR
-- IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;
-- nota esta página por sus características, no es del tipo de separación PL de codigo HTML

--  Inicio de la pagina HTML
 -- DBMS_OUTPUT.PUT_LINE(PK_ObjHTML.vgsCssBanner);
 
    --md-03 start    
     vsNameArchivo := '%'||substr(psArchivo,instr(psArchivo,'/') + 1)||'%';
     vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');
      --Obtengo Numero de secuencia de archivo
      vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);
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
      
      -- existe archivo , se marca en bitacora de error y se para el proceso.   y borro de foto   
      if viArchVivo > 0 then
   
          INSERT INTO GWRERRO VALUES (cgsCodApp,psArchivo ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);
          
           insert into twraacp values ( cgsCodApp, vnNumProcCarga, 1, 'Arch Repetido ' || psArchivo , 'X' , 'Archivo_Repetido' , sysdate, vgsUSR); 

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
                       
         COMMIT; --md-x start
         RETURN;
         --rollback;   -- md-x end                        
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


--md-01 start

--    INSERT INTO  GWBDOCS(
--                 SELECT   x.NAME          ,  x.MIME_TYPE     ,
--                          x.DOC_SIZE      , x.DAD_CHARSET   ,
--                          x.LAST_UPDATED  , x.CONTENT_TYPE  ,
--                          NULL          , x.BLOB_CONTENT  ,
--                          x.PLAIN_TEXT    , x.NOT_READ
--                 from SWBFOTO  x
--                 WHERE x.NAME = psArchivo );
--    Commit;
--
--    vsNameArchivo := '%'||substr(psArchivo,instr(psArchivo,'/') + 1)||'%';
--
--    delete  from SWBFOTO
--    where name like  vsNameArchivo;
--    commit;
--
--    --obtengo los datos del archivo
--    Select  DOC_SIZE, BLOB_CONTENT  INTO  vnTamano,  vrArchivoBLOB
--    FROM   GWBDOCS
--    WHERE  NAME like  vsNameArchivo;



    --calculo la firma SHA1 del archivo
    vrDigestionSHA1 := DBMS_CRYPTO.HASH(vrArchivoBLOB,DBMS_CRYPTO.HASH_SH1);

    --Muestro los datos del archivo
--    p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
--    p_ImprimeLineaResultado ('Tamaño de archivo: ' || vnTamano);
--    p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);

--  verificar que no se haya subido previamente este archivo
-- esta validacion se cancela ya que este archivo fue subido previamente
-- archivo E
/*
    BEGIN

        SELECT GWBAACR_USER  ,GWBAACR_ACTIVITY_DATE INTO vsUserAnt  ,vdFechaAnt
        FROM GWBAACR
        WHERE GWBAACR_TAMANO = vnTamano
        AND GWBAACR_HASH_SHA1 = vrDigestionSHA1;

        vsExiste := 'Y';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vsExiste := 'N';
    END;

--    --Si existe, indico que no se puede volver a subir este mismo archivo
    IF vsExiste = 'Y' THEN
        -- Eliminar el archivo recien subido
        DELETE GWBDOCS
        WHERE  NAME = psArchivo;
        COMMIT;

        --Informo al usuario.
        p_ImprimeLineaResultado ( 'Este archivo ya se había subido anteriormente.');
        p_ImprimeLineaResultado (  'Usuario: '||vsUserAnt||'. Fecha y Hora: '
                                   ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.'  );
        p_ImprimeLineaResultado ('No se procesara .');
        RETURN;

    END IF;
    */

    -- vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');

    --Obtengo Numero de secuencia de archivo
     --vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);

    --vgsUsr := NVL(vgsUSR,USER);

    --Imprimo el numero de proceso
    --p_ImprimeLineaResultado ('Número de proceso: ' || vnNumProcCarga);
    
    --md-03 end

    --coninuando el archivo existe, procedo a convertir BLOB a CLOB
    vsArchivoCLOB := pk_UtilCrgEnvArch.f_BLOBaCLOB(vrArchivoBLOB);

    --Convertir los saltos de linea de unix a dos
    pk_UtilCrgEnvArch.p_ConvSaltoLineaUnixDos(vsArchivoCLOB);

    --inicio el extraer las lineas del archivo
    vni         := 1;
    vnNumLineas := 0;
    viNumReg    := 0;
    vsError     := null;
    vsLoad_stat := null;

   -- contador de commit
    vnBitacoraSeq := 0;

    vsPsuYr := pk_Util.f_ObtieneParam('PSUYR', 'PSU_YEAR');
 
    for cu_AnioProc  in  cuAnioProceso loop
        vsAnioActual   := cu_AnioProc.anio ;
        vsPerActual    := cu_AnioProc.presente ;
        vsPerPrevio    := cu_AnioProc.previo ;
        vdFecActual    := to_date( cu_AnioProc.fecha_act) ;
        vdFecPrev      := to_date(cu_AnioProc.fecha_ant);
    end loop;

    WHILE vni <= vnTamano LOOP

        vsLinea := pk_UtilCrgEnvArch.f_ExtraeLineaCLOB(vsArchivoCLOB, vni );

        -- verificamos que no se haya regresado null
        if length(vsLinea) > 0 then

           --Incremento mi contador de lineas
          -- vnNumLineas := vnNumLineas + 1;
           --Obtengo el tamaño de la linea
           vnTamLinea := LENGTH(vsLinea);
           --Incremento la posicion actual
           vni := vni + vnTamLinea;

           vsError     := null ;
           -- Campo en donde se dio el error.
           vsLoad_stat := null ;
         viNumReg := viNumReg + 1;
           
        --if  viNumReg >= 1186  then     --md-x 

           -----------***************obtiene datos **************----------
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 0, 1))),0) = 0) THEN
               vsTIdentificacion := NULL;
           ELSE
               vsTIdentificacion  :=  TRIM(SUBSTR(vsLinea, 0, 1));
           END IF;

           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 2, 9))),0) = 0) THEN
               vsNDocumento := NULL;
           ELSE
               vsNDocumento  :=   TRIM(SUBSTR(vsLinea, 2, 8))||'-'||TRIM(SUBSTR(vsLinea, 10, 1));
               vsRut := vsNDocumento;
           END IF;

           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 11, 4))),0) = 0) THEN
               vsAProceso := NULL;
           ELSE
               vsAProceso  :=  TRIM(SUBSTR(vsLinea, 11, 4));
           END IF;
           
           --md-04 start
           -- codigo carrera           
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 94, 5))),0) = 0) THEN
               vsCarrera := NULL;
           ELSE
               vsCarrera :=  TRIM(SUBSTR(vsLinea, 94, 5));
           END IF;
           
           -- local educacional 
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 115, 4))),0) = 0) THEN
               vsLocalE := NULL;
           ELSE
               vsLocalE  :=  TRIM(SUBSTR(vsLinea, 115, 4));
           END IF;
            
           -- unidad educacional 
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 119, 2))),0) = 0) THEN
               vsUnidadE := NULL;
           ELSE
               vsUnidadE  :=  TRIM(SUBSTR(vsLinea, 119, 2));
           END IF;           
           
           if (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 135, 4))),0) = 0) THEN
              vsAnio := null;
              vdAnioPrepa := null;  
           else
              vsAnio := TRIM(SUBSTR(vsLinea, 135, 4));
              vdAnioPrepa := to_date('01/01/' || vsAnio , 'dd/mm/yyyy'); 
           end if;
           -- md-04 end
           
           --26
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 139, 3))),0) = 0) THEN
               vsPromedioN := NULL;
           ELSE
               vsPromedioN  :=  TRIM(SUBSTR(vsLinea, 139, 3));
           END IF;
           --27
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 142, 3))),0) = 0) THEN
               vsPuntajeNEM := NULL;
           ELSE
               vsPuntajeNEM  :=  TRIM(SUBSTR(vsLinea, 142, 3));
           END IF;
           --28 vsPuntajeRAN
           --nuevo valor
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 145, 3))),0) = 0) THEN
               vsPuntajeRAN := NULL;
           ELSE
               vsPuntajeRAN  :=  TRIM(SUBSTR(vsLinea, 145, 3));
           END IF;
           --termina nuevo valor
           --29
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 148, 3))),0) = 0) THEN
               vsLenguajeC := NULL;
           ELSE
               vsLenguajeC  :=  TRIM(SUBSTR(vsLinea, 148, 3));
           END IF;
           --30
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 151, 3))),0) = 0) THEN
               vsMatematicas := NULL;
           ELSE
               vsMatematicas  :=  TRIM(SUBSTR(vsLinea, 151, 3));
           END IF;
           --31
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 154, 3))),0) = 0) THEN
               vsHistoria := NULL;
           ELSE
               vsHistoria  :=  TRIM(SUBSTR(vsLinea, 154, 3));
           END IF;
           --32
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 157, 3))),0) = 0) THEN
               vsCiencias := NULL;
           ELSE
               vsCiencias  :=  TRIM(SUBSTR(vsLinea, 157, 3));
           END IF;
           --33 (modulo ciencias)
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 160, 3))),0) = 0) THEN
               vsModulo := NULL;
           ELSE
               vsModulo  :=  TRIM(SUBSTR(vsLinea, 160, 3));
           END IF;
           -- 34
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 163, 4))),0) = 0) THEN
               vsPromMLM := NULL;
           ELSE
               vsPromMLM  :=  TRIM(SUBSTR(vsLinea, 163, 4));
           END IF;

           -- 40 -47
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 196, 174))),0) = 0) THEN
               vsDomicilio := NULL;
           ELSE
               vsDomicilio  :=  TRIM(SUBSTR(vsLinea, 196, 174));
           END IF;
           -- 40
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 196, 40))),0) = 0) THEN
               vsCalleD   := NULL;
           ELSE
               vsCalleD    :=  TRIM(SUBSTR(vsLinea, 196, 40));
           END IF;
           -- 41
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 236, 7))),0) = 0) THEN
               vsNumeroD   := NULL;
           ELSE
               vsNumeroD    :=  TRIM(SUBSTR(vsLinea, 236, 7));
           END IF;
           -- 42
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 243, 7))),0) = 0) THEN
               vsBockD   := NULL;
           ELSE
               vsBockD    :=  TRIM(SUBSTR(vsLinea, 243, 7));
           END IF;
           -- 43
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 250, 7))),0) = 0) THEN
               vsDeptoD   := NULL;
           ELSE
               vsDeptoD    :=  TRIM(SUBSTR(vsLinea, 250, 7));
           END IF;
           -- 44
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 257, 40))),0) = 0) THEN
               vsVillaD   := NULL;
           ELSE
               vsVillaD    :=  TRIM(SUBSTR(vsLinea, 257, 40));
           END IF;
           -- 45
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 297, 2))),0) = 0) THEN
               vsRegion   := NULL;
           ELSE
               vsRegion    :=  TRIM(SUBSTR(vsLinea, 297, 2));
           END IF;
           -- 46
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 299, 3))),0) = 0) THEN
               vsProvincia   := NULL;
           ELSE
               vsProvincia    :=  TRIM(SUBSTR(vsLinea, 299, 3));
           END IF;
           -- 47
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 302, 5))),0) = 0) THEN
               vsComuna   := NULL;
           ELSE
               vsComuna    :=  TRIM(SUBSTR(vsLinea, 302, 5));
           END IF;
           -- 51
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 352, 2))),0) = 0) THEN
               vsCodArea   := NULL;
           ELSE
               vsCodArea    :=  TRIM(SUBSTR(vsLinea, 352, 2));
           END IF;
           -- 52
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 354, 8))),0) = 0) THEN
               vsTelefono   := NULL;
           ELSE
               vsTelefono    :=  TRIM(SUBSTR(vsLinea, 354, 8));
           END IF;
           -- 53
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 362, 2))),0) = 0) THEN
               vsPCel   := NULL;
           ELSE
               vsPCel   :=  TRIM(SUBSTR(vsLinea, 362, 2));
           END IF;
           -- 54
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 364, 8))),0) = 0) THEN
               vsNCel   := NULL;
           ELSE
               vsNCel   :=  TRIM(SUBSTR(vsLinea, 364, 8));
           END IF;

           -- 55
           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 372, 60))),0) = 0) THEN
               vsEmail := NULL;
           ELSE
               vsEmail  :=  TRIM(SUBSTR(vsLinea, 372, 60));
           END IF;

           IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 446, 1))),0) = 0) THEN
               vsPondAA := NULL;
           ELSE
               vsPondAA  :=  TRIM(SUBSTR(vsLinea, 446, 1));
           END IF;

           -----------***************obtiene datos fin  **************----------

           if vsError = 'e' or vsError is null then

                  --saco del dv del rut.
                  vsDv := substr(vsRut, instr(vsRut,'-')+ 1 ,1);

                  vnNumLineas := vnNumLineas + 1;
                  --viNumReg := viNumReg + 1;
                  
                  -- carrera postulacion
                SELECT NVL(MAX(SOBCURR_PROGRAM),'N') into  vsProgramaN   
                FROM SOBCURR, SORCMJR
                WHERE SORCMJR_CURR_RULE = SOBCURR_CURR_RULE
                AND  SORCMJR_EDI_VALUE = vsCarrera;                
                
                --  cuantos pidm hay 
                   SELECT count(1) into vnPidmst
                   FROM SPBPERS
                   WHERE SPBPERS_NAME_SUFFIX = vsRut; 
                   
                   vnExiste := 0;
                   
                   if  vnPidmst <> 1 then   -- descartar que pidm es el correcto.
                      for cu_pdim in  cuPidm loop
                      
                           viPidm   := cu_pdim.pidm;
                           
                           --  si existe en saradap
                            select count(1) into vnPidmst
                            from sarappd , saradap
                            where SARAPPD_TERM_CODE_ENTRY like  vsPerActual
                            and sarappd_pidm = viPidm 
                            and sarappd_pidm = saradap_pidm
                            and SARAPPD_TERM_CODE_ENTRY = SARADAP_TERM_CODE_ENTRY
                            and  saradap_program_1 = vsProgramaN; 
                            
                            if vnPidmst >= 1 then
                               vnExiste := 1; 
                               exit; 
                            end if ;                       
                      
                      end loop;                       
                   else 
                   
                      SELECT SPBPERS_PIDM  into   viPidm
                      FROM SPBPERS
                      WHERE SPBPERS_NAME_SUFFIX = vsRut;
                      
                      vnExiste := 1; 
                   end if;                       
                       

                if vnExiste = 1 then 
                  ---- valido y actalizo tablas necesarias
                  --for cu_pdim in  cuPidm loop
                    --begin
                      vnExiste := 0;
                      --viPidm   := cu_pdim.pidm;
                      
                      --md-04 actualiza colegio unidad educacional                      
                      vsCodBanerCol := null;  
                      
                      for  cur_col in (SELECT STVSBGI_CODE  into vsCodBanerCol
                                            FROM STVSBGI
                                            WHERE STVSBGI_FICE = vsLocalE || vsUnidadE) loop
                                            
                           vsCodBanerCol :=     cur_col.STVSBGI_CODE;
                                
                      end loop;  
                      
                      if vsCodBanerCol is not null then
                         vdPrepa := null;                          
                         
                         if length(nvl(vsCodBanerCol,'0')) >= 2 then
                              
                             delete from  SORHSCH
                             where SORHSCH_pidm = viPidm;

                             insert into SORHSCH (SORHSCH_PIDM , SORHSCH_SBGI_CODE , SORHSCH_GRADUATION_DATE
                                                           , SORHSCH_ACTIVITY_DATE, SORHSCH_USER_ID , SORHSCH_DATA_ORIGIN ) 
                                            values
                                                         (  viPidm, vsCodBanerCol, vdAnioPrepa
                                                         ,  sysdate, 'DMRE', 'DMRE'); 

                         end if; 
                      end if;  
                      
                      --md-04 end.

                      -- verifica en sortest
                      -- PEM
                      vsPem := lpad(vsPromedioN,3,'0');
                      vsPem := substr(vsPem, 1,1) || ',' || substr(vsPem, 2);
                      P_ActualizaSortest(viPidm    , vsPondAA , 'PEM'   , vsPem  );

                      -- NEME
                      vsNeme := lpad(vsPuntajeNEM  ,3,'0');
                      P_ActualizaSortest(viPidm    , vsPondAA , 'NEME'  , vsNeme  );

                      -- PRAN Actual
                      vsPRAN_a := lpad(vsPuntajeRAN ,3,'0');
                      P_ActualizaSortest(viPidm    , vsPondAA , 'PRAN'  , vsPRAN_a );

                      -- PSLC Anterior
                      vsPSLC_a := lpad(vsLenguajeC  ,3,'0');
                      P_ActualizaSortest(viPidm    , vsPondAA , 'PSLC'  , vsPSLC_a  );

                      -- PSMA Anterior
                      vsPSMA_a := lpad(vsMatematicas ,3,'0');
                      P_ActualizaSortest(viPidm    , vsPondAA , 'PSMA'  , vsPSMA_a  );

                      -- PSHC Anterior
                      vsPSHC_a := lpad(vsHistoria  ,3,'0');
                      P_ActualizaSortest(viPidm    , vsPondAA , 'PSHC'  , vsPSHC_a );

                      -- PSCI Anterior
                       vsPSCI_a := lpad(vsCiencias ,3,'0');
                      P_ActualizaSortest(viPidm    , vsPondAA , 'PSCI'  , vsPSCI_a );

                       -- PPSU PROM_LM (PROMEDIO LENGUAJE + MATEMÁTICA)
                        vsPem := lpad(vsPromMLM , 4,'0');
                        vsPem := substr(vsPem, 1,3) || ',' || substr(vsPem, 4);
                        P_ActualizaSortest(viPidm    , vsPondAA , 'PPSU'   , vsPem   );

                      -- telefono pr
                      vs_TelOK := 0;
                      if to_number(vsTelefono) > 0 then

                         vs_TelOK := 1;

                         select count(1) into viSequencia
                         from SPRTELE
                         where SPRTELE_pidm = viPidm
                         and SPRTELE_PHONE_AREA = vsCodArea
                         and SPRTELE_PHONE_NUMBER = vsTelefono
                         and SPRTELE_TELE_CODE =  'TFPA';      

                         if viSequencia = 0 then 

                            -- select max(SPRTELE_SEQNO) + 1 into viSequencia    --md-02                             
                            select nvl(max(SPRTELE_SEQNO),0) + 1 into viSequencia      --md-02
                            from SPRTELE
                            where SPRTELE_pidm = viPidm;

                            update SPRTELE set SPRTELE_ATYP_CODE = null
                                               ,SPRTELE_ADDR_SEQNO = null
                                               ,SPRTELE_PRIMARY_IND = null
                            where SPRTELE_pidm = viPidm;                 

                            insert into SPRTELE
                                 ( SPRTELE_PIDM             , SPRTELE_SEQNO       , SPRTELE_TELE_CODE
                                 , SPRTELE_ACTIVITY_DATE    , SPRTELE_PHONE_AREA  , SPRTELE_PHONE_NUMBER
                                 , SPRTELE_ATYP_CODE        , SPRTELE_ADDR_SEQNO  , SPRTELE_PRIMARY_IND
                                 , SPRTELE_USER_ID)
                            values
                                 (viPidm                    ,viSequencia          ,  'TFPA'
                                 --,vdFecActual               ,vsCodArea            ,vsTelefono
                                 , sysdate                ,vsCodArea            ,vsTelefono
                                 , 'PA'                     , 1                   , 'Y'
                                 , 'DMRE' );
                                 
                         else 
                         
                             update SPRTELE set SPRTELE_ATYP_CODE = null
                                                       ,SPRTELE_ADDR_SEQNO = null
                                                      ,SPRTELE_PRIMARY_IND = null
                            where SPRTELE_pidm = viPidm
                            and SPRTELE_TELE_CODE = 'TFPA';
                            
                            update SPRTELE set SPRTELE_ATYP_CODE = 'PA'
                                                       ,SPRTELE_ADDR_SEQNO = null
                                                      ,SPRTELE_PRIMARY_IND = 'Y'
                                                      , SPRTELE_TELE_CODE = 'TFPA'
                            where SPRTELE_pidm = viPidm
                            --and SPRTELE_TELE_CODE = 'TFPA'
                            and SPRTELE_PHONE_AREA = vsCodArea
                           and SPRTELE_PHONE_NUMBER = vsTelefono;

                         end if;

                      end if;

                      --? existencia de direccion

                      vsStreet := substr(trim(vsCalleD) || ' ' || trim(vsNumeroD) || ' ' || trim(vsBockD), 1,75);

                      vs_ComunaBan := null;
                      select STVCNTY_CODE into vs_ComunaBan
                      from stvcnty
                      where substr(stvcnty_desc, 1,5) = vsComuna
                      and rownum = 1;

                      vs_RegionBan := null;
                      select STVSTAT_CODE into vs_RegionBan
                      from stvstat
                      where substr(STVSTAT_DESC, 1,2) = vsRegion
                      and rownum = 1;

                      select count(1) into vnExiste
                      from spraddr
                      where SPRADDR_PIDM  = viPidm
                      and SPRADDR_ATYP_CODE = 'PR' ;      --md-04
                      
                      --AND SPRADDR_STREET_LINE1 = vsStreet;  --md-04

                      if vnExiste = 0 then
                         --alta
                         --SELECT nvl(max(SPRADDR_SEQNO),0) + 1 into viSequencia
                         --FROM  SPRADDR
                         --WHERE SPRADDR_PIDM =  viPidm ;
                         viSequencia := 1; 

                          if vs_TelOK = 0 then
                             insert into SPRADDR (SPRADDR_PIDM          ,SPRADDR_ATYP_CODE       ,SPRADDR_SEQNO
                                                ,SPRADDR_FROM_DATE      ,SPRADDR_STREET_LINE1    ,SPRADDR_STREET_LINE2
                                                ,SPRADDR_STREET_LINE3   ,SPRADDR_STAT_CODE       ,SPRADDR_ZIP
                                                ,SPRADDR_CNTY_CODE      ,SPRADDR_NATN_CODE       ,SPRADDR_ACTIVITY_DATE
                                                ,SPRADDR_USER           ,SPRADDR_ASRC_CODE       , SPRADDR_CITY )
                                          values
                                                (viPidm                 , 'PR'                   ,viSequencia
                                               , vdFecActual            , vsStreet               , substr(vsDeptoD,1,75)
                                               , substr(vsVillaD,1,75)  , vs_RegionBan           , vsProvincia
                                               , vs_ComunaBan           , '39'                   , sysdate
                                               ,'DMRE'                 ,'WEB'                   , 0 );
                          else
                            insert into SPRADDR (SPRADDR_PIDM          ,SPRADDR_ATYP_CODE       ,SPRADDR_SEQNO
                                                ,SPRADDR_FROM_DATE      ,SPRADDR_STREET_LINE1    ,SPRADDR_STREET_LINE2
                                                ,SPRADDR_STREET_LINE3   ,SPRADDR_STAT_CODE       ,SPRADDR_ZIP
                                                ,SPRADDR_CNTY_CODE      ,SPRADDR_NATN_CODE       ,SPRADDR_ACTIVITY_DATE
                                                ,SPRADDR_USER           ,SPRADDR_ASRC_CODE       , SPRADDR_CITY
                                                ,SPRADDR_PHONE_AREA     , SPRADDR_PHONE_NUMBER)
                                          values
                                                (viPidm                 , 'PR'                   ,viSequencia
                                               , vdFecActual            , vsStreet               ,  substr(vsDeptoD,1,75)
                                               , substr(vsVillaD,1,75)  , vs_RegionBan           , vsProvincia
                                               , vs_ComunaBan           , '39'                   , sysdate
                                               ,'DMRE'                 ,'WEB'                   , 0
                                               , vsCodArea              , vsTelefono );
                          end if;

                      else
                         -- solo me quedo con solo la dirreccion 1    --md-04 start
                         delete from spraddr
                         where SPRADDR_PIDM = viPidm
                         and SPRADDR_ATYP_CODE = 'PR'
                         and SPRADDR_SEQNO > 1; 
                         
                        --update
                         update spraddr set SPRADDR_STREET_LINE1 = vsStreet  , SPRADDR_STREET_LINE2 =  substr(vsDeptoD,1,75)
                                                  , SPRADDR_ZIP = vsProvincia
                                                  , SPRADDR_CNTY_CODE = vs_ComunaBan , SPRADDR_STAT_CODE = vs_RegionBan       --md-04 end
                                                  , SPRADDR_ACTIVITY_DATE = SYSDATE    , SPRADDR_USER = 'DMRE'
                         where SPRADDR_PIDM = viPidm
                         and SPRADDR_ATYP_CODE = 'PR' ; 

                      end if;

                       -- telefono tmpa
                       select count(1) into viSequencia
                       from SPRTELE
                       where SPRTELE_pidm = viPidm
                       and SPRTELE_PHONE_AREA = vsPCel
                       and SPRTELE_PHONE_NUMBER = vsNCel
                       and SPRTELE_TELE_CODE = 'TMPA';

                       if viSequencia = 0 then

                          select nvl(max(SPRTELE_SEQNO),0) + 1 into viSequencia
                          from SPRTELE
                          where SPRTELE_pidm = viPidm;

                           insert into SPRTELE
                               ( SPRTELE_PIDM                , SPRTELE_SEQNO      , SPRTELE_TELE_CODE
                               , SPRTELE_ACTIVITY_DATE       , SPRTELE_PHONE_AREA , SPRTELE_PHONE_NUMBER
                               , SPRTELE_USER_ID)
                          values
                               ( viPidm                      , viSequencia        , 'TMPA'
                               , SYSDATE                 , vsPCel             , vsNCel
                               , 'DMRE');

                       end if;

                      -- CORREO
                       select count(1) into viSequencia
                       from GOREMAL
                       where GOREMAL_PIDM = viPidm
                       and  GOREMAL_EMAIL_ADDRESS = vsEmail;

                       if viSequencia = 0 then

                             --                          update GOREMAL set GOREMAL_PREFERRED_IND = 'N'
                             --                          where GOREMAL_PIDM = vsPIDM;

                          insert into GOREMAL
                               ( GOREMAL_PIDM           , GOREMAL_EMAL_CODE      , GOREMAL_EMAIL_ADDRESS
                               , GOREMAL_STATUS_IND     ,GOREMAL_PREFERRED_IND   , GOREMAL_ACTIVITY_DATE
                               , GOREMAL_USER_ID        , GOREMAL_DISP_WEB_IND)
                          values
                               ( viPidm                 , 'PERS'                 , vsEmail
                               , 'A'                    , 'Y'                    , vdFecActual
                               , 'DMRE'                 ,  'Y');
                       
                       else
                          
                             update GOREMAL set GOREMAL_PREFERRED_IND = 'Y' 
                                                        , GOREMAL_EMAL_CODE = 'PERS'  
                             where GOREMAL_PIDM = viPidm
                             and GOREMAL_EMAIL_ADDRESS = vsEmail;                        

                       end if;

                                --                     EXCEPTION
                                --                      WHEN OTHERS THEN
                                --                          ROLLBACK; --ROLLBACK!!
                                --                    end;
                      
                    --    exit;  -- me aseguro que solo acualizo el primero.

                    --end loop;
                end if; 
                  
                  commit;

                  vnBitacoraSeq := vnBitacoraSeq + 1;

                  insert into twraacp values ( cgsCodApp, vnNumProcCarga, vnNumLineas, viPidm , 'A' , null, sysdate, vgsUSR);  --md-01

           else

                vsLoad_stat := 'faltan campos ' || vsLoad_stat;

                  insert into twraacp values ( cgsCodApp, vnNumProcCarga, vnNumLineas, vsRut || '-' || vsDv , 'E' , null, sysdate, vgsUSR);  --md-01


           END IF;
               
        End If;
      -- else         --md-x
       --   viNumReg := viNumReg;  --md-x  
      --end if ;    --md-x

        vni := vni + 2;
        -- lo puse afuera para evitar ciclos infinitos, pero podría tener  efectos secundarios
    END LOOP;

    commit;

     --  inserto bitacora del archivo..
     INSERT INTO GWBAACR (  GWBAACR_NOMBRE_ARCHIVO
                           ,GWBAACR_TIPO
                           ,GWBAACR_NUM_REGISTROS
                           ,GWBAACR_TAMANO
                           ,GWBAACR_HASH_SHA1
                           ,GWBAACR_NUM_PROCESO
                           ,GWBAACR_ACTIVITY_DATE
                           ,GWBAACR_USER
                    )VALUES(
                           psArchivo
                           ,cgsCodApp
                           ,viNumReg
                           ,vnTamano
                           ,vrDigestionSHA1
                           ,vnNumProcCarga
                           ,SYSDATE
                           ,vgsUSR  );

      commit;
  --  vgsUsr := NVL(vgsUSR,USER);
    --Indico al usuario que ya termine
   -- p_ImprimeLineaResultado('Proceso del Actualización Datos DEMRE Finalizado.');

END p_Carga;


/******************************************************************************
PROCEDIMIENTO:      p_ImprimeLineaResultado
OBJETIVO:           Genera una linea con el mensaje y/o HTML indicado en la
                    pagina de resultados
PARAMETROS:
psLinea             Mensaje y/o HTML a mostrar
******************************************************************************/
PROCEDURE p_ImprimeLineaResultado(   psLinea    VARCHAR2   ) IS
BEGIN

    DBMS_OUTPUT.PUT_LINE(psLinea);

END p_ImprimeLineaResultado;


PROCEDURE P_ActualizaSortest(piPidm      number
                            ,psAcad      varchar2
                            ,psTipo      varchar2
                            ,psValor     varchar2 ) is

pnExite number(10);
psTerm varchar2(10);
pdFecha  date;

myRowId   rowid;    --md-04

begin

     -- periodo actual
     psTerm  := vsPerActual;
     pdFecha := vdFecActual;

     if psAcad = 2 then
     -- periodo anterior
        psTerm := vsPerPrevio ;
        pdFecha := vdFecPrev;
     end if;

     select count(1) into pnExite
     from sortest
     where SORTEST_PIDM = piPidm
     and SORTEST_TESC_CODE = psTipo
     and SORTEST_TERM_CODE_ENTRY = psTerm; 
     
    -- and SORTEST_TEST_DATE  = pdFecha ;                         --md-02   --md-04

     if pnExite = 0 then

     -- alta el registro en sortet
        insert into sortest  (SORTEST_PIDM          ,SORTEST_TESC_CODE        ,SORTEST_TEST_DATE ,SORTEST_TEST_SCORE
                             ,SORTEST_ACTIVITY_DATE ,SORTEST_TERM_CODE_ENTRY  ,SORTEST_APPL_NO
                             ,SORTEST_RELEASE_IND  ,SORTEST_EQUIV_IND        , SORTEST_USER_ID  ,SORTEST_DATA_ORIGIN )
                             values
                             (piPidm                , psTipo                   , pdFecha          ,psValor
                             ,sysdate               , psTerm                  , 0
                             , 'N'                  , 'N'                     , vgsUsr         ,'DMRE');
     else
       --actualizo registro existente. 
       
        --md-04 start
        delete 
        from sortest a
        where a.sortest_pidm = piPidm
        and a.sortest_tesc_code = psTipo
        and a.sortest_term_code_entry =psTerm;
         
        /*and a.SORTEST_TEST_DATE <> (  select max( SORTEST_TEST_DATE ) 
                                                            from sortest 
                                                            where sortest_pidm = a.sortest_pidm 
                                                            and sortest_tesc_code = a.sortest_tesc_code
                                                            AND sortest_term_code_entry = a.sortest_term_code_entry); */   
                                                            
                                                            --md-04 end
                                                            
        insert into sortest  (SORTEST_PIDM          ,SORTEST_TESC_CODE        ,SORTEST_TEST_DATE ,SORTEST_TEST_SCORE
                             ,SORTEST_ACTIVITY_DATE ,SORTEST_TERM_CODE_ENTRY  ,SORTEST_APPL_NO
                             ,SORTEST_RELEASE_IND  ,SORTEST_EQUIV_IND        , SORTEST_USER_ID  ,SORTEST_DATA_ORIGIN )
                     values
                             (piPidm                , psTipo                   , pdFecha          ,psValor
                             ,sysdate               , psTerm                  , 0
                             , 'N'                  , 'N'                     , vgsUsr         ,'DMRE');                                                              

        /*
        update sortest set SORTEST_TEST_DATE = pdFecha , SORTEST_TEST_SCORE = psValor  ,SORTEST_ACTIVITY_DATE = sysdate
                          ,SORTEST_APPL_NO = 0         , SORTEST_RELEASE_IND = 'N'   ,SORTEST_EQUIV_IND = 'N'
                          ,SORTEST_USER_ID = vgsUsr    ,SORTEST_DATA_ORIGIN = 'DMRE'
        where SORTEST_PIDM = piPidm
        and SORTEST_TESC_CODE = psTipo
        and SORTEST_TERM_CODE_ENTRY = psTerm;     --md-04 start  */
        
        /* and SORTEST_TEST_DATE  = pdFecha        
        and SORTEST_ACTIVITY_DATE = ( select max(SORTEST_ACTIVITY_DATE)        --md-02  start
                                                              from  sortest  
                                                              where SORTEST_PIDM = piPidm
                                                              and SORTEST_TESC_CODE = psTipo
                                                              and SORTEST_TERM_CODE_ENTRY = psTerm);      --md-02 end
          md-04 end */                                                                          

     end if;

end P_ActualizaSortest;


END pk_CargaAdicionalDemre_NV ;
/


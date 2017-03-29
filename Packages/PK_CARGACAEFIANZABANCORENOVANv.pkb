CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaCaeFianzaBancoRenovaNv IS

/******************************************************************************
PAQUETE:            BANINST1.pk_CargaCaeFianzaBancoRenovaNv
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos de fianzas del sistema Ingresa
AUTOR:              Roman Ruiz
FECHA:              22 oct 2014
--------------------------------------
modificacion        md-01
objetivo            adecuar al nuevo tipo de carga kwaproceso
elaboro             Roman Ruiz
fecha               3-mar-2014
--------------------------------------
modificacion        md-02
objetivo            agrevar validacion para obtener pidm de acuerdo a sgbstdn
elaboro             Roman Ruiz
fecha               8-jul-2015
--------------------------------------
modificacion        md-03
objetivo             nuevo metodo de carga. (unificacion )
elaboro             Roman Ruiz
fecha               27-ene-2016
******************************************************************************/

    --variable para seguridad GWAMNUR
    vgsUSR              VARCHAR2(500);
    cgsCodApp           CONSTANT VARCHAR2(4) := 'CFBR';   -- codigo aplicacion
    csFBR               constant varchar2(4) := 'FBR';    -- fianza bancos renovante
    csFBRZ              constant varchar2(4) := 'FBRZ';   -- fianza bancos renovante rezagado
    vsNomSeq            VARCHAR2(50);
    csTipoC             CONSTANT char(1) := 'C';
    cgsErr20408         CONSTANT VARCHAR2(200) := 'No esta configurado el Año para proceso CAE';
    cnRoundNum          constant number(1) := 4;     -- decimales a redondear
    csSepara            constant varchar2(1) := ',';  --chr(9);  -- tabulador
    csRen               constant char(1) := 'R' ;   -- tipo renovane
    csLis               constant char(1) := 'L' ;   -- tipo Licitado

----prototipos de Funciones y procedimientos privados

PROCEDURE p_ImprimeLineaResultado(psLinea        VARCHAR2);
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
    vnExiste   NUMBER:= 0;
    vnSEQ      VARCHAR2(6);
    vsCODE     VARCHAR2(6);
    vsRegularE VARCHAR2(10) := '^(*[0-9])';

    vsCampo    VARCHAR2(200);
    vnCantidad  number(12,4) := 0;
    viNumReg    number;

    vsYEAR                TWRCFBK.TWRCFBK_YEAR%TYPE;
    vsFileSeq             TWRCFBK.TWRCFBK_FILE_SEQ%TYPE;
    vsSeqNum              TWRCFBK.TWRCFBK_SEQ_NUM%TYPE;
    vsRut                 TWRCFBK.TWRCFBK_RUT%TYPE;
    vsDv                  TWRCFBK.TWRCFBK_DV%TYPE;
    vsAnoLiciatacion      TWRCFBK.TWRCFBK_ANO_LICITACION%TYPE;
    vnMontoFianza         TWRCFBK.TWRCFBK_MONTO_FIANZA%TYPE;
    vnMontoSeguro         TWRCFBK.TWRCFBK_MONTO_SEGURO%TYPE;
    vsRutBanco            TWRCFBK.TWRCFBK_RUT_BANCO%TYPE;
    vsDvBanco             TWRCFBK.TWRCFBK_DV_BANCO%TYPE;
    vsNombreBanco         TWRCFBK.TWRCFBK_NOMBRE_BANCO%TYPE;

    vsError         char(1);
    vsLoad_stat     varchar2(100);
    viExisteBanner  number(5);
    viResagado      number(3);
    vsStatRes       varchar2(4);
    viPidm          number(10);
    viSeqNum        number(4);
    vsRutGral       varchar2(15);
   -- vsNameArchivo   varchar2(300);    --md-01
    
    vsalida             VARCHAR2(3000);      --md-03  start
    vsNameArchivo       varchar2(300);   
    vsArchExitente     varchar2(300);    
     vsArchExSize       number(10):= 0;
     vrArchivoExBlob   BLOB;
     viArchVivo           number(4) := 0;    --md-03  end         

    cursor cur_resagado is
           select case
                      when  TWBCCAE_LIMIT_DATE < sysdate then 1
                      when  TWBCCAE_LIMIT_DATE > sysdate then 0
                  end  limite
           from TWBCCAE
           where TWBCCAE_YEAR = vsYEAR
           and TWBCCAE_PCAE_CODE = cgsCodApp;

    cursor cur_Pidm is
           SELECT  sgbstdn_pidm
                  ,SGBSTDN_TERM_CODE_EFF
                  ,sgbstdn_activity_date
           FROM   sgbstdn
                 ,spbpers
           WHERE  spbpers_name_suffix = vsRut || '-' || vsDv
           AND    sgbstdn_pidm = spbpers_pidm
           and  SGBSTDN_LEVL_CODE in ('LI','LC')                 --md-02
           and SGBSTDN_MAJR_CODE_1 <> 'EDME'                     --md-02
           ORDER BY SGBSTDN_TERM_CODE_EFF desc, sgbstdn_activity_date ;

     --md-03 start     
     cursor ArchExistente   is 
                  SELECT   NAME  ,    DOC_SIZE    , BLOB_CONTENT
                  -- from SWBFOTO   --md-x
                  from   GWBDOCS
                  WHERE NAME like  vsNameArchivo
                  order by LAST_UPDATED desc;
     
     --md-03 end              

BEGIN

-- IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;
-- nota esta página por sus características, no es del tipo de separación PL de codigo HTML
   --md-01 start
   
   --md-03 start
   --  año general del proceso cae
    vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');
    
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

      -- existe archivo , se marca en bitacora de error y se para el proceso.      
      if viArchVivo > 0 then
   
          INSERT INTO GWRERRO VALUES (cgsCodApp, psArchivo  ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);
          
           insert into twraacp values ( cgsCodApp, vnNumProcCarga, 1, 'Arch Repetido ' || psArchivo , 'X' ,  'Archivo_Repetido' , sysdate, vgsUSR); 
           
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
         RETURN;                       
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

--    --obtengo los datos del archivo
--    Select  DOC_SIZE, BLOB_CONTENT  INTO  vnTamano,  vrArchivoBLOB
--    FROM   GWBDOCS
--    WHERE  NAME like  vsNameArchivo;

     for cur_doc in (SELECT DOC_SIZE ,BLOB_CONTENT
                            FROM GWBDOCS
                            WHERE NAME like  vsNameArchivo
                            order by last_updated desc ) loop

        vnTamano      := cur_doc.DOC_SIZE;
        vrArchivoBLOB := cur_doc.BLOB_CONTENT;
        exit;

     end loop;

    --calculo la firma SHA1 del archivo
    vrDigestionSHA1 := DBMS_CRYPTO.HASH(vrArchivoBLOB,DBMS_CRYPTO.HASH_SH1);

    /*  --md-01 start
    --Muestro los datos del archivo
    p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
    p_ImprimeLineaResultado ('Tamaño de archivo: ' || vnTamano);
    p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);
    md-01 end
    */

    --  verificar que no se haya subido previamente este archivo
--    vsExiste := 'N';
--    FOR curExiste in (SELECT GWBAACR_USER  ,GWBAACR_ACTIVITY_DATE
--                      FROM GWBAACR
--                      WHERE GWBAACR_TAMANO = vnTamano
--                      AND GWBAACR_HASH_SHA1 = vrDigestionSHA1) loop
--       vsUserAnt := curExiste.GWBAACR_USER;
--       vdFechaAnt := curExiste.GWBAACR_ACTIVITY_DATE;
--       vsExiste := 'Y';
--    end loop;

    --Si existe, indico que no se puede volver a subir este mismo archivo
--    IF vsExiste = 'Y' THEN
--        -- Eliminar el archivo recien subido
--        DELETE GWBDOCS
--        WHERE  NAME = psArchivo;
--
--        -- md-01 start
--        INSERT INTO GWRERRO VALUES (cgsCodApp, psArchivo ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);
--        COMMIT;
--
--        /* --Informo al usuario.
--        p_ImprimeLineaResultado ( 'Este archivo ya se había subido anteriormente.');
--        p_ImprimeLineaResultado (  'Usuario: '||vsUserAnt||'. Fecha y Hora: ' ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.'  );
--        p_ImprimeLineaResultado ('No se procesara .');    */
--        RETURN;
--
--    END IF;

--    vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');
--    --Obtengo Numero de secuencia de archivo
--    vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);
--    vgsUsr := NVL(vgsUSR,USER);

    --Imprimo el numero de proceso
    -- p_ImprimeLineaResultado ('Número de proceso: ' || vnNumProcCarga);  --md-01
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

    -- calulando valor de rezagado
    viResagado := 0;
    for curRes in cur_resagado loop
        viResagado := curRes.limite;
    end loop;
    if viResagado = 0 then
      -- carga normal
      vsStatRes := csFBR;
    else
      -- carga resagada
      vsStatRes :=  csFBRZ;
    end if;
    viExisteBanner := 0;

    WHILE vni <= vnTamano LOOP

        vsLinea := pk_UtilCrgEnvArch.f_ExtraeLineaCLOB(vsArchivoCLOB, vni );

        -- verificamos que no se haya regresado null
        if length(vsLinea) > 0 then

           --Incremento mi contador de lineas
           vnNumLineas := vnNumLineas + 1;
           --Obtengo el tamaño de la linea
           vnTamLinea := LENGTH(vsLinea);

           --Incremento la posicion actual
           vni := vni + vnTamLinea;

           if  vnNumLineas > 1 then  --esto  a que la linea 1 trea los encabezados.
               -- Variabla para determinar Errores   E = (sin rut no continua)  e = solo falta de dato
               vsError     := null ;
               -- Campo en donde se dio el error.
               vsLoad_stat := null ;

            --    campos solicitados
            --   RUT,DV,Monto Fianza,Monto Seguro, Banco, Anio Proceso

           -- TWRCFBK_RUT  -- campo1 - vsRut
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,1,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                   vsCampo := NULL;
                   vsError := 'E';
                   vsLoad_stat := '1';
               ELSE
                   vsCampo :=  TRIM(vsCampo);
               END IF;
               vsRut := vsCampo;

           -- TWRCFBK_DV -- campo2 - vsDv
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,2,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                    vsCampo := NULL;
                     if vsError is null then
                        vsError := 'E';
                     end if ;
                     vsLoad_stat := vsLoad_stat || ' 2';
               ELSE
                    vsCampo :=  TRIM(vsCampo);
               END IF;
               vsDv := vsCampo;

           -- TWRCFBK_MONTO_FIANZA -- campo3 - vnMontoFianza
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,3,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                    vsCampo := 0;
                     if vsError is null then
                        vsError := 'E';
                     end if ;
                     vsLoad_stat := vsLoad_stat || ' 3';
               ELSE
                    vsCampo :=  TRIM(vsCampo);
               END IF;
               --md-01 start
               vsCampo := replace( replace( vsCampo, '"'),',','.');
               vsCampo := substr(  vsCampo , 1 , instr(vsCampo,'.') + cnRoundNum);
               vnCantidad := round(to_number(vsCampo , '99999999.9999'),cnRoundNum);
               vnMontoFianza := vnCantidad;
               --md-01 end

           -- TWRCFBK_MONTO_SEGURO -- campo4 - vnMontoSeguro
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,4,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                    vsCampo := 0;
                     if vsError is null then
                        vsError := 'e';
                     end if ;
                     vsLoad_stat := vsLoad_stat || ' 4';
               ELSE
                    vsCampo :=  TRIM(vsCampo);
               END IF;
               -- md-01 start
               vsCampo := replace( replace( vsCampo, '"'),',','.');
               vsCampo := substr(  vsCampo , 1 , instr(vsCampo,'.') + cnRoundNum);
               vnCantidad := round(to_number(vsCampo , '99999999.9999'),cnRoundNum);
               vnMontoSeguro := vnCantidad;
               --md-01 end

           -- TWRCFBK_NOMBRE_BANCO -- campo5 - vsNombreBanco
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,5,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                    vsCampo := NULL;
                     if vsError is null then
                        vsError := 'e';
                     end if ;
                     vsLoad_stat := vsLoad_stat || ' 5';
               ELSE
                    vsCampo :=  TRIM(vsCampo);
               END IF;
               vsNombreBanco := vsCampo;

           -- calcular rut-dv del banco en base al nombre
               select nvl(TWVBANK_RUT_BANCO, '')  into vsRutGral
               from TWVBANK
               where TWVBANK_DESC = trim(vsNombreBanco);

               vsRutBanco := '';
               vsDvBanco  := '';
               if length(vsRutGral) > 2 then
                  if instr(vsRutGral ,'-') > 1 then
                     vsRutBanco := substr( vsRutGral, 1,  instr(vsRutGral ,'-')-1) ;
                     vsDvBanco  := substr( vsRutGral, instr( vsRutGral ,'-') +1 ) ;
                  end if;
               end if;

           -- TWRCFBK_ANO_LICITACION  -- campo6 - vsAnoLiciatacion
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,6,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                   vsCampo := NULL;
                   if vsError is null then
                      vsError := 'e';
                   end if ;
                   vsLoad_stat := vsLoad_stat || ' 6';
               ELSE
                   vsCampo :=  TRIM(vsCampo);
               END IF;
               vsAnoLiciatacion := vsCampo;

               -- linea de descripcion de Error
               if vsError is not null then
                     vsLoad_stat := 'faltan campos ' || vsLoad_stat;
               end if;

               -- BEGIN
               if vsError = 'e' or vsError is null then

                  viNumReg := viNumReg + 1;

                  -- verificar su exsitencia el rut  en twrcarh e incrementar secuencial en 1
                  select count(1) + 1 into vnNumLineas
                  from   TWRCFBK
                  where  TWRCFBK_YEAR = vsYEAR
                  and    TWRCFBK_RUT  = vsRut;

                  -- inserta archivo Fianza Bancos
                   INSERT INTO TWRCFBK (
                                        TWRCFBK_FILE_SEQ       ,
                                        TWRCFBK_SEQ_NUM        ,
                                        TWRCFBK_YEAR           ,
                                        TWRCFBK_RUT            ,
                                        TWRCFBK_DV             ,
                                        TWRCFBK_ANO_LICITACION ,
                                        TWRCFBK_MONTO_FIANZA   ,
                                        TWRCFBK_MONTO_SEGURO   ,
                                        TWRCFBK_RUT_BANCO      ,
                                        TWRCFBK_DV_BANCO       ,
                                        TWRCFBK_NOMBRE_BANCO   ,
                                        TWRCFBK_STATUS_CODE    ,
                                        TWRCFBK_TIPO_CAE       ,
                                        TWRCFBK_LOAD_ERROR     ,
                                        TWRCFBK_PROCESS_ERROR  ,
                                        TWRCFBK_USER           ,
                                        TWRCFBK_ACTIVITY_DATE   )
                               VALUES (
                                        vnNumProcCarga,
                                        vnNumLineas,  --CONCECUTIVO  EN LA TABLA PARA EL RUT
                                        vsYEAR,
                                        vsRut,
                                        vsDv,
                                        vsAnoLiciatacion,
                                        vnMontoFianza,
                                        vnMontoSeguro,
                                        vsRutBanco,
                                        vsDvBanco,
                                        vsNombreBanco,
                                        vsStatRes ,     --csStatusCAE,
                                        csRen,          -- renovante
                                        vsLoad_stat,
                                        null,           -- error de proceso
                                        vgsUsr ,
                                        SYSDATE );

                  viPidm := 0;
                  for cuPidm in cur_Pidm loop
                     viPidm := cuPidm.sgbstdn_pidm;
                     exit;
                  end loop;

                  if viPidm > 0 then -- es alumno uft

                     viExisteBanner :=   viExisteBanner + 1;
                     viSeqNum := 0;

                     -- sig entrada en twrcaes
                     select Nvl( max(TWRCAES_SEQ_NUM), 0) + 1  into viSeqNum
                     from twrcaes
                     where TWRCAES_RUT = vsRut
                     and TWRCAES_YEAR = vsYEAR;

                      -- inserta n tabla de seguimiento de Status
                      insert into TWRCAES
                               (  TWRCAES_RUT            ,
                                  TWRCAES_RUT_DV         ,
                                  TWRCAES_SEQ_NUM        ,
                                  TWRCAES_STATUS_CODE    ,
                                  TWRCAES_PIDM           ,
                                  TWRCAES_FILE_SEQ       ,
                                  TWRCAES_TYPE           ,
                                  TWRCAES_LOAD_STAT      ,
                                  TWRCAES_LOAD_ERROR     ,
                                  TWRCAES_PROCESS_ERROR  ,
                                  TWRCAES_REG_ERROR      ,
                                  TWRCAES_YEAR           ,
                                  TWRCAES_USER           ,
                                  TWRCAES_ACTIVITY_DATE  ,
                                  TWRCAES_STATUS_UNI )
                        values ( vsRut
                               ,vsDv
                               ,viSeqNum             -- consecutivo conforme mov del rut
                               ,vsStatRes            -- csStatusCAE
                               ,viPidm
                               ,vnNumProcCarga       --vnNumProcCarga -- numero de arch carga
                               ,csTipoC              -- C de carga
                               , NULL
                               , 'Carga Fianza Banco' -- vsError        -- null si no tiene error
                               , NULL
                               , 'Carga Fianza Banco ' || vsNombreBanco || ' en Carga '  || vnNumProcCarga   -- errores en la carga de arch
                               ,vsAnoLiciatacion
                               ,vgsUsr
                               ,sysdate
                               ,csFBR);

                     insert into twraacp values ( cgsCodApp, vnNumProcCarga, viNumReg, vsRut || vsDv , 'A' , null, sysdate, vgsUsr);  --md-01

                  end if;

                  if vnBitacoraSeq >= 50 then
                     vnBitacoraSeq := 0;
                     COMMIT;
                  end if;

                  vnBitacoraSeq := vnBitacoraSeq + 1;

               END IF;

           End If;

        end if;
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

    /*  md-01 start
    --Indico al usuario que ya termine
    p_ImprimeLineaResultado('Registros cargados ' || viNumReg );
    p_ImprimeLineaResultado('Alumnos UFT : ' || viExisteBanner );
    p_ImprimeLineaResultado('Procesamiento del archivo CAE Fianza Bancos terminado.');
    md-01 end */

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

END pk_CargaCaeFianzaBancoRenovaNv;
/


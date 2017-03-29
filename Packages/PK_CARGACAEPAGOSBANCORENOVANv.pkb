CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaCaePagosBancoRenovaNv IS
--pk_CargaCaePagosBancoRenova

/******************************************************************************
PAQUETE:            BANINST1.pk_CargaCaePagosBancoRenova
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos de Pagos Banco
AUTOR:              Roman Ruiz
FECHA:              22 oct 2014
--------------------------------
cambio              md-01
objetivo            adecuar el proceso al nuevo tipo de carga  kwaproceso
autor               roman ruiz
fecha               09-mar-2015
--------------------------------
cambio              md-02
objetivo            se adiciona campo de saldo seguro en twrcaba para
                    poder llevar su saldo
autor               roman ruiz
fecha               05-jun-2015
--------------------------------
cambio              md-03
objetivo            cambio de año a año licitacion
autor               roman ruiz
fecha               18-jun-2015
--------------------------------
cambio              md-04
objetivo            se adiciona columna de tipo de beneficio c = cae m = minieduc
                    y si ha sido contabilizado  = 0
autor               roman ruiz
fecha               24-jun-2015
--------------------------------------
modificacion        md-05
objetivo            agregar validacion para obtener pidm de acuerdo a sgbstdn
elaboro             Roman Ruiz
fecha               8-jul-2015
--------------------------------------
modificacion        md-06
objetivo            cambio de metodo de carga archivo (unificar)
elaboro             Roman Ruiz
fecha               27-ene-2016

******************************************************************************/

    --variable para seguridad GWAMNUR
    vgsUSR              VARCHAR2(500);
    global_aidm       SABNSTU.SABNSTU_AIDM%TYPE;
    global_id           SABNSTU.SABNSTU_ID%TYPE;
    cgsCodApp        CONSTANT VARCHAR2(4) := 'CPBR';   -- codigo aplicacion
    csPBR               constant varchar2(4) := 'PBR';    -- pagos bancos renovante
    csPBRZ              constant varchar2(4) := 'PBRZ';   -- pagos bancos renovante rezagado
    vsNomSeq         VARCHAR2(50);
    csTipoC             CONSTANT char(1) := 'C';
    cgsErr20408      CONSTANT VARCHAR2(200) := 'No esta configurado el Año para proceso CAE';
    cnRoundNum     constant number(1) := 4;     -- decimales a redondear
    csSepara          constant varchar2(1) := ',';    --chr(9);  -- tabulador
    csRen               constant char(1) := 'R' ;   -- tipo renovane
    csLis                  constant char(1) := 'L' ;   -- tipo Licitado
    vsBeneType       char(1);       --md-04
    vsContaInd        char(1);       --md-04

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
    err_num1   NUMBER;
    err_msg1   VARCHAR2 (1999);

    vnExiste   NUMBER:= 0;
    vnSEQ      VARCHAR2(6);
    vsCODE     VARCHAR2(6);
    vsCODECNTY VARCHAR2(6);
    vnSEQCMT   VARCHAR2(10);

    vsRegularE VARCHAR2(10) := '^(*[0-9])';
    vsWhere1   VARCHAR2(10) := '999999';
    vsWhere2   VARCHAR2(10) := '999998';

    vsCampo    VARCHAR2(200);
    vnCantidad  number(12,4) := 0;
    viNumReg    number;

    vsYEAR                 TWRCPBK.TWRCPBK_YEAR%TYPE;
    vsFileSeq              TWRCPBK.TWRCPBK_FILE_SEQ%TYPE;
    vsSeqNum            TWRCPBK.TWRCPBK_SEQ_NUM%TYPE;
    vsRut                    TWRCPBK.TWRCPBK_RUT%TYPE;
    vsDv                     TWRCPBK.TWRCPBK_DV%TYPE;
    vsAnoLiciatacion    TWRCPBK.TWRCPBK_ANO_LICITACION%TYPE;
    vnMontoPago        TWRCPBK.TWRCPBK_MONTO_PAGO%TYPE;
    vnMontoSeguro     TWRCPBK.TWRCPBK_MONTO_SEGURO%TYPE;
    vsRutBanco           TWRCPBK.TWRCPBK_RUT_BANCO%TYPE;
    vsDvBanco            TWRCPBK.TWRCPBK_DV_BANCO%TYPE;
    vsNombreBanco    TWRCPBK.TWRCPBK_NOMBRE_BANCO%TYPE;
    vsNombreBancoAnt  TWRCPBK.TWRCPBK_NOMBRE_BANCO%TYPE;
    vsCodigoBanco      varchar2(5);

    vsError           char(1);
    vsLoad_stat     varchar2(100);
    viExisteBanner  number(5);
    viResagado      number(3);
    vsStatRes         varchar2(4);
    viPidm              number(10);
    viSeqNum        number(4);
    vsRutGral         varchar2(15);
    -- vsNameArchivo  varchar2(300);   --md-01
     
    vsalida               VARCHAR2(3000);      --md-06  start
    vsNameArchivo    varchar2(300);   
    vsArchExitente     varchar2(300);    
     vsArchExSize       number(10):= 0;
     vrArchivoExBlob   BLOB;
     viArchVivo           number(4) := 0;    --md-06  end            

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
           and SGBSTDN_LEVL_CODE in ('LI','LC')                    --md-05
           and SGBSTDN_MAJR_CODE_1 <> 'EDME'                       --md-05
           ORDER BY SGBSTDN_TERM_CODE_EFF desc, sgbstdn_activity_date ;

     --md-06 start     
     cursor ArchExistente   is 
                  SELECT   NAME  ,    DOC_SIZE    , BLOB_CONTENT
                  -- from SWBFOTO   --md-x
                  from   GWBDOCS
                  WHERE NAME like  vsNameArchivo
                  order by LAST_UPDATED desc;
     
     --md-06 end      
           
BEGIN

-- IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;
-- nota esta página por sus características, no es del tipo de separación PL de codigo HTML

--  año general del proceso cae
    vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');
    IF vsYEAR IS NULL THEN
        RAISE_APPLICATION_ERROR(-20408, cgsErr20408, TRUE);
    END IF;    
    
    vsBeneType := 'C' ;       --md-04
    vsContaInd := '0' ;        --md-04
    
     --md-06 start    
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

    --obtengo los datos del archivo
--    Select  DOC_SIZE, BLOB_CONTENT  INTO  vnTamano,  vrArchivoBLOB
--    FROM   GWBDOCS
--    WHERE  NAME like vsNameArchivo;

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

    --Muestro los datos del archivo
    /* md-01 start
    p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
    p_ImprimeLineaResultado ('Tamaño de archivo: ' || vnTamano);
    p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);
    md-01 end */
--  verificar que no se haya subido previamente este archivo


--  verificar que no se haya subido previamente este archivo
--    vsExiste := 'N';
--    for cur_archivo in ( SELECT GWBAACR_USER  ,GWBAACR_ACTIVITY_DATE
--                       FROM GWBAACR
--                       where GWBAACR_NOMBRE_ARCHIVO like vsNameArchivo
--                       order by GWBAACR_ACTIVITY_DATE desc)  loop
--
--         vsUserAnt := cur_archivo.GWBAACR_USER;
--         vdFechaAnt := cur_archivo.GWBAACR_ACTIVITY_DATE;
--         vsExiste := 'Y';
--         exit;
--    end loop;

--    BEGIN
--
--        SELECT GWBAACR_USER  ,GWBAACR_ACTIVITY_DATE INTO vsUserAnt  ,vdFechaAnt
--        FROM GWBAACR
--        WHERE GWBAACR_TAMANO = vnTamano
--        AND GWBAACR_HASH_SHA1 = vrDigestionSHA1;
--
--        vsExiste := 'Y';
--
--    EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--            vsExiste := 'N';
--    END;

    --Si existe, indico que no se puede volver a subir este mismo archivo
--    IF vsExiste = 'Y' THEN
--        -- Eliminar el archivo recien subido
--        DELETE GWBDOCS
--        WHERE  NAME like  vsNameArchivo;
--        COMMIT;
--
--       -- md-01 start
--        --Informo al usuario.
--
--        INSERT INTO GWRERRO VALUES (cgsCodApp,psArchivo ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);
--        COMMIT;
--
--        /* p_ImprimeLineaResultado ( 'Este archivo ya se había subido anteriormente.');
--        p_ImprimeLineaResultado (  'Usuario: '||vsUserAnt||'. Fecha y Hora: ' ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.'  );
--        p_ImprimeLineaResultado ('No se procesara .');    md-01 end*/
--
--        RETURN;

--    END IF;

--md-01 end

--    vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');
--    --Obtengo Numero de secuencia de archivo
--    vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);
--    vgsUsr := NVL(vgsUSR,USER);

    -- p_ImprimeLineaResultado ('Número de proceso: ' || vnNumProcCarga);  md-01
    
    --md-06 end 

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
    vsNombreBancoAnt := ' ';

    -- calulando valor de rezagado
    viResagado := 0;
    for curRes in cur_resagado loop
        viResagado := curRes.limite;
    end loop;
    if viResagado = 0 then  -- carga normal
      vsStatRes := csPBR;
    else  -- carga resagada
      vsStatRes := csPBRZ;
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

               /* campos solicitados
               RUT,DV,Monto Pago, Monto Seguro, Banco, Anio Proceso
               */

           -- TWRCPBK_RUT  -- campo1 - vsRut
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,1,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                   vsCampo := NULL;
                   vsError := 'E';
                   vsLoad_stat := '1';
               ELSE
                   vsCampo :=  TRIM(vsCampo);
               END IF;
               vsRut := vsCampo;

           -- TWRCPBK_DV -- campo2 - vsDv
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,2,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                    vsCampo := NULL;
                     if vsError is null then
                        vsError := 'E';
                     end if ;
                     vsLoad_stat := vsLoad_stat || ' 2';
               ELSE
                    vsCampo := upper( TRIM(vsCampo));
               END IF;
               vsDv := vsCampo;

           -- TWRCPBK_MONTO_Pago -- campo3 - vnMontoPago
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
               vsCampo := replace( replace( vsCampo, '"'),',','.');
               vnCantidad :=  instr(vsCampo,'.');
               if vnCantidad <> 0 then
                   vsCampo := substr(  vsCampo , 1 , vnCantidad + 4);
               end if;
               vnCantidad := round(to_number(vsCampo , '999999999.9999'),cnRoundNum);
               vnMontoPago := vnCantidad;


           -- TWRCPBK_MONTO_SEGURO -- campo4 - vnMontoSeguro
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
               vsCampo := replace( replace( vsCampo, '"'),',','.');
               vnCantidad :=  instr(vsCampo,'.');
               if vnCantidad <> 0 then
                   vsCampo := substr(  vsCampo , 1 , vnCantidad + 4);
               end if;
               vnCantidad := round(to_number(vsCampo , '999999999.9999'),cnRoundNum);
               vnMontoSeguro := vnCantidad;

           -- TWRCPBK_NOMBRE_BANCO -- campo5 - vsNombreBanco
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

               if vsNombreBanco <> vsNombreBancoAnt then

                   vsNombreBancoAnt := vsNombreBanco;

                   -- calcular rut-dv del banco en base al nombre
                   select nvl(TWVBANK_RUT_BANCO, ''), twvbank_code  into vsRutGral, vsCodigoBanco
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

               end if;

           -- TWRCPBK_ANO_LICITACION  -- campo6 - vsAnoLiciatacion
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
                  select count(1) + 1 into viSeqNum
                  from   TWRCPBK
                  -- where  TWRCPBK_YEAR = vsYEAR                    --md-03
                  where  TWRCPBK_ANO_LICITACION = vsAnoLiciatacion   --md-03
                  and    TWRCPBK_RUT  = vsRut;

                  err_msg1 := null;

                  if viSeqNum >= 2 then  --mas de 2 depositos
                     vsLoad_stat := ' Alumno con mas de 2 depositos ';
                     err_msg1 := vsLoad_stat;
                  end if;

                  viPidm := 0;
                  for cuPidm in cur_Pidm loop
                     viPidm := cuPidm.sgbstdn_pidm;
                     exit;
                  end loop;

                   -- inserta archivo Fianza Bancos
                   INSERT INTO TWRCPBK (
                                        TWRCPBK_FILE_SEQ       ,
                                        TWRCPBK_SEQ_NUM        ,
                                        TWRCPBK_YEAR           ,
                                        TWRCPBK_RUT            ,
                                        TWRCPBK_DV             ,
                                        TWRCPBK_ANO_LICITACION ,
                                        TWRCPBK_MONTO_PAGO     ,
                                        TWRCPBK_MONTO_SEGURO   ,
                                        TWRCPBK_MONTO_DEUDA    ,
                                        TWRCPBK_RUT_BANCO      ,
                                        TWRCPBK_DV_BANCO       ,
                                        TWRCPBK_NOMBRE_BANCO   ,
                                        TWRCPBK_STATUS_CODE    ,
                                        TWRCPBK_TIPO_CAE       ,
                                        TWRCPBK_LOAD_ERROR     ,
                                        TWRCPBK_PROCESS_ERROR  ,
                                        TWRCPBK_USER           ,
                                        TWRCPBK_ACTIVITY_DATE  ,
                                        TWRCPBK_DIA_CARGA      ,
                                        TWRCPBK_PIDM)
                               VALUES (
                                        vnNumProcCarga,
                                        viSeqNum,   -- CONCECUTIVO  EN LA TABLA PARA EL RUT
                                        vsYEAR,
                                        vsRut,
                                        vsDv,
                                        vsAnoLiciatacion,
                                        vnMontoPago,
                                        vnMontoSeguro,
                                        nvl(vnMontoPago,0) + nvl(vnMontoSeguro,0),
                                        vsRutBanco,
                                        vsDvBanco,
                                        vsNombreBanco,
                                        vsStatRes ,     -- csStatusCAE,
                                        csRen,          -- renovante
                                        vsLoad_stat,    -- stat de carga
                                        err_msg1,       -- error de proceso
                                        vgsUsr ,
                                        SYSDATE,
                                        sysdate,
                                        viPidm  );

                  --insert into twraacp values ( cgsCodApp, vnNumProcCarga, vnNumLineas, vsRut || '-' || vsDv , 'A' , null, sysdate, vgsUSR);  --md-05

                  if viPidm > 0 then -- es alumno uft

                     -- ver que no tenga un deposito bancario previo ..
                     select count(1) into viSeqNum
                     from TWRCABA
                     where TWRCABA_PIDM = viPidm
                     and TWRCABA_ANIO_LICITA = vsAnoLiciatacion
                     and TWRCABA_BANK_CODE is not null
                     and TWRCABA_TIPO_DOCUMENTO is null;

                     if viSeqNum = 0 then
                        viExisteBanner :=   viExisteBanner + 1;

                        -- que entrada le corresponde
                        select nvl( max(TWRCABA_SEQ_NUM),0) into viSeqNum
                        from TWRCABA
                        where TWRCABA_PIDM = viPidm
                        and TWRCABA_ANIO_LICITA = vsAnoLiciatacion;

                        viSeqNum := viSeqNum +1;

                        insert into TWRCABA  (
                              TWRCABA_ANIO_LICITA,
                              TWRCABA_PIDM,
                              TWRCABA_SEQ_NUM,
                              TWRCABA_BANK_CODE ,
                              TWRCABA_MONTO_DEPOSITO ,
                              TWRCABA_MONTO_FIANZA ,
                              TWRCABA_PAGADO,
                              TWRCABA_ENTRY_DATE ,
                              TWRCABA_MONTO_BALANCE,
                              TWRCABA_SALDO_FIANZA ,                       --md-02
                              TWRCABA_ACTIVITY_DATE ,
                              TWRCABA_USER,
                              TWRCABA_TIPO_BENE,                            --md-04
                              TWRCABA_CONT_IND                              --md-04
                              )
                          values(vsAnoLiciatacion,
                                viPidm,
                                viSeqNum,
                                vsCodigoBanco,
                                vnMontoPago,
                                NVL(vnMontoSeguro,0),
                                'D',
                                sysdate,
                                NVL(vnMontoPago,0) + NVL(vnMontoSeguro,0) ,
                                NVL(vnMontoSeguro,0),                      --md-02
                                sysdate,
                                'Banscr',
                                vsBeneType,       --md-04
                                vsContaInd        --md-04
                                 );

                        -- sig entrada en twrcaes
                        select Nvl( max(TWRCAES_SEQ_NUM), 0) + 1  into viSeqNum
                        from twrcaes
                        where TWRCAES_RUT = vsRut
                        and TWRCAES_YEAR = vsAnoLiciatacion;

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
                                     TWRCAES_STATUS_UNI )        -- md-02 end
                           values ( vsRut
                                  ,vsDv
                                  ,viSeqNum         -- consecutivo conforme mov del rut
                                  ,vsStatRes        -- csStatusCAE    -- ps  md-04
                                  ,viPidm
                                  ,vnNumProcCarga   --vnNumProcCarga -- numero de arch carga  --md-04
                                  ,csTipoC          -- C de carga
                                  , NULL
                                  , 'Carga Pago Banco' -- vsError        -- null si no tiene error
                                  , NULL
                                  , err_msg1 || 'Carga Pago Banco ' || vsNombreBanco || ' en Carga '  || vnNumProcCarga   -- errores en la carga de arch
                                  ,vsAnoLiciatacion
                                  ,vgsUsr
                                  ,sysdate
                                  ,csPBR);     --md-02 se agrega status Unico

                     end if;

                     --- INSERTA EN BITACORA CAE
                     if vnBitacoraSeq >= 50 then
                        vnBitacoraSeq := 0;
                        COMMIT;
                     end if;

                     vnBitacoraSeq := vnBitacoraSeq + 1;

                     insert into twraacp values ( cgsCodApp, vnNumProcCarga, vnNumLineas, vsRut || '-' || vsDv , 'A' , null, sysdate, vgsUSR);  --md-05

                  else

                     insert into twraacp values ( cgsCodApp, vnNumProcCarga, vnNumLineas, vsRut || '-' || vsDv , 'U' , null, sysdate, vgsUSR);  --md-05

                  end if;
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

  -- vgsUsr := NVL(vgsUSR,USER);
  -- Indico al usuario que ya termine
    /* md-01 start
    p_ImprimeLineaResultado('Registros cargados ' || viNumReg );
    p_ImprimeLineaResultado('Alumnos UFT : ' || viExisteBanner );
    p_ImprimeLineaResultado('Procesamiento del archivo CAE Pagos Bancos Terminado.');
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

END pk_CargaCaePagosBancoRenovaNv;
/


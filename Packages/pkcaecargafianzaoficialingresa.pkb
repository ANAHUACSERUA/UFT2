CREATE OR REPLACE PACKAGE BODY BANINST1.pkCaeCargaFianzaOficialIngresa IS
                                        

/******************************************************************************
PAQUETE:            BANINST1.pk_CaeCargaFianzasOficialIngresa
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos de fianzas del sistema Ingresa
AUTOR:              Roman Ruiz
FECHA:              20 oct 2014
--------------------------------------------
modificacion        md-01
objetivo            cambio de paqute de carga de archivos (kwaproceso)
autor               roman ruiz
fecha               26-feb-2014
--------------------------------------------
modificacion        md-02
objetivo            se adiciona filtro de sgbstdn al registro del estudiante
autor               roman ruiz
fecha               09-jul-2015
******************************************************************************/

    --variable para seguridad GWAMNUR
    vgsUSR              VARCHAR2(500);
    global_aidm         SABNSTU.SABNSTU_AIDM%TYPE;
    global_id           SABNSTU.SABNSTU_ID%TYPE;
    cgsCodApp           CONSTANT VARCHAR2(4) := 'CFOI';
    csFOIZ              constant varchar2(4) := 'FOIZ';
    vsNomSeq            VARCHAR2(50);
    csTipoC             CONSTANT char(1) := 'C';
    cgsErr20408         CONSTANT VARCHAR2(200) := 'No esta configurado el Año para proceso CAE';
    csStatusCAE         CONSTANT char(3)  := 'FOI'; -- Fianzas oficial Ingresa.
    csStatCCaeH         constant char(2)  := 'CH';  -- carga historica
    cnRoundNum          constant number(1) := 4;     -- decimales a redondear
    csSepara            constant varchar2(1) := ';';    --chr(9);  -- tabulador
    
     
    
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
    viContador  number(9);

    vsYEAR                TWRCFOI.TWRCFOI_YEAR%TYPE;
    vsFileSeq             TWRCFOI.TWRCFOI_FILE_SEQ%TYPE;
    vsSeqNum              TWRCFOI.TWRCFOI_SEQ_NUM%TYPE;
    vsRut                 TWRCFOI.TWRCFOI_RUT%TYPE;
    vsDv                  TWRCFOI.TWRCFOI_DV%TYPE;
    vsAnoLiciatacion      TWRCFOI.TWRCFOI_ANO_LICITACION%TYPE;  
    vsNest                TWRCFOI.TWRCFOI_NESTN_COD%TYPE;
    vnTasaDesercion       TWRCFOI.TWRCFOI_TASA_DESERCION%TYPE;
    vnPorcentGarantia     TWRCFOI.TWRCFOI_PORCENTAJE_GARANTIA%TYPE;
    vsSaldoDeuda          TWRCFOI.TWRCFOI_SALDO_DEUDA%TYPE;
    vsMontoFianza         TWRCFOI.TWRCFOI_MONTO_FIANZA%TYPE;
    vsMontoBoleta         TWRCFOI.TWRCFOI_MONTO_BOLETA%TYPE;
    vsRutBanco            TWRCFOI.TWRCFOI_RUT_BANCO%TYPE;
    vsDvBanco             TWRCFOI.TWRCFOI_DV_BANCO%TYPE;
    vsNombreBanco         TWRCFOI.TWRCFOI_NOMBRE_BANCO%TYPE;
      
    vsError         char(1);
    vsLoad_stat     varchar2(100);
    viExisteBanner  number(5);
    viResagado      number(3); 
    vsStatRes       varchar2(4);   
    viPidm          number(10); 
    viSeqNum        number(4);
    vsNameArchivo   varchar2(300); 
    
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
           and SGBSTDN_LEVL_CODE in ('LI','LC')                    --md-02
           and SGBSTDN_MAJR_CODE_1 <> 'EDME'                       --md-02
           ORDER BY SGBSTDN_TERM_CODE_EFF desc, sgbstdn_activity_date ; 

BEGIN

-- Seguridad de GWAMNUR
-- IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;
-- nota esta página por sus características, no es del tipo de separación PL de codigo HTML

--  año general del proceso cae

    INSERT INTO  GWBDOCS(
                 SELECT   x.NAME          ,  x.MIME_TYPE     ,
                          x.DOC_SIZE      , x.DAD_CHARSET   ,
                          x.LAST_UPDATED  , x.CONTENT_TYPE  ,
                          NULL          , x.BLOB_CONTENT  ,
                          x.PLAIN_TEXT    , x.NOT_READ
                 from SWBFOTO  x  
                 WHERE x.NAME = psArchivo );
    Commit;
   
    vsNameArchivo := '%'||substr(psArchivo,instr(psArchivo,'/') + 1)||'%';
    
    delete  from SWBFOTO
    where name = psArchivo;   
    commit; 

    vsYEAR := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');

    --Si no se encontró el nombre de la secuencia mandamos error
--    IF vsYEAR IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20408, cgsErr20408, TRUE);
--    END IF;

--  Inicio de la pagina HTML
 -- DBMS_OUTPUT.PUT_LINE(PK_ObjHTML.vgsCssBanner);

    
    --obtengo los datos del archivo
    select DOC_SIZE, BLOB_CONTENT  Into vnTamano, vrArchivoBLOB
    FROM   GWBDOCS
    WHERE  NAME  like  vsNameArchivo;

    --calculo la firma SHA1 del archivo
    vrDigestionSHA1 := DBMS_CRYPTO.HASH(vrArchivoBLOB,DBMS_CRYPTO.HASH_SH1);

    /* md-01 start
    --Muestro los datos del archivo
    p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
    p_ImprimeLineaResultado ('Tamaño de archivo: ' || vnTamano);
    p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);
    md-01 end */

--  verificar que no se haya subido previamente este archivo
    vsExiste := 'N';
    for cur_archivo in ( SELECT GWBAACR_USER  ,GWBAACR_ACTIVITY_DATE 
                       FROM GWBAACR
                       where GWBAACR_NOMBRE_ARCHIVO like vsNameArchivo
                       order by GWBAACR_ACTIVITY_DATE desc)  loop 
         
         vsUserAnt := cur_archivo.GWBAACR_USER;
         vdFechaAnt := cur_archivo.GWBAACR_ACTIVITY_DATE;
         vsExiste := 'Y';
         exit; 
    end loop; 

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
    IF vsExiste = 'Y' THEN
         
        -- Eliminar el archivo recien subido
        DELETE GWBDOCS
        WHERE  NAME like vsNameArchivo;
        COMMIT;
        
        -- md-01 start
        --Informo al usuario.
        
        INSERT INTO GWRERRO VALUES (cgsCodApp,psArchivo ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);        
        COMMIT; 
        
        /*
        p_ImprimeLineaResultado ( 'Este archivo ya se había subido anteriormente.');        
        p_ImprimeLineaResultado (  'Usuario: '||vsUserAnt||'. Fecha y Hora: ' ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.'  );
        p_ImprimeLineaResultado ('No se procesara .');
        md-01 end*/

        RETURN;
        
    END IF;
       
    vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');
    --Obtengo Numero de secuencia de archivo
    vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);
    vgsUsr := NVL(vgsUSR,USER);

    --Imprimo el numero de proceso
    -- p_ImprimeLineaResultado ('Número de proceso: ' || vnNumProcCarga); -- md-01
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
      vsStatRes := csStatusCAE; 
    else
      -- carga resagada
      vsStatRes :=  csFOIZ; 
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
              --RUT;DV;NOMBRES;PATERNO;MATERNO;ANO_LICITACION;TIESN_COD;IESN_COD;SEDEN_COD;CARRN_COD;JORNN_COD;NOMBRE_IES;NOMBRE_CARRERA;NESTN_COD;TASA_DESERCION;PORCENTAJE_GARANTIA;SALDO_DEUDA;MONTO_FIANZA;MONTO_BOLETA;RUT_BANCO;DV_BANCO;NOMBRE_BANCO
               -- Variabla para determinar Errores   E = (sin rut no continua)  e = solo falta de dato   
               vsError     := null ;
               -- Campo en donde se dio el error. 
               vsLoad_stat := null ;  
             /* campos solicitados 
             rut, dv, año licitacion, NESTN_COD, TASA_DESERCION PORCENTAJE_GARANTIA SALDO_DEUDA MONTO_FIANZA MONTO_BOLETA RUT_BANCO DV_BANCO    
             */            

           -- TWRCFOI_RUT  -- campo1 - vsRut
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,1,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                   vsCampo := NULL;
                   vsError := 'E';
                   vsLoad_stat := '1';
               ELSE
                   vsCampo :=  TRIM(vsCampo);
               END IF;
               vsRut := vsCampo;

           -- TWRCFOI_DV -- campo2 - vsDv
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
               
           --TWRCFOI_ANO_LICITACION  -- campo6 - vsAnoLiciatacion
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

           -- TWRCFOI_NESTN -- campo14 - vsNest
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,14,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                   vsCampo := NULL;
                   if vsError is null then
                      vsError := 'e';
                   end if ;
                   vsLoad_stat := vsLoad_stat || ' 14';
               ELSE
                   vsCampo :=  TRIM(vsCampo);
               END IF;
               vsNest := vsCampo;

           --TWRCFOI_TASA_DESERCION-- campo15 - vnTasaDesercion
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,15,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                  vsCampo := 0;
                  if vsError is null then
                     vsError := 'e';
                  end if ;
                  vsLoad_stat := vsLoad_stat || ' 15';
               ELSE
                  vsCampo :=  TRIM(vsCampo);
               END IF;
               vsCampo := replace( replace( vsCampo, '"'),',','.'); 
               vnCantidad := to_number( vsCampo,'9999.99'); 
               vnTasaDesercion := vnCantidad;

           -- TWRCFOI_PORCENTAJE_GARANTIA -- campo16 - vnPorcentGarantia
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,16,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                  vsCampo := 0;
                  if vsError is null then
                     vsError := 'e';
                  end if ;
                  vsLoad_stat := vsLoad_stat || ' 16';
               ELSE
                  vsCampo :=  TRIM(vsCampo);
               END IF;
               vsCampo := replace( replace( vsCampo, '"'),',','.'); 
               vnCantidad := to_number(vsCampo,'9999.99'); 
               vnPorcentGarantia := vnCantidad;

           -- TWRCFOI_SALDO_DEUDA -- campo17 - vsSaldoDeuda
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,17,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                  vsCampo := 0;
                  if vsError is null then
                     vsError := 'e';
                  end if ;
                  vsLoad_stat := vsLoad_stat || ' 17';
               ELSE
                  vsCampo :=  TRIM(vsCampo);
               END IF;
               vsCampo := replace( replace( vsCampo, '"'),',','.');               
               vsCampo := substr(  vsCampo , 1 , instr(vsCampo,'.') + 4);               
               vnCantidad := round(to_number(vsCampo , '99999999.9999'),cnRoundNum); 
               vsSaldoDeuda := vnCantidad;

           -- TWRCFOI_MONTO_FIANZA -- campo18 - vsMontoFianza
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,18,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                  vsCampo := 0;
                  if vsError is null then
                     vsError := 'e';
                  end if ;
                  vsLoad_stat := vsLoad_stat || ' 18';
               ELSE
                  vsCampo :=  TRIM(vsCampo);
               END IF;
               vsCampo := replace( replace( vsCampo, '"'),',','.');
               vsCampo := substr(  vsCampo , 1 , instr(vsCampo,'.') + 4); 
               vnCantidad := round(to_number(vsCampo, '99999999.9999'),cnRoundNum);
               vsMontoFianza := vnCantidad;

               -- TWRCFOI_MONTO_BOLETA -- campo19 - vsMontoBoleta
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,19,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                  vsCampo := NULL;
                  if vsError is null then
                     vsError := 'e';
                  end if ;
                  vsLoad_stat := vsLoad_stat || ' 19';
               ELSE
                  vsCampo :=  TRIM(vsCampo);
               END IF;
               vsCampo := replace( replace( vsCampo, '"'),',','.');
               vsCampo := substr(  vsCampo , 1 , instr(vsCampo,'.') + 4);        
               vnCantidad := round(to_number(vsCampo, '9999999.99999'),cnRoundNum);
               vsMontoBoleta := vnCantidad; 

               -- TWRCFOI_RUT_BANCO -- campo20 - vsRutBanco
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,20,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                  vsCampo := NULL;
                  if vsError is null then
                     vsError := 'e';
                  end if ;
                  vsLoad_stat := vsLoad_stat || ' 20';
               ELSE
                  vsCampo :=  TRIM(vsCampo);
               END IF;
               vsRutBanco := vsCampo;

               -- TWRCFOI_DV_BANCO  -- campo21 - vsDvBanco
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,21,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                  vsCampo := NULL;
                  if vsError is null then
                     vsError := 'e';
                  end if ;
                  vsLoad_stat := vsLoad_stat || ' 21';
               ELSE
                  vsCampo :=  TRIM(vsCampo);
               END IF;
               vsDvBanco := vsCampo;

               -- TWRCFOI_NOMBRE_BANCO  -- campo 22 - vsNombreBanco
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,22,csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                  vsCampo := NULL;
                  if vsError is null then
                     vsError := 'e';
                  end if ;
                  vsLoad_stat := vsLoad_stat || ' 22';
               ELSE
                  vsCampo :=  TRIM(vsCampo);
               END IF;
               vsNombreBanco := vsCampo;

               -- linea de descripcion de Error
               if vsError is not null then
                     vsLoad_stat := 'faltan campos ' || vsLoad_stat;
               end if;

               -- BEGIN
               if vsError = 'e' or vsError is null then   
               
                  viNumReg := viNumReg + 1;
                  
                  -- verificar su exsitencia el rut  en twrcarh e incrementar secuencial en 1 
                  select count(1) into viContador
                  from   TWRCFOI
                  where  TWRCFOI_YEAR = vsYEAR
                  and    TWRCFOI_RUT   = vsRut;
                  
                  viContador := viContador + 1;                                
                  
                  -- inserta archivo cae
                   INSERT INTO TWRCFOI ( TWRCFOI_FILE_SEQ   
                                        , TWRCFOI_SEQ_NUM    
                                        , TWRCFOI_YEAR        
                                        , TWRCFOI_RUT        
                                        , TWRCFOI_DV          
                                        , TWRCFOI_ANO_LICITACION  
                                        , TWRCFOI_NESTN_COD      
                                        , TWRCFOI_TASA_DESERCION 
                                        , TWRCFOI_PORCENTAJE_GARANTIA
                                        , TWRCFOI_SALDO_DEUDA        
                                        , TWRCFOI_MONTO_FIANZA       
                                        , TWRCFOI_MONTO_BOLETA       
                                        , TWRCFOI_RUT_BANCO          
                                        , TWRCFOI_DV_BANCO           
                                        , TWRCFOI_NOMBRE_BANCO       
                                        , TWRCFOI_STATUS_CODE        
                                        , TWRCFOI_LOAD_ERROR         
                                        , TWRCFOI_PROCESS_ERROR      
                                        , TWRCFOI_SEND_SEQ           
                                        , TWRCFOI_USER               
                                        , TWRCFOI_ACTIVITY_DATE  
                                         )
                                       VALUES ( vnNumProcCarga,
                                                viContador,  --CONCECUTIVO  EN LA TABLA PARA EL RUT
                                                vsYEAR,
                                                vsRut,
                                                vsDv,
                                                vsAnoLiciatacion, 
                                                vsNest,
                                                vnTasaDesercion,
                                                vnPorcentGarantia,
                                                vsSaldoDeuda,
                                                vsMontoFianza,
                                                vsMontoBoleta,
                                                vsRutBanco,
                                                vsDvBanco,
                                                vsNombreBanco,                                               
                                                vsStatRes , --csStatusCAE, 
                                                vsLoad_stat,
                                                null,       -- error de proceso     
                                                null,       -- num de envio
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
                                  TRWCAES_CNTR_NUM       ,
                                  TWRCAES_SEND_SEQ       ,
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
                               ,viSeqNum       -- consecutivo conforme mov del rut
                               ,vsStatRes      -- csStatusCAE    -- ps  md-04
                               ,viPidm
                               ,vnNumProcCarga              --vnNumProcCarga -- numero de arch carga  --md-04
                               ,null           -- TRWCAES_CNTR_NUM
                               ,null           -- TWRCAES_SEND_SEQ
                               ,csTipoC        -- C de carga
                               ,null           --'Carga Fianza IES Oficial' -- vsError        -- null si no tiene error
                               ,'Carga Fianza IES Oficial del archvio ' || vnNumProcCarga  -- errores en la carga de arch
                               , null          -- eror en proceso
                               , null          -- error (glosa)
                               ,vsYEAR
                               ,vgsUsr
                               ,sysdate
                               ,csStatusCAE);     -- se agrega status Unico
                               
                      insert into twraacp values ( cgsCodApp, vnNumProcCarga, vnNumLineas, vsRut || '-' || vsDv , 'A' , null, sysdate, vgsUSR);  --md-05                               
                  
                  end if; 
                  
                  --- INSERTA EN BITACORA CAE                  
                                   
                  if vnBitacoraSeq >= 500 then
                     vnBitacoraSeq := 0;
                     COMMIT;
                  end if;
                  
                  vnBitacoraSeq := vnBitacoraSeq + 1;
               else
               
               insert into twraacp values ( cgsCodApp, vnNumProcCarga, vnNumLineas, vsRut || '-' || vsDv , 'E' , null, sysdate, vgsUSR);  --md-05

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
                           ,vnNumLineas - 1   -- restando el encabezado
                           ,vnTamano
                           ,vrDigestionSHA1
                           ,vnNumProcCarga
                           ,SYSDATE
                           ,vgsUSR  );

      commit;
 
  --  vgsUsr := NVL(vgsUSR,USER);
    /* md-01 start
    --Indico al usuario que ya termine    
    p_ImprimeLineaResultado('Registros cargados ' || viNumReg );
    p_ImprimeLineaResultado('Alumnos UFT : ' || viExisteBanner );    
    p_ImprimeLineaResultado('Procesamiento del archivo CAE Fianza Oficial Ingresa terminado.');
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



END pkCaeCargaFianzaOficialIngresa;
/

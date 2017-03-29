CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaCCP_Nv IS

/******************************************************************************
PAQUETE:            BANINST1.pk_CargaCCP
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos
AUTOR:              Marcela Altamirano Chan
FECHA:              20100922
--------------------
modificacion        md-01
objetivo            cambio de paqute de carga de archivos (kwaproceso)
autor               roman ruiz
fecha               19-mar-2014
--------------------
modificacion        md-02
objetivo            unifica metodo de carga
autor               roman ruiz
fecha               5-feb-2016
--------------------
modificacion        md-03
objetivo            Cambio de layout 
autor               roman ruiz
fecha               8-feb-2016
--------------------
modificacion        md-04
objetivo           Actualizar si existe el colegio 
autor               roman ruiz
fecha               22-feb-2016

******************************************************************************/

    --variable para seguridad GWAMNUR
    vgsUSR              VARCHAR2(500);
    global_aidm         SABNSTU.SABNSTU_AIDM%TYPE;
    global_id           SABNSTU.SABNSTU_ID%TYPE;

    cgsCodApp            CONSTANT VARCHAR2(4) := 'CPCC';
    vsNomSeq            VARCHAR2(50);
----prototipos de Funciones y procedimientos privados
----veasé el cuerpo del procedimiento/funcion para mayor info


PROCEDURE p_ImprimeLineaResultado(psLinea             VARCHAR2);
----fin de prototipos privados

/******************************************************************************
PROCEDIMIENTO:      p_Carga
OBJETIVO:           Procesa un archivo
PARAMETROS:
psArchivo           Nombre con que fue guardado el archivo cargado
                    por el usuario. Este nombre es proveido por la base de
                    datos con el que el archivo puede ser extraido de la tabla
                    indicada por la configuración del DAD.
******************************************************************************/
PROCEDURE p_Carga(
                    psArchivo         VARCHAR2
                   ,psUser             VARCHAR2 DEFAULT USER
                 ) IS

    --Guarda la Firma SHA1 del archivo
    vrDigestionSHA1     RAW(20);
    --Guarda el tamaño del archivo
    vnTamano            NUMBER(10);
    --El archivo en sí, formato BLOB:
    vrArchivoBLOB       BLOB;
    --El archivo en sí, formato CLOB:
    vsArchivoCLOB       CLOB;
    --Variable para verificar que exista el archivo
    vbExiste            BOOLEAN;
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
    viPosIni   number(4);
  --  vsNameArchivo   varchar2(300);   --md-01
    viNumReg   number(6); 
    
    vsalida             VARCHAR2(3000);      --md-02  start
    vsNameArchivo       varchar2(300);   
    vsArchExitente     varchar2(300);    
    vsArchExSize       number(10):= 0;
    vrArchivoExBlob   BLOB;
    viArchVivo           number(4) := 0;    --md-02  end    

    TYPE ADV_REC IS RECORD (
      R_LEDUCACIONAL    SWBCAUE.SWBCAUE_LEDUCACIONAL%TYPE,
      R_UEDUCATIVA      SWBCAUE.SWBCAUE_UEDUCATIVA%TYPE,
      R_APROCESO        SWBCAUE.SWBCAUE_APROCESO%TYPE,
      R_NOFICIAL        SWBCAUE.SWBCAUE_NOFICIAL%TYPE,
      R_CREGION         SWBCAUE.SWBCAUE_CREGION%TYPE,
      R_CPROVINCIA      SWBCAUE.SWBCAUE_CPROVINCIA%TYPE,
      R_CCOLUMNA        SWBCAUE.SWBCAUE_CCOLUMNA%TYPE,
      R_CPOSTAL         SWBCAUE.SWBCAUE_CPOSTAL%TYPE,
      R_DDIRECTO        SWBCAUE.SWBCAUE_DDIRECTO%TYPE,
      R_FPRINCIPAL      SWBCAUE.SWBCAUE_FPRINCIPAL%TYPE,
      R_FAX             SWBCAUE.SWBCAUE_FAX%TYPE,
      R_EMAIL           SWBCAUE.SWBCAUE_EMAIL%TYPE,
      R_DIRECCION       SWBCAUE.SWBCAUE_DIRECCION%TYPE,
      R_REDUCACIONAL    SWBCAUE.SWBCAUE_REDUCACIONAL%TYPE,
      R_REGIMEN         SWBCAUE.SWBCAUE_REGIMEN%TYPE,
      R_DEPENDENCIA     SWBCAUE.SWBCAUE_DEPENDENCIA%TYPE,
      R_GDEPENDENCIA    SWBCAUE.SWBCAUE_GDEPENDENCIA%TYPE,
      R_MPEN_CURSO      SWBCAUE.SWBCAUE_MPEN_CURSO%TYPE,
      R_MULT_CURSO      SWBCAUE.SWBCAUE_MULT_CURSO%TYPE,
      R_NDIRECTOR       SWBCAUE.SWBCAUE_NDIRECTOR%TYPE,
      R_NORIENTADOR     SWBCAUE.SWBCAUE_NORIENTADOR%TYPE,
      R_RELACIONADOR    SWBCAUE.SWBCAUE_RELACIONADOR%TYPE,
      R_RBD             SWBCAUE.SWBCAUE_RBD%TYPE
     , R_CODENSENA        SWBCAUE.SWBCAUE_COD_ENSENANZA%TYPE      --md-03 start
     , R_PNC                    SWBCAUE.SWBCAUE_PNC%TYPE
     , R_PMNC                  SWBCAUE.SWBCAUE_PMNC%TYPE                      --md-03 end
      );

    /** Entity cursor variable type*/
    TYPE ADV_SET IS TABLE OF  ADV_REC;
    ADV_ITEMS ADV_SET;

  vsLEducacional SWBCAUE.SWBCAUE_LEDUCACIONAL%TYPE;
  vsUEucacional SWBCAUE.SWBCAUE_UEDUCATIVA%TYPE;
  vsAProceso SWBCAUE.SWBCAUE_APROCESO%TYPE;
  vsNOficial SWBCAUE.SWBCAUE_NOFICIAL%TYPE;
  vsCRegion SWBCAUE.SWBCAUE_CREGION%TYPE;
  vsCProvincia SWBCAUE.SWBCAUE_CPROVINCIA%TYPE;
  vsCColumna SWBCAUE.SWBCAUE_CCOLUMNA%TYPE;
  vsCPostal SWBCAUE.SWBCAUE_CPOSTAL%TYPE;
  vsDDirecto SWBCAUE.SWBCAUE_DDIRECTO%TYPE;
  vsFPrincipal SWBCAUE.SWBCAUE_FPRINCIPAL%TYPE;
  vsFax SWBCAUE.SWBCAUE_FAX%TYPE;
  vsEmail SWBCAUE.SWBCAUE_EMAIL%TYPE;
  vsDireccion SWBCAUE.SWBCAUE_DIRECCION%TYPE;
  vsREducacional SWBCAUE.SWBCAUE_REDUCACIONAL%TYPE;
  vsRegimen SWBCAUE.SWBCAUE_REGIMEN%TYPE;
  vsDependencia SWBCAUE.SWBCAUE_DEPENDENCIA%TYPE;
  vsGDependencia SWBCAUE.SWBCAUE_GDEPENDENCIA%TYPE;
  vsMPCurso SWBCAUE.SWBCAUE_MPEN_CURSO%TYPE;
  vsMCurso SWBCAUE.SWBCAUE_MULT_CURSO%TYPE;
  vsNDirector SWBCAUE.SWBCAUE_NDIRECTOR%TYPE;
  vsNOrientador SWBCAUE.SWBCAUE_NORIENTADOR%TYPE;
  vsRelacionador SWBCAUE.SWBCAUE_RELACIONADOR%TYPE;
  vsRBD SWBCAUE.SWBCAUE_RBD%TYPE;
  
   vsCodEnsena      SWBCAUE.SWBCAUE_COD_ENSENANZA%TYPE;      --md-03 start
   vsPNC                SWBCAUE.SWBCAUE_PNC%TYPE;
   vsPMNC               SWBCAUE.SWBCAUE_PMNC%TYPE;                       --md-03 end
   
   vs_codigoBann     stvsbgi.stvsbgi_code%type;  --md-04
   viValor                number(5); 

  TYPE vsTYP IS REF CURSOR;
  vsTYPAUE vsTYP;
  vsalida                     varchar2(500);
  
  --vnamecorto                  varchar2(15);

    --Cursor para obtener el contenido del archivo que recien se acaba de cargar
    CURSOR cuArchivo(vsArchivo VARCHAR2) IS
        SELECT DOC_SIZE       AS Tamano
              ,BLOB_CONTENT     AS Contenido
        FROM  GWBDOCS
        WHERE NAME LIKE(vsArchivo);

    --Cursor para ver si el archivo ya habia sido cargado anteriormente
    CURSOR cuAnterior(  pnTamano            NUMBER
                       ,prDigestionSHA1    RAW    ) IS
        SELECT GWBAACR_ACTIVITY_DATE   AS Fecha
              ,GWBAACR_USER            AS Usuario
        INTO
            vdFechaAnt
            ,vsUserAnt
        FROM  GWBAACR
        WHERE GWBAACR_TAMANO    = vnTamano
          AND GWBAACR_HASH_SHA1 = vrDigestionSHA1;

     --md-02 start     
     cursor ArchExistente   is 
                  SELECT   NAME  ,    DOC_SIZE    , BLOB_CONTENT
                  -- from SWBFOTO   --md-x
                  from   GWBDOCS
                  WHERE NAME like  vsNameArchivo
                  order by LAST_UPDATED desc;
     
     --md-02 end            

BEGIN

 -- vnamecorto :=  substr(REPLACE(psArchivo, ' ' ,'' ),1,10);
 
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
   
          INSERT INTO GWRERRO VALUES (cgsCodApp,psArchivo ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);
          
           insert into twraacp values ( cgsCodApp, vnNumProcCarga, 1, 'Arch Repetido ' || vsNameArchivo , 'X' , 'Archivo_Repetido' , sysdate, vgsUSR); 
           
           for  cur_hast in (select GWBAACR_HASH_SHA1  has
                                   from GWBAACR
                                   where GWBAACR_NOMBRE_ARCHIVO = psArchivo
                                   and GWBAACR_TAMANO = vsArchExSize
                                   order by GWBAACR_ACTIVITY_DATE desc ) loop 
                 vrDigestionSHA1 :=  cur_hast.has; 
                 exit  ;
           end loop;             
           
          INSERT INTO GWBAACR ( GWBAACR_NOMBRE_ARCHIVO  ,GWBAACR_TIPO    ,GWBAACR_NUM_REGISTROS  ,GWBAACR_TAMANO
                                                ,GWBAACR_HASH_SHA1  ,GWBAACR_NUM_PROCESO   ,GWBAACR_ACTIVITY_DATE                      ,GWBAACR_USER
                                 )VALUES(  psArchivo  ,cgsCodApp   ,1   ,vsArchExSize
                                                ,vrDigestionSHA1                ,vnNumProcCarga                      ,SYSDATE                      ,vgsUSR                 );
                                                
          delete  from swbfoto
          where name like  vsNameArchivo;                                                
                       
         COMMIT;
         RETURN;              --md-x
         -- rollback;     --md-x          
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
--    where name = psArchivo;   
--    commit;

    --Ojo, esta página por sus características, no es del tipo de separación
    --de codigo PL de codigo HTML
        
    --obtengo los datos del archivo
--    Select  DOC_SIZE, BLOB_CONTENT  INTO  vnTamano,  vrArchivoBLOB
--    FROM   GWBDOCS
--    WHERE  NAME like vsNameArchivo
--    and rownum = 1; 
    
    --calculo la firma SHA1 del archivo
    vrDigestionSHA1 := DBMS_CRYPTO.HASH(vrArchivoBLOB,DBMS_CRYPTO.HASH_SH1);

    --Muestro los datos del archivo
    /*  md-01 start
    p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
    p_ImprimeLineaResultado ('Tama&ntilde;o de archivo: ' || vnTamano);
    p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);
    md-01 end */

    --vbExiste := false; 
    --busco que no se haya subido antes este mismo archivo
--    OPEN cuAnterior(vnTamano, vrDigestionSHA1);
--        FETCH cuAnterior INTO vdFechaAnt, vsUserAnt;
--         vbExiste := cuAnterior%FOUND;
--    CLOSE cuAnterior;
--
----    Si existió el archivo indico que no se puede volver a subir este mismo
--    IF vbExiste  THEN
--        --Elimino el archivo recien subido
--        DELETE  GWBDOCS
--        WHERE NAME = psArchivo;
--        COMMIT;
--
--        INSERT INTO GWRERRO
--        VALUES(cgsCodApp, psArchivo, 'Este archivo ya se había subido anteriormente.', SYSDATE, user   );
--        commit;
          --   md-01 stat     p_ImprimeLineaResultado (
          --            );
          --        p_ImprimeLineaResultado (
          --            'Usuario: '||vsUserAnt||'. Fecha y Hora: '
          --            ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.'
          --            );
          --        p_ImprimeLineaResultado ('No se procesará.');
          -- md-01 end
        --cierro la pagina
        --p_CierrePaginaResultado;
        
--        RETURN;
--        
--    END IF;
    
    --Obtengo Numero de secuencia de archivo
    --NumProcCarga := pk_Contrato.p_NumSec('PROCESO_CARGA_ARCH');
    --Imprimo el numero de proceso    
    -- p_ImprimeLineaResultado ('N&uacute;mero de proceso: ' || vnNumProcCarga); --md-01 start
    
--    vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');
--    --Obtengo Numero de secuencia de archivo
--    vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);
--    vgsUsr := NVL(vgsUSR,USER);
    
    --md-01 end

    --Si sigo aqui es que el archivo existe, procedo a convertir BLOB a CLOB
    vsArchivoCLOB := pk_UtilCrgEnvArch.f_BLOBaCLOB(vrArchivoBLOB);

    --Convierto los saltos de linea de unix a dos
    pk_UtilCrgEnvArch.p_ConvSaltoLineaUnixDos(vsArchivoCLOB);

    --comienzo a extraer las lineas del archivo
    vni := 1;
    vnNumLineas := 0;

    --global_rut := 0;
    WHILE vni <= vnTamano LOOP

        vsLinea := pk_UtilCrgEnvArch.f_ExtraeLineaCLOB(vsArchivoCLOB, vni );

        --verificamos que no se haya regresado null
        IF vsLinea IS NOT NULL THEN

            --Incremento mi contador de lineas
            vnNumLineas := vnNumLineas + 1;

            --Obtengo el tamaño de la linea
            vnTamLinea := LENGTH(vsLinea);

            --Incremento la posicion actual
            vni := vni + vnTamLinea;

            --Linea de depuracion
            --p_ImprimeLineaResultado(vsLinea);

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 0, 4))),0) = 0) THEN
                vsLEducacional := NULL;
            ELSE
                vsLEducacional  :=  TRIM(SUBSTR(vsLinea, 0, 4));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 5, 2))),0) = 0) THEN
                vsUEucacional := NULL;
            ELSE
                vsUEucacional  :=   TRIM(SUBSTR(vsLinea, 5, 2));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 7, 4))),0) = 0) THEN
                vsAProceso := NULL;
            ELSE
                vsAProceso  :=  TRIM(SUBSTR(vsLinea, 7, 4));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 11, 45))),0) = 0) THEN
                vsNOficial := NULL;
            ELSE
                vsNOficial  :=  TRIM(SUBSTR(vsLinea, 11, 45));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 56, 2))),0) = 0) THEN
                vsCRegion := NULL;
            ELSE
                vsCRegion  :=  TRIM(SUBSTR(vsLinea, 56, 2));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 58, 3))),0) = 0) THEN
                vsCProvincia := NULL;
            ELSE
                vsCProvincia  :=  TRIM(SUBSTR(vsLinea, 58, 3));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 61, 5))),0) = 0) THEN
                vsCColumna := NULL;
            ELSE
                vsCColumna  :=  TRIM(SUBSTR(vsLinea, 61, 5));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 66, 8))),0) = 0) THEN
                vsCPostal := NULL;
            ELSE
                vsCPostal  :=  TRIM(SUBSTR(vsLinea, 66, 8));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 74, 2))),0) = 0) THEN
                vsDDirecto := NULL;
            ELSE
                vsDDirecto  :=  TRIM(SUBSTR(vsLinea, 74, 2));
            END IF;

            -- IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 76, 7))),0) = 0) THEN    --md-03
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 76, 8))),0) = 0) THEN       --md-03
                vsFPrincipal := NULL;
            ELSE
                --vsFPrincipal  :=  TRIM(SUBSTR(vsLinea, 76, 7));   --md-03
                vsFPrincipal  :=  TRIM(SUBSTR(vsLinea, 76, 8));   --md-03
            END IF;
           
            --IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 83, 7))),0) = 0) THEN   --md-03
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 84, 8))),0) = 0) THEN     --md-03
                vsFax := NULL;
            ELSE
                --vsFax  :=  TRIM(SUBSTR(vsLinea, 83, 7));       --md-03
                vsFax  :=  TRIM(SUBSTR(vsLinea, 84, 8));          --md-03
            END IF;

            viPosIni:= 92;                      --md-01  90 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 60))),0) = 0) THEN     --md-01  90 orignal 
                vsEmail := NULL;
            ELSE
                vsEmail  :=  TRIM(SUBSTR(vsLinea, viPosIni, 60));                 --md-01  90 orignal
            END IF;
            
            viPosIni:= 152;                      --md-01  150 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 51))),0) = 0) THEN  --md-01  150 original
                vsDireccion := NULL;
            ELSE
                vsDireccion  :=  TRIM(SUBSTR(vsLinea, viPosIni, 51));         --md-01  150 original  
            END IF;
            
            viPosIni:= 203;                      --md-01     201 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 2))),0) = 0) THEN   --md-01     201 orignal
                vsREducacional := NULL;
            ELSE
                vsREducacional  :=  TRIM(SUBSTR(vsLinea, viPosIni, 2));      --md-01     201 orignal
            END IF;
            
            viPosIni:= 205;                      --md-01     203 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 1))),0) = 0) THEN  --md-01     203 orignal
                vsRegimen := NULL;
            ELSE
                vsRegimen  :=  TRIM(SUBSTR(vsLinea, viPosIni, 1));           --md-01     203 orignal
            END IF;
            
            viPosIni:= 206;                      --md-01     204 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 1))),0) = 0) THEN   --md-01     204 orignal
                vsDependencia := NULL;
            ELSE
                vsDependencia  :=  TRIM(SUBSTR(vsLinea, viPosIni, 1));        --md-01     204 orignal
            END IF;

            viPosIni:= 207;                      --md-01     205 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 1))),0) = 0) THEN   --md-01     205 orignal
                vsGDependencia := NULL;
            ELSE
                vsGDependencia  :=  TRIM(SUBSTR(vsLinea, viPosIni, 1));       --md-01     205 orignal
            END IF;
            
            viPosIni:= 208;                      --md-01     206 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 12))),0) = 0) THEN   --md-01     206 orignal
                vsMPCurso := NULL;
            ELSE
                vsMPCurso  :=  TRIM(SUBSTR(vsLinea, viPosIni, 12));            --md-01     206 orignal
            END IF;

            viPosIni:= 220;                      --md-01     218 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 12))),0) = 0) THEN   --md-01     218 orignal
                vsMCurso := NULL;
            ELSE
                vsMCurso  :=  TRIM(SUBSTR(vsLinea, viPosIni, 12));             --md-01     218 orignal
            END IF;
           
            viPosIni:= 232;                      --md-01     230 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 47))),0) = 0) THEN     --md-01     230 orignal
                vsNDirector := NULL;
            ELSE
                vsNDirector  :=  TRIM(SUBSTR(vsLinea, viPosIni, 47));             --md-01     230 orignal
            END IF;
            
            viPosIni:= 279;                      --md-01     277 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 47))),0) = 0) THEN     --md-01     277 orignal
                vsNOrientador := NULL;
            ELSE
                vsNOrientador  :=  TRIM(SUBSTR(vsLinea, viPosIni, 47));          --md-01     277 orignal
            END IF;

            viPosIni:= 326;                      --md-01     324 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 47))),0) = 0) THEN     --md-01     324 orignal
                vsRelacionador := NULL;
            ELSE
                vsRelacionador  :=  TRIM(SUBSTR(vsLinea, viPosIni, 47));         --md-01     324 orignal
            END IF;
            
            viPosIni:= 373;                      --md-01     371 orignal
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 6))),0) = 0) THEN      --md-01     371 orignal
                vsRBD := NULL;
            ELSE
                vsRBD  :=  TRIM(SUBSTR(vsLinea, viPosIni, 6));                    --md-01     371 orignal
            END IF;
            
            --md-03 start
            -- cod eneñanza
            viPosIni:= 379; 
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 3))),0) = 0) THEN   
                vsCodEnsena := NULL;
            ELSE
                vsCodEnsena  :=  TRIM(SUBSTR(vsLinea, viPosIni, 3));                   
            END IF;

            -- pnc   promedio nota colegio
            viPosIni:= 382; 
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 3))),0) = 0) THEN   
                vsPNC := NULL;
            ELSE
                vsPNC  :=  TRIM(SUBSTR(vsLinea, viPosIni, 3));                   
            END IF;            
            
            --pmnc promedio maxio nota colegio 
            viPosIni:= 385; 
            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, viPosIni, 3))),0) = 0) THEN   
                vsPMNC := NULL;
            ELSE
                vsPMNC  :=  TRIM(SUBSTR(vsLinea, viPosIni, 3));                   
            END IF;            
            --md-03 end 
            
            BEGIN
               SELECT COUNT(1) INTO vnExiste 
               FROM  SWBCAUE
               WHERE SWBCAUE_LEDUCACIONAL = vsLEducacional
                 AND SWBCAUE_UEDUCATIVA = vsUEucacional
                 AND SWBCAUE_APROCESO = vsAProceso;
                    
               IF vnExiste = 0 then
                  INSERT INTO SWBCAUE (
                                       SWBCAUE_LEDUCACIONAL, SWBCAUE_UEDUCATIVA, SWBCAUE_APROCESO,
                                       SWBCAUE_NOFICIAL, SWBCAUE_CREGION, SWBCAUE_CPROVINCIA,
                                       SWBCAUE_CCOLUMNA, SWBCAUE_CPOSTAL, SWBCAUE_DDIRECTO,
                                       SWBCAUE_FPRINCIPAL, SWBCAUE_FAX, SWBCAUE_EMAIL,
                                       SWBCAUE_DIRECCION, SWBCAUE_REDUCACIONAL, SWBCAUE_REGIMEN,
                                       SWBCAUE_DEPENDENCIA, SWBCAUE_GDEPENDENCIA, SWBCAUE_MPEN_CURSO,
                                       SWBCAUE_MULT_CURSO, SWBCAUE_NDIRECTOR, SWBCAUE_NORIENTADOR,
                                       SWBCAUE_RELACIONADOR, SWBCAUE_RBD 
                                      ,  SWBCAUE_COD_ENSENANZA,  SWBCAUE_PNC,   SWBCAUE_PMNC          )                 --md-03                                       
                              VALUES ( 
                                       vsLEducacional,  vsUEucacional,  vsAProceso,
                                       vsNOficial,      vsCRegion,      vsCProvincia,
                                       vsCColumna,      vsCPostal,      vsDDirecto,
                                       vsFPrincipal,    vsFax,          vsEmail,
                                       vsDireccion,     vsREducacional, vsRegimen,
                                       vsDependencia,   vsGDependencia, vsMPCurso,
                                       vsMCurso,        vsNDirector,    vsNOrientador,
                                       vsRelacionador,  vsRBD
                                      , vsCodEnsena , vsPNC , vsPMNC  );  --md-03                                        

                              COMMIT;
               --md-04 start
               else 
                    --  actualiza en  general de colegios                    
                    update SWBCAUE set  SWBCAUE_NOFICIAL  = substr(vsNOficial, 1 , 45) ,
                                                    SWBCAUE_CREGION  = vsCRegion ,
                                                    SWBCAUE_CPROVINCIA = vsCProvincia ,
                                                    SWBCAUE_CCOLUMNA = vsCColumna ,
                                                    SWBCAUE_CPOSTAL = vsCPostal ,
                                                    SWBCAUE_DDIRECTO = vsDDirecto ,
                                                    SWBCAUE_FPRINCIPAL = vsFPrincipal ,    
                                                    SWBCAUE_DIRECCION = vsDireccion ,
                                                    SWBCAUE_REDUCACIONAL = vsREducacional ,
                                                    SWBCAUE_GDEPENDENCIA = vsGDependencia ,
                                                    SWBCAUE_NDIRECTOR  = vsNDirector ,
                                                    SWBCAUE_NORIENTADOR   = vsNOrientador                             
                    WHERE SWBCAUE_LEDUCACIONAL = vsLEducacional
                    AND SWBCAUE_UEDUCATIVA = vsUEucacional
                    AND SWBCAUE_APROCESO = vsAProceso; 
                    
                    vs_codigoBann := null; 
                    for cur_CodColegio in (select stvsbgi_code
                                                     from stvsbgi 
                                                     where STVSBGI_FICE =  vsLEducacional || vsUEucacional) loop
                       vs_codigoBann := cur_CodColegio.stvsbgi_code;
                    end loop; 
                    
                    -- nombre                    
                    update stvsbgi set   stvsbgi_desc = substr(vsNOficial, 1,30) 
                    where STVSBGI_FICE =  vsLEducacional || vsUEucacional;
                    
                    -- direccion 
                    vsCODE:= '00'; 
                    vsCODECNTY := '00000';
                    
                   SELECT NVL(STVSTAT_CODE,'00') INTO vsCODE
                   FROM STVSTAT
                   WHERE SUBSTR(STVSTAT_DESC,0,2) = vsCRegion;

                   SELECT NVL(STVCNTY_CODE,'00000') INTO vsCODECNTY
                   FROM STVCNTY
                   WHERE SUBSTR(STVCNTY_DESC,0,5) = vsCColumna;
                                       
                    update  sobsbgi set sobsbgi_street_line1= substr(vsDireccion, 1, 75), 
                                                sobsbgi_street_line2= substr(vsDireccion, 76 , 150) , 
                                                sobsbgi_street_line3 = Null ,
                                                SOBSBGI_CITY =  '000000' ,
                                                SOBSBGI_STAT_CODE = vsCODE,
                                                SOBSBGI_CNTY_CODE = vsCODECNTY,
                                                SOBSBGI_ZIP  = '0',
                                                 SOBSBGI_NATN_CODE = '39'                                                
                    where SOBSBGI_SBGI_CODE = vs_codigoBann; 
                    
                    -- nom colegio
                    update  sorbcmt set  SORBCMT_COMMENT = vsNOficial
                    where SORBCMT_SBGI_CODE = vs_codigoBann ;
                    
                    -- eth                    
                    select count(1) into viValor
                    from sorbeth 
                    where SORBETH_SBGI_CODE = vs_codigoBann
                    and SORBETH_DEMO_YEAR = vsAProceso
                    and SORBETH_ETHN_CODE = vsREducacional;
                                        
                    if viValor = 0 then
                      insert into sorbeth (SORBETH_SBGI_CODE , SORBETH_DEMO_YEAR , SORBETH_ETHN_CODE , SORBETH_ACTIVITY_DATE) 
                                        values
                                                 ( vs_codigoBann, vsAProceso, vsREducacional, sysdate); 
                    end if;  
                    
                    -- dependencia
                    select count(1) into viValor
                    from SORBCHR 
                    where SORBCHR_SBGI_CODE = vs_codigoBann
                    and  SORBCHR_DEMO_YEAR = vsAProceso
                    and SORBCHR_BCHR_CODE = vsGDependencia ;   
                    
                    if viValor = 0 then
                      insert into SORBCHR ( SORBCHR_SBGI_CODE , SORBCHR_DEMO_YEAR , SORBCHR_BCHR_CODE , SORBCHR_ACTIVITY_DATE ) 
                                         values (vs_codigoBann, vsAProceso, vsGDependencia, sysdate) ; 
                    end if; 
                  
                   -- dir - tel director                   
                   if vsNDirector IS NOT NULL THEN
                      
                      select count(1) into viValor 
                      from SORBCNT
                      where SORBCNT_SBGI_CODE = vs_codigoBann
                      and SORBCNT_PTYP_CODE =  'PRIN';
                     
                      if viValor  = 0  then
                          insert into SORBCNT ( SORBCNT_SBGI_CODE ,  SORBCNT_NAME ,  SORBCNT_PTYP_CODE 
                                        ,  SORBCNT_PHONE_AREA , SORBCNT_PHONE_NUMBER , SORBCNT_ACTIVITY_DATE) 
                               values 
                                       ( vs_codigoBann,  vsNDirector,  'PRIN'
                                       ,     vsDDirecto  , vsFPrincipal , sysdate ) ; 
                      else 
                          update SORBCNT set SORBCNT_NAME = vsNDirector
                                                     ,    SORBCNT_PHONE_AREA = vsDDirecto
                                                     ,    SORBCNT_PHONE_NUMBER = vsFPrincipal
                                                     ,    SORBCNT_PHONE_EXT   = null
                                                     , SORBCNT_ACTIVITY_DATE = sysdate
                          where SORBCNT_SBGI_CODE = vs_codigoBann
                          and SORBCNT_PTYP_CODE =  'PRIN'; 
                      end if; 
                                                 
                   END IF;

                   --dir - tel orienta
                   IF vsNOrientador <> vsNDirector THEN
                     
                      IF vsNOrientador IS NOT NULL THEN
                      
                         select count(1) into viValor
                         from SORBCNT
                         where  SORBCNT_SBGI_CODE = vs_codigoBann
                         and  SORBCNT_PTYP_CODE =  'ORIE';
                         
                         if viValor = 0 then 
                           insert into SORBCNT (SORBCNT_SBGI_CODE, SORBCNT_PTYP_CODE, SORBCNT_NAME, SORBCNT_ACTIVITY_DATE)
                                                  values
                                                         ( vs_codigoBann, 'ORIE',  vsNOrientador, sysdate);
                         else 
                            update SORBCNT set SORBCNT_NAME = vsNOrientador
                                                         ,  SORBCNT_PHONE_AREA = null
                                                         ,  SORBCNT_PHONE_NUMBER = null
                                                         ,  SORBCNT_PHONE_EXT = null
                                                         ,  SORBCNT_ACTIVITY_DATE = sysdate                                                         
                            where SORBCNT_SBGI_CODE = vs_codigoBann
                            and SORBCNT_PTYP_CODE =  'ORIE';
                         end if ;  

                      END IF;
                   END IF;

               --md-04 end 
               END IF;
            EXCEPTION
            WHEN OTHERS THEN
                --si llega a pasar algo cucho :'(
                ROLLBACK;
                --Indico el error.  md-01 start
                --p_ImprimeLineaResultado('Error: '||sqlcode || '. '|| replace(sqlerrm,'"','\"'));
                err_msg1 := 'Error: '||sqlcode || '. '|| replace(sqlerrm,'"','\"'); 

                INSERT INTO GWRERRO
                 VALUES(cgsCodApp,psArchivo, err_msg1  , SYSDATE, user   );
                --md-01 end
            END;

        END IF;

        --agrego a la posicion el tanaño del salto de linea \r\n
        --caso paranoico, ver como podriamos ajustar esto para
        --que no quedara en codigo duro y aceptara saltos de linea al estilo
        --unix \n puro.
        vni := vni + 2;
        -- lo puse afuera para evitar ciclos infinitos, pero podría tener
        -- efectos secundarios :s :s :s

    END LOOP;

    EXECUTE IMMEDIATE
            ' SELECT SWBCAUE_LEDUCACIONAL, SWBCAUE_UEDUCATIVA, SWBCAUE_APROCESO, '||
                             '  SWBCAUE_NOFICIAL, SWBCAUE_CREGION, SWBCAUE_CPROVINCIA, '||
                             '  SWBCAUE_CCOLUMNA, SWBCAUE_CPOSTAL, SWBCAUE_DDIRECTO,  '||
                             '  SWBCAUE_FPRINCIPAL, SWBCAUE_FAX, SWBCAUE_EMAIL,  '||
                             '  SWBCAUE_DIRECCION, SWBCAUE_REDUCACIONAL, SWBCAUE_REGIMEN, '||
                             '  SWBCAUE_DEPENDENCIA, SWBCAUE_GDEPENDENCIA, SWBCAUE_MPEN_CURSO, '||
                             '  SWBCAUE_MULT_CURSO, SWBCAUE_NDIRECTOR, SWBCAUE_NORIENTADOR,  '||
                             '  SWBCAUE_RELACIONADOR, SWBCAUE_RBD '||
                             '  , SWBCAUE_COD_ENSENANZA , SWBCAUE_PNC , SWBCAUE_PMNC ' ||
            ' FROM SWBCAUE    '||
            ' WHERE NOT EXISTS (SELECT * FROM STVSBGI WHERE STVSBGI_FICE = SWBCAUE_LEDUCACIONAL||SWBCAUE_UEDUCATIVA ) ' BULK COLLECT 

    INTO ADV_ITEMS;
    
    viNumReg := 0; 
    
    IF ADV_ITEMS IS NOT NULL THEN
       IF ADV_ITEMS.COUNT > 0 THEN
           FOR I IN ADV_ITEMS.FIRST..ADV_ITEMS.LAST LOOP
           
               BEGIN
                   SELECT  TO_CHAR( MAX(STVSBGI_CODE)+1) INTO vnSEQ
                   FROM STVSBGI
                   WHERE  REGEXP_LIKE( STVSBGI_CODE,vsRegularE) 
                     AND  STVSBGI_CODE <> vsWhere1 
                     AND  STVSBGI_CODE <> vsWhere2
                     and  stvsbgi_type_ind = 'H';

                   --    1

                   INSERT INTO STVSBGI (
                         STVSBGI_CODE, STVSBGI_TYPE_IND, STVSBGI_SRCE_IND,
                         STVSBGI_DESC, STVSBGI_ACTIVITY_DATE, STVSBGI_ADMR_CODE,
                         STVSBGI_EDI_CAPABLE, STVSBGI_FICE, STVSBGI_VR_MSG_NO,
                         STVSBGI_DISP_WEB_IND)
                   VALUES ( vnSEQ, 'H', NULL,
                         SUBSTR(ADV_ITEMS(I).R_NOFICIAL,0,30), SYSDATE, NULL,
                         NULL, ADV_ITEMS(I).R_LEDUCACIONAL||ADV_ITEMS(I).R_UEDUCATIVA, NULL,
                         NULL); 
                         
                    COMMIT;

                   SELECT NVL(STVSTAT_CODE,'00') INTO vsCODE
                   FROM STVSTAT
                   WHERE SUBSTR(STVSTAT_DESC,0,2) = ADV_ITEMS(I).R_CREGION;

                   SELECT NVL(STVCNTY_CODE,'00000') INTO vsCODECNTY
                   FROM STVCNTY
                   WHERE SUBSTR(STVCNTY_DESC,0,5) = ADV_ITEMS(I).R_CCOLUMNA;

                   --  2
                   INSERT INTO SOBSBGI (
                        SOBSBGI_SBGI_CODE, SOBSBGI_STREET_LINE1, SOBSBGI_STREET_LINE2,
                        SOBSBGI_STREET_LINE3, SOBSBGI_CITY, SOBSBGI_STAT_CODE,
                        SOBSBGI_CNTY_CODE, SOBSBGI_ZIP, SOBSBGI_NATN_CODE,
                        SOBSBGI_ACTIVITY_DATE)
                   VALUES ( vnSEQ, SUBSTR(ADV_ITEMS(I).R_DIRECCION,0,30), SUBSTR(ADV_ITEMS(I).R_DIRECCION,31,51),
                        NULL,  '000000',  vsCODE,
                        vsCODECNTY,  '0', '39',
                        SYSDATE); 
                        
                   COMMIT;

                   --  3
                   SELECT NVL(TO_CHAR( MAX(SORBCMT_SEQNO)+1),'N') INTO vnSEQCMT
                   FROM SORBCMT
                   WHERE  SORBCMT_SBGI_CODE = ADV_ITEMS(I).R_LEDUCACIONAL||ADV_ITEMS(I).R_UEDUCATIVA;

                   INSERT INTO SORBETH (
                        SORBETH_SBGI_CODE, SORBETH_DEMO_YEAR, SORBETH_ETHN_CODE,
                        SORBETH_ETHN_PERCENT, SORBETH_ACTIVITY_DATE)
                   VALUES ( vnSEQ,  ADV_ITEMS(I).R_APROCESO, ADV_ITEMS(I).R_REDUCACIONAL,
                        NULL, SYSDATE);

                   --  9
                   INSERT INTO SORBCHR (
                        SORBCHR_SBGI_CODE,  SORBCHR_DEMO_YEAR, 
                        SORBCHR_BCHR_CODE,  SORBCHR_ACTIVITY_DATE)
                   VALUES ( vnSEQ,     ADV_ITEMS(I).R_APROCESO,
                        ADV_ITEMS(I).R_GDEPENDENCIA,  SYSDATE);

                   --insert into dos values ('problema dependencia',vnSEQ||''||ADV_ITEMS(I).R_APROCESO||ADV_ITEMS(I).R_GDEPENDENCIA);

                   IF vnSEQCMT = 'N' THEN

                       INSERT INTO SORBCMT (
                           SORBCMT_SBGI_CODE, SORBCMT_SEQNO, 
                           SORBCMT_COMMENT,   SORBCMT_ACTIVITY_DATE)
                       VALUES ( vnSEQ,      1,
                           ADV_ITEMS(I).R_NOFICIAL, SYSDATE ); 
                       COMMIT;

                   ELSE

                       INSERT INTO SORBCMT (
                            SORBCMT_SBGI_CODE, SORBCMT_SEQNO, 
                            SORBCMT_COMMENT,   SORBCMT_ACTIVITY_DATE)
                       VALUES (  vnSEQ,       vnSEQCMT,
                            ADV_ITEMS(I).R_NOFICIAL,  SYSDATE );
                       COMMIT;

                   END IF;

                   --  4
                   IF ADV_ITEMS(I).R_NDIRECTOR IS NOT NULL THEN

                      INSERT INTO SORBCNT (
                           SORBCNT_SBGI_CODE, SORBCNT_NAME, SORBCNT_PTYP_CODE,
                           SORBCNT_PHONE_AREA, SORBCNT_PHONE_NUMBER, SORBCNT_PHONE_EXT,
                           SORBCNT_ACTIVITY_DATE)
                       VALUES (  vnSEQ, ADV_ITEMS(I).R_NDIRECTOR, 'PRIN',
                           ADV_ITEMS(I).R_DDIRECTO,  ADV_ITEMS(I).R_FPRINCIPAL, NULL,
                           SYSDATE);
                   END IF;

                   --  5
                   IF ADV_ITEMS(I).R_NORIENTADOR <> ADV_ITEMS(I).R_NDIRECTOR THEN

                      IF ADV_ITEMS(I).R_NORIENTADOR IS NOT NULL THEN
                          INSERT INTO SORBCNT (
                               SORBCNT_SBGI_CODE, SORBCNT_NAME, SORBCNT_PTYP_CODE,
                               SORBCNT_PHONE_AREA, SORBCNT_PHONE_NUMBER, SORBCNT_PHONE_EXT,
                               SORBCNT_ACTIVITY_DATE)
                          VALUES ( 
                               vnSEQ, ADV_ITEMS(I).R_NORIENTADOR, 'ORIE',
                               NULL,  NULL,  NULL,
                               SYSDATE);
                      END IF;
                   END IF;
                   
                   --  6
                   IF ADV_ITEMS(I).R_NORIENTADOR <> ADV_ITEMS(I).R_RELACIONADOR  THEN
                      IF ADV_ITEMS(I).R_RELACIONADOR IS NOT NULL THEN
                         INSERT INTO SORBCNT (
                              SORBCNT_SBGI_CODE, SORBCNT_NAME, SORBCNT_PTYP_CODE,
                              SORBCNT_PHONE_AREA, SORBCNT_PHONE_NUMBER, SORBCNT_PHONE_EXT,
                              SORBCNT_ACTIVITY_DATE)
                          VALUES (  
                              vnSEQ, ADV_ITEMS(I).R_RELACIONADOR, 'RELA',
                              NULL,  NULL,  NULL,
                              SYSDATE);
                      END IF;
                   END IF;
                   
                  --  7
                  --          INSERT INTO SORBDMO (
                  --          SORBDMO_SBGI_CODE, SORBDMO_DEMO_YEAR, SORBDMO_ENROLLMENT,
                  --          SORBDMO_NO_OF_SENIORS, SORBDMO_MEAN_FAMILY_INCOME, SORBDMO_PERC_COLLEGE_BOUND,
                  --          SORBDMO_ACTIVITY_DATE)
                  --          VALUES ( vnSEQ,
                  --          ADV_ITEMS(I).R_APROCESO,
                  --          ADV_ITEMS(I).R_MULT_CURSO,
                  --          ADV_ITEMS(I).R_MPEN_CURSO,
                  --          NULL,
                  --          NULL,
                  --          SYSDATE);
                  --  8


                   COMMIT;
               EXCEPTION
               WHEN OTHERS THEN
                 --INSERT INTO DOS VALUES ('ERROR', 'ERROR');
                     --si llega a pasar algo cucho :'(
                   --Indico el error.  md-01 start
                  err_msg1 := 'Error: '||sqlcode || '. '|| replace(sqlerrm,'"','\"'); 
                
                  INSERT INTO GWRERRO
                  VALUES(cgsCodApp,psArchivo, err_msg1  , SYSDATE, user   );
                       
                  -- p_ImprimeLineaResultado('Error: '||sqlcode || '. '|| replace(sqlerrm,'"','\"')); md-01 end
               END;
               
               -- md-01 start
               err_msg1 := ADV_ITEMS(I).R_LEDUCACIONAL || ' ' ||  ADV_ITEMS(I).R_UEDUCATIVA ; 
               err_msg1 := err_msg1 || ' ' || ADV_ITEMS(I).R_APROCESO || ' ' ||  ADV_ITEMS(I).R_NOFICIAL;
                          
               insert into twraacp values ( cgsCodApp, vnNumProcCarga, I, err_msg1 , 'A' , null, sysdate, vgsUSR);
                 
               --md-01 end 
               
           END LOOP;

       END IF;
    END IF;
    
    vgsUsr := NVL(vgsUSR,USER);
    
    -- md-01 start
    
    INSERT INTO GWBAACR (  GWBAACR_NOMBRE_ARCHIVO     ,GWBAACR_TIPO
                          ,GWBAACR_NUM_REGISTROS      ,GWBAACR_TAMANO
                          ,GWBAACR_HASH_SHA1          ,GWBAACR_NUM_PROCESO
                          ,GWBAACR_ACTIVITY_DATE      ,GWBAACR_USER
                  )VALUES(
                          psArchivo                   ,cgsCodApp
                         ,vnNumLineas                 ,vnTamano
                         ,vrDigestionSHA1             ,vnNumProcCarga
                         ,SYSDATE                     ,vgsUSR  );

     commit; 
     
     --md-01 end


    --Indico al usuario que ya termine
    --p_ImprimeLineaResultado('Procesamiento del archivo terminado.');

END p_Carga;

/******************************************************************************
PROCEDIMIENTO:      p_ImprimeLineaResultado
OBJETIVO:           Genera una linea con el mensaje y/o HTML indicado en la
                    pagina de resultados
PARAMETROS:
psLinea             Mensaje y/o HTML a mostrar
******************************************************************************/
PROCEDURE p_ImprimeLineaResultado(
    psLinea             VARCHAR2
) IS
BEGIN
    DBMS_OUTPUT.PUT_LINE(psLinea);
END p_ImprimeLineaResultado;


FUNCTION  isdate (p_inDate VARCHAR2) RETURN DATE  AS
    v_dummy DATE;
        --manejo de errores
    vsFecha   VARCHAR2(10) := '';

 BEGIN

    IF (p_inDate IS NOT NULL) THEN
        IF (LENGTH(p_inDate) = 8) THEN
            vsFecha := substr('05112009',1,2) ||'/'|| substr('05112009',3,2)||'/'|| substr('05112009',5,4);

            SELECT  TO_DATE(vsFecha,'DD/MM/YYYY')
            INTO v_dummy
            FROM DUAL;

            return v_dummy;
        END IF;
    END IF;
    RETURN sysdate;
 EXCEPTION
     WHEN OTHERS
        THEN RETURN sysdate;
 END  isdate;

END pk_CargaCCP_Nv;
/

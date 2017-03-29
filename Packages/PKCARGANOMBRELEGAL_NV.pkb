CREATE OR REPLACE PACKAGE BODY BANINST1.pkCargaNombreLegal_NV  IS
--CREATE OR REPLACE PACKAGE BODY BANINST1.pkCaeCargaFianzaOficialIngresa IS


/******************************************************************************
PAQUETE:            BANINST1.pkCargaNombreLegal_NV
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos con nombres legales
AUTOR:              Roman Ruiz
FECHA:              19 jun 2014
*********************************
modificacion         md-01
objetivo            desplegar ruts que no exiten.
autor               roman ruiz
fecha               05-ago-2014
*********************************
modificacion         md-02
objetivo            se hacen adecuaciones a nuevo metodo de carga
autor               roman ruiz
fecha               28-jul-2015
------------------------
mod   md-03
Obj     se hacen las modificaciones necesarias para el nuevo sistema de cargas de archivos
autor   roman ruiz
date  8-feb-2016

******************************************************************************/

    --variable para seguridad GWAMNUR
    vgsUSR              VARCHAR2(500);
    global_aidm         SABNSTU.SABNSTU_AIDM%TYPE;
    global_id           SABNSTU.SABNSTU_ID%TYPE;
    cgsCodApp           CONSTANT VARCHAR2(4) := 'CNLG';   -- CARGA NOMBRE LEGAL
    vsNomSeq            VARCHAR2(50);
    cgsErr20408         CONSTANT VARCHAR2(200) := 'No esta configurado el Año para proceso CAE';
    cnRoundNum          constant number(1) := 4;     -- decimales a redondear
    csSepara            constant char(1) := ',';


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

    vsCampo    VARCHAR2(200);
    vnCantidad  number(12,4) := 0;
    viNumReg    number;
    vsYEAR                varchar2(4);
    vsFileSeq             number(6);
    vsSeqNum              number(6);
    vsRut                 varchar2(15);
    vsDv                  varchar2(5);
    vsNombre              varchar2(200);
    vsError         char(1);
    vsLoad_stat     varchar2(100);
    vsStatusCaeJ    varchar2(4);
    vsStatusCaeH    varchar2(4);

    --vsNameArchivo   varchar2(300);  --md-02

    vsalida                 VARCHAR2(3000);      --md-03  start
    vsNameArchivo     varchar2(300);   
    vsArchExitente      varchar2(300);    
     vsArchExSize       number(10):= 0;
     vrArchivoExBlob   BLOB;
     viArchVivo           number(4) := 0;            

     cursor ArchExistente   is 
                  SELECT   NAME  ,    DOC_SIZE    , BLOB_CONTENT
                  -- from SWBFOTO   --md-x
                  from   GWBDOCS
                  WHERE NAME like  vsNameArchivo
                  order by LAST_UPDATED desc;
     
     --md-03 end         
    
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
      
      -- existe archivo , se marca en bitacora de error , y borro archivo de foto y paro el proceso       
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
     
     for cur_doc in (SELECT DOC_SIZE ,BLOB_CONTENT
                            FROM GWBDOCS
                            WHERE NAME like  vsNameArchivo
                            order by last_updated desc ) loop

        vnTamano      := cur_doc.DOC_SIZE;
        vrArchivoBLOB := cur_doc.BLOB_CONTENT;
        exit;

     end loop;      
 
-- --md-02 start
--     INSERT INTO  GWBDOCS(
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
--
--    --obtengo los datos del archivo
--
--    Select  DOC_SIZE, BLOB_CONTENT  INTO  vnTamano,  vrArchivoBLOB
--    FROM   GWBDOCS
--    WHERE  NAME like vsNameArchivo
--    AND TRUNC(LAST_UPDATED)  = TRUNC(SYSDATE);

    -- WHERE  NAME = psArchivo;

    --calculo la firma SHA1 del archivo
    vrDigestionSHA1 := DBMS_CRYPTO.HASH(vrArchivoBLOB,DBMS_CRYPTO.HASH_SH1);

    --Muestro los datos del archivo
    --p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
    --p_ImprimeLineaResultado ('Tamaño de archivo: ' || vnTamano);
    --p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);

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
--    IF vsExiste = 'Y' THEN
--        -- Eliminar el archivo recien subido
--        DELETE GWBDOCS
--        WHERE  NAME like  vsNameArchivo;
--
--        --WHERE  NAME = psArchivo;
--
--        COMMIT;
--
--        --Informo al usuario.
--
--        INSERT INTO GWRERRO VALUES (cgsCodApp,psArchivo ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);
--        commit;

--        p_ImprimeLineaResultado ( 'Este archivo ya se había subido anteriormente.');
--        p_ImprimeLineaResultado (  'Usuario: '||vsUserAnt||'. Fecha y Hora: '
--                                   ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.'  );
--        p_ImprimeLineaResultado ('No se procesara .');

--        RETURN;
--    END IF;

--     vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');

    --Obtengo Numero de secuencia de archivo
--     vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);

--    vgsUsr := NVL(vgsUSR,USER);

    --Imprimo el numero de proceso
    --p_ImprimeLineaResultado ('Número de proceso: ' || vnNumProcCarga);
    
    --md-03  end 

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
              --RUT;NOMBRES
               -- Variabla para determinar Errores   E = (sin rut no continua)  e = solo falta de dato
               vsError     := null ;
               -- Campo en donde se dio el error.
               vsLoad_stat := null ;
             /* campos solicitados
             rut, nombre
             */

             --  campo1 - vsRut
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,1, csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                   vsCampo := NULL;
                   vsError := 'E';
                   vsLoad_stat := '1';
               ELSE
                   vsCampo :=  TRIM(vsCampo);
               END IF;
               vsRut := vsCampo;

             -- campo2 - vsNombre
               vsCampo :=  pk_UtilCrgEnvArch.f_ExtraeCampo(vsLinea,2, csSepara);
               IF (NVL(LENGTH(TRIM(vsCampo)),0) = 0) THEN
                    vsCampo := NULL;
                     if vsError is null then
                        vsError := 'E';
                     end if ;
                     vsLoad_stat := vsLoad_stat || ' 2';
               ELSE
                    vsCampo :=  trim(substr(vsCampo,1,200));
               END IF;
               vsCampo := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(vsCampo,'~aacute','&aacute'),'~eacute','&eacute'),'~iacute','&iacute'),'~oacute','&oacute'),'~uacute','&uacute');
               vsNombre := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(replace(vsCampo,'~aacute','&aacute'),'~eacute','&eacute'),'~iacute','&iacute'),'~oacute','&oacute'),'~uacute','&uacute')  ,'~AACUTE','&Aacute'),'~EACUTE','&Eacute'),'~IACUTE','&Iacute'),'~OACUTE','&Oacute'),'~Uacute','&Uacute'),'Ã±','ñ');
               -- BEGIN
               if vsError = 'e' or vsError is null then

                  --saco del dv del rut.
                  vsDv := substr(vsRut, instr(vsRut,'-')+ 1 ,1);

                  vnNumLineas := vnNumLineas + 1;

                  -- md-01 start

                  select count(*) into err_num1
                  from spbpers
                  where SPBPERS_NAME_SUFFIX = vsRut;

                  if err_num1 > 0 then

                    update spbpers set SPBPERS_LEGAL_NAME =   vsNombre,
                                       SPBPERS_ACTIVITY_DATE = sysdate
                    where SPBPERS_NAME_SUFFIX = vsRut;

                  --else
                  --    p_ImprimeLineaResultado ('Linea ' || vnBitacoraSeq || ' No se encontro el Rut : ' || vsRut);
                  end if ;

                  -- md-01 end

                  if vnBitacoraSeq >= 500 then
                     vnBitacoraSeq := 0;
                     COMMIT;
                  end if;

                  vnBitacoraSeq := vnBitacoraSeq + 1;

                  insert into twraacp values ( cgsCodApp, vnNumProcCarga, vnNumLineas, vsRut || '-' || vsDv , 'A' , null, sysdate, vgsUSR);  --md-05

               else

                 vsLoad_stat := 'faltan campos ' || vsLoad_stat;

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
                           ,viNumReg
                           ,vnTamano
                           ,vrDigestionSHA1
                           ,vnNumProcCarga
                           ,SYSDATE
                           ,vgsUSR  );

      commit;
  --  vgsUsr := NVL(vgsUSR,USER);
    --Indico al usuario que ya termine
   -- p_ImprimeLineaResultado('Proceso del Actualizacionn Nombres Legales Finalizado.');

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

END pkCargaNombreLegal_NV ;
/
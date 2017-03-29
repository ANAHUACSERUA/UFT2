CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaBChile_Nv IS
/******************************************************************************
PAQUETE:   BANINST1.pk_CargaBChile
OBJETIVO:   Contiene los procedimientos, funciones y variables
     requeridos para la carga de archivos de rendición del
     Banco de Chile
AUTOR:    Gilberto Velazquez Hernandez
FECHA:    20111222
---
modificacion    - md-01
objetivo        cambio de posiciones del layout  por lo que hacen ajustes a posiciones
autor           roman ruiz
fecha            04-jul-2014
---
modificacion    - md-02
objetivo        cambio de posiciones del contrato
autor           roman ruiz
fecha            24-jul-2014
-----------------------------
modificacion    - md-03
objetivo        se cambia leyenda de warning.
autor           roman ruiz
fecha           05-ago-2014

-----------------------------
modificacion    - md-04
objetivo        se cambia leyenda de warning.
autor           roman ruiz
fecha           02-feb-2016

-----------------------------
modificacion    - md-05
autor  :   roman ruiz
accion :   Cambio de procedimiento de p_pagardocu
Fecha  :   07-sep-2016

-----------------------------
modificacion    - md-06
autor  :   roman ruiz
accion :   aplica fecha de pago en le campo twbdocu_pay_day
Fecha  :   22-sep-2016

----------------------------
Modificación :    md-07
Autor  :   Roman ruiz
Acción :   Agregar parametro fecha 
Fecha  :   26-oct-2016 


******************************************************************************/

 --Codigo global de la aplicacion
 cgsCodApp   CONSTANT VARCHAR2(4) := 'CBCH';
 
 cgsCodCarga          constant varchar2(3) := 'BCH';   --md-05

 --Variable global para guardar el usuario
 vgsUsr    VARCHAR2(30) := NULL;

--prototipos de Funciones y procedimientos privados
--veasé el cuerpo del procedimiento/funcion para mayor info
PROCEDURE p_InicioPaginaResultado;

PROCEDURE p_ImprimeLineaResultado(
 psLinea    VARCHAR2
);

PROCEDURE p_CierrePaginaResultado;

PROCEDURE p_ProcesaEncabezado(
 psLinea    VARCHAR2
 ,pnNumDocs   NUMBER
 ,pnMontoA   NUMBER
 ,psRes  IN OUT VARCHAR2
 ,psMsg  IN OUT VARCHAR2
);
PROCEDURE p_ProcesaRegistro(  psLinea     IN  VARCHAR2
                             ,pnMontoR    IN OUT NUMBER
                             ,psRes       IN OUT VARCHAR2
                             ,psMsg       IN OUT VARCHAR2
                             ,pdOverdate  in     date
                            );

PROCEDURE p_AplicaPago(
 pnNumSeqDoc   NUMBER
 ,pnMontoInt   NUMBER
 ,pdFecha IN  DATE
 ,psRes  IN OUT VARCHAR2
 ,psMsg  IN OUT VARCHAR2
);
--fin de prototipos privados


/******************************************************************************
PROCEDIMIENTO:  p_Carga
OBJETIVO:   Procesa un archivo de rendición PEC para que los pagos
     indicados en el mismo sean transferidos al estado de cuenta
     de los alumnos
PARAMETROS:
psArchivo   Nombre con que fue guardado el archivo cargado
     por el usuario.
******************************************************************************/
PROCEDURE p_Carga(
                   psArchivo   VARCHAR2
                  ,psUser    VARCHAR2 DEFAULT USER
                  ,psfecha          varchar2      -- md-07
                   ) IS

 --Guarda la Firma SHA1 del archivo
 vrDigestionSHA1  RAW(20);
 --Guarda el tamaño del archivo
 vnTamano   NUMBER(10);
 --El archivo en sí, formato BLOB:
 vrArchivoBLOB  BLOB;
 --El archivo en sí, formato CLOB:
 vsArchivoCLOB  CLOB;
 --Variable para verificar que exista el archivo
 vbExiste   BOOLEAN;
 --Variable de contador para ver en que posicion estamos del archivo
 vni     PLS_INTEGER;
 --Variable de contador de lineas
 vnNumLineas   PLS_INTEGER;
 --Variable temporal para ver cual es el tamaño de la linea
 vnTamLinea   PLS_INTEGER;
 --Variable para guardar la linea en si
 vsLinea    VARCHAR2(4000);
 --Variable de resultado del proceso del registro
 vsStatus   VARCHAR2(1);
 --Variable de resultado del proceso del registro
 vsMensajeProc  VARCHAR2(4000);
 --Variable para guardar el monto recaudado total (calculado)
 vnMontoTotal  NUMBER(14,2);
 --Variable para guardar el monto del registro (extraido)
 vnMontoReg  NUMBER(14,2);
 --Variable para guardar el numero de proceso de carga de archivo
 vnNumProcCarga  PLS_INTEGER;
 --variable para el usuario que habia cargado este archivo previamente
 vsUserAnt   GWBAACR.GWBAACR_USER%TYPE;
 --variable para la fecha en que se habia cargado este archivo previamente
 vdFechaAnt   GWBAACR.GWBAACR_ACTIVITY_DATE%TYPE;
 --Secuencia de donde se extraerá el número de ejecución
 vsNomSeq   VARCHAR2(30);
 --Linea de encabezado
 vsLineaEnc   VARCHAR2(4000);
 --Variable para guardar la salida del registro.
 vsMsg    VARCHAR2(4000);

 --Variable para guardar el BOM de utf-8
 vrBOMUTF8   RAW(3) := HEXTORAW('EFBBBF');
 --variable para extraer los 3 primeros bytes del blob
 vrTmp    RAW(3);
 --blob temporal sin el BOM
 vrBlobUTF   BLOB;
 --variable para guardar el tamaño del CLOB
 vnTamanoCLOB  NUMBER(10);

     vsalida                VARCHAR2(3000);      --md-04  start
    vsNameArchivo     varchar2(300);
    vsArchExitente      varchar2(300);
     vsArchExSize       number(10):= 0;
     vrArchivoExBlob   BLOB;
     viArchVivo           number(4) := 0;
     
     vdOverDate           date;           -- md-07 

     cursor ArchExistente   is
                  SELECT   NAME  ,    DOC_SIZE    , BLOB_CONTENT
                  -- from SWBFOTO   --md-x
                  from   GWBDOCS
                  WHERE NAME like  vsNameArchivo
                  order by LAST_UPDATED desc;

     --md-04 end

 --Cursor para obtener el archivo
 CURSOR cuArch(psArchivo VARCHAR2) IS
  SELECT DOC_SIZE     AS Tamaño
        ,BLOB_CONTENT    AS Contenido
  FROM  GWBDOCS
  WHERE  NAME = psArchivo;

 --Cursor para verificar que el archivo no se haya cargado antes
 CURSOR cuExiste( pnTamano  NUMBER
                 ,prDigSHA1  RAW ) IS
  SELECT GWBAACR_ACTIVITY_DATE  AS Fecha
        ,GWBAACR_USER    AS Usuario
  FROM GWBAACR
  WHERE GWBAACR_TAMANO = pnTamano
   AND GWBAACR_HASH_SHA1 = prDigSHA1;


BEGIN

    -- md-07 start
    
    if psfecha is not null then 
    
       vdOverDate :=  TO_DATE(psfecha,'DD/MM/YYYY');
    else
       vdOverDate :=  null; 
    end if;
    
     --md-07 end 

    --Inicio del reporte
   --  p_InicioPaginaResultado;   --md-04 start

    --Obtengo el nombre de la secuencia de los parametros de la aplicacion
    vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');

    --Obtengo Numero de secuencia de archivo
    vnNumProcCarga := pk_Util.f_NumSec(vsNomSeq);

    vsNameArchivo := '%'||substr(psArchivo,instr(psArchivo,'/') + 1)||'%';
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

           insert into twraacp values ( cgsCodApp, vnNumProcCarga, 1, 'Arch Repetido ' || psArchivo , 'X' , 'Archivo_Repetido', sysdate, vgsUSR);

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
--    OPEN cuArch(psArchivo);
--        FETCH cuArch INTO vnTamano , vrArchivoBLOB ;
--    CLOSE cuArch;

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

--    --Muestro los datos del archivo
--    p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
--    p_ImprimeLineaResultado ('Tamaño de archivo: ' || vnTamano);
--    p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);

--    --busco que no se haya subido antes este mismo archivo
--    OPEN cuExiste(vnTamano, vrDigestionSHA1);
--         FETCH cuExiste INTO vdFechaAnt ,vsUserAnt;
--         vbExiste := cuExiste%FOUND;
--    CLOSE cuExiste;

    --Si existió el archivo indico que no se puede volver a subir este mismo archivo
--    IF vbExiste THEN
--       --Elimino el archivo recien subido
--       DELETE GWBDOCS
--       WHERE NAME = psArchivo;
--
--       --confirmo la eliminación
--       COMMIT;
--
--       --Informo al usuario.
--       p_ImprimeLineaResultado ('Este archivo ya se había subido anteriormente.');
--       p_ImprimeLineaResultado ( 'Usuario: '||vsUserAnt||'. Fecha y Hora: '  ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.' );
--       p_ImprimeLineaResultado ('No se procesará.');
--
--       --cierro la pagina
--       p_CierrePaginaResultado;
--
--       --No tiene mucho caso seguir aqui adentro :p
--       RETURN;
--    END IF;

    --Imprimo el numero de proceso
--    p_ImprimeLineaResultado ('Número de proceso: ' || vnNumProcCarga);

    --Si sigo aqui es que el archivo existe, procedo a convertir BLOB a CLOB
    --Ojo el Banco de chile esta mandando la combinación mas extraña
    --que haya visto, UTF-8 con saltos de linea MAC (a parte con BOM si hay
    --caracteres Unicode y sin BOM cuando todo entra en ASCII, wtf!!!

    --Para detectar primero que version es, tengo que extraer los primeros 3
    --bytes del blob y ver si es corresponden al BOM de UTF-8
    vrTmp := DBMS_LOB.SUBSTR(vrArchivoBLOB,3,1);

    --Si los tres primeros bytes corresponden aL BOM
    IF UTL_RAW.COMPARE(vrTmp, vrBOMUTF8) = 0 THEN
        --Copio el BLOB a otro descartando los 3 primeros bytes que
         --corresponden al BOM
       DBMS_LOB.CREATETEMPORARY(vrBlobUTF,true);
       DBMS_LOB.COPY( vrBlobUTF ,vrArchivoBLOB ,DBMS_LOB.GETLENGTH(vrArchivoBLOB)-3 ,1 ,4 );

       --Aqui convierto el nuevo BLOB en CLOB
       vsArchivoCLOB := pk_UtilCrgEnvArch.f_BLOBaCLOB(vrBlobUTF,'AL32UTF8');
    ELSE
       --Si no encontró el BOM asumo que es la codificación estandar ISO-8859-1
        vsArchivoCLOB := pk_UtilCrgEnvArch.f_BLOBaCLOB(vrArchivoBLOB);
    END IF;

    --Convierto los saltos de linea de mac a dos
    pk_UtilCrgEnvArch.p_ConvSaltoLineaMacDos(vsArchivoCLOB);

    --asigno el usuario a vgsUser
    vgsUsr := psUser;

    --comienzo a extraer las lineas del archivo
    vni := 1;
    vnNumLineas := 0;
    vnMontoTotal := 0.0;
    vnTamanoCLOB := DBMS_LOB.GETLENGTH(vsArchivoCLOB);

    WHILE vni <= vnTamanoCLOB LOOP
        --Limpiamos el mensaje
       vsMsg := '';
       vsMensajeProc := '';
       --Limpiamos el resultado
       vsStatus := '';

       --Extraemos una linea
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

          --aqui debería empieza el procesamiento de afectación
          IF vnNumLineas = 1 THEN
              --si es la primera linea la guardo para procesarla al final!!!
              vsLineaEnc := vsLinea;

              --Ojo, establezco la posicion de lectura en la siguiente
              --linea (leer abajo el caso general)
              vni := vni + 2;

              --Lo bueno de oracle 11g es que ya existe el continue  jojojojojo
              CONTINUE;

          ELSE
              --Limpio el monto del registro
              vnMontoReg := 0;

              --si no es la primera linea forzosamente es un registro
              p_ProcesaRegistro(vsLinea, vnMontoReg, vsStatus, vsMensajeProc , vdOverDate);

              --sumo el monto
              vnMontoTotal := vnMontoTotal + vnMontoReg;

          END IF;

          --Agrego el numero de linea al archivo
          vsMsg := 'Num Linea: '||vnNumLineas||'. ';
          --En base al estatus mando el mensaje de salida
          CASE vsStatus
                   WHEN 'A' THEN  vsMsg:=vsMsg||'Registro Correcto: ';
                   WHEN 'W' THEN  vsMsg:=vsMsg||'Advertencia: ';
                   WHEN 'R' THEN  vsMsg:=vsMsg||'Registro no procesado: ';
                   WHEN 'E' THEN  vsMsg:=vsMsg||'Error: ';
          END CASE;

          --Agrego la salida del proceso
          vsMsg:=vsMsg||vsMensajeProc;
          --p_ImprimeLineaResultado(vsMsg);

          --Guardar registro en tabla de auditoria
          INSERT INTO TWRAACP( TWRAACP_FILE_TYPE
                       ,TWRAACP_FILE_NUM
                       ,TWRAACP_RECORD_NUM
                       ,TWRAACP_RECORD
                       ,TWRAACP_RESULT
                       ,TWRAACP_MSG
                       ,TWRAACP_ACTIVITY_DATE
                       ,TWRAACP_USER
                   )VALUES(
                       cgsCodApp
                       ,vnNumProcCarga
                       ,vnNumLineas
                       ,vsLinea
                       ,vsStatus
                       ,vsMsg
                       ,SYSDATE
                       ,psUser );

       END IF;

      --agrego a la posicion el tanaño del salto de linea \r\n
      --caso paranoico, ver como podriamos ajustar esto para
      --que no quedara en codigo duro y aceptara saltos de linea al estilo unix \n puro.
      vni := vni + 2;
      -- lo puse afuera para evitar ciclos infinitos, pero podría tener
      -- efectos secundarios :s :s :s

   END LOOP;

    --Proceso el encabezado
    --Limpiamos el mensaje
    vsMsg := '';
    vsMensajeProc := '';
    --Limpiamos el resultado
    vsStatus := '';

    p_ProcesaEncabezado(  vsLineaEnc ,vnNumLineas-1 ,vnMontoTotal ,vsStatus ,vsMensajeProc );

    --Agrego el numero de linea al mensaje de salida
    vsMsg := 'Num Linea: 1. ';
    --En base al estatus mando el mensaje de salida
    CASE vsStatus
       WHEN 'A' THEN  vsMsg:=vsMsg||'Registro Correcto: ';
       WHEN 'W' THEN  vsMsg:=vsMsg||'Advertencia: ';
       WHEN 'R' THEN  vsMsg:=vsMsg||'Registro no procesado: ';
       WHEN 'E' THEN  vsMsg:=vsMsg||'Error: ';
    END CASE;

    --Agrego la salida del proceso
    vsMsg:=vsMsg||vsMensajeProc;
    --p_ImprimeLineaResultado(vsMsg);

    --Guardar registro en tabla de auditoria
    INSERT INTO TWRAACP(  TWRAACP_FILE_TYPE
                         ,TWRAACP_FILE_NUM
                         ,TWRAACP_RECORD_NUM
                         ,TWRAACP_RECORD
                         ,TWRAACP_RESULT
                         ,TWRAACP_MSG
                         ,TWRAACP_ACTIVITY_DATE
                         ,TWRAACP_USER
                  )VALUES(
                         cgsCodApp
                        ,vnNumProcCarga
--                        ,1
                        , vnNumLineas +1
                         ,vsLineaEnc
                         ,vsStatus
                         ,vsMsg
                         ,SYSDATE
                         ,psUser  );

    --si llegamos aqui todo debería estar nice :)
    --Guardo los datos del archivo en la tabla de auditoria
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
                         ,vnNumLineas
                         ,vnTamano
                         ,vrDigestionSHA1
                         ,vnNumProcCarga
                         ,SYSDATE
                         ,psUser  );

    COMMIT;

    --Indico al usuario que ya termine
    --p_ImprimeLineaResultado('Procesamiento del archivo terminado.');
    --cierro la pagina
    --p_CierrePaginaResultado;

EXCEPTION
    WHEN OTHERS THEN
     --si llega a pasar algo cucho :'(
      ROLLBACK; --ROLLBACK!!
     --Indico el error.
    --  p_ImprimeLineaResultado('Error: '||sqlcode || '. '  || replace(sqlerrm,'"','\"'));
     --Cierro la pagina
      --p_CierrePaginaResultado;
END p_Carga;

/******************************************************************************
PROCEDIMIENTO:  p_ProcesaEncabezado
OBJETIVO:   Procesa y verifica que el registro de encabezado (primer
     renglon) del archivo de rendición PEC sea válido.
PARAMETROS:
psLinea:   Linea de texto a procesar como archivo de encabezado
pnNumDocs   Numero de documentos que existian en el archivo
pnMontoA:   Monto total calculado del cuerpo del archivo
psRes:    Parametro de salida, guarda el resultado del procesamiento:
     A - Aprobado/Aplicado, R - Rechazado
     W - Aplicado con advertencias, E - Error
psMsg:    Parametro de salida, Mensaje de resultado de la operacion
******************************************************************************/
PROCEDURE p_ProcesaEncabezado(
 psLinea    VARCHAR2
 ,pnNumDocs   NUMBER
 ,pnMontoA   NUMBER
 ,psRes  IN OUT VARCHAR2
 ,psMsg  IN OUT VARCHAR2
) IS

 --Longitud del registro
 vnTamano   PLS_INTEGER;
 --Variable temporal
 vsTemp    VARCHAR2(130);
 --RUT de la Universidad + digito verificador
 --Sin guion y relleno con ceros a la izquierda longitud 10
 vsRutUFT   VARCHAR2(10);

BEGIN

    --Obtengo el rut de la uft
    vsRutUFT := pk_Util.f_ObtieneParam(cgsCodApp,'RUT_UFT');

    --obtengo tamaño del registro:
--    IF LENGTH(psLinea) <> 61 THEN  -- md-01
    IF LENGTH(psLinea) <> 41 THEN  -- md-01
       psRes := 'R'; --Rechazado
       psMsg := 'Longitud de registro incorrecta.';
       RETURN;
    END IF;

    --verifico el primer caracter, debe ser '1'
    vsTemp := SUBSTR(psLinea, 1, 1);
    IF SUBSTR(psLinea, 1, 1) <> '1' THEN
       psRes := 'R'; --Rechazado
       psMsg := 'Tipo de registro es incorrecto.';
       RETURN;
    END IF;

    --verifico el rut de la UFT
    --IF REGEXP_REPLACE(TRIM(SUBSTR(psLinea,52,9)),'^0+','')||'-'||SUBSTR(psLinea,61,1) <> vsRutUFT THEN  --md-01
    IF REGEXP_REPLACE(TRIM(SUBSTR(psLinea,32,9)),'^0+','')||'-'||SUBSTR(psLinea,41,1) <> vsRutUFT THEN    --md-01
       psRes := 'W'; --Rechazado
       psMsg := 'El rut del recaudador no coincide';
       RETURN;
    END IF;

    --Verifico el monto
    IF TO_NUMBER(SUBSTR(psLinea,12,20),'099999999999999.9999') <> pnMontoA THEN
       psRes := 'W'; --Rechazado
       psMsg := 'El monto del encabezado no coincide con lo calculado';
       RETURN;
    END IF;

    --si sigo aqui significa que lo principal estuvo bien
    psRes := 'A'; --Aceptado
    psMsg := 'Registro de Encabezado Correcto.';

  EXCEPTION
      WHEN OTHERS THEN
        psRes := 'E'; --Error
        psMsg := psMsg|| SQLCODE || ' ' || SQLERRM;
END p_ProcesaEncabezado;

/******************************************************************************
PROCEDIMIENTO:  p_ProcesaRegistro
OBJETIVO:   Verifica un registro de pago. Si es correcto el formato
     ejecuta el proceso de aplicación de pagos
PARAMETROS:
psLinea:   Linea de texto a procesar como registro de pago
pnMonto:   Parametro de salida, Indica el total informado en este
     registro. Sirve para verificar el monto de cuadratura en
     el encabezado
psRes:    Parametro de salida, guarda el resultado del procesamiento:
     A - Aprobado/Aplicado, R - Rechazado
     W - Aplicado con advertencias, E - Error
psMsg:    Parametro de salida, Mensaje de resultado de la operacion
******************************************************************************/
PROCEDURE p_ProcesaRegistro(
                              psLinea     IN     VARCHAR2
                             ,pnMontoR    IN OUT NUMBER
                             ,psRes       IN OUT VARCHAR2
                             ,psMsg       IN OUT VARCHAR2
                             ,pdOverdate  in     date
                            ) IS
                            
 --Longitud del registro
 vnTamano   PLS_INTEGER;
 --Variable temporal
 vsTemp    VARCHAR2(130);

 --Rut del apoderado
 vsRutApo   VARCHAR2(10);
 --Rut del alumno
 vsRutAlu   VARCHAR2(10);
 --Numero de contrato
 vsCntr    varchar2(22);-- TWBCNTR.TWBCNTR_NUM%TYPE;
 --Numero de documento
 vsNumDoc   TWBDOCU.TWBDOCU_DOCU_NUM%TYPE;
 --Numero secuencial de documento
 vnNumSeqDoc   TWBDOCU.TWBDOCU_SEQ_NUM%TYPE;
 --Fecha de vencimiento
 vdFechaVen   DATE;
 --Fecha de pago
 vdFechaPago   DATE;
 --Monto base
 vnMontoBase   TWBDOCU.TWBDOCU_AMOUNT%TYPE;
 --Monto de intereses
 vnMontoInt   TWBDOCU.TWBDOCU_AMOUNT%TYPE;
 --Monto total
 vnMontoTot   TWBDOCU.TWBDOCU_AMOUNT%TYPE;

 vnLargo    number(10);
 vcString   string(200);

 --Cursor para obtener los datos originales del documento
 CURSOR cuDatosDoc(pnNumSeqDoc NUMBER) IS
  SELECT SPBPERS_NAME_SUFFIX      AS RutAlu
         ,pk_MatApoderado.f_GetApoderadoDocu(
          TWBDOCU_SEQ_NUM
         )          AS RutApo
         ,TWBDOCU_CNTR_NUM      AS Cntr
         ,TWBDOCU_DOCU_NUM      AS NumDoc
         ,TWBDOCU_AMOUNT       AS Monto
         ,CEIL(TWBDOCU_NOM_AMOUNT)    AS MontoNom
         ,TWBDOCU_EXPIRATION_DATE    AS FechaVen
         ,TWBDOCU_STATUS_IND      AS Status
    FROM SPBPERS
         ,TWBDOCU
   WHERE SPBPERS_PIDM(+) = TWBDOCU_PIDM
    AND TWBDOCU_SEQ_NUM = pnNumSeqDoc;

 --Registro para guardar la salida del cursor
 vrDatosDoc   cuDatosDoc%ROWTYPE;
 --Variable para ver si se encontraron los datos
 vbFound    BOOLEAN;

BEGIN

   --si el tamaño es diferente de 879 caracteres se rechaza este registro
   --IF LENGTH(psLinea) <> 879 THEN --md-01
   vnLargo := LENGTH(psLinea);
   IF vnLargo < 949  or vnLargo > 950 THEN

      psRes := 'R'; --Rechazado
      psMsg := 'Longitud de registro incorrecta. ';
      RETURN;
   END IF;

   --verifico el primer caracter, debe ser '2'
   IF SUBSTR(psLinea, 1, 1) <> '2' THEN
       psRes := 'R'; --Rechazado
       psMsg := 'Tipo de registro es incorrecto. ';
       RETURN;
   END IF;

    --El segundo caracter debiera ser 'R', recaudación (rendición)
   IF SUBSTR(psLinea, 2, 1) <> 'R' THEN
      psRes := 'R'; --Rechazado
      psMsg := 'Tipo de acción es incorrecto. ';
      RETURN;
   END IF;

   BEGIN
      --Comienzo a hacer extraccion de datos utiles
      --Rut del apoderado, quito los ceros y agrego el guion
      --Se extrae el rut del cliente pagador: (Pos: 3~12)
      vsRutApo := REGEXP_REPLACE(SUBSTR(psLinea,3,9),'^0+','') ||'-'|| SUBSTR(psLinea,12,1);

      --md-02 start
      --Numero del contrato (Pos: 323~347)
      --vsCntr := TRIM(SUBSTR(psLinea,323,25));

      vsCntr := TRIM(SUBSTR(psLinea,418,22));
      vsCntr :=  substr(vsCntr, length(vsCntr)-8,8) || '-' ||substr(vsCntr, length(vsCntr));

      --md-02 end

      --md-01 start
      --Numero de documento (Pos: 376~395)  --md-01
      --vnNumSeqDoc := TO_NUMBER(REGEXP_REPLACE(SUBSTR(psLinea,376,20),'^0+','') );  --md-01
      --Numero de documento (Pos: 450~469)
      vnNumSeqDoc := TO_NUMBER(REGEXP_REPLACE(SUBSTR(psLinea,450,20),'^0+',''));


      -- Fecha de Vencimiento (Pos 366~375)  --md-01
      -- vdFechaVen := TO_DATE(SUBSTR(psLinea,366,10),'DD/MM/YYYY'); --md-01
      --Fecha de Vencimiento (Pos 480~489)
      vcString := SUBSTR(psLinea,480,10);
      vdFechaVen := TO_DATE(vcString,'DD/MM/YYYY');

      --Monto de la cuota (Pos: 420~434)  --md-01  (en el layout el nombre es monto documento)
      -- vnMontoBase := TO_NUMBER(SUBSTR(psLinea,420,15),'0999999999.9999');  --md-01
      --Monto de la cuota (Pos: 490~434)  --md-01 (en el layout el nombre es monto cuot)
      vcString := nvl(SUBSTR(psLinea,490,15),0);
      vnMontoBase := TO_NUMBER(vcString,'0999999999.9999');

      --Monto de intereses cobrados: (Pos 439~453)       --md-01
      --vnMontoInt := TO_NUMBER(SUBSTR(psLinea,439,15),'0999999999.9999');  --md-01
      --Monto de intereses cobrados: (Pos 509~523)
      vcString := nvl(SUBSTR(psLinea,509,15),0);
      vnMontoInt := TO_NUMBER(vcString,'0999999999.9999');

      --Fecha de Pago (Pos 540~549)                       --md-01
      --vdFechaPago := TO_DATE(SUBSTR(psLinea,540,10),'DD/MM/YYYY');   --md-01
      --Fecha de Pago (Pos 610~691)
      vdFechaPago := TO_DATE(nvl(SUBSTR(psLinea,610,10),null),'DD/MM/YYYY');

      --Monto Pagado (Pos: 565~579)   --md-01
      --vnMontoTot := TO_NUMBER(SUBSTR(psLinea,565,15),'0999999999.9999');   --md-01
      --Monto Pagado (Pos: 635~649)
      vnMontoTot := TO_NUMBER(SUBSTR(psLinea,635,15),'0999999999.9999');

      --md-01 end

   EXCEPTION
    WHEN OTHERS THEN
     psRes := 'E'; --Rechazado
     psMsg := 'Error al extraer los datos del registro: ' ||SQLCODE  ||' '||SQLERRM;
     RETURN;
   END;

   --Si ya estoy aqui obtengo los datos del documento
   OPEN cuDatosDoc(vnNumSeqDoc);
     FETCH cuDatosDoc INTO vrDatosDoc;
     vbFound := cuDatosDoc%FOUND;
   CLOSE cuDatosDoc;

 --Si no se encontró el registro a la goma :)
   IF NOT vbFound THEN
     psRes := 'R'; --Rechazado
     psMsg := 'El numero secuencial de documento ' ||vnNumSeqDoc||' no fue encontrado en la base de datos. ';
     RETURN;
   END IF;

   --Si lo encontro significa que puedo armar mi mensaje de numero de
   --contrato y cuota
   psMsg := 'Contrato: '||vrDatosDoc.Cntr  ||'. Num. Cuota: '||vrDatosDoc.NumDoc||'. ';

   --La siguiente verificacion de registro es el estado de pago, debe ser
   --03, pagado, eso se ve en la posicion 437, L: 2
   --     estado del pago (507-508)    --md-01
   --IF SUBSTR(psLinea, 437, 2) <> '03' THEN
   IF SUBSTR(psLinea, 507, 2) <> '03' THEN
      psRes := 'R'; --Rechazado
      psMsg := psMsg||'El estado del pago no es pagado. ';
      RETURN;
   END IF;

   --Empiezo a comparar datos criticos:
   --Monto de la cuota nominal de la cuota debe ser el mismo,
   --Contrato debe ser el mismo
   IF vsCntr <> vrDatosDoc.Cntr OR vnMontoBase <> vrDatosDoc.MontoNom THEN
      psRes := 'R'; --Rechazado
      psMsg := psMsg || 'El monto y/o el contrato del documento difieren al indicado. ';
      RETURN;
   END IF;

   --El estado del documento no debe ser PA
   IF NOT pk_Matricula.f_GetBanSt('PAGABLE',vrDatosDoc.Status) THEN
      psRes := 'R'; --Rechazado
      psMsg := psMsg || 'El documento no puede ser marcado como pagado. ';
      RETURN;
   END IF;

   --El monto pagado debe ser igual o mayor que la suma de la cuota mas los
   --intereses
   IF vnMontoBase + vnMontoInt > vnMontoTot THEN
      psRes := 'R'; --Rechazado
      psMsg := psMsg || 'El monto de la cuota mas intereses es mayor que el monto pagado. ';
    RETURN;
   END IF;

   --Una vez estando aqui ya tengo todos los elementos para marcar el documento
   -- md-07 start
   if pdOverdate is not null then 
      vdFechaPago := pdOverdate; 
   end if; 
   -- md-07 end
   
   
   p_AplicaPago( vnNumSeqDoc ,vnMontoInt ,vdFechaPago ,psRes ,psMsg );

   --El monto pagado debe coincidir con la suma de la cuota base mas intereses
   IF vnMontoTot > vnMontoInt + VnMontoBase THEN
      psRes := 'W';
      psMsg := psMsg ||'Aviso : La cantidad pagada excede el monto de la cuota mas intereses. ';   --md-03
   END IF;

   --Ultima revision de integridad, la fecha de vencimiento
   --los ruts del apoderado y alumno y el numeor de cuota deben ser iguales
   IF vsRutApo <> vrDatosDoc.RutApo OR vsRutAlu <> vrDatosDoc.Rutalu
      OR vdFechaVen <> vrDatosDoc.FechaVen OR vsNumDoc <> vrDatosDoc.NumDoc THEN
     psRes := 'W';
     psMsg := psMsg
           ||'Aviso : Algunos de los datos indicados no coinciden con los existentes '
           ||'en la base de datos. ';   --md-03
   END IF;

   --marco la salida
   pnMontoR := vnMontoTot;

EXCEPTION
   WHEN OTHERS THEN
      psRes := 'E'; --Error
      psMsg := psMsg|| SQLCODE || ' ' || SQLERRM;
END p_ProcesaRegistro;

/******************************************************************************
PROCEDIMIENTO:  p_AplicaPago
OBJETIVO:   Marca el documento como pagado (realizando todas las
     operaciones requeridas) y agrega los intereses respectivos
PARAMETROS:
pnNumSeqDoc:  Numero Secuencial de Documento
pnMontoInt:   Monto de intereses a cargar al documento
pdFecha:   Fecha en la que fue liquidado el documento
psRes:    Parametro de salida, guarda el resultado del procesamiento:
     A - Aprobado/Aplicado, R - Rechazado
     W - Aplicado con advertencias, E - Error
psMsg:    Parametro de salida, Mensaje de resultado de la operacion
******************************************************************************/
PROCEDURE p_AplicaPago(
 pnNumSeqDoc   NUMBER
 ,pnMontoInt   NUMBER
 ,pdFecha IN  DATE
 ,psRes  IN OUT VARCHAR2
 ,psMsg  IN OUT VARCHAR2
) IS
 --Variable para guardar el estutos de la operacion
 vsResultado   CHAR(1);
 --Variable para guardar el mensaje de salida (resultado del procesamiento)
 vsMensaje   VARCHAR2(4000);

 --Codigo de detalle del cargo de intereses
 vsCodDetCargoR  TBBDETC.TBBDETC_DETAIL_CODE%TYPE := 'INTC';
 --Numero de transaccion del cargo
 vnNumTranCargo  TBRACCD.TBRACCD_TRAN_NUMBER%TYPE;
 --Descripcion del cargo
 vsDesc    TBBDETC.TBBDETC_DESC%TYPE;

 --Cursor para obtener el pidm de un documento
 CURSOR cuDatos(pnNumSeqDoc NUMBER) IS
  SELECT
   TWBDOCU_PIDM   AS Pidm
   ,TWBDOCU_TERM_CODE  AS Perio
  FROM
   TWBDOCU
  WHERE
   TWBDOCU_SEQ_NUM = pnNumSeqDoc;
 --Registro para guardar la salida del cursor
 vrDatos    cuDatos%ROWTYPE;

BEGIN

 --Defino un punto de control por si no puedo hacer el procedimiento
 --completo
 SAVEPOINT ANTES_APLICAR_PAGO;

 --obtengo el pidm del documento
 OPEN cuDatos(pnNumSeqDoc);
   FETCH cuDatos INTO vrDatos;
 CLOSE cuDatos;

 --Antes de, hago el update a el estado de pagado via Banco de Chile
 --Esto es para que la contabilidad no haga cosas raras
 UPDATE
  TWBDOCU
 SET
  TWBDOCU_STATUS_IND = 'PC'
  , TWBDOCU_PAY_DATE  =   pdFecha       -- md-06
 WHERE
  TWBDOCU_SEQ_NUM = pnNumSeqDoc;

 --Si hubo recargos...
 IF pnMontoInt <> 0 THEN
    --Los asignamos a TBRACCD / TWRDOTR

    --Obtengo numero de siguiente transaccion en TBRACCD
    vnNumTranCargo := pk_Matricula.f_SigNumTranACCD(vrDatos.Pidm);

    --obtengo la descripcion del cargo de intereses
    vsDesc := pk_Matricula.f_ObtDescCodDet(vsCodDetCargoR);

    --Inserta el cargo en TBRACCD
    pk_Matricula.p_RegTbraccd(vrDatos.Pidm ,vnNumTranCargo ,vrDatos.Perio
                              ,vsCodDetCargoR ,pnMontoInt ,pnMontoInt
                              ,pdFecha ,vsDesc ,NULL ,cgsCodApp);

    --Insertamos el documento transaccion
    pk_Matricula.p_insTranDocu(vrDatos.Pidm ,vnNumTranCargo ,pnNumSeqDoc
                               ,pnMontoInt ,NULL ,NULL ,NULL);

    --actualizamos el monto
    UPDATE  TWBDOCU
    SET  TWBDOCU_AMOUNT = TWBDOCU_AMOUNT + pnMontoInt
    WHERE TWBDOCU_SEQ_NUM = pnNumSeqDoc;

 END IF; 

  --md-05 start
 --Procesamos el documento como pagado
 -- pk_Matricula.p_PagarDocu(pnNumSeqDoc ,pdFecha , vgsUsr ,cgsCodApp);
 Pk_Matricula_Amalia.p_PagarDocu(pnNumSeqDoc ,pdFecha , vgsUsr , null, cgsCodCarga, null );   ---cgsCodApp);
 
 --md-05 end

 --Ahh perfecto, aqui ya se hicieron todos los movimientos en DB
 psMsg := psMsg || 'Registrado como pagado. ';
 psRes := 'A';

 --Ahora verifico casos de integridad.
 --Verifico el pago de recargos
 IF pnMontoInt <> 0 THEN
  psMsg := psMsg
         ||' Se aplicaron recargos por $'||TO_CHAR(pnMontoInt,'999999999')
         ||'. ';
 END IF;

 --si llegue aqui significa que todo estuvo ok
EXCEPTION
 WHEN OTHERS THEN
   --Rollback parcial a este procedimiento unicamente
  ROLLBACK TO ANTES_APLICAR_PAGO;
  psRes := 'E'; --Error
  psMsg := psMsg||'Código: '||sqlcode||'. Descripción: '||sqlerrm;

END;

/******************************************************************************
PROCEDIMIENTO:  p_InicioPaginaResultado
OBJETIVO:   Genera la parte inicial de la pagina de resultados.
     Encabezado HTML, Body y titulo en el cuerpo del mismo
     asi como la tabla de resultados.
******************************************************************************/
PROCEDURE p_InicioPaginaResultado
IS
BEGIN

 DBMS_OUTPUT.PUT_LINE('Resultado de Carga de Archivos de Rendición Banco de Chile');

END p_InicioPaginaResultado;

/******************************************************************************
PROCEDIMIENTO:  p_ImprimeLineaResultado
OBJETIVO:   Genera una linea con el mensaje y/o HTML indicado en la
     pagina de resultados
PARAMETROS:
psLinea    Mensaje y/o HTML a mostrar
******************************************************************************/
PROCEDURE p_ImprimeLineaResultado(
 psLinea    VARCHAR2
) IS
BEGIN
 DBMS_OUTPUT.PUT_LINE(psLinea);
END p_ImprimeLineaResultado;

/******************************************************************************
PROCEDIMIENTO:  p_CierrePaginaResultado
OBJETIVO:   Cierra el cuerpo y el HTML de la pagina de resultados.
******************************************************************************/
PROCEDURE p_CierrePaginaResultado
IS
BEGIN
 DBMS_OUTPUT.PUT_LINE ('Fin del Proceso.');
END p_CierrePaginaResultado;

END pk_CargaBChile_Nv;
/

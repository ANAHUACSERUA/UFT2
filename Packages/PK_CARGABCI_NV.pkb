CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaBCI_Nv IS
/******************************************************************************
PAQUETE:   BANINST1.pk_CargaBCI
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
objetivo        se cambia metodo de carga archivo
autor           roman ruiz
fecha           03-feb-2015

-----------------------------
modificacion    - md-05
autor  :   roman ruiz
accion :   Cambio de procedimiento de p_pagardocu
Fecha  :   07-sep-2016

******************************************************************************/

 --Codigo global de la aplicacion
 cgsCodApp   CONSTANT VARCHAR2(4) := 'CBCI';
 
  cgsCodCarga          constant varchar2(3) := 'BCI';   --md-05

 --Variable global para guardar el usuario
 vgsUsr    VARCHAR2(30) := NULL;
vnamenew  varchar2(40);
vsalida             VARCHAR2(3000);

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
PROCEDURE p_ProcesaRegistro(
 psLinea  IN  VARCHAR2
 ,pnMontoR IN OUT NUMBER
 ,psRes  IN OUT VARCHAR2
 ,psMsg  IN OUT VARCHAR2
);
PROCEDURE p_AplicaPago(
 pnNumSeqDoc   NUMBER
 ,pnMontoInt   NUMBER
 ,pdFecha IN  DATE
 ,psRes  IN OUT VARCHAR2
 ,psMsg  IN OUT VARCHAR2
);
--fin de prototipos privados

FUNCTION f_genera_string_de_espacios(pnNumEspacios NUMBER) RETURN VARCHAR2;
/******************************************************************************
PROCEDIMIENTO:  p_Carga
OBJETIVO:   Procesa un archivo de rendición PEC para que los pagos
     indicados en el mismo sean transferidos al estado de cuenta
     de los alumnos
PARAMETROS:
psArchivo   Nombre con que fue guardado el archivo cargado
     por el usuario.
******************************************************************************/
FUNCTION f_genera_string_de_espacios(pnNumEspacios NUMBER) RETURN VARCHAR2
IS

salida  varchar2(300):='';
begin
     for i in 1..pnNumEspacios loop
         salida := salida || ' ';
     end loop;

RETURN salida;
END;
PROCEDURE p_Carga(
                                psArchivo   VARCHAR2
                                ,psUser    VARCHAR2 DEFAULT USER
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

vnamecorto  varchar2(40);

    vsalida             VARCHAR2(3000);      --md-04  start
    vsNameArchivo       varchar2(300);
    vsArchExitente     varchar2(300);
     vsArchExSize       number(10):= 0;
     vrArchivoExBlob   BLOB;
     viArchVivo           number(4) := 0;

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

     --md-04 start
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

          INSERT INTO GWRERRO VALUES (cgsCodApp, psArchivo ,'Este Archivo Ya Se Habia Subido Anteriormente', sysdate, psUser);

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

    --calculo la firma SHA1 del archivo
     vrDigestionSHA1 := DBMS_CRYPTO.HASH(vrArchivoBLOB,DBMS_CRYPTO.HASH_SH1);

     --Si sigo aqui es que el archivo existe, procedo a convertir BLOB a CLOB
     --Ojo el Banco de chile esta mandando la combinación mas extraña
     --que haya visto, UTF-8 con saltos de linea MAC (a parte con BOM si hay
     --caracteres Unicode y sin BOM cuando todo entra en ASCII, wtf!!!

   --Para detectar primero que version es, tengo que extraer los primeros 3
    --bytes del blob y ver si es corresponden al BOM de UTF-8
     vrTmp := DBMS_LOB.SUBSTR(vrArchivoBLOB,3,1);

    --Si los tres primeros bytes corresponden aL BOM
     IF UTL_RAW.COMPARE(vrTmp, vrBOMUTF8) = 0 THEN
         --Copio el BLOB a otro descartando los 3 primeros bytes que corresponden al BOM
         DBMS_LOB.CREATETEMPORARY(vrBlobUTF,true);
         DBMS_LOB.COPY( vrBlobUTF ,vrArchivoBLOB  ,DBMS_LOB.GETLENGTH(vrArchivoBLOB)-3   ,1  ,4 );

          --Aqui convierto el nuevo BLOB en CLOB
         vsArchivoCLOB := pk_UtilCrgEnvArch.f_BLOBaCLOB(vrBlobUTF,'AL32UTF8');
     ELSE
          --Si no encontró el BOM asumo que es la codificación estandar  ISO-8859-1
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

             --aqui debería empieza el procesamiento de afectación
              IF vnNumLineas = 1 THEN
                 --si es la primera linea  la guardo para procesarla al final!!!
                 vsLineaEnc := vsLinea;

                 --Ojo, establezco la posicion de lectura en la siguiente linea (leer abajo el caso general)
                 vni := vni + 2;

                 CONTINUE;

              ELSE
                 --Limpio el monto del registro
                  vnMontoReg := 0;

                  --si no es la primera linea forzosamente es un registro
                  p_ProcesaRegistro(vsLinea, vnMontoReg, vsStatus, vsMensajeProc);

                --sumo el monto
                  vnMontoTotal := vnMontoTotal + vnMontoReg;

              END IF;

             --Agrego el numero de linea al archivo
              vsMsg := 'Num Linea: '||vnNumLineas||'. ';

             CASE vsStatus
                   WHEN 'A' THEN  vsMsg := vsMsg || 'Registro Correcto: '   || vsMensajeProc;
                   WHEN 'W' THEN  vsMsg := vsMsg || 'Advertencia: '    || vsMensajeProc;
                   WHEN 'R' THEN   vsMsg := vsMsg || 'Registro no procesado: ' || vsMensajeProc;
                   WHEN 'E' THEN  vsMsg := vsMsg || 'Error: '  || vsMensajeProc;
                   ELSE  vsMsg := vsMsg || ' Error no codificado ' || vsMensajeProc;

             END CASE;

             --Agrego la salida del proceso
             if vsMsg  is null then
                vsMsg:='inicio';
             else
                 vsMsg:=vsMsg||vsMensajeProc;
             end if;

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
          --que no quedara en codigo duro y aceptara saltos de linea al estilo
          --unix \n puro.
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

   --- p_ProcesaEncabezado(  vsLineaEnc ,vnNumLineas-1 ,vnMontoTotal ,vsStatus ,vsMensajeProc );

    --Agrego el numero de linea al mensaje de salida
    vsMsg := 'Num Linea: 1. ';
 --En base al estatus mando el mensaje de salida

     CASE vsStatus
                   WHEN 'A' THEN  vsMsg := vsMsg || 'Registro Correcto: '   || vsMensajeProc;
                   WHEN 'W' THEN  vsMsg := vsMsg || 'Advertencia: '    || vsMensajeProc;
                   WHEN 'R' THEN   vsMsg := vsMsg || 'Registro no procesado: ' || vsMensajeProc;
                   WHEN 'E' THEN  vsMsg := vsMsg || 'Error: '  || vsMensajeProc;
                   ELSE  vsMsg := vsMsg || ' Error no codificado ' || vsMensajeProc;
      END CASE;

     if vsMsg  is null then
         vsMsg:='inicio';
     end if;


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
                      ,vnNumLineas +1
                      ,vsLineaEnc
                      ,vsStatus
                      ,vsMsg
                      ,SYSDATE
                      ,psUser  );

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

EXCEPTION
    WHEN OTHERS THEN
          vsalida := ('Error:gral- '||sqlcode || '. ' || (sqlerrm));
       INSERT INTO GWRERRO
        VALUES(cgsCodApp,psArchivo, vsalida, SYSDATE, user   );
        commit;

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
    IF LENGTH(psLinea) <> 170 THEN  -- md-01
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

    --verifico la cuenta corriente dela UFT

    --IF REGEXP_REPLACE(TRIM(SUBSTR(psLinea,52,9)),'^0+','')||'-'||SUBSTR(psLinea,61,1) <> vsRutUFT THEN  --md-01
   -- IF REGEXP_REPLACE(TRIM(SUBSTR(psLinea,32,9)),'^0+','')||'-'||SUBSTR(psLinea,41,1) <> vsRutUFT THEN    --md-01
   IF SUBSTR(psLinea, 2, 12) <> '123456789012' THEN -- sustituir '123456789012' por cuenta corriente de la empresa
       psRes := 'W'; --Rechazado
       psMsg := 'La cuenta corriente de la empresa no coincide';
       RETURN;
    END IF;
   --verifico el nombre de la empresa

    IF SUBSTR(psLinea, 14, 20) <> 'UNIVERS FINIS TERRAE' THEN -- sustituir 'UNIVERS FINIS TERRAE' por nombre de la empresa
       psRes := 'W'; --Rechazado
       psMsg := 'El nombre de la empresa no coincide';
       RETURN;
    END IF;
 -- verifico fecha de recaudacion dia
IF TO_NUMBER(SUBSTR(psLinea, 34, 2),'099999999999999.9999') >= 1  AND TO_NUMBER(SUBSTR(psLinea, 34, 35),'099999999999999.9999') <= 31  THEN -- sustituir 'UNIVERS FINIS TERRAE' por nombre de la empresa
       psRes := 'W'; --Rechazado
       psMsg := 'El dia de la fecha de recaudacion es erroneo';
       RETURN;
    END IF;
-- verifico fecha de recaudacion mes
IF TO_NUMBER(SUBSTR(psLinea, 36, 2),'099999999999999.9999') >= 1  AND TO_NUMBER(SUBSTR(psLinea, 34, 35),'099999999999999.9999') <= 12  THEN -- sustituir 'UNIVERS FINIS TERRAE' por nombre de la empresa
       psRes := 'W'; --Rechazado
       psMsg := 'El mes de la fecha de recaudacion es erroneo';
       RETURN;
    END IF;
-- verifico fecha de recaudacion año
IF TO_NUMBER(SUBSTR(psLinea, 38, 2),'099999999999999.9999') >= 1  AND TO_NUMBER(SUBSTR(psLinea, 34, 35),'099999999999999.9999') <= 99  THEN -- sustituir 'UNIVERS FINIS TERRAE' por nombre de la empresa
       psRes := 'W'; --Rechazado
       psMsg := 'El anio de la fecha de recaudacion es erroneo';
       RETURN;
    END IF;
-- verifico el filler de 131 espacios


IF SUBSTR(psLinea, 40, 131) <> f_genera_string_de_espacios(131) THEN -- sustituir 'UNIVERS FINIS TERRAE' por nombre de la empresa
       psRes := 'W'; --Rechazado
       psMsg := 'El filler es erroneo';
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
 psLinea  IN  VARCHAR2
 ,pnMontoR IN OUT NUMBER
 ,psRes  IN OUT VARCHAR2
 ,psMsg  IN OUT VARCHAR2
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

  --Monto efe
 vnMontoEfe   TWBDOCU.TWBDOCU_AMOUNT%TYPE;

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
  --  insert into swrpaso values ( 'carga pk-bancos-proceso largo-1  - ' , '---linea-'|| vnLargo);commit;

   IF vnLargo <> 170 THEN
       insert into swrpaso values ( 'carga pk-bancos-proceso reg-2  - ' , '---linea-'|| vnLargo);commit;
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
   IF SUBSTR(psLinea, 2, 1) <> '1' THEN
      psRes := 'R'; --Rechazado
      psMsg := 'Tipo de acción es incorrecto. ';
      RETURN;
   END IF;

   BEGIN
      --Comienzo a hacer extraccion de datos utiles
      --Rut del apoderado (Número Cliente), quito los ceros y agrego el guion
      --Se extrae el rut del cliente pagador: (Pos: 3~13)
      vsRutApo := REGEXP_REPLACE(SUBSTR(psLinea,3,9),'^0+','') ||'-'|| SUBSTR(psLinea,13,1);

           insert into swrpaso values ( 'carga pk-bancos-proceso begin--3--  ' , '---rut  -'|| vsRutApo);commit;

      --Numero de documento (Número Boleta) (Pos: 14~24)
      vnNumSeqDoc := TO_NUMBER(REGEXP_REPLACE(SUBSTR(psLinea,14,11),'^0+',''));

-- Campo 5 Unidad Monetaria  0b,    pesos M/N
  IF SUBSTR(psLinea, 25, 2) <> '0 ' THEN
      psRes := 'R'; --Rechazado
      psMsg := 'El cupón solo se puede pagar en pesos';
      RETURN;
   END IF;

   -- Campo 6 Valor (Pos: 27~41)
       vcString := nvl(SUBSTR(psLinea,27,15),0);
      vnMontoBase := TO_NUMBER(vcString,'0999999999.9999');

  -- Campo 7 MOnto Total  (Pos: 42~54)
  /*
  sólo tiene sentido si la Unidad Monetaria es distinto de cero (0). Contiene 11 dígitos enteros y 2 dígitos decimales
  */
    vnMontoTot := TO_NUMBER(SUBSTR(psLinea,42,13),'0999999999.99');
  --Campo 8 : Monto Efectivo
 vnMontoEfe := TO_NUMBER(SUBSTR(psLinea,55,15),'0999999999.99');

/*


Campo 9    CÓDIGO TRANSACCIÓN: forma en que se recaudó la factura:(Pos: 68~71)
6700: totalmente en efectivo
6710: totalmente en cheque otro banco otra plaza o parte en efectivo y parte en cheque otro  banco otra plaza
6720: totalmente en cheque otro banco misma plaza o parte en efectivo y parte en cheque otro banco misma plaza
6740: totalmente en cheque del B.C.I. o parte en efectivo y parte en cheque del B.C.I.
6750: totalmente en efectivo

Campo 10    CÓDIGO OFICINA: código de la oficina del banco que realizó la recaudación (Pos: 72~74)


*/
--11.    FECHA RECAUDACIÓN: fecha en que fue efectuada la recaudación, en formato AAMMDD. (Pos: 75 ~ 80)
vdFechaPago := TO_DATE(nvl(SUBSTR(psLinea,75,6),null),'DD/MM/YYYY');



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
 --como pagado. Mello!? que novato me vi en ese entonces JOJOJO
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

     vsalida := ('Error:procesa- '||psMsg || '-- ' || (sqlerrm));
       INSERT INTO GWRERRO
        VALUES(cgsCodApp,'procesa', vsalida, SYSDATE, user   );
        commit;

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
  TWBDOCU_STATUS_IND = 'PB'
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

 -- md-05 start
 --Procesamos el documento como pagado
 -- pk_Matricula.p_PagarDocu(pnNumSeqDoc ,pdFecha , vgsUsr ,cgsCodApp);
 
  Pk_Matricula_Amalia.p_PagarDocu(pnNumSeqDoc ,pdFecha , vgsUsr , null, cgsCodCarga, cgsCodApp);
 
 -- md-05 end

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

 DBMS_OUTPUT.PUT_LINE('Resultado de Carga de Archivos de Rendición Banco BCI');

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

END pk_CargaBCI_Nv;
/

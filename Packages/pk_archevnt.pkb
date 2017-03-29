DROP PACKAGE BODY BANINST1.PK_ARCHEVNT;

CREATE OR REPLACE PACKAGE BODY BANINST1.PK_ARCHEVNT AS

  /******************************************************************************
  PAQUETE:            BANINST1.pk_ArchEvnt
  OBJETIVO:           Contiene los procedimientos, funciones y variables
                      requeridos para la generación de archivos de Eventos
  AUTOR:              Alejandro Gómez Mondragón
  FECHA:              20131005
  -------------------------------------
  modificacion        md-01
  autor               roman ruiz
  objetivo            cambiar del archivo CSV  a un archivo ZIP
  fehca               14-oct-2013
  ******************************************************************************/

    --Codigo global de la aplicacion 'EVNT'
    cgsCodApp            CONSTANT VARCHAR2(4) := 'EVNT';

    --Mensajes de Error
    cgsErr20401      CONSTANT VARCHAR2(4000) := 'No esta configurada la secuencia para la generacion de archivos de contabilidad';
    cgsErr20402      CONSTANT VARCHAR2(4000) := 'No se pudo obtener un numero de archivo';
    cgsErr20403      CONSTANT VARCHAR2(4000) := 'No se encontró el archivo especificado';
    cgsErr20404      CONSTANT VARCHAR2(4000) := 'No se encontraron los registros correspondientes al archivo';
    cgsErr20405      CONSTANT VARCHAR2(4000) := 'El archivo recien leido difiere del original. Posible corrupción de datos';
    cgsErr20406      CONSTANT VARCHAR2(4000) := 'No se encontraron los datos del alumno';
    cgsErr20407      CONSTANT VARCHAR2(4000) := 'No se encontraron los datos del apoderado';

    --Mensajes en general:
    cgsMsg001        CONSTANT VARCHAR2(4000) :=  'No hay transacciones disponibles para generar el archivo.';

    --Tipo para guardar el detalle de una operacion
    TYPE t_DetOper IS RECORD(
        SEQ                 NUMBER(10),
        RUT                 VARCHAR2(20),
        PIDM                NUMBER(8),
        ID                  VARCHAR2(9),
        TERM_CODE           VARCHAR2(6),
        APPL_NO             NUMBER(2),
        PROGRAMA            VARCHAR2(12),
        ADMT_CODE           VARCHAR2(2),
        EVNT_CODE           VARCHAR2(10),
        CODIGO              VARCHAR2(10),
        CODIGO_DESC         VARCHAR2(100),
        VAL_PNT             VARCHAR2(80),
        USUARIO             VARCHAR2(30),
        FECHA               DATE
    );

    --Tabla de Hash con los datos de las operaciones
    TYPE t_HshOper IS TABLE OF t_DetOper INDEX BY VARCHAR2(14);
    --Un simple arreglo de enteros
    TYPE t_Dets IS TABLE OF PLS_INTEGER;
    --Una tabla de hash con los arreglos
    TYPE t_HshDets IS TABLE OF t_Dets INDEX BY VARCHAR2(14);

--Prototipos de procedimientos y funciones privadas
PROCEDURE p_InsertaReg(
    pnNumArch            PLS_INTEGER
    ,pnNumReg            PLS_INTEGER
    ,psLinea            VARCHAR2
    ,psUser                VARCHAR2
);

FUNCTION f_GeneraArchivo(
    psNumArch       PLS_INTEGER
) RETURN CLOB;

FUNCTION f_CLOBaBLOB(
  prContenido   IN OUT NOCOPY CLOB
 ,psCharset   VARCHAR2 DEFAULT 'WE8ISO8859P1'
) RETURN BLOB;

  /******************************************************************************
  PROCEDIMIENTO:        p_Genera
  OBJETIVO:             Generar los registros contables para su posterior reporte.
  PARAMETROS:
  pnNumArch:            Parámetro de salida para indicar el número de archivo.
                        Nulo si no hubo registro alguno a reportar.
  pnNumRegs:            Número registros procesados / reportados. Nulo si no hubo
                        registro alguno a procesar
  pdFecha               Fecha donde solo se utiliza el año para tomar info EVNT
  psUser:               Usuario que invoco el proceso, si no se especifica se toma
                        el ID de oracle de la conexión.
  *****************************  *************************************************/
  PROCEDURE p_Genera(
      pnNumArch   OUT        PLS_INTEGER
      ,pnNumRegs  OUT        PLS_INTEGER
      ,pdFecha    IN         DATE DEFAULT SYSDATE
      ,psUser     IN         VARCHAR2 DEFAULT USER
  ) IS

      --Cursor con los movimientos del EVNT
        CURSOR cuDatos IS
                  SELECT * FROM GWBEVNT
                   WHERE GWBEVNT_SEQ >=  (SELECT MAX(GWRBIEV_SEQ) + 1 FROM GWRBIEV)
                     AND (GWBEVNT_EVNT_CODE IN  ('PERS', 'PPSU', 'MATR', 'RETR', 'DECI', 'COPR')
                          OR GWBEVNT_EVNT_CODE LIKE 'B%')
                   ORDER BY GWBEVNT_SEQ;


      TYPE t_Datos IS TABLE OF cuDatos%ROWTYPE;

      --Una tabla de movimientos de documento
      vtMovs                t_TblMovDoc;

      --Tabla para guardar las operaciones ordenadas
      vtOperBase     t_TblOrd := t_TblOrd();
      vtOperOrd      pk_Util.t_TblVarchar2 := pk_Util.t_TblVarchar2();

      --Registro temporal para una operación
      vrDetOper            t_DetOper;
      --El hash table en si
      vhOpers                pk_ArchEvnt.t_HshOper;
      --Este es el mapa de operaciones contra detalles contables
      vhDets                t_HshDets;

      --Arreglo donde guardamos las operaciones normales
      vtDatosMov           t_Datos;
      --vtDatosMD            t_Datos;
      vtDatos              t_Datos;

      --Variable para guardar el nombre de la secuencia de numero de archivo
      vsNomSeq            VARCHAR2(30);
      --Variable para guardar el número de archivo
      vnNumArch            PLS_INTEGER;
      --Variable para guardar el número de registros
      vnNumReg            PLS_INTEGER;

      --Linea para guardar la salida del registro
      vsLinea                VARCHAR2(4000);
      --Separador de columnas
      vsSep                  VARCHAR2(2) := ';';
      --Variable para guardar si se encontraron datos
      vbFound                BOOLEAN;
      -- Variable para guardar el Tipo de Operacion
      vsTipoOper             VARCHAR2(25);

      --Contadores comunes y corrientes
      vni                    PLS_INTEGER;
      vnj                    PLS_INTEGER;

      --Variables para guardar los datos acerca de una operacion
      vsTipo                VARCHAR2(2);
      vsId                  VARCHAR2(14);
      vnNum                 NUMBER(14);

      --Indice para recorrer el Hash table
      vsIdx                VARCHAR2(14);
      vdDate               DATE := sysdate;

      vsAnio               varchar2(4);

      err_msg              VARCHAR2(4000);

      csDDMMRRRR CONSTANT  VARCHAR2(21) := 'DD/MM/YYYY HH24:MI:SS';

      vdInicial    DATE;
      vdFinal      DATE;

  BEGIN

      --Establezco un savepoint
      SAVEPOINT InicioArchivo;
      vdInicial := NULL;
      vdFinal   := NULL;
      vdInicial := SYSDATE;


      --Indico los valores de salida como nulos
      pnNumArch := NULL;
      pnNumRegs := NULL;

      --Obtengo el nombre de la secuencia de los parametros de
      --la aplicacion
      vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');

      --Si no se encontró el nombre de la secuencia mandamos error
      IF vsNomSeq IS NULL THEN
          RAISE_APPLICATION_ERROR(-20401, cgsErr20401, TRUE);
      END IF;

      ---Genero detalle de registros
      vsAnio:= to_char(pdFecha,'YYYY');
      -- p_ObtDetOper(vsAnio);

      --obtengo un nombre NUMERO de archivo
      vnNumArch := pk_Util.f_NumSec(vsNomSeq);

      --Si el numero de archivo fue nulo...
      IF vsNomSeq IS NULL THEN
          RAISE_APPLICATION_ERROR(-20402, cgsErr20402,TRUE);
      END IF;

    --Abro el cursor para registros de eventos
      OPEN cuDatos;
      FETCH cuDatos BULK COLLECT INTO vtDatosMov;
      CLOSE cuDatos;

      --Creo una sola coleccion de los datos ...
       vtDatos := vtDatosMov;

      --Si el tamaño de la colección es cero, no tiene caso seguir
      IF vtDatos.COUNT < 1 THEN
          RETURN;
      END IF;

      --aterrizar tablas.
      vtDatosMov := NULL;

      --Inicializo mi contador de lineas
      vnNumReg := 0;

     For vni in 1 .. vtDatos.COUNT LOOP
        --se llena la linea del archivo
        vsLinea :=    vtDatos(vni).GWBEVNT_SEQ            || vsSep
                      || vtDatos(vni).GWBEVNT_RUT         || vsSep
                      || vtDatos(vni).GWBEVNT_PIDM        || vsSep
                      || vtDatos(vni).GWBEVNT_ID          || vsSep
                      || vtDatos(vni).GWBEVNT_TERM_CODE   || vsSep
                      || vtDatos(vni).GWBEVNT_APPL_NO     || vsSep
                      || vtDatos(vni).GWBEVNT_PROGRAM_1   || vsSep
                      || vtDatos(vni).GWBEVNT_ADMT_CODE   || vsSep
                      || vtDatos(vni).GWBEVNT_EVNT_CODE   || vsSep
                      || vtDatos(vni).GWBEVNT_CODIGO      || vsSep
                      || vtDatos(vni).GWBEVNT_CODIGO_DESC || vsSep
                      || vtDatos(vni).GWBEVNT_VAL_PNT     || vsSep
                      || vtDatos(vni).GWBEVNT_USER        || vsSep
                      || vtDatos(vni).GWBEVNT_DATE        || vsSep
                 ;

         --insertar el renglon en la tabla de salida
         vnNumReg := vnNumReg + 1;
         p_InsertaReg(vnNumArch, vnNumReg, vsLinea, psUser);

     END LOOP;-- FIN DEL FOR

      --Una vez que genere el archivo regreso el numero de archivo y el número de registros
      pnNumArch := vnNumArch;
      pnNumRegs := vnNumReg;

      vdFinal := SYSDATE;
      INSERT INTO GWVTCNT VALUES (vdInicial, vdFinal, vnNumReg,'Fin p_Genera');

  EXCEPTION
      WHEN OTHERS THEN
          --Deshago los cambios de esta transaccion

          ROLLBACK TO InicioArchivo;
          err_msg := substr(sqlcode||'-'||sqlerrm,1,3999);
          INSERT INTO GWVTCNT VALUES (vdInicial,
                                      vdFinal,
                                      vnNumReg,
                                      substr('p_Genera:'||replace(err_msg,'"','\"'),1,399));
          COMMIT;

          --Mando el control a la aplicacion que invoco a este proceso
          RAISE;
  END p_Genera;

  /******************************************************************************
PROCEDIMIENTO:        p_InsertaReg
OBJETIVO:            Insertar un registro en la tabla de auditoria para
                    archivos enviados
pnNumArch:            Numero de archivo al que pertenece al registro
pnNumReg:            Numero de registro dentro del archivo
psLinea                El registro en si
psUser:                Usuario que genero el registro
******************************************************************************/
PROCEDURE p_InsertaReg(
    pnNumArch            PLS_INTEGER
    ,pnNumReg            PLS_INTEGER
    ,psLinea            VARCHAR2
    ,psUser             VARCHAR2
) IS
BEGIN

    INSERT INTO TWRAAEP(
        TWRAAEP_FILE_TYPE
        ,TWRAAEP_FILE_NUM
        ,TWRAAEP_RECORD_NUM
        ,TWRAAEP_RECORD
        ,TWRAAEP_ACTIVITY_DATE
        ,TWRAAEP_USER
    )VALUES(
        cgsCodApp
        ,pnNumArch
        ,pnNumReg
        ,psLinea
        ,SYSDATE
        ,psUser
    );
END p_InsertaReg;

-------------------------------------------------------------------
-- funcion f_CLOBaBLOB  convertir de Clob a Blob..
FUNCTION f_CLOBaBLOB(
 prContenido   IN OUT NOCOPY CLOB
 ,psCharset   VARCHAR2 DEFAULT 'WE8ISO8859P1'
) RETURN BLOB IS
 --Longitud del Archivo
 vnTamano   PLS_INTEGER;
 --Cadena de almacenamiento
 vsBuffer   VARCHAR2(4000);
 --Datos binarios extraidos
 vrBuffer   RAW(4000);
 --Contador de posiciones
 vni     PLS_INTEGER;
 --El CLOB :p, inicializado en vacio
 vsContenidoCLOB  CLOB;
 --Numero de caracteres a transferir en una iteracion
 vnNumCars   PLS_INTEGER;
 --El bLOB inicializado en vacio
 vlContenidoBLOB  BLOB;

 vnLangContext  PLS_INTEGER := DBMS_LOB.Default_Lang_Ctx;
 vnWarning      PLS_INTEGER;
 vnOff1         PLS_INTEGER := 1;
 vnOff2         PLS_INTEGER := 1;
 vnCsId         PLS_INTEGER;

BEGIN
   --Crea un almacen temporal para nuestro CLOB
   DBMS_LOB.CREATETEMPORARY(vlContenidoBLOB,true);

    vnCsId := NLS_CHARSET_ID(psCharset);

    --Convierto el CLOB a BLOB en el charset, codigo fijo a ISO8851-1
    DBMS_LOB.CONVERTTOBLOB(
                           vlContenidoBLOB
                           ,prContenido
                           ,DBMS_LOB.LobMaxSize
                           ,vnOff1
                           ,vnOff2
                           ,vnCsId
                           ,vnLangContext
                           ,vnWarning );

    RETURN vlContenidoBLOB;

END f_CLOBaBLOB;
-----------------------------
  /******************************************************************************
  FUNCION:              f_GeneraArchivo
  OBJETIVO:             Generar un archivo de texto con el detalle contable.
  PARAMETROS:
  pnNumArch:            Número de archivo a generar/obtener.
  VALOR DE RETORNO:     CLOB con el archivo
  ******************************************************************************/
  FUNCTION f_GeneraArchivo(
      psNumArch            PLS_INTEGER
  ) RETURN CLOB IS

      --El archivo en si
      vsContenido            CLOB := EMPTY_CLOB();
      viContador             number := 0;
      vsTexto                varchar2(500);

    cgsCR           CONSTANT VARCHAR2(1) := CHR(13);
    cgsLF           CONSTANT VARCHAR2(1) := CHR(10);
    cgsCRLF         CONSTANT VARCHAR2(2) := cgsCR||cgsLF;
    cgsSalto        CONSTANT VARCHAR2(2) := cgsCRLF;

      --Cursor para leer los datos del archivo
      CURSOR cuDatos(
          psNumArch        VARCHAR2
      ) IS
          SELECT TWRAAEP_RECORD_NUM AS Registro,
                 TWRAAEP_RECORD    AS Linea
            FROM TWRAAEP
           WHERE TWRAAEP_FILE_TYPE = cgsCodApp
             AND TWRAAEP_FILE_NUM = psNumArch
        ORDER BY TWRAAEP_RECORD_NUM;

      --Salto de linea
      vsLn                VARCHAR2(2) := cgsSalto;
      --Linea del archivo
     -- vsLinea             VARCHAR2(1000);
      vsLinea               TWRAAEP.TWRAAEP_RECORD%TYPE;

  BEGIN
      --declaro el espacio temporal para el CLOB
     DBMS_LOB.CREATETEMPORARY(vsContenido,true,1);

      viContador := 0;

      --abro mi cursor
      FOR regDatos IN cuDatos(psNumArch) LOOP
          --Limpio mi linea actual
          vsLinea := NULL;
          vsTexto := '';

          --leemos del cursor y agregamos el salto de linea
          --vsLinea := regDatos.Registro || ';' || regDatos.Linea || vsLn;

          vsTexto :=  regDatos.Linea || vsLn;

          --Inserto la linea en el clob
          DBMS_LOB.WRITEAPPEND( vsContenido, LENGTH(vsTexto), vsTexto );

          viContador := viContador + 1;

          if viContador >= 100 then
             -- ir liberando memoria
             commit;

             viContador := 0;
          end if;

      END LOOP;

      commit; -- se aplicapor si no fueron mas de 3000 registros.
      viContador := 0;
      --Una vez afuera del ciclo regreso el LOB
      RETURN vsContenido;

  END f_GeneraArchivo;


  /******************************************************************************
  PROCEDIMIENTO:        p_ObtArchivoNuevo
  OBJETIVO:             Genera un archivo separado por comas (csv), que contiene el
                        reporte de contabilidad para todas las transacciones no
                        reportadas y lo envia al usuario
  ******************************************************************************/
  PROCEDURE p_ObtArchivoNuevo(psFecha VARCHAR2)
  IS

      --Numero de secuencia de generacion de archivo
      vnNumArch            GWBGEFA.GWBGEFA_FILE_NUM%TYPE;
      --Nombre del archivo a generarse
      vsNomArch            GWBGEFA.GWBGEFA_FILE_NAME%TYPE;
      --Hash SHA1 del archivo a generarse
      vrSHA1Digest        GWBGEFA.GWBGEFA_FILE_SHA1_HASH%TYPE;
      --Tamaño del archivo generado
      vnTamano            GWBGEFA.GWBGEFA_FILE_SIZE%TYPE;
      --Numero de registros
      vnNumRegs            GWBGEFA.GWBGEFA_RECORD_NUM%TYPE;
      --El archivo en sí
      vcArchivo            CLOB DEFAULT '';
      --Fecha de corte
      vdFecha             DATE;

      --Usuario de Web
      vsUser              VARCHAR2(30);
      vdInicial           DATE;
      vdFinal             DATE;

     l_in_blob            BLOB;

     l_compressed_blob    BLOB;

     l_uncompressed_blob  BLOB;

     vsArchivo_cblb  clob;

     -- ultima secuencia de registos
     vnLastSeqReg            GWBGEFA.GWBGEFA_RECORD_NUM%TYPE;

  BEGIN
      -- Seguridad de GWAMNUA
      vsUser := 'MALTAMIRANO';

        vcArchivo := EMPTY_CLOB();
       --IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

       --IF PK_Login.F_ValidacionDeAcceso(vsUser) THEN RETURN; END IF;

      vdInicial := NULL;
      vdFinal   := NULL;
      vdInicial := SYSDATE;
      --Obtengo la fecha:
      vdFecha := TO_DATE(SYSDATE,'DD/MM/YYYY');

      -- inicializo a cero
      vnLastSeqReg:= 0;

      --Si la fecha esta nula
      IF vdFecha IS NULL THEN
          HTP.P('No se indico una fecha de corte.');
          RETURN;
      END IF;

      vdFinal := SYSDATE;
      INSERT INTO GWVTCNT VALUES (vdInicial, vdFinal, NULL,'Inicia p_Genera');

      --Genero archivo EVNT.
      --p_Genera(vnNumArch, vnNumRegs, vdFecha,pk_login.vgsUSR);
      p_Genera(vnNumArch, vnNumRegs, vdFecha,vsUser);

      --Verificamos que haya un numero de archivo
      IF vnNumArch IS NULL THEN
          ROLLBACK; --Deshago cualquier cambio
          -- informo al usuario  -- Mensaje general 01
          HTP.P(cgsMsg001);
          RETURN;
      ELSE
          COMMIT ;
      END IF;

      --obtengo el archivo:
      vcArchivo := f_GeneraArchivo(vnNumArch);

      --calculo tamaño del archivo
      vnTamano := LENGTH(vcArchivo);

      --calculo hash SHA-1 del archivo
      vrSHA1Digest := DBMS_CRYPTO.HASH(vcArchivo,DBMS_CRYPTO.HASH_SH1);

      --obtenemos nombre de archivo
      vsNomArch := 'ARCH_EVNT_' || TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS_') || LPAD(TO_CHAR(vnNumArch),10,'0') || '.ZIP';  --  md-01  '.csv' ;

      --inserto datos de auditoria
      pk_UtilCrgEnvArch.p_InsRegAuditArch( cgsCodApp
                                           ,vnNumArch
                                           ,vsNomArch
                                           ,vnTamano
                                           ,vrSHA1Digest
                                           ,vnNumRegs
                                           ,SYSDATE
                                           ,vsUser );

      SELECT MAX(GWBEVNT_SEQ) INTO vnLastSeqReg FROM GWBEVNT;

      INSERT INTO SATURN.GWRBIEV (GWRBIEV_SEQ,GWRBIEV_EVNT_READ,GWRBIEV_FILE_NAME,GWRBIEV_ACTIVITY_DATE,GWRBIEV_USER_ID)
      VALUES (vnLastSeqReg,vnNumRegs,vsNomArch,SYSDATE,vsUser);

      -- md-01 start
      l_in_blob := f_CLOBaBLOB(vcArchivo);

--      --se cambia el archivo de cblob a blob
      l_compressed_blob   := TO_BLOB('0');

--      --ahora el blob creado se crea como un archivo ZIP
      UTL_COMPRESS.lz_compress(l_in_blob, l_compressed_blob);
--
--     -- se regrea el archivo (zip)que es un blob  se vuelve a crear como CBLOB
      vsArchivo_cblb:= pk_UtilCrgEnvArch.f_BLOBaCLOB(l_compressed_blob);
-- md-01 end

     -- se envia archivo para ser descargado en la maq local
     pk_UtilCrgEnvArch.p_EnviaArchTxtHTTP( vsArchivo_cblb
                                          --         vcArchivo  md-01
                                           ,vsNomArch
                                           ,'text/csv' );

      COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
          --si llega a pasar algo cucho :'(
          ROLLBACK; --ROLLBACK!!

          --pantallazo de error.
          pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),
              'pk_ArchEvnt.p_ObtArchivoNuevo', NULL);

  END p_ObtArchivoNuevo;


  /******************************************************************************
  PROCEDIMIENTO:        p_ReimprimeArchivo
  OBJETIVO:             Regenera un archivo csv con anterioridad. La salida
                        HTTP, entregará un archivo csv con nombre identico al
                        original
  PARAMETROS:
  psSecuencia:          Numero original del archivo.
  ******************************************************************************/
  PROCEDURE p_ReimprimeArchivo(
      psNumArch            VARCHAR2
  ) IS

      --Numero de secuencia de generacion de archivo
      vnNumArch            GWBGEFA.GWBGEFA_FILE_NUM%TYPE;
      --Nombre del archivo a generarse
      vsNomArch            GWBGEFA.GWBGEFA_FILE_NAME%TYPE;
      --Hash SHA1 del archivo que se genero originalmente
      vrSHA1Digest        GWBGEFA.GWBGEFA_FILE_SHA1_HASH%TYPE;
      --Hash SHA1 del archivo recien leido
      vrSHA1DigestNew        GWBGEFA.GWBGEFA_FILE_SHA1_HASH%TYPE;
      --Tamaño del archivo generado originalmente
      vnTamano            GWBGEFA.GWBGEFA_FILE_SIZE%TYPE;
      --Tamaño del archivo recien leido
      vnTamanoNew            GWBGEFA.GWBGEFA_FILE_SIZE%TYPE;
      --El archivo en sí
      vcArchivo            CLOB DEFAULT '';
      --Variable para saber si se encontro el archivo
      vbFound                BOOLEAN;
      --El usuario de web
      vsUser                VARCHAR2(30);

      --Cursor para obtener los datos del archivo
      CURSOR cuDatosArch(pnNumArch NUMBER) IS
          SELECT
              GWBGEFA_FILE_NAME
              ,GWBGEFA_FILE_SIZE
              ,GWBGEFA_FILE_SHA1_HASH
          INTO
              vsNomArch
              ,vnTamano
              ,vrSHA1Digest
          FROM
              GWBGEFA
          WHERE
              GWBGEFA_PROCESS = cgsCodApp
              AND GWBGEFA_FILE_NUM = pnNumArch;

  BEGIN

      --Seguridad de GWAMNUA
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      --Convierto el numero de secuencia a numero
      vnNumArch := TO_NUMBER(psNumArch,'9999999999');

      --obtenemos el nombre de archivo, tamaño y hash original
      OPEN cuDatosArch(vnNumArch);
      FETCH cuDatosArch INTO vsNomArch ,vnTamano ,vrSHA1Digest;
      vbFound := cuDatosArch%FOUND;
      CLOSE cuDatosArch;

      --si no hubo archivo
      IF NOT vbFound THEN
          RAISE_APPLICATION_ERROR(-20403,cgsErr20403, TRUE);
      END IF;

      --obtenemos el archivo indicado
      vcArchivo := f_GeneraArchivo(vnNumArch);

      --Si no obtuvimos datos
      IF vcArchivo IS NULL THEN
          RAISE_APPLICATION_ERROR(-20404,cgsErr20404, TRUE);
      END IF;

      --obtengo longitud del archivo recien leido
      vnTamanoNew := LENGTH(vcArchivo);

      --calculo hash SHA-1 del archivo recien leido
      vrSHA1DigestNew := DBMS_CRYPTO.HASH(vcArchivo,DBMS_CRYPTO.HASH_SH1);

      --Verifico que los campos sean identicos en lo nuevo como en lo viejo
      IF vnTamanoNew <> vnTamano OR vrSHA1Digest <> vrSHA1DigestNew THEN
          RAISE_APPLICATION_ERROR(-20405,cgsErr20405, TRUE);
      END IF;

      --si sigo aqui es que el registro esta integro, lo envio al usuario
      pk_UtilCrgEnvArch.p_EnviaArchTxtHTTP(
          vcArchivo
          ,vsNomArch
          ,'text/csv'
      );

  EXCEPTION
      WHEN OTHERS THEN
          --pantallazo de error.
          pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),
              'pk_ArchEvnt.p_ReimprimeArchivo', NULL);
  END p_ReimprimeArchivo;

  /******************************************************************************
  PROCEDIMIENTO:        p_JSONListaArchivos
  OBJETIVO:             Devuelve el listado de archivos generados con anterioridad
                        filtrados en base a los parametros
                        La lista es en formato JSON, Arreglo Bidimensional
                        [ ["numLectura", "nombreArchivo"] ... ]
  PARAMETROS:
  psYear:               Año en que se generaron los archivos
  psMonth:              Mes en que se generaron los archivos
  ******************************************************************************/
  PROCEDURE p_JSONListaArchivos(
      psYear                VARCHAR2
      ,psMonth            VARCHAR2
  ) IS

      CURSOR cuDatos IS
          SELECT
              GWBGEFA_FILE_NUM Numero
              ,GWBGEFA_FILE_NAME Nombre
          FROM
              GWBGEFA
          WHERE
              GWBGEFA_PROCESS = cgsCodApp
              AND EXTRACT(YEAR FROM GWBGEFA_ACTIVITY_DATE) = psYear
              AND EXTRACT(MONTH FROM GWBGEFA_ACTIVITY_DATE) = psMonth
          ORDER BY
              GWBGEFA_FILE_NUM;
      --Contador comun y corriente
      vni                    PLS_INTEGER;
      --Usuario de web
      vsUser                VARCHAR2(30);

  BEGIN
      --Seguridad de GWAMNUA
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      --Indico que va a la salida es JSON
      OWA_UTIL.MIME_HEADER('application/json');

      --Imprimo el corchete inicial
      HTP.PRN('[');

      --inicializo mi contador
      vni := 0;
      FOR regDatos in cuDatos LOOP
          --Imprimo una coma si no es el primer elemento
          IF vni <> 0 THEN HTP.PRN(','); END IF;

          --Imprimo el registro como un arreglo bidimensional
          HTP.PRN('["'||regDatos.Numero||'","'||regDatos.Nombre||'"]');

          vni := vni+1;
      END LOOP;

      --Imprimo el corchete final
      HTP.PRN(']');

      --Se acabo :)
  END p_JSONListaArchivos;


  /******************************************************************************
  PROCEDIMIENTO:        p_Main
  OBJETIVO:            Pagina principal de la aplicación
  ******************************************************************************/
  PROCEDURE p_Main (psParametro IN VARCHAR2 DEFAULT NULL) IS

      --Primer año a mostrarse en el combo de años
      vsFirstYear            VARCHAR2(4) DEFAULT '2013';
      --Ultimo año a mostrarse en el combo de años
      vsLastYear            VARCHAR2(4);

      --Cursor para obtener el año
      CURSOR cuLastYear IS
          SELECT distinct SUBSTR(STVTERM_CODE,1,4)--MAX(SUBSTR(STVTERM_CODE,1,4))
            FROM STVTERM
           WHERE STVTERM_TRMT_CODE IS NOT NULL
            AND to_number(SUBSTR(STVTERM_CODE,1,4)) >=  to_number('2013')
            AND STVTERM_CODE <> '9999'; --EXTRACT(YEAR FROM SYSDATE);

      --Usuario de web
      vsUser                VARCHAR2(30);

  BEGIN

      --Seguridad de aplicacion GWAMNUR
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
      --IF PK_Login.F_ValidacionDeAcceso(vsUser) THEN RETURN; END IF;

      --Obtengo el ultimo año a mostrarse en la lista de años:
      OPEN cuLastYear;
      FETCH cuLastYear INTO vsLastYear;
      CLOSE cuLastYear;

      --Comienza a imprimir header de HTML
      HTP.P(
  '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
  <HTML>
      <HEAD>
          <TITLE>Generaci&oacute;n Archivo Eventos</TITLE>'
      );

      -- META tags de Banner
      -- la aplicación no se guarda en el cache de la maquina.
      PK_ObjHTML.P_NoCache;

      --hoja de estilos de wtailor
      HTP.P(PK_ObjHTML.vgsCssBanner);

      HTP.P('
      </HEAD>'
      );
      --Fin del encabezado

      --Body Completo
      HTP.P('

      <BODY>

          <div style="height:100px;"> </div>
          <h2>
              Generaci&oacute;n Archivo Eventos
          </h2>
          <hr/>
          <br/>
          <table border="0" cellpadding="0" cellspacing="0" width="100%" bgcolor="#efefef" >
              <form name="frmDatos" method="post">
                  <tr>
                      <td valign="top"></td>
                      <td class="etiqueta" valign="middle" style="font-size:16px">
                          Generar Archivo Nuevo:
                      </td>
                      <td valign="top" align="right" ></td>
                  </tr>
                  <tr style="height:12px"><td colspan="3"></td></tr>


                  <tr>
                      <td></td>
                      <td class="etiqueta" valign="middle" align="center">
                          <input type="button" name="cmdOK" value="Generar Archivo Nuevo" />
                      </td>
                      <td></td>
                  </tr>
                  <tr style="height:16px;background-color:#FFFFFF"><td colspan="3"></td></tr>
                <tr>
                    <td valign="top"></td>
                    <td class="etiqueta" valign="middle" style="font-size:16px">
                        Recuperar Archivos Anteriores:
                    </td>
                    <td valign="top" align="right" ></td>
                </tr>
                <tr style="height:12px"><td colspan="3"></td></tr>
                <tr>
                    <td></td>
                    <td class="etiqueta">
                        A&ntilde;o:&nbsp;
                        <select name="cboYear" style="width:60px"></select>
                        &nbsp;
                        &nbsp;

                        Mes:&nbsp;
                        <select name="cboMonth" style="width:100px"></select>
                        &nbsp;
                        &nbsp;

                        <input type="button" name="cmdSearch" value="Buscar" />
                        &nbsp;
                        &nbsp;
                        &nbsp;
                        &nbsp;

                        Archivo:&nbsp;
                        <select name="cboFile" style="width:330px"></select>
                        &nbsp;
                        &nbsp;
                        <input type="button" name="cmdRecover" value="Recuperar" />
                    </td>
                    <td></td>
                </tr>
              </form>
          </table>
          <br/>
          <br/>
          <hr/>

          <form name="frmParams" method="post">
              <input type="hidden" name="psNumArch">
              <input type="hidden" name="psFecha">
          </form>
      </BODY>'
      );



      --Invocacion del archivo js de funciones comunes
      HTP.P('
      <script type="application/javascript" src="pk_UtilWeb.js"></script>'
      );

      --Invocacion del archivo js del calendario
       HTP.P('
       <script type="application/javascript" src="kwacalendario.js"></script>'
      );

      -- Inicio de javascript
      HTP.P('
      <script type="text/javascript">
          //valores obtenidos de la base de datos'
      );

      HTP.P('
          var FirstYear="'||vsFirstYear||'";
          var LastYear="'||vsLastYear||'";'
      );

      HTP.P('
          //variables para los formularios
          var frmDatos = document.frmDatos;
          var frmParams = document.frmParams;

          function ValidaParamsBusqueda(){
              //valida el año
              if( frmDatos.cboYear.value == "" ){
                  alert("Elija un año.");
                  return false;
              }

            //  if( frmDatos.cboMonth.value == "" ){
            //      alert("Elija un mes.");
            //      return false;
            //  }
              return true;
          }

          //funcion para validar si un archivo esta seleccionado
          function ValidaArchivo(){
              if(frmDatos.cboFile.value==""){
                  alert("Seleccione un archivo");
                  return false;
              }
              return true;
          }

          function CargaComboArchivos(str){
              var Arr;
              eval("Arr="+ str);//cargo el contenido de str en Arr

              //limpio el combo de archivos
              LimpiaCombos(frmDatos.cboFile);

              //comienzo la carga
              for(i=0; i<Arr.length; i++){
                  AgregaElementoCombo(frmDatos.cboFile, Arr[i][0], Arr[i][1]);
              }

              //verifico si hay elementos en el combobox
              if(frmDatos.cboFile.length>0){
                  //muestro el boton de recuperar
                  frmDatos.cmdRecover.style.display = "";

                  frmDatos.cboFile.disabled = false;
              }else{
                  //desactivo el boton de recuperar
                  frmDatos.cmdRecover.style.display = "none";

                  frmDatos.cboFile.disabled = true;

                  //indico que no se encontró ningun archivo
                  alert("No se encontraron archivos");
              }
          }

          function BuscarArchivos(){
              //si no son validos los parametros de busqueda, bye...
              if ( ! ValidaParamsBusqueda() ) return;

              //creo el arreglo de parametros
              var prms = [
                  ["psYear",frmDatos.cboYear.value]
                  ,["psMonth",frmDatos.cboMonth.value]
              ];

              //obtengo la lista de archivos que cumplen con las condiciones de busqueda
              ExecAjax("pk_ArchEvnt.p_JSONListaArchivos",prms,CargaComboArchivos);

          }

      //funcion para el boton recuperar
          function Recuperar(){
              //si no se ha seleccionado un archivo, bye...
              if(!ValidaArchivo()) return;

              //indico el destino de la generacion de archivos
              frmParams.action = "pk_ArchEvnt.p_ReimprimeArchivo";

              //si seguimos aqui asigno el numero de secuencia del
              //combo al de la forma
              frmParams.psNumArch.value = frmDatos.cboFile.value;

              //activo el parametro psSecuencia
              frmParams.psNumArch.disabled = false;

              //desactivo el campo de fecha
              frmParams.psFecha.disabled = true;

              //enviamos la peticion
              frmParams.submit();

          }

       //carga los datos en la ventana
          function InicializarPagina(){

              //lleno el combo de años
              AgregaElementoCombo(frmDatos.cboYear,"",""); //elemento hueco
              for(var i=parseInt(FirstYear); i<=parseInt(LastYear); i++)
                  AgregaElementoCombo(frmDatos.cboYear,String(i),String(i));

              //lleno el combo de mes
              ComboMeses(frmDatos.cboMonth);

              //desactivo el boton de recuperacion de archivo:
              frmDatos.cmdRecover.style.display = "none";

              //desactivo el combobox
              frmDatos.cboFile.disabled = true;
          }InicializarPagina();

                //boton de busqueda
              frmDatos.cmdSearch.onclick=BuscarArchivos;

              //boton de recuperar:
              frmDatos.cmdRecover.onclick=Recuperar;


          //envia la forma datos a la pagina de generacion
          function Generar(){

              //indico el destino de la generacion de archivos
              frmParams.action = "pk_ArchEvnt.p_ObtArchivoNuevo";

              //desactivo el parametro psSecuencia
              frmParams.psNumArch.disabled = true;

              //activo el parametro de fecha y asigno valor
              frmParams.psFecha.disabled = false;


              frmParams.submit();
          }

          function AsignarEventos(){

              //asigno los eventos a los controles de la pagina
              //que lo requieran

              //bloqueo de click derecho
              BloquearMenuContxt();

              //boton de generar archivo
              frmDatos.cmdOK.onclick=Generar;

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
              'pk_ArchEvnt.p_Main', NULL);

  END p_Main;


END PK_ARCHEVNT;
/


DROP SYNONYM BANSECR.PK_ARCHEVNT;

CREATE SYNONYM BANSECR.PK_ARCHEVNT FOR BANINST1.PK_ARCHEVNT;


DROP PUBLIC SYNONYM PK_ARCHEVNT;

CREATE PUBLIC SYNONYM PK_ARCHEVNT FOR BANINST1.PK_ARCHEVNT;


GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO CARGAPORTAL;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ARCHEVNT TO WWW2_USER;

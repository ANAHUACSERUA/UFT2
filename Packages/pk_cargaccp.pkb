DROP PACKAGE BODY BANINST1.PK_CARGACCP;

CREATE OR REPLACE PACKAGE BODY BANINST1.pk_CargaCCP IS

/******************************************************************************
PAQUETE:            BANINST1.pk_CargaCCP
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la carga de archivos
AUTOR:              Marcela Altamirano Chan
FECHA:              20100922
******************************************************************************/

    --variable para seguridad GWAMNUR
    vgsUSR              VARCHAR2(500);
    global_aidm         SABNSTU.SABNSTU_AIDM%TYPE;
    global_id           SABNSTU.SABNSTU_ID%TYPE;

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
    psArchivo           VARCHAR2
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

    --variable para el usuario que habia cargado este archivo previamente
    vsUserAnt           GWBAACR.GWBAACR_USER%TYPE;
    --variable para la fecha en que se habia cargado este archivo previamente
    vdFechaAnt          GWBAACR.GWBAACR_ACTIVITY_DATE%TYPE;

    --manejo de errores
    err_num1   NUMBER;
    err_msg1   VARCHAR2 (1999);


    vnExiste NUMBER:= 0;
    vnSEQ   VARCHAR2(6);
    vsCODE  VARCHAR2(6);
    vsCODECNTY  VARCHAR2(6);
    vnSEQCMT VARCHAR2(10);

    vsRegularE VARCHAR2(10) := '^(*[0-9])';
    vsWhere1 VARCHAR2(10) := '999999';
    vsWhere2 VARCHAR2(10) := '999998';


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


  TYPE vsTYP IS REF CURSOR;
  vsTYPAUE vsTYP;


BEGIN

--    Seguridad de GWAMNUR
--    IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

--    Ojo, esta página por sus características, no es del tipo de separación
--    de codigo PL de codigo HTML

--    Inicio de la pagina HTML
   -- DBMS_OUTPUT.PUT_LINE(PK_ObjHTML.vgsCssBanner);

    --obtengo los datos del archivo
    Select
        DOC_SIZE
        ,BLOB_CONTENT
    INTO
        vnTamano
        ,vrArchivoBLOB
    FROM
        GWBDOCS
    WHERE
        NAME = psArchivo;

    --calculo la firma SHA1 del archivo
    vrDigestionSHA1 := DBMS_CRYPTO.HASH(vrArchivoBLOB,DBMS_CRYPTO.HASH_SH1);

    --Muestro los datos del archivo
    p_ImprimeLineaResultado ('Nombre del archivo en servidor: ' || psArchivo);
    p_ImprimeLineaResultado ('Tama&ntilde;o de archivo: ' || vnTamano);
    p_ImprimeLineaResultado ('Firma SHA-1: ' || vrDigestionSHA1);

--    busco que no se haya subido antes este mismo archivo
    BEGIN
        SELECT
            GWBAACR_USER
            ,GWBAACR_ACTIVITY_DATE
        INTO
            vsUserAnt
            ,vdFechaAnt
        FROM
            GWBAACR
        WHERE
            GWBAACR_TAMANO = vnTamano
            AND GWBAACR_HASH_SHA1 = vrDigestionSHA1;

        vsExiste := 'Y';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vsExiste := 'N';
    END;

--    Si existió el archivo indico que no se puede volver a subir este mismo
--    archivo
    IF vsExiste = 'Y' THEN
        --Elimino el archivo recien subido
        DELETE
            GWBDOCS
        WHERE
            NAME = psArchivo;

        COMMIT;

        --Informo al usuario.
        p_ImprimeLineaResultado (
            'Este archivo ya se hab&iacute;a subido anteriormente.');
        p_ImprimeLineaResultado (
            'Usuario: '||vsUserAnt||'. Fecha y Hora: '
            ||TO_CHAR(vdFechaAnt,'YYYY-MM-DD HH24:MI:SS')||'.'
            );
        p_ImprimeLineaResultado ('No se procesar&aacute;.');

        --No tiene mucho caso seguir aqui adentro :p
        RETURN;
    END IF;

    --Obtengo Numero de secuencia de archivo
    --NumProcCarga := pk_Contrato.p_NumSec('PROCESO_CARGA_ARCH');

    --Imprimo el numero de proceso
    p_ImprimeLineaResultado ('N&uacute;mero de proceso: ' || vnNumProcCarga);

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

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 76, 7))),0) = 0) THEN
                vsFPrincipal := NULL;
            ELSE
                vsFPrincipal  :=  TRIM(SUBSTR(vsLinea, 76, 7));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 83, 7))),0) = 0) THEN
                vsFax := NULL;
            ELSE
                vsFax  :=  TRIM(SUBSTR(vsLinea, 83, 7));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 90, 60))),0) = 0) THEN
                vsEmail := NULL;
            ELSE
                vsEmail  :=  TRIM(SUBSTR(vsLinea, 90, 60));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 150, 51))),0) = 0) THEN
                vsDireccion := NULL;
            ELSE
                vsDireccion  :=  TRIM(SUBSTR(vsLinea, 150, 51));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 201, 2))),0) = 0) THEN
                vsREducacional := NULL;
            ELSE
                vsREducacional  :=  TRIM(SUBSTR(vsLinea, 201, 2));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 203, 1))),0) = 0) THEN
                vsRegimen := NULL;
            ELSE
                vsRegimen  :=  TRIM(SUBSTR(vsLinea, 203, 1));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 204, 1))),0) = 0) THEN
                vsDependencia := NULL;
            ELSE
                vsDependencia  :=  TRIM(SUBSTR(vsLinea, 204, 1));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 205, 1))),0) = 0) THEN
                vsGDependencia := NULL;
            ELSE
                vsGDependencia  :=  TRIM(SUBSTR(vsLinea, 205, 1));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 206, 12))),0) = 0) THEN
                vsMPCurso := NULL;
            ELSE
                vsMPCurso  :=  TRIM(SUBSTR(vsLinea, 206, 12));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 218, 12))),0) = 0) THEN
                vsMCurso := NULL;
            ELSE
                vsMCurso  :=  TRIM(SUBSTR(vsLinea, 218, 12));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 230, 47))),0) = 0) THEN
                vsNDirector := NULL;
            ELSE
                vsNDirector  :=  TRIM(SUBSTR(vsLinea, 230, 47));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 277, 47))),0) = 0) THEN
                vsNOrientador := NULL;
            ELSE
                vsNOrientador  :=  TRIM(SUBSTR(vsLinea, 277, 47));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 324, 47))),0) = 0) THEN
                vsRelacionador := NULL;
            ELSE
                vsRelacionador  :=  TRIM(SUBSTR(vsLinea, 324, 47));
            END IF;

            IF (NVL(LENGTH(TRIM(SUBSTR(vsLinea, 371, 6))),0) = 0) THEN
                vsRBD := NULL;
            ELSE
                vsRBD  :=  TRIM(SUBSTR(vsLinea, 371, 6));
            END IF;
                BEGIN
                SELECT COUNT(1) INTO vnExiste FROM SWBCAUE
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
                       SWBCAUE_RELACIONADOR, SWBCAUE_RBD)
                    VALUES (   vsLEducacional,
                              vsUEucacional,
                              vsAProceso,
                              vsNOficial,
                              vsCRegion,
                              vsCProvincia,
                              vsCColumna,
                              vsCPostal,
                              vsDDirecto,
                              vsFPrincipal,
                              vsFax,
                              vsEmail,
                              vsDireccion,
                              vsREducacional,
                              vsRegimen,
                              vsDependencia,
                              vsGDependencia,
                              vsMPCurso,
                              vsMCurso,
                              vsNDirector,
                              vsNOrientador,
                              vsRelacionador,
                              vsRBD  );

                              COMMIT;
                    END IF;
                    EXCEPTION
                    WHEN OTHERS THEN
                        --si llega a pasar algo cucho :'(
                        ROLLBACK;
                        --Indico el error.
                        p_ImprimeLineaResultado('Error: '||sqlcode || '. '|| replace(sqlerrm,'"','\"'));
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
            ' FROM SWBCAUE    '||
            ' WHERE NOT EXISTS (SELECT * FROM STVSBGI WHERE STVSBGI_FICE = SWBCAUE_LEDUCACIONAL||SWBCAUE_UEDUCATIVA ) ' BULK COLLECT


    INTO ADV_ITEMS;
    IF ADV_ITEMS IS NOT NULL THEN
            IF ADV_ITEMS.COUNT > 0 THEN
                FOR I IN ADV_ITEMS.FIRST..ADV_ITEMS.LAST LOOP
                    BEGIN
                        SELECT  TO_CHAR( MAX(STVSBGI_CODE)+1) INTO vnSEQ
                        FROM STVSBGI
                        WHERE  REGEXP_LIKE( STVSBGI_CODE,vsRegularE) AND
                               STVSBGI_CODE <> vsWhere1 AND STVSBGI_CODE <> vsWhere2
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
                        NULL); COMMIT;


                        SELECT NVL(STVSTAT_CODE,00) INTO vsCODE
                        FROM STVSTAT
                        WHERE SUBSTR(STVSTAT_DESC,0,2) = ADV_ITEMS(I).R_CREGION;

                        SELECT NVL(STVCNTY_CODE,00000) INTO vsCODECNTY
                        FROM STVCNTY
                        WHERE SUBSTR(STVCNTY_DESC,0,5) = ADV_ITEMS(I).R_CCOLUMNA;

                        --  2

                        INSERT INTO SOBSBGI (
                        SOBSBGI_SBGI_CODE, SOBSBGI_STREET_LINE1, SOBSBGI_STREET_LINE2,
                        SOBSBGI_STREET_LINE3, SOBSBGI_CITY, SOBSBGI_STAT_CODE,
                        SOBSBGI_CNTY_CODE, SOBSBGI_ZIP, SOBSBGI_NATN_CODE,
                        SOBSBGI_ACTIVITY_DATE)
                        VALUES ( vnSEQ,
                        SUBSTR(ADV_ITEMS(I).R_DIRECCION,0,30),
                        SUBSTR(ADV_ITEMS(I).R_DIRECCION,31,51),
                        NULL,
                        '000000',
                        vsCODE,
                        vsCODECNTY,
                        '0',
                        '39',
                        SYSDATE); COMMIT;

                        --  3
                        SELECT NVL(TO_CHAR( MAX(SORBCMT_SEQNO)+1),'N') INTO vnSEQCMT
                        FROM SORBCMT
                        WHERE  SORBCMT_SBGI_CODE = ADV_ITEMS(I).R_LEDUCACIONAL||ADV_ITEMS(I).R_UEDUCATIVA;

                               INSERT INTO SORBETH (
                        SORBETH_SBGI_CODE, SORBETH_DEMO_YEAR, SORBETH_ETHN_CODE,
                        SORBETH_ETHN_PERCENT, SORBETH_ACTIVITY_DATE)
                        VALUES ( vnSEQ,
                        ADV_ITEMS(I).R_APROCESO,
                        ADV_ITEMS(I).R_REDUCACIONAL,
                        NULL,
                        SYSDATE);

                        --  9
                        INSERT INTO SORBCHR (
                        SORBCHR_SBGI_CODE, SORBCHR_DEMO_YEAR, SORBCHR_BCHR_CODE,
                        SORBCHR_ACTIVITY_DATE)
                        VALUES ( vnSEQ,
                        ADV_ITEMS(I).R_APROCESO,
                        ADV_ITEMS(I).R_GDEPENDENCIA,
                        SYSDATE);

                        --insert into dos values ('problema dependencia',vnSEQ||''||ADV_ITEMS(I).R_APROCESO||ADV_ITEMS(I).R_GDEPENDENCIA);

                        IF vnSEQCMT = 'N' THEN

                            INSERT INTO SORBCMT (
                            SORBCMT_SBGI_CODE, SORBCMT_SEQNO, SORBCMT_COMMENT,
                            SORBCMT_ACTIVITY_DATE)
                            VALUES ( vnSEQ,
                            1,
                            ADV_ITEMS(I).R_NOFICIAL,
                            SYSDATE ); COMMIT;

                        ELSE

                            INSERT INTO SORBCMT (
                            SORBCMT_SBGI_CODE, SORBCMT_SEQNO, SORBCMT_COMMENT,
                            SORBCMT_ACTIVITY_DATE)
                            VALUES (  vnSEQ,
                            vnSEQCMT,
                            ADV_ITEMS(I).R_NOFICIAL,
                            SYSDATE );COMMIT;

                        END IF;

                        --  4

                        IF ADV_ITEMS(I).R_NDIRECTOR IS NOT NULL THEN


                            INSERT INTO SORBCNT (
                            SORBCNT_SBGI_CODE, SORBCNT_NAME, SORBCNT_PTYP_CODE,
                            SORBCNT_PHONE_AREA, SORBCNT_PHONE_NUMBER, SORBCNT_PHONE_EXT,
                            SORBCNT_ACTIVITY_DATE)
                            VALUES (  vnSEQ,
                            ADV_ITEMS(I).R_NDIRECTOR,
                            'PRIN',
                            ADV_ITEMS(I).R_DDIRECTO,
                            ADV_ITEMS(I).R_FPRINCIPAL,
                            NULL,
                            SYSDATE);
                        END IF;

                        --  5
                        IF ADV_ITEMS(I).R_NORIENTADOR <> ADV_ITEMS(I).R_NDIRECTOR THEN

                        IF ADV_ITEMS(I).R_NORIENTADOR IS NOT NULL THEN
                            INSERT INTO SORBCNT (
                            SORBCNT_SBGI_CODE, SORBCNT_NAME, SORBCNT_PTYP_CODE,
                            SORBCNT_PHONE_AREA, SORBCNT_PHONE_NUMBER, SORBCNT_PHONE_EXT,
                            SORBCNT_ACTIVITY_DATE)
                            VALUES ( vnSEQ,
                            ADV_ITEMS(I).R_NORIENTADOR,
                            'ORIE',
                            NULL,
                            NULL,
                            NULL,
                            SYSDATE);
                        END IF;
                    END IF;
                        --  6
                    IF ADV_ITEMS(I).R_NORIENTADOR <> ADV_ITEMS(I).R_RELACIONADOR
                    THEN
                        IF ADV_ITEMS(I).R_RELACIONADOR IS NOT NULL THEN
                            INSERT INTO SORBCNT (
                            SORBCNT_SBGI_CODE, SORBCNT_NAME, SORBCNT_PTYP_CODE,
                            SORBCNT_PHONE_AREA, SORBCNT_PHONE_NUMBER, SORBCNT_PHONE_EXT,
                            SORBCNT_ACTIVITY_DATE)
                            VALUES (  vnSEQ,
                            ADV_ITEMS(I).R_RELACIONADOR,
                            'RELA',
                            NULL,
                            NULL,
                            NULL,
                            SYSDATE);
                        END IF;
                      END IF;
                        --  7
--                        INSERT INTO SORBDMO (
--                        SORBDMO_SBGI_CODE, SORBDMO_DEMO_YEAR, SORBDMO_ENROLLMENT,
--                        SORBDMO_NO_OF_SENIORS, SORBDMO_MEAN_FAMILY_INCOME, SORBDMO_PERC_COLLEGE_BOUND,
--                        SORBDMO_ACTIVITY_DATE)
--                        VALUES ( vnSEQ,
--                        ADV_ITEMS(I).R_APROCESO,
--                        ADV_ITEMS(I).R_MULT_CURSO,
--                        ADV_ITEMS(I).R_MPEN_CURSO,
--                        NULL,
--                        NULL,
--                        SYSDATE);

                        --  8


                        COMMIT;
                    EXCEPTION
                    WHEN OTHERS THEN
                    --INSERT INTO DOS VALUES ('ERROR', 'ERROR');
                        --si llega a pasar algo cucho :'(

                        --Indico el error.
                        p_ImprimeLineaResultado('Error: '||sqlcode || '. '|| replace(sqlerrm,'"','\"'));
                    END;
                END LOOP;

            END IF;
    END IF;



    vgsUsr := NVL(vgsUSR,USER);

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

END pk_CargaCCP;
/


DROP PUBLIC SYNONYM PK_CARGACCP;

CREATE PUBLIC SYNONYM PK_CARGACCP FOR BANINST1.PK_CARGACCP;


GRANT EXECUTE ON BANINST1.PK_CARGACCP TO ADM_ADMISION;

GRANT EXECUTE ON BANINST1.PK_CARGACCP TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_CARGACCP TO WWW2_USER;

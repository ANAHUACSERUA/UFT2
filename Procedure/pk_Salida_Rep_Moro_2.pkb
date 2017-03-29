CREATE OR REPLACE PACKAGE BODY BANINST1.pk_Salida_Rep_Moro_2 IS
/******************************************************************************
PAQUETE:            BANINST1.pk_Salida_Rep_Moro_2
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la generación del archivo de salida CAE Egresados
                    (archivo que se envia de Alumno egresados  al ministerio)
AUTOR:              Roman Ruiz
FECHA:              06-mar-2014
-----------------------------
cambio              md-01
objetivo            se pidieron nuevos parametros
autor               roman ruiz
fecha               15 ene 2015
-----------------------------
cambio              md-02
objetivo            correccion de parametros para reimpresion
autor               roman ruiz
fecha               05 may 2015

******************************************************************************/

    --Mensajes de Error
    cgsErr20401      CONSTANT VARCHAR2(4000) := 'No esta configurada la secuencia para la generacion de archivo Salida CAE MAT Egresados';
    cgsErr20402      CONSTANT VARCHAR2(4000) := 'No se pudo obtener un numero de archivo';
    cgsErr20403      CONSTANT VARCHAR2(4000) := 'No se encontró el archivo especificado';
    cgsErr20404      CONSTANT VARCHAR2(4000) := 'No se encontraron los registros correspondientes al archivo';
    cgsErr20405      CONSTANT VARCHAR2(4000) := 'El archivo recien leido difiere del original. Posible corrupción de datos';
    cgsErr20406      CONSTANT VARCHAR2(4000) := 'No se encontraron los datos del alumno';
    cgsErr20407      CONSTANT VARCHAR2(4000) := 'No se encontraron los datos del apoderado';
    cgsErr20408      CONSTANT VARCHAR2(4000) := 'No esta configurado el Año para proceso CAE';

    --Mensajes en general:
    cgsMsg001        CONSTANT VARCHAR2(4000) :=  'No hay transacciones disponibles para generar el archivo.';

    --Codigo global de la aplicacion 'KEEG'  -de cae Eggresado
    cgsCodApp       CONSTANT VARCHAR2(4) := 'RMM2';                       --md-v
    csDDMMRRRR      CONSTANT  VARCHAR2(21) := 'DD/MM/YYYY HH24:MI:SS';
    csEgresado      constant varchar2(2) := 'EG';
    csTeleFijo      constant varchar2(4) := 'TFPA';
    csTeleCelu      constant varchar2(4) := 'TMPA';
    csMailUft       constant varchar2(3) := 'UFT';
    csDirMa         constant varchar2(2) := 'MA';

    --Tipo para guardar el detalle de una operacion
    TYPE t_DetOper IS RECORD(
        RUT                NUMBER(8),
        DV                 CHAR(1),
        APELLIDO_PAT       VARCHAR2(200),
        APELLIDO_MAT       VARCHAR2(200),
        NOMBRE             VARCHAR2(200),
        TIPO_IES           CHAR(1),
        IES                VARCHAR2(3),
        SEDE               VARCHAR2(3),
        CARRERA            VARCHAR2(4),
        JORNADA            number(1),
        SEQ_NUM            NUMBER(6)
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



PROCEDURE p_AsignaIdxOper(
    phHash    IN OUT NOCOPY    t_HshDets
    ,psId                VARCHAR2
    ,pnIdx                PLS_INTEGER
);

/******************************************************************************
PROCEDIMIENTO:     p_ObtDetOper
OBJETIVO:          se toma la ultima version del rut que no haya sido reportada en
                   el año corriente en twrcarh  , y se analiza si es alumno uft
                   y verifica si es alumno egresado .  y llena el detalle del mismo.

-- ESE  PROCEDIMIENTO NO SE QUITO DEL TODO.. DEBIDO A SI ES NECESARIO EN UN FUTURO
   HACER MAS OPERACIONES  Y NO VOLVER A DECLARAR EN LA ESPECIFICACION DEL PAQUETE

******************************************************************************/
PROCEDURE p_ObtDetOper (psFecha varchar2) is

   rcDetOper              t_DetOper;

BEGIN
 null;

EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),' pk_Salida_Rep_Moro_2.p_ObtDetOper', NULL);

END p_ObtDetOper;


/******************************************************************************
PROCEDIMIENTO:       p_Genera
OBJETIVO:            Generar los registros a para Salida Reporte de morosos 2
PARAMETROS:
pnNumArch:            Parámetro de salida para indicar el número de archivo.
                    Nulo si no hubo registro alguno a reportar.
pnNumRegs:            Número registros procesados / reportados. Nulo si no hubo
                    registro alguno a procesar
psUser:                Usuario que invoco el proceso, si no se especifica se toma
                    el ID de oracle de la conexión.
*****************************  *************************************************/
PROCEDURE p_Genera(
     pnNumArch   OUT        PLS_INTEGER
    ,pnNumRegs  OUT        PLS_INTEGER
    ,pdFecha    IN         DATE DEFAULT SYSDATE
    ,psUser     IN         VARCHAR2 DEFAULT USER
    ,psTodo varchar2                     --md-01
) IS

    --Una tabla de movimientos de documento
    vtMovs                t_TblMovDoc;
    --Tabla para guardar las operaciones ordenadas
    vtOperBase           t_TblOrd := t_TblOrd();
    vtOperOrd            pk_Util.t_TblVarchar2 := pk_Util.t_TblVarchar2();
    --Registro temporal para una operación
    vrDetOper            t_DetOper;
    --El hash table en si
    vhOpers               pk_Salida_Rep_Moro_2.t_HshOper;
    --Este es el mapa de operaciones contra detalles contables
    vhDets                t_HshDets;
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
    viNumEnvios          number(5);
    vsStMov              varchar(2);
    vdInicial            DATE;
    vdFinal              DATE;



  --Cursor del reporte moro 1   --md-v
  /*
    CURSOR cuDatos IS
                   SELECT TWBDOCU_SEQ_NUM                       AS NumSeqDoc
                         ,TWBDOCU_TERM_CODE                     AS Perio
                         ,TWBDOCU_CNTR_NUM                      AS Cntr
                         ,TWBDOCU_PAYM_CODE                     AS MP
                         ,TWBDOCU_AMOUNT                        AS Monto
                         ,TWBDOCU_NOM_AMOUNT                    AS MontoNom
                         ,TWBDOCU_EXPIRATION_DATE               AS FechaVig
                         ,TWBDOCU_DOCU_NUM                      AS NumDocu
                         ,TWBDOCU_BANK_CODE                     AS Banco
                         ,TWBDOCU_CTYP_CODE                     AS TipoTarjeta
                         ,TWBDOCU_PLCE_CODE                     AS Plaza
                         ,TWBDOCU_CURR_ACNT                     AS CuentaCorriente
                         ,TWBDOCU_ENTRY_DATE                    AS FechaCaptura
                         ,TWBDOCU_ENTRY_USER                    AS UsuarioCaptura
                         ,DOMV1.TWRDOMV_STATUS_IND              AS Status
                         ,DOMV1.TWRDOMV_MOVE_DATE               AS FechaStatus
                         ,DOMV1.TWRDOMV_USER                    AS UsuarioStatus
                         ,TWRPRCC_CCTS_CODE                     AS CentrodeCosto
                         ,f_get_rut(twbcntr_pidm)               AS RutAlumno
                         ,spriden_id                            AS IdAlumno
                         ,TWBCNTR_RUT                           as RutApoderado
                         ,(SELECT STVLEVL_DESC FROM STVLEVL WHERE STVLEVL_CODE = SMRPRLE_LEVL_CODE) as Nivel
                   FROM
                          TWBDOCU
                         ,TWRDOMV DOMV1
                         ,TWRPRCC
                         ,TWBCNTR
                         ,spriden
                         ,SMRPRLE
                   WHERE DOMV1.TWRDOMV_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
                     AND DOMV1.TWRDOMV_MOVE_NUM = ( SELECT MAX(DOMV2.TWRDOMV_MOVE_NUM)
                                                      FROM TWRDOMV DOMV2
                                                     WHERE DOMV2.TWRDOMV_DOCU_SEQ_NUM = DOMV1.TWRDOMV_DOCU_SEQ_NUM
                                                    -- AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) >= TRUNC(TO_DATE('01/10/2012','DD/MM/YYYY')) --fecha inicio
                                                     --AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) < TRUNC(SYSDATE + 1) -- fecha fin}
                                                      AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) <=  trunc(pdFecha) )
                     --AND (TWBDOCU_TERM_CODE LIKE '2014%'  )--promocion 2014
                     AND (TWBDOCU_TERM_CODE LIKE to_char(psTodo||'%'))
                     AND TWBCNTR_ORI_PROGRAM = TWRPRCC_PROGRAM
                     AND TWBCNTR_NUM = TWBDOCU_CNTR_NUM
                     and TWBCNTR_PIDM = spriden_PIDM
                     AND TWBCNTR_ORI_PROGRAM = SMRPRLE_PROGRAM
                     and SPRIDEN_CHANGE_IND is null;
                     */

CURSOR cuDatos IS
SELECT TWBDOCU_SEQ_NUM                       AS NumSeqDoc
      ,TWBDOCU_TERM_CODE                     AS Perio
      ,TWBDOCU_CNTR_NUM                      AS Cntr
      ,TWBDOCU_PAYM_CODE                     AS MP
      ,TWBDOCU_AMOUNT                        AS Monto
      ,TWBDOCU_NOM_AMOUNT                    AS MontoNom
      ,TWBDOCU_EXPIRATION_DATE               AS FechaVig
      ,TWBDOCU_DOCU_NUM                      AS NumDocu
      ,TWBDOCU_BANK_CODE                     AS Banco
      ,TWBDOCU_CTYP_CODE                     AS TipoTarjeta
      ,TWBDOCU_PLCE_CODE                     AS Plaza
      ,TWBDOCU_CURR_ACNT                     AS CuentaCorriente
      ,TWBDOCU_ENTRY_DATE                    AS FechaCaptura
      ,TWBDOCU_ENTRY_USER                    AS UsuarioCaptura
      ,DOMV1.TWRDOMV_STATUS_IND              AS Status
      ,DOMV1.TWRDOMV_MOVE_DATE               AS FechaStatus
      ,DOMV1.TWRDOMV_USER                    AS UsuarioStatus
      ,TWRPRCC_CCTS_CODE                     AS CentrodeCosto
      ,f_get_rut(twbcntr_pidm)               AS RutAlumno
      ,spriden_id                            AS IdAlumno
      ,TWBCNTR_RUT                           as RutApoderado
      ,(SELECT STVLEVL_DESC FROM STVLEVL WHERE STVLEVL_CODE = SMRPRLE_LEVL_CODE) as Nivel
FROM
       TWBDOCU
      ,TWRDOMV DOMV1
      ,TWRPRCC
      ,TWBCNTR
      ,spriden
      ,SMRPRLE
WHERE DOMV1.TWRDOMV_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
  AND DOMV1.TWRDOMV_MOVE_NUM = ( SELECT MAX(DOMV2.TWRDOMV_MOVE_NUM)
                                   FROM TWRDOMV DOMV2
                                  WHERE DOMV2.TWRDOMV_DOCU_SEQ_NUM = DOMV1.TWRDOMV_DOCU_SEQ_NUM
                                 -- AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) >= TRUNC(TO_DATE('01/10/2012','DD/MM/YYYY')) --fecha inicio
                                  --AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) < TRUNC(SYSDATE + 1) -- fecha fin}
                                   AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) <=  trunc(pdFecha) )    --md-01
  --AND (TWBDOCU_TERM_CODE LIKE '2014%'  )--promocion 2014
  AND TWBDOCU_TERM_CODE LIKE to_char(psTodo||'%')                     --md-01
  AND TWBCNTR_ORI_PROGRAM = TWRPRCC_PROGRAM
  AND TWBCNTR_NUM = TWBDOCU_CNTR_NUM
  and TWBCNTR_PIDM = spriden_PIDM
  AND TWBCNTR_ORI_PROGRAM = SMRPRLE_PROGRAM
  and SPRIDEN_CHANGE_IND is null
union                                                --md-01 start
SELECT TWBDOCU_SEQ_NUM                       AS NumSeqDoc
      ,TWBDOCU_TERM_CODE                     AS Perio
      ,TWBDOCU_CNTR_NUM                      AS Cntr
      ,TWBDOCU_PAYM_CODE                     AS MP
      ,TWBDOCU_AMOUNT                        AS Monto
      ,TWBDOCU_NOM_AMOUNT                    AS MontoNom
      ,TWBDOCU_EXPIRATION_DATE               AS FechaVig
      ,TWBDOCU_DOCU_NUM                      AS NumDocu
      ,TWBDOCU_BANK_CODE                     AS Banco
      ,TWBDOCU_CTYP_CODE                     AS TipoTarjeta
      ,TWBDOCU_PLCE_CODE                     AS Plaza
      ,TWBDOCU_CURR_ACNT                     AS CuentaCorriente
      ,TWBDOCU_ENTRY_DATE                    AS FechaCaptura
      ,TWBDOCU_ENTRY_USER                    AS UsuarioCaptura
      ,DOMV1.TWRDOMV_STATUS_IND              AS Status
      ,DOMV1.TWRDOMV_MOVE_DATE               AS FechaStatus
      ,DOMV1.TWRDOMV_USER                    AS UsuarioStatus
      ,(select nvl(TWRCCCP_CCTS_CODE, 'NA')
        from   twrdtrt, TWRSERV, tbbdetc, TWRCCCP
        where  TWRSERV_PIDM = TWRDTRT_PIDM
        and    TWRSERV_TRAN_NUMBER = TWRDTRT_TRAN_NUMBER
        and    TWRDTRT_DOCU_SEQ_NUM =  DOMV1.TWRDOMV_DOCU_SEQ_NUM
        and    tbbdetc_detail_code = TWRSERV_DETAIL_CODE
        and    TBBDETC_DETAIL_CODE = TWRCCCP_DETAIL_CODE
        and    rownum = 1)                     AS CentrodeCosto
      ,f_get_rut(SPRIDEN_PIDM)               AS RutAlumno
      ,spriden_id                            AS IdAlumno
      ,''        as RutApoderado
      ,'curso '  as Nivel
FROM  TWRDOMV  DOMV1 , TWBDOCU , SPRIDEN
WHERE DOMV1.TWRDOMV_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
AND DOMV1.TWRDOMV_MOVE_NUM = ( SELECT MAX(DOMV2.TWRDOMV_MOVE_NUM)
                               FROM TWRDOMV DOMV2
                              WHERE DOMV2.TWRDOMV_DOCU_SEQ_NUM = DOMV1.TWRDOMV_DOCU_SEQ_NUM
                             -- AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) >= TRUNC(TO_DATE('01/10/2012','DD/MM/YYYY')) --fecha inicio
                              --AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) < TRUNC(SYSDATE + 1) -- fecha fin}
                                AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) <=  trunc(pdFecha) )
and TWBDOCU_ORIGIN = 'SERV'
AND TWBDOCU_TERM_CODE LIKE to_char( psTodo ||'%' )       --   40268
and TWBDOCU_PIDM = spriden_PIDM
and SPRIDEN_CHANGE_IND is null;


CURSOR cuDatosNullProm IS
SELECT TWBDOCU_SEQ_NUM                       AS NumSeqDoc
      ,TWBDOCU_TERM_CODE                     AS Perio
      ,TWBDOCU_CNTR_NUM                      AS Cntr
      ,TWBDOCU_PAYM_CODE                     AS MP
      ,TWBDOCU_AMOUNT                        AS Monto
      ,TWBDOCU_NOM_AMOUNT                    AS MontoNom
      ,TWBDOCU_EXPIRATION_DATE               AS FechaVig
      ,TWBDOCU_DOCU_NUM                      AS NumDocu
      ,TWBDOCU_BANK_CODE                     AS Banco
      ,TWBDOCU_CTYP_CODE                     AS TipoTarjeta
      ,TWBDOCU_PLCE_CODE                     AS Plaza
      ,TWBDOCU_CURR_ACNT                     AS CuentaCorriente
      ,TWBDOCU_ENTRY_DATE                    AS FechaCaptura
      ,TWBDOCU_ENTRY_USER                    AS UsuarioCaptura
      ,DOMV1.TWRDOMV_STATUS_IND              AS Status
      ,DOMV1.TWRDOMV_MOVE_DATE               AS FechaStatus
      ,DOMV1.TWRDOMV_USER                    AS UsuarioStatus
      ,TWRPRCC_CCTS_CODE                     AS CentrodeCosto
      ,f_get_rut(twbcntr_pidm)               AS RutAlumno
      ,spriden_id                            AS IdAlumno
      ,TWBCNTR_RUT                           as RutApoderado
      ,(SELECT STVLEVL_DESC FROM STVLEVL WHERE STVLEVL_CODE = SMRPRLE_LEVL_CODE) as Nivel
FROM
       TWBDOCU
      ,TWRDOMV DOMV1
      ,TWRPRCC
      ,TWBCNTR
      ,spriden
      ,SMRPRLE
WHERE DOMV1.TWRDOMV_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
  AND DOMV1.TWRDOMV_MOVE_NUM = ( SELECT MAX(DOMV2.TWRDOMV_MOVE_NUM)
                                   FROM TWRDOMV DOMV2
                                  WHERE DOMV2.TWRDOMV_DOCU_SEQ_NUM = DOMV1.TWRDOMV_DOCU_SEQ_NUM
                                   AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) <=  trunc(pdFecha) )
  AND TWBCNTR_ORI_PROGRAM = TWRPRCC_PROGRAM
  AND TWBCNTR_NUM = TWBDOCU_CNTR_NUM
  and TWBCNTR_PIDM = spriden_PIDM
  AND TWBCNTR_ORI_PROGRAM = SMRPRLE_PROGRAM
  and SPRIDEN_CHANGE_IND is null
union
SELECT TWBDOCU_SEQ_NUM                       AS NumSeqDoc
      ,TWBDOCU_TERM_CODE                     AS Perio
      ,TWBDOCU_CNTR_NUM                      AS Cntr
      ,TWBDOCU_PAYM_CODE                     AS MP
      ,TWBDOCU_AMOUNT                        AS Monto
      ,TWBDOCU_NOM_AMOUNT                    AS MontoNom
      ,TWBDOCU_EXPIRATION_DATE               AS FechaVig
      ,TWBDOCU_DOCU_NUM                      AS NumDocu
      ,TWBDOCU_BANK_CODE                     AS Banco
      ,TWBDOCU_CTYP_CODE                     AS TipoTarjeta
      ,TWBDOCU_PLCE_CODE                     AS Plaza
      ,TWBDOCU_CURR_ACNT                     AS CuentaCorriente
      ,TWBDOCU_ENTRY_DATE                    AS FechaCaptura
      ,TWBDOCU_ENTRY_USER                    AS UsuarioCaptura
      ,DOMV1.TWRDOMV_STATUS_IND              AS Status
      ,DOMV1.TWRDOMV_MOVE_DATE               AS FechaStatus
      ,DOMV1.TWRDOMV_USER                    AS UsuarioStatus
      ,(select nvl(TWRCCCP_CCTS_CODE, 'NA')
        from   twrdtrt, TWRSERV, tbbdetc, TWRCCCP
        where  TWRSERV_PIDM = TWRDTRT_PIDM
        and    TWRSERV_TRAN_NUMBER = TWRDTRT_TRAN_NUMBER
        and    TWRDTRT_DOCU_SEQ_NUM =  DOMV1.TWRDOMV_DOCU_SEQ_NUM
        and    tbbdetc_detail_code = TWRSERV_DETAIL_CODE
        and    TBBDETC_DETAIL_CODE = TWRCCCP_DETAIL_CODE
        and    rownum = 1)                     AS CentrodeCosto
      ,f_get_rut(SPRIDEN_PIDM)               AS RutAlumno
      ,spriden_id                            AS IdAlumno
      ,''        as RutApoderado
      ,'curso '  as Nivel
FROM  TWRDOMV  DOMV1 , TWBDOCU , SPRIDEN
WHERE DOMV1.TWRDOMV_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
AND DOMV1.TWRDOMV_MOVE_NUM = ( SELECT MAX(DOMV2.TWRDOMV_MOVE_NUM)
                               FROM TWRDOMV DOMV2
                              WHERE DOMV2.TWRDOMV_DOCU_SEQ_NUM = DOMV1.TWRDOMV_DOCU_SEQ_NUM
                                AND TRUNC(DOMV2.TWRDOMV_MOVE_DATE) <=  trunc(pdFecha) )
and TWBDOCU_ORIGIN = 'SERV'
and TWBDOCU_PIDM = spriden_PIDM
and SPRIDEN_CHANGE_IND is null;

--md-01 end


    TYPE t_Datos IS TABLE OF cuDatos%ROWTYPE;

    --Arreglo donde guardamos las operaciones normales
    vtDatosMov           t_Datos;
    --vtDatosMD            t_Datos;
    vtDatos              t_Datos;


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

    vsAnio := pk_Util.f_ObtieneParam('CAYR','CAE_YEAR');

    --Si no se encontró el nombre de la secuencia mandamos error
    IF vsAnio IS NULL THEN
        RAISE_APPLICATION_ERROR(-20408, cgsErr20408, TRUE);
    END IF;

    -- Generea detalles del registro.
    --p_ObtDetOper(vsAnio);

    --obtengo un nombre NUMERO de archivo
    vnNumArch := pk_Util.f_NumSec(vsNomSeq);

    --Si el numero de archivo fue nulo...
    IF vsNomSeq IS NULL THEN
        RAISE_APPLICATION_ERROR(-20402, cgsErr20402,TRUE);
    END IF;

    --Abro el cursor para registros de morosos --md-01 start

    if psTodo = 'xxxx' then

       OPEN cuDatosNullProm;
          FETCH cuDatosNullProm BULK COLLECT INTO vtDatosMov;
       CLOSE cuDatosNullProm;

    else

       OPEN cuDatos;
          FETCH cuDatos BULK COLLECT INTO vtDatosMov;
       CLOSE cuDatos;

    end if; --md-01 end

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
    vnj := 0;
    vsLinea :=  'NumSeqDoc'        || vsSep
              || 'Perio'           || vsSep
              || 'Cntr'            || vsSep
              || 'Nivel'           || vsSep
              || 'MP'              || vsSep
              || 'Monto'           || vsSep
              || 'MontoNom'        || vsSep
              || 'FechaVig'        || vsSep
              || 'NumDocu'         || vsSep
              || 'Banco'           || vsSep
              || 'TipoTarjeta'     || vsSep
              || 'Plaza'           || vsSep
              || 'CuentaCorriente' || vsSep
              || 'FechaCaptura'    || vsSep
              || 'UsuarioCaptura'  || vsSep
              || 'Status'          || vsSep
              || 'FechaStatus'     || vsSep
              || 'UsuarioStatus'   || vsSep
              || 'CentrodeCosto'   || vsSep
              || 'RutAlumno'       || vsSep
              || 'IdAlumno'        || vsSep
              || 'RutApoderado';

   For vni in 1 .. vtDatos.COUNT LOOP

     IF vni = 1 then
        p_InsertaReg(vnNumArch, vnNumReg, vsLinea, psUser);
     end if;

     --se llena la linea del archivo    --md-v
     vsLinea :=  vtDatos(vni).NumSeqDoc       || vsSep
              || vtDatos(vni).Perio           || vsSep
              || vtDatos(vni).Cntr            || vsSep
              || vtDatos(vni).Nivel           || vsSep
              || vtDatos(vni).MP              || vsSep
              || vtDatos(vni).Monto           || vsSep
              || vtDatos(vni).MontoNom        || vsSep
              || vtDatos(vni).FechaVig        || vsSep
              || vtDatos(vni).NumDocu         || vsSep
              || vtDatos(vni).Banco           || vsSep
              || vtDatos(vni).TipoTarjeta     || vsSep
              || vtDatos(vni).Plaza           || vsSep
              || vtDatos(vni).CuentaCorriente || vsSep
              || vtDatos(vni).FechaCaptura    || vsSep
              || vtDatos(vni).UsuarioCaptura  || vsSep
              || vtDatos(vni).Status          || vsSep
              || vtDatos(vni).FechaStatus     || vsSep
              || vtDatos(vni).UsuarioStatus   || vsSep
              || vtDatos(vni).CentrodeCosto   || vsSep
              || vtDatos(vni).RutAlumno       || vsSep
              || vtDatos(vni).IdAlumno        || vsSep
              || vtDatos(vni).RutApoderado;

       --insertar el renglon en la tabla de salida
       vnNumReg := vnNumReg + 1;
       vnj := vnj + 1;
       p_InsertaReg(vnNumArch, vnNumReg, vsLinea, psUser);

       if vnj = 2000 then
          vnj := 0;
          commit;
       end if;

   END LOOP;-- FIN DEL FOR

   COMMIT;
    --Una vez que genere registros regreso el numero de archivo y el numero de registros
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


/******************************************************************************
FUNCION:            f_GeneraArchivo
OBJETIVO:            Generar un archivo de texto con el detalle contable.
PARAMETROS:
pnNumArch:            Número de archivo a generar/obtener.
VALOR DE RETORNO:     CLOB con el archivo
******************************************************************************/
FUNCTION f_GeneraArchivo(
    psNumArch            PLS_INTEGER
) RETURN CLOB IS

    --El archivo en si
    vsContenido            CLOB;

    --Cursor para leer los datos del archivo
    CURSOR cuDatos(
        psNumArch        VARCHAR2
    ) IS
        SELECT
            TWRAAEP_RECORD        AS Linea
        FROM
            TWRAAEP
        WHERE
            TWRAAEP_FILE_TYPE = cgsCodApp
            AND TWRAAEP_FILE_NUM = psNumArch
        ORDER BY
            TWRAAEP_FILE_TYPE
            ,TWRAAEP_FILE_NUM
            ,TWRAAEP_RECORD_NUM;

    --Salto de linea
    vsLn                VARCHAR2(2) := pk_UtilCrgEnvArch.cgsSalto;
    --Linea del archivo
    vsLinea                VARCHAR2(1000);

BEGIN
    --declaro el espacio temporal para el CLOB
    DBMS_LOB.CREATETEMPORARY(vsContenido,true);

    --abro mi cursor
    FOR regDatos IN cuDatos(psNumArch) LOOP
        --Limpio mi linea actual
        vsLinea := NULL;

        --leemos del cursor y agregamos el salto de linea
        vsLinea := regDatos.Linea || vsLn;

        --Inserto la linea en el clob
        DBMS_LOB.WRITEAPPEND( vsContenido, LENGTH(vsLinea), vsLinea );

    END LOOP;

    --Una vez afuera del ciclo regreso el LOB
    RETURN vsContenido;

END f_GeneraArchivo;

/******************************************************************************
PROCEDIMIENTO:        p_ObtArchivoNuevo
OBJETIVO:            Genera un archivo separado por comas (csv), que contiene el
                    reporte de contabilidad para todas las transacciones no
                    reportadas y lo envia al usuario
******************************************************************************/
PROCEDURE p_ObtArchivoNuevo(psFecha VARCHAR2,
                            psTodo  varchar2)   --md-01
IS

    --Numero de secuencia de generacion de archivo
    vnNumArch            GWBGEFA.GWBGEFA_FILE_NUM%TYPE;
    --Nombre del archivo a generarse
    vsNomArch            GWBGEFA.GWBGEFA_FILE_NAME%TYPE;
    --Hash SHA1 del archivo a generarse
    vrSHA1Digest         GWBGEFA.GWBGEFA_FILE_SHA1_HASH%TYPE;
    --Tamaño del archivo generado
    vnTamano             GWBGEFA.GWBGEFA_FILE_SIZE%TYPE;
    --Numero de registros
    vnNumRegs            GWBGEFA.GWBGEFA_RECORD_NUM%TYPE;
    --El archivo en sí
    vcArchivo            CLOB DEFAULT '';
    --Fecha de corte
    vdFecha              DATE;

    --Usuario de Web
    vsUser              VARCHAR2(30);
    vdInicial           DATE;
    vdFinal             DATE;

BEGIN
    --Seguridad de GWAMNUA
     IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
    --IF PK_Login.F_ValidacionDeAcceso(vsUser) THEN RETURN; END IF;

    vdInicial := NULL;
    vdFinal   := NULL;
    vdInicial := SYSDATE;
    --Obtengo la fecha:
    vdFecha := TO_DATE(psFecha,'DD/MM/YYYY'); -- md-v correr vecha a reporte

    --Si la fecha esta nula
    IF vdFecha IS NULL THEN
        HTP.P('No se indico una fecha de corte.');
        RETURN;
    END IF;

    vdFinal := SYSDATE;
    INSERT INTO GWVTCNT VALUES (vdInicial, vdFinal, NULL,'Inicia p_Genera');

    --Genero archivo CAE.

    p_Genera(vnNumArch, vnNumRegs, vdFecha, pk_login.vgsUSR, psTodo );   --md-01

    --Verificamos que haya un numero de archivo
    IF vnNumArch IS NULL THEN
        ROLLBACK; --Deshago cualquier cambio
        --Le informo al usuario que no mas no hay nada
        --Mensaje general 01
        HTP.P(cgsMsg001);
        --no tiene sentido seguir en este valle de lagrimas
        RETURN;
    END IF;

    --obtengo el archivo:
    vcArchivo := f_GeneraArchivo(vnNumArch);

    --calculo tamaño del archivo
    vnTamano := LENGTH(vcArchivo);

    --calculo hash SHA-1 del archivo
    vrSHA1Digest := DBMS_CRYPTO.HASH(vcArchivo,DBMS_CRYPTO.HASH_SH1);

    --obtenemos nombre de archivo
     --md-04
    vsNomArch := 'UFT_MOROSO_2_'
                 ||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS_')
                 ||LPAD(TO_CHAR(vnNumArch),5,'0')||'.csv';

    --inserto datos de auditoria
    pk_UtilCrgEnvArch.p_InsRegAuditArch(
        cgsCodApp
        ,vnNumArch
        ,vsNomArch
        ,vnTamano
        ,vrSHA1Digest
        ,vnNumRegs
        ,SYSDATE
        ,pk_login.vgsUSR
    );
    --Hago Commit, aqui ya es seguro
    COMMIT;

    --envio el archivo a las manos del usuario jejejejeje
    pk_UtilCrgEnvArch.p_EnviaArchTxtHTTP(
        vcArchivo
        ,vsNomArch
        ,'text/csv'
    );

EXCEPTION
    WHEN OTHERS THEN
        --si llega a pasar algo cucho :'(
        ROLLBACK; --ROLLBACK!!

        --pantallazo de error.
        pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),
            'pk_Salida_Rep_Moro_2.p_ObtArchivoNuevo', NULL);

END p_ObtArchivoNuevo;

/******************************************************************************
PROCEDIMIENTO:        p_ReimprimeArchivo
OBJETIVO:            Regenera un archivo csv con anterioridad. La salida
                    HTTP, entregará un archivo csv con nombre identico al
                    original
PARAMETROS:
psSecuencia:        Numero original del archivo.
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
        SELECT GWBGEFA_FILE_NAME
              ,GWBGEFA_FILE_SIZE
              ,GWBGEFA_FILE_SHA1_HASH
        INTO vsNomArch
            ,vnTamano
            ,vrSHA1Digest
        FROM GWBGEFA
        WHERE GWBGEFA_PROCESS = cgsCodApp
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
    pk_UtilCrgEnvArch.p_EnviaArchTxtHTTP( vcArchivo
                                         ,vsNomArch
                                         ,'text/csv' );

EXCEPTION
    WHEN OTHERS THEN
        --pantallazo de error.
        pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),
            'pk_Salida_Rep_Moro_2.p_ReimprimeArchivo', NULL);
END p_ReimprimeArchivo;

/******************************************************************************
PROCEDIMIENTO:        p_JSONListaArchivos
OBJETIVO:            Devuelve el listado de archivos generados con anterioridad
                    filtrados en base a los parametros
                    La lista es en formato JSON, Arreglo Bidimensional
                    [ ["numLectura", "nombreArchivo"] ... ]
PARAMETROS:
psYear:                Año en que se generaron los archivos
psMonth:            Mes en que se generaron los archivos
******************************************************************************/
PROCEDURE p_JSONListaArchivos(
    psYear                VARCHAR2
    ,psMonth            VARCHAR2
) IS

    CURSOR cuDatos IS
        SELECT  GWBGEFA_FILE_NUM Numero   ,GWBGEFA_FILE_NAME Nombre
        FROM  GWBGEFA
        WHERE GWBGEFA_PROCESS = cgsCodApp
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
    vsFirstYear            VARCHAR2(4) DEFAULT '2010';
    --Ultimo año a mostrarse en el combo de años
    vsLastYear            VARCHAR2(4);

    --Cursor para obtener el año
    CURSOR cuLastYear IS
        SELECT MAX(SUBSTR(STVTERM_CODE,1,4)) + 1
        FROM  STVTERM
        WHERE STVTERM_TRMT_CODE IS NOT NULL
        AND   SUBSTR(STVTERM_CODE,1,4) >= EXTRACT(YEAR FROM SYSDATE)
        and SUBSTR(STVTERM_CODE,1,4) not in ('9999');


    cursor cuAnio is
            SELECT distinct SUBSTR(STVTERM_CODE,1,4) as anio
            FROM STVTERM
            WHERE  STVTERM_TRMT_CODE IS NOT NULL
            and SUBSTR(STVTERM_CODE,1,4) not in ('9999')
            and SUBSTR(STVTERM_CODE,1,4) >= vsFirstYear
            order by SUBSTR(STVTERM_CODE,1,4);

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
        <TITLE>Generaci&oacute;n de Archivo Morosidad 2</TITLE>'
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
          Reporte 2 Morosidad = matriculados promoción Año N
        </h2>
        <h4>
         <p>Filtros <br/>
         Fecha Inicial = blanco<br/>
         Fecha Final  = Fecha de corte seleccionada <br/>
         Promoción    = Año Seleccionado
        </p>
        </h4>
        <hr/>
        <br/>
        <table border="0" cellpadding="0" cellspacing="0" width="100%" bgcolor="#efefef" >
            <form name="frmDatos" method="post">
                <tr>
                    <td valign="top"></td>
                    <td class="etiqueta" valign="middle" style="font-size:16px">
                        Generar Archivo Nuevo:
                    </td>
                </tr>
                <tr>
                    <td>  </td>
                    <td class="etiqueta" align="rigth">
                        Promocion :

                    <select name="psAnio"  valign="middle"  style="width:200px" >
                       <option value="xxxx"> Todos </option> ');
                        ------curosr  de tipo de anio
                        FOR regta IN cuAnio LOOP
                                 htp.p('<option value="'||regta.anio||'">'||regta.anio||'</option>');
                        END LOOP;

        htp.p('     </select>
                 </td>
                 <td></td>
               </tr>
               <tr>
                  <td></td>
                    <td class="etiqueta"  align="rigth">
                        Fecha de corte:
                        <input name="txtFecha" type="text" />

                        <img src="/imagenes/calendario_sin.gif" id="imgCal" onclick="show_calendar('|| chr(39)||'frmDatos.txtFecha'|| chr(39)||');" />

                        <br/>
                    </td>
                    <td></td>
                </tr>

                <tr>
                    <td></td>
                    <td class="etiqueta" valign="middle" align="center">
                        <input type="button" name="cmdOK" value="Generar Archivo Nuevo" />
                    </td>
                    <td></td>
                </tr>

                <tr style="height:16px;background-color:#FFFFFF">
                    <td colspan="3"></td>
                </tr>

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
            <input type="hidden" name="psAnio">
            <input type="hidden" name="psTodo">
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
            ExecAjax("pk_Salida_Rep_Moro_2.p_JSONListaArchivos",prms,CargaComboArchivos);

        }

    //funcion para el boton recuperar
        function Recuperar(){
            //si no se ha seleccionado un archivo, bye...
            if(!ValidaArchivo()) return;

            //indico el destino de la generacion de archivos
            frmParams.action = "pk_Salida_Rep_Moro_2.p_ReimprimeArchivo";

            //si seguimos aqui asigno el numero de secuencia del
            //combo al de la forma
            frmParams.psNumArch.value = frmDatos.cboFile.value;

            //activo el parametro psSecuencia
            frmParams.psNumArch.disabled = false;

            //desactivo el campo de fecha
            frmParams.psFecha.disabled = true;
            //md-02 ini
            frmParams.psAnio.disabled = true;
            frmParams.psTodo.disabled = true;
            //md-02 end 
            

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

            //Calendario
//            frmDatos.imgCal.onclick=function(){
//                show_calendar("frmDatos.txtFecha");
//            }

//            frmDatos.imgCal.onmouseover=imgCal.onmouseup=function(){
//                frmDatos.imgCal.src = "/imagenes/calendario_over.gif"
//            }

//            frmDatos.imgCal.onmouseout=function(){
//                frmDatos.imgCal.src = "/imagenes/calendario_sin.gif"
//            }

//            frmDatos.imgCal.onmousedown=function(){
//                frmDatos.imgCal.src = "/imagenes/calendario.gif"
//            }

        }InicializarPagina();

              //boton de busqueda
            frmDatos.cmdSearch.onclick=BuscarArchivos;

            //boton de recuperar:
            frmDatos.cmdRecover.onclick=Recuperar;

        function ValidaNuevo(){
            //valido fecha de corte

            if(frmDatos.txtFecha.value==""){
                alert("No se especifico una fecha valida.");
                frmDatos.txtFecha.focus();
                return false;
            }

            var val = frmDatos.txtFecha.value;

            //verificar el formato de la cadena
            var rx = /[0-3][0-9]\/[01][0-9]\/[0-9]{4}/;
            if(!rx.test(val)){
                alert("No se especifico una fecha valida.");
                frmDatos.txtFecha.focus();
                return false;
            }

            //solo me falta verificar que la fecha sea correcta:
            if(!ValidaFecha(val.substr(0,2),val.substr(3,2),val.substr(6,4))){
                alert("No se especifico una fecha valida.");
                frmDatos.txtFecha.focus();
                return false;
            }

            //Si llegue aqui es que todo esta ok
            return true;
        }

        //envia la forma datos a la pagina de generacion
        function Generar(){
           // if(!ValidaNuevo()) return;

            //indico el destino de la generacion de archivos
            frmParams.action = "pk_Salida_Rep_Moro_2.p_ObtArchivoNuevo";

            //desactivo el parametro psSecuencia
            frmParams.psNumArch.disabled = true;
            frmParams.psAnio.disabled = true;

            //activo el parametro de fecha y asigno valor
            frmParams.psFecha.disabled = false;
            frmParams.psTodo.disabled = false;

            frmParams.psFecha.value = frmDatos.txtFecha.value;
            frmParams.psTodo.value =  frmDatos.psAnio.value;

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
            'pk_Salida_Rep_Moro_2.p_Main', NULL);

END p_Main;


/******************************************************************************
PROCEDIMIENTO:        p_AsignaIdxOper
OBJETIVO:            Inserta una referencia (indice) en el hash table de
                    referencias a movimientos.
PARAMETROS:
phHash                Parametro de paso por referencia. Hash table donde se
                    guardan las listas/arreglos de referencia hacia la
                    collecion de movimientos,
psId                Id. de la operación
pnIdx                Indice en el arreglo de movimiento
******************************************************************************/
PROCEDURE p_AsignaIdxOper(
    phHash    IN OUT NOCOPY    t_HshDets
    ,psId                VARCHAR2
    ,pnIdx                PLS_INTEGER
) IS

BEGIN

    --Si no existe el elemento en el hash, lo creo
    IF NOT phHash.EXISTS(psId) THEN
        phHash(psId) := t_Dets();
    END IF;

    --Se supone que aqui tendría que hacer una validación para no insertar
    --duplicados, pero teoricamente este procedimiento solo se invoca
    --usa sola vez por operación, entonces supongo que no debiese haber lio
    phHash(psId).EXTEND(1);
    phHash(psId)(phHash(psId).COUNT) := pnIdx;

    --Se acabo ;)

END p_AsignaIdxOper;



END pk_Salida_Rep_Moro_2;
/

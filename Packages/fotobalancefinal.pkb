CREATE OR REPLACE PACKAGE BODY BANINST1.pk_FotoBalanceFinal IS
/******************************************************************************
PAQUETE:            BANINST1.pk_FotoBalanceFinal   --BANINST1.pk_Salida_CAE_Egresados
OBJETIVO:           Contiene los procedimientos, funciones y variables
                    requeridos para la generación una foto de un balance de matriculdos
                    a cierto dia configurado 31 abril y 31 marzo
AUTOR:              Roman Ruiz
FECHA:              27-oct-2014


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
    cgsCodApp       CONSTANT VARCHAR2(4) := 'FOBF';
    csMarzo         constant varchar2(5) := 'dia_1';
    csAbril         constant varchar2(5) := 'dia_2';
    csDDMMRRRR      CONSTANT  VARCHAR2(21) := 'DD/MM/YYYY HH24:MI:SS';

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
PROCEDIMIENTO:       p_Genera
OBJETIVO:            Generar los registros a para Salida CAE Superior.
PARAMETROS:
pnNumArch:            Parámetro de salida para indicar el número de archivo.
                    Nulo si no hubo registro alguno a reportar.
pnNumRegs:            Número registros procesados / reportados. Nulo si no hubo
                    registro alguno a procesar
pdFecha                fecha donde solo se utiliza el año para tomar info CAE
psUser:                Usuario que invoco el proceso, si no se especifica se toma
                    el ID de oracle de la conexión.
*****************************  *************************************************/
PROCEDURE p_Genera(
    pnNumArch   OUT        PLS_INTEGER
    ,pnNumRegs  OUT        PLS_INTEGER
    ,pdFecha    IN         DATE DEFAULT SYSDATE
    ,psUser     IN         VARCHAR2 DEFAULT USER
) IS

    --Una tabla de movimientos de documento
    vtMovs                t_TblMovDoc;

    --Tabla para guardar las operaciones ordenadas
    vtOperBase           t_TblOrd := t_TblOrd();
    vtOperOrd            pk_Util.t_TblVarchar2 := pk_Util.t_TblVarchar2();
    --Registro temporal para una operación
    vrDetOper            t_DetOper;
    --El hash table en si
    vhOpers               pk_FotoBalanceFinal.t_HshOper;
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
    vIX                    PLS_INTEGER;
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
    
    vs_FechaAbril        varchar2(12);
    vs_FechaMarzo        varchar2(12);
    vs_FechaEjecuta      varchar2(12);
    
    vsTerm          varchar2(6) := null;
    vnTermAct       varchar2(6) := null;
    vnTermAnt       varchar2(6) := null;
    vsPropsu_ant    varchar2(50) := null; 
    vsPropsu_act    varchar2(50) := null;     
    vdDiaEjecuta    date; 
    vsAnioEjecuta   varchar2(4);
    vsFotoMes       number(3); 
    

        --Cursor con los movimientos del CAE
    CURSOR cur_BalFinal IS
       SELECT DISTINCT spbpers_name_suffix                                                              RUT,
              SPRIDEN_ID                                                                                ID,
              UPPER(REPLACE(REPLACE(SPRIDEN_LAST_NAME, '*', ' '), '  ', ' ' ))                          APELLIDOS,
              UPPER(REPLACE(REPLACE(SPRIDEN_FIRST_NAME||' '||SPRIDEN_MI,'   ', ' '), '  ', ' '))        NOMBRE,
              A.SGBSTDN_STST_CODE                                                                       STATUS,
              (SELECT STVSTST_DESC FROM STVSTST
               WHERE STVSTST_CODE=A.SGBSTDN_STST_CODE)                                                  DESC_STATUS,
              (SELECT SPRADDR_CNTY_CODE||' '||STVCNTY_DESC FROM SPRADDR, STVCNTY
               WHERE SPRADDR_ATYP_CODE = 'PR'
               AND SPRADDR_CNTY_CODE = STVCNTY_CODE
               AND SPRADDR_PIDM = A.SGBSTDN_PIDM
               AND ROWNUM = 1)                                                                          COMUNA_RESIDENCIA,
              (SELECT SPRADDR_STAT_CODE||' '||STVSTAT_DESC FROM SPRADDR, STVSTAT
               WHERE SPRADDR_ATYP_CODE = 'PR'
               AND SPRADDR_STAT_CODE = STVSTAT_CODE
               AND SPRADDR_PIDM = A.SGBSTDN_PIDM
               AND ROWNUM = 1)                                                                          REGION_RESIDENCIA,
              A.SGBSTDN_PROGRAM_1                                                                       PROGRAMA,
              decode(TWBCNTR_STATUS_IND,'A',TWBCNTR_NUM,null)                                           CONTRATO,
              decode(TWBCNTR_STATUS_IND,'A',twbcntr_issue_date,null)                                    FECHA_CONTRATO,
              (SELECT X.SARADAP_ADMT_CODE FROM SARADAP X, sarappd Y
               WHERE X.SARADAP_PIDM = A.SGBSTDN_PIDM
               and x.saradap_pidm = y.sarappd_pidm
               and x.saradap_appl_no = sarappd_appl_no
               and SARAPPD_APDC_CODE in ('CO','IN','C2')
               AND X.SARADAP_TERM_CODE_ENTRY = A.SGBSTDN_TERM_CODE_EFF
               AND X.SARADAP_PROGRAM_1 = A.SGBSTDN_PROGRAM_1
               AND ROWNUM = 1)                                                                          TIPO_ADMISION,
              (SELECT STVADMT_DESC  FROM STVADMT
               WHERE STVADMT_CODE = SGBSTDN_ADMT_CODE)                                                  DESC_TIPO_ADMISION,
              SWVTAVI_RTYP_CODE                                                                         VIA,
              (SELECT STVRTYP_DESC FROM STVRTYP
               WHERE STVRTYP_CODE = SWVTAVI_RTYP_CODE)                                                  DESC_VIA_INGRESO,
              (SELECT X.SARADAP_APPL_PREFERENCE FROM SARADAP X
               WHERE X.SARADAP_PIDM = A.SGBSTDN_PIDM
               AND X.SARADAP_TERM_CODE_ENTRY = A.SGBSTDN_TERM_CODE_EFF
               AND X.SARADAP_PROGRAM_1 = A.SGBSTDN_PROGRAM_1
               AND X.SARADAP_APPL_NO = (select max(Y.SARADAP_APPL_NO) from saradap y
                                         WHERE A.SGBSTDN_PIDM = Y.SARADAP_PIDM
                                           AND A.SGBSTDN_TERM_CODE_EFF = Y. SARADAP_TERM_CODE_ENTRY
                                           AND A.SGBSTDN_PROGRAM_1 = Y.SARADAP_PROGRAM_1)
                                           AND ROWNUM = 1)                                              PREFERENCIA,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PEM',1,vnTermAct,null)                                       PEM,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'NEME',1,vnTermAct,null)                                      NEME,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PSCI',2,null,vnTermAnt)                                      PSCI_ANTERIOR,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PETE',2,null,vnTermAnt)                                      PETE_ANTERIOR,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PPSU',2,null,vnTermAnt)                                      PPSU_ANTERIOR,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PSHC',2,null,vnTermAnt)                                      PSHC_ANTERIOR,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PSLC',2,null,vnTermAnt)                                      PSLC_ANTERIOR,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PSMA',2,null,vnTermAnt)                                      PSMA_ANTERIOR,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PRAN',2,null,vnTermAnt)                                      PRAN_ANTERIOR,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PSCI',1,vnTermAct,null)                                      PSCI_ACTUAL,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PSHC',1,vnTermAct,null)                                      PSHC_ACTUAL,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PSLC',1,vnTermAct,null)                                      PSLC_ACTUAL,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PPSU',1,vnTermAct,null)                                      PPSU_ACTUAL,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PRAN',1,vnTermAct,null)                                      PRAN,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PETE',1,vnTermAct,null)                                      PETE_ACTUAL,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PSMA',1,vnTermAct,null)                                      PSMA_ACTUAL,
              F_PUNTAJES (A.SGBSTDN_PIDM, 'PRAN',1,vnTermAct,null)                                      PRAN_ACTUAL,
              F_PONDERADOS (A.SGBSTDN_PIDM, A.SGBSTDN_PROGRAM_1,1,vnTermAct,null)                       PONDERADO_UFT_ACTUAL,
              F_PONDERADOS (A.SGBSTDN_PIDM, A.SGBSTDN_PROGRAM_1,2,null,vnTermAnt)                       PONDERADO_UFT_ANTERIOR,
              SPBPERS_SEX                                                                               SEXO,
              (select UPPER(PK_CATALOGO.PREPARATORIA (SORHSCH_SBGI_CODE))
               from SORHSCH
               where SORHSCH_PIDM = A.SGBSTDN_PIDM
               and rownum = 1)                                                                          COLEGIO,
              (select  (SORHSCH_SBGI_CODE)
               from SORHSCH
               where SORHSCH_PIDM = A.SGBSTDN_PIDM
               and rownum = 1)                                                                          CODIGO_COLEGIO,
              (select  (SORBCHR_BCHR_CODE)
               from SORHSCH,SORBCHR
               where SORHSCH_PIDM = A.SGBSTDN_PIDM
               AND SORBCHR_SBGI_CODE = SORHSCH_SBGI_CODE
               AND ROWNUM = 1)                                                                          CODIGO_DEPENDENCIA,
              (select  STVBCHR_DESC 
               FROM SORHSCH, SORBCHR, STVBCHR
               where SORHSCH_PIDM = A.SGBSTDN_PIDM
               AND SORBCHR_SBGI_CODE = SORHSCH_SBGI_CODE
               AND SORBCHR_BCHR_CODE = STVBCHR_CODE
               AND ROWNUM = 1)                                                                          DESC_DEPENDENCIA,
              (select SOBSBGI_STAT_CODE
               from SORHSCH,SOBSBGI
               where SORHSCH_PIDM = A.SGBSTDN_PIDM
               and SORHSCH_SBGI_CODE = SOBSBGI_SBGI_CODE
               and rownum = 1)                                                                          REGION_COL,
              (select SOBSBGI_CNTY_CODE
               from SORHSCH, SOBSBGI
               where SORHSCH_PIDM = A.SGBSTDN_PIDM
               and SORHSCH_SBGI_CODE = SOBSBGI_SBGI_CODE
               and rownum = 1)                                                                          COMUNA_COL,
              (SELECT SUBSTR(SARQUAN_ANSWER,1,3)||','||SUBSTR(SARQUAN_ANSWER,4,2) 
               from sarquan g, saradap X, SARAPPD Y
               where g.SARQUAN_ADMR_CODE = 'PPON'
               AND g.SARQUAN_PIDM = A.SGBSTDN_PIDM
               and g.SARQUAN_PIDM = X.saradap_pidm
               AND X.SARADAP_PIDM = Y.SARAPPD_PIDM
               AND X.SARADAP_APPL_NO = Y.SARAPPD_APPL_NO
               AND Y.SARAPPD_APDC_CODE IN ('CO','IN','C2')
               AND g.SARQUAN_TERM_CODE_ENTRY = X.SARADAP_TERM_CODE_ENTRY
               and g.SARQUAN_TERM_CODE_ENTRY = A.SGBSTDN_TERM_CODE_EFF
               and SARQUAN_APPL_NO = X.SARADAP_APPL_NO
               and rownum = 1)                                                                          PPON,
              (select SARQUAN_ANSWER
               from sarquan g, saradap x, SARAPPD Y
               where g.SARQUAN_ADMR_CODE = 'AÑOA'
               and g.SARQUAN_PIDM = A.SGBSTDN_PIDM
               and g.SARQUAN_PIDM = x.saradap_pidm
               AND g.SARQUAN_TERM_CODE_ENTRY = x.SARADAP_TERM_CODE_ENTRY
               AND x.SARADAP_PIDM = Y.SARAPPD_PIDM
               AND x.SARADAP_APPL_NO = Y.SARAPPD_APPL_NO
               AND Y.SARAPPD_APDC_CODE IN ('CO','IN','C2')
               and SARQUAN_APPL_NO = x.SARADAP_APPL_NO
               and rownum = 1)                                                                          ANOA,
              (SELECT 'Si'
               FROM TWBRETR
               WHERE TWBRETR_CNTR_NUM = TWBCNTR_NUM)                                                    Retracto,
              (SELECT 'Si'
               FROM SFRWDRL
               WHERE SFRWDRL_PIDM = A.SGBSTDN_PIDM
               AND SFRWDRL_TERM_CODE = A.SGBSTDN_TERM_CODE_EFF
               AND SFRWDRL_WDRL_CODE = 'R2')                                                            Ext
       FROM SPRIDEN
           ,SPBPERS
           ,SMRPRLE
           ,SGBSTDN A
           ,SWVTAVI
           ,TWBCNTR
           ,SARAATT
       WHERE SPRIDEN_PIDM = SPBPERS_PIDM
       AND SPRIDEN_CHANGE_IND IS NULL
       AND SPBPERS_PIDM = TWBCNTR_PIDM
       AND A.SGBSTDN_PIDM = TWBCNTR_PIDM
       AND SWVTAVI_ADMT_CODE = SGBSTDN_ADMT_CODE
       AND SWVTAVI_RTYP_CODE IN ('AR', 'AE','AC')
       AND FWATYALUFT(TWBCNTR_PIDM, TWBCNTR_TERM_CODE) = 'N'
       AND SWVTAVI_TERM_CODE = TWBCNTR_TERM_CODE
       AND EXISTS (SELECT 1 FROM SARADAP
                   WHERE SARADAP_PIDM = TWBCNTR_PIDM
                   AND SARADAP_TERM_CODE_ENTRY = A.SGBSTDN_TERM_CODE_EFF
                   AND SARADAP_PROGRAM_1 = A.SGBSTDN_PROGRAM_1)
       AND SARAATT_TERM_CODE = TWBCNTR_TERM_CODE
       AND SARAATT_PIDM = TWBCNTR_PIDM
       AND TWBCNTR_TERM_CODE = vsTerm
       AND SGBSTDN_TERM_CODE_EFF = vsTerm
       AND A.SGBSTDN_PROGRAM_1 is not null
       -- and A.SGBSTDN_PROGRAM_1  = 'LC-PERI-14'  --md-x
       AND TWBCNTR_STATUS_IND = 'A'
       AND A.SGBSTDN_STYP_CODE IN('N','D','R')
       AND TWBCNTR_ISSUE_DATE <= vdDiaEjecuta;
       

    cursor cur_Term is
           select swvcpsu_term_code_previous, swvcpsu_term_code_present
           from  swvcpsu
           where SWVCPSU_ACYR_CODE = vsAnioEjecuta;

BEGIN
    --Establezco un savepoint
    SAVEPOINT InicioArchivo;
    vdInicial := NULL;
    vdFinal   := NULL;
    vdInicial := SYSDATE;

    --Indico los valores de salida como nulos
    pnNumArch := NULL;
    pnNumRegs := NULL;
    
    vdDiaEjecuta  := pdFecha;   -- parametro
    vsAnioEjecuta := to_char(vdDiaEjecuta, 'YYYY'); 

    --Obtengo el nombre de la secuencia de los parametros de la aplicacion
    vsNomSeq := pk_Util.f_ObtieneParam(cgsCodApp,'NUM_EXEC');
    
    --Si no se encontró el nombre de la secuencia mandamos error
    IF vsNomSeq IS NULL THEN
        RAISE_APPLICATION_ERROR(-20401, cgsErr20401, TRUE);
    END IF;

    vnNumArch := pk_Util.f_NumSec(vsNomSeq);

       --Si el numero de archivo fue nulo...
    IF vsNomSeq IS NULL THEN
        RAISE_APPLICATION_ERROR(-20402, cgsErr20402,TRUE);
    END IF;
    
    vnTermAnt := null;
    vnTermAct := null; 
    -- obteniendo term actual y term previo
    FOR cuTerm in cur_Term loop
        vnTermAnt := cuTerm.swvcpsu_term_code_previous; 
        vnTermAct := cuTerm.swvcpsu_term_code_present;     
    end loop; 

    -- en caso de no exitir terms  son construidos.
    if vnTermAct is null then
       vnTermAct := vsAnioEjecuta || '10';
    end if;
    if vnTermAnt is null then
       vnTermAnt := ( to_number(vsAnioEjecuta) - 1 ) || '10';
    end if;   
    
    vsTerm := vnTermAct;
    
    vni := 0;  
    vIX := 0; 
    
    for cuBalFin in cur_BalFinal loop      
      
      vni := vni + 1 ;
      vIX := vIX + 1 ; 
      
      if vni = 1 then 
        -- encabezado del reporte o nombres de columnas 
         vsLinea := 'RUT'                            || vsSep
                 || 'ID'                             || vsSep
                 || 'Apellidos'                      || vsSep
                 || 'Nombre'                         || vsSep
                 || 'Comuna Residencia'              || vsSep
                 || 'Región Residencia'              || vsSep
                 || 'Programa'                       || vsSep
                 || 'Contrato'                       || vsSep
                 || 'Status'                         || vsSep
                 || 'Descripción Status'             || vsSep
                 || 'Fecha Contrato'                 || vsSep
                 || 'Tipo Admisión'                  || vsSep
                 || 'Descripción Admisión'           || vsSep
                 || 'Vía Admisión'                   || vsSep
                 || 'Descripción VíaAdmisión'        || vsSep
                 || 'Preferencia'                    || vsSep
                 || 'PEM'                            || vsSep
                 || 'NEME'                           || vsSep
                 || 'PSCI Anterior'                  || vsSep
                 || 'PSHC Anterior'                  || vsSep
                 || 'PSLC Anterior'                  || vsSep
                 || 'PSMA Anterior'                  || vsSep
                 || 'PRAN Anterior'                  || vsSep
                 || 'PETE Anterior'                  || vsSep
                 || 'PSU Anterior'                   || vsSep
                 || 'Ponderado Anterior'             || vsSep
                 || 'PSCI Actual'                    || vsSep
                 || 'PSHC Actual'                    || vsSep
                 || 'PSLC Actual'                    || vsSep
                 || 'PSMA Actual'                    || vsSep
                 || 'PRAN Actual'                    || vsSep
                 || 'PETE Actual'                    || vsSep
                 || 'PSU Actual'                     || vsSep
                 || 'Ponderado Actual'               || vsSep
                 || 'Puntaje Ponderado de Selección' || vsSep
                 || 'Año Académico de las pruebas'   || vsSep
                 || 'Sexo'                           || vsSep
                 || 'Código Colegio'                 || vsSep
                 || 'Colegio'                        || vsSep
                 || 'Región'                         || vsSep
                 || 'Comuna'                         || vsSep
                 || 'Dependencia Colegio'            || vsSep
                 || 'Descipción Dependencia Colegio' || vsSep
                 || 'Retracto'                       || vsSep
                 || 'Retracto Extemporáneo'          || vsSep; 
                 
          p_InsertaReg(vnNumArch, 1, vsLinea, psUser); 
          
          vni := vni + 1 ;     
      
      end if; 

      vsPropsu_ant := null; 
      vsPropsu_act := null; 
    
      SELECT 
             CASE
                 WHEN ROUND((TO_NUMBER(REPLACE(nvl(cuBalFin.PSLC_ANTERIOR,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(cuBalFin.PSMA_ANTERIOR,0) , ',', '.')))/2,2) = 0 
                     THEN null
                 WHEN ROUND((TO_NUMBER(REPLACE(nvl(cuBalFin.PSLC_ANTERIOR,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(cuBalFin.PSMA_ANTERIOR,0) , ',', '.')))/2,2) <> 0 
                     THEN replace(ROUND((TO_NUMBER(REPLACE(nvl(cuBalFin.PSLC_ANTERIOR,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(cuBalFin.PSMA_ANTERIOR,0) , ',', '.')))/2,2),'.',',')
             END ,
             CASE
                 WHEN ROUND((TO_NUMBER(REPLACE(nvl(cuBalFin.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(cuBalFin.PSMA_ACTUAL,0) , ',', '.')))/2,2) = 0
                     THEN null
                 WHEN ROUND((TO_NUMBER(REPLACE(nvl(cuBalFin.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(cuBalFin.PSMA_ACTUAL,0) , ',', '.')))/2,2) <> 0
                     THEN replace(ROUND((TO_NUMBER(REPLACE(nvl(cuBalFin.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(cuBalFin.PSMA_ACTUAL,0) , ',', '.')))/2,2),'.',',')
             END
                 into vsPropsu_ant,vsPropsu_act
      from dual;   
      
      vsLinea :=  cuBalFin.RUT                    || vsSep 
                 || cuBalFin.ID                     || vsSep
                 || cuBalFin.APELLIDOS              || vsSep
                 || cuBalFin.NOMBRE                 || vsSep
                 || cuBalFin.COMUNA_RESIDENCIA      || vsSep
                 || cuBalFin.REGION_RESIDENCIA      || vsSep
                 || cuBalFin.PROGRAMA               || vsSep
                 || cuBalFin.CONTRATO               || vsSep
                 || cuBalFin.STATUS                 || vsSep
                 || cuBalFin.DESC_STATUS            || vsSep
                 || cuBalFin.FECHA_CONTRATO         || vsSep
                 || cuBalFin.TIPO_ADMISION          || vsSep
                 || cuBalFin.DESC_TIPO_ADMISION     || vsSep 
                 || cuBalFin.VIA                    || vsSep
                 || cuBalFin.DESC_VIA_INGRESO       || vsSep
                 || cuBalFin.PREFERENCIA            || vsSep
                 || cuBalFin.PEM                    || vsSep
                 || cuBalFin.NEME                   || vsSep
                 || cuBalFin.PSCI_ANTERIOR          || vsSep
                 || cuBalFin.PSHC_ANTERIOR          || vsSep
                 || cuBalFin.PSLC_ANTERIOR          || vsSep
                 || cuBalFin.PSMA_ANTERIOR          || vsSep
                 || cuBalFin.PRAN_ANTERIOR          || vsSep
                 || cuBalFin.PETE_ANTERIOR          || vsSep
                 || vsPropsu_ant                    || vsSep
                 || cuBalFin.PONDERADO_UFT_ANTERIOR || vsSep
                 || cuBalFin.PSCI_ACTUAL            || vsSep
                 || cuBalFin.PSHC_ACTUAL            || vsSep
                 || cuBalFin.PSLC_ACTUAL            || vsSep
                 || cuBalFin.PSMA_ACTUAL            || vsSep
                 || cuBalFin.PRAN_ACTUAL            || vsSep
                 || cuBalFin.PETE_ACTUAL            || vsSep
                 || vsPropsu_act                    || vsSep
                 || cuBalFin.PONDERADO_UFT_ACTUAL   || vsSep
                 || cuBalFin.PPON                   || vsSep
                 || cuBalFin.ANOA                   || vsSep
                 || cuBalFin.SEXO                   || vsSep
                 || cuBalFin.CODIGO_COLEGIO         || vsSep
                 || cuBalFin.COLEGIO                || vsSep
                 || cuBalFin.REGION_COL             || vsSep
                 || cuBalFin.COMUNA_COL             || vsSep
                 || cuBalFin.CODIGO_DEPENDENCIA     || vsSep
                 || cuBalFin.DESC_DEPENDENCIA       || vsSep
                 || cuBalFin.RETRACTO                 || vsSep
                 || cuBalFin.EXT;       

       --insertar el renglon en la tabla de salida
 
       p_InsertaReg(vnNumArch, vni, vsLinea, psUser);
       
        if vIX = 200 then
           vIX := 0; 
           commit;  
        end if;


    END LOOP;-- FIN DEL FOR

   COMMIT;
    --Una vez que genere registros regreso el numero de archivo y el numero de registros
    vnNumReg := vni; 
    pnNumArch := vnNumArch;
    pnNumRegs := vnNumReg;

    vdFinal := SYSDATE;

    INSERT INTO GWVTCNT VALUES (vdInicial, vdFinal, vnNumReg,'Fin p_Genera');

EXCEPTION
    WHEN OTHERS THEN
        --Deshago los cambios de esta transaccion

        ROLLBACK TO InicioArchivo;
        err_msg := substr(sqlcode||'-'||sqlerrm,1,3999);
        INSERT INTO GWVTCNT VALUES (vdInicial, vdFinal, vnNumReg, substr('p_Genera:'||replace(err_msg,'"','\"'),1,399));
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
PROCEDURE p_ObtArchivoNuevo(psFecha VARCHAR2)
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
    vdFecha := TO_DATE(psFecha,'DD/MM/YYYY');

    --Si la fecha esta nula
    IF vdFecha IS NULL THEN
        HTP.P('No se indico una fecha.');
        RETURN;
    END IF;

    vdFinal := SYSDATE;
    INSERT INTO GWVTCNT VALUES (vdInicial, vdFinal, NULL,'Inicia p_Genera');

    --Genero archivo CAE.

    p_Genera(vnNumArch, vnNumRegs, vdFecha, pk_login.vgsUSR);

    --Verificamos que haya un numero de archivo
    IF vnNumArch IS NULL THEN
        ROLLBACK; --Deshago cualquier cambio
        --Mensaje general 01
        HTP.P(cgsMsg001);
        RETURN;
    END IF;

    --obtengo el archivo:
    vcArchivo := f_GeneraArchivo(vnNumArch);


    --calculo tamaño del archivo
    vnTamano := LENGTH(vcArchivo);

    --calculo hash SHA-1 del archivo
    vrSHA1Digest := DBMS_CRYPTO.HASH(vcArchivo,DBMS_CRYPTO.HASH_SH1);

    --obtenemos nombre de archivo

    vsNomArch := 'BalanceFinal_'
        ||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS_')
        ||LPAD(TO_CHAR(vnNumArch),5,'0')||'.txt';

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
            'pk_FotoBalanceFinal.p_ObtArchivoNuevo', NULL);

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
            'pk_FotoBalanceFinal.p_ReimprimeArchivo', NULL);
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
        SELECT  MAX(SUBSTR(STVTERM_CODE,1,4))
        FROM STVTERM
        WHERE  STVTERM_TRMT_CODE IS NOT NULL
          AND SUBSTR(STVTERM_CODE,1,4) >= EXTRACT(YEAR FROM SYSDATE);

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
        <TITLE>Generaci&oacute;n de Archivo Balance Final</TITLE>'
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
            Recuperación de Foto Balance Final
        </h2>
        <hr/>
        <br/>
        <table border="0" cellpadding="0" cellspacing="0" width="100%" bgcolor="#efefef" >
            <form name="frmDatos" method="post">
                
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
            ExecAjax("pk_FotoBalanceFinal.p_JSONListaArchivos",prms,CargaComboArchivos);

        }

    //funcion para el boton recuperar
        function Recuperar(){
            //si no se ha seleccionado un archivo, bye...
            if(!ValidaArchivo()) return;

            //indico el destino de la generacion de archivos
            frmParams.action = "pk_FotoBalanceFinal.p_ReimprimeArchivo";

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
            frmParams.action = "pk_FotoBalanceFinal.p_ObtArchivoNuevo";

            //desactivo el parametro psSecuencia
            frmParams.psNumArch.disabled = true;

            //activo el parametro de fecha y asigno valor
            frmParams.psFecha.disabled = false;
            frmParams.psFecha.value = frmDatos.txtFecha.value;

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
            'pk_FotoBalanceFinal.p_Main', NULL);

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



END pk_FotoBalanceFinal;
/

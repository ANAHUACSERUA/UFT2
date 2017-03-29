CREATE OR REPLACE PACKAGE BODY BANINST1.pk_ContratoCFC IS
/******************************************************************************
PAQUETE:            BANSECR.pk_Contrato
OBJETIVO:            Contiene los procedimientos, funciones y variables
                    requeridos para la impresion de la documentaciÃ³n del
                    proceso de matricula, asÃ­ como cÃ³digo auxiliar para el
                    funcionamiento de las pantallas TWAPAYM/TWAMACE
AUTORES:            Eduardo Armando Moreno Macal
                    Gilberto Velazquez Hernandez
FECHA (REFACT):        20130102

Modificacion 1 md-01
Objetivo: Redacci;n de articulos 1 y 6 en  p_ContratoServicios
Autor: Virgilio De la Cruz Jard;n
Fecha: 20130923
modify: Glovicx@17.02.2014 by twapcfc
se agregan funciones: f_get_mes;  f_porcomprometer;
se modifica p_selcontratos; p_inscontratos; p_selresumen

fecha:  > 28.agst.2014
by       glovicx
-- se modifico p_selcontratos para que no tome encuenta contratos activos.
--  es decir no toma en cuanta contratos activos pero si cancelados

******************************************************************************/
--Prototipos de funciones privadas, ver cuerpo de la funciÃ³n para mayor detalle
--PROCEDURE p_ContratoServicios(psCntr VARCHAR2);
--PROCEDURE p_Contrato2011(psCntr VARCHAR2);
--Fin de prototipos de funciones privadas
--Cursor Datos
/*
CURSOR cuAlumnosCntrEmpresarial(psCntr VARCHAR2) IS


SELECT
            SPRIDEN_ID                                AS IdAlumno,
            f_get_rut(TWBCNID_PIDM)              as RUT,
            SPRIDEN_FIRST_NAME                   as NombreAlumno,
            SPRIDEN_LAST_NAME                   as ApellidosAlumno,
           pk_Catalogo.Programa(SGBSTDN_PROGRAM_1) AS Programa
            ,TWBCNID_TERM_CODE                        AS Periodo

        FROM
            TWBCNTR
            ,SPRIDEN
            ,SGBSTDN
            ,TWBCNID
        WHERE
          SPRIDEN_PIDM = TWBCNID_PIDM
          AND SPRIDEN_PIDM = SGBSTDN_PIDM
          and TWBCNID_TERM_CODE = SGBSTDN_TERM_CODE_EFF
            AND TWBCNTR_NUM = psCntr
          AND TWBCNTR_NUM = TWBCNID_CNTR_NUM
          AND SGBSTDN_STST_CODE = 'AS';

  CURSOR cuDatosBaseCntrEmpresarial(psCntr VARCHAR2) IS
 SELECT
            TWBCNTR_PIDM                            AS Pidm
            ,TWBCNTR_TERM_CODE                        AS Perio
            ,TWBCNTR_TERM_TYPE                        AS TipoPerio
            ,TWBCNTR_RUT                            AS RutApo
            ,TWBCNTR_ISSUE_DATE                        AS FEmi
            ,SPRIDEN_ID                                AS IdAluEmpresarial
            ,REPLACE(SPRIDEN_LAST_NAME,'*',' ')        AS NombreEmpresa
        FROM
            TWBCNTR
            ,SPRIDEN
        WHERE
            SPRIDEN_PIDM = TWBCNTR_PIDM
            AND SPRIDEN_CHANGE_IND IS NULL
            AND TWBCNTR_NUM = psCntr;

*/
    --Cursor para obtener los datos base de un contrato
    CURSOR cuDatosBase(psCntr VARCHAR2) IS
        /*
        SELECT
            TWBCNTR_PIDM                            AS Pidm
            ,TWBCNTR_TERM_CODE                        AS Perio
            ,TWBCNTR_TERM_TYPE                        AS TipoPerio
            ,TWBCNTR_RUT                            AS RutApo
            ,TWBCNTR_ISSUE_DATE                        AS FEmi
            ,TWBCNTR_ORI_PROGRAM                    AS Prog
            ,SPRIDEN_ID                                AS IdAlu
            ,REPLACE(SPRIDEN_LAST_NAME,'*',' ')        AS ApeAlu
            ,SPRIDEN_FIRST_NAME                        AS NomAlu
            ,SPRIDEN_MI                                AS Nom2Alu
            ,SPBPERS_NAME_SUFFIX                    AS RutAlu
            ,TWBCNTR_TERM_CFC                      AS PeriodoCFC
        FROM
            TWBCNTR
            ,SPRIDEN
            ,SPBPERS
        WHERE
            SPBPERS_PIDM = SPRIDEN_PIDM
            AND SPRIDEN_PIDM = TWBCNTR_PIDM
            AND SPRIDEN_CHANGE_IND IS NULL
            AND TWBCNTR_NUM = psCntr;
            */
            SELECT
            TWBCNTR_PIDM                            AS Pidm
            ,TWBCNTR_TERM_CODE                        AS Perio
            ,TWBCNTR_TERM_TYPE                        AS TipoPerio
            ,TWBCNTR_RUT                            AS RutApo
            ,TWBCNTR_ISSUE_DATE                        AS FEmi
            ,TWBCNTR_ORI_PROGRAM                    AS Prog
            ,SPRIDEN_ID                                AS IdAlu
            ,REPLACE(SPRIDEN_LAST_NAME,'*',' ')        AS ApeAlu
            ,SPRIDEN_FIRST_NAME                        AS NomAlu
            ,SPRIDEN_MI                                AS Nom2Alu
            ,SPBPERS_NAME_SUFFIX                    AS RutAlu
            ,TWBCNTR_TERM_CFC                      AS PeriodoCFC
            ,STVLEVL_DESC AS Nivel
        FROM
            TWBCNTR
            ,SPRIDEN
            ,SPBPERS
               ,STVLEVL
        WHERE
           STVLEVL_CODE = SUBSTR(TWBCNTR_ORI_PROGRAM ,1,2)
            AND SPBPERS_PIDM = SPRIDEN_PIDM
            AND SPRIDEN_PIDM = TWBCNTR_PIDM
            AND SPRIDEN_CHANGE_IND IS NULL
            AND TWBCNTR_NUM = psCntr;

    --Cursor para obtener los documentos que se imprimiran en los documentos
    CURSOR cuDocs(psCntr VARCHAR2) IS
        SELECT
            TWBDOCU_SEQ_NUM                AS NumSeqDoc
            ,TWVPAYM_DESC                AS DescMP
            ,TWBDOCU_DOCU_NUM            AS NumDocu
            ,TWBDOCU_EXPIRATION_DATE    AS FechaVen
            ,TWVBANK_DESC                AS Banco
            ,TWBDOCU_AMOUNT                AS Monto
        FROM
            TWVPAYM
            ,TWVBANK
            ,TWBDOCU
        WHERE
            TWBDOCU_CNTR_NUM = psCntr
            AND TWVPAYM_CODE = TWBDOCU_PAYM_CODE
            AND TWVBANK_CODE(+) = TWBDOCU_BANK_CODE
            AND TWVPAYM_AGRE_PRINTABLE_IND = 'Y'
            AND TWBDOCU_STATUS_IND <> 'CA'
            AND EXISTS(
                SELECT
                    1
                FROM
                    TWRDOTR
                WHERE
                    TWRDOTR_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
                    AND TWRDOTR_ORIG_IND = 'O'
            )
        ORDER BY
            TWBDOCU_SEQ_NUM;

    --Cursor para obtener los montos por categorias para un documento
    CURSOR cuCats(pnNumSeqDoc NUMBER) IS
        SELECT
            TTVDCAT_DESC                        AS Categoria
            ,SUM(TWRDOTR_PART_AMOUNT)            AS Monto
        FROM
            TWRDOTR
            ,TBRACCD
            ,TBBDETC
            ,TTVDCAT
        WHERE
            TWRDOTR_DOCU_SEQ_NUM = pnNumSeqDoc
            AND TWRDOTR_PIDM = TBRACCD_PIDM
            AND TWRDOTR_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
            AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
            AND TBRACCD_AMOUNT > 0
            AND TBBDETC_TYPE_IND = 'C'
            AND TTVDCAT_CODE = TBBDETC_DCAT_CODE
        GROUP BY
            TTVDCAT_DESC;

    --Cursor para obtener el periodo de admision de un alumno
    CURSOR cuPerioAdmt(
        pnPidm            NUMBER
        ,psPerio        VARCHAR2
    ) IS
        SELECT
            SGBSTDN_TERM_CODE_ADMIT
        FROM
            SGBSTDN STDN1
        WHERE
            STDN1.SGBSTDN_PIDM = pnPidm
            AND STDN1.SGBSTDN_TERM_CODE_EFF = (
                SELECT
                    MAX(STDN2.SGBSTDN_TERM_CODE_EFF)
                FROM
                    SGBSTDN STDN2
                WHERE
                    STDN2.SGBSTDN_PIDM = STDN1.SGBSTDN_PIDM
                    AND STDN2.SGBSTDN_TERM_CODE_EFF <=
                        STDN1.SGBSTDN_TERM_CODE_EFF
            );

    -- CURSOR QUE SACA EL AÃ‘O DEL PERDIOS
    CURSOR cuAnioPeriodo(psTerm STVTERM.STVTERM_CODE%TYPE) IS
        SELECT
            STVTERM_ACYR_CODE
        FROM
            STVTERM
        WHERE
            STVTERM_CODE = psTerm;

CURSOR cuNivelCFC (psCntr VARCHAR2) IS
   SELECT
          SUBSTR(TWBCNTR_ORI_PROGRAM ,1,2)  AS Nivel
        FROM
            TWBCNTR
               ,STVLEVL
        WHERE
           STVLEVL_CODE = SUBSTR(TWBCNTR_ORI_PROGRAM ,1,2)
            AND TWBCNTR_NUM = psCntr;


function f_porcomprometer  (pspidm  number, psntran number)
RETURN NUMBER IS
 vnCntr        NUMBER:=0;

----se modifica la funcion para que siempre traiga el monto segun el caso

begin
------ no tiene documentos
select cc2.tbraccd_amount
      into  vnCntr
   from tbraccd cc2
   where  cc2.tbraccd_pidm  = pspidm ---117695
   and cc2.tbraccd_tran_number  = psntran --5 --5
   and (cc2.tbraccd_pidm,cc2.tbraccd_tran_number)  not in
   (select tb.twbdocu_pidm, twr.twrdotr_tran_number
    from twbdocu tb ,TWRDOTR twr
    where tb.twbdocu_pidm = cc2.tbraccd_pidm
    and tb.twbdocu_seq_num  = twr.twrdotr_docu_seq_num
    and twr.twrdotr_pidm   = cc2.tbraccd_pidm
    and twr.twrdotr_tran_number  = cc2.tbraccd_tran_number
    and tb.twbdocu_paym_code  not in (select twvpaym_code
                                         from twvpaym a
                                    where a.twvpaym_enabled_ind = 'Y'
                                    and a.twvpaym_user_viewable_ind  ='Y'
                                    and a.TWVPAYM_ONLINE_IND = 'Y')
    );


if vnCntr is null then
----- si tiene documentos --
  select cc2.tbraccd_amount
      into  vnCntr
   from tbraccd cc2
   where  cc2.tbraccd_pidm  = pspidm ---117695
   and cc2.tbraccd_tran_number  = psntran --5 --5
   and (cc2.tbraccd_pidm,cc2.tbraccd_tran_number)  in
   (select tb.twbdocu_pidm, twr.twrdotr_tran_number
    from twbdocu tb ,TWRDOTR twr
    where tb.twbdocu_pidm = cc2.tbraccd_pidm
    and tb.twbdocu_seq_num  = twr.twrdotr_docu_seq_num
    and twr.twrdotr_pidm   = cc2.tbraccd_pidm
    and twr.twrdotr_tran_number  = cc2.tbraccd_tran_number
    and tb.twbdocu_paym_code  not in (select twvpaym_code
                                         from twvpaym a
                                    where a.twvpaym_enabled_ind = 'Y'
                                    and a.twvpaym_user_viewable_ind  ='Y'
                                    and a.TWVPAYM_ONLINE_IND = 'Y')
    );


end if;


 RETURN vnCntr;
  EXCEPTION
      WHEN OTHERS THEN
          vnCntr := NULL;
          RETURN vnCntr;
  END f_porcomprometer;




/******************************************************************************
PROCEDIMIENTO:        p_SelContratos
OBJETIVO:            Procedimiento de seleccion para el bloque de datos
                    principal en la pantalla TWAPAYM
PARAMETROS:
psPidm:                Pidm del Alumno
psTerm:                Periodo de Matricula
rcContrato:            Parametro de Salida. Cursor con los datos para el bloque
modify by glovicx 31.1.14 para que tome los cargos con o sin contrato ok
******************************************************************************/
PROCEDURE p_SelContratos(
    psPidm        IN        NUMBER        DEFAULT NULL,
    psTerm        IN        VARCHAR2    DEFAULT NULL,
    psprogram   IN        VARCHAR2    DEFAULT NULL,
    rcContrato    IN OUT    rc_contrato
) IS BEGIN
    OPEN rcContrato FOR
  --- se modifico para que tome los cargos con contrato y sin contrato
   SELECT TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_BALANCE, --PK_MATRICULA.f_obtmontotransindoc(TBRACCD_PIDM, TBRACCD_TRAN_NUMBER), --TBRACCD_BALANCE,
           TBRACCD_EFFECTIVE_DATE, TBRACCD_DESC, TWBDOCU_SEQ_NUM, TWBDOCU_PAYM_CODE, TWBDOCU_DOCU_NUM,
           TWRDOTR_PART_AMOUNT, TWBDOCU_EXPIRATION_DATE, TWBDOCU_STATUS_IND, TWBDOCU_CNTR_NUM,
           TWBDOCU_BANK_CODE, TWBDOCU_CTYP_CODE, TWBDOCU_PLCE_CODE, TWBDOCU_CURR_ACNT, TBBDETC_DCAT_CODE, TWVPAYM_USER_EDITABLE_IND
    FROM   TBRACCD,
           TWRDOTR,
           TWBDOCU,
           TBBDETC,
           TWVPAYM,
            TWBCNTR
     WHERE TWRDOTR_PIDM = TBRACCD_PIDM
       AND TWRDOTR_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
       AND TWBDOCU_SEQ_NUM = TWRDOTR_DOCU_SEQ_NUM
       AND TWVPAYM_CODE = TWBDOCU_PAYM_CODE
       AND TWVPAYM_USER_VIEWABLE_IND = 'Y'
       AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
       AND TBBDETC_TYPE_IND = 'C'
       AND TWBDOCU_STATUS_IND = 'AC'
       AND TWBCNTR_NUM = TWBDOCU_CNTR_NUM
--         AND TWBDOCU_STATUS_IND NOT IN ('CA', 'PA', 'RP', 'RV')
       AND TBRACCD_PIDM = psPidm
       AND TBRACCD_TERM_CODE = psTerm
         and  twbcntr_pidm  = TBRACCD_PIDM
       and  twbcntr_ori_program   =     psprogram
    UNION
    SELECT A.TBRACCD_PIDM, A.TBRACCD_TRAN_NUMBER, A.TBRACCD_TERM_CODE, A.TBRACCD_DETAIL_CODE, A.TBRACCD_BALANCE, -- PK_MATRICULA.f_obtmontotransindoc(A.TBRACCD_PIDM, A.TBRACCD_TRAN_NUMBER), --A.TBRACCD_BALANCE,
           A.TBRACCD_EFFECTIVE_DATE, A.TBRACCD_DESC, NULL, NULL, NULL,
           NULL, NULL, NULL, NULL,
           NULL, NULL, NULL, NULL, TBBDETC_DCAT_CODE, 'Y'
      FROM TBRACCD A,
           TBBDETC
      WHERE A.TBRACCD_PIDM = psPidm
       AND A.TBRACCD_TERM_CODE = psTerm
       AND TBBDETC_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
       AND TBBDETC_TYPE_IND = 'C'
       AND PK_MATRICULA.F_OBTMONTOTRANSINDOC(A.TBRACCD_PIDM, A.TBRACCD_TRAN_NUMBER) >= 0
       AND A.TBRACCD_AMOUNT > 0
            AND NOT EXISTS ( SELECT 1
                                   FROM TWRDOTR , TWBDOCU
                                   WHERE TWRDOTR_PIDM  = psPidm
                                   AND TWBDOCU.TWBDOCU_PIDM  =TWRDOTR.TWRDOTR_PIDM
                                   AND TWBDOCU.TWBDOCU_SEQ_NUM  = TWRDOTR.TWRDOTR_DOCU_SEQ_NUM
                                   AND TWBDOCU.TWBDOCU_PAYM_CODE <> 'BPG'
                                   AND   TWRDOTR_TRAN_NUMBER  = A.TBRACCD_TRAN_NUMBER)
       AND   not exists (SELECT 1
                                 FROM   twbcntr TWR
                              WHERE   TWR.TWBCNTR_PIDM = psPidm
                                   AND   TWR.TWBCNTR_TERM_CODE  =   psTerm
                                  and  twbcntr_ori_program   =  psprogram
                                    and  TWR.TWBCNTR_STATUS_IND <> 'C'  )
  UNION
    SELECT A.TBRACCD_PIDM, A.TBRACCD_TRAN_NUMBER, A.TBRACCD_TERM_CODE, A.TBRACCD_DETAIL_CODE, A.TBRACCD_BALANCE, -- PK_MATRICULA.f_obtmontotransindoc(A.TBRACCD_PIDM, A.TBRACCD_TRAN_NUMBER), --A.TBRACCD_BALANCE,
           A.TBRACCD_EFFECTIVE_DATE, A.TBRACCD_DESC,TWBDOCU_SEQ_NUM, TWBDOCU_PAYM_CODE, TWBDOCU_DOCU_NUM,
           TWRDOTR_PART_AMOUNT, TWBDOCU_EXPIRATION_DATE, TWBDOCU_STATUS_IND, TWBDOCU_CNTR_NUM,
           TWBDOCU_BANK_CODE, TWBDOCU_CTYP_CODE, TWBDOCU_PLCE_CODE, TWBDOCU_CURR_ACNT, TBBDETC_DCAT_CODE, 'Y'
      FROM TBRACCD A,
           TBBDETC,
             TWRDOTR,
           TWBDOCU
      WHERE A.TBRACCD_PIDM = psPidm
       AND A.TBRACCD_TERM_CODE = psTerm
       AND TBBDETC_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
       AND TBBDETC_TYPE_IND = 'C'
       and TWRDOTR_PIDM = TBRACCD_PIDM
       AND TWRDOTR_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
       AND TWBDOCU_SEQ_NUM = TWRDOTR_DOCU_SEQ_NUM
       AND PK_MATRICULA.F_OBTMONTOTRANSINDOC(A.TBRACCD_PIDM, A.TBRACCD_TRAN_NUMBER) >= 0
       AND A.TBRACCD_AMOUNT > 0
  ORDER BY TBRACCD_PIDM, TBRACCD_TRAN_NUMBER;



END p_selcontratos;

/******************************************************************************
PROCEDIMIENTO:        p_InsContratos
OBJETIVO:            Procedimiento de insercion para el bloque de datos
                    principal en la pantalla TWAPAYM
PARAMETROS:
TContratos:            Parametro de Salida. Cursor con los datos del bloque ???
******************************************************************************/
PROCEDURE p_InsContratos (TContratos IN OUT tty_contrato) IS
-- DECLARACION DE VARIABLES LOCALES
    vnNumSec            NUMBER;
    vnBusca                NUMBER;
    err_num                NUMBER;
    err_msg                VARCHAR2(255);
BEGIN
    FOR vlContrato IN 1..TContratos.COUNT LOOP
        -- BUSCA SI LA EXISTE LA TRANSACION
        SELECT COUNT(*)
          INTO vnBusca
          FROM TBRACCD
         WHERE TBRACCD_PIDM = TContratos(vlContrato).pidm
           AND TBRACCD_TRAN_NUMBER = TContratos(vlContrato).tran ;

      ---    insert into twrpaso  values ('insert 1' , TContratos(vlContrato).pidm|| ' PERIODO '||TContratos(vlContrato).term|| ' DETAIL '||TContratos(vlContrato).detail    );

        -- SI NO EXISTE LO INSERTA
        IF (vnBusca = 0 ) THEN
            -- INSERTA NUEVO CARGO EN EL ESTADO DE CUENTA
            pk_matricula.p_RegTbraccd(
                    TContratos(vlContrato).pidm,
                    TContratos(vlContrato).tran,
                    TContratos(vlContrato).term,
                    TContratos(vlContrato).detail,
                    TContratos(vlContrato).dmonto,
                    TContratos(vlContrato).dmonto,
                    TContratos(vlContrato).efedate,
                    TContratos(vlContrato).descr,
                    null,
                    'TWAPCFC');

          ---           insert into twrpaso  values ('insert 2' , TContratos(vlContrato).dmonto|| ' PERIODO '||TContratos(vlContrato).numcont     );
        END IF;
        --- INSERTA INFORMACION DEL DOCUMENTO Y SUS RELACIONES CON LOS CARGOS CORRESPONDIENTE
        pk_matricula.p_insdocumento(
                TContratos(vlContrato).seqnum,
                TContratos(vlContrato).pidm,
                TContratos(vlContrato).term,
                TContratos(vlContrato).paym,
                TContratos(vlContrato).docume,
                NULL,
                TContratos(vlContrato).dmonto,
                TContratos(vlContrato).dmonto,
                TContratos(vlContrato).efedate,
                'AC',
                TContratos(vlContrato).banco,
                TContratos(vlContrato).ttarjeta,
                TContratos(vlContrato).plaza,
                TContratos(vlContrato).cuecon,
                SYSDATE,
                NULL,
                SYSDATE,
                USER);
      ----          insert into twrpaso  values ('insert 3' , TContratos(vlContrato).seqnum);
         -- INSERTA LA RELACION ENTRE CARGOS Y DOCUMENTOS
         pk_matricula.p_insTranDocu(
                TContratos(vlContrato).pidm,
                TContratos(vlContrato).tran,
                TContratos(vlContrato).seqnum,
                TContratos(vlContrato).dmonto,
                NULL,
                NULL,
                'O' );
          ---       insert into twrpaso  values ('insert 4' , TContratos(vlContrato).dmonto);
    END LOOP;
   ---  insert into twrpaso  values ('insert 5' , 'sale del proceso');
EXCEPTION
    WHEN OTHERS THEN
        err_num := SQLCODE;  err_msg := SQLERRM;
        RAISE_APPLICATION_ERROR(TO_CHAR(err_num), err_msg);

   ---      insert into twrpaso  values ('insert 6  ERROR ' , 'sale del proceso'||  err_msg );
END p_inscontratos;

/******************************************************************************
PROCEDIMIENTO:        p_UpdContratos
OBJETIVO:            Procedimiento de actualizacion para el bloque de datos
                    principal en la pantalla TWAPAYM
PARAMETROS:
TContratos:            Parametro de Salida. Cursor con los datos del bloque ???
******************************************************************************/
PROCEDURE p_UpdContratos (TContratos IN OUT tty_contrato) IS
    -- DECLARACION DE VARIABLES LOCALES
    vnNumSec            NUMBER;
    vvAntDoc            NUMBER;
    vnBusca                NUMBER;
    err_num                NUMBER;
    err_msg                VARCHAR2(255);

    --variable para recorrer el hash
    vni                    PLS_INTEGER;

    --CURSOR para saber si ya existe un documento:
    CURSOR cuExisteDocu(
        pnNumSeqDoc        NUMBER
        ,pnPidm            NUMBER
        ,psPerio        VARCHAR2
    ) IS
    SELECT
        1
    FROM
        TWBDOCU
    WHERE
        TWBDOCU_SEQ_NUM = pnNumSeqDoc
        AND TWBDOCU_PIDM = pnPidm
        AND TWBDOCU_TERM_CODE = psPerio;

    --Hash table para llevar control de los documentos que estoy actualizado
    TYPE t_HshDocu IS TABLE OF ty_contrato INDEX BY PLS_INTEGER;
    --El hash en si
    vhDocus                t_HshDocu;

    --cursor para obtener el monto en twrdotr de los cargos que cubre un
    --documento
    CURSOR cuMontoDotr(pnNumSeqDoc NUMBER) IS
        SELECT
            SUM(TWRDOTR_PART_AMOUNT)
        FROM
            TWRDOTR
            ,TBRACCD
            ,TBBDETC
        WHERE
            TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            AND TBRACCD_PIDM = TWRDOTR_PIDM
            AND TBRACCD_TRAN_NUMBER = TWRDOTR_TRAN_NUMBER
            AND TBBDETC_TYPE_IND = 'C'
            AND TBRACCD_AMOUNT > 0
            AND TWRDOTR_DOCU_SEQ_NUM = pnNumSeqDoc;

    --Variable para guardar el monto del documento
    vnMontoDoc            TWBDOCU.TWBDOCU_AMOUNT%TYPE;

    --Cursor para saber si un medio de pago es editable
    CURSOR cuEditable(psMP VARCHAR2) IS
        SELECT
            1
        FROM
            TWVPAYM
        WHERE
            TWVPAYM_CODE = psMP
            AND TWVPAYM_USER_EDITABLE_IND = 'Y';

    --Variable para verificar si el medio de pago es editable....}
    vnEditable            PLS_INTEGER;

BEGIN
    FOR vlContrato IN 1..TContratos.COUNT LOOP
        -- ACTUALIZA LA TRANSACIONES SOLO LA FECHA DE VIGENCIA
        PK_MATRICULA.p_ActFecVenCargo(
                    TContratos(vlContrato).pidm,
                    TContratos(vlContrato).tran,
                    TContratos(vlContrato).efedate);



        --Si tiene numero de secuencia y medio de pago...
        IF (TContratos(vlContrato).seqnum IS NOT NULL)
            AND (TContratos(vlContrato).paym IS NOT NULL) THEN

                --Busco si ya existe el documento
                vnBusca := 0;
                OPEN cuExisteDocu(
                    TContratos(vlContrato).seqnum
                    ,TContratos(vlContrato).pidm
                    ,TContratos(vlContrato).term
                );
                FETCH cuExisteDocu INTO vnBusca;
                CLOSE cuExisteDocu;

                --Si no existio el documento insertamos....
                IF vnBusca < 1 THEN
                    pk_matricula.p_insdocumento(
                        TContratos(vlContrato).seqnum,
                        TContratos(vlContrato).pidm,
                        TContratos(vlContrato).term,
                        TContratos(vlContrato).paym,
                        TContratos(vlContrato).docume,
                        NULL,
                        TContratos(vlContrato).dmonto,
                        TContratos(vlContrato).dmonto,
                        TContratos(vlContrato).efedate,
                        'AC',
                        TContratos(vlContrato).banco,
                        TContratos(vlContrato).ttarjeta,
                        TContratos(vlContrato).plaza,
                        TContratos(vlContrato).cuecon,
                        SYSDATE,
                        NULL,
                        SYSDATE,
                        USER
                    );

                    -- INSERTA LA RELACION ENTRE CARGOS Y DOCUMENTOS
                    pk_matricula.p_insTranDocu(
                        TContratos(vlContrato).pidm,
                        TContratos(vlContrato).tran,
                        TContratos(vlContrato).seqnum,
                        TContratos(vlContrato).dmonto,
                        NULL,
                        NULL,
                        'O'
                    );
                ELSE

                    --Verifico si el documento es editable
                    vnEditable:= 0;
                    OPEN cuEditable(TContratos(vlContrato).paym);
                    FETCH cuEditable INTO vnEditable;
                    CLOSE cuEditable;

                    --si es editable... pus edito :-P
                    IF vnEditable = 1 THEN
                        --si existe el documento...
                        --Primer paso... actualizo las relaciones
                        UPDATE
                            TWRDOTR
                        SET
                            TWRDOTR_PART_AMOUNT = TContratos(vlContrato).dmonto
                        WHERE
                            TWRDOTR_PIDM = TContratos(vlContrato).pidm
                            AND TWRDOTR_TRAN_NUMBER = TContratos(vlContrato).tran
                            AND TWRDOTR_DOCU_SEQ_NUM = TContratos(vlContrato).seqnum;

                        --Veo si el documento existe en el hasH
                        --Si no existe lo agrego
                        IF NOT vhDocus.EXISTS( TContratos(vlContrato).seqnum ) THEN

                            vhDocus( TContratos(vlContrato).seqnum ) :=
                                TContratos(vlContrato);

                        END IF;
                        --Si viene repetido ese mismo numero de documento
                        --en renglones diferentes, simplemente los omitimos :)
                    END IF;

                END IF;

        END IF;

    END LOOP;

    --obtengo el primer elemento del hash:
    vni := vhDocus.FIRST;

    --Mientras la llave del hash no sea nula, es decir aun haya elementos
    --que recorrer dentre
    WHILE vni IS NOT NULL LOOP

        --obtengo el monto de cargos del documento
        OPEN cuMontoDotr(vni);
        FETCH cuMontoDotr INTO vnMontoDoc;
        CLOSE cuMontoDotr;

        UPDATE
            TWBDOCU
        SET
            TWBDOCU_PAYM_CODE = vhDocus(vni).paym,
            TWBDOCU_DOCU_NUM = vhDocus(vni).docume,
            TWBDOCU_AMOUNT = vnMontoDoc,
            --TWBDOCU_NOM_AMOUNT = TContratos(vlContrato).dmonto,
            TWBDOCU_EXPIRATION_DATE = vhDocus(vni).efedate,
            TWBDOCU_STATUS_IND = 'AC',
            TWBDOCU_BANK_CODE = vhDocus(vni).banco,
            TWBDOCU_CTYP_CODE = vhDocus(vni).ttarjeta,
            TWBDOCU_PLCE_CODE = vhDocus(vni).plaza,
            TWBDOCU_CURR_ACNT = vhDocus(vni).cuecon,
            TWBDOCU_ENTRY_DATE = SYSDATE,
            TWBDOCU_ENTRY_USER = USER,
            TWBDOCU_ACTIVITY_DATE = SYSDATE,
            TWBDOCU_USER = USER
        WHERE
            TWBDOCU_SEQ_NUM = vni;

        vni := vhDocus.NEXT(vni);

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END p_updcontratos;


--PROCEDURE p_UpdContratos (TContratos IN OUT tty_contrato) IS
--    -- DECLARACION DE VARIABLES LOCALES
--    vnNumSec            NUMBER;
--    vvAntDoc            NUMBER;
--    vnBusca                NUMBER;
--    err_num                NUMBER;
--    err_msg                VARCHAR2(255);
--BEGIN
--    FOR vlContrato IN 1..TContratos.COUNT LOOP
--        -- ACTUALIZA LA TRANSACIONES SOLO LA FECHA DE VIGENCIA
--        PK_MATRICULA.p_ActFecVenCargo(
--                    TContratos(vlContrato).pidm,
--                    TContratos(vlContrato).tran,
--                    TContratos(vlContrato).efedate);
--        -- ACTUALIZACION DE DOCUEMNTOS
--        IF (TContratos(vlContrato).seqnum IS NOT NULL) THEN
--            IF (TContratos(vlContrato).paym IS NOT NULL) THEN
--                -- BUSCO SI YA CAMBIO EL MEDIO DE PAGO O SOLO SE ESTA ACTUALIZANDO
--                BEGIN
--                    SELECT COUNT(*)
--                      INTO vnBusca
--                      FROM TWBDOCU
--                     WHERE TWBDOCU_SEQ_NUM = TContratos(vlContrato).seqnum
--                       AND TWBDOCU_PIDM = TContratos(vlContrato).pidm
--                       AND TWBDOCU_TERM_CODE = TContratos(vlContrato).term;
--                EXCEPTION
--                   WHEN OTHERS THEN
--                      vnBusca := 0;
--                END;
--                -- SI EXISTE EL REGISTRO SOLO LO ACTUALIZA Y SINO LO PONE NUEVO
--                IF (vnBusca = 0) THEN
--                    -- INSERTA INFORMACION DEL DOCUMENTO Y SUS RELACIONES CON LOS CARGOS CORRESPONDIENTE
--                    pk_matricula.p_insdocumento(
--                            TContratos(vlContrato).seqnum,
--                            TContratos(vlContrato).pidm,
--                            TContratos(vlContrato).term,
--                            TContratos(vlContrato).paym,
--                            TContratos(vlContrato).docume,
--                            NULL,
--                            TContratos(vlContrato).dmonto,
--                            TContratos(vlContrato).dmonto,
--                            TContratos(vlContrato).efedate,
--                            'AC',
--                            TContratos(vlContrato).banco,
--                            TContratos(vlContrato).ttarjeta,
--                            TContratos(vlContrato).plaza,
--                            TContratos(vlContrato).cuecon,
--                            SYSDATE,
--                            NULL,
--                            SYSDATE,
--                            USER);
--                     -- INSERTA LA RELACION ENTRE CARGOS Y DOCUMENTOS
--                     pk_matricula.p_insTranDocu(
--                            TContratos(vlContrato).pidm,
--                            TContratos(vlContrato).tran,
--                            TContratos(vlContrato).seqnum,
--                            TContratos(vlContrato).dmonto,
--                            NULL,
--                            NULL,
--                            'O');
--                ELSE
--                    -- ACTUALIZA EL REGISTRO SOLAMENTE
--                    UPDATE TWBDOCU
--                       SET TWBDOCU_PAYM_CODE = TContratos(vlContrato).paym,
--                           TWBDOCU_DOCU_NUM = TContratos(vlContrato).docume,
--                           TWBDOCU_AMOUNT = TContratos(vlContrato).dmonto,
--                           TWBDOCU_NOM_AMOUNT = TContratos(vlContrato).dmonto,
--                           TWBDOCU_EXPIRATION_DATE = TContratos(vlContrato).efedate,
--                           TWBDOCU_STATUS_IND = 'AC',
--                           TWBDOCU_BANK_CODE = TContratos(vlContrato).banco,
--                           TWBDOCU_CTYP_CODE = TContratos(vlContrato).ttarjeta,
--                           TWBDOCU_PLCE_CODE = TContratos(vlContrato).plaza,
--                           TWBDOCU_CURR_ACNT = TContratos(vlContrato).cuecon,
--                           TWBDOCU_ENTRY_DATE = SYSDATE,
--                           TWBDOCU_ENTRY_USER = USER,
--                           TWBDOCU_ACTIVITY_DATE = SYSDATE,
--                           TWBDOCU_USER = USER
--                     WHERE TWBDOCU_SEQ_NUM = TContratos(vlContrato).seqnum;
--                     -- ACTUALIZA LA RELACION ENTRE DOCUMENTOS Y TRANSACIONES
--                     UPDATE TWRDOTR
--                        SET TWRDOTR_PART_AMOUNT = TContratos(vlContrato).dmonto
--                      WHERE TWRDOTR_PIDM = TContratos(vlContrato).pidm
--                        AND TWRDOTR_TRAN_NUMBER = TContratos(vlContrato).tran
--                        AND TWRDOTR_DOCU_SEQ_NUM = TContratos(vlContrato).seqnum;
--                END IF;
--            END IF;
--        END IF;
--    END LOOP;
--EXCEPTION
--    WHEN OTHERS THEN
--        err_num := SQLCODE;  err_msg := SQLERRM;
--        RAISE_APPLICATION_ERROR(TO_CHAR(err_num), err_msg);
--END p_updcontratos;

/******************************************************************************
PROCEDIMIENTO:        p_DelContratos
OBJETIVO:            Procedimiento de eliminaciÃ³n para el bloque de datos
                    principal en la pantalla TWAPAYM
PARAMETROS:
TContratos:            Parametro de Salida. Cursor con los datos del bloque ???
******************************************************************************/
PROCEDURE p_DelContratos (TContratos IN OUT tty_contrato) IS BEGIN
    FOR vlContrato IN 1..TContratos.COUNT LOOP
        -- NO SE BORRAN LOS REGISTROS SOLO SE CAMCELA EL DOCUMENTO SI MANDO ESTE ALGUNOS
        IF (TContratos(vlContrato).seqnum IS NOT NULL) THEN
            -- CANCELA EL DOCUMENTO ELIMINADO SOLAMENTE
            pk_matricula.p_updstadoc (
                             TContratos(vlContrato).seqnum,
                             'CA');
        END IF;
    END LOOP;
END p_delcontratos;

/******************************************************************************
PROCEDIMIENTO:        p_LokContratos
OBJETIVO:            Procedimiento de bloqueo para el bloque de datos
                    principal en la pantalla TWAPAYM
PARAMETROS:
TContratos:            Parametro de Salida. Cursor con los datos del bloque ???
******************************************************************************/
PROCEDURE p_LokContratos (TContratos IN OUT tty_contrato) IS
    -- DECLARACION DE VARIABLES LOCALES
    vnNumSec            NUMBER;
    vnPidm                TBRACCD.TBRACCD_PIDM%TYPE;
    vvTerm                TBRACCD.TBRACCD_TERM_CODE%TYPE;
    vnTran                TBRACCD.TBRACCD_TRAN_NUMBER%TYPE;
    err_num                NUMBER;
    err_msg                VARCHAR2(255);
BEGIN
--    FOR vlContrato IN 1..TContratos.COUNT LOOP
--        IF (TContratos(vlContrato).seqnum IS NOT NULL) THEN
--            SELECT TBRACCD_PIDM, TBRACCD_TERM_CODE, TBRACCD_TRAN_NUMBER
--              INTO vnPidm, vvTerm, vnTran
--              FROM TBRACCD,
--                   TWRDOTR,
--                   TWBDOCU
--             WHERE TWRDOTR_PIDM = TBRACCD_PIDM
--               AND TWRDOTR_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
--               AND TWBDOCU_SEQ_NUM = TWRDOTR_DOCU_SEQ_NUM
--               --AND TWBDOCU_STATUS_IND <> 'CA'
--               AND TBRACCD_PIDM = TContratos(vlContrato).pidm
--               AND TBRACCD_TRAN_NUMBER = TContratos(vlContrato).tran
--               AND TBRACCD_TERM_CODE = TContratos(vlContrato).term
--               AND TWRDOTR_DOCU_SEQ_NUM = TContratos(vlContrato).seqnum;
--               --FOR UPDATE;
--         ELSE
--            SELECT TBRACCD_PIDM, TBRACCD_TERM_CODE, TBRACCD_TRAN_NUMBER
--              INTO vnPidm, vvTerm, vnTran
--              FROM TBRACCD
--             WHERE TBRACCD_PIDM = TContratos(vlContrato).pidm
--               AND TBRACCD_TRAN_NUMBER = TContratos(vlContrato).tran ;
--               --FOR UPDATE;
--         END IF;
--     END LOOP;

    --Diganle al $%&/ perdon a forms que se pegue unos ...
    NULL;

EXCEPTION
    WHEN OTHERS THEN
        err_num := SQLCODE;  err_msg := SQLERRM;
        RAISE_APPLICATION_ERROR(TO_CHAR(err_num), err_msg);
END p_lokcontratos;


/******************************************************************************
PROCEDIMIENTO:        p_SelContratos
OBJETIVO:            Procedimiento de seleccion para el bloque de datos
                    de resumen en la pantalla TWAPAYM
PARAMETROS:
psPidm:                Pidm del Alumno
psTerm:                Periodo de Matricula
rcResumen:            Parametro de Salida. Cursor con los datos para el bloque
******************************************************************************/
PROCEDURE p_SelResumen (
    psPidm        IN        NUMBER        DEFAULT NULL,
    psTerm        IN        VARCHAR2    DEFAULT NULL,
    rcResumen    IN OUT    rc_resumen
) IS
  BEGIN
    OPEN rcResumen FOR
        SELECT TWBDOCU_PAYM_CODE,
               PK_MATRICULA.F_EXISTEMEDIOPAGO(TWBDOCU_PAYM_CODE),
               DECODE(TWVPAYM_AUTO_DOCU_IND, 'Y', '00000000', TWBDOCU_DOCU_NUM),
               SUM(NVL(TWBDOCU_AMOUNT, 0) ),
               TWBDOCU_BANK_CODE,
               PK_MATRICULA.F_EXISTEBANCO(TWBDOCU_BANK_CODE),
               TWBDOCU_CTYP_CODE,
               PK_MATRICULA.F_EXISTETIPOTARJ(TWBDOCU_CTYP_CODE)
          FROM TWBDOCU,
               TWVPAYM
         WHERE TWVPAYM_CODE = TWBDOCU_PAYM_CODE
           AND TWBDOCU_PIDM = psPidm
           AND TWBDOCU_TERM_CODE = psTerm
           AND TWBDOCU_STATUS_IND <> 'CA'
      GROUP BY TWBDOCU_PAYM_CODE,
               PK_MATRICULA.F_EXISTEMEDIOPAGO(TWBDOCU_PAYM_CODE),
               DECODE(TWVPAYM_AUTO_DOCU_IND, 'Y', '00000000', TWBDOCU_DOCU_NUM),
               TWBDOCU_BANK_CODE,
                PK_MATRICULA.F_EXISTEBANCO(TWBDOCU_BANK_CODE),
               TWBDOCU_CTYP_CODE,
               PK_MATRICULA.F_EXISTETIPOTARJ(TWBDOCU_CTYP_CODE);
  END p_selResumen;



/******************************************************************************
PROCEDIMIENTO:        p_Contrato
OBJETIVO:            Imprime en web el contrato legal especificado
PARAMETROS:
psCntr:                Numero del contrato
OBSERVACIONES:        Sirve unicamente como un wrapper, evalua que contrato se
                    imprimirÃ¡ en base a la fecha de emisiÃ³n y llama al
                    procedimiento acorde.
******************************************************************************/
PROCEDURE p_Contrato(psCntr VARCHAR2) IS

CURSOR cuNivelCFC (psCntr VARCHAR2) IS
   SELECT
          SUBSTR(TWBCNTR_ORI_PROGRAM ,1,2)  AS Nivel
        FROM
            TWBCNTR
               ,STVLEVL
        WHERE
           STVLEVL_CODE = SUBSTR(TWBCNTR_ORI_PROGRAM ,1,2)
            AND TWBCNTR_NUM = psCntr;

    --Cursor para obtener la fecha de emision del contrato
 CURSOR cuFechaEmi(psCntr VARCHAR2) IS
        SELECT
            TWBCNTR_ISSUE_DATE            AS Fecha
        FROM
            TWBCNTR
        WHERE
            TWBCNTR_NUM = psCntr;

    --Fecha de corte 2013, esto no es parametrizable, debe ser duuuurooo
    --como el corazon de tu exnovia!!! jajajaja
    vdF2013                DATE := TO_DATE('04/01/2013','DD/MM/YYYY');
     vdF2014_ebustos        DATE := TO_DATE('01/01/2014','DD/MM/YYYY');
    --Fecha de emision del contrato
    vdFEmi                DATE;
    vsNivelCFC          VARCHAR2(10);

BEGIN
    --Obtengo la fecha de emision para el contrato indicado
/*
       OPEN cuNivelCFC(psCntr);
    FETCH cuNivelCFC INTO vsNivelCFC;
    CLOSE cuNivelCFC;
    --Si la fecha de emision es igual o mayor que la del 2013 ejecutamos el
    --contrato 2013
    IF vsNivelCFC = 'DI' THEN


    */

     OPEN cuFechaEmi(psCntr);
    FETCH cuFechaEmi INTO vdFEmi;
    CLOSE cuFechaEmi;

    --Si la fecha de emision es igual o mayor que la del 2013 ejecutamos el
    --contrato 2013
    IF TRUNC(vdFEmi) >= vdF2014_ebustos THEN


         p_Contrato_firma_ebustos_2014(psCntr);
    ELSE
        --Sino ejecutamos el contrato clasico
        p_ContratoIndividual(psCntr);
    END IF;


         --  p_ContratoIndividual(psCntr);
/*
 ELSE
        --Sino ejecutamos el contrato clasico
      p_ContratoIndividual(psCntr);
    END IF;
*/
END p_Contrato;

/******************************************************************************
PROCEDIMIENTO:        p_Recibo
OBJETIVO:            Imprime al buffer HTP el recibo de ingreso a tesoreria
                    relacionado con el contrato indicado
PARAMETROS:
psCntr:                Numero del contrato
******************************************************************************/
PROCEDURE p_Recibo(psCntr VARCHAR2) IS

    -- DECLARACION DE VARIABLES LOCALES
    vnombre                VARCHAR2(200);
    valumno                VARCHAR2(200);
    vrut                VARCHAR2(30);
    vArut                VARCHAR2(30);
    vrol                VARCHAR2(30);
    vcont                VARCHAR2(30);
    vcarrera            VARCHAR2(30);
    vterm                VARCHAR2(30);
    vacumulado            NUMBER := 0;
    vnCargo                NUMBER := 0;
    vnPagos                NUMBER := 0;
    vncuenta            NUMBER := 1;
    vlObsev                VARCHAR2(10000);
    vsUser                VARCHAR2(50);
    vsAdmision            SGBSTDN.SGBSTDN_TERM_CODE_ADMIT%TYPE;
    vsTipoPerio            VARCHAR2(2);
    vsTexto                VARCHAR2(200);
    vsTerm                VARCHAR2(6);
    vnPidm                NUMBER(10);
      vFechaCntr         DATE;

    TYPE t_TblCats IS TABLE OF cuCats%ROWTYPE;
    vtCats                t_TblCats;
    vrDatosBase            cuDatosBase%ROWTYPE;
--md-01
     -- vrDatosBaseCntrEmpr          cuDatosBaseCntrEmpresarial%ROWTYPE;
    --Contador comun y corriente
    vni                    PLS_INTEGER;
--md-01
--Variable para guardar si se encontraron datos
    vbFound                BOOLEAN;
     vbFoundEmp                BOOLEAN;
BEGIN
      /* Check/update the user's web session */
--   IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

--IF
    OPEN cuDatosBase(psCntr);
    FETCH cuDatosBase INTO vrDatosBase;
     vbFound := cuDatosBase%FOUND;
    CLOSE cuDatosBase;

IF vbFound then
    vnPidm := vrDatosBase.Pidm;
    vsTerm := vrDatosBase.Perio;
    vFechaCntr := vrDatosBase.FEmi;
    -- BUSCA LA INFOMACION DEL LA PRIMERA PARTE
    vnombre := pk_MatApoderado.f_Apellido(vrDatosBase.RutApo) || ', '
        ||pk_MatApoderado.f_Nombre(vrDatosBase.RutApo);
    valumno := vrDatosBase.ApeAlu || ', ' ||vrDatosBase.NomAlu;
    vrut := vrDatosBase.RutApo;
    vrol := vrDatosBase.IdAlu;
    vcont := psCntr;
    vcarrera := pk_Catalogo.Programa(vrDatosBase.Prog);
    vterm := pk_Catalogo.Periodo(vrDatosBase.Perio);
    vArut := vrDatosBase.RutAlu;
ELSE
 /*
   OPEN cuDatosBaseCntrEmpresarial(psCntr);
    FETCH cuDatosBaseCntrEmpresarial INTO vrDatosBaseCntrEmpr;
   vbFoundEmp:= cuDatosBaseCntrEmpresarial%FOUND;
    CLOSE cuDatosBaseCntrEmpresarial;
   */
    --vnPidm := vrDatosBaseCntrEmpr.Pidm;
    --vsTerm := vrDatosBaseCntrEmpr.Perio;
    --vFechaCntr := vrDatosBaseCntrEmpr.FEmi;
    -- BUSCA LA INFOMACION DEL LA PRIMERA PARTE
  --  vnombre := pk_MatApoderado.f_Apellido(vrDatosBaseCntrEmpr.RutApo) || ', '
    --    ||pk_MatApoderado.f_Nombre(vrDatosBaseCntrEmpr.RutApo);
    --valumno :=  vrDatosBaseCntrEmpr.NombreEmpresa;
    --vrut := vrDatosBaseCntrEmpr.RutApo;
    --vrol := vrDatosBaseCntrEmpr.IdAluEmpresarial;
    vcont := psCntr;
    vcarrera := pk_Catalogo.Programa(vrDatosBase.Prog);
    --pk_Catalogo.Programa(vrDatosBase.Prog)
    vterm := pk_Catalogo.Periodo(vrDatosBase.Perio);
    --vArut := vrDatosBaseCntrEmpr.RutApo;


    end if;
    OPEN cuPerioAdmt(vnPidm,vsTerm);
    FETCH cuPerioAdmt INTO vsAdmision;
    CLOSE cuPerioAdmt;

    --
    -- BUSCA EL TEXTO DINAMICO DEL CONTRATO SEGUN EL PERIODO DE INSCRIPCION
    vsTipoPerio := vrDatosBase.TipoPerio;

    vsTexto := CASE vsTipoPerio
        WHEN 'A' THEN PK_CATALOGO.PERIODO(vsTerm)
        WHEN '1' THEN PK_CATALOGO.PERIODO( (SUBSTR(vsTerm, 1, 4) || '25') )
        WHEN '2' THEN PK_CATALOGO.PERIODO( (SUBSTR(vsTerm, 1, 4) || '75') )
        ELSE pk_util.f_ObtieneParam('TTERM', SUBSTR(vsTerm, 5, 2) )
    END;

    -- SACA EL ULTIMA OBSERVACION QUE TENGA REGISTRADO
    vlObsev := pk_Matricula.f_ComeCont(psCntr);

    HTP.P('<HTML><HEAD>');
    HTP.P('
        <style type="text/css" >
        <!--
      body.bodyCeroR {
         margin-left: 20pt;
         margin-right: 20pt;
         margin-top: 2pt;
         margin-bottom: 2pt;}
      tr.Estilo3 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 9px;
         text-align: center;}
      tr.Estilo4 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 10px;
         text-align: justify}
      tr.Estilo5 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 9px;
         text-align: justify;}
      td.Estilo6 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 9px;
         text-align: right;}
      tr.Estilo7 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 12px;
         text-align: justify;}
      td.Estilo11 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 8px;
         text-align: justify;}
      td.Estilo12 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 8px;
         text-align: right;}
      H1.SaltoDePagina
        { PAGE-BREAK-BEFORE: always }
         --></style>
         </script>
         </head>');

    HTP.P('<BODY onLoad="focus()" class="bodyCeroR" > <table  width=100% border="0">');

    --
    -- PAGINA PRIMERA
    --
    htp.p('<tr class="Estilo7"><td colspan="6">UNIVERSIDAD FINIS TERRAE</td>
                               <td colspan="14">FECHA: ' || TO_CHAR(vFechaCntr, 'DD/MM/YYYY') || '</td></tr>');
    htp.p('<tr class="Estilo7"><td colspan="6">CENTRO DE FORMACIÓN CONTINUA</td>
                               <td colspan="14">HORA: ' || TO_CHAR(vFechaCntr, 'HH24:MI') || '</td></tr>');

    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');


if vbFoundEmp then
    htp.p('<tr class="Estilo4"><td colspan="3">EMPRESA:</td>
                               <td colspan="18">' || valumno || '</td></tr>');
  else
  htp.p('<tr class="Estilo4"><td colspan="3">ALUMNO:</td>
                               <td colspan="18">' || valumno || '</td></tr>');
end if;

    htp.p('<tr class="Estilo4"><td colspan="3">ID:</td>
                               <td colspan="18">' || vrol || ' </td></tr>');

    htp.p('<tr class="Estilo4"><td colspan="3">R.U.T:</td>
                               <td colspan="18">' || vrut || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">CONTRATO:</td>
                               <td colspan="18">' || vcont || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">PROGRAMA:</td>
                               <td colspan="18">' ||vrDatosBase.Nivel|| ' en '  ||vcarrera || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">PERIODO:</td>
                               <td colspan="18">' || vrDatosBase.PeriodoCFC || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">ADMISIÓN:</td>
                               <td colspan="18">' || vsAdmision || '</td></tr>');

    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');

    htp.p('<tr class="Estilo4"><td colspan="20">COMPROBANTE DE INGRESOS</td></tr>');

    htp.p('<tr class="Estilo11"><td colspan="20"></td></tr>');

    htp.p('<tr><td colspan="1" class="Estilo11"></td>
                <td colspan="3" class="Estilo11">Medio de Pago</td>
                <td colspan="2" class="Estilo11">Número de Documento</td>
                <td colspan="2" class="Estilo11">Banco</td>
                <td colspan="4" class="Estilo11">Vencimiento</td>
                <td colspan="4" class="Estilo11">Concepto</td>
                <td colspan="2" class="Estilo11">Monto</td>
               </tr>');


    FOR regDocs IN cuDocs (psCntr) LOOP

        --Abro el cursor con las categorias de detalle
        OPEN cuCats(regDocs.NumSeqDoc);
        FETCH cuCats BULK COLLECT INTO vtCats;
        CLOSE cuCats;

        htp.p('<tr><td colspan="1" rowspan="'||vtCats.COUNT||'" class="Estilo11">'|| vncuenta ||'</td>
                    <td colspan="3" rowspan="'||vtCats.COUNT||'" class="Estilo11">'|| regDocs.DescMP ||'</td>
                    <td colspan="2" rowspan="'||vtCats.COUNT||'" class="Estilo11">'|| regDocs.NumDocu ||'</td>
                    <td colspan="2" rowspan="'||vtCats.COUNT||'" class="Estilo11">'|| regDocs.Banco ||'</td>
                    <td colspan="4" rowspan="'||vtCats.COUNT||'" class="Estilo11">'|| TO_CHAR(regDocs.FechaVen,'DD/MM/YYYY')||'</td>');

        FOR vni IN 1..vtCats.COUNT LOOP
            IF vni > 1 THEN HTP.P('<tr>'); END IF;
            HTP.P('<td colspan="4" class="Estilo11">'|| vtCats(vni).Categoria||'</td>');
            HTP.P('<td colspan="2" class="Estilo12">$'|| TO_CHAR(vtCats(vni).Monto, ConstglFormato)||'</td>');
            HTP.P('<td colspan="2" class="Estilo11"></td>');
            vacumulado := vacumulado + vtCats(vni).Monto ;
            HTP.P('</tr>');
        END LOOP;

        vncuenta := vncuenta + 1;
    END LOOP;

        htp.p('<tr><td colspan="1" class="Estilo11"></td>
                <td colspan="1" class="Estilo11"></td>
                <td colspan="3" class="Estilo11">TOTALES</td>
                <td colspan="3" class="Estilo11"></td>
                <td colspan="2" class="Estilo11"></td>
                <td colspan="4" class="Estilo11"></td>
                <td colspan="2" class="Estilo11"></td>
                <td colspan="2" class="Estilo12">'|| CASE vacumulado WHEN '0' THEN '' ELSE TO_CHAR(vacumulado, ConstglFormato) END ||'</td></tr>');
        HTP.P('<td colspan="2" class="Estilo11"></td>');
    htp.p('<tr class="Estilo3"><td colspan="20">' || LPAD('-', 150, '-') || '</td></tr>');
    htp.p('<tr class="Estilo3"><td colspan="20">Total Arancel $  ' || TO_CHAR(vacumulado, '999g999g999') || ' </td></tr>');
    htp.p('<tr class="Estilo3"><td colspan="20">' || LPAD('-', 150, '-') || '</td></tr>');

    htp.p('<tr class="Estilo4"><td colspan="20">OBSERVACIONES:</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="20">' || vlObsev || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="20"></td></tr>');

    htp.p('<tr class="Estilo3"><td colspan="20">____________________________________ </td></tr>');
    htp.p('<tr class="Estilo3"><td colspan="20">RECIBIDO: ' || vsUser || ' </td></tr>');

    HTP.TABLECLOSE;
    HTP.P('</BODY></HTML>');
EXCEPTION
  WHEN OTHERS THEN
        htp.p( SQLERRM);
END p_Recibo;

/******************************************************************************
PROCEDIMIENTO:        p_Boleta
OBJETIVO:            Imprime al buffer HTP la boleta de servicios relacionada
                    con el contrato indicado
PARAMETROS:
psCntr:                Numero del contrato
******************************************************************************/
PROCEDURE p_Boleta(psCntr VARCHAR2) IS

    -- DECLARACION DE VARIABLES LOCALES
    vcuenta                NUMBER:=0;
    vnombre                VARCHAR2(200);
    valumno                VARCHAR2(200);
    vrut                VARCHAR2(30);
    varut                VARCHAR2(30);
    vrol                VARCHAR2(30);
    vcont                VARCHAR2(30);
    vcarrera            VARCHAR2(30);
    vterm                VARCHAR2(30);
    vlMonto                NUMBER(16,2) := 0;
    vsAdmision            SGBSTDN.SGBSTDN_TERM_CODE_ADMIT%TYPE;
    vsTipoPerio            VARCHAR2(2);
    vvTextContrato        VARCHAR2(200);
    vlRUTApod            TWBCNTR.TWBCNTR_RUT%TYPE;
    vlNomApod            TWBAPLE.TWBAPLE_FIRST_NAME%TYPE;
    vlApeApoD            TWBAPLE.TWBAPLE_LAST_NAME%TYPE;
    vsTerm                VARCHAR2(6);
    vnPidm                NUMBER(10);
    vrDatosBase            cuDatosBase%ROWTYPE;
     vFechaCntr         DATE;

     --md-01
   --  vrDatosBaseCntrEmpr          cuDatosBaseCntrEmpresarial%ROWTYPE;
    --Contador comun y corriente
    vni                    PLS_INTEGER;
--md-01
--Variable para guardar si se encontraron datos
    vbFound                BOOLEAN;
     vbFoundEmp                BOOLEAN;

BEGIN
      /* Check/update the user's web session */
--   IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;
 OPEN cuDatosBase(psCntr);
    FETCH cuDatosBase INTO vrDatosBase;
     vbFound := cuDatosBase%FOUND;
    CLOSE cuDatosBase;

IF vbFound then
    vnPidm := vrDatosBase.Pidm;
    vsTerm := vrDatosBase.Perio;
    vFechaCntr := vrDatosBase.FEmi;
    -- BUSCA LA INFOMACION DEL LA PRIMERA PARTE
    vnombre := pk_MatApoderado.f_Apellido(vrDatosBase.RutApo) || ', '
        ||pk_MatApoderado.f_Nombre(vrDatosBase.RutApo);
    valumno := vrDatosBase.ApeAlu || ', ' ||vrDatosBase.NomAlu;
    vrut := vrDatosBase.RutApo;
    vrol := vrDatosBase.IdAlu;
    vcont := psCntr;
    vcarrera := pk_Catalogo.Programa(vrDatosBase.Prog);
    vterm := pk_Catalogo.Periodo(vrDatosBase.Perio);
    vArut := vrDatosBase.RutAlu;


    end if;


    OPEN cuPerioAdmt(vnPidm,vsTerm);
    FETCH cuPerioAdmt INTO vsAdmision;
    CLOSE cuPerioAdmt;

    --
    -- BUSCA EL PROC DE TERM
    OPEN cuAnioPeriodo(vsTerm);
    FETCH cuAnioPeriodo INTO vterm;
    CLOSE cuAnioPeriodo;

    --
    -- BUSCA EL TEXTO DINAMICO DEL CONTRATO SEGUN EL PERIODO DE INSCRIPCION
    vsTipoPerio := vrDatosBase.TipoPerio;

    vvTextContrato := CASE vsTipoPerio
        WHEN 'A' THEN 'I y II semestre (' || vterm
        WHEN '1' THEN 'I semestre (' || vterm
        WHEN '2' THEN 'II semestre (' || vterm
        ELSE pk_util.f_ObtieneParam('TTERM', SUBSTR(vsTerm, 5, 2) )
    END;

    -- BUSCA EL MONTO A PAGAR COMPLETOS
    vlMonto := pk_Matricula.f_MontoContrato(vcont);


    HTP.P('<HTML><HEAD>');
    HTP.P('
        <style type="text/css" >
        <!--
      body.bodyCeroR {
         margin-left: 2cm;
         margin-right: 0cm;
         margin-top: 0pt;
         margin-bottom: 0pt;}
      tr.Estilo1 {
         font-family: "Courier New", Helvetica, sans-serif;
         font-size: 12px;
         line-height: 0.6cm;
         text-align: justify;}
      tr.Estilo2 {
         font-family: "Courier New", Helvetica, sans-serif;
         font-size: 12px;
         text-align: justify;}
      tr.Estilo4 {
         font-family: "Courier New", Helvetica, sans-serif;
         font-size: 12px;
         text-align: justify;}
      H1.SaltoDePagina
        { PAGE-BREAK-AFTER: avoid; }
         --></style>
         </script>
         </head>');
    HTP.P('<BODY onLoad=focus() class="bodyCeroR">');
    HTP.P('<table width=100% border="0">');

    --
    -- CONTROLA LOS TAMANOS DE LAS CELDAS
    htp.p('<tr class="Estilo1" style="line-height: 4.5cm">
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               </tr>');
    --
    -- PAGINA PRIMERA
    --
    htp.p('<tr class="Estilo1"><td colspan="4" >' || to_char(vFechaCntr, 'DD' ) || '</td>
                               <td colspan="7" >' || to_char(vFechaCntr, 'MONTH' ) || '</td>
                               <td colspan="9" >' || to_char(vFechaCntr, 'RRRR' ) ||  '</td>
                               </tr>');

    htp.p('<tr class="Estilo1"><td colspan="13">
                               ' || upper(vrDatosBase.ApeAlu) || ' ' || upper(vrDatosBase.NomAlu) || '</td>
                               <td colspan="4" >' || vlRUTApod || '</td>
                               <td colspan="3" >PARTICULAR</td></tr>');

    htp.p('<tr class="Estilo1"><td colspan="16">

                               ' || REPLACE(pk_matricula.f_DirAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' ') || '</td>
                               <td colspan="4" >' || SUBSTR(REPLACE(pk_matricula.f_RegAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' '),4,30)
                               || ', ' || SUBSTR(REPLACE(pk_matricula.f_ComuAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' '),7,30)   || '</td></tr>');

    HTP.P('<tr class="Estilo1"><td colspan="20" style="line-height: 1.5cm"></td></tr>');


    --
    -- INICIAL LA IMPRESION DE LA INFORMACION
    --

    htp.p('<tr class="Estilo4"><td colspan="3">R.U.T:</td>
                               <td colspan="18">' || vrut || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">CONTRATO:</td>
                               <td colspan="18">' || vcont || '</td></tr>');
    if vbFoundEmp then
    htp.p('<tr class="Estilo4"><td colspan="3">EMPRESA:</td>
                               <td colspan="18">' || valumno || '</td></tr>');
    else
    htp.p('<tr class="Estilo4"><td colspan="3">ALUMNO:</td>
                               <td colspan="18">' || valumno || '</td></tr>');
    end if;

    htp.p('<tr class="Estilo4"><td colspan="3">ROL:</td>
                               <td colspan="18">' || vrol || ' </td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">PROGRAMA:</td>
                               <td colspan="18">' || vcarrera || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">PERIODO (VIGENCIA):</td>
                               <td colspan="18">' || vrDatosBase.PeriodoCFC || '</td></tr>');
--   htp.p('<tr class="Estilo4"><td colspan="3">PERIODO:</td>
--                                 <td colspan="18">I y II Semestre </td></tr>');

    htp.p('<tr class="Estilo4"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="8"></td>
                               <td colspan="12">TOTAL: $  ' || TO_CHAR( vlMonto, ConstglFormato )  || ',--</td></tr>');
--   HTP.P('<tr class="Estilo1"><td colspan="20" style="line-height: 0.5cm"></td></tr>');
    HTP.TABLECLOSE;
    HTP.P('<H1 class="SaltoDePagina"></H1>');
    HTP.P('</BODY></HTML>');
EXCEPTION
  WHEN OTHERS THEN
     htp.p( SQLERRM);
END p_Boleta;

/******************************************************************************
PROCEDIMIENTO:        p_Pagare
OBJETIVO:            En base al contrato indicado, determina cuales la
                    informacion a imprimirse e invoca a pk_MatPagare
PARAMETROS:
psCntr:                Numero del contrato
******************************************************************************/
PROCEDURE p_Pagare(psCntr VARCHAR2) IS

    --Este cursor es para traer los documentos que se pueden imprimir en
    --el pagare y que son del momento de apertura
    CURSOR cuDocus(psCntr VARCHAR2) IS
        SELECT
            TWBDOCU_SEQ_NUM                AS NumSeqDoc
        FROM
            TWBDOCU
            ,TWVPAYM
        WHERE
            TWBDOCU_CNTR_NUM = psCntr
            AND PK_MATRICULA.F_GETBANSTQ('VIGENTE' , TWBDOCU_STATUS_IND) = 'Y'
            AND TWVPAYM_CODE = TWBDOCU_PAYM_CODE
            AND TWVPAYM_PAGARE_IND = 'Y'
            AND EXISTS(
                SELECT
                    1
                FROM
                    TWRDOTR
                WHERE
                    TWRDOTR_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
                    AND TWRDOTR_ORIG_IND = 'O'
            )
        ORDER BY
            TWBDOCU_EXPIRATION_DATE;

    --Este cursor es para obtener la fecha de emision del contrato (y por
    --ende del pagarÃ©) y para sacar el rut del apoderado original
    CURSOR cuDatosCntr(psCntr VARCHAR2) IS
        SELECT
            TWBCNTR_RUT                AS Rut
            ,TWBCNTR_ISSUE_DATE        AS Fecha
        FROM
            TWBCNTR
        WHERE
            TWBCNTR_NUM = psCntr;

    --arreglo para guardar la salida
    vtDocus                pk_Util.t_TblVarchar2;
    --variable para guardar la lista de cupones
    vsDocus                VARCHAR2(4000);
    --Contador comun y corriente
    vni                    PLS_INTEGER;
    --Registro para guardar los datos del contrato
    vrDatosCntr            cuDatosCntr%ROWTYPE;

BEGIN

    --Obtengo los datos base del contrato
    OPEN cuDatosCntr(psCntr);
    FETCH cuDatosCntr INTO vrDatosCntr;
    CLOSE cuDatosCntr;

    --Si el resultado esta vacio, pues a la alver!
    IF vrDatosCntr.Rut IS NULL OR vrDatosCntr.Fecha IS NULL THEN
        HTP.P('No se encontraron los datos del contrato.');
        RETURN;
    END IF;

    --Obtengo los datos de los documentos a imprimirse en el pagare
    OPEN cuDocus(psCntr);
    FETCH cuDocus BULK COLLECT INTO vtDocus;
    CLOSE cuDocus;

    --Si no hubo documentos pues a la goma
    IF vtDocus.COUNT < 1 THEN
        HTP.P('No hay documentos para el pagarÃ©.');
        RETURN;
    END IF;

    --si los hubo creo la cadena de texto
    FOR vni IN 1..vtDocus.COUNT LOOP
        IF vni > 1 THEN vsDocus := vsDocus || ','; END IF;
        vsDocus := vsDocus ||vtDocus(vni);
    END LOOP;

    --Ya que tenemos todos los datos, solo invoco al poderoso pagarÃ©
    pk_MatPagare.p_PagareCFC(psCntr ,vrDatosCntr.Rut
        ,TO_CHAR(vrDatosCntr.Fecha, 'DD/MM/YYYY'),vsDocus);

    --Se acabo :)
END p_Pagare;

/******************************************************************************
PROCEDIMIENTO:        p_Cuponera
OBJETIVO:            En base al contrato indicado, determina cuales la
                    informacion a imprimirse e invoca a pk_MatCupon
PARAMETROS:
psCntr:                Numero del contrato
******************************************************************************/
PROCEDURE p_Cuponera(psCntr VARCHAR2) IS
 vrDatosBase            cuDatosBase%ROWTYPE;
    --cursor para obtener los cupones del contrato
    CURSOR cuCupones(psCntr VARCHAR2) IS
        SELECT
            TO_CHAR(TWBDOCU_SEQ_NUM)            AS NumSeqDoc
        FROM
            TWBDOCU
        WHERE
            TWBDOCU_CNTR_NUM = psCntr
            AND TWBDOCU_PAYM_CODE = 'CUP'
            AND EXISTS(
                SELECT
                    1
                FROM
                    TWRDOTR
                WHERE
                    TWRDOTR_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
                    AND TWRDOTR_ORIG_IND = 'O'
            )
            AND TWBDOCU_STATUS_IND = 'AC'
        ORDER BY
            TWBDOCU_EXPIRATION_DATE, TWBDOCU_DOCU_NUM;
    --arreglo para guardar la salida
    vtCupones            pk_Util.t_TblVarchar2;
    --variable para guardar la lista de cupones
    vsCupones            VARCHAR2(4000);
    --Contador comun y corriente
    vni                    PLS_INTEGER;

BEGIN

    --Obtengo la lista de cupones
    OPEN cuCupones(psCntr);
    FETCH cuCupones BULK COLLECT INTO vtCupones;
    CLOSE cuCupones;

    --Si no hubo cupones...
    IF vtCupones.COUNT < 1 THEN
        HTP.P('No hay cupones para este contrato.');
        RETURN;
    END IF;

    --si los hubo creo la cadena de texto
    FOR vni IN 1..vtCupones.COUNT LOOP
        IF vni > 1 THEN vsCupones := vsCupones || ','; END IF;
        vsCupones := vsCupones ||vtCupones(vni);
    END LOOP;
    OPEN cuDatosBase(psCntr);
    FETCH cuDatosBase INTO vrDatosBase;
    CLOSE cuDatosBase;
    --ultimo paso! invoco la cuponera

    pk_MatCupon.p_CuponeraCFC(vsCupones,vrDatosBase.NomAlu  ||' '|| vrDatosBase.ApeAlu );


END p_Cuponera;



/******************************************************************************
PROCEDIMIENTO:        p_Contrato2011
OBJETIVO:            Imprime al buffer HTP el contrato legal version 2011
                    indicado
PARAMETROS:
psCntr:                Numero del contrato
******************************************************************************/
PROCEDURE p_Contrato2011(
    psCntr                VARCHAR2
) IS
    -- DECLARACION DE VARIABLES LOCALES
    vlNombre            SPRIDEN.SPRIDEN_FIRST_NAME%TYPE;
    vlApellido            VARCHAR2(60);
    vlRutAlu            VARCHAR2(15);
    vlTerm                VARCHAR2(6);
    vlProg                VARCHAR2(60);
    vlMonto                VARCHAR2(20);
    vlID                VARCHAR2(20);
    vnPagina            NUMBER:=1;
    vnRenglon            NUMBER:=1;
    vnRengCon            NUMBER:=0;
    vvContrato            TWBCNTR.TWBCNTR_NUM%TYPE;
    vvTextContrato        VARCHAR2(200);
    vlRUTApod            TWBCNTR.TWBCNTR_RUT%TYPE;
    vlNomApod            TWBAPLE.TWBAPLE_LAST_NAME%TYPE;
    vlApeApoD            TWBAPLE.TWBAPLE_FIRST_NAME%TYPE;
    vsTerm                VARCHAR2(6);
    vnPidm                NUMBER(10);
    vsTipoPerio            VARCHAR2(1);

    --Contador comun y corriente
    vni                    PLS_INTEGER;
    vnj                    PLS_INTEGER;

    --Tipos y tablas para los cursores
    TYPE t_TblDocs IS TABLE OF cuDocs%ROWTYPE;
    vtDocs                t_TblDocs;
    TYPE t_TblCats IS TABLE OF cuCats%ROWTYPE;
    vtCats                t_TblCats;
    vrDatosBase            cuDatosBase%ROWTYPE;

BEGIN

      /* Check/update the user's web session */
--   IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

    OPEN cuDatosBase(psCntr);
    FETCH cuDatosbase INTO vrDatosBase;
    CLOSE cuDatosBase;

    vnPidm := vrDatosBase.Pidm;
    vsTerm := vrDatosBase.Perio;

    --
    -- BUSCA LOS DATOS DEL APODERADO
    --
    vlRUTApod := vrDatosBase.RutApo;
    vlNomApod := pk_MatApoderado.f_Nombre(vlRUTApod);
    vlApeApoD := pk_MatApoderado.f_Apellido(vlRUTApod);

-- --
-- -- BUSCA EL NOMBRE DEL ALUMNO
    vlNombre := vrDatosBase.NomAlu;
    vlApellido := vrDatosBase.ApeAlu;
    vlRutAlu := vrDatosBase.RutAlu;
    vlID := vrDatosBase.IdAlu;

    --
    -- CARGA EL NUMERO DE CONTRATRO
    vvContrato := psCntr;

    -- BUSCA EL PROC DE TERM
    OPEN cuAnioPeriodo(vsTerm);
    FETCH cuAnioPeriodo INTO vlTerm;
    CLOSE cuAnioPeriodo;

    -- BUSCA EL PROGRAMA A CURSAR DEL ALUMNO
    vlProg := pk_Catalogo.Programa(vrDatosBase.Prog);
    --
    -- BUSCA EL TEXTO DINAMICO DEL CONTRATO SEGUN EL PERIODO DE INSCRIPCION
    vsTipoPerio := vrDatosBase.TipoPerio;
    vvTextContrato := CASE vsTipoPerio
        WHEN 'A' THEN 'periodo acad;mico I y II semestre'
        WHEN '1' THEN 'primer semestre del periodo acad;mico'
        WHEN '2' THEN 'segundo semestre del periodo acad;mico'
        ELSE pk_util.f_ObtieneParam('TTERM', SUBSTR(vsTerm, 5, 2) )
    END;

    --Abro mi cursor para obtener los montos
    OPEN cuDocs(vvContrato);
    FETCH cuDocs BULK COLLECT INTO vtDocs;
    CLOSE cuDocs;

    --Obtengo el monto total
    vlMonto := 0;
    FOR vni in 1..vtDocs.COUNT LOOP
        vlMonto := vlMonto + vtDocs(vni).Monto;
    END LOOP;

    HTP.P('<HTML><HEAD> ');
    -- CONFIGURACION DE LA HOJA CON CSS
    HTP.P('
        <style type="text/css" >
        <!--
      body.bodyCeroR {
         margin-left: 16pt;
         margin-right: 15pt;
         margin-top: 2pt;
         margin-bottom: 2pt;}
      td.Estilo2 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 10px;
         text-align: justify;}
      tr.Estilo21 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 12px;
         line-height: 1;
         text-align: justify;}
      td.Estilo22 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 10px;
         text-align: right;}
      tr.Estilo3 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 12px;
         text-align: center;}
      tr.Estilo5 {
         font-family: Arial, Helvetica, sans-serif;
         font-size: 12px;
         line-height: 1;
         text-align: justify;}
      td.Estilo6 {
         font-family: Arial, Helvetica, sans-serif;
         line-height: 1;
         font-size: 15px;
         text-align: right;}
      td.Estilo61{
         font-family: Arial, Helvetica, sans-serif;
         line-height: 1;
         font-size: 15px;
         text-align: justify;}
      H1.SaltoDePagina
        { PAGE-BREAK-BEFORE: always }
         --></style>
         </script>
         </head>
    ');

    HTP.P('<BODY onLoad=focus() class="bodyCeroR" > <table width=100% border="0">');
    HTP.P ('<col span="17" style="width: 3em" />
            <col span="3" style="width: 3.6em" align="right"  />
    ');

    --
    -- PAGINA PRIMERA
    --
    --htp.p('<tr class="Estilo5"><td colspan="20">' || HTF.IMG('/wtlgifs/web_powered_by.gif', cattributes=>'WIDTH=300 HEIGTH=80') ||'</td></tr>');
    htp.p('<tr><td colspan="10" class="Estilo61">' ||htf.img('/wtlgifs/logo_uft.jpg', cattributes=>'WIDTH="100" HEIGTH="40"') || '</td>
               <td colspan="10" class="Estilo6" >' || vlRutAlu || ' / ' || vvContrato  || '<BR> ID ' || vlID || '</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo3"><td colspan="20"><B>CONTRATO DE SERVICIOS EDUCACIONALES</B></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">

     En Santiago, a '||TO_CHAR(vrDatosBase.FEmi
            ,'DD" de "MONTH" de "YYYY')||' entre la Universidad Finis Terrae, con domicilio
         en esta ciudad, Av. Pedro de Valdivia Nº 1509, Providencia, RUT Nº 70.884.700-3, en lo sucesivo la
         Universidad, por una parte, y por otra, Don(a) ' || vlApeApoD || ' ' || vlNomApod || ', RUT Nº ' || vlRUTApod || ', domiciliado(a) en
         ' || pk_MatApoderado.f_Direccion(vlRUTApod, vsTerm) || ', ' || pk_MatApoderado.f_Comuna(vlRUTApod, vsTerm) || ', ' || pk_MatApoderado.f_Ciudad(vlRUTApod,vsTerm)
         || ', en adelante el contratante, se ha convenido el siguiente contrato de prestaci;n de servicios educacionales:
         </td></tr>');



    --
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>PRIMERO:</B> La Universidad, a solicitud del contratante, acepta e inscribe al
         ALUMNO(A), <B>' || vlApellido || ' '  || vlNombre || ' ( ' || vlRutAlu || ')</B>,
         quien se ha matriculado, previo pago o documentaci;n de la matr;cula correspondiente,
         como alumno regular para el ' || vvTextContrato || '
         del año <B>' || vlTerm || ' (' || vsTerm || ' ) </B>, en la carrera de <B>' || vlProg || '</B>
         </td></tr>');

    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>SEGUNDO:</B> El valor total de la colegiatura, incluida la matr;cula ser; de <B>
         $ ' || TO_CHAR( vlMonto, ConstglFormato)  || '</B>, que se pagar; en cuotas mensuales, con vencimientos los
         d;as INDICADOS de cada mes, a contar del mes ESPECIFICADO EN CLAUSULA TERCERA.
         </td></tr>');

--           En caso que el contratante opte por pagar en este acto, al contado, la
--           totalidad de la colegiatura, su valor ser; de $ ************ -


    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>TERCERO:</B> Para facilitar el cumplimiento de la obligaci;n de pago a que se obliga en virtud
         de la cl;usula anterior, as; como tambi;n el pago de la matr;cula, el contratante acepta
         en este acto, la siguiente documentaci;n, con vencimiento en las fechas que se señalan y
         por los montos que se indican:
         </td></tr>');

    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');

    htp.p('<tr class="Estilo21"><td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               <td colspan="1"></td>
                               </tr>');
-- htp.p('<tr><B><td colspan="3" class="Estilo2">Codigo</td>
--                  <td colspan="4" class="Estilo2">Medio de<BR>Pago</td>
--                  <td colspan="3" class="Estilo2">Documento</td>
--                  <td colspan="3" class="Estilo2">Vencimiento</td>
--                  <td colspan="3" class="Estilo2">Banco</td>
--                  <td colspan="4" class="Estilo22">Balance</td>
--                  </tr>');

-- htp.p('<tr><td colspan="1" class="Estilo11">;</td>
--                <td colspan="3" class="Estilo11">Medio de Pago</td>
--                <td colspan="2" class="Estilo11">N;mero de Documento</td>
--                <td colspan="2" class="Estilo11">Banco</td>
--                <td colspan="4" class="Estilo11">Vencimiento</td>
--                <td colspan="4" class="Estilo11">Concepto</td>
--                <td colspan="2" class="Estilo11">Monto</td>
--               </tr>');

    htp.p('<tr><B>
                <td colspan="4" class="Estilo2">Medio de<br/>Pago</td>
                <td colspan="3" class="Estilo2">N;mero de <br/>Documento</td>
                <td colspan="3" class="Estilo2">Banco</td>
                <td colspan="3" class="Estilo2">Vencimiento</td>
                <td colspan="3" class="Estilo2">Concepto</td>
                <td colspan="4" class="Estilo22">Monto</td>
            </tr>');

    FOR vnj IN 1..vtDocs.COUNT LOOP

        --Abro el cursor con las categorias de detalle
        OPEN cuCats(vtDocs(vnj).NumSeqDoc);
        FETCH cuCats BULK COLLECT INTO vtCats;
        CLOSE cuCats;

        htp.p('<tr><td colspan="4" rowspan="'||vtCats.COUNT||'" class="Estilo2">'|| vtDocs(vnj).DescMP ||'</td>
                    <td colspan="3" rowspan="'||vtCats.COUNT||'" class="Estilo2">'|| vtDocs(vnj).NumDocu ||'</td>
                    <td colspan="3" rowspan="'||vtCats.COUNT||'" class="Estilo2">'|| vtDocs(vnj).Banco ||'</td>
                    <td colspan="3" rowspan="'||vtCats.COUNT||'" class="Estilo2">'|| TO_CHAR(vtDocs(vnj).FechaVen,'DD/MM/YYYY')||'</td>');

        FOR vni IN 1..vtCats.COUNT LOOP
            IF vni > 1 THEN HTP.P('<tr>'); END IF;
            HTP.P('<td colspan="3" class="Estilo2">'|| vtCats(vni).Categoria||'</td>');
            HTP.P('<td colspan="4" class="Estilo22">'|| TO_CHAR(vtCats(vni).Monto, ConstglFormato)||'</td>');
            HTP.P('</tr>');

            -- REGLONES DE DATOS
            vnRenglon := vnRenglon + 1;
            vnRengCon := vnRengCon + 1;

        END LOOP;

        -- VALIDACIONES  PARA EL SALTO DE PAGUINA
        IF (vnPagina = 1 AND vnRenglon >= 45) THEN
            -- REALIZA SALTO DE PAGINA PARA LA DOS
            HTP.TABLECLOSE;
            HTP.HEADER(1, '', cattributes=>'class=SaltoDePagina' );
            HTP.P ('<table width=100%  border="0">');
            HTP.P ('<col span="17" style="width: 3em" />
                 <col span="3" style="width: 3.6em" align="right"  />');

            htp.p('<tr class="Estilo21"><td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       <td colspan="1"></td>
                                       </tr>');

            -- INICIALIZA UNOS VARIABLES DE CONTROL
            vnPagina := vnPagina + 1;
            vnRenglon := 1;
        END IF;

    END LOOP;

    IF (vnRengCon <= 45 AND vnRengCon >= 40 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table width=100% border="0">');
    END IF;

    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         La Universidad NO est; obligada a notificar en cada oportunidad las fechas de pago y
         se reserva el derecho de efectuar la cobranza en forma directa o a trav;s de una entidad
         bancaria o financiera, vencidos los plazos establecidos en la Ley 19.496.
         </td></tr>');

    IF (vnRengCon <= 39 AND vnRengCon >= 35 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table  width=100% border="0">');
    END IF;

    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>CUARTO:</B> En virtud del presente contrato, la Universidad se obliga a mantener el
         cupo asignado al alumno regular en los servicios docentes que prestar; durante el año
         acad;mico, sin perjuicio de lo dispuesto en la cl;usula s;ptima de este contrato.
         </td></tr>');

    IF (vnRengCon <= 34 AND vnRengCon >= 30 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table width=100% border="0">');
    END IF;

    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>QUINTO:</B> Los cursos que la Universidad impartir; durante el año acad;mico señalado
         en la cl;usula primera ser;n los que correspondan al curr;culo de la carrera, seg;n sea
         que ;l se desarrolle en forma semestral o anual. En ning;n caso disminuir; el valor de la
         colegiatura si el alumno no toma o no puede tomar, por cualquier causa, el total de los
         cursos contemplados en el curr;culo respectivo. Lo mismo ser; v;lido por si cualquier
         causa justificada, no se impartiere un determinado curso del curr;culo correspondiente
         a un periodo acad;mico determinado.
         </td></tr>');

    IF (vnRengCon <= 29 AND vnRengCon >= 25 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table width=100% border="0">');
    END IF;

    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>SEXTO:</B> La mora o el simple retardo en el pago de una o m;s cuotas facultar; a
         la Universidad para exigir el pago de toda la deuda y sus intereses, como si
         fuera de plazo vencido. Si la Universidad no ejerciere este derecho en caso
         alguno significar; que renuncia al mismo.
         </td></tr>');
/*
    IF (vnRengCon <= 25 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table width=100% border="0">');
    END IF;
*/
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          En este caso, durante el per;odo de mora de cualquiera de las cuotas,
          la Universidad estar; facultada para cobrar el inter;s m;ximo convencional
          para operaciones no reajustables, calculado desde la fecha de vencimiento
          original hasta la de pago efectivo. <B>En el evento que el pago se efectuara
          en la Universidad y no en la entidad bancaria o financiera, tendr; un costo
          adicional por servicio administrativo ascendente a $5.000.</B>
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          Mientras persista la mora o el simple retardo en el pago de una o m;s cuotas del
          valor de la colegiatura, el alumno no podr; presentarse a ex;menes, inscribir cursos
          para el per;odo acad;mico siguiente, recibir su t;tulo profesional o grado acad;mico u
          obtener certificaciones. Lo mismo ocurrir; mientras el alumno no haya devuelto
          oportunamente bienes o materiales entregados en pr;stamo.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          <B>S;PTIMO:</B> El contratante estar; obligado a pagar oportunamente el total de la suma acordada
          por el periodo completo convenido, a;n cuando el alumno no hiciere uso del servicio educacional
          contratado, por cualquier causa, tales como retiro, suspensi;n o anulaci;n de periodos acad;micos
          no procediendo devoluci;n, imputaci;n ni compensaci;n alguna, toda vez que la universidad ha adquirido
          compromisos acad;micos y econ;micos para la prestaci;n de los servicios contratados. Esta obligaci;n
          persistir; en el caso que el alumno sea eliminado como consecuencia de su rendimiento acad;mico o si
          fuera sancionado reglamentariamente con la suspensi;n o expulsi;n de la Universidad por haber incurrido
          en falta grave de acuerdo con el Reglamento del Alumno.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          La misma obligaci;n existir; en caso de impedimento temporal de la Universidad para prestar el servicio
          educacional por eventos de fuerza mayor, ya sea naturales o provocados por terceras personas. El alumno
          se obliga tambi;n a pagar el respectivo derecho o arancel de licenciamiento o titulaci;n
          que anualmente fija la Universidad para cada una de sus carreras, en el momento en que de inici;
          a su proceso de licenciamiento o titulaci;n.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          <B>OCTAVO:</B> Para todos los efectos legales derivados del presente contrato, las partes fijan domicilio
          en la ciudad de Santiago y se someten a la jurisdicci;n de los Tribunales Ordinarios de Justicia.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          <B>NOVENO:</B> El contratante declara haber le;do y conocer el texto y alcance del presente
          contrato y lo acepta en su totalidad.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          <B>D;CIMO:</B> El presente contrato se firma en dos ejemplares del mismo tenor y efecto,
          quedando uno en poder de cada parte.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20"></td></tr>');
    htp.p('<tr class="Estilo1"><td colspan="3"></td>
                               <td colspan="7">' ||
                               HTF.IMG('/wtlgifs/firma_contrato.jpg', cattributes=>'WIDTH="140" HEIGTH="60"') || '
                               <td colspan="10"></td></tr>');
    htp.p('<tr class="Estilo1"><td colspan="3"></td>
                               <td colspan="5">_________________________________</td>
                               <td colspan="7"></td>
                               <td colspan="5">_________________________________</td></tr>');

    htp.p('<tr class="Estilo1"><td colspan="3"></td>
                               <td colspan="5">UNIVERSIDAD FINIS TERRAE</td>
                               <td colspan="7"></td>
                               <td colspan="5"> CONTRATANTE</td></tr>');
    HTP.TABLECLOSE;
    HTP.P('</BODY></HTML>');
EXCEPTION
  WHEN OTHERS THEN
     htp.p(SQLERRM);
END p_Contrato2011;


/******************************************************************************
PROCEDIMIENTO:        p_ContratoIndividual
OBJETIVO:            Imprime al buffer HTP el contrato legal version 2013
                    indicado
PARAMETROS:
psCntr:                Numero del contrato
Modificado: vdelacruz 20130729

******************************************************************************/
PROCEDURE p_ContratoIndividual(psCntr VARCHAR2) IS
  --Tipos y tablas para los cursores
    TYPE t_TblDocs IS TABLE OF cuDocs%ROWTYPE;
    vtDocs                t_TblDocs;
    TYPE t_TblCats IS TABLE OF cuCats%ROWTYPE;
    vtCats                t_TblCats;

    --AÃ±o del periodo
    vsYear                VARCHAR2(4);
    --Registro con los datos base del contrato
    vrDatosBase            cuDatosBase%ROWTYPE;
    --Descripcion del periodo
    vsDescPerio            VARCHAR2(200);
    --DescripciÃ³n del programa
    vsDescProg            VARCHAR2(30);
    --Nombre Completo del apoderado
    vsNomCApo            VARCHAR2(91);
    --Monto Total del contrato
    vnMonto                NUMBER(16,2) := 0;
    --Numero de renglones, ojo este es importante para los saltos de linea
    vnNumReng            PLS_INTEGER;
    --Contadores comunes y corrientes
    vni                    PLS_INTEGER;
    vnj                    PLS_INTEGER;
    vnk                    PLS_INTEGER:=0;
     --vsNivelCFC          VARCHAR2(10);

     CURSOR cuFechaEmi(psCntr VARCHAR2) IS
        SELECT
            TWBCNTR_ISSUE_DATE            AS Fecha
        FROM
            TWBCNTR
        WHERE
            TWBCNTR_NUM = psCntr;

    --Fecha de corte 2013, esto no es parametrizable, debe ser duuuurooo
    --como el corazon de tu exnovia!!! jajajaja
    vdF2013                DATE := TO_DATE('01/01/2013','DD/MM/YYYY');
    vdF2014_ebustos        DATE := TO_DATE('01/01/2014','DD/MM/YYYY');
    --Fecha de emision del contrato
    vdFEmi                DATE;
    vsNivelCFC          VARCHAR2(10);
BEGIN

    --Obtengo los datos del contrato
    OPEN cuDatosBase(psCntr);
    FETCH cuDatosBase INTO vrDatosBase;
    CLOSE cuDatosBase;

   OPEN cuNivelCFC(psCntr);
    FETCH cuNivelCFC INTO vsNivelCFC;
    CLOSE cuNivelCFC;

    --Si la fecha de emision es igual o mayor que la del 2013 ejecutamos el
    --contrato 2013
    IF vsNivelCFC = 'DI' THEN
       p_ContratoDiplomado(psCntr);
   ELSE
        --Sino ejecutamos el contrato clasico
     -- p_ContratoIndividual(psCntr);


    --Obtengo el nombre completo del apoderado
    vsNomCApo := pk_MatApoderado.f_Nombre(vrDatosBase.RutApo)||' '
        ||pk_MatApoderado.f_Apellido(vrDatosBase.RutApo);

    --Obtengo la descripcion del periodo
    vsDescPerio := CASE vrDatosBase.TipoPerio
        WHEN 'A' THEN 'los periodos académicos I y II semestre'
        WHEN '1' THEN 'el primer semestre del periodo académico'
        WHEN '2' THEN 'el segundo semestre del periodo académico'
        ELSE 'el '
            ||pk_util.f_ObtieneParam('TTERM', SUBSTR(vrDatosBase.Perio,5,2))
    END;

    --Obtengo el aÃ±o del periodo
    OPEN cuAnioPeriodo(vrDatosBase.Perio);
    FETCH cuAnioPeriodo INTO vsYear;
    CLOSE cuAnioPeriodo;

    --Abro mi cursor para obtener los documentos
    OPEN cuDocs(psCntr);
    FETCH cuDocs BULK COLLECT INTO vtDocs;
    CLOSE cuDocs;

    --Obtengo el monto del contrato
    FOR vni in 1..vtDocs.COUNT LOOP
        vnMonto := vnMonto + vtDocs(vni).Monto;
        vnk:= vnk +1;
    END LOOP;
        --Comienzo la impresion de mi poderoso HTML
    HTP.P(
'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
    <head>
        <title> Contrato </title>
        <style type="text/css">
            body{
                font-size: 13px;
                font-family: Arial, Helvetica, sans-serif;
                margin-left:auto;
                margin-right:auto;
                margin-top:0;
                border:0;
                width: 18cm;
            }

            p.Art{
                text-align:justify;
                margin-top:0.4cm;
                margin-bottom:0.4cm;
                page-break-inside: avoid;
            }

            span.NumArt{
                font-weight:bold;
            }

            p.Titulo{
                text-align:center;
                font-weight:bold;
                margin-top:1cm;
                margin-bottom:1cm;
            }

            td.Firma{
                width:46%;
                vertical-align:bottom;
            }

            td.SubF{
                vertical-align:top;
            }

            table.Docs{
                margin-left:auto;
                margin-right:auto;
                font-size:10px;
            }

            td.DocH{
                text-align:center;
                font-weight:bold;
            }

            td.Monto{
                text-align:right;
                font-weight:bold;
            }

            div.Salto{
                page-break-before:always;
                margin:0;
                border:0;
                padding:0;
                height:0;
                width:100%;
            }
.tablapagoscfc {
    margin:0px;padding:0px;
    width:100%;
    border:1px solid #000000;

    -moz-border-radius-bottomleft:0px;
    -webkit-border-bottom-left-radius:0px;
    border-bottom-left-radius:0px;

    -moz-border-radius-bottomright:0px;
    -webkit-border-bottom-right-radius:0px;
    border-bottom-right-radius:0px;

    -moz-border-radius-topright:0px;
    -webkit-border-top-right-radius:0px;
    border-top-right-radius:0px;

    -moz-border-radius-topleft:0px;
    -webkit-border-top-left-radius:0px;
    border-top-left-radius:0px;
}.tablapagoscfc table{
    border-collapse: collapse;
        border-spacing: 0;
    width:100%;
    height:100%;
    margin:0px;padding:0px;
}.tablapagoscfc tr:last-child td:last-child {
    -moz-border-radius-bottomright:0px;
    -webkit-border-bottom-right-radius:0px;
    border-bottom-right-radius:0px;
}
.tablapagoscfc table tr:first-child td:first-child {
    -moz-border-radius-topleft:0px;
    -webkit-border-top-left-radius:0px;
    border-top-left-radius:0px;
}
.tablapagoscfc table tr:first-child td:last-child {
    -moz-border-radius-topright:0px;
    -webkit-border-top-right-radius:0px;
    border-top-right-radius:0px;
}.tablapagoscfc tr:last-child td:first-child{
    -moz-border-radius-bottomleft:0px;
    -webkit-border-bottom-left-radius:0px;
    border-bottom-left-radius:0px;
}.tablapagoscfc tr:hover td{
    background-color:#ffffff;


}
.tablapagoscfc td{
    vertical-align:middle;

    background-color:#ffffff;

    border:1px solid #000000;
    border-width:0px 1px 1px 0px;
    text-align:center;
    padding:7px;
    font-size:10px;
    font-family:Arial;
    font-weight:normal;
    color:#000000;
}.tablapagoscfc tr:last-child td{
    border-width:0px 1px 0px 0px;
}.tablapagoscfc tr td:last-child{
    border-width:0px 0px 1px 0px;
}.tablapagoscfc tr:last-child td:last-child{
    border-width:0px 0px 0px 0px;
}
.tablapagoscfc tr:first-child td{
        background:-o-linear-gradient(bottom, #ffffff 5%, #ffffff 100%);    background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #ffffff), color-stop(1, #ffffff) );
    background:-moz-linear-gradient( center top, #ffffff 5%, #ffffff 100% );
    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr="#ffffff", endColorstr="#ffffff");    background: -o-linear-gradient(top,#ffffff,ffffff);

    background-color:#ffffff;
    border:0px solid #000000;
    text-align:center;
    border-width:0px 0px 1px 1px;
    font-size:12px;
    font-family:Arial;
    font-weight:bold;
    color:#000000;
}
.tablapagoscfc tr:first-child:hover td{
    background:-o-linear-gradient(bottom, #ffffff 5%, #ffffff 100%);    background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #ffffff), color-stop(1, #ffffff) );
    background:-moz-linear-gradient( center top, #ffffff 5%, #ffffff 100% );
    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr="#ffffff", endColorstr="#ffffff");    background: -o-linear-gradient(top,#ffffff,ffffff);

    background-color:#ffffff;
}
.tablapagoscfc tr:first-child td:first-child{
    border-width:0px 0px 1px 0px;
}
.tablapagoscfc tr:first-child td:last-child{
    border-width:0px 0px 1px 1px;
}

        </style>
    </head>
    <body>
        <table style="width:100%">
            <tr>
                <td style="text-align:left;">
                <!--    <img src="/wtlgifs/logo_uft.jpg" style="width:4cm;"/> -->
                </td>
                <td style="text-align:right;font-weight:bold;">
                    Rut: '||vrDatosBase.RutAlu||'/ Contrato '||psCntr||'<br/>
                    ID: '||vrDatosBase.IdAlu||'
                </td>
            </tr>
        </table>
        <p class="Titulo">CONTRATO DE SERVICIOS EDUCACIONALES</p>
        <p class="Art">
            En Santiago, a '||TO_CHAR(vrDatosBase.FEmi
            ,'DD" de "MONTH" de "YYYY')||' entre la Universidad Finis Terrae,
            con domicilio en esta ciudad, Av. Pedro de Valdivia No. 1509,
            Providencia, RUT No. 70.884.700-3, en lo sucesivo la
            Universidad, por una parte, y por otra, don(a) '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu ||',
            RUT: '||vrDatosBase.RutAlu||', domiciliado(a) en '
             ||
            REPLACE(pk_matricula.f_DirAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' ')

         ||' , ' ||
       SUBSTR(REPLACE(pk_matricula.f_RegAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' '),4,30)
        ||' , '||

         SUBSTR(REPLACE(pk_matricula.f_ComuAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' '),7,30)

         ||', en adelante el
            contratante, se ha convenido el siguiente contrato de
            prestación de servicios educacionales:
        </p>

        <p class="Art">
            <span class="NumArt">PRIMERO:</span> La Universidad, a solicitud del
            contratante, acepta e inscribe a don(a), '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu ||',
            quien se ha inscrito , mediante pago o documentación del arancel
            correspondiente, como alumno regular para el periodo académico '
            ||vrDatosBase.PeriodoCFC||' en<b> '||vrDatosBase.Nivel ||' de ' || pk_Catalogo.Programa(vrDatosBase.Prog)||'.
       </b>
        </p>


        <p class="Art">
            <span class="NumArt">SEGUNDO:</span>En virtud del presente contrato, la Universidad se obliga
             a mantener el cupo asignado al alumno regular del programa en los servicios docentes que prestará
             durante el período académico, sin perjuicio de lo dispuesto en la cláusula séptima de este contrato.
        </p>



        <p class="Art">
            <span class="NumArt">TERCERO:</span> Los cursos que la Universidad impartirá durante el período académico señalado
            en la cláusula anterior serán los que correspondan al currículo de la carrera, según sea que él se desarrolle en forma
            semestral o anual. En ningún caso disminuirá el valor del arancel si el alumno no toma o no puede tomar, por cualquier causa, el total de los
             cursos contemplados en el currículo respectivos. Lo mismo será válido si por cualquier causa justificada, no se impartiere un determinado
              curso del currículo correspondiente a un periodo académico determinado. La coordinación de los cursos estará entregada al
              Centro de Formación Continua de la Universidad Finis Terrae y su administración a las distintas Facultades y/o Escuelas.
        </p>
         <p class="Art">


            <span class="NumArt"> CUARTO:</span> El valor total del arancel será de $' ||TO_CHAR(vnMonto,ConstglFormato)||', que se pagará en
            cuotas mensuales
            ('||vnk||'). con vencimientos los días 30 de cada mes,
             A contar de '|| f_get_mes(TO_CHAR(vtDocs(1).FechaVen,'MM'))||' '|| TO_CHAR(vtDocs(1).FechaVen,'YYYY')||'
            . En caso que el contratante opte por pagar en este acto, al contado, la totalidad del arancel, su valor será de  $'||TO_CHAR(vnMonto,ConstglFormato)||'.<p>
         <p class="Art">
            <span class="NumArt">
QUINTO: </span>Para facilitar el cumplimiento de la obligación de pago a que se obliga
en virtud de la cláusula anterior, el contratante, acepta en este acto, la siguiente
documentación, con vencimiento en las fechas que se señalan y por los montos
que se indican:
<div class="tablapagoscfc">
        <table>
            <tr>
                <td>Medio de<br/>Pago</td>
                <td> Número de<br/>Documento </td>
                <td>Banco</td>
                <td>Vencimiento</td>
                <td>Concepto</td>
                <td>Monto</td>
            </tr>
'
    );

    --Inicializo los renglones
    vnNumReng := 0;

    --Comienzo a recorrer los renglones
    FOR vni IN 1..vtDocs.COUNT LOOP

        --Obtengo las categorias de detalle
        OPEN cuCats(vtDocs(vni).NumSeqDoc);
        FETCH cuCats BULK COLLECT INTO vtCats;
        CLOSE cuCats;

        --Comienzo a recorrer las categorias del documento
        FOR vnj IN 1..vtCats.COUNT LOOP

            IF vnj = 1 THEN
                --Si es el primer registro del documento imprimimos todos los
                --datos
                HTP.P(
'            <tr>
                <td>'||vtDocs(vni).DescMP||'</td>
                <td>'||vtDocs(vni).NumDocu||'</td>
                <td>'||vtDocs(vni).Banco||'</td>
                <td>'||TO_CHAR(vtDocs(vni).FechaVen,'DD/MM/YYYY')||'</td>
                <td>'|| vtCats(vnj).Categoria ||'</td>
                <td>$'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato) ||'</td>
            </tr>
'
                );
            ELSE
                --Si no solo la categoria y el monto
                HTP.P(
'            <tr>
                 <td>'||vtDocs(vni).DescMP||'</td>
                <td>'||vtDocs(vni).NumDocu||'</td>
                <td>'||vtDocs(vni).Banco||'</td>
                <td>'||TO_CHAR(vtDocs(vni).FechaVen,'DD/MM/YYYY')||'</td>
                <td>'|| vtCats(vnj).Categoria ||'</td>
                <td>$'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato) ||'</td>
            </tr>
'
                );
            END IF;

            --sumo un renglon a mi contador de renglones
            vnNumReng := vnNumReng + 1;
        END LOOP;
--
    END LOOP;

    --Cierro mi tabla de documentos
    HTP.P(
'        </table></div>'
    );

    --Aqui se van insertando los saltos de pagina como se vayan requiriendo
 /*
 IF vnNumReng BETWEEN 38 AND 40 THEN
      HTP.P(
'        <div class="Salto"><div/>'
       );
 END IF;

*/
    HTP.P(
'        <p class="Art">
           La Universidad NO está obligada a notificar en cada oportunidad las fechas de
pago y se reserva el derecho de efectuar la cobranza en forma directa o a
través de una entidad bancaria o financiera.
        </p>'
    );

/*
 IF vnNumReng BETWEEN 34 AND 47 THEN
        HTP.P(
'        <div class="Salto"><div/>'
      );
 END IF;
*/

    HTP.P(
'        <p class="Art">
            <span class="NumArt">SEXTO:</span>  La mora o el simple retardo en el pago de una o más cuotas facultará
a la Universidad para exigir el pago de toda la deuda y sus intereses, como si
fuera de plazo vencido. Si la Universidad no ejerciere este derecho en caso
alguno significará que renuncia al mismo.
        </p>'
    );

/*
IF vnNumReng BETWEEN 27 AND 33 THEN
HTP.P(
'        <div class="Salto"><div/>'
       );
   END IF;
*/

    HTP.P(
'        <p class="Art">
            En este caso, durante el periodo de mora de cualquiera de las cuotas, la
Universidad estará facultada para cobrar el interés máximo convencional para
operaciones no reajustables, calculando desde la fecha de vencimiento original
hasta la de pago efectivo.
</p>
<p class="Art">
Mientras persista la mora o el simple retardo en el pago de una o más cuotas
del valor de la colegiatura, el alumno no podrá presentarse a inscribir cursos
para el período académico siguiente, recibir su certificado o grado académico u
obtener certificaciones. Lo mismo ocurrirá mientras el alumno no haya devuelto
bienes o materiales entregados en préstamo.
        </p>'
    );
/*
    IF vnNumReng BETWEEN 23 AND 26 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;

  */
    HTP.P(
'        <p class="Art">
            <span class="NumArt">SÉPTIMO:</span> :<b> El contratante estará obligado a pagar oportunamente el total
de la suma acordada por el periodo completo convenido, salvo
expresamente en los siguientes casos:
<p>
En caso de que un participante (cliente) de un curso abierto, se retire,
este deber; enviar e-mail o carta formal informando su decisión.
</p>
<p>
Si el aviso se realiza 10 o más dias de anticipación en que ha decidido
cancelar la realización de un curso, se reembolsará el valor total del curso
menos un 20% por concepto de gastos de administración.
</p>
<p>
Si el aviso se realiza con menos de 10 días de anticipación y hasta 5 días
antes de la fecha de inicio del programa sólo se reembolsará el 50% del
valor total del curso.</p>
<p>
Los retiros con posterioridad a este plazo no tendrán derecho a reintegro,
aún cuando el alumno no hiciere uso del servicio educacional contratado,
por cualquier causa, tales como retiro, suspensión o anulación de
periodos académicos, no procediendo devolución, imputación ni
compensación alguna, toda vez que la Universidad ha adquirido
compromisos académicos y económicos para la presentación de los
servicios contratados. Esta obligación persistirá en el caso que el alumno
sea eliminado como consecuencia de su rendimiento académico o
expulsión de la Universidad por haber incurrido en falta grave de acuerdo
con el Reglamento de Alumno.</b><p>

La misma obligación existirá en caso de impedimento temporal de la
Universidad para prestar servicio educacional por evento o fuerza mayor, ya
sea naturales o provocados por terceras personas.

        </p>'
    );

/*
    IF vnNumReng BETWEEN 19 AND 22 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
*/
    HTP.P(
'        <p class="Art">
            <span class="NumArt">OCTAVO:</span>Para todos los efectos legales derivados del presente contrato, las
partes fijan domicilio en la ciudad de Santiago y se someten a la jurisdicción de
los Tribunales Ordinarios de Justicia.</p>'

    );


    HTP.P('
        <p class="Art">
            <span class="NumArt">NOVENO:</span> El contratante declara haber leído y conocer el texto y alcance del
presente contrato y lo acepta en su totalidad.
        </p>


        <span class="NumArt">DÉCIMO </span>El presente contrato se firma en dos ejemplares del mismo tenor y efecto,
        quedando uno en poder de cada parte.

        </p>');


    --Cierro mi tabla de documentos
    HTP.P(
'        </table>'
    );
       htp.p(' <table style="width:100%;text-align:center;page-break-inside: avoid;">
            <tr>
                <td class="Firma">');



    OPEN cuFechaEmi(psCntr);
    FETCH cuFechaEmi INTO vdFEmi;
    CLOSE cuFechaEmi;

    --Si la fecha de emision es igual o mayor que la del 2013 ejecutamos el
    --contrato 2013
    --htp.p(vdFEmi);
   --htp.p(vdF2014_ebustos);
    IF  TRUNC(vdFEmi) < trunc(vdF2014_ebustos) THEN
    --htp.p(vdFEmi);
    --htp.p(vdF2014_ebustos);
        HTP.P('<img src="http://uft.lcred.net/imagenes/f_sfte.png" style="width:4cm;">');
    ELSE


htp.p('<img src="data:image/jpg;base64,');
htp.p('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDABALDA4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9PDkzODdASFxOQERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/wgALCACAAJcBAREA/8QAGgABAAMBAQEAAAAAAAAAAAAAAAEEBQMCBv/aAAgBAQAAAAH6AAARIAAABwqaNbxCPGkAcq1S7Z9mLOxIDGjV6kcMnZrXgRm+O0TM++PnSo3wipWy7/TVlGd6u17SSnSnneuyVHLpbqWOjjzqd7fur4u+czRp+rwZ3LUz9JgV/p87v6z+2kGbpRmacfO69uney2l6RLn0Z/S358+XTH2pAAecuj9B0AARX4XvQAAAAAAB/8QAKRAAAgIBAgQGAgMAAAAAAAAAAgMBBAARExASFCAFISMkMDM0UCIxMv/aAAgBAQABBQL9Y1kLgmuDgT1jO8c5zWJzWzm+QZWeTz+FhwsFjpnMVl+zzYIwMcb7ZyV9IP8AfwmzcsugiJYQsOw2gAojctsjmXTmZr973FKwLp64QNYIuK5uqgs5rBZtNnIrrxoxJ1POcqfX3TMum2xYoU1gh0sniELk+xM85UvxynQa4+37WzJEQN0qV4iRTD2xXjtss20AG3Wo/i2frywo2wAwA8Gs21qHbCPdMslPKIwA5YdsgmyDjyZiML17Z/4o/ix6lntZPPZnmtzEQML9W3w8SPSfDR9fHK6g0JhIPnRC2bVJIOWXbV828KH05rrjFTbtIrgjJnTKpEQ54gfLXqqnNfPtgBguE15gxUXDSIz+RYeggjySRQAr93Y+eY1gXGlcQ28YBAD85b2dOTMiIiP1v//EADUQAAECAwUFBQYHAAAAAAAAAAEAAgMREhAhMUFREyAiYXEjMkJSgTBAUGKCsQQzQ3KRobL/2gAIAQEABj8C+GX45DVML2tpcZSzslVM6C9cMF3rcvy2D6l3IZ9V2sJzRqL08y7MYeyLn');
htp.p('YBbaNKr/KDoY4GZnVdo8u5YBSaANwQWYnFNiMw8Y19lS0VUYDmhDnVFd/DQg1uA3SahcpnwiZ6pw1CbPEXewfs7mtxcmBonEeqoruN2JUnTb1XZse/oFcxrOpXHGP0iSvm7qUyE0XYlRX6usP7jv0i5gxOqdCBvNwaEYgaJ92Z+y2n4mIZ/ZVtZJg7vPnuxYvoEOpRKaDnvbJv1HQI1v2UFuTVtS2XlCdFYaBPhIz5qcR7onXDdcc8AqeSaqPOZWANiUaoNbgLS5Tf3je4qr9FuHzIQ2959yDRgLKpTvlJOa3Ef3ZeZIN8MK89UeiYvlh/feDfDDFRVIBbBzPmUhgnvyZwi2GPVE6CymZAbpqqRfqU88lDl33d0IN4aMzmTvRznXK12tRnbEkZBty4cZX2Oc5spmfWyXmuQiv0k0aBS3i4C842l8GJsycRKYXaxC/lgLLgs2pzswEzoi5xkAtoR2bMOfuBCodBfNueSv4YYQa0SA9w4aPVdu+Y8owUgJD4d/8QAKRABAAIBAgUDBAMBAAAAAAAAAQARMSFBEFFhgbEgcaEwQJHRUMHw4f/aAAgBAQABPyH+MHtlaDlRUaGtaX14fLAXxNx+tI2Xu7SrwGR1m6NJAuDS51+k/X9ktKBml4HKIpOPAxfV0t4JRi8g9CDIap4mrFNHmQQCNj9F/iedb7RQTEfXoFDLFhoLq5Tan5JBZwhALevt9BAdB/SQqd1gZV5xIRS+c8ie4SJqfOTQmz73vEPisIA2U6zC4ltM2nb/ANiOJo/3a+tCrhPwIGCrIsSpxPb7CBCmGoNECygq2r6bfEXskNM7p8zpcXKibpaPXXgI4b9ApaXWBpuxMiTNpybHN6x3h9Qbw5FBs/D01Bl+RldvNfvPJ8xWBkP3g');
htp.p('AAYIhYXhuQeKCjiTG2Dmy9bcEuSKXRzfqYmrXobsMmgo4BnaBbMSKub4cKWqzRcVLrIKl6p5XmK9NQru9VxXgfPaOqNkKej2hk6GgR8m+9vx6Q3F3Buui93zJZxS2mVnQpyiGxrqMpbu90epXf6BwcSqm7hAYa1KPwgf93mqWuBc4A1Zg583fBf31cIo0gVACtx09QODO58XccyDtFfhhAAKCiFtAvVomg4bzpbDlidXMFPphQMhZ7bRd32HWwqEFAqmXW5qfa2x/1mxyB9hyr6pikezcGhBgP47//aAAgBAQAAABAAAIAAAA/4AcEAILA37gqmIVh2OJwEJ8F6AQaCAAIAAYAAAAAAAP/EACkQAQABAwIGAgIDAQEAAAAAAAERACExQVFhcYGRobEQIDDwUMHRQOH/2gAIAQEAAT8Q/jJe1hZ2gVOV2ZpnQ9vi0HbXsSpwTmyh5Z8VnEbN6FZjwnsChoQyQ+LFw6U/FRk5ieXaT8S5gMGVoHFprTOONmnXdpxPo9GmYywYPN6k5dM3gZ6tHzHRB9G7U24nHVl/9p3hMrINpoi0ZYEiYT8L9Ycavd6HtWUb1DjEOWrUMwI4rqvF+gEgHFpx9SEq8KkfN7XS6EHSjPFBPKlCleoIeI++CWpEwt1O68dKgrXimlVsT4qcaI3dIMwbVKrbbiHLJ1oVHKz3MFW0kMszpQG2Fl8ou0A3r8TjxVn5gRbpRLFKjkW91cozFGXoqfcx4IZCvRu0dXFSBkggx1qbJiAEAAbzSBM0QO0/5S1LQVDlTpt1frrCF7S/2mhk2jiqlXX7ChCQ5FmbcdfgGQGJH6JeDB/SXSpIIogTYl3f0pZOHVu8bvFQt6hGPQbcqUjkkDsWetABAQH00pMG9ipgCXzwv5pT+7KpLWzGYcuw0TYBAGhQODhX2p01qwd4+bmbZvFg704rnzXnsFqKmkGtHqmz91orV3D9gPdF+GDgfANoYoSePelgKQIWGu');
htp.p('4+C0AEiJXBzota50Xg6f7RLYE8V+xxUePHdHN2Pf2GQHwFnQgza8camoeWuCDjiohJQGAqQ7i2ZXX9ck+XHjJvrg/ugzGfmp8EcYXI4HoHmnS3ZpatX/izeMNJzeiJnkZoiqScqold/B9pBzJByYPb8JEhLGKUjlLcNv6j4YRgsU3qfIwkklo9qzlSjZGsaXpwgMWN6igkGQG1jJEGfgAYFBrBd9eanb0UUZjdzQnmEW6L4vhx9o06wbMTx+VBTMRG8sNDzwRdYLvejQgsBpQswsBL0zTCCKwSDeGQPPKoCyDNYNCJFsfKhAFOAFFn5ba24++3/BeWJpbSVbvP5GY0AjegLmb1D5NKLoKA/OzFs0gwZs/gH3TUTZh7+rQNBgEAcv47/9k="/>');

    END IF;

                        HTP.P('<br/>
                    <hr/>
                </td>
                <td></td>
                <p style="font-size: 9px;">La factura correspondiente se emitirá en forma electrónica y se enviará al correo y/o domicilio del suscriptor dentro de las 48 horas siguientes al cierre del contrato.</p>
                <td class="Firma"><hr/></td>
            </tr>
            <tr>
                <td class="SubF">
                    UNIVERSIDAD FINIS TERRAE<br/>
            <br/>

                </td>
                <td></td>
                <td class="SubF">
                    CONTRATANTE<br/>
                    '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu||'<br/>
                    '||vrDatosBase.RutAlu||'
                </td>
            </tr>
        </table>
    </body>
</html>'
    );
   END IF;

END p_ContratoIndividual;
PROCEDURE p_Contrato_firma_ebustos_2014(psCntr VARCHAR2) IS
  --Tipos y tablas para los cursores
    TYPE t_TblDocs IS TABLE OF cuDocs%ROWTYPE;
    vtDocs                t_TblDocs;
    TYPE t_TblCats IS TABLE OF cuCats%ROWTYPE;
    vtCats                t_TblCats;

    --AÃ±o del periodo
    vsYear                VARCHAR2(4);
    --Registro con los datos base del contrato
    vrDatosBase            cuDatosBase%ROWTYPE;
    --Descripcion del periodo
    vsDescPerio            VARCHAR2(200);
    --DescripciÃ³n del programa
    vsDescProg            VARCHAR2(30);
    --Nombre Completo del apoderado
    vsNomCApo            VARCHAR2(91);
    --Monto Total del contrato
    vnMonto                NUMBER(16,2) := 0;
    --Numero de renglones, ojo este es importante para los saltos de linea
    vnNumReng            PLS_INTEGER;
    --Contadores comunes y corrientes
    vni                    PLS_INTEGER;
    vnj                    PLS_INTEGER;
    vnk                    PLS_INTEGER:=0;
     vsNivelCFC          VARCHAR2(10);
BEGIN

    --Obtengo los datos del contrato
    OPEN cuDatosBase(psCntr);
    FETCH cuDatosBase INTO vrDatosBase;
    CLOSE cuDatosBase;

   OPEN cuNivelCFC(psCntr);
    FETCH cuNivelCFC INTO vsNivelCFC;
    CLOSE cuNivelCFC;

    --Si la fecha de emision es igual o mayor que la del 2013 ejecutamos el
    --contrato 2013
    IF vsNivelCFC = 'DI' THEN
       p_ContratoDiplomado(psCntr);
   ELSE
        --Sino ejecutamos el contrato clasico
     -- p_ContratoIndividual(psCntr);


    --Obtengo el nombre completo del apoderado
    vsNomCApo := pk_MatApoderado.f_Nombre(vrDatosBase.RutApo)||' '
        ||pk_MatApoderado.f_Apellido(vrDatosBase.RutApo);

    --Obtengo la descripcion del periodo
    vsDescPerio := CASE vrDatosBase.TipoPerio
        WHEN 'A' THEN 'los periodos académicos I y II semestre'
        WHEN '1' THEN 'el primer semestre del periodo académico'
        WHEN '2' THEN 'el segundo semestre del periodo académico'
        ELSE 'el '
            ||pk_util.f_ObtieneParam('TTERM', SUBSTR(vrDatosBase.Perio,5,2))
    END;

    --Obtengo el aÃ±o del periodo
    OPEN cuAnioPeriodo(vrDatosBase.Perio);
    FETCH cuAnioPeriodo INTO vsYear;
    CLOSE cuAnioPeriodo;

    --Abro mi cursor para obtener los documentos
    OPEN cuDocs(psCntr);
    FETCH cuDocs BULK COLLECT INTO vtDocs;
    CLOSE cuDocs;

    --Obtengo el monto del contrato
    FOR vni in 1..vtDocs.COUNT LOOP
        vnMonto := vnMonto + vtDocs(vni).Monto;
        vnk:= vnk +1;
    END LOOP;
        --Comienzo la impresion de mi poderoso HTML
    HTP.P(
'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
    <head>
        <title> Contrato </title>
        <style type="text/css">
            body{
                font-size: 13px;
                font-family: Arial, Helvetica, sans-serif;
                margin-left:auto;
                margin-right:auto;
                margin-top:0;
                border:0;
                width: 18cm;
            }

            p.Art{
                text-align:justify;
                margin-top:0.4cm;
                margin-bottom:0.4cm;
                page-break-inside: avoid;
            }

            span.NumArt{
                font-weight:bold;
            }

            p.Titulo{
                text-align:center;
                font-weight:bold;
                margin-top:1cm;
                margin-bottom:1cm;
            }

            td.Firma{
                width:46%;
                vertical-align:bottom;
            }

            td.SubF{
                vertical-align:top;
            }

            table.Docs{
                margin-left:auto;
                margin-right:auto;
                font-size:10px;
            }

            td.DocH{
                text-align:center;
                font-weight:bold;
            }

            td.Monto{
                text-align:right;
                font-weight:bold;
            }

            div.Salto{
                page-break-before:always;
                margin:0;
                border:0;
                padding:0;
                height:0;
                width:100%;
            }
.tablapagoscfc {
    margin:0px;padding:0px;
    width:100%;
    border:1px solid #000000;

    -moz-border-radius-bottomleft:0px;
    -webkit-border-bottom-left-radius:0px;
    border-bottom-left-radius:0px;

    -moz-border-radius-bottomright:0px;
    -webkit-border-bottom-right-radius:0px;
    border-bottom-right-radius:0px;

    -moz-border-radius-topright:0px;
    -webkit-border-top-right-radius:0px;
    border-top-right-radius:0px;

    -moz-border-radius-topleft:0px;
    -webkit-border-top-left-radius:0px;
    border-top-left-radius:0px;
}.tablapagoscfc table{
    border-collapse: collapse;
        border-spacing: 0;
    width:100%;
    height:100%;
    margin:0px;padding:0px;
}.tablapagoscfc tr:last-child td:last-child {
    -moz-border-radius-bottomright:0px;
    -webkit-border-bottom-right-radius:0px;
    border-bottom-right-radius:0px;
}
.tablapagoscfc table tr:first-child td:first-child {
    -moz-border-radius-topleft:0px;
    -webkit-border-top-left-radius:0px;
    border-top-left-radius:0px;
}
.tablapagoscfc table tr:first-child td:last-child {
    -moz-border-radius-topright:0px;
    -webkit-border-top-right-radius:0px;
    border-top-right-radius:0px;
}.tablapagoscfc tr:last-child td:first-child{
    -moz-border-radius-bottomleft:0px;
    -webkit-border-bottom-left-radius:0px;
    border-bottom-left-radius:0px;
}.tablapagoscfc tr:hover td{
    background-color:#ffffff;


}
.tablapagoscfc td{
    vertical-align:middle;

    background-color:#ffffff;

    border:1px solid #000000;
    border-width:0px 1px 1px 0px;
    text-align:center;
    padding:7px;
    font-size:10px;
    font-family:Arial;
    font-weight:normal;
    color:#000000;
}.tablapagoscfc tr:last-child td{
    border-width:0px 1px 0px 0px;
}.tablapagoscfc tr td:last-child{
    border-width:0px 0px 1px 0px;
}.tablapagoscfc tr:last-child td:last-child{
    border-width:0px 0px 0px 0px;
}
.tablapagoscfc tr:first-child td{
        background:-o-linear-gradient(bottom, #ffffff 5%, #ffffff 100%);    background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #ffffff), color-stop(1, #ffffff) );
    background:-moz-linear-gradient( center top, #ffffff 5%, #ffffff 100% );
    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr="#ffffff", endColorstr="#ffffff");    background: -o-linear-gradient(top,#ffffff,ffffff);

    background-color:#ffffff;
    border:0px solid #000000;
    text-align:center;
    border-width:0px 0px 1px 1px;
    font-size:12px;
    font-family:Arial;
    font-weight:bold;
    color:#000000;
}
.tablapagoscfc tr:first-child:hover td{
    background:-o-linear-gradient(bottom, #ffffff 5%, #ffffff 100%);    background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #ffffff), color-stop(1, #ffffff) );
    background:-moz-linear-gradient( center top, #ffffff 5%, #ffffff 100% );
    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr="#ffffff", endColorstr="#ffffff");    background: -o-linear-gradient(top,#ffffff,ffffff);

    background-color:#ffffff;
}
.tablapagoscfc tr:first-child td:first-child{
    border-width:0px 0px 1px 0px;
}
.tablapagoscfc tr:first-child td:last-child{
    border-width:0px 0px 1px 1px;
}

        </style>
    </head>
    <body>
        <table style="width:100%">
            <tr>
                <td style="text-align:left;">
                <!--    <img src="/wtlgifs/logo_uft.jpg" style="width:4cm;"/> -->
                </td>
                <td style="text-align:right;font-weight:bold;">
                    Rut: '||vrDatosBase.RutAlu||'/ Contrato '||psCntr||'<br/>
                    ID: '||vrDatosBase.IdAlu||'
                </td>
            </tr>
        </table>
        <p class="Titulo">CONTRATO DE SERVICIOS EDUCACIONALES</p>
        <p class="Art">
            En Santiago, a '||TO_CHAR(vrDatosBase.FEmi
            ,'DD" de "MONTH" de "YYYY')||' entre la Universidad Finis Terrae,
            con domicilio en esta ciudad, Av. Pedro de Valdivia N; 1509,
            Providencia, RUT N; 70.884.700-3, en lo sucesivo la
            Universidad, por una parte, y por otra, don(a) '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu ||',
            RUT: '||vrDatosBase.RutAlu||', domiciliado(a) en '
             ||
            REPLACE(pk_matricula.f_DirAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' ')

         ||' , ' ||
       SUBSTR(REPLACE(pk_matricula.f_RegAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' '),4,30)
        ||' , '||

         SUBSTR(REPLACE(pk_matricula.f_ComuAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' '),7,30)

         ||', en adelante el
            contratante, se ha convenido el siguiente contrato de
            prestación de servicios educacionales:
        </p>

        <p class="Art">
            <span class="NumArt">PRIMERO:</span> La Universidad, a solicitud del
            contratante, acepta e inscribe a don(a), '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu ||',
            quien se ha inscrito , mediante pago o documentación del arancel
            correspondiente, como alumno regular para el periodo académico '
            ||vrDatosBase.PeriodoCFC||' en<b> '||vrDatosBase.Nivel ||' de ' || pk_Catalogo.Programa(vrDatosBase.Prog)||'.
       </b>
        </p>


        <p class="Art">
            <span class="NumArt">SEGUNDO:</span>En virtud del presente contrato, la Universidad se obliga
             a mantener el cupo asignado al alumno regular del programa en los servicios docentes que prestar;
             durante el período académico, sin perjuicio de lo dispuesto en la cláusula séptima de este contrato.
        </p>



        <p class="Art">
            <span class="NumArt">TERCERO:</span> Los cursos que la Universidad impartirá durante el período académico señalado
            en la cláusula anterior serán los que correspondan al currículo de la carrera, según sea que él se desarrolle en forma
            semestral o anual. En ningún caso disminuirá el valor del arancel si el alumno no toma o no puede tomar, por cualquier causa, el total de los
             cursos contemplados en el currículo respectivos. Lo mismo será válido si por cualquier causa justificada, no se impartiere un determinado
              curso del currículo correspondiente a un periodo académico determinado. La coordinación de los cursos estará entregada al
              Centro de Formación Continua de la Universidad Finis Terrae y su administración a las distintas Facultades y/o Escuelas.
        </p>
         <p class="Art">


            <span class="NumArt"> CUARTO:</span> El valor total del arancel será de $' ||TO_CHAR(vnMonto,ConstglFormato)||', que se pagará en
            cuotas mensuales
            ('||vnk||'). con vencimientos los días 30 de cada mes,
             A contar de '|| f_get_mes(TO_CHAR(vtDocs(1).FechaVen,'MM'))||' '|| TO_CHAR(vtDocs(1).FechaVen,'YYYY')||'
            . En caso que el contratante opte por pagar en este acto, al contado, la totalidad del arancel, su valor será de  $'||TO_CHAR(vnMonto,ConstglFormato)||'.<p>
         <p class="Art">
            <span class="NumArt">
QUINTO: </span>Para facilitar el cumplimiento de la obligación de pago a que se obliga
en virtud de la cláusula anterior, el contratante, acepta en este acto, la siguiente
documentación, con vencimiento en las fechas que se señalan y por los montos
que se indican:
<div class="tablapagoscfc">
        <table>
            <tr>
                <td>Medio de<br/>Pago</td>
                <td> Número de<br/>Documento </td>
                <td>Banco</td>
                <td>Vencimiento</td>
                <td>Concepto</td>
                <td>Monto</td>
            </tr>
'
    );

    --Inicializo los renglones
    vnNumReng := 0;

    --Comienzo a recorrer los renglones
    FOR vni IN 1..vtDocs.COUNT LOOP

        --Obtengo las categorias de detalle
        OPEN cuCats(vtDocs(vni).NumSeqDoc);
        FETCH cuCats BULK COLLECT INTO vtCats;
        CLOSE cuCats;

        --Comienzo a recorrer las categorias del documento
        FOR vnj IN 1..vtCats.COUNT LOOP

            IF vnj = 1 THEN
                --Si es el primer registro del documento imprimimos todos los
                --datos
                HTP.P(
'            <tr>
                <td>'||vtDocs(vni).DescMP||'</td>
                <td>'||vtDocs(vni).NumDocu||'</td>
                <td>'||vtDocs(vni).Banco||'</td>
                <td>'||TO_CHAR(vtDocs(vni).FechaVen,'DD/MM/YYYY')||'</td>
                <td>'|| vtCats(vnj).Categoria ||'</td>
                <td>$'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato) ||'</td>
            </tr>
'
                );
            ELSE
                --Si no solo la categoria y el monto
                HTP.P(
'            <tr>
                 <td>'||vtDocs(vni).DescMP||'</td>
                <td>'||vtDocs(vni).NumDocu||'</td>
                <td>'||vtDocs(vni).Banco||'</td>
                <td>'||TO_CHAR(vtDocs(vni).FechaVen,'DD/MM/YYYY')||'</td>
                <td>'|| vtCats(vnj).Categoria ||'</td>
                <td>$'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato) ||'</td>
            </tr>
'
                );
            END IF;

            --sumo un renglon a mi contador de renglones
            vnNumReng := vnNumReng + 1;
        END LOOP;
--
    END LOOP;

    --Cierro mi tabla de documentos
    HTP.P(
'        </table></div>'
    );

    --Aqui se van insertando los saltos de pagina como se vayan requiriendo
 /*
 IF vnNumReng BETWEEN 38 AND 40 THEN
      HTP.P(
'        <div class="Salto"><div/>'
       );
 END IF;

*/
    HTP.P(
'        <p class="Art">
           La Universidad NO está obligada a notificar en cada oportunidad las fechas de
pago y se reserva el derecho de efectuar la cobranza en forma directa o a
través de una entidad bancaria o financiera.
        </p>'
    );

/*
 IF vnNumReng BETWEEN 34 AND 47 THEN
        HTP.P(
'        <div class="Salto"><div/>'
      );
 END IF;
*/

    HTP.P(
'        <p class="Art">
            <span class="NumArt">SEXTO:</span>  La mora o el simple retardo en el pago de una o más cuotas facultará
a la Universidad para exigir el pago de toda la deuda y sus intereses, como si
fuera de plazo vencido. Si la Universidad no ejerciere este derecho en caso
alguno significará que renuncia al mismo.
        </p>'
    );

/*
IF vnNumReng BETWEEN 27 AND 33 THEN
HTP.P(
'        <div class="Salto"><div/>'
       );
   END IF;
*/

    HTP.P(
'        <p class="Art">
            En este caso, durante el periodo de mora de cualquiera de las cuotas, la
Universidad estará facultada para cobrar el interés máximo convencional para
operaciones no reajustables, calculando desde la fecha de vencimiento original
hasta la de pago efectivo.
</p>
<p class="Art">
Mientras persista la mora o el simple retardo en el pago de una o más cuotas
del valor de la colegiatura, el alumno no podrá presentarse a inscribir cursos
para el período académico siguiente, recibir su certificado o grado académico u
obtener certificaciones. Lo mismo ocurrirá mientras el alumno no haya devuelto
bienes o materiales entregados en préstamo.
        </p>'
    );
/*
    IF vnNumReng BETWEEN 23 AND 26 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;

  */
    HTP.P(
'        <p class="Art">
            <span class="NumArt">SÉPTIMO:</span> :<b> El contratante estará obligado a pagar oportunamente el total
de la suma acordada por el periodo completo convenido, salvo
expresamente en los siguientes casos:
<p>
En caso de que un participante (cliente) de un curso abierto, se retire,
este deber; enviar e-mail o carta formal informando su decisión.
</p>
<p>
Si el aviso se realiza 10 o más dias de anticipación en que ha decidido
cancelar la realización de un curso, se reembolsará el valor total del curso
menos un 20% por concepto de gastos de administración.
</p>
<p>
Si el aviso se realiza con menos de 10 días de anticipación y hasta 5 días
antes de la fecha de inicio del programa sólo se reembolsará el 50% del
valor total del curso.</p>
<p>
Los retiros con posterioridad a este plazo no tendrán derecho a reintegro,
aún cuando el alumno no hiciere uso del servicio educacional contratado,
por cualquier causa, tales como retiro, suspensión o anulación de
periodos académicos, no procediendo devolución, imputación ni
compensación alguna, toda vez que la Universidad ha adquirido
compromisos académicos y económicos para la presentación de los
servicios contratados. Esta obligación persistirá en el caso que el alumno
sea eliminado como consecuencia de su rendimiento académico o
expulsión de la Universidad por haber incurrido en falta grave de acuerdo
con el Reglamento de Alumno.</b><p>

La misma obligación existirá en caso de impedimento temporal de la
Universidad para prestar servicio educacional por evento o fuerza mayor, ya
sea naturales o provocados por terceras personas.

        </p>'
    );

/*
    IF vnNumReng BETWEEN 19 AND 22 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
*/
    HTP.P(
'        <p class="Art">
            <span class="NumArt">OCTAVO:</span>Para todos los efectos legales derivados del presente contrato, las
partes fijan domicilio en la ciudad de Santiago y se someten a la jurisdicción de
los Tribunales Ordinarios de Justicia.</p>'

    );


    HTP.P('
        <p class="Art">
            <span class="NumArt">NOVENO:</span> El contratante declara haber leído y conocer el texto y alcance del
presente contrato y lo acepta en su totalidad.
        </p>


        <span class="NumArt">DÉCIMO </span>El presente contrato se firma en dos ejemplares del mismo tenor y efecto,
        quedando uno en poder de cada parte.

        </p>');


    --Cierro mi tabla de documentos
    HTP.P(
'        </table>'
    );
       htp.p(' <table style="width:100%;text-align:center;page-break-inside: avoid;">
            <tr>
                <td class="Firma">
                   <!-- <img src="http://uft.lcred.net/imagenes/f_sfte.png" -->');
                   htp.p('<img src="data:image/jpg;base64,');
                   htp.p('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDABALDA4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9PDkzODdASFxOQERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/wgALCACAAJcBAREA/8QAGgABAAMBAQEAAAAAAAAAAAAAAAMEBQECBv/aAAgBAQAAAAH6AAAAAAAAjp2ZwACDC0NPoADmJt1LHPapy8jkc684t+7QvZ9De7majN0gyodqny98jrbDNu58ugFGLSzNL1n2Z4I6tmz7Qc9+KktiY80qnmW7aOKdzO9X+uY/nO3ZLYco38uSXxznFa7dAzdH5/ck6VqHdcBHj2NQjr07F32AZcvXZZ829KAAAAc6AAP/xAApEAACAgECBAYCAwAAAAAAAAACAwEEABITEBEUICEjMDEyM0BQBSIk/9oACAEBAAEFAv1pmIDDmNwd38BrRSAg64ZAaPwYjrX+2WfFOrPEs5xzmYiCazAsc2cNY6+3l43GyY1A26+PEibli2KcqnNm3y4Wvv4M8b3aw3hNpcKpx7WLEIxB705dnVb/AI0eSeEeZdMxWAAdia/92doeZYu/HK8bzoiBjG1AYaV7SsczaWgNpIx1RvKcEYAeDWQoEGRrYWhaB0qu/G2elCg218ZnlHU88BsWbNmwJnDXc1BMdvtln4Zb9z8y12MsKNhWDsQ8DiFApCgGTLusfbj5/wBSJiB6gM3HFmiwWdIE50a9TC28sDCqy1zPoXPAM++zCwjte2ErTq5V16negYwYFYlCKKdtfEjEM3SLFBNhjJ3JGIEfRbXl1jZYOcrOabE5slOAlYcAS4VgArH9Z//EADMQAAECAgYIBAYDAAAAAAAAAAEAAgMhEBESIjFBEyAjMkJRYXEzUnKBBDBAUJGhgrHB/9oACAEBAAY/');
                   htp.p('AvttpxqC2UO75nK/Z9voLTlbddYMEHiK905g/Qlx8JmHWgjmQFKZ6KcuiqrmqytnBLu5qWjiMLH/AN02K72NWtWnsZut3j/iYPeiGA6WJFBHGtKRuin4fnaphdGmvWIu35MAQhjM0CVonIIxcsBQ4eyceZpLsoYq90XOMgtJFJazhaCokXnIdtZz8m3QofrFD45w3WqoCoUW8HVIMGVBd+FexxcrbvCbujmtG3ed+gg0YCm0VW9lk8k53IJozUP1hEDF0k1oy1KytnDe/qm2roZMNOZWirujGrPog4t0cIcOZRe/ed+tZrfM4CiEOb00ZMnqkPdcbw+Yos+HYRzcUG1jZjhyQcBVLFaR/wDFvLXg+qiEPKC4oxHkAuKu2ndgrkGr1FXoob6QtoXP7lVisA5BCDAAtH9LRNm959yg6Jlg3l8hj/K6h/W6Oyk0atrPJGxeiO3nnAIxSbVUgTn8ktOBTob/ABBJvVWnbx1LzgFs2E9TIIxIt5rZNC0MPDjPJADAfKBf4YEgtnGPZ01vQ/wpxGDs1X4zz2kqw2fOjRW2hvmGKstEvtv/xAAoEAEAAgAEBQMFAQAAAAAAAAABABEhMUFRECBhcYGhscEwQJHh8FD/2gAIAQEAAT8h/wA1EMtWY9VuaHxKsz7E+wavgZG8udYzYnghpTQfYi/YKBa0EtRjUN0AABQQ/wAsMQWYLSKqbGaghbIuXooiso3lxgLEFs7HjoTB4OanXqs4yGHgasbqJbzwp83wO2twAyKmF9gENGIaRWG39jKLacDYGt+MOIw2sXM1l9UHX8TFFpt3YKBtAjfJ50roTX8KozKE/neuJ6VndKw0OgJk8sFjk/G5jZ4/tYbLeWUzh+hhgQaHBLduGG+8BtdM9+AL5mTd0lFfFjO8auxMXXuxgbb7jCJoKOLn');
                   htp.p('H2DV2gaaCzuS3Mxb3eGE2jfMDRSuQEQAzWOhuwo9YefwAdJj0u317IQPhTNsk70Lo25EHMyigVaDVjsH9D8cLo9CDZ2/fTkUC2ADvoGP6IFcywFEs54iD3watgqxWBRqv2O/OvyvbgazKQvkixdI6Reux9Yq/SaU9vmZYtfxStauJRAJrLrTvMXBR7jFqtjpfv8AQuTpL2yg2WSsLqs2Gcyl+JllyKFjkG7KWBiPwSG2DqZq/Ry12mXZg2aHeKJfCch194ZpcmM4LwFF6st8MYDo27wU6Cg+k/ZlhxWaVmxFWt5T5ik94D4RSn1MWJYm8LAPcuQzSHr/AJv/2gAIAQEAAAAQAAAAAAAEAACgAAxghDiBZHAQnFcZg+DgwfgMhgCCwB8QAAABAAD/xAAoEAEAAQMDBAIBBQEAAAAAAAABEQAhMUFRYXGBkaEQILEwQMHR8FD/2gAIAQEAAT8Q/wCbkBUkVYGmHcgF0o+B/wAwv7CMfYDL2KDkxlB1MvLQBTbkAxs30/YMzAlVgCjVnTXm6fxFGWBABAFbwAdzRwHJiX3Y70OdDuIV6p/FIyQuXPQpEM8rXYSQPQbvgqPM0OBwZ+byNnLLKJN/tErpjJEZxjXNKJDb7YA+3pRQsd+3f0dvjJn4tc7F9Q2o2CHBUBpsyJOaD0bLkTa3lUikUxOnwGvkJoLv4+YCbkmzIHmftPTEOyTk7FzylSLobZZlXvQE4AFIJc7AZaNDdjJC6+X18QkX0YrALLCGQR/fzrdPtG4+C3iiQGld+DmjWUFLdFMtNMslMand/H2P8zfl+YK2mA0oFWAy1AS4i4DlOv8AdYKgBAfBsQkAhQgjVJ9VDIxMIllY6/F6gI1HsPNWkk1quuz0x2oSotZEHq2KR/XJ3Dtao5xBwfIeMLZzYHWl6OpJmTfjp');
                   htp.p('WIFobwYpr4ke9xfLULv+pppIU9Z9TQ5QH3a/QMLSiAKZsZ3H0cqGJEqXOyyWaXK7SP4Y3aKHUgLKANNNu9WgrSNNAdPooIKpJMUZYUqQBvSPowjFpoCCCrVsqeBqeycX1f4/RAgBdVxT2EFVhqxo03ay/BAG04fdaebXCxnNWaiO4CUhac32KVAcjRu5evvAE6neXwnZ0qNPx7pQ6rIgMBU1NhTHRYPdDEgcEh1F61FNy0AwVo7LoWqUmuOd8xxNGGawW1XzV/6zVZn0R3qVMYC5R75foRzk4SrvyUAJIkjSFTQwPI/jzULaCBDQAgAbH0I8Tq/BRdx6tbN4xBapms9Ih2NDj9Ee5TxTrQVWObmwXgzTEAZhzk8ufH0JkXFhehrRarMeWvd8UrMppI0NTS8z2pnQbAm15Y4KGOYDQP0nxr4JGZ2vrwUDgDgZO9n3WEc9L+aMINZF7aCwHqAfSfdf441u3q9kQSadF6ApCuGw3zeiaXnK1V1ef8Am//Z"/>');

                        htp.p('<br/>
                    <hr/>
                </td>
                <td>;</td>
                <td class="Firma"><hr/></td>
            </tr>
            <tr>
                <td class="SubF">
                    UNIVERSIDAD FINIS TERRAE<br/>
            <br/>

                </td>
                <td></td>
                <td class="SubF">
                    CONTRATANTE<br/>
                    '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu||'<br/>
                    '||vrDatosBase.RutAlu||'
                </td>
            </tr>
        </table>
    </body>
</html>'
    );
   END IF;

END p_Contrato_firma_ebustos_2014;

PROCEDURE p_ContratoDiplomado(psCntr VARCHAR2) IS
  --Tipos y tablas para los cursores
    TYPE t_TblDocs IS TABLE OF cuDocs%ROWTYPE;
    vtDocs                t_TblDocs;
    TYPE t_TblCats IS TABLE OF cuCats%ROWTYPE;
    vtCats                t_TblCats;

    --AÃ±o del periodo
    vsYear                VARCHAR2(4);
    --Registro con los datos base del contrato
    vrDatosBase            cuDatosBase%ROWTYPE;
    --Descripcion del periodo
    vsDescPerio            VARCHAR2(200);
    --DescripciÃ³n del programa
    vsDescProg            VARCHAR2(30);
    --Nombre Completo del apoderado
    vsNomCApo            VARCHAR2(91);
    --Monto Total del contrato
    vnMonto                NUMBER(16,2) := 0;
    --Numero de renglones, ojo este es importante para los saltos de linea
    vnNumReng            PLS_INTEGER;
    --Contadores comunes y corrientes
    vni                    PLS_INTEGER;
    vnj                    PLS_INTEGER;
    vnk                    PLS_INTEGER:=0;
    vsNivelCFC          VARCHAR2(10);
    --vdFEmi  DATE;
       CURSOR cuFechaEmi(psCntr VARCHAR2) IS
        SELECT
            TWBCNTR_ISSUE_DATE            AS Fecha
        FROM
            TWBCNTR
        WHERE
            TWBCNTR_NUM = psCntr;
     vdF2013                DATE := TO_DATE('01/01/2013','DD/MM/YYYY');
    vdF2014_ebustos        DATE := TO_DATE('01/01/2014','DD/MM/YYYY');
    --Fecha de emision del contrato
    vdFEmi                DATE;
BEGIN

    --Obtengo los datos del contrato
    OPEN cuDatosBase(psCntr);
    FETCH cuDatosBase INTO vrDatosBase;
    CLOSE cuDatosBase;
/*
   OPEN cuNivelCFC(psCntr);
    FETCH cuNivelCFC INTO vsNivelCFC;
    CLOSE cuNivelCFC;*/

    --Si la fecha de emision es igual o mayor que la del 2013 ejecutamos el
    --contrato 2013
   -- IF vsNivelCFC = 'DI' THEN
    --    p_ContratoDiplomado(psCntr);
   -- ELSE
        --Sino ejecutamos el contrato clasico
     -- p_ContratoIndividual(psCntr);
    --END IF;


    --Obtengo el nombre completo del apoderado
    vsNomCApo := pk_MatApoderado.f_Nombre(vrDatosBase.RutApo)||' '
        ||pk_MatApoderado.f_Apellido(vrDatosBase.RutApo);

    --Obtengo la descripcion del periodo
    vsDescPerio := CASE vrDatosBase.TipoPerio
        WHEN 'A' THEN 'los periodos académicos I y II semestre'
        WHEN '1' THEN 'el primer semestre del periodo académico'
        WHEN '2' THEN 'el segundo semestre del periodo académico'
        ELSE 'el '
            ||pk_util.f_ObtieneParam('TTERM', SUBSTR(vrDatosBase.Perio,5,2))
    END;

    --Obtengo el aÃ±o del periodo
    OPEN cuAnioPeriodo(vrDatosBase.Perio);
    FETCH cuAnioPeriodo INTO vsYear;
    CLOSE cuAnioPeriodo;

    --Abro mi cursor para obtener los documentos
    OPEN cuDocs(psCntr);
    FETCH cuDocs BULK COLLECT INTO vtDocs;
    CLOSE cuDocs;

    --Obtengo el monto del contrato
    FOR vni in 1..vtDocs.COUNT LOOP
        vnMonto := vnMonto + vtDocs(vni).Monto;
        vnk:= vnk +1;
    END LOOP;
        --Comienzo la impresion de mi poderoso HTML
    HTP.P(
'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
    <head>
        <title> Contrato </title>
        <style type="text/css">
            body{
                font-size: 13px;
                font-family: Arial, Helvetica, sans-serif;
                margin-left:auto;
                margin-right:auto;
                margin-top:0;
                border:0;
                width: 18cm;
            }

            p.Art{
                text-align:justify;
                margin-top:0.4cm;
                margin-bottom:0.4cm;
                page-break-inside: avoid;
            }

            span.NumArt{
                font-weight:bold;
            }

            p.Titulo{
                text-align:center;
                font-weight:bold;
                margin-top:1cm;
                margin-bottom:1cm;
            }

            td.Firma{
                width:46%;
                vertical-align:bottom;
            }

            td.SubF{
                vertical-align:top;
            }

            table.Docs{
                margin-left:auto;
                margin-right:auto;
                font-size:10px;
            }

            td.DocH{
                text-align:center;
                font-weight:bold;
            }

            td.Monto{
                text-align:right;
                font-weight:bold;
            }

            div.Salto{
                page-break-before:always;
                margin:0;
                border:0;
                padding:0;
                height:0;
                width:100%;
            }
.tablapagoscfc {
    margin:0px;padding:0px;
    width:100%;
    border:1px solid #000000;

    -moz-border-radius-bottomleft:0px;
    -webkit-border-bottom-left-radius:0px;
    border-bottom-left-radius:0px;

    -moz-border-radius-bottomright:0px;
    -webkit-border-bottom-right-radius:0px;
    border-bottom-right-radius:0px;

    -moz-border-radius-topright:0px;
    -webkit-border-top-right-radius:0px;
    border-top-right-radius:0px;

    -moz-border-radius-topleft:0px;
    -webkit-border-top-left-radius:0px;
    border-top-left-radius:0px;
}.tablapagoscfc table{
    border-collapse: collapse;
        border-spacing: 0;
    width:100%;
    height:100%;
    margin:0px;padding:0px;
}.tablapagoscfc tr:last-child td:last-child {
    -moz-border-radius-bottomright:0px;
    -webkit-border-bottom-right-radius:0px;
    border-bottom-right-radius:0px;
}
.tablapagoscfc table tr:first-child td:first-child {
    -moz-border-radius-topleft:0px;
    -webkit-border-top-left-radius:0px;
    border-top-left-radius:0px;
}
.tablapagoscfc table tr:first-child td:last-child {
    -moz-border-radius-topright:0px;
    -webkit-border-top-right-radius:0px;
    border-top-right-radius:0px;
}.tablapagoscfc tr:last-child td:first-child{
    -moz-border-radius-bottomleft:0px;
    -webkit-border-bottom-left-radius:0px;
    border-bottom-left-radius:0px;
}.tablapagoscfc tr:hover td{
    background-color:#ffffff;


}
.tablapagoscfc td{
    vertical-align:middle;

    background-color:#ffffff;

    border:1px solid #000000;
    border-width:0px 1px 1px 0px;
    text-align:center;
    padding:7px;
    font-size:10px;
    font-family:Arial;
    font-weight:normal;
    color:#000000;
}.tablapagoscfc tr:last-child td{
    border-width:0px 1px 0px 0px;
}.tablapagoscfc tr td:last-child{
    border-width:0px 0px 1px 0px;
}.tablapagoscfc tr:last-child td:last-child{
    border-width:0px 0px 0px 0px;
}
.tablapagoscfc tr:first-child td{
        background:-o-linear-gradient(bottom, #ffffff 5%, #ffffff 100%);    background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #ffffff), color-stop(1, #ffffff) );
    background:-moz-linear-gradient( center top, #ffffff 5%, #ffffff 100% );
    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr="#ffffff", endColorstr="#ffffff");    background: -o-linear-gradient(top,#ffffff,ffffff);

    background-color:#ffffff;
    border:0px solid #000000;
    text-align:center;
    border-width:0px 0px 1px 1px;
    font-size:12px;
    font-family:Arial;
    font-weight:bold;
    color:#000000;
}
.tablapagoscfc tr:first-child:hover td{
    background:-o-linear-gradient(bottom, #ffffff 5%, #ffffff 100%);    background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #ffffff), color-stop(1, #ffffff) );
    background:-moz-linear-gradient( center top, #ffffff 5%, #ffffff 100% );
    filter:progid:DXImageTransform.Microsoft.gradient(startColorstr="#ffffff", endColorstr="#ffffff");    background: -o-linear-gradient(top,#ffffff,ffffff);

    background-color:#ffffff;
}
.tablapagoscfc tr:first-child td:first-child{
    border-width:0px 0px 1px 0px;
}
.tablapagoscfc tr:first-child td:last-child{
    border-width:0px 0px 1px 1px;
}

        </style>
    </head>
    <body>
        <table style="width:100%">
            <tr>
                <td style="text-align:left;">
                <!--    <img src="/wtlgifs/logo_uft.jpg" style="width:4cm;"/> -->
                </td>
                <td style="text-align:right;font-weight:bold;">
                    Rut: '||vrDatosBase.RutAlu||'/ Contrato '||psCntr||'<br/>
                    ID: '||vrDatosBase.IdAlu||'
                </td>
            </tr>
        </table>
        <p class="Titulo">CONTRATO DE SERVICIOS EDUCACIONALES</p>
        <p class="Art">
            En Santiago, a '||TO_CHAR(vrDatosBase.FEmi
            ,'DD" de "MONTH" de "YYYY')||' entre la Universidad Finis Terrae,
            con domicilio en esta ciudad, Av. Pedro de Valdivia N; 1509,
            Providencia, RUT N; 70.884.700-3, en lo sucesivo la
            Universidad, por una parte, y por otra, don(a) '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu ||',
            RUT: '||vrDatosBase.RutAlu||', domiciliado(a) en '
             ||
            REPLACE(pk_matricula.f_DirAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' ')

         ||' , ' ||
       SUBSTR(REPLACE(pk_matricula.f_RegAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' '),4,30)
        ||' , '||

         SUBSTR(REPLACE(pk_matricula.f_ComuAlumno(f_get_pidm(vrDatosBase.IdAlu)),'*',' '),7,30)

         ||', en adelante el
            contratante, se ha convenido el siguiente contrato de
            prestación de servicios educacionales:
        </p>

        <p class="Art">
            <span class="NumArt">PRIMERO:</span> La Universidad, a solicitud del
            contratante, acepta e inscribe a don(a), '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu ||',
            quien se ha inscrito , mediante pago o documentación del arancel
            correspondiente, como alumno regular para el periodo académico '
            ||vrDatosBase.PeriodoCFC||' en el DIPLOMADO :<b> ' || pk_Catalogo.Programa(vrDatosBase.Prog)||'.
       </b>
        </p>


        <p class="Art">
            <span class="NumArt">SEGUNDO:</span>En virtud del presente contrato,
            la Universidad se obligaráa mantener el cupo asignado al alumno regular del programa en
             los servicios docentes que prestará durante el período académico,
             sin perjuicio de lo dispuesto en la cláusula séptima de este contrato.
        </p>



        <p class="Art">
            <span class="NumArt">TERCERO:</span>
            Los cursos que la Universidad impartirá durante el período académico señalado en la cláusula anterior serán los que correspondan
             al currículo del programa, según sea que él se desarrolle en forma trimestral, semestral o anual. En ningún caso disminuirá el valor del arancel
             si el alumno no toma o no puede tomar, por cualquier causa, el total de los cursos contemplados en el currículo respectivo. Lo mismo será válido si por cualquier causa justificada,
              no se impartiere un determinado curso del currículo correspondiente . La coordinación de los cursos estará entregada al Centro de Formación Continua de la Universidad Finis Terrae
               y su administración a las distintas Facultades y/o Escuelas.
        </p>
         <p class="Art">
            <span class="NumArt">  CUARTO:</span> El valor total del arancel ser; de $' ||TO_CHAR(vnMonto,ConstglFormato)||', que se pagar; en
            '||vnk||' cuota(s) , por el total $' ||TO_CHAR(vnMonto,ConstglFormato)||'
            En caso que el contratante opte por pagar en este acto, al contado, la totalidad del arancel, su valor será de  $'||TO_CHAR(vnMonto,ConstglFormato)||'.<p>

         <p class="Art">
            <span class="NumArt">
QUINTO: </span>Para facilitar el cumplimiento de la obligación de pago a que se obliga
en virtud de la cláusula anterior, el contratante, acepta en este acto, la siguiente
documentación, con vencimiento en las fechas que se señalan y por los montos
que se indican:
<div class="tablapagoscfc">
        <table>
            <tr>
                <td>Medio de<br/>Pago</td>
                <td> Número de<br/>Documento </td>
                <td>Banco</td>
                <td>Vencimiento</td>
                <td>Concepto</td>
                <td>Monto</td>
            </tr>
'
    );

    --Inicializo los renglones
    vnNumReng := 0;

    --Comienzo a recorrer los renglones
    FOR vni IN 1..vtDocs.COUNT LOOP

        --Obtengo las categorias de detalle
        OPEN cuCats(vtDocs(vni).NumSeqDoc);
        FETCH cuCats BULK COLLECT INTO vtCats;
        CLOSE cuCats;

        --Comienzo a recorrer las categorias del documento
        FOR vnj IN 1..vtCats.COUNT LOOP

            IF vnj = 1 THEN
                --Si es el primer registro del documento imprimimos todos los
                --datos
                HTP.P(
'            <tr>
                <td>'||vtDocs(vni).DescMP||'</td>
                <td>'||vtDocs(vni).NumDocu||'</td>
                <td>'||vtDocs(vni).Banco||'</td>
                <td>'||TO_CHAR(vtDocs(vni).FechaVen,'DD/MM/YYYY')||'</td>
                <td>'|| vtCats(vnj).Categoria ||'</td>
                <td>$'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato) ||'</td>
            </tr>
'
                );
            ELSE
                --Si no solo la categoria y el monto
                HTP.P(
'            <tr>
                 <td>'||vtDocs(vni).DescMP||'</td>
                <td>'||vtDocs(vni).NumDocu||'</td>
                <td>'||vtDocs(vni).Banco||'</td>
                <td>'||TO_CHAR(vtDocs(vni).FechaVen,'DD/MM/YYYY')||'</td>
                <td>'|| vtCats(vnj).Categoria ||'</td>
                <td>$'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato) ||'</td>
            </tr>
'
                );
            END IF;

            --sumo un renglon a mi contador de renglones
            vnNumReng := vnNumReng + 1;
        END LOOP;
--
    END LOOP;

    --Cierro mi tabla de documentos
    HTP.P(
'        </table></div>'
    );

    --Aqui se van insertando los saltos de pagina como se vayan requiriendo
 /*
 IF vnNumReng BETWEEN 38 AND 40 THEN
      HTP.P(
'        <div class="Salto"><div/>'
       );
 END IF;

*/
    HTP.P(
'        <p class="Art">
           La Universidad NO está obligada a notificar en cada oportunidad las fechas de
pago y se reserva el derecho de efectuar la cobranza en forma directa o a
través de una entidad bancaria o financiera.
        </p>'
    );

/*
 IF vnNumReng BETWEEN 34 AND 47 THEN
        HTP.P(
'        <div class="Salto"><div/>'
      );
 END IF;
*/

    HTP.P(
'        <p class="Art">
            <span class="NumArt">SEXTO:</span>  La mora o el simple retardo en el pago de una o más cuotas facultará
a la Universidad para exigir el pago de toda la deuda y sus intereses, como si
fuera de plazo vencido. Si la Universidad no ejerciere este derecho en caso
alguno significará que renuncia al mismo.
        </p>'
    );

/*
IF vnNumReng BETWEEN 27 AND 33 THEN
HTP.P(
'        <div class="Salto"><div/>'
       );
   END IF;
*/

    HTP.P(
'        <p class="Art">
            En este caso, durante el periodo de mora de cualquiera de las cuotas, la
Universidad estará facultada para cobrar el interés máximo convencional para
operaciones no reajustables, calculando desde la fecha de vencimiento original
hasta la de pago efectivo.
</p>
<p class="Art">
Mientras persista la mora o el simple retardo en el pago de una o más cuotas
del valor de la colegiatura, el alumno no podrá presentarse a inscribir cursos
para el período académico siguiente, recibir su certificado o grado académico u
obtener certificaciones. Lo mismo ocurrirá mientras el alumno no haya devuelto
bienes o materiales entregados en préstamo.
        </p>'
    );
/*
    IF vnNumReng BETWEEN 23 AND 26 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;

  */
    HTP.P(
'        <p class="Art">
            <span class="NumArt">SÉPTIMO:</span> :<b> El contratante estará obligado a pagar oportunamente el total
de la suma acordada por el periodo completo convenido, salvo
expresamente en los siguientes casos:
<p>
En caso de que un participante (cliente) de un curso abierto, se retire,
este deberá enviar e-mail o carta formal informando su decisión.
</p>
<p>
Si el aviso se realiza 10 o más dias de anticipación en que ha decidido
cancelar la realización de un curso, se reembolsará el valor total del curso
menos un 20% por concepto de gastos de administración.
</p>
<p>
Si el aviso se realiza con menos de 10 días de anticipación y hasta 5 días
antes de la fecha de inicio del programa sólo se reembolsará el 50% del
valor total del curso.</p>
<p>
Los retiros con posterioridad a este plazo no tendrán derecho a reintegro,
aún cuando el alumno no hiciere uso del servicio educacional contratado,
por cualquier causa, tales como retiro, suspensión o anulación de
periodos académicos, no procediendo devolución, imputación ni
compensación alguna, toda vez que la Universidad ha adquirido
compromisos académicos y económicos para la presentación de los
servicios contratados. Esta obligación persistirá en el caso que el alumno
sea eliminado como consecuencia de su rendimiento académico o
expulsión de la Universidad por haber incurrido en falta grave de acuerdo
con el Reglamento de Alumno.</b><p>

La misma obligación existir; en caso de impedimento temporal de la
Universidad para prestar servicio educacional por evento o fuerza mayor, ya
sea naturales o provocados por terceras personas.

        </p>'
    );

/*
    IF vnNumReng BETWEEN 19 AND 22 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
*/
    HTP.P(
'        <p class="Art">
            <span class="NumArt">OCTAVO:</span>Para todos los efectos legales derivados del presente contrato, las
partes fijan domicilio en la ciudad de Santiago y se someten a la jurisdicción de
los Tribunales Ordinarios de Justicia.</p>'

    );


    HTP.P('
        <p class="Art">
            <span class="NumArt">NOVENO:</span> El contratante declara haber leído y conocer el texto y alcance del
presente contrato y lo acepta en su totalidad.
        </p>


        <span class="NumArt">DÉCIMO </span>El presente contrato se firma en dos ejemplares del mismo tenor y efecto,
        quedando uno en poder de cada parte.

        </p>');


    --Cierro mi tabla de documentos
    HTP.P(
'        </table>'
    );
       htp.p(' <table style="width:100%;text-align:center;page-break-inside: avoid;">
            <tr>
                <td class="Firma">');

    OPEN cuFechaEmi(psCntr);
    FETCH cuFechaEmi INTO vdFEmi;
    CLOSE cuFechaEmi;

    --Si la fecha de emision es igual o mayor que la del 2013 ejecutamos el
    --contrato 2013
    --htp.p(vdFEmi);
   --htp.p(vdF2014_ebustos);
    IF  TRUNC(vdFEmi) < trunc(vdF2014_ebustos) THEN
    --htp.p(vdFEmi);
    --htp.p(vdF2014_ebustos);
        HTP.P('<img src="http://uft.lcred.net/imagenes/f_sfte.png" style="width:4cm;">');
    ELSE


htp.p('<img src="data:image/jpg;base64,');
htp.p('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDABALDA4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9PDkzODdASFxOQERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/wgALCACAAJcBAREA/8QAGgABAAMBAQEAAAAAAAAAAAAAAAEEBQMCBv/aAAgBAQAAAAH6AAARIAAABwqaNbxCPGkAcq1S7Z9mLOxIDGjV6kcMnZrXgRm+O0TM++PnSo3wipWy7/TVlGd6u17SSnSnneuyVHLpbqWOjjzqd7fur4u+czRp+rwZ3LUz9JgV/p87v6z+2kGbpRmacfO69uney2l6RLn0Z/S358+XTH2pAAecuj9B0AARX4XvQAAAAAAB/8QAKRAAAgIBAgQGAgMAAAAAAAAAAgMBBAARExASFCAFISMkMDM0UCIxMv/aAAgBAQABBQL9Y1kLgmuDgT1jO8c5zWJzWzm+QZWeTz+FhwsFjpnMVl+zzYIwMcb7ZyV9IP8AfwmzcsugiJYQsOw2gAojctsjmXTmZr973FKwLp64QNYIuK5uqgs5rBZtNnIrrxoxJ1POcqfX3TMum2xYoU1gh0sniELk+xM85UvxynQa4+37WzJEQN0qV4iRTD2xXjtss20AG3Wo/i2frywo2wAwA8Gs21qHbCPdMslPKIwA5YdsgmyDjyZiML17Z/4o/ix6lntZPPZnmtzEQML9W3w8SPSfDR9fHK6g0JhIPnRC2bVJIOWXbV828KH05rrjFTbtIrgjJnTKpEQ54gfLXqqnNfPtgBguE15gxUXDSIz+RYeggjySRQAr93Y+eY1gXGlcQ28YBAD85b2dOTMiIiP1v//EADUQAAECAwUFBQYHAAAAAAAAAAEAAgMREhAhMUFREyAiYXEjMkJSgTBAUGKCsQQzQ3KRobL/2gAIAQEABj8C+GX45DVML2tpcZSzslVM6C9cMF3rcvy2D6l3IZ9V2sJzRqL08y7MYeyLn');
htp.p('YBbaNKr/KDoY4GZnVdo8u5YBSaANwQWYnFNiMw8Y19lS0VUYDmhDnVFd/DQg1uA3SahcpnwiZ6pw1CbPEXewfs7mtxcmBonEeqoruN2JUnTb1XZse/oFcxrOpXHGP0iSvm7qUyE0XYlRX6usP7jv0i5gxOqdCBvNwaEYgaJ92Z+y2n4mIZ/ZVtZJg7vPnuxYvoEOpRKaDnvbJv1HQI1v2UFuTVtS2XlCdFYaBPhIz5qcR7onXDdcc8AqeSaqPOZWANiUaoNbgLS5Tf3je4qr9FuHzIQ2959yDRgLKpTvlJOa3Ef3ZeZIN8MK89UeiYvlh/feDfDDFRVIBbBzPmUhgnvyZwi2GPVE6CymZAbpqqRfqU88lDl33d0IN4aMzmTvRznXK12tRnbEkZBty4cZX2Oc5spmfWyXmuQiv0k0aBS3i4C842l8GJsycRKYXaxC/lgLLgs2pzswEzoi5xkAtoR2bMOfuBCodBfNueSv4YYQa0SA9w4aPVdu+Y8owUgJD4d/8QAKRABAAIBAgUDBAMBAAAAAAAAAQARMSFBEFFhgbEgcaEwQJHRUMHw4f/aAAgBAQABPyH+MHtlaDlRUaGtaX14fLAXxNx+tI2Xu7SrwGR1m6NJAuDS51+k/X9ktKBml4HKIpOPAxfV0t4JRi8g9CDIap4mrFNHmQQCNj9F/iedb7RQTEfXoFDLFhoLq5Tan5JBZwhALevt9BAdB/SQqd1gZV5xIRS+c8ie4SJqfOTQmz73vEPisIA2U6zC4ltM2nb/ANiOJo/3a+tCrhPwIGCrIsSpxPb7CBCmGoNECygq2r6bfEXskNM7p8zpcXKibpaPXXgI4b9ApaXWBpuxMiTNpybHN6x3h9Qbw5FBs/D01Bl+RldvNfvPJ8xWBkP3g');
htp.p('AAYIhYXhuQeKCjiTG2Dmy9bcEuSKXRzfqYmrXobsMmgo4BnaBbMSKub4cKWqzRcVLrIKl6p5XmK9NQru9VxXgfPaOqNkKej2hk6GgR8m+9vx6Q3F3Buui93zJZxS2mVnQpyiGxrqMpbu90epXf6BwcSqm7hAYa1KPwgf93mqWuBc4A1Zg583fBf31cIo0gVACtx09QODO58XccyDtFfhhAAKCiFtAvVomg4bzpbDlidXMFPphQMhZ7bRd32HWwqEFAqmXW5qfa2x/1mxyB9hyr6pikezcGhBgP47//aAAgBAQAAABAAAIAAAA/4AcEAILA37gqmIVh2OJwEJ8F6AQaCAAIAAYAAAAAAAP/EACkQAQABAwIGAgIDAQEAAAAAAAERACExQVFhcYGRobEQIDDwUMHRQOH/2gAIAQEAAT8Q/jJe1hZ2gVOV2ZpnQ9vi0HbXsSpwTmyh5Z8VnEbN6FZjwnsChoQyQ+LFw6U/FRk5ieXaT8S5gMGVoHFprTOONmnXdpxPo9GmYywYPN6k5dM3gZ6tHzHRB9G7U24nHVl/9p3hMrINpoi0ZYEiYT8L9Ycavd6HtWUb1DjEOWrUMwI4rqvF+gEgHFpx9SEq8KkfN7XS6EHSjPFBPKlCleoIeI++CWpEwt1O68dKgrXimlVsT4qcaI3dIMwbVKrbbiHLJ1oVHKz3MFW0kMszpQG2Fl8ou0A3r8TjxVn5gRbpRLFKjkW91cozFGXoqfcx4IZCvRu0dXFSBkggx1qbJiAEAAbzSBM0QO0/5S1LQVDlTpt1frrCF7S/2mhk2jiqlXX7ChCQ5FmbcdfgGQGJH6JeDB/SXSpIIogTYl3f0pZOHVu8bvFQt6hGPQbcqUjkkDsWetABAQH00pMG9ipgCXzwv5pT+7KpLWzGYcuw0TYBAGhQODhX2p01qwd4+bmbZvFg704rnzXnsFqKmkGtHqmz91orV3D9gPdF+GDgfANoYoSePelgKQIWGu');
htp.p('4+C0AEiJXBzota50Xg6f7RLYE8V+xxUePHdHN2Pf2GQHwFnQgza8camoeWuCDjiohJQGAqQ7i2ZXX9ck+XHjJvrg/ugzGfmp8EcYXI4HoHmnS3ZpatX/izeMNJzeiJnkZoiqScqold/B9pBzJByYPb8JEhLGKUjlLcNv6j4YRgsU3qfIwkklo9qzlSjZGsaXpwgMWN6igkGQG1jJEGfgAYFBrBd9eanb0UUZjdzQnmEW6L4vhx9o06wbMTx+VBTMRG8sNDzwRdYLvejQgsBpQswsBL0zTCCKwSDeGQPPKoCyDNYNCJFsfKhAFOAFFn5ba24++3/BeWJpbSVbvP5GY0AjegLmb1D5NKLoKA/OzFs0gwZs/gH3TUTZh7+rQNBgEAcv47/9k="/>');

    END IF;
                   htp.p('<br/>
                    <hr/>
                </td>
                <td></td>
                                <p style="font-size: 9px;">La factura correspondiente se emitirá en forma electrónica y se enviará al correo y/o domicilio del suscriptor dentro de las 48 horas siguientes al cierre del contrato.</p>

                <td class="Firma"><hr/></td>
            </tr>
            <tr>
                <td class="SubF">
                    UNIVERSIDAD FINIS TERRAE<br/>
            <br/>

                </td>
                <td></td>
                <td class="SubF">
                    CONTRATANTE<br/>
                    '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu||'<br/>
                    '||vrDatosBase.RutAlu||'
                </td>
            </tr>
        </table>
    </body>
</html>'
    );
END p_ContratoDiplomado;

FUNCTION f_get_mes(psMes VARCHAR2) RETURN VARCHAR2 IS
BEGIN
CASE psMes
  WHEN '01' THEN return 'ENERO';
  WHEN '02' THEN return 'FEBRERO';
  WHEN '03' THEN return 'MARZO';
  WHEN '04' THEN return 'ABRIL';
  WHEN '05' THEN return 'MAYO';
  WHEN '06' THEN return 'JUNIO';
  WHEN '07' THEN return 'JULIO';
  WHEN '08' THEN return 'AGOSTO';
  WHEN '08' THEN return 'SEPTIEMBRE';
  WHEN '10' THEN return 'OCTUBRE';
  WHEN '11' THEN return 'NOVIEMBRE';
  WHEN '12' THEN return 'DICIEMBRE';

   ELSE return 'null';
END CASE;
END f_get_mes;
END pk_ContratoCFC;
/


CREATE OR REPLACE PACKAGE BODY BANINST1.pk_Contrato IS
/******************************************************************************
PAQUETE:            BANINST1.pk_Contrato
OBJETIVO:            Contiene los procedimientos, funciones y variables
                    requeridos para la impresion de la documentaciÃ³n del
                    proceso de matricula, asÃ­ como cÃ³digo auxiliar para el
                    funcionamiento de las pantallas TWAPAYM/TWAMACE
AUTORES:            Eduardo Armando Moreno Macal
                    Gilberto Velazquez Hernandez
FECHA (REFACT):        20130102

Modificacion 1 md-01
Objetivo: Redacción de articulos 1 y 6 en  p_Contrato2013
Autor: Virgilio De la Cruz Jardón
Fecha: 20130923


******************************************************************************/

--Prototipos de funciones privadas, ver cuerpo de la funciÃ³n para mayor detalle
PROCEDURE p_Contrato2013(psCntr VARCHAR2);
PROCEDURE p_Contrato_firma_ebustos_2014(psCntr VARCHAR2);
PROCEDURE p_Contrato2011(psCntr VARCHAR2);
--Fin de prototipos de funciones privadas

    --Cursor para obtener los datos base de un contrato
    CURSOR cuDatosBase(psCntr VARCHAR2) IS
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
        FROM
            TWBCNTR
            ,SPRIDEN
            ,SPBPERS
        WHERE
            SPBPERS_PIDM = SPRIDEN_PIDM
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

/******************************************************************************
PROCEDIMIENTO:        p_SelContratos
OBJETIVO:            Procedimiento de seleccion para el bloque de datos
                    principal en la pantalla TWAPAYM
PARAMETROS:
psPidm:                Pidm del Alumno
psTerm:                Periodo de Matricula
rcContrato:            Parametro de Salida. Cursor con los datos para el bloque
******************************************************************************/
PROCEDURE p_SelContratos(
    psPidm        IN        NUMBER        DEFAULT NULL,
    psTerm        IN        VARCHAR2    DEFAULT NULL,
    rcContrato    IN OUT    rc_contrato
) IS BEGIN
    OPEN rcContrato FOR
    SELECT TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_BALANCE, --PK_MATRICULA.f_obtmontotransindoc(TBRACCD_PIDM, TBRACCD_TRAN_NUMBER), --TBRACCD_BALANCE,
           TBRACCD_EFFECTIVE_DATE, TBRACCD_DESC, TWBDOCU_SEQ_NUM, TWBDOCU_PAYM_CODE, TWBDOCU_DOCU_NUM,
           TWRDOTR_PART_AMOUNT, TWBDOCU_EXPIRATION_DATE, TWBDOCU_STATUS_IND, TWBDOCU_CNTR_NUM,
           TWBDOCU_BANK_CODE, TWBDOCU_CTYP_CODE, TWBDOCU_PLCE_CODE, TWBDOCU_CURR_ACNT, TBBDETC_DCAT_CODE, TWVPAYM_USER_EDITABLE_IND
    FROM   TBRACCD,
           TWRDOTR,
           TWBDOCU,
           TBBDETC,
           TWVPAYM
     WHERE TWRDOTR_PIDM = TBRACCD_PIDM
       AND TWRDOTR_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
       AND TWBDOCU_SEQ_NUM = TWRDOTR_DOCU_SEQ_NUM
       AND TWVPAYM_CODE = TWBDOCU_PAYM_CODE
       AND TWVPAYM_USER_VIEWABLE_IND = 'Y'
       AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
       AND TBBDETC_TYPE_IND = 'C'
       AND TWBDOCU_STATUS_IND = 'AC'
--         AND TWBDOCU_STATUS_IND NOT IN ('CA', 'PA', 'RP', 'RV')
       AND TBRACCD_PIDM = psPidm
       AND TBRACCD_TERM_CODE = psTerm
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
       AND PK_MATRICULA.F_OBTMONTOTRANSINDOC(A.TBRACCD_PIDM, A.TBRACCD_TRAN_NUMBER) > 0
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
                    'TWAPAYM');
        END IF;
        -- INSERTA INFORMACION DEL DOCUMENTO Y SUS RELACIONES CON LOS CARGOS CORRESPONDIENTE
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
         -- INSERTA LA RELACION ENTRE CARGOS Y DOCUMENTOS
         pk_matricula.p_insTranDocu(
                TContratos(vlContrato).pidm,
                TContratos(vlContrato).tran,
                TContratos(vlContrato).seqnum,
                TContratos(vlContrato).dmonto,
                NULL,
                NULL,
                'O' );
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        err_num := SQLCODE;  err_msg := SQLERRM;
        RAISE_APPLICATION_ERROR(TO_CHAR(err_num), err_msg);
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
    vdF2014_E_BUSTOS       DATE := TO_DATE('01/09/2014','DD/MM/YYYY');
    --Fecha de emision del contrato
    vdFEmi                DATE;

BEGIN
    --Obtengo la fecha de emision para el contrato indicado
    OPEN cuFechaEmi(psCntr);
    FETCH cuFechaEmi INTO vdFEmi;
    CLOSE cuFechaEmi;

    --Si la fecha de emision es igual o mayor que la del 2013 ejecutamos el
    --contrato 2013
    IF TRUNC(vdFEmi) >= vdF2014_E_BUSTOS THEN
      p_Contrato_firma_ebustos_2014(psCntr);
     ELSIF TRUNC(vdFEmi) >= vdF2013 AND TRUNC(vdFEmi) < vdF2014_E_BUSTOS THEN
        p_Contrato2013(psCntr);          
    ELSE 
        --Sino ejecutamos el contrato clasico
        p_Contrato2011(psCntr);
    END IF;

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

    --Contador comun y corriente
    vni                    PLS_INTEGER;

BEGIN
      /* Check/update the user's web session */
--   IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;


    OPEN cuDatosBase(psCntr);
    FETCH cuDatosbase INTO vrDatosBase;
    CLOSE cuDatosBase;

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
    htp.p('<tr class="Estilo7"><td colspan="6">DEPARTAMENTO DE MATRICULAS</td>
                               <td colspan="14">HORA: ' || TO_CHAR(vFechaCntr, 'HH24:MI') || '</td></tr>');

    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');



    htp.p('<tr class="Estilo4"><td colspan="3">ALUMNO:</td>
                               <td colspan="18">' || valumno || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">ID:</td>
                               <td colspan="18">' || vrol || ' (' || vARut || ')</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">APODERADO:</td>
                               <td colspan="18">' || upper( vnombre) || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">R.U.T:</td>
                               <td colspan="18">' || vrut || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">CONTRATO:</td>
                               <td colspan="18">' || vcont || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">CARRERA:</td>
                               <td colspan="18">' || vcarrera || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">PERIODO:</td>
                               <td colspan="18">' || vsTexto || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">ADMISION:</td>
                               <td colspan="18">' || vsAdmision || '</td></tr>');

    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');

    htp.p('<tr class="Estilo4"><td colspan="20">COMPROBANTE DE INGRESOS</td></tr>');

    htp.p('<tr class="Estilo11"><td colspan="20">&nbsp</td></tr>');

    htp.p('<tr><td colspan="1" class="Estilo11">&nbsp;</td>
                <td colspan="3" class="Estilo11">Medio de Pago</td>
                <td colspan="2" class="Estilo11">N&uacute;mero de Documento</td>
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
            HTP.P('<td colspan="2" class="Estilo12">'|| TO_CHAR(vtCats(vni).Monto, ConstglFormato)||'</td>');
            HTP.P('<td colspan="2" class="Estilo11">&nbsp;</td>');
            vacumulado := vacumulado + vtCats(vni).Monto ;
            HTP.P('</tr>');
        END LOOP;

        vncuenta := vncuenta + 1;
    END LOOP;

        htp.p('<tr><td colspan="1" class="Estilo11">&nbsp</td>
                <td colspan="1" class="Estilo11">&nbsp</td>
                <td colspan="3" class="Estilo11">TOTALES</td>
                <td colspan="3" class="Estilo11">&nbsp</td>
                <td colspan="2" class="Estilo11">&nbsp</td>
                <td colspan="4" class="Estilo11">&nbsp</td>
                <td colspan="2" class="Estilo11">&nbsp</td>
                <td colspan="2" class="Estilo12">'|| CASE vacumulado WHEN '0' THEN '&nbsp' ELSE TO_CHAR(vacumulado, ConstglFormato) END ||'</td></tr>');
        HTP.P('<td colspan="2" class="Estilo11">&nbsp;</td>');
    htp.p('<tr class="Estilo3"><td colspan="20">' || LPAD('-', 150, '-') || '</td></tr>');
    htp.p('<tr class="Estilo3"><td colspan="20">Total Arancel &nbsp&nbsp$&nbsp&nbsp  ' || TO_CHAR(vacumulado, '999g999g999') || ' </td></tr>');
    htp.p('<tr class="Estilo3"><td colspan="20">' || LPAD('-', 150, '-') || '</td></tr>');

    htp.p('<tr class="Estilo4"><td colspan="20">OBSERVACIONES:</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="20">' || vlObsev || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="20">&nbsp</td></tr>');

    htp.p('<tr class="Estilo3"><td colspan="20">____________________________________ </td></tr>');
    htp.p('<tr class="Estilo3"><td colspan="20">RECIBIDO: ' || vsUser || ' </td></tr>');

    HTP.TABLECLOSE;
        htp.p('<p style="font-size: 9px;">La factura correspondiente se emitirá en forma electrónica y se enviará al correo y/o domicilio del suscriptor dentro de las 48 horas siguientes al cierre del contrato.</p>');

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

    -- BUSCA LA INFOMACION DEL LA PRIMERA PARTE
    vnombre := pk_MatApoderado.f_Apellido(vrDatosBase.RutApo) || ', '
        ||pk_MatApoderado.f_Nombre(vrDatosBase.RutApo);
    valumno := vrDatosBase.ApeAlu || ', ' ||vrDatosBase.NomAlu;
    vrut := vrDatosBase.RutApo;
    vrol := vrDatosBase.IdAlu;
    vcont := psCntr;
    vcarrera := pk_Catalogo.Programa(vrDatosBase.Prog);
    vFechaCntr := vrDatosBase.FEmi;
-- vterm := pk_Catalogo.Periodo(vrDatosBase.Perio);
    vArut := vrDatosBase.RutAlu;
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
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               </tr>');
    --
    -- PAGINA PRIMERA
    --
    htp.p('<tr class="Estilo1"><td colspan="4" >' || to_char(vFechaCntr, 'DD' ) || '</td>
                               <td colspan="7" >' || to_char(vFechaCntr, 'MONTH' ) || '</td>
                               <td colspan="9" >' || to_char(vFechaCntr, 'RRRR' ) ||  '</td>
                               </tr>');

    htp.p('<tr class="Estilo1"><td colspan="13">
                               ' || upper(vlApeApoD) || ' ' || upper(vlNomApod) || '</td>
                               <td colspan="4" >' || vlRUTApod || '</td>
                               <td colspan="3" >PARTICULAR</td></tr>');

    htp.p('<tr class="Estilo1"><td colspan="16">
                               ' || pk_MatApoderado.f_Direccion(vlRUTApod, vsTerm) || '</td>
                               <td colspan="4" >' ||  pk_MatApoderado.f_Ciudad(vlRUTApod, vsTerm)
                               || ', ' || pk_MatApoderado.f_Comuna(vlRUTApod, vsTerm) || '</td></tr>');

    HTP.P('<tr class="Estilo1"><td colspan="20" style="line-height: 1.5cm">&nbsp</td></tr>');


    --
    -- INICIAL LA IMPRESION DE LA INFORMACION
    --
    htp.p('<tr class="Estilo4"><td colspan="3">APODERADO:</td>
                               <td colspan="18">' || UPPER( vnombre )  || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">R.U.T:</td>
                               <td colspan="18">' || vrut || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">CONTRATO:</td>
                               <td colspan="18">' || vcont || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">ALUMNO:</td>
                               <td colspan="18">' || valumno || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">ROL:</td>
                               <td colspan="18">' || vrol || ' (' || varut || ')</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">CARRERA:</td>
                               <td colspan="18">' || vcarrera || '</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="3">PERIODO:</td>
                               <td colspan="18">' || vvTextContrato || ')</td></tr>');
--   htp.p('<tr class="Estilo4"><td colspan="3">PERIODO:</td>
--                                 <td colspan="18">I y II Semestre </td></tr>');

    htp.p('<tr class="Estilo4"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo4"><td colspan="8">&nbsp</td>
                               <td colspan="12">TOTAL: $  ' || TO_CHAR( vlMonto, ConstglFormato )  || ',--</td></tr>');
--   HTP.P('<tr class="Estilo1"><td colspan="20" style="line-height: 0.5cm">&nbsp</td></tr>');
    HTP.TABLECLOSE;
        htp.p('<p style="font-size: 9px;">La factura correspondiente se emitirá en forma electrónica y se enviará al correo y/o domicilio del suscriptor dentro de las 48 horas siguientes al cierre del contrato.</p>');

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
            TWBCNTR_RUT                AS RutApo
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
    IF vrDatosCntr.RutApo IS NULL OR vrDatosCntr.Fecha IS NULL THEN
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
    pk_MatPagare.p_Pagare(psCntr ,vrDatosCntr.RutApo
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

    --ultimo paso! invoco la cuponera
    pk_MatCupon.p_Cuponera(vsCupones);

END p_Cuponera;

/******************************************************************************
PROCEDIMIENTO:        p_Contrato2013
OBJETIVO:            Imprime al buffer HTP el contrato legal version 2013
                    indicado
PARAMETROS:
psCntr:                Numero del contrato
Modificado: vdelacruz 20130729

******************************************************************************/
PROCEDURE p_Contrato2013(psCntr VARCHAR2) IS

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

BEGIN

    --Obtengo los datos del contrato
    OPEN cuDatosBase(psCntr);
    FETCH cuDatosBase INTO vrDatosBase;
    CLOSE cuDatosBase;

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

        </style>
    </head>
    <body>
        <table style="width:100%">
            <tr>
                <td style="text-align:left;">
                    <img src="/wtlgifs/logo_uft.jpg" style="width:4cm;"/>
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
            con domicilio en esta ciudad, Av. Pedro de Valdivia N&ordm; 1509,
            Providencia, RUT N&ordm; 70.884.700-3, en lo sucesivo la
            Universidad, por una parte, y por otra, don(a) '||vsNomCApo||',
            RUT: '||vrDatosBase.RutApo||', domiciliado(a) en '
            ||pk_MatApoderado.f_Direccion(vrDatosBase.RutApo, vrDatosBase.Perio)
            ||' Comuna '|| pk_MatApoderado.f_Comuna(vrDatosBase.RutApo,
            vrDatosBase.Perio) ||' Ciudad '|| pk_MatApoderado.f_Ciudad(
            vrDatosBase.RutApo, vrDatosBase.Perio ) ||', en adelante el
            contratante, se ha convenido el siguiente contrato de
            prestaci&oacute;n de servicios educacionales:
        </p>


        <p class="Art">
            <span class="NumArt">PRIMERO:</span> La Universidad, a solicitud del
            contratante, acepta e inscribe a don(a), '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu ||' RUT: '|| vrDatosBase.RutAlu ||',
            quien se ha matriculado, previo pago o documentaci&oacute;n de la
            matr&iacute;cula correspondiente, como alumno regular para '
            ||vsDescPerio||' del a&ntilde;o '||vsYear||' en la carrera de '
            ||pk_Catalogo.Programa(vrDatosBase.Prog)||'.
        </p>


        <p class="Art">
            <span class="NumArt">SEGUNDO:</span> El valor total de la
            colegiatura de la carrera de ' ||pk_Catalogo.Programa(vrDatosBase.Prog)||' , incluida la matr&iacute;cula ser&aacute; de $'
            ||TO_CHAR(vnMonto,ConstglFormato)||'-, que se pagar&aacute; en
            cuotas mensuales o al contado, con vencimientos los d&iacute;as
            indicados de cada mes, a contar del mes especificado en clausula tercera.
        </p>



        <p class="Art">
            <span class="NumArt">TERCERO:</span> Para facilitar el cumplimiento
            de la obligaci&oacute;n de pago a que se obliga en virtud de la
            cl&aacute;usula anterior, as&iacute; como tambi&eacute;n el pago de
            la matr&iacute;cula, y sin que signifique novaci&oacute;n, el contratante acepta en este acto, la
            siguiente documentaci&oacute;n, con vencimiento en las fechas que
            se se&ntilde;alan y por los montos que se indican:
        </p>

        <table class="Docs">
            <tr>
                <td class="DocH" style="width:3cm;">Medio de<br/>Pago</td>
                <td class="DocH" style="width:3cm;">
                    N&uacute;mero de<br/>Documento
                </td>
                <td class="DocH" style="width:2cm;">Banco</td>
                <td class="DocH" style="width:2cm;">Vencimiento</td>
                <td class="DocH" style="width:3cm;">Concepto</td>
                <td class="DocH" style="width:2.5cm;">Monto<td>
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
                <td class="Monto">'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato)
                ||'<td>
            </tr>
'
                );
            ELSE
                --Si no solo la categoria y el monto
                HTP.P(
'            <tr>
                <td colspan="4">&nbsp;</td>
                <td>'|| vtCats(vnj).Categoria ||'</td>
                <td class="Monto">'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato)
                    ||'<td>
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
'        </table>'
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
            Por la suscripci&oacute;n del presente contrato se entender&aacute;n
            notificadas las fechas de pago y la Universidad se reserva el
            derecho de efectuar la cobranza en forma directa o a trav&eacute;s
            de una entidad bancaria o financiera, vencidos los plazos
            establecidos en la Ley
            19.496.
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
            <span class="NumArt">CUARTO:</span> En virtud del presente contrato,
            la Universidad se obliga a mantener el cupo asignado al alumno
            regular en los servicios docentes que prestar&aacute; durante el
            a&ntilde;o acad&eacute;mico, sin perjuicio de lo dispuesto en la
            cl&aacute;usula s&eacute;ptima de este contrato.En virtud de lo anterior,
            el contratante declara conocer y aceptar que la no utilizaci&oacute;n del
            cupo asignado como alumno regular de los servicios docentes no le faculta
            para eximirse del cumplimiento de las obligaciones que asume en virtud del
            presente contrato, toda vez que terminado el per&iacute;odo de retracto
            establecido en la Ley 19.496 sobre protecci&oacute;n de los derechos de
            los consumidores la Universidad no podr&aacute; asignar el cupo asignado
            al contratante a otro alumno.
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
            <span class="NumArt">QUINTO:</span> Los cursos que la Universidad
            impartir&aacute; durante el a&ntilde;o acad&eacute;mico
            se&ntilde;alado en la cl&aacute;usula primera ser&aacute;n los que
            correspondan al curr&iacute;culo de la carrera, seg&uacute;n sea que
            &eacute;l se desarrolle en forma semestral o anual. En ning&uacute;n
            caso disminuir&aacute; el valor de la colegiatura si el alumno no
            toma o no puede tomar, por cualquier causa que no sea responsabilidad
            de la Universidad, el total de los cursos contemplados en el curr&iacute;culo
            respectivo.
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
            <span class="NumArt">SEXTO:</span> La mora o el simple retardo en el pago de
            una o m&aacute;s cuotas facultar&aacute;n a la Universidad para exigir el pago
            de toda la deuda del per&iacute;odo contratado completo y sus intereses, como si fuera
            de plazo vencido. Si la Universidad no ejerciere este derecho en caso alguno significar&aacute;
            que renuncia al mismo.

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

            En este caso, durante el per&iacute;odo de mora de cualquiera de las cuotas, la Universidad estar&aacute;
            facultada para cobrar el inter&eacute;s m&aacute;ximo convencional para operaciones no reajustables,
            calculado desde la fecha de vencimiento original hasta la de pago efectivo.
        </p>'
    );
/*
    IF vnNumReng BETWEEN 10 AND 18 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
    */
HTP.P(
'        <p class="Art">
            El contratante autoriza irrevocablemente a la Universidad para que en caso de  mora, simple retardo
            o incumplimiento de una o m&aacute;s de las obligaciones contra&iacute;das por el presente contrato,
            sus datos personales y dem&aacute;s derivados del presente contrato puedan ser ingresados, registrados,
            procesados, tratados y comunicados por la Instituci&oacute;n o por terceros que dispongan de bases de datos
            o sistemas de informaci&oacute;n comercial, financiero, econ&oacute;mico, bancario o relativo a morosidades
            como, por v&iacute;a ejemplar, el bolet&iacute;n comercial o su equivalente, en los t&eacute;rminos m&aacute;s
            amplios que permita la Ley N&ordm;19.628, sobre protecci&oacute;n de
            la vida privada, y sus modificaciones.
        </p>'
    );
    /*
    IF vnNumReng BETWEEN 10 AND 18 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
    */
    HTP.P(
'        <p class="Art">
            Mientras persista la mora o el simple retardo en el pago de una o m&aacute;s cuotas del valor de la
            colegiatura, el alumno no podr&aacute; presentarse a ex&aacute;menes, inscribir cursos para el
            per&iacute;odo acad&eacute;mico siguiente, recibir su t&iacute;tulo profesional o
            grado acad&eacute;mico u obtener certificaciones. Lo mismo ocurrir&aacute; mientras el alumno
            no haya devuelto oportunamente bienes o materiales entregados que hubiere recibido en
            comodato por parte de la Universidad.
        </p>'
    );
    /*
    IF vnNumReng BETWEEN 10 AND 18 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
*/
    HTP.P(
'        <p class="Art">
            El contratante, para los efectos contemplados en el art&iacute;culo 19 de la ley N&ordm;19.628, se
            compromete a realizar personalmente todas las gestiones que digan relaci&oacute;n con documentos protestados
            por no pago, los que presentar&aacute; en o los boletines, registros y/o bancos de datos liberando desde ya a
            la Universidad de dicha responsabilidad. No obstante lo anterior, la Universidad otorgar&aacute; colaboraci&oacute;n
            razonable entregando los certificados que correspondan al contratante, de manera que &eacute;ste pueda realizar
            las referidas gestiones.
        </p>'
    );

/*
  IF vnNumReng BETWEEN 10 AND 18 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
  */
    HTP.P(
'        <p class="Art" style="font-weight:bold;">
            <span class="NumArt">S&Eacute;PTIMO:</span> El contratante estar&aacute; obligado a pagar oportunamente
            el total de la suma acordada por el periodo completo convenido, a&uacute;n cuando el alumno no
            hiciere uso del servicio educacional contratado, por cualquier causa, tales como retiro,
            suspensi&oacute;n o anulaci&oacute;n de periodos acad&eacute;micos no procediendo devoluci&oacute;n,
            imputaci&oacute;n ni compensaci&oacute;n alguna, toda vez que la universidad ha adquirido compromisos
            acad&eacute;micos y econ&oacute;micos para la prestaci&oacute;n de los servicios contratados.
            Esta obligaci&oacute;n persistir&aacute; en el caso que el alumno fuera sancionado reglamentariamente
            con la suspensi&oacute;n o expulsi&oacute;n de la Universidad por haber incurrido en falta grave de
            acuerdo con el Reglamento del Alumno, correspondiendo en este caso dicho pago a una cl&aacute;usula
            penal a t&iacute;tulo de multa por el incumplimiento de contrato y los reglamentos y dem&aacute;s
            normas de la Universidad, de acuerdo a lo dispuesto en los art&iacute;culos 1.535
            y siguientes del C&oacute;digo Civil.
        </p>'
    );

/*

    IF vnNumReng BETWEEN 4 AND 9 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;

*/


    HTP.P(
'        <p class="Art">
            En caso de que el alumno se desvincule de la Universidad, estar&aacute; obligado a pagar
            completo el a&ntilde;o que est&eacute; cursando al momento del retiro, habida consideraci&oacute;n
            a lo dispuesto en el art&iacute;culo cuarto anterior. Sin perjuicio de lo anterior, ser&aacute;n aplicables
            las normas de la ley N&ordm;19.496 referidas al derecho de retracto, cuando corresponda.
        </p>'
    );

/*
    IF vnNumReng BETWEEN 0 AND 3 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;

  */
    HTP.P(
'        <p class="Art">
            La misma obligaci&oacute;n existir&aacute; en caso de impedimento temporal de la Universidad
            para prestar el servicio educacional por eventos de fuerza mayor, ya sean naturales o provocados
            por terceras personas, debiendo en este caso reanudarse con la prestaci&oacute;n del servicio
            una vez terminado los eventos de fuerza mayor y sin costo para el contratante. El alumno se obliga
            tambi&eacute;n a pagar el respectivo derecho o arancel de licenciamiento o titulaci&oacute;n que
            anualmente fija la Universidad para cada una de sus carreras, en el momento en que de inicio
            a su proceso de licenciamiento o titulaci&oacute;n.</p>'
    );

    /*
    IF vnNumReng BETWEEN 0 AND 3 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
*/
    HTP.P(
'        <p class="Art">
            <span class="NumArt">OCTAVO:</span>Las partes dejan expresa constancia que ser&aacute; responsabilidad del alumno el
            resguardo de los efectos personales que introduzca o mantenga en los recintos universitarios.</p>'

    );


    HTP.P('
        <p class="Art">
            <span class="NumArt">NOVENO:</span> El contratante y el alumno declaran estar en conocimiento y
            aceptar los reglamentos y dem&aacute;s normas internas vigentes en la Universidad, las que en versi&oacute;n
            oficial est&aacute;n disponibles en la p&aacute;gina Web de la Universidad: www.uft.cl
        </p>


        <p class="Art">
            <span class="NumArt">D&Eacute;CIMO:</span> Las becas promocionales y asistenciales propias de la Universidad se regir&aacute;n por el
            reglamento respectivo. Si el alumno es de aquellos que han sido preseleccionados con Cr&eacute;dito con Aval del Estado y/o
            con alg&uacute;n tipo de beca otorgada por el Ministerio de Educaci&oacute;n, declara en este acto que est&aacute;
            totalmente informado acerca de ambos procesos y que conoce la eventual posibilidad de que en definitiva no se le asignen
            los beneficios antes se&ntilde;alados por no cumplir &eacute;l o la carrera con los requisitos exigidos por la Ley N&ordm;20.027,
            por el Ministerio de Educaci&oacute;n o por la Universidad, eximiendo desde ya a &eacute;sta &uacute;ltima de todo perjuicio
            que esto le ocasionare, y autorizando a &eacute;sta para realizar ajustes a los montos de arancel se&ntilde;alados en la
            cl&aacute;usula Tercera de este Contrato, para el caso que el Alumno no fuera favorecido con alguno de los beneficios.
        </p>

        <p class="Art">
            <span class="NumArt">D&Eacute;CIMO PRIMERO:</span> Para todos los efectos legales derivados del presente contrato,
            las partes fijan domicilio en la ciudad de Santiago y se someten a la jurisdicci&oacute;n
            de los Tribunales Ordinarios de Justicia.
        </p>

        <p class="Art">
        <span class="NumArt">D&Eacute;CIMO SEGUNDO:</span>El contratante declara haber le&iacute;do y conocer el texto
        y alcance del presente contrato y lo acepta en su totalidad.

        </p>

        <p class="Art">
        <span class="NumArt">D&Eacute;CIMO TERCERO:</span>El presente contrato se firma en dos ejemplares del mismo tenor y efecto,
        quedando uno en poder de cada parte.

        </p>

        <table style="width:100%;text-align:center;page-break-inside: avoid;">
            <tr>
                <td class="Firma">
                    <img src="http://uft.lcred.net/imagenes/f_sfte.png"
                        style="width:4cm;"/><br/>
                    <hr/>
                </td>
                <td>&nbsp;</td>
                <td class="Firma"><hr/></td>
            </tr>
            <tr>
                <td class="SubF">
                    UNIVERSIDAD FINIS TERRAE<br/>
                    Francisco Torres Espinoza<br/>
                    Director de Finanzas y Contabilidad
                </td>
                <td>&nbsp</td>
                <td class="SubF">
                    CONTRATANTE<br/>
                    '||vsNomCApo||'<br/>
                    '||vrDatosBase.RutApo||'
                </td>
            </tr>
        </table>
    </body>
</html>'
    );
END p_Contrato2013;

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

BEGIN

    --Obtengo los datos del contrato
    OPEN cuDatosBase(psCntr);
    FETCH cuDatosBase INTO vrDatosBase;
    CLOSE cuDatosBase;

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

        </style>
    </head>
    <body>
        <table style="width:100%">
            <tr>
                <td style="text-align:left;">
                    <img src="/wtlgifs/logo_uft.jpg" style="width:4cm;"/>
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
            con domicilio en esta ciudad, Av. Pedro de Valdivia N&ordm; 1509,
            Providencia, RUT N&ordm; 70.884.700-3, en lo sucesivo la
            Universidad, por una parte, y por otra, don(a) '||vsNomCApo||',
            RUT: '||vrDatosBase.RutApo||', domiciliado(a) en '
            ||pk_MatApoderado.f_Direccion(vrDatosBase.RutApo, vrDatosBase.Perio)
            ||' Comuna '|| pk_MatApoderado.f_Comuna(vrDatosBase.RutApo,
            vrDatosBase.Perio) ||' Ciudad '|| pk_MatApoderado.f_Ciudad(
            vrDatosBase.RutApo, vrDatosBase.Perio ) ||', en adelante el
            contratante, se ha convenido el siguiente contrato de
            prestaci&oacute;n de servicios educacionales:
        </p>


        <p class="Art">
            <span class="NumArt">PRIMERO:</span> La Universidad, a solicitud del
            contratante, acepta e inscribe a don(a), '|| vrDatosBase.NomAlu
            ||' '|| vrDatosBase.ApeAlu ||' RUT: '|| vrDatosBase.RutAlu ||',
            quien se ha matriculado, previo pago o documentaci&oacute;n de la
            matr&iacute;cula correspondiente, como alumno regular para '
            ||vsDescPerio||' del a&ntilde;o '||vsYear||' en la carrera de '
            ||pk_Catalogo.Programa(vrDatosBase.Prog)||'.
        </p>


        <p class="Art">
            <span class="NumArt">SEGUNDO:</span> El valor total de la
            colegiatura de la carrera de ' ||pk_Catalogo.Programa(vrDatosBase.Prog)||' , incluida la matr&iacute;cula ser&aacute; de $'
            ||TO_CHAR(vnMonto,ConstglFormato)||'-, que se pagar&aacute; en
            cuotas mensuales o al contado, con vencimientos los d&iacute;as
            indicados de cada mes, a contar del mes especificado en clausula tercera.
        </p>



        <p class="Art">
            <span class="NumArt">TERCERO:</span> Para facilitar el cumplimiento
            de la obligaci&oacute;n de pago a que se obliga en virtud de la
            cl&aacute;usula anterior, as&iacute; como tambi&eacute;n el pago de
            la matr&iacute;cula, y sin que signifique novaci&oacute;n, el contratante acepta en este acto, la
            siguiente documentaci&oacute;n, con vencimiento en las fechas que
            se se&ntilde;alan y por los montos que se indican:
        </p>

        <table class="Docs">
            <tr>
                <td class="DocH" style="width:3cm;">Medio de<br/>Pago</td>
                <td class="DocH" style="width:3cm;">
                    N&uacute;mero de<br/>Documento
                </td>
                <td class="DocH" style="width:2cm;">Banco</td>
                <td class="DocH" style="width:2cm;">Vencimiento</td>
                <td class="DocH" style="width:3cm;">Concepto</td>
                <td class="DocH" style="width:2.5cm;">Monto<td>
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
                <td class="Monto">'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato)
                ||'<td>
            </tr>
'
                );
            ELSE
                --Si no solo la categoria y el monto
                HTP.P(
'            <tr>
                <td colspan="4">&nbsp;</td>
                <td>'|| vtCats(vnj).Categoria ||'</td>
                <td class="Monto">'||TO_CHAR(vtCats(vnj).Monto,ConstglFormato)
                    ||'<td>
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
'        </table>'
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
            Por la suscripci&oacute;n del presente contrato se entender&aacute;n
            notificadas las fechas de pago y la Universidad se reserva el
            derecho de efectuar la cobranza en forma directa o a trav&eacute;s
            de una entidad bancaria o financiera, vencidos los plazos
            establecidos en la Ley
            19.496.
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
            <span class="NumArt">CUARTO:</span> En virtud del presente contrato,
            la Universidad se obliga a mantener el cupo asignado al alumno
            regular en los servicios docentes que prestar&aacute; durante el
            a&ntilde;o acad&eacute;mico, sin perjuicio de lo dispuesto en la
            cl&aacute;usula s&eacute;ptima de este contrato.En virtud de lo anterior,
            el contratante declara conocer y aceptar que la no utilizaci&oacute;n del
            cupo asignado como alumno regular de los servicios docentes no le faculta
            para eximirse del cumplimiento de las obligaciones que asume en virtud del
            presente contrato, toda vez que terminado el per&iacute;odo de retracto
            establecido en la Ley 19.496 sobre protecci&oacute;n de los derechos de
            los consumidores la Universidad no podr&aacute; asignar el cupo asignado
            al contratante a otro alumno.
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
            <span class="NumArt">QUINTO:</span> Los cursos que la Universidad
            impartir&aacute; durante el a&ntilde;o acad&eacute;mico
            se&ntilde;alado en la cl&aacute;usula primera ser&aacute;n los que
            correspondan al curr&iacute;culo de la carrera, seg&uacute;n sea que
            &eacute;l se desarrolle en forma semestral o anual. En ning&uacute;n
            caso disminuir&aacute; el valor de la colegiatura si el alumno no
            toma o no puede tomar, por cualquier causa que no sea responsabilidad
            de la Universidad, el total de los cursos contemplados en el curr&iacute;culo
            respectivo.
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
            <span class="NumArt">SEXTO:</span> La mora o el simple retardo en el pago de
            una o m&aacute;s cuotas facultar&aacute;n a la Universidad para exigir el pago
            de toda la deuda del per&iacute;odo contratado completo y sus intereses, como si fuera
            de plazo vencido. Si la Universidad no ejerciere este derecho en caso alguno significar&aacute;
            que renuncia al mismo.

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

            En este caso, durante el per&iacute;odo de mora de cualquiera de las cuotas, la Universidad estar&aacute;
            facultada para cobrar el inter&eacute;s m&aacute;ximo convencional para operaciones no reajustables,
            calculado desde la fecha de vencimiento original hasta la de pago efectivo.
        </p>'
    );
/*
    IF vnNumReng BETWEEN 10 AND 18 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
    */
HTP.P(
'        <p class="Art">
            El contratante autoriza irrevocablemente a la Universidad para que en caso de  mora, simple retardo
            o incumplimiento de una o m&aacute;s de las obligaciones contra&iacute;das por el presente contrato,
            sus datos personales y dem&aacute;s derivados del presente contrato puedan ser ingresados, registrados,
            procesados, tratados y comunicados por la Instituci&oacute;n o por terceros que dispongan de bases de datos
            o sistemas de informaci&oacute;n comercial, financiero, econ&oacute;mico, bancario o relativo a morosidades
            como, por v&iacute;a ejemplar, el bolet&iacute;n comercial o su equivalente, en los t&eacute;rminos m&aacute;s
            amplios que permita la Ley N&ordm;19.628, sobre protecci&oacute;n de
            la vida privada, y sus modificaciones.
        </p>'
    );
    /*
    IF vnNumReng BETWEEN 10 AND 18 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
    */
    HTP.P(
'        <p class="Art">
            Mientras persista la mora o el simple retardo en el pago de una o m&aacute;s cuotas del valor de la
            colegiatura, el alumno no podr&aacute; presentarse a ex&aacute;menes, inscribir cursos para el
            per&iacute;odo acad&eacute;mico siguiente, recibir su t&iacute;tulo profesional o
            grado acad&eacute;mico u obtener certificaciones. Lo mismo ocurrir&aacute; mientras el alumno
            no haya devuelto oportunamente bienes o materiales entregados que hubiere recibido en
            comodato por parte de la Universidad.
        </p>'
    );
    /*
    IF vnNumReng BETWEEN 10 AND 18 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
*/
    HTP.P(
'        <p class="Art">
            El contratante, para los efectos contemplados en el art&iacute;culo 19 de la ley N&ordm;19.628, se
            compromete a realizar personalmente todas las gestiones que digan relaci&oacute;n con documentos protestados
            por no pago, los que presentar&aacute; en o los boletines, registros y/o bancos de datos liberando desde ya a
            la Universidad de dicha responsabilidad. No obstante lo anterior, la Universidad otorgar&aacute; colaboraci&oacute;n
            razonable entregando los certificados que correspondan al contratante, de manera que &eacute;ste pueda realizar
            las referidas gestiones.
        </p>'
    );

/*
  IF vnNumReng BETWEEN 10 AND 18 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
  */
    HTP.P(
'        <p class="Art" style="font-weight:bold;">
            <span class="NumArt">S&Eacute;PTIMO:</span> El contratante estar&aacute; obligado a pagar oportunamente
            el total de la suma acordada por el periodo completo convenido, a&uacute;n cuando el alumno no
            hiciere uso del servicio educacional contratado, por cualquier causa, tales como retiro,
            suspensi&oacute;n o anulaci&oacute;n de periodos acad&eacute;micos no procediendo devoluci&oacute;n,
            imputaci&oacute;n ni compensaci&oacute;n alguna, toda vez que la universidad ha adquirido compromisos
            acad&eacute;micos y econ&oacute;micos para la prestaci&oacute;n de los servicios contratados.
            Esta obligaci&oacute;n persistir&aacute; en el caso que el alumno fuera sancionado reglamentariamente
            con la suspensi&oacute;n o expulsi&oacute;n de la Universidad por haber incurrido en falta grave de
            acuerdo con el Reglamento del Alumno, correspondiendo en este caso dicho pago a una cl&aacute;usula
            penal a t&iacute;tulo de multa por el incumplimiento de contrato y los reglamentos y dem&aacute;s
            normas de la Universidad, de acuerdo a lo dispuesto en los art&iacute;culos 1.535
            y siguientes del C&oacute;digo Civil.
        </p>'
    );

/*

    IF vnNumReng BETWEEN 4 AND 9 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;

*/


    HTP.P(
'        <p class="Art">
            En caso de que el alumno se desvincule de la Universidad, estar&aacute; obligado a pagar
            completo el a&ntilde;o que est&eacute; cursando al momento del retiro, habida consideraci&oacute;n
            a lo dispuesto en el art&iacute;culo cuarto anterior. Sin perjuicio de lo anterior, ser&aacute;n aplicables
            las normas de la ley N&ordm;19.496 referidas al derecho de retracto, cuando corresponda.
        </p>'
    );

/*
    IF vnNumReng BETWEEN 0 AND 3 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;

  */
    HTP.P(
'        <p class="Art">
            La misma obligaci&oacute;n existir&aacute; en caso de impedimento temporal de la Universidad
            para prestar el servicio educacional por eventos de fuerza mayor, ya sean naturales o provocados
            por terceras personas, debiendo en este caso reanudarse con la prestaci&oacute;n del servicio
            una vez terminado los eventos de fuerza mayor y sin costo para el contratante. El alumno se obliga
            tambi&eacute;n a pagar el respectivo derecho o arancel de licenciamiento o titulaci&oacute;n que
            anualmente fija la Universidad para cada una de sus carreras, en el momento en que de inicio
            a su proceso de licenciamiento o titulaci&oacute;n.</p>'
    );

    /*
    IF vnNumReng BETWEEN 0 AND 3 THEN
        HTP.P(
'        <div class="Salto"><div/>'
        );
    END IF;
*/
    HTP.P(
'        <p class="Art">
            <span class="NumArt">OCTAVO:</span>Las partes dejan expresa constancia que ser&aacute; responsabilidad del alumno el
            resguardo de los efectos personales que introduzca o mantenga en los recintos universitarios.</p>'

    );


    HTP.P('
        <p class="Art">
            <span class="NumArt">NOVENO:</span> El contratante y el alumno declaran estar en conocimiento y
            aceptar los reglamentos y dem&aacute;s normas internas vigentes en la Universidad, las que en versi&oacute;n
            oficial est&aacute;n disponibles en la p&aacute;gina Web de la Universidad: www.uft.cl
        </p>


        <p class="Art">
            <span class="NumArt">D&Eacute;CIMO:</span> Las becas promocionales y asistenciales propias de la Universidad se regir&aacute;n por el
            reglamento respectivo. Si el alumno es de aquellos que han sido preseleccionados con Cr&eacute;dito con Aval del Estado y/o
            con alg&uacute;n tipo de beca otorgada por el Ministerio de Educaci&oacute;n, declara en este acto que est&aacute;
            totalmente informado acerca de ambos procesos y que conoce la eventual posibilidad de que en definitiva no se le asignen
            los beneficios antes se&ntilde;alados por no cumplir &eacute;l o la carrera con los requisitos exigidos por la Ley N&ordm;20.027,
            por el Ministerio de Educaci&oacute;n o por la Universidad, eximiendo desde ya a &eacute;sta &uacute;ltima de todo perjuicio
            que esto le ocasionare, y autorizando a &eacute;sta para realizar ajustes a los montos de arancel se&ntilde;alados en la
            cl&aacute;usula Tercera de este Contrato, para el caso que el Alumno no fuera favorecido con alguno de los beneficios.
        </p>

        <p class="Art">
            <span class="NumArt">D&Eacute;CIMO PRIMERO:</span> Para todos los efectos legales derivados del presente contrato,
            las partes fijan domicilio en la ciudad de Santiago y se someten a la jurisdicci&oacute;n
            de los Tribunales Ordinarios de Justicia.
        </p>

        <p class="Art">
        <span class="NumArt">D&Eacute;CIMO SEGUNDO:</span>El contratante declara haber le&iacute;do y conocer el texto
        y alcance del presente contrato y lo acepta en su totalidad.

        </p>

        <p class="Art">
        <span class="NumArt">D&Eacute;CIMO TERCERO:</span>El presente contrato se firma en dos ejemplares del mismo tenor y efecto,
        quedando uno en poder de cada parte.

        </p>

        <table style="width:100%;text-align:center;page-break-inside: avoid;">
            <tr>
                <td class="Firma">');
                    htp.p('<img src="data:image/jpg;base64,');
                    htp.p('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDABALDA4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9PDkzODdASFxOQERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/wgALCACAAJcBAREA/8QAGgABAAMBAQEAAAAAAAAAAAAAAAEEBQMCBv/aAAgBAQAAAAH6AAARIAAABwqaNbxCPGkAcq1S7Z9mLOxIDGjV6kcMnZrXgRm+O0TM++PnSo3wipWy7/TVlGd6u17SSnSnneuyVHLpbqWOjjzqd7fur4u+czRp+rwZ3LUz9JgV/p87v6z+2kGbpRmacfO69uney2l6RLn0Z/S358+XTH2pAAecuj9B0AARX4XvQAAAAAAB/8QAKRAAAgIBAgQGAgMAAAAAAAAAAgMBBAARExASFCAFISMkMDM0UCIxMv/aAAgBAQABBQL9Y1kLgmuDgT1jO8c5zWJzWzm+QZWeTz+FhwsFjpnMVl+zzYIwMcb7ZyV9IP8AfwmzcsugiJYQsOw2gAojctsjmXTmZr973FKwLp64QNYIuK5uqgs5rBZtNnIrrxoxJ1POcqfX3TMum2xYoU1gh0sniELk+xM85UvxynQa4+37WzJEQN0qV4iRTD2xXjtss20AG3Wo/i2frywo2wAwA8Gs21qHbCPdMslPKIwA5YdsgmyDjyZiML17Z/4o/ix6lntZPPZnmtzEQML9W3w8SPSfDR9fHK6g0JhIPnRC2bVJIOWXbV828KH05rrjFTbtIrgjJnTKpEQ54gfLXqqnNfPtgBguE15gxUXDSIz+RYeggjySRQAr93Y+eY1gXGlcQ28YBAD85b2dOTMiIiP1v//EADUQAAECAwUFBQYHAAAAAAAAAAEAAgMREhAhMUFREyAiYXEjMkJSgTBAUGKCsQQzQ3KRobL/2gAIAQEABj8C+GX45DVML2tpcZSzslVM6C9cMF3rcvy2D6l3IZ9V2sJzRqL08y7MYeyLn');
                    htp.p('YBbaNKr/KDoY4GZnVdo8u5YBSaANwQWYnFNiMw8Y19lS0VUYDmhDnVFd/DQg1uA3SahcpnwiZ6pw1CbPEXewfs7mtxcmBonEeqoruN2JUnTb1XZse/oFcxrOpXHGP0iSvm7qUyE0XYlRX6usP7jv0i5gxOqdCBvNwaEYgaJ92Z+y2n4mIZ/ZVtZJg7vPnuxYvoEOpRKaDnvbJv1HQI1v2UFuTVtS2XlCdFYaBPhIz5qcR7onXDdcc8AqeSaqPOZWANiUaoNbgLS5Tf3je4qr9FuHzIQ2959yDRgLKpTvlJOa3Ef3ZeZIN8MK89UeiYvlh/feDfDDFRVIBbBzPmUhgnvyZwi2GPVE6CymZAbpqqRfqU88lDl33d0IN4aMzmTvRznXK12tRnbEkZBty4cZX2Oc5spmfWyXmuQiv0k0aBS3i4C842l8GJsycRKYXaxC/lgLLgs2pzswEzoi5xkAtoR2bMOfuBCodBfNueSv4YYQa0SA9w4aPVdu+Y8owUgJD4d/8QAKRABAAIBAgUDBAMBAAAAAAAAAQARMSFBEFFhgbEgcaEwQJHRUMHw4f/aAAgBAQABPyH+MHtlaDlRUaGtaX14fLAXxNx+tI2Xu7SrwGR1m6NJAuDS51+k/X9ktKBml4HKIpOPAxfV0t4JRi8g9CDIap4mrFNHmQQCNj9F/iedb7RQTEfXoFDLFhoLq5Tan5JBZwhALevt9BAdB/SQqd1gZV5xIRS+c8ie4SJqfOTQmz73vEPisIA2U6zC4ltM2nb/ANiOJo/3a+tCrhPwIGCrIsSpxPb7CBCmGoNECygq2r6bfEXskNM7p8zpcXKibpaPXXgI4b9ApaXWBpuxMiTNpybHN6x3h9Qbw5FBs/D01Bl+RldvNfvPJ8xWBkP3g');
                    htp.p('AAYIhYXhuQeKCjiTG2Dmy9bcEuSKXRzfqYmrXobsMmgo4BnaBbMSKub4cKWqzRcVLrIKl6p5XmK9NQru9VxXgfPaOqNkKej2hk6GgR8m+9vx6Q3F3Buui93zJZxS2mVnQpyiGxrqMpbu90epXf6BwcSqm7hAYa1KPwgf93mqWuBc4A1Zg583fBf31cIo0gVACtx09QODO58XccyDtFfhhAAKCiFtAvVomg4bzpbDlidXMFPphQMhZ7bRd32HWwqEFAqmXW5qfa2x/1mxyB9hyr6pikezcGhBgP47//aAAgBAQAAABAAAIAAAA/4AcEAILA37gqmIVh2OJwEJ8F6AQaCAAIAAYAAAAAAAP/EACkQAQABAwIGAgIDAQEAAAAAAAERACExQVFhcYGRobEQIDDwUMHRQOH/2gAIAQEAAT8Q/jJe1hZ2gVOV2ZpnQ9vi0HbXsSpwTmyh5Z8VnEbN6FZjwnsChoQyQ+LFw6U/FRk5ieXaT8S5gMGVoHFprTOONmnXdpxPo9GmYywYPN6k5dM3gZ6tHzHRB9G7U24nHVl/9p3hMrINpoi0ZYEiYT8L9Ycavd6HtWUb1DjEOWrUMwI4rqvF+gEgHFpx9SEq8KkfN7XS6EHSjPFBPKlCleoIeI++CWpEwt1O68dKgrXimlVsT4qcaI3dIMwbVKrbbiHLJ1oVHKz3MFW0kMszpQG2Fl8ou0A3r8TjxVn5gRbpRLFKjkW91cozFGXoqfcx4IZCvRu0dXFSBkggx1qbJiAEAAbzSBM0QO0/5S1LQVDlTpt1frrCF7S/2mhk2jiqlXX7ChCQ5FmbcdfgGQGJH6JeDB/SXSpIIogTYl3f0pZOHVu8bvFQt6hGPQbcqUjkkDsWetABAQH00pMG9ipgCXzwv5pT+7KpLWzGYcuw0TYBAGhQODhX2p01qwd4+bmbZvFg704rnzXnsFqKmkGtHqmz91orV3D9gPdF+GDgfANoYoSePelgKQIWGu');
                     htp.p('4+C0AEiJXBzota50Xg6f7RLYE8V+xxUePHdHN2Pf2GQHwFnQgza8camoeWuCDjiohJQGAqQ7i2ZXX9ck+XHjJvrg/ugzGfmp8EcYXI4HoHmnS3ZpatX/izeMNJzeiJnkZoiqScqold/B9pBzJByYPb8JEhLGKUjlLcNv6j4YRgsU3qfIwkklo9qzlSjZGsaXpwgMWN6igkGQG1jJEGfgAYFBrBd9eanb0UUZjdzQnmEW6L4vhx9o06wbMTx+VBTMRG8sNDzwRdYLvejQgsBpQswsBL0zTCCKwSDeGQPPKoCyDNYNCJFsfKhAFOAFFn5ba24++3/BeWJpbSVbvP5GY0AjegLmb1D5NKLoKA/OzFs0gwZs/gH3TUTZh7+rQNBgEAcv47/9k="/>');

                        HTP.p('<br/>
                    <hr/>
                </td>
                <td>&nbsp;</td>
                 <p style="font-size: 9px;">La factura correspondiente se emitirá en forma electrónica y se enviará al correo y/o domicilio del suscriptor dentro de las 48 horas siguientes al cierre del contrato.</p>
                <td class="Firma"><hr/></td>
            </tr>
            <tr>
                <td class="SubF">
                    UNIVERSIDAD FINIS TERRAE<br/>
                    Eduardo Bustos Adonis<br/>
                    Director de Finanzas y Contabilidad
                </td>
                <td>&nbsp</td>
                <td class="SubF">
                    CONTRATANTE<br/>
                    '||vsNomCApo||'<br/>
                    '||vrDatosBase.RutApo||'
                </td>
            </tr>
        </table>
    </body>
</html>'
    );
END  p_Contrato_firma_ebustos_2014;


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
        WHEN 'A' THEN 'periodo académico I y II semestre'
        WHEN '1' THEN 'primer semestre del periodo académico'
        WHEN '2' THEN 'segundo semestre del periodo académico'
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
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo3"><td colspan="20"><B>CONTRATO DE SERVICIOS EDUCACIONALES</B></td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">

     En Santiago, a '||TO_CHAR(vrDatosBase.FEmi
            ,'DD" de "MONTH" de "YYYY')||' entre la Universidad Finis Terrae, con domicilio
         en esta ciudad, Av. Pedro de Valdivia Nº 1509, Providencia, RUT Nº 70.884.700-3, en lo sucesivo la
         Universidad, por una parte, y por otra, Don(a) ' || vlApeApoD || ' ' || vlNomApod || ', RUT Nº ' || vlRUTApod || ', domiciliado(a) en
         ' || pk_MatApoderado.f_Direccion(vlRUTApod, vsTerm) || ', ' || pk_MatApoderado.f_Comuna(vlRUTApod, vsTerm) || ', ' || pk_MatApoderado.f_Ciudad(vlRUTApod,vsTerm)
         || ', en adelante el contratante, se ha convenido el siguiente contrato de prestación de servicios educacionales:
         </td></tr>');



    --
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>PRIMERO:</B> La Universidad, a solicitud del contratante, acepta e inscribe al
         ALUMNO(A), <B>' || vlApellido || ' '  || vlNombre || ' ( ' || vlRutAlu || ')</B>,
         quien se ha matriculado, previo pago o documentación de la matrícula correspondiente,
         como alumno regular para el ' || vvTextContrato || '
         del año <B>' || vlTerm || ' (' || vsTerm || ' ) </B>, en la carrera de <B>' || vlProg || '</B>
         </td></tr>');

    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>SEGUNDO:</B> El valor total de la colegiatura, incluida la matrícula será de <B>
         $ ' || TO_CHAR( vlMonto, ConstglFormato)  || '</B>, que se pagará en cuotas mensuales, con vencimientos los
         días INDICADOS de cada mes, a contar del mes ESPECIFICADO EN CLAUSULA TERCERA.
         </td></tr>');

--           En caso que el contratante opte por pagar en este acto, al contado, la
--           totalidad de la colegiatura, su valor será de $ ************ -


    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>TERCERO:</B> Para facilitar el cumplimiento de la obligación de pago a que se obliga en virtud
         de la cláusula anterior, así como también el pago de la matrícula, el contratante acepta
         en este acto, la siguiente documentación, con vencimiento en las fechas que se señalan y
         por los montos que se indican:
         </td></tr>');

    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');

    htp.p('<tr class="Estilo21"><td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               <td colspan="1">&nbsp</td>
                               </tr>');
-- htp.p('<tr><B><td colspan="3" class="Estilo2">Codigo</td>
--                  <td colspan="4" class="Estilo2">Medio de<BR>Pago</td>
--                  <td colspan="3" class="Estilo2">Documento</td>
--                  <td colspan="3" class="Estilo2">Vencimiento</td>
--                  <td colspan="3" class="Estilo2">Banco</td>
--                  <td colspan="4" class="Estilo22">Balance</td>
--                  </tr>');

-- htp.p('<tr><td colspan="1" class="Estilo11">&nbsp;</td>
--                <td colspan="3" class="Estilo11">Medio de Pago</td>
--                <td colspan="2" class="Estilo11">N&uacute;mero de Documento</td>
--                <td colspan="2" class="Estilo11">Banco</td>
--                <td colspan="4" class="Estilo11">Vencimiento</td>
--                <td colspan="4" class="Estilo11">Concepto</td>
--                <td colspan="2" class="Estilo11">Monto</td>
--               </tr>');

    htp.p('<tr><B>
                <td colspan="4" class="Estilo2">Medio de<br/>Pago</td>
                <td colspan="3" class="Estilo2">N&uacute;mero de <br/>Documento</td>
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
            HTP.HEADER(1, '&nbsp', cattributes=>'class=SaltoDePagina' );
            HTP.P ('<table width=100%  border="0">');
            HTP.P ('<col span="17" style="width: 3em" />
                 <col span="3" style="width: 3.6em" align="right"  />');

            htp.p('<tr class="Estilo21"><td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       <td colspan="1">&nbsp</td>
                                       </tr>');

            -- INICIALIZA UNOS VARIABLES DE CONTROL
            vnPagina := vnPagina + 1;
            vnRenglon := 1;
        END IF;

    END LOOP;

    IF (vnRengCon <= 45 AND vnRengCon >= 40 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '&nbsp', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table width=100% border="0">');
    END IF;

    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         La Universidad NO está obligada a notificar en cada oportunidad las fechas de pago y
         se reserva el derecho de efectuar la cobranza en forma directa o a través de una entidad
         bancaria o financiera, vencidos los plazos establecidos en la Ley 19.496.
         </td></tr>');

    IF (vnRengCon <= 39 AND vnRengCon >= 35 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '&nbsp', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table  width=100% border="0">');
    END IF;

    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>CUARTO:</B> En virtud del presente contrato, la Universidad se obliga a mantener el
         cupo asignado al alumno regular en los servicios docentes que prestará durante el año
         académico, sin perjuicio de lo dispuesto en la cláusula séptima de este contrato.
         </td></tr>');

    IF (vnRengCon <= 34 AND vnRengCon >= 30 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '&nbsp', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table width=100% border="0">');
    END IF;

    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>QUINTO:</B> Los cursos que la Universidad impartirá durante el año académico señalado
         en la cláusula primera serán los que correspondan al currículo de la carrera, según sea
         que él se desarrolle en forma semestral o anual. En ningún caso disminuirá el valor de la
         colegiatura si el alumno no toma o no puede tomar, por cualquier causa, el total de los
         cursos contemplados en el currículo respectivo. Lo mismo será válido por si cualquier
         causa justificada, no se impartiere un determinado curso del currículo correspondiente
         a un periodo académico determinado.
         </td></tr>');

    IF (vnRengCon <= 29 AND vnRengCon >= 25 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '&nbsp', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table width=100% border="0">');
    END IF;

    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
         <B>SEXTO:</B> La mora o el simple retardo en el pago de una o más cuotas facultará a
         la Universidad para exigir el pago de toda la deuda y sus intereses, como si
         fuera de plazo vencido. Si la Universidad no ejerciere este derecho en caso
         alguno significará que renuncia al mismo.
         </td></tr>');
/*
    IF (vnRengCon <= 25 ) THEN
        HTP.TABLECLOSE;
        HTP.HEADER(1, '&nbsp', cattributes=>'class=SaltoDePagina' );
        HTP.P('<table width=100% border="0">');
    END IF;
*/
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          En este caso, durante el período de mora de cualquiera de las cuotas,
          la Universidad estará facultada para cobrar el interés máximo convencional
          para operaciones no reajustables, calculado desde la fecha de vencimiento
          original hasta la de pago efectivo. <B>En el evento que el pago se efectuara
          en la Universidad y no en la entidad bancaria o financiera, tendrá un costo
          adicional por servicio administrativo ascendente a $5.000.</B>
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          Mientras persista la mora o el simple retardo en el pago de una o más cuotas del
          valor de la colegiatura, el alumno no podrá presentarse a exámenes, inscribir cursos
          para el período académico siguiente, recibir su título profesional o grado académico u
          obtener certificaciones. Lo mismo ocurrirá mientras el alumno no haya devuelto
          oportunamente bienes o materiales entregados en préstamo.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          <B>SÉPTIMO:</B> El contratante estará obligado a pagar oportunamente el total de la suma acordada
          por el periodo completo convenido, aún cuando el alumno no hiciere uso del servicio educacional
          contratado, por cualquier causa, tales como retiro, suspensión o anulación de periodos académicos
          no procediendo devolución, imputación ni compensación alguna, toda vez que la universidad ha adquirido
          compromisos académicos y económicos para la prestación de los servicios contratados. Esta obligación
          persistirá en el caso que el alumno sea eliminado como consecuencia de su rendimiento académico o si
          fuera sancionado reglamentariamente con la suspensión o expulsión de la Universidad por haber incurrido
          en falta grave de acuerdo con el Reglamento del Alumno.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          La misma obligación existirá en caso de impedimento temporal de la Universidad para prestar el servicio
          educacional por eventos de fuerza mayor, ya sea naturales o provocados por terceras personas. El alumno
          se obliga tambi&eacute;n a pagar el respectivo derecho o arancel de licenciamiento o titulaci&oacute;n
          que anualmente fija la Universidad para cada una de sus carreras, en el momento en que de inici&oacute;
          a su proceso de licenciamiento o titulaci&oacute;n.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          <B>OCTAVO:</B> Para todos los efectos legales derivados del presente contrato, las partes fijan domicilio
          en la ciudad de Santiago y se someten a la jurisdicción de los Tribunales Ordinarios de Justicia.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          <B>NOVENO:</B> El contratante declara haber leído y conocer el texto y alcance del presente
          contrato y lo acepta en su totalidad.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">
          <B>DÉCIMO:</B> El presente contrato se firma en dos ejemplares del mismo tenor y efecto,
          quedando uno en poder de cada parte.
         </td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo5"><td colspan="20">&nbsp</td></tr>');
    htp.p('<tr class="Estilo1"><td colspan="3">&nbsp</td>
                               <td colspan="7">' ||
                               HTF.IMG('/wtlgifs/firma_contrato.jpg', cattributes=>'WIDTH="140" HEIGTH="60"') || '
                               <td colspan="10">&nbsp</td></tr>');
    htp.p('<tr class="Estilo1"><td colspan="3">&nbsp</td>
                               <td colspan="5">_________________________________</td>
                               <td colspan="7">&nbsp</td>
                               <td colspan="5">_________________________________</td></tr>');

    htp.p('<tr class="Estilo1"><td colspan="3">&nbsp</td>
                               <td colspan="5">UNIVERSIDAD FINIS TERRAE</td>
                               <td colspan="7">&nbsp</td>
                               <td colspan="5"> CONTRATANTE</td></tr>');
    HTP.TABLECLOSE;
    HTP.P('</BODY></HTML>');
EXCEPTION
  WHEN OTHERS THEN
     htp.p(SQLERRM);
END p_Contrato2011;

END pk_Contrato;
/


CREATE OR REPLACE PACKAGE BANINST1.pk_Contrato IS
/******************************************************************************
PAQUETE:			BANINST1.pk_Contrato
OBJETIVO:			Contiene los procedimientos, funciones y variables
					requeridos para la impresion de la documentación del
					proceso de matricula, así como código auxiliar para el
					funcionamiento de las pantallas TWAPAYM/TWAMACE
AUTORES:			Eduardo Armando Moreno Macal
					Gilberto Velazquez Hernandez
FECHA (REFACT):		20130102
******************************************************************************/

--Contante para el formato de los montos
ConstglFormato			CONSTANT VARCHAR2(15) DEFAULT '999G999G999G999';

/******************************************************************************
TIPO:				ty_contrato
OBJETIVO:			Registro con la información que se despliega en las
					pantallas TWAPAYM/TWAMACE
MIEMBROS:
pidm				pidm del alumno
tran				Numero de transaccion en TBRACCD
term				periodo
detail				Codigo de detalle de la transaccion
balance				Balance de la transaccion
efedate				Fecha Efectiva de la transaccion
descr				Descripcion/Nota de la transaccion
seqnum				Numero secuencial de documento
paym				medio de pago
docume				numero de documento
dmonto				Monto del documento
dfechaven			Fecha de vencimiento del documento
dstatus				Status del documento
numcont				numero de contrato
banco				clave del banco del documento
ttarjeta			tipo de tarjeta de credito
plaza				plaza del documento
cuecon				cuenta corriente del documento
dcat				Codigo de Categoria
cmod				Bandera si el medio de pago se puede editar.
******************************************************************************/
TYPE ty_contrato IS RECORD (
	pidm				TBRACCD.TBRACCD_PIDM%TYPE,
	tran				TBRACCD.TBRACCD_TRAN_NUMBER%TYPE,
	term				TBRACCD.TBRACCD_TERM_CODE%TYPE,
	detail				TBRACCD.TBRACCD_DETAIL_CODE%TYPE,
	balance				TBRACCD.TBRACCD_BALANCE%TYPE,
	efedate				TBRACCD.TBRACCD_EFFECTIVE_DATE%TYPE,
	descr				TBRACCD.TBRACCD_DESC%TYPE,
	seqnum				TWBDOCU.TWBDOCU_SEQ_NUM%TYPE,
	paym				TWBDOCU.TWBDOCU_PAYM_CODE%TYPE,
	docume				TWBDOCU.TWBDOCU_DOCU_NUM%TYPE,
	dmonto				TWBDOCU.TWBDOCU_AMOUNT%TYPE,
	dfechaven			TWBDOCU.TWBDOCU_EXPIRATION_DATE%TYPE,
	dstatus				TWBDOCU.TWBDOCU_STATUS_IND%TYPE,
	numcont				TWBDOCU.TWBDOCU_CNTR_NUM%TYPE,
	banco				TWBDOCU.TWBDOCU_BANK_CODE%TYPE,
	ttarjeta			TWBDOCU.TWBDOCU_CTYP_CODE%TYPE,
	plaza				TWBDOCU.TWBDOCU_PLCE_CODE%TYPE,
	cuecon				TWBDOCU.TWBDOCU_CURR_ACNT%TYPE,
	dcat				TBBDETC.TBBDETC_DCAT_CODE%TYPE,
	cmod				TWVPAYM.TWVPAYM_USER_EDITABLE_IND%TYPE
);

/******************************************************************************
TIPO:				rc_contrato
OBJETIVO:			Cursor de Referencia para uso en la pantalla TWAPAYM/TWMACE
******************************************************************************/
TYPE rc_contrato IS REF CURSOR RETURN ty_contrato;

/******************************************************************************
TIPO:				tty_contrato
OBJETIVO:			Arreglo (tabla anidada) de registros para desplegarse
					en TWAPAYM/TWMACE
******************************************************************************/
TYPE tty_contrato IS TABLE OF ty_contrato INDEX BY BINARY_INTEGER;

/******************************************************************************
TIPO:				ty_resumen
OBJETIVO:			Registro con la información que se despliega en las
					pantallas TWAPAYM/TWAMACE como resumen
MIEMBROS:
paym				medio de pago
dpaym				Descripcion del Medio de Pago
docume				numero de documento
dmonto				Monto del documento
banco				clave del banco del documento
dbanco				Descripcion del Banco
ttarjeta			tipo de tarjeta de credito
dtarjeta			Descripcion de la tarjeta
******************************************************************************/
TYPE ty_resumen IS RECORD (
	paym				TWBDOCU.TWBDOCU_PAYM_CODE%TYPE,
	dpaym				VARCHAR2(30),
	docume				TWBDOCU.TWBDOCU_DOCU_NUM%TYPE,
	dmonto				TWBDOCU.TWBDOCU_AMOUNT%TYPE,
	banco				TWBDOCU.TWBDOCU_BANK_CODE%TYPE,
	dbanco				VARCHAR2(30),
	ttarjeta			TWBDOCU.TWBDOCU_CTYP_CODE%TYPE,
	dtarjeta			VARCHAR2(30)
);

/******************************************************************************
TIPO:				rc_contrato
OBJETIVO:			Cursor de Referencia para el resumen en las pantallas
					TWAPAYM/TWMACE
******************************************************************************/
TYPE rc_resumen IS REF CURSOR RETURN ty_resumen;


	-- CURSOR PARA LA GENEARACION DE DATOS DEL CONTRATO
	CURSOR cuContrato(
		psPidm			TBRACCD.TBRACCD_PIDM%TYPE,
		psTerm			TBRACCD.TBRACCD_TERM_CODE%TYPE
	) IS
		SELECT
			TBBDETC_TYPE_IND,
			TBRACCD_DETAIL_CODE,
			TWBDOCU_PAYM_CODE,
			TBRACCD_DESC,
			TBRACCD_TERM_CODE,
			TWVPAYM_DESC,
			DECODE (TWBDOCU_PAYM_CODE, 'EFE', '00000000', TWBDOCU_DOCU_NUM) AS TWBDOCU_DOCU_NUM,
			TO_CHAR( TRUNC(TBRACCD_EFFECTIVE_DATE), 'DD/MON/YYYY') AS TBRACCD_EFFECTIVE_DATE1,
			TWBDOCU_BANK_CODE,
			TWRDOTR_PART_AMOUNT AS TBRACCD_BALANCE,
			SUM ( DECODE(TBBDETC_TYPE_IND, 'C', TBRACCD_AMOUNT, 0) ) AS CARGO,
			SUM ( DECODE(TBBDETC_TYPE_IND, 'P', TBRACCD_AMOUNT, 0) ) AS PAGO
		FROM
			TBRACCD,
			TWRDOTR,
			TWBDOCU,
			TWVPAYM,
			TBBDETC
		WHERE
			TBRACCD_PIDM = psPidm
			AND TBRACCD_TERM_CODE = psTerm
			AND TWRDOTR_PIDM = TBRACCD_PIDM
			AND TWRDOTR_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
			AND TWRDOTR_DOCU_SEQ_NUM = TWBDOCU_SEQ_NUM
			AND TWVPAYM_CODE = TWBDOCU_PAYM_CODE
			AND TWVPAYM_AGRE_PRINTABLE_IND = 'Y'
			AND TWBDOCU_STATUS_IND <> 'CA'
			AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
			AND TBBDETC_TYPE_IND = 'C'
		GROUP BY
			TBBDETC_TYPE_IND,
			TBRACCD_DETAIL_CODE,
			TWBDOCU_PAYM_CODE,
			TBRACCD_DESC,
			TBRACCD_TERM_CODE,
			TWVPAYM_DESC,
			DECODE (TWBDOCU_PAYM_CODE, 'EFE', '00000000', TWBDOCU_DOCU_NUM),
			TRUNC(TBRACCD_EFFECTIVE_DATE),
			TO_CHAR( TRUNC(TBRACCD_EFFECTIVE_DATE), 'DD/MON/YYYY'),
			TWBDOCU_BANK_CODE,
			TWRDOTR_PART_AMOUNT
		ORDER BY TBBDETC_TYPE_IND,
			TRUNC(TBRACCD_EFFECTIVE_DATE),
			TBRACCD_DETAIL_CODE;

/******************************************************************************
PROCEDIMIENTO:		p_SelContratos
OBJETIVO:			Procedimiento de seleccion para el bloque de datos
					principal en la pantalla TWAPAYM
PARAMETROS:
psPidm:				Pidm del Alumno
psTerm:				Periodo de Matricula
rcContrato:			Parametro de Salida. Cursor con los datos para el bloque
******************************************************************************/
PROCEDURE p_SelContratos(
	psPidm		IN		NUMBER		DEFAULT NULL,
	psTerm		IN		VARCHAR2	DEFAULT NULL,
	rcContrato	IN OUT	rc_contrato
);

/******************************************************************************
PROCEDIMIENTO:		p_InsContratos
OBJETIVO:			Procedimiento de insercion para el bloque de datos
					principal en la pantalla TWAPAYM
PARAMETROS:
TContratos:			Parametro de Salida. Cursor con los datos del bloque ???
******************************************************************************/
PROCEDURE p_InsContratos (TContratos IN OUT tty_contrato);

/******************************************************************************
PROCEDIMIENTO:		p_UpdContratos
OBJETIVO:			Procedimiento de actualizacion para el bloque de datos
					principal en la pantalla TWAPAYM
PARAMETROS:
TContratos:			Parametro de Salida. Cursor con los datos del bloque ???
******************************************************************************/
PROCEDURE p_UpdContratos (TContratos IN OUT tty_contrato);

/******************************************************************************
PROCEDIMIENTO:		p_DelContratos
OBJETIVO:			Procedimiento de eliminación para el bloque de datos
					principal en la pantalla TWAPAYM
PARAMETROS:
TContratos:			Parametro de Salida. Cursor con los datos del bloque ???
******************************************************************************/
PROCEDURE p_DelContratos (TContratos IN OUT tty_contrato);

/******************************************************************************
PROCEDIMIENTO:		p_LokContratos
OBJETIVO:			Procedimiento de bloqueo para el bloque de datos
					principal en la pantalla TWAPAYM
PARAMETROS:
TContratos:			Parametro de Salida. Cursor con los datos del bloque ???
******************************************************************************/
PROCEDURE p_LokContratos (TContratos IN OUT tty_contrato);

/******************************************************************************
PROCEDIMIENTO:		p_SelContratos
OBJETIVO:			Procedimiento de seleccion para el bloque de datos
					de resumen en la pantalla TWAPAYM
PARAMETROS:
psPidm:				Pidm del Alumno
psTerm:				Periodo de Matricula
rcResumen:			Parametro de Salida. Cursor con los datos para el bloque
******************************************************************************/
PROCEDURE p_SelResumen (
	psPidm		IN		NUMBER		DEFAULT NULL,
	psTerm		IN		VARCHAR2	DEFAULT NULL,
	rcResumen	IN OUT	rc_resumen
);

/******************************************************************************
PROCEDIMIENTO:		p_Contrato
OBJETIVO:			Imprime en web el contrato legal especificado
PARAMETROS:
psCntr:				Numero del contrato
OBSERVACIONES:		Sirve unicamente como un wrapper, evalua que contrato se
					imprimirá en base a la fecha de emisión y llama al
					procedimiento acorde.
******************************************************************************/
PROCEDURE p_Contrato(psCntr VARCHAR2);

/******************************************************************************
PROCEDIMIENTO:		p_Recibo
OBJETIVO:			Imprime al buffer HTP el recibo de ingreso a tesoreria
					relacionado con el contrato indicado
PARAMETROS:
psCntr:				Numero del contrato
******************************************************************************/
PROCEDURE p_Recibo(psCntr VARCHAR2);

/******************************************************************************
PROCEDIMIENTO:		p_Boleta
OBJETIVO:			Imprime al buffer HTP la boleta de servicios relacionada
					con el contrato indicado
PARAMETROS:
psCntr:				Numero del contrato
******************************************************************************/
PROCEDURE p_Boleta(psCntr VARCHAR2);

/******************************************************************************
PROCEDIMIENTO:		p_Pagare
OBJETIVO:			En base al contrato indicado, determina cuales la
					informacion a imprimirse e invoca a pk_MatPagare
PARAMETROS:
psCntr:				Numero del contrato
******************************************************************************/
PROCEDURE p_Pagare(psCntr VARCHAR2);

/******************************************************************************
PROCEDIMIENTO:		p_Cuponera
OBJETIVO:			En base al contrato indicado, determina cuales la
					informacion a imprimirse e invoca a pk_MatCupon
PARAMETROS:
psCntr:				Numero del contrato
******************************************************************************/
PROCEDURE p_Cuponera(psCntr VARCHAR2);

END pk_contrato;
/


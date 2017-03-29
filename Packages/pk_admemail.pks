DROP PACKAGE BANINST1.PK_ADMEMAIL;

CREATE OR REPLACE PACKAGE BANINST1.PK_ADMEMAIL IS
/*******************************************************************************
Nombre			PK_ADMEMAIL
Autor			Eduardo Armando Moreno Macal
Fecha			16 de Mayo de 2012
Objetivo		Paquete que contiene toda la funcionalidad para el
				modulo de control de email de la universidad
Version			Fecha			Autor			Descripcion
	1.0			16/May/2012		EAMM			Creacion del paquete
*********************************************************************************/

-- PROCESO QUE BUSQUEDA DEL PIDM
FUNCTION f_ExistePidm (
	psPidm		IN		NUMBER)
	RETURN NUMBER;

-- GENERA Y VALIDA EL EMAIL
PROCEDURE p_genmail(
	psPidm		IN		NUMBER,
	psEmail		IN OUT	GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE);

-- FUNCION DE VALIDACION DE EXISTENCIA DE MAIL EN GOREMAL GENERAL
FUNCTION f_existemail(
	psPidm		IN		NUMBER)
    RETURN NUMBER;

-- PROCESO DE VALIDACION EL EMAIL
PROCEDURE p_valmail(
	psPidm		IN		NUMBER,
	psEmail		IN		GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE);

-- PROCESO DE INSERTADO DE MAIL GENERAL
PROCEDURE p_insmail(
	psPidm		IN		NUMBER,
	psEmail		IN		GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE);

-- FUNCION QUE TRAE EL PASSWORD TEMPORAL DEL ALUMNO
FUNCTION f_get_pass(
	psPidm		IN		NUMBER)
    RETURN VARCHAR2;

/******************************************************************************
PROCEDIMIENTO:		p_Comprobante
OBJETIVO:			Impresion de documentacion del Admisiones
PARAMETROS:
pnPidm				Numero de Pidem del alumno
******************************************************************************/
PROCEDURE p_Comprobante(
	psPidm			NUMBER) ;

-- FUNCION QUE VALIDA QUE TENGA EL FORMATO DE STANDAR EL NOMBRE DEL ALUMNO
FUNCTION f_valnombre(
	psPidm		IN		NUMBER)
    RETURN VARCHAR2;

-- PROCESO GENERAL DE EMAIL DE ALUMNOS Y DOCENTES
PROCEDURE p_armaemail(
	psPidm		IN		NUMBER);


END PK_ADMEMAIL;
/


DROP PUBLIC SYNONYM PK_ADMEMAIL;

CREATE PUBLIC SYNONYM PK_ADMEMAIL FOR BANINST1.PK_ADMEMAIL;


GRANT EXECUTE ON BANINST1.PK_ADMEMAIL TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PK_ADMEMAIL TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PK_ADMEMAIL TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PK_ADMEMAIL TO SATURN;

GRANT EXECUTE ON BANINST1.PK_ADMEMAIL TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ADMEMAIL TO WWW2_USER;

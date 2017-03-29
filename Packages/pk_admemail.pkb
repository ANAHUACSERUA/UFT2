DROP PACKAGE BODY BANINST1.PK_ADMEMAIL;

CREATE OR REPLACE PACKAGE BODY BANINST1.PK_ADMEMAIL IS
/*******************************************************************************
Nombre			PK_ADMEMAIL
Autor			Eduardo Armando Moreno Macal
Fecha			16 de Mayo de 2012
Objetivo		Paquete que contiene toda la funcionalidad para el
				modulo de control de email de la universidad
Version			Fecha			Autor			Descripcion
	1.0			16/May/2012		EAMM			Creacion del paquete
*********************************************************************************/
-- DECLARACION DE CONSTANTES
gv_CodeMail		CONSTANT	GOREMAL.GOREMAL_EMAL_CODE%TYPE := PK_UTIL.f_ObtieneParam('MAIL', 'code');
gv_Codeserv		CONSTANT	GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE := PK_UTIL.f_ObtieneParam('MAIL', 'serv');
gv_PassMail 	CONSTANT	GOREMAL.GOREMAL_EMAL_CODE%TYPE := PK_UTIL.f_ObtieneParam('MAIL', 'pass');
-- FUNCION QUE BUSQUEDA DEL PIDM SI EXISTE
FUNCTION f_ExistePidm (
	psPidm		IN		NUMBER)
	RETURN NUMBER IS
--- DECLARACION DE VARIABLES LOCALES
vnExiste		NUMBER(2):=0;
BEGIN
	-- query qie valida que el PIdm enviando existe
	SELECT COUNT(*)
	  INTO vnExiste
	  FROM GWBMAIL
	 WHERE GWBMAIL_PIDM = psPidm;
	-- REGRESA EL VALOR OBTENIDO
	RETURN vnExiste;
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END f_ExistePidm;

-- GENERA Y VALIDA EL EMAIL
PROCEDURE p_genmail(
	psPidm		IN		NUMBER,
	psEmail		IN OUT	GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE) IS
-- DECLARACION DE VARIABLES LOCALES
vvEmail		GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE;
vnExiste	NUMBER(3):=0;
BEGIN
	-- GENERA EL FORMATO DE LA CUENTA DE EMAIL
	SELECT
		REPLACE(
		TRANSLATE(
		LOWER(
		SUBSTR(SPRIDEN_FIRST_NAME, 1, 1) ||
		SUBSTR(SPRIDEN_LAST_NAME, 1, (INSTR(SPRIDEN_LAST_NAME, '*') -1) ) ||
		SUBSTR(SPRIDEN_LAST_NAME, (INSTR(SPRIDEN_LAST_NAME, '*') + 1 ), 1 )
		),
		'áéíóúàèìòùãõâêîôôäëïöüñ', 'aeiouaeiouaoaeiooaeioun')
		, ' ', NULL) AS EMAIL
	 INTO vvEmail
	 FROM SPRIDEN
	WHERE SPRIDEN_PIDM = psPidm
	  AND SPRIDEN_CHANGE_IND IS NULL;
	-- VALIDA SI EL MAIL EXISTE REPETIDO PARA GENERAR UN CONSECUTIVO
	SELECT COUNT(*)
	  INTO vnExiste
	  FROM GWBMAIL
	 WHERE INSTR(LOWER(GWBMAIL_EMAIL), vvEmail) > 0;
	-- VALIDACION SE ENCONTRO INFORMACION O GENERA SECUENCIA
	IF (vnExiste > 0) THEN
		psEmail := vvEmail || vnExiste;
	ELSE
		psEmail := vvEmail;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		psEmail := 'NO HAY';
END p_genmail;

-- FUNCION DE VALIDACION DE EXISTENCIA DE MAIL EN GOREMAL GENERAL
FUNCTION f_ExisteMail(
	psPidm		IN		NUMBER)
	RETURN NUMBER IS
--- DECLARACION DE VARIABLES LOCALES
vnExiste		NUMBER(2):=0;
BEGIN
	-- query qie valida que el PIdm enviando existe
	SELECT COUNT(*)
	  INTO vnExiste
	  FROM GOREMAL
	 WHERE GOREMAL_PIDM = psPidm
	   AND GOREMAL_EMAL_CODE = gv_CodeMail;
	-- REGRESA EL VALOR OBTENIDO
	RETURN vnExiste;
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END f_ExisteMail;

FUNCTION f_ExistePassMail(
	psPidm		IN		NUMBER)
	RETURN NUMBER IS
--- DECLARACION DE VARIABLES LOCALES
vnExiste		NUMBER(2):=0;
BEGIN
	-- query qie valida que el PIdm enviando existe
	SELECT COUNT(*)
	  INTO vnExiste
	  FROM GOREMAL
	 WHERE GOREMAL_PIDM = psPidm
	   AND GOREMAL_EMAL_CODE = gv_PassMail;
	-- REGRESA EL VALOR OBTENIDO
	RETURN vnExiste;
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END f_ExistePassMail;

-- PROCESO DE VALIDACION EL EMAIL
PROCEDURE p_valmail(
	psPidm		IN		NUMBER,
	psEmail		IN		GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE) IS
-- DECLARACION DE VARIABLES LOCALES
vvEmail		GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE;
vnExiste	NUMBER(3):=0;
BEGIN
	-- VALIDA SI EL MAIL EXISTE REPETIDO PARA GENERAR UN CONSECUTIVO
	SELECT COUNT(*)
	  INTO vnExiste
	  FROM GOREMAL
	 WHERE GOREMAL_PIDM = psPidm
	   AND GOREMAL_EMAL_CODE = gv_CodeMail
	   AND INSTR(LOWER(GOREMAL_EMAIL_ADDRESS), psEmail) > 0;
	-- VALIDACION SE ENCONTRO INFORMACION O GENERA SECUENCIA
	IF (vnExiste = 0) THEN
		-- ACTUALIZA EL CAMPO ENCONTRADO
		UPDATE GENERAL.GOREMAL
		SET GOREMAL_EMAIL_ADDRESS = psEmail || gv_Codeserv
		WHERE GOREMAL_PIDM = psPidm
		  AND GOREMAL_EMAL_CODE = gv_CodeMail;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END p_valmail;

-- PROCESO DE INSERTADO DE MAIL GENERAL
PROCEDURE p_insmail(
	psPidm		IN		NUMBER,
	psEmail		IN		GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE) IS
BEGIN
	-- INSERTA INFORMACION DEL MAIL GENERAL
	INSERT INTO GENERAL.GOREMAL
		(GOREMAL_PIDM, GOREMAL_EMAL_CODE, GOREMAL_EMAIL_ADDRESS, GOREMAL_STATUS_IND, GOREMAL_PREFERRED_IND, GOREMAL_ACTIVITY_DATE, GOREMAL_USER_ID, GOREMAL_DISP_WEB_IND)
	VALUES
		(psPidm, gv_CodeMail, psEmail || gv_Codeserv, 'A', 'Y', SYSDATE, USER, 'Y');
END p_insmail;


-- PROCESO DE INSERTADO EL PASSWORD DE MAIL GENERAL
PROCEDURE p_inspassmail(
	psPidm		IN		NUMBER) IS
BEGIN
	-- INSERTA INFORMACION DEL MAIL GENERAL
	INSERT INTO GENERAL.GOREMAL
		(GOREMAL_PIDM, GOREMAL_EMAL_CODE, GOREMAL_EMAIL_ADDRESS, GOREMAL_STATUS_IND, GOREMAL_PREFERRED_IND, GOREMAL_ACTIVITY_DATE, GOREMAL_USER_ID, GOREMAL_DISP_WEB_IND)
	VALUES
		(psPidm, gv_PassMail, 'Cl@ve_inicial.:'||PK_ADMEMAIL.f_get_pass(psPidm), 'A', 'Y', SYSDATE, USER, 'Y');
END p_inspassmail;

-- FUNCION QUE TRAE EL PASSWORD TEMPORAL DEL ALUMNO
FUNCTION f_get_pass(
	psPidm		IN		NUMBER)
	RETURN VARCHAR2 IS
--- DECLARACION DE VARIABLES LOCALES
vnExiste		GWBMAIL.GWBMAIL_PASSW%TYPE;
BEGIN
	-- query qie valida que el PIdm enviando existe
	SELECT GWBMAIL_PASSW
	  INTO vnExiste
	  FROM GWBMAIL
	 WHERE GWBMAIL_PIDM = psPidm;
	-- REGRESA EL VALOR OBTENIDO
	RETURN vnExiste;
EXCEPTION
	WHEN OTHERS THEN
		RETURN NULL;
END f_get_pass;

/******************************************************************************
PROCEDIMIENTO:		p_Comprobante
OBJETIVO:			Impresion de documentacion del Admisiones
PARAMETROS:
pnPidm				Numero de Pidem del alumno
******************************************************************************/
PROCEDURE p_Comprobante(
	psPidm			NUMBER
) IS

	-- Id del alumno
	vsId				SPRIDEN.SPRIDEN_ID%TYPE;
	-- Nombre del alumno
	vsNomAlum			VARCHAR2(100):= f_get_nombre(psPidm);
	--  Email del alumno
	vsMail				VARCHAR2(30):=f_GetEmailAlum(psPidm, 'UFT');
	-- Genera Password alterno
	vvPass				VARCHAR2 (8):= PK_ADMEMAIL.f_get_pass(psPidm);

BEGIN
	IF (NVL(psPidm, 0) = 0) THEN
		HTP.P('Error el Pidm de alumno no es conocido');
		RETURN;
	END IF;

	--Ya que estoy aqui empiezo la impresion jojojo
	HTP.P('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
    <head>
        <title> Comprobante de Operaci&oacute;n de Congelaci&oacute;nes </title>
    </head>');

	HTP.P('
    <style type="text/css">
        body{
            font-family: Arial, Helvetica, sans-serif;
            font-size: 100%;
            margin: 1cm;
            padding: 0;
            width: 18cm;
        }
        td.DatosFinis{
            width: 12cm;
            vertical-align: top;
        }
        table.DatosFinis{
            font-size: 10px; /*0.8em*/
        }
        td.DatosOper{
            width: 7cm;
            vertical-align: top;
        }
        table.DatosOper{
            font-size: 8px; /*0.6em*/
        }
        h1.Titulo{
            font-weight: bold;
            font-size: 18px;
            text-align: center;
        }
        table.DatosCntr{
            font-size: 9px;
            width: 10cm;
        }
        table.DatosCntr td.NombreCampo{
            width: 4cm;
        }
        .NombreCampo{
            font-weight:bold;
        }
    </style>');

HTP.BODYOPEN;
	HTP.P('
        <table >
            <tr>
                <td class="DatosFinis">
                    <table class="DatosFinis">
                        <tr><td>Universidad Finis Terrae</td></tr>
                        <tr><td>Educaci&oacute;n</td></tr>
                        <tr><td>70.884.700-3</td></tr>
                        <tr><td>Av. Pedro de Valdivia 1509</td></tr>
                        <tr><td>Providencia, Santiago</td></tr>
                    </table>
                </td>
                <td class="DatosOper">
                    <table class="DatosOper">
                        <tr>
                            <td class="NombreCampo">
                                Fecha/Hora Oper.:
                            </td>
                            <td>
                                '||TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')||'
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>

        <h1 class="Titulo">
            Comprobante de entrega de Email
        </h1>

        <table class="DatosCntr">
            <tr>
                <td class="NombreCampo">
                    Alumno
                </td>
                <td>
                    '|| vsNomAlum ||'
                </td>
            </tr>
            <tr>
                <td class="NombreCampo">
                    Email:
                </td>
                <td>
                    '|| vsMail ||'
                </td>
            </tr>
            <tr>
                <td class="NombreCampo">
                    Password:
                </td>
                <td>
                    '||vvPass||'
                </td>
            </tr>
        </table>');

HTP.BODYCLOSE;
    HTP.P('
    <script type="text/javascript">'
    );
	HTP.HTMLCLOSE;

EXCEPTION
    WHEN OTHERS THEN
        --pantallazo de error.
        pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),
            'PK_ADMEMAIL.p_Comprobante', NULL);
END p_Comprobante;

-- FUNCION QUE VALIDA QUE TENGA EL FORMATO DE STANDAR EL NOMBRE DEL ALUMNO
FUNCTION f_valnombre(
	psPidm		IN		NUMBER)
	RETURN VARCHAR2 IS
-- DECLARACION DE VARIABLES LOCALES
vnExiste			NUMBER(2):=0;
BEGIN
	-- BUSCA SI TIENE EL ESTANDAR DEL ASTERISCO
	SELECT COUNT(*)
	  INTO vnExiste
	  FROM SPRIDEN
	 WHERE SPRIDEN_PIDM = psPidm
	   AND INSTR(SPRIDEN_LAST_NAME, '*') > 0;
	-- VALIDA LO ENCONTRADO
	IF (vnExiste = 0) THEN
		RETURN 'N';
	ELSE
		RETURN 'Y';
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'N';
END;

-- PROCESO GENERAL DE EMAIL DE ALUMNOS Y DOCENTES
PROCEDURE p_armaemail(
	psPidm		IN		NUMBER) IS
-- TRANSACCION INDEPENDIENTE Y DIFERENTE
-- A LA QUE HAYA INVOCADO A LA FUNCIÓN
PRAGMA AUTONOMOUS_TRANSACTION;
-- DECLARACION DE VARIABLE LOCALES
vvNuevoEmail	GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE:=NULL;
BEGIN
	-- VALIDA SI EL PIDM NO ENVIADO EXISTE
	IF ( f_ExistePidm (psPidm) = 0 AND (f_valnombre(psPidm) = 'Y') ) THEN
		-- ARMAN EL MAIL NUEVO
		p_genmail(psPidm, vvNuevoEmail);
		-- INSERTA EL NUEVO MAIL EN TABLA DE MAIL
		INSERT INTO GWBMAIL (GWBMAIL_PIDM, GWBMAIL_EMAIL, GWBMAIL_PASSW, GWBMAIL_USER, GWBMAIL_ACTIVITY_DATE)
		VALUES(psPidm, vvNuevoEmail, DBMS_RANDOM.STRING('X', 8), USER, SYSDATE);
		-- VALIDA SI SE ENCUENTRA EN MAIL GENERAL
		IF (f_ExisteMail(psPidm) = 0 ) THEN
			-- INSERTA EL NUEVO MAIL
			p_insmail(psPidm, vvNuevoEmail);
            IF
            (f_ExistePassMail(psPidm) = 0 )  THEN
            p_inspassmail(psPidm);
            END IF;
		ELSE
			-- VALIDA SI CUMPLE CON EL STANDAR PARA ACTUALIZARLO
			p_valmail(psPidm, vvNuevoEmail);
		END IF;
		-- CONSOLIDA LA INFORMACION GENERADA
		COMMIT;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;
		DBMS_OUTPUT.PUT_LINE('PIDM CON ERROR  ' || psPidm);
END p_armaemail;


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

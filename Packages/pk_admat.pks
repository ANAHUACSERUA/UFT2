DROP PACKAGE BANINST1.PK_ADMAT;

CREATE OR REPLACE PACKAGE BANINST1.pk_AdMat IS
/******************************************************************************
PAQUETE:			BANINST1.pk_AdMat
OBJETIVO:			Contiene los procedimientos, funciones y variables
					de uso comun para los procesos intermedios entre Admisiones
					y Matrícula.
AUTORES:			Eduardo Antonio Moreno Macal
					Guillermo Almazan Ibañez
					Gilberto Velazquez Hernandez
FECHA:				20111114
******************************************************************************/

/******************************************************************************
FUNCION:			f_CupoDisponible
OBJETIVO:			Indica el numero de cupos de matricula restantes para una
					carrera para el periodo y tipo de ingreso indicado
PARAMETROS:
psPerio:			Periodo de ingreso
psProg:				Programa de ingreso
psTipoIng:			Tipo de Ingreso
VALOR DE RETORNO:	Numero de cupos. En caso de no existir la configuración
					en la tabla SWBCUNI, regresa cero.
******************************************************************************/
FUNCTION f_CupoDisponible(
	psPerio				VARCHAR2
	,psProg				VARCHAR2
	,psTipoIng			VARCHAR2
) RETURN NUMBER;

-- DEVUELDE EL PSU PONDERADO DEL ALUMNO
function f_get_PSU_pond(
				p_pidm					SGBSTDN.sgbstdn_pidm%TYPE,
				p_term					SGBSTDN.SGBSTDN_TERM_CODE_EFF%TYPE
				) RETURN VARCHAR2;


-- DEVUELDE EL PSU DEL ALUMNO SEGUN EL CODIGO DE PSU
function f_get_PSU(
				p_pidm					sortest.sortest_pidm%type,
				p_code					sortest.sortest_tesc_code%type
				) RETURN VARCHAR2;

-- FUNCION QUE REGRESA EL RTYP DEL ALUMNO SEGUN SU PERIODO
FUNCTION f_get_rtyp_alumn(
		p_pidm		SGBSTDN.SGBSTDN_PIDM%TYPE,
		p_term		SWVTAVI.SWVTAVI_TERM_CODE%TYPE
		) RETURN VARCHAR2;

--Función para obtener el periodo de ingreso del alumno
FUNCTION f_PeriodoIngreso (
        pnPidm      SGBSTDN.SGBSTDN_PIDM%TYPE,
        pnPeriodo   SGBSTDN.SGBSTDN_TERM_CODE_EFF%TYPE
        ) RETURN CHAR;

FUNCTION f_get_val_PSU(
	pnPidm				NUMBER
	,psPerio			VARCHAR2
) RETURN VARCHAR2;

END pk_AdMat;
/


DROP PUBLIC SYNONYM PK_ADMAT;

CREATE PUBLIC SYNONYM PK_ADMAT FOR BANINST1.PK_ADMAT;


GRANT EXECUTE ON BANINST1.PK_ADMAT TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PK_ADMAT TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PK_ADMAT TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PK_ADMAT TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ADMAT TO WWW2_USER;

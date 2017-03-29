DROP PACKAGE BODY BANINST1.PK_ADMAT;

CREATE OR REPLACE PACKAGE BODY BANINST1.pk_AdMat IS
/******************************************************************************
PAQUETE:			BANINST1.pk_AdMat
OBJETIVO:			Contiene los procedimientos, funciones y variables
					de uso comun para los procesos intermedios entre Admisiones
					y Matr¿cula.
AUTORES:			Eduardo Antonio Moreno Macal
					Guillermo Almazan Iba¿ez
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
VALOR DE RETORNO:	Numero de cupos. En caso de no existir la configuraci¿n
					en la tabla SWBCUNI, regresa cero.
******************************************************************************/
FUNCTION f_CupoDisponible(
	psPerio				VARCHAR2
	,psProg				VARCHAR2
	,psTipoIng			VARCHAR2
) RETURN NUMBER IS
	--Variable para guardar el cupo total
	vnCupo				PLS_INTEGER;
	--Variable para guardar el numero de contratos cerrados
	--para el tipo de ingreso, programa y periodo
	vnNumCntr			PLS_INTEGER;
	--Variable para ver si devolvio datos el
	--cursor de cupos
	vbFound				BOOLEAN;

	--Cursor para obtener el cupo total
	CURSOR cuCupo(
		psPerio				VARCHAR2
		,psProg				VARCHAR2
		,psTipoIng			VARCHAR2
	) IS
		SELECT
			SWBCUNI_ENRL_NUM		AS Cupo
		FROM
			SWBCUNI
		WHERE
			SWBCUNI_TERM_CODE = psPerio
			AND SWBCUNI_PROGRAM = psProg
			AND SWBCUNI_RTYP_CODE = psTipoIng;

	--Cursor para obtener el total de contratos que coincidan
	CURSOR cuNumCntr (
		psPerio				VARCHAR2
		,psProg				VARCHAR2
		,psTipoIng			VARCHAR2
	) IS
		SELECT
			COUNT(*)
		FROM
			TWBCNTR
		WHERE
			TWBCNTR_TERM_CODE = psPerio
			AND TWBCNTR_ORI_PROGRAM = psProg
			AND TWBCNTR_RTYP_CODE = psTipoIng
			AND TWBCNTR_STATUS_IND <> 'C'
			AND NOT EXISTS(
				SELECT
					1
				FROM
					TWBRETR
				WHERE
					TWBRETR_CNTR_NUM = TWBCNTR_NUM
			);
BEGIN

	--Abro el cursor de cupos
	OPEN cuCupo(psPerio, psProg, psTipoIng);
	FETCH cuCupo INTO vnCupo;
	vbFound := cuCupo%FOUND;
	CLOSE cuCupo;

	--Si no se encontr¿ el renglo de configuraci¿n pus no hay cupos
	IF NOT vbFound THEN RETURN 0; END IF;

	--Ahora si sigo aqui es que si hay cupos, obtengo el numero de contratos
	--que cumplen la condicion
	OPEN cuNumCntr(psPerio, psProg, psTipoIng);
	FETCH cuNumCntr INTO vnNumCntr;
	CLOSE cuNumCntr;

	--el cursor de numero de contratos siempre devuelve un valor por lo que
	--solo me queda devolver la resta
	RETURN vnCupo - vnNumCntr;

END f_CupoDisponible;


-- DEVUELVE EL PSU PONDERADO DEL ALUMNO
function f_get_PSU_pond(
				p_pidm					SGBSTDN.sgbstdn_pidm%TYPE,
				p_term					SGBSTDN.SGBSTDN_TERM_CODE_EFF%TYPE
				) RETURN VARCHAR2 is
	psu sortest.sortest_test_score%type;
begin
	select sortest_test_score
	into psu
	from sortest t1,
		 swbprct,
		 sgbstdn s1
	where sgbstdn_pidm = p_pidm
	  and s1.sgbstdn_term_code_eff =
				(select max(s2.sgbstdn_term_code_eff)
				from sgbstdn s2
				where s1.sgbstdn_pidm = s2.sgbstdn_pidm
				and s2.sgbstdn_term_code_eff <= p_term)
	and s1.sgbstdn_program_1 = swbprct_program
	and swbprct_tesc_code_pond = sortest_tesc_code
	and t1.sortest_pidm = p_pidm
	and t1.sortest_test_date =
				(select max (t2.sortest_test_date)
				from sortest t2
				where t2.sortest_pidm = t1.sortest_pidm
				and t2.sortest_tesc_code = t1.sortest_tesc_code)
	and rownum = 1;
	return psu;
EXCEPTION
	WHEN no_data_found THEN
		psu := NULL;
		RETURN psu;
end f_get_PSU_pond;

-- DEVUELDE EL PSU DEL ALUMNO SEGUN EL CODIGO DE PSU
function f_get_PSU(
				p_pidm					sortest.sortest_pidm%type,
				p_code					sortest.sortest_tesc_code%type
				) RETURN VARCHAR2 is
	psu sortest.sortest_test_score%type;
begin
	select sortest_test_score
	into psu
	from sortest t1
	where t1.sortest_pidm = p_pidm
	and t1.sortest_tesc_code = p_code
	and t1.sortest_test_date = (select max (t2.sortest_test_date)
								from sortest t2
								where t2.sortest_pidm = t1.sortest_pidm
								and t2.sortest_tesc_code = t1.sortest_tesc_code)
	and rownum = 1;
	return psu;
EXCEPTION
	WHEN no_data_found THEN
		psu := NULL;
		RETURN psu;
end f_get_PSU;

-- FUNCION QUE REGRESA EL RTYP DEL ALUMNO SEGUN SU PERIODO
FUNCTION f_get_rtyp_alumn(
		p_pidm		SGBSTDN.SGBSTDN_PIDM%TYPE,
		p_term		SWVTAVI.SWVTAVI_TERM_CODE%TYPE
		) RETURN VARCHAR2 IS
-- DECLARACION DE VARIABLES LOCALES
vvRtyp		SWVTAVI.SWVTAVI_RTYP_CODE%TYPE;
BEGIN
	-- BUSQUEDA DE INFORMACION DEL ALUMNO
	SELECT SWVTAVI_RTYP_CODE
		INTO vvRtyp
		FROM SGBSTDN S1,
			SWVTAVI S2
		WHERE SWVTAVI_TERM_CODE = p_term
		AND SWVTAVI_ADMT_CODE = SGBSTDN_ADMT_CODE
		AND SGBSTDN_PIDM = p_pidm
		AND SGBSTDN_TERM_CODE_EFF =
				(SELECT MAX(SGBSTDN_TERM_CODE_EFF)
					FROM SGBSTDN
					WHERE SGBSTDN_PIDM = S1.SGBSTDN_PIDM
					AND SGBSTDN_TERM_CODE_EFF <= SWVTAVI_TERM_CODE);
	RETURN vvRtyp;
EXCEPTION
	WHEN no_data_found THEN
		vvRtyp := NULL;
		RETURN vvRtyp;
END f_get_rtyp_alumn;

--Funci¿n para obtener el periodo de ingreso del alumno
function f_PeriodoIngreso (pnPidm sgbstdn.sgbstdn_pidm%type,
                           pnPeriodo sgbstdn.sgbstdn_term_code_eff%type)
return char
is
vsPeriodIng sgbstdn.sgbstdn_term_code_admit%type;
begin
    select sgbstdn_term_code_admit
    into vsPeriodIng
    from sgbstdn g1
    where sgbstdn_pidm = pnPidm
    and g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                    from sgbstdn g2
                                    where g1.sgbstdn_pidm = g2.sgbstdn_pidm
                                      and g2.sgbstdn_term_code_eff <= pnPeriodo);
return vsPeriodIng;

end f_PeriodoIngreso;

FUNCTION f_get_val_PSU(
	pnPidm				NUMBER
	,psPerio			VARCHAR2
) RETURN VARCHAR2 IS

	CURSOR cuPunt(
		pnPidm			VARCHAR2
		,psPerioBase	VARCHAR2
	) IS
		SELECT
			MAX(TO_NUMBER(
				sortest_test_score
				,'999D99'
				,'NLS_NUMERIC_CHARACTERS = '',.'''
			))				Puntaje
		FROM
			SORTEST
		WHERE
			SORTEST_PIDM = pnPidm
			AND SORTEST_TERM_CODE_ENTRY >= psPerioBase
			AND SORTEST_TESC_CODE = 'PPSU';

	vsPerioBase			VARCHAR2(6);
	vnPunt 				NUMBER;

BEGIN

	BEGIN
		vsPerioBase := TO_CHAR( TO_NUMBER(substr(psPerio,1,4))-1 ,'FM9999')||'00';
		OPEN cuPunt(pnPidm,vsPerioBase);
		FETCH cuPunt INTO vnPunt;
		CLOSE cuPunt;
	EXCEPTION WHEN OTHERS THEN
		vnPunt := NULL;
	END;

	RETURN TRIM(TO_CHAR(vnPunt,'999D99'));

END f_get_val_PSU;

END pk_AdMat;
/


DROP PUBLIC SYNONYM PK_ADMAT;

CREATE PUBLIC SYNONYM PK_ADMAT FOR BANINST1.PK_ADMAT;


GRANT EXECUTE ON BANINST1.PK_ADMAT TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PK_ADMAT TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PK_ADMAT TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PK_ADMAT TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_ADMAT TO WWW2_USER;

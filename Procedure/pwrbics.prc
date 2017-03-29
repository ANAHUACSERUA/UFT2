DROP PROCEDURE BANINST1.PWRBICS;

CREATE OR REPLACE PROCEDURE BANINST1.PWRBICS
(
  psReclDesc VARCHAR2
)
AS
/******************************************************************************
PROCEDIMIENTO:		PWRBICP
OBJETIVO:			Reporte Bitacora Carga Postulantes CAE
PARAMETROS:
psReclDesc			Variable estandar para la maquina de reportes custom
AUTOR:				Alejandro Gómez Mondragón
FECHA:				20131205
******************************************************************************/

	--Numero de renglones
	vnRow				PLS_INTEGER := 0;
	--Bandera para mostrar si hubo datos
	vnExists			INTEGER := 0;
	--Numero de columnas
	vnColumnas			INTEGER := 8;
	--Numero de registros
	vnRegs				INTEGER := 0;
	--Arreglo (nested table) donde se guardan los encabezados de las columnas
	tabColumna			Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla();
	-- la variable es una bandera que al tener el valor "imprime" no colocara
	--el salto de página para impresion
	vsInicoPag			VARCHAR2(10) := NULL;
	--Número de renglones por página
	vnRegsPag			PLS_INTEGER := 100;

	--Filtro de Fecha
	vdFecha				DATE;


  CURSOR cuReporte(
		pdFecha			DATE
	) IS
		SELECT
			GWBAACR_NOMBRE_ARCHIVO								AS NomArch
			,GWBAACR_TAMANO										AS Tamano
			,GWBAACR_NUM_REGISTROS								AS NumReg
			,GWBAACR_NUM_PROCESO								AS NumProc
			,GWBAACR_ACTIVITY_DATE								AS Fecha
			,GWBAACR_USER										AS Usuario
			,(SELECT
				COUNT(*)
			FROM
				TWBPCAS
			WHERE
				TWBPCAS_FILE_SEQ = GWBAACR_NUM_PROCESO
			)													AS NumOk
			,(SELECT
				COUNT(*)
			FROM
				TWRCAES
			WHERE
				TWRCAES_FILE_SEQ = GWBAACR_NUM_PROCESO
				AND TWRCAES_LOAD_STAT IN('E', 'e')
			)													AS NumErr
		FROM
			GWBAACR
		WHERE
			GWBAACR_TIPO = 'CAES'
--			AND (pdFecha IS NULL OR (GWBAACR_ACTIVITY_DATE>=pdFecha AND
--				GWBAACR_ACTIVITY_DATE < pdFecha+1))
      AND TO_DATE(GWBAACR_ACTIVITY_DATE, 'DD/MM/YYYY') = TO_DATE(pdFecha, 'DD/MM/YYYY')
		ORDER BY
			GWBAACR_ACTIVITY_DATE;

BEGIN

	--Seguridad de GWAMNUR

  IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

	--Obtengo la fecha del reporte
	vdFecha := TO_DATE(pk_objHtml.getValueCookie('psFecha'),'DD/MM/YYYY');

	-- Redimensiono el arreglo (tabla anidada) de encabezados de columnas
	tabColumna.EXTEND(vnColumnas);

	--Guardamos los encabezados en el arreglo de columnas
	tabColumna( 1) := '<center> Archivo';
	tabColumna( 2) := '<center> Tamaño';
	tabColumna( 3) := '<center> Num. Registros';
	tabColumna( 4) := '<center> Fecha';
	tabColumna( 5) := '<center> Num. Proceso';
	tabColumna( 6) := '<center> Usuario';
	tabColumna( 7) := '<center> Cargados';
	tabColumna( 8) := '<center> Rechazados';

	--Inicializamos contador de renglones
	vnRow := 0;

	FOR regReporte IN cuReporte(vdFecha) LOOP

		--Incremento el contador de renglones
		vnRow := vnRow + 1;
		vnExists := 1; --Bandera para indicar que hubo resultados

		--Si es el primer renglon de cada página...
		IF MOD(vnRow, vnRegsPag) = 1  THEN
			--imprimo el encabezado de reporte
			Pk_Sisrepimp.P_EncabezadoDeReporte(
				psReclDesc ,vnColumnas ,tabColumna
				,vsInicoPag ,'1' ,psUsuario=>pk_login.vgsUSR
			);
			vsInicoPag := 'SALTO';
		END IF;

		--Comienzo a desplegar el renglon
		HTP.P('<tr>');
		HTP.P('<td>'||regReporte.NomArch||'</td>');
		HTP.P('<td>'||regReporte.Tamano||'</td>');
		HTP.P('<td>'||regReporte.NumReg||'</td>');
		HTP.P('<td>'||TO_CHAR(regReporte.Fecha, 'DD/MM/YYYY HH:MI:SS')||'</td>');
		HTP.P('<td>'||regReporte.NumProc||'</td>');
		HTP.P('<td>'||regReporte.Usuario||'</td>');
		HTP.P('<td>'||regReporte.NumOk ||'</td>');
		HTP.P('<td>'||regReporte.NumErr ||'</td>');
		--Fin del renglon
		HTP.P('</tr>');

	END LOOP;

	IF vnExists = 0 THEN
		--Ojo esta linea lo que hace es imprimir
		--NO SE ENCONTRARON DATOS o un mensaje similar
		htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
	ELSE

		-- la variable es una bandera que al tener el valor "imprime" no colocara el salto de p¿gina para impresion
		Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

		-- es omitido el encabezado del reporte pero se agrega el salto de pagina
		Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
	END IF;

	--Fin de la pagina
	htp.p('</table><br/></body></html>');
EXCEPTION
	WHEN OTHERS THEN
		--pantallazo de error.
		pk_ObjHTML.p_ReporteError(sqlcode,replace(sqlerrm,'"','\"'),
			'PWRCRMG', NULL);
END PWRBICS;
/


DROP PUBLIC SYNONYM PWRBICS;

CREATE PUBLIC SYNONYM PWRBICS FOR BANINST1.PWRBICS;


GRANT EXECUTE ON BANINST1.PWRBICS TO WWW2_USER;

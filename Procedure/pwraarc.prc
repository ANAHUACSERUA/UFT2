DROP PROCEDURE BANINST1.PWRAARC;

CREATE OR REPLACE PROCEDURE BANINST1.PWRAARC (
    psReclDesc            VARCHAR2
) IS
/******************************************************************************
PROCEDIMIENTO:        PWRAARC
OBJETIVO:            Reporte de Alumnos para Análisis Rechazados CAE
PARAMETROS:
psReclDesc            Variable estandar para la maquina de reportes custom
AUTOR:                Alejandro Gómez Mondragón
FECHA:                20131220
******************************************************************************/

    --Numero de renglones
    vnRow                PLS_INTEGER := 0;
    --Bandera para mostrar si hubo datos
    vnExists            INTEGER := 0;
    --Numero de columnas
    vnColumnas            INTEGER := 7;
    --Numero de registros
    vnRegs                INTEGER := 0;
    --Arreglo (nested table) donde se guardan los encabezados de las columnas
    tabColumna            Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla();
    -- la variable es una bandera que al tener el valor "imprime" no colocara
    --el salto de página para impresion
    vsInicoPag            VARCHAR2(10) := NULL;
    --Número de renglones por página
    vnRegsPag            PLS_INTEGER := 4000;

    --Filtro de numero de carga
    vnNumProc            NUMBER;
    --Filtro de tipo de dato
    vsTipo                VARCHAR2(1);

    CURSOR cuReporte(
        pnNumProc        NUMBER
        ,psTipo            VARCHAR2
    ) IS
        SELECT distinct
          SPRIDEN_ID                                                      ID,
          SPRIDEN_FIRST_NAME                                              Nombres,
          SPRIDEN_LAST_NAME                                               Apellidos,
          PE.SPBPERS_NAME_SUFFIX                                          RUT,
          SG.SGBSTDN_TERM_CODE_ADMIT                                      Periodo_admision,
          TWRCAES_STATUS_CODE                                             Estatus,
          (SELECT (TWVCAES_DESCRIPTION) FROM TWVCAES
            WHERE TWVCAES_CODE = TWRCAES_STATUS_CODE)                     descripcion
        FROM SPRIDEN SP, SPBPERS PE, SGBSTDN SG, TWRCAES
          WHERE SPBPERS_NAME_SUFFIX = TWRCAES_RUT||'-'||TWRCAES_RUT_DV
          AND SPRIDEN_CHANGE_IND IS NULL
          AND TWRCAES_STATUS_CODE <> 'PS'
          AND SP.SPRIDEN_PIDM = PE.SPBPERS_PIDM
          AND SP.SPRIDEN_PIDM = SG.SGBSTDN_PIDM
          AND SG.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF) FROM SGBSTDN B
                                              WHERE SG.SGBSTDN_PIDM = B.SGBSTDN_PIDM);

BEGIN
    --Seguridad de GWAMNUR
    IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

    --Obtengo el numero de proceso
    vnNumProc := pk_objHtml.getValueCookie('psNum');
    --Obtengo el tipo de registro
    vsTipo := pk_objHtml.getValueCookie('psRgRes');

    -- Redimensiono el arreglo (tabla anidada) de encabezados de columnas
    tabColumna.EXTEND(vnColumnas);

    --Guardamos los encabezados en el arreglo de columnas
    tabColumna( 1) := '<center> ID';
    tabColumna( 2) := '<center> Nombres';
    tabColumna( 3) := '<center> Apellidos';
    tabColumna( 4) := '<center> RUT';
    tabColumna( 5) := '<center> Período de Admisión';
    tabColumna( 6) := '<center> Estatus';
    tabColumna( 7) := '<center> Descripción';

    --Inicializamos contador de renglones
    vnRow := 0;

    FOR regReporte IN cuReporte(vnNumProc,vsTipo) LOOP

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
        HTP.P('<td>'||regReporte.ID||'</td>');
        HTP.P('<td>'||regReporte.Nombres||'</td>');
        HTP.P('<td>'||regReporte.Apellidos||'</td>');
        HTP.P('<td>'||regReporte.RUT||'</td>');
        HTP.P('<td>'||regReporte.Periodo_admision||'</td>');
        HTP.P('<td>'||regReporte.Estatus||'</td>');
        HTP.P('<td>'||regReporte.descripcion||'</td>');
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
            'PWRAARC', NULL);
END PWRAARC;
/


DROP PUBLIC SYNONYM PWRAARC;

CREATE PUBLIC SYNONYM PWRAARC FOR BANINST1.PWRAARC;


GRANT EXECUTE ON BANINST1.PWRAARC TO WWW2_USER;

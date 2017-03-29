DROP PROCEDURE BANINST1.PWRARPC;

CREATE OR REPLACE PROCEDURE BANINST1.PWRARPC (
    psReclDesc            VARCHAR2
) IS
/******************************************************************************
PROCEDIMIENTO:        PWRARPC
OBJETIVO:            Reporte de Alumnos Respaldados para Carga
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
    vnColumnas            INTEGER := 4;
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
        SELECT
            SWRRCRM_NUM_LINEA                        AS NumLinea
            ,SWRRCRM_CONTENIDO                        AS Contenido
            ,SWRRCRM_RESULTADO                        AS Resultado
            ,SWRRCRM_MENSAJE                        AS Mensaje
        FROM
            SWRRCRM
        WHERE
            SWRRCRM_NUM_PROCESO = pnNumProc
            AND (
                psTipo = 'T'
                OR (psTipo = 'N' AND SWRRCRM_RESULTADO IN ('W','R','E') )
                  OR (SWRRCRM_RESULTADO = psTipo)
            )
        ORDER BY
            SWRRCRM_NUM_LINEA;

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
    tabColumna( 1) := '#';
    tabColumna( 2) := 'Contenido';
    tabColumna( 3) := 'Resultado';
    tabColumna( 4) := 'Comentario';

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
        HTP.P('<td>'||regReporte.NumLinea||'</td>');
        HTP.P('<td>'||regReporte.Contenido||'</td>');
        HTP.P('<td>'||regReporte.Resultado||'</td>');
        HTP.P('<td>'||regReporte.Mensaje||'</td>');
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
            'PWRARPC', NULL);
END PWRARPC;
/


DROP PUBLIC SYNONYM PWRARPC;

CREATE PUBLIC SYNONYM PWRARPC FOR BANINST1.PWRARPC;


GRANT EXECUTE ON BANINST1.PWRARPC TO WWW2_USER;

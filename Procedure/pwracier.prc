DROP PROCEDURE BANINST1.PWRACIER;

CREATE OR REPLACE PROCEDURE BANINST1.PWRACIER (
    psReclDesc            VARCHAR2
) IS
/******************************************************************************
PROCEDIMIENTO:        PWRACIER
OBJETIVO:            Cierre de Semestre
PARAMETROS:
psReclDesc            Variable estandar para la maquina de reportes custom
AUTOR:               Alejandra Munguía --- se le agregan columnas y parametros al reporte original
FECHA:                20120912
******************************************************************************/
    --Numero de renglones
    vnRow                PLS_INTEGER := 0;
    --Bandera para mostrar si hubo datos
    vnExists            INTEGER := 0;
    --Numero de columnas
    vnColumnas            INTEGER := 18;
    --Numero de registros
    vnRegs                INTEGER := 0;
    --Arreglo (nested table) donde se guardan los encabezados de las columnas
    tabColumna            Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla();
    -- la variable es una bandera que al tener el valor "imprime" no colocara
    --el salto de página para impresion
    vsInicoPag            VARCHAR2(10) := NULL;
    --Número de renglones por página
    vnRegsPag            PLS_INTEGER := 25;
    --Variable para guardar el periodo deseado
    vsPerio                STVTERM.STVTERM_CODE%TYPE;
    --Variable para guardar EL PROGRAMA DESEADO
    vsProg                SMRPRLE.SMRPRLE_PROGRAM%TYPE;
    --Variable para guardar el total de matriculados del dia
    vnTotalDia            PLS_INTEGER;
    --Fecha del reporte
    vdFecha                DATE;
    -- Indicador de la escuela
    vsEscu               VARCHAR2(5);

    CURSOR cuReporte(
        psPerio            VARCHAR2
        ,psProgr           VARCHAR2
        ,psEscu             VARCHAR2
     ) IS
            SELECT  DISTINCT S1.SGBSTDN_PROGRAM_1                    CARRERA,
                            S1.SGBSTDN_MAJR_CODE_1                MALLA,
                            S1.SGBSTDN_TERM_CODE_ADMIT      PERIODO_ADMISION,
                            (SELECT SMRPRLE_PROGRAM FROM SMRPRLE
                            WHERE SMRPRLE_PROGRAM = S1.SGBSTDN_PROGRAM_1)           DESCRIPCION_CARRERA,
                            SPBPERS_NAME_SUFFIX                    RUT,
                            SPRIDEN_ID                                          ID,
                            S1.SGBSTDN_PIDM                                 PIDM,
                            S1.SGBSTDN_LEVL_CODE                          NIVEL,
                            SPRIDEN_FIRST_NAME||' '||SPRIDEN_LAST_NAME    NOMBRE_APELLIDOS,
                            NVL(S3.SGBUSER_SUDC_CODE,0)           RAMOS_REPROB_HA,
                            NVL(S3.SGBUSER_SUDD_CODE,0)           OPORT_UTIL_HA,
                            NVL(S3.SGBUSER_SUDE_CODE,0)           AVANC_CRED_TOT,
                            NVL(S3.SGBUSER_SUDA_CODE,0)           ULT_SEM_A_COMP_ACR,
                           NVL( S3.SGBUSER_SUDF_CODE,0)           RANKING,
                            NVL(S3.SGBUSER_SUDG_CODE,0)           PERIOD_CONSEC_REP,
                               NVL (
                     (SELECT ROUND(SHRTGPA_GPA,2)
                        FROM SHRTGPA
                       WHERE     SHRTGPA_PIDM = S1.SGBSTDN_PIDM
                             AND SHRTGPA_LEVL_CODE = S1.SGBSTDN_LEVL_CODE
                             AND SHRTGPA_TERM_CODE = psPerio),
                     0)
                     PPA,
                            NVL(S3.SGBUSER_SUDH_CODE,0)           ASIG_ACRED_PER_ACT,
                             (SELECT DECODE (COUNT (1), 0, 0, COUNT (1))
           FROM SFRSTCR
          WHERE     SFRSTCR_PIDM = S1.SGBSTDN_PIDM
                AND SFRSTCR_TERM_CODE = psPerio
                AND SFRSTCR_RSTS_CODE IN ('RE', 'RW'))AIP,
                            S3.SGBUSER_SUDI_CODE               ASIG_ACRED_ACUM_HIS,
                  (SELECT DECODE(TBBESTU_PIDM, NULL,' ','X')
              FROM TBBESTU
             WHERE TBBESTU_PIDM = S1.SGBSTDN_PIDM
                   AND TBBESTU_TERM_CODE = psPerio
                   and rownum= 1) BECA
              FROM SPRIDEN,
                           SGBSTDN S1,
                           SPBPERS,
                           SGBUSER S3
             WHERE SPRIDEN_PIDM = S1.SGBSTDN_PIDM
                  AND SPRIDEN_CHANGE_IND IS NULL
                  AND SGBSTDN_PIDM = S3.SGBUSER_PIDM
                  AND S1.SGBSTDN_PIDM = SPBPERS_PIDM
                  AND (S3.SGBUSER_TERM_CODE = psPerio OR psPerio IS NULL)
                  AND (S1.SGBSTDN_PROGRAM_1 = psProgr OR psProgr IS NULL)
--                  AND EXISTS (SELECT 1 FROM SWRCIRR
--                                        WHERE SWRCIRR_PIDM = S3.SGBUSER_PIDM)
                  AND S1.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(S2.SGBSTDN_TERM_CODE_EFF)
                                                                                          FROM SGBSTDN S2
                                                                                        WHERE S1.SGBSTDN_PIDM = S2.SGBSTDN_PIDM
                                                                                        )
                  AND s1.SGBSTDN_COLL_CODE_1=nvl(psEscu,s1.SGBSTDN_COLL_CODE_1)
               ORDER BY S1.SGBSTDN_MAJR_CODE_1, S1.SGBSTDN_LEVL_CODE, S1.SGBSTDN_PROGRAM_1;

BEGIN

    --Seguridad de GWAMNUR
    IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
--HTP.P('PARAMETROS ');
    --Obtengo el numero de corte que se desea para el usuario dado
    vsPerio := pk_objHtml.getValueCookie('psPerio');
--vsPerio := '201175';
    --Obtengo de las cookies el valor fechas de corte de caja
    vsProg := pk_objHtml.getValueCookie('psProgr');
    vsEscu := pk_objHtml.getValueCookie('psEscu');
    --Obtenemos la fecha
    vdFecha := NVL(TO_DATE(pk_objHtml.getValueCookie('psFecha'),'DD/MM/YYYY'),SYSDATE);

 --HTP.P('PARAMETROS periodo:'||vsPerio||' prog:'||vsProg||' IndSem:'||vsIndSem||' Fecha:'||vdFecha);
--HTP.P('PARAMETROS'||vnRetractosDia||'-'||vnRetractosAcum||'-'||);

    -- Redimensiono el arreglo (tabla anidada) de encabezados de columnas
    tabColumna.EXTEND(vnColumnas);

    --Guardamos los encabezados en el arreglo de columnas
    tabColumna( 1) := 'Carrera';
    tabColumna( 2) := 'Malla';
    tabColumna( 3) := 'Periodo de Admision';
    tabColumna( 4) := 'Descripción de la Carrera';
    tabColumna( 5) := 'RUT';
    tabColumna( 6) := 'ID';
    tabColumna( 7) := 'Nombre';
    tabColumna( 8) := 'Ramos Reprobados en la Historia Academica';
    tabColumna(9) := 'Oportunidades Utilizadas en la Historia Academica';
    tabColumna(10) := '% de Avance Respecto a los Creditos Totales';
    tabColumna(11) := 'Ultimo Semestre o Año Completo Acreditado';
    tabColumna(12) := 'Ranking';
    tabColumna(13) := 'Periodos Consecutivos Reprobados';
    tabColumna(14) := 'Promedio del Periodo Actual';
    tabColumna(15) := 'Asignaturas Acreditadas en el Periodo Actual';
    tabColumna(16) := 'Asignaturas Inscritas en el Periodo';
    tabColumna(17) := '% Asignaturas Acreditadas Acumuladas en el Historial';
    tabColumna(18) := 'Beca';

    --Inicializamos contador de renglones
    vnRow := 0;

     FOR regReporte IN cuReporte(vsPerio, vsProg,vsEscu) LOOP

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

        HTP.P('<td>'||regReporte.CARRERA||'</td>');
        HTP.P('<td>'||regReporte.MALLA||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.PERIODO_ADMISION ||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.DESCRIPCION_CARRERA ||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.RUT ||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.ID ||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.NOMBRE_APELLIDOS ||'</td>');
        HTP.P(
            '<td valign="top"><a  href="#" ><font title="Informacion de SUB y CRSE y PERIODO');

--        htp.p(regReporte.pidm||''|| regReporte.Nivel||vsPerio);
         --P_DetToolTip (pnPidm NUMBER, psLevel VARCHAR, psTerm VARCHAR2);
         KWACIERRE.P_DetToolTip (regReporte.pidm, regReporte.Nivel, vsPerio);

        HTP.P('<td style="text-align:left;">'||regReporte.RAMOS_REPROB_HA||'</td>');
        HTP.
          p (
            '<td valign="top"><a  href="#" ><font title="Informacion de SUB y CRSE y PERIODO');
         KWACIERRE.P_DetToolTipA (regReporte.pidm, regReporte.Nivel, vsPerio);
         htp.p('hola'||regReporte.pidm);
         htp.p(regReporte.nivel);
         htp.p(vsPerio);
        HTP.P('<td style="text-align:left;">'||regReporte.OPORT_UTIL_HA||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.AVANC_CRED_TOT||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.ULT_SEM_A_COMP_ACR||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.RANKING||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.PERIOD_CONSEC_REP||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.PPA||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.ASIG_ACRED_PER_ACT||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.AIP||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.ASIG_ACRED_ACUM_HIS||'</td>');
        HTP.P('<td style="text-align:left;">'||regReporte.BECA||'</td>');
        --Fin del renglon
        HTP.P('</tr>');

     END LOOP;



    IF vnExists = 0 THEN
        --Ojo esta linea lo que hace es imprimir
        --NO SE ENCONTRARON DATOS o un mensaje similar
        htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
    ELSE

        -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
        Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

        -- es omitido el encabezado del reporte pero se agrega el salto de pagina
        Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
    END IF;

    --Fin de la pagina
    htp.p('</table><br/></body></html>');
EXCEPTION
    WHEN OTHERS THEN
        --pantallazo de error.

        htp.p(SQLERRM);

END PWRACIER;
/


DROP PUBLIC SYNONYM PWRACIER;

CREATE PUBLIC SYNONYM PWRACIER FOR BANINST1.PWRACIER;


GRANT EXECUTE ON BANINST1.PWRACIER TO WWW2_USER;

CREATE OR REPLACE PROCEDURE BANINST1.PWRBFUA(psReclDesc   VARCHAR2) IS

/******************************************************************************
   NAME:       PWRBFUA
   pURPOSE:    reporte de bitacora posterior a la regla del POSTERIOR A LA EJECUCION REGLA DEL 70% 
              (Bitacora FUAS)

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23 / jul /2014  ROMAN RUIZ   Bitacora Fuas   


******************************************************************************/
    --Numero de renglones
    vnRow                PLS_INTEGER := 0;
    --Bandera para mostrar si hubo datos
    vnExists            INTEGER := 0;
    --Numero de columnas
    vnColumnas            INTEGER := 8;
    --Numero de registros
    vnRegs                INTEGER := 0;
    --Arreglo (nested table) donde se guardan los encabezados de las columnas
    tabColumna            Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla();
    -- la variable es una bandera que al tener el valor "imprime" no colocara
    --el salto de página para impresion
    vsInicoPag            VARCHAR2(10) := NULL;
    --Número de renglones por página
    vnRegsPag            PLS_INTEGER := 100;
    --Filtro de Fecha
    vdFecha                DATE;
    --Período de busqueda
    vsPeriodo VARCHAR2(30) := NULL;    
    vsAnio    varchar2(4); 

    CURSOR cuReporte( psPerio VARCHAR2  DEFAULT NULL  ) IS
           select a.TWRCAES_YEAR                        anio
             , a.TWRCAES_RUT || '-' || a.TWRCAES_RUT_DV RUT
             , f_get_id(a.TWRCAES_PIDM)                 ID      
             --, SPBPERS_LEGAL_NAME                        nombre
             , SPRIDEN_FIRST_NAME || ' ' || replace(SPRIDEN_LAST_NAME, '*',' ')  nombre
             , (select TWVCAES_DESCRIPTION 
               from twvcaes 
               where TWVCAES_CODE = a.TWRCAES_STATUS_UNI)  Stat_Gral
             , a.TWRCAES_LOAD_ERROR                        Stat_proc_Cae
             , s.SGBSTDN_STST_CODE                         Stat_alumno
             , f_get_id(SPBPERS_PIDM)                      std_id
          from TWRCAES a , spbpers,  SGBSTDN s, spriden
          where a.TWRCAES_YEAR = vsAnio
          and   a.TWRCAES_TYPE = 'P'
          and   a.TWRCAES_STATUS_CODE IN ( 'R7', 'RE' )
          and   a.TWRCAES_SEQ_NUM = (select max(TWRCAES_SEQ_NUM)
                                     from TWRCAES b
                                     where b.TWRCAES_YEAR = vsAnio
                                     and   b.TWRCAES_RUT  = a.TWRCAES_RUT
                                     and   b.TWRCAES_TYPE = 'P'
                                     and   b.TWRCAES_STATUS_CODE IN ( 'R7', 'RE' ))
          and   a.TWRCAES_RUT || '-' || a.TWRCAES_RUT_DV = SPBPERS_NAME_SUFFIX
          and   a.TWRCAES_PIDM  = SPBPERS_PIDM
          AND   a.TWRCAES_PIDM =  s.SGBSTDN_PIDM
          AND   s.SGBSTDN_TERM_CODE_EFF = ( SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                            FROM SGBSTDN SS
                                            WHERE SS.SGBSTDN_PIDM = s.SGBSTDN_PIDM)
          and SPRIDEN_PIDM = a.TWRCAES_PIDM 
          and SPRIDEN_CHANGE_IND is null  
          ORDER BY a.TWRCAES_YEAR, a.TWRCAES_RUT ;

BEGIN

    --Seguridad de GWAMNUR
    IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

    --Obtengo la fecha del reporte
    vdFecha := TO_DATE(SYSDATE,'DD/MM/YYYY');

   -- obtiene los valores de las cookies para asignar los valores del filtro del query:
   vsPeriodo   := pk_objHtml.getValueCookie('psAño');
   vsAnio      := SUBSTR(vsPeriodo,1,4); 
    
   vsPeriodo   := substr(vsPeriodo,1,4);  --md-01
   
--    htp.p('<br>');
--    htp.p('vsPeriodo:'||vsPeriodo);

    -- Redimensiono el arreglo (tabla anidada) de encabezados de columnas
    tabColumna.EXTEND(vnColumnas);

    --Guardamos los encabezados en el arreglo de columnas

    tabColumna( 1) := '<center> AÑO';  
    tabColumna( 2) := '<center> ID';
    tabColumna( 3) := '<center> RUT';
    --tabColumna( 3) := '<center> ID';
    tabColumna( 4) := '<center> Nombre';
    tabColumna( 5) := '<center> Status General';
    tabColumna( 6) := '<center> Status Proceso CAE';
    tabColumna( 7) := '<center> Status Alumno ';  
--    tabColumna( 8) := 'No Cargados';

    --Inicializamos contador de renglones
    vnRow := 0;

    FOR regReporte IN cuReporte(vsPeriodo) LOOP

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
        HTP.P('<td align=center>'||regReporte.anio||'</td>');
        HTP.P('<td align=center>'||regReporte.std_id||'</td>');
        HTP.P('<td align=center>'||regReporte.RUT||'</td>');
        HTP.P('<td>'||regReporte.nombre||'</td>');
        HTP.P('<td>'||regReporte.Stat_Gral||'</td>');
        HTP.P('<td>'||regReporte.Stat_proc_Cae||'</td>');
        HTP.P('<td>'||regReporte.Stat_alumno||'</td>');
        --Fin del renglon
        HTP.P('</tr>');

    END LOOP;

    IF vnExists = 0 THEN
        --NO SE ENCONTRARON DATOS 
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
             WHEN NO_DATA_FOUND THEN
               NULL;
             WHEN OTHERS THEN
               -- Consider logging the error and then re-raise
               RAISE;
END PWRBFUA;
/
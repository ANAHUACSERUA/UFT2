CREATE OR REPLACE PROCEDURE BANINST1.PWRBFINH(psReclDesc   VARCHAR2) IS
-----reporte  balance final historico

--modify by glovicx_--- 29-oct-2014
--  se crea este nuevo reporte igual al de balance final solo que con nuevos filtros 
--  para alumnos de los años 2010,2011,2012



  -- declaración de variables:
  vnExists       INTEGER      := 0;
  vnColumnas     INTEGER      := 35;
  vgsInicioPag   VARCHAR2(30) := NULL;         -- bandera que al tener el valor "imprime" no colocará el salto de página para impresión
  vnIdRenglon    INTEGER      := 1;
  tabColumna     Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla(1);

  vsTerm         SARAPPD.SARAPPD_TERM_CODE_ENTRY%TYPE DEFAULT NULL;
  vsProgr        SARADAP.SARADAP_PROGRAM_1%TYPE       DEFAULT NULL;
  vsPropsu_ant          VARCHAR2(50) := NULL;
  vsPropsu_act          VARCHAR2(50) := NULL;
  vnTermAnt             VARCHAR2(6) := NULL;
  vnTermAct             VARCHAR2(6) := NULL;
  vnAnoEje                VARCHAR2(4) := NULL;
  vsnivel1                   VARCHAR2(4) := NULL;
--
csSlh       varchar2(1):= '/';
vsnivel    varchar2(50);


  -- obtiene la información de los alumnos:
CURSOR cuReporte ( psTerm    VARCHAR2  DEFAULT NULL,
                              psProgr   VARCHAR2  DEFAULT NULL,
                              psnivel    varchar2     ) IS
SELECT DISTINCT   F_GET_RUT(a.sgbstdn_PIDM)                                       RUT,
            SPRIDEN_ID                                                                                 ID,
            UPPER(REPLACE(REPLACE(SPRIDEN_LAST_NAME, '*', ' '), '  ', ' ' ))                           APELLIDOS,
            UPPER(REPLACE(REPLACE(SPRIDEN_FIRST_NAME||' '||SPRIDEN_MI,'   ', ' '), '  ', ' '))        NOMBRE,
           (SELECT SPRADDR_CNTY_CODE||' '||STVCNTY_DESC FROM SPRADDR, STVCNTY
            WHERE SPRADDR_ATYP_CODE = 'PR'
            AND SPRADDR_CNTY_CODE = STVCNTY_CODE
            AND SPRADDR_PIDM = A.SGBSTDN_PIDM
            AND ROWNUM = 1)                                                                             COMUNA_RESIDENCIA,
            (SELECT SPRADDR_STAT_CODE||' '||STVSTAT_DESC FROM SPRADDR, STVSTAT
            WHERE SPRADDR_ATYP_CODE = 'PR'
            AND SPRADDR_STAT_CODE = STVSTAT_CODE
            AND SPRADDR_PIDM = A.SGBSTDN_PIDM
            AND ROWNUM = 1)                                                                              REGION_RESIDENCIA,
            A.SGBSTDN_PROGRAM_1                                                                           PROGRAMA,
              A.SGBSTDN_STST_CODE                                                                         STATUS,
            (SELECT STVSTST_DESC FROM STVSTST
             WHERE STVSTST_CODE=A.SGBSTDN_STST_CODE)                                                       DESC_STATUS,
              (SELECT X.SARADAP_ADMT_CODE FROM SARADAP X, sarappd Y
            WHERE X.SARADAP_PIDM = A.SGBSTDN_PIDM
            and x.saradap_pidm = y.sarappd_pidm
            and x.saradap_appl_no = sarappd_appl_no
            and SARAPPD_APDC_CODE in ('CO','IN','C2')
            AND X.SARADAP_TERM_CODE_ENTRY = A.SGBSTDN_TERM_CODE_ADMIT
            AND X.SARADAP_PROGRAM_1 = A.SGBSTDN_PROGRAM_1
                                    AND ROWNUM=1)                                                       TIPO_ADMISION,
             (SELECT STVADMT_DESC  FROM STVADMT
             WHERE STVADMT_CODE = SGBSTDN_ADMT_CODE) DESC_TIPO_ADMISION,
            SWVTAVI_RTYP_CODE                                                                           VIA,
            (SELECT STVRTYP_DESC FROM STVRTYP
            WHERE STVRTYP_CODE =SWVTAVI_RTYP_CODE)                                                    DESC_VIA_INGRESO,
             SARADAP_APPL_PREFERENCE                                                      PREFERENCIA,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PEM',1,psTerm,null)                    PEM,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'NEME',1,psTerm,null)                  NEME,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSCI',1,psTerm,null)                   PSCI_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSHC',1,psTerm,null)                  PSHC_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSLC',1,psTerm,null)                   PSLC_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSMA',1,psTerm,null)                  PSMA_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PRAN',1,psTerm,null)                  PRAN_ACTUAL,  
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PETE',1,psTerm,null)                  PETE_ACTUAL,    
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PPSU',1,psTerm,null)                   PPSU_ACTUAL,   
            F_PONDERADOS (A.SGBSTDN_PIDM, A.SGBSTDN_PROGRAM_1,1,psTerm,null)             PONDERADO_UFT_ACTUAL,
           (  SELECT  substr(SORTEST_TERM_CODE_ENTRY,1,4)
                 FROM SORTEST
                  WHERE  SORTEST_PIDM = A.SGBSTDN_PIDM
                          AND SORTEST_TERM_CODE_ENTRY= psterm
                   and rownum=1)                                                              AÑOA,
        F_GET_SEXO(A.SGBSTDN_PIDM)                                                                    SEXO,
             (select  (SORHSCH_SBGI_CODE)
             from SORHSCH
             where SORHSCH_PIDM=A.SGBSTDN_PIDM
                and rownum=1)                                                            CODIGO_COLEGIO,
              (select UPPER(PK_CATALOGO.PREPARATORIA (SORHSCH_SBGI_CODE))
             from SORHSCH
             where SORHSCH_PIDM=A.SGBSTDN_PIDM
              and rownum=1)                                                             COLEGIO,
              (select SOBSBGI_STAT_CODE
             from SORHSCH,SOBSBGI
             where SORHSCH_PIDM =A.SGBSTDN_PIDM
              and SORHSCH_SBGI_CODE=SOBSBGI_SBGI_CODE
              and rownum=1)                                                            REGION_COL,
             (select SOBSBGI_CNTY_CODE
             from SORHSCH,SOBSBGI
             where SORHSCH_PIDM =A.SGBSTDN_PIDM
              and SORHSCH_SBGI_CODE=SOBSBGI_SBGI_CODE
              and rownum=1)                                                           COMUNA_COL,
              (select  (SORBCHR_BCHR_CODE)
             from SORHSCH,SORBCHR
             where SORHSCH_PIDM=A.SGBSTDN_PIDM
             AND SORBCHR_SBGI_CODE = SORHSCH_SBGI_CODE
             AND ROWNUM =1)                                                           CODIGO_DEPENDENCIA,
             (select  STVBCHR_DESC FROM
             SORHSCH,SORBCHR, STVBCHR
             where SORHSCH_PIDM=A.SGBSTDN_PIDM
             AND SORBCHR_SBGI_CODE = SORHSCH_SBGI_CODE
             AND SORBCHR_BCHR_CODE = STVBCHR_CODE
             AND ROWNUM =1)                                                         DESC_DEPENDENCIA
 FROM  SPRIDEN
       ,SARADAP d
       ,SGBSTDN A
       ,SWVTAVI
    WHERE SPRIDEN_CHANGE_IND IS NULL
     AND SARADAP_PIDM = SPRIDEN_PIDM
     and SARADAP_PIDM = sgbstdn_PIDM
    -- and SARADAP_TERM_CODE_ENTRY  =  SGBSTDN_TERM_CODE_ADMIT
     --and  substr(SARADAP_TERM_CODE_ENTRY,1,4)   in (2010,2011,2012)
     and  substr(SARADAP_TERM_CODE_ENTRY,1,4)   = SUBSTR(psterm, 1,4)
     AND SWVTAVI_ADMT_CODE = SGBSTDN_ADMT_CODE
     AND SWVTAVI_RTYP_CODE IN ('AR', 'AE','AC')
     and  A.SGBSTDN_TERM_CODE_EFF  = ( select   max(SGBSTDN_TERM_CODE_EFF ) from sgbstdn s2  
                                            where    s2.SGBSTDN_TERM_CODE_EFF <= psterm
                                              and     s2.sgbstdn_pidm =  a.sgbstdn_pidm )
     AND (A.SGBSTDN_PROGRAM_1 = psProgr  or psProgr is null) --programa
     AND (D.SARADAP_PROGRAM_1 = psProgr  or psProgr is null) --programa
      and (instr(csSlh||psnivel, csSlh||A.SGBSTDN_LEVL_CODE||csSlh) > 0 or   psnivel= csSlh  OR  psnivel is null)    --md  vic..
      ;


---------------------------------------------------
-- bloque principal para la generación del reporte
---------------------------------------------------
BEGIN

   -- valida que el usuario tenga acceso a la base de datos:
   IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

   -- obtiene los valores de las cookies para asignar los valores del filtro del query:
   vsTerm  := pk_ObjHtml.getValueCookie('psTerm');
   vsProgr := pk_ObjHtml.getValueCookie('psProg1');
   vsnivel  :=  pk_ObjHtml.getValueCookie('psNivl1');

   -- determina el largo de la tabla:
   FOR vnI IN 1..vnColumnas LOOP
       tabColumna.EXTEND(vnI);
       tabColumna(vnI) := NULL;
   END LOOP;

   -- define los encabezados de las columnas:
   tabColumna(1)  := '<center> RUT';
   tabColumna(2)  := '<center> ID';
   tabColumna(3)  := '<center> Apellidos';
   tabColumna(4)  := '<center> Nombre';
   tabColumna(5)  := '<center> Comuna <br> Residencia';
   tabColumna(6)  := '<center> Regi&oacute;n<br> Residencia';
   tabColumna(7)  := '<center> Programa';
  tabColumna(8)  := '<center> Status';
   tabColumna(9)  := '<center> Descripci&oacute;n<br>Status';
  tabColumna(10) := '<center> Tipo <br> Admisi&oacute;n';
   tabColumna(11) := '<center> Descripci&oacute;n<br> Admisi&oacute;n';
   tabcolumna(12) := '<center> V&iacute;a <br> Admisi&oacute;n';
   tabColumna(13) :='<center> Descripci&oacute;n<br> V&iacute;a Admisi&oacute;n';
   tabColumna(14) := '<center> Preferencia';
   tabColumna(15) := '<center> PEM';
   tabColumna(16) := '<center> NEME';
   tabColumna(17) := '<center> PSCI <br> Actual';
   tabColumna(18) := '<center> PSHC <br> Actual';
   tabColumna(19) := '<center> PSLC <br> Actual';
   tabColumna(20) := '<center> PSMA <br> Actual';
   tabColumna(21) := '<center> PRAN <br> Actual';
   tabColumna(22) := '<center> PETE<br> Actual';
   tabColumna(23) := '<center> PSU<br> Actual';
   tabColumna(24) := '<center> Ponderado <br> Actual';
  tabColumna(25) := '<center> Puntaje Ponderado <br> de Selección';
   tabColumna(26) := '<center> Año Académico <br> de las pruebas';
   tabColumna(27) := '<center> Sexo';
   tabColumna(28) := '<center> C&oacute;digo Colegio';
   tabColumna(29) := '<center> Colegio';
   tabColumna(30) := '<center> Regi&oacute;n';
   tabColumna(31) := '<center> Comuna';
   tabColumna(32) := '<center> Dependencia Colegio';
   tabColumna(33) := '<center> Descipci&oacute;n <br> Dependencia Colegio';

      -- idetermina los parámetros con los cuales obtendrá los puntajes anteriores y actuales

       begin
        select  stvterm_acyr_code
           into  vnAnoEje
        from  stvterm
        where
            stvterm_code=vsTerm;
        exception
        when no_data_found then
            vnAnoEje:=substr(vsTerm,1,4);
        when others then
            vnAnoEje:=substr(vsTerm,1,4);
    end;

   begin
        select  swvcpsu_term_code_previous,swvcpsu_term_code_present
           into  vnTermAnt,vnTermAct
        from  swvcpsu
        where
            swvcpsu_acyr_code=substr(vsTerm, 1,4);
       
   end;

   -- manipula la información obtenida por el cursor:
   FOR regRep IN cuReporte (vsTerm, vsProgr,vsnivel) LOOP

       IF vnExists = 0 THEN

          -- muestra el encabezado según el periodo y programa seleccionados:
          IF vsProgr IS NOT NULL THEN
             Pk_Sisrepimp.p_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, vgsInicioPag, '1',
                                                psSubtitulo   => 'Periodo: &nbsp;'||vsTerm||' - '||Pk_Catalogo.PERIODO(vsTerm)||'<br>'||'Programa: &nbsp;'||vsProgr||' - '||Pk_Catalogo.Programa(vsProgr),
                                                psUniversidad => 'UFT');
             vgsInicioPag := 'SALTO';
          ELSE
             Pk_Sisrepimp.p_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, vgsInicioPag, '1',
                                                psSubtitulo   => 'Periodo: &nbsp;'||vsTerm||' - '||Pk_Catalogo.PERIODO(vsTerm)||'<br>'||'Programa: &nbsp;'||'Todos ',
                                                psUniversidad => 'UFT');
             vgsInicioPag := 'SALTO';
          END IF;

       END IF;

              SELECT
                     CASE
                        WHEN ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ACTUAL,0) , ',', '.')))/2,2) = 0
                           THEN null
                        WHEN ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ACTUAL,0) , ',', '.')))/2,2) <> 0
                          THEN
                              replace(ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ACTUAL,0) , ',', '.')))/2,2),'.',',')
              END
            into vsPropsu_act
       from dual;

       HTP.P('<tr> <td valign="top" align="left">' ||regRep.RUT                          ||'</td>
                   <td valign="top" align="left">'       ||regRep.ID                             ||'</td>
                   <td valign="top" align="left">'       ||regRep.APELLIDOS                  ||'</td>
                   <td valign="top" align="left">'       ||regRep.NOMBRE                     ||'</td>
                   <td valign="top" align="left">'       ||regRep.COMUNA_RESIDENCIA   ||'</td>
                   <td valign="top" align="left">'       ||regRep.REGION_RESIDENCIA      ||'</td>
                   <td valign="top" align="left">'       ||regRep.PROGRAMA                    ||'</td>
                      <td valign="top" align="left">' ||regRep.STATUS                    ||'</td>
                   <td valign="top" align="left">' ||regRep.DESC_STATUS                    ||'</td>
                  <td valign="top" align="left">' ||regRep.TIPO_ADMISION            ||'</td>
                   <td valign="top" align="left">' ||regRep.DESC_TIPO_ADMISION     ||'</td>
                   <td valign="top" align="left">' ||regRep.VIA                               ||'</td>
                   <td valign="top" align="left">' ||regRep.DESC_VIA_INGRESO         ||'</td>
                   <td valign="top" align="left">' ||regRep.PREFERENCIA                  ||'</td>
                   <td valign="top" align="center">' ||regRep.PEM                               ||'</td>
                   <td valign="top" align="center">' ||regRep.NEME                             ||'</td>
                   <td valign="top" align="center">' ||regRep.PSCI_ACTUAL             ||'</td>
                   <td valign="top" align="center">' ||regRep.PSHC_ACTUAL            ||'</td>
                   <td valign="top" align="center">' ||regRep.PSLC_ACTUAL              ||'</td>
                   <td valign="top" align="center">' ||regRep.PSMA_ACTUAL              ||'</td>
                   <td valign="top" align="center">' ||regRep.PRAN_ACTUAL              ||'</td>
                   <td valign="top" align="center">' ||regRep.PETE_ACTUAL             ||'</td>
                    <td valign="top" align="center">' ||regRep.PPSU_ACTUAL                    ||'</td>
                   <td valign="top" align="center">' ||regRep.PONDERADO_UFT_ACTUAL          ||'</td>
                   <td valign="top" align="center">' ||regRep.PPSU_ACTUAL                      ||'</td>
                   <td valign="top" align="center">' ||regRep.AÑOA                          ||'</td>
                   <td valign="top" align="left">'     ||regRep.SEXO                            ||'</td>
                   <td valign="top" align="left">'     ||regRep.CODIGO_COLEGIO          ||'</td>
                   <td valign="top" align="left">'     ||regRep.COLEGIO                       ||'</td>
                   <td valign="top" align="left">'     ||regRep.REGION_COL                  ||'</td>
                   <td valign="top" align="left">'     ||regRep.COMUNA_COL                 ||'</td>
                   <td valign="top" align="left">'     ||regRep.CODIGO_DEPENDENCIA        ||'</td>
                   <td valign="top" align="left">'     ||regRep.DESC_DEPENDENCIA                 ||'</td>
                  </tr>');

       vnExists    := 1;
       vnIdRenglon := vnIdRenglon + 1;

   END LOOP;

   -- muestra el pie de reporte:
   IF vnExists = 0 THEN
      htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- bandera que al tener el valor "imprime" no colocará el salto de página para impresión:
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- omite el encabezado del reporte pero se agrega el salto de página:
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, 'PIE', '0', psUsuario=>pk_login.vgsUSR );
   END IF;

   htp.p('</table><br/> Num. Registros:   ' || vnIdRenglon  || ' </body></html>');

EXCEPTION
   WHEN OTHERS THEN
        htp.p(SQLERRM);

END PWRBFINH;
/
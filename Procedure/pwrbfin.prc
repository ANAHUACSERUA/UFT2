CREATE OR REPLACE PROCEDURE BANINST1.PWRBFIN(psReclDesc   VARCHAR2) IS

  -- declaración de variables:
  vnExists       INTEGER      := 0;
  vnColumnas     INTEGER      := 45;
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


  -- obtiene la información de los alumnos:
CURSOR cuReporte ( psTerm    VARCHAR2  DEFAULT NULL,
                              psProgr   VARCHAR2  DEFAULT NULL ) IS
SELECT DISTINCT spbpers_name_suffix                                                                                   RUT,
            SPRIDEN_ID                                                                                                        ID,
            UPPER(REPLACE(REPLACE(SPRIDEN_LAST_NAME, '*', ' '), '  ', ' ' ))                                 APELLIDOS,
            UPPER(REPLACE(REPLACE(SPRIDEN_FIRST_NAME||' '||SPRIDEN_MI,'   ', ' '), '  ', ' '))    NOMBRE,
            A.SGBSTDN_STST_CODE                                                                                            STATUS,
            (SELECT STVSTST_DESC FROM STVSTST
             WHERE STVSTST_CODE=A.SGBSTDN_STST_CODE)                                                       DESC_STATUS,
            (SELECT SPRADDR_CNTY_CODE||' '||STVCNTY_DESC FROM SPRADDR, STVCNTY
            WHERE SPRADDR_ATYP_CODE = 'PR'
            AND SPRADDR_CNTY_CODE = STVCNTY_CODE
            AND SPRADDR_PIDM = A.SGBSTDN_PIDM
            AND ROWNUM = 1)                                                                                                  COMUNA_RESIDENCIA,
            (SELECT SPRADDR_STAT_CODE||' '||STVSTAT_DESC FROM SPRADDR, STVSTAT
            WHERE SPRADDR_ATYP_CODE = 'PR'
            AND SPRADDR_STAT_CODE = STVSTAT_CODE
            AND SPRADDR_PIDM = A.SGBSTDN_PIDM
            AND ROWNUM = 1)                                                                                                 REGION_RESIDENCIA,
            A.SGBSTDN_PROGRAM_1                                                                                          PROGRAMA,
            decode(TWBCNTR_STATUS_IND,'A',TWBCNTR_NUM,null)                                               CONTRATO,
            decode(TWBCNTR_STATUS_IND,'A',twbcntr_issue_date,null)                                            FECHA_CONTRATO,
            (SELECT X.SARADAP_ADMT_CODE FROM SARADAP X, sarappd Y
            WHERE X.SARADAP_PIDM = A.SGBSTDN_PIDM
            and x.saradap_pidm = y.sarappd_pidm
            and x.saradap_appl_no = sarappd_appl_no
            and SARAPPD_APDC_CODE in ('CO','IN','C2')
            AND X.SARADAP_TERM_CODE_ENTRY = A.SGBSTDN_TERM_CODE_EFF
            AND X.SARADAP_PROGRAM_1 = A.SGBSTDN_PROGRAM_1
                                    AND ROWNUM=1)                                                                                   TIPO_ADMISION,
             (SELECT STVADMT_DESC  FROM STVADMT
             WHERE STVADMT_CODE = SGBSTDN_ADMT_CODE) DESC_TIPO_ADMISION,
            SWVTAVI_RTYP_CODE                                                                                             VIA,
            (SELECT STVRTYP_DESC FROM STVRTYP
            WHERE STVRTYP_CODE =SWVTAVI_RTYP_CODE)                                                       DESC_VIA_INGRESO,
              (SELECT X.SARADAP_APPL_PREFERENCE FROM SARADAP X
            WHERE X.SARADAP_PIDM = A.SGBSTDN_PIDM
            AND X.SARADAP_TERM_CODE_ENTRY = A.SGBSTDN_TERM_CODE_EFF
            AND X.SARADAP_PROGRAM_1 = A.SGBSTDN_PROGRAM_1
            AND X.SARADAP_APPL_NO = (select max(Y.SARADAP_APPL_NO) from saradap y
            						WHERE A.SGBSTDN_PIDM = Y.SARADAP_PIDM
                                    AND A.SGBSTDN_TERM_CODE_EFF = Y. SARADAP_TERM_CODE_ENTRY
                                    AND A.SGBSTDN_PROGRAM_1 = Y.SARADAP_PROGRAM_1)
                                    AND ROWNUM=1) PREFERENCIA,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PEM',1,vnTermAct,null)                    PEM,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'NEME',1,vnTermAct,null)                  NEME,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSCI',2,null,vnTermAnt)                   PSCI_ANTERIOR,
         F_PUNTAJES (A.SGBSTDN_PIDM, 'PETE',2,null,vnTermAnt)                   PETE_ANTERIOR,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PPSU',2,null,vnTermAnt)                   PPSU_ANTERIOR,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSHC',2,null,vnTermAnt)                  PSHC_ANTERIOR,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSLC',2,null,vnTermAnt)                   PSLC_ANTERIOR,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSMA',2,null,vnTermAnt)                  PSMA_ANTERIOR,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PRAN',2,null,vnTermAnt)                  PRAN_ANTERIOR,
            --DECODE(A.SGBSTDN_PIDM, 'LC-ACTU-10',F_PUNTAJES (A.SGBSTDN_PIDM, 'PETE',2,null,vnTermAnt),'LC-PRMC-10',F_PUNTAJES (A.SGBSTDN_PIDM, 'PEPR',2,null,vnTermAnt),NULL) PETE_ANTERIOR,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSCI',1,vnTermAct,null)                   PSCI_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSHC',1,vnTermAct,null)                  PSHC_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSLC',1,vnTermAct,null)                   PSLC_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PPSU',1,vnTermAct,null)                   PPSU_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PRAN',1,vnTermAct,null)    				PRAN,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PETE',1,vnTermAct,null)                  PETE_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PSMA',1,vnTermAct,null)                  PSMA_ACTUAL,
            F_PUNTAJES (A.SGBSTDN_PIDM, 'PRAN',1,vnTermAct,null)                  PRAN_ACTUAL,
            --DECODE(A.SGBSTDN_PROGRAM_1, 'LC-ACTU-10',F_PUNTAJES (A.SGBSTDN_PIDM, 'PETE',1,vnTermAct,null),'LC-PRMC-10',F_PUNTAJES (A.SGBSTDN_PIDM, 'PEPR',1,vnTermAct,null),NULL) PETE_ACTUAL,
            F_PONDERADOS (A.SGBSTDN_PIDM, A.SGBSTDN_PROGRAM_1,1,vnTermAct,null)    PONDERADO_UFT_ACTUAL,
            F_PONDERADOS (A.SGBSTDN_PIDM, A.SGBSTDN_PROGRAM_1,2,null,vnTermAnt)   PONDERADO_UFT_ANTERIOR,
            SPBPERS_SEX                                                                                                                           SEXO,
            (select UPPER(PK_CATALOGO.PREPARATORIA (SORHSCH_SBGI_CODE))
             from SORHSCH
             where SORHSCH_PIDM=A.SGBSTDN_PIDM
              and rownum=1) COLEGIO,
            (select  (SORHSCH_SBGI_CODE)
             from SORHSCH
             where SORHSCH_PIDM=A.SGBSTDN_PIDM
              and rownum=1) CODIGO_COLEGIO,
              (select  (SORBCHR_BCHR_CODE)
             from SORHSCH,SORBCHR
             where SORHSCH_PIDM=A.SGBSTDN_PIDM
             AND SORBCHR_SBGI_CODE = SORHSCH_SBGI_CODE
             AND ROWNUM =1)CODIGO_DEPENDENCIA,
             (select  STVBCHR_DESC FROM
             SORHSCH,SORBCHR, STVBCHR
             where SORHSCH_PIDM=A.SGBSTDN_PIDM
             AND SORBCHR_SBGI_CODE = SORHSCH_SBGI_CODE
             AND SORBCHR_BCHR_CODE = STVBCHR_CODE
             AND ROWNUM =1)DESC_DEPENDENCIA,
            (select SOBSBGI_STAT_CODE
             from SORHSCH,SOBSBGI
             where SORHSCH_PIDM =A.SGBSTDN_PIDM
              and SORHSCH_SBGI_CODE=SOBSBGI_SBGI_CODE
              and rownum=1) REGION_COL,
             (select SOBSBGI_CNTY_CODE
             from SORHSCH,SOBSBGI
             where SORHSCH_PIDM =A.SGBSTDN_PIDM
              and SORHSCH_SBGI_CODE=SOBSBGI_SBGI_CODE
              and rownum=1)  COMUNA_COL,
            (SELECT SUBSTR(SARQUAN_ANSWER,1,3)||','||SUBSTR(SARQUAN_ANSWER,4,2) from sarquan g, saradap X, SARAPPD Y
                   where g.SARQUAN_ADMR_CODE='PPON'
                   and g.SARQUAN_PIDM=A.SGBSTDN_PIDM
                   and G.SARQUAN_PIDM = x.saradap_pidm
                   AND X.SARADAP_PIDM = Y.SARAPPD_PIDM
                   AND X.SARADAP_APPL_NO = Y.SARAPPD_APPL_NO
                   AND Y.SARAPPD_APDC_CODE IN ('CO','IN','C2')
                   AND G.SARQUAN_TERM_CODE_ENTRY = X.SARADAP_TERM_CODE_ENTRY
                   and g.SARQUAN_TERM_CODE_ENTRY=A.SGBSTDN_TERM_CODE_EFF
                   and SARQUAN_APPL_NO = X.SARADAP_APPL_NO
                   and rownum=1) PPON,
                     (select SARQUAN_ANSWER
                from sarquan g, saradap x, SARAPPD Y
               where g.SARQUAN_ADMR_CODE='AÑOA'
                   and g.SARQUAN_PIDM=A.SGBSTDN_PIDM
                   and G.SARQUAN_PIDM = x.saradap_pidm
                   AND G.SARQUAN_TERM_CODE_ENTRY = X.SARADAP_TERM_CODE_ENTRY
                       AND X.SARADAP_PIDM = Y.SARAPPD_PIDM
                   AND X.SARADAP_APPL_NO = Y.SARAPPD_APPL_NO
                   AND Y.SARAPPD_APDC_CODE IN ('CO','IN','C2')
                   and SARQUAN_APPL_NO = X.SARADAP_APPL_NO
                   and rownum=1) AÑOA
                  ,(SELECT 'Si'
                	FROM TWBRETR
              		WHERE TWBRETR_CNTR_NUM = TWBCNTR_NUM)                    Retracto
              		,(SELECT 'Si'
                FROM SFRWDRL
              WHERE SFRWDRL_PIDM = A.SGBSTDN_PIDM
              AND SFRWDRL_TERM_CODE = A.SGBSTDN_TERM_CODE_EFF
              AND SFRWDRL_WDRL_CODE = 'R2')                     Ext
  FROM  SPRIDEN
                    ,SPBPERS
                    ,SMRPRLE
                    ,SGBSTDN A
                    ,SWVTAVI
                    ,TWBCNTR
                    ,SARAATT
                  WHERE SPRIDEN_PIDM = SPBPERS_PIDM
             AND SPRIDEN_CHANGE_IND IS NULL
             --AND SPRIDEN_PIDM = SARADAP_PIDM
             AND SPBPERS_PIDM = TWBCNTR_PIDM
             AND A.SGBSTDN_PIDM = TWBCNTR_PIDM
             AND SWVTAVI_ADMT_CODE = SGBSTDN_ADMT_CODE
             AND SWVTAVI_RTYP_CODE IN ('AR', 'AE','AC')
             AND FWATYALUFT(TWBCNTR_PIDM, TWBCNTR_TERM_CODE) = 'N'
             AND SWVTAVI_TERM_CODE = TWBCNTR_TERM_CODE
             --AND (SARAATT_ATTS_CODE = psIndSe OR psIndSe IS NULL)
             AND EXISTS (SELECT 1 FROM SARADAP
             			WHERE SARADAP_PIDM = TWBCNTR_PIDM
                        AND SARADAP_TERM_CODE_ENTRY = A.SGBSTDN_TERM_CODE_EFF
                        --AND SARADAP_APPL_NO = SARAATT_APPL_NO
			AND SARADAP_PROGRAM_1 = A.SGBSTDN_PROGRAM_1)
             AND SARAATT_TERM_CODE = TWBCNTR_TERM_CODE
             AND SARAATT_PIDM = TWBCNTR_PIDM
            --AND SARADAP_APPL_NO = SARAATT_APPL_NO
              AND TWBCNTR_TERM_CODE = psTerm
              AND SGBSTDN_TERM_CODE_EFF = psTerm
              AND A.SGBSTDN_PROGRAM_1 = SMRPRLE.SMRPRLE_PROGRAM
              AND TWBCNTR_STATUS_IND = 'A'
                AND (psProgr IS NULL OR a.SGBSTDN_PROGRAM_1 = psProgr)
                AND A.SGBSTDN_STYP_CODE IN('N','D','R') ;


---------------------------------------------------
-- bloque principal para la generación del reporte
---------------------------------------------------
BEGIN

   -- valida que el usuario tenga acceso a la base de datos:
   IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

   -- obtiene los valores de las cookies para asignar los valores del filtro del query:
   vsTerm  := pk_ObjHtml.getValueCookie('psTerm');
   vsProgr := pk_ObjHtml.getValueCookie('psProgr');

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
   tabColumna(8)  := '<center> Contrato';
   tabColumna(9)  := '<center> Status';
   tabColumna(10)  := '<center> Descripci&oacute;n<br>Status';
   tabColumna(11)  := '<center> Fecha <br> Contrato';
   tabColumna(12) := '<center> Tipo <br> Admisi&oacute;n';
   tabColumna(13) := '<center> Descripci&oacute;n<br> Admisi&oacute;n';
   tabcolumna(14) := '<center> V&iacute;a <br> Admisi&oacute;n';
   tabColumna(15) :='<center> Descripci&oacute;n<br> V&iacute;a Admisi&oacute;n';
   tabColumna(16) := '<center> Preferencia';
   tabColumna(17) := '<center> PEM';
   tabColumna(18) := '<center> NEME';
   tabColumna(19) := '<center> PSCI <br> Anterior';
   tabColumna(20) := '<center> PSHC <br> Anterior';
   tabColumna(21) := '<center> PSLC <br> Anterior';
   tabColumna(22) := '<center> PSMA <br> Anterior';
   tabColumna(23) := '<center> PRAN <br> Anterior';
   tabColumna(24) := '<center> PETE<br> Anterior';
   tabColumna(25) := '<center> PSU<br> Anterior';
   tabColumna(26) := '<center> Ponderado <br> Anterior';
   tabColumna(27) := '<center> PSCI <br> Actual';
   tabColumna(28) := '<center> PSHC <br> Actual';
   tabColumna(29) := '<center> PSLC <br> Actual';
   tabColumna(30) := '<center> PSMA <br> Actual';
   tabColumna(31) := '<center> PRAN <br> Actual';
   tabColumna(32) := '<center> PETE <br> Actual';
   tabColumna(33) := '<center> PSU<br> Actual';
   tabColumna(34) := '<center> Ponderado <br> Actual';
   tabColumna(35) := '<center> Puntaje Ponderado <br> de Selección';
   tabColumna(36) := '<center> Año Académico <br> de las pruebas';
   tabColumna(37) := '<center> Sexo';
   tabColumna(38) := '<center> C&oacute;digo Colegio';
   tabColumna(39) := '<center> Colegio';
   tabColumna(40) := '<center> Regi&oacute;n';
   tabColumna(41) := '<center> Comuna';
   tabColumna(42) := '<center> Dependencia Colegio';
   tabColumna(43) := '<center> Descipci&oacute;n <br> Dependencia Colegio';
   tabColumna(44) := '<center> Retracto';
   tabColumna(45) := '<center> Retracto Extemporáneo';
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
        --exception
        --when no_data_found then
        --    vnTermAnt:=vsTerm;
          --  vnTermAct:=vsTerm;
        --when others then
          --  vnTermAnt:=vsTerm;
            --vnTermAct:=vsTerm;
   end;

   -- manipula la información obtenida por el cursor:
   FOR regRep IN cuReporte (vsTerm, vsProgr) LOOP

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
                        WHEN ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ANTERIOR,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ANTERIOR,0) , ',', '.')))/2,2) = 0
                           THEN null
                        WHEN ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ANTERIOR,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ANTERIOR,0) , ',', '.')))/2,2) <> 0
                          THEN
                              replace(ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ANTERIOR,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ANTERIOR,0) , ',', '.')))/2,2),'.',',')
              END,
              CASE
                        WHEN ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ACTUAL,0) , ',', '.')))/2,2) = 0
                           THEN null
                        WHEN ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ACTUAL,0) , ',', '.')))/2,2) <> 0
                          THEN
                              replace(ROUND((TO_NUMBER(REPLACE(nvl(regRep.PSLC_ACTUAL,0) , ',', '.'))+TO_NUMBER(REPLACE(nvl(regRep.PSMA_ACTUAL,0) , ',', '.')))/2,2),'.',',')
              END
            into vsPropsu_ant,vsPropsu_act
       from dual;

       HTP.P('<tr> <td valign="top" align="left">' ||regRep.RUT                          ||'</td>
                   <td valign="top" align="left">'       ||regRep.ID                             ||'</td>
                   <td valign="top" align="left">'       ||regRep.APELLIDOS                  ||'</td>
                   <td valign="top" align="left">'       ||regRep.NOMBRE                     ||'</td>
                   <td valign="top" align="left">'       ||regRep.COMUNA_RESIDENCIA   ||'</td>
                   <td valign="top" align="left">'       ||regRep.REGION_RESIDENCIA      ||'</td>
                   <td valign="top" align="left">'       ||regRep.PROGRAMA                    ||'</td>
                   <td valign="top" align="left">' ||regRep.CONTRATO                    ||'</td>
                   <td valign="top" align="left">' ||regRep.STATUS                    ||'</td>
                   <td valign="top" align="left">' ||regRep.DESC_STATUS                    ||'</td>
                   <td valign="top" align="left">' ||regRep.FECHA_CONTRATO          ||'</td>
                   <td valign="top" align="left">' ||regRep.TIPO_ADMISION            ||'</td>
                   <td valign="top" align="left">' ||regRep.DESC_TIPO_ADMISION     ||'</td>
                   <td valign="top" align="left">' ||regRep.VIA                               ||'</td>
                   <td valign="top" align="left">' ||regRep.DESC_VIA_INGRESO         ||'</td>
                   <td valign="top" align="left">' ||regRep.PREFERENCIA                  ||'</td>
                   <td valign="top" align="center">' ||regRep.PEM                               ||'</td>
                   <td valign="top" align="center">' ||regRep.NEME                             ||'</td>
                   <td valign="top" align="center">' ||regRep.PSCI_ANTERIOR             ||'</td>
                   <td valign="top" align="center">' ||regRep.PSHC_ANTERIOR             ||'</td>
                   <td valign="top" align="center">' ||regRep.PSLC_ANTERIOR              ||'</td>
                   <td valign="top" align="center">' ||regRep.PSMA_ANTERIOR              ||'</td>
                   <td valign="top" align="center">' ||regRep.PRAN_ANTERIOR              ||'</td>
                   <td valign="top" align="center">' ||regRep.PETE_ANTERIOR              ||'</td>
                    <td valign="top" align="center">' ||vsPropsu_ant                          ||'</td>
                    <td valign="top" align="center">' ||regRep.PONDERADO_UFT_ANTERIOR         ||'</td>
                   <td valign="top" align="center">' ||regRep.PSCI_ACTUAL                 ||'</td>
                   <td valign="top" align="center">' ||regRep.PSHC_ACTUAL                ||'</td>
                   <td valign="top" align="center">' ||regRep.PSLC_ACTUAL                 ||'</td>
                   <td valign="top" align="center">' ||regRep.PSMA_ACTUAL                ||'</td>
                   <td valign="top" align="center">' ||regRep.PRAN_ACTUAL                ||'</td>
                   <td valign="top" align="center">' ||regRep.PETE_ACTUAL             ||'</td>
                   <td valign="top" align="center">' ||vsPropsu_act                          ||'</td>
                   <td valign="top" align="center">' ||regRep.PONDERADO_UFT_ACTUAL          ||'</td>
                   <td valign="top" align="center">' ||regRep.PPON                            ||'</td>
                   <td valign="top" align="center">' ||regRep.AÑOA                          ||'</td>
                   <td valign="top" align="left">'     ||regRep.SEXO                            ||'</td>
                   <td valign="top" align="left">'     ||regRep.CODIGO_COLEGIO                            ||'</td>
                   <td valign="top" align="left">'     ||regRep.COLEGIO                       ||'</td>
                   <td valign="top" align="left">'     ||regRep.REGION_COL                  ||'</td>
                   <td valign="top" align="left">'     ||regRep.COMUNA_COL                 ||'</td>
                   <td valign="top" align="left">'     ||regRep.CODIGO_DEPENDENCIA                 ||'</td>
                   <td valign="top" align="left">'     ||regRep.DESC_DEPENDENCIA                 ||'</td>
                   <td valign="top" align="left">'     ||regRep.RETRACTO                 ||'</td>
                   <td valign="top" align="left">'     ||regRep.EXT                 ||'</td>
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

   htp.p('</table><br/></body></html>');

EXCEPTION
   WHEN OTHERS THEN
        htp.p(SQLERRM);

END PWRBFIN;
/


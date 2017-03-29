DROP PROCEDURE BANINST1.PWRALBE;

CREATE OR REPLACE PROCEDURE BANINST1.PWRALBE(psReclDesc VARCHAR2) IS
/*
        NOMBRE: REPORTE DE BECAS SIN FORMATO
         TAREA: La base de este reporte se tomo de PK_REPORTEALUMBECADOS.P_ALUMCON
         FECHA: 15/02/2011
         AUTOR : MAC

*/

ckNombres    owa_cookie.vc_arr;
ckValores    owa_cookie.vc_arr;
ckCount      INTEGER;
vgsInicoPag  VARCHAR2(10) := NULL; -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
vgsUSR       VARCHAR2(500);

  vnExists     INTEGER                        := 0;
  vnColumnas   INTEGER                        := 16;
  tabColumna   PK_sisRepImp.tipoTabla         := PK_sisRepImp.tipoTabla(1);
  vsPerio      VARCHAR2(50)                   := NULL;
  vsTermCode   VARCHAR2(6)                    := NULL;
  vsCodeBeca   VARCHAR2(8)                    := NULL;
  vsBeca       VARCHAR2(50)                   := NULL;
  vsNivel      VARCHAR2(50)                   := NULL;
  vsFacu       VARCHAR2(50)                   := NULL;
  vsMajrr      VARCHAR2(50)                   := NULL;
  vsTermAnt    VARCHAR2(6)                    := NULL;
  vsiD         VARCHAR2(10)                   := NULL;
  vsClase      VARCHAR2(15)                   := NULL;
  vsSeccion    VARCHAR2(3)                    := NULL;
  vsIdAnt      SPRIDEN.SPRIDEN_ID%TYPE        := NULL;
  vsCreditHR   SFRSTCR.SFRSTCR_CREDIT_HR%TYPE := NULL;
  vsBillHR     SFRSTCR.SFRSTCR_BILL_HR%TYPE   := NULL;
  vnPorcBeca   NUMBER                         := 0;
  vnTotalMonto NUMBER                         := 0;

  CURSOR cuReporte(psPerio VARCHAR2 DEFAULT NULL,
                   psBeca  VARCHAR2 DEFAULT NULL,
                   psNivel VARCHAR2 DEFAULT NULL,
                   psFacu  VARCHAR2 DEFAULT NULL,
                   psMajrr VARCHAR2 DEFAULT NULL,
                   psID    VARCHAR2 DEFAULT NULL) IS
         SELECT TBBESTU_EXEMPTION_CODE                                     Beca,
                (SELECT TBBEXPT_DESC
                   FROM TBBEXPT
                  WHERE A.TBBESTU_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                    AND A.TBBESTU_TERM_CODE      = TBBEXPT_TERM_CODE
                 )                                                         DescBeca,
                 TBBESTU_EXEMPTION_CODE||' '||
                 (SELECT TBBEXPT_DESC
                    FROM TBBEXPT
                    WHERE A.TBBESTU_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                    AND A.TBBESTU_TERM_CODE        = TBBEXPT_TERM_CODE
                 )                                                         Tipo,
                 D.SPRIDEN_PIDM                                            Pidm,
                 D.SPRIDEN_ID                                              Id,
                 F_GET_RUT(D.SPRIDEN_PIDM)                                   RUT,
                 D.SPRIDEN_LAST_NAME||' '||
                 D.SPRIDEN_FIRST_NAME                                      Nombre,
                 GASTON.NIVEL                                              Nivel,
                 (SELECT STVLEVL_DESC
                    FROM STVLEVL
                   WHERE STVLEVL_CODE = GASTON.NIVEL
                 )                                                        DescNivel,
                 GASTON.CARRERA                                           Carrera,
                 (SELECT STVMAJR_DESC
                    FROM STVMAJR
                   WHERE STVMAJR_CODE = GASTON.CARRERA
                 )                                                        DescCarrera,
                 A.TBBESTU_ACTIVITY_DATE                                  FecRegistro,
                 A.TBBESTU_DEL_IND                                        Status,
                 A.TBBESTU_TERM_CODE                                      TermCode,
                 PK_CATALOGO.COLEGIO(GASTON.ESCUELA)                      Escuela,
                 TBBESTU_USER_ID                                          Usuario,
                 Gaston.StatusSTST                                        StatusSTST,
                 F_GET_TOT_BEC(A.TBBESTU_TERM_CODE,A.TBBESTU_PIDM,
                               A.TBBESTU_EXEMPTION_CODE
                              )                                           Importe
            FROM SPRIDEN D,
                 (SELECT a.SGBSTDN_PROGRAM_1    Programa,
                         a.SGBSTDN_PIDM         Pidm,
                         a.SGBSTDN_CAMP_CODE    Camp,
                         a.SGBSTDN_DEGC_CODE_1  Degree,
                         a.SGBSTDN_LEVL_CODE    Nivel,
                         a.SGBSTDN_MAJR_CODE_1  Carrera,
                         a.SGBSTDN_COLL_CODE_1  Escuela,
                 (SELECT STVSTST_DESC
                    FROM STVSTST
                   WHERE STVSTST_CODE = a.SGBSTDN_STST_CODE) StatusSTST
                    FROM SGBSTDN a
                   WHERE a.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                      FROM SGBSTDN B
                                                     WHERE B.SGBSTDN_PIDM = a.SGBSTDN_PIDM
                                                       AND SGBSTDN_TERM_CODE_EFF <= psPerio
                                                   )
                  AND a.SGBSTDN_STST_CODE = 'AS'
                 ) Gaston,
                 TBBESTU A
           WHERE gaston.PIDM            = D.SPRIDEN_PIDM
             AND D.SPRIDEN_PIDM            = A.TBBESTU_PIDM
             AND D.SPRIDEN_CHANGE_IND     IS NULL
             AND NVL(A.TBBESTU_DEL_IND,'A') <> 'D' -- NO MOSTRAR BECAS ELIMINADAS
             AND (A.TBBESTU_EXEMPTION_CODE = psBeca  OR psBeca  IS NULL)
             AND (A.TBBESTU_TERM_CODE      = psPerio OR psPerio IS NULL)
             AND (GASTON.NIVEL             = psNivel OR psNivel IS NULL)
             AND (GASTON.CARRERA           = psMajrr OR psMajrr IS NULL)
             AND (D.SPRIDEN_ID             = psID    OR psID    IS NULL)
             AND (GASTON.ESCUELA           = psFacu  OR psFacu  IS NULL)
           ORDER BY TBBESTU_TERM_CODE, TBBESTU_EXEMPTION_CODE;

  BEGIN
      IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

      --son buscadas los valores de las cookies para asignar los valores del filtro del query.
      ckCount := 0;
      owa_cookie.get_all(ckNombres,ckValores,ckCount);

      IF ckCount != 0 THEN
         FOR vnCOKIES IN 1..ckCount LOOP
             IF    ckNOMBRES(vnCOKIES) = 'psBeca' THEN
                   vsBeca := ckValores(vnCOKIES);

             ELSIF ckNOMBRES(vnCOKIES) = 'psPerio' THEN
                   vsPerio  := ckValores(vnCOKIES);

             ELSIF ckNOMBRES(vnCOKIES) = 'psNivel' THEN
                   vsNivel := ckValores(vnCOKIES);

             ELSIF ckNOMBRES(vnCOKIES) = 'psFacu' THEN
                   vsFacu  := ckValores(vnCOKIES);

             ELSIF ckNOMBRES(vnCOKIES) = 'psMajrr' THEN
                   vsMajrr := ckValores(vnCOKIES);

             ELSIF ckNOMBRES(vnCOKIES) = 'cookSeccion' THEN
                   vsSeccion := ckValores(vnCOKIES);

             ELSIF ckNOMBRES(vnCOKIES) = 'psId' THEN
                   vsId := ckValores(vnCOKIES);

             END IF;
         END LOOP;
      END IF;

      -- las instrucciones determinan el largo de la tabla
      FOR vnI IN 1..vnColumnas LOOP
          tabColumna.EXTEND(vnI);
          tabColumna(vnI) := NULL;
      END LOOP;

      tabColumna(1)  := 'Periodo';
      tabColumna(2)  := 'ID';
      tabColumna(3)  := 'RUT';
      tabColumna(4)  := 'Nombre';
      tabColumna(5)  := 'Descripci&oacute;n del Programa';
      tabColumna(6)  := 'Status alumno';
      tabColumna(7)  := 'Promedio del semestre anterior';
      tabColumna(8)  := 'Materias reprobadas';
      tabColumna(9) := 'Fecha Beca';
      tabColumna(10) := 'Usuario Registrado';
      tabColumna(11) := 'Status de la beca';
      tabColumna(12) := 'Cr&eacute;ditos inscritos (del periodo)';
      tabColumna(13) := 'Total de Cr&eacute;ditos  ganados';
      tabColumna(14) := 'C&oacute;digo de la beca';
      tabColumna(15) := 'Porcentaje';
      tabColumna(16) := 'Tipo de beca';

      vsIdAnt:= '0';

      FOR regRep IN cuReporte(vsPerio,vsBeca,vsNivel,vsFacu,vsMajrr, vsId) LOOP
          IF vnExists = 0 THEN
             PK_sisRepImp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vgsInicoPag,'1',psSubtitulo=>' ',psUsuario=>vgsUSR,psSeccion=>vsSeccion);--, psUniversidad=>'UAS');
             vgsInicoPag := 'SALTO';
          END IF;


          IF (vsIdAnt = regRep.Id and vsTermcode = regRep.TermCode and vsCodeBeca = regRep.Beca) THEN
              -- Mismo expediente
              htp.p('<tr><td></td><td></td><td></td><td></td>');
          ELSE
             SELECT DECODE(SUBSTR(regRep.TermCode,5),'75',SUBSTR(regRep.TermCode,1,4)  ||'25',
                           '25',SUBSTR(regRep.TermCode,1,4)-1||'75',
                           regRep.TermCode)
               INTO vsTermAnt
               FROM DUAL;

             SELECT DECODE(SGKCLAS.F_CLASS_CODE(regRep.Pidm,regRep.Nivel,'999999'),'00','Nuevo ingreso','Reingreso')
               INTO vsClase
               FROM DUAL;

             htp.p('<tr>
             <td valign="top">'||regRep.TermCode   ||'</td>
             <td valign="top">'||regRep.Id         ||'</td>
             <td valign="top">'||regRep.RUT        ||'</td>
             <td valign="top">'||regRep.Nombre     ||'</td>
             <td valign="top">'||regRep.DescCarrera||'</td>
             <td valign="top">'||regRep.StatusSTST ||'</td>
             <td valign="top">'||FWAPRTG(regRep.Pidm, vsTermAnt,'G', regRep.Nivel)||'</td>
             <td valign="top">'||FWRMTRP(regRep.TermCode, regRep.Pidm, regRep.Nivel)                      ||'</td>
             ');
          END IF;

          -- Query obtenido de reporte en pro*c creado por AMP    (tsralbe.pc)
          BEGIN
              SELECT NVL(SUM(SFRSTCR_CREDIT_HR),0),
                     NVL(SUM(SFRSTCR_BILL_HR)  ,0)
                INTO vsCreditHR,
                     vsBillHR
                FROM SFRSTCR
               WHERE SFRSTCR_PIDM      = regRep.Pidm
                 AND SFRSTCR_TERM_CODE = regRep.TermCode
                 AND SFRSTCR_RSTS_CODE IN ('RE','RW');
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   vsCreditHR := NULL;
                   vsBillHR   := NULL;
          END;

          --MCC 07/09/2006 Cambio para integrar el % de beca definido por AMP
          BEGIN
              SELECT MAX(TBREDET_PERCENT)
                INTO vnPorcBeca
                FROM TBREDET
               WHERE TBREDET_EXEMPTION_CODE = regRep.beca
                 AND TBREDET_TERM_CODE      = regRep.TermCode;
          EXCEPTION
              WHEN OTHERS THEN
                   vnPorcBeca := 0;
          END;

          htp.p('
          <td valign="top">'||regRep.FecRegistro||'</td>
          <td valign="top">'||regRep.Usuario    ||'</td>
          <td valign="top">'||regRep.Status     ||'</td>
          <td valign="top">'||vsCreditHR        ||'</td>
          <td valign="top">'||FWRCRED(regRep.Pidm, regRep.Nivel, regRep.TermCode)||'</td>
          <td valign="top">'||regRep.Beca       ||'</td>
          <td valign="top">'||vnPorcBeca        ||'</td>
          <td valign="top">'||regRep.Tipo       ||'</td>
          ');

          vnExists := 1;
          vsIdAnt      := regRep.Id;
          vsTermCode   := regRep.TermCode;
          vsCodeBeca   := regRep.Beca;
          vnTotalMonto := NULL;
      END LOOP;

      -- La variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
      PK_sisRepImp.vgsSaltoImp := 'Imprime';

      vgsInicoPag:= 'PIE';
      -- Es omitido el encabezado del reporte pero se agrega el salto de pagina
      PK_sisRepImp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vgsInicoPag,'0', psUsuario=>vgsUSR, psSeccion=>vsSeccion);

      IF vnExists = 0 THEN
         htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||PK_sisRepImp.vgsResultado||'</font></th></tr>');
      END IF;

      htp.p('</table></body></html>');

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);
  END PWRALBE;
/


DROP PUBLIC SYNONYM PWRALBE;

CREATE PUBLIC SYNONYM PWRALBE FOR BANINST1.PWRALBE;


GRANT EXECUTE ON BANINST1.PWRALBE TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWRALBE TO WWW2_USER;

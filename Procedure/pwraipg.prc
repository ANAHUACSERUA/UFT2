DROP PROCEDURE BANINST1.PWRAIPG;

CREATE OR REPLACE PROCEDURE BANINST1.PWRAIPG(psReclDesc VARCHAR2) IS

/**************************************************************
           tarea:  procedimiento para el reporte de alumnos inscritos por programa
         módulo:  selección de cursos
           autor:  horacio martínez ramírez - hmr
           fecha:  05/sep/2010
**************************************************************/

  vnRow      INTEGER                := 0;
  vnExists   INTEGER                := 0;
  vnColumnas INTEGER                := 14;
  tabColumna Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla(1);
  vsPerio    VARCHAR2(20)           := NULL;
  vsUniv     VARCHAR2(20)           := NULL;
  vsProgr    VARCHAR2(20)           := NULL;
  vsClase    VARCHAR2(20)           := NULL;
  vsTipo     VARCHAR2(20)           := NULL;
  vsSeccion  VARCHAR2(3)            := NULL;
  vsEdad     VARCHAR2(2)            := NULL;
  vsTipoE    VARCHAR2(5)            := NULL;
  vsSxo      VARCHAR2(5)            := NULL;
  vsMajr     VARCHAR2(30)           := NULL;
  vsTermCode VARCHAR2(10)           := NULL;
  vsCampCode VARCHAR2(10)           := NULL;
  vsRateCode VARCHAR2(10)           := NULL;
  vsEnca     VARCHAR2(1)            := NULL;
  vsSede     VARCHAR2(10)           := NULL;
  vsInicoPag VARCHAR2(10)           := NULL;
  vbEnca     BOOLEAN                := TRUE;

  CURSOR cuReporte(psUniv  VARCHAR2 DEFAULT NULL,
                            psPerio VARCHAR2 DEFAULT NULL,
                            psProgr VARCHAR2 DEFAULT NULL,
                            psTipo  VARCHAR2 DEFAULT NULL,
                            psTipoE VARCHAR2 DEFAULT NULL,
                            psMajr  VARCHAR2 DEFAULT NULL,
                            psSede  VARCHAR2 DEFAULT NULL   ) IS
                SELECT alumno.termCode                             AS TermCode,
                           Pk_Catalogo.PERIODO(alumno.termCode)        AS Descperiodo,
                           NVL(alumno.campCode,'S/Unive')              AS CampCode,
                           alumno.progCode                             AS CvePrograma,
                           Pk_Catalogo.PROGRAMA(alumno.progCode)       AS DescPrograma,
                           SPRIDEN_PIDM                                AS Pidm,
                           SPRIDEN_ID                                  AS Id,
                           SPBPERS_NAME_SUFFIX                   AS Rut,
                           REPLACE(REPLACE(
                           SPRIDEN_LAST_NAME||' '||
                           SPRIDEN_FIRST_NAME,'*',' '),'ñ','&ntilde;') AS Nombre,
                           Pk_Catalogo.TipoAlumno(alumno.stypCode)     AS TipoEstudiante,
                           Pk_Catalogo.Admision(alumno.admtCode)       AS DescAdmision,
                           alumno.Clase                                AS CveClase,
                           alumno.Creditos                             AS Creditos,
                           alumno.BillHrs                              AS BillHrs,
                           alumno.rateCode                             AS rateCode
                   FROM SPRIDEN,
                            SPBPERS,
                        (SELECT SFRSTCR_TERM_CODE               AS termCode,
                                SGBSTDN_CAMP_CODE               AS campCode,
                                SGBSTDN_PROGRAM_1               AS progCode,
                                SGBSTDN_PIDM                    AS Pidm,
                                SGBSTDN_STYP_CODE               AS stypCode,
                                SGBSTDN_ADMT_CODE               AS admtCode,
                                SGBSTDN_MAJR_CODE_1             AS majrCode,
                                SGBSTDN_RATE_CODE               AS rateCode,
                                SGKCLAS.F_CLASS_CODE(
                                SGBSTDN_PIDM,SGBSTDN_LEVL_CODE,
                                NVL(psPerio,'999999'))          AS Clase,
                                SUM(SFRSTCR_CREDIT_HR)          AS Creditos,
                                SUM(SFRSTCR_BILL_HR)            AS BillHrs
                           FROM SGBSTDN A,
                                SFRSTCR
                          WHERE SFRSTCR_PIDM            = A.SGBSTDN_PIDM
                            AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                             FROM SGBSTDN B
                                                            WHERE B.SGBSTDN_PIDM           = A.SGBSTDN_PIDM
                                                              AND B.SGBSTDN_TERM_CODE_EFF <= SFRSTCR_TERM_CODE
                                                          )
                            AND A.SGBSTDN_STST_CODE     = 'AS'
                            AND SFRSTCR_RSTS_CODE      IN ('RW','RE')
                          GROUP BY SFRSTCR_TERM_CODE,
                                   SGBSTDN_CAMP_CODE,
                                   SGBSTDN_PROGRAM_1,
                                   SGBSTDN_PIDM,
                                   SGBSTDN_LEVL_CODE,
                                   SGBSTDN_STYP_CODE,
                                   SGBSTDN_ADMT_CODE,
                                   SGBSTDN_MAJR_CODE_1,
                                   SGBSTDN_RATE_CODE
                        ) alumno
                  WHERE SPRIDEN_PIDM        = alumno.Pidm
                    AND SPRIDEN_PIDM          = SPBPERS_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND (alumno.termCode = psPerio OR psPerio IS NULL)
                    AND (alumno.campCode = psUniv  OR psUniv  IS NULL)
                    AND (alumno.progCode = psProgr OR psProgr IS NULL)
                    AND (alumno.admtCode = psTipo  OR psTipo  IS NULL)
                    AND (alumno.stypCode = psTipoE OR psTipoE IS NULL)
                    AND (alumno.majrCode = psMajr  OR psMajr  IS NULL)
                    AND (alumno.rateCode = psSede  OR psSede  IS NULL)
                  ORDER BY TermCode DESC, rateCode, CvePrograma, NOMBRE;

  CURSOR cuSuda(psPidm NUMBER,
                         psTerm VARCHAR2) IS
         SELECT SGBUSER_SUDA_CODE SUDA
           FROM SGBUSER
          WHERE SGBUSER_TERM_CODE = psTerm
              AND SGBUSER_PIDM      = psPidm;

  function f_Detalle(psCamp varchar2,
                           psProg varchar2,
                           psTerm varchar2) return varchar2 is

  vnAlumnos INTEGER := 0;

  begin

      if psProg is not null then
         SELECT COUNT(DISTINCT alumno.Pidm)
           INTO vnAlumnos
           FROM (SELECT SFRSTCR_TERM_CODE  termCode,
                        SGBSTDN_CAMP_CODE  campCode,
                        SGBSTDN_PROGRAM_1  progCode,
                        SGBSTDN_PIDM       Pidm
                   FROM SGBSTDN A,
                        SFRSTCR
                  WHERE SFRSTCR_PIDM            = A.SGBSTDN_PIDM
                    AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                     FROM SGBSTDN B
                                                    WHERE B.SGBSTDN_PIDM           = A.SGBSTDN_PIDM
                                                      AND B.SGBSTDN_TERM_CODE_EFF <= SFRSTCR_TERM_CODE
                                                  )
                    AND A.SGBSTDN_STST_CODE     = 'AS'
                    AND SFRSTCR_RSTS_CODE      IN ('RW','RE')
                ) alumno
          WHERE alumno.termCode = psTerm
            AND alumno.campCode = psCamp
            AND alumno.progCode = psProg;

         return '<tr><td valign="top" colspan="2" align="right">Total de inscritos al programa:'||
                  '</td><td colspan="'||(vnColumnas-2)||'">'||vnAlumnos||'</td></tr>';
       end if;

       return null;

  end f_Detalle;

  BEGIN
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      -- son buscados los valores de las cookies para asignar los valores del filtro del query
      vsUniv    := pk_ObjHtml.getValueCookie('psUnive');
      vsPerio   := pk_ObjHtml.getValueCookie('psPerio');
      vsProgr   := pk_ObjHtml.getValueCookie('psProgr');
      vsClase   := pk_ObjHtml.getValueCookie('psClase');
      vsTipo    := pk_ObjHtml.getValueCookie('psTipoA');
      vsTipoE   := pk_ObjHtml.getValueCookie('psTyAl');
      vsEnca    := pk_ObjHtml.getValueCookie('psEnca');
      vsMajr    := pk_ObjHtml.getValueCookie('psMajrr');
      vsSeccion := pk_ObjHtml.getValueCookie('cookSeccion');
      vsSede    := pk_ObjHtml.getValueCookie('psRate');

      -- las instrucciones determinan el largo de la tabla
      FOR vnI IN 1..vnColumnas LOOP
          tabColumna.EXTEND(vnI);
          tabColumna(vnI) := NULL;
      END LOOP;

      tabColumna(1)  := 'Programa';
      tabColumna(2)  := 'Descripci&oacute;n';
      tabColumna(3)  := 'Id';
      tabColumna(4)  := 'Rut';
      tabColumna(5)  := 'Nombre';
      tabColumna(6)  := 'Sexo';
      tabColumna(7)  := 'Edad';
      tabColumna(8)  := 'Tipo de Estudiante';
      tabColumna(9)  := 'Periodos cursados';
      tabColumna(10) := 'Tipo de admisi&oacute;n';
      tabColumna(11) := 'Clase ';
      tabColumna(12) := 'Descripci&oacute;n';
      tabColumna(13) := 'Cr&eacute;ditos inscritos';
      tabColumna(14) := 'Bill Hrs';

      FOR regRep IN cuReporte(vsUniv, vsPerio, vsProgr, vsTipo, vsTipoE, vsMajr, vsSede) LOOP
          vsSxo       := NULL;

          IF regRep.CveClase = vsClase  OR vsClase IS NULL  THEN

             IF (vsTermCode IS NULL OR vsTermCode <> regRep.TermCode OR
                  vsCampCode IS NULL OR vsCampCode <> regRep.CampCode OR
                  vsRateCode IS NULL OR vsRateCode <> regRep.rateCode OR
                  vnRow = 28) AND vbEnca THEN

                  Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicoPag,'1',psSubtitulo=>'<br>Periodo '||regRep.TermCode,psUsuario=>pk_login.vgsUSR,psSeccion=>vsSeccion,psUniversidad=>regRep.CampCode, psDetalle=>f_Detalle(regRep.CampCode,vsProgr,regRep.TermCode) );

                  vsInicoPag := 'SALTO';
                  vnRow  := 0;

             END IF;

             IF vsEnca = 'N' THEN
                 vbEnca := FALSE;
             END IF;

             BEGIN
                 SELECT SPBPERS_SEX, FLOOR(MONTHS_BETWEEN(SYSDATE, SPBPERS_BIRTH_DATE)/12)
                   INTO vsSxo,vsEdad
                   FROM SPBPERS
                  WHERE SPBPERS_PIDM = regRep.Pidm;

             EXCEPTION
                 WHEN OTHERS THEN
                          NULL;
             END;

             htp.p('<tr>
             <td valign="top" align="left">'  ||regRep.CvePrograma   ||'</td>
             <td valign="top" align="left">'  ||regRep.DescPrograma  ||'</td>
             <td valign="top" align="left">'  ||regRep.Id            ||'</td>
             <td valign="top" align="left">'  ||regRep.Rut            ||'</td>
             <td valign="top" align="left">'  ||regRep.Nombre        ||'</td>
             <td valign="top" align="center">'||vsSxo                ||'</td>
             <td valign="top" align="center">'||vsEdad               ||'</td>
             <td valign="top" align="left">'  ||regRep.TipoEstudiante||'</td>
             <td valign="top" align="left">');

             FOR regSud IN cuSuda(regRep.Pidm, regRep.TermCode) LOOP
                   htp.p(regSud.SUDA||'</br>');
             END LOOP;

             htp.p('</td>
             <td valign="top" align="left">'  ||regRep.DescAdmision||'</td>
             <td valign="top" align="center">'||regRep.CveClase    ||'</td>
             <td valign="top" align="left">  </td>
             <td valign="top" align="right">' ||regRep.Creditos    ||'</td>
             <td valign="top" align="right">' ||regRep.BillHrs     ||'</td>
             </tr>');

             vnExists   := 1;
             vnRow      := vnRow + 1;
             vsTermCode := regRep.TermCode;
             vsCampCode := regRep.CampCode;
             vsRateCode := regRep.rateCode;
          END IF;
      END LOOP;

      IF vnExists = 0 THEN
          htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
      ELSE
          -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresión
          Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

          -- es omitido el encabezado del reporte pero se agrega el salto de página
          Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR, psSeccion=>vsSeccion);
      END IF;

      htp.p('</table><br><br></body></html>');

  EXCEPTION
      WHEN OTHERS THEN
               HTP.P(SQLERRM);

  END PWRAIPG;
/


DROP PUBLIC SYNONYM PWRAIPG;

CREATE PUBLIC SYNONYM PWRAIPG FOR BANINST1.PWRAIPG;


GRANT EXECUTE ON BANINST1.PWRAIPG TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWRAIPG TO WWW2_USER;

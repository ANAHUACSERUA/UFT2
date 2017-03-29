DROP PROCEDURE BANINST1.PWRARCH;

CREATE OR REPLACE PROCEDURE BANINST1.PWRARCH(psReclDesc VARCHAR2) IS

/**************************************************************
           tarea:  obtiene las evaluaciones realizadas por el alumno (evaluación sin promediar)
          módulo:  resultados del sistema de evaluación de la práctica docente (seprad)
           autor:  horacio martínez ramírez - hmr
           fecha:  01/nov/2010

          21  ENE 2011
          JCCR
          *  Se le agrega lo delk parametro de excell
                IF vsExcel = 'EXCEL' THEN
                 owa_util.mime_header('application/ms-excel',true);
                 owa_util.http_header_close;
              END IF;
**************************************************************/

  TYPE reg_Reac IS RECORD (qcodCode VARCHAR2(30),
                           teqaCode VARCHAR2(30),
                           qcodDesc VARCHAR2(500)
                          );

  TYPE tableReac IS TABLE OF reg_Reac INDEX BY BINARY_INTEGER;

  tabReac  tableReac;

  tabColumna        Pk_Sisrepimp.tipoTabla           := Pk_Sisrepimp.tipoTabla(1);
  vnRow             INTEGER                          := 0;
  vnReac            INTEGER                          := 0;
  vnNoAplTot        INTEGER                          := 0;
  vnNoAplica        INTEGER                          := 0;
  vnColumnas        INTEGER                          := 25;
  vnI               NUMBER(1)                        := 0;
  cn1               NUMBER(1)                        := 1;
  cn2               NUMBER(1)                        := 2;
  cn3               NUMBER(1)                        := 3;
  cn4               NUMBER(1)                        := 4;
  cn5               NUMBER(1)                        := 5;
  cn6               NUMBER(1)                        := 6;
  cn7               NUMBER(1)                        := 7;
  cn8               NUMBER(1)                        := 8;
  cn9               NUMBER(1)                        := 9;
  cnM1              NUMBER(1)                        := -1;
  vsInicoPag        VARCHAR2(10)                     := NULL;
  vnPidmA           NUMBER                           := NULL;
  vnPidmFclt        NUMBER                           := NULL;
  vsCamp            VARCHAR2(6)                      := NULL;
  vsTerm            VARCHAR2(6)                      := NULL;
  vsEncu            VARCHAR2(30)                     := NULL;
  vsRate            VARCHAR2(6)                      := NULL;
  vsColl            VARCHAR2(6)                      := NULL;
  vsSedeCode        VARCHAR2(6)                      := NULL;
  vsProgCode        VARCHAR2(300)                    := NULL;
  vsProgDesc        VARCHAR2(300)                    := NULL;
  vsProgVpdi        VARCHAR2(300)                    := NULL;
  vsProg            VARCHAR2(300)                    := NULL;
  vsPro2            VARCHAR2(300)                    := NULL;
  vsPtrm            VARCHAR2(1000)                   := NULL;
  vsFaculty         VARCHAR2(1000)                   := NULL;
  vsTipoContrato    VARCHAR2(1000)                   := NULL;
  vsGradoAcademico  VARCHAR2(1000)                   := NULL;
  vsSubjCode        VARCHAR2(5)                      := NULL;
  vsSstsCode        VARCHAR2(10)                     := NULL;
  vsNoAplica        SVBTESD.SVBTESD_OPEN_ANSWER%TYPE := NULL;
  vsTipoDesc        STVSCHD.STVSCHD_DESC%TYPE        := NULL;
  vsTipoCode        STVSCHD.STVSCHD_CODE%TYPE        := NULL;
  vsCampCode        STVCAMP.STVCAMP_CODE%TYPE        := NULL;
  vsCampDesc        STVCAMP.STVCAMP_DESC%TYPE        := NULL;
  vsCollCode        STVCOLL.STVCOLL_CODE%TYPE        := NULL;
  vsCollDesc        STVCOLL.STVCOLL_DESC%TYPE        := NULL;

  vsExcel           VARCHAR2(20)                     := NULL;

  vsPaav            SWMSPBR.SWMSPBR_PAAV_ALUMNO%TYPE := NULL;
  vsPaan            SWMSPBR.SWMSPBR_PAAN_ALUMNO%TYPE := NULL;
  vsSexo            VARCHAR2(30)                     := NULL;

  csSIN             CONSTANT VARCHAR2(3)             := 'SIN';
  csAutoEval        CONSTANT VARCHAR2(8)             := 'AUTOEVAL';
  csComment         CONSTANT VARCHAR2(6)             := 'COMENT';
  csPlanea          CONSTANT VARCHAR2(10)            := 'PLANEACION';
  csHabil           CONSTANT VARCHAR2(10)            := 'HABILIDADE';
  csEvalua          CONSTANT VARCHAR2(10)            := 'EVALUACIÓN';
  csRasgos          CONSTANT VARCHAR2(6)             := 'RASGOS';
  csIdentif         CONSTANT VARCHAR2(10)            := 'IDENTIFICA';
  csVgp             CONSTANT VARCHAR2(8)             := 'VALGPROF';
  csVgc             CONSTANT VARCHAR2(9)             := 'VALGCURSO';
  csMayorQ          CONSTANT VARCHAR2(1)             := '>';
  csArrB            CONSTANT VARCHAR2(1)             := '@';
  csAsterQ          CONSTANT VARCHAR2(1)             := '*';
  csEspace          CONSTANT VARCHAR2(1)             := ' ';
  csSlash           CONSTANT VARCHAR2(1)             := '/';
  cnCero            CONSTANT NUMBER(1)               := 0;

  -- cubruto
  CURSOR cuBruto IS
         SELECT SWRPGAC_TERM_CODE    AS Term,
                SWRPGAC_CRN          AS Crn,
                SWRPGAC_CAMP_CODE    AS Camp,
                SWRPGAC_PTRM_CODE    AS Ptrm,
                SWRPGAC_COLL_CODE    AS Coll,
                SWRPGAC_SUBJ_CODE    AS Subj,
                SWRPGAC_CRSE_NUMB    AS Crse,
                SWRPGAC_TITLE        AS Titulo,
                SWRPGAC_SCHD_CODE    AS Tipo,
                SWRPSPD_FACULTY_PIDM AS Faculty,
                SWRPSPD_PIDM         AS PidA,
                SWRPSPD_TEMP_PIDM    AS PidB
           FROM SWRPGAC, SWRPSPD
          WHERE SWRPGAC_TERM_CODE = SWRPSPD_TERM_CODE
            AND SWRPGAC_CRN       = SWRPSPD_CRN
          ORDER BY SWRPSPD_FACULTY_PIDM,SWRPGAC_CRN,SWRPSPD_PIDM, SWRPGAC_COLL_CODE,
                   SWRPGAC_SUBJ_CODE,   SWRPGAC_CRSE_NUMB;

  -- cureactivos
  CURSOR cuReactivos(psEncu VARCHAR2) IS
         SELECT (SELECT SVBQCOD_DESC
                   FROM SVBQCOD
                  WHERE SVBQCOD_CODE = SVRSDEF_QCOD_CODE
                )                 qcodDesc,
                SVRSDEF_QCOD_CODE qcodCode,
                SVRSDEF_TEQA_CODE teqaCode,
                DECODE(SVRSDEF_TEQA_CODE,csAutoEval,cn1,csPlanea,cn2,csHabil,cn3,csEvalua,cn4,csRasgos,cn5,csIdentif,cn6,csVgp,cn7,csVgc,cn8,csComment,cn9) Orden1,
                SUBSTR(SVRSDEF_QCOD_CODE,LENGTH(SVRSDEF_QCOD_CODE)- cn1,cn2) Orden2
           FROM SVRSDEF
          WHERE SVRSDEF_TSSC_CODE = psEncu
          ORDER BY Orden1,Orden2;

  -- retorna los comentarios
  function f_qpoints(psTerm varchar2,
                     pnCrn  number,
                     pnTemp number,
                     pnFacu number,
                     psQcod varchar2,
                     psEncu varchar2) return varchar2 is

  vsComentarios svbtesd.svbtesd_open_answer%type := null;

  begin
      select DECODE(svbtesd_pvac_qpoints,NULL,svbtesd_open_answer,svbtesd_pvac_qpoints)
        into vsComentarios
        from svbtesd
       where svbtesd_esas_temp_pidm = pnTemp
         and svbtesd_term_code      = psTerm
         and svbtesd_crn            = pnCrn
         and svbtesd_faculty_pidm   = pnFacu
         and svbtesd_tssc_code      = psEncu
         and svbtesd_qcod_code      = psQcod;

      return vsComentarios;

  exception
      when others then
           return null;
  end f_qpoints;

  -- retorna la descripción del tipo de materia
  function F_TipoMateria(psTipo varchar2) return varchar2 is

  Begin
      if vsTipoCode is null or vsTipoCode <> psTipo then
         select stvschd_desc
           into vsTipoDesc
           from stvschd
          where stvschd_code = psTipo;
      end if;

      return vsTipoDesc;

  exception
      when others then
           return null;
  end F_TipoMateria;

  -- retorna el grado académico
  function F_GradoAcademico(pnFaculty number) return varchar2 is

  begin
      if vnPidmFclt is null or vnPidmFclt <> pnFaculty then
         begin
             select '<td valign="top" '||PK_ObjHTML.vgsBorderDDDDDD||csMayorQ||A.STVDEGC_CODE||'</td>'||
                    '<td valign="top" '||PK_ObjHTML.vgsBorderDDDDDD||csMayorQ||A.STVDEGC_DESC||'</td>'
               into vsGradoAcademico
               from sordegr, stvdegc a
              where sordegr_pidm         = pnFaculty
                and sordegr_degc_code   = a.stvdegc_code
                and a.stvdegc_acat_code = (select max(b.stvdegc_acat_code)
                                             from stvdegc b
                                            where b.stvdegc_code = a.stvdegc_code
                                          );
         exception
             when others then
                  vsGradoAcademico := '<td '||PK_ObjHTML.vgsBorderDDDDDD||'></td><td '||PK_ObjHTML.vgsBorderDDDDDD||'></td>';
         end;
      end if;

      return vsGradoAcademico;


  end F_GradoAcademico;

  -- la función retorna el tipo de contrato del alumno
  function F_TipoContrato(pnFaculty number) return varchar2 is

  begin
      if vnPidmFclt is null or vnPidmFclt <> pnFaculty then
         begin
             select '<td valign="top" '||PK_ObjHTML.vgsBorderDDDDDD||csMayorQ||a.sibinst_fstp_code||'</td>'||
                    '<td valign="top" '||PK_ObjHTML.vgsBorderDDDDDD||csMayorQ||
                    (select stvfstp_desc
                       from stvfstp
                      where stvfstp_code = a.sibinst_fstp_code)||'</td>'
               into vsTipoContrato
               from sibinst a
              where a.sibinst_pidm          = pnFaculty
                and a.sibinst_term_code_eff = (select max(b.sibinst_term_code_eff)
                                                 from sibinst b
                                                where b.sibinst_pidm = a.sibinst_pidm
                                               );
         exception
             when others then
                  vsTipoContrato := '<td '||PK_ObjHTML.vgsBorderDDDDDD||'></td><td '||PK_ObjHTML.vgsBorderDDDDDD||'></td>';
         end;
      end if;

      return vsTipoContrato;


  end F_TipoContrato;

  -- la función retorna el tipo de contrato del alumno
  function F_Contrato(pnFaculty number) return varchar2 is

  vsContrato varchar2(50) := null;

  begin
      select a.sibinst_fstp_code||csArrB||
             (select stvfstp_desc
                from stvfstp
               where stvfstp_code = a.sibinst_fstp_code)
        into vsContrato
        from sibinst a
       where a.sibinst_pidm          = pnFaculty
         and a.sibinst_term_code_eff = (select max(b.sibinst_term_code_eff)
                                          from sibinst b
                                         where b.sibinst_pidm = pnFaculty
                                       );

      return vsContrato;

  exception
      when others then
           return null;
  end F_Contrato;

  -- la función retorna el id y nombre del profesor
  function F_IdNameFaculty(pnPidm number) return varchar2 is

  begin
      if vnPidmFclt is null or vnPidmFclt <> pnPidm then
         begin
             select '<td valign="top" '||PK_ObjHTML.vgsBorderDDDDDD||csMayorQ||spriden_id||
                    '</td>'||
                    '<td valign="top" '||PK_ObjHTML.vgsBorderDDDDDD||csMayorQ||f_get_rut(pnPidm)||
                    '</td>'||
                    '<td valign="top" '||PK_ObjHTML.vgsBorderDDDDDD||csMayorQ||
                    replace(spriden_last_name||spriden_first_name,csAsterQ,csEspace)||'</td>'
               into vsFaculty
               from spriden
              where spriden_pidm = pnPidm
                and spriden_change_ind is null;

         exception
             when others then
                  vsFaculty :=  '<td '||PK_ObjHTML.vgsBorderDDDDDD||'></td><td '||PK_ObjHTML.vgsBorderDDDDDD||'></td>';
         end;
      end if;

      return vsFaculty;


  end F_IdNameFaculty;

  function f_CampDesc(psCamp varchar2) return varchar2 is

  begin
      if vsCampCode is null or psCamp <> vsCampCode then
         vsCampDesc := pk_Seprad1.F_CampDesc(psCamp);
      end if;

      return vsCampDesc;
  end f_CampDesc;

  function f_CollDesc(psColl varchar2) return varchar2 is

  begin
      if vsCollCode is null or psColl <> vsCollCode then
         vsCollDesc := pk_Seprad1.F_CollDesc(psColl);
      end if;

      return vsCollDesc;
  end f_CollDesc;

  procedure p_GrdeAdm(pnPidm number) is

  begin
      vsProg := NULL;
      vsPaav := NULL;
      vsPaan := NULL;
      vsSexo := NULL;

      begin
          select swmspbr_program_alumno,
                 swmspbr_paav_alumno,
                 swmspbr_paan_alumno,
                 swmspbr_sexo_alumno
            into vsProg, vsPaav, vsPaan, vsSexo
            from swmspbr
           where swmspbr_camp_code   = vsCamp
             and swmspbr_term_code   = vsTerm
             and swmspbr_pidm_alumno = pnPidm;
      exception
          when others then
               null;
      end;
  end p_GrdeAdm;

  BEGIN
      -- valida que el usuario pertenezca a la base de datos
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      vsCamp := pk_objHTML.getValueCookie('psSprUn');
      vsEncu := pk_objHTML.getValueCookie('psSeprd');
      vsTerm := pk_objHTML.getValueCookie('psSprTD');
      vsColl := pk_objHTML.getValueCookie('psSprCo');
      vsPtrm := pk_objHTML.getValueCookie('psPtrmP');
      vsRate := pk_objHTML.getValueCookie('psRatS');
      vsExcel := PK_ObjHTML.getValueCookie('reporteEnExcel');

      IF vsExcel = 'EXCELL' THEN
         owa_util.mime_header('application/ms-excel',true);
         owa_util.http_header_close;
      END IF;

      -- ejecuta procesos para minimizar tiempo
      PWAISSBSECT(vsCamp,vsTerm,vsColl,vsSubjCode,vsSstsCode,vsPtrm);
      PWARSEPRAD(vsTerm,vsEncu,vsRate);

      FOR regRea IN cuReactivos(vsEncu) LOOP
         vnReac := vnReac + cn1;
         tabReac(vnReac).qcodCode := regRea.qcodCode;
         tabReac(vnReac).qcodDesc := regRea.qcodDesc;
         tabReac(vnReac).teqaCode := regRea.teqaCode;
      END LOOP;

      htp.p('<html><head><title>'||psReclDesc||'</title>' );



      -- la aplicación no se guarda en el cache de la máquina
      PK_ObjHTML.P_NoCache;

      -- código css
      PK_ObjHTML.P_CssTabs;

      htp.p('<script language="JavaScript"><!--');
      htp.p('function fImprimeReporte() {
      window.focus()
      print();
      }');
      htp.p('//--></script>');

      htp.p('</head><body bgcolor="#ffffff" class="bodyCeroR"><br/>');

      htp.p('<script language="javascript" src="kwacnls.js"></script>');

      htp.p('<table border="0" cellpadding="2" cellspacing="1" bordercolor="#ffffff" bgcolor="#ffffff" width="100%">
      <tr class="trTabSepara">
          <td rowspan="4" width="10%" valign="top"><img src="/imagenes/logo_uft.jpg'||'" width="80" border="0"></td>
          <td colspan="2" align="left" valign="top" class="tdTitulo"><b>'||
           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(psReclDesc,'~aacute','&aacute'),'~eacute','&eacute'),'~iacute','&iacute'),'~oacute','&oacute'),'~uacute','&uacute')
           ||' - '||vsTerm||'</b></td>
          </tr>
      <tr class="trTabSepara"><td valign="top" width="70%">'||pK_Seprad1.F_Fecha||'</td>
                              <td valign="top" width="30%" align="right"></td></tr>
      <tr class="trTabSepara"><td colspan="2"></td></tr>
      <tr class="trTabSepara"><td colspan="2"></td></tr>
      </table><br/>');

      htp.p('<table border="1" width="100%">');
      htp.p('<tr><td colspan="24"  '||PK_ObjHTML.vgsBorderDDDDDD||'></td>');

      FOR vnI IN cn1..vnReac LOOP
          htp.p('<td bgcolor="#efefef" valign="bottom" class="tdFont7"  '||PK_ObjHTML.vgsBorderDDDDDD||'>'||tabReac(vnI).qcodDesc||'</td>');
      END LOOP;

      htp.p('</tr>
      <tr bgcolor="#efefef">
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>No.</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Campus</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Sede</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Sede_descr</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Parte de periodo</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Cve_Esc_Materia</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Desc_Esc_Materia</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Cve_Programa_Alumno</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Desc_Programa_Alumno</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Exp_Profesor</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Pers_Suffix</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Nombre_Profesor</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Sexo_Profesor</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Cve_Contrato_Profesor</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Desc_Contrato_Profesor</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Cve_Nivel_Acad_Profesor</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Desc_Nivel_Acad_Profesor</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Cve_Materia</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Nombre_Materia</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Tipo_Materia</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>CRN     </td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>PAA Verbal</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>PAA Numérica</td>
      <td valign="bottom" '||PK_ObjHTML.vgsBorderDDDDDD||'>Sexo Alumno</td>');

      FOR vnI IN cn1..vnReac LOOP
          htp.p('<td valign="bottom" class="tdFont7"  '||PK_ObjHTML.vgsBorderDDDDDD||'>'||tabReac(vnI).qcodCode||'</td>');
      END LOOP;

      htp.p('</tr>');


      FOR regBrut IN cuBruto LOOP
             vnRow  := vnRow + cn1;

             IF vnPidmA IS NULL OR vnPidmA <> regBrut.PidA THEN
                p_GrdeAdm(regBrut.PidA);

                vsPro2 := vsProG;
             ELSE
                vsProG := vsPro2;
             END IF;

             vsProgCode := SUBSTR(vsProg,cn1,INSTR(vsProg,csArrB) - cn1);
                 vsProg := SUBSTR(vsProg,    INSTR(vsProg,csArrB) + cn1);

             vsProgDesc := SUBSTR(vsProg,cn1,INSTR(vsProg,csArrB) - cn1);
                 vsProg := SUBSTR(vsProg,    INSTR(vsProg,csArrB) + cn1);

--             vsProgVpdi := SUBSTR(vsProg,cn1,INSTR(vsProg,csArrB)- cn1);
--                 vsProg := SUBSTR(vsProg,  INSTR(vsProg,csArrB)+ cn1);
--             vsSedeCode := SUBSTR(vsProg,  INSTR(vsProg,csArrB)+ cn1);

             IF vsProgCode IS NULL THEN
                vsProgCode := '<b><font color="#ff0000" size="4">'||regBrut.PidA||'</font></b>';
             END IF;

             htp.p('<tr>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top" align="right">'||vnRow||'.</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||f_CampDesc(regBrut.Camp)||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||vsSedeCode||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||pk_catalogo.fstvrate(vsSedeCode)||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||regBrut.Ptrm                       ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||regBrut.Coll                       ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||f_CollDesc(regBrut.Coll)||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||vsProgCode                         ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||vsProgDesc                         ||'</td>
             '                 ||F_IdNameFaculty(regBrut.Faculty)   ||'
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||FWRSEXO(regBrut.Faculty)           ||'</td>
             '                 ||F_TipoContrato(regBrut.Faculty)    ||'
             '                 ||F_GradoAcademico(regBrut.Faculty)  ||'
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||regBrut.Subj  ||' '||regBrut.Crse  ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||regBrut.Titulo                     ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||F_TipoMateria(regBrut.Tipo)        ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||regBrut.Crn                        ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||vsPaav                             ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||vsPaan                             ||'</td>
             <td '||PK_ObjHTML.vgsBorderDDDDDD||' valign="top">'||vsSexo                             ||'</td>
             ');

             FOR vnI IN cn1..vnReac LOOP
                 vsNoAplica := f_qpoints(regBrut.Term, regBrut.Crn, regBrut.PidB, regBrut.Faculty, tabReac(vnI).qcodCode,vsEncu);

                 -- se realiza la cuenta de las evaluaciones "no aplica"
                 IF tabReac(vnI).teqaCode IN(csPlanea,csHabil,csEvalua,csRasgos,csIdentif,csVgp,csVgc) THEN
                    vnNoAplica := vnNoAplica + TO_NUMBER(vsNoAplica);
                 END IF;

                 htp.prn('<td valign="top" '||PK_ObjHTML.vgsBorderDDDDDD);

                 IF tabReac(vnI).teqaCode = csComment THEN
                    htp.prn(' class="tdFont7" ');
                 ELSE
                    htp.prn(' align="center" ');
                 END IF;

                 htp.prn('>'||vsNoAplica||'</td>');
             END LOOP;

             htp.prn('</tr>');

             IF vnNoAplica = cnCero THEN
                vnNoAplTot := vnNoAplTot + cn1;
             END IF;

            vnPidmA    := regBrut.PidA;
            vsCampCode := regBrut.Camp;
            vsCollCode := regBrut.Coll;
            vnPidmFclt := regBrut.Faculty;
            vsTipoCode := regBrut.Tipo;
            vnNoAplica := cnCero;
      END LOOP;

      htp.p('</table><br/><br/></body></html>');

      ROLLBACK;

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P(SQLERRM);
  END PWRARCH;
/


DROP PUBLIC SYNONYM PWRARCH;

CREATE PUBLIC SYNONYM PWRARCH FOR BANINST1.PWRARCH;


GRANT EXECUTE ON BANINST1.PWRARCH TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWRARCH TO WWW2_USER;

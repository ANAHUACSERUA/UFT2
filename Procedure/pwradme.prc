CREATE OR REPLACE PROCEDURE baninst1.PWRADME(psReclDesc VARCHAR2) IS
/*
   Tarea: Reporte de archivos de datos del "Motor de encuestas"
   Fecha: 22/11/2010
   Autor: MAC
  Modulo: Motor de encuestas

modify: vic...
date      22-oct-2014
se le agrega el campo de escuela al reporte



*/
  TYPE t_Record IS RECORD (rAcod VARCHAR2(10),
                           rQcod VARCHAR2(10),
                           rAnsw VARCHAR2(10),
                           rMaxw INTEGER,
                           rGvbq CLOB,
                           rWeid VARCHAR2(10),
                           rGsrc VARCHAR2(20)
                          );

  TYPE t_Table IS TABLE OF t_Record INDEX BY BINARY_INTEGER;

  vsUnive     VARCHAR2(6)     := NULL;
  vsEncst     VARCHAR2(20)    := NULL;
  vnNmRfE     INTEGER         := NULL;
  vsPerio     VARCHAR2(6)     := NULL;
  vsAccpr     VARCHAR2(20)    := NULL;
  vsEscul     VARCHAR2(2)     := NULL;
  vsDescEncst VARCHAR2(300)   := NULL;

  tabReac     t_Table;
  vsId        VARCHAR2(10)  := NULL;
  vsFecha     VARCHAR2(10)  := NULL;
  vsProgCode  VARCHAR2(20)  := NULL;
  vsProgDesc  VARCHAR2(300) := NULL;
  vsLevlCode  VARCHAR2(3)   := NULL;
  vsCollDesc  VARCHAR2(300) := NULL;
  vsRateCode  VARCHAR2(6)   := NULL;
  vsErned     VARCHAR2(20)  := NULL;
  vsOverall   VARCHAR2(20)  := NULL;
  vsCredito   VARCHAR2(20)  := NULL;
  vsAsnw      VARCHAR2(10)  := NULL;
  vsRate      VARCHAR2(6)   := NULL;
  vnEdad      NUMBER        := 0;
  vnRow       INTEGER       := 0;
  vnReg       INTEGER       := 0;
  vnTDwidth   INTEGER       := 0;
  vnWithTd    INTEGER       := 100;
  vnWit2Td    INTEGER       := 300;
  vnWithTable INTEGER       := 100;

  csSIN CONSTANT VARCHAR2(3) := 'SIN';

  vscole     varchar2(80);

  Cursor cuReactivo(pnSrnn INTEGER,
                    psGsrc VARCHAR2) IS
         SELECT GVRASDF_SORT_NUM  SORR,
                GVRASDF_QCOD_CODE QCOD,
                (SELECT GVBQCOD_DESC
                   FROM GVBQCOD
                  WHERE GVBQCOD_CODE = GVRASDF_QCOD_CODE
                )                 GVBQ,
                (SELECT GVBQCOD_ACOD_CODE
                   FROM GVBQCOD
                  WHERE GVBQCOD_CODE = GVRASDF_QCOD_CODE
                )                 ACOD,
                DECODE(GVRASDF_WEIGHT+
                 GVRASDF_TOTAL_SCORE,0,'COMENT',NULL) Weid,
                (SELECT 'Y'
                   FROM GVRSDEF
                  WHERE GVRSDEF_GSRC_CODE_REF_IND = 'Y'
                    AND GVRSDEF_QCOD_CODE        = GVRASDF_QCOD_CODE
                    AND GVRSDEF_GSRC_CODE        = psGsrc
                ) SubE
           FROM GVRASDF
          WHERE GVRASDF_GSRC_CODE = psGsrc
            AND GVRASDF_SRN       = pnSrnn
          ORDER BY GVRASDF_SORT_NUM;

  Cursor cuReactiv2(pnSrnn INTEGER,
                    psGsrc VARCHAR2) IS
         SELECT GVRASDF_SORT_NUM  SORR,
                GVRASDF_QCOD_CODE QCOD,
                (SELECT GVBQCOD_DESC
                   FROM GVBQCOD
                  WHERE GVBQCOD_CODE = GVRASDF_QCOD_CODE
                )                 GVBQ,
                (SELECT GVBQCOD_ACOD_CODE
                   FROM GVBQCOD
                  WHERE GVBQCOD_CODE = GVRASDF_QCOD_CODE
                )                 ACOD,
                DECODE(GVRASDF_WEIGHT+
                 GVRASDF_TOTAL_SCORE,0,'COMENT',NULL) Weid,
                (SELECT 'Y'
                   FROM GVRSDEF
                  WHERE GVRSDEF_GSRC_CODE_REF_IND = 'Y'
                    AND GVRSDEF_QCOD_CODE        = GVRASDF_QCOD_CODE
                    AND GVRSDEF_GSRC_CODE        = psGsrc
                ) SubE
           FROM GVRASDF
          WHERE GVRASDF_GSRC_CODE = psGsrc
            AND GVRASDF_SRN       = pnSrnn
          ORDER BY GVRASDF_SORT_NUM;

  CURSOR cuArchivo(pnSrnn INTEGER,
                   psQcod VARCHAR2,
                   pnPidm NUMBER) IS
         SELECT GVBGSED_PVAC_QPOINTS PVAC,
                GVBGSED_OPEN_ANSWER  OPIN,
                GVBGSED_PVAC_SEQ_NUM SEQN
           FROM GVBGSED
          WHERE GVBGSED_QCOD_CODE      = psQcod
            AND GVBGSED_SRAS_TEMP_PIDM = pnPidm
            AND GVBGSED_SRN            = pnSrnn;

  CURSOR cuEncuestados(pnSrnn INTEGER,
                       psRate VARCHAR2
                      ) IS
         SELECT
         c.SPRIDEN_ID ID,
         c.SPRIDEN_LAST_NAME||' '||c.SPRIDEN_FIRST_NAME NOMBRE,
         SPBPERS_NAME_SUFFIX sufijo,
         GVRSRAS_SPIDM                    Pidm,
                GVRSRAS_TEMP_PIDM                    Temp,
                DECODE(GVRSRAS_STATUS_IND,
                        'P','Pendiente',
                        'I','Proceso',
                        'C','Completada',NULL) Status
           FROM SPRIDEN C, SPBPERS B, GVRSRAS
            WHERE
            C.SPRIDEN_PIDM = B.SPBPERS_PIDM
            AND C.SPRIDEN_CHANGE_IND IS NULL
            AND C.SPRIDEN_PIDM = GVRSRAS_SPIDM
            AND GVRSRAS_SRN = pnSrnn
                AND (
                    EXISTS (SELECT NULL
                               FROM SGBSTDN A
                              WHERE A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                                                 FROM SGBSTDN B
                                                                WHERE B.SGBSTDN_PIDM = A.SGBSTDN_PIDM
                                                              )
                                AND A.SGBSTDN_PIDM          = GVRSRAS_SPIDM
                                AND NVL(A.SGBSTDN_RATE_CODE,csSIN) = psRate
                           )

                 OR
                    psRate IS NULL
                )
          ORDER BY Status;

  CURSOR cuAnswer(psAcod VARCHAR2) IS
         SELECT REPLACE(REPLACE(GVRPVAC_DESC,'<P ALIGN=Center>',NULL),'<br>',NULL) pvacDesc,
                GVRPVAC_QPOINTS pvacQpoi
           FROM GVRPVAC
          WHERE GVRPVAC_ACOD_CODE = psAcod
          ORDER BY GVRPVAC_SEQ_NUM;

  --subencuesta
  CURSOR cuSubEnc(vsGsrc VARCHAR2,
                  vsQcod VARCHAR2) IS
         SELECT GVRSREL_GSRC_CODE_REF GSRC
           FROM GVRSREL
          WHERE GVRSREL_GSRC_CODE = vsGsrc
            AND GVRSREL_QCOD_CODE = vsQcod;

----cursor que obtiene elnombre de la escuela      vic...
cursor cu_colegios  ( vspidm  VARCHAR2,  vsterm  VARCHAR2) IS
   select LL.STVCOLL_DESC   as  colegio
   from SIRDPCL dp, stvcoll ll
   where DP.SIRDPCL_COLL_CODE = LL.STVCOLL_CODE
   and  DP.SIRDPCL_PIDM  = vspidm
   and  DP.SIRDPCL_TERM_CODE_EFF  = (select max(cl.SIRDPCL_TERM_CODE_EFF)  from SIRDPCL cl
                                                                    where CL.SIRDPCL_TERM_CODE_EFF  <=    vsterm
                                                                    and    CL.SIRDPCL_PIDM   =  DP.SIRDPCL_PIDM);
   
   
   
  -- obtiene el campus del encuestado
  function f_Campus(pnPidm number) return varchar2 is

  vsCampDesc     stvcamp.stvcamp_desc%type := null;
  vsVpdiAnterior varchar2(10)              := NULL;

  cursor cuCamp is
         select stvcamp_code campCode
           from stvcamp;

  begin
      vsVpdiAnterior := sys_context('g$_vpdi_home_context','vpdi_home_code');
      vsProgCode     := null;
      vsProgDesc     := null;
      vsLevlCode     := null;
      vsCollDesc     := null;
      vsRateCode     := null;
      vsErned        := null;
      vsOverall      := null;
      vsCredito      := null;

      begin
          select pk_Catalogo.universidad(a.sgbstdn_camp_code),
                 sgbstdn_program_1,
                 pk_Catalogo.programa(sgbstdn_program_1),
                 sgbstdn_levl_code,
                 sgbstdn_rate_code
            into vsCampDesc,
                 vsProgCode,
                 vsProgDesc,
                 vsLevlCode,
                 vsRateCode
            from sgbstdn a
           where a.sgbstdn_term_code_eff = (select max(b.sgbstdn_term_code_eff)
                                              from sgbstdn b
                                             where b.sgbstdn_pidm = pnPidm
                                             and b.sgbstdn_term_code_eff <= vsPerio
                                           )
             and a.sgbstdn_pidm          = pnPidm;
      exception
          when others then
               null;
      end;

      if vsCampDesc is null then
         for regCmp in cuCamp loop
             if vsCampDesc is null then
                g$_vpdi_security.g$_vpdi_set_home_context(regCmp.campCode);

                begin
                    select pk_Catalogo.universidad(a.sgbstdn_camp_code),
                           sgbstdn_program_1,
                           pk_Catalogo.programa(sgbstdn_program_1),
                           sgbstdn_levl_code,
                           sgbstdn_rate_code
                      into vsCampDesc,
                           vsProgCode,
                           vsProgDesc,
                           vsLevlCode,
                           vsRateCode
                      from sgbstdn a
                     where a.sgbstdn_term_code_eff = (select max(b.sgbstdn_term_code_eff)
                                                        from sgbstdn b
                                                       where b.sgbstdn_pidm = pnPidm
                                                       and b.sgbstdn_term_code_eff <= vsPerio
                                                     )
                       and a.sgbstdn_pidm          = pnPidm;
                exception
                    when others then
                         null;
                end;

             end if;
         end loop;

         g$_vpdi_security.g$_vpdi_set_home_context(vsVpdiAnterior);

      end if;

      begin
          select smbpgen_req_credits_overall
            into vsOverall
            from smbpgen
           where smbpgen_program = vsProgCode;
      exception
          when others then
               null;
      end;

      begin
          select pk_Catalogo.colegio(smrprle_coll_code)
            into vsCollDesc
            from smrprle
           where smrprle_program = vsProgCode;
      exception
          when others then
               null;
      end;

      --creditos ganados
      begin
          select decode(sum(nvl(a.shrtgpa_hours_earned,0)),0,null,sum(nvl(a.shrtgpa_hours_earned,0)))
            into vsErned
            from shrtgpa a
           where a.shrtgpa_pidm       = pnPidm
             and a.shrtgpa_levl_code  = vsLevlCode
             and a.shrtgpa_term_code <= vsPerio;
      exception
          when others then
               null;
      end;

      begin
          select sum(NVL(sfrstcr_credit_hr,0))
            into vsCredito
            from sfrstcr
           where sfrstcr_rsts_code in ('RE','RW')
             and sfrstcr_term_code  = vsPerio
             and sfrstcr_pidm       = pnPidm;
      exception
          when others then
               null;
      end;

      return vsCampDesc;

  exception
      when no_data_found then
           g$_vpdi_security.g$_vpdi_set_home_context(vsVpdiAnterior);
           return null;
      when others then
           g$_vpdi_security.g$_vpdi_set_home_context(vsVpdiAnterior);
           return null;
  end f_Campus;

  -- obtiene el sexo de la persona
  function f_Sexo(pnPidm number) return varchar2 is

  vsSexo  varchar2(20) := null;
  vsEdad  varchar2(10) := null;

  begin

      select decode(spbpers_sex,'F','Femenino','M','Masculino','No disponible'),
             to_char(spbpers_birth_date,'dd/mm/yyyy'),
             to_char(spbpers_birth_date,'yyyymmdd')
        into vsSexo,
             vsFecha,
             vsEdad
        from spbpers
       where spbpers_pidm = pnPidm;

      if vsEdad is not null then
         vnEdad := trunc((to_number(to_char(sysdate,'yyyymmdd')) - to_number(vsEdad))/10000);
      end if;

      return vsSexo;

  exception
      when no_data_found then
           return vsSexo;
      when others then
           return vsSexo;
  end f_Sexo;

  function f_Points(pnSrnn integer,
                    psQcod varchar2,
                    pnPidm number,
                    psAnsw varchar2,
                    pnMaxw integer,
                    psAcod varchar2,
                    psAco2 varchar2) return varchar2 is

  type tablePoints is table of number;

  tabPont  tablePoints  := tablePoints(1);
  vnPoints number(10,4) := null;
  vsAnswer clob         := null;
  vnSequen integer      := null;

  begin
      if 'COMENT' in (psAco2, psAcod) then
         htp.p('<td valign="top" width="'||vnWithTD||'px;">');
      else
         htp.p('<td align="center" valign="top">');
      end if;

      if psAnsw = 'MS' then
         for vnI in 1..pnMaxw loop
             tabPont.extend(vnI);
             tabPont(vnI) := null;
         end loop;

         vnTDwidth := 100/pnMaxw;

         htp.p('
         <table border="0" cellpadding="0" cellspacing="0" width="100%">
         <tr>
         ');
      end if;

      for regArh in cuArchivo(pnSrnn, psQcod, pnPidm) loop
          vnPoints := regArh.pvac;
          vsAnswer := regArh.opin;
          vnSequen := regArh.seqn;

          if psAnsw = 'MS' then
             tabPont(vnSequen) := vnPoints;
          else
             if 'COMENT' in (psAco2, psAcod) then
                htp.p(vsAnswer);
             else
                htp.p(vnPoints);
             end if;
          end if;

      end loop;

      if psAnsw = 'MS' then
         for vnI in 1..pnMaxw loop
             htp.p('
             <td width="'||vnTDwidth||'%" valign="top">
             '||tabPont(vnI)||'
             </td>');
         end loop;

         htp.p('</tr></table>');
      end if;

      htp.p('</td>');

      return null;
  end f_Points;

  function f_AsnMax(psAcod varchar2,
                    psAsnw in out varchar2) return integer is

  vnMaxw INTEGER := 0;

  begin
      psAsnw := NULL;

      begin
          select gvvacod_answ
            into psAsnw
            from gvvacod
           where gvvacod_code = psAcod;
      exception
          when others then
               null;
      end;

      if psAsnw = 'MS' then
         begin
             select max(gvrpvac_seq_num)
               into vnMaxw
               from gvrpvac
              where gvrpvac_acod_code = psAcod;
         exception
             when others then
                  null;
         end;
      end if;

      return vnMaxw;

  end f_AsnMax;

  BEGIN
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;
         htp.p('<script language="javascript" src="kwacnls.js"></script>');

      --son buscadas los valores de las cookies para asignar los valores del filtro del query.
      vsRate  := pk_objHTML.getValueCookie('psRatS');
      vsUnive := pk_objHTML.getValueCookie('psUnive');
      vsEncst := pk_objHTML.getValueCookie('psEncst');
      vnNmRfE := pk_objHTML.getValueCookie('psNmRfE');
      vsPerio := pk_objHTML.getValueCookie('psTerm');
      vsAccpr := pk_objHTML.getValueCookie('psAccpr');
      vsEscul := pk_objHTML.getValueCookie('psEscu');

      SELECT GVVGSRC_DESC
        INTO vsDescEncst
        FROM GVVGSRC
       WHERE GVVGSRC_CODE = vsEncst;

      FOR regReac IN cuReactivo(vnNmRfE, vsEncst) LOOP
          vnRow := vnRow + 1;

          tabReac(vnRow).rAcod := regReac.Acod;
          tabReac(vnRow).rQcod := regReac.Qcod;
          tabReac(vnRow).rGvbq := regReac.Gvbq;
          tabReac(vnRow).rWeid := regReac.Weid;
          tabReac(vnRow).rGsrc := vsEncst;

          IF regReac.SubE = 'Y' THEN
             FOR regSub IN cuSubEnc(vsEncst, regReac.Qcod) LOOP
                 FOR regSubE IN cuReactiv2(vnNmRfE, regSub.GSRC) LOOP
                     vnRow := vnRow + 1;

                     tabReac(vnRow).rAcod := regSubE.Acod;
                     tabReac(vnRow).rQcod := regSubE.Qcod;
                     tabReac(vnRow).rGvbq := regSubE.Gvbq;
                     tabReac(vnRow).rWeid := regSubE.Weid;
                     tabReac(vnRow).rGsrc := regSub.GSRC;
                 END LOOP;
             END LOOP;
          END IF;
      END LOOP;

      FOR vnI IN 1..vnRow LOOP
          vsAsnw             :=  NULL;
          tabReac(vnI).rMaxw := f_AsnMax(tabReac(vnI).rAcod, vsAsnw);
          tabReac(vnI).rAnsw := vsAsnw;
      END LOOP;

      vnWithTable := (vnWithTD * 14) + (vnWit2Td * vnRow);

      htp.p('<html><head><title>&nbsp;</title>');

      -- la aplicación no se guarda en el cache de la maquina.
      pk_objHTML.P_NoCache;

      --código css
      pk_objHTML.P_CssTabs;

      htp.p('<script language="JavaScript"><!--');
      htp.p('function fImprimeReporte() {
      window.focus()
      print();
      }');
      htp.p('--></script>');

      htp.p('</head><body bgcolor="#ffffff" class="bodyCeroR"><br/>
      <table border="0" cellpadding="2" cellspacing="1" width="100%" bgcolor="#ffffff" bordercolor="#ffffff">
      <tr><td width="10%" rowspan="3"><img src="/imagenes/logo_uft.jpg" border="0" width="80"/></td>
          <td width="90%" class="tdTitulo"><b>&nbsp;&nbsp;'||vsDescEncst||' ('||vsEncst||'), NRE: '||vnNmRfE||', Periodo:'||vsPerio||'</td></tr>
      <tr><th align="left">&nbsp;&nbsp;'||psReclDesc||'</th></tr>
      <tr><td>&nbsp;&nbsp;'||pK_Seprad1.F_Fecha||'</td></tr>
      <tr><td colspan="2">&nbsp;</td>
      </table>

      <table border="1" width="'||vnWithTable||'px;" >
      <tr><th colspan="12" bgcolor="#efefef" '||pk_objHTML.vgsBorderDDDDDD||' align="right">C&Oacute;DIGO DE LA ENCUESTA</th>
      ');

      FOR vnI IN 1..vnRow LOOP
          htp.p('<th bgcolor="#efefef" '||pk_objHTML.vgsBorderDDDDDD||'>'||tabReac(vnI).rGsrc||'</th>');
      END LOOP;

      htp.p('
          </tr>
      <tr bgcolor="#efefef">
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>No. Registro                               </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Estatus de la encuesta                     </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Campus                                     </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Programa                                   </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Descripci&oacute;n del programa            </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Id                                         </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Nombre                                     </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Rut                                        </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Escuela o Facultad del programa            </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Sede                                       </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Sede - Descripci&oacute;n                  </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>No. Cr&eacute;ditos del programa           </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>No. Cr&eacute;ditos ganados por el alumno  </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>No. Cr&eacute;ditos inscritos por el alumno</th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Sexo                                       </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Fecha de nacimiento                        </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Edad                                       </th>
      <th valign="bottom" align="left" width="'||vnWithTD||'px;" rowspan="3" '||pk_objHTML.vgsBorderDDDDDD||'>Escuela de Docencia                         </th>    
      ');

      FOR vnI IN 1..vnRow LOOP
          SELECT DECODE(tabReac(vnI).rMaxw,0,2,tabReac(vnI).rMaxw)
            INTO vnTDwidth
            FROM DUAL;

          htp.p('<th valign="bottom" align="left" '||pk_objHTML.vgsBorderDDDDDD||'>
          <table border="0" cellpadding="0" cellspacing="0" width="100%">
          <tr><td colspan="'||vnTDwidth||'">'||tabReac(vnI).rAcod||'</td></tr>
          ');

          IF tabReac(vnI).rAnsw = 'MS' THEN
             vnTDwidth := 100/tabReac(vnI).rMaxw;

             htp.p('<tr>');

             FOR regAns IN cuAnswer(tabReac(vnI).rAcod) LOOP
                 htp.p('<td width="'||vnTDwidth||'%" class="tdFont7">'||regAns.pvacDesc||'</td>');
             END LOOP;

             htp.p('</tr><tr>');

             FOR regAns IN cuAnswer(tabReac(vnI).rAcod) LOOP
                 htp.p('<td>'||regAns.pvacQpoi||'</td>');
             END LOOP;

             htp.p('</tr>');

          ELSE
             FOR regAns IN cuAnswer(tabReac(vnI).rAcod) LOOP
                 htp.p('<tr><td width="70%">'||regAns.pvacDesc||'</td><td width="30%">'||regAns.pvacQpoi||'</td></tr>');
             END LOOP;
          END IF;

          htp.p('</table>');

      END LOOP;

      htp.p('</tr><tr bgcolor="#efefef">');

      FOR vnI IN 1..vnRow LOOP
          htp.p('<th valign="bottom" align="left" '||pk_objHTML.vgsBorderDDDDDD||' width="'||vnWit2Td||'px;">'||tabReac(vnI).rGvbq||'</th>');
      END LOOP;

      htp.p('</tr><tr bgcolor="#efefef">');

      FOR vnI IN 1..vnRow LOOP
          htp.p('<th valign="bottom" '||pk_objHTML.vgsBorderDDDDDD||' >'||tabReac(vnI).rQcod||'</th>');
      END LOOP;

      htp.p('</tr>');

      FOR regEnc IN cuEncuestados(vnNmRfE, vsRate) LOOP
          vnReg := vnReg + 1;
          
          vscole  := null;
          FOR  regCol  in cu_colegios(regEnc.Pidm,vsPerio) LOOP
               vscole  := regCol.colegio;
          END LOOP;     
          

          htp.p('
          <tr>
          <td valign="top" align="right"  '||pk_objHTML.vgsBorderDDDDDD||'>'||vnReg                ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||regEnc.Status        ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||f_Campus(regEnc.Pidm)||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||vsProgCode           ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||vsProgDesc           ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||regEnc.Id            ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||regEnc.Nombre        ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||regEnc.Sufijo           ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||vsCollDesc           ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||vsRateCode           ||'</td>
          <td valign="top" align="left"   '||pk_objHTML.vgsBorderDDDDDD||'>'||pk_catalogo.fstvrate(vsRateCode)||'</td>
          <td valign="top" align="center" '||pk_objHTML.vgsBorderDDDDDD||'>'||vsOverall            ||'</td>
          <td valign="top" align="center" '||pk_objHTML.vgsBorderDDDDDD||'>'||vsErned              ||'</td>
          <td valign="top" align="center" '||pk_objHTML.vgsBorderDDDDDD||'>'||vsCredito            ||'</td>
          <td valign="top" align="center" '||pk_objHTML.vgsBorderDDDDDD||'>'||f_Sexo(regEnc.Pidm)  ||'</td>
          <td valign="top" align="center" '||pk_objHTML.vgsBorderDDDDDD||'>'||vsFecha              ||'</td>
          <td valign="top" align="center" '||pk_objHTML.vgsBorderDDDDDD||'>'||vnEdad               ||'</td>
          <td valign="top" align="center" '||pk_objHTML.vgsBorderDDDDDD||'>'||vscole               ||'</td>
          ');

          FOR vnI IN 1..vnRow LOOP
              htp.p(f_Points(vnNmRfE, tabReac(vnI).rQcod, regEnc.Temp, tabReac(vnI).rAnsw, tabReac(vnI).rMaxw, tabReac(vnI).rAcod, tabReac(vnI).rWeid));
          END LOOP;

          htp.p('
          </tr>
          ');
      END LOOP;

      htp.p('</table>
      <br/>
      <br/>
      </body></html>
      ');
  EXCEPTION
      WHEN OTHERS THEN
           htp.p(sqlerrm);
  END PWRADME;
/

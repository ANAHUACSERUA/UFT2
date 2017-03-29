DROP PROCEDURE BANINST1.PWAHIAC;

CREATE OR REPLACE PROCEDURE BANINST1.PWAHIAC(pnPidm     NUMBER,
                                             psPrograma VARCHAR2,
                                             psNivel    VARCHAR2,
                                             psMayab    VARCHAR2 DEFAULT NULL,
                                             psMatEx    VARCHAR2 DEFAULT NULL
                                            ) IS

  /*
            TAREA: Realizar la consulta para los diferentes reprotes de Historia academica
                   PWRHIAC, PWRHAMY, PWRHIPG
            FECHA: 01/04/2010
            AUTOR: GEPC

     MODIFICACION: 26/01/2011
                   GEPC
                   * Se crearon las tablas temporales "SWRDOCN" y "SWRDOUS", para actualizar valores
                     de historia académica.

     MODIFICACION: 28/01/2011
                   GEPC
                   * Se actualiza la prioridad del BLOQUE ELECTIVO.

     MODIFICACION: 22/03/2011
                   LPV
                   * Se agrego la condición para el campo "csLevlCode", esto con el fin de que se tomen en cuenta todo el posgrado.

                                              and (
                                                     (
                                                          nvl(z.smrdocn_levl_code,csLevlCode) = csLevlCode
                                                      and
                                                          psNivel = csLIC
                                                     )
                                                  or
                                                     (
                                                          nvl(z.smrdocn_levl_code,csLevlCode) IN (csLevlCode,csES)
                                                      and
                                                          psNivel = csPOS
                                                     )
                                                  )

     MODIFICACION: 22/03/2011
                   LPV
                   * Corregir cerocreditos con extraordinario aprobado

     MODIFICACION: 02/06/2011
                   LPV
                   * Se cambio la sentancia del subquery reprobadasConCreditos, "por min(to_number(".
                   * Se agrego el parametro psMayab, para la parte de eliminar SWRDOCN (SMRDOCN_REPEAT_COURSE_IND = E y SMRDOCN_GMOD_CODE = N.
                   * Se agrego en el cursor aprobadasConCreditos el filtro para que existan en SHRTCKN (caso 00300063 MER3108).

     MODIFICACION: 20/06/2011
                   LPV
                   * Se agrego en el cursor materiasCeroCreditos, el filtro de que sean iguales los CRN.

     MODIFICACION: 24/10/2011
                   LPV
                   * Se agrego el parametro psMatEx para el reporte Historia académica (Posgrado)



  */

  vnPriority SWRCAPP.SWRCAPP_AREA_PRIORITY%TYPE := NULL;

  csPrograma  CONSTANT VARCHAR2(20) := psPrograma;
  csBloqueElc CONSTANT VARCHAR2(15) := 'BLOQUE ELECTIVO';
  csLevlCode  CONSTANT VARCHAR2(2)  := SUBSTR(psPrograma,1,2);
  csOtros     CONSTANT VARCHAR2(5)  := 'OTROS';
  csAsesores  CONSTANT VARCHAR2(8)  := 'ASESORES';
  csBloque    CONSTANT VARCHAR2(6)  := 'BLOQUE';
  csCN        CONSTANT VARCHAR2(2)  := 'CN';
  csUS        CONSTANT VARCHAR2(2)  := 'US';
  csOT        CONSTANT VARCHAR2(2)  := 'OT';
  csOU        CONSTANT VARCHAR2(2)  := 'OU';
  csPO        CONSTANT VARCHAR2(2)  := 'PO';
  csAC        CONSTANT VARCHAR2(2)  := 'AC';
  csAD        CONSTANT VARCHAR2(2)  := 'AD';
  csLIC       CONSTANT VARCHAR2(3)  := 'lic';
  csPOS       CONSTANT VARCHAR2(3)  := 'pos';
  csES        CONSTANT VARCHAR2(2)  := 'ES';
  csR         CONSTANT VARCHAR2(1)  := 'R';
  csH         CONSTANT VARCHAR2(1)  := 'H';
  csF         CONSTANT VARCHAR2(1)  := 'F';
  csP         CONSTANT VARCHAR2(1)  := 'P';
  csE         CONSTANT VARCHAR2(1)  := 'E';
  csX         CONSTANT VARCHAR2(1)  := 'X';
  csN         CONSTANT VARCHAR2(1)  := 'N';
  csI         CONSTANT VARCHAR2(1)  := 'I';
  cs4         CONSTANT VARCHAR2(1)  := '4';
  csNull      CONSTANT VARCHAR2(1)  := NULL;
  csTilde     CONSTANT VARCHAR2(2)  := '~';
  cs10        CONSTANT VARCHAR2(2)  := '10';
  cs20        CONSTANT VARCHAR2(2)  := '20';
  cs30        CONSTANT VARCHAR2(2)  := '30';
  cs40        CONSTANT VARCHAR2(2)  := '40';
  cn0         CONSTANT INTEGER      := 0;
  cn1         CONSTANT INTEGER      := 1;
  cn6         CONSTANT INTEGER      := 6;
  cn999       CONSTANT INTEGER      := 999;
  cn500       CONSTANT INTEGER      := 500;

  --Son registrados los cursos usados
  procedure cursosUsados is

  cursor cuLCnull is
         select l.shrtckl_levl_code       as levlCode,
                g.shrtckg_gmod_code       as gmodCode,
                g.shrtckg_credit_hours    as credHour,
                g.shrtckg_grde_code_final as grdeCode,
                n.shrtckn_seq_no          as tcknSeqn,
                n.shrtckn_crn             as tcknCrnn,
                n.shrtckn_term_code       as termCode,
                n.shrtckn_pidm            as tcknPidm
           from shrtckn n,
                shrtckg g,
                shrtckl l
          where g.shrtckg_pidm         = n.shrtckn_pidm
            and g.shrtckg_term_code    = n.shrtckn_term_code
            and g.shrtckg_tckn_seq_no  = n.shrtckn_seq_no
            and g.shrtckg_seq_no       = (select max(g1.shrtckg_seq_no)
                                            from shrtckg g1
                                           where g1.shrtckg_pidm        = g.shrtckg_pidm
                                             and g1.shrtckg_term_code   = g.shrtckg_term_code
                                             and g1.shrtckg_tckn_seq_no = g.shrtckg_tckn_seq_no
                                         )
            and l.shrtckl_pidm         = n.shrtckn_pidm
            and l.shrtckl_term_code    = n.shrtckn_term_code
            and l.shrtckl_tckn_seq_no  = n.shrtckn_seq_no
            and (n.shrtckn_seq_no,    n.shrtckn_crn,
                 n.shrtckn_term_code, n.shrtckn_pidm
                ) in
                (select
                 smrdous_tckn_seq_no, smrdous_crn,
                 smrdous_term_code,   smrdous_pidm
                   from swrdous
                  where (
                            smrdous_levl_code    is null
                         or smrdous_gmod_code    is null
                         or smrdous_grde_code    is null
                         or smrdous_credit_hours is null
                        )
                );

  begin
      insert into sWrdous
      (smrdous_pidm,                smrdous_request_no,         smrdous_compliance_order,    smrdous_area,
       smrdous_caa_seqno,           smrdous_group,              smrdous_key_rule,            smrdous_term_code_eff,
       smrdous_rul_seqno,           smrdous_rule,               smrdous_rul_seqno_2,         smrdous_program,
       smrdous_area_priority,       smrdous_cnt_in_program_ind, smrdous_cnt_in_area_ind,     smrdous_cnt_in_group_ind,
       smrdous_cnt_in_gpa_ind,      smrdous_split_ind,          smrdous_crse_source,         smrdous_applied_ind,
       smrdous_activity_date,       smrdous_a_crse_reuse_ind,   smrdous_a_attr_reuse_ind,    smrdous_g_crse_reuse_ind,
       smrdous_g_attr_reuse_ind,    smrdous_potential_used_ind, smrdous_equivalent_ind,      smrdous_catalog_ind,
       smrdous_agam_set,            smrdous_agam_subset,        smrdous_crn,                 smrdous_title,
       smrdous_term_code,           smrdous_levl_code,          smrdous_subj_code,           smrdous_crse_numb,
       smrdous_grde_code,           smrdous_gmod_code,          smrdous_credit_hours,        smrdous_credit_hours_used,
       smrdous_camp_code,           smrdous_coll_code,          smrdous_dept_code,           smrdous_attr_code,
       smrdous_atts_code,           smrdous_repeat_course_ind,  smrdous_trad_ind,            smrdous_tckn_seq_no,
       smrdous_trit_seq_no,         smrdous_tram_seq_no,        smrdous_trcr_seq_no,         smrdous_trce_seq_no,
       smrdous_dgmr_seq_no,         smrdous_earned_ind,         smrdous_cnt_in_area_gpa_ind, smrdous_cnt_in_prog_gpa_ind,
       smrdous_grde_quality_points, smrdous_compl_credits,      smrdous_compl_courses,       smrdous_actn_code,
       smrdous_adj_credits,         smrdous_adj_courses,        smrdous_adj_source_ind,      smrdous_agrl_key_rule,
       smrdous_agrl_rul_seqno,      smrdous_agrl_rule,          smrdous_agrl_rul_seqno_2,    smrdous_tesc_code,
       smrdous_test_score,          smrdous_concurrency_ind
      )
      select
       smrdous_pidm,                smrdous_request_no,         smrdous_compliance_order,    smrdous_area,
       smrdous_caa_seqno,           smrdous_group,              smrdous_key_rule,            smrdous_term_code_eff,
       smrdous_rul_seqno,           smrdous_rule,               smrdous_rul_seqno_2,         smrdous_program,
       smrdous_area_priority,       smrdous_cnt_in_program_ind, smrdous_cnt_in_area_ind,     smrdous_cnt_in_group_ind,
       smrdous_cnt_in_gpa_ind,      smrdous_split_ind,          smrdous_crse_source,         smrdous_applied_ind,
       smrdous_activity_date,       smrdous_a_crse_reuse_ind,   smrdous_a_attr_reuse_ind,    smrdous_g_crse_reuse_ind,
       smrdous_g_attr_reuse_ind,    smrdous_potential_used_ind, smrdous_equivalent_ind,      smrdous_catalog_ind,
       smrdous_agam_set,            smrdous_agam_subset,        smrdous_crn,                 smrdous_title,
       smrdous_term_code,           smrdous_levl_code,          smrdous_subj_code,           smrdous_crse_numb,
       smrdous_grde_code,           smrdous_gmod_code,          smrdous_credit_hours,        smrdous_credit_hours_used,
       smrdous_camp_code,           smrdous_coll_code,          smrdous_dept_code,           smrdous_attr_code,
       smrdous_atts_code,           smrdous_repeat_course_ind,  smrdous_trad_ind,            smrdous_tckn_seq_no,
       smrdous_trit_seq_no,         smrdous_tram_seq_no,        smrdous_trcr_seq_no,         smrdous_trce_seq_no,
       smrdous_dgmr_seq_no,         smrdous_earned_ind,         smrdous_cnt_in_area_gpa_ind, smrdous_cnt_in_prog_gpa_ind,
       smrdous_grde_quality_points, smrdous_compl_credits,      smrdous_compl_courses,       smrdous_actn_code,
       smrdous_adj_credits,         smrdous_adj_courses,        smrdous_adj_source_ind,      smrdous_agrl_key_rule,
       smrdous_agrl_rul_seqno,      smrdous_agrl_rule,          smrdous_agrl_rul_seqno_2,    smrdous_tesc_code,
       smrdous_test_score,          smrdous_concurrency_ind
        from smrdous a
       where a.smrdous_request_no = (select max(b.smrdous_request_no)
                                       from smrdous b
                                      where b.smrdous_pidm      = pnPidm
                                        and b.smrdous_program   = csPrograma
                                        and exists (select null
                                                      from smrprrq
                                                     where smrprrq_request_no = b.smrdous_request_no
                                                       and smrprrq_pidm       = pnPidm
                                                       and smrprrq_cprt_code  = csAsesores
                                                   )
                                    )
         and a.smrdous_pidm       = pnPidm
         and a.smrdous_program    = csPrograma;

      --actualizando valores nulos
      for regLcn in cuLCnull loop
          update sWrdous
             set smrdous_levl_code          = regLcn.levlCode,
                 smrdous_gmod_code          = regLcn.gmodCode,
                 smrdous_grde_code          = regLcn.grdeCode,
                 smrdous_credit_hours       = regLcn.credHour
           where smrdous_tckn_seq_no = regLcn.tcknSeqn
             and smrdous_crn         = regLcn.tcknCrnn
             and smrdous_term_code   = regLcn.termCode
             and smrdous_pidm        = regLcn.tcknPidm;
      end loop;

      --registra los datos a procesar
      insert into swrcapp
      (swrcapp_area,        swrcapp_area_priority, swrcapp_group,
       swrcapp_subj_code,   swrcapp_crse_numb,     swrcapp_grde_code,
       swrcapp_term_code,   swrcapp_credit_hours,  swrcapp_gmod_code,
       swrcapp_crn,         swrcapp_title,         swrcapp_request_no,
       swrcapp_crse_source, swrcapp_camp_code,     swrcapp_type
      )
      select
      smrdous_area,        smrdous_area_priority, smrdous_group,
      smrdous_subj_code,   smrdous_crse_numb,     smrdous_grde_code,
      smrdous_term_code,   smrdous_credit_hours,  smrdous_gmod_code,
      smrdous_crn,         smrdous_title,         smrdous_request_no,
      smrdous_crse_source, smrdous_camp_code,     csUS
        from sWrdous a
       where (a.smrdous_tckn_seq_no||
              a.smrdous_term_code) = (select min(z.smrdous_tckn_seq_no||z.smrdous_term_code)
                                        from sWrdous z
                                       where z.smrdous_request_no = a.smrdous_request_no
                                         and z.smrdous_crse_numb  = a.smrdous_crse_numb
                                         and z.smrdous_subj_code  = a.smrdous_subj_code
                                         and (
                                                (
                                                     z.smrdous_levl_code = csLevlCode
                                                 and
                                                     psNivel = csLIC
                                                )
                                             or
                                                (
                                                     z.smrdous_levl_code in (csLevlCode,csES)
                                                 and
                                                     psNivel = csPOS
                                                )
                                             )
                                         and z.smrdous_program    = csPrograma
                                         and z.smrdous_pidm       = pnPidm
                                     )
         and a.smrdous_pidm        = pnPidm
         and a.smrdous_program     = csPrograma
         and (
                (
                     a.smrdous_levl_code = csLevlCode
                 and
                     psNivel = csLIC
                )
             or
                (
                     a.smrdous_levl_code in (csLevlCode,csES)
                 and
                     psNivel = csPOS
                )
             );


  end cursosUsados;

  -- Cursos no usados
  procedure cursosNoUsados is

  cursor cuLCnull is
         select l.shrtckl_levl_code       as levlCode,
                g.shrtckg_gmod_code       as gmodCode,
                g.shrtckg_credit_hours    as credHour,
                g.shrtckg_grde_code_final as grdeCode,
                n.shrtckn_seq_no          as tcknSeqn,
                n.shrtckn_crn             as tcknCrnn,
                n.shrtckn_term_code       as termCode,
                n.shrtckn_pidm            as tcknPidm
           from shrtckn n,
                shrtckg g,
                shrtckl l
          where g.shrtckg_pidm         = n.shrtckn_pidm
            and g.shrtckg_term_code    = n.shrtckn_term_code
            and g.shrtckg_tckn_seq_no  = n.shrtckn_seq_no
            and g.shrtckg_seq_no       = (select max(g1.shrtckg_seq_no)
                                            from shrtckg g1
                                           where g1.shrtckg_pidm        = g.shrtckg_pidm
                                             and g1.shrtckg_term_code   = g.shrtckg_term_code
                                             and g1.shrtckg_tckn_seq_no = g.shrtckg_tckn_seq_no
                                         )
            and l.shrtckl_pidm         = n.shrtckn_pidm
            and l.shrtckl_term_code    = n.shrtckn_term_code
            and l.shrtckl_tckn_seq_no  = n.shrtckn_seq_no
            and (n.shrtckn_seq_no,    n.shrtckn_crn,
                 n.shrtckn_term_code, n.shrtckn_pidm
                ) in
                (select
                 smrdocn_tckn_seq_no, smrdocn_crn,
                 smrdocn_term_code,   smrdocn_pidm
                   from swrdocn
                  where (
                            smrdocn_levl_code    is null
                         or smrdocn_gmod_code    is null
                         or smrdocn_grde_code    is null
                         or smrdocn_credit_hours is null
                        )
                );

  begin
      insert into swrdocn
      (
      smrdocn_pidm,        smrdocn_request_no,        smrdocn_term_code,
      smrdocn_crn,         smrdocn_subj_code,         smrdocn_crse_numb,
      smrdocn_program,     smrdocn_activity_date,     smrdocn_crse_title,
      smrdocn_crse_source, smrdocn_levl_code,         smrdocn_grde_code,
      smrdocn_gmod_code,   smrdocn_credit_hours,      smrdocn_credit_hours_avail,
      smrdocn_camp_code,   smrdocn_coll_code,         smrdocn_dept_code,
      smrdocn_trad_ind,    smrdocn_repeat_course_ind, smrdocn_tckn_seq_no,
      smrdocn_trit_seq_no, smrdocn_tram_seq_no,       smrdocn_trcr_seq_no,
      smrdocn_trce_seq_no, smrdocn_dgmr_seq_no,       smrdocn_concurrency_ind
      )
      select
      smrdocn_pidm,        smrdocn_request_no,        smrdocn_term_code,
      smrdocn_crn,         smrdocn_subj_code,         smrdocn_crse_numb,
      smrdocn_program,     smrdocn_activity_date,     smrdocn_crse_title,
      smrdocn_crse_source, smrdocn_levl_code,         smrdocn_grde_code,
      smrdocn_gmod_code,   smrdocn_credit_hours,      smrdocn_credit_hours_avail,
      smrdocn_camp_code,   smrdocn_coll_code,         smrdocn_dept_code,
      smrdocn_trad_ind,    smrdocn_repeat_course_ind, smrdocn_tckn_seq_no,
      smrdocn_trit_seq_no, smrdocn_tram_seq_no,       smrdocn_trcr_seq_no,
      smrdocn_trce_seq_no, smrdocn_dgmr_seq_no,       smrdocn_concurrency_ind
        from smrdocn b
       where b.smrdocn_request_no = (select max(c.smrdocn_request_no)
                                       from smrdocn c
                                      where c.smrdocn_pidm      = pnPidm
                                        and c.smrdocn_program   = csPrograma
                                        and exists (select null
                                                      from smrprrq
                                                     where smrprrq_request_no = c.smrdocn_request_no
                                                       and smrprrq_pidm       = pnPidm
                                                       and smrprrq_cprt_code  = csAsesores
                                                   )
                                    )
         and exists (select null
                       from shrtckn
                      where shrtckn_pidm      = b.smrdocn_pidm
                        and shrtckn_subj_code = b.smrdocn_subj_code
                        and shrtckn_crse_numb = b.smrdocn_crse_numb
                    )
         and not exists (select null
                           from sWrdous
                          where smrdous_subj_code  = b.smrdocn_subj_code
                            and smrdous_crse_numb  = b.smrdocn_crse_numb
                            and smrdous_camp_code <> b.smrdocn_camp_code
                        )
         and b.smrdocn_program    = csPrograma
         and b.smrdocn_pidm       = pnPidm
         and (psMatEx = 'false' or psMatEx is null);

      --actualizando valores nulos
      for regLcn in cuLCnull loop
          update sWrdocn
             set smrdocn_levl_code          = regLcn.levlCode,
                 smrdocn_gmod_code          = regLcn.gmodCode,
                 smrdocn_grde_code          = regLcn.grdeCode,
                 smrdocn_credit_hours       = regLcn.credHour,
                 smrdocn_credit_hours_avail = regLcn.credHour
           where smrdocn_tckn_seq_no = regLcn.tcknSeqn
             and smrdocn_crn         = regLcn.tcknCrnn
             and smrdocn_term_code   = regLcn.termCode
             and smrdocn_pidm        = regLcn.tcknPidm;
      end loop;

  end cursosNoUsados;

  -- Cursos no usados
  -- Materias que se colocan en el bloque que les corresponde
  -- Reprobadas y con creditos
  procedure reprobadasConCreditos is

  begin
      insert into swrcapp
      (swrcapp_area,        swrcapp_area_priority, swrcapp_group,
       swrcapp_subj_code,   swrcapp_crse_numb,     swrcapp_grde_code,
       swrcapp_term_code,   swrcapp_credit_hours,  swrcapp_gmod_code,
       swrcapp_crn,         swrcapp_title,         swrcapp_request_no,
       swrcapp_crse_source, swrcapp_camp_code,     swrcapp_type
      )
      select
      SUBSTR(SMRDO2.Area,cn1,INSTR(SMRDO2.Area,csTilde)-cn1),
      TO_NUMBER(SUBSTR(SUBSTR(SMRDO2.Area,  INSTR(SMRDO2.Area,csTilde)+cn1),cn1,INSTR(SUBSTR(SMRDO2.Area,  INSTR(SMRDO2.Area,csTilde)+cn1),csTilde)-cn1)),
      SUBSTR(SUBSTR(SMRDO2.Area,  INSTR(SMRDO2.Area,csTilde)+cn1),  INSTR(SUBSTR(SMRDO2.Area,  INSTR(SMRDO2.Area,csTilde)+cn1),csTilde)+cn1),
      SMRDO2.Subj,          SMRDO2.Crse,           SMRDO2.Grde,
      SMRDO2.Term,          SMRDO2.Cred,           SMRDO2.Gmod,
      SMRDO2.Crn,           SMRDO2.Titl,           SMRDO2.Requ,
      SMRDO2.Sour,          SMRDO2.Camp,           csCN
         from (
               select nvl(
                           (select d.smrpaap_area||csTilde||d.smrpaap_area_priority||csTilde||b.smrgcaa_group
                              from smragam a,
                                   smrgcaa b,
                                   smrpaap d
                             where b.smrgcaa_group         = a.smragam_group
                               and b.smrgcaa_term_code_eff = a.smragam_term_code_eff
                               and b.smrgcaa_term_code_eff = (select max(c.smrgcaa_term_code_eff)
                                                                from smrgcaa c
                                                               where c.smrgcaa_subj_code      = b.smrgcaa_subj_code
                                                                 and c.smrgcaa_crse_numb_low  = b.smrgcaa_crse_numb_low
                                                                 and c.smrgcaa_term_code_eff <= a.smragam_term_code_eff
                                                                 and c.smrgcaa_group          = b.smrgcaa_group
                                                             )
                               and b.smrgcaa_seqno         = (select max(smrgcaa_seqno)
                                                                from smrgcaa c
                                                               where c.smrgcaa_subj_code      = b.smrgcaa_subj_code
                                                                 and c.smrgcaa_crse_numb_low  = b.smrgcaa_crse_numb_low
                                                                 and c.smrgcaa_group          = b.smrgcaa_group
                                                                 and c.smrgcaa_term_code_eff  = (select max(d.smrgcaa_term_code_eff)
                                                                                                   from smrgcaa d
                                                                                                  where d.smrgcaa_subj_code      = c.smrgcaa_subj_code
                                                                                                    and d.smrgcaa_crse_numb_low  = c.smrgcaa_crse_numb_low
                                                                                                    and d.smrgcaa_term_code_eff <= a.smragam_term_code_eff
                                                                                                    and d.smrgcaa_group          = c.smrgcaa_group
                                                                                                )
                                                             )
                               and a.smragam_area          = d.smrpaap_area
                               and d.smrpaap_term_code_eff = (select max(e.smrpaap_term_code_eff)
                                                                from smrpaap e
                                                               where e.smrpaap_area    = d.smrpaap_area
                                                                 and e.smrpaap_program = csPrograma
                                                             )
                               and d.smrpaap_program       = csPrograma
                               and b.smrgcaa_subj_code     = smrdocn_subj_code
                               and b.smrgcaa_crse_numb_low = smrdocn_crse_numb
                               and rownum = cn1
                           )
                          ,
                           nvl(
                                (select c.smrpaap_area||csTilde||c.smrpaap_area_priority||csTilde||null as Areapriogrop
                                   from smracaa a,
                                        smrpaap c
                                  where a.smracaa_term_code_eff = (select max(b.smracaa_term_code_eff)
                                                                     from smracaa b
                                                                    where b.smracaa_term_code_eff <= smrdocn_term_code
                                                                      and b.smracaa_subj_code      = a.smracaa_subj_code
                                                                      and b.smracaa_crse_numb_low  = a.smracaa_crse_numb_low
                                                                      and b.smracaa_area           = c.smrpaap_area
                                                                  )
                                    and a.smracaa_activity_date = (select max(c.smracaa_activity_date)
                                                                     from smracaa c
                                                                    where c.smracaa_term_code_eff <= smrdocn_term_code
                                                                      and c.smracaa_subj_code      = a.smracaa_subj_code
                                                                      and c.smracaa_crse_numb_low  = a.smracaa_crse_numb_low
                                                                      and c.smracaa_area           = c.smrpaap_area
                                                                      and c.smracaa_term_code_eff  = (select max(d.smracaa_term_code_eff)
                                                                                                        from smracaa d
                                                                                                       where d.smracaa_subj_code      = a.smracaa_subj_code
                                                                                                         and d.smracaa_crse_numb_low  = a.smracaa_crse_numb_low
                                                                                                         and d.smracaa_area           = c.smrpaap_area
                                                                                                         and d.smracaa_term_code_eff <= smrdocn_term_code
                                                                                                     )
                                                                  )
                                    and a.smracaa_area          = c.smrpaap_area
                                    and c.smrpaap_term_code_eff = (select max(d.smrpaap_term_code_eff)
                                                                     from smrpaap d
                                                                    where d.smrpaap_program = csPrograma
                                                                      and d.smrpaap_area    = c.smrpaap_area
                                                                  )
                                    and c.smrpaap_program       = csPrograma
                                    and a.smracaa_subj_code     = smrdocn_subj_code
                                    and a.smracaa_crse_numb_low = smrdocn_crse_numb
                                    and rownum = cn1
                                )
                               ,
                                nvl(
                                     (select e.smrpaap_area||csTilde||e.smrpaap_area_priority||csTilde||c.smragam_group as Areapriogrop
                                        from smragam c,
                                             smrgcaa d,
                                             smrpaap e
                                       where c.smragam_group         = d.smrgcaa_group
                                         and c.smragam_term_code_eff = d.smrgcaa_term_code_eff
                                         and exists (select null
                                                       from smrgrul a
                                                      where a.smrgrul_subj_code     = smrdocn_subj_code
                                                        and a.smrgrul_crse_numb_low = smrdocn_crse_numb
                                                        and a.smrgrul_group         = d.smrgcaa_group
                                                        and a.smrgrul_key_rule      = d.smrgcaa_rule
                                                        and a.smrgrul_term_code_eff = d.smrgcaa_term_code_eff
                                                        and a.smrgrul_seqno         = (select max(b.smrgrul_seqno)
                                                                                         from smrgrul b
                                                                                        where b.smrgrul_subj_code     = a.smrgrul_subj_code
                                                                                          and b.smrgrul_crse_numb_low = a.smrgrul_crse_numb_low
                                                                                     )
                                                    )
                                         and c.smragam_area          = e.smrpaap_area
                                         and e.smrpaap_term_code_eff = (select max(f.smrpaap_term_code_eff)
                                                                          from smrpaap f
                                                                         where f.smrpaap_program = csPrograma
                                                                           and f.smrpaap_area    = e.smrpaap_area
                                                                       )
                                         and e.smrpaap_program       = csPrograma
                                         and d.smrgcaa_crse_numb_low = smrdocn_crse_numb ---GEPC 04/01/2012
                                         and d.smrgcaa_subj_code     = smrdocn_subj_code --GEPC 04/01/2012
                                         and rownum = cn1
                                     )
                                    ,
                                     nvl(
                                          (select e.smrpaap_area||csTilde||e.smrpaap_area_priority||csTilde||c.smragam_group as Areapriogrop
                                             from smragam c,
                                                  smrgcaa d,
                                                  smrpaap e
                                            where c.smragam_group         = d.smrgcaa_group
                                              and c.smragam_term_code_eff = d.smrgcaa_term_code_eff
                                              and exists (select null
                                                            from smrgrul a
                                                           where a.smrgrul_subj_code     = smrdocn_subj_code
                                                             and a.smrgrul_crse_numb_low = smrdocn_crse_numb
                                                             and a.smrgrul_group         = d.smrgcaa_group
                                                             and a.smrgrul_key_rule      = d.smrgcaa_rule
                                                             and a.smrgrul_term_code_eff = d.smrgcaa_term_code_eff
                                                             and a.smrgrul_seqno         = (select max(b.smrgrul_seqno)
                                                                                              from smrgrul b
                                                                                             where b.smrgrul_subj_code     = a.smrgrul_subj_code
                                                                                               and b.smrgrul_crse_numb_low = a.smrgrul_crse_numb_low
                                                                                          )
                                                         )
                                              and c.smragam_area          = e.smrpaap_area
                                              and e.smrpaap_term_code_eff = (select max(f.smrpaap_term_code_eff)
                                                                               from smrpaap f
                                                                              where f.smrpaap_program = e.smrpaap_program
                                                                                and f.smrpaap_area    = e.smrpaap_area
                                                                            )
                                              and d.smrgcaa_crse_numb_low = smrdocn_crse_numb ---GEPC 04/01/2012
                                              and d.smrgcaa_subj_code     = smrdocn_subj_code --GEPC 04/01/2012
                                              and rownum = cn1
                                          )
                                         ,
--                                          nvl(
--                                               (select a.smracaa_area||csTilde||decode(substr(a.smracaa_area,length(a.smracaa_area),cn1),csF,cs10,csP,cs20,cs4,cs20,csE,cs30,cs40)||csTilde as areapriogrop
--                                                  from smracaa a
--                                                 where a.smracaa_term_code_eff = (select max(b.smracaa_term_code_eff)
--                                                                                    from smracaa b
--                                                                                   where b.smracaa_term_code_eff <= SMRDOCN_TERM_CODE
--                                                                                     and b.smracaa_subj_code      = a.smracaa_subj_code
--                                                                                     and b.smracaa_crse_numb_low  = a.smracaa_crse_numb_low
--                                                                                     and b.smracaa_area           = a.smracaa_area
--                                                                                 )
--                                                   and a.smracaa_activity_date = (select max(c.smracaa_activity_date)
--                                                                                    from smracaa c
--                                                                                   where c.smracaa_term_code_eff <= SMRDOCN_TERM_CODE
--                                                                                     and c.smracaa_subj_code      = a.smracaa_subj_code
--                                                                                     and c.smracaa_crse_numb_low  = a.smracaa_crse_numb_low
--                                                                                     and c.smracaa_area           = a.smracaa_area
--                                                                                     and c.smracaa_term_code_eff  = (select max(d.smracaa_term_code_eff)
--                                                                                                                       from smracaa d
--                                                                                                                      where d.smracaa_subj_code      = a.smracaa_subj_code
--                                                                                                                        and d.smracaa_crse_numb_low  = a.smracaa_crse_numb_low
--                                                                                                                        and d.smracaa_area           = a.smracaa_area
--                                                                                                                        and d.smracaa_term_code_eff <= SMRDOCN_TERM_CODE
--                                                                                                                    )
--                                                                                 )
--                                                   and a.smracaa_subj_code     = SMRDOCN_SUBJ_CODE
--                                                   and a.smracaa_crse_numb_low = SMRDOCN_CRSE_NUMB
--                                                   and rownum = cn1
--                                               )
--                                              ,
                                               csBloque||csTilde --csOtros||csTilde--
                                             --)
                                        )
                                   )
                              )
                         )                 as Area,
                      smrdocn_subj_code    as Subj,
                      smrdocn_crse_numb    as Crse,
                      smrdocn_grde_code    as Grde,
                      smrdocn_term_code    as Term,
                      smrdocn_credit_hours as Cred,
                      smrdocn_gmod_code    as Gmod,
                      smrdocn_crn          as Crn,
                      smrdocn_crse_title   as Titl,
                      smrdocn_request_no   as Requ,
                      smrdocn_crse_source  as Sour,
                      smrdocn_camp_code    as Camp
                 from sWrdocn b,
                      shrgrde a
                where not exists (select null
                                    from swrcapp
                                   where swrcapp_gmod_code    = b.smrdocn_gmod_code
                                     and swrcapp_subj_code    = b.smrdocn_subj_code
                                     and swrcapp_crse_numb    = b.smrdocn_crse_numb
                                     and swrcapp_crse_source <> csR
                                     and swrcapp_gmod_code   <> csX
                                 )
                  and b.smrdocn_credit_hours        > cn0
                  and a.shrgrde_quality_points      < cn6
                  and a.shrgrde_term_code_effective = (select max(d.shrgrde_term_code_effective)
                                                         from shrgrde d
                                                        where d.shrgrde_levl_code = a.shrgrde_levl_code
                                                          and d.shrgrde_code      = a.shrgrde_code
                                                      )
                  and a.shrgrde_levl_code           = smrdocn_levl_code
                  and a.shrgrde_code                = smrdocn_grde_code
                  and (b.smrdocn_tckn_seq_no||
                       b.smrdocn_term_code        ) = (select min(to_number(z.smrdocn_tckn_seq_no||z.smrdocn_term_code))
                                                         from sWrdocn z
                                                        where z.smrdocn_request_no = b.smrdocn_request_no
                                                          and z.smrdocn_crse_numb  = b.smrdocn_crse_numb
                                                          and z.smrdocn_subj_code  = b.smrdocn_subj_code
                                                          and z.smrdocn_gmod_code  = b.smrdocn_gmod_code
                                                          and (
                                                                 (
                                                                      z.smrdocn_levl_code = csLevlCode
                                                                  and
                                                                      psNivel = csLIC
                                                                 )
                                                              or
                                                                 (
                                                                      z.smrdocn_levl_code in (csLevlCode,csES)
                                                                  AND
                                                                      psNivel = csPOS
                                                                 )
                                                              )
                                                          and z.smrdocn_program    = csPrograma
                                                          and z.smrdocn_pidm       = pnPidm
                                                      )
                  and b.smrdocn_pidm                = pnPidm
                  and b.smrdocn_program             = csprograma
                  and (
                         (
                              b.smrdocn_levl_code = csLevlCode
                          and
                              psNivel = csLIC
                         )
                      or
                         (
                              b.smrdocn_levl_code in (csLevlCode,csES)
                          AND
                              psNivel = csPOS
                         )
                      )
              ) SMRDO2;

  end reprobadasConCreditos;

  -- Cursos no usados
  -- Materias con cero creditos
  procedure materiasCeroCreditos is

  begin
      insert into swrcapp
      (swrcapp_area,        swrcapp_area_priority, swrcapp_group,
       swrcapp_subj_code,   swrcapp_crse_numb,     swrcapp_grde_code,
       swrcapp_term_code,   swrcapp_credit_hours,  swrcapp_gmod_code,
       swrcapp_crn,         swrcapp_title,         swrcapp_request_no,
       swrcapp_crse_source, swrcapp_camp_code,     swrcapp_type
      )
      select
      csOtros,              cn999,                 csNull,
      smrdocn_subj_code,    smrdocn_crse_numb,     smrdocn_grde_code,
      smrdocn_term_code,    smrdocn_credit_hours,  smrdocn_gmod_code,
      smrdocn_crn,          smrdocn_crse_title,    smrdocn_request_no,
      smrdocn_crse_source,  smrdocn_camp_code,     csOT
        from sWrdocn b
       where (b.smrdocn_tckn_seq_no||
              b.smrdocn_term_code    ) = (select min(z.smrdocn_tckn_seq_no)||min(z.smrdocn_term_code)
                                              from sWrdocn z
                                             where z.smrdocn_request_no = b.smrdocn_request_no
                                               and z.smrdocn_crse_numb  = b.smrdocn_crse_numb
                                               and z.smrdocn_subj_code  = b.smrdocn_subj_code
                                              and (
                                                     (
                                                          nvl(z.smrdocn_levl_code,csLevlCode) = csLevlCode
                                                      and
                                                          psNivel = csLIC
                                                     )
                                                  or
                                                     (
                                                          nvl(z.smrdocn_levl_code,csLevlCode) IN (csLevlCode,csES)
                                                      and
                                                          psNivel = csPOS
                                                     )
                                                  )
                                               and z.smrdocn_program    = csPrograma
                                               and z.smrdocn_pidm       = pnPidm
                                           )
         and b.smrdocn_program         = csPrograma
         and b.smrdocn_pidm            = pnPidm
         and b.smrdocn_credit_hours    = cn0
         and (
                (
                     nvl(b.smrdocn_levl_code,csLevlCode) = csLevlCode
                 and
                     psNivel = csLIC
                )
             or
                (
                     nvl(b.smrdocn_levl_code,csLevlCode) IN (csLevlCode,csES)
                 and
                     psNivel = csPOS
                )
             );

  end materiasCeroCreditos;

  -- Cursos no usados
  -- MATERIAS QUE SE COLOCAN EN EL BLOQUE ELECTIVO
  -- Aprobadas y con creditos
  procedure aprobadasConCreditos is

  begin
      insert into swrcapp
      (swrcapp_area,        swrcapp_area_priority, swrcapp_group,
       swrcapp_subj_code,   swrcapp_crse_numb,     swrcapp_grde_code,
       swrcapp_term_code,   swrcapp_credit_hours,  swrcapp_gmod_code,
       swrcapp_crn,         swrcapp_title,         swrcapp_request_no,
       swrcapp_crse_source, swrcapp_camp_code,     swrcapp_type
      )
      select
      SMRDOC.Area,          SMRDOC.Prio,           SMRDOC.Grup,
      SMRDOC.Subj,          SMRDOC.Crse,           SMRDOC.Grde,
      SMRDOC.Term,          SMRDOC.Cred,           SMRDOC.Gmod,
      SMRDOC.Crnn,          SMRDOC.Titl,           SMRDOC.Requ,
      SMRDOC.Sour,          SMRDOC.Camp,           csAC
        from (select csBloque             as Area,
                     cn500                as Prio,
                     csNULL               as Grup,
                     smrdocn_subj_code    as Subj,
                     smrdocn_crse_numb    as Crse,
                     smrdocn_grde_code    as Grde,
                     smrdocn_term_code    as Term,
                     smrdocn_credit_hours as Cred,
                     smrdocn_gmod_code    as Gmod,
                     smrdocn_crn          as Crnn,
                     smrdocn_crse_title   as Titl,
                     (select shrgrde_quality_points
                        from shrgrde a
                       where a.shrgrde_term_code_effective = (select max(b.shrgrde_term_code_effective)
                                                                from shrgrde b
                                                               where b.shrgrde_levl_code = a.shrgrde_levl_code
                                                                 and b.shrgrde_code      = a.shrgrde_code
                                                             )
                         and a.shrgrde_levl_code = smrdocn_levl_code
                         and a.shrgrde_code      = smrdocn_grde_code
                     )                     as Grd2,
                     b.smrdocn_request_no  as Requ,
                     b.smrdocn_crse_source as Sour,
                     b.smrdocn_camp_code   as Camp
                from sWrdocn b
               where (b.smrdocn_tckn_seq_no||
                      b.smrdocn_term_code    ) = (select min(to_number(z.smrdocn_tckn_seq_no||z.smrdocn_term_code))
                                                      from sWrdocn z
                                                     where z.smrdocn_request_no = b.smrdocn_request_no
                                                       and z.smrdocn_crse_numb  = b.smrdocn_crse_numb
                                                       and z.smrdocn_subj_code  = b.smrdocn_subj_code
                                                       and (
                                                            (
                                                                 z.smrdocn_levl_code = csLevlCode
                                                             and
                                                                 psNivel = csLIC
                                                            )
                                                         or
                                                            (
                                                                 z.smrdocn_levl_code in (csLevlCode,csES)
                                                             and
                                                                 psNivel = csPOS
                                                            )
                                                           )
                                                       and z.smrdocn_program    = csPrograma
                                                       and z.smrdocn_pidm       = pnPidm
                                                   )
                 and not exists (select null
                                    from swrcapp
                                   where swrcapp_gmod_code    = b.smrdocn_gmod_code
                                     and swrcapp_subj_code    = b.smrdocn_subj_code
                                     and swrcapp_crse_numb    = b.smrdocn_crse_numb
                                     and swrcapp_crse_source <> csR
                                     and swrcapp_gmod_code   <> csX
                                 )
                 and b.smrdocn_program            = csPrograma
                 and b.smrdocn_pidm               = pnPidm
                 and b.smrdocn_credit_hours       > cn0
                 and (
                      (
                           b.smrdocn_levl_code = csLevlCode
                       and
                           psNivel = csLIC
                      )
                   or
                      (
                           b.smrdocn_levl_code in (csLevlCode,csES)
                       and
                           psNivel = csPOS
                      )
                   )
             ) SMRDOC
       where SMRDOC.Grd2 >= cn6;

  end aprobadasConCreditos;

  -- Cursos no usados
  -- filtros solo para posgrado
  procedure materiasPosgrado is

  begin
      insert into swrcapp
      (swrcapp_area,        swrcapp_area_priority, swrcapp_group,
       swrcapp_subj_code,   swrcapp_crse_numb,     swrcapp_grde_code,
       swrcapp_term_code,   swrcapp_credit_hours,  swrcapp_gmod_code,
       swrcapp_crn,         swrcapp_title,         swrcapp_request_no,
       swrcapp_crse_source, swrcapp_camp_code,     swrcapp_type
      )
      select
       csNULL,               cn999,                 cn0,
       smrdocn_subj_code,   smrdocn_crse_numb,     smrdocn_grde_code,
       smrdocn_term_code,   smrdocn_credit_hours,  smrdocn_gmod_code,
       smrdocn_crn,         smrdocn_crse_title,    smrdocn_request_no,
       smrdocn_crse_source, smrdocn_camp_code,     csPO
        from sWrdocn b
       where (b.smrdocn_tckn_seq_no||
              b.smrdocn_term_code    ) = (select min(z.smrdocn_tckn_seq_no)||min(z.smrdocn_term_code)
                                              from sWrdocn z
                                             where z.smrdocn_request_no = b.smrdocn_request_no
                                               and z.smrdocn_crse_numb  = b.smrdocn_crse_numb
                                               and z.smrdocn_subj_code  = b.smrdocn_subj_code
                                               and z.smrdocn_levl_code  IN (csLevlCode,csES)
                                               and z.smrdocn_program    = csPrograma
                                               and z.smrdocn_pidm       = pnPidm
                                           )
         and b.smrdocn_program             = csPrograma
         and b.smrdocn_levl_code          IN (csLevlCode,csES)
         and b.smrdocn_pidm                = pnPidm
         and psNivel                       = csPOS
         and not exists (select null
                           from swrcapp
                          where swrcapp_subj_code    = smrdocn_subj_code
                            and swrcapp_crse_numb    = smrdocn_crse_numb
                            and swrcapp_crse_source <> csR
                        );

  end materiasPosgrado;

  --corregir cerocreditos con extraordinario aprobado
  procedure ceroCreditosExtrAprobado IS

  --credtos aprobados
  cursor cuCero is
         select swrcapp_term_code     as cappTerm,
                swrcapp_crn           as cappCrnn,
                sWrdou.dousArea       as dousArea,
                sWrdou.dousPrio       as dousPrio,
                sWrdou.dousGrop       as dousGrop,
                sWrdou.dousCred       as dousCred
           from swrcapp,
                (select smrdous_subj_code                as dousSubj,
                        smrdous_crse_numb                as dousCrse,
                        smrdous_area                     as dousArea,
                        smrdous_area_priority            as dousPrio,
                        smrdous_group                    as dousGrop,
                        smrdous_credit_hours             as dousCred,
                        max(smrdous_grde_quality_points) as dousGrde
                   from sWrdous
                  where smrdous_grde_quality_points >= cn6
                    and smrdous_credit_hours         > cn0
                    and smrdous_gmod_code            = csX
                  group by smrdous_subj_code,
                           smrdous_crse_numb,
                           smrdous_area,
                           smrdous_area_priority,
                           smrdous_group,
                            smrdous_credit_hours
                ) sWrdou
          where swrcapp_subj_code = sWrdou.dousSubj
            and swrcapp_crse_numb = sWrdou.dousCrse
            and swrcapp_type      = csOT;

  begin

      for regCap in cuCero loop
          update swrcapp
             set swrcapp_area          = regCap.dousArea,
                 swrcapp_area_priority = regCap.dousPrio,
                 swrcapp_group         = regCap.dousGrop,
                 swrcapp_credit_hours  = regCap.dousCred
           where swrcapp_crn       = regCap.cappCrnn
             and swrcapp_term_code = regCap.cappTerm
             and swrcapp_type      = csOT;
      end loop;

  end ceroCreditosExtrAprobado;

  BEGIN

      --Son registrados los cursos usados
      cursosUsados;

      -- Cursos no usados
      cursosNoUsados;

      DELETE FROM SWRDOCN A
       WHERE A.SMRDOCN_REPEAT_COURSE_IND  = csE
         AND A.SMRDOCN_GMOD_CODE          = csN
         AND A.SMRDOCN_GRDE_CODE         <> csOU
         AND NOT EXISTS (SELECT NULL
                           FROM SWRDOCN B
                          WHERE B.SMRDOCN_SUBJ_CODE                   = A.SMRDOCN_SUBJ_CODE
                            AND B.SMRDOCN_CRSE_NUMB                   = A.SMRDOCN_CRSE_NUMB
                            AND NVL(B.SMRDOCN_REPEAT_COURSE_IND,'I') IN (csE,csI)
                            AND B.SMRDOCN_GMOD_CODE                   = csX
                        )
         AND NOT EXISTS (SELECT NULL
                          FROM SWRCAPP B
                         WHERE B.SWRCAPP_SUBJ_CODE = A.SMRDOCN_SUBJ_CODE
                           AND B.SWRCAPP_CRSE_NUMB = A.SMRDOCN_CRSE_NUMB
                           AND B.SWRCAPP_GMOD_CODE = csX
                        );

      -- Cursos no usados
      -- Materias que se colocan en el bloque que les corresponde
      -- Reprobadas y con creditos
      reprobadasConCreditos;

      -- Cursos no usados
      -- Materias con cero creditos
      materiasCeroCreditos;

      -- Cursos no usados
      -- MATERIAS QUE SE COLOCAN EN EL BLOQUE ELECTIVO
      -- Aprobadas y con creditos
      aprobadasConCreditos;

      -- Cursos no usados
      -- filtros solo para posgrado
      materiasPosgrado;

      --corregir cerocreditos con extraordinario aprobado
      ceroCreditosExtrAprobado;

      --buscando un bloque electivo
      BEGIN
          SELECT MAX(SWRCAPP_AREA_PRIORITY)
            INTO vnPriority
            FROM SWRCAPP
           WHERE EXISTS (SELECT C.SMRACMT_TEXT
                           FROM SMRACMT C
                          WHERE (C.SMRACMT_TERM_CODE_EFF,C.SMRACMT_TEXT_SEQNO) = (SELECT MAX(D.SMRACMT_TERM_CODE_EFF),MAX(D.SMRACMT_TEXT_SEQNO)
                                                                                    FROM SMRACMT D
                                                                                   WHERE D.SMRACMT_AREA = C.SMRACMT_AREA
                                                                                 )
                            AND LTRIM(RTRIM(C.SMRACMT_TEXT))                   = csBloqueElc
                            AND C.SMRACMT_AREA                                 = SWRCAPP_AREA
                        )
             AND SWRCAPP_AREA_PRIORITY IS NOT NULL
             AND ROWNUM                 = cn1
           GROUP BY SWRCAPP_AREA;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               NULL;
          WHEN OTHERS THEN
               NULL;
      END;

      --ACTUALIZANDO LA PRIORIDAD A UN BLOQUE ELECTIVO
      UPDATE SWRCAPP
         SET SWRCAPP_AREA_PRIORITY = vnPriority
       WHERE (
                 EXISTS (SELECT C.SMRACMT_TEXT
                           FROM SMRACMT C
                          WHERE (C.SMRACMT_TERM_CODE_EFF,C.SMRACMT_TEXT_SEQNO) = (SELECT MAX(D.SMRACMT_TERM_CODE_EFF),MAX(D.SMRACMT_TEXT_SEQNO)
                                                                                    FROM SMRACMT D
                                                                                   WHERE D.SMRACMT_AREA = C.SMRACMT_AREA
                                                                                 )
                            AND LTRIM(RTRIM(C.SMRACMT_TEXT))                   = csBloqueElc
                            AND C.SMRACMT_AREA                                 = SWRCAPP_AREA
                        )
              OR
                 SWRCAPP_AREA = csBloque
             )
         AND vnPriority IS NOT NULL;

      --ACTUALIZANDO LA PRIORIDAD A UN BLOQUE ELECTIVO
      --EN CASO DE QUE LA VARIABLE "vnPriority" TENGA EL VALOR NULL SE EJECUTA LA SIGUIENTE ACTUALIZACION
      UPDATE SWRCAPP A
         SET A.SWRCAPP_AREA_PRIORITY  = (SELECT MIN(B.SWRCAPP_AREA_PRIORITY)
                                           FROM SWRCAPP B
                                          WHERE B.SWRCAPP_AREA_PRIORITY IS NOT NULL
                                            AND B.SWRCAPP_AREA           = csBloque
                                        )
       WHERE A.SWRCAPP_AREA_PRIORITY IS NULL
         AND A.SWRCAPP_AREA           = csBloque
         AND vnPriority              IS NULL;

  END PWAHIAC;
/

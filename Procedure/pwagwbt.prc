DROP PROCEDURE BANINST1.PWAGWBT;

CREATE OR REPLACE PROCEDURE BANINST1.PWAGWBT IS

/*

    TAREA: * Consulta de admiciones para alimentar la lectura del CRM
             para los periodos definidos en "GWBTERM".
    FECHA: 20/12/2010
    AUTOR: GEPC
   MODULO: GENERAL

*/

  vsError VARCHAR2(4000) := NULL;

  cn1        CONSTANT NUMBER(1)    := 1;
  cn2        CONSTANT NUMBER(1)    := 2;
  csEsp      CONSTANT VARCHAR2(1)  := ' ';
  csY        CONSTANT VARCHAR2(1)  := 'Y';
  csA        CONSTANT VARCHAR2(1)  := 'A';
  csPR       CONSTANT VARCHAR2(2)  := 'PR';
  cs99       CONSTANT VARCHAR2(2)  := '99';
  cs88       CONSTANT VARCHAR2(2)  := '88';
  cs440      CONSTANT VARCHAR2(3)  := '440';
  cs115      CONSTANT VARCHAR2(3)  := '115';
  cs221      CONSTANT VARCHAR2(3)  := '221';
  csEsp_     CONSTANT VARCHAR2(3)  := ' - ';
  csYYYY     CONSTANT VARCHAR2(4)  := 'YYYY';
  csPSMA     CONSTANT VARCHAR2(4)  := 'PSMA';
  csPSLC     CONSTANT VARCHAR2(4)  := 'PSLC';
  csPSCI     CONSTANT VARCHAR2(4)  := 'PSCI';
  csPSHC     CONSTANT VARCHAR2(4)  := 'PSHC';
  csTFPA     CONSTANT VARCHAR2(4)  := 'TFPA';
  csTMPA     CONSTANT VARCHAR2(4)  := 'TMPA';
  csNEME     CONSTANT VARCHAR2(4)  := 'NEME';
  cs11110    CONSTANT VARCHAR2(5)  := '11110';
  cs11220    CONSTANT VARCHAR2(5)  := '11220';
  cs11210    CONSTANT VARCHAR2(5)  := '11210';
  cs22220    CONSTANT VARCHAR2(5)  := '22220';
  csGENERAL  CONSTANT VARCHAR2(7)  := 'GENERAL';
  csGWBTCR0  CONSTANT VARCHAR2(7)  := 'GWBTCR0';
  csGWBTCR1  CONSTANT VARCHAR2(7)  := 'GWBTCR1';
  csGWBTCR2  CONSTANT VARCHAR2(7)  := 'GWBTCR2';
  csGWBTCR3  CONSTANT VARCHAR2(7)  := 'GWBTCR3';
  csGWBTCRM  CONSTANT VARCHAR2(7)  := 'GWBTCRM';
  cs11440050 CONSTANT VARCHAR2(8)  := '11440050';
  cs11330010 CONSTANT VARCHAR2(8)  := '11330010';
  csSysDate  CONSTANT DATE         := SYSDATE;
  csUser     CONSTANT VARCHAR2(32) := USER;

  -- Información personal
  -- insertGWBTCR0
  procedure insertGWBTCR0 is

  begin
      insert into gwbtcr0(
      gwbtcr0_pidm,                 gwbtcr0_name_suffix,          gwbtcr0_id,                  gwbtcr0_program_code,
      gwbtcr0_date_banner,          gwbtcr0_sts_adm,              gwbtcr0_term_code,           gwbtcr0_sarhead_code,
      gwbtcr0_sarhead_apls_code,    gwbtcr0_sarhead_add_date,     gwbtcr0_saretry_priority_no, gwbtcr0_saraddr_street_line1,
      gwbtcr0_saraddr_street_line2, gwbtcr0_saraddr_street_line3, gwbtcr0_saraddr_city,        gwbtcr0_saraddr_stat_cde,
      gwbtcr0_saraddr_cnty_cde,     gwbtcr0_saraddr_zip,          gwbtcr0_saraddr_natn_cde,    gwbtcr0_sarphon_pqlf_cde1,
      gwbtcr0_sarphon_phone1,       gwbtcr0_sarphon_pqlf_cde2,    gwbtcr0_sarphon_phone2,      gwbtcr0_sarpers_first_name,
      gwbtcr0_sarpers_last_name,    gwbtcr0_sarpers_middle_name1, gwbtcr0_sarpers_birth_dte,   gwbtcr0_sarpers_gender,
      gwbtcr0_sarpers_citz_cde,     gwbtcr0_sarpcol_iden_cde,     gwbtcr0_sarrqst_ansr_desc,   gwbtcr0_sarrqst_ansr_desc2,
      gwbtcr0_activity_date,        gwbtcr0_user
      )
      select spride.idenPidm,
             spbpers_name_suffix,
             spride.idenIddd,
             (select j.sovlcur_program
                from sovlcur j
               where j.sovlcur_pidm        = a.saradap_pidm
                 and j.sovlcur_key_seqno   = a.saradap_appl_no
                 and j.sovlcur_term_code   = a.saradap_term_code_entry
                 and j.sovlcur_lmod_code   = sb_curriculum_str.f_admissions
                 and j.sovlcur_current_ind = csY
                 and j.sovlcur_active_ind  = csY
                 and j.sovlcur_seqno       = (select min(k.sovlcur_seqno)
                                                from sovlcur k
                                               where k.sovlcur_pidm        = a.saradap_pidm
                                                 and k.sovlcur_key_seqno   = a.saradap_appl_no
                                                 and k.sovlcur_term_code   = a.saradap_term_code_entry
                                                 and k.sovlcur_lmod_code   = sb_curriculum_str.f_admissions
                                                 and k.sovlcur_current_ind = csY
                                                 and k.sovlcur_active_ind  = csY
                                             )
                 and rownum                = cn1
             ) lcurProg,
             a.saradap_appl_date,
             a.saradap_apst_code,
             a.saradap_term_code_entry,
             a.saradap_admt_code,
             (select i.sarhead_apls_code
                from sarhead i
               where i.sarhead_appl_seqno = (select max(j.sarhead_appl_seqno)
                                               from sarhead j
                                              where j.sarhead_aidm = i.sarhead_aidm
                                            )
                 and i.sarhead_aidm       = (select sabiden_aidm
                                               from sabiden
                                              where sabiden_pidm = a.saradap_pidm
                                            )
                 and rownum               = cn1
             ) aplsCode,
             a.saradap_appl_date,
             a.saradap_appl_no,
             spradd.addrLIN1,
             spradd.addrLIN2,
             spradd.addrLIN3,
             spradd.addrCity,
             spradd.addrStat,
             spradd.addrCnty,
             spradd.addrZipp,
             spradd.addrNatn,
             csTFPA,
             (select sprtele_phone_area||csEsp_||sprtele_phone_number||csEsp_||sprtele_phone_ext
                from sprtele
               where sprtele_seqno     = (select max(sprtele_seqno)
                                            from sprtele
                                           where sprtele_tele_code = csTFPA
                                             and sprtele_pidm      = a.saradap_pidm
                                         )
                 and sprtele_tele_code = csTFPA
                 and sprtele_pidm      = a.saradap_pidm
                 and rownum            = cn1
             ) AS teleArea,
             csTMPA,
             (select sprtele_phone_area||csEsp_||sprtele_phone_number||csEsp_||sprtele_phone_ext
                from sprtele
               where sprtele_seqno     = (select max(sprtele_seqno)
                                            from sprtele
                                           where sprtele_tele_code = csTMPA
                                             and sprtele_pidm      = a.saradap_pidm
                                         )
                 and sprtele_tele_code = csTMPA
                 and sprtele_pidm      = a.saradap_pidm
                 and rownum            = cn1
             ) AS teleAre2,
             spride.idenFirs,
             spride.idenLast,
             spride.idenMiii,
             spbpers_birth_date,
             spbpers_sex,
             spbpers_citz_code,
             sorpcol_sbgi_code,
             (select sarquan_answer
                from sarquan g
               where g.sarquan_appl_no         = (select max(h.sarquan_appl_no)
                                                    from sarquan h
                                                   where h.sarquan_seqno           = g.sarquan_seqno
                                                     and h.sarquan_term_code_entry = g.sarquan_term_code_entry
                                                     and h.sarquan_pidm            = g.sarquan_pidm
                                                 )
                 and g.sarquan_seqno           = cn1
                 and g.sarquan_term_code_entry = a.saradap_term_code_entry
                 and g.sarquan_pidm            = a.saradap_pidm
                 and rownum                    = cn1
             ) ANSWER1,
             (select sarquan_answer
                from sarquan g
               where g.sarquan_appl_no         = (select max(h.sarquan_appl_no)
                                                    from sarquan h
                                                   where h.sarquan_seqno           = g.sarquan_seqno
                                                     and h.sarquan_term_code_entry = g.sarquan_term_code_entry
                                                     and h.sarquan_pidm            = g.sarquan_pidm
                                                 )
                 and g.sarquan_seqno           = cn2
                 and g.sarquan_term_code_entry = a.saradap_term_code_entry
                 and g.sarquan_pidm            = a.saradap_pidm
                 and rownum                    = cn1
             ) ANSWER2,
             csSysDate,
             csUSER
        from saradap a,
             spbpers,
             (select spriden_id         as idenIddd,
                     spriden_last_name  AS idenLast,
                     spriden_first_name AS idenFirs,
                     spriden_mi         AS idenMiii,
                     spriden_pidm       AS idenPidm
                from spriden
               where spriden_change_ind is null
             ) spride,
             (select c.spraddr_street_line1 as addrLIN1,
                     c.spraddr_street_line2 as addrLIN2,
                     c.spraddr_street_line3 as addrLIN3,
                     c.spraddr_city         as addrCity,
                     c.spraddr_stat_code    as addrStat,
                     c.spraddr_cnty_code    as addrCnty,
                     c.spraddr_zip          as addrZipp,
                     c.spraddr_natn_code    as addrNatn,
                     c.spraddr_pidm         as addrPidm
                from spraddr c
               where c.spraddr_atyp_code = csPR
                 and c.spraddr_seqno     = (select max(d.spraddr_seqno)
                                              from spraddr d
                                             where d.spraddr_atyp_code = csPR
                                               and d.spraddr_pidm      = c.spraddr_pidm
                                           )
             ) spradd,
             sorpcol
--       where a.saradap_appl_no          = (select max(b.saradap_appl_no)
--                                             from saradap b
--                                            where b.saradap_term_code_entry = a.saradap_term_code_entry
--                                              and b.saradap_pidm            = a.saradap_pidm
--                                          )
         where a.saradap_pidm             = spbpers_pidm
         and a.saradap_pidm             = spride.idenPidm
         and a.saradap_pidm             = spradd.addrPidm(+)
         and a.saradap_pidm             = sorpcol_pidm(+)
         and a.saradap_term_code_entry in (select gwbterm_term_code
                                             from gwbterm
                                            where gwbterm_check_ind = csY
                                          );

  exception
      when others then
           vsError := sqlerrm;

           rollback;

           insert into gwrerrm(gwrerrm_error,gwrerrm_origin) values(vsError, csGWBTCR0);

           commit;
  end insertGWBTCR0;

  -- Promedios
  -- insertGWBTCR1
  procedure insertGWBTCR1 is

  begin
      insert into gwbtcr1
      (
      gwbtcr1_pidm,       gwbtcr1_psma,       gwbtcr1_pslc,       gwbtcr1_psci,
      gwbtcr1_pshc,       gwbtcr1_nem,        gwbtcr1_psu_score,
      gwbtcr1_exp_autpsu, gwbtcr1_exp_autcol, gwbtcr1_exp_esar,   gwbtcr1_exp_eses,
      gwbtcr1_exp_conv,   gwbtcr1_exp_desc,   gwbtcr1_exp_bher,   gwbtcr1_exp_bpar,
      gwbtcr1_exp_basi,   gwbtcr1_exp_bdep
      )
      select
        gwbtcr.tcr0Pidm,
      fwascor(gwbtcr.tcr0Pidm, csPSMA),
      fwascor(gwbtcr.tcr0Pidm, csPSLC),
      fwascor(gwbtcr.tcr0Pidm, csPSCI),
      fwascor(gwbtcr.tcr0Pidm, csPSHC),
      fwascor(gwbtcr.tcr0Pidm, csNEME),
      fwappsu(gwbtcr.tcr0Pidm),
      fwrbeca(gwbtcr.tcr0Pidm, cs11110),
      fwrbeca(gwbtcr.tcr0Pidm, cs440),
      fwrbeca(gwbtcr.tcr0Pidm, cs11220),
      fwrbeca(gwbtcr.tcr0Pidm, cs11210),
      fwrbeca(gwbtcr.tcr0Pidm, cs99),
      fwrbeca(gwbtcr.tcr0Pidm, cs88,cs11440050),
      fwrbeca(gwbtcr.tcr0Pidm, cs11330010),
      fwrbeca(gwbtcr.tcr0Pidm, cs115),
      fwrbeca(gwbtcr.tcr0Pidm, cs221),
      fwrbeca(gwbtcr.tcr0Pidm, cs22220)
 from (select distinct gwbtcr0_pidm as tcr0Pidm
         from gwbtcr0
      ) gwbtcr;

  exception
      when others then
           vsError := sqlerrm;

           rollback;

           insert into gwrerrm(gwrerrm_error,gwrerrm_origin) values(vsError, csGWBTCR1);

           commit;
  end insertGWBTCR1;

  -- Correo electronico
  -- insertGWBTCR2
  procedure insertGWBTCR2 is

  begin
      insert into gwbtcr2
      (
      gwbtcr2_pidm,
      gwbtcr2_sarphon_pqlf_cde3,
      gwbtcr2_sarphon_phone3
      )
      select
      gwbtcr1_pidm,
      gorema.emalCode,
      gorema.emalAddr
        from (select goremal_emal_code     as emalCode,
                     goremal_email_address as emalAddr,
                     goremal_pidm          as emalPidm
                from goremal
               where goremal_status_ind = csA
             ) gorema,
             gwbtcr1
       where gorema.emalPidm = gwbtcr1_pidm;

  exception
      when others then
           vsError := sqlerrm;

           rollback;

           insert into gwrerrm(gwrerrm_error,gwrerrm_origin) values(vsError, csGWBTCR2);

           commit;
  end insertGWBTCR2;

  -- Registro de estado
  -- insertGWBTCR3
  procedure insertGWBTCR3 is

  begin
      insert into gwbtcr3
      (
      gwbtcr3_pidm,
      gwbtcr3_dec_adm,
      gwbtcr3_date_fin,
      gwbtcr3_user_fin
      )
      select
      gwbtcr1_pidm,
      sarapp.appdCode,
      sarapp.appdDate,
      sarapp.appdUser
        from (select e.sarappd_apdc_code       as appdcode,
                     e.sarappd_apdc_date       as appddate,
                     e.sarappd_user            as appduser,
                     e.sarappd_term_code_entry as appdterm,
                     e.sarappd_pidm            as appdpidm
                from sarappd e
               where (e.sarappd_appl_no, e.sarappd_seq_no) = (select max(f.sarappd_appl_no),
                                                                     max(f.sarappd_seq_no)
                                                                from sarappd f
                                                               where f.sarappd_term_code_entry = e.sarappd_term_code_entry
                                                                 and f.sarappd_pidm            = e.sarappd_pidm
                                                             )
             ) sarapp,
            gwbtcr1
      where sarapp.appdpidm = gwbtcr1_pidm;
        --and sarapp.appdterm = gwbtcr0_term_code;

  exception
      when others then
           vsError := sqlerrm;

           rollback;

           insert into gwrerrm(gwrerrm_error,gwrerrm_origin) values(vsError, csGWBTCR3);

           commit;
  end insertGWBTCR3;


  -- Promedios
  -- insertGWBTCR1
  procedure insertGWBTCR4 is

  begin
      insert into gwbtcr4
      (
      gwbtcr4_pidm,       GWBTCR4_PROGRAM_CODE, GWBTCR4_PROGRAM_SCORE
      )
      select
      gwbtcr0_pidm,
      gwbtcr0_program_code,
      fwapond(gwbtcr0_pidm, gwbtcr0_program_code)
      from gwbtcr0;
  exception
      when others then
           vsError := sqlerrm;

           rollback;

           insert into gwrerrm(gwrerrm_error,gwrerrm_origin) values(vsError, csGWBTCR1);

           commit;
  end insertGWBTCR4;

  -- homologacion de las consultas anteriores
  -- insertGWBTCRM
  procedure insertGWBTCRM is

  begin
      insert into gwbtcrm
      (
      gwbtcrm_name_suffix,          gwbtcrm_id,                  gwbtcrm_program_code,
      gwbtcrm_date_banner,
      gwbtcrm_sts_adm,
      gwbtcrm_term_code,            gwbtcrm_sarhead_code,
      gwbtcrm_sarhead_apls_code,    gwbtcrm_sarhead_add_date,     gwbtcrm_saretry_priority_no, gwbtcrm_saraddr_street_line1,
      gwbtcrm_saraddr_street_line2, gwbtcrm_saraddr_street_line3, gwbtcrm_saraddr_city,        gwbtcrm_saraddr_stat_cde,
      gwbtcrm_saraddr_cnty_cde,     gwbtcrm_saraddr_zip,          gwbtcrm_saraddr_natn_cde,    gwbtcrm_sarphon_pqlf_cde1,
      gwbtcrm_sarphon_phone1,       gwbtcrm_sarphon_pqlf_cde2,    gwbtcrm_sarphon_phone2,
      gwbtcrm_sarpers_first_name,   gwbtcrm_sarpers_last_name,   gwbtcrm_sarpers_middle_name1,
      gwbtcrm_sarpers_birth_dte,    gwbtcrm_sarpers_gender,       gwbtcrm_sarpers_citz_cde,
      gwbtcrm_sarpcol_iden_cde,     gwbtcrm_sarrqst_ansr_desc,   gwbtcrm_sarrqst_ansr_desc2,
      gwbtcrm_activity_date,        gwbtcrm_user ,
      gwbtcrm_psma,       gwbtcrm_pslc,       gwbtcrm_psci,
      gwbtcrm_pshc,       gwbtcrm_nem,        gwbtcrm_prog_score, gwbtcrm_psu_score,
      gwbtcrm_exp_autpsu, gwbtcrm_exp_autcol, gwbtcrm_exp_esar,   gwbtcrm_exp_eses,
      gwbtcrm_exp_conv,   gwbtcrm_exp_desc,   gwbtcrm_exp_bher,   gwbtcrm_exp_bpar,
      gwbtcrm_exp_basi,   gwbtcrm_exp_bdep,
      gwbtcrm_sarphon_pqlf_cde3,
      gwbtcrm_sarphon_phone3,
      gwbtcrm_dec_adm,
      gwbtcrm_date_fin,
      gwbtcrm_user_fin
      )
      select
      gwbtcr0_name_suffix,          gwbtcr0_id,                  gwbtcr0_program_code,
      gwbtcr0_date_banner,
      gwbtcr0_sts_adm,
      gwbtcr0_term_code,            gwbtcr0_sarhead_code,
      gwbtcr0_sarhead_apls_code,    gwbtcr0_sarhead_add_date,     gwbtcr0_saretry_priority_no, gwbtcr0_saraddr_street_line1,
      gwbtcr0_saraddr_street_line2, gwbtcr0_saraddr_street_line3, gwbtcr0_saraddr_city,        gwbtcr0_saraddr_stat_cde,
      gwbtcr0_saraddr_cnty_cde,     gwbtcr0_saraddr_zip,          gwbtcr0_saraddr_natn_cde,    gwbtcr0_sarphon_pqlf_cde1,
      gwbtcr0_sarphon_phone1,       gwbtcr0_sarphon_pqlf_cde2,    gwbtcr0_sarphon_phone2,
      gwbtcr0_sarpers_first_name,   gwbtcr0_sarpers_last_name,   gwbtcr0_sarpers_middle_name1,
      gwbtcr0_sarpers_birth_dte,    gwbtcr0_sarpers_gender,       gwbtcr0_sarpers_citz_cde,
      gwbtcr0_sarpcol_iden_cde,     gwbtcr0_sarrqst_ansr_desc,   gwbtcr0_sarrqst_ansr_desc2,
      gwbtcr0_activity_date,        gwbtcr0_user ,
      gwbtcr1_psma,       gwbtcr1_pslc,       gwbtcr1_psci,
      gwbtcr1_pshc,       gwbtcr1_nem,        GWBTCR4_PROGRAM_SCORE, gwbtcr1_psu_score,
      gwbtcr1_exp_autpsu, gwbtcr1_exp_autcol, gwbtcr1_exp_esar,   gwbtcr1_exp_eses,
      gwbtcr1_exp_conv,   gwbtcr1_exp_desc,   gwbtcr1_exp_bher,   gwbtcr1_exp_bpar,
      gwbtcr1_exp_basi,   gwbtcr1_exp_bdep,
      gwbtcr2_sarphon_pqlf_cde3,
      gwbtcr2_sarphon_phone3,
      gwbtcr3_dec_adm,
      gwbtcr3_date_fin,
      gwbtcr3_user_fin
        from gwbtcr0,
             gwbtcr1,
             gwbtcr2,
             gwbtcr3,
             gwbtcr4
       where gwbtcr0_pidm = gwbtcr1_pidm(+)
         and gwbtcr0_pidm = gwbtcr2_pidm(+)
         and gwbtcr0_pidm = gwbtcr3_pidm(+)
         and gwbtcr0_pidm = gwbtcr4_pidm(+);

  exception
      when others then
           vsError := sqlerrm;

           rollback;

           insert into gwrerrm(gwrerrm_error,gwrerrm_origin) values(vsError, csGWBTCRM);

           commit;
  end insertGWBTCRM;

  BEGIN
      -- Información personal
      insertGWBTCR0;
      --Promedios
      insertGWBTCR1;
      -- Correo electronico
      insertGWBTCR2;
      -- Registro de estado
      insertGWBTCR3;
      -- homologacion de las consultas anteriores
      insertGWBTCRM;

      COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
           vsError := SQLERRM;

           ROLLBACK;

           INSERT INTO GWRERRM(GWRERRM_ERROR,GWRERRM_ORIGIN) VALUES(vsError, csGENERAL);

           COMMIT;

  END PWAGWBT;
/

DROP PROCEDURE BANINST1.PWADXCA;

CREATE OR REPLACE PROCEDURE BANINST1.PWADXCA (psReclDesc VARCHAR2)
IS
   vnRow         INTEGER := 0;
   vnExists      INTEGER := 0;
   vnColumnas    INTEGER := 30;
   vsProg        sgbstdn.sgbstdn_program_1%TYPE;
   vsPerio1      sgbstdn.sgbstdn_term_code_admit%TYPE;
   vsPerio2      sgbstdn.sgbstdn_term_code_admit%TYPE;
   tabColumna   Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vsInicioPag   VARCHAR2 (10) := NULL;

CURSOR cuReporte_Cambio (vsProg        sgbstdn.sgbstdn_program_1%TYPE,
                         vsPerio1      sgbstdn.sgbstdn_term_code_admit%TYPE,
                         vsPerio2      sgbstdn.sgbstdn_term_code_admit%TYPE)
  IS
  select smrprle_program
           , smrprle_program_desc
         , reg_nueing_per1
         , reg_nueing_per2
         , reg_anti_per1
         , reg_anti_per2
         , libre_per1
         , libre_per2
         , psu_ant_per1
         , psu_ant_per2
         , convalidacion_per1
         , convalidacion_per2
         , estu_extranjeros_per1
         , estu_extranjeros_per2
         , vespertino_per1
         , vespertino_per2
         , bach_ingles_per1
         , bach_ingles_per2
         , bach_frances_per1
         , bach_frances_per2
         , bach_aleman_per1
         , bach_aleman_per2
         , bach_artes_per1
         , bach_artes_per2
         , lt_otra_u_per1
         , lt_otra_u_per2
         , lt_uft_per1
         , lt_uft_per2
         , adm_med_per1
         , adm_med_per2
  from smrprle,
       /***** Regular Nuevo Ingreso per1 *****/
      (select prog_code, prog_des, sum(pidm) reg_nueing_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select code_prog, pidm_g1, admt_peri, admt_code, nue_ant
                   from (select g1.sgbstdn_program_1         code_prog
                              , g1.sgbstdn_pidm              pidm_g1
                              , g1.sgbstdn_term_code_admit   admt_peri
                              , g1.sgbstdn_admt_code         admt_code
                              , fwatyaluft(g1.sgbstdn_pidm, g1.sgbstdn_term_code_admit) nue_ant
                         from sgbstdn g1
                         where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                           from sgbstdn g2
                                                           where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                           and g1.sgbstdn_admt_code = 'AD'
                           and g1.sgbstdn_term_code_admit = vsPerio1)
             where nue_ant = 'N')a
       where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) RNIP1,
       /***** Regular Nuevo Ingreso per2 *****/
      (select prog_code, prog_des, sum(pidm) reg_nueing_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select code_prog, pidm_g1, admt_peri, admt_code, nue_ant
                   from (select g1.sgbstdn_program_1         code_prog
                              , g1.sgbstdn_pidm              pidm_g1
                              , g1.sgbstdn_term_code_admit   admt_peri
                              , g1.sgbstdn_admt_code         admt_code
                              , fwatyaluft(g1.sgbstdn_pidm, g1.sgbstdn_term_code_admit) nue_ant
                         from sgbstdn g1
                         where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                           from sgbstdn g2
                                                           where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                           and g1.sgbstdn_admt_code = 'AD'
                           and g1.sgbstdn_term_code_admit = vsPerio2)
                   where nue_ant = 'N')a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) RNIP2,
       /***** Regular Antiguo per1 *****/
      (select prog_code, prog_des, sum(pidm) reg_anti_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select code_prog, pidm_g1, admt_peri, admt_code, nue_ant
                   from (select g1.sgbstdn_program_1         code_prog
                              , g1.sgbstdn_pidm              pidm_g1
                              , g1.sgbstdn_term_code_admit   admt_peri
                              , g1.sgbstdn_admt_code         admt_code
                              , fwatyaluft(g1.sgbstdn_pidm, g1.sgbstdn_term_code_admit) nue_ant
                         from sgbstdn g1
                         where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                           from sgbstdn g2
                                                           where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                           and g1.sgbstdn_admt_code = 'AD'
                           and g1.sgbstdn_term_code_admit = vsPerio1)
                   where nue_ant = 'A')a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) RAP1,
       /***** Regular Antiguo per2 *****/
      (select prog_code, prog_des, sum(pidm) reg_anti_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select code_prog, pidm_g1, admt_peri, admt_code, nue_ant
                   from (select g1.sgbstdn_program_1         code_prog
                              , g1.sgbstdn_pidm              pidm_g1
                              , g1.sgbstdn_term_code_admit   admt_peri
                              , g1.sgbstdn_admt_code         admt_code
                              , fwatyaluft(g1.sgbstdn_pidm, g1.sgbstdn_term_code_admit) nue_ant
                         from sgbstdn g1
                         where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                           from sgbstdn g2
                                                           where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                           and g1.sgbstdn_admt_code = 'AD'
                           and g1.sgbstdn_term_code_admit = vsPerio2)
                   where nue_ant = 'A')a
            where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) RAP2,
       /***** Libre per1 *****/
      (select prog_code, prog_des, sum(pidm) libre_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'AL'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) LP1,
       /***** Libre per2 *****/
      (select prog_code, prog_des, sum(pidm) libre_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'AL'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) LP2,
       /***** PSU Anterior per1 *****/
      (select prog_code, prog_des, sum(pidm) psu_ant_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'PA'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) PSUAP1,
       /***** PSU Anterior per2 *****/
      (select prog_code, prog_des, sum(pidm) psu_ant_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'PA'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) PSUAP2,
       /***** Convalidación per1 *****/
      (select prog_code, prog_des, sum(pidm) convalidacion_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'CO'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) CP1,
       /***** Convalidación per2 *****/
      (select prog_code, prog_des, sum(pidm) convalidacion_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'CO'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) CP2,
       /***** Estudios Extranjeros per1 *****/
      (select prog_code, prog_des, sum(pidm) estu_extranjeros_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                  , (select g1.sgbstdn_program_1         code_prog
                           , g1.sgbstdn_pidm              pidm_g1
                           , g1.sgbstdn_term_code_admit   admt_peri
                           , g1.sgbstdn_admt_code         admt_code
                      from sgbstdn g1
                      where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                        from sgbstdn g2
                                                        where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                        and g1.sgbstdn_admt_code = 'EE'
                        and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) EEP1,
       /***** Estudios Extranjeros per2 *****/
      (select prog_code, prog_des, sum(pidm) estu_extranjeros_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'EE'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) EEP2,
       /***** Vespertino per1 *****/
      (select prog_code, prog_des, sum(pidm) vespertino_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'VP'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) VP1,
       /***** Vespertino per2 *****/
      (select prog_code, prog_des, sum(pidm) vespertino_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'VP'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) VP2,
       /*****     Bachillerato Inglés per1 *****/
      (select prog_code, prog_des, sum(pidm) bach_ingles_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'BI'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) BIP1,
       /***** Bachillerato Inglés per2 *****/
      (select prog_code, prog_des, sum(pidm) bach_ingles_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
              from smrprle
                 , (select g1.sgbstdn_program_1         code_prog
                         , g1.sgbstdn_pidm              pidm_g1
                         , g1.sgbstdn_term_code_admit   admt_peri
                         , g1.sgbstdn_admt_code         admt_code
                    from sgbstdn g1
                    where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                      from sgbstdn g2
                                                      where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                    and g1.sgbstdn_admt_code = 'BI'
                    and g1.sgbstdn_term_code_admit = vsPerio2)a
              where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) BIP2,
       /***** Bachillerato Francés per1 *****/
      (select prog_code, prog_des, sum(pidm) bach_frances_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'BF'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) BFP1,
       /***** Bachillerato Francés per2 *****/
      (select prog_code, prog_des, sum(pidm) bach_frances_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'BF'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) BFP2,
       /***** Bachillerato Alemán per1 *****/
      (select prog_code, prog_des, sum(pidm) bach_aleman_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'BA'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) BAP1,
       /***** Bachillerato Alemán per2 *****/
      (select prog_code, prog_des, sum(pidm) bach_aleman_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'BA'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) BAP2,
       /***** Bachillerato Artes per1 *****/
      (select prog_code, prog_des, sum(pidm) bach_artes_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'BR'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) BRP1,
       /***** Bachillerato Artes per2 *****/
      (select prog_code, prog_des, sum(pidm) bach_artes_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'BR'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) BRP2,
       /***** Licenciatura / Tit. Otras Univ per1 *****/
      (select prog_code, prog_des, sum(pidm) lt_otra_u_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'LO'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
       where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) LTOUP1,
       /***** Licenciatura / Tit. Otras Univ per2 *****/
      (select prog_code, prog_des, sum(pidm) lt_otra_u_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'LO'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) LTOUP2,
       /***** Licenciatura / Tit. UFT per1 *****/
      (select prog_code, prog_des, sum(pidm) lt_uft_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'LU'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) LTUFTP1,
       /***** Licenciatura / Tit. UFT per2 *****/
      (select prog_code, prog_des, sum(pidm) lt_uft_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'LU'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
       where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) LTUFTP2,
       /***** Admisión IV Medio *****/
      (select prog_code, prog_des, sum(pidm) adm_med_per1
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'CM'
                     and g1.sgbstdn_term_code_admit = vsPerio1)a
             where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) CMP1,
       /***** Admisión IV Medio *****/
      (select prog_code, prog_des, sum(pidm) adm_med_per2
       from (select smrprle_program                    prog_code
                  , smrprle_program_desc               prog_des
                  , decode(a.pidm_g1, null,0,1)        pidm
                  , a.admt_code                        peri_admit
             from smrprle
                , (select g1.sgbstdn_program_1         code_prog
                        , g1.sgbstdn_pidm              pidm_g1
                        , g1.sgbstdn_term_code_admit   admt_peri
                        , g1.sgbstdn_admt_code         admt_code
                   from sgbstdn g1
                   where g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                                     from sgbstdn g2
                                                     where g1.sgbstdn_pidm = g2.sgbstdn_pidm)
                     and g1.sgbstdn_admt_code = 'CM'
                     and g1.sgbstdn_term_code_admit = vsPerio2)a
       where smrprle_program = a.code_prog(+))
       group by prog_code, prog_des
       order by prog_des, prog_code) CMP2
  where RNIP1.prog_code(+) = smrprle_program
    and RNIP2.prog_code(+) = smrprle_program
    and RAP1.prog_code(+) = smrprle_program
    and RAP2.prog_code(+) = smrprle_program
    and LP1.prog_code(+) = smrprle_program
    and LP2.prog_code(+) = smrprle_program
    and PSUAP1.prog_code(+) = smrprle_program
    and PSUAP2.prog_code(+) = smrprle_program
    and CP1.prog_code(+) = smrprle_program
    and CP2.prog_code(+) = smrprle_program
    and EEP1.prog_code(+) = smrprle_program
    and EEP2.prog_code(+) = smrprle_program
    and VP1.prog_code(+) = smrprle_program
    and VP2.prog_code(+) = smrprle_program
    and BIP1.prog_code(+) = smrprle_program
    and BIP2.prog_code(+) = smrprle_program
    and BFP1.prog_code(+) = smrprle_program
    and BFP2.prog_code(+) = smrprle_program
    and BAP1.prog_code(+) = smrprle_program
    and BAP2.prog_code(+) = smrprle_program
    and BRP1.prog_code(+) = smrprle_program
    and BRP2.prog_code(+) = smrprle_program
    and LTOUP1.prog_code(+) = smrprle_program
    and LTOUP2.prog_code(+) = smrprle_program
    and LTUFTP1.prog_code(+) = smrprle_program
    and LTUFTP2.prog_code(+) = smrprle_program
    and CMP1.prog_code(+) = smrprle_program
    and CMP2.prog_code(+) = smrprle_program
    and (smrprle_program = vsProg or vsProg is null);

BEGIN

   IF Pk_Login.F_ValidacionDeAcceso (pk_login.vgsUSR)
   THEN
      RETURN;
   END IF;

    /* Parámetros */
    --Se busca el valor de la cookie (parámetro) para asignarlo al filtro del query.
    vsProg   := pk_ObjHtml.getValueCookie ('psProgr');
    vsPerio1 := pk_ObjHtml.getValueCookie ('psPerio');
    vsPerio2 := pk_ObjHtml.getValueCookie ('psTerm');

  -- Número de columnas de la tabla --
   FOR vnI IN 1 .. vnColumnas
   LOOP
      tabColumna.EXTEND (vnI);
      tabColumna (vnI) := NULL;
   END LOOP;

   /* Encabezado de las columnas */
   tabColumna (1) := 'Programa';
   tabColumna (2) := 'Programa Descripción';
   tabColumna (3) := 'Regular Nuevo Ingreso Periodo 1';
   tabColumna (4) := 'Regular Nuevo Ingreso Periodo 2';
   tabColumna (5) := 'Regular Avanzado Periodo 1';
   tabColumna (6) := 'Regular Avanzado Periodo 2';
   tabColumna (7) := 'Libre Periodo 1';
   tabColumna (8) := 'Libre Periodo 2';
   tabColumna (9) := 'PSU Anterior Periodo 1';
   tabColumna (10) := 'PSU Anterior Periodo 2';
   tabColumna (11) := 'Convalidación Periodo 1';
   tabColumna (12) := 'Convalidación Periodo 2';
   tabColumna (13) := 'Estudios Extranjeros Periodo 1';
   tabColumna (14) := 'Estudios Extranjeros Periodo 2';
   tabColumna (15) := 'Vespertino Periodo 1';
   tabColumna (16) := 'Vespertino Periodo 2';
   tabColumna (17) := 'Bach. Ingles Periodo 1';
   tabColumna (18) := 'Bach. Ingles Periodo 2';
   tabColumna (19) := 'Bach. Francés Periodo 1';
   tabColumna (20) := 'Bach. Francés Periodo 2';
   tabColumna (21) := 'Bach. Alemán Periodo 1';
   tabColumna (22) := 'Bach. Alemán Periodo 2';
   tabColumna (23) := 'Bach. Artes Periodo 1';
   tabColumna (24) := 'Bach. Artes Periodo 2';
   tabColumna (25) := 'L/T otra U Periodo 1';
   tabColumna (26) := 'L/T otra U Periodo 2';
   tabColumna (27) := 'L/T UFT Periodo 1';
   tabColumna (28) := 'L/T UFT Periodo 2';
   tabColumna (29) := 'Admisión IV Medio Periodo 1';
   tabColumna (30) := 'Admisión IV Medio Periodo 2';

      FOR regRep IN cuReporte_Cambio(vsProg, vsPerio1, vsPerio2) LOOP
          IF vnRow = 0 THEN
             Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag,
                                                psSubtitulo=>'Periodo 1: '||vsPerio1||'  '||Pk_Catalogo.PERIODO(vsPerio1)||
                                                        '<br> Periodo 2: '||vsPerio2||'  '||Pk_Catalogo.PERIODO(vsPerio2));
             vsInicioPag := 'SALTO';
             vnRow  := 0;
          END IF;

          htp.p(
          '<tr>
          <td valign="top">'||regRep.smrprle_program||'</td>
          <td valign="top">'||regRep.smrprle_program_desc||'</td>
          <td valign="top">'||regRep.reg_nueing_per1||'</td>
          <td valign="top">'||regRep.reg_nueing_per2||'</td>
          <td valign="top">'||regRep.reg_anti_per1||'</td>
          <td valign="top">'||regRep.reg_anti_per2||'</td>
          <td valign="top">'||regRep.libre_per1||'</td>
          <td valign="top">'||regRep.libre_per2||'</td>
          <td valign="top">'||regRep.psu_ant_per1||'</td>
          <td valign="top">'||regRep.psu_ant_per2||'</td>
          <td valign="top">'||regRep.convalidacion_per1||'</td>
          <td valign="top">'||regRep.convalidacion_per2||'</td>
          <td valign="top">'||regRep.estu_extranjeros_per1||'</td>
          <td valign="top">'||regRep.estu_extranjeros_per2||'</td>
          <td valign="top">'||regRep.vespertino_per1||'</td>
          <td valign="top">'||regRep.vespertino_per2||'</td>
          <td valign="top">'||regRep.bach_ingles_per1||'</td>
          <td valign="top">'||regRep.bach_ingles_per2||'</td>
          <td valign="top">'||regRep.bach_frances_per1||'</td>
          <td valign="top">'||regRep.bach_frances_per2||'</td>
          <td valign="top">'||regRep.bach_aleman_per1||'</td>
          <td valign="top">'||regRep.bach_aleman_per2||'</td>
          <td valign="top">'||regRep.bach_artes_per1||'</td>
          <td valign="top">'||regRep.bach_artes_per2||'</td>
          <td valign="top">'||regRep.lt_otra_u_per1||'</td>
          <td valign="top">'||regRep.lt_otra_u_per2||'</td>
          <td valign="top">'||regRep.lt_uft_per1||'</td>
          <td valign="top">'||regRep.lt_uft_per2||'</td>
          <td valign="top">'||regRep.adm_med_per1||'</td>
          <td valign="top">'||regRep.adm_med_per2||'</td>
          ');

          vnExists   := 1;
          vnRow      := vnRow + 1;
      END LOOP;

   IF vnExists = 0
   THEN
      HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- es omitido el encabezado del reporte pero se agrega el salto de pagina
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   END IF;

   HTP.p ('</table><br/></body></html>');
EXCEPTION
   WHEN OTHERS
   THEN
      HTP.P (SQLERRM);
END PWADXCA;
/


DROP PUBLIC SYNONYM PWADXCA;

CREATE PUBLIC SYNONYM PWADXCA FOR BANINST1.PWADXCA;


GRANT EXECUTE ON BANINST1.PWADXCA TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWADXCA TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWADXCA TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWADXCA TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWADXCA TO WWW2_USER;

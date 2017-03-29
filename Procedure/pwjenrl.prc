CREATE OR REPLACE PROCEDURE BANINST1.pwjenrl(pdNextDate IN OUT DATE) IS
  /*
         TAREA: Actualizar la cantidad de inscritos en la programación académica
         FECHA: 18/02/2014
         AUTOR: GEPC
        MODULO: Programación académica

                * Etapas de actualización
                    1. UPDATE INCORRECT ENROLLMENT COUNT ON SSBSECT
                    3. UPDATE INCORRECT WAITING LIST COUNT ON SSBSECT
                    5. UPDATE ENROLLMENT COUNT ON XLIST RECORDS SSBXLST
                    7. UPDATE INCORRECT ENROLLMENT COUNT ON RESERVED SEATS
                    8. UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS

  */

  TYPE regCupos  IS RECORD(rTerm SFRSTCR.SFRSTCR_TERM_CODE%TYPE,
                           rCrnn SFRSTCR.SFRSTCR_CRN%TYPE,
                           rEnrl NUMBER(4),
                           rCred NUMBER(5)
                          );

  TYPE regCensus IS RECORD(rTerm SFRSTCR.SFRSTCR_TERM_CODE%TYPE,
                           rCrnn SFRSTCR.SFRSTCR_CRN%TYPE,
                           rEnrl NUMBER(5)
                          );

  TYPE regResv   IS RECORD(rTerm SSRRESV.SSRRESV_TERM_CODE%TYPE,
                           rCrnn SSRRESV.SSRRESV_CRN%TYPE,
                           rSeqn SSRRESV.SSRRESV_SEQ_NO%TYPE,
                           rEnrl NUMBER(4)
                          );

  TYPE tableResv   IS TABLE OF regResv   INDEX BY BINARY_INTEGER;
  TYPE tableCensus IS TABLE OF regCensus INDEX BY BINARY_INTEGER;
  TYPE tableCupos  IS TABLE OF regCupos  INDEX BY BINARY_INTEGER;

  tblResv   tableResv;
  tblCensus tableCensus;
  tblCupos  tableCupos;
  vsError   VARCHAR2(10000) := NULL;
  vnSeqn    NUMBER(8)       := 0;
  vnCasos   NUMBER(8)       := 0;
  vnRows    NUMBER(4)       := 0;
  vbAudTF   BOOLEAN         := FALSE;

  cdNext            CONSTANT DATE         := TO_DATE(TO_CHAR(SYSDATE+1,'DD/MM/YYYY')||' '||'01:00:00','DD/MM/YYYY HH24:MI:SS');
  cdLimiteEjecucion CONSTANT DATE         := TO_DATE(TO_CHAR(SYSDATE,  'DD/MM/YYYY')||' '||'23:30:00','DD/MM/YYYY HH24:MI:SS');
  cdTysDate         CONSTANT DATE         := TRUNC(SYSDATE);
  cn0               CONSTANT NUMBER(1)    := 0;
  cn1               CONSTANT NUMBER(1)    := 1;
  csY               CONSTANT VARCHAR2(1)  := 'Y';
  csA               CONSTANT VARCHAR2(1)  := 'A';
  csN               CONSTANT VARCHAR2(1)  := 'N';
  csF               CONSTANT VARCHAR2(1)  := 'F';
  cs0               CONSTANT VARCHAR2(1)  := '0';
  csRE              CONSTANT VARCHAR2(2)  := 'RE';
  csRW              CONSTANT VARCHAR2(2)  := 'RW';
  csALL             CONSTANT VARCHAR2(3)  := 'ALL';
  csYYYY            CONSTANT VARCHAR2(4)  := 'YYYY';
  csYear1           CONSTANT VARCHAR2(4)  := to_char(sysdate,csYYYY);
  csYear2           CONSTANT VARCHAR2(4)  := to_char(sysdate,csYYYY)+cn1;
  cs000000          CONSTANT VARCHAR2(6)  := '000000';
  csPWJENRL         CONSTANT VARCHAR2(7)  := 'PWJENRL';
  csKWACUPO         CONSTANT VARCHAR2(7)  := 'KWACUPO';
  csUser            CONSTANT VARCHAR2(32) := user;

  --secuencia de proceso
  --getMaxProceso
  function getMaxProceso return number is

  vnSeqnMax NUMBER := 0;

  begin
      SELECT SQC_SWRCUPO.NEXTVAL
       INTO vnSeqnMax
        FROM DUAL;

      return vnSeqnMax;

  end getMaxProceso;

  --valida que no exista un proceso en ejecución
  --getExecute
  function getExecute return boolean is

  vsExists varchar2(1) := null;

  begin
      select csY
        into vsExists
        from swrcupo
       where trunc(swrcupo_begin)  = cdTysDate
         and swrcupo_end          is null
         and swrcupo_seqn_numb     = (select max(swrcupo_seqn_numb)
                                        from swrcupo
                                       where swrcupo_proceso in (csPWJENRL,csKWACUPO)
                                     )
         and swrcupo_proceso      in (csPWJENRL,csKWACUPO);




      return (csY = vsExists);

  exception
      when no_data_found then
           return false;

  end getexecute;

  --verifica que el JOB pueda ser ejecutado
  --getExecuteTF
  FUNCTION getExecuteTF RETURN BOOLEAN IS

  vnUno NUMBER(1) := 0;

  csJOB CONSTANT VARCHAR2(3) := 'JOB';

  BEGIN
      SELECT cn1
        INTO vnUno
        FROM SWBPROC
       WHERE SWBPROC_EXEC_IND = csY
         AND SWBPROC_CODE     = csJOB;

      RETURN (vnUno = cn1);
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
           RETURN FALSE;
      WHEN OTHERS THEN
           RETURN FALSE;
  END getExecuteTF;

  --verifica que la auditoria sea ejecutada
  --getAuditoriaTF
  FUNCTION getAuditoriaTF RETURN BOOLEAN IS

  vnUno NUMBER(1) := 0;

  csAJOB CONSTANT VARCHAR2(4) := 'AJOB';

  BEGIN
      SELECT cn1
        INTO vnUno
        FROM SWBPROC
       WHERE SWBPROC_EXEC_IND = csY
         AND SWBPROC_CODE     = csAJOB;

      RETURN (vnUno = cn1);
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
           RETURN FALSE;
      WHEN OTHERS THEN
           RETURN FALSE;
  END getAuditoriaTF;

  --REGISTRA EL AVANCE DEL PROCESO PARA CREAR MATERIAS EN LA PROGRAMACIÓN ACADEMICA
  --auditoria
  procedure auditoria(psAccion  varchar2,
                      psProceso varchar2,
                      psError   varchar2 default null
                     ) IS

  cnSeqnCode CONSTANT NUMBER       := vnSeqn;
  csProceso  CONSTANT VARCHAR2(40) := psProceso;

  begin
      --verifica que la auditoria sea ejecutada o no "getAuditoriaTF()"
      if not vbAudTF then
         return;
      end if;

      if    psAccion = 'I' then
            insert into swrcupo
            (swrcupo_seqn_numb,
             swrcupo_camp_code,
             swrcupo_term_code,
             swrcupo_pidm,
             swrcupo_crn,
             swrcupo_rsts_code,
             swrcupo_user,
             swrcupo_proceso
            )
            values
            (cnSeqnCode,
             cs0,
             cs000000,
             cn0,
             cn0,
             cs0,
             csUser,
             csProceso
            );

      elsif psAccion = 'U' then
            update swrcupo
               set swrcupo_end       = sysdate,
                   swrcupo_error     = psError
             where swrcupo_seqn_numb = cnSeqnCode
               and swrcupo_proceso   = csProceso;

      end if;

      commit;

  end auditoria;

  --registra periodos a tomar encuenta
  --setTermPtrmCamp
  procedure setTermPtrmCamp is

  cs201460 constant varchar2(6) := '201460';
  cs299999 constant varchar2(6) := '299999';
  cs999996 constant varchar2(6) := '999996';
  cs999997 constant varchar2(6) := '999997';
  cs999998 constant varchar2(6) := '999998';

  begin
      begin
      insert into swbtrmj
      (swbtrmj_term_code, swbtrmj_ptrm_code, swbtrmj_vpdi_code, swbtrmj_exec_ind)
      select
       ssbsect_term_code, ssbsect_ptrm_code, ssbsect_camp_code, csY
        from ssbsect
       where not exists          (select null
                                    from swbtrmj
                                   where swbtrmj_vpdi_code = ssbsect_camp_code
                                     and swbtrmj_ptrm_code = ssbsect_ptrm_code
                                     and swbtrmj_term_code = ssbsect_term_code
                                  )
         and ssbsect_term_code >= cs201460
         and ssbsect_term_code <> cs299999
         and ssbsect_term_code <> cs999996
         and ssbsect_term_code <> cs999997
         and ssbsect_term_code <> cs999998
       group by ssbsect_term_code,ssbsect_camp_code,ssbsect_ptrm_code
       order by ssbsect_term_code,ssbsect_camp_code,ssbsect_ptrm_code;

      exception
          when others then
               null;
      end;

      commit;

      insert into swrpgac
      (swrpgac_term_code,
       swrpgac_ptrm_code,
       swrpgac_camp_code
      )
      select
       swbtrmj_term_code,
       swbtrmj_ptrm_code,
       swbtrmj_vpdi_code
        from swbtrmj
       where swbtrmj_exec_ind = csY;

      commit;

  end setTermPtrmCamp;

  --actualiza a cero cursos sin inscritos
  --setCeroInscritos
  procedure setCeroInscritos is

  --cuCuposCero
  cursor cuCuposCero is
         select ssbsec.term,
                ssbsec.crnn,
                ssbsec.insc
           from (select ssbsect_term_code as term,
                        ssbsect_crn       as crnn,
                        (select count(cn1)
                           from sfrstcr
                          where sfrstcr_rsts_code in (csRE,csRW)
                            and sfrstcr_crn        = ssbsect_crn
                            and sfrstcr_term_code  = ssbsect_term_code
                        )                 as insc
                   from ssbsect
                  where (ssbsect_term_code,
                         ssbsect_ptrm_code,
                         ssbsect_camp_code
                        )                 in (select swrpgac_term_code,
                                                     swrpgac_ptrm_code,
                                                     swrpgac_camp_code
                                                from swrpgac
                                             )
                    and ssbsect_ssts_code  = csA
                    and ssbsect_enrl       > cn0
                ) ssbsec
          where ssbsec.insc = cn0;

  begin
      auditoria('I','setCeroInscritos');

       open cuCuposCero;
      fetch cuCuposCero bulk collect into tblCensus;
      close cuCuposCero;

      vnCasos := tblCensus.count;

      for vnI in 1..vnCasos loop
          update ssbsect
             set ssbsect_enrl           = cn0,
                 ssbsect_seats_avail    = ssbsect_max_enrl,
                 ssbsect_tot_credit_hrs = cn0
           where ssbsect_crn       = tblCensus(vnI).rCrnn
             and ssbsect_term_code = tblCensus(vnI).rTerm;

          vnRows := vnRows + 1;

          if vnRows >= 1000 then
             commit;

             vnRows := 0;
          end if;
      end loop;

      commit;

      tblCensus.delete;

      auditoria('U','setCeroInscritos');

      vnRows  := 0;
      vnCasos := 0;

  exception
      when others then
           vsError :=  SQLERRM;

           auditoria('U','setCeroInscritos',vsError);

           tblCensus.delete;

  end setCeroInscritos;

  --1. UPDATE INCORRECT ENROLLMENT COUNT ON SSBSECT
  --actualiza Inscritos
  --setInscritos
  procedure setInscritos is

  --cuCupos
  cursor cuCupos is
         select sfrstc.stcrTerm,
                sfrstc.stcrCrnn,
                sfrstc.stcrEnrl,
                sfrstc.stcrCred
           from (select sfrstcr_term_code      as stcrTerm,
                        sfrstcr_crn            as stcrCrnn,
                        count(cn1)             as stcrEnrl,
                        sum(sfrstcr_credit_hr) as stcrCred
                   from sfrstcr
                  where sfrstcr_rsts_code in (csRE,csRW)
                    and               exists (select null
                                                from swrpgac
                                               where swrpgac_term_code = sfrstcr_term_code
                                                 and swrpgac_ptrm_code = sfrstcr_ptrm_code
                                                 and swrpgac_camp_code ='UFT'
                                             )
                  group by sfrstcr_term_code,
                           sfrstcr_crn
                ) sfrstc
                INNER JOIN
                (select ssbsect_term_code as sectTerm,
                        ssbsect_crn       as sectCrnn,
                        ssbsect_enrl      as sectEnrl
                   from ssbsect
                  where               exists (select null
                                                from swrpgac
                                               where swrpgac_term_code = ssbsect_term_code
                                                 and swrpgac_ptrm_code = ssbsect_ptrm_code
                                                 and swrpgac_camp_code = ssbsect_camp_code
                                             )
                    and ssbsect_ssts_code  = csA
                ) ssbsec
                ON (sfrstc.stcrCrnn  = ssbsec.sectCrnn AND sfrstc.stcrTerm  = ssbsec.sectTerm)
          where sfrstc.stcrEnrl <> ssbsec.sectEnrl;

  begin
      auditoria('I','setInscritos');

       open cuCupos;
      fetch cuCupos bulk collect into tblCupos;
      close cuCupos;

      vnCasos := tblCupos.count;

      for vnI in 1..vnCasos loop
          update ssbsect
             set ssbsect_enrl           = tblCupos(vnI).rEnrl,
                 ssbsect_tot_credit_hrs = tblCupos(vnI).rCred,
                 ssbsect_census_enrl    = tblCupos(vnI).rEnrl,
                 ssbsect_census_2_enrl  = tblCupos(vnI).rEnrl,
                 ssbsect_seats_avail    = (ssbsect_max_enrl - tblCupos(vnI).rEnrl)
           where ssbsect_crn       = tblCupos(vnI).rCrnn
             and ssbsect_term_code = tblCupos(vnI).rTerm;

          vnRows := vnRows + 1;

          if vnRows >= 1000 then
             commit;

             vnRows := 0;
          end if;
      end loop;

      commit;

      tblCupos.delete;

      auditoria('U','setInscritos');

      vnRows  := 0;
      vnCasos := 0;

  exception
      when others then
           vsError :=  SQLERRM;

           auditoria('U','setInscritos',vsError);

           tblCupos.delete;

  end setInscritos;

  --3. UPDATE INCORRECT WAITING LIST COUNT ON SSBSECT
  --actualiza Inscritos wait
  --setInscritosWait
  procedure setInscritosWait is

  --cuCupos
  cursor cuCupos is
         select sfrstc.stcrTerm,
                sfrstc.stcrCrnn,
                sfrstc.stcrEnrl
           from (select sfrstcr_term_code      as stcrTerm,
                        sfrstcr_crn            as stcrCrnn,
                        count(cn1)             as stcrEnrl
                   from sfrstcr,
                        stvrsts
                  where sfrstcr_rsts_code = stvrsts_code
                    and stvrsts_wait_ind  = csY
                    and              exists (select null
                                                from swrpgac
                                               where swrpgac_term_code = sfrstcr_term_code
                                                 and swrpgac_ptrm_code = sfrstcr_ptrm_code
                                                 and swrpgac_camp_code = 'UFT'
                                             )
                  group by sfrstcr_term_code,
                           sfrstcr_crn
                ) sfrstc
                INNER JOIN
                (select ssbsect_term_code  as sectTerm,
                        ssbsect_crn        as sectCrnn,
                        ssbsect_wait_count as sectWait
                   from ssbsect
                  where               exists (select null
                                                from swrpgac
                                               where swrpgac_term_code = ssbsect_term_code
                                                 and swrpgac_ptrm_code = ssbsect_ptrm_code
                                                 and swrpgac_camp_code = ssbsect_camp_code
                                             )
                    and ssbsect_ssts_code  = csA
                ) ssbsec
                ON (sfrstc.stcrCrnn  = ssbsec.sectCrnn AND sfrstc.stcrTerm  = ssbsec.sectTerm)
          where sfrstc.stcrEnrl <> ssbsec.sectWait;

  begin
      auditoria('I','setInscritosWait');

       open cuCupos;
      fetch cuCupos bulk collect into tblCensus;
      close cuCupos;

      vnCasos := tblCensus.count;

      for vnI in 1..vnCasos loop
          update ssbsect
             set ssbsect_wait_count = tblCensus(vnI).rEnrl,
                 ssbsect_wait_avail = (ssbsect_wait_capacity - tblCensus(vnI).rEnrl)
           where ssbsect_crn       = tblCensus(vnI).rCrnn
             and ssbsect_term_code = tblCensus(vnI).rTerm;

          vnRows := vnRows + 1;

          if vnRows >= 1000 then
             commit;

             vnRows := 0;
          end if;
      end loop;

      commit;

      tblCensus.delete;

      auditoria('U','setInscritosWait');

      vnRows  := 0;
      vnCasos := 0;

  exception
      when others then
           vsError :=  SQLERRM;

           auditoria('U','setInscritosWait',vsError);

           tblCensus.delete;
  end setInscritosWait;

  --5. UPDATE ENROLLMENT COUNT ON XLIST RECORDS SSBXLST
  --actualiza la lista cruzada inscritos
  --setInscritosListaCruzada
  procedure setInscritosListaCruzada is

  --cuCupos
  cursor cuCupos is
         select ssbsec.sectTerm,
                ssbsec.sectXlst,
                ssbsec.sectEnrl
           from (select ssbsect_term_code          as sectTerm,
                        ssrxlst_xlst_group         as sectXlst,
                        sum(nvl(ssbsect_enrl,cn0)) as sectEnrl
                   from ssbsect INNER JOIN ssrxlst
                                ON (ssbsect_term_code = ssrxlst_term_code AND ssbsect_crn = ssrxlst_crn)
                  where (ssbsect_term_code,
                         ssbsect_ptrm_code,
                         ssbsect_camp_code
                        )                in (select swrpgac_term_code,
                                                    swrpgac_ptrm_code,
                                                    swrpgac_camp_code
                                               from swrpgac
                                            )
                    and ssbsect_ssts_code = csA
                  group by ssbsect_term_code,
                           ssrxlst_xlst_group
                ) ssbsec
           where exists (select null
                           from ssbxlst
                          where ssbxlst_term_code   = ssbsec.sectTerm
                            and ssbxlst_xlst_group  = ssbsec.sectXlst
                            and ssbxlst_enrl       <> ssbsec.sectEnrl
                        );
  begin
      auditoria('I','setInscritosListaCruzada');

       open cuCupos;
      fetch cuCupos bulk collect into tblCensus;
      close cuCupos;

      vnCasos := tblCensus.count;

      for vnI in 1..vnCasos loop
          update ssbxlst
             set ssbxlst_enrl        = tblCensus(vnI).rEnrl,
                 ssbxlst_seats_avail = (ssbxlst_max_enrl - tblCensus(vnI).rEnrl)
           where ssbxlst_xlst_group = tblCensus(vnI).rCrnn
             and ssbxlst_term_code  = tblCensus(vnI).rTerm;

          vnRows := vnRows + 1;

          if vnRows >= 1000 then
             commit;

             vnRows := 0;
          end if;
      end loop;

      commit;

      tblCensus.delete;

      auditoria('U','setInscritosListaCruzada');

      vnRows  := 0;
      vnCasos := 0;

  exception
      when others then
           vsError :=  SQLERRM;

           auditoria('U','setInscritosListaCruzada',vsError);

           tblCensus.delete;
  end setInscritosListaCruzada;

  --7. UPDATE INCORRECT ENROLLMENT COUNT ON RESERVED SEATS
  --actualiza cursos reservados Inbscritos
  --setReservInscritos
  procedure setReservInscritos is

  csSh2  constant varchar2(2)  := '##';
  csSh3  constant varchar2(3)  := '###';
  csSh4  constant varchar2(4)  := '####';
  csSh6  constant varchar2(6)  := '######';
  csSh10 constant varchar2(10) := '##########';
  csSh12 constant varchar2(12) := '############';
  csSh15 constant varchar2(15) := '###############';

  --cuCupos
  cursor cuCupos is
         select ssrresv_term_code,
                ssrresv_crn,
                ssrresv_seq_no,
                ssbsec.stcrEnrl
           from (select sfrstcr_term_code    as sectTerm,
                        sfrstcr_crn          as sectCrnn,
                        sfrstcr_reserved_key as stcrRese,
                        count(cn1)           as stcrEnrl
                   from sfrstcr INNER JOIN ssbsect
                                ON (ssbsect_term_code = sfrstcr_term_code AND ssbsect_crn = sfrstcr_crn)
                  where sfrstcr_rsts_code           in (csRE,csRW)
                    and nvl(sfrstcr_error_flag,csN) <> csF
                    and (ssbsect_term_code,
                         ssbsect_ptrm_code,
                         ssbsect_camp_code
                        )                           in (select swrpgac_term_code,
                                                               swrpgac_ptrm_code,
                                                               swrpgac_camp_code
                                                          from swrpgac
                                                       )
                    and ssbsect_ssts_code            = csA
                  group by sfrstcr_term_code,
                           sfrstcr_crn,
                           sfrstcr_reserved_key
                ) ssbsec INNER JOIN ssrresv
                         ON (ssbsec.sectTerm = ssrresv_term_code AND ssbsec.sectCrnn = ssrresv_crn)
          where ssbsec.stcrEnrl <> ssrresv_enrl
            and ssbsec.stcrRese  = nvl(ssrresv_levl_code,       csSh2 )||
                                   nvl(ssrresv_camp_code,       csSh3 )||
                                   nvl(ssrresv_coll_code,       csSh2 )||
                                   nvl(ssrresv_degc_code,       csSh6 )||
                                   nvl(ssrresv_program,         csSh12)||
                                   nvl(ssrresv_lfst_code,       csSh15)||
                                   nvl(ssrresv_majr_code,       csSh4 )||
                                   nvl(ssrresv_dept_code,       csSh4 )||
                                   nvl(ssrresv_clas_code,       csSh2 )||
                                   nvl(ssrresv_atts_code,       csSh4 )||
                                   nvl(ssrresv_chrt_code,       csSh10)||
                                   nvl(ssrresv_term_code_admit, csSh6 )||
                                   nvl(ssrresv_term_code_matric,csSh6 )||
                                   nvl(ssrresv_term_code_grad,  csSh6 );



  begin
      auditoria('I','setReservInscritos');

       open cuCupos;
      fetch cuCupos bulk collect into tblResv;
      close cuCupos;

      vnCasos := tblResv.count;

      for vnI in 1..vnCasos loop
          update ssrresv
             set ssrresv_enrl        = tblResv(vnI).rEnrl,
                 ssrresv_seats_avail = (ssrresv_max_enrl - tblResv(vnI).rEnrl)
           where ssrresv_seq_no    = tblResv(vnI).rSeqn
             and ssrresv_crn       = tblResv(vnI).rCrnn
             and ssrresv_term_code = tblResv(vnI).rTerm;

          vnRows := vnRows + 1;

          if vnRows >= 1000 then
             commit;

             vnRows := 0;
          end if;
      end loop;

      commit;

      tblResv.delete;

      auditoria('U','setReservInscritos');

      vnRows  := 0;
      vnCasos := 0;

  exception
      when others then
           vsError :=  SQLERRM;

           auditoria('U','setReservInscritos',vsError);

           tblResv.delete;
  end setReservInscritos;

  --8. UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS
  --actualiza cursos reservados Inbscritos Wait
  --setReservInscritosWait
  procedure setReservInscritosWait is

  csSh2  constant varchar2(2)  := '##';
  csSh3  constant varchar2(3)  := '###';
  csSh4  constant varchar2(4)  := '####';
  csSh6  constant varchar2(6)  := '######';
  csSh10 constant varchar2(10) := '##########';
  csSh12 constant varchar2(12) := '############';
  csSh15 constant varchar2(15) := '###############';

  --cuCupos
  cursor cuCupos is
         select ssrresv_term_code,
                ssrresv_crn,
                ssrresv_seq_no,
                ssbsec.stcrEnrl
           from (select sfrstcr_term_code    as sectTerm,
                        sfrstcr_crn          as sectCrnn,
                        sfrstcr_reserved_key as stcrRese,
                        count(cn1)           as stcrEnrl
                   from sfrstcr INNER JOIN ssbsect
                                        ON (sfrstcr_term_code = ssbsect_term_code AND sfrstcr_crn = ssbsect_crn)
                                INNER JOIN stvrsts
                                        ON (sfrstcr_rsts_code = stvrsts_code      AND stvrsts_wait_ind = csY)
                  where nvl(sfrstcr_error_flag,csN) <> csF
                    and (ssbsect_term_code,
                         ssbsect_ptrm_code,
                         ssbsect_camp_code
                        )                           in (select swrpgac_term_code,
                                                               swrpgac_ptrm_code,
                                                               swrpgac_camp_code
                                                          from swrpgac
                                                       )
                    and ssbsect_ssts_code            = csA
                  group by sfrstcr_term_code,
                           sfrstcr_crn,
                           sfrstcr_reserved_key
                ) ssbsec INNER JOIN ssrresv
                         ON (ssbsec.sectTerm = ssrresv_term_code AND ssbsec.sectCrnn = ssrresv_crn)
          where ssbsec.stcrEnrl <> ssrresv_wait_count
            and ssbsec.stcrRese  = nvl(ssrresv_levl_code,       csSh2 )||
                                   nvl(ssrresv_camp_code,       csSh3 )||
                                   nvl(ssrresv_coll_code,       csSh2 )||
                                   nvl(ssrresv_degc_code,       csSh6 )||
                                   nvl(ssrresv_program,         csSh12)||
                                   nvl(ssrresv_lfst_code,       csSh15)||
                                   nvl(ssrresv_majr_code,       csSh4 )||
                                   nvl(ssrresv_dept_code,       csSh4 )||
                                   nvl(ssrresv_clas_code,       csSh2 )||
                                   nvl(ssrresv_atts_code,       csSh4 )||
                                   nvl(ssrresv_chrt_code,       csSh10)||
                                   nvl(ssrresv_term_code_admit, csSh6 )||
                                   nvl(ssrresv_term_code_matric,csSh6 )||
                                   nvl(ssrresv_term_code_grad,  csSh6 );

  begin
      auditoria('I','setReservInscritosWait');

       open cuCupos;
      fetch cuCupos bulk collect into tblResv;
      close cuCupos;

      vnCasos := tblResv.count;

      for vnI in 1..vnCasos loop
          update ssrresv
             set ssrresv_wait_count = tblResv(vnI).rEnrl,
                 ssrresv_wait_avail = (ssrresv_wait_capacity - tblResv(vnI).rEnrl)
           where ssrresv_seq_no    = tblResv(vnI).rSeqn
             and ssrresv_crn       = tblResv(vnI).rCrnn
             and ssrresv_term_code = tblResv(vnI).rTerm;

          vnRows := vnRows + 1;

          if vnRows >= 1000 then
             commit;

             vnRows := 0;
          end if;
      end loop;

      commit;

      tblResv.delete;

      auditoria('U','setReservInscritosWait');

      vnRows  := 0;
      vnCasos := 0;

  exception
      when others then
           vsError :=  SQLERRM;

           auditoria('U','setReservInscritosWait',vsError);

           tblResv.delete;

  end setReservInscritosWait;

  --El procedimiento mantiene el intervalo de ejecuci¿n de JOB
  --intervalo
  procedure intervalo is

  cdInterval CONSTANT DATE := SYSDATE;

  begin

--      if sysdate >= cdLimiteEjecucion then
--         pdNextDate := cdNext;
--      else
         pdNextDate := cdInterval + 1/680;
         --pdNextDate := cdInterval + 1/280;
         --pdNextDate := cdInterval + 1/140;
      --end if;

  end intervalo;

  BEGIN
      --valida que no exista un proceso en ejecución
      IF getExecute() THEN
         intervalo();

         --el proceso no es ejecutado
         RETURN;
      END IF;

      --verifica que la auditoria sea ejecutada
      vbAudTF := getAuditoriaTF();

      --secuencia de proceso
      vnSeqn := getMaxProceso();

      auditoria('I',csPWJENRL);

      --verifica que el JOB pueda ser ejecutado
      IF NOT getExecuteTF() THEN

         auditoria('U',csPWJENRL);

         intervalo();
         RETURN;
      END IF;

      --registra periodos a tomar encuenta
      setTermPtrmCamp();

      --actualiza a cero cursos sin inscritos
      setCeroInscritos();

      --1. UPDATE INCORRECT ENROLLMENT COUNT ON SSBSECT
      --actualiza Inscritos
      setInscritos();

      --3. UPDATE INCORRECT WAITING LIST COUNT ON SSBSECT
      --actualiza Inscritos wait
      --setInscritosWait();  --Se deshabilita se ha observado que la RUA no usa esta configuración

      --5. UPDATE ENROLLMENT COUNT ON XLIST RECORDS SSBXLST
      --actualiza la lista cruzada inscritos
      setInscritosListaCruzada();

      --7. UPDATE INCORRECT ENROLLMENT COUNT ON RESERVED SEATS
      --actualiza cursos reservados Inbscritos
      setReservInscritos();

      --8. UPDATE INCORRECT WAITING LIST COUNT ON RESERVED SEATS
      --actualiza cursos reservados Inbscritos Wait
      --setReservInscritosWait(); --Se deshabilita se ha observado que la RUA no usa esta configuración

      delete swrpgac;
      commit;

      auditoria('U',csPWJENRL);

      intervalo();

  EXCEPTION
      WHEN OTHERS THEN
           vsError :=  SQLERRM;

           delete swrpgac;
           commit;

           auditoria('U',csPWJENRL,vsError);

           intervalo();
  END pwjenrl;
/
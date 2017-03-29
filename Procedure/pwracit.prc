CREATE OR REPLACE PROCEDURE BANINST1.PWRACIT(pnPidm    NUMBER,
                                             psTerm    VARCHAR2 DEFAULT NULL,
                                             psColl    VARCHAR2 DEFAULT NULL,
                                             psCamp    VARCHAR2 DEFAULT NULL,
                                             psClas    VARCHAR2 DEFAULT NULL,
                                             psMajr    VARCHAR2 DEFAULT NULL,
                                             psCred    VARCHAR2 DEFAULT NULL,
                                             psLevl    VARCHAR2 DEFAULT NULL,
                                             psStyp    VARCHAR2 DEFAULT NULL,
                                             pdDateBeg DATE     DEFAULT NULL,
                                             pdDateEnd DATE     DEFAULT NULL,
                                             psHourBeg VARCHAR2 DEFAULT NULL,
                                             psHourEnd VARCHAR2 DEFAULT NULL,
                                             psHoldST  VARCHAR2 DEFAULT NULL
                                            ) IS


  --verifica si ya existe la cita de inscripción
  --existeCita
  function existeCita return boolean is

  vnExiste number(4) := null;

  cn1 constant number(1) := 1;
  cn0 constant number(1) := 0;

  begin
      select count(cn1)
        into vnExiste
        from swracit
       where swracit_hour_end = psHourEnd
         and swracit_hour_beg = psHourBeg
         and swracit_date_end = pdDateEnd
         and swracit_date_beg = pdDateBeg
         and swracit_pidm     = pnPidm;

      return (vnExiste > cn0);

  end existeCita;

  --registra la cita en caso de no existir
  --insertaCita
  procedure insertaCita is

  cdSysDate constant date := sysdate;

  begin
      insert into swracit
      (swracit_pidm,      swracit_term_code, swracit_coll_code,
       swracit_camp_code, swracit_clas_code, swracit_majr_code,
       swracit_cred,      swracit_levl_code, swracit_date_beg,
       swracit_date_end,  swracit_hour_beg,  swracit_hour_end,
       swracit_hold_st,   swracit_stud_type, swracit_activity_date
      )
      values
      (pnPidm,            psTerm,            psColl,
       psCamp,            psClas,            psMajr,
       psCred,            psLevl,            pdDateBeg,
       pdDateEnd,         psHourBeg,         psHourEnd,
       psHoldST,          psStyp,            cdSysDate
      );

  exception
     when others then
          null;
  end insertaCita;

  BEGIN
      --verifica si ya existe la cita de inscripción
      IF NOT existeCita() THEN
         --registra la cita en caso de no existir
         insertaCita();

         commit;
      END IF;

  EXCEPTION
     WHEN OTHERS THEN
          NULL;
  END PWRACIT;
/
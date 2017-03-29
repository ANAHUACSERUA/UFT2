



CREATE OR REPLACE function BANINST1.f_nivel_estudios_cae(piPidm number)  return number
as

vsProg       varchar2(12);
vinumSemestre   number(3);


cursor cur_programa is  
       select SGBSTDN_PROGRAM_1 programa
       from sgbstdn 
       where SGBSTDN_PIDM = piPidm
       and SGBSTDN_TERM_CODE_EFF = (select max(SGBSTDN_TERM_CODE_EFF)
                                    from sgbstdn 
                                    where SGBSTDN_PIDM = piPidm);
                                    
cursor cur_semestres is 
        select  distinct n.SHRTCKN_TERM_CODE
          from smrpaap a,
               smracaa c,
               shrtckn n
         where a.smrpaap_program        = vsProg
           and a.smrpaap_term_code_eff  = (select max(b.smrpaap_term_code_eff)
                                             from smrpaap b
                                            where b.smrpaap_program = a.smrpaap_program  )
           and c.smracaa_area           = a.smrpaap_area
           and c.smracaa_term_code_eff  = (select max(d.smracaa_term_code_eff)
                                             from smracaa d
                                            where d.smracaa_area = c.smracaa_area)
           and substr( SMRACAA_RULE , 1,  instr(SMRACAA_RULE,' ')-1) = n.SHRTCKN_SUBJ_CODE
           and substr( SMRACAA_RULE , instr(SMRACAA_RULE,' ')+1 )    = n.SHRTCKN_CRSE_NUMB
           and n.SHRTCKN_PIDM = piPidm ;

/*  calculo de años en la carrera   */
begin    
    
    vinumSemestre := 0; 
    vsProg := null;
    
    -- busco la carrera 
    for cuPrograma in cur_programa loop 
       vsProg := cuPrograma.programa; 
    end loop;
   
    if vsProg is null or vsProg = '' then
       -- no carrera regreso 0
       return vinumSemestre; 
    end if;
    
    -- barriendo el num de semestres 
    for cuSemestre in cur_semestres loop
       vinumSemestre := vinumSemestre + 1; 
    end loop; 
    
    if vinumSemestre > 0 then
       -- divido entre 2 ya que un año tiene 2 semestres
       vinumSemestre := ceil(vinumSemestre / 2); 
    end if ; 
    
    if  vinumSemestre > 7 then 
       vinumSemestre:= 7;
    end if; 
    
    return vinumSemestre;

end f_nivel_estudios_cae;


GRANT EXECUTE ON BANINST1.f_nivel_estudios_cae TO WWW_USER;

GRANT EXECUTE ON BANINST1.f_nivel_estudios_cae  TO WWW2_USER;

CREATE OR REPLACE PUBLIC SYNONYM f_nivel_estudios_cae for BANINST1.f_nivel_estudios_cae;
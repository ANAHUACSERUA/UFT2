

CREATE OR REPLACE function BANINST1.f_num_sem_prog(psPrograma varchar2)  return number
as

x            number(2);
vsSemestre   varchar2(2);
viOcurrencia number(2);
viMaxSem     number(2);
vnExiste     number(3);

ciMaxSemestres constant  number(2) :=  15;  

/*  calculo semestres por carrea    */
begin    
    
    viMaxSem := 0;
     
    for x in  1 .. ciMaxSemestres loop  --
    
       --ocurrencia
       viOcurrencia := 1;
       
       --semestre a buscar
       select lpad(x, 2,'0') into vsSemestre
       from dual;
       
       vnExiste := 0; 
       
       select sum( instr(substr(SMRPAAP_AREA,5), vsSemestre, viOcurrencia) )  into vnExiste 
       from smrpaap a
       where a.SMRPAAP_PROGRAM = psPrograma
       and a.SMRPAAP_TERM_CODE_EFF =  (select max(aa.SMRPAAP_TERM_CODE_EFF)
                                       from smrpaap aa
                                       where aa.SMRPAAP_PROGRAM =  a.SMRPAAP_PROGRAM );
       
       if vnExiste > 0 then
          viMaxSem := x; 
       end if;  
       
    end loop;
   
     return viMaxSem;

end f_num_sem_prog;

GRANT EXECUTE ON BANINST1.f_num_sem_prog TO WWW_USER;

GRANT EXECUTE ON BANINST1.f_num_sem_prog  TO WWW2_USER;

CREATE OR REPLACE PUBLIC SYNONYM f_num_sem_prog for BANINST1.f_num_sem_prog;
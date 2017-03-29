create or replace function baninst1.f_get_componentes (term varchar2, crn varchar2) return varchar2 is
  i       number;
  vsComps varchar2(1000);
  
  cursor cur1 is
    select SHRGCOM_DESCRIPTION descr,SHRGCOM_WEIGHT weight,SHRGCOM_TOTAL_SCORE score,to_char(SHRGCOM_DATE,'dd/mm/yyyy') xdate,SHRGCOM_INCL_IND ind
    from  saturn.SHRGCOM
    where SHRGCOM_TERM_CODE = term
    and   SHRGCOM_CRN = crn;
  
begin
  vsComps := null;
  for i in cur1 loop
      vsComps := vsComps||i.descr||' '||i.weight||' '||i.score||' '||i.xdate||' '||i.ind||', '; 
  end loop;
  vsComps := rtrim(vsComps,', ');
  return vsComps;
  
end f_get_componentes;
/
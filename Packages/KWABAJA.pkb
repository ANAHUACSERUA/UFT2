CREATE OR REPLACE PACKAGE BODY BANINST1.KWABAJA IS
/*
         AUTOR: GEPC
         FECHA: 28/05/2010
         TAREA: Reporte de Bajas
        MODULO: Historia academicaregistroAcademico

MODIFY: GLOVICX@15-05-2014  BY  VIC...
SE CORRIGIO EL PROC  PROCESO EN EL CURSOR PRINCIPAL PARA QUE SOLO TOME LAS CARRERAS QUE VIENEN EN EL PARAMETRO DE ENTRADA

last modification on 17-jul-2014  by glovicx.
ajustes de validaciones de art 32. y baja permanente-
last modify 11-agost-2014  by glovicx


--  se separa las materias  del cursor principal  en el reporte y se hace un cursor especial para recorrer las materias reprobadas
--  este cambio lo pidio maltamirano 26.dic.1014
-- modifico  vic..


*/

---------  varoables--- de articulos- causales de baja----

AA31       NUMBER;
AAA31      NUMBER;
AAAA31     NUMBER;
AA32       NUMBER;
AA33       NUMBER;
AAA33      NUMBER;
psTerm2    VARCHAR2(14);
vsError    VARCHAR2(500) := NULL;
prom31     VARCHAR2(1);
oport32    VARCHAR2(1);
ponde33    VARCHAR2(1);
conta      NUMBER := 0;
vscontav   NUMBER:=0;
vsTipo     VARCHAR2(6);
----vsError    VARCHAR2(500)  := null;
vnveces    NUMBER;
vssubj     VARCHAR2(8);
vscrse     VARCHAR2(8);
vspidm     number;
vstemni    VARCHAR2(10);
vsterm2    VARCHAR2(10);
vsstyp_code VARCHAR2(3);
vscampCode VARCHAR2(4);
vspsprog   VARCHAR2(14);
vsLevl     VARCHAR2(3);







procedure inserta_swrbaja   is
--------------inserta los valores ya con los calculos de baja ----para reporte-----
--dbms_output.put_line( 'antes de insert swrbaja ' || '-' ||   regRep.stdnPidm||  psTerm);

vsodon  varchar2(4) := 'ODON';

begin

  if  substr(vspsprog,4,4) = vsodon THEN------ CON ESTA VALIDACION se evita que se llegue a dar de baja algun alumno de odontologia
    null; ----- NO HACE NADA                           ellos tienen otras reglas
    prom31    := 'C';  ----- cae en baja 31   Y/N
    oport32   :=  'C';        ---baja 32
    ponde33   := 'C';     ----baja 33

  end if;

  insert into swrbaja
         (swrbaja_pidm,     
          swrbaja_term,         
          swrbaja_campus,
          swrbaja_nivel,    
          swrbaja_program,    
          swrbaja_tipo,
          swrbaja_perc_aprob,
          swrbaja_baja_31,
          swrbaja_baja_32,
          swrbaja_prom_ponderado,
          swrbaja_baja_33,
          swrbaja_documentos, -- aqui va el tipo de alumno
          swrbaja_reprobadas, --- num veces materia reprobada
          swrbaja_ingles,     ---aqui pondo subj de la materia rep oportunidades
          swrbaja_swavcode,
          swrbaja_prom_pond_anterior)  -- aqui va el scrse de la mat rep oport )
         values
         (vspidm ,
          vstemni,  
          vscampCode,
          vsLevl,     
          vspsprog,   
          vsTipo,
          AAAA31, ---- inserta el valor del  ART 31  ultimo valor
          prom31, ----- cae en baja 31   Y/N
          oport32,
          AA33,
          ponde33 ,
          vsstyp_code, -- aqui va el tipo de alumno vnveces,vssubj,vscrse
          vnveces, --- num veces materia reprobada
          vssubj,     ---aqui pondo subj de la materia rep oportunidades
          vscrse,    ---- codgo  crse
          AAA33 ) ; -- aqui va el scrse de la mat rep oport);
       conta := conta +1 ;


end inserta_swrbaja;


----++++++++++++++++++++++funcion OPORTUNIDADES ESPECIAL  +++++++++++++
PROCEDURE oportunidadX (pnPidm IN number,psLevl in varchar2) is

vnbajas       number := 0;
vnCuenta      number:= 0;
vnCuenta2     number:= 0;
vncontador    number:= 0;
vnMaxSEQ      number := 0;
calificacion  varchar2(5);
vnLimite      number:= 0;
vnAprobada    number:= 0;
vnseq_tckn    number:=0;
csC           constant varchar2(1) := 'C';
csH           constant varchar2(1) := 'H';
csX           constant varchar2(1) := 'X';
csG           constant varchar2(1) := 'G';
csP           constant varchar2(1) := 'P';
csNV          constant varchar2(2) := 'NP';


cursor cuOportunidades is
  select distinct shrtckn_pidm 
        ,shrtckn_subj_code SUBJ
        ,shrtckn_crse_numb CRSE
        ,count(shrtckn_subj_code||shrtckn_crse_numb)  cuenta
  from shrtckn ck
  where  ck.shrtckn_pidm   = pnPidm 
  ---    AND  ck.shrtckn_subj_code = 'AVI'
   --- and   ck.shrtckn_crse_numb =  'IA404'
  and   exists (select shrtckg_pidm from shrtckg kg where kg.shrtckg_gmod_code  NOT   in (csC,csH,csX,csG)
                                                      and  shrtckg_grde_code_final not  IN  (csP, csNV)
                                                       and  shrtckg_pidm = ck.shrtckn_pidm
                                                       and kg.shrtckg_tckn_seq_no  = ck.shrtckn_seq_no
                                                       and exists (select de.shrgrde_code  from shrgrde de
                                                                   where  de.shrgrde_levl_code  = psLevl
                                                                   and  de.shrgrde_code  = kg.shrtckg_grde_code_final ) )
  group by shrtckn_pidm, shrtckn_subj_code , shrtckn_crse_numb
  having count(shrtckn_subj_code||shrtckn_crse_numb) > 1
  order by 1;

CURSOR  cu_maxim (VPID  NUMBER, VSUBJ VARCHAR2 , VCRSE VARCHAR2 )   IS
 select  kg1.shrtckg_tckn_seq_no  AS tckn_no,  
         max(kg1.shrtckg_seq_no)  AS MAXSEQ ,
         kg1.shrtckg_grde_code_final  AS CALIFICA --* --SHRTCKG_pidm
       , kg1.shrtckg_term_code
  from    shrtckg kg1
  where   shrtckg_pidm = pnPidm
  and    (kg1.shrtckg_seq_no ,kg1.shrtckg_tckn_seq_no,kg1.shrtckg_term_code ) IN
              (SELECT   MAX(shrtckg_seq_no)  AS maxseq ,kg.shrtckg_tckn_seq_no  AS  TCKN
                     , kg.shrtckg_term_code
               from shrtckg kg
               where shrtckg_pidm = pnPidm
               and    kg.shrtckg_gmod_code not in (csC,csH,csX,csG)
                      --  and  SHRTCKG_GRDE_CODE_FINAL  IN ('P', 'NV')
               and  (kg.shrtckg_tckn_seq_no , kg.shrtckg_term_code)   in (SELECT distinct (CK.shrtckn_seq_no), ck.shrtckn_term_code
                                                                                from   shrtckn ck
                                                                                WHERE ck.shrtckn_pidm   = pnPidm---pnPid
                                                                                AND  ck.shrtckn_subj_code = VSUBJ
                                                                                  and shrtckn_crse_numb = VCRSE )
  group by kg.shrtckg_tckn_seq_no , kg.shrtckg_term_code)
  group by  kg1.shrtckg_tckn_seq_no ,kg1.shrtckg_grde_code_final, kg1.shrtckg_term_code
  order by 1,2 ;



  begin

    for regOpor in cuOportunidades loop
          vnCuenta  := regOpor.Cuenta;
          vncuenta2 := regOpor.Cuenta;
          vsSubj := regOpor.SUBJ;
          vsCrse := regOpor.CRSE;
          VNCONTADOR  := 0;
                --     INSERT INTO SWRPASO VALUES ('MATERIAS REPR ' ,  vnCuenta||vsSubj||vsCrse); COMMIT;

                     for regOpor1 in cu_maxim (pnPidm, vsSubj,vsCrse )  loop
                                   vnMaxSEQ := regOpor1.MAXSEQ;
                                   calificacion := regOpor1.CALIFICA;
                                   VNSEQ_TCKN  := regOpor1.tckn_no;

                          IF calificacion in ( 'NV' , 'P')  THEN
                             vnCuenta   := vnCuenta -1;
                             vncontador  := vncontador +1;
                          END IF;
                          --   DBMS_OUTPUT.PUT_LINE  ('kwabaja-oportunid '|| vsSubj||'-'|| vsCrse|| ' tckn '||VNSEQ_TCKN|| '  >>>seq_no< '||vnMaxSEQ||'  -  '||calificacion||'--cntdr-- '||vncontador||'- cta--> '||vnCuenta      );
                       END LOOP;


         if vnCuenta > 1 then

            select     count(1)     into vnAprobada from swvhiac
            where swvhiac_pidm = pnPidm
            and swvhiac_subj = regOpor.SUBJ
            and swvhiac_crse = regOpor.CRSE
            and swvhiac_quality_points >= 4;

            if vnAprobada = 0 then

                select scbcrse_repeat_limit Into vnLimite from scbcrse
                where scbcrse_subj_code = regOpor.SUBJ
                and scbcrse_crse_numb = regOpor.CRSE
                and rownum = 1;


                if vnLimite + 1 <= vnCuenta then
                    vnbajas := 1;

                     vnveces  := vnCuenta;
                     vssubj   := regOpor.SUBJ;
                     vscrse   := regOpor.CRSE;
                  ----         INSERT INTO swrpaso values  ('oportunid2 ' ,vnCuenta||'-'|| vsSubj||'-'|| vsCrse||' limite  > ' ||vnLimite); commit;
                    ---- DBMS_OUTPUT.put_line ( vnveces ) ;
                ----NOTA : AQUI ME TIENE QUE INSERTAR TANTAN VECES ENTRE A ESTA VALIDACION YA QUE DEBE MOSTRAR C/u DE MAS MAT REPROBADAS--> VIC
                       oport32  := 'Y';
                        inserta_swrbaja ;
                     else
                   --  oport32  := 'N';
                     vnveces   := NULL;
                     vssubj    := NULL;
                     vscrse    := NULL;

                         null;
                end if;

                 ---- inserta_swrbaja ;
                     vnveces   := NULL;
                     vssubj    := NULL;
                     vscrse    := NULL;

         end if;
              -- inserta_swrbaja ;
                     vnveces   := NULL;
                     vssubj    := NULL;
                     vscrse    := NULL;

          else
                     vnveces   := NULL;
                     vssubj    := NULL;
                     vscrse    := NULL;
         end if;



    end loop;
---insert into swrpaso values ('1',vncontador);



        exception
            when others then
        vsError := SUBSTR(SQLERRM,1,500);
   ---      INSERT INTO swrpaso values  ('kwabaja-ERROORR ' ,  pnPidm ||'---'||   vnContador||'-'|| vsSubj||'-'|| vsCrse||' limite  > ' ||vnLimite||'**'||vsError  ); commit;
         vnveces  := NULL;
         vssubj    := NULL;
         vscrse    := NULL;
  end  oportunidadX;




--FUNCTION  f_next_period ( psperiodo  varchar2 )
--  return varchar2  is
--   vsperiod    varchar2(8);
--   vrecid      varchar2(2);
--   vsalida     varchar2(8);
--   cn25        constant varchar2(2) := '25';
--   cn75        constant varchar2(2) := '75';
--   cn10        constant varchar2(2) := '10';
--
--   begin
------calcula el sig periodo dependiendo del periodo que le manden en el parametro
------ el calculo se debe hacer por periodo anual o semestral
----- ejemplo si el parm es 201410  es anual y el proximo debe ser 201510
----- si  el param  es 201425   es semmestral y el sig  es 201475.
--vsperiod := substr(psperiodo,1,4);
--vrecid   := substr(psperiodo,5,2);
---- aca haca la valuacion
--if vrecid = cn25  then
--   vrecid :=  cn75;
--   vsalida := vsperiod || vrecid;
--   elsif  vrecid =  cn75  then
--   vrecid := cn25;
--   vsalida := vsperiod +1 || vrecid;
--   elsif  vrecid = cn10  then
--   vsalida := vsperiod +1 || vrecid;
--   end if;
--
--
--null;
--return(vsalida);
--
--end;



FUNCTION  f_next_period ( psperiodo  varchar2 )
  return varchar2  is
   vsperiod    varchar2(8);
   vrecid      varchar2(2);
   vsalida     varchar2(8);
   cn25        constant varchar2(2) := '25';
   cn75        constant varchar2(2) := '75';
   cn10        constant varchar2(2) := '10';

   begin
----calcula el sig periodo dependiendo del periodo que le manden en el parametro
---- el calculo se debe hacer por periodo anual o semestral
--- ejemplo si el parm es 201410  es anual y el proximo debe ser 201510
--- si  el param  es 201425   es semmestral y el sig  es 201475.
vsperiod := substr(psperiodo,1,4);
vrecid   := substr(psperiodo,5,2);
-- aca haca la valuacion
if vrecid = cn25  then
   vrecid :=  cn75;
   vsalida := vsperiod || vrecid;
   elsif  vrecid =  cn75  then
   vrecid := cn10;
   vsalida := vsperiod +1 || vrecid;
   elsif  vrecid = cn10  then
   vsalida := vsperiod +1 || vrecid;
   end if;


null;
return(vsalida);

end;


FUNCTION  f_back_period ( psperiodo  varchar2 )
  return varchar2  is
   vsperiod    varchar2(8);
   vrecid      varchar2(2);
   vsalida     varchar2(8);
   cn25        constant varchar2(2) := '25';
   cn75        constant varchar2(2) := '75';
   cn10        constant varchar2(2) := '10';

   begin
----calcula el sig periodo dependiendo del periodo que le manden en el parametro
---- el calculo se debe hacer por periodo anual o semestral
--- ejemplo si el parm es 201410  es anual y el proximo debe ser 201510
--- si  el param  es 201425   es semmestral y el sig  es 201475.
vsperiod := substr(psperiodo,1,4);
vrecid   := substr(psperiodo,5,2);
-- aca haca la valuacion
if vrecid = cn25  then
   vrecid := cn75;
   vsalida := vsperiod || vrecid;
   elsif  vrecid = cn75  then
   vrecid := cn25;
   vsalida := vsperiod -1 || vrecid;
   elsif  vrecid = cn10  then
   vsalida := vsperiod -1 || vrecid;
   end if;


null;
return(vsalida);

end;




procedure splitChain ( lcadena in  varchar2) is
--declare
 --- l_frase VARCHAR2 (32766) := 'ARQU', 'DERE', 'KINE')';
lpos    number:=0;
--lpos2    number :=0;
conta   number := 1;
tamcan  number;

begin

 tamcan   :=  length(lcadena);
 lpos     := (INSTR(lcadena, ','));
   -- DBMS_OUTPUT.put_line ('TAMAÑO TOTAL DELA CADENA > '||tamcan);

---delete swrpaso commit;
  for x IN  1..tamcan LOOP

    if  conta > tamcan  then
  -- DBMS_OUTPUT.put_line(CONTA);
     exit;
    else
   -- DBMS_OUTPUT.put_line(X);


-- se comenta MRC
    insert into swrpaso values('kwabaja', (SUBSTR(lcadena,conta,4 )));

 --DBMS_OUTPUT.put_line ('AA '||SUBSTR(lcadena,conta,4 )||'--'|| conta );
 -- lpos := lpos + 5;
    conta := conta +lpos ;
    end if;
  end loop;
  commit;

 exception
      when no_data_found then
        null;
         --- return vnPromedio;
      when others then
        null;
          -- return vnPromedio;
end splitChain;


procedure  p_borratblbaja  is

begin
  delete swrbaja
  where swrbaja_fecha_baja is null
  and  swrbaja_permanent is null;
  --------borra tbl paso-----
  delete swrpaso wr
  where wr.valor1 like('kwabaja%');
  commit;
 exception
      when no_data_found then
      null;
         --- return vnPromedio;
      when others then
      null;
end  p_borratblbaja;


procedure aplica_baja(pspidm     varchar2,
                      psterm     varchar2,
                      pscampus   varchar2,
                      pslevl     varchar2,
                      psprog     varchar2,
                      pstipo     varchar2,
                      psperaprob number,
                      psbaja31   varchar2,
                      psbaja32   varchar2,
                      psprompon  number, ----actual AA33
                      psbaja33   varchar2,  --causa baja Y/N  del art 33
                      pstipoalum varchar2,  -- tipo alumno
                      pnveces    number,   ----NUM MAT REP
                      pssubj     varchar2,
                      pscrse     varchar2  )is


vnxt_term    varchar2(8);
experiod     number :=0;
vnComentario number :=0;
cn1          number := 1;
psBajaOrigen varchar2(50);
begin


--VICTOR SI CUMPLE CON CUALQUIERA DE LOS TRES ARTICULOS CAUSA BAJA
     --MODO INSERT
       ---------------se inserta en la tabla de forma permanente el alumno para ver la historia--
--------       las condiciones de como estaba y cual fue la causa de baja en es momento
------++++++++++---excluir del insert y update todos los dela baja definitiva los reg de odontologia.


    insert into swrbaja
                (swrbaja_pidm,
                 swrbaja_term,
                 swrbaja_campus,
                 swrbaja_nivel,
                 swrbaja_program,
                 swrbaja_tipo,
                 swrbaja_perc_aprob,
                 swrbaja_baja_31,
                 swrbaja_baja_32,
                 swrbaja_prom_ponderado,
                 swrbaja_baja_33,
                 swrbaja_documentos, -- aqui va el tipo de alumno
                 swrbaja_reprobadas, --- num veces materia reprobada
                 swrbaja_ingles,     ---aqui pondo subj de la materia rep oportunidades
                 swrbaja_swavcode,  -- aqui va el scrse de la mat rep oport
                 swrbaja_fecha_baja,
                 swrbaja_permanent  )
           values
                (pspidm,
                 psterm,
                 pscampus,
                 pslevl,
                 psprog,
                 pstipo,
                 psperaprob,
                 psbaja31,
                 psbaja32,
                 psprompon,
                 psbaja33,
                 pstipoalum ,  -- tipo alumno
                 pnveces,      --num veces materia reprobada
                 pssubj,
                 pscrse,
                 sysdate,
                 'Y'
                  );
     ------------    ----aqui se hace el insert a sgbtdn y sprhold
          INSERT INTO SPRHOLD
            (
              SPRHOLD_PIDM,--           NUMBER(music)              NOT NULL,
              SPRHOLD_HLDD_CODE,--      VARCHAR2(2 CHAR)       NOT NULL,
              SPRHOLD_USER,--           VARCHAR2(30 CHAR)      NOT NULL,
              SPRHOLD_FROM_DATE,--      DATE                   NOT NULL,
              SPRHOLD_TO_DATE,--        DATE                   NOT NULL,
              SPRHOLD_RELEASE_IND,--    VARCHAR2(1 CHAR)       NOT NULL,
              SPRHOLD_REASON,--         VARCHAR2(30 CHAR),
              SPRHOLD_ACTIVITY_DATE  --  DATE                   NOT NULL,
            )
            VALUES (pspidm, 'CE', USER, TRUNC(SYSDATE), TO_DATE('31/12/2099','DD/MM/YYYY'), 'Y', 'Causal de Eliminación', SYSDATE );
         --------inserta en sgbstdn-------
         --VICTOR
         --TERM_CODE SI ESTA EN EL 75 SSERIA 25 Y SI FUERA 10 SERIA EN EL SIGUENTE 10
        vnxt_term  :=  f_next_period( psterm);
  ------- valida si ya existe el periodo siguiente el que calculo hay que hacer un update si no el insert
  begin
  select 1
  into experiod
  from sgbstdn
  where  sgbstdn_pidm  =  pspidm
       and  sgbstdn_term_code_eff  = vnxt_term
       and   sgbstdn_levl_code  = pslevl;
  exception
  when others then
   experiod := 0;
   end;

insert into swrpaso values (' next period  ', experiod);  commit;


 if  experiod = 1  then
  ----hacemos update
     update  sgbstdn
     set sgbstdn_stst_code = 'EL',
             sgbstdn_activity_date  = sysdate,
            sgbstdn_data_origin  =   'GWABAJA',
            sgbstdn_user_id     =  USER
     where sgbstdn_pidm  =  pspidm
       and  sgbstdn_term_code_eff  = vnxt_term
       and   sgbstdn_levl_code  = pslevl;

  else
      insert into sgbstdn
         (select sgbstdn_pidm,
                 vnxt_term, ----sgbstdn_term_code_eff, inserta el proximo periodo
                 'EL', -----sgbstdn_stst_code,
                 sgbstdn_levl_code,
                 sgbstdn_styp_code,
                 sgbstdn_term_code_matric,
                 sgbstdn_term_code_admit,
                 sgbstdn_exp_grad_date,
                 sgbstdn_camp_code,
                 sgbstdn_full_part_ind,
                 sgbstdn_sess_code,
                 sgbstdn_resd_code,
                 sgbstdn_coll_code_1,
                 sgbstdn_degc_code_1,
                 sgbstdn_majr_code_1,
                 sgbstdn_majr_code_minr_1,
                 sgbstdn_majr_code_minr_1_2,
                 sgbstdn_majr_code_conc_1,
                 sgbstdn_majr_code_conc_1_2,
                 sgbstdn_majr_code_conc_1_3,
                 sgbstdn_coll_code_2,
                 sgbstdn_degc_code_2,
                 sgbstdn_majr_code_2,
                 sgbstdn_majr_code_minr_2,
                 sgbstdn_majr_code_minr_2_2,
                 sgbstdn_majr_code_conc_2,
                 sgbstdn_majr_code_conc_2_2,
                 sgbstdn_majr_code_conc_2_3,
                 sgbstdn_orsn_code,
                 sgbstdn_prac_code,
                 sgbstdn_advr_pidm,
                 sgbstdn_grad_credit_appr_ind,
                 sgbstdn_capl_code,
                 sgbstdn_leav_code,
                 sgbstdn_leav_from_date,
                 sgbstdn_leav_to_date,
                 sgbstdn_astd_code,
                 sgbstdn_term_code_astd,
                 sgbstdn_rate_code,
                 sysdate, ------sgbstdn_activity_date,
                 sgbstdn_majr_code_1_2,
                 sgbstdn_majr_code_2_2,
                 sgbstdn_edlv_code,
                 sgbstdn_incm_code,
                 sgbstdn_admt_code,
                 sgbstdn_emex_code,
                 sgbstdn_aprn_code,
                 sgbstdn_trcn_code,
                 sgbstdn_gain_code,
                 sgbstdn_voed_code,
                 sgbstdn_blck_code,
                 sgbstdn_term_code_grad,
                 sgbstdn_acyr_code,
                 sgbstdn_dept_code,
                 sgbstdn_site_code,
                 sgbstdn_dept_code_2,
                 sgbstdn_egol_code,
                 sgbstdn_degc_code_dual,
                 sgbstdn_levl_code_dual,
                 sgbstdn_dept_code_dual,
                 sgbstdn_coll_code_dual,
                 sgbstdn_majr_code_dual,
                 sgbstdn_bskl_code,
                 sgbstdn_prim_roll_ind,
                 sgbstdn_program_1,
                 sgbstdn_term_code_ctlg_1,
                 sgbstdn_dept_code_1_2,
                 sgbstdn_majr_code_conc_121,
                 sgbstdn_majr_code_conc_122,
                 sgbstdn_majr_code_conc_123,
                 sgbstdn_secd_roll_ind,
                 sgbstdn_term_code_admit_2,
                 sgbstdn_admt_code_2,
                 sgbstdn_program_2,
                 sgbstdn_term_code_ctlg_2,
                 sgbstdn_levl_code_2,
                 sgbstdn_camp_code_2,
                 sgbstdn_dept_code_2_2,
                 sgbstdn_majr_code_conc_221,
                 sgbstdn_majr_code_conc_222,
                 sgbstdn_majr_code_conc_223,
                 sgbstdn_curr_rule_1,
                 sgbstdn_cmjr_rule_1_1,
                 sgbstdn_ccon_rule_11_1,
                 sgbstdn_ccon_rule_11_2,
                 sgbstdn_ccon_rule_11_3,
                 sgbstdn_cmjr_rule_1_2,
                 sgbstdn_ccon_rule_12_1,
                 sgbstdn_ccon_rule_12_2,
                 sgbstdn_ccon_rule_12_3,
                 sgbstdn_cmnr_rule_1_1,
                 sgbstdn_cmnr_rule_1_2,
                 sgbstdn_curr_rule_2,
                 sgbstdn_cmjr_rule_2_1,
                 sgbstdn_ccon_rule_21_1,
                 sgbstdn_ccon_rule_21_2,
                 sgbstdn_ccon_rule_21_3,
                 sgbstdn_cmjr_rule_2_2,
                 sgbstdn_ccon_rule_22_1,
                 sgbstdn_ccon_rule_22_2,
                 sgbstdn_ccon_rule_22_3,
                 sgbstdn_cmnr_rule_2_1,
                 sgbstdn_cmnr_rule_2_2,
                 sgbstdn_prev_code,
                 sgbstdn_term_code_prev,
                 sgbstdn_cast_code,
                 sgbstdn_term_code_cast,
                 'GWABAJA', --sgbstdn_data_origin,
                 USER, -----sgbstdn_user_id,
                 sgbstdn_scpc_code
                 from sgbstdn
                 where sgbstdn_pidm = pspidm
                 and  sgbstdn_levl_code    =  psLevl
                 AND   sgbstdn_term_code_eff = (select max(sgbstdn_term_code_eff) from sgbstdn
                                                where  sgbstdn_pidm = pspidm
                                                   and  sgbstdn_levl_code    =  psLevl
                                                   and sgbstdn_term_code_eff <=  psterm ) );

     END IF;

   
     select count(1) INTO vnComentario from SGRSCMT
     where SGRSCMT_PIDM = pspidm
     AND SGRSCMT_TERM_CODE  = psterm
     AND SUBSTR(SGRSCMT_COMMENT_TEXT,1,6) = 'CAUSAL';
     
         IF vnComentario = 0 THEN 
         
         IF psbaja31 = 'Y' THEN 
         psBajaOrigen := 'CAUSAL DE ELIMINACION POR ARTICULO 31';
         END IF;
         IF psbaja32 = 'Y'   THEN
         psBajaOrigen := 'CAUSAL DE ELIMINACION POR ARTICULO 32';
         END IF;
         IF psbaja33 = 'Y'   THEN
         psBajaOrigen := 'CAUSAL DE ELIMINACION POR ARTICULO 33';
         END IF;
     
       --insert into twrpaso values  (' causan baja ', ' <<31 >> '||psbaja31||'  <<32>> ' || psbaja32 || '<<33>> ' || psbaja33 ); commit;
           INSERT INTO SGRSCMT
           VALUES (pspidm, cn1, psTerm, psBajaOrigen, sysdate);
     
         END IF;
     
     
     
     
     
   
   commit;
   
 exception
      when no_data_found then
        null;
         --- return vnPromedio;
      when others then
        null;

end aplica_baja;

---PROCEDURE oportunidadX (pnPidm IN number, pnveces out number, PSSUBJ  out varchar2, PSCRSE OUT VARCHAR2);

  FUNCTION Articulo31(pnPidm number, psTerm varchar2, tip varchar2 ) RETURN NUMBER;

 FUNCTION Articulo33(pnPidm number,
                     psTerm varchar2,
                      pslevel   varchar2   ) RETURN NUMBER;

PROCEDURE tablaDePaso (psTerm  VARCHAR2,
                        pnPidm  NUMBER DEFAULT NULL,
                        psLevl  VARCHAR2,
                        psPBaja VARCHAR2,
                        psTipo      VARCHAR2 DEFAULT NULL,
                        psMode    varchar2,
                        psCondicion VARCHAR2 DEFAULT NULL
                       );

FUNCTION Articulo31(pnPidm number, psTerm varchar2, tip varchar2 ) RETURN NUMBER IS
 vnPromedio NUMBER;

 --VICTOR
-- ARTICULO 31
--VALIDA EL ELEMENTO NUEVE QE ES EL PORCENTAJE DE APROBACIÓN
--DEBE DE TOMAR EN CUENTA LOS 10 25 Y 75
--Y LA REGLA DEL TIPO DE ALUMNO

 BEGIN

    if tip  in  ('N') then  ----nuevo ingreso toma el elemento 9
    SELECT SGBUSER_SUDI_CODE into VnPromedio FROM SGBUSER
    WHERE SGBUSER_PIDM = pnPidm
    AND SGBUSER_TERM_CODE = psTerm;

        else                     --- alumno existete  toma elemento 10
     SELECT SGBUSER_SUDJ_CODE into VnPromedio FROM SGBUSER
    WHERE SGBUSER_PIDM = pnPidm
    AND SGBUSER_TERM_CODE = psTerm;

    end if;



 Return vnPromedio;



   exception
      when no_data_found then
        vnPromedio := null;
           return vnPromedio;
      when others then
           vnPromedio := null;
           return vnPromedio;
 END;


 FUNCTION Articulo33(pnPidm number,
                     psTerm varchar2,
                      pslevel   varchar2   ) RETURN NUMBER IS
 vnPonderadoPeriodo NUMBER;

 -- VICTOR PROMEDIO PONDERADO DEL PERIODO


 BEGIN
     SELECT SHRTGPA_GPA  into  vnPonderadoPeriodo FROM SHRTGPA
    WHERE SHRTGPA_PIDM = pnPidm
    AND SHRTGPA_TERM_CODE = psTerm
     and  SHRTGPA_levl_code   = pslevel ;

Return vnPonderadoPeriodo;
 exception
      when no_data_found then
        vnPonderadoPeriodo := null;
           return vnPonderadoPeriodo;
      when others then
           vnPonderadoPeriodo := null;
           return vnPonderadoPeriodo;


 END;


PROCEDURE tablaDePaso (psTerm  VARCHAR2,
                        pnPidm  NUMBER DEFAULT NULL,
                        psLevl  VARCHAR2,
                        psPBaja VARCHAR2,
                        psTipo      VARCHAR2 DEFAULT NULL,
                        psMode    varchar2,
                        psCondicion VARCHAR2 DEFAULT NULL
                       ) IS
--aca



  csAS        CONSTANT VARCHAR2(2) := 'AS';
  vscierre    constant varchar2(7) :=  'kwabaja';

  CURSOR cuEstuduante IS
     SELECT DISTINCT S.SGBSTDN_PIDM             AS stdnPidm,
                         S.SGBSTDN_CAMP_CODE        AS campCode,
                         s.sgbstdn_program_1                as psprog,
                         s.sgbstdn_styp_code                 as styp_code,
                         S.SGBSTDN_TERM_CODE_EFF as pstermn
           FROM SGBSTDN S
           WHERE S.SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(S2.SGBSTDN_TERM_CODE_EFF)
                                              FROM SGBSTDN S2
                                             WHERE S2.SGBSTDN_PIDM      = S.SGBSTDN_PIDM
                                         ---      AND S2.SGBSTDN_LEVL_CODE = S.SGBSTDN_LEVL_CODE
                                              And  S2.SGBSTDN_TERM_CODE_EFF <= psTerm  )
           AND  S.SGBSTDN_STST_CODE      = csAS
           AND (S.SGBSTDN_PIDM          = pnPidm OR pnPidm IS NULL)
           AND  S.SGBSTDN_LEVL_CODE      = psLevl
           AND EXISTS
                         (SELECT 1
                            FROM SFRSTCR
                           WHERE     SFRSTCR_PIDM = SGBSTDN_PIDM
                                 AND SFRSTCR_TERM_CODE = psTerm
                                 AND SFRSTCR_RSTS_CODE IN ('RE', 'RW')
                                 AND  SFRSTCR_LEVL_CODE   = psLevl
                                 AND (SFRSTCR_ERROR_FLAG <> 'F' OR SFRSTCR_ERROR_FLAG IS NULL ))
         ---  and fr.sfrstcr_levl_code  = psLevl  -- se le quito este filtro para que solo tome el nivel de gaston vic 15.07.2014
          --   AND S.SGBSTDN_PIDM IN ( 11050, 1235)
           AND (S.SGBSTDN_MAJR_CODE_1  in (select valor2 from swrpaso where valor1 = vscierre  )
             or S.SGBSTDN_MAJR_CODE_1 is null)
             --and s.sgbstdn_pidm = 2413
           ORDER BY S.SGBSTDN_PIDM   ;

 begin
   vsTipo    := psTipo;
if vsTipo is not null then
    ----  DBMS_OUTPUT.PUT_LINE('entra vs typo  '|| vsTipo);
  FOR regRep IN cuEstuduante LOOP  -- inicio

prom31    := 'N';
oport32    := 'N';
ponde33    := 'N';
AA31    :=0 ;
AAA31   :=0;
AAAA31   :=0;
AA32   :=0;
AA33   :=0;
AAA33  :=0;
 vnveces := null;
  vssubj := null;
  vscrse := null;
vspidm  := regRep.stdnPidm;
vstemni  := regRep.pstermn;
vscampcode := regrep.campcode;
vspsprog     :=   regrep.psprog;
vsstyp_code := regrep.styp_code;
vsLevl   :=  psLevl ;


         --insert into swrpaso values  (' pasan baja ',vspidm|| '--' || regRep.psprog  ); commit;

-------- ++++++++++++++++ evalua el articulo 31  % de aprobacion +++++++++++++++++++++++ ---------------

begin
-------------------VALIDAR ESTE YA NO E USA PARA QUITAR
select max(shrtckn_term_code)
into psTerm2
from shrtckn
where shrtckn_pidm = regRep.stdnPidm  --1094
and shrtckn_term_code < psTerm
order by 1 desc;

 ----DBMS_OUTPUT.PUT_LINE('en el loop   '|| regRep.stdnPidm);
-- victor
-- validar el tipo de alumno si tienen 'N', 'C', 'D', VALIDAR EL 25%
-- Si tienen 'A', 'R', 'I' VALIDAR EL 50 %


 ---IF AA31 > 0 THEN
                if vsstyp_code in ('N', 'C', 'D' ) then
                   AA31 := Articulo31(vspidm ,psTerm, 'N');------- perido actual
                   AAAA31 := AA31;
                   if  AA31 < 25 then
                    prom31  := 'Y';
                   end if;
                end if;

    ---- -- Si tienen 'A', 'R', 'I' VALIDAR EL 50 %
             if vsstyp_code in ('A', 'R', 'I') then    -----Periodo del parametro para ambos casos
                AAA31 := Articulo31(vspidm ,psTerm,'A');
              AAAA31 := AAA31;
                  if   AAA31 < 50 then
                   prom31  := 'Y';
                  end if;
                 end if;
--ELSE
 -- NULL;
---END IF;


  exception
      when no_data_found then
           vsError :='Error en art 31'|| SUBSTR(SQLERRM,1,500);
             dbms_output.put_line ('men  '||vsError );
             prom31  := 'N';
      when others then
            vsError :='Error en art 31'|| SUBSTR(SQLERRM,1,500);
               dbms_output.put_line ('men  '||vsError );
               prom31  := 'N';


end;


------------+++++++++++++++++++EVALUA ART 33  prom ponderado------++++++++++++
begin

     select  max (SHRTGPA_term_code)   into psTerm2
         from   SHRTGPA
      WHERE SHRTGPA_PIDM = vspidm
      and  SHRTGPA_TERM_CODE < psTerm
        order by 1 desc;

---vsterm2 := f_before_period(psTerm2);

--insert into  swrpaso values ('term exist  ', psTerm2);
---DBMS_OUTPUT.PUT_LINE('ART 33 '|| psTerm2 ||' PIDM ' ||regRep.stdnPidm  ||' TERM  ' ||psTerm);

AAA33  := Articulo33(vspidm , psTerm2, psLevl  );  --- cacula promedio periodo anterior

AA33  := Articulo33(vspidm , psTerm, psLevl );   ---- calcula promedio periodo actual

if aa33 < 3.95 and AAA33 < 3.95  then


--insert into paso values ('entro', aa33, aaa33);



----  sientra entonces evalua el segundo periodo anterior
ponde33  := 'Y';

end if;


null;

 exception
      when no_data_found then
            vsError :='Error en art 33'|| SUBSTR(SQLERRM,1,500);
          ---     dbms_output.put_line ('men  '||vsError );
               ponde33  :=  null;
      when others then
          vsError :='Error en art 33'|| SUBSTR(SQLERRM,1,500);
          ---  dbms_output.put_line ('men  '||vsError );
            ponde33  := null;
end;

------------------++++++++++++++++++evalua el articulo 32   oportunidades-----

begin
  --------se cambio el proceso de insertar
   oportunidadX (vspidm,psLevl );

               if  oport32  = 'Y'  then
               null;  ---no lo inserta x q salio del loop de oportunidades y ahi lo inserto
               else
                inserta_swrbaja ;
                end if;
end;



        ---COMMIT;
    ---- insert into swrpaso values  (' causan baja ', ' <<31 >> '||prom31||'  <<32>> ' || oport32 || '<<33>> ' || PONDE33|| ' pidm ' || regRep.stdnPidm||' MODO ' ||psMode ); commit;
--------ejecuta aplica baja-----
 IF psMode = 'U' THEN
     if (prom31 = 'Y'  OR  oport32 = 'Y' OR PONDE33 = 'Y') THEN
  
 
 --insert into paso values (prom31, opor32, PONDE33);  
           --insert into twrpaso values  (' causan baja ', ' <<31 >> '||prom31||'  <<32>> ' || oport32 || '<<33>> ' || PONDE33 ); commit;
       aplica_baja(vspidm ,
                  psTerm,---- se envia el periodo origen el del parametro
                  vscampcode,
                  vsLevl,
                  vspsprog ,
                  vsTipo,
                  AA31, ---- inserta el valor del  ART 31  ultimo valor
                  prom31, ----- cae en baja 31   Y/N
                   oport32,
                  AA33,
                  ponde33 ,
                  vsstyp_code, -- aqui va el tipo de alumno vnveces,vssubj,vscrse
                   vnveces, --- num veces materia reprobada
                   vssubj,     ---aqui pondo subj de la materia rep oportunidades
                   vscrse
                );
      END IF;

 end if;

  vscontav  := vscontav + 1;

      END LOOP;
   -- insert into swrpaso values('conta total ' , vscontav);

else
  NULL;
  ---- insert into twrpaso values('conta total 2 ' , conta);
end if;

---- insert into twrpaso values('conta total 3 ' , conta);
      COMMIT;    --este si va ok glovicx
  EXCEPTION
       when others then
     vsError := SUBSTR(SQLERRM,1,500);
 insert into swrpaso values('error en proc gwbaja ' ,  '  pidm   ' ||vspidm||'--'|| vsError );
  commit;
   --- dbms_output.put_line ('mensaje error cursor principal  '||vsError );

  END tablaDePaso;

  --realiza le registro de bajas academicas
  Procedure proceso(psTerm  VARCHAR2,
                    psMode      VARCHAR2,
                    pnPidm      NUMBER DEFAULT NULL,
                    psLevl      VARCHAR2,
                    psBaja      VARCHAR2,
                    psPBaja     VARCHAR2,
                    psTipo      VARCHAR2 DEFAULT NULL,
                    psCondicion VARCHAR2 DEFAULT NULL
                   ) IS



  BEGIN


  p_borratblbaja ;

 /*  INSERT INTO swrpaso
         VALUES('inicio gwabaja'||sysdate,' psmode '||psmode||' psBaja '|| psBaja|| ' psPBaja '|| psPBaja|| ' psTipo '|| psTipo||' psCondicion '||psCondicion  );
     INSERT INTO swrpaso
         VALUES('inicio gwabaja 2 '||sysdate,' psTerm '||psTerm||' pnPidm '|| pnPidm );
     commit;
*/

    splitchain(psCondicion);

    tablaDePaso(psTerm, pnPidm, psLevl,psPBaja,psTipo,psMode,psCondicion);


  EXCEPTION
        when others then
        vsError := SUBSTR(SQLERRM,1,500);
    --  INSERT INTO BITACORA_GBAJA(PERIODO, PIDM, CAMPUS,    ERROR, PROCESO)
      ---      VALUES(psTerm,  null, 'CbjaPro', vsError, 'Inicio');


  END proceso;



-------------------------------------------------------------------
PROCEDURE reporte(psReclDesc  VARCHAR2,
                    psTerm      VARCHAR2,
                    pnPidm      NUMBER DEFAULT NULL,
                    psBaja      VARCHAR2,
                    psPBaja     VARCHAR2
                   ) IS
--  se separa las materias  del cursor principal  en el reporte y se hace un cursor especial para recorrer las materias reprobadas
--  este cambio lo pidio maltamirano 26.dic.1014
-- modifico  vic..

  vnExists   INTEGER                := 0;
  existe     NUMBER                 := 0;
  vsExiste   VARCHAR2(3)            := NULL;
   vsRut      VARCHAR2(20)         ;
  vsReclDesc   VARCHAR2(80);
cnt1   number  := 0;
vnColumnas    number  := 20;
tabColumna Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla(1);
vsInicoPag VARCHAR2(20)           := NULL;
vsnomtypo   varchar2(20);
vsmateria   varchar2(100);

  CURSOR cuBajas  IS
         SELECT  DISTINCT
                spr.spriden_pidm                                       AS bajaPidm,
                spr.spriden_id                                         AS idenIddd,
                ltrim(spr.spriden_last_name) ||'  '||rtrim(spr.spriden_first_name)  AS idenName,
                swr.swrbaja_niveldesc                                   as niveldc,
                 swr.swrbaja_term                                        AS termBaja,
               swr.swrbaja_program                                     AS progCode,
               Pk_catalogo.Programa(swr.swrbaja_program)         AS progDesc,
                swr.swrbaja_campus                                       AS campCode,
                 swr.swrbaja_tipo                 AS bajaTipo,
               swr.swrbaja_Perc_aprob           AS bajaPerRep,
                swr.swrbaja_prom_ponderado       AS bajaPromponde,
                swrbaja_documentos               AS tipoalumn,
           --     swrbaja_reprobadas              as nveces, --- num veces materia reprobada
         ---       swrbaja_ingles                  as subj, ---aqui pondo subj de la materia rep oportunidades
          ---      swrbaja_swavcode                as scre,  -- aqui va el scrse de la mat rep oport
                swr.swrbaja_baja_31              as baja31,
                swr.swrbaja_baja_32              as baja32,
                swr.swrbaja_baja_33              as baja33,
                SWR.SWRBAJA_PROM_POND_ANTERIOR    AS PONDERADO_ANT
               from swrbaja swr, spriden spr
               where swr.swrbaja_pidm  = spr.spriden_pidm
               and spr.spriden_change_ind  is null
               and  swrbaja_fecha_baja is null
               and  swrbaja_permanent is null
            ---  and rownum < 50
               ORDER BY 1 ;

       cursor  materias (pspidm   number)    is
                select      swrbaja_reprobadas ||'-'||  swrbaja_ingles    ||':'||  swrbaja_swavcode                as materias  -- aqui va el scrse de la mat rep oport
                   from swrbaja swr
                               where swr.swrbaja_pidm  = pspidm
                               and  swrbaja_fecha_baja is null
                               and  swrbaja_permanent is null   ;



  BEGIN
    -- IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

----------------------------------AQUI EMPIEZA EL  REPORTE-----------------
------------------------------ENCABEZADO----------------------------------
 HTP.P('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
    <head>
        <title> Reporte GWABAJA "Alumnos que causan baja" </title>
    </head>
   <BODY>

   <body>
 <h1 >
 <center>
            Listado  de Baja de Alumnos   </h1> ');
 --- DBMS_OUTPUT.PUT_LINE(' AQUI VOY 1 ');
    HTP.P(' <center>

       <LI>     ART. 31: % de Aprobación de Asignaturas </LI>

        <LI>    ART. 32: Oportunidad de Reprobación de asignaturas </LI>

        <LI>    ART. 33: Prom. ponderado menor a 4,0 en dos periodos consecutivos  </LI>

     </center>
    ');


---HTP.P(' Ejec. '||to_date(sysdate,'dd/mm/yyyy hh:mm:ss');

  IF psBaja= 'BI' THEN
            vsReclDesc := 'Baja administrativa';
        END IF;
        IF psBaja= 'BA' THEN
            vsReclDesc := 'Causales de Eliminación';
        END IF;

----------------------------------------encabezado---------
--- DBMS_OUTPUT.PUT_LINE(' AQUI VOY 2 ');

 FOR vnI IN 1..vnColumnas LOOP
          tabColumna.EXTEND(vnI);
          tabColumna(vnI) := NULL;
      END LOOP;

 -- VICTOR VERIFICAR SI TRAE TODOS LOS QUE TIENEN BAJA

      tabColumna(1)  := 'ID';
      tabColumna(2)  := 'Nombre';
      tabColumna(3)  := 'RUT';
      tabColumna(4)  := 'Programa';
      tabColumna(5)  := 'Descripción';
   --   tabColumna(6)  := 'Periodo';
    tabColumna(6)  := 'Tipo Alumno';
    tabColumna(7)  := '% de aprobación ';
     tabColumna(8)  := 'Baja ART. 31 ';

   --  tabColumna(9)  := 'Oportunidades';
    tabColumna(10)  := ' Oportunidades- Materias-Subj-Scre'  ;
  --    tabColumna(11)  := 'Scre-Materia' ;
      tabColumna(12)  :=  'Baja ART. 32 ';

      tabColumna(13)  := 'Promedio pond. Anterior ';
      tabColumna(14)  := 'Promedio pond. Actual ';
      tabColumna(15)  := 'Baja ART. 33 ';




--- DBMS_OUTPUT.PUT_LINE(' AQUI VOY 3 ');
 FOR regRep IN cuBajas  LOOP--mod 2306

 IF vnExists = 0 THEN
             Pk_Sisrepimp.P_EncabezadoDeReporte(vsReclDesc,vnColumnas,tabColumna,vsInicoPag,'1',psSubtitulo=>'Periodo '||psTerm,psSeccion=>'3',psUniversidad=>pk_Catalogo.universidad(regRep.campCode));

             vsInicoPag := 'SALTO';
          END IF;

          --- OBTIENE VALOR DE PERS_SUFIX
          BEGIN
             SELECT  SPBPERS_NAME_SUFFIX
                INTO vsRut
                FROM SPBPERS
               WHERE SPBPERS_PIDM = regRep.bajaPidm;
     ----  dbms_output.put_line (' pidm '|| regRep.bajaPidm||' rut '|| vsRut);
          EXCEPTION
             WHEN no_data_found THEN
              vsRut     := null;
                vsError := SUBSTR(SQLERRM,1,500);
                dbms_output.put_line (' err ' ||vsError);
          END;

  ------regrsa el tipo alumno
          select ty.stvstyp_desc
              into vsnomtypo
            from stvstyp ty
            where ty.stvstyp_code = regRep.tipoalumn;

         FOR regRe3 IN materias (regRep.bajaPidm)  LOOP--mod  vic
            vsmateria  := vsmateria || '/'||  regRe3.materias ;

        end loop;

        if vsmateria =  '/-:'  then
         vsmateria  := null;
       end if;


----------------------------detalle-------------
  HTP.P('
   <tr>'||      '<td valign="top">'||regRep.idenIddd  ||'</td>'||
                '<td valign="top">'|| regRep.idenName   ||'</td>'||
                 '<td valign="top">'|| vsRut ||'</td>'||
                 '<td valign="top">'||RegRep.progCode||'</td>'||
                 '<td valign="top">'||regRep.progDesc||'</td>'||
                 '<td valign="top">'||regRep.tipoalumn||'-'|| vsnomtypo||'</td>'||---AS tipoalumn,
                 '<td valign="top">'||regRep.bajaPerRep||'</td>'||--art31
                 '<td valign="top">'||regRep.baja31||'</td>'||
               --  '<td valign="top">'||regRep.termBaja||'</td>'||
            --     '<td valign="top">'||regRep.nveces||'</td>'||--art32
                 '<td valign="top">'||vsmateria||'</td>'||-- sub-materia
            --     '<td valign="top">'||regRep.scre||'</td>'||-- scre-materia
                 '<td valign="top">'||regRep.baja32||'</td>'||
                 '<td valign="top">'||round((regRep.PONDERADO_ANT),1)||'</td>'||
                 '<td valign="top">'||round((regRep.bajaPromponde),1)||'</td>'||-- art33  hay que ponerle una clase de mascara de pesos 0.00
                 '<td valign="top">'||regRep.baja33||'</td>'||
                 '</tr>'

   ---- ROUND((vnTotalC/vnTotalM) * 100,2);
     );
     vsmateria := null;
   cnt1 := cnt1 + 1;
    vnExists := 1;
      END LOOP;

 IF vnExists = 0 THEN
          htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
      ELSE
          -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de pagina para impresion
          Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

          -- es omitido el encabezado del reporte pero se agrega el salto de pagina
          Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psSeccion=>'3');
      END IF;

 IF vnExists = 0 THEN
          htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
      ELSE
          -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de pagina para impresion
          Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

          -- es omitido el encabezado del reporte pero se agrega el salto de pagina
       -----   Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psSeccion=>'3');
      END IF;
  htp.p('</table>
 <tr>
  Número de Registros en Reporte.....: '|| cnt1||
 '</body></html>');

  EXCEPTION
      WHEN OTHERS THEN
           HTP.P('Error <<V1.1>>  '|| SQLERRM);
  END reporte;


END KWABAJA;
/
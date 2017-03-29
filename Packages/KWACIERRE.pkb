CREATE OR REPLACE PACKAGE BODY BANINST1.KWACIERRE
IS
   /*
            AUTOR: JCCR
            FECHA: 29/11/2010
            TAREA: Cierre de semestre UFT
           MODULO: Historia academica

     Evalua a todos los alumnos con estatus AS y que tengan materias inscritas para el periodo en el que se ejecuta.
     Inserta en tabla de paso a todos los estudiantes que caidan en los parametros recibidos
   */


procedure  p_borratblbaja  is

begin
  --------borra tbl paso-----
  delete swrpaso wr
  where wr.valor1 = 'kwacierre';

-----BORRA TBL DE PASO2----MARCE  me comento que se tenia que borrar al inicio del proceso  31-jul-2014  vic..
DELETE SWRCIRR;

 commit;
-- exception
  --    when no_data_found then
     --   null;
         --- return vnPromedio;
     -- when others then
       -- null;
end  p_borratblbaja;


------proceso de rankeo para todas las carreras 
--- create   glovicx
--- date   4-sept-2014
-----------------------------------------------------------
PROCEDURE pwranking   (psperiodo  varchar2, psnivel varchar2)  is

csAS     varchar2(2)  := 'AS' ;

vsTerm   VARCHAR2(12) ;
vsLevl  VARCHAR2(2) ;
camprog   varchar2(12);
rankeo       number  := 0;
promant    number := 0;

cursor cu_carreras  is
   SELECT DISTINCT S.SGBSTDN_PIDM                  AS Pidm,
                          s.sgbstdn_program_1                  as programa,
                          vsTerm      as periodo
                            ,(  select SH.SHRTGPA_GPA
                                 from    shrtgpa sh
                                 where SH.SHRTGPA_PIDM =  S.SGBSTDN_PIDM  
                                 and   SH.SHRTGPA_TERM_CODE =  vsTerm
                                 and  SH.SHRTGPA_LEVL_CODE  = vsLevl    )  as promedio
           FROM SGBSTDN S, Sfrstcr fr
           WHERE S.SGBSTDN_TERM_CODE_EFF  = (SELECT MAX(S2.SGBSTDN_TERM_CODE_EFF)
                                              FROM SGBSTDN S2
                                             WHERE S2.SGBSTDN_PIDM      = S.SGBSTDN_PIDM
                                               AND S2.SGBSTDN_LEVL_CODE = S.SGBSTDN_LEVL_CODE
                                              And  S2.SGBSTDN_TERM_CODE_EFF <= vsTerm  ) 
           AND  S.SGBSTDN_STST_CODE      = csAS
         --  AND (S.SGBSTDN_PIDM          = pnPidm OR pnPidm IS NULL)
           AND  S.SGBSTDN_LEVL_CODE      = vsLevl
           and  fr.sfrstcr_rsts_code  in ('RE','RW')
           and (fr.sfrstcr_error_flag <> 'F' OR fr.sfrstcr_error_flag is null)
           and  fr.sfrstcr_term_code = vsTerm
           and  s.sgbstdn_pidm  = fr.sfrstcr_pidm
      ORDER BY 2   ;



cursor cu_rank  is
select  substr(swbrank_programa,4,4)  as prog , (swbrank_promedio) as prom, swbrank_pidm as pidm
from swbrank
where ( swbrank_promedio is not null  and  swbrank_promedio <> 0)
order by 1,2 desc;


begin

vsLevl    :=  psnivel;
vsTerm  := psperiodo;


for reg1 in  cu_carreras   loop

insert into swbrank  ( SWBRANK_PIDM,SWBRANK_PROGRAMA,SWBRANK_PERIODO,SWBRANK_promedio,SWBRANK_ACTIVITY_DATE,SWBRANK_USER )
values ( reg1.pidm, reg1.programa, reg1.periodo,reg1.promedio, sysdate, user);

end loop;

commit;


------- este cursor es para asignar el rank como ya vienen acomodados del cursor solo le pasa el num de orden al campo rank como update
for reg2 in cu_rank  loop
---dbms_output.put_line('cambio de prog ' || camprog   );

if   camprog <>  reg2.prog  then
--dbms_output.put_line('cambio de programa ' || camprog   );

rankeo := 0;

end if;

if   reg2.prom  = promant  then 
rankeo := rankeo -1;
--dbms_output.put_line('cambio de promedio  ' || rankeo   );
end if;

rankeo := rankeo + 1;
update  swbrank
set    swbrank_ranking  = rankeo
where swbrank_pidm = reg2.pidm
and   swbrank_promedio = reg2.prom;


camprog := reg2.prog ;
promant := reg2.prom;

--dbms_output.put_line('cambio de prog ' || rankeo   );

end loop;


COMMIT;
exception
when others then

dbms_output.put_line( 'error  v 1 '||SQLERRM);

end pwranking;




 procedure splitChain ( lcadena in  varchar2) is
--declare
 --- l_frase VARCHAR2 (32766) := 'ARQU', 'DERE', 'KINE')';
  lpos    number:=0;
--lpos2    number :=0;
conta   number := 1;
tamcan  number;

begin

  tamcan :=  length(lcadena);
 lpos := (INSTR(lcadena, ','));
    --DBMS_OUTPUT.put_line ('TAMAÑO TOTAL DELA CADENA > '||tamcan);

---delete swrpaso commit;
FOR x IN  1..tamcan LOOP

 IF  conta > tamcan  then
  -- DBMS_OUTPUT.put_line(CONTA);
  exit;
  else
   -- DBMS_OUTPUT.put_line(X);
 insert into swrpaso values('kwacierre', (SUBSTR(lcadena,conta,4 )));

 --DBMS_OUTPUT.put_line ('AA '||SUBSTR(lcadena,conta,4 )||'--'|| conta );
 -- lpos := lpos + 5;
 conta := conta +lpos ;
 end if;
    END LOOP;
commit;

 exception
      when no_data_found then
        null;
         --- return vnPromedio;
      when others then
        null;
          -- return vnPromedio;
end splitChain;





   FUNCTION ValidaIngles (pnPidm    NUMBER)
      RETURN VARCHAR2;



   PROCEDURE tablaDePaso (psTerm         VARCHAR2,
                          pnPidm         NUMBER DEFAULT NULL,
                          psLevel        VARCHAR2,
                          psAtributo     VARCHAR2,
                          psTipo         VARCHAR2 DEFAULT NULL,
                          psCondicion    VARCHAR2 DEFAULT NULL,
                          psValIng       VARCHAR2);

   PROCEDURE cierre (psTerm        VARCHAR2,
                     pnPidm        NUMBER DEFAULT NULL,
                     psLevl        VARCHAR2,
                     psAtributo    VARCHAR2,
                     psValIng      VARCHAR2);

   

   FUNCTION ValidaIngles (pnPidm    NUMBER)

      RETURN VARCHAR2
   IS
      --- Regresa el Valor del nivel de ingles
      vsNivelIngles   VARCHAR2 (4) := NULL;
      vnNivelIngles   NUMBER(1):= NULL;
   BEGIN
      -- Obtiene Nivel maximo de ingles para el alumno
      BEGIN
      SELECT MAX(SWCINVI_NVL_NUMB) INTO vnNivelIngles
              FROM SHRTCKN N, SHRTCKG G, SWCINVI
             WHERE N.SHRTCKN_CRSE_NUMB = SWCINVI_CRSE_NUMB
             AND   N.SHRTCKN_SUBJ_CODE = SWCINVI_SUBJ_CODE
             AND N.SHRTCKN_PIDM = pnPidm
               AND G.SHRTCKG_PIDM = N.SHRTCKN_PIDM
               AND G.SHRTCKG_TERM_CODE = N.SHRTCKN_TERM_CODE
               AND G.SHRTCKG_TCKN_SEQ_NO = N.SHRTCKN_SEQ_NO
               AND (G.SHRTCKG_GRDE_CODE_FINAL = 'AC'
                     OR G.SHRTCKG_GRDE_CODE_FINAL >= '4')
               AND G.SHRTCKG_SEQ_NO =
                      (SELECT MAX (G1.SHRTCKG_SEQ_NO)
                         FROM SHRTCKG G1
                        WHERE G1.SHRTCKG_PIDM = G.SHRTCKG_PIDM
                          AND G1.SHRTCKG_TERM_CODE = G.SHRTCKG_TERM_CODE
                          AND G1.SHRTCKG_TCKN_SEQ_NO = G.SHRTCKG_TCKN_SEQ_NO);
      
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnNivelIngles  := NULL;
      
      END;
      BEGIN
      
      
      SELECT MAX(SWCINVI_NVL_CODE) INTO  vsNivelIngles FROM SWCINVI
      WHERE SWCINVI_NVL_NUMB  = vnNivelIngles;
      
      
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vsNivelIngles  := NULL;
      END;


      RETURN vsNivelIngles;
   END ValidaIngles;


   FUNCTION Mat_aprobadas (psTerm VARCHAR2 DEFAULT NULL,    -- rcm 15 jun 2011
                                                        pnPidm NUMBER, psLevl VARCHAR2)
      RETURN VARCHAR2
   IS
      vnTotal     NUMBER := 1;
      vnTotalAp   NUMBER := 0;

   BEGIN
      BEGIN
         SELECT DECODE (COUNT (1), 0, 1, COUNT (1))
           INTO vnTotal
           FROM SHRTCKL l,
                SHRTCKN n, SHRTCKG g1
          WHERE     l.shrtckl_pidm = n.shrtckn_pidm
                and l.shrtckl_term_code = n.shrtckn_term_code
                and L.shrtckl_levl_code = psLevl
                and l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
                and n.SHRTCKN_PIDM = g1.SHRTCKG_PIDM
                AND n.SHRTCKN_TERM_CODE = g1.SHRTCKG_TERM_CODE
                AND n.SHRTCKN_SEQ_NO = g1.SHRTCKG_TCKN_SEQ_NO
                AND g1.SHRTCKG_SEQ_NO =
                       (SELECT MAX (g2.SHRTCKG_SEQ_NO)
                          FROM SHRTCKG g2
                         WHERE g1.SHRTCKG_PIDM = g2.SHRTCKG_PIDM
                               AND g1.SHRTCKG_TERM_CODE =
                                      g2.SHRTCKG_TERM_CODE
                               AND g1.SHRTCKG_TCKN_SEQ_NO =
                                      g2.SHRTCKG_TCKN_SEQ_NO)
                ---------------------------------------------------------------------
                AND n.shrtckn_pidm = pnPidm
                and g1.SHRTCKG_GRDE_CODE_FINAL NOT IN ('NV')
                AND g1.SHRTCKG_TERM_CODE = psTerm;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnTotal := 1;
      END;

      BEGIN
         SELECT COUNT (1)
           INTO vnTotalAp
           FROM SHRTCKL l,
                SHRTCKN n, SHRTCKG g1
          WHERE     l.shrtckl_pidm = n.shrtckn_pidm
                    and l.shrtckl_term_code = n.shrtckn_term_code
                    and l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
                    and n.SHRTCKN_PIDM = g1.SHRTCKG_PIDM
                AND n.SHRTCKN_TERM_CODE = g1.SHRTCKG_TERM_CODE
                AND n.SHRTCKN_SEQ_NO = g1.SHRTCKG_TCKN_SEQ_NO
                AND g1.SHRTCKG_SEQ_NO =
                       (SELECT MAX (g2.SHRTCKG_SEQ_NO)
                          FROM SHRTCKG g2
                         WHERE g1.SHRTCKG_PIDM = g2.SHRTCKG_PIDM
                               AND g1.SHRTCKG_TERM_CODE =
                                      g2.SHRTCKG_TERM_CODE
                               AND g1.SHRTCKG_TCKN_SEQ_NO =
                                      g2.SHRTCKG_TCKN_SEQ_NO)
                ---------------------------------------------------------------------
                AND n.shrtckn_pidm = pnPidm
                AND g1.SHRTCKG_TERM_CODE = psTerm
                and l.shrtckl_levl_code = psLevl 
                AND (g1.SHRTCKG_GRDE_CODE_FINAL = 'AC'
                     OR SHRTCKG_GRDE_CODE_FINAL >= '4')
                     AND g1.SHRTCKG_GRDE_CODE_FINAL <> 'P'; --  >= 4; -- rcm 16 jun 2011
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnTotalAp := 0;
      END;


      RETURN vnTotalAp;                                      --rcm 15 jun 2011
   -- RETURN pnPidm|| '-' || psTerm || ' -- ' ||vnTotal || ' --- ' ||vnTotalAp;  -- rcm pruebas 16 junio 2011


   END Mat_aprobadas;

  FUNCTION Porcentaje_Mat_aprobadas(psTerm VARCHAR2 DEFAULT NULL,    -- rcm 15 jun 2011
                                                        pnPidm NUMBER, psLevl VARCHAR2)
      RETURN VARCHAR2
   IS
      vnTotal     NUMBER := 1;
      vnTotalAp   NUMBER := 0;
   --  vnTotal   varchar2(100) := null;
   --  vnTotalAp varchar2(100) := null;

   BEGIN
      BEGIN
         SELECT SUM(g1.shrtckg_credit_hours)--DECODE (COUNT (1), 0, 1, COUNT (1))
           INTO vnTotal
           FROM SHRTCKL l,
                SHRTCKN n, SHRTCKG g1
          WHERE     l.shrtckl_pidm = n.shrtckn_pidm
                    and l.shrtckl_term_code = n.shrtckn_term_code
                    and l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
                    and n.SHRTCKN_PIDM = g1.SHRTCKG_PIDM
                AND n.SHRTCKN_TERM_CODE = g1.SHRTCKG_TERM_CODE
                AND n.SHRTCKN_SEQ_NO = g1.SHRTCKG_TCKN_SEQ_NO
                AND g1.SHRTCKG_SEQ_NO =
                       (SELECT MAX (g2.SHRTCKG_SEQ_NO)
                          FROM SHRTCKG g2
                         WHERE g1.SHRTCKG_PIDM = g2.SHRTCKG_PIDM
                               AND g1.SHRTCKG_TERM_CODE =
                                      g2.SHRTCKG_TERM_CODE
                               AND g1.SHRTCKG_TCKN_SEQ_NO =
                                      g2.SHRTCKG_TCKN_SEQ_NO)
                ---------------------------------------------------------------------
                AND n.shrtckn_pidm = pnPidm
                AND l.shrtckl_levl_code = psLevl
                and g1.SHRTCKG_GRDE_CODE_FINAL NOT IN ('NV')
                AND g1.SHRTCKG_GMOD_CODE NOT IN ('C', 'X', 'G', 'M')
                
                AND g1.SHRTCKG_TERM_CODE = psTerm;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnTotal := 1;
      END;

      BEGIN
         SELECT SUM(g1.shrtckg_credit_hours) --COUNT (1)
           INTO vnTotalAp
           FROM SHRTCKL l,
                SHRTCKN n, SHRTCKG g1
          WHERE     l.shrtckl_pidm = n.shrtckn_pidm
                    and l.shrtckl_term_code = n.shrtckn_term_code
                    and l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
                    and n.SHRTCKN_PIDM = g1.SHRTCKG_PIDM
                AND n.SHRTCKN_TERM_CODE = g1.SHRTCKG_TERM_CODE
                AND n.SHRTCKN_SEQ_NO = g1.SHRTCKG_TCKN_SEQ_NO
                   AND g1.SHRTCKG_GMOD_CODE NOT IN ('C', 'X', 'G','M')
                   and g1.SHRTCKG_GRDE_CODE_FINAL NOT IN ('NV')
                AND g1.SHRTCKG_SEQ_NO =
                       (SELECT MAX (g2.SHRTCKG_SEQ_NO)
                          FROM SHRTCKG g2
                         WHERE g1.SHRTCKG_PIDM = g2.SHRTCKG_PIDM
                               AND g1.SHRTCKG_TERM_CODE =
                                      g2.SHRTCKG_TERM_CODE
                               AND g1.SHRTCKG_TCKN_SEQ_NO =
                                      g2.SHRTCKG_TCKN_SEQ_NO)
                ---------------------------------------------------------------------
                AND n.shrtckn_pidm = pnPidm
                and l.shrtckl_levl_code = psLevl
                AND g1.SHRTCKG_TERM_CODE = psTerm
                AND (g1.SHRTCKG_GRDE_CODE_FINAL = 'AC'
                     OR SHRTCKG_GRDE_CODE_FINAL >= '4')
                AND g1.SHRTCKG_GRDE_CODE_FINAL <> 'P'; --  >= 4; -- rcm 16 jun 2011
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnTotalAp := 0;
      END;

  RETURN TRUNC ( (vnTotalAp * 100 / vnTotal), 1);       -- rcm 15 jun 2011
   -- RETURN pnPidm|| '-' || psTerm || ' -- ' ||vnTotal || ' --- ' ||vnTotalAp;  -- rcm pruebas 16 junio 2011



   END Porcentaje_Mat_aprobadas;



   FUNCTION Mat_aprobadasGral (pnPidm NUMBER, psTerm VARCHAR, psLevl        VARCHAR2)
      RETURN VARCHAR2
   IS
      vnTotal     NUMBER := 1;
      vnTotalAp   NUMBER := 0;
   --  vnTotal   varchar2(100) := null;
   --  vnTotalAp varchar2(100) := null;

   BEGIN
      BEGIN
         SELECT SUM(shrtckg_credit_hours)-- DECODE (COUNT (1), 0, 1, COUNT (1)) 
           INTO vnTotal
           FROM SHRTCKL l,
                SHRTCKN n, SHRTCKG g1
          where
          l.shrtckl_pidm = n.shrtckn_pidm
          and l.shrtckl_term_code = n.shrtckn_term_code
          and l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
          and l.shrtckl_levl_code = psLevl
          ---------------------------------------------------------------------
          --and
          and     n.SHRTCKN_PIDM = g1.SHRTCKG_PIDM
                AND n.SHRTCKN_TERM_CODE = g1.SHRTCKG_TERM_CODE
                AND n.SHRTCKN_SEQ_NO = g1.SHRTCKG_TCKN_SEQ_NO
                and g1.SHRTCKG_GRDE_CODE_FINAL NOT IN ('NV')
                AND g1.SHRTCKG_SEQ_NO =
                       (SELECT MAX (g2.SHRTCKG_SEQ_NO)
                          FROM SHRTCKG g2
                         WHERE g1.SHRTCKG_PIDM = g2.SHRTCKG_PIDM
                               AND g1.SHRTCKG_TERM_CODE =
                                      g2.SHRTCKG_TERM_CODE
                               AND g1.SHRTCKG_TCKN_SEQ_NO =
                                      g2.SHRTCKG_TCKN_SEQ_NO)
                ---------------------------------------------------------------------
                AND n.shrtckn_pidm = pnPidm
                AND SHRTCKG_GMOD_CODE NOT IN ('C', 'X', 'G','M')
--                AND (SUBSTR (SHRTCKN_TERM_CODE, 5, 2) =
--                        DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
--                     OR SUBSTR (SHRTCKN_TERM_CODE, 5, 2) =
--                           DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
                AND SUBSTR (SHRTCKN_TERM_CODE, 1, 6) <= SUBSTR (psTerm, 1, 6);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnTotal := 1;
      END;

      BEGIN
           SELECT SUM(g1.shrtckg_credit_hours)--COUNT (1)
           INTO vnTotalAp
           FROM SHRTCKL l,
                SHRTCKN n, SHRTCKG g1
            where
          l.shrtckl_pidm = n.shrtckn_pidm
          and l.shrtckl_term_code = n.shrtckn_term_code
          and l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
          and l.shrtckl_levl_code = psLevl
          ---------------------------------------------------------------------
          and     n.SHRTCKN_PIDM = g1.SHRTCKG_PIDM
                AND n.SHRTCKN_TERM_CODE = g1.SHRTCKG_TERM_CODE
                AND n.SHRTCKN_SEQ_NO = g1.SHRTCKG_TCKN_SEQ_NO
                AND g1.SHRTCKG_SEQ_NO =
                       (SELECT MAX (g2.SHRTCKG_SEQ_NO)
                          FROM SHRTCKG g2
                         WHERE g1.SHRTCKG_PIDM = g2.SHRTCKG_PIDM
                               AND g1.SHRTCKG_TERM_CODE =
                                      g2.SHRTCKG_TERM_CODE
                               AND g1.SHRTCKG_TCKN_SEQ_NO =
                                      g2.SHRTCKG_TCKN_SEQ_NO)
                ---------------------------------------------------------------------
                AND n.shrtckn_pidm = pnPidm
                   and g1.SHRTCKG_GRDE_CODE_FINAL NOT IN ('NV')
                   AND g1.SHRTCKG_GMOD_CODE NOT IN ('C', 'X', 'M','G')
--                AND (SUBSTR (SHRTCKN_TERM_CODE, 5, 2) =
--                        DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
--                     OR SUBSTR (SHRTCKN_TERM_CODE, 5, 2) =
--                           DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
                AND SUBSTR (SHRTCKN_TERM_CODE, 1, 6) <= SUBSTR (psTerm, 1, 6)
                AND (g1.SHRTCKG_GRDE_CODE_FINAL = 'AC'
                     OR SHRTCKG_GRDE_CODE_FINAL >= '4')
                AND g1.SHRTCKG_GRDE_CODE_FINAL <> 'P'  ; --  >= rcm 16 jun 2011
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnTotalAp := 0;
      END;

     if vnTotalAp <= vnTotal then
      RETURN TRUNC ( (vnTotalAp * 100 / vnTotal), 1);       -- rcm 15 jun 2011
   -- RETURN pnPidm|| '-' || psTerm || ' -- ' ||vnTotal || ' --- ' ||vnTotalAp;  -- rcm pruebas 16 junio 2011
else
return null;
end if;

   END Mat_aprobadasGral;


   FUNCTION Mat_inscritas (psTerm VARCHAR2 DEFAULT NULL,    -- mac 15 jun 2011
                                                        pnPidm NUMBER)
      RETURN VARCHAR2
   IS
      vnTotal   NUMBER := 1;
   --  vnTotal   varchar2(100) := null;
   --  vnTotalAp varchar2(100) := null;

   BEGIN
      BEGIN
         SELECT DECODE (COUNT (1), 0, 0, COUNT (1))
           INTO vnTotal
           FROM SFRSTCR
          WHERE     SFRSTCR_PIDM = pnPidm
                AND SFRSTCR_TERM_CODE = psTerm
                AND SFRSTCR_RSTS_CODE IN ('RE', 'RW')
                AND (SFRSTCR_ERROR_FLAG <> 'F' OR SFRSTCR_ERROR_FLAG IS NULL );
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnTotal := 0;
      END;


      RETURN vnTotal;
   -- RETURN pnPidm|| '-' || psTerm || ' -- ' ||vnTotal || ' --- ' ||vnTotalAp;  -- rcm pruebas 16 junio 2011


   END Mat_inscritas;



   FUNCTION f_CreditosPrograma (psTerm VARCHAR2, psPrograma VARCHAR2)
      RETURN NUMBER
   IS
      vnCreditoMateria   NUMBER := 0;
   BEGIN
      BEGIN
         SELECT SMBPGEN_REQ_CREDITS_OVERALL
           INTO vnCreditoMateria
           FROM SMBPGEN
          WHERE     SMBPGEN_TERM_CODE_EFF = psTerm
                AND SMBPGEN_PROGRAM = psPrograma
                AND SMBPGEN_ACTIVE_IND = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnCreditoMateria := 0;
      END;

      RETURN vnCreditoMateria;
   END f_CreditosPrograma;


   -- obtiene y muestra la información adicional cuando se trata de una clase: --
   PROCEDURE P_DetToolTip (pnPidm NUMBER, psLevel VARCHAR, psTerm VARCHAR2)
   IS
      CURSOR cuInfo
      IS
         SELECT DISTINCT n.shrtckn_subj_code SUBJ,
                n.shrtckn_crse_numb CRSE,
                n.shrtckn_term_code TERM
           FROM shrtckn n,
                shrtckg g,
                shrtckl l,
                shrgrde r
          WHERE n.shrtckn_pidm = pnPidm--f_getpidm('00011955')
                AND (r.shrgrde_quality_points <=
                        (SELECT SWAVMRE_GRDE_MIN
                           FROM SWAVMRE
                          WHERE SWAVMRE_LEVL_CODE = psLevel))
                AND shrgrde_gpa_ind = 'Y'
                AND (n.shrtckn_repeat_course_ind IS NULL OR n.shrtckn_repeat_course_ind = 'I')
                AND NVL (g.shrtckg_credit_hours, 0) > 0
                AND shrgrde_passed_ind = 'N'
                AND l.shrtckl_levl_code = psLevel
                AND r.shrgrde_code <> 'OU'
                -------------------------------------MAC
                AND (SUBSTR (n.shrtckn_term_code, 5, 2) = DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
                     OR
                     SUBSTR (n.shrtckn_term_code, 5, 2) = DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75)
                    )
                AND SUBSTR (n.shrtckn_term_code, 1, 6) <= SUBSTR (psTerm, 1, 6)
                AND INSTR (r.shrgrde_code, ',') > 0
                AND g.shrtckg_pidm = n.shrtckn_pidm
                AND g.shrtckg_term_code = n.shrtckn_term_code
                AND g.shrtckg_tckn_seq_no = n.shrtckn_seq_no
                AND g.shrtckg_seq_no =
                       (SELECT MAX (g1.shrtckg_seq_no)
                          FROM shrtckg g1
                         WHERE     g1.shrtckg_pidm = g.shrtckg_pidm
                               AND g1.shrtckg_term_code = g.shrtckg_term_code
                               AND g1.shrtckg_tckn_seq_no = g.shrtckg_tckn_seq_no)
                AND l.shrtckl_pidm = n.shrtckn_pidm
                AND l.shrtckl_term_code = n.shrtckn_term_code
                AND l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
                AND r.shrgrde_code = g.shrtckg_grde_code_final
                AND r.shrgrde_levl_code = l.shrtckl_levl_code;
--         SELECT DISTINCT
--                SWVHIAC_SUBJ SUBJ, SWVHIAC_CRSE CRSE, SWVHIAC_TERM_CODE TERM
--           FROM SWVHIAC A
--          WHERE SWVHIAC_PIDM = pnPidm
--                AND (SWVHIAC_QUALITY_POINTS <=
--                        (SELECT SWAVMRE_GRDE_MIN
--                           FROM SWAVMRE
--                          WHERE SWAVMRE_LEVL_CODE = psLevel))
--                AND SWVHIAC_GPA_IND = 'Y'
--                AND NVL (SWVHIAC_CREDIT_HOURS, 0) > 0
--                AND SWVHIAC_PASSED_IND = 'N'
--                AND SWVHIAC_LEVL_CODE = psLevel
--                AND SWVHIAC_CALIF <> 'OU'
--                -------------------------------------MAC
--                AND (SUBSTR (SWVHIAC_TERM_CODE, 5, 2) =
--                        DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
--                     OR SUBSTR (SWVHIAC_TERM_CODE, 5, 2) =
--                           DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
--                AND SUBSTR (SWVHIAC_TERM_CODE, 1, 6) <= SUBSTR (psTerm, 1, 6)
--                AND INSTR (SWVHIAC_CALIF, ',') > 0
--                AND NOT EXISTS
--                           (SELECT 1
--                              FROM SWVHIAC T
--                             WHERE T.SWVHIAC_PIDM = A.SWVHIAC_PIDM
--                                   AND T.SWVHIAC_LEVL_CODE =
--                                          A.SWVHIAC_LEVL_CODE
--                                   AND T.SWVHIAC_CRSE = A.SWVHIAC_CRSE
--                                   AND T.SWVHIAC_SUBJ = A.SWVHIAC_SUBJ
--                                   AND T.SWVHIAC_PASSED_IND = 'Y');
   BEGIN
      FOR regInf IN cuInfo
      LOOP
         HTP.
          p (
            'Detalle:'
            || regInf.SUBJ
            || ' - '
            || regInf.CRSE
            || ' - '
            || regInf.TERM
            || ';');
      END LOOP;
   END P_DetToolTip;


   
  -- obtiene y muestra la información adicional cuando se trata de una clase: --
   PROCEDURE P_DetToolTipA (pnPidm NUMBER, psTerm VARCHAR2)
   IS
      CURSOR cuInfo1(
         pnPidm    NUMBER,
         psTerm    VARCHAR)
      IS

Select DISTINCT shrtckn_subj_code SUBJ, shrtckn_crse_numb CRSE,
           count(shrtckn_subj_code||shrtckn_crse_numb)  cuenta 
            from shrtckn n, shrtckl l
            where  n.shrtckn_pidm   = pnPidm
            AND l.shrtckl_pidm = n.shrtckn_pidm
            AND l.shrtckl_term_code = n.shrtckn_term_code
            AND l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
            and n.shrtckn_term_code <= psTerm            
        group by shrtckn_pidm, shrtckn_subj_code , shrtckn_crse_numb 
        having count(shrtckn_subj_code||shrtckn_crse_numb) > 1
        order by 1;

   CURSOR cuDetalle(
         pnPidm    NUMBER,
         SUBJ    VARCHAR,
     CRSE    VARCHAR2,
     psTerm  VARCHAR2)
      IS

Select DISTINCT shrtckn_subj_code SUBJ, shrtckn_crse_numb CRSE
           FROM SHRTCKN N, SHRTCKG G
                   WHERE G.SHRTCKG_PIDM = N.SHRTCKN_PIDM
                    AND G.SHRTCKG_TERM_CODE = N.SHRTCKN_TERM_CODE
                    AND G.SHRTCKG_TCKN_SEQ_NO = N.SHRTCKN_SEQ_NO
                    AND N.SHRTCKN_PIDM = pnPidm
                    AND N.SHRTCKN_SUBJ_CODE = subj
                    AND N.SHRTCKN_CRSE_NUMB = crse
                    AND (G.SHRTCKG_GRDE_CODE_FINAL < '4,0' OR G.SHRTCKG_GRDE_CODE_FINAL = 'RE')
                    AND N.SHRTCKN_TERM_CODE = psTerm
                    AND G.SHRTCKG_SEQ_NO =
                      (SELECT MAX (G1.SHRTCKG_SEQ_NO)
                         FROM SHRTCKG G1
                        WHERE G1.SHRTCKG_PIDM = G.SHRTCKG_PIDM
                          AND G1.SHRTCKG_TERM_CODE = G.SHRTCKG_TERM_CODE
                          AND G1.SHRTCKG_TCKN_SEQ_NO = G.SHRTCKG_TCKN_SEQ_NO);

    

        
   BEGIN
      FOR regInf IN cuInfo1(pnPidm, psTerm)
      LOOP

    FOR regDetalle IN cuDetalle(pnPidm, regInf.subj, regInf.crse, psTerm)
    loop

         HTP.
          p (
            'Detalle:'
            || regDetalle.SUBJ
            || ' - '
            || regDetalle.CRSE
            || ';');
      END LOOP;
      end loop;
   END P_DetToolTipA;
   

   -- muestra la información de las clases y eventos:
   PROCEDURE P_InformacionCurso (psInicio    VARCHAR2 DEFAULT NULL,
                                 psFin       VARCHAR2 DEFAULT NULL,
                                 psHrI       VARCHAR2 DEFAULT NULL,
                                 psHrF       VARCHAR2 DEFAULT NULL,
                                 psDias      VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      HTP.
       prn (
            ''''
         || psInicio
         || ''','''
         || psFin
         || ''','''
         || psHrI
         || ''','''
         || psHrF
         || ''','''
         || psDias
         || ''','''
         || 'vsNombre'
         || ''','''
         || 'vsSubj'
         || ''','''
         || 'vsCrse'
         || ''','''
         || 'vsTitl'
         || ''','''
         || 'vsLista'
         || ''','''
         || 'vsTipoLista'
         || ''','''
         || 'vsCollDesc'
         || 'vsCollDescEv'
         || '''');
   END P_InformacionCurso;

   PROCEDURE tablaDePaso (psTerm         VARCHAR2,
                          pnPidm         NUMBER DEFAULT NULL,
                          psLevel        VARCHAR2,
                          psAtributo     VARCHAR2,
                          psTipo         VARCHAR2 DEFAULT NULL,
                          psCondicion    VARCHAR2 DEFAULT NULL,
                          psValIng       VARCHAR2)
   IS
      TYPE reg_Cierre IS RECORD
      (
         rPidm         SWRCIRR.SWRCIRR_PIDM%TYPE,
         rTerm         SWRCIRR.SWRCIRR_TERM%TYPE,
         rCampus       SWRCIRR.SWRCIRR_CAMPUS%TYPE,
         rMatReprob    SWRCIRR.SWRCIRR_MAT_REPROB%TYPE,
         rOporAgot     SWRCIRR.SWRCIRR_OPORT_AGOTADA%TYPE,
         rNivIngl      SWRCIRR.SWRCIRR_NIVEL_INGLES%TYPE,
         rPorcAvance   SWRCIRR.SWRCIRR_PORC_AVANCE%TYPE,
         rSemestre     SWRCIRR.SWRCIRR_SEMESTRE%TYPE,
         rMajorCode    SWRCIRR.SWRCIRR_MAJR_CODE%TYPE,
         rLevlCode     SWRCIRR.SWRCIRR_LEVL_CODE%TYPE,
         rProgram      SWRCIRR.SWRCIRR_PROGRAM%TYPE,
         rId           SWRCIRR.SWRCIRR_ID%TYPE,
         rLastName     SWRCIRR.SWRCIRR_LAST_NAME%TYPE,
         rFistName     SWRCIRR.SWRCIRR_FIRST_NAME%TYPE,
         rSwarCode     SWRCIRR.SWRCIRR_SWAR_CODE%TYPE,
         rCalifProm    NUMBER (5, 2),
         rRanking      SWRCIRR.SWRCIRR_RANKING%TYPE,
         rPerReprob    SWRCIRR.SWRCIRR_PER_REPR%TYPE,
         rPorcPeriodo SWRCIRR.SWRCIRR_PORC_PERIODO%TYPE
      );

      TYPE tableCierre IS TABLE OF reg_Cierre
                             INDEX BY BINARY_INTEGER;

      tabCierre           tableCierre;

      i_NivIngles         VARCHAR2 (10) := NULL;
      i_NivInglesCrse     VARCHAR2 (10) := NULL;
      i_NivInglesTot      VARCHAR2 (10) := NULL;
      q_Ingles_sgaus      VARCHAR2 (10) := NULL;
      q_niv_ingles        VARCHAR2 (6) := NULL;
      q_mat_reprob        VARCHAR2 (6) := NULL;
      q_oportunidad       NUMBER(3) := 0;
      q_voportunidad      VARCHAR2(6)   := NULL;
      q_porc_avance       VARCHAR2 (6) := NULL;
      q_semestre          VARCHAR2 (6) := NULL;
      vsError             VARCHAR2 (500) := NULL;
  /*    vsCondicion         VARCHAR2 (9000)
         := REPLACE (SUBSTR (psCondicion, 2, LENGTH (psCondicion) - 2),
                     '''',
                     NULL);       */  -- SE CAMBIA FUNCIONALIDAD VIC..

      vsId                SPRIDEN.SPRIDEN_ID%TYPE := NULL;
      vsLast              SPRIDEN.SPRIDEN_LAST_NAME%TYPE := NULL;
      vsFirst             SPRIDEN.SPRIDEN_FIRST_NAME%TYPE := NULL;

      vnIngles            NUMBER := NULL;
      vnRep               NUMBER := NULL;
      vnOcu               NUMBER := NULL;
      vnAvan              NUMBER := NULL;
      vnNivIn             NUMBER := NULL;
      vnSemestre          NUMBER := NULL;
      vnRanking           VARCHAR2(5);
      vnCuentaRep         NUMBER := NULL;
      vnCuentaPer         NUMBER := NULL;
      vnCuentaTot         NUMBER := NULL;
      vnPerReprob         NUMBER := NULL;
      vnCalifProm         NUMBER (3, 2) := NULL;
      vnPerRepCons        INTEGER := 0;
      vsTermA             VARCHAR2 (7) := NULL;
      vnContador          INTEGER := 1;
      vnBarre             INTEGER := 0;
      vsPerPaso           VARCHAR2 (10) := NULL;
      vnQueRank           INTEGER := 1;
      vnValAnt            NUMBER (3, 2) := 0;
      vnValAct            NUMBER (3, 2) := 0;
      vnOporOcup          NUMBER := 0;
      vnPromAnt           NUMBER := 0;
      vnPromAnt1          NUMBER := 0;
      vsRank              VARCHAR2 (15) := NULL;
      vsPerRepCon      VARCHAR2 (15) := NULL;
      vsPorcPeriodo    VARCHAR2 (15) := NULL;
      vsBanRep            VARCHAR2 (1) := 'N';
      vnOporCurs       NUMBER;
      vnOpor           NUMBER;
      vnCuenta         NUMBER;
      csCampus   CONSTANT VARCHAR2 (6) := F_CONTEXTO ();
      csAS       CONSTANT VARCHAR2 (2) := 'AS';
      csAst      CONSTANT VARCHAR2 (1) := '*';
      csEsp      CONSTANT VARCHAR2 (1) := ' ';
      csCma      CONSTANT VARCHAR2 (1) := ',';


      CURSOR cuEstuduante (
         pnPidm       NUMBER DEFAULT NULL,
         psPeriodo    VARCHAR2)
      IS
           SELECT S.SGBSTDN_PIDM stdnPidm,
                  S.SGBSTDN_PROGRAM_1 stdnProg,
                  S.SGBSTDN_CAMP_CODE stdnCamp,
                  S.SGBSTDN_MAJR_CODE_1 stdnMajr,
                  NVL (
                     (SELECT MAX(SHRTGPA_GPA)
                        FROM SHRTGPA
                       WHERE     SHRTGPA_PIDM = S.SGBSTDN_PIDM
                             AND SHRTGPA_LEVL_CODE = S.SGBSTDN_LEVL_CODE
                             AND SHRTGPA_TERM_CODE = psPeriodo),
                     0)
                     PromPeriodo
             FROM SGBSTDN S
            WHERE S.SGBSTDN_TERM_CODE_EFF =
                     (SELECT MAX (S2.SGBSTDN_TERM_CODE_EFF)
                        FROM SGBSTDN S2
                       WHERE S2.SGBSTDN_PIDM = S.SGBSTDN_PIDM
                             AND S2.SGBSTDN_TERM_CODE_EFF <=psPeriodo)
                  AND S.SGBSTDN_STST_CODE = csAS
                  AND S.SGBSTDN_LEVL_CODE = psLevel
                  AND (S.SGBSTDN_PIDM = pnPidm OR pnPidm IS NULL)
                  AND EXISTS
                         (SELECT 1
                            FROM SFRSTCR
                           WHERE     SFRSTCR_PIDM = SGBSTDN_PIDM
                                 AND SFRSTCR_TERM_CODE = psPeriodo
                                 AND SFRSTCR_RSTS_CODE IN ('RE', 'RW')
                                 AND  SFRSTCR_LEVL_CODE   = psLevel
                                 AND (SFRSTCR_ERROR_FLAG <> 'F' OR SFRSTCR_ERROR_FLAG IS NULL ))
           AND (S.SGBSTDN_MAJR_CODE_1  in (select valor2 from swrpaso where valor1 = 'kwacierre'  )
             or S.SGBSTDN_MAJR_CODE_1 is null)
         ORDER BY PromPeriodo DESC, stdnPidm ASC;



      --NIVEL DEL GRUPO FUNDAMENTAL / ***  PERIODO EN EL QUE SE UBICA
      CURSOR C_SEMESTRE (
         pnPidm      NUMBER,
         pProgram    VARCHAR)
      IS
         SELECT MAX (SUBSTR (A.SMBAOGN_AREA, LENGTH (A.SMBAOGN_AREA) - 1, 2))
                   grupo
           FROM SMBAOGN A
          WHERE     A.SMBAOGN_PIDM = pnPidm
                AND A.SMBAOGN_PROGRAM = pProgram
                AND A.SMBAOGN_MET_IND = 'Y'                 --confirmar adrian
                AND A.SMBAOGN_REQUEST_NO =
                       (SELECT MAX (W.SMBAOGN_REQUEST_NO)
                          FROM SMBAOGN W
                         WHERE     W.SMBAOGN_PIDM = A.SMBAOGN_PIDM
                               AND W.SMBAOGN_AREA = A.SMBAOGN_AREA
                               AND W.SMBAOGN_PROGRAM = A.SMBAOGN_PROGRAM
                               AND W.SMBAOGN_MET_IND = A.SMBAOGN_MET_IND)
                AND SUBSTR (A.SMBAOGN_AREA, LENGTH (A.SMBAOGN_AREA) - 1, 2) IN
                       ('00',
                        '01',
                        '02',
                        '03',
                        '04',
                        '05',
                        '06',
                        '07',
                        '08',
                        '09',
                        '10',
                        '11',
                        '12',
                        '13',
                        '14',
                        '15',
                        '16',
                        '17');

      -- MATERIAS REPROBADAS ELEMENTO 3 TOTAL DE MATERIAS REPROBADAS EN HISTORIA ACADEMICA
      CURSOR C_MATREPROB (pnPidm NUMBER, pLevel VARCHAR, psTerm VARCHAR2)
      IS
         SELECT COUNT (M.SUB) MatRepro
            FROM (SELECT DISTINCT n.shrtckn_subj_code SUB,
                    n.shrtckn_crse_numb CRSE,
                    n.shrtckn_term_code TERM
                    FROM shrtckn n,
                    shrtckg g,
                    shrtckl l,
                    shrgrde r
            WHERE n.shrtckn_pidm = pnPidm--f_getpidm('00011955')
             AND (r.shrgrde_quality_points <=
                        (SELECT SWAVMRE_GRDE_MIN
                           FROM SWAVMRE
                          WHERE SWAVMRE_LEVL_CODE = pLevel))
              AND shrgrde_gpa_ind = 'Y'
              AND (n.shrtckn_repeat_course_ind IS NULL OR n.shrtckn_repeat_course_ind = 'I')
              AND NVL (g.shrtckg_credit_hours, 0) > 0
              AND shrgrde_passed_ind = 'N'
              AND l.shrtckl_levl_code = pLevel
              AND r.shrgrde_code <> 'OU'
                -------------------------------------MAC
              AND (SUBSTR (n.shrtckn_term_code, 5, 2) = DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
                     OR
                     SUBSTR (n.shrtckn_term_code, 5, 2) = DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75)
                    )
              AND SUBSTR (n.shrtckn_term_code, 1, 6) <= SUBSTR (psTerm, 1, 6)
              AND INSTR (r.shrgrde_code, ',') > 0
              AND g.shrtckg_pidm = n.shrtckn_pidm
              AND g.shrtckg_term_code = n.shrtckn_term_code
              AND g.shrtckg_tckn_seq_no = n.shrtckn_seq_no
              AND g.shrtckg_seq_no =
                       (SELECT MAX (g1.shrtckg_seq_no)
                          FROM shrtckg g1
                         WHERE     g1.shrtckg_pidm = g.shrtckg_pidm
                               AND g1.shrtckg_term_code = g.shrtckg_term_code
                               AND g1.shrtckg_tckn_seq_no = g.shrtckg_tckn_seq_no)
              AND l.shrtckl_pidm = n.shrtckn_pidm
              AND l.shrtckl_term_code = n.shrtckn_term_code
              AND l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
              AND r.shrgrde_code = g.shrtckg_grde_code_final
              AND r.shrgrde_levl_code = l.shrtckl_levl_code
            ) M
        HAVING COUNT (M.SUB) > 0;
--         

      --OPORTUNIDADES UTILIZADAS POR MATERIA ELEMENTO 4 
      CURSOR C_OPOR (
         pnPidm    NUMBER,
         psTerm    VARCHAR)
      IS
         select DISTINCT shrtckn_pidm, shrtckn_subj_code SUBJ, shrtckn_crse_numb CRSE
   ,        count(shrtckn_subj_code||shrtckn_crse_numb)  cuenta 
            from shrtckn n, shrtckl l
            where  n.shrtckn_pidm   = pnPidm
            AND l.shrtckl_pidm = n.shrtckn_pidm
            AND l.shrtckl_term_code = n.shrtckn_term_code
            AND l.shrtckl_tckn_seq_no = n.shrtckn_seq_no
            and n.shrtckn_term_code <= psTerm            
        group by shrtckn_pidm, shrtckn_subj_code , shrtckn_crse_numb 
        having count(shrtckn_subj_code||shrtckn_crse_numb) > 1
        order by 1; 
--           SELECT SUM (COUNT (SWVHIAC_CALIF)) MatOcup
--             FROM SWVHIAC A
--            WHERE     SWVHIAC_PIDM = pnPidm
--                  AND SWVHIAC_PASSED_IND = 'N'
--                  AND SWVHIAC_LEVL_CODE = pLevel
--                  --AND (   SWVHIAC_CALIF  = 'OU'
--                  --    OR
--                  --(
--                  AND SWVHIAC_QUALITY_POINTS <=
--                         (SELECT SWAVMRE_GRDE_MIN
--                            FROM SWAVMRE
--                           WHERE SWAVMRE_LEVL_CODE = pLevel--                                )
--                      )
--                  --)
--                  AND NVL (SWVHIAC_CREDIT_HOURS, 0) > 0
--                  AND INSTR (SWVHIAC_CALIF, ',') > 0
--                  AND (SUBSTR (SWVHIAC_TERM_CODE, 5, 2) =
--                          DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
--                       OR SUBSTR (SWVHIAC_TERM_CODE, 5, 2) =
--                             DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
--                  AND SUBSTR (SWVHIAC_TERM_CODE, 1, 6) <= SUBSTR (psTerm, 1, 6)
--                  AND NOT EXISTS
--                             (SELECT 1
--                                FROM SWVHIAC T
--                               WHERE T.SWVHIAC_PIDM = A.SWVHIAC_PIDM
--                                     AND T.SWVHIAC_LEVL_CODE =
--                                            A.SWVHIAC_LEVL_CODE
--                                     AND T.SWVHIAC_CRSE = A.SWVHIAC_CRSE
--                                     AND T.SWVHIAC_SUBJ = A.SWVHIAC_SUBJ
--                                     AND T.SWVHIAC_PASSED_IND = 'Y')
--         GROUP BY A.SWVHIAC_CRSE, A.SWVHIAC_SUBJ
--           HAVING COUNT (SWVHIAC_CALIF) > 1;

      ----- %  DE  AVANCE
      CURSOR C_AVANCE (
         pnPidm       NUMBER,
         pPrograma    VARCHAR,
         psTerm       VARCHAR,
         pCampus      VARCHAR,
         pLevel       VARCHAR)
      IS
             SELECT LPAD (
                       (CASE
                           WHEN (B.SMBPOGN_REQ_CREDITS_OVERALL > 0
                                 AND B.SMBPOGN_ACT_CREDITS_OVERALL > 0)
                           THEN
                              (CASE
                                  WHEN ROUND (
                                          (B.SMBPOGN_ACT_CREDITS_OVERALL * 100)
                                          / B.SMBPOGN_REQ_CREDITS_OVERALL) > 100
                                  THEN
                                     100
                                  ELSE
                                     ROUND (
                                        (B.SMBPOGN_ACT_CREDITS_OVERALL * 100)
                                        / B.SMBPOGN_REQ_CREDITS_OVERALL)
                               END)
                           ELSE
                              NULL
                        END),
                       3,
                       '0')
                       AVANCE
               FROM SMBPOGN B
              WHERE     SMBPOGN_LEVL_CODE = pLevel
                    AND SMBPOGN_PIDM = pnPidm
                    AND SMBPOGN_PROGRAM = pPrograma
                    AND NVL (SMBPOGN_CAMP_CODE, 'UFT') = pCampus
                    AND SMBPOGN_REQUEST_NO =
                           (SELECT MAX (Z.SMBPOGN_REQUEST_NO)
                              FROM SMBPOGN Z
                             WHERE     Z.SMBPOGN_PIDM = B.SMBPOGN_PIDM
                                   AND Z.SMBPOGN_PROGRAM = B.SMBPOGN_PROGRAM
                                   AND Z.SMBPOGN_LEVL_CODE = B.SMBPOGN_LEVL_CODE
                                   AND z.SMBPOGN_TERM_CODE_EFF =
                                          B.SMBPOGN_TERM_CODE_EFF);

--cursor calcula periodos consecutivos reprobados
      CURSOR C_REPPER (
         pnPidm    NUMBER,
         pLevel    VARCHAR,
         psTerm    VARCHAR2)
      IS
           
           SELECT shrtgpa_pidm, SHRTGPA_TERM_CODE, SHRTGPA_GPA
             FROM SHRTGPA
            WHERE     SHRTGPA_PIDM = pnPidm
                  AND SHRTGPA_LEVL_CODE = pLevel
                  AND ROUND (SHRTGPA_gpa, 2) < 4
                  AND (SHRTGPA_TERM_CODE = psTerm)
                      -- OR SHRTGPA_TERM_CODE = BANINST1.FWAPVNXT (psTerm, 'A'))
                  AND EXISTS
                         (SELECT 1
                            FROM SHRTCKN
                           WHERE SHRTCKN_PIDM = SHRTGPA_PIDM
                                 AND SHRTCKN_TERM_CODE = SHRTGPA_TERM_cODE)
         ORDER BY SHRTGPA_TERM_CODE;
         
       --MAC 0909
         CURSOR C_REPPER1 (
         pnPidm    NUMBER,
         pLevel    VARCHAR,
         psTerm    VARCHAR2)
      IS
           
           SELECT SHRTGPA_TERM_CODE, SHRTGPA_GPA
             FROM SHRTGPA
            WHERE     SHRTGPA_PIDM = pnPidm
                  AND SHRTGPA_LEVL_CODE = pLevel
                  AND SHRTGPA_TERM_CODE < psTerm
                  AND ROUND (SHRTGPA_gpa, 2) < 4
             AND EXISTS
                         (SELECT 1
                            FROM SHRTCKN
                           WHERE SHRTCKN_PIDM = SHRTGPA_PIDM
                                 AND SHRTCKN_TERM_CODE = SHRTGPA_TERM_cODE)
         ORDER BY SHRTGPA_TERM_CODE DESC;
         
   --_____________________________________
   --- ===== INICIA PROCESO ========
   BEGIN
      --BORRA LA TABLA DE PASO YA SEA PARA TODO EL PERIODO O POR ALUMNO
      IF pnPidm IS NULL THEN
          IF psLevel IS NULL THEN
             DELETE SWRCIRR
              --  WHERE SWRCIRR_TERM = psTerm; -- rcm 09 jun 2011
              WHERE (SUBSTR (SWRCIRR_TERM, 5, 2) =
                        DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
                     OR SUBSTR (SWRCIRR_TERM, 5, 2) =
                           DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
                    AND SUBSTR (SWRCIRR_TERM, 1, 4) <= SUBSTR (psTerm, 1, 4);
          ELSE
             DELETE SWRCIRR
              --WHERE SWRCIRR_TERM = psTerm  -- rcm 09 jun 2011
              WHERE (SUBSTR (SWRCIRR_TERM, 5, 2) =
                        DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
                     OR SUBSTR (SWRCIRR_TERM, 5, 2) =
                           DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
                    AND SUBSTR (SWRCIRR_TERM, 1, 4) <= SUBSTR (psTerm, 1, 4)
                    AND SWRCIRR_PIDM = PNPIDM
                    AND SWRCIRR_LEVL_CODE = psLevel;
          END IF;
      ELSE
           DELETE SWRCIRR
            --WHERE SWRCIRR_TERM = psTerm  -- rcm 09 jun 2011
            WHERE (SUBSTR (SWRCIRR_TERM, 5, 2) =
                      DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
                   OR SUBSTR (SWRCIRR_TERM, 5, 2) =
                         DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
                  AND SUBSTR (SWRCIRR_TERM, 1, 4) <= SUBSTR (psTerm, 1, 4)
                  AND SWRCIRR_PIDM = PNPIDM;
      END IF;

      COMMIT;

      --VALIDA LA SELECCION DEL USUARIO DESDE LA FORMA.
      SELECT INSTR (psAtributo, 'V'),
             INSTR (psAtributo, 'R'),
             INSTR (psAtributo, 'O'),
             INSTR (psAtributo, 'A'),
             INSTR (psAtributo, 'I'),
             INSTR (psAtributo, 'S'),
             INSTR (psAtributo, 'K'),
             INSTR (psAtributo, 'P')
        INTO vnIngles,
             vnRep,
             vnOcu,
             vnAvan,
             vnNivIn,
             vnSemestre,
             vnRanking,
             vnPerReprob
        FROM DUAL;

      -- inicializa el Rankeo
      vnQueRank := 0;
      vnValAnt := NULL;

------  AQUI BORRAMOS LA TABLA DE PASO DEL RANKING     M.D. VIC  22.DIC.2014
                delete from swbrank ;
                  commit;

       --------   aca manda ejecutar el nuevo proceso de ranking    vic..
           pwranking   (psTerm , psLevel );

      FOR regRep IN cuEstuduante (pnPidm, psTerm)
      LOOP
         ---____________________________________________________________
         --- SI EL USUARIO SELECCIONO VALIDAR EL NIVEL DE INGLES
         
            q_niv_ingles := ValidaIngles(regRep.stdnPidm);
         

         ---_______________________________________________________________
         --VALIDAR SI EL USUARIO PIDIO CALCULO DE SEMESTRE DESDE LA FORMA
         IF NVL (vnSemestre, 0) > 0
         THEN
            FOR i IN C_SEMESTRE (regRep.stdnPidm, regRep.stdnProg)
            LOOP
               q_semestre := LPAD (NVL (i.grupo, 0), 2, '0');
            END LOOP;

            IF (q_semestre = '00')
            THEN
               q_semestre := NULL;
            END IF;
         ELSE
            q_semestre := NULL;
         END IF;                                       --SELECCION DE SEMESTRE

         ---_________________________________________________________________________
         -- VALIDAR SI EL USUARIO PIDIO EL CALCULO DE MATERIAS REPRO. DESDE LA FORMA
         IF NVL (vnRep, 0) > 0
         THEN
            FOR j IN C_MATREPROB (regRep.stdnPidm, psLevel, psTerm)
            LOOP
            
                  q_mat_reprob := LPAD (j.MatRepro, 2, '0');
            END LOOP;
         ELSE
            q_mat_reprob := NULL;
         END IF;                                         --CALCULO DE OPORTUNIDADES

         ---____________________________________________________________________
         -- VALIDAR SI EL USUARIO PIDIO EL CALCULO OPORTUNIDADES DESDE LA FORMA
         vnOporOcup := 0;


            
            FOR m IN C_OPOR (regRep.stdnPidm, psTerm)
            LOOP
                   
            SELECT COUNT(1) INTO vnCuentaPer FROM SHRTCKN N, SHRTCKG G
                   WHERE G.SHRTCKG_PIDM = N.SHRTCKN_PIDM
                    AND G.SHRTCKG_TERM_CODE = N.SHRTCKN_TERM_CODE
                    AND G.SHRTCKG_TCKN_SEQ_NO = N.SHRTCKN_SEQ_NO
                    AND N.SHRTCKN_PIDM = regRep.stdnPidm
                    AND N.SHRTCKN_SUBJ_CODE = m.subj
                    AND N.SHRTCKN_CRSE_NUMB = m.crse
                    AND (G.SHRTCKG_GRDE_CODE_FINAL < '4,0' OR G.SHRTCKG_GRDE_CODE_FINAL = 'RE')
                    AND N.SHRTCKN_TERM_CODE = psTerm
                    AND G.SHRTCKG_SEQ_NO =
                      (SELECT MAX (G1.SHRTCKG_SEQ_NO)
                         FROM SHRTCKG G1
                        WHERE G1.SHRTCKG_PIDM = G.SHRTCKG_PIDM
                          AND G1.SHRTCKG_TERM_CODE = G.SHRTCKG_TERM_CODE
                          AND G1.SHRTCKG_TCKN_SEQ_NO = G.SHRTCKG_TCKN_SEQ_NO);
                          
                          
                        --  INSERT INTO PASO2
                          --VALUES (regRep.stdnPidm, m.subj,m.crse,psTerm);
             
                  IF vnCuentaPer >= 1 then 
                  
                  --  INSERT INTO PASO2
                         -- VALUES ('VARIABLE', vnCuentaPer, NULL, NULL);

                   q_oportunidad:= q_oportunidad+1;
                  -- INSERT INTO PASO2
                        --  VALUES ('opor', q_oportunidad, NULL, NULL);
                --END IF;   
               END IF; 
               --end if;
               
            END LOOP;

--            IF vnOporOcup >= 10
--            THEN
--               q_oportunidad := '10';
--            ELSE
               q_voportunidad:= q_oportunidad;
               q_voportunidad := LPAD (q_voportunidad, 2, '0');

               IF (q_voportunidad = '00')
               THEN
                  q_voportunidad := NULL;
               END IF;
--            END IF;                                   -- CALCULO DE OPORTUNIDADES

         ---____________________________________________________________
         --VALIDAR SI EL USUARIO PIDIO EL CALCULO %AVANCE DESDE LA FORMA
         IF NVL (vnAvan, 0) > 0
         THEN
            -- FOR w IN C_AVANCE(regRep.stdnPidm,regRep.stdnProg,psTerm,regRep.stdnCamp,psLevel) LOOP   -- rcm 09 jun 2011

            FOR w IN C_AVANCE (regRep.stdnPidm,
                               regRep.stdnProg,
                               psTerm,
                               regRep.stdnCamp,
                               psLevel)
            LOOP
               q_porc_avance := w.Avance;
            END LOOP;
         ELSE
            q_porc_avance := NULL;
         END IF;                                         --CALCULO DE % AVANCE

         ---____________________________________________________________
         --- Promedio de Calificaciones del Estudiante de sus Materias
         --- Para el Calculo del Proceso del Ranking
      
         
         --------   aca manda ejecutar el nuevo proceso de ranking    vic..
        --   pwranking   (psTerm , psLevel );
       
         select nvl(SWBRANK_RANKING,0) into vnRanking from swbrank
            WHERE SWBRANK_PIDM = regRep.stdnPidm
            AND SWBRANK_PERIODO = psTerm;
            
            vnRanking:= lpad(vnRanking,4,'0');
         
/*
         IF (NVL (vnRanking, 0) > 0)
         THEN
            vnValAct := regRep.PromPeriodo;

            IF (vnValAnt = vnValAct)
            THEN
               tabCierre (vnContador).rRanking := LPAD (vnQueRank, 4, '0');
            ELSE
               IF (vnValAct > 0)
               THEN
                  vnQueRank := vnQueRank + 1;
                  tabCierre (vnContador).rRanking := LPAD (vnQueRank, 4, '0');
               --                   ELSE
               --                      regRep.PromPeriodo := NULL;
               END IF;
            END IF;

            vnValAnt := regRep.PromPeriodo;
         END IF;

*/
         ---____________________________________________________________
         --- N¿mero de Periodos Consecutivos Reprobados < 4
         vnPerRepCons := 0;
         vsBanRep := 'N';
         vsTermA := NULL;

         IF (NVL (vnPerReprob, 0) > 0)
         THEN
            FOR reg_paso IN C_REPPER (regRep.stdnPidm, psLevel, psTerm)
            LOOP
               
            
               
               IF (reg_paso.SHRTGPA_GPA < 4)
               
               THEN
               vnPerRepCons := vnPerRepCons + 1;
               --MAC08/09/2014
               
               FOR reg_paso1 IN C_REPPER1 (regRep.stdnPidm, psLevel, psTerm) 
               LOOP
                IF reg_paso1.SHRTGPA_TERM_CODE = BANINST1.FWAPVNXT(psTerm,'A') THEN
                    vnPerRepCons := vnPerRepCons + 1;
                
                END IF;
               END LOOP;
               
               
               
--               SELECT SHRTGPA_GPA INTO vnPromAnt
--             FROM SHRTGPA 
--            WHERE     SHRTGPA_PIDM = regRep.stdnPidm
--                  AND SHRTGPA_LEVL_CODE = psLevel
--                  AND ROUND (SHRTGPA_gpa, 2) < 4
--                  AND (SHRTGPA_TERM_CODE = BANINST1.FWAPVNXT(reg_paso.SHRTGPA_TERM_CODE,'A'));
--               
--               
--                    IF vnPromAnt< 4 THEN
--                  vnPerRepCons := vnPerRepCons + 1;
--                    END IF;
               --END IF;
               END IF;
            -- IF   (reg_paso.SHRTGPA_GPA < 4 ) THEN
            --IF vnPerRepCons > 0 THEN
            --IF BANINST1.FWAPVNXT(reg_paso.SHRTGPA_TERM_CODE,'A')  = vsTermA THEN
            --vnPerRepCons  :=  vnPerRepCons +1;
            --vsBanRep      := 'S';
            --END IF;
            -- End IF;

            --BANINST1.FWAPVNXT('200925','S')
            --ELSE
            --IF (vnPerRepCons = 1 ) THEN vnPerRepCons := vnPerRepCons - 1; END IF;
            --END IF;

            --vsTermA :=reg_paso.SHRTGPA_TERM_CODE;
            END LOOP;
         ELSE
            vnPerRepCons := NULL;
         END IF;

         IF (vnPerRepCons = 0 AND vsBanRep = 'S')
         THEN
            vnPerRepCons := 1;
         END IF;

         IF (vnPerRepCons < 0)
         THEN
            vnPerRepCons := 0;
         END IF;

         vsPerRepCon := LPAD (vnPerRepCons, 2, '0');

         IF (vsPerRepCon = '00')
         THEN
            vsPerRepCon := NULL;
         END IF;

         ---____________________________________________________________
         --OBTIENE VALORES DEL RESTANTES DEL ESTUDIANTE PROCESADO
         BEGIN
            SELECT SPRIDEN_ID,
                   REPLACE (SPRIDEN_LAST_NAME, csAst, csEsp),
                   REPLACE (SPRIDEN_FIRST_NAME, csAst, csEsp)
              INTO vsId, vsLast, vsFirst
              FROM SPRIDEN
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = regRep.stdnPidm;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         ---__________________________________________________________________
         ---     INSERTA EN TEMPORAL , PARA CALCULOS  FALTANTES
         ---__________________________________________________________________
         tabCierre (vnContador).rPidm := regRep.stdnPidm;
         tabCierre (vnContador).rTerm := psTerm; -- psTerm; -- rcm 09 jun 2011
         tabCierre (vnContador).rCampus := regRep.stdnCamp;
         tabCierre (vnContador).rMatReprob := q_mat_reprob;
         tabCierre (vnContador).rOporAgot := q_voportunidad;
         tabCierre (vnContador).rNivIngl := q_niv_ingles;
         tabCierre (vnContador).rPorcAvance := q_porc_avance;
         tabCierre (vnContador).rSemestre := q_semestre;
         tabCierre (vnContador).rMajorCode := regRep.stdnMajr;
         tabCierre (vnContador).rLevlCode := psLevel;
         tabCierre (vnContador).rProgram := regRep.stdnProg;
         tabCierre (vnContador).rId := vsId;
         tabCierre (vnContador).rLastName := vsLast;
         tabCierre (vnContador).rFistName := vsFirst;
         tabCierre (vnContador).rSwarCode := psValIng;
         tabCierre (vnContador).rCalifProm := regRep.PromPeriodo;
         tabCierre(vnContador).rRanking     := vnRanking;
         tabCierre (vnContador).rPerReprob := vsPerRepCon;
         tabCierre (vnContador).rPorcPeriodo := vsPorcPeriodo;

         --- _________  LIMPIA   VARIABLES PARA PROCESO ___________
         q_niv_ingles := NULL;
         q_mat_reprob := NULL;
         q_oportunidad := 0;
         q_voportunidad:= NULL;
         q_porc_avance := NULL;
         q_semestre := NULL;
         i_NivInglesCrse := NULL;
         i_NivInglesTot := NULL;
         vnCalifProm := NULL;
         vnPerRepCons := 0;
         vsTermA := NULL;
         vnContador := vnContador + 1;
      END LOOP;

      --- _______________ *** INSERTA EN TABLA DE CIERRE LO PROCESADO *** ___________________
      FOR vnContador IN 1 .. tabCierre.COUNT
      LOOP
         BEGIN
            INSERT INTO SWRCIRR (SWRCIRR_PIDM,
                                 SWRCIRR_TERM,
                                 SWRCIRR_CAMPUS,
                                 SWRCIRR_MAT_REPROB,
                                 SWRCIRR_OPORT_AGOTADA,
                                 SWRCIRR_NIVEL_INGLES,
                                 SWRCIRR_PORC_AVANCE,
                                 SWRCIRR_SEMESTRE,
                                 SWRCIRR_MAJR_CODE,
                                 SWRCIRR_LEVL_CODE,
                                 SWRCIRR_PROGRAM,
                                 SWRCIRR_ID,
                                 SWRCIRR_LAST_NAME,
                                 SWRCIRR_FIRST_NAME,
                                 SWRCIRR_SWAR_CODE,
                                 SWRCIRR_RANKING,
                                 SWRCIRR_CALI_PROM,
                                 SWRCIRR_PER_REPR,
                                 SWRCIRR_PORC_PERIODO)
                 VALUES (tabCierre (vnContador).rPidm,
                         tabCierre (vnContador).rTerm,
                         tabCierre (vnContador).rCampus,
                         tabCierre (vnContador).rMatReprob,
                         tabCierre (vnContador).rOporAgot,
                         tabCierre (vnContador).rNivIngl,
                         tabCierre (vnContador).rPorcAvance,
                         tabCierre (vnContador).rSemestre,
                         tabCierre (vnContador).rMajorCode,
                         tabCierre (vnContador).rLevlCode,
                         tabCierre (vnContador).rProgram,
                         tabCierre (vnContador).rId,
                         tabCierre (vnContador).rLastName,
                         tabCierre (vnContador).rFistName,
                         tabCierre (vnContador).rSwarCode,
                         tabCierre (vnContador).rRanking,
                         tabCierre (vnContador).rCalifProm,
                         tabCierre (vnContador).rPerReprob,
                         tabCierre (vnContador).rPorcPeriodo);
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               vsError := SUBSTR (SQLERRM, 1, 500);

               INSERT INTO BITACORA_CISE (PERIODO,
                                          PIDM,
                                          CAMPUS,
                                          ERROR)
                    VALUES (tabCierre (vnContador).rTerm,
                            tabCierre (vnContador).rPidm,
                            'dSWRErr',
                            vsError);
            -- VALUES(psTerm,  tabCierre(vnContador).rPidm, 'dSWRErr', vsError);  -- rcm 09 jun 2011
            WHEN OTHERS
            THEN
               vsError := SUBSTR (SQLERRM, 1, 500);

               INSERT INTO BITACORA_CISE (PERIODO,
                                          PIDM,
                                          CAMPUS,
                                          ERROR)
                    VALUES (tabCierre (vnContador).rTerm,
                            tabCierre (vnContador).rPidm,
                            'oSWRErr',
                            vsError);
         --VALUES(psTerm,  tabCierre(vnContador).rPidm, 'oSWRErr', vsError);   -- rcm 09 jun 2011
         END;
      END LOOP;

      COMMIT;
   END tablaDePaso;

   PROCEDURE cierre (psTerm        VARCHAR2,
                     pnPidm        NUMBER DEFAULT NULL,
                     psLevl        VARCHAR2,
                     psAtributo    VARCHAR2,
                     psValIng      VARCHAR2)
   IS
      vsSemestre   VARCHAR2 (6) := NULL;
      vsNivelIng   VARCHAR2 (6) := NULL;
      vsMatRep     VARCHAR2 (6) := NULL;
      vsOpor       VARCHAR2 (6) := NULL;
      vsPorcAvan   VARCHAR2 (6) := NULL;
      vsError      VARCHAR (500) := NULL;
      vsRanking    VARCHAR2 (15) := NULL;
      vsPerRep     VARCHAR2 (15) := NULL;

      CURSOR cuCierre
      IS
         SELECT SWRCIRR_PIDM Pidm,
                SWRCIRR_TERM Term,
                SWRCIRR_CAMPUS Campus,
                (CASE
                    WHEN INSTR (psAtributo, 'S') > 0 THEN SWRCIRR_SEMESTRE
                    ELSE NULL
                 END)
                   Semestre,
                (CASE
                    WHEN INSTR (psAtributo, 'R') > 0 THEN SWRCIRR_MAT_REPROB
                    ELSE NULL
                 END)
                   MatRep,
                (CASE
                    WHEN INSTR (psAtributo, 'O') > 0
                    THEN
                       SWRCIRR_OPORT_AGOTADA
                    ELSE
                       NULL
                 END)
                   Opor,
                (CASE
                    WHEN INSTR (psAtributo, 'I') > 0
                    THEN
                       SWRCIRR_NIVEL_INGLES
                    ELSE
                       NULL
                 END)
                   NivIng,
                (CASE
                    WHEN INSTR (psAtributo, 'A') > 0 THEN SWRCIRR_PORC_AVANCE
                    ELSE NULL
                 END)
                   Porc,
                (CASE
                    WHEN INSTR (psAtributo, 'K') > 0 THEN SWRCIRR_RANKING
                    ELSE NULL
                 END)
                   Ranking,
                (CASE
                    WHEN INSTR (psAtributo, 'P') > 0 THEN SWRCIRR_PER_REPR
                    ELSE NULL
                 END)
                   PerReprob,
                Mat_aprobadas (SWRCIRR_TERM, SWRCIRR_PIDM, SWRCIRR_LEVL_CODE) Mat_AProb, -- rcm 15 jun 2011
                Mat_aprobadasGral (SWRCIRR_PIDM, SWRCIRR_TERM,SWRCIRR_LEVL_CODE) MatGral,
                Porcentaje_Mat_aprobadas(SWRCIRR_TERM,SWRCIRR_PIDM,SWRCIRR_LEVL_CODE) PorcPeriodo,
                Mat_inscritas (SWRCIRR_PIDM, SWRCIRR_TERM) MatIns
           FROM SWRCIRR
          --WHERE SWRCIRR_TERM = psTerm  -- rcm 15 jun 2011
          ------------------------------------------------------------------------------------------
          WHERE (SUBSTR (SWRCIRR_TERM, 5, 2) =
                    DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
                 OR SUBSTR (SWRCIRR_TERM, 5, 2) =
                       DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
                AND SUBSTR (SWRCIRR_TERM, 1, 4) <= SUBSTR (psTerm, 1, 4)
                ------------------------------------------------------------------------------------------
                AND (SWRCIRR_PIDM = pnPidm OR pnPidm IS NULL);
   BEGIN
      FOR regRep IN cuCierre
      LOOP
         vsNivelIng := regRep.NivIng;
         vsMatRep := regRep.MatRep;
         vsOpor := regRep.Opor;
         vsPorcAvan := regRep.Porc;
         vsSemestre := regRep.Semestre;
         vsRanking := regRep.Ranking;
         vsPerRep := regRep.PerReprob;

--INSERT INTO prueban values ('llego', 'inserto');

         BEGIN
            INSERT INTO SGBUSER (SGBUSER_PIDM,
                                 SGBUSER_TERM_CODE,
                                 SGBUSER_SUDA_CODE,
                                 SGBUSER_SUDB_CODE,
                                 SGBUSER_SUDC_CODE,
                                 SGBUSER_SUDD_CODE,
                                 SGBUSER_SUDE_CODE,
                                 SGBUSER_SUDF_CODE,
                                 SGBUSER_SUDG_CODE,
                                 SGBUSER_ACTIVITY_DATE,
                                 SGBUSER_SUDH_CODE,
                                 SGBUSER_SUDI_CODE,          -- promedio por periodo
                                 SGBUSER_SUDJ_CODE)        --- promedio general
                 VALUES (regRep.Pidm,
                         regRep.Term,
                         vsSemestre,
                         vsNivelIng,
                         vsMatRep,
                         vsOpor,
                         vsPorcAvan,
                         vsRanking,
                         vsPerRep,
                         SYSDATE,
                         REPLACE (regRep.Mat_AProb, ',', '.'),
                         REPLACE (regRep.PorcPeriodo, ',', '.'),
                         REPLACE (regRep.MatGral, ',', '.'));
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               BEGIN
                  UPDATE SGBUSER
                     SET SGBUSER_SUDA_CODE =
                            (CASE
                                WHEN INSTR (psAtributo, 'S') > 0
                                THEN
                                   vsSemestre
                                ELSE
                                   SGBUSER_SUDA_CODE
                             END),
                         SGBUSER_SUDB_CODE =
                            (CASE
                                WHEN INSTR (psAtributo, 'I') > 0
                                THEN
                                   vsNivelIng
                                ELSE
                                   SGBUSER_SUDB_CODE
                             END),
                         SGBUSER_SUDC_CODE =
                            (CASE
                                WHEN INSTR (psAtributo, 'R') > 0
                                THEN
                                   vsMatRep
                                ELSE
                                   SGBUSER_SUDC_CODE
                             END),
                         SGBUSER_SUDD_CODE =
                            (CASE
                                WHEN INSTR (psAtributo, 'O') > 0 THEN vsOpor
                                ELSE SGBUSER_SUDD_CODE
                             END),
                         SGBUSER_SUDE_CODE =
                            (CASE
                                WHEN INSTR (psAtributo, 'A') > 0
                                THEN
                                   vsPorcAvan
                                ELSE
                                   SGBUSER_SUDE_CODE
                             END),
                         SGBUSER_SUDF_CODE =
                            (CASE
                                WHEN INSTR (psAtributo, 'K') > 0
                                THEN
                                   vsRanking
                                ELSE
                                   SGBUSER_SUDF_CODE
                             END),
                         SGBUSER_SUDG_CODE =
                            (CASE
                                WHEN INSTR (psAtributo, 'P') > 0
                                THEN
                                   vsPerRep
                                ELSE
                                   SGBUSER_SUDG_CODE
                             END),
                         SGBUSER_SUDH_CODE =
                            REPLACE (regRep.Mat_AProb, ',', '.'), -- rcm 15 jun 2011
                         SGBUSER_SUDI_CODE =
                            REPLACE (regRep.PorcPeriodo, ',', '.'), -- rcm 15 jun 2011
                            SGBUSER_SUDj_CODE =
                            REPLACE (regRep.MatGral, ',', '.') -- rcm 15 jun 2011
                   WHERE SGBUSER_PIDM = regRep.Pidm
                         AND SGBUSER_TERM_CODE = regRep.Term;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vsError := SUBSTR (SQLERRM, 1, 500);
                    -- INSERT INTO PASO VALUES (regRep.PorcPeriodo,NULL,null);

                     INSERT INTO BITACORA_CISE (PERIODO,
                                                PIDM,
                                                CAMPUS,
                                                ERROR)
                          VALUES (regRep.PorcPeriodo,
                                  REPLACE (regRep.MatGral, ',', '.'),
                                  'upSGBUS',
                                  vsError);
               END;
            WHEN OTHERS
            THEN
               vsError := SUBSTR (SQLERRM, 1, 500);

               --INSERT INTO BITACORA_CISE(PERIODO,     PIDM,        CAMPUS, ERROR)
               --VALUES(regRep.Term, regRep.Pidm, 'inSGBUS',   vsError);

               INSERT INTO BITACORA_CISE (PERIODO,
                                          PIDM,
                                          CAMPUS,
                                          ERROR)
                    VALUES (REPLACE (regRep.Mat_AProb, ',', '.'),
                            REPLACE (regRep.MatGral, ',', '.'),
                            'upSGBUS',
                            vsError);
         --VALUES(regRep.Term, regRep.Pidm, 'inSGxxS',   regRep.Mat_AProb);

         END;

         vsSemestre := NULL;
         vsNivelIng := NULL;
         vsMatRep := NULL;
         vsOpor := NULL;
         vsPorcAvan := NULL;
         vsRanking := NULL;
         vsPerRep := NULL;

--         IF INSTR (psAtributo, 'V') > 0
--         THEN
--            validaIngles (regRep.Pidm,
--                          psTerm,
--                          psLevl,
--                          psValIng);
--         END IF;
      END LOOP;

      COMMIT;
   END cierre;

   PROCEDURE validaIngles (pnPidm      NUMBER,
                           psTerm      VARCHAR2,
                           psLevl      VARCHAR2,
                           psValIng    VARCHAR2)
   IS
      vsValidacion   VARCHAR2 (2) := NULL;
      csN   CONSTANT VARCHAR2 (1) := 'N';
      csU   CONSTANT VARCHAR2 (1) := 'U';

      CURSOR cuRegistro
      IS
         SELECT SGBUSER_SUDB_CODE Ingles,
                NVL (TO_NUMBER (SGBUSER_SUDE_CODE), 0) Avance
           FROM SGBUSER
          WHERE SGBUSER_TERM_CODE = psTerm AND SGBUSER_PIDM = pnPidm;
   BEGIN
      ---  Obtiene el Valor del Standard Academico
      FOR regReg IN cuRegistro
      LOOP
       --  vsValidacion := ValidaIngles (regReg.Ingles, regReg.Avance, psValIng);
       vsValidacion := null;
      END LOOP;

      INSERT INTO BITACORA_CISE (PERIODO,
                                 PIDM,
                                 CAMPUS,
                                 ERROR)
           VALUES (psTerm,
                   pnPidm,
                   'ValiIng',
                   vsValidacion);

      -- Si se Encontro Estandard Acad¿mico
      IF vsValidacion IS NOT NULL
      THEN
         BEGIN
            INSERT INTO SHRTTRM (SHRTTRM_PIDM,
                                 SHRTTRM_TERM_CODE,
                                 SHRTTRM_UPDATE_SOURCE_IND,
                                 SHRTTRM_RECORD_STATUS_IND,
                                 SHRTTRM_RECORD_STATUS_DATE,
                                 SHRTTRM_ACTIVITY_DATE,
                                 SHRTTRM_ASTD_CODE_END_OF_TERM,
                                 SHRTTRM_PRE_CATALOG_IND)
                 VALUES (pnPidm,
                         psTerm,
                         csU,
                         csN,
                         SYSDATE,
                         SYSDATE,
                         vsValidacion,
                         csN);
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               UPDATE SHRTTRM
                  SET SHRTTRM_ASTD_CODE_END_OF_TERM = vsValidacion,
                      SHRTTRM_ACTIVITY_DATE = SYSDATE,
                      SHRTTRM_PRE_CATALOG_IND = csN
                WHERE SHRTTRM_PIDM = pnPidm AND SHRTTRM_TERM_CODE = psTerm;
         END;
      END IF;

      COMMIT;
   END validaIngles;



   PROCEDURE Proceso (psTerm         VARCHAR2,
                      psMode         VARCHAR2,
                      pnPidm         NUMBER DEFAULT NULL,
                      psLevl         VARCHAR2,
                      psAtributo     VARCHAR2,
                      psTipo         VARCHAR2 DEFAULT NULL,
                      psCondicion    VARCHAR2 DEFAULT NULL,
                      psValIng       VARCHAR2)
   IS
      psDesc   VARCHAR2 (50) := 'Cierre de semestre';
   BEGIN



---- BORRA LAS TABLAS DE PASO  vic..
 p_borratblbaja ;
-------EJECUTA EL NEW PROC PARA SEPARAR LAS CARRERAS  vic..
    splitchain(psCondicion);


      tablaDePaso (psTerm,
                   pnPidm,
                   psLevl,
                   psAtributo,
                   psTipo,
                   psCondicion,
                   psValIng);


      IF psMode = 'U'
      THEN                                                       --MODO INSERT
      
      
         cierre (psTerm,
                 pnPidm,
                 psLevl,
                 psAtributo,
                 psValIng);
      END IF;
   END Proceso;


   PROCEDURE reporte (psReclDesc    VARCHAR2,
                      psTerm        VARCHAR2,
                      pnPidm        NUMBER DEFAULT NULL,
                      psLevl        VARCHAR2,
                      psAtributo    VARCHAR2,
                      psValIng      VARCHAR2)
   IS
      vnExists              INTEGER := 0;
      tabColumna            Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
      vsValIngles           VARCHAR2 (10) := NULL;
      vsSemestre            VARCHAR2 (6) := NULL;
      vsNivelIng            VARCHAR2 (6) := NULL;
      vsMatRep              VARCHAR2 (6) := NULL;
      vsOpor                VARCHAR2 (6) := NULL;
      vsPorcAvan            VARCHAR2 (6) := NULL;
      vsInicoPag            VARCHAR2 (20) := NULL;
      vsTooltip             VARCHAR2 (2000) := NULL;
      vnIngles              NUMBER := 0;
      vnRep                 NUMBER := 0;
      vnOcu                 NUMBER := 0;
      vnAvan                NUMBER := 0;
      vnNivIn               NUMBER := 0;
      vnSemestre            NUMBER := 0;
      vsAvanzado            VARCHAR (2) := NULL;
      vnTotAvan             NUMBER := 0;
      vnRanking             varchar2(5) := NULL;
      vnPerReprob           NUMBER := NULL;
      vnCalifProm           NUMBER (5, 2) := NULL;
      vsRut                 VARCHAR2 (20) := NULL;
      vsTermAdm             VARCHAR2 (8) := NULL;
      vsBeca                VARCHAR2 (1) := NULL;
      vnBeca                NUMBER := 0;
      cnColumnas   CONSTANT INTEGER := 19;           -- 17; -- rcm 15 jun 2011
      csCampus     CONSTANT VARCHAR2 (6) := F_CONTEXTO ();


      CURSOR C_ESTUD
      IS
           SELECT SWRCIRR_PIDM AS pidms,
                  SWRCIRR_ID AS Id,
                  SWRCIRR_LAST_NAME || ' ' || SWRCIRR_FIRST_NAME AS Nombre,
                  SWRCIRR_MAJR_CODE AS Majr,
                  SWRCIRR_LEVL_CODE AS Nivel,
                  Pk_catalogo.Programa (SWRCIRR_PROGRAM) AS descripcion,
                  SWRCIRR_PROGRAM AS Programa,
                  SWRCIRR_CAMPUS AS Campus,
                  NVL (SWRCIRR_MAT_REPROB, 0) AS Matrep,
                  DECODE (SWRCIRR_MAT_REPROB,
                          15, '15 o mas',
                          LPAD (SWRCIRR_MAT_REPROB, 2, 0))
                     AS MatrepDesc,
                  NVL (SWRCIRR_OPORT_AGOTADA, 0) AS OporAgo,
                  DECODE (SWRCIRR_OPORT_AGOTADA,
                          '10', '10 o mas',
                          LPAD (SWRCIRR_OPORT_AGOTADA, 2, 0))
                     AS OporAgoDesc,
                  NVL (SWRCIRR_NIVEL_INGLES, 0) AS NivIngles,
                  NVL (SWRCIRR_PORC_AVANCE, 0) AS PorcAvan,
                  NVL (SWRCIRR_SEMESTRE, 0) AS Semestre,
                  (CASE
                      WHEN TO_NUMBER (SWRCIRR_MAT_REPROB) >= 5 THEN 'S'
                      WHEN TO_NUMBER (SWRCIRR_OPORT_AGOTADA) >= 4 THEN 'S'
                      ELSE 'N'
                   END)
                     AS Baja,
                  NVL (SWRCIRR_RANKING, 0) AS Ranking,
                  NVL (SWRCIRR_PER_REPR, 0) AS PerReprob,
                  NVL (SWRCIRR_CALI_PROM, 0) AS CalifProm,
                  SWRCIRR_TERM termz,
                  NVL (Mat_aprobadas (SWRCIRR_TERM, SWRCIRR_PIDM, SWRCIRR_LEVL_CODE), 0)
                     AS MatAProb,
                  NVL (
                     TRUNC (Mat_aprobadasGral (SWRCIRR_PIDM, SWRCIRR_TERM,SWRCIRR_LEVL_CODE ), 1),
                     0)
                     AS MatGral,
                  NVL (Mat_Inscritas (SWRCIRR_TERM, SWRCIRR_PIDM), 0) AS MatIns
             FROM SWRCIRR
            WHERE SWRCIRR_TERM        = psTerm  -- rcm 09 junio 2011
            ------------------------------------------------------------------------------------------  se regreso a la forma anterior x odrnes de marce 21.07.2014
       /*     WHERE (SUBSTR (SWRCIRR_TERM, 5, 2) =
                      DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 25)
                   OR SUBSTR (SWRCIRR_TERM, 5, 2) =
                         DECODE (SUBSTR (psTerm, 5, 2), 10, 10, 75))
                  AND SUBSTR (SWRCIRR_TERM, 1, 4) <= SUBSTR (psTerm, 1, 4)   */
                  ------------------------------------------------------------------------------------------
                  AND (SWRCIRR_PIDM = pnPidm OR pnPidm IS NULL)
                     AND (SWRCIRR_LEVL_CODE = psLevl OR psLevl IS NULL)
                and swrcirr_majr_code in  (select valor2 from swrpaso where valor1 = 'kwacierre'  )  ---aqui toma solo los valores que tiene la tabla de paso  vic...
         ORDER BY SWRCIRR_MAJR_CODE, SWRCIRR_LEVL_CODE, SWRCIRR_PROGRAM;


      PROCEDURE p_acceso
      IS
      BEGIN
         /* Check/update the user's web session */
         IF Pk_Login.F_ValidacionDeAcceso (pk_login.vgsUSR)
         THEN
            RETURN;
         END IF;
      END p_acceso;
   BEGIN

--      htp.p('<br>');
--psReclDesc
--psTerm,
--pnPidm,
--psLevl,
--psAtributo,
--psValIng
--
--
--
--
--   htp.p('<br>');
--
         htp.p('<script language="javascript" src="kwatime.js"></script>');
      FOR vnI IN 1 .. cnColumnas
      LOOP
         tabColumna.EXTEND (vnI);
         tabColumna (vnI) := NULL;
      END LOOP;

      tabColumna (1) := 'Carrera';
      tabColumna (2) := 'Malla';
      tabColumna (3) := 'Periodo de Admisión';
      tabColumna (4) := 'Descripción de Carrera';
      tabColumna (5) := 'RUT';
      tabColumna (6) := 'ID';
      tabColumna (7) := 'Nombre';
      tabColumna (8) := 'Nivel Ingles Acreditado';
      tabColumna (9) := 'Ramos Reprobados en la historia académica';
      tabColumna (10) := 'Oportunidades utilizadas en la historia académica';
      tabColumna (11) := '% Avance respecto a los créditos totales';
      tabColumna (12) := 'Ultimo Semestre o año completo acreditado';
      tabColumna (13) := 'Ranking';
      tabColumna (14) := 'Periodos Consecutivos reprobados';
      tabColumna (15) := 'Promedio del Periodo actual';
      tabColumna (16) := 'Asignaturas Acreditadas en el periodo actual';
      tabColumna (17) := 'Asignaturas Inscritas en el periodo';
      tabColumna (18) :=
         '% Asignaturas acreditados acumulados en el historial';
      tabColumna (19) := 'Beca';

      BEGIN
         SELECT INSTR (psAtributo, 'V'),
                INSTR (psAtributo, 'R'),
                INSTR (psAtributo, 'O'),
                INSTR (psAtributo, 'A'),
                INSTR (psAtributo, 'I'),
                INSTR (psAtributo, 'S'),
                INSTR (psAtributo, 'K'),
                INSTR (psAtributo, 'P')
           INTO vnIngles,
                vnRep,
                vnOcu,
                vnAvan,
                vnNivIn,
                vnSemestre,
                vnRanking,
                vnPerReprob
           FROM DUAL;
      END;

      FOR regRep IN C_ESTUD
      LOOP
         IF vnExists = 0
         THEN
            Pk_Sisrepimp.
             P_EncabezadoDeReporte (
               psReclDesc,
               cnColumnas,
               tabColumna,
               vsInicoPag,
               '1',
               psSubtitulo     => 'Periodo ' || psTerm,
               psUsuario       => pk_login.vgsUSR,
               psSeccion       => '3',
               psUniversidad   => pk_Catalogo.universidad (csCampus));
            vsInicoPag := 'SALTO';
         END IF;

         BEGIN
            SELECT SHRTTRM_ASTD_CODE_END_OF_TERM
              INTO vsValIngles
              FROM SHRTTRM
             WHERE SHRTTRM_PIDM = regRep.pidms
                   AND SHRTTRM_TERM_CODE = regRep.termz; -- psTerm;  -- rcm 10 jun 2011
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         BEGIN
            -- OBTIENE PERIODO DE ADMISION
            SELECT A.SGBSTDN_TERM_CODE_ADMIT
              INTO vsTermAdm
              FROM SGBSTDN A
             WHERE A.SGBSTDN_PIDM = regRep.pidms
                   AND A.SGBSTDN_TERM_CODE_EFF =
                          (SELECT MAX (B.SGBSTDN_TERM_CODE_EFF)
                             FROM SGBSTDN B
                            WHERE A.SGBSTDN_PIDM = B.SGBSTDN_PIDM);
         EXCEPTION
            WHEN OTHERS
            THEN
               vsTermAdm := NULL;
         END;

         --- OBTIENE VALOR DE PERS_SUFIX
         BEGIN
            SELECT SPBPERS_NAME_SUFFIX
              INTO vsRut
              FROM SPBPERS
             WHERE SPBPERS_PIDM = regRep.pidms;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               vsRut := NULL;
         END;

         BEGIN
            -- DETERMINA SI TIENE BECA
            SELECT COUNT (1)
              INTO vnBeca
              FROM TBBESTU
             WHERE TBBESTU_PIDM = regRep.pidms
                   AND SUBSTR(TBBESTU_TERM_CODE,1,4) = SUBSTR(regRep.termz,1,4);

            IF vnBeca > 0
            THEN
               vsBeca := 'X';
            ELSE
               vsBeca := ' ';
            END IF;
         END;


         --MCC 03/08/2007 CAMBIO PARA SOLO VALIDAR LO QUE EL USUARIO MANDA EN LA FORMA
         IF NVL (vnNivIn, 0) > 0
         THEN
            vsNivelIng := regRep.NivIngles;
         END IF;

         IF NVL (vnRep, 0) > 0
         THEN
            vsMatRep := regRep.Matrep;
         END IF;

         IF NVL (vnOcu, 0) > 0
         THEN
            vsOpor := regRep.OporAgo;
         END IF;

         IF NVL (vnAvan, 0) > 0
         THEN
            vsPorcAvan := regRep.PorcAvan;
         END IF;

         IF NVL (vnSemestre, 0) > 0
         THEN
            vsSemestre := regRep.semestre;
         END IF;

         IF NVL (vnRanking, 0) > 0
         THEN
            vnRanking := regRep.Ranking;
         END IF;

         IF NVL (vnPerReprob, 0) > 0
         THEN
            vnPerReprob := regRep.PerReprob;
         END IF;


         -- Si es Avanzado o Principiante
         vsAvanzado := FWATYAL (regRep.pidms, regRep.Campus, regRep.termz); -- psTerm); -- rcm 10 jun 2011

         --IF vsAvanzado  = 'A' then  -- esto es necesario  rcm 10 jun 2011

         --************************************************************************************************************

         HTP.
          p (
               '<tr>'
            || '<td valign="top">'
            || RegRep.Majr
            || '</td>'
            || '<td valign="top">'
            || regRep.Programa
            || '</td>'
            || '<td valign="top">'
            || vsTermAdm
            || '</td>'
            || '<td valign="top">'
            || regRep.descripcion
            || '</td>'
            || '<td valign="top">'
            || vsRut
            || '</td>'
            || '<td valign="top">'
            || regRep.ID
            || '</td>'
            || '<td valign="top">'
            || regRep.Nombre
            || '</td>'
            || '<td valign="top">'
            || vsNivelIng
            || '</td>');


         --********************************** rcm 14 jul 2011 incorporacion de tooltip  SUBJ y CRSE
         --****************************************************************************************

         HTP.
          p (
            '<td valign="top"><a  href="#" ><font title="Informacion de SUB y CRSE y PERIODO');

         --P_DetToolTip (pnPidm NUMBER, psLevel VARCHAR, psTerm VARCHAR2);
         P_DetToolTip (regRep.pidms, regRep.Nivel, psTerm);

         HTP.p ('">' || vsMatRep || '</font></a></td>');

         --****************************************************************************************
         --****************************************************************************************
         HTP.
          p (
            '<td valign="top"><a  href="#" ><font title="Informacion de SUB y CRSE y PERIODO');
         P_DetToolTipA (regRep.pidms, psTerm);
         HTP.p ('">' || vsOpor || '</font></a></td>');


         HTP.
          P (
               '<td valign="top">'
            || vsPorcAvan
            || '</td>'
            || '<td valign="top">'
            || vsSemestre
            || '</td>'
            || '<td valign="top">'
            || regRep.Ranking
            || '</td>'
            || '<td valign="top">'
            || regRep.PerReprob
            || '</td>'
            || '<td valign="top">'
            || regRep.CalifProm
            || '</td>'
            || '<td valign="top">'
            || regRep.MatAProb
            || '</td>'
            || '<td valign="top">'
            || regRep.MatIns
            || '</td>'
            || '<td valign="top">'
            || regRep.MatGral
            || '</td>'
            || '<td valign="top">'
            || vsBeca
            || '</td>'
            || '</tr>');

         vnExists := 1;
         vsValIngles := NULL;
         --END IF;

         vnExists := 1;
      END LOOP;



      IF vnExists = 0
      THEN
         HTP.
          p (
               '<tr><th colspan="'
            || cnColumnas
            || '"><font color="#ff0000">'
            || Pk_Sisrepimp.vgsResultado
            || '</font></th></tr>');
      ELSE
         -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de pagina para impresion
         Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

         -- es omitido el encabezado del reporte pero se agrega el salto de pagina
         Pk_Sisrepimp.P_EncabezadoDeReporte (psReclDesc,
                                             cnColumnas,
                                             tabColumna,
                                             'PIE',
                                             '0',
                                             psUsuario   => pk_login.vgsUSR,
                                             psSeccion   => '3');

      -- rcm 13 jul 2011
      /*
       htp.p('</table>');
       htp.p('<script language="JavaScript"><!--');

       htp.p('function fIniciarVentana(){
       frmLOVcur = window.open("","winCursos","toolbar=no,menubar=no,directories=no,status=no,resizable=no,location=no,scrollbars=no,width=0,height=0");

       frmLOVcur.resizeTo(10,10)
       frmLOVcur.moveTo(0,0);

       if (frmLOVcur.opener == null) {
       frmLOVcur.opener = self;
       }

       frmLOVcur.close();
       }');

       htp.p('
       function fMuestraDiv(psInicio, psFin, psHrI, psHrF, psDias, psNombre, psSubj, psCrseNum, psTit, psLista, psTipoLista, psCollDesc){

       document.frmInforma.psInicio.value = "hola";
       document.frmInforma.psFin.value = psFin;
       document.frmInforma.psHrI.value = psHrI;
       document.frmInforma.psHrF.value = psHrF;
       document.frmInforma.psDias.value = psDias;
       document.frmInforma.psNombre.value = psNombre;
       document.frmInforma.psCollDesc.value = psCollDesc;
       document.frmInforma.psSubj.value = psSubj;
       document.frmInforma.psCrseNum.value = psCrseNum;
       document.frmInforma.psTit.value = psTit;
       document.frmInforma.psLista.value = psLista;
       document.frmInforma.psTipoLista.value = psTipoLista;

       frmLOVcur.close();

       frmLOVcur = window.open("","winCursos","toolbar=no,menubar=no,directories=no,status=no,resizable=no,location=no,scrollbars=no,screenX=0,screenY=0,width=300,height=300");

       if (frmLOVcur.opener == null) {
       frmLOVcur.opener = self;
       }

       window.status = "";
       frmLOVcur.moveTo(0,0);

       // establece el tiempo en que estará activo el "tooltip" con información del crn:
       setTimeout("fMuestraInf()",10000);

       }');

       -- despliega la información de ayuda del crn:
       htp.p('function fMuestraInf() {
       document.frmInforma.submit();
       }

       fIniciarVentana();
       ');

       htp.p('//--></script>');

       htp.p('<form name="frmInforma" action="#" method="post" target="winCursos">
       <input type="hidden" name="psReclDesc" value="'||psReclDesc||'" />
       <input type="hidden" name="psInicio" />
       <input type="hidden" name="psFin" />
           <input type="hidden" name="psHrI" />
       <input type="hidden" name="psHrF" />
       <input type="hidden" name="psDias" />
       <input type="hidden" name="psNombre" />
       <input type="hidden" name="psCollDesc" />
       <input type="hidden" name="psSubj" />
       <input type="hidden" name="psCrseNum" />
       <input type="hidden" name="psTit" />
       <input type="hidden" name="psLista" />
       <input type="hidden" name="psTipoLista" />
       <input type="hidden" name="psDetalle" value="X" />
       </form>
       </body></html>');

          */



      END IF;

      HTP.p ('</table><br/></body></html>');
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM);
   END reporte;


   PROCEDURE Menu_Reporte (psReclDesc    VARCHAR2)    IS

      vnExists              INTEGER := 0;
      tabColumna            Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
      vsValIngles           VARCHAR2 (10) := NULL;
      vsSemestre            VARCHAR2 (6) := NULL;
      vsNivelIng            VARCHAR2 (6) := NULL;
      vsMatRep              VARCHAR2 (6) := NULL;
      vsOpor                VARCHAR2 (6) := NULL;
      vsPorcAvan            VARCHAR2 (6) := NULL;
      vsInicoPag            VARCHAR2 (20) := NULL;
      vsTooltip             VARCHAR2 (2000) := NULL;
      vnIngles              NUMBER := 0;
      vnRep                 NUMBER := 0;
      vnOcu                 NUMBER := 0;
      vnAvan                NUMBER := 0;
      vnNivIn               NUMBER := 0;
      vnSemestre            NUMBER := 0;
      vsAvanzado            VARCHAR (2) := NULL;
      vnTotAvan             NUMBER := 0;
      vnRanking             VARCHAR2(5);
      vnPerReprob           NUMBER := NULL;
      vnCalifProm           NUMBER (5, 2) := NULL;
      vsRut                 VARCHAR2 (20) := NULL;
      vsTermAdm             VARCHAR2 (8) := NULL;
      vsBeca                VARCHAR2 (1) := NULL;
      vnBeca                NUMBER := 0;
      vsPerio               VARCHAR2(20) := NULL;
      vsProgr               VARCHAR2(20) := NULL;

      cnColumnas   CONSTANT INTEGER := 19;           -- 17; -- rcm 15 jun 2011
      csCampus     CONSTANT VARCHAR2 (6) := F_CONTEXTO ();
      csEsp        CONSTANT VARCHAR2 (1) := ' ';
      csS          CONSTANT VARCHAR2 (1) := 'S';
      csN          CONSTANT VARCHAR2 (1) := 'N';
      cs15         CONSTANT VARCHAR2 (8) := '15 o mas';
      cs10         CONSTANT VARCHAR2 (8) := '10 o mas';
      csAtributo   CONSTANT VARCHAR2 (8) := 'IAROVSKP';
      csV          CONSTANT VARCHAR2 (1) := 'V';
      csR          CONSTANT VARCHAR2 (1) := 'R';
      csO          CONSTANT VARCHAR2 (1) := 'O';
      csA          CONSTANT VARCHAR2 (1) := 'A';
      csI          CONSTANT VARCHAR2 (1) := 'I';
      csK          CONSTANT VARCHAR2 (1) := 'K';
      csP          CONSTANT VARCHAR2 (1) := 'P';
      cs1          CONSTANT VARCHAR2 (1) := '1';
      cs3          CONSTANT VARCHAR2 (1) := '3';



      cn0          CONSTANT NUMBER := 0;
      cn1          CONSTANT NUMBER := 1;
      cn2          CONSTANT NUMBER := 2;
      cn4          CONSTANT NUMBER := 4;
      cn5          CONSTANT NUMBER := 5;
      cn10         CONSTANT NUMBER := 10;
      cn15         CONSTANT NUMBER := 15;
      cn25         CONSTANT NUMBER := 25;
      cn75         CONSTANT NUMBER := 75;

      CURSOR C_ESTUD(vsPeriodo VARCHAR2,vsPrograma VARCHAR2)
      IS
           SELECT SWRCIRR_PIDM            AS pidms,
                  SWRCIRR_ID              AS Id,
                  SWRCIRR_LAST_NAME ||
                  csEsp ||
                  SWRCIRR_FIRST_NAME      AS Nombre,
                  SWRCIRR_MAJR_CODE       AS Majr,
                  SWRCIRR_LEVL_CODE       AS Nivel,
                  Pk_catalogo.Programa (SWRCIRR_PROGRAM) AS descripcion,
                  SWRCIRR_PROGRAM         AS Programa,
                  SWRCIRR_CAMPUS          AS Campus,
                  NVL (SWRCIRR_MAT_REPROB,
                        cn0)              AS Matrep,
                  DECODE (SWRCIRR_MAT_REPROB,
                          cn15, cs15,
                          LPAD (SWRCIRR_MAT_REPROB, cn2, cn0))
                                          AS MatrepDesc,
                  NVL (SWRCIRR_OPORT_AGOTADA, cn0) AS OporAgo,
                  DECODE (SWRCIRR_OPORT_AGOTADA,
                          cn10, cs10,
                          LPAD (SWRCIRR_OPORT_AGOTADA, cn2, cn0))
                                          AS OporAgoDesc,
                  NVL (SWRCIRR_NIVEL_INGLES, cn0)  AS NivIngles,
                  NVL (SWRCIRR_PORC_AVANCE, cn0)   AS PorcAvan,
                  NVL (SWRCIRR_SEMESTRE, cn0)      AS Semestre,
                  (CASE
                      WHEN TO_NUMBER (SWRCIRR_MAT_REPROB) >= cn5 THEN csS
                      WHEN TO_NUMBER (SWRCIRR_OPORT_AGOTADA) >= cn4 THEN csS
                      ELSE csN
                   END)
                     AS Baja,
                  NVL (SWRCIRR_RANKING, cn0)   AS Ranking,
                  NVL (SWRCIRR_PER_REPR, cn0)  AS PerReprob,
                  NVL (SWRCIRR_CALI_PROM, cn0) AS CalifProm,
                  SWRCIRR_TERM termz,
                  NVL (Mat_aprobadas (SWRCIRR_TERM, SWRCIRR_PIDM, SWRCIRR_LEVL_CODE), cn0)
                     AS MatAProb,
                  NVL (
                     TRUNC (Mat_aprobadasGral (SWRCIRR_PIDM, SWRCIRR_TERM,SWRCIRR_LEVL_CODE), cn1),
                     cn0)
                     AS MatGral,
                  NVL (Mat_Inscritas (SWRCIRR_TERM, SWRCIRR_PIDM), 0) AS MatIns
             FROM SWRCIRR
            WHERE (SUBSTR (SWRCIRR_TERM, cn5, cn2) =
                      DECODE (SUBSTR (vsPeriodo, cn5, cn2), cn10, cn10, cn25)
                   OR SUBSTR (SWRCIRR_TERM, cn5, cn2) =
                         DECODE (SUBSTR (vsPeriodo, cn5, cn2), cn10, cn10, cn75))
                  AND SUBSTR (SWRCIRR_TERM, cn1, cn4) <= SUBSTR (vsPeriodo, cn1, cn4)
                  AND (SWRCIRR_PROGRAM = vsPrograma OR vsPrograma IS NULL)
         ORDER BY SWRCIRR_MAJR_CODE, SWRCIRR_LEVL_CODE, SWRCIRR_PROGRAM;

   BEGIN
      IF PK_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      vsPerio   := pk_ObjHtml.getValueCookie('psPerio');
      vsProgr   := pk_ObjHtml.getValueCookie('psProgr');


    tablaDePaso (vsPerio, NULL, 'LI',
                 'IAROVSKP', NULL, NULL,
                 NULL);

--    tablaDePaso (vsPerio, NULL, 'LC',
--                 'IAROVSKP', NULL, NULL,
--                 NULL);

      FOR vnI IN 1 .. cnColumnas
      LOOP
         tabColumna.EXTEND (vnI);
         tabColumna (vnI) := NULL;
      END LOOP;

      tabColumna (1) := 'Carrera';
      tabColumna (2) := 'Malla';
      tabColumna (3) := 'Periodo de Admisi;n';
      tabColumna (4) := 'Descripci;n de Carrera';
      tabColumna (5) := 'RUT';
      tabColumna (6) := 'ID';
      tabColumna (7) := 'Nombre';
      tabColumna (8) := 'Nivel Ingles Acreditado';
      tabColumna (9) := 'Ramos Reprobados en la historia acad;mica';
      tabColumna (10) :='Oportunidades utilizadas en la historia acad;mica';
      tabColumna (11) := '% Avance respecto a los cr;ditos totales';
      tabColumna (12) := ';ltimo Semestre o año completo acreditado';
      tabColumna (13) := 'Ranking';
      tabColumna (14) := 'Periodos Consecutivos reprobados';
      tabColumna (15) := 'Promedio del Periodo actual';
      tabColumna (16) := 'Asignaturas Acreditadas en el periodo actual';
      tabColumna (17) := 'Asignaturas Inscritas en el periodo';
      tabColumna (18) :='% Asignaturas acreditados acumulados en el historial';
      tabColumna (19) := 'Beca';

      BEGIN
         SELECT INSTR (csAtributo, csV),
                INSTR (csAtributo, csR),
                INSTR (csAtributo, csO),
                INSTR (csAtributo, csA),
                INSTR (csAtributo, csI),
                INSTR (csAtributo, csS),
                INSTR (csAtributo, csK),
                INSTR (csAtributo, csP)
           INTO vnIngles,
                vnRep,
                vnOcu,
                vnAvan,
                vnNivIn,
                vnSemestre,
                vnRanking,
                vnPerReprob
           FROM DUAL;
      END;

      FOR regRep IN C_ESTUD(vsPerio,vsProgr)
      LOOP
         IF vnExists = 0
         THEN
            Pk_Sisrepimp.
             P_EncabezadoDeReporte (
               psReclDesc,
               cnColumnas,
               tabColumna,
               vsInicoPag,
               cs1,
               psSubtitulo     => 'Periodo ' || vsPerio,
               psUsuario       => pk_login.vgsUSR,
               psSeccion       => cs3,
               psUniversidad   => pk_Catalogo.universidad (csCampus));
            vsInicoPag := 'SALTO';
         END IF;

         BEGIN
            SELECT SHRTTRM_ASTD_CODE_END_OF_TERM
              INTO vsValIngles
              FROM SHRTTRM
             WHERE SHRTTRM_PIDM = regRep.pidms
                   AND SHRTTRM_TERM_CODE = regRep.termz; -- vsPerio;  -- rcm 10 jun 2011
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         BEGIN
            -- OBTIENE PERIODO DE ADMISION
            SELECT A.SGBSTDN_TERM_CODE_ADMIT
              INTO vsTermAdm
              FROM SGBSTDN A
             WHERE A.SGBSTDN_PIDM = regRep.pidms
                   AND A.SGBSTDN_TERM_CODE_EFF =
                          (SELECT MAX (B.SGBSTDN_TERM_CODE_EFF)
                             FROM SGBSTDN B
                            WHERE A.SGBSTDN_PIDM = B.SGBSTDN_PIDM);
         EXCEPTION
            WHEN OTHERS
            THEN
               vsTermAdm := NULL;
         END;

         --- OBTIENE VALOR DE PERS_SUFIX
         BEGIN
            SELECT SPBPERS_NAME_SUFFIX
              INTO vsRut
              FROM SPBPERS
             WHERE SPBPERS_PIDM = regRep.pidms;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               vsRut := NULL;
         END;

         BEGIN
            -- DETERMINA SI TIENE BECA
            SELECT COUNT (1)
              INTO vnBeca
              FROM TBBESTU
             WHERE TBBESTU_PIDM = regRep.pidms
                   AND TBBESTU_TERM_CODE = regRep.termz;

            IF vnBeca > 0
            THEN
               vsBeca := 'X';
            ELSE
               vsBeca := ' ';
            END IF;
         END;


         --MCC 03/08/2007 CAMBIO PARA SOLO VALIDAR LO QUE EL USUARIO MANDA EN LA FORMA
         IF NVL (vnNivIn, 0) > 0
         THEN
            vsNivelIng := regRep.NivIngles;
         END IF;

         IF NVL (vnRep, 0) > 0
         THEN
            vsMatRep := regRep.Matrep;
         END IF;

         IF NVL (vnOcu, 0) > 0
         THEN
            vsOpor := regRep.OporAgo;
         END IF;

         IF NVL (vnAvan, 0) > 0
         THEN
            vsPorcAvan := regRep.PorcAvan;
         END IF;

         IF NVL (vnSemestre, 0) > 0
         THEN
            vsSemestre := regRep.semestre;
         END IF;

         IF NVL (vnRanking, 0) > 0
         THEN
            vnRanking := regRep.Ranking;
         END IF;

         IF NVL (vnPerReprob, 0) > 0
         THEN
            vnPerReprob := regRep.PerReprob;
         END IF;

         -- Si es Avanzado o Principiante
         vsAvanzado := FWATYAL (regRep.pidms, regRep.Campus, regRep.termz); -- psTerm); -- rcm 10 jun 2011

         --IF vsAvanzado  = 'A' then  -- esto es necesario  rcm 10 jun 2011

         --************************************************************************************************************

         HTP.
          p (
               '<tr>'
            || '<td valign="top">'
            || RegRep.Majr
            || '</td>'
            || '<td valign="top">'
            || regRep.Programa
            || '</td>'
            || '<td valign="top">'
            || vsTermAdm
            || '</td>'
            || '<td valign="top">'
            || regRep.descripcion
            || '</td>'
            || '<td valign="top">'
            || vsRut
            || '</td>'
            || '<td valign="top">'
            || regRep.ID
            || '</td>'
            || '<td valign="top">'
            || regRep.Nombre
            || '</td>'
            || '<td valign="top">'
            || vsNivelIng
            || '</td>');


         --********************************** rcm 14 jul 2011 incorporacion de tooltip  SUBJ y CRSE
         --****************************************************************************************

         HTP.
          p (
            '<td valign="top"><a  href="#" ><font title="Informacion de SUB y CRSE y PERIODO');

         --P_DetToolTip (pnPidm NUMBER, psLevel VARCHAR, psTerm VARCHAR2);
         P_DetToolTip (regRep.pidms, regRep.Nivel, vsPerio);

         HTP.p ('">' || vsMatRep || '</font></a></td>');

         --****************************************************************************************
         --****************************************************************************************
         HTP.
          p (
            '<td valign="top"><a  href="#" ><font title="Informacion de SUB y CRSE y PERIODO');
         P_DetToolTipA (regRep.pidms,  vsPerio);
         HTP.p ('">' || vsOpor || '</font></a></td>');


         HTP.
          P (
               '<td valign="top">'
            || vsPorcAvan
            || '</td>'
            || '<td valign="top">'
            || vsSemestre
            || '</td>'
            || '<td valign="top">'
            || regRep.Ranking
            || '</td>'
            || '<td valign="top">'
            || regRep.PerReprob
            || '</td>'
            || '<td valign="top">'
            || regRep.CalifProm
            || '</td>'
            || '<td valign="top">'
            || regRep.MatAProb
            || '</td>'
            || '<td valign="top">'
            || regRep.MatIns
            || '</td>'
            || '<td valign="top">'
            || regRep.MatGral
            || '</td>'
            || '<td valign="top">'
            || vsBeca
            || '</td>'
            || '</tr>');

         vnExists := 1;
         vsValIngles := NULL;
         --END IF;

         vnExists := 1;
      END LOOP;



      IF vnExists = 0
      THEN
         HTP.
          p (
               '<tr><th colspan="'
            || cnColumnas
            || '"><font color="#ff0000">'
            || Pk_Sisrepimp.vgsResultado
            || '</font></th></tr>');
      ELSE
         -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de pagina para impresion
         Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

         -- es omitido el encabezado del reporte pero se agrega el salto de pagina
         Pk_Sisrepimp.P_EncabezadoDeReporte (psReclDesc,
                                             cnColumnas,
                                             tabColumna,
                                             'PIE',
                                             '0',
                                             psUsuario   => pk_login.vgsUSR,
                                             psSeccion   => '3');

      END IF;
      htp.p('<script language="javascript">
            function closeWindowTime() {

        if (dom) {
            document.getElementById("pleasewaitScreen").style.visibility=''hidden'';
        }

        if (document.layers) {
            document.layers["pleasewaitScreen"].visibility=''hide'';
        }

        vbgActiv = false;

        document.body.className = "";
      } //closeWindowTime
      ');
--kwatime.js;
      htp.p('</script>');

      HTP.p ('</table><br/></body></html>');
--htp.p('<script language="javascript" src="kwatime.js"></script>');
   EXCEPTION
      WHEN OTHERS
      THEN
         HTP.p (SQLERRM);
   END Menu_Reporte;
END KWACIERRE;
/
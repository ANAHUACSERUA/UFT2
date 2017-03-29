CREATE OR REPLACE PROCEDURE BANINST1.PWRACS(psReclDesc   VARCHAR2) IS
-----Creación de Reporte “Auditoría de Cierre de Semestre”

--CREATE   by glovicx_--- 01- DIC-  2014
----modify      vic..   19.ene.2014
----



  -- declaración de variables:
  vnExists       INTEGER      := 0;
  vnColumnas     INTEGER      := 23;
  vgsInicioPag   VARCHAR2(30) := NULL;         -- bandera que al tener el valor "imprime" no colocará el salto de página para impresión
  vnIdRenglon    INTEGER      := 1;
  tabColumna     Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla(1);

  vsTerm         SARAPPD.SARAPPD_TERM_CODE_ENTRY%TYPE DEFAULT NULL;
  vsProgr        SARADAP.SARADAP_PROGRAM_1%TYPE       DEFAULT NULL;
  vsPropsu_ant          VARCHAR2(50) := NULL;
  vsPropsu_act          VARCHAR2(50) := NULL;
  vnTermAnt             VARCHAR2(6) := NULL;
  vnTermAct             VARCHAR2(6) := NULL;
  vnAnoEje                VARCHAR2(4) := NULL;
  vsnivel1                   VARCHAR2(4) := NULL;
--
  csSlh       varchar2(1):= '/';
  vsnivel    varchar2(50);

  vsingles       SGBUSER.SGBUSER_SUDA_CODE%TYPE;
  vstoramrep  SGBUSER.SGBUSER_SUDA_CODE%TYPE;
  vstooporuti   SGBUSER.SGBUSER_SUDA_CODE%TYPE;
  vsavance    SGBUSER.SGBUSER_SUDA_CODE%TYPE;
  vsranking     SGBUSER.SGBUSER_SUDA_CODE%TYPE;
  vsnumpere   SGBUSER.SGBUSER_SUDA_CODE%TYPE;
  vsasigacred  SGBUSER.SGBUSER_SUDA_CODE%TYPE; 
  vsultimo       number;
  vsbeca       number:= 0;
  vsbeca2     varchar2(1);
  vsmatap      number:=0;
  vsmatapp    number:=0;


cursor  cubeca  (pspidm  varchar2,psterm  varchar2  ) is
 SELECT  count(1)   as  conta
 FROM   TBBESTU 
 WHERE  tbbestu_pidm    = pspidm
 AND    substr(tbbestu_term_code,1,4)  =   substr(psterm,1,4);



cursor cu_guser   ( pspidm  varchar2, psterm varchar2) is
select   sg.SGBUSER_SUDB_CODE            as   nvl_ingles  -- Nivel de Inglés (Elemento 2 SGAUSDF) 
          ,sg.SGBUSER_SUDC_CODE          as   toramrep     ---- Total de Ramos reprobados.(Elemento 3 SGAUSDF) 
          ,sg.SGBUSER_SUDD_CODE          as  tooporuti        ----- Total de Oportunidades utilizadas (Elemento 4 SGAUSDF)
          ,sg.SGBUSER_SUDE_CODE          as  avance            ---- % de avance (Elemento 5 SGAUSDF) 
          ,sg.SGBUSER_SUDF_CODE          as  ranking             ----- Ranking (Elemento 6 SGAUSDF)        
          ,sg.SGBUSER_SUDG_CODE          as  numpere         --Número de periodos consecutivos reprobados (Elemento 7 SGAUSDF)
          ,sg.SGBUSER_SUDI_CODE          as  asigacred    --% Asignaturas acreditados acumulados en el historial     
from    SGBUSER    sg
where   SG.SGBUSER_PIDM  = pspidm
and     SG.SGBUSER_TERM_CODE  =  psterm;
 
  
  -- obtiene la información de los alumnos:
CURSOR cuReporte ( psTerm    VARCHAR2  DEFAULT NULL,
                              psProgr   VARCHAR2  DEFAULT NULL,
                              psnivel    varchar2     ) IS
SELECT DISTINCT   
            MA.STVMAJR_CODE                                                                      as code_carrera,
            A.SGBSTDN_PROGRAM_1                                                               as malla,
            a.SGBSTDN_Term_code_admit                                                        as periodo_admit,
            MA.STVMAJR_DESC                                                                      as carrera ,
            spbpers_name_suffix                                                                     as    RUT,
            SPRIDEN_ID                                                                                as     ID,
            UPPER(REPLACE(REPLACE(SPRIDEN_FIRST_NAME||' '||SPRIDEN_MI,'   ', ' '), '  ', ' '))      as     NOMBRE
           ,(select  to_char (AVG(ha.swvhiac_quality_points), '9999.9')
             from SWVHIAC ha
             where ha.swvhiac_pidm =  A.SGBSTDN_PIDM
             and   ha.swvhiac_term_code  = psterm   )                                               as propeact -- promedio del periodo actual 
          -- ,NVL (TRUNC (kwacierre.Mat_aprobadasGral (A.SGBSTDN_PIDM, psTerm,psnivel), 1),  0)    as   asig_acred_peri_act    --- asignaturas acreditadas en el perio actual                                
        ---     ,NVL (substr (kwacierre.Mat_aprobadasGral (A.SGBSTDN_PIDM, psTerm, psnivel), 1,1),  0)    as   asig_acred_peri_act    --- asignaturas acreditadas en el perio actual
           ,kwacierre.Mat_inscritas (psTerm ,A.SGBSTDN_PIDM )                                       as mat_inscrt     ------ Asignaturas Inscritas en el periodo
            ,a.SGBSTDN_STST_CODE                                                                     as stst_alumno    -- ultimo eststus del alumno
            ,A.SGBSTDN_PROGRAM_1                                                                     as programa    ---- ultimo programa
            ,(SELECT max(TWBCNTR_NUM)     FROM TWBCNTR TN
              WHERE TN.TWBCNTR_TERM_CODE  >= psterm---KWABAJA.f_next_period(psterm)
              AND   TN.TWBCNTR_PIDM = A.SGBSTDN_PIDM 
              and   TN.TWBCNTR_STATUS_IND <> 'C'         )                                              as  cntr_fut             ---Contrato en periodo futuro
             ,(select  ST.SGRCHRT_CHRT_CODE
               from SGRCHRT st
               where ST.SGRCHRT_PIDM = A.SGBSTDN_PIDM
               and   ST.SGRCHRT_TERM_CODE_EFF   = (SELECT MAX(G.SGRCHRT_TERM_CODE_EFF) FROM SGRCHRT G
                                                   WHERE   G.SGRCHRT_PIDM = ST.SGRCHRT_PIDM
                                                   AND G.SGRCHRT_TERM_CODE_EFF <=psTerm  ))          as   cohorte ---Cohorte de Ingreso
             ,A.SGBSTDN_PIDM                                                                         as pidm   
FROM         SPRIDEN  
             ,SPBPERS
             ,SGBSTDN A
             ,STVMAJR  ma
      WHERE SPRIDEN_PIDM = SPBPERS_PIDM
            and  SPRIDEN_PIDM   =  A.SGBSTDN_PIDM
            and  A.SGBSTDN_MAJR_CODE_1  =   MA.STVMAJR_CODE    
            AND SPRIDEN_CHANGE_IND IS NULL
            and   a.SGBSTDN_MAJR_CODE_1  = MA.STVMAJR_CODE
           and (instr(csSlh||psnivel, csSlh||A.SGBSTDN_LEVL_CODE||csSlh) > 0 or   psnivel= csSlh  OR  psnivel is null)    --md  vic..
         ---  and (instr(csSlh||psnivel, csSlh||SARADAP_LEVL_CODE||csSlh) > 0 or   psnivel= csSlh  OR  psnivel is null)    --md  vic..
       ---  and    A.SGBSTDN_LEVL_CODE = psnivel
            and  A.SGBSTDN_TERM_CODE_EFF  = ( select   max(SGBSTDN_TERM_CODE_EFF ) from sgbstdn s2  
                                              where  s2.sgbstdn_pidm = a.sgbstdn_pidm
                                              and     s2.SGBSTDN_TERM_CODE_EFF <= psterm)
            AND (A.SGBSTDN_PROGRAM_1 = psProgr  or psProgr is null) --programa
        --      
       order by   SPRIDEN_ID    ;    


FUNCTION Mat_aprobadasGral (pnPidm NUMBER, psTerm VARCHAR, psLevl    VARCHAR2)
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
                AND SUBSTR (SHRTCKN_TERM_CODE, 1, 6) <= SUBSTR (psTerm, 1, 6)
                AND (g1.SHRTCKG_GRDE_CODE_FINAL = 'AC'
                     OR SHRTCKG_GRDE_CODE_FINAL >= '4')
                AND g1.SHRTCKG_GRDE_CODE_FINAL <> 'P'  ; --  >= rcm 16 jun 2011
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vnTotalAp := 0;
      END;

     ---   insert into swrpaso values ('pwracs ', 'pidm ' ||pnPidm ||'  term '|| psTerm || '  level ' ||psLevl ||'  total '||vnTotal|| '  totalAP '|| vnTotalAp); commit;

     if vnTotalAp <= vnTotal then
      RETURN TRUNC ( (vnTotalAp * 100 / vnTotal), 1);      
         -- RETURN pnPidm|| '-' || psTerm || ' -- ' ||vnTotal || ' --- ' ||vnTotalAp;  -- rcm pruebas 16 junio 2011
        else
        return null;
        end if;

   END Mat_aprobadasGral;



 function  ultimo_sem (pspidm  varchar2, psprog   varchar2)
 return number  is
ultimo  number;

begin
ultimo := null;

 SELECT MAX (SUBSTR (A.SMBAOGN_AREA, LENGTH (A.SMBAOGN_AREA) - 1, 2))    grupo
   into ultimo 
           FROM SMBAOGN A
          WHERE     A.SMBAOGN_PIDM = pspidm
                AND A.SMBAOGN_PROGRAM = psprog
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
                        '17')
                     and  rownum < 2;   


return(ultimo);
exception
when others  then

ultimo := null;
end ultimo_sem;
--------------------------------------------------------

 
---------------------------------------------------
-- bloque principal para la generación del reporte
---------------------------------------------------
BEGIN

   -- valida que el usuario tenga acceso a la base de datos:
 ---  IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

   -- obtiene los valores de las cookies para asignar los valores del filtro del query:
   vsTerm  := pk_ObjHtml.getValueCookie('psTerm');
   vsProgr := pk_ObjHtml.getValueCookie('psProg1');
   vsnivel  := pk_ObjHtml.getValueCookie('psNivl1');

   -- determina el largo de la tabla:
   FOR vnI IN 1..vnColumnas LOOP
       tabColumna.EXTEND(vnI);
       tabColumna(vnI) := NULL;
   END LOOP;

   -- define los encabezados de las columnas:
   tabColumna(1)  := '<center> Carrera';
   tabColumna(2)  := '<center>   Malla    ';
   tabColumna(3)  := '<center> Periodo de Admisión';
   tabColumna(4)  := '<center> Descripción de Carrera';
   tabColumna(5)  := '<center> RUT';
   tabColumna(6)  := '<center> ID';
   tabColumna(7)  := '<center> Nombre';
   tabColumna(8)  := '<center> Nivel Inglés<br> Acreditado';
   tabColumna(9)  := '<center> Ramos Reprobados en<br> la historia académica';
   tabColumna(10) := '<center> Oportunidades utilizadas en<br> la historia académica';
   tabColumna(11) := '<center> % Avance respecto a <br> los créditos totales';
   tabcolumna(12) := '<center> Último Semestre o año<br> completo acreditado';
   tabColumna(13) :='<center> Ranking';
   tabColumna(14) := '<center> Periodos Consecutivos<br> reprobados';
   tabColumna(15) := '<center> Promedio del <br> Periodo actual';
   tabColumna(16) := '<center> Asignaturas Acreditadas<br> en el periodo actual';
   tabColumna(17) := '<center> Asignaturas Inscritas<br> en el periodo';
   tabColumna(18) := '<center> % Asignaturas acreditados <br> acumulados en el historial';
   tabColumna(19) := '<center> Beca';
   tabColumna(20) := '<center> Último Estatus alumno';
   tabColumna(21) := '<center> Último Programa del Alumno';
   tabColumna(22) := '<center> Contrato en periodo futuro';
   tabColumna(23) := '<center> Cohorte de Ingreso';
  

   -- manipula la información obtenida por el cursor:
   FOR regRep IN cuReporte (vsTerm, vsProgr,vsnivel) LOOP

        vsmatap  := 0;
        vsmatapp  := 0;

       IF vnExists = 0 THEN

          -- muestra el encabezado según el periodo y programa seleccionados:
          IF vsProgr IS NOT NULL THEN
             Pk_Sisrepimp.p_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, vgsInicioPag, '1',
                                                psSubtitulo   => 'Periodo: &nbsp;'||vsTerm||' - '||Pk_Catalogo.PERIODO(vsTerm)||'<br>'||'Programa: &nbsp;'||vsProgr||' - '||Pk_Catalogo.Programa(vsProgr),
                                                psUniversidad => 'UFT');
             vgsInicioPag := 'SALTO';
          ELSE
             Pk_Sisrepimp.p_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, vgsInicioPag, '1',
                                                psSubtitulo   => 'Periodo: &nbsp;'||vsTerm||' - '||Pk_Catalogo.PERIODO(vsTerm)||'<br>'||'Programa: &nbsp;'||'Todos ',
                                                psUniversidad => 'UFT');
             vgsInicioPag := 'SALTO';
          END IF;

       END IF;
 
        for regs1  IN  cu_guser  (regRep.PIDM, vsterm) LOOP 
         vsingles        :=    regs1.nvl_ingles;
         vstoramrep   :=     regs1.toramrep;
         vstooporuti    :=     regs1.tooporuti;
         vsavance      :=     regs1.avance;
         vsranking      :=     regs1.ranking;
         vsnumpere    :=     regs1.numpere;
         vsasigacred   :=     regs1.asigacred;  
        END LOOP;
            
        vsultimo     :=    ultimo_sem (regRep.PIDM,regRep.malla )   ;   
        
        for  reg2  in cubeca    ( regRep.PIDM, vsterm) loop
         vsbeca     :=   reg2.conta;
         
               if vsbeca   > 0  then  
               vsbeca2 := 'X';
               end if;
               
          --   
      end loop;
      
      -------asigna los valores de materias aprobadas e inscritas
   ---     insert into swrpaso values ('pwracs 2 ', 'pidm ' ||regRep.pidm ||'  term '|| vsTerm || '  level ' || substr(vsnivel,1,2)   ); commit;
      vsmatap           := nvl( substr (Mat_aprobadasGral (regRep.pidm, vsterm,substr(vsnivel,1,2)), 1,1),0);
    --  vsmatapp         := baninst1.kwacierre.Mat_inscritas (regRep.periodo_admit ,regRep.pidm) ;
          ---    as   asig_acred_peri_act    --- asignaturas acreditadas en el perio actual
         ---   ,kwacierre.Mat_inscritas (psTerm ,A.SGBSTDN_PIDM )                                       as mat_inscrt     ------ Asignaturas Inscritas en el periodo
      
                 HTP.P('<tr> <td valign="top" align="left">' ||regRep.code_carrera    || '</td>' ||
                   '<td valign="top" align="left">'       ||regRep.malla              ||    '</td>'||
                   ' <td valign="top" align="left">'      ||regRep.periodo_admit      ||'</td>'||
                   ' <td valign="top" align="left">'      ||regRep.carrera            ||  '</td>'||
                   ' <td valign="top" align="left">'      ||regRep.rut                || '</td>'||
                   ' <td valign="top" align="left">'       ||regRep.id                ||  '</td>'||
                   ' <td valign="top" align="left">' ||regRep.nombre                  || '</td>'||
                   ' <td valign="top" align="left">' ||vsingles                         ||  '</td>'||
                   ' <td valign="top" align="left">' ||vstoramrep                       ||'</td>'||
                   ' <td valign="top" align="left">' ||vstooporuti                      ||'</td>'||
                   ' <td valign="top" align="left">' ||vsavance                         ||    '</td>'||
                   ' <td valign="top" align="left">' ||vsultimo                         || '</td>'||                
                   ' <td valign="top" align="left">' ||vsranking                        || '</td>'||
                   ' <td valign="top" align="left">' ||vsnumpere                        ||'</td>'||
                   ' <td valign="top" align="left">' ||regRep.propeact                  ||   '</td>'||  
                   ' <td valign="top" align="left">' ||vsmatap                           ||    '</td>'||                                                                      
                   ' <td valign="top" align="left">' ||regRep.mat_inscrt                        ||  '</td>'||    
                   ' <td valign="top" align="left">' ||vsasigacred                      ||  '</td>'||        
                   ' <td valign="top" align="left">'    ||   vsbeca2                    ||    '</td>'||
                   ' <td valign="top" align="left">' ||regRep.stst_alumno               || '</td>'||
                   ' <td valign="top" align="center">' ||regRep.programa                ||  '</td>'||
                   ' <td valign="top" align="center">' ||regRep.cntr_fut                ||   '</td>'||
                   ' <td valign="top" align="center">' ||regRep.cohorte                 ||  '</td>'
                   ||  ' </tr>');
         
      
       vnExists    := 1;
       vnIdRenglon := vnIdRenglon + 1;
         vsbeca2  := null;  
   END LOOP;

   -- muestra el pie de reporte:
   IF vnExists = 0 THEN
      htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- bandera que al tener el valor "imprime" no colocará el salto de página para impresión:
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- omite el encabezado del reporte pero se agrega el salto de página:
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas, tabColumna, 'PIE', '0', psUsuario=>pk_login.vgsUSR );
   END IF;

   htp.p('</table><br/> Num. Registros:   ' || vnIdRenglon  || ' </body></html>');

EXCEPTION
   WHEN OTHERS THEN
        htp.p(SQLERRM);

END PWRACS;
/


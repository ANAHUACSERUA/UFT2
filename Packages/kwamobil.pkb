CREATE OR REPLACE PACKAGE BODY BANINST1.kwamobil IS
/*kwamobil.getRetenciones
 Tarea: Consultas para las aplicaciones Mobile
 Fecha: 26/06/2012.


 Modificación: CONSULTE EL "PACKAGE BODY" PARA VER EL DETALLE DE LAS MODIFICACIONES
 RCM UFT 2014
*/

 vgsError VARCHAR2(5000) := NULL;

 cs0 CONSTANT VARCHAR2(1) := '0';
 csY CONSTANT VARCHAR2(1) := 'Y';
 csAst CONSTANT VARCHAR2(1) := '*';
 csEsp CONSTANT VARCHAR2(1) := ' ';
 csM CONSTANT VARCHAR2(1) := 'M';
 csN CONSTANT VARCHAR2(1) := 'N';
 csC CONSTANT VARCHAR2(1) := 'C';
 csP CONSTANT VARCHAR2(1) := 'P';
 csI CONSTANT VARCHAR2(1) := 'I';
 csF CONSTANT VARCHAR2(1) := 'F';
 csCma CONSTANT VARCHAR2(1) := ',';
 csPrc CONSTANT VARCHAR2(1) := '%';
 csPop CONSTANT VARCHAR2(1) := '(';
 csPcl CONSTANT VARCHAR2(1) := ')';
 csRE CONSTANT VARCHAR2(2) := 'RE';
 csRW CONSTANT VARCHAR2(2) := 'RW';
 csYear CONSTANT VARCHAR2(4) := TO_CHAR(SYSDATE,'YYYY');
 csPago CONSTANT VARCHAR2(4) := 'Pago';
 csCargo CONSTANT VARCHAR2(5) := 'Cargo';
 cs99p99 CONSTANT VARCHAR2(5) := '99.99';
 cs999998 CONSTANT VARCHAR2(6) := '999998';
 cs999997 CONSTANT VARCHAR2(6) := '999997';
 cs999996 CONSTANT VARCHAR2(6) := '999996';
 csDDMMYYYY CONSTANT VARCHAR2(10) := 'DD/MM/YYYY';
 cs9_999_99 CONSTANT VARCHAR2(17) := '9,999,999,990.99';
 cdSysDate CONSTANT DATE := SYSDATE;
 cdTysDate CONSTANT DATE := TRUNC(SYSDATE);
 cn0 CONSTANT NUMBER(1) := 0;
 cn1 CONSTANT NUMBER(1) := 1;
 cn2 CONSTANT NUMBER(1) := 2;
 cn4 CONSTANT NUMBER(1) := 4;
 cn5 CONSTANT NUMBER(1) := 5;
 cn6 CONSTANT NUMBER(1) := 6;
 cn10 CONSTANT NUMBER(2) := 10;

 cn20100    CONSTANT NUMBER(6)    := -20100;

 --obtiene el maximo periodo inscrito en SFAREGS
 --getMaxTermEnrl
 FUNCTION getMaxTermEnrl(pnPIDM NUMBER) RETURN VARCHAR2;

 --colorCalificacion
 FUNCTION colorCalificacion(pnGrade NUMBER) RETURN VARCHAR2 IS

 vsColor VARCHAR2(1) := NULL;

  csa        CONSTANT VARCHAR2(1)  := 'a';
  csb        CONSTANT VARCHAR2(1)  := 'b';
  csc        CONSTANT VARCHAR2(1)  := 'c';
  csd        CONSTANT VARCHAR2(1)  := 'd';
  cse        CONSTANT VARCHAR2(1)  := 'e';

  /**rcm nuevos colores
  cn89       CONSTANT NUMBER(4,2)  := 8.9;
  cn79       CONSTANT NUMBER(4,2)  := 7.9;
  cn69       CONSTANT NUMBER(4,2)  := 6.9;
  cn59       CONSTANT NUMBER(4,2)  := 5.9;
  cn7        CONSTANT NUMBER(1)    := 7;
  cn8        CONSTANT NUMBER(1)    := 8;
  cn9        CONSTANT NUMBER(2)    := 9;  **/
  
  cn1_        CONSTANT NUMBER(2)    := 1;
  cn4_        CONSTANT NUMBER(2)    := 4;
  cn5_        CONSTANT NUMBER(2)    := 5;
  cn6_        CONSTANT NUMBER(2)    := 6;
  cn7_        CONSTANT NUMBER(2)    := 7;
  
  cn39_       CONSTANT NUMBER(4,2)  := 3.99;
  cn49_       CONSTANT NUMBER(4,2)  := 4.99;
  cn59_       CONSTANT NUMBER(4,2)  := 5.99;
  cn69_       CONSTANT NUMBER(4,2)  := 6.99;
  

 BEGIN
  IF pnGrade >= cn7_ THEN
   vsColor := csa;
  ELSIF pnGrade BETWEEN cn6_ AND cn69_ THEN
   vsColor := csb;
  ELSIF pnGrade BETWEEN cn5_ AND cn59_ THEN
   vsColor := csc;
  ELSIF pnGrade BETWEEN cn4_ AND cn49_ THEN
   vsColor := csd;
  ELSIF pnGrade <= cn39_ THEN
   vsColor := cse;
  ELSE
   vsColor := csa;
  END IF;

  RETURN vsColor;

 END colorCalificacion;

 --promedioParcial
 FUNCTION promedioParcial(pnPidm NUMBER,
                          psTerm VARCHAR2,
                          pnCrn NUMBER,
                          psType VARCHAR2
 ) RETURN VARCHAR2 IS

 vsPromedio VARCHAR2(30) := NULL;
 vnWeight NUMBER := 0;
 vnGrade NUMBER := 0;
 vnMinPass NUMBER := 0;

 BEGIN
   BEGIN
    SELECT SHRGCOM_MIN_PASS_SCORE/cn10
      INTO vnMinPass
      FROM SHRGCOM
     WHERE SHRGCOM_PASS_IND = csY
       AND SHRGCOM_INCL_IND = psType
       AND SHRGCOM_CRN = pnCrn
       AND SHRGCOM_TERM_CODE = psTerm;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      vnMinPass := cn0;
     WHEN OTHERS THEN
      vnMinPass := cn0;
   END;

    SELECT TRUNC(SUM(TO_NUMBER(SHRMRKS_GRDE_CODE,cs99p99) *
                   SHRGCOM_WEIGHT)/SUM(SHRGCOM_WEIGHT),cn1),
           SUM(SHRGCOM_WEIGHT)
      INTO vnGrade,vnWeight
      FROM SHRMRKS, SHRGCOM
     WHERE SHRMRKS_GCOM_ID = SHRGCOM_ID
       AND SHRMRKS_CRN = SHRGCOM_CRN
       AND SHRMRKS_TERM_CODE = SHRGCOM_TERM_CODE
       AND LTRIM(SHRMRKS_GRDE_CODE) IS NOT NULL
       AND SHRGCOM_INCL_IND = psType
-- AND (
-- ( psType = csM
-- AND SHRGCOM_INCL_IND = psType
-- )
-- OR
-- (
-- psType = csF
-- )
-- )
       AND SHRMRKS_PIDM = pnPidm
       AND SHRGCOM_CRN = pnCrn
       AND SHRGCOM_TERM_CODE = psTerm;

     IF vnMinPass > cn0 AND vnGrade < vnMinPass THEN
       vnGrade := cn5;
     END IF;

     IF vnGrade IS NOT NULL THEN
       vsPromedio := vnGrade||csEsp||csPop||vnWeight||csPrc||csPcl;
     ELSE
       vsPromedio := csEsp;
     END IF;

     RETURN vsPromedio;

 EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN csEsp;
    WHEN OTHERS THEN
     RETURN csEsp;
 END promedioParcial;

 --ponderacion
 FUNCTION ponderacion(psTerm VARCHAR2,
                      pnCrn NUMBER,
                      psType VARCHAR2
 ) RETURN VARCHAR2 IS

  vsPromedio VARCHAR2(30) := NULL;
  vnWeight NUMBER := 0;

  csa        CONSTANT VARCHAR2(1)  := 'a';
  csb        CONSTANT VARCHAR2(1)  := 'b';

 BEGIN
    SELECT SUM(SHRGCOM_WEIGHT)
      INTO vnWeight
      FROM SHRGCOM
     WHERE (
             ( psType = csM
               AND SHRGCOM_INCL_IND = psType
             )
             OR
            (
             psType = csF
            )
           )
       AND SHRGCOM_CRN = pnCrn
       AND SHRGCOM_TERM_CODE = psTerm;


    vsPromedio := csEsp||csPop||vnWeight||csPrc||csPcl;

    RETURN vsPromedio;

 EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN csa;
  WHEN OTHERS THEN
    RETURN csb;

 END ponderacion;

 --obtiene el maximo periodo inscrito en SFAREGS
 --getMaxTermEnrl
 FUNCTION getMaxTermEnrl(pnPIDM NUMBER) RETURN VARCHAR2 IS

 vsTerm VARCHAR2(6) := NULL;

 BEGIN
     SELECT MAX(SFRSTCR_TERM_CODE)
       INTO vsTerm
       FROM SFRSTCR
      WHERE SFRSTCR_RSTS_CODE IN (csRE,csRW)
        AND SFRSTCR_TERM_CODE <> cs999998
        AND SFRSTCR_TERM_CODE <> cs999997
        AND SFRSTCR_TERM_CODE <> cs999996
        AND SFRSTCR_PIDM = pnPIDM;

 RETURN vsTerm;

 END getMaxTermEnrl;

 --getName
 PROCEDURE getName(psId VARCHAR2,
                   cuName OUT type_cursor
                  ) IS

  BEGIN
    OPEN cuName FOR
    SELECT SPRIDEN_FIRST_NAME||csEsp||
           REPLACE(SPRIDEN_LAST_NAME,csAst,csEsp) AS nombre
      FROM SPRIDEN
     WHERE SPRIDEN_CHANGE_IND IS NULL
       AND SPRIDEN_ID = psId;
  END getName;

 --getTerms
 PROCEDURE getTerm(psTypeTerm VARCHAR2 DEFAULT NULL,
                   cuTerm OUT type_cursor
                  ) IS

 cnHH24MI   NUMBER(4);

 cs9999     CONSTANT VARCHAR2(4)  := '9999';
 csFHH24MI  CONSTANT VARCHAR2(6)  := 'HH24MI';

 BEGIN

    cnHH24MI := TO_NUMBER(TO_CHAR(SYSDATE,csFHH24MI),cs9999);

    OPEN cuTerm FOR
         SELECT STVTERM_CODE AS termCode,
                STVTERM_DESC AS termDesc
           FROM STVTERM
          WHERE STVTERM_CODE IN (SELECT SFRCTRL_TERM_CODE_HOST
                                   FROM SFRCTRL
                                  WHERE (
                                          (
                                          TRUNC(SFRCTRL_BEGIN_DATE) >= cdTysDate
                                          AND cdTysDate NOT BETWEEN TRUNC(SFRCTRL_BEGIN_DATE) AND TRUNC(SFRCTRL_END_DATE)
                                          )
                                          OR
                                           (
                                            cdTysDate BETWEEN TRUNC(SFRCTRL_BEGIN_DATE) AND TRUNC(SFRCTRL_END_DATE)
                                            AND ( cnHH24MI BETWEEN TO_NUMBER(SFRCTRL_HOUR_BEGIN) AND TO_NUMBER(SFRCTRL_HOUR_END)
                                                  OR
                                                    (
                                                     TO_NUMBER(SFRCTRL_HOUR_BEGIN) > cnHH24MI
                                                     AND cnHH24MI NOT BETWEEN TO_NUMBER(SFRCTRL_HOUR_BEGIN) AND TO_NUMBER(SFRCTRL_HOUR_END)
                                                    )
                                                )
                                         )
                                        )
                                 )
            AND SUBSTR(STVTERM_CODE,cn6,cn1) = cs0
            AND TRUNC(STVTERM_END_DATE) > cdTysDate
            AND STVTERM_CODE <> cs999998
            AND STVTERM_CODE <> cs999997
            AND STVTERM_CODE <> cs999996
       ORDER BY STVTERM_CODE DESC;

 END getTerm;

 --getHiAc
 PROCEDURE getHiAc(psId VARCHAR2,
                   cuHiAc OUT type_cursor
                   ) IS

   cnPidm CONSTANT NUMBER(8) := f_get_pidm(psId);

   vsHoldED VARCHAR2(500) := NULL;
   vsHoldOT VARCHAR2(500) := NULL;

   csX       CONSTANT VARCHAR2(1) := 'X';
   csY       CONSTANT VARCHAR2(1) := 'Y';
   csF       CONSTANT VARCHAR2(1) := 'F';
   csED      CONSTANT VARCHAR2(2) := 'ED';
   csHOLD    CONSTANT VARCHAR2(4) := 'HOLD';
   csOTRO    CONSTANT VARCHAR2(4) := 'OTRO';
   csSINP    CONSTANT VARCHAR2(4) := 'SINP';
   csgetHiAc CONSTANT VARCHAR2(9) := 'getHiAc: ';

 --cuHold
 cursor cuHold(psHoldCode varchar2 default null) is
        SELECT STVHLDD_DESC AS holdDesc
          FROM STVHLDD, SPRHOLD
         WHERE SPRHOLD_PIDM = cnPidm
           AND TRUNC(SPRHOLD_FROM_DATE) <= cdTysDate
           AND TRUNC(SPRHOLD_TO_DATE) >= cdTysDate
           AND STVHLDD_CODE = SPRHOLD_HLDD_CODE
           AND (
                 (
                 psHoldCode = csED
                 AND STVHLDD_CODE = psHoldCode
                 )
                OR
                 (
                   psHoldCode IS NULL
                   AND stvhldd_code <> csED
                 )
               )
           AND STVHLDD_GRADE_HOLD_IND = csY;

   BEGIN
    FOR regHld IN cuHold(csED) LOOP
      vsHoldED := vsHoldED||regHld.holdDesc||csCma;
    END LOOP;

    FOR regHld IN cuHold LOOP
      vsHoldOT := vsHoldOT||regHld.holdDesc||csCma;
    END LOOP;

 --se registran las calificaciones parciales
   IF vsHoldED||vsHoldOT IS NULL THEN
     OPEN cuHiAc FOR
          SELECT SWRTCKH_CRSE_TITLE AS crseTitl,
                 SWRTCKH_GRDE_CODE_FINAL AS grdeFinl,
                 SWRTCKH_TERM_CODE AS termCode,
                 SWRTCKH_CREDIT_HOURS AS credHour,
                 SWRTCKH_NAME_FACULTY AS nameFacu,
                 SWRTCKH_TERM_DESC AS termDesc,
                 SWRTCKH_COLOR_QUALITY_POINTS AS colorGrd,
                 SWRTCKH_SUBJ_CODE AS subjCode,
                 SWRTCKH_CRSE_NUMB AS crseNumb
            FROM (select shrtckn_pidm AS SWRTCKH_PIDM,
                         shrtckn_term_code AS SWRTCKH_TERM_CODE,
                         shrtckn_crn AS SWRTCKH_CRN,
                         nvl(shrtckn_crse_title,csEsp) AS SWRTCKH_CRSE_TITLE,
                         shrtckg_grde_code_final AS SWRTCKH_GRDE_CODE_FINAL,
                         shrtckg_credit_hours AS SWRTCKH_CREDIT_HOURS,
                         nvl ((select replace (spriden_last_name||csEsp||spriden_first_name,csAst,csEsp)
                                 from sirasgn, spriden
                                where sirasgn_pidm = spriden_pidm
                                  and spriden_change_ind is null
                                  and sirasgn_primary_ind = csY
                                  and sirasgn_crn = shrtckn_crn
                                  and sirasgn_term_code = shrtckn_term_code
                                  and ROWNUM = cn1
                              ),
                              csEsp
                              ) AS SWRTCKH_NAME_FACULTY,
                              ( select stvterm_desc
                                  from stvterm
                                 where stvterm_code = shrtckn_term_code
                              ) AS SWRTCKH_TERM_DESC,
                             colorcalificacion (shrgrde_quality_points) AS SWRTCKH_COLOR_QUALITY_POINTS,
                             shrtckn_subj_code AS SWRTCKH_SUBJ_CODE,
                             shrtckn_crse_numb AS SWRTCKH_CRSE_NUMB,
                             shrtckl_levl_code AS SWRTCKH_LEVL_CODE
                  from shrtckg,
                       shrtckn,
                       shrtckl,
                       shrgrde a
                 where shrtckn_pidm = shrtckg_pidm
                   and shrtckg_term_code = shrtckn_term_code
                   and shrtckg_tckn_seq_no = shrtckn_seq_no
                   and shrtckg_seq_no = (select max(shrtckg_seq_no)
                                           from shrtckg
                                          where shrtckg_pidm = shrtckn_pidm
                                            and shrtckg_term_code = shrtckn_term_code
                                            and shrtckg_tckn_seq_no = shrtckn_seq_no
                                        )
                   and shrtckl_pidm = shrtckn_pidm
                   and shrtckl_term_code = shrtckn_term_code
                   and shrtckl_tckn_seq_no = shrtckn_seq_no
                   and a.shrgrde_code = shrtckg_grde_code_final
                   and a.shrgrde_levl_code = shrtckl_levl_code
                   and a.shrgrde_term_code_effective = (select max (b.shrgrde_term_code_effective)
                                                          from shrgrde b
                                                         where b.shrgrde_code = shrtckg_grde_code_final
                                                           and b.shrgrde_levl_code = shrtckl_levl_code
                                                           and b.shrgrde_term_code_effective <= shrtckn_term_code
                                                       )
                   and shrtckl_primary_levl_ind = csY
                   and shrtckn_pidm = cnPidm
                   ) SWRTCKH
       GROUP BY SWRTCKH_CRSE_TITLE,
                SWRTCKH_GRDE_CODE_FINAL,
                SWRTCKH_TERM_CODE,
                SWRTCKH_CREDIT_HOURS,
                SWRTCKH_NAME_FACULTY,
                SWRTCKH_TERM_DESC,
                SWRTCKH_COLOR_QUALITY_POINTS,
                SWRTCKH_SUBJ_CODE,
                SWRTCKH_CRSE_NUMB
       ORDER BY SWRTCKH_TERM_CODE DESC,
                 SWRTCKH_CRSE_TITLE;

   ELSIF vsHoldED IS NOT NULL THEN
      OPEN cuHiAc FOR
           SELECT csHOLD AS crseTitl,
                  csHOLD AS grdeFinl,
                  csHOLD AS termCode,
                  csHOLD AS credHour,
                  csHOLD AS nameFacu,
                  csHOLD AS termDesc,
                  csHOLD AS colorGrd,
                  csAst AS subjCode,
                  vsHoldED AS crseNumb
           FROM DUAL;

   ELSIF vsHoldOT IS NOT NULL THEN
      OPEN cuHiAc FOR
           SELECT csOTRO AS crseTitl,
                  csOTRO AS grdeFinl,
                  csOTRO AS termCode,
                  csOTRO AS credHour,
                  csOTRO AS nameFacu,
                  csOTRO AS termDesc,
                  csOTRO AS colorGrd,
                  csAst AS subjCode,
                  vsHoldOT AS crseNumb
             FROM DUAL;
   END IF;

 EXCEPTION
 WHEN OTHERS THEN
 vgsError := SQLERRM;

 RAISE_APPLICATION_ERROR(cn20100,csgetHiAc||vgsError);
 END getHiAc;

 --getProm
 PROCEDURE getProm(psId VARCHAR2,
                   cuProm OUT type_cursor
                   ) IS

  cnPidm    CONSTANT NUMBER(8)     := f_get_pidm(psId);
  cs99p9    CONSTANT VARCHAR2(5) := '99.99';
  csgetProm CONSTANT VARCHAR2(9)   := 'getProm: ';
  cs10      CONSTANT VARCHAR2(5) := '10';
  cn10      CONSTANT NUMBER(5,2) := 10.00;
  cs0      CONSTANT VARCHAR2(5)  := '0';
  cn0      CONSTANT NUMBER(5,2)  :=   0;
  -- rcm 20 Enero 2014 Calculo Promedios
  BEGIN
    OPEN cuProm FOR
       SELECT A.SHRTGPA_TERM_CODE AS termCode,
               --rcm NVL(TO_CHAR(TRUNC(A.SHRTGPA_GPA,cn2),cs99p9),csEsp) AS tgpaGpaa,
              decode(NVL(TO_CHAR(TRUNC(A.SHRTGPA_GPA,cn2),cs99p9),csEsp),cn10,cs10, cn0,cs0, NVL(TO_CHAR(TRUNC(A.SHRTGPA_GPA,cn2),cs99p9),csEsp)  ) AS tgpaGpaa,
              (
                 NVL(
                       (SELECT
                              decode(
                                TRUNC( DECODE(SUM(b.SHRTGPA_GPA_HOURS), cn0, cn0, SUM(b.SHRTGPA_QUALITY_POINTS) / SUM(b.SHRTGPA_GPA_HOURS)), cn2)
                                , cn10 , cs10,
                                to_char(TRUNC( DECODE(SUM(b.SHRTGPA_GPA_HOURS), cn0, cn0, SUM(b.SHRTGPA_QUALITY_POINTS) / SUM(b.SHRTGPA_GPA_HOURS)), cn2),cs99p9)
                                      )
                              from shrtgpa b
                             where   b.SHRTGPA_PIDM       = A.SHRTGPA_PIDM
                               AND   b.SHRTGPA_LEVL_CODE  = A.SHRTGPA_LEVL_CODE
                               AND   b.SHRTGPA_TERM_CODE <= A.SHRTGPA_TERM_CODE
                               AND   b.SHRTGPA_GPA_TYPE_IND = csI
                        )
                  ,csEsp )
              ) AS promGlob ,
              colorcalificacion ( NVL(TO_CHAR(TRUNC(A.SHRTGPA_GPA,cn2),cs99p9),csEsp) ) coloGpaa,
              colorcalificacion ( (
                 NVL(
                       (SELECT
                              to_char(TRUNC( DECODE(SUM(b.SHRTGPA_GPA_HOURS), cn0, cn0, SUM(b.SHRTGPA_QUALITY_POINTS) / SUM(b.SHRTGPA_GPA_HOURS)), cn2),cs99p9)
                              from shrtgpa b
                             where   b.SHRTGPA_PIDM       = A.SHRTGPA_PIDM
                               AND   b.SHRTGPA_LEVL_CODE  = A.SHRTGPA_LEVL_CODE
                               AND   b.SHRTGPA_TERM_CODE <= A.SHRTGPA_TERM_CODE
                               AND   b.SHRTGPA_GPA_TYPE_IND = csI
                        )
                  ,csEsp )
              )
                                ) coloGlob
         FROM SHRTGPA A
        WHERE A.SHRTGPA_GPA_TYPE_IND = csI
          AND A.SHRTGPA_PIDM = cnPidm;

                -- 17 abril 2013
               -- SELECT A.SHRTGPA_TERM_CODE AS termCode,
               -- NVL(TO_CHAR(TRUNC(A.SHRTGPA_GPA,cn2),cs99p99),csEsp) AS tgpaGpaa,
               -- (NVL(TO_CHAR((select trunc(sum(b.shrtgpa_gpa*b.shrtgpa_gpa_hours)/sum(b.shrtgpa_gpa_hours),cn2)
               -- from shrtgpa b
               -- where b.shrtgpa_gpa_type_ind = csI
               -- and b.shrtgpa_term_code <= A.SHRTGPA_TERM_CODE
               -- and b.shrtgpa_pidm = cnPidm
               -- ),cs99p99
               -- ),csEsp
               -- ) ) AS promGlob ,
               -- 54 coloGpaa,
               -- 6347 coloGlob
               -- FROM SHRTGPA A
               -- WHERE A.SHRTGPA_GPA_TYPE_IND = csI
               -- AND A.SHRTGPA_PIDM = cnPidm;

       EXCEPTION
         WHEN OTHERS THEN
           vgsError := SQLERRM;

           RAISE_APPLICATION_ERROR(cn20100,csgetProm||vgsError);
  END getProm;


 --getParciales
 PROCEDURE getParciales(psId VARCHAR2,
                        cuParciales OUT type_cursor
                        ) IS

  vnExists      NUMBER(1)     := NULL;
  vnExistsNivel VARCHAR2(3)   := NULL;
  vsHoldED      VARCHAR2(500) := NULL;
  vsHoldOT      VARCHAR2(500) := NULL;
  vsTermCode    VARCHAR2(6)   := NULL;

  csX    CONSTANT  VARCHAR2(1) := 'X';
  csY    CONSTANT  VARCHAR2(1) := 'Y';
  csF    CONSTANT  VARCHAR2(1) := 'F';
  csED   CONSTANT  VARCHAR2(2) := 'ED';
  csSEsp CONSTANT VARCHAR2(1)  := '';
  csHOLD CONSTANT  VARCHAR2(4) := 'HOLD';
  csOTRO CONSTANT  VARCHAR2(4) := 'OTRO';
  csSINP CONSTANT  VARCHAR2(4) := 'SINP';
  csPL CONSTANT  VARCHAR2(4)   := 'PL';
  csUAN CONSTANT  VARCHAR2(4)  := 'UAN';
  cnPidm CONSTANT  NUMBER(8)   := F_GET_PIDM(psId);
  csgetParciales CONSTANT VARCHAR2(14) := 'getParciales: ';

 -- Restringir Nivel PL UAN -- rcm 07 Marzo 2014
  cursor cuNivel is
         select 1 as existeNivel
         FROM SGBSTDN F
         WHERE
               F.SGBSTDN_PIDM = cnPidm
           AND F.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF)
                                            FROM SGBSTDN B
                                           WHERE B.SGBSTDN_PIDM = f.SGBSTDN_PIDM
                                          )
          and F.SGBSTDN_LEVL_CODE = csPL
          -- vpdi and F.SGBSTDN_VPDI_CODE = csUAN;
          and F.SGBSTDN_CAMP_CODE = csUAN;


 --cuHold
   cursor cuHold(psHoldCode varchar2 default null) is
       SELECT STVHLDD_DESC AS holdDesc
         FROM STVHLDD, SPRHOLD
        WHERE SPRHOLD_PIDM = cnPidm
          AND TRUNC(SPRHOLD_FROM_DATE) <= cdTysDate
          AND TRUNC(SPRHOLD_TO_DATE) >= cdTysDate
          AND STVHLDD_CODE = SPRHOLD_HLDD_CODE
          AND (
               (
                psHoldCode = csED
                AND STVHLDD_CODE = psHoldCode
               )
               OR
               (
               psHoldCode IS NULL
               AND stvhldd_code <> csED
               )
              )
          AND STVHLDD_GRADE_HOLD_IND = csY;

    BEGIN
       FOR regHld IN cuHold(csED) LOOP
         vsHoldED := vsHoldED||regHld.holdDesc||csCma;
       END LOOP;

       FOR regHld IN cuHold LOOP
         vsHoldOT := vsHoldOT||regHld.holdDesc||csCma;
       END LOOP;

       FOR regNivel IN cuNivel LOOP
         vnExistsNivel := regNivel.existeNivel;
       END LOOP;

       --rcm Nivel 07 Marzo 2014
       IF vnExistsNivel IS NOT NULL THEN
            OPEN cuParciales FOR
                       SELECT csSINP AS crseCrnn,
                              csSINP AS crseSubj,
                              csSINP AS crseCrse,
                              --csSINP
                              csOTRO AS crseTitl,
                              csSINP AS stcrMidd,
                              csSINP AS stcrGrde,
                              csSINP AS nameFacu,
                              csAst  AS colorGrd,
                              csEsp  AS holdDesc,
                              csEsp  AS termCode
                       FROM DUAL;
       ELSE
       --se registran las calificaciones parciales
               IF vsHoldED||vsHoldOT IS NULL THEN
                 vsTermCode := getMaxTermEnrl(cnPidm);

               --el alumno no tiene registro de calificaciones parciales
                   IF vsTermCode IS NULL THEN
                     OPEN cuParciales FOR
                       SELECT csSINP AS crseCrnn,
                              csSINP AS crseSubj,
                              csSINP AS crseCrse,
                              --csSINP
                              csOTRO AS crseTitl,
                              csSINP AS stcrMidd,
                              csSINP AS stcrGrde,
                              csSINP AS nameFacu,
                              csAst  AS colorGrd,
                              csEsp  AS holdDesc,
                              csEsp  AS termCode
                       FROM DUAL;
                   ELSE
                     OPEN cuParciales FOR
                      SELECT SFRSTCR_CRN AS crseCrnn,
                             SCBCRSE_SUBJ_CODE AS crseSubj,
                             SCBCRSE_CRSE_NUMB AS crseCrse,
                             SCBCRSE_TITLE AS crseTitl,
                             nvl(DECODE(SFRSTCR_GRDE_CODE_MID,NULL, promedioParcial(cnPidm,SFRSTCR_TERM_CODE,SFRSTCR_CRN,csM),
                                        SFRSTCR_GRDE_CODE_MID||PONDERACION(SFRSTCR_TERM_CODE,SFRSTCR_CRN,csM)
                                       ),csSEsp) AS stcrMidd,
                             nvl(DECODE(SFRSTCR_GRDE_CODE ,NULL, promedioParcial(cnPidm,SFRSTCR_TERM_CODE,SFRSTCR_CRN,csF),
                             SFRSTCR_GRDE_CODE||PONDERACION(SFRSTCR_TERM_CODE,SFRSTCR_CRN,csF)
                             ),csSEsp) AS stcrGrde,
                             NVL((select replace(spriden_last_name||csEsp||spriden_first_name,csAst,csEsp)
                                    from sirasgn, spriden
                                   where sirasgn_pidm = spriden_pidm
                                     and SPRIDEN_CHANGE_IND is null
                                     and sirasgn_primary_ind = csY
                                     and sirasgn_crn = sfrstcr_crn
                                     and sirasgn_term_code = sfrstcr_term_code
                                     and rownum = cn1
                             ),csEsp) AS nameFacu,
                             NVL((select colorCalificacion(shrgrde_quality_points)
                                    from shrgrde c
                                   where c.shrgrde_code = sfrstcr_grde_code
                                     and c.shrgrde_levl_code = sfrstcr_levl_code
                                     and c.shrgrde_term_code_effective = (select max (b.shrgrde_term_code_effective)
                                                                            from shrgrde b
                                                                           where b.shrgrde_code = SFRSTCR_GRDE_CODE
                                                                             and b.shrgrde_levl_code = SFRSTCR_LEVL_CODE
                                                                             and b.shrgrde_term_code_effective <= SFRSTCR_TERM_CODE
                                                                         )
                                 ),csAst) AS colorGrd,
                             csAst AS holdDesc,
                             SSBSECT_TERM_CODE AS termCode
                        FROM SSBSECT,
                             SCBCRSE,
                             SFRSTCR
                       WHERE SSBSECT_SUBJ_CODE = SCBCRSE_SUBJ_CODE
                         AND SSBSECT_CRSE_NUMB = SCBCRSE_CRSE_NUMB
                         AND SCBCRSE_EFF_TERM = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                                   FROM SCBCRSE SC
                                                  WHERE SC.SCBCRSE_EFF_TERM <= SSBSECT_TERM_CODE
                                                    AND SC.SCBCRSE_SUBJ_CODE = SSBSECT_SUBJ_CODE
                                                    AND SC.SCBCRSE_CRSE_NUMB = SSBSECT_CRSE_NUMB
                                                )
                         AND SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE
                         AND SSBSECT_CRN = SFRSTCR_CRN
                         AND SFRSTCR_RSTS_CODE IN (csRE, csRW)
                         AND SFRSTCR_TERM_CODE = vsTermCode
                         AND SFRSTCR_PIDM = cnPidm
                    ORDER BY SSBSECT_SUBJ_CODE,SSBSECT_CRSE_NUMB ;
                   END IF;

                ELSIF vsHoldED IS NOT NULL THEN
                   OPEN cuParciales FOR
                     SELECT csHOLD AS crseCrnn,
                            csHOLD AS crseSubj,
                            csHOLD AS crseCrse,
                            --csHOLD
                            csOTRO AS crseTitl,
                            csHOLD AS stcrMidd,
                            csHOLD AS stcrGrde,
                            csHOLD AS nameFacu,
                            csAst AS colorGrd,
                            vsHoldED AS holdDesc,
                            csEsp AS termCode
                       FROM DUAL;

                ELSIF vsHoldOT IS NOT NULL THEN
                  OPEN cuParciales FOR
                    SELECT csOTRO AS crseCrnn,
                           csOTRO AS crseSubj,
                           csOTRO AS crseCrse,
                           csOTRO AS crseTitl,
                           csOTRO AS stcrMidd,
                           csOTRO AS stcrGrde,
                           csOTRO AS nameFacu,
                           csAst AS colorGrd,
                           vsHoldOT AS holdDesc,
                           csEsp AS termCode
                    FROM DUAL;
                END IF;

        END IF; -- Fin de Nivel

      EXCEPTION
        WHEN OTHERS THEN
          vgsError := SQLERRM;
          RAISE_APPLICATION_ERROR(cn20100,csgetParciales||vgsError);
    END getParciales;

 --getCompParciales
 PROCEDURE getCompParciales(psId VARCHAR2,
                            cuCompParciales OUT type_cursor
                            ) IS

   cnPidm             CONSTANT NUMBER(8)    := f_get_pidm(psId);
   csTermCode         CONSTANT VARCHAR2(6)  := getMaxTermEnrl(cnPidm);
   csGetCompParciales CONSTANT VARCHAR2(18) := 'getCompParciales: ';

   BEGIN
     OPEN cuCompParciales FOR
      select sfrstcr_crn AS cparCrnn,
             SHRGCO.compTipo AS stcrTipo,
             SHRGCO.compDesc AS compDesc,
             SHRGCO.compPond AS compPond,
             NVL(SHRGCO.compGrde,csAst) AS compGrde
        from sfrstcr,
             (select swvcomp_desc||csEsp||shrgcom_seq_no as compDesc,
                     shrgcom_weight as compPond,
                     shrmrks_grde_code as compGrde,
                     shrgcom_crn as compCrnn,
                     decode(swvcomp_tipo,csM,csP,csF) as compTipo,
                     decode(swvcomp_tipo,csM,cn1,cn2) as compOrd1,
                     swvcomp_orden as compOrd2
                from shrmrks,
                     shrgcom,
                     swvcomp
               where shrgcom_id = shrmrks_gcom_id
                 and shrgcom_crn = shrmrks_crn
                 and shrgcom_term_code = shrmrks_term_code
                 and shrgcom_name = swvcomp_code
                 and shrgcom_term_code = csTermCode
                 and shrmrks_pidm = cnPidm
            ) SHRGCO
       where sfrstcr_crn = SHRGCO.compCrnn
         and sfrstcr_rsts_code in (csRE, csRW)
         and sfrstcr_term_code = csTermCode
         and sfrstcr_pidm = cnPidm
    order by sfrstcr_crn,
             SHRGCO.compOrd1,
             SHRGCO.compOrd2;

     EXCEPTION
       WHEN OTHERS THEN
         vgsError := SQLERRM;
         RAISE_APPLICATION_ERROR(cn20100,csGetCompParciales||vgsError);
   END getCompParciales;



/************************************* Comentado por que no se va a desplegar este tipo de baance ******************/
/*************************************
 --getEstadoCuenta
 PROCEDURE getEstadoCuenta(psId VARCHAR2,
                           cuEstadoCuenta OUT type_cursor
                           ) IS

   cnPidm CONSTANT NUMBER(8) := f_get_pidm(psId);
   csGetEstadoCuenta CONSTANT VARCHAR2(17) := 'getEstadoCuenta: ';

   BEGIN

     OPEN cuEstadoCuenta FOR
        select nvl(to_char(estadoCuenta.adeudoSiVencido,cs9_999_99),cs0) AS adeudoSiVenc,
               nvl(to_char(estadoCuenta.adeudoNoVencido,cs9_999_99),cs0) AS adeudoNoVenc,
               nvl(to_char(estadoCuenta.adeudoAfavor,cs9_999_99),cs0) AS adeudoAfavor,
               nvl(to_char((estadoCuenta.adeudoSiVencido+
               estadoCuenta.adeudoNoVencido+
               estadoCuenta.adeudoAfavor
               ) ,cs9_999_99),cs0) AS saldoACuenta,
               nvl(to_char(estadoCuenta.totalPago,cs9_999_99),cs0) AS totalPago,
               nvl(to_char(estadoCuenta.totalCargo,cs9_999_99),cs0) AS totalCargo,
               nvl(to_char(estadoCuenta.totalRecargo,cs9_999_99),cs0) AS totalRecargo
          from (select (select nvl(sum(nvl(twradremb_balance,cn0) + nvl(twradremb_recargo,cn0)), cn0)
                          from twradremb
                         where twradremb_pidm = cnPidm
                           and trunc(twradremb_fecven) < cdTysDate
                       ) AS adeudoSiVencido,
               (select nvl(sum(nvl(tbraccd_balance,cn0)),cn0)
                  from tbraccd,
                       tbbdetc
                 where tbraccd_detail_code = tbbdetc_detail_code
                   and tbraccd_vpdi_code = tbbdetc_vpdi_code
                   and tbbdetc_type_ind = csC
                   and tbraccd_balance <> cn0
                   and trunc(tbraccd_effective_date) >= cdTysDate
                   and tbraccd_pidm = cnPidm
               ) AS adeudoNoVencido,
               (select nvl(sum(nvl(tbraccd_balance,cn0)),cn0)
                  from tbraccd,tbbdetc
                 where tbraccd_detail_code = tbbdetc_detail_code
                   and tbraccd_vpdi_code = tbbdetc_vpdi_code
                   and tbbdetc_type_ind = csP
                   and tbraccd_balance < cn0
                   and tbraccd_pidm = cnPidm
               ) AS adeudoAfavor,
              (select sum(nvl(tbraccd_amount,cn0))
                 from tbraccd,tbbdetc
                where tbraccd_detail_code = tbbdetc_detail_code
                  and tbraccd_vpdi_code = tbbdetc_vpdi_code
                  and tbbdetc_type_ind = csP
                  and tbraccd_pidm = cnPidm
              ) AS totalPago,
              (select sum(nvl(tbraccd_amount,cn0))
                 from tbraccd,tbbdetc
                where tbraccd_detail_code = tbbdetc_detail_code
                  and tbraccd_vpdi_code = tbbdetc_vpdi_code
                  and tbbdetc_type_ind = csC
                  and tbraccd_pidm = cnPidm
             ) AS totalCargo,
             (select sum(nvl(fwacrmb(tbraccd_detail_code, tbraccd_effective_date, tbraccd_balance, tbraccd_srce_code,tbraccd_vpdi_code),cn0))
             from tbraccd
             where tbraccd_pidm = cnPidm
             ) AS totalRecargo
        FROM DUAL
        ) estadoCuenta;

     EXCEPTION
       WHEN OTHERS THEN
         vgsError := SQLERRM;
         RAISE_APPLICATION_ERROR(cn20100,csGetEstadoCuenta||vgsError);
   END getEstadoCuenta;
   
   *************************************************************************************/

/************************************* Comentado por que no se va a desplegar este tipo de baance ******************/
/*************************************
 --getEstadoCuenta
 PROCEDURE getEstadoCuentaVpdi(psId VARCHAR2,
                               cuEstadoCuenta OUT type_cursor
                               ) IS

    cnPidm                 CONSTANT NUMBER(8)    := f_get_pidm(psId);
    csGetEstadoCuentaVpdi CONSTANT VARCHAR2(21) := 'getEstadoCuentaVpdi: ';

    BEGIN

      OPEN cuEstadoCuenta FOR
        SELECT tbracc.VPDI AS vpdi,
               --PK_CATALOGO.UNIVERSIDAD(tbracc.VPDI) AS campDes,
               tbracc.VPDI AS campDes,
               nvl(to_char(adeudoSiVencido.adeudoSiVencido,cs9_999_99),cs0) AS adeudoSiVenc,
               nvl(to_char(adeudoNoVencido.adeudoNoVencido,cs9_999_99),cs0) AS adeudoNoVenc,
               nvl(to_char(adeudoAfavor.adeudoAfavor,cs9_999_99),cs0) AS adeudoAfavor,
               nvl(to_char((nvl(adeudoSiVencido.adeudoSiVencido,cn0)+
               nvl(adeudoNoVencido.adeudoNoVencido,cn0)+
               nvl(adeudoAfavor.adeudoAfavor, cn0)
               ) ,cs9_999_99),cs0) AS saldoACuenta,
               nvl(to_char(totalPago.totalPago,cs9_999_99),cs0) AS totalPago,
               nvl(to_char(totalCargo.totalCargo,cs9_999_99),cs0) AS totalCargo,
               nvl(to_char(totalRecargo.BALANCE,cs9_999_99),cs0) AS totalRecargo
          FROM (select nvl(sum(nvl(twradremb_balance,cn0)
                           + nvl(twradremb_recargo,cn0)), cn0) AS adeudoSiVencido,
                       twradremb_VPDI_CODE AS VPDI
                  from twradremb
                 where twradremb_pidm = cnPidm
                   and trunc(twradremb_fecven) < cdTysDate
              GROUP BY twradremb_VPDI_CODE
               ) adeudoSiVencido,
              (select nvl(sum(nvl(tbraccd_balance,cn0)),cn0) AS adeudoNoVencido,
                      tbraccd_vpdi_code AS VPDI
                 from tbraccd, tbbdetc
                where tbraccd_detail_code = tbbdetc_detail_code
                  and tbraccd_vpdi_code = tbbdetc_vpdi_code
                  and tbbdetc_type_ind = csC
                  and tbraccd_balance <> cn0
                  and trunc(tbraccd_effective_date) >= cdTysDate
                  and tbraccd_pidm = cnPidm
             GROUP BY tbraccd_vpdi_code
              ) adeudoNoVencido,
              (select nvl(sum(nvl(tbraccd_balance,cn0)),cn0) AS adeudoAfavor,
                      tbraccd_vpdi_code AS VPDI
                from tbraccd, tbbdetc
               where tbraccd_detail_code = tbbdetc_detail_code
                 and tbraccd_vpdi_code = tbbdetc_vpdi_code
                 and tbbdetc_type_ind = csP
                 and tbraccd_balance < cn0
                 and tbraccd_pidm = cnPidm
            GROUP BY tbraccd_vpdi_code
             ) adeudoAfavor,
             (select sum(nvl(tbraccd_amount,cn0)) AS totalPago,
                     tbraccd_vpdi_code AS VPDI
                from tbraccd, tbbdetc
               where tbraccd_detail_code = tbbdetc_detail_code
                 and tbraccd_vpdi_code = tbbdetc_vpdi_code
                 and tbbdetc_type_ind = csP
                 and tbraccd_pidm = cnPidm
            GROUP BY tbraccd_vpdi_code
            ) totalPago,
            (select sum(nvl(tbraccd_amount,cn0)) AS totalCargo,
                    tbraccd_vpdi_code AS VPDI
               from tbraccd,tbbdetc
              where tbraccd_detail_code = tbbdetc_detail_code
                and tbraccd_vpdi_code = tbbdetc_vpdi_code
                and tbbdetc_type_ind = csC
                and tbraccd_pidm = cnPidm
           GROUP BY tbraccd_vpdi_code
            ) totalCargo,
            (select sum(nvl(baninst1.fwacrmb(tbraccd_detail_code,
                    tbraccd_effective_date, tbraccd_balance,
                    tbraccd_srce_code,tbraccd_vpdi_code),cn0)) AS BALANCE,
                    tbraccd_vpdi_code AS VPDI
               from tbraccd
              where tbraccd_pidm = cnPidm
           GROUP BY tbraccd_vpdi_code
            ) totalRecargo,
           (select tbraccd_vpdi_code AS VPDI,
                   count(cn1)
              from tbraccd
             where tbraccd_pidm = cnPidm
          group by tbraccd_vpdi_code
           ) tbracc
      WHERE tbracc.VPDI = adeudoNoVencido.VPDI(+)
        AND tbracc.VPDI = adeudoAfavor.VPDI(+)
        AND tbracc.VPDI = totalPago.VPDI(+)
        AND tbracc.VPDI = totalCargo.VPDI(+)
        AND tbracc.VPDI = totalRecargo.VPDI(+)
        AND tbracc.VPDI = adeudoSiVencido.VPDI(+);


      EXCEPTION
        WHEN OTHERS THEN
          vgsError := SQLERRM;
          RAISE_APPLICATION_ERROR(cn20100,csGetEstadoCuentaVpdi||vgsError);
    END getEstadoCuentaVpdi;
    ****************************************************************************/


/************************************* Comentado por que no se va a desplegar este tipo de baance ******************/
/*************************************
 --getAdeudoSiVencido
 PROCEDURE getAdeudoSiVencido(psId VARCHAR2,
                             --psVpdi VARCHAR2,
                             cuEstadoCuenta OUT type_cursor
                             ) IS

   cnPidm               CONSTANT NUMBER(8)    := f_get_pidm(psId);
   csGetAdeudoSiVencido CONSTANT VARCHAR2(20) := 'getAdeudoSiVencido: ';
  --csVpdi CONSTANT VARCHAR2(3) := psVpdi;

   BEGIN
     OPEN cuEstadoCuenta FOR
       select twradremb_term_code AS termCode,
              twradremb_tran_number AS detlTran,
              (select stvterm_desc
                 from stvterm
                where stvterm_code = twradremb_term_code
              ) AS termDesc,
             --PK_CATALOGO.UNIVERSIDAD (twradremb_vpdi_code) AS vpdiDesc,
              twradremb_vpdi_code AS vpdiDesc,
              twradremb_detail_code AS detlCode,
              initcap(twradremb_desc) AS detlDesc,
              to_char(TWRADREMB_BALANCE,cs9_999_99) AS detlAmnt,
              to_char((TWRADREMB_BALANCE+twradremb_recargo),cs9_999_99) AS detlBaln,
              to_char(twradremb_fecven,csDDMMYYYY) AS detlFevn,
              to_char(twradremb_recargo,cs9_999_99) AS detlRecg
       from twradremb
       where trunc(twradremb_fecven) < cdTysDate
       and twradremb_pidm = cnPidm;
     --and twradremb_vpdi_code = csVpdi;

     EXCEPTION
       WHEN OTHERS THEN
        vgsError := SQLERRM;
        RAISE_APPLICATION_ERROR(cn20100,csGetAdeudoSiVencido||vgsError);
   END getAdeudoSiVencido;
   *****************************************************************************/



/************************************* Comentado por que no se va a desplegar este tipo de baance ******************/
/*************************************
 --getAdeudoNoVencido
 PROCEDURE getAdeudoNoVencido(psId VARCHAR2,
                              --psVpdi VARCHAR2,
                              cuEstadoCuenta OUT type_cursor
                              ) IS

  cnPidm               CONSTANT NUMBER(8)    := f_get_pidm(psId);
  csGetAdeudoNoVencido CONSTANT VARCHAR2(20) := 'getAdeudoNoVencido: ';
 --csVpdi CONSTANT VARCHAR2(3) := psVpdi;

  BEGIN
   OPEN cuEstadoCuenta FOR
      select tbraccd_term_code AS termCode,
             tbraccd_tran_number AS detlTran,
             (select stvterm_desc
                from stvterm
               where stvterm_code = tbraccd_term_code
             ) AS termDesc,
             --PK_CATALOGO.UNIVERSIDAD(tbraccd_vpdi_code) AS vpdiDesc,
             tbraccd_vpdi_code AS vpdiDesc,
             tbraccd_detail_code AS detlCode,
             initcap(tbbdetc_desc) AS detlDesc,
             to_char(tbraccd_balance,cs9_999_99) AS detlAmnt,
             to_char(tbraccd_balance,cs9_999_99) AS detlBaln,
             to_char(tbraccd_effective_date,csDDMMYYYY) AS detlFevn,
             tbbdetc_type_ind AS detlType
        from tbraccd, tbbdetc
       where tbbdetc_detail_code = tbraccd_detail_code
         and tbbdetc_vpdi_code = tbraccd_vpdi_code
         and trunc(tbraccd_effective_date) >= cdTysDate
         and tbbdetc_type_ind = csC
         and tbraccd_balance <> cn0
         and tbraccd_pidm = cnPidm;
         --and tbraccd_vpdi_code = csVpdi;

    EXCEPTION
      WHEN OTHERS THEN
        vgsError := SQLERRM;
        RAISE_APPLICATION_ERROR(cn20100,csGetAdeudoNoVencido||vgsError);
  END getAdeudoNoVencido;
  ******************************************************************************/


/************************************* Comentado por que no se va a desplegar este tipo de baance ******************/
/*************************************
 --getDetalleCuenta
 PROCEDURE getDetalleCuenta(psId VARCHAR2,
                            --psVpdi VARCHAR2,
                            cuEstadoCuenta OUT type_cursor
                            ) IS

  cnPidm             CONSTANT NUMBER(8)    := f_get_pidm(psId);
  csGetDetalleCuenta CONSTANT VARCHAR2(18) := 'getDetalleCuenta: ';
 --csVpdi CONSTANT VARCHAR2(3) := psVpdi;

   BEGIN
     OPEN cuEstadoCuenta FOR
        select tbraccd_term_code AS termCode,
               tbraccd_tran_number AS detlTran,
               (select stvterm_desc
                  from stvterm
                 where stvterm_code = tbraccd_term_code
               ) AS termDesc,
              --PK_CATALOGO.UNIVERSIDAD(tbraccd_vpdi_code) AS vpdiDesc,
               tbraccd_vpdi_code AS vpdiDesc,
               tbraccd_detail_code AS detlCode,
               -- rcm 21 mar initcap(tbbdetc_desc) AS detlDesc,
               initcap(tbraccd_desc) AS detlDesc,
               to_char(tbraccd_amount,cs9_999_99) AS detlAmon,
               to_char(tbraccd_balance,cs9_999_99) AS detlBaln,
               to_char(tbraccd_effective_date,csDDMMYYYY) AS detlVenc,
               decode(tbbdetc_type_ind,csP,csPago,
               csC,csCargo) AS detlType,
               tbraccd_srce_code AS detlSrce,
               ttvsrce_desc AS detlSrcd,
               to_char(nvl(fwacrmb(
               tbraccd_detail_code,
               tbraccd_effective_date,
               tbraccd_balance,
               tbraccd_srce_code,
               tbraccd_vpdi_code),cn0),cs9_999_99) AS detlRecg
          from tbraccd, tbbdetc, ttvsrce
         where tbbdetc_detail_code = tbraccd_detail_code
           and tbbdetc_vpdi_code = tbraccd_vpdi_code
           and ttvsrce_code = tbraccd_srce_code
           and tbraccd_pidm = cnPidm
         --and tbraccd_vpdi_code = csVpdi
      order by termCode DESC,detlType,detlVenc DESC;

     EXCEPTION
        WHEN OTHERS THEN
          vgsError := SQLERRM;
          RAISE_APPLICATION_ERROR(cn20100,csGetDetalleCuenta||vgsError);

   END getDetalleCuenta;
   *****************************************************************************/



/************************************* Comentado por que no se va a desplegar este tipo de baance ******************/
/*************************************
 --getPagosPorAplicar
 PROCEDURE getPagosPorAplicar(psId VARCHAR2,
                              --psVpdi VARCHAR2,
                              cuEstadoCuenta OUT type_cursor
                              ) IS

  cnCount NUMBER(8) := 0;

  cnPidm           CONSTANT NUMBER(8)     := f_get_pidm(psId);

  csSEsp           CONSTANT VARCHAR2(1)  := '';
  csSinInformacion CONSTANT VARCHAR2(23) := 'No se tiene información';
  csGetPagos       CONSTANT VARCHAR2(22) := 'getPagos por Aplicar: ';
 --csVpdi CONSTANT VARCHAR2(3) := psVpdi;

  BEGIN

    select count(*) into cnCount
      from tbraccd, tbbdetc
     where tbraccd_detail_code = tbbdetc_detail_code
       and tbraccd_vpdi_code = tbbdetc_vpdi_code
       and tbbdetc_type_ind = csP
       and tbraccd_balance < cn0
       and tbraccd_pidm = cnPidm;
       --and tbraccd_vpdi_code = csVpdi;

    if cnCount > cn0 then
      OPEN cuEstadoCuenta FOR
          select nvl(tbraccd_term_code,csSEsp) AS termCode,
                 nvl(to_char(tbraccd_effective_date, csDDMMYYYY),csSEsp) AS termDesc,
                 --PK_CATALOGO.UNIVERSIDAD(tbraccd_vpdi_code) AS vpdiDesc,
                 tbraccd_vpdi_code AS vpdiDesc,
                 nvl(to_char(tbraccd_balance),csSEsp) AS adAfavor,
                 nvl(tbraccd_desc,csSEsp) AS tranDeta,
                 nvl(to_char(TBRACCD_AMOUNT),csSEsp) AS tranAmou,
                 nvl(to_char(TBRACCD_BALANCE),csSEsp) AS tranBalc
            from tbraccd, tbbdetc
           where tbraccd_detail_code = tbbdetc_detail_code
             and tbraccd_vpdi_code = tbbdetc_vpdi_code
             and tbbdetc_type_ind = csP
             and tbraccd_balance < cn0
             and tbraccd_pidm = cnPidm
           --and tbraccd_vpdi_code = csVpdi
        order by termCode DESC;
    else
      OPEN cuEstadoCuenta FOR
         select csSinInformacion AS termCode,
                csSinInformacion AS termDesc,
                csSinInformacion AS adAfavor,
                csSinInformacion AS tranDeta,
                csSinInformacion AS tranAmou,
                csSinInformacion AS tranBalc
           from dual
       order by termCode DESC;
    end if;

    EXCEPTION
      WHEN OTHERS THEN
       vgsError := SQLERRM;
       RAISE_APPLICATION_ERROR(cn20100,csGetPagos||vgsError);
 END getPagosPorAplicar;
 *******************************************************************************/
 
 

 --muestra la situacion académica del alumno
 --getSituacion
 PROCEDURE getSituacion(psId VARCHAR2,
                        cuSituacion OUT type_cursor
                        ) IS

  cnPidm     CONSTANT NUMBER(8) := f_get_pidm(psId);
  csGetSi    CONSTANT VARCHAR2(14)  := 'getSituacion: ';
  csCredIn   CONSTANT VARCHAR2(100) := 'Creditos inscritos: ';
  csGlobal   CONSTANT VARCHAR2(100) := 'Promedio global: ';
  csPromed   CONSTANT VARCHAR2(100) := 'Promedio por periodo: ';
  csNoDisp   CONSTANT VARCHAR2(100) := 'No disponible';
  csNing     CONSTANT VARCHAR2(100) := 'Ninguna';
  csNingo    CONSTANT VARCHAR2(100) := 'Ninguno';
  csNot      CONSTANT VARCHAR2(3)   := 'not';
  cs00       CONSTANT VARCHAR2(3)   := '0.0';
  cs9999p99  CONSTANT VARCHAR2(10)  := '9999.99';
  cs99p9     CONSTANT VARCHAR2(5)   := '99.99';
  cs10       CONSTANT VARCHAR2(5)    := '10';
  cn10       CONSTANT NUMBER(5,2)    := 10.00;
  csRW       CONSTANT VARCHAR2(3)   := 'RW';
  csRE       CONSTANT VARCHAR2(3)   := 'RE';
  csAS       CONSTANT VARCHAR2(3)   := 'AS';
  csRUA_P    CONSTANT VARCHAR2(5)   := 'RUA_P';
  BEGIN
    OPEN cuSituacion FOR
      -- RCM 07 MAR
      select
      -- rcm 03 mayo 2013
      --NVL(MAX (su1.SGBUSER_TERM_CODE || '-' ||su1.SGBUSER_VPDI_CODE) ,'not' ) as headSitu,
              NVL(MAX (su1.SGBUSER_TERM_CODE) ,csNot ) as headSitu,
              NVL(MAX ( NVL( (select stvsudd_desc from stvsudd where stvsudd_code = su1.sgbuser_sudd_code) , csNoDisp ) ) ,csNot ) siacOUou, --OporUtil
              NVL(MAX ( NVL( (select stvsudc_desc from stvsudc where stvsudc_code = su1.sgbuser_sudc_code) , csNing ) ) ,csNing ) siacRPrp, -- MatRep
              NVL(MAX ( NVL( (select stvsudb_desc from stvsudb where stvsudb_code = su1.sgbuser_sudb_code) , csNoDisp ) ) ,csNot ) siacNIni, -- NivIng
              -----------------------RCM 20 ENE 2014--------------------------------
--              NVL(MAX ( nvl(to_char(trunc((select shrtgpa_gpa
--                                             from shrtgpa
--                                            where shrtgpa_term_code = su1.SGBUSER_TERM_CODE
--                                              and shrtgpa_pidm = su1.SGBUSER_PIDM ),cn2 ),cs9999p99),cs00) ) ,csNot ) promTerm, --PromedioPeriodo,
              ----rcm 20 enero 2014 ------------------------------------------------
              NVL(MAX ( NVL ( ( SELECT
                              DECODE(NVL(TO_CHAR(TRUNC(A.SHRTGPA_GPA,cn2),cs99p9),csEsp),cn10,cs10, cn0,cs0, NVL(TO_CHAR(TRUNC(A.SHRTGPA_GPA,cn2),cs99p9),csEsp)  )
                              FROM SHRTGPA A
                              WHERE A.SHRTGPA_GPA_TYPE_IND = csI
                              AND A.SHRTGPA_PIDM = su1.SGBUSER_PIDM
                              and A.SHRTGPA_TERM_CODE =  su1.SGBUSER_TERM_CODE
                                                       --(select max(A2.SHRTGPA_TERM_CODE)
                                                       --FROM SHRTGPA A2 WHERE A2.SHRTGPA_GPA_TYPE_IND = A.SHRTGPA_GPA_TYPE_IND
                                                       --AND A2.SHRTGPA_PIDM = A.SHRTGPA_PIDM)
                              ),cs00) ) ,csNot ) promTerm, --PromedioPeriodo,
              ----------------------------------------------------------------------
              --rcm 20 ene 2014-----------------------------------------------------
              --NVL(MAX ( nvl((select to_char ( trunc(sum(shrtgpa_gpa*shrtgpa_gpa_hours)/
              --                      decode(sum(shrtgpa_gpa_hours),cn0,cn1,sum(shrtgpa_gpa_hours) )
              --                      ,cn2),cs9999p99)
              --                 from shrtgpa
              --                where shrtgpa_pidm = su1.SGBUSER_PIDM ),cs00) ) ,csNot ) promGlob, --PromGlob,
              ---------------------------------------------------------------------------------------------------------
              NVL(MAX ( nvl((select
                 NVL(
                 (SELECT
                              decode(
                                TRUNC( DECODE(SUM(b.SHRTGPA_GPA_HOURS), cn0, cn0, SUM(b.SHRTGPA_QUALITY_POINTS) / SUM(b.SHRTGPA_GPA_HOURS)), cn2)
                                , cn10 , cs10,
                                to_char(TRUNC( DECODE(SUM(b.SHRTGPA_GPA_HOURS), cn0, cn0, SUM(b.SHRTGPA_QUALITY_POINTS) / SUM(b.SHRTGPA_GPA_HOURS)), cn2),cs99p9)
                                      )
                              from shrtgpa b
                             where   b.SHRTGPA_PIDM       = A3.SHRTGPA_PIDM
                               AND   b.SHRTGPA_LEVL_CODE  = A3.SHRTGPA_LEVL_CODE
                               AND   b.SHRTGPA_TERM_CODE <= A3.SHRTGPA_TERM_CODE
                               AND   b.SHRTGPA_GPA_TYPE_IND = csI
                        )
                     ,csEsp )
              FROM SHRTGPA A3
                              WHERE A3.SHRTGPA_GPA_TYPE_IND = csI
                                AND A3.SHRTGPA_PIDM = su1.SGBUSER_PIDM
                                AND A3.SHRTGPA_TERM_CODE =  su1.SGBUSER_TERM_CODE
               ) ,cs00) ) ,csNot ) promGlob,
              ---------------------------------------------------------------------------------------------------------
              NVL(MAX ( NVL( (select stvsude_desc
                                from stvsude
                               where stvsude_code = su1.sgbuser_sude_code) , csNoDisp ) ) ,csNot ) porcAvan, --PorAvan,
              NVL(MAX ( (SELECT NVL(TO_CHAR(SUM(SFRSTCR_CREDIT_HR), cs9999p99),cs00)
                           FROM SFRSTCR
                          WHERE SFRSTCR_RSTS_CODE IN (csRW,csRE)
                            AND SFRSTCR_TERM_CODE = su1.SGBUSER_TERM_CODE
                            AND SFRSTCR_PIDM = su1.SGBUSER_PIDM
                            -- vpdi AND SFRSTCR_VPDI_CODE = su1.SGBUSER_VPDI_CODE  
                            ) ) ,csNot ) credInsc, --CredInsc,
              NVL(MAX ( nvl ( (select (select stvastd_desc
                                         from stvastd
                                        where stvastd_code = shrttrm_astd_code_end_of_term)
                                 from shrttrm
                                where shrttrm_term_code = su1.SGBUSER_TERM_CODE
                                  and shrttrm_pidm = su1.SGBUSER_PIDM), csNingo) ) ,csNot ) estnAcdm --EstAcad
       FROM SGBUSER su1       --, sgbstdn A
      WHERE su1.SGBUSER_PIDM = cnPidm
        and su1.sgbuser_term_code =  (select max(A2.SHRTGPA_TERM_CODE)  --rcm 20 ene 2014
                                                       FROM SHRTGPA A2 WHERE A2.SHRTGPA_GPA_TYPE_IND = csI
                                                       AND A2.SHRTGPA_PIDM = su1.SGBUSER_PIDM);
                                  -- (select max(su2.sgbuser_term_code)
                                  --     from sgbuser su2
                                  --    where su2.sgbuser_pidm = su1.sgbuser_pidm
                                  --  )
      -----------------------------------------------------------
--rcm 30 ene      and SU1.sgbuser_pidm =  a.sgbstdn_pidm
-- rcm 30 ene     and a.sgbstdn_term_code_eff = (select max(A2.SHRTGPA_TERM_CODE)  --rcm 28 ene 2014
--                                                       FROM SHRTGPA A2 WHERE A2.SHRTGPA_GPA_TYPE_IND = csI
--                                                       AND A2.SHRTGPA_PIDM = su1.SGBUSER_PIDM)
--                                    (select max(b.sgbstdn_term_code_eff)
--                                       from sgbstdn b
--                                      where b.sgbstdn_pidm = a.sgbstdn_pidm
--                                        and b.sgbstdn_vpdi_code = a.sgbstdn_vpdi_code
--                                        and b.sgbstdn_stst_code = csAS
--                                        and b.sgbstdn_vpdi_code <> csRUA_P
--                                     )
      --rcm 30 eneand SU1.sgbuser_vpdi_code = a.sgbstdn_vpdi_code
--      and a.sgbstdn_stst_code = csAS
      --rcm 30 ene and a.sgbstdn_vpdi_code <> csRUA_P;

      EXCEPTION
         WHEN OTHERS THEN
           vgsError := SQLERRM;
           RAISE_APPLICATION_ERROR(cn20100,csGetSi||vgsError);
  END getSituacion;

         /** rcm 06 mar
          su1.SGBUSER_TERM_CODE || '-' ||su1.SGBUSER_VPDI_CODE as headSitu,
         NVL( (select stvsudd_desc from stvsudd where stvsudd_code = su1.sgbuser_sudd_code) , 'N/A' ) siacOUou, --OporUtil
         NVL( (select stvsudc_desc from stvsudc where stvsudc_code = su1.sgbuser_sudc_code) , 'N/A' ) siacRPrp, -- MatRep
         NVL( (select stvsudb_desc from stvsudb where stvsudb_code = su1.sgbuser_sudb_code) , 'N/A' ) siacNIni, -- NivIng
         nvl(to_char(trunc((select shrtgpa_gpa from shrtgpa where shrtgpa_term_code = su1.SGBUSER_TERM_CODE and shrtgpa_pidm = su1.SGBUSER_PIDM ),2 ),'9999.99'),'0.0') promTerm, --PromedioPeriodo,
         nvl((select to_char ( trunc(sum(shrtgpa_gpa*shrtgpa_gpa_hours)/sum(shrtgpa_gpa_hours),2),'9999.99') from shrtgpa where shrtgpa_pidm = su1.SGBUSER_PIDM ),'0.0') promGlob, --PromGlob,
         NVL( (select stvsude_desc from stvsude where stvsude_code = su1.sgbuser_sude_code) , 'N/A' ) porcAvan, --PorAvan,
          (SELECT NVL(TO_CHAR(SUM(SFRSTCR_CREDIT_HR), '9999.99'),'0.0') FROM SFRSTCR WHERE SFRSTCR_RSTS_CODE IN ('RW','RE') AND SFRSTCR_TERM_CODE = su1.SGBUSER_TERM_CODE AND SFRSTCR_PIDM = su1.SGBUSER_PIDM AND SFRSTCR_VPDI_CODE = su1.SGBUSER_VPDI_CODE) credInsc, --CredInsc,
         nvl ( (select (select stvastd_desc from stvastd where stvastd_code = shrttrm_astd_code_end_of_term) from shrttrm where shrttrm_term_code = su1.SGBUSER_TERM_CODE and shrttrm_pidm = su1.SGBUSER_PIDM), 'N/A') estnAcdm --EstAcad

         select --SGBUSER_PIDM, SGBUSER_TERM_CODE, SGBUSER_VPDI_CODE,
         SGBUSER_TERM_CODE || '-' ||SGBUSER_VPDI_CODE as headSitu,
         (select stvsudd_desc from stvsudd where stvsudd_code = sgbuser_sudd_code) siacOUou, --OporUtil
         (select stvsudc_desc from stvsudc where stvsudc_code = sgbuser_sudc_code) siacRPrp, -- MatRep
          (select stvsudb_desc from stvsudb where stvsudb_code = sgbuser_sudb_code) siacNIni, -- NivIng
         nvl(to_char(trunc((select shrtgpa_gpa from shrtgpa where shrtgpa_term_code = SGBUSER_TERM_CODE and shrtgpa_pidm = SGBUSER_PIDM ),2 ),'9999.99'),'0.0') promTerm, --PromedioPeriodo,
         nvl((select to_char ( trunc(sum(shrtgpa_gpa*shrtgpa_gpa_hours)/sum(shrtgpa_gpa_hours),2),'9999.99') from shrtgpa where shrtgpa_pidm = SGBUSER_PIDM ),'0.0') promGlob, --PromGlob,
          (select stvsude_desc from stvsude where stvsude_code = sgbuser_sude_code) porcAvan, --PorAvan,
          (SELECT NVL(TO_CHAR(SUM(SFRSTCR_CREDIT_HR), '9999.99'),'0.0') FROM SFRSTCR WHERE SFRSTCR_RSTS_CODE IN ('RW','RE') AND SFRSTCR_TERM_CODE = SGBUSER_TERM_CODE AND SFRSTCR_PIDM = SGBUSER_PIDM AND SFRSTCR_VPDI_CODE = SGBUSER_VPDI_CODE) credInsc, --CredInsc,
         (select (select stvastd_desc from stvastd where stvastd_code = shrttrm_astd_code_end_of_term) from shrttrm where shrttrm_term_code = SGBUSER_TERM_CODE and shrttrm_pidm = SGBUSER_PIDM) estnAcdm --EstAcad
         FROM SGBUSER
         WHERE SGBUSER_PIDM = 126078
         AND SGBUSER_TERM_CODE = 201260
         AND SGBUSER_VPDI_CODE = 'UAN';
         **/
          /** rcm
          SELECT sgbuse.optUti AS siacOUou,
          sgbuse.matrep AS siacRPrp,
          sgbuse.nvlIng AS siacNIni,
          nvl(csPromed||
          to_char(trunc((select shrtgpa_gpa
          from shrtgpa
          where shrtgpa_term_code = (select max(shrtgpa_term_code)
          from shrtgpa
          where shrtgpa_pidm = cnPidm
          )
          and shrtgpa_pidm = cnPidm
          ),cn2
          ),cs99p99
          ),csEsp
          ) AS promTerm, --Promedio por periodo
          nvl(csGlobal||
          to_char((select trunc(sum(shrtgpa_gpa*shrtgpa_gpa_hours)/sum(shrtgpa_gpa_hours),cn2)
          from shrtgpa
          where shrtgpa_pidm = cnPidm
          ),cs99p99
          ),csEsp
          ) AS promGlob, --Promedio Global
          sgbuse.prcAvn AS porcAvan,
          nvl(csCredIn||
          to_char((select sum(nvl(sfrstcr_credit_hr,cn0))
          from sfrstcr
          where sfrstcr_rsts_code in (csRW,csRE)
          and sfrstcr_term_code = (select max(sfrstcr_term_code)
          from sfrstcr
          where sfrstcr_rsts_code in (csRW,csRE)
          and sfrstcr_pidm = cnPidm
          and sfrstcr_term_code <> cs999998
          and sfrstcr_term_code <> cs999997
          and sfrstcr_term_code <> cs999996
          )
          and sfrstcr_pidm = cnPidm
          )
          ),csEsp
          ) AS credInsc, --Créditos inscritos
          nvl((select (select stvastd_desc
          from stvastd
          where stvastd_code = shrttrm_astd_code_end_of_term
          )
          from shrttrm
          where shrttrm_term_code = (select max(shrttrm_term_code)
          from shrttrm
          where shrttrm_pidm = cnPidm
          )
          and shrttrm_pidm = cnPidm
          ),csEsp
          ) AS estnAcdm--Estándar académico
          FROM (select nvl((select stvsudd_desc
          from stvsudd
          where stvsudd_code = sgbuser_sudd_code
          ),csEsp
          ) as optUti, --Oportunidades utilizadas
          nvl((select stvsudc_desc
          from stvsudc
          where stvsudc_code = sgbuser_sudc_code
          ),csEsp
          ) as matrep, --Materias reprobadas
          nvl((select stvsudb_desc
          from stvsudb
          where stvsudb_code = sgbuser_sudb_code
          ),csEsp
          ) as nvlIng,-- Nivel de Inglés
          nvl((select stvsude_desc
          from stvsude
          where stvsude_code = sgbuser_sude_code
          ),csEsp
          ) as prcAvn --% de Avance
          from sgbuser
          where sgbuser_term_code = (select max(sgbuser_term_code)
          from sgbuser
          where sgbuser_pidm = cnPidm
          )
          and sgbuser_pidm = cnPidm
          ) sgbuse;

          **/



--getRetenciones
 PROCEDURE getRetenciones(psId VARCHAR2,
                          cuRetenciones OUT type_cursor
                          ) IS

  csNot  CONSTANT VARCHAR2(3) := 'not';
  csGetR CONSTANT VARCHAR2(16):= 'getRetenciones: ';
  cnPidm CONSTANT NUMBER(8)   := F_GET_PIDM(psId);


  BEGIN

    OPEN cuRetenciones FOR
      SELECT STVHLDD_DESC AS holdDesc,
             TO_CHAR(SPRHOLD_FROM_DATE,csDDMMYYYY) fInicio,
             TO_CHAR(SPRHOLD_TO_DATE ,csDDMMYYYY) fFin
        FROM STVHLDD, SPRHOLD
       WHERE SPRHOLD_PIDM = cnPidm --165950 --165950--cnPidm
         AND STVHLDD_CODE = SPRHOLD_HLDD_CODE
         and trunc(SPRHOLD_FROM_DATE) <= trunc(sysdate) -- rcm 28
         and trunc(SPRHOLD_TO_DATE) >= trunc(sysdate)
      --and rownum < 1
   union all
      SELECT csNot AS holdDesc,
             TO_CHAR(SYSDATE, csDDMMYYYY) fInicio,
             TO_CHAR(SYSDATE, csDDMMYYYY) fFin
        FROM dual
       where not exists (
             SELECT cn1
               FROM STVHLDD, SPRHOLD
              WHERE SPRHOLD_PIDM = cnPidm --165950 --178558--cnPidm
                AND STVHLDD_CODE = SPRHOLD_HLDD_CODE
                and trunc(SPRHOLD_FROM_DATE) <= trunc(sysdate) -- rcm 28
                and trunc(SPRHOLD_TO_DATE) >= trunc(sysdate)
             );


        /** RCM 12

        SELECT STVHLDD_DESC AS holdDesc,
        TO_CHAR(SPRHOLD_FROM_DATE,csDDMMYYYY) fInicio,
        TO_CHAR(SPRHOLD_TO_DATE ,csDDMMYYYY) fFin
        FROM STVHLDD, SPRHOLD
        WHERE SPRHOLD_PIDM = cnPidm
        AND STVHLDD_CODE = SPRHOLD_HLDD_CODE
        and trunc(SPRHOLD_FROM_DATE) <= trunc(sysdate) -- rcm 28
        and trunc(SPRHOLD_TO_DATE) >= trunc(sysdate);

        **/
       EXCEPTION
         WHEN OTHERS THEN
           vgsError := SQLERRM;
           RAISE_APPLICATION_ERROR(cn20100,csGetR||vgsError);
           commit;
 END getRetenciones;


--getPerfiles
 PROCEDURE getPerfiles(psId VARCHAR2,
                       cuPerfiles OUT type_cursor
                       ) IS

  cnPidm CONSTANT NUMBER(8) := F_GET_PIDM(psId);
  cn3    CONSTANT NUMBER(1) := 3;
  csPR   CONSTANT VARCHAR2(2) := 'PR';
  csN    CONSTANT VARCHAR2(7) := 'Ninguno';
  csH    CONSTANT VARCHAR2(4) := 'HOLD';
  csPERS CONSTANT VARCHAR2(4) := 'PERS';
  csGetP CONSTANT VARCHAR2(13):= 'getPerfiles: ';
  csAS       CONSTANT VARCHAR2(3)   := 'AS';
  BEGIN



     --el alumno consulta su PERFIL --RCM 24 OCT 2012
     --agregar 3 campos adicionales --RCM 16 ABR 2013
     OPEN cuPerfiles FOR
        SELECT
               SPRIDEN_ID crseCrnn, --Matricola,
               -- rcm 03 may SPRIDEN_FIRST_NAME || ' ' || SPRIDEN_LAST_NAME crseSubj, --Studente,
               REPLACE(SPRIDEN_FIRST_NAME||csEsp||SPRIDEN_LAST_NAME,csAst,csEsp) crseSubj, --Studente,
               f.SGBSTDN_TERM_CODE_EFF crseCrse, --Periodo,
               (SELECT STVLEVL_DESC FROM STVLEVL WHERE STVLEVL_CODE = f.SGBSTDN_LEVL_CODE ) crseTitl, --Livello,
               f.SGBSTDN_PROGRAM_1 stcrMidd, --Programma,
               (SELECT STVMAJR_DESC FROM STVMAJR WHERE STVMAJR_CODE = f.SGBSTDN_MAJR_CODE_1) stcrGrde, --Major,
               (SELECT STVSTST_DESC FROM STVSTST WHERE STVSTST_CODE = f.SGBSTDN_STST_CODE) nameFacu, --Status,
               (SELECT STVSTYP_DESC FROM STVSTYP WHERE STVSTYP_CODE = f.SGBSTDN_STYP_CODE) colorGrd, --Tipo_Studente,
               NVL((SELECT STVADMT_DESC FROM STVADMT WHERE STVADMT_CODE = f.SGBSTDN_ADMT_CODE),csH) holdDesc, --Tipo_Ingresso
               ----------------------------------------------------------------------------------------------------------------------
               (select NVL ( MAX ( TRIM( SPRTELE_PHONE_AREA||csEsp||SPRTELE_PHONE_NUMBER||csEsp||SPRTELE_PHONE_EXT ) ) , csN)
                  from SPRTELE T1
                 where SPRTELE_PIDM(+) = SPRIDEN_PIDM
                   and SPRTELE_TELE_CODE(+) = csPR ) telefono,
               ----------------------------------------------------------------------------------------------------------------------
               (select NVL ( MAX ( TRIM( G1.GOREMAL_EMAIL_ADDRESS ) ) , csN)
                  from GOREMAL G1
                 where G1.GOREMAL_PIDM(+) = SPRIDEN_PIDM
                   and G1.GOREMAL_EMAL_CODE(+) = csPERS ) correo,
               ----------------------------------------------------------------------------------------------------------------------
               (select NVL ( MAX ( TRIM( SP.SPRADDR_STREET_LINE1||csEsp||SP.SPRADDR_STREET_LINE2 ||csEsp|| SP.SPRADDR_STREET_LINE3 ) ) , csN)
                  from SPRADDR SP
                 where SP.SPRADDR_PIDM(+) = SPRIDEN_PIDM
                   AND SP.SPRADDR_ATYP_CODE(+) = csPR
                   AND NVL(SP.SPRADDR_SEQNO,cn1) = DECODE (SP.SPRADDR_SEQNO, NULL,cn1,
                                                        (SELECT MAX(SP1.SPRADDR_SEQNO)
                                                           FROM SPRADDR SP1
                                                          WHERE SP1.SPRADDR_PIDM = SP.SPRADDR_PIDM
                                                            AND SP1.SPRADDR_ATYP_CODE = SP.SPRADDR_ATYP_CODE
                                                        ) ) ) direccion
               ----------------------------------------------------------------------------------------------------------------------
          FROM SPRIDEN, SGBSTDN F
         WHERE SPRIDEN_CHANGE_IND IS NULL
           AND SPRIDEN_PIDM = F.SGBSTDN_PIDM
           AND F.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(B.SGBSTDN_TERM_CODE_EFF) -- rcm 16 abril 3 registros
                                            FROM SGBSTDN B
                                           WHERE B.SGBSTDN_PIDM = f.SGBSTDN_PIDM
                                             --AND B.SGBSTDN_STST_CODE = csAS
                                             )
                                             AND SPRIDEN_PIDM = cnPidm
                                             AND ROWNUM = cn1
--                                             AND f.sgbstdn_vpdi_code = (SELECT swrstud_camp_code
--                                                                          FROM swrstud
--                                                                         WHERE swrstud_seqn = (SELECT MAX(swrstud_seqn)
--                                                                                                 FROM swrstud
--                                                                                                WHERE swrstud_pidm = f.sgbstdn_pidm
--                                                                                              )
--
--                                                                           AND swrstud_pidm = f.sgbstdn_pidm
--                                                                           AND ROWNUM = cn1
--                                                                        )
      order by cn3 desc;

     EXCEPTION
        WHEN OTHERS THEN
          vgsError := SQLERRM;
          RAISE_APPLICATION_ERROR(cn20100,csGetP||vgsError);
 END getPerfiles;



/************************************* Comentado por que no se va a desplegar este tipo de baance ******************/
/*************************************
--getEventos RCM enero 2014
 PROCEDURE getEventos(psId VARCHAR2,
                       cuEventos OUT type_cursor
                       ) IS

  cnPidm CONSTANT NUMBER(8) := F_GET_PIDM(psId);
  cn3    CONSTANT NUMBER(1) := 3;
  cn7    CONSTANT NUMBER(1) := 7;
  csPR   CONSTANT VARCHAR2(2) := 'PR';
  csAl   CONSTANT VARCHAR2(2) := 'al';
  csRED  CONSTANT VARCHAR2(3) := 'RED';
  csALL   CONSTANT VARCHAR2(3) := 'ALL';
  csANA   CONSTANT VARCHAR2(50) := 'Red de Universidades An&aacute;huac';
  csNode   CONSTANT VARCHAR2(30) := 'Campus No declarado';
  csN    CONSTANT VARCHAR2(7) := 'Ninguno';
  csH    CONSTANT VARCHAR2(4) := 'HOLD';
  csPERS CONSTANT VARCHAR2(4) := 'PERS';
  csGetP CONSTANT VARCHAR2(13):= 'getEventos: ';
  csAS       CONSTANT VARCHAR2(3)   := 'AS';
  BEGIN



     --el alumno consulta sus Eventos --RCM 30 de enero de 2014

     OPEN cuEventos FOR
        SELECT
          to_char(SWEVENT_FECHA_INICIO,'dd/mm/yyyy')         vsFecInicio,
          initcap(to_char(SWEVENT_FECHA_INICIO,'day'))       vsDiaFecInicio,
          SWEVENT_ASUNTO                                     vsAsunto,
          --substr(SWEVENT_ASUNTO,1,50) || '...'               crseSubj,
          SWEVENT_UBICACION_EVENTO                           vsUbiEvento,
          SWEVENT_DETALLE_EVENTO                             vsDetEvento,
          --SWEVENT_CLAVE          ,
          --(SELECT STVCAMP_DESC FROM STVCAMP WHERE STVCAMP_CODE = SWEVENT_CAMPUS)  vsCampus,
          decode(SWEVENT_CAMPUS, csRED, csANA, csALL, csANA, (SELECT nvl(max(STVCAMP_DESC), csNODE) FROM STVCAMP WHERE STVCAMP_CODE = SWEVENT_CAMPUS) )  vsCampus,
          --SWEVENT_PRIORIDAD         crseCrnn,
          replace(to_char(SWEVENT_FECHA_INICIO,'dd-month-yyyy'), ' ' , '') || ' '||csAl|| ' ' || replace(to_char(SWEVENT_FECHA_FIN,'dd-month-yyyy'), ' ' , '')    vsRangoFecha,
          SWEVENT_HORA_INICIO || ' - ' || SWEVENT_HORA_FIN   vsRangoHora,
          SWEVENT_ORGANIZA          vsOrganiza,
          SWEVENT_UBICACION_CONTACTO vsUbicacionContacto,
          SWEVENT_TELEFONO          vsTelefono,
          SWEVENT_CORREO            vsCorreo,
          SWEVENT_LIGA_EVENTO       vsLiga
          FROM SWEVENT
          where
                  trunc(sysdate) >= trunc(SWEVENT_FECHA_INICIO - cn7)
              and trunc(sysdate) <= trunc(SWEVENT_FECHA_FIN)
              and SWEVENT_CAMPUS in (  select csRED campus from dual  union all select csALL campus from dual
                                        union all
                                        select s1.SGBSTDN_VPDI_CODE from SGBSTDN s1 where s1.SGBSTDN_PIDM = cnPidm
                                        --and s1.SGBSTDN_STST_CODE = csAS
                                        and s1.SGBSTDN_TERM_CODE_EFF = (  select max(s2.SGBSTDN_TERM_CODE_EFF)
                                                                       from SGBSTDN s2
                                                                       where
                                                                              s2.SGBSTDN_PIDM = s1.SGBSTDN_PIDM
                                                                          --and s2.SGBSTDN_STST_CODE = csAS
                                                                       )
                                        )
          ORDER BY 1;


     EXCEPTION
        WHEN OTHERS THEN
          vgsError := SQLERRM;
          RAISE_APPLICATION_ERROR(cn20100,csGetP||vgsError);
 END getEventos;
 *******************************************************************************/


--
----getEventos RCM enero 2014
-- PROCEDURE getEventoDetalle(psId VARCHAR2,
--                       cuEventos OUT type_cursor
--                       ) IS
--
--  cnPidm CONSTANT NUMBER(8) := F_GET_PIDM(psId);
--  cn3    CONSTANT NUMBER(1) := 3;
--  csPR   CONSTANT VARCHAR2(2) := 'PR';
--  csN    CONSTANT VARCHAR2(7) := 'Ninguno';
--  csH    CONSTANT VARCHAR2(4) := 'HOLD';
--  csPERS CONSTANT VARCHAR2(4) := 'PERS';
--  csGetP CONSTANT VARCHAR2(13):= 'getEventos: ';
--  csAS       CONSTANT VARCHAR2(3)   := 'AS';
--  BEGIN
--
--
--
--     --el alumno consulta sus Eventos --RCM 30 de enero de 2014
--
--     OPEN cuEventos FOR
--        SELECT
--          to_char(SWEVENT_FECHA_REGISTRO,'dd-mm-yyyy')      crseTitl,
--          initcap( to_char(SWEVENT_FECHA_REGISTRO,'day') )  crseCrnn,
--          --SWEVENT_CLAVE          ,
--          SWEVENT_CAMPUS || ' - ' ||SWEVENT_CLAVE  crseCrse,
--          --SWEVENT_PRIORIDAD         crseCrnn,
--          substr(SWEVENT_ASUNTO,1,40) || '...'            crseSubj,
--          SWEVENT_UBICACION_EVENTO         stcrGrde,
--          to_char(SWEVENT_FECHA_INICIO,'dd-mm-yyyy') || ' ' || SWEVENT_HORA_INICIO      stcrMidd,
--          to_char(SWEVENT_FECHA_FIN,'dd-mm-yyyy') || ' ' || SWEVENT_HORA_FIN          nameFacu,
--          SWEVENT_LIGA_EVENTO       colorGrd,
--          SWEVENT_DETALLE_EVENTO    holdDesc,
--          SWEVENT_ORGANIZA          telefono,
--          SWEVENT_TELEFONO          correo,
--          SWEVENT_CORREO            direccion
--          --
--          --SWEVENT_USUARIO_REGISTRO
--          FROM SWEVENT
--          ORDER BY 1, 2,3;
--
--
--     EXCEPTION
--        WHEN OTHERS THEN
--          vgsError := SQLERRM;
--          RAISE_APPLICATION_ERROR(cn20100,csGetP||vgsError);
-- END getEventoDetalle;
--



/************************************* Comentado por que no se va a desplegar este tipo de baance ******************/
/*************************************
--getNoticias RCM febrero 2014
 PROCEDURE getNoticias(psId VARCHAR2,
                       cuNoticias OUT type_cursor
                       ) IS

  cnPidm CONSTANT NUMBER(8) := F_GET_PIDM(psId);
  cn3    CONSTANT NUMBER(1) := 3;
  csPR   CONSTANT VARCHAR2(2) := 'PR';
  csRED   CONSTANT VARCHAR2(3) := 'RED';
  csALL   CONSTANT VARCHAR2(3) := 'ALL';
  csANA   CONSTANT VARCHAR2(50) := 'Red de Universidades An&aacute;huac';
  csNode   CONSTANT VARCHAR2(30) := 'Campus No declarado';
  csN    CONSTANT VARCHAR2(7) := 'Ninguno';
  csH    CONSTANT VARCHAR2(4) := 'HOLD';
  csPERS CONSTANT VARCHAR2(4) := 'PERS';
  csGetP CONSTANT VARCHAR2(13):= 'getNoticias: ';
  csAS   CONSTANT VARCHAR2(3) := 'AS';
  BEGIN

     --el alumno consulta sus Noticias --RCM Febrero de 2014

     OPEN cuNoticias FOR
       SELECT
            SWNOTIC_ASUNTO    vsAsunto,
            (select substr(SWCATEG_DESCRIPCION,1,50) from SWCATEG where SWCATEG_CLAVE = SWNOTIC_CATEGORIA ) vsCategoria,
            initcap( to_char(SWNOTIC_FECHA_NOTICIA,'day')) || ' ' || replace(to_char(SWNOTIC_FECHA_NOTICIA,'dd-month-yyyy'), ' ' , '')  vsFechaNoticia,
            --(SELECT STVCAMP_DESC FROM STVCAMP WHERE STVCAMP_CODE = SWNOTIC_CAMPUS)  vsCampus,
decode(SWNOTIC_CAMPUS, csRED, csANA, csALL, csANA, (SELECT nvl(max(STVCAMP_DESC), csNode) FROM STVCAMP WHERE STVCAMP_CODE = SWNOTIC_CAMPUS) )  vsCampus,
            SWNOTIC_DETALLE_NOTICIA vsDetalleNoticia,
            SWNOTIC_VIGENCIA_INICIO vsVigenciaInicio,
            SWNOTIC_VIGENCIA_FIN    vsVigenciaFin,
            SWNOTIC_CONTACTO_ORGANIZA vsContacto,
            SWNOTIC_UBICACION_CONTACTO vsUbicacion,
            SWNOTIC_TELEFONO_CONTACTO vsTelefono,
            SWNOTIC_CORREO_CONTACTO vsCorreo,
            SWNOTIC_LIGA_NOTICIA vsLiga,
            SWNOTIC_FECHA_REGISTRO vsFechaRegistro,
            SWNOTIC_CLAVE vsClave,
            SWNOTIC_PRIORIDAD vsPrioridad,
            SWNOTIC_USUARIO_REGISTRO vsUsuario
          FROM SWNOTIC
             where
                  trunc(sysdate) >= trunc(SWNOTIC_VIGENCIA_INICIO)
              and trunc(sysdate) <= trunc(SWNOTIC_VIGENCIA_FIN)
              and SWNOTIC_CAMPUS in (  select csRED campus from dual union all select csALL campus from dual
                                        union all
                                        select s1.SGBSTDN_VPDI_CODE from SGBSTDN s1 where s1.SGBSTDN_PIDM = cnPidm
                                        --and s1.SGBSTDN_STST_CODE = csAS
                                        and s1.SGBSTDN_TERM_CODE_EFF = (  select max(s2.SGBSTDN_TERM_CODE_EFF)
                                                                       from SGBSTDN s2
                                                                       where
                                                                              s2.SGBSTDN_PIDM = s1.SGBSTDN_PIDM
                                                                          --and s2.SGBSTDN_STST_CODE = csAS
                                                                       )
                                        )
          ORDER BY SWNOTIC_CATEGORIA, SWNOTIC_FECHA_NOTICIA;


     EXCEPTION
        WHEN OTHERS THEN
          vgsError := SQLERRM;
          RAISE_APPLICATION_ERROR(cn20100,csGetP||vgsError);
 END getNoticias;
 *******************************************************************************/


END kwamobil;
/
CREATE OR REPLACE PROCEDURE BANINST1.PWRASAL(psReclDesc VARCHAR2) IS
/**************************************************************
           tarea:  procedimiento para el reporte de asignacion de salas
         módulo:  reportes -asignacion academica
           autor:
           fecha:
    ------------------------------------
    Modificacion :   chg-01  16/jul/2013
          cambio :   se agregan columna(escuela) y se cambia orden segregando veticalmente los horarios.
           autor :   RRA - Roman ruiz

**************************************************************/
  vnExists    INTEGER                := 0;
  vnColumnas  INTEGER                := 21;
  tabColumna  Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla(1);
  vsCampCode  VARCHAR2(6)            := NULL;
  vsTermCode  VARCHAR2(1000)         := NULL;
  vsTerm      VARCHAR2(8)            := NULL;
  vsCollCode  VARCHAR2(3)            := NULL;
  vsSubjCode  VARCHAR2(4)            := NULL;
  vsSstsCode  VARCHAR2(2)            := NULL;
  vsPtrmCode  VARCHAR2(1000)         := NULL;
  vsBldgCode  VARCHAR2(50)           := NULL;
  vsStarDate  VARCHAR2(50)           := NULL;
  vsEnddDate  VARCHAR2(50)           := NULL;
  vsFstpCode  VARCHAR2(50)           := NULL;
  vsInicoPag  VARCHAR2(10)           := NULL;
  vsXlstType  VARCHAR2(2)            := NULL;
  vsFattCode  VARCHAR2(10)           := NULL;
  vsSeccion   VARCHAR2(3)            := NULL;
  vsExp       VARCHAR2(15)           := NULL;
  vsBecadef   VARCHAR2(1)            :=NULL;
  vnIngresado VARCHAR2(300);
  vnIngresadoDef VARCHAR2(300);
  -- Año Académico
  vsAcyr      VARCHAR2(10);
  global_pidm SPRIDEN.SPRIDEN_PIDM%TYPE;


  csAC      CONSTANT VARCHAR2(2)  := 'AC';
  csEsp     CONSTANT VARCHAR2(1)  := ' ';
  csM       CONSTANT VARCHAR2(1)  := 'M';
  csT       CONSTANT VARCHAR2(1)  := 'T';
  csW       CONSTANT VARCHAR2(1)  := 'W';
  csR       CONSTANT VARCHAR2(1)  := 'R';
  csF       CONSTANT VARCHAR2(1)  := 'F';
  csS       CONSTANT VARCHAR2(1)  := 'S';
  csP       CONSTANT VARCHAR2(1)  := 'P';
  csLu      CONSTANT VARCHAR2(2)  := 'Lu';
  csMa      CONSTANT VARCHAR2(2)  := 'Ma';
  csMi      CONSTANT VARCHAR2(2)  := 'Mi';
  csJu      CONSTANT VARCHAR2(2)  := 'Ju';
  csVi      CONSTANT VARCHAR2(2)  := 'Vi';
  csSa      CONSTANT VARCHAR2(2)  := 'Sa';
  cs2p      CONSTANT VARCHAR2(1)  := ':';
  cs1       CONSTANT VARCHAR2(1)  := '1';
  cs00      CONSTANT VARCHAR2(2)  := '00';
  csAst     CONSTANT VARCHAR2(1)  := '*';
  csSlh     CONSTANT VARCHAR2(1)  := '/';
  csEne     CONSTANT VARCHAR2(1)  := 'ñ';
  csTil     CONSTANT VARCHAR2(8)  := '&ntilde;';
  csMas     CONSTANT VARCHAR2(6)  := 'Master';
  csSml     CONSTANT VARCHAR2(10) := 'Simultáneo';
  csInd     CONSTANT VARCHAR2(13) := 'Independiente';
  csPeriodo CONSTANT VARCHAR2(8)  := 'Periodo ';

  -- chg 01
  cursor curSepararHoras is
         select * from FWRHORS;

  CURSOR cuReporte_respaldo IS
         SELECT SWRPGAC_TERM_CODE        AS termCode,
                SWRPGAC_CAMP_CODE        AS campCode,
                SWRPGAC_CRN              AS sectCrnn,
               /* Pk_Catalogo.STATUS_1(SWRPGAC_SSTS_CODE) AS sstsCode,
                Pk_Catalogo.SCHDTYPE(SWRPGAC_SCHD_CODE) AS schdCode,
                Pk_Catalogo.INSTMETH(SWRPGAC_INSM_CODE) AS insmCode,
                SWRPGAC_PTRM_CODE        AS ptrmCode,*/
                SWRPGAC_SUBJ_CODE        AS subjCode,
                SWRPGAC_CRSE_NUMB        AS crseNumb,
                SWRPGAC_COLL_CODE         AS escuela,
                SWRPGAC_TITLE            AS crseTitl,
               /* SWRPGAC_CONT_HR_LOW      AS contHrLw,
                SWRPGAC_CREDIT_HR_LOW    AS credHrLw,*/
                SWRPGAC_SEQ_NUMB         AS seqqNumb,
                SWRPGAC_MAX_ENRL         AS maxxEnrl,
               /* SWRPGAC_ENRL             AS sectEnrl,
                Pk_Catalogo.COLEGIO(SWRPGAC_COLL_CODE) AS collCode,*/
                FWRHORS_HRS_WEEK         AS hrssWeek,
                FWRHORS_MON_DAY          AS meetMonn,
                FWRHORS_TUE_DAY          AS meetTuee,
                FWRHORS_WED_DAY          AS meetWedd,
                FWRHORS_THU_DAY          AS meetThuu,
                FWRHORS_FRI_DAY          AS meetFrii,
                FWRHORS_SAT_DAY          AS meetSatt,
                FWRHORS_BEGIN_TIME       AS begnTime,
                FWRHORS_END_TIME         AS enddTime,
                FWRHORS_BLDG_CODE        AS bldgCode,
                FWRHORS_ROOM_CODE        AS roomCode,
                FWRHORS_PERCENT_RESPONSE AS prcnResp,
                Pk_Catalogo.Tipo(FWRHORS_FSTP_CODE) AS fstpCode,
                SWRPGAC_SESS_CODE        AS meetCatg,
                Pk_Catalogo.Categoria(FWRHOR_FCTG_CODE) AS fctgCode,
                SPRIDEN_ID               AS idenIDdd,
                REPLACE(REPLACE(SPRIDEN_LAST_NAME||csEsp||
                SPRIDEN_FIRST_NAME||csEsp||SPRIDEN_MI,csEne,csTil),csAst,csEsp) AS idenName,
                FWRXLST_XLST_GROUP                                              AS xlstGrup,
                DECODE(FWRXLST_TYPE ,csM,csMas,csS,csSml,csInd)                 AS xlstType
           FROM SPRIDEN,
                FWRHORS,
                SWRPGAC,
                FWRXLST
          WHERE FWRHORS_PIDM        = SPRIDEN_PIDM
            AND SPRIDEN_CHANGE_IND IS NULL
            AND SWRPGAC_TERM_CODE   = FWRHORS_TERM_CODE(+)
            AND SWRPGAC_CRN         = FWRHORS_CRN(+)
            AND SWRPGAC_TERM_CODE   = FWRXLST_TERM_CODE(+)
            AND SWRPGAC_CRN         = FWRXLST_CRN(+)
            --AND (FWRXLST_TYPE       = vsXlstType OR vsXlstType IS NULL)
            --AND (FWRHORS_FSTP_CODE  = vsFstpCode OR vsFstpCode IS NULL)
            /*AND (
                   (vsFattCode IS NULL)
                 OR
                   (
                       (vsFattCode IS NOT NULL)
                    AND
                       EXISTS (SELECT NULL
                                 FROM SIRATTR A
                                WHERE A.SIRATTR_TERM_CODE_EFF = (SELECT MAX(B.SIRATTR_TERM_CODE_EFF)
                                                                   FROM SIRATTR B
                                                                  WHERE B.SIRATTR_PIDM = SPRIDEN_PIDM
                                                                )
                                  AND A.SIRATTR_PIDM          = SPRIDEN_PIDM
                                  AND A.SIRATTR_FATT_CODE     = vsFattCode
                              )
                   )
                )*/
--          ORDER BY SWRPGAC_TERM_CODE DESC, SWRPGAC_COLL_CODE,FWRXLST_XLST_GROUP,SWRPGAC_SUBJ_CODE;
          ORDER BY SWRPGAC_CRN, FWRHORS_MON_DAY, FWRHORS_TUE_DAY, FWRHORS_WED_DAY, FWRHORS_THU_DAY, FWRHORS_FRI_DAY, FWRHORS_SAT_DAY, FWRHORS_BEGIN_TIME, FWRHORS_END_TIME;


  CURSOR cuReporte IS
         SELECT SWRPGAC_TERM_CODE        AS termCode,
                SWRPGAC_CAMP_CODE        AS campCode,
                SWRPGAC_CRN              AS sectCrnn,
                SWRPGAC_SUBJ_CODE        AS subjCode,
                SWRPGAC_CRSE_NUMB        AS crseNumb,
                SWRPGAC_COLL_CODE         AS escuela,
                SWRPGAC_TITLE            AS crseTitl,
                SWRPGAC_SEQ_NUMB         AS seqqNumb,
                SWRPGAC_MAX_ENRL         AS maxxEnrl,
                FWRHRSS_HRS_WEEK         AS hrssWeek,
                FWRHRSS_MON_DAY          AS meetMonn,
                FWRHRSS_TUE_DAY          AS meetTuee,
                FWRHRSS_WED_DAY          AS meetWedd,
                FWRHRSS_THU_DAY          AS meetThuu,
                FWRHRSS_FRI_DAY          AS meetFrii,
                FWRHRSS_SAT_DAY          AS meetSatt,
                FWRHRSS_BEGIN_TIME       AS begnTime,
                FWRHRSS_END_TIME         AS enddTime,
                FWRHRSS_BLDG_CODE        AS bldgCode,
                FWRHRSS_ROOM_CODE        AS roomCode,
                FWRHRSS_PERCENT_RESPONSE AS prcnResp,
                Pk_Catalogo.Tipo(FWRHRSS_FSTP_CODE) AS fstpCode,
                SWRPGAC_SESS_CODE        AS meetCatg,
                Pk_Catalogo.Categoria(FWRHRSS_FCTG_CODE) AS fctgCode,
                SPRIDEN_ID               AS idenIDdd,
                REPLACE(REPLACE(SPRIDEN_LAST_NAME||csEsp||
                SPRIDEN_FIRST_NAME||csEsp||SPRIDEN_MI,csEne,csTil),csAst,csEsp) AS idenName,
                FWRXLST_XLST_GROUP                                              AS xlstGrup,
                DECODE(FWRXLST_TYPE ,csM,csMas,csS,csSml,csInd)                 AS xlstType
           FROM SPRIDEN,
                FWRHRSS,
                SWRPGAC,
                FWRXLST
          WHERE FWRHRSS_PIDM      = SPRIDEN_PIDM
            AND SPRIDEN_CHANGE_IND IS NULL
            AND SWRPGAC_TERM_CODE   = FWRHRSS_TERM_CODE(+)
            AND SWRPGAC_CRN         = FWRHRSS_CRN(+)
            AND SWRPGAC_TERM_CODE   = FWRXLST_TERM_CODE(+)
            AND SWRPGAC_CRN         = FWRXLST_CRN(+)
          ORDER BY SWRPGAC_CRN, FWRHRSS_MON_DAY, FWRHRSS_TUE_DAY, FWRHRSS_WED_DAY, FWRHRSS_THU_DAY, FWRHRSS_FRI_DAY, FWRHRSS_SAT_DAY, FWRHRSS_BEGIN_TIME, FWRHRSS_END_TIME;


     cursor cuIngresado(psTerm varchar2,psCrn varchar2) is select SSRSRDF_RDEF_CODE as SSRSRDF_CODE, STVRDEF_DESC
                 from SSRSRDF,STVRDEF
                    where
                       SSRSRDF_TERM_CODE =psTerm
                  and SSRSRDF_CRN=psCrn
                  and SSRSRDF_RDEF_CODE=STVRDEF_CODE;

  BEGIN
      IF Pk_Login.F_ValidacionDeAcceso(pk_login.vgsUSR) THEN RETURN; END IF;

      --son buscadas los valores de las cookies para asignar los valores del filtro del query.

      vsTermCode := NVL(pk_objHtml.getValueCookie('psPerio'),csSlh);
      vsCollCode := pk_objHtml.getValueCookie('psFacu');
      vsSubjCode := pk_objHtml.getValueCookie('psSubjc');
      --vsFstpCode := pk_objHtml.getValueCookie('psType');
      --vsSstsCode := pk_objHtml.getValueCookie('psStat1');
      --vsBldgCode := pk_objHtml.getValueCookie('psEdifi');
      --vsXlstType := pk_objHtml.getValueCookie('psTipol');
      --vsFattCode := pk_objHtml.getValueCookie('psAtbs');
      vsStarDate := pk_objHtml.getValueCookie('psHrDe');
      vsEnddDate := pk_objHtml.getValueCookie('psHrA');
      vsSeccion  := pk_objHtml.getValueCookie('cookSeccion');
      vsPtrmCode := NVL(pk_objHtml.getValueCookie('psPtrm'),csSlh);
      vsExp    := pk_objHTML.getValueCookie('psExped');
      --Obtengo de las cookies el del año académico.
      vsAcyr := pk_objHtml.getValueCookie('psAcyr');

      global_pidm := f_get_pidm(vsExp);

      WHILE INSTR(vsTermCode, csSlh) > 0  LOOP
            vsTerm := SUBSTR(vsTermCode, 1, INSTR(vsTermCode,csSlh)-1);

            PWAISSBSECT(vsCampCode,vsTerm,vsCollCode,vsSubjCode,null,vsPtrmCode);
            vsTermCode := SUBSTR(vsTermCode, INSTR(vsTermCode,csSlh)+1);

      END LOOP ;


      INSERT INTO FWRHORS
      (FWRHORS_PIDM,       FWRHORS_TERM_CODE, FWRHORS_CRN,       FWRHORS_CATAGORY,
       FWRHORS_HRS_WEEK,   FWRHORS_MON_DAY,   FWRHORS_TUE_DAY,   FWRHORS_WED_DAY,
       FWRHORS_THU_DAY,    FWRHORS_FRI_DAY,   FWRHORS_SAT_DAY,   FWRHORS_BEGIN_TIME,
       FWRHORS_END_TIME,   FWRHORS_BLDG_CODE, FWRHORS_ROOM_CODE, FWRHORS_PERCENT_RESPONSE,
       FWRHORS_FSTP_CODE,  FWRHOR_FCTG_CODE
       )
      SELECT
       sirasg.asgnPidm,    sirasg.termCode,   sirasg.meetCrnn,   sirasg.meetCatg,
       sirasg.hrssWeek,    sirasg.meetMonn,   sirasg.meetTuee,   sirasg.meetWedd,
       sirasg.meetThuu,    sirasg.meetFrii,   sirasg.meetSatt,   sirasg.begnTime,
       sirasg.enddTime,    sirasg.bldgCode,   sirasg.roomCode,   sirasg.prcnResp,
       (SELECT A.SIBINST_FSTP_CODE
          FROM SIBINST A
         WHERE SIBINST_TERM_CODE_EFF = (SELECT MAX(B.SIBINST_TERM_CODE_EFF)
                                          FROM SIBINST B
                                         WHERE B.SIBINST_PIDM           = sirasg.asgnPidm
                                           AND B.SIBINST_TERM_CODE_EFF <= sirasg.termCode
                                        )
           AND A.SIBINST_FCST_CODE = csAC
           AND A.SIBINST_PIDM      = sirasg.asgnPidm
       ) fstpCode,
       (SELECT A.SIBINST_FCTG_CODE
          FROM SIBINST A
         WHERE SIBINST_TERM_CODE_EFF = (SELECT MAX(B.SIBINST_TERM_CODE_EFF)
                                          FROM SIBINST B
                                         WHERE B.SIBINST_PIDM           = sirasg.asgnPidm
                                           AND B.SIBINST_TERM_CODE_EFF <= sirasg.termCode
                                        )
           AND A.SIBINST_FCST_CODE = csAC
           AND A.SIBINST_PIDM      = sirasg.asgnPidm
       ) fctgCode
         FROM (SELECT SIRASGN_PIDM                                        asgnPidm,
                      SSRMEET_TERM_CODE                                   termCode,
                      SSRMEET_CRN                                         meetCrnn,
                      SSRMEET_CATAGORY                                    meetCatg,
                      SUM(NVL(SSRMEET_HRS_WEEK,0))                        hrssWeek,
                      DECODE(SSRMEET_MON_DAY, csM, csLu, SSRMEET_MON_DAY) meetMonn,
                      DECODE(SSRMEET_TUE_DAY, csT, csMa, SSRMEET_TUE_DAY) meetTuee,
                      DECODE(SSRMEET_WED_DAY, csW, csMi, SSRMEET_WED_DAY) meetWedd,
                      DECODE(SSRMEET_THU_DAY, csR, csJu, SSRMEET_THU_DAY) meetThuu,
                      DECODE(SSRMEET_FRI_DAY, csF, csVi, SSRMEET_FRI_DAY) meetFrii,
                      DECODE(SSRMEET_SAT_DAY, csS, csSa, SSRMEET_SAT_DAY) meetSatt,
                      SUBSTR(SSRMEET_BEGIN_TIME,1,2)||cs2p||
                      NVL(SUBSTR(SSRMEET_BEGIN_TIME,3,2),cs00)            begnTime,
                      SUBSTR(SSRMEET_END_TIME,1,2)||cs2p||
                      NVL(SUBSTR(SSRMEET_END_TIME,3,2),cs00)              enddTime,
                      SSRMEET_BLDG_CODE                                   bldgCode,
                      SSRMEET_ROOM_CODE                                   roomCode,
                      SIRASGN_PERCENT_RESPONSE                            prcnResp
                 FROM SSRMEET,
                          SIRASGN
                WHERE SSRMEET_TERM_CODE = SIRASGN_TERM_CODE(+)
                  AND SSRMEET_CRN               = SIRASGN_CRN(+)
                  AND SSRMEET_CATAGORY     = SIRASGN_CATEGORY(+)
                  --AND (SSRMEET_BLDG_CODE = vsBldgCode OR vsBldgCode IS NULL)
                  AND (SIRASGN_PIDM      = global_pidm OR global_pidm IS NULL)
                  --and SIRASGN_PIDM=global_pidm
                  AND nvl(SIRASGN_PRIMARY_IND,'N') ='Y'
                  AND (SSRMEET_CRN,SSRMEET_TERM_CODE) IN (SELECT SWRPGAC_CRN,SWRPGAC_TERM_CODE
                                                            FROM SWRPGAC
                                                         )
                  AND SUBSTR(SSRMEET_TERM_CODE,1,4) = vsAcyr --'2013'
                 GROUP BY SIRASGN_PIDM,
                          SSRMEET_TERM_CODE,
                          SSRMEET_CRN,
                          SSRMEET_CATAGORY,
                          DECODE(SSRMEET_MON_DAY, csM, csLu, SSRMEET_MON_DAY),
                          DECODE(SSRMEET_TUE_DAY, csT, csMa, SSRMEET_TUE_DAY),
                          DECODE(SSRMEET_WED_DAY, csW, csMi, SSRMEET_WED_DAY),
                          DECODE(SSRMEET_THU_DAY, csR, csJu, SSRMEET_THU_DAY),
                          DECODE(SSRMEET_FRI_DAY, csF, csVi, SSRMEET_FRI_DAY),
                          DECODE(SSRMEET_SAT_DAY, csS, csSa, SSRMEET_SAT_DAY),
                          SUBSTR(SSRMEET_BEGIN_TIME,1,2)||cs2p||
                          NVL(SUBSTR(SSRMEET_BEGIN_TIME,3,2),cs00),
                          SUBSTR(SSRMEET_END_TIME,1,2)||cs2p||
                          NVL(SUBSTR(SSRMEET_END_TIME,3,2),cs00),
                          SSRMEET_BLDG_CODE,
                          SSRMEET_ROOM_CODE,
                          SIRASGN_PERCENT_RESPONSE
              ) sirasg
        WHERE (sirasg.begnTime >= vsStarDate OR vsStarDate IS NULL)
          AND (sirasg.enddTime <= vsEnddDate OR vsEnddDate IS NULL);


      -- chg-01 start
      -- segregar horarios DE FWRHORS y dejar en FWRHRSS

      FOR regLine IN curSepararHoras LOOP
         if regLine.FWRHORS_MON_DAY is not null then
            insert into FWRHRSS values (regLine.FWRHORS_PIDM, regLine.FWRHORS_TERM_CODE, regLine.FWRHORS_CRN,
                                          regLine.FWRHORS_CATAGORY, regLine.FWRHORS_HRS_WEEK ,
                                          regLine.FWRHORS_MON_DAY, null, null, null, null, null,
                                          regLine.FWRHORS_BEGIN_TIME, regLine.FWRHORS_END_TIME, regLine.FWRHORS_BLDG_CODE,
                                          regLine.FWRHORS_ROOM_CODE, regLine.FWRHORS_PERCENT_RESPONSE, regLine.FWRHORS_START_DATE,
                                          regLine.FWRHORS_END_DATE, regLine.FWRHORS_FSTP_CODE, regLine.FWRHOR_FCTG_CODE, '0');
         end if;

         if regLine.FWRHORS_TUE_DAY is not null then
            insert into FWRHRSS values (regLine.FWRHORS_PIDM, regLine.FWRHORS_TERM_CODE, regLine.FWRHORS_CRN,
                                          regLine.FWRHORS_CATAGORY, regLine.FWRHORS_HRS_WEEK ,
                                          null, regLine.FWRHORS_TUE_DAY, null, null, null, null,
                                          regLine.FWRHORS_BEGIN_TIME, regLine.FWRHORS_END_TIME, regLine.FWRHORS_BLDG_CODE,
                                          regLine.FWRHORS_ROOM_CODE, regLine.FWRHORS_PERCENT_RESPONSE, regLine.FWRHORS_START_DATE,
                                          regLine.FWRHORS_END_DATE, regLine.FWRHORS_FSTP_CODE, regLine.FWRHOR_FCTG_CODE, '0');
         end if;

         if regLine.FWRHORS_WED_DAY is not null then
             insert into FWRHRSS values (regLine.FWRHORS_PIDM, regLine.FWRHORS_TERM_CODE, regLine.FWRHORS_CRN,
                                          regLine.FWRHORS_CATAGORY, regLine.FWRHORS_HRS_WEEK ,
                                          null, null, regLine.FWRHORS_WED_DAY, null, null, null,
                                          regLine.FWRHORS_BEGIN_TIME, regLine.FWRHORS_END_TIME, regLine.FWRHORS_BLDG_CODE,
                                          regLine.FWRHORS_ROOM_CODE, regLine.FWRHORS_PERCENT_RESPONSE, regLine.FWRHORS_START_DATE,
                                          regLine.FWRHORS_END_DATE, regLine.FWRHORS_FSTP_CODE, regLine.FWRHOR_FCTG_CODE, '0');
         end if;

         if regLine.FWRHORS_THU_DAY is not null then
              insert into FWRHRSS values (regLine.FWRHORS_PIDM, regLine.FWRHORS_TERM_CODE, regLine.FWRHORS_CRN,
                                          regLine.FWRHORS_CATAGORY, regLine.FWRHORS_HRS_WEEK ,
                                          null, null, null, regLine.FWRHORS_THU_DAY, null, null,
                                          regLine.FWRHORS_BEGIN_TIME, regLine.FWRHORS_END_TIME, regLine.FWRHORS_BLDG_CODE,
                                          regLine.FWRHORS_ROOM_CODE, regLine.FWRHORS_PERCENT_RESPONSE, regLine.FWRHORS_START_DATE,
                                          regLine.FWRHORS_END_DATE, regLine.FWRHORS_FSTP_CODE, regLine.FWRHOR_FCTG_CODE, '0');
         end if;

         if regLine.FWRHORS_FRI_DAY is not null then
              insert into FWRHRSS values (regLine.FWRHORS_PIDM, regLine.FWRHORS_TERM_CODE, regLine.FWRHORS_CRN,
                                          regLine.FWRHORS_CATAGORY, regLine.FWRHORS_HRS_WEEK ,
                                          null, null, null, null, regLine.FWRHORS_FRI_DAY, null,
                                          regLine.FWRHORS_BEGIN_TIME, regLine.FWRHORS_END_TIME, regLine.FWRHORS_BLDG_CODE,
                                          regLine.FWRHORS_ROOM_CODE, regLine.FWRHORS_PERCENT_RESPONSE, regLine.FWRHORS_START_DATE,
                                          regLine.FWRHORS_END_DATE, regLine.FWRHORS_FSTP_CODE, regLine.FWRHOR_FCTG_CODE, '0');
         end if;

         if regLine.FWRHORS_SAT_DAY is not null then
              insert into FWRHRSS values (regLine.FWRHORS_PIDM, regLine.FWRHORS_TERM_CODE, regLine.FWRHORS_CRN,
                                          regLine.FWRHORS_CATAGORY, regLine.FWRHORS_HRS_WEEK ,
                                          null, null, null, null, null, regLine.FWRHORS_SAT_DAY,
                                          regLine.FWRHORS_BEGIN_TIME, regLine.FWRHORS_END_TIME, regLine.FWRHORS_BLDG_CODE,
                                          regLine.FWRHORS_ROOM_CODE, regLine.FWRHORS_PERCENT_RESPONSE, regLine.FWRHORS_START_DATE,
                                          regLine.FWRHORS_END_DATE, regLine.FWRHORS_FSTP_CODE, regLine.FWRHOR_FCTG_CODE, '0');
         end if;

      end LOOP;

      -- chg-01 end

      INSERT INTO FWRXLST
      (FWRXLST_CRN,FWRXLST_TERM_CODE,FWRXLST_XLST_GROUP,FWRXLST_TYPE)
      SELECT SSRXLST_CRN,
             SSRXLST_TERM_CODE,
             SSRXLST_XLST_GROUP,
             (SELECT SWRXLST_TYPE
                FROM SWRXLST
               WHERE SWRXLST_TERM_CODE  = SSRXLST_TERM_CODE
                 AND SWRXLST_CRN        = SSRXLST_CRN
                 AND SWRXLST_XLST_GROUP = SSRXLST_XLST_GROUP
             )
        FROM SSRXLST
       WHERE (SSRXLST_CRN,SSRXLST_TERM_CODE) IN (SELECT SWRPGAC_CRN,SWRPGAC_TERM_CODE
                                                   FROM SWRPGAC
                                                 );

      vsCampCode := NULL;
      vsTermCode := NULL;

      -- Las instrucciones determinan el largo de la tabla
      FOR vnI IN 1..vnColumnas LOOP
          tabColumna.EXTEND(vnI);
          tabColumna(vnI) := NULL;
      END LOOP;

      tabColumna(1) := 'Escuela';
      tabColumna(2) := 'NRC';
      tabColumna(3) := 'Secci&oacute;n';
      tabColumna(4) := 'Sesi&oacute;n';
      tabColumna(5) := 'Materia';
      tabColumna(6) := 'Curso';
      tabColumna(7) := 'Nombre materia';
      tabColumna(8) := 'Lista cruzada';
      tabColumna(9) := 'ID Docente Principal';
      tabColumna(10) := 'Nombre Docente';
      tabColumna(11) := csLu;
      tabColumna(12) := csMa;
      tabColumna(13) := csMi;
      tabColumna(14) := csJu;
      tabColumna(15) := csVi;
      tabColumna(16) := csSa;
      tabColumna(17) := 'Hora inicio';
      tabColumna(18) := 'Hora fin';
      tabColumna(19) := 'Cupo';
      tabColumna(20) := 'Preferencia Atributo Sal&oacute;n';
      tabColumna(21) := 'Descripci&oacute;n Preferencia';


      FOR regRep IN cuReporte LOOP
          IF (vnExists = 0 OR vsTermCode <> regRep.termCode) THEN
             Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicoPag,cs1,psSubtitulo=>csPeriodo||regRep.termCode,psUsuario=>pk_login.vgsUSR,psSeccion=>vsSeccion, psSinPiePag=>csP,psSinLogo=>csP);
             vsInicoPag := 'SALTO';
          END IF;

                    vnIngresado:=null;
                    vnIngresadoDef:=null;
                 for regdet in cuIngresado(regRep.termCode,regRep.sectCrnn) loop
                        vnIngresado:=regdet.SSRSRDF_CODE||'/';
                        vnIngresadoDef:=regdet.STVRDEF_DESC||'/';
                 end loop;

                select substr(vnIngresado,1,length(vnIngresado)-1),substr(vnIngresadoDef,1,length(vnIngresadoDef)-1)
                  into vnIngresado,vnIngresadoDef
                 from dual;

          htp.p(
          '<tr>
          <td class="tdfont7" valign="top" align="left">'  ||regRep.escuela||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||regRep.sectCrnn||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.seqqNumb||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.meetCatg||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.subjCode||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||regRep.crseNumb||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||regRep.crseTitl||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||regRep.xlstGrup||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||regRep.idenIDdd||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||regRep.idenName||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.meetMonn||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.meetTuee||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.meetWedd||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.meetThuu||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.meetFrii||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.meetSatt||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.begnTime||'</td>
          <td class="tdfont7" valign="top" align="center">'||regRep.enddTime||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||regRep.maxxEnrl||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||vnIngresado||'</td>
          <td class="tdfont7" valign="top" align="left">'  ||vnIngresadoDef||'</td>
          </tr>'
          );

          vnExists   := 1;
          vsCampCode := regRep.campCode;
          vsTermCode := regRep.termCode;

      END LOOP;

      IF vnExists = 0 THEN
         htp.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
      ELSE
         -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
         Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

         -- es omitido el encabezado del reporte pero se agrega el salto de pagina
         Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR, psSeccion=>vsSeccion,psSinPiePag=>'P',psSinLogo=>'P');
      END IF;

      htp.p('</table><br></body></html>');

      ROLLBACK;

 -- EXCEPTION
   --   WHEN OTHERS THEN
 --          htp.p(SQLERRM);
  END PWRASAL;
/
DROP PROCEDURE BANINST1.PWACREV;

CREATE OR REPLACE PROCEDURE BANINST1.PWACREV IS
/*
    Tarea : Copia los criterios de evaluación del curso a los alumnos.
            Esto debe hacerse por los lumnos que se inscribieron despues de haber sido
            asignados los criterios de evaluación.
    Autor : GEPC
    Fecha : 02/12/2010

*/

  TYPE reg_Crn IS RECORD (Crnn SWRXLST.SWRXLST_CRN%TYPE,
                          Grup SWRXLST.SWRXLST_XLST_GROUP%TYPE,
                          Term SWRXLST.SWRXLST_TERM_CODE%TYPE
                         );

  TYPE tableCrn IS TABLE OF reg_Crn INDEX BY BINARY_INTEGER;

  tabCrn   tableCrn;
  vnExiste INTEGER        := 0;
  vnRow    INTEGER        := 0;
  vsError  VARCHAR2(4000) := NULL;
  vsBreak  VARCHAR2(10)   := 'BKP01';

--P_JobCriterioEvaluacion(

  csA        CONSTANT VARCHAR2(1) := 'A';
  csM        CONSTANT VARCHAR2(1) := 'M';
  csS        CONSTANT VARCHAR2(1) := 'S';
  csRE       CONSTANT VARCHAR2(2) := 'RE';
  csRW       CONSTANT VARCHAR2(2) := 'RW';
  csOE       CONSTANT VARCHAR2(2) := 'OE';
  cs201010   CONSTANT VARCHAR2(6) := '201010';
  csFixReg   CONSTANT VARCHAR2(7) := 'FIX_REG';
  csESCALALC CONSTANT VARCHAR2(8) := 'ESCALALC';

  cdSysDate  CONSTANT DATE        := SYSDATE;

  CURSOR cuCriterioAlumno IS
         SELECT SHRGCOM_TERM_CODE AS Term,
                SHRGCOM_CRN       AS Crnn,
                SFRSTCR_PIDM      AS Pidm,
                SHRGCOM_ID        AS Iddd,
                SHRGCOM_DATE      AS GcoD
           FROM SHRGCOM,
                SFRSTCR
          WHERE SHRGCOM_TERM_CODE = SFRSTCR_TERM_CODE
            AND SHRGCOM_CRN       = SFRSTCR_CRN
            AND NOT EXISTS (SELECT NULL
                              FROM SHRMRKS
                             WHERE SHRMRKS_GCOM_ID   = SHRGCOM_ID
                               AND SHRMRKS_PIDM      = SFRSTCR_PIDM
                               AND SHRMRKS_CRN       = SFRSTCR_CRN
                               AND SHRMRKS_TERM_CODE = SFRSTCR_TERM_CODE
                           )
            AND SFRSTCR_RSTS_CODE IN (csRE,csRW)
            AND SHRGCOM_TERM_CODE >= cs201010;

  -- Cursos simultaneos con status activo
  --                    que tienen alumnos inscritos
  --                    no tiene registrados los criterios de evaluación
  --                    y el curso maestro tiene criterios de evaluación
  CURSOR cuSimul IS
         SELECT A.SWRXLST_CRN        AS Crnn,
                A.SWRXLST_XLST_GROUP AS Grup,
                A.SWRXLST_TERM_CODE  AS Term
           FROM (SELECT B.SWRXLST_CRN        AS Crnn,
                        B.SWRXLST_XLST_GROUP AS Grup,
                        B.SWRXLST_TERM_CODE  AS Term
                   FROM SWRXLST B, SHRGCOM C
                  WHERE C.SHRGCOM_TERM_CODE  = B.SWRXLST_TERM_CODE
                    AND C.SHRGCOM_CRN        = B.SWRXLST_CRN
                    AND B.SWRXLST_TYPE       = csM
                    AND B.SWRXLST_TERM_CODE >= cs201010
                ) Maestro,
                SWRXLST A
          WHERE A.SWRXLST_XLST_GROUP = Maestro.Grup
            AND A.SWRXLST_TERM_CODE  = Maestro.Term
            AND     EXISTS (SELECT NULL
                              FROM SFRSTCR,
                                   SSBSECT
                             WHERE SSBSECT_TERM_CODE  = A.SWRXLST_TERM_CODE
                               AND SSBSECT_CRN        = A.SWRXLST_CRN
                               AND SFRSTCR_TERM_CODE  = SSBSECT_TERM_CODE
                               AND SFRSTCR_CRN        = SSBSECT_CRN
                               AND SSBSECT_SSTS_CODE  = csA
                               AND SFRSTCR_RSTS_CODE IN (csRE,csRW)
                               AND SSBSECT_TERM_CODE >= cs201010
                           )
            AND NOT EXISTS (SELECT NULL
                              FROM SHRGCOM
                             WHERE SHRGCOM_TERM_CODE  = A.SWRXLST_TERM_CODE
                               AND SHRGCOM_CRN        = A.SWRXLST_CRN
                               AND SHRGCOM_TERM_CODE >= cs201010
                           )
            AND SWRXLST_TYPE       = csS
            AND SWRXLST_TERM_CODE >= cs201010;

  --obtine los cursos maestros por grupo y periodo
  CURSOR cuMaestro(psTerm VARCHAR2,
                   psGrup VARCHAR2
                  ) IS
         SELECT SHRGCOM_NAME           AS Name,
                SHRGCOM_WEIGHT         AS Weight,
                SHRGCOM_TOTAL_SCORE    AS Score,
                SHRGCOM_INCL_IND       AS incl,
                SHRGCOM_DATE           AS Daet,
                SHRGCOM_SEQ_NO         AS Seq,
                SHRGCOM_DESCRIPTION    AS Descr,
                SHRGCOM_GRADE_SCALE    AS Escala,
                SHRGCOM_MIN_PASS_SCORE AS Minp,
                SHRGCOM_TERM_CODE      AS Term,
                SHRGCOM_CRN            AS Crn,
                SHRGCOM_ID             as gcomId
           FROM SHRGCOM C,SWRXLST A
          WHERE SHRGCOM_TERM_CODE  = SWRXLST_TERM_CODE
            AND SHRGCOM_CRN        = SWRXLST_CRN
            AND SWRXLST_TYPE       = csM
            AND SWRXLST_XLST_GROUP = psGrup
            AND SWRXLST_TERM_CODE  = psTerm;

  CURSOR cuAlumnos(psTerm VARCHAR2,
                   psNrc  VARCHAR2
                  ) IS
         SELECT SFRSTCR_PIDM AS Pidm
           FROM SFRSTCR
          WHERE SFRSTCR_RSTS_CODE IN (csRE,csRW)
            AND SFRSTCR_CRN        = psNrc
            AND SFRSTCR_TERM_CODE  = psTerm;

  BEGIN
      --Seguardan datos antes de procesar la información
      FOR regSim IN cuSimul LOOP
          vnRow := vnRow + 1;

          tabCrn(vnRow).Crnn := regSim.Crnn;
          tabCrn(vnRow).Grup := regSim.Grup;
          tabCrn(vnRow).Term := regSim.Term;
      END LOOP;

      vsBreak := 'BKP02';

      --sebuscan los criterios de evaluación del curso maestro
      FOR vnI IN 1..vnRow LOOP
          -- se actualiza la escala de calificación del curso simultaneo
          BEGIN
              UPDATE SSBSECT
                 SET SSBSECT_GSCH_NAME = csESCALALC
               WHERE SSBSECT_TERM_CODE = tabCrn(vnI).Term
                 AND SSBSECT_CRN       = tabCrn(vnI).Crnn;
          EXCEPTION
              WHEN OTHERS THEN
                   NULL;
          END;

          vsBreak := 'BKP03';

          FOR regMast IN cuMaestro(tabCrn(vnI).Term, tabCrn(vnI).Grup) LOOP
              vnExiste := 0;

              -- se busca el criterio de evaluación para ya no agregarlo
              SELECT COUNT(1)
                INTO vnExiste
                FROM SHRGCOM
               WHERE SHRGCOM_TERM_CODE = regMast.Term
                 AND SHRGCOM_CRN       = tabCrn(vnI).Crnn --CRN sumultaneo
                 AND SHRGCOM_NAME      = regMast.Name
                 AND SHRGCOM_SEQ_NO    = regMast.Seq;

              IF vnExiste = 0 THEN
                 BEGIN
                     INSERT INTO SHRGCOM
                     (
                      SHRGCOM_TERM_CODE, SHRGCOM_CRN,         SHRGCOM_ID,          SHRGCOM_NAME,
                      SHRGCOM_WEIGHT,    SHRGCOM_TOTAL_SCORE, SHRGCOM_INCL_IND,    SHRGCOM_DATE,
                      SHRGCOM_SEQ_NO,    SHRGCOM_DESCRIPTION, SHRGCOM_GRADE_SCALE, SHRGCOM_MIN_PASS_SCORE
                     )
                     VALUES
                     (
                      regMast.Term,      tabCrn(vnI).Crnn,    regMast.gcomId,      regMast.Name,
                      regMast.Weight,    regMast.Score,       regMast.Incl,        regMast.Daet,
                      regMast.Seq,       regMast.Descr,       regMast.Escala,      regMast.Minp
                     );
                 EXCEPTION
                     WHEN DUP_VAL_ON_INDEX THEN
                          NULL;
                     WHEN OTHERS THEN
                          NULL;
                 END;

                 vsBreak := 'BKP04';

                 --registra el componente a los alumnos del curso
                 FOR regAlu IN cuAlumnos(regMast.Term, tabCrn(vnI).Crnn) LOOP
                     BEGIN
                         INSERT INTO SHRMRKS
                         (
                          SHRMRKS_TERM_CODE, SHRMRKS_CRN,      SHRMRKS_PIDM, SHRMRKS_GCOM_ID,
                          SHRMRKS_GCOM_DATE, SHRMRKS_GCHG_CODE
                         )
                         VALUES
                         (
                          regMast.Term,      tabCrn(vnI).Crnn, regAlu.Pidm,  regMast.gcomId,
                          TRUNC(cdSysDate),  csOE
                         );
                     EXCEPTION
                         WHEN DUP_VAL_ON_INDEX THEN
                              NULL;
                         WHEN OTHERS           THEN
                              NULL;
                     END;
                 END LOOP;
              END IF;

              vsBreak := 'BKP05';

          END LOOP;

          COMMIT;

      END LOOP;

      vsBreak := 'BKP06';

      --introduce los criterios de evaluación al laumno que se registro despues que profesor
      --capturo los criterios de evaluación
      FOR regCrAl IN cuCriterioAlumno LOOP
          NULL;

          BEGIN
              INSERT INTO SHRMRKS
              (
               SHRMRKS_TERM_CODE, SHRMRKS_CRN,           SHRMRKS_PIDM,
               SHRMRKS_GCOM_ID,   SHRMRKS_ACTIVITY_DATE, SHRMRKS_USER_ID,
               SHRMRKS_GCOM_DATE, SHRMRKS_GCHG_CODE
              )
              VALUES
              (
               regCrAl.Term,      regCrAl.CRNn,          regCrAl.Pidm,
               regCrAl.IDdd,      cdSysDate,             csFixReg,
               regCrAl.GcoD,      csOE
              );
          EXCEPTION
              WHEN DUP_VAL_ON_INDEX  THEN
                   NULL;
              WHEN OTHERS           THEN
                   NULL;
          END;

      END LOOP;

      COMMIT;

      vsBreak := 'BKP07';

      -- Se agrega el update para actualizar la escala de calificaciones a cursos que les hace falta
      -- y por ese motivo no pueden rolarse a historia académica
      UPDATE SSBSECT
         SET SSBSECT_GSCH_NAME = csESCALALC
       WHERE EXISTS (SELECT NULL
                       FROM SHRGCOM
                      WHERE SHRGCOM_TERM_CODE  = SSBSECT_TERM_CODE
                        AND SHRGCOM_CRN        = SSBSECT_CRN
                        AND SHRGCOM_TERM_CODE >= cs201010
                    )
         AND SSBSECT_GSCH_NAME IS NULL
         AND SSBSECT_TERM_CODE >= cs201010;


      COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
           RAISE;

  END PWACREV;
/

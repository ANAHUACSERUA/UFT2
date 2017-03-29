DROP PROCEDURE BANINST1.PWAINGD;

CREATE OR REPLACE PROCEDURE BANINST1.PWAINGD(psCamp  VARCHAR2,
                                             psTerm  VARCHAR2,
                                             psColl  VARCHAR2,
                                             psSede  VARCHAR2 DEFAULT NULL,
                                             ps2     VARCHAR2 DEFAULT NULL
                                            ) IS

/*
         TAREA: Llena tablas de paso para mejorar la velocidad en el reporte
         FECHA: 19/04/2010
         AUTOR: GEPC
        MODULO: Registro de calificaciones

  MODIFICACION: 09/08/2010
                GEPC
                * Se agrega el parametro "ps2" para hacer el filtro de las materias
                  que pertenece al nuevo programa educativo 2010 y ocupar el proceso
                  en el reporte de "Avance captura de programas magisteriales"

*/

  cs0       CONSTANT VARCHAR2(1) := '0';
  csA       CONSTANT VARCHAR2(1) := 'A';
  csY       CONSTANT VARCHAR2(1) := 'Y';
  csDI      CONSTANT VARCHAR2(2) := 'DI';
  csZZ      CONSTANT VARCHAR2(2) := 'ZZ';
  csSinSede CONSTANT VARCHAR2(8) := 'sin Sede';
  ciCero    CONSTANT INTEGER     := 0;
  cn1       CONSTANT NUMBER(1)   := 1;
  cn2       CONSTANT NUMBER(1)   := 2;

  vsCamp VARCHAR2(6)  := psCamp;
  vsSede VARCHAR2(10) := psSede;
  vsTerm VARCHAR2(10) := psTerm;
  vsColl VARCHAR2(10) := psColl;

  BEGIN
      INSERT INTO SWRPGAC
      (SWRPGAC_TERM_CODE, SWRPGAC_CRN, SWRPGAC_COLL_CODE, SWRPGAC_SUBJ_CODE, SWRPGAC_CRSE_NUMB, SWRPGAC_TITLE
      )
       SELECT C.SSBSECT_TERM_CODE,
              C.SSBSECT_CRN,
              NVL(D.SSBOVRR_COLL_CODE,A.SCBCRSE_COLL_CODE),
              A.SCBCRSE_SUBJ_CODE,
			           A.SCBCRSE_CRSE_NUMB,
			           A.SCBCRSE_TITLE
         FROM SSBSECT C,
              SCBCRSE A,
              SSBOVRR D
        WHERE (NVL(D.SSBOVRR_COLL_CODE,A.SCBCRSE_COLL_CODE) = vsColl OR vsColl  is null)
          AND A.SCBCRSE_EFF_TERM            = (SELECT MAX(B.SCBCRSE_EFF_TERM)
                                                 FROM SCBCRSE B
                                                WHERE B.SCBCRSE_EFF_TERM <= C.SSBSECT_TERM_CODE
                                                  AND B.SCBCRSE_SUBJ_CODE = C.SSBSECT_SUBJ_CODE
                                                  AND B.SCBCRSE_CRSE_NUMB = C.SSBSECT_CRSE_NUMB
                                              )
          AND C.SSBSECT_TERM_CODE           = D.SSBOVRR_TERM_CODE(+)
          AND C.SSBSECT_CRN                 = D.SSBOVRR_CRN(+)
          AND C.SSBSECT_SUBJ_CODE           = A.SCBCRSE_SUBJ_CODE
          AND C.SSBSECT_CRSE_NUMB           = A.SCBCRSE_CRSE_NUMB
          AND (
                 (
                      ps2 IS NULL
                  AND
                      C.SSBSECT_ENRL > ciCero
                 )
              OR (
                      ps2 IS NOT NULL
                  AND
                      SUBSTR(SSBSECT_CRSE_NUMB,cn2,cn1) = ps2
                 )
              )
          AND NVL(C.SSBSECT_INSM_CODE,cs0) <> csDI
          AND C.SSBSECT_SSTS_CODE           = csA
          AND C.SSBSECT_TERM_CODE           = vsTerm
          AND C.SSBSECT_CAMP_CODE           = vsCamp;

      INSERT INTO FWRHORS
      (FWRHORS_PIDM, FWRHORS_TERM_CODE, FWRHORS_CRN, FWRHORS_ROOM_CODE
       )
       SELECT sirasg.asgnPidm,
              sirasg.termCode,
              sirasg.asgnCrnn,
              sirasg.deptSede
         FROM (SELECT DISTINCT SIRASGN_PIDM                   AS asgnPidm,
                               SIRASGN_TERM_CODE              AS termCode,
                               SIRASGN_CRN                    AS asgnCrnn,
                               NVL(SIRDPC.deptSede,csSinSede) AS deptSede
                 FROM SIRASGN,
                      (SELECT SIRDPCL_PIDM      AS dpclPidm,
                              SIRDPCL_DEPT_CODE AS deptSede
                         FROM SIRDPCL A
                        WHERE SIRDPCL_HOME_IND      = csY
                          AND SIRDPCL_TERM_CODE_EFF = (SELECT MAX(SI.SIRDPCL_TERM_CODE_EFF)
                                                         FROM SIRDPCL SI
                                                        WHERE SI.SIRDPCL_PIDM           =  A.SIRDPCL_PIDM
                                                          AND SI.SIRDPCL_TERM_CODE_EFF <= vsTerm
                                                      )
                      ) SIRDPC
                WHERE SIRASGN_PIDM                     = SIRDPC.dpclPidm(+)
                  AND (SIRASGN_CRN,SIRASGN_TERM_CODE) IN (SELECT SWRPGAC_CRN,SWRPGAC_TERM_CODE
                                                            FROM SWRPGAC
                                                         )
                  AND SIRASGN_PRIMARY_IND              = csY
                  AND (NVL(SIRDPC.deptSede,csSinSede) = vsSede OR vsSede IS NULL)
              ) sirasg;

      INSERT INTO FWRSIRG
      (FWRSIRG_PIDM, FWRSIRG_TERM_CODE, FWRSIRG_CRN, FWRSIRG_DEPT_CODE, FWRSIRG_COLL_CODE)
      SELECT FWRHORS_PIDM,
             SWRPGAC_TERM_CODE,
             SWRPGAC_CRN,
             FWRHORS_ROOM_CODE,
             SWRPGAC_COLL_CODE
        FROM SWRPGAC,
             FWRHORS
       WHERE SWRPGAC_TERM_CODE = FWRHORS_TERM_CODE
         AND SWRPGAC_CRN       = FWRHORS_CRN;

  END PWAINGD;
/

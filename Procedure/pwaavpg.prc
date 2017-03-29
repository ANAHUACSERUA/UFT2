DROP PROCEDURE BANINST1.PWAAVPG;

CREATE OR REPLACE PROCEDURE BANINST1.pwaavpg (psCamp    VARCHAR2,
                            psTerm    VARCHAR2,
                            psColl    VARCHAR2,
                            psSede    VARCHAR2 DEFAULT NULL)
IS
   /*
            TAREA: Llena tablas de paso para mejorar la velocidad en el reporte
            FECHA: 01/08/2011
            AUTOR: GEPC
           MODULO: Profesores

     Modificación: 22/09/2011
                   JCCR
                   Se Agrego la Condicion  (C.SSBSECT_GMOD_CODE != csS OR C.SSBSECT_GMOD_CODE != csX)

     Modificación: 05/10/2011
                   GEPC
                   Se modifico la Condicion  (C.SSBSECT_GMOD_CODE != csS OR C.SSBSECT_GMOD_CODE != csX)
                   por
                        AND C.SSBSECT_GMOD_CODE <> csS
                        AND C.SSBSECT_GMOD_CODE <> csX
   */

   cs0         CONSTANT VARCHAR2 (1) := '0';
   csA         CONSTANT VARCHAR2 (1) := 'A';
   csY         CONSTANT VARCHAR2 (1) := 'Y';
   csS         CONSTANT VARCHAR2 (1) := 'S';
   csX         CONSTANT VARCHAR2 (1) := 'X';
   csDI        CONSTANT VARCHAR2 (2) := 'DI';
   csZZ        CONSTANT VARCHAR2 (2) := 'ZZ';
   csSinSede   CONSTANT VARCHAR2 (8) := 'sin Sede';
   ciCero      CONSTANT INTEGER := 0;
   cn1         CONSTANT NUMBER (1) := 1;
   cn2         CONSTANT NUMBER (1) := 2;

   vsCamp               VARCHAR2 (6) := psCamp;
   vsSede               VARCHAR2 (10) := psSede;
   vsTerm               VARCHAR2 (10) := psTerm;
   vsColl               VARCHAR2 (10) := psColl;
BEGIN
   DELETE SWRPGAC;

   INSERT INTO SWRPGAC (SWRPGAC_TERM_CODE,
                        SWRPGAC_CRN,
                        SWRPGAC_COLL_CODE,
                        SWRPGAC_SUBJ_CODE,
                        SWRPGAC_CRSE_NUMB,
                        SWRPGAC_TITLE,
                        SWRPGAC_GMOD_CODE)
      SELECT C.SSBSECT_TERM_CODE,
             C.SSBSECT_CRN,
             NVL (D.SSBOVRR_COLL_CODE, A.SCBCRSE_COLL_CODE),
             A.SCBCRSE_SUBJ_CODE,
             A.SCBCRSE_CRSE_NUMB,
             A.SCBCRSE_TITLE,
             C.SSBSECT_GMOD_CODE
        FROM SSBSECT C, SCBCRSE A, SSBOVRR D
       WHERE A.SCBCRSE_EFF_TERM =
                (SELECT MAX (B.SCBCRSE_EFF_TERM)
                   FROM SCBCRSE B
                  WHERE     B.SCBCRSE_EFF_TERM <= C.SSBSECT_TERM_CODE
                        AND B.SCBCRSE_SUBJ_CODE = C.SSBSECT_SUBJ_CODE
                        AND B.SCBCRSE_CRSE_NUMB = C.SSBSECT_CRSE_NUMB)
             AND C.SSBSECT_TERM_CODE = D.SSBOVRR_TERM_CODE(+)
             AND C.SSBSECT_CRN = D.SSBOVRR_CRN(+)
             AND C.SSBSECT_SUBJ_CODE = A.SCBCRSE_SUBJ_CODE
             AND C.SSBSECT_CRSE_NUMB = A.SCBCRSE_CRSE_NUMB
             AND (NVL (D.SSBOVRR_COLL_CODE, A.SCBCRSE_COLL_CODE) = vsColl
                  OR vsColl = csZZ)
             AND NVL (C.SSBSECT_INSM_CODE, cs0) <> csDI
             AND C.SSBSECT_SSTS_CODE = csA
             AND C.SSBSECT_TERM_CODE = vsTerm
             AND C.SSBSECT_CAMP_CODE = vsCamp
             AND NVL (C.SSBSECT_GMOD_CODE, cs0) <> csS
             AND NVL (C.SSBSECT_GMOD_CODE, cs0) <> csX;

   DELETE FWRHORS;

   INSERT INTO FWRHORS (FWRHORS_PIDM,
                        FWRHORS_TERM_CODE,
                        FWRHORS_CRN,
                        FWRHORS_ROOM_CODE)
      SELECT sirasg.asgnPidm,
             sirasg.termCode,
             sirasg.asgnCrnn,
             sirasg.deptSede
        FROM (SELECT DISTINCT SIRASGN_PIDM AS asgnPidm,
                              SIRASGN_TERM_CODE AS termCode,
                              SIRASGN_CRN AS asgnCrnn,
                              NVL (SIRDPC.deptSede, csSinSede) AS deptSede
                FROM SIRASGN,
                     (SELECT SIRDPCL_PIDM AS dpclPidm,
                             SIRDPCL_DEPT_CODE AS deptSede
                        FROM SIRDPCL A
                       WHERE SIRDPCL_HOME_IND = csY
                             AND SIRDPCL_TERM_CODE_EFF =
                                    (SELECT MAX (SI.SIRDPCL_TERM_CODE_EFF)
                                       FROM SIRDPCL SI
                                      WHERE SI.SIRDPCL_PIDM = A.SIRDPCL_PIDM
                                            AND SI.SIRDPCL_TERM_CODE_EFF <=
                                                   vsTerm)) SIRDPC
               WHERE SIRASGN_PIDM = SIRDPC.dpclPidm(+)
                     AND (SIRASGN_CRN, SIRASGN_TERM_CODE) IN
                            (SELECT SWRPGAC_CRN, SWRPGAC_TERM_CODE
                               FROM SWRPGAC)
                     AND SIRASGN_PRIMARY_IND = csY
                     AND (NVL (SIRDPC.deptSede, csSinSede) = vsSede
                          OR vsSede IS NULL)) sirasg;

   DELETE FWRSIRG;

   INSERT INTO FWRSIRG (FWRSIRG_PIDM,
                        FWRSIRG_TERM_CODE,
                        FWRSIRG_CRN,
                        FWRSIRG_DEPT_CODE,
                        FWRSIRG_COLL_CODE)
      SELECT FWRHORS_PIDM,
             SWRPGAC_TERM_CODE,
             SWRPGAC_CRN,
             FWRHORS_ROOM_CODE,
             SWRPGAC_COLL_CODE
        FROM SWRPGAC, FWRHORS
       WHERE SWRPGAC_TERM_CODE = FWRHORS_TERM_CODE
             AND SWRPGAC_CRN = FWRHORS_CRN;
END PWAAVPG;
/


DROP PUBLIC SYNONYM PWAAVPG;

CREATE PUBLIC SYNONYM PWAAVPG FOR BANINST1.PWAAVPG;

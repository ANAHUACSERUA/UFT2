DROP PROCEDURE BANINST1.PWAISSBSECT;

CREATE OR REPLACE PROCEDURE BANINST1.PWAISSBSECT(psCampCode VARCHAR2 DEFAULT NULL,
                                                   psTermCode VARCHAR2 DEFAULT NULL,
                                                   psCollCode VARCHAR2 DEFAULT NULL,
                                                   psSubjCode VARCHAR2 DEFAULT NULL,
                                                   psSstsCode VARCHAR2 DEFAULT NULL,
                                                   psPtrmCode VARCHAR2 DEFAULT NULL
                                                  ) IS

  /*
     Tarea: Insertar datos para la optimización de consultas
     Fecha: 24/05/2010
     Autor: GEPC             U  F  T

            Observaciones: El proceso es llamdo en
                           -- PWRPGAC
                           -- PWRPGA2
                           -- PWRINDR
                           -- PWRFMPS

     Modif:  21 ENE 2011
        * JCCR
        - Se Agregarón las Columnas de SWRPGAC_SECT_TITLE, SWRPGAC_SESS_CODE, para igusalarlo a RUA
        - campo SWRPGAC_SESS_CODE por Modificaciones e UFT Reporte PWRPGAC


  */

  csEsp CONSTANT VARCHAR2(1) := ' ';
  csSlh CONSTANT VARCHAR2(1) := '/';
  csA   CONSTANT VARCHAR2(1) := 'A';

  BEGIN
      INSERT INTO SWRPGAC
      (SWRPGAC_TERM_CODE, SWRPGAC_CAMP_CODE, SWRPGAC_CRN,        SWRPGAC_SSTS_CODE,
       SWRPGAC_SCHD_CODE, SWRPGAC_INSM_CODE, SWRPGAC_SUBJ_CODE,  SWRPGAC_PTRM_CODE,
       SWRPGAC_CRSE_NUMB, SWRPGAC_TITLE,     SWRPGAC_CONT_HR_LOW,SWRPGAC_CREDIT_HR_LOW,
       SWRPGAC_SEQ_NUMB,  SWRPGAC_MAX_ENRL,  SWRPGAC_ENRL,       SWRPGAC_COLL_CODE,
       SWRPGAC_GMOD_CODE, SWRPGAC_PTRM,      SWRPGAC_SECT_TITLE, SWRPGAC_SESS_CODE
      )
      SELECT
       SSBSECT_TERM_CODE, SSBSECT_CAMP_CODE, SSBSECT_CRN,        SSBSECT_SSTS_CODE,
       SSBSECT_SCHD_CODE, SSBSECT_INSM_CODE, SCBCRSE_SUBJ_CODE,  SSBSECT_PTRM_CODE||csEsp||SSBSECT_PTRM_START_DATE||csEsp||SSBSECT_PTRM_END_DATE||csEsp||SSBSECT_PTRM_WEEKS,
       SCBCRSE_CRSE_NUMB, SCBCRSE_TITLE,     SCBCRSE_CONT_HR_LOW,SCBCRSE_CREDIT_HR_LOW,
       SSBSECT_SEQ_NUMB,  SSBSECT_MAX_ENRL,  SSBSECT_ENRL,       NVL(SSBOVRR_COLL_CODE,SCBCRSE_COLL_CODE),
       SSBSECT_GMOD_CODE, SSBSECT_PTRM_CODE, SSBSECT_CRSE_TITLE, SSBSECT_SESS_CODE
        FROM SSBSECT,
             SCBCRSE,
             SSBOVRR
       WHERE SSBSECT_SUBJ_CODE     = SCBCRSE_SUBJ_CODE
         AND SSBSECT_CRSE_NUMB     = SCBCRSE_CRSE_NUMB
         AND SCBCRSE_EFF_TERM      = (SELECT MAX(SC.SCBCRSE_EFF_TERM)
                                        FROM SCBCRSE SC
                                       WHERE SC.SCBCRSE_EFF_TERM <= SSBSECT_TERM_CODE
                                         AND SC.SCBCRSE_SUBJ_CODE = SSBSECT_SUBJ_CODE
                                         AND SC.SCBCRSE_CRSE_NUMB = SSBSECT_CRSE_NUMB
                                     )
         AND SSBSECT_SSTS_CODE     = csA
         AND SSBSECT_TERM_CODE     = SSBOVRR_TERM_CODE(+)
         AND SSBSECT_CRN           = SSBOVRR_CRN(+)
         AND (SSBSECT_CAMP_CODE                                        = psCampCode OR psCampCode IS NULL)
         AND (SSBSECT_TERM_CODE                                        = psTermCode OR psTermCode IS NULL)
         AND (NVL(SSBOVRR_COLL_CODE,SCBCRSE_COLL_CODE)                 = psCollCode OR psCollCode IS NULL)
         AND (SCBCRSE_SUBJ_CODE                                        = psSubjCode OR psSubjCode IS NULL)
         AND (SSBSECT_SSTS_CODE                                        = psSstsCode OR psSstsCode IS NULL)
         AND (INSTR(csSlh||psPtrmCode,csSlh||SSBSECT_PTRM_CODE||csSlh) > 0          OR psPtrmCode = csSlh OR psPtrmCode IS NULL);


  END PWAISSBSECT;
/

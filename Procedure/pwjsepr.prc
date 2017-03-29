DROP PROCEDURE BANINST1.PWJSEPR;

CREATE OR REPLACE PROCEDURE BANINST1.PWJSEPR(pdNextDate IN OUT DATE) IS
/*
          Tarea: Ejecuta el procedimiento pk_ProcesoSeprad
         Modulo: Evaluación Docente
          Autor: MAC
          Fecha: 16/11/2010

*/

  TYPE reg_Camps IS RECORD (rTermCode VARCHAR2(10),
                            rPtrmCode VARCHAR2(10),
						                      rCampCode VARCHAR2(10)
                           );

  TYPE tableCamps IS TABLE OF reg_Camps INDEX BY BINARY_INTEGER;

  tabCamp        tableCamps;
  vnRow          INTEGER      := 0;
  vnExiste       INTEGER      := 1;
  vsCamp         VARCHAR2(10) := NULL;

  --cuStatus
  CURSOR cuStatus IS
         SELECT encuesta.TERM AS termCode,
                encuesta.PTRM AS ptrmCode,
                encuesta.CAMP AS campCode,
                encuesta.TSSC AS tsscCode
           FROM (SELECT SVRESAF_TERM_CODE            AS TERM,
                        SSBSECT_PTRM_CODE            AS PTRM,
                        SSBSECT_CAMP_CODE            AS CAMP,
                        SVRESAF_TSSC_CODE            AS TSSC,
                        MIN(SVRESAF_DTES_BEGIN_DATE) AS MIND,
                        MAX(SVRESAF_DTES_END_DATE)   AS MAXD
                   FROM SVRESAF,SSBSECT
                  WHERE SVRESAF_TERM_CODE = SSBSECT_TERM_CODE
                    AND SVRESAF_CRN       = SSBSECT_CRN
                  GROUP BY SVRESAF_TERM_CODE,
                           SSBSECT_PTRM_CODE,
                           SSBSECT_CAMP_CODE,
                           SVRESAF_TSSC_CODE
                ) encuesta
          WHERE TRUNC(SYSDATE) BETWEEN TRUNC(encuesta.MIND) AND TRUNC(encuesta.MAXD+4)
          ORDER BY encuesta.CAMP,
                   encuesta.TERM DESC,
                   encuesta.PTRM;

  CURSOR cuCampus IS
         SELECT encuesta.TERM termCode,
                encuesta.PTRM ptrmCode,
                encuesta.CAMP campCode
           FROM (SELECT SVRESAF_TERM_CODE            TERM,
                        SSBSECT_PTRM_CODE            PTRM,
                        SSBSECT_CAMP_CODE            CAMP,
                        MIN(SVRESAF_DTES_BEGIN_DATE) MIND,
                        MAX(SVRESAF_DTES_END_DATE)   MAXD
                   FROM SVRESAF,SSBSECT
                  WHERE SVRESAF_TERM_CODE = SSBSECT_TERM_CODE
                    AND SVRESAF_CRN       = SSBSECT_CRN
                  GROUP BY SVRESAF_TERM_CODE,SSBSECT_PTRM_CODE,SSBSECT_CAMP_CODE
                ) encuesta
          WHERE TRUNC(SYSDATE) BETWEEN TRUNC(encuesta.MIND) AND TRUNC(encuesta.MAXD+4)
          ORDER BY encuesta.CAMP,
                   encuesta.TERM DESC,
                   encuesta.PTRM;

  CURSOR cuComparativo IS
         SELECT DISTINCT encuesta.TERM termCode,
                         encuesta.CAMP campCode
           FROM (SELECT SVRESAF_TERM_CODE            TERM,
                        SSBSECT_CAMP_CODE            CAMP,
                        MIN(SVRESAF_DTES_BEGIN_DATE) MIND,
                        MAX(SVRESAF_DTES_END_DATE)   MAXD
                   FROM SVRESAF,SSBSECT
                  WHERE SVRESAF_TERM_CODE = SSBSECT_TERM_CODE
                    AND SVRESAF_CRN       = SSBSECT_CRN
                  GROUP BY SVRESAF_TERM_CODE,SSBSECT_CAMP_CODE
                ) encuesta
          WHERE TRUNC(SYSDATE) BETWEEN TRUNC(encuesta.MIND) AND TRUNC(encuesta.MAXD+4)
          ORDER BY encuesta.CAMP,
                   encuesta.TERM DESC;

  BEGIN
      SELECT COUNT(1)
        INTO vnExiste
        FROM SWRERRP
       WHERE SWRERRP_ETAPA       = 'BEGIN'
         AND TRUNC(SWRERRP_DATE) = TRUNC(SYSDATE);

      IF vnExiste = 0 THEN
         FOR regEnc IN cuStatus LOOP
             kwaprsp.statusDeEvaluacion(regEnc.termCode, regEnc.tsscCode, regEnc.ptrmCode, regEnc.campCode);
         END LOOP;

         --Se obtiene los campus que estan aplicando el SEPRAD por periodo y parte de periodo
         FOR regCmp IN cuCampus LOOP
             vnRow := vnRow + 1;

             tabCamp(vnRow).rTermCode := regCmp.termCode;
             tabCamp(vnRow).rPtrmCode := regCmp.ptrmCode;
             tabCamp(vnRow).rCampCode := regCmp.campCode;
         END LOOP;

         --Borra las evaluaciones que se estan aplicando para recalcular los promedios
         FOR vnI IN 1..vnRow LOOP
             DELETE FROM SWRSEPR
              WHERE SWRSEPR_TERM_CODE = tabCamp(vnI).rTermCode
                AND SWRSEPR_CAMP_CODE = tabCamp(vnI).rCampCode
                AND SWRSEPR_PTRM_CODE = tabCamp(vnI).rPtrmCode;

             DELETE FROM SWBSEPR
              WHERE SWBSEPR_TERM_CODE = tabCamp(vnI).rTermCode
                AND SWBSEPR_CAMP_CODE = tabCamp(vnI).rCampCode
                AND SWBSEPR_PTRM_CODE = tabCamp(vnI).rPtrmCode;

             DELETE FROM SWBSEPG
              WHERE SWBSEPG_TERM_CODE = tabCamp(vnI).rTermCode
                AND SWBSEPG_CAMP_CODE = tabCamp(vnI).rCampCode
                AND SWBSEPG_PTRM_CODE = 'GLOBAL';

             DELETE FROM SWBSEPG
              WHERE SWBSEPG_TERM_CODE = tabCamp(vnI).rTermCode
                AND SWBSEPG_CAMP_CODE = tabCamp(vnI).rCampCode
                AND SWBSEPG_PTRM_CODE = tabCamp(vnI).rPtrmCode;

             COMMIT;
         END LOOP;


         --Se calcula el promedio de los cursos
         FOR vnI IN 1..vnRow LOOP


             kwaprsp.PromedioListaCruzada  (tabCamp(vnI).rTermCode,
                                            tabCamp(vnI).rCampCode,
                                            tabCamp(vnI).rPtrmCode,'JobSEPRA1','BEGIN'
                                           );

             kwaprsp.PromedioMaestro       (tabCamp(vnI).rTermCode,
                                            tabCamp(vnI).rCampCode,
                                            tabCamp(vnI).rPtrmCode,'JobSEPRA2','BEGIN'
                                           );

             kwaprsp.PromedioSimultaneo    (tabCamp(vnI).rTermCode,
                                            tabCamp(vnI).rCampCode,
                                            tabCamp(vnI).rPtrmCode,'JobSEPRA3','BEGIN'
                                           );

             kwaprsp.PromedioIndependiente (tabCamp(vnI).rTermCode,
                                            tabCamp(vnI).rCampCode,
                                            tabCamp(vnI).rPtrmCode,'JobSEPRA4','BEGIN'
                                           );

             kwaprsp.InscritosSepradLista  (tabCamp(vnI).rTermCode,
                                            tabCamp(vnI).rCampCode,
                                            tabCamp(vnI).rPtrmCode,'JobSEPRA5','BEGIN'
                                           );

             kwaprsp.InscritosSepradNoLista(tabCamp(vnI).rTermCode,
                                            tabCamp(vnI).rCampCode,
                                            tabCamp(vnI).rPtrmCode,'JobSEPRA6','BEGIN'
                                           );

             kwaprsp.Bruto                 (tabCamp(vnI).rTermCode,
                                            tabCamp(vnI).rCampCode,
                                            tabCamp(vnI).rPtrmCode,'JobSEPRA7','BEGIN'
                                           );

             kwaprsp.PromedioPartePeriodo  (tabCamp(vnI).rTermCode,
                                            tabCamp(vnI).rCampCode,
                                            tabCamp(vnI).rPtrmCode,'JobSEPR10','BEGIN'
                                           );

         END LOOP;


         --se limpia los datos de la tabla
         FOR vnI IN 1..vnRow LOOP
             tabCamp(vnI).rTermCode := NULL;
             tabCamp(vnI).rCampCode := NULL;
             tabCamp(vnI).rPtrmCode := NULL;
         END LOOP;

         vnRow := 0;

         --Se obtiene los campus que estan aplicando el SEPRAD por periodo.
         FOR regCmp IN cuComparativo LOOP
             vnRow := vnRow + 1;

             tabCamp(vnRow).rTermCode := regCmp.termCode;
             tabCamp(vnRow).rCampCode := regCmp.campCode;
         END LOOP;

         --Se calcula el promedio por univeridad y periodo
         FOR vnI IN 1..vnRow LOOP
             kwaprsp.PromedioGlobal(tabCamp(vnI).rTermCode,
                                    tabCamp(vnI).rCampCode,
                                    'GLOBAL','JobSEPRA9','BEGIN'
                                   );

             kwaprsp.TablaBase     (tabCamp(vnI).rTermCode,
                                    tabCamp(vnI).rCampCode,
                                    'JobSEPR11','BEGIN'
                                   );
         END LOOP;

      END IF;

      pdNextDate := TO_DATE(TO_CHAR(SYSDATE+1,'DD/MM/YYYY')||' '||'01:00:00','DD/MM/YYYY HH24:MI:SS');

  END PWJSEPR;
/

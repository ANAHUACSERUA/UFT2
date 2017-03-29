DROP PROCEDURE BANINST1.PWJCREV;

CREATE OR REPLACE PROCEDURE BANINST1.PWJCREV(pdNextDate IN OUT DATE) IS
  /*
  Tarea: Ejecuta el procedimiento p_CriteriosDeEvaluacion con diferente VPDI
  Autor: GEPC
  Fecha: 31/03/2008

  */

  cn1        CONSTANT NUMBER(1)   := 1;
  cs000      CONSTANT VARCHAR2(3) := '000';
  cdSysDate  CONSTANT DATE        := SYSDATE;
  cdNext     CONSTANT DATE        := TO_DATE(TO_CHAR(cdSysDate,'DD/MM/YYYY')||' '||'10:00:00','DD/MM/YYYY HH24:MI:SS');
  cdInterval CONSTANT DATE        := TO_DATE(TO_CHAR(cdSysDate,'DD/MM/YYYY')||' '||'15:00:00','DD/MM/YYYY HH24:MI:SS');

  BEGIN
      PWACREV;

      IF cdSysDate >= cdNext AND cdSysDate <= cdInterval THEN
         pdNextDate := cdInterval;
      ELSE
         pdNextDate := cdNext + cn1;
      END IF;

  END PWJCREV;
/

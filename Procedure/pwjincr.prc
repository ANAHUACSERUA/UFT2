DROP PROCEDURE BANINST1.PWJINCR;

CREATE OR REPLACE PROCEDURE BANINST1.PWJINCR(pdNextDate IN OUT DATE) IS
/*
   Tarea: Eliminar inconsistencia de Banner
   Autor: GEPC
   Fecha: 27/07/2010

*/

  csOE              CONSTANT VARCHAR2(2)  := 'OE';
  cs201010          CONSTANT VARCHAR2(6)  := '201010';
  csDDMMYYYY        CONSTANT VARCHAR2(10) := 'DD/MM/YYYY';
  cn2               CONSTANT NUMBER(1)    := 2;
  cn0p5             CONSTANT NUMBER(3,2)  := 0.5;
  cn60              CONSTANT NUMBER(2)    := 60;
  cdSysDate         CONSTANT DATE         := SYSDATE;
  cdNext            CONSTANT DATE         := TO_DATE(TO_CHAR(cdSysDate+1,csDDMMYYYY)||' '||'06:00:00','DD/MM/YYYY HH24:MI:SS');
  cdLimiteEjecucion CONSTANT DATE         := TO_DATE(TO_CHAR(cdSysDate,  csDDMMYYYY)||' '||'23:00:00','DD/MM/YYYY HH24:MI:SS');

  BEGIN

      DELETE FROM SHRMRKA
       WHERE LTRIM(SHRMRKA_GRDE_CODE) IS NULL
         AND SHRMRKA_AUDIT_SEQ_NO     >= cn2
         AND SHRMRKA_GCHG_CODE         = csOE
         AND SHRMRKA_TERM_CODE        >= cs201010;

      COMMIT;

      IF cdSysDate >= cdLimiteEjecucion THEN
         pdNextDate := cdNext;
      ELSE
         pdNextDate := cdSysDate + cn0p5/cn60;
      END IF;

  END PWJINCR;
/

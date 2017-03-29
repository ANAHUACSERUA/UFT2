DROP PROCEDURE BANINST1.PWJCCRM;

CREATE OR REPLACE PROCEDURE BANINST1.PWJCCRM(pdNextDate IN OUT DATE) IS

  vsError           VARCHAR2(4000) := NULL;
  vdInterval        DATE           := SYSDATE;
  vdNext            DATE           := TO_DATE(TO_CHAR(SYSDATE+1,'DD/MM/YYYY')||' '||'07:00:00','DD/MM/YYYY HH24:MI:SS');
  vdLimiteEjecucion DATE           := TO_DATE(TO_CHAR(SYSDATE,  'DD/MM/YYYY')||' '||'22:00:00','DD/MM/YYYY HH24:MI:SS');
  csPINSORT         VARCHAR2(7);


  csSysDateI CONSTANT DATE        := SYSDATE;

  --insertIni

  --intervalo
  procedure intervalo is

  begin
      if sysdate >= vdLimiteEjecucion then
         pdNextDate := vdNext;
      else
         pdNextDate := vdInterval + 1/100;
      end if;
  end intervalo;

  BEGIN
      PK_CARGAPSU.p_InsertaSortestInd;

      intervalo;



  EXCEPTION
      WHEN OTHERS THEN
           vsError := SQLERRM;

           --determina el intervalo de nueva ejecución
           intervalo;

           INSERT INTO GWRERRM(GWRERRM_ERROR,GWRERRM_ORIGIN) VALUES(vsError, csPINSORT);

           COMMIT;

  END PWJCCRM;
/

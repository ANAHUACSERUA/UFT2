DROP PROCEDURE BANINST1.PWJICRM;

CREATE OR REPLACE PROCEDURE BANINST1.PWJICRM(pdNextDate IN OUT DATE) IS

  vsError           VARCHAR2(4000) := NULL;
  vdInterval        DATE           := SYSDATE;
  vdNext            DATE           := TO_DATE(TO_CHAR(SYSDATE+1,'DD/MM/YYYY')||' '||'07:00:00','DD/MM/YYYY HH24:MI:SS');
  vdLimiteEjecucion DATE           := TO_DATE(TO_CHAR(SYSDATE,  'DD/MM/YYYY')||' '||'22:00:00','DD/MM/YYYY HH24:MI:SS');
  csPININD         VARCHAR2(7);


  csSysDateI CONSTANT DATE        := SYSDATE;

  --insertIni

  --intervalo
  procedure intervalo is

  begin
      if sysdate >= vdLimiteEjecucion then
         pdNextDate := vdNext;
      else
         pdNextDate := vdInterval + 5/1440;
      end if;
  end intervalo;

  BEGIN
      PK_CARGAINDIVIDUAL.p_carga;

      intervalo;



  EXCEPTION
      WHEN OTHERS THEN
           vsError := SQLERRM;

           --determina el intervalo de nueva ejecución
           intervalo;

           INSERT INTO GWRERRM(GWRERRM_ERROR,GWRERRM_ORIGIN) VALUES(vsError, csPININD);

           COMMIT;

  END PWJICRM;
/


DROP PUBLIC SYNONYM PWJICRM;

CREATE PUBLIC SYNONYM PWJICRM FOR BANINST1.PWJICRM;

DROP PROCEDURE BANINST1.PWJPCRM;

CREATE OR REPLACE PROCEDURE BANINST1.PWJPCRM(pdNextDate IN OUT DATE) IS

  vsError           VARCHAR2(4000) := NULL;
  vdInterval        DATE           := SYSDATE;
  vdNext            DATE           := TO_DATE(TO_CHAR(SYSDATE+1,'DD/MM/YYYY')||' '||'07:00:00','DD/MM/YYYY HH24:MI:SS');
  vdLimiteEjecucion DATE           := TO_DATE(TO_CHAR(SYSDATE,  'DD/MM/YYYY')||' '||'22:00:00','DD/MM/YYYY HH24:MI:SS');


  csPWAGWBT  CONSTANT VARCHAR2(7) := 'PWAGWBT';
  csPWATCRM  CONSTANT VARCHAR2(7) := 'PWATCRM';
  csPWJPCRM  CONSTANT VARCHAR2(7) := 'PWJPCRM';
  csSysDateI CONSTANT DATE        := SYSDATE;

  --insertIni
  procedure insertIni(psCode varchar2) is

  begin
      insert into gwbpcrm
      (
       gwbpcrm_code,gwbpcrm_date_beg
      )
      values
      (
       psCode,      csSysDateI
      );

      commit;
  end insertIni;

  --updateEnd
  procedure updateEnd(psCode varchar2) is

  csSysDateU constant date := sysdate;

  begin
      update gwbpcrm
         set gwbpcrm_date_end = csSysDateU
       where gwbpcrm_code     = psCode
         and gwbpcrm_date_beg = csSysDateI;

      commit;
  end updateEnd;

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
      insertIni(csPWAGWBT);

      -- * Consulta de admiciones para alimentar la lectura del CRM
      -- para los periodos definidos en "GWBTERM".
      PWAGWBT;

      updateEnd(csPWAGWBT);
      insertIni(csPWATCRM);

      -- * Consulta de admiciones para alimentar la lectura del CRM
      -- y carga las diferencias.
      PWATCRM;

      updateEnd(csPWATCRM);

      --determina el intervalo de nueva ejecución
      intervalo;

      PWATRNT('GWBTCRM');
      PWATRNT('GWBTCR0');
      PWATRNT('GWBTCR1');
      PWATRNT('GWBTCR2');
      PWATRNT('GWBTCR3');

  EXCEPTION
      WHEN OTHERS THEN
           vsError := SQLERRM;

           --determina el intervalo de nueva ejecución
           intervalo;

           INSERT INTO GWRERRM(GWRERRM_ERROR,GWRERRM_ORIGIN) VALUES(vsError, csPWJPCRM);

           COMMIT;

  END PWJPCRM;
/

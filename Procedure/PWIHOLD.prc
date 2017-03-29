CREATE OR REPLACE PROCEDURE BANINST1.PWIHOLD
IS

  -- DECLARACION DE VARIABLES LOCALES
    vnVencimiento  NUMBER := 20;
  csAC varchar2(2)  :='AC';
  csCE varchar2(2)  :='CE';
  csJC varchar2(2)  :='JC';
  csJG varchar2(2)  :='JG';
  csPR varchar2(2)  :='PR'; 
  csRE varchar2(2)  :='RE';
  csTR varchar2(2)  :='TR';
  csAA varchar2(2)  :='AA';
  csN  varchar2(1)  :='N';
  csSh varchar2(1)  :='/';
  csOrigen varchar2(10)  := 'AUTOMATICO';
  cfFecha  DATE  := '31/12/2099';
  

    -- CURSOR QUE BUSCA ALUMNOS MOROSOS
    CURSOR cuMorosos IS
    select twbdocu_pidm PIDM,TWBDOCU_SEQ_NUM DOCU, SUBSTR(TWBDOCU_TERM_CODE,1,4)ANIO, TWBDOCU_PAYM_CODE MPAGO, TWBDOCU_CNTR_NUM CONTRATO, TWBDOCU_EXPIRATION_DATE FECHA, m.TWRDOMV_STATUS_IND ESTATUS from twbdocu d,  twrdomv m
    where m.TWRDOMV_DOCU_SEQ_NUM = d.TWBDOCU_SEQ_NUM
    and  m.TWRDOMV_MOVE_NUM = (SELECT MAX(DOMV2.TWRDOMV_MOVE_NUM)
                           FROM  TWRDOMV DOMV2
                           WHERE DOMV2.TWRDOMV_DOCU_SEQ_NUM = m.TWRDOMV_DOCU_SEQ_NUM  )
    and m.TWRDOMV_STATUS_IND IN (csAC, csCE, csJC, csJG, csPR, csRE)       
--  and twbdocu_term_code like  '2015%'
    and trunc(TWBDOCU_EXPIRATION_DATE + vnVencimiento) <= trunc(sysdate)
    and TWBDOCU_CNTR_NUM is not null
    and not exists (select 1 from SWECRAA
                    where SWECRAA_CNTR_NUM = TWBDOCU_CNTR_NUM
                    and SWECRAA_TERM_CODE = TWBDOCU_TERM_CODE)
    and not EXISTS   (select 1 
               from SPRHOLD
               where  SPRHOLD_HLDD_CODE = csAA
               and    SPRHOLD_PIDM = d.twbdocu_pidm 
               and   SPRHOLD_AMOUNT_OWED= d.TWBDOCU_SEQ_NUM
               and    SPRHOLD_RELEASE_IND = csN )
order by d.TWBDOCU_PIDM;
    -- CURSOR QUE CARGA LOS PROGRAMAS DEL ESTUDIANTE



    -- CURSOR QUE CARGA LOS TIPOS DE CERTIFICADOS
BEGIN
  
    FOR ReHolds IN cuMorosos LOOP
    
    INSERT INTO SPRHOLD
    values (ReHolds.PIDM, csAA, USER, trunc(sysdate), cfFecha, csN, ReHolds.CONTRATO||csSh||TO_CHAR(ReHolds.FECHA, 'MM')||csSh||ReHolds.MPAGO||csSh||ReHolds.ESTATUS||csSh||ReHolds.ANIO, ReHolds.DOCU, null, SYSDATE,cfFecha);


    END LOOP;

  COMMIT;
END PWIHOLD;
/
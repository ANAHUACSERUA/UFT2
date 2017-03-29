DROP PROCEDURE BANINST1.PK_CREACONTATO_DOCUMENTO;

CREATE OR REPLACE PROCEDURE BANINST1.pk_CreaContato_Documento is
/******************************************************************************
Nombre de Script:   pk_CreaContato_Documento
Objetivo:           Crea el contrato y sus documentos por  N $.
Autor:              Roman Ruiz
Fecha:              10-dic-2013
******************************************************************************/

/*AGREGAMOS $ A DOCUMENTO */

    vnNumTran       TBRACCD.TBRACCD_TRAN_NUMBER%TYPE;
    vnNumSeqDoc     TWBDOCU.TWBDOCU_SEQ_NUM%TYPE;
    vsCuenta        TWVACNT.TWVACNT_ACCOUNT%TYPE;
    vsCCosto        TWVCCTS.TWVCCTS_CODE%TYPE;
    vsPrograma      SGBSTDN.SGBSTDN_PROGRAM_1%TYPE;
    vsRes           VARCHAR2(1);
    vsMsg           VARCHAR2(4000);
    vsPIDM          NUMBER(8);
    vsPeriodo       VARCHAR2(6);
    vsContrato      VARCHAR2(10);
    viLargo         number(4);
    ciContrato      number(2);
    viSalva         number(4);

BEGIN
   vsPIDM:= null;
   vsPeriodo:='201075';   -- AQUI VA EL PERIODO
   vsContrato := null;
   vnNumTran := NULL;
   vnNumSeqDoc := NULL;
   vsCuenta := '';
   vsCCosto := '';
   vsRes := '';
   vsMsg := '';
   vsPrograma := null;
   viLargo := 0;
   ciContrato := 10;  --log max de un contato
   viSalva    := 0;

   for curMoroso in (select distinct TWRCLMR_CONTRACT, TWRCLMR_CCTS_CODE, TWRCLMR_RUT_ALUM , TWRCLMR_RUT_APO
                     from TWRCLMR ) loop
                   --  where   TWRCLMR_CONTRACT =  '102849-9') loop   --debug..

      viSalva := viSalva + 1;

      for curPers in (select SPBPERS_PIDM from spbpers
                      where spbpers_name_suffix = curMoroso.TWRCLMR_RUT_ALUM) loop

          vsPIDM := curPers.SPBPERS_PIDM;

          vsContrato := curMoroso.TWRCLMR_CONTRACT;

          select length( vsContrato) into viLargo  from dual;

          if viLargo > 3 then
             viLargo := viLargo +1;
          end if;

          FOR Lcntr IN viLargo..ciContrato  LOOP

              vsContrato := '0'||vsContrato;

          END LOOP;


          -- programa
          for curProg in (select SGBSTDN_PROGRAM_1
                          from sgbstdn
                          where SGBSTDN_PIDM = vsPIDM
                          and SGBSTDN_TERM_CODE_EFF = (select max( sdnt.SGBSTDN_TERM_CODE_EFF)
                                                      from sgbstdn sdnt
                                                      where sdnt.SGBSTDN_PIDM = vsPIDM)) loop

              vsPrograma := curProg.SGBSTDN_PROGRAM_1;

          end loop; -- end programa

          if vsPrograma is null then
             exit;
          end if;

          -- inserta contrato..
          INSERT INTO TWBCNTR VALUES (vsPIDM,     vsContrato,
                                      vsPeriodo,  curMoroso.TWRCLMR_RUT_APO,
                                      SYSDATE,    'A',
                                      SYSDATE,    'BANSECR',
                                      vsPrograma,  null,
									  'BANSECR',  null,
									  null,     null,
									  null,     null);

          -- documentos a insertar
          for curDoctos in (select * from TWRCLMR
                            where  TWRCLMR_CONTRACT = curMoroso.TWRCLMR_CONTRACT) loop

              vnNumSeqDoc := pk_Matricula.f_InsDocAuto(vsPIDM
                                                      ,vsPeriodo
                                                      ,'CUP'
                                                      ,curDoctos.TWRCLMR_AMOUNT
                                                      ,'AC'
                                                      ,curDoctos.TWRCLMR_CANCEL_DATE );

              UPDATE TWBDOCU SET  TWBDOCU_CNTR_NUM = vsContrato
              WHERE TWBDOCU_SEQ_NUM = vnNumSeqDoc;

              commit;

              --Creo la transaccion en TBRACCD
              vnNumTran := pk_Matricula.f_InsertaCargo(vsPIDM
                                                       ,curDoctos.TWRCLMR_AMOUNT
                                                       ,'MGAR'
                                                       ,vsPeriodo
                                                       ,'T'
                                                       ,USER );

              commit;
              --Creo TWRDOTR
              pk_Matricula.p_insTranDocu(vsPIDM
                                       ,vnNumTran
                                       ,vnNumSeqDoc
                                       ,curDoctos.TWRCLMR_AMOUNT
                                       ,'Y'
                                       ,SYSDATE
                                       ,NULL);

               commit;
               -- inserto encabezado en cotabilidad para no generar contabilización
               insert into TWRADMV values (vnNumSeqDoc
                                          ,1 --,vnNumTran
                                          ,curDoctos.TWRCLMR_AMOUNT
                                          ,curDoctos.TWRCLMR_ACCOUNT
                                          ,curDoctos.TWRCLMR_CCTS_CODE
                                          ,'Y'
                                          ,sysdate
                                          ,'banner');

                commit;
                -- actualizo info en tabla principal del proceso

                update TWRCLMR set  TWRCLMR_DOCU_SEQ_NUM = vnNumSeqDoc , TWRCLMR_MOVE_NUM = vnNumTran
                 where TWRCLMR_CONTRACT = curMoroso.TWRCLMR_CONTRACT
                 and  TWRCLMR_ACCOUNT   = curDoctos.TWRCLMR_ACCOUNT
                 and  TWRCLMR_AMOUNT    = curDoctos.TWRCLMR_AMOUNT;

                 commit;
          end loop; -- doctos

      end loop; -- for pers

      if viSalva = 500 then
         commit;
         viSalva := 0;
      end if;

   end loop;  -- for pricipal

   COMMIT;

END   pk_CreaContato_Documento;
/

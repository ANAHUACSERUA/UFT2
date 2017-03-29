CREATE OR REPLACE PROCEDURE BANINST1.PWCLADO (psReclDesc VARCHAR2)
IS
/******************************************************************************
PROCEDIMIENTO:          BANINST1.PWCLADO
OBJETIVO:               Reporte de Clasificación de Documentos
AUTORES:                Guillermo Almazan Ibañez
FECHA:                  10/12/2010
******************************************************************************/
/****************************************************************
modificacion :          md-01 se elimina la columna programa y se agrega estado del documento
autor        :          Virgilio De la Cruz
fecha        :          20130903

modify: se agrego un parametro para la consulta, por nivel,
ademas se modifico la estructura del  cursor para que sea mas rapido.
BY glovicx@19-may-2014.
modify    07-jul-2014  se cambiaron los filtro de nivel y programa x nueva funcionalidad.


modificacion :          md-03 se agrega multiseleccion al campo de nivel.
autor        :          roman ruiz
fecha        :          18-jun-2014

modificacion :          md-04 se cambia de sbstdn a contrato el campo de nivel.
autor        :          roman ruiz
fecha        :          18-ago-2014

modificacion :          md-05 se agregan los campos de intereses y descuento de pronto pago
autor        :          Virgilio De la Cruz
fecha        :          10-feb-2015

modificacion :          md-06 se agregan si lleva intereses
autor        :          Roman Ruiz
fecha        :          24-abr-2015  


nota: se intento hacer como sql dinamico (pero el armado del sql tuvo problemas y
       se hizo con 3 cursores. practicmante iguales.. por lo que si hay que hacer cambio futuro
       y el cambio impacta al sql se deberá hacer en los 3 cursores.

modificacion :          md-07 se agregan filtro y columna de Status Contrato
autor        :          Virgilio De la Cruz
fecha        :          07-agosto-2015

modificacion :          md-08 se modifca el formato de canidades para que salgan puntos y comas 
autor        :          Roman Ruiz
fecha        :          16-may-2016


******************************************************************************/
   vnRow         INTEGER := 0;
   vnExists      INTEGER := 0;
   vnColumnas    INTEGER := 22;
   vsProg       smrprle.smrprle_program_desc%TYPE;
   vsType       stvstyp.stvstyp_code%TYPE;
  -- vsYear       VARCHAR2(4);
   vdIni        twbcntr.twbcntr_issue_date%TYPE;
   vdFin        twbcntr.twbcntr_issue_date%TYPE;
   vsCont       twbcntr.twbcntr_num%TYPE;
   vsPago       twvpaym.twvpaym_code%TYPE;
   vsTaDo       varchar2(100);
   tabColumna   Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vsInicioPag  VARCHAR2 (10) := NULL;
   vslevl       varchar2(1000); -- VARCHAR2(10);  md-03
   csSlh        CONSTANT VARCHAR2(1)    := '/';   --md-03
   vsYear       VARCHAR2(4);
   vsStCntr     VARCHAR2(1);--md-07
--md-06  start
  vsInteres    char(1) := null;
  
   vsMonto_cnt  varchar2(20); 
   vsMonto_doc  varchar2(20);
   vsInter      varchar2(20);
   vsDescuento  varchar2(20);
   
   vsMonto_test varchar2(20);       --md-0x
   vst1         varchar2(20);
   vst2         varchar2(20);
   vst3         varchar2(20);
   

  type t_DetOper is record(
      anio            varchar2(4),
      term            varchar2(6),
      contrato        varchar2(10),
      statuscntr      varchar2(1), --md-07
      secuencia       number(10),
      fecha           date,
      monto_con       varchar2(20),   --md-08  cambia la long a 20
      me_pa_code      varchar2(3),
      medio_pago      varchar2(30),
      documento       varchar2(25),
      vencimiento     date,
      banco           varchar2(30),
      monto_doc       varchar2(20),
      intereses       varchar2(20),
      descuento_pronto_pago varchar2(20),
      id_al           varchar2(10),
      rut_al          varchar2(20),
      nombre_al       varchar2(100),
      programa        varchar2(12),
      programa_desc   varchar2(30),
      tipo            varchar2(5),
      fechapago       date,
      userpago        varchar2(30),
      rutapo          varchar2(20),
      nomapo          varchar2(100),
      status_doc      varchar2(30),
      nivelado        varchar2(2)
  );

type t_Datos is table of t_DetOper;

vtDatosMov           t_Datos;

vtDatos              t_Datos;

--CURSOR cuReporte_ConInteres (vsProg in smrprle.smrprle_program_desc%TYPE,
--       vsType in stvstyp.stvstyp_code%TYPE,
--       vsYear in VARCHAR2,
--       vdIni in twbcntr.twbcntr_issue_date%TYPE,
--       vdFin in twbcntr.twbcntr_issue_date%TYPE,
--       vsCont in twbcntr.twbcntr_num%TYPE,
--       vsPago in twvpaym.twvpaym_code%TYPE,
--       vsTaDo in twbdocu.twbdocu_status_ind%TYPE,
--       vslevl IN VARCHAR2  )
CURSOR cuReporte_ConInteres
  IS
  select   /*+ INDEX(twbnctr twbnctr_pidmterm_idx) */
       anio,      term,       contrato,
       statuscntr,--md-07
        secuencia,              fecha,
       monto_con, me_pa_code, medio_pago, documento,              vencimiento,
       banco,     monto_doc,  intereses,  descuento_pronto_pago,  id_al,
       rut_al,    nombre_al,  programa,   programa_desc,          tipo,
       fechapago, userpago,   rutapo,     nomapo,                 status_doc
       , nivelado
from (select substr(twbcntr_term_code, 1, 4)                                      anio
    , twbcntr_term_code                                                           term
    , a.twbdocu_cntr_num                                                          contrato
    ,twbcntr_status_ind                                                           statuscntr  --md-07
    , twbdocu_seq_num                                                             secuencia
    , twbcntr_issue_date                                                          fecha
    , pk_matricula.f_MontoContrato(twbdocu_cntr_num)                              monto_con   --md-08
    , a.twbdocu_paym_code                                                         me_pa_code
    , pk_matricula.f_existemediopago(a.twbdocu_paym_code)                         medio_pago
    , a.twbdocu_docu_num                                                          documento
    , a.twbdocu_expiration_date                                                   vencimiento
    , pk_matricula.f_existebanco(a.twbdocu_bank_code)                             banco
    ,a.twbdocu_amount                                                             monto_doc
     , CASE
                  when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) = 0 then 0
                  when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) < 0 then 0
                  ELSE TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT
       END                                                                        intereses
     , CASE
                 when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) = 0 then 0
                 when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) > 0 then 0
                 ELSE (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT )* -1
        END                                                                        descuento_pronto_pago
    --md-05 fin
    , f_get_id(a.twbdocu_pidm)                                                    id_al
    , f_get_rut(a.twbdocu_pidm)                                                   rut_al
    , substr(f_get_nombre(a.twbdocu_pidm),1,100)                                  nombre_al
    , twbcntr_ori_program                                                         programa
    , pk_catalogo.programa(twbcntr_ori_program)                                   programa_desc
    , fwatyaluft(twbcntr_pidm, twbcntr_term_code)                                 tipo
    , pk_MatApoderado.f_GetApoderadoDocu(TWBDOCU_SEQ_NUM)                         rutapo
    , substr(pk_MatApoderado.f_NombreCompleto(pk_MatApoderado.f_GetApoderadoDocu(TWBDOCU_SEQ_NUM)),1,100)  nomapo
    , a.twbdocu_pay_date                                                          fechapago
    , a.twbdocu_pay_user                                                          userpago
    , b.TWVDOST_STATUS_DESC                                                       status_doc
    , substr(TWBCNTR_ORI_PROGRAM,1,2)                                             nivelado
from  twbcntr
    , twbdocu a
    , sgbstdn g1
    , twvdost b
    , TWRRPOD
    , TWVPAYM
where a.twbdocu_cntr_num = twbcntr_num(+)
  and a.twbdocu_pidm = g1.sgbstdn_pidm
  --and twbcntr_status_ind = 'A'
   AND (vsStCntr = twbcntr_status_ind  or vsStCntr IS NULL)--md-07
  and a.TWBDOCU_SEQ_NUM = TWRRPOD_DOCU_SEQ_NUM (+)
  and TWVPAYM_CODE = a.TWBDOCU_PAYM_CODE
  and (instr(csSlh||vslevl , csSlh||substr(TWBCNTR_ORI_PROGRAM,1,2)||csSlh) > 0 or   vslevl = csSlh  OR  vslevl is null)  --md-04
  and A.TWBDOCU_STATUS_IND = B.TWVDOST_STATUS_IND
  and TWBCNTR_PIDM    = A.TWBDOCU_PIDM
  and TWBCNTR_TERM_CODE  = A.TWBDOCU_TERM_CODE
  and  (twbcntr_ori_program      = vsProg or vsProg is null)
  and  (a.twbdocu_cntr_num     = vsCont or vsCont is null)
  and  (a.twbdocu_paym_code    = vsPago or vsPago is null)
  and (twbcntr_term_code   like (vsYear||'%') or vsYear is null)
  and g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                  from   sgbstdn g2
                                  where g1.sgbstdn_pidm = g2.sgbstdn_pidm
                                  and g2.sgbstdn_term_code_eff <= twbcntr_term_code)
  and (TWBDOCU_STATUS_IND = vsTaDo or vsTaDo is null)--md-07
  and  nvl((TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT),0) > 0
  and not exists (select 1
                  from twbretr
                  where twbretr_cntr_num = twbcntr_num))
where (tipo = vsType or vsType is null)

 AND (TRUNC(vencimiento) >= TRUNC(vdIni) OR vdIni IS NULL)
  AND (TRUNC(vencimiento) <= TRUNC(vdFin) OR vdFin IS NULL)

/*
  AND (TRUNC(a.twbdocu_expiration_date) >= TRUNC(vdIni) OR vdIni IS NULL)
   AND (TRUNC(a.twbdocu_expiration_date) <= TRUNC(vdFin) OR vdFin IS NULL)
   */
order by contrato, fecha, secuencia;

--CURSOR cuReporte_SinInteres (vsProg in smrprle.smrprle_program_desc%TYPE,
--       vsType in stvstyp.stvstyp_code%TYPE,
--       vsYear in VARCHAR2,
--       vdIni in twbcntr.twbcntr_issue_date%TYPE,
--       vdFin in twbcntr.twbcntr_issue_date%TYPE,
--       vsCont in twbcntr.twbcntr_num%TYPE,
--       vsPago in twvpaym.twvpaym_code%TYPE,
--       vsTaDo in twbdocu.twbdocu_status_ind%TYPE,
--       vslevl IN VARCHAR2  )

CURSOR cuReporte_SinInteres
  IS
  select  /*+ INDEX(twbnctr twbnctr_pidmterm_idx) */
       anio,      term,       contrato,
       statuscntr ,--md-07
       secuencia,              fecha,
       monto_con, me_pa_code, medio_pago, documento,              vencimiento,
       banco,     monto_doc,  intereses,  descuento_pronto_pago,  id_al,
       rut_al,    nombre_al,  programa,   programa_desc,          tipo,
       fechapago, userpago,   rutapo,     nomapo,                 status_doc
       , nivelado
from (select substr(twbcntr_term_code, 1, 4)                                      anio
    , twbcntr_term_code                                                           term
    , a.twbdocu_cntr_num                                                          contrato
       ,twbcntr_status_ind                                                           statuscntr  --md-07
    , twbdocu_seq_num                                                             secuencia
    , twbcntr_issue_date                                                          fecha
    , pk_matricula.f_MontoContrato(twbdocu_cntr_num)                              monto_con   --md-08
    , a.twbdocu_paym_code                                                         me_pa_code
    , pk_matricula.f_existemediopago(a.twbdocu_paym_code)                         medio_pago
    , a.twbdocu_docu_num                                                          documento
    , a.twbdocu_expiration_date                                                   vencimiento
    , pk_matricula.f_existebanco(a.twbdocu_bank_code)                             banco
   ,  a.twbdocu_amount                                                            monto_doc  --md-08
    , CASE
                  when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) = 0 then 0
                  when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) < 0 then 0
                  ELSE TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT
      END                                                intereses
    , CASE
                    when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) = 0 then 0
                    when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) > 0 then 0
                    ELSE (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT ) * -1
      END                                                                 descuento_pronto_pago    
    --md-05 fin
    , f_get_id(a.twbdocu_pidm)                                                    id_al
    , f_get_rut(a.twbdocu_pidm)                                                   rut_al
    , substr(f_get_nombre(a.twbdocu_pidm),1,100)                                  nombre_al
    , twbcntr_ori_program                                                         programa
    , pk_catalogo.programa(twbcntr_ori_program)                                   programa_desc
    , fwatyaluft(twbcntr_pidm, twbcntr_term_code)                                 tipo
    , pk_MatApoderado.f_GetApoderadoDocu(TWBDOCU_SEQ_NUM)                         rutapo
    , substr(pk_MatApoderado.f_NombreCompleto(pk_MatApoderado.f_GetApoderadoDocu(TWBDOCU_SEQ_NUM)),1,100)  nomapo
    , a.twbdocu_pay_date                                                          fechapago
    , a.twbdocu_pay_user                                                          userpago
    , b.TWVDOST_STATUS_DESC                                                       status_doc
    , substr(TWBCNTR_ORI_PROGRAM,1,2)                                             nivelado
from  twbcntr
    , twbdocu a
    , sgbstdn g1
    , twvdost b
    , TWRRPOD
    , TWVPAYM
where a.twbdocu_cntr_num = twbcntr_num(+)
  and a.twbdocu_pidm = g1.sgbstdn_pidm
  AND (vsStCntr = twbcntr_status_ind  or vsStCntr IS NULL)--md-07
    and a.TWBDOCU_SEQ_NUM = TWRRPOD_DOCU_SEQ_NUM (+)
  and TWVPAYM_CODE = a.TWBDOCU_PAYM_CODE
  and (instr(csSlh||vslevl , csSlh||substr(TWBCNTR_ORI_PROGRAM,1,2)||csSlh) > 0 or   vslevl = csSlh  OR  vslevl is null)  --md-04
  and A.TWBDOCU_STATUS_IND = B.TWVDOST_STATUS_IND
  and TWBCNTR_PIDM    = A.TWBDOCU_PIDM
  and TWBCNTR_TERM_CODE  = A.TWBDOCU_TERM_CODE
  and  (twbcntr_ori_program      = vsProg or vsProg is null)
  and  (a.twbdocu_cntr_num     = vsCont or vsCont is null)
  and  (a.twbdocu_paym_code    = vsPago or vsPago is null)
  and (twbcntr_term_code   like (vsYear||'%') or vsYear is null)
  and g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                  from   sgbstdn g2
                                  where g1.sgbstdn_pidm = g2.sgbstdn_pidm
                                  and g2.sgbstdn_term_code_eff <= twbcntr_term_code)
  and (TWBDOCU_STATUS_IND = vsTaDo or vsTaDo is null)
  and  nvl((TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT),0)<= 0
  and not exists (select 1
                  from twbretr
                  where twbretr_cntr_num = twbcntr_num))
where (tipo = vsType or vsType is null)
  AND (TRUNC(vencimiento) >= TRUNC(vdIni) OR vdIni IS NULL)
  AND (TRUNC(vencimiento) <= TRUNC(vdFin) OR vdFin IS NULL)
  --AND (vsStCntr = twbcntr_status_ind  or vsStCntr IS NULL)
order by contrato, fecha, secuencia;

--md-06 end

--CURSOR cuReporte_Cambio (vsProg in smrprle.smrprle_program_desc%TYPE,
--       vsType in stvstyp.stvstyp_code%TYPE,
--       vsYear in VARCHAR2,
--       vdIni in twbcntr.twbcntr_issue_date%TYPE,
--       vdFin in twbcntr.twbcntr_issue_date%TYPE,
--       vsCont in twbcntr.twbcntr_num%TYPE,
--       vsPago in twvpaym.twvpaym_code%TYPE,
--       vsTaDo in twbdocu.twbdocu_status_ind%TYPE,
--       vslevl IN VARCHAR2  )
Cursor cuReporte_Cambio
  IS
  select   /*+ INDEX(twbnctr twbnctr_pidmterm_idx) */
      anio, term, contrato,
      statuscntr,--md-07
      secuencia, fecha, monto_con, me_pa_code, medio_pago, documento, vencimiento, banco, monto_doc,
      --md-05 inicio
      intereses,descuento_pronto_pago,
      --md-05 fin
      id_al, rut_al, nombre_al,  programa, programa_desc, tipo, fechapago, userpago, rutapo, nomapo
      --md-01 inicio
       ,status_doc
       ,nivelado
      --md-01 fin
from (select substr(twbcntr_term_code, 1, 4)                                      anio
    , twbcntr_term_code                                                           term
    , a.twbdocu_cntr_num                                                          contrato
       ,twbcntr_status_ind                                                           statuscntr  --md-07
    , twbdocu_seq_num                                                             secuencia
    , twbcntr_issue_date                                                          fecha
    , pk_matricula.f_MontoContrato(twbdocu_cntr_num)                              monto_con   --md-08 
    , a.twbdocu_paym_code                                                         me_pa_code
    , pk_matricula.f_existemediopago(a.twbdocu_paym_code)                         medio_pago
    , a.twbdocu_docu_num                                                          documento
    , a.twbdocu_expiration_date                                                   vencimiento
    , pk_matricula.f_existebanco(a.twbdocu_bank_code)                             banco
    , a.twbdocu_amount                                                            monto_doc
    --md-05 inicio
    , CASE
        when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) = 0 then 0
        when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) < 0 then 0
         ELSE TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT
      END                                                                         intereses
     ,case
          when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) = 0 then 0
          when (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT) > 0 then 0
          ELSE (TWRRPOD_NPV_AMOUNT - a.TWBDOCU_AMOUNT )* -1
       END                                                                       descuento_pronto_pago
    --md-05 fin
    , f_get_id(a.twbdocu_pidm)                                                    id_al
    , f_get_rut(a.twbdocu_pidm)                                                   rut_al
    , substr(f_get_nombre(a.twbdocu_pidm),1,100)                                   nombre_al
    , twbcntr_ori_program                                                         programa
    , pk_catalogo.programa(twbcntr_ori_program)                                   programa_desc
    , fwatyaluft(twbcntr_pidm, twbcntr_term_code)                                 tipo
    , pk_MatApoderado.f_GetApoderadoDocu(TWBDOCU_SEQ_NUM)                         rutapo
    , substr(pk_MatApoderado.f_NombreCompleto(pk_MatApoderado.f_GetApoderadoDocu(TWBDOCU_SEQ_NUM)),1,100)  nomapo
    , a.twbdocu_pay_date                                                          fechapago
    , a.twbdocu_pay_user                                                          userpago
       --md-01 inicio
    , b.TWVDOST_STATUS_DESC                                                       status_doc
       --md-01 fin
    , substr(TWBCNTR_ORI_PROGRAM,1,2)                                             nivelado    --md-04
from  twbcntr
    , twbdocu a
    , sgbstdn g1
    , twvdost b   --md-01
     ,TWRRPOD --md-05
    ,TWVPAYM --md-05
where a.twbdocu_cntr_num = twbcntr_num(+)
  and a.twbdocu_pidm = g1.sgbstdn_pidm
  --and twbcntr_status_ind = 'A'
   AND (vsStCntr = twbcntr_status_ind  or vsStCntr IS NULL)
    and a.TWBDOCU_SEQ_NUM = TWRRPOD_DOCU_SEQ_NUM (+) --md-05
  and TWVPAYM_CODE = a.TWBDOCU_PAYM_CODE --md-05
 -- and SGBSTDN_LEVL_CODE     = vslevl    --md-03
 -- and (instr(csSlh||vslevl , csSlh||SGBSTDN_LEVL_CODE||csSlh) > 0 or   vslevl = csSlh  OR  vslevl is null)   --md-03 -md-04
  and (instr(csSlh||vslevl , csSlh||substr(TWBCNTR_ORI_PROGRAM,1,2)||csSlh) > 0 or   vslevl = csSlh  OR  vslevl is null)  --md-04
  and A.TWBDOCU_STATUS_IND = B.TWVDOST_STATUS_IND
  and TWBCNTR_PIDM    = A.TWBDOCU_PIDM
  and TWBCNTR_TERM_CODE  = A.TWBDOCU_TERM_CODE
  and  (twbcntr_ori_program      = vsProg or vsProg is null)
  and  (a.twbdocu_cntr_num     = vsCont or vsCont is null)
  and  (a.twbdocu_paym_code    = vsPago or vsPago is null)
  and (twbcntr_term_code   like (vsYear||'%') or vsYear is null)
  and g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
                                  from   sgbstdn g2
                                  where g1.sgbstdn_pidm = g2.sgbstdn_pidm
                                  and g2.sgbstdn_term_code_eff <= twbcntr_term_code)
  and (TWBDOCU_STATUS_IND = vsTaDo or vsTaDo is null)
  and not exists (select 1
                    from twbretr
                    where twbretr_cntr_num = twbcntr_num))
where (tipo = vsType or vsType is null)
  AND (TRUNC(vencimiento) >= TRUNC(vdIni) OR vdIni IS NULL)
  AND (TRUNC(vencimiento) <= TRUNC(vdFin) OR vdFin IS NULL)
--  and (vencimiento between vdIni and vdFin or vdFin is null or vdIni is null)
 -- AND (vsStCntr = twbcntr_status_ind  or vsStCntr IS NULL)
order by contrato, fecha, secuencia;

BEGIN

   IF Pk_Login.F_ValidacionDeAcceso (pk_login.vgsUSR)  THEN
     RETURN;
   END IF;

   /* Parámetros */
   --Se busca el valor de la cookie (parámetro) para asignarlo al filtro del query.
--   vsProg  := pk_ObjHtml.getValueCookie ('psProgr');   --md-03
   vsProg  := pk_ObjHtml.getValueCookie ('psProg1');     --md-03
   vsType  := pk_ObjHtml.getValueCookie ('psTiPo');
   vsYear  := pk_ObjHtml.getValueCookie ('psYear');
   vdIni   := pk_ObjHtml.getValueCookie ('pdIni');
   vdFin   := pk_ObjHtml.getValueCookie ('pdFin');
   vsCont  := pk_ObjHtml.getValueCookie ('psId');
   vsPago  := pk_ObjHtml.getValueCookie ('psPago');
   vsTaDo  := pk_ObjHtml.getValueCookie ('psTaDoc');
--   vslevl  := pk_ObjHtml.getValueCookie ('psNivel');    --md-03
   vslevl  := pk_ObjHtml.getValueCookie ('psNivl1');      --md-03
   vsInteres := pk_ObjHtml.getValueCookie ('psSiNo');     --md-06
   vsStCntr:= pk_ObjHtml.getValueCookie ('psStCnt');
  
  -- Número de columnas de la tabla --
   tabColumna.EXTEND (vnColumnas);
  
   /* Encabezado de las columnas */
   tabColumna (1) := 'Año';
   tabColumna (2) := 'Contrato';
    tabColumna (3) := 'Status Contrato';
   tabColumna (4) := 'Fecha Ingreso';
   tabColumna (5) := 'Monto Contrato';
   tabColumna (6) := 'Medio Pago';
   tabColumna (7) := 'Documento';
    --md-01 inicio
    tabColumna (8) := 'Status Documento';
    --md-01 fin
   tabColumna (9) := 'Vencimiento';
   tabColumna (10) := 'Banco';
   tabColumna (11) := 'Monto Documento';
   tabColumna (12) := 'Intereses';
   tabColumna (13) := 'Descuento Pronto Pago';
   tabColumna (14) := 'Rut Apoderado';
   tabColumna (15) := 'Apoderado';
   tabColumna (16) := 'Fecha de Pago';
   tabColumna (17) := 'Usuario Pago';
   tabColumna (18) := 'Id Alumno';
   tabColumna (19) := 'Rut Alumno';
   tabColumna (20) := 'Nombre';
   --md-01 tabColumna (17) := 'Programa';
   tabColumna (21) := 'Descripción Programa';
   tabColumna (22) := 'Nivel';          --md-04

   --md-06 start

   if vsInteres = 0 then
      OPEN cuReporte_SinInteres;
         FETCH cuReporte_SinInteres BULK COLLECT INTO vtDatosMov;
      CLOSE cuReporte_SinInteres;
   else
       if vsInteres = 1 then
          OPEN cuReporte_ConInteres;
            FETCH cuReporte_ConInteres BULK COLLECT INTO vtDatosMov;
          CLOSE cuReporte_ConInteres;
       else
          OPEN cuReporte_Cambio;
            FETCH cuReporte_Cambio BULK COLLECT INTO vtDatosMov;
          CLOSE cuReporte_Cambio;
       end if;
   end if;

   vtDatos := vtDatosMov;
       --Si el tamaño de la colección es cero, no tiene caso seguir
    IF vtDatos.COUNT < 1 THEN
        htp.p('');
    END IF;

    vtDatosMov := NULL;

    For vni in 1 .. vtDatos.COUNT LOOP
    
      
       vsMonto_cnt := 0; 
       vsMonto_doc := 0; 
       vsInter     := 0; 
       vsDescuento := 0; 
       
    
       IF vnRow = 0 THEN
          Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);
          vsInicioPag := 'SALTO';
          vnRow  := 0;
       END IF;        
       
       --vsMonto_cnt := replace ( trim( replace ( replace (  replace (to_char(vtDatos(vni).monto_con, '999G999G999G999D00'), '.', '|') , ',', '.') , '|', ',')) , ',00') ; 
       --vsMonto_doc := replace ( trim( replace ( replace (  replace (to_char(vtDatos(vni).monto_doc, '999G999G999G999D00'), '.', '|') , ',', '.') , '|', ',')) , ',00') ;
       
       vsMonto_cnt := to_char(nvl(vtDatos(vni).monto_con,0),'999G999G999G999D00');
       vsMonto_cnt := replace ( trim( replace ( replace (  replace (vsMonto_cnt, '.', '|') , ',', '.') , '|', ',')) , ',00') ;
       
       vsMonto_doc := to_char(nvl(vtDatos(vni).monto_doc,0),'999G999G999G999D00');
       vsMonto_doc := replace ( trim( replace ( replace (  replace (vsMonto_doc, '.', '|') , ',', '.') , '|', ',')) , ',00') ;
       
       vsInter := to_char(nvl(vtDatos(vni).intereses,0),'999G999G999G999D00');
       vsInter := replace ( trim( replace ( replace ( replace (vsInter, '.', '|') , ',', '.') , '|', ',')) , ',00') ;
       
       vsDescuento := to_char(nvl(vtDatos(vni).descuento_pronto_pago,0),'999G999G999G999D00');
       vsDescuento := replace ( trim( replace ( replace (  replace (vsDescuento, '.', '|') , ',', '.') , '|', ',')) , ',00') ;

       htp.p(
       '<tr>
         <td valign="top">'||vtDatos(vni).anio||'</td>
         <td valign="top">'||vtDatos(vni).contrato||'</td>
         <td valign="top">'||vtDatos(vni).statuscntr||'</td>
         <td valign="top">'||vtDatos(vni).fecha||'</td>
         <td valign="top">'|| vsMonto_cnt ||'</td>
         <td valign="top">'||vtDatos(vni).medio_pago||'</td>
         <td valign="top">'||vtDatos(vni).documento||'</td>
         <td valign="top">'||vtDatos(vni).status_doc||'</td>
         <td valign="top">'||vtDatos(vni).vencimiento||'</td>
         <td valign="top">'||vtDatos(vni).banco||'</td>
         <td valign="top">'|| vsMonto_doc ||'</td>
         <td valign="top">'|| vsInter  ||'</td>
         <td valign="top">'|| vsDescuento ||'</td>
         <td valign="top">'||vtDatos(vni).rutapo||'</td>
         <td valign="top">'||vtDatos(vni).nomapo||'</td>
         <td valign="top">'||vtDatos(vni).fechapago||'</td>
         <td valign="top">'||vtDatos(vni).userpago||'</td>
         <td valign="top">'||vtDatos(vni).id_al||'</td>
         <td valign="top">'||vtDatos(vni).rut_al||'</td>
         <td valign="top">'||vtDatos(vni).nombre_al||'</td>
         <td valign="top">'||vtDatos(vni).programa_desc||'</td>
         <td valign="top">'||vtDatos(vni).nivelado||'</td>
       </tr>');

      vnExists   := 1;
      vnRow      := vnRow + 1;

    end loop; 




--   FOR regRep IN cuReporte_Cambio(vsProg, vsType, vsYear, vdIni, vdFin, vsCont, vsPago,vsTaDo,vslevl) LOOP
--      IF vnRow = 0 THEN
--         Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);
--         vsInicioPag := 'SALTO';
--         vnRow  := 0;
--      END IF;
--
--     --md-01 se comento la columna donde aparece regRep.programa y se agrego status de documento
--     --regRep.contrato
--      htp.p(
--      '<tr>
--      <td valign="top">'||regRep.anio||'</td>
--      <td valign="top">'||regRep.contrato||'</td>
--      <td valign="top">'||regRep.fecha||'</td>
--      <td valign="top">'||regRep.monto_con||'</td>
--      <td valign="top">'||regRep.medio_pago||'</td>
--      <td valign="top">'||regRep.documento||'</td>
--      <td valign="top">'||regRep.status_doc||'</td>
--      <td valign="top">'||regRep.vencimiento||'</td>
--      <td valign="top">'||regRep.banco||'</td>
--      <td valign="top">'||regRep.monto_doc||'</td>
--      <td valign="top">'||regRep.intereses||'</td>
--      <td valign="top">'||regRep.descuento_pronto_pago||'</td>
--      <td valign="top">'||regRep.rutapo||'</td>
--      <td valign="top">'||regRep.nomapo||'</td>
--      <td valign="top">'||regRep.fechapago||'</td>
--      <td valign="top">'||regRep.userpago||'</td>
--      <td valign="top">'||regRep.id_al||'</td>
--      <td valign="top">'||regRep.rut_al||'</td>
--      <td valign="top">'||regRep.nombre_al||'</td>
--      <td valign="top">'||regRep.programa_desc||'</td>
--      <td valign="top">'||regRep.nivelado||'</td>');     --md-04
--
--      vnExists   := 1;
--      vnRow      := vnRow + 1;
--   END LOOP;

    --md-06 end

   IF vnExists = 0 THEN
      HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
     -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
     Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

     -- es omitido el encabezado del reporte pero se agrega el salto de pagina
     Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);

   END IF;

   HTP.p ('</table><br/>    No. de Registros  ' ||vnRow||   '</body></html>');

EXCEPTION
   WHEN OTHERS
   THEN
   HTP.P (SQLERRM);
END PWCLADO; 
/


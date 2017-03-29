CREATE OR REPLACE PROCEDURE BANINST1.PWABCDE (psReclDesc VARCHAR2)
IS
/******************************************************************************
PROCEDIMIENTO:          BANINST1.PWABCDE
OBJETIVO:               Reporte de Becas, Creditos y Descuentos
AUTORES:                Guillermo Almazan Ibañez
FECHA:                  10/12/2010

Modificación md-01: Se modifica la columna de Monto Beneficio
Autor: Virgilio De la Cruz Jardón
Fecha: 27/04/2015
----------------------------------
Modificación md-02: Se modifica formatos del reporte y se adiconan
                    columna de grupo, categoria
Autor: Roman ruiz
Fecha: 07/05/2015
----------------------------------
Modificación md-03: se optimiza el query principal
Autor: Roman ruiz
Fecha: 07/05/2015

******************************************************************************/

   vnRow         INTEGER := 0;
   vnExists      INTEGER := 0;
   vnColumnas    INTEGER := 24;   -- 17   --md-02
   vsProg        smrprle.smrprle_program_desc%TYPE;
   vsVia         stvstst.stvstst_code%TYPE;
   vsTyAl        stvstyp.stvstyp_code%TYPE;
   vsYear        varchar2(4);
   vsCont        twbcntr.twbcntr_num%TYPE;
   vsPidm        TWRCRAL.TWRCRAL_PIDM%TYPE;
   tabColumna    Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vsInicioPag   VARCHAR2 (10) := NULL;

--md-02 start
/*
CURSOR cuABCDE (vsProg in smrprle.smrprle_program_desc%TYPE,
                          vsVia in stvstst.stvstst_code%TYPE,
                          vsType in stvstyp.stvstyp_code%TYPE,
                          vsYear in VARCHAR2,
                          vsCont in twbcntr.twbcntr_num%TYPE)
  IS
  select pidm, periodo, rut_beneficiado, dv_rut, rut_def, id_al, nombre,
         programa, periodo_ing, code_nuevo_antiguo,
         decode(code_nuevo_antiguo, 'A', 'Avanzado','N', 'Nuevo Ingreso') nuevo_antiguo,
         pk_catalogo.stastst(condicion) condicion,
         contrato,
         monto_cntr, --to_char(monto_cntr, pk_contrato.ConstglFormato) monto_cntr,
         monto_mat, --to_char(monto_mat, pk_contrato.ConstglFormato) monto_mat,
         monto_ara, --to_char(monto_ara, pk_contrato.ConstglFormato) monto_ara,
         monto_Beca, --to_char(monto_Beca, pk_contrato.ConstglFormato) monto_Beca,
         beca, descrip, Por_Beca
       , nvl(grupo,'N.A.') grupo ,  nvl(desc_grupo,'N.A.') desc_grupo           --md-02
       , nvl(catego,'N.A.') catego,  nvl(desc_catego,'N.A.') desc_catego        --md-02
  from (
        select twbcntr_pidm                                                                 pidm
             , twbcntr_term_code                                                            periodo
             , substr(f_get_rut(twbcntr_pidm), 1, length(f_get_rut(twbcntr_pidm))-2)        rut_beneficiado
             , substr(f_get_rut(twbcntr_pidm), length(f_get_rut(twbcntr_pidm)),1)           dv_rut
             , f_get_rut(twbcntr_pidm)                                                      rut_def
             , f_get_id(twbcntr_pidm)                                                       id_al
             , f_format_name(twbcntr_pidm, 'LF30')                                          nombre
             , pk_catalogo.programa(f_get_programa(twbcntr_pidm, twbcntr_term_code))        programa
             , pk_AdMat.f_PeriodoIngreso(twbcntr_pidm, twbcntr_term_code)                   periodo_ing
             , case
                 when pk_AdMat.f_PeriodoIngreso(twbcntr_pidm, twbcntr_term_code) < twbcntr_term_code then 'A'
                 else 'N'
               end                                                                          code_nuevo_antiguo
             , f_sgbstdn_fields(twbcntr_pidm, twbcntr_term_code, 'STU_STATUS')              condicion
             , twbcntr_num                                                                  contrato
             , pk_matricula.f_MontoContrato(twbcntr_num)                                    monto_cntr
--             ,(select sum(TBRACCD_AMOUNT)
--               from TBRACCD
--               where TBRACCD_DETAIL_CODE in (select TBBDETC_DETAIL_CODE
--                                             from TBBDETC
--                                             where TBBDETC_DCAT_CODE = 'FEE'
--                                               and TBBDETC_TYPE_IND = 'C')
--                and TBRACCD_PIDM = twbcntr_pidm
--                and TBRACCD_TERM_CODE = twbcntr_term_code)                                  monto_mat
             ,(select sum( abs(twrdotr_part_amount)*sign(tbraccd_amount) )
                from tbbdetc ,tbraccd ,twbdocu ,twrdotr ,twbcntr b
               where tbbdetc_detail_code = tbraccd_detail_code
                 and tbbdetc_type_ind = 'C'
                 and tbbdetc_dcat_code = 'FEE'
                 and tbraccd_pidm = twrdotr_pidm
                 and tbraccd_tran_number = twrdotr_tran_number
                 and twbdocu_seq_num = twrdotr_docu_seq_num
                 and twbdocu_cntr_num = b.twbcntr_num
                 and twrdotr_orig_ind = 'O'
                 and b.twbcntr_num = a.twbcntr_num
                 and not exists (select 1
                                 from twbretr
                                 where twbretr_cntr_num = b.twbcntr_num))                 monto_mat
--             ,(select sum(TBRACCD_AMOUNT)
--               from TBRACCD
--               where TBRACCD_DETAIL_CODE in (select TBBDETC_DETAIL_CODE
--                                             from TBBDETC
--                                             where TBBDETC_DCAT_CODE = 'TUI'
--                                               and TBBDETC_TYPE_IND = 'C')
--                and TBRACCD_PIDM = twbcntr_pidm
--                and TBRACCD_TERM_CODE = twbcntr_term_code)                                  monto_ara
             ,(select sum( abs(twrdotr_part_amount)*sign(tbraccd_amount) )
                 from tbbdetc ,tbraccd ,twbdocu ,twrdotr ,twbcntr b
                where tbbdetc_detail_code = tbraccd_detail_code
                  and tbbdetc_type_ind = 'C'
                  and tbbdetc_dcat_code = 'TUI'
                  and tbraccd_pidm = twrdotr_pidm
                  and tbraccd_tran_number = twrdotr_tran_number
                  and twbdocu_seq_num = twrdotr_docu_seq_num
                  and twbdocu_cntr_num = b.twbcntr_num
                  and twrdotr_orig_ind = 'O'
                  and b.twbcntr_num = a.twbcntr_num
                  and not exists (select 1
                                  from twbretr
                                  where twbretr_cntr_num = b.twbcntr_num))                monto_ara
             --, Becas.monto                                                                  monto_Beca
             , (select TWBDOCU_AMOUNT
                from  twbdocu
                where TWBDOCU_SEQ_NUM = Becas.seqnum
                and   TWBDOCU_cntr_num = a.twbcntr_num   )                                monto_Beca
             , Becas.code                                                                 beca
             , Becas.descrip                                                              descrip
             , Becas.por                                                                  Por_Beca
             --md-02 start
             , (SELECT GOVSDAV_VALUE_AS_CHAR
                from  GOVSDAV, TBBEXPT
                where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                AND TBBEXPT_TERM_CODE = Becas.term
                AND TBBEXPT_EXEMPTION_CODE = Becas.code
                and GOVSDAV_ATTR_NAME = 'EXEMPTION_CODE')                                 grupo
             , (select STVSOFF_DESC
                from stvsoff
                where STVSOFF_CODE = (SELECT GOVSDAV_VALUE_AS_CHAR
                                      from  GOVSDAV, TBBEXPT
                                      where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                                      AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                                      AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                                      AND TBBEXPT_TERM_CODE = Becas.term
                                      AND TBBEXPT_EXEMPTION_CODE = Becas.code
                                      and GOVSDAV_ATTR_NAME = 'EXEMPTION_CODE'))          desc_grupo
             , (SELECT GOVSDAV_VALUE_AS_CHAR
                from  GOVSDAV, TBBEXPT
                where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                AND TBBEXPT_TERM_CODE = Becas.term
                AND TBBEXPT_EXEMPTION_CODE = Becas.code
                and GOVSDAV_ATTR_NAME = 'CATEGORIA')                                      catego
             , (select STVSOFF_DESC
                from stvsoff
                where STVSOFF_CODE = (SELECT GOVSDAV_VALUE_AS_CHAR
                                      from  GOVSDAV, TBBEXPT
                                      where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                                      AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                                      AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                                      AND TBBEXPT_TERM_CODE = Becas.term
                                      AND TBBEXPT_EXEMPTION_CODE = Becas.code
                                      and GOVSDAV_ATTR_NAME = 'CATEGORIA'))               desc_catego
        -- md-02 end
        --     , Tipo
        --     , Grupo
        from twbcntr a, ( select TWBDOCU_SEQ_NUM seqnum,      TWBDOCU_CNTR_NUM cntr,      tbbestu_exemption_code code,
                                 tbbexpt_desc descrip,        max(TBREDET_PERCENT) por,   twbdocu_amount monto
                               , twbdocu_term_code term     --md-02
                            from tbbestu, tbbexpt, tbredet, twbdocu
                           where TWBDOCU_PIDM = TBBESTU_PIDM
                             and TWBDOCU_TERM_CODE = TBBESTU_TERM_CODE
                             and TWBDOCU_DOCU_NUM = TBBESTU_EXEMPTION_CODE
                             and TBBEXPT_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
                             and TBBEXPT_TERM_CODE = TBBESTU_TERM_CODE
                             and TBREDET_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
                             and TBREDET_TERM_CODE = TBBESTU_TERM_CODE
                           group by TWBDOCU_SEQ_NUM,TWBDOCU_CNTR_NUM, tbbestu_exemption_code, tbbexpt_desc, twbdocu_amount,  twbdocu_term_code
                         union
                          select TWBDOCU_SEQ_NUM seqnum,     TWBDOCU_CNTR_NUM cntr, 'CUFT_'||TWRCUFT_NUM   code,
                                 'Crédito UFT' descrip, TWRCUFT_PERCENT por,    pk_MatCreUFT.f_montocobercred(TWRCUFT_NUM) monto
                                ,twbdocu_term_code term    --md-02
                            from TWRCUFT, twbdocu
                           where TWRCUFT_DOCU_SEQ_NUM is not null
                             and TWBDOCU_SEQ_NUM = TWRCUFT_DOCU_SEQ_NUM
                         union
                          select TWBDOCU_SEQ_NUM seqnum,    TWBDOCU_CNTR_NUM cntr,      TWRCRAL_CRET_CODE    code,
                                 TWVCRET_DESC descrip,      null por,                   TWBCRET_AMOUNT monto
                               , twbdocu_term_code term   --md-02
                            from twbdocu, TWVCRET, TWBCRET, TWRCRAL
                           where TWBDOCU_PIDM = TWRCRAL_PIDM
                             and TWBDOCU_TERM_CODE = TWRCRAL_TERM_CODE
                             and TWBCRET_CODE = TWVCRET_CODE
                             and TWRCRAL_TERM_CODE = TWBCRET_TERM_CODE
                             and TWRCRAL_MAJR_CODE = TWBCRET_MAJR_CODE
                             and TWRCRAL_CRET_CODE = TWBCRET_CODE
                             and TWRCRAL_DOCU_SEQ_NUM is not null
                             and TWBDOCU_SEQ_NUM = TWRCRAL_DOCU_SEQ_NUM
                             ) Becas
        where twbcntr_status_ind = 'A'
          and Becas.cntr = twbcntr_num
          and not exists (select 1
                          from twbretr
                          where twbretr_cntr_num = twbcntr_num)
        )
  where (programa = vsProg or vsProg is null)
    --and (stvadmt_code = vsVia or vsVia is null)
    and (code_nuevo_antiguo = vsTyAl or vsTyAl is null)
    and (periodo like (vsYear||'%') or vsYear is null)
    and (contrato = vsCont or vsCont is null)
  order by pidm;
*/

CURSOR cuABCDE (vsProg in smrprle.smrprle_program_desc%TYPE,
                          vsVia in stvstst.stvstst_code%TYPE,
                          vsType in stvstyp.stvstyp_code%TYPE,
                          vsYear in VARCHAR2,
                          vsCont in twbcntr.twbcntr_num%TYPE)
  IS
 select pidm
       , cntr
       , term
       , substr(f_get_rut(pidm), 1, length(f_get_rut(pidm))-2)        rut_beneficiado
       , substr(f_get_rut(pidm), length(f_get_rut(pidm)),1)           dv_rut
       , f_get_rut(pidm)                                              rut_def
       , f_get_id(pidm)                                               id_al
       , f_format_name(pidm, 'LF30')                                  nombre
       ,(SELECT nvl(TWBCNTR_ORI_PROGRAM,'N/A') FROM twbcntr
         WHERE  twbcntr_num = cntr )                                  programa
       , (SELECT nvl(SMRPRLE_PROGRAM_DESC,'N/A') FROM SMRPRLE , twbcntr
         WHERE SMRPRLE_PROGRAM = TWBCNTR_ORI_PROGRAM  and twbcntr_num = cntr )  desc_programa
       , pk_AdMat.f_PeriodoIngreso(pidm, term)                        periodo_ing
       , case
           when pk_AdMat.f_PeriodoIngreso(pidm, term) < term then 'A'
           else 'N'
         end                                                          code_nuevo_antiguo
       , f_sgbstdn_fields(pidm, term, 'STU_STATUS')                   condicion
       , cntr                                                         contrato
       , pk_matricula.f_MontoContrato(cntr)                           monto_cntr
       ,(select sum( abs(twrdotr_part_amount)*sign(tbraccd_amount) )
          from tbbdetc ,tbraccd ,twbdocu ,twrdotr ,twbcntr b
         where tbbdetc_detail_code = tbraccd_detail_code
           and tbbdetc_type_ind = 'C'
           and tbbdetc_dcat_code = 'FEE'
           and tbraccd_pidm = twrdotr_pidm
           and tbraccd_tran_number = twrdotr_tran_number
           and twbdocu_seq_num = twrdotr_docu_seq_num
           and twbdocu_cntr_num = b.twbcntr_num
           and twrdotr_orig_ind = 'O'
           and b.twbcntr_num = cntr )                                 monto_mat
       ,(select sum( abs(twrdotr_part_amount)*sign(tbraccd_amount) )
           from tbbdetc ,tbraccd ,twbdocu ,twrdotr ,twbcntr b
          where tbbdetc_detail_code = tbraccd_detail_code
            and tbbdetc_type_ind = 'C'
            and tbbdetc_dcat_code = 'TUI'
            and tbraccd_pidm = twrdotr_pidm
            and tbraccd_tran_number = twrdotr_tran_number
            and twbdocu_seq_num = twrdotr_docu_seq_num
            and twbdocu_cntr_num = b.twbcntr_num
            and twrdotr_orig_ind = 'O'
            and b.twbcntr_num = cntr)                                 monto_ara
       , (select TWBDOCU_AMOUNT
          from  twbdocu
          where TWBDOCU_SEQ_NUM = seqnum
          and   TWBDOCU_cntr_num = cntr     )                         monto_Beca
       , code                                                         beca
       , descrip                                                      descrip
       , por                                                          Por_Beca
       , grupo                                                       grupo
       , desc_grupo                                                desc_grupo
       , catego                                                     catego
       , desc_catego                                                 desc_catego
       , clasificacion                                               clasificacion
       , desc_clasi   desc_clasi    
  from (
        select TWBDOCU_PIDM pidm , TWBDOCU_SEQ_NUM seqnum,    TWBDOCU_CNTR_NUM cntr,      tbbestu_exemption_code code,
               tbbexpt_desc descrip,      max(TBREDET_PERCENT) por,   twbdocu_amount monto
             , twbdocu_term_code term
                , (SELECT GOVSDAV_VALUE_AS_CHAR
                from  GOVSDAV, TBBEXPT
                where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                AND TBBEXPT_TERM_CODE = twbdocu_term_code
                AND TBBEXPT_EXEMPTION_CODE = tbbestu_exemption_code
                and GOVSDAV_ATTR_NAME = 'EXEMPTION_CODE')                                 grupo
             , (select STVSOFF_DESC
                from stvsoff
                where STVSOFF_CODE = (SELECT GOVSDAV_VALUE_AS_CHAR
                                      from  GOVSDAV, TBBEXPT
                                      where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                                      AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                                      AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                                      AND TBBEXPT_TERM_CODE =twbdocu_term_code
                                      AND TBBEXPT_EXEMPTION_CODE = tbbestu_exemption_code
                                      and GOVSDAV_ATTR_NAME = 'EXEMPTION_CODE'))          desc_grupo
             , (SELECT GOVSDAV_VALUE_AS_CHAR
                from  GOVSDAV, TBBEXPT
                where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                AND TBBEXPT_TERM_CODE = twbdocu_term_code
                AND TBBEXPT_EXEMPTION_CODE = tbbestu_exemption_code
                and GOVSDAV_ATTR_NAME = 'CATEGORIA')                                      catego
             , (select STVSOFF_DESC
                from stvsoff
                where STVSOFF_CODE = (SELECT GOVSDAV_VALUE_AS_CHAR
                                      from  GOVSDAV, TBBEXPT
                                      where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                                      AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                                      AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                                      AND TBBEXPT_TERM_CODE = twbdocu_term_code
                                      AND TBBEXPT_EXEMPTION_CODE =tbbestu_exemption_code
                                      and GOVSDAV_ATTR_NAME = 'CATEGORIA'))               desc_catego,
                                      (SELECT GOVSDAV_VALUE_AS_CHAR
                from  GOVSDAV, TBBEXPT
                where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                AND TBBEXPT_TERM_CODE = twbdocu_term_code
                AND TBBEXPT_EXEMPTION_CODE = tbbestu_exemption_code
                and GOVSDAV_ATTR_NAME = 'CLASIFICACION'
                and rownum = 1)                                      clasificacion
             , (select STVSOFF_DESC
                from stvsoff
                where STVSOFF_CODE = (SELECT GOVSDAV_VALUE_AS_CHAR
                                      from  GOVSDAV, TBBEXPT
                                      where GOVSDAV_TABLE_NAME = 'TBBEXPT'
                                      AND TBBEXPT_EXEMPTION_CODE = SUBSTR(GOVSDAV_PK_PARENTTAB,1,8)
                                      AND TBBEXPT_TERM_CODE =  SUBSTR(GOVSDAV_PK_PARENTTAB,10,6)
                                      AND TBBEXPT_TERM_CODE = twbdocu_term_code
                                      AND TBBEXPT_EXEMPTION_CODE = tbbestu_exemption_code
                                      and GOVSDAV_ATTR_NAME = 'CLASIFICACION'
                                      and rownum = 1))               desc_clasi
        from  tbbestu, tbbexpt, tbredet, twbdocu
        where TWBDOCU_PIDM = TBBESTU_PIDM
          and TWBDOCU_TERM_CODE = TBBESTU_TERM_CODE
          and TWBDOCU_DOCU_NUM = TBBESTU_EXEMPTION_CODE
          and TBBEXPT_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
          and TBBEXPT_TERM_CODE = TBBESTU_TERM_CODE
          and TBREDET_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
          and TBREDET_TERM_CODE = TBBESTU_TERM_CODE
          and TWBDOCU_SEQ_NUM in (select TWBDOCU_SEQ_NUM
                                  from twbdocu, twbcntr
                                  where (twbdocu_term_code like (vsYear||'%') or vsYear is null)
                                  and (twbcntr_num = vsCont or vsCont is null)
                                  --and (twbcntr_num = null or null is null)
                                  and (TWBCNTR_ORI_PROGRAM = vsProg or vsProg is null)
                                  --and (TWBCNTR_ORI_PROGRAM = null or null is null)
                                  and twbcntr_num = twbdocu_cntr_num
                                  and twbcntr_pidm = twbdocu_pidm
                                  and twbcntr_term_code = twbdocu_term_code
                                  and TWBCNTR_STATUS_IND = 'A'
                                  and not exists (select 1
                                                 from twbretr
                                                 where twbretr_cntr_num = twbcntr_num))
        group by TWBDOCU_PIDM, TWBDOCU_SEQ_NUM,TWBDOCU_CNTR_NUM, tbbestu_exemption_code, tbbexpt_desc, twbdocu_amount,  twbdocu_term_code
   union
        select TWBDOCU_PIDM pidm,  TWBDOCU_SEQ_NUM seqnum,     TWBDOCU_CNTR_NUM cntr, 'CUFT_'||TWRCUFT_NUM   code,
               'Crédito UFT' descrip, TWRCUFT_PERCENT por,    pk_MatCreUFT.f_montocobercred(TWRCUFT_NUM) monto
              ,twbdocu_term_code term, null grupo, null  desc_grupo, null catego, null desc_catego, null clasificacion, null desc_clasi
          from TWRCUFT, twbdocu
         where TWBDOCU_SEQ_NUM = TWRCUFT_DOCU_SEQ_NUM
           and TWRCUFT_DOCU_SEQ_NUM in (select TWBDOCU_SEQ_NUM
                                        from twbdocu, twbcntr
                                        where (twbdocu_term_code like (vsYear||'%') or vsYear is null)
                                        and (twbcntr_num = vsCont or vsCont is null)
                                        --and (twbcntr_num = null or null is null)
                                        and (TWBCNTR_ORI_PROGRAM = vsProg or vsProg is null)
                                        --and (TWBCNTR_ORI_PROGRAM = null or null is null)
                                        and twbcntr_num = twbdocu_cntr_num
                                        and twbcntr_pidm = twbdocu_pidm
                                        and twbcntr_term_code = twbdocu_term_code
                                        and TWBCNTR_STATUS_IND = 'A'
                                        and not exists (select 1
                                                        from twbretr
                                                         where twbretr_cntr_num = twbcntr_num))
    union
              select TWBDOCU_PIDM pidm , TWBDOCU_SEQ_NUM seqnum,    TWBDOCU_CNTR_NUM cntr,      TWRCRAL_CRET_CODE    code,
               TWVCRET_DESC descrip,      null por,                   TWBCRET_AMOUNT monto
             , twbdocu_term_code term,
             (SELECT GOVSDAV_VALUE_AS_CHAR
                from  GOVSDAV, TWVCRET
                where GOVSDAV_TABLE_NAME = 'TWVCRET'
                AND TWVCRET_CODE = GOVSDAV_PK_PARENTTAB 
                AND TWVCRET_CODE =  TWRCRAL_CRET_CODE
                and GOVSDAV_ATTR_NAME = 'GRUPO'
                and rownum = 1)                                 grupoc
             , (select STVSOFF_DESC
                from stvsoff
                where STVSOFF_CODE = (SELECT GOVSDAV_VALUE_AS_CHAR
                                      from  GOVSDAV, TWVCRET
                                      where GOVSDAV_TABLE_NAME = 'TWVCRET'
                                      AND TWVCRET_CODE = GOVSDAV_PK_PARENTTAB
                                      AND TWVCRET_CODE = TWRCRAL_CRET_CODE
                                      and GOVSDAV_ATTR_NAME = 'GRUPO'
                                      and rownum = 1))          desc_grupo
             , (SELECT GOVSDAV_VALUE_AS_CHAR
                from  GOVSDAV, TWVCRET
                where GOVSDAV_TABLE_NAME = 'TWVCRET'
                AND TWVCRET_CODE = GOVSDAV_PK_PARENTTAB
                AND TWVCRET_CODE  = TWRCRAL_CRET_CODE
                and GOVSDAV_ATTR_NAME = 'CATEGORIA'
                and rownum = 1)                                      catego
             , (select STVSOFF_DESC
                from stvsoff
                where STVSOFF_CODE = (SELECT GOVSDAV_VALUE_AS_CHAR
                                      from  GOVSDAV, TWVCRET
                                      where GOVSDAV_TABLE_NAME = 'TWVCRET'
                                      AND TWVCRET_CODE = GOVSDAV_PK_PARENTTAB
                                      AND TWVCRET_CODE =TWRCRAL_CRET_CODE
                                      and GOVSDAV_ATTR_NAME = 'CATEGORIA'
                                      and rownum = 1))               desc_catego,
                                      (SELECT GOVSDAV_VALUE_AS_CHAR
                from  GOVSDAV, TWVCRET
                where GOVSDAV_TABLE_NAME = 'TWVCRET'
                AND TWVCRET_CODE = GOVSDAV_PK_PARENTTAB
                AND TWVCRET_CODE =TWRCRAL_CRET_CODE
                and GOVSDAV_ATTR_NAME = 'CLASIFICACION'
                and rownum = 1)                                      clasificacion
             , (select STVSOFF_DESC
                from stvsoff
                where STVSOFF_CODE = (SELECT GOVSDAV_VALUE_AS_CHAR
                                      from  GOVSDAV, TWVCRET
                                      where GOVSDAV_TABLE_NAME = 'TWVCRET'
                                      AND TWVCRET_CODE = GOVSDAV_PK_PARENTTAB
                                      AND TWVCRET_CODE = TWRCRAL_CRET_CODE
                                      and GOVSDAV_ATTR_NAME = 'CLASIFICACION'
                                      and rownum = 1))               desc_clasi
          from twbdocu, TWVCRET, TWBCRET, TWRCRAL
         where TWBDOCU_PIDM = TWRCRAL_PIDM
           and TWBDOCU_TERM_CODE = TWRCRAL_TERM_CODE
           and TWBCRET_CODE = TWVCRET_CODE
           and TWRCRAL_TERM_CODE = TWBCRET_TERM_CODE
           and TWRCRAL_MAJR_CODE = TWBCRET_MAJR_CODE
           and TWRCRAL_CRET_CODE = TWBCRET_CODE
           and TWBDOCU_SEQ_NUM = TWRCRAL_DOCU_SEQ_NUM
           and TWRCRAL_DOCU_SEQ_NUM in (select TWBDOCU_SEQ_NUM
                                        from twbdocu, twbcntr
                                        where (twbdocu_term_code like (vsYear||'%') or vsYear is null)
                                        and (twbcntr_num = vsCont or vsCont is null)
                                        --and (twbcntr_num = null or null is null)
                                        and (TWBCNTR_ORI_PROGRAM = vsProg or vsProg is null)
                                        --and (TWBCNTR_ORI_PROGRAM = null or null is null)
                                        and twbcntr_num = twbdocu_cntr_num
                                        and twbcntr_pidm = twbdocu_pidm
                                        and twbcntr_term_code = twbdocu_term_code
                                        and TWBCNTR_STATUS_IND = 'A'
                                       and not exists (select 1
                                                       from twbretr
                                                       where twbretr_cntr_num = twbcntr_num))
        )
order by pidm ;

--md-03 end

BEGIN

   IF Pk_Login.F_ValidacionDeAcceso (pk_login.vgsUSR) THEN
      RETURN;
   END IF;

    /* Parámetros */
    --Se busca el valor de la cookie (parámetro) para asignarlo al filtro del query.
    vsProg   := pk_ObjHtml.getValueCookie ('psProgr');
    vsVia    := pk_ObjHtml.getValueCookie ('psVia');
    vsTyAl   := pk_ObjHtml.getValueCookie ('psTiPo');
    vsYear   := pk_ObjHtml.getValueCookie ('psYear');
    vsCont   := pk_ObjHtml.getValueCookie ('psCont');

  -- Número de columnas de la tabla --
   tabColumna.EXTEND (vnColumnas);

   /* Encabezado de las columnas */
   tabColumna (1) := 'RUT Beneficiado';
   tabColumna (2) := 'DV RUT';
   tabColumna (3) := 'RUT Def';
   tabColumna (4) := 'ID';
   tabColumna (5) := 'Alumno';
   tabColumna (6) := 'Programa';
   tabColumna (7) := 'Periodo Ingreso';
   tabColumna (8) := 'Nuevo/Antiguo';
   tabColumna (9) := 'Condición';
   tabColumna (10) := 'Periodo Matrícula';    --md-02 se agrega acento
   tabColumna (11) := 'Contrato';
   tabColumna (12) := 'Monto Contrato';
   tabColumna (13) := 'Monto Matrícula';      --md-02 se agrega acento
   tabColumna (14) := 'Monto Arancel';
   tabColumna (15) := 'Monto Beneficio';
   tabColumna (16) := 'Beneficio';
   tabColumna (17) := 'Descripción Beneficio';
   --- md-02 start
   --tabColumna (18) := ' % Beneficio ';
   tabColumna (18) := ' % ';
   tabColumna (19) := 'Grupo';
   tabColumna (20) := 'Descripción Grupo';
   tabColumna (21) := 'Categoría';
   tabColumna (22) := 'Descripción Categoría';
   tabColumna (23) := 'Clasificación';
   tabColumna (24) := 'Descripción Clasificación';
   -- md-03 end


   htp.p(vsProg);
   htp.p(vsVia);
   htp.p(vsTyAl);
   htp.p(vsYear);
   htp.p(vsCont);

      FOR regRep IN cuABCDE(vsProg, vsVia, vsTyAl, vsYear, vsCont) LOOP

          IF vnRow = 0 THEN
             Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);
             vsInicioPag := 'SALTO';
             vnRow  := 0;
          END IF;

          htp.p(
          '<tr>
          <td valign="top">'||regRep.rut_beneficiado||'</td>
          <td valign="top">'||regRep.dv_rut||'</td>
          <td valign="top">'||regRep.rut_def||'</td>
          <td valign="top">'||regRep.id_al||'</td>
          <td valign="top">'||regRep.nombre||'</td>
          <td valign="top">'||regRep.programa||'</td>
          <td valign="top">'||regRep.periodo_ing||'</td> ');

          --<td valign="top">'||regRep.nuevo_antiguo||'</td>

          htp.p('<td> </td>');

          htp.p('<td valign="top">'||regRep.condicion||'</td>
          <td valign="top">'||regRep.term||'</td>
          <td valign="top">'||regRep.contrato||'</td>
          <td valign="top">'||regRep.monto_cntr||'</td>
          <td valign="top">'||regRep.monto_mat||'</td>
          <td valign="top">'||regRep.monto_ara||'</td>
          <td valign="top">'||regRep.monto_Beca||'</td>
          <td valign="top">'||regRep.beca||'</td>
          <td valign="top">'||regRep.descrip||'</td>
          <td valign="top">'||regRep.Por_Beca||'</td>');  --md-02 start
          htp.p('
          <td valign="top">' || regRep.grupo || '</td>
          <td valign="top">' || regRep.desc_grupo || '</td>
          <td valign="top">' || regRep.catego || '</td>
          <td valign="top">' || regRep.desc_catego || '</td>
          <td valign="top">' || regRep.clasificacion || '</td>
          <td valign="top">' || regRep.desc_clasi || '</td>

          ');
   
          --md-02 end
          vnExists   := 1;
          vnRow      := vnRow + 1;
      END LOOP;

   IF vnExists = 0
   THEN
      HTP.p('<tr><th colspan="'||vnColumnas||'"><font color="#ff0000">'||Pk_Sisrepimp.vgsResultado||'</font></th></tr>');
   ELSE
      -- la variable es una bandera que al tener el valor "imprime" no colocara el salto de página para impresion
      Pk_Sisrepimp.vgsSaltoImp := 'Imprime';

      -- es omitido el encabezado del reporte pero se agrega el salto de pagina
      Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc, vnColumnas,tabColumna,'PIE','0', psUsuario=>pk_login.vgsUSR);
   END IF;

   HTP.p ('</table><br/></body></html>');
EXCEPTION
   WHEN OTHERS
   THEN
      HTP.P (SQLERRM);
END PWABCDE;
/
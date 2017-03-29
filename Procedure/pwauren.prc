CREATE OR REPLACE PROCEDURE BANINST1.PWAUREN (psReclDesc VARCHAR2)
IS
/******************************************************************************
PROCEDIMIENTO:          BANINST1.PWAUREN
OBJETIVO:               Reporte Auditoria Rendimiento
AUTORES:                Guillermo Almazan Ibañez
FECHA:                  27/12/2010

modificacion            md-01   se cambia el formato del monto 99g999g99g99g
autor                   roman ruiz
fecha                   17-may-2016 

******************************************************************************/
   vnRow         INTEGER := 0;
   vnExists      INTEGER := 0;
   vnColumnas    INTEGER := 33;
   vsProg       smrprle.smrprle_program_desc%TYPE;
   vsVia        stvstst.stvstst_code%TYPE;
   vsTyAl       stvstyp.stvstyp_code%TYPE;
   vsPerio      stvterm.stvterm_code%TYPE;
   vsCont       twbcntr.twbcntr_num%TYPE;
   vsPidm       TWRCRAL.TWRCRAL_PIDM%TYPE;
   tabColumna   Pk_Sisrepimp.tipoTabla := Pk_Sisrepimp.tipoTabla (1);
   vsInicioPag   VARCHAR2 (10) := NULL;
   
   --md-01 stat
   vsbec_prom_por   varchar2(20); 
   vsbec_ori_por    varchar2(20);
   vsbec_depo_por   varchar2(20);
   vsbec_psu_por    varchar2(20);
   vsbec_descon_por varchar2(20);
   vscre_uft_por    varchar2(20);
   vscre_cae_por    varchar2(20);
   vscre_min_por    varchar2(20);
   
  --end  md-01  
   
CURSOR cuABCDE (vsProg in smrprle.smrprle_program_desc%TYPE,
						  vsVia in stvstst.stvstst_code%TYPE,
						  vsType in stvstyp.stvstyp_code%TYPE,
						  vsPerio in stvterm.stvterm_code%TYPE,
						  vsCont in twbcntr.twbcntr_num%TYPE)
  IS
  select a.pidm
	   , a.anio
	   , a.contrato
	   , a.fecha
	   , a.id
	   , a.rut_al
	   , a.alumno
	   , a.lenguaje
	   , a.matematicas
	   , a.ciencias
	   , a.sociales
	   , a.nem
	   , a.ponderado
	   , a.periodo_in
	   , a.tipo
	   , a.via
	   , a.programa
	   , a.prog_desc
       /* md-01
	   , sum(b.por) bec_prom_por,   to_char(sum(b.monto), pk_contrato.ConstglFormato) bec_prom_monto
	   , sum(c.por) bec_ori_por,    to_char(sum(c.monto), pk_contrato.ConstglFormato) bec_ori_monto
	   , sum(d.por) bec_depo_por,   to_char(sum(d.monto), pk_contrato.ConstglFormato) bec_depo_monto
	   , sum(i.por) bec_psu_por,    to_char(sum(i.monto), pk_contrato.ConstglFormato) bec_psu_monto
	   , sum(e.por) bec_descon_por, to_char(sum(e.monto), pk_contrato.ConstglFormato) bec_descon_monto
	   , sum(f.por) cre_uft_por,    to_char(sum(f.monto), pk_contrato.ConstglFormato) cre_uft_monto
	   , sum(g.por) cre_cae_por,    to_char(sum(g.monto), pk_contrato.ConstglFormato) cre_cae_monto
	   , sum(h.por) cre_min_por,    to_char(sum(h.monto), pk_contrato.ConstglFormato) cre_min_monto
       */
       , sum(b.por) bec_prom_por,   sum(b.monto)  bec_prom_monto
       , sum(c.por) bec_ori_por,    sum(c.monto)  bec_ori_monto
       , sum(d.por) bec_depo_por,   sum(d.monto)  bec_depo_monto
       , sum(i.por) bec_psu_por,    sum(i.monto)  bec_psu_monto
       , sum(e.por) bec_descon_por, sum(e.monto)  bec_descon_monto
       , sum(f.por) cre_uft_por,    sum(f.monto)  cre_uft_monto
       , sum(g.por) cre_cae_por,    sum(g.monto)  cre_cae_monto
       , sum(h.por) cre_min_por,    sum(h.monto)  cre_min_monto
  from (select twbcntr_pidm                                                                               pidm
			 , substr(twbcntr_term_code, 1,4)                                                             anio
			 --, to_char(twbcntr_issue_date, 'yyyy')                                                        anio
			 , twbcntr_num                                                                                contrato
			 , twbcntr_term_code                                                                          periodo
			 , twbcntr_issue_date                                                                         fecha
			 , f_get_id(twbcntr_pidm)                                                                     id
			 , f_get_rut(twbcntr_pidm)                                                                    rut_al
			 , f_get_nombre(twbcntr_pidm)                                                                 alumno
			 , pk_AdMat.f_get_PSU(twbcntr_pidm, 'PSLC')                                               lenguaje
			 , pk_AdMat.f_get_PSU(twbcntr_pidm, 'PSMA')                                               matematicas
			 , pk_AdMat.f_get_PSU(twbcntr_pidm, 'PSCI')                                               ciencias
			 , pk_AdMat.f_get_PSU(twbcntr_pidm, 'PSHC')                                               sociales
			 , pk_AdMat.f_get_PSU(twbcntr_pidm, 'NEME')                                               nem
			 , pk_AdMat.f_get_PSU_pond(twbcntr_pidm, twbcntr_term_code)                               ponderado
			 , g1.sgbstdn_term_code_admit                                                                 periodo_in_code
			 , stvterm_desc                                                                               periodo_in
			 , fwatyaluft(twbcntr_pidm, twbcntr_term_code)                                            tipo_code
			 , decode(fwatyaluft(twbcntr_pidm, twbcntr_term_code),'N','Nuevo Ingreso','A','Avanzado') tipo
			 , stvadmt_code                                                                               via_code
			 , stvadmt_desc                                                                               via
			 , f_get_programa(twbcntr_pidm, twbcntr_term_code)                                            programa
			 , pk_catalogo.Programa(f_get_programa(twbcntr_pidm, twbcntr_term_code))                      prog_desc
		from twbcntr
		   , sgbstdn g1
		   , stvterm
		   , stvstyp
		   , stvadmt
		where sgbstdn_pidm = twbcntr_pidm
		  and g1.sgbstdn_term_code_admit = stvterm_code(+)
		  and g1.sgbstdn_styp_code = stvstyp_code(+)
		  and g1.sgbstdn_admt_code = stvadmt_code(+)
		  and g1.sgbstdn_term_code_eff = (select max(g2.sgbstdn_term_code_eff)
										  from sgbstdn g2
										  where g1.sgbstdn_pidm = g2.sgbstdn_pidm
											and g2.sgbstdn_term_code_eff <= twbcntr_term_code)
          and not exists (select 1
                          from twbretr
                          where twbretr_cntr_num = twbcntr_num))A,
	   (SELECT TBBESTU_PIDM pidm, TBBESTU_EXEMPTION_CODE BECA, TBBEXPT_DESC DESCR, TBBESTU_TERM_CODE PER, max(TBREDET_PERCENT) POR, SUM(TWBDOCU_AMOUNT) MONTO
		FROM TBBESTU, TBBEXPT, tbredet, twbdocu
		WHERE TBBEXPT_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
		  and TBBEXPT_TERM_CODE = TBBESTU_TERM_CODE
		  AND TBBESTU_DEL_IND IS NULL
		  AND TBBESTU_TERM_CODE = TBREDET_TERM_CODE
		  AND TBBESTU_EXEMPTION_CODE = TBREDET_EXEMPTION_CODE
		  AND TWBDOCU_PAYM_CODE(+) = 'BEC'
		  AND TWBDOCU_DOCU_NUM(+) = TBBESTU_EXEMPTION_CODE
		  AND TBBESTU_EXEMPTION_CODE LIKE '1122%'
		group by TBBESTU_PIDM, TBBESTU_TERM_CODE, TBBESTU_EXEMPTION_CODE, TBBEXPT_DESC)B,
	/*****PSU*****/
	 (SELECT TBBESTU_PIDM pidm, TBBESTU_EXEMPTION_CODE BECA, TBBEXPT_DESC DESCR, TBBESTU_TERM_CODE PER, max(TBREDET_PERCENT) POR, SUM(TWBDOCU_AMOUNT) MONTO
	  FROM TBBESTU, TBBEXPT, tbredet, twbdocu
	  WHERE TBBEXPT_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
		and TBBEXPT_TERM_CODE = TBBESTU_TERM_CODE
		AND TBBESTU_DEL_IND IS NULL
		AND TBBESTU_TERM_CODE = TBREDET_TERM_CODE
		AND TBBESTU_EXEMPTION_CODE = TBREDET_EXEMPTION_CODE
		AND TWBDOCU_PAYM_CODE(+) = 'BEC'
		AND TWBDOCU_DOCU_NUM(+) = TBBESTU_EXEMPTION_CODE
		AND TBBESTU_EXEMPTION_CODE LIKE '1111%'
	  group by TBBESTU_PIDM, TBBESTU_TERM_CODE, TBBESTU_EXEMPTION_CODE, TBBEXPT_DESC)I,
	/*****Origen*****/
	 (SELECT TBBESTU_PIDM pidm, TBBESTU_EXEMPTION_CODE BECA, TBBEXPT_DESC DESCR, TBBESTU_TERM_CODE PER, max(TBREDET_PERCENT) POR, SUM(TWBDOCU_AMOUNT) MONTO
	  FROM TBBESTU, TBBEXPT, tbredet, twbdocu
	  WHERE TBBEXPT_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
		and TBBEXPT_TERM_CODE = TBBESTU_TERM_CODE
		AND TBBESTU_DEL_IND IS NULL
		AND TBBESTU_TERM_CODE = TBREDET_TERM_CODE
		AND TBBESTU_EXEMPTION_CODE = TBREDET_EXEMPTION_CODE
		AND TWBDOCU_PAYM_CODE(+) = 'BEC'
		AND TWBDOCU_DOCU_NUM(+) = TBBESTU_EXEMPTION_CODE
		AND TBBESTU_EXEMPTION_CODE LIKE '44%'
	  group by TBBESTU_PIDM, TBBESTU_TERM_CODE, TBBESTU_EXEMPTION_CODE, TBBEXPT_DESC)C,
	/*****Deportiva*****/
	 (SELECT TBBESTU_PIDM pidm, TBBESTU_EXEMPTION_CODE BECA, TBBEXPT_DESC DESCR, TBBESTU_TERM_CODE PER, max(TBREDET_PERCENT) POR, SUM(TWBDOCU_AMOUNT) MONTO
	  FROM TBBESTU, TBBEXPT, tbredet, twbdocu
	  WHERE TBBEXPT_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
		and TBBEXPT_TERM_CODE = TBBESTU_TERM_CODE
		AND TBBESTU_DEL_IND IS NULL
		AND TBBESTU_TERM_CODE = TBREDET_TERM_CODE
		AND TBBESTU_EXEMPTION_CODE = TBREDET_EXEMPTION_CODE
		AND TWBDOCU_PAYM_CODE(+) = 'BEC'
		AND TWBDOCU_DOCU_NUM(+) = TBBESTU_EXEMPTION_CODE
		AND TBBESTU_EXEMPTION_CODE LIKE '2222%'
	  group by TBBESTU_PIDM, TBBESTU_TERM_CODE, TBBESTU_EXEMPTION_CODE, TBBEXPT_DESC)D,
	/*****Descuentos/Convenios*****/
	 (SELECT TBBESTU_PIDM pidm, TBBESTU_EXEMPTION_CODE BECA, TBBEXPT_DESC DESCR, TBBESTU_TERM_CODE PER, max(TBREDET_PERCENT) POR, SUM(TWBDOCU_AMOUNT) MONTO
	  FROM TBBESTU, TBBEXPT, tbredet, twbdocu
	  WHERE TBBEXPT_EXEMPTION_CODE = TBBESTU_EXEMPTION_CODE
		and TBBEXPT_TERM_CODE = TBBESTU_TERM_CODE
		AND TBBESTU_DEL_IND IS NULL
		AND TBBESTU_TERM_CODE = TBREDET_TERM_CODE
		AND TBBESTU_EXEMPTION_CODE = TBREDET_EXEMPTION_CODE
		AND TWBDOCU_PAYM_CODE(+) = 'BEC'
		AND TWBDOCU_DOCU_NUM(+) = TBBESTU_EXEMPTION_CODE
		AND (TBBESTU_EXEMPTION_CODE LIKE '88%' or TBBESTU_EXEMPTION_CODE LIKE '99%')
	  group by TBBESTU_PIDM, TBBESTU_TERM_CODE, TBBESTU_EXEMPTION_CODE, TBBEXPT_DESC)E,
	/*****Credito UFT*****/
--     (select TWBCRED_CREDIT_CODE credit, TWRALCR_TERM_CODE per, TWRCRPE_PROGRAM prog, TWRALCR_PIDM pidm, TWRCRPE_AMOUNT monto, TWRCRPE_PERCENTAGE por, TWRALCR_STATUS_IND stat
--      from TWBCRED, TWRCRPE, TWRALCR
--      where TWRCRPE_CREDIT_CODE(+) = TWBCRED_CREDIT_CODE
--        and TWRALCR_TERM_CODE(+) = TWRCRPE_TERM_CODE
--        and TWRALCR_PROGRAM = TWRCRPE_PROGRAM
--        and TWRALCR_CREDIT_CODE = TWBCRED_CREDIT_CODE
--        and TWBCRED_CREDIT_CODE = 'CUFT'
--        and TWRALCR_STATUS_IND = 'A')F,
	 (select 'CUFT_'||TWRCUFT_NUM credit, TWRCUFT_TERM_CODE per, f_get_programa(TWRCUFT_PIDM, TWRCUFT_TERM_CODE)prog, TWRCUFT_PIDM pidm,
			   pk_MatCreUFT.f_montocobercred(TWRCUFT_NUM) monto, TWRCUFT_PERCENT por, decode(TWRCUFT_DOCU_SEQ_NUM, null, null,'A') stat
		from TWRCUFT
		where TWRCUFT_DOCU_SEQ_NUM is not null)F,
	/*****Credito CCAE*****/
--     (select TWBCRED_CREDIT_CODE credit, TWRALCR_TERM_CODE per, TWRCRPE_PROGRAM prog, TWRALCR_PIDM pidm, TWRCRPE_AMOUNT monto, TWRCRPE_PERCENTAGE por, TWRALCR_STATUS_IND stat
--      from TWBCRED, TWRCRPE, TWRALCR
--      where TWRCRPE_CREDIT_CODE(+) = TWBCRED_CREDIT_CODE
--        and TWRALCR_TERM_CODE(+) = TWRCRPE_TERM_CODE
--        and TWRALCR_PROGRAM = TWRCRPE_PROGRAM
--        and TWRALCR_CREDIT_CODE = TWBCRED_CREDIT_CODE
--        and TWBCRED_CREDIT_CODE = 'CCAE'
--        and TWRALCR_STATUS_IND = 'A')G,
	   (select TWVCRET_CODE credit, TWRCRAL_TERM_CODE per, f_sgbstdn_fields(TWRCRAL_PIDM, TWRCRAL_TERM_CODE, 'MAJOR_1') prog, TWRCRAL_PIDM pidm, TWBCRET_AMOUNT monto, null por, decode(TWRCRAL_DOCU_SEQ_NUM, null, null,'A') stat
		from TWVCRET, TWBCRET, TWRCRAL
		where TWBCRET_CODE = TWVCRET_CODE
		  and TWRCRAL_TERM_CODE = TWBCRET_TERM_CODE
		  and TWRCRAL_MAJR_CODE = TWBCRET_MAJR_CODE
		  and TWRCRAL_CRET_CODE = TWBCRET_CODE
		  and TWVCRET_CODE = 'CAE'
		  and TWRCRAL_DOCU_SEQ_NUM is not null)G,
	/*****Beca del Ministerio*****/
--     (select TWBCRED_CREDIT_CODE credit, TWRALCR_TERM_CODE per, TWRCRPE_PROGRAM prog, TWRALCR_PIDM pidm, TWRCRPE_AMOUNT monto, TWRCRPE_PERCENTAGE por, TWRALCR_STATUS_IND stat
--      from TWBCRED, TWRCRPE, TWRALCR
--      where TWRCRPE_CREDIT_CODE(+) = TWBCRED_CREDIT_CODE
--        and TWRALCR_TERM_CODE(+) = TWRCRPE_TERM_CODE
--        and TWRALCR_PROGRAM = TWRCRPE_PROGRAM
--        and TWRALCR_CREDIT_CODE = TWBCRED_CREDIT_CODE
--        and TWBCRED_CREDIT_CODE = 'BMIN'
--        and TWRALCR_STATUS_IND = 'A')H
	   (select TWVCRET_CODE credit, TWRCRAL_TERM_CODE per, f_sgbstdn_fields(TWRCRAL_PIDM, TWRCRAL_TERM_CODE, 'MAJOR_1') prog, TWRCRAL_PIDM pidm, TWBCRET_AMOUNT monto, null por, decode(TWRCRAL_DOCU_SEQ_NUM, null, null,'A') stat
		from TWVCRET, TWBCRET, TWRCRAL
		where TWBCRET_CODE = TWVCRET_CODE
		  and TWRCRAL_TERM_CODE = TWBCRET_TERM_CODE
		  and TWRCRAL_MAJR_CODE = TWBCRET_MAJR_CODE
		  and TWRCRAL_CRET_CODE = TWBCRET_CODE
		  and TWVCRET_CODE = 'BMIN'
		  and TWRCRAL_DOCU_SEQ_NUM is not null)H
where b.pidm(+) = a.pidm
	and c.pidm(+) = a.pidm
	and d.pidm(+) = a.pidm
	and e.pidm(+) = a.pidm
	and f.pidm(+) = a.pidm
	and g.pidm(+) = a.pidm
	and h.pidm(+) = a.pidm
	and i.pidm(+) = a.pidm
	and (a.programa = vsProg or vsProg is null)
	and (a.via_code = vsVia or vsVia is null)
	and (a.tipo_code = vsTyAl or vsTyAl is null)
	and (a.periodo_in_code = vsPerio or vsPerio is null)
	and (a.contrato = vsCont or vsCont is null)
group by a.pidm
	   , a.anio
	   , a.contrato
	   , a.fecha
	   , a.id
	   , a.rut_al
	   , a.alumno
	   , a.lenguaje
	   , a.matematicas
	   , a.ciencias
	   , a.sociales
	   , a.nem
	   , a.ponderado
	   , a.periodo_in
	   , a.tipo
	   , a.via
	   , a.programa
	   , a.prog_desc
order by id;

BEGIN

   IF Pk_Login.F_ValidacionDeAcceso (pk_login.vgsUSR)
   THEN
	  RETURN;
   END IF;

	/* Parámetros */
	--Se busca el valor de la cookie (parámetro) para asignarlo al filtro del query.
	vsProg  := pk_ObjHtml.getValueCookie ('psProgr');
	vsVia  := pk_ObjHtml.getValueCookie ('psVia');
	vsTyAl   := pk_ObjHtml.getValueCookie ('psTiPo');
	vsPerio   := pk_ObjHtml.getValueCookie ('psPerio');
	vsCont   := pk_ObjHtml.getValueCookie ('psCont');

  -- Número de columnas de la tabla --
   FOR vnI IN 1 .. vnColumnas
   LOOP
	  tabColumna.EXTEND (vnI);
	  tabColumna (vnI) := NULL;
   END LOOP;

   /* Encabezado de las columnas */
   tabColumna (1) := 'Año';
   tabColumna (2) := 'Contrato';
   tabColumna (3) := 'Fecha Contrato';
   tabColumna (4) := 'Id Alumno';
   tabColumna (5) := 'Rut Alumno';
   tabColumna (6) := 'Alumno';
   tabColumna (7) := 'PSU Lenguaje';
   tabColumna (8) := 'PSU Matemáticas';
   tabColumna (9) := 'PSU Ciencias';
   tabColumna (10) := 'PSU Sociales';
   tabColumna (11) := 'NEM';
   tabColumna (12) := 'PSU Ponderado';
   tabColumna (13) := 'Periodo Admisión';
   tabColumna (14) := 'Tipo Alumno';
   tabColumna (15) := 'Vía';
   tabColumna (16) := 'Programa';
   tabColumna (17) := 'Descripción Programa';
   tabColumna (18) := 'Porcentaje Beca Promocional';
   tabColumna (19) := 'Monto Beca Promocional';
   tabColumna (20) := 'Porcentaje Beca Origen';
   tabColumna (21) := 'Monto Beca Origen';
   tabColumna (22) := 'Porcentaje Beca Deportiva';
   tabColumna (23) := 'Monto Beca Deportiva';
   tabColumna (24) := 'Porcentaje Beca PSU';
   tabColumna (25) := 'Monto Beca PSU';
   tabColumna (26) := 'Porcentaje Descuentos /Convenios';
   tabColumna (27) := 'Monto Descuentos /Convenios';
   tabColumna (28) := 'Porcentaje Crédito UFT';
   tabColumna (29) := 'Monto Crédito UFT';
   tabColumna (30) := 'Porcentaje Crédito CAE';
   tabColumna (31) := 'Monto Crédito CAE';
   tabColumna (32) := 'Porcentaje Beca Ministerio';
   tabColumna (33) := 'Monto Beca Ministerio';

	  FOR regRep IN cuABCDE(vsProg, vsVia, vsTyAl, vsPerio, vsCont) LOOP
      
      
            --md-01 start    
            vsbec_prom_por  := 0; 
            vsbec_ori_por   := 0; 
            vsbec_depo_por  := 0; 
            vsbec_psu_por   := 0; 
            vsbec_descon_por:= 0; 
            vscre_uft_por   := 0; 
            vscre_cae_por   := 0; 
            vscre_min_por   := 0;
            --md-01 end  
      
      
		  IF vnRow = 0 THEN
			 Pk_Sisrepimp.P_EncabezadoDeReporte(psReclDesc,vnColumnas,tabColumna,vsInicioPag);
			 vsInicioPag := 'SALTO';
			 vnRow  := 0;
		  END IF;
            
          -- md-01 start   
            vsbec_prom_por  := to_char(regRep.bec_prom_monto,  pk_contrato.ConstglFormato); 
            vsbec_prom_por  := trim( replace ( replace ( replace ( vsbec_prom_por , '.', '|') , ',', '.') , '|', ','));
            vsbec_ori_por   := to_char(regRep.bec_ori_monto,   pk_contrato.ConstglFormato); 
            vsbec_ori_por   := trim( replace ( replace ( replace ( vsbec_ori_por , '.', '|') , ',', '.') , '|', ','));
            
            vsbec_depo_por  := to_char(regRep.bec_depo_monto,  pk_contrato.ConstglFormato);  
            vsbec_depo_por  := trim( replace ( replace ( replace ( vsbec_depo_por , '.', '|') , ',', '.') , '|', ','));
            
            vsbec_psu_por   := to_char(regRep.bec_psu_monto,   pk_contrato.ConstglFormato); 
            vsbec_psu_por  := trim( replace ( replace ( replace ( vsbec_psu_por , '.', '|') , ',', '.') , '|', ',')); 
            
            vsbec_descon_por:= to_char(regRep.bec_descon_monto, pk_contrato.ConstglFormato);
            vsbec_descon_por:= trim( replace ( replace ( replace ( vsbec_descon_por , '.', '|') , ',', '.') , '|', ',')) ;  
            
            vscre_uft_por   := to_char(regRep.cre_uft_monto,   pk_contrato.ConstglFormato); 
            vscre_uft_por  := trim( replace ( replace ( replace ( vscre_uft_por , '.', '|') , ',', '.') , '|', ',')); 
            
            vscre_cae_por   := to_char(regRep.cre_cae_monto,   pk_contrato.ConstglFormato);
            vscre_cae_por  := trim( replace ( replace ( replace ( vscre_cae_por , '.', '|') , ',', '.') , '|', ','));  
            
            vscre_min_por   := to_char(regRep.cre_min_monto,   pk_contrato.ConstglFormato); 
            vscre_min_por  := trim( replace ( replace ( replace ( vscre_min_por , '.', '|') , ',', '.') , '|', ','));


--		  htp.p(
--		  '<tr>
--		  <td valign="top">'||regRep.anio||'</td>
--		  <td valign="top">'||regRep.contrato||'</td>
--		  <td valign="top">'||regRep.fecha||'</td>
--		  <td valign="top">'||regRep.id||'</td>
--		  <td valign="top">'||regRep.rut_al||'</td>
--		  <td valign="top">'||regRep.alumno||'</td>
--		  <td valign="top">'||regRep.lenguaje||'</td>
--		  <td valign="top">'||regRep.matematicas||'</td>
--		  <td valign="top">'||regRep.ciencias||'</td>
--		  <td valign="top">'||regRep.sociales||'</td>
--		  <td valign="top">'||regRep.nem||'</td>
--		  <td valign="top">'||regRep.ponderado||'</td>
--		  <td valign="top">'||regRep.periodo_in||'</td>
--		  <td valign="top">'||regRep.tipo||'</td>
--		  <td valign="top">'||regRep.via||'</td>
--		  <td valign="top">'||regRep.programa||'</td>
--		  <td valign="top">'||regRep.prog_desc||'</td>
--		  <td valign="top">'||regRep.bec_prom_por||'</td>
--		  <td valign="top">'||regRep.bec_prom_monto||'</td>
--		  <td valign="top">'||regRep.bec_ori_por||'</td>
--		  <td valign="top">'||regRep.bec_ori_monto||'</td>
--		  <td valign="top">'||regRep.bec_depo_por||'</td>
--		  <td valign="top">'||regRep.bec_depo_monto||'</td>
--		  <td valign="top">'||regRep.bec_psu_por||'</td>
--		  <td valign="top">'||regRep.bec_psu_monto||'</td>
--		  <td valign="top">'||regRep.bec_descon_por||'</td>
--		  <td valign="top">'||regRep.bec_descon_monto||'</td>
--		  <td valign="top">'||regRep.cre_uft_por||'</td>
--		  <td valign="top">'||regRep.cre_uft_monto||'</td>
--		  <td valign="top">'||regRep.cre_cae_por||'</td>
--		  <td valign="top">'||regRep.cre_cae_monto||'</td>
--		  <td valign="top">'||regRep.cre_min_por||'</td>
--		  <td valign="top">'||regRep.cre_min_monto||'</td>');

          htp.p(
          '<tr>
          <td valign="top">'||regRep.anio||'</td>
          <td valign="top">'||regRep.contrato||'</td>
          <td valign="top">'||regRep.fecha||'</td>
          <td valign="top">'||regRep.id||'</td>
          <td valign="top">'||regRep.rut_al||'</td>
          <td valign="top">'||regRep.alumno||'</td>
          <td valign="top">'||regRep.lenguaje||'</td>
          <td valign="top">'||regRep.matematicas||'</td>
          <td valign="top">'||regRep.ciencias||'</td>
          <td valign="top">'||regRep.sociales||'</td>
          <td valign="top">'||regRep.nem||'</td>
          <td valign="top">'||regRep.ponderado||'</td>
          <td valign="top">'||regRep.periodo_in||'</td>
          <td valign="top">'||regRep.tipo||'</td>
          <td valign="top">'||regRep.via||'</td>
          <td valign="top">'||regRep.programa||'</td>
          <td valign="top">'||regRep.prog_desc||'</td>
          <td valign="top">'||regRep.bec_prom_por||'</td>
          <td valign="top">'|| vsbec_prom_por ||'</td>
          <td valign="top">'||regRep.bec_ori_por||'</td>
          <td valign="top">'|| vsbec_ori_por ||'</td>
          <td valign="top">'||regRep.bec_depo_por||'</td>
          <td valign="top">'|| vsbec_depo_por ||'</td>
          <td valign="top">'||regRep.bec_psu_por||'</td>
          <td valign="top">'||  vsbec_psu_por ||'</td>
          <td valign="top">'||regRep.bec_descon_por||'</td>
          <td valign="top">'|| vsbec_descon_por ||'</td>
          <td valign="top">'||regRep.cre_uft_por||'</td>
          <td valign="top">'|| vscre_uft_por ||'</td>
          <td valign="top">'||regRep.cre_cae_por||'</td>
          <td valign="top">'|| vscre_cae_por ||'</td>
          <td valign="top">'||regRep.cre_min_por||'</td>
          <td valign="top">'|| vscre_min_por ||'</td>');

          --md-01 end   

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
END PWAUREN;
/

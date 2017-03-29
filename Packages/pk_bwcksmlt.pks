DROP PACKAGE BANINST1.PK_BWCKSMLT;

CREATE OR REPLACE PACKAGE BANINST1.pk_bwcksmlt AS
--AUDIT_TRAIL_MSGKEY_UPDATE
-- PROJECT : MSGKEY
-- MODULE  : pk_bwcksmlt
-- SOURCE  : enUS
-- TARGET  : I18N
-- DATE    : Thu Apr 22 12:58:23 2010
-- MSGSIGN : #0000000000000000
--TMI18N.ETR DO NOT CHANGE--
--
-- FILE NAME..: pk_bwcksmlt.sql
-- RELEASE....: 8.4.0.1
-- OBJECT NAME: pk_bwcksmlt
-- PRODUCT....: SCOMWEB
-- USAGE......:
-- COPYRIGHT..: Copyright(C) 2010 SunGard. All rights reserved.
--
-- Contains confidential and proprietary information of SunGard and its subsidiaries.
-- Use of these materials is limited to SunGard Higher Education licensees, and is
-- subject to the terms and conditions of one or more written license agreements
-- between SunGard Higher Education and the licensee in question.
--
-- DESCRIPTION:
--
-- This package contains objects used to process and display
-- Student's CAPP output to the web.
--
-- FUNCTIONS AND PROCEDURES :
--
-- DESCRIPTION END
--
   -------------------------------------------
   --
   -- Function Section
   --
   -------------------------------------------

   FUNCTION get_levl_desc (param1 IN stvlevl.stvlevl_code%TYPE)
      RETURN stvlevl.stvlevl_desc%TYPE;

   FUNCTION get_camp_desc (param1 IN stvcamp.stvcamp_code%TYPE)
      RETURN stvcamp.stvcamp_desc%TYPE;

   FUNCTION get_coll_desc (param1 IN stvcoll.stvcoll_code%TYPE)
      RETURN stvcoll.stvcoll_desc%TYPE;

   FUNCTION get_degc_desc (param1 IN stvdegc.stvdegc_code%TYPE)
      RETURN stvdegc.stvdegc_desc%TYPE;

   FUNCTION get_exp_grad_date (
      param1   IN   shrdgmr.shrdgmr_pidm%TYPE,
      param2   IN   smrrqcm.smrrqcm_dgmr_seq_no%TYPE
   )
      RETURN SHRDGMR.SHRDGMR_GRAD_DATE%TYPE;

  -- 82277
  FUNCTION get_stdn_grad_date (
      param1   IN   sgbstdn.sgbstdn_pidm%type,
      param2   IN   sgbstdn.sgbstdn_term_code_eff%type
   )
      RETURN SGBSTDN.SGBSTDN_EXP_GRAD_DATE%TYPE;

   FUNCTION f_smracmt_rowcount (
      area        IN   SMRACMT.SMRACMT_AREA%TYPE,
      term        IN   STVTERM.STVTERM_CODE%TYPE,
      dflt_text   IN   STVCPRT.STVCPRT_CODE%TYPE
   )
      RETURN NUMBER;

   FUNCTION f_smrsacm_rowcount (
      pidm        IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      area        IN   SMRSACM.SMRSACM_AREA%TYPE,
      term        IN   STVTERM.STVTERM_CODE%TYPE,
      dflt_text   IN   STVCPRT.STVCPRT_CODE%TYPE
   )
      RETURN NUMBER;

   FUNCTION f_smrgcmt_rowcount (
      grp         IN   SMRGCMT.SMRGCMT_GROUP%TYPE,
      term        IN   STVTERM.STVTERM_CODE%TYPE,
      dflt_text   IN   STVCPRT.STVCPRT_CODE%TYPE
   )
      RETURN NUMBER;

   FUNCTION f_smrsgcm_rowcount (
      pidm        IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      grp         IN   SMRSGCM.SMRSGCM_GROUP%TYPE,
      term        IN   STVTERM.STVTERM_CODE%TYPE,
      dflt_text   IN   STVCPRT.STVCPRT_CODE%TYPE
   )
      RETURN NUMBER;

   FUNCTION get_area_desc (param1 IN smralib.smralib_area%TYPE)
      RETURN smralib.smralib_area_desc%TYPE;

   FUNCTION F_GenOutputAreaText (
      pidm        IN   spriden.spriden_pidm%TYPE,
      area        IN   smbaogn.smbaogn_area%TYPE,
      rec_source  IN   smbaogn.smbaogn_source_ind%TYPE,
      term        IN   stvterm.stvterm_code%TYPE,
      dflt_text   IN   stvprnt.stvprnt_code%TYPE
   )
      RETURN VARCHAR2;

   FUNCTION get_group_desc (param1 IN smrglib.smrglib_group%TYPE)
      RETURN smrglib.smrglib_group_desc%TYPE;

   FUNCTION get_alib_levl_code_stu (param1 IN smralib.smralib_area%TYPE)
      RETURN smralib.smralib_levl_code_stu%TYPE;

   FUNCTION get_program_desc (param1 IN smrprle.smrprle_program%TYPE)
      RETURN smrprle.smrprle_program_desc%TYPE;

   FUNCTION chk_smbarul_addtnl_text (
      param1   IN   smbaogn.smbaogn_area%TYPE,
      param2   IN   smrdorq.smrdorq_caa_seqno%TYPE,
      param3   IN   smrdorq.smrdorq_term_code_eff%TYPE,
      param4   IN   stvprnt.stvprnt_code%TYPE
   )
      RETURN NUMBER;

   FUNCTION chk_smbgrul_addtnl_text (
      param1   IN   smbgogn.smbgogn_group%TYPE,
      param2   IN   smrdorq.smrdorq_caa_seqno%TYPE,
      param3   IN   smrdorq.smrdorq_term_code_eff%TYPE,
      param4   IN   stvprnt.stvprnt_code%TYPE
   )
      RETURN NUMBER;

   FUNCTION chk_adj_smbgrul_addtnl_text (
      param1   IN   spriden.spriden_pidm%TYPE,
      param2   IN   smbgogn.smbgogn_group%TYPE,
      param3   IN   smrdorq.smrdorq_caa_seqno%TYPE,
      param4   IN   smrdorq.smrdorq_term_code_eff%TYPE,
      param5   IN   stvprnt.stvprnt_code%TYPE
   )
      RETURN NUMBER;

   FUNCTION chk_adj_smbarul_addtnl_text (
      param1   IN   spriden.spriden_pidm%TYPE,
      param2   IN   smbaogn.smbaogn_area%TYPE,
      param3   IN   smrdorq.smrdorq_caa_seqno%TYPE,
      param4   IN   smrdorq.smrdorq_term_code_eff%TYPE,
      param5   IN   stvprnt.stvprnt_code%TYPE
   )
      RETURN NUMBER;

   FUNCTION chk_smrdous_grp_rule_crse_cnt (
      param1   IN   spriden.spriden_pidm%TYPE,
      param2   IN   smrdous.smrdous_request_no%TYPE,
      param3   IN   smrdous.smrdous_area%TYPE,
      param4   IN   smbgogn.smbgogn_group%TYPE,
      param5   IN   smrdous.smrdous_caa_seqno%TYPE,
      param6   IN   smrdous.smrdous_key_rule%TYPE
   )
      RETURN NUMBER;

   FUNCTION get_prog_ip_cred_tot (
      param1   IN   smbpogn.smbpogn_pidm%TYPE,
      param2   IN   smbpogn.smbpogn_request_no%TYPE
   )
      RETURN NUMBER;

   FUNCTION get_prog_unused_crse_tot (
      param1   IN   smbpogn.smbpogn_pidm%TYPE,
      param2   IN   smbpogn.smbpogn_request_no%TYPE
   )
      RETURN NUMBER;

   FUNCTION get_prog_ip_crse_tot (
      param1   IN   smbpogn.smbpogn_pidm%TYPE,
      param2   IN   smbpogn.smbpogn_request_no%TYPE
   )
      RETURN NUMBER;

   FUNCTION get_prog_trans_cred_tot (
      param1   IN   smbpogn.smbpogn_pidm%TYPE,
      param2   IN   smbpogn.smbpogn_request_no%TYPE
   )
      RETURN NUMBER;

   FUNCTION get_prog_unused_cred_tot (
      param1   IN   smbpogn.smbpogn_pidm%TYPE,
      param2   IN   smbpogn.smbpogn_request_no%TYPE
   )
      RETURN NUMBER;

   FUNCTION get_group_key_rule_desc (
      param1   IN   smbgrul.smbgrul_key_rule%TYPE,
      param2   IN   smbgrul.smbgrul_group%TYPE,
      param3   IN   smbgrul.smbgrul_term_code_eff%TYPE
   )
      RETURN smbgrul.smbgrul_desc%TYPE;

   FUNCTION get_adj_group_key_rule_desc (
      param1   IN   smbsgru.smbsgru_key_rule%TYPE,
      param2   IN   smbsgru.smbsgru_group%TYPE,
      param3   IN   smbsgru.smbsgru_term_code_eff%TYPE,
      param4   IN   spriden.spriden_pidm%TYPE
   )
      RETURN smbsgru.smbsgru_desc%TYPE;

   FUNCTION get_area_key_rule_desc (
      param1   IN   smbarul.smbarul_key_rule%TYPE,
      param2   IN   smbarul.smbarul_area%TYPE,
      param3   IN   smbarul.smbarul_term_code_eff%TYPE
   )
      RETURN smbarul.smbarul_desc%TYPE;

   FUNCTION get_adj_area_key_rule_desc (
      param1   IN   smbsaru.smbsaru_key_rule%TYPE,
      param2   IN   smbsaru.smbsaru_area%TYPE,
      param3   IN   smbsaru.smbsaru_term_code_eff%TYPE,
      param4   IN   spriden.spriden_pidm%TYPE
   )
      RETURN smbsaru.smbsaru_desc%TYPE;

   FUNCTION chk_smrdous_area_rule_crse_cnt (
      param1   IN   spriden.spriden_pidm%TYPE,
      param2   IN   smrdous.smrdous_request_no%TYPE,
      param3   IN   smbaogn.smbaogn_area%TYPE,
      param4   IN   smrdous.smrdous_caa_seqno%TYPE,
      param5   IN   smrdous.smrdous_key_rule%TYPE
   )
      RETURN NUMBER;

   -- 80840
   FUNCTION f_get_grp_rule_met_ind(pidm_in    IN SPRIDEN.SPRIDEN_PIDM%TYPE,
                                   req_no_in  IN SMRRQCM.SMRRQCM_REQUEST_NO%TYPE,
                                   area_in    IN SMRALIB.SMRALIB_AREA%TYPE,
                                   group_in   IN SMRGLIB.SMRGLIB_GROUP%TYPE,
                                   rule_in    IN SMBGOGN.SMBGOGN_RULE%TYPE,
                                   term_in    IN SMRGRRQ.SMRGRRQ_TERM_CODE_EFF%TYPE
   )
      RETURN SMRGRRQ.SMRGRRQ_MET_IND%TYPE;

   FUNCTION F_GetAdvrPidm (
      pidm   IN   spriden.spriden_pidm%TYPE,
      term   IN   stvterm.stvterm_code%TYPE
   )
      RETURN spriden.spriden_pidm%TYPE;

   FUNCTION F_GetEmailAddress (
      pidm_in         IN   spriden.spriden_pidm%TYPE,
      email_code_in   IN   GOREMAL.GOREMAL_EMAL_CODE%TYPE
   )
      RETURN GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE;

   FUNCTION F_GetEmailNamestr (pidm IN spriden.spriden_pidm%TYPE)
      RETURN VARCHAR2;

   FUNCTION print_requirements (
      req_credits   IN   NUMBER,
      req_courses   IN   NUMBER,
      connector     IN   VARCHAR2,
      act_credits   IN   NUMBER,
      act_courses   IN   NUMBER
   )
      RETURN VARCHAR2;

   FUNCTION req_conv (param1 IN smbpogn.smbpogn_met_ind%TYPE)
      RETURN VARCHAR2;

   FUNCTION req_notmet_color (param1 IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION req_notmet_color (
      param1   IN   smbpogn.smbpogn_act_credits_overall%TYPE
   )
      RETURN VARCHAR2;

   FUNCTION req_notmet_color (
      param1   IN   smbpogn.smbpogn_act_courses_overall%TYPE
   )
      RETURN VARCHAR2;

   FUNCTION req_conv_color (param1 IN smbpogn.smbpogn_met_ind%TYPE)
      RETURN VARCHAR2;

   --
   -- RPE 26595.
   FUNCTION det_conv_color (
      param1   IN   smrdorq.smrdorq_met_ind%TYPE,
      param2   IN   smbpogn.smbpogn_met_ind%TYPE
   )
      RETURN VARCHAR2;

   FUNCTION f_gen_req_label_disp (
      param1   IN   SMBAOGN.SMBAOGN_REQ_CREDITS_OVERALL%TYPE,
      param2   IN   SMBAOGN.SMBAOGN_REQ_COURSES_OVERALL%TYPE
   )
      RETURN BOOLEAN;

-- PRAGMA RESTRICT_REFERENCES (f_gen_req_label_disp, WNDS, WNPS, RNPS);

   --
   -- Following function for RPE # 26520
   -- ( Allow control of whether to display
   --   spacer bar on detail requirements. )
   --

   FUNCTION f_display_separator
      RETURN BOOLEAN;

-- PRAGMA RESTRICT_REFERENCES (f_display_separator, WNDS, WNPS, RNPS);

-------------------------------------------
--
-- Procedure Section
--
-------------------------------------------

   --
   -- The following seven procedures used for processing
   -- or formating of output for the remaining procedures.
   --

   PROCEDURE P_CommonOutputHeader (
      call_proc          IN    VARCHAR2 DEFAULT NULL,
      printer_friendly   IN    VARCHAR2,
      eval_term_out     OUT    SMRRQCM.SMRRQCM_TERM_CODE_EVAL%TYPE
   );

   PROCEDURE P_GenReqOutput (
      pidm         IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrrqcm.smrrqcm_request_no%TYPE,
      term         IN   stvterm.stvterm_code%TYPE
   );

   PROCEDURE decode_set_subset (
      prev_set     IN       smracaa.smracaa_set%TYPE DEFAULT NULL,
      prev_sub     IN       smracaa.smracaa_subset%TYPE DEFAULT NULL,
      cur_set      IN       smracaa.smracaa_set%TYPE DEFAULT NULL,
      cur_sub      IN       smracaa.smracaa_subset%TYPE DEFAULT NULL,
      open_paren   IN OUT   BOOLEAN,
      first_req    IN OUT   BOOLEAN,
      set_sub      OUT      VARCHAR2
   );

   PROCEDURE p_decode_subj_link (
      catlg_term_in      IN OUT   STVTERM.STVTERM_CODE%TYPE,
      subj_code_in       IN OUT   STVSUBJ.STVSUBJ_CODE%TYPE,
      crse_low_in        IN OUT   SCBCRSE.SCBCRSE_CRSE_NUMB%TYPE,
      crse_high_in       IN OUT   SCBCRSE.SCBCRSE_CRSE_NUMB%TYPE,
      request_no_in      IN OUT   SMRRQCM.SMRRQCM_REQUEST_NO%TYPE,
      printer_friendly   IN OUT   VARCHAR2,
      detl_met_ind       IN       SMRDORQ.SMRDORQ_MET_IND%TYPE,
      area_met_ind       IN       SMBPOGN.SMBPOGN_MET_IND%TYPE
   );

   PROCEDURE p_format_met_bar (
      param1   IN   SMBAOGN.SMBAOGN_AREA%TYPE,
      param2   IN   SMBAOGN.SMBAOGN_REQ_CREDITS_OVERALL%TYPE,
      param3   IN   SMBAOGN.SMBAOGN_REQ_COURSES_OVERALL%TYPE,
      param4   IN   SMBAOGN.SMBAOGN_CONNECTOR_OVERALL%TYPE,
      param5   IN   VARCHAR2 DEFAULT NULL,
      param6   IN   SMBAOGN.SMBAOGN_MET_IND%TYPE,
      param7   IN   VARCHAR2 DEFAULT NULL
   );

   PROCEDURE p_format_detail_title_bar;

   PROCEDURE p_format_area_detail_text (
      pidm_in         IN       SPRIDEN.SPRIDEN_PIDM%TYPE,
      source_in       IN       SMBAOGN.SMBAOGN_SOURCE_IND%TYPE,
      area_in         IN       SMBAOGN.SMBAOGN_AREA%TYPE,
      term_in         IN       STVTERM.STVTERM_CODE%TYPE,
      met_ind_in      IN       SMBAOGN.SMBAOGN_MET_IND%TYPE,
      gc_ind          IN       SMBAOGN.SMBAOGN_GC_IND%TYPE,
      dflt_text_out   OUT      STVPRNT.STVPRNT_CODE%TYPE
   );

   PROCEDURE p_format_group_detail_text (
      pidm_in         IN       SPRIDEN.SPRIDEN_PIDM%TYPE,
      source_in       IN       SMBGOGN.SMBGOGN_SOURCE_IND%TYPE,
      group_in        IN       SMBGOGN.SMBGOGN_AREA%TYPE,
      term_in         IN       STVTERM.STVTERM_CODE%TYPE,
      met_ind_in      IN       SMBGOGN.SMBGOGN_MET_IND%TYPE,
      dflt_text_out   OUT      STVPRNT.STVPRNT_CODE%TYPE
   );

   PROCEDURE p_format_program_hdr_text (
      pidm_in      IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      source_in    IN   SMBAOGN.SMBAOGN_SOURCE_IND%TYPE,
      prog_in      IN   SMBAOGN.SMBAOGN_AREA%TYPE,
      term_in      IN   STVTERM.STVTERM_CODE%TYPE,
      met_ind_in   IN   SMBPOGN.SMBPOGN_MET_IND%TYPE
   );

   PROCEDURE p_format_pgen_reqments (
       req_credits IN SMBPGEN.SMBPGEN_REQ_CREDITS_OVERALL%TYPE,
       req_courses IN SMBPGEN.SMBPGEN_REQ_COURSES_OVERALL%TYPE,
       act_credits IN SMBPGEN.SMBPGEN_REQ_CREDITS_OVERALL%TYPE,
       act_courses IN SMBPGEN.SMBPGEN_REQ_COURSES_OVERALL%TYPE
   );

   --
   -- RPE # 26520
   --
   PROCEDURE p_format_separator (text_in IN TWGRINFO.TWGRINFO_TEXT%TYPE);

   --
   -- Web Page
   --
   PROCEDURE P_DispEvalDetailReq(psReclDesc VARCHAR2);

   --
   -- Web Page
   --
   PROCEDURE P_DispEvalGeneralReq(psReclDesc VARCHAR2);
---------------------------------------------------------------------------
-- BOTTOM
-- Package Specification pk_bwcksmlt

  PROCEDURE P_VerifyDispEvalViewOption(psReclDesc VARCHAR2);

  PROCEDURE P_CSS;

END pk_bwcksmlt;
/


DROP PUBLIC SYNONYM PK_BWCKSMLT;

CREATE PUBLIC SYNONYM PK_BWCKSMLT FOR BANINST1.PK_BWCKSMLT;


GRANT EXECUTE ON BANINST1.PK_BWCKSMLT TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_BWCKSMLT TO WWW2_USER;

DROP PACKAGE BODY BANINST1.PK_BWCKSMLT;

CREATE OR REPLACE PACKAGE BODY BANINST1.pk_bwcksmlt AS
--AUDIT_TRAIL_MSGKEY_UPDATE
-- PROJECT : MSGKEY
-- MODULE  : BWCKSML1
-- SOURCE  : enUS
-- TARGET  : I18N
-- DATE    : Thu Apr 22 13:02:36 2010
-- MSGSIGN : #379452d028af4ffb
--TMI18N.ETR DO NOT CHANGE--
--
-- FILE NAME..: bwcksml1.sql
-- RELEASE....: 8.4.0.1
-- OBJECT NAME: bwcksmlt
-- PRODUCT....: SCOMWEB
-- USAGE......:
-- COPYRIGHT..: Copyright(C) 2002 - 2009 SunGard. All rights reserved.
--
-- Contains confidential and proprietary information of SunGard and its subsidiaries.
-- Use of these materials is limited to SunGard Higher Education licensees, and is
-- subject to the terms and conditions of one or more written license agreements
-- between SunGard Higher Education and the licensee in question.
--
-- DESCRIPTION:
--
-- This package contains objects used to display
-- Student's CAPP output to the web.
--
-- DESCRIPTION END
--
   pidm                 SPRIDEN.SPRIDEN_PIDM%TYPE;
   curr_release         CONSTANT VARCHAR2 (10) := '8.4.0.1';
   smbpogn_row        SMBPOGN%ROWTYPE;
   global_pidm          SPRIDEN.SPRIDEN_PIDM%TYPE;
   student_name         VARCHAR2(185);
   confid_msg           VARCHAR2(90);
   smbwcrl_row          SMBWCRL%ROWTYPE;
   smrcprt_row          SMRCPRT%ROWTYPE;
   term_used               STVTERM.STVTERM_CODE%TYPE;
   levl_used               STVLEVL.STVLEVL_CODE%TYPE;
   camp_used               STVCAMP.STVCAMP_CODE%TYPE;
   round_truncate_gpa      SHROGDR.SHROGDR_GPA_ROUND_CDE%TYPE;
   display_gpa_digits      SHROGDR.SHROGDR_GPA_DISPLAY_NUMBER%TYPE;
   round_truncate_points   SHROGDR.SHROGDR_QP_ROUND_CDE%TYPE;
   display_points_digits   SHROGDR.SHROGDR_QP_DISPLAY_NUMBER%TYPE;
   qual_pts                VARCHAR2 (25)             DEFAULT NULL;
   gpa_hrs                 VARCHAR2 (25)             DEFAULT NULL;
   max_field_length        VARCHAR2 (3)              DEFAULT '18';
   max_gpa_length          VARCHAR2 (3)              DEFAULT '25';
   format_mask             VARCHAR2 (31)             DEFAULT NULL;
   sig_format_mask         VARCHAR2 (31)             DEFAULT NULL;

   -- Common Label section used for both pages.
   -- If change required, change label only.
   -- Labels current for

   -- bwcksmlt.P_CommonOutputHeader
   -- bwcksmlt.P_DispEvalDetailReq
   -- bwcksmlt.P_DispGeneralReq
   --
   lbl_prog_header      VARCHAR2(47) DEFAULT
       g$_nls.get('BWCKSML1-0000','SQL','Program Evaluation');
   lbl_prog             VARCHAR2(29)  DEFAULT
       g$_nls.get('BWCKSML1-0001','SQL','Program :');
   lbl_levl             VARCHAR2(27)  DEFAULT
       g$_nls.get('BWCKSML1-0002','SQL','Level :');
   lbl_camp             VARCHAR2(28)  DEFAULT
       g$_nls.get('BWCKSML1-0003','SQL','Campus :');
   lbl_coll             VARCHAR2(29)  DEFAULT
       g$_nls.get('BWCKSML1-0004','SQL','College :');
   lbl_degc             VARCHAR2(28)  DEFAULT
       g$_nls.get('BWCKSML1-0005','SQL','Degree :');
   lbl_majrs            VARCHAR2(31) DEFAULT
       g$_nls.get('BWCKSML1-0006','SQL','Majors :');
   lbl_depts            VARCHAR2(37) DEFAULT
       g$_nls.get('BWCKSML1-0007','SQL','Departments :');
   lbl_ctlg_term        VARCHAR2(36) DEFAULT
       g$_nls.get('BWCKSML1-0008','SQL','Catalog Term :');
   lbl_eval_term        VARCHAR2(37) DEFAULT
       g$_nls.get('BWCKSML1-0009','SQL','Evaluation Term :');
   lbl_exp_grd_date     VARCHAR2(47) DEFAULT
       g$_nls.get('BWCKSML1-0010','SQL','Expected Graduation Date :');
   lbl_req_no           VARCHAR2(37) DEFAULT
       g$_nls.get('BWCKSML1-0011','SQL','Request Number :');
   lbl_eff_date         VARCHAR2(35) DEFAULT
       g$_nls.get('BWCKSML1-0012','SQL','Results as of :');
   lbl_minrs            VARCHAR2(30) DEFAULT
       g$_nls.get('BWCKSML1-0013','SQL','Minors :');
   lbl_concs            VARCHAR2(39) DEFAULT
       g$_nls.get('BWCKSML1-0014','SQL','Concentrations :');
   lbl_tot_req          VARCHAR2(36) DEFAULT
       g$_nls.get('BWCKSML1-0015','SQL','Total Required :');
   lbl_prg_gpa          VARCHAR2(100) DEFAULT
       g$_nls.get('BWCKSML1-0016','SQL','Program %01% :',
                  '<ACRONYM title = "' ||
                  g$_nls.get ('BWCKSML1-0017','SQL','Grade Point Average') ||
                  '">' ||
                  g$_nls.get('BWCKSML1-0018', 'SQL','GPA') ||
                  '</ACRONYM>'
                  );
   lbl_ovr_gpa          VARCHAR2(100) DEFAULT
       g$_nls.get('BWCKSML1-0019','SQL','Overall %01% :',
                  '<ACRONYM title = "' ||
                  g$_nls.get ('BWCKSML1-0020','SQL','Grade Point Average') ||
                  '">' ||
                  g$_nls.get('BWCKSML1-0021', 'SQL','GPA') ||
                  '</ACRONYM>'
                  );
   lbl_othr_info        VARCHAR2(47) DEFAULT
       g$_nls.get('BWCKSML1-0022','SQL','Other Course Information');
   lbl_trans            VARCHAR2(30) DEFAULT
       g$_nls.get('BWCKSML1-0023','SQL','Transfer :');
   lbl_ip               VARCHAR2(33) DEFAULT
       g$_nls.get('BWCKSML1-0024','SQL','In Progress :');
   lbl_unused           VARCHAR2(28)  DEFAULT
       g$_nls.get('BWCKSML1-0025','SQL','Unused :');
   lbl_req_inst         VARCHAR2(44) DEFAULT
       g$_nls.get('BWCKSML1-0026','SQL','Required Institutional :');
   lbl_inst_trad        VARCHAR2(50) DEFAULT
       g$_nls.get('BWCKSML1-0027','SQL','Institutional Traditional :');
   lbl_max_inst         VARCHAR2(250) DEFAULT
       g$_nls.get('BWCKSML1-0028','SQL','Maximum Institutional %01% Non-Traditional :');
   lbl_lst_num          VARCHAR2(62) DEFAULT
       g$_nls.get('BWCKSML1-0029','SQL',
                  'Last Number %01% Institutional Required :', htf.br);
   lbl_lst_ernd         VARCHAR2(43) DEFAULT
       g$_nls.get('BWCKSML1-0030','SQL','...Out of Last Earned :');
   lbl_max_tran            VARCHAR2(39) DEFAULT
       g$_nls.get('BWCKSML1-0031','SQL','Maximum Transfer :');
   lbl_com_req          VARCHAR2(28)  DEFAULT
       g$_nls.get('BWCKSML1-0032','SQL','Required');
   lbl_com_used         VARCHAR2(24)  DEFAULT
       g$_nls.get('BWCKSML1-0033','SQL','Used');
   lbl_com_cred         VARCHAR2(27)  DEFAULT
       g$_nls.get('BWCKSML1-0034','SQL','Credits');
   lbl_com_crse         VARCHAR2(27)  DEFAULT
       g$_nls.get('BWCKSML1-0035','SQL','Courses');
   --
   -- End of P_CommonOutput common naming convention
   -- Starting Detail Requirement (P_DispEvalDetailReq )
   -- common naming convention.
   --
   lbl_area             VARCHAR2(28)  DEFAULT
       g$_nls.get('BWCKSML1-0036','SQL','Area  :');
   lbl_group            VARCHAR2(28)  DEFAULT
       g$_nls.get('BWCKSML1-0037','SQL','Group :');
   lbl_desc             VARCHAR2(33)  DEFAULT
       g$_nls.get('BWCKSML1-0038','SQL','Description :');
   lbl_met              VARCHAR2(23)  DEFAULT
       g$_nls.get('BWCKSML1-0039','SQL','Met');
   lbl_cond             VARCHAR2(31)  DEFAULT
       g$_nls.get('BWCKSML1-0040','SQL',' Condition ');
   lbl_rule             VARCHAR2(24)  DEFAULT
       g$_nls.get('BWCKSML1-0041','SQL','Rule');
   lbl_subj             VARCHAR2(27)  DEFAULT
       g$_nls.get('BWCKSML1-0042','SQL','Subject');
   lbl_attr             VARCHAR2(29)  DEFAULT
       g$_nls.get('BWCKSML1-0043','SQL','Attribute');
   lbl_low              VARCHAR2(23)  DEFAULT
       g$_nls.get('BWCKSML1-0044','SQL','Low');
   lbl_high             VARCHAR2(24)  DEFAULT
       g$_nls.get('BWCKSML1-0045','SQL','High');
   lbl_req_cred         VARCHAR2(37) DEFAULT
       g$_nls.get('BWCKSML1-0046','SQL','Required Credits');
   lbl_req_crse         VARCHAR2(37) DEFAULT
       g$_nls.get('BWCKSML1-0047','SQL','Required Courses');
   lbl_det_term         VARCHAR2(24)  DEFAULT
       g$_nls.get('BWCKSML1-0048','SQL','Term');
   lbl_det_crse         VARCHAR2(26)  DEFAULT
       g$_nls.get('BWCKSML1-0049','SQL','Course');
   lbl_title            VARCHAR2(25)  DEFAULT
       g$_nls.get('BWCKSML1-0050','SQL','Title');
   lbl_grde             VARCHAR2(25)  DEFAULT
       g$_nls.get('BWCKSML1-0051','SQL','Grade');
   lbl_src              VARCHAR2(26)  DEFAULT
       g$_nls.get('BWCKSML1-0052','SQL','Source');
   lbl_grp              VARCHAR2(25)  DEFAULT
       g$_nls.get('BWCKSML1-0053','SQL','Group');
   lbl_dsc              VARCHAR2(31)  DEFAULT
       g$_nls.get('BWCKSML1-0054','SQL','Description');
   lbl_act_cred         VARCHAR2(37) DEFAULT
       g$_nls.get('BWCKSML1-0055','SQL','Used Credits');
   lbl_act_crse         VARCHAR2(37) DEFAULT
       g$_nls.get('BWCKSML1-0056','SQL','Used Courses');
   --
   -- End of naming convention
   --

   -------------------------------------------
   --
   -- Cursors
   --
   -------------------------------------------

   CURSOR SMRDOUS_GROUP_COUNT_C
      (pidm       IN spriden.spriden_pidm%type,
       request_no IN smrdorq.smrdorq_request_no%type,
       area       IN smrdorq.smrdorq_area%type,
       grp        IN smrdorq.smrdorq_group%type,
       caa_seqno  IN smrdorq.smrdorq_caa_seqno%type)
   IS
      SELECT COUNT(*) cnt2
      FROM smrdous
      WHERE smrdous_pidm = pidm
      AND smrdous_request_no = request_no
      AND smrdous_area = area
      AND smrdous_group = grp
      AND smrdous_caa_seqno = caa_seqno
      ORDER BY smrdous_subj_code ASC, smrdous_crse_numb ASC, smrdous_attr_code ASC;

   -------------------------------------------

   CURSOR SMRDORQ_GROUP_C
      (pidm       IN spriden.spriden_pidm%type,
       request_no IN smbaogn.smbaogn_request_no%type,
       area       IN smrdorq.smrdorq_area%type,
       grp        IN smbgogn.smbgogn_group%type)
   IS
      SELECT *
      FROM smrdorq
      WHERE smrdorq_pidm = pidm
      AND smrdorq_request_no = request_no
      AND smrdorq_area = area
      AND smrdorq_group = grp
      ORDER BY DECODE(smrdorq_set,    '', '000', smrdorq_set),
               DECODE(smrdorq_subset, '', -1,    smrdorq_subset),
               DECODE(smrdorq_rule,   '', '000', smrdorq_rule),
                      smrdorq_subj_code,
                      smrdorq_crse_numb_low,
                      smrdorq_crse_numb_high,
                      smrdorq_attr_code,
                      smrdorq_atts_code,
                      smrdorq_camp_code,
                      smrdorq_coll_code,
                      smrdorq_dept_code;

   -------------------------------------------

   CURSOR SMRDOUS_GROUP_C
      (pidm       IN spriden.spriden_pidm%type,
       request_no IN smrdorq.smrdorq_request_no%type,
       area       IN smrdorq.smrdorq_area%type,
       grp        IN smbgogn.smbgogn_group%type,
       caa_seqno  IN smrdorq.smrdorq_caa_seqno%type)
   IS
      SELECT *
      FROM smrdous
      WHERE smrdous_pidm = pidm
      AND smrdous_request_no = request_no
      AND smrdous_area = area
      AND smrdous_group = grp
      AND smrdous_caa_seqno = caa_seqno
      ORDER BY smrdous_subj_code ASC,
               smrdous_crse_numb ASC,
               smrdous_attr_code ASC;

   -------------------------------------------

   CURSOR SMBGOGN_C
      (pidm       IN spriden.spriden_pidm%type,
       request_no IN smbaogn.smbaogn_request_no%type,
       area       IN smbaogn.smbaogn_area%type)

   IS
      SELECT *
      FROM
      SMBGOGN
      WHERE  SMBGOGN_PIDM = pidm
      AND    SMBGOGN_REQUEST_NO = request_no
      AND    SMBGOGN_AREA = area
      ORDER BY SMBGOGN_SET, SMBGOGN_SUBSET, SMBGOGN_GROUP;
/* 104232
      ORDER  BY DECODE(SMBGOGN_SET,    '', '000'),
                DECODE(SMBGOGN_SUBSET, '', -1);
*/
   -------------------------------------------

   CURSOR SMRPCMT_TEXT_C
      (program   IN smbpogn.smbpogn_program%TYPE,
       term      IN stvterm.stvterm_code%TYPE,
       dflt_text IN stvprnt.stvprnt_code%TYPE)
   IS
      SELECT SMRPCMT_TEXT
      FROM SMRPCMT
      WHERE SMRPCMT_PROGRAM = program
      AND   SMRPCMT_PRNT_CODE = dflt_text
      AND   SMRPCMT_TEXT_SEQNO IS NOT NULL
      AND   SMRPCMT_TERM_CODE_EFF = ( SELECT MAX(X.SMRPCMT_TERM_CODE_EFF)
                                       FROM SMRPCMT X
                                      WHERE X.SMRPCMT_PROGRAM = program
--                                         AND X.SMRPCMT_PRNT_CODE = dflt_text
                                         AND X.SMRPCMT_TERM_CODE_EFF <= term)
      ORDER BY SMRPCMT_TEXT_SEQNO ASC;

   -------------------------------------------

   CURSOR SMRSPCM_TEXT_c
      (pidm      IN spriden.spriden_pidm%TYPE,
       program   IN smbpgen.smbpgen_program%TYPE,
       term      IN stvterm.stvterm_code%TYPE,
       dflt_text IN stvprnt.stvprnt_code%TYPE)
   IS
      SELECT SMRSPCM_TEXT
      FROM   SMRSPCM
      WHERE  SMRSPCM_PIDM = pidm
      AND    SMRSPCM_PROGRAM = program
      AND    SMRSPCM_PRNT_CODE = dflt_text
      AND    SMRSPCM_TEXT_SEQNO IS NOT NULL
      AND    SMRSPCM_TERM_CODE_EFF = ( SELECT MAX(X.SMRSPCM_TERM_CODE_EFF)
                                        FROM   SMRSPCM X
                                        WHERE  X.SMRSPCM_PIDM = pidm
                                        AND    X.SMRSPCM_PROGRAM = program
                                        AND    X.SMRSPCM_TERM_CODE_EFF <= term)
--                                        WHERE  SMRSPCM_TERM_CODE_EFF <= term)
      ORDER BY SMRSPCM_TEXT_SEQNO ASC;

   -------------------------------------------

   CURSOR SMRACMT_TEXT_C
      (area      IN smbaogn.smbaogn_area%TYPE,
       term      IN stvterm.stvterm_code%TYPE,
       dflt_text IN stvcprt.stvcprt_code%TYPE)
   IS
      SELECT *
      FROM SMRACMT
      WHERE SMRACMT_AREA = area
      AND   SMRACMT_PRNT_CODE =  dflt_text
      AND   SMRACMT_TEXT_SEQNO IS NOT NULL
      AND   SMRACMT_TERM_CODE_EFF = ( SELECT MAX(X.SMRACMT_TERM_CODE_EFF)
                                       FROM SMRACMT X
                                       WHERE X.SMRACMT_AREA = area
--                                       AND   X.SMRACMT_PRNT_CODE = dflt_text
                                       AND   X.SMRACMT_TERM_CODE_EFF <= term)
      ORDER BY SMRACMT_TEXT_SEQNO;

   -------------------------------------------

   CURSOR SMRSACM_TEXT_C
      (pidm      IN spriden.spriden_pidm%TYPE,
       area      IN smbagen.smbagen_area%TYPE,
       term      IN stvterm.stvterm_code%TYPE,
       dflt_text IN stvcprt.stvcprt_code%TYPE)
   IS
      SELECT *
      FROM   SMRSACM
      WHERE  SMRSACM_PIDM = pidm
      AND    SMRSACM_AREA = area
      AND    SMRSACM_PRNT_CODE = dflt_text
      AND    SMRSACM_TEXT_SEQNO IS NOT NULL
      AND    SMRSACM_TERM_CODE_EFF = ( SELECT MAX(X.SMRSACM_TERM_CODE_EFF)
                                        FROM   SMRSACM X
                                        WHERE  X.SMRSACM_PIDM = pidm
                                        AND    X.SMRSACM_AREA  = area
--                                        AND    X.SMRSACM_PRNT_CODE = dflt_text
                                        AND    X.SMRSACM_TERM_CODE_EFF <= term)
      ORDER BY SMRSACM_TEXT_SEQNO;

   -------------------------------------------

   CURSOR smraccm_text_c
      (param1 IN smbaogn.smbaogn_area%TYPE,
       param2 IN smrdorq.smrdorq_caa_seqno%TYPE,
       param3 IN smrdorq.smrdorq_term_code_eff%TYPE,
       param4 IN stvprnt.stvprnt_code%TYPE)
   IS
      SELECT *
      FROM smraccm
      WHERE   smraccm_area = param1
      AND     smraccm_smracaa_seqno = param2
      AND     smraccm_prnt_code = param4
      AND     smraccm_term_code_eff = (SELECT MAX(x.smracaa_term_code_eff)
                                        FROM smracaa x
                                        WHERE x.smracaa_area = param1
                                        AND   x.smracaa_seqno = param2
--                                        AND   x.smraccm_prnt_code = param4
                                        AND   x.smracaa_term_code_eff <= param3)
      ORDER BY smraccm_text_seqno ASC;

   -------------------------------------------

   CURSOR smrgccm_text_c
      (param1 IN smbgogn.smbgogn_group%TYPE,
       param2 IN smrdorq.smrdorq_caa_seqno%TYPE,
       param3 IN smrdorq.smrdorq_term_code_eff%TYPE,
       param4 IN stvprnt.stvprnt_code%TYPE)
   IS
      SELECT *
      FROM smrgccm
      WHERE   smrgccm_group = param1
      AND     smrgccm_smrgcaa_seqno = param2
      AND     smrgccm_prnt_code = param4
      AND     smrgccm_term_code_eff = (SELECT MAX(x.smrgcaa_term_code_eff)
                                        FROM smrgcaa x
                                        WHERE x.smrgcaa_group = param1
                                        AND   x.smrgcaa_seqno = param2
--                                        AND   x.smrgccm_prnt_code = param4
                                        AND   x.smrgcaa_term_code_eff <= param3)
      ORDER BY smrgccm_text_seqno ASC;

   -------------------------------------------

   CURSOR SMRSGCM_TEXT_C
      (pidm      IN spriden.spriden_pidm%TYPE,
       grp       IN smbggen.smbggen_group%TYPE,
       term      IN stvterm.stvterm_code%TYPE,
       dflt_text IN stvcprt.stvcprt_code%TYPE)
   IS
      SELECT *
      FROM   SMRSGCM
      WHERE  SMRSGCM_PIDM = pidm
      AND    SMRSGCM_GROUP = grp
      AND    SMRSGCM_PRNT_CODE = dflt_text
      AND    SMRSGCM_TEXT_SEQNO IS NOT NULL
      AND    SMRSGCM_TERM_CODE_EFF = ( SELECT MAX(X.SMRSGCM_TERM_CODE_EFF)
                                        FROM   SMRSGCM X
                                        WHERE  X.SMRSGCM_PIDM = pidm
                                        AND    X.SMRSGCM_GROUP  = grp
--                                        AND    X.SMRSGCM_PRNT_CODE = dflt_text
                                        AND    X.SMRSGCM_TERM_CODE_EFF <= term)
      ORDER BY SMRSGCM_TEXT_SEQNO;

   -------------------------------------------

   CURSOR SMRGCMT_TEXT_C
      (grp       IN smbgogn.smbgogn_group%TYPE,
       term      IN stvterm.stvterm_code%TYPE,
       dflt_text IN stvcprt.stvcprt_code%TYPE)
   IS
      SELECT *
      FROM SMRGCMT
      WHERE SMRGCMT_GROUP = grp
      AND   SMRGCMT_PRNT_CODE =  dflt_text
      AND   SMRGCMT_TEXT_SEQNO IS NOT NULL
      AND   SMRGCMT_TERM_CODE_EFF = ( SELECT MAX(X.SMRGCMT_TERM_CODE_EFF)
                                       FROM SMRGCMT X
                                       WHERE X.SMRGCMT_GROUP = grp
--                                       AND   X.SMRGCMT_PRNT_CODE = dflt_text
                                       AND   X.SMRGCMT_TERM_CODE_EFF <= term)
      ORDER BY SMRGCMT_TEXT_SEQNO;

   -------------------------------------------

   CURSOR smrsact_text_c
      (param1 IN spriden.spriden_pidm%TYPE,
       param2 IN smbaogn.smbaogn_area%TYPE,
       param3 IN smrdorq.smrdorq_caa_seqno%TYPE,
       param4 IN smrdorq.smrdorq_term_code_eff%TYPE,
       param5 IN stvprnt.stvprnt_code%TYPE)
   IS
      SELECT *
      FROM smrsact
      WHERE   smrsact_area = param2
      AND     smrsact_pidm = param1
      AND     smrsact_smrsaca_seqno = param3
      AND     smrsact_prnt_code = param5
      AND     smrsact_term_code_eff = (SELECT MAX(x.smrsaca_term_code_eff)
                                        FROM smrsaca x
                                        WHERE x.smrsaca_area = param2
                                        AND   x.smrsaca_pidm = param1
                                        AND   x.smrsaca_seqno = param3
--                                        AND   x.smrsact_prnt_code = param5
                                        AND   x.smrsaca_term_code_eff <= param4)
      ORDER BY smrsact_text_seqno ASC;

   -------------------------------------------

   CURSOR smrsgct_text_c
      (param1 IN spriden.spriden_pidm%TYPE,
       param2 IN smbgogn.smbgogn_group%TYPE,
       param3 IN smrdorq.smrdorq_caa_seqno%TYPE,
       param4 IN smrdorq.smrdorq_term_code_eff%TYPE,
       param5 IN stvprnt.stvprnt_code%TYPE)
   IS
      SELECT *
      FROM smrsgct
      WHERE   smrsgct_group = param2
      AND     smrsgct_pidm = param1
      AND     smrsgct_smrsgca_seqno = param3
      AND     smrsgct_prnt_code = param5
      AND     smrsgct_term_code_eff = (SELECT MAX(x.smrsgca_term_code_eff)
                                        FROM smrsgca x
                                        WHERE x.smrsgca_group = param2
                                        AND   x.smrsgca_pidm = param1
                                        AND   x.smrsgca_seqno = param3
--                                        AND   x.smrsgct_prnt_code = param5
                                        AND   x.smrsgca_term_code_eff <= param4)
      ORDER BY smrsgct_text_seqno ASC;

   -------------------------------------------

   CURSOR SMRRQCM_ALL_C
      (pidm       IN spriden.spriden_pidm%TYPE,
       request_no IN smrrqcm.smrrqcm_request_no%type)
   IS
      SELECT *
      FROM SMRRQCM
      WHERE SMRRQCM_PIDM = pidm
      AND SMRRQCM_REQUEST_NO = request_no;

   -------------------------------------------

   CURSOR SMBPOGN_C
      (pidm       IN spriden.spriden_pidm%type,
       request_no IN smbpogn.smbpogn_request_no%type)
   IS
      SELECT * FROM smbpogn
      WHERE smbpogn_pidm = pidm
      AND smbpogn_request_no = request_no;

   -------------------------------------------
   -- 7.3.3
   -- Add smbaogn_area to ORDER BY.
   --
   CURSOR SMBAOGN_C
      (pidm       IN spriden.spriden_pidm%type,
       request_no IN smbaogn.smbaogn_request_no%type)
   IS
      SELECT DISTINCT * FROM smbaogn
      WHERE smbaogn_pidm = pidm
      AND smbaogn_request_no = request_no
      ORDER BY smbaogn_area_priority, smbaogn_area;

   -------------------------------------------

   CURSOR SMRDORQ_C
      (pidm       IN spriden.spriden_pidm%type,
       request_no IN smbaogn.smbaogn_request_no%type,
       area       IN smrdorq.smrdorq_area%type)
   IS
      SELECT *
      FROM smrdorq
      WHERE smrdorq_pidm = pidm
      AND smrdorq_request_no = request_no
      AND smrdorq_area = area
      ORDER BY DECODE(smrdorq_set,    '', '000', smrdorq_set),
               DECODE(smrdorq_subset, '', -1,    smrdorq_subset),
               DECODE(smrdorq_rule,   '', '000', smrdorq_rule),
                      smrdorq_subj_code,
                      smrdorq_crse_numb_low,
                      smrdorq_crse_numb_high,
                      smrdorq_attr_code,
                      smrdorq_atts_code,
                      smrdorq_camp_code,
                      smrdorq_coll_code,
                      smrdorq_dept_code;

   -------------------------------------------

   CURSOR SMRDOUS_COUNT_C(pidm IN spriden.spriden_pidm%type, request_no IN smrdorq.smrdorq_request_no%type,
                          area IN smrdorq.smrdorq_area%type, caa_seqno IN smrdorq.smrdorq_caa_seqno%type)
   IS
      SELECT COUNT(*) cnt
      FROM smrdous
      WHERE smrdous_pidm = pidm
      AND smrdous_request_no = request_no
      AND smrdous_area = area
      AND smrdous_caa_seqno = caa_seqno
      ORDER BY smrdous_subj_code ASC, smrdous_crse_numb ASC, smrdous_attr_code ASC;

   -------------------------------------------

   CURSOR SMRDOUS_C(pidm IN spriden.spriden_pidm%type, request_no IN smrdorq.smrdorq_request_no%type,
                    area IN smrdorq.smrdorq_area%type, caa_seqno IN smrdorq.smrdorq_caa_seqno%type)
   IS
      SELECT *
      FROM smrdous
      WHERE smrdous_pidm = pidm
      AND smrdous_request_no = request_no
      AND smrdous_area = area
      AND smrdous_caa_seqno = caa_seqno
      ORDER BY smrdous_subj_code ASC, smrdous_crse_numb ASC, smrdous_attr_code ASC;

   -------------------------------------------

   CURSOR SMRDOUS_ALL_C(pidm IN spriden.spriden_pidm%type, request_no IN smrdorq.smrdorq_request_no%type,
                       area IN smrdorq.smrdorq_area%type)
   IS
      SELECT *
      FROM smrdous
      WHERE smrdous_pidm = pidm
      AND smrdous_request_no = request_no
      AND smrdous_area = area
      ORDER BY smrdous_term_code ASC, smrdous_subj_code ASC, smrdous_crse_numb ASC, smrdous_attr_code ASC;

   -------------------------------------------
   --
   -- 5.4. New cursor for SMAWCRL Form controls
   --

   CURSOR smbwcrl_c (term_in IN STVTERM.STVTERM_CODE%TYPE)
   IS
      SELECT *
      FROM SMBWCRL
      WHERE SMBWCRL_TERM_CODE = ( SELECT MAX(X.SMBWCRL_TERM_CODE)
                                  FROM SMBWCRL X
                                  WHERE SMBWCRL_TERM_CODE <= term_in );

   -------------------------------------------
   --
   -- 5.4. New cursor for retrieving SMRCPRT
   -- ( compliance type values ) for print fields.
   --

   CURSOR smrcprt_c (cprt_code_in IN SMRCPRT.SMRCPRT_CPRT_CODE%TYPE)
   IS
      SELECT *
      FROM   SMRCPRT
      WHERE  SMRCPRT_CPRT_CODE = cprt_code_in;

   -------------------------------------------
   --
   -- FUNCTIONS
   --
   -------------------------------------------

   FUNCTION get_majr_desc
      (param1 IN stvmajr.stvmajr_code%TYPE)
      RETURN  stvmajr.stvmajr_desc%TYPE IS
      return_value         stvmajr.stvmajr_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT stvmajr_desc INTO return_value FROM stvmajr
      WHERE stvmajr_code = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_majr_desc;

    -------------------------------------------

   FUNCTION get_dept_desc
      (param1 IN stvdept.stvdept_code%TYPE)
      RETURN  stvdept.stvdept_desc%TYPE IS
      return_value         stvdept.stvdept_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT stvdept_desc INTO return_value FROM stvdept
      WHERE stvdept_code = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_dept_desc;

   -------------------------------------------

   FUNCTION get_date_fmt
      RETURN  twgbwrul.twgbwrul_date_fmt%TYPE IS
      return_value         twgbwrul.twgbwrul_date_fmt%TYPE  DEFAULT NULL;

   BEGIN

      SELECT twgbwrul_date_fmt INTO return_value FROM twgbwrul;

      RETURN return_value ;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_date_fmt ;

   -------------------------------------------

   FUNCTION get_term_desc
      (param1 IN stvterm.stvterm_code%TYPE)
      RETURN  stvterm.stvterm_desc%TYPE IS
      return_value         stvterm.stvterm_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT stvterm_desc INTO return_value FROM stvterm
      WHERE stvterm_code = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_term_desc;

   -------------------------------------------

   FUNCTION f_smrsacm_rowcount
      (pidm       IN  SPRIDEN.SPRIDEN_PIDM%TYPE,
       area       IN  SMRSACM.SMRSACM_AREA%TYPE,
       term       IN  STVTERM.STVTERM_CODE%TYPE,
       dflt_text  IN  STVCPRT.STVCPRT_CODE%TYPE)
      RETURN  NUMBER IS
      return_value         NUMBER DEFAULT 0;
      cnt                  NUMBER DEFAULT 0;

   BEGIN

      SELECT count(1) INTO cnt
      FROM  SMRSACM
      WHERE SMRSACM_PIDM = pidm
      AND   SMRSACM_AREA = area
      AND   SMRSACM_PRNT_CODE = dflt_text
      AND   SMRSACM_TEXT_SEQNO IS NOT NULL
      AND   SMRSACM_TERM_CODE_EFF <= (SELECT MAX(X.SMRSACM_TERM_CODE_EFF)
                                      FROM SMRSACM X
                                      WHERE X.SMRSACM_PIDM = pidm
                                      AND   X.SMRSACM_AREA = area
--                                      AND   X.SMRSACM_PRNT_CODE = dflt_text
                                      AND   X.SMRSACM_TERM_CODE_EFF <= term);
      SELECT CEIL(cnt/2) into return_value
      FROM dual;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END f_smrsacm_rowcount;

   -------------------------------------------

   FUNCTION f_smracmt_rowcount
      (area       IN  SMRACMT.SMRACMT_AREA%TYPE,
       term       IN  STVTERM.STVTERM_CODE%TYPE,
       dflt_text  IN  STVCPRT.STVCPRT_CODE%TYPE)
      RETURN  NUMBER IS
      return_value         NUMBER DEFAULT 0;
      cnt                  NUMBER DEFAULT 0;

   BEGIN

      SELECT count(1) INTO cnt
      FROM  SMRACMT
      WHERE SMRACMT_AREA = area
      AND   SMRACMT_PRNT_CODE =  dflt_text
      AND   SMRACMT_TEXT_SEQNO IS NOT NULL
      AND   SMRACMT_TERM_CODE_EFF <= ( SELECT MAX(X.SMRACMT_TERM_CODE_EFF)
                                       FROM SMRACMT X
                                       WHERE  X.SMRACMT_AREA = area
--                                       AND    X.SMRACMT_PRNT_CODE = dflt_text
                                       AND    X.SMRACMT_TERM_CODE_EFF <= term);

      SELECT CEIL(cnt/2) INTO return_value
      FROM DUAL;

      RETURN return_value ;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END f_smracmt_rowcount;

   -------------------------------------------

   FUNCTION f_smrsgcm_rowcount
      (pidm       IN  SPRIDEN.SPRIDEN_PIDM%TYPE,
       grp        IN  SMRSGCM.SMRSGCM_GROUP%TYPE,
       term       IN  STVTERM.STVTERM_CODE%TYPE,
       dflt_text  IN  STVCPRT.STVCPRT_CODE%TYPE)
      RETURN  NUMBER IS
      return_value         NUMBER DEFAULT 0;
      cnt                  NUMBER DEFAULT 0;

   BEGIN

      SELECT count(1) INTO cnt
      FROM  SMRSGCM
      WHERE SMRSGCM_PIDM = pidm
      AND   SMRSGCM_GROUP = grp
      AND   SMRSGCM_PRNT_CODE = dflt_text
      AND   SMRSGCM_TEXT_SEQNO IS NOT NULL
      AND   SMRSGCM_TERM_CODE_EFF <= (SELECT MAX(X.SMRSGCM_TERM_CODE_EFF)
                                      FROM SMRSGCM X
                                      WHERE X.SMRSGCM_PIDM = pidm
                                      AND   X.SMRSGCM_GROUP = grp
--                                      AND   X.SMRSGCM_PRNT_CODE = dflt_text
                                      AND   X.SMRSGCM_TERM_CODE_EFF <= term);

      SELECT CEIL(cnt/2) into return_value
      FROM dual;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END f_smrsgcm_rowcount;

   -------------------------------------------

   FUNCTION f_smrgcmt_rowcount
      (grp        IN  SMRGCMT.SMRGCMT_GROUP%TYPE,
       term       IN  STVTERM.STVTERM_CODE%TYPE,
       dflt_text  IN  STVCPRT.STVCPRT_CODE%TYPE)
      RETURN  NUMBER IS
      return_value         NUMBER DEFAULT 0;
      cnt                  NUMBER DEFAULT 0;

   BEGIN

      SELECT count(1) INTO cnt
      FROM  SMRGCMT
      WHERE SMRGCMT_GROUP = grp
      AND   SMRGCMT_PRNT_CODE = dflt_text
      AND   SMRGCMT_TEXT_SEQNO IS NOT NULL
      AND   SMRGCMT_TERM_CODE_EFF <= (SELECT MAX(X.SMRGCMT_TERM_CODE_EFF)
                                      FROM SMRGCMT X
                                      WHERE X.SMRGCMT_GROUP = grp
--                                      AND   X.SMRGCMT_PRNT_CODE = dflt_text
                                      AND   X.SMRGCMT_TERM_CODE_EFF <= term);
      SELECT CEIL(cnt/2) into return_value
      FROM dual;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END f_smrgcmt_rowcount;

   -------------------------------------------

   FUNCTION get_area_desc
      (param1 IN smralib.smralib_area%TYPE)
      RETURN  smralib.smralib_area_desc%TYPE IS

      return_value         smralib.smralib_area_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smralib_area_desc INTO return_value FROM smralib
      WHERE smralib_area = param1 ;

      RETURN return_value ;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_area_desc ;

   -------------------------------------------

   FUNCTION get_group_desc
      (param1 IN smrglib.smrglib_group%TYPE)
      RETURN  smrglib.smrglib_group_desc%TYPE IS

      return_value         smrglib.smrglib_group_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smrglib_group_desc INTO return_value FROM smrglib
      WHERE smrglib_group = param1 ;

      RETURN return_value ;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_group_desc ;

   -------------------------------------------

   FUNCTION get_alib_levl_code_stu
      (param1 IN smralib.smralib_area%TYPE)
      RETURN  smralib.smralib_levl_code_stu%TYPE IS

      return_value         smralib.smralib_levl_code_stu%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smralib_levl_code_stu INTO return_value FROM smralib
      WHERE smralib_area = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_alib_levl_code_stu;

   -------------------------------------------
   --
   -- Defect # 76704 - changed to SMRDOCN_CREDIT_HOURS_AVAIL.
   --
   FUNCTION get_prog_unused_cred_tot
      (param1 IN smbpogn.smbpogn_pidm%TYPE,
       param2 IN smbpogn.smbpogn_request_no%TYPE)
      RETURN NUMBER IS
      return_value   NUMBER DEFAULT 0;

   BEGIN

      SELECT SUM(SMRDOCN_CREDIT_HOURS_AVAIL) INTO return_value
      FROM   SMRDOCN
      WHERE  SMRDOCN_PIDM = param1
      AND    SMRDOCN_REQUEST_NO = param2;
      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_prog_unused_cred_tot;

   -------------------------------------------

   FUNCTION get_prog_ip_crse_tot
      (param1 IN smbpogn.smbpogn_pidm%TYPE,
       param2 IN smbpogn.smbpogn_request_no%TYPE)
      RETURN NUMBER IS

      return_value   NUMBER DEFAULT 0;

   BEGIN

      SELECT COUNT(*) INTO return_value
      FROM   SMRDOUS
      WHERE  SMRDOUS_PIDM = param1
      AND    SMRDOUS_REQUEST_NO = param2
      AND    SMRDOUS_CRSE_SOURCE = 'R'
      AND    SMRDOUS_CNT_IN_PROGRAM_IND = 'Y';

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_prog_ip_crse_tot;

   -------------------------------------------

   FUNCTION get_prog_unused_crse_tot
      (param1 IN smbpogn.smbpogn_pidm%TYPE,
       param2 IN smbpogn.smbpogn_request_no%TYPE)
      RETURN NUMBER IS

      return_value   NUMBER DEFAULT 0;

   BEGIN

      SELECT COUNT(*) INTO return_value
      FROM   SMRDOCN
      WHERE  SMRDOCN_PIDM = param1
      AND    SMRDOCN_REQUEST_NO = param2;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_prog_unused_crse_tot;

   -------------------------------------------

   FUNCTION get_prog_ip_cred_tot
      (param1 IN smbpogn.smbpogn_pidm%TYPE,
       param2 IN smbpogn.smbpogn_request_no%TYPE)
      RETURN NUMBER IS

      return_value   NUMBER DEFAULT 0;

   BEGIN

      SELECT SUM(SMRDOUS_CREDIT_HOURS) INTO return_value
      FROM   SMRDOUS
      WHERE  SMRDOUS_PIDM = param1
      AND    SMRDOUS_REQUEST_NO = param2
      AND    SMRDOUS_CRSE_SOURCE = 'R'
      AND    SMRDOUS_CNT_IN_PROGRAM_IND = 'Y';

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_prog_ip_cred_tot;

   -------------------------------------------

   FUNCTION get_prog_trans_cred_tot
      (param1 IN smbpogn.smbpogn_pidm%TYPE,
       param2 IN smbpogn.smbpogn_request_no%TYPE)
      RETURN NUMBER IS

      return_value   NUMBER DEFAULT NULL;

   BEGIN

      SELECT SUM(SMRDOUS_CREDIT_HOURS) INTO return_value
      FROM   SMRDOUS
      WHERE  SMRDOUS_PIDM = param1
      AND    SMRDOUS_REQUEST_NO = param2
      AND    SMRDOUS_CRSE_SOURCE = 'T';

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_prog_trans_cred_tot;

   -------------------------------------------

   FUNCTION get_area_key_rule_desc
      (param1 IN smbarul.smbarul_key_rule%TYPE,
       param2 IN smbarul.smbarul_area%TYPE,
       param3 IN smbarul.smbarul_term_code_eff%TYPE)
      RETURN  smbarul.smbarul_desc%TYPE IS

      return_value         smbarul.smbarul_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smbarul_desc INTO return_value FROM smbarul
      WHERE smbarul_key_rule = param1
      AND   smbarul_area     = param2
      AND   smbarul_term_code_eff = (SELECT MAX(x.smbarul_term_code_eff)
                                     FROM  smbarul x
                                     WHERE x.smbarul_key_rule = param1
                                     AND   x.smbarul_area     = param2
                                     AND   x.smbarul_term_code_eff <= param3);

      RETURN return_value ;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_area_key_rule_desc ;

   -------------------------------------------

   FUNCTION get_adj_area_key_rule_desc
      (param1 IN smbsaru.smbsaru_key_rule%TYPE,
       param2 IN smbsaru.smbsaru_area%TYPE,
       param3 IN smbsaru.smbsaru_term_code_eff%TYPE,
       param4 IN spriden.spriden_pidm%TYPE)
      RETURN  smbsaru.smbsaru_desc%TYPE IS

      return_value         smbsaru.smbsaru_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smbsaru_desc INTO return_value FROM smbsaru
      WHERE smbsaru_key_rule = param1
      AND   smbsaru_area     = param2
      AND   smbsaru_pidm     = param4
      AND   smbsaru_term_code_eff = (SELECT MAX(x.smbsaru_term_code_eff)
                                     FROM  smbsaru x
                                     WHERE x.smbsaru_key_rule = param1
                                     AND   x.smbsaru_area     = param2
                                     AND   x.smbsaru_pidm     = param4
                                     AND   x.smbsaru_term_code_eff <= param3);
      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_adj_area_key_rule_desc;

   -------------------------------------------

   FUNCTION get_group_key_rule_desc
      (param1 IN smbgrul.smbgrul_key_rule%TYPE,
       param2 IN smbgrul.smbgrul_group%TYPE,
       param3 IN smbgrul.smbgrul_term_code_eff%TYPE)
      RETURN  smbgrul.smbgrul_desc%TYPE IS

      return_value         smbgrul.smbgrul_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smbgrul_desc INTO return_value FROM smbgrul
      WHERE smbgrul_key_rule  = param1
      AND   smbgrul_group     = param2
      AND   smbgrul_term_code_eff = (SELECT MAX(x.smbgrul_term_code_eff)
                                     FROM  smbgrul x
                                     WHERE x.smbgrul_key_rule = param1
                                     AND   x.smbgrul_group     = param2
                                     AND   x.smbgrul_term_code_eff <= param3);

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_group_key_rule_desc;

   -------------------------------------------

   FUNCTION get_adj_group_key_rule_desc
      (param1 IN smbsgru.smbsgru_key_rule%TYPE,
       param2 IN smbsgru.smbsgru_group%TYPE,
       param3 IN smbsgru.smbsgru_term_code_eff%TYPE,
       param4 IN spriden.spriden_pidm%TYPE)
      RETURN  smbsgru.smbsgru_desc%TYPE IS

      return_value         smbsgru.smbsgru_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smbsgru_desc INTO return_value FROM smbsgru
      WHERE smbsgru_key_rule = param1
      AND   smbsgru_group    = param2
      AND   smbsgru_pidm     = param4
      AND   smbsgru_term_code_eff = (SELECT MAX(x.smbsgru_term_code_eff)
                                     FROM  smbsgru x
                                     WHERE x.smbsgru_key_rule = param1
                                     AND   x.smbsgru_group    = param2
                                     AND   x.smbsgru_pidm     = param4
                                     AND   x.smbsgru_term_code_eff <= param3);

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_adj_group_key_rule_desc ;

   -------------------------------------------

   FUNCTION chk_smbgrul_addtnl_text
      (param1 IN smbgogn.smbgogn_group%TYPE,
       param2 IN smrdorq.smrdorq_caa_seqno%TYPE,
       param3 IN smrdorq.smrdorq_term_code_eff%TYPE,
       param4 IN stvprnt.stvprnt_code%TYPE)
      RETURN  NUMBER IS

      return_value         NUMBER DEFAULT 0;

      CURSOR smrgccm_test_text_c
      (param1 smbgogn.smbgogn_group%TYPE,
       param2 smrdorq.smrdorq_caa_seqno%TYPE,
       param3 smrdorq.smrdorq_term_code_eff%TYPE,
       param4 stvprnt.stvprnt_code%TYPE)
      IS
      SELECT COUNT(*)
      FROM smrgccm
      WHERE   smrgccm_group = param1
      AND     smrgccm_smrgcaa_seqno = param2
      AND     smrgccm_prnt_code = param4
      AND     smrgccm_term_code_eff = (SELECT MAX(x.smrgcaa_term_code_eff)
                                        FROM smrgcaa x
                                        WHERE x.smrgcaa_group = param1
                                        AND   x.smrgcaa_seqno = param2
--                                        AND   x.smrgccm_prnt_code = param4
                                        AND   x.smrgcaa_term_code_eff <= param3);
   BEGIN

      OPEN smrgccm_test_text_c(param1, param2, param3, param4);
      FETCH smrgccm_test_text_c INTO return_value;
      CLOSE smrgccm_test_text_c;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END chk_smbgrul_addtnl_text;

   -------------------------------------------

   FUNCTION chk_smrdous_grp_rule_crse_cnt
      (param1 IN spriden.spriden_pidm%TYPE,
       param2 IN smrdous.smrdous_request_no%TYPE,
       param3 IN smrdous.smrdous_area%TYPE,
       param4 IN smbgogn.smbgogn_group%TYPE,
       param5 IN smrdous.smrdous_caa_seqno%TYPE,
       param6 IN smrdous.smrdous_key_rule%TYPE)

      RETURN  NUMBER IS

      return_value         NUMBER DEFAULT 0;

   BEGIN

      SELECT COUNT(1) INTO return_value
      FROM  SMRDOUS
      WHERE SMRDOUS_PIDM = param1
      AND   SMRDOUS_REQUEST_NO = param2
      AND   SMRDOUS_AREA = param3
      AND   SMRDOUS_GROUP = param4
      AND   SMRDOUS_CAA_SEQNO = param5
      AND   SMRDOUS_KEY_RULE = param6;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END chk_smrdous_grp_rule_crse_cnt;

   -------------------------------------------

   FUNCTION chk_smbarul_addtnl_text
      (param1 IN smbaogn.smbaogn_area%TYPE,
       param2 IN smrdorq.smrdorq_caa_seqno%TYPE,
       param3 IN smrdorq.smrdorq_term_code_eff%TYPE,
       param4 IN stvprnt.stvprnt_code%TYPE)
      RETURN  NUMBER IS

      return_value         NUMBER DEFAULT 0;

      CURSOR smraccm_test_text_c
      (param1 smbaogn.smbaogn_area%TYPE,
       param2 smrdorq.smrdorq_caa_seqno%TYPE,
       param3 smrdorq.smrdorq_term_code_eff%TYPE,
       param4 stvprnt.stvprnt_code%TYPE)
      IS
      SELECT COUNT(*)
      FROM smraccm
      WHERE   smraccm_area = param1
      AND     smraccm_smracaa_seqno = param2
      AND     smraccm_prnt_code = param4
      AND     smraccm_term_code_eff = (SELECT MAX(x.smracaa_term_code_eff)
                                        FROM smracaa x
                                        WHERE x.smracaa_area = param1
                                        AND   x.smracaa_seqno = param2
--                                        AND   x.smraccm_prnt_code = param4
                                        AND   x.smracaa_term_code_eff <= param3);
   BEGIN

      OPEN smraccm_test_text_c(param1, param2, param3, param4);
      FETCH smraccm_test_text_c INTO return_value;
      CLOSE smraccm_test_text_c;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END chk_smbarul_addtnl_text;

   -------------------------------------------

   FUNCTION chk_adj_smbgrul_addtnl_text
      (param1 IN spriden.spriden_pidm%TYPE,
       param2 IN smbgogn.smbgogn_group%TYPE,
       param3 IN smrdorq.smrdorq_caa_seqno%TYPE,
       param4 IN smrdorq.smrdorq_term_code_eff%TYPE,
       param5 IN stvprnt.stvprnt_code%TYPE)

      RETURN  NUMBER IS

      return_value         NUMBER DEFAULT 0;

      CURSOR smrsgct_test_text_c
      (param1 spriden.spriden_pidm%TYPE,
       param2 smbgogn.smbgogn_group%TYPE,
       param3 smrdorq.smrdorq_caa_seqno%TYPE,
       param4 smrdorq.smrdorq_term_code_eff%TYPE,
       param5 stvprnt.stvprnt_code%TYPE)
      IS
      SELECT COUNT(*)
      FROM smrsgct
      WHERE   smrsgct_group = param2
      AND     smrsgct_pidm = param1
      AND     smrsgct_smrsgca_seqno = param3
      AND     smrsgct_prnt_code = param5
      AND     smrsgct_term_code_eff <= (SELECT MAX(x.smrsgca_term_code_eff)
                                        FROM smrsgca x
                                        WHERE x.smrsgca_group = param2
                                        AND   x.smrsgca_pidm = param1
                                        AND   x.smrsgca_seqno = param3
--                                        AND   x.smrsgct_prnt_code = param5
                                        AND   x.smrsgca_term_code_eff <= param4);

   BEGIN

      OPEN smrsgct_test_text_c(param1, param2, param3, param4, param5);
      FETCH smrsgct_test_text_c INTO return_value;
      CLOSE smrsgct_test_text_c;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END chk_adj_smbgrul_addtnl_text;

   -------------------------------------------

   FUNCTION chk_adj_smbarul_addtnl_text
      (param1 IN spriden.spriden_pidm%TYPE,
       param2 IN smbaogn.smbaogn_area%TYPE,
       param3 IN smrdorq.smrdorq_caa_seqno%TYPE,
       param4 IN smrdorq.smrdorq_term_code_eff%TYPE,
       param5 IN stvprnt.stvprnt_code%TYPE)

      RETURN  NUMBER IS

      return_value         NUMBER DEFAULT 0;

      CURSOR smrsact_test_text_c
      (param1 spriden.spriden_pidm%TYPE,
       param2 smbaogn.smbaogn_area%TYPE,
       param3 smrdorq.smrdorq_caa_seqno%TYPE,
       param4 smrdorq.smrdorq_term_code_eff%TYPE,
       param5 stvprnt.stvprnt_code%TYPE)
      IS
      SELECT COUNT(*)
      FROM smrsact
      WHERE   smrsact_area = param2
      AND     smrsact_pidm = param1
      AND     smrsact_smrsaca_seqno = param3
      AND     smrsact_prnt_code = param5
      AND     smrsact_term_code_eff <= (SELECT MAX(x.smrsaca_term_code_eff)
                                        FROM smrsaca x
                                        WHERE x.smrsaca_area = param2
                                        AND   x.smrsaca_pidm = param1
                                        AND   x.smrsaca_seqno = param3
--                                        AND   x.smrsact_prnt_code = param5
                                        AND   x.smrsaca_term_code_eff <= param4);

   BEGIN

      OPEN smrsact_test_text_c(param1, param2, param3, param4, param5);
      FETCH smrsact_test_text_c INTO return_value;
      CLOSE smrsact_test_text_c;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END chk_adj_smbarul_addtnl_text;

   -------------------------------------------

   FUNCTION get_program_desc
      (param1 IN smrprle.smrprle_program%TYPE)
      RETURN  smrprle.smrprle_program_desc%TYPE IS

      return_value         smrprle.smrprle_program_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smrprle_program_desc INTO return_value FROM smrprle
      WHERE smrprle_program = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_program_desc;

   -------------------------------------------
   -- 82277
   -- Create seperate function to retrieve grad date
   -- based upon SGBSTDN record.
   -- 97960

   FUNCTION get_stdn_grad_date
      (param1 IN sgbstdn.sgbstdn_pidm%type,
       param2 IN sgbstdn.sgbstdn_term_code_eff%type)
      RETURN  SGBSTDN.SGBSTDN_EXP_GRAD_DATE%TYPE IS

      return_value  sgbstdn.sgbstdn_exp_grad_date%type DEFAULT NULL;

   BEGIN

      IF param2 IS NOT NULL THEN
         SELECT outer.sgbstdn_exp_grad_date INTO return_value
           FROM sgbstdn outer
          WHERE outer.sgbstdn_pidm = param1
            AND outer.sgbstdn_term_code_eff =
              (SELECT MAX (x.sgbstdn_term_code_eff)
                FROM sgbstdn x
                WHERE x.sgbstdn_term_code_eff <= param2
                  AND x.sgbstdn_pidm = param1);

      END IF;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_stdn_grad_date;

   -------------------------------------------
   -- 71426
   -- Rewrote so that only required parameters IN
   -- are for primary key sql query.
   --
   FUNCTION get_exp_grad_date
      (param1 IN shrdgmr.shrdgmr_pidm%type,
       param2 IN smrrqcm.smrrqcm_dgmr_seq_no%type)
      RETURN  SHRDGMR.SHRDGMR_GRAD_DATE%TYPE IS

      return_value  shrdgmr.shrdgmr_grad_date%type DEFAULT NULL;

   BEGIN

      IF param2 IS NOT NULL THEN
         SELECT shrdgmr_grad_date INTO return_value
         FROM   shrdgmr
         WHERE  shrdgmr_pidm = param1
         AND    shrdgmr_seq_no = param2;
      END IF;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_exp_grad_date;

   -------------------------------------------

   FUNCTION get_area_rule_desc
      (param1 IN smbarul.smbarul_key_rule%TYPE,
       param2 IN smbarul.smbarul_area%TYPE)
      RETURN  smbarul.smbarul_desc%TYPE IS

      return_value         smbarul.smbarul_desc%TYPE  DEFAULT NULL;

   BEGIN

      SELECT smbarul_desc INTO return_value FROM smbarul
      WHERE smbarul_key_rule = param1
      AND   smbarul_area     = param2;

      RETURN return_value ;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_area_rule_desc ;

   ---------------------------------------------

   FUNCTION get_levl_desc
      (param1 IN stvlevl.stvlevl_code%type )
      RETURN  stvlevl.stvlevl_desc%TYPE IS

      return_value  stvlevl.stvlevl_desc%TYPE DEFAULT NULL;

   BEGIN

      SELECT stvlevl_desc  INTO return_value
      FROM   stvlevl
      WHERE  stvlevl_code = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_levl_desc;

   -------------------------------------------

   FUNCTION get_eval_term
      (param1 IN smrrqcm.smrrqcm_pidm%TYPE,
       param2 IN smrrqcm.smrrqcm_request_no%TYPE)
      RETURN  smrrqcm.smrrqcm_term_code_eval%TYPE IS

      return_value   smrrqcm.smrrqcm_term_code_eval%type DEFAULT NULL;

   BEGIN

      SELECT smrrqcm_term_code_eval INTO return_value
      FROM   smrrqcm
      WHERE  smrrqcm_pidm = param1
      AND    smrrqcm_request_no = param2;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_eval_term;

   -------------------------------------------

   FUNCTION get_camp_desc
      (param1 IN stvcamp.stvcamp_code%type )
      RETURN  STVCAMP.STVCAMP_DESC%TYPE IS

      return_value   stvcamp.stvcamp_desc%type DEFAULT NULL;

   BEGIN

      SELECT stvcamp_desc INTO return_value
      FROM   stvcamp
      WHERE  stvcamp_code = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_camp_desc;

   -------------------------------------------

   FUNCTION get_coll_desc
      (param1 IN stvcoll.stvcoll_code%type )
      RETURN  STVCOLL.STVCOLL_DESC%TYPE IS

      return_value  stvcoll.stvcoll_desc%type DEFAULT NULL;

   BEGIN

      SELECT stvcoll_desc INTO return_value
      FROM   stvcoll
      WHERE  stvcoll_code = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

    END get_coll_desc;

   -------------------------------------------

   FUNCTION get_degc_desc
      (param1 IN stvdegc.stvdegc_code%type )
      RETURN  STVDEGC.STVDEGC_DESC%TYPE IS

      return_value   stvdegc.stvdegc_desc%type DEFAULT NULL;

   BEGIN

      SELECT stvdegc_desc INTO return_value
      FROM   stvdegc
      WHERE  stvdegc_code = param1;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END get_degc_desc;

   -------------------------------------------

   FUNCTION chk_smrdous_area_rule_crse_cnt
      (param1 IN spriden.spriden_pidm%TYPE,
       param2 IN smrdous.smrdous_request_no%TYPE,
       param3 IN smbaogn.smbaogn_area%TYPE,
       param4 IN smrdous.smrdous_caa_seqno%TYPE,
       param5 IN smrdous.smrdous_key_rule%TYPE)

      RETURN  NUMBER IS

      return_value         NUMBER DEFAULT 0;

   BEGIN

      SELECT COUNT(1) INTO return_value
      FROM  SMRDOUS
      WHERE SMRDOUS_PIDM = param1
      AND   SMRDOUS_REQUEST_NO = param2
      AND   SMRDOUS_AREA = param3
      AND   SMRDOUS_CAA_SEQNO = param4
      AND   SMRDOUS_KEY_RULE = param5;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END chk_smrdous_area_rule_crse_cnt;

   -------------------------------------------

   FUNCTION F_GetAdvrPidm
      (pidm IN spriden.spriden_pidm%type,
       term IN stvterm.stvterm_code%type)
      RETURN spriden.spriden_pidm%TYPE IS

      return_value           spriden.spriden_pidm%TYPE DEFAULT NULL;

      CURSOR get_advr_pidm_c(pidm smrrqcm.smrrqcm_pidm%type,
                             term sgradvr.sgradvr_term_code_eff%type)
      IS
      SELECT spriden_pidm
      FROM   SPRIDEN, SGRADVR
      WHERE  sgradvr_pidm = pidm
      AND    sgradvr_prim_ind = 'Y'
      AND    spriden_pidm = sgradvr_advr_pidm
      AND    spriden_change_ind IS NULL
      AND    sgradvr_term_code_eff = ( SELECT MAX(X.SGRADVR_TERM_CODE_EFF)
                                         FROM SGRADVR X
                                        WHERE X.SGRADVR_PIDM = pidm
                                          AND X.SGRADVR_TERM_CODE_EFF <= term);

   BEGIN

      OPEN get_advr_pidm_c(pidm, term);
      FETCH get_advr_pidm_c INTO
         return_value;
      CLOSE get_advr_pidm_c;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END F_GetAdvrPidm;

   -------------------------------------------

   FUNCTION F_GetEmailNamestr
      (  pidm IN spriden.spriden_pidm%type )
      RETURN VARCHAR2 IS

      return_value           VARCHAR2(130) DEFAULT NULL;

      CURSOR get_advr_namestr_c(pidm smrrqcm.smrrqcm_pidm%type)
      IS
      SELECT spriden_first_name || ' ' || spriden_last_name
      FROM   SPRIDEN
      WHERE  spriden_pidm = pidm
      AND    spriden_change_ind IS NULL;

   BEGIN

      OPEN get_advr_namestr_c(pidm);
      FETCH get_advr_namestr_c INTO
         return_value;
      CLOSE get_advr_namestr_c;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END F_GetEmailNamestr;

   -------------------------------------------

   FUNCTION F_GetEmailAddress
      (pidm_in       IN spriden.spriden_pidm%type,
       email_code_in IN GOREMAL.GOREMAL_EMAL_CODE%TYPE)
      RETURN GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE IS

      return_value   goremal.goremal_email_address%type DEFAULT NULL;

      CURSOR get_goremal_email_c(pidm_in GOREMAL.GOREMAL_PIDM%TYPE,
                                 email_code_in goremal.goremal_emal_code%TYPE)
      IS
      SELECT GOREMAL_EMAIL_ADDRESS
      FROM   GOREMAL
      WHERE  GOREMAL_PIDM = pidm_in
      AND    GOREMAL_STATUS_IND = 'A'
      AND    GOREMAL_PREFERRED_IND = 'Y'
      AND    GOREMAL_DISP_WEB_IND = 'Y'
      AND    GOREMAL_EMAL_CODE = email_code_in;

   BEGIN

      OPEN get_goremal_email_c(pidm_in, emaIl_code_in);
      FETCH get_goremal_email_c INTO
         return_value;
      CLOSE get_goremal_email_c;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN return_value;

   END F_GetEmailAddress;

   -------------------------------------------

   FUNCTION req_notmet_color
      (param1 IN  SMBPOGN.SMBPOGN_ACT_COURSES_OVERALL%TYPE)
      RETURN   VARCHAR2 IS

      return_value  VARCHAR2(58) DEFAULT NULL;
      tmp           SMBPOGN.SMBPOGN_ACT_COURSES_OVERALL%TYPE DEFAULT NULL;
      BEGIN
      tmp := param1;
      return_value := twbkfrmt.F_PrintText(tmp,class_in=>'requirementnotmet');

      RETURN return_value;

   END req_notmet_color;

   -------------------------------------------

   FUNCTION req_notmet_color
      (param1 IN VARCHAR2 )
      RETURN   VARCHAR2 IS
      return_value  VARCHAR2(250) DEFAULT NULL;
      tmp           VARCHAR2(250) DEFAULT NULL;
   BEGIN
      tmp := param1;
      return_value := twbkfrmt.F_PrintText(tmp,class_in=>'requirementnotmet');

      RETURN return_value;

   END req_notmet_color;

   -------------------------------------------

   FUNCTION req_notmet_color
      (param1 IN  SMBPOGN.SMBPOGN_ACT_CREDITS_OVERALL%TYPE)
      RETURN   VARCHAR2 IS

      return_value  VARCHAR2(58) DEFAULT NULL;
      tmp           SMBPOGN.SMBPOGN_ACT_CREDITS_OVERALL%TYPE DEFAULT NULL;
   BEGIN
      tmp := param1;
      return_value := twbkfrmt.F_PrintText(tmp,class_in=>'requirementnotmet');

      RETURN return_value;

   END req_notmet_color;

   -------------------------------------------

   FUNCTION req_conv
      (param1 IN SMBPOGN.SMBPOGN_MET_IND%TYPE)
      RETURN   VARCHAR2 IS

      return_value  VARCHAR2(24) DEFAULT NULL;

   BEGIN
      IF param1 = 'N' THEN
         --return_value := G$_NLS.Get('BWCKSML1-0004','SQL','No');--I18N Issue 1-3FA6GU
           return_value := 'No';
      ELSE
         return_value := param1;
      END IF;

      RETURN return_value;
   END req_conv;

   -------------------------------------------

   FUNCTION F_GenOutputAreaText
      (pidm       IN spriden.spriden_pidm%TYPE,
       area       IN smbaogn.smbaogn_area%TYPE,
       rec_source IN smbaogn.smbaogn_source_ind%TYPE,
       term       IN stvterm.stvterm_code%TYPE,
       dflt_text  IN stvprnt.stvprnt_code%TYPE)

   RETURN VARCHAR2 IS
       -- 7.3.3 1-1O7E26.  Increase size of text variables.

       return_value varchar2(32000) DEFAULT NULL;
       smracmt_rowcount NUMBER DEFAULT 0;
       smrsacm_rowcount NUMBER DEFAULT 0;
       area_text_cnt    NUMBER DEFAULT 0;
       hold_text        VARCHAR2(32000) DEFAULT NULL;

   BEGIN

      IF dflt_text IS NOT NULL THEN
         IF rec_source = 'O' THEN
            smracmt_rowcount := f_smracmt_rowcount(area, term, dflt_text);
            IF smracmt_rowcount <> 0 THEN
               return_value := '';
               hold_text := '';
                FOR smracmt_row in SMRACMT_TEXT_C(area, term, dflt_text) LOOP
                        hold_text := hold_text||' '||smracmt_row.smracmt_text;
                END LOOP;
            return_value := hold_text;
            END IF;  -- end smracmt
         END IF;     -- end original
         IF rec_source = 'A' THEN
            smrsacm_rowcount := f_smrsacm_rowcount(pidm, area, term, dflt_text);
            IF smrsacm_rowcount <> 0 THEN
               return_value := '';
               hold_text := '';
               FOR smrsacm_row IN SMRSACM_TEXT_C(pidm, area, term, dflt_text) LOOP
                        hold_text := hold_text||' '||smrsacm_row.smrsacm_text;
               END LOOP;
            return_value := hold_text;
            END IF; -- end smrsacm
         END IF;    -- end adjustment
      END IF;       -- end dflt_text

   RETURN return_value;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN return_value;

   END F_GenOutputAreaText;

   -------------------------------------------
   -- 80840
   FUNCTION f_get_grp_rule_met_ind(pidm_in    IN SPRIDEN.SPRIDEN_PIDM%TYPE,
                                   req_no_in  IN SMRRQCM.SMRRQCM_REQUEST_NO%TYPE,
                                   area_in    IN SMRALIB.SMRALIB_AREA%TYPE,
                                   group_in   IN SMRGLIB.SMRGLIB_GROUP%TYPE,
                                   rule_in    IN SMBGOGN.SMBGOGN_RULE%TYPE,
                                   term_in    IN SMRGRRQ.SMRGRRQ_TERM_CODE_EFF%TYPE)

   RETURN         SMRGRRQ.SMRGRRQ_MET_IND%TYPE IS

      return_value   SMRGRRQ.SMRGRRQ_MET_IND%TYPE DEFAULT NULL;

   BEGIN

     SELECT SMRGRRQ_MET_IND
       INTO return_value
       FROM SMRGRRQ
      WHERE SMRGRRQ_PIDM = pidm_in
        AND SMRGRRQ_REQUEST_NO = req_no_in
        AND SMRGRRQ_AREA = area_in
        AND SMRGRRQ_GROUP = group_in
        AND SMRGRRQ_KEY_RULE = rule_in
        AND SMRGRRQ_TERM_CODE_EFF = (SELECT MAX(SMRGRRQ_TERM_CODE_EFF)
       FROM SMRGRRQ
      WHERE SMRGRRQ_PIDM = pidm_in
        AND SMRGRRQ_REQUEST_NO = req_no_in
        AND SMRGRRQ_AREA = area_in
        AND SMRGRRQ_GROUP = group_in
        AND SMRGRRQ_KEY_RULE = rule_in
        AND SMRGRRQ_TERM_CODE_EFF <= term_in)
     ORDER BY SMRGRRQ_SEQNO;

   RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
       RETURN return_value;

   END f_get_grp_rule_met_ind;

   -------------------------------------------

   FUNCTION req_conv_color
      (param1 IN SMBPOGN.SMBPOGN_MET_IND%TYPE)
      RETURN VARCHAR2 IS

      return_value  VARCHAR2(58) DEFAULT NULL;

   BEGIN
      IF param1 = 'Y' THEN
        --return_value := G$_NLS.Get('BWCKSML1-0007','SQL','Yes');--I18N Issue 1-3FA6GU
          return_value := 'Yes';
      END IF;
      IF param1 = 'N' THEN
        return_value := twbkfrmt.F_PrintText(
                           --G$_NLS.Get( 'BWCKSML1-0008', 'SQL', 'No'), --I18N Issue 1-3FA6GU
                           'No',
                           class_in => 'requirementnotmet');
      END IF;

      RETURN return_value;

   END req_conv_color;

   -------------------------------------------

   FUNCTION det_conv_color
      (param1 IN SMRDORQ.SMRDORQ_MET_IND%TYPE,
       param2 IN SMBPOGN.SMBPOGN_MET_IND%TYPE)
      RETURN VARCHAR2 IS

      return_value  VARCHAR2(58) DEFAULT NULL;

   BEGIN

      --
      -- New function for RPE 26595.
      -- If an area or group is MET, do
      -- not display any detail requirements
      -- that are NOT met in color of red.
      --

      IF param2 = 'N' THEN
         IF param1 = 'Y' THEN
            --return_value := G$_NLS.Get('BWCKSML1-0009', 'SQL', 'Yes');--I18N Issue 1-3FA6GU
              return_value := 'Yes';
         END IF;
         IF param1 = 'N' THEN
            return_value :=
        twbkfrmt.F_PrintText(
                                                 --G$_NLS.Get('BWCKSML1-0010', 'SQL','No'),--I18N Issue 1-3FA6GU
                                                 'No',
                             class_in=>'requirementnotmet');
         END IF;
         IF param1 = 'E' THEN
            -- 8.0 I18N 1-1ADJRE
            -- return_value := G$_NLS.Get('BWCKSML1-0013','SQL','E');
            return_value := 'E';
         END IF;
      ELSE
         IF param1 = 'Y' THEN
            --return_value := G$_NLS.Get('BWCKSML1-0011', 'SQL', 'Yes');--I18N Issue 1-3FA6GU
              return_value := 'Yes';
         END IF;
         IF param1 = 'N' THEN
            --return_value :=  G$_NLS.Get('BWCKSML1-0012', 'SQL', 'No');--I18N Issue 1-3FA6GU
              return_value := 'No';
         END IF;
         IF param1 = 'E' THEN
            -- 8.0 I18N 1-1ADJRE
            -- return_value := G$_NLS.Get('BWCKSML1-0013','SQL','E');
            return_value := 'E';
         END IF;
      END IF;

      RETURN return_value;

   END det_conv_color;

   -------------------------------------------

   FUNCTION print_requirements
      (req_credits IN NUMBER,
       req_courses IN NUMBER,
       connector   IN VARCHAR2,
       act_credits IN NUMBER,
       act_courses IN NUMBER)
      RETURN  VARCHAR2 IS

      return_value         VARCHAR2(3)  NOT NULL DEFAULT 'N';

   BEGIN

      -- ADD NVL to all req_* so that if there is "NULL" requirement
      -- and any type of actual - returns "Y"

      IF connector = 'A' THEN
         IF act_credits >= NVL(req_credits,0) AND act_courses >= NVL(req_courses,0) THEN
             return_value := 'Y';
         ELSE
             return_value := 'N';
         END IF;
      ELSIF connector = 'O' THEN
         IF act_credits >= NVL(req_credits,0) OR act_courses >= NVL(req_courses,0) THEN
             return_value := 'Y';
         ELSE
             return_value := 'N';
         END IF;
      ELSIF connector = 'N' THEN
      -- Defect 78685
         IF req_credits IS NOT NULL THEN
             IF act_credits >= req_credits THEN
                return_value := 'Y';
             ELSE
                   return_value := 'N';
             END IF;
         ELSIF req_courses IS NOT NULL THEN
             IF act_courses >= req_courses THEN
                return_value := 'Y';
             ELSE
                return_value := 'N';
             END IF;
         ELSIF ( req_courses IS NULL AND req_credits IS NULL) THEN
                return_value := 'Y';
         END IF;
      END IF;
      RETURN return_value ;
   END;

   -------------------------------------------
   --
   -- Used in procedure p_format_met_label.
   -- If required credits and courses for general requirements
   -- are both null, then we do not need any type of
   -- parenthesis's, therefor we'd skip any code logic
   -- that follows if this returns false.
   --

   FUNCTION f_gen_req_label_disp
      ( param1 IN SMBAOGN.SMBAOGN_REQ_CREDITS_OVERALL%TYPE,
        param2 IN SMBAOGN.SMBAOGN_REQ_COURSES_OVERALL%TYPE)
     RETURN BOOLEAN IS

     return_value BOOLEAN DEFAULT TRUE;

   BEGIN

      IF (param1 IS NULL) AND (param2 IS NULL) THEN
         return_value := FALSE;
      ELSE
         return_value := TRUE;
      END IF;

      RETURN return_value;

   END f_gen_req_label_disp;

   -------------------------------------------
   --
   -- Function for RPE # 26520
   --
   -- Returns true or false as to
   -- whether we are displaying a separator
   -- bar for the duration of the
   -- detail requirements page.
   -- Audit 5.5 WebUI. Order by
   -- _source_ind to pick up local first.

   FUNCTION f_display_separator
      RETURN       BOOLEAN IS

      return_value BOOLEAN DEFAULT FALSE;
      tmp          TWGRINFO.TWGRINFO_TEXT%TYPE;

      CURSOR twgrinfo_text_c IS
      SELECT TWGRINFO_TEXT
      FROM   TWGRINFO
      WHERE  TWGRINFO_NAME = 'bwcksmlt.P_DispEvalDetailReq'
      AND    TWGRINFO_LABEL = 'SPACER'
      AND    TWGRINFO_SEQUENCE = 1
      ORDER BY TWGRINFO_SOURCE_IND DESC;

   BEGIN

      OPEN twgrinfo_text_c;
      FETCH twgrinfo_text_c INTO tmp;
      CLOSE twgrinfo_text_c;

      IF tmp IS NOT NULL THEN
         return_value := TRUE;
      ELSE
         return_value := FALSE;
      END IF;

      RETURN return_value;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN return_value;

   END f_display_separator;

   -------------------------------------------
   --
   -- Procedure Section
   --
   -------------------------------------------
   --
   -- Web Page.
   -- This procedure responsible for formatting
   -- general requirements section.
   --

   PROCEDURE P_DispEvalGeneralReq(psReclDesc VARCHAR2)
   IS

      pidm                 SPRIDEN.SPRIDEN_PIDM%TYPE;
      global_pidm          SPRIDEN.SPRIDEN_PIDM%TYPE;
      button_text          VARCHAR2(20) DEFAULT NULL;
      header               BOOLEAN  NOT NULL DEFAULT FALSE;
      header2              BOOLEAN  NOT NULL DEFAULT FALSE;
      row_count            BINARY_INTEGER  NOT NULL DEFAULT 0;
      row_count2           BINARY_INTEGER  NOT NULL DEFAULT 0;
      term                 SMBPOGN.SMBPOGN_TERM_CODE_EFF%TYPE;
      email                GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE;
      namestr              VARCHAR2(90) DEFAULT NULL;
      advr_pidm            SPRIDEN.SPRIDEN_PIDM%TYPE DEFAULT NULL;
      call_path            VARCHAR2(2) DEFAULT NULL;
      smbarul_addtnl_text  NUMBER DEFAULT 0;
      prog_ip_cred_tot     NUMBER DEFAULT 0;
      prog_unused_cred_tot NUMBER DEFAULT 0;
      prog_ip_crse_tot     NUMBER DEFAULT 0;
      prog_unused_crse_tot NUMBER DEFAULT 0;
      curr_eval_term       SMRRQCM.SMRRQCM_TERM_CODE_EVAL%TYPE DEFAULT NULL;
      transfer_header      BOOLEAN NOT NULL DEFAULT FALSE;
      other_crse_header    BOOLEAN NOT NULL DEFAULT FALSE;
      call_proc            VARCHAR2(2) DEFAULT NULL;
      hold_term            STVTERM.STVTERM_CODE%TYPE;
      eval_term_out        SMRRQCM.SMRRQCM_TERM_CODE_EVAL%TYPE;
      eval_pidm            NUMBER DEFAULT 0;

   request_no       INTEGER       := 0;
   printer_friendly VARCHAR2(2)   := 'N';
   vsNombre         VARCHAR2(300) := NULL;
   vsPrograma       VARCHAR2(20)  := NULL;
   vsTerm           VARCHAR2(6)   := NULL;
   vsExpd           VARCHAR2(10)  := NULL;

   BEGIN
       IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

       --son buscadas los valores de las cookies para asignar los valores del filtro del query.
       vsTerm     := pk_objhtml.getvaluecookie('psPerio');
       vsPrograma := pk_objhtml.getvaluecookie('psProgr');
       vsExpd     := pk_objhtml.getvaluecookie('psExped');



        SELECT COUNT(*) INTO eval_pidm
        FROM SPRIDEN
        WHERE SPRIDEN_ID          = vsExpd
        AND SPRIDEN_CHANGE_IND IS NULL;

        IF eval_pidm > 0 THEN

            SELECT SPRIDEN_PIDM,
            REPLACE(SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME,'*',' ')
            INTO global_pidm,vsNombre
            FROM SPRIDEN
            WHERE SPRIDEN_ID          = vsExpd
            AND SPRIDEN_CHANGE_IND IS NULL;
        END IF;

        pidm        := global_pidm;
        call_path   := 'S';
        hold_term   := vsTerm;

        SELECT MAX(SMRRQCM_REQUEST_NO)
        INTO request_no
        FROM SMRRQCM
        WHERE SMRRQCM_PIDM        = pidm
        AND SMRRQCM_PROCESS_IND = 'N'
        AND SMRRQCM_PROGRAM     = vsPrograma;

        htp.p('<html><head><title>'||psReclDesc||'</title>');

       --muestra las hojas de estilo
       p_CSS;

       htp.p('
       <script type="text/javascript">
       <!--
       function fImprimeReporte() {
       window.focus()
       print();
       }
       //-->
       </script>

       </head><body>
       <br/>

       <table border="0" width="100%">
       <tr><th>'||psReclDesc||'</th></tr>
       <tr><th>'||vsTerm    ||' '||pk_Catalogo.Periodo(vsTerm)||'</th></tr>
       <tr><td>&nbsp;</td></tr>
       <tr><td>'||vsExpd||' '||vsNombre||'</td></tr>
       </table>

       <hr>
       ');

       twbkwbis.P_DispInfo('bwcksmlt.P_DispEvalGeneralReq','DEFAULT');

      OPEN SMBPOGN_C(pidm, request_no);
      FETCH SMBPOGN_C INTO smbpogn_row;
      CLOSE SMBPOGN_C;

      OPEN smbwcrl_c(hold_term);
      FETCH smbwcrl_c INTO smbwcrl_row;
      CLOSE smbwcrl_c;

      --
      -- If using a compliance type to build evaluation output,
      -- get this data now.
      --
      IF smbwcrl_row.smbwcrl_dflt_eval_cprt_code IS NOT NULL THEN
         OPEN smrcprt_c(smbwcrl_row.smbwcrl_dflt_eval_cprt_code);
         FETCH smrcprt_c INTO smrcprt_row;
         CLOSE smrcprt_c;
      END IF;

      --
      -- Place spacer at top of page;
      -- Initialize variables, then call procedures for creation
      -- /formatting of page
      --

      term := smbpogn_row.smbpogn_term_code_catlg;
      call_proc := 'GR';
      P_CommonOutputHeader(call_proc ,printer_friendly, eval_term_out);

      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0057',
                                   'SQL',
            'This table is used to present program general requirements') ||
                                '."'
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0058',
                                   'SQL',
            'This table is used to present program general requirements') ||
                                '."' ||
                                'WIDTH="100%"'         );
      END IF;
      P_GenReqOutput(pidm, request_no,term);
      twbkfrmt.P_TableClose;
      --
      -- Email link section.
      --
      IF call_path = 'S' THEN
         advr_pidm := F_GetAdvrPidm(pidm, hold_term);
         email := F_GetEmailAddress(advr_pidm, smbwcrl_row.smbwcrl_fac_email_code);
         IF email IS NOT NULL THEN
            namestr := F_GetEmailNamestr(advr_pidm);
            IF namestr IS NOT NULL THEN
               twbkwbis.P_DispInfo('bwcksmlt.P_DispEvalDetailReq','EMAIL',value1=>email, value2=>namestr );
            END IF;
         END IF;
      END IF;
      IF call_path = 'F' THEN
         email := F_GetEmailAddress(pidm, smbwcrl_row.smbwcrl_stu_email_code);
         IF email IS NOT NULL THEN
            twbkwbis.P_DispInfo('bwlkfcap.P_FacDispCurrent','EMAIL',value1=>email, value2=> student_name );
         END IF;
      END IF;

--      --
--      -- Print Back to View Options
--      twbkfrmt.P_PrintText (
--         twbkfrmt.f_printanchor (
--            curl    => twbkfrmt.f_encodeurl (
--                          twbkwbis.f_cgibin || 'bwckcapp.P_DispEvalViewOption' ||
--                             '?request_no=' ||
--                             twbkfrmt.f_encode (request_no)
--                       ),
--            ctext   => g$_nls.get ('BWCKSML1-0059',
--                          'SQL',
--                          'Back to Display Options'
--                       )
--         )
--      );

--      twbkwbis.p_closedoc (curr_release);

   END P_DispEvalGeneralReq;
   ----------------------------------------------------------------------------
   --
   -- Web Page
   -- This procedure responsible for formating
   -- all of the detail requirement page.
   --

   PROCEDURE P_DispEvalDetailReq(psReclDesc VARCHAR2)

   IS

      button_text            VARCHAR2(20) DEFAULT NULL;
      header                 BOOLEAN  NOT NULL DEFAULT FALSE;
      header2                BOOLEAN  NOT NULL DEFAULT FALSE;
      row_count              BINARY_INTEGER  NOT NULL DEFAULT 0;
      row_count2             BINARY_INTEGER  NOT NULL DEFAULT 0;
      term                   SMBPOGN.SMBPOGN_TERM_CODE_EFF%TYPE;
      email                  GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE;
      namestr                VARCHAR2(90) DEFAULT NULL;
      advr_pidm              SPRIDEN.SPRIDEN_PIDM%TYPE DEFAULT NULL;
      call_path              VARCHAR2(2) DEFAULT NULL;
      dflt_text              STVCPRT.STVCPRT_CODE%TYPE DEFAULT NULL;
      smbarul_addtnl_text    NUMBER DEFAULT 0;
      prog_ip_cred_tot       NUMBER DEFAULT 0;
      prog_unused_cred_tot   NUMBER DEFAULT 0;
      prog_ip_crse_tot       NUMBER DEFAULT 0;
      prog_unused_crse_tot   NUMBER DEFAULT 0;
      curr_eval_term         SMRRQCM.SMRRQCM_TERM_CODE_EVAL%TYPE DEFAULT NULL;
      transfer_header        BOOLEAN NOT NULL DEFAULT FALSE;
      other_crse_header      BOOLEAN NOT NULL DEFAULT FALSE;
      smrdous_area_rule_cnt  NUMBER DEFAULT 0;
      addtnl_rule_text_org   VARCHAR2(32000);
      rule_text_rowspan      NUMBER DEFAULT 0;
      diff_rowspan           NUMBER DEFAULT 0;
      rule_text_processed    BOOLEAN DEFAULT FALSE;
      addtnl_rule_text_exist BOOLEAN DEFAULT FALSE;
      hold_row_count         NUMBER DEFAULT 0;
      smrdous_grp_rule_cnt   NUMBER DEFAULT 0;
      smbgrul_addtnl_text    NUMBER DEFAULT 0;
      open_paren             BOOLEAN DEFAULT FALSE;
      first_req              BOOLEAN DEFAULT TRUE;
      set_sub                VARCHAR2(20) DEFAULT NULL;
      prev_set               SMRACAA.SMRACAA_SET%TYPE DEFAULT NULL;
      prev_sub               SMRACAA.SMRACAA_SUBSET%TYPE DEFAULT NULL;
      call_proc              VARCHAR2(2) DEFAULT NULL;
      hold_term              STVTERM.STVTERM_CODE%TYPE;
      dflt_text_out          STVPRNT.STVPRNT_CODE%TYPE DEFAULT NULL;
      eval_term_out          SMRRQCM.SMRRQCM_TERM_CODE_EVAL%TYPE;
      hold_gpa               SMBAOGN.SMBAOGN_ACT_AREA_GPA%TYPE DEFAULT NULL;
      hold_act_cred          SMBAOGN.SMBAOGN_ACT_CREDITS_OVERALL%TYPE DEFAULT NULL;
      hold_grp_rule_met_ind  SMRGRRQ.SMRGRRQ_MET_IND%TYPE DEFAULT NULL;
      lv_request_no          SMRRQCM.SMRRQCM_REQUEST_NO%TYPE;
      lv_printer_friendly    VARCHAR2(1);
      eval_pidm            NUMBER DEFAULT 0;
      --
      -- Two Var's for RPE # 26520
      --
      dis_sep_txt          BOOLEAN DEFAULT FALSE;

  request_no       INTEGER       := 0;
  printer_Friendly VARCHAR2(2)   := 'N';
  vsNombre         VARCHAR2(300) := NULL;
  vsPrograma       VARCHAR2(20)  := NULL;
  vsTerm           VARCHAR2(6)   := NULL;
  vsExpd           VARCHAR2(10)  := NULL;

   BEGIN
       IF PK_Login.F_ValidacionDeAcceso(PK_Login.vgsUSR) THEN RETURN; END IF;

       --son buscadas los valores de las cookies para asignar los valores del filtro del query.
       vsTerm     := pk_objhtml.getvaluecookie('psPerio');
       vsPrograma := pk_objhtml.getvaluecookie('psProgr');
       vsExpd     := pk_objhtml.getvaluecookie('psExped');


        SELECT COUNT(*) INTO eval_pidm
        FROM SPRIDEN
        WHERE SPRIDEN_ID          = vsExpd
        AND SPRIDEN_CHANGE_IND IS NULL;

        IF eval_pidm > 0 THEN

            SELECT SPRIDEN_PIDM,
            REPLACE(SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME,'*',' ')
            INTO global_pidm,vsNombre
            FROM SPRIDEN
            WHERE SPRIDEN_ID          = vsExpd
            AND SPRIDEN_CHANGE_IND IS NULL;
        END IF;


       call_path   := 'S';
       hold_term   := vsTerm;
       pidm        := global_pidm;

       SELECT MAX(SMRRQCM_REQUEST_NO)
         INTO request_no
         FROM SMRRQCM
        WHERE SMRRQCM_PIDM        = pidm
          AND SMRRQCM_PROCESS_IND = 'N'
          AND SMRRQCM_PROGRAM     = vsPrograma;

       htp.p('<html><head><title>'||psReclDesc||'</title>');

       --muestra las hojas de estilo
       p_CSS;

       htp.p('
       <script type="text/javascript"><!--
       function fImprimeReporte() {
       window.focus()
       print();
       }
       //--></script>

       </head><body><br/>');

       htp.p('
       <table border="0" width="100%">
       <tr><th>'||psReclDesc||'</th></tr>
       <tr><th>'||vsTerm    ||' '||pk_Catalogo.Periodo(vsTerm)||'</th></tr>
       <tr><td>&nbsp;</td></tr>
       <tr><td>'||vsExpd||' '||vsNombre||'</td></tr>
       </table>

       <hr>');

      twbkwbis.P_DispInfo('bwcksmlt.P_DispEvalDetailReq','DEFAULT');
      --
      -- Defect 1-B9N55D
      --
      lv_request_no := request_no;
      lv_printer_friendly := printer_friendly;
      --
      -- Get Program output.
      OPEN SMBPOGN_C(pidm, request_no);
      FETCH SMBPOGN_C INTO smbpogn_row;
      CLOSE SMBPOGN_C;
      --
      -- Get data from rules forms.
      --
      OPEN smbwcrl_c(hold_term);
      FETCH smbwcrl_c INTO smbwcrl_row;
      CLOSE smbwcrl_c;
      --
      -- If using a compliance type to build evaluation output,
      -- get this data now.
      --
      IF smbwcrl_row.smbwcrl_dflt_eval_cprt_code IS NOT NULL THEN
         OPEN smrcprt_c(smbwcrl_row.smbwcrl_dflt_eval_cprt_code);
         FETCH smrcprt_c INTO smrcprt_row;
         CLOSE smrcprt_c;
      END IF;
      --
      -- RPE # 26520. Determine if we should display
      -- the separator bar with text.
      --
      dis_sep_txt := f_display_separator;
      --
      -- End RPE # 26520 initialization.
      --
      term := smbpogn_row.smbpogn_term_code_catlg;
      --
      -- Build the generic program general requirements table.
      --
      P_CommonOutputHeader(call_proc, lv_printer_friendly, eval_term_out);
      --
      -- SSSUI RPE.  Change such that all area's and group's
      -- are their own individual table as opposed to sections
      -- of one, large table.
      --
      -- After we display the program header, start main processing loop
      -- for each area in the program.
      --
      FOR smbaogn_row IN SMBAOGN_C(pidm, request_no) LOOP
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0060',
                                   'SQL',
                                   'This table is used to present area requirements'
                                ) ||
                                '."'
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0061',
                                   'SQL',
                                   'This table is used to present area requirements') ||
                                '."' ||
                                'WIDTH="100%"'
         );
      END IF;
      --
      -- Clear out the text type for each Area/Group processed.
      -- ( Necessary for clearing out rule text )
      --
      dflt_text_out := '';
      hold_gpa   := null;
      hold_act_cred := null;
      --
      -- Format the Area description bar
      --
      -- RPE SSSUI : The number of table columns now based upon whether
      -- data is an area of group.
      --
      IF smbaogn_row.smbaogn_gc_ind = 'G' THEN
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_area,class_in=>'fieldmediumtextbold'));
        twbkfrmt.P_TableDataOpen(ccolspan => '6');
      ELSE
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_area,class_in=>'fieldmediumtextbold'));
        twbkfrmt.P_TableDataOpen(ccolspan => '16');
      END IF;

        p_format_met_bar(smbaogn_row.smbaogn_area,
                         smbaogn_row.smbaogn_req_credits_overall,
                         smbaogn_row.smbaogn_req_courses_overall,
                         smbaogn_row.smbaogn_connector_overall,
                         'A',
                         smbaogn_row.smbaogn_met_ind,
                         'fieldmediumtextbold');

        twbkfrmt.P_TableDataClose;
      twbkfrmt.P_TableRowClose;
      --
      -- Format Area Text bar.
      -- dftl_text_out is the same print code that is used in
      -- the following procedure; where placing as an OUT
      -- variable so we can share same print code with rules text.
      --
      -- RPE SSSUI : Change call to procedure to send in GC_IND.
      -- This will determine how many ccolspan to write the data to.
      --
      p_format_area_detail_text(pidm,
                                smbaogn_row.smbaogn_source_ind,
                                smbaogn_row.smbaogn_area,
                                term,
                                smbaogn_row.smbaogn_met_ind,
                                smbaogn_row.smbaogn_gc_ind,
                                dflt_text_out);
      --
      -- The following section creates the main 'label' section under an area listing.
      -- It will either create a label specific for groups if groups are used in the area,
      -- or it will create a label specific for courses attached to the area.
      -- Remember, if you want to change 'terminology', simply change the package global
      -- varibables ( i.e lbl_prog )
      --
      IF smbaogn_row.smbaogn_gc_ind = 'G' THEN
         twbkfrmt.P_TableRowOpen;
            twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_met,class_in=>'fieldsmallboldtext'));
            twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_cond,class_in=>'fieldsmallboldtext')); -- , calign=>'CENTER');
            twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_dsc,class_in=>'fieldsmallboldtext'), ccolspan=>'1');
            twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_req_cred,class_in=>'fieldsmallboldtext'));
            twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_req_crse,class_in=>'fieldsmallboldtext'));
            -- RPE SSSUI. Add two new labels and data fields
            twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_act_cred,class_in=>'fieldsmallboldtext'));
            twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_act_crse,class_in=>'fieldsmallboldtext'));
         twbkfrmt.P_TableRowClose;
      ELSE
         p_format_detail_title_bar;
      END IF;
     --
     -- This loop lists each group attached to the area UNDER the Area display.
     --
     -- Main processing loop for GROUPS under an Area.
     -- Start out by listing all groups attached to an area.
     --
     IF smbaogn_row.smbaogn_gc_ind = 'G' THEN
        open_paren := FALSE;
        first_req  := TRUE;
        prev_set := '';
        prev_sub := '';
        FOR smbgogn_row IN SMBGOGN_C (pidm, request_no, smbaogn_row.smbaogn_area) LOOP
           set_sub := '';
           decode_set_subset(prev_set, prev_sub, smbgogn_row.smbgogn_set, smbgogn_row.smbgogn_subset,
                             open_paren, first_req, set_sub);
           prev_set := smbgogn_row.smbgogn_set;
           prev_sub := smbgogn_row.smbgogn_subset;
           twbkfrmt.P_TableRowOpen;
           -- RPE 26595.
           -- 80840
           hold_grp_rule_met_ind := null;

           IF smbgogn_row.smbgogn_rule IS NOT NULL THEN
              hold_grp_rule_met_ind := f_get_grp_rule_met_ind(pidm, smbgogn_row.smbgogn_request_no,
                                                              smbgogn_row.smbgogn_area, smbgogn_row.smbgogn_group,
                                                              smbgogn_row.smbgogn_rule, smbgogn_row.smbgogn_term_code_eff);
           END IF;
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(det_conv_color(NVL(hold_grp_rule_met_ind,smbgogn_row.smbgogn_met_ind),
                                                                    smbaogn_row.smbaogn_met_ind),
                                                                    class_in=>'fieldsmalltext'));
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(set_sub,class_in=>'fieldsmalltext'));
           -- twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smbgogn_row.smbgogn_group,class_in=>'fieldsmalltext'),
           -- calign=>'CENTER');
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(get_group_desc(smbgogn_row.smbgogn_group),class_in=>'fieldsmalltext')
           ,ccolspan=>'1');

           IF smbgogn_row.smbgogn_req_credits_overall IS NULL THEN
              twbkfrmt.P_TableDataDead;
           ELSE
              twbkfrmt.P_TableData(twbkfrmt.F_PrintText(TO_CHAR(smbgogn_row.smbgogn_req_credits_overall,
                       '99999999999990D990')||'&nbsp;'
                       ,class_in=>'fieldsmalltext'), calign=>'RIGHT');
           END IF;
           IF smbgogn_row.smbgogn_req_courses_overall IS NULL THEN
              twbkfrmt.P_TableDataDead;
           ELSE
              twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(smbgogn_row.smbgogn_req_courses_overall,'')
              ,class_in=>'fieldsmalltext'), calign=>'RIGHT');
           END IF;
           -- RPE SSSUI. Add two new data displays.
           IF smbgogn_row.smbgogn_act_credits_overall IS NULL THEN
              twbkfrmt.P_TableDataDead;
           ELSE
              twbkfrmt.P_TableData(twbkfrmt.F_PrintText(TO_CHAR(smbgogn_row.smbgogn_act_credits_overall,
                       '99999999999990D990')||'&nbsp;'
                       ,class_in=>'fieldsmalltext'), calign=>'RIGHT');
           END IF;
           IF smbgogn_row.smbgogn_act_courses_overall IS NULL THEN
              twbkfrmt.P_TableDataDead;
           ELSE
              twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(smbgogn_row.smbgogn_act_courses_overall,'')
              ,class_in=>'fieldsmalltext'), calign=>'RIGHT');
           END IF;

        twbkfrmt.P_TableRowClose;
        END LOOP;
        --  Defect# 94483 - ")" text.
        IF open_paren = TRUE THEN
           --set_sub := g$_nls.get('BWCKSML1-0149','SQL',')');--I18N Issue 1-3FA6GU
             set_sub := ')';
           open_paren := FALSE;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataDead;
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(set_sub,class_in=>'fieldsmalltext'));
           twbkfrmt.P_TableRowClose;
        END IF;
        --
        twbkfrmt.p_tableclose;
        --
        -- Now that we listed all groups under an area - put spacer in and
        -- create group output display tables under according area.
        --
        -- RPE # 26520; creation of optional separator bar.
        -- RPE SSSUI. Change RPE 26520 from table to htp display calls.
        IF dis_sep_txt THEN
           htp.br;
        END IF;
        --
        -- This loop creates a GROUP detail output table, just like the AREA detail output display table
        -- for each group attached to the area.
        --
        FOR smbgogn_row IN SMBGOGN_C(pidm, smbaogn_row.smbaogn_request_no, smbaogn_row.smbaogn_area) LOOP
        -- RPE SSSUI. Each Group now it's own table.
        IF printer_friendly = 'Y'
        THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0062',
                                   'SQL',
            'This table is used to present group general requirements') ||
                                '."'
         );
        ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0063',
                                   'SQL',
            'This table is used to present group general requirements') ||
                                '."' ||
                                'WIDTH="100%"'         );
        END IF;
           --
           -- Clear out text type for each group.
           --
           dflt_text_out := '';
           hold_gpa  := null;
           hold_act_cred := null;
           hold_act_cred := smbgogn_row.smbgogn_act_credits_overall;
           -- 80840
           hold_grp_rule_met_ind := null;
           IF smbgogn_row.smbgogn_rule IS NOT NULL THEN
              hold_grp_rule_met_ind := f_get_grp_rule_met_ind(pidm, smbgogn_row.smbgogn_request_no,
                                                              smbgogn_row.smbgogn_area, smbgogn_row.smbgogn_group,
                                                              smbgogn_row.smbgogn_rule, smbgogn_row.smbgogn_term_code_eff);
           END IF;

           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_group,class_in=>'fieldmediumtextbold'));
           twbkfrmt.P_TableDataOpen(ccolspan => '16');

           p_format_met_bar(smbgogn_row.smbgogn_group,
                            smbgogn_row.smbgogn_req_credits_overall,
                            smbgogn_row.smbgogn_req_courses_overall,
                            smbgogn_row.smbgogn_connector_overall,
                            'G',
                            NVL(hold_grp_rule_met_ind,smbgogn_row.smbgogn_met_ind),
                            'fieldmediumtextbold');

           p_format_group_detail_text(pidm,
                                      smbgogn_row.smbgogn_source_ind,
                                      smbgogn_row.smbgogn_group,
                                      term,
                                      smbgogn_row.smbgogn_met_ind,
                                      dflt_text_out);

           p_format_detail_title_bar;
           --
           -- Reset following variables before processing group details.
           --
           open_paren := FALSE;
           first_req  := TRUE;
           prev_set := '';
           prev_sub := '';
           --
           -- Main processing for detail requirements under a group.
           --
           FOR smrdorq_row IN SMRDORQ_GROUP_C (pidm, smbaogn_row.smbaogn_request_no,
                                               smbaogn_row.smbaogn_area, smbgogn_row.smbgogn_group) LOOP
              set_sub := '';
              decode_set_subset(prev_set, prev_sub, smrdorq_row.smrdorq_set, smrdorq_row.smrdorq_subset,
                                open_paren, first_req, set_sub);
              prev_set := smrdorq_row.smrdorq_set;
              prev_sub := smrdorq_row.smrdorq_subset;
              twbkfrmt.P_TableRowOpen;
              -- RPE 26595.
              twbkfrmt.P_TableData(twbkfrmt.F_PrintText(det_conv_color(smrdorq_row.smrdorq_met_ind,
                                                                       smbgogn_row.smbgogn_met_ind)
                                                                       ,class_in=>'fieldsmalltext'));
              twbkfrmt.P_TableData(twbkfrmt.F_PrintText(set_sub,class_in=>'fieldsmalltext'));
              twbkfrmt.P_Tabledata(twbkfrmt.F_PrintText(NVL(smrdorq_row.smrdorq_rule, htf.br),class_in=>'fieldsmalltext'));
              --
              -- Main processing for rules under groups
              --
              -- If detail line is a rule, check for additional text for that
              -- Rule.
              IF smrdorq_row.smrdorq_rule IS NOT NULL THEN
                 --
                 -- Defect 79769
                 --
                 dflt_text_out := '';
                 IF smbwcrl_row.smbwcrl_dflt_eval_prnt_code is NOT NULL THEN
                    dflt_text_out := smbwcrl_row.smbwcrl_dflt_eval_prnt_code;
                 ELSIF smbwcrl_row.smbwcrl_dflt_eval_cprt_code is NOT NULL THEN
                    IF smrdorq_row.smrdorq_met_ind = 'Y' THEN
                       dflt_text_out := smrcprt_row.smrcprt_prnt_code_gccm_met;
                    ELSE
                       dflt_text_out := smrcprt_row.smrcprt_prnt_code_gccm_nmet;
                    END IF;
                 END IF;

                 IF smrdorq_row.smrdorq_source_ind = 'O' THEN
                    smbgrul_addtnl_text := chk_smbgrul_addtnl_text(smrdorq_row.smrdorq_group, smrdorq_row.smrdorq_caa_seqno,
                                                                   smrdorq_row.smrdorq_term_code_eff, dflt_text_out);
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    get_group_key_rule_desc(smrdorq_row.smrdorq_rule, smrdorq_row.smrdorq_group, smrdorq_row.smrdorq_term_code_eff)
                    || '&nbsp;',class_in=>'fieldsmalltext'),ccolspan => '6');
                 ELSE
                    smbgrul_addtnl_text := chk_adj_smbgrul_addtnl_text(pidm, smrdorq_row.smrdorq_group,
                                           smrdorq_row.smrdorq_caa_seqno, smrdorq_row.smrdorq_term_code_eff, dflt_text_out);
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    get_adj_group_key_rule_desc(smrdorq_row.smrdorq_rule, smrdorq_row.smrdorq_group,
                    smrdorq_row.smrdorq_term_code_eff, pidm)||'&nbsp;',class_in=>'fieldsmalltext'),ccolspan => '6');
                 END IF;
                 --
                 -- If the rule has additional text, get text and place in variable.  Determine
                 -- if the number of lines of text are greater than or less than
                 -- the number of courses applied to the requirement.
                 -- This is for formatting reasons for next detail line requirement.
                 --
                 IF smbgrul_addtnl_text > 0 THEN
                    addtnl_rule_text_exist := TRUE;
                    smrdous_grp_rule_cnt   := 0;
                    addtnl_rule_text_org   := '';
                    rule_text_processed    := FALSE;
                    diff_rowspan           := 0;
                    smrdous_grp_rule_cnt   := chk_smrdous_grp_rule_crse_cnt(pidm, smrdorq_row.smrdorq_request_no,
                                              smrdorq_row.smrdorq_area, smrdorq_row.smrdorq_group, smrdorq_row.smrdorq_caa_seqno,
                                              smrdorq_row.smrdorq_rule);
                       IF smbgogn_row.smbgogn_source_ind = 'O' THEN
                       FOR smrgccm_row IN smrgccm_text_c(smrdorq_row.smrdorq_group, smrdorq_row.smrdorq_caa_seqno,
                                                         smrdorq_row.smrdorq_term_code_eff, dflt_text_out) LOOP
                          addtnl_rule_text_org := addtnl_rule_text_org||' '||smrgccm_row.smrgccm_text;
                       END LOOP;
                       ELSE
                       FOR smrsgct_row IN smrsgct_text_c(pidm, smrdorq_row.smrdorq_group, smrdorq_row.smrdorq_caa_seqno,
                                                         smrdorq_row.smrdorq_term_code_eff, dflt_text_out) LOOP
                          addtnl_rule_text_org := addtnl_rule_text_org||' '||smrsgct_row.smrsgct_text;
                       END LOOP;
                       END IF;
                       IF smbgrul_addtnl_text >= smrdous_grp_rule_cnt THEN
                          rule_text_rowspan := smbgrul_addtnl_text;
                          diff_rowspan := smbgrul_addtnl_text - smrdous_area_rule_cnt;
                       ELSE
                          rule_text_rowspan := smrdous_grp_rule_cnt;
                          diff_rowspan := smrdous_grp_rule_cnt - smbgrul_addtnl_text;
                       END IF;
                 END IF;    -- end smbgrul_addtnl_text
              ELSE          -- else if smrdorq_row.smrdorq_rule is not null
                 --
                 -- If rule does not have additional text
                 -- start listing the course used towards requirements on right hand
                 -- side of page.
                 --
                 -- 7.3.3 RPE 6218
                 --
                 IF smrdorq_row.smrdorq_tesc_code IS NOT NULL THEN
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    gb_stvtesc.f_get_description(smrdorq_row.smrdorq_tesc_code),class_in=>'fieldsmalltext'));
                    twbkfrmt.P_TableDataDead;
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    NVL(smrdorq_row.smrdorq_min_value, htf.br),class_in=>'fieldsmalltext'));
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    NVL(smrdorq_row.smrdorq_max_value, htf.br),class_in=>'fieldsmalltext'));
                 ELSE
                    p_decode_subj_link(hold_term,
                                   smrdorq_row.smrdorq_subj_code,
                                   smrdorq_row.smrdorq_crse_numb_low,
                                   smrdorq_row.smrdorq_crse_numb_high,
                                   lv_request_no,
                                   lv_printer_friendly,
                                   smrdorq_row.smrdorq_met_ind,
                                   smbgogn_row.smbgogn_met_ind);

                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    NVL(smrdorq_row.smrdorq_attr_code, htf.br),class_in=>'fieldsmalltext'));
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    NVL(smrdorq_row.smrdorq_crse_numb_low, htf.br),class_in=>'fieldsmalltext'));
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    NVL(smrdorq_row.smrdorq_crse_numb_high, htf.br),class_in=>'fieldsmalltext'));
                 END IF;
                 --
                 -- End RPE 6218
                 --
                 IF smrdorq_row.smrdorq_req_credits IS NULL THEN
                    twbkfrmt.P_TableDataDead;
                 ELSE
                    twbkfrmt.P_TableData(
                       twbkfrmt.F_PrintText(
                          TO_CHAR(smrdorq_row.smrdorq_req_credits,
                          '99999999999990D990'), class_in=>'fieldsmalltext'),
                       calign=>'RIGHT');
                 END IF;
                 IF smrdorq_row.smrdorq_req_courses IS NULL THEN
                    twbkfrmt.P_TableDataDead;
                 ELSE
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    smrdorq_row.smrdorq_req_courses,class_in=>'fieldsmalltext'), calign=>'RIGHT');
                 END IF;
                       --
              END IF;  -- end if smrdorq_row.smrdorq_rule is not null
              --
              -- The above processing was to list the one detail requirement.
              -- The below processing list all elements that were applied
              -- to the one detail requirement.
              --
              FOR smrdous_row_cnt IN SMRDOUS_GROUP_COUNT_C(pidm, smrdorq_row.smrdorq_request_no,
                  smrdorq_row.smrdorq_area, smrdorq_row.smrdorq_group, smrdorq_row.smrdorq_caa_seqno) LOOP
                  IF smrdous_row_cnt.cnt2 > 0 THEN
                     hold_row_count := smrdous_row_cnt.cnt2;
                     row_count2 := 0;
                     FOR smrdous_row IN SMRDOUS_GROUP_C (pidm, smrdorq_row.smrdorq_request_no,
                     smrdorq_row.smrdorq_area, smrdorq_row.smrdorq_group, smrdorq_row.smrdorq_caa_seqno) LOOP
                        IF NOT header2 THEN
                            header2 := TRUE;
                        ELSE
                           --
                           -- If detail requirement was rule with additional text, place
                           -- this text directly under the one detail requirement description.
                           -- Otherwise, space out this block.
                           --
                           IF addtnl_rule_text_exist = TRUE THEN
                              twbkfrmt.P_TableRowOpen;
                                 IF rule_text_processed = FALSE THEN
                                    rule_text_processed := TRUE;
                                    twbkfrmt.P_TableDataDead(ccolspan=>'3',crowspan=>''||smrdous_row_cnt.cnt2 - 1||'');
                                    twbkfrmt.P_TableDataDead(twbkfrmt.F_PrintText(addtnl_rule_text_org,class_in=>'fieldsmalltext'),
                                    ccolspan=>'6', crowspan=>''||smrdous_row_cnt.cnt2 - 1||'');
                                 END IF;
                           ELSE
                              twbkfrmt.P_TableRowOpen;
                              IF row_count2 = 0 THEN
                                 twbkfrmt.P_TableDataDead(ccolspan=>'9', crowspan=>''||smrdous_row_cnt.cnt2 - 1||'');
                                 row_count2 := smrdous_row_cnt.cnt2;
                              END IF;
                           END IF;
                        END IF;  -- end header2
                        --
                        -- This section lists each element that was applied
                        -- to a detail requirement.
                        --
                        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_term_code||'&nbsp;'
                                             ,class_in=>'fieldsmalltext'),'RIGHT');
                        --
                        -- 7.3.3 RPE 6218
                        --
                        /* IF smrdous_row.smrdous_tesc_code IS NOT NULL THEN
                           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_tesc_code,
                           class_in=>'fieldsmalltext'));
                        ELS */
                        IF smrdous_row.smrdous_subj_code IS NULL THEN
                            twbkfrmt.P_TableDataDead;
                        ELSE
                            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_subj_code,
                                                 class_in=>'fieldsmalltext'));
                        END IF;
                        --
                        -- 6218
                        --
                        /* IF smrdous_row.smrdous_test_score IS NOT NULL THEN
                           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_test_score,
                                                                     class_in=>'fieldsmalltext'));
                        ELS */
                        IF smrdous_row.smrdous_crse_numb IS NULL THEN
                            twbkfrmt.P_TableDataDead;
                        ELSE
                            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_crse_numb
                            ,class_in=>'fieldsmalltext'));
                        END IF;
                        --
                        -- 7.3.3 RPE 6218
                        --
                        IF smrdous_row.smrdous_tesc_code IS NOT NULL THEN
                       twbkfrmt.P_TableData(twbkfrmt.F_PrintText(gb_stvtesc.f_get_description(smrdous_row.smrdous_tesc_code)
                       ,class_in=>'fieldsmalltext'));
                        ELSE
                           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_title
                           ,class_in=>'fieldsmalltext'));
                        END IF;
                        --
                        -- 7.3.3 RPE 6218
                        --
                        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_attr_code||
                        '&nbsp;',class_in=>'fieldsmalltext'));
                        IF smrdous_row.smrdous_credit_hours_used IS NULL THEN
                           twbkfrmt.P_TableDataDead;
                        ELSE
                           twbkfrmt.P_TableData(
                              twbkfrmt.F_PrintText(
                               TO_CHAR(smrdous_row.smrdous_credit_hours_used, '99999999999990D990'),
                               class_in=>'fieldsmalltext'),
                              'RIGHT');
                        END IF;

                        IF smrdous_row.smrdous_test_score IS NOT NULL THEN
                           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_test_score,
                                                                     class_in=>'fieldsmalltext'));
                        ELSE
                           /* 7.3.3 1-1GE4WY */
                           IF smrdous_row.smrdous_crse_source <> 'R' THEN
                           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(smrdous_row.smrdous_grde_code,htf.br),
                                                class_in=>'fieldsmalltext'),'CENTER');
                           ELSE
                              twbkfrmt.P_TableDataDead;
                           END IF;
                        END IF;

                        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_crse_source,class_in=>'fieldsmalltext'),
                        'CENTER');
                        twbkfrmt.P_TableRowClose;

                        IF addtnl_rule_text_exist = TRUE THEN
                           smbgrul_addtnl_text := smbgrul_addtnl_text - 1;
                           smrdous_grp_rule_cnt := smrdous_grp_rule_cnt - 1;
                        END IF;
                        IF smrdous_grp_rule_cnt = 0 THEN
                           IF hold_row_count = 1 THEN
                              IF addtnl_rule_text_exist = TRUE THEN
                                 IF rule_text_processed = FALSE THEN
                                    rule_text_processed := TRUE;
                                    twbkfrmt.P_TableRowOpen;
                                    twbkfrmt.P_TableDataDead(ccolspan=>'3',crowspan=>'rule_text_rowspan');
                                    twbkfrmt.P_TableDataDead(twbkfrmt.F_PrintText(addtnl_rule_text_org,class_in=>'fieldsmalltext'),
                                    ccolspan=>'6', crowspan=>'rule_text_rowspan');
                                    twbkfrmt.P_TableDataDead(ccolspan=>'8',crowspan=>'rule_text_rowspan');
                                    twbkfrmt.P_TableRowClose;
                                 ELSE
                                    twbkfrmt.P_TableRowOpen;
                                    twbkfrmt.P_TableDataDead(ccolspan=>'3',crowspan=>'diff_rowspan');
                                    twbkfrmt.P_TableRowClose;
                                 END IF;
                              END IF;
                           END IF;
                        END IF;     -- end smrdous_grp_rule_cnt
                     END LOOP;      -- end SMRDOUS_GROUP_COUNT_C
                  END IF;           -- smrdous_row_cnt.cnt
              END LOOP;             -- end SMRDORQ_GROUP_C

              IF NOT header2 THEN
                 IF addtnl_rule_text_exist = TRUE THEN
                    --
                    -- Special processing regarding rules and additional text .
                    --
                    -- If there are no courses under a rule - and there is addtnl
                    -- rule text, we still need to print the text. This code
                    -- creates the rule additional text block under the description,
                    -- then 'blocks out' the right hand side where courses should be listed.
                    --
                    twbkfrmt.P_TableDataDead(ccolspan=>'8', crowspan=>'rule_text_rowspan');
                    twbkfrmt.P_TableRowClose; -- this closes 'header' row on the right
                    twbkfrmt.P_TableRowOpen;  -- this opens next row.
                    twbkfrmt.P_TableDataDead(ccolspan=>'3', crowspan=>'rule_text_rowspan');
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(addtnl_rule_text_org,class_in=>'fieldsmalltext'),
                    ccolspan=>'6', crowspan=>'rule_text_rowspan');
                    twbkfrmt.P_TableDataDead(ccolspan=>'8', crowspan=>'rule_text_rowspan');
                    twbkfrmt.P_tableRowClose;
                 ELSE
                    twbkfrmt.P_TableDataDead(ccolspan => '8');
                    twbkfrmt.P_TableRowClose;
                 END IF;
              END IF;

              header2 := FALSE;
              addtnl_rule_text_exist := FALSE;
              rule_text_processed := FALSE;
                   --
        END LOOP;  -- end SMBGOGN_C cursor in smbgogn_c loop for each group
        --  Defect# 94483 - ")" text.
        IF open_paren = TRUE THEN
           --set_sub := g$_nls.get('BWCKSML1-0150','SQL',')');--I18N Issue 1-3FA6GU
             set_sub := ')';
           open_paren := FALSE;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataDead;
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(set_sub,class_in=>'fieldsmalltext'));
           twbkfrmt.P_TableRowClose;
        END IF;
        --
        --
        -- Display group total credits.
        --
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataDead(
           twbkfrmt.F_PrintText(
              g$_nls.get ('BWCKSML1-0064','SQL','Total Credits'),
              class_in=>'fieldsmalltext'),
           calign=>'RIGHT',
           ccolspan=>'14');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
        NVL(TO_CHAR(hold_act_cred,'99999999999990D990'),''),
        class_in=>'fieldsmalltext'), calign=>'RIGHT');
        twbkfrmt.P_TableDataDead(ccolspan=>'1');
        twbkfrmt.P_TableDataDead(ccolspan=>'1');
        twbkfrmt.P_TableRowClose;
        --
        -- RPE # 26520
        -- The space bar between groups is now optional/controlable
        -- based upon the twgrinfo value.  IF that value null, no spacer.
        -- RPE SSSUI. Change RPE 26520 from table to htp display calls.
        --
        IF dis_sep_txt THEN
           htp.br;
        END IF;
        twbkfrmt.p_tableclose;
                   --
        END LOOP;  -- End SMBGOGN_C cursor in smbaogn_c loop for each area.
                   -- ( Done processing a group for an area. )
                   --
      ELSE         -- Main Area detail Processing.
                   -- If no groups under an area,
                   -- Do Courses under Area output.
                   --
         open_paren := FALSE;
         first_req  := TRUE;
         set_sub := '';
         prev_set := '';
         prev_sub := '';
         hold_gpa := null;
         hold_act_cred := null;
         hold_gpa := smbaogn_row.smbaogn_act_area_gpa;
         hold_act_cred := smbaogn_row.smbaogn_act_credits_overall;
         --
         -- Main processing for detail requirements under an Area.
         --
         FOR smrdorq_row IN SMRDORQ_C (pidm, request_no, smbaogn_row.smbaogn_area) LOOP
            set_sub := '';
            decode_set_subset(prev_set, prev_sub, smrdorq_row.smrdorq_set, smrdorq_row.smrdorq_subset,
                              open_paren, first_req, set_sub);
            prev_set := smrdorq_row.smrdorq_set;
            prev_sub := smrdorq_row.smrdorq_subset;
            twbkfrmt.P_TableRowOpen;
            -- RPE 26595.
             twbkfrmt.P_TableData(twbkfrmt.F_PrintText(det_conv_color(smrdorq_row.smrdorq_met_ind,
                                                                      smbaogn_row.smbaogn_met_ind)
                                                                      ,class_in=>'fieldsmalltext'));
            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(set_sub,class_in=>'fieldsmalltext'));
            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(smrdorq_row.smrdorq_rule, htf.br),class_in=>'fieldsmalltext'));
            --
            -- Main processing for rules under Areas
            --
            -- If detail line is a rule, check for additional text for that
            -- Rule.
            --
            IF smrdorq_row.smrdorq_rule IS NOT NULL THEN
                 --
                 -- Defect 79769
                 --
                 dflt_text_out := '';
                 IF smbwcrl_row.smbwcrl_dflt_eval_prnt_code is NOT NULL THEN
                    dflt_text_out := smbwcrl_row.smbwcrl_dflt_eval_prnt_code;
                 ELSIF smbwcrl_row.smbwcrl_dflt_eval_cprt_code is NOT NULL THEN
                    IF smrdorq_row.smrdorq_met_ind = 'Y' THEN
                       dflt_text_out := smrcprt_row.smrcprt_prnt_code_accm_met;
                    ELSE
                       dflt_text_out := smrcprt_row.smrcprt_prnt_code_accm_nmet;
                    END IF;
                 END IF;

               IF smrdorq_row.smrdorq_source_ind = 'O' THEN
                  smbarul_addtnl_text := chk_smbarul_addtnl_text(smrdorq_row.smrdorq_area,
                  smrdorq_row.smrdorq_caa_seqno,smrdorq_row.smrdorq_term_code_eff, dflt_text_out);
                  twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                  get_area_key_rule_desc(smrdorq_row.smrdorq_rule, smrdorq_row.smrdorq_area,
                  smrdorq_row.smrdorq_term_code_eff)
                  || '&nbsp;',class_in=>'fieldsmalltext'),ccolspan => '6');
               ELSE
                  smbarul_addtnl_text := chk_adj_smbarul_addtnl_text(pidm, smrdorq_row.smrdorq_area,
                  smrdorq_row.smrdorq_caa_seqno,smrdorq_row.smrdorq_term_code_eff, dflt_text_out);
                  twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                  get_adj_area_key_rule_desc(smrdorq_row.smrdorq_rule, smrdorq_row.smrdorq_area,
                  smrdorq_row.smrdorq_term_code_eff, pidm) || '&nbsp;',class_in=>'fieldsmalltext'),ccolspan => '6');
               END IF;
                  --
                  -- If the rule has additional text, get text and place in variable.  Determine
                  -- if the number of lines of text are greater than or less than
                  -- the number of courses applied to the requirement.
                  -- This is for formatting reasons for next detail line requirement.
                  --
                  IF smbarul_addtnl_text > 0 THEN
                     addtnl_rule_text_exist := TRUE;
                     smrdous_area_rule_cnt := 0;
                     addtnl_rule_text_org := '';
                     rule_text_processed := FALSE;
                     diff_rowspan := 0;
                     IF smbaogn_row.smbaogn_source_ind = 'O' THEN
                        smrdous_area_rule_cnt := chk_smrdous_area_rule_crse_cnt(pidm, smrdorq_row.smrdorq_request_no,
                        smrdorq_row.smrdorq_area, smrdorq_row.smrdorq_caa_seqno, smrdorq_row.smrdorq_rule);
                           FOR smraccm_row IN smraccm_text_c(smrdorq_row.smrdorq_area, smrdorq_row.smrdorq_caa_seqno,
                                                         smrdorq_row.smrdorq_term_code_eff, dflt_text_out)  LOOP
                              addtnl_rule_text_org := addtnl_rule_text_org||' '||smraccm_row.smraccm_text;
                           END LOOP;
                     ELSE
                        smrdous_area_rule_cnt := chk_smrdous_area_rule_crse_cnt(pidm, smrdorq_row.smrdorq_request_no,
                        smrdorq_row.smrdorq_area, smrdorq_row.smrdorq_caa_seqno, smrdorq_row.smrdorq_rule);
                           FOR smrsact_row IN smrsact_text_c(pidm, smrdorq_row.smrdorq_area, smrdorq_row.smrdorq_caa_seqno,
                              smrdorq_row.smrdorq_term_code_eff, dflt_text_out) LOOP
                              addtnl_rule_text_org := addtnl_rule_text_org||' '||smrsact_row.smrsact_text;
                           END LOOP;
                     END IF;
                     IF smbarul_addtnl_text >= smrdous_area_rule_cnt THEN
                        rule_text_rowspan := smbarul_addtnl_text;
                        diff_rowspan := smbarul_addtnl_text - smrdous_area_rule_cnt;
                     ELSE
                        rule_text_rowspan := smrdous_area_rule_cnt;
                        diff_rowspan := smrdous_area_rule_cnt - smbarul_addtnl_text;
                     END IF;
                           --
                  END IF;  -- end smbarul_addtnl_text
             ELSE          -- else if requirement NOT a rule
                           --
                --
                -- If rule does not have additional text
                -- start listing the course used towards requirements on right hand
                -- side of page.
                --
                -- 7.3.3 RPE 6218
                --
                IF smrdorq_row.smrdorq_tesc_code IS NOT NULL THEN
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    gb_stvtesc.f_get_description(smrdorq_row.smrdorq_tesc_code),class_in=>'fieldsmalltext'));
                    twbkfrmt.P_TableDataDead;
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    NVL(smrdorq_row.smrdorq_min_value, htf.br),class_in=>'fieldsmalltext'));
                    twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                    NVL(smrdorq_row.smrdorq_max_value, htf.br),class_in=>'fieldsmalltext'));
                ELSE
                   p_decode_subj_link(hold_term,
                                   smrdorq_row.smrdorq_subj_code,
                                   smrdorq_row.smrdorq_crse_numb_low,
                                   smrdorq_row.smrdorq_crse_numb_high,
                                   lv_request_no,
                                   lv_printer_friendly,
                                   smrdorq_row.smrdorq_met_ind,
                                   smbaogn_row.smbaogn_met_ind);

                   twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                   NVL(smrdorq_row.smrdorq_attr_code, htf.br),class_in=>'fieldsmalltext'));
                   twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                   NVL(smrdorq_row.smrdorq_crse_numb_low, htf.br),class_in=>'fieldsmalltext'));
                   twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                   NVL(smrdorq_row.smrdorq_crse_numb_high, htf.br),class_in=>'fieldsmalltext'));
                END IF;
                --
                -- 7.3.3 RPE 6218
                --
                IF smrdorq_row.smrdorq_req_credits IS NULL THEN
                   twbkfrmt.P_TableDataDead;
                ELSE
                   twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                   TO_CHAR(smrdorq_row.smrdorq_req_credits,
                   '99999999999990D990'), class_in=>'fieldsmalltext'),
                   'RIGHT');
                END IF;
                IF smrdorq_row.smrdorq_req_courses IS NULL THEN
                   twbkfrmt.P_TableDataDead;
                ELSE
                   twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                   smrdorq_row.smrdorq_req_courses,class_in=>'fieldsmalltext'), 'RIGHT');
                END IF;
             END IF;
             --
             -- The above processing was to list the one detail requirement.
             -- The below processing list all elements that were applied
             -- to the one detail requirement.
             --
             FOR smrdous_row_cnt IN SMRDOUS_COUNT_C (pidm, smrdorq_row.smrdorq_request_no,
                                                     smrdorq_row.smrdorq_area,
                                                     smrdorq_row.smrdorq_caa_seqno) LOOP
                IF smrdous_row_cnt.cnt > 0 THEN
                   hold_row_count := smrdous_row_cnt.cnt;
                   row_count := 0;
                   FOR smrdous_row IN SMRDOUS_C (pidm, smrdorq_row.smrdorq_request_no,
                                                 smrdorq_row.smrdorq_area,
                                                 smrdorq_row.smrdorq_caa_seqno) LOOP
                      IF NOT header THEN
                         header := TRUE;
                      ELSE
                         --
                         -- If detail requirement was rule with additional text, place
                         -- this text directly under the one detail requirement description.
                         -- Otherwise, space out this block.
                         --
                         IF addtnl_rule_text_exist = TRUE THEN
                            twbkfrmt.P_TableRowOpen;
                            IF rule_text_processed = FALSE THEN
                               rule_text_processed := TRUE;
                               twbkfrmt.P_TableRowOpen;
                               twbkfrmt.P_TableDataDead(ccolspan=>'3',crowspan=>''||smrdous_row_cnt.cnt - 1||'');
                               twbkfrmt.P_TableDataDead(twbkfrmt.F_PrintText(addtnl_rule_text_org,class_in=>'fieldsmalltext'),
                               ccolspan=>'6', crowspan=>''||smrdous_row_cnt.cnt - 1||'');
                            END IF;
                         ELSE
                             -- if no additional rule text, then space out left hand side.
                             -- set rowcount to ZERO so we don' process this path again.
                             twbkfrmt.P_TableRowOpen;
                             IF row_count = 0 THEN
                                twbkfrmt.P_TableDataDead(ccolspan => '9', crowspan => ''||smrdous_row_cnt.cnt - 1||'');
                                row_count := smrdous_row_cnt.cnt;
                             END IF;
                         END IF;
                      END IF;     -- end if not header
                      --
                      -- This section lists each element that was applied
                      -- to a detail requirement.
                      --
                      twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_term_code||
                      '&nbsp;',class_in=>'fieldsmalltext'), calign=>'RIGHT',crowspan=>'1');
                      --
                      -- 7.3.3 RPE6218
                      --
                      IF smrdous_row.smrdous_tesc_code IS NOT NULL THEN
                        /*
                        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_tesc_code || '&nbsp;'
                        ,class_in=>'fieldsmalltext'), crowspan=>'1');
                        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_test_score || '&nbsp;'
                        ,class_in=>'fieldsmalltext'), crowspan=>'1');
                        */
                        twbkfrmt.P_TableDataDead;
                        twbkfrmt.P_TableDataDead;
                     twbkfrmt.P_TableData(twbkfrmt.F_PrintText(gb_stvtesc.f_get_description(smrdous_row.smrdous_tesc_code),
                        class_in=>'fieldsmalltext'),
                        crowspan=>'1');
                      ELSE
                         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_subj_code|| '&nbsp;'
                         ,class_in=>'fieldsmalltext'), crowspan=>'1');
                         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_crse_numb|| '&nbsp;'
                         ,class_in=>'fieldsmalltext'), crowspan=>'1');
                         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_title,class_in=>'fieldsmalltext'),
                         crowspan=>'1');
                      END IF;

                      twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_attr_code||'&nbsp;',class_in=>'fieldsmalltext'),
                      crowspan=>'1');
                      twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(smrdous_row.smrdous_credit_hours_used, '99999999999990D990'),'')
                      ,class_in=>'fieldsmalltext'), calign=>'RIGHT', crowspan=>'1');

                      IF smrdous_row.smrdous_tesc_code IS NOT NULL THEN
                        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_test_score || '&nbsp;'
                        ,class_in=>'fieldsmalltext'), crowspan=>'1');
                      ELSE
                           /* 7.3.3 1-1GE4WY */
                           IF smrdous_row.smrdous_crse_source <> 'R' THEN
                           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(smrdous_row.smrdous_grde_code,htf.br),
                                                class_in=>'fieldsmalltext'),'CENTER');
                           ELSE
                              twbkfrmt.P_TableDataDead;
                           END IF;
                      END IF;

                      twbkfrmt.P_TableData(twbkfrmt.F_PrintText(smrdous_row.smrdous_crse_source,class_in=>'fieldsmalltext'),
                      calign=>'CENTER',crowspan=>'1');
                      twbkfrmt.P_TableRowClose;

                      IF addtnl_rule_text_exist = TRUE THEN
                         smbarul_addtnl_text := smbarul_addtnl_text - 1;
                         smrdous_area_rule_cnt := smrdous_area_rule_cnt - 1;
                      END IF;
                      IF smrdous_area_rule_cnt = 0 THEN
                         IF hold_row_count = 1 THEN
                            IF addtnl_rule_text_exist = TRUE THEN
                               IF rule_text_processed = FALSE THEN
                                  rule_text_processed := TRUE;
                                  twbkfrmt.P_TableRowOpen;
                                  twbkfrmt.P_TableDataDead(ccolspan=>'3',crowspan=>'rule_text_rowspan');
                                  twbkfrmt.P_TableDataDead(twbkfrmt.F_PrintText(addtnl_rule_text_org,class_in=>'fieldsmalltext'),
                                  ccolspan=>'6', crowspan=>'rule_text_rowspan');
                                  twbkfrmt.P_TableDataDead(ccolspan=>'8',crowspan=>'rule_text_rowspan');
                                  twbkfrmt.P_TableRowClose;
                               ELSE
                                  twbkfrmt.P_TableRowOpen;
                                  twbkfrmt.P_TableDataDead(ccolspan=>'3',crowspan=>'diff_rowspan');
                                  twbkfrmt.P_TableRowClose;
                               END IF;
                            END IF;
                         END IF;
                      END IF;

                   END LOOP;  -- smrdous_c loop
                END IF;       -- smrdous_row_cnt.cnt
             END LOOP;        -- smrdous_count_c

             IF NOT header THEN
                IF addtnl_rule_text_exist = TRUE THEN
                   --
                   -- Special processing regarding rules and additional text .
                   --
                   -- If there are no courses under a rule - and there is addtnl
                   -- rule text, we still need to print the text. This code
                   -- creates the rule additional text block under the description,
                   -- then 'blocks out' the right hand side where courses should be listed.
                   --
                   twbkfrmt.P_TableDataDead(ccolspan=>'8', crowspan=>'rule_text_rowspan');
                   twbkfrmt.P_TableRowClose; -- this closes 'header' row on the right
                   twbkfrmt.P_TableRowOpen;  -- this opens next row.
                   twbkfrmt.P_TableDataDead(ccolspan=>'3', crowspan=>'rule_text_rowspan');
                   twbkfrmt.P_TableData(twbkfrmt.F_PrintText(addtnl_rule_text_org,class_in=>'fieldsmalltext'),
                   ccolspan=>'6', crowspan=>'rule_text_rowspan');
                   twbkfrmt.P_TableDataDead(ccolspan=>'8', crowspan=>'rule_text_rowspan');
                   twbkfrmt.P_tableRowClose;
                ELSE
                   twbkfrmt.P_TableDataDead(ccolspan => '8');
                   twbkfrmt.P_TableRowClose;
                END IF;
             END IF;

             header := FALSE;
             addtnl_rule_text_exist := FALSE;
             rule_text_processed := FALSE;
             hold_row_count := 0;

          END LOOP;  -- smrdorq
        --  Defect# 94483 - ")" text.
        IF open_paren = TRUE THEN
           --set_sub := g$_nls.get('BWCKSML1-0151','SQL',')');--I18N Issue 1-3FA6GU
             set_sub := ')';
           open_paren := FALSE;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataDead;
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(set_sub,class_in=>'fieldsmalltext'));
           twbkfrmt.P_TableRowClose;
        END IF;
        --

        --
        -- Display Area total credits and GPA.
        --
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataDead(
           twbkfrmt.F_PrintText(
              g$_nls.get ('BWCKSML1-0065','SQL','Total Credits and ') ||
              '<ACRONYM title = "' ||
               g$_nls.get ('BWCKSML1-0066','SQL','Grade Point Average') ||
               '">' ||
               g$_nls.get('BWCKSML1-0067', 'SQL',' GPA ')||
               '</ACRONYM>',
              class_in=>'fieldsmalltext'),
           calign=>'RIGHT',
           ccolspan=>'14');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                                NVL(TO_CHAR(hold_act_cred, '99999999999990D990'),''),
                                class_in=>'fieldsmalltext'),
                             calign=>'RIGHT');
        shkcgpa.p_get_student_formats (
           pidm,
           levl_used,
           camp_used,
           term_used,
           round_truncate_gpa,
           display_gpa_digits,
           round_truncate_points,
           display_points_digits
        );
        shkcgpa.p_make_disp_web_format(hold_gpa,
                                       hold_gpa,
                                       sig_format_mask);
        shkcgpa.p_trunc_or_round (
           display_gpa_digits,
           round_truncate_gpa,
           hold_gpa,
           hold_gpa
        );

        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                                NVL(TO_CHAR(hold_gpa,
        sig_format_mask),''), class_in=>'fieldsmalltext'),
                             calign=>'RIGHT');
        twbkfrmt.P_TableDataDead(ccolspan=>'1');
        twbkfrmt.P_TableRowClose;

       END IF;    -- end area or group condition
       --
       -- RPE # 26520
       -- RPE SSSUI. Add tableclose. Change RPE 26520 from table to htp display calls.
       --
       twbkfrmt.p_tableclose;
       IF dis_sep_txt THEN
          htp.br;
          htp.prn(twbkwbis.F_DispInfo('bwcksmlt.P_DispEvalDetailReq','SPACER'));
          htp.br;
       END IF;
       -- End RPE # 26520
              --
    END LOOP; --(aogn) Areas loop.  Done processing area.
    --
    -- Following code responsible for creation of email link/name
    --
    IF call_path = 'S' THEN
       advr_pidm := F_GetAdvrPidm(pidm, hold_term);
       email := F_GetEmailAddress(advr_pidm, smbwcrl_row.smbwcrl_fac_email_code);
       IF email IS NOT NULL THEN
          namestr := F_GetEmailNamestr(advr_pidm);
          IF namestr IS NOT NULL THEN
             twbkwbis.P_DispInfo('bwcksmlt.P_DispEvalDetailReq','EMAIL',value1=>email, value2=>namestr );
          END IF;
       END IF;
    END IF;
    IF call_path = 'F' THEN
       email := F_GetEmailAddress(pidm, smbwcrl_row.smbwcrl_stu_email_code);
       IF email IS NOT NULL THEN
          twbkwbis.P_DispInfo('bwlkfcap.P_FacDispCurrent','EMAIL',value1=>email, value2=> student_name );
       END IF;
    END IF;
--      --
--      -- Print Back to View Options
--      --
--      twbkfrmt.P_PrintText (
--         twbkfrmt.f_printanchor (
--            curl    => twbkfrmt.f_encodeurl (
--                          twbkwbis.f_cgibin || 'bwckcapp.P_DispEvalViewOption' ||
--                             '?request_no=' ||
--                             twbkfrmt.f_encode (request_no)
--                       ),
--            ctext   => g$_nls.get ('BWCKSML1-0068',
--                          'SQL',
--                          'Back to Display Options'
--                       )
--         )
--      );

--    twbkwbis.p_closedoc (curr_release);

   END P_DispEvalDetailReq;

   ----------------------------------------------------------------------------
   --
   -- This procedure is responsible for formating the area output
   -- table under the P_DispEvalGeneralReq procedure.
   --
  PROCEDURE P_GenReqOutput(pidm IN spriden.spriden_pidm%TYPE,
                            request_no IN smrrqcm.smrrqcm_request_no%TYPE,
                            term IN stvterm.stvterm_code%TYPE)
   IS

     smbaogn_row             smbaogn%rowtype;
     next_area               smbaogn.smbaogn_area%TYPE;
     next_area_source        smbaogn.smbaogn_source_ind%TYPE;
     next_area_gpa           smbaogn.smbaogn_act_area_gpa%TYPE;
     next_area_credits       smbaogn.smbaogn_act_credits_overall%TYPE;
     next_area_overall_crd   smbaogn.smbaogn_req_credits_overall%TYPE;
     next_area_overall_crs   smbaogn.smbaogn_req_courses_overall%TYPE;
     next_area_connector     smbaogn.smbaogn_connector_overall%TYPE;
     next_area_met_ind       smbaogn.smbaogn_met_ind%TYPE;
     dflt_text               stvcprt.stvcprt_code%TYPE;
     area_text               VARCHAR2(32000) DEFAULT NULL;
     area_courses            VARCHAR2(32000) DEFAULT NULL;
     /* 7.3.3 1-1GE4WY add new lv_grde_code variable. */
     lv_grde_code            smrdous.smrdous_grde_code%TYPE;

     table_counter           NUMBER(4) DEFAULT 0;
     total_records           NUMBER(4) DEFAULT 0;
     next_row                NUMBER(4) DEFAULT 0;

     TYPE smbaogn_results_type IS TABLE OF smbaogn%ROWTYPE
        INDEX BY BINARY_INTEGER;

     smbaogn_table           smbaogn_results_type;


   BEGIN
   --
   -- For the particular format of the page, the logic is
   -- such that two 'areas' are processed for each
   -- loop in a cursor loop.
   --
   -- Defect 80881. Previously, the logic used the
   -- smbaogn_c cursor ( same as detail page ) - but
   -- determined the 'next' or right hand display
   -- based off functions ( f_get_next_area_% )
   -- based off the existing(current) area ( priority , area_name) -
   -- The problem was that multiple areas can share the
   -- area priority - thus corrupting the output display.
   --
   -- To correct the problem, a pl/sql table was created
   -- ( smbaogn_table_type ) - and the table was populated
   -- with the same order/cursor as before.  This time,
   -- the binary_integer index on the table is used
   -- to determine the right hand or 'NEXT' area to
   -- to display based upon the current record.
   -- ( table_name.NEXT(table_index) and table_name.EXISTS(table_index)
   -- used for logic/display. )
   --
   -- Example.
   -- FOR INDEX IN all_areas_in_program_cursor LOOP ...
   -- Page Format
   -- /* ************************************************************ */
   -- /*                           *                                  */
   -- /* table_name(I).field_name  * table_name.(NEXT_ROW).field_name */
   -- /*                           *                                  */
   -- /* ************************************************************ */
   --
   -- The left hand column equates to information
   -- retrieved based upon the current cursor for_loop index.
   -- The right hand side column data is retrieved
   -- by the PL/SQL table function table_name.NEXT attribute.
   --

      OPEN smbaogn_c(pidm, request_no);
      LOOP
         EXIT WHEN smbaogn_c%NOTFOUND;
         table_counter := table_counter + 1;
         FETCH smbaogn_c INTO smbaogn_table(table_counter);
      END LOOP;
      CLOSE smbaogn_c;

      total_records := smbaogn_table.count;

      FOR I in 1 .. NVL(smbaogn_table.LAST,0)
      LOOP

      IF I = next_row THEN
         NULL;
      ELSE
         --
         -- The left hand display should process odd indices (1,3,5,etc)
         -- The even indices are displayed by the table.NEXT feature.
         -- If the indice (above ) is EVEN, then skip that loop.
         --
         next_row := smbaogn_table.NEXT(I);
         IF smbaogn_table.EXISTS(next_row) THEN
            next_area := smbaogn_table(next_row).smbaogn_area;
         END IF;
         --
         -- Open up the left column row, initialize the settings, the
         -- place data with procedure p_format_met_bar
         --
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_area,class_in=>'fieldsmallboldtext'),
         ccolspan=>'1');
--
--          twbkfrmt.P_TableDataOpen(ccolspan=>'8');
--
         twbkfrmt.P_TableDataOpen(ccolspan=>'1');

         p_format_met_bar(smbaogn_table(I).smbaogn_area,
                          smbaogn_table(I).smbaogn_req_credits_overall,
                          smbaogn_table(I).smbaogn_req_courses_overall,
                          smbaogn_table(I).smbaogn_connector_overall,
                          'A',
                          smbaogn_table(I).smbaogn_met_ind,
                          'fieldsmallboldtext');
         twbkfrmt.P_TableDataClose;

         IF NOT smbaogn_table.EXISTS(next_row) THEN
            twbkfrmt.P_TableDataDead(ccolspan=>'2', crowspan=>'4');
--
--            twbkfrmt.P_TableDataDead(ccolspan=>'8', crowspan=>'4');
--
            --
            -- This is the 'empty block' spacer that should be located
            -- at the bottom right hand side of the page if there is
            -- and odd number of areas attached to program.
            --
            -- crowspan of '4' will 'grow' to size of left hand side
            -- of course listings.
            --
         ELSE
            --
            -- Right Column set up.
            --
            next_area_overall_crd := smbaogn_table(next_row).smbaogn_req_credits_overall;
            next_area_overall_crs := smbaogn_table(next_row).smbaogn_req_courses_overall;
            next_area_connector   := smbaogn_table(next_row).smbaogn_connector_overall;
            next_area_met_ind     := smbaogn_table(next_row).smbaogn_met_ind;

            twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_area,class_in=>'fieldsmallboldtext'));
            twbkfrmt.P_TableDataOpen(ccolspan=>'1');
--
--            twbkfrmt.P_TableDataOpen(ccolspan=>'7');
--

            p_format_met_bar(smbaogn_table(next_row).smbaogn_area,
                             smbaogn_table(next_row).smbaogn_req_credits_overall,
                             smbaogn_table(next_row).smbaogn_req_courses_overall,
                             smbaogn_table(next_row).smbaogn_connector_overall,
                             'A',
                             smbaogn_table(next_row).smbaogn_met_ind,
                             'fieldsmallboldtext');

            twbkfrmt.P_TableDataClose;
         END IF;  -- end next_area is null

      twbkfrmt.P_TableRowClose;

      -- -------------------------------------------------
      -- Text.  This section is responsible for retrieving
      -- the area text.
      -- -------------------------------------------------

      twbkfrmt.P_TableRowOpen;
        --
        -- Get dflt_text type.
        IF smbwcrl_row.smbwcrl_dflt_eval_prnt_code is NOT NULL THEN
           dflt_text := smbwcrl_row.smbwcrl_dflt_eval_prnt_code;
        ELSIF smbwcrl_row.smbwcrl_dflt_eval_cprt_code is NOT NULL THEN
           IF smbaogn_table(I).smbaogn_met_ind = 'Y' THEN
              dflt_text := smrcprt_row.smrcprt_prnt_code_acmt_met;
           ELSE
              dflt_text := smrcprt_row.smrcprt_prnt_code_acmt_nmet;
           END IF;
        END IF;

        area_text := F_GenOutputAreaText(pidm,smbaogn_table(I).smbaogn_area,
                                         smbaogn_table(I).smbaogn_source_ind, term, dflt_text);

        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_text|| '&nbsp;',class_in=>'fieldsmalltext'),
        ccolspan=>'2');
--
--        ccolspan=>'8');
--
-- ???        twbkfrmt.P_TableData('&nbsp;',ccolspan=>'1');

        area_text := '';

        IF smbaogn_table.EXISTS(next_row) THEN
           IF smbwcrl_row.smbwcrl_dflt_eval_prnt_code is NOT NULL THEN
              dflt_text := smbwcrl_row.smbwcrl_dflt_eval_prnt_code;
           ELSIF smbwcrl_row.smbwcrl_dflt_eval_cprt_code is NOT NULL THEN
              IF smbaogn_table(next_row).smbaogn_met_ind = 'Y' THEN
                 dflt_text := smrcprt_row.smrcprt_prnt_code_acmt_met;
              ELSE
                 dflt_text := smrcprt_row.smrcprt_prnt_code_acmt_nmet;
              END IF;
           END IF;

          area_text := F_GenOutputAreaText(pidm, smbaogn_table(next_row).smbaogn_area,
                                           smbaogn_table(next_row).smbaogn_source_ind,
                                           term, dflt_text);


          twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_text||'&nbsp;',
          class_in=>'fieldsmalltext'),ccolspan=>'2');
--
--          class_in=>'fieldsmalltext'),ccolspan=>'8');
--
        END IF;
      twbkfrmt.P_TableRowClose;

      -- -------------------------------------------------
      -- Details.  This Section is responsible for listing all courses
      -- used in a particuluar area.
      -- -------------------------------------------------

      twbkfrmt.P_TableRowOpen;
      area_courses := '';
         FOR smrdous_row in SMRDOUS_ALL_C(pidm, smbaogn_table(I).smbaogn_request_no, smbaogn_table(I).smbaogn_area) LOOP
            lv_grde_code := NULL;
            IF smrdous_row.smrdous_tesc_code IS NULL THEN
              /* 1-1GE4WY */
              IF smrdous_row.smrdous_crse_source = 'R' THEN
                 lv_grde_code := NULL;
              ELSE
                 lv_grde_code := smrdous_row.smrdous_grde_code;
              END IF;
              area_courses :=  area_courses||'&nbsp;'||
                               TO_CHAR(smrdous_row.smrdous_credit_hours, '99999999999990D990')|| '&nbsp;' ||
                               NVL(lv_grde_code, ' * ')|| '&nbsp;' ||
                               smrdous_row.smrdous_term_code|| '  -   '||
                               smrdous_row.smrdous_subj_code|| '    '||
                               smrdous_row.smrdous_crse_numb|| '  '||
                               smrdous_row.smrdous_title|| htf.br;
            ELSE
              area_courses :=  area_courses ||'&nbsp;&nbsp;'||
                               gb_stvtesc.f_get_description(smrdous_row.smrdous_tesc_code) || '    '||
                               smrdous_row.smrdous_test_score || '  ' || htf.br;
            END IF;
         END LOOP;
      twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_courses||'&nbsp;',class_in=>'fieldsmalltext'), ccolspan=>'2');
--
-- twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_courses||'&nbsp;',class_in=>'fieldsmalltext'), ccolspan=>'9');
--

      area_courses := '';
       IF smbaogn_table.EXISTS(next_row) THEN
         FOR smrdous_row in SMRDOUS_ALL_C(pidm, smbaogn_table(next_row).smbaogn_request_no, smbaogn_table(next_row).smbaogn_area)
         LOOP
            lv_grde_code := NULL;
            IF smrdous_row.smrdous_tesc_code IS NULL THEN
              /* 1-1GE4WY */
              IF smrdous_row.smrdous_crse_source = 'R' THEN
                 lv_grde_code := NULL;
              ELSE
                 lv_grde_code := smrdous_row.smrdous_grde_code;
              END IF;
              area_courses :=  area_courses||'&nbsp;'||
                               TO_CHAR(smrdous_row.smrdous_credit_hours, '99999999999990D990')|| '&nbsp;' ||
                               NVL(lv_grde_code, ' * ')||'&nbsp;' ||
                               smrdous_row.smrdous_term_code|| '  -   '||
                               smrdous_row.smrdous_subj_code|| '    '||
                               smrdous_row.smrdous_crse_numb|| '  '||
                               smrdous_row.smrdous_title|| htf.br;
            ELSE
              area_courses :=  area_courses ||'&nbsp;&nbsp;'||
                               gb_stvtesc.f_get_description(smrdous_row.smrdous_tesc_code) || '    '||
                               smrdous_row.smrdous_test_score || '  ' || htf.br;
            END IF;
         END LOOP;
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_courses||'&nbsp;',class_in=>'fieldsmalltext'), ccolspan=>'2');
--
-- twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_courses||'&nbsp;',class_in=>'fieldsmalltext'), ccolspan=>'8');
--
      END IF;

      twbkfrmt.P_TableRowClose;

      -- -------------------------------------------------
      -- Footer information for Area listing (GPA & Credits)
      -- -------------------------------------------------

      twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(smbaogn_table(I).smbaogn_act_credits_overall,'99999999999990D990'),'') ||
                                                       g$_nls.get('BWCKSML1-0069', 'SQL',' Credits '),
                                                       class_in=>'fieldsmalltext'),ccolspan=>'1');
         shkcgpa.p_get_student_formats (
            pidm,
            levl_used,
            camp_used,
            term_used,
            round_truncate_gpa,
            display_gpa_digits,
            round_truncate_points,
            display_points_digits
         );
         shkcgpa.p_make_disp_web_format(smbaogn_table(I).smbaogn_act_area_gpa,
                                        smbaogn_table(I).smbaogn_act_area_gpa,
                                        sig_format_mask);
         shkcgpa.p_trunc_or_round (
            display_gpa_digits,
            round_truncate_gpa,
            smbaogn_table(I).smbaogn_act_area_gpa,
            smbaogn_table(I).smbaogn_act_area_gpa
         );

         twbkfrmt.P_TableData(
            twbkfrmt.F_PrintText(

NVL(TO_CHAR(smbaogn_table(I).smbaogn_act_area_gpa,
            sig_format_mask ) , '') || '<ACRONYM title = "' ||
               g$_nls.get ('BWCKSML1-0070','SQL','Grade Point Average') ||
               '">' ||
               g$_nls.get('BWCKSML1-0071', 'SQL',' GPA ')||
               '</ACRONYM>',
               class_in=>'fieldsmalltext'),
            ccolspan=>'1');
--
--         twbkfrmt.P_TableDataSeparator(ccolspan=>'7');
--

         IF smbaogn_table.EXISTS(next_row) THEN
             shkcgpa.p_get_student_formats (
                pidm,
                levl_used,
                camp_used,
                term_used,
                round_truncate_gpa,
                display_gpa_digits,
                round_truncate_points,
                display_points_digits
             );
             shkcgpa.p_make_disp_web_format(smbaogn_table(next_row).smbaogn_act_area_gpa,
                                            smbaogn_table(next_row).smbaogn_act_area_gpa,
                                            sig_format_mask);
             shkcgpa.p_trunc_or_round (
                display_gpa_digits,
                round_truncate_gpa,
                smbaogn_table(next_row).smbaogn_act_area_gpa,
                smbaogn_table(next_row).smbaogn_act_area_gpa
             );

            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
               NVL(TO_CHAR(smbaogn_table(next_row).smbaogn_act_credits_overall,
                           '99999999999990D990'),'') ||
               g$_nls.get('BWCKSML1-0072', 'SQL',' Credits '),
               class_in=>'fieldsmalltext'),ccolspan=>'1');
            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(

NVL(TO_CHAR(smbaogn_table(next_row).smbaogn_act_area_gpa,
            sig_format_mask),'') || ' <ACRONYM title = "' ||
               g$_nls.get ('BWCKSML1-0073','SQL','Grade Point Average') ||
               '">' ||
               g$_nls.get('BWCKSML1-0074', 'SQL','GPA')||
               '</ACRONYM> ',
               class_in=>'fieldsmalltext'),
                                 ccolspan=>'1');
--
--            twbkfrmt.P_TableDataSeparator(ccolspan=>'6');
--
         END IF;
      twbkfrmt.P_TableRowClose;

      END IF;    -- end next_area test

      END LOOP;  -- end smbaogn_c loop

   END P_GenReqOutput;


   ----------------------------------------------------------------------------
   --
   -- This procedure used used both in the
   -- detail requirements page (P_DispEvalDetailReq)
   -- and general requirements page (P_DispEvalGeneralReq).
   --
   -- This procedure formats tabledata for program
   -- general requirements.
   --

   PROCEDURE P_CommonOutputHeader
      (call_proc          IN VARCHAR2 DEFAULT NULL,
       printer_friendly   IN VARCHAR2,
       eval_term_out      OUT SMRRQCM.SMRRQCM_TERM_CODE_EVAL%TYPE)
   IS
      exp_grad_date        SHRDGMR.SHRDGMR_GRAD_DATE%TYPE DEFAULT NULL;
      prog_ip_cred_tot     NUMBER DEFAULT 0;
      prog_unused_cred_tot NUMBER DEFAULT 0;
      prog_ip_crse_tot     NUMBER DEFAULT 0;
      prog_unused_crse_tot NUMBER DEFAULT 0;
      curr_eval_term       SMRRQCM.SMRRQCM_TERM_CODE_EVAL%TYPE DEFAULT NULL;
      transfer_header      BOOLEAN NOT NULL DEFAULT FALSE;
      other_crse_header    BOOLEAN NOT NULL DEFAULT FALSE;
      smrrqcm_row          SMRRQCM%ROWTYPE;
      dflt_text            STVPRNT.STVPRNT_CODE%TYPE DEFAULT NULL;
      term                 SMBPOGN.SMBPOGN_TERM_CODE_CATLG%TYPE;

   BEGIN


      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0075',
                                   'SQL',
                                   'This table is used to present a program evaluation'
                                ) ||
                                '."',
            ccaption      => lbl_prog_header
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0076',
                                   'SQL',
                                   'This table is used to present a program evaluation'
                                ) ||
                                '."' ||
                                'WIDTH="90%"',
            ccaption      => lbl_prog_header
         );
      END IF;

      term := smbpogn_row.smbpogn_term_code_catlg;

      OPEN SMRRQCM_ALL_C(smbpogn_row.smbpogn_pidm, smbpogn_row.smbpogn_request_no);
      FETCH SMRRQCM_ALL_C INTO smrrqcm_row;
      CLOSE SMRRQCM_ALL_C;

      -- 82277
      -- 96760
      IF smrrqcm_row.smrrqcm_orig_curr_source = 'HISTORY' THEN
         exp_grad_date := get_exp_grad_date(smbpogn_row.smbpogn_pidm,smrrqcm_row.smrrqcm_dgmr_seq_no);
      ELSIF smrrqcm_row.smrrqcm_orig_curr_source = 'GENLSTU' THEN
         -- 96760
         exp_grad_date := get_stdn_grad_date(smrrqcm_row.smrrqcm_pidm, smrrqcm_row.smrrqcm_term_code_curr_source);
         -- exp_grad_date := get_stdn_grad_date(smrrqcm_row.smrrqcm_pidm, smrrqcm_row.smrrqcm_term_code_ctlg_1);
      END IF;

      eval_term_out := smrrqcm_row.smrrqcm_term_code_eval;

      -- change this procedure from 17 to 4
      p_format_program_hdr_text(smbpogn_row.smbpogn_pidm,
                                smbpogn_row.smbpogn_source_ind,
                                smbpogn_row.smbpogn_program,
                                smbpogn_row.smbpogn_term_code_catlg,
                                smbpogn_row.smbpogn_met_ind);

      --
      -- This section lists the program and evaluation term
      --
      twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_prog, class_in=>'fieldmediumtextbold'), ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(get_program_desc(smbpogn_row.smbpogn_program), class_in=>'fieldmediumtext'),
        ccolspan=>'1');
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_ctlg_term, class_in=>'fieldmediumtextbold'), ccolspan=>'1');
        twbkfrmt.P_Tabledata(twbkfrmt.F_PrintText(get_term_desc(smbpogn_row.smbpogn_term_code_catlg), class_in=>'fieldmediumtext'),ccolspan=>'1');
      twbkfrmt.P_TableRowClose;
      --
      curr_eval_term := get_eval_term(smbpogn_row.smbpogn_pidm, smbpogn_row.smbpogn_request_no);
      --
      -- This section lists the campus and graduation term
      --
      camp_used := smbpogn_row.smbpogn_camp_code;
      term_used := curr_eval_term;

      twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_camp,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(get_camp_desc(smbpogn_row.smbpogn_camp_code),class_in=>'fieldmediumtext'),
        ccolspan=>'1');
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_eval_term,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_Tabledata(twbkfrmt.F_PrintText(get_term_desc(curr_eval_term),class_in=>'fieldmediumtext'),ccolspan=>'1');
      twbkfrmt.P_TableRowClose;
      --
      -- This section lists the college and graduation term
      --
      twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_coll,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(get_coll_desc(smbpogn_row.smbpogn_coll_code),class_in=>'fieldmediumtext'),
        ccolspan=>'1');
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_exp_grd_date,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        -- 96760
        IF exp_grad_date IS NOT NULL THEN
twbkfrmt.P_Tabledata(twbkfrmt.F_PrintText(TO_CHAR(exp_grad_date, get_date_fmt), class_in=>'fieldmediumtext'),ccolspan=>'1');
           -- class_in=>'fieldmediumtext'),ccolspan=>'1');
           -- twbkfrmt.P_Tabledata(twbkfrmt.F_PrintText(get_term_desc(exp_grad_date),class_in=>'fieldmediumtext'),ccolspan=>'1');
        ELSE
           twbkfrmt.P_TableDataDead('&nbsp;', ccolspan => '1');
        END IF;
      twbkfrmt.P_TableRowClose;
      --
      -- This section lists the Degree and Request Number.
      --
      twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_degc,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(get_degc_desc(smbpogn_row.smbpogn_degc_code),class_in=>'fieldmediumtext'),
        ccolspan=>'1');
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_req_no,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_Tabledata(twbkfrmt.F_PrintText(TO_CHAR(smbpogn_row.smbpogn_request_no,'9990'),class_in=>'fieldmediumtext'),
        ccolspan=>'1');
      twbkfrmt.P_TableRowClose;
      --
      -- This section lists the level and activity date of request
      --
      levl_used := smbpogn_row.smbpogn_levl_code;
      twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_levl,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(get_levl_desc(smbpogn_row.smbpogn_levl_code),
        class_in=>'fieldmediumtext'),ccolspan=>'1');
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_eff_date,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_Tabledata(twbkfrmt.F_PrintText(TO_CHAR(smbpogn_row.smbpogn_activity_date, get_date_fmt),
        class_in=>'fieldmediumtext'),ccolspan=>'1');
      twbkfrmt.P_TableRowClose;
      --
      -- This section lists the majors and minors
      --
      twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_majrs,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_TableDataOpen(ccolspan=>'1');
        IF smrrqcm_row.smrrqcm_majr_code_1_2 IS NOT NULL THEN
           twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_1),
                                class_in=>'fieldmediumtext');
           htp.br;
           twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_1_2),
                                class_in=>'fieldmediumtext');
        ELSE
           twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_1)||'&nbsp;',
                                class_in=>'fieldmediumtext');
        END IF;
        twbkfrmt.P_TableDataClose;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_minrs,
                                                       class_in=>'fieldmediumtextbold'),
                                  ccolspan=>'1');
        twbkfrmt.P_TableDataOpen(ccolspan=>'1');
        IF smrrqcm_row.smrrqcm_majr_code_minr_1_2 IS NOT NULL THEN
           twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_minr_1_1),
                                class_in=>'fieldmediumtext');
           htp.br;
           twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_minr_1_2),
                                class_in=>'fieldmediumtext');
        ELSE
           twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_minr_1_1),
                                class_in=>'fieldmediumtext');
        END IF;
        twbkfrmt.P_TableDataClose;
      twbkfrmt.P_TableRowClose;
      --
      -- This section lists the departments and concentrations
      --
      twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_depts,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_TableDataOpen(ccolspan=>'1');
        IF smrrqcm_row.smrrqcm_dept_code_1_2 IS NOT NULL THEN
           twbkfrmt.P_PrintText(get_dept_desc(smrrqcm_row.smrrqcm_dept_code),
                     class_in=>'fieldmediumtext');
           htp.br;
           twbkfrmt.P_PrintText(get_dept_desc(smrrqcm_row.smrrqcm_dept_code_1_2),
                                class_in=>'fieldmediumtext');
        ELSE
           twbkfrmt.P_PrintText(get_dept_desc(smrrqcm_row.smrrqcm_dept_code)||'&nbsp;',
                                class_in=>'fieldmediumtext');
        END IF;
        twbkfrmt.P_TableDataClose;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_concs,class_in=>'fieldmediumtextbold'),ccolspan=>'1');
        twbkfrmt.P_TableDataOpen(ccolspan=>'1');
        --
        -- If multiple majors or concentrations exist, concatenate
        -- them together for formatting to web.
        --
      IF ( smrrqcm_row.smrrqcm_majr_code_conc_1 IS NOT NULL )  OR
         ( smrrqcm_row.smrrqcm_majr_code_conc_1_2 IS NOT NULL) OR
         ( smrrqcm_row.smrrqcm_majr_code_conc_1_3 IS NOT NULL) OR
         ( smrrqcm_row.smrrqcm_majr_code_conc_121 IS NOT NULL) OR
         ( smrrqcm_row.smrrqcm_majr_code_conc_122 IS NOT NULL) OR
         ( smrrqcm_row.smrrqcm_majr_code_conc_123 IS NOT NULL) THEN
         IF ( smrrqcm_row.smrrqcm_majr_code_conc_1 IS NOT NULL )    THEN
            twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_conc_1),
                                 class_in=>'fieldmediumtext');
            htp.br;
         END IF;
         IF ( smrrqcm_row.smrrqcm_majr_code_conc_1_2 IS NOT NULL )  THEN
            twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_conc_1_2),
                                 class_in=>'fieldmediumtext');
            htp.br;
         END IF;
         IF ( smrrqcm_row.smrrqcm_majr_code_conc_1_3 IS NOT NULL )  THEN
            twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_conc_1_3),
                                 class_in=>'fieldmediumtext');
            htp.br;
         END IF;
         IF ( smrrqcm_row.smrrqcm_majr_code_conc_121 IS NOT NULL )  THEN
            twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_conc_121),
                                 class_in=>'fieldmediumtext');
            htp.br;
         END IF;
         IF ( smrrqcm_row.smrrqcm_majr_code_conc_122 IS NOT NULL )  THEN
            twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_conc_122),
                                 class_in=>'fieldmediumtext');
            htp.br;
         END IF;
         IF ( smrrqcm_row.smrrqcm_majr_code_conc_123 IS NOT NULL )  THEN
            twbkfrmt.P_PrintText(get_majr_desc(smrrqcm_row.smrrqcm_majr_code_conc_123),
                                 class_in=>'fieldmediumtext');
            htp.br;
         END IF;
      ELSE
         twbkfrmt.P_PrintText('&nbsp;');
      END IF;

      twbkfrmt.P_TableDataClose;
      twbkfrmt.P_TableRowClose;
      twbkfrmt.P_TableClose;
      --
      --
      htp.br;
      --
      -- RPE SSSUI - Close table above, and Create new table
      --
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0077',
                                   'SQL',
                                   'This table is used to present a program evaluation'
                                ) ||
                                '."'
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSML1-0078',
                                   'SQL',
                                   'This table is used to present a program evaluation'
                                ) ||
                                '."' ||
                                'WIDTH="65%"'
         );
      END IF;
      --
      -- The following three blocks create necessary spacers,
      -- labels, and formatting to set up for the next section of display data
      --
       twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'1');
        twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(
              G$_NLS.Get('BWCKSML1-0079', 'SQL', '%01%Met', '&nbsp;' ),
              class_in=>'fieldmediumtextbold'),
        calign=>'CENTER', crowspan=>'2');
        twbkfrmt.P_TableHeader(twbkfrmt.F_PrintText(lbl_com_cred,
                                                    class_in=>'fieldmediumtextbold'),
                               ccolspan=>'2');
        twbkfrmt.P_TableHeader(twbkfrmt.F_PrintText(lbl_com_crse,
                                                    class_in=>'fieldmediumtextbold'),
                               ccolspan=>'2');
      twbkfrmt.P_TableRowClose;

      twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataDead('&nbsp;',ccolspan=>'1');
        twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_com_req,
                                                        class_in=>'fieldmediumtextbold'));
        twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_com_used,
                                                        class_in=>'fieldmediumtextbold'));
        twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_com_req,
                                                        class_in=>'fieldmediumtextbold'));
        twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_com_used,
                                                        class_in=>'fieldmediumtextbold'));
      twbkfrmt.P_TableRowClose;
      --
      -- This section formats the 'required credits' row.
      --
      twbkfrmt.P_TableRowOpen;
       twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_tot_req, class_in=>'fieldmediumtextbold'),
       ccolspan=>'1');
       twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_conv_color(print_requirements(smbpogn_row.smbpogn_req_credits_overall,
                                   smbpogn_row.smbpogn_req_courses_overall,
                                   smbpogn_row.smbpogn_connector_overall,
                                   smbpogn_row.smbpogn_act_credits_overall,
                                   smbpogn_row.smbpogn_act_courses_overall)),class_in=>'fieldmediumtext'), 'CENTER');

       p_format_pgen_reqments(smbpogn_row.smbpogn_req_credits_overall,
                              smbpogn_row.smbpogn_req_courses_overall,
                              smbpogn_row.smbpogn_act_credits_overall,
                              smbpogn_row.smbpogn_act_courses_overall);

     twbkfrmt.P_TableRowClose;
     --
     -- This section formats the 'institutional required credits' row.
     --
     IF smbpogn_row.smbpogn_req_credits_inst IS NOT NULL OR smbpogn_row.smbpogn_req_courses_inst IS NOT NULL THEN
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_req_inst,class_in=>'fieldmediumtextbold'),
        ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_conv_color(print_requirements(smbpogn_row.smbpogn_req_credits_inst,
                                     smbpogn_row.smbpogn_req_courses_inst,
                                     smbpogn_row.smbpogn_connector_inst,
                                     smbpogn_row.smbpogn_act_credits_inst,
                                     smbpogn_row.smbpogn_act_courses_inst)),class_in=>'fieldmediumtext'), 'CENTER');

         p_format_pgen_reqments(smbpogn_row.smbpogn_req_credits_inst,
                                smbpogn_row.smbpogn_req_courses_inst,
                                smbpogn_row.smbpogn_act_credits_inst,
                                smbpogn_row.smbpogn_act_courses_inst);

         twbkfrmt.P_TableRowClose;
     END IF;
     --
     -- This section formats the 'institutional traditional required credits' row.
     --
     IF smbpogn_row.smbpogn_req_credits_i_trad IS NOT NULL OR smbpogn_row.smbpogn_req_courses_i_trad IS NOT NULL THEN
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_inst_trad,class_in=>'fieldmediumtextbold'),
        ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_conv_color(print_requirements(smbpogn_row.smbpogn_req_credits_i_trad,
                                   smbpogn_row.smbpogn_req_courses_i_trad,
                                   smbpogn_row.smbpogn_connector_i_trad,
                                   smbpogn_row.smbpogn_act_credits_i_trad,
                                   smbpogn_row.smbpogn_act_courses_i_trad)),class_in=>'fieldmediumtext'), 'CENTER');

        p_format_pgen_reqments(smbpogn_row.smbpogn_req_credits_i_trad,
                               smbpogn_row.smbpogn_req_courses_i_trad,
                               smbpogn_row.smbpogn_act_credits_i_trad,
                               smbpogn_row.smbpogn_act_courses_i_trad);

        twbkfrmt.P_TableRowClose;
     END IF;
     --
     -- This section formats the 'maximum institutional required credits' row.
     --
     IF smbpogn_row.smbpogn_max_credits_i_nontrad IS NOT NULL OR smbpogn_row.smbpogn_max_courses_i_nontrad IS NOT NULL THEN
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_max_inst,class_in=>'fieldmediumtextbold'),
        ccolspan=>'1');
        twbkfrmt.P_TableDataDead('&nbsp;',ccolspan=>'1');
        --
        -- Defect 79321. Maxes do not get a met/notmet indicator.
        -- However, to match baseline output(SMICRLT) - values still display in red.
        --

        p_format_pgen_reqments(smbpogn_row.smbpogn_max_credits_i_nontrad,
                               smbpogn_row.smbpogn_max_courses_i_nontrad,
                               smbpogn_row.smbpogn_act_credits_i_nontrad,
                               smbpogn_row.smbpogn_act_courses_i_nontrad);

        twbkfrmt.P_TableRowClose;
     END IF;
     --
     -- This section formats the 'last institutional required credits' row.
     --
     IF smbpogn_row.smbpogn_last_inst_credits IS NOT NULL OR smbpogn_row.smbpogn_last_inst_courses IS NOT NULL THEN
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_lst_num,class_in=>'fieldmediumtextbold'),
        ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_conv_color(print_requirements(smbpogn_row.smbpogn_last_inst_credits,
                                   smbpogn_row.smbpogn_last_inst_courses,
                                   smbpogn_row.smbpogn_connector_inst,
                                   smbpogn_row.smbpogn_act_last_inst_credits,
                                   smbpogn_row.smbpogn_act_last_inst_courses)),class_in=>'fieldmediumtext'), 'CENTER');

        p_format_pgen_reqments(smbpogn_row.smbpogn_last_inst_credits,
                               smbpogn_row.smbpogn_last_inst_courses,
                               smbpogn_row.smbpogn_act_last_inst_credits,
                               smbpogn_row.smbpogn_act_last_inst_courses);

        twbkfrmt.P_TableRowClose;
     END IF;
     --
     -- This section formats the 'institutional required credits' row.
     --
     IF smbpogn_row.smbpogn_last_earned_credits IS NOT NULL OR smbpogn_row.smbpogn_last_earned_courses IS NOT NULL THEN
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_lst_ernd,class_in=>'fieldmediumtextbold'),
        ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_conv_color(print_requirements(smbpogn_row.smbpogn_last_earned_credits,
                                   smbpogn_row.smbpogn_last_earned_courses,
                                   smbpogn_row.smbpogn_connector_inst,
                                   smbpogn_row.smbpogn_act_last_earn_credits,
                                   smbpogn_row.smbpogn_act_last_earn_courses)),class_in=>'fieldmediumtext'), 'CENTER');

         p_format_pgen_reqments(smbpogn_row.smbpogn_last_earned_credits,
                                smbpogn_row.smbpogn_last_earned_courses,
                                smbpogn_row.smbpogn_act_last_earn_credits,
                                smbpogn_row.smbpogn_act_last_earn_courses);

        twbkfrmt.P_TableRowClose;
     END IF;
     -- Defect 79321.
     -- This section formats the 'maximum transfer credits' row.
     --
     IF smbpogn_row.smbpogn_max_credits_transfer IS NOT NULL OR smbpogn_row.smbpogn_max_courses_transfer IS NOT NULL THEN
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_max_tran,class_in=>'fieldmediumtextbold'),
        ccolspan=>'1');
        twbkfrmt.P_TableDataDead('&nbsp;',ccolspan=>'1');

        p_format_pgen_reqments(smbpogn_row.smbpogn_max_credits_transfer,
                               smbpogn_row.smbpogn_max_courses_transfer,
                               smbpogn_row.smbpogn_act_credits_transfer,
                               smbpogn_row.smbpogn_act_courses_transfer);

        twbkfrmt.P_TableRowClose;
     END IF;
     --
     -- This section formats the program gpa row.
     --
     twbkfrmt.P_TableRowOpen;
     twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_prg_gpa,class_in=>'fieldmediumtextbold'), ccolspan=>'1');
     IF smbpogn_row.smbpogn_act_program_gpa >= NVL(smbpogn_row.smbpogn_min_program_gpa, 0) THEN
         shkcgpa.p_get_student_formats (
            pidm,
            levl_used,
            camp_used,
            term_used,
            round_truncate_gpa,
            display_gpa_digits,
            round_truncate_points,
            display_points_digits
         );
         shkcgpa.p_make_disp_web_format(
            smbpogn_row.smbpogn_min_program_gpa,
            smbpogn_row.smbpogn_min_program_gpa,
            sig_format_mask
         );
         shkcgpa.p_trunc_or_round (
            display_gpa_digits,
            round_truncate_gpa,
            smbpogn_row.smbpogn_min_program_gpa,
            smbpogn_row.smbpogn_min_program_gpa
         );

         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                                G$_NLS.Get('BWCKSML1-0080', 'SQL', 'Yes'),
                                class_in=>'fieldmediumtext'),
                             'CENTER');
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                                TO_CHAR(smbpogn_row.smbpogn_min_program_gpa, sig_format_mask),
                                class_in=>'fieldmediumtext'),
                              'RIGHT');

         shkcgpa.p_get_student_formats (
            pidm,
            levl_used,
            camp_used,
            term_used,
            round_truncate_gpa,
            display_gpa_digits,
            round_truncate_points,
            display_points_digits
         );
         shkcgpa.p_make_disp_web_format(
            smbpogn_row.smbpogn_act_program_gpa,
            smbpogn_row.smbpogn_act_program_gpa,
            sig_format_mask
         );
         shkcgpa.p_trunc_or_round (
            display_gpa_digits,
            round_truncate_gpa,
            smbpogn_row.smbpogn_act_program_gpa,
            smbpogn_row.smbpogn_act_program_gpa
         );

         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                                TO_CHAR(smbpogn_row.smbpogn_act_program_gpa, sig_format_mask),
                                class_in=>'fieldmediumtext'),
                              'RIGHT');
     ELSE
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_conv_color('N'),class_in=>'fieldmediumtext'), 'CENTER');
        shkcgpa.p_get_student_formats (
           pidm,
           levl_used,
           camp_used,
           term_used,
           round_truncate_gpa,
           display_gpa_digits,
           round_truncate_points,
           display_points_digits
        );
        shkcgpa.p_make_disp_web_format(
           smbpogn_row.smbpogn_min_program_gpa,
           smbpogn_row.smbpogn_min_program_gpa,
           sig_format_mask
        );
        shkcgpa.p_trunc_or_round (
           display_gpa_digits,
           round_truncate_gpa,
           smbpogn_row.smbpogn_min_program_gpa,
           smbpogn_row.smbpogn_min_program_gpa
        );
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                                req_notmet_color(TO_CHAR(smbpogn_row.smbpogn_min_program_gpa, sig_format_mask)),
                                class_in=>'fieldmediumtext'),
                              'RIGHT');

         shkcgpa.p_get_student_formats (
            pidm,
            levl_used,
            camp_used,
            term_used,
            round_truncate_gpa,
            display_gpa_digits,
            round_truncate_points,
            display_points_digits
         );
        shkcgpa.p_make_disp_web_format(smbpogn_row.smbpogn_act_program_gpa,
                                        smbpogn_row.smbpogn_act_program_gpa,
                                        sig_format_mask);
         shkcgpa.p_trunc_or_round (
            display_gpa_digits,
            round_truncate_gpa,
            smbpogn_row.smbpogn_act_program_gpa,
            smbpogn_row.smbpogn_act_program_gpa
         );
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_notmet_color(TO_CHAR(smbpogn_row.smbpogn_act_program_gpa,
                                                 sig_format_mask)),class_in=>'fieldmediumtext'),'RIGHT');

     END IF;
     twbkfrmt.P_TableData('&nbsp;');
     twbkfrmt.P_TableData('&nbsp;');
     twbkfrmt.P_TableRowClose;
     --
     -- This section formats the overall gpa row.
     --
     twbkfrmt.P_TableRowOpen;
     twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_ovr_gpa,class_in=>'fieldmediumtextbold'),
     ccolspan=>'1');
     IF smbpogn_row.smbpogn_act_gpa >= NVL(smbpogn_row.smbpogn_min_gpa, 0) THEN
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                               G$_NLS.Get('BWCKSML1-0081', 'SQL', 'Yes'),
                               class_in=>'fieldmediumtext'),
                             'CENTER');
        shkcgpa.p_get_student_formats (
           pidm,
           levl_used,
           camp_used,
           term_used,
           round_truncate_gpa,
           display_gpa_digits,
           round_truncate_points,
           display_points_digits
        );
        shkcgpa.p_make_disp_web_format(smbpogn_row.smbpogn_min_gpa,
                                       smbpogn_row.smbpogn_min_gpa,
                                       sig_format_mask);
        shkcgpa.p_trunc_or_round (
           display_gpa_digits,
           round_truncate_gpa,
           smbpogn_row.smbpogn_min_gpa,
           smbpogn_row.smbpogn_min_gpa
        );

        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                               TO_CHAR(smbpogn_row.smbpogn_min_gpa, sig_format_mask),
                               class_in=>'fieldmediumtext'),
                             'RIGHT');

        shkcgpa.p_get_student_formats (
           pidm,
           levl_used,
           camp_used,
           term_used,
           round_truncate_gpa,
           display_gpa_digits,
           round_truncate_points,
           display_points_digits
        );
        shkcgpa.p_make_disp_web_format(smbpogn_row.smbpogn_act_gpa,
                                       smbpogn_row.smbpogn_act_gpa,
                                       sig_format_mask);
        shkcgpa.p_trunc_or_round (
           display_gpa_digits,
           round_truncate_gpa,
           smbpogn_row.smbpogn_act_gpa,
           smbpogn_row.smbpogn_act_gpa
        );

        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(TO_CHAR(smbpogn_row.smbpogn_act_gpa,sig_format_mask),
        class_in=>'fieldmediumtext'),'RIGHT');
     ELSE
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_conv_color('N'),class_in=>'fieldmediumtext'), 'CENTER');
        shkcgpa.p_get_student_formats (
           pidm,
           levl_used,
           camp_used,
           term_used,
           round_truncate_gpa,
           display_gpa_digits,
           round_truncate_points,
           display_points_digits
        );
        shkcgpa.p_make_disp_web_format(smbpogn_row.smbpogn_min_gpa,
                                       smbpogn_row.smbpogn_min_gpa,
                                       sig_format_mask);
         shkcgpa.p_trunc_or_round (
           display_gpa_digits,
           round_truncate_gpa,
           smbpogn_row.smbpogn_min_gpa,
           smbpogn_row.smbpogn_min_gpa
        );

        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
                               req_notmet_color(TO_CHAR(smbpogn_row.smbpogn_min_gpa, sig_format_mask)),
                               class_in=>'fieldmediumtext'),
                             'RIGHT');

        shkcgpa.p_get_student_formats (
           pidm,
           levl_used,
           camp_used,
           term_used,
           round_truncate_gpa,
           display_gpa_digits,
           round_truncate_points,
           display_points_digits
        );
        shkcgpa.p_make_disp_web_format(smbpogn_row.smbpogn_act_gpa,
                                       smbpogn_row.smbpogn_act_gpa,
                                       sig_format_mask);
        shkcgpa.p_trunc_or_round (
           display_gpa_digits,
           round_truncate_gpa,
           smbpogn_row.smbpogn_act_gpa,
           smbpogn_row.smbpogn_act_gpa
        );

        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_notmet_color(TO_CHAR(smbpogn_row.smbpogn_act_gpa,
        sig_format_mask)) ,class_in=>'fieldmediumtext'),'RIGHT');
     END IF;
     twbkfrmt.P_TableData('&nbsp;');
     twbkfrmt.P_TableData('&nbsp;');
     twbkfrmt.P_TableRowClose;
     --
     --
     --
     IF transfer_header = FALSE THEN
        IF smbpogn_row.smbpogn_act_credits_transfer IS NOT NULL OR smbpogn_row.smbpogn_act_courses_transfer IS NOT NULL THEN
           other_crse_header := TRUE;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_othr_info,class_in=>'fieldmediumtextbold'),
           ccolspan=>'1');
           twbkfrmt.P_TableDataDead('&nbsp;',ccolspan=>'5');
           twbkfrmt.P_TableRowClose;

           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_trans,class_in=>'fieldmediumtextbold'),
           ccolspan=>'1');
           twbkfrmt.P_TableDataDead('&nbsp;',ccolspan=>'1');
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(smbpogn_row.smbpogn_max_credits_transfer, '99999999999990D990'),'')
           ,class_in=>'fieldmediumtext'),'RIGHT');
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(smbpogn_row.smbpogn_act_credits_transfer, '99999999999990D990'),'')
           ,class_in=>'fieldmediumtext'),'RIGHT');
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(smbpogn_row.smbpogn_max_courses_transfer, '990'),'')
           ,class_in=>'fieldmediumtext'), 'RIGHT');
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(smbpogn_row.smbpogn_act_courses_transfer, '990'),'')
           ,class_in=>'fieldmediumtext'),'RIGHT');
           -- twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'6');
           twbkfrmt.P_TableRowClose;
        END IF;
     END IF;
     --
     prog_ip_cred_tot := get_prog_ip_cred_tot(smbpogn_row.smbpogn_pidm, smbpogn_row.smbpogn_request_no);
     prog_ip_crse_tot := get_prog_ip_crse_tot(smbpogn_row.smbpogn_pidm, smbpogn_row.smbpogn_request_no);
     --
     IF ((prog_ip_cred_tot > 0) OR (prog_ip_crse_tot > 0)) THEN
        IF other_crse_header = FALSE THEN
           other_crse_header := TRUE;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'6');
           twbkfrmt.P_TableRowClose;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_othr_info,class_in=>'fieldmediumtextbold'),
           ccolspan=>'1');
           twbkfrmt.P_TableDataDead('&nbsp;',ccolspan=>'5');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'6');
           twbkfrmt.P_TableRowClose;
        END IF;
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_ip,class_in=>'fieldmediumtextbold'),
        ccolspan=>'1');
        twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'1');
        twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'1');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(TO_CHAR(prog_ip_cred_tot,
                                                          '99999999999990D990'),class_in=>'fieldmediumtext')
        ,'RIGHT');
        twbkfrmt.P_TableData('&nbsp;');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(TO_CHAR(prog_ip_crse_tot, '990'),class_in=>'fieldmediumtext')
        ,'RIGHT');
        twbkfrmt.P_TableRowClose;
     END IF;
     --
     prog_unused_cred_tot := get_prog_unused_cred_tot(smbpogn_row.smbpogn_pidm, smbpogn_row.smbpogn_request_no);
     prog_unused_crse_tot := get_prog_unused_crse_tot(smbpogn_row.smbpogn_pidm, smbpogn_row.smbpogn_request_no);
     --
     IF ((prog_unused_cred_tot > 0) OR (prog_unused_crse_tot > 0)) THEN
        IF other_crse_header = FALSE THEN
           other_crse_header := TRUE;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'6');
           twbkfrmt.P_TableRowClose;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_othr_info,class_in=>'fieldmediumtextbold'),
           ccolspan=>'1');
           twbkfrmt.P_TableDataDead('&nbsp;',ccolspan=>'5');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableData('&nbsp;');
           -- twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'6');
           twbkfrmt.P_TableRowClose;
        END IF;

        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_unused,class_in=>'fieldmediumtextbold'),
        ccolspan=>'1');
        twbkfrmt.P_TableDataDead('&nbsp;',ccolspan=>'1');
        twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'1');
        -- twbkfrmt.P_TableData('&nbsp;');

twbkfrmt.P_TableData(twbkfrmt.F_PrintText(TO_CHAR(prog_unused_cred_tot,
'99999999999990D990'),class_in=>'fieldmediumtext'), 'RIGHT');
        twbkfrmt.P_TableData('&nbsp;');
        twbkfrmt.P_TableData(twbkfrmt.F_PrintText(TO_CHAR(prog_unused_crse_tot, '990'),class_in=>'fieldmediumtext'),
        'RIGHT');
        twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'1');
        twbkfrmt.P_TableRowClose;
        twbkfrmt.P_TableRowOpen;
        twbkfrmt.P_TableDataDead('&nbsp;', ccolspan=>'6');
        twbkfrmt.P_TableRowClose;
     END IF;

     -- Inhouse Defect; Use web tailor "COMMENT" vx. hardcoded value.
     twbkfrmt.P_TableRowOpen;
     twbkfrmt.P_TableDataSeparator(twbkwbis.F_DispInfo('bwcksmlt.P_DispEvalDetailReq','COMMENT'),
              calign=>'CENTER',ccolspan=>'17');
     twbkfrmt.P_TableRowClose;

     twbkfrmt.P_TableClose;

   END P_CommonOutputHeader;

   ----------------------------------------------------------------------------
   --
   -- Procedure used to set/subsets into
   --    "("   , - Defect# 94483
   --   "AND"  ,
   --  ")AND(" ,
   --   "OR"   ,
   --   ")OR("   text.
   -- which is the return value 'set_sub'.
   --

   PROCEDURE decode_set_subset
      (prev_set  IN smracaa.smracaa_set%TYPE DEFAULT NULL,
       prev_sub  IN smracaa.smracaa_subset%TYPE DEFAULT NULL,
       cur_set   IN smracaa.smracaa_set%TYPE DEFAULT NULL,
       cur_sub   IN smracaa.smracaa_subset%TYPE DEFAULT NULL,
       open_paren IN OUT BOOLEAN,
       first_req IN OUT BOOLEAN,
       set_sub OUT VARCHAR2)
   IS

   BEGIN

   set_sub := '';

      IF cur_set IS NOT NULL THEN
         IF prev_set = cur_set THEN
            IF prev_sub = cur_sub THEN
               set_sub := g$_nls.get('BWCKSML1-0082','SQL','AND');
            ELSE
               IF open_paren = TRUE THEN
                  set_sub := g$_nls.get('BWCKSML1-0083','SQL',')OR(');
               ELSE
                  set_sub := g$_nls.get('BWCKSML1-0084','SQL','OR');
               END IF;
            END IF;
         ELSE
            IF open_paren = TRUE THEN
               set_sub := g$_nls.get('BWCKSML1-0085','SQL',')AND(');
            ELSE
               IF first_req = FALSE THEN
                  set_sub := g$_nls.get('BWCKSML1-0086','SQL','AND (');
               ELSE
                  -- Defect# 94483
                  --set_sub := g$_nls.get('BWCKSML1-0148','SQL','(');--I18N Issue 1-3FA6GU
                    set_sub := '(';
                  first_req := FALSE;
               END IF;
               open_paren := TRUE;
            END IF;
         END IF;
      ELSE
        --  Defect# 94483 - ")" text.
        IF open_paren = TRUE THEN
           --set_sub := g$_nls.get('BWCKSML1-0173','SQL',')');--I18N Issue 1-3FA6GU
             set_sub := ')';
           open_paren := FALSE;
           twbkfrmt.P_TableRowOpen;
           twbkfrmt.P_TableDataDead;
           twbkfrmt.P_TableData(twbkfrmt.F_PrintText(set_sub,class_in=>'fieldsmalltext'));
           twbkfrmt.P_TableRowClose;
        END IF;
        --
         IF first_req = FALSE THEN
            set_sub := g$_nls.get('BWCKSML1-0087','SQL',' AND');
         ELSE
            set_sub := '';
            first_req := FALSE;
         END IF;
      END IF;

   END decode_set_subset;

   -----------------------------------------------------------------------------
   --
   PROCEDURE p_decode_subj_link
      (catlg_term_in     IN OUT STVTERM.STVTERM_CODE%TYPE,
       subj_code_in      IN OUT STVSUBJ.STVSUBJ_CODE%TYPE,
       crse_low_in       IN OUT SCBCRSE.SCBCRSE_CRSE_NUMB%TYPE,
       crse_high_in      IN OUT SCBCRSE.SCBCRSE_CRSE_NUMB%TYPE,
       request_no_in     IN OUT SMRRQCM.SMRRQCM_REQUEST_NO%TYPE,
       printer_friendly  IN OUT VARCHAR2,
       detl_met_ind      IN  SMRDORQ.SMRDORQ_MET_IND%TYPE,
       area_met_ind      IN  SMBPOGN.SMBPOGN_MET_IND%TYPE)
   IS

      call_proc_out      VARCHAR2(120) DEFAULT NULL;
      tmp_crse_high_in   SCBCRSE.SCBCRSE_CRSE_NUMB%TYPE DEFAULT NULL;

   BEGIN

      call_proc_out      := 'bwcksmlt.P_DispEvalDetailReq*request_no='||request_no_in||';printer_friendly='||printer_friendly;

      -- If an area or group is MET, do
      -- not allow subject code to be linked to
      -- dynamic catalog display.
      -- Otherwise, if area or group is NOT MET,
      -- and the detail requirement line is NOT MET
      -- as well, then we allow link to dynamic catalog.
      --

      IF area_met_ind = 'N' THEN
         IF detl_met_ind = 'Y' THEN
            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
            NVL(subj_code_in, ''),class_in=>'fieldsmalltext'));
         END IF;
         IF detl_met_ind = 'E' THEN
            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
            NVL(subj_code_in, ''),class_in=>'fieldsmalltext'));
         END IF;
         IF detl_met_ind = 'N' THEN
            IF subj_code_in IS NOT NULL THEN
               --
               -- If no high value, assign working var to low
               -- so that the search only retrieves exact course,
               -- not search low -> null ( highest ).
               --
               IF crse_high_in IS NULL THEN
                  tmp_crse_high_in := crse_low_in;
               ELSE
                  tmp_crse_high_in := crse_high_in;
               END IF;
               -- 78466
               twbkfrmt.P_TableData (twbkfrmt.F_PrintText(
                                        twbkfrmt.f_printanchor(
                                        curl => twbkfrmt.f_encodeurl (
                                                twbkwbis.f_cgibin || 'bwckctlg.p_display_courses' ||
                                                '?term_in='   || twbkfrmt.f_encode(catlg_term_in) ||
                                                '&one_subj='  || twbkfrmt.f_encode(subj_code_in) ||
                                                '&sel_subj=' || NULL ||
                                                '&sel_crse_strt='  || twbkfrmt.f_encode(crse_low_in) ||
                                                '&sel_crse_end='   || twbkfrmt.f_encode(tmp_crse_high_in) ||
                                                '&sel_title='  || NULL ||
                                                '&sel_levl='  || NULL ||
                                                '&sel_schd='  || NULL ||
                                                '&sel_coll='  || NULL ||
                                                '&sel_divs='  || NULL ||
                                                '&sel_dept='  || NULL ||
                                                '&sel_from_cred='  || NULL ||
                                                '&sel_to_cred='  || NULL ||
                                                '&sel_attr='  || NULL ),
                                        ctext => subj_code_in,
                                        cattributes   => bwckfrmt.f_anchor_focus (
                                                         g$_nls.get ('BWCKSML1-0088', 'SQL', 'Display Course')
                                                         )
                                     ),
                                     class_in=>'fieldsmalltext')
                                    );
            ELSE
               twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
               NVL(subj_code_in, ''),class_in=>'fieldsmalltext'));
            END IF;
         END IF;
      ELSE
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(
         NVL(subj_code_in, ''),class_in=>'fieldsmalltext'));
      END IF;

   END p_decode_subj_link;

   -----------------------------------------------------------------------------
   --
   -- Common procedure to format the detail label title bar under areas
   -- and groups.
   --
   PROCEDURE p_format_detail_title_bar
   IS
   BEGIN

        twbkfrmt.P_TableRowOpen;
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_met,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_cond,class_in=>'fieldsmallboldtext')); -- , calign=>'CENTER');
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_rule,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_subj,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_attr,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_low,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_high,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_req_cred,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_req_crse,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_det_term,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_subj,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_det_crse,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_title,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_attr,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_com_cred,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_grde,class_in=>'fieldsmallboldtext'));
          twbkfrmt.P_TableDataHeader(twbkfrmt.F_PrintText(lbl_src,class_in=>'fieldsmallboldtext'));
        twbkfrmt.P_TableRowClose;

   END p_format_detail_title_bar;

   -----------------------------------------------------------------------------
   --
   -- This procedure formats area text on the
   -- detail requirements page.
   --
   PROCEDURE p_format_area_detail_text
      (pidm_in       IN SPRIDEN.SPRIDEN_PIDM%TYPE,
       source_in     IN SMBAOGN.SMBAOGN_SOURCE_IND%TYPE,
       area_in       IN SMBAOGN.SMBAOGN_AREA%TYPE,
       term_in       IN STVTERM.STVTERM_CODE%TYPE,
       met_ind_in    IN SMBAOGN.SMBAOGN_MET_IND%TYPE,
       gc_ind        IN SMBAOGN.SMBAOGN_GC_IND%TYPE,
       dflt_text_out    OUT STVPRNT.STVPRNT_CODE%TYPE)

   IS

       smracmt_rowcount     NUMBER DEFAULT 0;
       smrsacm_rowcount     NUMBER DEFAULT 0;
       area_text            VARCHAR2(32000) DEFAULT NULL;
       area_text_cnt        NUMBER DEFAULT 0;
       dflt_text            STVPRNT.STVPRNT_CODE%TYPE;

   BEGIN

      IF smbwcrl_row.smbwcrl_dflt_eval_prnt_code is NOT NULL THEN
         dflt_text := smbwcrl_row.smbwcrl_dflt_eval_prnt_code;
      ELSIF smbwcrl_row.smbwcrl_dflt_eval_cprt_code is NOT NULL THEN
         IF met_ind_in = 'Y' THEN
            dflt_text := smrcprt_row.smrcprt_prnt_code_acmt_met;
         ELSE
            dflt_text := smrcprt_row.smrcprt_prnt_code_acmt_nmet;
         END IF;
      END IF;

      dflt_text_out := dflt_text;
      /* Defect 81768 - rewrite logic to retrieve adjusted text. */

   IF dflt_text IS NOT NULL THEN
       smrsacm_rowcount := f_smrsacm_rowcount(pidm_in, area_in, term_in, dflt_text);
       smracmt_rowcount := f_smracmt_rowcount(area_in, term_in, dflt_text);

       IF smrsacm_rowcount <> 0 THEN
          area_text := '';
          area_text_cnt := 0;
          twbkfrmt.P_TableRowOpen;
          twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_desc,class_in=>'fieldmediumtextbold'));
          FOR smrsacm_row IN SMRSACM_TEXT_C(pidm_in, area_in, term_in, dflt_text) LOOP
             area_text := area_text || ' ' || smrsacm_row.smrsacm_text;
             area_text_cnt := area_text_cnt + 1;
          END LOOP;
          IF gc_ind = 'C' THEN
             twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_text,class_in=>'fieldmediumtext'), ccolspan=>'16');
          ELSE
             twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_text,class_in=>'fieldmediumtext'), ccolspan=>'6');
          END IF;
          twbkfrmt.P_TableDataClose;
          twbkfrmt.P_TableRowClose;
       ELSIF smracmt_rowcount <> 0 THEN
          area_text := '';
          area_text_cnt := 0;
          twbkfrmt.P_TableRowOpen;
          twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_desc,class_in=>'fieldmediumtextbold'));
          FOR smracmt_row in SMRACMT_TEXT_C(area_in, term_in, dflt_text) LOOP
            area_text := area_text || ' ' ||smracmt_row.smracmt_text;
            area_text_cnt := area_text_cnt+1;
          END LOOP;
          IF gc_ind = 'C' THEN
             twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_text,class_in=>'fieldmediumtext'), ccolspan=>'16');
          ELSE
             twbkfrmt.P_TableData(twbkfrmt.F_PrintText(area_text,class_in=>'fieldmediumtext'), ccolspan=>'6');
          END IF;
          twbkfrmt.P_TableDataClose;
          twbkfrmt.P_TableRowClose;
       END IF;  -- end smracmt_rowcount
    END IF;    -- end if dflt_text is not null

   END p_format_area_detail_text;

   -----------------------------------------------------------------------------
   --
   -- This procedure formats group text on the
   -- detail requirements page.
   --
   PROCEDURE p_format_group_detail_text
      (pidm_in       IN SPRIDEN.SPRIDEN_PIDM%TYPE,
       source_in     IN SMBGOGN.SMBGOGN_SOURCE_IND%TYPE,
       group_in      IN SMBGOGN.SMBGOGN_AREA%TYPE,
       term_in       IN STVTERM.STVTERM_CODE%TYPE,
       met_ind_in    IN SMBGOGN.SMBGOGN_MET_IND%TYPE,
       dflt_text_out OUT STVPRNT.STVPRNT_CODE%TYPE)

   IS

       smrgcmt_rowcount       NUMBER DEFAULT 0;
       smrsgcm_rowcount       NUMBER DEFAULT 0;
       group_text             VARCHAR2(32000) DEFAULT NULL;
       group_text_cnt         NUMBER DEFAULT 0;
       dflt_text              STVPRNT.STVPRNT_CODE%TYPE;

   BEGIN

      IF smbwcrl_row.smbwcrl_dflt_eval_prnt_code is NOT NULL THEN
         dflt_text := smbwcrl_row.smbwcrl_dflt_eval_prnt_code;
      ELSIF smbwcrl_row.smbwcrl_dflt_eval_cprt_code is NOT NULL THEN
         IF met_ind_in = 'Y' THEN
            dflt_text := smrcprt_row.smrcprt_prnt_code_gcmt_met;
         ELSE
            dflt_text := smrcprt_row.smrcprt_prnt_code_gcmt_nmet;
         END IF;
      END IF;

      dflt_text_out := dflt_text;
      /* Defect 81768. Rewrote logic  to retrieve adjusted text. */

     IF dflt_text IS NOT NULL THEN
         smrgcmt_rowcount := f_smrgcmt_rowcount(group_in, term_in, dflt_text);
         smrsgcm_rowcount := f_smrsgcm_rowcount(pidm_in, group_in, term_in, dflt_text);

         IF smrsgcm_rowcount <> 0 THEN
            group_text := '';
            group_text_cnt := 0;
            twbkfrmt.P_TableRowOpen;
            twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_desc,class_in=>'fieldmediumtextbold'));
            FOR smrsgcm_row IN SMRSGCM_TEXT_C(pidm_in, group_in, term_in, dflt_text) LOOP
               group_text := group_text || ' ' || smrsgcm_row.smrsgcm_text;
               group_text_cnt := group_text_cnt + 1;
            END LOOP;
            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(group_text,class_in=>'fieldmediumtext'), ccolspan=>'16');
            twbkfrmt.P_TableDataClose;
            twbkfrmt.P_TableRowClose;
         ELSIF smrgcmt_rowcount <> 0 THEN
            group_text := '';
            group_text_cnt := 0;
            twbkfrmt.P_TableRowOpen;
            twbkfrmt.P_TableDataLabel(twbkfrmt.F_PrintText(lbl_desc,class_in=>'fieldmediumtextbold'));
            FOR smrgcmt_row in SMRGCMT_TEXT_C(group_in, term_in, dflt_text) LOOP
               group_text := group_text || ' ' ||smrgcmt_row.smrgcmt_text;
               group_text_cnt := group_text_cnt+1;
            END LOOP;
            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(group_text,class_in=>'fieldmediumtext'),ccolspan=>'16');
            twbkfrmt.P_TableDataClose;
            twbkfrmt.P_TableRowClose;
         END IF;
      END IF;

   END p_format_group_detail_text;

   -----------------------------------------------------------------------------
   --
   -- This procedure formats the program text on the
   -- general requirements page.
   --
   PROCEDURE p_format_program_hdr_text
      (pidm_in       IN SPRIDEN.SPRIDEN_PIDM%TYPE,
       source_in     IN SMBAOGN.SMBAOGN_SOURCE_IND%TYPE,
       prog_in       IN SMBAOGN.SMBAOGN_AREA%TYPE,
       term_in       IN STVTERM.STVTERM_CODE%TYPE,
       met_ind_in    IN SMBPOGN.SMBPOGN_MET_IND%TYPE)

   IS

      program_text         VARCHAR2(32000) DEFAULT NULL;
      program_text_cnt     NUMBER DEFAULT 0;
      dflt_text            STVPRNT.STVPRNT_CODE%TYPE;

   BEGIN

      program_text := '';

      IF smbwcrl_row.smbwcrl_dflt_eval_prnt_code is NOT NULL THEN
         dflt_text := smbwcrl_row.smbwcrl_dflt_eval_prnt_code;
      ELSIF smbwcrl_row.smbwcrl_dflt_eval_cprt_code is NOT NULL THEN
         IF met_ind_in = 'Y' THEN
            dflt_text := smrcprt_row.smrcprt_prnt_code_pcmt_met;
         ELSE
            dflt_text := smrcprt_row.smrcprt_prnt_code_pcmt_nmet;
         END IF;
      END IF;

      IF dflt_text IS NOT NULL THEN
         FOR smrspcm_row in SMRSPCM_TEXT_C(pidm_in, prog_in, term_in, dflt_text) LOOP
            EXIT WHEN SMRSPCM_TEXT_C%NOTFOUND;
            program_text := program_text || ' ' || smrspcm_row.smrspcm_text;
         END LOOP;

         IF program_text IS NULL THEN
            FOR smrpcmt_row in SMRPCMT_TEXT_C(prog_in, term_in, dflt_text) LOOP
            EXIT WHEN SMRPCMT_TEXT_C%NOTFOUND;
               program_text := program_text || ' ' || smrpcmt_row.smrpcmt_text;
            END LOOP;
         END IF;

         IF program_text IS NOT NULL THEN
            twbkfrmt.P_TableRowOpen;
            twbkfrmt.P_TableData(twbkfrmt.F_PrintText(program_text, class_in=>'fieldmediumtext'),ccolspan=>'4');
            twbkfrmt.P_TableRowClose;
         END IF;
      END IF;  -- end if dflt_text is not null

   END p_format_program_hdr_text;

   -----------------------------------------------------------------------------
   --
   -- This procedure new as of 5.4/5.2.
   -- Used to 'translate' the area and group title
   -- bars on both the general and detail requirement output page.
   -- It takes the required credits, required courses, connector, and
   -- met status to build a descriptive statement.
   -- i.e : area ( 30 credits and 10 courses ) - Not Met
   --

   PROCEDURE p_format_met_bar
      (param1 IN SMBAOGN.SMBAOGN_AREA%TYPE,
       param2 IN SMBAOGN.SMBAOGN_REQ_CREDITS_OVERALL%TYPE,
       param3 IN SMBAOGN.SMBAOGN_REQ_COURSES_OVERALL%TYPE,
       param4 IN SMBAOGN.SMBAOGN_CONNECTOR_OVERALL%TYPE,
       param5 IN VARCHAR2 DEFAULT NULL,
       param6 IN SMBAOGN.SMBAOGN_MET_IND%TYPE,
       param7 IN VARCHAR2 DEFAULT NULL)
   IS

      bld_statement varchar2(250) DEFAULT NULL;
      bld_met       varchar2(68) DEFAULT NULL;

   BEGIN

      bld_statement := '';
      bld_met       := '';

      IF f_gen_req_label_disp(param2, param3) THEN

         IF param5 = 'A' THEN
            bld_statement := get_area_desc(param1);
         ELSIF param5 = 'G' THEN
            bld_statement := get_group_desc(param1);
         END IF;

         IF param4 = 'A' THEN
            bld_statement := bld_statement || ' ( ' ||
                             TO_CHAR(param2,'99999999999990D990') ||
                             g$_nls.get('BWCKSML1-0089','SQL',' credits AND ' )||
                             TO_CHAR(param3,'990') ||
                             g$_nls.get('BWCKSML1-0090','SQL',' courses )');

         ELSIF param4 = 'O' THEN
            bld_statement := bld_statement || ' ( ' ||
                             TO_CHAR(param2,'99999999999990D990') ||
                             g$_nls.get('BWCKSML1-0091','SQL',' credits OR ' )||
                             TO_CHAR(param3,'990') ||
                             g$_nls.get('BWCKSML1-0092','SQL',' courses )');
         ELSIF param4 = 'N' THEN
            IF param2 IS NOT NULL THEN
               bld_statement := bld_statement ||
                                ' ( ' ||
                                TO_CHAR(param2,'99999999999990D990') ||
                                g$_nls.get('BWCKSML1-0093','SQL',' credits ) ');
            ELSE
              bld_statement := bld_statement ||
                                ' ( ' ||
                                TO_CHAR(param3,'990') ||
                                g$_nls.get('BWCKSML1-0094','SQL',' courses ) ');
            END IF;
         END IF;
      ELSE
         IF param5 = 'A' THEN
            bld_statement := get_area_desc(param1);
         ELSIF param5 = 'G' THEN
            bld_statement := get_group_desc(param1);
         END IF;
      END IF;

      IF param6 = 'N' THEN
         bld_met := twbkfrmt.F_PrintText(
                       g$_nls.get('BWCKSML1-0095','SQL',' - Not Met'),
                       class_in=>'requirementnotmet');
      ELSIF param6 = 'Y' THEN
         bld_met := twbkfrmt.F_PrintText(
                       g$_nls.get('BWCKSML1-0096','SQL',' - Met'));
      END IF;

      twbkfrmt.P_PrintText(bld_statement, class_in=>param7);
      twbkfrmt.P_PrintText(bld_met, class_in=>param7);


   END p_format_met_bar;

   ----------------------------------------------------------------------------
   --
   -- Procedure for RPE # 26520
   --
   PROCEDURE p_format_separator
     (text_in IN TWGRINFO.TWGRINFO_TEXT%TYPE)
   IS
   BEGIN

      IF text_in IS NOT NULL THEN
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableDataSeparator(text_in, calign=>'CENTER', ccolspan => '17');
         twbkfrmt.P_TableRowClose;
      END IF;

   END p_format_separator;

   -----------------------------------------------------------------------------
   --
   -- New procedure for 5.5.  Used on p_commonoutputheader
   -- to reduce redundant code.
   --
   PROCEDURE p_format_pgen_reqments
      (req_credits IN SMBPGEN.SMBPGEN_REQ_CREDITS_OVERALL%TYPE,
       req_courses IN SMBPGEN.SMBPGEN_REQ_COURSES_OVERALL%TYPE,
       act_credits IN SMBPGEN.SMBPGEN_REQ_CREDITS_OVERALL%TYPE,
       act_courses IN SMBPGEN.SMBPGEN_REQ_COURSES_OVERALL%TYPE)
   IS
   BEGIN

      IF NVL(act_credits,0) >= NVL(req_credits,0) THEN
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(req_credits, '99999999999990D990'),'')
         ,class_in=>'fieldmediumtext'),calign=>'RIGHT');
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(act_credits, '99999999999990D990'),'')
         ,class_in=>'fieldmediumtext'),calign=>'RIGHT');
      ELSE
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_notmet_color(NVL(TO_CHAR(req_credits,
         '99999999999990D990'),'')),class_in=>'fieldmediumtext'),calign=>'RIGHT');
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_notmet_color(NVL(TO_CHAR(act_credits,
         '99999999999990D990'),'')),class_in=>'fieldmediumtext'),calign=>'RIGHT');
      END IF;
      IF NVL(act_courses,0)  >= NVL(req_courses,0) THEN
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(req_courses, '990'),'')
         ,class_in=>'fieldmediumtext'),calign=>'RIGHT');
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(NVL(TO_CHAR(act_courses, '990'),'')
         ,class_in=>'fieldmediumtext'),calign=>'RIGHT');
      ELSE
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_notmet_color(NVL(TO_CHAR(req_courses,
         '990'),'')),class_in=>'fieldmediumtext'),calign=>'RIGHT');
         twbkfrmt.P_TableData(twbkfrmt.F_PrintText(req_notmet_color(NVL(TO_CHAR(act_courses,
         '990'),'')),class_in=>'fieldmediumtext'),calign=>'RIGHT');
      END IF;
   END;

   -----------------------------------------------------------------------------
     -- BOTTOM

  PROCEDURE P_VerifyDispEvalViewOption(psReclDesc VARCHAR2) IS

  /*
      Fecha: 07/12/2010
         Autor: CCR
  Modificación: Se le agrgo la instrucción para que termine la imagen load del reporte
  */


  vsOpcion VARCHAR2(1) := NULL;

  BEGIN
      --son buscadas los valores de las cookies para asignar los valores del filtro del query.
      vsOpcion := pk_objhtml.getvaluecookie('psCapp');

      htp.p('<script language="javascript" src="kwacnls.js"></script>');

      IF    vsOpcion = '1' THEN
            P_DispEvalGeneralReq('Requerimientos generales');

      ELSIF vsOpcion = '2' THEN
            P_DispEvalDetailReq('Requerimientos a detalle');

      ELSIF vsOpcion = '3' THEN
            pk_bwcksncr.P_DISPEVALADDITIONAL('Información adcional');

      END IF;

  END P_VerifyDispEvalViewOption;

  PROCEDURE P_CSS IS

  BEGIN
      htp.p('
      <style type="text/css"><!--
      .centeraligntext {
        text-align: center;
        }

        .leftaligntext {
        text-align: left;
        }

        .rightaligntext {
        text-align: right;
        }

        .menulisttext {
        list-style: none;
        }
        ');

        htp.p('
        .captiontext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: italic;
        text-align: left;
        margin-top: 1em;
        }

        .skiplinks {
        display: none;
        }

        .pageheaderlinks {
        color: #FFFFFF;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: center;
        }
        ');

        htp.p('
        .requirementnotmet {
        color: black;
        }

        /* Class for Sub-menu Items                                  */
        /* ========================================================  */
        .pageheaderlinks2 {
        color: #CED5EA;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-size: 90%;
        text-align: justify;
        }

        .pagebodylinks {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: center;
        }

        .gotoanchorlinks {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }
        ');

        htp.p('
        .pagefooterlinks {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: center;
        /* BROWSER CONSIDERATION - To make Netscape and IE compatible for PageFooter Division. */
        /* Margin-left style specified for Netscape within parent SPAN tag,                    */
        /* while IE uses the padding-left style within parent DIV tag.                         */
        margin-left: 3px;
        }

        .backlinktext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: right;
        margin-bottom: 5px;
        }

        .menuheadertext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 100%;
        font-style: normal;
        text-align: left;
        }

        .menulinktext {
        color: #0F2167;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-style: normal;
        }

        .menulinkdesctext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .normaltext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .infotext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .errortext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .warningtext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .multipagemsgtext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .releasetext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        text-transform: uppercase;
        }

        .requiredmsgtext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fieldlabeltext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fieldlabeltextinvisible {
        display: none;
        }

        .fieldrequiredtext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fieldformattext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fieldformatboldtext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fielderrortext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fieldsmallboldtext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fieldsmalltext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }
        ');

        htp.p('
        .fieldmediumtext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fieldlargetext {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 110%;
        font-style: normal;
        text-align: left;
        }

        .fieldmediumtextbold {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        .fieldOrangetextbold {
        color: ORANGE;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }



        /* ANCHORS (LINKS)                                          */
        /* ======================================================== */
        A:link{color:#0000ff;text-decoration:none;}

        A:visited{color:#660099;text-decoration:none;}

        A:active{color:#990000;}

        A:hover{color:#990000;text-decoration:underline;}


        /* ANCHOR Definitions for Home Page MenuItems class.        */
        /* ======================================================== */
        A.menulinktext {
        font-family:  Verdana,Arial Narrow, helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        color:#0000ff;
        text-decoration: none;
        }


        A.submenulinktext {
        font-family:  Verdana,Arial Narrow, helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-transform: none;
        color:#0000ff;
        text-decoration: none;
        }

        A.submenulinktext:hover {
        background-color: #1E2B83;
        font-family:  verdana,Arial Narrow, helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: justify;
        text-transform: none;
        color: #FFFFFF;
        text-decoration: none;
        }

        A.submenulinktext:visited {
        font-family:  Verdana,Arial Narrow, helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-transform: none;
        color:#660099;
        text-decoration: none;
        }

        A.submenulinktext:visited:hover {
        background-color: #1E2B83;
        font-family:  Verdana,Arial Narrow, helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: justify;
        text-transform: none;
        color: #FFFFFF;
        text-decoration: none;
        }

        A.submenulinktext2 {
        font-weight: normal;
        font-size: 90%;
        color:#0000ff;
        text-decoration:none;
        }

        A.submenulinktext2:hover {
        font-weight: normal;
        font-size: 90%;
        color:#990000;
        text-decoration:underline;
        }

        A.submenulinktext2:visited {
        font-family:  Verdana,Arial Narrow, helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        color:#660099;;
        text-decoration: none;
        }

        A.submenulinktext2:visited:hover {
        font-family:  Verdana,Arial Narrow, helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        text-decoration:underline;
        color:#990000;
        }
        ');

        htp.p('


        A.whitespacelink
        {
        line-height: 200%;
        COLOR: #1E2B83;
        text-decoration: underline;
        }


        A.largelinktext {
        font-family: Verdana,Arial,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 110%;
        font-style: normal;
        text-align: left;
        text-decoration: underline;
        }


        A.sitemaplevel1 {
        font-family:  Verdana,Arial, helvetica, sans-serif;
        font-weight: bold;
        font-size: 80%;
        font-style: normal;
        text-align: left;
        text-decoration: none;
        color:       #1E2B83;
        }

        A.sitemaplevel1:visited {
        font-family: Verdana,Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 80%;
        font-style : normal;
        text-align : left;
        text-decoration: none;
        color:#660099;
        }

        A.sitemaplevel1:hover {
        font-family: Verdana,Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 80%;
        font-style : normal;
        text-align : left;
        text-decoration:underline;
        color:#990000;
        }


        A.sitemaplevel2 {
        font-family: Verdana,Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 70%;
        font-style: normal;
        text-align: left;
        text-decoration: none;
        color:#0000ff;
        }

        A.sitemaplevel2:visited {
        font-family:  Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 70%;
        font-style : normal;
        text-align : left;
        text-decoration: none;
        color:#660099;
        }

        A.sitemaplevel2:hover {
        font-family: Verdana,Arial,  helvetica, sans-serif;
        font-weight: bold;
        font-size  : 70%;
        font-style : normal;
        text-align : left;
        text-decoration:underline;
        color:#990000;
        }

        A.sitemaplevel3 {
        font-family: Verdana,Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 60%;
        font-style: normal;
        text-align: left;
        text-decoration: none;
        color:#0000ff;
        }

        A.sitemaplevel3:visited {
        font-family: Verdana,Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 60%;
        font-style : normal;
        text-align : left;
        text-decoration: none;
        color:#660099;
        }

        A.sitemaplevel3:hover {
        font-family: Verdana,Arial,  helvetica, sans-serif;
        font-weight: bold;
        font-size  : 70%;
        font-style : normal;
        text-align : left;
        color:#990000;
        text-decoration:underline;
        }


        /* ANCHOR Definitions for Home Page MenuItems class.        */
        /* ======================================================== */


        A.whitespacelink
        {
        line-height: 200%;
        color: black;
        text-decoration: underline;
        }


        A.largelinktext {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 120%;
        font-style: normal;
        text-align: left;
        text-decoration: underline;
        }


        A.sitemaplevel1 {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 80%;
        font-style: normal;
        text-align: left;
        text-decoration: none;
        color:#0000ff;
        }

        A.sitemaplevel1:visited {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 80%;
        font-style : normal;
        text-align : left;
        text-decoration: none;
        color:#660099;
        }

        A.sitemaplevel1:hover {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 80%;
        font-style : normal;
        text-align : left;
        text-decoration:underline;
        color:#990000;
        }


        A.sitemaplevel2 {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 80%;
        font-style: normal;
        text-align: left;
        text-decoration: none;
        color:#0000ff;
        }

        A.sitemaplevel2:visited {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 80%;
        font-style : normal;
        text-align : left;
        text-decoration: none;
        color:#660099;
        }

        A.sitemaplevel2:hover {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 80%;
        font-style : normal;
        text-align : left;
        text-decoration:underline;
        color:#990000;
        }

        A.sitemaplevel3 {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 60%;
        font-style: normal;
        text-align: left;
        text-decoration: none;
        color:#0000ff;
        }

        A.sitemaplevel3:visited {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 60%;
        font-style : normal;
        text-align : left;
        text-decoration: none;
        color:#660099;
        }

        A.sitemaplevel3:hover {
        font-family: Verdana, Arial,  helvetica, sans-serif;
        font-weight: normal;
        font-size  : 60%;
        font-style : normal;
        text-align : left;
        text-decoration: none;
        text-decoration:underline;
        color:#990000;
        }

        ');

        htp.p('
        .whitespace1{
        padding-top:0em;
        }

        .whitespace2{
        padding-top:1em;
        }
        .whitespace3{
        padding-top:2em;
        }
        .whitespace4{
        padding-top:3em;
        }

        /* BODY                                                     */
        /* ======================================================== */
        BODY {
        background-color: #FFFFFF;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-style: normal;
        text-align: left;
        /* BROWSER CONSIDERATION - Override browser settings for BODY margin */
        margin-top: 0px;
        margin-left: 1%;
        margin-right: 2%;
        background-repeat: no-repeat;
        }
        BODY.campuspipeline {
        background-color: #FFFFFF;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-style: normal;
        text-align: left;
        /* BROWSER CONSIDERATION - Override browser settings for BODY margin */
        margin-top: 6px;
        margin-left: 2%;
        background-image: none;
        background-repeat: no-repeat;
        }
        BODY.previewbody {
        background-color: #FFFFFF;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        margin-left: 2%;
        margin-right: 2%;

        /* Override the background image in the main BODY */
        background-image: none;
        }

        BODY.validationbody {
        background-color: #FFFFFF;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        margin-left: 0%;
        margin-right: 2%;
        /* Override the background image in the main BODY */
        background-image: none;
        }

        /* DIVIDES                                                  */
        /* All divides should have rules defined for margin and     */
        /* text-align.                                              */
        /* ======================================================== */
        DIV.menulistdiv {
        text-align: left;
        }

        DIV.headerwrapperdiv {

        margin-left: 0px;
        margin-top: 0px;
        }

        DIV.pageheaderdiv1 {

        text-align: left;
        margin-top: 8%;
        margin-left: 0px;
        border-bottom: 0px solid;
        border-left: 0px solid;
        border-right: 0px solid;
        border-top: 0px solid;

        }

        DIV.pageheaderdiv2 {
        text-align: right;
        margin-top: 10px;
        margin-right: 10px;
        position: absolute;
        top: 0px;
        right: 0px;
        float: right;
        display: none;

        }

        DIV.headerlinksdiv {
        text-align: left;
        margin-right: 0%;

        }

        /* Class for BANNER SEARCH Form text and button controls     */
        /* ========================================================  */
        DIV.headerlinksdiv2 {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        text-transform: none;
        }

        DIV.bodylinksdiv {
        text-align: center;
        margin-top: 1%;
        }

        DIV.footerlinksdiv {
        text-align: center;
        }

        DIV.backlinkdiv {
        text-align: right;
        margin-top: -40px;
        }

        DIV.pagetitlediv {
        text-align: left;
        }

        DIV.infotextdiv {
        text-align: left;
        }

        DIV.pagebodydiv {
        text-align: left;
        }
        ');

        htp.p('
        DIV.pagefooterdiv {
        text-align: left;
        border: 0px;
        margin-top: 0px;
        float: left;
        }

        DIV.poweredbydiv {
        text-align: right;
        margin-right: -1px;
        margin-top: 0px;
        border-bottom: 0px solid;
        border-left: 0px solid;
        border-right: 0px solid;
        border-top: 0px solid;
        float: right;
        }

        DIV.previewdiv {
        text-align: center;
        }

        DIV.validationdiv {
        text-align: center;
        }

        DIV.staticheaders {
        text-align: right;
        font-size:  90%;
        }
        /* HEADERS                                                  */
        /* Do not set font-size for headers - defer to browser.      */
        /* ======================================================== */
        /* H1 is reserved for Page Header */
        H1 {
        color: #FFFFFF;
        font-family: verdana, Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-style: normal;
        font-size:0%;
        margin-top: 0px;
        }


        /* H2 is reserved for Page Title */
        H2 {
        color       : BLACK;
        font-family: verdana, Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-style : normal;
        }

        /* H3 is reserved for Sub Title */
        H3 {
        color       : BLACK;
        font-family: verdana, Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-style : normal;
        }

        /* Horizontal Rule for Menu Section                         */
        /* ======================================================== */

        HR {
        /* color: #CCCC33; modificado 23-mayo-3008 MRM */
        color: #5992BE;
        text-align: left;
        vertical-align: top;
        margin-top: -10px;
        HEIGHT="2"
        }

        HR.pageseprator {
        /* color: #003366; modificado 23-mayo-3008 MRM */
        color: #5992BE;
        text-align: left;
        vertical-align: top;
        }


        /* FORM CONTROLS                                            */
        /* ======================================================== */
        INPUT {
        /*background-color: #FFFFFF;*/
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        }


        TEXTAREA {
        /*background-color: #FFFFFF;*/
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;

        }

        SELECT {
        /*background-color: #FFFFFF;*/
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        }



        /* TABLES                                                   */
        /* ======================================================== */
        TABLE.dataentrytable {
        border-bottom: 0px solid;
        border-left: 0px solid;
        border-right: 0px solid;
        border-top: 0px solid;
        }

        TABLE.datadisplaytable {
        border-bottom: 0px solid;
        border-left: 0px solid;
        border-right: 0px solid;
        border-top: 0px solid;
        }

        TABLE.plaintable {
        border-bottom: 0px solid;
        border-left: 0px solid;
        border-right: 0px solid;
        border-top: 0px solid;
        }

        TABLE.menuplaintable {
        /* Create a horizontal rule effect. */
        border-top: 1pt #707070 solid;
        }

        TABLE.pageheadertable {
        margin-top: 0px;
        }

        TABLE.colorsampletable {
        background-color: #FFFFFF;
        }

        TABLE.bordertable {
        border-collapse:collapse;
        border-bottom: 1px solid;
        border-left: 1px solid;
        border-right: 1px solid;
        border-top: 1px solid;
        }

        /* TABLE HEADERS AND DATA CELLS                             */
        /* ======================================================== */
        TABLE TH {
        vertical-align: top;
        color: black;
        }

        TABLE TD {
        vertical-align: top;
        color: black;
        }

        .pageheadertablecell {
        text-align: left;
        }

        .pageheadernavlinkstablecell {
        text-align: right;
        }

        /* DATA ENTRY TABLE HEADERS AND DATA CELLS                  */
        /* Some font rules are redunant because they do not         */
        /* inherit well from the BODY on older browsers.            */
        /* ======================================================== */
        TABLE TD.deheader {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TH.deheader {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.detitle {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /* Make titles big and chunky. */
        padding-bottom: 1em;
        }

        TABLE TH.detitle {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /* Make titles big and chunky. */
        padding-bottom: 1em;
        }

        TABLE TD.delabel {
        /*background-color: #E3E5EE;*/
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TH.delabel {
        /*background-color: #E3E5EE;*/
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.deseparator {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.dehighlight {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.dedead {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.dedefault {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.dewhite {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.deborder {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        border: 1px solid;

        }

        /* DATA DISPLAY TABLE HEADERS AND DATA CELLS                */
        /* Some font rules are redunant because they do not         */
        /* inherit well from the BODY on older browsers.            */
        /* ======================================================== */
        TABLE TD.ddheader {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TH.ddheader {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.ddtitle {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /* Make titles big and chunky. */
        padding-bottom: 1em;
        }

        TABLE TH.ddtitle {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /* Make titles big and chunky. */
        padding-bottom: 1em;
        }

        TABLE TD.ddlabel {
        /*background-color: #E3E5EE;*/
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TH.ddlabel {
        /*background-color: #E3E5EE;*/
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }


        TABLE TD.ddseparator {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.ddhighlight {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.dddead {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.dddefault {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /*border-bottom: 1pt #BFBFBF solid; */
        }

        TABLE TD.ddnontabular {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.ddwhite {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        /* PLAIN TABLE HEADERS AND DATA CELLS                       */
        /* These table data cell classes pertain to a table that is */
        /* used strictly for layout. They do not have the redundant */
        /* font rules because it is assumed that whatever is placed */
        /* in these TD/TH tags will have its own class.             */
        /* ======================================================== */
        TABLE TD.pltitle {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-weight: bold;
        }

        TABLE TD.plheader {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-size: 90%;
        font-weight: bold;
        }

        TABLE TH.pllabel {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-size: 90%;
        font-weight: bold;
        }

        TABLE TD.plseparator {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        }

        TABLE TD.plhighlight {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        }

        TABLE TD.pldead {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        }

        TABLE TD.pldefault {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        }

        TABLE TD.plwhite {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;

        }
        TABLE TD.plheaderlinks {
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;

        }


        /*========================================================*/
        /*=======  Class for header links=========================*/
        /*========================================================*/

        TABLE TD.plheadermenulinks {
        font-weight: normal;
        /*background-color:#CED5EA;*/
        }




        /* MENU PLAIN TABLE HEADERS AND DATA CELLS                  */
        /* ======================================================== */
        TABLE TD.mptitle {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.mpheader {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TH.mplabel {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.mpwhite {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.mpdefault {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.indefault {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        }

        /* Define tables with border                    */
        /* ======================================================== */
        TABLE TD.dbheader {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        border: 1px solid;
        }

        TABLE TH.dbheader {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        border: 1px solid;
        }

        TABLE TD.dbtitle {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /* Make titles big and chunky. */
        padding-bottom: 1em;
        border: 1px solid;
        }

        TABLE TH.dbtitle {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /* Make titles big and chunky. */
        padding-bottom: 1em;
        border: 1px solid;
        }

        TABLE TD.dblabel {
        /*background-color: #E3E5EE;*/
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        border: 1px solid;
        }

        TABLE TH.dblabel {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        border: 1px solid;
        }
        TABLE TD.dbdefault {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        border: 1px solid;
        }




        /* NON TABULAR TABLE DATA DISPLAY  HEADERS AND DATA CELLS  */
        /* Some font rules are redunant because they do not         */
        /* inherit well from the BODY on older browsers.            */
        /* ======================================================== */
        TABLE TD.ntheader {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TH.ntheader {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.nttitle {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /* Make titles big and chunky. */
        padding-bottom: 1em;
        }

        TABLE TH.nttitle {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        /* Make titles big and chunky. */
        padding-bottom: 1em;
        }

        TABLE TD.ntlabel {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TH.ntlabel {
        background-color: #E3E5EE;
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: bold;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.ntseparator {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.nthighlight {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.ntdead {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.ntdefault {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }

        TABLE TD.ntwhite {
        color: black;
        font-family: Verdana,Arial Narrow,  helvetica, sans-serif;
        font-weight: normal;
        font-size: 90%;
        font-style: normal;
        text-align: left;
        vertical-align: top;
        }
        /*

        New Tab styles for Self Service

        */
        .bgtabon {
            BACKGROUND-COLOR: #003366
        }
        .bgtaboff {
            BACKGROUND-COLOR: #cccccc
        }
        .texttabon {
            COLOR: #ffffff
        }
        .texttaboff {
            COLOR: #000000
        }
        .tabon {
            PADDING-LEFT: 8px; FONT-WEIGHT: bold; FONT-SIZE: 12px; COLOR: #ffffff; BACKGROUND-REPEAT: no-repeat; BACKGROUND-COLOR: #003366
        }
        .tabon A:link {
            COLOR: #ffffff; TEXT-DECORATION: none
        }
        .tabon A:visited {
            COLOR: #ffffff; TEXT-DECORATION: none
        }
        .tabon A:active {
            COLOR: #ffffff; TEXT-DECORATION: none
        }
        .tabon A:hover {
            COLOR: #ffffff; TEXT-DECORATION: none
        }
        .taboff {
            PADDING-LEFT: 8px;
              FONT-WEIGHT: bold;
              FONT-SIZE: 12px;
              BACKGROUND-IMAGE: url(/wtlgifs/web_tab_corner.gif);
              COLOR: #000000;
              BACKGROUND-REPEAT: no-repeat;
              BACKGROUND-COLOR: #cccccc
        }
        .taboff A:link {
            COLOR: #000000; TEXT-DECORATION: none
        }
        .taboff A:visited {
            COLOR: #000000; TEXT-DECORATION: none
        }
        .taboff A:active {
            COLOR: #000000; TEXT-DECORATION: none
        }
        .taboff A:hover {
            COLOR: #000000; TEXT-DECORATION: none
        }
        .bg3 {
            BACKGROUND-COLOR: #cccc00
        }
        --></style>
      ');
  END P_CSS;

END pk_bwcksmlt; -- Package Body bwcksmlt
/


DROP PUBLIC SYNONYM PK_BWCKSMLT;

CREATE PUBLIC SYNONYM PK_BWCKSMLT FOR BANINST1.PK_BWCKSMLT;


GRANT EXECUTE ON BANINST1.PK_BWCKSMLT TO WWW_USER;

GRANT EXECUTE ON BANINST1.PK_BWCKSMLT TO WWW2_USER;

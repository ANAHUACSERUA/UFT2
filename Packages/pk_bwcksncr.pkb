DROP PACKAGE BODY BANINST1.PK_BWCKSNCR;

CREATE OR REPLACE PACKAGE BODY BANINST1.pk_bwcksncr
AS
--AUDIT_TRAIL_MSGKEY_UPDATE
-- PROJECT : MSGKEY
-- MODULE  : BWCKSNC1
-- SOURCE  : enUS
-- TARGET  : I18N
-- DATE    : Thu Apr 22 13:18:09 2010
-- MSGSIGN : #3f982a935992e638
--TMI18N.ETR DO NOT CHANGE--
--
-- FILE NAME..: bwcksnc1.sql
-- RELEASE....: 8.4.0.1
-- OBJECT NAME: bwcksncr
-- PRODUCT....: SCOMWEB
-- USAGE......:
-- COPYRIGHT..: Copyright(C) 2009 SunGard. All rights reserved.
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
-- Main processing of this package is for display
-- of existing compliance evaluations on the system.
--
-- FUNCTIONS AND PROCEDURES :
--
-- DESCRIPTION END
--

   pidm                    SPRIDEN.SPRIDEN_PIDM%TYPE;
   curr_release            CONSTANT VARCHAR2 (10)             := '8.4.0.1';
   global_pidm             SPRIDEN.SPRIDEN_PIDM%TYPE;
   smbpogn_row             SMBPOGN%ROWTYPE;
   smbwcrl_row             SMBWCRL%ROWTYPE;
   smrcprt_row             SMRCPRT%ROWTYPE;
   -- Common Label section.
   -- If change required, change label only.
   -- Labels current for bwcksncr.P_DispAdditional only.
   -- Used for internationalization/Customization of CAPP
   -- Terminology.
   --
   lbl_ncr                 VARCHAR2 (50)
      DEFAULT g$_nls.get ('BWCKSNC1-0000',
                 'SQL',
                 'Program Non-Course Requirements - '
              );
   lbl_pra                 VARCHAR2 (50)
      DEFAULT g$_nls.get ('BWCKSNC1-0001',
                 'SQL',
                 'Program Required Attributes - '
              );
   lbl_ipcrse              VARCHAR2 (30)
               DEFAULT g$_nls.get ('BWCKSNC1-0002',
                          'SQL',
                          'In-Progress Courses'
                       );
   lbl_plan_crse           VARCHAR2 (30)
                   DEFAULT g$_nls.get ('BWCKSNC1-0003',
                              'SQL',
                              'Planned Courses'
                           );
   lbl_unused_crse         VARCHAR2 (30)
                  DEFAULT g$_nls.get ('BWCKSNC1-0004',
                             'SQL',
                             'Courses Not Used'
                          );
   lbl_unused_attr         VARCHAR2 (40)
        DEFAULT g$_nls.get ('BWCKSNC1-0005',
                   'SQL',
                   'Course Attributes Not Used'
                );
   lbl_rej_crse            VARCHAR2 (25)
                  DEFAULT g$_nls.get ('BWCKSNC1-0006',
                             'SQL',
                             'Rejected Courses'
                          );
   lbl_incl_levl           VARCHAR2 (55)
      DEFAULT g$_nls.get ('BWCKSNC1-0007',
                 'SQL',
                 'Program Included or Excluded Levels'
              );
   lbl_restr_grde          VARCHAR2 (55)
         DEFAULT g$_nls.get ('BWCKSNC1-0008',
                    'SQL',
                    'Program Restricted Grades'
                 );
   lbl_restr_subj_attr     VARCHAR2 (55)
      DEFAULT g$_nls.get ('BWCKSNC1-0009',
                 'SQL',
                 'Program Restricted Subjects and Attributes'
              );
   lbl_met                 VARCHAR2 (10)
                               DEFAULT g$_nls.get ('BWCKSNC1-0010',
                                          'SQL',
                                          'Met'
                                       );
   lbl_desc                VARCHAR2 (20)
                       DEFAULT g$_nls.get ('BWCKSNC1-0011',
                                  'SQL',
                                  'Description'
                               );
   lbl_yrlmt               VARCHAR2 (20)
                        DEFAULT g$_nls.get ('BWCKSNC1-0012',
                                   'SQL',
                                   'Year Limit'
                                );
   lbl_stcd                VARCHAR2 (20)
                            DEFAULT g$_nls.get ('BWCKSNC1-0013',
                                       'SQL',
                                       'Status'
                                    );
   lbl_stdt                VARCHAR2 (20)
                       DEFAULT g$_nls.get ('BWCKSNC1-0014',
                                  'SQL',
                                  'Status Date'
                               );
   lbl_action              VARCHAR2 (15)
                            DEFAULT g$_nls.get ('BWCKSNC1-0015',
                                       'SQL',
                                       'Action'
                                    );
   lbl_crsattr             VARCHAR2 (30)
                  DEFAULT g$_nls.get ('BWCKSNC1-0016',
                             'SQL',
                             'Course Attribute'
                          );
   lbl_stuatts             VARCHAR2 (30)
                 DEFAULT g$_nls.get ('BWCKSNC1-0017',
                            'SQL',
                            'Student Attribute'
                         );
   lbl_reqcrds             VARCHAR2 (25)
                  DEFAULT g$_nls.get ('BWCKSNC1-0018',
                             'SQL',
                             'Required Credits'
                          );
   lbl_reqcrse             VARCHAR2 (25)
                  DEFAULT g$_nls.get ('BWCKSNC1-0019',
                             'SQL',
                             'Required Courses'
                          );
   lbl_actcrds             VARCHAR2 (25)
                    DEFAULT g$_nls.get ('BWCKSNC1-0020',
                               'SQL',
                               'Actual Credits'
                            );
   lbl_actcrse             VARCHAR2 (25)
                    DEFAULT g$_nls.get ('BWCKSNC1-0021',
                               'SQL',
                               'Actual Courses'
                            );
   lbl_area                VARCHAR2 (15)
                              DEFAULT g$_nls.get ('BWCKSNC1-0022',
                                         'SQL',
                                         'Area'
                                      );
   lbl_group               VARCHAR2 (15)
                             DEFAULT g$_nls.get ('BWCKSNC1-0023',
                                        'SQL',
                                        'Group'
                                     );
   lbl_subj                VARCHAR2 (15)
                           DEFAULT g$_nls.get ('BWCKSNC1-0024',
                                      'SQL',
                                      'Subject'
                                   );
   lbl_crse                VARCHAR2 (15)
                            DEFAULT g$_nls.get ('BWCKSNC1-0025',
                                       'SQL',
                                       'Course'
                                    );
   lbl_crds                VARCHAR2 (15)
                           DEFAULT g$_nls.get ('BWCKSNC1-0026',
                                      'SQL',
                                      'Credits'
                                   );
   lbl_attr                VARCHAR2 (15)
                         DEFAULT g$_nls.get ('BWCKSNC1-0027',
                                    'SQL',
                                    'Attribute'
                                 );
   lbl_title               VARCHAR2 (15)
                             DEFAULT g$_nls.get ('BWCKSNC1-0028',
                                        'SQL',
                                        'Title'
                                     );
   lbl_term                VARCHAR2 (10)
                              DEFAULT g$_nls.get ('BWCKSNC1-0029',
                                         'SQL',
                                         'Term'
                                      );
   lbl_grde                VARCHAR2 (15)
                             DEFAULT g$_nls.get ('BWCKSNC1-0030',
                                        'SQL',
                                        'Grade'
                                     );
   lbl_reason              VARCHAR2 (15)
                            DEFAULT g$_nls.get ('BWCKSNC1-0031',
                                       'SQL',
                                       'Reason'
                                    );
   lbl_lvl                 VARCHAR2 (10)
                             DEFAULT g$_nls.get ('BWCKSNC1-0032',
                                        'SQL',
                                        'Level'
                                     );
   lbl_inclexcl            VARCHAR2 (30)
                DEFAULT g$_nls.get ('BWCKSNC1-0033',
                           'SQL',
                           'Include or Exclude'
                        );
   lbl_mingrde             VARCHAR2 (25)
                     DEFAULT g$_nls.get ('BWCKSNC1-0034',
                                'SQL',
                                'Minimum Grade'
                             );
   lbl_maxcrds             VARCHAR2 (25)
                   DEFAULT g$_nls.get ('BWCKSNC1-0035',
                              'SQL',
                              'Maximum Credits'
                           );
   lbl_maxcrse             VARCHAR2 (25)
                   DEFAULT g$_nls.get ('BWCKSNC1-0036',
                              'SQL',
                              'Maximum Courses'
                           );
   lbl_camp                VARCHAR2 (15)
                            DEFAULT g$_nls.get ('BWCKSNC1-0037',
                                       'SQL',
                                       'Campus'
                                    );
   lbl_coll                VARCHAR2 (15)
                           DEFAULT g$_nls.get ('BWCKSNC1-0038',
                                      'SQL',
                                      'College'
                                   );
   lbl_dept                VARCHAR2 (20)
                        DEFAULT g$_nls.get ('BWCKSNC1-0039',
                                   'SQL',
                                   'Department'
                                );
   lbl_low                 VARCHAR2 (10)
                               DEFAULT g$_nls.get ('BWCKSNC1-0040',
                                          'SQL',
                                          'Low'
                                       );
   lbl_high                VARCHAR2 (10)
                              DEFAULT g$_nls.get ('BWCKSNC1-0041',
                                         'SQL',
                                         'High'
                                      );
   lbl_program             VARCHAR2 (30)
                        DEFAULT g$_nls.get ('BWCKSNC1-0042',
                                   'SQL',
                                   'Program : '
                                );

-------------------------------------------
--
-- Cursor Section
--
-------------------------------------------
--
-- Gets program overall results.
--
   CURSOR SMBPOGN_C (
      pidm         IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smbpogn.smbpogn_request_no%TYPE
   )
   IS
      SELECT *
        FROM smbpogn
       WHERE smbpogn_pidm = pidm
         AND smbpogn_request_no = request_no;

-------------------------------------------
--
-- Gets webcapp display rules information from form SMAWCRL
--
   CURSOR smbwcrl_c (term_in IN STVTERM.STVTERM_CODE%TYPE)
   IS
      SELECT *
        FROM SMBWCRL
       WHERE SMBWCRL_TERM_CODE =
              (SELECT MAX (X.SMBWCRL_TERM_CODE)
                 FROM SMBWCRL X
                WHERE SMBWCRL_TERM_CODE <= term_in);

-------------------------------------------
--
-- Hardcopy output rules type.
--
   CURSOR smrcprt_c (cprt_code_in IN SMRCPRT.SMRCPRT_CPRT_CODE%TYPE)
   IS
      SELECT *
        FROM SMRCPRT
       WHERE SMRCPRT_CPRT_CODE = cprt_code_in;

-------------------------------------------
--
-- In Progress Course Cursor
-- Cursor taken from smrcrlt.pc cursor name
-- 'in_prog_courses'
--
-- 7.3.3.1 1-1GE4WY. Don't need to add smrdous_crse_source
-- because all courses are IP.
--
   CURSOR ip_smrdous_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE,
      program_in   IN   smrdous.smrdous_program%TYPE
   )
   IS
      SELECT SMRDOUS_AREA, SMRDOUS_GROUP, SMRDOUS_KEY_RULE, SMRDOUS_SUBJ_CODE,
             SMRDOUS_CRSE_NUMB, SMRDOUS_CREDIT_HOURS, SMRDOUS_ATTR_CODE
        FROM SMRDOUS
       WHERE SMRDOUS_PIDM = pidm_in
         AND SMRDOUS_REQUEST_NO = request_no
         AND SMRDOUS_PROGRAM = program_IN
         AND SMRDOUS_CRSE_SOURCE = 'R'
       ORDER BY SMRDOUS_AREA,
                SMRDOUS_GROUP,
                SMRDOUS_SUBJ_CODE ASC,
                SMRDOUS_CRSE_NUMB ASC,
                SMRDOUS_TERM_CODE ASC,
                SMRDOUS_TITLE,
                SMRDOUS_ATTR_CODE ASC,
                SMRDOUS_GRDE_CODE ASC,
                SMRDOUS_CREDIT_HOURS_USED DESC;

-------------------------------------------
--
-- Planned Course cursor.
-- Cursor taken from smrcrlt.pc cursor name
-- 'planned courses'
--
   CURSOR smrpcrs_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE
   )
   IS
      SELECT SMRPCRS_TERM_CODE, SMRPCRS_SUBJ_CODE, SMRPCRS_CRSE_NUMB,
             SMRPCRS_LEVL_CODE, SMRPCRS_CREDIT_HR, SMRPCRS_TITLE,
             SMRPCRS_ATTR_CODE
        FROM SMRPCRS
       WHERE SMRPCRS_PIDM = pidm_in
         AND SMRPCRS_REQUEST_NO = request_no
       ORDER BY SMRPCRS_SUBJ_CODE ASC,
                SMRPCRS_CRSE_NUMB ASC,
                SMRPCRS_ATTR_CODE ASC;

-------------------------------------------
--
-- Non Course Requirements Cursor
--
   CURSOR smrponc_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE
   )
   IS
      SELECT DISTINCT *
        FROM SMRPONC
       WHERE SMRPONC_PIDM = pidm_in
         AND SMRPONC_REQUEST_NO = request_no
       ORDER BY SMRPONC_NCRQ_CODE;

-------------------------------------------
--
-- Program Required Attributes Cursor
--
   CURSOR smrpoat_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE
   )
   IS
      SELECT DISTINCT *
        FROM SMRPOAT
       WHERE SMRPOAT_PIDM = pidm_in
         AND SMRPOAT_REQUEST_NO = request_no
       ORDER BY SMRPOAT_ATTR_CODE, SMRPOAT_ATTS_CODE;

-------------------------------------------
--
-- Courses Not Used Cursor.
-- Cursor taken from smrcrlt.pc cursor name
-- 'program_courses_not_used'
--
-- 7.3.3.1 1-1GE4WY.  Add smrdocn_crse_source to cursor.
--

   CURSOR smrdocn_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE,
      program_in   IN   smrdous.smrdous_program%TYPE
   )
   IS
      SELECT SMRDOCN_SUBJ_CODE, SMRDOCN_CRSE_NUMB, SMRDOCN_CRSE_TITLE,
             SMRDOCN_GRDE_CODE, SMRDOCN_TERM_CODE, SMRDOCN_CREDIT_HOURS_AVAIL,
             SMRDOCN_CRSE_SOURCE
        FROM SMRDOCN
       WHERE SMRDOCN_PROGRAM = program_in
         AND SMRDOCN_PIDM = pidm_in
         AND SMRDOCN_REQUEST_NO = request_no
       order by smrdocn_subj_code,
                smrdocn_crse_numb,
                smrdocn_term_code,
                smrdocn_crse_title,
                smrdocn_grde_code;

-------------------------------------------
--
-- Attributes not Used Cursor.
-- Cursor taken from smrcrlt.pc cursor name
-- 'program_attributes_not_used'
--
-- 7.3.3.1 1-1GE4WY.  Add smrdoan_crse_source to cursor.
--
   CURSOR smrdoan_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE,
      program_in   IN   smrdous.smrdous_program%TYPE
   )
   IS
      SELECT SMRDOAN_ATTR_CODE, SMRDOAN_SUBJ_CODE, SMRDOAN_CRSE_NUMB,
             SMRDOAN_CRSE_TITLE, SMRDOAN_GRDE_CODE, SMRDOAN_TERM_CODE,
             SMRDOAN_CREDIT_HOURS_USED, SMRDOAN_CRSE_SOURCE
        FROM SMRDOAN
       WHERE SMRDOAN_PROGRAM = program_in
         AND SMRDOAN_PIDM = pidm_in
         AND SMRDOAN_REQUEST_NO = request_no
       order by smrdoan_attr_code,
                smrdoan_subj_code,
                smrdoan_crse_numb,
                smrdoan_term_code,
                smrdoan_crse_title,
                smrdoan_grde_code;

-------------------------------------------
--
-- Rejected Courses Cursor.
-- Cursor taken from smrcrlt.pc cursor name
-- 'rejected_courses'
--
   CURSOR smrdorj_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE
   )
   IS
      SELECT SMRDORJ_TERM_CODE, SMRDORJ_SUBJ_CODE, SMRDORJ_CRSE_NUMB,
             SMRDORJ_AREA, SMRDORJ_GROUP, SMRDORJ_KEY_RULE,
             SMRDORJ_REJECTION_REASON, SMRDORJ_ATTR_CODE
        FROM SMRDORJ
       WHERE SMRDORJ_PIDM = pidm_in
         AND SMRDORJ_REQUEST_NO = request_no
       ORDER BY SMRDORJ_AREA ASC,
                SMRDORJ_GROUP ASC,
                SMRDORJ_KEY_RULE ASC,
                SMRDORJ_SUBJ_CODE ASC,
                SMRDORJ_CRSE_NUMB ASC,
                SMRDORJ_ATTR_CODE ASC;

-------------------------------------------
--
-- Include/Exclude additional levels cursor.
-- Cursor taken from smrcrlt.pc cursor name
-- 'program_incl_excl_levels'
--
   CURSOR smrpolv_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE
   )
   IS
      SELECT SMRPOLV_LEVL_CODE, SMRPOLV_SOURCE_IND, SMRPOLV_TERM_CODE_EFF,
             SMRPOLV_INCL_EXCL_IND, SMRPOLV_GRDE_CODE_MIN,
             SMRPOLV_MAX_CREDITS, SMRPOLV_CONNECTOR_MAX, SMRPOLV_MAX_COURSES,
             SMRPOLV_ACT_CREDITS, SMRPOLV_ACT_COURSES, SMRPOLV_ACTN_CODE
        FROM SMRPOLV
       WHERE SMRPOLV_PIDM = pidm_in
         AND SMRPOLV_REQUEST_NO = request_no
       ORDER BY SMRPOLV_LEVL_CODE;

-------------------------------------------
--
-- Program Restricted Grades cursor.
-- Cursor taken from smrcrlt.pc cursor name
-- 'program_restricted_grades'
--
   CURSOR smrpogd_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE
   )
   IS
      SELECT SMRPOGD_GRDE_CODE, SMRPOGD_SOURCE_IND, SMRPOGD_TERM_CODE_EFF,
             SMRPOGD_MAX_CREDITS, SMRPOGD_CONNECTOR_MAX, SMRPOGD_MAX_COURSES,
             SMRPOGD_ACT_CREDITS, SMRPOGD_ACT_COURSES, SMRPOGD_ACTN_CODE
        FROM SMRPOGD
       WHERE SMRPOGD_PIDM = pidm_in
         AND SMRPOGD_REQUEST_NO = request_no;

-------------------------------------------
--
-- Program Restricted Subjects & Attributes cursor.
-- Cursor taken from smrcrlt.pc cursor name
-- 'program_restr_subj_attr'
--
   CURSOR smrposa_c (
      pidm_in      IN   spriden.spriden_pidm%TYPE,
      request_no   IN   smrdous.smrdous_request_no%TYPE
   )
   IS
      SELECT SMRPOSA_PROGRAM, SMRPOSA_SOURCE_IND, SMRPOSA_TERM_CODE_EFF,
             SMRPOSA_SUBJ_CODE, SMRPOSA_CRSE_NUMB_LOW, SMRPOSA_CRSE_NUMB_HIGH,
             SMRPOSA_ATTR_CODE, SMRPOSA_CAMP_CODE, SMRPOSA_COLL_CODE,
             SMRPOSA_DEPT_CODE, SMRPOSA_MAX_CREDITS, SMRPOSA_CONNECTOR_MAX,
             SMRPOSA_MAX_COURSES, SMRPOSA_ACT_CREDITS, SMRPOSA_ACT_COURSES,
             SMRPOSA_ACTN_CODE, SMRPOSA_PRSA_SEQNO
        FROM SMRPOSA
       WHERE SMRPOSA_PIDM = pidm_in
         AND SMRPOSA_REQUEST_NO = request_no
       ORDER BY smrposa_camp_code,
                smrposa_coll_code,
                smrposa_dept_code,
                smrposa_subj_code,
                smrposa_crse_numb_low,
                smrposa_attr_code;

-------------------------------------------
--
-- Function Section
--
-------------------------------------------

   FUNCTION get_actn_desc (param1 IN stvactn.stvactn_code%TYPE)
      RETURN stvactn.stvactn_desc%TYPE
   IS
      return_value   stvactn.stvactn_desc%TYPE DEFAULT NULL;
   BEGIN
      SELECT stvactn_desc
        INTO return_value
        FROM stvactn
       WHERE stvactn_code = param1;
      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END get_actn_desc;

-------------------------------------------

   FUNCTION get_ncrq_desc (param1 IN stvncrq.stvncrq_code%TYPE)
      RETURN stvncrq.stvncrq_desc%TYPE
   IS
      return_value   stvncrq.stvncrq_desc%TYPE DEFAULT NULL;
   BEGIN
      SELECT stvncrq_desc
        INTO return_value
        FROM stvncrq
       WHERE stvncrq_code = param1;
      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END get_ncrq_desc;

-------------------------------------------

   FUNCTION get_ncst_desc (param1 IN stvncst.stvncst_code%TYPE)
      RETURN stvncst.stvncst_desc%TYPE
   IS
      return_value   stvncst.stvncst_desc%TYPE DEFAULT NULL;
   BEGIN
      SELECT stvncst_desc
        INTO return_value
        FROM stvncst
       WHERE stvncst_code = param1;
      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END get_ncst_desc;

--------------------------------------------------

   FUNCTION get_attr_desc (param1 IN stvattr.stvattr_code%TYPE)
      RETURN stvattr.stvattr_desc%TYPE
   IS
      return_value   stvattr.stvattr_desc%TYPE DEFAULT NULL;
   BEGIN
      SELECT stvattr_desc
        INTO return_value
        FROM stvattr
       WHERE stvattr_code = param1;
      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END get_attr_desc;

--------------------------------------------------


   FUNCTION get_atts_desc (param1 IN stvatts.stvatts_code%TYPE)
      RETURN stvatts.stvatts_desc%TYPE
   IS
      return_value   stvatts.stvatts_desc%TYPE DEFAULT NULL;
   BEGIN
      SELECT stvatts_desc
        INTO return_value
        FROM stvatts
       WHERE stvatts_code = param1;
      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END get_atts_desc;

--------------------------------------------------
--
-- Returns TRUE if In Progress courses exist
-- for Student/Request number.
--
   FUNCTION f_ip_crse_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE,
      param3   IN   SMRDOUS.SMRDOUS_PROGRAM%TYPE
   )
      RETURN BOOLEAN
   IS
      return_value   BOOLEAN DEFAULT FALSE;
      cnt            NUMBER  DEFAULT 0;
   BEGIN
      FOR i IN ip_smrdous_c (param1, param2, param3)
      LOOP
         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         return_value := FALSE;
      ELSIF cnt >= 1
      THEN
         return_value := TRUE;
      END IF;

      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END f_ip_crse_exists;

-------------------------------------------
--
-- Returns TRUE if Planned Courses exist
-- for Student/Request number.
--
   FUNCTION f_planned_crse_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN
   IS
      return_value   BOOLEAN DEFAULT FALSE;
      cnt            NUMBER  DEFAULT 0;
   BEGIN
      FOR i IN smrpcrs_c (param1, param2)
      LOOP
         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         return_value := FALSE;
      ELSIF cnt >= 1
      THEN
         return_value := TRUE;
      END IF;

      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END f_planned_crse_exists;

-------------------------------------------
--
-- Returns TRUE if unused courses exist
-- for Student/Request number.
--
   FUNCTION f_unused_crse_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE,
      param3   IN   SMRDOUS.SMRDOUS_PROGRAM%TYPE
   )
      RETURN BOOLEAN
   IS
      return_value   BOOLEAN DEFAULT FALSE;
      cnt            NUMBER  DEFAULT 0;
   BEGIN
      FOR i IN smrdocn_c (param1, param2, param3)
      LOOP
         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         return_value := FALSE;
      ELSIF cnt >= 1
      THEN
         return_value := TRUE;
      END IF;

      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END f_unused_crse_exists;

-------------------------------------------
--
-- Returns TRUE if unused attributes exist
-- for Student/Request number.
--
   FUNCTION f_unused_attr_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE,
      param3   IN   SMRDOUS.SMRDOUS_PROGRAM%TYPE
   )
      RETURN BOOLEAN
   IS
      return_value   BOOLEAN DEFAULT FALSE;
      cnt            NUMBER  DEFAULT 0;
   BEGIN
      FOR i IN smrdoan_c (param1, param2, param3)
      LOOP
         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         return_value := FALSE;
      ELSIF cnt >= 1
      THEN
         return_value := TRUE;
      END IF;

      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END f_unused_attr_exists;

-------------------------------------------
--
-- Returns TRUE if Rejected courses exist
-- for Student/Request number.
--
   FUNCTION f_reject_crse_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN
   IS
      return_value   BOOLEAN DEFAULT FALSE;
      cnt            NUMBER  DEFAULT 0;
   BEGIN
      FOR i IN smrdorj_c (param1, param2)
      LOOP
         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         return_value := FALSE;
      ELSIF cnt >= 1
      THEN
         return_value := TRUE;
      END IF;

      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END f_reject_crse_exists;

-------------------------------------------
--
-- Returns TRUE if additional levels exist
-- for Student/Request number.
--
   FUNCTION f_prog_incl_excl_lvl_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN
   IS
      return_value   BOOLEAN DEFAULT FALSE;
      cnt            NUMBER  DEFAULT 0;
   BEGIN
      FOR i IN smrpolv_c (param1, param2)
      LOOP
         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         return_value := FALSE;
      ELSIF cnt >= 1
      THEN
         return_value := TRUE;
      END IF;

      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END f_prog_incl_excl_lvl_exists;

-------------------------------------------
--
-- Returns TRUE if Restricted Grades exist
-- for Student/Request number.
--
   FUNCTION f_prog_restr_grde_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN
   IS
      return_value   BOOLEAN DEFAULT FALSE;
      cnt            NUMBER  DEFAULT 0;
   BEGIN
      FOR i IN smrpogd_c (param1, param2)
      LOOP
         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         return_value := FALSE;
      ELSIF cnt >= 1
      THEN
         return_value := TRUE;
      END IF;

      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END f_prog_restr_grde_exists;

-------------------------------------------
--
-- Returns TRUE if Restricted subjects or Attributes exist
-- for Student/Request number.
--
   FUNCTION f_prog_restr_subj_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN
   IS
      return_value   BOOLEAN DEFAULT FALSE;
      cnt            NUMBER  DEFAULT 0;
   BEGIN
      FOR i IN smrposa_c (param1, param2)
      LOOP
         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         return_value := FALSE;
      ELSIF cnt >= 1
      THEN
         return_value := TRUE;
      END IF;

      RETURN return_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN return_value;
   END f_prog_restr_subj_exists;

-------------------------------------------
--
-- Procedure Section
--
-------------------------------------------
--
-- Main Web Page. Calls procedures to display
-- Third page ( additional ) compliance information.
--

   PROCEDURE P_DispEvalAdditional(psReclDesc VARCHAR2)
   IS
      call_path      VARCHAR2 (2)                       DEFAULT NULL;
      hold_term      STVTERM.STVTERM_CODE%TYPE;
      student_name   VARCHAR2 (185);
      confid_msg     VARCHAR2 (100);
      email          GOREMAL.GOREMAL_EMAIL_ADDRESS%TYPE;
      namestr        VARCHAR2 (90)                      DEFAULT NULL;
      advr_pidm      SPRIDEN.SPRIDEN_PIDM%TYPE          DEFAULT NULL;
      info_exists    BOOLEAN                            DEFAULT FALSE;
      req_no         SMRRQCM.SMRRQCM_REQUEST_NO%TYPE    DEFAULT NULL;
      use_hardcopy   BOOLEAN                            DEFAULT FALSE;
      lv_request_no  SMRRQCM.SMRRQCM_REQUEST_NO%TYPE;
      lv_printer_friendly VARCHAR2(1);
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

       htp.p(
       '<script type="text/javascript"><!--
	      function fImprimeReporte() {
	      window.focus()
	      print();
	      }
	      //--></script>

       </head><body><br/>

       <table border="0" width="100%">
       <tr><th>'||psReclDesc||'</th></tr>
       <tr><th>'||vsTerm    ||' '||pk_Catalogo.Periodo(vsTerm)||'</th></tr>
       <tr><td>&nbsp;</td></tr>
       <tr><td>'||vsExpd||' '||vsNombre||'</td></tr>
       </table>

       <hr>');

      twbkwbis.P_DispInfo ('bwcksncr.P_DispEvalAdditional', 'DEFAULT');
      --
      -- The following Three cursors retrieves basic compliance
      -- results and information on how to build the output.
      --
      -- Defect 1-B9N55D
      --
      lv_request_no       := request_no;
      lv_printer_friendly := printer_friendly;
      --
      OPEN SMBPOGN_C (pidm, request_no);
      FETCH SMBPOGN_C INTO smbpogn_row;
      CLOSE SMBPOGN_C;
      req_no := smbpogn_row.smbpogn_request_no;
      OPEN smbwcrl_c (hold_term);
      FETCH smbwcrl_c INTO smbwcrl_row;
      CLOSE smbwcrl_c;

      -- If using a compliance type to build evaluation output,
      -- get this data now.

      IF smbwcrl_row.smbwcrl_dflt_eval_cprt_code IS NOT NULL
      THEN
         OPEN smrcprt_c (smbwcrl_row.smbwcrl_dflt_eval_cprt_code);
         FETCH smrcprt_c INTO smrcprt_row;
         CLOSE smrcprt_c;
         use_hardcopy := TRUE;
      END IF;

      HTP.br;
      twbkfrmt.P_PrintHeader (
         '3',
         lbl_program ||
            bwcksmlt.get_program_desc (smbpogn_row.smbpogn_program)
      );

-- --------------------------------------------------------------------
--
-- The following "X" procedures are the basis for displaying
-- 'additional' compliance information to the third page
-- of results.
-- 1) Each "Section" can be moved/commented out for customization
--    of display.
-- 2) Each Section first test whether information is present
--    for said section.  If no data - don't display the table.
-- 3) Output can be based upon hardcopy rules ( SMACPRT/SMRCPRT ).
--    If using a compliance type to build this output, check
--    corresponding SMRCPRT% field to test if we should be displaying
--    this 'section'.
--
-- --------------------------------------------------------------------

-- -------------------------------------------------
-- Non-Course Requirement Section.
--
      IF smbpogn_row.smbpogn_ncrse_req_met_ind <> 'Z'
      THEN
         IF use_hardcopy
         THEN
            IF    (
                         (smbpogn_row.smbpogn_ncrse_req_met_ind = 'Y')
                     AND (smrcprt_row.smrcprt_pncr_met_ind = 'Y')
                  )
               OR (
                         (smbpogn_row.smbpogn_ncrse_req_met_ind = 'N')
                     AND (smrcprt_row.smrcprt_pncr_nmet_ind <> '2')
                  )
            THEN
               p_display_ncr (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_ncr (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- Required Attribute Section.
      IF smbpogn_row.smbpogn_attr_req_met_ind <> 'Z'
      THEN
         IF use_hardcopy
         THEN
            IF    (
                         (smbpogn_row.smbpogn_attr_req_met_ind = 'Y')
                     AND (smrcprt_row.smrcprt_patr_met_ind = 'Y')
                  )
               OR (
                         (smbpogn_row.smbpogn_attr_req_met_ind = 'N')
                     AND (smrcprt_row.smrcprt_patr_nmet_ind <> '2')
                  )
            THEN
               p_display_prog_attr (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_prog_attr (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- In-Progress Course Section.
      IF f_ip_crse_exists (
            smbpogn_row.smbpogn_pidm,
            smbpogn_row.smbpogn_request_no,
            smbpogn_row.smbpogn_program
         )
      THEN
         IF use_hardcopy
         THEN
            IF smrcprt_row.smrcprt_in_prog_term_ind = 'Y'
            THEN
               p_display_ip_course (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_ip_course (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- Planned-Course Section.
      IF f_planned_crse_exists (
            smbpogn_row.smbpogn_pidm,
            smbpogn_row.smbpogn_request_no
         )
      THEN
         IF use_hardcopy
         THEN
            IF smrcprt_row.smrcprt_planned_crse_prt_ind = 'Y'
            THEN
               p_display_plan_crse (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_plan_crse (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- Unused-Course Section.
      IF f_unused_crse_exists (
            smbpogn_row.smbpogn_pidm,
            smbpogn_row.smbpogn_request_no,
            smbpogn_row.smbpogn_program
         )
      THEN
         IF use_hardcopy
         THEN
            IF smrcprt_row.smrcprt_unused_crse_prt_ind = 'Y'
            THEN
               p_display_courses_not_used (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_courses_not_used (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- Unused Attribute Section.
      IF f_unused_attr_exists (
            smbpogn_row.smbpogn_pidm,
            smbpogn_row.smbpogn_request_no,
            smbpogn_row.smbpogn_program
         )
      THEN
         IF use_hardcopy
         THEN
            IF smrcprt_row.smrcprt_unused_crse_prt_ind = 'Y'
            THEN
               p_display_attr_not_used (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_attr_not_used (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- Rejected Course Section.
      IF f_reject_crse_exists (
            smbpogn_row.smbpogn_pidm,
            smbpogn_row.smbpogn_request_no
         )
      THEN
         IF use_hardcopy
         THEN
            IF smrcprt_row.smrcprt_rej_crse_prt_ind = 'Y'
            THEN
               p_display_rejected (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_rejected (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- Program Additional Levels Section.
      IF f_prog_incl_excl_lvl_exists (
            smbpogn_row.smbpogn_pidm,
            smbpogn_row.smbpogn_request_no
         )
      THEN
         IF use_hardcopy
         THEN
            IF smrcprt_row.smrcprt_plvl_ind <> '2'
            THEN
               p_display_incl_excl_lvl (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_incl_excl_lvl (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- Program Restricted Grades Section.
      IF f_prog_restr_grde_exists (
            smbpogn_row.smbpogn_pidm,
            smbpogn_row.smbpogn_request_no
         )
      THEN
         IF use_hardcopy
         THEN
            IF smrcprt_row.smrcprt_prgd_ind <> '2'
            THEN
               p_display_restr_grde (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_restr_grde (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------

-- -------------------------------------------------
-- Program Restricted Subjects & Attributes Section.
      IF f_prog_restr_subj_exists (
            smbpogn_row.smbpogn_pidm,
            smbpogn_row.smbpogn_request_no
         )
      THEN
         IF use_hardcopy
         THEN
            IF smrcprt_row.smrcprt_prsa_ind <> '2'
            THEN
               p_display_restr_subj_attr (lv_printer_friendly);
               HTP.br;
               info_exists := TRUE;
            END IF;
         ELSE
            p_display_restr_subj_attr (lv_printer_friendly);
            HTP.br;
            info_exists := TRUE;
         END IF;
      END IF;

-- Done
-- ------------------------------------------------
--
-- If no 'additional information' is available for display,
-- print informational message to screen indicating so.
--
      IF NOT info_exists
      THEN
         twbkwbis.P_DispInfo ('bwcksncr.P_DispEvalAdditional', 'NODATA');
      END IF;

      --
      -- Email link section.
      --
      HTP.br;

      IF call_path = 'S'
      THEN
         advr_pidm := bwckcapp.F_GetAdvrPidm (pidm, hold_term);
         email :=
           bwckcapp.F_GetEmailAddress (
              advr_pidm,
              smbwcrl_row.smbwcrl_fac_email_code
           );

         IF email IS NOT NULL
         THEN
            namestr := bwckcapp.F_GetEmailNamestr (advr_pidm);

            IF namestr IS NOT NULL
            THEN
               twbkwbis.P_DispInfo (
                  'bwckcapp.P_DispCurrent',
                  'EMAIL',
                  value1   => email,
                  value2   => namestr
               );
            END IF;
         END IF;
      END IF;

      IF call_path = 'F'
      THEN
         email :=
           bwckcapp.F_GetEmailAddress (
              pidm,
              smbwcrl_row.smbwcrl_stu_email_code
           );

         IF email IS NOT NULL
         THEN
            twbkwbis.P_DispInfo (
               'bwlkfcap.P_FacDispCurrent',
               'EMAIL',
               value1   => email,
               value2   => student_name
            );
         END IF;
      END IF;

--      --
--      -- Print Back to View Options
--      twbkfrmt.P_PrintText (
--         twbkfrmt.f_printanchor (
--            curl    => twbkfrmt.f_encodeurl (
--                          twbkwbis.f_cgibin || 'bwckcapp.P_DispEvalViewOption' ||
--                             '?request_no=' ||
--                             twbkfrmt.f_encode (req_no)
--                       ),
--            ctext   => g$_nls.get ('BWCKSNC1-0043',
--                          'SQL',
--                          'Back to Display Options'
--                       )
--         )
--      );
--      twbkwbis.p_closedoc (curr_release);
   END P_DispEvalAdditional;

-------------------------------------------
--
-- Formats Non Course Requirements
-- for display.
--

   PROCEDURE p_display_ncr (printer_friendly IN OUT VARCHAR2)
   IS
      head_text   VARCHAR2 (150) DEFAULT NULL;
   BEGIN
      p_format_ncr_headers (
         lbl_ncr,
         smbpogn_row.smbpogn_ncrse_req_met_ind,
         head_text
      );

      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0044',
                           'SQL',
                           'This table is used to present all Non Course Requirements' ||
                           ' that may be attached to the program') ||
               '."',
            ccaption      => head_text
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0045',
                           'SQL',
                           'This table is used to present all Non Course Requirements' ||
                           ' that may be attached to the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => head_text
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_met);
      twbkfrmt.P_TableDataHeader (lbl_desc);
      twbkfrmt.P_TableDataHeader (lbl_yrlmt);
      twbkfrmt.P_TableDataHeader (lbl_stcd);
      twbkfrmt.P_TableDataHeader (lbl_stdt);
      twbkfrmt.P_TableDataHeader (lbl_action);
      twbkfrmt.P_TableRowClose;

      FOR smrponc_row IN smrponc_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no
                         )
      LOOP
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (
            bwcksmlt.det_conv_color (
               smrponc_row.smrponc_met_ind,
               smbpogn_row.smbpogn_ncrse_req_met_ind
            )
         );
         twbkfrmt.P_TableData (
            get_ncrq_desc (smrponc_row.smrponc_ncrq_code));
         twbkfrmt.P_TableData (smrponc_row.smrponc_year_rule);
         twbkfrmt.P_TableData (
            get_ncst_desc (smrponc_row.smrponc_ncst_code));
         twbkfrmt.P_TableData (
            TO_CHAR (
               smrponc_row.smrponc_ncst_date,
               twbklibs.twgbwrul_rec.twgbwrul_date_fmt
            ));
         twbkfrmt.P_TableData (
            get_actn_desc (smrponc_row.smrponc_actn_code));
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_ncr;

-------------------------------------------
--
-- Formats Program Required Attributes
-- for display.
--
   PROCEDURE p_display_prog_attr (printer_friendly IN OUT VARCHAR2)
   IS
      con         VARCHAR2 (6)  DEFAULT NULL;
      head_text   VARCHAR2 (150) DEFAULT NULL;
   BEGIN
      p_format_ncr_headers (
         lbl_pra,
         smbpogn_row.smbpogn_attr_req_met_ind,
         head_text
      );

      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0046',
                           'SQL',
                           'This layout table is used to present all Student and' ||
                           ' or Course Attributes that may be required in the program') ||
               '."',
            ccaption      => head_text
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0047',
                           'SQL',
                           'This table is used to present all Student and' ||
                           ' or Course Attributes that may be required in the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => head_text
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_met);
      twbkfrmt.P_TableDataHeader (lbl_crsattr);
      twbkfrmt.P_TableDataHeader (lbl_stuatts);
      twbkfrmt.P_TableDataHeader (lbl_reqcrds);
      twbkfrmt.P_TableDataHeader (
         twbkfrmt.F_PrintText ( '<ACRONYM title = "' ||
            g$_nls.get ('BWCKSNC1-0048', 'SQL', 'Connector') ||
            '">' ||
            g$_nls.get ('BWCKSNC1-0049', 'SQL', 'Con') ||
            '</ACRONYM>',
            class_in   => 'fieldlabeltextinvisible'
         )
      );
      twbkfrmt.P_TableDataHeader (lbl_reqcrse);
      twbkfrmt.P_TableDataHeader (lbl_actcrds);
      twbkfrmt.P_TableDataHeader (lbl_actcrse);
      twbkfrmt.P_TableDataHeader (lbl_action);
      twbkfrmt.P_TableRowClose;

      FOR smrpoat_row IN smrpoat_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no
                         )
      LOOP
         --
         -- 'con' used for 'and/or' display; reset after each loop.
         --
         con := NULL;
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (
            bwcksmlt.det_conv_color (
               smrpoat_row.smrpoat_met_ind,
               smbpogn_row.smbpogn_attr_req_met_ind
            )
         );
         twbkfrmt.P_TableData (
            get_attr_desc (smrpoat_row.smrpoat_attr_code));
         twbkfrmt.P_TableData (
            get_atts_desc (smrpoat_row.smrpoat_atts_code));
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrpoat_row.smrpoat_req_credits,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         p_decode_and_or (smrpoat_row.smrpoat_connector_req, con);
         twbkfrmt.P_TableData (con);
         twbkfrmt.P_TableData (smrpoat_row.smrpoat_req_courses, 'RIGHT');
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrpoat_row.smrpoat_act_credits,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         twbkfrmt.P_TableData (smrpoat_row.smrpoat_act_courses, 'RIGHT');
         twbkfrmt.P_TableData (
            get_actn_desc (smrpoat_row.smrpoat_actn_code));
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_prog_attr;

-------------------------------------------
--
-- Formats In Progress courses used
-- for display.
--
   PROCEDURE p_display_ip_course (printer_friendly IN OUT VARCHAR2)
   IS
   BEGIN
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0050',
                           'SQL',
                           'This table is used to present all in-progress' ||
                           ' courses that are available to the program') ||
               '."',
            ccaption      => lbl_ipcrse
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0051',
                           'SQL',
                           'This table is used to present all in-progress' ||
                           ' courses that are available to the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => lbl_ipcrse
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_area);
      twbkfrmt.P_TableDataHeader (lbl_group);
      twbkfrmt.P_TableDataHeader (lbl_subj);
      twbkfrmt.P_TableDataHeader (lbl_crse);
      twbkfrmt.P_TableDataHeader (lbl_crds);
      twbkfrmt.P_TableDataHeader (lbl_attr);
      twbkfrmt.P_TableRowClose;

      FOR smrdous_row IN ip_smrdous_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no,
                            smbpogn_row.smbpogn_program
                         )
      LOOP
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (
            bwcksmlt.get_area_desc (smrdous_row.smrdous_area));
         twbkfrmt.P_TableData (
            bwcksmlt.get_group_desc (smrdous_row.smrdous_group));
         twbkfrmt.P_TableData (smrdous_row.smrdous_subj_code);
         twbkfrmt.P_TableData (smrdous_row.smrdous_crse_numb);
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrdous_row.smrdous_credit_hours,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            get_attr_desc (smrdous_row.smrdous_attr_code));
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_ip_course;

-------------------------------------------
--
-- Formats Courses not used in compliance
-- for display.
--
   PROCEDURE p_display_courses_not_used (printer_friendly IN OUT VARCHAR2)
   IS
   BEGIN
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSNC1-0052',
                                   'SQL',
                                   'This table is used to present all Courses not used by the program'
                                ) ||
                                '."',
            ccaption      => lbl_unused_crse
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   => 'SUMMARY="' ||
                                g$_nls.get ('BWCKSNC1-0053',
                                   'SQL',
                                   'This table is used to present all Courses not used by the program'
                                ) ||
                                '."' ||
                                'WIDTH="100%"',
            ccaption      => lbl_unused_crse
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_subj);
      twbkfrmt.P_TableDataHeader (lbl_crse);
      twbkfrmt.P_TableDataHeader (lbl_title);
      twbkfrmt.P_TableDataHeader (lbl_term);
      twbkfrmt.P_TableDataHeader (lbl_crds);
      twbkfrmt.P_TableDataHeader (lbl_grde);
      twbkfrmt.P_TableRowClose;

      FOR smrdocn_row IN smrdocn_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no,
                            smbpogn_row.smbpogn_program
                         )
      LOOP
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (smrdocn_row.smrdocn_subj_code);
         twbkfrmt.P_TableData (smrdocn_row.smrdocn_crse_numb);
         twbkfrmt.P_TableData (smrdocn_row.smrdocn_crse_title);
         twbkfrmt.P_TableData (
            bwckcapp.get_term_desc (smrdocn_row.smrdocn_term_code));
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrdocn_row.smrdocn_credit_hours_avail,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         -- 1_1GE4WY
         IF (smrdocn_row.smrdocn_crse_source = 'R') THEN
            twbkfrmt.P_TableDataDead;
         ELSE
            twbkfrmt.P_TableData (smrdocn_row.smrdocn_grde_code);
         END IF;
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_courses_not_used;

-------------------------------------------
--
-- Formats Attributes not used by program
-- for display.
--

   PROCEDURE p_display_attr_not_used (printer_friendly IN OUT VARCHAR2)
   IS
   BEGIN
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0054',
                           'SQL',
                           'This table is used to present all Course Attributes' ||
                           ' that were not used in the program') ||
               '."',
            ccaption      => lbl_unused_attr
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0055',
                           'SQL',
                           'This table is used to present all Course Attributes' ||
                           ' that were not used in the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => lbl_unused_attr
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_attr);
      twbkfrmt.P_TableDataHeader (lbl_subj);
      twbkfrmt.P_TableDataHeader (lbl_crse);
      twbkfrmt.P_TableDataHeader (lbl_title);
      twbkfrmt.P_TableDataHeader (lbl_term);
      twbkfrmt.P_TableDataHeader (lbl_crds);
      twbkfrmt.P_TableDataHeader (lbl_grde);
      twbkfrmt.P_TableRowClose;

      FOR smrdoan_row IN smrdoan_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no,
                            smbpogn_row.smbpogn_program
                         )
      LOOP
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (
            get_attr_desc (smrdoan_row.smrdoan_attr_code));
         twbkfrmt.P_TableData (smrdoan_row.smrdoan_subj_code);
         twbkfrmt.P_TableData (smrdoan_row.smrdoan_crse_numb);
         twbkfrmt.P_TableData (smrdoan_row.smrdoan_crse_title);
         twbkfrmt.P_TableData (
            bwckcapp.get_term_desc (smrdoan_row.smrdoan_term_code));
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrdoan_row.smrdoan_credit_hours_used,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         -- 1_1GE4WY
         IF (smrdoan_row.smrdoan_crse_source = 'R') THEN
            twbkfrmt.P_TableDataDead;
         ELSE
            twbkfrmt.P_TableData (smrdoan_row.smrdoan_grde_code);
         END IF;
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_attr_not_used;

-------------------------------------------
--
-- Formats Rejected
-- for display.
--

   PROCEDURE p_display_rejected (printer_friendly IN OUT VARCHAR2)
   IS
   BEGIN
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0056',
                           'SQL',
                           'This table is used to present all Course that were' ||
                           ' rejected by the program') ||
               '."',
            ccaption      => lbl_rej_crse
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0057',
                           'SQL',
                           'This table is used to present all Course that were' ||
                           ' rejected by the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => lbl_rej_crse
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_subj);
      twbkfrmt.P_TableDataHeader (lbl_crse);
      twbkfrmt.P_TableDataHeader (lbl_area);
      twbkfrmt.P_TableDataHeader (lbl_reason);
      twbkfrmt.P_TableDataHeader (lbl_attr);
      twbkfrmt.P_TableRowClose;

      FOR smrdorj_row IN smrdorj_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no
                         )
      LOOP
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (smrdorj_row.smrdorj_subj_code);
         twbkfrmt.P_TableData (smrdorj_row.smrdorj_crse_numb);
         twbkfrmt.P_TableData (
            bwcksmlt.get_area_desc (smrdorj_row.smrdorj_area));
         twbkfrmt.P_TableData (smrdorj_row.smrdorj_rejection_reason);
         twbkfrmt.P_TableData (
            get_attr_desc (smrdorj_row.smrdorj_attr_code));
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_rejected;

-------------------------------------------
--
-- Formats program included/excluded levels
-- for display.
--

   PROCEDURE p_display_incl_excl_lvl (printer_friendly IN OUT VARCHAR2)
   IS
      con   VARCHAR2 (6) DEFAULT NULL;
   BEGIN
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0058',
                           'SQL',
                           'This table is used to present any additional course' ||
                           ' levels that may be included or excluded by the program') ||
               '."',
            ccaption      => lbl_incl_levl
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0059',
                           'SQL',
                           'This table is used to present any additional course levels' ||
                           ' that may be included or excluded by the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => lbl_incl_levl
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_inclexcl);
      twbkfrmt.P_TableDataHeader (lbl_lvl);
      twbkfrmt.P_TableDataHeader (lbl_mingrde);
      twbkfrmt.P_TableDataHeader (lbl_maxcrds);
      twbkfrmt.P_TableDataHeader (
         twbkfrmt.F_PrintText (
            '<ACRONYM title = "' ||
            g$_nls.get ('BWCKSNC1-0060', 'SQL', 'Connector') ||
            '">' ||
            g$_nls.get ('BWCKSNC1-0061', 'SQL', 'Con') ||
            '</ACRONYM>',
            class_in   => 'fieldlabeltextinvisible'
         )
      );
      twbkfrmt.P_TableDataHeader (lbl_maxcrse);
      twbkfrmt.P_TableDataHeader (lbl_actcrds);
      twbkfrmt.P_TableDataHeader (lbl_actcrse);
      twbkfrmt.P_TableDataHeader (lbl_action);
      twbkfrmt.P_TableRowClose;

      FOR smrpolv_row IN smrpolv_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no
                         )
      LOOP
         --
         -- 'con' used for 'and/or' display; reset after each loop.
         --
         con := NULL;
         twbkfrmt.P_TableRowOpen;

         IF smrpolv_row.smrpolv_incl_excl_ind = 'I'
         THEN
            twbkfrmt.P_TableData (
               G$_NLS.Get ('BWCKSNC1-0062', 'SQL', 'Include'));
         ELSE
            twbkfrmt.P_TableData (
               G$_NLS.Get ('BWCKSNC1-0063', 'SQL', 'Exclude'));
         END IF;

         twbkfrmt.P_TableData (
            bwcksmlt.get_levl_desc (smrpolv_row.smrpolv_levl_code));
         twbkfrmt.P_TableData (smrpolv_row.smrpolv_grde_code_min);
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrpolv_row.smrpolv_max_credits,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         p_decode_and_or (smrpolv_row.smrpolv_connector_max, con);
         twbkfrmt.P_TableData (con);
         twbkfrmt.P_TableData (
            NVL (smrpolv_row.smrpolv_max_courses, ''),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrpolv_row.smrpolv_act_credits,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            NVL (smrpolv_row.smrpolv_act_courses, ''),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            get_actn_desc (smrpolv_row.smrpolv_actn_code));
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_incl_excl_lvl;

-------------------------------------------
--
-- Formats program included/excluded grades
-- for display.
--

   PROCEDURE p_display_restr_grde (printer_friendly IN OUT VARCHAR2)
   IS
      con   VARCHAR2 (6) DEFAULT NULL;
   BEGIN
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0064',
                           'SQL',
                           'This table is used to present any additional course' ||
                           ' grades that may restricted by the program') ||
               '."',
            ccaption      => lbl_restr_grde
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0065',
                           'SQL',
                           'This table is used to present any additional course' ||
                           ' grades that may restricted by the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => lbl_restr_grde
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_grde);
      twbkfrmt.P_TableDataHeader (lbl_maxcrds);
      twbkfrmt.P_TableDataHeader (
         twbkfrmt.F_PrintText (
            '<ACRONYM title = "' ||
            g$_nls.get ('BWCKSNC1-0066', 'SQL', 'Connector') ||
            '">' ||
            g$_nls.get ('BWCKSNC1-0067', 'SQL', 'Con') ||
            '</ACRONYM>',
            class_in   => 'fieldlabeltextinvisible'
         )
      );
      twbkfrmt.P_TableDataHeader (lbl_maxcrse);
      twbkfrmt.P_TableDataHeader (lbl_actcrds);
      twbkfrmt.P_TableDataHeader (lbl_actcrse);
      twbkfrmt.P_TableDataHeader (lbl_action);
      twbkfrmt.P_TableRowClose;

      FOR smrpogd_row IN smrpogd_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no
                         )
      LOOP
         --
         -- 'con' used for 'and/or' display; reset after each loop.
         --
         con := NULL;
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (smrpogd_row.smrpogd_grde_code);
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrpogd_row.smrpogd_max_credits,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         p_decode_and_or (smrpogd_row.smrpogd_connector_max, con);
         twbkfrmt.P_TableData (con);
         twbkfrmt.P_TableData (
            NVL (smrpogd_row.smrpogd_max_courses, ''),
            'RIGHT'
         );
        twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrpogd_row.smrpogd_act_credits,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            NVL (smrpogd_row.smrpogd_act_courses, ''),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            get_actn_desc (smrpogd_row.smrpogd_actn_code));
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_restr_grde;

-------------------------------------------
--
-- Formats program restricted subjects/attributes
-- for display.
--

   PROCEDURE p_display_restr_subj_attr (printer_friendly IN OUT VARCHAR2)
   IS
      con   VARCHAR2 (6) DEFAULT NULL;
   BEGIN
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0068',
                           'SQL',
                           'This table is used to present any subjects or attributes' ||
                           ' that may be restricted by the program') ||
               '."',
            ccaption      => lbl_restr_subj_attr
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0069',
                           'SQL',
                           'This table is used to present any subjects or attributes' ||
                           ' that may be restricted by the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => lbl_restr_subj_attr
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_camp);
      twbkfrmt.P_TableDataHeader (lbl_coll);
      twbkfrmt.P_TableDataHeader (lbl_dept);
      twbkfrmt.P_TableDataHeader (lbl_subj);
      twbkfrmt.P_TableDataHeader (lbl_low);
      twbkfrmt.P_TableDataHeader (lbl_high);
      twbkfrmt.P_TableDataHeader (lbl_crsattr);
      twbkfrmt.P_TableDataHeader (lbl_maxcrds);
      twbkfrmt.P_TableDataHeader (lbl_actcrds);
      twbkfrmt.P_TableDataHeader (
         twbkfrmt.F_PrintText (
            '<ACRONYM title = "' ||
            g$_nls.get ('BWCKSNC1-0070', 'SQL', 'Connector') ||
            '">' ||
            g$_nls.get ('BWCKSNC1-0071', 'SQL', 'Con') ||
            '</ACRONYM>',
            class_in   => 'fieldlabeltextinvisible'
         )
      );
      twbkfrmt.P_TableDataHeader (lbl_maxcrse);
      twbkfrmt.P_TableDataHeader (lbl_actcrse);
      twbkfrmt.P_TableDataHeader (lbl_action);
      twbkfrmt.P_TableRowClose;

      FOR smrposa_row IN smrposa_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no
                         )
      LOOP
         --
         -- 'con' used for 'and/or' display; reset after each loop.
         --
         con := NULL;
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (
            bwcksmlt.get_camp_desc (smrposa_row.smrposa_camp_code));
         twbkfrmt.P_TableData (
            bwcksmlt.get_coll_desc (smrposa_row.smrposa_coll_code));
         twbkfrmt.P_TableData (
            bwckcapp.get_dept_desc (smrposa_row.smrposa_dept_code));
         twbkfrmt.P_TableData (smrposa_row.smrposa_subj_code);
         twbkfrmt.P_TableData (smrposa_row.smrposa_crse_numb_low);
         twbkfrmt.P_TableData (smrposa_row.smrposa_crse_numb_high);
         twbkfrmt.P_TableData (
            get_attr_desc (smrposa_row.smrposa_attr_code));
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrposa_row.smrposa_max_credits,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrposa_row.smrposa_act_credits,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         p_decode_and_or (smrposa_row.smrposa_connector_max, con);
         twbkfrmt.P_TableData (con);
         twbkfrmt.P_TableData (
            NVL (smrposa_row.smrposa_max_courses, ''),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            NVL (smrposa_row.smrposa_act_courses, ''),
            'RIGHT'
         );
         twbkfrmt.P_TableData (
            get_actn_desc (smrposa_row.smrposa_actn_code));
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_restr_subj_attr;

-------------------------------------------
--
-- Formats Non Course Requirements
-- for display.
--

   PROCEDURE p_display_plan_crse (printer_friendly IN OUT VARCHAR2)
   IS
   BEGIN
      IF printer_friendly = 'Y'
      THEN
         twbkfrmt.P_TableOpen (
            'PLAIN',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0072',
                           'SQL',
                           'This table is used to present any planned courses' ||
                           ' that can be used by the program') ||
               '."',
            ccaption      => lbl_plan_crse
         );
      ELSE
         twbkfrmt.P_TableOpen (
            'DATADISPLAY',
            cattributes   =>
               'SUMMARY="' ||
               g$_nls.get ('BWCKSNC1-0073',
                           'SQL',
                           'This table is used to present any planned courses' ||
                           ' that can be used by the program') ||
               '."' || 'WIDTH="100%"',
            ccaption      => lbl_plan_crse
         );
      END IF;

      twbkfrmt.P_TableRowOpen;
      twbkfrmt.P_TableDataHeader (lbl_term);
      twbkfrmt.P_TableDataHeader (lbl_subj);
      twbkfrmt.P_TableDataHeader (lbl_crse);
      twbkfrmt.P_TableDataHeader (lbl_lvl);
      twbkfrmt.P_TableDataHeader (lbl_crds);
      twbkfrmt.P_TableDataHeader (lbl_title);
      twbkfrmt.P_TableDataHeader (lbl_attr);
      twbkfrmt.P_TableRowClose;

      FOR smrpcrs_row IN smrpcrs_c (
                            smbpogn_row.smbpogn_pidm,
                            smbpogn_row.smbpogn_request_no
                         )
      LOOP
         twbkfrmt.P_TableRowOpen;
         twbkfrmt.P_TableData (
            bwckcapp.get_term_desc (smrpcrs_row.smrpcrs_term_code));
         twbkfrmt.P_TableData (smrpcrs_row.smrpcrs_subj_code);
         twbkfrmt.P_TableData (smrpcrs_row.smrpcrs_crse_numb);
         twbkfrmt.P_TableData (
            bwcksmlt.get_levl_desc (smrpcrs_row.smrpcrs_levl_code));
         twbkfrmt.P_TableData (
            NVL (TO_CHAR (smrpcrs_row.smrpcrs_credit_hr,'99999990D990'),'&nbsp;'),
            'RIGHT'
         );
         twbkfrmt.P_TableData (smrpcrs_row.smrpcrs_title);
         twbkfrmt.P_TableData (
            get_attr_desc (smrpcrs_row.smrpcrs_attr_code));
         twbkfrmt.P_TableRowClose;
      END LOOP;

      twbkfrmt.P_TableClose;
   END p_display_plan_crse;

----------------------------------------
--
-- Working procedure. Takes a table connector value
-- of either "A" or "O" and converts it to an
-- "And" or an "Or".

   PROCEDURE p_decode_and_or (
      param1   IN       SMRPOAT.SMRPOAT_CONNECTOR_REQ%TYPE,
      con      OUT      VARCHAR2
   )
   IS
   BEGIN
      IF param1 = 'A'
      THEN
         con := G$_NLS.Get ('BWCKSNC1-0074', 'SQL', 'And');
      ELSIF param1 = 'O'
      THEN
         con := G$_NLS.Get ('BWCKSNC1-0075', 'SQL', 'Or');
      ELSE
         con := '&nbsp;';
      END IF;
   END p_decode_and_or;

----------------------------------------
-- NCR and Required attributes are REQUIREMENTS,
-- thus can be met or notmet.  Take in the
-- label name, and the met indicator;  and
-- return the label name with the new
-- translated 'met/notmet' text appended to name.
--

   PROCEDURE p_format_ncr_headers (
      param1      IN       VARCHAR2,
      param2      IN       VARCHAR2,
      head_text   OUT      VARCHAR2
   )
   IS
      hld_header_text   VARCHAR2 (150) DEFAULT NULL;
   BEGIN
      IF param2 = 'N'
      THEN
         hld_header_text :=
           param1 ||
              twbkfrmt.F_PrintText (
                 G$_NLS.Get ('BWCKSNC1-0076', 'SQL', 'Not Met'),
                 class_in   => 'requirementnotmet'
              );
      ELSIF param2 = 'Y'
      THEN
         hld_header_text :=
           param1 ||
              twbkfrmt.F_PrintText (G$_NLS.Get ('BWCKSNC1-0077', 'SQL', 'Met'));
      ELSE
         hld_header_text := param1;
      END IF;

      head_text := hld_header_text;
   END p_format_ncr_headers;
----------------------------------------
-- BOTTOM
-- Package Body BWCKSNC1
END pk_bwcksncr;
/


DROP PUBLIC SYNONYM PK_BWCKSNCR;

CREATE PUBLIC SYNONYM PK_BWCKSNCR FOR BANINST1.PK_BWCKSNCR;


GRANT EXECUTE ON BANINST1.PK_BWCKSNCR TO WWW_USER;

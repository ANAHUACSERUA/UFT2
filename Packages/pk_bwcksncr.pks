DROP PACKAGE BANINST1.PK_BWCKSNCR;

CREATE OR REPLACE PACKAGE BANINST1.pk_bwcksncr
AS
--AUDIT_TRAIL_MSGKEY_UPDATE
-- PROJECT : MSGKEY
-- MODULE  : BWCKSNCR
-- SOURCE  : enUS
-- TARGET  : I18N
-- DATE    : Thu Apr 22 13:16:21 2010
-- MSGSIGN : #0000000000000000
--TMI18N.ETR DO NOT CHANGE--
--
-- FILE NAME..: bwcksncr.sql
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
   -------------------------------------------

   FUNCTION get_actn_desc (param1 IN stvactn.stvactn_code%TYPE)
      RETURN stvactn.stvactn_desc%TYPE;

   FUNCTION get_ncrq_desc (param1 IN stvncrq.stvncrq_code%TYPE)
      RETURN stvncrq.stvncrq_desc%TYPE;

   FUNCTION get_ncst_desc (param1 IN stvncst.stvncst_code%TYPE)
      RETURN stvncst.stvncst_desc%TYPE;

   FUNCTION get_attr_desc (param1 IN stvattr.stvattr_code%TYPE)
      RETURN stvattr.stvattr_desc%TYPE;

   FUNCTION get_atts_desc (param1 IN stvatts.stvatts_code%TYPE)
      RETURN stvatts.stvatts_desc%TYPE;

   FUNCTION f_ip_crse_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE,
      param3   IN   SMRDOUS.SMRDOUS_PROGRAM%TYPE
   )
      RETURN BOOLEAN;

   FUNCTION f_planned_crse_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN;

   FUNCTION f_unused_crse_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE,
      param3   IN   SMRDOUS.SMRDOUS_PROGRAM%TYPE
   )
      RETURN BOOLEAN;

   FUNCTION f_unused_attr_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE,
      param3   IN   SMRDOUS.SMRDOUS_PROGRAM%TYPE
   )
      RETURN BOOLEAN;

   FUNCTION f_reject_crse_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN;

   FUNCTION f_prog_incl_excl_lvl_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN;

   FUNCTION f_prog_restr_grde_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN;

   FUNCTION f_prog_restr_subj_exists (
      param1   IN   SPRIDEN.SPRIDEN_PIDM%TYPE,
      param2   IN   SMRDOUS.SMRDOUS_REQUEST_NO%TYPE
   )
      RETURN BOOLEAN;

-------------------------------------------

   PROCEDURE p_display_ncr (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_prog_attr (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_ip_course (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_plan_crse (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_courses_not_used (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_attr_not_used (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_rejected (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_incl_excl_lvl (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_restr_grde (printer_friendly IN OUT VARCHAR2);

   PROCEDURE p_display_restr_subj_attr (printer_friendly IN OUT VARCHAR2);

   PROCEDURE P_DispEvalAdditional(psReclDesc VARCHAR2);

   PROCEDURE p_decode_and_or (
      param1   IN       SMRPOAT.SMRPOAT_CONNECTOR_REQ%TYPE,
      con      OUT      VARCHAR2
   );

   PROCEDURE p_format_ncr_headers (
      param1      IN       VARCHAR2,
      param2      IN       VARCHAR2,
      head_text   OUT      VARCHAR2
   );
END pk_BWCKSNCR; -- Package Specification BWCKSNCR
     -- Bottom
/


DROP PUBLIC SYNONYM PK_BWCKSNCR;

CREATE PUBLIC SYNONYM PK_BWCKSNCR FOR BANINST1.PK_BWCKSNCR;


GRANT EXECUTE ON BANINST1.PK_BWCKSNCR TO WWW_USER;

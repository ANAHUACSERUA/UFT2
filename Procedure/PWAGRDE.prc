CREATE PROCEDURE BANINST1.PWAGRDE(pnCRNN NUMBER,
                                  psTERM VARCHAR2
                                 ) IS
       
  cn100      CONSTANT NUMBER(3)   := 100;
  cnCRNN     CONSTANT NUMBER(6)   := pnCRNN;
  csF        CONSTANT VARCHAR2(1) := 'F';
  csM        CONSTANT VARCHAR2(1) := 'M';
  csRE       CONSTANT VARCHAR2(2) := 'RE';
  csRW       CONSTANT VARCHAR2(2) := 'RW';
  csTERM     CONSTANT VARCHAR2(6) := psTERM;
  csESCALALC CONSTANT VARCHAR2(8) := 'ESCALALC';
  
  --setPromMtemporal
  procedure setPromMtemporal is
  
  begin
      UPDATE SHRCMRK
         SET SHRCMRK_GRDE_CODE = (select shkegrb.f_get_grade_code(csESCALALC,
                                            (sum(shrgcom_weight * (shrmrks_PERCENTAGE/cn100))/sum (shrgcom_weight))*cn100)
                                       from shrmrks, 
                                            shrgcom
                                      where shrmrks_gcom_id   = shrgcom_id
                                        and shrmrks_term_code = shrgcom_term_code
                                        and shrmrks_crn       = shrgcom_crn
                                        and shrgcom_incl_ind  = csM
                                        and shrmrks_pidm      = SHRCMRK_PIDM
                                        and shrmrks_crn       = SHRCMRK_CRN
                                        and shrmrks_term_code = SHRCMRK_TERM_CODE
                                     )
       WHERE SHRCMRK_RECTYPE_IND = csM
         AND SHRCMRK_CRN         = cnCRNN
         AND SHRCMRK_TERM_CODE   = csTERM; 
         
      commit;         
  exception
      when others then
           null;
  end setPromMtemporal;
  
  --setPromFtemporal
  procedure setPromFtemporal is
  
  begin
      UPDATE SHRCMRK
         SET SHRCMRK_GRDE_CODE = (select shkegrb.f_get_grade_code(csESCALALC,
                                            (sum(shrgcom_weight * (shrmrks_PERCENTAGE/cn100))/sum (shrgcom_weight))*cn100)
                                       from shrmrks, 
                                            shrgcom
                                      where shrmrks_gcom_id   = shrgcom_id
                                        and shrmrks_term_code = shrgcom_term_code
                                        and shrmrks_crn       = shrgcom_crn
                                        and shrmrks_pidm      = SHRCMRK_PIDM
                                        and shrmrks_crn       = SHRCMRK_CRN
                                        and shrmrks_term_code = SHRCMRK_TERM_CODE
                                     )
       WHERE SHRCMRK_RECTYPE_IND = csF
         AND SHRCMRK_CRN         = cnCRNN
         AND SHRCMRK_TERM_CODE   = csTERM;
      
      commit; 
  exception
      when others then
           null;
  end setPromFtemporal;
  
  --setPromedio
  procedure setPromedio is
  
  begin
      UPDATE SFRSTCR
         SET SFRSTCR_GRDE_CODE_MID = (select shkegrb.f_get_grade_code(csESCALALC,
                                            (sum(shrgcom_weight * (shrmrks_PERCENTAGE/cn100))/sum (shrgcom_weight))*cn100)
                                       from shrmrks, 
                                            shrgcom
                                      where shrmrks_gcom_id   = shrgcom_id
                                        and shrmrks_term_code = shrgcom_term_code
                                        and shrmrks_crn       = shrgcom_crn
                                        and shrgcom_incl_ind  = csM
                                        and shrmrks_pidm      = SFRSTCR_PIDM
                                        and shrmrks_crn       = SFRSTCR_CRN
                                        and shrmrks_term_code = SFRSTCR_TERM_CODE
                                     ),
             SFRSTCR_GRDE_CODE     = (select shkegrb.f_get_grade_code(csESCALALC,
                                            (sum(shrgcom_weight * (shrmrks_PERCENTAGE/cn100))/sum (shrgcom_weight))*cn100)
                                       from shrmrks, 
                                            shrgcom
                                      where shrmrks_gcom_id   = shrgcom_id
                                        and shrmrks_term_code = shrgcom_term_code
                                        and shrmrks_crn       = shrgcom_crn
                                        and shrmrks_pidm      = SFRSTCR_PIDM
                                        and shrmrks_crn       = SFRSTCR_CRN
                                        and shrmrks_term_code = SFRSTCR_TERM_CODE
                                     )
       WHERE SFRSTCR_RSTS_CODE     IN (csRE,csRW)
         AND SFRSTCR_CRN            = cnCRNN
         AND SFRSTCR_TERM_CODE      = csTERM; 
      
      commit; 
  exception
      when others then
           null;
  end setPromedio;  
                          
  BEGIN                                 
      setPromMtemporal();
      
      setPromFtemporal();
       
      setPromedio();
  END;
/      
   

   
   
     
           
            
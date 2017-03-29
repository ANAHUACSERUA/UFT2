CREATE OR REPLACE FUNCTION BANINST1.f_get_programa
(pidm          number,
term_code     varchar)
return varchar2
IS
-- fuente: f_get_programa.sql.
-- Autor : Alfonso Moreno.
-- Uso   : Vistas para Discoverer.
-- Area  : Finanzas.
-- Fecha : 14-enero-2003.
--modify  by Glovicx@  26.04.2014--- se puso lel filtro de level_code = LC
i_programa     varchar2(11) := NULL;
CURSOR chk_sgbstdn IS
SELECT SGBSTDN_PROGRAM_1
FROM SGBSTDN S1
WHERE SGBSTDN_PIDM = pidm
and sgbstdn_levl_code IN ('LC', 'LI')
AND SGBSTDN_TERM_CODE_EFF =
                  (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                  FROM SGBSTDN
                  WHERE SGBSTDN_PIDM = S1.SGBSTDN_PIDM
                  AND SGBSTDN_TERM_CODE_EFF <= term_code
                  and sgbstdn_levl_code IN ('LC', 'LI')
                  );
BEGIN
OPEN chk_sgbstdn;
FETCH chk_sgbstdn
INTO i_programa;
IF chk_sgbstdn%NOTFOUND THEN
i_programa := NULL;
END IF;
CLOSE chk_sgbstdn;
return i_programa;
END f_get_programa;
/


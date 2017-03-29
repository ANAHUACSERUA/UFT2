CREATE OR REPLACE FUNCTION BANINST1.f_get_rut
(pidm          number)
return varchar2
IS
i_rut     varchar2(25) := NULL;
CURSOR chk_paso IS
SELECT SPBPERS_NAME_SUFFIX FROM SPBPERS
WHERE SPBPERS_PIDM = pidm;
BEGIN
OPEN chk_paso;
FETCH chk_paso
INTO    i_rut;
IF chk_paso%NOTFOUND THEN
i_rut := NULL;
END IF;
CLOSE chk_paso;
return    i_rut;
END f_get_rut;
/
CREATE OR REPLACE FUNCTION BANINST1.F_GET_PROGRAMA_VIG
    (pidm          NUMBER,
     term_code     VARCHAR)
    return varchar2
IS
    -- DECLARACION DE VARIABLES LOCALES
    -- VARIABLE PARA CARGAR EL PROGRAMA ENCONTRADO
    i_programa     varchar2(11) := NULL;
    -- CURSOR QUE BUSCA EL PROGRAMA ANTERIOR SI HUBO CAMBIO DE CARRERA
    CURSOR chk_sgbstdn IS
        SELECT SGBSTDN_PROGRAM_1
          FROM SGBSTDN S1
         WHERE SGBSTDN_PIDM = pidm
           AND SGBSTDN_TERM_CODE_EFF =
                  (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                     FROM SGBSTDN
                    WHERE SGBSTDN_PIDM = S1.SGBSTDN_PIDM
                  );
BEGIN
    -- ABRE EL CURSO PARA CARGAR LA INFOMACION
    OPEN chk_sgbstdn;
    FETCH chk_sgbstdn INTO i_programa;
    -- VALIDA SI NO ENCONTRO REGISTROS
    IF chk_sgbstdn%NOTFOUND THEN
        i_programa := NULL;
    END IF;
    -- CIEERA EL CURSOR
    CLOSE chk_sgbstdn;
    -- REGRESE EL VALOR ENCONTRADO
    return i_programa;
END F_GET_PROGRAMA_VIG;
/
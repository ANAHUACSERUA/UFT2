DROP PROCEDURE BANINST1.PWAREG4;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG4(psLevl VARCHAR2,
                                             psTerm VARCHAR2,
                                             pnSeq  INTEGER,
                                             psUser VARCHAR2,
                                             psStat VARCHAR2
                                            ) IS

/*
    Tarea: Reglas de repetici?n (Cuarta etapa)
             * Actualizar los campos
               "SHRTCKN_REPEAT_COURSE_IND", "SHRTCKN_ACTIVITY_DATE", "SHRTCKN_REPEAT_SYS_IND",
               de las materias repetidas por los alumnos encontrados en la "etapa 1" y
               actualizadas en la "etapa 2", con los valores

               --Materia aprobada
               SHRTCKN_REPEAT_COURSE_IND = 'I',  (Incluir, "Tomar encuenta la calificación")
               SHRTCKN_ACTIVITY_DATE     = SYSDATE,
               SHRTCKN_REPEAT_SYS_IND    = 'S'

               --Materia reprobada
               SHRTCKN_REPEAT_COURSE_IND = 'E',  (Excluir, "No tomar encuenta la calificación")
               SHRTCKN_ACTIVITY_DATE     = SYSDATE,
               SHRTCKN_REPEAT_SYS_IND    = 'S'

    Fecha: 07/07/2011
    AUTOR: MAC
   Modulo: Historia academica



*/

  vnRow    INTEGER      := 0;
  vsCodErr VARCHAR2(50) := NULL;

  csS       CONSTANT VARCHAR2(1) := 'S';
  cdSysDate CONSTANT DATE        := SYSDATE;
  cn4       constant VARCHAR2(1)   := '4';
  csRE      constant VARCHAR2(2)   := 'RE';
  cn1       constant number(1)   := 1;
  vnReprobadas number(2)   := 0;
  vnAprobadas number(3) := 0;
  -- alumnos y materias
  --cuRegla
  CURSOR cuRegla IS
         SELECT SWRTCKN_PIDM      AS Pidm,
                SWRTCKN_SUBJ_CODE AS Subj,
                SWRTCKN_CRSE_NUMB AS Crse,
                SWRTCKN_GRDE_CODE_FINAL As Cali
           FROM SWRTCKN
          WHERE SWRTCKN_SEQ       = pnSeq
            AND SWRTCKN_LEVL_CODE = psLevl
            AND SWRTCKN_TERM_CODE = psTerm;

  --excluir (E: no tomar encuenta la calificación) todas la materias encontradas en la "etapa 1" del proceso
  --excluirMaterias
  procedure excluirMaterias(pnPidm number,
                            psSubj varchar2,
                            psCrse varchar2
                           ) is

  csE constant varchar2(1) := 'E';

  begin
      update shrtckn
         set shrtckn_repeat_course_ind  = csE,
             shrtckn_activity_date      = cdSysDate,
             shrtckn_repeat_sys_ind     = csS
       where shrtckn_repeat_course_ind is null
         and shrtckn_crse_numb          = psCrse
         and shrtckn_subj_code          = psSubj
         and shrtckn_pidm               = pnPidm;
  end excluirMaterias;

  --incluir (I: si tomar encuenta la calificación) todas la materias encontradas en la "etapa 1" del proceso
  --incluirMaterias

  procedure incluirMaterias(pnPidm number,
                            psSubj varchar2,
                            psCrse varchar2
                           ) is

  typE regGrde is record(rGrde shrtckg.shrtckg_grde_code_final%type,
                         rCrnn shrtckn.shrtckn_crn%type,
                         rSeqn shrtckn.shrtckn_seq_no%type,
                         rTerm shrtckn.shrtckn_term_code%type
                        );

  regActualiza regGrde;

  cn5   constant number(1)   := 5;
  csP   constant varchar2(1) := 'P';
  cs0   constant varchar2(1) := '0';
  csAC  constant varchar2(2) := 'AC';
  csAD  constant varchar2(2) := 'AD';
  csCN  constant varchar2(2) := 'CN';
  csOU  constant varchar2(2) := 'OU';
  csRM  constant varchar2(2) := 'RM';
  csNV  constant varchar2(2) := 'RM';
  csOU1 constant varchar2(3) := 'OU1';
  csRE  constant varchar2(2) := 'RE';
  csOU2 constant varchar2(3) := 'OU2';
  cs7c0 constant varchar2(3) := '7,0';
  cs7p0 constant varchar2(3) := '7.0';
  cs3p5 constant varchar2(3) := '3.5';

  -- calificaciones de las materias
  --cuGrde
  cursor cuGrde Is
         select decode(b.shrtckg_grde_code_final,
                       cs7c0, cs7p0,
                       csAC,  cs7p0,
                       csAD,  cs0,
                       csCN,  cs0,
                       csOU,  cs0,
                       csOU1, cs0,
                       csOU2, cs0,
                       csP,   cs0,
                       csRM,  cs0,
                       csNV,  cs0,
                       csRE,  cs3p5,
                       b.shrtckg_grde_code_final
                )                   as Grde,
                a.shrtckn_crn       as Crnn,
                a.shrtckn_seq_no    as Seqn,
                a.shrtckn_term_code as Term
           from shrtckn a,
                shrtckg b
          where a.shrtckn_pidm      = b.shrtckg_pidm
            and a.shrtckn_seq_no    = b.shrtckg_tckn_seq_no
            and a.shrtckn_term_code = b.shrtckg_term_code
            and b.shrtckg_seq_no    = (select max(c.shrtckg_seq_no)
                                         from shrtckg c
                                        where c.shrtckg_term_code   = a.shrtckn_term_code
                                          and c.shrtckg_pidm        = a.shrtckn_pidm
                                          and c.shrtckg_tckn_seq_no = a.shrtckn_seq_no
                                      )
            and a.shrtckn_crse_numb = psCrse
            and a.shrtckn_subj_code = psSubj
            and a.shrtckn_pidm      = pnPidm
            and b.shrtckg_grde_code_final <> 'NV'
            order by 1 desc, a.shrtckn_term_code desc,
            shrtckg_activity_date;



  --incluirCurso
  procedure incluirCurso(psTerm varchar2,
                         pnSeqn number
                        ) is

  csI constant varchar2(1) := 'I';

  begin
      update shrtckn
          set shrtckn_repeat_course_ind = csI,
              shrtckn_activity_date     = cdSysDate,
              shrtckn_repeat_sys_ind    = csS
        where shrtckn_seq_no    = pnSeqn
          and shrtckn_term_code = psTerm
          and shrtckn_subj_code = psSubj
          and shrtckn_crse_numb = psCrse
          and shrtckn_pidm      = pnPidm;
  end incluirCurso;


  begin
      -- el cursor solo "procesa" el primer registro de varios que puede obtener

      open cuGrde;
      fetch cuGrde into regActualiza;

            --incluir el primer curso encontrado
            incluirCurso(regActualiza.rTerm, regActualiza.rSeqn);

      close cuGrde;


  end incluirMaterias;

procedure incluirMateriasReprobadas(pnPidm number,
                            psSubj varchar2,
                            psCrse varchar2
                           ) is

  typE regGrdeOrden is record(rGrde shrtckg.shrtckg_grde_code_final%type,
                         rCrnn shrtckn.shrtckn_crn%type,
                         rSeqn shrtckn.shrtckn_seq_no%type,
                         rTerm shrtckn.shrtckn_term_code%type
                        );

  regActualizaOrden regGrdeOrden;

  cn5   constant number(1)   := 5;
  csP   constant varchar2(1) := 'P';
  cs0   constant varchar2(1) := '0';
  csAC  constant varchar2(2) := 'AC';
  csAD  constant varchar2(2) := 'AD';
  csCN  constant varchar2(2) := 'CN';
  csOU  constant varchar2(2) := 'OU';
  csRM  constant varchar2(2) := 'RM';
  csOU1 constant varchar2(3) := 'OU1';
  csOU2 constant varchar2(3) := 'OU2';
  cs7c0 constant varchar2(3) := '7,0';
  cs7p0 constant varchar2(3) := '7.0';
  csNV  constant varchar2(3) := 'NV';
  cs3p5 constant varchar2(3) := '3.5';
  -- calificaciones de las materias
  --cuGrde

  cursor cuGrdeOrden Is
         select decode(b.shrtckg_grde_code_final,
                       cs7c0, cs7p0,
                       csAC,  cs7p0,
                       csAD,  cs0,
                       csCN,  cs0,
                       csOU,  cs0,
                       csOU1, cs0,
                       csOU2, cs0,
                       csP,   cs0,
                       csRM,  cs0,
                       csNV,  cs0,
                       csRE,  cs3p5,
                       b.shrtckg_grde_code_final
                )                   as Grde,
                a.shrtckn_crn       as Crnn,
                a.shrtckn_seq_no    as Seqn,
                a.shrtckn_term_code as Term
           from shrtckn a,
                shrtckg b
          where a.shrtckn_pidm      = b.shrtckg_pidm
            and a.shrtckn_seq_no    = b.shrtckg_tckn_seq_no
            and a.shrtckn_term_code = b.shrtckg_term_code
            and b.shrtckg_seq_no    = (select max(c.shrtckg_seq_no)
                                         from shrtckg c
                                        where c.shrtckg_term_code   = a.shrtckn_term_code
                                          and c.shrtckg_pidm        = a.shrtckn_pidm
                                          and c.shrtckg_tckn_seq_no = a.shrtckn_seq_no
                                      )
            and a.shrtckn_crse_numb = psCrse
            and a.shrtckn_subj_code = psSubj
            and a.shrtckn_pidm      = pnPidm
             and b.shrtckg_grde_code_final <> 'NV'
          order by-- b.shrtckg_grde_code_final desc,
                   a.shrtckn_term_code   desc;


  --incluirCurso
  procedure incluirCursoReprobado(psTerm varchar2,
                         pnSeqn number
                        ) is

  csI constant varchar2(1) := 'I';
  csAC constant varchar2(2) := 'AC';

  begin
      update shrtckn
          set shrtckn_repeat_course_ind = csI,
              shrtckn_activity_date     = cdSysDate,
              shrtckn_repeat_sys_ind    = csS
        where shrtckn_seq_no    = pnSeqn
          and shrtckn_term_code = psTerm
          and shrtckn_subj_code = psSubj
          and shrtckn_crse_numb = psCrse
          and shrtckn_pidm      = pnPidm;
  end incluirCursoReprobado;


  begin
      -- el cursor solo "procesa" el primer registro de varios que puede obtener

     open cuGrdeOrden;

        fetch cuGrdeOrden into regActualizaOrden;

            --incluir el primer curso encontrado
            incluirCursoReprobado(regActualizaOrden.rTerm, regActualizaOrden.rSeqn);

        close cuGrdeOrden;


  end incluirMateriasReprobadas;


  BEGIN

      PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'I');

      -- alumnos y materias
      FOR regRgl IN cuRegla LOOP
        vnRow := vnRow + 1;

          --excluir todas la materias encontradas en la "etapa 1" del proceso
          --(E: no tomar encuenta la calificación)
          excluirMaterias(regRgl.Pidm, regRgl.Subj, regRgl.Crse);


          --incluir la primera meteria que tenga la fecha mas actual por periodo y calificacion
          --(I: si tomar encuenta la calificación)

          select count(1) into vnReprobadas
         from shrtckn a,
                shrtckg b
          where a.shrtckn_pidm      = b.shrtckg_pidm
            and a.shrtckn_seq_no    = b.shrtckg_tckn_seq_no
            and a.shrtckn_term_code = b.shrtckg_term_code
            and b.shrtckg_seq_no    = (select max(c.shrtckg_seq_no)
                                         from shrtckg c
                                        where c.shrtckg_term_code   = a.shrtckn_term_code
                                          and c.shrtckg_pidm        = a.shrtckn_pidm
                                          and c.shrtckg_tckn_seq_no = a.shrtckn_seq_no
                                      )
            and a.shrtckn_crse_numb = regRgl.Crse
            and a.shrtckn_subj_code = regRgl.Subj
            and a.shrtckn_pidm      = regRgl.Pidm
            and    (b.shrtckg_grde_code_final = csRE or b.shrtckg_grde_code_final <= cn4)
            and (b.shrtckg_grde_code_final <> 'AC' or b.shrtckg_grde_code_final >= cn4);

             select count(1) into vnAprobadas
         from shrtckn a,
                shrtckg b
          where a.shrtckn_pidm      = b.shrtckg_pidm
            and a.shrtckn_seq_no    = b.shrtckg_tckn_seq_no
            and a.shrtckn_term_code = b.shrtckg_term_code
            and b.shrtckg_seq_no    = (select max(c.shrtckg_seq_no)
                                         from shrtckg c
                                        where c.shrtckg_term_code   = a.shrtckn_term_code
                                          and c.shrtckg_pidm        = a.shrtckn_pidm
                                          and c.shrtckg_tckn_seq_no = a.shrtckn_seq_no
                                      )
            and a.shrtckn_crse_numb = regRgl.Crse
            and a.shrtckn_subj_code = regRgl.Subj
            and a.shrtckn_pidm      = regRgl.Pidm
            and    (b.shrtckg_grde_code_final <> csRE or b.shrtckg_grde_code_final >= cn4)
            and (b.shrtckg_grde_code_final = 'AC' or b.shrtckg_grde_code_final >= cn4);


         if vnReprobadas <= 0 AND vnAprobadas > 0 then
          incluirMaterias(regRgl.Pidm, regRgl.Subj, regRgl.Crse);
          end if;
         -- if vnReprobadas = cn1 AND vnAprobadas = 0 then
          --incluirMaterias(regRgl.Pidm, regRgl.Subj, regRgl.Crse);
          --end if;
          if vnReprobadas > 0 AND vnAprobadas = 0 then
          incluirMateriasReprobadas(regRgl.Pidm, regRgl.Subj, regRgl.Crse);
          end if;
          if vnReprobadas  > 0 AND vnAprobadas > 0 then
           incluirMaterias(regRgl.Pidm, regRgl.Subj, regRgl.Crse);
          end if;
          if vnReprobadas = 0 AND vnAprobadas > 0 then
           incluirMaterias(regRgl.Pidm, regRgl.Subj, regRgl.Crse);
          end if;
          IF vnRow = 50 THEN
             vnRow := 0;
             COMMIT;
          END IF;

      END LOOP;

      COMMIT;

      PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'U');

  EXCEPTION
      WHEN OTHERS THEN
           vsCodErr := SQLCODE;

           ROLLBACK;

           PWAREG7(psLevl, psTerm, pnSeq, psUser, psStat, 'O', vsCodErr);

  END PWAREG4;
/


DROP PUBLIC SYNONYM PWAREG4;

CREATE PUBLIC SYNONYM PWAREG4 FOR BANINST1.PWAREG4;


GRANT EXECUTE ON BANINST1.PWAREG4 TO BAN_DEFAULT_M;

GRANT EXECUTE ON BANINST1.PWAREG4 TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PWAREG4 TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PWAREG4 TO OAS_PUBLIC;

GRANT EXECUTE ON BANINST1.PWAREG4 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG4 TO WWW2_USER;

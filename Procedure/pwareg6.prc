DROP PROCEDURE BANINST1.PWAREG6;

CREATE OR REPLACE PROCEDURE BANINST1.PWAREG6(psLevl  VARCHAR2,
                                             psTerm  VARCHAR2,
                                             pnSeq   INTEGER,
                                             psUser  VARCHAR2,
                                             psStat  VARCHAR2) IS

/*
    Tarea: Ejecutar las Reglas de repetici?n (Primera etapa)
    Fecha: 07/07/20011
   Modulo: Historia academica

*/
  vgsUSR    VARCHAR2(500);
  vsProceso VARCHAR2(50)   := '(Etapa: '||psStat||') Proceso en ejecuci?n...';
  vdEnd     DATE           := NULL;
  vdBegin   DATE           := NULL;

  procedure p_SiguienteEtapa is

  vnEtapa INTEGER := TO_NUMBER(psStat)+1;

  begin
      htp.p('
      <html><head><title></title>

      <script language=''JavaScript''><!--
      javascript:window.history.forward(1);
      //--></script>

      <style type="text/css"><!--
      body {cursor:wait;}
      --></style>

      </head>
      <body bgcolor="#ffffff" onLoad="parent.f_Ejecucion('||vnEtapa||','''||psLevl||''');">
      ');

      IF vnEtapa > 4 THEN
         htp.p('EL PROCESO A TERMINADO DE EJECUTARSE');
      ELSE
         htp.p(vsProceso);
      END IF;

      htp.p('
      </body>
      </html>
      ');

  end p_SiguienteEtapa;

  procedure p_Ciclo is


  begin
      htp.p('
      <html><head><title></title>

      <script language=''JavaScript''><!--
      javascript:window.history.forward(1);
      //--></script>

      <style type="text/css"><!--
      body {cursor:wait;}
      --></style>

      </head>
      <body bgcolor="#ffffff" onLoad="parent.f_Ciclo();">
      '||vsProceso||'
      </body>
      </html>
      ');

  end p_Ciclo;

  procedure p_Inicio is


  begin
      htp.p('
      <html><head><title></title>

      <script language=''JavaScript''><!--
      javascript:window.history.forward(1);
      //--></script>

      <style type="text/css"><!--
      body {cursor:wait;}
      --></style>

      </head>
      <body bgcolor="#ffffff">
      '||vsProceso||'
      </body>
      </html>
      ');

  end p_Inicio;

  BEGIN
      -- valida que el usuario pertenezca a la base de datos.
      IF PK_Login.F_ValidacionDeAcceso(vgsUSR) THEN RETURN; END IF;

      -- se busca si el proceso ya termino
      BEGIN
          SELECT SWNTCKA_BEGIN,SWNTCKA_END
            INTO vdBegin, vdEnd
            FROM SWNTCKA
           WHERE SWNTCKA_SEQ       = pnSeq
             AND SWNTCKA_TERM_CODE = psTerm
             AND SWNTCKA_LEVL_CODE = psLevl
             AND SWNTCKA_PROCEDURE = 'PWAREG'||psStat
             AND SWNTCKA_USER      = psUser;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               vdEnd := NULL;
          WHEN OTHERS THEN
               vdEnd := NULL;
      END;


      IF    vdEnd IS NOT NULL THEN
            p_SiguienteEtapa;


            RETURN;
      ELSIF vdBegin IS NOT NULL AND vdEnd IS NULL THEN
            p_Ciclo;

            RETURN;
      END IF;

      p_Inicio;

      IF vdBegin IS NULL THEN
         IF    psStat = '1' THEN
               PWAREG1(psLevl, psTerm, pnSeq, psUser, psStat);

         ELSIF psStat = '2' THEN
               PWAREG2(psLevl, psTerm, pnSeq, psUser, psStat);

         ELSIF psStat = '3' THEN
               PWAREG3(psLevl, psTerm, pnSeq, psUser, psStat);

         ELSIF psStat = '4' THEN
               PWAREG4(psLevl, psTerm, pnSeq, psUser, psStat);

         END IF;
      END IF;


  END PWAREG6;
/


DROP PUBLIC SYNONYM PWAREG6;

CREATE PUBLIC SYNONYM PWAREG6 FOR BANINST1.PWAREG6;


GRANT EXECUTE ON BANINST1.PWAREG6 TO WWW_USER;

GRANT EXECUTE ON BANINST1.PWAREG6 TO WWW2_USER;

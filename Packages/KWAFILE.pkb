CREATE OR REPLACE PACKAGE BODY BANINST1.kwafile
IS
   /*******************************************************************************
            tarea: crear archivos en excel.
        pr�posito: enviar a un archivo de excel la informaci�n obtenida por los
                   reportes.
           m�dulo: general - uft.
            fecha: 19/05/2010.
            autor: gepc.

     modificaci�n: 21/10/2011 - hmr.
                   se orden� y actualiz� el llamado de cada uno los reportes del
                   sistema uft.
   *******************************************************************************/

   vgsUSR   VARCHAR2 (500);


   PROCEDURE xls (psReclProc VARCHAR2, psReclDesc VARCHAR2)
   IS
      vsTitulo   VARCHAR2 (600)
         := REPLACE (
               REPLACE (
                  REPLACE (
                     REPLACE (
                        REPLACE (
                           REPLACE (
                              REPLACE (
                                 REPLACE (
                                    REPLACE (
                                       REPLACE (psReclDesc, '~aacute', '�'),
                                       '~eacute',
                                       '�'),
                                    '~iacute',
                                    '�'),
                                 '~oacute',
                                 '�'),
                              '~uacute',
                              '�'),
                           '~AACUTE',
                           '�'),
                        '~EACUTE',
                        '�'),
                     '~IACUTE',
                     '�'),
                  '~OACUTE',
                  '�'),
               '~Uacute',
               '�');
   BEGIN
      IF Pk_Login.F_ValidacionDeAcceso (vgsUSR)
      THEN
         RETURN;
      END IF;

      IF psReclProc = 'PWRPGAC'
      THEN
         PWRPGAC (vsTitulo);
      -- ************************************************************************
      --    m�dulo de admisiones
      -- ************************************************************************

      -- hmr - 15/12/2010: para el reporte de decisi�n y seguimiento de directores
      ELSIF psReclProc = 'PWRSEGP'
      THEN
         PWRSEGP (vsTitulo);
      -- hmr - 04/01/2011: para el reporte de carga de postulaciones
      ELSIF psReclProc = 'PWRCPOS'
      THEN
         PWRCPOS (vsTitulo);
      -- hmr - 04/01/2011: para el reporte estad�stico por carrera y por colegio
      ELSIF psReclProc = 'PWRESTC'
      THEN
         PWRESTC (vsTitulo);
      -- hmr - 20/01/2011: para el reporte de s�ntesis de postulaciones
      ELSIF psReclProc = 'PWRSINP'
      THEN
         PWRSINP (vsTitulo);
      -- hmr - 21/02/2011: para el reporte de puntajes de ingreso
      ELSIF psReclProc = 'PWRPING'
      THEN
         PWRPING (vsTitulo);
      -- hmr - 23/02/2011: para el reporte de tramos psu
      ELSIF psReclProc = 'PWRTPSU'
      THEN
         PWRTPSU (vsTitulo);
      -- hmr - 23/02/2011: para el reporte de colegios de procedencia
      ELSIF psReclProc = 'PWRCOLP'
      THEN
         PWRCOLP (vsTitulo);
      -- hmr - 21/02/2011: para el reporte de ingresados seg�n v�a de ingreso
      ELSIF psReclProc = 'PWRIVIN'
      THEN
         PWRIVIN (vsTitulo);
      -- hmr - 07/01/2011: para el reporte de ingresados seg�n datos socioecon�micos
      ELSIF psReclProc = 'PWRIDSE'
      THEN
         PWRIDSE (vsTitulo);
      -- hmr - 07/03/2011: para el reporte de ingresados seg�n comuna de residencia
      ELSIF psReclProc = 'PWRISCR'
      THEN
         PWRISCR (vsTitulo);
      -- hmr - 04/01/2011: para el reporte de matriculados
      ELSIF psReclProc = 'PWRSEGM'
      THEN
         PWRSEGM (vsTitulo);
      -- hmr - 20/01/2011: para el reporte de postulaciones
      ELSIF psReclProc = 'PWRPOST'
      THEN
         PWRPOST (vsTitulo);
      -- mac - 02/02/2011: para el reporte para beca nem                      <-- revisar
      ELSIF psReclProc = 'PWRNEME'
      THEN
         PWRNEME (vsTitulo);
      -- hmr - 03/06/2011: para el reporte de seguimiento de directores
      ELSIF psReclProc = 'PWRSEGD'
      THEN
         PWRSEGD (vsTitulo);
      -- hmr - 16/06/2011: para el reporte para seguimiento de call center
      ELSIF psReclProc = 'PWRSCCA'
      THEN
         PWRSCCA (vsTitulo);
      -- hmr - 16/06/2011: para el reporte para seguimiento de call center - postulantes presenciales
      ELSIF psReclProc = 'PWRSCCP'
      THEN
         PWRSCCP (vsTitulo);
      --gvh: 2013/01/13: REPORTE DE CONVOCADOS
      ELSIF psReclProc = 'PWRCENS'
   THEN
         PWRCENS (vsTitulo);


      -- ************************************************************************
      --    m�dulo de programaci�n acad�mica
      -- ************************************************************************

      -- mac - 08/03/2011: para el reporte de eventos por sal�n               <-- revisar
      ELSIF psReclProc = 'PWREVXS'
      THEN
         PWREVXS (vsTitulo);
      -- jccr - 21/01/2011: para el reporte de n�mina de honorarios           <-- revisar
      ELSIF psReclProc = 'PWRNHON'
      THEN
         PWRNHON (vsTitulo);
      -- jccr - 21/01/2011: para el reporte de n�mina de planta               <-- revisar
      ELSIF psReclProc = 'PWRNOMP'
      THEN
         PWRNOMP (vsTitulo);
      -- jccr - 21/01/2011: para el reporte de pago de n�mina de honorarios   <-- revisar
      ELSIF psReclProc = 'PWRNHOE'
      THEN
         PWRNHOE (vsTitulo);
      -- jccr - 21/01/2011: para el reporte de pago de n�mina de planta       <-- revisar
      ELSIF psReclProc = 'PWRNHOP'
      THEN
         PWRNHOP (vsTitulo);
      -- hmr - 13/07/2011: para el reporte de ocupaci�n de salones por d�a (antes domino) v.2
      ELSIF psReclProc = 'PWROSAL'
      THEN
         PWROSAL (vsTitulo);
      -- hmr - 30/09/2011: para el reporte de pago de n�mina de honorarios  v.2
      ELSIF psReclProc = 'PWRNOMH'
      THEN
         PWRNOMH (vsTitulo);
      -- ************************************************************************
      --    m�dulo de toma de ramos
      -- ************************************************************************

      -- hmr - 25/05/2011: para el reporte de registro de materias inscritas
      ELSIF psReclProc = 'PWRMINS'
      THEN
         PWRMINS (vsTitulo);
      -- mac - 16/03/2011: para el reporte de alumnos inscritos con menos de 18 cr�ditos    <-- revisar
      ELSIF psReclProc = 'PWRAIMD'
      THEN
         PWRAIMD (vsTitulo);
       -- mac - 03/06/2013: para el reporte de baja de materias
      ELSIF psReclProc = 'PWRBJMA'
      THEN
         PWRBJMA (vsTitulo);

      -- ************************************************************************
      --    m�dulo de registro estudiantil
      -- ************************************************************************

      -- hmr - 08/07/2011: para el directorio de alumnos por periodo
      ELSIF psReclProc = 'PWRESTD'
      THEN
         PWRESTD (vsTitulo);
      -- mac - 08/03/2011: para el reporte de situaci�n acad�mica             <-- revisar
      ELSIF psReclProc = 'PWRSACD'
      THEN
         PWRSACD (vsTitulo);
      -- ************************************************************************
      --    m�dulo de profesores
      -- ************************************************************************

      -- hmr - 27/07/2011: para el reporte de directorio de profesores
      ELSIF psReclProc = 'PWRDRFY'
      THEN
         PWRDRFY (vsTitulo);
      -- hmr - 27/05/2011: para el reporte de s�ntesis de antecedentes acad�micos
      ELSIF psReclProc = 'PWRSAAD'
      THEN
         PWRSAAD (vsTitulo);
      -- ************************************************************************
      --    m�dulo de consulta al registro de calificaciones
      -- ************************************************************************


      -- ************************************************************************
      --    m�dulo de auditor�a
      -- ************************************************************************

      -- hmr - 31/05/2011: para el reporte de privilegios por objeto
      ELSIF psReclProc = 'PWRPOBJ'
      THEN
         PWRPOBJ (vsTitulo);
      -- hmr - 17/06/2011: para el reporte de privilegios por usuario (clases y objetos sueltos)
      ELSIF psReclProc = 'PWRPUCO'
      THEN
         PWRPUCO (vsTitulo);
      -- ************************************************************************
      --    m�dulo de motor de encuestas
      -- ************************************************************************


      -- ************************************************************************
      --    m�dulo de revisi�n de cumplimiento de grado/capp
      -- ************************************************************************


      -- ************************************************************************
      --    m�dulo de encuesta de evaluaci�n docente
      -- ************************************************************************

      -- jccr - 21/01/2011: para el archivo de datos eeda
      ELSIF psReclProc = 'PWRARCH'
      THEN
         PWRARCH (vsTitulo);
      -- ************************************************************************
      --    m�dulo de historia acad�mica
      -- ************************************************************************


      -- ************************************************************************
      --    m�dulo de registro curricular
      -- ************************************************************************


      -- ************************************************************************
      --    m�dulo de cat�logo de cursos
      -- ************************************************************************

      -- hmr - 28/07/2011: para el reporte de prerequisitos y correquisitos de asignatura
      ELSIF psReclProc = 'PWRPRAS'
      THEN
         PWRPRAS (vsTitulo);
      -- ************************************************************************
      --    m�dulo de matr�cula
      -- ************************************************************************

      -- aigui - 03/01/2011: para los reportes de matr�cula
      ELSIF psReclProc = 'PWCLADO'
      THEN
         PWCLADO (vsTitulo);
      ELSIF psReclProc = 'PWCONMA'
      THEN
         PWCONMA (vsTitulo);
      ELSIF psReclProc = 'PWRTIBE'
      THEN
         PWRTIBE (vsTitulo);
      ELSIF psReclProc = 'PWAUREN'
      THEN
         PWAUREN (vsTitulo);
      ELSIF psReclProc = 'PWRCNAN'
      THEN
         PWRCNAN (vsTitulo);
      ELSIF psReclProc = 'PWABCDE'
      THEN
         PWABCDE (vsTitulo);

      ELSIF psReclProc = 'PWRCENV'
      THEN
         PWRCENV (vsTitulo);
      ELSIF psReclProc = 'PWRCEN2'
      THEN
         PWRCEN2 (vsTitulo);
      ELSIF psReclProc = 'PWCCSXM'
      THEN
         PWCCSXM (vsTitulo);
      ELSIF psReclProc = 'PWADXCA'
      THEN
         PWADXCA (vsTitulo);
      ELSIF psReclProc = 'PWRMNLA'
      THEN
         PWRMNLA (vsTitulo);
      ELSIF psReclProc = 'PWRMNLD'
      THEN
         PWRMNLD (vsTitulo);
      ELSIF psReclProc = 'PWRMTMT'
      THEN
         PWRMTMT (vsTitulo);
      ELSIF psReclProc = 'pk_matcortecaja.PWRMCCG'
      THEN
         pk_MatCorteCaja.PWRMCCG (vsTitulo);
      ELSIF psReclProc = 'pk_matcortecaja.PWRMCCC'
      THEN
         pk_MatCorteCaja.PWRMCCC (vsTitulo);
      ELSIF psReclProc = 'pk_matcortecaja.PWRMCCD'
      THEN
         pk_MatCorteCaja.PWRMCCD (vsTitulo);
      ELSIF psReclProc = 'pk_matcortecaja.PWRMCSD'
      THEN
         pk_MatCorteCaja.PWRMCSD (vsTitulo);
      ELSIF psReclProc = 'PWMATCO'
      THEN
         PWMATCO (vsTitulo);
      -- aigui - 16/05/2011: para el reporte de factoring
      --ELSIF psreclproc = 'pk_Factoring.PWRFACT' THEN
      --      pk_Factoring.PWRFACT(vstitulo);
      ELSIF psReclProc = 'PWRMDC'
      THEN
         PWRMDC (vstitulo);
       ELSIF psReclProc = 'PWRMNLI'
      THEN
         PWRMNLI (vstitulo);
       ELSIF psReclProc = 'PWRMNLD3'
      THEN
         PWRMNLD3 (vstitulo);
      ELSIF psReclProc = 'PWRRGMC' --GVH 20130318 rep global montos x contrato
      THEN
         PWRRGMC (vsTitulo);
      ELSIF psReclProc = 'PWRRGCN' --GVH 20130318 rep global contabilidad
      THEN
         PWRRGCN (vsTitulo);
      ELSIF psReclProc = 'PWRRHDM' --GVH 20130318 rep historico documentos mat
      THEN
         PWRRHDM (vsTitulo);
      ELSIF psReclProc = 'PWRGEST' --Reporte general de estudiates
      THEN
         PWRGEST (vstitulo);
         ELSIF psReclProc = 'PWRCICO' --Reporte de gestion e cuentas de correo.
      THEN
         PWRCICO (vstitulo);
      ELSIF psReclProc = 'PWRMORO' --Reporte de morosidad
      THEN
         PWRMORO (vstitulo, null, '1');
      ELSIF psReclProc = 'PWRCUFT' -- Reporte de Cohortes UFT
       THEN
          PWRCUFT (vstitulo);
     ELSIF psReclProc = 'PWLIBVP' -- Reporte de Libro de Ventas CFC
       THEN
          PWLIBVP (vstitulo);
     ELSIF psReclProc = 'PWLIBVE' -- Reporte de Libro de Ventas
       THEN
          PWLIBVE (vstitulo);
     ELSIF psReclProc = 'PWRSCAE' -- Reporte de An�lisis FUAS CAE
       THEN
          PWRSCAE  (vstitulo);
     ELSIF psReclProc = 'PWRBFUA' -- Reporte de An�lisis regla 70pct  CAE
       THEN
          PWRBFUA  (vstitulo);
     ELSIF psReclProc = 'PWRPRSL' -- Reporte de An�lisis Carga Preseleccionados CAE
       THEN
          PWRPRSL  (vstitulo);
     ELSIF psReclProc = 'PWREVHT' -- Reporte de An�lisis Carga Historica CAE
       THEN
          PWREVHT  (vstitulo);
     ELSIF psReclProc = 'PWRLSA2' -- Reporte de Cursos no usadados CAPP
       THEN
          PWRLSA2  (vstitulo);
      ELSIF psReclProc = 'PWRCOMA' -- Reporte Concentrado de Matricula
          then
          PWRCOMA  (vstitulo);
     ELSIF psReclProc = 'PWRDEMA' -- Reporte Concentrado de Matricula
          then
          PWRDEMA  (vstitulo);
     ELSIF psReclProc = 'PWRRGFE' -- Reporte configuracion Reglas de cobro   -- rra  03/may/2016
          then
          PWRRGFE  (vstitulo);
     ELSIF psReclProc = 'PWRDCPA' -- Reporte DOC PAGADOS  arqueo          -- rra  09/jun/2016
          then
          PWRDCPA  (vstitulo);

     END IF;

   END xls;
END kwafile; 
/


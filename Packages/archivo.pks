CREATE OR REPLACE PACKAGE BANINST1.archivo IS
/*
        Tarea: Almacenar las fotos de los alumnos en (SWRFOTO)
       Modulo: General
        Fecha: 23/08/2011
        Autor: RZL
---------------------------
 Modificación:  md-01
 cambio         se hacen adecuaciones a UTF
 autor          Roman Ruiz
 fecha          09-jul-2014
 
  --------------------------
  Modificación:  md-05
 cambio         paso de parametro de fecha.
 autor          Roman Ruiz
 fecha          26-oct-2016

*/

  --APLICACIÓN PARA REGISTRAR FOTOGRAFIAS DE ALUMNOS
  PROCEDURE TeleCharger(psParametro VARCHAR2 DEFAULT NULL);

-- md-05
  PROCEDURE guardaFoto(name         OWA_UTIL.ident_arr,
                       psCamp       VARCHAR2,
                       psUrl        VARCHAR2,
                       psUser       VARCHAR2,
                       psAplicacion VARCHAR2,
                       pnSecuencia  NUMBER DEFAULT NULL,
                       pstxtFecha   varchar2            --md-05
                      );

/*                      
  PROCEDURE guardaFoto(name         OWA_UTIL.ident_arr,
                       psCamp       VARCHAR2,
                       psUrl        VARCHAR2,
                       psUser       VARCHAR2,
                       psAplicacion VARCHAR2,
                       pnSecuencia  NUMBER DEFAULT NULL
                      );         

*/                                   
 
  --GENERA LA PAGINA PARA PRESENTAR EL LISTADO DE LAS FOTOS REGISTRADAS
  PROCEDURE Lista(psID VARCHAR2
                 );

  --LEE EL ARCHIVO BLOB PARA SER PRESENTADO EN HTML
  PROCEDURE jpg(pnPidm NUMBER);

  --ESTILO
  PROCEDURE css;

  --CÓDIGO JS
  PROCEDURE js;

END archivo;
/

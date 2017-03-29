CREATE OR REPLACE PACKAGE BANINST1.KWACTLG IS

/*
         TAREA: C�digo AJAX para llenar objetos "SELECT" y el objeto "boxFrame"
                que es creado con el paquete "KWAPRMG1"
        MODULO: Porgramaci�n Acad�mica
    APLICACION: Programas Magisteriales
         FECHA: 10/02/2014
         AUTOR: MAC

  MODIFICACION: El historico de modificaciones consultalo en el PACKAGE BODY.

*/

  --LLENA UN OBJETO "SELECT" DE HTML
  PROCEDURE catalogo(psCatalogo VARCHAR2,
                     psFiltro1  VARCHAR2 DEFAULT NULL,
                     psFiltro2  VARCHAR2 DEFAULT NULL,
                     psFiltro3  VARCHAR2 DEFAULT NULL,
                     psFiltro4  VARCHAR2 DEFAULT NULL,
                     psFiltro5  VARCHAR2 DEFAULT NULL
                    );

  --CREA UN P�GINA PARA LA SELECCI�N DE CHECKBOX
  PROCEDURE paginaHTML(psPagina  VARCHAR2,
                       psFiltro1 VARCHAR2 DEFAULT NULL,
                       psFiltro2 VARCHAR2 DEFAULT NULL,
                       psFiltro3 VARCHAR2 DEFAULT NULL,
                       psFiltro4 VARCHAR2 DEFAULT NULL,
                       psFiltro5 VARCHAR2 DEFAULT NULL,
                       psCambio  VARCHAR2 DEFAULT NULL
                      );

  --HOJAS DE ESTILOS PARA EL PROCEDIMINETO "paginaHTML"
  PROCEDURE css;

  --C�DIGO JavaScript PARA EL PROCEDIMINETO "paginaHTML"
  PROCEDURE js;

END KWACTLG;
/
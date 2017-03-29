DROP PROCEDURE BANINST1.PWACLSD;

CREATE OR REPLACE PROCEDURE BANINST1.PWACLSD(psNombreFuncion VARCHAR2 DEFAULT NULL,
                                             psTitulo        VARCHAR2 DEFAULT NULL,
                                             psMensaje1      VARCHAR2 DEFAULT NULL,
                                             psMensaje2      VARCHAR2 DEFAULT NULL,
                                             psEvento        VARCHAR2 DEFAULT NULL
                                            ) IS

/*
   AUTOR: GEPC
   FECHA: 22/03/2010
   TAREA: Craea la función en lenguale JavaSCript "paginaSalir", para reabrir una pagina HTML
          y no crear una sesion en el servidor WEB y en la instancia de base de datos.
  MODULO: GENERAL

*/

  vsTitulo   VARCHAR2(1000) := 'Salir de la aplicación';
  vsMensaje1 VARCHAR2(1000) := 'La aplicación se esta cerrando...';

  BEGIN
      vsTitulo   := NVL(psTitulo,  vsTitulo);
      vsMensaje1 := NVL(psMensaje1, vsMensaje1);

      htp.p(
      'function paginaSalir'||psNombreFuncion||'() {
      document.open();
      document.writeln("<html><head><title>'||vsTitulo||'<\/title>");

      document.writeln("<meta http-equiv=''Expires''       CONTENT=''0''>");
      document.writeln("<meta http-equiv=''Cache-Control'' CONTENT=''no-cache''>");
      document.writeln("<meta http-equiv=''Pragma''        CONTENT=''no-cache''>");
      document.writeln("<link rel=''stylesheet'' href=''\/css\/web_defaultapp.css'' TYPE=''text\/css''>");
      document.writeln("<script type=''text/javaScript''><!--");
      document.writeln("javascript:window.history.forward(1);");

      document.writeln("function fCerrarVentana() {");'
      );

      IF psEvento IS NULL THEN
         htp.p(
         'document.writeln("setTimeout(''fClose()'',3000);");'
         );
      ELSE
         htp.p(
         'document.writeln("fAplicacion();");'
         );
      END IF;

      htp.p(
      'document.writeln("}");

      document.writeln("function fClose() {");
      document.writeln("close();");
      document.writeln("}");

      document.writeln("function DerechosReservados() {");
      document.writeln("if (event.button==2) {");
      document.writeln("alert(''Operación deshabilitada.'');");
      document.writeln("}");
      document.writeln("}");

      document.writeln("function fAplicacion() {");
      document.writeln("setTimeout(\"fAbriendo()\",3000);");
      document.writeln("}");

      document.writeln("function fAbriendo() {");
      document.writeln("document.frmMenuAplicacion.submit();");
      document.writeln("}");

      //document.writeln("document.onmousedown=DerechosReservados;");
      document.writeln("\/\/--><\/script>");
      document.writeln("<\/head><body bgcolor=''#ffffff'' style=''cursor:wait;'' onLoad=''fCerrarVentana();''><br\/><br\/><br\/><br\/><br\/>");

      document.writeln("<table border=''0'' width=''100%'' align=''center'' cellpadding=''0'' cellspacing=''0''>");
      document.writeln("<tr><th align=''left'' valign=''bottom''>");
      document.writeln("'||vsTitulo||'<\/th><\/tr>");
      document.writeln("<\/table>");
      document.writeln("<br\/>");
      document.writeln("<table class=''plaintable'' width=''100%'' cellSpacing=''0'' cellPadding=''0'' border=''0''>");
      document.writeln("<tr class=''trSeparado4''>");
      document.writeln("<td class=''bg3'' width=''100%''>");
      document.writeln("<img src=''/wtlgifs/web_transparent.gif'' hspace=''0'' vspace=''0'' border=''0'' height=''3'' width=''10''></td>");
      document.writeln("</tr>");
      document.writeln("</table>");
      document.writeln("<br\/>");

      document.writeln("<p><center><font size=''6''>'||vsMensaje1||'<\/font><\/center><\/p>");'
      );

      IF psMensaje2 IS NOT NULL THEN
         htp.p(
         'document.writeln("<p><center><font size=''6''>'||psMensaje2||'<\/font><\/center><\/p>");'
         );
      END IF;

      htp.p(
      'document.writeln("<br\/>");
      document.writeln("<table border=''0'' width=''100%'' align=''center'' cellpadding=''0'' cellspacing=''0''>");
      document.writeln("<tr><th align=''right'' valign=''bottom''>");

      document.writeln("<\/th><\/tr>");
      document.writeln("<\/table>");
      document.writeln("<br\/>");

      document.writeln("<form name=''frmMenuAplicacion'' action=''pk_AsignaAplicacion.P_Aplicacion'' target=''_top'' method=''post''>");
      document.writeln("<input type=''hidden'' name=''psParametro'' value=''ADM'' \/>");
      document.writeln("<\/form>");

      document.writeln("<br\/>");
      document.writeln("<table class=''plaintable'' width=''100%'' cellSpacing=''0'' cellPadding=''0'' border=''0''>");
      document.writeln("<tr class=''trSeparado4''>");
      document.writeln("<td class=''bg3'' width=''100%''>");
      document.writeln("<img src=''/wtlgifs/web_transparent.gif'' hspace=''0'' vspace=''0'' border=''0'' height=''3'' width=''10''></td>");
      document.writeln("</tr>");
      document.writeln("</table>");

      document.writeln("<table border=''0'' width=''100%'' align=''center'' cellpadding=''0'' cellspacing=''0''>");
      document.writeln("<tr><th align=''right'' valign=''bottom''>");
      document.writeln("<img src=''\/imagenes\/UFT.gif''>");
      document.writeln("<\/th><\/tr>");
      document.writeln("<\/table>");
      document.writeln("<br\/>");

      document.writeln("<\/body><\/html>");
      document.close();

      } //paginaSalir'
      );
  END PWACLSD;
/


DROP PUBLIC SYNONYM PWACLSD;

CREATE PUBLIC SYNONYM PWACLSD FOR BANINST1.PWACLSD;

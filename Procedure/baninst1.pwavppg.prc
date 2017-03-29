CREATE OR REPLACE PROCEDURE baninst1.pwavppg(psSIU VARCHAR2 DEFAULT NULL) IS

  /*
     TAREA: * Identificar con claridad cantidad de nodos
            * Identificar total de PIPEs y GURJOBS por NODO
     FECHA: 05/09/2014
    MODULO: General
     AUTOR: GEPC

  */

  vgnNodo number(2) := 0;

  --numero de nodos
  --getCantidadNodos
  function getCantidadNodos return number is

  vnNodos number(2) := 0;

  begin
      select count(distinct inst_id) as nodos
        into vnNodos
        from gv$session;

      return vnNodos;
  end getCantidadNodos;

  --titulos de nodos
  --setTituloNodos
  procedure setTituloNodos is

  begin
      htp.p(
      '<table border="0" cellpadding="1" cellspacing="1" width="100%" align="center" >'||
      '<tr>'||
      '<th colspan="3" class="delabel">En el sistema existen '||vgnNodo||' nodos.'||
      '</th></tr>'||
      '<td width="20%" align="right"><b>PIPE: </b></td><td width="60%">Debe existir 10 PIPEs por nodo.'||
      '</td>'||
      '<td width="20%">'
      );

      if psSIU is null then
         htp.p(
         '<a href="javascript:parent.closeVerifica();" '||
                            'onMouseover="window.status=''Cierra verificación''; return true" '||
                            'onMouseout="window.status=''; return true" '||
                               'OnFocus="window.status=''Cierra verificación''; return true" '||
                                'onBlur="window.status=''; return true" class="submenulinktext2">'||
         'Cierra verificación</a>'
         );
      end if;


      htp.p('</td>'||
      '</tr>'||
      '<td align="right"><b>gurJob: </b></td><td>Debe existir 1 gurJob por nodo.'||
      '</td>'||
      '<td>&nbsp;</td>'||
      '</tr>'||
      '</table>'
      );
  end setTituloNodos;


  --procesos de PIPES y GURJOBS en ejecución
  --setListaProcesos
  procedure setListaProcesos is

  vnRac  number(2) := 0;
  vnRows number    := 0;
  vnCero number    := 0;

  cn1        constant number(1)   := 1;
  csPIPE     constant varchar2(4) := 'PIPE';
  cs_PIP_    constant varchar2(5) := '%PIP%';
  csGENLPRD  constant varchar2(7) := 'GENLPRD';
  csSFRPIPE  constant varchar2(7) := 'SFRPIPE';
  csGURJOBS  constant varchar2(7) := 'GURJOBS';
  csGURJob2  constant varchar2(7) := 'gurJobs';
  csSFRPIPE_ constant varchar2(8) := 'SFRPIPE%';


  --cuProcesos
  cursor cuProcesos is
         select inst_id                            as Nodo,
                decode(module,csSFRPIPE,csPIPE,
                              csGURJOBS,csGURJob2,
                              module)              as Proc,
                username                           as Usee,
                count(cn1)                         as Cant
           from gv$session
          where (    upper(program) like cs_PIP_
                 or
                     upper(program) like csSFRPIPE_
                 or
                     username = csGENLPRD
                 or
                     module = csSFRPIPE
                 or
                     module = csGURJOBS
                )
          group by inst_id,module,username
          order by inst_id,module;

  begin
      htp.p(
      '<br>'||
      '<table border="0" cellpadding="1" cellspacing="1" width="100%" align="center" style="border-collapse:collapse;border:none;">'||
      '<tr bgcolor="#dddddd">'||
      '<th style="border:solid 1.0pt #dddddd;" width="20%">Nodo</th>'||
      '<th style="border:solid 1.0pt #dddddd;" width="20%">Proceso</th>'||
      '<th style="border:solid 1.0pt #dddddd;" width="20%">Usuario</th>'||
      '<th style="border:solid 1.0pt #dddddd;" width="40%">Cantidad de procesos</th>'||
      '</tr>'
      );

      for regPrc in cuProcesos loop
          vnRows := vnRows + 1;

          if vnRac = regPrc.Nodo then
             regPrc.Nodo := null;
          end if;

          htp.p(
          '<tr>'
          );

          if regPrc.Nodo is not null then
             htp.p(
             '<td style="border:solid 1.0pt #dddddd;" align="center" rowspan="2" bgcolor="#efefef">'||regPrc.Nodo||'</td>'
             );
          end if;

          htp.p(
          '<td style="border:solid 1.0pt #dddddd;" valign="top" align="center">'||regPrc.Proc||'</td>'||
          '<td style="border:solid 1.0pt #dddddd;" valign="top" align="center">'||regPrc.Usee||'</td>'||
          '<td style="border:solid 1.0pt #dddddd;" valign="top" align="center">'||regPrc.Cant||'</td>'||
          '</tr>'
          );


          if regPrc.Nodo is null then
             htp.p(
             '<tr>'||
             '<td style="border-left:solid 1.0pt #ffffff;border-right:solid 1.0pt #ffffff;" colspan="4">&nbsp;</td>'||
             '</tr>'
             );
          end if;

          vnRac := regPrc.Nodo;
      end loop;

      htp.p(
      '<tr>'||
      '<td colspan="4" align="center">'
      );

      begin
          select mod(vnRows,2)
            into vnCero
            from dual;

          if vnCero = 0 and vnRows > 0 then
             htp.p('<img src="/imagenes/acreditado.jpg" name="imgPipe" value="0" border="0" />');
          else
             htp.p('<img src="/imagenes/sincursar.jpg" name="imgPipe" value="0" border="0" /> ');
          end if;

      exception
          when others then
               htp.p('<img src="/imagenes/sincursar.jpg" name="imgGurj" value="0" border="0"  />');
      end;

      htp.p(
      '</td>'||
      '</tr>'||
      '</table>'
      );

  end;

  --seguridad
  procedure seguridad is

  begin
      if pk_login.f_validaciondeacceso(pk_login.vgsusr) then return; end if;
  end seguridad;

  BEGIN
      vgnNodo := getCantidadNodos();

      htp.p(
      '<br/>'||
      '<center>'||
      '<table border="0" width="60%" cellpadding="1" cellspacing="1" style="border:solid #FCB656 2.0pt;"><tr><td>'
      );

      --titulos de nodos
      setTituloNodos();

      --procesos de PIPES y GURJOBS en ejecución
      setListaProcesos();

      htp.p(
      '</td></tr></table>'||
      '<center>'||
      '<br/>'
      );

  END pwavppg;
/
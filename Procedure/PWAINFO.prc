CREATE OR REPLACE PROCEDURE BANINST1.PWAINFO(psProceso  VARCHAR2,
                                  psEtiqueta VARCHAR2,
                                  psValor1   VARCHAR2 DEFAULT NULL,
                                  psValor2   VARCHAR2 DEFAULT NULL,
                                  psValor3   VARCHAR2 DEFAULT NULL,
                                  psValor4   VARCHAR2 DEFAULT NULL,
                                  psValor5   VARCHAR2 DEFAULT NULL,
                                  psValor6   VARCHAR2 DEFAULT NULL
                                 ) IS

  --cuMensaje
  cursor cuMensaje is
         select twgrinfo_image as IMAG,
                twgrinfo_text  as TEXT
           from twgrinfo
          where twgrinfo_name  = psProceso
            and twgrinfo_label = psEtiqueta
          order by twgrinfo_sequence;

  BEGIN
      for regIns in cuMensaje loop

          htp.p(
          '<DIV class="infotextdiv">'||
          '<TABLE  CLASS="infotexttable">'||
          '<TR><TD CLASS="indefault">'
          );

          if regIns.IMAG is not null then
             htp.p(
             '<IMG SRC="/wtlgifs/'||regIns.IMAG||'.gif" CLASS="headerImg" TITLE=""  NAME="web_info" HSPACE=0 VSPACE=0 BORDER=0 HEIGHT=28 WIDTH=30>'
             );
          end if;

          htp.p(
          '</TD>'||
          '<TD CLASS="indefault">'||
          '<SPAN class="infotext">'||replace(replace(replace(replace(replace(replace(regIns.TEXT,'%1%',psValor1),'%2%',psValor2),'%3%',psValor3),'%4%',psValor4),'%5%',psValor5),'%6%',psValor6)||
          '</SPAN></TD></TR></TABLE><P></DIV>'
          );
      end loop;
  END PWAINFO;
/


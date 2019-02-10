unit vServerLog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, vVar;

procedure WriteSafeText(const S: string; Log_Level: word = 0);

implementation


procedure Log_Add(s : string; log_level : word = 0);
var
  C_FNAME, dt, cl: string;
  tfOut: TextFile;
begin
  // Связываем имя файла с переменной
  C_FNAME := 'http/re_log.html';

  dt:=DateToStr(Date);
  dt:=dt+' '+TimeToStr(Time);

  AssignFile(tfOut, C_FNAME);
  // Использовать исключение для перехвата ошибок (это по умолчанию и указывать не обязательно)
  {$I+}

  // Для обработки исключений, используем блок try/except
  try
    // Создать файл, записать текст и закрыть его.
    if FileExists(C_FNAME) then Append(tfOut) else
    rewrite(tfOut);

    case log_level of
    0: cl := '$000000';
    1: cl := '$00aa00';
    3: cl := '$cc0000';
    255:
      begin
        Rewrite(tfOut);
        cl := '$00aa00';
        writeln(tfOut, '<html> ');
        writeln(tfOut, '<head> ');
        writeln(tfOut, '<meta charset="utf-8"> ');
        writeln(tfOut, '<title>MT Reborn server log</title>  ');
        writeln(tfOut, '</head> ');
        writeln(tfOut, '<body>  ');
      end
    else
      cl := '$0000cc';
    end;

    writeln(tfOut, '<font color=' + cl + '>[' + dt + '] : ' + s + '</font><br>');

    CloseFile(tfOut);

  except
    // Если ошибка - отобразить её
    on E: EInOutError do
      writeln('Log Error. Details: ', E.ClassName, '/', E.Message);
  end;

end;

//В многопоточном приложении нужно безопасно работать с данными :)
//А сеть у нас многопоточная, данные могут придти в любое время!
procedure WriteSafeText(const S: string; Log_Level: word = 0);
begin
  CS.Enter;
  Try
    Log_Add(S, log_level);
    //не допускаем одновременного вывода в консоль иначе у нас программа упадёт
    WriteLn(S);
  finally
    CS.Leave;
  end;
end;


end.



unit uObjManager;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, vNetCore, vVar;

procedure Obj_SendDialogs(sID, oID : DWORD);

//procedure Obj_QuestProcess(charLID, qLink : DWORD);

implementation

uses uPkgProcessor, uDB, vServerLog;

procedure Obj_SendDialogs(sID, oID : DWORD);
var _head: TPackHeader; _pkg : TPkg041;
    mStr : TMemoryStream;
    i, j, k, n : integer;
    rs, rs2, rs3, rs4, cV : word;
    charLID : dword;
begin
  for i := 1 to 10 do      // обнуляем диалоги
    _pkg.data[i].dID:=0;
  CharLID := Sessions[sID].charLID;
                           // записываем базовые данные про объект
  _pkg.ID := oID;
  _pkg.pic:= LocObjs[oID].pic;
  _pkg.descr:=LocObjs[oID].discr;
  _pkg.name:=LocObjs[oID].name;
                           // Делаем выборку диалогов
  rs := 0; rs2 := 0; rs3 := 0; rs4 := 0; k := 1;
  for i := 1 to 25 do
  begin
    if LocObjs[oID].props[i] <> 0 then
       begin
         {сначала проверяем по qVar. Проверяем количество заявленых кВаров
          и количество совпадений по значениям. Если совпадает, то пропускаем
         }
         rs := 0; rs2 := 0;
         if ObjDialogs[LocObjs[oID].props[i]].vName <> '' then
            begin
              inc(rs2);
              if DB_GetCharVar( charLID, ObjDialogs[LocObjs[oID].props[i]].vName) = ObjDialogs[LocObjs[oID].props[i]].vVal then inc(rs);
            end;
         if ObjDialogs[LocObjs[oID].props[i] ].vName2 <> '' then
            begin
              inc(rs2);
              if DB_GetCharVar( charLID, ObjDialogs[LocObjs[oID].props[i]].vName2) = ObjDialogs[LocObjs[ oID].props[i] ].vVal2 then inc(rs);
            end;
         if ObjDialogs[LocObjs[oID].props[i] ].vName3 <> '' then
            begin
              inc(rs2);
              if DB_GetCharVar( charLID, ObjDialogs[LocObjs[oID].props[i]].vName3) = ObjDialogs[LocObjs[oID].props[i] ].vVal3 then inc(rs);
            end;
     //    WriteSafeText(IntToStr(i) +'> RS <> RS2 ' + IntToStr(rs) + ' === ' + IntToStr(rs2), 2);

         if rs2 > 0 then
         if rs = rs2 then
            begin
              rs3 := 0; rs4 := 0;
              {Теперь делаем проверку по скрипту.
                * Проверяем наличие скриптовых условий
                  1 - наличие предмета в сумке
                  10 - проверка счётчика
                * Проверяем выполнение скриптовых условий
              }
              for j := 1 to 25 do
                if (j = 1) or (j / 4 = j div 4) then
                begin
                   inc(rs4);
                   case ObjDialogs[LocObjs[oID].props[i] ].props[j]  of
                     1 :  // проверка на наличие предмета
                       begin
                         for n := 1 to high(chars[charLID].Inventory) do
                           if chars[charLID].Inventory[n].iID = ObjDialogs[LocObjs[oID].props[i] ].props[j + 1]  then
                              if chars[charLID].Inventory[n].cDur >= ObjDialogs[LocObjs[oID].props[i] ].props[j + 2]  then inc(rs3);
                       end;
                     10 :  // проверка по счётчику
                       begin
                         cV := DB_GetCharCounter(charLID, ObjDialogs[LocObjs[oID].props[i] ].props[j + 1] );
                         if cV >= ObjDialogs[LocObjs[oID].props[i] ].props[j + 2]  then inc(rs3);

                       end;
                   else
                     inc(rs3);
                   end;
                end;
              WriteSafeText(IntToStr(i) +'> RS3 <> RS4 ' + IntToStr(rs3) + ' === ' + IntToStr(rs4), 2);
              if rs3 = rs4 then
              begin
                _pkg.data[k] := ObjDialogs[LocObjs[oID].props[i]].data;
                writeln('Add dlg ## ', _pkg.data[k].dID);
                inc(k);
              end;
            end;
            end;
  end;
  Writeln('Totals :', k - 1);
  try
         mStr := TMemoryStream.Create;
         _head._flag := $F;
         _head._id   := 41;

         _pkg.fail_code := k - 1;

         mStr.Write(_head, sizeof(_head));
         mStr.Write(_pkg, sizeof(_pkg));

         // Отправляем пакет
         TCP.FCon.IterReset;
         while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
       finally
         mStr.Free;
       end;
end;

//procedure Obj_QuestProcess(charLID, qLink : DWORD);

end.


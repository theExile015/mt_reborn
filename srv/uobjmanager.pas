unit uObjManager;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, vNetCore, vVar;

procedure Obj_SendDialogs(sID, oID : DWORD);
//procedure Obj_SendVendors(sID, oID : DWORD)

procedure Obj_QuestSend(charLID, dID : DWORD);
procedure Obj_QuestProcess(sID, qID, rID, f_code : DWORD);
procedure Obj_StartQuestBattle(charLID, dID : DWORD);
procedure Obj_StartBattle(charLID, ceUID : DWORD);

implementation

uses uPkgProcessor, uDB, vServerLog, uCharManager, uCombatProcessor;

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

procedure Obj_QuestSend(charLID, dID : DWORD);
var _head: TPackHeader; _pkg : TPkg042;
    mStr : TMemoryStream;
    qlid : dword;
begin
  qlid := objdialogs[did].qLink;
  if not QuestDB[qLID].exist then exit;

  _head._flag:=$f;
  _head._id:=42;
  _pkg.qID:=qLID;

  if ObjDialogs[dID].data.dType = 11 then
     begin
       _pkg.name:=questDB[qlid].name;
       _pkg.descr:=Copy(questDB[qlid].discr, 1, 255);
       _pkg.descr2:=Copy(questDB[qlid].discr, 256, 255);
       _pkg.descr3:=Copy(questDB[qlid].discr, 511, 255);
       _pkg.obj:=questDB[qlid].objective;
       _pkg.reward := questDB[qlid].prors;
       _pkg.spic:= questDB[qlid].spic;
       _pkg.smask:= questDB[qlid].smask;
       _pkg.fail_code := 11;
     end;

  if ObjDialogs[dID].data.dType = 7 then
     begin
       _pkg.name:=questDB[qlid].name;
       _pkg.descr:=Copy(questDB[qlid].fdiscr, 1, 256);
       _pkg.descr2:=Copy(questDB[qlid].fdiscr, 256, 256);
       _pkg.descr3:=Copy(questDB[qlid].fdiscr, 511, 256);
       _pkg.reward := questDB[qlid].prors;
       _pkg.spic:= questDB[qlid].fpic;
       _pkg.smask:= questDB[qlid].fmask;
       _pkg.fail_code := 7;
     end;

  try
         mStr := TMemoryStream.Create;

         mStr.Write(_head, sizeof(_head));
         mStr.Write(_pkg, sizeof(_pkg));

         // Отправляем пакет
         TCP.FCon.IterReset;
         while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
       finally
         mStr.Free;
       end;
end;


procedure Obj_QuestProcess(sID, qID, rID, f_code : DWORD);
var  qS, charLID : DWORD;
     i, j : integer;
begin
   charLID := Sessions[sID].charLID;
   Writeln(' Processing quest ID = ', qID);
   qS := 0;
   qS := DB_GetCharVar(charLID, QuestDB[qID].vName );

 //  if qID = 2 then qS :=

   if qS > f_code then Exit;

   if f_code = 0 then
      begin
        for j := 1 to 25 do
            if (j - 1) / 3 = (j - 1) div 3 then
               case questDB[qID].props2[j] of
                    7:
                      begin
                        Char_AddItem(charLID, questDB[qID].props2[j + 1]);
                        DB_GetCharInv(charLID);
                      end;
                    10:
                      begin
                        DB_StartCharCounter(charLID, questDB[qID].props2[j + 1],
                        1, questDB[qID].props2[j + 2] );
                      end;
               end;
      end;

   if f_code = 1 then
     begin
        Char_AddNumbers(charLID, questDB[qID].prors[2], questDB[qID].prors[1], 0, 0, 0);
        for i := 1 to 3 do
            if questDB[qID].prors[i * 2 + 1] <> 0 then
               Begin
                 WriteLN(questDB[qID].prors[i * 2 + 1]);
                 Char_AddItem(charLID, questDB[qID].prors[i * 2 + 1] );
               end;
        if rID <> 0 then
        if questDB[qID].prors[rID * 2 + 1] > 0 then
           Char_AddItem(charLID, questDB[qID].prors[rID * 2 + 1]);

        for j := 1 to 25 do
            if (j - 1) / 3 = (j - 1) div 3 then
               case questDB[qID].props2[j] of
                    1:
                      begin
                        for i := 1 to high(chars[charLID].Inventory) do
                            if chars[charLID].Inventory[i].iID = questDB[qID].props2[j + 1] then
                               DB_DelItem(charLID, i);
                        DB_GetCharInv(charLID);
                      end;
                    2:
                      begin
                        DB_SetCharVar(charLID, questDB[qID].props2[j + 2],
                                               'v' + IntToStr(questDB[qID].props2[j + 1]));
                        Char_SendLocObjs(charLID, chars[charLID].header.loc);
                      end;
               end;
     end;

  DB_SetCharVar( charLID, qS + 1, QuestDB[qID].vName );
end;

procedure Obj_StartQuestBattle(charLID, dID : DWORD);
var i, r   : integer;
    comLID : Word;
    _head  : TPackHeader; _pkg : TPkg100;
    mStr   : TMemoryStream;
begin
  r := high(word);

  if objDialogs[dID].data.dType = 3 then
     r := CM_StartNew(charLID, 1, objDialogs[dID].qLink);

  if r = high(word) then exit;

  comLID := CM_GetCombatLID(r);

  _head._flag := $f;
  _head._id   := 100;

  _pkg.ID := r;
  _pkg.ceType := 1;
  _pkg.ceround  := combats[comLID].ceRound;

       try
         mStr := TMemoryStream.Create;

         mStr.Write(_head, sizeof(_head));
         mStr.Write(_pkg, sizeof(_pkg));

         // Отправляем пакет
         TCP.FCon.IterReset;
         while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
       finally
         mStr.Free;
         CM_SendUnits(comLID, charLID);
       end;
end;

procedure Obj_StartBattle(charLID, ceUID : DWORD);
var i, r   : integer;
    comLID : Word;
    _head  : TPackHeader; _pkg : TPkg100;
    mStr   : TMemoryStream;
begin
  r := high(word);
                     // не может существовать более 1 экземпляра
                     // (в отличие от квестовых боёв)
                     // поэтому делаем проверочку
  for i := 0 to high(combats) do
    if combats[i].ceUID = ceUID then
       r := i;
  if r = high(word) then
     r := CM_StartNew(charLID, 1, ceUID) else exit; // затычка

  if r = high(word) then exit;

  comLID := CM_GetCombatLID(r);

  _head._flag := $f;
  _head._id   := 100;

  _pkg.ID := r;
  _pkg.ceType := 1;
  _pkg.ceround  := combats[comLID].ceRound;

       try
         mStr := TMemoryStream.Create;

         mStr.Write(_head, sizeof(_head));
         mStr.Write(_pkg, sizeof(_pkg));

         // Отправляем пакет
         TCP.FCon.IterReset;
         while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
       finally
         mStr.Free;
         CM_SendUnits(comLID, charLID);
       end;
end;

end.


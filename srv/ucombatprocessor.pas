unit uCombatProcessor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  vVar,
  vNetCore,
  DOS,
  uAI;


function CM_StartNew(initiator, ceType, ceUID : DWORD): word;
function CM_AddPUnit(comID, charLID: DWORD; uTeam : byte) : byte;
function CM_AddAIUnit(comID, uID : DWORD; uTeam : byte) : byte;

function CM_GetPUnitsNum( comLID : DWORD) : byte;
function CM_GetCombatLID( comID : DWORD) : DWORD;
function CM_DR( armor, level : dword) : single;
function CM_CombatFreeAndNil( comLID : dword) : byte;
function CM_CheckFreeNode( comLID: DWORD; mX, mY: word): boolean;
function CM_SetStartPos( comLID: DWORD; uTeam: byte) : TMPoint;
function CM_SetUnitDirection( sX, sY, fX, fY : DWORD) : DWORD;
function CM_CheckMelee(comLID, u1, u2: dword) : boolean;

function CM_CheckCol(x, y, x2, y2 : DWORD): boolean; inline;
function CM_AddAura(comLID, charLID, ID, stacks : DWord): byte;
function CM_DelAura(comLID, charLID, ID : DWord): byte;
function CM_FindAura(comLID, charLID, ID : DWord): byte;

procedure CM_Process();

procedure CM_SendUnits(comLID, charLID : word);
procedure CM_SendNewRound(comLID : word);
procedure CM_SendTurnStart(comLID, uLID : DWORD);

var
  zero_combat : TCombatEvent;

implementation

uses
  uPkgProcessor, uCharManager, vServerLog;

procedure CM_Process();
var i, j, k  : integer;
    hh, mm, ss, ms : word;
begin
for i := 0 to high(combats) do
  if combats[i].exist then
  begin
    k := 0;   // проверяем есть ли в битве ещё "живые" игроки, если нет, то закрываем.
    for j := 0 to high(combats[i].Units) do
      if combats[i].Units[j].exist then
         if combats[i].Units[j].uType = 1 then
            if chars[combats[i].Units[j].charLID].exist then inc(k) // если плеер - игрок, то тогда прибавляем счётчик
            else  // Если же игров офнулся, то ---- ???
            begin

            end;

    if k = 0 then
       begin
         combats[i].exist := false;
         combats[i] := zero_combat;
         WriteSafeText('Combat LID ## ' + IntToStr(i) + ' closed.');
       end;

// проверяем время хода...
    GetTime(hh, mm, ss, ms);
    if abs((60 * mm + ss) - (60 * combats[i].tsMin + combats[i].tsSec)) > 20 then
       begin
         combats[i].on_recount:=true;
// combats[i].AI.build_turn:=false;
// время вышло, передаём ход...
       end;
// перестройка АТБ-шкалы
    if combats[i].On_Recount then
       begin
         combats[i].NextTurn    := -1;
         combats[i].NextTurnATB := -1;
// сначала проверяем, может кто-то уже зашёл за финишную черту
         for j := 0 to high(combats[i].Units) do
           if combats[i].Units[j].exist then
           if combats[i].Units[j].alive then
           if combats[i].Units[j].ATB >= 1000 then // если пришли в конец шкалы
           if combats[i].Units[j].ATB > combats[i].NextTurnATB then
              begin
                combats[i].NextTurnATB := combats[i].Units[j].ATB;
                combats[i].NextTurn    := combats[i].Units[j].uLID;
              end;
// никого не нашли - делаем сдвиги
           if combats[i].NextTurn = -1 then
              begin
                inc(combats[i].ATBTime);           // делаем тик времени
                if (combats[i].ATBTime >= 10) then  // 10 тиков - 1 раунд
                   begin
// Начался новый раунд
// Проводим все необходимые манипуляции
                     combats[i].ATBTime:= 0;
                     inc(combats[i].ceRound);
                     CM_SendNewRound( i );   // начинаем следующий раунд
                     for j := 0 to high(combats[i].units) do
                       if combats[i].units[j].exist then
                       if combats[i].units[j].alive then
                       if combats[i].units[j].uType = 1 then
                          inc(combats[i].units[j].rounds_in);
                   end;
// Двигаем юнитов по АТБ шкале
                 for j := 0 to length(combats[i].units) - 1 do
                   if combats[i].units[j].exist then
                   if combats[i].units[j].exist then
                      begin
                        inc( combats[i].units[j].ATB, combats[i].units[j].Ini ); // делаем шаг вперёд
                        writeln(combats[i].Units[j].VData.name, ' ATB : ', combats[i].Units[j].ATB);
                        if combats[i].units[j].ATB >= 1000 then // если пришли в конец...
                        if combats[i].units[j].ATB > combats[i].NextTurnATB then
                           begin
                             combats[i].NextTurnATB := combats[i].units[j].ATB;
                             combats[i].NextTurn:= combats[i].units[j].uLID;
                           end;
                      end;
              end;
// если нашли кто ходит следущим - рассылаем сообщения, если нет - оставляем флаг
// чтобы на следующем цикле процессор снова сделал обработку АТБ шкалы
         if combats[i].NextTurn <> -1 then
            begin
              combats[i].tsMin:= mm;
              combats[i].tsSec:= ss;

              combats[i].on_recount := false;
              combats[i].uTurn := combats[i].NextTurn;
              for j := 0 to high(combats[i].Units) do
                if combats[i].Units[j].uLID = combats[i].NextTurn then
                   begin
                     Dec(combats[i].Units[j].ATB, 1000);
                     combats[i].Units[j].Data.cAP:=combats[i].Units[j].Data.mAP;
                     if combats[i].Units[j].ATB < 0 then combats[i].Units[j].ATB := 0;
                   end;
     //         CM_SendATB( i );                              //отправляем новую атб-шкалу
              CM_SendTurnStart( i, combats[i].NextTurn );   //отправляем новый ход
              WriteSafeText(' Combat #' + IntToStr(combats[i].ID) + ' next turn uUID =' + IntToStr( combats[i].NextTurn ) );
            end;
       end;
// Обрабатываем работу ИИ
    AI_Process( i );
  end;
end;

function CM_StartNew(initiator, ceType, ceUID : DWORD): word;
var i, j, r: integer;
begin
  result := high(word);
                     // создаём бой
  for i := 0 to high(combats) do
    if not combats[i].exist then
       begin
         inc(cm_total);
         combats[i].exist    := true;
         combats[i].ID       := cm_total;
         combats[i].comLID   := i;
         combats[i].ceUID    := ceUID;
         combats[i].ceType   := ceType;
         combats[i].ceRound  := 0;
         combats[i].ATBTime  := 0;
         combats[i].pLimit   := 1;

         combats[i].On_Recount := true;

         result := combats[i].ID;
         break;
       end;

  WriteSafeText('Combat ID ## ' + IntToStr(result) + ' prototype added.', 1);


  if ceType = 1 then  // добавляем мобов
     begin
       if not ceDB[ceUID].exist then exit;
       combats[i].pLimit:= ceDB[ceUID].limit;
       for j := 1 to 4 do
           if ceDB[ceUID].mobs[j] > 0 then CM_AddAIUnit(combats[i].ID, ceDB[ceUID].mobs[j], 2);

       for j := 1 to 3 do
           if ceDB[ceUID].ally[j] > 0 then CM_AddAIUnit(combats[i].ID, ceDB[ceUID].ally[j], 1);

     end else combats[i].pLimit := 2;

                     // добавляем юниты
  if result <> high(word) then
     begin
       r := CM_AddPUnit(result, initiator, 1);
       if r <> 1 then result := high(word);
     end;

  if result <> high(word) then
     WriteSafeText('Combat ID #' + IntToStr(combats[i].ID) + ' has been opened.', 1);
end;

function CM_AddPUnit(comID, charLID: DWORD; uTeam : byte) : byte;
var i, k   : integer;
    comLID : DWORD;
begin
  result := high(byte);
  comLID := CM_GetCombatLID( comID );

  if chars[charLID].in_combat then
     begin
       WriteSafeText('Already in combat! Abort.', 3);
       exit;
     end;
  if comLID = high(DWORD) then
    begin            // такого боя не существует. логгируем
      WriteSafeText(' Combat #' + intToStr(comID) + ' doesnt exist! CM_AddUnit charID = ' + IntToStr(charLID) + ' aborted.', 3);
      exit;
    end;
  if CM_GetPUnitsNum( comLID ) >= combats[comLID].pLimit then
    begin   // если нет пустой ячейки для игрока
      WriteSafeText('Not enough slots to enter combat LID ## ' + IntToStr(CM_GetPUnitsNum( comLID )) + ' / ' + IntToStr(combats[comLID].pLimit), 2);
      result := high(byte) - 1;     // код ошибки
      exit;
    end;

  k := -1;
  for i := 0 to high(combats[comLID].Units) do
    if not combats[comLID].Units[i].exist then
      begin
        combats[comLID].Units[i].exist   := true;
        combats[comLID].Units[i].uLID    := i;
        combats[comLID].Units[i].uType   := 1;
        combats[comLID].Units[i].uTeam   := uTeam;
        combats[comLID].Units[i].charLID := charLID;
        combats[comLID].Units[i].rounds_in:= 0;

        combats[comLID].Units[i].Data.pos:= CM_SetStartPos(comLID, uTeam);
        Writeln(combats[comLID].Units[i].Data.pos.x, ' - ', combats[comLID].Units[i].Data.pos.y);

        combats[comLID].Units[i].VData.name:=Chars[charLID].header.Name;
        if uTeam = 1 then combats[comLID].units[i].Data.Direct:=0 else combats[comLID].units[i].Data.Direct:= 4;

        combats[comLID].Units[i].VData.Race:=chars[charLID].header.raceID;
        combats[comLID].Units[i].VData.skinArm := 1;
        combats[comLID].Units[i].VData.skinMH  := 1;
        combats[comLID].Units[i].VData.skinOH  := 1;

         // приписываем юниту свойства
        combats[comLID].Units[i].Data.mHP := chars[charLID].hpmp.mHP;
        combats[comLID].Units[i].Data.cHP := chars[charLID].hpmp.cHP;
        combats[comLID].Units[i].Data.mMP := chars[charLID].hpmp.mMP;
        combats[comLID].Units[i].Data.cMP := chars[charLID].hpmp.cMP;
        combats[comLID].Units[i].Data.mAP := chars[charLID].hpmp.mAP;
        combats[comLID].Units[i].Data.cAP := chars[charLID].hpmp.mAP;

        combats[comLID].Units[i].Ini := chars[charLID].Stats.Ini;

        chars[charLID].in_combat := true;
        k := i;
        result := 1;
        writesafetext('Player Unit ## ' + IntToStr(charLID) + ' has been added in slot ' + IntToStr(i));
        break;
      end;
  if k = -1 then result := high(byte) - 2;
end;

function CM_AddAIUnit(comID, uID : DWORD; uTeam : byte) : byte;
var i, k : integer;
    comLID : DWORD;
begin
  comLID := CM_GetCombatLID( comID );

  if comLID = high(DWORD) then
    begin            // такого боя не существует. логгируем
      WriteSafeText(' Combat ID #' + intToStr(comID) + ' doesnt exist! CM_AddAIUnit uID = ' + IntToStr(uID) + ' aborted.', 3);
      exit;
    end;

   k := -1;
  for i := 0 to high(combats[comLID].Units) do
    if not combats[comLID].Units[i].exist then
      begin
        combats[comLID].Units[i].exist   := true;
        combats[comLID].Units[i].alive   := true;
        combats[comLID].Units[i].uLID    := i;
        combats[comLID].Units[i].uType   := 2;
        combats[comLID].Units[i].uTeam   := uTeam;
        combats[comLID].Units[i].uID     := uID;
        combats[comLID].Units[i].Data.pos:= CM_SetStartPos(comLID, uTeam);
        if uTeam = 1 then combats[comLID].units[i].Data.Direct:=0 else combats[comLID].units[i].Data.Direct:= 4;
        Writeln(combats[comLID].Units[i].Data.pos.x, ' - ', combats[comLID].Units[i].Data.pos.y);

        combats[comLID].Units[i].VData.name    := MobDataDB[uID].name;
        combats[comLID].Units[i].VData.Race    := MobDataDB[uID].race;
        combats[comLID].units[i].VData.skinMH  := MobDataDB[uID].skMH;
        combats[comLID].units[i].VData.skinArm := MobDataDB[uID].skBody;
        combats[comLID].units[i].VData.skinOH  := MobDataDB[uID].skOH;

          // приписываем юниту свойства
        combats[comLID].Units[i].Data.mHP := hpmp_counter(MobDataDB[uID].HP, MobDataDB[uID].Con);
        combats[comLID].Units[i].Data.cHP := hpmp_counter(MobDataDB[uID].HP, MobDataDB[uID].Con);
        combats[comLID].Units[i].Data.mMP := hpmp_counter(MobDataDB[uID].MP, MobDataDB[uID].Int);
        combats[comLID].Units[i].Data.cMP := hpmp_counter(MobDataDB[uID].MP, MobDataDB[uID].Int);
        combats[comLID].Units[i].Data.mAP := MobDataDB[uID].AP;
        combats[comLID].Units[i].Data.cAP := MobDataDB[uID].AP;

        combats[comLID].Units[i].Ini := MobDataDB[uID].Ini;

        k := i;
        writesafetext('AI Unit ## ' + IntToStr(uID) + ' has been added in slot ' + IntToStr(i));
        result := 1;
        break;
      end;
  if k = -1 then result := high(byte) - 2;
end;

// получаем количесто игроков, которые уже в бою
function CM_GetPUnitsNum( comLID : DWORD) : byte;
var i, k: integer;
begin
  k := 0; result := 0;
  for i:= 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].exist then
    if combats[comLID].units[i].uType = 1 then inc(k);
  result := k;
end;

// получаем номер ячейки в которой идёт комбат
function CM_GetCombatLID( comID : DWORD) : DWORD;
var i: integer;
begin
  result := high(DWORD); // нет такого комбата
  for i:= 0 to length(combats) - 1 do
    if combats[i].exist then
    if combats[i].ID = comID then
       begin
         result := i;
         exit;
       end;
end;

function CM_DR( armor, level : dword) : single;
begin
  result := 0;
  result := armor / (armor + 200 + level * 25 );
  if result > 0.75 then result := 0.75;
end;

function CM_CombatFreeAndNil( comLID : dword) : byte;
var i: integer;
begin
  combats[comLID].exist:= false;
  combats[comLID] := zero_combat;
end;

function CM_CheckFreeNode( comLID: DWORD; mX, mY: word): boolean;
var i: integer;
begin
  result:=true;
  for i:=0 to length(combats[comLID].units) - 1 do
  begin
    if combats[comLID].units[i].exist then
      if combats[comLID].units[i].Data.pos.x = mX then
        if combats[comLID].units[i].Data.pos.y = mY then
          begin
            result := false;   // выяснили, что клетка занята
            exit;
          end;
   // result := true; //если дошли до сюда, значит юнитов нет и можно входить
  end;
end;

function CM_SetStartPos( comLID: DWORD; uTeam: byte) : TMPoint;
var x, y : word; b: boolean;
begin
  x := 0; y:= 0;
  if not combats[comLID].exist then exit;
  case uTeam of
    1 : begin
          x:= 1;
          b:= false;
          while not b do
            begin
              y := 1 + random(18);
              b := CM_CheckFreeNode( comLID, x, y);
            end;
        end;
    2 : begin
          x := 19;
          b := false;
          while not b do
            begin
              y := 1 + random(18);
              b := CM_CheckFreeNode( comLID, x, y);
            end;
        end;
  end;
  result.x:=x;
  result.y:=y;
end;

function CM_SetUnitDirection( sX, sY, fX, fY : DWORD) : DWORD;
begin
  if fX > sX then
     begin
       if fY > sY then result := 6;
       if fY = sY then result := 7;
       if fY < sY then result := 0;
     end;

  if fX = sX then
     begin
       if fY > sY then result := 5;
       if fY < sY then result := 1;
     end;

  if fX < sX then
     begin
       if fY > sY then result := 4;
       if fY = sY then result := 3;
       if fY < sY then result := 2;
     end;
end;

function CM_CheckMelee(comLID, u1, u2: dword) : boolean;
var i: integer;
begin
  result := false;
  if not combats[comLID].exist then exit;
  if not combats[comLID].units[u1].exist then exit;
  if not combats[comLID].units[u2].exist then exit;
  if not combats[comLID].units[u1].alive then exit;
  if not combats[comLID].units[u2].alive then exit;
  if (abs(combats[comLID].units[u1].Data.pos.x - combats[comLID].units[u2].Data.pos.x) <= 1) and
     (abs(combats[comLID].units[u1].Data.pos.y - combats[comLID].units[u2].Data.pos.y) <= 1) then
     result := true;
end;

function CM_CheckCol(x, y, x2, y2 : DWORD): boolean; inline;
begin
  result := false;
  if abs(x - x2) <= 1 then
     if abs(y - y2) <= 1 then
        result := true;
end;

function CM_AddAura(comLID, charLID, ID, stacks : DWord): byte;
var i: integer;
begin
  result := high(byte);
  for i := 1 to high(combats[comLID].units[charLID].auras) do
      if combats[comLID].units[charLID].auras[i].exist then
         if combats[comLID].units[charLID].auras[i].id = ID then
            begin
              result := high(byte) - 1;
              exit;
            end;

  for i := 1 to high(combats[comLID].units[charLID].auras) do
      if not combats[comLID].units[charLID].auras[i].exist then
         begin
           result := i;
           combats[comLID].units[charLID].auras[i].exist := true;
           combats[comLID].units[charLID].auras[i].id := ID;
           combats[comLID].units[charLID].auras[i].sub := 1;
           combats[comLID].units[charLID].auras[i].left:= 1;
           if stacks > 0 then combats[comLID].units[charLID].auras[i]._st:=true;
           inc(combats[comLID].units[charLID].auras[i].stacks, stacks);
           if combats[comLID].units[charLID].auras[i]._st then
              if combats[comLID].units[charLID].auras[i].stacks < 1 then
                 combats[comLID].units[charLID].auras[i].exist:= false;
           break;
         end;

//  CM_SendAuras(comLID);
end;

function CM_DelAura(comLID, charLID, ID : DWord): byte;
var i: integer;
begin
  result := high(byte) ;
  for i := 1 to high(combats[comLID].units[charLID].auras) do
      if combats[comLID].units[charLID].auras[i].exist then
         if combats[comLID].units[charLID].auras[i].id = ID then
            begin
              combats[comLID].units[charLID].auras[i].exist := false;
              combats[comLID].units[charLID].auras[i]._st:=false;
              combats[comLID].units[charLID].auras[i].stacks:=0;
              WriteSafeText('Aura ' + IntToStr(combats[comLID].units[charLID].auras[i].id) + ' deleted.', 1);
              break;
            end;
 // CM_SendAuras(comLID);
end;

function CM_FindAura(comLID, charLID, ID : DWord): byte;
var i: integer;
begin
  result := high(byte) ;
  for i := 1 to high(combats[comLID].units[charLID].auras) do
      if combats[comLID].units[charLID].auras[i].exist then
         if combats[comLID].units[charLID].auras[i].id = ID then
            begin
              result := i;
              exit;
            end;
end;

procedure CM_SendUnits(comLID, charLID : word);
var _head  : TPackHeader; _pkg : TPkg101;
    mStr   : TMemoryStream;
    i      : integer;
begin
  for i := 0 to high(combats[comLID].Units) do
    if combats[comLID].Units[i].exist then
       begin
         _pkg.list[i].exist  := true;
         _pkg.list[i].Name   := combats[comLID].Units[i].VData.name;
         _pkg.list[i].uType  := combats[comLID].Units[i].uType;
         _pkg.list[i].uLID   := combats[comLID].Units[i].uLID;
         _pkg.list[i].uTeam  := combats[comLID].Units[i].uTeam;
       end else _pkg.list[i].exist := false;

   _head._flag := $f;
  _head._id   := 101;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет
 {   for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then  }
         begin
           TCP.FCon.IterReset;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;

procedure CM_SendNewRound(comLID : word);
var _head  : TPackHeader; _pkg : TPkg104;
    mStr   : TMemoryStream;
    i, charLID: word;
begin
  _head._flag := $f;
  _head._id   := 104;

  _pkg.ceRound := combats[comLID].ceRound;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет всем игрока в бою
    for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then
         begin
           TCP.FCon.IterReset;
           charLID := combats[comLID].Units[i].charLID;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;

procedure CM_SendNextTurn(comLID : word);
var _head  : TPackHeader; _pkg : TPkg104;
    mStr   : TMemoryStream;
    i, charLID: word;
begin
  _head._flag := $f;
  _head._id   := 104;

  _pkg.ceRound := combats[comLID].ceRound;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет всем игрока в бою
    for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then
         begin
           TCP.FCon.IterReset;
           charLID := combats[comLID].Units[i].charLID;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;

procedure CM_SendTurnStart( comLID, uLID : DWORD);
var _head  : TPackHeader; _pkg : TPkg105;
    mStr   : TMemoryStream;
    i, charLID: word;
begin
  _head._flag := $f;
  _head._id   := 105;

  _pkg.NextTurn := uLID;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет всем игрока в бою
    for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then
         begin
           TCP.FCon.IterReset;
           charLID := combats[comLID].Units[i].charLID;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;


end.


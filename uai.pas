unit uAI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, vVar, uCharManager;

procedure Map_CreateMask( comLID: DWORD );
function SearchWay( comLID: DWORD; StartX, StartY, FinishX, FinishY: Integer): Boolean;

function AI_AnyPlayerInMelee( comLID, aiUID : DWORD ) : byte;
function AI_AnyPlayerInRange( comLID, aiUID : DWORD ) : byte;
function AI_PlayerToHeal( comLID, aiUID : DWORD ) : byte;
function AI_FindTarget( comLID, aiUID : DWORD ) : byte;
function AI_MoveTo( comLID, aiUID, tLID: DWORD ) : byte;
function AI_MoveToMostSafe( comLID, aiUID, tLID: DWORD ) : byte;
function AI_TurnTo( comLID, aiUID, tLID: DWORD ) : byte;

function AI_PointInRange( x, y, _x, _y, r : Word) : boolean;

procedure AI_Process(comLID : DWORD);

implementation

uses uCombatProcessor, vServerLog, vNetCore, uAdd, uPkgProcessor;

procedure AI_Process(comLID : DWORD);
var j: integer;
    target : integer;
begin
  //writeln('AI_Process next turn: ', combats[comLID].NextTurn);

  for j := 0 to length(combats[comLID].units) - 1 do
  if combats[comLID].units[j].exist then
  if combats[comLID].units[j].alive then
  if combats[comLID].units[j].uType = 2 then
  begin
  if combats[comLID].units[j].uLID = combats[comLID].NextTurn then
     begin
       WriteSafeText('AI TURN: ' + IntToStr(combats[comLID].units[j].uLID ) + ', ' + IntToStr(j) + ', ' + combats[comLID].units[j].VData.name, 2);
       combats[comLID].NextTurn:= -1;
       combats[comLID].AI.build_turn:=true;   // устанавливаем флаг того, что нужно сделать ход
       combats[comLID].AI.delay:=0;
       combats[comLID].AI.sAP:= 0;
       combats[comLID].AI.locUID:=j;
       combats[comLID].AI.attempt:=0;
       combats[comLID].Units[j].Data.cAP := combats[comLID].Units[j].Data.mAP;
       dec(combats[comLID].units[j].ATB, 1000);   // сдвигаем в начало по атб шкале
       if combats[comLID].units[j].ATB < 0 then combats[comLID].units[j].ATB := 0;
     end;
  end;

  if combats[comLID].AI.build_turn then
     begin
       inc(combats[comLID].AI.delay);   // делаем небольшую задержку между действиями
       if combats[comLID].AI.delay > 300 then
       if combats[comLID].AI.attempt > 4 then // если уже 5 раз заходим сюда, значит АИ глючит
                                                  // поэтому передаём ход.
          begin
            combats[comLID].on_recount:=true;
            combats[comLID].AI.build_turn:=false;
          end else
          begin
            combats[comLID].AI.delay := 0;   // обнуляем дейлей, чтобы делать паузы между действиями
            inc(combats[comLID].AI.attempt); // увеличиваем счётчик попытоr
            Writeln(' ********* Attempt # ', combats[comLID].AI.attempt, ' *********** ');
          if combats[comLID].Units[combats[comLID].AI.locUID].Data.cAP < 5 then
          begin
            combats[comLID].on_recount:=true;
            combats[comLID].AI.build_turn:=false;
            // Если АП мало, то не "ломаем" комедию и сразу передаём ход
          end else
          begin
// БЛОК ПОИСКА ЦЕЛИ
// если милик - ищем мили цель, в противном случае ищем в рейндже
            case combats[comLID].units[combats[comLID].AI.locUID].aiFlag of
              0 : Target := AI_AnyPlayerInMelee( comLID, combats[comLID].AI.locUID);
              1 : Target := AI_AnyPlayerInRange( comLID, combats[comLID].AI.locUID);
              2 : begin
                    Target := AI_PlayerToHeal(comLID, combats[comLID].AI.locUID);
                    if target = high(byte) then Target := AI_AnyPlayerInRange( comLID, combats[comLID].AI.locUID);
              end;
            end;
// БЛОК ДЕЙСТВИЙ, ЕСЛИ НЕТ ЦЕЛИ В ЗОНЕ ПОРАЖЕНИЯ
// если не нашли цель для атаки, но есть АП то....
            if Target = high(byte) then        // если никого нет в мили, то идём
               begin
// если есть АП на ход
                 if (combats[comLID].units[combats[comLID].AI.locUID].Data.cAP >= 5) then
                    begin
// ищем к кому идти
                      target := AI_FindTarget(comLID, combats[comLID].AI.locUID );
                      AI_MoveTo( comLID, combats[comLID].AI.locUID, Target );
                    end else
                    begin
// а если их нет
                      combats[comLID].on_recount := true;
                      combats[comLID].AI.build_turn := false;
                    end;
               end else
// БЛОК ДЕЙСТВИЙ, ЕСЛИ ЕСТЬ ЦЕЛЬ В ЗОНЕ ПОРАЖЕНИЯ
               begin    // если таргет наш не в секторе
                 if not InSector( combats[comLID].units[combats[comLID].AI.locUID].Data.Direct,
                                  m_Angle(combats[comLID].units[combats[comLID].AI.locUID].Data.pos.x,
                                          combats[comLID].units[combats[comLID].AI.locUID].Data.pos.y,
                                          combats[comLID].units[target].Data.pos.x,
                                          combats[comLID].units[target].Data.pos.y) ) then
                    begin
                      AI_TurnTo( comLID, combats[comLID].AI.locUID, Target );  // то крутимся
                    end else
                    begin  // а если в секторе, то стараемся ударить
                           // если рейнж
                      if combats[comLID].units[combats[comLID].AI.locUID].aiFlag = 1 then
                         begin
                           // и есть ап
                           if combats[comLID].units[combats[comLID].AI.locUID].Data.cAP >= 25 then
                              CM_RangeAttack( comLID, combats[comLID].AI.locUID, target, 0 )
                           else
                           begin
                             // а если их нет
                             AI_MoveToMostSafe(comLID, combats[comLID].AI.locUID, Target);
                             combats[comLID].on_recount:=true;
                             combats[comLID].AI.build_turn:=false;
                           end;
                         end;

                      if combats[comLID].units[combats[comLID].AI.locUID].aiFlag = 0 then
                         begin  // если милик и есть ап
                           if combats[comLID].units[combats[comLID].AI.locUID].Data.cAP >= combats[comLID].units[combats[comLID].AI.locUID].aph then
                              CM_MeleeAttack( comLID, combats[comLID].AI.locUID, target, 0 )
                           else
                           begin
                             // а если их нет
                             combats[comLID].on_recount:=true;
                             combats[comLID].AI.build_turn:=false;
                           end;
                         end;

                      if combats[comLID].units[combats[comLID].AI.locUID].aiFlag = 2 then
                         begin  // если хилик
                                // и действуем по схеме хила, то
                           if combats[comLID].units[target].uTeam = combats[comLID].units[combats[comLID].AI.locUID].uTeam then
                              begin
                                if combats[comLID].units[combats[comLID].AI.locUID].Data.cAP >= 25 then
                                   begin
                                     if combats[comLID].units[combats[comLID].AI.locUID].Data.cMP < 37 then
                                        combats[comLID].units[combats[comLID].AI.locUID].aiFlag := 0;
                                     if AI_PointInRange( combats[comLID].units[combats[comLID].AI.locUID].Data.pos.x,
                                                         combats[comLID].units[combats[comLID].AI.locUID].Data.pos.y,
                                                         combats[comLID].units[target].Data.pos.x,
                                                         combats[comLID].units[target].Data.pos.y, 5) then
                                        CM_FriendlyCast( comLID, combats[comLID].AI.locUID, target, 5 )
                                     else
                                        AI_MoveTo( comLID, combats[comLID].AI.locUID, Target );
                                     end
                                     else begin
                                        // а если их нет
                                        AI_MoveTo( comLID, combats[comLID].AI.locUID, Target );
                                        combats[comLID].on_recount:=true;
                                        combats[comLID].AI.build_turn:=false;
                                      end;
                              end else // действуем по схеме дд
                              begin
                                // и есть ап
                                if combats[comLID].units[combats[comLID].AI.locUID].Data.cAP >= 25 then
                                   CM_RangeAttack( comLID, combats[comLID].AI.locUID, target, 1 )
                                else
                                begin
                                  // а если их нет
                                  AI_MoveToMostSafe(comLID, combats[comLID].AI.locUID, Target);
                                  combats[comLID].on_recount:=true;
                                  combats[comLID].AI.build_turn:=false;
                                end;
                              end;
                         end;
                    end;
               end;
          end;
end;
end;
end;

               // возвращает первого попавшегося игрока в мили радиусе
function AI_AnyPlayerInMelee( comLID, aiUID : DWORD ) : byte;
var i: integer; teamo : byte;
begin
  result := high(byte);
  teamo  := combats[comLID].units[aiUID].uTeam;
  for i := 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist then
    if i <> aiUID then
       combats[comLID].MapMatrix[combats[comLID].units[i].Data.pos.X, combats[comLID].units[i].Data.pos.Y].cType:= 1;

  for i:=0 to high(combats[comLID].units) do
      if combats[comLID].units[i].exist then
         if combats[comLID].units[i].alive and combats[comLID].units[i].visible then
           if i <> aiUID then
            if combats[comLID].units[i].uTeam <> teamo then
               if (abs(combats[comLID].units[aiUID].Data.pos.x - combats[comLID].units[i].Data.pos.x) <= 1) and
                  (abs(combats[comLID].units[aiUID].Data.pos.y - combats[comLID].units[i].Data.pos.y) <= 1) then
                begin
                  WriteSafeText( 'CheckPoint PLAYER IN MELEE ');
                  result := i;
                  break;
                end;
end;


               // возвращает первого попавшегося игрока в рейнж радиусе
function AI_AnyPlayerInRange( comLID, aiUID : DWORD ) : byte;
var i: integer; teamo : byte;
begin
  result := high(byte);
  teamo  := combats[comLID].units[aiUID].uTeam;
  WriteSafeText( combats[comLID].units[aiUID].VData.Name + ' LF any player in Range.' );
  for i:=0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist then
    if combats[comLID].units[i].alive and combats[comLID].units[i].visible then
    if i <> aiUID then
      if combats[comLID].units[i].uTeam <> teamo then
        if Distance( combats[comLID].units[aiUID].Data.pos.x,
                     combats[comLID].units[aiUID].Data.pos.y,
                     combats[comLID].units[i].Data.pos.x,
                     combats[comLID].units[i].Data.pos.y) <= combats[comLID].units[aiUID].sDist  then
             // если можем дойти до юнита...
                begin
     {             WriteSafeText( IntToStr( combats[comLID].units[aiUID].pos.x) );
                  WriteSafeText( IntToStr( combats[comLID].units[aiUID].pos.y) );
                  WriteSafeText( IntToStr( combats[comLID].units[i].pos.x) );
                  WriteSafeText( IntToStr( combats[comLID].units[i].pos.y) );      }
                  WriteSafeText( 'CheckPoint PLAYER IN RANGE ' + FloatToStr(Distance( combats[comLID].units[aiUID].Data.pos.x,
                     combats[comLID].units[aiUID].Data.pos.y,
                     combats[comLID].units[i].Data.pos.x,
                     combats[comLID].units[i].Data.pos.y)));
                  result := i;
                  break;
                end;
end;
  // возвращает юнита которого может похилить в этом ходу. Если в этом ходу не может
  // то тогда похилить в принципе. Если ни того, ни другого - не возвращает ничего
function AI_PlayerToHeal( comLID, aiUID : DWORD ) : byte;
var i : integer;
    steps, heal, hurt : word;
    sr1, sr2 : byte;
begin
  result := high(byte);
  hurt := 0; sr1 := 0; sr2 := 0;
 // heal := round( 0.75 * (combats[comLID].units[aiUID].Spi + combats[comLID].units[aiUID].spellpower + 17));
  WriteSafeText( combats[comLID].units[aiUID].VData.Name + ' LF player for Heal.' );
  for i:=0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist then
    if combats[comLID].units[i].alive and combats[comLID].units[i].visible then
    if combats[comLID].units[i].uTeam = combats[comLID].units[aiUID].uTeam then
    if (combats[comLID].units[i].Data.mHP - combats[comLID].units[i].Data.cHP) > heal then
    if (combats[comLID].units[i].Data.mHP - combats[comLID].units[i].Data.cHP) > hurt then
       begin
         hurt := combats[comLID].units[i].Data.mHP - combats[comLID].units[i].Data.cHP;
         sr1 := i;
       end;
  if sr1 <> 0 then result := sr1;
end;

function AI_FindTarget( comLID, aiUID : DWORD ) : byte;
var i: integer; teamo : byte;
    tarID : DWORD;
begin
  result := high(byte);
  teamo  := combats[comLID].units[aiUID].uTeam;
  Map_CreateMask( comLID );
  for i := 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist and combats[comLID].units[i].alive then
    if i <> aiUID then
       combats[comLID].MapMatrix[combats[comLID].units[i].Data.pos.X, combats[comLID].units[i].Data.pos.Y].cType:= 1;
//  Writeln('Debug 1 lid:', comLID, ' id:', combats[comLID].ID);

  for i := 0 to high(combats[comLID].units) do
    if combats[comLID].units[i].exist then
    if combats[comLID].units[i].alive and combats[comLID].units[i].visible then
    begin
    //  Writeln('debug 2 ', combats[comLID].Units[i].VData.name);
      if i <> aiUID then
      if combats[comLID].units[i].uTeam <> teamo then
        if SearchWay( comLID, combats[comLID].units[aiUID].Data.pos.x,
                              combats[comLID].units[aiUID].Data.pos.y,
                              combats[comLID].units[i].Data.pos.x,
                              combats[comLID].units[i].Data.pos.y) then
             // если можем дойти до юнита...
                begin
                  WriteSafeText( ' Way FOUND AI_FindTarget ');
                  result := i;
                  break;
                end;
    end;
end;

function AI_MoveTo( comLID, aiUID, tLID: DWORD ) : byte;
var i, j, n, rs: integer;
    charLID  : DWORD;
    X, Y, F, DIR, cAP, step_AP: word;
    _pkg : TPkg106; _head : TPackHeader;
    mStr : TMemoryStream;
begin
  result := high(byte);
  if combats[comLID].Units[aiUID].Data.cAP < 5 then Exit;
  if tLID = high(byte) then Exit;

  Map_CreateMask( comLID );
  for i := 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist and combats[comLID].units[i].alive then
    if i <> aiUID then
       combats[comLID].MapMatrix[combats[comLID].units[i].Data.pos.X, combats[comLID].units[i].Data.pos.Y].cType:= 1;


  if SearchWay(comLID, combats[comLID].units[aiUID].Data.pos.x,
                       combats[comLID].units[aiUID].Data.pos.y,
                       combats[comLID].units[tLID].Data.pos.x,
                       combats[comLID].units[tLID].Data.pos.y ) then
     begin
       if high(combats[comLID].Way) < 2 then exit;
    {   if combats[comLID].AI.sAP <> 0 then
          begin
            cAP := combats[comLID].AI.sAP;
            combats[comLID].AI.sAP := 0;
          end else }
       cAP := combats[comLID].units[aiUID].Data.cAP;
       WriteSafeText( ' AP : ' + IntToStr( cAP ) );

       step_AP := 5;
       if not combats[comLID].units[aiUID].visible then step_AP := 9;
       Writeln(length(combats[comLID].Way) - 2, ' vs ', cAP div Step_AP);
       if (length(combats[comLID].Way) - 2) > (cAP div Step_AP) then
          F := cAP div 5 // финишная точка
       else
          F := length(combats[comLID].Way) - 2;
       Writeln('F = ', f);
       if f = 0 then Exit;

       X := combats[comLID].Way[F].x;
       Y := combats[comLID].Way[F].y;

       Writeln('X :', X, ' Y :', Y);

       if x = combats[comLID].Units[aiUID].Data.pos.x then
       if y = combats[comLID].Units[aiUID].Data.pos.y then Exit; // никуда не ушли ?

       DIR := CM_SetUnitDirection(combats[comLID].Way[F - 1].x,
                                  combats[comLID].Way[F - 1].y,
                                  X, Y);

       dec(combats[comLID].units[aiUID].Data.cAP, F * Step_AP);


  {     // ломаем видимость
         for j := 0 to high(combats[comLID].Way) do
             for n := 0 to high(combats[comLID].units) do
                 if combats[comLID].units[n].exist and combats[comLID].units[n].alive then
                    if n <> aiUID then
                    if combats[comLID].units[aiUID].uTeam <> combats[comLID].units[n].uTeam then
                    begin
                     {  WriteSafeText('?x1: ' + IntToStr(combats[comLID].Way[j].x) +
                                     ' y1: ' + IntToStr(combats[comLID].Way[j].y) +
                                     ' x2: ' + IntToStr(combats[comLID].units[n].pos.x) +
                                     ' y2: ' + IntToStr(combats[comLID].units[n].pos.y));    }
                       if CM_CheckCol(combats[comLID].Way[j].x, combats[comLID].Way[j].y,
                                      combats[comLID].units[n].Data.pos.x, combats[comLID].units[n].Data.pos.y) then
                          begin
                            WriteSafeText('COLLISION CHECKED!');
                      {      if not combats[comLID].units[aiUID].visible then CM_TurnVisible(comLID, i);
                            if not combats[comLID].units[n].visible then CM_TurnVisible(comLID, n);  }
                          end;
                    end;
         }
        combats[comLID].Units[aiUID].Data.pos.x := x;
        combats[comLID].Units[aiUID].Data.pos.y := y;
        CM_AddAura(comLID, aiUID, 1, 0); // Keep moving
     end;
  // теперь рассылаем данные
         try
           writeln('Whooot&&&');
           mStr := TMemoryStream.Create;

           _head._flag := $f;
           _head._id   := 106;

           _pkg.X := X;
           _pkg.Y := Y;
           _pkg.comID   := Combats[comLID].ID;
           _pkg.uLID    := aiUID;
           _pkg.ap_left := combats[comLID].Units[aiUID].Data.cAP;

           mStr.Write(_head, sizeof(_head));
           mStr.Write(_pkg, sizeof(_pkg));

             // Отправляем пакет всем игрока в бою
      for i := 0 to high(combats[comLID].Units) do
        if combats[comLID].Units[i].exist then
        if combats[comLID].Units[i].uType = 1 then
           begin
           TCP.FCon.IterReset;
           charLID := combats[comLID].Units[i].charLID;
           TCP.FCon.IterReset;
           while TCP.FCon.IterNext do
             if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
             if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
                begin
                  writeln('Sending... ', TCP.FCon.Iterator.PeerAddress);
                  Writeln('Bytes sended... ', TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator));
                  Break;
                end;
           end;
         finally
           mStr.Free;
         end;
end;

function AI_MoveToMostSafe( comLID, aiUID, tLID: DWORD ) : byte;
var i, j, rs: integer;
    X, Y, F, DIR: word;
    cID : DWORD;
    dist, d: single;
    s, s2: string;
begin
  result := high(byte);

  Map_CreateMask( comLID );
  for i := 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist and combats[comLID].units[i].alive then
    if i <> aiUID then
       combats[comLID].MapMatrix[combats[comLID].units[i].Data.pos.X, combats[comLID].units[i].Data.pos.Y].cType:= 1;

  dist := 0;
  F := trunc(combats[comLID].units[aiUID].Data.cAP / 5);
  for i := 1 to 19 do
    for j := 1 to 19 do
      if AI_PointInRange(i, j, combats[comLID].units[aiUID].Data.pos.x, combats[comLID].units[aiUID].Data.pos.y, F) then
         begin
           d := Distance(i, j, combats[comLID].units[tLID].Data.pos.x, combats[comLID].units[tLID].Data.pos.y);
           if d > dist then
              begin
                x := i;
                y := j;
                dist := d;
              end;
         end;

  if SearchWay(comLID, combats[comLID].units[aiUID].Data.pos.x,
                       combats[comLID].units[aiUID].Data.pos.y,
                       x,
                       y ) then
     begin
       if high(combats[comLID].Way) < 2 then exit;
       WriteSafeText( ' AP : ' + IntToStr( combats[comLID].units[aiUID].Data.cAP ) );
       if F > high(combats[comLID].Way) then F := high(combats[comLID].Way);
       X := combats[comLID].Way[F].x;
       Y := combats[comLID].Way[F].y;
       DIR := CM_SetUnitDirection(combats[comLID].Way[F - 1].x,
                                  combats[comLID].Way[F - 1].y,
                                  X, Y);

       dec(combats[comLID].units[aiUID].Data.cAP, F * 5);

   //    CM_AddAura(comLID, aiUID, 1, 0); // Keep moving

    {   s := '2`' + IntToStr(combats[comLID].units[aiUID].charID) + '`' + IntToStr(X) + '`' + IntToStr(Y) + '`' + IntToStr(DIR) + '`';
       for i := 0 to length(combats[comLID].units) - 1 do
         if combats[comLID].units[i].exist then
           if combats[comLID].units[i].uType = 1 then
              begin
                cID := Char_GetCharCID( combats[comLID].units[i].charID );
                s2 := IntToStr(connections[cID].id) + '`034`' + s;
                WriteSafeText(' > ' + s2, 0);
                TCP.FCon.IterReset;
                while TCP.FCon.IterNext do
                  if (TCP.FCon.Iterator.PeerAddress = connections[cid].ip) and
                     (TCP.FCon.Iterator.LocalPort = connections[cid].lport) then
                rs := TCP.FCon.SendMessage(s2, TCP.FCon.Iterator);
                if rs < 0 then WriteSafeText(IntToStr(rs));
                if rs = 0 then Con_Clear(cid);
              end;
       combats[comLID].units[aiUID].pos.x:= X;
       combats[comLID].units[aiUID].pos.y:= Y;
       combats[comLID].units[aiUID].uDirect:= DIR;
       combats[comLID].AI.delay:=0;
       WriteSafeText(' Combat ID = ' + intToStr(combats[comLID].ID) );
       WriteSafeText( 'Moved to : ' + inttostr(x) + ',' + inttostr(y));   }
     end;
 // CM_SendUnitsCurData( comLID );
end;

function AI_TurnTo( comLID, aiUID, tLID: DWORD ) : byte;
var
    charLID : DWORD;
    i, DIR  : integer;
    angle   : single;
    _head   : TPackHeader;
    _pkg    : TPkg107;
    mStr    : TMemoryStream;
begin
  result := high(byte);

  WriteSafeText('Turn Debug Info:');
  WriteSafeText(combats[comLID].units[aiUID].VData.Name);
  WriteSafeText(combats[comLID].units[tLID].VData.Name);

  angle := m_Angle( combats[comLID].units[aiUID].Data.pos.x,
                    combats[comLID].units[aiUID].Data.pos.y,
                    combats[comLID].units[tLID].Data.pos.x,
                    combats[comLID].units[tLID].Data.pos.y );
  WriteSafeText( ' -- ! ---> Angle : ' + FloatToStr(angle) );
  DIR := round( (360 - angle) / 45 ) + 3;
  if DIR > 7 then DIR := DIR - 8;

  if combats[comLID].units[aiUID].Data.cAP < 5 then
     begin
       WriteSafeText(' Not enough AP for AI TURN TO !! ', 3);
       exit;
     end;

  if CM_FindAura(comLID, aiUID, 1) <> high(byte) then
     begin
       CM_DelAura(comLID, aiUID, 1);
     end else
       dec(combats[comLID].units[aiUID].Data.cAP, 5);

  combats[comLID].units[aiUID].Data.Direct:= DIR;
  result := dir;

try
  mStr := TMemoryStream.Create;

  _head._flag := $f;
  _head._id   := 107;

  _pkg.comID   := combats[comLID].ID;
  _pkg.uLID    := combats[comLID].Units[aiUID].uLID;
  _pkg.dir     := combats[comLID].Units[aiUID].Data.Direct;
  _pkg.ap_left := combats[comLID].Units[aiUID].Data.cAP;

  mStr.Write(_head, sizeof(_head));
  mStr.Write(_pkg, sizeof(_pkg));

           // Отправляем пакет всем игрока в бою
  for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then
         begin
         TCP.FCon.IterReset;
         charLID := combats[comLID].Units[i].charLID;
         TCP.FCon.IterReset;
         while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                break;
              end;
         end;
finally
  mStr.Free;
end;
end;


procedure Map_CreateMask( comLID: DWORD );
var i, j : integer;
begin
with Combats[comLID] do
  for I := 0 to 20 do
    for j := 0 to 20 do
      MapMatrix[i,j].cType:=0;

with Combats[comLID] do
for I := 0 to 20 do
    for j := 0 to 20 do
      if (i = 0) or (i = 20) then MapMatrix[i,j].cType:=1  // края карты
      else
        begin
          if (j = 0) or (j = 20) then MapMatrix[i,j].cType:=1; // края карты
        end;

end;


function SearchWay(comLID: DWORD; StartX, StartY, FinishX, FinishY: Integer): Boolean;
var
   Angle, X, Y, i, j, Step: Integer;
   Added: Boolean;
   Point: TMPoint;
begin
   WriteSafeText( IntToStr(StartX) + ', SY : ' +
                  IntToStr(StartY) + ', FX : ' +
                  IntToStr(FinishX) + ', FY : ' +
                  IntToStr(FinishY));
with Combats[comLID] do
begin
   SetLength(Way, 0); // Обнуляем массив с путем
   for i := 0 to High(MapMatrix) do
     for j := 0 to High(MapMatrix[i]) do
       MapMatrix[i][j].Step := -1; // Мы еще нигде не были
// До финиша ноль шагов - от него будем разбегаться
   MapMatrix[FinishX][FinishY].Step := 0;
   Step := 0; // Изначально мы сделали ноль шагов
   Added := True; // Для входа в цикл

   while Added And (MapMatrix[StartX][StartY].Step = -1) do
   begin
   // Пока вершины добаляются и мы не дошли до старта
     Added := False; // Пока что ничего не добавили
     Inc(Step); // Увеличиваем число шагов
     for i := 0 to High(MapMatrix) do
       for j := 0 to High(MapMatrix[i]) do // Пробегаем по всей карте
         if MapMatrix[i][j].Step = Step - 1 then
         begin
         // Если (i, j) была добавлена на предыдущем шаге
         // Пробегаем по всем четырем сторонам света
           for Angle := 0 to 3 do
           begin
             X := i + Round(Cos(Angle/2*pi)); // Вычисляем коор-
             Y := j + Round(Sin(Angle/2*pi)); // динаты соседа
           // Если вышли за пределы поля, (X, Y) не обрабатываем
             if (X < 0) Or (Y < 0) Or (X > High(MapMatrix)) Or (Y > High(MapMatrix[0])) then
               Continue;
           // Если (X, Y) уже добавлено или непроходимо, то не обрабатываем
             if (MapMatrix[X][Y].cType = 1) Or (MapMatrix[X][Y].Step <> -1) then
               Continue;
             MapMatrix[X][Y].Step := Step; // Добав-
             MapMatrix[X][Y].Parent.X := i; // ля-
             MapMatrix[X][Y].Parent.Y := j; // ем
             Added := True; // Что-то добавили
           end;
         end;
   end;

// Если до старта не дошли,
   if MapMatrix[StartX][StartY].Step = -1 then
   begin
     Result := False; // то пути не существует
     Exit;
   end;

   Point.X := StartX;
   Point.Y := StartY;

// Пока не дойдем до финиша
   while MapMatrix[Point.X][Point.Y].Step <> 0 do
   begin
     SetLength(Way, Length(Way) + 1);
     Way[High(Way)] := Point; // добавляем текущую вершину
     Point := MapMatrix[Point.X][Point.Y].Parent; // переходим к следующей
   end;

   SetLength(Way, Length(Way) + 1); // добавляем финиш
   Way[High(Way)].X := FinishX;
   Way[High(Way)].Y := FinishY;
   WriteSafeText( 'Way length = ' + inttostr(length(way)));
   Result := True;
end;
end;

function AI_PointInRange( x, y, _x, _y, r : Word) : boolean;
begin
  result := false;
  if abs(x - _x) + abs(y - _y) <= r then result := true;
end;

end.


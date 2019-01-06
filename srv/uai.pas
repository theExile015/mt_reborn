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

uses uCombatProcessor, vServerLog, vNetCore, uAdd;

procedure AI_Process(comLID : DWORD);
var j: integer;
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
       dec(combats[comLID].units[j].ATB, 1000);   // сдвигаем в начало по атб шкале
       if combats[comLID].units[j].ATB < 0 then combats[comLID].units[j].ATB := 0;
     end;
  end;

  if combats[comLID].AI.build_turn then
     begin
       inc(combats[comLID].AI.delay);   // делаем небольшую задержку между действиями
       if combats[comLID].AI.delay > 100 then
       if combats[comLID].AI.attempt > 4 then // если уже 5 раз заходим сюда, значит АИ глючит
                                                  // поэтому передаём ход.
          begin
            combats[comLID].on_recount:=true;
            combats[comLID].AI.build_turn:=false;
          end else
          begin
            inc(combats[comLID].AI.attempt); // увеличиваем счётчик попытоr
  // БЛОК ПОИСКА ЦЕЛИ
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

  for i:=0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist then
    if combats[comLID].units[i].alive  and combats[comLID].units[i].visible then
     if i <> aiUID then
      if combats[comLID].units[i].uTeam <> teamo then
        if SearchWay( comLID, combats[comLID].units[aiUID].Data.pos.x,
                              combats[comLID].units[aiUID].Data.pos.y,
                              combats[comLID].units[i].Data.pos.x,
                              combats[comLID].units[i].Data.pos.y) then
             // если можем дойти до юнита...
                begin
                  WriteSafeText( ' Way FOUND AI_FindTarget');
                  result := i;
                  break;
                end;
end;

function AI_MoveTo( comLID, aiUID, tLID: DWORD ) : byte;
var i, j, n, rs: integer;
    X, Y, F, DIR, cAP, step_AP: word;
    cID : DWORD;
    s, s2: string;
begin
  result := high(byte);

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
     {  if combats[comLID].AI.sAP <> 0 then
          begin
            cAP := combats[comLID].AI.sAP;
            combats[comLID].AI.sAP := 0;
          end else cAP := combats[comLID].units[aiUID].curAP;   }
       WriteSafeText( ' AP : ' + IntToStr( cAP ) );

       step_AP := 5;
       if not combats[comLID].units[aiUID].visible then step_AP := 9;

       if (length(combats[comLID].Way) - 2) > cAP div Step_AP then
          F := cAP div 5 // финишная точка
       else
          F := length(combats[comLID].Way) - 2;

       X := combats[comLID].Way[F].x;
       Y := combats[comLID].Way[F].y;
       DIR := CM_SetUnitDirection(combats[comLID].Way[F - 1].x,
                                  combats[comLID].Way[F - 1].y,
                                  X, Y);

       dec(combats[comLID].units[aiUID].Data.cAP, F * Step_AP);

       // ломаем видимость
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

   //    CM_AddAura(comLID, aiUID, 1, 0); // Keep moving

  {     s := '2`' + IntToStr(combats[comLID].units[aiUID].charID) + '`' + IntToStr(X) + '`' + IntToStr(Y) + '`' + IntToStr(DIR) + '`';
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
       WriteSafeText( 'Moved to : ' + inttostr(x) + ',' + inttostr(y));  }
     end;
  // CM_SendUnitsCurData( comLID );}
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
var i, j, rs: integer;
    DIR: integer;
    cID : DWORD;
    angle : single;
    s, s2: string;
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

  {if CM_FindAura(comLID, aiUID, 1) <> high(byte) then
     begin
       CM_DelAura(comLID, aiUID, 1);
     end else
       dec(combats[comLID].units[aiUID].curAP, 5);  }
  combats[comLID].units[aiUID].Data.Direct:= DIR;
  result := dir;

    {   s := IntToStr(combats[comLID].units[aiUID].uType) + '`' + IntToStr(combats[comLID].units[aiUID].charID) +  '`' + IntToStr(DIR) + '`';
       for i := 0 to length(combats[comLID].units) - 1 do
         if combats[comLID].units[i].exist then
           if combats[comLID].units[i].uType = 1 then
              begin
                cID := Char_GetCharCID( combats[comLID].units[i].charID );
                s2 := IntToStr(connections[cID].id) + '`039`' + s;
                WriteSafeText(' > ' + s2, 0);
                TCP.FCon.IterReset;
                while TCP.FCon.IterNext do
                  if (TCP.FCon.Iterator.PeerAddress = connections[cid].ip) and
                     (TCP.FCon.Iterator.LocalPort = connections[cid].lport) then
                rs := TCP.FCon.SendMessage(s2, TCP.FCon.Iterator);
                if rs < 0 then WriteSafeText(IntToStr(rs));
                if rs = 0 then Con_Clear(cid);
              end;
       combats[comLID].units[aiUID].uDirect:= DIR;
       combats[comLID].AI.delay:=0;
       WriteSafeText(' Combat ID = ' + intToStr(combats[comLID].ID) );
       WriteSafeText( 'DIR : ' + inttostr(DIR));  }

//  CM_SendUnitsCurData( comLID );
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
   WriteSafeText( IntToStr(StartX) + ', ' +
                  IntToStr(StartY) + ', ' +
                  IntToStr(FinishX) + ', ' +
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
   WriteSafeText( inttostr(length(way)));
   Result := True;
end;
end;

function AI_PointInRange( x, y, _x, _y, r : Word) : boolean;
begin
  result := false;
  if abs(x - _x) + abs(y - _y) <= r then result := true;
end;

end.


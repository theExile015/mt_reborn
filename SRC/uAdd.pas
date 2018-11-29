unit uAdd;

interface

uses uVar,
     Windows,
     zglHeader,
     md5,
    { jwatlhelp32,  }
     sysutils;

function _Mouse_X : single; inline;
function _Mouse_Y : single; inline;
function Line(x1, y1, x2, y2 : single): zglTLine; inline;
function Circle(x, y, r : single) : zglTCircle; inline;
function Rect(x, y, w, h: single) : zglTRect; inline;
function GetRaceName(rID : byte): utf8string;
function GetClassName(cID : byte): utf8string;
function GetClassNameS(cID : byte): utf8string;
function GetLocName(lID : word): utf8string;
function CheckSymbolsLP(const s: String): Boolean;
function CheckSymbolsN(const s: String): Boolean;
function md5(s: utf8string): utf8string;  inline;
//function GetSector( dir : byte ) : TSector;
function InSector( dir : byte; angle : single) : boolean;

procedure Clean_CharList();

function itt_GetProperty( pID, pV : longword ): UTF8String;
function itt_GetType( pID : longword ): UTF8String;

procedure Map_CreateMask;
function SearchWay(uLID: byte; StartX, StartY, FinishX, FinishY: Integer): Boolean;

function str_trans1(s: utf8string): utf8string;
function str_trans2(s: utf8string): utf8string;
{
procedure qlog_Save();
procedure qlog_Open();
function qlog_QAccepted(qID : longword): boolean;
function qlog_GetQLID(qID : longword): byte;

procedure SaveItemCache();
procedure ItemDataRequests();

function inv_FindFreeSpot() : word;
}
function sp_GetSchool(sID : word) : utf8string;
function sp_GetType(tID : word) : utf8string;


//function KillTask(ExeFileName: string): Integer;

implementation

uses
  uLocalization, uNetCore;

function _Mouse_X : single; inline;
begin
  result := Mouse_X() / ScaleXY + (zglCam1.X - (1920 - scr_w) / 2);
end;

function _Mouse_Y : single; inline;
begin
  result := Mouse_Y()  / ScaleXY + (zglCam1.Y - (1080 - scr_h) / 2);
end;

function md5(s: utf8string): utf8string; inline;
begin
  result := MD5Print(MD5String(s + 're:venture secret word'));
end;

procedure Clean_CharList();
var i: integer;
begin
  {for I := 0 to length(CharList) - 1 do
    begin
      CharList[i + 1].ID := 0;
      CharList[i + 1].Name := '';
      CharList[i + 1].raceID := 255;
      CharList[i + 1].classID := 255;
      CharList[i + 1].locID := high(word);
      Charlist[i + 1].level := 0;
    end; }
end;

function Line(x1, y1, x2, y2 : single): zglTLine; inline;
begin
  result.x0 := x1;
  result.y0 := y1;
  result.x1 := x2;
  result.y1 := y2;
end;

function Circle(x, y, r : single) : zglTCircle; inline;
begin
  result.cX := x;
  result.cY := y;
  result.Radius := r;
end;

function Rect(x, y, w, h: single) : zglTRect; inline;
begin
  result.X := x;
  result.Y := y;
  result.W := W;
  result.H := H;
end;

function GetRaceName(rID : byte): utf8string;
begin
  case rID of
    1 : result := (Race_Names[rID]);
    2 : result := (Race_Names[rID]);
    3 : result := (Race_Names[rID]);
    4 : result := (Race_Names[rID]);
    5 : result := (Race_Names[rID]);
  else
    result := '';
  end;
end;

function GetClassName(cID : byte): utf8string;
begin
  case cID of
    1 : result := AnsiToUTF8('Adventurer');
  else
    result := '';
  end;
end;

function GetClassNameS(cID : byte): utf8string;
begin
  case cID of
    1 : result := AnsiToUTF8('Adv');
  else
    result := '';
  end;
end;

function GetLocName(lID : word): utf8string;
begin
  case lID of
    0: result := AnsiToUTF8('Pure Spring');
    1: result := AnsiToUTF8('Pure Spring');
    2: result := AnsiToUTF8('Eastern Bridge');
    3: result := AnsiToUTF8('Robbers Camp');
  else
    result := '';
  end;
end;

function CheckSymbolsLP(const s: String): Boolean;
var i, len: Integer;   s_ : string;
begin
  len := Length(s);
  if len > 0 then begin
    Result := True;
    for i := 1 to len do
      if not (s[i] in ['a'..'z','A'..'Z','0'..'9']) then begin
        Result := False;
        break;
      end;
  end
  else
    Result := False;
end;

function CheckSymbolsN(const s: String): Boolean;
var i, len: Integer;   s_ : string;
begin
  len := Length(s);
  if len > 2 then begin
    Result := True;
    for i := 1 to len do
      if not (s[i] in ['a'..'z','A'..'Z']) then begin
        Result := False;
        break;
      end;
  end
  else
    Result := False;
end;

function InSector( dir : byte; angle : single) : boolean;
var aD : integer;
begin
  result := false;
  aD := round( (360 - angle) / 45 ) + 3;
  if aD > 7 then aD := aD - 8;
  if abs(dir - aD) <= 1 then result := true;
  if (dir = 0) and (aD = 7) then result := true;
  if (dir = 7) and (aD = 0) then result := true;
end;

function itt_GetProperty( pID, pV : longword ): UTF8String;
begin
  case pID of
    1 : result := 'Durability ' + u_IntToStr(pV) + '/' + u_IntToStr(pV);
    2 : result := u_IntToStr(pV) + ' - ';
    3 : result := 'Requires ' + u_IntToStr(pV) + ' level' ;
    4 : result := u_IntToStr(pV) + ' AP';
    5 : result := u_IntToStr(pV) + ' armor';
    6 : result := '+' + u_IntToStr(pV) + ' Strength';
    7 : result := '+' + u_IntToStr(pV) + ' Agility';
    8 : result := '+' + u_IntToStr(pV) + ' Constitution';
    9 : result := '+' + u_IntToStr(pV) + ' Haste';
    10: result := '+' + u_IntToStr(pV) + ' Intellect';
    11 : result := '+' + u_IntToStr(pV) + ' Spirit';
    12: result := 'Improves hit rating by ' + u_IntToStr(pV) + '.';
    13: result := 'Improves crit rating by ' + u_IntToStr(pV) + '.';
    14: result := 'Improves spell power by ' + u_IntToStr(pV) + '.';
    15: result := 'Improves initiative by ' + u_IntToStr(pV) + '.';
    16: result := 'Increase action points by ' + u_IntToStr(pV) + '.';
    17: result := 'Improves spell hit rating by ' + u_IntToStr(pV) + '.';
    18: result := 'Improves spell crit rating by ' + u_IntToStr(pV) + '.';
    19: result := 'Improves dodge rating by ' + u_IntToStr(pV) + '.';
    20: result := 'Improves block rating by ' + u_IntToStr(pV) + '.';
    21: result := 'Improves HP regeneration by ' + u_IntToStr(pV) + '.';
    22: result := 'Improves MP regeneration by ' + u_IntToStr(pV) + '.';
    // 22 - тип прока 23 величина прока
    // 24 - тип стата 25 требования стата
  else
    result := 'Unknown property';
  end;
  //Log_Add(result);
end;

function itt_GetType( pID : longword ): UTF8String;
begin
  case pID of
    1: result := 'Two-Hand mace';
    2: result := 'Two-Hand sword';
    3: result := 'Two-Hand axe';
    4: result := 'Staff';
    5: result := 'Bow';
    6: result := 'Crossbow';
    7: result := 'One-hand mace';
    8: result := 'One-hand sword';
    9: result := 'One-hand axe';
    10: result := 'Dagger';
    11: result := 'Helm';
    13: result := 'Cloak';
    12: result := 'Amulet';
    14: result := 'Shield';
    15: result := 'Chest';
    16: result := 'Legs';
    17: result := 'Gloves';
    18: result := 'Boots';
    19: result := 'Belt';
    20: result := 'Ring';
    21: result := 'Polearm';
    22: result := 'Meals';
    23: result := 'Potions';
    24: result := 'Misc.';
    35: result := 'Quest Item';
    52: result := 'Reagent';
  else
    result := 'Unknown';
  end;
end;


procedure Map_CreateMask;
var i, j : integer;
begin

  for I := 0 to 20 do
    for j := 0 to 20 do
      MapMatrix[i,j].cType:=0 ; // заполняем карту

  for I := 0 to 20 do
    for j := 0 to 20 do
      if (i = 0) or (i = 20) then MapMatrix[i,j].cType:=1  // края карты
      else
        begin
          if (j = 0) or (j = 20) then MapMatrix[i,j].cType:=1; // края карты
        end;
end;



function SearchWay(uLID: byte; StartX, StartY, FinishX, FinishY: Integer): Boolean;
var
   Angle, X, Y, i, j, Step: Integer;
   Added: Boolean;
   Point: TMPoint;
begin
   {
   SetLength(units[uLID].Way, 0); // Обнуляем массив с путем
   }
   for i := 0 to High(MapMatrix) do
     for j := 0 to High(MapMatrix[i]) do
       MapMatrix[i][j].Step := -1;

   // Мы еще нигде не были
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
   {
// Пока не дойдем до финиша
   while MapMatrix[Point.X][Point.Y].Step <> 0 do
   begin
     SetLength(units[uLID].Way, Length(units[uLID].Way) + 1);
     units[uLID].Way[High(units[uLID].Way)] := Point; // добавляем текущую вершину
     Point := MapMatrix[Point.X][Point.Y].Parent; // переходим к следующей
   end;

   SetLength(units[uLID].Way, Length(units[uLID].Way) + 1); // добавляем финиш
   units[uLID].Way[High(units[uLID].Way)].X := FinishX;
   units[uLID].Way[High(units[uLID].Way)].Y := FinishY;
   }
   Result := True;
end;
{
function KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOLEAN;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;
}

function str_trans1(s: utf8string): utf8string;
var i, k: integer;
    c : utf8string;
begin
  k := utf8_length(s);
  i := 1;
  result := '';
  while i <= k do
    begin
      c := utf8_copy(s, i, 2);
      if c = #13#10 then
         begin
           result := result + '~';
           inc(i, 2);
         end else
         begin
           result := result + utf8_copy(s, i, 1);
           inc(i, 1);
         end;
    end;
end;

function str_trans2(s: utf8string): utf8string;
var i, k: integer;
    c : utf8string;
begin
  k := utf8_length(s);
  i := 1;
  result := '';
  while i <= k do
    begin
      c := utf8_copy(s, i, 1);
      if c = '~' then result := result + #13#10 else result := result + c;
      inc(i);
    end;
end;
{
procedure qlog_Save();
var i: integer;
begin
  for i := 1 to high(quest_log) do
  if quest_log[i].exist then
    begin
      ini_add( u_IntToStr(i), 'ID');
      ini_add( u_IntToStr(i), 'qp');
      ini_add( u_IntToStr(i), 'N');
      ini_add( u_IntToStr(i), 'D');
      ini_add( u_IntToStr(i), 'O');
      ini_add( u_IntToStr(i), 'R');

      ini_WriteKeyInt( u_IntToStr(i), 'ID', quest_log[i].qID );
      ini_WriteKeyStr( u_IntToStr(i), 'qp', quest_log[i].qpID);
      ini_WriteKeyStr( u_IntToStr(i), 'N', quest_log[i].Name);
      ini_WriteKeyStr( u_IntToStr(i), 'D', str_trans1(quest_log[i].Descr));
      ini_WriteKeyStr( u_IntToStr(i), 'O', str_trans1(quest_log[i].Obj));
      ini_WriteKeyStr( u_IntToStr(i), 'R', quest_log[i].Reward);
    end;
  ini_savetofile('Cache\' + activechar.Name + '_qlog.ch');
  ini_free();
end;

procedure qlog_Open();
var i: integer;
begin
  if not File_Exists('Cache\' + activechar.Name + '_qlog.ch') then Exit;

  for i := 1 to high(mWins[9].dlgs) do
      mWins[9].dlgs[i].exist:=false;

  ini_loadFromFile('Cache\' + activechar.Name + '_qlog.ch');
  for i:= 1 to high(quest_log) do
    if ini_IsSection(u_IntToStr(i)) then
       begin
         quest_log[i].exist:=true;
         quest_log[i].qID:=ini_ReadKeyInt(u_IntToStr(i), 'ID');
         quest_log[i].qpID:=ini_ReadKeyStr(u_IntToStr(i), 'qp');
         quest_log[i].Name:=ini_ReadKeyStr(u_IntToStr(i), 'N');
         quest_log[i].Descr:=str_trans2(ini_ReadKeyStr(u_IntToStr(i), 'D'));
         quest_log[i].Obj:=str_trans2(ini_ReadKeyStr(u_IntToStr(i), 'O'));
         quest_log[i].Reward:=ini_ReadKeyStr(u_IntToStr(i), 'R');

         mWins[9].dlgs[i].exist:=true;
         mWins[9].dlgs[i].dID:=quest_log[i].qID;
         mWins[9].dlgs[i].dType:= 16;
         mWins[9].dlgs[i].text := quest_log[i].Name;
         mWins[9].dlgs[i].dy := 30 + i * 20;
       end;
  ini_free();
end;

function qlog_QAccepted(qID : longword): boolean;
var i: integer;
begin
  result := false;
  for i := 1 to high(quest_log) do
    if quest_log[i].qID = qID then
       begin
         result := true;
         exit;
       end;
end;

function qlog_GetQLID(qID : longword): byte;
var i: integer;
begin
  result := -1;
  for i:=1 to high(quest_log) do
    if quest_log[i].exist then
       if quest_log[i].qID = qID then
          begin
            result := i;
            exit;
          end;
end;

procedure ItemDataRequests();
var i: integer;
begin
  //k := 0;
  if inv_request <> -1 then exit;
  for i := 1 to high(mWins[5].dnds) do
    if mWins[5].dnds[i].exist then
      if mWins[5].dnds[i].contains > 0 then
        if (items[mWins[5].dnds[i].contains].ID = 0) or (items[mWins[5].dnds[i].contains].vCheck = false) then
           begin
             SendData(inline_pkgCompile(6, u_IntToStr(mWins[5].dnds[i].contains) + '`'));
             items[mWins[5].dnds[i].contains].req:=true;
             inv_request := mWins[5].dnds[i].contains;
             exit;
           end;
end;

procedure SaveItemCache();
  var i, j: integer;
begin
if iga <> igaLoc then exit;
ini_LoadFromFile('cache\items.ch');
try
  for i:= 1 to high(items) do
    if items[i].exist then
      if (items[i].ID > 0) and (items[i].ID < 1001) then
          begin
            if not ini_isSection(u_IntToStr(i)) then
               begin
                 ini_add(u_IntToStr(i), 'Ver');
                 ini_add(u_IntToStr(i), 'Upd');
                 ini_add(u_IntToStr(i), 'Name');
                 ini_add(u_IntToStr(i), 'rare');
                 ini_add(u_IntToStr(i), 'type');
                 ini_add(u_IntToStr(i), 'sub');
                 ini_add(u_IntToStr(i), 'iList');
                 ini_add(u_IntToStr(i), 'iID');
                 ini_add(u_IntToStr(i), 'price');
                 for j := 1 to 25 do
                     ini_add(u_IntToStr(i), 'p' + u_IntToStr(j));
               end;

               ini_WriteKeyStr( u_IntToStr(i), 'Ver',  MT_VER );
               ini_WriteKeyStr( u_IntToStr(i), 'Name', items[i].name );
               ini_WriteKeyInt( u_IntToStr(i), 'rare', items[i].rare );
               ini_WriteKeyInt( u_IntToStr(i), 'type', items[i].iType );
               ini_WriteKeyInt( u_IntToStr(i), 'sub',  items[i].sub);
               ini_WriteKeyInt( u_IntToStr(i), 'iList',items[i].iList );
               ini_WriteKeyInt( u_IntToStr(i), 'iID',  items[i].iID );
               ini_WriteKeyInt( u_IntToStr(i), 'price',  items[i].price );
               for j:= 1 to 25 do
                   ini_WriteKeyInt( u_IntToStr(i), 'p' + u_IntToStr(j), items[i].props[j].pNum);
          end
finally
  ini_savetofile('cache\items.ch');
  ini_free();
end;
end;

function inv_FindFreeSpot() : word;
var i : integer;
begin
  result := high(word);
  for i := 22 to 38 do
    if mWins[5].dnds[i].contains = 0 then
       begin
         result := i;
         break;
       end;
end;
}
function sp_GetSchool(sID : word) : utf8string;
begin
  case sID of
    1: result := 'Combat Arts';
    2: result := 'Defensive Arts';
    3: result := 'Restoration Arts';
    4: result := 'Elemental Arts';
    5: result := 'Spriritual Arts';
    6: result := 'Survival Arts';
    7: result := 'Subtlety Arts';
  else
    result := 'No school';
  end;
end;

function sp_GetType(tID : word) : utf8string;
begin
  case tID of
    0: result := 'Common';
    1: result := 'Single, Material';
    2: result := 'Single, Melee';
    3: result := 'Single, Range';
  else
    result := 'Unknown';
  end;
end;

end.

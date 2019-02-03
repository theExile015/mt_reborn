unit uAdd;

interface

{$codepage utf8}

uses uVar,
  Windows,
  zglHeader,
  md5,
  { jwatlhelp32,  }
  SysUtils;

function _Mouse_X: single; inline;
function _Mouse_Y: single; inline;
function Line(x1, y1, x2, y2: single): zglTLine; inline;
function Circle(x, y, r: single): zglTCircle; inline;
function Rect(x, y, w, h: single): zglTRect; inline;
function GetRaceName(rID: byte): utf8string;
function GetClassName(cID: byte): utf8string;
function GetClassNameS(cID: byte): utf8string;
function GetLocName(lID: word): utf8string;
function CheckSymbolsLP(const s: string): boolean;
function CheckSymbolsN(const s: string): boolean;
function md5(s: utf8string): utf8string; inline;
//function GetSector( dir : byte ) : TSector;
function InSector(dir: byte; angle: single): boolean;

procedure Clean_CharList();

function itt_GetProperty(pID, pV: longword): UTF8String;
function itt_GetType(pID: longword): UTF8String;

procedure Map_CreateMask;
function SearchWay(uLID: byte; StartX, StartY, FinishX, FinishY: integer): boolean;

function str_trans1(s: utf8string): utf8string;
function str_trans2(s: utf8string): utf8string;
{
procedure qlog_Save();
procedure qlog_Open();
function qlog_QAccepted(qID : longword): boolean;
function qlog_GetQLID(qID : longword): byte;
    }
procedure SaveItemCache();
procedure SaveLocCache();
procedure SaveObjCache();
{procedure ItemDataRequests();
}
function inv_FindFreeSpot(): word;

function sp_GetSchool(sID: word): utf8string;
function sp_GetType(tID: word): utf8string;

procedure Rebuild_Atb(var ATB_Data : TATB_Data);

//function KillTask(ExeFileName: string): Integer;

implementation

uses
  uLocalization;

function _Mouse_X: single; inline;
begin
  Result := Mouse_X() / ScaleXY + (zglCam1.X - (1920 - scr_w) / 2);
end;

function _Mouse_Y: single; inline;
begin
  Result := Mouse_Y() / ScaleXY + (zglCam1.Y - (1080 - scr_h) / 2);
end;

function md5(s: utf8string): utf8string; inline;
begin
  Result := MD5Print(MD5String(s + 're:venture secret word'));
end;

procedure Clean_CharList();
var
  i: integer;
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

function Line(x1, y1, x2, y2: single): zglTLine; inline;
begin
  Result.x0 := x1;
  Result.y0 := y1;
  Result.x1 := x2;
  Result.y1 := y2;
end;

function Circle(x, y, r: single): zglTCircle; inline;
begin
  Result.cX := x;
  Result.cY := y;
  Result.Radius := r;
end;

function Rect(x, y, w, h: single): zglTRect; inline;
begin
  Result.X := x;
  Result.Y := y;
  Result.W := W;
  Result.H := H;
end;

function GetRaceName(rID: byte): utf8string;
begin
  case rID of
    1: Result := (Race_Names[rID]);
    2: Result := (Race_Names[rID]);
    3: Result := (Race_Names[rID]);
    4: Result := (Race_Names[rID]);
    5: Result := (Race_Names[rID]);
    else
      Result := '';
  end;
end;

function GetClassName(cID: byte): utf8string;
begin
  case cID of
    1: Result := AnsiToUTF8('Adventurer');
    else
      Result := '';
  end;
end;

function GetClassNameS(cID: byte): utf8string;
begin
  case cID of
    1: Result := AnsiToUTF8('Adv');
    else
      Result := '';
  end;
end;

function GetLocName(lID: word): utf8string;
begin
  case lID of
    0: Result := AnsiToUTF8('Pure Spring');
    1: Result := AnsiToUTF8('Pure Spring');
    2: Result := AnsiToUTF8('Eastern Bridge');
    3: Result := AnsiToUTF8('Robbers Camp');
    else
      Result := '';
  end;
end;

function CheckSymbolsLP(const s: string): boolean;
var
  i, len: integer;
  s_: string;
begin
  len := Length(s);
  if len > 0 then
  begin
    Result := True;
    for i := 1 to len do
      if not (s[i] in ['a'..'z', 'A'..'Z', '0'..'9']) then
      begin
        Result := False;
        break;
      end;
  end
  else
    Result := False;
end;

function CheckSymbolsN(const s: string): boolean;
var
  i, len: integer;
  s_: string;
begin
  len := Length(s);
  if len > 2 then
  begin
    Result := True;
    for i := 1 to len do
      if not (s[i] in ['a'..'z', 'A'..'Z']) then
      begin
        Result := False;
        break;
      end;
  end
  else
    Result := False;
end;

function InSector(dir: byte; angle: single): boolean;
var
  aD: integer;
begin
  Result := False;
  aD := round((360 - angle) / 45) + 3;
  if aD > 7 then
    aD := aD - 8;
  if abs(dir - aD) <= 1 then
    Result := True;
  if (dir = 0) and (aD = 7) then
    Result := True;
  if (dir = 7) and (aD = 0) then
    Result := True;
end;

function itt_GetProperty(pID, pV: longword): UTF8String;
begin
  case pID of
    1: Result := 'Durability ' + u_IntToStr(pV) + '/' + u_IntToStr(pV);
    2: Result := u_IntToStr(pV) + ' - ';
    3: Result := 'Requires ' + u_IntToStr(pV) + ' level';
    4: Result := u_IntToStr(pV) + ' AP';
    5: Result := u_IntToStr(pV) + ' armor';
    6: Result := '+' + u_IntToStr(pV) + ' Strength';
    7: Result := '+' + u_IntToStr(pV) + ' Agility';
    8: Result := '+' + u_IntToStr(pV) + ' Constitution';
    9: Result := '+' + u_IntToStr(pV) + ' Haste';
    10: Result := '+' + u_IntToStr(pV) + ' Intellect';
    11: Result := '+' + u_IntToStr(pV) + ' Spirit';
    //12: result := 'Improves hit rating by ' + u_IntToStr(pV) + '.';
    12: Result := 'Improves crit rating by ' + u_IntToStr(pV) + '.';
    13: Result := 'Improves spell power by ' + u_IntToStr(pV) + '.';
    14: Result := 'Improves initiative by ' + u_IntToStr(pV) + '.';
    15: Result := 'Increase action points by ' + u_IntToStr(pV) + '.';
    16: Result := 'Improves dodge rating by ' + u_IntToStr(pV) + '.';
    17: Result := 'Improves block rating by ' + u_IntToStr(pV) + '.';
    //19: result := 'Improves HP regeneration by ' + u_IntToStr(pV) + '.';
    18: Result := 'Improves MP regeneration by ' + u_IntToStr(pV) + '.';
      // 22 - тип прока 23 величина прока
      // 24 - тип стата 25 требования стата
    else
      Result := 'Unknown property';
  end;
  //Log_Add(result);
end;

function itt_GetType(pID: longword): UTF8String;
begin
  case pID of
    1: Result := 'Two-Hand mace';
    2: Result := 'Two-Hand sword';
    3: Result := 'Two-Hand axe';
    4: Result := 'Staff';
    5: Result := 'Bow';
    6: Result := 'Crossbow';
    7: Result := 'One-hand mace';
    8: Result := 'One-hand sword';
    9: Result := 'One-hand axe';
    10: Result := 'Dagger';
    11: Result := 'Helm';
    13: Result := 'Cloak';
    12: Result := 'Amulet';
    14: Result := 'Shield';
    15: Result := 'Chest';
    16: Result := 'Legs';
    17: Result := 'Gloves';
    18: Result := 'Boots';
    19: Result := 'Belt';
    20: Result := 'Ring';
    21: Result := 'Polearm';
    22: Result := 'Meals';
    23: Result := 'Potions';
    24: Result := 'Misc.';
    35: Result := 'Quest Item';
    52: Result := 'Reagent';
    else
      Result := 'Unknown';
  end;
end;


procedure Map_CreateMask;
var
  i, j: integer;
begin
  for I := 0 to 20 do
    for j := 0 to 20 do
      MapMatrix[i, j].cType := 0; // заполняем карту

  for I := 0 to 20 do
    for j := 0 to 20 do
      if (i = 0) or (i = 20) then
        MapMatrix[i, j].cType := 1  // края карты
      else
      begin
        if (j = 0) or (j = 20) then
          MapMatrix[i, j].cType := 1; // края карты
      end;
end;



function SearchWay(uLID: byte; StartX, StartY, FinishX, FinishY: integer): boolean;
var
  Angle, X, Y, i, j, Step: integer;
  Added: boolean;
  Point: TMPoint;
begin
  SetLength(units[uLID].Way, 0); // Обнуляем массив с путем

  for i := 0 to High(MapMatrix) do
    for j := 0 to High(MapMatrix[i]) do
      MapMatrix[i][j].Step := -1;

  // Мы еще нигде не были
  // До финиша ноль шагов - от него будем разбегаться
  MapMatrix[FinishX][FinishY].Step := 0;
  Step := 0; // Изначально мы сделали ноль шагов
  Added := True; // Для входа в цикл

  while Added and (MapMatrix[StartX][StartY].Step = -1) do
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
            X := i + Round(Cos(Angle / 2 * pi)); // Вычисляем коор-
            Y := j + Round(Sin(Angle / 2 * pi)); // динаты соседа
            // Если вышли за пределы поля, (X, Y) не обрабатываем
            if (X < 0) or (Y < 0) or (X > High(MapMatrix)) or
              (Y > High(MapMatrix[0])) then
              Continue;
            // Если (X, Y) уже добавлено или непроходимо, то не обрабатываем
            if (MapMatrix[X][Y].cType = 1) or (MapMatrix[X][Y].Step <> -1) then
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
     SetLength(units[uLID].Way, Length(units[uLID].Way) + 1);
     units[uLID].Way[High(units[uLID].Way)] := Point; // добавляем текущую вершину
     Point := MapMatrix[Point.X][Point.Y].Parent; // переходим к следующей
   end;

   SetLength(units[uLID].Way, Length(units[uLID].Way) + 1); // добавляем финиш
   units[uLID].Way[High(units[uLID].Way)].X := FinishX;
   units[uLID].Way[High(units[uLID].Way)].Y := FinishY;

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

procedure SaveItemCache();
var
  Cache: zglTFile;
  Data: TItemData;
  i: integer;
begin
  if File_Exists('Cache\items.rec') then
  begin
    File_Open(Cache, 'Cache\items.rec', FOM_OPENRW);
    File_Flush(cache);
    for i := 1 to high(items) do
      if items[i].exist then
        file_Write(cache, items[i].Data, sizeof(Data));
  end;
  File_Close(Cache);
end;

procedure SaveLocCache();
var
  Cache: zglTFile;
  Data: TLocData;
  i: integer;
begin
  if File_Exists('Cache\locs.rec') then
  begin
    File_Open(Cache, 'Cache\locs.rec', FOM_OPENRW);
    File_Flush(cache);
    for i := 1 to high(locs) do
      if locs[i].exist then
        file_Write(cache, locs[i].Data, sizeof(Data));
  end;
  File_Close(Cache);
end;

procedure SaveObjCache();
var
  Cache: zglTFile;
  Data : TLocObjData;
  i    : integer;
begin
  if File_Exists('Cache\objs.rec') then
  begin
    File_Open(Cache, 'Cache\objs.rec', FOM_OPENRW);
    File_Flush(cache);
    for i := 1 to high(objstore) do
      if objstore[i].exist then
         file_Write(cache, objstore[i].Data, sizeof(Data));
  end;
  File_Close(Cache);
end;

function str_trans1(s: utf8string): utf8string;
var
  i, k: integer;
  c: utf8string;
begin
  k := utf8_length(s);
  i := 1;
  Result := '';
  while i <= k do
  begin
    c := utf8_copy(s, i, 2);
    if c = #13#10 then
    begin
      Result := Result + '~';
      Inc(i, 2);
    end
    else
    begin
      Result := Result + utf8_copy(s, i, 1);
      Inc(i, 1);
    end;
  end;
end;

function str_trans2(s: utf8string): utf8string;
var
  i, k: integer;
  c: utf8string;
begin
  k := utf8_length(s);
  i := 1;
  Result := '';
  while i <= k do
  begin
    c := utf8_copy(s, i, 1);
    if c = '~' then
      Result := Result + #13#10
    else
      Result := Result + c;
    Inc(i);
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
}
function inv_FindFreeSpot(): word;
var
  i: integer;
begin
  Result := high(word);
  for i := 22 to 38 do
    if mWins[5].dnds[i].Data.contain = 0 then
    begin
      Result := i;
      break;
    end;
end;

function sp_GetSchool(sID: word): utf8string;
begin
  case sID of
    1: Result := 'Combat Arts';
    2: Result := 'Defensive Arts';
    3: Result := 'Restoration Arts';
    4: Result := 'Elemental Arts';
    5: Result := 'Spriritual Arts';
    6: Result := 'Survival Arts';
    7: Result := 'Subtlety Arts';
    else
      Result := 'No school';
  end;
end;

function sp_GetType(tID: word): utf8string;
begin
  case tID of
    0: Result := 'Common';
    1: Result := 'Single, Material';
    2: Result := 'Single, Melee';
    3: Result := 'Single, Range';
    else
      Result := 'Unknown';
  end;
end;

procedure Rebuild_Atb(var ATB_Data : TATB_Data);
var i, j : integer;
    tmp : TATBItem;
begin
{  // сначала переносим лидера в жопу
  if ATB_Data[20].atb >= 1000 then
     begin
       dec(atb_data[20].atb, 1000);  }
       // сортируем
       for i := 0 to 19 do
       for j := 0 to 19 - i do
            if ATB_Data[j].atb > ATB_Data[j+1].atb then
            begin
                tmp           := ATB_Data[j];
                ATB_Data[j  ] := ATB_Data[j + 1];
                ATB_Data[j+1] := tmp;
            end;
//     end;
  // если был ещё кто-то с АТБ > 1000 то всё ок
  if ATB_Data[20].atb >= 1000 then Exit;
  // если нет, пробуем провести игру имитацию
  for i := 0 to 20 do
    if atb_data[i].ID > -1 then
       inc(atb_data[i].atb, atb_data[i].ini); // имитируем тик инициативы
  // и ещё раз сортируем
  for i := 0 to 19 do
       for j := 0 to 19 - i do
            if ATB_Data[j].atb > ATB_Data[j+1].atb then
            begin
                tmp           := ATB_Data[j];
                ATB_Data[j]   := ATB_Data[j+1];
                ATB_Data[j+1] := tmp;
            end;
  // на этом всё, выходим в цикл
end;

end.

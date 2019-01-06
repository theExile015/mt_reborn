unit uPkgProcessor;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes,
  vVar,
  uDB,
  uAdd,
  uai,
  vServerLog,
  sysutils,
  uCharManager,
  uChatManager,
  uObjManager,
  dos;

type
  TPackHeader = record
    _flag : byte;
    _id   : word;
  end;

  TPkg001 = record
    login, pass : string[35];
    fail_code   : byte;
  end;

  TPkg003 = record
    id        : dword;
    fail_code : byte;
  end;

  TPkg004 = record
    data      : TCharHeader;
    fail_code : byte;
  end;

  TPkg005 = record
    id        : dword;
    fail_code : byte;
  end;


  TPkg010 = record
    data : TCharHPMP;
    fail_code : byte;
  end;

  TPkg011 = record
    data : TCharNumbers;
    fail_code : byte;
  end;

  TPkg012 = record
    data : TCharStats;
    fail_code : byte;
  end;

  TPkg013 = record
    data      : TInventory;
    fail_code : byte;
  end;

  TPkg014 = record
    data      : TItemData;
    fail_code : byte;
  end;

  TPkg015 = record
    data      : TCharHeader;
    fail_code : byte;
  end;

  TPkg016 = record
    data      : TPerks;
    fail_code : byte;
  end;

  TPkg017 = record
    data      : array [1..50] of boolean;
    fail_code : byte;
  end;

  TPkg018 = record
    data  : TLocData;
    fail_code : byte;
  end;

  TPkg020 = record
    _from, _to : byte;
    fail_code  : byte;
  end;

  TPkg025 = record
    channel, _to, _from : word;
    msg          : string[200];
    fail_code    : byte;
  end;

  TPkg026 = record
    channel   : word;
    members   : TChatMembersList;
    fail_code : byte;
  end;

  TPkg027 = record
    _who  : word;
    name  : string[50];
    fail_code : byte;
  end;

  TPkg028 = record
    _to, _time : word;
    fail_code  : byte;
  end;

  TPkg029 = record
     data : array [1..16] of Integer;
     fail_code : byte;
  end;

  TPkg030 = record
    stat  : byte;
    fail_code : byte;
  end;

  TPkg031 = record
    school, perk : byte;
    fail_code    : byte;
  end;

  TPkg032 = record
    id        : word;
    data      : TLocObjData;
    fail_code : byte;
  end;

  TPkg040 = record
    ID    : dword;
    fail_code : byte;
  end;

  TPkg041 = record
    ID, pic : dword;
    name : string[30];
    descr: string[200];
    data : array[1..10] of TDialogData;
    fail_code : byte;
  end;

  TPkg042 = record
    qID   : DWORD;
    name  : string[40];
    descr : string[255];
    descr2: string[255];
    descr3: string[255];
    obj   : string[200];
    spic, smask : dword;
    reward : TProps;
    fail_code : byte;
  end;

  TPkg043 = record
    rID : byte;
    qID : dword;
    fail_code : byte;
  end;

  TPkg044 = record
    _what : dword;
    _num  : dword;
    fail_code : byte;
  end;

  TPkg045 = record
    fail_code : byte;
  end;

  TPkg100 = record
    ID        : word;
    ceType    : byte;
    ceRound   : word;
    fail_code : byte;
  end;

  TPkg101 = record
    list      : array [0..20] of TUnitHeader;
    fail_code : byte;
  end;

  TPkg102 = record
    comID          : DWORD;
    uType, uLID    : DWORD;
    what           : byte;
    fail_code      : byte;
  end;

  TPkg103 = record
    uType, uLID    : DWORD;
    data           : TUnitData;
    Vdata          : TUnitVisualData;
    fail_code      : byte;
  end;

  TPkg104 = record
    ceRound   : word;
    fail_code : byte;
  end;

  TPkg105 = record
    comID, uLID : DWORD;
    NextTurn : word;
    fail_code: byte;
  end;

  TPkg106 = record
    comID, uLID   : dword;
    X, Y, ap_left : byte;
    fail_code     : byte;
  end;

  TPkg107 = record
    comID, uLID  : dword;
    dir, ap_left : byte;
    fail_code    : byte;
  end;

procedure pkg001(pkg : TPkg001; sID : word);
   // 2
procedure pkg003(pkg : TPkg003; sID : word);   // 3
procedure pkg004(pkg : TPkg004; sID : word);
procedure pkg005(pkg : TPkg005; sID : word);
  // 6
  // 7
  // 8
  // 9
procedure pkg010(pkg : TPkg010; sID : word);
procedure pkg011(pkg : TPkg011; sID : word);
procedure pkg012(pkg : TPkg012; sID : word);
procedure pkg013(pkg : TPkg013; sID : word);
procedure pkg014(pkg : TPkg014; sID : word);
procedure pkg015(pkg : TPkg015; sID : word);
procedure pkg016(pkg : TPkg016; sID : word);
procedure pkg017(pkg : TPkg017; sID : word);
procedure pkg018(pkg : TPkg018; sID : word);
  // 19
procedure pkg020(pkg : TPkg020; sID : word);
  // 21
  // 22
  // 23
  // 24
procedure pkg025(pkg : TPkg025; sID : word);
procedure pkg026(pkg : TPkg026; sID : word);
procedure pkg027(pkg : TPkg027; sID : word);
procedure pkg028(pkg : TPkg028; sID : word);
procedure pkg029(pkg : TPkg029; sID : word);
procedure pkg030(pkg : TPkg030; sID : word);
procedure pkg031(pkg : TPkg031; sID : word);
procedure pkg032(pkg : TPkg032; sID : word);

procedure pkg040(pkg : TPkg040; sID : word);


procedure pkg043(pkg : TPkg043; sID : word);

procedure pkg045(pkg : TPkg045; sID : word);

procedure pkg102(pkg : TPkg102; sID : word);

procedure pkg105(pkg : TPkg105; sID : word);
procedure pkg106(pkg : TPkg106; sID : word);
procedure pkg107(pkg : TPkg107; sID : word);

procedure pkgProcess(msg: string);

implementation

uses
  vNetCore, uCombatProcessor;

procedure pkg001(pkg : TPkg001; sID : word);
var i    : integer;
    aID  : DWORD;
    _head: TPackHeader;
    _pkg : TPkg001;
    _pkg2: TPkg002;
    mStr : TMemoryStream;
begin
try
  // ищем аккаунт по данным
  aID := DB_GetAccID(pkg.login, pkg.pass);
  WriteSafeText('Acc ID ##:' + IntToStr(aID));
  if aID > high(dword) - 100 then _pkg.fail_code := 2 else _pkg.fail_code := 1;
  // заполняем шапку
  _head._flag := $f;
  _head._id   :=  1;
  // ищем, нет ли сессии с таким же аккаунтом
  // если есть, то выбиваем его
  for i := 0 to high(sessions) do
      if sessions[i].exist then
      if sessions[i].aID = aID then
         begin
           TCP.FCon.IterReset;
           while TCP.FCon.IterNext do
                 if TCP.FCon.Iterator.PeerAddress = sessions[i].ip then
                 if TCP.FCon.Iterator.LocalPort = sessions[i].lport then
                    begin
                      TCP.FCon.Iterator.Disconnect(true);
                      Break;
                    end;
         end;

  // если нашли - присваиваем к сессии
  if _pkg.fail_code = 1 then sessions[sID].aID := aID;

  // Формируем пакет
  mStr := TMemoryStream.Create;

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

  // отправили пакет с ответом, формируем следующий
  mStr.Clear;
  mStr.Position:=0;

  _head._id := 2;
  _pkg2 := DB_GetCharList(aID); // схватываем список персонажей

  mStr.Write(_head, sizeof(_head));
  mStr.Write(_pkg2, sizeof(_pkg2));

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

procedure pkg003(pkg: TPkg003; sID : word);
var _pkg  : TPkg003;
    _pkg2 : TPkg002;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
  _pkg.fail_code := DB_DeleteChar( IntToStr( pkg.id ) );
  Writeln('Delete ##:', _pkg.fail_code);
  try
    mStr := TMemoryStream.Create;
    _head._flag := $f;
    _head._id := 3;

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

    if _pkg.fail_code = 3 then Exit;

    // отправили пакет с ответом, формируем следующий
    mStr.Clear;
    mStr.Position:=0;

    _head._id := 2;
    _pkg2 := DB_GetCharList(Sessions[sID].aID); // схватываем список персонажей

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg2, sizeof(_pkg2));

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



procedure pkg004(pkg : TPkg004; sID : word);
var _pkg  : TPkg004;
    _pkg2 : TPkg002;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
  Writeln('Name ##:', pkg.data.Name);
  _pkg.fail_code :=
  DB_CreateNewChar( sessions[sID].aID,
                    pkg.data.Name,
                    pkg.data.raceID,
                    pkg.data.sex );

try
  mStr := TMemoryStream.Create;
  _head._flag := $f;
  _head._id := 4;

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

  if _pkg.fail_code <> 2 then Exit;

  // отправили пакет с ответом, формируем следующий
  mStr.Clear;
  mStr.Position:=0;

  _head._id := 2;
  _pkg2 := DB_GetCharList(Sessions[sID].aID); // схватываем список персонажей

  mStr.Write(_head, sizeof(_head));
  mStr.Write(_pkg2, sizeof(_pkg2));

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

procedure pkg005(pkg : TPkg005; sID : word);
var _pkg  : TPkg005;
    _head : TPackHeader;
    mStr  : TMemoryStream;
    i     : word;
begin
  i := Char_EnterTheWorld(sID, pkg.id);
  Writeln('Enter world ##:', i);
  if i = high(word) then _pkg.fail_code := 255 else _pkg.fail_code := 1;
  Writeln('Debug 001');
try
  mStr := TMemoryStream.Create;
  _head._flag := $f;
  _head._id := 5;

  mStr.Write(_head, sizeof(_head));
  mStr.Write(_pkg, sizeof(_pkg));
  Writeln('Debug 002');
  // Отправляем пакет
  TCP.FCon.IterReset;
  while TCP.FCon.IterNext do
    if TCP.FCon.Iterator.PeerAddress = sessions[sID].ip then
    if TCP.FCon.Iterator.LocalPort = sessions[sID].lport then
       begin
         Writeln('Debug 003');
         TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
         Break;
       end;
finally
  Writeln('Debug 004');
  mStr.Free;
end;
end;

procedure pkg010(pkg : TPkg010; sID : word);
var _pkg  : TPkg010;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
try
  mStr := TMemoryStream.Create;
  _head._flag := $F;
  _head._id   := 10;

  _pkg.data := Chars[sessions[sID].charLID].hpmp;
  _pkg.fail_code := 0;

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

procedure pkg011(pkg : TPkg011; sID : word);
var _pkg  : TPkg011;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
try
  mStr := TMemoryStream.Create;
  _head._flag := $F;
  _head._id   := 11;

  _pkg.data := Chars[sessions[sID].charLID].Numbers;
  _pkg.fail_code := 0;

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

procedure pkg012(pkg : TPkg012; sID : word);
var _pkg  : TPkg012;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
try
  mStr := TMemoryStream.Create;
  _head._flag := $F;
  _head._id   := 12;

  Char_CalculateStats(sessions[sID].charLID);
  _pkg.data := Chars[sessions[sID].charLID].Stats;
  _pkg.fail_code := 0;

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

procedure pkg013(pkg : TPkg013; sID : word);
var _pkg  : TPkg013;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
try
  mStr := TMemoryStream.Create;
  _head._flag := $F;
  _head._id   := 13;

  DB_GetCharInv(sessions[sID].charLID);
  _pkg.data := Chars[sessions[sID].charLID].Inventory;
  _pkg.fail_code := 0;

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

procedure pkg014(pkg : TPkg014; sID : word);
var _pkg  : TPkg014;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
try
  mStr := TMemoryStream.Create;
  _head._flag := $F;
  _head._id   := 14;

  _pkg.fail_code:=high(byte);

  if pkg.data.ID > 0 then
  if pkg.data.ID <= high(ItemDB) then
     if itemDB[pkg.data.ID].exist then
        begin
          _pkg.data := itemDB[pkg.data.ID].data;
          _pkg.fail_code := 0;
        end;

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

procedure pkg015(pkg : TPkg015; sID : word);
var _pkg  : TPkg015;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
try
  mStr := TMemoryStream.Create;
  _head._flag := $F;
  _head._id   := 15;

  _pkg.data := chars[sessions[sID].charLID].header;
  _pkg.fail_code:=0;

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

procedure pkg016(pkg : TPkg016; sID : word);
var _pkg  : TPkg016;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
try
  mStr := TMemoryStream.Create;
  _head._flag := $F;
  _head._id   := 16;

  _pkg.data := chars[sessions[sID].charLID].perks;

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

// локации на карте
procedure pkg017(pkg : TPkg017; sID : word);
var charLID : DWORD;
    _head   : TPackHeader; _pkg : TPkg017;
    i,k     : word;
    mStr    : TMemoryStream;
begin
  charLID := Sessions[sID].charLID;

  for i := 1 to high(_pkg.data) do
      _pkg.data[i]:=false;


  for i := 1 to high(LocDB) do
    if locDB[i].exist then
       if (locDB[i].props[4] = 0) or         // если нет специальных условий
          (DB_GetCharVar(charLID, 'q' + IntToStr(locDB[i].props[4])) = locDB[i].props[5]) then // или условие выполнено
         _pkg.data[i]:=true;

try
    mStr := TMemoryStream.Create;
    _head._flag := $F;
    _head._id   := 17;

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

// локации на карте
procedure pkg018(pkg : TPkg018; sID : word);
var _head   : TPackHeader; _pkg : TPkg018;
    i       : word;
    mStr    : TMemoryStream;
begin
  i := pkg.data.id;

  if not locDB[i].exist then Exit;

  _pkg.data.id := i;
  _pkg.data.name := LocDB[i].name;
  _pkg.data.links := LocDB[i].links;
  _pkg.data.x:= LocDB[i].props[1];
  _pkg.data.y:= LocDB[i].props[2];
  _pkg.data.pic:= LocDB[i].props[3];

try
    mStr := TMemoryStream.Create;
    _head._flag := $F;
    _head._id   := 18;

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

procedure pkg020(pkg : TPkg020; sID : word);
var charLID : word;
    i1, i2  : byte;
    _pkg    : TPkg013;   _pkg2 : TPkg012; _pkg3 : TPkg010;
begin
  charLID := sessions[sID].charLID;

  i1 := pkg._from;
  i2 := pkg._to;

       if (chars[charLID].Inventory[i2].sub = 6) or  // проверяем совместимость предмета и солота
          (chars[charLID].Inventory[i2].sub = ItemDB[chars[charLID].Inventory[i1].iID].data.sub) then
          if chars[charLID].Inventory[i2].gID = 0 then // если целевой слот пустой
          if chars[charLID].Inventory[i2].sub <> 6 then
          begin
            if ItemDB[chars[charLID].Inventory[i1].iID].data.props[3] <= chars[charLID].header.level then // проверяем требования по лвл
               begin                                     // тогда ставим туда и записываем изменения
                 chars[charLID].Inventory[i2].cDur:=chars[charLID].Inventory[i1].cDur;
                 chars[charLID].Inventory[i2].gID:=chars[charLID].Inventory[i1].gID;
                 chars[charLID].Inventory[i2].iID:=chars[charLID].Inventory[i1].iID;

                 chars[charLID].Inventory[i1].gID:=0;
                 chars[charLID].Inventory[i1].iID:=0;
                 chars[charLID].Inventory[i1].cDur:=0;
                 DB_SetCharInv(charLID);
               end;
          end else
          begin
            chars[charLID].Inventory[i2].cDur:=chars[charLID].Inventory[i1].cDur;
            chars[charLID].Inventory[i2].gID:=chars[charLID].Inventory[i1].gID;
            chars[charLID].Inventory[i2].iID:=chars[charLID].Inventory[i1].iID;

            chars[charLID].Inventory[i1].gID:=0;
            chars[charLID].Inventory[i1].iID:=0;
            chars[charLID].Inventory[i1].cDur:=0;
            DB_SetCharInv(charLID);
          end;

  // готово. шлём обновлённый инвентарь

  pkg013(_pkg, sID);
  Char_CalculateStats( charLID );
  pkg012(_pkg2, sID);
  pkg010(_pkg3, sID);
end;

procedure pkg025(pkg : TPkg025; sID : word);
begin
  case pkg.channel of
    0: Chat_SendMessageToGlobal(pkg.msg, sID);
    1: Chat_SendMessageToLocal(Chars[Sessions[sID].charLID].header.loc, pkg._from, pkg.msg);
    2: Chat_SendMessageToPrivate( pkg._from, pkg._to, pkg.msg );
  end;
end;

procedure pkg026(pkg : TPkg026; sID : word);
begin
  Chat_GetMembersList( pkg.channel, Chars[sessions[sID].charLID].header.loc, sID );
end;

procedure pkg027(pkg : TPkg027; sID : word);
var _pkg  : TPkg027;
    _head : TPackHeader;
    mStr  : TMemoryStream;
    i     : integer;
begin
try
  mStr := TMemoryStream.Create;
  _head._flag := $F;
  _head._id   := 27;

  //_pkg.name:='';
  _pkg._who:= pkg._who;

  for i := 0 to high(chars) do
  if chars[i].exist then
      if chars[i].header.ID = pkg._who then
      begin
        _pkg.name := chars[i].header.Name;
        break;
      end;
  Writeln(_pkg.name);
  if _pkg.name = '' then _pkg.fail_code := 1;

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

procedure pkg028(pkg : TPkg028; sID : word);
var i, rs : integer;
    locID, charLID : DWORD;
    hh, ms : WORD;
var _pkg  : TPkg028;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
  charLID := Sessions[sID].charLID;

  if chars[charLID].in_trvl then exit;                // уже в путешествии
  if chars[charLID].in_combat then exit;              // уже в комбате

  locID := pkg._to;
  if not locDB[locID].exist then exit;

  // проверяем есть ли данная локация в списке линков
  rs := 0;
  for i := 1 to high(locDB[chars[charLID].header.loc].links) do
      if locDB[chars[charLID].header.loc].links[i] = locID then  // лока существует в списке линков
         begin// теперь проверяем открыта ли она
         WriteSafeText('m_Check 1 ' + IntToStr(locDB[locID].links[i]));
         if locDB[locID].exist then
            begin
            WriteSafeText('m_Check 2');
            if (locDB[locDB[locID].links[i]].props[4] = 0) or         // если нет специальных условий
                (DB_GetCharVar(charLID, 'q' + IntToStr(locDB[locDB[locID].links[i]].props[4])) = locDB[locDB[locID].links[i]].props[5]) then // или условие выполнено
                begin
                  rs := 1;
                  break;
                end;
           end;
         end;

  if rs = 0 then
     begin
       WriteSafeText('Can''t reach locID = ' + intToStr(locID));
       exit;
     end else
     begin
       chars[charLID].in_trvl := true;
       GetTime(hh, chars[charLID].trvMin, chars[charLID].trvSec, ms);
       chars[charLID].trvTime := 15;
       chars[charLID].trvDest:=locID;
     //  chars[charLID].header.loc := high(word);
     end;


try
       mStr := TMemoryStream.Create;
       _head._flag := $F;
       _head._id   := 28;

       //_pkg.name:='';
       _pkg._to := locID;
       _pkg._time := chars[charLID].trvTime;
       _pkg.fail_code := rs;

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

procedure pkg029(pkg : TPkg029; sID : word);
begin
  char_SendLocObjs(sessions[sID].charLID, chars[sessions[sID].charLID].header.loc);
end;

procedure pkg030(pkg : TPkg030; sID : word);
var stat    : byte;   pkg1 : TPkg010; pkg2 : TPkg011; pkg3: TPkg012;
    cap     : word;
    charLID : dword;
begin
  charLID := Sessions[sID].charLID;
  if chars[charLID].Numbers.SP < 1 then exit;

  stat := pkg.stat;
  cap := chars[charLID].header.level * 2 + 15;
  if chars[charLID].header.raceID = 2 then
     if stat = 3 then
        cap := cap + trunc(chars[charLID].header.level * 0.5);

  case stat of
    0 : if chars[charLID].bStr + chars[charLID].Points.pStr < cap then
           begin
             inc(chars[charLID].Points.pStr);
             dec(chars[charLID].Numbers.SP);
           end;
    1 : if chars[charLID].bAgi + chars[charLID].Points.pAgi < cap then
           begin
             inc(chars[charLID].Points.pAgi);
             dec(chars[charLID].Numbers.SP);
           end;
    2 : if chars[charLID].bCon + chars[charLID].Points.pCon < cap then
           begin
             inc(chars[charLID].Points.pCon);
             dec(chars[charLID].Numbers.SP);
           end;
    3 : if chars[charLID].bHst + chars[charLID].Points.pHst < cap then
           begin
             inc(chars[charLID].Points.pHst);
             dec(chars[charLID].Numbers.SP);
           end;
    4 : if chars[charLID].bInt + chars[charLID].Points.pInt < cap then
           begin
             inc(chars[charLID].Points.pInt);
             dec(chars[charLID].Numbers.SP);
           end;
    5 : if chars[charLID].bSpi + chars[charLID].Points.pSpi < cap then
           begin
             inc(chars[charLID].Points.pSpi);
             dec(chars[charLID].Numbers.SP);
           end;
  end;

  DB_SetCharData(charLID, chars[charLID].header.Name);
  Char_CalculateStats(charLID);

  pkg010(pkg1, sID);
  pkg011(pkg2, sID);
  pkg012(pkg3, sID);
end;

procedure pkg031(pkg : TPkg031; sID : word);
var i, pid: integer;   _pkg010 : TPkg010; _pkg011: TPkg011; _pkg012: TPkg012; _pkg016: TPkg016;
    s: string; sk, pr : word;
    r, charLID, cID: DWORD;
begin
  charLID := Sessions[sID].charLID;
  sk := pkg.school;
  pr := pkg.perk;
  pid := GetPerkID(sk, pr);

  if chars[charLID].perks[sk][pr] >= PerksDB[pid].maxrank then exit;

  if Chars[charLID].numbers.TP < PerksDB[pid].cost[chars[charLID].perks[sk][pr] + 1] then
     begin
       exit;
     end;

  if (sk = 0) and (pr = 2) then
     if chars[charLID].perks[0][1] < 2 then exit;
  if (sk = 1) and (pr = 2) then
     if chars[charLID].perks[1][1] < 2 then exit;
  if (sk = 2) and (pr = 2) then
     if chars[charLID].perks[2][1] < 2 then exit;
  if (sk = 3) and (pr = 2) then
     if chars[charLID].perks[3][1] < 2 then exit;
  if (sk = 4) and (pr = 2) then
     if chars[charLID].perks[4][1] < 2 then exit;
  if (sk = 5) and (pr = 2) then
     if chars[charLID].perks[5][1] < 2 then exit;
  if (sk = 6) and (pr = 2) then
     if chars[charLID].perks[6][1] < 2 then exit;

  WriteSafeText('Before incr = ' + IntToStr( chars[charLID].perks[sk][pr] ), 2);
  inc(chars[charLID].perks[sk][pr], 1);
  WriteSafeText('After incr = ' + IntToStr( chars[charLID].perks[sk][pr]), 2);

  WriteSafeText('pID = ' + IntToStr(pID), 2);
  WriteSafeText('Cost = ' + IntToStr(PerksDB[pid].cost[chars[charLID].perks[sk][pr]]), 2);
  dec(chars[charLID].Numbers.TP, PerksDB[pid].cost[chars[charLID].perks[sk][pr]]);

  DB_SetCharData( charLID, Chars[charLID].header.Name);
  Char_CalculateStats(charLID);

  pkg010(_pkg010, sID);
  pkg011(_pkg011, sID);
  pkg012(_pkg012, sID);
  pkg016(_pkg016, sID);
end;

procedure pkg032(pkg : TPkg032; sID : word);
var _pkg  : TPkg032;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
if not LocObjs[pkg.id].exist then exit;
   _pkg.data.x:=LocObjs[pkg.id].props2[1];
   _pkg.data.y:=LocObjs[pkg.id].props2[2];
   _pkg.data.w:=LocObjs[pkg.id].props2[3];
   _pkg.data.h:=LocObjs[pkg.id].props2[4];
   _pkg.data.cType:=LocObjs[pkg.id].props2[5];
   _pkg.data.oID:=LocObjs[pkg.id].props2[6];
   _pkg.data.gID:=pkg.id;
   _pkg.data.tID:=LocObjs[pkg.id].props2[7];
   _pkg.data.enabled:=1;
   _pkg.data.name:=LocObjs[pkg.id].name;
   _pkg.data.animation:=LocObjs[pkg.id].props2[8];;
try
       mStr := TMemoryStream.Create;
       _head._flag := $F;
       _head._id   := 32;

       _pkg.id:= pkg.id;

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

procedure pkg040(pkg : TPkg040; sID : word);
begin
try
  if pkg.fail_code <> 1 then
  if LocObjs[pkg.ID].exist then
     case LocObjs[pkg.ID].oType of
       1 : Obj_SendDialogs(sID, pkg.ID);
      // 2 : Obj_SendVerndor(sId, pkg.ID);
       5 : Obj_StartBattle(sessions[sID].charLID, LocObjs[pkg.ID].props[1]);
     else
       WriteSafeText('DUMMY!!!', 1);
     end;

  if pkg.fail_code = 1 then
  if ObjDialogs[pkg.ID].exist then
     case ObjDialogs[pkg.ID].data.dType of
       3     : Obj_StartQuestBattle(sessions[sID].charLID, pkg.ID);
       11, 7 : Obj_QuestSend(Sessions[sID].charLID, pkg.ID);
     else
       WriteSafeText('~~ !!! ~~', 2);
     end;
except
  WriteSafeText('Illegal object request', 1);
end;
end;

procedure pkg043(pkg : TPkg043; sID : word);
begin
  if QuestDB[pkg.qID].exist then
     Obj_QuestProcess(sID, pkg.qID, pkg.rID, pkg.fail_code);
end;

procedure pkg045(pkg : TPkg045; sID : word);
begin
  DB_SetCharTutor(Sessions[sID].charLID, pkg.fail_code);
end;

procedure pkg102(pkg : TPkg102; sID : word);
var  comLID, uLID, i : DWORD;
     _pkg   : TPkg103;
     _head  : TPackHeader;
     mStr   : TMemoryStream;
begin
  writeln(pkg.uLID, ' ', pkg.uType, ' ', pkg.comID);

  comLID := CM_GetCombatLID(pkg.comID);
  Writeln('ComLID = ', comLID);
  if comLID = high(dword) then Exit;

  uLID := high(dword);
  for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = pkg.uType then
      if combats[comLID].Units[i].uLID = pkg.uLID then
         uLID := i;
  Writeln('uLID = ', uLID);
  if uLID = high(dword) then exit;

  Writeln('Fine. Forming pkg');
  _pkg.uType:= pkg.uType;
  _pkg.uLID:= pkg.uLID;
  _pkg.data := combats[comLID].Units[uLID].Data;
  _pkg.Vdata:= combats[comLID].Units[uLID].VData;

  _head._id:=103;
  _head._flag:=$f;

       try
         mStr := TMemoryStream.Create;

         mStr.Write(_head, sizeof(_head));
         mStr.Write(_pkg, sizeof(_pkg));

         // Отправляем пакет
         TCP.FCon.IterReset;
         while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[sID].lport then
              begin
                writeln('Sending... ', TCP.FCon.Iterator.PeerAddress);
                Writeln('Bytes sended... ', TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator));
                Break;
              end;
       finally
         mStr.Free;
       end;
end;

procedure pkg105(pkg : TPkg105; sID : word);
var comLID : dword;
begin
  comLID := CM_GetCombatLID(pkg.comID);
  if comlid <> high(dword) then
     if combats[comlid].NextTurn = pkg.uLID then
        combats[comlid].On_Recount := true;
end;

procedure pkg106(pkg : TPkg106; sID : word);
var  comLID, uLID, charLID, i : DWORD;
     _pkg   : TPkg106;
     _head  : TPackHeader;
     mStr   : TMemoryStream;
     step_ap, DIR   : byte;
     SW     : boolean;
begin
  uLID   := high(DWORD);
  comLID := CM_GetCombatLID(pkg.comID);
  if comLID = high(dword) then Exit;
  for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uLID = pkg.uLID then
         uLID := i;
  if uLID = high(dword) then exit;
// заполняем маску карты "препядствиями"
  Map_CreateMask( comLID );
  for i := 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist and combats[comLID].units[i].alive then
    if (i <> uLID) then
       combats[comLID].MapMatrix[combats[comLID].units[i].Data.pos.x, combats[comLID].units[i].Data.pos.Y].cType:= 1;
// устанавливаем цену шага
  step_ap := 5;
// проверяем, хватает ли АП на ход. Если нет - аборт
  SW := AI_PointInRange( combats[comLID].Units[uLID].Data.pos.x,
                         combats[comLID].Units[uLID].Data.pos.y, pkg.X, pkg.Y,
                         trunc(combats[comLID].Units[uLID].Data.cAP/step_ap));
  if not SW then exit;
// ищем путь
  SW := SearchWay( comLID, combats[comLID].units[uLID].Data.pos.x,
                   combats[comLID].units[uLID].Data.pos.y, pkg.X, pkg.Y);
  if not SW then exit;
// Если нашли - устанавливаем координаты, убавляем АП
  combats[comLID].units[uLID].Data.pos.x:=pkg.X;
  combats[comLID].units[uLID].Data.pos.y:=pkg.y;
  if length(combats[comLID].Way) < 2 then exit;
  combats[comLID].units[uLID].Data.cAP:=combats[comLID].units[uLID].Data.cAP - (length(combats[comLID].Way) - 1) * Step_AP;
  Writeln('AP LEFT : ',  combats[comLID].units[uLID].Data.cAP);
  DIR := CM_SetUnitDirection(combats[comLID].Way[length(combats[comLID].Way) - 2].x,
                             combats[comLID].Way[length(combats[comLID].Way) - 2].y,
                             pkg.X, pkg.Y);
  combats[comLID].units[uLID].Data.Direct := DIR;

  if combats[comLID].units[uLID].Data.cAP < 0 then
     combats[comLID].units[uLID].Data.cAP := 0;

// теперь рассылаем данные
       try
         mStr := TMemoryStream.Create;

         _head._flag:=$f;
         _head._id:=106;

         _pkg.X:=pkg.X;
         _pkg.Y:=pkg.y;
         _pkg.comID:=combats[comLID].ID;
         _pkg.uLID:= combats[comLID].Units[uLID].uLID;
         _pkg.ap_left:= combats[comLID].Units[uLID].Data.cAP;

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

procedure pkg107(pkg : TPkg107; sID : word);
var  comLID, uLID, charLID, i : DWORD;
     _pkg   : TPkg107;
     _head  : TPackHeader;
     mStr   : TMemoryStream;
begin
  uLID   := high(DWORD);
  comLID := CM_GetCombatLID(pkg.comID);
  if comLID = high(dword) then Exit;
  for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uLID = pkg.uLID then
         uLID := i;
  if uLID = high(dword) then exit;

// проверяем ауру Keep Moving
  if (combats[comLID].units[uLID].Data.cAP > 4) or (CM_FindAura(comLID, uLID, 1) <> high(byte)) then
     begin
       Writeln('Inside ', pkg.dir);
       i := high(DWORD);
       combats[comLID].units[uLID].Data.Direct := pkg.dir;
       if CM_FindAura(comLID, uLID, 1) <> high(byte) then
          CM_DelAura(comLID, uLID, 1)
       else
       begin
         dec(combats[comLID].units[uLID].Data.cAP, 5 );
         CM_DelAura(comLID, uLID, 2);
       end;
       if combats[comLID].units[uLID].Data.cAP < 0 then combats[comLID].units[uLID].Data.cAP := 0;
     end;
  Writeln('Result : ', i);
  if i <> high(DWORD) then Exit;
// теперь рассылаем данные
try
  mStr := TMemoryStream.Create;

  _head._flag:=$f;
  _head._id:=107;

  _pkg.comID   := combats[comLID].ID;
  _pkg.uLID    := combats[comLID].Units[uLID].uLID;
  _pkg.dir     := combats[comLID].Units[uLID].Data.Direct;
  _pkg.ap_left := combats[comLID].Units[uLID].Data.cAP;

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

procedure pkgProcess(msg: string);
begin
  if msg = '' then Exit;
end;

end.


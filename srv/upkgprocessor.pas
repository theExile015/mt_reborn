unit uPkgProcessor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  vVar,
  uDB,
  vServerLog,
  sysutils,
  uCharManager;

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


procedure pkgProcess(msg: string);

implementation

uses
  vNetCore;

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
begin
  _pkg.fail_code := Char_EnterTheWorld(sID, pkg.id);

  Writeln('Enter world ##:', pkg.fail_code);

try
  mStr := TMemoryStream.Create;
  _head._flag := $f;
  _head._id := 5;

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

procedure pkgProcess(msg: string);
begin
  if msg = '' then Exit;
end;

end.


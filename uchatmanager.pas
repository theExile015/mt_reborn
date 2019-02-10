unit uChatManager;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, vVar, vServerLog;

function Chat_GetMembersList(chatID, locID, sID : DWORD) : string;

function Chat_SendMessageToGlobal(msg : string; _sID : word): byte;
function Chat_SendMessageToLocal(locID, from: word; msg : string): byte;
function Chat_SendMessageToPrivate(_from, _to : word; msg : string): byte;

implementation

uses uCharManager, vNetCore, uPkgProcessor;

function Chat_GetMembersList(chatID, locID, sID : DWORD) : string;
var _pkg : TPkg026; _head : TPackHeader;
    i, k : integer;
    mStr : TMemoryStream;
begin
  result := '';   k := 1;

  for i := 0 to high(_pkg.members) do
      begin
        _pkg.members[i].exist:=false;
        _pkg.members[i].Nick:='';
      end;

  _pkg.channel := chatID;

  if chatID = 0 then    // глобальный чат
     for i := 0 to length(chars) - 1 do
         if chars[i].exist and chars[i].in_global_chat then
            begin
              _pkg.members[k].exist:=true;
              _pkg.members[k].Nick := Chars[i].header.Name;
              _pkg.members[k].charID:= Chars[i].header.ID;
              _pkg.members[k].clan:= Chars[i].Numbers.Clan;
              _pkg.members[k].level:= Chars[i].header.level;
              _pkg.members[k].klass:= Chars[i].header.classID;
              inc(k);
              if k > 30 then break;
            end;

  if chatID = 1 then // локальный чат
       for i := 0 to length(chars) - 1 do
         if chars[i].exist and (chars[i].header.loc  = locID) then
            begin  // пишем чар ИД, ник, lvl, класс, клан
              _pkg.members[k].exist:=true;
              _pkg.members[k].Nick := Chars[i].header.Name;
              _pkg.members[k].charID:= Chars[i].header.ID;
              _pkg.members[k].clan:= Chars[i].Numbers.Clan;
              _pkg.members[k].level:= Chars[i].header.level;
              _pkg.members[k].klass:= Chars[i].header.classID;
              inc(k);
              if k > 30 then break;
            end;
  try
    mStr := TMemoryStream.Create;
    _head._flag := $F;
    _head._id   := 26;

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

function Chat_SendMessageToGlobal(msg : string; _sID : word): byte;
var i : integer;
    key : string;
    _pkg : TPkg025; _head : TPackHeader;
    mStr : TMemoryStream;
begin
         if length(msg) > 2 then
         if copy(Chars[sessions[_sID].charLID].header.Name, length(Chars[sessions[_sID].charLID].header.Name) - 4, 5) = '[DEV]' then
            begin
              key := copy(msg, 1, 2);
              if key = '!i' then
                 begin
                   if length(msg) < 5 then exit;
                   key := copy(msg, 3, 3);
                   // Char_AddItem(charLID, StrToInt(key));
                   exit;
                 end;
              if key = '!e' then
                 begin
                   if length(msg) < 6 then exit;
                   key := copy(msg, 3, 4);
                   Char_AddNumbers(Sessions[_sID].charLID, 0, StrToInt(key), 0, 0, 0);
                   exit;
                 end;
              if key = '!g' then
                 begin
                   if length(msg) < 6 then exit;
                   key := copy(msg, 3, 4);
                   Char_AddNumbers(Sessions[_sID].charLID, StrToInt(key), 0, 0, 0, 0);
                   exit;
                 end;
            end;

  try
    mStr := TMemoryStream.Create;
    _head._flag := $F;
    _head._id   := 25;

    _pkg.channel := 0;
    _pkg._from   := Chars[sessions[_sID].charLID].header.ID;
    _pkg.msg     := msg;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет
for i := 0 to high(chars) do
    if chars[i].exist then
    if chars[i].in_global_chat then
begin
    TCP.FCon.IterReset;
    while TCP.FCon.IterNext do
      if TCP.FCon.Iterator.PeerAddress = sessions[chars[i].sID].ip then
      if TCP.FCon.Iterator.LocalPort = sessions[chars[i].sID].lport then
         begin
           TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
           Break;
         end;
end;
  finally
    mStr.Free;
  end;
end;

function Chat_SendMessageToLocal(locID, from: word; msg : string): byte;
var _pkg  : TPkg025;
    _head : TPackHeader;
    mStr  : TMemoryStream;
    i     : integer;
begin
  try
     mStr := TMemoryStream.Create;
     _head._flag := $F;
     _head._id   := 25;

     _pkg.channel := 1;
     _pkg._from   := from;
     _pkg.msg     := msg;

     mStr.Write(_head, sizeof(_head));
     mStr.Write(_pkg, sizeof(_pkg));

     // Отправляем пакет
 for i := 0 to high(chars) do
     if chars[i].exist then
     if chars[i].header.loc = locID then
 begin
     TCP.FCon.IterReset;
     while TCP.FCon.IterNext do
       if TCP.FCon.Iterator.PeerAddress = sessions[chars[i].sID].ip then
       if TCP.FCon.Iterator.LocalPort = sessions[chars[i].sID].lport then
          begin
            TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
            Break;
          end;
 end;
   finally
     mStr.Free;
   end;
end;

function Chat_SendMessageToPrivate(_from, _to : word; msg : string): byte;
var _pkg  : TPkg025;
    _head : TPackHeader;
    mStr  : TMemoryStream;
    i     : integer;
begin
  try
     mStr := TMemoryStream.Create;
     _head._flag := $F;
     _head._id   := 25;

     _pkg.channel := 1;
     _pkg._from   := _from;
     _pkg._to     := _to;
     _pkg.msg     := msg;

     mStr.Write(_head, sizeof(_head));
     mStr.Write(_pkg, sizeof(_pkg));

     // Отправляем пакет
 for i := 0 to high(chars) do
     if chars[i].exist then
     if chars[i].header.ID = _to then
 begin
     TCP.FCon.IterReset;
     while TCP.FCon.IterNext do
       if TCP.FCon.Iterator.PeerAddress = sessions[chars[i].sID].ip then
       if TCP.FCon.Iterator.LocalPort = sessions[chars[i].sID].lport then
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


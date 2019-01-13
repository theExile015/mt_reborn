unit uXClick;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  windows,
  classes,
  zglHeader,
  uVar,
  uLocalization,
  uAdd,
  dos;

procedure DoLogin();
procedure DoCreateChar();
procedure DoDelete();
procedure DoEnterTheWorld();
procedure SendEnterTheWorld();
procedure DoOpenInv();
procedure DoItemRequest(ID: integer);
procedure DoPerkRequest();
procedure DoSwap(_from, _to: byte);
procedure DoSendMsg(msg: string);
function DoWho(id : word): string;
procedure DoStatUP(stat: byte);
procedure DoPerkUP(sc, perk: byte);
procedure DoMapRequest();
procedure DoRequestLoc(id: word);
procedure DoRequestLocObjs();
procedure DoRequestObj(id: word);
procedure DoTravel(id: word);
procedure DoObjectClick(id: word);
procedure DoDlgClick(id: word);
procedure DoSendQuest(id, action : word);
procedure DoSendTutorial(step : byte);
procedure DoRequestUnit(id, uType, what: word);
procedure DoRequestMembers();

implementation

uses u_MM_gui, uNetCore, uPkgProcessor, uChat;

procedure DoLogin();
begin
       if TCP.FConnect then exit;

       if utf8_length(NonameEdit2.Caption) < 3 then
          begin
            gui.ShowMessage(ERC[15], ERB[15]);
            exit;
          end;

       if utf8_length(NonameEdit3.Caption) < 3 then
          begin
            gui.ShowMessage(ERC[16], ERB[16]);
            exit;
          end;

       if not checkSymbolsLP(Nonameedit2.Caption) then
       if not checkSymbolsLP(Nonameedit3.Caption) then
          begin
            gui.ShowMessage(ERC[5], ERB[5]);
            exit;
          end;

       cns := csConcting;
       mWins[17].visible := true;
       mWins[17].btns[1].visible:=false;
       mWins[17].btns[2].visible:=false;
       mWins[17].texts[1].Text:= 'Connecting...';
      // timeout := gettickcount();
       Nonameform1.Enabled:=false;

       ini_LoadFromFile('gameini.ini');
       Ini_WriteKeyStr('LOGIN', 'ACC', Nonameedit2.Caption);
       Ini_WriteKeyStr('LOGIN', 'PASS', Nonameedit3.Caption);
       Ini_SaveToFile('gameini.ini');
       ini_free();
end;

procedure DoCreateChar();
var i    : integer;
    _pkg : TPkg004;
    _head: TPackHeader;
    mStr : TMemoryStream;
begin
       if utf8_length(eCharName.Caption) < 2 then
          begin
            gui.ShowMessage(ERC[18], ERB[18]);
            exit;
          end;
       if not CheckSymbolsN(eCharName.Caption) then
          begin
            gui.ShowMessage(ERC[6], ERB[6]);
            exit;
          end;
       //берём значение пола
       if rgGender.Selected = rbMale then i := 0 else i := 1;
       //преобразуем имя в правильный формат
       _pkg.data.Name := u_StrUp( utf8_Copy( eCharName.Caption, 1, 1) ) + u_StrDown( utf8_Copy( eCharName.Caption, 2, utf8_Length( eCharName.Caption ) - 1 ) );
       _pkg.data.sex := i;
       _pkg.data.raceID := cbRace.Selected + 1;

       _head._FLAG := $f;
       _head._ID   := 4;
try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
finally
       mStr.Free;
end;
end;

procedure DoDelete();
var _pkg  : TPkg003;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
       _head._FLAG := $f;
       _head._ID   := 3;
       _pkg.id     := charlist[gSI].ID ;
try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
finally
       mStr.Free;
end;
end;


procedure DoEnterTheWorld();
begin
  if CharList[gSI].ID = 0 then Exit;
  fCharMan.Hide;
  a_p := 0;
  gs := gsPreGame;
end;

procedure SendEnterTheWorld();
var _pkg  : TPkg005;
    _head : TPackHeader;
    mStr  : TMemoryStream;
    hh, mm, ss, ms : word;
begin
       _head._FLAG := $f;
       _head._ID   := 5;
       _pkg.id     := charlist[gSI].ID ;

       GetTime(hh, mm, ss, ms);
       wait_for_05 := ss;

       activechar.header := charlist[gSI];
       tutorial := activechar.header.tutorial;

       writeln('Tutorial ## ', tutorial);
try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
finally
       mStr.Free;
end;
end;

procedure DoOpenInv();
var _pkg  : TPkg013;
    _head : TPackHeader;
    mStr  : TMemoryStream;
    i     : integer;
begin
  for i := 0 to high(items) do
      items[i].req:=false;

       _head._FLAG := $f;
       _head._ID   := 13;
       _pkg.fail_code:= 1;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
finally
       mStr.Free;
end;
end;

procedure DoPerkRequest();
var _pkg  : TPkg016;  _pkg011: TPkg011; _pkg012: TPkg012;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
       _head._FLAG := $f;
       _head._ID   := 16;
       _pkg.fail_code:= 0;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
finally
       mStr.Free;
end;

       sleep(20);
       _head._FLAG := $f;
       _head._ID   := 11;
       _pkg011.fail_code:= 0;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg011, sizeof(_pkg011));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
finally
       mStr.Free;
end;

       sleep(20);
       _head._FLAG := $f;
       _head._ID   := 12;
       _pkg012.fail_code:= 0;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg012, sizeof(_pkg012));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
finally
       mStr.Free;
end;
end;

procedure DoItemRequest(ID: integer);
var _pkg  : TPkg014;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
       _head._FLAG := $f;
       _head._ID   := 14;
       _pkg.data.ID := ID;
       writeln('item request ## :', id);
try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoSwap(_from, _to: byte);
var _pkg  : TPkg020;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
       _head._FLAG := $f;
       _head._ID   := 20;

       _pkg._from := _from;
       _pkg._to   := _to;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoSendMsg(msg: string);
var _pkg  : TPkg025;
    _head : TPackHeader;
    mStr  : TMemoryStream;
    s     : String;
    i     : integer;
begin
  if msg = '' then Exit;
  s := Chat_CatchPrivte( msg ) ;
 // if Chat_CheckMessage( msg ) then //проверим сообщение
  if s = '' then
  begin
     _pkg.channel := ch_tab_curr;
     _pkg._from   := activechar.header.ID;
     _pkg._to := high(word);;
     _pkg.msg := msg;
  end else
  begin
    _pkg._to     := 0;
    _pkg.channel := 2;
    _pkg._from   := activechar.header.ID;
    for i := 1 to high(ch_tabs[ch_tab_curr].Members) do
        if ch_tabs[ch_tab_curr].Members[i].Nick = s then
           _pkg._to:= ch_tabs[ch_tab_curr].Members[i].charID;
  end;
  if _pkg._to = 0 then Exit; // кривой приват какой-то

  _head._FLAG := $f;
  _head._ID   := 25;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

function DoWho(id : word): string;
var _pkg  : TPkg027;
    _head : TPackHeader;
    mStr  : TMemoryStream;
    i     : integer;
begin
  result := '';

  for i := 1 to high(wholist) do
      if wholist[i].id = id then
         begin
            result := wholist[i].name;
            break;
         end;

  if result <> '' then Exit;

  _head._FLAG := $f;
  _head._ID   := 27;

  _pkg._who := id;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoStatUP(stat: byte);
var _pkg  : TPkg030;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
  block_btn := true; // блокируем кнопку во избежании мультикликов

  _head._FLAG := $f;
  _head._ID   := 30;

  _pkg.stat := stat;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoPerkUP(sc, perk: byte);
var _pkg  : TPkg031;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
  block_btn := true; // блокируем кнопку во избежании мультикликов

  Writeln(sc, ' ', perk);

  _head._FLAG := $f;
  _head._ID   := 31;

  _pkg.school := sc;
  _pkg.perk := perk;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoMapRequest();
var _pkg  : TPkg017;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 17;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoRequestLoc(id: word);
var _pkg  : TPkg018;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 18;

  _pkg.data.id:=id;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoTravel(id: word);
var _pkg  : TPkg028;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
  if id = 0 then exit;
  _head._FLAG := $f;
  _head._ID   := 28;

  _pkg._to := id;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoRequestLocObjs();
var
  _head : TPackHeader; _pkg029: TPkg029;
  mStr  : TMemoryStream;
  hh, mm, ss, ms : word;
begin
    GetTime(hh, mm, ss, ms);
    wait_for_29 := ss;

    _head._FLAG := $f;
    _head._ID   := 29;
  try
    mStr := TMemoryStream.Create;
    mStr.Position := 0;
    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg029, sizeof(_pkg029));

    TCP.FCon.IterReset;
    TCP.FCon.IterNext;
    TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
    In_Request := true;
  finally
    mStr.Free;
  end;
end;

procedure DoRequestObj(id: word);
var _pkg  : TPkg032;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
if objstore[id].request then exit;

  objstore[id].request:=true;
  _head._FLAG := $f;
  _head._ID   := 32;

  _pkg.id:=id;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
  sleep(50);
end;

procedure DoObjectClick(id: word);
var
  _pkg : TPkg040; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  objstore[id].request:=true;
  _head._FLAG := $f;
  _head._ID   := 40;

  _pkg.id:=id;
  _pkg.fail_code:=0;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;

end;

procedure DoDlgClick(id: word);
var
  _pkg : TPkg040; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  objstore[id].request:=true;
  _head._FLAG := $f;
  _head._ID   := 40;

  _pkg.id := id;
  _pkg.fail_code := 1;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;

end;

procedure DoSendQuest(id, action : word);
var
  _pkg : TPkg043; _head: TPackHeader;
  mStr : TMemoryStream;
  i, j, k : integer;
begin
  objstore[id].request:=true;
  _head._FLAG := $f;
  _head._ID   := 43;

  _pkg.qid := id;
  _pkg.rID:= 0;
  _pkg.fail_code:=255;
  if mWins[8].flag = 11 then
     _pkg.fail_code := 0
  else
     _pkg.fail_code := 1;

  if _pkg.fail_code = 1 then
     begin
       j := 0; k := 0;
       for i := 6 to 10 do
         if mWins[8].dnds[i].exist then
            if mWins[8].dnds[i].data.contain > 0 then inc(k);
       //Chat_AddMessage(ch_tab_curr, '', u_IntToStr(j));
       //k := j;
       if k > 0 then
       begin
          for i := 6 to 10 do
            if mWins[8].dnds[i].exist then
               if mWins[8].dnds[i].selected then j := i;
          if (k > 0) and (j = 0) then
             begin
               Chat_AddMessage(ch_tab_curr, high(word), 'Choose reward first.');
               Exit;
             end
       end;
       if (k <> 0) and (j <> 0) then _pkg.rID := j - 2;

       if k = 0 then
          begin
            mWins[8].visible:=false;
            Chat_AddMessage(ch_tab_curr, high(word), 'Quest "' + mWins[8].texts[1].Text + '" complete.');
            igs := igsNone;
          end else
          if j <> 0 then
          begin
            mWins[8].visible:=false;
            Chat_AddMessage(ch_tab_curr, high(word), 'Quest "' + mWins[8].texts[1].Text + '" complete.');
            igs := igsNone;
          end;
     end else
     begin
        mWins[8].visible:=false;
        Chat_AddMessage(ch_tab_curr, high(word), 'Quest "' + mWins[8].texts[1].Text + '" accepted.');
        igs := igsNone;
     end;

if (k <> 0) and (j = 0) then Exit;

try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoSendTutorial(step : byte);
var
  _pkg : TPkg045; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 45;

  _pkg.fail_code := step;
try
       mStr := TMemoryStream.Create;
       mStr.Position := 0;
       mStr.Write(_head, sizeof(_head));
       mStr.Write(_pkg, sizeof(_pkg));

       TCP.FCon.IterReset;
       TCP.FCon.IterNext;
       TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
       In_Request := true;
finally
       mStr.Free;
end;
end;

procedure DoRequestUnit(id, uType, what: word);
var
  _pkg : TPkg102; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 102;

  _pkg.comID := combat_id;
  _pkg.uType := uType;
  _pkg.uLID  := units[id].uLID;
  _pkg.what  := 0;
try
  mStr := TMemoryStream.Create;
  mStr.Position := 0;
  mStr.Write(_head, sizeof(_head));
  mStr.Write(_pkg, sizeof(_pkg));

  TCP.FCon.IterReset;
  TCP.FCon.IterNext;
  TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
  In_Request := true;
finally
  mStr.Free;
end;
end;

procedure DoRequestMembers();
var
  _pkg : TPkg026; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 26;

  _pkg.channel := ch_tab_curr;
try
  mStr := TMemoryStream.Create;
  mStr.Position := 0;
  mStr.Write(_head, sizeof(_head));
  mStr.Write(_pkg, sizeof(_pkg));

  TCP.FCon.IterReset;
  TCP.FCon.IterNext;
  TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);

  Sleep(100);
finally
  mStr.Free;
end;

end;

end.


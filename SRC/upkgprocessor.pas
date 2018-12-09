unit uPkgProcessor;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes,
  uVar,
  uAdd,
  zglHeader,
  uParser,
  uCharSelect,
  uLocalization;

type
  TPackHeader = record
    _FLAG : BYTE;
    _ID   : WORD;
  end;

  TPkg001 = record
    login, pass : string[35];
    fail_code   : byte;         // присылает сервер
  end;

  TPkg002 = record
    Chars     : array [1..4] of TCharHeader;
    fail_code : byte;
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
    data       : TCharHPMP;
    fail_code  : byte;
  end;

  TPkg011 = record
    data       : TCharNumbers;
    fail_code  : byte;
  end;

  TPkg012 = record
    data       : TCharStats;
    fail_code  : byte;
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
    _who : word;
    name : string[50];
    fail_code : byte;
  end;

  TPkg030 = record
    stat : byte;
    fail_code : byte;
  end;

  TPkg031 = record
    school, perk : byte;
    fail_code    : byte;
  end;

procedure pkg000;
procedure pkg001(pkg: TPkg001);   // Логин
procedure pkg002(pkg: TPkg002);   // Список персонажей
procedure pkg003(pkg: TPkg003);   // Удалить персонажа
procedure pkg004(pkg: TPkg004);   // Новый персонаж
procedure pkg005(pkg: TPkg005);   // Вход в мир
  // 6
  // 7
  // 8
  // 9
procedure pkg010(pkg: TPkg010);   // HP-MP-AP
procedure pkg011(pkg: TPkg011);   // Numbers
procedure pkg012(pkg: TPkg012);   // Stats
procedure pkg013(pkg: TPkg013);   // Inv
procedure pkg014(pkg: TPkg014);   // Item data
procedure pkg015(pkg: TPkg015);   // Header
procedure pkg016(pkg: TPkg016);   // Perks



procedure pkg025(pkg: TPkg025);   // Chat msg
procedure pkg026(pkg: TPkg026);   // Member list
procedure pkg027(pkg: TPkg027);   // Who request

procedure pkgProcess(var msg: string);

{procedure pkgProcess(var msg : string);
procedure pkgExecute(pack : TPackage); }

implementation

uses
  uNetCore, u_MM_gui, uLoader, uChat, uXClick;

procedure pkgProcess(var msg: string);
var
    _msg   : string;
    head   : TPackHeader;
    mStr   : TMemoryStream;
    _pkg001: TPkg001;   _pkg002: TPkg002;   _pkg003: TPkg003;
    _pkg004: TPkg004;   _pkg005: TPkg005;

    _pkg010: TPkg010;   _pkg011: TPkg011;   _pkg012: TPkg012;
    _pkg013: TPkg013;   _pkg014: TPkg014;   _pkg015: TPkg015;
    _pkg016: TPkg016;

    _pkg025: TPkg025;   _pkg026: TPkg026;   _pkg027: TPkg027;
begin
  try
       begin
       //  writeln('Pkg ##:', msg);
       //  writeln('Size ##:', length(msg));
         mStr := TMemoryStream.Create;
         mStr.Write(msg[1], length(msg));       // загружаем эти данные в поток

         mStr.Position:=0;                      // выставляем каретку на 0
         mStr.Read(head, sizeof(head));         // читаем заголовок

         if head._FLAG <> $f then Exit;         // если заголовок "битый" прерываем дальнейшие действия
         Writeln('Pack ##:', head._ID);
         case head._ID of
           0:
           begin
             pkg000();
           end;
           1:
           begin
             mStr.Read(_pkg001, SizeOf(_pkg001));
             pkg001(_pkg001);
           end;
           2:
           begin
             mStr.Read(_pkg002, SizeOf(_pkg002));
             pkg002(_pkg002);
           end;
           3:
           begin
             mStr.Read(_pkg003, SizeOf(_pkg003));
             pkg003(_pkg003);
           end;
           4:
           begin
             mStr.Read(_pkg004, SizeOf(_pkg004));
             pkg004(_pkg004);
           end ;
           5:
           begin
             mStr.Read(_pkg005, SizeOf(_pkg005));
             pkg005(_pkg005);
           end;

           10:
           begin
             mStr.Read(_pkg010, SizeOf(_pkg010));
             pkg010(_pkg010);
           end;
           11:
           begin
             mStr.Read(_pkg011, SizeOf(_pkg011));
             pkg011(_pkg011);
           end;
           12:
           begin
             mStr.Read(_pkg012, SizeOf(_pkg012));
             pkg012(_pkg012);
           end;
           13:
           begin
             mStr.Read(_pkg013, SizeOf(_pkg013));
             pkg013(_pkg013);
           end;
           14:
           begin
             mStr.Read(_pkg014, SizeOf(_pkg014));
             pkg014(_pkg014);
           end;
           15:
           begin
             mStr.Read(_pkg015, SizeOf(_pkg015));
             pkg015(_pkg015);
           end;
           16:
           begin
             mStr.Read(_pkg016, SizeOf(_pkg016));
             pkg016(_pkg016);
           end;
           25:
           begin
             mStr.Read(_pkg025, SizeOf(_pkg025));
             pkg025(_pkg025);
           end;
           26:
           begin
             mStr.Read(_pkg026, SizeOf(_pkg026));
             pkg026(_pkg026);
           end;
           27:
           begin
             mStr.Read(_pkg027, SizeOf(_pkg027));
             pkg027(_pkg027);
           end;
         else
           // ID пакета кривой
           Writeln('Wrong ID');
           Exit;
         end;
       end;
       Writeln('Pos ##:', mStr.Position, ' / ', mStr.Size);
       if mStr.Position < mStr.Size then
          begin
            Writeln('Divading ##');
            SetLength(_msg, mStr.Size - mStr.Position);
            mStr.Read(PChar(_msg)^, length(_msg));
            pkgProcess(_msg);  // Он оглянулся посмотреть, не оглянулась ли она...
          end;
  finally
   // writeln(' Oooooops... ');
    mStr.Free;
  end;
end;

procedure pkg000;
var
  mStr   : TMemoryStream;
  _head  : TPackHeader;
  _pkg001: TPkg001;
begin
  mStr := TMemoryStream.Create;

  _head._FLAG:=$f;
  _head._ID  := 1;

  _pkg001.login:= Nonameedit2.Caption;
  _pkg001.pass := md5(Nonameedit3.Caption);

  mStr.Write(_head, sizeof(_head));
  mStr.Write(_pkg001, sizeof(_pkg001));

  TCP.FCon.IterReset;
  TCP.FCon.IterNext;
  TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);

  mStr.Free;
end;

procedure pkg001(pkg: TPkg001);
begin
  if pkg.fail_code = 1 then
     begin
       cns := csChList;
       mWins[17].texts[1].Text:='Loading character list...';
     end
     else
       begin
         TCP.FCon.Disconnect(false);
         mWins[17].texts[1].Text:='Wrong login or password.';
       end;
end;

procedure pkg002(pkg: TPkg002);
var i: integer;
begin
  if pkg.fail_code > 0 then

  if pkg.fail_code = high(byte) then
     begin
       TCP.FCon.Disconnect(true);
       exit;
     end;

  for i := 1 to 4 do
    begin
      CharList[i].ID:=0;
      CharList[i].raceID:=0;
      CharList[i].Name:='';
      CharList[i].level:=0;
      CharList[i].loc:=0;
    end;

  for i := 1 to pkg.fail_code do
      if pkg.Chars[i].ID > 0 then
         CharList[i] := pkg.Chars[i];
  cns:= csConctd;
  gs := gsCharSelect;
  CharSel_Init;
  mWins[17].visible:=false;
  NonameForm1.Hide;
  fCharMan.Show;
  fCharMan.Move(scr_w / 2 - 150, scr_h - 80);
end;

procedure pkg003(pkg: TPkg003);   // Удалить персонажа
begin
  if pkg.fail_code = 2 then
     begin
       fDelChar.Hide;
       DelCharMode := false;
       NonameEdit35.Caption := '';
       CharSel_Init;
       gui.ShowMessage(ERC[13], ERB[13]);
     end else
       gui.ShowMessage(ERC[18], ERC[19]);
end;

procedure pkg004(pkg: TPkg004);
begin
  if pkg.fail_code = 2 then
     begin
       gui.ShowMessage(ERC[11], ERB[11]);
       fCharMake.Hide;
       fCharMan.Show;
       CreateCharMode := false;
       mWins[3].visible:=false;
       CharSel_Init;
     end else
       gui.ShowMessage(ERC[12], ERB[12]);
end;

procedure pkg005(pkg: TPkg005);
begin
  if pkg.fail_code = high(word) then
     TCP.FCon.Disconnect(false) else
  begin
    //ActiveChar := CharList[gSI];
    tutorial := activechar.tutorial;
    LoadLoc(activechar.header.loc);
      // SendData(inline_PkgCompile(27, activechar.Name + '`'));
      // sleep(50);
      // SendData(inline_PkgCompile(26, activechar.Name + '`'));
      // взяли данные активного чара со списка (лишний раз не гоняем туда-сюда)
  end;
end;

procedure pkg010(pkg: TPkg010);
begin
  activechar.hpmp := pkg.data;
end;

procedure pkg011(pkg: TPkg011);
begin
  activechar.Numbers := pkg.data;
  block_btn := false;
end;

procedure pkg012(pkg: TPkg012);
begin
  activechar.Stats := pkg.data;
  writeln(pkg.data.DMG, ' ', pkg.data.APH);
end;

procedure pkg013(pkg: TPkg013);
var i: integer;
begin
  activechar.Inv := pkg.data;

  for i := 1 to high(mWins[5].dnds) do
    begin
    //  Writeln( activechar.Inv[i].iID, ', ', activechar.Inv[i].sub, ', ', activechar.Inv[i].cDur );
      mWins[5].dnds[i].data.contain := activechar.Inv[i].iID;
      mWins[5].dnds[i].data.dur:= activechar.Inv[i].cDur;
    end;
end;

procedure pkg014(pkg: TPkg014);
begin
  if pkg.fail_code <> high(byte) then
     begin
        items[pkg.data.ID].data := pkg.data;
        items[pkg.data.ID].exist:= true;

       { Writeln(pkg.data.ID);
        Writeln(pkg.data.name);  }
     end else
       Writeln('PKG 014: Fail code 255');
  In_Request := false;
end;

procedure pkg015(pkg: TPkg015);
begin
  activechar.header := pkg.data;
end;

procedure pkg016(pkg: TPkg016);
var i, j : integer;
begin
  for i := 0 to 6 do
    for j := 1 to 25 do
      begin
        write(pkg.data[i][j]);
        skills[i * 25 + j].rank := pkg.data[i][j];
      end;
end;

procedure pkg025(pkg: TPkg025);
begin
  writeln('FROM ::: ' ,pkg._from);
  Chat_AddMessage( pkg.channel, pkg._from, pkg.msg );
end;

procedure pkg026(pkg: TPkg026);   // Member list
var i, n : integer;
begin
  if pkg.channel = 0 then ch_tabs[0].Members := pkg.members;

  {for i := 2 to high(ch_tabs[0].members) do
    begin
      ch_tabs[0].Members[i].exist:=true;
      ch_tabs[0].Members[i].Nick:='Noob'+u_IntToStr(random(123));
      ch_tabs[0].Members[i].level:=i;
    end;        }

  n := 0;
  for i := 0 to high(ch_tabs[0].Members) do
      if ch_tabs[0].Members[i].exist then
         inc(n);
  ch_tabs[0].nMem := n;

  if pkg.channel = 1 then ch_tabs[1].Members := pkg.members;
  n := 0;
  for i := 0 to high(ch_tabs[1].Members) do
      if ch_tabs[1].Members[i].exist then
         inc(n);
  ch_tabs[1].nMem := n;
end;

procedure pkg027(pkg: TPkg027);
var i, j : integer;
begin
  Writeln(pkg.fail_code);
  Writeln(pkg._who);
  writeln(pkg.name);

  if pkg.fail_code = 1 then Exit;
  for i := 1 to high(wholist) do
      if wholist[i].id = 0 then
      begin
         wholist[i].id:= pkg._who;
         wholist[i].name:= pkg.name;
      end;

  for i := 0 to high(ch_tabs) do
    for j := 0 to high(ch_tabs[i].msgs) do
      if ch_tabs[i].msgs[j].exist then
        if ch_tabs[i].msgs[j].sender = '' then
           ch_tabs[i].msgs[j].sender:= DoWho(ch_tabs[i].msgs[j].sendID);
end;

end.

{procedure pkgProcess(var msg : string);
var pkg : string;
begin
  if msg = '' then exit;
  repeat
    pkg := pkgDivade(msg);
    pkgParse(pkg);
  until pkg = 'BREAK';
  pkgParse(msg);
end;

procedure pkgExecute(pack : TPackage);
begin
  if pack.pkID = high(word) then exit;
end;   }

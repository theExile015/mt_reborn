unit uPkgProcessor;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  sysutils,
  Classes,
  uVar,
  uAdd,
  uCharSelect,
  uLocalization,
  zglHeader,
  DOS;

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

  TPkg017 = record
    data  : array [1..50] of boolean;
    fail_code : byte;
  end;

  TPkg018 = record
    data : TLocData;
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

  TPkg028 = record
    _to, _time: word;
    fail_code : byte;
  end;

  TPkg029 = record
    data : array [1..16] of integer;
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

  TPkg032 = record
    id : word;
    data : TLocObjData;
    fail_code : byte;
  end;

  TPkg040 = record
    id : dword;
    fail_code : byte;
  end;

  TPkg041 = record
    ID, pic : dword;
    name : string[30];
    descr: String[200];
    data : array [1..10] of TDialogData;
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
    round     : word;
    fail_code : byte;
  end;

  TPkg101 = record
    list      : array [0..20] of TUnitHeader;
    fail_code : byte;
  end;

  TPkg102 = record
    comID           : DWORD;
    uType, uLID     : DWORD;
    what            : byte;
    fail_code       : byte;
  end;

  TPkg103 = record
    uType, uLID    : DWORD;
    data           : TUnitData;
    vdata          : TUnitVisualData;
    fail_code      : byte;
  end;

  TPkg104 = record
    ceRound : word;
    fail_code : byte;
  end;

  TPkg105 = record
    NextTurn : word;
    fail_code : byte;
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
procedure pkg017(pkg: TPkg017);   // Map Locs
procedure pkg018(pkg: TPkg018);   // Map Locs  Data



procedure pkg025(pkg: TPkg025);   // Chat msg
procedure pkg026(pkg: TPkg026);   // Member list
procedure pkg027(pkg: TPkg027);   // Who request
procedure pkg028(pkg: TPkg028);   // Who request
procedure pkg029(pkg: TPkg029);   // loc objs

procedure pkg032(pkg: TPkg032);   // obj data


procedure pkg041(pkg: TPkg041);   // dialog data
procedure pkg042(pkg: TPkg042);   // q data

procedure pkg044(pkg: TPkg044);   // NEW

procedure pkg100(pkg: TPkg100);   // Enter Combat
procedure pkg101(pkg: TPkg101);   // Combat Units

procedure pkg103(pkg: TPkg103);   // Unit Data
procedure pkg104(pkg: TPkg104);   // Next round
procedure pkg105(pkg: TPkg105);   // Next turn

procedure pkgProcess(var msg: string);

{procedure pkgProcess(var msg : string);
procedure pkgExecute(pack : TPackage); }

implementation

uses
  uNetCore, u_MM_gui, uLoader, uChat, uXClick, uLocation, uCombatManager;

procedure pkgProcess(var msg: string);
var
    _msg   : string;
    head   : TPackHeader;
    mStr   : TMemoryStream;
    _pkg001: TPkg001;   _pkg002: TPkg002;   _pkg003: TPkg003;
    _pkg004: TPkg004;   _pkg005: TPkg005;

    _pkg010: TPkg010;   _pkg011: TPkg011;   _pkg012: TPkg012;
    _pkg013: TPkg013;   _pkg014: TPkg014;   _pkg015: TPkg015;
    _pkg016: TPkg016;   _pkg017: TPkg017;   _pkg018: TPkg018;

    _pkg025: TPkg025;   _pkg026: TPkg026;   _pkg027: TPkg027;
    _pkg028: TPkg028;   _pkg029: TPkg029;
                        _pkg032: TPkg032;

                        _pkg041: TPkg041;   _pkg042: TPkg042;
                        _pkg044: TPkg044;

    _pkg100: Tpkg100;   _pkg101: TPkg101;
    _pkg103: TPkg103;   _pkg104: TPkg104;   _pkg105: TPkg105;
begin
  try
       begin
        // writeln('Pkg ##:', msg);
         //writeln('Size ##:', length(msg));
         mStr := TMemoryStream.Create;
         mStr.Write(msg[1], length(msg));       // загружаем эти данные в поток

         mStr.Position:=0;                      // выставляем каретку на 0
         mStr.Read(head, sizeof(head));         // читаем заголовок

         if head._FLAG <> $f then Exit;         // если заголовок "битый" прерываем дальнейшие действия
         if head._ID <> 10 then Writeln('Pack ##:', head._ID);
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
           17:
           begin
             mStr.Read(_pkg017, SizeOf(_pkg017));
             pkg017(_pkg017);
           end;
           18:
           begin
             mStr.Read(_pkg018, SizeOf(_pkg018));
             pkg018(_pkg018);
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
           28:
           begin
             mStr.Read(_pkg028, SizeOf(_pkg028));
             pkg028(_pkg028);
           end;
           29:
           begin
             mStr.Read(_pkg029, SizeOf(_pkg029));
             pkg029(_pkg029);
           end;
           32:
           begin
             mStr.Read(_pkg032, SizeOf(_pkg032));
             pkg032(_pkg032);
           end;
           41:
           begin
             mStr.Read(_pkg041, SizeOf(_pkg041));
             pkg041(_pkg041);
           end;
           42:
           begin
             mStr.Read(_pkg042, SizeOf(_pkg042));
             pkg042(_pkg042);
           end;
           44:
           begin
             mStr.Read(_pkg044, SizeOf(_pkg044));
             pkg044(_pkg044);
           end;
           100:
           begin
             mStr.Read(_pkg100, SizeOf(_pkg100));
             pkg100(_pkg100);
           end;
           101:
           begin
             mStr.Read(_pkg101, SizeOf(_pkg101));
             pkg101(_pkg101);
           end;
           103:
           begin
             mStr.Read(_pkg103, SizeOf(_pkg103));
             pkg103(_pkg103);
           end;
           104:
           begin
             mStr.Read(_pkg104, SizeOf(_pkg104));
             pkg104(_pkg104);
           end;
           105:
           begin
             mStr.Read(_pkg105, SizeOf(_pkg105));
             pkg105(_pkg105);
           end;
         else
           // ID пакета кривой
           Writeln('Wrong ID');
           Exit;
         end;
       end;
       // Writeln('Pos ##:', mStr.Position, ' / ', mStr.Size);
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
  for i := 1 to 4 do
    Writeln(CharList[i].tutorial);
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
var
  _head : TPackHeader; _pkg029: TPkg029;
  mStr  : TMemoryStream;
  hh, mm, ss, ms : word;
begin
  writeln('WORLD ENTERED!');
  if pkg.fail_code = high(byte) then
     TCP.FCon.Disconnect(false) else
  begin
    ActiveChar.header := CharList[gSI];
    tutorial := activechar.header.tutorial;
    sleep(50);

    LoadComplete();

    wait_for_05 := 255;
    GetTime(hh, mm, ss, ms);
    wait_for_29 := ss;
    Writeln('Wait for 29 = ', wait_for_29);

    if tutorial < 2 then
       begin
         DoDlgClick(26);
         sleep(50);
       end;

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
                                // защита от кривых пакетов
  for i := 1 to high(activechar.Inv) do
    if not (activechar.Inv[i].iID in [1..1000]) then
       begin
         activechar.Inv[i].iID := 0;
         activechar.Inv[i].gID := 0;
         activechar.Inv[i].cDur:= 0;
       end;

  for i := 1 to high(mWins[5].dnds) do
    begin
    //  Writeln( activechar.Inv[i].iID, ', ', activechar.Inv[i].sub, ', ', activechar.Inv[i].cDur );
      mWins[5].dnds[i].data.contain := activechar.Inv[i].iID;
      mWins[5].dnds[i].data.dur:= activechar.Inv[i].cDur;
    end;
  in_request := false;
end;

procedure pkg014(pkg: TPkg014);
begin
  if pkg.fail_code <> high(byte) then
     begin
        items[pkg.data.ID].data := pkg.data;
        items[pkg.data.ID].exist:= true;
        items[pkg.data.ID].req  := false;
      { Writeln(pkg.data.ID);
        Writeln(pkg.data.name);  }
     end else
       Writeln('PKG 014: Fail code 255');
  In_Request := false;
  SaveItemCache();
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

procedure pkg017(pkg: TPkg017);
var i: integer;
begin
  for i := 1 to high(locs) do
     locs[i].exist:=false;

  for i := 1 to high(pkg.data) do
      locs[i].exist := pkg.data[i];
end;

procedure pkg018(pkg: TPkg018);
var i: word;
begin
  i := pkg.data.id;
  locs[i].data := pkg.data;
  SaveLocCache();
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

procedure pkg027(pkg: TPkg027);   // who is it&
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

procedure pkg028(pkg: TPkg028);
var hh, mm, ss, ms : word;
    _pkg029 : TPkg029; _head : TPackHeader;
    mStr : TMemoryStream;
begin
  if pkg.fail_code = 0 then Exit;
  if pkg.fail_code = 1 then
  begin
    trvlDest := pkg._to;
    // trvlScreen := tex_LoadFromFile('Data\forest_road.jpg');
    iga := igaTravel;
    igs := igsNone;
    trvlText := locs[trvlDest].data.name;
    GetTime(hh, mm, ss, ms);
    trvlMin := mm;
    trvlSec := ss;
    trvlTime:= pkg._time;
    fInGame.Hide;
  end;

  if pkg.fail_code = 255 then
  begin
    if pkg._to <= 0 then exit;
    activechar.header.loc := pkg._to;
    //SetLength(layer, 0);
    LoadLoc(activechar.header.loc);
    fInGame.Show;

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
end;

procedure pkg029(pkg: TPkg029);   // loc objs
var i: integer;
begin
try
  objMan_HideAll();

  wait_for_29 := 255;

  if pkg.fail_code < 1 then Writeln('Fail code ## ', pkg.fail_code) else
  for i := 1 to pkg.fail_code do
    begin
      writeln(pkg.data[i]);
      objStore[pkg.data[i]].visible := true;
      objStore[pkg.data[i]].exist   := true;
      if objStore[pkg.data[i]].Data.tID = 0 then
         begin
           DoRequestObj(i);
           sleep(50);
         end;
    end;

  iga := igaLoc;

except
  writeln('Range error desu');
end;

end;

procedure pkg032(pkg: TPkg032);   // loc objs
begin
try
  objStore[pkg.id].Data := pkg.data;

  SaveObjCache();

  writeln('tID ## ', objstore[pkg.id].Data.tID);
     objStore[pkg.id].cCircle := Circle(objStore[pkg.id].Data.x + objStore[pkg.id].Data.w / 2,
                                        objStore[pkg.id].Data.y + objStore[pkg.id].Data.h / 2,
                                        objStore[pkg.id].Data.h / 2);

     objStore[pkg.id].a_fr := objStore[pkg.id].Data.animation;
     objStore[pkg.id].c_fr := 1;
     if objStore[pkg.id].a_fr > 0 then
        objStore[pkg.id].anim := True;
  objStore[pkg.id].request:=false;
  //scr_Flush;
except
  Writeln('obj data failed');
end;
end;

procedure pkg041(pkg: TPkg041);   // dialog data
var i, k: integer;
begin
  mWins[7].texts[1].Text   := pkg.name;
  mWins[7].texts[2].Text   := pkg.descr;
  mWins[7].imgs[1].maskID  := 0;
  mWins[7].imgs[1].texID   := 'qp' + u_IntToStr(pkg.pic);

  for i := 1 to high(mWins[7].dlgs) do
    mWins[7].dlgs[i].exist := false;

  k := 1;
  writeln('Fail ## :', pkg.fail_code);
  if pkg.fail_code > 0 then
  for i := 1 to pkg.fail_code do
    if pkg.data[i].dID > 0 then
       begin
         Writeln(i, ' >> ', pkg.data[i].dID );
         mWins[7].dlgs[i].exist:=true;
         mWins[7].dlgs[i].data := pkg.data[i];
         mWins[7].dlgs[i].dy:= 260 + k * 20;
         Writeln('Dlg ## ', i , ' :: ', mWins[7].dlgs[i].data.text);
         inc(k);
       end;

  mWins[7].dlgs[k].exist:=true;
  mWins[7].dlgs[k].data.dID := 0;
  mWins[7].dlgs[k].data.dType := 12;
  mWins[7].dlgs[k].data.text := string('Пройти мимо.');
  mWins[7].dlgs[k].dy := 260 + k * 20;

  Writeln(mWins[7].texts[1].Text);
  Writeln(mWins[7].texts[2].Text);

  igs := igsNPC;
  mWins[7].visible:=true;
end;

procedure pkg042(pkg: TPkg042);   // q data
var i : integer;
begin
  mWins[7].visible:=false;

  if tutorial = 0 then
     begin
       Writeln('Tutorial >>>>>>> 1');
       tutorial := 1;
       DoSendTutorial( 1 );
       mWins[8].btns[1].enabled := false;
     end;

  for i := 1 to 10 do
      begin
        mWins[8].dnds[i].data.contain:=0;
        mWins[8].dnds[i].data.dur:=0;
      end;
  writeln(pkg.descr);
  writeln(pkg.descr2);

  mWins[8].Name := IntToStr(pkg.qID);
  mWins[8].texts[1].Text := pkg.name;
  mWins[8].texts[3].Text := string(pkg.descr) + string(pkg.descr2) + string(pkg.descr3) ;

  if pkg.fail_code = 11 then
     begin
       mWins[8].texts[5].Text:=pkg.obj;
       mWins[8].texts[4].visible:=true;
       mWins[8].texts[5].visible:=true;
       mWins[8].flag := pkg.fail_code;
     end else
     begin
       mWins[8].texts[4].visible:=false;
       mWins[8].texts[5].visible:=false;
       mWins[8].flag := pkg.fail_code;
     end;

  if pkg.fail_code = 11 then
     begin
       mWins[8].imgs[1].texID:='qp'+u_IntToStr(pkg.spic);
       mWins[8].imgs[1].maskID:=pkg.smask;
     end;

  if pkg.reward[1] > 0 then
     begin
       mWins[8].dnds[1].data.contain:=1000;
       mWins[8].dnds[1].data.dur:= pkg.reward[1];
     end;

  if pkg.reward[2] > 0 then
     begin
       mWins[8].dnds[2].data.contain := 999;
       mWins[8].dnds[2].data.dur := pkg.reward[2];
     end;

  for i := 3 to 10 do
      if pkg.reward[i * 2 - 3] <> 0 then
         begin
           mWins[8].dnds[i].data.contain:=pkg.reward[i * 2 - 3];
           mWins[8].dnds[i].data.dur:=pkg.reward[i * 2 - 2];
         end;

  for i := 3 to 10 do
    if mWins[8].dnds[i].data.contain > 0 then
      if not items[mWins[8].dnds[i].data.contain].exist then
        if not items[mWins[8].dnds[i].data.contain].req then
          begin
            items[mWins[8].dnds[i].data.contain].req := true;
            DoItemRequest(mWins[8].dnds[i].data.contain);
            sleep(50);
          end;


  // Заблокировать кнопку "отмена" для первого квеста.
  if (activechar.header.tutorial = 1) or
     (activechar.header.tutorial = 4) then mWins[8].btns[1].enabled:=false;

  igs := igsNPC;
  gs  := gsGame;
  mWins[8].visible:=true;
end;

procedure pkg044(pkg: TPkg044);   // NEW
begin
  case pkg._what of
    0: Chat_AddMessage(ch_tab_curr, high(word), 'You earn ' + IntToStr(pkg._num) + ' experience.');
    1: Chat_AddMessage(ch_tab_curr, high(word), 'You earn ' + IntToStr(pkg._num) + ' gold.');
    2: Chat_AddMessage(ch_tab_curr, high(word), 'You have reached ' + IntToStr(pkg._num) + ' level.');
    3: Chat_AddMessage(ch_tab_curr, high(word), 'You earn ' + IntToStr(pkg._num) + ' stat points.');
    4: Chat_AddMessage(ch_tab_curr, high(word), 'You earn ' + IntToStr(pkg._num) + ' perk points.');
    5: Chat_AddMessage(ch_tab_curr, high(word), 'You recieved ' + '{!:' + IntToStr(pkg._num) + ':0:0:' + Items[pkg._num].data.name + '}{ ' );
  else
    Writeln('IDK what to add.');
  end;
end;

procedure pkg100(pkg: TPkg100);   // enter combat
begin
  Combat_Init;
  sleep(50);
  Chat_AddMessage(3, high(word), 'You joined battle #' + IntToStr(pkg.ID) );
  combat_id  := pkg.ID;
  curr_round := pkg.round;

  NonameFrame41.Move(scr_w - 120, scr_h - 190);
  NonameFrame41.Show;

  gs  := gsCLoad;
  iga := igaCombat;
end;

procedure pkg101(pkg: TPkg101);   // Combat Units
var i : integer; f : boolean;
    hh, mm, ss, ms : word;
begin
  for i := 0 to high(pkg.list) do
    if pkg.list[i].exist then
       begin
         units[i].exist:=pkg.list[i].exist;
         units[i].name :=pkg.list[i].Name;
         Writeln('Unit ', units[i].name, ' added in slot ', i);
         units[i].uType:=pkg.list[i].uType;
         //writeln(units[i].uType);
         units[i].uLID  :=pkg.list[i].uLID;
         //writeln(units[i].uLID);
         DoRequestUnit(units[i].uLID, units[i].uType, 1);
         sleep(20);
         f := true;
         if units[i].uType = 1 then
           if units[i].name = activechar.header.Name then
              your_unit := i;
       end;
  if f then
    begin
      GetTime(hh, mm, ss, ms);
      wait_for_103 := ss;
    end;
end;

procedure pkg103(pkg: TPkg103);
var I : integer;
begin
  wait_for_103 := 255;
  for i := 0 to high(units) do
    if units[i].exist then
    if units[i].uType = pkg.uType then
    if units[i].uLID = pkg.uLID then
       begin
         units[i].visible := true;
         units[i].complex := true;
         units[i].alive   := true;
         units[i].ani     := 0;
         units[i].fTargetPos := pkg.data.pos;
         units[i].data    := pkg.data;
         units[i].VData   := pkg.vdata;
         Writeln('Unit ', i, ' x :', units[i].data.pos.x, ' y: ', units[i].data.pos.y);
         exit;
       end;
end;

procedure pkg104(pkg: TPkg104);
begin
  Chat_AddMessage(3, high(word), 'Round ' + IntToStr(pkg.ceRound) + ' started.');
  curr_round := pkg.ceRound;
end;

procedure pkg105(pkg: TPkg105);
var i : Integer;
    hh, mm, ss, ms : word;
begin
  turn_mode := false;
  range_mode := false;
  your_turn := false;

  for i := 0 to high(units) do
    if units[i].exist then
       if (units[i].uLID = pkg.NextTurn) then
          begin
            units[i].turn := true;
            units[i].data.cAP:=units[i].data.mAP;
            GetTime(hh, mm, ss, ms);
            t_mm := mm;
            t_ss := ss;
            curr_turn_name := units[i].name;
            if (units[i].name = ActiveChar.header.Name) and (units[i].uType = 1) then
               begin
                 your_turn := true;
                 your_unit := i;
               end;
            Chat_AddMessage(3, high(word), Units[i].name + ' turn start.' );
          end;

  Map_CreateMask;
  for i := 1 to high(units) do
    if units[i].exist and units[i].alive then
       if (pkg.NextTurn <> units[i].uLID) then
           MapMatrix[units[i].data.pos.x, units[i].data.pos.y].cType := 1;

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

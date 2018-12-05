unit uXClick;

{$mode objfpc}{$H+}

interface

uses
  windows,
  classes,
  zglHeader,
  uVar,
  uLocalization,
  uAdd;

procedure DoLogin();
procedure DoCreateChar();
procedure DoDelete();
procedure DoEnterTheWorld();
procedure SendEnterTheWorld();
procedure DoOpenInv();
procedure DoItemRequest(ID: integer);
procedure DoSwap(_from, _to: byte);

implementation

uses u_MM_gui, uMyGui, uNetCore, uPkgProcessor;

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
       timeout := gettickcount();
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
begin
       _head._FLAG := $f;
       _head._ID   := 5;
       _pkg.id     := charlist[gSI].ID ;

       activechar.header := charlist[gSI];
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
begin
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

procedure DoItemRequest(ID: integer);
var _pkg  : TPkg014;
    _head : TPackHeader;
    mStr  : TMemoryStream;
begin
       _head._FLAG := $f;
       _head._ID   := 14;
       _pkg.data.ID := ID;

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

end.


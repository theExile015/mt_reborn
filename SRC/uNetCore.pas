unit uNetCore;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  lnet,
  zglHeader,
  uVar,
  uPkgProcessor;

{const
   S_ADDRESS = '151.80.40.97';
   S_PORT    = 11112;  }

type

TLTCPTest = class
 private
 {  these are all events which happen on our server connection. They are called inside CallAction
    OnEr gets fired when a network error occurs.
    OnRe gets fired when any of the server sockets receives new data.
    OnDs gets fired when any of the server sockets disconnects gracefully.
 }
  procedure OnDs(aSocket: TLSocket);
  procedure OnRe(aSocket: TLSocket);
  procedure OnEr(const msg: string; aSocket: TLSocket);
 public
  FCon     : TLTcp; // the connection
  FConnect : boolean;
  attempt  : word;
  constructor Create;
  destructor Destroy; override;
  procedure Run;
  procedure Process;
end;

var
  TCP: TLTCPTest;

implementation

uses u_MM_gui;

procedure TLTCPTest.OnDs(aSocket: TLSocket);
var i : integer;
begin
  gs  := gsMMenu;
  igs := igsNone;
  cns := csOnDisc;
  iga := igaLoc;

  for i := 1 to 18 do
      mWins[i].visible:=false;

  NonameForm1.Visible:=true;
  fCharMan.Visible:=false;
  fCharMake.Visible:=false;
  fDelChar.Visible:=false;
  NonameFrame38.Visible:=false;
  NonameFrame41.Visible:=false;
  fInGame.Visible:=false;
  pbLoading.Visible:=false;

  snd_Stop(theme2, thID2);
  snd_Stop(theme1, thID1);
  snd_del(theme1);
  snd_del(theme2);
  theme_two := false;
  theme1 := snd_LoadFromFile('Data\Sound\augury.ogg');
  thID1 := snd_Play(theme1, true, 0, 0, 0, ambient_vol);

  TCP.FConnect := false;
  mWins[17].visible := true;
  // mWins[17].texts[1].Text := 'Disconnected.';
  Log_Add('Lost connection');
end;

procedure TLTCPTest.OnRe(aSocket: TLSocket);
var
  msg    : string;
begin
  if aSocket.GetMessage(msg) > 0 then         // читаем всё, что накопилось в буфере
     pkgProcess(msg);
end;

procedure TLTCPTest.OnEr(const msg: string; aSocket: TLSocket);
begin
  writeln(msg); // if error occured, write it
  cns := csDisc;
  mWins[17].texts[1].Text:='Can''t connect with server.';
  TCP.FConnect:=false;
  TCP.FCon.Disconnect(false);
end;

constructor TLTCPTest.Create;
begin
  FCon := TLTCP.Create(nil); // create new TCP connection with no parent component
  FCon.OnError := @OnEr; // assign callbacks
  FCon.OnReceive := @OnRe;
  FCOn.OnDisconnect := @OnDs;
  FCon.Timeout := 100; // responsive enough, but won't hog cpu
end;

destructor TLTCPTest.Destroy;
begin
  FCon.Free; // free the connection
  inherited Destroy;
end;

procedure TLTCPTest.Run;
begin
  FConnect := FCon.Connect(ip1, Port1);
  if not FConnect then inc(attempt) else attempt := 0;
end;

procedure TLTCPTest.Process;
begin
  FCon.CallAction;
end;


end.


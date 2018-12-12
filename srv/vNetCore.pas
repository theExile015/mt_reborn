unit vNetCore;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  cthreads, cmem, Classes, Crt, SysUtils,
  lnet, vVar, dos, vServerLog, uCharManager ;

{ TLTCPTest }

type

TLTCPTest = class
   public
    FCon: TLTCP; // THE server connection
   {  these are all events which happen on our server connection. They are called inside CallAction
      OnEr gets fired when a network error occurs.
      OnAc gets fired when a new connection is accepted on the server socket.
      OnRe gets fired when any of the server sockets receives new data.
      OnDs gets fired when any of the server sockets disconnects gracefully.
   }
    procedure OnEr(const msg: string; aSocket: TLSocket);
    procedure OnAc(aSocket: TLSocket);
    procedure OnRe(aSocket: TLSocket);
    procedure OnDs(aSocket: TLSocket);
 //  public
    constructor Create;
    destructor Destroy; override;
    procedure Run; // main loop with CallAction
  end;


var
  TCP: TLTCPTest;
implementation

uses
  uPkgProcessor, uChatManager;

procedure TLTCPTest.OnEr(const msg: string; aSocket: TLSocket);
begin
  WriteSafeText(msg, 3);  // if error occured, write it explicitly
end;

procedure TLTCPTest.OnAc(aSocket: TLSocket);
var
  i : integer;
  head : TPackHeader;
begin
  WriteSafeText('Connection accepted from ' + aSocket.PeerAddress, 2); // on accept, write whom we accepted
  WriteSafeText('Peer address : ' + aSocket.PeerAddress, 2);
  WriteSafeText('Peer port : ' + IntToStr(aSocket.PeerPort), 2);
  WriteSafeText('Local address : ' + aSocket.LocalAddress, 2);
  WriteSafeText('Local port : ' + IntToStr(aSocket.LocalPort), 2);

  // Ищем, есть ли свободные сессии
  for i := 0 to high(sessions) do
      if not sessions[i].exist then
         begin
           if i = high(sessions) then exit; // последний слот не занимаем

           sessions[i].exist:=true;
           sessions[i].ip:=aSocket.PeerAddress;
           sessions[i].lport:=aSocket.LocalPort;

           // Отправляем нулевой пакет, подтвержая, что мы получили коннект
           head._flag:=$F;
           head._id:=0;
           FCon.Send(head, sizeof(head), aSocket);

           break;
         end;

  //if i = high(sessions) then // все места заняты, отправляем отказ
end;

procedure TLTCPTest.OnRe(aSocket: TLSocket);
var
  i, sID  : integer;
  msg     : string;
  mStr    : TMemoryStream;
  _head   : TPackHeader;
  _pkg001 : TPkg001;                        _pkg003: TPkg003;
  _pkg004 : TPkg004;   _pkg005 : TPkg005;

  _pkg010 : TPkg010;   _pkg011 : TPkg011;   _pkg012: TPkg012;
  _pkg013 : TPkg013;   _pkg014 : TPkg014;
  _pkg016 : TPkg016;   _pkg017 : TPkg017;   _pkg018: TPkg018;
                       _pkg020 : TPkg020;

  _pkg025 : TPkg025;   _pkg026 : TPkg026;   _pkg027: Tpkg027;
  _pkg028 : TPkg028;
  _pkg030 : TPkg030;   _pkg031 : TPkg031;
begin
try
  mStr := TMemoryStream.Create;
  if aSocket.GetMessage(msg) > 0 then
     begin
       writeln(msg);
       mStr.Write(msg[1], length(msg));
       mStr.Position:=0;
       mStr.Read(_head, SizeOf(_head));

       if _head._flag <> $f then Exit;

       // Теперь ищем сессию, с которой работаем
       sID := -1;
       for i := 0 to high(sessions) do
           if sessions[i].ip = aSocket.PeerAddress then
              if sessions[i].lport = aSocket.LocalPort then
                 begin
                   sID := i;
                   break;
                 end;
       if sID < 0 then exit;

       Writeln('Pack ##:', _head._id );

       case _head._id of
         1:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg001, SizeOf(_pkg001));
           pkg001(_pkg001, sID);
         end;

         3:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg003, SizeOf(_pkg003));
           pkg003(_pkg003, sID);
         end;
         4:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg004, SizeOf(_pkg004));
           pkg004(_pkg004, sID);
         end;
         5:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg005, SizeOf(_pkg005));
           pkg005(_pkg005, sID);
         end;

         10:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg010, SizeOf(_pkg010));
           pkg010(_pkg010, sID);
         end;
         11:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg011, SizeOf(_pkg011));
           pkg011(_pkg011, sID);
         end;
         12:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg012, SizeOf(_pkg012));
           pkg012(_pkg012, sID);
         end;
         13:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg013, SizeOf(_pkg013));
           pkg013(_pkg013, sID);
         end;
         14:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg014, SizeOf(_pkg014));
           pkg014(_pkg014, sID);
         end;
         16:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg016, SizeOf(_pkg016));
           pkg016(_pkg016, sID);
         end;
         17:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg017, SizeOf(_pkg017));
           pkg017(_pkg017, sID);
         end;
         18:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg018, SizeOf(_pkg018));
           pkg018(_pkg018, sID);
         end;
         20:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg020, SizeOf(_pkg020));
           pkg020(_pkg020, sID);
         end;
         25:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg025, SizeOf(_pkg025));
           pkg025(_pkg025, sID);
         end;
         26:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg026, SizeOf(_pkg026));
           pkg026(_pkg026, sID);
         end;
         27:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg027, SizeOf(_pkg027));
           pkg027(_pkg027, sID);
         end;
         28:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg028, SizeOf(_pkg028));
           pkg028(_pkg028, sID);
         end;
         30:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg030, SizeOf(_pkg030));
           pkg030(_pkg030, sID);
         end;
         31:
         begin
           mStr.Position:=SizeOf(_head);
           mStr.Read(_pkg031, SizeOf(_pkg031));
           pkg031(_pkg031, sID);
         end;
       else
         Writeln('Wrong ID');
         Exit;
       end;
     end;
finally
  mStr.Free;
end;
end;

procedure TLTCPTest.OnDs(aSocket: TLSocket);
var i: integer;
begin
  for i := 0 to high(sessions) do
      if sessions[i].exist then
      if aSocket.PeerAddress = sessions[i].ip then
      if aSocket.LocalPort = sessions[i].lport then
         begin
           chars[sessions[i].charLID].exist := false; // отрубаем персонажа
           sessions[i].exist:=false;
           sessions[i].aID:=0;
           sessions[i].lport:=0;
           sessions[i].ip:='';
           break;
         end;
  WriteSafeText('Lost connection ' + aSocket.PeerAddress, 2); // write info if connection was lost

  for i := 0 to high(chars) do
    if chars[i].exist then
       Chat_GetMembersList(1, chars[i].header.loc, chars[i].sID);
end;

constructor TLTCPTest.Create;
begin
  FCon := TLTCP.Create(nil); // create new TCP connection
  FCon.OnError := @OnEr;     // assign all callbacks
  FCon.OnReceive := @OnRe;
  FCon.OnDisconnect := @OnDs;
  FCon.OnAccept := @OnAc;
  FCon.Timeout := 10; // responsive enough, but won't hog cpu
  FCon.ReuseAddress := True;
end;

destructor TLTCPTest.Destroy;
begin
  FCon.Free; // free the TCP connection
  inherited Destroy;
end;

procedure TLTCPTest.Run;
var
  Quit: Boolean; // main loop control
  hour, min, sec, hsec : word;
begin
  Quit:= false;
  if FCon.Listen(11112) then begin // if listen went ok
      WriteSafeText('Server running!', 2);
      Writeln('Press ''escape'' to quit.');
      repeat
        FCon.CallAction; // eventize the lNet
        if Keypressed then // if user provided input
          case readkey of
           #27: quit := true; // if he pressed "escape" then quit
          end;
        Char_Update(); // проверяем персонажа на лвл ап, ауры итд
        GetTime(hour, min, sec, hsec);
        if abs(min * 60 + sec - (lpMin * 60 + lpSec)) >= 5 then          // пробрасываем пинг
           begin
                Char_RegEvent();
                lpMin := min;
                lpSec := sec;
           end;
      until Quit; // until user quit
    end; // listen
end;

end.


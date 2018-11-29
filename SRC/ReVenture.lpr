program ReVenture;

{$mode objfpc}{$H+}
{$codepage utf8}
{$I zglCustomConfig.cfg}
{.$APPTYPE GUI}

uses
 sysutils,
 Classes,
 zglHeader,
 uNetCore,
 uMain,
 uVar,
 uLUA,
 uPkgProcessor,
 uParser,
 uLoader,
 uLocation,
 uXClick, uCombatManager
 ;

{$R *.res}

procedure Init;
begin
  TCP := TLTCPTest.Create;
  Game_Init;
  // wnd_SetPos(0, 0);
end;

procedure Draw;
begin
  Game_Render;
end;

procedure Loader;
begin
  LoadMainData();
  LoadCombatData();
  LoadLocData();
end;

procedure Timer;
begin
  if TCP.FConnect then
     TCP.Process;

  Game_Update;

  video_Update( video, 25, TRUE );
  Gui.Update(12);

  key_ClearState();
  mouse_ClearState();
end;

procedure Exit;
begin
  Game_Free;
end;

Begin
try
  if not zglLoad( libZenGL ) Then exit;

  zgl_Disable(APP_USE_AUTOPAUSE);

  randomize();
  InitLUA;
  Game_PreInit;

  timer_Add( @Timer,      20 );
  timer_Add( @Loader,     20 );
  zgl_Reg( SYS_LOAD,   @Init );
  zgl_Reg( SYS_DRAW,   @Draw );
  zgl_Reg( SYS_EXIT,   @Exit );

  wnd_SetCaption( 'Re:Venture ');
  wnd_ShowCursor(false);

  scr_SetOptions( scr_w, scr_h, REFRESH_MAXIMUM, f_scr, FALSE );

  zgl_Init();
  zgl_Exit();
except
  on E : Exception do
     Log_Add('Core exeption: ' + e.Message + ' ' + e.ToString);
end;
end.


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
 uLoader;

{$R *.res}

procedure Init;
begin
  TCP := TLTCPTest.Create;
  Game_Init;
  wnd_SetPos(trunc(Zgl_Get(DESKTOP_WIDTH)/2 - scr_w/2), trunc(Zgl_Get(DESKTOP_HEIGHT)/2 - scr_h/2));
end;

procedure Draw;
begin
  Game_Render;
  SSprite2d_Draw( tex_Cursors[cur_type], mouse_x() - 2, mouse_y() - 3, 32, 32, cur_angle);

//  SSprite2d_Draw( texZero, 10, 10, 20, 20, 0);

  Text_Draw( fntMain, scr_w - 50, scr_h - 20, u_IntToStr(zgl_Get(RENDER_FPS)) );
  Text_Draw( fntMain, scr_w - 50, scr_h - 40, u_IntToStr(zgl_Get(RENDER_BATCHES_2D)) );
  //Text_Draw( fntMain, scr_w - 80, scr_h - 60, u_IntToStr(zgl_Get(RENDER_VRAM_USED)) );
end;

procedure Loader;
begin
  LoadMainData();
end;

procedure Timer;
begin
  if TCP.FConnect then
     TCP.Process;

  LoadCombatData();
  LoadLocData();

  Game_Update;

  video_Update( video, 25, TRUE );
  Gui.Update(12);

  if Key_Press(K_F11) then RunLUAScript('gui.lua');

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
  //  DestinyMode := true;
  zgl_Disable(APP_USE_AUTOPAUSE);

  randomize();
  InitLUA;
  Game_PreInit;

  timer_Add( @Timer,      20 );
  timer_Add( @Loader,     20 );
  zgl_Reg( SYS_LOAD,   @Init );
  zgl_Reg( SYS_DRAW,   @Draw );
  zgl_Reg( SYS_EXIT,   @Exit );

  wnd_SetCaption( 'Re:Venture' );
  wnd_ShowCursor(false);

  scr_SetOptions( scr_w, scr_h, REFRESH_MAXIMUM, f_scr, FALSE );

  zgl_Init();
  zgl_Exit();
except
  on E : Exception do
     Log_Add('Core exeption: ' + e.Message + ' ' + e.ToString);
end;
end.


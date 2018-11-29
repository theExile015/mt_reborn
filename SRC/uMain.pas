unit uMain;

{$mode delphi}{$H+}

interface

uses
  windows,
  zglHeader,
  u_MM_GUI,
  uVar,
  uLoader,
  uMyGui,
  uLocalization,
  uLUA,
  uNetCore,
  sysutils,
  uAdd,
  uTileMap,
  uCharSelect,
  uChat,
  uLocation,
  uSkillFl,
  uCombatManager;

procedure Game_PreInit;
procedure Game_Init;
procedure Game_Free;
procedure Game_Render;
procedure Game_Update;

implementation

procedure Game_PreInit;
begin
    // грузим ини файл
  ini_LoadFromFile('gameini.ini');

  scr_w := ini_ReadKeyInt('SCREEN', 'WIDTH');
  scr_h := ini_ReadKeyInt('SCREEN', 'HEIGHT');
  f_scr := ini_ReadKeyBool('SCREEN', 'FULLSCREEN');

  if scr_w < 1024 then scr_w := 1024;
  if scr_h < 594  then scr_h := 594 ;

  Port1 := ini_ReadKeyInt('NET', 'PORT');
  IP1   := PChar(_ini_ReadKeyStr('NET', 'IP'));

  login := ini_ReadKeyStr('LOGIN', 'ACC');
  pass  := ini_ReadKeyStr('LOGIN', 'PASS');

  ini_free();
end;

procedure Game_Init;
begin
  cam2d_Init( zglCam1 );
  cam2d_Init( zglCam2 );

  scaleXY := scr_W / 1920;

  zglCam1.Zoom.X:= ScaleXY;
  zglCam1.Zoom.Y:= ScaleXY;
  zglCam1.X := (1920 - scr_w) / 2;
  zglCam1.Y := (1080 - scr_h) / 2;

  LoadBaseData(); // Базовая загрузка
  InitGui(gui);   // Инициируем гуй из плагина
  mGUI_Init;
  SF_Init();
  DestSel_Init();
  {
    В общем, после редактирования интерфеса его элементы имеют свойство
    терять некоторые параметры, поэтому для перестраховки добавляю
    тут дополнительное присвоение значений наиболее критичных из них.
  }
  NoNameEdit2.MaxLength := 20;
  NoNameEdit3.MaxLength := 20;
  NoNameEdit3.PasswordChar := '*';

  NonameFrame38.Hide;
  NonameFrame38.Move(15, scr_h - 170);
  NonameFrame38.Resize(scr_w - 30, 20);
  bChatSend.Move(scr_w - 30 - 50, 0);
  eChatFrame.Resize(scr_w - 30 - 50, 20);

  eCharName.MaxLength := 20;
  fCharMake.Hide;
  fDelChar.Hide;
  fCharMan.Hide;
  fCharMake.MoveToCenter;
  Nonameform1.Move(scr_w / 2 - nonameform1.Rect.W / 2, scr_h - nonameform1.Rect.H);
  NonameFrame41.Hide;
  fInGame.Hide;
  fLoading.Hide;

  // Загружаем скрипты
  RunLUAScript('list.lua');
  RunLUAScript('gui.lua');

  // устанавливаем локализацию
  SetLocalization(locEn);
  // выставляем EN раскладку
  LoadKeyboardLayout('00000409', 1);

  Nonameedit2.Caption:=login;
  Nonameedit3.Caption:=pass;
end;

procedure Game_Free;
begin
  Gui.Free;
end;

procedure Game_Render;
begin
  if iga = igaCombat then
     begin
       if abs(fCam_x - zglCam1.X) > 0 then zglCam1.X:= zglCam1.X + (fCam_x - zglCam1.X) / 20;
       if abs(fCam_y - zglCam1.y) > 0 then zglCam1.y:= zglCam1.y + (fCam_y - zglCam1.y) / 20;
     end else
     begin
       zglCam1.X := (1920 - scr_w) / 2;
       zglCam1.Y := (1080 - scr_h) / 2;
     end;

/// Отрисовка всего в глобальных коррдинатах

  cam2d_Set( @zglCam1 );

  location_draw();
  Combat_Draw();

  pengine2d_Draw();

/// Отрисовка частей, берущих координаты экрана в качестве основы, в частности
/// элементы интерфейса

  cam2d_Set( @zglCam2 );

  if (gs = gsMMenu) or (gs = gsCharSelect) then
     SSprite2d_Draw( video.Texture, 0 , 0 , scr_w, scr_h, 0);


  if gs = gsCharSelect then CharSel_Render();

  if gs = gsPreGame then
  begin
    fx_SetBlendMode(FX_BLEND_ADD);
       SSprite2d_Draw( video.Texture, 0 , 0 , scr_w, scr_h, 0, 255 - a_p * 2);
       SSprite2d_Draw(lScreen, 0, 0, scr_w, scr_h, 0, a_p * 2);
    fx_SetBlendMode(FX_BLEND_NORMAL);
  end;

  if (gs = gsLoad) or (gs = gsCLoad) or (gs = gsLLoad) then
  begin
    SSprite2d_Draw(lScreen, 0, 0, scr_w, scr_h, 0);
  end;

  if gs = gsGame then
     Chat_Draw();

  Combat_GUI_Draw();
  DestSel_Render;
  myGUI_Draw;
  Gui.Draw;
  Console_Draw();
  Gui.DrawMouse;
end;

procedure Game_Update;
begin
  inc(a_p);
  if a_p/2 = a_p div 2 then inc(sc_ani);
  if a_p/2 = a_p div 2 then inc(tut_frame);
  if tut_frame > 30 then tut_frame := 1;
  if a_p > 1000 then a_p := 0;

  // пробуем подключиться
  if cns = csConcting then
     begin
       scr_flush();
       if not TCP.FConnect then
          TCP.Run;
       if TCP.FConnect then
          cns := csAuth
          else
          begin
            cns := csDisc;
            mWins[17].texts[1].Text:='Can''t connect with server.';
          end;
       if GetTickCount() - Timeout > 1000 then
          begin
            cns := csDisc;
            mWins[17].texts[1].Text:='Can''t connect with server.';
            TCP.FConnect:=false;
            TCP.FCon.Disconnect(false);
          end;
     end;

  // Обработка нажатий клавиш
  if gs = gsMMenu then
  begin
    if key_press(K_ENTER) and not con_visible then
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
       timeout := GetTickCount();
       Nonameform1.Enabled:=false;

       ini_LoadFromFile('gameini.ini');

       Ini_WriteKeyStr('LOGIN', 'ACC', Nonameedit2.Caption);
       Ini_WriteKeyStr('LOGIN', 'PASS', Nonameedit3.Caption);

       Ini_SaveToFile('gameini.ini');
       ini_free();
       end;
  end;

  if gs = gsCharSelect then CharSel_Update;

  if gs = gsPreGame then
    begin
    if a_p * 2 > 252 then
       begin
         gs := gsLoad;
         floading.Move(scr_w / 2 - 200, scr_h - 50);
         pbLoading.Progress:=0;
         fLoading.Show;
       end;
  end;

  if gs = gsGame then
     Chat_Update();

  location_Update();
  myGUI_Update;
  SF_Update();
  Combat_Update();
  DestSel_Update();
  Console_Update();
  oMX := Mouse_X;
  oMY := Mouse_Y;
end;

end.


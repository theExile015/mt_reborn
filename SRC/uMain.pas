unit uMain;

{$mode delphi}{$H+}
{$codepage utf8}

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
  uCharSelect,
  uChat,
  uLocation,
  uSkillFl,
  uXClick,
  uCombatManager,
  DOS;

procedure Game_PreInit;
procedure Game_Init;
procedure Game_Free;
procedure Game_Render;
procedure Game_Update;

implementation

uses zglGui;

procedure Game_PreInit;
begin
    // грузим ини файл
  ini_LoadFromFile('gameini.ini');

  scr_w := ini_ReadKeyInt('SCREEN', 'WIDTH');
  scr_h := ini_ReadKeyInt('SCREEN', 'HEIGHT');
  f_scr := ini_ReadKeyBool('SCREEN', 'FULLSCREEN');

  case scr_w of
     960  : scr_h := 540;
     1024 : scr_h := 576;
     1280 : scr_h := 720;
     1366 : scr_h := 768;
     1600 : scr_h := 900;
     1920 : scr_h := 1080;
  else
    scr_w := 960; scr_h := 540;
  end;


  Port1 := ini_ReadKeyInt('NET', 'PORT');
  IP1   := PChar(_ini_ReadKeyStr('NET', 'IP'));

  login := ini_ReadKeyStr('LOGIN', 'ACC');
  pass  := ini_ReadKeyStr('LOGIN', 'PASS');

  ini_free();
end;

procedure Game_Init;
begin
  snd_Init();
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

  wholist[1].id := high(word);
  wholist[1].name := 'Re:';

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
  snd_free();
  Gui.Free;
end;

procedure Game_Render;
var i, t: integer;
    hh, mm, ss, ms : word;
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

  if iga = igaTravel then
     begin
       SSprite2d_Draw( GetTex('trvlScreen'), 0, 0, scr_w, scr_h, 0);
       Text_DrawEx( fntMain, scr_w - 20, 150, 1, 0, 'Пункт назначения:', 255, $ffffff, TEXT_HALIGN_RIGHT );
       Text_DrawEx( fntMain, scr_w - 20, 170, 1, 0, trvlText, 255, $ffffff, TEXT_HALIGN_RIGHT );
       Text_DrawEx( fntMain2, scr_w - 20, 200, 1, 0, 'Прибытие через:', 255, $5e4f21, TEXT_HALIGN_RIGHT );
       GetTime(hh, mm, ss, ms);
       t := trvlTime - abs(trvlMin - mm) * 60 - abs(trvlSec - ss);
       if t < 0 then t := 0;
       Text_DrawEx( fntMain2, scr_w - 20, 220, 1,0, u_IntToStr(t), 255, $5e4f21, TEXT_HALIGN_RIGHT );
       if t = 0 then
          begin

          end;
     end;


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
  //Gui.DrawMouse;
end;

procedure Game_Update;
var i: integer; t: dword;
    hh, mm, ss, ms : word;
begin
  inc(a_p);
  if a_p/2 = a_p div 2 then inc(sc_ani);
  if a_p/2 = a_p div 2 then inc(tut_frame);
  if tut_frame > 30 then tut_frame := 1;
  if a_p > 1000 then a_p := 0;

  if theme_change then
     begin
       inc(theme_scale);
       if theme_Scale = 1 then thID2 := snd_Play(theme2, true, 0, 0, ambient_vol * 0.01 );
       snd_SetVolume(theme2, thID2, ambient_vol * theme_scale / 100);
       snd_SetVolume(theme1, thID1, ambient_vol * (100 - theme_scale) / 100);
       if theme_scale >= 100 then
          begin
            snd_Stop(theme1, thID1);
            theme_change := false;
            theme_scale := 0;
          end;
     end;

  // пробуем подключиться
  if cns = csConcting then
     begin
       Writeln('Attempt to connect');
       scr_flush();

       if not TCP.FConnect then
          begin
            TCP.Run;
            attempt := true;
            GetTime(hh, mm, ss, ms);
            timeout := ss;
          end else Writeln('Already connected.');

       if TCP.FConnect then
          begin
             cns := csAuth;
             attempt := false;
          end else
          begin
            cns := csDisc;
            writeln('TCP.FConnect = false');
            mWins[17].texts[1].Text:='Can''t connect with server.';
          end;

       GetTime(hh, mm, ss, ms);
       if attempt = true then
       if abs(ss - timeout) > 5 then
          begin
            cns := csDisc;
            attempt := false;
            mWins[17].texts[1].Text := 'Timeout error.';
            TCP.FConnect := false;
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
     begin
       if eChatFrame.Gui.Handler.HHandle = heNone then
          ch_message_inp := false;

       if key_press(K_ENTER) then
          if not con_visible then
          if not ch_message_inp then
             begin
               ch_message_inp := true;
               eChatFrame.Focus;
               eChatFrame.SelectAll;
               eChatFrame.DeleteSelection;
             end;

       if not ch_message_inp then
       if not con_visible then
          if key_press(K_I) or key_press(K_B) then
             if igs <> igsInv then
                begin
                  DoOpenInv();
                  igs := igsInv
                end else igs := igsNone;

       if not ch_message_inp then
       if not con_visible then
          if key_press(K_C) then
             if igs <> igsChar then
                begin
                  DoPerkRequest();

                  igs := igsChar;
                end else igs := igsNone;

       Chat_Update();

       if wait_for_29 <> 255 then
          begin
            GetTime(hh, mm, ss, ms);
            if abs(ss - wait_for_29) > 5 then
               DoRequestLocObjs();
          end;
       if wait_for_05 <> 255 then
          begin
            GetTime(hh, mm, ss, ms);
            if abs(ss - wait_for_05) > 5 then
               DoEnterTheWorld();
          end;
     end;

{$R+}
try
  // запрос данных по предметам, при открытии инвентаря
  if igs = igsInv then
     begin
       t := GetTickCount();
       if t / 3000 = t div 3000 then        // снимаем счётчики
       begin
         for i := 1 to high(items) do
             items[i].req := false;
         for i := 1 to high(objstore) do
             objstore[i].request := false;
         in_request := false;
         sleep(20);
       end;

      // writeln(in_request);

       if not in_request then
       for i := 1 to high(mWins[5].dnds) do
           if mWins[5].dnds[i].data.contain > 0 then
           if not items[mWins[5].dnds[i].data.contain].exist then
           if not items[mWins[5].dnds[i].data.contain].req then
              begin
                writeln('tuta');
                items[mWins[5].dnds[i].data.contain].req := true;
                DoItemRequest(mWins[5].dnds[i].data.contain);
                sleep(20);
              end;
     end;
except
  on e: ERangeError do
  begin
  Writeln('ERangeError :: uMain :: in_request ::', mWins[5].dnds[i].data.contain,
        '::', i);
  mWins[5].dnds[i].data.contain := 0;
  end;
end;

  if igs = igsMap then
     begin
       for i := 1 to high(locs) do
           if locs[i].exist then
           if not locs[i].request then
              if locs[i].data.pic = 0 then
                 begin
                   DoRequestLoc(i);
                   Locs[i].request:=true;
                   Sleep(40);
                 end;
     end;

{$R-}
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


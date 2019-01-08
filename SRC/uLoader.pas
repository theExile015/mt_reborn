unit uLoader;
{
    uLoader.pas для проекта MT
    Owl&Mushrooms 05/04/2017
    Модуль содержит в себе процедуры загрузки и выгрузки ресурсов
    для игры.
}
{$mode delphi}
{$codepage utf8}
interface

uses
  uVar,
  zglHeader,
  zglGUI,
  uTileMap,
  uLocation,
  u_MM_GUI,
 // uCombat,
  uChat;
 // uParser;

procedure LoadBaseData();
procedure LoadMainData();
procedure LoadCombatData();
procedure LoadComplete();
procedure LoadLocData();
procedure LoadLoc(ID : word);

function GetTex(name : utf8string) : zglPTexture;
function Find_TexInList(name : utf8string) : word;

implementation

uses uXClick;

// загрузка базовых данных при инициализации игры
procedure LoadBaseData();
var i : integer;
begin
  // нулевая текстура
  texZero := tex_LoadFromFile( dirSys + 'zeroTex.png');

  snd_gui[1] := snd_LoadFromFile('Data\Sound\click.ogg');
  snd_gui[2] := snd_LoadFromFile('Data\Sound\drag_onmousedown.ogg');
  snd_gui[3] := snd_LoadFromFile('Data\Sound\drag_onmouseup.ogg');
  snd_gui[4] := snd_LoadFromFile('Data\Sound\snare.ogg');
  snd_gui[5] := snd_LoadFromFile('Data\Sound\glassbell.ogg');

  // шрифты
  if file_OpenArchive('Data\fonts.red') then
     begin
       fntMain := font_LoadFromFile( 'font_1.zfi' );
       fntMain2:= font_LoadFromFile( 'font_2.zfi' );
       fntCombat := font_LoadFromFile( 'combat.zfi');
       fntChat := font_LoadFromFile( 'chat2.zfi' );
     end else
     begin
       Writeln('Can''t open archive fonts.red');
       MessageBoxA( 0, 'Re: client seem to be broken.', 'Error', $00000010 );
     end;
  file_CloseArchive();
  // GUI
  gSkin := zglTGuiSkin.Create('Data\main.skin');
  Gui := zglTGui.Create(gSkin, 0, 0, scr_w, scr_h,
  zglTFontContainer.Create(
      zglTFontObject.Create(fntMain, 1, $E6D690, 255),
      zglTFontObject.Create(fntMain, 1, $E6D690, 255),
      zglTFontObject.Create(fntMain, 1, $E6D690, 128)
    ));
  // анимациая первого экрана
  video := video_OpenFile( 'Data\giphy.ogv' );

  if file_OpenArchive('Data\UI.red') then
     begin
       // подгрузка скинов гуя
       for i := 1 to 3 do
         begin
           frmPak[i].brd:= tex_LoadFromFile( 'frm_brd' + u_IntToStr(i) + '.png');
           frmPak[i].crn:= tex_LoadFromFile( 'frm_crn' + u_IntToStr(i) + '.png');
           frmPak[i].w:=frmPak[i].brd.Width;
           frmPak[i].h:=frmPak[i].brd.Height;
           frmPak[i].c:=frmPak[i].crn.Width;
         end;
       for i := 2 to 14 do
           tex_IBtn[i] := tex_LoadFromFile('b' + u_IntToStr(i) + '.tga');

       tex_AddBtn := tex_LoadFromFile( 'ch_plus.png');
       tex_ChBkgr := tex_LoadFromFile( 'ch_bkgr.png');
       tex_Btn    := tex_LoadFromFile( 'btn1.png');

        // подгрузка элементов прогресс-бара
        tex_PBar[1]      := tex_LoadFromFile( 'ProgressBarBorder.png');
        tex_PBar[2]      := tex_LoadFromFile( 'ProgressBarBorder1.png');
        tex_PBar[3]      := tex_LoadFromFile( 'ProgressBarFiller.png');
        tex_PBar[4]      := tex_LoadFromFile( 'ProgressBarFiller1.png');
        // Стрелочка-указатель для туториала
        tex_Arr_Point    := tex_LoadFromFile( 'Arrow_pointer2.png');
        tex_SetFrameSize(tex_Arr_Point, 64, 64);

        tex_item_slots   := tex_LoadFromFile('item_slots.png');
        tex_SetFrameSize(tex_item_slots, tex_item_slots.Width div 6, tex_item_slots.Width div 6);
        tex_Skills       := tex_LoadFromFile('skillflower.png');

        tex_ui_scr_arr   := tex_LoadFromFile( 'scroll_arr.png');
        tex_SetFrameSize(tex_ui_scr_arr, 39, 29);
        tex_ui_scr_bod   := tex_LoadFromFile( 'scroll_bod.png');
        tex_ui_scr_spot  := tex_LoadFromFile( 'scroll_spot.png');
        tex_SetFrameSize(tex_ui_scr_spot, 31, 31);

        tex_ATB          := tex_LoadFromFile( 'Ini bar1.tga');
        tex_ATB_Rect     := tex_LoadFromFile( 'Ini bar unit1.tga');
        tex_WMap         := tex_LoadFromFile( 'world_map.png');
        tex_map_locs     := tex_LoadFromFile( 'MapLocs.png');
        tex_SetFrameSize(tex_map_locs, 64, 64);
        tex_Belt         := tex_LoadFromFile( 'belt.png');
        tex_Chest        := tex_LoadFromFile( 'chest.png');
        tex_glow         := tex_LoadFromFile( 'glowbox.png');
        tex_SetFrameSize(tex_map_spot, 32, 32);

        // Загрузка курсоров
        for i := 1 to 5 do
            tex_Cursors[i] := tex_LoadFromFile( 'cr_main' + u_IntToStr(i) +'.png' );
     end else
     begin
       Writeln('Can''t open archive UI.red');
       MessageBoxA( 0, 'Re: client seem to be broken.', 'Error', $00000010 );
     end;
  file_CloseArchive();

  tex_ChMask := tex_LoadFromFile( dirSys + 'mask0.png');

  lScreen := tex_LoadFromFile( dirRes + 'Back03.jpg' );

//------------------------------------------------
  for i := 2 to 14 do
      Tex_SetFrameSize( tex_IBtn[i], 16, 16);
  Tex_SetFrameSize( tex_Btn, 24, 24 );

  theme1 := snd_LoadFromFile('Data\Sound\augury.ogg');
  thID1 := snd_Play(theme1, true, 0, 0, 0, ambient_vol);
end;

procedure LoadMainData();
var i, j: integer;
begin
  if gs <> gsLoad then Exit;
  if lVProgress < lProgress then inc(lVProgress);
// блок первый - удаление ненужных ресурсов, подготовка массивов
  if lVProgress = 0 then
    begin
      lProgress := 20;
      objMan_Clear;
      objMan_Fill;

      // video_Del(video);

   {   //  ЧАСТИЦЫ ДЛЯ ЗАКЛИНАНИЙ ИТП
      em_Test := emitter2d_LoadFromFile('Data\fx\em_recovery.zei');
      em_test.Params.Position.X:=0;
      em_test.Params.Position.Y:=0;
      em_test.Params.Loop:=false;

      fx_pr[1] :=  emitter2d_LoadFromFile('Data\fx\em_recovery.zei');
      fx_pr[1].Params.Position.X:=0;
      fx_pr[1].Params.Position.Y:=0;
      fx_pr[1].Params.Loop:=false;

      fx_pr[2] :=  emitter2d_LoadFromFile('Data\fx\em_frostbolt.zei');
      fx_pr[2].Params.Position.X:=0;
      fx_pr[2].Params.Position.Y:=0;
      fx_pr[2].Params.Loop:=false;

      fx_pr[3] :=  emitter2d_LoadFromFile('Data\fx\em_magic.zei');
      fx_pr[3].Params.Position.X:=0;
      fx_pr[3].Params.Position.Y:=0;
      fx_pr[3].Params.Loop:=false;

      fx_pr[4] :=  emitter2d_LoadFromFile('Data\fx\em_shot.zei');
      fx_pr[4].Params.Position.X:=0;
      fx_pr[4].Params.Position.Y:=0;
      fx_pr[4].Params.Loop:=false;

      fx_pr[5] :=  emitter2d_LoadFromFile('Data\fx\em_trample.zei');
      fx_pr[5].Params.Position.X:=0;
      fx_pr[5].Params.Position.Y:=0;
      fx_pr[5].Params.Loop:=false;

      fx_pr[6] :=  emitter2d_LoadFromFile('Data\fx\em_poison.zei');
      fx_pr[6].Params.Position.X:=0;
      fx_pr[6].Params.Position.Y:=0;
      fx_pr[6].Params.Loop:=false;

      pengine2d_Set( @particles );}
    end;
// блок второй - загрузка элементов локаций
  if lVProgress = 20 then
    begin
      lProgress := 40;
      loadloc(activechar.header.loc);
      texTiles := tex_LoadFromFile( dirRes + '\maps\tileset_cave_1.png' );
      tex_SetFrameSize( texTiles, 64, 32 );
      texTiles2:= tex_LoadFromFile( dirRes + '\maps\grassland_tiles.png' );
      tex_SetFrameSize( texTiles2, 64, 32);
      texTiles3:= tex_LoadFromFile( dirRes + '\maps\tileset_desert.png' );
      tex_SetFrameSize( texTiles3, 64, 32);
      texTiles4:= tex_LoadFromFile( dirRes + '\maps\wooden_barricade.png' );
      tex_SetFrameSize( texTiles4, 64, 32);

      tex_Objs[1] := tex_LoadFromFile( dirRes + 'Struct\building_1.png' );
      tex_Objs[2] := tex_LoadFromFile( dirRes + 'Struct\building_2.png', $000000 );
      tex_Objs[3] := tex_LoadFromFile( dirRes + 'Struct\monolith_1.png', $0000FF );
      tex_Objs[4] := tex_LoadFromFile( dirRes + 'Struct\npc1.png' );
      tex_SetFrameSize( tex_objs[4], 32, 64);
      tex_Objs[5] := tex_LoadFromFile( dirRes + 'Struct\npc2.png' );
      tex_SetFrameSize( tex_objs[5], 128, 128);
      tex_Objs[6] := tex_LoadFromFile( dirRes + 'Struct\npc3.png' );
      tex_SetFrameSize( tex_objs[6], 32, 64);
      tex_Objs[7] := tex_LoadFromFile( dirRes + 'Struct\npc5.png' );
      tex_Objs[8] := tex_LoadFromFile( dirRes + 'Struct\npc6.png' );
      tex_SetFrameSize( tex_objs[8], 48, 64);
    end;
// блок третий - загрузка текстур боя
    if lVProgress = 40 then
      begin
        lProgress := 60;

        tex_node := tex_LoadFromFile( dirRes + 'node.png');

        if file_OpenArchive('Data\Chars.red') then
           begin

             tex_Units[0, 0].head[1] := tex_loadFromFile( 'male_head1.png' );
             tex_Units[0, 0].body[1] := tex_loadFromFile( 'male_clothes.png');
             tex_Units[0, 0].body[2] := tex_loadFromFile( 'male_leather_armor.png');
             tex_Units[0, 0].body[3] := tex_loadFromFile( 'male_steel_armor.png');
             tex_Units[0, 0].MH[1] := tex_loadFromFile( 'male_dagger.png' );
             tex_Units[0, 0].MH[2] := tex_loadFromFile( 'male_greatstaff.png' );
             tex_Units[0, 0].MH[3] := tex_loadFromFile( 'male_greatsword.png' );
             tex_Units[0, 0].MH[4] := tex_loadFromFile( 'male_shortbow.png' );
             tex_Units[0, 0].MH[5] := tex_loadFromFile( 'male_shortsword.png' );
             tex_Units[0, 0].OH[1] := tex_loadFromFile( 'male_buckler.png' );
             tex_Units[0, 0].OH[2] := tex_loadFromFile( 'male_shield.png' );

             tex_Units[1, 0].head[1] := tex_loadFromFile( 'female_head_long.png' );
             tex_Units[1, 0].body[1] := tex_loadFromFile( 'female_clothes.png');
             tex_Units[1, 0].body[2] := tex_loadFromFile( 'female_leather_armor.png');
             tex_Units[1, 0].body[3] := tex_loadFromFile( 'female_steel_armor.png');
             tex_Units[1, 0].MH[1] := tex_loadFromFile( 'female_dagger.png' );
             tex_Units[1, 0].MH[2] := tex_loadFromFile( 'female_greatstaff.png' );
             tex_Units[1, 0].MH[3] := tex_loadFromFile( 'female_greatsword.png' );
             tex_Units[1, 0].MH[4] := tex_loadFromFile( 'female_shortbow.png' );
             tex_Units[1, 0].MH[5] := tex_loadFromFile( 'female_shortsword.png' );
             tex_Units[1, 0].OH[1] := tex_loadFromFile( 'female_buckler.png' );
             tex_Units[1, 0].OH[2] := tex_loadFromFile( 'female_shield.png' );

             file_CloseArchive();

           end else
               begin
                 Writeln('Can''t open archive Chars.red');
                 MessageBoxA( 0, 'Re: client seem to be broken.', 'Error', $00000010 );
               end;


        tex_setFrameSize( tex_Units[0, 0].head[1], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].body[1], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].body[2], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].body[3], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].MH[1], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].MH[2], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].MH[3], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].MH[4], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].MH[5], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].OH[1], 128, 128);
        tex_setFrameSize( tex_Units[0, 0].OH[2], 128, 128);

        tex_setFrameSize( tex_Units[1, 0].head[1], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].body[1], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].body[2], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].body[3], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].MH[1], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].MH[2], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].MH[3], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].MH[4], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].MH[5], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].OH[1], 128, 128);
        tex_setFrameSize( tex_Units[1, 0].OH[2], 128, 128);
      end;
// блок четвертый - загрузка дополнительных элементов интерфейса
      if lVProgress = 60 then
         begin
           lProgress := 80;
           tex_LocIcons := tex_LoadFromFile( dirSys + 'Icons.png', $ffffff);
           tex_BIcons := tex_LoadFromFile( dirSys + 'BIcons.png', $ff00ff);
           tex_SetFrameSize(tex_LocIcons, 16, 16);
           tex_SetFrameSize(tex_BIcons, 16, 16);

           for i := 1 to 10 do
             begin
               if File_Exists('Data\Sys\mask' + u_IntToStr(i) + '.png') then
                  tex_qMask[i] := tex_LoadFromFile( 'Data\Sys\mask' + u_IntToStr(i) + '.png' );
               if File_Exists('Data\QuestPic\qp' + u_IntToStr(i) + '.png') then
                  tex_qPic[i] := tex_LoadFromFile( 'Data\QuestPic\qp' + u_IntToStr(i) + '.png' );
             end;

           tex_SetMask( tex_qPic[1], tex_qMask[4]);
           tex_SetMask( tex_qPic[2], tex_qMask[1]);
           tex_SetMask( tex_qPic[3], tex_qMask[3]);
         end;

// блок пятый - загрузка иконок
      if lVProgress = 80 then
         begin
           lProgress := 100;
           tex_UnkItem := tex_LoadFromFile('Data\Items\unknown.png');

           theme2 := snd_LoadFromFile('Data\Sound\minstrel.ogg');
         // for i:= 1 to 33 do
         //     for j:= 1 to 50 do
         //         if file_exists('Data\Items\' + u_IntToStr(i) + '\i' + u_IntToStr(j) + '.png') then
         //            tex_Items[i, j] := tex_LoadFromFile('Data\Items\' + u_IntToStr(i) + '\i' + u_IntToStr(j) + '.png');
         end;

// блок шестой перевод игры в активное состояние
      if pbLoading.Progress >= 100 then
         begin
            SendEnterTheWorld();
         end;
   if lVProgress > pbLoading.Progress then
      pbLoading.Progress:=pbLoading.Progress + round((lVProgress - pbLoading.Progress)/3);
   if pbloading.Progress - lVProgress < 3 then pbLoading.Progress:=lVProgress;;

end;

procedure LoadComplete();
begin
  
            Chat_Init();
            Chat_AddTab();  // ГЛОБАЛЬНЫЙ ЧАТ
            Chat_AddTab();  // ЛОКАЛЬНЫЙ ЧАТ
            Chat_AddTab();  // ПРИВАТ
            Chat_AddTab();  // КОМБАТ ЛОГ

            gs := gsLLoad;
            fInGame.Show;
            NonameFrame38.Visible:=true;
            NonameFrame38.Move(10, scr_h - 20);
            NonameFrame38.Resize(scr_w - 210, 20);
            eChatFrame.Resize(scr_w - 260, 20);
            bChatSend.Move(scr_w - 260, 0);
            floading.Hide;
            bInv.Enabled:=true;
            bCharView.Enabled:=true;
            bServants.Enabled:=true;
            bMail.Enabled:=true;
            bMap.Enabled:=true;
       //     mWins[18].visible:=true;

            theme_change := true;
end;

procedure LoadCombatData();
begin
  if gs <> gsCLoad then Exit;
  l_ms := true;
  loadMap( dirRes + '\Maps\battle_map.tmx');
  l_ms := false;
  gs := gsGame;
end;

procedure LoadLocData();
begin
  if gs <> gsLLoad then Exit;
  LoadLoc(activechar.header.loc);
  gs := gsGame;
end;

procedure LoadLoc(ID : word);
begin
  l_ms := true;
  // objMan_HideAll();
  // SendData(inline_pkgCompile(52, u_IntToStr(activechar.ID) + '`' + u_IntToStr(ID) + '`'));
  case id of
    1 : loadMap( dirRes + '\maps\pure_spring3.tmx');
    2 : loadMap( dirRes + '\maps\Eastern_Bridge.tmx');
    3 : loadMap( dirRes + '\maps\robbers_camp.tmx');
    4 : loadMap( dirRes + '\maps\forrest1.tmx');
  end;
 // objMan_Fill;
  l_ms := false;
end;

function GetTex(name : utf8string) : zglPTexture;
var i, n: integer;
begin
  result := texZero;

  for i := 1 to high(tex_man) do
    if tex_man[i].exist then
       if tex_man[i].name = name then
          begin
            result := tex_man[i].tex;
            exit;
          end;
  n := Find_TexInList(name);

  if n > 0 then
  for i := 1 to high(tex_man) do
    if not tex_man[i].exist then
    if file_exists(tex_list[n].path) then
       begin
         tex_man[i].exist:=true;
         tex_man[i].name:=name;
         tex_man[i].tex:= tex_LoadFromFile(tex_list[n].path);
         if (tex_list[n].w <> 0) and (tex_list[n].h <> 0) then
             tex_SetFrameSize(tex_man[i].tex, tex_list[n].w, tex_list[n].h);
         result := tex_man[i].tex;
         //Log_Add( '[dLoad] ' + u_IntToStr(i) + ' >>> ' + name + ' || ' + tex_list[n].path );
         exit;
       end;
end;

function Find_TexInList(name : utf8string) : word;
var i : integer;
begin
  result := 0;
  for i := 1 to high(tex_list) do
    if tex_list[i].exist then
       if tex_list[i].name = name then
          begin
            result := i;
            exit;
          end;
end;

end.


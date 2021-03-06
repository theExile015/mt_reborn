unit uCombatManager;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  sysutils,
  zglHeader,
  uVar,
  uLoader,
  uTileMap,
  u_MM_GUI,
  uAdd,
  dos;

procedure Combat_Init;
procedure Combat_Draw;
procedure Combat_GUI_Draw;
procedure Combat_Update;
procedure Combat_GUI_Update;

procedure Unit_Update(id : integer);
procedure Unit_Draw(id : integer);

function  cm_SetDir( sX, sY, fX, fY : word ) : byte;
procedure cm_ClearUnit( uLID : byte);
function  cm_InRange( x, y, rng : byte ): boolean;
function  cm_InRangeOfMove( x, y, rng : byte) : boolean;
function  cm_ShootLine( x, y : byte ) : boolean;
procedure cm_SetDirP( uLID, Dir, ap_left : Longword);

function  cm_CheckEnemyOMO(): byte;
function  cm_CheckFriendOMO(): byte;
function  cm_CheckEnemyInMelee(): byte;

procedure cm_MeleeAtk( uLID, tLID, dmg, die, _spID, i3: longword);
procedure cm_RangeAtk( uLID, tLID, dmg, die, i3 : longword);
procedure cm_TargetSpell( uLID, tLID, dmg, die, _spID, i3 : longword);
procedure cm_RangeMiss( uLID, x,  y : longword);

procedure cm_SetWay( uLID, X, Y, ap_left : Longword);

procedure cm_SendMove( X, Y: byte );
procedure cm_SendDir( dir : byte );
procedure cm_EndTurn( _end : byte);
procedure cm_SendMelee(tLID, skillID : dword);
procedure cm_SendRange(tLID, skillID : dword);
procedure cm_SendSpell(tLID, skillID : dword);
procedure cm_SendSelfSpell(skillID : dword);

procedure cm_AddCombatText( x, y : single; text : utf8string; color, _spID : longword);
procedure cm_CloseCombat();

type
  TUnitQ = record
    id, y : integer;
  end;

implementation

uses
  uXClick, uChat, uPkgProcessor, uNetCore;

procedure Combat_Init;
var i, j : integer;
begin
  Writeln('Combat Init.');
  in_action  := false;
  your_turn  := false;
  close_combat := false;
  icm        := icmNone;
  your_unit  := high(byte);
  focus_unit := -1;
  for i := 1 to high(cText) do
      cText[i].exist:=false;

  for i := 0 to length(units) - 1 do
      begin
        units[i].exist:= false;
        units[i].alive:= false;
        units[i].data.pos.x := 0;
        units[i].data.pos.y := 0;
        units[i].uID := 0;
        units[i].uType := 0;
        units[i].vdata.sex:=0;
        units[i].in_act:=false;
        for j := 1 to high(units[i].auras) do
            begin
              units[i].auras[j].exist  := false;
              units[i].auras[j].id     := 0;
              units[i].auras[j].left   := 0;
              units[i].auras[j].stacks := 0;
              units[i].auras[j].sub    := 0;
            end;
      end;

  Map_CreateMask();
  fCam_X := (1920 - scr_w) / 2;
  fCam_Y := (1080 - scr_h) / 2;
  fInGame.Hide;

  if theme_two then
     begin
       snd_Del(theme1);
       theme1 := snd_LoadFromFile('Data\Sound\close_the_gates.ogg');
       theme_change := true;
     end else
     begin
       snd_Del(theme2);
       theme2 := snd_LoadFromFile('Data\Sound\close_the_gates.ogg');
       theme_change := true;
     end;

  ATB_Grid[1].x :=  5;
  ATB_Grid[1].y :=  5;
  ATB_Grid[1].w := 45;
  ATB_Grid[1].h := 60;
  ATB_Grid[1].omo := false;
  ATB_Grid[1].id  := 0;

  for i := 2 to 10 do
      begin
        ATB_Grid[i].x := 55 + (i - 2) * 35;
        ATB_Grid[i].y :=  5;
        ATB_Grid[i].w := 30;
        ATB_Grid[i].h := 40;
        ATB_Grid[i].omo := false;
        ATB_Grid[i].id  := 0;
      end;
end;

procedure Combat_Draw;
var i, j, k, step_ap : integer;
    x, y : single;
    alpha: byte;
    FX   : DWORD;

    draw_q : array [0..20] of TUnitQ;
    buffer : TUnitQ;
begin

  if iga <> igaCombat then Exit;
  if gs  <> gsGame    then Exit;
//Scissor_Begin(0, 0, scr_w, scr_h, false);
  DrawTiles();

  step_ap  := 5;
  m_omo := false;
  batch2d_Begin();
{  for i := 0 to 20 do
  for j := 0 to 20 do
    text_Draw(fntMain, j * 64 + (19 - i) * 64 + 40,
                       j * 32 - (19 - i) * 32 + 430,
                       IntToStr(mapmatrix[i][j].cType));    }
  for i := 1 to 19 do
      for j := 1 to 19 do
          begin
            x := j * 64 + (19 - i) * 64 ;
            y := j * 32 - (19 - i) * 32  + 400;
// отрисовка поля
            fx2d_SetColor($222222);
            alpha := 100;
            FX := FX_BLEND or FX_COLOR;
            if your_turn and (not in_action) and (icm = icmNone) then
               if cm_InRangeOfMove(i, j, units[your_unit].data.cAP div step_ap) then alpha := 175;

            if your_turn and (icm = icmRange) then
               if cm_InRange(i, j, spR) and InSector(units[your_unit].data.Direct, m_Angle(units[your_unit].data.pos.x, units[your_unit].data.pos.y, i, j))
                  then FX := FX_BLEND or FX_COLOR
                  else FX := FX_BLEND;

            if your_turn and (icm = icmRange) then
                if cm_InRange(i, j, 8) and InSector(units[your_unit].data.Direct, m_Angle(units[your_unit].data.pos.x, units[your_unit].data.pos.y, i, j)) then
                    if cm_shootline(i, j) then fx2d_setcolor($cc0000);


            if your_turn and (icm = icmRotate) then
               if InSector(n_dir, m_Angle(units[your_unit].data.pos.x, units[your_unit].data.pos.y, i, j)) then
                  FX := FX_BLEND or FX_COLOR
               else FX := FX_BLEND;

             fx2d_SetColor($111111);
             ssprite2d_Draw(tex_node, x, y, 128, 64, 0, alpha, FX);

// отрисовка положения курсора
             if (not in_action) then
                begin
                  if  cm_InRangeOfMove(m_x, m_y, trunc(units[your_unit].data.cAP / step_ap)) then
                      fx2d_setcolor($44FF44) else fx2d_SetColor($FF4444);
                  if (mouse_y() < (scr_h - 150)) and
                     (not col2d_PointInRect(mouse_x(), mouse_y(), rect(0, scr_h - 200 + com_face, 200, 50))) then
                        if col2d_PointInCircle( _Mouse_X, _Mouse_Y, circle( x + 64, y + 32, 24 )) then
                           begin
                             ssprite2d_Draw(tex_node, x, y, 128, 64, 0, 175, FX_BLEND or FX_COLOR);
                             m_x := i;
                             m_y := j;
                             m_omo := true;
                           end ;
               end;
          end;
// отрисовка найденого пути
   if your_turn and (not in_action) and (icm = icmNone) then
   if sw_result then
      for k := 0 to high(units[your_unit].Way) - 1 do
          begin
            if cm_InRangeOfMove(units[your_unit].Way[k].x, units[your_unit].Way[k].y, trunc(units[your_unit].data.cAP / step_ap)) then
               fx2d_setcolor($44FF44) else fx2d_SetColor($ff4444);
            x := units[your_unit].Way[k].y * 64 + (19 - units[your_unit].Way[k].x) * 64 ;
            y := units[your_unit].Way[k].y * 32 - (19 - units[your_unit].Way[k].x) * 32  + 400;
            ssprite2d_Draw(tex_node, x, y, 128, 64, 0, 175, FX_BLEND or FX_COLOR);
          end;
  Batch2d_End();

  for i := 0 to high(units) do
      if units[i].exist then
      //   Unit_Draw(i);
         begin
           draw_q[i].id := i;
           draw_q[i].y  := units[i].data.pos.y * 32 - (19 - units[i].data.pos.x) * 32  + 400;
         end else draw_q[i].id := high(units);

  for i := 0 to 19 do
        for j := 0 to 19 - i do
            if draw_q[j].y > draw_q[j+1].y then
            begin
                buffer := draw_q[j];
                draw_q[j] := draw_q[j+1];
                draw_q[j+1] := buffer;
            end;

  for i := 0 to high(draw_q) do
      Unit_Draw(draw_q[i].id);

   // отрисовка комбат текстов
  for i:=1 to high(cText) do
      if cText[i].exist then
         begin
           Text_DrawEx( fntCombat, cText[i].x, cText[i].y, 0.3 / ScaleXY, 1, cText[i].text, trunc(255 - 200 * cText[i].timer/100), cText[i].color);
           if cText[i].spID <> 0 then
              SSprite2d_Draw( GetTex('i33,' + u_IntToStr(Spells[cText[i].spID].iID)), cText[i].x + text_GetWidth(fntCombat, cText[i].text) + 3, cText[i].y - 4, 24, 24, 0, trunc(255 - 200 * cText[i].timer/100));
         end;
//Scissor_End();
end;

procedure Combat_GUI_Draw;
var i, j, k : integer; flag : boolean;
    r : zglTRect;
    color : longword;
    hh, mm, ss, ms, t : word;
begin
  if iga <> igaCombat then Exit;
  if gs  <> gsGame    then Exit;

  for i := 1 to high(ATB_Grid) do
      SSprite2D_Draw( GetTex('ava' + u_IntToStr((units[ATB_Grid[i].id].VData.race - 1) * 2 + units[ATB_Grid[i].id].vdata.sex + 1)),
                              ATB_Grid[i].x, ATB_Grid[i].y, ATB_Grid[i].w, ATB_Grid[i].h, 0);

      GetTime(hh, mm, ss, ms);
      T := 20 - abs(mm * 60 + ss - t_mm * 60 - t_ss);
      if T > 20 then T := 20; if T < 0 then T := 0;

      Text_DrawInRectEx(fntCombat, rect(5, 30, 45, 40), 0.4, 2, u_IntToStr(T), 255, $FFFFFF, TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER);

      Scissor_Begin( 0, 65, 55, 15);
        text_DrawInRectEx(fntMain, rect(0, 65, 55, 15), 0.6, 0, curr_turn_name, 255, $ffffff, TEXT_HALIGN_CENTER );
      Scissor_End;

      k := 0;
      mWins[15].visible:=true;
      for i := 1 to high(mWins[15].dnds) do
          mWins[15].dnds[i].visible:=false;

      for i := 1 to high(units[your_unit].auras) do
          if units[your_unit].auras[i].exist then
          if units[your_unit].auras[i].id < 40 then
             begin
               inc(k);
               mWins[15].dnds[k].visible      := true;
               mWins[15].dnds[k].data.contain := units[your_unit].auras[i].id;
             end;

      mWins[15].pbs[3].visible:=true;
      mWins[15].pbs[4].visible:=true;
      mWins[15].imgs[2].visible:=false;
      mWins[15].imgs[3].visible:=false;
      mWins[15].texts[1].visible:=false;
      mWins[15].texts[2].visible:=false;
      mWins[15].pbs[1].cProg:=units[your_unit].data.cHP;
      mWins[15].pbs[1].mProg:=units[your_unit].data.mHP;
      mWins[15].pbs[2].mProg:=units[your_unit].data.mMP;
      mWins[15].pbs[2].cProg:=units[your_unit].data.cMP;
      mWins[15].pbs[3].mProg:=units[your_unit].data.mAP;
      mWins[15].pbs[3].cProg:=units[your_unit].data.cAP;
      mWins[15].pbs[4].mProg:=100;
      mWins[15].pbs[4].cProg:=units[your_unit].Rage;
      mWins[15].imgs[1].texID:= 'ava' + u_IntToStr((activechar.header.raceID - 1) * 2 + activechar.header.sex + 1);

      for i := 0 to high(units) do
        if units[i].exist then
          if units[i].data.pos.x = m_X then
           if units[i].data.pos.y = m_y then
              begin
                 k := 0;
                 for j := 1 to high(mWins[16].dnds) do
                     mWins[16].dnds[j].visible:=false;

                 for j := 1 to high(units[i].auras) do
                     if units[i].auras[j].exist then
                     if units[i].auras[j].id < 40 then
                        begin
                          inc(k);
                          mWins[16].dnds[k].visible      := true;
                          mWins[16].dnds[k].data.contain := units[i].auras[j].id;
                        end;

                 mWins[16].visible:=true;
                 mWins[16].pbs[1].cProg:=units[i].data.cHP;
                 mWins[16].pbs[1].mProg:=units[i].data.mHP;
                 mWins[16].pbs[2].mProg:=units[i].data.mMP;
                 mWins[16].pbs[2].cProg:=units[i].data.cMP;
                 mWins[16].pbs[3].mProg:=units[i].data.mAP;
                 mWins[16].pbs[3].cProg:=units[i].data.cAP;
                 mWins[16].texts[1].Text:=units[i].name;
                 mWins[16].imgs[1].texID:= 'ava' + u_IntToStr((units[i].VData.race - 1) * 2 + units[i].vdata.sex + 1);
                 flag := true;
              end;

    for i := 1 to 10 do
      if ATB_Grid[i].omo then
         begin
           k := 0;
           for j := 1 to high(mWins[16].dnds) do
               mWins[16].dnds[j].visible:=false;

           for j := 1 to high(units[i].auras) do
               if units[ATB_Grid[i].id].auras[j].exist then
               if units[ATB_Grid[i].id].auras[j].id < 40 then
                  begin
                    inc(k);
                    mWins[16].dnds[k].visible      := true;
                    mWins[16].dnds[k].data.contain := units[ATB_Grid[i].id].auras[j].id;
                  end;

           mWins[16].visible:=true;
           mWins[16].pbs[1].cProg:=units[ATB_Grid[i].id].data.cHP;
           mWins[16].pbs[1].mProg:=units[ATB_Grid[i].id].data.mHP;
           mWins[16].pbs[2].mProg:=units[ATB_Grid[i].id].data.mMP;
           mWins[16].pbs[2].cProg:=units[ATB_Grid[i].id].data.cMP;
           mWins[16].pbs[3].mProg:=units[ATB_Grid[i].id].data.mAP;
           mWins[16].pbs[3].cProg:=units[ATB_Grid[i].id].data.cAP;
           mWins[16].texts[1].Text:=units[ATB_Grid[i].id].name;
           mWins[16].imgs[1].texID:= 'ava' + u_IntToStr((units[ATB_Grid[i].id].VData.race - 1) * 2 + units[ATB_Grid[i].id].vdata.sex + 1);
           flag := true;
         end;

    if focus_unit > -1 then
       begin
         k := 0;
         for j := 1 to high(mWins[16].dnds) do
             mWins[16].dnds[j].visible:=false;

         for j := 1 to high(units[focus_unit].auras) do
             if units[focus_unit].auras[j].exist then
             if units[focus_unit].auras[j].id < 40 then
                begin
                  inc(k);
                  mWins[16].dnds[k].visible      := true;
                  mWins[16].dnds[k].data.contain := units[focus_unit].auras[j].id;
                end;

         mWins[16].visible:=true;
         mWins[16].pbs[1].cProg:=units[focus_unit].data.cHP;
         mWins[16].pbs[1].mProg:=units[focus_unit].data.mHP;
         mWins[16].pbs[2].mProg:=units[focus_unit].data.mMP;
         mWins[16].pbs[2].cProg:=units[focus_unit].data.cMP;
         mWins[16].pbs[3].mProg:=units[focus_unit].data.mAP;
         mWins[16].pbs[3].cProg:=units[focus_unit].data.cAP;
         mWins[16].texts[1].Text:=units[focus_unit].name;
         mWins[16].imgs[1].texID:= 'ava' + u_IntToStr((units[focus_unit].VData.race - 1) * 2 + units[focus_unit].vdata.sex + 1);
         flag := true;
       end;

    if not flag then mWins[16].visible:= false;

    if spID <> 0 then
       SSprite2d_Draw( GetTex('i33,' + u_IntToStr(spells[spID].iID)), mouse_x() + 5, mouse_y() + 5, 24, 24, 0);
end;

procedure Combat_Update;
var i, l, k, n, step_ap : integer;
    hh, mm, ss, ms : word;
    da : integer;
begin
  if iga <> igaCombat then Exit;
  if gs  <> gsGame    then Exit;

  if not in_action then
     if close_combat then
        cm_CloseCombat();

  if your_unit = high(byte) then
     for i := 0 to high(units) do
       if units[i].exist then
       if units[i].name = activechar.header.Name then
       your_unit := i;

{  if not wait_for_103 then
     begin
       for i := 0 to high(units) do
         if units[i].exist then
            DoRequestUnit(units[i].uLID, units[i].uType, 1);
     end;   }

  if your_turn and (not in_action) and (icm = icmNone) then
     sw_result := SearchWay(your_unit, units[your_unit].data.pos.x, units[your_unit].data.pos.y, m_x, m_y );

   // движение камеры
  if mouse_x() < 5 then fCam_X := fCam_X + mouse_x() / 10 - 1;
  if mouse_X() > scr_w - 5 then fCam_X := fCam_X + (mouse_x() - scr_w) / 10 + 1;
  if mouse_y() < 5 then fCam_y := fCam_y + mouse_y() / 10 - 1;
  if mouse_y() > scr_h - 5 then fCam_y := fCam_y + (mouse_y() - scr_h) / 10 + 1;

  if fCam_X < scr_w / 4 then fCam_X := scr_w / 4;
  if fCam_Y < -200 then fCam_Y := -200;
  if fCam_X > scr_w + 200 then fCam_X := scr_w + 200;
  if fCam_Y > scr_h then fCam_Y := scr_h;
// переключение статуса боя
  k := 0; n := 0;
  if in_action then
  for i := 1 to high(units) do
      if units[i].exist and units[i].alive then
         begin
            inc(n);
            if not units[i].in_act then inc(k);
         end;
  if k = n then in_action := false;
// Если не ваш ход, отключаем "режимы
  if not your_turn then
  begin
     icm  := icmNone;
     spID := 0;
     mWins[13].visible := false;
     cur_type  := 1;
     cur_angle := 0;
  end;
// отлетающий текст
  for i := 1 to high(cText) do
      if cText[i].exist then
         begin
            cText[i].y := cText[i].y - 1.5;
            inc(cText[i].Timer);
            if cText[i].Timer > 100 then cText[i].exist:=false;
         end;
// показываем окошко с хинтом
  if (spID <> 0) or (icm <> icmNone) then
     begin
       mWins[13].visible:=true;
       mWins[13].dnds[1].data.contain := spID;
       if Key_Press(k_escape) then
          begin
            spID := 0;
            mWins[13].visible := false;
            cur_type  := 1;
            cur_angle := 0;
          end;
       cur_type := 4;
     end;

 // if m_omo then
  if icm = icmNone then
  begin
    da := cm_CheckEnemyOMO();
  //  writeln(da);
    if spID = 0 then
    if da <> high(byte) then cur_type := 2 else cur_type := 1;
  end;
// ФОКУС ИГРОКА
  if m_Omo then
  if mouse_click(M_BRIGHT) then
     begin
       focus_unit := -1;
       if cm_CheckEnemyOmo <> high(byte) then focus_unit := cm_CheckEnemyOmo();
       if cm_CheckFriendOmo <> high(byte) then focus_unit := cm_CheckFriendOmo();
     end;

// Наводим мышку на игрока
  if m_omo then
  if mouse_click(M_BLEFT) and (icm = icmNone) then
     begin
       if m_X = units[your_unit].data.pos.x then
       if m_Y = units[your_unit].data.pos.y then exit;
       da := cm_CheckEnemyInMelee();
       Chat_AddMessage(3, high(word), 'Tar = ' + u_IntToStr(da));
       if da <> high(byte) then
       if InSector( units[your_unit].data.Direct, m_Angle( units[your_unit].data.pos.x,
                    units[your_unit].data.pos.y, m_X, m_Y ) ) then
          begin
 // мили атака
            if spID = 0 then
               begin
                 if (units[da].alive) then
                 if (units[your_unit].data.cAP >= activechar.Stats.APH) then
                    begin
                      //writeln('YES');
                      cm_SendMelee(da, 0);
                      exit;
                    end else Chat_AddMessage(3, high(word), 'Can''t attack in melee. Not enough AP for attack.' );
               end else
               begin
                 if (units[da].alive) then
                    begin
                      cm_SendMelee(da, spID);
                      spID := 0;
                      mWins[13].visible := false;
                      cur_type  := 1;
                      cur_angle := 0;
                      exit;
                    end else Chat_AddMessage(3, high(word), 'Can''t attack in melee. Not enough AP for attack.' );
                  end;
          end else
       Chat_AddMessage(3, high(word), 'Can''t attack in melee. Wrong direction.' );
     end;

// Если ход игрока
  if (not in_action) and (icm = icmNone) then
     begin
       if m_omo then
       if Mouse_Click(M_BLEFT) and (cm_CheckEnemyOMO = high(byte)) then
          begin
            if sw_result then
               begin
                 step_ap := 5;
           {      if not units[your_unit].visible then
                   begin
                       //step_ap := 9;
                       if skills[71].rank > 0 then
                          step_ap := step_ap + skills[71].xyz[skills[71].rank].X;
                   end; }

                 l := length(units[your_unit].way) - 1;
                 if l < 0 then
                    begin
                       Log_Add(u_IntToStr( l ));
                       exit;
                    end;
                 if MapMatrix[units[your_unit].way[l].x, units[your_unit].way[l].y].cType = 1 then dec(l, 1);
                 if l < 1 then exit;

                 if l * step_ap > units[your_unit].data.cAP then
                    l := units[your_unit].data.cAP div step_ap;
                 if l > 0 then
                    begin
                      if tutorial = 7 then
                         begin
                           tutorial := 8;
                           DoSendTutorial( 8 );
                           sleep(50);
                         end;
                      cm_SendMove(units[your_unit].way[l].x, units[your_unit].way[l].y);
                  end;
                end;
           end;
//  передача хода
       if Key_Press( K_F1 ) and not ch_message_inp then
          begin
            cm_EndTurn( 0 );
            your_turn := false;
          end;
       if Key_Press( K_F2 ) and not ch_message_inp then
       if units[your_unit].data.cAP = units[your_unit].data.mAP then
          begin
            cm_EndTurn( 1 );
            your_turn := false;
          end;
       if Key_Press( K_F3 ) and not ch_message_inp then
          icm := icmRotate;
       if Key_Press( K_F4 ) and not ch_message_inp then
          icm := icmRange;
     end;
//  Отключаем все режимы
  if your_turn then
  if Key_Press( K_ESCAPE ) and not ch_message_inp then
     begin
       icm  := icmNone;
       spID := 0;
     end;
// Режим разворота
  if (icm = icmRotate) then
     begin
       mWins[13].visible:=true;
       mWins[13].dnds[1].data.contain := spID;
       da := round(m_Angle(units[your_unit].data.pos.x,
                           units[your_unit].data.pos.y, m_x, m_y));
       n_dir := round( (360 - da) / 45 ) + 3;
       if n_dir > 7 then n_dir := n_dir - 8;
       if on_CGUI then
          begin
            cur_type  := 1;
            cur_angle := 0;
          end else
          begin
            cur_type  := 5;
            cur_angle := (n_dir - 2) * 45;
          end;
       if mouse_click(M_BLEFT) and (units[your_unit].data.Direct <> n_dir) and (not on_CGUI) then
          begin
            icm := icmNone;
            { TODO 1 -oVeresk -cbug : Добавить проверку на Keep Moving }
            if units[your_unit].data.cAP >= 5 then
               begin
                 cur_type  := 1;
                 cur_angle := 0;
                 mWins[13].visible := false;
                 icm := icmNone;
                 cm_SendDir( n_dir );
                 exit;
               end else chat_addmessage(3, high(word), 'Not enough AP to turn.');
          end;
     end;
// Режим выстрела
  if icm = icmRange then
     begin
       mWins[13].visible:=true;
       mWins[13].dnds[1].data.contain:=spID;
       if spID = 0 then cur_type := 3 else cur_type := 4;
       if mouse_click(M_BLEFT) then
          begin
            da := cm_CheckEnemyOMO();
            //chat_addMessage(3, 's', u_IntToStr(da));
            if da <> high(byte) then
            if cm_inrange(m_X, m_Y, spR) and InSector( units[your_unit].data.Direct,
                                                       m_Angle( units[your_unit].data.pos.x,
                                                       units[your_unit].data.pos.y,
                                                       m_X, m_Y ) ) then
               if spID = 0 then
                  begin
                    if units[your_unit].data.cAP >= activechar.Stats.APH then
                       begin
                         cm_SendRange(da, 0);
                         spID := 0;
                         mWins[13].visible := false;
                         cur_type  := 1;
                         icm := icmNone;
                         cur_angle := 0;
                         exit;
                       end else
                         chat_addMessage(3, high(word), 'Not enough AP for range attack.');
                  end else
                  begin
                  //  writeln('WHOOOT ', spID);
                    cm_SendRange(da, spID);
                    spID := 0;
                    mWins[13].visible := false;
                    cur_type  := 1;
                    icm := icmNone;
                    cur_angle := 0;
                    exit;
                  end;

            da := cm_CheckEnemyOMO();
            chat_addMessage(3, high(word), u_IntToStr(da));
            if da <> high(byte) then
               if cm_inrange(m_X, m_Y, spR) and (InSector( units[your_unit].data.Direct,
                                                           m_Angle( units[your_unit].data.pos.x,
                                                           units[your_unit].data.pos.y,
                                                           m_X, m_Y )) or (da = your_unit) )   then
                  if spID = 5 then
                     begin
                       if units[your_unit].data.cAP >= 24 then
                          begin
                            cm_SendSpell(da, spID);
                            spID := 0;
                            mWins[13].visible := false;
                            cur_type  := 1;
                            icm := icmNone;
                            cur_angle := 0;
                            exit;
                          end else
                            chat_addMessage(3, high(word), 'Not enough AP for spell cast.');
                     end
          end;
     end;
// обработка спецэффектов
  for i := 1 to high(fx) do
     if fx[i].exist then
        begin
          da := round(m_angle(fx[i].x, fx[i].y, fx[i].tx, fx[i].ty));
          fx[i].x:= fx[i].x - fx[i].speed * m_cos(da);
          fx[i].y:= fx[i].y - fx[i].speed * m_sin(da);
          if fx[i].id <> 1 then
          begin
            if not col2d_pointInCircle(fx[i].x, fx[i].y, circle(fx[i].sx, fx[i].sy, 32)) then
                   pengine2d_AddEmitter(fx_pr[fx[i].id], nil, fx[i].x, fx[i].y);
          end else pengine2d_AddEmitter(fx_pr[fx[i].id], nil, fx[i].x, fx[i].y);
          if col2d_pointInCircle(fx[i].x, fx[i].y, circle(fx[i].tx, fx[i].ty, 16)) then fx[i].exist:=false;
        end;
// отрисовка юнитов
  for i := 0 to high(units) do
      Unit_Update(i);

  Combat_GUI_Update;
end;

procedure Combat_GUI_Update;
var i : integer;
begin
  for i := 1 to 10 do
    if col2d_PointInRect( Mouse_X(), Mouse_Y(),
                          rect(ATB_Grid[i].x, ATB_Grid[i].y,
                               ATB_Grid[i].w, ATB_Grid[i].h)) then
       ATB_Grid[i].omo := true else ATB_Grid[i].omo := false;
end;

procedure Unit_Update(id : integer);
var i, f1, f2, asp : integer;
begin
 // if id > high(units) then Writeln(id);
  if id > high(units) then Exit;
  if not units[id].exist then exit;
  if not units[id].alive then
     begin
        // если трупик, то лежим и не дёргаемся
       if not units[id].alive then units[id].ani_frame:= 24 + units[id].data.Direct * 32;
       exit;
     end;

// перемещение
  if units[id].in_act and (units[id].ani = 1) then
     begin
       inc(units[id].WayProg);
       if units[id].WayProg >= 16 then
          begin
            units[id].WayProg:=0;
            inc(units[id].WayPos);
            if units[id].WayPos >= high(units[id].Way) then
               begin
                 units[id].in_act:=false;
                 units[id].ani:=0;
                 units[id].data.pos := units[id].fTargetPos;
               end else
               begin
                 units[id].data.pos := units[id].Way[units[id].waypos];
                 units[id].TargetPos := units[id].Way[units[id].waypos + 1];
                 units[id].data.Direct:=cm_SetDir(units[id].data.pos.x, units[id].data.pos.y,
                                                  units[id].TargetPos.x, units[id].TargetPos.y );
               end;
          end;
     end;

  if not units[id].in_act then
     if units[id].fTargetPos.x <> units[id].data.pos.x then
     if units[id].fTargetPos.y <> units[id].data.pos.y then
        units[id].data.pos := units[id].fTargetPos;

// выставляем параметры аницмации
  if units[id].complex then
  begin
  case units[id].ani of
    0: begin f1 := 1;  f2 := 4;  asp := 8; end;   // стоим 4
    1: begin f1 := 5;  f2 := 12; asp := 4; end;   // бежим 8
    2: begin f1 := 13; f2 := 16; asp := 3; end;   // удар 4
    3: begin f1 := 17; f2 := 18; asp := 6; end;   // блок 2
    4: begin f1 := 19; f2 := 20; asp := 6; end;   // урон 2
    5: begin f1 := 21; f2 := 24; asp := 4; end;   // смерть 4
    6: begin f1 := 25; f2 := 28; asp := 5; end;   // каст 4
    7: begin f1 := 29; f2 := 32; asp := 6; end;   // стрельба 4
  end;
// коррекция на направление
    f1 := f1 + units[id].data.Direct * 32;
    f2 := f2 + units[id].data.Direct * 32;
  end else
  begin
    case units[id].ani of
    0: begin f1 := 1;  f2 := 4;  asp := 8; end;   // стоим 4
    1: begin f1 := 5;  f2 := 12; asp := 4; end;   // бежим 8
    2: begin f1 := 13; f2 := 16; asp := 3; end;   // удар 4
    3: begin f1 := 17; f2 := 18; asp := 6; end;   // урон 2
    5: begin f1 := 19; f2 := 24; asp := 4; end;   // смерть 6
  end;
// коррекция на направление
    f1 := f1 + units[id].data.Direct * 24;
    f2 := f2 + units[id].data.Direct * 24;
  end;

// кадры
  inc(units[id].ani_delay);
  if units[id].ani_delay > asp then
     begin
       units[id].ani_delay:=0;
       if (units[id].ani = 0) then
       begin
         if not units[id].ani_bkwrd then inc(units[id].ani_frame) else dec(units[id].ani_frame);
         if units[id].ani_frame > f2 then
            begin
              units[id].ani_frame:=f2 - 1;
              units[id].ani_bkwrd:=true;
            end;
         if units[id].ani_frame < f1 then
            begin
              units[id].ani_frame:=f1 + 1;
              units[id].ani_bkwrd:=false;
            end;
       end else
       begin
         inc(units[id].ani_frame);
         if units[id].ani_frame > f2 then
            begin
              if (units[id].ani <> 1) and (units[id].ani <> 5) then
                 begin
                   units[id].in_act:=false;
                   units[id].ani:=0;
                 end else
                     units[id].ani_frame:=f1 ;

              if units[id].ani = 5 then
                 begin
                   units[id].ani_frame:=f2;
                   units[id].alive:=false;
                   units[id].in_act:=false;
                   Map_CreateMask;
                   for i := 0 to high(units) do
                       if units[i].exist and units[i].alive then
                          if units[i].uLID <> your_unit then
                             MapMatrix[units[i].data.pos.x, units[i].data.pos.y].cType := 1;
                 end;
            end;
         if units[id].ani_frame < f1 then units[id].ani_frame:=f1;
       end;
     end;
end;

procedure Unit_Draw(id : integer);
var f1, f2, i, n : integer;
    color : longword;
    x, y, x2, y2, w, h: single;
    s : string;
    alpha: byte;
begin
  if id > high(units) then Exit;
  if id < 0 then Exit;
  if not units[id].exist then Exit;
  if not (gs = gsGame) then Exit;

       if units[your_unit].team <> units[id].team then
          if not units[id].visible then exit else alpha := 255;

       if units[your_unit].team = units[id].team then
          if not units[id].visible then alpha := 150 else alpha := 255;

       x := units[id].data.pos.y * 64 + (19 - units[id].data.pos.x) * 64 - 65;
       y := units[id].data.pos.y * 32 - (19 - units[id].data.pos.x) * 32  + 240;

       if units[id].ani = 1 then
          begin
            x2 := units[id].TargetPos.y * 64 + (19 - units[id].TargetPos.x) * 64 - 65 ;
            y2 := units[id].TargetPos.y * 32 - (19 - units[id].TargetPos.x) * 32  + 240;
            x := x + units[id].WayProg / 16 * (x2 - x);
            y := y + units[id].WayProg / 16 * (y2 - y);
          end;

       if units[id].complex then
          begin
            ASprite2d_Draw( tex_Units[units[id].vdata.sex, 0].body[units[id].VData.skinArm], x, y, 256, 256, 0, units[id].ani_frame, alpha );
            ASprite2d_Draw( tex_Units[units[id].vdata.sex, 0].head[1], x, y, 256, 256, 0, units[id].ani_frame, alpha );
            ASprite2d_Draw( tex_Units[units[id].vdata.sex, 0].MH[units[id].VData.skinMH], x, y, 256, 256, 0, units[id].ani_frame, alpha );
            ASprite2d_Draw( tex_Units[units[id].vdata.sex, 0].OH[units[id].VData.skinOH], x, y, 256, 256, 0, units[id].ani_frame, alpha );
          end else
            ASprite2d_Draw( tex_Creatures[1], x, y, 196, 196, 0, units[id].ani_frame, alpha);

       if units[id].team = 2 then color := $aa7777 else color := $7777aa;
       w := text_GetWidth( fntCombat, units[id].name, 1) * 0.7;
       h := text_GetHeight( fntCombat, w, units[id].name, 0.3 / scaleXY, 0);
       //pr2d_Rect(x + 196/2 - w/2 + 400, y, w, h, $222222, 150, PR2D_FILL);
       s := ''; n := 0;
       s := IntToStr(units[id].data.pos.x) + ' ' + IntToStr(units[id].data.pos.y);
       for i := 1 to high(units[id].auras) do
         if units[id].auras[i].exist then
            begin
              if n > 7 then x2 := x + 256 / 2 - 24 * 4 + (n - 8) * 24
                       else x2 := x + 256 / 2 - 24 * 4 + (n) * 24 ;
              if n > 7 then y2 := y - 49 else y2 := y - 25;
              inc(n);

              fx2d_SetColor(aura_data[units[id].auras[i].id].color);
              ASprite2d_Draw( tex_Item_Slots, x2, y2, 24, 24, 0, 6, 190, FX_BLEND or FX_COLOR);
              SSprite2d_Draw(GetTex(aura_data[units[id].auras[i].id].icon), x2, y2, 24, 24, 0, 190);
              if units[id].auras[i].stacks > 0 then
                 Text_DrawInRectEx(fntCombat, rect(x + i * 25, y - 25, 24, 24), 0.2 / scaleXY, 1, u_IntToStr(units[id].auras[i].stacks), 200, $ff0000);
            end;
       Text_DrawInRectEx( fntCombat, rect(x + 256/2 - w/2, y, w, h), 0.3 / scaleXY, 0, units[id].name + '#' + s, 255, color, TEXT_HALIGN_CENTER );
end;

function cm_SetDir( sX, sY, fX, fY : word ) : byte;
begin
  if fX > sX then
     begin
       if fY < sY then result := 0;
       if fY = sY then result := 7;
       if fY > sY then result := 6;
     end;
  if fX < sX then
     begin
       if fY < sY then result := 2;
       if fY = sY then result := 3;
       if fY > sY then result := 4;
     end;
  if fX = sX then
     begin
       if fY < sY then result := 1;
       if fY > sY then result := 5;
     end;
end;

procedure cm_ClearUnit( uLID : byte);
var i: integer;
begin
  Writeln('Clear unit ', uLID);
  i := uLID;
  units[i].exist:= false;
  units[i].alive:= false;
  units[i].data.pos.x := 0;
  units[i].data.pos.y := 0;
  units[i].uID := 0;
  units[i].uType := 0;
  units[i].name := '';
  units[i].vdata.sex:=0;
end;

function cm_InRange( x, y, rng : byte ): boolean;
var r : single;
begin
  result := false;
  r := (sqrt( sqr( units[your_unit].data.pos.x - x ) + sqr( units[your_unit].data.pos.y - y ) ) );
  if r <= rng then result := true;
end;

function cm_InRangeOfMove( x, y, rng : byte) : boolean;
var d : integer;
begin
  result := false;
  d := abs(x - units[your_unit].data.pos.x) + abs( y - units[your_unit].data.pos.y);
  if d <= rng then result := true;
end;

function cm_ShootLine( x, y : byte ) : boolean;
begin
  result := false;
  result := col2d_LineVsCircle( line( units[your_unit].data.pos.x * 64 + 32,
                                      units[your_unit].data.pos.y * 64 + 32,
                                      m_x * 64 + 32, m_y * 64 + 32 ),
                              circle( x * 64 + 32, y * 64 + 32, 32 ) );
end;

function cm_CheckEnemyOMO(): byte;
var i: integer;
begin
  result := high(byte);
  // Log_add( 'Check enemy ' + u_intToStr(result));
  for i := 0 to high(units) do
  if units[i].exist and (units[i].team <> units[your_unit].team) and units[i].alive then
    if units[i].data.pos.x = m_x then
      if units[i].data.pos.y = m_y then
        result := i;
end;

function cm_CheckFriendOMO(): byte;
var i: integer;
begin
  result := high(byte);
  // Log_add( 'Check enemy ' + u_intToStr(result));
  for i := 0 to high(units) do
  if units[i].exist and (units[i].team = units[your_unit].team) and units[i].alive then
    if units[i].data.pos.x = m_x then
      if units[i].data.pos.y = m_y then
        result := i;
end;

function cm_CheckEnemyInMelee(): byte;
var i: integer;
begin
  result := high(byte);
  // Log_add( 'Check enemy ' + u_intToStr(result));
  // Writeln(your_unit);
  for i := 0 to high(units) do
  if units[i].exist and (units[i].team <> units[your_unit].team) then
    if units[i].data.pos.x = m_x then
      if units[i].data.pos.y = m_y then
        if cm_InRange(m_x, m_y, 1) then result := i else
           if (abs(units[i].data.pos.x - units[your_unit].data.pos.x) = 1) and
              (abs(units[i].data.pos.y - units[your_unit].data.pos.y) = 1) then result := i;

end;

procedure cm_SetWay( uLID, X, Y, ap_left : Longword);
var i, j: integer;
begin
  Map_CreateMask;
  for i := 0 to high(units) do
    if units[i].exist and units[i].alive then
       if (uLID <> units[i].uLID) then
           MapMatrix[units[i].data.pos.x, units[i].data.pos.y].cType := 1;

  for i := 0 to high(units) do
    if units[i].exist then
    if (units[i].uLID = uLID) then
       begin
         units[i].TargetPos.X := X;
         units[i].TargetPos.y := Y;
         units[i].fTargetPos := units[i].TargetPos;
         units[i].data.cAP := ap_left;
         sw_result := SearchWay(i, units[i].data.pos.x, units[i].data.pos.y,
                                   units[i].TargetPos.x, units[i].TargetPos.y);

         if not sw_result then exit;

         units[i].in_act := true;
         units[i].WayPos := 0;
         units[i].ani:= 1;
         units[i].WayProg:=0;
         units[i].data.pos := units[i].Way[0];
         units[i].TargetPos := units[i].Way[1];
         units[i].data.Direct:=cm_SetDir(units[i].data.pos.x, units[i].data.pos.y,
                                         units[i].TargetPos.x, units[i].TargetPos.y );

         in_action := true;
         if units[i].visible then
            Chat_AddMessage(3, high(word), Units[i].name + ' moves to node x: ' + u_IntToStr(x) + ', y: ' + u_IntToStr(Y) + '.' );
       end;
end;

procedure cm_SetDirP( uLID, Dir, ap_left : Longword );
var i : integer;
begin
  for i := 0 to high(units) do
    if units[i].exist and units[i].alive and units[i].visible then
    if (units[i].uLID = uLID) then
       begin
         units[i].data.Direct := Dir;
         units[i].data.cAP := ap_left;
         Chat_AddMessage(3, high(word), Units[i].name + ' changes direction.' );
         break;
       end;
end;

procedure cm_MeleeAtk( uLID, tLID, dmg, die, _spID, i3: longword);
var i: integer; n1, n2, spN, _mod : String;   x, y : single;
begin
  if not units[uLID].exist then exit;
  if not units[tLID].exist then exit;

  in_action := true;
  units[uLID].ani := 2;
  units[uLID].ani_frame:= 13 + units[uLID].data.Direct * 32;
  units[uLID].ani_delay := 0;
  units[uLID].in_act := true;
  n1 := units[uLID].name;

  n2 := units[tLID].name;
  units[tLID].ani := 4;
  units[tLID].in_act:=true;
  units[tLID].ani_frame:= 19 + units[tLID].data.Direct * 32;

  if i3 = 0 then _mod := '';
  if i3 = 1 then _mod := ' * MISS * ';
  if i3 = 2 then _mod := ' * DODGE *';
  if i3 = 3 then _mod := ' * BLOCK *';
  if i3 = 10 then _mod := ' * CRIT *';
  if i3 / 10 > 1 then _mod := ' * CRIT * * BLOCK *';

  x := units[uLID].data.pos.y * 64 + (19 - units[uLID].data.pos.x) * 64 - 32 ;
  y := units[uLID].data.pos.y * 32 - (19 - units[uLID].data.pos.x) * 32  + 400;
  cm_AddCombatText(x - 10, y + 100, '-' + u_IntToStr(dmg) + _mod, $CC0000, _spID);

            if _spID = 0 then spN := '' else
               spN := '''s ' + spells[_spID].name;

            if i3 = 0 then
               Chat_AddMessage(3, high(word), n1 + spN + ' hits ' + n2 + ' for ' + u_IntToStr(dmg) + ' damage.' );
            if i3 = 1 then
               Chat_AddMessage(3, high(word), n1 + ' miss' + spN + '.');
            if i3 = 2 then
               Chat_AddMessage(3, high(word), n2 + ' dodge ' + n1 + spN + '.');
            if i3 = 10 then
               Chat_AddMessage(3, high(word), n1 + spN + ' crits ' + n2 + ' for ' + u_IntToStr(dmg) + ' damage.' );
            if i3 / 10 > 1.1 then
               Chat_AddMessage(3, high(word), n2 + ' block ' + n1 + spN + ' crit and got ' + u_IntToStr(dmg) + ' damage.');
            if i3 = 3 then
               Chat_AddMessage(3, high(word), n2 + ' block ' + n1 + spN + ' and got ' + u_IntToStr(dmg) + ' damage.');

            if die = 1 then
               begin
                 Chat_AddMessage(3, high(word), n2 + ' dies.' );
                 units[tLID].ani := 5;
                 units[tLID].ani_frame:= 21 + units[tLID].data.Direct * 32;
                 units[tLID].ani_delay := 0;
                 units[tLID].in_act:=true;
               end;
end;

procedure cm_RangeAtk( uLID, tLID, dmg, die, i3 : longword);
var i: integer; n1, n2, _mod : UTF8String;  x, y: single;
begin
  if not units[uLID].exist then exit;
  if not units[tLID].exist then exit;

         in_action := true;
         units[uLID].in_act:=true;
         units[uLID].ani := 7;
         units[uLID].ani_frame := 29 + units[uLID].data.Direct * 32;
         units[uLID].ani_delay := 0;
         n1 := units[uLID].name;


         n2 := units[tLID].name;
         units[tLID].ani := 4;
         units[tLID].in_act:=true;
         units[tLID].ani_frame:= 19 + units[tLID].data.Direct * 32;

         if i3 = 0 then _mod := '';
         if i3 = 1 then _mod := ' * MISS * ';
         if i3 = 2 then _mod := ' * DODGE *';
         if i3 = 3 then _mod := ' * BLOCK *';
         if i3 = 10 then _mod := ' * CRIT *';
         if i3 / 10 > 1.1 then _mod := ' * CRIT * * BLOCK *';

         x := units[tLID].data.pos.y * 64 + (19 - units[tLID].data.pos.x) * 64 - 32 ;
         y := units[tLID].data.pos.y * 32 - (19 - units[tLID].data.pos.x) * 32  + 400 - 112;
         cm_AddCombatText(x - 10, y + 100, '-' + u_IntToStr(dmg) + _mod, $CC0000, 0);

         if i3 = 0 then
            Chat_AddMessage(3, high(word), n1 + ' shoot ' + n2 + ' for ' + u_IntToStr(dmg) + ' damage.' );
         if i3 = 1 then
            Chat_AddMessage(3, high(word), n1 + '''s shot miss ' + '.');
         if i3 = 2 then
            Chat_AddMessage(3, high(word), n2 + ' dodge ' + n1 + '''s shoot.');
         if i3 = 10 then
            Chat_AddMessage(3, high(word), n1 + ''' shot crits ' + n2 + ' for ' + u_IntToStr(dmg) + ' damage.' );
         if i3 / 10 > 1.1 then
            Chat_AddMessage(3, high(word), n2 + ' block ' + n1 + '''s shot crit and got ' + u_IntToStr(dmg) + ' damage.');
         if i3 = 3 then
            Chat_AddMessage(3, high(word), n2 + ' block ' + n1 + '''s shot and got ' + u_IntToStr(dmg) + ' damage.');

         if die = 1 then
         begin
            Chat_AddMessage(3, high(word), n2 + ' dies.' );
            units[tLID].ani := 5;
            units[tLID].ani_frame:= 21 + units[tLID].data.Direct * 32;
            units[tLID].ani_delay := 0;
            units[tLID].in_act:=true;
         end;
end;

procedure cm_TargetSpell( uLID, tLID, dmg, die, _spID, i3 : longword);
var i, _i: integer; n1, n2, _mod : UTF8String; x, y : single;
begin
  if not units[uLID].exist then exit;
  if not units[tLID].exist then exit;

  for i := 1 to high(fx) do
    if not fx[i].exist then
       begin
         fx[i].exist:=true;
         _i := i;
         fx[i].speed := 7.5;
         case _spID of
           5 : fx[i].id:=1;
           1 : fx[i].id:=3;
           6 : fx[i].id:=2;
           12: fx[i].id:=6;
           4 : fx[i].id:=5;
           0 : fx[i].id:=4;
         else
           fx[i].id:=1;
         end;
         break;
       end;


         in_action := true;
         units[uLID].in_act:=true;
         units[uLID].ani := 6;
         units[uLID].ani_frame := 25 + units[uLID].data.Direct * 32;
         units[uLID].ani_delay := 0;
         fx[_i].sx := units[uLID].data.pos.y * 64 + (19 - units[uLID].data.pos.x) * 64 - 32 + 96;
         fx[_i].sy := units[uLID].data.pos.y * 32 - (19 - units[uLID].data.pos.x) * 32  + 400 - 112 + 96;
         fx[_i].x:= fx[_i].sx;
         fx[_i].y:= fx[_i].sy;
         n1 := units[uLID].name;

         n2 := units[tLID].name;

         if _spID <> 5 then
            begin
              units[tLID].ani := 4;
              units[tLID].in_act:=true;
              units[tLID].ani_frame:= 19 + units[tLID].data.Direct * 32;
            end;

         fx[_i].tx := units[tLID].data.pos.y * 64 + (19 - units[tLID].data.pos.x) * 64 - 32 + 96;
         fx[_i].ty := units[tLID].data.pos.y * 32 - (19 - units[tLID].data.pos.x) * 32  + 400 - 112 + 96;

         x := units[tLID].data.pos.y * 64 + (19 - units[tLID].data.pos.x) * 64 - 32 ;
         y := units[tLID].data.pos.y * 32 - (19 - units[tLID].data.pos.x) * 32  + 400 - 112;

         if i3 = 0 then _mod := '';
         if i3 = 1 then _mod := ' * MISS * ';
         if i3 = 2 then _mod := ' * DODGE *';
         if i3 = 3 then _mod := ' * BLOCK *';
         if i3 = 10 then _mod := ' * CRIT *';
         if i3 / 10 > 1.1 then _mod := ' * CRIT * * BLOCK *';

         if _spID <> 5 then
           cm_AddCombatText(x - 10, y + 100, '-' + u_IntToStr(dmg) + _mod, $5522CC, _spID)
         else
           cm_AddCombatText(x - 10, y + 100, '+' + u_IntToStr(dmg) + _mod, $22CC22, _spID);

         if _spID <> 5 then
            begin
              if i3 = 0 then
                 Chat_AddMessage(3, high(word), n1 + ' hits ' + n2 + ' with ' + Spells[_spID].name + ' for ' + u_IntToStr(dmg) + ' magical damage.' );
              if i3 = 1 then
                 Chat_AddMessage(3, high(word), n1 + ' miss ' + n2 + ' with ' + Spells[_spID].name + '.' );
              if i3 = 2 then
                 Chat_AddMessage(3, high(word), n2 + ' dodge ' + n1 + '''s ' + Spells[_spID].name + '.' );
              if i3 = 3 then
                 Chat_AddMessage(3, high(word), n2 + ' block ' + n1 + '''s ' + Spells[_spID].name + ' and got ' + u_IntToStr(dmg) + ' magical damage.' );
              if i3 = 10 then
                 Chat_AddMessage(3, high(word), n1 + ' crits ' + n2 + ' with ' + Spells[_spID].name + ' for ' + u_IntToStr(dmg) + ' magical damage.' );
              if i3 / 10 > 1.1 then
                 Chat_AddMessage(3, high(word), n2 + ' block ' + n1 + '''s crit with ' + Spells[_spID].name + ' and got ' + u_IntToStr(dmg) + ' magical damage.' );
            end
         else
            Chat_AddMessage(3, high(word), n1 + ' heals ' + n2 + ' with ' + Spells[_spID].name + ' for ' + u_IntToStr(dmg) + '.' ) ;

         if die = 1 then
         begin
            Chat_AddMessage(3, high(word), n2 + ' dies.' );
            units[tLID].ani := 5;
            units[tLID].ani_frame:= 21 + units[tLID].data.Direct * 32;
            units[tLID].ani_delay := 0;
            units[tLID].in_act:=true;
         end;
end;

procedure cm_RangeMiss( uLID, x,  y : longword);
var n1 : UTF8String;
begin
  if not units[uLID].exist then exit;

         in_action := true;
         units[uLID].in_act:=true;
         units[uLID].ani := 7;
         units[uLID].ani_frame := 29 + units[uLID].data.Direct * 32;
         units[uLID].ani_delay := 0;
         n1 := units[uLID].name;
         if x + y = 0 then Chat_AddMessage(3, high(word), n1 + ' miss.' );
end;

procedure cm_SendMove( X, Y: byte );
var
  _pkg : TPkg106; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 106;

  _pkg.comID := combat_id;
  _pkg.uLID  := your_unit;
  _pkg.X     := X;
  _pkg.Y     := Y;
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

procedure cm_EndTurn(_end : byte);
var
  _pkg : TPkg105; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 105;

  _pkg.comID := combat_id;
  _pkg.uLID  := your_unit;
  _pkg.fail_code  := _end;
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

procedure cm_SendDir( dir : byte );
var
  _pkg : TPkg107; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 107;

  _pkg.comID := combat_id;
  _pkg.uLID  := your_unit;
  _pkg.dir   := dir;

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

procedure cm_SendMelee(tLID, skillID : dword);
var
  _pkg : TPkg108; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 108;

  _pkg.comID   := combat_id;
  _pkg.uLID    := your_unit;
  _pkg.skillID := skillID;
  _pkg.tLID    := tLID;

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

procedure cm_SendRange(tLID, skillID : dword);
var
  _pkg : TPkg111; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 111;

  _pkg.comID   := combat_id;
  _pkg.uLID    := your_unit;
  _pkg.skillID := skillID;
  _pkg.tLID    := tLID;

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

procedure cm_SendSpell(tLID, skillID : dword);
var
  _pkg : TPkg112; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 112;

  _pkg.comID   := combat_id;
  _pkg.uLID    := your_unit;
  _pkg.skillID := skillID;
  _pkg.tLID    := tLID;

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

procedure cm_SendSelfSpell(skillID : dword);
var
  _pkg : TPkg114; _head: TPackHeader;
  mStr : TMemoryStream;
begin
  _head._FLAG := $f;
  _head._ID   := 114;

  _pkg.comID   := combat_id;
  _pkg.uLID    := your_unit;
  _pkg.spellID := skillID;

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

procedure cm_AddCombatText( x, y : single; text : utf8string; color, _spID : longword);
var i: integer;
begin
  for i := 1 to high(cText) do
    if not cText[i].exist then
       begin
         cText[i].exist:=true;
         cText[i].x:=x;
         cText[i].y:=y;
         cText[i].text:=text;
         cText[i].color:=color;
         cText[i].timer:=0;
         cText[i].spID:=_spID;
         exit;
       end;
end;

procedure cm_CloseCombat();
begin
  com_face := 50;
  Chat_AddMessage(3, high(word), 'Team ' + IntToStr(Win_Team) + ' win.' );
  Snd_Play(snd_gui[4], false, 0, 0, 0, gui_vol);
  Nonameframe41.Hide;
  fInGame.Show;
  zglCam1.X := (1920 - scr_w) / 2;
  zglCam1.Y := (1080 - scr_h) / 2;
 // cam_x := 0; cam_y := 0;
  gs  := gsLLoad;
  iga := igaLoc;
  igs := igsNone;

  cur_type  := 1;
  cur_angle := 0;

  if theme_two then
     begin
       snd_Del(theme1);
       theme1 := snd_LoadFromFile('Data\Sound\minstrel.ogg');
       theme_change := true;
     end else
     begin
       snd_Del(theme2);
       theme2 := snd_LoadFromFile('Data\Sound\minstrel.ogg');
       theme_change := true;
     end;
end;

end.


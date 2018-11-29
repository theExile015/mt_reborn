unit uCombatManager;

{$mode objfpc}{$H+}

interface

uses
  Classes,
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

procedure Unit_Update(id : integer);
procedure Unit_Draw(id : integer);

function  cm_SetDir( sX, sY, fX, fY : word ) : byte;
procedure cm_ClearUnit( uLID : byte);
function  cm_InRange( x, y, rng : byte ): boolean;
function  cm_InRangeOfMove( x, y, rng : byte) : boolean;
function  cm_ShootLine( x, y : byte ) : boolean;

implementation

procedure Combat_Init;
var i : integer;
begin
  in_action := false;
  your_turn := false;
  range_mode := false;
  turn_mode := false;
  your_unit := 0;
  for i := 1 to high(cText) do
      begin
        cText[i].exist:=false;
      end;

  for i := 1 to high(ATB) do
      begin
        ATB[i].exist:=false;
        ATB[i].name:='';
        nATB[i].exist:=false;
        nATB[i].name := '';
      end;

  for i := 1 to length(units) - 1 do
      begin
        units[i].exist:= false;
        units[i].alive:= false;
        units[i].pos.x := 0;
        units[i].pos.y := 0;
        units[i].uID := 0;
        units[i].uType := 0;
        units[i].sex:=0;
        units[i].in_act:=false;
      end;
  Map_CreateMask();
  fCam_X := (1920 - scr_w) / 2;
  fCam_Y := (1080 - scr_h) / 2;
  fInGame.Hide;
end;

procedure Combat_Draw;
var i, j, k, step_ap : integer;
    x, y : single;
    alpha: byte;
    FX   : DWORD;
begin
  if iga <> igaCombat then Exit;
  if gs  <> gsGame    then Exit;

  DrawTiles();

  step_ap  := 5;
  m_omo := false;

  for i := 1 to 19 do
      for j := 1 to 19 do
          begin
            x := j * 64 + (19 - i) * 64 ;
            y := j * 32 - (19 - i) * 32  + 400;
            // отрисовка поля
            fx2d_SetColor($222222);
            alpha := 100;
            FX := FX_BLEND or FX_COLOR;
            if your_turn and (not in_action) and (not Range_mode) and (not turn_mode) then
               if cm_InRangeOfMove(i, j, units[your_unit].cAP div step_ap) then alpha := 175;

            if your_turn and range_mode then
               if cm_InRange(i, j, spR) and InSector(units[your_unit].Direct, m_Angle(units[your_unit].pos.x, units[your_unit].pos.y, i, j))
                  then FX := FX_BLEND or FX_COLOR
                  else FX := FX_BLEND;

            if your_turn and range_mode then
                if cm_InRange(i, j, 8) and InSector(units[your_unit].Direct, m_Angle(units[your_unit].pos.x, units[your_unit].pos.y, i, j)) then
                    if cm_shootline(i, j) then fx2d_setcolor($cc0000);


            if your_turn and turn_mode then
               if InSector(n_dir, m_Angle(units[your_unit].pos.x, units[your_unit].pos.y, i, j)) then
                  FX := FX_BLEND or FX_COLOR
               else FX := FX_BLEND;

             fx2d_SetColor($111111);
             ssprite2d_Draw(tex_node, x, y, 128, 64, 0, alpha, FX);

             // отрисовка положения курсора
             if (not in_action) then
                begin
                  if  cm_InRangeOfMove(m_x, m_y, trunc(units[your_unit].cAP / step_ap)) then
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

  Unit_Draw(1);
end;

procedure Combat_GUI_Draw;
var i, j, k : integer; flag : boolean;
    r : zglTRect;
    color : longword;
    hh, mm, ss, ms, t : word;
begin
  if iga <> igaCombat then Exit;
  if gs  <> gsGame    then Exit;

  k := 0; flag := false;
  SSprite2d_draw( tex_ATB, 0, 0, 85, 300, 0 );
  for i := 1 to high(ATB) do
  if ATB[i].exist then
     begin
        r.W := 80;
        r.H := 20;
        r.Y := 280 - ATB[i].vATB / 4.8;
        r.X := 5;
        if r.y < 60 then r.y := 60;
      //  pr2d_RECT( r.X, r.Y, r.W, r.H, color, 150, pr2d_FILL);
        SSprite2d_Draw( tex_ATB_Rect, r.X, r.Y, r.W, r.H, 0);
        Scissor_Begin( 5, round(r.Y), 75, 15);
        if ATB[i].Team = 2 then color := $ff9999 else color := $9999ff;
        text_DrawInRectEx( fntMain, rect(r.X + 5, r.Y + 4, r.W - 10, r.H - 7), 0.8, 0,
                           ATB[i].name, 255, color, TEXT_HALIGN_CENTER);
        Scissor_End;
      end;

      GetTime(hh, mm, ss, ms);

      T := 20 - abs(mm * 60 + ss - t_mm * 60 - t_ss);

      if T > 20 then T := 20; if T < 0 then T := 0;

      Text_DrawInRectEx(fntCombat, rect(0, 0, 70, 40), 0.4, 2, u_IntToStr(T), 255, $FFFFFF, TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER);

      Scissor_Begin( 1, 40, 70, 15);
        text_DrawInRectEx(fntMain, rect(1, 40, 70, 15), 0.8, 0, curr_turn_name, 255, $ffffff, TEXT_HALIGN_CENTER );
      Scissor_End;

      mWins[15].visible:=true;
      mWins[15].pbs[3].visible:=true;
      mWins[15].pbs[4].visible:=true;
      mWins[15].imgs[2].visible:=false;
      mWins[15].imgs[3].visible:=false;
      mWins[15].texts[1].visible:=false;
      mWins[15].texts[2].visible:=false;
      mWins[15].pbs[1].cProg:=units[your_unit].cHP;
      mWins[15].pbs[1].mProg:=units[your_unit].mHP;
      mWins[15].pbs[2].mProg:=units[your_unit].mMP;
      mWins[15].pbs[2].cProg:=units[your_unit].cMP;
      mWins[15].pbs[3].mProg:=units[your_unit].mAP;
      mWins[15].pbs[3].cProg:=units[your_unit].cAP;
      mWins[15].pbs[4].mProg:=100;
      mWins[15].pbs[4].cProg:=units[your_unit].Rage;
      mWins[15].imgs[1].texID:= 'ava' + u_IntToStr((activechar.header.raceID - 1) * 2 + activechar.header.sex + 1);

      for i := 1 to high(units) do
        if units[i].exist then
         if units[i].pos.x = m_X then
           if units[i].pos.y = m_y then
              begin
                 mWins[16].visible:=true;
                 mWins[16].pbs[1].cProg:=units[i].cHP;
                 mWins[16].pbs[1].mProg:=units[i].mHP;
                 mWins[16].pbs[2].mProg:=units[i].mMP;
                 mWins[16].pbs[2].cProg:=units[i].cMP;
                 mWins[16].pbs[3].mProg:=units[i].mAP;
                 mWins[16].pbs[3].cProg:=units[i].cAP;
                 mWins[16].texts[1].Text:=units[i].name;
                 mWins[16].imgs[1].texID:= 'ava' + u_IntToStr((units[i].race - 1) * 2 + units[i].sex + 1);
                 flag := true;
              end;

    if not flag then mWins[16].visible:= false;

    if spID <> 0 then
       SSprite2d_Draw( GetTex('i33,' + u_IntToStr(spells[spID].iID)), mouse_x() + 5, mouse_y() + 5, 24, 24, 0);
end;

procedure Combat_Update;
begin
  if iga <> igaCombat then Exit;
  if gs  <> gsGame    then Exit;

   // движение камеры
  if mouse_x() < 0 then fCam_X := fCam_X + mouse_x() / 10 - 1;
  if mouse_X() > scr_w then fCam_X := fCam_X + (mouse_x() - scr_w) / 10 + 1;
  if mouse_y() < 0 then fCam_y := fCam_y + mouse_y() / 10 - 1;
  if mouse_y() > scr_h then fCam_y := fCam_y + (mouse_y() - scr_h) / 10 + 1;

  if fCam_X < scr_w / 4 then fCam_X := scr_w / 4;
  if fCam_Y < 0 then fCam_Y := 0;
  if fCam_X > scr_w then fCam_X := scr_w;
  if fCam_Y > scr_h then fCam_Y := scr_h;

  Unit_Update(1);
end;

procedure Unit_Update(id : integer);
var i, f1, f2, asp : integer;
begin
  if not units[id].exist then exit;
  if not units[id].alive then
     begin
        // если трупик, то лежим и не дёргаемся
       if not units[id].alive then units[id].ani_frame:= 24 + units[id].Direct * 32;
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
                 units[id].pos := units[id].fTargetPos;
               end else
               begin
                 units[id].pos := units[id].Way[units[id].waypos];
                 units[id].TargetPos := units[id].Way[units[id].waypos + 1];
                 units[id].Direct:=cm_SetDir(units[id].pos.x, units[id].pos.y,
                                             units[id].TargetPos.x, units[id].TargetPos.y );
               end;
          end;
     end;

  if not units[id].in_act then
     if units[id].fTargetPos.x <> units[id].pos.y then units[id].pos := units[id].fTargetPos;

  // выставляем параметры аницмации
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
  f1 := f1 + units[id].Direct * 32;
  f2 := f2 + units[id].Direct * 32;
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
                  { Map_CreateMask;
                   for i := 1 to high(units) do
                       if units[i].exist and units[i].alive then
                          if i <> your_unit then
                             MapMatrix[units[i].pos.x, units[id].pos.y].cType := 1;  }
                 end;
            end;
         if units[id].ani_frame < f1 then units[id].ani_frame:=f1;
       end;
     end;
end;

procedure Unit_Draw(id : integer);
var f1, f2, i : integer;
    color : longword;
    x, y, x2, y2, w, h: single;
    s : string;
    alpha: byte;
begin
  if not units[id].exist then Exit;
  if not (gs = gsGame) then Exit;

  if units[id].exist then
     begin
       if units[your_unit].team <> units[id].team then
          if not units[id].visible then exit else alpha := 255;

       if units[your_unit].team = units[id].team then
          if not units[id].visible then alpha := 150 else alpha := 255;

       x := units[id].pos.y * 64 + (19 - units[id].pos.x) * 64 - 32 ;
       y := units[id].pos.y * 32 - (19 - units[id].pos.x) * 32  + 400 - 112;

       if units[id].ani = 1 then
          begin
            x2 := units[id].TargetPos.y * 64 + (19 - units[id].TargetPos.x) * 64 - 32 ;
            y2 := units[id].TargetPos.y * 32 - (19 - units[id].TargetPos.x) * 32  + 400 - 112;
            x := x + units[id].WayProg/16 * (x2 - x);
            y := y + units[id].WayProg/16 * (y2 - y);
          end;

       ASprite2d_Draw( tex_Units[units[id].sex, 0].body[units[id].gSet.body], x, y, 196, 196, 0, units[id].ani_frame, alpha );
       ASprite2d_Draw( tex_Units[units[id].sex, 0].head[units[id].gSet.head], x, y, 196, 196, 0, units[id].ani_frame, alpha );
       ASprite2d_Draw( tex_Units[units[id].sex, 0].MH[units[id].gSet.MH], x, y, 196, 196, 0, units[id].ani_frame, alpha );
       ASprite2d_Draw( tex_Units[units[id].sex, 0].OH[units[id].gSet.OH], x, y, 196, 196, 0, units[id].ani_frame, alpha );

       if units[id].team = 2 then color := $aa7777 else color := $7777aa;
       w := text_GetWidth( fntCombat, units[id].name, 1) * 0.7;
       h := text_GetHeight( fntCombat, w, units[id].name, 0.3 / scaleXY, 0);
   //    pr2d_Rect(x + 196/2 - w/2, y, w, h, $222222, 150, PR2D_FILL);
       for i := 1 to high(units[id].auras) do
         if units[id].auras[i].exist then
            begin
              ASprite2d_Draw(tex_BIcons, x + i * 25, y - 25, 24, 24, 0,
                                         units[id].auras[i].id);
             // if units[id].auras[i].stacks > 0 then
             // Text_DrawInRectEx(fntCombat, rect(x + i * 25, y - 25, 24, 24), 0.2 / scaleXY, 1, u_IntToStr(units[id].auras[i].stacks), 200, $ff0000);

            end;

       Text_DrawInRectEx( fntCombat, rect(x + 196/2 - w/2, y, w, h), 0.3 / scaleXY, 0, units[id].name + ' ' + s, 255, color, TEXT_HALIGN_CENTER );

     end;
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
  i := uLID;
  units[i].exist:= false;
  units[i].alive:= false;
  units[i].pos.x := 0;
  units[i].pos.y := 0;
  units[i].uID := 0;
  units[i].uType := 0;
  units[i].name := '';
  units[i].sex:=0;
end;

function cm_InRange( x, y, rng : byte ): boolean;
var r : single;
begin
  result := false;
  r := (sqrt( sqr( units[your_unit].pos.x - x ) + sqr( units[your_unit].pos.y - y ) ) );
  if r <= rng then result := true;
end;

function cm_InRangeOfMove( x, y, rng : byte) : boolean;
var d : integer;
begin
  result := false;
  d := abs(x - units[your_unit].pos.x) + abs( y - units[your_unit].pos.y);
  if d <= rng then result := true;
end;

function cm_ShootLine( x, y : byte ) : boolean;
begin
  result := false;
  result := col2d_LineVsCircle( line( units[your_unit].pos.x * 64 + 32,
                                      units[your_unit].pos.y * 64 + 32,
                                      m_x * 64 + 32, m_y * 64 + 32 ),
                                circle( x * 64 + 32, y * 64 + 32, 32 ) );
end;

end.


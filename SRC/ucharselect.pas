unit uCharSelect;

{$mode delphi}
{$codepage utf8}
interface

uses
  uVar,
  uAdd,
  zglHeader,
  uMyGuiTT;

type
  TCharItem = record
    exist : boolean;
    aID   : byte;
    sel   : boolean;
    Name, race, clss, level, loc : utf8string;
    x, y, tx, ty : single;
  end;

  TDestItem = record
    exist : boolean;
    sel   : boolean;
    x, y, tx, ty : single;
  end;

var
  cL : array [1..4] of TCharItem;
  dL : array [1..4] of TDestItem;

procedure CharSel_Init;
procedure CharSel_Render;
procedure CharSel_Update;

procedure DestSel_Init;
procedure DestSel_Render;
procedure DestSel_Update;


implementation

uses uLoader, u_MM_GUI, uXClick;

procedure CharSel_Init;
var i : integer;
begin
  for i := 1 to 4 do
  begin
    cL[i].exist:=false;
    cL[i].Name:='';
    cL[i].clss:='';
    cL[i].level:='';
    cL[i].race:='';
    cL[i].loc:='';
    if charlist[i].ID <> 0 then
       begin
         cL[i].exist:=true;
         cL[i].aID := charlist[i].raceID * 2 - 1 + charlist[i].sex;
         cL[i].sel:=false;
         cL[i].Name:=charlist[i].Name;
         cL[i].race:=GetRaceName(charlist[i].raceID);
         cL[i].clss:=GetClassName(charlist[i].classID);
         cL[i].level:=u_IntToStr(charlist[i].level) + ' level';
         cL[i].loc:=GetLocName(charlist[i].loc);
       end;
    cL[i].tx:= scr_w / 2 - 595 + i * 200;
    cL[i].ty:= scr_h / 2 - 200;
    cL[i].x:= -400;
    cL[i].y:= -400;
  end;
end;

procedure CharSel_Render;
var i: integer; tex: zglPTexture;
begin
  if not (gs = gsCharSelect) then exit;

  for i := 1 to 4 do
    begin
   //   pr2d_rect( scr_w / 2 - 595 + i * 200, scr_h / 2 - 200, 190, 400, $1f1a16, 200, PR2D_FILL);
      SSprite2d_Draw( tex_ChBkgr, cl[i].x, cl[i].y, 190, 350, 0);
      if cL[i].exist then
         begin
           tex := GetTex('ava' + u_IntToStr(cL[i].aID));
           tex_SetMask( tex, tex_ChMask);
           SSprite2d_Draw( GetTex('ava' + u_IntToStr(cL[i].aID)), cl[i].x + 10, cl[i].y + 10, 170, 226, 0 );
           Text_DrawEx( fntMain2, cl[i].x + 90, cl[i].y + 250, 1, 1,
                        cl[i].Name, 255, $002366, TEXT_HALIGN_CENTER );
           Text_DrawEx( fntMain2, cl[i].x + 90, cl[i].y + 265, 1, 1,
                        cl[i].race, 255, $002366, TEXT_HALIGN_CENTER );
           Text_DrawInRectEx( fntMain2, rect(cl[i].x + 10, cl[i].y + 280, 170, 30), 1, 1,
                        cl[i].clss, 255, $002366, TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER );
           Text_DrawEx( fntMain2, cl[i].x + 90, cl[i].y + 310, 1, 1,
                        cl[i].level, 255, $002366, TEXT_HALIGN_CENTER );
           Text_DrawEx( fntMain2, cl[i].x + 90, cl[i].y + 325, 1, 1,
                        cl[i].loc, 255, $002366, TEXT_HALIGN_CENTER );
         end;

      if col2d_PointInRect( Mouse_X, mouse_y, rect(cl[i].x, cl[i].y, 190, 400)) then
         fx_SetBlendMode(FX_BLEND_ADD);
      if not cl[i].exist then
         SSprite2d_Draw(tex_AddBtn, cl[i].x + 10, cl[i].y + 90, 170, 170, 0, 240);
      fx_SetBlendMode(FX_BLEND_NORMAL);
    end;
end;

procedure CharSel_Update;
var i, j: integer;  delta : single;
    fly : boolean;  si : integer; sx : integer;
begin
  if not (gs = gsCharSelect) then exit;
  bNewChar.Enabled:=false;
  bEnterWorld.Enabled:=false;
  bDelChar.Enabled:=false;
  fly := true; si := 0;
  for i := 1 to 4 do
  //  if cL[i].exist then
       begin
         cL[i].x := cL[i].x + (cl[i].tx - cl[i].x) / 12;
         cL[i].y := cL[i].y + (cl[i].ty - cl[i].y) / 15;

         if abs(cl[i].tx - cl[i].x) < 2 then cl[i].x:=cl[i].tx;
         if abs(cl[i].ty - cl[i].y) < 2 then cl[i].y:=cl[i].ty;

         if cl[i].tx = cl[i].x then fly := false;
         if cl[i].ty = cl[i].y then fly := false;

         if not cl[i].sel then;
            begin
              cL[i].tx:= scr_w / 2 - 595 + i * 200;
              cL[i].ty:= scr_h / 2 - 200;
            end;

         if not fly then
            if col2d_PointInRect(Mouse_X, Mouse_Y, rect(cl[i].x, cl[i].y, 190, 350) ) then
               begin
                 cl[i].ty:= scr_h / 2 - 175;
                 if mouse_click(M_BLEFT) then
                    if not cl[i].sel then
                    begin
                      cl[i].sel:=true;
                      for j := 1 to 4 do
                        if i <> j then
                           cl[j].sel:=false;
                    end else
                    begin  // вход по клику
                      if charlist[i].ID <> 0 then
                         begin
                           DoEnterTheWorld();
                         end;
                    end;
               end
               else cl[i].ty := scr_h / 2 - 200;

         if cl[i].sel then
            begin
              si := i;
              cl[i].tx:= 3;
              cl[i].ty:= scr_h - 353 ;
            end else
            if CreateCharMode or DelCharMode then
               begin
                 cl[i].tx:= -400;
                 cl[i].ty:= -400;
               end;
       end;

  if si <> 0 then
     if cl[si].exist then
        begin
          bEnterWorld.Enabled := true;
          bDelChar.Enabled := true;
          gSI := si;
        end else bNewChar.Enabled := true;

  if CreateCharmode then
     begin
       if rgGender.Selected = rbMale then sx := 0 else sx := 1;
       cl[si].exist:=true;
       cl[si].aID:=(cbRace.Selected + 1) * 2 - 1 + sx;
       cL[si].Name:=eCharName.Caption;
       cL[si].race:=GetRaceName(cbRace.Selected + 1);
       cL[si].clss:=GetClassName(1);
       cL[si].level:=u_IntToStr(1) + ' level';
       cL[si].loc:=GetLocName(1);

       mWins[3].imgs[1].texID:= 'sIcon' + u_IntToStr((cbRace.Selected + 1) * 2 - 1);
       mWins[3].imgs[2].texID:= 'sIcon' + u_IntTostr((cbRace.Selected + 1) * 2);

       if mWins[3].imgs[1].omo then mgui_TTOpen(1);
       if mWins[3].imgs[2].omo then mgui_TTOpen(2);
     end else
         if charlist[si].ID = 0 then cl[si].exist:=false;
end;

procedure DestSel_Init;
var i : integer;
begin
  for i := 1 to 4 do
  begin
    dL[i].exist := true;
    dL[i].sel   := false;
    cL[i].tx:= scr_w / 2 - 595 + i * 200;
    cL[i].ty:= scr_h / 2 - 200;
    cL[i].x:= -400;
    cL[i].y:= -400;
  end;
end;

procedure DestSel_Update;
var i, j: integer;  delta : single;
    fly : boolean;  si : integer; sx : integer;
begin
  if not DestinyMode then Exit;
  fly := true; si := 0;
  for i := 1 to 4 do
    begin
         dL[i].x := dL[i].x + (dl[i].tx - dl[i].x) / 12;
         dL[i].y := dL[i].y + (dl[i].ty - dl[i].y) / 15;

         if abs(dl[i].tx - dl[i].x) < 2 then dl[i].x:=dl[i].tx;
         if abs(dl[i].ty - dl[i].y) < 2 then dl[i].y:=dl[i].ty;

         if dl[i].tx = dl[i].x then fly := false;
         if dl[i].ty = dl[i].y then fly := false;

         if not dl[i].sel then;
            begin
              dL[i].tx:= scr_w / 2 - 595 + i * 200;
              dL[i].ty:= scr_h / 2 - 200;
            end;

         if not fly then
            if col2d_PointInRect(Mouse_X, Mouse_Y, rect(dl[i].x, dl[i].y, 190, 250) ) then
               begin
                 dl[i].ty:= scr_h / 2 - 175;
                 if mouse_click(M_BLEFT) then
                    if not cl[i].sel then
                    begin
                      dl[i].sel:=true;
                      for j := 1 to 4 do
                        if i <> j then
                           dl[j].sel:=false;
                    end else
               end
               else dl[i].ty := scr_h / 2 - 200;
       end;
end;

procedure DestSel_Render;
var i: integer; tex: zglPTexture;
begin
  if not DestinyMode then Exit;
  Text_DrawEx( fntCombat, scr_w/2, 35, 1, 1,
               'What did you saw in your last dream?',
               255, $ffffff, TEXT_HALIGN_CENTER );
  for i := 1 to 4 do
    begin
      SSprite2d_Draw( tex_ChBkgr, dl[i].x, dl[i].y, 190, 250, 0);
         begin
           tex := GetTex('dest' + u_IntToStr(i));
           tex_SetMask( tex, tex_ChMask);
           SSprite2d_Draw( tex, dl[i].x + 10, dl[i].y + 10, 170, 226, 0 );
         end;
    end;
end;

end.


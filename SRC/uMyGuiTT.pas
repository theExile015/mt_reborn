unit uMyGuiTT;

{$mode objfpc}{$H+}

interface

uses
  zglHeader,
  sysutils,
  uVar,
  uLocalization,
  uMyGui;

procedure mgui_TTOpen( sender : longword );

implementation

uses u_MM_GUI;

procedure mgui_TTOpen( sender : longword );
var i: integer;       w, h: single;
    d1, d2, d3 : integer; f1, f2, f3 : single;
begin
  d1:=0; d2:=0; d3:=0; f1:=0; f2:=0; f3:=0;
{$REGION 'TTTEXT'}
  case sender of
    1 :
    begin
       mWins[2].texts[1].Text := race_spec[cbRace.Selected*2 + 1];
       mWins[2].texts[2].Text := race_SDisc[cbRace.Selected*2 + 1];
    end;
    2 :
    begin
      mWins[2].texts[1].Text := race_spec[cbRace.Selected*2 + 2];
      mWins[2].texts[2].Text := race_SDisc[cbRace.Selected*2 + 2];
    end;

    26:
    begin
      mWins[2].texts[1].Text := race_names[activechar.header.raceID];
      mWins[2].texts[2].Text := race_discr[activechar.header.raceID];
    end;

    27:
    begin
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[6], [activechar.header.level]));
      mWins[2].texts[2].Text := STD[6];
    end;

    28:
    begin
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[7], [activechar.Numbers.exp, exp_cap[activechar.header.level + 1]]));
      mWins[2].texts[2].Text := STD[7];
    end;

    29:
    begin
      mWins[2].texts[1].Text := class_names[activechar.header.classID];
      mWins[2].texts[2].Text := class_descr[activechar.header.classID];
    end;

    30:
    begin
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[1], [activechar.hpmp.mHP]));
      mWins[2].texts[2].Text := STD[1];
    end;

    31:
    begin
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[2], [activechar.hpmp.mMP]));
      mWins[2].texts[2].Text := STD[2];
    end;

    32:
    begin
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[3], [activechar.hpmp.mAP]));
      mWins[2].texts[2].Text := STD[3];
    end;

    33:
    begin
      mWins[2].texts[1].Text := STT[4];
      mWins[2].texts[2].Text := STD[4];
    end;

    34:
    begin
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[8], [activechar.Stats.HPReg]));
      mWins[2].texts[2].Text := STD[8];
    end;

    35:
    begin
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[9], [activechar.Stats.MPReg]));
      mWins[2].texts[2].Text := STD[9];
    end;

    36:
    begin
      d1 := trunc(activechar.Stats.Str/50 * activechar.Stats.APH);
      d2 := trunc(activechar.Stats.Str/ 2 / 50 * activechar.Stats.APH);
      d3 := trunc(m_Sin(activechar.Stats.APH) * activechar.Stats.Str / 2 );
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[11], [activechar.Stats.Str]));
      mWins[2].texts[2].Text := AnsiToUTF8(format(STD[11], [d1, d2, d3]));
    end;
    37:
    begin
      d1 := trunc(activechar.Stats.agi/50 * activechar.Stats.APH);
      d2 := trunc(activechar.Stats.agi/ 2 / 50 * activechar.Stats.APH);
      d3 := trunc(activechar.Stats.agi / 1.5 );
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[12], [activechar.Stats.Agi]));
      mWins[2].texts[2].Text := AnsiToUTF8(format(STD[12], [d1, d2, d3]));
    end;
    38:
    begin
      if activechar.Stats.Con < 10 then
         for i := 1 to activechar.Stats.Con do
             d1 := d1 + i
      else
         d1 := 65 + (activechar.Stats.Con - 10) * 10;
      d2 := trunc(activechar.header.level + activechar.Stats.Con/activechar.header.level);
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[13], [activechar.Stats.con]));
      mWins[2].texts[2].Text := AnsiToUTF8(format(STD[13], [d1, d2]));
    end;
    39:
    begin
      d1 := trunc(activechar.Stats.hst * 1.75/(activechar.header.level/3 + 5));
      d2 := trunc(activechar.Stats.hst * 2.5/(activechar.header.level + 10));
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[14], [activechar.Stats.hst]));
      mWins[2].texts[2].Text := AnsiToUTF8(format(STD[14], [d1, d2]));
    end;
    40:
    begin
      if activechar.Stats.Int < 10 then
         for i := 1 to activechar.Stats.Int do
             d1 := d1 + i
      else
         d1 := 65 + (activechar.Stats.Int - 10) * 10;
      d2 := trunc(activechar.header.level + activechar.Stats.Int/activechar.header.level);
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[15], [activechar.Stats.int]));
      mWins[2].texts[2].Text := AnsiToUTF8(format(STD[15], [d1, d2]));
    end;
    41:
    begin
      d1 := trunc(activechar.Stats.spi/(activechar.header.level) + activechar.header.level);
      mWins[2].texts[1].Text := AnsiToUTF8(format(STT[16], [activechar.Stats.hst]));
      mWins[2].texts[2].Text := AnsiToUTF8(format(STD[16], [d1]));
    end;
   {
     mWins[6].texts[34].Text:=u_IntToStr(round(activechar.iDMG/10 * activechar.APH + 1)) + '-' + u_IntToStr(2 + round(activechar.iDMG/10 * activechar.APH * 1.1));  // дмг
     mWins[6].texts[35].Text:=u_IntToStr(activechar.APH);  // апх
     mWins[6].texts[36].Text:=u_FloatToStr(15/9) + '%';    // крит
     mWins[6].texts[37].Text:=u_FloatToStr(16/13) + '%';   // хит
      }
    42:
    begin
      if stat_tab = 0 then
         begin
           d1 := 1 + trunc(activechar.Stats.DMG / 10 * activechar.Stats.APH * 0.95);
           d2 := 2 + trunc(activechar.Stats.DMG / 10 * activechar.Stats.APH * 1.05);
           mWins[2].texts[1].Text := AnsiToUTF8(format(STT[17], [d1, d2]));
           mWins[2].texts[2].Text := STD[17];
         end;
      if stat_tab = 1 then
         begin
           f1 := activechar.Stats.Armor / (activechar.Stats.Armor + 200 + activechar.header.level * 25) * 100;
           mWins[2].texts[1].Text := AnsiToUTF8(format(STT[21], [activechar.Stats.Armor]));
           mWins[2].texts[2].Text := AnsiToUTF8(format(STD[21], [f1]));
         end;
      if stat_tab = 2 then
         begin
           mWins[2].texts[1].Text := STT[24];
           mWins[2].texts[2].Text := STD[24];
         end;
    end;
    43:
    begin
      if stat_tab = 0 then
         begin
           mWins[2].texts[1].Text := AnsiToUTF8(format(STT[18], [activechar.Stats.APH]));
           mWins[2].texts[2].Text := STD[18];
         end;
      if stat_tab = 1 then
         begin
           mWins[2].texts[1].Text := STT[22];
           mWins[2].texts[2].Text := STD[22];
         end;
      if stat_tab = 2 then
         begin
           mWins[2].texts[1].Text := STT[25];
           mWins[2].texts[2].Text := STD[25];
         end;
    end;
    44:
    begin
      if stat_tab = 0 then
         begin
           mWins[2].texts[1].Text := STT[19];
           mWins[2].texts[2].Text := STD[19];
         end;
      if stat_tab = 1 then
         begin
           mWins[2].texts[1].Text := STT[20];
           mWins[2].texts[2].Text := STD[20];
         end;
      if stat_tab = 2 then
         begin
           mWins[2].texts[1].Text := STT[26];
           mWins[2].texts[2].Text := STD[26];
         end;
    end;
    45:
    begin
      if stat_tab = 0 then
         begin
           mWins[2].texts[1].Text := STT[20];
           mWins[2].texts[2].Text := STD[20];
         end;
    end;
  else
    mWins[2].texts[1].Text:='Unknown tooltip ' + u_IntToStr(sender);
  //  mWins[2].texts[2].Text:= LOREM;
  end;
                 {PERK DESCRIPTION}
  if (sender > 100) and (sender < 300) then
     begin
       mWins[2].texts[4].visible:=false;
       mWins[2].texts[5].visible:=false;
       if skills[sender - 100].rank < skills[sender - 100].maxrank then
          begin
            mWins[2].texts[3].visible:=true;
            mWins[2].texts[3].Text:= u_IntToStr(skills[sender - 100].costs[skills[sender - 100].rank + 1]) + ' perk pts.';
            mWins[2].texts[3].rect.W:= mWins[2].rect.W - 15 ;
            if skills[sender - 100].costs[skills[sender - 100].rank + 1] <= activechar.Numbers.TP then
               mWins[2].texts[3].color:= $9696A8
            else
               mWins[2].texts[3].color:= $D82323;
          end else mWins[2].texts[3].visible:=false;


       if (skills[sender - 100].rank > 0) and (skills[sender - 100].rank < skills[sender - 100].maxrank) then
          begin
            mWins[2].texts[4].visible:=true;
            mWins[2].texts[4].Text:= 'Next Rank';
            mWins[2].texts[4].color:= $9696A8;

            mWins[2].texts[5].visible:=true;
            mWins[2].texts[5].Text := AnsiToutf8(format(PD[sender - 100], [skills[sender - 100].xyz[skills[sender - 100].rank + 1].X,
                                                                           skills[sender - 100].xyz[skills[sender - 100].rank + 1].Y,
                                                                           skills[sender - 100].xyz[skills[sender - 100].rank + 1].Z]));
            mWins[2].texts[5].rect.Y:= mWins[2].texts[4].rect.Y + mWins[2].texts[4].rect.H - 5;
            mWins[2].texts[5].rect.W:= mWins[2].rect.W - 15;
            mWins[2].texts[5].rect.H:= text_GetHeight(fntMain, mWins[2].texts[5].rect.W, mWins[2].texts[5].Text);

          end else
          if skills[sender - 100].rank = 0 then
          if ((sender - 100) - trunc((sender - 100) / 10) * 10 < 3 ) and
             ((sender - 100) - trunc((sender - 100) / 10) * 10 > 0 )then
             begin
               mWins[2].texts[4].visible:=true;
               mWins[2].texts[4].Text:= 'Requires ' +  AnsiToutf8(format(PT[trunc((sender - 100) / 10)*10],[ 2, skills[trunc((sender - 100) / 10)*10].maxrank]));
               mWins[2].texts[4].color:= $D82323;
               mWins[2].texts[5].visible:=false;
             end ;

       mWins[2].texts[4].rect.W:= mWins[2].rect.W - 15;
       mWins[2].texts[4].rect.Y:= mWins[2].texts[2].rect.Y + mWins[2].texts[2].rect.H;

       mWins[2].texts[1].Text:= format(PT[sender - 100], [skills[sender - 100].rank, skills[sender - 100].maxrank]);

       if skills[sender - 100].rank < skills[sender - 100].maxrank then
          mWins[2].texts[2].Text:= AnsiToutf8(format(PD[sender - 100], [skills[sender - 100].xyz[skills[sender - 100].rank ].X,
                                                                        skills[sender - 100].xyz[skills[sender - 100].rank ].Y,
                                                                        skills[sender - 100].xyz[skills[sender - 100].rank ].Z]))
       else
          mWins[2].texts[2].Text:= AnsiToutf8(format(PD[sender - 100], [skills[sender - 100].xyz[skills[sender - 100].maxrank].X,
                                                                        skills[sender - 100].xyz[skills[sender - 100].maxrank].Y,
                                                                        skills[sender - 100].xyz[skills[sender - 100].maxrank].Z]));
       if skills[sender - 100].rank = 0 then
          mWins[2].texts[2].Text:= AnsiToutf8(format(PD[sender - 100], [skills[sender - 100].xyz[1].X,
                                                                        skills[sender - 100].xyz[1].Y,
                                                                        skills[sender - 100].xyz[1].Z]))

     end else
     begin
       mWins[2].texts[3].visible:=false;
       mWins[2].texts[4].visible:=false;
       mWins[2].texts[5].visible:=false;
     end;
{$ENDREGION}

  mWins[2].visible:=true;
  w := Text_GetWidth(fntMain, mWins[2].texts[1].Text);
  w := w * 2 + 10 + 6;
  if w < 175 then w := 175;
  h := Text_GetHeight( fntMain, w - 16, mWins[2].texts[2].Text );
  h := h + 45 + 6;

  if mWins[2].texts[5].visible then h := h + Text_GetHeight(fntMain, mWins[2].texts[2].rect.W, mWins[2].texts[5].Text);

  if Mouse_X() + W > scr_w then
     mWins[2].rect.X:= Mouse_X() - W
  else
     mWins[2].rect.X:= Mouse_X() + 16;
  if Mouse_Y() + H > scr_h then
     mWins[2].rect.Y:= Mouse_Y() - H
  else
     mWins[2].rect.Y:= Mouse_Y() + 16;

  mWins[2].rect.W:=W;
  mWins[2].rect.H:=H;
  mWins[2].texts[1].rect.W:= W - 6;
  mWins[2].texts[2].rect.W:= W - 6;
  mWins[2].texts[2].rect.H:= Text_GetHeight(fntMain, mWins[2].texts[2].rect.W, mWins[2].texts[2].Text);
end;

end.


unit uChat;

{/$codepage utf8}
{$mode delphi}

interface

uses
  sysutils, classes, uVar, zglHeader, uAdd, uMyGui;

procedure Chat_Init();
procedure Chat_Update();
procedure Chat_Draw();
function Chat_AddMember(chID: byte; Nick : string; charID, clanID, klassID, lvl: cardinal): byte;

function Chat_AddTab(): byte;
function Chat_ClearTabMembers(tab : byte): byte;
function Chat_AddMessage(chID: byte; sender, msg: string): byte;
function Chat_ParseMessage(cID, mID : byte) : byte;
function Chat_MsgNum(chID: byte): byte;

function Chat_AddPrivate(Sender : UTF8String): byte;
function Chat_CatchPrivte( msg: UTF8String ): UTF8String;
function Chat_CheckMessage( msg: String): boolean;
procedure Chat_SaveToFile;

implementation

uses u_MM_gui, uNetCore, uPkgProcessor, uLoader;

procedure Chat_Init();
var i, j, k : integer;
begin

  // сначала всё чистим
  for i := 0 to length(ch_tabs) - 1 do
    begin
      ch_tabs[i].exist := false;
      ch_tabs[i].Name := 'Tab #' + u_IntToStr(i);
      ch_tabs[i].chID := 0;
      for j := 0 to length(ch_tabs[i].Members) - 1 do
        begin
          ch_tabs[i].Members[j].exist := false;
          ch_tabs[i].Members[j].Nick := 'No name';
          ch_tabs[i].Members[j].charID := 0;
          ch_tabs[i].Members[j].level := 0;
          ch_tabs[i].Members[j].klass := 0;
          ch_tabs[i].Members[j].Clan := 0;
        end;
      for j := 0 to length(ch_tabs[i].msgs) - 1 do
        begin
          ch_tabs[i].msgs[j].exist := false;
          ch_tabs[i].msgs[j].raw := 'Default';
          for k:= 0 to Length(ch_tabs[i].msgs[j].lexems) - 1 do
            begin
              ch_tabs[i].msgs[j].lexems[k].raw := 'dLex';
              ch_tabs[i].msgs[j].lexems[k].lType := 0;
              ch_tabs[i].msgs[j].lexems[k].ToPrint := 'Lex';
            end;
        end;
    end;

  {===================================

  ==================================}

  for i := 1 to 5 do
    begin
      ActionBar[i].exist:=true;
      ActionBar[i].x:= (i - 1) * 36 + 2;
      ActionBar[i].y:= scr_h - 186;
      ActionBar[i].ddType:= 2;
      {if i = 1 then ActionBar[i].contains:= 1 else  }
         ActionBar[i].data.contain:=0;
      ActionBar[i].visible:= true;

      SystemBar[i].exist:=true;
      SystemBar[i].x:= scr_w - 187 + (i - 1) * 36+ 2;
      SystemBar[i].y:= scr_h - 186;
      SystemBar[i].ddType:= 2;

      //SystemBar[i].contains:=i;
      SystemBar[i].visible:= true;
    end;

  SystemBar[1].data.contain:=1;
  SystemBar[2].data.contain:=5;
  SystemBar[3].data.contain:=7;
  SystemBar[4].data.contain:=4;

{ ActionBar[1].contains:=1;
  ActionBar[2].contains:=2;
  ActionBar[3].contains:=6;
  ActionBar[4].contains:=4;
  ActionBar[5].contains:=5; }

  com_face := 50;
  ch_scroll_pos := 1; // выставляем фокус чата на последнее сообщение
end;

procedure Chat_Update();
var i, j: integer; dy : single;
begin
{if iga = igaCombat then
   begin
     for i := 1 to 5 do
         ActionBar[i].contains:=mWins[11].dnds[i].contains;

     if your_turn then
        begin
          if com_face <> 0 then com_face := com_face - com_face / 12;
          if (not Range_mode) and (spID = 1) then spID := 0;
          if (spID = 11) or (spID = 8) or (spID = 13) or (spID = 14) or (spID = 15) then spID := 0;

          for i := 1 to high(ActionBar) do
            begin
              ActionBar[i].omo:= Col2d_PointInRect( Mouse_X, Mouse_Y, rect(ActionBar[i].x, ActionBar[i].y, 34, 34));
              SystemBar[i].omo:= Col2d_PointInRect( Mouse_X, Mouse_Y, rect(SystemBar[i].x, SystemBar[i].y, 34, 34));

              for j := 0 to 4 do
              if KEY_PRESS(K_1 + j) and (not ch_message_inp) then
                 begin
                      if units[your_unit].cAP >= spells[ActionBar[1 + j].contains].AP_Cost then
                         begin
                           if units[your_unit].cMP >= spells[ActionBar[1 + j].contains].MP_Cost then
                              begin
                                spID := ActionBar[1 + j].contains;
                                if (spID = 11) or (spID = 8) or (spID = 13) or (spID = 14) or (spID = 15) then
                                   begin
                                     SendData( inline_pkgCompile(058, u_IntToStr(combat_id) + '`' +
                                                                 u_IntToStr(units[your_unit].uType) + '`' +
                                                                 u_IntToStr(units[your_unit].uID)  + '`' +
                                                                 u_IntToStr(spID) ) ) ;
                                     if spID = 15 then
                                        begin
                                          sleep(50);
                                          SendData( inline_pkgCompile(032, u_IntToStr(combat_id) + '`'));
                                          your_turn := false;
                                        end;
                                     exit;
                                   end;
                                spR := spells[ActionBar[1 + j].contains].range;
                                if (spID = 6) and (skills[42].rank > 0) then
                                    spR := spR + skills[42].xyz[skills[42].rank].X;
                                if (spID = 1) or (spID = 5) or (spID = 4) or (spID = 6) or (spID = 12) then range_mode := true else range_mode := false;
                              end else Chat_AddMessage(3, 'S', 'Not enough MP to cast ' + spells[ActionBar[1 + j].contains].name );
                         end else Chat_AddMessage(3, 'S', 'Not enough AP to cast ' + spells[ActionBar[1 + j].contains].name );
                 end;



              if ActionBar[i].omo then
                 begin
                   stt_Open(ActionBar[i].contains, 2);
                   if Mouse_Click(M_BLEFT) and (ActionBar[i].contains > 0) then
                      if units[your_unit].cAP >= spells[ActionBar[i].contains].AP_Cost then
                         begin
                           if units[your_unit].cMP >= spells[ActionBar[i].contains].MP_Cost then
                              begin
                                spID := ActionBar[i].contains;
                                if (spID = 1) or (spID = 5) or (spID = 4)or (spID = 12) then range_mode := true else range_mode := false;
                                spR := spells[ActionBar[i].contains].range;
                              end else Chat_AddMessage(3, 'S', 'Not enough MP to cast ' + spells[ActionBar[i].contains].name );
                         end else Chat_AddMessage(3, 'S', 'Not enough AP to cast ' + spells[ActionBar[i].contains].name );
                 end;

              if SystemBar[i].omo then
                 begin
                   Stt_Open(100 - SystemBar[i].contains, 2);
                   if mouse_click(m_bleft) then
                      begin
                        if systembar[i].contains = 1 then
                            begin
                              SendData( inline_pkgCompile(032, u_IntToStr(combat_id) + '`'));
                              your_turn := false;
                            end;

                        if systembar[i].contains = 4 then
                           begin
                             range_mode := true;
                             spR := 8;
                             if skills[62].rank > 0 then
                                spR := spR + skills[62].xyz[skills[62].rank].X;
                           end;

                        if systembar[i].contains = 7 then
                           if units[your_unit].cAP > 4 then
                              turn_mode := true;
                      end;
                 end;
            end;
        end else
        begin
          if com_face <> -50 then com_face := com_face - (com_face - 50) / 12;
        end;
      Nonameframe41.Hide;
   end; }


// действия с чатом
begin
  // omo_ch_scr_up, omo_ch_scr_dw, omo_ch_scr_spot
  omo_ch_scr_up := col2d_PointInCircle( Mouse_X, Mouse_Y, circle(scr_w - 25, scr_h - 120, 10));
  omo_ch_scr_spot := col2d_PointInCircle( Mouse_X, Mouse_Y, circle(scr_w - 25, scr_h - 100 + ch_mem_scroll_pos * 60, 10));
  omo_ch_scr_dw := col2d_PointInCircle( Mouse_X, Mouse_Y, circle(scr_w - 25, scr_h - 20, 10));

  omo_scr_up := col2d_PointInCircle( Mouse_X, Mouse_Y, circle(scr_w - 215, scr_h - 100, 10));
  omo_scr_spot := col2d_PointInCircle( Mouse_X, Mouse_Y, circle(scr_w - 215, scr_h - 80 + ch_scroll_pos * 30, 10));
  omo_scr_dw := col2d_PointInCircle( Mouse_X, Mouse_Y, circle(scr_w - 215, scr_h - 35, 10));

  if Mouse_X < scr_w - 200 then
     begin
       if mouse_wheel(M_WUP) then ch_scroll_pos := ch_scroll_pos - 0.05;
       if mouse_wheel(M_WDOWN) then ch_scroll_pos := ch_scroll_pos + 0.05;
       if ch_scroll_pos < 0 then ch_scroll_pos := 0;
       if ch_scroll_pos > 1 then ch_scroll_pos := 1;
     end else
     begin
       if mouse_wheel(M_WUP) then ch_mem_scroll_pos := ch_mem_scroll_pos - 0.05;
       if mouse_wheel(M_WDOWN) then ch_mem_scroll_pos := ch_mem_scroll_pos + 0.05;
       if ch_mem_scroll_pos < 0 then ch_mem_scroll_pos := 0;
       if ch_mem_scroll_pos > 1 then ch_mem_scroll_pos := 1;
     end;

  for I := 0 to 7 do
    if ch_tabs[i].exist then
       omo_ch_tabs[i] := col2d_PointInRect( mouse_X, Mouse_Y, rect( 15 + i*75, scr_h - 135, 75, 20 ) );

  for I := 0 to length(ch_tabs[ch_tab_curr].msgs) - 1 do
      if ch_tabs[ch_tab_curr].msgs[i].exist then
         begin
           ch_tabs[ch_tab_curr].msgs[i].omo :=
              col2d_PointInRect( mouse_X, Mouse_Y, ch_tabs[ch_tab_curr].msgs[i].sRect );
           for j := 0 to 3 do
           if ch_tabs[ch_tab_curr].msgs[i].lexems[j].lType > 0 then
              ch_tabs[ch_tab_curr].msgs[i].lexems[j].omo :=
                col2d_PointInRect( mouse_X, Mouse_Y, ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect )
           else
              ch_tabs[ch_tab_curr].msgs[i].lexems[j].omo := false;
         end;

  if mouse_Click(M_BRIGHT) then
     begin

       for I := 0 to length(ch_tabs[ch_tab_curr].msgs) - 1 do
       if ch_tabs[ch_tab_curr].msgs[i].vis and ch_tabs[ch_tab_curr].msgs[i].exist then
           begin
             // добавляем приватку
             if ch_tabs[ch_tab_curr].msgs[i].omo then
                begin  // Добавляем ссылку в чатик
                  Chat_AddPrivate(ch_tabs[ch_tab_curr].msgs[i].sender);
                end;
             // добавляем ссылку из чата
             for j := 0 to 3 do
               if ch_tabs[ch_tab_curr].msgs[i].lexems[j].omo then
                  begin  // Добавляем ссылку в чатик
                    if ch_message_inp then
                      begin
                       if utf8_Length(eChatFrame.Caption + ' {' + ch_tabs[ch_tab_curr].msgs[i].lexems[j].raw + '{') < 90 then
                          eChatFrame.Caption := eChatFrame.Caption + ' {' + ch_tabs[ch_tab_curr].msgs[i].lexems[j].raw + '{' ;
                       eChatFrame.Focus;
                       echatFrame.SelectAll;
                       eChatFrame.DeleteSelection;
                      end else
                      begin
                        ch_message_inp := true;
                        Nonameframe38.Show;
                        eChatFrame.Show;
                        bChatSend.Show;
                        eChatFrame.Caption := ' {' + ch_tabs[ch_tab_curr].msgs[i].lexems[j].raw + '{';
                        eChatFrame.Focus;
                        echatFrame.SelectAll;
                        eChatFrame.DeleteSelection;
                      end;
                  end;
           end;

       for I := 0 to length(ch_tabs[ch_tab_curr].msgs) - 1 do
         if ch_tabs[ch_tab_curr].msgs[i].vis and ch_tabs[ch_tab_curr].msgs[i].exist then
             for j := 0 to 3 do
               if ch_tabs[ch_tab_curr].msgs[i].lexems[j].omo then
                  begin
                    if ch_tabs[ch_tab_curr].msgs[i].lexems[j].lType = 1 then
                       itt_open(ch_tabs[ch_tab_curr].msgs[i].lexems[j].par1, 1); //открываем ссылку
                    if ch_tabs[ch_tab_curr].msgs[i].lexems[j].lType = 2 then
                       stt_Open(ch_tabs[ch_tab_curr].msgs[i].lexems[j].par1, 1); //открываем ссылку на спелл
                  end;

       dy := 1 / (ch_tabs[ch_tab_curr].nMem - 8);
       if omo_ch_scr_up then ch_mem_scroll_pos := ch_mem_scroll_pos - dy;
       if omo_ch_scr_dw then ch_mem_scroll_pos := ch_mem_scroll_pos + dy;
       if ch_mem_scroll_pos < 0 then ch_mem_scroll_pos := 0;
       if ch_mem_scroll_pos > 1 then ch_mem_scroll_pos := 1;

       dy := 6 / 64;
       if omo_scr_up then ch_scroll_pos := ch_scroll_pos - dy;
       if omo_scr_dw then ch_scroll_pos := ch_scroll_pos + dy;
       if ch_scroll_pos < 0 then ch_scroll_pos := 0;
       if ch_scroll_pos > 1 then ch_scroll_pos := 1;
  end;

  if mouse_Click(M_BLEFT) then
     begin
       for I := 0 to 7 do
           if ch_tabs[i].exist then
              if omo_ch_tabs[i] then
                begin
                  ch_tab_curr := i;
                  ch_tabs[i].newmsg := false;
                end;

       for I := 0 to length(ch_tabs[ch_tab_curr].msgs) - 1 do
         if ch_tabs[ch_tab_curr].msgs[i].vis and ch_tabs[ch_tab_curr].msgs[i].exist then
           if ch_tabs[ch_tab_curr].msgs[i].omo then
              pum_nick_open(ch_tabs[ch_tab_curr].msgs[i].sender); //открываем менюшку
     end;

  if mouse_down(M_BLEFT) then
     begin
       if omo_ch_scr_spot then
          begin
            ch_mem_scroll_pos := (mouse_Y - (scr_h - 100)) / 60;
            if mouse_y < scr_h - 100 then ch_mem_scroll_pos := 0;
            if mouse_y > scr_h - 40 then ch_mem_scroll_pos := 1;
          end;
       if omo_scr_spot then
          begin
            ch_scroll_pos := (mouse_Y - (scr_h - 80)) / 30;
            if mouse_y < scr_h - 80 then ch_scroll_pos := 0;
            if mouse_y > scr_h - 50 then ch_scroll_pos := 1;
          end;
     end;
end;
end;

procedure Chat_Draw();
var i, j, b, k, n, m: integer;
    Color, fColor, flag : LongWord;
    r: zglTRect;
    fH, sW, mW, nH, dH : single;
begin
  // рисуем интерфейс управления боем
  if iga = igaCombat then
     begin
       Scissor_Begin(0, scr_h - 200, 200, 50);
         b := round(200 / frmpak[3].h) + 1;
         pr2d_Rect( 0, scr_h - 200 + com_face, 200, 50, $1f1a16, 200, PR2D_FILL);
         for I := 0 to b do
             SSprite2d_draw( frmpak[3].brd, i * frmpak[3].h, scr_h - 200 - frmpak[3].dy + com_face, frmpak[3].w, frmpak[3].h, 90);
         SSprite2d_draw( frmpak[3].brd, 200 - frmpak[3].w, scr_h - 190 + frmpak[3].w + com_face, frmpak[3].w, frmpak[3].h, 180);
         SSprite2d_Draw( frmPak[3].crn, 200 - frmPak[3].c, scr_h - 200 + com_face, frmPak[3].c , frmPak[3].c, 90);

         for i := 1 to high(ActionBar) do
             begin
                fx2d_SetColor($aaaa00);
                if ActionBar[i].omo then flag := FX_COLOR or FX_BLEND else flag := FX_BLEND;
                if ActionBar[i].data.contain = spID then
                   begin
                     flag := FX_COLOR or FX_BLEND;
                     fx2d_SetColor($5555FF);
                   end;
                ASprite2d_Draw( tex_Item_Slots, ActionBar[i].X, ActionBar[i].Y + com_face, 34, 34, 0, 6, 255, flag );
                if ActionBar[i].data.contain > 0 then
                   SSprite2d_Draw( GetTex('i33,' + u_IntToStr(spells[actionbar[i].data.contain].iID)), ActionBar[i].x, actionbar[i].y + com_face, 34, 34, 0, 255);
                text_Draw(fntMain, ActionBar[i].x + 5, ActionBar[i].y + 5 + com_face, u_IntToStr(i) );
             end;

       Scissor_End();

       Scissor_Begin(scr_w - 200, scr_h - 200, 200, 50);
         pr2d_Rect( scr_w - 200, scr_h - 200 + com_face, 200, 50, $1f1a16, 200, PR2D_FILL);
         for I := 0 to b do
             SSprite2d_draw( frmpak[3].brd, scr_w - 200 + i * frmpak[3].h, scr_h - 200 - frmpak[3].dy + com_face , frmpak[3].w, frmpak[3].h, 90);
         SSprite2d_draw( frmpak[3].brd, scr_w - 200, scr_h - 190 + frmpak[3].w + com_face, frmpak[3].w, frmpak[3].h, 180);
         SSprite2d_Draw( frmPak[3].crn, scr_w - 200, scr_h - 200 + com_face, frmPak[3].c, frmPak[3].c, 0);

         for i := 1 to high(SystemBar) do
             begin
                fx2d_SetColor($aaaa00);
                if SystemBar[i].omo then flag := FX_COLOR or FX_BLEND else flag := FX_BLEND;
                ASprite2d_Draw( tex_Item_Slots, SystemBar[i].X, SystemBar[i].Y + com_face, 34, 34, 0, 6, 255, flag );
                if SystemBar[i].data.contain > 0 then
                   SSprite2d_Draw( GetTex('i32,' + u_IntToStr(SystemBar[i].data.contain)), SystemBar[i].x, SystemBar[i].y + com_face, 34, 34, 0, 255);
             end;
      { if your_turn then
           if units[your_unit].cAP < 5 then
              begin
                SSprite2d_Draw(tex_Glow, systembar[1].x - 2, systembar[1].y - 2, 36, 36, 0, 255);
              end;    }
       Scissor_End();
     end;

  // рисуем бордюр и бэкграунд чата
  b := round(scr_w / frmpak[3].h) + 1;
  pr2d_Rect( 0, scr_h - 150, scr_w, 150, chat_color.bgr, 200, PR2D_FILL);
  if ch_message_inp then
      pr2d_rect( 10, scr_h - 20, scr_w - 210, 20, $000000, 255, pr2d_fill);
  for I := 0 to b do
    SSprite2d_draw( frmpak[3].brd, i * frmpak[3].h, scr_h - 150 - frmpak[3].dy, frmpak[3].w, frmpak[3].h, 90);
  for I := 0 to 4 do
    begin
     SSprite2d_draw( frmpak[3].brd, scr_w - 200, scr_h - 138 + i * frmpak[3].h, frmpak[3].w, frmpak[3].h, 0);
     SSprite2d_draw( frmpak[3].brd, -3, scr_h - 138 + i * frmpak[3].h, frmpak[3].w, frmpak[3].h, 0);
     SSprite2d_draw( frmpak[3].brd, scr_w - 10, scr_h - 138 + i * frmpak[3].h, frmpak[3].w, frmpak[3].h, 0);
    end;

  // отрисовка тела чата
  // pr2d_Line( 15, scr_h - 135, 15, scr_h - 25, $1351D7, 150 );                 // левая
  pr2d_Line( 10, scr_h - 23 , scr_w - 200 , scr_h - 23, $1f1a16, 200 );          // нижняя
  pr2d_Line( scr_w - 220, scr_h - 23 , scr_w - 220 , scr_h - 115, $1f1a16, 150 );// правая

  pr2d_Line( 10, scr_h - 115, 10 + ch_tab_curr * 75 + 5, scr_h - 115, $1f1a16, 200 );      //верх - лев
  pr2d_Line( 10 + ch_tab_curr * 75 + 75 + 5, scr_h - 115, scr_w - 200 , scr_h - 115, $1f1a16, 200 ); // верх - прав

  // отрисовка вкладок чата
  for I := 0 to length(ch_tabs) - 1 do
  if ch_tabs[i].exist then
    begin
      pr2d_Line( 15 + i * 75, scr_h - 135, 15 + (i + 1) * 75, scr_h - 135, $1f1a16, 200 );  // таб - верх
      pr2d_Line( 15 + i * 75, scr_h - 135, 15 + i * 75, scr_h - 115, $1f1a16, 200 );
      pr2d_Line( 15 + (i + 1) * 75, scr_h - 135, 15 + (i + 1) * 75, scr_h - 115, $1f1a16, 200 );
      if ch_tab_curr = i then
         begin
           text_DrawInRectEx( fntMain2, Rect( 15 + i * 75, scr_h - 135,
                                             75, 20),
                              1, 0, AnsiToUTF8(ch_tabs[i].Name),
                              255, $CCCCCC, TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER );

         end else
         begin
           if omo_ch_tabs[i] then color := $555555 else color := $222222;
           if ch_tabs[i].newmsg then fcolor := $CC0000 else fcolor := $CCCCCC;

           pr2d_Rect( 15 + i * 75 + 1, scr_h - 135 + 1, 75 - 1, 20 - 2 , color, 170, PR2D_FILL);
           text_DrawInRectEx( fntMain2, Rect( 15 + i * 75, scr_h - 135,
                                             75, 20),
                              1, 0, AnsiToUTF8(ch_tabs[i].Name),
                              255, fColor, TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER );
         end;
    end;

  // отрисовка тела списка игроков
  pr2d_Rect( scr_w - 180, scr_h - 135, 165, 130, $1f1a16, 200);
  pr2d_Line( scr_w - 35, scr_h - 135, scr_w - 35, scr_h - 5, $1f1a16, 200);
  SSprite2d_Draw(tex_ui_scr_bod, scr_w - 75, scr_h - 75, 100, 5, 90);
  // omo_ch_scr_up, omo_ch_scr_dw, omo_ch_scr_spot
  if omo_ch_scr_up then
     begin
       fx2d_SetColor( $F4A460 );
       ASprite2d_Draw(tex_ui_scr_arr, scr_w - 40, scr_h - 130 , 29, 19, 90, 1,
                      255, FX_BLEND or FX_COLOR);
     end else
       ASprite2d_Draw(tex_ui_scr_arr, scr_w - 40, scr_h - 130 , 29, 19, 90, 1,
                      255);

  if omo_ch_scr_dw then
     begin
       fx2d_SetColor( $F4A460 );
       ASprite2d_Draw(tex_ui_scr_arr, scr_w - 40, scr_h - 30 , 29 , 19, 90, 2,
                      255, FX_BLEND or FX_COLOR);
     end else
       ASprite2d_Draw(tex_ui_scr_arr, scr_w - 40, scr_h - 30 , 29 , 19, 90, 2,
                      255);

  if omo_ch_scr_spot then
     begin
       fx2d_SetColor( $F4A460 );
       ASprite2d_Draw(tex_ui_scr_spot, scr_w - 35, scr_h - 110 + ch_mem_scroll_pos * 60  , 20, 20, 45, 1,
                      255, FX_BLEND or FX_COLOR);
     end else
       ASprite2d_Draw(tex_ui_scr_spot, scr_w - 35, scr_h - 110 + ch_mem_scroll_pos * 60  , 20, 20, 45, 1,
                      255);
// скролл-бар чата
  SSprite2d_Draw(tex_ui_scr_bod, scr_w - 245, scr_h - 70, 70, 5, 90);
  if omo_scr_up then
     begin
       fx2d_SetColor( $F4A460 );
       ASprite2d_Draw(tex_ui_scr_arr, scr_w - 225, scr_h - 110 , 29, 19, 90, 1,
                      255, FX_BLEND or FX_COLOR);
     end else
       ASprite2d_Draw(tex_ui_scr_arr, scr_w - 225, scr_h - 110 , 29, 19, 90, 1,
                      255);

  if omo_scr_dw then
     begin
       fx2d_SetColor( $F4A460 );
       ASprite2d_Draw(tex_ui_scr_arr, scr_w - 225, scr_h - 45 , 29 , 19, 90, 2,
                      255, FX_BLEND or FX_COLOR);
     end else
       ASprite2d_Draw(tex_ui_scr_arr, scr_w - 225, scr_h - 45 , 29 , 19, 90, 2,
                      255);

  if omo_scr_spot then
     begin
       fx2d_SetColor( $F4A460 );
       ASprite2d_Draw(tex_ui_scr_spot, scr_w - 220, scr_h - 95 + ch_scroll_pos * 30  , 20, 20, 45, 1,
                      255, FX_BLEND or FX_COLOR);
     end else
       ASprite2d_Draw(tex_ui_scr_spot, scr_w - 220, scr_h - 95 + ch_scroll_pos * 30  , 20, 20, 45, 1,
                      255);

  { Pr2d_Circle(scr_w - 25, scr_h - 120, 10);
  Pr2d_Circle(scr_w - 25, scr_h - 100 + ch_mem_scroll_pos * 60, 10);
  Pr2d_Circle(scr_w - 25, scr_h - 20, 10);    }

  // Поскольку после изменения количества мемберов
  // всегда происходит его перестроение, то мы всегда знаем
  // что мемберы находятся в начале таблицы и их определённое количество
  // исходя из этого и позиции скролл-бара, можно вывести нуженое
  // количество мемберов.

  // Мемберы пишутся в следующем формате уровень(число) раса(АБР) класс(ИКО) клан(ИКО) ник(СЛОВО)
  k := 0;
  if ch_tabs[ch_tab_curr].nMem < 9 then n := 0 else
     begin
       if ch_mem_scroll_pos < 0 then ch_mem_scroll_pos := 0;
       if ch_mem_scroll_pos > 1 then ch_mem_scroll_pos := 1;
       n := round((ch_tabs[ch_tab_curr].nMem - 8) * ch_mem_scroll_pos);
     end;
  m := n + 8;
  if m > ch_tabs[ch_tab_curr].nMem - 1 then m := ch_tabs[ch_tab_curr].nMem - 1;

  for i := n to ch_tabs[ch_tab_curr].nMem - 1 do
    if ch_tabs[ch_tab_curr].Members[i].exist then   //  ну доп проверки ещё никому не вредили )
       begin
          text_DrawInRectEx( fntMain2, Rect( scr_w - 175, scr_h - 130 + k*15 + 3 ,
                                            15, 15),
                              1, 0, u_IntToStr(ch_tabs[ch_tab_curr].Members[i].level),
                              255, $DDDDDD, TEXT_HALIGN_CENTER or TEXT_VALIGN_Bottom );

          ASprite2d_Draw(tex_LocIcons, scr_w - 158 , scr_h - 131 + k*15, 15, 15, 0, 1);
          ASprite2d_Draw(tex_LocIcons, scr_w - 143 , scr_h - 131 + k*15, 15, 15, 0, 5);
          scissor_Begin( scr_w - 128, scr_h - 131 + k * 15 , 90, 16);
            text_DrawInRectEx( fntMain2, Rect( scr_w - 128, scr_h - 131 + k * 15 + 3 ,
                                              90, 16),
                                1, 0, AnsiToUTF8(ch_tabs[ch_tab_curr].Members[i].Nick),
                                255, $CCCCCC, TEXT_HALIGN_LEFT or TEXT_VALIGN_Bottom );
          scissor_End;
          inc(k);
          if k > 7 then break;
       end;
  // pr2d_rect(10, scr_h - 115 , scr_w - 230, 92, $FFFF00 );
  // ножницы, чтоб ничего нигде не выпирало, если вдруг что-то пойдёт не так.
  scissor_Begin( 10, scr_h - 115 , scr_w - 230, 92);

  // отрисовка сообщений чата
  fH := text_GetHeight( fntChat, text_GetWidth( fntMain, 'H'), 'H');
  nH := -fH ;

  for j := 0 to length(ch_tabs) - 1 do
    for i := 63 to 0 do
      ch_tabs[j].msgs[i].vis := false;

 // ch_scroll_pos := 1; //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  n := 0; m := 63;
  n := round(63 * (1 - ch_scroll_pos));
  if n > 63 - 6 then n := 63 - 6;
  m := n + 6;

  for i := n to m do
      if ch_tabs[ch_tab_curr].msgs[i].exist then
         begin
           ch_tabs[ch_tab_curr].msgs[i].vis := true;
           //  поскольку мы не знаем, сколько строк займёт сообщение, поэтому нужно его рассчитать
           //  исходя из текста сообщения и доступной ширины окна сообщения
           r.W := text_GetWidth( fntChat, '<' + ch_tabs[ch_tab_curr].msgs[i].sender + '>' + ch_tabs[ch_tab_curr].msgs[i].raw ) + 10;
           if r.W > scr_w - 250 then  dH := 2 * fH else dH := fH;
           nH := nH + dH;
           r.W := text_GetWidth( fntChat, '<' + ch_tabs[ch_tab_curr].msgs[i].sender+ '>:' ) + 5;
           r.H := text_GetHeight( fntChat, r.W ,ch_tabs[ch_tab_curr].msgs[i].sender);
           ch_tabs[ch_tab_curr].msgs[i].sRect.X := 15;
           ch_tabs[ch_tab_curr].msgs[i].sRect.y := scr_h - 42 - nH;
           ch_tabs[ch_tab_curr].msgs[i].sRect.W := r.w;
           ch_tabs[ch_tab_curr].msgs[i].sRect.H := fH;
           if ch_tabs[ch_tab_curr].msgs[i].omo then
              pr2d_Rect( 15, scr_h - 42 - nH, r.W, r.H , $888888, 150, PR2D_FILL );
           text_DrawInRectEx ( fntChat, Rect( 15, scr_h - 42 - nH, r.W, fH), 1, 0,
                               '<' + ch_tabs[ch_tab_curr].msgs[i].sender + '>:',
                                255, $CCCCCC, TEXT_HALIGN_LEFT or TEXT_VALIGN_TOP );

           sW := r.W; // запоминаем ширину отправителя
           mW := 0;
           // теперь начинаем полексемно выводить сообщения...
           for j := 0 to 3 do
           if ch_tabs[ch_tab_curr].msgs[i].lexems[j].ToPrint <> '' then
              begin
                // перво наперво строим рект исходя из текста лексемы, который ToPrint
                // сначала длина и ширина
                ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W := 
                   text_GetWidth( fntChat, ch_tabs[ch_tab_curr].msgs[i].lexems[j].ToPrint ) + 5;
                if ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W > scr_w - 250 - sW then
                begin
                  ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W := scr_w - 250 - sW;
                  ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.H := fH * 2;
                end else
                   ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.H := fH;
                // теперь координаты. Если у нас первая лексем, то берём базовые
                if j = 0 then
                   begin
                     ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.X := 15 + sW;
                     ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.Y := scr_h - 42 - nH;
                     mW := ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W; // получаем ширину лексем в текущей строке
                   end else
                   begin
                     // добавляем ширину ещё одной, и смотрим че получается...
                     mW := mW + ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W;
                     if mW > scr_w - 250 then // если мы шире, то переносим на другую строку
                        begin
                          mW := ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W;;
                          ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.X := 15 + sW;
                          ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.Y := 
                            ch_tabs[ch_tab_curr].msgs[i].lexems[j - 1].rect.Y + fH;
                        end else
                        begin
                          ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.Y := ch_tabs[ch_tab_curr].msgs[i].lexems[j - 1].rect.Y;
                          ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.X :=
                            mW - ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W + 15 + sW;
                        end;
                   end;
                   if ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.X < 15 + sW then
                      begin
                        ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.X := 15 + sW;
                        mW := ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W;
                      end;

                if (ch_tabs[ch_tab_curr].msgs[i].lexems[j].lType <> 1111) and
                   (ch_tabs[ch_tab_curr].msgs[i].lexems[j].omo = true) then
                pr2d_Rect(  ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.X,
                            ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.Y,
                            ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W, 
                            ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.H, $888888, 150, PR2D_FILL ) ;


                if ch_tabs[ch_tab_curr].msgs[i].lexems[j].lType = 1 then
                   begin
                    case items[ch_tabs[ch_tab_curr].msgs[i].lexems[j].par1].data.rare of
                      1 : color := $AAAAAA; // Серенький
                      2 : color := $FFFFFF; // беленький
                      3 : color := $00FF00; // зелёненький
                      4 : color := $63CACA; // синенький
                      6 : color := $FF8000  // ОРАНЖЖЖЖ
                    else
                       color := $DD0000; //красный - ошипка;
                    end;
                   end else color := $CCCCCC;

                if ch_tabs[ch_tab_curr].msgs[i].lexems[j].lType = 2 then color := $a468d5;
                
                text_DrawInRectEx ( fntChat,
                                    Rect(ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.X,
                                         ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.Y,
                                         ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.W, 
                                         ch_tabs[ch_tab_curr].msgs[i].lexems[j].rect.H), 
                                    1, 0,
                                    ch_tabs[ch_tab_curr].msgs[i].lexems[j].ToPrint,
                                    255, color, TEXT_HALIGN_LEFT or TEXT_VALIGN_TOP );
             end;

         end;
 scissor_end;
end;

function Chat_AddMember(chID: byte; Nick : string; charID, clanID, klassID, lvl: Cardinal): byte;
var i, j: integer;
    b : boolean;
begin
  result := 1;
  for i := 0 to length(ch_tabs) - 1 do
      if ch_Tabs[i].exist then
      begin
         if ch_tabs[i].chID = chID then        // смотрим, включен ли у нас такой чат в принципе
            begin
              result := 100;
              for j := 0 to length(ch_tabs[i].Members) - 1 do
                if ch_tabs[i].Members[j].exist then   // теперь проверяем, может у нас уже есть такой мембер
                   if ch_tabs[i].Members[j].Nick = Nick then
                   begin
                     // такой мембер уже есть. выходим из функции и возвращаем
                     // код результата - 3
                     result := 3;
                     exit;
                   end;
              for j := 0 to length(ch_tabs[i].Members) - 1 do
                if not ch_tabs[i].Members[j].exist then   //подбираем место для нового мембера
                   begin
                     ch_tabs[i].Members[j].exist := true;
                     ch_tabs[i].Members[j].Nick := Nick;
                     ch_tabs[i].Members[j].charID := charID;
                     ch_tabs[i].Members[j].level := lvl;
                     ch_tabs[i].Members[j].Klass := klassID;
                     ch_tabs[i].Members[j].Clan := ClanID;
                     inc(ch_tabs[i].nMem);
                     result := 4;
                     exit; // всё в порядке, возвращаем 4
                   end;
              result := 2; // раз сюда пришли, значит что-то не то
            end else Log_Add( u_IntToStr( ch_tabs[i].chID ) + '<>'+ u_IntToStr( chID ));
      end else Log_Add( u_IntToStr( i * 1000));
end;

function Chat_AddTab(): byte;
var i : integer; n : utf8string;
begin
  result := 1;
  for i := 0 to length(ch_tabs) - 1 do
      if not ch_Tabs[i].exist then
         begin
           ch_Tabs[i].exist := true;
           case i of
             0 : n:= 'Global';
             1 : n:= 'Local';
             2 : n:= 'Private';
             3 : n:= 'System';
           else
             n := 'Test ' + u_IntToStr(i);
           end;
           ch_Tabs[i].Name := n;
           ch_Tabs[i].chID := i;
           inc(ch_tab_total);
           ch_tab_curr := 0;
           result := 2;
           Log_Add('Chat tab has been added in slot #' + u_IntToStr(i));
           exit;
         end;
end;

function Chat_ClearTabMembers(tab : byte): byte;
var j: integer;
begin
  if ch_tabs[tab].exist then
  for j := 0 to length(ch_tabs[tab].Members) - 1 do
      begin
        ch_tabs[tab].Members[j].exist := false;
        ch_tabs[tab].Members[j].Nick := 'No name';
        ch_tabs[tab].Members[j].charID := 0;
        ch_tabs[tab].Members[j].level := 0;
        ch_tabs[tab].Members[j].klass := 0;
        ch_tabs[tab].Members[j].Clan := 0;
      end;
end;

function Chat_AddMessage(chID: byte; sender, msg: string): byte;
var i, mID, flag: integer;
begin
  if not ch_tabs[chID].exist then exit;
  for i := 62 downto 0 do
      ch_tabs[chID].msgs[i + 1] := ch_tabs[chID].msgs[i];
  ch_tabs[chID].msgs[0].exist := true;
  ch_tabs[chID].msgs[0].sender := sender;
  ch_tabs[chID].msgs[0].raw := msg;
  ch_tabs[chID].nMsg := Chat_MsgNum(chID);
  Chat_ParseMessage(chID, 0);
  if ch_scroll_pos < 60/63 then
     ch_scroll_pos := ch_scroll_pos - 1/63;
  if ch_scroll_pos < 0 then ch_scroll_pos := 0;
end;

function Chat_ParseMessage(cID, mID : byte) : byte;
var s, c, l: UTF8String;
    Lex : array[0..3] of TLexeme;
    i, j, k: integer;
begin
  for i:=0 to 3 do
    begin
      Lex[i].par1:=0;
      Lex[i].par2:=0;
      Lex[i].par3:=0;
      Lex[i].lType:=0;
    end;
  s := ch_tabs[cID].msgs[mID].raw;
  k := 0;
     // сначала делим сообщение на лексемы
  for I := 1 to utf8_Length(s) do
    begin
       c := utf8_Copy( s, i, 1);
       if c <> '{' then l := l + c else
          begin
            if k > 3 then
               begin
                 Log_Add(' ----------> Error while parsing message! Break. ');
                 break;
               end;
       //     Log_add( ' Lex #' + u_IntToStr(k) + ' "' + l + '"');
            Lex[k].raw := l;
            inc(k);
            l := '';
          end;
    end;
  Lex[k].raw := l;
  // Log_add(' Lex #Last ' + l );
  // получили список лексем, теперь надо определить их тип
  // если первым знаком идёт ! - значит возможно это ссылка
  // и будем проверять формат дальше, если нет - просто слова. игнорим.
  // Образец {!:10:20:30:Sword of the Thousand Truths}{ первая скобка уже отсечена и сейчас её в лексемме нет
  // Look at {!:2:20:30:Mushroomas, the Sacred Mace of Awanross}{ It's so fkng awesome!!

  for I := 0 to 3 do
  begin
    Log_Add( utf8_Copy( lex[i].raw, 1, 1) );
      if (utf8_Copy( lex[i].raw, 1, 1) = '!') or (utf8_Copy( lex[i].raw, 1, 1) = '$') then
         if utf8_Copy( lex[i].raw, utf8_length( lex[i].raw ), 1 ) = '}' then
            begin   // нашли скобку в конце, теперь считаем двоеточия, должно быть 4
              k := 0;
              for j := 1 to utf8_Length(lex[i].raw ) do
                  begin 
                    c := utf8_copy(lex[i].raw, j , 1);
                    if c = ':' then inc(k);
                  end;
              if k = 4 then
                 begin
                   if (utf8_Copy( lex[i].raw, 1, 1) = '!') then lex[i].lType := 1;
                   if (utf8_Copy( lex[i].raw, 1, 1) = '$') then lex[i].lType := 2;
                 end;
            end else Log_Add('Missing }');
  end;

  // нашли ссылки, теперь из них нужно вытянуть параметры... всего их 3
  // а также непосредственно текст, который будет показан
for j := 0 to 3 do
if lex[j].lType > 0 then
begin
  l := ''; k := 0;
  for I := 1 to utf8_Length(s) do
    begin
       c := utf8_Copy( lex[j].raw, i, 1);
       if c <> ':' then l := l + c else
          begin
            if k > 3 then
               begin
                 Log_Add(' ----------> Error while parsing message! Break. ');
                 break;
               end;
     //       Log_add('>>>' + l );
            if k = 1 then lex[j].par1 := u_StrToInt(l);
            if k = 2 then lex[j].par2 := u_StrToInt(l);
            if k = 3 then lex[j].par3 := u_StrToInt(l);
            inc(k);
            l := '';
          end;
    end;
  Lex[j].ToPrint := '[' + utf8_copy( l, 1, utf8_length(l) - 1) + ']';
  Log_add( 'To Print: "' + l + '"' );
end else Lex[j].ToPrint := Lex[j].raw;

for I := 0 to 3 do
  ch_tabs[cID].msgs[mID].lexems[i] := lex[i]; // вписываем
  
end;

function Chat_MsgNum(chID: byte): byte;
var i, k: integer;
begin
  result := 0;
  k := 0;
  if ch_tabs[chID].exist then
     for i := 0 to length(ch_tabs[chID].msgs) - 1 do
       if ch_tabs[chID].msgs[i].exist then inc(k);
  result := k;
end;

function Chat_AddPrivate(Sender : UTF8String): byte;
begin
  if ch_message_inp then
     begin
       if utf8_Length(eChatFrame.Caption) < 70 then
          eChatFrame.Caption := eChatFrame.Caption + '@' + sender + ':';
       eChatFrame.Focus;
       eChatFrame.SelectAll;
       eChatFrame.DeleteSelection;
     end else
     begin
       ch_message_inp := true;
       Nonameframe38.Show;
       eChatFrame.Show;
       bChatSend.Show;
       eChatFrame.Caption := '@' + sender + ':';
       eChatFrame.Focus;
       echatFrame.SelectAll;
       eChatFrame.DeleteSelection;
     end;
end;

function Chat_CatchPrivte( msg: UTF8String ): UTF8String;
var i, k: integer; c, w : utf8string;
begin
 result := '';
 if utf8_copy( msg, 1, 1 ) <> '@' then exit; // нет ключевого знака - выходим

 for I := 2 to utf8_Length(msg) do
    begin
       c := utf8_Copy( msg, i, 1);
       if c <> ':' then w := w + c else   // нашли двоеточие, возвращаем ник и выходим
       begin
         result := w;
         exit;
       end;
    end;
 end;

function Chat_CheckMessage( msg: String): boolean;
var i: integer; s: String;
begin
  result := false; s:= msg;
  if Length( msg ) < 1 then exit;
     for i := 1 to Length( msg ) do
         if Copy( msg, i, 1) <> ' ' then
            begin
              if copy( msg, i, 1) = '`' then Delete( s, i, 1);
              result := true;
            end;
  eChatFrame.Caption := s;
end;

procedure Chat_SaveToFile;
var
  myFile : TextFile;
  text   : string;
  I,J      : integer;
  formattedDate : string;
begin
  // Попытка открыть Test.txt файл для записи
  LongTimeFormat := 'hh mm ss (zzz)';
  DateTimeToString(formattedDate, 'tt', Now);
  AssignFile(myFile, 'Saves\' + formattedDate + '.txt');
  Rewrite(myFile);

  // Запись нескольких известных слов в этот файл
  WriteLn(myFile, 'Chat Dump ', formattedDate);

  for i := 0 to 63 do
    begin
    //  WriteLn(MyFile, ch_tabs[ch_tab_curr].msgs[i].exist );
      WriteLn(MyFile, i, '.', ch_tabs[ch_tab_curr].msgs[i].sender, ' -> ', ch_tabs[ch_tab_curr].msgs[i].raw );
    {  WriteLn(MyFile, ch_tabs[ch_tab_curr].msgs[i].sRect.X, ' ', ch_tabs[ch_tab_curr].msgs[i].sRect.Y, ' ',
                      ch_tabs[ch_tab_curr].msgs[i].sRect.W, ' ', ch_tabs[ch_tab_curr].msgs[i].sRect.H);   }

      for j := 0 to 3 do
      begin
       { WriteLn(MyFile, j, '>>' ,ch_tabs[ch_tab_curr].msgs[i].lexems[j].ToPrint);
          WriteLn(MyFile, j, '......' ,ch_tabs[ch_tab_curr].msgs[i].lexems[j].par1);
          WriteLn(MyFile, j, '......' ,ch_tabs[ch_tab_curr].msgs[i].lexems[j].par2);
          WriteLn(MyFile, j, '......' ,ch_tabs[ch_tab_curr].msgs[i].lexems[j].par3);   }

      end;
    end;

  WriteLN(MyFile, 'Chat Dump - end' );


  // Закрытие файла в последний раз
  CloseFile(myFile);
end;

end.

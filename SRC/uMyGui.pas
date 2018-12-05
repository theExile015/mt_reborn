unit uMyGui;

{$mode delphi}
{$codepage utf8}

interface

uses
    zglHeader,
    uVar,
    uAdd,
    sysutils,
    // uParser,
    uXClick,
    dos;


function mgui_AddWindow( fType: integer; name : utf8string; rect : zglTRect) : byte;
function mgui_AddButton( Parent, TexID: byte; Caption : utf8string; rect: zglTRect) : byte;
function mgui_AddText( Parent, Orient: byte; Text: utf8string; rect: zglTRect; color: longword) : byte;
function mgui_AddImg( parent, iType: byte; rect : zglTRect; texID : utf8string) : byte;
function mgui_AddDnDSlot( parent, ddType, ddsub: byte; rect : zglTRect) : byte;
function mgui_AddPBar( parent, color : longword; rect : zglTRect) : byte;

procedure mgui_TTOpen( sender : longword );
procedure mgui_SetWinVis( p: integer; vis : boolean); inline;
procedure mgui_OnMouseClick( Parent, Sender : integer );

procedure MyGui_Draw();
procedure MyGui_Update();

procedure itt_Open(iID, ittType : longword);
procedure stt_Open( sID, sttType : longword);

procedure pum_Nick_open(sender : UTF8String);
procedure pum_Item_open(wID, sID: longword; sender : utf8string);
procedure pum_Close;

procedure dlg_Click(dType, dID : longword);

procedure mGui_Init;

implementation

uses uLocalization, u_MM_GUI, uChat, uLoader, uNetCore;

function mgui_AddWindow( fType : integer; name : utf8string; rect : zglTRect) : byte;
var i: integer;
begin
 result := 0;
 for i := 1 to high(mWins) do
   if not mWins[i].exist then
     begin
       mWins[i].exist:=true;
       mWins[i].visible:=true;
       mWins[i].fType:=fType;
       if not (mWins[i].fType in [1..3]) then mWins[i].fType := 1;
       mWins[i].rect := rect;
       mWins[i].Name:=name;
       result := i;
       break;
     end;
end;

function mgui_AddButton( Parent, TexID: byte; Caption : utf8string; rect: zglTRect) : byte;
var i: integer;
begin
  result := 0;
  // если вдруг такой формы не существует
  if not mWins[Parent].exist then
     begin
       Log_Add( '::: GUI ERROR ::: >>> Parent form #' + u_IntToStr(Parent) + ' doesn''t exist. BtnAdd ' + Caption);
       exit;
     end;
  for i := 1 to high(mWins[Parent].btns) do
    if not mWins[Parent].btns[i].exist then
       begin
         mWins[Parent].btns[i].exist:=true;
         mWins[Parent].btns[i].enabled:=true;
         mWins[Parent].btns[i].visible:=true;
         mWins[Parent].btns[i].texID:=TexID;
         mWins[Parent].btns[i].Caption:=Caption;
         mWins[Parent].btns[i].rect := rect;
         // на случай если рамка вдруг не определена, делаем её по кэпшену, в противном случае - аборт
         if (rect.W < 1) or (rect.H < 1) then
            begin
              if caption <> '' then
                 begin
                   mWins[Parent].btns[i].rect.W := Text_GetWidth( fntMain, Caption );
                   mWins[Parent].btns[i].rect.H := Text_GetHeight( fntMain, mWins[Parent].btns[i].rect.W, Caption);
                 end else
                 begin
                   mWins[Parent].btns[i].exist:=false;
                   Log_Add( '::: GUI ERROR ::: >>> Unable to set rect. BtnAdd ' + Caption);
                   exit
                 end;
            end;
         result := i;
         break;
       end;
end;

function mgui_AddText( Parent, Orient: byte; Text: utf8string; rect: zglTRect; color: longword) : byte;
var i: integer;
begin
  result := 0;
  // если вдруг такой формы не существует
  if not mWins[Parent].exist then
    begin
      Log_Add( '::: GUI ERROR ::: >>> Parent form #' + u_IntToStr(Parent) + ' doesn''t exist. TextAdd ' + Text);
      exit;
    end;
  for i:=1 to high(mWins[Parent].texts) do
    if not mWins[Parent].texts[i].exist then
      begin
        mWins[Parent].texts[i].exist := true;
        mWins[Parent].texts[i].visible:= true;
        mWins[Parent].texts[i].rect := rect;
        mWins[Parent].texts[i].Text:= Text;
        mWins[Parent].texts[i].color:=color;
        mWins[Parent].texts[i].center := Orient;
           // на случай если рамка вдруг не определена, делаем её по кэпшену, в противном случае - аборт
        if (rect.W < 1) or (rect.H < 1) then
            begin
              if text <> '' then
                 begin
                   mWins[Parent].texts[i].rect.W := Text_GetWidth( fntMain, text );
                   mWins[Parent].texts[i].rect.H := Text_GetHeight( fntMain, mWins[Parent].texts[i].rect.W, Text);
                   if Orient > 0 then
                      begin
                        mWins[Parent].texts[i].rect.W  := mWins[Parent].rect.W - frmPak[mWins[Parent].fType].w * 2;
                        mWins[Parent].texts[i].rect.H  := mWins[Parent].rect.H - frmPak[mWins[Parent].fType].w * 2;
                      end;
                 end else
                 begin
                   mWins[Parent].texts[i].exist:=false;
                   Log_Add( '::: GUI ERROR ::: >>> Unable to set rect. TextAdd ' + Text);
                   exit
                 end;
            end;
        result := i;
        break;
      end;
end;

function mgui_AddImg( parent, iType : byte; rect : zglTRect; texID : utf8string) : byte;
var i: integer;
begin
   result := 0;
  // если вдруг такой формы не существует
  if not mWins[Parent].exist then
    begin
      Log_Add( '::: GUI ERROR ::: >>> Parent form #' + u_IntToStr(Parent) + ' doesn''t exist. ImgAdd ');
      exit;
    end;
  for i:=1 to high(mWins[parent].imgs) do
    if not mWins[parent].imgs[i].exist then
       begin
         mWins[parent].imgs[i].exist:=true;
         mWins[parent].imgs[i].visible:=true;
         mWins[parent].imgs[i].iType:=iType;
         mWins[parent].imgs[i].texID:=texID;
         mWins[parent].imgs[i].rect:=rect;
         result := i;
         break;
       end;
end;

function mgui_AddDnDSlot( parent, ddType, ddsub: byte; rect : zglTRect) : byte;
var i: integer;
begin
  result := 0;
  // если вдруг такой формы не существует
  if not mWins[Parent].exist then
    begin
      Log_Add( '::: GUI ERROR ::: >>> Parent form #' + u_IntToStr(Parent) + ' doesn''t exist. DnDadd');
      exit;
    end;
  for i := 1 to high(mWins[parent].dnds) do
    if not mWins[parent].dnds[i].exist then
       begin
         mWins[parent].dnds[i].exist:=true;
         mWins[parent].dnds[i].visible:=true;
         mWins[parent].dnds[i].ddType:=ddType;
         mWins[parent].dnds[i].data.ddSubType:=ddsub;
         mWins[parent].dnds[i].x:=rect.X;
         mWins[parent].dnds[i].y:=rect.Y;
         break;
       end;
end;

function mgui_AddPBar( parent, color : longword; rect : zglTRect) : byte;
var i: integer;
begin
  result := 0;
  // если вдруг такой формы не существует
  if not mWins[Parent].exist then
    begin
      Log_Add( '::: GUI ERROR ::: >>> Parent form #' + u_IntToStr(Parent) + ' doesn''t exist. DnDadd');
      exit;
    end;
  for i := 1 to high(mWins[parent].pbs) do
    if not mWins[parent].pbs[i].exist then
       begin
         mWins[parent].pbs[i].exist := true;
         mWins[parent].pbs[i].visible:= true;
         mWins[parent].pbs[i].rect := rect;
         mWins[parent].pbs[i].color:= color;
         mWins[parent].pbs[i].cProg := random(1000)/1000;
         mWins[parent].pbs[i].mProg := 1;
         break;
       end;
end;

procedure mgui_SetWinVis( p: integer; vis : boolean); inline;
begin
  mWins[p].visible:=vis;
end;

procedure mGui_OnMouseClick( Parent, Sender : integer );
var i, j, k: integer; p: TProps;
begin
  if not mWins[parent].btns[sender].enabled then exit;

      // Кнопка Cancel (Ok) при статусе подключения
  if (parent = 17) and (sender = 3) then
     begin
       if TCP.FConnect then
          TCP.FCon.Disconnect(true);
       TCP.FConnect := false;
       cns := csDisc;
       Nonameform1.Enabled:=true;
       mWins[17].visible:=false;
     end;

  if (parent = 1) and (sender = 1) then
     begin
      { if mWins[17].Name <> '' then
          SendData(inline_pkgCompile(46, '0`' + mWins[17].Name + '`')); }
       mWins[17].Name:='';
       mWins[17].visible:=false;
       mWins[17].btns[1].visible:=false;
       mWins[17].btns[2].visible:=false;
     end;

  if (parent = 1) and (sender = 2) then
     begin
       {if mWins[17].Name <> '' then
          SendData(inline_pkgCompile(46, '1`' + mWins[17].Name + '`')); }
       mWins[17].Name:='';
       mWins[17].visible:=false;
       mWins[17].btns[1].visible:=false;
       mWins[17].btns[2].visible:=false;
     end;

  if (parent = 5) and (sender = 1) then
     igs := igsNone;

  if (parent = 6) and (sender = 1) then
     igs := igsNone;

  if (parent = 6) and (sender = 2) then
     sk_ta := sk_ta - 360/7;

  if (parent = 6) and (sender = 3) then
     sk_zoom := not sk_zoom;

  if (parent = 6) and (sender = 4) then
     sk_ta := sk_ta + 360/7;

  if (parent = 6) and (sender >= 5) and (sender <=10) then
     if activechar.Numbers.SP > 0 then
       // SendData(inline_PkgCompile(50, activechar.Name + '`' + u_IntToStr(sender - 5) + '`'))
     else
        Chat_AddMessage(3, 'S', 'Not enough SP to increase.');

  if (parent = 6) and (sender = 11) then stat_tab := 0;
  if (parent = 6) and (sender = 12) then stat_tab := 1;
  if (parent = 6) and (sender = 13) then stat_tab := 2;

  if (parent = 5) and (sender = 2) then stat_tab := 0;
  if (parent = 5) and (sender = 3) then stat_tab := 1;
  if (parent = 5) and (sender = 4) then stat_tab := 2;

  if (parent = 8) and (sender = 1) then
     begin
       mWins[8].visible:=false;
       mWins[7].visible:=true;
     end;

 { if (parent = 8) and (sender = 2) then
  //if not qlog_QAccepted( u_StrToInt(mWins[8].Name) ) then
  if mWins[8].flag = 0 then
     begin
       // Переводим счётчит обучения.
       if (mWins[8].Name = '12') and (tutorial = 1) then
          begin
            tutorial := 2;
            // SendData(inline_PkgCompile(4, activechar.Name + '`2`'));
          end;

       k := 0;
       for i := 1 to high(quest_log) do
         if quest_log[i].exist then inc(k) else
            begin
              quest_log[i].exist:=true;
              quest_log[i].qID:=u_StrToInt(mWins[8].Name);
              quest_log[i].Name:=mWins[8].texts[1].Text;
              quest_log[i].Descr:=mWins[8].texts[3].Text;
              quest_log[i].Obj:=mWins[8].texts[5].Text;
              quest_log[i].Reward:=mWins[8].texts[45].Text;
              quest_log[i].qpID:=mWins[8].imgs[1].texID;
              inc(k);
              break;
            end;
       if k = high(quest_log) then
          begin
            gui.ShowMessage('', 'Your questlog is full.');
            exit;
          end else
          begin
            SendData(inline_pkgCompile(22, mWins[8].Name + '`1`'));
            mWins[8].visible:=false;
            Chat_AddMessage(ch_tab_curr, 'S', 'Quest "' + Utf8ToAnsi(quest_log[k].Name) + '" accepted.');
            qlog_save();
            igs := igsNone;
          end;
     end else
     begin
       j := 0; k := 0;
       for i := 6 to 10 do
         if mWins[8].dnds[i].exist then
            if mWins[8].dnds[i].contains > 0 then inc(k);
       //Chat_AddMessage(ch_tab_curr, '', u_IntToStr(j));
       //k := j;
       if k > 0 then
       begin
          for i:=6 to 10 do
            if mWins[8].dnds[i].exist then
               if mWins[8].dnds[i].selected then j := i;
          if (k > 0) and (j = 0) then
             begin
               Chat_AddMessage(ch_tab_curr,'S', 'Choose reward first.');
               Exit;
             end;
       end;

         // Переводим счётчит обучения.
       if (mWins[8].Name = '2') and (tutorial = 4) then
          begin
            tutorial := 5;
            // SendData(inline_PkgCompile(4, activechar.Name + '`5`'));
            sleep(50);
          end;

       SendData(inline_pkgCompile(22, mWins[8].Name + '`2`' + u_IntToStr(j - 2) + '`'));
       Chat_AddMessage(ch_tab_curr, 'S', 'Quest "' + quest_log[qlog_GetQLID(u_StrToInt(mWins[8].Name))].Name + '" completed.' );
       quest_log[qlog_GetQLID(u_StrToInt(mWins[8].Name))].exist:=false;
       qlog_save();
       Sleep(50);
       mWins[8].visible:=false;
       igs := igsNone;
     end;  }

  if (parent = 9) and (sender = 1) then
     igs := igsNone;
  if (parent = 11) and (sender = 1) then
     igs := igsNone;
  if (parent = 12) and (sender = 1) then
     igs := igsNone;

  if (parent = 14) and (sender = 1) then
     begin
       igs := igsNone;
       mWins[14].visible:=false;
     end;
end;

procedure MyGui_Draw();
var i, j, k  : integer;
    frame : byte;
    FLAG, color : longword;
    dx, dy : single;
    s : utf8string;
    hh, mm, ss, ms : word;
    _tex : zglPTexture;
begin

 // отрисовка портрета инфы на локации
 if (gs = gsGame) and (iga = igaLoc) then
     begin
       mWins[15].visible:=true;
       mWins[16].visible:=false;
       mWins[15].pbs[3].visible:=false;
       mWins[15].pbs[4].visible:=false;
       mWins[15].imgs[2].visible:=true;
       mWins[15].imgs[3].visible:=true;
       mWins[15].texts[1].visible:=true;
       mWins[15].texts[2].visible:=true;
       mWins[15].texts[3].Text:=activechar.header.Name;
       mWins[15].pbs[1].cProg:=activechar.hpmp.cHP;
       mWins[15].pbs[1].mProg:=activechar.hpmp.mHP;
       mWins[15].pbs[2].mProg:=activechar.hpmp.mMP;
       mWins[15].pbs[2].cProg:=activechar.hpmp.cMP;
       mWins[15].texts[1].Text:=u_IntToStr(activechar.Numbers.gold);
       mWins[15].texts[2].Text:=u_FloatToStr(activechar.Numbers.exp / exp_cap[activechar.header.level + 1] * 100) + '%';
       mWins[15].imgs[1].texID:= 'ava' + u_IntToStr((activechar.header.raceID - 1) * 2 + activechar.header.sex + 1);
     end else
     if iga <> igaCombat then
        begin
           mWins[15].visible:=false; mWins[16].visible:=false;
        end;

 // отрисовка гуя
 for i := high(mWins) downto 1 do
   if mWins[i].exist and mWins[i].visible then
     begin
         if mWins[i].fType = 1 then frame := 255 else frame := 210;
         pr2d_Rect(mWins[i].rect.X + 3, mWins[i].rect.Y + 3, mWins[i].rect.W - 6, mWins[i].rect.H - 6,
                   frmPak[mWins[i].fType].bgr_color , frame, PR2D_FILL );
         // горизонтальные границы формы
     Scissor_Begin(round(mWins[i].rect.X + frmPak[mWins[i].fType].c), round(mWins[i].rect.Y),
                   round(mWins[i].rect.W - 2 * frmPak[mWins[i].fType].c), round(mWins[i].rect.H));
         for j := 0 to trunc(mWins[i].rect.W / frmPak[mWins[i].fType].w) do
           begin
             SSprite2d_Draw( frmPak[mWins[i].fType].brd, mWins[i].rect.X + frmPak[mWins[i].fType].c + j * frmPak[mWins[i].fType].h,
                             mWins[i].rect.Y - frmPak[mWins[i].fType].dy,
                             frmPak[mWins[i].fType].w, frmPak[mWins[i].fType].h, 90);
             SSprite2d_Draw( frmPak[mWins[i].fType].brd, mWins[i].rect.X + frmPak[mWins[i].fType].c + j * frmPak[mWins[i].fType].h,
                             mWins[i].rect.Y - frmPak[mWins[i].fType].dy - frmPak[mWins[i].fType].dy2 + mWins[i].rect.H,
                             frmPak[mWins[i].fType].w, frmPak[mWins[i].fType].h, 90, 255, FX2D_FLIPX );
           end;
     Scissor_End();
         // вертикальные границы формы
     Scissor_Begin(round(mWins[i].rect.X), round(mWins[i].rect.Y + frmPak[mWins[i].fType].c),
                   round(mWins[i].rect.W), round(mWins[i].rect.H - 2 * frmPak[mWins[i].fType].c));
         for j := 0 to trunc(mWins[i].rect.H / frmPak[mWins[i].fType].h) do
           begin
             SSprite2d_Draw( frmPak[mWins[i].fType].brd, mWins[i].rect.X,
                             mWins[i].rect.Y + frmPak[mWins[i].fType].c + j * frmPak[mWins[i].fType].h ,
                             frmPak[mWins[i].fType].w, frmPak[mWins[i].fType].h, 0);
             SSprite2d_Draw( frmPak[mWins[i].fType].brd, mWins[i].rect.X + mWins[i].rect.W - frmPak[mWins[i].fType].w,
                             mWins[i].rect.Y + frmPak[mWins[i].fType].c + j * frmPak[mWins[i].fType].h ,
                             frmPak[mWins[i].fType].w, frmPak[mWins[i].fType].h, 180, 255);
           end;
     Scissor_End();

         // углы
         SSprite2d_Draw( frmPak[mWins[i].fType].crn, mWins[i].rect.X,
                         mWins[i].rect.Y,
                         frmPak[mWins[i].fType].c, frmPak[mWins[i].fType].c, 0);
         SSprite2d_Draw( frmPak[mWins[i].fType].crn, mWins[i].rect.X + mWins[i].rect.W - frmPak[mWins[i].fType].c,
                         mWins[i].rect.Y,
                         frmPak[mWins[i].fType].c, frmPak[mWins[i].fType].c, 90);
         SSprite2d_Draw( frmPak[mWins[i].fType].crn, mWins[i].rect.X,
                         mWins[i].rect.Y  + mWins[i].rect.H - frmPak[mWins[i].fType].c,
                         frmPak[mWins[i].fType].c, frmPak[mWins[i].fType].c, -90);
         SSprite2d_Draw( frmPak[mWins[i].fType].crn, mWins[i].rect.X  + mWins[i].rect.W - frmPak[mWins[i].fType].c,
                         mWins[i].rect.Y  + mWins[i].rect.H - frmPak[mWins[i].fType].c,
                         frmPak[mWins[i].fType].c, frmPak[mWins[i].fType].c, 180);
          // отрисовка карты
         if mWins[i].Name = 'Map' then
            begin
              Scissor_Begin( round(mWins[i].rect.X + 24), round(mWins[i].rect.Y + 24), 352, 352);
                dx := locs[activechar.header.loc].x - 200;
                dy := locs[activechar.header.loc].y - 200;
                if dx < 0 then dx := 0;
                if dy < 0 then dy := 0;
                Text_draw( fntMain, mWins[i].rect.X + 20, mWins[i].rect.Y + 20, u_FloatToStr(dx) + ' ' + u_FloatToStr(dy));
                SSprite2d_Draw( tex_WMap, mWins[i].rect.X - dx, mWins[i].rect.Y - dy, tex_WMap.Width / 1.5, tex_WMap.Height / 1.5, 0);
                for j := 1 to high(locs) do
                  if locs[j].exist then
                  begin
                     for k := 1 to 25 do
                       if locs[j].links[k] <> 0 then
                          if locs[locs[j].links[k]].exist then
                             pr2d_line( mWins[i].rect.X + locs[j].x - dx,
                                        mWins[i].rect.Y + locs[j].y - dy,
                                        mWins[i].rect.X + locs[locs[j].links[k]].x - dx,
                                        mWins[i].rect.Y + locs[locs[j].links[k]].y - dy, $00AA00, 200);
                     if col2d_PointInRect( mouse_X, mouse_Y, rect(mWins[i].rect.X + locs[j].x - dx - 24, mWins[i].rect.Y + locs[j].y - dy - 24, 48, 48)) then
                        begin
                          FLAG := FX_BLEND or FX_COLOR;
                          if mouse_click(M_BLEFT) then
                          if j <> activechar.header.loc then
                             begin
                              { SendData(inline_pkgCompile(42, u_IntToStr(activechar.ID) + '`' + u_IntToStr(j) + '`'));
                              }
                             end;
                        end else FLAG := FX_BLEND;
                     fx2d_SetColor($f0ac34);
                     ASprite2d_Draw( tex_map_locs, mWins[i].rect.X + locs[j].x - dx - 24, mWins[i].rect.Y + locs[j].y - dy - 24, 48, 48, 0, locs[j].pic, 255, FLAG);
                     if activechar.header.loc = j then color := $f0ac34 else color := $dddddd;
                     Text_DrawEx( fntMain, mWins[i].rect.X + locs[j].x - text_GetWidth(fntMain, locs[j].name) / 2 - dx,
                               mWins[i].rect.y + locs[j].y + 1 - dy + 20, 1, 0, locs[j].name, 255, color);
                  end;
                Scissor_End();
            end;


         // отрисовка кнопок
         for j := 1 to high(mWins[i].btns) do
           if mWins[i].btns[j].exist and mWins[i].btns[j].visible then
           if mWins[i].btns[j].texID > 0 then
             begin
               frame := 1;
               if mWins[i].btns[j].OMO then frame := 2;
               if mWins[i].btns[j].OMD then frame := 3;
               if not mWins[i].btns[j].enabled then frame := 4;

               ASprite2D_Draw(tex_IBtn[mWins[i].btns[j].texID],
                              mWins[i].rect.X + mWins[i].btns[j].rect.X + frmPak[mWins[i].fType].w,
                              mWins[i].rect.Y + mWins[i].btns[j].rect.Y + frmPak[mWins[i].fType].w,
                              mWins[i].btns[j].rect.W, mWins[i].btns[j].rect.H, 0,
                              frame);
               Text_DrawInRectEx( fntMain, rect( mWins[i].rect.X + mWins[i].btns[j].rect.X + frmPak[mWins[i].fType].w,
                                  mWins[i].rect.Y + mWins[i].btns[j].rect.Y + frmPak[mWins[i].fType].w,
                                  mWins[i].btns[j].rect.W, mWins[i].btns[j].rect.H), 1, 0,
                                  mWins[i].btns[j].Caption, 255, $1351D7,
                                  TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER );
             end else
             begin
               frame := 4;
               if mWins[i].btns[j].OMO then frame := 1;
               if mWins[i].btns[j].OMD then frame := 2;
               if not mWins[i].btns[j].enabled then frame := 3;
               for k := 0 to trunc( (mWins[i].btns[j].rect.W - 48 ) / 24 ) do
                   ASprite2D_Draw( tex_Btn,
                                   mWins[i].rect.X + mWins[i].btns[j].rect.X + frmPak[mWins[i].fType].w + 24 * (k+1),
                                   mWins[i].rect.Y + mWins[i].btns[j].rect.Y + frmPak[mWins[i].fType].w,
                                   24, mWins[i].btns[j].rect.H, 0,
                                   2 + (frame - 1)*3);

               ASprite2D_Draw( tex_Btn,
                               mWins[i].rect.X + mWins[i].btns[j].rect.X + frmPak[mWins[i].fType].w,
                               mWins[i].rect.Y + mWins[i].btns[j].rect.Y + frmPak[mWins[i].fType].w,
                               24, mWins[i].btns[j].rect.H, 0,
                               1 + (frame - 1)*3);
               ASprite2D_Draw( tex_Btn,
                               mWins[i].rect.X + mWins[i].btns[j].rect.X + frmPak[mWins[i].fType].w + mWins[i].btns[j].rect.W - 24,
                               mWins[i].rect.Y + mWins[i].btns[j].rect.Y + frmPak[mWins[i].fType].w,
                               24, mWins[i].btns[j].rect.H, 0,
                               3 + (frame - 1)*3);

               Text_DrawInRectEx( fntMain2, rect( mWins[i].rect.X + mWins[i].btns[j].rect.X + frmPak[mWins[i].fType].w,
                                  mWins[i].rect.Y + mWins[i].btns[j].rect.Y + frmPak[mWins[i].fType].w,
                                  mWins[i].btns[j].rect.W, mWins[i].btns[j].rect.H), 1, 0,
                                  mWins[i].btns[j].Caption, 255, $DDDDDD,
                                  TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER );
             end;
         // отрисовка прогресс баров
         for j := 1 to high(mWins[i].pbs) do
             if mWins[i].pbs[j].exist and mWins[i].pbs[j].visible then
                begin
                  fx2d_SetColor(mWins[i].pbs[j].color);
                  Scissor_Begin( round(mWins[i].rect.X + mWins[i].pbs[j].rect.X), round(mWins[i].rect.Y + mWins[i].pbs[j].rect.Y),
                                 round(mWins[i].pbs[j].rect.W * mWins[i].pbs[j].cProg/mWins[i].pbs[j].mProg), round(mWins[i].pbs[j].rect.H));
                    SSprite2d_draw(tex_PBar[3], mWins[i].rect.X + mWins[i].pbs[j].rect.X,   // левая
                                                mWins[i].rect.Y + mWins[i].pbs[j].rect.Y,
                                                8, mWins[i].pbs[j].rect.H, 0, 255, FX_BLEND or FX_COLOR);
                    SSprite2d_draw(tex_PBar[3], mWins[i].rect.X + mWins[i].pbs[j].rect.X + mWins[i].pbs[j].rect.W - 8,
                                                mWins[i].rect.Y + mWins[i].pbs[j].rect.Y,    // правая
                                                8, mWins[i].pbs[j].rect.H, 0, 255, FX2D_FLIPX or FX_BLEND or FX_COLOR);
                    SSprite2d_draw(tex_PBar[4], mWins[i].rect.X + mWins[i].pbs[j].rect.X + 8,  // центр
                                                mWins[i].rect.Y + mWins[i].pbs[j].rect.Y,
                                                mWins[i].pbs[j].rect.W - 16 , mWins[i].pbs[j].rect.H, 0, 255, FX_BLEND or FX_COLOR);
                  Scissor_End();
                  SSprite2d_draw(tex_PBar[1], mWins[i].rect.X + mWins[i].pbs[j].rect.X,   // левая
                                              mWins[i].rect.Y + mWins[i].pbs[j].rect.Y,
                                              8, mWins[i].pbs[j].rect.H, 0, 255);
                  SSprite2d_draw(tex_PBar[1], mWins[i].rect.X + mWins[i].pbs[j].rect.X + mWins[i].pbs[j].rect.W - 8,
                                              mWins[i].rect.Y + mWins[i].pbs[j].rect.Y,    // правая
                                              8, mWins[i].pbs[j].rect.H, 0, 255, FX2D_FLIPX);
                  SSprite2d_draw(tex_PBar[2], mWins[i].rect.X + mWins[i].pbs[j].rect.X + 8,  // центр
                                              mWins[i].rect.Y + mWins[i].pbs[j].rect.Y,
                                              mWins[i].pbs[j].rect.W - 16 , mWins[i].pbs[j].rect.H, 0, 255);

                  mWins[i].pbs[j].text:= u_FloatToStr(mWins[i].pbs[j].cProg, 0) + '/' + u_FloatToStr(mWins[i].pbs[j].mProg, 0);
                  Text_DrawInRect( fntChat, rect(mWins[i].rect.X + mWins[i].pbs[j].rect.X,
                                                 mWins[i].rect.Y + mWins[i].pbs[j].rect.Y + 2,
                                                 mWins[i].pbs[j].rect.W, mWins[i].pbs[j].rect.H), mWins[i].pbs[j].text, TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER );
                end;

         // отрисовка текстов
         for j := 1 to high(mWins[i].texts) do
           if mWins[i].texts[j].exist and mWins[i].texts[j].visible then
             begin

               scissor_begin( round(mWins[i].rect.X + mWins[i].texts[j].rect.X + frmPak[mWins[i].fType].w),
                              round(mWins[i].rect.Y + mWins[i].texts[j].rect.Y + frmPak[mWins[i].fType].w),
                              round(mWins[i].texts[j].rect.W), round(mWins[i].texts[j].rect.H));
               FLAG := TEXT_HALIGN_JUSTIFY or TEXT_VALIGN_TOP;
               if mWins[i].texts[j].center = 1 then FLAG := TEXT_HALIGN_CENTER or TEXT_VALIGN_CENTER;
               if mWins[i].texts[j].center = 2 then FLAG := TEXT_HALIGN_RIGHT or TEXT_VALIGN_TOP;

               if (Text_GetWidth(fntMain, mWins[i].texts[j].Text) > mWins[i].texts[j].rect.W - 5) and
                  (Text_GetHeight(fntMain, mWins[i].texts[j].rect.W, mWins[i].texts[j].Text) > mWins[i].texts[j].rect.H) then
                  begin
                    for k := 1 to utf8_length(mWins[i].texts[j].Text) do
                      begin
                        s := utf8_copy(mWins[i].texts[j].Text, 1, k) + '...';
                        if Text_GetWidth( fntMain, s, 0 ) >= mWins[i].texts[j].rect.W - 5 then
                           begin
                             s :=  utf8_copy(mWins[i].texts[j].Text, 1, k - 1) + '...';
                             break;
                           end;
                      end;
                  end else s := mWins[i].texts[j].Text;

               Text_DrawInRectEx( fntMain2, rect( mWins[i].rect.X + mWins[i].texts[j].rect.X + frmPak[mWins[i].fType].w,
                                  mWins[i].rect.Y + mWins[i].texts[j].rect.Y + frmPak[mWins[i].fType].w,
                                  mWins[i].texts[j].rect.W, mWins[i].texts[j].rect.H), 1, 0,
                                  s, 255, mWins[i].texts[j].color,
                                  FLAG );
               Scissor_End();
               // Отрисовка ограничивающей рамки (debug)
            {  pr2d_rect(  mWins[i].rect.X + mWins[i].texts[j].rect.X + frmPak[mWins[i].fType].w,
                                  mWins[i].rect.Y + mWins[i].texts[j].rect.Y + frmPak[mWins[i].fType].w,
                                  mWins[i].texts[j].rect.W, mWins[i].texts[j].rect.H , $00FF00);  }
             end;
         // отрисовка рисунков
         for j := 1 to high(mWins[i].imgs) do
           if mWins[i].imgs[j].exist and mWins[i].imgs[j].visible then
              begin
            //    fx2d_S
              //  if mWins[i].imgs[j].iType = 1 then
                   _tex := GetTex(mWins[i].imgs[j].texID);
                   tex_SetMask( _tex, tex_qMask[mWins[i].imgs[j].maskID]);
                   SSprite2d_Draw( GetTex(mWins[i].imgs[j].texID),
                                   mWins[i].rect.X + mWins[i].imgs[j].rect.X + frmPak[mWins[i].fType].w,
                                   mWins[i].rect.Y + mWins[i].imgs[j].rect.Y + frmPak[mWins[i].fType].w,
                                   mWins[i].imgs[j].rect.W, mWins[i].imgs[j].rect.H, 0);
                 {  SSprite2d_Draw( tex_qPic[mWins[i].imgs[j].texID],
                                   mWins[i].rect.X + mWins[i].imgs[j].rect.X + frmPak[mWins[i].fType].w,
                                   mWins[i].rect.Y + mWins[i].imgs[j].rect.Y + frmPak[mWins[i].fType].w,
                                   mWins[i].imgs[j].rect.W, mWins[i].imgs[j].rect.H, 0, 255) }
              end;
         // отрисовка колеса умений
         if i = 6 then
         begin
           pr2d_rect(mWins[6].rect.X + 195, mWins[6].rect.Y + 45, 355, 355, $555555, 200);
           Scissor_Begin( round(mWins[6].rect.X + 195), round(mWins[6].rect.Y + 45), 355, 355 );

           SSprite2D_Draw( tex_Skills, mWins[6].rect.X + sk_x, mWins[6].rect.Y + sk_y, sk_w, sk_h, sk_a);

           for j := 1 to high(skills) do
             if skills[j].exist then
             begin
                ASprite2D_Draw(tex_Item_Slots,
                               mWins[6].rect.X + sk_x + sk_w / 2 - 7 * sk_z + sk_z * skills[j].dist * m_cos(round(skills[j].school * 360 / 7 + skills[j].ang + sk_a)),
                               mWins[6].rect.Y + sk_y + sk_h / 2 - 7 * sk_z + sk_z * skills[j].dist * m_sin(round(skills[j].school * 360 / 7 + skills[j].ang + sk_a)),
                               14 * sk_z, 14 * sk_z, 0, 6);
                fx2d_SetColor($444444);
                if skills[j].enabled then FLAG := FX_BLEND else FLAG := FX_BLEND or FX_COLOR;
                SSprite2d_Draw(GetTex('i' + u_IntToStr(25 + skills[j].school) + ',' + u_IntToStr(skills[j].iID)),
                               1 + mWins[6].rect.X + sk_x + sk_w / 2 - 7 * sk_z + sk_z * skills[j].dist * m_cos(round(skills[j].school * 360 / 7 + skills[j].ang + sk_a)),
                               1 + mWins[6].rect.Y + sk_y + sk_h / 2 - 7 * sk_z + sk_z * skills[j].dist * m_sin(round(skills[j].school * 360 / 7 + skills[j].ang + sk_a)),
                               13 * sk_z, 13 * sk_z, 0, 255, flag);
                if sk_zoom then
                Text_draw(fntMain,
                          1 + mWins[6].rect.X + sk_x + sk_w / 2 - 7 * sk_z + sk_z * skills[j].dist * m_cos(round(skills[j].school * 360 / 7 + skills[j].ang + sk_a)),
                          1 + mWins[6].rect.Y + sk_y + sk_h / 2 - 7 * sk_z + sk_z * skills[j].dist * m_sin(round(skills[j].school * 360 / 7 + skills[j].ang + sk_a)),
                          u_IntToStr(skills[j].rank) );

             end;
          end;
         // отрисовка диалоговых вариантов
        // if i = 7 then
        Scissor_Begin( round(mWins[i].rect.X + 25 ),  round(mWins[i].rect.Y + 25 ),  round(mWins[i].rect.W - 50 ),  round(mWins[i].rect.H - 50 ));
        for j := 1 to high(mWins[i].dlgs) do
           if mWins[i].dlgs[j].exist then
              begin
                if mWins[i].dlgs[j].omo then
                   pr2d_rect(mWins[i].rect.X + 25, mWins[i].rect.Y + mWins[i].dlgs[j].dy - 1, mWins[i].rect.W - 50, 18, $888877, 150, pr2d_fill);

                ASprite2d_Draw( tex_LocIcons, mWins[i].rect.X + 30, mWins[i].rect.Y + mWins[i].dlgs[j].dy,
                                16, 16, 0, mWins[i].dlgs[j].dType, 255 );
                Text_DrawEx(fntMain2, mWins[i].rect.X + 55, mWins[i].rect.Y + mWins[i].dlgs[j].dy + 2,
                            1, 0, mWins[i].dlgs[j].text, 255, $e09c24);
              end;
        Scissor_End();

         // отрисовка элементов драг'н'дроп
         for j := 1 to high(mWins[i].dnds) do
           if mWins[i].dnds[j].exist and mWins[i].dnds[j].visible then
              begin
                if on_DD then
                   begin
                     if (ddItem.data.ddSubType = mWins[i].dnds[j].data.ddSubType) or (mWins[i].dnds[j].data.ddSubType = 6) then
                         fx2d_SetColor($00CC00)
                     else
                         fx2d_SetColor($CC0000);
                     if mWins[i].dnds[j].data.contain > 0 then fx2d_SetColor($CC0000);
                     FLAG := FX_BLEND or FX_COLOR;
                     if mWins[i].dnds[j].omo then
                        fx2d_SetColor($CCCC00);
                   end else FLAG := FX_BLEND;

                if mWins[i].dnds[j].data.contain > 0 then frame := 6 else frame := mWins[i].dnds[j].data.ddSubType;

                ASprite2d_Draw( tex_Item_Slots, mWins[i].rect.X + frmPak[mWins[i].fType].w + mWins[i].dnds[j].x,
                                mWins[i].rect.Y + frmPak[mWins[i].fType].w + mWins[i].dnds[j].y, 32, 32, 0,
                                frame, 255, FLAG );

                if mWins[i].dnds[j].ddType = 1 then fx2d_SetColor($CC0000);
                if items[mWins[i].dnds[j].data.contain].data.props[3] > activechar.header.level then
                   FLAG := FX_BLEND or FX_COLOR
                else
                   FLAG := FX_BLEND;

                if (mWins[i].dnds[j].ddType = 3) and (mWins[i].dnds[j].selected) then
                   begin
                     FLAG := FX_BLEND or FX_COLOR;
                     fx2d_SetColor($DD7700);
                   end;

                if (mWins[i].dnds[j].ddType = 1) or (mWins[i].dnds[j].ddType = 3) or (mWins[i].dnds[j].ddType = 4) or (mWins[i].dnds[j].ddType = 5) then
                begin
                   if mWins[i].dnds[j].data.contain > 0 then
                      if Items[mWins[i].dnds[j].data.contain].data.ID > 0 then
                                 // tex_Items[items[mWins[i].dnds[j].contains].iType, items[mWins[i].dnds[j].contains].iID]
                         SSprite2d_Draw( GetTex('i' + IntToStr(items[mWins[i].dnds[j].data.contain].data.iType) + ',' + IntToStr(items[mWins[i].dnds[j].data.contain].data.iID)),
                                         mWins[i].rect.X + frmPak[mWins[i].fType].w + mWins[i].dnds[j].x,
                                         mWins[i].rect.Y + frmPak[mWins[i].fType].w + mWins[i].dnds[j].y, 32, 32, 0, 255, FLAG)
                      else
                         SSprite2d_Draw( tex_UnkItem,
                                         mWins[i].rect.X + frmPak[mWins[i].fType].w + mWins[i].dnds[j].x,
                                         mWins[i].rect.Y + frmPak[mWins[i].fType].w + mWins[i].dnds[j].y, 32, 32, 0, 210, FLAG);

                   if mWins[i].dnds[j].data.contain = 0 then
                      if mWins[i].dnds[j].ddType = 4 then
                         SSprite2d_Draw( tex_Belt,
                                         mWins[i].rect.X + frmPak[mWins[i].fType].w + mWins[i].dnds[j].x,
                                         mWins[i].rect.Y + frmPak[mWins[i].fType].w + mWins[i].dnds[j].y, 32, 32, 0, 210, FLAG);

                   if mWins[i].dnds[j].data.contain = 0 then
                      if mWins[i].dnds[j].ddType = 5 then
                         SSprite2d_Draw( tex_Chest,
                                         mWins[i].rect.X + frmPak[mWins[i].fType].w + mWins[i].dnds[j].x,
                                         mWins[i].rect.Y + frmPak[mWins[i].fType].w + mWins[i].dnds[j].y, 32, 32, 0, 210, FLAG);

                end else
                     if mWins[i].dnds[j].data.contain > 0 then
                     if Spells[mWins[i].dnds[j].data.contain].ID > 0 then
                         SSprite2d_Draw( GetTex('i33,' + u_IntToStr(Spells[mWins[i].dnds[j].data.contain].iID)),
                                         mWins[i].rect.X + frmPak[mWins[i].fType].w + mWins[i].dnds[j].x,
                                         mWins[i].rect.Y + frmPak[mWins[i].fType].w + mWins[i].dnds[j].y, 32, 32, 0, 255, FX_BLEND) ;

                if Items[mWins[i].dnds[j].data.contain].data.iType > 21 then
                   if mWins[i].dnds[j].data.dur > 0 then
                      begin
                         text_Draw( fntMain, mWins[i].rect.X + frmPak[mWins[i].fType].w + mWins[i].dnds[j].x + 32 - Text_GetWidth(fntMain, u_IntToStr(mWins[i].dnds[j].data.dur)),
                                    mWins[i].rect.Y + frmPak[mWins[i].fType].w + mWins[i].dnds[j].y + 18, u_IntToStr(mWins[i].dnds[j].data.dur) );
                      end;
              end;

       Scissor_End;
     end;

  if on_DD then
     begin
       ASprite2d_Draw( tex_Item_Slots, Mouse_X, Mouse_Y, 32, 32, 0, 6);
       SSprite2d_Draw( GetTex('i'+ u_IntToStr(Items[ddItem.data.contain].data.iType) + ',' + u_IntToStr(Items[ddItem.data.contain].data.iID)), Mouse_X, Mouse_Y, 32, 32, 0);

      // Text_Draw(fntMain, Mouse_X + 40, Mouse_Y, u_IntToStr(ddItem.contains));
     //  Text_Draw(fntMain, Mouse_X + 40, Mouse_Y + 10, u_IntToStr(dditem.ddSubType));
     end;


        // отрисовка выпадающего меню
  if puMenu.exist then
     begin
       // сначала рисуем базовый прямоугольник
       pr2d_rect( puMenu.rect.X, puMenu.rect.Y, puMenu.rect.W, puMenu.rect.H,
                  $AAAAAA, 200, PR2D_FILL );
       // теперь нужно подсветить элементы, которые под мышкой и написать текст
       for i := 0 to 9 do
       begin
         if puMenu.elements[i].exist and puMenu.elements[i].omo then
            pr2d_rect( puMenu.elements[i].rect.X + 1  , puMenu.elements[i].rect.Y + 1,
                       puMenu.rect.W - 2, puMenu.elements[i].rect.H - 2,
                       $4444DD, 200, PR2D_FILL);
         if puMenu.elements[i].enable then Color := $EEEEEE else Color := $999999;
         if puMenu.elements[i].exist then
            text_DrawInRectEx( fntMain2, puMenu.elements[i].rect, 1, 0,
                               puMenu.elements[i].Text, 255, color );
       end;

     end;

  if mWins[1].visible then
     begin
       case tutorial of
         1: if mWins[1].visible then ASprite2D_Draw(tex_arr_point, mWins[1].rect.X + mWins[1].rect.W - 15, mWins[1].rect.Y - 5, 50, 50, 180, tut_frame, 255);
         2: if mWins[1].visible then ASprite2D_Draw(tex_arr_point, mWins[1].rect.X - 35, mWins[1].rect.Y - 5, 50, 50, 0, tut_frame, 255);
         3: if mWins[1].visible then ASprite2D_Draw(tex_arr_point, mWins[1].rect.X - 35, mWins[1].rect.Y - 5, 50, 50, 0, tut_frame, 255);
         4: if mWins[8].visible then ASprite2D_Draw(tex_arr_point, mWins[1].rect.X, mWins[1].rect.Y + mWins[1].rect.H - 15, 50, 50, -90, tut_frame, 255);
         5: if mWins[1].visible then ASprite2D_Draw(tex_arr_point, mWins[1].rect.X - 35, mWins[1].rect.Y - 15, 50, 50, 0, tut_frame, 255);
         6: if igs = igsInv then ASprite2D_Draw(tex_arr_point, mWins[1].rect.X - 35, mWins[1].rect.Y - 15, 50, 50, 0, tut_frame, 255);
       end;
     end;
end;

procedure MyGui_Update();
var i, j, n: integer;
    s : utf8string;
    flag : boolean;
begin
  if iga = igaCombat then mWins[7].visible:=false;
  if gs = gsGame then
     begin
       if igs = igsInv then mWins[5].visible:=true else mWins[5].visible:=false;
       if igs = igsChar then mWins[6].visible:=true else mWins[6].visible:=false;
       if igs = igsQLog then mWins[9].visible:=true else mWins[9].visible:=false;
       if igs = igsMap then mWins[12].visible:=true else mWins[12].visible:=false;
       if igs = igsSBook then mWins[11].visible:=true else mWins[11].visible:=false;

       // tutorial switcher
       if (tutorial = 5) and (igs = igsInv) then
          begin
            tutorial := 6;
            sleep(50);
          //  SendData(inline_PkgCompile(4, activechar.Name + '`6`'));
          end;

       if igs <> igsNPC then mWins[7].visible:=false;
       if (igs <> igsNPC) and (igs <> igsQLog) then mWins[8].visible:=false;

       if igs = igsSBook then
          for i := 1 to 10 do
            if mWins[11].dnds[i].data.contain <> 0 then
               begin
                 mWins[11].texts[i * 2].Text:=Spells[mWins[11].dnds[i].data.contain].name;
                 mWins[11].texts[i * 2 + 1].Text:= 'Rank 1';
               end else
               begin
                 mWins[11].texts[i * 2].Text:='';
                 mWins[11].texts[i * 2 + 1].Text:= '';
               end;

       if activechar.Numbers.SP > 0 then flag := true else flag := false;
       for i := 5 to 10 do
           mWins[6].btns[i].enabled := flag;

       if sk_zoom then mWins[6].btns[3].texID := 4 else mWins[6].btns[3].texID:= 3 ;
     end;

  if mWins[2].exist then if mWins[2].visible then mWins[2].visible:=false;

  if mWins[4].visible then
     if mWins[4].Name = '2' then mWins[4].visible:=false else
        if mouse_click(m_bleft) or mouse_click(m_bright) then
           if GetTickCount() - u_StrToInt(mWins[4].Name) > 100 then mWins[4].visible:=false;

  for i := 1 to high(mWins) do
    if mWins[i].exist and mWins[i].visible then
    begin
      if col2d_PointInRect( Mouse_X, Mouse_Y, rect(mWins[i].rect.x, mWins[i].rect.y, mWins[i].rect.W, 24) ) then
        if mouse_down(M_BLEFT) then
          begin
            // таскаем окно за заголовок
            mWins[i].rect.X:= mWins[i].rect.X + (Mouse_X - oMX);
            mWins[i].rect.Y:= mWins[i].rect.Y + (Mouse_Y - oMY);
          end;
      if mWins[i].rect.X < - mWins[i].rect.W * 0.8 then mWins[i].rect.X := - mWins[i].rect.W * 0.8;
      if mWins[i].rect.X > scr_w - mWins[i].rect.W * 0.2 then mWins[i].rect.X := scr_w - mWins[i].rect.W * 0.2;
      if mWins[i].rect.Y < 0 then mWins[i].rect.Y := 0;
      if mWins[i].rect.Y + 23 > scr_h then mWins[i].rect.Y:= scr_h - 23;

       // проверка на кнопках
      for j := 1 to high(mWins[i].btns) do
        if mWins[i].btns[j].exist then
           begin
             mWins[i].btns[j].OMD:=false;
             mWins[i].btns[j].OMO:=false;
             if col2d_PointInRect( Mouse_X, Mouse_Y,
                                   rect( mWins[i].rect.X + mWins[i].btns[j].rect.X + frmPak[mWins[i].fType].w,
                                         mWins[i].rect.Y + mWins[i].btns[j].rect.Y + frmPak[mWins[i].fType].w,
                                         mWins[i].btns[j].rect.W, mWins[i].btns[j].rect.H ) ) then
                begin
                  mWins[i].btns[j].OMO := true;
                  if mouse_down(M_BLEFT) and mWins[i].btns[j].enabled then
                     mWins[i].btns[j].OMD := true;
                  If mouse_click(M_BLEFT) and mWins[i].btns[j].enabled then
                     mGui_OnMouseClick(i, j);
                end;
           end;

      for j := 1 to high(mWins[i].texts) do
        if mWins[i].texts[j].exist then
          begin
            mWins[i].texts[j].OMO:=col2d_PointInRect( mouse_X, mouse_Y,
                                   rect(mWins[i].rect.X + mWins[i].texts[j].rect.X + frmPak[mWins[i].fType].w,
                                        mWins[i].rect.Y + mWins[i].texts[j].rect.Y + frmPak[mWins[i].fType].w,
                                        mWins[i].texts[j].rect.W, mWins[i].texts[j].rect.H
                                        ));;
          end;

      // проверка на картинках
      for j := 1 to high(mWins[i].imgs) do
        if mWins[i].imgs[j].exist then
          begin
            mWins[i].imgs[j].omo:= col2d_PointInRect( Mouse_X, Mouse_Y,
                                   rect( mWins[i].rect.X + mWins[i].imgs[j].rect.X + frmPak[mWins[i].fType].w,
                                         mWins[i].rect.Y + mWins[i].imgs[j].rect.Y + frmPak[mWins[i].fType].w,
                                         mWins[i].imgs[j].rect.W, mWins[i].imgs[j].rect.H ) );
          end;

      // проверка на диалогах
      for j := 1 to high(mWins[i].dlgs) do
        if mWins[i].dlgs[j].exist then
           begin
             mWins[i].dlgs[j].omo:= Col2d_PointInRect( Mouse_X, Mouse_Y, rect(mWins[i].rect.X + 30, mWins[i].rect.Y + mWins[i].dlgs[j].dy,
                                                       500, 20));
             if mWins[i].dlgs[j].omo and Mouse_Click(M_BLEFT) then
                dlg_Click(mWins[i].dlgs[j].dType, mWins[i].dlgs[j].dID);
           end;

      // ДРАГ ЭН ДРОП ДЕСУ
      for j := 1 to high(mWins[i].dnds) do
        if mWins[i].dnds[j].exist and mWins[i].dnds[j].visible then
          begin
            mWins[i].dnds[j].omo:= col2d_PointInRect( Mouse_X, Mouse_Y,
                                   rect(mWins[i].rect.X + frmPak[mWins[i].fType].w + mWins[i].dnds[j].x,
                                        mWins[i].rect.Y + frmPak[mWins[i].fType].w + mWins[i].dnds[j].y,
                                        32, 32));
            if mWins[i].dnds[j].omo and (mWins[i].dnds[j].data.contain > 0) then
               if (mWins[i].dnds[j].ddType = 1) or (mWins[i].dnds[j].ddType = 3) then
                  itt_open(mWins[i].dnds[j].data.contain, 2)
               else
                  stt_open(mWins[i].dnds[j].data.contain, 2);

            if mWins[i].dnds[j].omo and (mWins[i].dnds[j].data.contain > 0) and mouse_click(m_bright) then
               begin
                 if mWins[14].visible then
                    begin
                      if (i = 5) then
                         begin
                         { SendData(inline_pkgCompile(48, u_IntToStr(j) + '`'));
                           sleep(50);
                           SendData(inline_PkgCompile(28, activechar.Name + '`')); }
                         end;
                      if (i = 14) then
                         begin
                         { SendData(inline_pkgCompile(47, u_IntToStr(mWins[i].dnds[j].contains) + '`' + mWins[i].texts[1].Text + '`1`'));
                           sleep(50);
                           SendData(inline_PkgCompile(28, activechar.Name + '`')); }
                         end;
                    end else
                      pum_item_open( i, j, mWins[i].texts[1].Text );
               end;

            if (mWins[i].dnds[j].ddType = 3) and             // выбор предмета в окошке
                Mouse_Click(M_BLEFT) and                     // выбора награды для квеста
                mWins[i].dnds[j].omo and
                (mWins[i].dnds[j].data.contain > 0) then
                begin
                  for n := 1 to high(mWins[i].dnds) do
                      if mWins[i].dnds[n].exist then mWins[i].dnds[n].selected:=false;
                  mWins[i].dnds[j].selected:=true;
                end;

            if mWins[i].dnds[j].omo and
               not puMenu.exist and                         // не таскаем, если открыто меню
               Mouse_Down(M_BLEFT) and
               (mWins[i].dnds[j].data.contain > 0) and
               (on_DD = false) then                         // ещё нет днд
               if (i = 5) then                              // таскаем, только если открыт инвентарь
               begin
                  on_DD := true;
                  ddIndex := j;
                  ddWin   := i;
                  ddItem := mWins[i].dnds[j];
                  ddItem.data.ddSubType:= Items[ddItem.data.contain].data.sub;
                  break;
               end;
          end;
    end;

  if mWins[5].visible = false then on_DD := false;  // обрываем, если нет окошка инвентаря

  if tutorial > 0 then
     begin
      // mWins[1].visible := true;
       case tutorial of
         1: begin
                 mwins[1].rect.X:= 400;
                 mwins[1].rect.Y:= 480;
                 mWins[1].rect.H:= 85;
                 mwins[1].texts[1].Text:= 'Getting started';
                 mwins[1].texts[2].Text:= 'Welcome to Re:Venture Online!' + #13#10+
                                          'Click on this button to accept your first quest.';
                 mWins[1].visible := true;
            end;
         2: begin
               mwins[1].rect.X:= 300;
               mwins[1].rect.Y:= 120;
               mWins[1].rect.H:= 85;
               mwins[1].texts[1].Text:= 'Interacting with objects';
               mwins[1].texts[2].Text:= '< ! > symbol means that this object is interactive.' + #13#10+
                                        'Click on "Guild House" to explore it.';
               if igs = igsNone then mWins[1].visible := true else mWins[1].visible:=false;
            end;
         3: begin
               mwins[1].rect.X:= 550;
               mwins[1].rect.Y:= 370;
               mWins[1].rect.H:= 115;
               mwins[1].texts[1].Text:= 'Dialogs';
               mwins[1].texts[2].Text:= 'Here is the list of possible "dialogs" and actions.' + #13#10+
                                        'Mentor wants you to explore the rack with equipment.' + #13#10 +
                                        'Click on "Explore rack" dialog to do this".';
               if mWins[7].visible then mWins[1].visible:=true else mWins[1].visible:=false;
            end;
         4: begin
              mWins[1].rect.X := 560;
              mwins[1].rect.Y:= 330;
              mWins[1].rect.H:= 85;
              mwins[1].texts[1].Text:= 'Reward choice';
              mwins[1].texts[2].Text:= 'Some quests provide optional rewards.' + #13#10+
                                       'Choose one and click on it.' ;
              if mWins[8].visible then mWins[1].visible:=true else mWins[1].visible:=false;
            end;
         5: begin
              mWins[1].rect.X := 160;
              mwins[1].rect.Y:= 0;
              mWins[1].rect.H:= 85;
              mwins[1].texts[1].Text:= 'Inventory';
              mwins[1].texts[2].Text:= 'It''s time to equip your new items.' + #13#10+
                                       'Click "Inventory" button to open it.' ;
              if igs = igsNone then mWins[1].visible := true else mWins[1].visible:=false;
            end;
         6: begin
              mWins[1].rect.X := mWins[5].rect.X + mWins[5].dnds[21].x + 100;
              mwins[1].rect.Y:= mWins[5].rect.Y + mWins[5].dnds[21].y + 30;
              mWins[1].rect.H:= 100;
              mwins[1].texts[1].Text:= 'Equipment';
              mwins[1].texts[2].Text:= 'You should drag-and-drop items to slot to equip item.' + #13#10 +
                                       'Now equip chest, pants, boots and weapon to finish quest.';

              if igs = igsInv then mWins[1].visible := true else mWins[1].visible:=false;
            end;
         7: begin
              mWins[1].rect.X := 512 - mWins[1].rect.W / 2;
              mwins[1].rect.Y:= 5;
              mWins[1].rect.H:= 90;
              mwins[1].texts[1].Text:= 'Movement';
              mwins[1].texts[2].Text:= 'Click on battelfield cell to move. ' + #13#10 +
                                       'Usually, character need 5 action points (AP) to move for 1 cell.';

              if iga = igaCombat then mWins[1].visible := true else mWins[1].visible:=false;
            end ;
         8: begin
              mWins[1].rect.X := 512 - mWins[1].rect.W / 2;
              mwins[1].rect.Y:= 5;
              mWins[1].rect.H:= 150;
              mwins[1].texts[1].Text:= 'Direction';
              mwins[1].texts[2].Text:= 'Green icon appers at your character. It means you gain "Keep moving" effect. This effect allows you to change direction once for free.' + #13#10 +
                                       'Press F5 of click to "Change direction" button to enter turning mode.' + #13#10 +
                                       'Now, move to phantom.';

              if iga = igaCombat then mWins[1].visible := true else mWins[1].visible:=false;
            end
       else
         mWins[1].visible := false;
       end;
     end;

  if mWins[5].visible then
     begin
       for i := 1 to high(items) do
         if items[i].exist then
            if items[i].data.name = '' then items[i].exist:= false;

       mWins[5].texts[1].Text:= activechar.header.Name;
       mWins[5].texts[2].Text:= GetRaceName(activechar.header.raceID);
       mWins[5].texts[3].Text:= u_IntToStr(activechar.header.level) + ' level';
       mWins[5].texts[4].Text:= GetClassNameS(activechar.header.classID);
       mWins[5].texts[5].Text:= GetLocName(activechar.header.loc);

       mWins[5].texts[22].Text:=u_IntToStr(activechar.hpmp.mHP);  // хп
       mWins[5].texts[23].Text:=u_IntToStr(activechar.hpmp.mMP);  // мп
       mWins[5].texts[24].Text:=u_IntToStr(activechar.hpmp.mAP);  // ап
       mWins[5].texts[25].Text:=u_IntToStr(activechar.Stats.Ini);  // ини
       mWins[5].texts[26].Text:=u_IntToStr(activechar.Stats.HPReg);  // хпрег
       mWins[5].texts[27].Text:=u_IntToStr(activechar.Stats.MPReg);  // мпрег

       mWins[5].texts[28].Text:=u_IntToStr(activechar.Stats.Str);  // сил
       mWins[5].texts[29].Text:=u_IntToStr(activechar.Stats.Agi);  // лов
       mWins[5].texts[30].Text:=u_IntToStr(activechar.Stats.Con);  // кон
       mWins[5].texts[31].Text:=u_IntToStr(activechar.Stats.Hst);  // хст
       mWins[5].texts[32].Text:=u_IntToStr(activechar.Stats.Int);  // инт
       mWins[5].texts[33].Text:=u_IntToStr(activechar.Stats.Spi);  // спи

       mWins[5].texts[34].Text:=u_IntToStr(round(activechar.Stats.DMG/10 * activechar.Stats.APH + 1)) + '-' + u_IntToStr(2 + round(activechar.Stats.DMG/10 * activechar.Stats.APH * 1.1));  // дмг
       mWins[5].texts[35].Text:=u_IntToStr(activechar.Stats.APH);  // апх
       mWins[5].texts[36].Text:=u_FloatToStr(15/9) + '%';  // хит
       mWins[5].texts[37].Text:=u_FloatToStr(16/10) + '%';  // крит
       for i := 6 to 21 do
         if mWins[5].texts[i].OMO then mgui_TTOpen(30 + i - 6);

       n := mWins[5].dnds[4].data.contain;

       if (Items[n].data.iType >= 1) and (Items[n].data.iType < 7) then
          if mWins[5].dnds[6].data.contain > 0 then
             begin
               i := inv_FindFreeSpot();
               DoSwap(6, i);
               Chat_AddMessage(ch_tab_curr, 'S', 'You can''t use that item with two-handed weapon.');
               mWins[5].dnds[6].data.contain := 0;
             end;
     end;

   if mWins[6].visible or mWins[5].visible then
     begin
       mWins[6].texts[1].Text:= activechar.header.Name;
       mWins[6].texts[2].Text:= GetRaceName(activechar.header.raceID);
       mWins[6].texts[3].Text:= u_IntToStr(activechar.header.level) + ' level ';
       mWins[6].texts[5].Text:= GetClassNameS(activechar.header.classID);
       mWins[6].texts[4].Text:= 'Exp.:' + u_FloatToStr(activechar.numbers.exp/exp_cap[activechar.header.level + 1]*100) + '%';

       mWins[6].texts[22].Text:=u_IntToStr(activechar.hpmp.mHP);  // хп
       mWins[6].texts[23].Text:=u_IntToStr(activechar.hpmp.mMP);  // мп
       mWins[6].texts[24].Text:=u_IntToStr(activechar.hpmp.mAP);  // ап
       mWins[6].texts[25].Text:=u_IntToStr(activechar.Stats.Ini);  // ини
       mWins[6].texts[26].Text:=u_IntToStr(activechar.Stats.HPReg);// хпрег
       mWins[6].texts[27].Text:=u_IntToStr(activechar.Stats.MPReg);// мпрег

       mWins[6].texts[28].Text:=u_IntToStr(activechar.Stats.Str);  // сил
       mWins[6].texts[29].Text:=u_IntToStr(activechar.Stats.Agi);  // лов
       mWins[6].texts[30].Text:=u_IntToStr(activechar.Stats.Con);  // кон
       mWins[6].texts[31].Text:=u_IntToStr(activechar.Stats.Hst);  // хст
       mWins[6].texts[32].Text:=u_IntToStr(activechar.Stats.Int);  // инт
       mWins[6].texts[33].Text:=u_IntToStr(activechar.Stats.Spi);  // спи

       if stat_tab = 0 then
          begin
            mWins[6].texts[41].Text := 'Combat Stats';

            mWins[6].texts[18].Text := 'Damage';
            mWins[6].texts[19].Text := 'AP/Hit';
            mWins[6].texts[20].Text := 'Hit';
            mWins[6].texts[21].Text := 'Crit';

            mWins[6].texts[34].Text:=u_IntToStr(round(activechar.Stats.DMG/10 * activechar.Stats.APH + 1)) + '-' + u_IntToStr(2 + round(activechar.Stats.DMG/10 * activechar.Stats.APH * 1.1));  // дмг
            mWins[6].texts[35].Text:=u_IntToStr(activechar.Stats.APH);  // апх
            mWins[6].texts[36].Text:=u_FloatToStr(15/9) + '%';    // крит
            mWins[6].texts[37].Text:=u_FloatToStr(16/13) + '%';   // хит

            mWins[6].btns[11].enabled:=false;
            mWins[6].btns[12].enabled:=true;
            mWins[6].btns[13].enabled:=true;

            mWins[5].texts[38].Text := 'Combat Stats';

            mWins[5].texts[18].Text := 'DMG';
            mWins[5].texts[19].Text := 'APH';
            mWins[5].texts[20].Text := 'HIT';
            mWins[5].texts[21].Text := 'CRIT';

            mWins[5].texts[34].Text:=u_IntToStr(round(activechar.Stats.DMG/10 * activechar.Stats.APH + 1)) + '-' + u_IntToStr(2 + round(activechar.Stats.DMG/10 * activechar.Stats.APH * 1.1));  // дмг
            mWins[5].texts[35].Text:=u_IntToStr(activechar.Stats.APH);  // апх
            mWins[5].texts[36].Text:=u_FloatToStr(15/9) + '%';    // крит
            mWins[5].texts[37].Text:=u_FloatToStr(16/13) + '%';   // хит

            mWins[5].btns[2].enabled:=false;
            mWins[5].btns[3].enabled:=true;
            mWins[5].btns[4].enabled:=true;
          end;

       if stat_tab = 1 then
          begin
            mWins[6].texts[41].Text := 'Defense Stats';

            mWins[6].texts[18].Text := 'Armor';
            mWins[6].texts[19].Text := 'Dodge';
            mWins[6].texts[20].Text := 'Block';
            mWins[6].texts[21].Text := '';

            mWins[6].texts[34].Text:=u_IntToStr(activechar.Stats.Armor);  // дмг
            mWins[6].texts[35].Text:=u_FloatToStr(3 + activechar.Stats.Agi/1.5 * (0.5 - 0.01*activechar.header.level)) + '%';    // додж
            mWins[6].texts[36].Text:=u_FloatToStr(1 + 16/11) + '%';   // блок
            mWins[6].texts[37].Text:='';

            mWins[6].btns[11].enabled:=true;
            mWins[6].btns[12].enabled:=false;
            mWins[6].btns[13].enabled:=true;

            mWins[5].texts[38].Text := 'Defense Stats';

            mWins[5].texts[18].Text := 'Armor';
            mWins[5].texts[19].Text := 'Dodge';
            mWins[5].texts[20].Text := 'Block';
            mWins[5].texts[21].Text := '';

            mWins[5].texts[34].Text:=u_IntToStr(activechar.Stats.Armor);  // дмг
            mWins[5].texts[35].Text:=u_FloatToStr(3 + activechar.Stats.Agi/1.5 * (0.5 - 0.01*activechar.header.level)) + '%';    // додж
            mWins[5].texts[36].Text:=u_FloatToStr(1 + 16/11) + '%';   // блок
            mWins[5].texts[37].Text:='';

            mWins[5].btns[2].enabled:=true;
            mWins[5].btns[3].enabled:=false;
            mWins[5].btns[4].enabled:=true;
          end;

       if stat_tab = 2 then
          begin
            mWins[6].texts[41].Text := 'Caster Stats';

            mWins[6].texts[18].Text := 'Spell power';
            mWins[6].texts[19].Text := 'Spell crit';
            mWins[6].texts[20].Text := 'Spell hit';
            mWins[6].texts[21].Text := '';

            mWins[6].texts[34].Text:= u_IntToStr(activechar.Stats.SPD);  // дмг
            mWins[6].texts[35].Text:=u_FloatToStr(3 + activechar.Stats.Int/1.5 * (0.5 - 0.01*activechar.header.level) ) + '%';  // крит
            mWins[6].texts[36].Text:=u_FloatToStr(85 + 15/9) + '%';    // хит
            mWins[6].texts[37].Text:='';

            mWins[6].btns[11].enabled:=true;
            mWins[6].btns[12].enabled:=true;
            mWins[6].btns[13].enabled:=false;

            mWins[5].texts[38].Text := 'Caster Stats';

            mWins[5].texts[18].Text := 'S.Power';
            mWins[5].texts[19].Text := 'S.Crit';
            mWins[5].texts[20].Text := 'S.Hit';
            mWins[5].texts[21].Text := '';

            mWins[5].texts[34].Text :=  u_IntToStr(activechar.Stats.SPD);  // дмг
            mWins[5].texts[35].Text :=  u_FloatToStr(3 + activechar.Stats.Int/1.5 * (0.5 - 0.01*activechar.header.level) ) + '%';  // крит
            mWins[5].texts[36].Text :=  u_FloatToStr(85 + 15/9) + '%';    // хит
            mWins[5].texts[37].Text :=  '';

            mWins[5].btns[2].enabled:=true;
            mWins[5].btns[3].enabled:=true;
            mWins[5].btns[4].enabled:=false;
          end;

       mWins[6].texts[40].Text:=u_IntToStr(activechar.Numbers.SP);
       mWins[6].texts[38].Text:='Character''s perks (' + u_IntToStr(activechar.Numbers.TP) + ' free Perk Pts.)';

       for i := 2 to 21 do
         if mWins[6].texts[i].OMO then mgui_TTOpen(30 + i - 6);
     end;

  if on_DD then
     if tutorial = 6 then
        begin
          tutorial := 7;
          //  SendData(inline_PkgCompile(4, activechar.Name + '`7`'));
        end;

  if on_DD and Mouse_Up(M_BLEFT) then  // драг н дроп в инвентаре
     begin
       if mWins[14].visible then
          if Col2d_PointInRect(Mouse_X, Mouse_Y, mWins[14].rect) then
             begin
              { SendData(inline_pkgCompile(48, u_IntToStr(ddIndex) + '`'));
               sleep(50);
               SendData(inline_PkgCompile(28, activechar.Name + '`'));    }
               ddIndex := 0;
               ddWin := 0;
               on_DD := false;
             end;

       for i := 1 to high(mwins[5].dnds) do
         if mWins[5].dnds[i].omo then
            begin
              if (mWins[5].dnds[i].data.contain = 0) then  // кладём в пустую ячейку?
                 begin
                   if ((mWins[5].dnds[i].data.ddSubType = ddItem.data.ddSubType) or (mWins[5].dnds[i].data.ddSubType = 6))then
                      begin
                        DoSwap(ddIndex, i);
                        ddIndex := 0;
                        ddWin := 0;
                        on_DD := false;
                      end else
                      begin
                        ddItem.exist:=false;
                        ddItem.data.contain:=0;
                        on_DD := false;
                      end;
                      break;
                 end else                            // попытка свапа предметов
                 begin
                   if ((mWins[5].dnds[i].data.ddSubType = ddItem.data.ddSubType) or (mWins[5].dnds[i].data.ddSubType = 6))then
                      begin
                        Writeln('Swap 1');
                        n := inv_FindFreeSpot;
                        Writeln(n);
                        if n <> high(word) then
                        begin
                          DoSwap(i, n);
                          sleep(50);
                          DoSwap(ddIndex, i);
                          sleep(50);
                          DoSwap(n, ddIndex);
                        end;
                        ddIndex := 0;
                        ddWin := 0;
                        on_DD := false;
                      end else
                      begin
                        ddItem.exist:=false;
                        ddItem.data.contain:=0;
                        on_DD := false;
                      end;
                      break;
                 end;
            end;
     end;

  if puMenu.exist then
     begin
       inc(puMenu.eTime);
       for i := 0 to 9 do
         if puMenu.elements[i].exist then
            puMenu.elements[i].omo := col2d_PointInRect( Mouse_X, Mouse_Y, puMenu.elements[i].rect );
     end;
 {
   if mouse_click(M_BLEFT) then
     begin
      if puMenu.exist and (puMenu.eTime > 3) then
         begin
              // меню ник игрока
           if puMenu.mType = 1 then
           for i := 0 to high(puMenu.elements) do
           if puMenu.elements[i].enable then
              begin
                if puMenu.elements[i].omo and (puMenu.elements[i].action = 1) then
                   begin      // приватный мессаг
                     Chat_AddPrivate(puMenu.sender);
                   end;
                if puMenu.elements[i].omo and (puMenu.elements[i].action = 2)  then
                   begin      // запрос на дуэль
                     if puMenu.sender = activechar.Name then exit;
                     SendData(inline_pkgCompile(45, puMenu.sender + '`'));
                     Chat_AddMessage(ch_tab_curr, 'S', 'You requested duel with ' + puMenu.sender);
                   end;
              end;


              // меню ппредмета
           if puMenu.mType = 2 then
           for i := 0 to high(puMenu.elements) do
           if puMenu.elements[i].enable then
              begin
                if puMenu.elements[i].omo and (puMenu.elements[i].action = 1) then
                   begin      // линк в чат
                     if puMenu.wID <> 11 then
                        s := '{!:' + u_IntToStr(mWins[puMenu.wID].dnds[puMenu.sID].contains) + ':0:0:' + items[mWins[puMenu.wID].dnds[puMenu.sID].contains].name + '}{'
                     else
                        s := '{$:' + u_IntToStr(mWins[puMenu.wID].dnds[puMenu.sID].contains) + ':0:0:' + Spells[mWins[puMenu.wID].dnds[puMenu.sID].contains].name + '}{';

                     if ch_message_inp then
                        begin
                          if utf8_Length(eChatFrame.Caption + ' ' + s) < 90 then
                             eChatFrame.Caption := eChatFrame.Caption + ' ' + s ;
                          eChatFrame.Focus;
                          echatFrame.SelectAll;
                          eChatFrame.DeleteSelection;
                        end else
                        begin
                          ch_message_inp := true;
                          Nonameframe38.Show;
                          eChatFrame.Show;
                          bChatSend.Show;
                          eChatFrame.Caption := ' ' + s;
                          eChatFrame.Focus;
                          echatFrame.SelectAll;
                          eChatFrame.DeleteSelection;
                        end;
                   end;
                if puMenu.elements[i].omo and (puMenu.elements[i].action = 2) then
                   begin
                     SendData(inline_pkgCompile(47, u_IntToStr(mWins[puMenu.wID].dnds[puMenu.sID].contains) + '`' + puMenu.sender + '`1`'));
                     sleep(50);
                     SendData(inline_PkgCompile(28, activechar.Name + '`'));
                   end;

                if puMenu.elements[i].omo and (puMenu.elements[i].action = 3) then
                   begin
                     SendData(inline_pkgCompile(48, u_IntToStr(puMenu.sID) + '`'));
                     sleep(50);
                     SendData(inline_PkgCompile(28, activechar.Name + '`'));
                   end;

                if puMenu.elements[i].omo and (puMenu.elements[i].action = 4) then
                   begin
                     SendData(inline_pkgCompile(54, u_IntToStr(activechar.ID) + '`' + u_IntToStr(mWins[5].dnds[puMenu.sID].contains) + '`'));
                     sleep(50);
                     SendData(inline_PkgCompile(28, activechar.Name + '`'));
                   end;
              end;
           pum_close;
         end;
     end;
  }
  if mouse_click(M_BRIGHT) then
     begin
      // if  and (itt.eTime > 3) then itt.exist := false;
       if puMenu.exist and (puMenu.eTime > 3) then pum_close;
     end;

  for i := 2 to 10 do
    mWins[11].dnds[i].data.contain:= 0;

  n := 2;
  for i := 1 to 7 do
    begin
      if skills[i * 10].rank > 0 then
         begin
           case i of
             1:
             begin     // комбат
               mWins[11].dnds[n].data.contain:=3;
               inc(n);
               mWins[11].dnds[n].data.contain:=7;
               inc(n);
             end;
             2:
             begin     // дефенсив
               mWins[11].dnds[n].data.contain:=9;
               inc(n);
               mWins[11].dnds[n].data.contain:=15;
               inc(n);
             end;
             3:
             begin     // Ресторатив
               mWins[11].dnds[n].data.contain:=5;
               inc(n);
               mWins[11].dnds[n].data.contain:=12;
               inc(n)
             end;
             4:
             begin     // Элементал
               mWins[11].dnds[n].data.contain:=6;
               inc(n);
               mWins[11].dnds[n].data.contain:=8;
               inc(n)
             end;
             5:
             begin     // Спиритуал
               mWins[11].dnds[n].data.contain:=1;
               inc(n);
               mWins[11].dnds[n].data.contain:=14;
               inc(n)
             end;
             6:
             begin     // Сурвайвал
               mWins[11].dnds[n].data.contain:=4;
               inc(n);
               mWins[11].dnds[n].data.contain:=13;
               inc(n)
             end;
             7:
             begin     // сабт
               mWins[11].dnds[n].data.contain:=10;
               inc(n);
               if skills[71].rank > 0 then
                  begin
                    mWins[11].dnds[n].data.contain:=11;
                    inc(n);
                  end;
             end;
           end;
        end;
    end;
end;


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
           d1 := round(activechar.Stats.DMG/10 * activechar.Stats.APH + 1);
           d2 := 2 + round(activechar.Stats.DMG/10 * activechar.Stats.APH * 1.1);
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
  if (sender > 100) and (sender < 200) then
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

  if Mouse_X + W > scr_w then mWins[2].rect.X:= Mouse_X - W else mWins[2].rect.X:= Mouse_X + 16;
  if Mouse_Y + H > scr_h then mWins[2].rect.Y:= Mouse_Y - H else mWins[2].rect.Y:= Mouse_Y + 16;
  mWins[2].rect.W:=W;
  mWins[2].rect.H:=H;
  mWins[2].texts[1].rect.W:= W - 6;
  mWins[2].texts[2].rect.W:= W - 6;
  mWins[2].texts[2].rect.H:= Text_GetHeight(fntMain, mWins[2].texts[2].rect.W, mWins[2].texts[2].Text);
end;

procedure itt_Open( iID, ittType : longword);
var fH, fW, tH: single;
    i, k: integer;
begin
 // Writeln('Debug 1');
  if (iID < 1) or (iID > 1000) then Exit;
  if items[iID].req then Exit;
{  if (items[iID].data.ID = 0) then
     begin
       items[iID].req:=true;
       // SendData(inline_pkgCompile(6, u_IntToStr(iID) + '`') );
       Exit;
     end;  }
  if mWins[4].visible then
     if items[iID].data.name =  mWins[4].texts[1].Text then Exit;

  if ittType = 2 then mWins[4].Name:='2' else mWins[4].Name:=u_IntToStr(GetTickCount());;

  for i := 2 to high(mWins[4].texts) do
    begin
      mWins[4].texts[i].visible:=false;
      mWins[4].texts[i].color:=$dddddd;
    end;
  mWins[4].texts[1].Text:=Items[iID].data.name;
  fW := text_GetWidth(fntMain, items[iID].data.name) + 50;
  if fW < 175 then fW := 175;
  fH := text_GetHeight( fntMain, 20, 'H');
  tH := fH;
  mWins[4].rect.W:= fW + 10;
  mWins[4].texts[1].rect.W := fW;
  mWins[4].texts[1].rect.H := fH;
  mWins[4].texts[1].rect.X := 0;
  mWins[4].texts[1].rect.Y := 0;

  case items[iID].data.rare of
    1 : mWins[4].texts[1].color := $AAAAAA; // Серенький
    2 : mWins[4].texts[1].color := $FFFFFF; // беленький
    3 : mWins[4].texts[1].color := $00FF00; // зелёненький
    4 : mWins[4].texts[1].color := $63CACA; // синенький
    6 : mWins[4].texts[1].color := $FF8000  // ОРАНЖЖЖЖ
  else
    mWins[4].texts[1].color := $DD0000; //красный - ошипка;
  end;

  // строка с видом предмета
  mWins[4].texts[2].rect.W := fW;
  mWins[4].texts[2].rect.H := fH;
  mWins[4].texts[2].rect.X := 0;
  mWins[4].texts[2].rect.Y := tH;
  mWins[4].texts[2].Text:= itt_GetType(items[iID].data.iType);
  mWins[4].texts[2].visible:=true;
  tH := tH + fH;

  // строка с дамагом для оружия и ап
  if items[iID].data.sub = 11 then
     begin
       mWins[4].texts[3].rect.W := fW;
       mWins[4].texts[3].rect.H := fH;
       mWins[4].texts[3].rect.X := 0;
       mWins[4].texts[3].rect.Y := tH;
       mWins[4].texts[3].Text:= u_IntToStr(round(1 + items[iID].data.props[2] / 10 * items[iID].data.props[4])) +
                                ' - ' +
                                u_IntToStr(2 + round(items[iID].data.props[2] / 10 * items[iID].data.props[4] * 1.1)) +
                                ' Damage';
       mWins[4].texts[3].visible:=true;

       mWins[4].texts[4].rect.W := text_GetWidth(fntMain, IntToStr(Items[iID].data.props[4])) + 10;
       mWins[4].texts[4].rect.H := fH;
       mWins[4].texts[4].rect.X := fW - 10 - text_GetWidth(fntMain, IntToStr(Items[iID].data.props[4]));
       mWins[4].texts[4].rect.Y := tH;
       mWins[4].texts[4].Text:= itt_GetProperty(4, Items[iID].data.props[4]);
       mWins[4].texts[4].visible:=true;
       tH := tH + fH
     end;

  // описание предмета
  if (items[iID].data.iType = 35) then
     begin
       mWins[4].texts[4].rect.W := fW;
       mWins[4].texts[4].rect.H := text_getheight(fntMain2, fW, QI[iID]);
       mWins[4].texts[4].rect.X := 0 ;
       mWins[4].texts[4].rect.Y := tH;
       mWins[4].texts[4].Text:= QI[iID];
       mWins[4].texts[4].visible:=true;
       mWins[4].texts[4].color:=$00DD00;
       tH := tH + mWins[4].texts[4].rect.H
     end;

  // строка с броней
  if not (items[iID].data.sub in [6, 11, 2, 7]) then
     begin
       mWins[4].texts[4].rect.W := fW;
       mWins[4].texts[4].rect.H := fH;
       mWins[4].texts[4].rect.X := 0 ;
       mWins[4].texts[4].rect.Y := tH;
       mWins[4].texts[4].Text:= itt_GetProperty(5, Items[iID].data.props[5]);
       mWins[4].texts[4].visible:=true;
       tH := tH + fH
     end;

  if items[iID].data.iType = 14 then
     begin
       mWins[4].texts[36].rect.W := fW;
       mWins[4].texts[36].rect.H := fH;
       mWins[4].texts[36].rect.X := 0 ;
       mWins[4].texts[36].rect.Y := tH;
       mWins[4].texts[36].Text:= 'Block ' + u_IntToStr(round(Items[iID].data.props[5] * 0.35));
       mWins[4].texts[36].visible:=true;
       tH := tH + fH
     end;


  // дурабилити
  if not (items[iID].data.sub in [2, 6, 7]) then
     begin
       mWins[4].texts[5].rect.W := fW;
       mWins[4].texts[5].rect.H := fH;
       mWins[4].texts[5].rect.X := 0;
       mWins[4].texts[5].rect.Y := tH;
       mWins[4].texts[5].Text:= itt_GetProperty(1, Items[iID].data.props[1]);
       mWins[4].texts[5].visible:=true;
       tH := tH + fH
     end;

  // требования по лвл
  if (items[iID].data.props[3] > 0) then
     begin
       mWins[4].texts[35].rect.W := fW;
       mWins[4].texts[35].rect.H := fH;
       mWins[4].texts[35].rect.X := 0;
       mWins[4].texts[35].rect.Y := tH;
       mWins[4].texts[35].Text:= itt_GetProperty(3, Items[iID].data.props[3]);
       if items[iID].data.props[3] > activechar.header.level then
          mWins[4].texts[35].color:=$CC0000;
       mWins[4].texts[35].visible:=true;
       tH := tH + fH
     end;

  for i := 0 to 5 do
    if (items[iID].data.iType <> 35) then
    if (items[iID].data.props[6 + i] > 0) then
       begin
         mWins[4].texts[6 + i].rect.W := fW;
         mWins[4].texts[6 + i].rect.H := fH;
         mWins[4].texts[6 + i].rect.X := 0;
         mWins[4].texts[6 + i].rect.Y := tH;
         mWins[4].texts[6 + i].Text:= itt_GetProperty(6 + i, Items[iID].data.props[6 + i]);
         mWins[4].texts[6 + i].visible:=true;
         tH := tH + fH
       end;

  for i := 0 to 13 do
    if (items[iID].data.iType <> 35) then
    if (items[iID].data.props[12 + i] > 0 ) then
       begin
         mWins[4].texts[12 + i].rect.W := fW;
         if text_GetHeight(fntMain, fW, IntToStr(Items[iID].data.props[12 + i])) > fH then
            mWins[4].texts[12 + i].rect.H := fH * 2
         else
            mWins[4].texts[12 + i].rect.H := fH;
         mWins[4].texts[12 + i].rect.X := 0;
         mWins[4].texts[12 + i].rect.Y := tH;
         mWins[4].texts[12 + i].Text:= itt_GetProperty(12 + i, Items[iID].data.props[12 + i]);
         mWins[4].texts[12 + i].visible:=true;
         mWins[4].texts[12 + i].rect.W := fW;
         mWins[4].texts[12 + i].color:= $00DD00;
         if text_GetHeight(fntMain, fW, IntToStr(Items[iID].data.props[12 + i])) > fH then
            tH := tH + fH * 2
         else
            tH := tH + fH;
       end;

   mWins[4].texts[26].rect.W := fW;
   mWins[4].texts[26].rect.H := fH;
   mWins[4].texts[26].rect.X := 0;
   mWins[4].texts[26].rect.Y := tH;
   mWins[4].texts[26].Text:= 'Sell for: ' + u_IntToStr(round(Items[iID].data.price * 0.3));
   mWins[4].texts[26].visible:=true;
   tH := tH + fH;


  mWins[4].rect.H:=tH + 5;
  if mWins[4].rect.W + mouse_X > scr_w then
     mWins[4].rect.X:= mouse_x - mWins[4].rect.W
  else
     mWins[4].rect.X:=Mouse_X + 16;

  if mWins[4].rect.H + mouse_Y > scr_h then
     mWins[4].rect.Y:= mouse_y - mWins[4].rect.H
  else
     mWins[4].rect.Y:=Mouse_Y + 16;

  mWins[4].visible := true;
 // Chat_AddMessage(0, 'S', u_BoolToStr(mWins[4].visible) + ' ' + u_FloatToStr(mWins[4].rect.X) + ' ' + u_FloatToStr(mWins[4].rect.Y) + ' ' +u_FloatToStr(mWins[4].rect.w) + ' ' + u_FloatToStr(mWins[4].rect.H));
end;

procedure stt_Open( sID, sttType : longword);
var fH, fW, tH: single;
    i, k, d1, d2, d3: integer;
    s : utf8string;
begin
  if not (sID in [1..100]) then Exit;
  if items[sID].req then Exit;
  { if (items[sID].ID = 0) or (items[iID].vCheck = false) then
     begin
       items[sID].req:=true;
       SendData(inline_pkgCompile(6, u_IntToStr(iID) + '`') );
       Exit;
     end;    }
  if mWins[4].visible then
     if Spells[sID].name =  mWins[4].texts[1].Text then Exit;

  if sttType = 2 then mWins[4].Name:='2' else mWins[4].Name:=u_IntToStr(GetTickCount());;

  for i := 2 to high(mWins[4].texts) do
    begin
      mWins[4].texts[i].visible:=false;
      mWins[4].texts[i].color:=$dddddd;
    end;

  if Spells[sID].hkey = '' then
     mWins[4].texts[1].Text:=Spells[sID].name
  else
     mWins[4].texts[1].Text:=Spells[sID].name + ' (' + Spells[sID].hkey + ')';

  fW := text_GetWidth(fntMain, Spells[sID].name) + 50;
  if fW < 200 then fW := 200;
  fH := text_GetHeight( fntMain, 20, 'H');
  tH := fH;
  mWins[4].rect.W:= fW + 10;
  mWins[4].texts[1].rect.W := fW;
  mWins[4].texts[1].rect.H := fH;
  mWins[4].texts[1].rect.X := 0;
  mWins[4].texts[1].rect.Y := 0;

  // строка с школой
  if spells[sID].school <> high(byte) then
     begin
  mWins[4].texts[2].rect.W := fW;
  mWins[4].texts[2].rect.H := fH;
  mWins[4].texts[2].rect.X := 0;
  mWins[4].texts[2].rect.Y := tH;
  mWins[4].texts[2].Text:= 'School: ' + sp_GetSchool(spells[sID].school);
  mWins[4].texts[2].visible:=true;
  tH := tH + fH;
     end;

  // строка с видом cпелла
  mWins[4].texts[6].rect.W := fW;
  mWins[4].texts[6].rect.H := fH;
  mWins[4].texts[6].rect.X := 0;
  mWins[4].texts[6].rect.Y := tH;
  mWins[4].texts[6].Text:= 'Type: ' + sp_GetType(spells[sID].sType);
  mWins[4].texts[6].visible:=true;
  tH := tH + fH;

  // строка с рейнжем
  if spells[spID].range > 0 then
     begin
  mWins[4].texts[7].rect.W := fW;
  mWins[4].texts[7].rect.H := fH;
  mWins[4].texts[7].rect.X := 0;
  mWins[4].texts[7].rect.Y := tH;
  mWins[4].texts[7].Text:= 'Range: ' + u_IntToStr(spells[sID].range);
  mWins[4].texts[7].visible:=true;
  tH := tH + fH;
     end;

  // строка с манакостом
  if (spells[sID].MP_cost > 0) or (spells[sID].AP_Cost > 0) then
     begin
       mWins[4].texts[3].rect.W := fW;
       mWins[4].texts[3].rect.H := fH;
       mWins[4].texts[3].rect.X := 0;
       mWins[4].texts[3].rect.Y := tH;
       s := '';
       case sID of
         1 : s := u_IntToStr(spells[sID].AP_cost);
         2 : s := u_IntToStr(spells[sID].AP_Cost + activechar.Stats.APH);
         3 : s := u_IntToStr(activechar.Stats.APH);
         4 : s := u_IntToStr(activechar.Stats.APH + spells[sID].AP_Cost);
         5 : s := u_IntToStr(spells[sID].AP_cost);
         6 : s := u_IntToStr(spells[sID].AP_cost);
         7 : s := u_IntToStr(spells[sID].AP_cost);
         8 : s := u_IntToStr(spells[sID].AP_cost);
         9 : s := u_IntToStr(spells[sID].AP_Cost);
         10: s := u_IntToStr(trunc(activechar.Stats.APH * 0.75));
         11: s := u_IntToStr(spells[sID].AP_Cost);
         12: s := u_IntToStr(spells[sID].AP_Cost);
         93: s := u_IntToStr(spells[sID].AP_Cost);
       //  95: s := u_IntToStr(units[your_unit].mAP);
       end;
       mWins[4].texts[3].Text:= 'Cost: ' + u_IntToStr(spells[sID].MP_cost) + ' MP and ' + s + ' AP';
       mWins[4].texts[3].visible:=true;
       tH := tH + fH;
     end;

  // строка с КД
  if spells[sID].CD > 0 then
     begin
       mWins[4].texts[4].rect.W := fW;
       mWins[4].texts[4].rect.H := fH;
       mWins[4].texts[4].rect.X := 0;
       mWins[4].texts[4].rect.Y := tH;
       mWins[4].texts[4].Text:= 'Cooldown: ' + u_FloatToStr(spells[sID].CD/10) + ' round(s)';
       mWins[4].texts[4].visible:=true;
       tH := tH + fH;
     end;

  case Spells[sID].ID of
    1: begin
         d1 := spells[sid].x;
         d2 := spells[sid].x + trunc((activechar.Stats.Spi + activechar.Stats.spd) * spells[sid].AP_Cost/ 25);
         Spells[sID].discr := AnsiToUTF8(format(Spells[sID].bdiscr, [d1, d2]));
       end;
    4: begin
         d1 := spells[sid].x + trunc((activechar.Stats.Str));
         Spells[sID].discr := AnsiToUTF8(format(Spells[sID].bdiscr, [d1]));
       end;
    5: begin
         d1 := spells[sid].x + trunc((activechar.Stats.Spi + activechar.Stats.spd) * spells[sid].AP_Cost/ 25);
         Spells[sID].discr := AnsiToUTF8(format(Spells[sID].bdiscr, [d1]));
       end;
    6: begin
         d1 := spells[sid].x + trunc((activechar.Stats.spd) * spells[sid].AP_Cost / 25);
         Spells[sID].discr := AnsiToUTF8(format(Spells[sID].bdiscr, [d1]));
       end;
    9: begin
         d1 := trunc(Items[mWins[5].dnds[6].data.contain].data.props[5] * 0.35);
         Spells[sID].discr := AnsiToUTF8(format(Spells[sID].bdiscr, [d1]));
       end;
    12: begin
         d1 := spells[sid].x + trunc((activechar.Stats.Spi + activechar.Stats.spd) * spells[sid].AP_Cost/ 25);
         Spells[sID].discr := AnsiToUTF8(format(Spells[sID].bdiscr, [d1]));
       end;
    else
      Spells[sID].discr:= spells[sID].bdiscr;
  end;

  // строка с описанием
  //if spells[sID].cost > 0 then
     begin
       mWins[4].texts[5].color:=$00AA00;
       mWins[4].texts[5].rect.W := fW;
       mWins[4].texts[5].rect.H := (trunc(Text_GetHeight(fntMain, fW, Spells[sID].discr)/fH) + 1) * fH;
       mWins[4].texts[5].rect.X := 0;
       mWins[4].texts[5].rect.Y := tH;
       mWins[4].texts[5].Text:= Spells[sID].discr;
       mWins[4].texts[5].visible:=true;
       tH := tH + mWins[4].texts[5].rect.H;
     end;


  mWins[4].rect.H:=tH + 5;
  if mWins[4].rect.W + mouse_X > scr_w then
     mWins[4].rect.X:= mouse_x - mWins[4].rect.W
  else
     mWins[4].rect.X:=Mouse_X + 16;

  if mWins[4].rect.H + mouse_Y > scr_h then
     mWins[4].rect.Y:= mouse_y - mWins[4].rect.H
  else
     mWins[4].rect.Y:=Mouse_Y + 16;

  mWins[4].visible:=true;
 // Chat_AddMessage(0, 'S', u_BoolToStr(mWins[4].visible) + ' ' + u_FloatToStr(mWins[4].rect.X) + ' ' + u_FloatToStr(mWins[4].rect.Y) + ' ' +u_FloatToStr(mWins[4].rect.w) + ' ' + u_FloatToStr(mWins[4].rect.H));
end;

procedure pum_Nick_open(sender : UTF8String);
var i, n: integer;
begin
  // меню, открывающееся при правом клике на игроке
  puMenu := puMenuZero; //           обнулим сначала;
  puMenu.exist := true;
  puMenu.eTime := 0;
  puMenu.mType := 1;
  puMenu.sender := sender;

  n := 0;
  puMenu.elements[n].exist := true;
  puMenu.elements[n].enable := true;
  puMenu.elements[n].Text := 'Private message';
  puMenu.elements[n].action:= 1;
  inc(n);

  puMenu.elements[n].exist := true;
  puMenu.elements[n].enable := false;
  puMenu.elements[n].Text := 'Inspect';
  puMenu.elements[n].action:= 0;
  inc(n);

  puMenu.elements[n].exist := true;
  puMenu.elements[n].enable := false;
  puMenu.elements[n].Text := 'Invite';
  puMenu.elements[n].action:= 0;
  inc(n);

  puMenu.elements[n].exist := true;
  puMenu.elements[n].enable := false;
  puMenu.elements[n].Text := 'Trade';
  puMenu.elements[n].action:= 0;
  inc(n);

  puMenu.elements[n].exist := true;
  puMenu.elements[n].enable := true;
  puMenu.elements[n].Text := 'Duel';
  puMenu.elements[n].action:= 2;
  inc(n);


  for I := 0 to n do
  begin  // заполняем прямоугольники для отрисовки, частные и общий
      puMenu.elements[i].rect.W := Text_GetWidth( fntMain, puMenu.elements[i].Text ) + 10;
      if puMenu.elements[i].rect.W > puMenu.rect.W then
         puMenu.rect.W := puMenu.elements[i].rect.W;
      puMenu.elements[i].rect.H := Text_GetHeight( fntMain, puMenu.elements[i].rect.W, puMenu.elements[i].Text);
      puMenu.rect.H := puMenu.rect.H + puMenu.elements[i].rect.H;
  end;

  // теперь нужно определить в какую сторону откроется меню, в зависимости от положения на экране
  if puMenu.rect.W + Mouse_X < scr_w - 50 then
     puMenu.rect.X := Mouse_X else
     puMenu.rect.X := Mouse_X - puMenu.rect.W;

  if puMenu.rect.Y + Mouse_Y < scr_H - 50 then
     puMenu.rect.Y := Mouse_Y else
     puMenu.rect.Y := Mouse_Y - puMenu.rect.H;

  // и расставить координаты элементов, относительно этого всего
  for I := 0 to n do
      begin
        puMenu.elements[i].rect.X := puMenu.rect.X;
        puMenu.elements[i].rect.Y := puMenu.rect.Y + i * puMenu.elements[i].rect.H;
      end;
end;

procedure pum_Item_open(wID, sID: longword; sender : utf8string);
var i, n, rs1, rs2: integer;  s: string;
begin
  // меню, открывающееся при правом клике на игроке
  puMenu := puMenuZero; //           обнулим сначала;
  puMenu.exist := true;
  puMenu.eTime := 0;
  puMenu.mType := 2;
  puMenu.sID := sID;
  puMenu.wID := wID;
  puMenu.sender:=sender;
  n := 0;

  if puMenu.wID = 14 then
     begin
       puMenu.elements[n].exist := true;
       puMenu.elements[n].enable := true;
       puMenu.elements[n].Text := 'Buy';
       puMenu.elements[n].action:= 2;
       inc(n);
     end;

  if puMenu.wID = 5 then
     begin
       rs1 := 0; rs2 := 0; s := '';
       puMenu.elements[n].exist := true;
       puMenu.elements[n].enable := false;
       if Items[mWins[wID].dnds[sID].data.contain].data.iType = 35 then
          if Items[mWins[wID].dnds[sID].data.contain].data.props[6] = 1 then
             begin        // чекаем локу
               if Items[mWins[wID].dnds[sID].data.contain].data.props[7] > 0 then
                  begin
                    inc(rs1);
                    if Items[mWins[wID].dnds[sID].data.contain].data.props[7] = activechar.header.loc then
                       inc(rs2);
                    Chat_AddMessage(0, 's', 'loc ' + IntToStr(rs2));
                  end;
               if Items[mWins[wID].dnds[sID].data.contain].data.props[8] > 0 then
                  begin       // чекаем инвентарь
                    inc(rs1);
                    for i := 1 to high(mWins[5].dnds) do
                    begin
                      if mWins[5].dnds[i].data.contain <> 0 then
                         if mWins[5].dnds[i].data.contain = Items[mWins[wID].dnds[sID].data.contain].data.props[8] then
                            begin
                              inc(rs2);
                              break;
                            end;
                    end;
                  end;
               if rs1 = rs2 then puMenu.elements[n].enable := true;
             end;
       puMenu.elements[n].Text := 'Use';
       puMenu.elements[n].action:= 4;
       inc(n);
     end;

  puMenu.elements[n].exist := true;
  puMenu.elements[n].enable := true;
  puMenu.elements[n].Text := 'Add to chat';
  puMenu.elements[n].action:= 1;
  inc(n);

  if puMenu.wID = 5 then
     begin
       puMenu.elements[n].exist := true;
       puMenu.elements[n].enable := false;
       puMenu.elements[n].Text := 'Delete';
       puMenu.elements[n].action:= 0;
       inc(n);
     end;

   if (mWins[14].visible = true) and (mWins[5].visible = true) and (puMenu.wID = 5) then
     begin
       puMenu.elements[n].exist := true;
       puMenu.elements[n].enable := true;
       puMenu.elements[n].Text := 'Sell';
       puMenu.elements[n].action:= 3;
       inc(n);
     end;

  for I := 0 to n do
  begin  // заполняем прямоугольники для отрисовки, частные и общий
      puMenu.elements[i].rect.W := Text_GetWidth( fntMain, puMenu.elements[i].Text ) + 10;
      if puMenu.elements[i].rect.W > puMenu.rect.W then
         puMenu.rect.W := puMenu.elements[i].rect.W;
      puMenu.elements[i].rect.H := Text_GetHeight( fntMain, puMenu.elements[i].rect.W, puMenu.elements[i].Text);
      puMenu.rect.H := puMenu.rect.H + puMenu.elements[i].rect.H;
  end;

  // теперь нужно определить в какую сторону откроется меню, в зависимости от положения на экране
  if puMenu.rect.W + Mouse_X < scr_w - 50 then
     puMenu.rect.X := Mouse_X else
     puMenu.rect.X := Mouse_X - puMenu.rect.W;

  if puMenu.rect.Y + Mouse_Y < scr_H - 50 then
     puMenu.rect.Y := Mouse_Y else
     puMenu.rect.Y := Mouse_Y - puMenu.rect.H;

  // и расставить координаты элементов, относительно этого всего
  for I := 0 to n do
      begin
        puMenu.elements[i].rect.X := puMenu.rect.X;
        puMenu.elements[i].rect.Y := puMenu.rect.Y + i * puMenu.elements[i].rect.H;
      end;
end;

procedure pum_Close;
begin
  puMenu := puMenuZero;
end;

procedure dlg_Click(dType, dID : longword);
var p: TProps; i, q : integer;
begin
if mWins[7].visible then
begin
  if dType = 12 then      // пройти мимо
     begin
       mWins[7].visible:=false;
       igs := igsNone;
     end;

  if dType = 1 then            // начать драку
     begin
       mWins[7].visible:=false;
       igs := igsNone;
       // SendData( inline_PkgCompile(25, u_IntToStr(dID) + '`1`'));
     end;

  if dType = 3 then
     begin
       // SendData( inline_PkgCompile(23, u_IntToStr(dID) + '`2`'));   // начать драчку
       mWins[7].visible:=false;
       mWins[8].visible:=false;
     end;

  if dType = 7 then
     begin
       if tutorial = 3 then
          begin
            tutorial := 4;
            // sleep(50);
            // SendData( inline_PkgCompile(4, u_IntToStr(dID) + '`1`'));
          end;
      // SendData( inline_PkgCompile(23, u_IntToStr(dID) + '`2`'));   // сдать квест
     end;

  if (dType = 11) or (dType = 10) then                     // взять квест
     begin
       // SendData( inline_PkgCompile(23, u_IntToStr(dID) + '`1`'));
     end;
end;

if mWins[9].visible then
   begin
    { q := qlog_GetQLID(dID);
     mWins[8].visible:=true;
     mWins[8].rect.X:= mWins[9].rect.X + mWins[9].rect.W;
     mWins[8].rect.Y:= mWins[9].rect.Y;
     mWins[8].btns[1].visible:=false;
     mWins[8].btns[2].visible:=false;
     for i := 1 to 10 do
         begin
           mWins[8].dnds[i].contains:=0;
           mWins[8].dnds[i].dur:=0;
         end;
     for i:=1 to 5 do
         mWins[8].texts[i].visible:=true;
     mWins[8].texts[1].Text:= quest_log[q].Name;
     mWins[8].texts[3].Text:= quest_log[q].Descr;
     mWins[8].texts[5].Text:= quest_log[q].Obj;
     mWins[8].imgs[1].texID:= quest_log[q].qpID;
     p := GetItemProps(quest_log[q].Reward);
     }
     if p[1] > 0 then
     begin
       mWins[8].dnds[1].data.contain:=1000;
       mWins[8].dnds[1].data.dur:=p[1];
     end;

     if p[2] > 0 then
     begin
       mWins[8].dnds[2].data.contain:=999;
       mWins[8].dnds[2].data.dur:=p[2];
     end;

     for i := 3 to 10 do
     if p[i * 2 - 3] <> 0 then
     begin
       mWins[8].dnds[i].data.contain:=p[i * 2 - 3];
       mWins[8].dnds[i].data.dur:=p[i * 2 - 2];
     end;
   end;
end;

procedure mGui_Init;
var i, j: integer ;
    ItemCache : zglTFile;
    data      : TItemData;
begin
{$R+}
try
  if File_Exists('Cache\items.idb') then
     begin
       File_Open(ItemCache, 'Cache\items.idb', FOM_OPENR);

       if file_GetSize(ItemCache) >= sizeof(data) then
       while file_getpos(ItemCache) < file_getsize(ItemCache) do
       begin
        // Writeln(file_getpos(itemcache), '/', file_getsize(itemcache));
         file_Read(ItemCache, data, sizeof(data));
         if data.ID <> 0 then
            begin
              Items[data.ID].exist:= true;
              Items[data.ID].data := data;
            end;
       end;
     end else file_open(itemCache, 'Cache\items.idb', FOM_CREATE);
except
  On e: ERangeError do writeln('ERangeError :: uMyGui :: CacheLoad' );
end;
  File_Close(ItemCache);
{$R-}

  items[1000].exist:=true;
  items[1000].data.iID:=9;
  items[1000].data.name:='Exp';
  items[1000].data.iType:=32;
  items[1000].data.ID:=1000;

  items[999].exist:=true;
  items[999].data.name:='Gold';
  items[999].data.iType:=32;
  items[999].data.iID:=10;
  items[999].data.ID:=999;

  Spells[1].exist:=true;
  Spells[1].CD:=10;
  Spells[1].range:=8;
  Spells[1].sType:=1;
  Spells[1].AP_Cost:=25;
  Spells[1].MP_cost:=27;
  Spells[1].school:=5;
  Spells[1].x:=15;
  Spells[1].ID:= 1;
  Spells[1].iID:= 1;

  Spells[2].exist:=true;
  Spells[2].CD:=10;
  Spells[2].range:=1;
  Spells[2].sType:=2;
  Spells[2].AP_Cost:=5;
  Spells[2].MP_cost:=0;
  Spells[2].school:=1;
  Spells[2].x:= 0;
  Spells[2].ID:= 2;
  Spells[2].iID:= 2;

  Spells[3].exist:=true;
  Spells[3].CD:=10;
  Spells[3].range:=1;
  Spells[3].sType:=2;
  Spells[3].AP_Cost:=1;
  Spells[3].MP_cost:=0;
  Spells[3].school:=1;
  Spells[3].x:= 0;
  Spells[3].ID:= 3;
  Spells[3].iID:= 3;

  Spells[4].exist:=true;
  Spells[4].CD:=10;
  Spells[4].range:= 8;
  Spells[4].sType:= 3;
  Spells[4].AP_Cost:= 5;
  Spells[4].MP_cost:= 0;
  Spells[4].school:= 6;
  Spells[4].x:= 50;
  Spells[4].ID:= 4;
  Spells[4].iID:= 6;

  Spells[5].exist:=true;
  Spells[5].CD:=15;
  Spells[5].range:= 5;
  Spells[5].sType:= 4;
  Spells[5].AP_Cost := 25;
  Spells[5].MP_cost := 37;
  Spells[5].school:=3;
  Spells[5].x:= 17;
  Spells[5].ID:= 5;
  Spells[5].iID:= 8;

  Spells[6].exist:=true;
  Spells[6].CD:=15;
  Spells[6].range:= 6;
  Spells[6].sType:= 1;
  Spells[6].AP_Cost := 20;
  Spells[6].MP_cost := 34;
  Spells[6].school :=4;
  Spells[6].x := 20;
  Spells[6].ID:= 6;
  Spells[6].iID:= 5;

  Spells[7].exist:=true;
  Spells[7].CD:=10;
  Spells[7].range:=1;
  Spells[7].sType:=2;
  Spells[7].AP_Cost:=5;
  Spells[7].MP_cost:=0;
  Spells[7].school:=1;
  Spells[7].x:= 0;
  Spells[7].ID:= 7;
  Spells[7].iID:= 9;

  Spells[8].exist:=true;
  Spells[8].CD:=50;
  Spells[8].range:= 5;
  Spells[8].sType:= 1;
  Spells[8].AP_Cost := 20;
  Spells[8].MP_cost := 50;
  Spells[8].school :=4;
  Spells[8].x := 75;
  Spells[8].y := 10;
  Spells[8].ID:= 8;
  Spells[8].iID:= 10;

  Spells[9].exist:=true;
  Spells[9].CD:=10;
  Spells[9].range:=1;
  Spells[9].sType:=2;
  Spells[9].AP_Cost:=15;
  Spells[9].MP_cost:=0;
  Spells[9].school:=2;
  Spells[9].x:= 0;
  Spells[9].ID:= 9;
  Spells[9].iID:= 19;

  Spells[10].exist:=true;
  Spells[10].CD:=10;
  Spells[10].range:=1;
  Spells[10].sType:=2;
  Spells[10].AP_Cost:=1;
  Spells[10].MP_cost:=0;
  Spells[10].school:=7;
  Spells[10].x:= 0;
  Spells[10].ID:= 10;
  Spells[10].iID:= 20;

  Spells[11].exist:=true;
  Spells[11].CD:=10;
  Spells[11].range:=1;
  Spells[11].sType:=2;
  Spells[11].AP_Cost:=10;
  Spells[11].MP_cost:=0;
  Spells[11].school:=7;
  Spells[11].x:= 0;
  Spells[11].ID:= 11;
  Spells[11].iID:= 14;

  Spells[12].exist:=true;
  Spells[12].CD:=15;
  Spells[12].range:= 4;
  Spells[12].sType:= 1;
  Spells[12].AP_Cost := 25;
  Spells[12].MP_cost := 34;
  Spells[12].school :=3;
  Spells[12].x := 60;
  Spells[12].ID:= 12;
  Spells[12].iID:= 12;

  Spells[13].exist:=true;
  Spells[13].CD:=10;
  Spells[13].range:=1;
  Spells[13].sType:=2;
  Spells[13].AP_Cost:=1;
  Spells[13].MP_cost:=0;
  Spells[13].school:=6;
  Spells[13].x:= 0;
  Spells[13].ID:= 13;
  Spells[13].iID:= 21;

  Spells[14].exist:=true;
  Spells[14].CD:=10;
  Spells[14].range:=1;
  Spells[14].sType:=2;
  Spells[14].AP_Cost:=25;
  Spells[14].MP_cost:=50;
  Spells[14].school:=5;
  Spells[14].x:= 0;
  Spells[14].ID:= 14;
  Spells[14].iID:= 22;

  Spells[15].exist:=true;
  Spells[15].CD:=10;
  Spells[15].range:=1;
  Spells[15].sType:=2;
  Spells[15].AP_Cost:=10;
  Spells[15].MP_cost:=0;
  Spells[15].school:=2;
  Spells[15].x:= 0;
  Spells[15].ID:= 14;
  Spells[15].iID:= 11;

  Spells[16].exist:=true;
  Spells[16].CD:=10;
  Spells[16].range:=1;
  Spells[16].sType:=2;
  Spells[16].AP_Cost:=0;
  Spells[16].MP_cost:=0;
  Spells[16].school:=5;
  Spells[16].x:= 0;
  Spells[16].ID:= 16;
  Spells[16].iID:= 23;

  Spells[93].exist:=true;
  Spells[93].school:=high(byte);
  Spells[93].AP_cost:=5;
  Spells[93].hkey:='f5';

  Spells[95].exist:=true;
  Spells[95].school:=high(byte);
  Spells[95].AP_Cost:=1;

  Spells[96].exist:=true;
  Spells[96].school:=high(byte);
  Spells[96].hkey:='f6';

  Spells[99].exist:=true;
  Spells[99].school:=high(byte);
  Spells[99].hkey:='Space';

  for i := 1 to 99 do
    begin
      Spells[i].name:=ST[i];
      Spells[i].bdiscr:=SD[i];
    end;

  mWins[11].dnds[1].data.contain:=2;

end;


end.


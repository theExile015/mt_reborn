unit uLUA;

{$mode delphi}
{$codepage utf8}
interface

uses
  sysutils,
  uVar,
  zglHeader,
  lua,
  lualib,
  lauxlib,
  uAdd,
  uCombatManager,
  uChat,
  u_MM_GUI;

var
  Lua_1 : Plua_State;

procedure InitLUA;
procedure FreeLUA;
procedure RunLUAScript(f : string);

procedure Console_Draw;
procedure Console_Update;

implementation

uses
  uMyGui, uLoader ;

procedure lua_mgui_clear;
var i, j: integer;
begin
  for i := 1 to high(mWins) do
    if mWins[i].exist then
       begin
         mWins[i].exist:=false;
         for j := 1 to high(mWins[i].btns) do mWins[i].btns[j].exist:=false;
         for j := 1 to high(mWins[i].texts) do mWins[i].texts[j].exist:=false;
         for j := 1 to high(mWins[i].dnds) do mWins[i].dnds[j].exist:=false;
         for j := 1 to high(mWins[i].imgs) do mWins[i].imgs[j].exist:=false;
         for j := 1 to high(mWins[i].pbs) do mWins[i].pbs[j].exist:=false;
       end;
end;

function lua_mgui_AddWindow() : byte;
var x, y, w, h : single;
    t : integer;
    s : utf8string;
begin
  t := Round(Lua_ToNumber(lua_1, 1));
  s := AnsiToUtf8(Lua_ToString(lua_1, 2));
  x := Lua_ToNumber(lua_1, 3);
  y := Lua_ToNumber(lua_1, 4);
  w := Lua_ToNumber(lua_1, 5);
  h := Lua_ToNumber(lua_1, 6);
  result := mgui_AddWindow(t, s, rect(x,y,w,h));
end;

function lua_mgui_AddButton() : byte;
var x, y, w, h : single;
    p, t : integer;
    s : utf8string;
begin
  p := round(Lua_ToNumber(lua_1, 1));
  t := round(lua_ToNumber(lua_1, 2));
  s := AnsiToUtf8(Lua_ToString(lua_1, 3));
  x := Lua_ToNumber(lua_1, 4);
  y := Lua_ToNumber(lua_1, 5);
  w := Lua_ToNumber(lua_1, 6);
  h := Lua_ToNumber(lua_1, 7);
  result := mgui_AddButton(p, t, s, rect(x,y,w,h));
end;

function lua_mgui_AddText() : byte;
var x, y, w, h : single;
    c : longword;
    s : utf8string;
    p, o : integer;
begin
  p := round(Lua_ToNumber(lua_1, 1));
  o := round(Lua_ToNumber(lua_1, 2));
  s := AnsiToUtf8(Lua_ToString(lua_1, 3));
  x := Lua_ToNumber(lua_1, 4);
  y := Lua_ToNumber(lua_1, 5);
  w := Lua_ToNumber(lua_1, 6);
  h := Lua_ToNumber(lua_1, 7);
  c := Round(Lua_ToNumber(lua_1, 8));
  result := mgui_AddText(p, o, s, rect(x,y,w,h), c);
end;

function lua_mgui_AddImg(): byte;
var p, t : integer;
    i : utf8string;
    x, y, w, h: single;
begin
  p := round(Lua_ToNumber(lua_1, 1));
  i := Lua_ToString(lua_1, 2);
  t := round(Lua_ToNumber(lua_1, 3));
  x := Lua_ToNumber(lua_1, 4);
  y := Lua_ToNumber(lua_1, 5);
  w := Lua_ToNumber(lua_1, 6);
  h := Lua_ToNumber(lua_1, 7);
  result := mgui_AddImg(p, t, rect(x, y, w, h), i);
end;

function lua_mgui_Adddnd(): byte;
var p, t, s : integer;
    x, y, w, h: single;
begin
  p := round(Lua_ToNumber(lua_1, 1));
  t := round(Lua_ToNumber(lua_1, 2));
  s := round(Lua_ToNumber(lua_1, 3));
  x := Lua_ToNumber(lua_1, 4);
  y := Lua_ToNumber(lua_1, 5);
  w := Lua_ToNumber(lua_1, 6);
  h := Lua_ToNumber(lua_1, 7);
  result := mgui_AddDnDSlot(p, t, s, rect(x, y, w, h));
end;

function lua_mgui_AddPB(): byte;
var p, c : integer;
    x, y, w, h: single;
begin
  p := round(Lua_ToNumber(lua_1, 1));
  c := round(Lua_ToNumber(lua_1, 2));
  x := Lua_ToNumber(lua_1, 3);
  y := Lua_ToNumber(lua_1, 4);
  w := Lua_ToNumber(lua_1, 5);
  h := Lua_ToNumber(lua_1, 6);
  result := mgui_AddPBar(p, c, rect(x, y, w, h));
end;

function lua_mgui_SetWVis() : byte;
var p : integer;
    v : boolean;
begin
  p := round(Lua_ToNumber(lua_1, 1));
  v := Lua_ToBoolean(lua_1, 2);
  mgui_SetWinVis(p, v);
end;

function lua_loader_GetTListItem() : byte;
var p, n : utf8string;
    i, w, h : integer;
begin
  n := utf8string(Lua_ToString(lua_1, 1));
  p := utf8String(Lua_ToString(lua_1, 2));
  w := Round(Lua_ToNumber(lua_1, 3));
  h := Round(Lua_ToNumber(lua_1, 4));

  p := stringreplace(p, '!', '\', [rfReplaceAll, rfIgnoreCase]);


  for i := 1 to high(tex_list) do
    if not tex_list[i].exist then
       begin
         tex_list[i].exist:=true;
         tex_list[i].path:=p;
         tex_list[i].name:=n;
         tex_list[i].w:=w;
         tex_list[i].h:=h;
       //Log_Add('[dList] ' + IntToStr(i) + ' >> ' + n + ' => ' + p);
         exit;
       end;
end;

function lua_draw_rect(): byte;
var x, y, w, h : single;
    color, alpha : longword;
    flag : longword;
begin
  x := Lua_ToNumber(lua_1, 1);
  y := Lua_ToNumber(lua_1, 2);
  w := Lua_ToNumber(lua_1, 3);
  h := Lua_ToNumber(lua_1, 4);
  color := Round(Lua_ToNumber(lua_1, 5));
  alpha := Round(Lua_ToNumber(lua_1, 6));
  flag  := Round(Lua_ToNumber(lua_1, 7));

  pr2d_Rect(x, y, w, h, color, alpha, flag);
end;

function lua_draw_text(): byte;
var x, y, w, h, scale, step : single;
    text : utf8string;
    fnt, color, alpha, flag : longword;
begin
  fnt := Round(Lua_ToNumber(lua_1, 1));
  x := Lua_ToNumber(lua_1, 2);
  y := Lua_ToNumber(lua_1, 3);
  w := Lua_ToNumber(lua_1, 4);
  h := Lua_ToNumber(lua_1, 5);
  scale := Lua_ToNumber(lua_1, 6);
  step := Lua_ToNumber(lua_1, 7);
  text := Lua_ToString(lua_1, 8);
  alpha := Round(Lua_ToNumber(lua_1, 9));
  color := Round(Lua_ToNumber(lua_1, 10));
  flag  := Round(Lua_ToNumber(lua_1, 11));

 // text_Draw(fntMain, x, y, 'Test', 0);
  text_DrawInRectEx(fntCombat, rect(x, y, w, h), scale, step, Text, alpha, color, flag);
end;

function lua_set_gui_params(): byte;
var dy, dy2 : single;
    skin, color    : longword;
begin
  skin := Round(Lua_ToNumber(lua_1, 1));
  dy := lua_toNumber(lua_1, 2);
  dy2:= lua_toNumber(lua_1, 3);
  color := Round(Lua_ToNumber(lua_1, 4));

  frmPak[skin].dy := dy; frmPak[skin].dy2:= dy2;
  frmPak[skin].bgr_color:=color;
end;

function lua_set_gui_chat_color(): byte;
begin
  chat_color.bgr     := round(lua_toNumber(lua_1, 1));
  chat_color.regular := round(lua_toNumber(lua_1, 2));
  chat_color.weak    := round(lua_toNumber(lua_1, 3));
  chat_color.normal  := round(lua_toNumber(lua_1, 4));
end;

function lua_combat_start(): byte;
begin
  Combat_Init;
  sleep(50);
  Chat_AddMessage(3, 'S', 'You joined battle #' + IntToStr($ABC) );
  combat_id := $ABC;
  NonameFrame41.Move(scr_w - 120, scr_h - 190);
  NonameFrame41.Show;
  gs  := gsCLoad;
  iga := igaCombat;

  units[1].exist:=true;
  units[1].alive:=true;
  units[1].pos.x:=2;
  units[1].pos.y:=2;
  units[1].Direct:=3;
  units[1].sex:=1;
  units[1].gSet.body:=1;
  units[1].gSet.head:=1;
  units[1].gSet.MH:=1;
  units[1].gSet.OH:=1;

  your_unit := 1;
end;

function lua_offline(): byte;
begin
  Nonameform1.Hide;
  a_p := 0;
  gs := gsPreGame;
  LoadLoc(1);
end;

function lua_save_cache(): byte;
var i: integer ;
    ItemCache : zglTFile;
begin
  file_open(ItemCache, 'Cache\items.idb', FOM_OPENRW);

  for i := 1 to high(items) do
    if items[i].exist then
       file_write(ItemCache, items[i].data, sizeof(items[i].data));

  file_close(ItemCache);
end;

procedure InitLUA;
begin
  Lua_1 := lua_open;
  if (Lua_1 = nil) then
      begin
        Log_Add(' Lua initialization error! ' );
        zgl_Exit();
      end;

  lua_register(lua_1, 'gui_Clear', @lua_mgui_Clear);
  lua_register(lua_1, 'gui_AddWindow', @lua_mgui_AddWindow);
  lua_register(lua_1, 'gui_AddButton', @lua_mgui_AddButton);
  lua_register(lua_1, 'gui_AddText', @lua_mgui_AddText);
  lua_register(lua_1, 'gui_AddImg', @lua_mgui_AddImg);
  lua_register(lua_1, 'gui_AddDND', @lua_mgui_AddDnD);
  lua_register(lua_1, 'gui_AddPB', @lua_mgui_AddPB);
  lua_register(lua_1, 'gui_SetFormVis', @lua_mgui_SetWVis);
  lua_register(lua_1, 'set_gui_params', @lua_set_gui_params);
  lua_register(lua_1, 'set_gui_chat_color', @lua_set_gui_chat_color);

  lua_register(lua_1, 'gfx_Rect', @lua_draw_rect);
  lua_register(lua_1, 'gfx_Text', @lua_draw_text);

  lua_register(lua_1, 'loader_GetListItem', @lua_loader_GetTListItem);

  lua_register(lua_1, 'core_combat', @lua_combat_start);
  lua_register(lua_1, 'core_offline', @lua_offline);
  lua_register(lua_1, 'core_savecache', @lua_save_cache);

  luaL_openlibs(Lua_1);
end;

procedure RunLUAScript(f : string);
begin
try
  if f = 'gui.lua' then
      begin
        lua_PushNumber(lua_1, scr_w);
        lua_SetGlobal(lua_1, 'scr_w');
        lua_PushNumber(lua_1, scr_h);
        lua_SetGlobal(lua_1, 'scr_h');
      end;
  if f <> 'user.lua' then Log_Add('Executing script...' + f);

  Lua_dofile(Lua_1, PChar(f));

except
  on e:exception do
    log_add(e.message);
end;
end;

procedure FreeLUA();
begin
  lua_close(Lua_1);
end;

procedure Console_Draw;
var y : single;
begin
  if not con_visible then exit;

  pr2d_Rect(0, 0, scr_w, 150, $777777, 150, PR2D_FILL);
  y := Text_GetHeight(fntMain, scr_w - 20, con_log, 1, 0);
  Text_Draw( fntMain, 10, 110 - y, con_Log);
  Text_Draw( fntMain, 10, 130, '/>' + Con_String + '|');
end;

procedure Console_Update;
begin
  if key_Press(K_F10) then
     if con_visible then
        begin
          con_visible := false;
          Key_EndReadText();
        end else
        begin
          con_visible := true;
          Key_BeginReadText(con_string, 100);
        end;

  if con_visible then
     begin
       con_string := key_GetText();
       if key_press(K_ENTER) then
          begin
             Key_EndReadText();
             lua_DoString(Lua_1, PChar(con_String));
             con_Log := con_log + con_String + #13#10;
             con_string := '';
             Key_BeginReadText(con_string, 100);
          end;
     end;

end;

end.


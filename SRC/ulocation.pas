unit uLocation;

{$mode objfpc}{$H+}

interface

uses
  zglHeader,
  uVar,
  uAdd,
  uTileMap;

procedure location_Draw();
procedure location_Update();

procedure objMan_Clear;
procedure objMan_Fill;
procedure objMan_Add(_x, _y, _w, _h, _cType, _oID, _gID, _tID, _enabled, ani: integer;
  _name: utf8string);
procedure objMan_HideAll();
procedure objMan_SetVisible(gID: integer);

procedure objMan_Update;
procedure objMan_Draw;

implementation

uses uMyGUITT, uXClick;

procedure location_Draw();
begin
  if gs = gsGame then
    DrawTiles();
  objMan_Draw;
end;

procedure location_Update();
var
  p: ^dword;
begin
  scr_ReadPixels(p, 100, 100, 1, 1);    // читаем угловой пиксель
  if gs = gsGame then
    // если он чёрный, значит локация не прогрузилась
    if iga = igaLoc then
      // пробуем грузануть её ещё раз
      if p^ = 1291845632 then
        gs := gsLLoad;
  objMan_Update;
end;

procedure objMan_Clear;                    // обнуляем все объекты
var
  i: integer;
begin
  for i := 1 to high(objStore) do
  begin
    objStore[i].exist := False;
    objStore[i].Data.x := 0;
    objStore[i].Data.y := 0;
    objStore[i].Data.w := 0;
    objStore[i].Data.h := 0;
    objStore[i].Data.cType := 0;
    objStore[i].cCircle := circle(0, 0, 0);
    objStore[i].Data.oID := 0;
    objStore[i].Data.gID := 0;
    objStore[i].Data.tID := 0;
    objStore[i].Visible := False;
    objStore[i].Data.Enabled := 0;
    objStore[i].MouseOver := False;
    objStore[i].anim := False;
    objStore[i].a_fr := 0;
    objStore[i].c_fr := 1;
  end;
end;

procedure objMan_Add(_x, _y, _w, _h, _cType, _oID, _gID, _tID, _enabled, ani: integer;
  _name: utf8string);
begin
 { if _gID < high(objStore) then
    with objStore[_gID] do
    begin
      Data.gID := _gID;
      Data.tID := _tID;
      Data.oID := _oID;
      Data.x := _x;
      y := _y;
      w := _w;
      h := _h;
      cType := _cType;
      if _cType = 1 then
        cCircle := Circle(x + w / 2, y + h / 2, h / 2);
      if _enabled = 1 then
        Enabled := True
      else
        Enabled := False;
      Visible := True;
      Name := _name;
      exist := True;
      a_fr := ani;
      c_fr := 1;
      if a_fr > 0 then
        anim := True;
    end;

  if tutorial = 0 then
    if _gID = 15 then
      // Запускаем диалог с ментором
    begin
      // SendData( inline_PkgCompile(24, u_IntToStr(15) + '`' + u_IntToStr(1) + '`'));
      //sleep(50);
      // SendData( inline_PkgCompile(23, u_IntToStr(26) + '`1`'));
      tutorial := 1;
      // sleep(50);
      // SendData(inline_PkgCompile(4, activechar.Name + '`1`'));
      //igs := igsNPC;
    end;
   }
end;

procedure objMan_Fill;
var
  i: integer;
begin
  with objStore[11] do
  begin
    exist := True;

    Data.x := 1520;
    Data.y := 330;
    Data.w := 96;
    Data.h := 128;

    // cCircle := circle( x + w/2 , y + h/2 , h/2) ;
    Data.oID := 1;
    Data.gID := 11;
    Data.tID := 8;
    Visible := True;
    Data.Enabled := 1;
    anim := True;
    a_fr := 6;
    if cCircle.Radius <> 0 then
      Data.cType := 1;
  end;

end;

procedure objMan_HideAll();
var
  i: integer;
begin
  for i := 1 to high(objStore) do
    objStore[i].Visible := False;
end;

procedure objMan_SetVisible(gID: integer);
begin
  if objStore[gID].exist then
    objStore[gID].Visible := True
  else
  begin
    Log_add('Unknown object ' + u_IntToStr(gID) + '. Request');
    // SendData(inline_pkgCompile(53, u_IntToStr(activechar.ID) + '`' + u_IntToStr(gID) + '`'));
    // sleep(50);
    exit;
  end;
end;

procedure objMan_Update;
var
  i: integer;
begin
  if igs <> igsNone then
    Exit;

  for i := 1 to high(objStore) do
    if objStore[i].exist and objStore[i].Visible then
      if objStore[i].Data.tID = 0 then
         DoRequestObj(i);

  for i := 1 to high(objStore) do
    if objStore[i].exist and (objStore[i].Data.Enabled = 1) and objStore[i].Visible then
    begin
      if objStore[i].Data.cType = 1 then    // проверяем на маус овер
        objStore[i].MouseOver :=
          col2d_PointInCircle(_Mouse_X, _Mouse_Y, objStore[i].cCircle)
      else
        objStore[i].MouseOver :=
          col2d_PointInRect(_Mouse_X, _Mouse_Y,
          rect(
          objStore[i].Data.x,
          objStore[i].Data.y,
          objStore[i].Data.w,
          objStore[i].Data.h));
      if objStore[i].anim then
      begin
        if a_p div 9 = a_p / 9 then
          Inc(objstore[i].c_fr);
        if objstore[i].c_fr > objstore[i].a_fr then
          objstore[i].c_fr := 1;
      end;

      if objStore[i].MouseOver then
      begin
        mgui_TTOpen(3);
        if mouse_click(M_BLEFT) then
        begin
          DoObjectClick(objStore[i].Data.gID);
          if (objStore[i].Data.gID = 1) and (tutorial = 2) then
          begin
            tutorial := 3;
            // SendData(inline_PkgCompile(4, activechar.Name + '`3`'));
          end;
        end;
      end;

    end;
end;

{ ID иконок
  1 - пассивный моб, битва не идёт
  2 - агрессивный моб, битва не идёт
  3 - битва идёт, мест нет
  4 - битва идёт, есть места
  5 - ресурс для добычи, никто не добывает
  6 - ресурс для добычи, кто-то добывает
  7 - ресурс для добычи, мест нет (или нет требований)
  8 - ХХХ
  9 - с объектом можно взаимодействовать
  10 - не определено
  11 - не оределено
  12..16 - XXX
}
function GetIID(oID: word): byte;
  // возвращает номер иконки исходя из номера объекта
begin
  Result := 9;
  //if oID =
  if oID = 5 then
    Result := 1;
end;

procedure objMan_Draw;
var
  i: integer;
begin
  for i := 1 to high(objStore) do
    if objStore[i].exist and objStore[i].Visible then
    begin
     if objStore[i].Data.tID <> 0 then
     if (objStore[i].Data.Enabled = 1) and objStore[i].MouseOver then
        // отрисовка с подсветкой
      begin
        with objStore[i] do
        begin
          fx2d_SetColor($F4A460);
          if not Anim then
            SSprite2d_Draw(tex_Objs[Data.tID], Data.X, Data.Y, Data.W, Data.H, 0, 255,
              FX_BLEND or FX_COLOR)
          else
            ASprite2d_Draw(tex_Objs[Data.tID], Data.X, Data.Y, Data.W, Data.H, 0, c_fr,
              255, FX_BLEND or FX_COLOR);
          ASprite2d_Draw(tex_LocIcons, Data.X + Data.W / 2 - 16, Data.Y - 32, 24, 24, 0, GetIID(Data.oID),
            255, FX_BLEND or FX_COLOR);
        end;
      end
      else
        with objStore[i] do
          // отрисовка без подсветки
        begin
          fx2d_SetColor($FFFFFF);
          if not Anim then
            SSprite2d_Draw(tex_Objs[Data.tID], Data.X, Data.Y, Data.W, Data.H, 0)
          else
            ASprite2d_Draw(tex_Objs[Data.tID], Data.X, Data.Y, Data.W, Data.H, 0, c_fr, 255);
          if Data.Enabled = 1 then
            // если объект доступен для использования
            // рисуем иконку
            ASprite2d_Draw(tex_LocIcons, Data.X + Data.W / 2 - 16, Data.Y - 32, 24, 24, 0, GetIID(Data.oID),
              255, FX_BLEND or FX_COLOR);
        end;
    end;
end;

end.

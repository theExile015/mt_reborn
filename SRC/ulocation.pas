unit uLocation;

{$mode objfpc}{$H+}

interface

uses
  zglHeader,
  uVar,
  uAdd,
  uMyGui,
  uNetCore,
  uTileMap;

procedure location_Draw();
procedure location_Update();

procedure objMan_Clear;
procedure objMan_Fill;
procedure objMan_Add(_x, _y, _w, _h, _cType, _oID, _gID, _tID, _enabled, ani: integer; _name : utf8string);
procedure objMan_HideAll();
procedure objMan_SetVisible(gID : integer);

procedure objMan_Update;
procedure objMan_Draw;

implementation

procedure location_Draw();
begin
  if gs = gsGame then
     DrawTiles();
  objMan_Draw;
end;

procedure location_Update();
begin
  objMan_Update;
end;

procedure objMan_Clear;                    // обнуляем все объекты
var i: integer;
begin
  for i := 1 to high(objStore) do
    begin
      objStore[i].exist   := false;
      objStore[i].x       := 0;
      objStore[i].y       := 0;
      objStore[i].w       := 0;
      objStore[i].h       := 0;
      objStore[i].cType   := 0;
      objStore[i].cCircle := circle(0, 0, 0);
      objStore[i].oID     := 0;
      objStore[i].gID     := 0;
      objStore[i].tID     := 0;
      objStore[i].visible := false;
      objStore[i].enabled := false;
      objStore[i].MouseOver := false;
      objStore[i].anim:= false;
      objStore[i].a_fr:=0;
      objStore[i].c_fr:=1;
    end;
end;

procedure objMan_Add(_x, _y, _w, _h, _cType, _oID, _gID, _tID, _enabled, ani: integer; _name : utf8string);
begin
  if _gID < high(objStore) then
     with objStore[_gID] do
        begin
          gID := _gID;
          tID := _tID;
          oID := _oID;
          x := _x;
          y := _y;
          w := _w;
          h := _h;
          cType := _cType;
          if _cType = 1 then
             cCircle := Circle(x + w/2, y + h/2, h/2);
          if _enabled = 1 then enabled := true else enabled := false;
          visible := true;
          name  := _name;
          exist := true;
          a_fr  := ani;
          c_fr  := 1;
          if a_fr > 0 then anim := true;
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

end;

procedure objMan_Fill;
var
  i: integer;
begin
    with objStore[11] do
      begin
        exist := true;

        x := 1520;
        y := 330;
        w := 96;
        h := 128;

       // cCircle := circle( x + w/2 , y + h/2 , h/2) ;
        oID := 1;
        gID := 11;
        tID := 8;
        visible := true;
        enabled := true;
        anim := true;
        a_fr := 6;
        if cCircle.Radius <> 0 then cType:= 1;
      end;

    with objStore[12] do
      begin
        exist := true;

        x := 1000;
        y := 200;
        w := 196;
        h := 220;

       // cCircle := circle( x + w/2 , y + h/2 , h/2) ;
        oID := 1;
        gID := 12;
        tID := 5;
        visible := true;
        enabled := true;
        anim := true;
        a_fr := 16;
        if cCircle.Radius <> 0 then cType:= 1;
      end;

   with objStore[13] do
      begin
        exist := true;

        x := 790;
        y := 210;
        w := 64;
        h := 128;

       // cCircle := circle( x + w/2 , y + h/2 , h/2) ;
        oID := 1;
        gID := 11;
        tID := 6;
        visible := true;
        enabled := true;
        anim := true;
        a_fr := 6;
        if cCircle.Radius <> 0 then cType:= 1;
      end;
end;

procedure objMan_HideAll();
var i: integer;
begin
  for i := 1 to high(objStore) do
      objStore[i].visible:= false;
end;

procedure objMan_SetVisible(gID : integer);
begin
  if objStore[gID].exist then
     objStore[gID].visible:= true
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
  i : integer;
begin
  if igs <> igsNone then Exit;

  //objMan_fill();
  //objstore[11].visible:=true;
  //objstore[12].visible:=true;
  //objstore[13].visible:=true;

 { for i := 0 to length(objStore) - 1 do
      if activechar.locID <> 1 then objstore[i].visible:=false else objstore[i].visible:=true;  }

  for i := 1 to high(objStore) do
    if objStore[i].exist and objStore[i].enabled and objStore[i].visible then
       begin
         if objStore[i].cType = 1 then    // проверяем на маус овер
            objStore[i].MouseOver := col2d_PointInCircle( _Mouse_X, _Mouse_Y, objStore[i].cCircle )
         else
            objStore[i].MouseOver := col2d_PointInRect( _Mouse_X, _Mouse_Y,
                                                        rect( objStore[i].x, objStore[i].y,
                                                              objStore[i].w, objStore[i].h ) );
         if objStore[i].anim then
            begin
              if a_p div 9 = a_p / 9 then
                 inc(objstore[i].c_fr);
              if objstore[i].c_fr > objstore[i].a_fr then objstore[i].c_fr := 1;
            end;

         if objStore[i].MouseOver then
            begin
             mgui_TTOpen(3);
             if mouse_click( M_BLEFT) then
                begin
                 // SendData( inline_PkgCompile(24, u_IntToStr(objStore[i].gID) + '`' + u_IntToStr(1) + '`'));

                  if (objStore[i].gID = 1) and (tutorial = 2) then
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
function GetIID(oID : word) : byte; // возвращает номер иконки исходя из номера объекта
begin
  result := 9;
  //if oID =
  if oID = 5 then result := 1;
end;

procedure objMan_Draw;
var
  i : integer;
begin
  for i := 1 to high(objStore) do
    if objStore[i].exist and objStore[i].visible then
       begin
         if objStore[i].enabled and objStore[i].MouseOver then  // отрисовка с подсветкой
         begin
         with objStore[i] do
            begin
              fx2d_SetColor( $F4A460 );
              if not Anim then
                 SSprite2d_Draw(tex_Objs[tID], X , Y , W , H , 0, 255, FX_BLEND or FX_COLOR)
              else
                 ASprite2d_Draw(tex_Objs[tID], X, Y, W, H, 0, c_fr, 255, FX_BLEND or FX_COLOR );
              ASprite2d_Draw(tex_LocIcons, X + W/2 - 16, Y - 32, 24, 24, 0, GetIID(oID),
                             255, FX_BLEND or FX_COLOR);
            end;
         end else
         with objStore[i] do                                  // отрисовка без подсветки
            begin
              fx2d_SetColor( $FFFFFF );
              if not Anim then
                 SSprite2d_Draw(tex_Objs[tID], X , Y , W , H , 0)
              else
                 ASprite2d_Draw(tex_Objs[tID], X, Y, W, H, 0, c_fr, 255 );
              if enabled then                                // если объект доступен для использования
                                                             // рисуем иконку
              ASprite2d_Draw(tex_LocIcons, X + W/2 - 16, Y - 32, 24, 24, 0, GetIID(oID),
                             255, FX_BLEND or FX_COLOR);
            end;
       end;
end;

end.


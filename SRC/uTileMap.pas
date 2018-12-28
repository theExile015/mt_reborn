unit uTileMap;

interface

uses
  zglHeader, uVar, SysUtils, Classes;

procedure loadMap(fname: string);
procedure DrawTiles;

var
  dm_x, dm_y: integer;

implementation

uses uChat;

procedure debug(output: string);
begin
  Log_Add(output);
end;

procedure loadMap(fname: string);
var
  mapfile: TextFile;
  s, s2, beginning: string;
  llen, i, j: integer;
  csv: TStringList;
begin
  // чистим карту
  for i := 0 to high(layer) do
    for j := 0 to high(layer[i].tile) do
      layer[i].tile[j].index := 0;

  AssignFile(mapfile, fname);
  Reset(mapfile);
  while (not (EOF(mapfile))) do
  begin
    ReadLn(mapfile, s);
    s := LowerCase(Trim(s));
    beginning := Copy(s, 1, 5);

    if (beginning = '<map ') then
    begin
      // Do some basic XML parsing / hacking to get dimensions of map

      // Sets s2 = the string starting from the width
      s2 := Copy(s, Pos('width', s) + 7, 10000);
      // Final parsing, copying to the double quote, we now have a number
      mapW := StrToInt(Copy(s2, 1, Pos('"', s2) - 1));

      // Sets s2 = the string starting from the width
      s2 := Copy(s, Pos('height', s) + 8, 10000);
      // Final parsing, copying to the double quote, we now have a number
      mapH := StrToInt(Copy(s2, 1, Pos('"', s2) - 1));

      debug('Map dimensions: ' + IntToStr(mapW) + 'x' + IntToStr(mapH));
      llen := -1;
    end
    else
    if (beginning = '<laye') then
    begin
      // Wee, we have a new tile layer full of delicious CSV tile data

      // Initialize objects and arrays to the map dimensions
      Inc(llen); // Going to be using this a lot, so make a var
      //SetLength(layer, llen+1);
      //layer[llen] := TTileMap.Create;
      //SetLength(layer[llen].tile, mapW * mapH);
      for i := 0 to mapW * mapH do
      begin
        //layer[llen].tile[i] := TTile.Create;
      end;
      debug('layer ' + IntToStr(llen) + ' objects initialized');

      // Read until we hit the CSV data
      while (not (s = '<data encoding="csv">')) do // This is the last line before
      begin
        ReadLn(mapfile, s);
        s := LowerCase(Trim(s));
      end;

      csv := TStringList.Create;
      s2 := '';
      // Read CSV data until no more
      while (not (s = '</data>')) do
      begin
        ReadLn(mapfile, s);
        s := LowerCase(Trim(s));
        s2 := Concat(s2, s);
      end;
      s2 := Copy(s2, 1, Length(s2) - 7); // </data> would otherwise be appended
      debug(s2);

      // CSV split into a TStringList
      csv.StrictDelimiter := True;
      csv.Delimiter := ',';
      csv.DelimitedText := s2;
      debug('-----');

      // Tile data populated
      for i := 0 to csv.Count - 1 do
      begin
        layer[llen].tile[i].index := StrToInt(csv[i]);
      end;

      debug('');
    end;
  end;

  Csv.Free;

  Chat_AddMessage(3, high(word), 'Map loading...');
  CloseFile(mapfile);
  l_ms := False;
  if not l_ms then
    Chat_AddMessage(3, high(word), 'Done.');
  // safe_map := false;
end;

procedure DrawTiles;
var
  i, i2, i3, c, c2: integer;
  x, y: single;
  flag: boolean;
begin
  {if key_down(k_left) then dec(dm_x);
  if key_down(k_right) then inc(dm_x);
  if key_down(k_up) then dec(dm_y);
  if key_down(k_down) then inc(dm_y);   }
  //if not l_ms then
  begin
    flag := False;
    if l_ms then
      Exit;
    if length(layer) < 1 then
      exit;
    c := 0;
    c2 := 0;
    batch2d_Begin;
    //  if flag then Exit;
    for i3 := 0 to Length(layer) - 1 do
    begin
      //  if flag then Exit;
      if length(layer[i3].tile) < 1 then
        exit;
      c := 0;
      for i := 0 to mapH - 1 do
      begin
        //   if flag then Exit;
        for i2 := 0 to mapW - 1 do
        begin
          //if flag then Exit;
          if (not (layer[i3].tile[c].index = 0)) {and (not flag)} then
          begin
            //if flag then Exit;
            // tex, x, y, w, h, angle, index
            x := i2 * 64 + (MapH - 1 - i) * 64;
            y := i2 * 32 - (MapH - 1 - i) * 32;
            //    scaleXY := 0.25;
            x := x - 2000 - 630;
            y := y + 150 + 110;

            if layer[i3].tile[c].index <= 672 then
              asprite2d_Draw(texTiles2, x, y, 128 + 1, 64 + 1,
                0, layer[i3].tile[c].index);
            if (layer[i3].tile[c].index > 672) and
              (layer[i3].tile[c].index <= 1184) then
              asprite2d_Draw(texTiles, x, y, 128 + 1, 64 + 1,
                0, layer[i3].tile[c].index - 672);
            if (layer[i3].tile[c].index > 1376) and
              (layer[i3].tile[c].index <= 2000) then
              asprite2d_Draw(texTiles3, x, y, 128 + 1, 64 + 1,
                0, layer[i3].tile[c].index - 1376);
            if (layer[i3].tile[c].index > 1184) and
              (layer[i3].tile[c].index <= 1376) then
              asprite2d_Draw(texTiles4, x, y, 128 + 1, 64 + 1,
                0, layer[i3].tile[c].index - 1184);

            Inc(c2);
          end;
          Inc(c);
        end;
      end;
    end;
  end;
  batch2d_end();
  //text_draw( fntCombat, 1000, 1000, u_IntToStr(dm_x) + ' ' + u_IntToStr(dm_y));

end;


end.

unit uSkillFl;

{$mode delphi}

interface

uses
  uAdd,
  uVar,
  zglHeader,
  uMyGui;

procedure SF_Init();
procedure SF_Update();

implementation

uses uNetCore, uParser;

procedure FillWithNumbers(id, n1, n2, n3, n4, n5: integer);
begin
  skills[id].costs[1] := n1;
  skills[id].costs[2] := n2;
  skills[id].costs[3] := n3;
  skills[id].costs[4] := n4;
  skills[id].costs[5] := n5;
end;

function xyz(x, y, z: integer) : TXYZ; inline;
begin
  result.X:= x;
  result.Y:= y;
  result.Z:= z;
end;

procedure SF_Init();
var i, j : integer;
begin
  sk_tx := 195;
  sk_ty := 45;
  sk_tw := 355;
  sk_th := 355;
  sk_ta := -45;
  sk_a := random(1000);

  for i := 1 to high(skills) do
    for j := 1 to 5 do
    skills[i].xyz[j] := xyz(0, 0, 0);

  Skills[10].exist := true;
  skills[10].school := 0;
  skills[10].dist := 25;
  skills[10].ang := 0;
  skills[10].iList := 2;
  skills[10].iID := 1;
  skills[10].maxrank:=5;
  skills[10].enabled:=true;
  skills[10].xyz[1] := xyz(2, 0, 0);
  skills[10].xyz[2] := xyz(5, 0, 0);
  skills[10].xyz[3] := xyz(9, 0, 0);
  skills[10].xyz[4] := xyz(14, 0, 0);
  skills[10].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(10, 2, 3, 4, 5, 6);

  Skills[11].exist := true;
  skills[11].school := 0;
  skills[11].dist := 45;
  skills[11].ang := -15;
  skills[11].iList := 1;
  skills[11].iID := 2;
  skills[11].maxrank:=3;
  skills[11].enabled:=false;
  skills[11].xyz[1] := xyz(20, 0, 0);
  skills[11].xyz[2] := xyz(45, 0, 0);
  skills[11].xyz[3] := xyz(80, 0, 0);
  FillWithNumbers(11, 2, 4, 6, 0, 0);


  Skills[12].exist := true;
  skills[12].school := 0;
  skills[12].dist := 45;
  skills[12].ang := 15;
  skills[12].iList := 2;
  skills[12].iID := 3;
  skills[12].maxrank:=3;
  skills[12].enabled:=false;
  skills[12].xyz[1] := xyz(2, 0, 0);
  skills[12].xyz[2] := xyz(4, 0, 0);
  skills[12].xyz[3] := xyz(6, 0, 0);
  FillWithNumbers(12, 2, 4, 6, 0, 0);

  Skills[13].exist := true;
  skills[13].school := 0;
  skills[13].dist := 67;
  skills[13].ang := 0;
  skills[13].iList := 2;
  skills[13].iID := 4;

  Skills[20].exist := true;
  skills[20].school := 1;
  skills[20].dist := 25;
  skills[20].ang := 0;
  skills[20].iList := 2;
  skills[20].iID := 1;
  skills[20].maxrank:=5;
  skills[20].enabled:=true;
  skills[20].xyz[1] := xyz(2, 0, 0);
  skills[20].xyz[2] := xyz(5, 0, 0);
  skills[20].xyz[3] := xyz(9, 0, 0);
  skills[20].xyz[4] := xyz(14, 0, 0);
  skills[20].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(20, 2, 3, 4, 5, 6);

  Skills[21].exist := true;
  skills[21].school := 1;
  skills[21].dist := 45;
  skills[21].ang := -15;
  skills[21].iList := 2;
  skills[21].iID := 2;
  skills[21].maxrank := 3;
  skills[21].xyz[1] := xyz(5, 0, 0);
  skills[21].xyz[2] := xyz(10, 0, 0);
  skills[21].xyz[3] := xyz(15, 0, 0);
  FillWithNumbers(21, 2, 4, 6, 0, 0);

  Skills[22].exist := true;
  skills[22].school := 1;
  skills[22].dist := 45;
  skills[22].ang := 15;
  skills[22].iList := 2;
  skills[22].iID := 3;
  skills[22].maxrank := 3;
  //skills[22].enabled:=true;
  skills[22].xyz[1] := xyz(2, 0, 0);
  skills[22].xyz[2] := xyz(5, 0, 0);
  skills[22].xyz[3] := xyz(9, 0, 0);
  FillWithNumbers(22, 2, 4, 6, 0, 0);

  Skills[23].exist := true;
  skills[23].school := 1;
  skills[23].dist := 67;
  skills[23].ang := 0;
  skills[23].iList := 2;
  skills[23].iID := 4;

  Skills[30].exist := true;
  skills[30].school := 2;
  skills[30].dist := 25;
  skills[30].ang := 0;
  skills[30].iList := 2;
  skills[30].iID := 1;
  skills[30].maxrank:=5;
  skills[30].enabled:=true;
  skills[30].xyz[1] := xyz(2, 0, 0);
  skills[30].xyz[2] := xyz(5, 0, 0);
  skills[30].xyz[3] := xyz(9, 0, 0);
  skills[30].xyz[4] := xyz(14, 0, 0);
  skills[30].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(30, 2, 3, 4, 5, 6);

  Skills[31].exist := true;
  skills[31].school := 2;
  skills[31].dist := 45;
  skills[31].ang := -15;
  skills[31].iList := 2;
  skills[31].iID := 2;
  skills[31].maxrank:=3;
  skills[31].enabled:=false;
  skills[31].xyz[1] := xyz(15, 0, 0);
  skills[31].xyz[2] := xyz(30, 0, 0);
  skills[31].xyz[3] := xyz(45, 0, 0);
  FillWithNumbers(31, 2, 4, 6, 0, 0);

  Skills[32].exist := true;
  skills[32].school := 2;
  skills[32].dist := 45;
  skills[32].ang := 15;
  skills[32].iList := 2;
  skills[32].iID := 3;
  skills[32].maxrank:=3;
  skills[32].enabled:=false;
  skills[32].xyz[1] := xyz(33, 0, 0);
  skills[32].xyz[2] := xyz(66, 0, 0);
  skills[32].xyz[3] := xyz(100, 0, 0);
  FillWithNumbers(32, 2, 4, 6, 0, 0);

  Skills[33].exist := true;
  skills[33].school := 2;
  skills[33].dist := 67;
  skills[33].ang := 0;
  skills[33].iList := 2;
  skills[33].iID := 4;

  Skills[40].exist := true;
  skills[40].school := 3;
  skills[40].dist := 25;
  skills[40].ang := 0;
  skills[40].iList := 2;
  skills[40].iID := 1;
  skills[40].maxrank:= 5;
  skills[40].enabled:=true;
  skills[40].xyz[1] := xyz(2, 0, 0);
  skills[40].xyz[2] := xyz(5, 0, 0);
  skills[40].xyz[3] := xyz(9, 0, 0);
  skills[40].xyz[4] := xyz(14, 0, 0);
  skills[40].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(40, 2, 3, 4, 5, 6);

  Skills[41].exist := true;
  skills[41].school := 3;
  skills[41].dist := 45;
  skills[41].ang := -15;
  skills[41].iList := 2;
  skills[41].iID := 2;
  skills[41].maxrank:= 3;
  skills[41].enabled:=false;
  skills[41].xyz[1] := xyz(10, 0, 0);
  skills[41].xyz[2] := xyz(20, 0, 0);
  skills[41].xyz[3] := xyz(30, 0, 0);
  FillWithNumbers(41, 2, 4, 6, 0, 0);

  Skills[42].exist := true;
  skills[42].school := 3;
  skills[42].dist := 45;
  skills[42].ang := 15;
  skills[42].iList := 2;
  skills[42].iID := 3;
  skills[42].maxrank:= 3;
  skills[42].enabled:=false;
  skills[42].xyz[1] := xyz(1, 0, 0);
  skills[42].xyz[2] := xyz(2, 0, 0);
  skills[42].xyz[3] := xyz(3, 0, 0);
  FillWithNumbers(42, 2, 4, 6, 0, 0);

  Skills[43].exist := true;
  skills[43].school := 3;
  skills[43].dist := 67;
  skills[43].ang := 0;
  skills[43].iList := 2;
  skills[43].iID := 4;

  Skills[50].exist := true;
  skills[50].school := 4;
  skills[50].dist := 25;
  skills[50].ang := 0;
  skills[50].iList := 2;
  skills[50].iID := 1;
  skills[50].maxrank:=5;
  skills[50].enabled:=true;
  skills[50].xyz[1] := xyz(2, 0, 0);
  skills[50].xyz[2] := xyz(5, 0, 0);
  skills[50].xyz[3] := xyz(9, 0, 0);
  skills[50].xyz[4] := xyz(14, 0, 0);
  skills[50].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(50, 2, 3, 4, 5, 6);

  Skills[51].exist := true;
  skills[51].school := 4;
  skills[51].dist := 45;
  skills[51].ang := -15;
  skills[51].iList := 2;
  skills[51].iID := 5;
  skills[51].maxrank:=3;
  skills[51].enabled:=true;
  skills[51].xyz[1] := xyz(10, 0, 0);
  skills[51].xyz[2] := xyz(20, 0, 0);
  skills[51].xyz[3] := xyz(30, 0, 0);
  FillWithNumbers(51, 2, 4, 6, 0, 0);

  Skills[52].exist := true;
  skills[52].school := 4;
  skills[52].dist := 45;
  skills[52].ang := 15;
  skills[52].iList := 2;
  skills[52].iID := 3;
  skills[52].maxrank:=3;
  skills[52].enabled:=true;
  skills[52].xyz[1] := xyz(2, 0, 0);
  skills[52].xyz[2] := xyz(3, 0, 0);
  skills[52].xyz[3] := xyz(4, 0, 0);
  FillWithNumbers(52, 2, 4, 6, 0, 0);

  Skills[53].exist := true;
  skills[53].school := 4;
  skills[53].dist := 67;
  skills[53].ang := 0;
  skills[53].iList := 2;
  skills[53].iID := 4;

  Skills[60].exist := true;
  skills[60].school := 5;
  skills[60].dist := 25;
  skills[60].ang := 0;
  skills[60].iList := 2;
  skills[60].iID := 1;
  skills[60].maxrank:=5;
  skills[60].enabled:=true;
  skills[60].xyz[1] := xyz(2, 0, 0);
  skills[60].xyz[2] := xyz(5, 0, 0);
  skills[60].xyz[3] := xyz(9, 0, 0);
  skills[60].xyz[4] := xyz(14, 0, 0);
  skills[60].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(60, 2, 3, 4, 5, 6);

  Skills[61].exist := true;
  skills[61].school := 5;
  skills[61].dist := 45;
  skills[61].ang := -15;
  skills[61].iList := 2;
  skills[61].iID := 2;
  skills[61].maxrank:=3;
  skills[61].enabled:=false;
  skills[61].xyz[1] := xyz(2, 0, 0);
  skills[61].xyz[2] := xyz(4, 0, 0);
  skills[61].xyz[3] := xyz(7, 0, 0);
  FillWithNumbers(61, 2, 4, 6, 0, 0);

  Skills[62].exist := true;
  skills[62].school := 5;
  skills[62].dist := 45;
  skills[62].ang := 15;
  skills[62].iList := 2;
  skills[62].iID := 3;
  skills[62].maxrank:= 3;
  skills[62].enabled:=false;
  skills[62].xyz[1] := xyz(1, 0, 0);
  skills[62].xyz[2] := xyz(2, 0, 0);
  skills[62].xyz[3] := xyz(3, 0, 0);
  FillWithNumbers(62, 2, 4, 6, 0, 0);

  Skills[63].exist := true;
  skills[63].school := 5;
  skills[63].dist := 67;
  skills[63].ang := 0;
  skills[63].iList := 2;
  skills[63].iID := 4;

  Skills[70].exist := true;
  Skills[70].enabled:= true;
  skills[70].school := 6;
  skills[70].dist := 25;
  skills[70].ang := 0;
  skills[70].iList := 2;
  skills[70].iID := 1;
  skills[70].maxrank:=5;
  skills[70].xyz[1] := xyz(1, 0, 0);
  skills[70].xyz[2] := xyz(2, 0, 0);
  skills[70].xyz[3] := xyz(3, 0, 0);
  skills[70].xyz[4] := xyz(5, 0, 0);
  skills[70].xyz[5] := xyz(7, 0, 0);
  FillWithNumbers(70, 2, 3, 4, 5, 6);

  Skills[71].exist := true;
  skills[71].school := 6;
  skills[71].dist := 45;
  skills[71].ang := -15;
  skills[71].iList := 2;
  skills[71].iID := 2;
  skills[71].maxrank:=3;
  skills[71].xyz[1] := xyz(1, 0, 0);
  skills[71].xyz[2] := xyz(2, 0, 0);
  skills[71].xyz[3] := xyz(3, 0, 0);
  FillWithNumbers(71, 2, 4, 6, 0, 0);

  Skills[72].exist := true;
  skills[72].school := 6;
  skills[72].dist := 45;
  skills[72].ang := 15;
  skills[72].iList := 2;
  skills[72].iID := 3;
  skills[72].maxrank:=3;
  skills[72].xyz[1] := xyz(2, 0, 0);
  skills[72].xyz[2] := xyz(5, 0, 0);
  skills[72].xyz[3] := xyz(9, 0, 0);
  FillWithNumbers(72, 2, 4, 6, 0, 0);

  Skills[73].exist := true;
  skills[73].school := 6;
  skills[73].dist := 67;
  skills[73].ang := 0;
  skills[73].iList := 2;
  skills[73].iID := 4;
end;

procedure SF_Update();
var i: integer;
begin
  if not mWins[6].visible then exit;

  if not sk_zoom then
  begin
    sk_tx := 195;
    sk_ty := 45;
    sk_tw := 355;
    sk_th := 355;
  end else
  begin
    sk_tx := 195 - 355 * 1.25;
    sk_ty := 45 - 355 * 0.25;
    sk_tw := 355 * 2.5;
    sk_th := 355 * 2.5;
  end;


  if abs(sk_x - sk_tx) > 0 then sk_x := sk_x + (sk_tx - sk_x) / 7;
  if abs(sk_y - sk_ty) > 0 then sk_y := sk_y + (sk_ty - sk_y) / 7;
  if abs(sk_x - sk_tw) > 0 then sk_w := sk_w + (sk_tw - sk_w) / 7;
  if abs(sk_h - sk_th) > 0 then sk_h := sk_h + (sk_th - sk_h) / 7;
  if abs(sk_a - sk_ta) > 0 then sk_a := sk_a + (sk_ta - sk_a) / 7;

  sk_z := sk_w / 355;


  if mouse_X > mWins[6].rect.X + 195 then
  if mouse_X < mWins[6].rect.X + 195 + 355 then
  if mouse_Y > mWins[6].rect.y + 45 then
  if mouse_Y < mWins[6].rect.y + 45 + 355 then
  for i := 1 to high(skills) do
    if skills[i].exist then
       begin
         skills[i].omo:=col2d_PointInRect(Mouse_X, Mouse_Y, rect(mWins[6].rect.X + sk_x + sk_w / 2 - 7 * sk_z + sk_z * skills[i].dist * m_cos(round(skills[i].school * 360 / 7 + skills[i].ang + sk_a)),
                               mWins[6].rect.Y + sk_y + sk_h / 2 - 7 * sk_z + sk_z * skills[i].dist * m_sin(round(skills[i].school * 360 / 7 + skills[i].ang + sk_a)),
                               14 * sk_z, 14 * sk_z ));
         if skills[i].omo then mgui_TTOpen(100 + i);
         if skills[i].omo then
            if mouse_Click(M_BLEFT) then
            if skills[i].enabled then
            if skills[i].rank <> skills[i].maxrank then
           { if activechar.TP >= skills[i].costs[skills[i].rank + 1] then
               SendData(inline_PkgCompile(56, activechar.Name + '`' + u_IntToStr(skills[i].school) + '`' + u_IntToStr(i - (skills[i].school + 1) * 10) + '`'));
       }end;

  if skills[10].rank > 1 then skills[11].enabled:=true;
  if skills[10].rank > 1 then skills[12].enabled:=true;

  if skills[20].rank > 1 then skills[21].enabled:=true;
  if skills[20].rank > 1 then skills[22].enabled:=true;

  if skills[30].rank > 1 then skills[32].enabled:=true;
  if skills[30].rank > 1 then skills[31].enabled:=true;

  if skills[40].rank > 1 then skills[41].enabled:=true;
  if skills[40].rank > 1 then skills[42].enabled:=true;

  if skills[50].rank > 1 then skills[51].enabled:=true;
  if skills[50].rank > 1 then skills[52].enabled:=true;

  if skills[60].rank > 1 then skills[61].enabled:=true;
  if skills[60].rank > 1 then skills[62].enabled:=true;

  if skills[70].rank > 1 then skills[71].enabled:=true;
  if skills[70].rank > 1 then skills[72].enabled:=true;
end;

end.


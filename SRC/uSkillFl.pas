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

  Skills[1].exist := true;
  skills[1].school := 0;
  skills[1].dist := 25;
  skills[1].ang := 0;
  skills[1].iList := 2;
  skills[1].iID := 1;
  skills[1].maxrank:=5;
  skills[1].enabled:=true;
  skills[1].xyz[1] := xyz(2, 0, 0);
  skills[1].xyz[2] := xyz(5, 0, 0);
  skills[1].xyz[3] := xyz(9, 0, 0);
  skills[1].xyz[4] := xyz(14, 0, 0);
  skills[1].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(1, 2, 3, 4, 5, 6);

  Skills[2].exist := true;
  skills[2].school := 0;
  skills[2].dist := 45;
  skills[2].ang := -15;
  skills[2].iList := 1;
  skills[2].iID := 2;
  skills[2].maxrank:=3;
  skills[2].enabled:=false;
  skills[2].xyz[1] := xyz(20, 0, 0);
  skills[2].xyz[2] := xyz(45, 0, 0);
  skills[2].xyz[3] := xyz(80, 0, 0);
  FillWithNumbers(2, 2, 4, 6, 0, 0);


  Skills[3].exist := true;
  skills[3].school := 0;
  skills[3].dist := 45;
  skills[3].ang := 15;
  skills[3].iList := 2;
  skills[3].iID := 3;
  skills[3].maxrank:=3;
  skills[3].enabled:=false;
  skills[3].xyz[1] := xyz(2, 0, 0);
  skills[3].xyz[2] := xyz(4, 0, 0);
  skills[3].xyz[3] := xyz(6, 0, 0);
  FillWithNumbers(3, 2, 4, 6, 0, 0);

  Skills[4].exist := true;
  skills[4].school := 0;
  skills[4].dist := 67;
  skills[4].ang := 0;
  skills[4].iList := 2;
  skills[4].iID := 4;

  Skills[26].exist := true;
  skills[26].school := 1;
  skills[26].dist := 25;
  skills[26].ang := 0;
  skills[26].iList := 2;
  skills[26].iID := 1;
  skills[26].maxrank:=5;
  skills[26].enabled:=true;
  skills[26].xyz[1] := xyz(2, 0, 0);
  skills[26].xyz[2] := xyz(5, 0, 0);
  skills[26].xyz[3] := xyz(9, 0, 0);
  skills[26].xyz[4] := xyz(14, 0, 0);
  skills[26].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(26, 2, 3, 4, 5, 6);

  Skills[27].exist := true;
  skills[27].school := 1;
  skills[27].dist := 45;
  skills[27].ang := -15;
  skills[27].iList := 2;
  skills[27].iID := 2;
  skills[27].maxrank := 3;
  skills[27].xyz[1] := xyz(5, 0, 0);
  skills[27].xyz[2] := xyz(10, 0, 0);
  skills[27].xyz[3] := xyz(15, 0, 0);
  FillWithNumbers(27, 2, 4, 6, 0, 0);

  Skills[28].exist := true;
  skills[28].school := 1;
  skills[28].dist := 45;
  skills[28].ang := 15;
  skills[28].iList := 2;
  skills[28].iID := 3;
  skills[28].maxrank := 3;
  //skills[22].enabled:=true;
  skills[28].xyz[1] := xyz(2, 0, 0);
  skills[28].xyz[2] := xyz(5, 0, 0);
  skills[28].xyz[3] := xyz(9, 0, 0);
  FillWithNumbers(28, 2, 4, 6, 0, 0);

  Skills[29].exist := true;
  skills[29].school := 1;
  skills[29].dist := 67;
  skills[29].ang := 0;
  skills[29].iList := 2;
  skills[29].iID := 4;

  Skills[51].exist := true;
  skills[51].school := 2;
  skills[51].dist := 25;
  skills[51].ang := 0;
  skills[51].iList := 2;
  skills[51].iID := 1;
  skills[51].maxrank:=5;
  skills[51].enabled:=true;
  skills[51].xyz[1] := xyz(2, 0, 0);
  skills[51].xyz[2] := xyz(5, 0, 0);
  skills[51].xyz[3] := xyz(9, 0, 0);
  skills[51].xyz[4] := xyz(14, 0, 0);
  skills[51].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(51, 2, 3, 4, 5, 6);

  Skills[52].exist := true;
  skills[52].school := 2;
  skills[52].dist := 45;
  skills[52].ang := -15;
  skills[52].iList := 2;
  skills[52].iID := 2;
  skills[52].maxrank:=3;
  skills[52].enabled:=false;
  skills[52].xyz[1] := xyz(15, 0, 0);
  skills[52].xyz[2] := xyz(30, 0, 0);
  skills[52].xyz[3] := xyz(45, 0, 0);
  FillWithNumbers(52, 2, 4, 6, 0, 0);

  Skills[53].exist := true;
  skills[53].school := 2;
  skills[53].dist := 45;
  skills[53].ang := 15;
  skills[53].iList := 2;
  skills[53].iID := 3;
  skills[53].maxrank:=3;
  skills[53].enabled:=false;
  skills[53].xyz[1] := xyz(33, 0, 0);
  skills[53].xyz[2] := xyz(66, 0, 0);
  skills[53].xyz[3] := xyz(100, 0, 0);
  FillWithNumbers(53, 2, 4, 6, 0, 0);

  Skills[54].exist := true;
  skills[54].school := 2;
  skills[54].dist := 67;
  skills[54].ang := 0;
  skills[54].iList := 2;
  skills[54].iID := 4;

  Skills[76].exist := true;
  skills[76].school := 3;
  skills[76].dist := 25;
  skills[76].ang := 0;
  skills[76].iList := 2;
  skills[76].iID := 1;
  skills[76].maxrank:= 5;
  skills[76].enabled:=true;
  skills[76].xyz[1] := xyz(2, 0, 0);
  skills[76].xyz[2] := xyz(5, 0, 0);
  skills[76].xyz[3] := xyz(9, 0, 0);
  skills[76].xyz[4] := xyz(14, 0, 0);
  skills[76].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(76, 2, 3, 4, 5, 6);

  Skills[77].exist := true;
  skills[77].school := 3;
  skills[77].dist := 45;
  skills[77].ang := -15;
  skills[77].iList := 2;
  skills[77].iID := 2;
  skills[77].maxrank:= 3;
  skills[77].enabled:=false;
  skills[77].xyz[1] := xyz(10, 0, 0);
  skills[77].xyz[2] := xyz(20, 0, 0);
  skills[77].xyz[3] := xyz(30, 0, 0);
  FillWithNumbers(77, 2, 4, 6, 0, 0);

  Skills[78].exist := true;
  skills[78].school := 3;
  skills[78].dist := 45;
  skills[78].ang := 15;
  skills[78].iList := 2;
  skills[78].iID := 3;
  skills[78].maxrank:= 3;
  skills[78].enabled:=false;
  skills[78].xyz[1] := xyz(1, 0, 0);
  skills[78].xyz[2] := xyz(2, 0, 0);
  skills[78].xyz[3] := xyz(3, 0, 0);
  FillWithNumbers(78, 2, 4, 6, 0, 0);

  Skills[79].exist := true;
  skills[79].school := 3;
  skills[79].dist := 67;
  skills[79].ang := 0;
  skills[79].iList := 2;
  skills[79].iID := 4;

  Skills[101].exist := true;
  skills[101].school := 4;
  skills[101].dist := 25;
  skills[101].ang := 0;
  skills[101].iList := 2;
  skills[101].iID := 1;
  skills[101].maxrank:=5;
  skills[101].enabled:=true;
  skills[101].xyz[1] := xyz(2, 0, 0);
  skills[101].xyz[2] := xyz(5, 0, 0);
  skills[101].xyz[3] := xyz(9, 0, 0);
  skills[101].xyz[4] := xyz(14, 0, 0);
  skills[101].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(101, 2, 3, 4, 5, 6);

  Skills[102].exist := true;
  skills[102].school := 4;
  skills[102].dist := 45;
  skills[102].ang := -15;
  skills[102].iList := 2;
  skills[102].iID := 5;
  skills[102].maxrank:=3;
  skills[102].enabled:=true;
  skills[102].xyz[1] := xyz(10, 0, 0);
  skills[102].xyz[2] := xyz(20, 0, 0);
  skills[102].xyz[3] := xyz(30, 0, 0);
  FillWithNumbers(102, 2, 4, 6, 0, 0);

  Skills[103].exist := true;
  skills[103].school := 4;
  skills[103].dist := 45;
  skills[103].ang := 15;
  skills[103].iList := 2;
  skills[103].iID := 3;
  skills[103].maxrank:=3;
  skills[103].enabled:=true;
  skills[103].xyz[1] := xyz(2, 0, 0);
  skills[103].xyz[2] := xyz(3, 0, 0);
  skills[103].xyz[3] := xyz(4, 0, 0);
  FillWithNumbers(103, 2, 4, 6, 0, 0);

  Skills[104].exist := true;
  skills[104].school := 4;
  skills[104].dist := 67;
  skills[104].ang := 0;
  skills[104].iList := 2;
  skills[104].iID := 4;

  Skills[126].exist := true;
  skills[126].school := 5;
  skills[126].dist := 25;
  skills[126].ang := 0;
  skills[126].iList := 2;
  skills[126].iID := 1;
  skills[126].maxrank:=5;
  skills[126].enabled:=true;
  skills[126].xyz[1] := xyz(2, 0, 0);
  skills[126].xyz[2] := xyz(5, 0, 0);
  skills[126].xyz[3] := xyz(9, 0, 0);
  skills[126].xyz[4] := xyz(14, 0, 0);
  skills[126].xyz[5] := xyz(20, 0, 0);
  FillWithNumbers(126, 2, 3, 4, 5, 6);

  Skills[127].exist := true;
  skills[127].school := 5;
  skills[127].dist := 45;
  skills[127].ang := -15;
  skills[127].iList := 2;
  skills[127].iID := 2;
  skills[127].maxrank:=3;
  skills[127].enabled:=false;
  skills[127].xyz[1] := xyz(2, 0, 0);
  skills[127].xyz[2] := xyz(4, 0, 0);
  skills[127].xyz[3] := xyz(7, 0, 0);
  FillWithNumbers(127, 2, 4, 6, 0, 0);

  Skills[128].exist := true;
  skills[128].school := 5;
  skills[128].dist := 45;
  skills[128].ang := 15;
  skills[128].iList := 2;
  skills[128].iID := 3;
  skills[128].maxrank:= 3;
  skills[128].enabled:=false;
  skills[128].xyz[1] := xyz(1, 0, 0);
  skills[128].xyz[2] := xyz(2, 0, 0);
  skills[128].xyz[3] := xyz(3, 0, 0);
  FillWithNumbers(128, 2, 4, 6, 0, 0);

  Skills[129].exist := true;
  skills[129].school := 5;
  skills[129].dist := 67;
  skills[129].ang := 0;
  skills[129].iList := 2;
  skills[129].iID := 4;

  Skills[151].exist := true;
  Skills[151].enabled:= true;
  skills[151].school := 6;
  skills[151].dist := 25;
  skills[151].ang := 0;
  skills[151].iList := 2;
  skills[151].iID := 1;
  skills[151].maxrank:=5;
  skills[151].xyz[1] := xyz(1, 0, 0);
  skills[151].xyz[2] := xyz(2, 0, 0);
  skills[151].xyz[3] := xyz(3, 0, 0);
  skills[151].xyz[4] := xyz(5, 0, 0);
  skills[151].xyz[5] := xyz(7, 0, 0);
  FillWithNumbers(151, 2, 3, 4, 5, 6);

  Skills[152].exist := true;
  skills[152].school := 6;
  skills[152].dist := 45;
  skills[152].ang := -15;
  skills[152].iList := 2;
  skills[152].iID := 2;
  skills[152].maxrank:=3;
  skills[152].xyz[1] := xyz(1, 0, 0);
  skills[152].xyz[2] := xyz(2, 0, 0);
  skills[152].xyz[3] := xyz(3, 0, 0);
  FillWithNumbers(152, 2, 4, 6, 0, 0);

  Skills[153].exist := true;
  skills[153].school := 6;
  skills[153].dist := 45;
  skills[153].ang := 15;
  skills[153].iList := 2;
  skills[153].iID := 3;
  skills[153].maxrank:=3;
  skills[153].xyz[1] := xyz(2, 0, 0);
  skills[153].xyz[2] := xyz(5, 0, 0);
  skills[153].xyz[3] := xyz(9, 0, 0);
  FillWithNumbers(153, 2, 4, 6, 0, 0);

  Skills[154].exist := true;
  skills[154].school := 6;
  skills[154].dist := 67;
  skills[154].ang := 0;
  skills[154].iList := 2;
  skills[154].iID := 4;
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


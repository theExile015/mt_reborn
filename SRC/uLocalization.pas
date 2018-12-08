unit uLocalization;

//
//   ¬ыт€нул в отдельный модуль, чтобы не засор€ть код
//   всЄ, включа€ переменные.
//

{$codepage utf8}
{$mode delphi}
interface

uses
  zglHeader,
  uVar;

type
  TLocalization = (locEn, locRu);

procedure SetLocalization(const loc : TLocalization = locEn);

var
  // общий формат √ЋќЅјЋ№Ќџ… ЁЋ≈ћ≈Ќ“_Ћќ јЋ№Ќџ… ЁЋ≈ћ≈Ќ“
  // Login window
  LW_CAPTION : UTF8String;
  LW_L1      : UTF8String;
  LW_L2      : UTF8String;
  LW_B1      : UTF8String;
  LW_B2      : UTF8String;
  LW_B3      : UTF8String;
  // Character manager window
  CM_CAPTION : UTF8String;
  CM_L1      : UTF8String;
  CM_L2      : UTF8String;
  CM_L3      : UTF8String;
  CM_B1      : UTF8String;
  CM_B2      : UTF8String;
  CM_B3      : UTF8String;
  CM_B4      : UTF8String;
  // Character make window
  NC_CAPTION : UTF8String;
  NC_L1      : UTF8String;
  NC_L2      : UTF8String;
  NC_B1      : UTF8String;
  NC_B2      : UTF8String;
  // Race info window
  RI_CAPTION : UTF8String;
  // Rase names
  Race_Names : array [1..5] of UTF8String;
  Race_Discr : array [1..5] of UTF8String;
  Race_Spec  : array [1..10] of Utf8String;
  Race_SDisc : array [1..10] of utf8string;
  Class_Names : array [0..14] of utf8string;
  Class_Descr : array [0..14] of utf8string;

  // Errors
  ERC, ERB : array [1..64] of UTF8String;
  // Stat title and description
  STT, STD : array [1..30] of UTF8String;
  // Perk title and description
  PT, PD : array [1..200] of UTF8String;
  // Spell title and description
  ST, SD : array [1..99] of UTF8String;

  QI : array [1..1000] of utf8string;

implementation

uses   u_MM_gui;

procedure SetLocalization(const loc : TLocalization = locEn);
var s : string; i: integer;
begin
  case loc of
    locEn: s := 'en';
    locRu: s := 'ru';
  end;
  ini_LoadFromFile('locals\' + s + '.ini');

   // Login window
  LW_CAPTION := ini_ReadKeyStr('LOGIN', 'Caption');
  LW_L1      := ini_ReadKeyStr('LOGIN', 'L1');
  LW_L2      := ini_ReadKeyStr('LOGIN', 'L2');
  LW_B1      := ini_ReadKeyStr('LOGIN', 'B1');
  LW_B2      := ini_ReadKeyStr('LOGIN', 'B2');
  LW_B3      := ini_ReadKeyStr('LOGIN', 'B3');
  // Character manager window
  CM_CAPTION := ini_ReadKeyStr('CHARM', 'Caption');
  CM_L1      := ini_ReadKeyStr('CHARM', 'L1') + ' ';
  CM_L2      := ' ' + ini_ReadKeyStr('CHARM', 'L2');
  CM_L3      := ini_ReadKeyStr('CHARM', 'L3');
  CM_B1      := ini_ReadKeyStr('CHARM', 'B1');
  CM_B2      := ini_ReadKeyStr('CHARM', 'B2');
  CM_B3      := ini_ReadKeyStr('CHARM', 'B3');
  CM_B4      := ini_ReadKeyStr('CHARM', 'B4');
  // Character make window
  NC_CAPTION := ini_ReadKeyStr('NCHAR', 'Caption');
  NC_L1      := ini_ReadKeyStr('NCHAR', 'L1');;
  NC_L2      := ini_ReadKeyStr('NCHAR', 'L2');
  NC_B1      := ini_ReadKeyStr('NCHAR', 'B1');
  NC_B2      := ini_ReadKeyStr('NCHAR', 'B2');
  // Race info window
  RI_CAPTION := ini_ReadKeyStr('CINFO', 'Caption');
  // Race names
  for i := 1 to 5 do
      begin
        Race_Names[i] := ini_ReadKeyStr('RACE_NAMES', 'R' + u_IntToStr(i));
        Race_Discr[i] := ini_ReadKeyStr('RACE_NAMES', 'D' + u_IntToStr(i));
      end;

  for i := 1 to 10 do
      begin
        Race_Spec[i] := ini_ReadKeyStr('RACE_NAMES', 'T' + u_IntToStr(i - 1));
        Race_SDisc[i] := ini_ReadKeyStr('RACE_NAMES', 'S' + u_IntToStr(i - 1));
      end;
  // class info
  for i:= 1 to 14 do
      begin
        class_names[i] := ini_ReadKeyStr('CLASS_NAMES', 'C' + u_IntToStr(i));
        class_descr[i] := ini_ReadKeyStr('CLASS_NAMES', 'D' + u_IntToStr(i));
      end;
  // Error discr
  for i := 1 to 18 do
      begin
        ERC[i] := (ini_ReadKeyStr('ERRORS', 'EC' + u_IntToStr(i)));
        ERB[i] := (ini_ReadKeyStr('ERRORS', 'EB' + u_IntToStr(i)));
      end;

  for i := 1 to 26 do
    if ini_IsSection('STATS') then
      begin
        STT[i] := ini_ReadKeyStr('STATS', 'STT' + u_IntToStr(i));
        STD[i] := ini_ReadKeyStr('STATS', 'STD' + u_IntToStr(i));
      end else Log_Add('NO SECTION');

  for i := 1 to 200 do
    if ini_IsSection('PERKS') then
      begin
        PT[i] := ini_ReadKeyStr('PERKS', 'PT' + u_IntToStr(i));
        PD[i] := ini_ReadKeyStr('PERKS', 'PD' + u_IntToStr(i));
      end else Log_Add('NO SECTION');

  for i := 1 to 99 do
    if ini_IsSection('SPELLS') then
      begin
        ST[i] := ini_ReadKeyStr('SPELLS', 'SN' + u_IntToStr(i));
        SD[i] := ini_ReadKeyStr('SPELLS', 'SD' + u_IntToStr(i));
        Spells[i].name:=ST[i];
        Spells[i].bdiscr:=SD[i];
      end else Log_Add('NO SECTION');

  for i := 1 to 1000 do
    if ini_IsSection('ITEMS') then
      begin
        QI[i] := ini_ReadKeyStr('ITEMS', 'QI' + u_IntToStr(i));
        if qi[i] <> '' then log_add(qi[i]);
      end else Log_Add('NO SECTION');

  ini_free();


  Log_Add(LW_Caption);
  // Login window
  Nonameform1.Caption := (LW_CAPTION);
  NonameLabel4.Caption := LW_L1;
  NonameLabel5.Caption := (LW_L2);
  NonameButton6.Caption := (LW_B1);
  NonameButton7.Caption := (LW_B2);
  NonameButton8.Caption := (LW_B3);

  // Character manager window
  fCharMan.Caption := (CM_CAPTION);
  bEnterWorld.Caption := (CM_B4);
  bDelChar.Caption := (CM_B2);
  bNewChar.Caption := (CM_B1);
  bSExit.Caption := (CM_B3);


  // Character make window
  fCharMake.Caption :=(NC_CAPTION);
  bCreate.Caption := (NC_B1);
  bCancel.Caption := (NC_B2);
  lCharName.Caption :=(NC_L1);
  NonameLabel28.Caption := (NC_L2);
  cbRace.Items.Clear;
  for i := 1 to 5 do
      begin
        cbRace.Items.Add((Race_Names[i]));
       // Log_Add(cbRace.Items[i]);
      end;

end;

end.

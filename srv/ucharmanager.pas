unit uCharManager;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  vVar,
  uDB,
  DOS;

function hpmp_counter(base, par : dword) : dword;
function GetPerkXYZ(sc, lid, lvl : byte) : TXYZ;
function GetPerkID(sc, lid : byte) : word;

procedure Char_InitInventory();
procedure Char_RegEvent();
procedure Char_Update();
procedure Char_AddNumbers(charLID, Gold, Exp, lvl, SP, TP : DWORD);

function Char_EnterTheWorld(sID, charID: DWORD): word;
function Char_CalculateStats(charLID: dword): word;
procedure char_MoveToLoc(charLID, locID : DWORD) ;


implementation

uses uPkgProcessor, vNetCore, uChatManager;

procedure Char_InitInventory();
var i, j : integer;
begin
  for i := 0 to length(chars) - 1 do
  for j := 1 to 130 do
    begin
      if j in [13..20] then
         chars[i].Inventory[j].sub := 6;
      if j in [21..100] then
         chars[i].Inventory[j].sub := 6;

      if j = 1 then chars[i].Inventory[j].sub := 3;
      if j = 2 then chars[i].Inventory[j].sub := 10;
      if j = 3 then chars[i].Inventory[j].sub := 2;
      if j = 4 then chars[i].Inventory[j].sub := 11;
      if j = 5 then chars[i].Inventory[j].sub := 1;
      if j = 6 then chars[i].Inventory[j].sub := 9;
      if j = 7 then chars[i].Inventory[j].sub := 7;
      if j = 8 then chars[i].Inventory[j].sub := 12;
      if j = 9 then chars[i].Inventory[j].sub := 7;
      if j = 10 then chars[i].Inventory[j].sub := 5;
      if j = 11 then chars[i].Inventory[j].sub := 4;
      if j = 12 then chars[i].Inventory[j].sub := 8;
    end;
end;

function GetPerkID(sc, lid : byte) : word;
var I: integer;
begin
  result := 0;
  for i := 1 to high(PerksDB) do
    if PerksDB[i].exist then
    if (PerksDB[i].sc = sc) and (PerksDB[i].lid = lid) then
       begin
         result := i;
         break;
       end;
end;

function GetPerkXYZ(sc, lid, lvl : byte) : TXYZ;
var i: integer;
begin
  result.x:=0;
  result.y:=0;
  result.z:=0;
  if lvl > 5 then exit; if lvl < 1 then exit;
  for i := 1 to high(PerksDB) do
    if PerksDB[i].exist then
       if (PerksDB[i].sc = sc) and (PerksDB[i].lid = lid) then
          begin
            result := PerksDB[i].xyz[lvl];
            break;
          end;
end;

function hpmp_counter(base, par : dword) : dword;
var i, k: integer;
begin
  result := base;
  if par < 10 then k := par else k := 10;
  for i := 1 to k do
      result := result + i;
  if par > 10 then
     result := result + (par - 10) * 10;
end;

procedure Char_RegEvent();
var i: integer;  _pkg : TPkg010;
begin
  for i := 0 to length(chars) - 1 do
    if chars[i].exist then
      if not chars[i].in_combat then
        begin
          chars[i].hpmp.cHP := chars[i].hpmp.cHP + chars[i].Stats.HPReg;
          chars[i].hpmp.cMP := chars[i].hpmp.cMP + chars[i].Stats.MPReg;
          if chars[i].hpmp.cHP > chars[i].hpmp.mHP then chars[i].hpmp.cHP:=chars[i].hpmp.mHP;
          if chars[i].hpmp.cMP > chars[i].hpmp.mMP then chars[i].hpmp.cMP:=chars[i].hpmp.mMP;
          DB_SetHPMP( i );
          pkg010( _pkg, chars[i].sID );
        end;
end;

function Char_EnterTheWorld(sID, charID: DWORD): word;
var i: integer;
    _head  : TPackHeader;
    _pkg10 : TPkg010; _pkg11 : TPkg011; _pkg12 : TPkg012;
    _pkg26 : TPkg026;
    mStr   : TMemoryStream;
begin
  result:=high(word);
  for i:=0 to length(chars) - 1 do
    if not chars[i].exist then
      begin
        chars[i].exist          := true;
        result                  := i; // результатом служит номер записи в массиве
        chars[i].charLID        := i;
        chars[i].header.ID      := charID;
        chars[i].sID            := sID;
        chars[i].in_combat      := false;
        chars[i].in_global_chat := true;
        Sessions[sID].charLID   := i; // чтобы было проще искать
        DB_GetCharData( i );
        Char_CalculateStats( i );
        break;
      end;
  if not sessions[i].exist then Exit; // если сессии такой нет, то выходим
  // Персонаж подготовлен. Теперь нужно отправить базовые данные клиенту
  pkg010(_pkg10, sID); // отправляем-с
  pkg011(_pkg11, sID); // отправляем-с
  pkg012(_pkg12, sID); // отправляем-с

  for i := 0 to high(chars) do
      if chars[i].exist then
         begin
           _pkg26.channel := 0;
           pkg026(_pkg26, chars[i].sID);
           _pkg26.channel := 1;
           pkg026(_pkg26, chars[i].sID);
         end;
end;

procedure Char_AddNumbers(charLID, Gold, Exp, lvl, SP, TP : DWORD);
var pkg : TPkg011; pkg2 : TPkg015;
begin
      chars[charLID].Numbers.gold:= chars[charLID].Numbers.gold + gold;
      chars[charLID].Numbers.Exp:= chars[charLID].Numbers.Exp + exp;
      chars[charLID].Header.level:= chars[charLID].Header.level + lvl;
      chars[charLID].Numbers.SP:= chars[charLID].Numbers.SP + SP;
      chars[charLID].Numbers.TP:= chars[charLID].Numbers.TP + TP;

      DB_SetCharData( charLID, chars[charLID].header.name );
      DB_GetCharData( charLID );

      pkg011( pkg, chars[charLID].sID );
      pkg015( pkg2, chars[charLID].sID );
end;

procedure Char_Update();
var i: integer;
    hh, mm, ss, ms : word;
    s : string;
begin
  for i := 0 to high(chars) - 1 do
    if chars[i].exist then
      begin
        // повышение уровня
        if chars[i].Numbers.Exp >= exp_cap[chars[i].header.level + 1] then
           begin
             chars[i].Numbers.Exp := chars[i].Numbers.Exp - exp_cap[chars[i].header.level + 1];
             Char_AddNumbers( i, 0, 0, 1, 3, 2);
           end;
        // перемещение на локацию
        if chars[i].in_trvl then
           begin
             GetTime(hh, mm, ss, ms);
             if abs(mm * 60 + ss - chars[i].trvMin * 60 - chars[i].trvSec) >= chars[i].trvTime then
                begin
                //    Writeln(' Char ' + (chars[i].name) + ' to LOC > ' + locDB[chars[i].trvDest].name, 2);
                  Char_MoveToLoc(i, chars[i].trvDest);
                end;
           end;
      end;
end;

function Char_CalculateStats(charLID: dword): word;
var i, j    : integer;
begin
  result:=0;
  i := CharLID;
      begin
          DB_GetCharData( i );
          DB_GetCharInv( i );
          result := i;

          chars[i].iStr:= 0;
          chars[i].iAgi:= 0;
          chars[i].iCon:= 0;
          chars[i].iHst:= 0;
          chars[i].iInt:= 0;
          chars[i].iSpi:= 0;
          chars[i].Stats.DMG:= 0;
          chars[i].Stats.APH:= 0;
          chars[i].iIni:= 0;
          chars[i].Stats.Armor := 0;
          chars[i].iCrit:=0;
          chars[i].iHit:=0;
          chars[i].iSPD:=0;
          chars[i].iAP:=0;
          chars[i].iMP5:=0;
          chars[i].iHP5:=0;

          chars[i].bStr:= b_chars[chars[i].header.raceID].bStr;
          chars[i].bAgi:= b_chars[chars[i].header.raceID].bAgi;
          chars[i].bCon:= b_chars[chars[i].header.raceID].bCon;
          chars[i].bHst:= b_chars[chars[i].header.raceID].bHst;
          chars[i].bInt:= b_chars[chars[i].header.raceID].bInt;
          chars[i].bSpi:= b_chars[chars[i].header.raceID].bSpi;
          chars[i].bHP := b_chars[chars[i].header.raceID].bHP;
          chars[i].bMP := b_chars[chars[i].header.raceID].bMP;
          chars[i].bAP := b_chars[chars[i].header.raceID].bAP;

          {for j := 1 to 130 do
          if chars[i].Inventory[j].gID<>0 then
            WriteSafeText( '(' + intToStr(j) + ', ' + intToStr(chars[i].Inventory[j].gID) +
                           ', ' + intToStr(chars[i].Inventory[j].iID) + ')');   }

          if chars[i].header.loc = 1 then // ограничитель чтобы лишнего не крутить
          if chars[i].Inventory[4].gID <> 0 then
             if chars[i].Inventory[5].gID <> 0 then
                if chars[i].Inventory[10].gID <> 0 then
                   if chars[i].Inventory[11].gID <> 0 then
                      DB_SetCharVar(i, 1, 'v12');

          for j := 1 to 12 do
          if chars[i].Inventory[j].gID <> 0 then
            begin
              //WriteSafeText(inttostr(i) + ' Item stats recalculation froms slot ' + intToStr(j) );
              //  дамаг, армор, апх
              if ItemDB[chars[i].Inventory[j].iID].data.props[2] <> 0 then
                 chars[i].Stats.Dmg:=ItemDB[chars[i].Inventory[j].iID].data.props[2];
              if ItemDB[chars[i].Inventory[j].iID].data.props[4] <> 0 then
                 chars[i].Stats.APH:=ItemDB[chars[i].Inventory[j].iID].data.props[4];
              if ItemDB[chars[i].Inventory[j].iID].data.props[5] <> 0 then
                 chars[i].Stats.Armor:=chars[i].Stats.Armor + ItemDB[chars[i].Inventory[j].iID].data.props[5];
              // базовые статы
              if ItemDB[chars[i].Inventory[j].iID].data.props[6] <> 0 then
                 chars[i].iStr:=chars[i].iStr + ItemDB[chars[i].Inventory[j].iID].data.props[6];
              if ItemDB[chars[i].Inventory[j].iID].data.props[7] <> 0 then
                 chars[i].iAgi:=chars[i].iAgi + ItemDB[chars[i].Inventory[j].iID].data.props[7];
              if ItemDB[chars[i].Inventory[j].iID].data.props[8] <> 0 then
                 chars[i].iCon:=chars[i].iCon + ItemDB[chars[i].Inventory[j].iID].data.props[8];
              if ItemDB[chars[i].Inventory[j].iID].data.props[9] <> 0 then
                 chars[i].iHst:=chars[i].iHst + ItemDB[chars[i].Inventory[j].iID].data.props[9];
              if ItemDB[chars[i].Inventory[j].iID].data.props[10] <> 0 then
                 chars[i].iInt:=chars[i].iInt + ItemDB[chars[i].Inventory[j].iID].data.props[10];
              if ItemDB[chars[i].Inventory[j].iID].data.props[11] <> 0 then
                 chars[i].iSpi:=chars[i].iSpi + ItemDB[chars[i].Inventory[j].iID].data.props[11];
              // вторичные статы
              if ItemDB[chars[i].Inventory[j].iID].data.props[12] <> 0 then
                 chars[i].iHit:=chars[i].iHit + ItemDB[chars[i].Inventory[j].iID].data.props[12];
              if ItemDB[chars[i].Inventory[j].iID].data.props[13] <> 0 then
                 chars[i].iCrit:=chars[i].iCrit + ItemDB[chars[i].Inventory[j].iID].data.props[13];
              if ItemDB[chars[i].Inventory[j].iID].data.props[14] <> 0 then
                 chars[i].iSPD:=chars[i].iSPD + ItemDB[chars[i].Inventory[j].iID].data.props[14];
              if ItemDB[chars[i].Inventory[j].iID].data.props[15] <> 0 then
                 chars[i].iIni:=chars[i].iIni + ItemDB[chars[i].Inventory[j].iID].data.props[15];
              if ItemDB[chars[i].Inventory[j].iID].data.props[16] <> 0 then
                 chars[i].iAP:=chars[i].iAP + ItemDB[chars[i].Inventory[j].iID].data.props[16];

              if ItemDB[chars[i].Inventory[j].iID].data.props[21] <> 0 then
                 chars[i].iHP5:=chars[i].iHP5 + ItemDB[chars[i].Inventory[j].iID].data.props[21];
              if ItemDB[chars[i].Inventory[j].iID].data.props[22] <> 0 then
                 chars[i].iMP5:=chars[i].iMP5 + ItemDB[chars[i].Inventory[j].iID].data.props[22];
              if ItemDB[chars[i].Inventory[j].iID].data.props[6] <> 0 then
                 chars[i].iStr:=chars[i].iStr + ItemDB[chars[i].Inventory[j].iID].data.props[6];

            end;

          //writeln('DMG ##: ', chars[i].Stats.DMG);

          chars[i].iStr := chars[i].iStr + GetPerkXYZ(0, 1, chars[i].perks[0][1]).x;
          chars[i].iAgi := chars[i].iAgi + GetPerkXYZ(5, 1, chars[i].perks[5][1]).x;
          chars[i].iCon := chars[i].iCon + GetPerkXYZ(1, 1, chars[i].perks[1][1]).x;
          chars[i].iInt := chars[i].iInt + GetPerkXYZ(3, 1, chars[i].perks[3][1]).x;
          chars[i].iSpi := chars[i].iSpi + GetPerkXYZ(4, 1, chars[i].perks[4][1]).x;
          chars[i].iMP5 := chars[i].iMP5 + GetPerkXYZ(2, 1, chars[i].perks[2][1]).x;

          chars[i].Stats.Str:=chars[i].bStr + chars[i].Points.pStr + chars[i].iStr;
          chars[i].Stats.Agi:=chars[i].bAgi + chars[i].Points.pAgi + chars[i].iAgi;
          chars[i].Stats.Con:=chars[i].bCon + chars[i].Points.pCon + chars[i].iCon;
          chars[i].Stats.Int:=chars[i].bInt + chars[i].Points.pInt + chars[i].iInt;
          chars[i].Stats.Hst:=chars[i].bHst + chars[i].Points.pHst + chars[i].iHst;
          chars[i].Stats.Spi:=chars[i].bSpi + chars[i].Points.pSpi + chars[i].iSpi;

          // расовый бонус Сильванов
          if chars[i].header.raceID = 3 then
             chars[i].iIni:= chars[i].iIni + 3;

          // проверяем на рукопашку
          if chars[i].Stats.APH = 0 then chars[i].Stats.APH:= 10;

        //  WriteSafeText(' >> I TYPE >> ' + IntToStr(ItemDB[chars[i].Inventory[4].iID].iType) );

          if ItemDB[chars[i].Inventory[4].iID].data.iType <> 5 then
            if ItemDB[chars[i].Inventory[4].iID].data.iType <> 6 then
              if ItemDB[chars[i].Inventory[4].iID].data.iType <> 10 then
                 chars[i].Stats.Dmg:=round((chars[i].Stats.Dmg + 10 * chars[i].Stats.Str/(50)));

          if ItemDB[chars[i].Inventory[4].iID].data.iType = 5 then
             chars[i].Stats.Dmg:=round((chars[i].Stats.Dmg + 10 * chars[i].Stats.Agi/(50)));

          if ItemDB[chars[i].Inventory[4].iID].data.iType = 10 then
             chars[i].Stats.Dmg:=round((chars[i].Stats.Dmg + 10 * (chars[i].Stats.Agi + chars[i].Stats.Str)/(100)));
          //writeln('DMG ##: ', chars[i].Stats.DMG);
               // Перк 1р-мастери
          if (ItemDB[chars[i].Inventory[4].iID].data.iType = 10) or
             (ItemDB[chars[i].Inventory[4].iID].data.iType = 8) then
              if chars[i].perks[6][3] > 0 then
                 chars[i].Stats.DMG := 1 + trunc(chars[i].Stats.DMG * (1 + PerksDB[17].xyz[chars[i].perks[6][3]].x / 100));


          chars[i].hpmp.mHP:=hpmp_counter(chars[i].bHP, chars[i].Stats.Con) + base_hp[chars[i].header.level] - 40;
          chars[i].hpmp.mMP:=hpmp_counter(chars[i].bMP, chars[i].Stats.Int) + base_mp[chars[i].header.level] - 20;
          chars[i].hpmp.mAP:=chars[i].bAP + trunc(chars[i].Stats.Hst * 1.75/(chars[i].header.level + 10)) + chars[i].iAP;

          if chars[i].hpmp.cHP > chars[i].hpmp.mHP then chars[i].hpmp.cHP:=chars[i].hpmp.mHP;
          if chars[i].hpmp.cMP > chars[i].hpmp.mMP then chars[i].hpmp.cMP:=chars[i].hpmp.mMP;
          if chars[i].hpmp.cAP > chars[i].hpmp.mAP then chars[i].hpmp.cAP:=chars[i].hpmp.mAP;

          chars[i].Stats.Ini   :=80 + trunc(chars[i].Stats.Hst * 2.5/(chars[i].header.level/3 + 5)) + chars[i].iIni;
          chars[i].Stats.HPReg :=chars[i].header.level + chars[i].iHP5 + trunc(chars[i].Stats.Con/chars[i].header.level);
          chars[i].Stats.MPReg :=chars[i].header.level + chars[i].iMP5 + trunc(chars[i].Stats.Spi/chars[i].header.level);
          chars[i].Stats.SPD   :=chars[i].iSPD;
      end;
end;

procedure char_MoveToLoc(charLID, locID : DWORD) ;
var i, rs : integer;
    s : string;
    _head : TPackHeader;
    _pkg  : TPkg028;
    mStr  : TMemoryStream;
begin
  chars[charLID].in_trvl:=false;
  chars[charLID].header.loc:= locID;
  DB_SetCharData(charLID, chars[charLID].header.name);

  try
         mStr := TMemoryStream.Create;
         _head._flag := $F;
         _head._id   := 28;

         //_pkg.name:='';
         _pkg._to := locID;
         _pkg._time := 0;
         _pkg.fail_code := high(byte);

         mStr.Write(_head, sizeof(_head));
         mStr.Write(_pkg, sizeof(_pkg));

         // Отправляем пакет
         TCP.FCon.IterReset;
         while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[charLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[charLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
       finally
         mStr.Free;
       end;
  // локацию сменена. нужно разослать новые списки
  for i := 0 to high(chars) do
    if chars[i].exist then
       Chat_GetMembersList(1, chars[i].header.loc, chars[i].sID);
end;

end.


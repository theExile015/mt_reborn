unit uCharManager;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  vVar,
  vNetCore,
  uDB;

function hpmp_counter(base, par : dword) : dword;
function GetPerkXYZ(sc, lid, lvl : byte) : TXYZ;
function GetPerkID(sc, lid : byte) : word;

function Char_EnterTheWorld(sID, charID: DWORD): word;
function Char_CalculateStats(charID: dword): word;

implementation

uses uPkgProcessor;

function GetPerkID(sc, lid : byte) : word;
var I: integer;
begin
  result := 0;
 { for i := 1 to high(PerksDB) do
    if PerksDB[i].exist then
    if (PerksDB[i].sc = sc) and (PerksDB[i].lid = lid) then
       begin
         result := i;
         break;
       end;    }
end;

function GetPerkXYZ(sc, lid, lvl : byte) : TXYZ;
var i: integer;
begin
  result.x:=0;
  result.y:=0;
  result.z:=0;
  if lvl > 5 then exit; if lvl < 1 then exit;
 { for i := 1 to high(PerksDB) do
    if PerksDB[i].exist then
       if (PerksDB[i].sc = sc) and (PerksDB[i].lid = lid) then
          begin
            result := PerksDB[i].xyz[lvl];
            break;
          end;  }
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

function Char_EnterTheWorld(sID, charID: DWORD): word;
var i: integer;
    _head  : TPackHeader;
    _pkg10 : TPkg010; _pkg11 : TPkg011; _pkg12 : TPkg012;
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
        Char_CalculateStats(charID);
        break;
      end;
  if not sessions[i].exist then Exit; // если сессии такой нет, то выходим
  // Персонаж подготовлен. Теперь нужно отправить базовые данные клиенту
  pkg010(_pkg10, sID); // отправляем-с
  pkg011(_pkg11, sID); // отправляем-с
  pkg012(_pkg12, sID); // отправляем-с
end;

function Char_CalculateStats(charID: dword): word;
var i, j    : integer;
    charLID : DWORD;
begin
  result:=0;
  for i:=0 to length(chars) - 1 do
    if chars[i].exist then
      if chars[i].header.ID = charID then
      begin
          CharLID := i;
          DB_GetCharData( i );
        //  DB_GetCharInv(i);
          result := i;

          chars[i].iStr:= 0;
          chars[i].iAgi:= 0;
          chars[i].iCon:= 0;
          chars[i].iHst:= 0;
          chars[i].iInt:= 0;
          chars[i].iSpi:= 0;
          chars[i].iDmg:= 0;
          chars[i].iAPH:= 0;
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
                 chars[i].iDmg:=chars[i].iDmg + ItemDB[chars[i].Inventory[j].iID].data.props[2];
              if ItemDB[chars[i].Inventory[j].iID].data.props[4] <> 0 then
                 chars[i].iAPH:=chars[i].iAPH + ItemDB[chars[i].Inventory[j].iID].data.props[4];
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

         { chars[i].iStr := chars[i].iStr + GetPerkXYZ(0, 1, chars[i].perks[0][1].pNum).x;
          chars[i].iAgi := chars[i].iAgi + GetPerkXYZ(5, 1, chars[i].perks[5][1].pNum).x;
          chars[i].iCon := chars[i].iCon + GetPerkXYZ(1, 1, chars[i].perks[1][1].pNum).x;
          chars[i].iInt := chars[i].iInt + GetPerkXYZ(3, 1, chars[i].perks[3][1].pNum).x;
          chars[i].iSpi := chars[i].iSpi + GetPerkXYZ(4, 1, chars[i].perks[4][1].pNum).x;
          chars[i].iMP5 := chars[i].iMP5 + GetPerkXYZ(2, 1, chars[i].perks[2][1].pNum).x;
          }
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
          if chars[i].iAPH = 0 then chars[i].iAPH:= 10;

        //  WriteSafeText(' >> I TYPE >> ' + IntToStr(ItemDB[chars[i].Inventory[4].iID].iType) );

          if ItemDB[chars[i].Inventory[4].iID].data.iType <> 5 then
            if ItemDB[chars[i].Inventory[4].iID].data.iType <> 6 then
              if ItemDB[chars[i].Inventory[4].iID].data.iType <> 10 then
                 chars[i].iDmg:=round((chars[i].iDmg + 10 * chars[i].Stats.Str/(50)));

          if ItemDB[chars[i].Inventory[4].iID].data.iType = 5 then
             chars[i].iDmg:=round((chars[i].iDmg + 10 * chars[i].Stats.Agi/(50)));

          if ItemDB[chars[i].Inventory[4].iID].data.iType = 10 then
             chars[i].iDmg:=round((chars[i].iDmg + 10 * (chars[i].Stats.Agi + chars[i].Stats.Str)/(100)));

          {     // Перк 1р-мастери
          if (ItemDB[chars[i].Inventory[4].iID].iType = 10) or
             (ItemDB[chars[i].Inventory[4].iID].iType = 8) then
              if chars[i].perks[6][3].pNum > 0 then
                 chars[i].iDmg := 1 + trunc(chars[i].iDmg * (1 + PerksDB[17].xyz[chars[i].perks[6][3].pNum].x / 100));
             }

          chars[i].hpmp.mHP:=hpmp_counter(chars[i].bHP, chars[i].Stats.Con) + base_hp[chars[i].header.level] - 40;
          chars[i].hpmp.mMP:=hpmp_counter(chars[i].bMP, chars[i].Stats.Int) + base_mp[chars[i].header.level] - 20;
          chars[i].hpmp.mAP:=chars[i].bAP + trunc(chars[i].Stats.Hst * 1.75/(chars[i].header.level + 10)) + chars[i].iAP;
          chars[i].Stats.Ini:=80 + trunc(chars[i].Stats.Hst * 2.5/(chars[i].header.level/3 + 5)) + chars[i].iIni;
          chars[i].Stats.HPReg:=chars[i].header.level + chars[i].iHP5 + trunc(chars[i].Stats.Con/chars[i].header.level);
          chars[i].Stats.MPReg:=chars[i].header.level + chars[i].iMP5 + trunc(chars[i].Stats.Spi/chars[i].header.level);
          chars[i].Stats.SPD:=chars[i].iSPD;
        break;
      end;
end;

end.


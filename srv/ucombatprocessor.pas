unit uCombatProcessor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  vVar,
  vNetCore,
  DOS,
  uAdd,
  uDB,
  uAI;


function CM_StartNew(initiator, ceType, ceUID : DWORD): word;
function CM_AddPUnit(comID, charLID: DWORD; uTeam : byte) : byte;
function CM_AddAIUnit(comID, uID : DWORD; uTeam : byte) : byte;

function CM_MeleeAttack( comLID, uLID, tLID, spID : dword) : byte;

function CM_CombatEnd( comLID, WinTeam : dword) : byte;
function CM_Loot(charLID, lootID: dword) : byte;

function CM_GetPUnitsNum( comLID : DWORD) : byte;
function CM_GetCombatLID( comID : DWORD) : DWORD;
function CM_DR( armor, level : dword) : single;
function CM_CombatFreeAndNil( comLID : dword) : byte;
function CM_CheckFreeNode( comLID: DWORD; mX, mY: word): boolean;
function CM_SetStartPos( comLID: DWORD; uTeam: byte) : TMPoint;
function CM_SetUnitDirection( sX, sY, fX, fY : DWORD) : DWORD;
function CM_CheckMelee(comLID, u1, u2: dword) : boolean;

function CM_CheckCol(x, y, x2, y2 : DWORD): boolean; inline;
function CM_AddAura(comLID, charLID, ID, stacks : DWord): byte;
function CM_DelAura(comLID, charLID, ID : DWord): byte;
function CM_FindAura(comLID, charLID, ID : DWord): byte;

procedure CM_Process();

procedure CM_SendUnits(comLID, charLID : word);
procedure CM_SendNewRound(comLID : word);
procedure CM_SendTurnStart(comLID, uLID : DWORD );
procedure CM_SendBaseInfo( comLID, uLID : DWORD );
procedure CM_SendEndBattle( comLID, uLID, WinTeam : DWORD );

var
  zero_combat : TCombatEvent;

implementation

uses
  uPkgProcessor, uCharManager, vServerLog;

procedure CM_Process();
var i, j, k, n  : integer;
    hh, mm, ss, ms : word;
begin
for i := 0 to high(combats) do
  if combats[i].exist then
  begin
    k := 0;   // проверяем есть ли в битве ещё "живые" игроки, если нет, то закрываем.
    for j := 0 to high(combats[i].Units) do
      if combats[i].Units[j].exist then
         if combats[i].Units[j].uType = 1 then
            if chars[combats[i].Units[j].charLID].exist then inc(k) // если плеер - игрок, то тогда прибавляем счётчик
            else  // Если же игров офнулся, то ---- ???
            begin
              { TODO 1 -oVeresk -cImprove : Проверка на офнутого игрока }
            end;

    // смотрим, может в одной из команд уже все умерли...
    k := 0; n := 0;
    for j:=0 to length(combats[i].units) - 1 do
        if combats[i].units[j].exist then
        if combats[i].units[j].alive then
        if combats[i].units[j].uTeam = 1 then inc(k) else inc(n);

    // посчитали живых, теперь смотрим есть ли нули...
    if k = 0 then CM_CombatEnd( i, 2 ) else
    if n = 0 then CM_CombatEnd( i, 1 );

    if k = 0 then
       begin
         CM_CombatFreeAndNil( i );
         WriteSafeText('Combat LID ## ' + IntToStr(i) + ' closed.');
       end;

// проверяем время хода...
    GetTime(hh, mm, ss, ms);
    if abs((60 * mm + ss) - (60 * combats[i].tsMin + combats[i].tsSec)) > 20 then
       begin
         combats[i].on_recount:=true;
// combats[i].AI.build_turn:=false;
// время вышло, передаём ход...
       end;
// перестройка АТБ-шкалы
    if combats[i].On_Recount then
       begin
         combats[i].NextTurn    := -1;
         combats[i].NextTurnATB := -1;
// сначала проверяем, может кто-то уже зашёл за финишную черту
         for j := 0 to high(combats[i].Units) do
           if combats[i].Units[j].exist then
           if combats[i].Units[j].alive then
           if combats[i].Units[j].ATB >= 1000 then // если пришли в конец шкалы
           if combats[i].Units[j].ATB > combats[i].NextTurnATB then
              begin
                combats[i].NextTurnATB := combats[i].Units[j].ATB;
                combats[i].NextTurn    := combats[i].Units[j].uLID;
              end;
// никого не нашли - делаем сдвиги
           if combats[i].NextTurn = -1 then
              begin
                inc(combats[i].ATBTime);           // делаем тик времени
                if (combats[i].ATBTime >= 10) then  // 10 тиков - 1 раунд
                   begin
// Начался новый раунд
// Проводим все необходимые манипуляции
                     combats[i].ATBTime:= 0;
                     inc(combats[i].ceRound);
                     CM_SendNewRound( i );   // начинаем следующий раунд
                     for j := 0 to high(combats[i].units) do
                       if combats[i].units[j].exist then
                       if combats[i].units[j].alive then
                       if combats[i].units[j].uType = 1 then
                          inc(combats[i].units[j].rounds_in);
                   end;
// Двигаем юнитов по АТБ шкале
                 for j := 0 to length(combats[i].units) - 1 do
                   if combats[i].units[j].exist then
                   if combats[i].units[j].alive then
                      begin
                        inc( combats[i].units[j].ATB, combats[i].units[j].Ini ); // делаем шаг вперёд
                        writeln(combats[i].Units[j].VData.name, ' ATB : ', combats[i].Units[j].ATB);
                        if combats[i].units[j].ATB >= 1000 then // если пришли в конец...
                        if combats[i].units[j].ATB > combats[i].NextTurnATB then
                           begin
                             combats[i].NextTurnATB := combats[i].units[j].ATB;
                             combats[i].NextTurn:= combats[i].units[j].uLID;
                           end;
                      end;
              end;
// если нашли кто ходит следущим - рассылаем сообщения, если нет - оставляем флаг
// чтобы на следующем цикле процессор снова сделал обработку АТБ шкалы
         if combats[i].NextTurn <> -1 then
            begin
              combats[i].tsMin:= mm;
              combats[i].tsSec:= ss;

              combats[i].on_recount := false;
              combats[i].uTurn := combats[i].NextTurn;
              for j := 0 to high(combats[i].Units) do
                if combats[i].Units[j].uLID = combats[i].NextTurn then
                   begin
                     writeln('Turn : ' + combats[i].Units[j].VData.name);
                     Dec(combats[i].Units[j].ATB, 1000);
                     combats[i].Units[j].Data.cAP:=combats[i].Units[j].Data.mAP;
                     if combats[i].Units[j].ATB < 0 then combats[i].Units[j].ATB := 0;
                   end;
     //         CM_SendATB( i );                            //отправляем новую атб-шкалу
              CM_SendTurnStart( i, combats[i].NextTurn );   //отправляем новый ход
              WriteSafeText(' Combat #' + IntToStr(combats[i].ID) +
                            ' next turn uUID =' + IntToStr( combats[i].NextTurn ) );
            end;
       end;
// Обрабатываем работу ИИ
    AI_Process( i );
  end;
end;

function CM_StartNew(initiator, ceType, ceUID : DWORD): word;
var i, j, r: integer;
begin
  result := high(word);
                     // создаём бой
  for i := 0 to high(combats) do
    if not combats[i].exist then
       begin
         inc(cm_total);
         combats[i].exist    := true;
         combats[i].ID       := cm_total;
         combats[i].comLID   := i;
         combats[i].ceUID    := ceUID;
         combats[i].ceType   := ceType;
         combats[i].ceRound  := 0;
         combats[i].ATBTime  := 0;
         combats[i].pLimit   := 1;

         combats[i].On_Recount := true;

         for j := 0 to high(combats[i].Units) do
             begin
               combats[i].Units[j].uID := high(word);
               combats[i].Units[j].uLID := high(word);
             end;

         result := combats[i].ID;
         break;
       end;

  WriteSafeText('Combat ID ## ' + IntToStr(result) + ' prototype added.', 1);


  if ceType = 1 then  // добавляем мобов
     begin
       if not ceDB[ceUID].exist then exit;
       combats[i].pLimit:= ceDB[ceUID].limit;
       for j := 1 to 4 do
           if ceDB[ceUID].mobs[j] > 0 then CM_AddAIUnit(combats[i].ID, ceDB[ceUID].mobs[j], 2);

       for j := 1 to 3 do
           if ceDB[ceUID].ally[j] > 0 then CM_AddAIUnit(combats[i].ID, ceDB[ceUID].ally[j], 1);

     end else combats[i].pLimit := 2;

                     // добавляем юниты
  if result <> high(word) then
     begin
       r := CM_AddPUnit(result, initiator, 1);
       if r <> 1 then result := high(word);
     end;

  if result <> high(word) then
     WriteSafeText('Combat ID #' + IntToStr(combats[i].ID) + ' has been opened.', 1);
end;

function CM_AddPUnit(comID, charLID: DWORD; uTeam : byte) : byte;
var i, k   : integer;
    comLID : DWORD;
begin
  result := high(byte);
  comLID := CM_GetCombatLID( comID );

  if chars[charLID].in_combat then
     begin
       WriteSafeText('Already in combat! Abort.', 3);
       exit;
     end;
  if comLID = high(DWORD) then
    begin            // такого боя не существует. логгируем
      WriteSafeText(' Combat #' + intToStr(comID) + ' doesnt exist! CM_AddUnit charID = ' + IntToStr(charLID) + ' aborted.', 3);
      exit;
    end;
  if CM_GetPUnitsNum( comLID ) >= combats[comLID].pLimit then
    begin   // если нет пустой ячейки для игрока
      WriteSafeText('Not enough slots to enter combat LID ## ' + IntToStr(CM_GetPUnitsNum( comLID )) + ' / ' + IntToStr(combats[comLID].pLimit), 2);
      result := high(byte) - 1;     // код ошибки
      exit;
    end;

  k := -1;
  for i := 0 to high(combats[comLID].Units) do
    if not combats[comLID].Units[i].exist then
      begin
        combats[comLID].Units[i].exist   := true;
        combats[comLID].Units[i].alive   := true;
        combats[comLID].Units[i].uLID    := i;
        combats[comLID].Units[i].uType   := 1;
        combats[comLID].Units[i].uTeam   := uTeam;
        combats[comLID].Units[i].charLID := charLID;
        combats[comLID].Units[i].rounds_in:= 0;

        combats[comLID].Units[i].Data.pos:= CM_SetStartPos(comLID, uTeam);
        Writeln(combats[comLID].Units[i].Data.pos.x, ' - ', combats[comLID].Units[i].Data.pos.y);

        combats[comLID].Units[i].VData.name:=Chars[charLID].header.Name;
        if uTeam = 1 then combats[comLID].units[i].Data.Direct:=0 else combats[comLID].units[i].Data.Direct:= 4;

        combats[comLID].Units[i].VData.Race:=chars[charLID].header.raceID;
        combats[comLID].Units[i].VData.skinArm := 1;
        combats[comLID].Units[i].VData.skinMH  := 1;
        combats[comLID].Units[i].VData.skinOH  := 1;

         // приписываем юниту свойства
        combats[comLID].Units[i].Data.mHP := chars[charLID].hpmp.mHP;
        combats[comLID].Units[i].Data.cHP := chars[charLID].hpmp.cHP;
        combats[comLID].Units[i].Data.mMP := chars[charLID].hpmp.mMP;
        combats[comLID].Units[i].Data.cMP := chars[charLID].hpmp.cMP;
        combats[comLID].Units[i].Data.mAP := chars[charLID].hpmp.mAP;
        combats[comLID].Units[i].Data.cAP := chars[charLID].hpmp.mAP;

        combats[comLID].Units[i].Ini := chars[charLID].Stats.Ini;
        combats[comLID].Units[i].APH := 15;
        combats[comLID].Units[i].minD:= 20;
        combats[comLID].Units[i].maxD:= 30;
        combats[comLID].Units[i].armor:=0;

        chars[charLID].in_combat := true;
        k := i;
        result := 1;
        writesafetext('Player Unit ## ' + IntToStr(charLID) + ' has been added in slot ' + IntToStr(i));
        break;
      end;
  if k = -1 then result := high(byte) - 2;
end;

function CM_AddAIUnit(comID, uID : DWORD; uTeam : byte) : byte;
var i, k : integer;
    comLID : DWORD;
begin
  comLID := CM_GetCombatLID( comID );

  if comLID = high(DWORD) then
    begin            // такого боя не существует. логгируем
      WriteSafeText(' Combat ID #' + intToStr(comID) + ' doesnt exist! CM_AddAIUnit uID = ' + IntToStr(uID) + ' aborted.', 3);
      exit;
    end;

   k := -1;
  for i := 0 to high(combats[comLID].Units) do
    if not combats[comLID].Units[i].exist then
      begin
        combats[comLID].Units[i].exist   := true;
        combats[comLID].Units[i].alive   := true;
        combats[comLID].Units[i].uLID    := i;
        combats[comLID].Units[i].uType   := 2;
        combats[comLID].Units[i].uTeam   := uTeam;
        combats[comLID].Units[i].uID     := uID;
        combats[comLID].Units[i].Data.pos:= CM_SetStartPos(comLID, uTeam);
        if uTeam = 1 then combats[comLID].units[i].Data.Direct:=0 else combats[comLID].units[i].Data.Direct:= 4;
        Writeln(combats[comLID].Units[i].Data.pos.x, ' - ', combats[comLID].Units[i].Data.pos.y);

        combats[comLID].Units[i].VData.name    := MobDataDB[uID].name;
        combats[comLID].Units[i].VData.Race    := MobDataDB[uID].race;
        combats[comLID].units[i].VData.skinMH  := MobDataDB[uID].skMH;
        combats[comLID].units[i].VData.skinArm := MobDataDB[uID].skBody;
        combats[comLID].units[i].VData.skinOH  := MobDataDB[uID].skOH;

          // приписываем юниту свойства
        combats[comLID].Units[i].Data.mHP := hpmp_counter(MobDataDB[uID].HP, MobDataDB[uID].Con);
        combats[comLID].Units[i].Data.cHP := hpmp_counter(MobDataDB[uID].HP, MobDataDB[uID].Con);
        combats[comLID].Units[i].Data.mMP := hpmp_counter(MobDataDB[uID].MP, MobDataDB[uID].Int);
        combats[comLID].Units[i].Data.cMP := hpmp_counter(MobDataDB[uID].MP, MobDataDB[uID].Int);
        combats[comLID].Units[i].Data.mAP := MobDataDB[uID].AP;
        combats[comLID].Units[i].Data.cAP := MobDataDB[uID].AP;

        combats[comLID].Units[i].lvl  := MobDataDB[uID].lvl;
        combats[comLID].Units[i].Ini  := MobDataDB[uID].Ini;
        combats[comLID].Units[i].APH  := MobDataDB[uID].APH;
        combats[comLID].Units[i].minD := trunc(MobDataDB[uID].DPAP * MobDataDB[uID].APH * 0.95);
        combats[comLID].Units[i].maxD := trunc(MobDataDB[uID].DPAP * MobDataDB[uID].APH * 1.05);
        combats[comLID].Units[i].armor:= MobDataDB[uID].ARM;

        k := i;
        writesafetext('AI Unit ## ' + IntToStr(uID) + ' has been added in slot ' + IntToStr(i));
        result := 1;
        break;
      end;
  if k = -1 then result := high(byte) - 2;
end;

function CM_MeleeAttack( comLID, uLID, tLID, spID : dword) : byte;
var i, rs : integer;
    charLID, uType, AP_DEC, auID, c_ID, c_V: DWORD;
    dam, bdam, deadly, add_dam, block_val, block_val2, armor : integer;
    dr, dr2 : single;
    hit_table : array [1..10000] of byte;
    i1, i2, i3 : integer;
    behind  : boolean;
    _pkg : TPkg108; _head : TPackHeader;
    mStr : TMemoryStream;
begin
  if (spID = 1) or (spID = 4) or (spID = 5) or (spID = 11) then exit;

  dam := 0; add_dam := 0; dr2 := 0;  behind := false;
  deadly := 0; // На всякий

  rs := combats[comLID].units[tLID].Data.Direct;
  rs := rs + 4;
  if rs > 7 then rs := rs - 8;
  if insector(rs, m_Angle(combats[comLID].units[tLID].Data.pos.x, combats[comLID].units[tLID].Data.pos.y,
                          combats[comLID].units[uLID].Data.pos.x, combats[comLID].units[uLID].Data.pos.y)) then
     behind := true;

  AP_DEC := combats[comLID].units[uLID].APH;
  if spID = 2 then AP_DEC := AP_DEC + 5;
  if spID = 3 then AP_DEC := AP_DEC + 0;
  if spID = 9 then AP_DEC := 15;
  if spID = 7 then AP_DEC := 15;
  if spID = 10 then AP_DEC := Round(combats[comLID].units[uLID].APH * 0.75);

  if combats[comLID].units[uLID].Data.cAP < AP_DEC then
     begin
       WriteSafeText( ' Not enough AP for melee attack !! ', 3 );
       exit;
     end;

  CM_DelAura(comLID, uLID, 1); // Keep moving
  sleep(10);
  CM_DelAura(comLID, uLID, 2); // Inertia

  if not InSector( combats[comLID].units[uLID].Data.Direct,
                   m_Angle( combats[comLID].units[uLID].Data.pos.x,
                            combats[comLID].units[uLID].Data.pos.y,
                            combats[comLID].units[tLID].Data.pos.x,
                            combats[comLID].units[tLID].Data.pos.y ) ) then
     begin
       WriteSafeText( ' Not in sector for melee attack !! ', 3 );
       exit;
     end;

  if (spID = 9) then    // если абилка связана со щитом, то
     begin
       block_val := -1;
   //    block_val := combats[comLID].units[uLID].bVal;
       if block_val < 1 then exit;
     end;

  // сканим ауру для инерции. Снимаем ауру независимо от результата удара
  auID := CM_FindAura(comLID, uLID, 2);
  if auID <> high(byte) then
     begin
       add_Dam := trunc(combats[comLID].units[uLID].auras[auID].stacks * combats[comLID].units[uLID].APH / 60 );
       writesafetext('ADD_DMG : ' + IntToStr(add_Dam), 2);
       CM_DelAura(comLID, uLID, 2);
     end;

  // строим таблицу ударов
  // сначала миссы (вытесняются хитом
  i1 := 500; // вставить код мисса сюда
  for i := 1 to i1 do
    hit_table[i] := 1;
  i2 := i1 + 1;

  if not behind then i1 := 500 else i1 := 0; // вставить код доджа сюда
  if i1 > 0 then
     begin
       for i := i2 to i2 + i1 do
           hit_table[i] := 2;
       i2 := i2 + i1 + 1;
     end;


  // вставить код блок сюда
  block_val2 := 0; i1 := 0;
//  block_val2 := combats[comLID].units[tLID].bVal;
  if block_val2 > 0 then
     begin
       i1 := 500;
       // ЧЕКАЕМ ПЕРК DEF ВЕТКИ
       if combats[comLID].Units[tLID].uType = 1 then
          if chars[combats[comLID].Units[tLID].charLID].perks[1][3] > 0 then  // block mastery
             i1 := i1 + PerksDB[15].xyz[chars[combats[comLID].Units[tLID].charLID].perks[1][3]].x * 100;
       // чекаем деф стойку
       if CM_FindAura(comLID, tLID, 9) <> high(byte) then
          i1 := i1 + 2500;
     end;
  if behind then i1 := 0;
 // WriteSafeText(IntToStr(i1));
  if i1 > 0 then
     begin
       for i := i2 to i2 + i1 do
           hit_table[i] := 3;
       i2 := i2 + i1 + 1;
     end;

  for i := i2 to high(hit_table) do      // остаток заполняем белыми атаками
    hit_table[i] := 0;

  i1 := random(9999) + 1;
  i3 := hit_table[i1];

if (i3 <> 1) and (i3 <> 2) then    // если попали, то...
begin
  // нашли локальные номера юнитов, теперь рассчитываем дамаг
  bdam := combats[comLID].units[uLID].minD + random(combats[comLID].units[uLID].maxD -
                                                    combats[comLID].units[uLID].minD);

  i2 := 300;    // базовый шанс крита
  // ЧЕКАЕМ ПЕРК САБТ ВЕТКИ
  if combats[comLID].Units[uLID].uType = 1 then
     if chars[combats[comLID].Units[tLID].charLID].perks[6][1] > 0 then  // бэсик сабт
        i2 := i2 + PerksDB[14].xyz[chars[combats[comLID].Units[tLID].charLID].perks[6][1]].x * 100;

  // проверка на крит
  i1 := random(10000);
  if i1 < i2 then i3 := i3 + 10;
     {то есть просто крит даёт и3 = 10
              блок крита даёт  и3 = 13
              простым делением на 10 можно определить был это блок или же
              прямой крит }

  // Поправка на СЛЭМ
  if spID = 2 then bdam := round(bdam * 1.25);

  // Поправка на ХЭЙТФУЛ СТРАЙК
  if spID = 3 then
     begin
       bdam := bdam + trunc(combats[comLID].units[uLID].PData.Rage * 0.25);
       combats[comLID].units[uLID].PData.Rage := 0;
     end;

  if spID = 7 then
     begin
       bdam := bdam div 4;
       if CM_FindAura(comLID, tLID, 4) <> high(byte) then CM_DelAura(comLID, tLID, 4);
       rs := CM_AddAura(comLID, tLID, 4, bdam * 4 div 3);
       combats[comLID].units[tLID].auras[rs].left := 3;
     end;

  // Поправка на ШИЛД БАШ
  if spID = 9 then
     begin
       bdam := 10 + trunc(1.5 + block_val);
       if combats[comLID].Units[uLID].uType = 1 then
          if chars[combats[comLID].Units[uLID].charLID].perks[1][2] > 0 then  // smashing shield
             bdam := 1 + trunc(bdam * (1 + PerksDB[18].xyz[chars[combats[comLID].Units[uLID].charLID].perks[1][2]].x / 100));
     end;

  // поправка на СЛАЙС
  if spID = 10 then bdam := trunc(bdam * 0.8);

  {
   Расчёт базового урона закончен. Теперь поверх этого добавляется
   модификатор крита.
  }

  if (i3 >= 10) then       // crit
     begin
       bdam := trunc(bdam * 1.5);
       if combats[comLID].Units[uLID].uType = 1 then // bloodlust
          if chars[combats[comLID].Units[uLID].charLID].perks[0][2] > 0 then
             begin
               writeSafeText('uATB_before = ' + IntToStr(combats[comLID].units[uLID].ATB), 1);
               combats[comLID].units[uLID].ATB := combats[comLID].units[uLID].ATB +
                                                      PerksDB[19].xyz[chars[combats[comLID].Units[uLID].charLID].perks[0][2]].x;
         //      CM_SendATB(comLID);
               writeSafeText('uATB_after = ' + IntToStr(combats[comLID].units[uLID].ATB), 1);
             end;
     end;

  // сканим перки
  if combats[comLID].Units[tLID].uType = 1 then
  if chars[combats[comLID].Units[tLID].charLID].perks[5][2] > 0 then  // Сурвайвал инстинкт
     dr2 := PerksDB[8].xyz[chars[combats[comLID].Units[tLID].charLID].perks[5][2]].x / 100;

  // расчёт снижения урона от брони
  armor := combats[comLID].units[tLID].armor;
         // поправка на фрост армор...
  rs  := CM_FindAura(comLID, tLID, 5);
  if rs <> high(byte) then
     begin
       armor := armor + 75;
       dec(combats[comLID].units[tLID].auras[rs].stacks);
       if combats[comLID].units[tLID].auras[rs].stacks <= 0 then
          CM_DelAura(comLID, tLID, 5);
     end;

  dr := CM_DR(armor, combats[comLID].units[tLID].VData.lvl );

  dam := trunc( (bdam + add_dam) * (1 - dr ) );

  WriteSafeText(' Dam Before = ' + IntToStr(dam), 2);
  WriteSafeText(' dr2 = ' + FloatToStr(dr2), 2);
  dam := trunc(dam * (1 - dr2));
  WriteSafeText(' Dam After = ' + IntToStr(dam), 2);

  {
   Самый последний модификатор на снижение - это блок.
   Он вычитается уже после всех манипуляций с уроном.
  }

  if i3 / 10 > 1 then dam := dam - block_val2;
  if i3 = 3 then dam := dam - block_val2;
  if dam < 1 then dam := 1;

  combats[comLID].units[tLID].Data.cHP:= combats[comLID].units[tLID].Data.cHP - dam;

  if (combats[comLID].units[tLID].Data.cHP <= 0 ) then
     begin
       combats[comLID].units[tLID].Data.cHP  := 0;
       combats[comLID].units[tLID].alive     :=false;
       deadly := 1;
       if combats[comLID].units[tLID].uTeam = 2 then
          if combats[comLID].units[tLID].uType = 2 then
             combats[comLID].xpPool := combats[comLID].xpPool + exp_mob[combats[comlid].units[tLID].lvl];
   {    //**** ПРОВЕРЯЕМ ЮНИТА ПО СЧЁТЧИКАМ...
               if combats[comLID].units[tarLID].uType = 2 then // это моб
                  for i := 0 to high(combats[comLID].units) do
                    if combats[comLID].units[i].exist then
                       if combats[comLID].units[i].uType = 1 then
                          begin

                            c_ID := high(DWORD);
                            c_ID := DB_GetCharCounter2(Char_GetCharLID2(combats[comLID].units[i].charID),
                                                        combats[comLID].units[tarLID].prototype);

                            if c_ID <> high(DWORD) then
                               begin
                                 c_V := DB_GetCharCounter(Char_GetCharLID2(combats[comLID].units[i].charID),
                                                           c_ID);
                                 inc(c_V);
                                 DB_SetCharCounter(Char_GetCharLID2(combats[comLID].units[i].charID),
                                                   c_ID, c_V);
                               end;
                          end; }
     end;

  // Smashing Strikes Perk
  if combats[comLID].Units[uLID].uType = 1 then
  if chars[combats[comLID].Units[uLID].charLID].perks[2][2] > 0 then
     if ItemDB[chars[combats[comLID].Units[uLID].charLID].Inventory[4].iID].data.iType = 4 then  // если в руках нужный вепон
        begin
          writeSafeText('uATB_before = ' + IntToStr(combats[comLID].units[tLID].ATB), 1);
          combats[comLID].units[tLID].ATB := combats[comLID].units[tLID].ATB -
             PerksDB[10].xyz[chars[combats[comLID].Units[uLID].charLID].perks[2][2]].x;
          if combats[comLID].units[tLID].ATB < 0 then
             combats[comLID].units[tLID].ATB := 0;
      //    CM_SendATB(comLID);
          writeSafeText('uATB_after = ' + IntToStr(combats[comLID].units[tLID].ATB), 1);
        end;

   // набираем рагу
  inc(combats[comLID].units[tLID].pData.Rage, AP_DEC);
  if combats[comLID].units[tLID].vData.Race = 2 then
     inc(combats[comLID].units[tLID].pData.Rage, 3);
  if combats[comLID].units[tLID].pData.Rage > 100 then
     combats[comLID].units[tLID].pData.Rage:= 100;
end else {блок попадания закончен}
  begin
    deadly := 0; dam := 0;
  end;

  // вычитаем АП
  combats[comLID].units[uLID].Data.cAP:=combats[comLID].units[uLID].Data.cAP - AP_DEC;
  if combats[comLID].units[uLID].Data.cAP < 0 then combats[comLID].units[uLID].Data.cAP := 0;

  // отменяем инвиз, если есть
{  if not combats[comLID].units[charLID].visible then
     CM_TurnVisible(comLID, charLID);         }

{  if (combats[comLID].units[tarLID].Rage = 100) and (combats[comLID].units[tarLID].alive)  then
     begin
       combats[comLID].units[tarLID].curAP:=combats[comLID].units[tarLID].maxAP;
       AI_TurnTo(comLID, tarLID, charLID);
       combats[comLID].units[tarLID].Rage := 0;
       CM_MeleeAttack(comLID, tarUID, charUID, spID);
     end;     }
try
  mStr := TMemoryStream.Create;

  _head._flag := $f;
  _head._id   := 108;

  _pkg.comID   := combats[comLID].ID;
  _pkg.tLID    := tLID;
  _pkg.uLID    := uLID;
  _pkg.skillID := spID;
  _pkg.ap_left := combats[comLID].Units[uLID].Data.cAP;

  _pkg.victims[1].uLID   := tLID;
  _pkg.victims[1].result := i3;
  _pkg.victims[1].dmg    := dam;
  _pkg.victims[1].deadly := deadly;
  _pkg.victims[1].hp_left:= combats[comLID].Units[tLID].Data.cHP;

  mStr.Write(_head, sizeof(_head));
  mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет всем игрока в бою
  for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then
         begin
           TCP.FCon.IterReset;
           charLID := combats[comLID].Units[i].charLID;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
finally
  mStr.Free;
end;

  CM_SendBaseInfo( comLID, uLID );  // отправляем обновлённые данные о хп
  CM_SendBaseInfo( comLID, tLID );
end;


function CM_CombatEnd( comLID, WinTeam : dword) : byte;
var i, j, rs: integer;
    cID, charLID : dword;
    numpl : byte;
    rnd1, rnd2 : byte;
    xp, gold : DWORD;
begin
  numpl := 0; xp := 0; gold := 0;

  for i := 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist then
      if combats[comLID].units[i].uType = 1 then
         begin
           CM_SendEndBattle(comLID, i, WinTeam);
           inc(numpl);
         end;

  WriteSafeText( 'NumPL = ' + IntToStr(numpl) + ' XP Pool  = ' + IntToStr(combats[comLID].xpPool ), 2);

  if combats[comLID].ceType = 1 then // если дуэл то опыта не даём
  if WinTeam = 1 then
     xp := combats[comLID].xpPool div numpl
  else
     xp := combats[comLID].xpPool div 15;

  if combats[comLID].ceType = 1 then // если дуэл то голда не даём не даём
     if WinTeam = 1 then
        gold := LootDB[combats[comLID].ceUID].gold
     else
        gold := 0;  // Если проиграли - то никакого голда

  for i := 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].units[i].exist then
      if combats[comLID].units[i].uType = 1 then
         begin
           charLID := combats[comLID].Units[i].charLID;
           chars[charLID].in_combat:= false;

           // проверяем если ли "победный" триггер, если да, то выполняем
           if winteam = combats[comLID].units[i].uTeam then
           for j := 1 to 10 do
              // if ceDB[combats[comLID].ceUID].on_win[j].pNum > 0 then
                  if (j - 1) / 3 = (j - 1) div 3 then
                     begin
                       if ceDB[combats[comLID].ceUID].on_win[j] = 2 then
                          begin
                            WriteSafeText('ON WIN TRIGGERED!');
                            DB_SetCharVar(charLID, ceDB[combats[comLID].ceUID].on_win[j + 2],
                                          'v' + IntToStr(ceDB[combats[comLID].ceUID].on_win[j + 1]));
                            Char_SendLocObjs(charLID, chars[charLID].header.loc);
                          end;
                     end;

           WriteSafeText('cur HP do >' + chars[charLID].header.name + ' ' + IntToStr(chars[charLID].hpmp.cHP) + ' > ' + intToStr(combats[comLID].units[i].Data.cHP) );

           chars[charLID].hpmp.cHP := combats[comLID].units[i].Data.cHP;
           chars[charLID].hpmp.cMP := combats[comLID].units[i].Data.cMP;

           if chars[charLID].hpmp.cHP < 1 then chars[charLID].hpmp.cHP := 1;
           if chars[charLID].hpmp.cMP < 0 then chars[charLID].hpmp.cMP := 0;

           DB_SetCharData(charLID, chars[charLID].header.name);

           WriteSafeText('cur HP posle >' + chars[charLID].header.name + ' ' + IntToStr(chars[charLID].hpmp.cHP) );
  //         Char_SendCharStats( cID, CharLID );
  // !!!!!!!!!!!!========================================================================
           Char_AddNumbers(charLID, gold,
                           round(xp * combats[comLID].units[i].rounds_in/combats[comLID].ceRound),
                           0, 0, 0);

           if combats[comLID].ceType = 1 then // если дуэл то лута не даём
           If WinTeam = 1 then
              begin
                CM_Loot(charLID, combats[comLID].ceUID);
              end;

         end;
 CM_CombatFreeAndNil( comLID );
end;


// получаем количесто игроков, которые уже в бою
function CM_GetPUnitsNum( comLID : DWORD) : byte;
var i, k: integer;
begin
  k := 0; result := 0;
  for i:= 0 to length(combats[comLID].units) - 1 do
    if combats[comLID].exist then
    if combats[comLID].units[i].uType = 1 then inc(k);
  result := k;
end;

// получаем номер ячейки в которой идёт комбат
function CM_GetCombatLID( comID : DWORD) : DWORD;
var i: integer;
begin
  result := high(DWORD); // нет такого комбата
  for i:= 0 to length(combats) - 1 do
    if combats[i].exist then
    if combats[i].ID = comID then
       begin
         result := i;
         exit;
       end;
end;

function CM_DR( armor, level : dword) : single;
begin
  result := 0;
  result := armor / (armor + 200 + level * 25 );
  if result > 0.75 then result := 0.75;
end;

function CM_CombatFreeAndNil( comLID : dword) : byte;
var i: integer;
begin
  combats[comLID].exist:= false;
  combats[comLID] := zero_combat;
end;

function CM_CheckFreeNode( comLID: DWORD; mX, mY: word): boolean;
var i: integer;
begin
  result:=true;
  for i:=0 to length(combats[comLID].units) - 1 do
  begin
    if combats[comLID].units[i].exist then
      if combats[comLID].units[i].Data.pos.x = mX then
        if combats[comLID].units[i].Data.pos.y = mY then
          begin
            result := false;   // выяснили, что клетка занята
            exit;
          end;
   // result := true; //если дошли до сюда, значит юнитов нет и можно входить
  end;
end;

function CM_SetStartPos( comLID: DWORD; uTeam: byte) : TMPoint;
var x, y : word; b: boolean;
begin
  x := 0; y:= 0;
  if not combats[comLID].exist then exit;
  case uTeam of
    1 : begin
          x:= 1;
          b:= false;
          while not b do
            begin
              y := 1 + random(18);
              b := CM_CheckFreeNode( comLID, x, y);
            end;
        end;
    2 : begin
          x := 19;
          b := false;
          while not b do
            begin
              y := 1 + random(18);
              b := CM_CheckFreeNode( comLID, x, y);
            end;
        end;
  end;
  result.x:=x;
  result.y:=y;
end;

function CM_SetUnitDirection( sX, sY, fX, fY : DWORD) : DWORD;
begin
  if fX > sX then
     begin
       if fY > sY then result := 6;
       if fY = sY then result := 7;
       if fY < sY then result := 0;
     end;

  if fX = sX then
     begin
       if fY > sY then result := 5;
       if fY < sY then result := 1;
     end;

  if fX < sX then
     begin
       if fY > sY then result := 4;
       if fY = sY then result := 3;
       if fY < sY then result := 2;
     end;
end;

// добавляем лут из таблицы
function CM_Loot(charLID, lootID: dword) : byte;
var i, k, r, qid, qch: integer;
    lt : array [1..4] of tltcache;
begin
  if not LootDB[lootID].exist then exit;
  r := 0;
  // первая группа лута - обязательные предметы
  for i := 1 to 4 do
    if LootDB[lootID].LItems[i].exist then
       begin
         r := random(10000);

         {
           Проверяем есть ли у чара квест, который требует данного предмета.
           Если квеста нет, то предмет 100% не упадёт.
         }
         if ItemDB[LootDB[lootID].LItems[i].iID].data.iType = 35 then
            begin
                  // получаем номер квеста к которому привязан предмет
              qid := ItemDB[LootDB[lootID].LItems[i].iID].data.props[5];
              qch := DB_GetCharVar(charLID, 'q' + IntToStr(qid));
              WriteSafeText('qid = ' + IntToStr(qid) + ' qch = ' + IntToStr(qch), 2);
              WriteSafeText(IntToStr(r) + 'vs' + IntToStr(LootDB[lootID].LItems[i].chance));
                  // проверяем статус квеста у игрока. Если есть, то добваляем
              if qch = 1 then
                 if r <= LootDB[lootID].LItems[i].chance then
                         char_AddItem( charLID, LootDB[lootID].LItems[i].iID );
            end else
         if r <= LootDB[lootID].LItems[i].chance then
            char_AddItem( charLID, LootDB[lootID].LItems[i].iID );
       end;
  k := 0;
  // вторая группа лута
  for i := 5 to 7 do
    if LootDB[lootID].LItems[i].exist then
       begin
         inc(k);
         lt[k].iID := LootDB[lootID].LItems[i].iID;
         if k = 1 then lt[k].min:=0 else lt[k].min:=lt[k - 1].max + 1;
         lt[k].max:=lt[k].min + LootDB[lootID].LItems[i].chance;
       end;
  if k <> 0 then
     begin
       r := random(10000);
       for i := 1 to 4 do
         if lt[i].iID <> 0 then
           if (r >= lt[i].min) and (r <= lt[i].max) then char_AddItem(charLID, lt[i].iID);
       k := 0;
       for i := 1 to 4 do
         begin
           lt[i].iID:=0;
           lt[i].max:=0;
           lt[i].min:=0;
         end;
     end;

  // третья группа лута
  for i := 8 to 10 do
    if LootDB[lootID].LItems[i].exist then
       begin
         inc(k);
         lt[k].iID := LootDB[lootID].LItems[i].iID;
         if k = 1 then lt[k].min:=0 else lt[k].min:=lt[k - 1].max + 1;
         lt[k].max:=lt[k].min + LootDB[lootID].LItems[i].chance;
       end;
  if k <> 0 then
     begin
       r := random(10000);
       for i := 1 to 4 do
         if lt[i].iID <> 0 then
           if (r >= lt[i].min) and (r <= lt[i].max) then char_AddItem(charLID, lt[i].iID);
       k := 0;
       for i := 1 to 4 do
         begin
           lt[i].iID:=0;
           lt[i].max:=0;
           lt[i].min:=0;
         end;
     end;

  // четвёртая группа лута
  for i := 11 to 12 do
    if LootDB[lootID].LItems[i].exist then
       begin
         inc(k);
         lt[k].iID := LootDB[lootID].LItems[i].iID;
         if k = 1 then lt[k].min:=0 else lt[k].min:=lt[k - 1].max + 1;
         lt[k].max:=lt[k].min + LootDB[lootID].LItems[i].chance;
       end;
  if k <> 0 then
     begin
       r := random(10000);
       for i := 1 to 4 do
         if lt[i].iID <> 0 then
           if (r >= lt[i].min) and (r <= lt[i].max) then char_AddItem(charLID, lt[i].iID);
       k := 0;
       for i := 1 to 4 do
         begin
           lt[i].iID:=0;
           lt[i].max:=0;
           lt[i].min:=0;
         end;
     end;
end;

function CM_CheckMelee(comLID, u1, u2: dword) : boolean;
var i: integer;
begin
  result := false;
  if not combats[comLID].exist then exit;
  if not combats[comLID].units[u1].exist then exit;
  if not combats[comLID].units[u2].exist then exit;
  if not combats[comLID].units[u1].alive then exit;
  if not combats[comLID].units[u2].alive then exit;
  if (abs(combats[comLID].units[u1].Data.pos.x - combats[comLID].units[u2].Data.pos.x) <= 1) and
     (abs(combats[comLID].units[u1].Data.pos.y - combats[comLID].units[u2].Data.pos.y) <= 1) then
     result := true;
end;

function CM_CheckCol(x, y, x2, y2 : DWORD): boolean; inline;
begin
  result := false;
  if abs(x - x2) <= 1 then
     if abs(y - y2) <= 1 then
        result := true;
end;

function CM_AddAura(comLID, charLID, ID, stacks : DWord): byte;
var i: integer;
begin
  result := high(byte);
  for i := 1 to high(combats[comLID].units[charLID].auras) do
      if combats[comLID].units[charLID].auras[i].exist then
         if combats[comLID].units[charLID].auras[i].id = ID then
            begin
              result := high(byte) - 1;
              exit;
            end;

  for i := 1 to high(combats[comLID].units[charLID].auras) do
      if not combats[comLID].units[charLID].auras[i].exist then
         begin
           result := i;
           combats[comLID].units[charLID].auras[i].exist := true;
           combats[comLID].units[charLID].auras[i].id := ID;
           combats[comLID].units[charLID].auras[i].sub := 1;
           combats[comLID].units[charLID].auras[i].left:= 1;
           if stacks > 0 then combats[comLID].units[charLID].auras[i]._st:=true;
           inc(combats[comLID].units[charLID].auras[i].stacks, stacks);
           if combats[comLID].units[charLID].auras[i]._st then
              if combats[comLID].units[charLID].auras[i].stacks < 1 then
                 combats[comLID].units[charLID].auras[i].exist:= false;
           break;
         end;

//  CM_SendAuras(comLID);
end;

function CM_DelAura(comLID, charLID, ID : DWord): byte;
var i: integer;
begin
  result := high(byte) ;
  for i := 1 to high(combats[comLID].units[charLID].auras) do
      if combats[comLID].units[charLID].auras[i].exist then
         if combats[comLID].units[charLID].auras[i].id = ID then
            begin
              combats[comLID].units[charLID].auras[i].exist := false;
              combats[comLID].units[charLID].auras[i]._st:=false;
              combats[comLID].units[charLID].auras[i].stacks:=0;
              WriteSafeText('Aura ' + IntToStr(combats[comLID].units[charLID].auras[i].id) + ' deleted.', 1);
              break;
            end;
 // CM_SendAuras(comLID);
end;

function CM_FindAura(comLID, charLID, ID : DWord): byte;
var i: integer;
begin
  result := high(byte) ;
  for i := 1 to high(combats[comLID].units[charLID].auras) do
      if combats[comLID].units[charLID].auras[i].exist then
         if combats[comLID].units[charLID].auras[i].id = ID then
            begin
              result := i;
              exit;
            end;
end;

procedure CM_SendUnits(comLID, charLID : word);
var _head  : TPackHeader; _pkg : TPkg101;
    mStr   : TMemoryStream;
    i      : integer;
begin
  for i := 0 to high(combats[comLID].Units) do
    if combats[comLID].Units[i].exist then
       begin
         _pkg.list[i].exist  := true;
         _pkg.list[i].Name   := combats[comLID].Units[i].VData.name;
         _pkg.list[i].uType  := combats[comLID].Units[i].uType;
         _pkg.list[i].uLID   := combats[comLID].Units[i].uLID;
         _pkg.list[i].uTeam  := combats[comLID].Units[i].uTeam;
       end else _pkg.list[i].exist := false;

  _head._flag := $f;
  _head._id   := 101;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет
 {   for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then  }
         begin
           TCP.FCon.IterReset;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;

procedure CM_SendNewRound(comLID : word);
var _head  : TPackHeader; _pkg : TPkg104;
    mStr   : TMemoryStream;
    i, charLID: word;
begin
  _head._flag := $f;
  _head._id   := 104;

  _pkg.ceRound := combats[comLID].ceRound;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет всем игрока в бою
    for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then
         begin
           TCP.FCon.IterReset;
           charLID := combats[comLID].Units[i].charLID;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;

procedure CM_SendNextTurn(comLID : word);
var _head  : TPackHeader; _pkg : TPkg104;
    mStr   : TMemoryStream;
    i, charLID: word;
begin
  _head._flag := $f;
  _head._id   := 104;

  _pkg.ceRound := combats[comLID].ceRound;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет всем игрока в бою
    for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then
         begin
           TCP.FCon.IterReset;
           charLID := combats[comLID].Units[i].charLID;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;

procedure CM_SendTurnStart( comLID, uLID : DWORD);
var _head  : TPackHeader; _pkg : TPkg105;
    mStr   : TMemoryStream;
    i, charLID: word;
begin
  _head._flag := $f;
  _head._id   := 105;

  _pkg.NextTurn := uLID;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет всем игрока в бою
    for i := 0 to high(combats[comLID].Units) do
      if combats[comLID].Units[i].exist then
      if combats[comLID].Units[i].uType = 1 then
         begin
           TCP.FCon.IterReset;
           charLID := combats[comLID].Units[i].charLID;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;


procedure CM_SendBaseInfo( comLID, uLID : DWORD);
var _head     : TPackHeader; _pkg : TPkg109;
    mStr      : TMemoryStream;
    charLID: word;
begin
  if not combats[comLID].Units[uLID].exist then Exit;
  if combats[comLID].Units[uLID].uType <> 1 then Exit;

  charLID := combats[comLID].Units[uLID].charLID;

  _head._flag := $f;
  _head._id   := 109;

  _pkg.comID:= combats[comLID].ID;
  _pkg.uLID := uLID;

  _pkg.cAP  := combats[comLID].Units[uLID].Data.cAP;
  _pkg.cHP  := combats[comLID].Units[uLID].Data.cHP;
  _pkg.cMP  := combats[comLID].Units[uLID].Data.cMP;
  _pkg.Rage := combats[comLID].Units[uLID].PData.rage;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет
         begin
           TCP.FCon.IterReset;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;

procedure CM_SendEndBattle( comLID, uLID, WinTeam : DWORD );
var _head     : TPackHeader; _pkg : TPkg110;
    mStr      : TMemoryStream;
    charLID: word;
begin
  if not combats[comLID].Units[uLID].exist then Exit;
  if combats[comLID].Units[uLID].uType <> 1 then Exit;

  charLID := combats[comLID].Units[uLID].charLID;

  _head._flag := $f;
  _head._id   := 110;

  _pkg.comID   := combats[comLID].ID;
  _pkg.uLID    := uLID;
  _pkg.WinTeam := WinTeam;

  try
    mStr := TMemoryStream.Create;

    mStr.Write(_head, sizeof(_head));
    mStr.Write(_pkg, sizeof(_pkg));

    // Отправляем пакет
         begin
           TCP.FCon.IterReset;
           while TCP.FCon.IterNext do
           if TCP.FCon.Iterator.PeerAddress = sessions[Chars[CharLID].sID].ip then
           if TCP.FCon.Iterator.LocalPort = sessions[Chars[CharLID].sID].lport then
              begin
                TCP.FCon.Send(mStr.Memory^, mStr.Size, TCP.FCon.Iterator);
                Break;
              end;
         end;
  finally
    mStr.Free;
  end;
end;


end.


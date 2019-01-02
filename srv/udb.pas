unit uDB;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, vVar, mysql57conn, sqldb, vServerLog {, uParser};

type
   TPkg002 = record
    Chars: array [1..4] of TCharHeader;
    fail_code : byte;
  end;

procedure DB_Init;
procedure DB_Free;

function DB_RegAccount(name, email, pass: string) : byte;
function DB_GetAccID(name, pass: string): integer;
function DB_GetCharList(aID : dword): TPkg002;
function DB_CreateNewChar(aID: DWORD; name: string; raceID, sex : byte): byte;
function DB_DeleteChar(_ID : string): byte;
function DB_GetCharData(charLID: DWORD) : byte;
function DB_SetCharData(charLID: DWORD; name :string) : byte;
function DB_SetHPMP(charLID: DWORD) : byte;
function DB_GetCharInv(charLID: DWORD): byte;
function DB_SetCharInv(charLID: DWORD): byte;
function DB_DelItem(charLID, sID: DWORD): byte;
function DB_GetCharVar(charLID : DWORD; vName : string) : DWORD;
function DB_SetCharVar(charLID, vNum : DWORD; vName : string) : byte;
function DB_SetCharTutor(charLID, tutor : DWORD) : byte;

function DB_GetCharCounter(charLID, c_ID : DWORD): DWORD;
function DB_GetCharCounter2(charLID, cLink : DWORD): DWORD;
function DB_SetCharCounter(charLID, c_ID, cValue : DWORD): DWORD;
function DB_StartCharCounter(charLID, c_ID, cType, cLink : DWORD): DWORD;

function DB_SetUsrIP(name, ip : string): byte;
function DB_InventoryCleanUP():byte;

function GetItemProps(str_props : string) : TProps;

implementation

uses uPkgProcessor;
// uses uCharManager;

function PropsToStr(props: TProps): string;
var i: integer;
begin
  result := '';
  for i := 1 to high(props) do
    result := result + IntToStr(props[i]) + ':';
end;

function GetItemProps(str_props : string) : TProps;
var i, k: integer;
    prop, c: string;
begin
  for i := 1 to 25 do
      result[i] := 0;


  //WriteSafeText('Parsing props = ' + str_props, 2 );
  prop := ''; k := 1;
  for i := 1 to length(str_props) do
    begin
      c := copy(str_props, i, 1);
      if c <> ':' then prop := prop + c else
         begin
           if k > 25 then
              begin
                WriteSafeText(' Error in parsing item pars = ' + str_props, 3);
                exit;
              end;
           result[k] := StrToInt(prop);
           inc(k);
           prop := '';
         end;
    end;
end;

function CreateConnection: TSQLConnection;
begin
  result := TMySQL57Connection.Create(nil);
  result.Hostname := 'localhost';
  result.DatabaseName := 'reborn';
  result.UserName := 'root';
  result.Password := 'anagabemy';
  result.CharSet  := 'utf8';
end;

function CreateQuery(): TSQLQuery;
begin
  result := TSQLQuery.Create(nil);
end;

function CreateTransaction(): TSQLTransaction;
begin
  result := TSQLTransaction.Create(nil);
end;

procedure DB_Init;
var i, j, id : integer; s: string; pr: TProps;
begin
TRY
  AConnection := CreateConnection;
  ATransaction := CreateTransaction();
  Query := CreateQuery();
  AConnection.Open;
  if Aconnection.Connected then
     begin
        WriteSafeText('Connecting MySQL server.... Successful connect!', 2) ;
        AConnection.Transaction := ATransaction;
        Query.DataBase := AConnection;
        Query.Transaction := ATransaction;
     end
  else
    WriteSafeText('This is not possible, because if the connection failed, ' +
                  'an exception should be raised, so this code would not ' +
                  'be executed', 3);

 { Char_InitInventory();    }

  WriteSafeText('Getting base rase data... ', 2);
  Query.SQL.Text:= 'SELECT * FROM base_race';
  Query.Open;
  while not Query.Eof do
  begin
    id := Query.FieldByName('rID').AsInteger;
    b_chars[id].header.raceID:= id;
    b_chars[id].bStr:=Query.FieldByName('Str').AsInteger;
    b_chars[id].bAgi:=Query.FieldByName('Agi').AsInteger;
    b_chars[id].bCon:=Query.FieldByName('Con').AsInteger;
    b_chars[id].bInt:=Query.FieldByName('Intel').AsInteger;
    b_chars[id].bHst:=Query.FieldByName('Hst').AsInteger;
    b_chars[id].bSpi:=Query.FieldByName('Spi').AsInteger;
    b_chars[id].bSP :=Query.FieldByName('fSp').AsInteger;
    b_chars[id].bAP:=Query.FieldByName('ap').AsInteger;
    b_chars[id].bHP:=Query.FieldByName('hp').AsInteger;
    b_chars[id].bMP:=Query.FieldByName('mp').AsInteger;
    Query.Next;
  end;

  WriteSafeText('Getting ItemDB... ', 2);
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM item_prototype';
  Query.Open;
  while not Query.Eof do
  begin
    s := '';
    id := Query.FieldByName('ID').AsInteger;
    ItemDB[id].exist:= true;
    ItemDB[id].data.ID := id;
    ItemDB[id].data.name:=Query.FieldByName('name').AsString;
    ItemDB[id].data.rare:=Query.FieldByName('rare').AsInteger;
    ItemDB[id].data.iType:=Query.FieldByName('itype').AsInteger;
    ItemDB[id].data.sub:=Query.FieldByName('sub').AsInteger;
    ItemDB[id].data.iID:=Query.FieldByName('iid').AsInteger;
    ItemDB[id].data.props:=GetItemProps(Query.FieldByName('props').AsString);
    ItemDB[id].data.price:=Query.FieldByName('price').AsInteger;
    Query.Next;
  end;

  WriteSafeText('Getting ObjDB...', 2);
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM loc_objs';
  Query.Open;
  while not Query.EOF do
  begin
    id := Query.FieldByName('ID').AsInteger;
    LocObjs[id].exist:=true;
    LocObjs[id].oType:=Query.FieldByName('otype').AsInteger;
    LocObjs[id].name:=Query.FieldByName('name').AsString;
    LocObjs[id].discr:=Query.FieldByName('discr').AsString;
    LocObjs[id].props:=GetItemProps(Query.FieldByName('props').AsString);
    LocObjs[id].props2:=GetItemProps(Query.FieldByName('props2').AsString);
    LocObjs[id].en:=Query.FieldByName('enabl').AsInteger;
    LocObjs[id].vis:=Query.FieldByName('vis').AsInteger;
    LocObjs[id].pic:=Query.FieldByName('pic').AsInteger;
    Query.Next;
  end;

  WriteSafeText('Getting ObjDialogs...', 2);
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM obj_dialogs';
  Query.Open;
  while not Query.EOF do
  begin
    id := Query.FieldByName('ID').AsInteger;
    ObjDialogs[id].exist:=true;
    ObjDialogs[id].data.dID:=id;
    ObjDialogs[id].data.text:=Query.FieldByName('text').AsString;
    ObjDialogs[id].data.dType:=Query.FieldByName('dType').AsInteger;
    ObjDialogs[id].vName:=Query.FieldByName('vName').AsString;
    ObjDialogs[id].vVal:=Query.FieldByName('vVal').AsInteger;
    ObjDialogs[id].qLink:=Query.FieldByName('qLink').AsInteger;
    ObjDialogs[id].vName2:=Query.FieldByName('vName2').AsString;
    ObjDialogs[id].vVal2:=Query.FieldByName('vVal2').AsInteger;
    ObjDialogs[id].vName3:=Query.FieldByName('vName3').AsString;
    ObjDialogs[id].vVal3:=Query.FieldByName('vVal3').AsInteger;
    ObjDialogs[id].props:=GetItemProps(Query.FieldByName('Props').AsString);
    //WriteSafeText( IntToStr(ObjDialogs[id].props[1].pNum), 2);
    Query.Next;
  end;

  WriteSafeText('Getting QuestDB...', 2);
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM quests';
  Query.Open;
  while not Query.EOF do
  begin
    id := Query.FieldByName('ID').AsInteger;
    QuestDB[id].exist:=true;
    QuestDB[id].name:=Query.FieldByName('name').AsString;
    QuestDB[id].discr:=Query.FieldByName('discr').AsString;
    QuestDB[id].fdiscr:=Query.FieldByName('fdiscr').AsString;
    QuestDB[id].objective:=Query.FieldByName('objctv').AsString;
    QuestDB[id].vName:=Query.FieldByName('vName').AsString;
    QuestDB[id].qType:=Query.FieldByName('qType').AsInteger;
    QuestDB[id].spic:=Query.FieldByName('spic').AsInteger;
    QuestDB[id].smask:=Query.FieldByName('smask').AsInteger;
    QuestDB[id].fpic:=Query.FieldByName('fpic').AsInteger;
    QuestDB[id].fmask:=Query.FieldByName('fmask').AsInteger;
    QuestDB[id].reward:=Query.FieldByName('reward').AsString;
    QuestDB[id].prors := GetItemProps(QuestDB[id].reward);
    QuestDB[id].props2 := GetItemProps(Query.FieldByName('props').AsString);
    Query.Next;
  end;

  WriteSafeText('Getting LootDB...', 2 );
  Query.Close;
  Query.SQL.Text:='SELECT * FROM loot';
  Query.Open;
  while not Query.EOF do
  begin
    id := query.FieldByName('ID').AsInteger;
 {   pr := GetItemProps(Query.FieldByName('loot').AsString);
    LootDB[id].exist:=true;
    LootDB[id].gold:= pr[1].pNum;
    for i := 1 to 12 do
      if pr[i * 2].pNum <> 0 then
         begin
            LootDB[id].LItems[i].exist:=true;
            LootDB[id].LItems[i].chance:=pr[i * 2 + 1].pNum;
       //     WriteSafeText(IntToStr(id) + ' ' + IntToStr(i) + ' ' + IntToStr(LootDB[id].LItems[i].chance));
            LootDB[id].LItems[i].iID:=pr[i * 2].pNum;
         end;     }
    Query.Next;
  end;

  WriteSafeText('Getting LocDB...', 2 );
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM locs';
  Query.Open;
  while not Query.EOF do
  begin
    id := query.FieldByName('id').AsInteger;
    pr := GetItemProps(Query.FieldByName('props').AsString);
    LocDB[id].exist :=true;
    LocDB[id].name:= query.FieldByName('Name').AsString;
    LocDB[id].props := pr;
    pr := GetItemProps(query.FieldByName('links').AsString);
    LocDB[id].links := pr;
    writesafetext(IntToStr(id) + ' ' + (locDB[id].name));
    Query.Next;
  end;

{ WriteSafeText('Getting VendorDB...', 2 );
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM vendors';
  Query.Open;
  while not Query.EOF do
  begin
    id := query.FieldByName('id').AsInteger;

    VendorDB[id].exist:=true;
    VendorDB[id].repair:=query.FieldByName('repair').AsBoolean;
    VendorDB[id].name:=query.FieldByName('name').AsString;

    pr := GetItemProps(Query.FieldByName('goods1').AsString);
    j := 0;
    for i := 1 to 12 do
      if pr[i * 2 - 1].pNum > 0 then
         begin
           inc(j);
           VendorDB[id].goods[j].exist := true;
           VendorDB[id].goods[j].id := pr[i * 2 - 1].pNum;
           VendorDB[id].goods[j].num:= pr[i * 2].pNum;
         end;

    pr := GetItemProps(Query.FieldByName('goods2').AsString);
    for i := 1 to 12 do
      if pr[i * 2 - 1].pNum > 0 then
         begin
           inc(j);
           VendorDB[id].goods[j].exist := true;
           VendorDB[id].goods[j].id := pr[i * 2 - 1].pNum;
           VendorDB[id].goods[j].num:= pr[i * 2].pNum;
         end;

    pr := GetItemProps(Query.FieldByName('goods3').AsString);
    for i := 1 to 12 do
      if pr[i * 2 - 1].pNum > 0 then
         begin
           inc(j);
           VendorDB[id].goods[j].exist := true;
           VendorDB[id].goods[j].id := pr[i * 2 - 1].pNum;
           VendorDB[id].goods[j].num:= pr[i * 2].pNum;
         end;

  //  for i := 1 to high(VendorDB[id].goods) do
  //      WriteSafeText(IntToStr(VendorDB[id].goods[i].id), 1);

    Query.Next;
  end;   }

  WriteSafeText('Getting MobDataDB...', 2 );
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM mobs';
  Query.Open;
  while not Query.EOF do
  begin
    id := query.FieldByName('id').AsInteger;

    MobDataDB[id].exist:=true;
    MobDataDB[id].name:=query.FieldByName('name').AsString;

    pr := GetItemProps(query.FieldByName('stats1').AsString);
    MobDataDB[id].HP:= pr[1];
    MobDataDB[id].MP:= pr[2];
    MobDataDB[id].AP:= pr[3];
    MobDataDB[id].Ini:=pr[4];
    MobDataDB[id].ARM:=pr[5];
    MobDataDB[id].Str:=pr[6];
    MobDataDB[id].Agi:=pr[7];
    MobDataDB[id].Con:=pr[8];
    MobDataDB[id].Hst:= pr[9];
    MobDataDB[id].Int:=pr[10];
    MobDataDB[id].Spi:=pr[11];
    MobDataDB[id].APH:=pr[12];
    MobDataDB[id].DPAP:=pr[13];
    MobDataDB[id].SP:=pr[14];

    pr := GetItemProps(query.FieldByName('stats2').AsString);
    MobDataDB[id].skBody:= pr[1];
    MobDataDB[id].skMH:= pr[2];
    MobDataDB[id].skOH:= pr[3];
    MobDataDB[id].lvl:= pr[4];
    MobDataDB[id].elete:= pr[5];
    MobDataDB[id].sex:=pr[6];
    if pr[7] > 0 then
       MobDataDB[id].race:=pr[7] else MobDataDB[id].race:=0;
    Query.Next;
  end;

  WriteSafeText('Getting ceDB...', 2 );
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM combat_events';
  Query.Open;
  while not Query.EOF do
  begin
    id := query.FieldByName('id').AsInteger;
    ceDB[id].exist:= true;
    //ceDB[id].name:= query.FieldByName('name').AsString;
    // WriteSafeText(query.FieldByName('name').AsString);
    ceDB[id].lvl:= query.FieldByName('lvl').AsInteger;
    ceDB[id].resp:= query.FieldByName('resp').AsInteger;
    pr := GetItemProps(query.FieldByName('mobs').AsString);

    ceDB[id].limit:= pr[1];

    for i := 1 to 4 do
      if pr[i + 1] <> 0 then
         ceDB[id].mobs[i] := pr[i + 1] else ceDB[id].mobs[i] := 0;
    ceDB[id].ceType:=pr[6];
    pr := GetItemProps(query.FieldByName('ally').AsString);
    for i := 1 to 3 do
      if pr[i + 1] <> 0 then
         ceDB[id].ally[i] := pr[i + 1] else ceDB[id].ally[i] := 0;

    ceDB[id].on_win := GetItemProps(query.FieldByName('on_win').AsString);
    ceDB[id].w_trig := GetItemProps(query.FieldByName('w_trig').AsString);
    ceDB[id].c_trig := GetItemProps(query.FieldByName('c_trig').AsString);

    Query.Next;
  end;

  WriteSafeText('Getting PerksDB...', 2 );
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM perks_data';
  Query.Open;
  while not Query.EOF do
  begin
    id := query.FieldByName('id').AsInteger;

    PerksDB[id].exist:= true;
    pr := GetItemProps(query.FieldByName('props').AsString);

    PerksDB[id].sc:= pr[1];
    PerksDB[id].lid:= pr[2];
    PerksDB[id].maxrank:= pr[3];

    for i := 1 to perksDB[id].maxrank do
      begin
        perksDB[id].xyz[i].x := pr[3 + (i - 1) * 3 + 1];
        perksDB[id].xyz[i].y := pr[3 + (i - 1) * 3 + 2];
        perksDB[id].xyz[i].z := pr[3 + (i - 1) * 3 + 3];
      end;

    pr := GetItemProps(query.FieldByName('cost').AsString);

    for i := 1 to perksDB[id].maxrank do
      perksDB[id].cost[i] := pr[i];

    Query.Next;
  end;

  WriteSafeText('DB_Init done.', 2);


 // Query.Close;
except
  on E:Exception do
     WriteSafeText('DB_LOADING ERROR ' + E.ToString, 3);
end;
end;

procedure DB_Free;
begin
try
  Query.Close;
  AConnection.Close;
  Query.Free;
  ATransaction.Free;
  AConnection.Free;
except
  WriteSafeText('DB_ERROR:: DB_FREE', 3);
end;
end;

function DB_RegAccount(name, email, pass: string) : byte;
begin
try
  result := 0;
  WriteSafeText('reg_acc debug ponin 1.1');
  Query.Close;
  Query.SQL.Text:= 'SELECT name FROM users WHERE name = "' + name + '"';
  Query.Open;
  WriteSafeText('reg_acc debug ponin 1.2 ');
  if Query.RecordCount > 0 then
     begin
       WriteSafeText('reg_acc debug ponin 1.3');
       result := 1;
       exit;  // уже есть такая учётка, возвращаем ошибку и выходим
     end else
     begin
       WriteSafeText('reg_acc debug ponin 1.4');
       Query.SQL.Text:='INSERT INTO users (name, email, password) values (:name, :email, :password)';
       Query.Prepare;
       WriteSafeText('reg_acc debug ponin 1.5');
       Query.Params.ParamByName('name').AsString:=name;
       Query.Params.ParamByName('email').AsString:=email;
       Query.Params.ParamByName('password').AsString:=pass;
       Query.ExecSQL;
       WriteSafeText('reg_acc debug ponin 1.6');
       Query.Close;
       Query.SQL.Text:= 'SELECT name FROM users WHERE name = "' + name + '"';
       Query.Open;
       WriteSafeText('reg_acc debug ponin 1.7');
       if Query.RecordCount > 0 then result := 2 else result := 3;
     end;

except
  on E : Exception do
  WriteSafeText(e.message, 3);
end;
end;

function DB_GetAccID(name, pass: string): integer;
var id : integer; p: string;
begin
 try
   // функция должна вернуть ID аккаунта, которое может быть только положительным числом
   // следовательно ошибки обозначаем отрицательными, чтобы не воротить огороды
   result := -1;
   Query.Close;
   Query.SQL.Text:= 'SELECT id, password FROM users WHERE name = "' + name + '"';
   Query.Open;
   if Query.RecordCount = 0 then
      begin
        result := -4;
        exit; //нет такого аккаунта
      end;
   if Query.RecordCount > 1 then
      begin
        result := -2;
        WriteSafeText('Error in DB_GetAccID. Query returns 1+ records. Login aborted', 3);
        exit;
      end else
      begin
        Query.First;
        id := Query.FieldByName('id').AsInteger;
        p  := Query.FieldByName('password').AsString;
        WriteSafeText('Pass ##:' + Pass);
        WriteSafeText('P    ##:' + P);
        if p <> pass then result := -3 else result := id;
      end;
   WriteSafeText('Result ##:' + IntToStr(result));
 except
   on E : Exception do
      WriteSafeText(e.message, 3);
 end;
end;

function DB_GetCharList(aID : dword): TPkg002;
var s: string; i: integer;
begin
  try
    result.fail_code:= 0;
    Query.Close;
    Query.SQL.Text:= 'SELECT id, Name, race, class, level, loc, sex, tutorial FROM Chars WHERE aID = "' + IntToStr(aID) + '"';
    Query.Open;
    result.fail_code:=Query.RecordCount;
    if Query.RecordCount > 4 then
       begin
         WriteSafeText('Error in DB_GetChatList. 4+ records returned', 3 );
         result.fail_code := high(byte);
         exit;          // получили больше 4 записей, сворачиаем лавочку
       end;
    i := 1;
    writesafetext('Char ##:' + IntToStr(Query.RecordCount));
    if Query.RecordCount > 0 then
    while not Query.Eof do
    begin
      result.Chars[i].ID:= Query.FieldByName('ID').AsInteger;
      result.Chars[i].Name:=Query.FieldByName('Name').AsString;
      result.Chars[i].raceID:=Query.FieldByName('race').AsInteger;
      result.Chars[i].classID:=Query.FieldByName('class').AsInteger;
      result.Chars[i].level:=Query.FieldByName('level').AsInteger;
      result.Chars[i].loc:=Query.FieldByName('loc').AsInteger;
      result.Chars[i].tutorial:=Query.FieldByName('tutorial').AsInteger;
      if result.Chars[i].tutorial = 0 then result.Chars[i].tutorial:=1;
      writeln(' ## ', i , ' == ', result.Chars[i].tutorial);
      result.Chars[i].sex:=Query.FieldByName('Sex').AsInteger;
      inc(i);
      Query.Next;
    end;
  except
   on E : Exception do
      WriteSafeText(e.message, 3);
  end;
end;

function DB_CreateNewChar(aID: DWORD; name: string; raceID, sex : byte): byte;
var
  id, sp : integer;
begin
  try
    result := 0;
    if raceID = 1 then sp := 8 else sp := 0;
    Query.Close;
    Query.SQL.Text := 'SELECT id FROM Chars WHERE name = "' + name + '"';
    Query.Open;
    if Query.RecordCount > 0 then
       begin
         result := 1;  // такой персонаж уже есть
         exit;
       end;
    // заносим данные в таблицу
    Query.SQL.Text := 'INSERT INTO Chars (aID, name, race, class, level, loc, sex) VALUES '+
                 '(:iaID, :iN, :iR, :iC, :iLv, :iL, :iS)';
    Query.Prepare;
    Query.Params.ParamByName('iaID').AsInteger:=aID;
    Query.Params.ParamByName('iN').AsString:=Name;
    Query.Params.ParamByName('iR').AsInteger:=raceID;
    Query.Params.ParamByName('iC').AsInteger:=1;
    Query.Params.ParamByName('iLv').AsInteger:=1;
    Query.Params.ParamByName('iL').AsInteger:=1;
    Query.Params.ParamByName('iS').AsInteger:=sex;
    Query.ExecSQL;
    // проверяем результаты
    Query.Close;
    Query.SQL.Text := 'SELECT id FROM Chars WHERE name = "' + name + '"';
    Query.Open;
    if Query.RecordCount > 0 then
       begin
         result := 2;
         id := Query.FieldByName('id').AsInteger;
         Query.Close;
         Query.SQL.Text:='INSERT INTO char_stats (chID, SP) VALUES (' + IntToStr(id) + ', ' + intToStr(sp) + ')';
         Query.Prepare;
         WriteSafeText( Query.SQL.Text );
         Query.ExecSQL;
       //  Query.SQL.Text:='INSERT INTO perks ;
       //  WriteSafeText(query.
       end else result := 3;
  except
   on E : Exception do
      WriteSafeText(e.message, 3);
  end;
end;

function DB_DeleteChar(_id : string): byte;
var id : integer;
begin
  try
    result := 0;
    Query.Close;
    Query.SQL.Text := 'SELECT id FROM Chars WHERE id = "' + _id + '"';
    Query.Open;
    if Query.RecordCount = 0 then
       begin
         result := 1;  // персонажа уже не существует...
         exit;
       end;
    Query.First;
    id := query.FieldByName('id').AsInteger;
    Query.SQL.Text:= 'DELETE FROM Chars WHERE id = "' + IntToStr(id) +'"';
    Query.ExecSQL;
    Query.SQL.Text:= 'DELETE FROM char_stats WHERE chID = "' + IntToStr(id) +'"';
    Query.ExecSQL;
    Query.SQL.Text:= 'DELETE FROM items WHERE chID = "' + IntToStr(id) +'"';
    Query.ExecSQL;
    Query.SQL.Text:= 'DELETE FROM char_vars WHERE chid = "' + IntToStr(id) +'"';
    Query.ExecSQL;
    Query.SQL.Text:= 'DELETE FROM perks WHERE cID = "' + IntToStr(id) +'"';
    Query.ExecSQL;
    Query.Close;
    Query.SQL.Text := 'SELECT id FROM Chars WHERE id = "' + _id + '"';
    Query.Open;
    if Query.RecordCount = 0 then result := 2 else result := 3;
  except
   on E : Exception do
      WriteSafeText(e.message, 3);
  end;
end;

function DB_GetCharData(charLID: DWORD) : byte;
var i, j: integer;
begin
try
  result := 0;
  Query.Close;    // подгружаем данные в список активных чаров
  Query.SQL.Text := 'SELECT * FROM Chars WHERE id = "' + IntToStr(Chars[CharLID].header.ID) + '"' ;
  Query.Open;
  Query.First;
  chars[charLID].header.Name    := Query.FieldByName('Name').AsString;
  Chars[charLID].header.loc     := Query.FieldByName('loc').AsInteger;
  Chars[charLID].header.classID := Query.FieldByName('class').AsInteger;
  Chars[charLID].header.raceID  := Query.FieldByName('race').AsInteger;
  Chars[charLID].header.level   := Query.FieldByName('level').AsInteger;
  Chars[charLID].header.sex     := Query.FieldByName('sex').AsInteger;
  Chars[charLID].header.tutorial:= Query.FieldByName('tutorial').AsInteger;
  Query.Close;
    Query.SQL.Text:= 'SELECT * FROM char_stats WHERE chID = "' + IntToStr(Chars[CharLID].header.ID) + '"' ;
  Query.Open;
  Query.First;
  chars[charLID].Points.pStr := Query.FieldByName('Str').AsInteger;
  chars[charLID].Points.pAgi := Query.FieldByName('Agi').AsInteger;
  chars[charLID].Points.pCon := Query.FieldByName('Con').AsInteger;
  chars[charLID].Points.pHst := Query.FieldByName('Hst').AsInteger;
  chars[charLID].Points.pInt := Query.FieldByName('Intel').AsInteger;
  chars[charLID].Points.pSpi := Query.FieldByName('Spi').AsInteger;

  chars[charLID].Numbers.Exp  := Query.FieldByName('Expa').AsInteger;
  chars[charLID].Numbers.gold := Query.FieldByName('Gold').AsInteger;
  chars[charLID].Numbers.SP   := Query.FieldByName('SP').AsInteger;
  chars[charLID].Numbers.TP   := Query.FieldByName('TP').AsInteger;
  chars[charLID].hpmp.cHP  := Query.FieldByName('curHP').AsInteger;
  chars[charLID].hpmp.cMP  := Query.FieldByName('curMP').AsInteger;

  if chars[charLID].hpmp.cHP < 1 then chars[charLID].hpmp.cHP:= 1;
  if chars[charLID].hpmp.cMP < 1 then chars[charLID].hpmp.cMP:= 1;

  DB_GetCharInv(Chars[CharLID].header.ID);

  Query.Close;
  Query.SQL.Text := 'SELECT * FROM perks WHERE cID = "' + IntToStr(Chars[charLID].header.ID) + '"' ;
  //WriteSafeText( Query.SQL.Text, 2);
  Query.Open;
  if Query.RecordCount = 0 then
      begin
        for i := 0 to 6 do
          for j := 1 to 25 do
            chars[charLID].perks[i][j] := 0;
      end else
      begin
  Query.First;
  chars[charLID].perks[0] := GetItemProps(Query.FieldByName('com').AsString);
  chars[charLID].perks[1] := GetItemProps(Query.FieldByName('def').AsString);
  chars[charLID].perks[2] := GetItemProps(Query.FieldByName('res').AsString);
  chars[charLID].perks[3] := GetItemProps(Query.FieldByName('ele').AsString);
  chars[charLID].perks[4] := GetItemProps(Query.FieldByName('spi').AsString);
  chars[charLID].perks[5] := GetItemProps(Query.FieldByName('sur').AsString);
  chars[charLID].perks[6] := GetItemProps(Query.FieldByName('sub').AsString);

      end;
except
  on E : Exception do
     WriteSafeText(e.message, 3);
end;
end;

function DB_SetCharData(charLID: DWORD; name :string) : byte;
begin
try
  result := 0;
  if not Chars[charLID].exist then Exit;
  Query.SQL.Text:= 'UPDATE Chars SET ' +
                   'level = "' + IntToStr(Chars[charLID].header.level) + '",' +
                   'loc = "' + IntToStr(Chars[charLID].header.loc) + '",' +
                   'class = "' + IntToStr(Chars[charLID].header.classID) + '" ' +
                   'WHERE name = "' + name + '"';
  Query.ExecSQL;   // обновляем данные в корневой таблице персонажа

  Query.SQL.Text:= 'UPDATE char_stats SET ' +
                   'Str = "' + IntToStr(chars[charLID].Points.pStr) + '",' +
                   'Agi = "' + IntToStr(chars[charLID].Points.pAgi) + '",' +
                   'Con = "' + IntToStr(chars[charLID].Points.pCon) + '",' +
                   'Hst = "' + IntToStr(chars[charLID].Points.pHst) + '",' +
                   'Intel = "' + IntToStr(chars[charLID].Points.pInt) + '",' +
                   'Spi = "' + IntToStr(chars[charLID].Points.pSpi) + '",' +
                   'Expa = "' + IntToStr(chars[charLID].Numbers.Exp) + '",' +
                   'Gold = "' + IntToStr(chars[charLID].Numbers.Gold) + '",' +
                   'SP = "' + IntToStr(chars[charLID].Numbers.SP) + '",' +
                   'TP = "' + IntToStr(chars[charLID].Numbers.TP) + '", ' +
                   'curHP = "' + IntToStr(chars[charLID].hpmp.cHP) + '",' +
                   'curMP = "' + IntToStr(chars[charLID].hpmp.cMP) + '" ' +
                   'WHERE chID = "' + IntToStr(Chars[charLID].Header.ID) + '"';
  //WriteSafeText(Query.SQL.Text);
   Query.ExecSQL;   // обновляем данные в таблице статов пероснажа

   Query.Close;
   Query.SQL.Text := 'SELECT * FROM perks WHERE cID = "' + IntToStr(chars[charLID].header.ID) + '"';
   //WriteSafeText( Query.SQL.Text, 2);
   Query.Open;
   if Query.RecordCount = 0 then
      begin
         Query.Close;
         Query.SQL.Text:= 'INSERT INTO perks (cID) VALUES (' + IntToStr(chars[charLID].header.ID) + ')' ;
         // WriteSafeText( Query.SQL.Text, 2);
         Query.ExecSQL;
      end;
   Query.Close;
   Query.SQL.Text:= 'UPDATE perks SET ' +
                   'com = "' + PropsToStr(chars[charLID].perks[0]) + '",' +
                   'def = "' + PropsToStr(chars[charLID].perks[1]) + '",' +
                   'res = "' + PropsToStr(chars[charLID].perks[2]) + '",' +
                   'ele = "' + PropsToStr(chars[charLID].perks[3]) + '",' +
                   'spi = "' + PropsToStr(chars[charLID].perks[4]) + '", ' +
                   'sur = "' + PropsToStr(chars[charLID].perks[5]) + '",' +
                   'sub = "' + PropsToStr(chars[charLID].perks[6]) + '" ' +
                   'WHERE cID = "' + IntToStr(Chars[charLID].header.ID) + '"';;
   //WriteSafeText( Query.SQL.Text, 2);
   Query.ExecSQL;
except
  on E : Exception do
     WriteSafeText(e.message, 3);
end;
end;

function DB_SetHPMP(charLID: DWORD) : byte;
begin
try
  result := 0;
  if not Chars[charLID].exist then Exit;
  // обновляем данные в корневой таблице персонажа

  Query.SQL.Text:= 'UPDATE char_stats SET ' +
                   'curHP = "' + IntToStr(chars[charLID].hpmp.cHP) + '",' +
                   'curMP = "' + IntToStr(chars[charLID].hpmp.cMP) + '" ' +
                   'WHERE chID = "' + IntToStr(Chars[charLID].header.ID) + '"';
  //WriteSafeText(Query.SQL.Text);
  Query.ExecSQL;   // обновляем данные в таблице статов пероснажа
except
  on E : Exception do
     WriteSafeText(e.message, 3);
end;
end;

function DB_GetCharInv(charLID: DWORD): byte;
var chID, sID : integer;
begin
try
  result := high(byte);
  for chID := 1 to 130 do
      begin
        chars[charLID].Inventory[chID].gID:=0; // зачищаем текущий инвентарь
        chars[charLID].Inventory[chID].cDur:=0;
        chars[charLID].Inventory[chID].iID:=0;
      end;

  chID := chars[charLID].header.ID;
  Query.Close;
  Query.SQL.Text:= 'SELECT * FROM items WHERE chID = "' + IntToStr(chID) + '"';
  Query.Open;
  if Query.RecordCount > 0 then
     while not Query.EOF do               // выгружаем актуальное состояние инвентаря
     begin
       sID := Query.FieldByName('islot').AsInteger;
       chars[charLID].Inventory[sID].gID:= Query.FieldByName('ID').AsInteger;
       chars[charLID].Inventory[sID].iID:= Query.FieldByName('iID').AsInteger;
       chars[charLID].Inventory[sID].cDur:= Query.FieldByName('cdur').AsInteger;
       Query.Next;
     end;
except
  on E : Exception do
     WriteSafeText(e.message, 3);
end;
end;

function DB_SetCharInv(charLID : DWORD): byte;
var i : integer;
begin
try
  result := high(byte);

  for i := 1 to 130 do
  if chars[charLID].Inventory[i].gID <> 0 then
    begin
      Query.Close;
      Query.SQL.Text := 'SELECT iID FROM items WHERE ' +
                        'ID = "' + IntToStr(chars[charLID].Inventory[i].gID) + '"';
      Query.Open;
      // если предмет такой есть, то вписываем актуальные параметры, если нет, то записываем в БД
      if Query.RecordCount > 0 then
         begin
           Query.SQL.Text:= 'UPDATE items SET islot = "' + inttostr(i) + '", ' +
                            'cdur = "' + inttostr(chars[charLID].Inventory[i].cDur) + '",' +
                            'chID = "' + intToStr(chars[charLID].header.ID) + '" WHERE ID = "' +
                            intToStr(chars[charLID].Inventory[i].gID) + '"';
         //  WriteSafeText(query.SQL.Text);
           Query.ExecSQL;
         end else
         begin
           Query.SQL.Text:= 'INSERT INTO items (iID, chID, islot, cdur, aprops) VALUES (' +
                             intToStr(chars[charLID].Inventory[i].iID) + ', ' +
                             intToStr(chars[charLID].header.ID) + ', ' +
                             intToStr(i) + ', ' +
                             intToStr(chars[charLID].Inventory[i].cDur) + ', ' +
                             '"")';
         //  WriteSafeText(query.SQL.Text);
           Query.ExecSQL;
         end;
    end;

except
  on E : Exception do
     WriteSafeText(e.message, 3);
 end;
end;

function DB_DelItem(charLID, sID: DWORD): byte;
begin
  Query.Close;
  Query.SQL.Text:= 'DELETE FROM items WHERE chID = "' + IntToStr(chars[charLID].header.ID) +
                   '" AND islot = "' + IntToStr(sID) + '"';
  Query.ExecSQL;

  DB_GetCharInv(charLID);
end;

function DB_GetCharVar(charLID : DWORD; vName: string): DWORD;
var i : integer;
begin
try
  result := 0;
  Query.Close;
  Query.SQL.Text:= 'SELECT vnum FROM char_vars WHERE (chid = "' +
                   IntToStr(chars[charLID].header.ID) + '") and (vname = "' + vName + '")';
  Query.Open;
  if Query.RecordCount > 0 then
     begin
       result := Query.FieldByName('vnum').AsInteger;
       writeln(vName, '=' , result);
     end;
except
  on E : Exception do
     WriteSafeText(e.message, 3);
 end;
end;

function DB_SetCharVar(charLID, vNum : DWORD; vName: string): byte;
var i : integer;
begin
try
  result := high(byte);

  Query.Close;
  Query.SQL.Text:= 'SELECT vnum FROM char_vars WHERE (chid="' +
                   IntToStr(chars[charLID].header.ID) + '") and (vname="' + vName + '")';
  Query.Open;
  if Query.RecordCount > 0 then
     begin
       Query.SQL.Text:= 'UPDATE char_vars SET vnum="' + IntToStr(vNum) + '"' +
                        ' WHERE (chid="' + IntToStr(chars[charLID].header.ID) + '") and ' +
                        '(vname="' + vName + '")';
       Query.ExecSQL;
     end else
     begin
       Query.SQL.Text:= 'INSERT INTO char_vars (chid, vname, vnum) VALUES (' +
                        IntToStr(chars[charLID].header.ID) + ', "' +
                        vName + '", ' +
                        IntToStr(vNum) + ')';
       Query.ExecSQL;
     end;
except
  on E : Exception do
     WriteSafeText(e.message, 3);
 end;
end;

function DB_SetCharTutor(charLID, tutor : DWORD): byte;
var i : integer;
begin
try
  result := high(byte);

  Query.Close;
  Query.SQL.Text:= 'SELECT tutorial FROM Chars WHERE (id="' +
                   IntToStr(chars[charLID].header.ID) + '")';
  Query.Open;
  if Query.RecordCount > 0 then
     begin
       Query.SQL.Text:= 'UPDATE Chars SET tutorial="' + IntToStr(tutor) + '"' +
                        ' WHERE (id="' + IntToStr(chars[charLID].header.ID) + '")';
       Query.ExecSQL;
       Chars[CharLID].header.tutorial := tutor;
     end;
except
  on E : Exception do
     WriteSafeText(e.message, 3);
 end;
end;

function DB_GetCharCounter(charLID, c_ID : DWORD): DWORD;
begin
  try
    Query.Close;
    Query.SQL.Text:= 'SELECT * FROM char_counters WHERE (chID = "' + IntToStr(Chars[charLID].header.ID) +
                     '" AND cID = "' + IntToStr(c_ID) + '")';
    Query.Open;
    if Query.RecordCount = 1 then
       begin
         Query.First;
         Result := Query.FieldByName('cValue').AsInteger;
       end else result := high(dword);
  except
    on E : Exception do
       WriteSafeText(e.message, 3);
  end;
end;

function DB_GetCharCounter2(charLID, cLink : DWORD): DWORD;
begin
  try
    Query.Close;
    Query.SQL.Text:= 'SELECT * FROM char_counters WHERE (chID = "' + IntToStr(Chars[charLID].header.ID) +
                     '" AND cLink = "' + IntToStr(cLink) + '")';
    Query.Open;
    if Query.RecordCount = 1 then
       begin
         Query.First;
           Result := Query.FieldByName('cID').AsInteger;
       end else result := high(dword);
  except
    on E : Exception do
       WriteSafeText(e.message, 3);
  end;
end;

function DB_StartCharCounter(charLID, c_ID, cType, cLink : DWORD): DWORD;
begin
  try
    Query.Close;
    Query.SQL.Text:= 'SELECT * FROM char_counters WHERE (chID = "' + IntToStr(Chars[charLID].header.ID) +
                     '" AND cID = "' + IntToStr(c_ID) + '")';
    Query.Open;
    if Query.RecordCount > 0 then exit else
       begin
         Query.Close;
         Query.SQL.Text:= 'INSERT INTO char_counters (chID, cID, cType, cLink, cValue) VALUES ('+
                          IntToStr(chars[charLID].header.ID) + ', ' +
                          IntToStr(c_ID) + ', ' +
                          IntToStr(cType) + ', ' +
                          IntToStr(cLink) + ', ' +
                          IntToStr(0) + ')';
         WriteSafeText(query.SQL.Text);
         Query.ExecSQL;
       end;
  except
    on E : Exception do
       WriteSafeText(e.message, 3);
  end;
end;

function DB_SetCharCounter(charLID, c_ID, cValue : DWORD): DWORD;
begin
  try
    Query.Close;
    Query.SQL.Text:= 'SELECT * FROM char_counters WHERE (chID = "' + IntToStr(Chars[charLID].header.ID) +
                     '" AND cID = "' + IntToStr(c_ID) + '")';
    Query.Open;
    if Query.RecordCount = 0 then exit else
       begin
         //WriteSafeText('d123453876975423578654');
         Query.Close;
         Query.SQL.Text:= 'UPDATE char_counters SET cValue = "' + IntToStr(cValue) + '" WHERE (chID = "' + IntToStr(Chars[charLID].header.ID) +
                     '" AND cID = "' + IntToStr(c_ID) + '")';

         Query.ExecSQL;
       end;
  except
    on E : Exception do
       WriteSafeText(e.message, 3);
  end;
end;

function DB_SetUsrIP(name, ip : string): byte;
begin
try
  result := 0;
  Query.SQL.Text:= 'UPDATE users SET IP = "' + ip + '" WHERE name = "' + name + '"';
  Query.ExecSQL;
except
  on E : Exception do
     WriteSafeText(e.message, 3);
 end;
end;

function DB_InventoryCleanUP():byte;
begin
  Query.Close;
  Query.SQL.Text:= 'DELETE FROM items WHERE iID = "0"';
  Query.ExecSQL;
end;

end.


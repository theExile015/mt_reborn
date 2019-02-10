unit vVar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, syncobjs, mysql50conn, sqldb;

type
  TGameSession = record
    exist : boolean;
    ip    : string;
    lport : word;
    aID, charLID : dword;
  end;

  TXYZ = record
    x, y, z: integer;
  end;

  TPerkData = record
    exist : boolean;
    sc, lid, maxrank : byte;
    xyz : array [1..5] of TXYZ;
    cost: array [1..5] of byte;
  end;

  TCharHeader = record
    ID                    : DWORD;
    Name                  : string[20];
    classID, raceID, avID : byte;
    level, sex, destiny   : byte;
    tutorial              : byte;
    loc                   : word;
  end;

  TCharHPMP = record
    cHP, cMP, mHP, mMP, cAP, mAP : DWORD;
  end;

  TCharStats = record
    Str, Agi, Con, Hst, Int, Spi       : DWORD;
    Hit, Crit, Block                   : DWORD;
    MPReg, HPReg, BlValue, Resist      : DWORD;
    Armor, Ini, SPD                    : DWORD;
    APH, DMG                           : DWORD;
  end;

  TCharPoints = record
    pStr, pAgi, pCon, pHst, pInt, pSpi : DWORD;
  end;

  TCharNumbers = record
    Clan, Party, gold            : DWORD;
    Exp, SP, TP                  : DWORD;
  end;

  TInvItem = record
    iID : DWORD;
    gID : DWORD;
    cDur: DWORD;
    sub : DWORD;
  end;

  TProps = array [1..25] of Integer;
  TPerks = array [0..6] of TProps;

  TInventory = array [1..130] of TInvItem;

  TCharacter = record
    exist, in_combat, in_trvl    : boolean;
    charLID, sID                 : dword;
    header                       : TCharHeader;
    hpmp                         : TCharHPMP;
    Stats                        : TCharStats;
    Points                       : TCharPoints;
    Numbers                      : TCharNumbers;
    in_global_chat               : boolean;
    iMP5, iHP5                   : DWORD;
    bStr, bAgi, bCon, bHst, bInt, bSpi      : DWORD;
    bHP , bAP , bMP, bSP                    : DWORD;
    iStr, iAgi, iCon, iHst, iInt, iSpi      : DWORD;
    iHit, iCrit, iBlock, iAP                : DWORD;
    iMPReg, iHPReg, iBlValue, iResist       : DWORD;
    iArmor, iIni, iSPD                      : DWORD;
    Inventory                               : TInventory;
    trvMin, trvSec, trvTime, trvDest : word;
    // auras : array [1..16] of TAura; }
    perks : TPerks;
  end;

  TItemData = record
    rare       : byte;
    iType, sub : byte;
    ID         : word;
    name       : string[50];
    iID        : word;
    props      : TProps;
    price      : integer;
  end;

  TItem = record
    exist              : boolean;
    data               : TItemData;
  end;

  TChatMember = record
    exist : boolean;
    Nick  : string[50];
    charID: word;
    level : byte;
    klass : byte;
    clan  : word;
  end;

  TLocObj = record
    exist : boolean;
    oType, en, vis, pic : dword;
    props, props2 : TProps;
    name  : string[30];
    discr : string[200];
  end;

  TLocation = record
    exist : boolean;
    name  : string;
    links : TProps;
    props : TProps;
  end;

  TLocData = record
    id        : word;
    name      : string[50];
    x, y, pic : word;
    links     : TProps;
  end;

  TLocObjData = record
    x, y, w, h : integer;
    cType, oID, gID, tID : word;
    enabled, animation   : word;
    name : string[30];
  end;

  TChatMembersList = array [1..30] of TChatMember;

  TDialogData = record
    dID   : dword;
    dType : byte;
    text  : string[60];
  end;

  TObjDialog = record
    exist : boolean;
    data  : TDialogData;
    vName, vName2, vName3 : string;
    vVal, vVal2, vVal3, qLink : DWORD;
    props : TProps;
  end;

  TQuest = record
    exist : boolean;
    name, discr, objective, fdiscr, reward : string;
    prors, props2 : TProps;
    spic, smask, fpic, fmask : DWORD;
    vName : string;
    qType : DWORD;
  end;

  TMPoint = record
    x, y : byte;
  end;

  TCell = record
    cType : integer;
    Step: Integer;
    Parent: TMPoint;
  end;

  TAura = record
    exist, _st : boolean;
    id    : word;
    stacks: word;
    sub   : byte;
    left  : dword;
  end;

  TPkgAura = array [1..16] of TAura;

  TUnitData = record
    cHP, cMP, cAP, mHP, mMP, mAP : integer;
    pos     : TMPoint;
    Direct  : byte;
    flag : boolean;
  end;

  TUnitVisualData = record
    sex, Race, lvl : byte;
    name : string[40];
    skinMH, skinOH, skinArm : byte;
    flag : boolean;
  end;

  TUnitPrivateData = record
    rage : byte;
    flag : boolean;
  end;

  TUnitHeader = record
    exist   : boolean;
    Name    : string[40];
    uType   : byte;
    uTeam   : byte;
    uLID    : word;
  end;

  TUnit = record
    exist, alive, visible : boolean;
    uLID                  : word;
    charLID, uID          : DWORD;
    uType, uTeam          : byte;

    Data                  : TUnitData;
    VData                 : TUnitVisualData;
    PData                 : TUnitPrivateData;

    range                 : byte;
    minD, maxD, armor     : word;
    Ini, APH, bVal, spi   : word;
    str, spow             : word;
    sDist                 : integer;

    ATB                   : integer;

    tar_pos               : TMPoint;

    rounds_in, aiFlag     : word;
    turn                  : boolean;
    auras                 : array [1..16] of TAura;
  end;

  TAI = record
    build_turn   : boolean;
    attempt      : integer;
    delay, sAP   : word;
    locUID       : byte;
  end;

  TCombatEvent = record
    exist      : boolean;
    ID, comLID : DWORD;      // глобальный и локальный ИД
    Units      : array [0..20] of TUnit;
    ceUID      : word; // отличительный параметр (ИД мобов для (1))
    ceType     : byte; // тип боя (1 - с мобами
    pLimit     : byte; // Лимит игроков в битве

    ceRound    : word; // текущий раунд
    ATBTime    : byte; // АТБ "время"
    uTurn      : byte; // чей ход
    tsSec,tsMin: word; // время когда был последний пересчёт АТБ
    NextTurn,
    NextTurnATB: integer;  // служебные переменные для определения следующего хода
    xpPool     : DWORD;    // пул опыта

    On_Recount : boolean;  // делаем пересчёт ?

    AI         : TAI;      // ИИ

    MapMatrix  : array [0..20, 0..20] of TCell;
    Way        : Array Of TMPoint;
  end;

  TMob = record
    exist : boolean;
    name  : string;
    HP, MP, AP, Ini, lvl, elete : Word;
    Str, Agi, Con, Hst, Int, Spi : word;
    DPAP, APH, ARM, SP : Word;
    skBody, skMH, skOH, sex, race : byte;
  end;

  TCE = record
    exist : boolean;
    name  : utf8string;
    lvl, limit   : byte;
    ceType: byte;
    mobs  : array [1..4] of byte;
    ally  : array [1..3] of byte;
    on_win, w_trig, c_trig: TProps;
    resp  : word;
  end;

  TVictim = record
    result : byte;
    uLID   : dword;
    dmg    : dword;
    deadly : dword;
    hp_left: dword;
  end;

  TLTItem = record
    exist : boolean;
    group : byte;
    iID, chance : word;
  end;

  TLTCache = record
    iID, min, max : word;
  end;

  TLootTable = record
    exist : boolean;
    gold  : word;
    LItems: array [1..12] of TLTItem;
  end;

  TGood = record
    exist   : boolean;
    id, num : dword;
    hh, mm, ss, timer : word;
  end;

  TVendor = record
    exist : boolean;
    name  : string;
    repair: boolean;
    goods : array [1..20] of TGood;
  end;

  TATBItem = record
    ID  : integer;
    ini : integer;
    atb : integer;
  end;


Var
  CS : TCriticalSection;

  AConnection  : TSQLConnection;
  ATransaction : TSQLTransaction;
  Query        : TSQLQuery;


  exp_cap : array [1..16] of integer = ( 240, 270, 600, 990, 1440, 1950, 2520,
                                         3150, 3840, 4590, 5400, 6270, 7200,
                                         8190, 9240, 100500 );
  exp_mob : array [1..16] of integer = (40, 45, 50, 55, 60, 65, 70, 75, 80, 85,
                                        90, 95, 100, 105, 110, 115);
  base_hp : array [1..15] of integer = (56, 63, 71, 80, 90, 101, 113, 126, 140,
                                        155, 171, 188, 206, 225, 245);
  base_mp : array [1..15] of integer = (28, 32, 37, 43, 50, 58, 67, 77, 88, 100,
                                        113, 127, 142, 158, 175);

  lpMin, lpSec : word;
  cm_total     : DWORD;

  sessions  : array [0..127] of TGameSession; // сессии
  chars     : array [0..127] of TCharacter;   // данные о чарах
  combats   : array [0..255] of TCombatEvent;

  b_chars   : array [1..25] of TCharacter;    // базовые чары
  ItemDB    : array [1..1000] of TItem;       // База предметов
  LocObjs   : array [1..1000] of TLocObj;
  PerksDB   : array [1..100] of TPerkData;
  LocDB     : array [1..50] of TLocation;
  ObjDialogs: array [1..1000] of TObjDialog;
  QuestDB   : array [1..1000] of TQuest;
  MobDataDB : array [1..100] of TMob;
  ceDB      : array [1..100] of TCE;
  LootDB    : array [1..50] of TLootTable;
  VendorDB  : array [1..50] of TVendor;

implementation

end.


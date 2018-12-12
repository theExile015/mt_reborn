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
    name  : string;
    discr : string;
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

  TChatMembersList = array [1..30] of TChatMember;

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

  sessions : array [0..127] of TGameSession; // сессии
  chars    : array [0..127] of TCharacter;   // данные о чарах
  b_chars  : array [1..25] of TCharacter;    // базовые чары
  ItemDB   : array [1..1000] of TItem;       // База предметов
  LocObjs  : array [1..1000] of TLocObj;
  PerksDB  : array [1..100] of TPerkData;
  LocDB    : array [1..50] of TLocation;

implementation

end.


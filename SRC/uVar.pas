unit uVar;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  zglHeader,
  zglGUI;

const
  RE_VER   = 'v.0.0.1';                        // версия клиента
  dirRes   = 'Data\';                          // путь к ресурсам
  dirUI    = 'Data\UI\';                       // путь к элементам интерфейса
  dirLocal = 'Locals\';                        // путь к локализациям
  dirSys   = 'Data\Sys\';                      // путь к системному
  dirChars = 'Data\Chars\';                    // путь к файлам графики персонажей

type
  // тип "сцены"
  TGameStatus = (gsMMenu, gsCharSelect, gsLoad, gsCLoad, gsLLoad, gsPreGame, gsGame);
  // состояние подключение
  TConnectionStatus = (csDisc, csOnDisc, csConcting, csTry, csConctd, csAuth, csChList);
  // состояние внутри игры
  TInGameStatus = (igsNone, igsInv, igsChar, igsNPC, igsQLog, igsMap, igsSBook);
  //
  TInGameAction = (igaLoc, igaCombat, igaTravel);
  // in combat mode
  TInCombatMode = (icmNone, icmRange, icmSpell, icmRotate);

  // пакет данных
  TPackage = record
    pkID     : word;
    pkVars   : array [0..127] of string;
  end;

  TMPoint = record
    x, y : byte;
  end;

  TCell = packed record
    cType  : integer;
    Step   : Integer;
    Parent : TMPoint;
  end;

  TSpell = record
    exist, req, proc : boolean;
    school : byte;
    sType  : byte;
    ID     : word;
    name, bdiscr, discr, hkey : UTF8String;
    iID    : word;
    CD, MP_cost, AP_Cost, range, x, y, z: integer;
  end;

  TXYZ = record
    X, Y, Z : WORD;
  end;

  TSkill = record
    exist, enabled : boolean;
    school: byte;
    dist, ang  : integer;
    iList, iID : word;
    omo : boolean;
    xyz : array [1..5] of TXYZ;
    rank, maxrank : byte;
    costs: array [1..5] of byte
  end;

  TTexManObj = record
    exist : boolean;
    tex   : zglPTexture;
    name  : utf8string;
    hh, mm: word;
  end;

  TTexListObj = record
    exist      : boolean;
    name, path : utf8string;
    w, h       : integer;
  end;

  TDDData = record
    ddSubType : byte;
    contain   : DWORD;
    dur       : word;
  end;

  TDragAndDropObj = record
      exist, visible     : boolean;
      ddType    : byte;         // 1 - предмет, 2 - абилка, 3 - чуз ван
      x, y      : single;
      omo       : boolean;
      selected  : boolean;
      data      : TDDData;
    end;



    // кнопка
    TMyGuiButton = record
      exist, visible, enabled : boolean;
      texID   : integer;
      Caption : utf8string;
      rect    : zglTRect;
      OMO, OMD: boolean;                  // OnMouseOver, OnMouseDown
    end;

    TMyImage = packed record
      exist, visible : boolean;
      iType : integer;
      texID : utf8string;
      maskID: integer;
      rect  : zglTRect;
      omo   : boolean;
    end;

    TMyGUIFormPack = packed record
      brd, crn  : zglPTexture;
      w, h, c   : single;
      dy, dy2   : single;
      bgr_color : longword;
    end;

    TDialogData = record
      dID : dword;
      dType : byte;
      text  : string[60];
    end;

    TMyDialog = packed record
      exist : boolean;
      data  : TDialogData;
      dy    : integer;
      omo   : boolean;
    end;

    TMyProgressBar = packed record
      exist, visible : boolean;
      rect     : zglTRect;
      cProg, mProg : single;
      text     : utf8string;
      color    : longword;
    end;

    TMyGuiText = record
      exist, visible : boolean;
      color : longword;
      Text : string;
      OMO: boolean;
      center : byte;
      rect : zglTRect;
    end;

    TMyGuiLine = record
      exist         : boolean;
      x1, x2, y1, y2: single;
      color         : DWORD;
      alpha         : byte;
    end;

    // форма
    TMyGuiWindow = record
      exist, visible : boolean;
      Name : utf8string;
      flag : byte;
      rect : zglTRect;
      fType: integer;
      btns : array [1..16]  of TMyGuiButton;
      lines: array [1..20]  of TMyGuiLine;
      texts: array [1..45]  of TMyGuiText;
      imgs : array [1..10]  of TMyImage;
      dnds : array [1..100] of TDragAndDropObj;
      dlgs : array [1..25]  of TMyDialog;
      pbs  : array [1..10]  of TMyProgressBar;
    end;

  TProps = array [1..25] of Integer;
  TPerks = array [0..6] of TProps;

  TPUMElement = record
    exist : boolean;
    enable: boolean;
    Text  : UTF8String;
    rect  : zglTRect;
    omo   : boolean;
    action: byte;
  end;

  TPopUpMenu = record
    exist    : boolean;
    eTime    : longword;
    mType    : byte;
    elements : array [0..9] of TPUMElement;
    rect     : zglTRect;
    sender   : UTF8String;
    sID, wID : longword;
  end;

  TCharTexPack = record
    idle : array [0..7] of zglPTexture;
    run  : array [0..7] of zglPTexture;
    act  : array [0..7] of zglPTexture;
    hited: array [0..7] of zglPTexture;
    die  : array [0..7] of zglPTexture;
  end;

  TCharPack = record
    exist : boolean;
    body  : array [0..5] of zglPTexture;
    head  : array [0..5] of zglPTexture;
    MH    : array [0..5] of zglPTexture;
    OH    : array [0..5] of zglPTexture;
  end;

  // игровой персонаж
  TCharHeader = record
    ID                   : dword;        // ID персонажа (глобальный)
    Name                 : String[20];  // Имя
    classID, raceID, avID: byte;       // класс, раса, аватар
    level, sex, destiny  : byte;      // уровень, пол, предназначение
    tutorial             : byte;     // стадия обучения (не то чтобы оно очень нужно в заголовке...)
    loc                  : word;    // локация
  end;

  TCharHPMP = record
    cHP, cMP, mHP, mMP, cAP, mAP: DWORD;
  end;

  TCharNumbers = record
    Clan, Party, gold  : DWORD;
    Exp, SP, TP        : DWORD;
  end;

  TInvItem = record
    iID : DWORD;
    gID : DWORD;
    cDur: DWORD;
    sub : DWORD;
  end;

  TInventory = array [1..130] of TInvItem;

  TCharStats = record
    Str, Agi, Con, Hst, Int, Spi  : DWORD;
    Hit, Crit, Block              : DWORD;
    MPReg, HPReg, BlValue, Resist : DWORD;
    Armor, Ini, SPD               : DWORD;
    APH, DMG                      : DWORD;
  end;

  TGameChar = record
    header          : TCharHeader;
    hpmp            : TCharHPMP;
    Stats           : TCharStats;
    Numbers         : TCharNumbers;
    Inv             : TInventory;
  end;

  // тайл карьы
  TTile = record
    index: integer;
  end;

  // вся карта
  TTileMap = record
    tile: array [0..high(word)] of TTile;
  end;

  TChatMember = record
    exist    : boolean;
    Nick     : string[50];
    charID   : word;
    level    : byte;
    klass    : byte;
    Clan     : WORD;
  end;

  TChatMembersList = array [1..30] of TChatMember;

  TLexeme = record                  // Формат {ТИП ССЫЛКИ:ПАРАМ1:ПАРАМ2:ПАРАМ3:ТЕКСТ}
    raw       : UTF8String;         // изначальный текст
    lType     : byte;               // 0 - текст, 1 - ссылка на предмет, 2 - ссылка на спелл
    ToPrint   : UTF8String;         // то, что будет выведено на экран
    par1, par2, par3 : integer;
    rect      : zglTRect;           // прямоугольник для отрисовки и детекта в чате
    omo       : boolean;
  end;

  TChatMessage = record             // просто строка не подойдёт, т.к. необходима
    exist : boolean;                // функция парсинга строки на лексеммы.
    raw   : UTF8String;             // лучше системно их ограничить. скажем. 4мя.
    lexems: array [0..3] of TLexeme;
    sender: UTF8String;
    sendID: word;
    sRect : zglTRect;
    vis   : boolean;
    omo   : boolean;
  end;

  TChatTab = record
    exist      : boolean;
    Name       : string;
    chID       : word;
    nMem, nMsg : word;
    Members    : TChatMembersList;
    msgs       : array [0..63] of TChatMessage;
    newmsg     : boolean;
  end;

  TChatColorPack = record
    bgr     : Longword;
    regular : longword;
    weak    : longword;
    normal  : longword;
  end;

  TLocData = record
    id        : word;
    name      : string[50];
    x, y, pic : word;
    links     : TProps;
  end;

  TLoc = record
    exist, request : boolean;
    data  : TLocData;
  end;

  TLocObjData = record
    x, y, w, h : integer;
    cType, oID, gID, tID : word;
    enabled, animation : word;
    name : string[30];
  end;

  TLocObject = record                     // объект на карте локации
    exist, anim, visible : boolean;                // существуем ли?
    request              : boolean;
    Data                 : TLocObjData;
    cCircle              : zglTCircle;                  // радиус объекта
    MouseOver            : boolean;                  // мышка над объектом?
    a_fr, c_fr           : integer;
    Descr                : string;
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
    exist,
    req,
    proc       : boolean;
    data       : TItemData;
  end;

  TAura = record
     exist, _st : boolean;
     id         : word;
     stacks     : word;
     sub        : byte;
     left       : dword;
  end;

  TPkgAura = array[1..16] of TAura;

  TCombatText = record
    exist : boolean;
    color : longword;
    text  : utf8string;
    x, y  : single;
    timer, spID : word;
  end;

  TUnitHeader = record
    exist    : boolean;
    Name     : string[40];
    uType    : byte;
    uTeam    : byte;
    uLID     : word;
  end;

  TUnitData = record
    cHP, cMP, cAP, mHP, mMP, mAP : integer;
    pos      : TMPoint;
    Direct   : byte;             // направление взгляда
    flag     : boolean;
  end;

  TUnitVisualData = record
    sex, Race, lvl : byte;
    name: string[40];
    skinMH, skinOH, skinArm : byte;
    flag : boolean;
  end;

  TUnit = record
    exist    : boolean;
    alive, visible, complex : boolean;
    turn     : boolean;             // ход
    in_act   : boolean;             // идёт анимация/действие
    Way      : array of TMPoint;
    WayPos, WayProg   : integer;
    TargetPos, fTargetPos: TMPoint;
    NextPos  : TMPoint;
    uType    : word;
    team     : byte;
    uID, uLID: longword;
    name     : UTF8String;
    data     : tUnitData;
    VData    : TUnitVisualData;
    Rage     : longword;
    to_kill  : boolean;   // удалить на следующем цикле
    ani_frame, ani_delay, ani, ani_key : word;
    ani_bkwrd: boolean;
    auras    : array [1..16] of TAura;
  end;

  TWhoItem  = record
    id   : word;
    name : string[50];
  end;

  TVictim = record
    result : byte;
    uLID   : dword;
    dmg    : dword;
    die    : dword;
    hp_left: dword;
  end;

  TSpFx = record
     exist : boolean;
     id    : byte;
     x, y  : single;
     sx, sy, tx, ty: single;
     speed : single;
  end;

  TAuraData = record
    Name, Descr, icon : String;
    color             : DWORD;
  end;

  TGood = record
    exist  : boolean;
    id, num: dword;
    hh, mm, ss, timer : word;
  end;

  TATBItem = record
    ID  : integer;
    ini : integer;
    atb : integer;
  end;

  TATBGItem = record
    x, y, w, h : integer;
    omo        : boolean;
    id         : integer;
  end;

  TATB_Data = array [0..20] of TATBItem;

var
  // CORE VARS
  GUI            : zglTGui;                   // ГУИ
  gSkin          : zglTGuiSkin;               // скин ГУЯ

  scr_w, scr_h   : longword;                  // ширина и высота экрана
  ScaleXY        : single  ;                  // скалирование изображения (возможно не пригодится)
  f_scr          : boolean ;                  // фулскрин
  oMX, oMY       : single  ;                  // старая позиция курсора
  fCam_X, fCam_Y : single;                    // целевая позиция камеры

  texZero        : zglPTexture;
  tex_man        : array [1..2000] of TTexManObj;
  tex_list       : array [1..2000] of TTexListObj;

  gs             : TGameStatus = gsMMenu;     // переключатель сцеy
  igs            : TInGameStatus = igsNone;   // переключатель состояний в игре
  cns            : TConnectionStatus = csDisc;// состояние подключения к серверу
  iga            : TInGameAction = igaLoc;    // локация/комбат/добыча итд.
  icm            : TInCombatMode = icmNone;

  DelCharMode, CreateCharMode, DestinyMode  : boolean;   // Режимы в меню персонажа

  con_visible           : boolean;                // Параметры
  con_string, con_log   : string;                 // консоли

  l_ms                  : boolean = false;        // статус загрузки карты
  a_p                   : integer;                // char select vars
  sc_ani, tut_timer     : integer;
  gSI, dSI              : byte   ;                // индекс персонажа для удаления
  lProgress, lVProgress : integer;                // состояние загрузки ресурсов
  In_Request            : boolean;                // В процессе запроса

  wholist : array [1..1000] of TWhoItem;

  wait_for_05           : boolean;
  wait_for_29           : boolean;
  wait_for_103          : boolean;


  // ZEN VARS
  zglCam1, zglCam2 : zglTCamera2D;                    // камера
  fntMain, fntMain2, fntChat, fntCombat: zglPFont;    // основной шрифт

  video     : zglPVideoStream;                        // видео
  videoSeek : Boolean;                                // vars

  tex_IBtn     : array [1..25] of  zglPTexture;       // кнопки-картинки
  tex_btn      : zglPTexture;                         // текстура кнопки
  tex_AddBtn, tex_ChBkgr, tex_ChMask : zglPTexture;   // кнопка добавить
  tex_PBar     : array [1..4] of zglPTexture;

  tex_UnkItem  : zglPTexture;
  tex_Units    : array [0..1, 0..5] of TCharPack;
  tex_Creatures: array [1..10] of zglPTexture;
  tex_qPic     : array [1..10] of zglPTexture;
  tex_qMask    : array [1..10] of zglPTexture;
  tex_Cursors  : array [1..10] of zglPTexture;

  texTiles, texTiles2, texTiles3, texTiles4 : zglPTexture;       // тайлы
  lScreen, trvlScreen : zglPTexture;                             // фон для экрана загрузки, путешествия
  tex_LocIcons, tex_BIcons : zglPTexture;                        // текстуры иконок
  tex_Objs     :  array [1..10] of zglPTexture;                  // текстуры объектов
  tex_ui_scr_arr, tex_ui_scr_bod, tex_ui_scr_spot : zglPTexture; // текстуры скролл бара
  tex_item_slots                                  : zglPTexture;
  tex_node     : zglPTexture;
  tex_Arr_Point: zglPTexture;
  tex_ATB, tex_ATB_Rect : zglPTexture;
  CharPack     : array [1..10] of TCharTexPack;
  tex_Icons    : array [1..3] of zglPTexture;
  tex_WMap, tex_map_spot, tex_map_locs   : zglPTexture;
  tex_Skills  : zglPTexture;
  tex_belt, tex_chest, tex_glow : zglPTexture;

  fx             : array [1..10] of TSpFx;
  fx_pr          : array [1..10] of zglPEmitter2D;
  particles      : zglTPEngine2D;
  em_Test        : zglPEmitter2D;


  // NET VARS
  Port1       : integer;                                  // ПОРТ
  Ip1         : PChar;                                    // IP
  attempt     : boolean = false;
  timeout     : integer;
  login, pass : utf8string;                               // сохранённые логин и

  // GAME DATA VARS
  items              : array [1..1000] of TItem;
  skills             : array [1..7*25] of TSkill;
  spells             : array [1..100] of TSpell;
  locs               : array [1..50] of TLoc;
  objStore           : array [1..64] of TLocObject;       // хранилище объектов локации

  CharList           : array [1..4] of TCharHeader;       // список персонажей
  ActiveChar         : TGameChar;                         // перс игрока

  exp_cap            : array [1..16] of integer = ( 240, 270, 600, 990, 1440, 1950,
                                                   2520, 3150, 3840, 4590, 5400,
                                                   6270, 7200, 8190, 9240, 100500);

  aura_data          : array [1..50] of TAuraData;

  // OBJECT, LOCATIONS ETC
  mapW, mapH   : integer;                                 // ширина и высота карты
  layer        : array [0..10] of TTileMap;               // слои

  // GUI VARIABLES
  frmPak    : array [1..3] of  TMyGUIFormPack;            // шкурка форм
  mWins     : array [1..50] of TMyGuiWindow;              // внутриигровые окна
  disap_timer : integer;                                  // исчезновение окна сообщения
  sk_x, sk_y, sk_tx, sk_ty, sk_w, sk_h,
  sk_tw, sk_th, sk_a, sk_ta, sk_z : single;               // параметры колеса умений
  sk_zoom   : boolean;
  puMenu, puMenuZero : TPopUpMenu;
  stat_tab  : byte = 0;                                   // вкладка статов мили\деф\кастер
  ActionBar, SystemBar : array [1..5] of TDragAndDropObj;
  trvlText  : utf8string;
  trvlMin, trvlSec, trvlTime, trvlDest: integer;
  cur_type  : integer = 1;
  cur_angle : integer = 0;
  chat_color: TChatColorPack;
  Tutorial  : word = 0;                                   // Стадия обучения
  tut_frame : word = 1;
  block_btn : boolean = false;                            // блокировка обработки действий

  Inv                : array [1..100] of TDragAndDropObj; // элементы драг-н-дроп
  ddItem             : TDragAndDropObj;
  ddIndex, ddWin     : word;
  on_DD              : boolean;
  Loc_OMO            : word;

  // INGAME CHAT
  ch_tab_curr, ch_tab_total : byte;                        // Текущая вкладка, всего вкладок
  ch_tabs : array [0..7] of TChatTab;                      // вкладки
  ch_scroll_pos, ch_mem_scroll_pos : single;               // позиция прокрутки чата и списка
  omo_ch_scr_up, omo_ch_scr_dw, omo_ch_scr_spot : boolean; // проверяем мышку над скролл-баром
  omo_scr_up, omo_scr_dw, omo_scr_spot : boolean;          // проверяем мышку над скролл-баром
  omo_ch_tabs : array [0..7] of boolean;
  ch_message_inp : boolean;
  com_face : single;
  chat_last_request : word;

   //  COMBAT
   Close_Combat          : boolean = false;
   win_team              : byte = 0;
   units                 : array [0..20] of TUnit;
   MapMatrix             : array [0..20, 0..20] of TCell;
   cText                 : array [1..20] of TCombatText;
   ATB_Data              : TATB_Data;
   ATB_Grid              : array [1..10] of TATBGItem;
   nATB                  : array [1..10] of Integer;
   your_turn             : boolean;
   your_unit, focus_unit : integer;
   in_action, m_omo      : boolean;
   on_CGUI               : boolean;
   m_x, m_y              : integer;
   combat_ID             : longword;
   curr_round            : word;
   sw_result             : boolean;
   n_dir                 : byte;
   spID, spR             : word;
   curr_turn_name        : utf8string;
   t_mm, t_ss            : word;

   // sound

   snd_gui               : array [1..10] of zglPSound;
   theme1, theme2        : zglPSound;
   thID1, thID2          : integer;
   theme_two             : boolean;

   theme_change          : boolean;
   theme_scale           : integer;

   ambient_vol           : single = 0.15;
   gui_vol               : single =  0.3;


implementation

end.


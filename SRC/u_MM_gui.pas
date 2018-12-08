unit u_MM_gui;

// PLEASE DO NOT REMOVE THE {*} COMMENTS, YOU CAN LOOSE YOU SOURCE!

interface
{$mode delphi}
{$codepage utf8}
// Store here uses or proc definition
{INTERFACE}
uses sysutils, zglGui, zglHeader, uVar, uAdd, uNetCore, uXClick;
{END}

var
  NonameForm1: zglTForm;
  NonameEdit2: zglTEdit;
  NonameEdit3: zglTEdit;
  NonameLabel4: zglTLabel;
  NonameLabel5: zglTLabel;
  NonameButton6: zglTButton;
  NonameButton7: zglTButton;
  NonameButton8: zglTButton;
  fCharMan: zglTForm;
  bEnterWorld: zglTButton;
  bDelChar: zglTButton;
  bNewChar: zglTButton;
  bSExit: zglTButton;
  fCharMake: zglTForm;
  eCharName: zglTEdit;
  cbRace: zglTComboBox;
  bCreate: zglTButton;
  bCancel: zglTButton;
  lCharName: zglTLabel;
  NonameLabel28: zglTLabel;
  rgGender: zglTRadioBox;
  rbMale: zglTRadioButton;
  rbFemale: zglTRadioButton;
  fDelChar: zglTForm;
  lDelChar: zglTLabel;
  NonameEdit35: zglTEdit;
  bDelConfirm: zglTButton;
  bDelCancel: zglTButton;
  NonameFrame38: zglTFrame;
  bChatSend: zglTButton;
  eChatFrame: zglTEdit;
  NonameFrame41: zglTFrame;
  ibNext: zglTImageButton;
  ibWait: zglTImageButton;
  ibInv: zglTImageButton;
  fInGame: zglTFrame;
  bInv: zglTButton;
  bCharView: zglTButton;
  bServants: zglTButton;
  bMail: zglTButton;
  bMap: zglTButton;
  fLoading: zglTFrame;
  pbLoading: zglTProgressBar;

procedure InitGui(gui: zglTGui);

const
  CREATED_GUI_VERSION = '0.1a';

type
  zglTGuiEventHandler = class
    class procedure OnClick(Sender: zglTGUIObject; X, Y: integer);
    class procedure OnKeyPress(Sender: zglTGUIObject; Key: Byte; var Cancel: Boolean);
    class procedure cbChange(Sender: zglTGUIObject);
    class procedure eOnChange(Sender: zglTGUIObject);
    class procedure OnEnterKey(Sender: zglTGUIObject);
  end;

implementation

// Store here recursive uses or proc implementation
{IMPLEMENTATION}
uses uLocalization, uLoader;
{END}

class procedure zglTGuiEventHandler.OnClick(Sender: zglTGUIObject; X, Y: integer);
{EVENT OnClick:zglTMouseEvent}
var i : integer;
    s: utf8String;
begin
// Кнопка Логин
  if sender = NonameButton6 then
     begin
     //  gs := gsLoad;

       DoLogin();
     end;
{
// кнопка регистрация
  if Sender = Nonamebutton7 then
     begin
       if cns <> csDisc then exit;

       if utf8_length(NonameEdit2.Caption) < 3 then
          begin
            gui.ShowMessage(ERC[15], ERB[15]);
            exit;
          end;

       if utf8_length(NonameEdit3.Caption) < 3 then
          begin
            gui.ShowMessage(ERC[16], ERB[16]);
            exit;
          end;

       if not checkSymbolsLP(Nonameedit2.Caption) then
       if not checkSymbolsLP(Nonameedit3.Caption) then
          begin
            gui.ShowMessage(ERC[5], ERB[5]);
            exit;
          end;

       cns := csConcting;
       mWins[17].visible := true;
       mWins[17].texts[1].Text:= 'Connecting...';
       Nonameform1.Enabled:=false;
       RegMode := true;
     end;
}
// кнопка выход
  if Sender = Nonamebutton8 then zgl_Exit();

// входим в мир
  if sender = bEnterWorld then
     begin
       DoEnterTheWorld();
     end;

// новый персонаж
  if sender = bNewChar then
     begin
       CreateCharMode := true;
       fCharMan.Visible:=false;
       fCharMake.Visible:=true;
       rgGender.Selected := rbMale;
       bCreate.Enabled:=false;
       mWins[3].visible:=true;
       mWins[3].texts[1].Text:=GetRaceName(cbRace.Selected + 1);
       mWins[3].texts[2].Text:=race_discr[cbRace.Selected + 1];
     end;

// кнопка удалить чара
  if sender = bDelChar then
     begin
       DelCharMode := true;
       fDelChar.Visible := true;
       fDelChar.MoveToCenter;
       bDelConfirm.Enabled:=false;
       fCharMan.Visible:=false;
     end;
// кнопка выход в окне выбора чара
  if sender = bSExit then TCP.FCon.Disconnect(false);

// кнопка подвердить удаление
  if sender = bDelConfirm then
     begin
       DoDelete();
     end;

// кнопка отмена в меню удаления чара
  if sender = bDelCancel then
     begin
       DelCharMode := false;
       fDelChar.Visible := false;
       bDelConfirm.Enabled:=true;
       fCharMan.Visible:=true;
     end;

// кнопка "создать" в меню создания персонажа
  if sender = bCreate then
     begin
       DoCreateChar();
     end;

// отмена в меню создания персонажа
  if sender = bCancel then
     begin
       CreateCharMode := false;
       fCharMan.Visible:= true;
       fCharMake.Visible:=false;
       mWins[3].visible:=false;
     end;

// кнопка отправки чата
  if sender = bChatSend then
     begin
       ch_message_inp := false;
       //Chat_AddMessage(ch_tab_curr, ActiveChar.Name, eChatFrame.Caption);
       DoSendMsg(eChatFrame.Caption);
       Sleep(10);
       eChatFrame.Caption := '';
       key_EndReadText;
       eChatFrame.Gui.Handler.HandleEvent(eChatFrame, heNone);
     end;
// поле ввода
  if sender = eChatFrame then
     begin
       if not ch_message_inp then ch_message_inp := true;
     end;

// кнопка инвентарь
  if sender = bInv then
     if igs <> igsInv then
        begin
          DoOpenInv();
          igs := igsInv
        end else igs := igsNone;

  if sender = bCharView then
     if igs <> igsChar then
         begin
          DoPerkRequest();
          //SendData(inline_PkgCompile(27, activechar.Name + '`'));
          //SendData(inline_PkgCompile(26, activechar.Name + '`'));
          igs := igsChar;
        end else igs := igsNone;

  if sender = bMail then
     if igs <> igsQLog then
        begin
          mWins[8].visible:=false;
          // qlog_Open();
          igs := igsQLog;
        end else igs := igsNone;

  if sender = bMap then
     if igs <> igsMap then
        begin
          igs := igsMap;
          //SendData(inline_PkgCompile(40, IntToStr(activechar.ID) + '`'));
        end else igs := igsNone;

  if sender = bServants then
     if igs <> igsSBook then
        begin
          igs := igsSBook;
        end else igs := igsNone;
end;
{END}

class procedure zglTGuiEventHandler.OnKeyPress(Sender: zglTGUIObject; Key: Byte; var Cancel: Boolean);
{EVENT OnKeyPress:zglTKeyEvent}
begin

end;
{END}

class procedure zglTGuiEventHandler.cbChange(Sender: zglTGUIObject);
{EVENT cbChange:zglTEvent}
begin
  if sender = cbRace then
  begin
      mWins[3].texts[1].Text:=GetRaceName(cbRace.Selected + 1);
      mWins[3].texts[2].Text:=race_discr[cbRace.Selected + 1];
  end;
end;
{END}

class procedure zglTGuiEventHandler.eOnChange(Sender: zglTGUIObject);
{EVENT eOnChange:zglTEvent}
begin
  if sender = eCharName then
     bCreate.Enabled := CheckSymbolsN(eCharName.Caption);
  if sender = Nonameedit35 then
     if u_StrUp(NonameEdit35.Caption) = AnsiToUTF8('DELETE') then
        bDelConfirm.Enabled:=true else bDelConfirm.Enabled:=false;
end;
{END}

class procedure zglTGuiEventHandler.OnEnterKey(Sender: zglTGUIObject);
{EVENT OnEnterKey:zglTEvent}
var s : string;
begin
   if (Sender = NonameEdit2) or (sender = NonameEdit3) then
   begin
     DoLogin();
   end;

   if Sender = eChatFrame then
     begin
       ch_message_inp := false;
       //Chat_AddMessage(ch_tab_curr, ActiveChar.Name, eChatFrame.Caption);
       DoSendMsg(eChatFrame.Caption);
       Sleep(10);
       eChatFrame.Caption := '';
       key_EndReadText;
       eChatFrame.Gui.Handler.HandleEvent(eChatFrame, heNone);
       eChatFrame.Caption := '';
     end;
end;
{END}

procedure InitGui(gui: zglTGui);
begin
  {INIT}
  {.$IF CREATED_GUI_VERSION <> GUI_VERSION}
    {.$MESSAGE Fatal 'GUI version diff with generated code.'}
  {.$IFEND}
  NonameForm1 := zglTForm.CreateDefaults(Gui); {ROOT}
  with NonameForm1 do begin
    Caption := 'Log In'; 
    Rect.H := 205.00; 
    Rect.W := 170.00; 
    Rect.X := 12.00; 
    Rect.Y := 16.00; 
  end;
  Gui.Items.Add(NonameForm1);
    NonameEdit2 := zglTEdit.CreateDefaults(Gui);
    with NonameEdit2 do begin
      Caption := ''; 
      OnChange := zglTGuiEventHandler.eOnChange; 
      OnEnterKey := zglTGuiEventHandler.OnEnterKey; 
      OnKeyDown := zglTGuiEventHandler.OnKeyPress; 
      Rect.H := 20.00; 
      Rect.W := 150.00; 
      Rect.X := 5.00; 
      Rect.Y := 25.00; 
    end;
    NonameForm1.Items.Add(NonameEdit2);
    NonameEdit3 := zglTEdit.CreateDefaults(Gui);
    with NonameEdit3 do begin
      Caption := ''; 
      OnChange := zglTGuiEventHandler.eOnChange; 
      OnEnterKey := zglTGuiEventHandler.OnEnterKey; 
      OnKeyDown := zglTGuiEventHandler.OnKeyPress; 
      Rect.H := 20.00; 
      Rect.W := 150.00; 
      Rect.X := 5.00; 
      Rect.Y := 65.00; 
    end;
    NonameForm1.Items.Add(NonameEdit3);
    NonameLabel4 := zglTLabel.CreateDefaults(Gui);
    with NonameLabel4 do begin
      Caption := 'Login'; 
      Rect.H := 15.00; 
      Rect.W := 150.00; 
      Rect.X := 5.00; 
      Rect.Y := 5.00; 
    end;
    NonameForm1.Items.Add(NonameLabel4);
    NonameLabel5 := zglTLabel.CreateDefaults(Gui);
    with NonameLabel5 do begin
      Caption := 'Password'; 
      Rect.H := 18.00; 
      Rect.W := 150.00; 
      Rect.X := 5.00; 
      Rect.Y := 50.00; 
    end;
    NonameForm1.Items.Add(NonameLabel5);
    NonameButton6 := zglTButton.CreateDefaults(Gui);
    with NonameButton6 do begin
      Caption := 'Log In'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 150.00; 
      Rect.X := 5.00; 
      Rect.Y := 110.00;
    end;
    NonameForm1.Items.Add(NonameButton6);
    NonameButton7 := zglTButton.CreateDefaults(Gui);
    with NonameButton7 do begin
      Caption := 'Registration';
      Visible := false;
      Enabled := false;
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 150.00; 
      Rect.X := 5.00; 
      Rect.Y := 130.00;
    end;
    NonameForm1.Items.Add(NonameButton7);
    NonameButton8 := zglTButton.CreateDefaults(Gui);
    with NonameButton8 do begin
      Caption := 'Exit'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 150.00; 
      Rect.X := 5.00; 
      Rect.Y := 140.00;
    end;
    NonameForm1.Items.Add(NonameButton8);
  fCharMan := zglTForm.CreateDefaults(Gui); {ROOT}
  with fCharMan do begin
    Caption := 'Char manager'; 
    Name := 'fCharMan'; 
    Rect.H := 80.00; 
    Rect.W := 300.00; 
    Rect.X := 0.00; 
    Rect.Y := 0.00; 
  end;
  Gui.Items.Add(fCharMan);
    bEnterWorld := zglTButton.CreateDefaults(Gui);
    with bEnterWorld do begin
      Caption := 'Enter the World'; 
      Name := 'bEnterWorld'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 30.00; 
      Rect.W := 290.00; 
      Rect.X := 0.00; 
      Rect.Y := 0.00; 
    end;
    fCharMan.Items.Add(bEnterWorld);
    bDelChar := zglTButton.CreateDefaults(Gui);
    with bDelChar do begin
      Caption := 'Delete'; 
      Name := 'bDelChar'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 80.00; 
      Rect.X := 105.00; 
      Rect.Y := 35.00; 
    end;
    fCharMan.Items.Add(bDelChar);
    bNewChar := zglTButton.CreateDefaults(Gui);
    with bNewChar do begin
      Caption := 'New'; 
      Name := 'bNewChar'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 80.00; 
      Rect.X := 0.00; 
      Rect.Y := 35.00; 
    end;
    fCharMan.Items.Add(bNewChar);
    bSExit := zglTButton.CreateDefaults(Gui);
    with bSExit do begin
      Caption := 'Exit'; 
      Name := 'bSExit'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 80.00; 
      Rect.X := 210.00; 
      Rect.Y := 35.00; 
    end;
    fCharMan.Items.Add(bSExit);
  fCharMake := zglTForm.CreateDefaults(Gui); {ROOT}
  with fCharMake do begin
    Caption := 'New character'; 
    Name := 'fCharMake'; 
    Rect.H := 210.00; 
    Rect.W := 190.00; 
    Rect.X := 9.00; 
    Rect.Y := 6.00; 
  end;
  Gui.Items.Add(fCharMake);
    eCharName := zglTEdit.CreateDefaults(Gui);
    with eCharName do begin
      Caption := ''; 
      MaxLength := 20; 
      Name := 'eCharName'; 
      OnChange := zglTGuiEventHandler.eOnChange; 
      OnKeyDown := zglTGuiEventHandler.OnKeyPress; 
      Rect.H := 20.00; 
      Rect.W := 170.00; 
      Rect.X := 5.00; 
      Rect.Y := 20.00; 
    end;
    fCharMake.Items.Add(eCharName);
    cbRace := zglTComboBox.CreateDefaults(Gui);
    with cbRace do begin
      Caption := 'Highlander'; 
      ComboMax := 5; 
      Items.Add('Bastard'); 
      Items.Add('Highlander'); 
      Items.Add('Silvan'); 
      Items.Add('Troll'); 
      Items.Add('Crimson demon'); 
      Name := 'cbRace'; 
      OnChange := zglTGuiEventHandler.cbChange; 
      Rect.H := 20.00; 
      Rect.W := 170.00; 
      Rect.X := 5.00; 
      Rect.Y := 55.00; 
      Selected := 1; 
    end;
    fCharMake.Items.Add(cbRace);
    bCreate := zglTButton.CreateDefaults(Gui);
    with bCreate do begin
      Caption := 'Create'; 
      Name := 'bCreate'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 170.00; 
      Rect.X := 5.00; 
      Rect.Y := 135.00; 
    end;
    fCharMake.Items.Add(bCreate);
    bCancel := zglTButton.CreateDefaults(Gui);
    with bCancel do begin
      Caption := 'Cancel'; 
      Name := 'bCancel'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 170.00; 
      Rect.X := 5.00; 
      Rect.Y := 165.00; 
    end;
    fCharMake.Items.Add(bCancel);
    lCharName := zglTLabel.CreateDefaults(Gui);
    with lCharName do begin
      Caption := 'Char name'; 
      Name := 'lCharName'; 
      Rect.H := 15.00; 
      Rect.W := 170.00; 
      Rect.X := 5.00; 
      Rect.Y := 5.00; 
    end;
    fCharMake.Items.Add(lCharName);
    NonameLabel28 := zglTLabel.CreateDefaults(Gui);
    with NonameLabel28 do begin
      Caption := 'Char race'; 
      Name := 'NonameLabel28'; 
      Rect.H := 15.00; 
      Rect.W := 170.00; 
      Rect.X := 5.00; 
      Rect.Y := 40.00; 
    end;
    fCharMake.Items.Add(NonameLabel28);
    rgGender := zglTRadioBox.CreateDefaults(Gui);
    with rgGender do begin
      Caption := 'Gender'; 
      Name := 'rgGender'; 
      Rect.H := 60.00; 
      Rect.W := 170.00; 
      Rect.X := 5.00; 
      Rect.Y := 75.00; 
    end;
    fCharMake.Items.Add(rgGender);
      rbMale := zglTRadioButton.CreateDefaults(Gui);
      with rbMale do begin
        Caption := 'Male'; 
        Name := 'rbMale'; 
        Rect.H := 20.00; 
        Rect.W := 160.00; 
        Rect.X := 5.00; 
        Rect.Y := 5.00; 
      end;
      rgGender.Items.Add(rbMale);
      rbFemale := zglTRadioButton.CreateDefaults(Gui);
      with rbFemale do begin
        Caption := 'Female'; 
        Name := 'rbFemale'; 
        Rect.H := 20.00; 
        Rect.W := 160.00; 
        Rect.X := 5.00; 
        Rect.Y := 30.00; 
      end;
      rgGender.Items.Add(rbFemale);
  fDelChar := zglTForm.CreateDefaults(Gui); {ROOT}
  with fDelChar do begin
    Caption := 'Delete character'; 
    Name := 'fDelChar'; 
    Rect.H := 115.00; 
    Rect.W := 400.00; 
    Rect.X := 9.00; 
    Rect.Y := 14.00; 
  end;
  Gui.Items.Add(fDelChar);
    lDelChar := zglTLabel.CreateDefaults(Gui);
    with lDelChar do begin
      Caption := 'Enter "DELETE" word to confirm your discision.'; 
      Name := 'lDelChar'; 
      Rect.H := 50.00; 
      Rect.W := 380.00; 
      Rect.X := 5.00; 
      Rect.Y := 5.00; 
    end;
    fDelChar.Items.Add(lDelChar);
    NonameEdit35 := zglTEdit.CreateDefaults(Gui);
    with NonameEdit35 do begin
      Caption := ''; 
      MaxLength := 6; 
      Name := 'NonameEdit35'; 
      OnChange := zglTGuiEventHandler.eOnChange; 
      Rect.H := 20.00; 
      Rect.W := 100.00; 
      Rect.X := 140.00; 
      Rect.Y := 70.00; 
    end;
    fDelChar.Items.Add(NonameEdit35);
    bDelConfirm := zglTButton.CreateDefaults(Gui);
    with bDelConfirm do begin
      Caption := 'Confirm'; 
      Name := 'bDelConfirm'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 100.00; 
      Rect.X := 5.00; 
      Rect.Y := 70.00; 
    end;
    fDelChar.Items.Add(bDelConfirm);
    bDelCancel := zglTButton.CreateDefaults(Gui);
    with bDelCancel do begin
      Caption := 'Cancel'; 
      Name := 'bDelCancel'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 100.00; 
      Rect.X := 285.00; 
      Rect.Y := 70.00; 
    end;
    fDelChar.Items.Add(bDelCancel);
  NonameFrame38 := zglTFrame.CreateDefaults(Gui); {ROOT}
  with NonameFrame38 do begin
    Name := 'NonameFrame38'; 
    Rect.H := 20.00; 
    Rect.W := 400.00; 
    Rect.X := 5.00; 
    Rect.Y := 5.00; 
  end;
  Gui.Items.Add(NonameFrame38);
    bChatSend := zglTButton.CreateDefaults(Gui);
    with bChatSend do begin
      Caption := '>>>'; 
      Name := 'bChatSend'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 50.00; 
      Rect.X := 350.00; 
      Rect.Y := 0.00; 
    end;
    NonameFrame38.Items.Add(bChatSend);
    eChatFrame := zglTEdit.CreateDefaults(Gui);
    with eChatFrame do begin
      Caption := ''; 
      MaxLength := 99; 
      Name := 'eChatFrame';
      OnClick := zglTGuiEventHandler.OnClick;
      OnEnterKey := zglTGuiEventHandler.OnEnterKey; 
      OnKeyDown := zglTGuiEventHandler.OnKeyPress; 
      Rect.H := 20.00; 
      Rect.W := 350.00; 
      Rect.X := 0.00; 
      Rect.Y := 0.00; 
    end;
    NonameFrame38.Items.Add(eChatFrame);
  NonameFrame41 := zglTFrame.CreateDefaults(Gui); {ROOT}
  with NonameFrame41 do begin
    Name := 'NonameFrame41'; 
    Rect.H := 40.00; 
    Rect.W := 120.00; 
    Rect.X := 24.00; 
    Rect.Y := 16.00; 
  end;
  Gui.Items.Add(NonameFrame41);
    ibNext := zglTImageButton.CreateDefaults(Gui);
    with ibNext do begin
      Name := 'ibNext'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 35.00;
      Rect.W := 35.00;
      Rect.X := 80.00; 
      Rect.Y := 5.00;
      Texture.FileName := 'Data\UI\CombatButton1.tga'; 
      Texture.TexHeight := 80; 
      Texture.TexWidth := 80; 
    end;
    NonameFrame41.Items.Add(ibNext);
    ibWait := zglTImageButton.CreateDefaults(Gui);
    with ibWait do begin
      Name := 'ibWait'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 35.00;
      Rect.W := 35.00;
      Rect.X := 40.00; 
      Rect.Y := 5.00;
      Texture.FileName := 'Data\UI\CombatButton2.tga'; 
      Texture.TexHeight := 80; 
      Texture.TexWidth := 80; 
    end;
    NonameFrame41.Items.Add(ibWait);
    ibInv := zglTImageButton.CreateDefaults(Gui);
    with ibInv do begin
      Name := 'ibInv'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 35.00;
      Rect.W := 35.00;
      Rect.X := 0.00; 
      Rect.Y := 5.00;
      Texture.FileName := 'Data\UI\CombatButton3.tga';
      Texture.TexHeight := 80; 
      Texture.TexWidth := 80; 
    end;
    NonameFrame41.Items.Add(ibInv);
  fInGame := zglTFrame.CreateDefaults(Gui); {ROOT}
  with fInGame do begin
    Name := 'fInGame'; 
    Rect.H := 104.00; 
    Rect.W := 104.00; 
    Rect.X := 0.00; 
    Rect.Y := 0.00;
  end;
  Gui.Items.Add(fInGame);
    bInv := zglTButton.CreateDefaults(Gui);
    with bInv do begin
      Caption := 'Inventory'; 
      Name := 'bInv'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 100.00; 
      Rect.X := 2.00; 
      Rect.Y := 2.00; 
    end;
    fInGame.Items.Add(bInv);
    bCharView := zglTButton.CreateDefaults(Gui);
    with bCharView do begin
      Caption := 'Character'; 
      Name := 'bCharView'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 100.00; 
      Rect.X := 2.00; 
      Rect.Y := 22.00; 
    end;
    fInGame.Items.Add(bCharView);
    bServants := zglTButton.CreateDefaults(Gui);
    with bServants do begin
      Caption := 'Spellbook';
      Name := 'bServants'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 100.00; 
      Rect.X := 2.00; 
      Rect.Y := 42.00; 
    end;
    fInGame.Items.Add(bServants);
    bMail := zglTButton.CreateDefaults(Gui);
    with bMail do begin
      Caption := 'Quest Log';
      Name := 'bMail'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 100.00; 
      Rect.X := 2.00; 
      Rect.Y := 62.00; 
    end;
    fInGame.Items.Add(bMail);
    bMap := zglTButton.CreateDefaults(Gui);
    with bMap do begin
      Caption := 'Map'; 
      Name := 'bMap'; 
      OnClick := zglTGuiEventHandler.OnClick; 
      Rect.H := 20.00; 
      Rect.W := 100.00; 
      Rect.X := 2.00; 
      Rect.Y := 82.00; 
    end;
    fInGame.Items.Add(bMap);
  fLoading := zglTFrame.CreateDefaults(Gui); {ROOT}
  with fLoading do begin
    Name := 'fLoading'; 
    Rect.H := 20.00; 
    Rect.W := 400.00; 
    Rect.X := 0.00; 
    Rect.Y := 0.00; 
  end;
  Gui.Items.Add(fLoading);
    pbLoading := zglTProgressBar.CreateDefaults(Gui);
    with pbLoading do begin
      Name := 'pbLoading'; 
      Rect.H := 20.00; 
      Rect.W := 400.00; 
      Rect.X := 0.00; 
      Rect.Y := 0.00; 
    end;
    fLoading.Items.Add(pbLoading);
  {END}
end;

end.

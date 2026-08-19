unit TestMainForm;

{ A VCL form built to be translated badly.

  Everything here exists to be a test: the containers are deliberately tight,
  the captions are deliberately short in English, and several of them sit in
  places where a translation half again as long has nowhere obvious to go. A
  form that looks comfortable in English proves nothing.

  It covers, in one place, every situation the analyser and the runtime have
  had trouble with:

    - a caption in a container barely wide enough for the English
    - a row of buttons that has to keep an even pitch as the words grow
    - a caption above its field, which must keep its column
    - a right-aligned caption, which must grow leftwards
    - a wrapped paragraph, which must grow downwards rather than sideways
    - column headers, held in a collection rather than as properties
    - menu items, which live outside the visual tree
    - a second form created fresh each time it is opened, which is the case
      that has never translated in the field

  The last one matters most. Forms that exist when the language is chosen are
  the easy case; a form built afterwards is the one that has been coming up in
  English. }

interface

uses
  System.Classes,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Menus,
  Vcl.Grids,
  DAT.Components.VCL,
  DAT.Components.VCL.LanguageSelector, DAT.Components.Core;

type
  TfrmVCLTestMain = class(TForm)
    DATManager: TDATVCLLanguageManager;
    mnuMain: TMainMenu;
    mnuFile: TMenuItem;
    mnuFileOpen: TMenuItem;
    mnuFileSave: TMenuItem;
    mnuFileExit: TMenuItem;
    mnuSettings: TMenuItem;
    mnuSettingsOptions: TMenuItem;
    mnuSettingsColors: TMenuItem;
    mnuHelp: TMenuItem;
    mnuHelpAbout: TMenuItem;
    lblTitle: TLabel;
    lblLanguage: TLabel;
    cboLanguage: TDATVCLLanguageComboBox;
    grpSchedule: TGroupBox;
    chkEnableSchedule: TCheckBox;
    lblScheduleNote: TLabel;
    pnlMedia: TPanel;
    btnPlay: TButton;
    btnPause: TButton;
    btnStop: TButton;
    lblCustomerName: TLabel;
    edtCustomerName: TEdit;
    lblEmail: TLabel;
    edtEmail: TEdit;
    lblDuration: TLabel;
    edtDuration: TEdit;
    lblIntro: TLabel;
    lblNotes: TLabel;
    memNotes: TMemo;
    lstItems: TListBox;
    rgMode: TRadioGroup;
    lvSchedule: TListView;
    grdValues: TStringGrid;
    btnDetails: TButton;
    btnClose: TButton;
    procedure btnDetailsClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure mnuFileExitClick(Sender: TObject);
  end;

var
  frmVCLTestMain: TfrmVCLTestMain;

implementation

{$R *.dfm}

uses
  TestDetailsForm;

procedure TfrmVCLTestMain.btnDetailsClick(Sender: TObject);
var
  Details: TfrmVCLTestDetails;
begin
  { Deliberately built fresh every time, and deliberately not the instance the
    project auto-created. This is what the application in the field does, and
    it is the case whose forms have been appearing untranslated. If this one
    opens in English while the main form is translated, the fault is in how the
    language manager finds a form rather than in anything about the text. }
  Details := TfrmVCLTestDetails.Create(Self);
  try
    Details.ShowModal;
  finally
    Details.Free;
  end;
end;

procedure TfrmVCLTestMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmVCLTestMain.mnuFileExitClick(Sender: TObject);
begin
  Close;
end;

end.

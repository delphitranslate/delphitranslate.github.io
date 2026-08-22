unit SampleVCL.MainForm;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Menus,
  DAT.Components.VCL;

resourcestring
  SWelcomeMessage = 'Welcome to the VCL translation sample.';
  SNameRequired = 'Please enter a customer name.';

type
  TfrmVCLSample = class(TForm)
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuExit: TMenuItem;
    mnuLanguage: TMenuItem;
    lblHeading: TLabel;
    lblCustomerName: TLabel;
    edtCustomerName: TEdit;
    btnSave: TButton;
    memInstructions: TMemo;
    cmbDateRange: TComboBox;
    { Dropped on the form in the designer, exactly as the component kit's
      instructions say to. Its three properties are set in the Object
      Inspector and stream from the .dfm; nothing is configured in code. }
    DATManager: TDATVCLLanguageManager;
    procedure btnSaveClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
  end;

var
  frmVCLSample: TfrmVCLSample;

implementation

uses
  System.SysUtils,
  Vcl.Dialogs;

{$R *.dfm}

procedure TfrmVCLSample.btnSaveClick(Sender: TObject);
begin
  if Trim(edtCustomerName.Text) = '' then
    ShowMessage(SNameRequired)
  else
    ShowMessage(SWelcomeMessage);
end;

procedure TfrmVCLSample.mnuExitClick(Sender: TObject);
begin
  Close;
end;

end.

unit SampleVCL.MainForm;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Menus;

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

unit SampleFMX.MainForm;

interface

uses
  System.Classes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Grid,
  FMX.Grid.Style,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.Memo,
  FMX.ScrollBox,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Menus;

resourcestring
  SWelcomeMessage = 'Welcome to the FireMonkey translation sample.';
  SNameRequired = 'Please enter a customer name.';

type
  TfrmFMXSample = class(TForm)
    MainMenuBar: TMenuBar;
    mnuFile: TMenuItem;
    mnuExit: TMenuItem;
    mnuLanguage: TMenuItem;
    ContentLayout: TLayout;
    lblHeading: TLabel;
    lblCustomerName: TLabel;
    edtCustomerName: TEdit;
    btnSave: TButton;
    memInstructions: TMemo;
    cmbDateRange: TComboBox;
    chkSendCopy: TCheckBox;
    grdCustomers: TStringGrid;
    colCustomer: TStringColumn;
    procedure btnSaveClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
  end;

var
  frmFMXSample: TfrmFMXSample;

implementation

uses
  System.SysUtils,
  FMX.Dialogs;

{$R *.fmx}

procedure TfrmFMXSample.btnSaveClick(Sender: TObject);
begin
  if Trim(edtCustomerName.Text) = '' then
    ShowMessage(SNameRequired)
  else
    ShowMessage(SWelcomeMessage);
end;

procedure TfrmFMXSample.mnuExitClick(Sender: TObject);
begin
  Close;
end;

end.

unit TestDetailsForm;

{ A form the application builds fresh every time it is opened.

  The project auto-creates one instance at start-up, and the main form ignores
  it and constructs another when the button is pressed. That is exactly what
  the application in the field does, and those are exactly the forms that have
  been appearing in English while everything else is translated.

  If this form opens translated, form discovery is sound and the field problem
  lies elsewhere. If it opens in English while the main form is Spanish, the
  fault is reproduced here, offline, where it can be fixed without anyone
  running the real application. }

interface

uses
  System.Classes,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TfrmVCLTestDetails = class(TForm)
    lblDetailsTitle: TLabel;
    lblExplain: TLabel;
    grpWindow: TGroupBox;
    lblStart: TLabel;
    edtStart: TEdit;
    lblEnd: TLabel;
    edtEnd: TEdit;
    chkSilence: TCheckBox;
    btnApply: TButton;
    btnCancel: TButton;
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
  end;

var
  frmVCLTestDetails: TfrmVCLTestDetails;

implementation

{$R *.dfm}

procedure TfrmVCLTestDetails.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmVCLTestDetails.btnApplyClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.

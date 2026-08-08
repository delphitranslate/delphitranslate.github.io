unit VCLLifecycle.Form;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  TfrmVCLLifecycle = class(TForm)
    lblProbe: TLabel;
    tmrModalClose: TTimer;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrModalCloseTimer(Sender: TObject);
  private
    FCloseModalAutomatically: Boolean;
    procedure RecordStage(const AStage: string);
  protected
    procedure Loaded; override;
  public
    procedure AfterConstruction; override;
    property CloseModalAutomatically: Boolean
      read FCloseModalAutomatically write FCloseModalAutomatically;
  end;

var
  frmVCLLifecycle: TfrmVCLLifecycle;

implementation

uses
  DAT.LifecycleSpike.Trace;

{$R *.dfm}

procedure TfrmVCLLifecycle.AfterConstruction;
begin
  inherited AfterConstruction;
  RecordStage('after-construction');
end;

procedure TfrmVCLLifecycle.FormActivate(Sender: TObject);
begin
  RecordStage('activate');
end;

procedure TfrmVCLLifecycle.FormCreate(Sender: TObject);
begin
  RecordStage('form-create');
end;

procedure TfrmVCLLifecycle.FormDestroy(Sender: TObject);
begin
  RecordStage('form-destroy');
end;

procedure TfrmVCLLifecycle.FormPaint(Sender: TObject);
begin
  RecordStage('paint');
end;

procedure TfrmVCLLifecycle.FormShow(Sender: TObject);
begin
  RecordStage('show');
  if FCloseModalAutomatically then
    tmrModalClose.Enabled := True;
end;

procedure TfrmVCLLifecycle.Loaded;
begin
  inherited Loaded;
  RecordStage('loaded');
end;

procedure TfrmVCLLifecycle.RecordStage(const AStage: string);
begin
  RecordLifecycle('VCL', Name, AStage, Caption, lblProbe.Caption);
end;

procedure TfrmVCLLifecycle.tmrModalCloseTimer(Sender: TObject);
begin
  tmrModalClose.Enabled := False;
  ModalResult := mrOk;
end;

end.

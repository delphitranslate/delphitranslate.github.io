unit FMXLifecycle.Form;

interface

uses
  System.Classes,
  System.Types,
  System.UITypes,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.StdCtrls,
  FMX.Types;

type
  TfrmFMXLifecycle = class(TForm)
    lblProbe: TLabel;
    tmrModalClose: TTimer;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
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
  frmFMXLifecycle: TfrmFMXLifecycle;

implementation

uses
  DAT.LifecycleSpike.Trace;

{$R *.fmx}

procedure TfrmFMXLifecycle.AfterConstruction;
begin
  inherited AfterConstruction;
  RecordStage('after-construction');
end;

procedure TfrmFMXLifecycle.FormActivate(Sender: TObject);
begin
  RecordStage('activate');
end;

procedure TfrmFMXLifecycle.FormCreate(Sender: TObject);
begin
  RecordStage('form-create');
end;

procedure TfrmFMXLifecycle.FormDestroy(Sender: TObject);
begin
  RecordStage('form-destroy');
end;

procedure TfrmFMXLifecycle.FormPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  RecordStage('paint');
end;

procedure TfrmFMXLifecycle.FormShow(Sender: TObject);
begin
  RecordStage('show');
  if FCloseModalAutomatically then
    tmrModalClose.Enabled := True;
end;

procedure TfrmFMXLifecycle.Loaded;
begin
  inherited Loaded;
  RecordStage('loaded');
end;

procedure TfrmFMXLifecycle.RecordStage(const AStage: string);
begin
  RecordLifecycle('FMX', Name, AStage, Caption, lblProbe.Text);
end;

procedure TfrmFMXLifecycle.tmrModalCloseTimer(Sender: TObject);
begin
  tmrModalClose.Enabled := False;
  ModalResult := mrOk;
end;

end.

unit VCLLifecycle.MDIMain;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  TfrmVCLLifecycleMDIMain = class(TForm)
    lblProbe: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure RecordStage(const AStage: string);
  protected
    procedure Loaded; override;
  public
    procedure AfterConstruction; override;
  end;

var
  frmVCLLifecycleMDIMain: TfrmVCLLifecycleMDIMain;

implementation

uses
  DAT.LifecycleSpike.Trace;

{$R *.dfm}

procedure TfrmVCLLifecycleMDIMain.AfterConstruction;
begin
  inherited AfterConstruction;
  RecordStage('after-construction');
end;

procedure TfrmVCLLifecycleMDIMain.FormCreate(Sender: TObject);
begin
  RecordStage('form-create');
end;

procedure TfrmVCLLifecycleMDIMain.FormDestroy(Sender: TObject);
begin
  RecordStage('form-destroy');
end;

procedure TfrmVCLLifecycleMDIMain.FormPaint(Sender: TObject);
begin
  RecordStage('paint');
end;

procedure TfrmVCLLifecycleMDIMain.FormShow(Sender: TObject);
begin
  RecordStage('show');
end;

procedure TfrmVCLLifecycleMDIMain.Loaded;
begin
  inherited Loaded;
  RecordStage('loaded');
end;

procedure TfrmVCLLifecycleMDIMain.RecordStage(const AStage: string);
begin
  RecordLifecycle('VCL', Name, AStage, Caption, lblProbe.Caption);
end;

end.

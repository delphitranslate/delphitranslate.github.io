unit VCLLifecycle.MDIChild;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls;

type
  TfrmVCLLifecycleMDIChild = class(TForm)
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

implementation

uses
  DAT.LifecycleSpike.Trace;

{$R *.dfm}

procedure TfrmVCLLifecycleMDIChild.AfterConstruction;
begin
  inherited AfterConstruction;
  RecordStage('after-construction');
end;

procedure TfrmVCLLifecycleMDIChild.FormCreate(Sender: TObject);
begin
  RecordStage('form-create');
end;

procedure TfrmVCLLifecycleMDIChild.FormDestroy(Sender: TObject);
begin
  RecordStage('form-destroy');
end;

procedure TfrmVCLLifecycleMDIChild.FormPaint(Sender: TObject);
begin
  RecordStage('paint');
end;

procedure TfrmVCLLifecycleMDIChild.FormShow(Sender: TObject);
begin
  RecordStage('show');
end;

procedure TfrmVCLLifecycleMDIChild.Loaded;
begin
  inherited Loaded;
  RecordStage('loaded');
end;

procedure TfrmVCLLifecycleMDIChild.RecordStage(const AStage: string);
begin
  RecordLifecycle('VCL', Name, AStage, Caption, lblProbe.Caption);
end;

end.

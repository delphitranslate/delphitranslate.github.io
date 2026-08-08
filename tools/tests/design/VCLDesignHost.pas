unit VCLDesignHost;

interface

uses
  System.Classes,
  Vcl.Forms,
  DAT.Components.VCL;

type
  TfrmVCLDesignHost = class(TForm)
    DATLanguageManager: TDATVCLLanguageManager;
  end;

implementation

{$R *.dfm}

end.

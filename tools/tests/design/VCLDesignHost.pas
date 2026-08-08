unit VCLDesignHost;

interface

uses
  System.Classes,
  Vcl.Forms,
  DAT.Components.VCL,
  DAT.Components.VCL.LanguageSelector;

type
  TfrmVCLDesignHost = class(TForm)
    DATLanguageManager: TDATVCLLanguageManager;
    LanguageSelector: TDATVCLLanguageComboBox;
  end;

implementation

{$R *.dfm}

end.

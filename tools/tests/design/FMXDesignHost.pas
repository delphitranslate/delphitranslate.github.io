unit FMXDesignHost;

interface

uses
  System.Classes,
  FMX.Forms,
  DAT.Components.FMX,
  DAT.Components.FMX.LanguageSelector;

type
  TfrmFMXDesignHost = class(TForm)
    DATLanguageManager: TDATFMXLanguageManager;
    LanguageSelector: TDATFMXLanguageComboBox;
  end;

implementation

{$R *.fmx}

end.

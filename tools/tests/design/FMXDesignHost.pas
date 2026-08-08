unit FMXDesignHost;

interface

uses
  System.Classes,
  FMX.Forms,
  DAT.Components.FMX;

type
  TfrmFMXDesignHost = class(TForm)
    DATLanguageManager: TDATFMXLanguageManager;
  end;

implementation

{$R *.fmx}

end.

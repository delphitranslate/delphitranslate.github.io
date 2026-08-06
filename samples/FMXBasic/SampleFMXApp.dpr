program SampleFMXApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  SampleFMX.MainForm in 'SampleFMX.MainForm.pas' {frmFMXSample};

begin
  Application.Initialize;
  Application.CreateForm(TfrmFMXSample, frmFMXSample);
  Application.Run;
end.

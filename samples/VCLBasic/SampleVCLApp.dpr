program SampleVCLApp;

uses
  Vcl.Forms,
  SampleVCL.MainForm in 'SampleVCL.MainForm.pas' {frmVCLSample};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmVCLSample, frmVCLSample);
  Application.Run;
end.

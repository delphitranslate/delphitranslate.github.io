program VCLTranslationTestApp;

{ A small VCL application whose only purpose is to be translated.

  Both forms are auto-created here, and the main form ignores the auto-created
  details form and builds its own when the button is pressed. That mirrors the
  application in the field, where the forms that never translate are precisely
  the ones constructed on demand. }

uses
  Vcl.Forms,
  TestMainForm in 'TestMainForm.pas' {frmVCLTestMain},
  TestDetailsForm in 'TestDetailsForm.pas' {frmVCLTestDetails};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'VCL Translation Test Application';
  Application.CreateForm(TfrmVCLTestMain, frmVCLTestMain);
  Application.CreateForm(TfrmVCLTestDetails, frmVCLTestDetails);
  Application.Run;
end.

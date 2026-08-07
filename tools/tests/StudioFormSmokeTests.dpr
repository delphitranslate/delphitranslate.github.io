program StudioFormSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  FMX.Forms,
  DAT.Studio.MainForm in '..\..\source\studio\DAT.Studio.MainForm.pas'
    {frmTranslationStudio};

begin
  try
    Application.Initialize;
    frmTranslationStudio := TfrmTranslationStudio.Create(nil);
    try
      if frmTranslationStudio.Caption <>
        'Delphi App Translation Studio' then
        raise Exception.Create('The main form caption is incorrect.');
      if not frmTranslationStudio.edtProviderApiKey.Password then
        raise Exception.Create('The provider API key field is not masked.');
      if frmTranslationStudio.cboTranslationProvider.Items.Count <> 2 then
        raise Exception.Create('The provider list is incomplete.');
      frmTranslationStudio.lblNavigationSettingsClick(nil);
      if not frmTranslationStudio.SettingsPageCard.Visible then
        raise Exception.Create('The Provider Settings workflow page did not activate.');
      Writeln('Studio FMX form creation and streaming passed.');
    finally
      frmTranslationStudio.Free;
      frmTranslationStudio := nil;
    end;
  except
    on E: Exception do
    begin
      Writeln('Studio FMX form smoke test failed: ', E.Message);
      Halt(1);
    end;
  end;
end.

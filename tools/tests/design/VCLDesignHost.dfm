object frmVCLDesignHost: TfrmVCLDesignHost
  Left = 0
  Top = 0
  Caption = 'VCL Designer Host'
  ClientHeight = 240
  ClientWidth = 420
  Position = poScreenCenter
  object DATLanguageManager: TDATVCLLanguageManager
    ApplicationId = 'VCLDesignHost'
    LanguagesFolder = 'Localization\Languages'
    SourceLanguage = 'en-US'
    AutoLoadPreferred = False
    AutoTranslateOwner = False
    ReapplyOpenForms = False
    PreferenceLocation = plExecutableFolder
    Left = 32
    Top = 32
  end
  object LanguageSelector: TDATVCLLanguageComboBox
    Left = 32
    Top = 80
    Width = 220
    Height = 21
    LanguageManager = DATLanguageManager
    TabOrder = 0
  end
end

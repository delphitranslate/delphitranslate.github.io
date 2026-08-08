object frmVCLLifecycle: TfrmVCLLifecycle
  Left = 0
  Top = 0
  Caption = 'VCL Lifecycle Source'
  ClientHeight = 180
  ClientWidth = 420
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  OnShow = FormShow
  object lblProbe: TLabel
    Left = 32
    Top = 56
    Width = 138
    Height = 23
    Caption = 'VCL source text'
    Font.Height = -19
    ParentFont = False
  end
  object tmrModalClose: TTimer
    Enabled = False
    Interval = 30
    OnTimer = tmrModalCloseTimer
    Left = 344
    Top = 120
  end
end

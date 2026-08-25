object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 400
  ClientWidth = 640
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object gbSchedule: TGroupBox
    Left = 20
    Top = 20
    Width = 579
    Height = 300
    TabOrder = 0
    object lblTimesToPlay: TLabel
      Left = 462
      Top = 150
      Width = 61
      Height = 40
      Caption = 'Times to Play:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object edtTimesToPlay: TEdit
      Left = 461
      Top = 197
      Width = 42
      Height = 28
      TabOrder = 0
    end
  end
end

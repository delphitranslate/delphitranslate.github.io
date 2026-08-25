object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 700
  ClientWidth = 960
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 930
    Height = 650
    TabOrder = 0
    object edtGroupFilter: TEdit
      Left = 20
      Top = 157
      Width = 190
      Height = 28
      TabOrder = 0
    end
    object btnAssignSeasonalGroup: TButton
      Left = 664
      Top = 155
      Width = 249
      Height = 30
      Caption = 'Assign a Group to Selected Rows'
      TabOrder = 1
      WordWrap = True
    end
    object gridPlaylist: TStringGrid
      Left = 20
      Top = 191
      Width = 893
      Height = 423
      TabOrder = 2
    end
  end
end

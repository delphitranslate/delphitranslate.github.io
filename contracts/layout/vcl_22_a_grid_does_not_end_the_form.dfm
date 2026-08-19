object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 300
  ClientWidth = 460
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object grdSchedule: TDBGrid
    Left = 24
    Top = 16
    Width = 400
    Height = 90
    Columns = <
      item
        Expanded = False
        Title.Caption = 'Time'
        Width = 90
        Visible = True
      end
      item
        Expanded = False
        Title.Caption = 'Song name'
        Width = 200
        Visible = True
      end
      item
        Expanded = False
        Title.Caption = 'Duration'
        Width = 90
        Visible = True
      end>
  end
  object grpMedia: TGroupBox
    Left = 24
    Top = 130
    Width = 300
    Height = 120
    Caption = 'Playback'
    object lblMedia: TLabel
      Left = 13
      Top = 20
      Width = 76
      Height = 17
      Caption = 'Media Player'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
end

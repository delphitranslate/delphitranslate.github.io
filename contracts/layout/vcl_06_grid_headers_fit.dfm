object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 260
  ClientWidth = 760
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  object grdSchedule: TDBGrid
    Left = 40
    Top = 50
    Width = 680
    Height = 150
    Columns = <
      item
        Expanded = False
        FieldName = 'PLAYDATEFROM'
        Title.Caption = 'Play Date From'
        Width = 72
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PLAYTIME'
        Title.Caption = 'Play Time'
        Width = 72
        Visible = True
      end>
  end
end

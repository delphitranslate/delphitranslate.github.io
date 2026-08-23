object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 260
  ClientWidth = 760
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Segoe UI'
  Font.Style = []
  object grdSchedule: TDBGrid
    Left = 40
    Top = 50
    Width = 537
    Height = 150
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -15
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'PLAYDATETO'
        Title.Caption = 'Play Date To'
        Width = 115
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'SEASONALGROUP'
        Title.Caption = 'Group'
        Width = 155
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PLAYDATEFROM'
        Title.Caption = 'Play Date From'
        Width = 115
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PLAYTIME'
        Title.Caption = 'Play Time'
        Width = 115
        Visible = True
      end>
  end
end

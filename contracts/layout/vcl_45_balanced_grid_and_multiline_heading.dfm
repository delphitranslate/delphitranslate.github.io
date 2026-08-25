object ContractForm: TContractForm
  Left = 0
  Top = 0
  Caption = 'Contract Form'
  ClientHeight = 700
  ClientWidth = 1604
  Font.Height = -12
  object lblSplashTitle: TLabel
    Left = 608
    Top = 80
    Width = 478
    Height = 142
    Alignment = taCenter
    AutoSize = False
    Caption = 'Westminster Chimes'#13#10'and Carillon Bells'
    Font.Height = -53
    ParentFont = False
    WordWrap = True
  end
  object grdGroups: TDBGrid
    Left = 176
    Top = 300
    Width = 500
    Height = 289
    TitleFont.Height = -15
    Columns = <
      item
        Title.Caption = 'Group'
        Width = 155
      end
      item
        Title.Caption = 'Play Date From'
        Width = 115
      end
      item
        Title.Caption = 'Play Date To'
        Width = 115
      end
      item
        Title.Caption = 'Play Time'
        Width = 115
      end>
  end
end

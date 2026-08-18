object frmTier2: TForm
  Caption = 'Tier two'
  ClientHeight = 300
  ClientWidth = 600
  object lvFiles: TListView
    Left = 8
    Top = 8
    Width = 300
    Height = 120
    Items = <
      item
        Caption = 'First row'
      end
      item
        Caption = 'Second row'
      end>
    Columns = <
      item
        Caption = 'Name column'
      end>
  end
  object tvFolders: TTreeView
    Left = 320
    Top = 8
    Width = 260
    Height = 120
    Items.NodeData = {}
  end
  object stbStatus: TStatusBar
    Panels = <
      item
        Text = 'Ready to run'
      end>
  end
  object lblAfter: TLabel
    Left = 8
    Top = 240
    Width = 200
    Height = 20
    Caption = 'Drawn after every collection'
  end
end

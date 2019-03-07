inherited FraCopy: TFraCopy
  Height = 93
  ExplicitHeight = 93
  object Label1: TLabel
    Left = 3
    Top = 3
    Width = 55
    Height = 13
    Caption = '{lblDestDir}'
  end
  object lblOnFileExists: TLabel
    Left = 3
    Top = 49
    Width = 78
    Height = 13
    Caption = '{lblOnFileExists}'
  end
  object bedtDestDirectory: TButtonedEdit
    Left = 3
    Top = 22
    Width = 445
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    AutoSelect = False
    Images = ModImageLists.Icons16
    RightButton.Hint = '{bedtDestDirRightButton}'
    RightButton.ImageIndex = 0
    RightButton.Visible = True
    TabOrder = 0
    OnExit = bedtDestDirectoryExit
    OnRightButtonClick = bedtDestDirectoryRightButtonClick
  end
  object cboOnFileExists: TComboBox
    Left = 3
    Top = 68
    Width = 445
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    OnSelect = cboOnFileExistsSelect
    Items.Strings = (
      '{itemOverwrite}'
      '{itemOverwriteNewer}'
      '{itemOverwriteOlder}'
      '{itemOverwriteGreater}'
      '{itemOverwriteSmaller}'
      '{itemSkip}'
      '{itemCopyKeepBoth}')
  end
end

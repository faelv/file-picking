object ModMain: TModMain
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 279
  Width = 312
  object MainActionManager: TActionManager
    DisabledImages = ModImageLists.IconsDisabled26
    LargeDisabledImages = ModImageLists.IconsDisabled26
    LargeImages = ModImageLists.Icons26
    Images = ModImageLists.Icons26
    Left = 50
    Top = 10
    StyleName = 'Platform Default'
    object ActionNew: TAction
      Category = 'Main'
      Caption = '{ActionNew}'
      Hint = '{ActionNewHint}'
      ImageIndex = 18
      ShortCut = 16462
      OnExecute = ActionNewExecute
    end
    object ActionOpen: TAction
      Category = 'Main'
      Caption = '{ActionOpen}'
      Hint = '{ActionOpenHint}'
      ImageIndex = 0
      ShortCut = 16463
      OnExecute = ActionOpenExecute
    end
    object ActionSave: TAction
      Category = 'Main'
      Caption = '{ActionSave}'
      Hint = '{ActionSaveHint}'
      ImageIndex = 1
      ShortCut = 16467
      OnExecute = ActionSaveExecute
    end
    object ActionSaveAs: TAction
      Category = 'Main'
      Caption = '{ActionSaveAs}'
      Hint = '{ActionSaveHint}'
      ImageIndex = 1
      ShortCut = 24659
      OnExecute = ActionSaveAsExecute
    end
    object ActionAbout: TAction
      Category = 'Main'
      Caption = '{ActionAbout}'
      Hint = '{ActionAboutHint}'
      ImageIndex = 5
      ShortCut = 16496
      OnExecute = ActionAboutExecute
    end
    object ActionStart: TAction
      Category = 'Main'
      Caption = '{ActionStart}'
      Hint = '{ActionStartHint}'
      ImageIndex = 3
      ShortCut = 16466
      OnExecute = ActionStartExecute
    end
    object ActionPause: TAction
      Category = 'Main'
      Caption = '{ActionPause}'
      Hint = '{ActionPauseHint}'
      ImageIndex = 2
      ShortCut = 16464
      OnExecute = ActionPauseExecute
    end
    object ActionStop: TAction
      Category = 'Main'
      Caption = '{ActionStop}'
      Hint = '{ActionStopHint}'
      ImageIndex = 4
      ShortCut = 16468
      OnExecute = ActionStopExecute
    end
    object ActionTest: TAction
      Category = 'Main'
      Caption = '{ActionTest}'
      Hint = '{ActionTestHint}'
      ImageIndex = 14
      ShortCut = 16454
      OnExecute = ActionTestExecute
    end
  end
  object MainOpenDialog: TOpenDialog
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 45
    Top = 170
  end
  object MainSaveDialog: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 140
    Top = 170
  end
  object ApplicationEvents: TApplicationEvents
    OnMessage = ApplicationEventsMessage
    Left = 55
    Top = 90
  end
end

program FilePicking;

uses
  Vcl.Forms,
  Fp.UI.FrmMain in 'frm\Fp.UI.FrmMain.pas' {FrmMain},
  Fp.Resources.Definitions in 'Fp.Resources.Definitions.pas',
  Fp.Resources.Strings in 'Fp.Resources.Strings.pas',
  Fp.Types.Interfaces in 'Fp.Types.Interfaces.pas',
  Fp.Resources.Notifications in 'Fp.Resources.Notifications.pas',
  Fp.Types.LangStorage in 'Fp.Types.LangStorage.pas',
  Fp.Types.Settings in 'Fp.Types.Settings.pas',
  Fp.Types.Storage in 'Fp.Types.Storage.pas',
  Fp.System in 'Fp.System.pas',
  Fp.Types.Notifications in 'Fp.Types.Notifications.pas',
  Fp.Types.General in 'Fp.Types.General.pas',
  Fp.Utils.Dialogs in 'Fp.Utils.Dialogs.pas',
  Fp.Utils.Versioning in 'Fp.Utils.Versioning.pas',
  Fp.Utils.Shell in 'Fp.Utils.Shell.pas',
  Fp.Utils.General in 'Fp.Utils.General.pas',
  Fp.UI.ModMain in 'frm\Fp.UI.ModMain.pas' {ModMain: TDataModule},
  Fp.Resources.ImageLists in 'frm\Fp.Resources.ImageLists.pas' {ModImageLists: TDataModule},
  Fp.UI.FrmAbout in 'frm\Fp.UI.FrmAbout.pas' {FrmAbout},
  Fp.Types.Actions in 'Fp.Types.Actions.pas',
  Fp.UI.FraAction in 'frm\Fp.UI.FraAction.pas' {FraAction: TFrame},
  Fp.Types.FileActions in 'Fp.Types.FileActions.pas',
  FP.UI.FraStatus in 'frm\FP.UI.FraStatus.pas' {FraStatus: TFrame},
  Fp.Types.SequenceStorage in 'Fp.Types.SequenceStorage.pas',
  Fp.Types.SequenceExecutor in 'Fp.Types.SequenceExecutor.pas',
  Fp.Utils.Taskbar in 'Fp.Utils.Taskbar.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := Fp.Resources.Definitions.APP_TITLE;

  Fp.System.Initialize;

  Application.Run;
end.

unit Fp.Utils.Dialogs;

interface

uses

   Winapi.Windows, Winapi.Messages,
   Vcl.Forms;

type

   TMsgBoxIcon = (
      mbiError = MB_ICONERROR, mbiQuestion = MB_ICONQUESTION, mbiWarning = MB_ICONWARNING,
      mbiInformation = MB_ICONINFORMATION
   );

   TMsgBoxButtons = (
      mbbOk = MB_OK, mbbOkCancel = MB_OKCANCEL, mbbCancelTryContinue = $00000006, mbbYesNoCancel = MB_YESNOCANCEL,
      mbbYesNo = MB_YESNO, mbbRetryCancel = MB_RETRYCANCEL
   );

   TMsgBoxDefaultButtons = (
      mbdButton1 = MB_DEFBUTTON1, mbdButton2 = MB_DEFBUTTON2, mbdButton3 = MB_DEFBUTTON3, mbdButton4 = MB_DEFBUTTON4
   );

   TMsgBoxResult = (
      mbrOk = IDOK, mbrCancel = IDCANCEL, mbrAbort = IDABORT, mbrRetry = IDRETRY, mbrIgnore = IDIGNORE, mbrYes = IDYES,
      mbrNo = IDNO, mbrClose = IDCLOSE, mbrHelp = IDHELP, mbrTryAgain = IDTRYAGAIN, mbrContinue = IDCONTINUE
   );

{Globals}

   function MsgBox(
      const Text: String; const Caption: String = ''; const Icon: TMsgBoxIcon = mbiInformation;
      const Buttons: TMsgBoxButtons = mbbOk; const DefaultButton: TMsgBoxDefaultButtons = mbdButton1;
      const CaptionAuto: Boolean = True; const MoreFlags: Integer = 0
   ): TMsgBoxResult;

var

   MBC_ERROR: String; //= 'Erro';
   MBC_QUESTION: String; //= 'Confirmação';
   MBC_WARNING: String; //= 'Atenção';
   MBC_INFORMATION: String;// = 'Informação';

implementation

function MsgBox(
   const Text: String; const Caption: String = ''; const Icon: TMsgBoxIcon = mbiInformation;
   const Buttons: TMsgBoxButtons = mbbOk; const DefaultButton: TMsgBoxDefaultButtons = mbdButton1;
   const CaptionAuto: Boolean = True; const MoreFlags: Integer = 0
): TMsgBoxResult;
var
    cText, cCaption: PChar;
begin
    cText := PChar(Text);

    cCaption := #0;
    if not CaptionAuto then
        cCaption := PChar(Caption)
    else begin
        case Icon of
            mbiError: cCaption := PChar(MBC_ERROR);
            mbiQuestion: cCaption := PChar(MBC_QUESTION);
            mbiWarning: cCaption := PChar(MBC_WARNING);
            mbiInformation: cCaption := PChar(MBC_INFORMATION);
        end;
    end;

    Result := TMsgBoxResult(
        Application.MessageBox(cText, cCaption,
        Ord(Icon) + Ord(Buttons) + Ord(DefaultButton) + MoreFlags)
    );
end;

initialization

   MBC_ERROR := 'Error';
   MBC_QUESTION := 'Question';
   MBC_WARNING := 'Warning';
   MBC_INFORMATION := 'Information';

end.

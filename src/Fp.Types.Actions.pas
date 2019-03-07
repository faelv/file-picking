unit Fp.Types.Actions;

interface

uses

   System.Contnrs,
   Vcl.ActnList;

type
   
   TStateFlag = (
      asNeverSet,
      asIdle, asWorking, asPaused, asAnalyzing, asWaiting
   );

   TStateFlags = set of TStateFlag;

   TStateFlagsArray = array of TStateFlags;

   TActionStateControl = class(TObject)
      private
         FAction: TCustomAction;
         FFlags: TStateFlagsArray;
      public
         property Action: TCustomAction read FAction write FAction;
         property Flags: TStateFlagsArray read FFlags write FFlags;
         constructor Create(AAction: TCustomAction; AFlags: TStateFlagsArray);
   end;

   TActionStateManager = class(TObjectList)
      private
         FFlags: TStateFlags;
      public
         procedure New(Action: TCustomAction; const AFlags: array of TStateFlags);
         constructor Create;
         procedure Update;
         procedure SetFlags(const FlagsToAdd: TStateFlags = []; const FlagsToRemove: TStateFlags = []);
         procedure SetAbsoluteFlags(const AFlags: TStateFlags);
         property Flags: TStateFlags read FFlags;
   end;

implementation

{ TActionsNeedsList }

constructor TActionStateManager.Create;
begin
   FFlags := [];
   Self.OwnsObjects := True;
end;

procedure TActionStateManager.New(Action: TCustomAction; const AFlags: array of TStateFlags);
var
   SF: TStateFlagsArray;
   I: Integer;
begin
   SetLength(SF, Length(AFlags));
   for I := 0 to High(AFlags) do
      SF[I] := AFlags[I];

   Self.Add(TActionStateControl.Create(Action, SF));
end;

procedure TActionStateManager.SetAbsoluteFlags(const AFlags: TStateFlags);
begin
   FFlags := AFlags;
   Self.Update;
end;

procedure TActionStateManager.SetFlags(const FlagsToAdd, FlagsToRemove: TStateFlags);
begin
   FFlags := FFlags - FlagsToRemove;
   FFlags := FFlags + FlagsToAdd;

   Self.Update;
end;

procedure TActionStateManager.Update;
var
   curObjPtr: Pointer;
   curObjAcn: TActionStateControl;
   I: Integer;
begin
   for curObjPtr in Self do begin
      curObjAcn := TActionStateControl(curObjPtr);
      if curObjAcn.Action = nil then continue;

      for I := 0 to High(curObjAcn.Flags) do begin
         curObjAcn.Action.Enabled := (curObjAcn.Flags[I] <= Self.Flags);
         if curObjAcn.Action.Enabled then break;
      end;
   end;
end;

{ TActionNeeds }

constructor TActionStateControl.Create(AAction: TCustomAction; AFlags: TStateFlagsArray);
begin
   FAction := AAction;
   FFlags := AFlags;
end;

end.

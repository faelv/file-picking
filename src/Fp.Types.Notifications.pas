unit Fp.Types.Notifications;

interface

uses

  Winapi.Messages,
  System.Contnrs, System.SysUtils, System.Classes;

type

  TNotificationList = class;

  INotificationListener = interface['{2548289D-82F5-4631-8B24-3E7FBC15BEC9}']
      procedure NotificationListNotification(Msg: Integer; const Params: array of const; Sender: TObject; var StopBrodcast: Boolean);
      procedure NotificationListAdded(const NotificationList: TNotificationList);
      procedure NotificationListRemoved;
  end;

  TNotificationProgessEvent = procedure(const Sender, Target: TObject; const Current, Count, Msg: Integer; const Interrupted: Boolean) of object;

  TNotificationList = class(TObject)
    private
      FList: TObjectList;
      FOnProgress: TNotificationProgessEvent;
      procedure DoOnProgress(const Target: TObject; const Current, Msg: Integer; const Interrupted: Boolean);
    public
      constructor Create;
      destructor Destroy; override;
      procedure Add(Obj: TObject);
      procedure Remove(Obj: TObject);
      procedure Broadcast(aMsg: Integer; const aParams: array of const; Sender: TObject);
      property OnProgress: TNotificationProgessEvent read FOnProgress write FOnProgress;
  end;

implementation

{ TNotificationList }

constructor TNotificationList.Create;
begin
   FList := TObjectList.Create;
   FList.OwnsObjects := False;
end;

destructor TNotificationList.Destroy;
begin
   FList.Free;
   inherited;
end;

procedure TNotificationList.DoOnProgress(const Target: TObject; const Current, Msg: Integer; const Interrupted: Boolean);
begin
   if Assigned(FOnProgress) then
      FOnProgress(Self, Target, Current, FList.Count, Msg, Interrupted);
end;

procedure TNotificationList.Add(Obj: TObject);
var
   Intf: INotificationListener;
begin
   if (not Assigned(Obj)) or (not Supports(Obj, INotificationListener, Intf)) then exit;

   FList.Add(Obj);
   Intf.NotificationListAdded(Self);
end;

procedure TNotificationList.Remove(Obj: TObject);
var
   Intf: INotificationListener;
begin
   if (not Assigned(Obj)) or (not Supports(Obj, INotificationListener, Intf)) then exit;

   FList.Remove(Obj);
   Intf.NotificationListRemoved;
end;

procedure TNotificationList.Broadcast(aMsg: Integer; const aParams: array of const; Sender: TObject);
var
  curPtr: Pointer;
  curObj: TObject;
  curIntf: INotificationListener;
  stopBroadcast: Boolean;
begin
  stopBroadcast := False;

  for curPtr in FList do
  begin
    curObj := TObject(curPtr);
    if Assigned(curObj) then
    begin
      if (Supports(curObj, INotificationListener, curIntf)) then
        curIntf.NotificationListNotification(aMsg, aParams, Sender,
          stopBroadcast);

      Self.DoOnProgress(curObj, FList.IndexOf(curObj) + 1, aMsg, stopBroadcast);
      if stopBroadcast then
        break;
    end;
  end;
end;

end.

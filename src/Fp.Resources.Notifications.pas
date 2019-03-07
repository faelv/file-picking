unit Fp.Resources.Notifications;

interface

uses

  Winapi.Messages;

const

  NOTF_APP_SYSTEM_LOADED     = WM_APP + 100;
  NOTF_APP_SYSTEM_ACTIVE     = WM_APP + 101;
  NOTF_APP_TERMINATED        = WM_APP + 102;
  NOTF_APP_TRY_TERMINATE     = WM_APP + 103;
  NOTF_APP_NOT_TERMINATED    = WM_APP + 104;

  NOTF_ACTIONS_STARTED       = WM_APP + 200;
  NOTF_ACTIONS_PAUSED        = WM_APP + 201;
  NOTF_ACTIONS_FINISHED      = WM_APP + 202;
  NOTF_ACTIONS_ANALYZING     = WM_APP + 203;
  NOTF_ACTIONS_WORKING       = WM_APP + 204;
  NOTF_ACTIONS_RESUME        = WM_APP + 205;
  NOTF_ACTIONS_PROGRESS      = WM_APP + 206;
  NOTF_ACTIONS_PAUSING       = WM_APP + 207;
  NOTF_ACTIONS_STOPPING      = WM_APP + 208;
  NOTF_ACTIONS_RESUMING      = WM_APP + 209;
  NOTF_ACTIONS_FILE_STARTED  = WM_APP + 210;
  NOTF_ACTIONS_FILE_PROGRESS = WM_APP + 211;
  NOTF_ACTIONS_FILE_FINISHED = WM_APP + 212;
  NOTF_ACTIONS_FILE_ERROR    = WM_APP + 213;
  NOTF_ACTIONS_ACTION_PICKED = WM_APP + 214;

implementation

end.

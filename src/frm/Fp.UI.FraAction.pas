unit Fp.UI.FraAction;

interface

{$WARN SYMBOL_PLATFORM OFF}

uses
  Fp.System,
  Fp.Resources.ImageLists, Fp.Resources.Notifications,
  Fp.Utils.Shell, Fp.Utils.Dialogs,
  Fp.Types.LangStorage, Fp.Types.FileActions, Fp.Types.Storage, Fp.Types.Notifications,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Menus, Vcl.Grids, Winapi.msxml,
  System.IOUtils;

type

  TFraAction = class(TFrame, ILangStorageUser, IXmlStorageUser, INotificationListener)
    imgSourceDir: TImage;
    imgFilters: TImage;
    imgOp: TImage;
    bedtSourceDir: TButtonedEdit;
    lblSourceDir: TLabel;
    chkIncludeSubfolders: TCheckBox;
    lblFilters: TLabel;
    lblOp: TLabel;
    cboOperation: TComboBox;
    pnlFiltersWrapper: TPanel;
    pnlFilters: TPanel;
    pnlFilterProps: TPanel;
    splFilters: TSplitter;
    trvFilters: TTreeView;
    tbFilterCommands: TToolBar;
    tbtnFilterAdd: TToolButton;
    tbtnFilterDel: TToolButton;
    popFilterAdd: TPopupMenu;
    mnuNodeAnd: TMenuItem;
    mnuNodeOr: TMenuItem;
    N1: TMenuItem;
    mnuFilter: TMenuItem;
    imgDescr: TImage;
    lblDescr: TLabel;
    edtName: TEdit;
    lblAttribute: TLabel;
    lblComparison: TLabel;
    cboAttribute: TComboBox;
    cboComparison: TComboBox;
    lblValue: TLabel;
    stgValues: TStringGrid;
    lblFileTypes: TLabel;
    imgFileTypes: TImage;
    chkTypeNormal: TCheckBox;
    chkTypeReadOnly: TCheckBox;
    chkTypeHidden: TCheckBox;
    chkTypeSystem: TCheckBox;
    chkTypeOffline: TCheckBox;
    chkTypeEncrypted: TCheckBox;
    chkTypeSymlink: TCheckBox;
    imgDestDir: TImage;
    lblDestDir: TLabel;
    bedtDestDir: TButtonedEdit;
    lblOnFileExists: TLabel;
    cboOnFileExists: TComboBox;
    lblOnNotFileExists: TLabel;
    cboOnNotFileExists: TComboBox;
    mnuNodeAndRoot: TMenuItem;
    mnuNodeOrRoot: TMenuItem;
    N2: TMenuItem;
    chkDelEmptyDirs: TCheckBox;
    procedure bedtBrowseButtonClick(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure cboComparisonSelect(Sender: TObject);
    procedure stgValuesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtNameExit(Sender: TObject);
    procedure bedtSourceDirExit(Sender: TObject);
    procedure chkIncludeSubfoldersClick(Sender: TObject);
    procedure chkTypeClick(Sender: TObject);
    procedure trvFiltersClick(Sender: TObject);
    procedure cboAttributeSelect(Sender: TObject);
    procedure mnuFilterClick(Sender: TObject);
    procedure mnuNodeAndClick(Sender: TObject);
    procedure mnuNodeOrClick(Sender: TObject);
    procedure tbtnFilterDelClick(Sender: TObject);
    procedure bedtDestDirExit(Sender: TObject);
    procedure cboOperationSelect(Sender: TObject);
    procedure cboOnFileExistsSelect(Sender: TObject);
    procedure cboOnNotFileExistsSelect(Sender: TObject);
    procedure stgValuesSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
    procedure mnuNodeAndRootClick(Sender: TObject);
    procedure mnuNodeOrRootClick(Sender: TObject);
    procedure chkDelEmptyDirsClick(Sender: TObject);
  private
    FAction: TFpAction;

    procedure ResetFilterPropsUI;
    procedure LoadFiltersUI(FilterNodeList: TFpFilterNodeList; TreeNode: TTreeNode);
    procedure LoadFiltersPropsUI(Filter: TFpFilter);
    procedure LoadUI;
    function MakeFilterText(Filter: TFpFilter): String;
    function GetSelectedFilter: TFpFilter;
    function GetSelectedFilterNode: TFpFilterNode;
    procedure AddFilterNode(const Kind: TFilterNodeKind; const Root: Boolean = False);
    procedure SetSequenceAction(const Value: TFpAction);
    procedure UpdateSelectedFilter;
  public //ILangStorageUser, IStorageUser, INotificationListener
    procedure OnLoadLangStrings(Node: IXMLDOMNode);
    function GetLangStorageName: String;
    procedure OnNodeLoad(Node: IXMLDOMNode);
    procedure OnNodeSave(Node: IXMLDOMNode);
    function GetStorageName: String;
    procedure NotificationListNotification(Msg: Integer; const Params: array of const; Sender: TObject; var StopBrodcast: Boolean);
    procedure NotificationListAdded(const NotificationList: TNotificationList);
    procedure NotificationListRemoved;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ResetUI;
    property SequenceAction: TFpAction read FAction write SetSequenceAction;
  end;

implementation

{$R *.dfm}

constructor TFraAction.Create(AOwner: TComponent);
begin
  inherited;

  Notifications.Add(Self);

  Language.Storage.AddUser(Self);
  Language.Storage.ReloadSingle(Self);

  Settings.Storage.AddUser(Self);
  Settings.Storage.ReloadSingle(Self);

  Self.Align := alClient;
  pnlFiltersWrapper.Anchors := [akLeft, akTop, akRight, akBottom];
  splFilters.Color := Self.Color;

  chkTypeSymlink.Enabled := OS_VISTA;
end;

destructor TFraAction.Destroy;
begin
  inherited;
end;

procedure TFraAction.FrameResize(Sender: TObject);
begin
  stgValues.DefaultColWidth := stgValues.ClientWidth -1;
end;

{BEGIN - Interfaces}

function TFraAction.GetStorageName: String;
begin
  Result := 'fraaction';
end;

procedure TFraAction.OnNodeSave(Node: IXMLDOMNode);
begin
  IXMLDOMElement(Node).setAttribute('filterPropsW', pnlFilterProps.Width);
end;

procedure TFraAction.OnNodeLoad(Node: IXMLDOMNode);
begin
  pnlFilterProps.Width := TXmlStorage.GetNodeAttributeDef(
    Node, 'filterPropsW', pnlFilterProps.Width
  );
end;

function TFraAction.GetLangStorageName: String;
begin
  Result := 'fraaction';
end;

procedure TFraAction.OnLoadLangStrings(Node: IXMLDOMNode);
begin
  Language.SetComponentStrings(Self, Node);
end;

procedure TFraAction.NotificationListNotification(Msg: Integer;
  const Params: array of const; Sender: TObject; var StopBrodcast: Boolean);
begin

end;

procedure TFraAction.NotificationListAdded(const NotificationList: TNotificationList);
begin
end;

procedure TFraAction.NotificationListRemoved;
begin
end;

{END - Interfaces}

{BEGIN - Methods}

procedure TFraAction.SetSequenceAction(const Value: TFpAction);
begin
  if FAction = Value then exit;

  FAction := nil;
  Self.ResetUI;

  FAction := Value;
  Self.LoadUI;

  if FAction = nil then
    Self.Visible := False
  else
    Self.Visible := True;
end;

procedure TFraAction.ResetUI;
begin
  edtName.Clear;
  bedtSourceDir.Clear;
  bedtDestDir.Clear;
  cboOperation.ItemIndex := -1;
  cboOnFileExists.ItemIndex := -1;
  cboOnNotFileExists.ItemIndex := -1;
  chkIncludeSubfolders.Checked := False;
  chkDelEmptyDirs.Checked := False;
  chkTypeNormal.Checked := False;
  chkTypeReadOnly.Checked := False;
  chkTypeHidden.Checked := False;
  chkTypeSystem.Checked := False;
  chkTypeOffline.Checked := False;
  chkTypeEncrypted.Checked := False;
  chkTypeSymlink.Checked := False;

  trvFilters.Items.Clear;
  Self.ResetFilterPropsUI;
end;

procedure TFraAction.ResetFilterPropsUI;
begin
  cboAttribute.ItemIndex := -1;
  cboComparison.ItemIndex := -1;
  stgValues.RowCount := 1;
  stgValues.Cells[0,0] := '';

  cboAttribute.Enabled := False;
  cboComparison.Enabled := False;
  stgValues.Enabled := False;
end;

function TFraAction.MakeFilterText(Filter: TFpFilter): String;
var
  attr, comp, val: String;
  I: Integer;
begin
  case Filter.Attribute of
    faName: attr := Language.Strings('attrName');
    faExtension: attr := Language.Strings('attrExt');
    faPath: attr := Language.Strings('attrPath');
    faSize: attr := Language.Strings('attrSize');
    faCreated: attr := Language.Strings('attrCreated');
    faModified: attr := Language.Strings('attrModified');
  end;

  case Filter.Comparison of
    fcEqual: comp := Language.Strings('compEqual');
    fcNotEqual: comp := Language.Strings('compNotEqual');
    fcGreater: comp := Language.Strings('compGreater');
    fcGreaterEqual: comp := Language.Strings('compGreaterEqual');
    fcSmaller: comp := Language.Strings('compSmaller');
    fcSmallerEqual: comp := Language.Strings('compSmallerEqual');
    fcIn: comp := Language.Strings('compIn');
    fcNotIn: comp := Language.Strings('compNotIn');
    fcContains: comp := Language.Strings('compContains');
    fcNotContains: comp := Language.Strings('compNotContains');
  end;

  if Filter.Values.Count > 1 then begin
    val := '(';
    for I := 0 to Filter.Values.Count -1 do begin
      if I > 0 then val := val + ', ';
      val := val + Filter.Values[I];
    end;
    val := val + ')';
  end
  else if Filter.Values.Count = 1 then
    val := '''' + Filter.Values[0] + ''''
  else
    val := '';

  if Length(val) > 30 then begin
    SetLength(val, 27);
    val := val + '...';
  end;

  Result := attr + ' ' + comp + ' ' + val;
end;

procedure TFraAction.LoadFiltersUI(FilterNodeList: TFpFilterNodeList;
  TreeNode: TTreeNode);
var
  S: String;
  newTreeNode: TTreeNode;
  filter: TFpFilter;
  filterNode: TFpFilterNode;
begin
  for filterNode in FilterNodeList do begin
    case filterNode.Kind of
      fkAnd: S := Language.Strings('filterAnd');
      fkOr: S := Language.Strings('filterOr');
    end;
    newTreeNode := trvFilters.Items.AddChildObject(TreeNode, S, filterNode);
    newTreeNode.ImageIndex := Ord(Icons16Index.i16Node);
    newTreeNode.SelectedIndex := newTreeNode.ImageIndex;
    newTreeNode.ExpandedImageIndex := newTreeNode.ImageIndex;
    for filter in filterNode.Items do begin
      with trvFilters.Items.AddChildObject(newTreeNode, MakeFilterText(filter), filter) do begin
        ImageIndex := Ord(Icons16Index.i16Filter);
        SelectedIndex := ImageIndex;
        ExpandedImageIndex := ImageIndex;
      end;
    end;
    LoadFiltersUI(filterNode.Nodes, newTreeNode);
  end;
end;

procedure TFraAction.LoadUI;
begin
  if not Assigned(FAction) then exit;

  edtName.Text := FAction.Description;
  bedtSourceDir.Text := FAction.SourceFolder;
  bedtDestDir.Text := FAction.DestFolder;

  cboOperation.ItemIndex := Ord(FAction.Operation);
  cboOnFileExists.ItemIndex := Ord(FAction.FileExistsDecision);
  cboOnNotFileExists.ItemIndex := Ord(FAction.FileNotExistsDecision);
  chkIncludeSubfolders.Checked := FAction.IncludeSubFolders;
  chkDelEmptyDirs.Checked := FAction.DeleteEmptyFolders;

  cboOnFileExists.Enabled := not(FAction.Operation = okDelete);
  cboOnNotFileExists.Enabled := not(FAction.Operation = okDelete);

  chkTypeNormal.Checked := (TFileAttribute.faArchive in FAction.FileTypes);
  chkTypeReadOnly.Checked := (TFileAttribute.faReadOnly in FAction.FileTypes);
  chkTypeHidden.Checked := (TFileAttribute.faHidden in FAction.FileTypes);
  chkTypeSystem.Checked := (TFileAttribute.faSystem in FAction.FileTypes);
  chkTypeOffline.Checked := (TFileAttribute.faOffline in FAction.FileTypes);
  chkTypeEncrypted.Checked := (TFileAttribute.faEncrypted in FAction.FileTypes);
  if OS_VISTA then
    chkTypeSymlink.Checked := (TFileAttribute.faSymLink in FAction.FileTypes);

  LoadFiltersUI(FAction.Filters, nil);

  trvFilters.FullExpand;
  trvFilters.Selected := nil;
end;

function TFraAction.GetSelectedFilter: TFpFilter;
var
  dataObj: TObject;
begin
  Result := nil;
  if trvFilters.Selected <> nil then begin
    dataObj := TObject(trvFilters.Selected.Data);
    if (dataObj is TFpFilter) then
      Result := TFpFilter(dataObj);
  end;
end;

function TFraAction.GetSelectedFilterNode: TFpFilterNode;
var
  dataObj: TObject;
begin
  Result := nil;
  if trvFilters.Selected <> nil then begin
    dataObj := TObject(trvFilters.Selected.Data);
    if (dataObj is TFpFilterNode) then
      Result := TFpFilterNode(dataObj);
  end;
end;

procedure TFraAction.LoadFiltersPropsUI(Filter: TFpFilter);
var
  I: Integer;
begin
  cboAttribute.Enabled := True;
  cboComparison.Enabled := True;
  stgValues.Enabled := True;

  cboAttribute.ItemIndex := Ord(Filter.Attribute);
  cboComparison.ItemIndex := Ord(Filter.Comparison);
  if Filter.Values.Count = 0 then
    stgValues.RowCount := 1
  else
    stgValues.RowCount := Filter.Values.Count;

    for I := 0 to Filter.Values.Count-1 do
      stgValues.Cells[0,I] := Filter.Values[I];
end;

procedure TFraAction.AddFilterNode(const Kind: TFilterNodeKind; const Root: Boolean);
var
  selNode, newFilterNode: TFpFilterNode;
  selNodeList: TFpFilterNodeList;
  selTreeNode, newTreeNode: TTreeNode;
  S: String;
begin
  if not Assigned(FAction) then exit;

  if Kind = fkAnd then
    S := Language.Strings('filterAnd')
  else
    S := Language.Strings('filterOr');

  selTreeNode := nil;
  selNode := nil;
  if not Root then
    selNode := Self.GetSelectedFilterNode;

  if not Assigned(selNode) then
    selNodeList := FAction.Filters
  else begin
    selNodeList := selNode.Nodes;
    selTreeNode := trvFilters.Selected;
  end;

  newFilterNode := selNodeList.New;
  newFilterNode.Kind := Kind;

  newTreeNode := trvFilters.Items.AddChildObject(selTreeNode, S, newFilterNode);
  newTreeNode.ImageIndex := Ord(Icons16Index.i16Node);
  newTreeNode.SelectedIndex := newTreeNode.ImageIndex;
  newTreeNode.ExpandedImageIndex := newTreeNode.ImageIndex;

  trvFilters.Selected := newTreeNode;
end;

{END - Methods}

{BEGIN - Control Events}

procedure TFraAction.edtNameExit(Sender: TObject);
begin
  if Assigned(FAction) then
    FAction.Description := edtName.Text;
end;

procedure TFraAction.bedtDestDirExit(Sender: TObject);
begin
  if Assigned(FAction) then
    FAction.DestFolder := TButtonedEdit(Sender).Text;
end;

procedure TFraAction.bedtSourceDirExit(Sender: TObject);
begin
  if Assigned(FAction) then
    FAction.SourceFolder := TButtonedEdit(Sender).Text;
end;

procedure TFraAction.bedtBrowseButtonClick(Sender: TObject);
var
  folder: String;
begin
  if not BrowseForFolder(Language.Strings('selFolder'), folder, Self.Handle) then exit;
  TButtonedEdit(Sender).Text := folder;
end;

procedure TFraAction.chkTypeClick(Sender: TObject);
var
  fa: TFileAttributes;
begin
  if not Assigned(FAction) then exit;

  if Sender = chkTypeNormal then
    fa := [TFileAttribute.faArchive]
  else if Sender = chkTypeReadOnly then
    fa := [TFileAttribute.faReadOnly]
  else if Sender = chkTypeHidden then
    fa := [TFileAttribute.faHidden]
  else if Sender = chkTypeSystem then
    fa := [TFileAttribute.faSystem]
  else if Sender = chkTypeOffline then
    fa := [TFileAttribute.faOffline]
  else if Sender = chkTypeEncrypted then
    fa := [TFileAttribute.faEncrypted]
  else if (Sender = chkTypeSymlink) and OS_VISTA then
    fa := [TFileAttribute.faSymLink];

  if TCheckBox(Sender).Checked then
    FAction.FileTypes := FAction.FileTypes + fa
  else
    FAction.FileTypes := FAction.FileTypes - fa;
end;

procedure TFraAction.chkDelEmptyDirsClick(Sender: TObject);
begin
  if Assigned(FAction) then
    FAction.DeleteEmptyFolders := TCheckBox(Sender).Checked;
end;

procedure TFraAction.chkIncludeSubfoldersClick(Sender: TObject);
begin
  if Assigned(FAction) then
    FAction.IncludeSubFolders := TCheckBox(Sender).Checked;
end;

procedure TFraAction.cboOnFileExistsSelect(Sender: TObject);
begin
  if Assigned(FAction) then
    FAction.FileExistsDecision := TFpOnExistsDecision(TComboBox(Sender).ItemIndex);
end;

procedure TFraAction.cboOnNotFileExistsSelect(Sender: TObject);
begin
  if Assigned(FAction) then
    FAction.FileNotExistsDecision := TFpOnNotExistsDecision(TComboBox(Sender).ItemIndex);
end;

procedure TFraAction.cboOperationSelect(Sender: TObject);
begin
  if Assigned(FAction) then begin
    FAction.Operation := TFpOperationKind(TComboBox(Sender).ItemIndex);
    cboOnFileExists.Enabled := not(FAction.Operation = okDelete);
    cboOnNotFileExists.Enabled := not(FAction.Operation = okDelete);
  end;
end;

procedure TFraAction.cboAttributeSelect(Sender: TObject);
var
  selFilter: TFpFilter;
begin
  selFilter := Self.GetSelectedFilter;
  if (not Assigned(selFilter)) or (cboAttribute.ItemIndex < 0) then exit;

  selFilter.Attribute := TFpFileAttributes(cboAttribute.ItemIndex);
  Self.UpdateSelectedFilter;
end;

procedure TFraAction.cboComparisonSelect(Sender: TObject);
var
  selFilter: TFpFilter;
begin
  selFilter := Self.GetSelectedFilter;

  if (not Assigned(selFilter)) or (cboComparison.ItemIndex < 0) then exit;

  if TFpComparison(cboComparison.ItemIndex) in [fcIn, fcNotIn] then begin
    stgValues.RowCount := 10;
  end else begin
    stgValues.RowCount := 1;
  end;
  stgValues.Cells[0,0] := '';

  selFilter.Comparison := TFpComparison(cboComparison.ItemIndex);
  selFilter.Values.Clear;
  Self.UpdateSelectedFilter;
end;

procedure TFraAction.stgValuesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  sel: TGridRect;
begin
  if (TFpComparison(cboComparison.ItemIndex) in [fcIn, fcNotIn])
  and (stgValues.Selection.Top = stgValues.RowCount-1)
  and (Key = VK_DOWN) then begin
    stgValues.RowCount := stgValues.RowCount + 1;
    sel := stgValues.Selection;
    sel.Top := sel.Top + 1;
    stgValues.Selection := sel;
  end;
end;

procedure TFraAction.stgValuesSetEditText(Sender: TObject; ACol, ARow: Integer;
  const Value: string);
var
  selFilter: TFpFilter;
begin
  selFilter := Self.GetSelectedFilter;
  if not Assigned(selFilter) then exit;

  if ARow > (selFilter.Values.Count-1) then
    selFilter.Values.Append(Value)
  else
    selFilter.Values[ARow] := Value;

  Self.UpdateSelectedFilter;
end;

procedure TFraAction.trvFiltersClick(Sender: TObject);
var
  selFilter: TFpFilter;
begin
  selFilter := Self.GetSelectedFilter;

  if not Assigned(selFilter) then
    Self.ResetFilterPropsUI
  else
    Self.LoadFiltersPropsUI(selFilter);
end;

procedure TFraAction.UpdateSelectedFilter;
var
  selFilter: TFpFilter;
begin
  selFilter := Self.GetSelectedFilter;
  if Assigned(selFilter) then
    trvFilters.Selected.Text := MakeFilterText(selFilter);
end;

procedure TFraAction.tbtnFilterDelClick(Sender: TObject);
var
  dataObj: TObject;
  parentList: TFpFilterList;
  parentNodeList: TFpFilterNodeList;
begin
  if trvFilters.Selected = nil then exit;

  dataObj := TObject(trvFilters.Selected.Data);
  if (dataObj is TFpFilterNode) then begin
      parentNodeList := TFpFilterNode(dataObj).Parent;
      parentNodeList.Remove(TFpFilterNode(dataObj));
  end
  else if (dataObj is TFpFilter) then begin
    parentList := TFpFilter(dataObj).Parent;
    parentList.Remove(TFpFilter(dataObj));
  end;

  trvFilters.Selected.Delete;
  Self.ResetFilterPropsUI;
end;

procedure TFraAction.mnuFilterClick(Sender: TObject);
var
  selNode: TFpFilterNode;
  newFilter: TFpFilter;
  newTreeNode: TTreeNode;
begin
  if not Assigned(FAction) then exit;

  selNode := Self.GetSelectedFilterNode;

  if not Assigned(selNode) then begin
    MsgBox(Language.Strings('addFilterFail'));
    exit;
  end;

  newFilter := selNode.Items.New;
  newTreeNode := trvFilters.Items.AddChildObject(
    trvFilters.Selected,
    MakeFilterText(newFilter),
    newFilter
  );
  newTreeNode.ImageIndex := Ord(Icons16Index.i16Filter);
  newTreeNode.SelectedIndex := newTreeNode.ImageIndex;
  newTreeNode.ExpandedImageIndex := newTreeNode.ImageIndex;

  trvFilters.Selected := newTreeNode;
  Self.LoadFiltersPropsUI(newFilter);
end;

procedure TFraAction.mnuNodeAndClick(Sender: TObject);
begin
  Self.AddFilterNode(fkAnd);
end;

procedure TFraAction.mnuNodeAndRootClick(Sender: TObject);
begin
  Self.AddFilterNode(fkAnd, True);
end;

procedure TFraAction.mnuNodeOrClick(Sender: TObject);
begin
  Self.AddFilterNode(fkOr);
end;

procedure TFraAction.mnuNodeOrRootClick(Sender: TObject);
begin
  Self.AddFilterNode(fkOr, True);
end;

{END - Control Events}

{$WARN SYMBOL_PLATFORM ON}

end.

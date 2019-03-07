unit Fp.Resources.ImageLists;

interface

uses
  System.SysUtils, System.Classes, Vcl.ImgList, Vcl.Controls;

type
  TModImageLists = class(TDataModule)
    Icons26: TImageList;
    Icons16: TImageList;
    IconsDisabled26: TImageList;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  Icons26Index = (
    i26Cog=15
  );

  Icons16Index = (
    i16Filter=3,
    i16Node=4,
    i16Play=6,
    i16Check=8,
    i16Cross=9,
    i16Cog=11
  );

var
  ModImageLists: TModImageLists;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.

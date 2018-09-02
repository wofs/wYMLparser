unit Unit1;

{$mode objfpc}{$H+}

{$DEFINE YMLExtended}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  laz2_DOM, laz2_xmlread,
  wYMLparser,
  ExtCtrls, StdCtrls, ComCtrls;

type

  TwTreeNode = class(TTreeNode)
    private
      fID: integer;
    public
      property ID: integer read fID write fID;
    end;

  { TTreeView }

  TTreeView = class(ComCtrls.TTreeView)
  protected
    function CreateNode: TwTreeNode; override;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    btnLoadYML: TButton;
    m1: TMemo;
    mOfferInfo: TMemo;
    od1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    StringGrid1: TStringGrid;
    TreeView1: TTreeView;
    procedure btnLoadYMLClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StringGrid1Selection(Sender: TObject; aCol, aRow: Integer);
    procedure TreeView1Click(Sender: TObject);
  private
    Catalog: TYML;
    procedure FillGrid(const aCategoty: integer = 0);
    procedure FillTree(aCategoriesArr: ArrayOfCategories);
    procedure GetOfferInfo(const aOffer: string = '');

  public
    procedure Log(AText: string);

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TTreeView }

function TTreeView.CreateNode: TwTreeNode;
begin
//  Result:=inherited CreateNode;
  Result := TwTreeNode.Create(Items);
end;

{ TForm1 }


procedure TForm1.Log(AText: string);
begin
  m1.Lines.Add(DateTimeToStr(now)+' | '+AText);
  //m1.Lines.Add(AText);
  Application.ProcessMessages;
end;

procedure TForm1.FillTree(aCategoriesArr: ArrayOfCategories); // заполнение дерева
var
  i, iTree: integer;
  NewNode: TwTreeNode;
begin

  with TreeView1 do
  begin
    BeginUpdate;
    Items.Clear;

    NewNode:= TwTreeNode(Items.Add(nil, aCategoriesArr[0].name));
    NewNode.ID:= aCategoriesArr[0].id;

    for i := 0 to High(aCategoriesArr)-1 do
    begin

      iTree := 0;
      while iTree < Items.Count do
      begin
        if TwTreeNode(Items.Item[iTree]).ID =  aCategoriesArr[i+1].parentId then
        begin
          NewNode:= TwTreeNode(Items.AddChild(TwTreeNode(Items.Item[iTree]), Catalog.DecodeText(aCategoriesArr[i+1].name)));
          NewNode.ID:= aCategoriesArr[i+1].id;
          break;
        end;
        Inc(iTree);
      end;

    end;

    Items[0].Expand(false);
    Selected:= Items[0];
    EndUpdate;
  end;
end;

procedure TForm1.FillGrid(const aCategoty: integer);
var
  i: integer;
  _Offers: ArrayOfOffers;
begin
  if Assigned(Catalog) then _Offers:= Catalog.GetOffersByCategory(aCategoty) else exit;

  with StringGrid1 do
  begin
     RowCount:= High(_Offers)+2;

     for i:=0 to High(_Offers) do
        begin
          Cells[1,i+1]:=_Offers[i].id;
          Cells[2,i+1]:=Catalog.DecodeText(_Offers[i].vendorcode);
          Cells[3,i+1]:=Catalog.DecodeText(_Offers[i].name);
          Cells[4,i+1]:=Catalog.DecodeText(_Offers[i].model);
          Cells[5,i+1]:=FloatToStr(_Offers[i].price);
        end;
  end;
end;

procedure TForm1.btnLoadYMLClick(Sender: TObject);
var
  _YMLFile, _Name: string;
  _arr: ArrayOfCategories;
  _arrOffers: ArrayOfOffers;

  i: Integer;
begin

  try
    if od1.Execute then
      _YMLFile := od1.FileName
    else
      exit;
      m1.Lines.Clear;

      if Assigned(Catalog) then Catalog.Free;


      Catalog:= TYML.Create(_YMLFile);
      Log('Open '+_YMLFile);

      Screen.Cursor:= crHourGlass;
      Application.ProcessMessages;

      Catalog.Open();
      Log('Open [OK]');

      with m1.Lines do
      begin
        Add('Shop details:');
        Add('company = '+ Catalog.Shop.company);
        Add('name = '+ Catalog.Shop.name);
        Add('url = '+ Catalog.Shop.url);
        Add('phone = '+ Catalog.Shop.phone);
        Add('email = '+ Catalog.Shop.email);
        Add('cpa = '+ IntToStr(Catalog.Shop.cpa));
        Add('platform = '+ Catalog.Shop.platform);
        Add('version = '+ Catalog.Shop.version);
        Add('agency = '+ Catalog.Shop.agency);
        Add(IntToStr(High(Catalog.Offers)+1)+' offers in '+IntToStr(High(Catalog.Categories)+1)+' categories.');
      end;


     _arr:= Catalog.Categories;

      SetLength(_arr,High(_arr)+2);
      _arr[High(_arr)].id:=0;
      _arr[High(_arr)].parentId:=-1;
      _arr[High(_arr)].name:='Root';

      _arr:= Catalog.SortedCategoriesByParentId(_arr);

      FillTree(_arr);

      FillGrid();
      Screen.Cursor:= crDefault;
  except
    on E: Exception do
    begin
      Screen.Cursor:= crDefault;
      m1.Lines.EndUpdate;
      Log(E.ClassName+' | '+E.Message);
    end;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(Catalog) then
    Catalog.Free;
end;

procedure TForm1.GetOfferInfo(const aOffer: string);
var
  i: integer;
  _Offer: TOffer;
begin
  if (Length(aOffer) = 0) or not Assigned(Catalog) then exit;

  _Offer:= Catalog.GetOfferByID(aOffer);

  with  mOfferInfo.Lines do
  begin
    BeginUpdate;
    clear;
    Add('id = ' + _Offer.id);
    {$ifdef YMLExtended}
      Add('product_id_1c = ' + IntToStr(_Offer.product_id_1c));
    {$endif}
    case _Offer.currencyId of
      criEUR: Add('currenty = EUR');
      criUSD: Add('currenty = USD');
      criKZT: Add('currenty = KZT');
      criRUR: Add('currenty = RUR');
      criUAH: Add('currenty = UAH');
      criBYN: Add('currenty = BYN');
      criNONE: Add('currenty = NONE');
    end;
    Add('url = ' + _Offer.url);
    Add('categoryId = ' + IntToStr(_Offer.categoryId));
    Add('name = ' + Catalog.DecodeText(_Offer.name));
    Add('model = ' + Catalog.DecodeText(_Offer.model));
    Add('vendorcode = ' + Catalog.DecodeText(_Offer.vendorCode));
    Add('vendor = ' + Catalog.DecodeText(_Offer.vendor));
    Add('oldprice = ' + FloatToStr(_Offer.oldprice));
    Add('price = ' + FloatToStr(_Offer.price));
    {$ifdef YMLExtended}
      Add('key_partner = ' + FloatToStr(_Offer.key_partner));
    {$endif}
    for i:=0 to High(_Offer.barcode) do
        Add('barcode = '+_Offer.barcode[i]);
    for i:=0 to High(_Offer.picture) do
        Add('picture = '+_Offer.picture[i]);

    Add('sales_notes = ' + Catalog.DecodeText(_Offer.sales_notes));
    Add('min-quantity = ' + IntToStr(_Offer.min_quantity));
    Add('step-quantity = ' + IntToStr(_Offer.step_quantity));
    Add('country_of_origin = ' + Catalog.DecodeText(_Offer.country_of_origin));
    Add('cpa = ' + IntToStr(_Offer.cpa));
    Add('expiry = ' + _Offer.expiry);
    Add('weight = ' + _Offer.weight);
    Add('dimensions = ' + _Offer.dimensions);
    Add('group_id = ' + IntToStr(_Offer.group_id));
    Add('bid = ' + IntToStr(_Offer.bid));
    Add('cbid = ' + IntToStr(_Offer.cbid));
    Add('fee = ' + IntToStr(_Offer.fee));
    Add('rec = ' + _Offer.rec);
    Add('type = ' + _Offer.type_);
    Add('typePrefix = ' + Catalog.DecodeText(_Offer.typePrefix));
    {$ifdef YMLExtended}
      Add('quantity = ' + IntToStr(_Offer.quantity));
    {$endif}
    for i:=0 to High(_Offer.outlets) do
       begin
        Add('outlets/outlet: id = '+IntToStr(_Offer.outlets[i].id)+' instock = '+IntToStr(_Offer.outlets[i].instock));
       end;

    for i:=0 to High(_Offer.param) do
       begin
        Add('param: name = '+Catalog.DecodeText(_Offer.param[i].name)+' unit = '+_Offer.param[i].unit_+' text = '+_Offer.param[i].text);
       end;

    if _Offer.downloadable then Add('downloadable = TRUE') else Add('downloadable = FALSE');
    if _Offer.pickup then Add('pickup = TRUE') else Add('pickup = FALSE');
    if _Offer.store then Add('store = TRUE') else Add('store = FALSE');
    if _Offer.delivery then Add('delivery = TRUE') else Add('delivery = FALSE');
    for i:=0 to High(_Offer.delivery_options) do
       begin
        Add('delivery-options/option: cost = '+IntToStr(_Offer.delivery_options[i].cost)+' days = '+_Offer.delivery_options[i].days+' order_before = '+IntToStr(_Offer.delivery_options[i].order_before));
       end;

    if _Offer.manufacturer_warranty then Add('manufacturer_warranty = TRUE') else Add('manufacturer_warranty = FALSE');
    if _Offer.adult then Add('adult = TRUE') else Add('adult = FALSE');
    if _Offer.available then Add('available = TRUE') else Add('available = FALSE');


    for i:=0 to High(_Offer.age) do
       begin
        Add('age: month = '+IntToStr(_Offer.age[i].month)+' year = '+IntToStr(_Offer.age[i].year));
       end;

    Add('description = ' + Catalog.DecodeText(_Offer.description));

    Add('');
    Add('More information about the format: https://yandex.ru/support/partnermarket/export/yml.html');
    EndUpdate;
  end;

end;

procedure TForm1.StringGrid1Selection(Sender: TObject; aCol, aRow: Integer);
var
  _aOffer: string;
begin
  _aOffer:= TStringGrid(Sender).Cells[1,aRow];
  GetOfferInfo(_aOffer);
end;

procedure TForm1.TreeView1Click(Sender: TObject);
begin
  if TTreeView(Sender).Items.Count = 0 then exit;
  FillGrid(TwTreeNode(TTreeView(Sender).Selected).ID);
end;

end.

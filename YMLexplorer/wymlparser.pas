unit wYMLparser;
// YML Parser
// v. 0.0.1.10
//
// wofs(c)2017-2018 [wofssirius@yandex.ru]
// GNU LESSER GENERAL PUBLIC LICENSE v.2.1
//
// Git: https://github.com/wofs/wYMLparser.git
//
// to work with win1251 files use win1251decoder https://github.com/wofs/win1251decoder.git
//

{$mode objfpc}{$H+}

{$DEFINE YMLExtended}

interface

uses
  Classes, SysUtils,
  DOM, xmlread
  ;

type
    TCurrencyID = (criEUR, criUSD, criKZT, criRUR, criUAH, criBYN, criNONE);

    //Param
    TParam = packed record
       name: string;
       unit_: string;
       text: string;
    end;

    //Age
    TAge = packed record
       year: byte;
       month: byte;
    end;

    //Outlets
    TOutlets = packed record
       id: integer;
       instock: integer;
    end;

    // DeliveryOptions
    TDeliveryOptions = packed record
       cost: integer;
       days: string;
       order_before: byte;
    end;

    // Currency
    TCurrency = packed record
       id: TCurrencyID;
       rate: Double;
    end;

    // Category
    TCategory = packed record
       id: integer;
       parentId: integer;
       name: string;
    end;

    // Offer
    ArrayOfOutlets =  array of TOutlets;
    ArrayOfAge = array of TAge;
    ArrayOfParams = array of TParam;
    ArrayOfBarcode = array of string;
    ArrayOfPicture = array of string;
    ArrayOfDeliveryOptions = array of TDeliveryOptions;

    TOffer = packed record
       id: string;
       url: string;
       oldprice: double;
       price: double;
       price_from: boolean;
       currencyId: TCurrencyID;
       categoryId: integer;
       name: string;
       vendorCode: string;
       model: string;
       barcode: ArrayOfBarcode;
       vendor: string;
       picture: ArrayOfPicture;
       delivery: boolean;
       pickup: boolean;
       store: boolean;
       delivery_options: ArrayOfDeliveryOptions;
       outlets: ArrayOfOutlets;
       description: string;
       sales_notes: string;
       min_quantity: integer;
       step_quantity: integer;
       manufacturer_warranty: boolean;
       country_of_origin: string;
       adult: boolean;
       age: ArrayOfAge;
       cpa: byte;
       param: ArrayOfParams;
       expiry: string;
       weight: string;
       dimensions: string;
       downloadable: boolean;
       group_id: integer;
       bid: integer;
       cbid: integer;
       fee: integer;
       available: boolean;
       rec: string;
       type_: string;
       typePrefix: string;

       {$ifdef YMLExtended}
         product_id_1c: integer;
         quantity: integer;
         key_partner: double;
       {$endif}

    end;

    ArrayOfCurrencies =  array of TCurrency;
    ArrayOfCategories = array of TCategory;
    ArrayOfOffers =  array of TOffer;

    // Shop
    TShop = packed record
       name: string;
       company: string;
       url: string;
       phone: string;
       platform: string;
       version: string;
       agency: string;
       email: string;
       cpa: byte;
       delivery_options: ArrayOfDeliveryOptions;
    end;

    { TYML }

    // Catalog
    TYML = class
       private
         fDecimalSeparator: Char;
         fYMLFile: string;

         Document: TXMLDocument;
         Node: TDOMNode;

         fDate: string;

         fShop: TShop;

         fCurrencies: ArrayOfCurrencies;
         fCategories: ArrayOfCategories;
         fOffers: ArrayOfOffers;

         function GetCurrencies(aNode: TDOMNode): ArrayOfCurrencies;
         function GetCategories(aNode: TDOMNode):ArrayOfCategories;
         function GetCurrencyID(aCurrencyString: string): TCurrencyID;
         function GetOffers(aNode: TDOMNode):ArrayOfOffers;
         procedure GetShop();
         function TryStrToByte(const s: string; out i: Byte): boolean;

       public

         constructor Create(aYMLFile: string);
         destructor Destroy; override;

         function Open(): boolean;

         function SortedCategoriesByParentId(aCategories: ArrayOfCategories): ArrayOfCategories;
         function GetChildrenCategories(aCategory: integer): ArrayOfCategories;
         function GetOffersByCategory(aCategory:integer):ArrayOfOffers;
         function GetOfferByID(aID:string):TOffer;
         function DecodeText(aText: string; const QuotedShield: boolean=false): string;

         property YMLFile: string read fYMLFile write fYMLFile;
         property Date: string read fDate write fDate;
         property Shop: TShop read fShop;

         property Currencies: ArrayOfCurrencies read fCurrencies write fCurrencies;
         property Categories: ArrayOfCategories read fCategories write fCategories;
         property Offers: ArrayOfOffers read fOffers write fOffers;

    end;

implementation

{ TYML }

constructor TYML.Create(aYMLFile: string);
begin
  fYMLFile:= aYMLFile;
  fDecimalSeparator:= DefaultFormatSettings.DecimalSeparator;
end;

destructor TYML.Destroy;
begin
    Currencies:= nil;
    Categories:= nil;
    Offers:= nil;
end;

function TYML.TryStrToByte(const s: string; out i : Byte) : boolean;
var Error : word;
begin
  Val(s, i, Error);
  if (Error = 0) and (i>=0) and (i<=255) then
      Result:= true else
    begin
      Result:= false;
      i:=0;
    end;
end;

function TYML.Open: boolean;
begin
  try
    result:= true;

    try
      ReadXMLFile(Document, YMLFile);

      GetShop; // GetShop
    finally
      Document.Free;
    end;

  except
    Result:=false;
    raise;
  end;
end;

function TYML.GetChildrenCategories(aCategory: integer): ArrayOfCategories;
var
  i: Integer;
  k: Integer;
begin
  try
    Result:=nil;

    SetLength(Result,High(Categories));
    k:=0;

    for i:=0 to High(Categories) do
    begin
       if Categories[i].parentId = aCategory then
       begin
         inc(k);
         Result[k-1]:=Categories[i];
       end;
    end;
    SetLength(Result,k);

  except
    Result:=nil;
    raise;
  end;

end;

function TYML.GetOffersByCategory(aCategory: integer): ArrayOfOffers;
var
  i: Integer;
  k: Integer;
begin
  try
    Result:=nil;
    if aCategory = 0 then
    begin
      Result:= Offers;
      exit;
    end;

    k:=0;

    SetLength(Result,High(Offers));

    k:=0;
    for i:=0 to High(Offers) do
    begin
       if Offers[i].categoryId = aCategory then
       begin
         inc(k);
         Result[k-1]:=Offers[i];
       end;
    end;

    SetLength(Result,k);
  except
    Result:=nil;
    raise;
  end;

end;

function TYML.GetOfferByID(aID: string): TOffer;
var
  i: Integer;
  k: Integer;
begin
  try
    if Length(aID) = 0 then exit;

    for i:=0 to High(Offers) do
    begin
       if Offers[i].id = aID then
       begin
         Result:=Offers[i];
         break;
       end;
    end;
  except
    raise;
  end;
end;

function TYML.GetCurrencyID(aCurrencyString: string):TCurrencyID;
begin
  case aCurrencyString of
   'EUR': Result:= criEUR;
   'USD': Result:= criUSD;
   'RUB': Result:= criRUR; // sometimes write so
   'RUR': Result:= criRUR;
   'KZT': Result:= criKZT;
   'UAH': Result:= criUAH;
   'BYN': Result:= criBYN;
   else
      Result:= criNONE;
  end;
end;

function TYML.GetCurrencies(aNode: TDOMNode): ArrayOfCurrencies;
var
  n: Integer;
begin

    try
      Result := nil;
      n := 0;

      if not Assigned(aNode) then exit;

        with aNode.ChildNodes do  //currency
        begin
          try
            SetLength(Result, Count);

            for n:=0 to Count-1 do
            begin
               if Assigned(Item[n].Attributes) then

                 Result[n].id:= GetCurrencyID(Item[n].Attributes[0].NodeValue);
                 TryStrToFloat(StringReplace(Item[n].Attributes[1].NodeValue,'.',fDecimalSeparator,[rfReplaceAll]), Result[n].rate);
            end;
          finally
            Free;
          end;
        end;  //aNode.ChildNodes

  except
    Result:=nil;
    raise;
  end;

end;

function TYML.GetCategories(aNode: TDOMNode): ArrayOfCategories;
var
n: Integer;
begin
    try
      Result := nil;

     if not Assigned(aNode) then exit;

        with aNode.ChildNodes do //category
        begin
          try
           SetLength(Result, Count);

           for n:=0 to Count-1 do
           begin
              if Assigned(Item[n].Attributes) then
                if Item[n].Attributes.Length = 2 then
                begin
                  TryStrToInt(Item[n].Attributes[0].NodeValue, Result[n].id);
                  TryStrToInt(Item[n].Attributes[1].NodeValue, Result[n].parentId);
                end
                else
                begin
                  TryStrToInt(Item[n].Attributes[0].NodeValue, Result[n].id);
                  Result[n].parentId:= 0;
                end;

              Result[n].name := Item[n].TextContent;

           end;

          finally
            Free;
          end;

        end;
  except
    Result:=nil;
    raise;
  end;
end;

function TYML.GetOffers(aNode: TDOMNode): ArrayOfOffers;
var
  i, k, j, n: Integer;
  ChildNode: TDOMNode;
        //i - Nodies Count
        //n - NodeCildrens Count
        //k - Attributes.Items Count
        //j - Result.resultArray Count
begin
    try
      Result := nil;
      ChildNode:= nil;
      i:= 0;

      if not Assigned(aNode) then exit;

      with aNode.ChildNodes do
      begin
        try
          SetLength(Result,Count);
        finally
          Free;
        end;
      end;

      aNode := aNode.FirstChild; // offer

      while Assigned(aNode) do
      begin

       Inc(i);

        // id
        if (aNode.HasAttributes) and (aNode.Attributes.Length > 0) then
        begin
          for k:=0 to aNode.Attributes.Length-1 do
          begin

            case aNode.Attributes[k].NodeName of
              'id'         : Result[i-1].id:= aNode.Attributes[k].NodeValue;
              'group_id'   : TryStrToInt(aNode.Attributes[k].NodeValue,Result[i-1].group_id);
              'bid'        : TryStrToInt(aNode.Attributes[k].NodeValue,Result[i-1].bid);
              'cbid'       : TryStrToInt(aNode.Attributes[k].NodeValue,Result[i-1].cbid);
              'fee'        : TryStrToInt(aNode.Attributes[k].NodeValue,Result[i-1].fee);
              'available'  :
                begin
                  case LowerCase(aNode.Attributes[k].NodeValue) of
                    'false': Result[i-1].available:= false;
                    'true' : Result[i-1].available:= true
                    else Result[i-1].available:= false;
                  end;
                end;
              'type'      : Result[i-1].type_:= aNode.Attributes[k].NodeValue;
            end;
          end;
        end;

        with aNode.ChildNodes do   // offer
        begin
          try

            for n:=0 to Count-1 do
            begin

              case Item[n].NodeName of
                'url'            : Result[i-1].url:= Item[n].TextContent;
                {$ifdef YMLExtended}
                  'product_id_1c'  : TryStrToInt(Item[n].TextContent,Result[i-1].product_id_1c);
                  'quantity'       : TryStrToInt(Item[n].TextContent,Result[i-1].quantity);
                  'key_partner'    : TryStrToFloat(StringReplace(Item[n].TextContent,'.',fDecimalSeparator,[rfReplaceAll]),Result[i-1].key_partner);
                {$endif}
                'oldprice'       : TryStrToFloat(StringReplace(Item[n].TextContent,'.',fDecimalSeparator,[rfReplaceAll]),Result[i-1].oldprice);
                'price'          :
                                 begin
                                  TryStrToFloat(StringReplace(Item[n].TextContent,'.',fDecimalSeparator,[rfReplaceAll]),Result[i-1].price);
                                   if Assigned(Item[n].Attributes) then
                                   begin
                                     for k:=0 to Item[n].Attributes.Length-1 do
                                     begin
                                       case Item[n].Attributes[k].NodeName of
                                         'from':
                                               begin
                                                  case LowerCase(Item[n].Attributes[k].NodeValue) of
                                                    'false': Result[i-1].price_from:= false;
                                                    'true': Result[i-1].price_from:= true
                                                    else Result[i-1].price_from:= false;
                                                  end;
                                               end;
                                       end;
                                     end;
                                   end else Result[i-1].price_from:= false;
                                 end;
                'currencyId'     : Result[i - 1].currencyId:= GetCurrencyID(Item[n].TextContent);
                'categoryId'     : TryStrToInt(Item[n].TextContent,Result[i-1].categoryId);
                'name'           : Result[i-1].name:= Item[n].TextContent;
                'vendorCode'     : Result[i-1].vendorCode:= Item[n].TextContent;
                'barcode'        :
                                  begin
                                   if not Assigned(Result[i-1].barcode) then
                                     j:= 0
                                   else
                                     j:= High(Result[i-1].barcode)+1;

                                   SetLength(Result[i-1].barcode,j+1);
                                   Result[i-1].barcode[j]:= Item[n].TextContent;
                                  end;
                'typePrefix'      : Result[i-1].typePrefix:= Item[n].TextContent;
                'vendor'          : Result[i-1].vendor:= Item[n].TextContent;
                'model'           : Result[i-1].model:= Item[n].TextContent;
                'picture'         :
                                  begin
                                    if not Assigned(Result[i-1].picture) then
                                      j:= 0
                                    else
                                      j:= High(Result[i-1].picture)+1;

                                    SetLength(Result[i-1].picture,j+1);
                                    Result[i-1].picture[j]:= Item[n].TextContent;
                                  end;
                'delivery'        :
                                  begin
                                   case LowerCase(Item[n].TextContent) of
                                     'false': Result[i-1].delivery:= false;
                                     'true': Result[i-1].delivery:= true
                                     else Result[i-1].delivery:= false;
                                   end;
                                  end;
                'pickup'          :
                                   begin
                                     case LowerCase(Item[n].TextContent) of
                                       'false': Result[i-1].pickup:= false;
                                       'true': Result[i-1].pickup:= true
                                       else Result[i-1].pickup:= false;
                                     end;
                                   end;
                'store'           :
                                   begin
                                     case LowerCase(Item[n].TextContent) of
                                       'false': Result[i-1].store:= false;
                                       'true': Result[i-1].store:= true
                                       else Result[i-1].store:= false;
                                     end;
                                   end;
                'delivery-options':
                                   begin
                                     ChildNode:=nil;
                                     ChildNode:=Item[n];

                                     if Assigned(ChildNode) then
                                     begin
                                       with ChildNode.ChildNodes do
                                       begin
                                        try
                                          SetLength(Result[i-1].delivery_options,Count);
                                          for j:=0 to Count-1 do
                                          begin
                                              if Assigned(Item[j].Attributes) then
                                              begin
                                                for k:=0 to Item[j].Attributes.Length-1 do
                                                begin
                                                  case Item[j].Attributes[k].NodeName of
                                                    'cost': TryStrToInt(Item[j].Attributes[k].NodeValue,Result[i-1].delivery_options[j].cost);
                                                    'days': Result[i-1].delivery_options[j].days:= Item[j].Attributes[k].NodeValue;
                                                    'order-before': TryStrToByte(Item[j].Attributes[k].NodeValue,Result[i-1].delivery_options[j].order_before);
                                                  end;
                                                end;
                                              end;
                                          end;
                                        finally
                                          Free;
                                        end;
                                       end; //with ChildNodes
                                     end;

                                     ChildNode:=nil;
                                   end;
                'description'      : Result[i-1].description:= Item[n].TextContent;
                'sales_notes'      : Result[i-1].sales_notes:= Item[n].TextContent;
                'min-quantity'     : TryStrToInt(ChildNode.TextContent,Result[i-1].min_quantity);
                'step-quantity'    : TryStrToInt(ChildNode.TextContent,Result[i-1].step_quantity);
                'manufacturer_warranty':
                                   begin
                                     case LowerCase(Item[n].TextContent) of
                                       'false': Result[i-1].manufacturer_warranty:= false;
                                       'true': Result[i-1].manufacturer_warranty:= true
                                       else Result[i-1].manufacturer_warranty:= false;
                                     end;
                                   end;
                'country_of_origin': Result[i-1].country_of_origin:= Item[n].TextContent;
                'adult'            :
                                   begin
                                     case LowerCase(Item[n].TextContent) of
                                       'false': Result[i-1].adult:= false;
                                       'true': Result[i-1].adult:= true
                                       else Result[i-1].adult:= false;
                                     end;
                                   end;
                'cpa'              : TryStrToByte(Item[n].TextContent,Result[i-1].cpa);
                'expiry'           : Result[i-1].expiry:= Item[n].TextContent;
                'weight'           : Result[i-1].weight:= Item[n].TextContent;
                'dimensions'       : Result[i-1].dimensions:= Item[n].TextContent;
                'downloadable'     :
                                   begin
                                     case LowerCase(Item[n].TextContent) of
                                       'false': Result[i-1].downloadable:= false;
                                       'true': Result[i-1].downloadable:= true
                                       else Result[i-1].downloadable:= false;
                                     end;
                                   end;
                'rec'              : Result[i-1].rec:= Item[n].TextContent;
                'outlets'          :
                                   begin
                                     ChildNode:=nil;
                                     ChildNode:=Item[n];

                                     if Assigned(ChildNode) then
                                     begin
                                       with ChildNode.ChildNodes do
                                       begin
                                        try
                                          SetLength(Result[i-1].outlets,Count);
                                          for j:=0 to Count-1 do
                                          begin
                                              if Assigned(Item[j].Attributes) then
                                              begin
                                                for k:=0 to Item[j].Attributes.Length-1 do
                                                begin
                                                  case Item[j].Attributes[k].NodeName of
                                                    'id': TryStrToInt(Item[j].Attributes[k].NodeValue,Result[i-1].outlets[j].id);
                                                    'instock': TryStrToInt(Item[j].Attributes[k].NodeValue,Result[i-1].outlets[j].instock);
                                                  end;
                                                end;
                                              end;
                                          end;
                                        finally
                                          Free;
                                        end;
                                       end; //with ChildNodes
                                     end;
                                     ChildNode:=nil;
                                   end;
                'param'            :
                                   begin

                                     if not Assigned(Result[i-1].param) then
                                       j:= 0
                                     else
                                       j:= High(Result[i-1].param)+1;

                                     SetLength(Result[i-1].param,j+1);

                                     if Assigned(Item[n].Attributes) then
                                     begin
                                       for k:=0 to Item[n].Attributes.Length-1 do
                                       begin
                                         case Item[n].Attributes[k].NodeName of
                                           'name': Result[i-1].param[j].name:= Item[n].Attributes[k].NodeValue;
                                           'unit': Result[i-1].param[j].unit_:= Item[n].Attributes[k].NodeValue;
                                         end;
                                       end;
                                     end;

                                     Result[i-1].param[j].text:= Item[n].TextContent;
                                   end;
                'age'              :
                                   begin
                                     if Assigned(Item[n].Attributes) then
                                     begin
                                       j:=0;
                                       for k:=0 to Item[n].Attributes.Length-1 do
                                       begin
                                         inc(j);
                                         case aNode.Attributes[k].NodeName of
                                           'unit' :
                                             begin
                                               case Item[n].Attributes[k].NodeValue of
                                                'year'  : TryStrToByte(Item[n].TextContent,Result[i-1].age[j-1].year);
                                                'month' : TryStrToByte(Item[n].TextContent,Result[i-1].age[j-1].month);
                                               end;
                                             end;
                                         end;
                                       end;
                                     end;
                                   end;

              end; //case
            end; //for n:=0 to Count-1

          finally
            Free;
          end;
        end;
         aNode := aNode.NextSibling;
      end; //while asigned

  except
    Result:=nil;
    raise;
  end;
end;

procedure TYML.GetShop;
var
  ChildNode: TDOMNode;
  n, j, k: Integer;
begin
  try
      try
          Node := Document.DocumentElement;
          ChildNode:= nil;

          if Assigned(Node) then
          begin
            if Node.NodeName = 'yml_catalog' then
            begin
               if Assigned(Node.Attributes) then
                    Date:=Node.Attributes[0].NodeValue;
            end;

           if Node.NodeName<>'shop' then
                 Node := Node.FindNode('shop');
          end;

          if Assigned(Node) then
          begin
            with Node.ChildNodes do
            begin
             try
               for n:=0 to Count-1 do
               begin
                  case Item[n].NodeName of
                    'name'              : fShop.name:= Item[n].TextContent;
                    'company'           : fShop.company:= Item[n].TextContent;
                    'url'               : fShop.url:= Item[n].TextContent;
                    'phone'             : fShop.phone:= Item[n].TextContent;
                    'platform'          : fShop.platform:= Item[n].TextContent;
                    'version'           : fShop.version:= Item[n].TextContent;
                    'agency'            : fShop.agency:= Item[n].TextContent;
                    'email'             : fShop.email:= Item[n].TextContent;
                    'cpa'               : TryStrToByte(Item[n].TextContent,fShop.cpa);
                    'currencies'        : Currencies:= GetCurrencies(Item[n]);
                    'categories'        : Categories:= GetCategories(Item[n]);
                    'delivery-options'  :
                                         begin
                                           ChildNode:=nil;
                                           ChildNode:=Item[n];

                                           if Assigned(ChildNode) then
                                           begin
                                             with ChildNode.ChildNodes do
                                             begin
                                              try
                                                SetLength(fShop.delivery_options,Count);
                                                for j:=0 to Count-1 do
                                                begin
                                                    if Assigned(Item[j].Attributes) then
                                                    begin
                                                      for k:=0 to Item[j].Attributes.Length-1 do
                                                      begin
                                                        case Item[j].Attributes[k].NodeName of
                                                          'cost': TryStrToInt(Item[j].Attributes[k].NodeValue,fShop.delivery_options[j].cost);
                                                          'days': fShop.delivery_options[j].days:= Item[j].Attributes[k].NodeValue;
                                                          'order-before': TryStrToByte(Item[j].Attributes[k].NodeValue,fShop.delivery_options[j].order_before);
                                                        end;
                                                      end;
                                                    end;
                                                end;
                                              finally
                                                Free;
                                              end;
                                             end; //with ChildNodes
                                           end;

                                           ChildNode:=nil;
                                         end;
                    'offers'            : Offers:= GetOffers(Item[n]);
                  end;
               end;
             finally
               Free;
             end;
            end; //with ChildNodes
          end;

      finally
        Node.Free;
      end;
  except
    raise;
  end;
end;

function TYML.SortedCategoriesByParentId(aCategories: ArrayOfCategories): ArrayOfCategories;
var
  bis, i, j, k : integer;
  temp: TCategory;
begin
if High(aCategories) > 0 then bis := High(aCategories) else exit;
k   := bis shr 1; // div 2
while k > 0 do begin
   for i := 0 to bis -k do begin
     j := i;
     while j >= 0 do begin
       if aCategories[j].parentId <= aCategories[j +k].parentId then break;
       temp := aCategories[j];
       aCategories[j] := aCategories[j+k];
       aCategories[j+k] := temp;
       if j > k then Dec(j, k) else j := 0;
     end;
   end;
   k := k shr 1; // div 2
end;
Result:= aCategories;
end;

function TYML.DecodeText(aText: string; const QuotedShield: boolean = false): string; // decode htmlEnt
const
  TagArr: array[1..5] of string = ('&lt;','&gt;','&amp;','&quot;','&apos;');
  CodeArr: array[1..5] of char = (#60,#62,#38,#34,#39);//< > & " '
var
  i: Integer;
  //<       &lt;
  //>       &gt;
  //&       &amp;
  //"       &quot;
  //'       &apos;
begin
  if QuotedShield then Result:= StringReplace(aText,#39,#39+#39,[rfReplaceAll, rfIgnoreCase]) else Result:=aText;

  for i:=1 to High(TagArr) do
    begin
      Result:= StringReplace(Result,TagArr[i],CodeArr[i],[rfReplaceAll, rfIgnoreCase]); //&amp;
    end;
end;

end.

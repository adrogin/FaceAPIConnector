codeunit 50101 "Microsoft Face API Connector"
{
    var
        FaceNotFoundErr: TextConst ENU = 'Could not detect face in the image';

    procedure AddFaceToGroup();
    begin

    end;

    procedure DeleteFaceFromGroup();
    begin

    end;

    procedure DetectFaceInBlobSource(Image: Record TempBlob): Text;
    var
        ImageStream: InStream;
    begin
        Image.Blob.CreateInStream(ImageStream);
        exit(DetectFace('application/octet-stream', ImageStream));
    end;

    procedure DetectFaceInUrlSource(Url: Text): Text;
    var
        JObj: JsonObject;
        OutStr: OutStream;
        InStr: InStream;
        TempBlob: Record TempBlob;
    begin
        // Wrap the URL in a JSon object and send the JSon content to an InStream
        JObj.Add('url', Url);
        TempBlob.Blob.CreateOutStream(OutStr);
        JObj.WriteTo(OutStr);

        TempBlob.Blob.CreateInStream(InStr);
        exit(DetectFace('application/json', InStr));
    end;

    local procedure DetectFace(ContentType: Text; ContentStream: InStream): Text;
    var
        MicrosoftFaceAPISetup: Record "Microsoft Face API Setup";
        AlHttpClient: HttpClient;
        MsgContent: HttpContent;
        ResponseMsg: HttpResponseMessage;
        RequestUrl: Text;
        JsonString: Text;
    begin
        MicrosoftFaceAPISetup.get;

        RequestUrl := StrSubstNo('https://%1.%2', MicrosoftFaceAPISetup.Location, MicrosoftFaceAPISetup."Base Url");
        AlHttpClient.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365 BC');
        SetContentHeaders(MsgContent, ContentType, MicrosoftFaceAPISetup."Subscription Key");

        RequestUrl := ConcatenateUrl(RequestUrl, MicrosoftFaceAPISetup.Method) + '?returnFaceAttributes=' + GetAttributesString;
        MsgContent.WriteFrom(ContentStream);

        if not AlHttpClient.Post(RequestUrl, MsgContent, ResponseMsg) then
            Error('HTTP request failed');

        ResponseMsg.Content.ReadAs(JsonString);
        exit(JsonString)
    end;

    local procedure SetContentHeaders(var MsgContent: HttpContent; ContentType: Text; SubscriptionKey: Text);
    var
        MsgHeaders: HttpHeaders;
    begin
        MsgContent.GetHeaders(MsgHeaders);
        MsgHeaders.Clear;
        MsgHeaders.Add('Content-Type', ContentType);
        MsgHeaders.Add('Ocp-Apim-Subscription-Key', SubscriptionKey);
    end;

    local procedure ConcatenateUrl(BaseUrl: Text; ResourceName: Text): Text;
    begin
        if BaseUrl[StrLen(BaseUrl)] <> '/' then
            BaseUrl := BaseUrl + '/';

        exit(BaseUrl + ResourceName);
    end;

    local procedure ConcatString(BaseText: Text; NewText: Text; SeparatorText: Text[10]): Text
    begin
        if BaseText = '' then
            exit(NewText);

        exit(BaseText + SeparatorText + NewText);
    end;

    local procedure GetAttributesString() Attributes: Text;
    var
        FaceAPISetupAttr: Record "Microsoft Face API Setup Attr.";
        NoAttributesSelectedErr: TextConst ENU = 'At least one attribute must be selected in the Microsoft Face API Setup';
    begin
        FaceAPISetupAttr.SetRange(Enabled, true);
        if FaceAPISetupAttr.FindSet then
            repeat
                Attributes := ConcatString(Attributes, FaceAPISetupAttr.Name, ',');
            until FaceAPISetupAttr.Next = 0;

        if Attributes = '' then
            Error(NoAttributesSelectedErr);
    end;

    local procedure FormatArrayOutput(JArr: JsonArray; ParentTokenName: Text[50]) Result: Text;
    var
        JTok: JsonToken;
    begin
        foreach JTok in JArr do begin
            if JTok.IsObject then
                exit(FormatObjectOutput(JTok.AsObject(), ParentTokenName));

            exit(JTok.AsValue().AsText());
        end;
    end;

    local procedure FormatObjectOutput(JObj: JsonObject; ParentTokenName: Text[50]) Result: Text;
    var
        FaceAPISetupAttr: Record "Microsoft Face API Setup Attr.";
        JTok: JsonToken;
        ParentAttrID: Integer;
        TokenText: Text[50];
    begin
        FaceAPISetupAttr.SetRange(Name, ParentTokenName);
        FaceAPISetupAttr.FindFirst;
        ParentAttrID := FaceAPISetupAttr.id;

        FaceAPISetupAttr.Reset();
        FaceAPISetupAttr.SetRange("Parent Attribute", ParentAttrID);
        if FaceAPISetupAttr.FindSet then
            repeat
                JObj.SelectToken(FaceAPISetupAttr.Name, JTok);

                if JTok.IsArray then
                    TokenText := FormatArrayOutput(JTok.AsArray(), FaceAPISetupAttr.Name)
                else
                    if JTok.IsObject then
                        TokenText := FormatObjectOutput(JTok.AsObject(), FaceAPISetupAttr.Name)
                    else
                        TokenText := JTok.AsValue().AsText();

                if Result <> '' then
                    Result := Result + '; ';
                Result := Result + FaceAPISetupAttr.Name + ': ' + TokenText;
            until FaceAPISetupAttr.Next = 0;
    end;

    local procedure FormatTokenOutput(JTok: JsonToken; ParentAttrName: Text[50]): Text;
    begin
        if JTok.IsObject then
            exit(FormatObjectOutput(JTok.AsObject(), ParentAttrName));

        if JTok.IsArray then
            exit(FormatArrayOutput(JTok.AsArray(), ParentAttrName));

        exit(JTok.AsValue.AsText);
    end;

    procedure GetAttributesFromResponseString(var AttrNameValueBuf: Record "Name/Value Buffer"; JsonString: Text);
    var
        APISetup: Record "Microsoft Face API Setup";
        APISetupAttr: Record "Microsoft Face API Setup Attr.";
        JObj: JsonObject;
        JTok: JsonToken;
        JArr: JsonArray;
    begin
        APISetup.Get;
        AttrNameValueBuf.DeleteAll;
        if not JArr.ReadFrom(JsonString) then
            Error(JsonString);

        if not JArr.Get(0, JTok) then
            Error(FaceNotFoundErr);

        JObj := JTok.AsObject;
        if not JObj.SelectToken(APISetup."Attributes Token", JTok) then
            Error(FaceNotFoundErr);

        JObj := JTok.AsObject;

        APISetupAttr.SetRange(Enabled, true);
        if APISetupAttr.FindSet then
            repeat
                AttrNameValueBuf.ID += 1;
                AttrNameValueBuf.Name := APISetupAttr.Name;
                JObj.SelectToken(APISetupAttr.Name, JTok);
                AttrNameValueBuf.Value := FormatTokenOutput(JTok, APISetupAttr.Name);
                AttrNameValueBuf.Insert;
            until APISetupAttr.Next = 0;
    end;
}
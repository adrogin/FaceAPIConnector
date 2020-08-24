codeunit 50101 "Microsoft Face API Connector"
{
    var
        FaceNotFoundErr: TextConst ENU = 'Could not detect face in the image';
        HttpStatusCodeTok: Label 'statusCode';
        BCUserAgentTok: Label 'Dynamics 365 BC';
        HttpRequestFailedErr: Label 'HTTP request failed';

    procedure CreatePersonGroup(GroupId: Text[64]; DisplayName: Text[128]; Description: Text; RecognitionModel: Text): Text
    var
        AlHttpClient: HttpClient;
        MsgContent: HttpContent;
        ResponseMsg: HttpResponseMessage;
        JsonBody: JsonObject;
        TextBody: Text;
        RequestUrl: Text;
        EndpointUri: Text;
    begin
        PrepareRequestHeaders(AlHttpClient, MsgContent, 'application/json');

        EndpointUri := 'persongroups/%1';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GroupId));
        JsonBody.Add('name', GroupId);
        JsonBody.Add('userData', DisplayName);
        JsonBody.Add('recognitionModel', RecognitionModel);
        JsonBody.WriteTo(TextBody);

        MsgContent.WriteFrom(TextBody);
        if not AlHttpClient.Put(RequestUrl, MsgContent, ResponseMsg) then
            Error(HttpRequestFailedErr);

        exit(SerializeResponseMessage(ResponseMsg));
    end;

    procedure DeletePersonGroup(GroupId: Text[64]): Text
    var
        MicrosoftFaceApiSetup: Record "Microsoft Face API Setup";
        AlHttpClient: HttpClient;
        ResponseMsg: HttpResponseMessage;
        RequestUrl: Text;
        EndpointUri: Text;
    begin
        MicrosoftFaceAPISetup.Get();
        AlHttpClient.DefaultRequestHeaders.Add('User-Agent', BCUserAgentTok);
        AlHttpClient.DefaultRequestHeaders.Add('Ocp-Apim-Subscription-Key', MicrosoftFaceAPISetup."Subscription Key");

        EndpointUri := 'persongroups/%1';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GroupId));

        if not AlHttpClient.Delete(RequestUrl, ResponseMsg) then
            Error(HttpRequestFailedErr);

        exit(SerializeResponseMessage(ResponseMsg));
    end;

    procedure UpdatePersonGroup(GroupId: Text[64]; DisplayName: Text[128]; Description: Text): Text
    var
        AlHttpClient: HttpClient;
        MsgContent: HttpContent;
        RequestMessage: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        JsonBody: JsonObject;
        TextBody: Text;
        RequestUrl: Text;
        EndpointUri: Text;
    begin
        PrepareRequestHeaders(AlHttpClient, MsgContent, 'application/json');

        EndpointUri := 'persongroups/%1';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GroupId));
        JsonBody.Add('name', GroupId);
        JsonBody.Add('userData', DisplayName);
        JsonBody.WriteTo(TextBody);

        MsgContent.WriteFrom(TextBody);

        RequestMessage.Content(MsgContent);
        RequestMessage.Method('PATCH');
        RequestMessage.SetRequestUri(RequestUrl);
        if not AlHttpClient.Send(RequestMessage, ResponseMsg) then
            Error(HttpRequestFailedErr);

        exit(SerializeResponseMessage(ResponseMsg));
    end;

    procedure CreatePersonInGroup(GroupId: Text[64]; PersonName: Text[128]; AddInfo: Text; var ResponseString: Text): Boolean
    var
        AlHttpCLient: HttpClient;
        MsgContent: HttpContent;
        ResponseMsg: HttpResponseMessage;
        JsonBody: JsonObject;
        Token: JsonToken;
        TextBody: Text;
        RequestUrl: Text;
        EndpointUri: Text;
    begin
        PrepareRequestHeaders(AlHttpCLient, MsgContent, 'application/json');

        EndpointUri := 'persongroups/%1/persons';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GroupId));

        JsonBody.Add('name', PersonName);
        JsonBody.Add('userData', AddInfo);
        JsonBody.WriteTo(TextBody);
        MsgContent.WriteFrom(TextBody);

        if not AlHttpClient.Post(RequestUrl, MsgContent, ResponseMsg) then
            Error(HttpRequestFailedErr);

        if ResponseMsg.HttpStatusCode = 200 then
            exit(GetJsonObjectValue(ResponseMsg, ResponseString, 'personId'));

        ResponseMsg.Content.ReadAs(ResponseString);
        JsonBody.ReadFrom(ResponseString);
        if JsonBody.Get('error', Token) then
            Token.WriteTo(ResponseString);

        exit(false);
    end;

    procedure AddFaceToGroup(GroupId: Text[64]; PersonId: Text; var ContentStream: InStream; ResponseString: Text): Boolean
    var
        ALHttpCLient: HttpClient;
        MsgContent: HttpContent;
        ResponseMsg: HttpResponseMessage;
        RequestUrl: Text;
        EndpointUri: Text;
    begin
        PrepareRequestHeaders(ALHttpCLient, MsgContent, 'application/octet-stream');

        // https://{endpoint}/face/v1.0/persongroups/{personGroupId}/persons/{personId}/persistedFaces[?userData][&targetFace][&detectionModel]
        EndpointUri := 'persongroups/%1/persons/%2/persistedFaces';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GroupId, PersonId));
        MsgContent.WriteFrom(ContentStream);

        if not AlHttpClient.Post(RequestUrl, MsgContent, ResponseMsg) then
            Error(HttpRequestFailedErr);

        if ResponseMsg.HttpStatusCode = 200 then
            exit(GetJsonObjectValue(ResponseMsg, ResponseString, 'persistedFaceId'));

        ResponseMsg.Content.ReadAs(ResponseString);
        exit(false)
    end;

    procedure DeleteFaceFromGroup();
    var
        MicrosoftFaceAPISetup: Record "Microsoft Face API Setup";
        AlHttpClient: HttpClient;
    begin
        MicrosoftFaceAPISetup.Get();
        AlHttpClient.DefaultRequestHeaders.Add('User-Agent', BCUserAgentTok);
        //SetContentHeaders(MsgContent, ContentType, MicrosoftFaceAPISetup."Subscription Key");
    end;

    procedure DetectFaceInFileSource(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        FileMgt.BLOBImport(TempBlob, '');
        exit(DetectFaceInBlobSource(TempBlob));
    end;

    procedure DetectFaceInBlobSource(var TempBlobImage: Codeunit "Temp Blob"): Text
    var
        ImageStream: InStream;
    begin
        TempBlobImage.CreateInStream(ImageStream);
        exit(DetectFace('application/octet-stream', ImageStream));
    end;

    procedure DetectFaceInCameraSource(): Text
    var
        CameraInteraction: Page "Camera Interaction";
        PictureStream: InStream;
    begin
        CameraInteraction.RunModal();
        if CameraInteraction.GetPicture(PictureStream) then
            exit(DetectFace('application/octet-stream', PictureStream));
    end;

    procedure DetectFaceInUrlSource(Url: Text): Text
    var
        JObj: JsonObject;
        OutStr: OutStream;
        InStr: InStream;
        TempBlob: Codeunit "Temp Blob";
    begin
        // Wrap the URL in a JSon object and send the JSon content to an InStream
        JObj.Add('url', Url);
        TempBlob.CreateOutStream(OutStr);
        JObj.WriteTo(OutStr);

        TempBlob.CreateInStream(InStr);
        exit(DetectFace('application/json', InStr));
    end;

    local procedure DetectFace(ContentType: Text; ContentStream: InStream): Text
    var
        AlHttpClient: HttpClient;
        MsgContent: HttpContent;
        ResponseMsg: HttpResponseMessage;
        RequestUrl: Text;
        EndpointUri: Text;
        ResponseString: Text;
    begin
        PrepareRequestHeaders(AlHttpClient, MsgContent, ContentType);

        // detect = MicrosoftFaceAPISetup.Method
        EndpointUri := 'detect?returnFaceAttributes=%1';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GetAttributesString));
        MsgContent.WriteFrom(ContentStream);

        if not AlHttpClient.Post(RequestUrl, MsgContent, ResponseMsg) then
            Error(HttpRequestFailedErr);

        ResponseMsg.Content.ReadAs(ResponseString);
        exit(ResponseString)
    end;

    local procedure SerializeResponseMessage(var ResponseMsg: HttpResponseMessage): Text
    var
        ResponseString: Text;
        ContentBody: JsonObject;
        ResponseArray: JsonArray;
        HttpStatus: JsonObject;
    begin
        ResponseMsg.Content.ReadAs(ResponseString);
        ContentBody.ReadFrom(ResponseString);

        HttpStatus.Add(HttpStatusCodeTok, ResponseMsg.HttpStatusCode);

        ResponseArray.Add(HttpStatus);
        ResponseArray.Add(ContentBody);
        ResponseArray.WriteTo(ResponseString);

        exit(ResponseString);
    end;

    local procedure GetJsonObjectValue(var ResponseMessage: HttpResponseMessage; var ResponseString: Text; KeyName: Text): Boolean
    var
        MsgString: Text;
        JsonMsg: JsonObject;
        Token: JsonToken;
    begin
        ResponseMessage.Content.ReadAs(MsgString);
        if not JsonMsg.ReadFrom(MsgString) then
            exit(false);

        if not JsonMsg.Get(KeyName, Token) then
            exit(false);

        ResponseString := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure PrepareRequestHeaders(var AlHttpClient: HttpClient; var MsgContent: HttpContent; ContentType: Text)
    var
        MicrosoftFaceAPISetup: Record "Microsoft Face API Setup";
    begin
        MicrosoftFaceAPISetup.Get();
        AlHttpClient.DefaultRequestHeaders.Add('User-Agent', BCUserAgentTok);
        SetContentHeaders(MsgContent, ContentType, MicrosoftFaceAPISetup."Subscription Key");
    end;

    local procedure GetBaseRequestUrl(): Text
    var
        MicrosoftFaceAPISetup: Record "Microsoft Face API Setup";
    begin
        MicrosoftFaceAPISetup.Get();
        exit(StrSubstNo('https://%1.%2', MicrosoftFaceAPISetup.Location, MicrosoftFaceAPISetup."Base Url"));
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
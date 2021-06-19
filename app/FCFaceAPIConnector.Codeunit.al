codeunit 50101 "FC Face API Connector"
{
    procedure CreatePersonGroup(GroupId: Text[64]; DisplayName: Text[128]; Description: Text; RecognitionModel: Text): HttpResponseMessage
    var
        AlHttpClient: HttpClient;
        MsgContent: HttpContent;
        ResponseMsg: HttpResponseMessage;
        JsonBody: JsonObject;
        TextBody: Text;
        RequestUrl: Text;
        EndpointUri: Text;
    begin
        EndpointUri := 'persongroups/%1';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GroupId));
        JsonBody.Add('name', DisplayName);
        // TODO: Not supported for now, to add user comments
        // JsonBody.Add('userData', DisplayName);
        JsonBody.Add('recognitionModel', RecognitionModel);
        JsonBody.WriteTo(TextBody);

        MsgContent.WriteFrom(TextBody);
        PrepareRequestHeaders(AlHttpClient, MsgContent, 'application/json');
        if not AlHttpClient.Put(RequestUrl, MsgContent, ResponseMsg) then
            Error(HttpRequestFailedErr);

        exit(ResponseMsg);
    end;

    procedure DeletePersonGroup(GroupId: Text[64]): HttpResponseMessage
    var
        AlHttpClient: HttpClient;
        ResponseMsg: HttpResponseMessage;
        RequestUrl: Text;
        EndpointUri: Text;
    begin
        SetDefaultRequestHeaders(AlHttpClient);
        EndpointUri := 'persongroups/%1';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GroupId));

        if not AlHttpClient.Delete(RequestUrl, ResponseMsg) then
            Error(HttpRequestFailedErr);

        exit(ResponseMsg);
    end;

    procedure GetPersonGroupList(): HttpResponseMessage
    var
        AlHttpClient: HttpClient;
        ResponseMsg: HttpResponseMessage;
        RequestUrl: Text;
        EndpointUri: Text;
    begin
        SetDefaultRequestHeaders(AlHttpClient);
        EndpointUri := 'persongroups?returnRecognitionModel=true';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), EndpointUri);

        if not AlHttpClient.Get(RequestUrl, ResponseMsg) then
            Error(HttpRequestFailedErr);

        exit(ResponseMsg);
    end;

    procedure GetPersonGroupTrainingStatus(GroupId: Text): HttpResponseMessage
    var
        ALHttpClient: HttpClient;
        ResponseMsg: HttpResponseMessage;
        EndpointUri: Text;
        RequestUrl: Text;
    begin
        SetDefaultRequestHeaders(AlHttpClient);
        EndpointUri := 'persongroups/%1/training';
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GroupId));

        if not AlHttpClient.Get(RequestUrl, ResponseMsg) then
            Error(HttpRequestFailedErr);

        exit(ResponseMsg);
    end;

    procedure UpdatePersonGroup(GroupId: Text[64]; DisplayName: Text[128]; Description: Text): HttpResponseMessage
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

        exit(ResponseMsg);
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
        FaceAPISetup: Record "FC Face API Setup";
        AlHttpClient: HttpClient;
    begin
        FaceAPISetup.Get();
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

    // TODO: Camera interaction is under construction
    procedure DetectFaceInCameraSource(): Text
    /*        var
                CameraInteraction: Page "Camera Interaction";
                PictureStream: InStream;*/
    begin
        /*            CameraInteraction.RunModal();
                    if CameraInteraction.GetPicture(PictureStream) then
                        exit(DetectFace('application/octet-stream', PictureStream));*/
    end;

    procedure DetectFaceInUrlSource(Url: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        JObj: JsonObject;
        OutStr: OutStream;
        InStr: InStream;
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
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), StrSubstNo(EndpointUri, GetAttributesString()));
        MsgContent.WriteFrom(ContentStream);

        if not AlHttpClient.Post(RequestUrl, MsgContent, ResponseMsg) then
            Error(HttpRequestFailedErr);

        ResponseMsg.Content.ReadAs(ResponseString);
        exit(ResponseString)
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
    begin
        SetDefaultRequestHeaders(AlHttpClient);
        SetContentHeaders(MsgContent, ContentType);
    end;

    local procedure SetDefaultRequestHeaders(var AlHttpClient: HttpClient)
    var
        FaceApiSetup: Record "FC Face API Setup";
    begin
        FaceAPISetup.Get();
        AlHttpClient.DefaultRequestHeaders.Add('User-Agent', BCUserAgentTok);
        AlHttpClient.DefaultRequestHeaders.Add('Ocp-Apim-Subscription-Key', FaceAPISetup."Subscription Key");
    end;

    local procedure GetBaseRequestUrl(): Text
    var
        FaceAPISetup: Record "FC Face API Setup";
        UriFormatTok: Label 'https://%1.%2', Comment = '%1: Service geography; %2 = API service URL', Locked = true;
    begin
        FaceAPISetup.Get();
        exit(StrSubstNo(UriFormatTok, FaceAPISetup.Location, FaceAPISetup."Base Url"));
    end;

    local procedure SetContentHeaders(var MsgContent: HttpContent; ContentType: Text);
    var
        MsgHeaders: HttpHeaders;
    begin
        MsgContent.GetHeaders(MsgHeaders);
        MsgHeaders.Clear();
        MsgHeaders.Add('Content-Type', ContentType);
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
        FaceAPISetupAttr: Record "FC Face API Setup Attr.";
        NoAttributesSelectedErr: TextConst ENU = 'At least one attribute must be selected in the Microsoft Face API Setup';
    begin
        FaceAPISetupAttr.SetRange(Enabled, true);
        if FaceAPISetupAttr.FindSet() then
            repeat
                Attributes := ConcatString(Attributes, FaceAPISetupAttr.Name, ',');
            until FaceAPISetupAttr.Next() = 0;

        if Attributes = '' then
            Error(NoAttributesSelectedErr);
    end;

    local procedure FormatArrayOutput(JArr: JsonArray; ParentTokenName: Text[50]): Text;
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
        FaceAPISetupAttr: Record "FC Face API Setup Attr.";
        JTok: JsonToken;
        ParentAttrID: Integer;
        TokenText: Text;
    begin
        FaceAPISetupAttr.SetRange(Name, ParentTokenName);
        FaceAPISetupAttr.FindFirst();
        ParentAttrID := FaceAPISetupAttr.id;

        FaceAPISetupAttr.Reset();
        FaceAPISetupAttr.SetRange("Parent Attribute", ParentAttrID);
        if FaceAPISetupAttr.FindSet() then
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
            until FaceAPISetupAttr.Next() = 0;
    end;

    local procedure FormatTokenOutput(JTok: JsonToken; ParentAttrName: Text[50]): Text;
    begin
        if JTok.IsObject then
            exit(FormatObjectOutput(JTok.AsObject(), ParentAttrName));

        if JTok.IsArray then
            exit(FormatArrayOutput(JTok.AsArray(), ParentAttrName));

        exit(JTok.AsValue().AsText());
    end;

    procedure GetAttributesFromResponseString(var AttrNameValueBuf: Record "Name/Value Buffer"; JsonString: Text);
    var
        FaceAPISetup: Record "FC Face API Setup";
        APISetupAttr: Record "FC Face API Setup Attr.";
        JObj: JsonObject;
        JTok: JsonToken;
        JArr: JsonArray;
    begin
        FaceAPISetup.Get();
        AttrNameValueBuf.DeleteAll();
        if not JArr.ReadFrom(JsonString) then
            Error(JsonString);

        if not JArr.Get(0, JTok) then
            Error(FaceNotFoundErr);

        JObj := JTok.AsObject();
        if not JObj.SelectToken(FaceAPISetup."Attributes Token", JTok) then
            Error(FaceNotFoundErr);

        JObj := JTok.AsObject();

        APISetupAttr.SetRange(Enabled, true);
        if APISetupAttr.FindSet() then
            repeat
                AttrNameValueBuf.ID += 1;
                AttrNameValueBuf.Name := APISetupAttr.Name;
                JObj.SelectToken(APISetupAttr.Name, JTok);
                AttrNameValueBuf.Value := CopyStr(FormatTokenOutput(JTok, APISetupAttr.Name), 1, MaxStrLen(AttrNameValueBuf.Value));
                AttrNameValueBuf.Insert();
            until APISetupAttr.Next() = 0;
    end;

    procedure GetDefaultRecognitionModel(): Text
    var
        FaceAPISetup: Record "FC Face API Setup";
    begin
        FaceAPISetup.Get();
        exit(FaceAPISetup."Default Recognition Model");
    end;

    var
        FaceNotFoundErr: TextConst ENU = 'Could not detect face in the image';
        BCUserAgentTok: Label 'Dynamics 365 BC';
        HttpRequestFailedErr: Label 'HTTP request failed';
}
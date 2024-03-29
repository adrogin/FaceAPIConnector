codeunit 50101 "FC Face API Connector"
{
    #region Person Group functions
    procedure CreatePersonGroup(GroupId: Text[64]; DisplayName: Text[128]; Description: Text; RecognitionModel: Text) ResponseMsg: HttpResponseMessage
    var
        JsonBody: JsonObject;
    begin
        JsonBody.Add('name', DisplayName.Trim());
        // TODO: Not supported for now, to add user comments
        // JsonBody.Add('userData', DisplayName);
        JsonBody.Add('recognitionModel', RecognitionModel.Trim());
        exit(SendHttpRequest(StrSubstNo(PersonGroupsEndpointTok, GroupId.Trim()), JsonBody, 'PUT'));
    end;

    procedure DeletePersonGroup(GroupId: Text[64]): HttpResponseMessage
    begin
        exit(SendDeleteRequest(StrSubstNo(PersonGroupsEndpointTok, GroupId)));
    end;

    procedure GetPersonGroupList() ResponseMsg: HttpResponseMessage
    begin
        exit(SendGetRequest('persongroups?returnRecognitionModel=true'));
    end;

    procedure GetPersonGroupTrainingStatus(GroupId: Text) ResponseMsg: HttpResponseMessage
    begin
        exit(SendGetRequest(StrSubstNo(PersonGroupTrainingStatusEndpointTok, GroupId)));
    end;

    procedure StartPersonGroupTraining(GroupId: Text[64]): HttpResponseMessage
    var
        DummyJsonObj: JsonObject;
    begin
        exit(SendHttpRequest(StrSubstNo(TrainGroupEndpointTok, GroupId), DummyJsonObj, 'POST'));
    end;

    procedure UpdatePersonGroup(GroupId: Text[64]; DisplayName: Text[128]; Description: Text) ResponseMsg: HttpResponseMessage
    var
        JsonBody: JsonObject;
    begin
        JsonBody.Add('name', DisplayName);
        JsonBody.Add('userData', Description);
        exit(SendHttpRequest(StrSubstNo(PersonGroupsEndpointTok, GroupId), JsonBody, 'PATCH'));
    end;

    procedure VerifyGroupID(GroupID: Text)
    var
        RegEx: Codeunit Regex;
        WrongGroupNameErr: Label 'Group ID can only contain lower case characters, digits, dash (-) and undescore (_).';
    begin
        if not RegEx.IsMatch(GroupID, '^[a-z0-9\-_]+$') then
            Error(WrongGroupNameErr);
    end;

    #endregion

    #region PersonGroup Person functions

    procedure CreatePerson(GroupId: Text[64]; PersonName: Text[128]; AddInfo: Text) ResponseMsg: HttpResponseMessage
    var
        JsonBody: JsonObject;
    begin
        JsonBody.Add('name', PersonName);
        JsonBody.Add('userData', AddInfo);
        exit(SendHttpRequest(StrSubstNo(PersonsEndpointTok, GroupId), JsonBody, 'POST'));
    end;

    procedure DeletePerson(GroupId: Text[64]; PersonId: Text[36]): HttpResponseMessage
    begin
        exit(SendDeleteRequest(StrSubstNo(PersonIDEndpointTok, GroupId, PersonId)));
    end;

    procedure UpdatePerson(GroupId: Text[64]; PersonId: Text[36]; PersonName: Text[128]; AddInfo: Text): HttpResponseMessage
    var
        JsonBody: JsonObject;
    begin
        JsonBody.Add('name', PersonName);
        JsonBody.Add('userData', AddInfo);
        exit(SendHttpRequest(StrSubstNo(PersonIDEndpointTok, GroupId, PersonId), JsonBody, 'PATCH'));
    end;

    procedure GetPersonIdFromResponseMessage(var ResponseMsg: HttpResponseMessage): Text
    begin
        exit(GetJsonObjectValue(ResponseMsg, 'personId'));
    end;

    procedure GetPersonGroupPersonsList(GroupId: Text[64]; StartRecId: Text[36]; var IsLastRecordReceived: Boolean): HttpResponseMessage
    var
        ResponseMsg: HttpResponseMessage;
        TopRecords: Integer;
    begin
        // 1000 is the default value and can be omitted
        // TODO: Number of records to receive should be stored in a setup
        TopRecords := 1000;
        ResponseMsg := SendGetRequest(StrSubstNo(PersonsListEndpointTok, GroupId, StartRecId, TopRecords));
        IsLastRecordReceived := IsLastPersonGroupPersonReceived(ResponseMsg, TopRecords);

        exit(ResponseMsg);
    end;

    #endregion

    #region Faces
    procedure AddPersonFace(GroupId: Text[64]; PersonId: Text; var ContentStream: InStream): HttpResponseMessage
    begin
        exit(SendHttpRequest(StrSubstNo(PersistedFacesEndpointTok, GroupId, PersonId), ContentStream, 'application/octet-stream', 'POST'));
    end;

    procedure DeletePersonFace(GroupId: Text[64]; PersonId: Text[36]; FaceId: Text[36]): HttpResponseMessage
    begin
        exit(SendDeleteRequest(StrSubstNo(PersistedFaceIdEndpointTok, GroupId, PersonId, FaceId)));
    end;

    procedure DetectFaceInFileSource(): HttpResponseMessage
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        FileMgt.BLOBImport(TempBlob, '');
        exit(DetectFaceInBlobSource(TempBlob));
    end;

    procedure DetectFaceInBlobSource(var TempBlobImage: Codeunit "Temp Blob"): HttpResponseMessage
    var
        ImageStream: InStream;
    begin
        TempBlobImage.CreateInStream(ImageStream);
        exit(DetectFace('application/octet-stream', ImageStream));
    end;

    procedure DetectFaceInUrlSource(Url: Text): HttpResponseMessage
    begin
        exit(DetectFaceInUrlSource(Url, GetAttributesString()));
    end;

    procedure DetectFaceInUrlSource(Url: Text; Attributes: Text): HttpResponseMessage
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
        exit(DetectFace('application/json', InStr, Attributes));
    end;

    procedure IdentifyFaceInUrlSource(Url: Text; GroupId: Text[64]; NoOfCandidates: Integer; MinConfidenceLevel: Decimal): HttpResponseMessage
    var
        ResponseMsg: HttpResponseMessage;
        FaceId: JsonToken;
        ResponseStream: InStream;
        JsonBody: JsonObject;
        FacesArray: JsonArray;
        JFace: JsonToken;
        NoMatchFoundErr: Label 'Matching face not found';
    begin
        ResponseMsg := DetectFaceInUrlSource(Url, '');
        ResponseMsg.Content.ReadAs(ResponseStream);
        FacesArray.ReadFrom(ResponseStream);

        if FacesArray.Count = 0 then
            Error(NoMatchFoundErr);

        // TODO: Process multiple results
        FacesArray.Get(0, JFace);
        JFace.AsObject().Get('faceId', FaceId);

        Clear(FacesArray);
        FacesArray.Add(FaceId.AsValue());
        JsonBody.Add('faceIds', FacesArray);
        JsonBody.Add('personGroupId', GroupId);
        JsonBody.Add('maxNumOfCandidatesReturned', NoOfCandidates);
        JsonBody.Add('confidenceThreshold', MinConfidenceLevel);

        exit(SendHttpRequest(FaceIdentificationEndpointTok, JsonBody, 'POST'));
    end;

    local procedure DetectFace(ContentType: Text; ContentStream: InStream): HttpResponseMessage
    begin
        exit(DetectFace(ContentType, ContentStream, GetAttributesString()));
    end;

    local procedure DetectFace(ContentType: Text; ContentStream: InStream; Attributes: Text): HttpResponseMessage
    begin
        // TODO: Recognition model must match the target group!
        exit(SendHttpRequest(StrSubstNo(FaceDetectionEndpointTok, Attributes, GetDefaultRecognitionModel()), ContentStream, ContentType, 'POST'));
    end;

    #endregion

    #region Helper functions

    local procedure GetJsonObjectValue(var ResponseMessage: HttpResponseMessage; KeyName: Text): Text
    var
        MsgString: Text;
        JsonMsg: JsonObject;
        Token: JsonToken;
    begin
        ResponseMessage.Content.ReadAs(MsgString);
        if not JsonMsg.ReadFrom(MsgString) then
            Error(ResponseNotJsonErr);

        if not JsonMsg.Get(KeyName, Token) then
            Error(KeyNotFoundErr, KeyName);

        exit(Token.AsValue().AsText());
    end;

    local procedure PrepareRequestHeaders(var AlHttpClient: HttpClient; var MsgContent: HttpContent; ContentType: Text)
    begin
        SetDefaultRequestHeaders(AlHttpClient);
        SetContentHeaders(MsgContent, ContentType);
    end;

    local procedure SetDefaultRequestHeaders(var AlHttpClient: HttpClient)
    begin
        AlHttpClient.DefaultRequestHeaders.Add('User-Agent', BCUserAgentTok);
        SetAuthenticationHeaders(AlHttpClient);
    end;

    local procedure SetAuthenticationHeaders(var AlHttpClient: HttpClient)
    var
        FaceApiSetup: Record "FC Face API Setup";
        AzureAuthProvider: Interface "AP Azure Auth. Provider";
        AuthHeaders: Dictionary of [Text, Text];
        I: Integer;
        HeaderName: Text;
        HeaderValue: Text;
    begin
        FaceApiSetup.Get();
        AzureAuthProvider := FaceApiSetup."Authentication Provider";
        AuthHeaders := AzureAuthProvider.GetAuthenticationHeaders();

        for I := 1 to AuthHeaders.Count() do begin
            AuthHeaders.Keys.Get(I, HeaderName);
            AuthHeaders.Values.Get(I, HeaderValue);
            AlHttpClient.DefaultRequestHeaders.Add(HeaderName, HeaderValue);
        end;
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

    local procedure SendDeleteRequest(EndpointUri: Text) ResponseMsg: HttpResponseMessage
    var
        AlHttpClient: HttpClient;
        RequestUrl: Text;
    begin
        SetDefaultRequestHeaders(AlHttpClient);
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), EndpointUri);

        if not AlHttpClient.Delete(RequestUrl, ResponseMsg) then
            Error(HttpRequestFailedErr);
    end;

    local procedure SendGetRequest(EndpointUri: Text) ResponseMsg: HttpResponseMessage
    var
        AlHttpClient: HttpClient;
    begin
        SetDefaultRequestHeaders(AlHttpClient);
        if not AlHttpClient.Get(ConcatenateUrl(GetBaseRequestUrl(), EndpointUri), ResponseMsg) then
            Error(HttpRequestFailedErr);
    end;

    local procedure SendHttpRequest(EndpointUri: Text; ContentJObj: JsonObject; HttpMethod: Text): HttpResponseMessage
    var
        TempBlob: Codeunit "Temp Blob";
        ContentStream: InStream;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        ContentJObj.WriteTo(OutStr);

        TempBlob.CreateInStream(ContentStream);
        exit(SendHttpRequest(EndpointUri, ContentStream, 'application/json', HttpMethod));
    end;

    local procedure SendHttpRequest(EndpointUri: Text; ContentStream: InStream; ContentType: Text; HttpMethod: Text) ResponseMsg: HttpResponseMessage
    var
        AlHttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        MsgContent: HttpContent;
        RequestUrl: Text;
    begin
        RequestUrl := ConcatenateUrl(GetBaseRequestUrl(), EndpointUri);
        MsgContent.WriteFrom(ContentStream);

        RequestMessage.Method(HttpMethod);
        RequestMessage.SetRequestUri(RequestUrl);
        PrepareRequestHeaders(AlHttpClient, MsgContent, ContentType);
        RequestMessage.Content(MsgContent);

        if not AlHttpClient.Send(RequestMessage, ResponseMsg) then
            Error(HttpRequestFailedErr);
    end;

    local procedure IsLastPersonGroupPersonReceived(var ResponseMsg: HttpResponseMessage; RequestedRecCount: Integer): Boolean
    var
        ContentInStream: InStream;
        ContentJson: JsonArray;
        MessageContent: HttpContent;
    begin
        MessageContent := ResponseMsg.Content;
        MessageContent.ReadAs(ContentInStream);
        ContentJson.ReadFrom(ContentInStream);
        exit(ContentJson.Count() < RequestedRecCount);
    end;

    #endregion

    var
        FaceNotFoundErr: Label 'Could not detect face in the image';
        BCUserAgentTok: Label 'Dynamics 365 BC';
        HttpRequestFailedErr: Label 'HTTP request failed';
        ResponseNotJsonErr: Label 'Response content is not a JSON object.';
        KeyNotFoundErr: Label 'Key %1 is not found in the response.', Comment = '%1: Key name';
        PersonGroupsEndpointTok: Label 'persongroups/%1', Comment = '%1: Group ID', Locked = true;
        PersonGroupTrainingStatusEndpointTok: Label 'persongroups/%1/training', Comment = '%1: Group ID', Locked = true;
        PersonsEndpointTok: Label 'persongroups/%1/persons', Comment = '%1: Group ID', Locked = true;
        PersonIDEndpointTok: Label 'persongroups/%1/persons/%2', Comment = '%1: Group ID, %2: Person ID', Locked = true;
        PersistedFacesEndpointTok: Label 'persongroups/%1/persons/%2/persistedFaces', Comment = '%1: Group ID, %2: Person ID', Locked = true;
        PersistedFaceIdEndpointTok: Label 'persongroups/%1/persons/%2/persistedFaces/%3', Comment = '%1: Group ID, %2: Person ID, %3: Face ID', Locked = true;
        PersonsListEndpointTok: Label 'persongroups/%1/persons?start=%2&top=%3', Comment = '%1: Person group ID, %2: starting ID to return, %3: number of records to retrieve';
        TrainGroupEndpointTok: Label 'persongroups/%1/train', Comment = '%1: Person group ID', Locked = true;
        FaceDetectionEndpointTok: Label 'detect?returnFaceAttributes=%1&returnFaceId&recognitionModel=%2',
            Comment = '%1: List of attributes to detect; %2: Recognition model. If used in conjunction with "identify" API, must match the person group recognition model',
            Locked = true;
        FaceIdentificationEndpointTok: Label 'identify';
}
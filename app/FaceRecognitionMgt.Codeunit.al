codeunit 50104 "Face Recognition Mgt."
{
    procedure CreatePersonGroup(var FaceRecognitionGroup: Record "Face Recognition Group")
    var
        ResponseString: Text;
    begin
        if FaceRecognitionGroup."Group Id" = '' then
            Error(GroupNameCannotBeEmptyErr);

        ResponseString := FaceApiConnector.CreatePersonGroup(FaceRecognitionGroup."Group Id", FaceRecognitionGroup.Name, '', DefaultRecognitionModelTok);
        if GetHttpStatusCodeFromResponseString(ResponseString) <> 200 then
            Error(GetServiceResponseObject(ResponseString).AsToken().AsValue().AsText());

        FaceRecognitionGroup.Validate(Synchronized, true);
        FaceRecognitionGroup.Modify(true);
    end;

    procedure UpdatePersonGroup(var FaceRecognitionGroup: Record "Face Recognition Group")
    ResponseString: Text;
    begin
        if FaceRecognitionGroup."Group Id" = '' then
            Error(GroupNameCannotBeEmptyErr);

        ResponseString := FaceApiConnector.UpdatePersonGroup(FaceRecognitionGroup."Group Id", FaceRecognitionGroup.Name, '');
        if GetHttpStatusCodeFromResponseString(ResponseString) <> 200 then
            Error(GetServiceResponseObject(ResponseString).AsToken().AsValue().AsText());

        FaceRecognitionGroup.Validate(Synchronized, true);
        FaceRecognitionGroup.Modify(true);
    end;

    procedure DeletePersonGroup(var FaceRecognitionGroup: Record "Face Recognition Group")
    var
        ResponseString: Text;
    begin
        ResponseString := FaceApiConnector.DeletePersonGroup(FaceRecognitionGroup."Group Id");
        if GetHttpStatusCodeFromResponseString(ResponseString) <> 200 then
            Error(GetServiceResponseObject(ResponseString).AsToken().AsValue().AsText());
    end;

    local procedure GetHttpStatusCodeFromResponseString(ServiceResponseString: Text): Integer
    begin
        exit(GetServiceResponseTokenFromArray(ServiceResponseString, 0, HttpStatusCodeTok).AsValue().AsInteger());
    end;

    local procedure GetServiceResponseObject(ServiceResponseString: Text): JsonObject
    begin
        exit(GetServiceResponseTokenFromArray(ServiceResponseString, 1, HttpErrorTok).AsObject());
    end;

    local procedure GetServiceResponseTokenFromArray(ServiceResponseString: Text; ItemNo: Integer; KeyName: Text): JsonToken
    var
        ResponseArray: JsonArray;
        Token: JsonToken;
        StatusCode: Integer;
    begin
        ResponseArray.ReadFrom(ServiceResponseString);
        if not ResponseArray.Get(ItemNo, Token) then
            Error(RetrieveResultFailedErr);

        if not Token.AsObject().Get(KeyName, Token) then
            Error(RetrieveResultFailedErr);

        exit(Token);
    end;

    var
        FaceApiConnector: Codeunit "Microsoft Face API Connector";
        DefaultRecognitionModelTok: Label 'recognition_03';
        HttpStatusCodeTok: Label 'statusCode';
        HttpErrorTok: Label 'error';
        GroupNameCannotBeEmptyErr: Label 'Group name cannot be empty';
        RetrieveResultFailedErr: Label 'Could not retrieve HTTP result from the response message.';
}
codeunit 50104 "FC Face Recognition Mgt."
{
    procedure CreatePersonGroup(var FaceRecognitionGroup: Record "FC Face Recognition Group")
    var
        ResponseMsg: HttpResponseMessage;
    begin
        if FaceRecognitionGroup.ID = '' then
            Error(GroupNameCannotBeEmptyErr);

        ResponseMsg := FaceApiConnector.CreatePersonGroup(FaceRecognitionGroup.ID, FaceRecognitionGroup.Name, '', FaceRecognitionGroup."Recognition Model");
        if not ResponseMsg.IsSuccessStatusCode() then
            HttpRequestError(ResponseMsg);

        FaceRecognitionGroup.Validate(Synchronized, true);
        FaceRecognitionGroup.Modify(true);
    end;

    procedure UpdatePersonGroup(var FaceRecognitionGroup: Record "FC Face Recognition Group")
    var
        ResponseMsg: HttpResponseMessage;
    begin
        if FaceRecognitionGroup.ID = '' then
            Error(GroupNameCannotBeEmptyErr);

        ResponseMsg := FaceApiConnector.UpdatePersonGroup(FaceRecognitionGroup.ID, FaceRecognitionGroup.Name, '');
        if not ResponseMsg.IsSuccessStatusCode() then
            HttpRequestError(ResponseMsg);

        FaceRecognitionGroup.Validate(Synchronized, true);
        FaceRecognitionGroup.Modify(true);
    end;

    procedure DeletePersonGroup(var FaceRecognitionGroup: Record "FC Face Recognition Group")
    var
        ResponseMsg: HttpResponseMessage;
    begin
        ResponseMsg := FaceApiConnector.DeletePersonGroup(FaceRecognitionGroup.ID);
        if not ResponseMsg.IsSuccessStatusCode() then
            HttpRequestError(ResponseMsg);
    end;

    procedure GetDefaultRecognitionModel(): Text
    begin
        exit(FaceApiConnector.GetDefaultRecognitionModel());
    end;

    procedure GetPersonGroupList()
    var
        FaceRecognitionGroup: Record "FC Face Recognition Group";
        ResponseMsg: HttpResponseMessage;
        ResponseInStream: InStream;
        ResponseTok: JsonToken;
        GroupTok: JsonToken;
    begin
        ResponseMsg := FaceApiConnector.GetPersonGroupList();
        if not ResponseMsg.IsSuccessStatusCode() then
            HttpRequestError(ResponseMsg);

        // Do not run table triggers - it will try to synchronize the operation and delete groups in Azure storage
        FaceRecognitionGroup.DeleteAll(false);

        ResponseMsg.Content.ReadAs(ResponseInStream);
        ResponseTok.ReadFrom(ResponseInStream);

        foreach GroupTok in ResponseTok.AsArray() do begin
            FaceRecognitionGroup.Validate(ID, GetAttributeValueFromJsonObject(GroupTok.AsObject(), 'personGroupId'));
            FaceRecognitionGroup.Validate(Name, CopyStr(GetAttributeValueFromJsonObject(GroupTok.AsObject(), 'name'), 1, MaxStrLen(FaceRecognitionGroup.Name)));
            FaceRecognitionGroup.Validate("Recognition Model", GetAttributeValueFromJsonObject(GroupTok.AsObject(), 'recognitionModel'));
            GetPersonGroupTrainingStatus(FaceRecognitionGroup);
            FaceRecognitionGroup.Insert(false);
        end;
    end;

    procedure GetPersonGroupTrainingStatus(var FaceRecongnitionGroup: Record "FC Face Recognition Group")
    var
        ResponseMsg: HttpResponseMessage;
        ResponseInStream: InStream;
        JObject: JsonObject;
        GroupStatus: Enum "FC Recognition Group Status";
    begin
        ResponseMsg := FaceApiConnector.GetPersonGroupTrainingStatus(FaceRecongnitionGroup.ID);

        if ResponseMsg.IsSuccessStatusCode() then begin
            ResponseMsg.Content.ReadAs(ResponseInStream);
            JObject.ReadFrom(ResponseInStream);
            GroupStatus := MapGroupTrainingStatus(GetAttributeValueFromJsonObject(JObject, 'status'))
        end
        else
            GroupStatus := GroupStatus::"Training Pending";

        FaceRecongnitionGroup.Validate(Status, GroupStatus);
    end;

    local procedure MapGroupTrainingStatus(Status: Text): Enum "FC Recognition Group Status"
    var
        RecognitionGroupState: Enum "FC Recognition Group Status";
    begin
        case Status.ToLower() of
            'notstarted':
                exit(RecognitionGroupState::"Training Pending");
            'running':
                exit(RecognitionGroupState::Training);
            'succeeded':
                exit(RecognitionGroupState::Trained);
            'failed':
                exit(RecognitionGroupState::Failed);
        end;
    end;

    local procedure GetAttributeValueFromJsonObject(JObject: JsonObject; AttributeName: Text): Text
    var
        Attribute: JsonToken;
    begin
        JObject.Get(AttributeName, Attribute);
        exit(Attribute.AsValue().AsText());
    end;

    local procedure HttpRequestError(ResponseMsg: HttpResponseMessage)
    var
        ErrorText: Text;
        MessageErr: Label 'Server returned the error: %1, %2\%3', Comment = '%1: Error code; %2: Reason phrase; %3: Error text.';
    begin
        ResponseMsg.Content.ReadAs(ErrorText);
        Error(MessageErr, ResponseMsg.HttpStatusCode(), ResponseMsg.ReasonPhrase(), ErrorText);
    end;

    var
        FaceApiConnector: Codeunit "FC Face API Connector";
        GroupNameCannotBeEmptyErr: Label 'Group name cannot be empty';
}
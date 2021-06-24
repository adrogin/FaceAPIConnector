codeunit 50104 "FC Face Recognition Mgt."
{
    #region Face detection functions

    procedure DetectFaceInFileSource() ReponseTxt: Text
    var
        ResponseMsg: HttpResponseMessage;
    begin
        ResponseMsg := FaceAPIConnector.DetectFaceInFileSource();
        VerifyHttpResponse(ResponseMsg);
        ResponseMsg.Content.ReadAs(ReponseTxt);
    end;

    procedure DetectFaceInUrlSource(Url: Text) ResponseTxt: Text
    var
        ResponseMsg: HttpResponseMessage;
    begin
        ResponseMsg := FaceAPIConnector.DetectFaceInUrlSource(Url);
        VerifyHttpResponse(ResponseMsg);
        ResponseMsg.Content.ReadAs(ResponseTxt);
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

    #endregion

    #region Person Group functions
    procedure CreatePersonGroup(var FaceRecognitionGroup: Record "FC Person Group")
    var
        ResponseMsg: HttpResponseMessage;
    begin
        if FaceRecognitionGroup.ID = '' then
            Error(GroupNameCannotBeEmptyErr);

        ResponseMsg := FaceApiConnector.CreatePersonGroup(FaceRecognitionGroup.ID, FaceRecognitionGroup.Name, '', FaceRecognitionGroup."Recognition Model");
        VerifyHttpResponse(ResponseMsg);
    end;

    procedure UpdatePersonGroup(var FaceRecognitionGroup: Record "FC Person Group")
    var
        ResponseMsg: HttpResponseMessage;
    begin
        if FaceRecognitionGroup.ID = '' then
            Error(GroupNameCannotBeEmptyErr);

        ResponseMsg := FaceApiConnector.UpdatePersonGroup(FaceRecognitionGroup.ID, FaceRecognitionGroup.Name, '');
        VerifyHttpResponse(ResponseMsg);
    end;

    procedure DeletePersonGroup(var FaceRecognitionGroup: Record "FC Person Group")
    var
        ResponseMsg: HttpResponseMessage;
    begin
        ResponseMsg := FaceApiConnector.DeletePersonGroup(FaceRecognitionGroup.ID);

        // If the group is not found on remote, delete the local group without error messages
        if not ResponseMsg.IsSuccessStatusCode() and (ResponseMsg.HttpStatusCode <> 404) then
            HttpRequestError(ResponseMsg);
    end;

    procedure GetPersonGroupList()
    var
        PersonGroup: Record "FC Person Group";
        ResponseMsg: HttpResponseMessage;
        ResponseInStream: InStream;
        ResponseTok: JsonToken;
        GroupTok: JsonToken;
    begin
        ResponseMsg := FaceApiConnector.GetPersonGroupList();
        VerifyHttpResponse(ResponseMsg);

        // Do not run table triggers - it will try to synchronize the operation and delete groups in Azure storage
        PersonGroup.DeleteAll(false);

        ResponseMsg.Content.ReadAs(ResponseInStream);
        ResponseTok.ReadFrom(ResponseInStream);

        foreach GroupTok in ResponseTok.AsArray() do begin
            PersonGroup.Validate(ID, GetAttributeValueFromJsonObject(GroupTok.AsObject(), 'personGroupId'));
            PersonGroup.Validate(Name, CopyStr(GetAttributeValueFromJsonObject(GroupTok.AsObject(), 'name'), 1, MaxStrLen(PersonGroup.Name)));
            PersonGroup.Validate("Recognition Model", GetAttributeValueFromJsonObject(GroupTok.AsObject(), 'recognitionModel'));
            GetPersonGroupTrainingStatus(PersonGroup);
            PersonGroup.Insert(false);
        end;
    end;

    procedure GetPersonGroupTrainingStatus(var FaceRecongnitionGroup: Record "FC Person Group")
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

    procedure VerifyGroupID(GroupID: Text)
    begin
        FaceApiConnector.VerifyGroupID(GroupID);
    end;

    #endregion

    #region PersonGroup Person functions

    procedure CreatePerson(var Person: Record "FC Person")
    var
        ResponseMsg: HttpResponseMessage;
    begin
        // TODO: Aditional info to be added, sending an empty string for now
        ResponseMsg := FaceApiConnector.CreatePerson(Person."Group ID", Person.Name, '');
        VerifyHttpResponse(ResponseMsg);

        Person.Validate(ID, FaceApiConnector.GetPersonIdFromResponseMessage(ResponseMsg));
    end;

    procedure DeletePerson(Person: Record "FC Person")
    begin
        VerifyHttpResponse(FaceApiConnector.DeletePerson(Person."Group ID", Person.Name));
    end;

    procedure UpdatePerson(Person: Record "FC Person")
    begin
        VerifyHttpResponse(FaceApiConnector.UpdatePerson(Person."Group ID", Person.ID, Person.Name, ''));
    end;

    #endregion

    procedure GetDefaultRecognitionModel(): Text
    begin
        exit(FaceApiConnector.GetDefaultRecognitionModel());
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

    local procedure VerifyHttpResponse(ResponseMsg: HttpResponseMessage)
    begin
        if not ResponseMsg.IsSuccessStatusCode() then
            HttpRequestError(ResponseMsg);
    end;

    var
        FaceApiConnector: Codeunit "FC Face API Connector";
        GroupNameCannotBeEmptyErr: Label 'Group name cannot be empty';
}
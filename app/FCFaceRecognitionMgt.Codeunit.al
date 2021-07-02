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

    procedure IdentifyFaceInUrlSource(Url: Text; PersonGroupId: Text[64]) Candidates: Dictionary of [Text, Decimal]
    var
        ResponseMsg: HttpResponseMessage;
        ResponseStream: InStream;
        ResponseArray: JsonArray;
        FaceObj: JsonToken;
        JCandidates: JsonToken;
        Candidate: JsonToken;
        JTokPersonId: JsonToken;
        JTokConfidence: JsonToken;
    begin
        // TODO: No. of candidates to return and the minimum level of confidence must be in a setup
        ResponseMsg := FaceApiConnector.IdentifyFaceInUrlSource(Url, PersonGroupId, 1, 0.8);
        VerifyHttpResponse(ResponseMsg);

        ResponseMsg.Content.ReadAs(ResponseStream);
        ResponseArray.ReadFrom(ResponseStream);

        foreach FaceObj in ResponseArray do begin
            FaceObj.AsObject().Get('candidates', JCandidates);

            foreach Candidate in JCandidates.AsArray() do begin
                Candidate.AsObject().Get('personId', JTokPersonId);
                Candidate.AsObject().Get('confidence', JTokConfidence);
                Candidates.Add(JTokPersonId.AsValue().AsText(), JTokConfidence.AsValue().AsDecimal());
            end;
        end;
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

    procedure GetPersonGroupTrainingStatus(var PersonGroup: Record "FC Person Group")
    var
        ResponseMsg: HttpResponseMessage;
        ResponseInStream: InStream;
        JObject: JsonObject;
        GroupStatus: Enum "FC Recognition Group Status";
    begin
        ResponseMsg := FaceApiConnector.GetPersonGroupTrainingStatus(PersonGroup.ID);

        if ResponseMsg.IsSuccessStatusCode() then begin
            ResponseMsg.Content.ReadAs(ResponseInStream);
            JObject.ReadFrom(ResponseInStream);
            GroupStatus := MapGroupTrainingStatus(GetAttributeValueFromJsonObject(JObject, 'status'))
        end
        else
            GroupStatus := GroupStatus::"Training Pending";

        PersonGroup.Validate(Status, GroupStatus);
    end;

    procedure GetAllPendingGroupsTrainingStatus()
    var
        PersonGroup: Record "FC Person Group";
    begin
        PersonGroup.SetRange(Status, PersonGroup.Status::Training);
        if PersonGroup.FindSet(true, true) then
            repeat
                GetPersonGroupTrainingStatus(PersonGroup);
                PersonGroup.Modify(false);
            until PersonGroup.Next() = 0;
    end;

    procedure StartPersonGroupTraining(var PersonGroup: Record "FC Person Group")
    begin
        FaceApiConnector.StartPersonGroupTraining(PersonGroup.ID);
        PersonGroup.Validate(Status, PersonGroup.Status::Training);
        PersonGroup.Modify(false);
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
        VerifyHttpResponse(FaceApiConnector.DeletePerson(Person."Group ID", Person.ID));
    end;

    procedure UpdatePerson(Person: Record "FC Person")
    begin
        VerifyHttpResponse(FaceApiConnector.UpdatePerson(Person."Group ID", Person.ID, Person.Name, ''));
    end;

    procedure GetPersonGroupPersonsList(var Person: Record "FC Person"; GroupId: Text[64])
    var
        ResponseMsg: HttpResponseMessage;
        ContentInStream: InStream;
        ResponseArray: JsonArray;
        PersonJTok: JsonToken;
        IsLastRecordReceived: Boolean;
        LastRecId: Text[36];
    begin
        Person.SetRange("Group ID", GroupId);
        Person.DeleteAll(false);

        while not IsLastRecordReceived do begin
            ResponseMsg := FaceApiConnector.GetPersonGroupPersonsList(GroupId, LastRecId, IsLastRecordReceived);
            VerifyHttpResponse(ResponseMsg);
            ResponseMsg.Content.ReadAs(ContentInStream);
            ResponseArray.ReadFrom(ContentInStream);

            foreach PersonJTok in ResponseArray do begin
                Person.Validate("Group ID", GroupId);
                Person.Validate(ID, GetAttributeValueFromJsonObject(PersonJTok.AsObject(), 'personId'));
                Person.Validate(Name, GetAttributeValueFromJsonObject(PersonJTok.AsObject(), 'name'));
                Person.Validate(Synchronized, true);
                Person.Insert(false);
            end;

            LastRecId := Person.ID;
        end;
    end;

    #endregion

    #region Person Faces

    procedure AddPersonFace(var PersonFace: Record "FC Person Face")
    var
        MediaInStream: InStream;
        ResponseMsg: HttpResponseMessage;
        ContentInStream: InStream;
        ResponseJson: JsonObject;
        FaceIdJTok: JsonToken;
        NoPersonFaceMediaErr: Label 'Person face image is missing. Image can be directly imported into the database or specified as the URL of the image file.';
    begin
        if PersonFace.Image.HasValue() then
            MediaInStream := GetPersonFaceDataStream(PersonFace)
        else
            if PersonFace.Url <> '' then
                MediaInStream := ImportMediaFromUrl(PersonFace.Url)
            else
                Error(NoPersonFaceMediaErr);

        ResponseMsg := FaceApiConnector.AddPersonFace(PersonFace."Person Group ID", PersonFace."Person ID", MediaInStream);
        VerifyHttpResponse(ResponseMsg);

        ResponseMsg.Content.ReadAs(ContentInStream);
        ResponseJson.ReadFrom(ContentInStream);
        ResponseJson.Get('persistedFaceId', FaceIdJTok);
        PersonFace.Validate("Face ID", FaceIdJTok.AsValue().AsText());
    end;

    procedure DeletePersonFace(PersonFace: Record "FC Person Face")
    begin
        FaceApiConnector.DeletePersonFace(PersonFace."Person Group ID", PersonFace."Person ID", PersonFace."Face ID");
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

    local procedure GetPersonFaceDataStream(var PersonFace: Record "FC Person Face") MediaInStream: InStream
    var
        TempBlob: Codeunit "Temp Blob";
        MediaOutStream: OutStream;
    begin
        PersonFace.Image.ExportStream(MediaOutStream);
        TempBlob.CreateOutStream(MediaOutStream);
        TempBlob.CreateInStream(MediaInStream);
    end;

    local procedure HttpRequestError(ResponseMsg: HttpResponseMessage)
    var
        ErrorText: Text;
        MessageErr: Label 'Server returned the error: %1, %2\%3', Comment = '%1: Error code; %2: Reason phrase; %3: Error text.';
    begin
        ResponseMsg.Content.ReadAs(ErrorText);
        Error(MessageErr, ResponseMsg.HttpStatusCode(), ResponseMsg.ReasonPhrase(), ErrorText);
    end;

    procedure ImportMediaFromUrl(Url: Text) MediaInStream: InStream
    var
        Client: HttpClient;
        ResponseMsg: HttpResponseMessage;
    begin
        Client.Get(Url, ResponseMsg);
        ResponseMsg.Content.ReadAs(MediaInStream);
    end;

    procedure ImportMediaFromUrl(var PersonFace: Record "FC Person Face")
    var
        ResponseInStream: InStream;
    begin
        ResponseInStream := ImportMediaFromUrl(PersonFace.Url);
        PersonFace.Image.ImportStream(ResponseInStream, PersonFace."User Data");
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
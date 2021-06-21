table 50102 "FC Face Recognition Group"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Text[64])
        {
            Caption = 'Group Id';
        }
        field(2; Name; Text[128])
        {
            Caption = 'Name';
        }
        field(3; "Recognition Model"; Text[100])
        {
            Caption = 'Recognition Model';
        }
        field(4; Synchronized; Boolean)
        {
            Caption = 'Synchronized';
            Editable = false;
        }
        field(5; Status; Enum "FC Recognition Group Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(6; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            Editable = false;
            Description = 'Error message returned by the training model if the training failed. Populated when the training status = failed.';
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if Rec."Recognition Model" = '' then
            Rec.Validate("Recognition Model", FaceRecognitionMgt.GetDefaultRecognitionModel());
        FaceRecognitionMgt.CreatePersonGroup(Rec);
    end;

    trigger OnDelete()
    begin
        FaceRecognitionMgt.DeletePersonGroup(Rec);
    end;

    trigger OnModify()
    begin
        FaceRecognitionMgt.UpdatePersonGroup(Rec);
    end;

    var
        FaceRecognitionMgt: Codeunit "FC Face Recognition Mgt.";
}
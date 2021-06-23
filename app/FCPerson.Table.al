table 50103 "FC Person"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group ID"; Text[64])
        {
            Caption = 'Group ID';
        }
        field(2; ID; Guid)
        {
            Caption = 'ID';
        }
        field(3; Name; Text[128])
        {
            Caption = 'Name';
        }
        field(4; Synchronized; Boolean)
        {
            Caption = 'Synchronized';
        }
    }

    keys
    {
        key(PK; "Group ID", ID)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        FaceRecognitionMgt.CreatePerson(Rec);
    end;

    trigger OnModify()
    begin
        FaceRecognitionMgt.UpdatePerson(Rec);
    end;

    trigger OnDelete()
    begin
        FaceRecognitionMgt.DeletePerson(Rec);
    end;

    var
        FaceRecognitionMgt: Codeunit "FC Face Recognition Mgt.";
}
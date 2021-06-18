table 50102 "FC Face Recognition Group"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Id"; Text[64])
        {
            Caption = 'Group Id';
        }
        field(2; Name; Text[128])
        {
            Caption = 'Name';
        }
        field(3; Synchronized; Boolean)
        {
            Caption = 'Synchronized';
            Editable = false;
        }
        field(4; State; Enum "FC Recognition Group State")
        {
            Caption = 'State';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Group Id")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
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
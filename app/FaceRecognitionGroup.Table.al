table 50102 "Face Recognition Group"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Id"; Text[64])
        {
            DataClassification = CustomerContent;
            Caption = 'Group Id';
        }
        field(2; Name; Text[128])
        {
            DataClassification = CustomerContent;
            Caption = 'Name';
        }
        field(3; Synchronized; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Synchronized';
            Editable = false;
        }
        field(4; State; Enum "Recognition Group State")
        {
            DataClassification = CustomerContent;
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
        FaceRecognitionMgt: Codeunit "Face Recognition Mgt.";
}
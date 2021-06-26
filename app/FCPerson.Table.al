table 50103 "FC Person"
{
    Caption = 'Person';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group ID"; Text[64])
        {
            Caption = 'Group ID';
            TableRelation = "FC Person Group";
            Editable = false;
        }
        field(2; ID; Text[36])
        {
            Caption = 'ID';
            Editable = false;
        }
        field(3; Name; Text[128])
        {
            Caption = 'Name';
        }
        field(4; Synchronized; Boolean)
        {
            Caption = 'Synchronized';
            Editable = false;
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
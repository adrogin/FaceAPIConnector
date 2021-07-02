table 50104 "FC Person Face"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Record ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Record ID';
        }
        field(2; "Person Group ID"; Text[64])
        {
            Caption = 'Person Group ID';
            Editable = false;
        }
        field(3; "Person ID"; Text[36])
        {
            Caption = 'Person ID';
            Editable = false;
        }
        field(4; "Face ID"; Text[36])
        {
            Caption = 'Face ID';
            Editable = false;
        }
        field(5; Image; Media)
        {
            Caption = 'Image';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; Url; Text[1024])
        {
            Caption = 'Url';
        }
        field(7; "Target Face"; Text[30])
        {
            Caption = 'Target Face';
        }
        field(8; "Detection Model"; Text[30])
        {
            Caption = 'Detection Model';
        }
        field(9; "User Data"; Text[1024])
        {
            Caption = 'User Data';
        }
    }

    keys
    {
        key(PK; "Person Group ID", "Person ID", "Record ID")
        {
            Clustered = true;
        }
        key(MSFaceID; "Person Group ID", "Person ID", "Face ID")
        {
        }
        key(FaceID; "Face ID")
        {
        }
    }

    trigger OnInsert()
    begin
        FaceRecongnitionMgt.AddPersonFace(Rec);
    end;

    trigger OnDelete()
    begin
        FaceRecongnitionMgt.DeletePersonFace(Rec);
    end;

    var
        FaceRecongnitionMgt: Codeunit "FC Face Recognition Mgt.";
}
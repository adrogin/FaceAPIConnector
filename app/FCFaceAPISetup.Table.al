table 50100 "FC Face API Setup"
{
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = CustomerContent;
        }

        field(2; "Base Url"; Text[100])
        {
            DataClassification = CustomerContent;
        }

        field(3; "Location"; Text[50])
        {
            DataClassification = CustomerContent;
        }

        field(4; "Subscription Key"; Text[50])
        {
            DataClassification = CustomerContent;
        }

        field(5; Method; Text[50])
        {
            DataClassification = CustomerContent;
        }

        field(6; "Attributes Token"; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
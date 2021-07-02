table 50100 "FC Face API Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Base Url"; Text[100])
        {
            Caption = 'Base Url';
        }
        field(3; "Location"; Text[50])
        {
            Caption = 'Location';
        }
        field(4; "Subscription Key"; Text[50])
        {
            Caption = 'Subscription Key';
        }
        field(5; Method; Text[50])
        {
            Caption = 'Method';
        }
        field(6; "Attributes Token"; Text[50])
        {
            Caption = 'Attributes Token';
        }
        field(7; "Default Recognition Model"; Text[50])
        {
            Caption = 'Default Recognition Model';
        }
        field(8; "Authentication Provider"; Enum "AP Azure Auth. Provider")
        {
            Caption = 'Authentication Provider';
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
table 50101 "FC Face API Setup Attr."
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; id; Integer)
        {
            AutoIncrement = true;
        }

        field(2; Name; Text[50]) { }

        field(3; Enabled; Boolean) { }

        field(4; "Parent Attribute"; Integer) { }
    }

    keys
    {
        key(PK; id)
        {
            Clustered = true;
        }
    }
}
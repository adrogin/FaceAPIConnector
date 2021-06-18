page 50101 "FC Face API Setup"
{
    PageType = Card;
    SourceTable = "FC Face API Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(ConnectionSettings)
            {
                field(BaseUrl; "Base Url") { }
                field(Location; Location) { }
                field(SubscriptionKey; "Subscription Key") { }
                field(Method; Method) { }
                field("Attributes Token"; "Attributes Token") { }
            }

            part(AttributesSubPage; "FC Face API Setup Attr.")
            {
                Caption = 'Attributes';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Setup)
            {
                Caption = 'Initialize Setup';
                RunObject = codeunit "FC Init Face API Setup";
                ToolTip = 'Reset API connection settings to default values.';
                Image = Default;
            }
        }
    }
}
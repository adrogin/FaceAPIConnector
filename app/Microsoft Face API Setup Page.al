page 50101 "Microsoft Face API Setup"
{
    PageType = Card;
    SourceTable = "Microsoft Face API Setup";
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
                field(BaseUrl;"Base Url") { }
                field(Location;Location) { }
                field(SubscriptionKey;"Subscription Key") { }
                field(Method;Method) { }
                field("Attributes Token";"Attributes Token") { }
            }

            part(AttributesSubPage; "Microsoft Face API Setup Attr.")
            {
                Caption = 'Attributes';
            }
        }
    }
}
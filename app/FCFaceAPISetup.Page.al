page 50101 "FC Face API Setup"
{
    PageType = Card;
    Caption = 'Face API Setup';
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
                Caption = 'Connection Settings';

                field(BaseUrl; Rec."Base Url")
                {
                    ToolTip = 'Base URL of the Microsoft Face API, excluding the service location.';
                }
                field(Location; Rec.Location)
                {
                    ToolTip = 'Geographical location of the service subscription, for example "uksouth" or "westeurope".';
                }
                field(AuthenticationProvider; Rec."Authentication Provider")
                {
                    ToolTip = 'Method of user authentication to access the API service.';
                }
                field(SubscriptionKey; Rec."Subscription Key")
                {
                    Editable = "Authentication Provider" = "Authentication Provider"::"Subscription Key";
                    ToolTip = 'Specifies the service subscription key if the selected authentication method if "Subscription Key".';
                }
                field("Attributes Token"; Rec."Attributes Token") { }
                field("Default Recognition Model"; Rec."Default Recognition Model")
                {
                    ToolTip = 'Default recognition model for a new person group.';
                }
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
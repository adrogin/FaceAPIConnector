page 50106 "FC Persons List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "FC Person";
    CardPageId = "FC Person";
    Caption = 'Persons List';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    ToolTip = 'Person ID generated by the Cognitive Services. This values is used to identify the person on the face recognition service.';
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Person name';
                }
                field(Synchronized; Rec.Synchronized)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates if the local data has been synchronized with Microsoft Cognitive Services.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetPersonsList)
            {
                ApplicationArea = All;
                Caption = 'Get Persons List';
                ToolTip = 'Import the list of persons in the group from Microsoft Cognitive Services.';

                trigger OnAction()
                var
                    FaceRecognitionMgt: Codeunit "FC Face Recognition Mgt.";
                begin
                    FaceRecognitionMgt.GetPersonGroupPersonsList(Rec, Rec.GetRangeMin("Group ID"));
                end;
            }
            action(Faces)
            {
                ApplicationArea = All;
                ToolTip = 'View and edit person face images.';
                RunObject = page "FC Person Faces";
                RunPageLink = "Person Group ID" = field("Group ID"), "Person ID" = field(ID);
            }
        }
    }
}
page 50104 "FC Face Recognition Groups"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "FC Face Recognition Group";
    DelayedInsert = true;
    Caption = 'Face Recognition Groups';

    layout
    {
        area(Content)
        {
            repeater(RecognitionGroup)
            {
                field(GroupId; Rec.ID)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field("Recognition Model"; Rec."Recognition Model")
                {
                    ApplicationArea = All;
                }
                field(Synchronized; Rec.Synchronized)
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetGroupsList)
            {
                ApplicationArea = All;
                Caption = 'Get Groups List';
                ToolTip = 'Read the list of person groups from Microsoft Cognitive Services. This action will delete the local list and replace it with the list received from the remote service.';

                trigger OnAction();
                var
                    ConfirmOverrideQst: Label 'Current list will be deleted and replaced with the list received from Cognitive Services.\Do you want to continue?';
                begin
                    if Confirm(ConfirmOverrideQst) then
                        FaceRecognitionMgt.GetPersonGroupList();
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Validate("Recognition Model", FaceRecognitionMgt.GetDefaultRecognitionModel());
    end;

    var
        FaceRecognitionMgt: Codeunit "FC Face Recognition Mgt.";
}
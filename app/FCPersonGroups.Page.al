page 50104 "FC Person Groups"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "FC Person Group";
    DelayedInsert = true;
    Caption = 'Person Groups';

    layout
    {
        area(Content)
        {
            repeater(RecognitionGroup)
            {
                field(GroupId; Rec.ID)
                {
                    ApplicationArea = All;
                    ToolTip = 'User-provided personGroupId as a string. The valid characters include numbers, English letters in lower case, "-" and "_". The maximum length of the personGroupId is 64.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Person group display name. The maximum length is 128.';
                }
                field("Recognition Model"; Rec."Recognition Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'The recognitionModel associated with this person group';
                }
                field(Synchronized; Rec.Synchronized)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates if the local person group information is synchronized with Microsoft Cognitive Services.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Person group training status. Status succeed means this person group is ready for identification, oterwise the training operation must be performed.';
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
            action(PersonsList)
            {
                ApplicationArea = All;
                Caption = 'Persons';
                ToolTip = 'View and manage the list of persons in this group.';
                RunObject = page "FC Person List";
                RunPageLink = "Group ID" = field(ID);
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
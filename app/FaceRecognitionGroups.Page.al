page 50104 "Face Recognition Groups"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Face Recognition Group";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(RecognitionGroup)
            {
                field(GroupId; "Group Id")
                {
                    ApplicationArea = All;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
                field(Synchronized; Synchronized)
                {
                    ApplicationArea = All;
                }
                field(State; State)
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
            action(SynchGroups)
            {
                ApplicationArea = All;
                Caption = 'Synchronize';

                trigger OnAction();
                begin

                end;
            }
        }
    }
}
page 50107 "FC Person Faces"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "FC Person Face";
    Caption = 'Person Faces';

    layout
    {
        area(Content)
        {
            group(Title)
            {
                ShowCaption = false;

                field(PersonName; PersonName)
                {
                    ShowCaption = false;
                    Editable = false;
                    Style = StrongAccent;
                }
            }
            repeater(Faces)
            {
                field(FaceID; Rec."Face ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identifier assigned to the persistent face by Microsoft Cognitive Services.';
                }
                field(Url; Rec.Url)
                {
                    ApplicationArea = All;
                    ToolTip = 'URL of the image containing the person''s face. If the face is imported into the BC database, URL can be left blank.';
                }
                field("Target Face"; Rec."Target Face")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'If the image contains multiple faces, this field must specify the target face, as a comma-separated rectangle coordinates: left, top, width, height.';
                }
                field("Detection Model"; Rec."Detection Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'The detectionModel associated with the detected faceIds. Supported detectionModel values include "detection_01", "detection_02" and "detection_03"';
                }
            }
        }
        area(Factboxes)
        {
            part(FaceImage; "FC Person Face Factbox")
            {
                ApplicationArea = All;
                SubPageLink = "Person Group ID" = field("Person Group ID"), "Person ID" = field("Person ID"), "Record ID" = field("Record ID");
                Caption = 'Face';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Person: Record "FC Person";
    begin
        if Person.Get(Rec."Person Group ID", Rec."Person ID") then
            PersonName := Person.Name
        else
            PersonName := '';
    end;

    var
        PersonName: Text;
}
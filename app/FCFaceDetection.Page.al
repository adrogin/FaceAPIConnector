page 50100 "FC Face Detection"
{
    PageType = Worksheet;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Face Detection';

    layout
    {
        area(content)
        {
            field(ImageSource; ImageSource)
            {
                Caption = 'Image Source';
                ToolTip = 'Source of the face image for annotation or identification.';

                trigger OnValidate();
                begin
                    ValidateImageSourceOption();
                end;
            }

            field(ImageUrl; ImageUrl)
            {
                Caption = 'Image URL';
                ToolTip = 'Location of the face image if it is stored outside of the BC database.';

                Editable = ImageUrlEditable;
            }
            field(PersonGroupId; PersonGroupId)
            {
                Caption = 'Person Group ID';
                ToolTip = 'Function "Identify" will try to match the image with faces in this group.';
                TableRelation = "FC Person Group";
            }

            repeater(Attributes)
            {
                Editable = false;

                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Name of the attribute';
                }

                field(Value; Rec.Value)
                {
                    Caption = 'Value';
                    ToolTip = 'Value of the attribute';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Annotate)
            {
                Caption = 'Annotate image';
                ToolTip = 'Detects the face in the image and provides characteristis selected in the Face API Setup.';

                trigger OnAction();
                begin
                    AnnotateImage();
                end;
            }
            action(Identify)
            {
                Caption = 'Identify';
                ToolTip = 'Identify the person in the picture against the selected person group.';

                trigger OnAction()
                var
                    FaceRecognitionUI: Codeunit "FC Face Recognition UI";
                    SelectPersonGroupErr: Label 'Select a person group to identify a person.';
                begin
                    if PersonGroupId = '' then
                        Error(SelectPersonGroupErr);

                    FaceRecognitionUI.ShowCandidates(FaceRecognitionMgt.IdentifyFaceInUrlSource(ImageUrl, PersonGroupId));
                end;
            }
        }
    }

    trigger OnOpenPage();
    begin
        ImageSource := ImageSource::"File";
        ValidateImageSourceOption();
    end;

    local procedure AnnotateImage();
    var
        FaceApiConnector: Codeunit "FC Face API Connector";
        Response: Text;
    begin
        case ImageSource of
            ImageSource::"File":
                Response := FaceRecognitionMgt.DetectFaceInFileSource();
            ImageSource::Web:
                Response := FaceRecognitionMgt.DetectFaceInUrlSource(ImageUrl);
            ImageSource::Camera:
                Response := FaceRecognitionMgt.DetectFaceInCameraSource();
        end;

        FaceAPIConnector.GetAttributesFromResponseString(Rec, Response);
    end;

    local procedure ValidateImageSourceOption();
    begin
        ImageUrlEditable := ImageSource = ImageSource::Web;
    end;

    var
        FaceRecognitionMgt: codeunit "FC Face Recognition Mgt.";
        PersonGroupId: Text[64];
        ImageSource: Enum "FC Image Source";
        ImageUrl: Text;
        ImageUrlEditable: Boolean;
}
page 50100 "Face Detection"
{
    PageType = Worksheet;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(ImageSource; ImageSource)
            {
                trigger OnValidate();
                begin
                    ValidateImageSourceOption();
                end;
            }

            field(ImageUrl; ImageUrl)
            {
                Editable = ImageUrlEditable;
            }

            repeater(Attributes)
            {
                Editable = false;

                field(Name; Name) { }

                field(Value; Value) { }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Annotate)
            {
                Caption = 'Annotate image';

                trigger OnAction();
                begin
                    AnnotateImage;
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
        FaceAPIConnector: codeunit "Microsoft Face API Connector";
        Response: Text;
    begin
        case ImageSource of
            ImageSource::"File":
                Response := FaceAPIConnector.DetectFaceInFileSource();
            ImageSource::Web:
                Response := FaceAPIConnector.DetectFaceInUrlSource(ImageUrl);
            ImageSource::Camera:
                Response := FaceAPIConnector.DetectFaceInCameraSource();
        end;

        FaceAPIConnector.GetAttributesFromResponseString(Rec, Response);
    end;

    local procedure ValidateImageSourceOption();
    begin
        ImageUrlEditable := ImageSource = ImageSource::Web;
    end;

    var
        ImageSource: Option "File",Web,Camera;
        ImageUrl: Text;
        ImageUrlEditable: Boolean;
}
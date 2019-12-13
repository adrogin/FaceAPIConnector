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
                Response := AnnotateImageFromFileSource;
            ImageSource::Web:
                Response := AnnotateImageFromWebSource;
            ImageSource::Camera:
                Response := AnnotateImageFromCameraSource;
        end;

        FaceAPIConnector.GetAttributesFromResponseString(Rec, Response);
    end;

    local procedure AnnotateImageFromFileSource(): Text;
    var
        TempBlob: Record TempBlob;
        MicrosoftFaceAPIConnector: Codeunit "Microsoft Face API Connector";
        FileMgt: Codeunit "File Management";
    begin
        FileMgt.BLOBImport(TempBlob, '');
        exit(MicrosoftFaceAPIConnector.DetectFaceInBlobSource(TempBlob));
    end;

    local procedure AnnotateImageFromWebSource(): Text;
    var
        MicrosoftFaceAPIConnector: Codeunit "Microsoft Face API Connector";
    begin
        exit(MicrosoftFaceAPIConnector.DetectFaceInUrlSource(ImageUrl));
    end;

    local procedure AnnotateImageFromCameraSource(): Text;
    var
        MicrosoftFaceAPIConnector: Codeunit "Microsoft Face API Connector";
    begin

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
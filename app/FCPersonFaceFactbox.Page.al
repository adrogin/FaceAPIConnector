page 50108 "FC Person Face Factbox"
{
    PageType = CardPart;
    SourceTable = "FC Person Face";
    Editable = false;

    layout
    {
        area(Content)
        {
            group(FaceImage)
            {
                ShowCaption = false;

                field(Image; Rec.Image)
                {
                    ApplicationArea = All;
                    ToolTip = 'Person image';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not Rec.Image.HasValue() then
            if Rec.Url <> '' then
                FaceRecognitionMgt.ImportMediaFromUrl(Rec);
    end;

    var
        FaceRecognitionMgt: Codeunit "FC Face Recognition Mgt.";
}
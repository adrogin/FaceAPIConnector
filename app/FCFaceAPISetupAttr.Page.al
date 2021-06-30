page 50102 "FC Face API Setup Attr."
{
    PageType = ListPart;
    SourceTable = "FC Face API Setup Attr.";
    SourceTableView = where("Parent Attribute" = const(0));
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ToolTip = 'Name of the face group.';
                }

                field(Enabled; Rec.Enabled)
                {
                    ToolTip = 'Indicates if the selected attribute will be included in the image analysis.';
                }

                field(ChildAttributes; ChildAttributes)
                {
                    Caption = 'Child attributes';
                    Editable = false;
                    ToolTip = 'The subset of related attributes. For example, if the selected attribute is "emotion", child attributes allows to choose values "happiness", "sadness", "fear", etc.';

                    trigger OnAssistEdit();
                    var
                        APISetupMgt: Codeunit "FC API Setup Mgt.";
                    begin
                        APISetupMgt.OpenChildAttributesList(id);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord();
    var
        APISetupMgt: Codeunit "FC API Setup Mgt.";
    begin
        ChildAttributes := APISetupMgt.FormatChildAttributesOutput(id);
    end;

    trigger OnNewRecord(BelowxRec: Boolean);
    begin
        ChildAttributes := '';
    end;

    var
        ChildAttributes: Text;
}
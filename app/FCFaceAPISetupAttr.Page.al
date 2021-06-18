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

                field(Enabled; Enabled) { }

                field(ChildAttributes; ChildAttributes)
                {
                    Caption = 'Child attributes';
                    Editable = false;

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
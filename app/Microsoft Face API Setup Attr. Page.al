page 50102 "Microsoft Face API Setup Attr."
{
    PageType = ListPart;
    SourceTable = "Microsoft Face API Setup Attr.";
    SourceTableView = where ("Parent Attribute" = const(0));
    ShowFilter = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name;Name) { }

                field(Enabled;Enabled) { }

                field(ChildAttributes;ChildAttributes)
                {
                    Caption = 'Child attributes';
                    Editable = false;

                    trigger OnAssistEdit();
                    var
                        APISetupMgt: Codeunit "API Setup Mgt.";
                    begin
                        APISetupMgt.OpenChildAttributesList(id);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord();
    var
        APISetupMgt: Codeunit "API Setup Mgt.";
    begin
        ChildAttributes := APISetupMgt.FormatChildAttributesOutput(id);
    end;

    trigger OnNewRecord(BelowxRec : Boolean);
    begin
        ChildAttributes := '';
    end;

    var
        ChildAttributes: Text;
}
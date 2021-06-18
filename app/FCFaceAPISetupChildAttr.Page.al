page 50103 "FC Face API Setup Child Attr."
{
    PageType = List;
    SourceTable = "FC Face API Setup Attr.";
    ShowFilter = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Name) { }

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
        "Parent Attribute" := ParentAttrId;
    end;

    procedure SetParentAttributeId(NewParentAttrId: Integer)
    begin
        ParentAttrId := NewParentAttrId;
    end;

    var
        ParentAttrId: Integer;
        ChildAttributes: Text;
}
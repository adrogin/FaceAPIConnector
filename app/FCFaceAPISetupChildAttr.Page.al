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
                field(Name; Rec.Name)
                {
                    ToolTip = 'Attribute name.';
                }

                field(ChildAttributes; ChildAttributes)
                {
                    Caption = 'Child attributes';
                    ToolTip = 'Some attribute have hierarchical relations where the main attribute has multiple sub-attributes. This field presents a list of related child atrributes.';
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
        Rec."Parent Attribute" := ParentAttrId;
    end;

    procedure SetParentAttributeId(NewParentAttrId: Integer)
    begin
        ParentAttrId := NewParentAttrId;
    end;

    var
        ParentAttrId: Integer;
        ChildAttributes: Text;
}
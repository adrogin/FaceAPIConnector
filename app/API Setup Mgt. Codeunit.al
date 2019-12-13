codeunit 50103 "API Setup Mgt."
{
    procedure FormatChildAttributesOutput(ParentAttrId: Integer) ChildAttributes: Text;
    var
        APISetupAttr: Record "Microsoft Face API Setup Attr.";
    begin
        APISetupAttr.SetRange("Parent Attribute", ParentAttrId);
        if APISetupAttr.FindSet then begin
            ChildAttributes := APISetupAttr.Name;
            while APISetupAttr.Next > 0 do
                ChildAttributes := ChildAttributes + ', ' + APISetupAttr.Name;
        end;
    end;

    procedure OpenChildAttributesList(ParentAttrId: Integer);
    var
        APISetupAttr: Record "Microsoft Face API Setup Attr.";
        APISetupChildAttr: Page "MS Face API Setup Child Attr.";
    begin
        if ParentAttrId = 0 then
            exit;

        APISetupAttr.FilterGroup(2);
        APISetupAttr.SetRange("Parent Attribute", ParentAttrId);
        APISetupAttr.FilterGroup(0);

        APISetupChildAttr.SetParentAttributeId(ParentAttrId);
        APISetupChildAttr.SetTableView(APISetupAttr);
        APISetupChildAttr.RunModal;
    end;
}
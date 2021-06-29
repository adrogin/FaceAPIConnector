codeunit 50105 "FC Face Recognition UI"
{
    procedure ShowCandidates(Candidates: Dictionary of [Text, Decimal])
    var
        PersonFace: Record "FC Person Face";
    begin
        if Candidates.Count() = 0 then
            exit;

        // TODO: There can be multiple candidates
        PersonFace.SetRange("Person ID", Candidates.Keys().Get(1));
        Page.Run(Page::"FC Person Faces", PersonFace);
    end;
}
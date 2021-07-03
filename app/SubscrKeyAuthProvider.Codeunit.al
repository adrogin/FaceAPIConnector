codeunit 50106 "Subscr. Key Auth. Provider" implements "AP Azure Auth. Provider"
{
    procedure GetAuthenticationHeaders(): Dictionary of [Text, Text]
    var
        FaceAPISetup: Record "FC Face API Setup";
        AuthHeader: Dictionary of [Text, Text];
    begin
        FaceAPISetup.Get();
        AuthHeader.Add('Ocp-Apim-Subscription-Key', FaceAPISetup."Subscription Key");
        exit(AuthHeader);
    end;
}
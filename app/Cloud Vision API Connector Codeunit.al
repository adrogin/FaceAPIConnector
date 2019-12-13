codeunit 50100 "Cloud Vision API Connector"
{
    trigger OnRun();
    begin
        SendRequest('https://vision.googleapis.com/v1/images:annotate');
    end;
    
    local procedure SendRequest(ServiceUrl: Text);
    var
        TempBlob: Record TempBlob temporary;
        FileMgt: Codeunit "File Management";
        Request: JsonObject;
        Image: JsonObject;
        ImageContent: JsonValue;
        Feature: JsonObject;
        FeaturesArray: JsonArray;
        RequestsArray: JsonArray;
        Payload: JsonObject;
        HttpResponse: HttpResponseMessage;
        MsgContent: HttpContent;
        JsonString: Text;
    begin
        FileMgt.BLOBImport(TempBlob, '');
        JsonString := '"' + TempBlob.ToBase64String + '"';
        ImageContent.ReadFrom(JsonString);
        Image.Add('content', ImageContent);
        
        Feature.Add('model', 'builtin/stable');
        Feature.Add('type', 'FACE_DETECTION');
        Feature.Add('maxResults', 5);
        FeaturesArray.Add(Feature);

        Request.Add('image', Image);
        Request.Add('features', FeaturesArray);
        RequestsArray.Add(Request);
        Payload.Add('requests', RequestsArray);
        if not Payload.WriteTo(JsonString) then
            Error('Could not write JSON object.');

        MsgContent.WriteFrom(JsonString);
        AlHttpClient.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365 BC');
        if not AlHttpClient.Post(ServiceUrl + '?key=AIzaSyD9MViqAzX0x1XIehTOO-c10BKeb3YnSJE', MsgContent, HttpResponse) then
            Error('Failed to send the web request');

        HttpResponse.Content.ReadAs(JsonString);
        Message(JsonString);
    end;

    local procedure SetCookie(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.");
    begin
        
    end;

    var
        AlHttpClient: HttpClient;
}
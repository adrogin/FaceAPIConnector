codeunit 50102 "Init. MS Face API Setup"
{
    trigger OnRun();
    begin
        InitSetup;
    end;

    local procedure InitSetup();
    begin
        InitConectionSettings;
        InitAttributes;
    end;

    local procedure InitConectionSettings()
    var
        MicrosoftFaceAPISetup: Record "Microsoft Face API Setup";
    begin
        MicrosoftFaceAPISetup.DeleteAll;

        MicrosoftFaceAPISetup."Base Url" := 'api.cognitive.microsoft.com/face/v1.0';
        MicrosoftFaceAPISetup.Location := 'westeurope';
        MicrosoftFaceAPISetup."Subscription Key" := 'aad3f6327d7b470a884d293ccf0512d6';
        MicrosoftFaceAPISetup.Method := 'detect';
        MicrosoftFaceAPISetup."Attributes Token" := 'faceAttributes';

        MicrosoftFaceAPISetup.Insert;        
    end;

    local procedure InitAttributes();
    var
        MicrosoftFaceAPISetupAttr: Record "Microsoft Face API Setup Attr.";
    begin
        MicrosoftFaceAPISetupAttr.DeleteAll;
        InsertAttribute('age', true);
        InsertAttribute('gender', true);
        InsertAttribute('smile', true);
        InsertAttribute('facialHair', true);
        InsertAttribute('glasses', true);
        InsertAttribute('headPose', false);
        InsertAttribute('emotion', true);
        InsertAttribute('hair', false);
        InsertAttribute('makeup', true);
        InsertAttribute('accessories', false);
        InsertAttribute('occlusion', false);
        InsertAttribute('blur', false);
        InsertAttribute('exposure', false);
        InsertAttribute('noise', false);

        InsertChildAttribute('facialHair', 'moustache');
        InsertChildAttribute('facialHair', 'beard');
        InsertChildAttribute('facialHair', 'sideburns');

        InsertChildAttribute('headPose', 'roll');
        InsertChildAttribute('headPose', 'yaw');
        InsertChildAttribute('headPose', 'pitch');

        InsertChildAttribute('emotion', 'anger');
        InsertChildAttribute('emotion', 'contempt');
        InsertChildAttribute('emotion', 'disgust');
        InsertChildAttribute('emotion', 'fear');
        InsertChildAttribute('emotion', 'happiness');
        InsertChildAttribute('emotion', 'neutral');
        InsertChildAttribute('emotion', 'sadness');
        InsertChildAttribute('emotion', 'surprise');

        InsertChildAttribute('hair', 'bald');
        InsertChildAttribute('hair', 'invisible');
        InsertChildAttribute('hair', 'hairColor');

        InsertChildAttribute('makeup', 'eyeMakeup');
        InsertChildAttribute('makeup', 'lipMakeup');

        InsertChildAttribute('occlusion', 'foreheadOccluded');
        InsertChildAttribute('occlusion', 'eyeOccluded');
        InsertChildAttribute('occlusion', 'mouthOccluded');

        InsertChildAttribute('blur', 'blurLevel');
        InsertChildAttribute('blur', 'value');

        InsertChildAttribute('exposure', 'exposureLevel');
        InsertChildAttribute('exposure', 'value');

        InsertChildAttribute('noise', 'noiseLevel');
        InsertChildAttribute('noise', 'value');

        InsertChildAttribute('hairColor', 'color');
        InsertChildAttribute('hairColor', 'confidence');

        InsertChildAttribute('accessories', 'type');
        InsertChildAttribute('accessories', 'confidence');
    end;

    local procedure InsertAttribute(AttrName: Text[50]; IsEnabled: Boolean);
    var
        MicrosoftFaceAPISetupAttr: Record "Microsoft Face API Setup Attr.";
    begin
        MicrosoftFaceAPISetupAttr.Name := AttrName;
        MicrosoftFaceAPISetupAttr.Enabled := IsEnabled;
        MicrosoftFaceAPISetupAttr.Insert;
    end;

    local procedure InsertChildAttribute(ParentAttrName: Text[50]; AttrName: Text[50]);
    var
        MicrosoftFaceAPISetupAttr: Record "Microsoft Face API Setup Attr.";
        ParentId: Integer;
    begin
        MicrosoftFaceAPISetupAttr.SetRange(Name, ParentAttrName);
        MicrosoftFaceAPISetupAttr.FindFirst;
        ParentId := MicrosoftFaceAPISetupAttr.id;

        Clear(MicrosoftFaceAPISetupAttr);
        MicrosoftFaceAPISetupAttr.Name := AttrName;
        MicrosoftFaceAPISetupAttr."Parent Attribute" := ParentId;
        MicrosoftFaceAPISetupAttr.Insert;
    end;
}
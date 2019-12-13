pageextension 50100 "Face Detection API" extends "Customer Card"
{
    actions
    {
        addlast(Navigation)
        {
            action(FaceAPISetup)
            {
                Caption = 'Face API Setup';
                RunObject = page "Microsoft Face API Setup";
            }

            action(FaceDetection)
            {
                Caption = 'Face Detection';
                RunObject = page "Face Detection";
            }

            action(InitSetup)
            {
                Caption = 'Init Setup';
                RunObject = codeunit "Init. MS Face API Setup";
            }
        }
    }
}
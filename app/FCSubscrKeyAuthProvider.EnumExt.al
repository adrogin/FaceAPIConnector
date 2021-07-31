enumextension 50100 "FC Subscr. Key Auth. Provider" extends "AP Azure Auth. Provider"
{
    value(2; "Subscription Key")
    {
        Caption = 'Subscription Key';
        Implementation = "AP Azure Auth. Provider" = "Subscr. Key Auth. Provider";
    }
}
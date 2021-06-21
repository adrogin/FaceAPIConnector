enum 50100 "FC Recognition Group Status"
{
    Extensible = true;

    value(0; "Synchronization Pending") { }
    value(1; "Training Pending") { }
    value(2; "Training") { }
    value(3; Trained) { }
    value(4; Failed) { }
}
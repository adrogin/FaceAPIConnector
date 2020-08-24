enum 50100 "Recognition Group State"
{
    Extensible = true;

    value(0; "Synchronization Pending") { }
    value(1; "Training Pending") { }
    value(2; "Training") { }
    value(3; Trained) { }
}
class U014 extends Actor;

function Foo()
{
    local int I;

    I = 3;
    J0x10:
    if (I > 0)
    {
        I = I - 1;
        goto J0x10;
    }
}

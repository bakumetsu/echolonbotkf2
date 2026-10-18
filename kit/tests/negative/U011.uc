class U011 extends Actor;

var array<Actor> Items;

function Foo()
{
    local int i;
    for (i = 0; i < Items.Length; i++)
    {
        if (Items[i] == None)
            Items.Remove(i, 1);
    }
}

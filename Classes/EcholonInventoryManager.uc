class EcholonInventoryManager extends KFInventoryManager hidecategories(Navigation);

var byte MaxGrenades;

simulated function bool AddInventory(Inventory NewItem, optional bool bDoNotActivate)
{
    return super(InventoryManager).AddInventory(NewItem, bDoNotActivate);
}

simulated function Inventory CreateInventory(Class<Inventory> NewInventoryItemClass, optional bool bDoNotActivate)
{
    local KFWeapon KFWeap;
    local Class<KFWeapon> KFWeapClass;

    KFWeapClass = Class<KFWeapon>(NewInventoryItemClass);
    if (KFWeapClass != None)
    {
        if (CanCarryWeapon(KFWeapClass))
        {
            if (FindInventoryType(KFWeapClass) != None)
            {
                return None;
            }
            KFWeap = KFWeapon(super(InventoryManager).CreateInventory(KFWeapClass, bDoNotActivate));
            if ((WorldInfo.TimeSeconds - CreationTime) > 1.0 && (WorldInfo.TimeSeconds - LastCreatedWeaponTime) > 1.0)
            {
                PlayGiveInventorySound(ItemPickupSound);
                LastCreatedWeaponTime = WorldInfo.TimeSeconds;
            }
            if (KFWeap != None)
            {
                CheckForExcessRemoval(KFWeap);
            }
            return KFWeap;
        }
        else
        {
            return None;
        }
    }
    return super(InventoryManager).CreateInventory(NewInventoryItemClass, bDoNotActivate);
}

simulated function ShowAllHUDGroups()
{
}

function bool GiveInitialGrenadeCount()
{
    local byte OriginalGrenadeCount;

    OriginalGrenadeCount = GrenadeCount;
    if (Class'EcholonBot.EcholonMut'.default.bBotsUnlimitedAmmo)
    {
        GrenadeCount = 231;
    }
    else
    {
        GrenadeCount = 2;
    }
    return int(GrenadeCount) > int(OriginalGrenadeCount);
}

function bool AddGrenades(int AmountToAdd)
{
    if (Class'EcholonBot.EcholonMut'.default.bBotsUnlimitedAmmo)
    {
        GrenadeCount = 231;
        return false;
    }
    if ((KFPawn(Instigator) != None) && (int(GrenadeCount) < int(MaxGrenades)))
    {
        GrenadeCount = byte(Min(int(MaxGrenades), int(GrenadeCount) + AmountToAdd));
        return true;
    }
    return false;
}

function bool GiveWeaponsAmmo(bool bIncludeGrenades)
{
    local KFWeapon W;
    local bool bAddedAmmo;

    bAddedAmmo = false;

    foreach InventoryActors(Class'KFGame.KFWeapon', W)
    {
        if (!W.bInfiniteSpareAmmo && GiveWeaponAmmo(W))
        {
            bAddedAmmo = true;
        }
    }

    if (bIncludeGrenades)
    {
        AddGrenades(1);
    }

    PlayGiveInventorySound(AmmoPickupSound);
    return bAddedAmmo;
}

reliable client simulated function SetCurrentWeapon(Weapon DesiredWeapon)
{
    super(InventoryManager).SetCurrentWeapon(DesiredWeapon);
}

function bool AddArmorFromPickup()
{
    local KFPawn_Human KFPH;

    KFPH = KFPawn_Human(Instigator);
    if (KFPH != None && int(KFPH.Armor) != KFPH.GetMaxArmor())
    {
        PlayGiveInventorySound(ArmorPickupSound);
        KFPH.GiveMaxArmor();
        return true;
    }
    return false;
}

simulated function RemoveFromInventory(Inventory ItemToRemove)
{
    local Inventory Item;
    local bool bFound;

    if (ItemToRemove == None)
    {
        return;
    }

    if (PreviousEquippedWeapons[0] == ItemToRemove)
    {
        PreviousEquippedWeapons[0] = None;
    }

    if (PreviousEquippedWeapons[1] == ItemToRemove)
    {
        PreviousEquippedWeapons[1] = None;
    }

    if (PendingWeapon == ItemToRemove)
    {
        PendingWeapon = None;
    }

    if ((Instigator != None) && Instigator.Weapon == ItemToRemove)
    {
        Instigator.Weapon = None;
    }

    if (InventoryChain == ItemToRemove)
    {
        bFound = true;
        InventoryChain = ItemToRemove.Inventory;
    }
    else
    {
        Item = InventoryChain;
        while (Item != None)
        {
            if (Item.Inventory == ItemToRemove)
            {
                bFound = true;
                Item.Inventory = ItemToRemove.Inventory;
                break;
            }
            Item = Item.Inventory;
        }
    }

    if (bFound)
    {
        ItemToRemove.ItemRemovedFromInvManager();
        ItemToRemove.SetOwner(None);
        ItemToRemove.Inventory = None;
    }

    if ((((Instigator != None) && Instigator.Health > 0) && Instigator.Controller != None) && Instigator.Weapon == None)
    {
        if ((PendingWeapon != None) && PendingWeapon != ItemToRemove)
        {
            ChangedWeapon();
        }
        else
        {
            if (Instigator.Controller != None)
            {
                Instigator.Controller.SwitchToBestWeapon(true);
            }
        }
    }
}

simulated function Weapon GetBestWeapon(optional bool bForceADifferentWeapon, optional bool allow9mm)
{
    local KFWeapon W, BestWeapon;
    local float Rating, BestRating;

    BestWeapon = None;
    BestRating = 0.0;

    foreach InventoryActors(Class'KFWeapon', W)
    {
        if ((!W.IsA('KFWeap_HealerBase') && !W.IsA('KFWeap_Welder')) && W.HasAnyAmmo())
        {
            Rating = (W.GroupPriority + 10.0) * (2.0 + FRand());
            switch (W.InventoryGroup)
            {
                case 0:
                    Rating *= 2.5;
                    break;
                case 1:
                    Rating *= 1.5;
                    break;
                case 2:
                    break;
                default:
                    Rating *= 0.25;
                    break;
            }

            if (Class'EcholonMut'.default.BotTestWeapon != "" && string(W.Class.Name) ~= Class'EcholonMut'.default.BotTestWeapon)
            {
                Rating *= 100.0;  // test only (BotTestWeapon): the named weapon always wins
            }

            if (Class'EcholonMut'.default.bBotsUnlimitedAmmo)
            {
                W.SpareAmmoCount[0] = 9999;
                W.SpareAmmoCount[1] = 9999;
            }

            if (!W.HasAmmo(0) && Instigator.Controller.Enemy != None)
            {
                Rating *= 0.75;
            }

            if (W == Instigator.Weapon)
            {
                if (bForceADifferentWeapon)
                {
                    Rating *= 0.25;
                }
                else
                {
                    Rating *= 1.15;
                }
            }

            if (BestWeapon == None || Rating > BestRating)
            {
                BestWeapon = W;
                BestRating = Rating;
            }
        }
    }

    return BestWeapon;
}

simulated function SwitchToBestWeapon(optional bool bForceADifferentWeapon, optional bool check_9mm_logic = false)
{
    local Weapon BestWeapon;

    if (bForceADifferentWeapon || PendingWeapon == None)
    {
        BestWeapon = GetBestWeapon(bForceADifferentWeapon, check_9mm_logic);
        if (BestWeapon == None)
        {
            return;
        }
        if (BestWeapon == Instigator.Weapon)
        {
            return;
        }
    }
    Instigator.Controller.StopFiring();
    SetCurrentWeapon(BestWeapon);
}

defaultproperties
{
    MaxGrenades=5
    RemoteRole=ROLE_None
}

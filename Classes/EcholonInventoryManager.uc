class EcholonInventoryManager extends KFInventoryManager hidecategories(Navigation);

var byte MaxGrenades;

// @STUB(M1) - legacy:KFInventoryManager_Bot.AddInventory
simulated function bool AddInventory(Inventory NewItem, optional bool bDoNotActivate)
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.CreateInventory
simulated function Inventory CreateInventory(Class<Inventory> NewInventoryItemClass, optional bool bDoNotActivate)
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.ShowAllHUDGroups
simulated function ShowAllHUDGroups()
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.GiveInitialGrenadeCount
function bool GiveInitialGrenadeCount()
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.AddGrenades
function bool AddGrenades(int AmountToAdd)
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.GiveWeaponsAmmo
function bool GiveWeaponsAmmo(bool bIncludeGrenades)
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.SetCurrentWeapon
reliable client simulated function SetCurrentWeapon(Weapon DesiredWeapon)
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.AddArmorFromPickup
function bool AddArmorFromPickup()
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.RemoveFromInventory
simulated function RemoveFromInventory(Inventory ItemToRemove)
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.GetBestWeapon
simulated function Weapon GetBestWeapon(optional bool bForceADifferentWeapon, optional bool allow9mm)
{
}

// @STUB(M1) - legacy:KFInventoryManager_Bot.SwitchToBestWeapon
simulated function SwitchToBestWeapon(optional bool bForceADifferentWeapon, optional bool check_9mm_logic = false)
{
}

defaultproperties
{
    MaxGrenades=5
    RemoteRole=ROLE_None
}

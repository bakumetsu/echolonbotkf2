class EcholonWeaponInfo extends Object transient;

var Class<KFWeapon> WeaponClass;
var Class<KFPerk> Perk;
var float AIRating;
var int BuyPrice;
var int AmmoPricePerMag;
var int SecondaryAmmoMagSize;
var int SecondaryAmmoMagPrice;
var float PricePerBullet[2];
var bool bCanSell;

// @STUB(M5b) - legacy:AIWeaponInfo.InitInformation
final function bool InitInformation(Class<KFWeaponDefinition> Def, name ClassName)
{
}

defaultproperties
{
}

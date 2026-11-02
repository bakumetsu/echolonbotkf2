class EcholonZedProfile extends Object config(EcholonBot);

struct ZedRow
{
    var name ZedClass;
    var float Priority;
    var float BandMin;
    var float BandMax;
    var bool bAllowBash;
    var name AimBone;
};

var config array<ZedRow> Rows;

static function AddRow(name C, float Pri, float BMin, float BMax, bool bBash, name Bone)
{
    local ZedRow R;
    R.ZedClass = C;
    R.Priority = Pri;
    R.BandMin = BMin;
    R.BandMax = BMax;
    R.bAllowBash = bBash;
    R.AimBone = Bone;
    default.Rows.AddItem(R);
}

static function BuildDefaults()
{
    default.Rows.Length = 0;
    AddRow('KFPawn_ZedFleshpoundKing', 1.5, 800, 2000, false, 'head');
    AddRow('KFPawn_ZedBloatKing', 1.5, 800, 2000, false, 'head');
    AddRow('KFPawn_ZedHans', 1.5, 800, 2000, false, 'head');
    AddRow('KFPawn_ZedPatriarch', 1.5, 800, 2000, false, 'head');
    AddRow('KFPawn_ZedMatriarch', 1.5, 800, 2000, false, 'head');
    AddRow('KFPawn_ZedFleshpoundMini', 1.4, 600, 1500, false, 'head');
    AddRow('KFPawn_ZedFleshpound', 1.7, 800, 1600, false, 'head');
    AddRow('KFPawn_ZedScrake', 1.5, 700, 1500, false, 'head');
    AddRow('KFPawn_ZedSiren', 2.0, 400, 1500, false, 'head');
    AddRow('KFPawn_ZedHusk', 1.6, 600, 1800, false, 'head');
    AddRow('KFPawn_ZedBloat', 1.0, 500, 1200, false, 'head');
    AddRow('KFPawn_ZedStalker', 1.3, 0, 0, true, 'head');
    AddRow('KFPawn_ZedCrawler', 0.9, 0, 0, true, 'head');
    AddRow('KFPawn_ZedGorefast', 1.1, 0, 0, true, 'head');
}

static function EnsureRows()
{
    if (default.Rows.Length == 0)
        BuildDefaults();
}

static function WriteDefaults()
{
    BuildDefaults();
    StaticSaveConfig();
}

static function int FindRow(Pawn Z)
{
    local int i;
    EnsureRows();
    if (Z == None)
        return -1;
    for (i = 0; i < default.Rows.Length; i++)
        if (Z.IsA(default.Rows[i].ZedClass))
            return i;
    return -1;
}

static function float GetPriority(Pawn Z)
{
    local int idx;
    idx = FindRow(Z);
    if (idx < 0)
        return -1.0;
    return default.Rows[idx].Priority;
}

static function float GetBandMin(Pawn Z)
{
    local int idx;
    idx = FindRow(Z);
    if (idx < 0)
        return 0.0;
    return default.Rows[idx].BandMin;
}

static function float GetBandMax(Pawn Z)
{
    local int idx;
    idx = FindRow(Z);
    if (idx < 0)
        return 0.0;
    return default.Rows[idx].BandMax;
}

static function bool GetAllowBash(Pawn Z)
{
    local int idx;
    idx = FindRow(Z);
    if (idx < 0)
        return true;
    return default.Rows[idx].bAllowBash;
}

static function name GetAimBone(Pawn Z)
{
    local int idx;
    idx = FindRow(Z);
    if (idx < 0)
        return 'head';
    return default.Rows[idx].AimBone;
}

static function int RowCount()
{
    EnsureRows();
    return default.Rows.Length;
}

defaultproperties
{
}

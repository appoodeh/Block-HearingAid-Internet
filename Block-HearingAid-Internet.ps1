# ============================================================
# Block Bernafon Oasis2 / Oticon Genie2 / Phonak Target
# Inbound + Outbound
# Run PowerShell as Administrator
# ============================================================

$GroupName = "HearingAid Software - Internet Block"

# إزالة القواعد القديمة من نفس المجموعة إذا شغلت السكربت سابقاً
Get-NetFirewallRule -Group $GroupName -ErrorAction SilentlyContinue |
    Remove-NetFirewallRule -ErrorAction SilentlyContinue

# مجلد Program Files (x86)
$PF86 = ${env:ProgramFiles(x86)}

# البرامج التي ذكرتها صراحةً
$ExplicitPrograms = @(
    "$PF86\Bernafon\Oasis2\Oasis.exe",
    "$PF86\Oticon\Genie2\ImcProxy\Phoenix.IMCProxy.Console.exe",
    "$PF86\Phonak\Phonak Target\Target.exe",
    "$PF86\Phonak\Phonak Target\Core.DeviceAbstraction.PalioHiProWrapper.Hw.Implementation.exe",
    "$PF86\Oticon\Genie2\Genie.exe"
)

# المجلدات التابعة للبرامج:
# سيتم البحث بداخلها عن كل ملفات EXE أيضاً
$Folders = @(
    "$PF86\Bernafon\Oasis2",
    "$PF86\Oticon\Genie2",
    "$PF86\Phonak\Phonak Target"
)

$Programs = @()

# إضافة الملفات المحددة
foreach ($Program in $ExplicitPrograms) {
    if (Test-Path $Program) {
        $Programs += (Resolve-Path $Program).Path
    }
}

# إضافة جميع ملفات EXE التابعة لهذه البرامج
foreach ($Folder in $Folders) {
    if (Test-Path $Folder) {
        $Programs += Get-ChildItem `
            -Path $Folder `
            -Filter *.exe `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
    }
}

# إزالة التكرارات
$Programs = $Programs | Sort-Object -Unique

# إنشاء قواعد الحظر
foreach ($Program in $Programs) {

    $FileName = [System.IO.Path]::GetFileName($Program)

    New-NetFirewallRule `
        -DisplayName "BLOCK HA OUT - $FileName" `
        -Group $GroupName `
        -Direction Outbound `
        -Program $Program `
        -Action Block `
        -Profile Any `
        -Enabled True | Out-Null

    New-NetFirewallRule `
        -DisplayName "BLOCK HA IN - $FileName" `
        -Group $GroupName `
        -Direction Inbound `
        -Program $Program `
        -Action Block `
        -Profile Any `
        -Enabled True | Out-Null

    Write-Host "BLOCKED: $Program"
}

Write-Host ""
Write-Host "---------------------------------------------"
Write-Host "Blocked EXE files: $($Programs.Count)"
Write-Host "Inbound  : BLOCKED"
Write-Host "Outbound : BLOCKED"
Write-Host "Profiles : Domain / Private / Public"
Write-Host "---------------------------------------------"
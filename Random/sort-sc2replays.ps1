#requires -Version 1
$SCBASEDIR = 'G:\fuul\Documents\StarCraft II\Accounts\100551093\2-S2-1-525799\Replays\Multiplayer\AutoMM'

$FormatArray = @('1v1', '2v2', '3v3', '4v4')

ForEach($directory in $FormatArray) 
{
    if (Test-Path -Path $SCBASEDIR\$directory\AutoMM\)
    {
        #Write-Output "$SCBASEDIR\$directory\Automm found"
        $replays = Get-ChildItem  -Recurse -Path "$SCBASEDIR\$directory\AutoMM\$directory\*.sc2replay"
        $replays | Move-Item -Destination "$SCBASEDIR\$directory\"
        
        if(!(Get-ChildItem  -Recurse -Path "$SCBASEDIR\$directory\AutoMM\$directory\*.sc2replay"))
        {
            Write-Output 'Keine Replays gefunden fuer '$directory
            Remove-Item -Path "$SCBASEDIR\$directory\AutoMM" -Confirm:$false
        }
    }
}

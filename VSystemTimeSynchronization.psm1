Get-ChildItem -Path $PSScriptRoot -File -Filter *.ps1 | ForEach-Object -Process `
{
    . $_.FullName
}

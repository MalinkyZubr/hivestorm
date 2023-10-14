# scan for unusual EXE files

function Show-Files {
    param (
        $fileList
    )
    for($i=0; $i -le $fileList.Length; $i++)
    {
        Write-Output "$i ---- $fileList[$i]"
    }
}

Write-Output "[+] Scanning for abnormal EXE files"
$exeLocal = Get-ChildItem -Recurse -Path C:\ -Filter "*.exe" | Select-Object -ExpandProperty FullName
$exeListProper = Get-Content -Path $PSScriptRoot\lists\exeList.txt 
$exeListProper = $exeListProper -split "`r`n"

$potentiallyDangerous = @()

foreach($file in $exeLocal){
    if(!$exeListProper -contains $file)
    {
        $potentiallyDangerous += $file
    }
}

if($potentiallyDangerous.Length -gt 0)
{
    Write-Output "[!] Files were found that seem unusual. Here they are"
    Show-Files -fileList $potentiallyDangerous
    Write-Output "[?] Would you like to delete any?"
    $decision = Read-Host -Prompt "(y/n)"
    if($decision -eq "y")
    {
        while($true)
        {
            clear
            Show-Files -fileList $potentiallyDangerous
            Write-Output "`n[+] Enter an index to delete file. Enter q to quit"
            $choice = Read-Host -Prompt ">> "
            try
            {
                $choice = [int]$choice
                if($choice -lt $potentiallyDangerous.Length -and $choice -ige 0)
                {
                    Remove-Item -Path $potentiallyDangerous[$choice]
                    Write-Host "[+] Removed $potentiallyDangerou[$choice]"
                }
            }
            catch [RuntimeException] 
            {
                if($choice -eq "q")
                {
                    Write-Output "[+] Exiting"
                    break
                }
                else 
                {
                    Write-Output "[!] Enter Valid Input"
                }
            }
        }
    }
}
Write-Output "[+] No suspicious exes detected"
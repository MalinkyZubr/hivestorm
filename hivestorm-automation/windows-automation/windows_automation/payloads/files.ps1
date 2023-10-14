# remove unauthorized file extensions
# remove unauthorized file names
# these are stored in cfg json and processed by the python script
# find all binary files, ask user which to delete
# get list of allowed EXEs

Write-Output "[+] Now checking for unauthorized file extensions"

param (
    [Array]$unauthorized_extensions,
    [Array]$unauthorized_programs
)

# check for unauthorized file extensions
Write-Output "[+] Now checking for unauthorized file extensions"
foreach($extension in $unauthorized_extensions) {
    $violators = Get-ChildItem C:\Users -Recurse -Filter "*.$extension" | Select-Object Directory, Name
    foreach($violator in $violators) {
        $directory = $violator.Directory
        $name = $violator.Name
        Remove-Item -Path "$directory\$name"
        Write-Output "[+] File $directory\$name removed for violating local policy"
    }
}

# scan for illegal programs
Write-Output "[+] Now checking for unauthorized programs"
foreach($progname in $unauthorized_programs) {
    $violators = Get-ChildItem -Path 'C:\' -Filter "*$progname*" -Directory -Recurse | Select-Object -ExpandProperty FullName
    if($violators.Length -gt 0) {
        Write-Output "[!] Detected program files for $progname at:`n$violators`nFixing the issue now..."
        foreach($violator in $violators) {
            Remove-Item -Path "$violator"
            Write-Output "[+] Successfully removed $violator"
        }
    }
    else {
        Write-Output "[+] $progname not found on the system!"
    }
}

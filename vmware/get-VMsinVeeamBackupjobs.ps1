#
$path = "$env:temp\veeam"
mkdir $path -ErrorAction SilentlyContinue
cd $path

Get-VBRJob | ForEach-Object -process {
        $file = $_.name
        $file += ".txt"
        $file =  New-Item -Path $file
        $_.getobjectsinjob() | ForEach-Object { 
                add-content -Path $file  -Value $_.Name
        }
}
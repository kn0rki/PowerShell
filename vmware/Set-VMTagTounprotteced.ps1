 $tagtoset = get-tag -Category Backup -Name NO
 get-vm |  ForEach-Object {
    $vm = $_
    $foo = $vm | Get-Annotation | Where-Object { $_.Name -eq "VEEAM" -and $_.Value -eq ""}
     $foo |  ForEach-Object{
        New-TagAssignment -Tag $tagtoset -Entity $vm
        }
}


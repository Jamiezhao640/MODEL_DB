
Set-Location "C:\Users\jamie\source\repos\navidatainc\MODEL_DB"

# Set-Location "C:\Users\jzhang2\Documents\GitHub\stpauls_db"

########################################################################
#      Combine into one file
########################################################################


$dir_view = ".\View"
$dir_SP = ".\Sp_fn"

$outFile = ".\Database_Versioning\999_generated_combined_all.sql"

"------------Merging Date and Time: $(Get-Date) --------------------" | Out-File -FilePath $outfile -Encoding ascii 


# Build the file list
$fileList = Get-ChildItem -Path $dir_view  -Recurse -Filter *.sql -File | % { $_.FullName}
foreach ($file in $filelist)
{
    "`r`n`r`n`r`n" | Out-File -FilePath $outfile -Encoding ascii -Append
    "---------------------------- $file --------------------" | Out-File -FilePath $outfile -Encoding ascii -Append

    Get-Content $file | Out-File -FilePath $outfile -Encoding ascii -Append
}


$fileList = Get-ChildItem -Path $dir_SP  -Recurse -Filter *.sql -File | % { $_.FullName}
foreach ($file in $filelist)
{
    "`r`n`r`n`r`n" | Out-File -FilePath $outfile -Encoding ascii -Append
    "---------------------------- $file --------------------" | Out-File -FilePath $outfile -Encoding ascii -Append

    Get-Content $file | Out-File -FilePath $outfile -Encoding ascii -Append
}


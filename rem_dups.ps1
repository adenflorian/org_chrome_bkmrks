# Removes duplicate bookmarks from an exported bookmarks html from google chrome
# Also removes empty folders afterwards
# Author: David "AdenFlorian" Valachovic - 2014 - AdenFlorian@gmail.com

# Settings
$removeEmptyFolders = $true

cp bkmrks.html fixed_bkmrks.html
$file = gc fixed_bkmrks.html
echo ($file.Count.ToString() + " lines to go through...")
$totalLines = $file.Count
$fivepercent = $totalLines / 20
$removedLineCount = 0
$nextCheckpoint = $fivepercent

# Remove duplicate bookmarks by matching URL
for ($i = 0; $i -lt $totalLines; $i++) {
    if ($i -gt $nextCheckpoint) {
        echo (($i / $totalLines * 100).ToString() + "% done")
        echo ($removedLineCount.ToString() + " duplicate lines removed so far...")
        $nextCheckpoint += $fivepercent
    }
    $line = $file[$i]
    if ($line -eq $null -or -not($line -match "<DT><A HREF=")) {continue}
    $line = [regex]::Escape($line)
    if ($line -match 'HREF=(".*?")') {
        $line = $Matches[1]
    } else {
        continue
    }
    for ($j = $i + 1; $j -lt $totalLines; $j++) {
        if ($file[$j] -match $line) {
            $file[$j] = $null
            $removedLineCount++
        }
    }
}

Set-Content fixed_bkmrks.html $file

if ($removeEmptyFolders) {
    echo "Removing folders next..."

    $file = gc fixed_bkmrks.html
    echo ($file.Count.ToString() + " lines to go through...")
    $totalLines = $file.Count
    $fivepercent = $totalLines / 20
    $nextCheckpoint = $fivepercent

    $removedFolderCount = 0
    $removedFolder = $true

    # Keep doing until no more empty folders
    # Have to do this multiple times because of null lines in $file array
    # Need to write to disk then reload file
    # Would be better if I could find a way to remove elements from array, and have remaining elements shift left
    while ($removedFolder) {
        $removedFolder = $false
        for ($i = 0; $i -lt $totalLines; $i++) {
            if ($i -gt $nextCheckpoint) {
                echo (($i / $totalLines * 100).ToString() + "% done")
                echo ($removedFolderCount.ToString() + " empty folders removed so far...")
                $nextCheckpoint += $fivepercent
            }

            $line = $file[$i]
            if ($line -eq $null -or -not($line -match "<DT><H3 ADD_DATE=")) {continue}
            if ($file[$i + 2] -match '</DL><p>') {
                $file[$i] = $null
                $file[$i + 1] = $null
                $file[$i + 2] = $null
                $removedFolderCount++
                $i += 2
                $removedFolder = $true
            }
        }
        Set-Content fixed_bkmrks.html $file
        $file = gc fixed_bkmrks.html
        echo ($file.Count.ToString() + " lines to go through...")
        $totalLines = $file.Count
        $fivepercent = $totalLines / 20
        $nextCheckpoint = $fivepercent
    }
}

echo ("Done: Removed " + $removedLineCount.ToString() + " lines and " + $removedFolderCount.ToString() + " folders!")

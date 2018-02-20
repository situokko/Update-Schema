# Updates database schema
#
# Dependencies: 
#   - SqlCmd (Microsoft Command Line Utilities 14.0 for SQL Server)
#            https://www.microsoft.com/en-us/download/details.aspx?id=53591
#   - Invoke-SqlCmd (I don't know where this comes from?)

Param(
	[string]$dbServer = "localhost",
	[string]$dbName,
	[string]$dbUser,
	[string]$dbPassword = $env:UPDATE_SCHEMA_PASSWORD,
	[boolean]$verbose = $false
)

function parseUpdateId($file) {
    $match = $file | Select-String -pattern "(\d+)_.*?\.sql"
    if ($match) {
        $id = $match.Matches.Groups[1].Value
        if ($id) {
            return [int]$id
        }
    }
}
function parsePatchFile($file) {
    function New-PatchItem() {
        Param(
           [string]$patch,
           [string]$IncludeFile
        )
        $item = new-object PSObject
        $item | add-member -type NoteProperty -Name Patch -Value $patch.Trim()
        $item | add-member -type NoteProperty -Name IncludeFile -Value $IncludeFile
        
        return $item
    }
    function parseIncludeFile($line) {
        $match = $line | Select-String -pattern "[ ]*--[ ]*#include[ ]+(.*)"
        if ($match) {
            return $match.Matches.Groups[1].Value
        }
    }

    function appendIfContent($buffer) {
        if ($buffer) {
            $buffer.Append([Environment]::NewLine)
            $item = New-PatchItem $buffer.ToString()
            $items.Add($item)
            $buffer.Clear()
        }
    }

    $buffer = New-Object System.Text.StringBuilder
    $items = New-Object System.Collections.ArrayList
    #Get content returns array of lines (and removes newlines)
    foreach ($line in (Get-Content -Path $file)) {
        $includeFile = parseIncludeFile($line)
        if ($includeFile) {
            $buffer.Append($line).Append([Environment]::NewLine)
            appendIfContent($buffer)
            
            $content = (Get-Content -Path $includeFile) -Join [Environment]::NewLine
            $buffer.Append($content).Append([Environment]::NewLine)
            $item = New-PatchItem $buffer.ToString() -IncludeFile $includeFile
            $items.Add($item)
            $buffer.Clear()

        } else {
            $buffer.Append($line).Append([Environment]::NewLine)
        }
    }
    appendIfContent($buffer)

    return $items
}

function executeQuery($sql) {
    if ($sql -is [string] -And $sql.Trim().Length) { 
        return Invoke-Sqlcmd -Username $dbUser -Password $dbPassword -Database $dbName -Hostname $dbServer -Query $sql
    }
}

function executeSqlcmd($sql) {
    $sql = $sql.Trim()
    if ($verbose) {
        Write-Host "<START>" $sql "<END>"
    }

    $tempFileName = 'Update-Schema.sql.tmp'
    
    # Write SQL into a file to prevent issues with double quotes inside the sql
    $sql | Out-File $tempFileName
    
    SQLCMD -U $dbUser -P $dbPassword -d $dbName -S $dbServer -b -V 1 -m-1 -i $tempFileName
    
    Remove-Item $tempFileName
}

function getCurrentVersion() {
    $query = @"
        IF object_id('dbo.database_schema_changelog') is not null
            SELECT max(id) as max_id FROM database_schema_changelog
        ELSE
            SELECT 0 as max_id;
        GO    
"@
    $rs = executeQuery($query)
    return $rs.max_id
}

function parseUpdates() {
    $allUpdateNames = Get-ChildItem *.sql | Sort-Object name | Select-Object -ExpandProperty "Name"
    $allUpdates = [ordered]@{}
    foreach ($file in $allUpdateNames) {
        $id = parseUpdateId($file)
        # Hashtable key needs to be a string or otherwise it cannot be accessed later
        # as Hashtable.Get(int) returns by index not by key
    
        #$allUpdates.Add(parseUpdateId($file), $file) # Why this does not work???
        $allUpdates.Add([string]$id, $file) # But this does
    }
    return $allUpdates
}

###
### Main program ###
###

$max = getCurrentVersion($null)
Write-Host "Current schema version:" $max

$allUpdates = parseUpdates($null)

$latestUpdateId = parseUpdateId($allUpdates[-1])
Write-Host "Lastest version:" $latestUpdateId

for ($i = $max+1; $i -le $latestUpdateId; $i++) {
    #Note all indexes might not exist if they have been deleted
    $file = $allUpdates[[string]$i]
    if ($file) {
        $parts = parsePatchFile($file)
        $partStrings = $parts | ForEach-Object { [string]$_.Patch }
        $sql = [system.String]::Join([Environment]::NewLine, $partStrings)
        Write-Host ""
        Write-Host "Applying $file"
        executeSqlcmd($sql)
    }
}


function Rename-PhishShowFolder {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $Path = '.',
        [switch]                $Recurse
    )

    # --- compile a single, reusable regex  ---
    $Pattern = [regex] @'
(?x)
(?<Date>\d{4}-\d{2}-\d{2})\s+
(?<Venue>[^,]+?)\s*,\s*
(?<City>[^,]+?)\s*,\s*
(?<State>[A-Z]{2})\b
'@

    # characters Windows forbids in file / folder names
    $Invalid = ([IO.Path]::GetInvalidFileNameChars() -join '') -replace '\]', '\]'

    Get-ChildItem -LiteralPath $Path -Directory -Recurse:$Recurse |
    ForEach-Object {
        $oldName = $_.Name
        if ($oldName -match $Pattern) {

            # clean pieces & build canonical name
            $venue = ($Matches.Venue -replace "[${Invalid}]", '').Trim()
            $city  = ($Matches.City  -replace "[${Invalid}]", '').Trim()
            $newName = "$($Matches.Date) $venue, $city, $($Matches.State)"

            if ($oldName -ne $newName) {
                try {
                    if ($PSCmdlet.ShouldProcess($oldName, "Rename to '$newName'")) {
                        Rename-Item -LiteralPath $_.FullName -NewName $newName -ErrorAction Stop
                        Write-Verbose "Renamed: '$oldName' -> '$newName'"
                    }
                }
                catch {
                    Write-Warning "Failed to rename '$oldName': $_"  # graceful error handling
                }
            }
        }
        else {
            Write-Verbose "Skipped '$oldName' – pattern not found"
        }
    }
}

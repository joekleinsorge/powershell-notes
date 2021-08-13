<#
.SYNOPSIS
    A way for me to organize and add functionality to my note taking.

.DESCRIPTION
    Allows the user to create a new note in Notepad automatically named the current month_day_year if no other inputs are used. 
    Allows the user to specify the name of the new note with the "-name" parameter, if a note with that name is already created in the directory, then it will open that note.
    Allows the user to create a "week" note if the "-week" switch is used, this combines all the notes that were edited in the last week into one note.
    Allows the user to create a "year" note if the "-year" switch is used, this combines all the notes that were edited in the last year into one note.
    Allows the user to search through all notes in the directory for a string pattern match when the "-search" parameter is used.
    Allows the user to list all of the notes inside of the directory if the "-list" parameter is used.
    Allows the user to specify the note directory with the "-directory" parameter.

.EXAMPLE
    Notes.ps1 

    This will create a new note in "-directory" with the current date as the name and open the note in notepad.
    If the note already exists, it will be opened in notepad.

.EXAMPLE
    Notes.ps1 -name "AzureNotes"

    This will create a new note in "-directory" with AzureNotes as the name and open the note in notepad.
    If the note already exists, it will be opened in notepad.

.EXAMPLE
    Notes.ps1 -week

    This will create a "week" note by combining all the notes in the directory that use the default date naming scheme in the last week. 
    The week note will use the current week's Sunday date as the start of the week.
    The note will be name month_day_year_week, i.e. "01_15_21_week.txt".

.EXAMPLE
    Notes.ps1 -year

    This will create a "year" note by combining all the notes in the directory use the default date naming scheme within the last year. 
    The note will be named for the year, i.e. "2021.txt".

.EXAMPLE
    .\Notes.ps1 -search kubernetes

    Found string in:

    C:\Notes\08_08_21.txt:1:Building and running applications successfully in Azure Kubernetes Service (AKS) require understanding and implementation of some key considerations, including:
    C:\Notes\08_08_21.txt:10:Kubernetes includes security components, such as network policies and Secrets.
    C:\Notes\08_08_21.txt:14:    Keep your AKS cluster running the latest OS security updates and Kubernetes releases.

    This will search through each ".txt" file in the directory and find any matches to "kubernetes". 
    It will output the name of the note it was found in, as well as the line number and the text line. 
    
.EXAMPLE
    .\Notes.ps1 -list
    Found the following notes:
    07_26_21
    07_29_21
    08_02_21_Week
    08_06_21
    08_08_21
    todo
    vcp-cma

    This will list out the names of all the ".txt" files in the directory.

.EXAMPLE
    .\Notes.ps1 -directory

    This will change the directory the script uses to create and search for notes in. I would suggest changing the default value inside the script to youre preferred location and rarely using the parameter. 

.NOTES
   Author: Joey Kleinsorge
   This script is provided "AS IS" without warranties or guarantees of any kind. USE AT YOUR OWN RISK. Public domain, no rights reserved.
   
   A detailed walkthrough of this script can be found on my website at: https://joeykleinsorge.com/how-i-take-notes/
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [string]$name = (Get-Date -Format 'MM_dd_yy'),
    [Parameter(Mandatory = $False)]
    [switch]$week,
    [Parameter(Mandatory = $False)]
    [switch]$year,
    [Parameter(Mandatory = $False)]
    [string]$search,
    [Parameter(Mandatory = $False)]
    [switch]$list,
    [Parameter(Mandatory = $False)]
    [string]$directory = '' # IMPORTANT, set this to your default note folder! Example 'C:\Notes'
)
BEGIN {
    #_Check flags
    if ($week) {
        $name = (Get-Date ).AddDays( - (Get-Date).DayOfWeek.value__ + 1).ToString('MM_dd_yy') + '_Week' #_Set $name to start of the current week
    }
    elseif ($year) {
        $name = (Get-Date).Year 
    }

    $file = $name + '.txt' #_Append file type to name
    $filepath = $directory + '\' + $file
}    
PROCESS {
    if ($list) {
        $listResults = (Get-ChildItem -Path $directory -Filter '*.txt').BaseName
    }
    elseif ($search) {
        #_Search through all notes for the string
        $searchResults = Get-ChildItem -Path $directory -Filter '*.txt' | Select-String -Pattern $search 
    }
    else {
        #_Check Week flag
        if ($week) {
            if (Test-Path $filepath) {
                Remove-Item $filepath -Force #_Delete the file if it already exists
            }
            New-Item $filepath 
            $notes = Get-ChildItem -Path $directory -Filter *.txt
            foreach ($note in $notes) {
                if (($note.BaseName -ne $name) -and ($note.BaseName -gt $name) -and ($note.BaseName -le (Get-Date -Format 'MM_dd_yy'))) {
                    Write-Host 'Adding notes from:' $note.BaseName -ForegroundColor Yellow
                    Write-Host 'Adding content:' (Get-Content $note) -ForegroundColor Cyan
                    Add-Content -Path $filepath -Value $note.BaseName 
                    Add-Content -Path $filepath -Value (Get-Content $note)
                    Add-Content -Path $filepath -Value '' 
                }
            }
        }
        #_Check Year flag
        elseif ($year) {
            if (Test-Path $filepath) {
                Remove-Item $filepath -Force #_Delete the file if it already exists
            }
            New-Item $filepath
            $notes = Get-ChildItem -Path $directory -Filter '*.txt'
            foreach ($note in $notes) {
                if (($note.BaseName.Substring($note.BaseName.length - 2) -eq $name.Substring($name.length - 2)) -and ($note.BaseName -ne $name)) {
                    Write-Host 'Adding notes from:' $note.BaseName -ForegroundColor Yellow
                    Write-Host 'Adding content:' (Get-Content $note) -ForegroundColor Cyan
                    Add-Content -Path $filepath -Value $note.BaseName 
                    Add-Content -Path $filepath -Value (Get-Content $note)
                    Add-Content -Path $filepath -Value '' 
                }
            }
        }
        #_Check if file already exists
        elseif (-not(Test-Path -Path $filepath)) {
            New-Item $filepath #_Create the new file
        }
    }
}
END {
    if ($list) {
        Write-Host 'Found the following notes:' -ForegroundColor Yellow
        $listResults
    }
    elseif ($search) {
        if ($searchResults) {
            Write-Host 'Found string in:' -ForegroundColor Yellow
            $searchResults
        }
        else {
            Write-Warning 'Unable to find a match' 
        }
    }
    else {
        notepad.exe $filepath #_Open the file in notepad
    }
}


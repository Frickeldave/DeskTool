function Write-DTLog() {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$Component,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string]$Type="Info"
        
    )

    if ([string]::IsNullOrEmpty($env:DeskLog_RootDir)) { $env:DeskLog_RootDir=$PSScriptRoot }
    if ($env:DeskLog_LogToFile -eq $true) { $Target="File" } else {$Target="Console"}
    if ([string]::IsNullOrEmpty($env:DeskLog_LogFileDir)) { $env:DeskLog_LogFileDir=$env:DeskLog_RootDir }
    if ([string]::IsNullOrEmpty($env:DeskLog_LogFileName)) { $env:DeskLog_LogFileName="DeskLog.log" }


    if(Get-Command Write-HalaLog) { 
        Write-DTOut -Message $Message -Target $Target -Component $Component -Type $Type -LogFileDir $env:DeskLog_LogFileDir -LogFileName $env:DeskLog_LogFileName
    } else {
        Write-Output $Message
    }
}

function Write-DTOut {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("File", "Console")]
        [string]$Target="Console",

        [Parameter(Mandatory=$false)]
        [string]$LogFileDir=$null,

        [Parameter(Mandatory=$false)]
        [string]$LogFileName=$null,

        [Parameter(Mandatory=$false)]
        [string]$Component="Main",

        [Parameter(Mandatory=$false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string]$Type="Info"
    )

    $_datetime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $_type = "I"
    if($Type -eq "Warning" ) { $_type = "W" }
    if($Type -eq "Error" ) { $_type = "E" }
    
    $_message="$_datetime $_type $Component - $Message"

    if($Target -eq "File") {
        
        if($null -eq $LogFileDir -and $IsLinux) {
            $_logdir = "/tmp"
        }
        elseif($null -eq $LogFileDir -and $IsWindows) {
            $_logdir = "$env:TEMP"
        } else {
            $_logdir = $LogFileDir
        }

        if($null -eq $LogFileName) {
            $_logfile = "hala.log"
        } else {
            $_logfile = $LogFileName
        }

        # Test if file is acccessable
        try { 
            [io.file]::OpenWrite("$($_logdir)/$($_logfile)").close() 
        } catch { 
            Write-Error "Unable to write to output file $($_logdir)/$($_logfile)" 
        }
        $_message | Out-File -Append -Encoding UTF8 -FilePath "$($_logdir)/$($_logfile)"
    } else {
        $_message | Out-Host
    }
}
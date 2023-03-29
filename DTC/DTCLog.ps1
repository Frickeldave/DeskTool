
function Write-DTCLog {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("File", "Console")]
        [string]$Target=$null,

        [Parameter(Mandatory=$false)]
        [string]$LogFileDir=$null,

        [Parameter(Mandatory=$false)]
        [string]$LogFileName=$null,

        [Parameter(Mandatory=$false)]
        [switch]$RefreshLogFile,

        [Parameter(Mandatory=$false)]
        [string]$Component="Main",

        [Parameter(Mandatory=$false)]
        [ValidateSet("Error", "Warning", "Info")]
        [string]$Type="Info"
    )

    # Logfile information can be set by global variables when there are not provided 
    if([string]::IsNullOrEmpty($LogFileDir)) { $LogFileDir = $global:_dt_log_file_dir }
    if([string]::IsNullOrEmpty($LogFileName)) { $LogFileName = $global:_dt_log_file_name }
    if([string]::IsNullOrEmpty($Target)) { $Target = $global:_dt_log_target }
    
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
            $_logfile = "app.log"
        } else {
            $_logfile = $LogFileName
        }

        # Test if file is acccessable
        try { 
            [io.file]::OpenWrite("$($_logdir)/$($_logfile)").close() 
        } catch { 
            Write-Error "Unable to write to output file $($_logdir)/$($_logfile)" 
        }
        if($RefreshLogFile) {
            $_message | Out-File -Encoding UTF8 -FilePath "$($_logdir)/$($_logfile)"
        } else {
            $_message | Out-File -Append -Encoding UTF8 -FilePath "$($_logdir)/$($_logfile)"
        }
    } else {
        $_message | Out-Host
    }
}
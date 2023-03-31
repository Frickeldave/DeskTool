$script:_dts_log_file_dir = $null
$script:_dts_log_file_name = $null
$script:_dts_log_target = $null

function Initialize-DTCLog {
    [CmdletBinding()]
    param (
        [string]$LogBasePath,
        [string]$LogFolder,
        [string]$LogFileDir,
        [string]$LogFileName,
        [string]$LogTarget
    )

	$script:_dts_log_file_dir = $(if([string]::IsNullOrEmpty($LogFileDir)) { "$LogBasePath\$LogFolder" } else { $LogFileDir })
	$script:_dts_log_file_name = $(if([string]::IsNullOrEmpty($LogFileName)) { "default.log" } else { $LogFileName })
	$script:_dts_log_target = $(if([string]::IsNullOrEmpty($LogTarget)) { "Console" } else { $LogTarget })

    if (-Not (Test-Path $script:_dts_log_file_dir)) {
        New-Item -Path $script:_dts_log_file_dir -ItemType Directory | Out-Null
    }

}



function Write-DTCLog {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [switch]$RefreshLogFile,

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

    if($script:_dts_log_target -eq "File") {
        
        if($null -eq $script:_dts_log_file_dir -and $IsLinux) {
            $_logdir = "/tmp"
        }
        elseif($null -eq $script:_dts_log_file_dir -and $IsWindows) {
            $_logdir = "$env:TEMP"
        } else {
            $_logdir = $script:_dts_log_file_dir
        }

        if($null -eq $script:_dts_log_file_name) {
            $_logfile = "app.log"
        } else {
            $_logfile = $script:_dts_log_file_name
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
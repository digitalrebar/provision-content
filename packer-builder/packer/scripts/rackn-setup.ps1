#param(
#    [string]$DrpcliPath = "drpcli.exe"
#)
$CurtinDir = "c:\curtin"
$DrpcliPath = "c:\curtin\drpcli.exe"

Write-Host "---------------------------------------------------------------------------"
Write-Host "Starting RackN specific setup steps ... "
Write-Host

if(!(Test-Path $CurtinDir))
{
    Write-Host "Creating '$CurtinDir' directory for image-deploy ... "
    New-Item -Path $CurtinDir -ItemType directory
} else {
    Write-Host "Path '$CurtinDir' already exists, not (re)creating ... "
}

Write-Host

Write-Host "Stage 'drpcli' binary in image ... "
if(!(Test-Path -PathType Leaf $DrpcliPath))
{
    $url = "https://rebar-catalog.s3-us-west-2.amazonaws.com/drpcli/v4.3.2/amd64/windows/drpcli.exe"
    Write-Host "Local copy of 'drpcli.exe' not found..."
    Write-Host "Attempting to download and use from: $url"
    $output = "$DrpcliPath"
    $start_time = Get-Date

    Invoke-WebRequest -Uri $url -OutFile $output

    if(!(Test-Path -PathType Leaf $DrpcliPath))
    {
        throw "Zip file ""$DrpcliPath"" does not exist (even tried download from $url)"
    } else {
        Write-Output "Download completed..."
	Write-Output ">>> DRPCLI path in image:  '$DrpcliPath'"
        Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    }
} else {
    Write-Host "'$DrpcliPath' binary already exists, not downloading again ..."
}

Write-Host
Write-Host "COMPLETED RackN specific setup steps ... "
Write-Host "---------------------------------------------------------------------------"

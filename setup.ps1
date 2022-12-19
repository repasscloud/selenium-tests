$selenium_webdriver_download = 'https://www.selenium.dev/downloads/'

if ($IsLinux)
{

}
if ($IsWindows)
{

}
if ($IsMacOS)
{
    $download_page = (Invoke-WebRequest -Uri $selenium_webdriver_download -UseBasicParsing -DisableKeepAlive).Links.outerHTML | 
        Select-String -Pattern 'https\:\/\/.*nuget\.org.*Selenium\.WebDriver' | 
        Select-Object -ExpandProperty Matches -First 1 | 
        Select-Object -ExpandProperty Value
    $download_page = ([System.Net.WebRequest]::CreateDefault($download_page)).GetResponse()
    $nuget_pkg = $download_page.ResponseUri.OriginalString
    if (Test-Path -Path "/tmp/$(Split-Path -Path $nuget_pkg -Leaf)") { Remove-Item -Path "/tmp/$(Split-Path -Path $nuget_pkg -Leaf)" -Force -Confirm:$false }
    Invoke-WebRequest -Uri $nuget_pkg -OutFile "/tmp/$(Split-Path -Path $nuget_pkg -Leaf)" -UseBasicParsing -DisableKeepAlive
    7za x "/tmp/$(Split-Path -Path $nuget_pkg -Leaf)" -o"${PSScriptRoot}"
}
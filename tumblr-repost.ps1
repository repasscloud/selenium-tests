$selenium_webdriver_download = 'https://www.selenium.dev/downloads/'

if ($IsLinux)
{
    which 7za
}
if ($IsWindows)
{
    # get chrome version installed from one of these:
    #   - https://stackoverflow.com/questions/52457766/how-can-i-get-google-chromes-version-number
    (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo
}
if ($IsMacOS)
{
    # get selenium details
    $download_page = (Invoke-WebRequest -Uri $selenium_webdriver_download -UseBasicParsing -DisableKeepAlive).Links.outerHTML | 
        Select-String -Pattern 'https\:\/\/.*nuget\.org.*Selenium\.WebDriver' | 
        Select-Object -ExpandProperty Matches -First 1 | 
        Select-Object -ExpandProperty Value
    $download_page = ([System.Net.WebRequest]::CreateDefault($download_page)).GetResponse()
    $nuget_pkg = $download_page.ResponseUri.OriginalString
    if (Test-Path -Path "/tmp/$(Split-Path -Path $nuget_pkg -Leaf)") { Remove-Item -Path "/tmp/$(Split-Path -Path $nuget_pkg -Leaf)" -Force -Confirm:$false }
    Invoke-WebRequest -Uri $nuget_pkg -OutFile "/tmp/$(Split-Path -Path $nuget_pkg -Leaf)" -UseBasicParsing -DisableKeepAlive
    if (Test-Path -Path "${PSScriptRoot}/selenium") { Remove-Item -Path "${PSScriptRoot}/selenium" -Recurse -Force -Confirm:$false }
    
    # add selenium
    New-Item -Path $PSScriptRoot -ItemType Directory -Name "selenium" -Force -Confirm:$false
    7za x "/tmp/$(Split-Path -Path $nuget_pkg -Leaf)" -o"${PSScriptRoot}/selenium"
    
    # set the chrome version
    if (Test-Path -Path '/Applications/Google Chrome.app')
    {
        $chrome_version = (Get-Content '/Applications/Google Chrome.app/Contents/Info.plist' | 
            Select-String -Pattern '\s{1,}<string>\d{1,}\.\d{1,}\.([\d{1,}\.]+)<\/string>' | 
            Select-Object -ExpandProperty Matches -First 1 | 
            Select-Object -ExpandProperty Value | 
            Select-String -Pattern '\d{1,}\.\d{1,}\.([\d{1,}\.]+)' | 
            Select-Object -ExpandProperty Matches -First 1 | 
            Select-Object -ExpandProperty Value).Split('.')[0]

        $download_page = Invoke-WebRequest -Uri https://chromedriver.chromium.org/downloads -UseBasicParsing -DisableKeepAlive
        $download_href = $download_page.Links | 
            Where-Object {$_.outerHTML -match "https:\/\/chromedriver\.storage\.googleapis\.com\/index\.html.path.${chrome_version}\.*"} | 
            Select-Object -ExpandProperty outerHTML -First 1
        $version_number = (($download_href | Select-String -Pattern '"https.*\/"' |
            Select-Object -ExpandProperty Matches -First 1 |
            Select-Object -ExpandProperty Value) -replace '[^0-9\.]','').Replace("....","")
        $chromedriver_uri = "https://chromedriver.storage.googleapis.com/${version_number}/chromedriver_mac64.zip"
        if (Test-Path -Path /tmp/chromedriver_mac64.zip) { Remove-Item -Path /tmp/chromedriver_mac64.zip -Force -Confirm:$false }
        Invoke-WebRequest -Uri $chromedriver_uri -OutFile /tmp/chromedriver_mac64.zip -UseBasicParsing -DisableKeepAlive
        if (Test-Path -Path "${PSScriptRoot}/chrome_driver") { Remove-Item -Path "${PSScriptRoot}/chrome_driver" -Recurse -Force -Confirm:$false }
        New-Item -ItemType Directory -Name chrome_driver -Path $PSScriptRoot
        7za x /tmp/chromedriver_mac64.zip -o"${PSScriptRoot}/chrome_driver"

        # create an app dir and setup drivers
        New-Item -ItemType Directory -Name app -Path $PSScriptRoot -Force -Confirm:$false
        Copy-Item -Path  "${PSScriptRoot}\selenium\lib\net6.0\WebDriver.dll" -Destination "${PSScriptRoot}\app\WebDriver.dll" -Force -Confirm:$false
        Copy-Item -Path  "${PSScriptRoot}\chrome_driver\chromedriver" -Destination "${PSScriptRoot}\app\chromedriver" -Force -Confirm:$false

        # load libraries
        Add-Type -Path "${PSScriptRoot}/app/WebDriver.dll"
        Start-Sleep -Seconds 4

        # setup chrome driver
        $chrome = New-Object OpenQA.Selenium.Chrome.ChromeDriver
        Start-Sleep -Seconds 4

        # set headless mode


        # go to google
        $chrome.Navigate().GoToUrl('https://www.tumblr.com/login')
        Start-Sleep -Seconds 5

        $email_login = $chrome.FindElement([OpenQA.Selenium.By]::Name('email'))
        $email_login.SendKeys("$($env:TUMBLR_USR)")

        $password_login = $chrome.FindElement([OpenQA.Selenium.By]::Name('password'))
        $password_login.SendKeys("$($env:TUMBLR_PWD)")

        $button_login = $chrome.FindElement([OpenQA.Selenium.By]::XPath('/html/body/div/div/div[2]/div[1]/section/div/div/div[2]/div[1]/section/div[2]/form/button'))
        $button_login.Click()

        Start-Sleep -Seconds 4

        for ($i = 0; $i -lt 100; $i++) {
            <# Action that will repeat until the condition is met #>
            $chrome.Navigate().GoToUrl('https://www.tumblr.com/likes')
            Start-Sleep -Seconds 1

            $button_reblog = $chrome.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="base-container"]/div[2]/div[2]/div[1]/div/div[2]/div[2]/div[1]/div/div/article/div[3]/footer/div[1]/div[2]/div[3]/span/span/span/span/a'))
            $button_reblog.Click()
            Start-Sleep -Seconds 1

            $button_reblog_select = $chrome.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="glass-container"]/div/div/div[2]/div/div[2]/div[2]/div/div[3]/div/div/div/button/span'))
            $button_reblog_select.Click()
            Start-Sleep -Seconds 2

            $like_button = $chrome.FindElement([OpenQA.Selenium.By]::XPath('//*[@id="base-container"]/div[2]/div[2]/div[1]/div/div[2]/div[2]/div[1]/div/div/article/div[3]/footer/div[1]/div[2]/div[4]/span/span/span/span/button'))
            $like_button.Click()
            Start-Sleep -Seconds 1
        }

        $chrome.Close()

        $chrome.Quit()
    }
}

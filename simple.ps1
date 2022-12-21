$username = $env:USERNAME
$password = $env:PASSWORD

Import-Module -Name Selenium
$Driver = Start-SeFirefox
Enter-SeUrl https://www.tumblr.com/login -Driver $Driver
$Element = Find-SeElement -Driver $Driver -Name "email"
Send-SeKeys -Element $Element -Keys $username
$Element = Find-SeElement -Driver $Driver -Name "password"
Send-SeKeys -Element $Element -Keys $password
$Element = Find-SeElement -Driver $Driver -Selection '/html/body/div/div/div[2]/div[1]/section/div/div/div[2]/div[1]/section/div[2]/form/button'
Invoke-SeClick -Element $Element
Enter-SeUrl https://www.tumblr.com/likes -Driver $Driver


$Element = Find-SeElement -Driver $Driver -Selection '//*[@id="base-container"]/div[2]/div[2]/div[1]/div/div[2]/div[2]/div[1]/div/div/article/div[3]/footer/div[1]/div[2]/div[3]/span/span/span/span/a'
Invoke-SeClick -Element $Element

$Element = Find-SeElement -Driver $Driver -Selection '//*[@id="glass-container"]/div/div/div[2]/div/div[2]/div[2]/div/div[3]/div/div/div/button/span'
Invoke-SeClick -Element $Element

$Element = Find-SeElement -Driver $Driver -Selection '//*[@id="base-container"]/div[2]/div[2]/div[1]/div/div[2]/div[2]/div[1]/div/div/article/div[3]/footer/div[1]/div[2]/div[4]/span/span/span/span/button'
Invoke-SeClick -Element $Element


$Driver.Quit()

$Driver = $null

if (Get-Module -Name Selenium)
{
    Remove-Module -Name Selenium
}

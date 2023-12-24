
# Publish-SharePointHub

$datestring = [datetime]::Today.ToString("yyyyMMdd")
$ticks = [datetime]::Now.Ticks.ToString()
$version = "3.1.$datestring.$ticks";
$sourcedir = "C:\code\WBEngineering\SharePoint Hub - Site Assets\Events-Calendar"
$targetsite = "https://wbengineering.sharepoint.com/"
$userlogin = "ows-planbuilder@wbengineering.onmicrosoft.com"
$libname = "Site Assets"
$secret_pwd = ConvertTo-SecureString -String "Pl@nB78ld3r!App1" -AsPlainText -Force 

#Add references to SharePoint client assemblies and authenticate to Office 365 site - required for CSOM
Add-Type -Path ("C:\code\__shared\CSOM\Microsoft.SharePoint.Client.dll")
Add-Type -Path ("C:\code\__shared\CSOM\Microsoft.SharePoint.Client.Runtime.dll")

#Bind to site collection
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($targetsite)
$creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userlogin,$secret_pwd)
$ctx.Credentials = $creds
Write-Host ""
Write-Host "Connecting to " -NoNewline
Write-Host $targetsite -ForegroundColor Cyan

#Retrieve list
$List = $ctx.Web.Lists.GetByTitle($libname)
$ctx.Load($List)
$ctx.ExecuteQuery()
# define code folder relative to source
$codefolder = $sourcedir

#Upload file
WRite-Host ""
Write-Host "Local Source " -NoNewline
WRite-Host $codefolder -ForegroundColor DarkCyan
WRite-Host ""
$first = $true 
$updates = $false
$info_filepath = $codefolder + "\last-publish-date.info"
$last_pub_date = [DateTime]::Now.AddDays(-7)
if ([IO.File]::Exists($info_filepath)) {
    $t = [IO.File]::ReadAllText($info_filepath)
    $last_pub_date = [datetime]::Parse($t)
}
$synced = @()
Foreach ($fsi in (Get-ChildItem $codefolder -File))
{
    #Write-Host $fsi.FullName
    if ($fsi.Name -eq "version-info.json" -or $fsi.Name -eq "last-publish-date.info" ) {
        # skip it.
    } else {
        

        if ($fsi.LastWriteTime -gt $last_pub_date) {
            $fs = New-Object IO.FileStream($fsi.FullName,[System.IO.FileMode]::Open)
            $fci = New-Object Microsoft.SharePoint.Client.FileCreationInformation
            $fci.Overwrite = $true
            $fci.ContentStream = $fs
            $fci.URL = $fsi
            $Upload = $List.RootFolder.Files.Add($fci)
            $ctx.Load($Upload)
            $ctx.ExecuteQuery()    

            $synced += $fsi.Name
            $updates = $true

            if ($first) {
                Write-Host "$fsi" -NoNewline -ForegroundColor Green
                $first = $false
            } else {
                Write-Host ", " -NoNewline
                Write-Host "$fsi" -NoNewline -ForegroundColor Green
            }

        } else {
            
            if ($first) {
                Write-Host "*$fsi" -NoNewline -ForegroundColor DarkGray
                $first = $false
            } else {
                Write-Host ", " -NoNewline
                Write-Host "*$fsi" -NoNewline -ForegroundColor DarkGray
            }

        }    
    }
}

if ($updates) {
    
    #$synced
    # update version data. 
    $version_info_filename = $codefolder + "\version-info.json";
    $filelist = [String]::Join(""", """, $synced)
   # $filelist
    # version info builder... 
    $json_payload = "{ ""name"":""wb-projectplanner-dashboards"", ""version"":""" + $version + """,""support"":""help@gfdata.io"", ""files"": [""" + $filelist + """] }";
    [System.IO.File]::WriteAllText($version_info_filename, $json_payload)

    $fs = New-Object IO.FileStream($version_info_filename,[System.IO.FileMode]::Open)
    $fci = New-Object Microsoft.SharePoint.Client.FileCreationInformation
    $fci.Overwrite = $true
    $fci.ContentStream = $fs
    $fci.URL = $fsi
    $Upload = $List.RootFolder.Files.Add($fci)
    $ctx.Load($Upload)
    $ctx.ExecuteQuery()
    
    Write-Host ", " -NoNewline
    Write-Host "[version-info]" -ForegroundColor Green

    Write-Host ""

    $d = [System.DateTime]::Now
    [System.IO.File]::WriteAllText(($codefolder + "\last-publish-date.info"), $d.ToString());
    WRite-Host "Sync Completed " -NoNewline
    Write-Host "successfully" -NoNewline -ForegroundColor Green
    Write-Host " at " -NoNewline
    WRite-Host $d -ForegroundColor Green
    #Write-Host "Files uploaded!"    
} else {
    
Write-Host ""
Write-Host ""
    WRite-Host "Nothing has changed." -ForegroundColor DarkRed
}
WRite-Host ""
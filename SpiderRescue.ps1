$start = [System.DateTime]::Now
$all_paths = "L:\projects_files\HB"
#Write-Host $all_paths

Function Prove-Down {
    param([string]$expath)
    
    $temp = [System.IO.Path]::GetDirectoryName($expath)
    if ([System.IO.Directory]::Exists($temp)) {
        return;
    }

    #Write-Host "$temp doesn't exist"

    $parent_path = $temp.Substring(0, $temp.LastIndexOf("\"))

    Prove-Down -expath $parent_path

    New-Item -Path $temp -ItemType "directory"
}

Function Get-SubDirs {
    param([string]$dir)
    WRite-Host "Get Sub dirs" + $dir
    $subdirs = [System.IO.Directory]::GetDirectories($dir, "*", [System.IO.SearchOption]::TopDirectoryOnly) 
    return $subdirs
}

Function Get-FileNames {
    param([string]$dir)

    $files = [System.IO.Directory]::GetFiles($dir, "*", [System.IO.SearchOption]::TopDirectoryOnly) 
    return $files
}

Function Rescue-File {
    param([string]$fullpath)
    ##Write-Host 
    $newpath = $fullpath.Replace("L:\", "C:\")
    Prove-Down $newpath
    if ([System.IO.File]::Exists($newpath)) {
        
        Write-Host "Skip: $newpath ..."
        return
    }
    Copy-Item -Path $fullpath -Destination $newpath
    Write-Host $newpath
}

Function Start-Here { 
    param([string[]]$paths)
    Write-Host $paths.Length
    foreach($path in $paths) {
        Write-Host $path
        $files = Get-FileNames($path)
            foreach($fi in $files) {
                Rescue-File $fi
            }
        foreach($d in Get-SubDirs($path)) {
            $files = Get-FileNames($d)
            foreach($fi in $files) {
                Rescue-File $fi
            }
            $subdirs = Get-SubDirs($d)
            Start-Here $subdirs
        }

    }
}

Start-Here $all_paths
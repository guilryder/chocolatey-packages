﻿import-module au

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

function global:au_BeforeUpdate { Get-RemoteFiles -NoSuffix -Purge }

function global:au_GetLatest {
    $releases = 'https://sourceforge.net/projects/djvu/files/DjVuLibre_Windows'
    $regex   = '(?<Path>/DjVuLibre_Windows/[\d\.]+\+(?<VersionDjView>[\d\.]+)/DjVuLibre-(?<Version>[\d\.]+)_DjView-4.11_Setup.exe)'

    (Invoke-WebRequest -Uri $releases).Content -match $regex | Out-Null

    return @{
        Version = $matches.Version + '.' + $matches.VersionDjView.Replace('.','')
        URL32   = 'https://netcologne.dl.sourceforge.net/project/djvu/' + $matches.Path
    }
}

function global:au_SearchReplace {
    @{
       "legal\VERIFICATION.txt"  = @{            
            "(?i)(x32: ).*"             = "`${1}$($Latest.URL32)"
            "(?i)(x64: ).*"             = "`${1}$($Latest.URL32)"            
            "(?i)(checksum type:\s+).*" = "`${1}$($Latest.ChecksumType32)"
            "(?i)(checksum32:).*"       = "`${1} $($Latest.Checksum32)"
            "(?i)(checksum64:).*"       = "`${1} $($Latest.Checksum32)"
        }

        "tools\chocolateyinstall.ps1" = @{        
          "(?i)(^\s*file\s*=\s*`"[$]toolsDir\\)(.*)`"" = "`$1$($Latest.FileName32)`""
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') { # run the update only if script is not sourced
    update -ChecksumFor none
}
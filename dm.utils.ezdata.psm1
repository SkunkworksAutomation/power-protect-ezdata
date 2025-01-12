function new-configuration {
    [CmdletBinding()]
    param (
    )
    begin {}
    process {
        $Title = 'ezdata'
        Write-Host "[$($Title)]: Starting new setup..."
        Write-Host "[$($Title)]: Checking for required directory structure."
        $Folders = @(
            'configuration',
            'reports',
            'templates'
        )

        # Check for the required directories
        $Items = @()
        $Folders | ForEach-Object {
            $Exists = Test-Path -Path ".\$($_)" -PathType Container
            if(!$Exists) {
                Write-Host "[$($Title)]: .\$($_) not found... creating it." -ForegroundColor Yellow
                $Item = New-Item -Path ".\$($_)" -ItemType Directory
                $Items += $Item 
            } else {
                Write-Host "[$($Title)]: .\$($_) found... skipping." -ForegroundColor Green
            }
        }
        # list out the foleders if we created any
        if($Items.Length -gt 0) {
            $Items | Format-Table -AutoSize
        }

        # Create the object for the global.json
        $json = [ordered]@{
            servers = @()
            retryNumber = 3
            retrySeconds = 15
        }

        try {
            [int]$Prompt = Read-Host `
            -Prompt "[$($Title)]: How many PowerProtect Data Manager servers do you have to extract data from?"
        }
        catch {
            throw "[$($Title)]: The value must be whole number...exiting"
        }

        $Servers = @(1..$Prompt)
        $Servers | ForEach-Object {
            $Server = Read-Host `
            -Prompt "[$($Title)]: What is the IP, or FQDN of this server?"
            $UserName = Read-Host `
            -Prompt "[$($Title)]: What is the username for this server?"
            
            $object = [ordered]@{
                ppdm = $Server
                username = $UserName
            }
            $json.servers += $object

            try {
                # Setup the credentials
                $Credential = Get-Credential `
                -Message "[$($Title)]: Provide the password for $($UserName) on $($Server)" `
                -UserName $UserName
            } catch {
                throw "$($_)"
            }
            $Credential | Export-Clixml ".\$($Folders[0])\$($Server).xml"
        }

        # Write the global.json
        $globalconfig = ".\$($Folders[0])\global.json"
        ($json | ConvertTo-Json -Depth 10) | `
        Out-File $globalconfig

        # Create a default sample report
        $report = [ordered]@{
            apiEndpoint = "activities"
            apiPaging = "serial"
            apiVersion = 2
            fileName = "dm-protection-jobs.csv"
            sortField = "startTime"
            sortOrder = "DESC"
            lookBack = 1
            lookBackFormat = "yyyy-MM-ddThh:mm:ss.fffZ"
            filters = @(
                "startTime ge `"{{lookBack}}`""
                "and category eq `"PROTECT`""
                "and classType eq `"JOB_GROUP`""
            )
            fields = @(
                [ordered]@{
                    label="startTime"
                    value="startTime"
                    format="local"
                },
                [ordered]@{
                    label="activityName"
                    value="name"
                },
                [ordered]@{
                    label="jobCategory"
                    value="category"
                },
                [ordered]@{
                    label="jobClass"
                    value="classType"
                },
                [ordered]@{
                    label="jobDuration"
                    value="duration"
                    format="{0:dd}d:{0:hh}h:{0:mm}m:{0:ss}s"
                },
                [ordered]@{
                    label="preCompSize"
                    value="stats.preCompBytes"
                    format="base2"
                },
                [ordered]@{
                    label="postCompSize"
                    value="stats.postCompBytes"
                    format="base10"
                },
                [ordered]@{
                    label="sizeTransferred"
                    value="stats.bytesTransferred"
                    format=$null
                }
            )
        }
        $defaultreport = ".\$($Folders[-1])\report1.json"
        ($report | ConvertTo-Json -Depth 10) | `
        Out-File $defaultreport
    } # END PROCESS
} # END FUNCTION

function new-template {
    [CmdletBinding()]
    param (
    )
    begin {}
    process {
        # GET THE TEMPLATES
        $Templates = (Get-ChildItem `
        -Path .\templates\*.json -File | `
        Sort-Object Name
        )

        # PARSE OUT THE NUMBER OF THE LAST TEMPLATE
        [int]$Number = ($Templates[-1].Name -split '\.' | `
        Select-Object -First 1) `
        -replace '[a-zA-Z]',''

        # NEW TEMPLATE NAME
        $Name = "report$($Number+1).json"

        # Create a default sample report
        $object = [ordered]@{
            apiEndpoint = "desiredEndpoint"
            apiPaging = "random"
            apiVersion = 2
            fileName = "dm-template.csv"
            sortField = "sortField"
            sortOrder = "DESC"
            lookBack = 1
            lookBackFormat = "yyyy-MM-ddThh:mm:ss.fffZ"
            filters = @(
                "sortField ge `"{{lookBack}}`""
            )
            fields = @(
                [ordered]@{
                    label="id"
                    value="id"
                }
            )
        }
        $newTemplate = ".\templates\$($Name)"
        ($object | ConvertTo-Json -Depth 10) | `
        Out-File $newTemplate
    }
}
function connect-dmapi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Server
    )
    begin {
        $Exists = Test-Path -Path ".\configuration\$($Server.ppdm).xml" -PathType Leaf
        if($Exists) {
            $Credential = Import-CliXml ".\configuration\$($Server.ppdm).xml"
        } else {
            $Credential = Get-Credential `
            -Message "`n`n[PowerProtect]: Credentials`nServer: $($Server.ppdm) | Username: $($Server.username)" `
            -UserName $Server.username
            $Credential | Export-CliXml ".\configuration\$($Server.ppdm).xml"
        } 
    }
    process {
        $login = @{
            username="$($Credential.username)"
            password="$(ConvertFrom-SecureString -SecureString $Credential.password -AsPlainText)"
        }
       
        # LOGON TO THE REST API 
        $Auth = Invoke-RestMethod -Uri "https://$($Server.ppdm):8443/api/v2/login" `
                    -Method POST `
                    -ContentType 'application/json' `
                    -Body (ConvertTo-Json $login) `
                    -SkipCertificateCheck
        $Object = @{
            server ="https://$($Server.ppdm):8443/api"
            token= @{
                authorization="Bearer $($Auth.access_token)"
            } # END TOKEN
        } # END

        $global:dmAuthObject = $Object

        if(!$null -eq $dmAuthObject.token) {
            Write-Host "`n[CONNECTED]: $($dmAuthObject.server)" -ForegroundColor Green
        } else {
            throw "`n[ERROR]: connecting to: $($dmAuthObject.server)"
        }

    } # END PROCESS
} # END FUNCTION

function get-data {
    [CmdletBinding()]
     param (
        [Parameter( Mandatory=$true)]
        [string]$Endpoint,
        [Parameter( Mandatory=$true)]
        [int]$Version
    )
    begin {}
    process {

        $Page = 1
        $results = @()

        Write-Host "[EndPoint]: $($dmAuthObject.server)/v$($Version)/$($Endpoint)&page=$($Page)" -ForegroundColor Yellow
        
        $query = Invoke-RestMethod -Uri "$($dmAuthObject.server)/v$($Version)/$($Endpoint)&page=$($Page)" `
        -Method GET `
        -ContentType 'application/json' `
        -Headers ($dmAuthObject.token) `
        -SkipCertificateCheck

        $results = $query.content
        
         if($query.page.totalPages -gt 1) {
             # INCREMENT THE PAGE NUMBER
             $Page++
             # PAGE THROUGH THE RESULTS
             do {
                 $Paging = Invoke-RestMethod -Uri "$($dmAuthObject.server)/v$($Version)/$($Endpoint)&page=$($Page)" `
                 -Method GET `
                 -ContentType 'application/json' `
                 -Headers ($dmAuthObject.token) `
                 -SkipCertificateCheck
 
                 # CAPTURE THE RESULTS
                 $results += $Paging.content
 
                 # INCREMENT THE PAGE NUMBER
                 $Page++   
             } 
             until ($Paging.page.number -eq $Query.page.totalPages)
         }

        return $results
    } # END PROCESS
} # END FUNCTION

function get-serial {
    [CmdletBinding()]
    param (
        [Parameter( Mandatory=$true)]
        [string]$Endpoint,
        [Parameter( Mandatory=$true)]
        [int]$Version
    )
    begin {}
    process {
        $Page = 1
        $results = @()

        Write-Host "[EndPoint]: $($dmAuthObject.server)/v$($Version)/$($Endpoint)&queryState=BEGIN" -ForegroundColor Yellow

        $Query =  Invoke-RestMethod -Uri "$($dmAuthObject.server)/v$($Version)/$($Endpoint)&queryState=BEGIN" `
        -Method GET `
        -ContentType 'application/json' `
        -Headers ($dmAuthObject.token) `
        -SkipCertificateCheck
        $results = $Query.content
   
        do {
            $Token = "$($Query.page.queryState)"
            if($Page -gt 1) {
                $Token = "$($Paging.page.queryState)"
            }
            $Paging = Invoke-RestMethod -Uri "$($dmAuthObject.server)/v$($Version)/$($Endpoint)&queryState=$($Token)" `
            -Method GET `
            -ContentType 'application/json' `
            -Headers ($dmAuthObject.token) `
            -SkipCertificateCheck
            $Results += $Paging.content

            $Page++;
        } 
        until ($Paging.page.queryState -eq "END")
        return $results
    }
}

function Convert-BytesToSize {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$false,Position=0)]
        [int64]$Size,
        [parameter(Mandatory=$false,Position=0)]
        [int]$Base
    )

    # DETERMINE SIZE IN BASE2
    switch ($Size)
    {
        {$Size -gt 1PB}
        {
            if($Base -eq 2) {
                $newSize = @{size=$([math]::Round(($Size /1PB),1));uom="PiB"}
            } else {
                $newSize = @{size=$([math]::Round(($Size /1000000000000000),1));uom="PB"}
            }
        
            Break;
        }
        {$Size -gt 1TB}
        {
            if($Base -eq 2) {
                $newSize = @{size=$([math]::Round(($Size /1TB),1));uom="TiB"}
            } else {
                $newSize = @{size=$([math]::Round(($Size /1000000000000),1));uom="TB"}
            }
            Break;
        }
        {$Size -gt 1GB}
        {
            if($Base -eq 2) {
                $newSize = @{size=$([math]::Round(($Size /1GB),1));uom="GiB"}
            } else {
                $newSize = @{size=$([math]::Round(($Size /1000000000),1));uom="GB"}
            }
            Break;
        }
        {$Size -gt 1MB}
        {
            if($Base -eq 2) {
                $newSize = @{size=$([math]::Round(($Size /1MB),1));uom="MiB"}
            } else {
                $newSize = @{size=$([math]::Round(($Size /1000000),1));uom="MB"}
            }
            
            Break;
        }
        {$Size -gt 1KB}
        {
            if($Base -eq 2) {
                $newSize = @{size=$([math]::Round(($Size /1KB),1));uom="KiB"}
            } else {
                $newSize = @{size=$([math]::Round(($Size /1000),1));uom="KB"}
            }
            Break;
        }
        Default
        {
            $newSize = @{size=$([math]::Round($Size,2));uom="Bytes"}
            Break;
        }
    }
        return $NewSize

}
function new-reportobject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Row,
        [Parameter(Mandatory=$true)]
        [array]$Mappings,
        [switch]$DebugMode
    )
    begin {}
    process {
    $fieldObj = [ordered]@{}       

    foreach($Map in $Mappings) {
        # IS IT A NESTED STRUCTURE
        $nested = $Map.value -match '\.'
        # IS IT A FILTERED STRUCTURE
        $filtered = $Map.value -match '\|'
        $unformatted = $null
        # UNFILTERED
        if(!$filtered) {
            # NESTED STRUCTURE
            if($nested) {
                $oPath = $Map.value -split '\.'
                [array]$nValue = $Row
                $oPath | ForEach-Object {
                    $nValue =  $nValue.$_
                }
                try {
                    $unformatted = $nValue
                }
                catch{
                    if($DebugMode) {
                        Write-Host "[ERROR]: Just above line 421`n$($nValue)" -ForegroundColor Red
                    }
                }
                
            } else {
                # FLAT STRUCTURE
                try {
                    $unformatted = $Row.($Map.value)
                }
                catch{
                    if($DebugMode) {
                        Write-Host "[ERROR]: Just above line 432`n$($Row.($Map.value))" -ForegroundColor Red
                    }
                }
                
            } # END IF
        } else {
            # FILTERED STRUCTURE
            # CREATE A MAP LIST [ ARRAY|FILTER|FIELD(S)|POSITION ]
            $mapList = $Map.value -split '\|'

            # PARSE OUT WHERE-OBJECT
            $where = $mapList[1] -split '\s'

            # FILTER THE OBJECT
            # TO DO: ADD SUPPORT FOR ADDITITONAL OPERATORS
            $filter = $Row."$($mapList[0])" | `
            where-object {$_."$($where[0])" -eq "$($where[2])"}
                     
            if($mapList[-2] -match "\.") {
                 # FILTERED AND NESTED
                 # ARRAY PATH
                 $oPath = $mapList[-2] -split '\.'

                 [array]$nValue = $filter
                 $oPath | ForEach-Object {
                     $nValue =  $nValue.$_
                 }
            
                 if($nValue.length -gt 0) {
                    try {
                        $unformatted = $nValue[$mapList[-1]]
                    }
                    catch {
                        if($DebugMode) {
                            Write-Host "[ERROR]: Just above line 466`n$($_.Message)" -ForegroundColor Red
                        }
                    }
                    
                 } else {
                    try {
                        $unformatted = $nValue
                    }
                    catch {
                        if($DebugMode) {
                            Write-Host "[ERROR]: Just above line 476`n$($_.Message)" -ForegroundColor Red
                        }
                    }
                    
                 }
            } else {
                $unformatted = $filter."$($nValue)"

            } # END IF
            } # END IF
        # SPECIAL FIELD HANDLING
        $formatted = $null
        switch -Regex ($Map.value) {
            '[b|B]ytes' {
                # FORMAT THE SIZE
                if($null -eq $Map.format) {
                    $formatted = $unformatted
                } else {
                    $filtered = $unformatted | Where-Object { $_ }
                    if($filtered) {
                        # FORMAT THE NUMBER
                        $base = $Map.format -replace "[a-zA-Z]", ""
                        $size = Convert-BytesToSize -Size $filtered -Base $base
                        $formatted = "$($size.size) $($size.uom)"
                    } else {
                        $formatted = $unformatted
                    }
                }
                break;
            }
            '^duration$' {
                # FORMAT THE DURATION
                if($null -eq $unformatted ) {
                    $timeSpan = 0
                } else {
                    $timeSpan = New-TimeSpan -Milliseconds $unformatted
                }
                if($null -eq $Map.format) {
                    $formatted = $unformatted
                } else {
                    $formatted = "$($Map.format -f $timeSpan)"
                }
                break;
            }
            '(At|Discovered|Time|Updated)$' {
                if($null -eq $Map.format) {
                    # UTC IS THE DEFAULT
                    $formatted = $unformatted
                } else {
                    if($Map.format -eq "local") {
                        # LOCAL
                        if($null -ne $unformatted) {
                            $Date = Get-Date("$($unformatted)")
                            $formatted = "$($Date.ToLocalTime())"
                        } else {
                            $formatted = $unformatted
                        }
                    } else {
                        # UTC IS THE DEFAULT
                        $formatted = $unformatted
                    }
                }
                break;
            }
            default {
                $formatted = $unformatted
                break;
            }
        } # END SWITCH
            $fieldObj."$($Map.label)"="$( $formatted )"  
    } # END MAPPINGS
        return (New-Object -TypeName psobject -Property $fieldObj)
    } # END PROCESS
} # END FUNCTION

function disconnect-dmapi {
[CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]$Version
    )
    begin {}
    process {
        # LOGOFF OF THE POWERPROTECT API
        Invoke-RestMethod -Uri "$($dmAuthObject.server)/v$($Version)/logout" `
        -Method POST `
        -ContentType 'application/json' `
        -Headers ($dmAuthObject.token) `
        -SkipCertificateCheck
        
        Write-Host "[DISCONNECTED]: $($dmAuthObject.server)" -ForegroundColor Yellow
        $global:dmAuthObject = $null
    } # END PROCESS
} # END FUNCTION

function start-extract {
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$false)]
    [switch]$Console
    )
    begin {
        $ConfigFile = '.\configuration\global.json'
        $Exists = Test-Path -Path $ConfigFile -PathType Leaf
        if($Exists) {
            $Config = Get-Content $ConfigFile | convertfrom-json -Depth 10
        } else {
            throw "`n[ERROR]: $($ConfigFile) is missing!"
        }
    }
    process {
    # WORKFLOW
    $Templates = Get-ChildItem -Path .\templates\*.json -File

    foreach($Server in $Config.servers) {
        # THE NUMBER OF TIMES TO RETRY THE CONNECTION TO PPDM
        $Retires = @(1..$Config.retryNumber)
        foreach($Retry in $Retires) {
            try {
            # CONNECT TO THE REST API
            connect-dmapi -Server $Server
            # GET THE REPORT TEMPLATES
            foreach($Item in $Templates) {
                Write-Host "[Template]: $($Item.Name)" -ForegroundColor Cyan
                $Template = (Get-Content -Path $Item.FullName | ConvertFrom-Json -Depth 10)
                
                $Query = @()
                $Filters = @()

                if(($Template.filters).length -gt 0) {
                    foreach($Filter in $Template.filters) {
                         # REPLACE DATA BINDINGS
                        if($Filter -match '(?<=\{\{)(.*?)(?=\}\})') {                            
                            switch($Matches[0]) {
                                'lookBack' {
                                    $Date = (Get-Date).AddDays(-$Template.lookBack)
                                    Write-Host "[Regex]: Replacing data binding for: {{$($Matches[0])}} with $($Date.ToString("$($Template.lookBackFormat)"))" -ForegroundColor Magenta
                                    $Filter = $Filter `
                                    -replace "\{\{$($Matches[0])\}\}", `
                                    $Date.ToString("$($Template.lookBackFormat)")
                                }
                            } # END SWITCH
                        }
                        $Filters += $Filter
                    }
                    # THIS ENDPOINT IS FILTERED
                    $endpoint = `
                    "$($Template.apiEndpoint)?filter=$($Filters)&orderby=$($Template.sortField) $($Template.sortOrder)"
                } else {
                    # THIS ENDPOINT IS UNFILTERED
                    $endpoint = `
                    "$($Template.apiEndpoint)?orderby=$($Template.sortField) $($Template.sortOrder)"
                }

                Write-Host "`n[Paging]: $($Template.apiPaging)" -ForegroundColor Yellow
                Write-Host "[Filters]: $($Filters)" -ForegroundColor Yellow
                Write-Host "[Sorting]: orderby=$($Template.sortField) $($Template.sortOrder)" -ForegroundColor Yellow 
                # GET THE PAGING METHOD
                switch($Template.apiPaging) {
                    'serial' {
                        # USE SERIAL PAGING
                        $Query = get-serial `
                        -Endpoint $endpoint `
                        -Version $Template.apiVersion
                        break;
                    }
                    default {
                        # USE RANDOM ACCESS PAGING
                        $Query = get-data `
                        -Endpoint $endpoint `
                        -Version $Template.apiVersion
                        break;
                    }
                } # END SWITCH

                # GENERATE REPORT OUTPUT
                $Report = @()
                Write-Host "`n[Generating]: Report... $($Template.fileName)" -ForegroundColor Yellow
                foreach($Row in $Query) {
                    $Report += new-reportobject `
                    -Row $Row `
                    -Mappings $Template.fields `
                    -DebugMode
                }
                if($Console) {
                    $Report | Format-Table -AutoSize
                } else {
                    $Report | Export-csv ".\reports\$($Server.ppdm)-$($Template.fileName)"
                }
            } # END REPORT

            # DISCONNECT FROM THE REST API
            disconnect-dmapi `
            -Version 2
            break;

            } catch {
                if($Retry -lt $Retires.length) {
                    Write-Host "[WARNING]: $($_). Sleeping $($Config.retrySeconds) seconds... Attempt #: $($Retry)" `
                    -ForegroundColor Yellow
                    Start-Sleep -Seconds $Config.retrySeconds
                } else {
                    # NON TERMINATING ERROR
                    Write-Host "[ERROR]: $($_). Attempts: $($Retry), moving on..." `
                    -ForegroundColor Red
                }
            } # END TRY CATCH BLOCK
        } # END RETRIES
    } # END SERVERS
} # END PROCESS
} # END FUNCTION
Export-ModuleMember -Function *
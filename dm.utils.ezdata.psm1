function new-configuration {
    [CmdletBinding()]
    param ()
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
            lookBackUnit = "days"
            lookBackFormat = "yyyy-MM-ddTHH:mm:ss.fffZ"
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
    param ()
    begin {
        $Title = 'ezdata'
        function Get-PropertyCount {
        param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [object]$Object
        )
        $count = 0
        foreach ($property in $Object.PSObject.Properties) {
            if ($property.Value -is [PSCustomObject] -or $property.Value -is [PSObject]) {
                $count += Get-PropertyCount $property.Value
            }
            $count++
        }
        return $count
        }  # END FUNCTION
    }
    process {
        # GET THE TEMPLATES
        $Templates = (Get-ChildItem `
        -Path .\templates\*.json -File | `
        Sort-Object Name
        )

        if($Templates.Length -gt 0) {
            # PARSE OUT THE NUMBER OF THE LAST TEMPLATE
            [int]$Number = ($Templates[-1].Name -split '\.' | `
            Select-Object -First 1) `
            -replace '[a-zA-Z]',''

            # NEW TEMPLATE NAME
            $Name = "report$($Number+1).json"
            # NEW TEST DATA NAME
            $dName = "testdata$($Number+1).json"
        } else {
            # NEW TEMPLATE NAME
            $Name = "report1.json"
            # NEW TEST DATA NAME
            $dName = "testdata1.json"
        }
        
        [string]$apiEndpoint = Read-Host `
            -Prompt "[$($Title)]: (string) What API endpoint will be used?"
        
        [int]$apiVersion = Read-Host `
            -Prompt "[$($Title)]: (int) What version of the API will be used?"
        
        [string]$sortField = Read-Host `
            -Prompt "[$($Title)]: (string) Enter a sort field name?"
        
        [int]$noFields = Read-Host `
            -Prompt "[$($Title)]: (int) How many fields in the template?"
        
        [string]$testData = Read-Host `
            -Prompt "[$($Title)]: (string) Do you want to create some test data from: /v$($apiVersion)/$($apiEndpoint)? [Y|N]:"

        # Create a default sample report
        $object = [ordered]@{
            apiEndpoint = $apiEndpoint
            apiPaging = "random"
            apiVersion = $apiVersion
            fileName = "dm-$($apiEndpoint).csv"
            sortField = $sortField
            sortOrder = "DESC"
            lookBack = 1
            lookBackUnit = "days"
            lookBackFormat = "yyyy-MM-ddTHH:mm:ss.fffZ"
            filters = @(
            )
            fields = @()
        }

        for($i=1;$i -lt ($noFields+1);$i++) {
            $object.fields += [ordered]@{
                label= "label$($i)"
                value= "value$($i)"
            }
        }

        $newTemplate = ".\templates\$($Name)"
        ($object | ConvertTo-Json -Depth 10) | `
        Out-File $newTemplate

        if($testData -eq 'Y') {
            $ConfigFile = '.\configuration\global.json'
            $Exists = Test-Path -Path $ConfigFile -PathType Leaf
            if($Exists) {
                $Config = Get-Content $ConfigFile | convertfrom-json -Depth 10
            } else {
                throw "`n[ERROR]: $($ConfigFile) is missing!"
            }

            # CONNECT TO PPDM 1st Server
            connect-dmapi -Server $Config.servers[0]
            
            $query = Invoke-RestMethod -Uri "$($dmAuthObject.server)/v$($apiVersion)/$($apiEndpoint)" `
            -Method GET `
            -ContentType 'application/json' `
            -Headers ($dmAuthObject.token) `
            -SkipCertificateCheck
            $content = $query.content
            Write-Host "[$($content.length)]: $($dmAuthObject.server)/v$($apiVersion)/$($apiEndpoint)"

            $Counts = @()
            for($i=0;$i -lt $content.length;$i++) {

                $count = (Get-PropertyCount -Object $content[$i])
                $object = [ordered]@{
                    position = $i
                    count = $count
                }
                $Counts += (New-Object -TypeName psobject -Property $object )
            }

            $Counts = $Counts | Sort-Object count -DESC

            ($content[$Counts[0].position] | convertto-json -Depth 10) | Out-File ".\$($dName)"

        } # END IF TESTDATA
     
    }
} # END FUNCTION
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

function new-query {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Data,
        [Parameter(Mandatory=$true)]
        [array]$Fields
    )
    begin {
        $fieldObj = [ordered]@{}
        $fieldValue = $null
    } # END BEGIN
    process {
        foreach($Field in $Fields) {            
            # CHECK FOR FILTERING
            $Filtered = $Field.value -match '\|'
        
            # NOT FILTERED
            if(!$Filtered) {
                # CHECK FOR NESTING
                if($Field.value -match '\.') {
                    # TRAVERSE THE DATA PATH
                    $fieldValue = $Data
                    $fieldPath = $Field.value -split '\.'
                    $fieldPath  | ForEach-Object {
                        $fieldValue = $fieldValue.$_
                    } 
                } else {
                    # NOT NESTED
                    $fieldValue = $Data."$($Field.value)"
                }

            } else {
                # CREATE THE FILTERS
                $Filters = $field.value -split '\|'
                # ITERATE OVER THE FILTERS
                for($i=0;$i -lt $filters.length;$i++) {
                    switch -Regex ($filters[$i]) {
                        '^\?[aA-zZ]' {
                            <#
                                RETURN DATA IN THE ARRAY BASED ON A QUERY
                                STRIP OUT THE QUESTION MARK
                                SPLIT ON SPACES EXCEPT BETWEEN SINGLE AND DOUBLE QUOTES
                            #>
                            [array]$vValue = ($filters[$i] -replace '\?','') `
                            -split "\s+(?=(?:[^\'`"]*[\'`"][^\'`"]*[\'`"])*[^\'`"]*$)" `
                            -replace "`"|'",""
                            break;
                        }
                        '^\?[0-9]' {
                            # RETURN DATA IN THE ARRAY BASED ON POSITION
                            [int]$vValue = ($filters[$i] -replace '\?','')
                            break;
                        }
                        default {
                            [string]$vValue = $filters[$i]
                            break;
                        }
                    } # END SWITCH

                    # CREATE THE DYNAMIC VARIABLE FOR THE QUERY
                    $vName = "filteredQuery$($i)"
                    Set-Variable -Name $vName -Value $vValue
                } # END FOR
                
                # GET A LIST OF THE QUERY VARIABLES
                $Queries = Get-Variable | Where-Object {$_.Name -Match "filteredQuery"}

                # ASSIGN THE ROOT DATA SET TO THE $fieldValue
                # WE WILL ALWAYS START QUERIES FOR EACH FIELD FROM THE ROOT
                $fieldValue = $Data
                foreach($Query in $Queries) {
                    # GET THE NAME OF THE BASETYPE
                    # Array FOR FILTERS USED IN WHERE-OBJECT
                    # ValueType FOR INTS USED IN A POSITIONAL QUERY OF AN ARRAY
                    # Object (default) USED TO QUERY FOR ROOT AND NESTED PROPERTIES
                    $Type = ($Query.Value).GetType().BaseType.Name
                    # Write-Host $Query.Value[2]
                    switch($Type) {
                        'Array' {
                            # ARRAY - QUERY THE ARRAY BASED ON A VALUES
                            switch($Query.Value[1]) {
                                'eq' {
                                    # EQUALS
                                    $fieldValue = $fieldValue | `
                                    Where-Object {$_."$($Query.Value[0])" -eq $Query.Value[2]}
                                    break;
                                }
                                'ne' {
                                    # NOT EQUALS
                                    $fieldValue = $fieldValue | `
                                    Where-Object {$_."$($Query.Value[0])" -ne $Query.Value[2]}
                                    break;
                                }
                                'match' {
                                    # MATCH USED TO PASS IN REGEX
                                    $fieldValue = $fieldValue | `
                                    Where-Object {$_."$($Query.Value[0])" -match $Query.Value[2]}
                                    break;
                                }
                            }               
                            break;
                        }
                        'ValueType' {
                            # INT - POSITIONAL ARRAY SEARCH
                            if($null -ne $fieldValue) {
                                $fieldValue = $fieldValue[$Query.Value]
                            } else {
                                $fieldValue = $fieldValue
                            }
                        }
                        default {
                            # OBJECT - SINGLE, OR NESTED
                            if($Query.Value -match '\.') {
                                ($Query.Value -split '\.') | ForEach-Object {
                                    $fieldValue = $fieldValue.$_
                                }
                            } else {
                                $fieldValue = ($fieldValue)."$($Query.Value)"
                            }
                            break;
                        }
                    }
                 } # END SWITCH
            } # END IF - FILTERED
            
            # SPECIAL FIELD HANDLING
            $formatted = $null
            switch -Regex ($Field.value) {
            '[b|B]ytes|[s|S]ize' {
                # FORMAT THE SIZE
                if($null -eq $Field.format) {
                    $formatted = $fieldValue
                } else {
                    $filtered = $fieldValue | Where-Object { $_ }
                    if($filtered) {
                        # FORMAT THE NUMBER
                        $base = $Field.format -replace "[a-zA-Z]", ""
                        $size = Convert-BytesToSize -Size $filtered -Base $base
                        $formatted = "$($size.size) $($size.uom)"
                    } else {
                        $formatted = $fieldValue
                    }
                }
                break;
            }
            '^duration$' {
                # FORMAT THE DURATION
                if($null -eq $fieldValue ) {
                    $timeSpan = 0
                } else {
                    $timeSpan = New-TimeSpan -Milliseconds $fieldValue
                }
                if($null -eq $Field.format) {
                    $formatted = $fieldValue
                } else {
                    $formatted = "$($Field.format -f $timeSpan)"
                }
                break;
            }
            '(At|Discovered|Time|Updated)$' {
                if($null -eq $Field.format) {
                    # UTC IS THE DEFAULT
                    $formatted = $fieldValue
                } else {
                    if($Field.format -eq "local") {
                        # LOCAL
                        if($null -ne $fieldValue) {
                            $Date = Get-Date("$($fieldValue)")
                            $formatted = "$($Date.ToLocalTime())"
                        } else {
                            $formatted = $fieldValue
                        }
                    } else {
                        # UTC IS THE DEFAULT
                        $formatted = $fieldValue
                    }
                }
                break;
            }
            default {
                $formatted = $fieldValue
                break;
            }
        } # END SWITCH

            # ADD A COLUMN AND VALUE
            $fieldObj.Add("$($Field.label)","$($formatted)")
        }  # END FOREACH
        # RETURN THE ROW
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
    [switch]$Console,
    [Parameter(Mandatory=$false)]
    [switch]$MergeReports
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
                                    switch -Regex ($Template.lookBackUnit){
                                        '^years' {
                                            $Date = (Get-Date).
                                            AddYears(-$Template.lookBack).
                                            ToUniversalTime()
                                            break;
                                        }
                                        '^months' {
                                            $Date = (Get-Date).
                                            AddMonths(-$Template.lookBack).
                                            ToUniversalTime()
                                            break;
                                        }
                                        '^days' {
                                            $Date = (Get-Date).
                                            AddDays(-$Template.lookBack).
                                            ToUniversalTime()
                                            break;
                                        }
                                        '^hours' {
                                            $Date = (Get-Date).
                                            AddHours(-$Template.lookBack).
                                            ToUniversalTime()
                                            break;
                                        }
                                        '^minutes' {
                                            $Date = (Get-Date).
                                            AddMinutes(-$Template.lookBack).
                                            ToUniversalTime()
                                            break;
                                        }
                                        default {
                                            $Date = (Get-Date).
                                            AddSeconds(-$Template.lookBack).
                                            ToUniversalTime()
                                            break;
                                        }
                                    } # END SWITCH

                                    Write-Host "[Regex]: Replacing data binding for: {{lookBack)}} with $($Date.ToString("$($Template.lookBackFormat)"))" -ForegroundColor Magenta
                                    $Filter = $Filter `
                                    -replace "\{\{lookBack\}\}", `
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
                Write-Host "[LookBack]: unit: $($Template.lookBackUnit), value: $($Template.lookBack)" -ForegroundColor Yellow
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
                    $Report += new-query `
                    -Data $Row `
                    -Fields $Template.fields
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
    if(!$Console) {
        if($MergeReports) {
            merge-reports
        }
    }
} # END PROCESS
} # END FUNCTION
function test-extract {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]$ConfigNo
    )
    begin {}
    process {
        $Data = Get-Content ".\testdata$($ConfigNo).json" | `
        ConvertFrom-Json -Depth 10
        $Template = Get-Content ".\templates\report$($ConfigNo).json" | `
        ConvertFrom-Json -Depth 10
        $Report = @()
        $Data | foreach-object {
            $Report += new-query `
            -Data $Data `
            -Fields $Template.fields
        }
        $Report | format-Table -AutoSize
    } # END PROCESS
} # END FUNCTION

function merge-reports {
    [CmdletBinding()]
    param (
    )
    begin {}
    process {
        $Title = "ezdata"
        $Date = Get-Date
        $Files = Get-ChildItem .\reports\*.csv -File
        $Folder = "$($Date.toString('yyyy-MM-dd'))"
        $Exists = Test-Path -Path ".\reports\$($Folder)" -PathType Container

        if(!$Exists) {
            Write-Host "`n[$($Title)]: .\reports\$($Folder) not found... creating it." -ForegroundColor Yellow
            New-Item -Path ".\reports\$($Folder)" -ItemType Directory
        }
        Write-Host "`n[$($Title)]: Merging report files..." -ForegroundColor Blue
        $Merge= @()
        foreach($File in $Files) {

            $Object = [ordered]@{
                fileName = $File.Name
                filePath = $File.FullName
                groupName = $File.Name -Split '\-dm\-' | Select-Object -last 1
                dataManager = $File.Name -Split '\-dm\-' | Select-Object -first 1
            }
            $Merge += (New-Object -TypeName psobject -Property $Object)
        }

        $Groups = $Merge| Group-Object groupName

        foreach($Row in $Groups) {

            $dataSet = @()
            # IMPORT THE CSV FILES FOR THAT GROUP
            $Row.Group | ForEach-Object {
                $Import = Import-Csv $_.filePath
                foreach($record in $Import) {
                    $Object = $record
                    $Object | Add-Member -NotePropertyName ppdm -NotePropertyValue $_.dataManager
                    $dataSet += $Object
                }
                
                $dataSet | Export-Csv ".\reports\$($Folder)\evt-$($_.groupName)"
            }
        } # END GROUPS
    } # END PROCESS
} # END FUNCTION

Export-ModuleMember -Function *
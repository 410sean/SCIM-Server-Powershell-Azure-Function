# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.
if ($env:MSI_SECRET -and (Get-Module -ListAvailable Az.Accounts)) {
    Connect-AzAccount -Identity
}

<#begin custom auth function#>
function Test-BasicAuthCred($Authorization){
    write-host $Authorization
    if ($env:basicauth){
        write-host "$($env:basicauth)"
        $basicauthsettings="$($env:basicauth)".Split(';') | foreach-object{$_ | ConvertFrom-Stringdata}
        if ($basicauthsettings.enabled -eq 'true'){
            write-host "checking credentials $($Authorization | convertto-json)-"
            if ($Authorization -like "Basic *"){
                $hash=$Authorization.replace('Basic ','')
                write-host "hash $hash"
                }else{
                    write-host "not using Basic auth"
                    return $false
                }
            try{
                $bytes=[convert]::frombase64string($hash)
                $creds=[System.Text.Encoding]::utf8.Getstring($bytes).split(':')
                write-host "recieved $([System.Text.Encoding]::utf8.Getstring($bytes))"
                if ($creds[0] -eq $basicauthsettings.client_id -and $creds[1] -eq $basicauthsettings.client_secret){
                    return $true
                }
                
                
            }
            catch{return $false}
            
        }else{
            return 'disabled'
        }
    }
    return $false
}
# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.

<#begin helper scim functions#>
function new-scimItem ($schema, $properties, $location, [switch]$includeMeta){
    #will create item starting with schema and ending with meta
    #nested properties should have a property name that can be split by underscore '_'
    $psitem=[pscustomobject]@{
      schemas=@("urn:ietf:params:scim:schemas:core:2.0:$schema")
    }
    foreach ($prop in $properties){
      if ($prop.name -in ('PartitionKey','RowKey','Timestamp')){continue}
      if ($prop.name -like "*_*"){
          $tree="$($prop.name)".split('_')
          if ($null -ne ($psitem."$($tree[0])")){
              $psitem."$($tree[0])" | add-member -notepropertyname "$($tree[1])" -notepropertyvalue ($prop.value) -verbose
          }else{
              $psitem | add-member -notepropertyname "$($tree[0])" -notepropertyvalue ([pscustomobject]@{"$($tree[1])"=$prop.value}) -verbose
          }
      }else{
          $psitem | add-member -notepropertyname $prop.name -notepropertyvalue $prop.value -verbose
      }
    }
    if ($includemeta){
        $meta=[pscustomobject]@{
            resourceType=$schema
            location="$location"
        }
        $psitem | add-member -notepropertyname 'meta' -notepropertyvalue $meta
    }
    return $psitem
  }
<#begin helper scim functions v2#>
function Get-AzTableRow
{
    <#
    .SYNOPSIS
        Used to return entities from a table with several options, this replaces all other Get-AzTable<XYZ> cmdlets.
    .DESCRIPTION
        Used to return entities from a table with several options, this replaces all other Get-AzTable<XYZ> cmdlets.
    .PARAMETER Table
        Table object of type Microsoft.Azure.Cosmos.Table.CloudTable to retrieve entities (common to all parameter sets)
    .PARAMETER PartitionKey
        Identifies the table partition (byPartitionKey and byPartRowKeys parameter sets)
    .PARAMETER RowKey
        Identifies the row key in the partition (byPartRowKeys parameter set)
    .PARAMETER ColumnName
        Column name to compare the value to (byColummnString and byColummnGuid parameter sets)
    .PARAMETER Value
        Value that will be looked for in the defined column (byColummnString parameter set)
    .PARAMETER GuidValue
        Value that will be looked for in the defined column as Guid (byColummnGuid parameter set)
    .PARAMETER Operator
        Supported comparison Operator. Valid values are "Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual" (byColummnString and byColummnGuid parameter sets)
    .PARAMETER CustomFilter
        Custom Filter string (byCustomFilter parameter set)
    .EXAMPLE
        # Getting all rows
        Get-AzTableRow -Table $Table
 
        # Getting rows by partition key
        Get-AzTableRow -Table $table -partitionKey NewYorkSite
 
        # Getting rows by partition and row key
        Get-AzTableRow -Table $table -partitionKey NewYorkSite -rowKey "afc04476-bda0-47ea-a9e9-7c739c633815"
 
        # Getting rows by Columnm Name using Guid columns in table
        Get-AzTableRow -Table $Table -ColumnName "id" -guidvalue "5fda3053-4444-4d23-b8c2-b26e946338b6" -operator Equal
 
        # Getting rows by Columnm Name using string columns in table
        Get-AzTableRow -Table $Table -ColumnName "osVersion" -value "Windows NT 4" -operator Equal
 
        # Getting rows using Custom Filter
        Get-AzTableRow -Table $Table -CustomFilter "(osVersion eq 'Windows NT 4') and (computerName eq 'COMP07')"
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ParameterSetName="GetAll")]
        [Parameter(ParameterSetName="byPartitionKey")]
        [Parameter(ParameterSetName="byPartRowKeys")]
        [Parameter(ParameterSetName="byColummnString")]
        [Parameter(ParameterSetName="byColummnGuid")]
        [Parameter(ParameterSetName="byCustomFilter")]
        $Table,

        [Parameter(Mandatory=$true,ParameterSetName="byPartitionKey")]
        [Parameter(ParameterSetName="byPartRowKeys")]
        [AllowEmptyString()]
        [string]$PartitionKey,

        [Parameter(Mandatory=$true,ParameterSetName="byPartRowKeys")]
        [AllowEmptyString()]
        [string]$RowKey,

        [Parameter(Mandatory=$true, ParameterSetName="byColummnString")]
        [Parameter(ParameterSetName="byColummnGuid")]
        [string]$ColumnName,

        [Parameter(Mandatory=$true, ParameterSetName="byColummnString")]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(ParameterSetName="byColummnGuid",Mandatory=$true)]
        [guid]$GuidValue,

        [Parameter(Mandatory=$true, ParameterSetName="byColummnString")]
        [Parameter(ParameterSetName="byColummnGuid")]
        [validateSet("Equal","GreaterThan","GreaterThanOrEqual","LessThan" ,"LessThanOrEqual" ,"NotEqual")]
        [string]$Operator,
        
        [Parameter(Mandatory=$true, ParameterSetName="byCustomFilter")]
        [string]$CustomFilter
    )

    $TableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"

    # Building filters if any
    if ($PSCmdlet.ParameterSetName -eq "byPartitionKey")
    {
        [string]$Filter = `
            [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("PartitionKey",`
            [Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$PartitionKey)
    }
    elseif ($PSCmdlet.ParameterSetName -eq "byPartRowKeys")
    {
        [string]$FilterA = `
            [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("PartitionKey",`
            [Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$PartitionKey)

        [string]$FilterB = `
            [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("RowKey",`
            [Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,$RowKey)

        [string]$Filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::CombineFilters($FilterA,"and",$FilterB)
    }
    elseif ($PSCmdlet.ParameterSetName -eq "byColummnString")
    {
        [string]$Filter = `
            [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition($ColumnName,[Microsoft.Azure.Cosmos.Table.QueryComparisons]::$Operator,$Value)
    }
    elseif ($PSCmdlet.ParameterSetName -eq "byColummnGuid")
    {
        [string]$Filter = `
            [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterConditionForGuid($ColumnName,[Microsoft.Azure.Cosmos.Table.QueryComparisons]::$Operator,$GuidValue)
    }
    elseif ($PSCmdlet.ParameterSetName -eq "byCustomFilter")
    {
        [string]$Filter = $CustomFilter
    }
    else
    {
        [string]$filter = $null    
    }
    
    # Adding filter if not null
    if (-not [string]::IsNullOrEmpty($Filter))
    {
        $TableQuery.FilterString = $Filter
    }

    # Getting results
    if (($TableQuery.FilterString -ne $null) -or ($PSCmdlet.ParameterSetName -eq "GetAll"))
    {
        $Result = ExecuteQueryAsync -Table $Table -TableQuery $TableQuery

        # if (-not [string]::IsNullOrEmpty($Result.Result.Results))
        # {
        # return (GetPSObjectFromEntity($Result.Result.Results))
        # }

        if (-not [string]::IsNullOrEmpty($Result))
        {
            return (GetPSObjectFromEntity($Result))
        }
    }
}
function Update-AzTableRow
{
    <#
    .SYNOPSIS
        Updates a table entity
    .DESCRIPTION
        Updates a table entity. To work with this cmdlet, you need first retrieve an entity with one of the Get-AzTableRow cmdlets available
        and store in an object, change the necessary properties and then perform the update passing this modified entity back, through Pipeline or as argument.
        Notice that this cmdlet accepts only one entity per execution.
        This cmdlet cannot update Partition Key and/or RowKey because it uses those two values to locate the entity to update it, if this operation is required
        please delete the old entity and add the new one with the updated values instead.
    .PARAMETER Table
        Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity exists
    .PARAMETER Entity
        The entity/row with new values to perform the update.
    .EXAMPLE
        # Updating an entity
 
        [string]$Filter = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"User1")
        $person = Get-AzTableRowByCustomFilter -Table $Table -CustomFilter $Filter
        $person.lastName = "New Last Name"
        $person | Update-AzTableRow -Table $Table
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $Table,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $entity
    )
    
    # Only one entity at a time can be updated
    $updatedEntityList = @()
    $updatedEntityList += $entity

    if ($updatedEntityList.Count -gt 1)
    {
        throw "Update operation can happen on only one entity at a time, not in a list/array of entities."
    }

    $updatedEntity = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.DynamicTableEntity" -ArgumentList $entity.PartitionKey, $entity.RowKey
    
    # Iterating over PS Object properties to add to the updated entity
    foreach ($prop in $entity.psobject.Properties)
    {
        if (($prop.name -ne "PartitionKey") -and ($prop.name -ne "RowKey") -and ($prop.name -ne "Timestamp") -and ($prop.name -ne "Etag") -and ($prop.name -ne "TableTimestamp"))
        {
            $updatedEntity.Properties.Add($prop.name, $prop.Value)
        }
    }

    $updatedEntity.ETag = $entity.Etag
    $updatedEntity.Timestamp = $entity.TableTimestamp

    # Updating the dynamic table entity to the table
    # return ($Table.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrMerge($updatedEntity)))
    return ($Table.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrMerge($updatedEntity)))
}

function Remove-AzTableRow
{
    <#
    .SYNOPSIS
        Remove-AzTableRow - Removes a specified table row
    .DESCRIPTION
        Remove-AzTableRow - Removes a specified table row. It accepts multiple deletions through the Pipeline when passing entities returned from the Get-AzTableRow
        available cmdlets. It also can delete a row/entity using Partition and Row Key properties directly.
    .PARAMETER Table
        Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity exists
    .PARAMETER Entity (ParameterSetName=byEntityPSObjectObject)
        The entity/row with new values to perform the deletion.
    .PARAMETER PartitionKey (ParameterSetName=byPartitionandRowKeys)
        Partition key where the entity belongs to.
    .PARAMETER RowKey (ParameterSetName=byPartitionandRowKeys)
        Row key that uniquely identifies the entity within the partition.
    .EXAMPLE
        # Deleting an entry by entity PS Object
        [string]$Filter1 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("firstName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"Paulo")
        [string]$Filter2 = [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("lastName",[Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"Marques")
        [string]$finalFilter = [Microsoft.Azure.Cosmos.Table.TableQuery]::CombineFilters($Filter1,"and",$Filter2)
        $personToDelete = Get-AzTableRowByCustomFilter -Table $Table -CustomFilter $finalFilter
        $personToDelete | Remove-AzTableRow -Table $Table
    .EXAMPLE
        # Deleting an entry by using PartitionKey and row key directly
        Remove-AzTableRow -Table $Table -PartitionKey "TableEntityDemoFullList" -RowKey "399b58af-4f26-48b4-9b40-e28a8b03e867"
    .EXAMPLE
        # Deleting everything
        Get-AzTableRowAll -Table $Table | Remove-AzTableRow -Table $Table
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $Table,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="byEntityPSObjectObject")]
        $entity,

        [Parameter(Mandatory=$true,ParameterSetName="byPartitionandRowKeys")]
        [AllowEmptyString()]
        [string]$PartitionKey,

        [Parameter(Mandatory=$true,ParameterSetName="byPartitionandRowKeys")]
        [AllowEmptyString()]
        [string]$RowKey
    )

    begin
    {
        $updatedEntityList = @()
        $updatedEntityList += $entity

        if ($updatedEntityList.Count -gt 1)
        {
            throw "Delete operation cannot happen on an array of entities, altough you can pipe multiple items."
        }
        
        $Results = @()
    }
    
    process
    {
        if ($PSCmdlet.ParameterSetName -eq "byEntityPSObjectObject")
        {
            $PartitionKey = $entity.PartitionKey
            $RowKey = $entity.RowKey
        }

        $TableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"
        [string]$Filter =  "(PartitionKey eq '$($PartitionKey)') and (RowKey eq '$($RowKey)')"
        $TableQuery.FilterString = $Filter
        #$itemToDelete = (ExecuteQueryAsync -Table $Table -TableQuery $TableQuery).Result
        $itemToDelete = ExecuteQueryAsync -Table $Table -TableQuery $TableQuery

        # Converting DynamicTableEntity to TableEntity for deletion
        $entityToDelete = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableEntity"
        $entityToDelete.ETag = $itemToDelete.Etag
        $entityToDelete.PartitionKey = $itemToDelete.PartitionKey
        $entityToDelete.RowKey = $itemToDelete.RowKey

        if ($entityToDelete -ne $null)
        {
               $Results += $Table.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::Delete($entityToDelete))
        }
    }
    
    end
    {
        return ,$Results
    }
}

function TestAzTableEmptyKeys
{
    param
    (
        [Parameter(Mandatory=$true)]
        $PartitionKey,

        [Parameter(Mandatory=$true)]
        $RowKey
    )

    $CosmosEmptyKeysErrorMessage = "Cosmos DB table API does not accept empty partition or row keys when using CloudTable.Execute operation, because of this we are disabling this capability in this module and it will not proceed." 

    if ([string]::IsNullOrEmpty($PartitionKey) -or [string]::IsNullOrEmpty($RowKey))
    {
        Throw $CosmosEmptyKeysErrorMessage
    }
}

function ExecuteQueryAsync
{
    param
    (
        [Parameter(Mandatory=$true)]
        $Table,
        [Parameter(Mandatory=$true)]
        $TableQuery
    )
    # Internal function
    # Executes query in async mode

    if ($TableQuery -ne $null)
    {
        $token = $null
        $AllRows = @()
        do
        {
            $Results = $Table.ExecuteQuerySegmentedAsync($TableQuery, $token)
            $token = $Results.Result.ContinuationToken
            $AllRows += $Results.Result.Results
        } while ($token)
    
        return $AllRows
    }
}

function GetPSObjectFromEntity($entityList)
{
    # Internal function
    # Converts entities output from the ExecuteQuery method of table into an array of PowerShell Objects

    $returnObjects = @()

    if (-not [string]::IsNullOrEmpty($entityList))
    {
        foreach ($entity in $entityList)
        {
            $entityNewObj = New-Object -TypeName psobject
            $entity.Properties.Keys | ForEach-Object {Add-Member -InputObject $entityNewObj -Name $_ -Value $entity.Properties[$_].PropertyAsObject -MemberType NoteProperty}

            # Adding table entity other attributes
            Add-Member -InputObject $entityNewObj -Name "PartitionKey" -Value $entity.PartitionKey -MemberType NoteProperty
            Add-Member -InputObject $entityNewObj -Name "RowKey" -Value $entity.RowKey -MemberType NoteProperty
            Add-Member -InputObject $entityNewObj -Name "TableTimestamp" -Value $entity.Timestamp -MemberType NoteProperty
            Add-Member -InputObject $entityNewObj -Name "Etag" -Value $entity.Etag -MemberType NoteProperty

            $returnObjects += $entityNewObj
        }
    }

    return $returnObjects

}

function new-scimError{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string][ValidateSet('307','308','400','401','403','404','409','412','413','500','501')]$status,
        [Parameter(Mandatory = $false)]
        [string][ValidateSet('invalidFilter','tooMany','uniqueness','mutability','invalidSyntax','invalidPath','noTarget','invalidValue','invalidVers','sensitive',$null)]$scimtype,
        [Parameter(Mandatory = $false)]
        [string]$detail
    )
    $errorResponse=[PSCustomObject]@{
        schema=@('urn:ietf:params:scim:api:messages:2.0:Error')
        status = $status
        detail = $detail #optional
    }
    if ($scimtype){
        $errorResponse | Add-Member -NotePropertyName 'scimType' -NotePropertyValue $scimtype
    }
    return $errorResponse
}
function new-scimListResponse($resources){
    $listresponse=[pscustomobject]@{
        schema=@('urn:ietf:params:scim:api:messages:2.0:ListResponse')
        totalResults=0
        itemsPerPage=0
        startIndex=0
        Resources=0        
    }
    #$json=test-json $resources
    if ($json){
        $resources=$resources | ConvertFrom-Json
    }
    $listresponse.Resources=$resources
    $listresponse.totalResults=$resources.count
    $listresponse.itemsPerPage=$resources.itemsPerPage
    return $listresponse
}
function get-scimServiceProviderConfig {
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'scimConfig'
    $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'ServiceProviderConfig'
    return ($rows.json | convertfrom-json)
}
function get-scimResourceTypes ($path) {
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'scimConfig'
    if ($path){
        $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'ResourceType' -RowKey $path
        $resourcetypes=$rows.json | ConvertFrom-Json
        $response=$resourcetypes
        if ($response.count -eq 0){
            $response=new-scimError -status 404 -detail "Resorce Type '$path' not found"
        }
    }else{
        $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'ResourceType'
        $resourcetypes=$rows.json | ConvertFrom-Json
        $response=new-scimListResponse -resources $resourcetypes
    }
    return ($response)
}
function get-scimSchema ($path) {
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'scimConfig'
    if ($path){
        $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'Schema' -RowKey $path
        $resourcetypes=$rows.json | ConvertFrom-Json
        $response=$resourcetypes
        if ($response.count -eq 0){
            $response=new-scimError -status 404 -detail "Resorce Type '$path' not found"
        }
    }else{
        $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'Schema'
        $resourcetypes=$rows.json | ConvertFrom-Json
        $response=new-scimListResponse -resources $resourcetypes
    }    
    return ($response)
}
function get-ScimItem {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string][ValidateSet(
            "urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig",
            "urn:ietf:params:scim:schemas:core:2.0:ResourceType",
            "urn:ietf:params:scim:schemas:core:2.0:Schema",
            "urn:ietf:params:scim:schemas:core:2.0:User",
            "urn:ietf:params:scim:api:messages:2.0:ListResponse",
            "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User",
            "urn:ietf:params:scim:schemas:core:2.0:Group",
            "urn:ietf:params:scim:api:messages:2.0:SearchRequest",
            "urn:ietf:params:scim:api:messages:2.0:PatchOp",
            "urn:ietf:params:scim:api:messages:2.0:BulkRequest",
            "urn:ietf:params:scim:api:messages:2.0:BulkResponse",
            "urn:ietf:params:scim:api:messages:2.0:Error")]$schemaURI,
            [Parameter(Mandatory = $false)]
            [string]$path
    )
    switch($schemauri){
        "urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"{return get-scimServiceProviderConfig}
        "urn:ietf:params:scim:schemas:core:2.0:ResourceType"{return get-scimResourceTypes -path $path}
        "urn:ietf:params:scim:schemas:core:2.0:Schema"{return get-scimSchema -path $path}
        "urn:ietf:params:scim:schemas:core:2.0:User"{}
        "urn:ietf:params:scim:api:messages:2.0:ListResponse"{}
        "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"{}
        "urn:ietf:params:scim:schemas:core:2.0:Group"{}
        "urn:ietf:params:scim:api:messages:2.0:SearchRequest"{}
        "urn:ietf:params:scim:api:messages:2.0:PatchOp"{}
        "urn:ietf:params:scim:api:messages:2.0:BulkRequest"{}
        "urn:ietf:params:scim:api:messages:2.0:BulkResponse"{}
        "urn:ietf:params:scim:api:messages:2.0:Error"{}
    }
}

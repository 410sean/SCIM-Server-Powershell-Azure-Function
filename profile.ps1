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
        
        [Parameter(Mandatory=$false,ParameterSetName="GetAll")]
        [Parameter(ParameterSetName="byPartitionKey")]
        [Parameter(ParameterSetName="byPartRowKeys")]
        [Parameter(ParameterSetName="byColummnString")]
        [Parameter(ParameterSetName="byColummnGuid")]
        [Parameter(ParameterSetName="byCustomFilter")]
        $Token=$null,
        
        [Parameter(Mandatory=$false,ParameterSetName="GetAll")]
        [Parameter(ParameterSetName="byPartitionKey")]
        [Parameter(ParameterSetName="byPartRowKeys")]
        [Parameter(ParameterSetName="byColummnString")]
        [Parameter(ParameterSetName="byColummnGuid")]
        [Parameter(ParameterSetName="byCustomFilter")]
        [switch]$returnToken,
        
        [Parameter(Mandatory=$false,ParameterSetName="GetAll")]
        [Parameter(ParameterSetName="byPartitionKey")]
        [Parameter(ParameterSetName="byPartRowKeys")]
        [Parameter(ParameterSetName="byColummnString")]
        [Parameter(ParameterSetName="byColummnGuid")]
        [Parameter(ParameterSetName="byCustomFilter")]
        $TakeCount=$null,

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
    <#
    .SYNOPSIS
        Takes a table and query object and performs an action on an azure table


    .PARAMETER Table
        (required) the cloud table type including auth information

    .PARAMETER TableQuery
        (required) pass this parameter an object type "Microsoft.Azure.Cosmos.Table.TableQuery" 

    .PARAMETER token
        optionally provide token to allow resuming query

    .PARAMETER returnToken
        switch parameter when set will return the token, useful when takecount is set in the tableQuery causing it to not get all results
    
    .PARAMETER resultSize

    .EXAMPLE
        $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
        $table=Get-AzStorageTable -Context $storageContext -Name 'User'
        $TableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"
        $TableQuery.FilterString="RowKey eq '$path'"
        $rows=GetPSObjectFromEntity(ExecuteQueryAsync -Table $table.CloudTable -TableQuery $TableQuery)

    .LINK
        https://www.powershellgallery.com/packages/AzureRmStorageTable/2.0.3
    
    .LINK
        https://www.powershellgallery.com/packages/AzTable/2.0.3


    #>
    param
    (
        [Parameter(Mandatory=$true)]
        $Table,
        [Parameter(Mandatory=$true)]
        $TableQuery,
        [Parameter(Mandatory=$false)]
        $token=$null,
        [Parameter(Mandatory=$false)]
        [switch]$returnToken,
        $resultSize=$null
    )
    # Internal function
    # Executes query in async mode

    if ($TableQuery -ne $null)
    {
        $AllRows = @()
        do
        {
            $Results = $Table.ExecuteQuerySegmentedAsync($TableQuery, $token)
            $token = $Results.Result.ContinuationToken
            #write-host $results.id
            $AllRows += $Results.Result.Results
        } while ($token -and ($null -eq $resultsize -or $allrows.count -lt $resultSize))
        if ($returnToken){
            return $AllRows,$token
        }else{
            return $AllRows
        }
        
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

function Add-AzTableRow
{
    <#
    .SYNOPSIS
        Adds a row/entity to a specified table
    .DESCRIPTION
        Adds a row/entity to a specified table
    .PARAMETER Table
        Table object of type Microsoft.Azure.Cosmos.Table.CloudTable where the entity will be added
    .PARAMETER PartitionKey
        Identifies the table partition
    .PARAMETER RowKey
        Identifies a row within a partition
    .PARAMETER Property
        Hashtable with the columns that will be part of the entity. e.g. @{"firstName"="Paulo";"lastName"="Marques"}
    .PARAMETER UpdateExisting
        Signalizes that command should update existing row, if such found by PartitionKey and RowKey. If not found, new row is added.
    .EXAMPLE
        # Adding a row
        Add-AzTableRow -Table $Table -PartitionKey $PartitionKey -RowKey ([guid]::NewGuid().tostring()) -property @{"firstName"="Paulo";"lastName"="Costa";"role"="presenter"}
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $Table,
        
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String]$PartitionKey,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String]$RowKey,

        [Parameter(Mandatory=$false)]
        [hashtable]$property,
        [Switch]$UpdateExisting
    )
    
    # Creates the table entity with mandatory PartitionKey and RowKey arguments
    $entity = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.DynamicTableEntity" -ArgumentList $PartitionKey, $RowKey
    
    # Adding the additional columns to the table entity
    foreach ($prop in $property.Keys)
    {
        if ($prop -ne "TableTimestamp")
        {
            $entity.Properties.Add($prop, $property.Item($prop))
        }
    }

    if ($UpdateExisting)
    {
        return ($Table.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrReplace($entity)))
    }
    else
    {
        return ($Table.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($entity)))
    }
}

function new-scimError{
    <#
    .SYNOPSIS
        returns SCIM 2.0 error response based on variables    

    .PARAMETER status
        (required) http status code of the response which indicates the type of error

    .PARAMETER scimType
        (optional) when there is a problem with the request then use this to specify the error type

    .PARAMETER detail
        string field to allow explanation of the error

    .EXAMPLE
        new-scimError -status 404 -detail "Resorce Type '$path' not found"

    .LINK
        https://tools.ietf.org/html/rfc7644#section-3.12
    
    #>
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
        schemas=@('urn:ietf:params:scim:api:messages:2.0:Error')
        status = $status
        detail = $detail #optional
    }
    if ($scimtype){
        $errorResponse | Add-Member -NotePropertyName 'scimType' -NotePropertyValue $scimtype
    }
    return $errorResponse
}
function new-scimListResponse{
    <#
    .SYNOPSIS
        returns SCIM 2.0 ListResponse response based on variables    

    .PARAMETER resources
        (required) scim resources which are to be returned by this list response

    .PARAMETER totalresults
        (optional) when returning partial results, provide the total count of results

    .EXAMPLE
        $response=new-scimListResponse -resources $resourcetypes

    .EXAMPLE
        $response=new-scimListResponse -resources $rows[$start..$finish] -totalResults $rows.count

    .LINK
        https://tools.ietf.org/html/rfc7644#section-3.4.2
    
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $resources,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [int]$totalresults=$null
    )
    $listresponse=[pscustomobject]@{
        schemas=@('urn:ietf:params:scim:api:messages:2.0:ListResponse')
        totalResults=0
        itemsPerPage=0
        startIndex=1
        Resources=@()      
    }
    #$json=test-json $resources
    if ($json){
        $resources=@($resources) | ConvertFrom-Json
    }
    $listresponse.Resources=@($resources)
    $listresponse.totalResults=(@($resources.count,$totalresults) | measure-object -Maximum).maximum
    $listresponse.itemsPerPage=$resources.count
    return $listresponse
}
function get-scimServiceProviderConfig {
    <#
    .SYNOPSIS
        handles response to get request on /serviceproviderconfig endpoint
    
    .DESCRIPTION
        returns SCIM 2.0 service Proider config response
    
    .EXAMPLE
        get-scimServiceProviderConfig

    .LINK
        https://tools.ietf.org/html/rfc7643#section-5
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.5
    
    #>
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'scimConfig'
    $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'ServiceProviderConfig'
    return ($rows.json | convertfrom-json)
}
function get-scimResourceTypes  {
     <#
    .SYNOPSIS
        handles get operation on /ResourceTypes endpoint

    .DESCRIPTION
        returns SCIM 2.0 ResourceTypes response 
        returns all ResourceTypes in a listResponse or a single ResourceType if $path is specified

    .PARAMETER path
        (optional) path at the end of the URL if requested

    .EXAMPLE
        $response=get-scimResourceTypes

    .EXAMPLE
        $response=get-scimResourceTypes -path 'User'

    .LINK
        https://tools.ietf.org/html/rfc7643#section-6
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.6
    
    #>
    [cmdletbinding()]
    param($path)
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
        $resourcetypes=@($rows.json | ForEach-Object {convertfrom-json -InputObject $_})
        $response=new-scimListResponse -resources $resourcetypes
    }
    return ($response)
}
function get-scimSchema {
    <#
    .SYNOPSIS
        handles get request to /schemas endpoint

    .DESCRIPTION
        returns SCIM 2.0 Schema response 
        returns all Schemas in a listResponse or a single Schema if $path is specified

    .PARAMETER path
        (optional) path at the end of the URL if requested

    .EXAMPLE
        $response=get-scimSchema

    .EXAMPLE
        $response=get-scimSchema -path "urn:ietf:params:scim:schemas:core:2.0:User"

    .LINK
        https://tools.ietf.org/html/rfc7643#section-7
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.7
    
    #>
    [cmdletbinding()]
    param($path)
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'scimConfig'
    if ($path){
        $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'Schema' -RowKey $path
        $resourcetypes=$rows.json | ConvertFrom-Json
        $resourcetypes.attributes=get-scimSchemaAttributes -schema $resourcetypes.id
        $response=$resourcetypes
        if ($response.count -eq 0){
            $response=new-scimError -status 404 -detail "Resorce Type '$path' not found"
        }
    }else{
        $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'Schema'
        $resourcetypes=@($rows.json | ForEach-Object {convertfrom-json -InputObject $_})
        ForEach ($resource in $resourcetypes){
            $resource.attributes=get-scimSchemaAttributes -schema $resource.id
        }
        $response=new-scimListResponse -resources $resourcetypes
    }    
    return ($response)
}

function new-scimItemUser{
    <#
    .SYNOPSIS
         converts user from azure table to SCIM 2.0

    .DESCRIPTION
        correctly formats user from azure table into SCIM 2.0 format needed for response based on schema

    .PARAMETER user
        (required) a single user details from azure table

    .EXAMPLE
        $scimusers+=new-scimItemUser -user $row

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $user
    )
    $scimuser=@{
        schemas=@('urn:ietf:params:scim:schemas:core:2.0:User')
        id = $user.rowkey
        meta=$user.meta
    }
    foreach ($prop in (get-scimSchemaAttributes -schema $scimuser.schemas[0]).where{$_.name -notin @('id')}){
        $scimuser.($prop.name)=$user.($prop.name)
    }
    if (test-json $scimuser.meta){$scimuser.meta=$scimuser.meta | convertfrom-json}
    return $scimuser
}
function get-scimUser {
    <#
    .SYNOPSIS
         handles /Users endpoint with get method

    .DESCRIPTION
        produces response for a get operation on the /Users endpoint handling optional path and queries

    .PARAMETER startIndex
        integer, used when producing a list response of user to specify where to start

    .PARAMETER itemsPerPage
        integer, used when producing a list response of user to specify how many users to return
        if value is null or exceeds serviceproviderconfig's filter.maxResults then we will use server setting

    .PARAMETER attributes
        string, when provided specifies if a reduced set of attributes should be returned in the response
        default will return entire user attribute set

    .PARAMETER filter
        string, when provided it will return a listresponse of user results that match the filter
        default is null and will return all users
    
    .PARAMETER path
        string, guid, when provided the path should include a single user's ID and return just that user if found
        providing this property is the only way we do not respond with a listresponse
    
    .EXAMPLE
        $response=get-scimUser

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [int]$startIndex=1,
        [Parameter(Mandatory = $false)]
        [int]$itemsPerPage=$null,
        [Parameter(Mandatory = $false)]
        [string]$attributes=$null,
        [Parameter(Mandatory = $false)]
        [string]$filter=$null,
        [Parameter(Mandatory = $false)]
        [string]$path=$null
    )
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'User'
    if ($path){ #single resource
        $TableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"
        $TableQuery.FilterString="RowKey eq '$path'"
        $rows=GetPSObjectFromEntity(ExecuteQueryAsync -Table $table.CloudTable -TableQuery $TableQuery)
        if ($rows.count -eq 0){
            return new-scimError -status 404 -detail "User '$path' not found"
        }
        $scimuser=new-scimItemUser -user $rows
        return $scimuser
    }#after this point, list response of query
    $serverConfig=[int](get-scimServiceProviderConfig).filter.maxResults
    if ($itemsPerPage -eq 0){$itemsPerPage=$serverConfig}
    [int]$itemsPerPage=(@($serverconfig,$itemsPerPage) | measure-object -Minimum).Minimum
    if ($attributes)  {
        $selectColumns=New-Object System.Collections.Generic.List[string]
        $selectColumns.add($attributes)
        $selectColumns.add('meta')
    }
    $rows,$total=get-scimuseraggregation -cloudTable $table.CloudTable -start $startIndex -count $itemsPerPage -TableQueryFilterString $filter -TableQuerySelectColumns $selectColumns
    $scimusers=@()
    if ($null -ne $rows){
        ForEach ($resource in $rows){
            $scimusers+=((GetPSObjectFromEntity($resource)) | new-scimItemUser)
        }
    }
    $response=new-scimListResponse -resources $scimusers -totalresults $total
    $response.startIndex=$startIndex
    return ($response)     
}
function get-scimSchemaAttributes {
    <#
    .SYNOPSIS
        returns schema's attributes

    .DESCRIPTION
        produces response for a get operation on the /Users endpoint handling optional path and queries

    .PARAMETER schema
        (required) string, will return the schema attributes that match the requested schema

    .PARAMETER tableObjects
        switch, when set this will return additional information making it NOT compliant with scim 2.0 
        provided information necessary to populate rest attributes
   
    .EXAMPLE
        $response=get-scimUser

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$schema,
        [Parameter(Mandatory = $false)]
        [switch]$tableObjects
    )
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'scimConfig'
    $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey $Schema
    if ($tableObjects){
        $rows | foreach {$_.json=convertfrom-json $_.json}
        return $rows
    }else{
        $attributes=@($rows.json | ForEach-Object {convertfrom-json -InputObject $_})
        return @($attributes)
    }
}
function get-ScimItem {
    <#
    .SYNOPSIS
        SCIM 2.0 data resources

    .DESCRIPTION
        produces valid data resources and server-related objects for SCIM Schema URIs

    .LINK
        https://www.iana.org/assignments/scim/scim.xhtml

    .LINK
        https://tools.ietf.org/html/rfc7643
    
    .LINK
        https://tools.ietf.org/html/rfc7644
    
    #>
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
        [string]$path,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName='Error')]
        [string][ValidateSet('307','308','400','401','403','404','409','412','413','500','501')]$statusCode,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName='Error')]
        [string]$detail,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName='Error')]
        [string]$scimType,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName='ListResponse')]
        [string]$resources
    )
    switch($schemauri){
        "urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"{return get-scimServiceProviderConfig}
        "urn:ietf:params:scim:schemas:core:2.0:ResourceType"{return get-scimResourceTypes -path $path}
        "urn:ietf:params:scim:schemas:core:2.0:Schema"{return get-scimSchema -path $path}
        "urn:ietf:params:scim:schemas:core:2.0:User"{return get-scimuser -path $path }
        "urn:ietf:params:scim:api:messages:2.0:ListResponse"{return new-scimListResponse -resources $resources}
        "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"{}
        "urn:ietf:params:scim:schemas:core:2.0:Group"{}
        "urn:ietf:params:scim:api:messages:2.0:SearchRequest"{}
        "urn:ietf:params:scim:api:messages:2.0:PatchOp"{}
        "urn:ietf:params:scim:api:messages:2.0:BulkRequest"{}
        "urn:ietf:params:scim:api:messages:2.0:BulkResponse"{}
        "urn:ietf:params:scim:api:messages:2.0:Error"{return new-scimError -status $statusCode -detail $detail -scimtype $scimType}
    }
}

#function get-scimuserobject{
#    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
#    $table=Get-AzStorageTable -Context $storageContext -Name 'User'
#    $rows=Get-AzTableRow -Table $table.cloudtable -PartitionKey 'User' -RowKey $path
#}

function update-scimuserput {
    <#
    .SYNOPSIS
         handles /Users endpoint with put method

    .DESCRIPTION
        will attempt to update user specified in put and respond with updated user
    
    .PARAMETER request
        (Required) psobject, the request body with attribute changes

    .PARAMETER path
        (Required) string, guid, the user's id as passed via the url path

    .LINK
        https://tools.ietf.org/html/rfc7644#section-3.5.1

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param($request,$path)
    $schema=get-scimSchemaAttributes -schema 'urn:ietf:params:scim:schemas:core:2.0:User' -tableObjects
    $guid=$request.id
    $user=get-scimuser -path $guid
    get-scimUser -path $request.id
    foreach($attribute in $schema){
        $response=test-scimuserconstraintUniqueness -attributeschema $attribute -value $request.($attribute.rowkey)
        if ($response){return $response}
        $response=test-scimuserconstraintRequired -attributeschema $attribute -value $request.($attribute.rowkey)
        if ($response){return $response}
        $response=test-scimuserconstraintMutability -attributeschema $attribute -value $request.($attribute.rowkey)
        if ($response){return $response}
        $response=test-scimuserconstraintType -attributeschema $attribute -value $request.($attribute.rowkey)
        if ($response){return $response}
        if ($attribute.url){
            $scimuser.($attribute.rowkey)=get-scimrestattribute -attributeschema $attribute -request $request
        }else{
            $scimuser.($attribute.rowkey)=$request.($attribute.rowkey)
        }
    }
    $timestamp=(get-date).ToUniversalTime().getdatetimeformats()[101]
    $scimuser.meta=@{
        resourceType='User'
        created = $timestamp
        lastModified = $timestamp
        location="/Users/$($scimuser.RowKey)"
    } | convertto-json
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'User'
    Add-AzTableRow -PartitionKey 'User' -RowKey $guid -Table $table.CloudTable -property $scimuser
    $newuser=get-scimUser -path $guid
    return $newuser
}

function Remove-scimUser {
    <#
    .SYNOPSIS
         handles /Users endpoint with delete method

    .DESCRIPTION
        will remove a user based on path of delete request
    
    .PARAMETER path
        (Required) string, guid, the path of the url following the /Users endpoint which specifies a user guid

    .LINK
        https://tools.ietf.org/html/rfc7644#section-3.6

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$path
        )
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'User'
    if ($null -ne (Get-AzTableRow -Table $Table.CloudTable -PartitionKey 'User' -RowKey $path)){
        $results=Remove-AzTableRow -Table $Table.CloudTable -PartitionKey 'User' -RowKey $path
    }else{
        return new-scimError -status 404 -detail "unable to find user id '$path' for removal"
    }
    return  $results      

}
function new-scimuser {
    <#
    .SYNOPSIS
         handles /Users endpoint with post method

    .DESCRIPTION
        will create a new user based on body of post request
    
    .PARAMETER request
        (Required) psobject, the request body with new user details

    .LINK
        https://tools.ietf.org/html/rfc7644#section-3.3

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param([Parameter(Mandatory = $true, ValueFromPipeline = $true)]$request)
    $schema=get-scimSchemaAttributes -schema 'urn:ietf:params:scim:schemas:core:2.0:User' -tableObjects
    $guid=(new-guid).guid
    $scimuser=@{
        PartitionKey='User'
        RowKey=$guid
    }
    foreach($attribute in $schema.where{$_.rowkey -ne 'id'}){
        $response=test-scimuserconstraintUniqueness -attributeschema $attribute -value ($request.($attribute.rowkey))
        if ($response){return $response}
        $response=test-scimuserconstraintRequired -attributeschema $attribute -value $request.($attribute.rowkey)
        if ($response){return $response}
        $response=test-scimuserconstraintMutability -attributeschema $attribute -value $request.($attribute.rowkey)
        if ($response){return $response}
        $response=test-scimuserconstraintType -attributeschema $attribute -value $request.($attribute.rowkey)
        if ($response){return $response}
        if ($attribute.url){
            $temp=get-scimrestattribute -attributeschema $attribute -request $request
            if ($null -ne $temp){
                $scimuser.($attribute.rowkey)=$temp
            }
        }else{
            $temp=$request.($attribute.rowkey)
            if ($null -ne $temp){
                $scimuser.($attribute.rowkey)=$temp
            }
        }
    }
    $scimuser.id=$guid
    $timestamp=(get-date).ToUniversalTime().getdatetimeformats()[101]
    $scimuser.meta=@{
        resourceType='User'
        created = $timestamp
        lastModified = $timestamp
        location="/Users/$($scimuser.RowKey)"
    } | convertto-json
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'User'
    $result=Add-AzTableRow -PartitionKey 'User' -RowKey $guid -Table $table.CloudTable -property $scimuser
    
    $newuser=get-scimUser -path $guid
    return $newuser
}
#test-scimuserconstraint will return a scim error if a bad input is found (#TODO)

function test-scimuserconstraintUniqueness {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        $attributeschema,
        [Parameter(Mandatory = $false)]
        $value
    )
    if ($attributeschema.json.uniqueness -in @('none',$null)){return $false}
    $filter="$($attributeschema.json.name) eq '$value'"
    Write-Verbose "checking $filter"
    $test=get-scimUser -filter $filter
    if ($test.itemsPerPage -gt 0){return new-scimError -status 409 -scimtype uniqueness -detail "The value for $($attribute.json.name) is required to be unique. '$value' already exists"}
    return $false
}

function test-scimuserconstraintRequired {
    <#
    .SYNOPSIS
        on create or update, will checks for attribute constraint required

    .DESCRIPTION
        on create or update this will check if an attribute is required 
        and if so it will then check if it was provided
    
    .PARAMETER attributeschema
        (Required) psobject, the attribute schema properties for the attribute we are checking

    .PARAMETER value
        value of attribute in create/update request

    .LINK
        https://tools.ietf.org/html/rfc7644#section-3.3

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        $attributeschema,
        [Parameter(Mandatory = $false)]
        $value
    )
    if ($attributeschema.json.required -in @('False',$null)){return $false}
    if ($null -eq $value){return new-scimError -status 400 -scimtype invalidValue -detail "A required value was missing for $($attributeschema.RowKey)"}
    return $false
}

function test-scimuserconstraintMutability {
    <#
    .SYNOPSIS
        on create or update, will checks for attribute constraint mutability

    .DESCRIPTION
        on create or update this will check if an attribute has mutability that is writeable 
    
    .PARAMETER attributeschema
        (Required) psobject, the attribute schema properties for the attribute we are checking

    .PARAMETER value
        value of attribute in create/update request

    .LINK
        https://tools.ietf.org/html/rfc7644#section-3.3

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        $attributeschema,
        [Parameter(Mandatory = $false)]
        $value
    )
    if ($attributeschema.json.mutability -in @('readWrite',$null)){return $null}
    return $null
}

function test-scimuserconstraintType {
    <#
    .SYNOPSIS
        on create or update, will checks for attribute constraint type

    .DESCRIPTION
        on create or update this will check if an attribute is a value that can become the appropriate type 
    
    .PARAMETER attributeschema
        (Required) psobject, the attribute schema properties for the attribute we are checking

    .PARAMETER value
        value of attribute in create/update request

    .LINK
        https://tools.ietf.org/html/rfc7644#section-3.3

    .LINK
        https://tools.ietf.org/html/rfc7643#section-4
    
    .LINK
        https://tools.ietf.org/html/rfc7643#section-8.1
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        $attributeschema,
        [Parameter(Mandatory = $false)]
        $value
    )
    return $null
}   

function get-scimRestAttribute {
    <#
    .SYNOPSIS
        fills in attributes configured as rest attributes

    .DESCRIPTION
        on create or update when the attribute is configured as a rest attribute this will query a rest endpoint like azure logic apps
        it will pull the needed values for creating a json input
        make a post request to the url with the input json
        and from the response extract and return the value from the output json to be assigned to the user
    
    .PARAMETER attributeschema
        (Required) psobject, the attribute schema properties for the attribute we are checking

    .PARAMETER request
        all values of the user in create/update request
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$attributeschema,
        [Parameter(Mandatory = $true)]
        [object]$request
    )
    $body=($attributeschema.input | convertfrom-json).properties
    foreach ($prop in get-member -InputObject $body -MemberType noteproperty){
        switch ("$($body.($prop.name).type)"){
            "string"{[string]$body.($prop.name)=$request.($prop.name)}
            default{$body.($prop.name)=$request.($prop.name)}
        }
    }
    $response=Invoke-RestMethod -Method post -Uri $attributeschema.url -Body ($body | convertto-json) -ContentType 'application/json'
    $output=get-member -InputObject ($attributeschema.output | convertfrom-json).properties -MemberType noteproperty
    return $response.($output.name)
}
function Test-BasicAuthCred{
    <#
    .SYNOPSIS
        check for basic auth

    .DESCRIPTION
        for select endpoints they can call this function with the authorization header to have basic auth validated
        it will be considered succesful if authorization matches $env:basicauth 
        or $env:basicauth is not properly configured for basic auth
        on a failure a scim error will br returned
    
    .PARAMETER Authorization
        (Required) string, the attribute schema properties for the attribute we are checking

    .PARAMETER value
        value of attribute in create/update request

    .EXAMPLE
        $body=Test-BasicAuthCred -authorization ($request.Headers.Authorization)
        if ($null -ne $body){
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::Unauthorized
                Body = $body
                headers = @{"Content-Type"= "application/scim+json"}
            })
        }

    .LINK
        https://tools.ietf.org/html/rfc7617
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Authorization
    )
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
                return new-scimError -status 401 -detail "failed basic auth:not using basic auth"
            }
            try{
                $bytes=[convert]::frombase64string($hash)
                $creds=[System.Text.Encoding]::utf8.Getstring($bytes).split(':')
                write-host "recieved $([System.Text.Encoding]::utf8.Getstring($bytes))"
                if ($creds[0] -eq $basicauthsettings.client_id -and $creds[1] -eq $basicauthsettings.client_secret){
                    return $null
                }
            }
            catch{return new-scimError -status 401 -detail "failed basic auth: problem reading credential"}
        }else{
            return $null
        }
    }
    return new-scimError -status 401 -detail "failed basic auth"
}
function get-HttpStatusCode {
    <#
    .SYNOPSIS
        convert http status code number into [System.Net.HttpStatusCode]
    
    .PARAMETER code
        (Required) integer

    .EXAMPLE
        $status=get-HttpStatusCode 200

    .LINK
        https://docs.microsoft.com/en-us/dotnet/api/system.net.httpstatuscode?view=netcore-3.1

    .LINK
        https://tools.ietf.org/html/rfc2616

    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$code
    )
    switch ($code){
        100{$httpstatus=[System.Net.HttpStatusCode]::Continue}
        101{$httpstatus=[System.Net.HttpStatusCode]::SwitchingProtocols}
        102{$httpstatus=[System.Net.HttpStatusCode]::Processing}
        103{$httpstatus=[System.Net.HttpStatusCode]::EarlyHints}
        200{$httpstatus=[System.Net.HttpStatusCode]::OK}
        201{$httpstatus=[System.Net.HttpStatusCode]::Created}
        202{$httpstatus=[System.Net.HttpStatusCode]::Accepted}
        203{$httpstatus=[System.Net.HttpStatusCode]::NonAuthoritativeInformation}
        204{$httpstatus=[System.Net.HttpStatusCode]::NoContent}
        205{$httpstatus=[System.Net.HttpStatusCode]::ResetContent}
        206{$httpstatus=[System.Net.HttpStatusCode]::PartialContent}
        207{$httpstatus=[System.Net.HttpStatusCode]::MultiStatus}
        208{$httpstatus=[System.Net.HttpStatusCode]::MultiStatus}
        226{$httpstatus=[System.Net.HttpStatusCode]::IMUsed}
        300{$httpstatus=[System.Net.HttpStatusCode]::Ambiguous;Write-Warning "http status code 300, returning 'Ambiguous' but possibly could be 'MultipleChoices'"}
        301{$httpstatus=[System.Net.HttpStatusCode]::Moved;Write-Warning "http status code 301, returning 'Moved' but possibly could be 'MovedPermanently'"}
        302{$httpstatus=[System.Net.HttpStatusCode]::Redirect;Write-Warning "http status code 302, returning 'Redirect' but possibly could be 'Found'"}
        303{$httpstatus=[System.Net.HttpStatusCode]::RedirectMethod;Write-Warning "http status code 303, returning 'RedirectMethod' but possibly could be 'SeeOther'"}
        304{$httpstatus=[System.Net.HttpStatusCode]::NotModified}
        305{$httpstatus=[System.Net.HttpStatusCode]::UseProxy}
        306{$httpstatus=[System.Net.HttpStatusCode]::Unused}
        307{$httpstatus=[System.Net.HttpStatusCode]::TemporaryRedirect;Write-Warning "http status code 307, returning 'TemporaryRedirect' but possibly could be 'RedirectKeepVerb'"}
        308{$httpstatus=[System.Net.HttpStatusCode]::PermanentRedirect}
        400{$httpstatus=[System.Net.HttpStatusCode]::BadRequest}
        401{$httpstatus=[System.Net.HttpStatusCode]::Unauthorized}
        402{$httpstatus=[System.Net.HttpStatusCode]::PaymentRequired}
        403{$httpstatus=[System.Net.HttpStatusCode]::Forbidden}
        404{$httpstatus=[System.Net.HttpStatusCode]::NotFound}
        405{$httpstatus=[System.Net.HttpStatusCode]::MethodNotAllowed}
        406{$httpstatus=[System.Net.HttpStatusCode]::NotAcceptable}
        407{$httpstatus=[System.Net.HttpStatusCode]::ProxyAuthenticationRequired}
        408{$httpstatus=[System.Net.HttpStatusCode]::RequestTimeout}
        409{$httpstatus=[System.Net.HttpStatusCode]::Conflict}
        410{$httpstatus=[System.Net.HttpStatusCode]::Gone}
        411{$httpstatus=[System.Net.HttpStatusCode]::LengthRequired}
        412{$httpstatus=[System.Net.HttpStatusCode]::PreconditionFailed}
        413{$httpstatus=[System.Net.HttpStatusCode]::RequestEntityTooLarge}
        414{$httpstatus=[System.Net.HttpStatusCode]::RequestUriTooLong}
        415{$httpstatus=[System.Net.HttpStatusCode]::UnsupportedMediaType}
        416{$httpstatus=[System.Net.HttpStatusCode]::RequestedRangeNotSatisfiable}
        417{$httpstatus=[System.Net.HttpStatusCode]::ExpectationFailed}
        421{$httpstatus=[System.Net.HttpStatusCode]::MisdirectedRequest}
        422{$httpstatus=[System.Net.HttpStatusCode]::UnprocessableEntity}
        423{$httpstatus=[System.Net.HttpStatusCode]::Locked}
        424{$httpstatus=[System.Net.HttpStatusCode]::FailedDependency}
        426{$httpstatus=[System.Net.HttpStatusCode]::UpgradeRequired}
        428{$httpstatus=[System.Net.HttpStatusCode]::PreconditionRequired}
        429{$httpstatus=[System.Net.HttpStatusCode]::TooManyRequests}
        431{$httpstatus=[System.Net.HttpStatusCode]::RequestHeaderFieldsTooLarge}
        451{$httpstatus=[System.Net.HttpStatusCode]::UnavailableForLegalReasons}
        500{$httpstatus=[System.Net.HttpStatusCode]::InternalServerError}
        501{$httpstatus=[System.Net.HttpStatusCode]::NotImplemented}
        502{$httpstatus=[System.Net.HttpStatusCode]::BadGateway}
        503{$httpstatus=[System.Net.HttpStatusCode]::ServiceUnavailable}
        504{$httpstatus=[System.Net.HttpStatusCode]::GatewayTimeout}
        505{$httpstatus=[System.Net.HttpStatusCode]::HttpVersionNotSupported}
        506{$httpstatus=[System.Net.HttpStatusCode]::VariantAlsoNegotiates}
        507{$httpstatus=[System.Net.HttpStatusCode]::InsufficientStorage}
        508{$httpstatus=[System.Net.HttpStatusCode]::LoopDetected}
        510{$httpstatus=[System.Net.HttpStatusCode]::NotExtended}
        511{$httpstatus=[System.Net.HttpStatusCode]::NetworkAuthenticationRequired}
    }
    return $httpstatus
}
function merge-PatchOps {
    <#
    .SYNOPSIS
        apply patch operation to 
    
    .PARAMETER originalObject
        pscustomobject of the object we wish to apply patch operations on.
    
    .PARAMETER patchOps
        pscustomobject (or json) of the opject we wish to apply patch operations to

    .EXAMPLE
        $updateObject=merge-PatchOps -originalObject $user -patchOps $request.body

    .LINK
        http://jsonpatch.com/

    .LINK
        https://tools.ietf.org/html/rfc6902

    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        $originalObject,
        [Parameter(Mandatory = $true)]
        $patchOps
    )
    $peap=$ErrorActionPreference
    $ErrorActionPreference='continue'
    if ($patchOps | Convertfrom-Json -depth 10){$patchops=$patchOps | Convertfrom-Json -depth 10}
    if ($originalObject | Convertfrom-Json -depth 10){$originalObject=$originalObject | Convertfrom-Json -depth 10}
    $ErrorActionPreference=$peap
    foreach ($op in $patchOps){
        switch($op.op){
            'add'{"$($op.op) $($op.value)"}
            'remove'{"$($op.op) $($op.value)"}
            'replace'{"$($op.op) $($op.value)"}
            'move'{"$($op.op) $($op.value)"}
            'copy'{"$($op.op) $($op.value)"}
            'test'{"$($op.op) $($op.value)"}
        }
    }
}

function get-scimuseraggregation
 {
    [cmdletbinding()]
    param (
        $cloudTable,
        [string]$TableQueryFilterString='',
        $TableQuerySelectColumns=$null,
        [ValidateScript({$_ -gt 0})]
        [int]$start=1,
        [ValidateScript({$_ -gt 0})]
        [int]$count=200
    )
    $tablecache=@()
    $tablecache=import-clixml "$([system.io.path]::gettemppath())tableCache.clixml"
    $tablecache=$tablecache.where{$_.timestamp -ge (get-date).AddMinutes(-15).ToUniversalTime()}
    $testagg=$tablecache.where{$_.tablequery.filterstring -eq $TableQueryFilterString -and $_.tablequery.selectColumns -eq $TableQuerySelectColumns} | Sort-Object timestamp -desc
    if ($testagg){
        $rows=$testagg[0].rows
    }else{
        $TableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"
        $TableQuery.FilterString=$TableQueryFilterString
        $TableQuery.SelectColumns=$TableQuerySelectColumns
        $rows=ExecuteQueryAsync -Table $cloudtable -TableQuery $TableQuery
        $timestamp=(get-date).ToUniversalTime()
        $tablecache+=[pscustomobject]@{
            timestamp=$timestamp
            tableQuery=$TableQuery
            totalCount=$rows.count
            rows=$rows
        }
        $tablecache | Export-Clixml -Path "$([system.io.path]::gettemppath())tableCache.clixml"
    }
    return $rows[($start-1)..($start+$count-2)],$rows.count
 }
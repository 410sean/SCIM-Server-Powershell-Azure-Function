using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes, $getUser)
Write-Verbose ($request | convertto-json -depth 10) -verbose
write-host ($request | convertto-json -depth 10) 
function new-scimuser ($prop){
    $userobj=[pscustomobject]@{
        schemas=@('urn:ietf:params:scim:schemas:core:2.0:User')
        id=$prop.RowKey
    }
    foreach ($attr in $schemaAttributes.name.where{$_ -notin ('schemas','id')}){
        if ($prop.$attr){$userobj | add-member -notepropertyname $attr -notepropertyvalue $prop.$attr}
    }
    $meta=[pscustomobject]@{
        resourceType='User'
        location="https://scimps.azurewebsites.net/api/Users/$($prop.RowKey)"
    }
    $userobj | add-member -notepropertyname meta -notepropertyvalue $meta
    return $userobj
}
$status = [HttpStatusCode]::OK
if ($Request.body -ne $null){
    $userjson=$Request.Body | convertfrom-json
    $guid=$userjson.id
    $myvalue=[pscustomobject]@{
        PartitionKey='User'
        RowKey=$guid
    }

    write-host "parsing $($Request.Body | convertto-json -depth 10)"
    write-host "parsing $($Request.Body))"
    write-host "parsing $($userjson.displayname)"
    foreach ($attr in $schemaAttributes.where{$_.PartitionKey -eq 'User'}.name){
        write-host "checking for $attr=$($userjson.$attr)"
        if ($userjson.$attr){$myvalue | add-member -notepropertyname $attr -notepropertyvalue $userjson.$attr}
    }

    Push-OutputBinding -Name createUser -Value $myValue 
}
    #$result=Invoke-RestMethod -Uri "$($Request.url)/$guid" -Method Get
#if ($result.schemas[0] -eq 'urn:ietf:params:scim:schemas:core:2.0:User'){
#    $body=$result
#}else{
    $body=new-scimuser $myvalue
#}
write-verbose $body -Verbose
$status = [HttpStatusCode]::OK
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $Body | convertto-json -depth 10
})

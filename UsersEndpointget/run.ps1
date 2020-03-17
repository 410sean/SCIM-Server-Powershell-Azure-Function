using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes, $User)
<#GET for retrieval of resources; POST for creation,
searching, and bulk modification; PUT for attribute replacement
within resources; PATCH for partial update of attributes; and DELETE
for removing resources#>
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
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
$resources=@()
if ($Request.params.path.length -eq 36){
    $userobj=$user.where{$_.RowKey -eq $Request.params.path}[0]
    if ($null -eq $userobj){
        $body=[pscustomobject]@{
            schemas=@("urn:ietf:params:scim:api:messages:2.0:Error")
            detail="User not found"
            status=404
        }
    }else{
        $body=new-scimuser -prop $userobj
    }
}elseif($Request.params.path.length -eq 0){
    #get all users (pagination)
    $body=[pscustomobject]@{
        startIndex= 1
        itemsPerPage= $resources.count
        totalResults= $resources.count
        schemas= @("urn:ietf:params:scim:api:messages:2.0:ListResponse")
        resources=@()
    }    
    foreach ($singleuser in $user){
        $userobj=new-scimuser -prop $singleuser
        $resources+=$userobj
    }
    if ($resources){$body.resources=@($resources)}
    $body.totalResults=$resources.count
    $body.itemsPerPage=$resources.count
}else{
    #TODO filter command
    $body=[pscustomobject]@{
        startIndex= 1
        itemsPerPage= 0
        totalResults= 0
        schemas= @("urn:ietf:params:scim:api:messages:2.0:ListResponse")
        resources=@()
    }    
}   
    $body.totalResults=$resources.count
    $body.itemsPerPage=$resources.count
    
    
    
    $status = [HttpStatusCode]::OK




$status = [HttpStatusCode]::OK
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body | convertto-json -depth 10
})

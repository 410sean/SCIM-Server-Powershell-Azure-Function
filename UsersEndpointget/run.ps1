using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes, $User)
<#GET for retrieval of resources; POST for creation,
searching, and bulk modification; PUT for attribute replacement
within resources; PATCH for partial update of attributes; and DELETE
for removing resources#>
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


if ($Request.params.path.length -eq 36){
    $body=[pscustomobject]@{
        schemas= @("urn:ietf:params:scim:api:messages:2.0:User")
    }    
    $userobj=$user.($Request.params.path)
    if ($null -eq $userobj){
        $body=[pscustomobj]@{
            schemas=@("urn:ietf:params:scim:api:messages:2.0:Error")
            detail="User not found"
            status=404
        }
    }else{
        $body=new-scimitem -schema 'User' -properties $userobj -location "https://scimps.azurewebsites.net/api/users/$($userobj.id)" -includeMeta
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
    $allusers=Get-Content $User -Raw | ConvertFrom-Json
    foreach ($singleuser in $allusers.getenumeration()){
        $userobj=new-scimitem -schema 'User' -properties $singleuser -location "https://scimps.azurewebsites.net/api/users/$($userobj.id)" -includeMeta
        $resources+=$userobj
    }
    if ($resources){$body.resources=@($resources)}
        
        
    
    
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
       
    
    
    
    
    $status = [HttpStatusCode]::OK




$status = [HttpStatusCode]::OK
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body | convertto-json -depth 10
})

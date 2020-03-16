using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $inputTable)
<#GET for retrieval of resources; POST for creation,
searching, and bulk modification; PUT for attribute replacement
within resources; PATCH for partial update of attributes; and DELETE
for removing resources#>
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
$schema=@('id','userName','displayName','companyCode','departmentCode','BusinessUnitCode','jobCode','location','domainID','EmployeeClass','PLMS','role','active')
# Interact with query parameters or the body of the request.
<#$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

if ($name) {
    $status = [HttpStatusCode]::OK
    $body=$Request
}#>

if ($Request.params.path){
    $user=@(Get-Content $inputTable -Raw | ConvertFrom-Json) | where-object{$_.id -eq $Request.params.path} | Select-Object $schema
    $user | Add-Member -NotePropertyName schemas -NotePropertyValue [pscustomobject]@("urn:ietf:params:scim:schemas:core:2.0:User")
        $user | Add-Member -NotePropertyName meta -NotePropertyValue ([PSCustomObject]@{
            resourceType = "User"
            location = "Users/$($user.id)"
        })
    $body=$user
}else{
    #get all users (pagination)
    $resources=Get-Content $inputTable -Raw | ConvertFrom-Json
    foreach ($user in $resources){
        $user | Add-Member -NotePropertyName schemas -NotePropertyValue [pscustomobject]@("urn:ietf:params:scim:schemas:core:2.0:User")
        $user | Add-Member -NotePropertyName meta -NotePropertyValue ([PSCustomObject]@{
            resourceType = "User"
            location = "Users/$($user.id)"
        })
    }
    $body=[pscustomobject]@{
        resources = $resources
        startIndex= 1
        itemsPerPage= $resources.count
        totalResults= $resources.count
        schemas= @("urn:ietf:params:scim:api:messages:2.0:ListResponse")
    }    
}   
       
    
    
    
    
    $status = [HttpStatusCode]::OK




$status = [HttpStatusCode]::OK
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

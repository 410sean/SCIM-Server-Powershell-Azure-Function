using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $User, $schemaAttributes, $Schemas)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
function Test-BasicAuthCred($Authorization){
    if ($env:basicauth){
        $basicauthsettings="$($env:basicauth)".Split(';') | foreach{$_ | ConvertFrom-Stringdata}
        if ($basicauthsettings.enabled){
            if ($Authorization.value -like "basic *"){$hash=$Authorization.value.replace('basic ','')}else{return $false}
            try{
                $bytes=[convert]::frombase64string($hash)
                $creds=[System.Text.Encoding]::utf8.Getstring($bytes).split(':')
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

if ((Test-BasicAuthCred -authorization ($request.Headers.autorization)) -eq $false){
    write-host "failed basic auth"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = @{
            status='401'
            response=@{
                schemas= @("urn:ietf:params:scim:api:messages:2.0:Error")
                scimType="invalidValue"
                detail='Basic Authentication Failed'
                status='401'
            }
        }
        headers = @{"Content-Type"= "application/scim+json"}
    })
    $badauth=$true
}
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
        location="https://$($Request.Headers.'disguised-host')/api/Users/$($prop.RowKey)"
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
        Resources=@()
    }
    $startindex=($Request.Query.startIndex)-1
    if ($startindex -lt 0){$startindex=0}
    $body.startIndex=$startindex+1
    $endindex=$startindex+$Request.Query.count-1
    foreach ($singleuser in $user[$startindex..$endindex]){
        $userobj=new-scimuser -prop $singleuser
        $resources+=$userobj
    }
    if ($resources){$body.resources=@($resources)}
    $body.totalResults=$user.count
    $body.itemsPerPage=$resources.count
}else{
    #TODO filter command
    $body=[pscustomobject]@{
        startIndex= 1
        itemsPerPage= [int]$resources.count
        totalResults= 0
        schemas= @("urn:ietf:params:scim:api:messages:2.0:ListResponse")
        resources=@()
    }    
}   

#$body.itemsPerPage=$resources.count
    
    
    
    $status = [HttpStatusCode]::OK




$status = [HttpStatusCode]::OK
write-host ($status | convertto-json -depth 10) 
write-host ($body | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body | convertto-json -depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})

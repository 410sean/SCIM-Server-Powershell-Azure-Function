using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes, $restAttributes)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
if ((Test-BasicAuthCred -authorization ($request.Headers.Authorization)) -eq $false){
    write-host "failed basic auth"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = @{
            status='401'
            response=@{
                schemas= @("urn:ietf:params:scim:api:messages:2.0:Error")
                scimType="invalidValue"
                detail="$($env:basicauth) recieved $($request.Headers.authorization)"
                status='401'
            }
        }
        headers = @{"Content-Type"= "application/scim+json"}
    })
    $keepgoing=$false
}
function new-scimuser ($prop){
    $userobj=[pscustomobject]@{
        schemas=@('urn:ietf:params:scim:schemas:core:2.0:User')
        id=$prop.RowKey
    }
    foreach ($attr in $schemaAttributes.name.where{$_ -notin ('schemas','id')}){
        if ($prop.$attr){$userobj | add-member -notepropertyname $attr -notepropertyvalue $prop.$attr}
    }
    $timestamp=(get-date).GetDateTimeFormats()[114].replace(' ','T')
    $meta=[pscustomobject]@{
        resourceType='User'
        created = $timestamp
        lastModified = $timestamp
        location="https://$($Request.Headers.'disguised-host')/api/Users/$($prop.RowKey)"
    }
    $userobj | add-member -notepropertyname meta -notepropertyvalue $meta
    return $userobj
}
$status = [HttpStatusCode]::OK
$guid=(new-guid).guid
$myvalue=[pscustomobject]@{
    PartitionKey='User'
    RowKey=$guid
}
if ($Request.Body.gettype().name -eq 'string'){
    $userjson=$Request.Body | convertfrom-json -depth 100
}else{
    $userjson=$Request.Body
}

#write-host "parsing $($Request.Body | convertto-json -depth 10)"
#write-host "parsing $($Request.Body))"
write-host "parsing $($userjson.displayName)"
foreach ($attr in $schemaAttributes.where{$_.PartitionKey -eq 'User'}.name){
    write-host "checking for $attr=$($userjson.$attr)"
    if ($userjson.$attr){$myvalue | add-member -notepropertyname $attr -notepropertyvalue $userjson.$attr}
}
foreach ($attr in $restAttributes){
    write-host $attr.input
    write-host $attr.output    
    $requestbody=[pscustomobject]@{}
    foreach ($in in $requestinputs){$requestbody | Add-Member -NotePropertyName $in -NotePropertyValue $myvalue.$in}
    write-host ($requestbody | convertto-json -depth 10) 
    write-host ($attr.url)
    $attrResult=Invoke-restmethod -Method post -Uri $attr.url -Body ($userjson | convertto-json -depth 10) -ContentType 'application/json'
    $myvalue | add-member -notepropertyname $attr.RowKey -notepropertyvalue $attrResult.($attr.RowKey)
}
write-host ($myValue | convertto-json -depth 10)
if ($status -eq [HttpStatusCode]::OK){ #required value check
    foreach ($req in $schemaAttributes.where{$_.Required}){ 
        if ($null -eq $myvalue.($req.name)){
            $status = [HttpStatusCode]::BadRequest
            $body={
                schemas= @("urn:ietf:params:scim:api:messages:2.0:Error")
                scimType="invalidValue"
                detail="Attribute '$($req.name)' is Required"
                status= "400"
            }
            break
        }
    }
}
if ($status -eq [HttpStatusCode]::OK){
    $body=new-scimuser $myvalue
    $myvalue | add-member -NotePropertyName 'meta' -NotePropertyValue $body.meta
    Push-OutputBinding -Name createUser -Value $myValue
    $status = [HttpStatusCode]::Created
    
}

write-verbose $body -Verbose

write-host ($status | convertto-json -depth 10) 
write-host ($Body | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $Body | convertto-json -depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes, $getUser, $restAttributes)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
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
$userobj=$getUser.where{$_.RowKey -eq $Request.params.path}
if ($null -eq $userobj){
    $body=[pscustomobject]@{
        schemas=@("urn:ietf:params:scim:api:messages:2.0:Error")
        detail="User not found"
        status=404
    }
}elseif ($userobj.count -eq 1){
    $userobj=$userobj[0]
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
        foreach ($attr in $restAttributes){
            $requestinputs=$attr.input.split(',')
            $requestbody=[pscustomobject]@{}
            foreach ($in in $requestinputs){$requestbody | Add-Member -NotePropertyName $in -NotePropertyValue $myvalue.$in}
            write-host ($myValue | convertto-json -depth 10) 
            $attrResult=Invoke-restmethod -Method post -Uri $attr.url -Body ($myValue | ConvertTo-Json -depth 10) -ContentType 'application/json'
            write-host ($attrResult | ConvertTo-Json -depth 10)
            $myvalue | add-member -notepropertyname $attr.rowkey -notepropertyvalue $attrResult.($attr.rowkey)
        }
        write-host ($myValue | convertto-json -depth 10) 
        #Push-OutputBinding -Name createUser -Value $myValue 
    }
}else{
}

    #$result=Invoke-RestMethod -Uri "$($Request.url)/$guid" -Method Get
#if ($result.schemas[0] -eq 'urn:ietf:params:scim:schemas:core:2.0:User'){
#    $body=$result
#}else{
if ($null -eq $body){
    $body=new-scimuser $myvalue
}
write-verbose $body -Verbose
$status = [HttpStatusCode]::OK
write-host ($status | convertto-json -depth 10) 
write-host ($Body | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $Body | convertto-json -depth 10
    headers = @{"Content-Type"= "application/json"}
})

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes)
Write-Verbose ($request | convertto-json -depth 10) -verbose
write-host ($request | convertto-json -depth 10) 
$status = [HttpStatusCode]::OK
$guid=(new-guid).guid
$myvalue=[pscustomobject]@{
    PartitionKey='User'
    RowKey=$guid
}
$userjson=$Request.Body | convertfrom-json
write-host "parsing $($Request.Body | convertto-json -depth 10)"
write-host "parsing $($Request.Body))"
write-host "parsing $($userjson.displayName)"
foreach ($attr in $schemaAttributes.where{$_.PartitionKey -eq 'User'}.name){
    write-host "checking for $attr=$($Request.Body.$attr)"
    if ($Request.Body.$attr){$myvalue | add-member -notepropertyname $attr -notepropertyvalue $Request.Body.$attr}
}
Push-OutputBinding -Name createUser -Value $myValue
#$result=Invoke-RestMethod -Uri "$($Request.url)/$guid" -Method Get
#if ($result.schemas[0] -eq 'urn:ietf:params:scim:schemas:core:2.0:User'){
#    $body=$result
#}else{
    $body=$myvalue
#}
write-verbose $body -Verbose
$status = [HttpStatusCode]::OK
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $Body | convertto-json -depth 10
})

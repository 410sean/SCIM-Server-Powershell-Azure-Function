using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $ServiceProviderConfig, $authenticationSchemes)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
$status = [HttpStatusCode]::OK
<#  
$psbody=[pscustomobject]@{
    schemas=@("urn:ietf:params:scim:schemas:core:2.0:$($ServiceProviderConfig.PartitionKey)")
}
foreach ($prop in $ServiceProviderConfig.getenumerator()){
    if ($prop.name -in ('PartitionKey','RowKey','Timestamp')){continue}
    if ($prop.name -like "*_*"){
        $tree="$($prop.name)".split('_')
        #write-host "$($tree[0]) - $($tree[1]) - $(($psbody."$($tree[0])") -eq $null)"
        if ($null -ne ($psbody."$($tree[0])")){
            $psbody."$($tree[0])" | add-member -notepropertyname "$($tree[1])" -notepropertyvalue ($prop.value) -verbose
        }else{
            $psbody | add-member -notepropertyname "$($tree[0])" -notepropertyvalue ([pscustomobject]@{"$($tree[1])"=$prop.value}) -verbose
        }
    }else{
        #write-host ($prop | out-string)
        #write-host "key=$($prop.name)"
        $psbody | add-member -notepropertyname $prop.name -notepropertyvalue $prop.value -verbose
    }   
}#>
$psauthenticationSchemes=@()
foreach ($auth in $authenticationSchemes.getenumerator()){
    $authscheme=[pscustomobject]@{}
    write-host "auth - $auth"
    foreach ($prop in $auth.keys){
        if ($prop -in ('PartitionKey','RowKey','Timestamp')){continue}
        $authscheme | add-member -notepropertyname "$prop" -notepropertyvalue $auth.$prop -verbose
    }
    $psauthenticationSchemes+=$authscheme
}
$meta=[pscustomobject]@{
    resourceType=$ServiceProviderConfig.PartitionKey
    location="https://$($Request.Headers.'disguised-host')/api/ServiceProviderConfig"
}
$psbody=new-scimItem -schema 'ServiceProviderConfig' -properties $ServiceProviderConfig
$psbody | add-member -notepropertyname 'authenticationSchemes' -notepropertyvalue $psauthenticationSchemes
$psbody | add-member -notepropertyname 'meta' -notepropertyvalue $meta
write-host ($status | convertto-json -depth 10) 
write-host ($psbody | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $psbody
})

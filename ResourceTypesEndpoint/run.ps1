using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $ResourceType)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
function new-scimItem ($schema, $properties, $location, [switch]$includeMeta){
  #will create item starting with schema and ending with meta
  #nested properties should have a property name that can be split by underscore '_'
  $psitem=[pscustomobject]@{
    schemas=@("urn:ietf:params:scim:schemas:core:2.0:$schema")
  }
  foreach ($prop in $properties.PSObject.Properties){
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
$status = [HttpStatusCode]::OK
  if ($Request.params.path -and $Request.params.path.length -ne 0){
    $targetresource=($ResourceType.where{$_.name -eq $Request.params.path})[0]
    write-host "converting resourcetype $($targetresource | convertto-json)"
    $psbody=new-scimItem -schema 'ResourceType' -properties $targetresource -location "https://$($Request.Headers.'disguised-host')/api/ResourceType/$($targetresource.name)" -includeMeta
  }else{
  $psbody=[pscustomobject]@{
    totalResults=0
    itemsPerPage=100
    startIndex=1
    schemas=@("urn:ietf:params:scim:api:messages:2.0:ListResponse")
    Resources=@()
  }
  $resources=@()
  foreach ($res in @($ResourceType)){
    write-host $res | convertto-json
    $resources+=$res
    #new-scimItem -schema 'ResourceType' -properties $res -location "https://$($Request.Headers.'disguised-host')/api/ResourceType/$($res.name)" -includeMeta
  }
  $psbody.totalResults=$resources.count
  $psbody.resources=@($resources)
}
write-host ($status | convertto-json -depth 10) 
write-host ($psbody | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $psbody
})

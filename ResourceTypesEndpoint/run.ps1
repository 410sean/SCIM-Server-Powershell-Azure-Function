using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $ResourceType)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$status = [HttpStatusCode]::OK
  if ($Request.params.path){
    $targetresource=($ResourceType.where{$_.name -eq $Request.params.path})[0]
    $psbody=new-scimItem -schema 'ResourceType' -properties $targetresource -location "https://scimps.azurewebsites.net/api/ResourceType/$($targetresource.name)" -includeMeta
  }else{
  $psbody=[pscustomobject]@{
    totalResults=0
    itemsPerPage=100
    startIndex=1
    schemas=@("urn:ietf:params:scim:schemas:core:2.0:ListResponse")
    Resources=@()
  }
  $resources=@()
  foreach ($res in $ResourceType){
    $resources=new-scimItem -schema 'ResourceType' -properties $res -location "https://scimps.azurewebsites.net/api/ResourceType/$($res.name)" -includeMeta
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

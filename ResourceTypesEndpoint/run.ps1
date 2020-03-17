using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $ResourceType)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$status = [HttpStatusCode]::OK
  if ($Request.params.path){
    $psbody=new-scimItem -schema 'ResourceType' -properties ($ResourceType.where{$_.name -eq $Request.params.path})[0] -location 'https://scimps.azurewebsites.net/api/ResourceType' -includeMeta
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
    $resources=new-scimItem -schema 'ResourceType' -properties $res -location "https://scimps.azurewebsites.net/api/ResourceType$($res.endpoint)" -includeMeta
  }
  $psbody.totalResults=$resources.count
  $psbody.resources=@($resources)
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $psbody
})

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $resourceType)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$status = [HttpStatusCode]::OK
$body='{
    "totalResults": 1,
    "itemsPerPage": 100,
    "startIndex": 1,
    "schemas": [
      "urn:ietf:params:scim:api:messages:2.0:ListResponse"
    ],
    "Resources": [
      {
        "schemas": [
          "urn:ietf:params:scim:schemas:core:2.0:ResourceType"
        ],
        "name": "User",
        "description": "Sean built this",
        "endpoint": "/Users",
        "schema": "urn:ietf:params:scim:schemas:core:2.0:User",
        "meta": {
          "resourceType": "ResourceType",
          "location": "https://scimps.azurewebsites.net/api/ResourceTypes/User"
        }
      }
    ]
  }'
  if ($Request.params.path){
    $psbody=create-scimItem -schema 'ResourceType' -properties $resourceType.where{$_.name -eq $Request.params.path} -location 'https://scimps.azurewebsites.net/api' -includeMeta
  }else{
  $psbody=[pscustomobject]@{
    totalResults=0
    itemsPerPage=100
    startIndex=1
    schemas=@("urn:ietf:params:scim:schemas:core:2.0:ListResponse")
  }
  $resources=@()
  foreach ($res in $resources){
    $resources+=create-scimItem -schema 'ResourceType' -properties $res -location "https://scimps.azurewebsites.net/api/ResourceType$($res.endpoint)" -includeMeta
  }
  $psbody.totalResults=$resources
  $psbody | Add-Member -NotePropertyName 'Resources' -NotePropertyValue $resources
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $psbody
})

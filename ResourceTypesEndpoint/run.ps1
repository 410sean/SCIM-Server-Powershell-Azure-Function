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

  }else{
  $psbody=[pscustomobject]@{
    totalResults=0
    itemsPerPage=100
    startIndex=1
    schemas=@("urn:ietf:params:scim:schemas:core:2.0:ListResponse")
  }
}
function create-scimItem ($schema, $properties, $location){
  #will create item starting with schema and ending with meta
  $psitem=[pscustomobject]@{
    schemas=@("urn:ietf:params:scim:schemas:core:2.0:$schema")
  }
  foreach ($prop in $properties.getenumerator()){
    if ($prop.name -in ('PartitionKey','RowKey','Timestamp')){continue}
    if ($prop.name -like "*_*"){
        $tree="$($prop.name)".split('_')
        if ($null -ne ($psbody."$($tree[0])")){
            $psitem."$($tree[0])" | add-member -notepropertyname "$($tree[1])" -notepropertyvalue ($prop.value) -verbose
        }else{
            $psitem | add-member -notepropertyname "$($tree[0])" -notepropertyvalue ([pscustomobject]@{"$($tree[1])"=$prop.value}) -verbose
        }
    }else{
        $psitem | add-member -notepropertyname $prop.name -notepropertyvalue $prop.value -verbose
    }
  }
  $meta=[pscustomobject]@{
    resourceType=$schema
    location="$location/$schema"
  }
  $psitem | add-member -notepropertyname 'meta' -notepropertyvalue $meta
  return $psitem
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

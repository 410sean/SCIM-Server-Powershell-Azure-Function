using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes)

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
      "id": "urn:ietf:params:scim:schemas:core:2.0:User",
      "name": "User",
      "description": "Front teammate Account",
      "attributes": [
        {
          "name": "userName",
          "description": "Teammate''s alias. REQUIRED.",
          "type": "string",
          "multiValued": false,
          "required": true,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "server"
        },
        {
          "name": "displayName",
          "description": "The name of the Teammate, suitable for display to end-users. UNSUPPORTED",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "companyCode",
          "description": "The company code of the user",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "EmployeeClass",
          "description": "the Employee Class of the user",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "departmentCode",
          "description": "the Department Code of the user",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "BusinessUnitCode",
          "description": "the Business Unit code, product code, or division code of the user",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "jobCode",
          "description": "the job code of the user",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "domainID",
          "description": "the domain override of the user",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "location",
          "description": "the office ID of the user",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "readWrite",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "role",
          "description": "the returned role of the user",
          "type": "string",
          "multiValued": false,
          "required": false,
          "caseExact": false,
          "mutability": "read",
          "returned": "default",
          "uniqueness": "none"
        },
        {
          "name": "active",
          "description": "A Boolean value indicating the Teammate''s administrative status. (Default to true)",
          "type": "boolean",
          "multiValued": false,
          "required": false,
          "mutability": "readWrite",
          "returned": "default"
        }
      ],
      "meta": {
        "resourceType": "Schema",
        "location": "https://scimps.azurewebsites.net/api/Schemas/urn:ietf:params:scim:schemas:core:2.0:User"
      }
    }
  ]
}'
if ($Request.params.path){
  $targetschema=($schemas.where{"urn:ietf:params:scim:schemas:core:2.0:$($_.name)" -eq $Request.params.path})[0]
  $targetattributes=($schemaAttributes.where{$_.PartitionKey -eq $targetschema.name})
  $psbody=[pscustomobject]@{
    id="urn:ietf:params:scim:schemas:core:2.0:$($targetschema.name)"
    name=$targetschema.name
    description=$targetschema.description
    attributes=@()
    meta=[pscustomobject]@{
      resourceType='Schema'
      location="https://scimps.azurewebsites.net/api/Schemas/urn:ietf:params:scim:schemas:core:2.0:$($targetschema.name)"
    }
  }
  foreach ($attr in $targetattributes | sort-object rowkey){
    $single=[pscustomobject]@{}
    foreach ($prop in $attr.getenumerator()){
      if ($prop.name -in ('PartitionKey','RowKey','Timestamp')){continue}
      $single | add-member -notepropertyname $prop.name -notepropertyvalue $prop.value -verbose
    }
    $psbody.attributes+=$single
  }
}else{
  $psbody=[pscustomobject]@{
    totalResults=0
    itemsPerPage=100
    startIndex=1
    schemas=@("urn:ietf:params:scim:schemas:core:2.0:ListResponse")
    Resources=@()
  }
  $resources=@()
  foreach ($targetschema in $resources){
    $targetattributes=($schemaAttributes.where{$_.PartitionKey -eq $targetschema.name})
    $schemabody=[pscustomobject]@{
      id="urn:ietf:params:scim:schemas:core:2.0:$($targetschema.name)"
      name=$targetschema.name
      description=$targetschema.description
      attributes=@()
      meta=[pscustomobject]@{
        resourceType='Schema'
        location="https://scimps.azurewebsites.net/api/Schemas/urn:ietf:params:scim:schemas:core:2.0:$($targetschema.name)"
      }
    }
    foreach ($attr in $targetattributes | sort-object rowkey){
      $single=[pscustomobject]@{}
      foreach ($prop in $attr.getenumerator()){
        if ($prop.name -in ('PartitionKey','RowKey','Timestamp')){continue}
        $single | add-member -notepropertyname $prop.name -notepropertyvalue $prop.value -verbose
      }
      $schemabody.attributes+=$single
    }
    $psbody.Resources+=$schemabody
  }
  $psbody.totalResults=$resources.count
  $psbody | Add-Member -NotePropertyName 'Resources' -NotePropertyValue $resources
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

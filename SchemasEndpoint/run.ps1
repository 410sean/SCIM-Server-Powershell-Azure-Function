using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


$status = [HttpStatusCode]::OK

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
  foreach ($targetschema in $Schemas){
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
    Body = $schema
})

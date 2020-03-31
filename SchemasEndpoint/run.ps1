using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Schemas, $schemaAttributes)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
function new-scimSchemaAttribute ($prop){
  $attributeTemplate=[pscustomobject]@{
    name=[string]$prop.name
    type=$prop.type
  }
  if ($prop.multiValued){$attributeTemplate | add-member -notepropertyname multiValued -NotePropertyValue $prop.multiValued}
  if ($prop.description){$attributeTemplate| add-member -notepropertyname description -NotePropertyValue $prop.description}
  if ($prop.required){$attributeTemplate | add-member -notepropertyname required -NotePropertyValue $prop.required}
  if ($prop.caseExact){$attributeTemplate | add-member -notepropertyname caseExact -NotePropertyValue $prop.caseExact}
  if ($prop.mutability){$attributeTemplate | add-member -notepropertyname mutability -NotePropertyValue $prop.mutability}
  if ($prop.returned){$attributeTemplate | add-member -notepropertyname returned -NotePropertyValue $prop.returned}
  if ($prop.uniqueness){$attributeTemplate | add-member -notepropertyname uniqueness -NotePropertyValue $prop.uniqueness}
  if ($prop.referencetypes){$attributeTemplate | add-member -notepropertyname referenceTypes -NotePropertyValue $prop.referecetypes}
  return $attributeTemplate  
}
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
    $psbody.attributes+=new-scimSchemaAttribute $attr
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
    $attributes=@()
    foreach ($attr in $targetattributes){
      $attributes+=new-scimSchemaAttribute $attr
    }
    $schemabody.attributes=@($attributes)
    $resources+=$schemabody
  }
  $psbody.totalResults=$resources.count
  $psbody.resources=@($resources)
}
write-host ($status | convertto-json -depth 10) 
write-host ($psbody | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $psbody | convertto-json -depth 10
})

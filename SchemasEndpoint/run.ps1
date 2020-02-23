using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

if ($name) {
    $status = [HttpStatusCode]::OK
    $body = "Hello $name"
}
else {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass a name on the query string or in the request body."
}
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
          "description": "the job code o the user",
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

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

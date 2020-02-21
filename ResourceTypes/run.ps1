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
        "schemas": [
          "urn:ietf:params:scim:schemas:core:2.0:ResourceType"
        ],
        "name": "User",
        "description": "Front teammate account",
        "endpoint": "/Users",
        "schema": "urn:ietf:params:scim:schemas:core:2.0:User",
        "meta": {
          "resourceType": "ResourceType",
          "location": "https://scim.frontapp.com/ResourceTypes/User"
        }
      }
    ]
  }'
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

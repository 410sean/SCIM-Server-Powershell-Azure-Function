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
    "schemas": [
      "urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"
    ],
    "documentation": "https://documenter.getpostman.com/view/1614368/RVfsHZ6o",
    "patch": {
      "supported": false
    },
    "bulk": {
      "supported": false,
      "maxOperations": 0,
      "maxPayloadSize": 0
    },
    "filter": {
      "supported": true,
      "maxResults": 100
    },
    "changePassword": {
      "supported": false
    },
    "sort": {
      "supported": true
    },
    "etag": {
      "supported": false
    },
    "authenticationSchemes": [
      {
        "type": "oauthbearertoken",
        "name": "OAuth Bearer Token",
        "description": "Authentication scheme using the OAuth Bearer Token Standard",
        "specUri": "https://www.rfc-editor.org/info/rfc6750"
      }
    ],
    "meta": {
      "resourceType": "ServiceProviderConfig",
      "location": "https://scimps.azurewebsites.net/api//ServiceProviderConfig"
    }
  }'
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

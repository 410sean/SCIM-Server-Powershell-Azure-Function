using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $inputTable)
<#GET for retrieval of resources; POST for creation,
searching, and bulk modification; PUT for attribute replacement
within resources; PATCH for partial update of attributes; and DELETE
for removing resources#>
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

if ($name) {
    $status = [HttpStatusCode]::OK
    $body=$Request
}
else {
    switch($Request.method){
        "GET"{
            if ($Request.params.path){
                $body=$inputTable
            }else{
                #get all users (pagination)
                $body=$inputTable
            }
        }
        "POST"{
            #create user
            Push-OutputBinding -Name outputTable -Value ({
                $Request.body
            })
        }
        "PATCH"{
            #updte user
            Push-OutputBinding -Name outputTable -Value ({
                $Request.body
            })
        }
        "PUT"{
            #update user
            Push-OutputBinding -Name outputTable -Value ({
                $Request.body
            })
        }
        "DELETE"{
            #remove user
        }




    }
    
    
    
    
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass a name on the query string or in the request body."
}



$status = [HttpStatusCode]::OK
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

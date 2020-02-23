using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $inputTable)
<#GET for retrieval of resources; POST for creation,
searching, and bulk modification; PUT for attribute replacement
within resources; PATCH for partial update of attributes; and DELETE
for removing resources#>
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
$schema="userName,displayName,companyCode,departmentCode,BusinessUnitCode,jobCode,role,active"
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
    $body = "Please pass a name on the query string or in the request body."
    switch($Request.method){
        "GET"{
            if ($Request.params.path){
                $body=$inputTable | where-object{$_.username -eq $Request.params.path} | Select-Object $schema
            }else{
                #get all users (pagination)
                $body=$inputTable | Select-Object $schema
            }
        }
        "POST"{
            #create user
            Push-OutputBinding -Name outputTable -Value ({
                $Request.body
            })
            $body = 'TODO: create user code here'
        }
        "PATCH"{
            #updte user
            Push-OutputBinding -Name outputTable -Value ({
                $Request.body
            })
            $body = 'TODO: update user code here'
        }
        "PUT"{
            #update user
            Push-OutputBinding -Name outputTable -Value ({
                $Request.body
            })
            $body = 'TODO: update user code here'
        }
        "DELETE"{
            #remove user
            $body = 'TODO: delete user code here'
        }




    }
    
    
    
    
    $status = [HttpStatusCode]::BadRequest
    #$body = "Please pass a name on the query string or in the request body."
}



$status = [HttpStatusCode]::OK
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

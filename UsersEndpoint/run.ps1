using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $inputTable)
<#GET for retrieval of resources; POST for creation,
searching, and bulk modification; PUT for attribute replacement
within resources; PATCH for partial update of attributes; and DELETE
for removing resources#>
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
$schema=@('id','userName','displayName','companyCode','departmentCode','BusinessUnitCode','jobCode','location','domainID','EmployeeClass','PLMS','role','active')
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
                $body=@(Get-Content $inputTable -Raw | ConvertFrom-Json) | where-object{$_.username -eq $Request.params.path} | Select-Object $schema
            }else{
                #get all users (pagination)
                $body=Get-Content $inputTable -Raw | ConvertFrom-Json
            }
        }
        "POST"{
            #create user
            $json=$Request.body | convertfrom-json
            $id=new-guid
            $newuser=[pscustomobject]@{
                id               = $id.guid
                RowKey           = $id.guid
                userName         = $json.username
                displayName      = $json.displayName
                companyCode      = $json.companyCode
                departmentCode   = $json.departmentCode
                BusinessUnitCode = $json.BusinessUnitCode
                jobCode          = $json.jobCode
                location         = $json.location
                domainID         = $json.domainID
                EmployeeClass    = $json.EmployeeClass
                active           = $json.active
            }
            $uri='https://prod-47.eastus.logic.azure.com:443/workflows/afb52f3ed8214ba5b28cfb640d1579db/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=KpJ5oxfHH8JdexxSB1eL_rU8QYw1sOOcqVVGY3vIcL8'
            $result=Invoke-RestMethod -uri $uri -Method post -body ($newuser | convertto-json) -UseBasicParsing
            $newuser | add-member -NotePropertyName role -NotePropertyValue $result.appRole.role
            $newuser | Add-member -NotePropertyName 'PLMS' -NotePropertyValue $result.plms
            $newuser | ConvertTo-Json | Out-File -Encoding UTF8 $outputTable
            $body=$newuser
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
            $body=Push-OutputBinding -Name outputTable -Value ({
                $Request.body
            })
            
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

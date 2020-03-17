# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.
if ($env:MSI_SECRET -and (Get-Module -ListAvailable Az.Accounts)) {
    Connect-AzAccount -Identity
}

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.
function new-scimItem ($schema, $properties, $location, [switch]$includeMeta){
    #will create item starting with schema and ending with meta
    #nested properties should have a property name that can be split by underscore '_'
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
    if ($includemeta){
        $meta=[pscustomobject]@{
            resourceType=$schema
            location="$location"
        }
        $psitem | add-member -notepropertyname 'meta' -notepropertyvalue $meta
    }
    return $psitem
  }
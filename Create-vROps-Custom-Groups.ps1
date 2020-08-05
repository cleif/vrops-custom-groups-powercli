<#	
	.NOTES
	===========================================================================
	 Created with: 	Powershell Core
	 Created on:   	02/07/2020
	 Created by:   	leifc
	 Organization: 	[]
	 Filename:     	Create-vROps-Custom-Groups.ps1
	===========================================================================
	.DESCRIPTION
		Creates custom vROps groups based off Application ID Tags
#>
#...Get Array List of Tags in vSphere..
$vSphereTagsList = New-Object System.Collections.ArrayList
Connect-VIServer []
$vSphereTagsList = Get-Tag -Category "[]"

#Testing
#$vSphereTagsList = Get-Tag [],[] #-Category "[]"
# ---------------------------------------------------------- START Authentication/Authorization ------------------------------------------------------------------------#

#...Generate new Token...
$Authheaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Authheaders.Add("Content-Type", "application/json")
$Authheaders.Add("Accept", "application/json")

$Authbody = @"
{
    "username": "savropsapi",
    "password": "[]"
}
"@
$response = Invoke-RestMethod 'https://[]/suite-api/api/auth/token/acquire' -Method 'POST' -Headers $Authheaders -Body $Authbody
$token = $response.token
# ---------------------------------------------------------- END Authentication/Authorization --------------------------------------------------------------------------#

# ---------------------------------------------------------- START Group Creation --------------------------------------------------------------------------------------#

#...Static Header to pass with Token...
$Groupheaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Groupheaders.Add("Content-Type", "application/json")
$Groupheaders.Add("Authorization", "vRealizeOpsToken $token")
$Groupheaders.Add("Accept", "application/json")

#...Loop thru the Tag list with custom JSON payload body per tag...
foreach($tag in $vSphereTagsList){
    #..do the work.
    $tagName = $tag.Name
    $TagDesc = $tag.Description

    $UniqueGroupbody = @"
    {
        "resourceKey": {
            "name": "$tagName - $TagDesc",
            "adapterKindKey": "Container",
            "resourceKindKey": "Environment"
        },
        "autoResolveMembership": "true",
        "membershipDefinition": {
            "rules": [{
                "resourceKindKey": {
                    "resourceKind": "VirtualMachine",
                    "adapterKind": "VMWARE"
                },
                "propertyConditionRules": [{
                    "key": "summary|tag",
                    "stringValue": "$tagName",
                    "compareOperator": "CONTAINS"
                }]
            }]
        }
    }
"@
    
    #...POST RestMethod response of current tag item... 200 == OK
    $response = Invoke-RestMethod 'https://[]/suite-api/api/resources/groups' -Method 'POST' -Headers $Groupheaders -Body $UniqueGroupbody
    Write-Host  $response.resourceKey.name "Created successfully" -ForegroundColor Green
}

# ---------------------------------------------------------- END Group Creation ----------------------------------------------------------------------------------------#


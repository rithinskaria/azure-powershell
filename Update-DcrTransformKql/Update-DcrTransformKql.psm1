<#
.SYNOPSIS
    Updates a Data Collection Rule (DCR) in Azure with new Stream and Kql transformation settings.

.DESCRIPTION
    The Update-DcrTransformKql function is used to update an existing Data Collection Rule in Azure.
    It allows adding a Kql (Kusto Query Language) transformation and an output Stream to a specified DCR.
    The function fetches the current configuration of a DCR, modifies it according to the inputs provided,
    and updates the DCR in Azure.

.PARAMETER DcrId
    The ID of the Data Collection Rule to be updated. It should be in the format:
    '/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/microsoft.insights/datacollectionrules/{ruleName}'.

.PARAMETER Path
    The file path where the current configuration of the DCR will be stored and modified.
    This should be a valid path on the local file system where the script is running.

.PARAMETER Kql
    The Kql transformation to be added to the DCR. This should be a valid Kql statement.

.PARAMETER Stream
    The name of the Stream to be updated in the DCR. Typically, this is 'Microsoft-Event'.

.EXAMPLE
    Update-DcrTransformKql `
            -DcrId "/subscriptions/22ba2-11ac11-0ee000-aedef001/resourcegroups/rg-demo/providers/microsoft.insights/datacollectionrules/demo-dcr" `
            -Path "C:\dcr.json" `
            -Kql "source `n| extend IgnoreFlag3_CF = iff (Computer contains 'demo' and RenderedDescription == 'SL query done','Ignore','DoNotIgnore') `n| where IgnoreFlag_CF != 'Ignore' `n" `
            -Stream "Microsoft-Event"

    This example updates the Data Collection Rule identified by the given DcrId, adding a Kql transformation and specifying the Stream.

.NOTES
    Author: Rithin Skaria
    Version: 1.0
    Required Modules: Az

.LINK
    https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/data-collection-rule-azure-monitor

#>

function Update-DcrTransformKql {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DcrId,

        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Kql,

        [Parameter(Mandatory=$true)]
        [string]$Stream
    )

    # Extract DCR
    $getDcr = Invoke-AzRestMethod -Path ("$DcrId"+"?api-version=2022-06-01") -Method GET
    $getDcr.Content | ConvertFrom-Json | ConvertTo-Json -Depth 20 | Out-File -FilePath $Path
    Copy-Item $Path "$Path-bkp"
    Write-Output "Update $DcrId with KQL: $kql"

    # File Modification
    $jsonContent = Get-Content -Path $Path | ConvertFrom-Json
    foreach ($dataFlow in $jsonContent.properties.dataFlows) {
        if ($dataFlow.streams -contains $Stream) {
            $dataFlow | Add-Member -NotePropertyName "transformKql" -NotePropertyValue $Kql
            $dataFlow | Add-Member -NotePropertyName "outputStream" -NotePropertyValue $Stream
        }
    }
    $jsonString = $jsonContent | ConvertTo-Json -Depth 10
    $jsonString | Set-Content -Path $Path

    # Update DCR
    $patch = Get-Content $Path -Raw
    Invoke-AzRestMethod -Path ("$DcrId"+"?api-version=2022-06-01") -Method PUT -Payload $patch
}


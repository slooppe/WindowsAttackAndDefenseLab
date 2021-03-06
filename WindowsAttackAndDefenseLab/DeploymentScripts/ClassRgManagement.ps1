Import-Module AzureRM
  
workflow Remove-AllAzureRmResourceGroups {
  
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)]
    [pscredential]$Credentials
  )

  $username = $credentials.UserName.ToString()
  Write-Output "Logging in as $username"
  
  Add-AzureRmAccount -Credential $credentials
  $resourceGroups = Get-AzureRmResourceGroup -ErrorAction Stop
 
  if ($resourceGroups.Count -gt 0) {
    forEach -parallel -throttle 30 ($resourceGroup in $resourceGroups) {
        $resourceGroupName = $resourceGroup.ResourceGroupName.toString()
        if ($resourceGroupName -notlike "*master" -and $resourceGroupName -notlike "cupcake*" -and $resourceGroupName -notlike "jah*") {
            $conn = Add-AzureRmAccount -Credential $credentials
            Write-Output "[*] Removing $resourceGroupName.."
            Remove-AzureRmResourceGroup -Name $resourceGroupName -Force
        }
    }
  }
  else {
    Write-Output "No Resource Groups Found"
  }

}
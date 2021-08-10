#Load balancing demo infra

#Note: LB is not deployed with this script, this is just for setting up the infrastructure. LB needs to be deployed separately

cls
#Variables
$rg = "az-lb-rg"
$region = "eastus"
$username = "rithin" #username for the VM
$plainPassword = "VMP@55w0rd" #your VM password
$VMSize = "Standard_B1s"

#Creating VM credential; use your own password and username by changing the variables
$password = ConvertTo-SecureString $plainPassword -AsPlainText -Force


#Create RG
New-AzResourceGroup -n $rg -l $region

#########-----Create resources---------######

#Creating vnet

Write-Host "Adding subnet configuration" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$jumpBox = New-AzVirtualNetworkSubnetConfig `
  -Name 'jumpboxSubnet' `
  -AddressPrefix 10.0.1.0/24
 
$workload = New-AzVirtualNetworkSubnetConfig `
  -Name 'webSubnet' `
  -AddressPrefix 10.0.2.0/24

Write-Host "Creating vnet-01" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $rg `
  -Location $region `
  -Name "vnet-01" `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $jumpBox, $workload


Write-Host "Creating availability set" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$avSet = New-AzAvailabilitySet -ResourceGroupName $rg -Name "webAvailabilitySet" `
-Location $region -PlatformUpdateDomainCount 5 `
-PlatformFaultDomainCount 3 -Sku "Aligned"

for($i=1; $i -le 3; $i++){

    $workloadNIC = New-AzNetworkInterface -Name "web-0$i-nic" -ResourceGroupName $rg `
    -Location $region -SubnetId $vnet.Subnets[1].Id

    Write-Host "----------------------------------------------------" `
    -ForegroundColor "Yellow" -BackgroundColor "Black"

    $credential = New-Object System.Management.Automation.PSCredential ($username, $password);

    Write-Host "Setting VM config" -ForegroundColor "Yellow" -BackgroundColor "Black"

    $VirtualMachine = New-AzVMConfig -VMName "web-0$i" -VMSize $VMSize -AvailabilitySetId $avSet.Id

    Write-Host "Setting OS Profile" -ForegroundColor "Yellow" -BackgroundColor "Black"

    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine `
    -Linux -ComputerName "web0$i" -Credential $credential

    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $workloadNIC.Id

    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine `
    -PublisherName 'Canonical' `
    -Offer 'UbuntuServer' `
    -Skus '18.04-LTS' `
    -Version latest

    Write-Host "Creating VM web-0$i" -ForegroundColor "Yellow" -BackgroundColor "Black"
    New-AzVM -ResourceGroupName $rg -Location $region -VM $VirtualMachine

}

 
Write-Host "Creating jumpbox VM" -ForegroundColor "Yellow" -BackgroundColor "Black"
$jumpVm = New-AzVM -Name jumpbox-vm `
-ResourceGroupName $rg `
-Location $region `
-Size 'Standard_B1s' `
-Image UbuntuLTS `
-VirtualNetworkName vnet-01 `
-SubnetName jumpboxSubnet `
-Credential $credential 

Write-Host "Deployment Completed!!" -BackgroundColor Yellow -ForegroundColor White 

$fqdn = $jumpVm.FullyQualifiedDomainName
Write-Host "Jumpbox VM DNS name : $fqdn "
for ($i=1; $i -le 3; $i++){

    $vmIP= (Get-AzNetworkInterface -Name "web-0$i-nic").IpConfigurations.PrivateIPAddress
    Write-Host "Private IP (web-0$i) :$vmIP"

}

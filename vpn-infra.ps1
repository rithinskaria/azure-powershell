#Peering demo script
cls
#Variables
$rg = "vpn-demo-rg"
$region1 = "eastus"
$region2 = "westus"
$username = "johndoe" #username for the VM
$plainPassword = "VMP@55w0rd" #your VM password
$VMSize = "Standard_B1s"

#Creating VM credential; use your own password and username by changing the variables
$password = ConvertTo-SecureString $plainPassword -AsPlainText -Force


#Create RG
New-AzResourceGroup -n $rg -l $region1

#########-----Create EUS resources---------######

#Creating vnet-01

Write-Host "Adding subnet configuration" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$jumpBox = New-AzVirtualNetworkSubnetConfig `
  -Name 'jumpboxSubnet' `
  -AddressPrefix 10.0.1.0/24
 
$workload = New-AzVirtualNetworkSubnetConfig `
  -Name 'workloadSubnet' `
  -AddressPrefix 10.0.2.0/24

$gateway = New-AzVirtualNetworkSubnetConfig `
 -Name 'GatewaySubnet' `
 -AddressPrefix 10.0.0.0/28

Write-Host "Creating vnet-01" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $rg `
  -Location $region1 `
  -Name "vnet-01" `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $jumpBox, $workload, $gateway

$workloadNIC = New-AzNetworkInterface -Name "vm-01-nic" -ResourceGroupName $rg `
-Location $region1 -SubnetId $vnet.Subnets[1].Id

Write-Host "----------------------------------------------------" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$credential = New-Object System.Management.Automation.PSCredential ($username, $password);

Write-Host "Setting VM config" -ForegroundColor "Yellow" -BackgroundColor "Black"

$VirtualMachine = New-AzVMConfig -VMName "vm-01" -VMSize $VMSize

Write-Host "Setting OS Profile" -ForegroundColor "Yellow" -BackgroundColor "Black"

$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine `
-Linux -ComputerName "vm01" -Credential $credential

$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $workloadNIC.Id

$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine `
-PublisherName 'Canonical' `
-Offer 'UbuntuServer' `
-Skus '18.04-LTS' `
-Version latest

Write-Host "Creating VM vm-01" -ForegroundColor "Yellow" -BackgroundColor "Black"
New-AzVM -ResourceGroupName $rg -Location $region1 -VM $VirtualMachine 

Write-Host "Creating jumpbox VM" -ForegroundColor "Yellow" -BackgroundColor "Black"
$jumpVm = New-AzVM -Name jumpbox-vm `
-ResourceGroupName $rg `
-Location $region1 `
-Size 'Standard_B1s' `
-Image UbuntuLTS `
-VirtualNetworkName vnet-01 `
-SubnetName jumpboxSubnet `
-Credential $credential 


#########-----Create WUS resources---------######

#Creating vnet-02

Write-Host "Adding subnet configuration" `
-ForegroundColor "Yellow" -BackgroundColor "Black"
 
$workload = New-AzVirtualNetworkSubnetConfig `
  -Name 'workloadSubnet' `
  -AddressPrefix 10.1.1.0/24

$gateway = New-AzVirtualNetworkSubnetConfig `
 -Name 'GatewaySubnet' `
 -AddressPrefix 10.1.0.0/28

Write-Host "Creating vnet-02" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $rg `
  -Location $region2 `
  -Name "vnet-02" `
  -AddressPrefix 10.1.0.0/16 `
  -Subnet $workload, $gateway


$workloadNIC = New-AzNetworkInterface -Name "vm-02-nic" -ResourceGroupName $rg `
-Location $region2 -SubnetId $vnet.Subnets[0].Id

Write-Host "----------------------------------------------------" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$credential = New-Object System.Management.Automation.PSCredential ($username, $password);

Write-Host "Setting VM config" -ForegroundColor "Yellow" -BackgroundColor "Black"

$VirtualMachine = New-AzVMConfig -VMName "vm-02" -VMSize $VMSize

Write-Host "Setting OS Profile" -ForegroundColor "Yellow" -BackgroundColor "Black"

$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine `
-Linux -ComputerName "vm02" -Credential $credential

$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $workloadNIC.Id

$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine `
-PublisherName 'Canonical' `
-Offer 'UbuntuServer' `
-Skus '18.04-LTS' `
-Version latest

Write-Host "Creating VM vm-02" -ForegroundColor "Yellow" -BackgroundColor "Black"

New-AzVM -ResourceGroupName $rg -Location $region2 -VM $VirtualMachine 

$fqdn = $jumpVm.FullyQualifiedDomainName
$vm01IP= (Get-AzNetworkInterface -Name "vm-01-nic").IpConfigurations.PrivateIPAddress
$vm02IP = (Get-AzNetworkInterface -Name "vm-02-nic").IpConfigurations.PrivateIPAddress


Write-Host "Deployment Completed!!" -BackgroundColor Yellow -ForegroundColor White 

Write-Host `
"Output:
 
Jumpbox VM DNS name : $fqdn  
Private IP (vm-01) :$vm01IP 
Private IP (vm-02) :$vm02IP" `
 -BackgroundColor DarkGreen -ForegroundColor White



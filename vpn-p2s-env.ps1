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


#Create VPN gateway

$gwpip= New-AzPublicIpAddress `
-Name pip-vpn-eus `
-ResourceGroupName vpn-demo-rg `
-Location 'East US' `
-AllocationMethod Dynamic

$vnet = Get-AzVirtualNetwork `
-Name vnet-01 `
-ResourceGroupName 'vpn-demo-rg'

$subnet = Get-AzVirtualNetworkSubnetConfig `
-Name 'GatewaySubnet' `
-VirtualNetwork $vnet

$gwipconfig = New-AzVirtualNetworkGatewayIpConfig `
-Name vpn-eus `
-SubnetId $subnet.Id `
-PublicIpAddressId $gwpip.Id

New-AzVirtualNetworkGateway `
-Name vpn-eus `
-ResourceGroupName vpn-demo-rg `
-Location 'East US' `
-IpConfigurations $gwipconfig `
-GatewayType Vpn `
-VpnType RouteBased `
-GatewaySku VpnGw1


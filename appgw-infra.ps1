#Application Gateway Demo Infra - v1.0, written by Rithin Skaria
cls
#Variables
$rg = "az-lb-rg3"
$region = "eastus"
$username = "rithin" #username for the VM
$plainPassword = "VMP@55w0rd" #your VM password
$VMSize = "Standard_B1s"

#Creating VM credential; use your own password and username by changing the variables
$password = ConvertTo-SecureString $plainPassword -AsPlainText -Force

Write-Host "Application Gateway Demo Infra - v1.0, written by Rithin Skaria" `
-ForegroundColor "Red" -BackgroundColor "White"

#Create RG
New-AzResourceGroup -n $rg -l $region

#########-----Create resources---------######

#Creating vnet

Write-Host "Adding subnet configuration" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$jumpBox = New-AzVirtualNetworkSubnetConfig `
  -Name 'jumpboxSubnet' `
  -AddressPrefix 10.0.0.0/24
 
$workload1 = New-AzVirtualNetworkSubnetConfig `
  -Name 'helloSubnet' `
  -AddressPrefix 10.0.1.0/24
   
$workload2 = New-AzVirtualNetworkSubnetConfig `
  -Name 'byeSubnet' `
  -AddressPrefix 10.0.2.0/24

Write-Host "Creating vnet-01" `
-ForegroundColor "Yellow" -BackgroundColor "Black"

$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $rg `
  -Location $region `
  -Name "vnet-01" `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $jumpBox, $workload1, $workload2

#---------------------------------------------------#

#-------------------NSG--------------------------------#

$webRule = New-AzNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" -Access Allow `
    -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 80

$networkSecurityGroup = New-AzNetworkSecurityGroup -ResourceGroupName $rg `
-Location $region -Name "appGwNSG" -SecurityRules $rdpRule

Set-AzVirtualNetworkSubnetConfig -Name helloSubnet -VirtualNetwork $vnet -AddressPrefix "10.0.1.0/24" `
-NetworkSecurityGroup $networkSecurityGroup

Set-AzVirtualNetworkSubnetConfig -Name byeSubnet -VirtualNetwork $vnet -AddressPrefix "10.0.2.0/24" `
-NetworkSecurityGroup $networkSecurityGroup

$vnet | Set-AzVirtualNetwork

#---------------------------------------------------#

#---------------------Hello Pool Servers------------------------------#

for($i=1; $i -le 3; $i++){

    $workloadNIC = New-AzNetworkInterface -Name "hello-0$i-nic" -ResourceGroupName $rg `
    -Location $region -SubnetId $vnet.Subnets[1].Id

    Write-Host "----------------------------------------------------" `
    -ForegroundColor "Yellow" -BackgroundColor "Black"

    $credential = New-Object System.Management.Automation.PSCredential ($username, $password);

    Write-Host "Setting VM config" -ForegroundColor "Yellow" -BackgroundColor "Black"

    $VirtualMachine = New-AzVMConfig -VMName "hello-0$i" -VMSize $VMSize 

    Write-Host "Setting OS Profile" -ForegroundColor "Yellow" -BackgroundColor "Black"

    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine `
    -Linux -ComputerName "hello0$i" -Credential $credential

    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $workloadNIC.Id

    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine `
    -PublisherName 'Canonical' `
    -Offer 'UbuntuServer' `
    -Skus '18.04-LTS' `
    -Version latest

    Write-Host "Creating VM hello-0$i" -ForegroundColor "Yellow" -BackgroundColor "Black"
    New-AzVM -ResourceGroupName $rg -Location $region -VM $VirtualMachine

}

#---------------------------------------------------#

#---------------------Bye Pool Servers------------------------------#

for($i=1; $i -le 3; $i++){

    $workloadNIC = New-AzNetworkInterface -Name "bye-0$i-nic" -ResourceGroupName $rg `
    -Location $region -SubnetId $vnet.Subnets[2].Id

    Write-Host "----------------------------------------------------" `
    -ForegroundColor "Yellow" -BackgroundColor "Black"

    $credential = New-Object System.Management.Automation.PSCredential ($username, $password);

    Write-Host "Setting VM config" -ForegroundColor "Yellow" -BackgroundColor "Black"

    $VirtualMachine = New-AzVMConfig -VMName "bye-0$i" -VMSize $VMSize 

    Write-Host "Setting OS Profile" -ForegroundColor "Yellow" -BackgroundColor "Black"

    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine `
    -Linux -ComputerName "bye0$i" -Credential $credential

    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $workloadNIC.Id

    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine `
    -PublisherName 'Canonical' `
    -Offer 'UbuntuServer' `
    -Skus '18.04-LTS' `
    -Version latest

    Write-Host "Creating VM bye-0$i" -ForegroundColor "Yellow" -BackgroundColor "Black"
    New-AzVM -ResourceGroupName $rg -Location $region -VM $VirtualMachine

}



#---------------------------------------------------#

#---------------------Jumpbox------------------------------#
 
Write-Host "Creating jumpbox VM" -ForegroundColor "Yellow" -BackgroundColor "Black"
$jumpVm = New-AzVM -Name jumpbox-vm `
-ResourceGroupName $rg `
-Location $region `
-Size 'Standard_B1s' `
-Image UbuntuLTS `
-VirtualNetworkName vnet-01 `
-SubnetName jumpboxSubnet `
-Credential $credential 

#---------------------------------------------------#

#---------------------Output------------------------------#

Write-Host "Deployment Completed!!" -BackgroundColor Yellow -ForegroundColor White 

$fqdn = $jumpVm.FullyQualifiedDomainName
Write-Host "Jumpbox VM DNS name : $fqdn "
for ($i=1; $i -le 3; $i++){

    $vmIP= (Get-AzNetworkInterface -Name "hello-0$i-nic").IpConfigurations.PrivateIPAddress
    Write-Host "Private IP (hello-0$i) :$vmIP"

}
for ($i=1; $i -le 3; $i++){

    $vmIP= (Get-AzNetworkInterface -Name "bye-0$i-nic").IpConfigurations.PrivateIPAddress
    Write-Host "Private IP (bye-0$i) :$vmIP"

}

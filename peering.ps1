#Peering demo script
cls
#Variables
$rg = "peering-rg"
$region1 = "eastus"
$region2 = "westus"
$username = "<username>" #enter username for VM
$plainPassword = "<password>" #enter password for VM
$VMSize = "Standard_B1s"

#Creating VM credential; use your own password and username by changing the variables
$password = ConvertTo-SecureString $plainPassword -AsPlainText -Force


#Create RG
New-AzResourceGroup -n $rg -l $region1

#########-----Create EUS resources---------######

#Creating vnet-01

Write-Host "Adding subnet configuration" -ForegroundColor "Yellow" -BackgroundColor "Black"
$subnet = New-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix 172.16.0.0/24
Write-Host "Creating Virtual Network vnet-01" -ForegroundColor "Yellow" -BackgroundColor "Black"
$Vnet = New-AzVirtualNetwork -Name "vnet-01" -ResourceGroupName $rg -Location $region1 -AddressPrefix 172.16.0.0/16 -Subnet $subnet
Write-Host "Adding NIC " -ForegroundColor "Yellow" -BackgroundColor "Black"
$NIC = New-AzNetworkInterface -Name "vm-01-nic" -ResourceGroupName $rg -Location $region1 -SubnetId $Vnet.Subnets[0].Id

#Creating vm-01
Write-Host "----------------------------------------------------" -ForegroundColor "Yellow" -BackgroundColor "Black"
$credential = New-Object System.Management.Automation.PSCredential ($username, $password);
Write-Host "Setting VM config" -ForegroundColor "Yellow" -BackgroundColor "Black"
$VirtualMachine = New-AzVMConfig -VMName "vm-01" -VMSize $VMSize
Write-Host "Setting OS Profile" -ForegroundColor "Yellow" -BackgroundColor "Black"
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName "vm01" -Credential $credential
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '18.04-LTS' -Version latest
Write-Host "Creating VM vm-01" -ForegroundColor "Yellow" -BackgroundColor "Black"
New-AzVM -ResourceGroupName $rg -Location $region1 -VM $VirtualMachine 

#Creating jumpbox
Write-Host "Creating jumpbox VM" -ForegroundColor "Yellow" -BackgroundColor "Black"
New-AzVM -Name jumpbox-vm `
-ResourceGroupName $rg `
-Location $region1 `
-Size $VMSize `
-Image UbuntuLTS `
-VirtualNetworkName vnet-01 `
-SubnetName default `
-Credential $credential 


#########-----Create WUS resources---------######

#Creating vnet-02
Write-Host "Adding subnet configuration" -ForegroundColor "Yellow" -BackgroundColor "Black"
$subnet = New-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix 192.168.0.0/24
Write-Host "Creating Virtual Network vnet-02" -ForegroundColor "Yellow" -BackgroundColor "Black"
$Vnet = New-AzVirtualNetwork -Name "vnet-02" -ResourceGroupName $rg -Location $region2 -AddressPrefix 192.168.0.0/16 -Subnet $subnet
Write-Host "Adding NIC " -ForegroundColor "Yellow" -BackgroundColor "Black"
$NIC = New-AzNetworkInterface -Name "vm-02-nic" -ResourceGroupName $rg -Location $region2 -SubnetId $Vnet.Subnets[0].Id

#Creating vm-02
Write-Host "----------------------------------------------------" -ForegroundColor "Yellow" -BackgroundColor "Black"
$credential = New-Object System.Management.Automation.PSCredential ($username, $password);
$VirtualMachine = New-AzVMConfig -VMName "vm-02" -VMSize $VMSize
Write-Host "Setting VM config" -ForegroundColor "Yellow" -BackgroundColor "Black"
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName "vm02"-Credential $credential 
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
Write-Host "Setting OS Profile" -ForegroundColor "Yellow" -BackgroundColor "Black"
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '18.04-LTS' -Version latest
Write-Host "Creating VM vm-02" -ForegroundColor "Yellow" -BackgroundColor "Black"
New-AzVM -ResourceGroupName $rg `
-Location $region2 `
-VM $VirtualMachine

Write-Host "Deployment done!!" -ForegroundColor "Green" -BackgroundColor "Black"

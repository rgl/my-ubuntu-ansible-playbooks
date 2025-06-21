Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
  Write-Output "ERROR: $_"
  Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
  Write-Output (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
  Exit 1
}

# see https://www.powershellgallery.com/packages/VCF.PowerCLI
# see https://developer.broadcom.com/powercli
# see https://developer.broadcom.com/powercli/installation-guide
$powercliVersion = $env:POWERCLI_VERSION

# bail when already installed.
$module = Get-InstalledModule -ErrorAction SilentlyContinue VCF.PowerCLI
if ($module -and $module.Version -eq $powercliVersion) {
  Write-Output 'ANSIBLE CHANGED NO'
  Exit 0
}

# uninstall old VMware.* and VCF.* modules.
# see https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-9-0-and-later/9-0/administration-sdks-cli-and-tools/introduction-to-vmware-vsphere-powercli/installing-vmware-vsphere-powercli/uninstall-powercli.html
Write-Output 'Uninstalling the old VMware.* and VCF.* modules...'
rm -rf /usr/local/share/powershell/Modules/VMware.*
rm -rf /usr/local/share/powershell/Modules/VCF.*

Write-Output 'Installing the VCF.PowerCLI module...'
Install-Module -Force -Scope AllUsers `
  -Name VCF.PowerCLI `
  -RequiredVersion $powercliVersion

Write-Output 'Configuring the VCF.PowerCLI module...'
Set-PowerCLIConfiguration -Scope AllUsers `
  -ParticipateInCEIP $false `
  -Confirm:$false `
  | Out-Null

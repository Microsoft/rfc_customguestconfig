# Converting Group Policy to Azure Policy Guest Configuration

# PREPERATION

# Install required modules
# BaselineManagement maps to specific versions of other modules.  It needs to be updated.
Install-Module az.resources, az.policyinsights, az.storage, guestconfiguration, gpregistrypolicyparser, securitypolicydsc, auditpolicydsc, baselinemanagement -scope currentuser -Repository psgallery -AllowClobber

# Download 2019 baseline files
# https://docs.microsoft.com/en-us/windows/security/threat-protection/security-compliance-toolkit-10
mkdir 'C:\git\policyfiles\downloads'
Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/Windows%2010%20Version%201909%20and%20Windows%20Server%20Version%201909%20Security%20Baseline.zip' -Out C:\git\policyfiles\downloads\Server2019Baseline.zip

# Unblock and expand the downloaded file
Unblock-File C:\git\policyfiles\downloads\Server2019Baseline.zip
Expand-Archive -Path C:\git\policyfiles\downloads\Server2019Baseline.zip -DestinationPath C:\git\policyfiles\downloads\

# Show the content details
C:\git\policyfiles\downloads\Local_Script\Tools\MapGuidsToGpoNames.ps1 -rootdir C:\git\policyfiles\downloads\GPOs\ -Verbose

# RUN

# Convert GP to DSC
ConvertFrom-GPO -Path 'C:\git\policyfiles\downloads\GPOs\{3657C7A2-3FF3-4C21-9439-8FDF549F1D68}\' -OutputPath 'C:\git\policyfiles\' -OutputConfigurationScript -Verbose

# Compile configuration
Rename-Item -Path C:\git\policyfiles\DSCFromGPO.ps1 -NewName C:\git\policyfiles\Server2019Baseline.ps1
(Get-Content -Path C:\git\policyfiles\Server2019Baseline.ps1).Replace('DSCFromGPO', 'Server2019Baseline') | Set-Content -Path C:\git\policyfiles\Server2019Baseline.ps1
(Get-Content -Path C:\git\policyfiles\Server2019Baseline.ps1).Replace('PSDesiredStateConfiguration', 'PSDscResources') | Set-Content -Path C:\git\policyfiles\Server2019Baseline.ps1
C:\git\policyfiles\Server2019Baseline.ps1

# Create Policy content package
New-GuestConfigurationPackage -Name Server2019Baseline -Configuration c:\git\policyfiles\localhost.mof -DestinationPath C:\git\policyfiles\ -Verbose

# Uploaded file to blob and get SAS uri
c:\git\policyfiles\storageupload.ps1 -resourceGroup rfc_customguestconfig -storageAccountName guestconfiguration -storageContainerName content -filePath c:\git\policyfiles\Server2019Baseline\Server2019Baseline.zip -blobName Server2019Baseline.zip

# Create Policies
$ContentUri = 'paste_value_from_previous_step'
New-GuestConfigurationPolicy -ContentUri $ContentUri -DisplayName 'Server 2019 Configuration Baseline' -Description 'This is validation of using a completely custom baseline configuration for Windows VMs' -Version 1.0.0.0 -DestinationPath C:\git\policyfiles\policy -Platform Windows -Verbose

# Publish policies
Publish-GuestConfigurationPolicy -Path C:\git\policyfiles\policy\ -Verbose

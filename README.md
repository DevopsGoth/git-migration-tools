# git-migration-tools
Tools to migrate git environments around, currently this is a quick powershell script to move from Bitbucket to Azure Devops

## Pre-requisites
* git is installed and can be used from Powershell
* az cli tool and azure-devops extension are installed as below

Installing pre-req Azure tools
-----
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
    # restart powershell
    az extension add --name azure-devops

Running Migration
----
To migrate from a json file containing Bitbucket API output, run the script as follows, adjust values to your environment:

    ./Migrate-Bitbucket-to-AzureRepos.ps1 -organizationUri https://dev.azure.com/DevopsGoth/ -projectName "ado project" -jsonFile git_repos.json
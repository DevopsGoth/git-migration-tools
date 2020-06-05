param ($organizationUri, $projectName, $jsonFile)


function Migrate-Git{
    <#
    .SYNOPSIS
        Fetches all git repos from input and creates them in Azure Devops Repos
    .DESCRIPTION
        Currently designed to use a json file pulled from Bitbucket API, passed in manually.
        Incredibly non-robust and specific right now, designed for particular instance
    #>
    param($jsonfile)
    # optionally can put the part that pulls from Bitbucket directly here
    
    $json = Get-Content $jsonfile | Out-String | ConvertFrom-Json    
    $sourceRepos = $json[0].values | Sort-Object -Property id | Select-Object -ExpandProperty links | Select-Object -ExpandProperty clone | Where-Object 'name' -eq 'http' | Select-Object -ExpandProperty href
    
    $sourceRepos | ForEach-Object -Process {
        $repoFolder = $_.split("/")[-1]
        $repoName = $repoFolder.TrimEnd(".git")
        $azrepo = Create-AzureRepo -repoName $repoName
        # if it returns blank, the repo already exists, don't migrate this repository
        if ([string]::IsNullOrEmpty($azrepo)){
            Write-Host "WARNING: Repository $reponame already exists in ADO, skipping git migration"
        } else {
            git clone --mirror $_
            cd $repoFolder
            git push --mirror $azrepo
            cd ..
        }
    }
}

function Create-AzureRepo{
    # only create if it doesn't exist already
    param($repoName)
    $azrepo = az repos create --name $repoName --query 'remoteUrl'
    if ($azrepo -ccontains "TF400948") {
        $azrepo = ""
    }
    return $azrepo

}

function Initialize-az{
    param ($organizationURI, $projectName)
    Write-Host "Setting project defaults: organization=$organizationURI project=$projectName"

    Write-Host "Logging into Azure"
    az login
    Write-Host "Setting project defaults: organization=$organizationURI project=$projectName"
    az devops configure --defaults organization=$organizationURI project=$projectName
}

echo "$organizationUri $projectName $jsonFile"
Initialize-az -organizationURI $organizationUri -projectName $projectName
Migrate-Git -jsonfile $jsonFile
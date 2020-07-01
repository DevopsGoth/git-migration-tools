param ($organizationUri, $projectName, $jsonFile)


function Copy-Git{
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
        $repoName = $repoFolder.substring(0,$repoFolder.Length-4)
        Write-Host "Repo folder: $repoFolder cloning into repo name $repoName from url: $_"
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

function Add-AzureRepo{
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

    Write-Host "Logging into Azure DevOps; you will need to provide a Personal Access Token with git permissions"
    az devops login --organization $organizationURI
    Write-Host "Setting project defaults: organization=$organizationURI project=$projectName"
    az devops configure --defaults organization=$organizationURI project=$projectName
}

Initialize-az -organizationURI $organizationUri -projectName $projectName
Copy-Git -jsonfile $jsonFile
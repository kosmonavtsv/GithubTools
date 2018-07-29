$Script:GithubCollaborators = @()

function Get-GithubCollaborators {
    param (
        [Parameter(Mandatory=$false)]
        [string]$Repository,
        [string]$ApiKey,
        [switch]$Short
    )
    $repositories = Get-GithubRepositories -ApiKey $ApiKey
    if($Repository){
        $repositories = $repositories | Where-Object{$_.name -eq $Repository}
    }
    $collaborators = $repositories | ForEach-Object{_Get-GithubRepositoryCollaborators -Repository $_ -ApiKey $ApiKey} 
    if ($Short) {
        return $collaborators |Select-Object  @{N='Repository'; E={$_.Repository.name}},
            login, 
            @{N='Name';E={$_.FullInfo.name}}
    }
    else {
        return $collaborators
    }
}

function _Get-GithubRepositoryCollaborators {
    param (
        $Repository,
        [string]$ApiKey
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    $uri = "https://api.github.com/repos/$($Repository.owner.login)/$($Repository.name)/collaborators?access_token=$ApiKey"
    $collaborators = Invoke-RestMethod $uri
    foreach ($collaborator in $collaborators) {
        $collaboratorFull = $Script:GithubCollaborators | ?{$_.login -eq $collaborator.login}
        if(!$collaboratorFull){
            $collaboratorFull = Invoke-RestMethod "$($collaborator.url)?access_token=$ApiKey" 
            $Script:GithubCollaborators += $collaboratorFull
        }
        Add-Member -InputObject $collaborator -MemberType NoteProperty -Name FullInfo -Value $collaboratorFull
        Add-Member -InputObject $collaborator -MemberType NoteProperty -Name Repository -Value $Repository
    }
    return $collaborators
}

function Get-GithubRepositories {
    param (
        [string]$ApiKey
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.github.com/user/repos?access_token=$ApiKey"
    $repositories = Invoke-RestMethod $uri
    return $repositories
}
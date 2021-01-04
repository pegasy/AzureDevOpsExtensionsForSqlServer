[CmdletBinding()]
param()

<#
	.SYNOPSIS
    Processes a tabular cube database

	.DESCRIPTION
    Processes a tabular cube database on a SQL Server Analysis Services (SSAS) server

    Script written by (c) Dr. John Tunnicliffe, 2019 https://github.com/DrJohnT/AzureDevOpsExtensionsForSqlServer
	This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT

    Depends on PowerShell module DeployCube written by (c) Dr. John Tunnicliffe, 2019 https://github.com/DrJohnT/DeployCube
#>
    if (-not (Get-Module -Name "DeployCube")) {
        # if module is not loaded
        $ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path;
        $ModulePath = Resolve-Path "$ModulePath\ps_modules\DeployCube\DeployCube.psd1";
        Import-Module -Name $ModulePath;
    }

    [string]$AsServer = Get-VstsInput -Name AsServer -Require;
    [string]$CubeDatabaseName = Get-VstsInput -Name CubeDatabaseName;
    [string]$RefreshType = Get-VstsInput -Name RefreshType;
    [string]$UserID = Get-VstsInput -Name "UserID";
    [string]$Password = Get-VstsInput -Name "Password";

    $global:ErrorActionPreference = 'Stop';

    Trace-VstsEnteringInvocation $MyInvocation;

    Write-Host "AsServer:           $AsServer";
    Write-Host "CubeDatabaseName:   $CubeDatabaseName";
    Write-Host "RefreshType:        $RefreshType";
    Write-Host "UserID:             $UserID";

    Write-Host "==============================================================================";

    try {
        if ("" -eq "$Password") {
            Invoke-ProcessTabularCubeDatabase -Server $AsServer -CubeDatabase $CubeDatabaseName -RefreshType $RefreshType;
        } else {
            [SecureString] $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force;
            [PsCredential] $Credential = New-Object System.Management.Automation.PSCredential($UserID, $SecurePassword);
            Invoke-ProcessTabularCubeDatabase -Server $AsServer -CubeDatabase $CubeDatabaseName -RefreshType $RefreshType -Credential $Credential;
        }
    } finally {
        Write-Host "==============================================================================";
        Trace-VstsLeavingInvocation $MyInvocation
    }



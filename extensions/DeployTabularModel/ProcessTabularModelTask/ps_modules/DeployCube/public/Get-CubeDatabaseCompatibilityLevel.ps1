function Get-CubeDatabaseCompatibilityLevel {
<#
    .SYNOPSIS
    Gets the compatibility level of a deployed cube.

    .DESCRIPTION
    Returns the compatibility level of a deployed cube as an integer.

    .PARAMETER Server
    Name of the SSAS server, including instance and port if required.

    .PARAMETER CubeDatabase
    The name of the cube database to be deployed.
    
    .PARAMETER Credential
    [Optional] A PSCredential object containing the credentials to connect to the AAS server.

    .EXAMPLE
    Get-CubeDatabaseCompatibilityLevel -Server localhost -CubeDatabase MyTabularCube;

    Finds MyTabularCube on localhost and returns 1400

    .LINK
    https://github.com/DrJohnT/DeployCube

    .NOTES
    Written by (c) Dr. John Tunnicliffe, 2019-2021 https://github.com/DrJohnT/DeployCube
    This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT
#>
    [OutputType([int])]
    [CmdletBinding()]
    param
    (
        [String] [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Server,

        [String] [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CubeDatabase,

        [PSCredential] [Parameter(Mandatory = $false)]
        $Credential = $null
    )

    try {
        # ensure SqlServer module is installed
        Get-ModuleByName -Name SqlServer;

        # Request a list of databases on the SSAS server
        # Annoyingly, Invoke-ASCmd does not generate an error we can capture with try/catch. But it does write output to the error console,
        # so we have to redirect the error output to the normal output to stop the error been detected by processes monitoring the error output such as the Azure DevOps build pipeline
        if ($null -eq $Credential) {
            $returnResult = Invoke-ASCmd -Server $Server -ConnectionTimeout 1 -Query "<Discover xmlns='urn:schemas-microsoft-com:xml-analysis'><RequestType>DBSCHEMA_CATALOGS</RequestType><Restrictions /><Properties /></Discover>" 2>&1;
         } else {
            $returnResult = Invoke-ASCmd -Server $Server -Credential $Credential -ConnectionTimeout 1 -Query "<Discover xmlns='urn:schemas-microsoft-com:xml-analysis'><RequestType>DBSCHEMA_CATALOGS</RequestType><Restrictions /><Properties /></Discover>" 2>&1;
        }

        if ([string]::IsNullOrEmpty($returnResult)) {
            throw "Invoke-ASCmd failed to return a list of databases on the server $Server";
        } else {
            $returnXml = New-Object -TypeName System.Xml.XmlDocument;
            $returnXml.LoadXml($returnResult);

            [System.Xml.XmlNamespaceManager] $nsmgr = $returnXml.NameTable;
            $nsmgr.AddNamespace('xmlAnalysis', 	'urn:schemas-microsoft-com:xml-analysis');
            $nsmgr.AddNamespace('rootNS', 		'urn:schemas-microsoft-com:xml-analysis:rowset');

            $rows = $returnXML.SelectNodes("//xmlAnalysis:return/rootNS:root/rootNS:row", $nsmgr) ;
            foreach ($row in $rows) {                
                if ($row.DATABASE_ID -eq $CubeDatabase) {
                    return $row.COMPATIBILITY_LEVEL -as [int];
                }
            }
            throw "Failed to find cube database $CubeDatabase on server $Server";
        }
    } 
    catch {
        throw "SSAS Server $Server not found $error";
    }
}

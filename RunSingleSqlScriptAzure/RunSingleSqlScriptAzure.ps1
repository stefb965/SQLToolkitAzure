﻿[CmdletBinding(DefaultParameterSetName = 'None')]
Param
(
	[String] [Parameter(Mandatory = $true)] $ConnectedServiceNameSelector,
	[String] $ConnectedServiceName,
	[String] $ConnectedServiceNameARM,
	[String] [Parameter(Mandatory = $true)] $sqlScript,
	[String] [Parameter(Mandatory = $true)] $serverName,
	[String] [Parameter(Mandatory = $true)] $databaseName,
	[String] [Parameter(Mandatory = $true)] $userName,
	[String] [Parameter(Mandatory = $true)] $userPassword,
	[String] [Parameter(Mandatory = $true)] $queryTimeout
)

[string]$batchDelimiter = "[gG][oO]"

Add-PSSnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue
Add-PSSnapin SqlServerProviderSnapin100 -ErrorAction SilentlyContinue

Try
{
		
	#Execute the query
	Write-Host "Running Script"
	$Query = [IO.File]::ReadAllText("$sqlScript")
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Server=tcp:$serverName.database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$userName;Password=$userPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
	$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) Write-Host $event.Message -ForegroundColor DarkBlue} 
    $SqlConnection.add_InfoMessage($handler) 
	$SqlConnection.FireInfoMessageEventOnUserErrors=$true
	$SqlConnection.Open()
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection
	$SqlCmd.CommandTimeout = $queryTimeout

	$batches = $Query -split "\s*$batchDelimiter\s*\r?\n"
		foreach($batch in $batches)
    {
        if(![string]::IsNullOrEmpty($batch.Trim()))
        {
            $SqlCmd.CommandText = $batch
	        $reader = $SqlCmd.ExecuteNonQuery()
        }
    }

	$SqlConnection.Close()

	Write-Host "Finished"
}

Catch
{
	Write-Host "Error running SQL script: $_" -ForegroundColor Red
	throw $_
}




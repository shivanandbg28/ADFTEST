param
(

[parameter(Mandatory=$true)]  [string] $paramfilepath, 
[parameter(Mandatory=$true)]  [string] $path,
[parameter(Mandatory=$true)]  [string] $azurePassword,
[parameter(Mandatory=$true)]  [string] $ResourceGroupName,
[parameter(Mandatory=$true)]  [string] $azureAplicationId,
[parameter(Mandatory=$true)]  [string] $azureTenantId,
[parameter(Mandatory=$true)]  [string] $ADFName,
[parameter(Mandatory=$true)]  [string] $SubscriptionName,
#[parameter(Mandatory=$true)]  [string] $DeployLinkedServices,

[parameter(Mandatory=$false)]  [bool] $datasets = $true , 
[parameter(Mandatory=$false)]  [bool] $pipelines = $true, 
[parameter(Mandatory=$false)]  [bool] $linkedservices = $true,
[parameter(Mandatory=$false)]  [bool] $triggers = $true,
[parameter(Mandatory=$false)]  [bool] $Starttriggers = $true,
[parameter(Mandatory=$false)]  [bool] $Stoptriggers = $true

)

Write-Host "Deploy Linked Services : " $DeployLinkedServices
$JSON = ConvertFrom-Json -InputObject(Gc $paramfilepath -Raw)

$azurePassword1 = ConvertTo-SecureString $azurePassword -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($azureAplicationId , $azurePassword1)
Connect-AzAccount -Credential $psCred -TenantId $azureTenantId  -ServicePrincipal  -Subscription  $SubscriptionName

#$psCred = New-Object System.Management.Automation.PSCredential($azureAplicationId , $azurePassword1)
#Add-AzureRmAccount -Credential $psCred -TenantId $azureTenantId  -ServicePrincipal 

if($linkedservices)
    {foreach($ds in $JSON.linkedservices) 
        {
        $dsname = $ds.Name
        Write-Host "JSON File name:" $dsname
        $linkedServicespath1 = (-join($path,"linkedService/",$dsname))

        Write-Host "Deployment linkedServicespath1 file: " $linkedServicespath1
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $ADFName -Name $dsname.Substring(0,($dsname.Length-5)) -File $linkedServicespath1 -force | Format-List #$datasetpath | Format-List

        Write-Host "Name : " $dsname.Substring(0,($dsname.Length-5))

        Write-Host "File Path :" $linkedServicespath1

        Write-Host "linked service :"    $dsname " deployed successfully"
        }
    Write-Host "linked service deployment completed successfully"
    }


if($datasets){
foreach($ds in $JSON.datasets) 
{
$dsname = $ds.Name
Write-Host "JSON File name:" $dsname
$datasetpath1 = (-join($path,"dataset/",$dsname))
$datasetname = $dsname.Substring(0,($dsname.Length-5))
$datasetpath = (-join($ADFName,"/",$datasetname))
$datasetcontent = Get-Content $datasetpath1 | ConvertFrom-Json


Write-Host "Deployment datasetpath1 file: " $datasetpath1
Write-Host "Name : " $dsname.Substring(0,($dsname.Length-5))
Write-Host "File Path :" $datasetpath1
Write-Host "ADFPath : "$datasetpath

#Set-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $ADFName -Name $dsname.Substring(0,($dsname.Length-5)) -DefinitionFile $datasetpath1.ToString() -force | Format-List #$datasetpath | Format-List
New-AzResource -ResourceType "Microsoft.DataFactory/factories/datasets" -ResourceGroupName $ResourceGroupName  -Name $datasetpath -ApiVersion "2018-06-01" -Properties $datasetcontent -Force -IsFullObject
Write-Host "Datasets :"    $dsname.Substring(0,($dsname.Length-5)) " deployed successfully"
}
Write-Host "datasets deployment completed successfully"
}

if($pipelines){
foreach($ds in $JSON.Pipelines) 
{
$dsname = $ds.Name
Write-Host "JSON File name:" $dsname
$pipelinespath1 = (-join($path,"Pipeline/",$dsname))
$pipelinename = $dsname.Substring(0,($dsname.Length-5))
$pipelinepath = (-join($ADFName,"/",$pipelinename))

Write-Host "Deployment pipelinespath1 file: " $pipelinespath1
Write-Host "Name : " $dsname.Substring(0,($dsname.Length-5))
Write-Host "File Path :" $pipelinespath1
Write-Host "ADFPath : "$pipelinepath
$pipelinecontent = Get-Content $pipelinespath1 | ConvertFrom-Json

#Set-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -Name $dsname.Substring(0,($dsname.Length-5)) -DataFactoryName $ADFName -File $pipelinespath1 -force | Format-List #$datasetpath | Format-List
New-AzResource -ResourceType "Microsoft.DataFactory/factories/pipelines" -ResourceGroupName $ResourceGroupName  -Name $pipelinepath -ApiVersion "2018-06-01" -Properties $pipelinecontent -Force -IsFullObject
Write-Host "Pipelines :"    $dsname.Substring(0,($dsname.Length-5)) " deployed successfully"
}
Write-Host "pipelines deployment completed successfully"
}

if($Stoptriggers){
foreach($tr in $JSON.Stoptriggers) 
{
$trname = $tr.Name
Write-Host "JSON File name:" $trname
$triggerpath1 = (-join($path,"trigger/",$trname))

Write-Host "Trigger Name : " $trname.Substring(0,($trname.Length-5))


Stop-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $ADFName -TriggerName $trname.Substring(0,($trname.Length-5)) -Force

Write-Host "trigger :"    $trname.Substring(0,($trname.Length-5)) " Stopped successfully"
}
Write-Host "triggers Stop completed successfully"
}

if($triggers){
foreach($tr in $JSON.triggers) 
{
$trname = $tr.Name
Write-Host "JSON File name:" $trname
$triggerpath1 = (-join($path,"trigger/",$trname))

Write-Host "Deployment triggerspath1 file: " $triggerpath1
Write-Host "Name : " $trname.Substring(0,($trname.Length-5))
Write-Host "File Path :" $triggerpath1

#Set-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -Name $dsname.Substring(0,($dsname.Length-5)) -DataFactoryName $ADFName -File $pipelinespath1 -force | Format-List #$datasetpath | Format-List
Set-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $ADFName -Name $trname.Substring(0,($trname.Length-5)) -DefinitionFile $triggerpath1 -force | Format-List

Write-Host "trigger :"    $trname.Substring(0,($trname.Length-5)) " deployed successfully"

#Set-AzureRmDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $ADFName -Name $trname.Substring(0,($trname.Length-5)) -DefinitionFile $triggerpath1

}
Write-Host "triggers deployment completed successfully"
}


if($Starttriggers){
foreach($tr in $JSON.Starttriggers) 
{
$trname = $tr.Name
Write-Host "JSON File name:" $trname
$triggerpath1 = (-join($path,"trigger/",$trname))

Write-Host "Trigger Name : " $trname.Substring(0,($trname.Length-5))


Start-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $ADFName -TriggerName $trname.Substring(0,($trname.Length-5)) -Force

Write-Host "trigger :"    $trname.Substring(0,($trname.Length-5)) " Started successfully"
}
Write-Host "triggers Start completed successfully"
}




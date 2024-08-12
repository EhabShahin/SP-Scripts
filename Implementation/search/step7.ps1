## Host-A Components
 
Write-Host "Creating Host A Components (Admin, Crawl, Analytics, Content Processing, Index Partition)..."
 
$AdminTopology = New-SPEnterpriseSearchAdminComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology
$CrawlTopology = New-SPEnterpriseSearchCrawlComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology
$AnalyticsTopology = New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology
$ContentProcessingTopology = New-SPEnterpriseSearchContentProcessingComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology
$IndexTopology = New-SPEnterpriseSearchIndexComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology -IndexPartition 0
 

## Host-B Components
 <#
Write-Host "Creating Host B Components (Admin, Crawl, Analytics, Content Processing, Index Partition)..."
 
$AdminTopology = New-SPEnterpriseSearchAdminComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology
$CrawlTopology = New-SPEnterpriseSearchCrawlComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology
$AnalyticsTopology = New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology
$ContentProcessingTopology = New-SPEnterpriseSearchContentProcessingComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology
$IndexTopology = New-SPEnterpriseSearchIndexComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology -IndexPartition 0
 #>


## Host-C Components

Write-Host "Creating Host C Components (Query)..."
 
$QueryTopology = New-SPEnterpriseSearchQueryProcessingComponent -SearchServiceInstance $hostC -SearchTopology $cloneTopology



## Host-D Components
 
 <#

Write-Host "Creating Host D Components (Query)..."
 
$QueryTopology = New-SPEnterpriseSearchQueryProcessingComponent -SearchServiceInstance $hostD -SearchTopology $cloneTopology

#>

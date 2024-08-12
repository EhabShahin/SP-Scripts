$site = "https://portal.lab2022.com/sites/pwa"
New-SPSite -ContentDatabase SP_2022_DEV_Main_WSS_Content_DB -Url $site -Template pwa#0 -OwnerAlias lab2022\adm.lw
Enable-SPFeature pwasite -Url $site
Set-SPProjectPermissionMode -Url $site -Mode ProjectServer
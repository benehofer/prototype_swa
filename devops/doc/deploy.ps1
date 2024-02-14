gci
$swatoken=$(az staticwebapp secrets list --name 'stapp-hofb-wup-tst-sn-01' -o tsv --query "properties.apiKey")
echo "SWATOKEN=$swatoken" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf8 -Append



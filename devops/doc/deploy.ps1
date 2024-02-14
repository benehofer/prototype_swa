gci
$swatoken=$(az staticwebapp secrets list --name 'stapp-hofb-wup-tst-sn-01' -o tsv --query "properties.apiKey")
echo SWATOKEN=$swatoken >> $GITHUB_ENV


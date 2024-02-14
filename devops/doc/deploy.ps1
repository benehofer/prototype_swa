npm install -g @azure/static-web-apps-cli
$swatoken=$(az staticwebapp secrets list --name 'stapp-hofb-wup-tst-sn-01' -o tsv --query "properties.apiKey")
write-Host $swaToken
gci
$res=$(swa deploy --deployment-token $swatoken --env Production)


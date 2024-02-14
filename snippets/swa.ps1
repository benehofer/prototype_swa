
npm install -g @azure/static-web-apps-cli


$swatoken=$(az staticwebapp secrets list --name 'stapp-hofb-wup-tst-sn-01' -o tsv --query "properties.apiKey")


$swaUrl="https://$($(az staticwebapp show --name 'stapp-hofb-wup-tst-sn-01' -o tsv  --query "defaultHostname"))/.auth/login/aad/callback"


swa deploy .\snippets\doc --deployment-token $swatoken --env Production

az ad app update --id "0f56b1d7-dd48-45a6-b98a-9eeb5b3f7a96" --web-redirect-uris $swaUrl --enable-id-token-issuance






Write-Host "Building documentation"
new-item -Path .\deployment\doc -ItemType Directory
copy-item -Path .\snippets\doc .\deployment\doc



Write-Host "Building documentation"
new-item -Path .\deployment -ItemType Directory | out-null
copy-item -Path ".\snippets\doc" ".\deployment\" -Recurse



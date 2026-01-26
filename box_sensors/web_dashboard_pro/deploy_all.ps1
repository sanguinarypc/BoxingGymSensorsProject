# deploy_all.ps1
$ErrorActionPreference = "Stop"

& .\prepare_ssh_agent.ps1
& .\deploy_node.bat
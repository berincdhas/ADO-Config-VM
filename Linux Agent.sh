#!/usr/bin/env bash
export ORG=berincdhas0398
export PROJECT=$(System.TeamProject)
export ENVIRONMENT=$(environmentName)
export TOKEN=$(token)
set -e
export SUDO_USER=azureuser
#export AZP_AGENT_VERSION=$(curl -s https://api.github.com/repos/microsoft/azure-pipelines-agent/releases | jq -r '.[0].tag_name' | cut -d "v" -f 2)
# Select a default agent version if one is not specified
if [ -z "$AZP_AGENT_VERSION" ]; then
  AZP_AGENT_VERSION=2.187.2
fi
if [[ "$ENVIRONMENT" == "" ]] 
then
    echo "environment . Use --environment to specify agent pool"
  exit 1
fi    
if [[ "$PROJECT" == "" ]] 
then
    echo "No Project. Use --agent-name to specify agent name"
  exit 1
fi    
# Verify Azure Pipelines token is set
if [ -z "$TOKEN" ]; then
  echo 1>&2 "error: missing TOKEN environment variable"
  exit 1
fi

# Verify Azure DevOps URL is set
if [ -z "$ORG" ]; then
  echo 1>&2 "error: missing ORG environment variable"
  exit 1
fi

export AZP_WORK=_work
# If a working directory was specified, create that directory
if [ -n "$AZP_WORK" ]; then
  mkdir -p "$AZP_WORK"
fi

# Create the Downloads directory under the user's home directory
if [ -n "$HOME/Downloads" ]; then
  mkdir -p "$HOME/Downloads"
fi

# Download the agent package
curl https://vstsagentpackage.azureedge.net/agent/$AZP_AGENT_VERSION/vsts-agent-linux-x64-$AZP_AGENT_VERSION.tar.gz > $HOME/Downloads/vsts-agent-linux-x64-$AZP_AGENT_VERSION.tar.gz

# Create the working directory for the agent service to run jobs under
if [ -n "$AZP_WORK" ]; then
  mkdir -p "$AZP_WORK"
fi

# Create a working directory to extract the agent package to
mkdir -p $HOME/azp/agent

# Move to the working directory
cd $HOME/azp/agent

# Extract the agent package to the working directory
tar zxvf $HOME/Downloads/vsts-agent-linux-x64-$AZP_AGENT_VERSION.tar.gz

# Install the agent software
./bin/installdependencies.sh
chmod -R 755 $HOME/azp/agent
# Configure the agent as the sudo (non-root) user
chown $SUDO_USER $HOME/azp/agent
chown $SUDO_USER . -R
sudo -u $SUDO_USER ./config.sh --unattended \
    --url https://dev.azure.com/${ORG} \
    --auth pat --token $TOKEN \
    --work $AZP_WORK \
    --projectname $PROJECT \
    --environment --environmentname $ENVIRONMENT \
    --agent $HOSTNAME \
    --runasservice \
    --replace \
    --acceptTeeEula

# Install and start the agent service
./svc.sh install
./svc.sh start

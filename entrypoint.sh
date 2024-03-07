#!/bin/bash

set -e

port_client_id="$INPUT_PORTCLIENTID"
port_client_secret="$INPUT_PORTCLIENTSECRET"
port_run_id="$INPUT_PORTRUNID"
github_token="$INPUT_TOKEN"
blueprint_identifier="$INPUT_BLUEPRINTIDENTIFIER"
repository_name="$INPUT_REPOSITORYNAME"
org_name="$INPUT_ORGANIZATIONNAME"
cookie_cutter_template="$INPUT_COOKIECUTTERTEMPLATE"
template_directory="$INPUT_TEMPLATEDIRECTORY"
port_user_inputs="$INPUT_PORTUSERINPUTS"
monorepo_url="$INPUT_MONOREPOURL"
scaffold_directory="$INPUT_SCAFFOLDDIRECTORY"
create_port_entity="$INPUT_CREATEPORTENTITY"
branch_name="port_$port_run_id"
git_url="$INPUT_GITHUBURL"

#!/bin/bash

set -e

port_client_id="$INPUT_PORTCLIENTID"
port_client_secret="$INPUT_PORTCLIENTSECRET"
port_run_id="$INPUT_PORTRUNID"
github_token="$INPUT_TOKEN"
blueprint_identifier="$INPUT_BLUEPRINTIDENTIFIER"
repository_name="$INPUT_REPOSITORYNAME"
org_name="$INPUT_ORGANIZATIONNAME"
cookie_cutter_template="$INPUT_COOKIECUTTERTEMPLATE"
template_directory="$INPUT_TEMPLATEDIRECTORY"
port_user_inputs="$INPUT_PORTUSERINPUTS"
monorepo_url="$INPUT_MONOREPOURL"
scaffold_directory="$INPUT_SCAFFOLDDIRECTORY"
create_port_entity="$INPUT_CREATEPORTENTITY"
branch_name="port_$port_run_id"
git_url="$INPUT_GITHUBURL"

# Imprimir os valores das variáveis
echo "port_client_id: $port_client_id"
echo "port_client_secret: $port_client_secret"
echo "port_run_id: $port_run_id"
echo "github_token: $github_token"
echo "blueprint_identifier: $blueprint_identifier"
echo "repository_name: $repository_name"
echo "org_name: $org_name"
echo "cookie_cutter_template: $cookie_cutter_template"
echo "template_directory: $template_directory"
echo "port_user_inputs: $port_user_inputs"
echo "monorepo_url: $monorepo_url"
echo "scaffold_directory: $scaffold_directory"
echo "create_port_entity: $create_port_entity"
echo "branch_name: $branch_name"
echo "git_url: $git_url"

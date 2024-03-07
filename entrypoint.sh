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

get_access_token() {
  curl -s --location --request POST 'https://api.getport.io/v1/auth/access_token' --header 'Content-Type: application/json' --data-raw "{
    \"clientId\": \"$port_client_id\",
    \"clientSecret\": \"$port_client_secret\"
  }" | jq -r '.accessToken'
}

send_log() {
  message=$1
  curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
    --header "Authorization: Bearer $access_token" \
    --header "Content-Type: application/json" \
    --data "{
      \"message\": \"$message\"
    }"
}

add_link() {
  url=$1
  curl --request PATCH --location "https://api.getport.io/v1/actions/runs/$port_run_id" \
    --header "Authorization: Bearer $access_token" \
    --header "Content-Type: application/json" \
    --data "{
      \"link\": \"$url\"
    }"
}

create_repository() {  
  resp=$(curl -H "Authorization: token $github_token" -H "Accept: application/json" -H "Content-Type: application/json" $git_url/users/$org_name)

  userType=$(jq -r '.type' <<< "$resp")
    
  if [ $userType == "User" ]; then
    curl -X POST -i -H "Authorization: token $github_token" -H "X-GitHub-Api-Version: 2022-11-28" \
       -d "{ \
          \"name\": \"$repository_name\", \"private\": true
        }" \
      $git_url/user/repos
  elif [ $userType == "Organization" ]; then
    curl -i -H "Authorization: token $github_token" \
       -d "{ \
          \"name\": \"$repository_name\", \"private\": true
        }" \
      $git_url/orgs/$org_name/repos
  else
    echo "Invalid user type"
  fi
}

clone_monorepo() {
  git clone $monorepo_url monorepo
  cd monorepo
  git checkout -b $branch_name
}

prepare_cookiecutter_extra_context() {
  echo "$port_user_inputs" | jq -r 'with_entries(select(.key | startswith("cookiecutter_")) | .key |= sub("cookiecutter_"; ""))'
}

cd_to_scaffold_directory() {
  if [ -n "$monorepo_url" ] && [ -n "$scaffold_directory" ]; then
    cd $scaffold_directory
  fi
}

apply_cookiecutter_template() {
  extra_context=$(prepare_cookiecutter_extra_context)

  echo "🍪 Applying cookiecutter template $cookie_cutter_template with extra context $extra_context"
  # Convert extra context from JSON to arguments
  args=()
  for key in $(echo "$extra_context" | jq -r 'keys[]'); do
      args+=("$key=$(echo "$extra_context" | jq -r ".$key")")
  done

  # Call cookiecutter with extra context arguments
  if [ -n "$template_directory" ]; then
    echo "cookiecutter --no-input $cookie_cutter_template --directory $template_directory ${args[*]}"
    cookiecutter --no-input $cookie_cutter_template --directory $template_directory "${args[@]}"
  else
    echo "cookiecutter --no-input $cookie_cutter_template ${args[*]}"
    cookiecutter --no-input $cookie_cutter_template "${args[@]}"
  fi

  # Verificar se a última execução foi bem-sucedida (código de saída igual a 0)
  if [ $? -eq 0 ]; then
    echo "🍪 Cookiecutter template applied successfully!"
    # Chame a próxima função aqui
    # next_function
  else
    echo "❌ Error: Failed to apply cookiecutter template."
    # Trate o erro conforme necessário
  fi
}

main() {
  access_token=$(get_access_token)

  if [ -z "$monorepo_url" ] || [ -z "$scaffold_directory" ]; then
    send_log "Creating a new repository: $repository_name 🏃"
    create_repository
    send_log "Created a new repository at https://github.com/$org_name/$repository_name 🚀"
  else
    send_log "Using monorepo scaffolding 🏃"
    clone_monorepo
    cd_to_scaffold_directory
    send_log "Cloned monorepo and created branch $branch_name 🚀"
  fi

  send_log "Starting templating with cookiecutter 🍪"
  apply_cookiecutter_template
  send_log "Create template sucessefull 👍"

  url="https://github.com/$org_name/$repository_name"

  if [[ "$create_port_entity" == "true" ]]
  then
    send_log "Reporting to Port the new entity created 🚢"
    report_to_port
  else
    send_log "Skipping reporting to Port the new entity created 🚢"
  fi

  if [ -n "$monorepo_url" ] && [ -n "$scaffold_directory" ]; then
    send_log "Finished! 🏁✅"
  else
    send_log "Finished! Visit $url 🏁✅"
  fi
}

main

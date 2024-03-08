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
#echo "port_client_id: $port_client_id"
#echo "port_client_secret: $port_client_secret"
#echo "port_run_id: $port_run_id"
#echo "github_token: $github_token"
#echo "blueprint_identifier: $blueprint_identifier"
#echo "repository_name: $repository_name"
#echo "org_name: $org_name"
#echo "cookie_cutter_template: $cookie_cutter_template"
#echo "template_directory: $template_directory"
#echo "port_user_inputs: $port_user_inputs"
#echo "monorepo_url: $monorepo_url"
#echo "scaffold_directory: $scaffold_directory"
#echo "create_port_entity: $create_port_entity"
#echo "branch_name: $branch_name"
#echo "git_url: $git_url"

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

echo "==============XXXXXXXXXXXXXXXXXX: $port_user_inputs"

#!/bin/bash

# Assuming your JSON data is stored in the variable port_user_inputs
user_inputs_json="$port_user_inputs"

# Use jq to process the JSON data
IFS=$'\n' read -r -d '' project_name aws_region name_vpc block_cidr \
 availability_zone private_subnets public_subnets enable_nat_gateway single_nat_gateway enable_vpn_gateway <<< "$user_inputs_json" \
  jq -r '
    . as entries |
    map(.key + "=" + (.value | tostring)) |
    join(" ")
  '

# Print the formatted output with each key-value pair on a new line
echo "project_name=$project_name"
echo "aws_region=$aws_region"
echo "name_vpc=$name_vpc"
echo "block_cidr=$block_cidr"
echo "availability_zone=$availability_zone"
echo "private_subnets=$private_subnets"
echo "public_subnets=$public_subnets"
echo "enable_nat_gateway=$enable_nat_gateway"
echo "single_nat_gateway=$single_nat_gateway"
echo "enable_vpn_gateway=$enable_vpn_gateway"





#prepare_cookiecutter_extra_context() {
#  echo "$port_user_inputs" | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | join(" ")'
#}
# Chame a função e atribua o resultado a uma variável
#prepare_cookiecutter_result=$(prepare_cookiecutter_extra_context)
# Exiba o conteúdo da variável
#echo "$prepare_cookiecutter_result"
cd_to_scaffold_directory() {
  if [ -n "$monorepo_url" ] && [ -n "$scaffold_directory" ]; then
    cd $scaffold_directory
  fi
}
apply_cookiecutter_template() {
  #extra_context=$(prepare_cookiecutter_extra_context)
  echo "🍪 Applying cookiecutter template $cookie_cutter_template with extra context $port_user_inputs"
  # Convert extra context from JSON to arguments
  args=()
  for key in $(echo "$port_user_inputs" | jq -r 'keys[]'); do
      args+=("$key=$(echo "$port_user_inputs" | jq -r ".$key")")
  done
  # Call cookiecutter with extra context arguments
  echo "cookiecutter --no-input $cookie_cutter_template $args"
  # Call cookiecutter with extra context arguments
  if [ -n "$template_directory" ]; then
    cookiecutter --no-input $cookie_cutter_template --directory $template_directory "${args[@]}"
  else
    cookiecutter --no-input $cookie_cutter_template "${args[@]}"
  fi
}
push_to_repository() {
  if [ -n "$monorepo_url" ] && [ -n "$scaffold_directory" ]; then
    git config user.name "GitHub Actions Bot"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add .
    git commit -m "Scaffolded project in $scaffold_directory"
    git push -u origin $branch_name
    send_log "Creating pull request to merge $branch_name into main 🚢"
    owner=$(echo "$monorepo_url" | awk -F'/' '{print $4}')
    repo=$(echo "$monorepo_url" | awk -F'/' '{print $5}')
    echo "Owner: $owner"
    echo "Repo: $repo"
    PR_PAYLOAD=$(jq -n --arg title "Scaffolded project in $repo" --arg head "$branch_name" --arg base "main" '{
      "title": $title,
      "head": $head,
      "base": $base
    }')
    echo "PR Payload: $PR_PAYLOAD"
    pr_url=$(curl -X POST \
      -H "Authorization: token $github_token" \
      -H "Content-Type: application/json" \
      -d "$PR_PAYLOAD" \
      "$git_url/repos/$owner/$repo/pulls" | jq -r '.html_url')
    send_log "Opened a new PR in $pr_url 🚀"
    add_link "$pr_url"
    else
      cd "$(ls -td -- */ | head -n 1)"
      git init
      git config user.name "GitHub Actions Bot"
      git config user.email "github-actions[bot]@users.noreply.github.com"
      git add .
      git commit -m "Initial commit after scaffolding"
      git branch -M main
      git remote add origin https://oauth2:$github_token@github.com/$org_name/$repository_name.git
      git push -u origin main
  fi
}
main() {
  if [ -z "$monorepo_url" ] || [ -z "$scaffold_directory" ]; then
    create_repository
  else
    clone_monorepo
    cd_to_scaffold_directory
  fi
  #apply_cookiecutter_template
  #push_to_repository
}
main

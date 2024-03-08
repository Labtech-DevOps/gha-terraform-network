import requests
import json
import subprocess
from collections import namedtuple


def get_access_token(port_client_id, port_client_secret):
    url = "https://api.getport.io/v1/auth/access_token"
    headers = {"Content-Type": "application/json"}
    data = {"clientId": port_client_id, "clientSecret": port_client_secret}
    response = requests.post(url, headers=headers, json=data)
    response.raise_for_status()
    return response.json()["accessToken"]


def send_log(message, access_token):
    url = f"https://api.getport.io/v1/actions/runs/{port_run_id}/logs"
    headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}
    data = {"message": message}
    requests.post(url, headers=headers, json=data)


def add_link(url, access_token):
    url = f"https://api.getport.io/v1/actions/runs/{port_run_id}"
    headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}
    data = {"link": url}
    requests.patch(url, headers=headers, json=data)


def create_repository(github_token, org_name, repository_name, git_url):
    url = f"{git_url}/users/{org_name}"
    headers = {"Authorization": f"token {github_token}", "Accept": "application/json", "Content-Type": "application/json"}
    response = requests.get(url, headers=headers)
    response.raise_for_status()

    user_type = response.json()["type"]

    if user_type == "User":
        url = f"{git_url}/user/repos"
        data = {"name": repository_name, "private": True}
        headers["X-GitHub-Api-Version"] = "2022-11-28"
        requests.post(url, headers=headers, json=data)
    elif user_type == "Organization":
        url = f"{git_url}/orgs/{org_name}/repos"
        data = {"name": repository_name, "private": True}
        requests.post(url, headers=headers, json=data)
    else:
        raise ValueError("Invalid user type")


def clone_monorepo(monorepo_url, branch_name):
    subprocess.run(["git", "clone", monorepo_url, "monorepo"])
    subprocess.run(["git", "checkout", "-b", branch_name], cwd="monorepo")


def prepare_cookiecutter_extra_context(port_user_inputs):
    process = subprocess.Popen(
        ["jq", "-r", '.with_entries(select(.key | startswith("cookiecutter_")) | .key |= sub("cookiecutter_"; ""))'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    output, _ = process.communicate(port_user_inputs, timeout=10)
    return output.strip()


def cd_to_scaffold_directory(monorepo_url, scaffold_directory):
    if monorepo_url and scaffold_directory:
        subprocess.run(["cd", scaffold_directory])


def apply_cookiecutter_template(cookie_cutter_template, extra_context, template_directory=None):
    print(f" Applying cookiecutter template {cookie_cutter_template} with extra context {extra_context}")

    # Convert extra context to arguments
    args = []
    for key in extra_context.splitlines():
        value = key.split("=", 1)[1]
        args.append(f"{key.split('=')[0]}={value}")

    # Call cookiecutter with extra context arguments
    print(f"cookiecutter --no-input {cookie_cutter_template} {' '.join(args)}")
    if template_directory:
        subprocess.run(
            ["cookiecutter", "--no-input", cookie_cutter_template, *args], cwd=template_directory
        )
    else:

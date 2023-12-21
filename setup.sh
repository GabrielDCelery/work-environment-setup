#!/bin/bash

function prompt_user_for_value {
	read -p "$1: " value
	echo "${value}"
}

function prompt_user_for_input_needed_for_setup {
	while true; do
		printf "\n"
		user_github_name=$(prompt_user_for_value "Enter your GitHub user name")
		user_github_email=$(prompt_user_for_value "Enter your GitHub email")
		user_github_access_key=$(prompt_user_for_value "Enter your GitHub access token")

		printf "\n"
		printf "\033[1mGitHub user name:\033[0m %1s\n" "${user_github_name}"
		printf "\033[1mGitHub email:\033[0m %1s\n" "${user_github_email}"
		printf "\033[1mGitHub access key:\033[0m %1s\n" "${user_github_access_key}"
		printf "\n"

		local default_happy_with_params="n"

		read -p "Are you happy with the settings (y/N)?: " happy_with_params
		happy_with_params=${happy_with_params:-$default_happy_with_params}
		if [[ "${happy_with_params}" == "y" ]]; then
			break
		fi
	done
}

function install_git {
	if [ $(type -p git) ]; then
		echo "Git already installed, skipping..."
		return 1
	fi
	sudo apt install git-all
}

function install_github_cli {
	if [ $(type -p gh) ]; then
		echo "GitHub cli already installed, skipping..."
		return 1
	fi
	type -p curl >/dev/null || sudo apt install curl -y
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
	sudo apt update
	sudo apt install gh -y
}

function create_unique_ssh_key {
	machine_username=$(whoami)
	machine_hostname=$(hostname)
	user_private_ssh_file_name=$(echo "${machine_username}_${machine_hostname}" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
	local user_private_ssh_file_path=~/.ssh/$user_private_ssh_file_name
	ssh-keygen -f $user_private_ssh_file_path -t ed25519 -C $user_github_email
	eval "$(ssh-agent -s)"
	ssh-add $user_private_ssh_file_path
}

function configure_git_locally {
	git config --global user.name "${user_github_name}"
	git config --global user.email "${user_github_email}"
}

function sync_ssh_key_with_github {
	echo $user_github_access_key | gh auth login --with-token
	user_public_ssh_key_file_name="${user_private_ssh_file_name}.pub"
	user_public_ssh_file_path=~/.ssh/$user_public_ssh_key_file_name
	gh ssh-key add $user_public_ssh_file_path --title $user_private_ssh_file_name
}

prompt_user_for_input_needed_for_setup
install_git
install_github_cli
create_unique_ssh_key
configure_git_locally
sync_ssh_key_with_github

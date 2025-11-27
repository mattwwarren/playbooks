check_ssh_key_unlocked() {

    # 1. Check for the existence of SSH key files in the default directory
    ssh_dir="$HOME/.ssh"
    if [ ! -d "$SSH_DIR" ]; then
        echo "The directory $SSH_DIR does not exist."
        return 1
    fi

    # Check if any private key files exist (look for files without a .pub extension)
    private_keys=$(find "$SSH_DIR" -maxdepth 1 -type f \( -name "id_rsa" -o -name "id_ecdsa" -o -name "id_ed25519" -o -name "id_dsa" \) 2>/dev/null)
    
    if [ -z "$PRIVATE_KEYS" ]; then
        echo "## Status: No Keys Available"
        return 1
    fi

    # Check if ssh-agent is running
    if ! pgrep -x "ssh-agent" > /dev/null; then
        echo "ssh-agent is not running. No keys are loaded. Assuming non-existant."
        return 1
    fi

    # List loaded SSH keys
    echo "Checking for loaded SSH keys in ssh-agent..."
    if ssh-add -l > /dev/null 2>&1; then
        echo "SSH keys are loaded in ssh-agent:"
        ssh-add -L
        return 0
    else
        echo "No SSH keys are currently loaded in ssh-agent."
        echo "You may need to add them using 'ssh-add <path_to_private_key>'."
        echo "Re-run install after unlocking your key."
        return 2
    fi
    return 128
}

check_github_ssh() {
    echo "Attempting to connect to GitHub via SSH..."
    output=$(ssh -T git@github.com 2>&1)
    exit_status=$?

    if [ $exit_status -eq 1 ]; then
        if [[ "$output" == *"Hi "* ]] && [[ "$output" == *"You've successfully authenticated"* ]]; then
            echo "✅ Success: GitHub SSH connection is valid."
            echo "Message from GitHub: $output"
            return 0
        else
            echo "❌ Failure: Authentication failed or unexpected message received."
            echo "Output: $output"
            return 1
        fi
    elif [ $exit_status -eq 0 ]; then
         echo "ssh returned unexpected 0"
         echo "$output"
         exit 128
    elif [ $exit_status -eq 255 ]; then
         return 
    else
        echo "❌ Failure: SSH connection failed with exit status $exit_status."
        echo "Check your SSH keys, ssh-agent, or network connectivity."
        echo "Output: $output"
        return 1
    fi
}

setup_gh_cli() {
    echo "GitHub keys not configured. Installing gh..."
    sudo zypper addrepo -y "https://cli.github.com/packages/rpm/gh-cli.repo"
    sudo zypper ref
    sudo zypper install -y "gh"
    echo "Configuring gh... This will be interactive"
    gh auth login
}

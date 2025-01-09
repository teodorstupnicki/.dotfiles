# Get sudo
#sudo -v

# Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Enable brew
(
  echo
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
) >>/Users/mrf/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install packages and casks with brew
echo "Installing programs with homebrew"
brew update
brew upgrade

brew install --cask 1password 1password-cli arc discord karabiner-elements orbstack raycast rectangle-pro shottr visual-studio-code

brew install corepack deno dockutil fnm gh git httpie iperf3 node plow stripe tfenv tmux fzf

# Install and setup foundry
/bin/bash -c "$(curl -L https://foundry.paradigm.xyz)" | bash
foundryup

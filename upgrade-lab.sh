# Our directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Reconfigure git repository after bootstrap
REMOTE_URL=$(git -C $SCRIPT_DIR remote get-url origin)
ORIGINAL_URL=$(curl -Ls -o /dev/null -w %{url_effective} https://tinyurl.com/rhbkws)
git -C $SCRIPT_DIR remote set-url origin $ORIGINAL_URL

# Setup git LFS and checkout binaries
sudo yum -y install git-lfs
git -C $SCRIPT_DIR lfs install
git -C $SCRIPT_DIR lfs fetch
git -C $SCRIPT_DIR lfs checkout

# Replace SSO version on student machine
ssh student@sso -- rm *.zip
scp $SCRIPT_DIR/rhbk-24.0.8.zip student@sso:

# Replace playbooks
cp $SCRIPT_DIR/install-sso-server.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/

# Startup script
cp $SCRIPT_DIR/rhbk.service $HOME

# Java version on RHSSO machine
ssh rhsso@sso sudo yum -y install java-17-openjdk
ssh rhsso@sso sudo ln -sf /usr/lib/jvm/jre-17/bin/java /etc/alternatives/java



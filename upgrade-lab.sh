# Our directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Reconfigure git repository after bootstrap
REMOTE_URL=$(git -C $SCRIPT_DIR remote get-url origin)
ORIGINAL_URL=$(curl -Ls -o /dev/null -w %{url_effective} https://tinyurl.com/rhbkws)
git -C $SCRIPT_DIR remote delete origin
git -C $SCRIPT_DIR remote add origin $ORIGINAL_URL

# Setup git LFS and checkout binaries
sudo yum -y install git-lfs
git -C $SCRIPT_DIR lfs install
git -C $SCRIPT_DIR lfs fetch
git -C $SCRIPT_DIR lfs checkout

# Copy RHBK to home direcotry
cp $SCRIPT_DIR/rhbk-24.0.8.zip $HOME




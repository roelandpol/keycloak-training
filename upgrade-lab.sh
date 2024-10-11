# https://tinyurl.com/rhbkws

# Our directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Reconfigure git repository after bootstrap since git does not work for tinyurl redirects
REMOTE_URL=$(git -C $SCRIPT_DIR remote get-url origin)
ORIGINAL_URL=$(curl -Ls -o /dev/null -w %{url_effective} $REMOTE_URL)
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
cp $SCRIPT_DIR/remove-sso-server.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/
cp $SCRIPT_DIR/start-install-ways.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/install-ways/start-install-ways.yaml
cp $SCRIPT_DIR/finish-install-ways.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/install-ways/finish-install-ways.yaml
sed -i 's/rh-sso-7.6/rhbk-24.0.8/g' -- $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/import-base-realm.yaml
# remove /auth prefix since RHBK does not use that anymore
sed -i 's/\/auth//g' -- $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/import-base-realm.yaml
# using https
sed -i 's/http:/https:/g' -- $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/import-base-realm.yaml
sed -i 's/jboss-eap-rhel/rhbk/g' -- $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/recreate-db.yaml
sudo chattr +i $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/install-sso-server.yaml
sudo chattr +i $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/remove-sso-server.yaml
sudo chattr +i $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/import-base-realm.yaml
sudo chattr +i $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/recreate-db.yaml
sudo chattr +i $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/install-ways/start-install-ways.yaml
sudo chattr +i $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/install-ways/finish-install-ways.yaml

# Startup script
cp $SCRIPT_DIR/rhbk.service $HOME

# Java version on RHSSO machine
ssh rhsso@sso sudo yum -y install java-17-openjdk
ssh rhsso@sso sudo ln -sf /usr/lib/jvm/jre-17/bin/java /etc/alternatives/java
scp /home/student/.venv/labs/lib/python3.6/site-packages/do313/materials/labs/common/sso.lab.example.com.pem rhsso@sso:/home/rhsso/
ssh rhsso@sso sudo keytool -keystore /usr/lib/jvm/jre-17/lib/security/cacerts -import -file /home/rhsso/sso.lab.example.com.pem -storepass changeit -trustcacerts -noprompt

# install keycloak on OpenShift CA cert on workstation machine
sudo cp $SCRIPT_DIR/keycloak-openshift-ca.crt /usr/share/pki/ca-trust-source/anchors/
sudo update-ca-trust


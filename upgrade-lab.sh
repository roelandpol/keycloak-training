# https://tinyurl.com/rhbkws

# Our directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# We are breaking the default environment. Disable updates to the labs framework
sudo systemctl disable dynolabs-update
sudo sed -i 's/^systemctl/#systemctl/g' -- /etc/rc.d/rc.local-rht

# Verify OpenShift connection
oc login -u admin -p redhat https://api.ocp4.example.com:6443
if [ $? -gt 0 ]; then
  echo "Failed to connect to OpenShift. Try again in 10 minutes"
  exit 1
fi

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
cp $SCRIPT_DIR/identity-broker-start.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/identity-broker/start-identity-broker.yaml
sed -i 's/rh-sso-7.6/rhbk-24.0.8/g' -- $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/import-base-realm.yaml
# remove /auth prefix since RHBK does not use that anymore
sed -i 's/\/auth//g' -- $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/import-base-realm.yaml
# using https
sed -i 's/http:/https:/g' -- $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/import-base-realm.yaml
sed -i 's/jboss-eap-rhel/rhbk/g' -- $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/common/recreate-db.yaml

# Startup script
cp $SCRIPT_DIR/rhbk.service $HOME

# Java version on RHSSO machine
ssh rhsso@sso sudo yum -y install java-17-openjdk
ssh rhsso@sso sudo ln -sf /usr/lib/jvm/jre-17/bin/java /etc/alternatives/java
scp /home/student/.venv/labs/lib/python3.6/site-packages/do313/materials/labs/common/sso.lab.example.com.pem rhsso@sso:/home/rhsso/
ssh rhsso@sso sudo keytool -keystore /usr/lib/jvm/jre-17/lib/security/cacerts -import -file /home/rhsso/sso.lab.example.com.pem -storepass changeit -trustcacerts -noprompt
scp $SCRIPT_DIR/rht-ca.crt rhsso@sso:/home/rhsso/
scp $SCRIPT_DIR/rht-ts.crt rhsso@sso:/home/rhsso/
ssh rhsso@sso sudo keytool -keystore /usr/lib/jvm/jre-17/lib/security/cacerts -import -file /home/rhsso/sso.lab.example.com.pem -storepass changeit -trustcacerts -noprompt
ssh rhsso@sso sudo keytool -keystore /usr/lib/jvm/jre-17/lib/security/cacerts -import -file /home/rhsso/rht-ca.crt -storepass changeit -trustcacerts -noprompt
ssh rhsso@sso sudo keytool -keystore /usr/lib/jvm/jre-17/lib/security/cacerts -import -file /home/rhsso/rht-ts.crt -storepass changeit -trustcacerts -noprompt

# install keycloak on OpenShift CA cert on workstation machine
sudo cp $SCRIPT_DIR/keycloak-openshift-ca.crt /usr/share/pki/ca-trust-source/anchors/
sudo update-ca-trust

# OpenShift changes
oc replace -f $SCRIPT_DIR/openshift-pullsecret.yaml
oc create -f $SCRIPT_DIR/openshift-catalogsource.yaml
cp $SCRIPT_DIR/openshift-sso-db-credentials.yaml $HOME/DO313/
cp $SCRIPT_DIR/openshift-sso-secret.yaml $HOME/DO313/
cp $SCRIPT_DIR/openshift-keycloak.yaml $HOME/DO313/
cp $SCRIPT_DIR/installsso-main.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/ocp-installsso/roles/rhsso_remove/tasks/main.yaml
cp $SCRIPT_DIR/configsso-install.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/ansible/ocp-configsso/roles/rhsso_install/tasks/main.yaml
cp $SCRIPT_DIR/configsso-resources.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/materials/solutions/ocp-configsso/resources.yaml 
rm -f $HOME/.venv/labs/lib/python3.6/site-packages/do313/materials/labs/ocp-configsso/*
cp $SCRIPT_DIR/configsso-realmimport.yaml $HOME/.venv/labs/lib/python3.6/site-packages/do313/materials/labs/ocp-configsso/

# base url changes for labs
find /home/student/.venv/labs/lib/python3.6/site-packages/do313/materials/labs -name application.properties | xargs sed -i 's|https://sso.lab.example.com:8080/auth/realms/rhtraining|https://sso.lab.example.com:8443/realms/rhtraining|g'
find /home/student/.venv/labs/lib/python3.6/site-packages/do313/materials/labs -name keycloak.json | xargs sed -i 's|https://sso.lab.example.com:8080/auth/|https://sso.lab.example.com:8443/|g'


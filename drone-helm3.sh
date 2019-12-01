#!/bin/sh
set -e
# set -x

# configuration
# $PLUGIN_PUSH
# $PLUGIN_CHART
# $PLUGIN_REPO
# $PLUGIN_AUTHORIZATION
# $PLUGIN_DEPLOY
# $PLUGIN_RELEASE_NAME
# $PLUGIN_NAMESPACE
# $PLUGIN_SERVER
# $PLUGIN_CERTIFICATE_AUTHORITY
# $PLUGIN_INSECURE
# $PLUGIN_TOKEN

# global variables
VAR_TAR_FILE=""

# package
exec_package() {
  # from env
  local chart=$PLUGIN_CHART

  local temp=$(helm package $chart)
  VAR_TAR_FILE=${temp##*/}
}

# push
exec_push() {
  if [ $PLUGIN_PUSH == true ]; then
    return
  fi

  # from package function
  local tar_file=$VAR_TAR_FILE

  # from env
  local repo=$PLUGIN_REPO
  local authorization=$PLUGIN_AUTHORIZATION

  local tar_name=${tar_file%.tgz}
  local chart_name=${tar_name%-*}
  local chart_version=${tar_name##*-}

  local auth_arg
  if [ $authorization != "" ]; then
    auth_arg="-H \"Authorization: $authorization\""
  fi

  curl $auth_arg -X DELETE $repo/api/charts/$chart_name/$chart_version
  curl $auth_arg --data-binary "@$tar_file" $repo/api/charts
}

# deploy
exec_deploy() {
  if [ $PLUGIN_DEPLOY == true ]; then
    return
  fi

  # from package function
  local tar_file=$VAR_TAR_FILE

  # from env
  local server=$PLUGIN_SERVER
  local certificate_authority=$PLUGIN_CERTIFICATE_AUTHORITY
  local token=$PLUGIN_TOKEN
  local release_name=$PLUGIN_RELEASE_NAME
  local namespace=$PLUGIN_NAMESPACE

  local insecure=false
  if [ $PLUGIN_INSECURE == true ]; then
    insecure=true
  fi

  export KUBECONFIG=/tmp/kubeconfig
  cat << EOF > $KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: $insecure
    certificate-authority-data: $certificate_authority
    server: $server
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    token: $token
EOF

  local release_exists=true
  helm hist $release_name --namespace=$namespace || release_exists=false
  if [ $release_exists == false ]; then
    helm install $release_name $tar_file --namespace=$namespace
  else
    helm upgrade $release_name $tar_file --namespace=$namespace
  fi
}

{
  exec_package
  exec_push
  exec_deploy
}

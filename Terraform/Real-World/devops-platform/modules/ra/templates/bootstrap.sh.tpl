#!/bin/bash
set -euo pipefail

S3_BUCKET="${s3_bucket}"
S3_DEPLOY_PREFIX="${s3_deploy_prefix}"
LAYOUT_SCRIPT="01_create_example_layout.sh"
INSTALL_SCRIPT="00_install_from_s3.sh"

SERVICE_USER="example"
example_BASE="/opt/example"
APP_DIR="$${example_BASE}/rosterautomation"
ROSTER_DIR="$${APP_DIR}/roster-app"
LAUNCH_SCRIPT_REL="scripts/launch/launch_automation_s3.sh"

INSTALL_RELEASE=""
ENV_SECRET_NAME="${env_secret_name}"
ENABLE_ECR_LOGIN="true"
ECR_REGISTRY="${ecr_registry}"
ECR_REGION="${ecr_region}"
AWS_REGION_OVERRIDE=""

LOG_FILE="/var/log/user-data-example.log"
TRACE_LOG="/var/log/user-data-example-trace.log"

exec > >(stdbuf -oL awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush(); }' | tee -a "$${LOG_FILE}") 2>&1

log()  { echo "==> $*"; }
fail() { echo "!!! ERROR: $*" >&2; exit 1; }
trap 'fail "Script aborted at line $LINENO (exit code $?)"' ERR

exec 9>>"$${TRACE_LOG}"
export BASH_XTRACEFD=9
PS4='+ [$$(date "+%Y-%m-%d %H:%M:%S")] [$${BASH_SOURCE##*/}:$${LINENO}] '
set -x

log "Starting roster-app automated deployment"

if [[ -n "$${AWS_REGION_OVERRIDE}" ]]; then
  export AWS_DEFAULT_REGION="$${AWS_REGION_OVERRIDE}"
else
  log "Detecting AWS region via instance metadata (IMDSv2)"
  TOKEN=$$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  export AWS_DEFAULT_REGION
  AWS_DEFAULT_REGION=$$(curl -s -H "X-aws-ec2-metadata-token: $${TOKEN}" \
    "http://169.254.169.254/latest/meta-data/placement/region")
fi
export AWS_REGION="$${AWS_DEFAULT_REGION}"
log "Using AWS region: $${AWS_REGION}"

log "Installing base packages (zip, unzip, net-tools, jq, tar)"
dnf install -y zip unzip net-tools jq tar shadow-utils
command -v curl >/dev/null 2>&1 || fail "curl not found - expected curl-minimal to be preinstalled on AL2023"

if ! command -v aws >/dev/null 2>&1; then
  log "Installing AWS CLI v2"
  tmp_awscli=$$(mktemp -d)
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$$(uname -m).zip" -o "$${tmp_awscli}/awscliv2.zip"
  unzip -q "$${tmp_awscli}/awscliv2.zip" -d "$${tmp_awscli}"
  "$${tmp_awscli}/aws/install"
  rm -rf "$${tmp_awscli}"
else
  log "AWS CLI already installed ($$(aws --version 2>&1)), skipping"
fi

if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker engine"
  dnf install -y docker
else
  log "Docker already installed, skipping engine install"
fi

log "Enabling and starting docker service"
systemctl enable --now docker

mkdir -p /usr/local/lib/docker/cli-plugins
if [[ ! -x /usr/local/lib/docker/cli-plugins/docker-compose ]]; then
  log "Installing docker compose CLI plugin"
  curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
else
  log "docker-compose plugin already present, skipping"
fi

docker compose version || fail "docker compose plugin did not install correctly"

WORKDIR=$$(mktemp -d)
cd "$${WORKDIR}"

log "Downloading $${LAYOUT_SCRIPT} from s3://$${S3_BUCKET}/$${S3_DEPLOY_PREFIX}/"
aws s3 cp "s3://$${S3_BUCKET}/$${S3_DEPLOY_PREFIX}/$${LAYOUT_SCRIPT}" .
log "Running $${LAYOUT_SCRIPT}"
bash "./$${LAYOUT_SCRIPT}"

id "$${SERVICE_USER}" >/dev/null 2>&1 || fail "Service account '$${SERVICE_USER}' was not created by $${LAYOUT_SCRIPT}"

chgrp example "$${LOG_FILE}" "$${TRACE_LOG}" 2>/dev/null || true
chmod 664 "$${LOG_FILE}" "$${TRACE_LOG}" 2>/dev/null || true

log "Switching to '$${SERVICE_USER}' user for application install + launch"

INSTALL_RELEASE_ARGS=""
if [[ -n "$${INSTALL_RELEASE}" ]]; then
  INSTALL_RELEASE_ARGS="--release $${INSTALL_RELEASE}"
fi

runuser -l "$${SERVICE_USER}" -c "
set -euo pipefail

export BASH_XTRACEFD=9
PS4='+ [example \$(date \"+%Y-%m-%d %H:%M:%S\")] [example-inline:\${LINENO}] '
set -x

APP_DIR='$${APP_DIR}'
ROSTER_DIR='$${ROSTER_DIR}'
INSTALL_SCRIPT='$${INSTALL_SCRIPT}'
S3_BUCKET='$${S3_BUCKET}'
S3_DEPLOY_PREFIX='$${S3_DEPLOY_PREFIX}'
ENV_SECRET_NAME='$${ENV_SECRET_NAME}'
LAUNCH_SCRIPT_REL='$${LAUNCH_SCRIPT_REL}'
AWS_REGION='$${AWS_REGION}'
ENABLE_ECR_LOGIN='$${ENABLE_ECR_LOGIN}'
ECR_REGISTRY='$${ECR_REGISTRY}'
ECR_REGION='$${ECR_REGION}'
export AWS_REGION AWS_DEFAULT_REGION=\"\${AWS_REGION}\"
export E2E_DEPLOY_S3_BUCKET=\"\${S3_BUCKET}\"

echo '==> [example] cd to' \"\${APP_DIR}\"
mkdir -p \"\${APP_DIR}\"
cd \"\${APP_DIR}\"

echo '==> [example] Downloading' \"\${INSTALL_SCRIPT}\" 'from S3'
aws s3 cp \"s3://\${S3_BUCKET}/\${S3_DEPLOY_PREFIX}/\${INSTALL_SCRIPT}\" .

echo '==> [example] Running' \"\${INSTALL_SCRIPT}\"
bash \"\${INSTALL_SCRIPT}\" $${INSTALL_RELEASE_ARGS}

[[ -d \"\${ROSTER_DIR}\" ]] || { echo '!!! ERROR:' \"\${ROSTER_DIR}\" 'was not created by' \"\${INSTALL_SCRIPT}\"; exit 1; }

cd \"\${ROSTER_DIR}\"

echo '==> [example] Fetching .env content from Secrets Manager secret:' \"\${ENV_SECRET_NAME}\"
aws secretsmanager get-secret-value \
  --secret-id \"\${ENV_SECRET_NAME}\" \
  --query 'SecretString' \
  --output text > .env

[[ -s .env ]] || { echo '!!! ERROR: .env file is empty after fetching from Secrets Manager'; exit 1; }
chmod 600 .env
echo '==> [example] .env written ('\$(wc -l < .env)' lines)'

if [[ \"\${ENABLE_ECR_LOGIN}\" == \"true\" ]]; then
  echo '==> [example] Logging in to ECR:' \"\${ECR_REGISTRY}\" '(region' \"\${ECR_REGION}\"')'
  aws ecr get-login-password --region \"\${ECR_REGION}\" \
    | docker login --username AWS --password-stdin \"\${ECR_REGISTRY}\" \
    || { echo '!!! ERROR: docker login to ECR failed'; exit 1; }
fi

echo '==> [example] Launching docker compose stack (automation-s3)'
bash \"\${LAUNCH_SCRIPT_REL}\"
"

log "Deployment finished successfully. Full log at $${LOG_FILE}"

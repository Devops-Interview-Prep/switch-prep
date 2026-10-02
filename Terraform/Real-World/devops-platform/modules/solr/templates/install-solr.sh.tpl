#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/solr-install.log | logger -t solr-install -s 2>/dev/console) 2>&1

# ── 1. System packages ────────────────────────────────────────────────────────
dnf update -y
dnf install -y java-11-amazon-corretto-headless wget tar curl jq lsof

# ── 2. Solr user ──────────────────────────────────────────────────────────────
useradd -r -m -d /var/solr -s /sbin/nologin solr 2>/dev/null || true
mkdir -p /var/solr/data /var/log/solr /opt/solr-configs
chown -R solr:solr /var/solr /var/log/solr

# ── 3. Download & install Solr ────────────────────────────────────────────────
SOLR_VERSION="${solr_version}"
SOLR_TARBALL="solr-$${SOLR_VERSION}.tgz"
SOLR_MIRROR="https://archive.apache.org/dist/solr/solr/$${SOLR_VERSION}/$${SOLR_TARBALL}"

cd /tmp
wget -q "$${SOLR_MIRROR}" -O "$${SOLR_TARBALL}"

# Extract install script from the tarball and run it
tar xzf "$${SOLR_TARBALL}" "solr-$${SOLR_VERSION}/bin/install_solr_service.sh" --strip-components=2
bash install_solr_service.sh "$${SOLR_TARBALL}" \
  -i /opt \
  -d /var/solr \
  -u solr \
  -s solr \
  -p "${solr_port}" \
  -f

# ── 4. Configure Solr environment ─────────────────────────────────────────────
cat > /etc/default/solr.in.sh << 'EOF'
SOLR_JAVA_HOME=/usr/lib/jvm/java-11
SOLR_HEAP="${heap_size_gb}g"
SOLR_PORT=${solr_port}
SOLR_HOME=/var/solr/data
SOLR_LOGS_DIR=/var/log/solr
SOLR_PID_DIR=/var/solr
SOLR_OPTS="$SOLR_OPTS -Dlog4j2.formatMsgNoLookups=true"
EOF

# ── 5. Start Solr ─────────────────────────────────────────────────────────────
service solr start

# Wait until Solr is ready (up to 120s)
for i in $(seq 1 24); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" "http://localhost:${solr_port}/solr/admin/ping" 2>/dev/null || echo 000)
  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "404" ]; then
    echo "Solr is up (HTTP $HTTP_CODE)"
    break
  fi
  echo "Waiting for Solr... attempt $i (HTTP $HTTP_CODE)"
  sleep 5
done

# ── 6. Configure basic auth ───────────────────────────────────────────────────
%{ if solr_auth_user != "" && solr_auth_password != "" ~}
cat > /tmp/setup-security.json << 'SECEOF'
{
  "authentication": {
    "blockUnknown": false,
    "class": "solr.BasicAuthPlugin",
    "credentials": {
      "${solr_auth_user}": "$(java -cp /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/solr-core-*.jar org.apache.solr.security.Sha256AuthenticationProvider ${solr_auth_password} 2>/dev/null | tail -1)"
    }
  },
  "authorization": {
    "class": "solr.RuleBasedAuthorizationPlugin",
    "permissions": [{"name":"all","role":"admin"}],
    "user-role": {"${solr_auth_user}":"admin"}
  }
}
SECEOF

AUTH_HEADER="Authorization: Basic $(echo -n '${solr_auth_user}:${solr_auth_password}' | base64)"
curl -s -X POST "http://localhost:${solr_port}/api/cluster/security/authentication" \
  -H "Content-Type: application/json" \
  -d '{"set-user":{"${solr_auth_user}":"${solr_auth_password}"}}' || true
%{ endif ~}

# ── 7. Create collections ─────────────────────────────────────────────────────
%{ for collection in collections ~}
echo "Creating collection: ${collection}"
curl -s "http://localhost:${solr_port}/solr/admin/collections?action=CREATE&name=${collection}&numShards=1&replicationFactor=1&maxShardsPerNode=1&wt=json" \
  || true

# Apply schema if provided
%{ if lookup(collection_configs, collection, "") != "" ~}
SCHEMA_JSON='${lookup(collection_configs, collection, "")}'
if [ -n "$${SCHEMA_JSON}" ]; then
  echo "$${SCHEMA_JSON}" > /tmp/schema-${collection}.json
  curl -s -X POST "http://localhost:${solr_port}/solr/${collection}/schema" \
    -H "Content-Type: application/json" \
    -d "@/tmp/schema-${collection}.json" || true
fi
%{ endif ~}

%{ endfor ~}

# ── 8. Enable auto-start on reboot ───────────────────────────────────────────
systemctl enable solr 2>/dev/null || chkconfig solr on 2>/dev/null || true

echo "✓ Solr ${solr_version} installation and configuration complete"
echo "  Collections: ${join(", ", collections)}"
echo "  Port: ${solr_port}"
echo "  Heap: ${heap_size_gb}g"

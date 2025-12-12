#!/bin/bash
# Upload Devfile Registry zu lokaler Nexus-Instanz
# Nexus URL: http://192.168.2.14:8081
# Repository: devfiles

NEXUS_URL="http://192.168.2.14:8081"
REPO="devfiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nexus Credentials (anpassen!)
NEXUS_USER="${NEXUS_USER:-admin}"
NEXUS_PASS="${NEXUS_PASS:-admin123}"

echo "=== Uploading Devfile Registry to Nexus ==="
echo "Nexus URL: ${NEXUS_URL}"
echo "Repository: ${REPO}"
echo ""

# Upload index.json
echo "Uploading index.json..."
curl -u "${NEXUS_USER}:${NEXUS_PASS}" \
  -X PUT \
  "${NEXUS_URL}/repository/${REPO}/index.json" \
  -H "Content-Type: application/json" \
  --data-binary @"${SCRIPT_DIR}/index.json" \
  -w "\nHTTP Status: %{http_code}\n"

# Upload devfile.yaml
echo ""
echo "Uploading stacks/python-workspace/devfile.yaml..."
curl -u "${NEXUS_USER}:${NEXUS_PASS}" \
  -X PUT \
  "${NEXUS_URL}/repository/${REPO}/stacks/python-workspace/devfile.yaml" \
  -H "Content-Type: text/yaml" \
  --data-binary @"${SCRIPT_DIR}/stacks/python-workspace/devfile.yaml" \
  -w "\nHTTP Status: %{http_code}\n"

# Upload Python icon
echo ""
echo "Uploading images/python.svg..."
curl -u "${NEXUS_USER}:${NEXUS_PASS}" \
  -X PUT \
  "${NEXUS_URL}/repository/${REPO}/images/python.svg" \
  -H "Content-Type: image/svg+xml" \
  --data-binary @"${SCRIPT_DIR}/images/python.svg" \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "=== Upload complete ==="
echo ""
echo "Verify uploads:"
echo "  curl ${NEXUS_URL}/repository/${REPO}/index.json"
echo "  curl ${NEXUS_URL}/repository/${REPO}/stacks/python-workspace/devfile.yaml"
echo "  curl ${NEXUS_URL}/repository/${REPO}/images/python.svg"

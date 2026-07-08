#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env.testflight"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}"
  echo "Copy .env.testflight.example to .env.testflight and fill in production values."
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

if [[ -z "${SHAQONET_API_BASE_URL:-}" ]]; then
  echo "SHAQONET_API_BASE_URL is required."
  exit 1
fi

if [[ "${SHAQONET_API_BASE_URL}" == http://localhost* || "${SHAQONET_API_BASE_URL}" == http://127.0.0.1* || "${SHAQONET_API_BASE_URL}" == http://10.0.2.2* ]]; then
  echo "TestFlight builds cannot use a local API URL: ${SHAQONET_API_BASE_URL}"
  exit 1
fi

if [[ "${SHAQONET_API_BASE_URL}" != https://* ]]; then
  echo "TestFlight API URL should use HTTPS: ${SHAQONET_API_BASE_URL}"
  exit 1
fi

if [[ -z "${SHAQONET_SUPABASE_URL:-}" || -z "${SHAQONET_SUPABASE_ANON_KEY:-}" ]]; then
  echo "Supabase URL and anon key are required for TestFlight builds."
  exit 1
fi

cd "${ROOT_DIR}"

PUBSPEC_VERSION="$(awk '/^version: / {print $2; exit}' pubspec.yaml)"
PUBSPEC_BUILD_NAME="${PUBSPEC_VERSION%%+*}"
PUBSPEC_BUILD_NUMBER="${PUBSPEC_VERSION##*+}"

flutter build ipa \
  --release \
  --build-name="${BUILD_NAME:-${PUBSPEC_BUILD_NAME}}" \
  --build-number="${BUILD_NUMBER:-${PUBSPEC_BUILD_NUMBER}}" \
  --dart-define="SHAQONET_API_BASE_URL=${SHAQONET_API_BASE_URL}" \
  --dart-define="SHAQONET_SUPABASE_URL=${SHAQONET_SUPABASE_URL}" \
  --dart-define="SHAQONET_SUPABASE_ANON_KEY=${SHAQONET_SUPABASE_ANON_KEY}"

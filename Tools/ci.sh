#!/usr/bin/env bash
# Runs the "Build iOS" workflow for a branch on the GitHub macOS runner and reports the result.
#
#   Tools/ci.sh build <branch>   dispatch Build iOS on origin/<branch>, wait, print the run URL and
#                                conclusion; on failure print the failed job logs and exit 1; on
#                                success download the Gooby-screenshots artifact to
#                                $GOOBY_SHOTS/<run_id>/ and list the PNGs.
#   Tools/ci.sh logs <run_id>    print the last 150 log lines of every failed job of a run.
#   Tools/ci.sh shots <run_id>   download the Gooby-screenshots artifact of a run.
#
# GOOBY_SHOTS defaults to <main checkout>/.agents/shots (ignored, shared by all worktrees, and
# persistent; /tmp is not kept between agent commands).
# Uses only `gh api` (gh run list does not work in the agent sandbox).
set -euo pipefail

REPO="MedusaV9/MyGooby"
WORKFLOW="build-ios.yml"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLL=20
COMMON_GIT="$(git -C "${ROOT}" rev-parse --path-format=absolute --git-common-dir)"
SHOTS="${GOOBY_SHOTS:-$(dirname "${COMMON_GIT}")/.agents/shots}"

usage() {
  sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 2
}

failed_logs() {
  local run_id="$1" jobs job_id name
  jobs="$(gh api "repos/${REPO}/actions/runs/${run_id}/jobs" --jq '.jobs[] | select(.conclusion != "success" and .conclusion != "skipped" and .conclusion != null) | "\(.id)\t\(.name)"')"
  if [ -z "${jobs}" ]; then
    echo "No failed jobs in run ${run_id}."
    return 0
  fi
  while IFS=$'\t' read -r job_id name; do
    echo "===== failed job: ${name} (${job_id}) ====="
    gh api "repos/${REPO}/actions/jobs/${job_id}/logs" 2>/dev/null | tail -n 150 || echo "(log not available)"
  done <<< "${jobs}"
}

job_summary() {
  gh api "repos/${REPO}/actions/runs/$1/jobs" --jq '.jobs[] | "  job \(.name): \(.conclusion // .status)"'
}

download_shots() {
  local run_id="$1" artifact dest
  artifact="$(gh api "repos/${REPO}/actions/runs/${run_id}/artifacts" --jq '.artifacts[] | select(.name == "Gooby-screenshots") | .id' | head -n 1)"
  if [ -z "${artifact}" ]; then
    echo "No Gooby-screenshots artifact in run ${run_id}."
    return 1
  fi
  dest="${SHOTS}/${run_id}"
  rm -rf "${dest}"
  mkdir -p "${dest}"
  gh api "repos/${REPO}/actions/artifacts/${artifact}/zip" > "${dest}/shots.zip"
  (cd "${dest}" && unzip -q -o shots.zip && rm -f shots.zip)
  echo "Screenshots in ${dest}:"
  find "${dest}" -name '*.png' | sort
}

build() {
  local branch="$1" sha since run_id="" state status conclusion url waited=0
  git -C "${ROOT}" fetch -q origin "${branch}"
  sha="$(git -C "${ROOT}" rev-parse "origin/${branch}")"
  since="$(python3 -c 'import datetime as d; print((d.datetime.now(d.timezone.utc) - d.timedelta(seconds=30)).strftime("%Y-%m-%dT%H:%M:%SZ"))')"
  echo "Dispatching ${WORKFLOW} on ${branch} at ${sha}"
  gh api -X POST "repos/${REPO}/actions/workflows/${WORKFLOW}/dispatches" -f ref="${branch}"

  while [ -z "${run_id}" ]; do
    sleep "${POLL}"
    waited=$((waited + POLL))
    run_id="$(gh api "repos/${REPO}/actions/runs?event=workflow_dispatch&branch=${branch}&per_page=10" \
      --jq ".workflow_runs[] | select(.head_sha == \"${sha}\" and .created_at >= \"${since}\") | .id" | tail -n 1)"
    if [ -z "${run_id}" ] && [ "${waited}" -ge 300 ]; then
      echo "No run for ${sha} appeared within 5 minutes."
      exit 1
    fi
  done
  echo "Run ${run_id}: https://github.com/${REPO}/actions/runs/${run_id}"

  while true; do
    state="$(gh api "repos/${REPO}/actions/runs/${run_id}" --jq '"\(.status) \(.conclusion // "")"')"
    status="${state%% *}"
    if [ "${status}" = "completed" ]; then break; fi
    sleep "${POLL}"
  done
  conclusion="${state#* }"
  url="$(gh api "repos/${REPO}/actions/runs/${run_id}" --jq '.html_url')"
  echo "${url}"
  echo "conclusion: ${conclusion}"
  job_summary "${run_id}"

  if [ "${conclusion}" != "success" ]; then
    failed_logs "${run_id}"
    exit 1
  fi
  if ! gh api "repos/${REPO}/actions/runs/${run_id}/artifacts" --jq '.artifacts[].name' | grep -qx 'Gooby-unsigned-ipa'; then
    echo "Run ${run_id} succeeded but has no Gooby-unsigned-ipa artifact."
    exit 1
  fi
  echo "artifact: Gooby-unsigned-ipa"
  # The screenshots job may fail without failing the run (continue-on-error); show why.
  failed_logs "${run_id}"
  download_shots "${run_id}" || true
}

case "${1:-}" in
  build) [ $# -eq 2 ] || usage; build "$2" ;;
  logs) [ $# -eq 2 ] || usage; failed_logs "$2" ;;
  shots) [ $# -eq 2 ] || usage; download_shots "$2" ;;
  *) usage ;;
esac

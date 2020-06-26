#!/bin/bash
set -euo pipefail

declare -a SSH_ARGS

USERNAME="$( ni get -p '{ .username }' )"
[ -z "${USERNAME}" ] && USERNAME=relay

ni get -p '{ .connection.sshKey }' >/workspace/id_rsa
if [[ "$( wc -c </workspace/id_rsa )" -gt 0 ]]; then
  chmod 0400 /workspace/id_rsa
  SSH_ARGS+=( -i /workspace/id_rsa )
fi

PORT="$( ni get -p '{ .port }' )"
[ -n "${PORT}" ] && SSH_ARGS+=( -p "${PORT}" )

SHELL="$( ni get -p '{ .shell }' )"
[ -z "${SHELL}" ] && SHELL=sh

INPUT="$( ni get | jq -r '.input // [] | join("\n")' )"

ERROR_BEHAVIOR="$( ni get -p '{ .errorBehavior }' )"
[ -z "${ERROR_BEHAVIOR}" ] && ERROR_BEHAVIOR=terminate

ni get -p '{ .knownHosts }' >/workspace/known_hosts
[[ "$( wc -c </workspace/known_hosts )" -gt 0 ]] && SSH_ARGS+=( -o UserKnownHostsFile=/workspace/known_hosts )

STRICT_HOST_KEY_CHECKING="$( ni get -p '{ .strictHostKeyChecking }' )"
[[ "${STRICT_HOST_KEY_CHECKING}" == "false" ]] && SSH_ARGS+=( -o StrictHostKeyChecking=false )

case "${ERROR_BEHAVIOR}" in
terminate|ignore|collect)
  ;;
*)
  ni log fatal 'spec: `errorBehavior` must be one of "terminate", "ignore", or "collect"'
  ;;
esac

ERRORS=0

declare -a SERVERS="( $( ni get | jq -r '.on | if type == "array" then .[] else . end' ) )"
for SERVER in "${SERVERS[@]}"; do
  ni log info "running on ${SERVER}..."
  ssh "${SSH_ARGS[@]}" -- "${USERNAME}@${SERVER}" "${SHELL}" -c "${INPUT}" || {
    EXITCODE="$?"
    case "${ERROR_BEHAVIOR}" in
    terminate)
      exit $EXITCODE
      ;;
    collect)
      ERRORS=$((ERRORS + 1))
      ;;
    esac
  }
done

if [[ "${ERRORS}" -gt 0 ]]; then
  ni log fatal "${ERRORS} error(s) occurred"
fi

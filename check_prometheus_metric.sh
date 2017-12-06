#!/bin/bash
#
# check_prometheus_metric.sh - Nagios plugin wrapper for checking Prometheus
#                              metrics. Requires curl and jq to be in $PATH.

# Avoid locale complications:
export LC_ALL=C

# Default configuration:
CURL=$(which curl) || { echo 'Unable to find path for curl. Please install jq and ensure it is in your $PATH' ; exit 2 ; }
ECHO=echo
JQ=$(which jq) || { echo 'Unable to find path for jq. Please install jq and ensure it is in your $PATH' ; exit 2 ; }
XARGS=xargs
COMPARISON_METHOD=ge
NAN_OK="false"
NAGIOS_INFO="false"
PROMETHEUS_QUERY_TYPE="scalar"

# Nagios status codes:
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3


function usage {

  cat <<'EoL'

  check_prometheus_metric.sh - Nagios plugin wrapper for checking Prometheus
                               metrics. Requires curl and jq to be in $PATH.

  Usage:
  check_prometheus_metric.sh -H HOST -q QUERY -w INT -c INT -n NAME [-m METHOD] [-O] [-i] [-t QUERY_TYPE]

  options:
    -H HOST          URL of Prometheus host to query.
    -q QUERY         Prometheus query, in single quotes, that returns by default a float or int (see -t).
    -w INT           Warning level value (must be zero or positive).
    -c INT           Critical level value (must be zero or positive).
    -n NAME          A name for the metric being checked.
    -m METHOD        Comparison method, one of gt, ge, lt, le, eq, ne.
                     (Defaults to ge unless otherwise specified.)
    -O               Accept NaN as an "OK" result .
    -i               Print the extra metric information into the Nagios message.
    -t QUERY_TYPE    Prometheus query return type: scalar (default) or vector.
                     The first element of the vector is used for the check.

EoL
}


function process_command_line {

  while getopts ':H:q:w:c:m:n:Oit:' OPT "$@"
  do
    case ${OPT} in
      H)        PROMETHEUS_SERVER="$OPTARG" ;;
      q)        PROMETHEUS_QUERY="$OPTARG" ;;
      n)        METRIC_NAME="$OPTARG" ;;

      m)        if [[ ${OPTARG} =~ ^([lg][et]|eq|ne)$ ]]
                then
                  COMPARISON_METHOD=${OPTARG}
                else
                  NAGIOS_SHORT_TEXT="invalid comparison method: ${OPTARG}"
                  NAGIOS_LONG_TEXT="$(usage)"
                  exit
                fi
                ;;

      c)        if [[ ${OPTARG} =~ ^[0-9]+$ ]]
                then
                  CRITICAL_LEVEL=${OPTARG}
                else
                  NAGIOS_SHORT_TEXT='-c CRITICAL_LEVEL requires an integer'
                  NAGIOS_LONG_TEXT="$(usage)"
                  exit
                fi
                ;;

      w)        if [[ ${OPTARG} =~ ^[0-9]+$ ]]
                then
                  WARNING_LEVEL=${OPTARG}
                else
                  NAGIOS_SHORT_TEXT='-w WARNING_LEVEL requires an integer'
                  NAGIOS_LONG_TEXT="$(usage)"
                  exit
                fi
                ;;

      O)        NAN_OK="true"
                ;;

      i)        NAGIOS_INFO="true"
                ;;

      t)        if [[ ${OPTARG} =~ ^(scalar|vector)$ ]]
                then
                  PROMETHEUS_QUERY_TYPE=${OPTARG}
                else
                  NAGIOS_SHORT_TEXT="invalid comparison method: ${OPTARG}"
                  NAGIOS_LONG_TEXT="$(usage)"
                  exit
                fi
                ;;

      \?)       NAGIOS_SHORT_TEXT="invalid option: -$OPTARG"
                NAGIOS_LONG_TEXT="$(usage)"
                exit
                ;;

      \:)       NAGIOS_SHORT_TEXT="-$OPTARG requires an arguement"
                NAGIOS_LONG_TEXT="$(usage)"
                exit
                ;;
    esac
  done

  # check for missing parameters
  if [[ -z ${PROMETHEUS_SERVER} ]] ||
     [[ -z ${PROMETHEUS_QUERY} ]] ||
     [[ -z ${PROMETHEUS_QUERY_TYPE} ]] ||
     [[ -z ${METRIC_NAME} ]] ||
     [[ -z ${WARNING_LEVEL} ]] ||
     [[ -z ${CRITICAL_LEVEL} ]]
  then
    NAGIOS_SHORT_TEXT='missing required option'
    NAGIOS_LONG_TEXT="$(usage)"
    exit
  fi
}

function on_exit {

  if [[ -z ${NAGIOS_STATUS} ]]
  then
    NAGIOS_STATUS=UNKNOWN
  fi

  if [[ -z ${NAGIOS_SHORT_TEXT} ]]
  then
    NAGIOS_SHORT_TEXT='an unknown error occured'
  fi

  printf '%s - %s\n' ${NAGIOS_STATUS} "${NAGIOS_SHORT_TEXT}"

  if [[ -n ${NAGIOS_LONG_TEXT} ]]
  then
    printf '%s\n' "${NAGIOS_LONG_TEXT}"
  fi

  exit ${!NAGIOS_STATUS} # hint: an indirect variable reference
}


function get_prometheus_raw_result {

  local _RESULT

  _RESULT=$( ${CURL} -sgG --data-urlencode "query=${PROMETHEUS_QUERY}" "${PROMETHEUS_SERVER}/api/v1/query" | $JQ -r '.data.result' )
  printf '%s' "${_RESULT}"

}

function get_prometheus_scalar_result {

  local _RESULT

  _RESULT=$( ${ECHO} $1 | $JQ -r '.[1]' )

  # check result
  if [[ ${_RESULT} =~ ^-?[0-9]+\.?[0-9]*$ ]]
  then
    printf '%.0F' ${_RESULT} # return an int if result is a number
  else
    case "${_RESULT}" in
      +Inf) printf '%.0F' $(( ${WARNING_LEVEL} + ${CRITICAL_LEVEL} )) # something greater than either level
            ;;
      -Inf) printf -- '-1' # something smaller than any level
            ;;
      *)    printf '%s' "${_RESULT}" # otherwise return as a string
            ;;
    esac
  fi
}

function get_prometheus_vector_value {

  local _RESULT

  # return the value of the first element of the vector
  _RESULT=$( ${ECHO} $1 | $JQ -r '.[0].value?' )
  printf '%s' "${_RESULT}"

}

function get_prometheus_vector_metric {

  local _RESULT

  # return the metric information of the first element of the vector
  _RESULT=$( ${ECHO} $1 | $JQ -r '.[0].metric?' | ${XARGS} )
  printf '%s' "${_RESULT}"

}

# set up exit function
trap on_exit EXIT TERM

# process the cli options
process_command_line "$@"

# get the raw query from prometheus
PROMETHEUS_RAW_RESULT="$( get_prometheus_raw_result )"

# extract the metric value from the raw prometheus result
if [[ "${PROMETHEUS_QUERY_TYPE}" = "scalar" ]]
then
    PROMETHEUS_RESULT=$( get_prometheus_scalar_result "$PROMETHEUS_RAW_RESULT" )
    PROMETHEUS_METRIC=UNKNOWN
else
    PROMETHEUS_VALUE=$( get_prometheus_vector_value "$PROMETHEUS_RAW_RESULT" )
    PROMETHEUS_RESULT=$( get_prometheus_scalar_result "$PROMETHEUS_VALUE" )
    PROMETHEUS_METRIC=$( get_prometheus_vector_metric "$PROMETHEUS_RAW_RESULT" ) 
fi

# check the value
if [[ ${PROMETHEUS_RESULT} =~ ^-?[0-9]+$ ]]
then
  if eval [[ ${PROMETHEUS_RESULT} -${COMPARISON_METHOD} ${CRITICAL_LEVEL} ]]
  then
    NAGIOS_STATUS=CRITICAL
    NAGIOS_SHORT_TEXT="${METRIC_NAME} is ${PROMETHEUS_RESULT}"
  elif eval [[ ${PROMETHEUS_RESULT} -${COMPARISON_METHOD} $WARNING_LEVEL ]]
  then
    NAGIOS_STATUS=WARNING
    NAGIOS_SHORT_TEXT="${METRIC_NAME} is ${PROMETHEUS_RESULT}"
  else
    NAGIOS_STATUS=OK
    NAGIOS_SHORT_TEXT="${METRIC_NAME} is ${PROMETHEUS_RESULT}"
  fi
else
  if [[ "${NAN_OK}" = "true" && "${PROMETHEUS_RESULT}" = "NaN" ]]
  then
    NAGIOS_STATUS=OK
    NAGIOS_SHORT_TEXT="${METRIC_NAME} is ${PROMETHEUS_RESULT}"
  else    
    NAGIOS_SHORT_TEXT="unable to parse prometheus response"
    NAGIOS_LONG_TEXT="${METRIC_NAME} is ${PROMETHEUS_RESULT}"
  fi
fi
if [[ "${NAGIOS_INFO}" = "true" ]]
then
    NAGIOS_SHORT_TEXT="${NAGIOS_SHORT_TEXT}: ${PROMETHEUS_METRIC}"
fi

exit

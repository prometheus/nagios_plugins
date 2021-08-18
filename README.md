# nagios_plugins

Nagios plugin (in fact only one) for alerting on prometheus query results.

__This repository has been archived. Please use
[magenta-aps/check_prometheus_metric](https://github.com/magenta-aps/check_prometheus_metric)
instead, which is an an actively maintained fork with added features, designed
to be fully backwards compatible.__

Examples of command line usage:
```
PROMETHEUS_SERVER='http://demo.robustperception.io:9090'
QUERY_SCALAR_UP='scalar(up{instance="demo.robustperception.io:9100"})'
QUERY_VECTOR_UP='up{instance="demo.robustperception.io:9100"}'

bash check_prometheus_metric.sh -H $PROMETHEUS_SERVER -q $QUERY_SCALAR_UP -w 1 -c 1 -n $QUERY_SCALAR_UP -m lt
OK - scalar(up{instance="demo.robustperception.io:9100"}) is 1

bash check_prometheus_metric.sh -H $PROMETHEUS_SERVER -q $QUERY_SCALAR_UP -w 1 -c 1 -n $QUERY_SCALAR_UP -m lt -i
OK - scalar(up{instance="demo.robustperception.io:9100"}) is 1: UNKNOWN

bash check_prometheus_metric.sh -H $PROMETHEUS_SERVER -q $QUERY_VECTOR_UP -w 1 -c 1 -n $QUERY_VECTOR_UP -m lt -t vector
OK - up{instance="demo.robustperception.io:9100"} is 1

bash check_prometheus_metric.sh -H $PROMETHEUS_SERVER -q $QUERY_VECTOR_UP -w 1 -c 1 -n $QUERY_VECTOR_UP -m lt -t vector -i
OK - up{instance="demo.robustperception.io:9100"} is 1: { __name__: up, instance: demo.robustperception.io:9100, job: node }
```

You need to add the following commands to your Nagios configuration to use it:
```
define command {
    command_name check_prometheus
    command_line $USER1$/check_prometheus_metric.sh -H '$ARG1$' -q '$ARG2$' -w '$ARG3$' -c '$ARG4$' -n '$ARG5$' -m '$ARG6$'
}

# check_prometheus, treating a NaN result as ok
define command {
    command_name check_prometheus_nan_ok
    command_line $USER1$/check_prometheus_metric.sh -H '$ARG1$' -q '$ARG2$' -w '$ARG3$' -c '$ARG4$' -n '$ARG5$' -m '$ARG6$' -O
}

# check_prometheus, the first element of the vector is used for the check,
# printing the extra metric information into the Nagios message
define command {
    command_name check_prometheus_extra_info
    command_line $USER1$/check_prometheus_metric.sh -H '$ARG1$' -q '$ARG2$' -w '$ARG3$' -c '$ARG4$' -n '$ARG5$' -m '$ARG6$' -i -t vector
}
```

The `echo`, `xargs`, [`curl`](https://curl.haxx.se/) and the
[`jq`](https://stedolan.github.io/jq/) (version 1.4 or newer) commands must be installed for the plugin
to work.

## Usage

    check_prometheus_metric.sh - simple prometheus metric extractor for nagios
  
      usage:
      check_prometheus_metric.sh -H HOST -q QUERY -w INT -c INT -n NAME [-m METHOD] [-O] [-i] [-t QUERY_TYPE]
    
      options:
        -H HOST          URL of Prometheus host to query
        -q QUERY         Prometheus query, in single quotes, that returns by default a float or int (see -t)
        -w INT           Warning level value (must be zero or positive)
        -c INT           Critical level value (must be zero or positive)
        -n NAME          A name for the metric being checked
        -m METHOD        Comparison method, one of gt, ge, lt, le, eq, ne
                         (defaults to ge unless otherwise specified)
        -C CURL_OPTS     Additional flags to pass to curl.
                         Can be passed multiple times. Options and option values must be passed separately.
                         e.g. -C --conect-timetout -C 10 -C --cacert -C /path/to/ca.crt
        -O               Accept NaN as an "OK" result 
        -i               Print the extra metric information into the Nagios message
        -p               Add perfdata to check output
        -t QUERY_TYPE    Prometheus query return type: scalar (default) or vector.
                         The first element of the vector is used for the check.

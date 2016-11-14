# nagios_plugins

Nagios plugin (in fact only one) for alerting on prometheus query results.

Examples of command line usage:
```
PROMETHEUS_SERVER='http://demo.robustperception.io:9090'
QUERY_SCALAR_UP='scalar(up{instance="demo.robustperception.io:9100"})'
QUERY_DICTIONARY_UP='up{instance="demo.robustperception.io:9100"}'

bash check_prometheus_metric.sh -H $PROMETHEUS_SERVER -q $QUERY_SCALAR_UP -w 1 -c 1 -n $QUERY_SCALAR_UP -m lt
OK - scalar(up{instance="demo.robustperception.io:9100"}) is 1

bash check_prometheus_metric.sh -H $PROMETHEUS_SERVER -q $QUERY_SCALAR_UP -w 1 -c 1 -n $QUERY_SCALAR_UP -m lt -i
OK - scalar(up{instance="demo.robustperception.io:9100"}) is 1: UNKNOWN

bash check_prometheus_metric.sh -H $PROMETHEUS_SERVER -q $QUERY_DICTIONARY_UP -w 1 -c 1 -n $QUERY_DICTIONARY_UP -m lt -t dictionary
OK - up{instance="demo.robustperception.io:9100"} is 1

bash check_prometheus_metric.sh -H $PROMETHEUS_SERVER -q $QUERY_DICTIONARY_UP -w 1 -c 1 -n $QUERY_DICTIONARY_UP -m lt -t dictionary -i
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

# check_prometheus, printing the extra metric information into the Nagios message
define command {
    command_name check_prometheus_extra_info
    command_line $USER1$/check_prometheus_metric.sh -H '$ARG1$' -q '$ARG2$' -w '$ARG3$' -c '$ARG4$' -n '$ARG5$' -m '$ARG6$' -i -t dictionary
}
```

The [`curl`](https://curl.haxx.se/) and the
[`jq`](https://stedolan.github.io/jq/) command must be installed for the plugin
to work.

## Usage

    check_prometheus_metric.sh - simple prometheus metric extractor for nagios
  
      usage:
      check_prometheus_metric.sh -H HOST -q QUERY -w INT -c INT -n NAME [-m METHOD] [-O] [-i] [-t QUERY_TYPE]
    
      options:
        -H HOST          URL of Prometheus host to query
        -q QUERY         Prometheus query, in single quotes, that by default (see -t) returns a float or int
        -w INT           Warning level value (must be zero or positive)
        -c INT           Critical level value (must be zero or positive)
        -n NAME          A name for the metric being checked
        -m METHOD        Comparison method, one of gt, ge, lt, le, eq, ne
                         (defaults to ge unless otherwise specified)
        -O               Accept NaN as an "OK" result 
        -i               Print extra metric information into the Nagios message
        -t QUERY_TYPE    Prometheus query return type: scalar (default) or dictionary

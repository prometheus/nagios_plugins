# nagios_plugins

Nagios plugin (in fact only one) for alerting on prometheus query results.

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
```

The [`curl`](https://curl.haxx.se/) and the
[`jq`](https://stedolan.github.io/jq/) command must be installed for the plugin
to work.

## Usage

    check_prometheus_metric.sh - simple prometheus metric extractor for nagios
  
      usage:
      check_prometheus_metric.sh -H HOST -q QUERY -w INT -c INT -n NAME [-m METHOD] [-O]
    
      options:
        -H HOST     URL of Prometheus host to query, in single quotes
        -q QUERY    Prometheus query, in single quotes, that returns a float or int
        -w INT      Warning level value (must be zero or positive)
        -c INT      Critical level value (must be zero or positive)
        -n NAME     A name for the metric being checked
        -m METHOD   Comparison method, one of gt, ge, lt, le, eq, ne
                    (defaults to ge unless otherwise specified)
        -O          Accept NaN as an "OK" result 

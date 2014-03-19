# nagios_plugins

nagios plugins for alerting on prometheus query results

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

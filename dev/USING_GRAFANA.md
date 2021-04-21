# Using Grafana for Viewing Conjur, NGINX, and Postgres Metrics

## Getting Started 

To start the dev environment with Prometheus and Grafana support, use
the `--metrics` flag for the `start` script:

```
./start --metrics
```

## Using the Grafana UI

1. On a local browser, navigate to `localhost:2345`.
1. Log in as `admin`/`admin`.
1. Change `admin` password to whatever you'd like.
1. On left column, select Dashboards (window pane icon), and `Manage`.
1. Select `Prometheus Stats` dashboard from the "Dashboards" selection in
   the lower left.

## TODO

- Add custom metrics panes?

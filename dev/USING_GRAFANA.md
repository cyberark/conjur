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
1. On left column, select settings (gear icon), and `Data Sources`
1. Select `Add Data Source`
1. Select `Prometheus`
1. Select `Dashboards`.
1. Select `Import` for `Prometheus Stats`, `Prometheus 2.0 Stats`, and `Grafana metrics`.
1. Select `Settings`
1. Under `HTTP`, set URL to `http://localhost:9090`
1. Under `HTTP` select the `Access` drop-down menu, and select `Browser`.
1. Scroll down to the bottom, and select `Save & Test`. You should see
   "Data source is working".
1. On left column, select Dashboards (window pane icon), and `Manage`.
1. Select `Prometheus Stats` dashboard.

## TODO

- Store data storage and dashboard in conjur repo so that they are available
  at startup.
- Add custom metrics panes?

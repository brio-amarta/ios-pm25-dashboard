# PM2.5 Dashboard for iOS

A native SwiftUI client for the PM2.5 forecasting pipeline. The app is
read-only: it displays committed forecasts and evaluation statistics from
Supabase PostgREST and never connects directly to PostgreSQL.

## Screens

| Screen | Content | Supabase view |
|---|---|---|
| Overview | Pipeline health, current PM2.5, freshness, model version, pending and total forecasts, recent observations | `pipeline_metrics`, `actuals_recent` |
| Forecast | Next 24 hours, peak/average/range, changes at +1h/+6h/+24h, hourly values | `forecast_latest`, `actuals_recent` |
| Accuracy | Seven-day MAE and sample size, MAE by horizon, best/worst horizon | `pipeline_metrics`, `mae_by_horizon` |

Loading, empty, configuration, stale-data, partial-data, and network-error
states are included. Pull to refresh is available on every tab.

## Configure

1. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig`.
2. In Supabase **Settings > API**, copy the project reference and the
   publishable key (or legacy anon key).
3. Fill in `SUPABASE_PROJECT_ID` and `SUPABASE_ANON_KEY`.
4. Open `PM25Dashboard.xcodeproj` and run the `PM25Dashboard` scheme.

Do not put `DATABASE_URL`, the Postgres password, or a Supabase service-role
key in this project. `Secrets.xcconfig` is ignored by Git.

## API contract

The app expects these read-only views from the pipeline repository's
`sql/schema.sql`:

| View | Required fields |
|---|---|
| `pipeline_metrics` | `model_version`, `latest_actual`, `data_age_hours`, `latest_forecast`, `latest_retrain`, `total_forecasts`, `pending_forecasts`, `mae_7d`, `scored_predictions_7d` |
| `forecast_latest` | `target_ts`, `predicted`, `horizon_h`, `model_version`, `run_at` |
| `actuals_recent` | `ts`, `pm25`, `ingested_at` |
| `mae_by_horizon` | `horizon_h`, `n`, `mae` |

The app deliberately does not label PM2.5 values with an AQI category. That
requires choosing a regional standard and its averaging period first.

## Validation

Build from the command line with:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project PM25Dashboard.xcodeproj \
  -scheme PM25Dashboard \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```


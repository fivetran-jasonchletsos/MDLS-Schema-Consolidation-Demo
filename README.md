# MDLS Schema Consolidation

Chris Rudolph is using the `fivetran_sales_sandbox` account to land SQL Server
data into a Managed Data Lake Service destination called `chris_rudolph_gcs_mdls`.
He estimated 60-70 schemas in Slack; pulling the real data from the Fivetran API
(2026-07-15) shows the account actually has **467** `zzz_`-prefixed SQL Server
connectors, each landing a schema of **350 tables** — **163,450 physical tables**
in one destination. He needs all of it consolidated into something queryable.

Full writeup: [`docs/index.html`](docs/index.html)
New to this repo? Start here: [`docs/setup-runbook.html`](docs/setup-runbook.html) —
a step-by-step guide to installing Git/VS Code/dbt Fusion, cloning this repo, running it,
and taking ownership of it.

---

## Architecture

```
SQL Server x467  (ft_scale_db_0001 ... ft_scale_db_0467)
    Fivetran (467 zzz_ connectors, service: sql_server)
chris_rudolph_gcs_mdls  (MDLS destination, 467 schemas x 350 tables)
    dbt Labs -- dynamic relation discovery (dbt_utils), not hand-written models
transform/models/consolidated/  (350 unified models, one per table name)
    BI / agents / analysts
```

## Data

`reference/connector_inventory.json` holds the metadata pulled from the live
Fivetran API for this destination: connector count, schema/table naming
patterns, and setup/sync status breakdown. No credentials are stored anywhere
in this repository.

Note: 30 connectors are `setup_state: broken` and 447 are `sync_state: paused`.
That's a reconnect job in the Fivetran dashboard, independent of the
consolidation work below.

## Transformation layer

`transform/` is a dbt project. Two `dbt_utils` macros
(`get_relations_by_pattern` + `union_relations`) find and union every
`ft_table_####` table across the 467 `zzz_sql01_ft_scale_db_####` schemas.
`scripts/generate_consolidation_models.py` generates the 350 model files —
see [`transform/README.md`](transform/README.md) for how to run it and how
the macro works.

```bash
python3 scripts/generate_consolidation_models.py   # writes 350 model files
cd transform && dbt deps && dbt run --select consolidated
```

## Web page

`docs/index.html` is a static page walking through the problem, why it's risky
at this scale in production, and the consolidation pattern, grounded in the
real numbers above. No build step -- open it directly or serve `docs/` via
GitHub Pages.

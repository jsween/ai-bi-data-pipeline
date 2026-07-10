# AI-BI Data Pipeline

An end-to-end data engineering and business intelligence project demonstrating
a modern analytics stack: data ingestion, warehouse design, data quality,
and AI-assisted workflows feeding a BI visualization layer.


## Dashboards

### Looker Studio
Interactive dashboard covering revenue trends, product performance, delivery SLAs, and customer geography, built on top of the `reporting.rpt_order_items_summary` view and the `warehouse` fact tables.

[View live dashboard →](https://datastudio.google.com/u/0/reporting/aed1d70d-09e7-4f9f-a08f-bbefb02c8746/page/LZV3F)

![Looker Studio dashboard](docs/screenshots/looker_studio_dashboard.png)

### Metabase
The same set of visualizations recreated in Metabase (self-hosted via Docker), connected directly to the BigQuery warehouse — built to compare BI tooling on top of the same dimensional model.

![Metabase dashboard](docs/screenshots/metabase_dashboard.png)

## Stack
- **Warehouse:** Google BigQuery (GCP)
- **Storage:** Google Cloud Storage
- **Orchestration:** n8n (self-hosted)
- **BI / Visualization:** Metabase (self-hosted)
- **Language:** Python
- **Version Control:** GitHub

## Architecture
*Diagram coming soon*

## Project Phases
- [x] v1.0 — Ingest Olist e-commerce dataset, design star schema, build warehouse in BigQuery
- [ ] v2.0 — Add second data source (DataCo Supply Chain), demonstrate multi-source ingestion
- [ ] v3.0 — Add agentic AI workflows via n8n
- [ ] v4.0 — Metabase dashboards and reporting layer

## Data Sources
See [data/README.md](data/README.md) for source details and setup instructions.

## Data Warehouse Schema

The warehouse is modeled as a star schema (fact constellation) in BigQuery: three fact tables at different grains, sharing conformed dimensions.

```mermaid
erDiagram
    DIM_CUSTOMERS ||--o{ FACT_ORDER_ITEMS : "customer_unique_id"
    DIM_CUSTOMERS ||--o{ FACT_ORDER_PAYMENTS : "customer_unique_id"
    DIM_CUSTOMERS ||--o{ FACT_REVIEWS : "customer_unique_id"
    DIM_PRODUCTS ||--o{ FACT_ORDER_ITEMS : "product_id"
    DIM_SELLERS ||--o{ FACT_ORDER_ITEMS : "seller_id"
    DIM_DATE ||--o{ FACT_ORDER_ITEMS : "order_date_key"
    DIM_DATE ||--o{ FACT_ORDER_PAYMENTS : "order_date_key"
    DIM_DATE ||--o{ FACT_REVIEWS : "review_date_key"

    DIM_CUSTOMERS {
        string customer_unique_id PK
        string city
        string state
        string zip_code_prefix
        float lat
        float lng
    }
    DIM_PRODUCTS {
        string product_id PK
        string category_name
        int product_name_length
        int product_description_length
        int photos_qty
        float weight_g
        float length_cm
        float height_cm
        float width_cm
    }
    DIM_SELLERS {
        string seller_id PK
        string city
        string state
        string zip_code_prefix
        float lat
        float lng
    }
    DIM_DATE {
        int date_key PK
        date full_date
        int year
        int quarter
        int month
        string month_name
        int day_of_month
        int day_of_week
        string day_name
        int week_of_year
        bool is_weekend
    }
    FACT_ORDER_ITEMS {
        string order_id
        int item_sequence_number
        string order_status
        bool is_late_delivery
        string product_id FK
        string seller_id FK
        string customer_unique_id FK
        int order_date_key FK
        numeric price
        numeric freight_value
        numeric total_amount
    }
    FACT_ORDER_PAYMENTS {
        string order_id
        int payment_sequence_number
        string payment_type
        string customer_unique_id FK
        int order_date_key FK
        int payment_installments
        numeric payment_value
    }
    FACT_REVIEWS {
        string review_id
        string order_id
        string customer_unique_id FK
        int review_date_key FK
        int score
        string comment_title
        string comment_message
        int response_time_days
    }
```

The warehouse is modeled as a fact constellation rather than a single star: three fact tables — `fact_order_items`, `fact_order_payments`, and `fact_reviews` — sit at three different grains (line item, payment, and review respectively) and share a common set of conformed dimensions (`dim_customers`, `dim_products`, `dim_sellers`, `dim_date`). Payments and reviews are kept as their own fact tables rather than joined into `fact_order_items` because they're order-grain, not item-grain — folding them into the line-item fact would fan a single order's payment or review out across every item on that order, inflating totals. `dim_customers` is built at the `customer_unique_id` grain rather than `customer_id`, since Olist generates a new `customer_id` for every order; using it as the customer grain would make repeat buyers look like first-time customers on every purchase.

## Setup
*Instructions coming soon*

## Status
🚧 In Progress
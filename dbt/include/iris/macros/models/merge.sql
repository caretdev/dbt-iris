{% macro iris__get_merge_sql(target, source, unique_key, dest_columns, predicates) -%}

    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {{ sql_header if sql_header is not none }}

    insert or update {{ target }} ({{ dest_cols_csv }})
    select {{ dest_cols_csv }} from {{ source }}

{% endmacro %}

{% macro iris__get_insert_overwrite_merge_sql(target, source, dest_columns, predicates, include_sql_header) -%}

    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {{ sql_header if sql_header is not none and include_sql_header }}

    insert or update {{ target }} ({{ dest_cols_csv }})
    select {{ dest_cols_csv }} from {{ source }}

{% endmacro %}

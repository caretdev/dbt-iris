{% macro iris__get_incremental_append_sql(arg_dict) %}

  {% do return(get_insert_into_sql(arg_dict["target_relation"], arg_dict["temp_relation"], arg_dict["dest_columns"])) %}

{% endmacro %}

{% macro get_insert_into_sql(target_relation, temp_relation, dest_columns) %}

    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}

    insert into {{ target_relation }} ({{ dest_cols_csv }})
        select {{ dest_cols_csv }}
        from {{ temp_relation }}

{% endmacro %}

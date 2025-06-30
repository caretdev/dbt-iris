{% macro iris__get_delete_insert_merge_sql(target, source, unique_key, dest_columns, incremental_predicates) -%}
    {%- set dest_cols_csv = get_quoted_csv(dest_columns | map(attribute="name")) -%}
    {% if unique_key %}
        {% set as_list = '' %}
        {% set unique_key_list = [] %}
        {% if unique_key is string %}
        {% set unique_key = [unique_key] %}
        {% endif %}
        {% if (unique_key | length) > 1 %}
        {% set as_list = '$list' %}
        {% endif %}
        {% for key in unique_key -%}
        {% do unique_key_list.append("IFNULL(%s, '')" | format(key)) %}
        {% endfor %}
        {%- set unique_key_str = unique_key_list | join(', ') -%}
        {% call statement('delete') -%}
            delete from {{ target }} as DBT_INTERNAL_DEST
            where {{ as_list }}({{ unique_key_str }}) in (
                select distinct {{ as_list }}({{ unique_key_str }})
                from {{ source }} as DBT_INTERNAL_SOURCE
            )
            {%- if incremental_predicates %}
                {% for predicate in incremental_predicates %}
                    and {{ predicate }}
                {% endfor %}
            {%- endif -%}
        {%- endcall %}
    {% endif %}

    insert into {{ target }} ({{ dest_cols_csv }})
    select {{ dest_cols_csv }}
    from {{ source }}

{%- endmacro %}
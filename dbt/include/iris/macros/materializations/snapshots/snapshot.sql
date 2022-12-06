{% macro iris__snapshot_hash_arguments(args) -%}
    HASH('md5', {%- for arg in args -%}
        coalesce(cast({{ arg }} as varchar(50) ), '')
        {% if not loop.last %} || '|' || {% endif %}
    {%- endfor -%})
{%- endmacro %}

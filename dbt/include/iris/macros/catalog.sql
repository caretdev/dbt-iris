
{% macro iris__get_catalog(information_schema, schemas) -%}
    {%- call statement('catalog', fetch_result=True) -%}
    select
      $Namespace as "table_database",
      t.table_schema as "table_schema",
      t.table_name as "table_name",
      case
        when table_type = 'BASE TABLE' then 'table'
        when table_type = 'VIEW' then 'view'
        else table_type
      end as "table_type",
      null as "table_comment",
      null as "table_owner",
      c.column_name as "column_name",
      c.ordinal_position as "column_index",
      c.data_type as "column_type",
      null as "column_comment"
    from
      information_schema.tables t
    join
      information_schema.columns c on
      t.table_name = c.table_name
      and
      t.table_schema = c.table_schema
    where
      not t.table_type in ('SYSTEM TABLE', 'SYSTEM VIEW')
      -- and not t.table_schema %STARTSWITH 'Ens'
      and (
    {%- for schema in schemas -%}
      t.table_schema = '{{ schema }}'{%- if not loop.last %} or {% endif -%}
    {%- endfor -%}
      )
    order by column_index
    {%- endcall -%}

    {{ return(load_result('catalog').table) }}

{%- endmacro %}

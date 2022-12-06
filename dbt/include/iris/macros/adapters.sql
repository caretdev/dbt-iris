/* For examples of how to fill out the macros please refer to the postgres adapter and docs
postgres adapter macros: https://github.com/dbt-labs/dbt-core/blob/main/plugins/postgres/dbt/include/postgres/macros/adapters.sql
dbt docs: https://docs.getdbt.com/docs/contributing/building-a-new-adapter
*/

{% macro iris__get_binding_char() %}
  {{ return('?') }}
{% endmacro %}

{% macro iris__current_timestamp() -%}
  current_timestamp
{%- endmacro %}

{% macro iris__list_schemas(database) -%}
    {% call statement('list_schemas', fetch_result=True, auto_begin=False) -%}
        select schema_name
        from information_schema.schemata
        where not schema_name %STARTSWITH ('%')
          and not schema_name %STARTSWITH ('Ens')
    {%- endcall %}

    {{ return(load_result('list_schemas').table) }}
{% endmacro %}

{% macro iris__create_schema(schema_relation) -%}
  {# no-op #}
{% endmacro %}

{% macro create_function_hash() -%}
  {% call statement('_', auto_begin=False) -%}
    CREATE OR REPLACE FUNCTION HASH(alg VARCHAR(''), str VARCHAR(''))
    PROCEDURE
    RETURNS VARCHAR('')
    LANGUAGE PYTHON
    {
        import hashlib
        return hashlib.new(alg, str.encode()).hexdigest()
    }
  {%- endcall %}
{% endmacro %}

{% macro iris__drop_schema(relation) -%}
'''drops a schema in a target database.'''
  {# no-op #}
{% endmacro %}

{% macro iris__drop_relation(relation) -%}
    {% call statement('drop_relation', auto_begin=False) -%}
        drop {{ relation.type }} if exists {{ relation }}
    {%- endcall %}
{% endmacro %}

{% macro iris__check_schema_exists(database, schema) -%}
'''Checks if schema name exists and returns number or times it shows up.'''
  {# no-op #}
{% endmacro %}

{% macro iris__alter_column_type(relation, column_name, new_column_type) -%}
  {#
    1. Create a new column (w/ temp name and correct type)
    2. Copy data over to it
    3. Drop the existing column (cascade!)
    4. Rename the new column to existing column
  #}
  {%- set tmp_column = column_name + "__dbt_alter" -%}

  {% call statement('alter_column_type 1', fetch_result=False) %}
    alter table {{ relation }} add column {{ adapter.quote(tmp_column) }} {{ new_column_type }}
  {% endcall %}
  {% call statement('alter_column_type 2', fetch_result=False) %}
    update {{ relation }} set {{ adapter.quote(tmp_column) }} = {{ adapter.quote(column_name) }}
  {% endcall %}
  {% call statement('alter_column_type 3', fetch_result=False) %}
    alter table {{ relation }} drop column {{ adapter.quote(column_name) }} cascade
  {% endcall %}
  {% call statement('alter_column_type 4', fetch_result=False) %}
    alter table {{ relation }} modify {{ adapter.quote(tmp_column) }} rename {{ adapter.quote(column_name) }}
  {% endcall %}

{% endmacro %}

{% macro iris__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    select
      null as "database",
      table_name as name,
      table_schema as "schema",
      case when table_type = 'BASE TABLE' then 'table'
           when table_type = 'VIEW' then 'view'
           else table_type
      end as table_type
    from information_schema.tables
    where table_schema = '{{ schema_relation.schema if schema_relation.schema else "SQLUser" }}'
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}

{% macro iris__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}
      select
          column_name,
          data_type,
          character_maximum_length,
          numeric_precision,
          numeric_scale
      from information_schema.columns
      where table_name = '{{ relation.identifier }}'
        and table_schema = '{{ relation.schema if relation.schema else "SQLUser" }}'
      order by ordinal_position

  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}


{% macro iris__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
  /* create_view_as */
  create table {{ relation }} as
    {{ sql }}

{%- endmacro %}

{% macro iris__create_table_as(temporary, relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}
  {% if temporary: -%}
    {% call statement('drop_relation') %}
      drop table if exists {{ relation }} cascade %DELDATA
    {% endcall %}
  {%- endif %}
  /* create_table_as */
  {{ sql_header if sql_header is not none }}
  create {% if temporary: -%}global temporary{%- endif %} table
    {{ relation }}
  as
    {{ sql }}
{%- endmacro %}

{% macro iris__rename_relation(from_relation, to_relation) -%}
  {% set target_name = adapter.quote_as_configured(to_relation.identifier, 'identifier') %}
  {% call statement('drop_relation') %}
    drop table if exists {{ to_relation }} cascade
  {% endcall %}
  {% call statement('rename_relation') -%}
    alter table {{ from_relation }} rename {{ target_name }}
  {%- endcall %}
{% endmacro %}

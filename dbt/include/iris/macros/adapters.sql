/* For examples of how to fill out the macros please refer to the postgres adapter and docs
postgres adapter macros: https://github.com/dbt-labs/dbt-core/blob/main/plugins/postgres/dbt/include/postgres/macros/adapters.sql
dbt docs: https://docs.getdbt.com/docs/contributing/building-a-new-adapter
*/

{% macro iris__get_binding_char() %}
  {{ return('?') }}
{% endmacro %}

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
    RETURNS VARCHAR(1024)
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
           when table_type = 'GLOBAL TEMPORARY' then 'table'
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
          NULLIF(CAST(character_maximum_length as INT),0) character_maximum_length,
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

{% macro iris__create_table_as(temporary, relation, compiled_code, language='sql') -%}
  {%- if language == 'sql' -%}
    {%- set sql_header = config.get('sql_header', none) -%}
    {% if temporary: -%}
      {% call statement('drop_relation') %}
        drop table if exists {{ relation }} cascade %DELDATA
      {% endcall %}
    {%- endif %}
    /* create_table_as */
    {{ sql_header if sql_header is not none }}
    create {% if temporary: -%}global temporary{%- endif %} table {{ relation }} as
      {{ compiled_code }}
  {%- elif language == 'python' -%}
    {{ py_write_table(compiled_code=compiled_code, target_relation=relation, temporary=temporary) }}
  {%- else -%}
      {% do exceptions.raise_compiler_error("iris__create_table_as macro didn't get supported language, it got %s" % language) %}
  {%- endif -%}
{%- endmacro %}

{% macro iris__rename_relation(from_relation, to_relation) -%}
  {% call statement('drop_relation') %}
    drop {{ to_relation.type }} if exists {{ to_relation }} cascade
  {% endcall %}
  {% if not from_relation.type %}
    {% do exceptions.raise_database_error("Cannot rename a relation with a blank type: " ~ from_relation.identifier) %}
  {% elif from_relation.type == 'table' %}
    {% set target_name = adapter.quote_as_configured(to_relation.identifier, 'identifier') %}
    {% do drop_related_view(from_relation) %}
    {%- set target_name = adapter.quote_as_configured(to_relation.identifier, 'identifier') %}
    {% call statement('rename_relation') -%}
      alter {{ from_relation.type }} {{ from_relation }} rename {{ target_name }}
    {%- endcall %}
  {%- elif from_relation.type == 'view' -%}
    {% do adapter.dispatch('rename_view')(from_relation, to_relation) %}
  {% else -%}
    {% do exceptions.raise_database_error("Unknown type '" ~ from_relation.type ~ "' for relation: " ~ from_relation.identifier) %}
  {% endif %}

{% endmacro %}

{% macro drop_related_view(relation) %}

  {% set to_drop = get_related_views(relation) %}

  {% if to_drop is not none and to_drop|length > 0 %}
    {% for view in to_drop %}
      {% set view_relation = api.Relation.create(
          identifier=view['VIEW_NAME'],
          schema=view['VIEW_SCHEMA'],
          database=relation.database,
          type='view') %}
      {{ drop_relation_if_exists(view_relation) }}
    {% endfor %}
  {% endif %}

{% endmacro %}

{% macro get_related_views(relation) %}
  {% call statement('list_tables', fetch_result=True) %}
    SELECT VIEW_SCHEMA,VIEW_NAME
    FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE
    WHERE TABLE_SCHEMA='{{ relation.schema }}' AND TABLE_NAME='{{ relation.identifier }}'
  {% endcall %}
  {{ return(load_result('list_tables').table) }}
{% endmacro %}

{# {% macro iris__rename_relation(from_relation, to_relation) -%}
  {% set target_name = adapter.quote_as_configured(to_relation.identifier, 'identifier') %}
  {{ print("!!!! rename_relation: " ~ from_relation.type ~ ":" ~ from_relation.identifier ~ " to " ~ to_relation.type ~ ":" ~ to_relation) }}
  {% call statement('rename_relation') -%}
    alter table {{ from_relation.render() }} rename {{ target_name }}
  {%- endcall %}
{% endmacro %} #}

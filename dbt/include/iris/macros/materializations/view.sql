{%- materialization view, adapter='iris' -%}

  {%- set identifier = model['alias'] -%}

  {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
  {%- set target_relation = api.Relation.create(identifier=identifier, schema=schema, database=database,
                                                type='view') -%}

  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  {% if old_relation is not none %}
    {{ adapter.drop_relation(old_relation) }}
  {% endif %}

  -- build model
  {% call statement('main') -%}
    {{ create_view_as(target_relation, sql) }}
  {%- endcall %}

  {% do persist_docs(target_relation, model) %}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  {{ adapter.commit() }}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization -%}

{% macro iris__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
  /* create_view_as */
  CREATE OR REPLACE VIEW {{ relation }}
  {# create table {{ relation }} #}
  as {{ sql }}

{%- endmacro %}

{% macro iris__rename_view(from_relation, to_relation) -%}
  {% set sql = adapter.dispatch("get_view_definition")(from_relation) %}
  {% call statement('rename_view_main') -%}
    {{ get_create_view_as_sql(to_relation, sql) }}
  {%- endcall %}
  {{ drop_relation_if_exists(from_relation) }}
{% endmacro %}


{% macro iris__get_view_definition(relation) %}
  {% set sql = adapter.dispatch("get_view_definition_sql")(relation) %}
  {% call statement('view_definition', fetch_result=true, auto_begin=false) %}
    {{ sql }}
  {% endcall %}
  {% set result = load_result('view_definition').data %}
  {% if result %}
    {{ return("\r\n".join(result[0][0].split('\r\n')[1:None]).strip()) }}
  {% else %}
    {{ return('') }}
  {% endif %}
{% endmacro %}

{% macro iris__get_view_definition_sql(relation) %}
  SELECT VIEW_DEFINITION
  FROM INFORMATION_SCHEMA.VIEWS
  WHERE TABLE_SCHEMA = '{{ relation.schema if relation.schema else "SQLUser" }}'
    AND TABLE_NAME = '{{ relation.identifier }}'
{% endmacro %}

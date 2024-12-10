{% materialization table, adapter='iris', supported_languages=['sql', 'python']-%}

  {%- set language = model['language'] -%}

  {%- set existing_relation = load_cached_relation(this) -%}
  {%- set target_relation = this.incorporate(type='table') %}
  {%- set intermediate_relation =  make_intermediate_relation(target_relation) -%}
  -- the intermediate_relation should not already exist in the database; get_relation
  -- will return None in that case. Otherwise, we get a relation that we can drop
  -- later, before we try to use this name for the current operation
  {%- set preexisting_intermediate_relation = load_cached_relation(intermediate_relation) -%}
  /*
      See ../view/view.sql for more information about this relation.
  */
  {%- set backup_relation_type = 'table' if existing_relation is none else existing_relation.type -%}
  {%- set backup_relation = make_backup_relation(target_relation, backup_relation_type) -%}
  -- as above, the backup_relation should not already exist
  {%- set preexisting_backup_relation = load_cached_relation(backup_relation) -%}
  -- grab current tables grants config for comparision later on
  {% set grant_config = config.get('grants') %}

  -- drop the temp relations if they exist already in the database
  {{ drop_relation_if_exists(preexisting_intermediate_relation) }}
  {{ drop_relation_if_exists(preexisting_backup_relation) }}

  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  -- build model
  {% call statement('main', language=language) -%}
    {{ create_table_as(False, intermediate_relation, compiled_code, language) }}
  {%- endcall %}

  -- cleanup
  {% if existing_relation is not none %}
     /* Do the equivalent of rename_if_exists. 'existing_relation' could have been dropped
        since the variable was first set. */
    {% set existing_relation = load_cached_relation(existing_relation) %}
    {% if existing_relation is not none %}
        {{ adapter.rename_relation(existing_relation, backup_relation) }}
    {% endif %}
  {% endif %}

  {{ adapter.rename_relation(intermediate_relation, target_relation) }}

  {% do create_indexes(target_relation) %}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  {% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
  {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}

  {% do persist_docs(target_relation, model) %}

  -- `COMMIT` happens here
  {{ adapter.commit() }}

  -- finally, drop the existing/backup relation after the commit
  {{ drop_relation_if_exists(backup_relation) }}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}

{% macro py_write_table(compiled_code, target_relation, temporary=False) %}
{{ compiled_code }}

try:
  import pandas
except:
  raise Exception("Missing required dependency: pandas")

try:
  from sqlalchemy import create_engine
  import intersystems_iris
except:
  raise Exception("Missing required dependencies: sqlalchemy, sqlalchemy-iris")

class DataFrame(pandas.DataFrame):
    def limit(self, num):
        return DataFrame(self.iloc[:num])

    def filter(self, condition):
        return DataFrame(self[condition])

class IRISSession:
    default_schema = 'SQLUser'

    def __init__(self) -> None:
        self.engine = create_engine('iris+emb:///')

    def table(self, full_name) -> DataFrame:
        [schema, table] = full_name.split('.') if '.' in full_name else [self.default_schema, full_name]
        df = pandas.read_sql_table(table, self.engine, schema=schema)
        return DataFrame(df)

    def to_sql(self, df, table, schema):
        df.to_sql(table, self.engine, if_exists='replace', schema=schema)

session = IRISSession()
dbt = dbtObj(session.table)
df = model(dbt, session)
session.to_sql(df, '{{ target_relation.identifier }}', '{{ target_relation.schema }}')
return "OK"
{% endmacro %}

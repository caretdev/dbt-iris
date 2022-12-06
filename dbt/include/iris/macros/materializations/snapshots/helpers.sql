{% macro iris__create_columns(relation, columns) %}
  {% for column in columns %}
    {% call statement() %}
      alter table {{ relation }} add column "{{ column.name }}" {{ column.data_type }}
    {% endcall %}
  {% endfor %}
{% endmacro %}

{% macro default__get_true_sql() %}
    {{ return('1=1') }}
{% endmacro %}

{% macro default__build_snapshot_table(strategy, sql) %}

    select *,
        {{ strategy.scd_id }} as dbt_scd_id,
        {{ strategy.updated_at }} as dbt_updated_at,
        {{ strategy.updated_at }} as dbt_valid_from,
        null as dbt_valid_to
    from (
        {{ sql }}
    ) sbq

{% endmacro %}

{% macro iris__snapshot_staging_table(strategy, source_sql, target_relation) -%}
select * from (
    select
        'insert' as dbt_change_type,
        source_data.*

    from (

        select
            *,
            {{ strategy.unique_key }} as dbt_unique_key,
            {{ strategy.updated_at }} as dbt_updated_at,
            {{ strategy.updated_at }} as dbt_valid_from,
            null as dbt_valid_to,
            {{ strategy.scd_id }} as dbt_scd_id

        from ( {{ source_sql }} )

    ) as source_data
    left outer join (
        select *,
            {{ strategy.unique_key }} as dbt_unique_key

        from {{ target_relation }}
        where dbt_valid_to is null

    ) as snapshotted_data on snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
    where snapshotted_data.dbt_unique_key is null
        or (
            snapshotted_data.dbt_unique_key is not null
        and (
            {{ strategy.row_changed }}
        )
    )
) as insertions
union all
select * from (
    select
        'update' as dbt_change_type,
        source_data.*,
        snapshotted_data.dbt_scd_id

    from (
        select
            *,
            {{ strategy.unique_key }} as dbt_unique_key,
            {{ strategy.updated_at }} as dbt_updated_at,
            {{ strategy.updated_at }} as dbt_valid_from,
            {{ strategy.updated_at }} as dbt_valid_to

        from ( {{ source_sql }} )

    ) as source_data
    join (
        select *,
            {{ strategy.unique_key }} as dbt_unique_key

        from {{ target_relation }}

    ) as snapshotted_data on snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
    where snapshotted_data.dbt_valid_to is null
    and (
        {{ strategy.row_changed }}
    )
) as updates
{%- if strategy.invalidate_hard_deletes %}
union all
select * from (
    select
        'delete' as dbt_change_type,
        source_data.*,
        {{ snapshot_get_time() }} as dbt_valid_from,
        {{ snapshot_get_time() }} as dbt_updated_at,
        {{ snapshot_get_time() }} as dbt_valid_to,
        snapshotted_data.dbt_scd_id

    from (
        select *,
            {{ strategy.unique_key }} as dbt_unique_key

        from {{ target_relation }}
        where dbt_valid_to is null

    ) as snapshotted_data
    left join (
        select
            *,
            {{ strategy.unique_key }} as dbt_unique_key
        from ( {{ source_sql }} )
    ) as source_data on snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
    where source_data.dbt_unique_key is null
) as deletes
{%- endif %}

{%- endmacro %}

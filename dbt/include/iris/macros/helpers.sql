{% macro iris__load_csv_rows(model, agate_table) %}

  {% set batch_size = get_batch_size() %}

  {% set cols_sql = get_seed_column_quoted_csv(model, agate_table.column_names) %}
  {% set bindings = [] %}

  {% set statements = [] %}

  {% for chunk in agate_table.rows | batch(batch_size) %}
      {% set bindings = [] %}

      {% for row in chunk %}
          {% do bindings.append(row[:]) %}
      {% endfor %}

      {% set sql %}
          insert into {{ this.render() }} ({{ cols_sql }}) values
          ({%- for column in agate_table.column_names -%}
              {{ get_binding_char() }}
              {%- if not loop.last%},{%- endif %}
          {%- endfor -%})
      {% endset %}

      {% do adapter.add_query(sql, bindings=bindings, abridge_sql_log=True) %}

      {% if loop.index0 == 0 %}
          {% do statements.append(sql) %}
      {% endif %}
  {% endfor %}

  {# Return SQL so we can render it out into the compiled files #}
  {{ return(statements[0]) }}
{% endmacro %}

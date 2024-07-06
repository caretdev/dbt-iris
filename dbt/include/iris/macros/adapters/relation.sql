{% macro iris__suffix() %}
  {{ return("__" ~ (invocation_id | replace("-",""))) }}
{% endmacro %}

{% macro iris__make_intermediate_relation(base_relation, suffix) %}
    {{ return(default__make_temp_relation(base_relation, iris__suffix())) }}
{% endmacro %}

{% macro iris__make_temp_relation(base_relation, suffix) %}
    {%- set temp_identifier = base_relation.identifier ~ iris__suffix() -%}
    {%- set temp_relation = base_relation.incorporate(
                                path={"identifier": temp_identifier}) -%}

    {{ return(temp_relation) }}
{% endmacro %}

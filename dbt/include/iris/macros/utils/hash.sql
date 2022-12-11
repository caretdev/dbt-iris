{% macro default__hash(field) -%}
  hash('md5', cast({{ field }} as {{ api.Column.translate_type('string') }}))
{%- endmacro %}
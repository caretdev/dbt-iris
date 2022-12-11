{% macro iris__split_part(string_text, delimiter_text, part_number) -%}
  $PIECE({{ string_text }},{{ delimiter_text }},{{ part_number }})
{%- endmacro %}

{% macro get_roles() %}
  {% call statement('all_roles', auto_begin=False, fetch_result=true) -%}
    select ROLE_NAME from %SQL_Manager.Roles() where not ROLE_NAME %STARTSWITH '%'
  {%- endcall %}
  {{ return(load_result('all_roles').table | map(attribute='ROLE_NAME')) }}
{% endmacro %}

{% macro get_users() %}
  {% call statement('all_users', auto_begin=False, fetch_result=true) -%}
    select USERNAME from %SQL_Manager.Users()
  {%- endcall %}
  {{ return(load_result('all_users').table | map(attribute='USERNAME')) }}
{% endmacro %}

{% macro iris__get_show_grant_sql(relation) %}
  select grantee,privilege_type
  from (
    select
      r.ROLE_NAME grantee,
      pr.granted_by grantor,
      pr.PRIVILEGE privilege_type,
      $Piece(pr.NAME, '.', 1) table_schema,
      $Piece(pr.NAME, '.', 2) table_name
    from %SQL_Manager.Roles() r, %SQL_Manager.RolePrivileges(r.ROLE_NAME) pr
    union all
    select
      u.USERNAME grantee,
      pu.granted_by grantor,
      pu.PRIVILEGE privilege_type,
      $Piece(pu.NAME, '.', 1) table_schema,
      $Piece(pu.NAME, '.', 2) table_name
    from %SQL_Manager.Users() r, %SQL_Manager.UserPrivs(u.USERNAME) pu
  ) where grantor = $username
      and grantee != $username
      and table_schema = '{{ relation.schema }}'
      and table_name = '{{ relation.identifier }}'
{% endmacro %}

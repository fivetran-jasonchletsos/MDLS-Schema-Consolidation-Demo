{% macro get_scale_relations(table_name) %}
  {#-
    Returns every relation across the 467 zzz_sql01_ft_scale_db_#### schemas
    that contains a table literally named `table_name` (e.g. 'ft_table_0001').
    One call replaces manually enumerating 467 schemas by hand.
  -#}
  {{ return(dbt_utils.get_relations_by_pattern(
      schema_pattern=var('source_schema_pattern'),
      table_pattern=table_name,
      database=var('source_database')
  )) }}
{% endmacro %}

{% macro consolidate_scale_table(table_name) %}
  {#-
    Unions `table_name` across every matching zzz_ schema into one relation,
    tagging each row with which source schema it came from.
  -#}
  {%- set relations = get_scale_relations(table_name) -%}
  with unioned as (
    {{ dbt_utils.union_relations(relations=relations) }}
  )
  select
    *,
    regexp_substr(_dbt_source_relation, 'zzz_sql01_ft_scale_db_(\\d+)', 1, 1, 'e', 1) as source_scale_db_id
  from unioned
{% endmacro %}

view: sequences {
  sql_table_name: public.sequences ;;
  
  dimension: sequence_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.sequence_id ;;
  }
  
  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }
  
  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }
  
  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }
  
  measure: count {
    type: count_distinct
    sql: ${sequence_id} ;;
  }
}

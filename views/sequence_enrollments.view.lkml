view: sequence_enrollments {
  sql_table_name: public.sequence_enrollments ;;
  
  dimension: enrollment_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.enrollment_id ;;
  }
  
  dimension: sequence_id {
    type: string
    sql: ${TABLE}.sequence_id ;;
  }
  
  dimension: contact_id {
    type: string
    sql: ${TABLE}.contact_id ;;
  }
  
  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }
  
  dimension: is_active {
    type: yesno
    sql: ${status} IN ('ACTIVE', 'ENROLLED') ;;
  }
  
  dimension_group: enrolled {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.enrolled_at ;;
  }
  
  dimension_group: completed {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.completed_at ;;
  }
  
  measure: count {
    type: count_distinct
    sql: ${enrollment_id} ;;
  }
  
  measure: active_enrollments {
    type: count_distinct
    sql: ${enrollment_id} ;;
    filters: [is_active: "yes"]
  }
  
  measure: enrolled_contacts {
    type: count_distinct
    sql: ${contact_id} ;;
    filters: [is_active: "yes"]
  }
}

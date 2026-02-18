view: deals {
  sql_table_name: public.deals ;;
  
  dimension: deal_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.deal_id ;;
  }
  
  dimension: deal_name {
    type: string
    sql: ${TABLE}.deal_name ;;
  }
  
  dimension: amount {
    type: number
    sql: ${TABLE}.amount ;;
    value_format_name: usd
  }
  
  dimension: stage {
    type: string
    sql: ${TABLE}.stage ;;
  }
  
  dimension: pipeline {
    type: string
    sql: ${TABLE}.pipeline ;;
  }
  
  dimension: owner {
    type: string
    sql: ${TABLE}.owner ;;
  }
  
  dimension: num_scheduled_meetings {
    type: number
    sql: ${TABLE}.num_scheduled_meetings ;;
  }
  
  dimension: has_meeting {
    type: yesno
    sql: ${num_scheduled_meetings} > 0 ;;
  }
  
  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }
  
  dimension_group: close {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.close_date ;;
  }
  
  measure: count {
    type: count_distinct
    sql: ${deal_id} ;;
  }
  
  measure: total_amount {
    type: sum
    sql: ${amount} ;;
    value_format_name: usd
  }
  
  measure: deals_with_meetings {
    type: count_distinct
    sql: ${deal_id} ;;
    filters: [has_meeting: "yes"]
  }
}

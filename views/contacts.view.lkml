view: contacts {
  sql_table_name: public.contacts ;;
  
  dimension: hubspot_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.hubspot_id ;;
  }
  
  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
  }
  
  dimension: first_name {
    type: string
    sql: ${TABLE}.first_name ;;
  }
  
  dimension: last_name {
    type: string
    sql: ${TABLE}.last_name ;;
  }
  
  dimension: full_name {
    type: string
    sql: CONCAT(${first_name}, ' ', ${last_name}) ;;
  }
  
  dimension: company {
    type: string
    sql: ${TABLE}.company ;;
  }
  
  dimension: hubspot_owner_id {
    type: number
    sql: ${TABLE}.hubspot_owner_id ;;
  }
  
  dimension: job_title {
    type: string
    sql: ${TABLE}.job_title ;;
  }
  
  dimension: lifecycle_stage {
    type: string
    sql: ${TABLE}.lifecycle_stage ;;
  }
  
  dimension: lead_status {
    type: string
    sql: ${TABLE}.lead_status ;;
  }
  
  dimension: hubspot_score {
    type: number
    sql: ${TABLE}.hubspot_score ;;
  }
  
  dimension: is_qualified {
    type: yesno
    sql: ${hubspot_score} >= 7 
      OR ${lead_status} IN ('Qualified', 'MQL', 'SQL')
      OR ${lifecycle_stage} IN ('marketingqualifiedlead', 'salesqualifiedlead') ;;
  }
  
  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }
  
  dimension_group: last_modified {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.hs_last_modified ;;
  }
  
  measure: count {
    type: count_distinct
    sql: ${hubspot_id} ;;
    drill_fields: [hubspot_id, full_name, email, company, hubspot_owner_id]
  }
  
  measure: qualified_count {
    type: count_distinct
    sql: ${hubspot_id} ;;
    filters: [is_qualified: "yes"]
  }
}

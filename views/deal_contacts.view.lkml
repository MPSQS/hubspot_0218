view: deal_contacts {
  sql_table_name: public.deal_contacts ;;
  
  dimension: pk {
    primary_key: yes
    hidden: yes
    sql: CONCAT(${deal_id}, '-', ${contact_id}) ;;
  }
  
  dimension: deal_id {
    type: string
    sql: ${TABLE}.deal_id ;;
  }
  
  dimension: contact_id {
    type: string
    sql: ${TABLE}.contact_id ;;
  }
  
  dimension: role {
    type: string
    sql: ${TABLE}.role ;;
  }
  
  dimension: is_primary {
    type: yesno
    sql: ${TABLE}.is_primary ;;
  }
  
  measure: count {
    type: count
  }
}

view: activities {
  sql_table_name: public.activities ;;
  
  dimension: activity_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.id ;;
  }
  
  dimension: contact_id {
    type: string
    sql: ${TABLE}.contact_id ;;
  }
  
  dimension: campaign_id {
    type: string
    sql: ${TABLE}.campaign_id ;;
  }
  
  dimension: channel {
    type: string
    sql: ${TABLE}.channel::text ;;
  }
  
  dimension: channel_label {
    type: string
    sql: CASE
      WHEN ${channel} = 'email' THEN 'Email'
      WHEN ${channel} = 'call' THEN 'Phone'
      WHEN ${channel} = 'linkedin_message' THEN 'LinkedIn'
      ELSE INITCAP(${channel})
    END ;;
  }
  
  dimension: subject {
    type: string
    sql: ${TABLE}.subject ;;
  }
  
  dimension: body {
    type: string
    sql: ${TABLE}.body_preview ;;
  }
  
  dimension: hubspot_owner_id {
    type: number
    sql: ${TABLE}.hubspot_owner_id ;;
  }
  
  dimension: call_disposition {
    type: string
    sql: ${TABLE}.call_disposition ;;
  }
  
  dimension: call_duration_seconds {
    type: number
    sql: ${TABLE}.duration_seconds ;;
  }
  
  dimension: call_connected_count {
    type: number
    sql: ${TABLE}.call_connected_count ;;
  }
  
  dimension: email_opened {
    type: yesno
    sql: ${TABLE}.email_opened ;;
  }
  
  dimension: email_clicked {
    type: yesno
    sql: ${TABLE}.email_clicked ;;
  }
  
  dimension: email_replied {
    type: yesno
    sql: ${TABLE}.email_replied ;;
  }
  
  dimension: is_engaged {
    type: yesno
    sql: ${email_opened} = true 
      OR ${email_clicked} = true 
      OR COALESCE(${call_connected_count}, 0) > 0 ;;
  }
  
  dimension: is_interested {
    type: yesno
    sql: ${email_replied} = true 
      OR ${call_disposition} IN ('interested', 'callback', 'positive', 'appointment set') ;;
  }
  
  dimension_group: activity {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.activity_timestamp ;;
  }
  
  measure: count {
    type: count_distinct
    sql: ${activity_id} ;;
  }
  
  measure: contact_count {
    type: count_distinct
    sql: ${contact_id} ;;
  }
  
  measure: engaged_contacts {
    type: count_distinct
    sql: ${contact_id} ;;
    filters: [is_engaged: "yes"]
  }
  
  measure: interested_contacts {
    type: count_distinct
    sql: ${contact_id} ;;
    filters: [is_interested: "yes"]
  }
}

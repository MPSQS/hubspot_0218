view: stale_contacts {
  derived_table: {
    sql: WITH contact_touch_summary AS (
      SELECT
        a.contact_id,
        COUNT(DISTINCT a.id) as touch_count,
        MAX(a.activity_timestamp::date) as last_activity_date,
        CURRENT_DATE - MAX(a.activity_timestamp::date) as days_since_last_activity
      FROM public.activities a
      WHERE a.contact_id IS NOT NULL
      GROUP BY a.contact_id
    )
    SELECT
      cts.contact_id,
      c.email,
      c.first_name,
      c.last_name,
      c.company,
      c.hubspot_owner_id,
      cts.touch_count,
      cts.last_activity_date,
      cts.days_since_last_activity,
      CASE
        WHEN cts.days_since_last_activity > 14 THEN 'Critical (14+ days)'
        WHEN cts.days_since_last_activity > 10 THEN 'High (10-14 days)'
        WHEN cts.days_since_last_activity > 7 THEN 'Medium (7-10 days)'
        ELSE 'Low (< 7 days)'
      END as urgency_level,
      CASE
        WHEN cts.days_since_last_activity > 14 THEN 4
        WHEN cts.days_since_last_activity > 10 THEN 3
        WHEN cts.days_since_last_activity > 7 THEN 2
        ELSE 1
      END as urgency_order
    FROM contact_touch_summary cts
    LEFT JOIN public.contacts c ON cts.contact_id = c.hubspot_id
    WHERE cts.touch_count BETWEEN 2 AND 3
      AND cts.days_since_last_activity > 7 ;;
  }
  
  dimension: contact_id {
    type: string
    sql: ${TABLE}.contact_id ;;
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
  
  dimension: touch_count {
    type: number
    sql: ${TABLE}.touch_count ;;
  }
  
  dimension_group: last_activity {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.last_activity_date ;;
  }
  
  dimension: days_since_last_activity {
    type: number
    sql: ${TABLE}.days_since_last_activity ;;
  }
  
  dimension: urgency_level {
    type: string
    sql: ${TABLE}.urgency_level ;;
    order_by_field: urgency_order
  }
  
  dimension: urgency_order {
    type: number
    sql: ${TABLE}.urgency_order ;;
    hidden: yes
  }
  
  measure: count {
    type: count_distinct
    sql: ${contact_id} ;;
    drill_fields: [full_name, email, company, hubspot_owner_id, touch_count, days_since_last_activity, urgency_level]
  }
  
  measure: critical_urgency_count {
    type: count_distinct
    sql: ${contact_id} ;;
    filters: [urgency_level: "Critical (14+ days)"]
  }
  
  measure: high_urgency_count {
    type: count_distinct
    sql: ${contact_id} ;;
    filters: [urgency_level: "High (10-14 days)"]
  }
}

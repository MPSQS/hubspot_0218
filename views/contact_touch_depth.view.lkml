view: contact_touch_depth {
  derived_table: {
    sql: SELECT
      a.contact_id,
      COUNT(DISTINCT a.id) as touch_count,
      CASE
        WHEN COUNT(DISTINCT a.id) BETWEEN 1 AND 3 THEN '1-3 Touches'
        WHEN COUNT(DISTINCT a.id) BETWEEN 4 AND 7 THEN '4-7 Touches'
        WHEN COUNT(DISTINCT a.id) BETWEEN 8 AND 12 THEN '8-12 Touches'
        WHEN COUNT(DISTINCT a.id) >= 13 THEN '13+ Touches'
        ELSE 'Unknown'
      END as touch_depth_bucket,
      CASE
        WHEN COUNT(DISTINCT a.id) BETWEEN 1 AND 3 THEN 1
        WHEN COUNT(DISTINCT a.id) BETWEEN 4 AND 7 THEN 2
        WHEN COUNT(DISTINCT a.id) BETWEEN 8 AND 12 THEN 3
        WHEN COUNT(DISTINCT a.id) >= 13 THEN 4
        ELSE 0
      END as touch_depth_bucket_order
    FROM public.activities a
    WHERE a.contact_id IS NOT NULL
    GROUP BY a.contact_id ;;
  }
  
  dimension: contact_id {
    type: string
    sql: ${TABLE}.contact_id ;;
  }
  
  dimension: touch_count {
    type: number
    sql: ${TABLE}.touch_count ;;
  }
  
  dimension: touch_depth_bucket {
    type: string
    sql: ${TABLE}.touch_depth_bucket ;;
    order_by_field: touch_depth_bucket_order
  }
  
  dimension: touch_depth_bucket_order {
    type: number
    sql: ${TABLE}.touch_depth_bucket_order ;;
    hidden: yes
  }
  
  measure: contacts_in_bucket {
    type: count_distinct
    sql: ${contact_id} ;;
    drill_fields: [contact_id, touch_count, touch_depth_bucket]
  }
  
  measure: total_contacts {
    type: count_distinct
    sql: ${contact_id} ;;
  }
  
  measure: bucket_percentage {
    type: number
    sql: 100.0 * ${contacts_in_bucket} / NULLIF(${total_contacts}, 0) ;;
    value_format_name: decimal_1
  }
}

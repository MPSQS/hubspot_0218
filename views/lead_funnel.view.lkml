view: lead_funnel {
  derived_table: {
    sql: WITH contact_activity_summary AS (
      SELECT
        c.hubspot_id as contact_id,
        COUNT(DISTINCT a.id) as touch_count,
        MAX(CASE WHEN a.email_opened = true OR a.email_clicked = true OR COALESCE(a.call_connected_count, 0) > 0 THEN 1 ELSE 0 END) as is_engaged,
        MAX(CASE WHEN a.email_replied = true OR a.call_disposition IN ('interested', 'callback', 'positive', 'appointment set') THEN 1 ELSE 0 END) as is_interested
      FROM public.contacts c
      LEFT JOIN public.activities a ON c.hubspot_id = a.contact_id
      GROUP BY c.hubspot_id
    ),
    contact_funnel_stages AS (
      SELECT DISTINCT
        c.hubspot_id as contact_id,
        1 as is_in_total_list,
        
        CASE WHEN (
          c.hubspot_score >= 7 
          OR c.lead_status IN ('Qualified', 'MQL', 'SQL')
          OR c.lifecycle_stage IN ('marketingqualifiedlead', 'salesqualifiedlead')
        ) THEN 1 ELSE 0 END as is_qualified,
        
        CASE WHEN EXISTS (
          SELECT 1 FROM public.sequence_enrollments se
          WHERE se.contact_id = c.hubspot_id
            AND se.status IN ('ACTIVE', 'ENROLLED')
        ) THEN 1 ELSE 0 END as is_in_sequence,
        
        COALESCE(cas.is_engaged, 0) as is_engaged,
        COALESCE(cas.is_interested, 0) as is_interested,
        
        CASE WHEN EXISTS (
          SELECT 1 FROM public.deal_contacts dc
          JOIN public.deals d ON dc.deal_id = d.deal_id
          WHERE dc.contact_id = c.hubspot_id AND d.num_scheduled_meetings > 0
        ) THEN 1 ELSE 0 END as is_meeting_booked
        
      FROM public.contacts c
      LEFT JOIN contact_activity_summary cas ON c.hubspot_id = cas.contact_id
    )
    SELECT * FROM contact_funnel_stages ;;
  }
  
  dimension: contact_id {
    type: string
    sql: ${TABLE}.contact_id ;;
  }
  
  dimension: is_in_total_list {
    type: number
    sql: ${TABLE}.is_in_total_list ;;
    hidden: yes
  }
  
  dimension: is_qualified {
    type: number
    sql: ${TABLE}.is_qualified ;;
    hidden: yes
  }
  
  dimension: is_in_sequence {
    type: number
    sql: ${TABLE}.is_in_sequence ;;
    hidden: yes
  }
  
  dimension: is_engaged {
    type: number
    sql: ${TABLE}.is_engaged ;;
    hidden: yes
  }
  
  dimension: is_interested {
    type: number
    sql: ${TABLE}.is_interested ;;
    hidden: yes
  }
  
  dimension: is_meeting_booked {
    type: number
    sql: ${TABLE}.is_meeting_booked ;;
    hidden: yes
  }
  
  measure: stage_1_total_list {
    type: sum
    sql: ${is_in_total_list} ;;
    label: "1. Total List"
    drill_fields: [contact_id]
  }
  
  measure: stage_2_qualified {
    type: sum
    sql: ${is_qualified} ;;
    label: "2. Qualified (ICP ≥7)"
    drill_fields: [contact_id]
  }
  
  measure: stage_3_in_sequence {
    type: sum
    sql: ${is_in_sequence} ;;
    label: "3. In Sequence"
    drill_fields: [contact_id]
  }
  
  measure: stage_4_engaged {
    type: sum
    sql: ${is_engaged} ;;
    label: "4. Engaged"
    drill_fields: [contact_id]
  }
  
  measure: stage_5_interested {
    type: sum
    sql: ${is_interested} ;;
    label: "5. Interested"
    drill_fields: [contact_id]
  }
  
  measure: stage_6_meeting_booked {
    type: sum
    sql: ${is_meeting_booked} ;;
    label: "6. Meeting Booked"
    drill_fields: [contact_id]
  }
  
  measure: conversion_1_to_2 {
    type: number
    sql: CASE WHEN ${stage_1_total_list} > 0
      THEN 100.0 * ${stage_2_qualified} / NULLIF(${stage_1_total_list}, 0)
      ELSE NULL END ;;
    value_format_name: decimal_1
    label: "Conv % (1→2)"
  }
  
  measure: conversion_2_to_3 {
    type: number
    sql: CASE WHEN ${stage_2_qualified} > 0
      THEN 100.0 * ${stage_3_in_sequence} / NULLIF(${stage_2_qualified}, 0)
      ELSE NULL END ;;
    value_format_name: decimal_1
    label: "Conv % (2→3)"
  }
  
  measure: conversion_3_to_4 {
    type: number
    sql: CASE WHEN ${stage_3_in_sequence} > 0
      THEN 100.0 * ${stage_4_engaged} / NULLIF(${stage_3_in_sequence}, 0)
      ELSE NULL END ;;
    value_format_name: decimal_1
    label: "Conv % (3→4)"
  }
  
  measure: conversion_4_to_5 {
    type: number
    sql: CASE WHEN ${stage_4_engaged} > 0
      THEN 100.0 * ${stage_5_interested} / NULLIF(${stage_4_engaged}, 0)
      ELSE NULL END ;;
    value_format_name: decimal_1
    label: "Conv % (4→5)"
  }
  
  measure: conversion_5_to_6 {
    type: number
    sql: CASE WHEN ${stage_5_interested} > 0
      THEN 100.0 * ${stage_6_meeting_booked} / NULLIF(${stage_5_interested}, 0)
      ELSE NULL END ;;
    value_format_name: decimal_1
    label: "Conv % (5→6)"
  }
}

view: lead_funnel_updated {
  # Section C: Lead Gen Funnel - 7 progressive stages with conversion rates
  # Contact-grain view with stage flags and conversion metrics
  
  derived_table: {
    sql: 
      SELECT
        c.hubspot_id as contact_id,
        c.email,
        c.first_name,
        c.last_name,
        c.company,
        c.hubspot_score,
        c.lifecycle_stage,
        c.lead_status,
        cc.campaign_id,
        COALESCE(cc.touch_count, 0) as touch_count,
        
        -- Stage 1: Total List (all contacts)
        1 as is_total_list,
        
        -- Stage 2: Qualified (ICP threshold: hubspot_score >= 7 OR qualified lifecycle/lead_status)
        CASE 
          WHEN c.hubspot_score >= 7 
            OR c.lifecycle_stage IN ('marketingqualifiedlead', 'salesqualifiedlead', 'opportunity') 
            OR c.lead_status IN ('qualified', 'open', 'in progress', 'contacted')
          THEN 1 
          ELSE 0 
        END as is_qualified,
        
        -- Stage 3: In Sequence (qualified contacts actively enrolled)
        CASE 
          WHEN (c.hubspot_score >= 7 
            OR c.lifecycle_stage IN ('marketingqualifiedlead', 'salesqualifiedlead', 'opportunity') 
            OR c.lead_status IN ('qualified', 'open', 'in progress', 'contacted'))
            AND se.enrollment_id IS NOT NULL 
            AND se.status = 'active'
          THEN 1 
          ELSE 0 
        END as is_in_sequence,
        
        -- Stage 4: Engaged (showing engagement activity)
        CASE 
          WHEN EXISTS (
            SELECT 1 FROM public.activities a 
            WHERE a.contact_id = c.hubspot_id 
            AND (
              a.email_opened = true 
              OR a.email_clicked = true 
              OR COALESCE(a.call_connected_count, 0) > 0
            )
          ) THEN 1 
          ELSE 0 
        END as is_engaged,
        
        -- Stage 5: Interested (marked as interested based on activities)
        CASE 
          WHEN EXISTS (
            SELECT 1 FROM public.activities a 
            WHERE a.contact_id = c.hubspot_id 
            AND (
              a.email_replied = true 
              OR a.call_disposition IN ('interested', 'callback', 'positive', 'appointment set')
            )
          ) THEN 1 
          ELSE 0 
        END as is_interested,
        
        -- Stage 6: Meeting Booked (has deal with scheduled meetings)
        CASE 
          WHEN EXISTS (
            SELECT 1 
            FROM public.deal_contacts dc
            JOIN public.deals d ON dc.deal_id = d.deal_id
            WHERE dc.contact_id = c.hubspot_id 
            AND d.num_scheduled_meetings > 0
          ) THEN 1 
          ELSE 0 
        END as is_meeting_booked
        
      FROM public.contacts c
      LEFT JOIN public.campaign_contacts cc ON c.hubspot_id = cc.contact_id
      LEFT JOIN public.sequence_enrollments se ON c.hubspot_id = se.contact_id AND se.status = 'active'
    ;;
  }
  
  # Primary Key
  dimension: contact_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.contact_id ;;
    hidden: yes
  }
  
  # Contact Information Dimensions
  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
  }
  
  dimension: full_name {
    type: string
    sql: CONCAT(${TABLE}.first_name, ' ', ${TABLE}.last_name) ;;
  }
  
  dimension: company {
    type: string
    sql: ${TABLE}.company ;;
  }
  
  dimension: campaign_id {
    type: string
    sql: ${TABLE}.campaign_id ;;
  }
  
  dimension: hubspot_score {
    type: number
    sql: ${TABLE}.hubspot_score ;;
  }
  
  dimension: lifecycle_stage {
    type: string
    sql: ${TABLE}.lifecycle_stage ;;
  }
  
  dimension: lead_status {
    type: string
    sql: ${TABLE}.lead_status ;;
  }
  
  # Stage Flag Dimensions (hidden - used for measures)
  dimension: is_total_list {
    type: number
    sql: ${TABLE}.is_total_list ;;
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
  
  # === STAGE MEASURES (Contact Counts) ===
  
  measure: stage_1_total_list {
    type: sum
    sql: ${is_total_list} ;;
    label: "1. Total List"
    description: "All contacts in the campaign"
    value_format_name: decimal_0
  }
  
  measure: stage_2_qualified {
    type: sum
    sql: ${is_qualified} ;;
    label: "2. Qualified"
    description: "Contacts meeting ICP threshold (score ≥7 or qualified status)"
    value_format_name: decimal_0
  }
  
  measure: stage_3_in_sequence {
    type: sum
    sql: ${is_in_sequence} ;;
    label: "3. In Sequence"
    description: "Qualified contacts actively enrolled in a sequence"
    value_format_name: decimal_0
  }
  
  measure: stage_4_engaged {
    type: sum
    sql: ${is_engaged} ;;
    label: "4. Engaged"
    description: "Contacts showing engagement (opened/clicked/connected)"
    value_format_name: decimal_0
  }
  
  measure: stage_5_interested {
    type: sum
    sql: ${is_interested} ;;
    label: "5. Interested"
    description: "Contacts marked as interested (replied/positive disposition)"
    value_format_name: decimal_0
  }
  
  measure: stage_6_meeting_booked {
    type: sum
    sql: ${is_meeting_booked} ;;
    label: "6. Meeting Booked"
    description: "Contacts with a booked meeting"
    value_format_name: decimal_0
  }
  
  # === CONVERSION RATE MEASURES ===
  
  measure: conversion_1_to_2 {
    type: number
    sql: CASE 
      WHEN ${stage_1_total_list} > 0 
      THEN 100.0 * ${stage_2_qualified} / NULLIF(${stage_1_total_list}, 0)
      ELSE 0 
    END ;;
    label: "Total List → Qualified %"
    description: "Conversion rate from Total List to Qualified"
    value_format_name: decimal_1
  }
  
  measure: conversion_2_to_3 {
    type: number
    sql: CASE 
      WHEN ${stage_2_qualified} > 0 
      THEN 100.0 * ${stage_3_in_sequence} / NULLIF(${stage_2_qualified}, 0)
      ELSE 0 
    END ;;
    label: "Qualified → In Sequence %"
    description: "Conversion rate from Qualified to In Sequence"
    value_format_name: decimal_1
  }
  
  measure: conversion_3_to_4 {
    type: number
    sql: CASE 
      WHEN ${stage_3_in_sequence} > 0 
      THEN 100.0 * ${stage_4_engaged} / NULLIF(${stage_3_in_sequence}, 0)
      ELSE 0 
    END ;;
    label: "In Sequence → Engaged %"
    description: "Conversion rate from In Sequence to Engaged"
    value_format_name: decimal_1
  }
  
  measure: conversion_4_to_5 {
    type: number
    sql: CASE 
      WHEN ${stage_4_engaged} > 0 
      THEN 100.0 * ${stage_5_interested} / NULLIF(${stage_4_engaged}, 0)
      ELSE 0 
    END ;;
    label: "Engaged → Interested %"
    description: "Conversion rate from Engaged to Interested"
    value_format_name: decimal_1
  }
  
  measure: conversion_5_to_6 {
    type: number
    sql: CASE 
      WHEN ${stage_5_interested} > 0 
      THEN 100.0 * ${stage_6_meeting_booked} / NULLIF(${stage_5_interested}, 0)
      ELSE 0 
    END ;;
    label: "Interested → Meeting Booked %"
    description: "Conversion rate from Interested to Meeting Booked"
    value_format_name: decimal_1
  }
  
  # === OVERALL FUNNEL METRICS ===
  
  measure: overall_conversion {
    type: number
    sql: CASE 
      WHEN ${stage_1_total_list} > 0 
      THEN 100.0 * ${stage_6_meeting_booked} / NULLIF(${stage_1_total_list}, 0)
      ELSE 0 
    END ;;
    label: "Overall Conversion %"
    description: "Overall conversion rate from Total List to Meeting Booked"
    value_format_name: decimal_1
  }
  
  measure: total_contacts {
    type: count_distinct
    sql: ${contact_id} ;;
    label: "Total Contacts"
    description: "Total unique contacts in the funnel"
  }
}

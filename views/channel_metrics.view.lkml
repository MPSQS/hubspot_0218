view: channel_metrics {
  derived_table: {
    sql: WITH channel_responses AS (
      SELECT
        a.channel::text as channel,
        a.hubspot_owner_id,
        COUNT(DISTINCT a.contact_id) as contacts_touched,
        COUNT(DISTINCT CASE 
          WHEN COALESCE(a.email_replied, false) = true 
            OR COALESCE(a.email_clicked, false) = true
            OR COALESCE(a.call_connected_count, 0) > 0
          THEN a.contact_id 
        END) as contacts_responded
      FROM public.activities a
      WHERE a.channel::text IN ('email', 'call', 'linkedin_message')
      GROUP BY a.channel::text, a.hubspot_owner_id
    ),
    meeting_attribution AS (
      SELECT
        a.contact_id,
        a.channel::text as channel,
        a.hubspot_owner_id,
        a.activity_timestamp as activity_date,
        d.created_at as deal_created_at,
        ROW_NUMBER() OVER (
          PARTITION BY dc.contact_id, d.deal_id 
          ORDER BY a.activity_timestamp DESC
        ) as recency_rank
      FROM public.activities a
      JOIN public.deal_contacts dc ON a.contact_id = dc.contact_id
      JOIN public.deals d ON dc.deal_id = d.deal_id
      WHERE d.num_scheduled_meetings > 0
        AND a.activity_timestamp <= d.created_at
        AND a.channel::text IN ('email', 'call', 'linkedin_message')
    ),
    meeting_counts AS (
      SELECT
        channel,
        hubspot_owner_id,
        COUNT(DISTINCT contact_id) as meetings_generated
      FROM meeting_attribution
      WHERE recency_rank = 1
      GROUP BY channel, hubspot_owner_id
    )
    SELECT
      COALESCE(cr.channel, mc.channel) as channel,
      COALESCE(cr.hubspot_owner_id, mc.hubspot_owner_id) as hubspot_owner_id,
      COALESCE(cr.contacts_touched, 0) as contacts_touched,
      COALESCE(cr.contacts_responded, 0) as contacts_responded,
      COALESCE(mc.meetings_generated, 0) as meetings_generated,
      CASE 
        WHEN COALESCE(cr.contacts_touched, 0) > 0 
        THEN 100.0 * COALESCE(cr.contacts_responded, 0) / cr.contacts_touched
        ELSE 0
      END as response_rate
    FROM channel_responses cr
    FULL OUTER JOIN meeting_counts mc 
      ON cr.channel = mc.channel 
      AND COALESCE(cr.hubspot_owner_id, 0) = COALESCE(mc.hubspot_owner_id, 0) ;;
  }
  
  dimension: channel {
    type: string
    sql: ${TABLE}.channel ;;
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
  
  dimension: hubspot_owner_id {
    type: number
    sql: ${TABLE}.hubspot_owner_id ;;
  }
  
  dimension: contacts_touched {
    type: number
    sql: ${TABLE}.contacts_touched ;;
  }
  
  dimension: contacts_responded {
    type: number
    sql: ${TABLE}.contacts_responded ;;
  }
  
  dimension: meetings_generated {
    type: number
    sql: ${TABLE}.meetings_generated ;;
  }
  
  dimension: response_rate {
    type: number
    sql: ${TABLE}.response_rate ;;
    value_format_name: decimal_1
  }
  
  measure: total_contacts_touched {
    type: sum
    sql: ${contacts_touched} ;;
    drill_fields: [channel_label, hubspot_owner_id, total_contacts_touched]
  }
  
  measure: total_contacts_responded {
    type: sum
    sql: ${contacts_responded} ;;
    drill_fields: [channel_label, hubspot_owner_id, total_contacts_responded]
  }
  
  measure: total_meetings_generated {
    type: sum
    sql: ${meetings_generated} ;;
    drill_fields: [channel_label, hubspot_owner_id, total_meetings_generated]
  }
  
  measure: avg_response_rate {
    type: average
    sql: ${response_rate} ;;
    value_format_name: decimal_1
  }
}

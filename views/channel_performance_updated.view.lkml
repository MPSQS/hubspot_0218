view: channel_performance_updated {
  # Derived table that calculates channel performance metrics
  # Section D: Channel Performance - Email and Phone focus
  derived_table: {
    sql: 
      SELECT
        -- Channel identification
        CASE 
          WHEN a.channel::text = 'email' THEN 'Email'
          WHEN a.channel::text = 'call' THEN 'Phone'
          WHEN a.channel::text = 'linkedin_message' THEN 'LinkedIn'
          ELSE INITCAP(a.channel::text)
        END as channel_name,
        
        -- Total activities sent per channel
        COUNT(DISTINCT a.id) as total_activities,
        
        -- Activities with responses per channel (Email and Phone only)
        COUNT(DISTINCT CASE 
          -- Email response: email_replied field
          WHEN a.channel::text = 'email' AND a.email_replied = true THEN a.id
          -- Phone response: connected call
          WHEN a.channel::text = 'call' AND COALESCE(a.call_connected_count, 0) > 0 THEN a.id
        END) as responded_activities,
        
        -- Unique contacts who responded (Email and Phone only)
        COUNT(DISTINCT CASE 
          WHEN a.channel::text = 'email' AND a.email_replied = true THEN a.contact_id
          WHEN a.channel::text = 'call' AND COALESCE(a.call_connected_count, 0) > 0 THEN a.contact_id
        END) as responded_contacts,
        
        -- Contacts who booked meetings (has deal with scheduled meetings)
        COUNT(DISTINCT CASE 
          WHEN d.num_scheduled_meetings > 0 THEN a.contact_id
        END) as meeting_booked_contacts,
        
        -- Unique contacts reached per channel
        COUNT(DISTINCT a.contact_id) as unique_contacts
        
      FROM public.activities a
      
      -- Join to deals to check for meeting bookings
      LEFT JOIN public.deal_contacts dc ON a.contact_id = dc.contact_id
      LEFT JOIN public.deals d ON dc.deal_id = d.deal_id
      
      WHERE a.channel::text IN ('email', 'call', 'linkedin_message')
      
      GROUP BY 1
    ;;
  }
  
  # Dimensions
  
  dimension: channel_name {
    type: string
    sql: ${TABLE}.channel_name ;;
    label: "Channel"
    description: "Communication channel: Email, Phone, or LinkedIn"
    order_by_field: channel_sort_order
  }
  
  dimension: channel_sort_order {
    type: number
    hidden: yes
    sql: CASE 
      WHEN ${channel_name} = 'Email' THEN 1
      WHEN ${channel_name} = 'Phone' THEN 2
      WHEN ${channel_name} = 'LinkedIn' THEN 3
      ELSE 4
    END ;;
  }
  
  # Measures (KPIs)
  
  measure: total_activities {
    type: sum
    sql: ${TABLE}.total_activities ;;
    label: "Activities Sent"
    description: "Total number of activities sent via this channel"
    value_format_name: decimal_0
  }
  
  measure: responded_activities {
    type: sum
    sql: ${TABLE}.responded_activities ;;
    label: "Activities with Response"
    description: "Number of activities that received a response (Email & Phone only)"
    value_format_name: decimal_0
  }
  
  measure: responded_contacts {
    type: sum
    sql: ${TABLE}.responded_contacts ;;
    label: "Contacts Responded"
    description: "Unique contacts who responded via this channel (Email & Phone only)"
    value_format_name: decimal_0
  }
  
  measure: meeting_booked_contacts {
    type: sum
    sql: ${TABLE}.meeting_booked_contacts ;;
    label: "Meetings Booked"
    description: "Contacts who booked meetings after engagement"
    value_format_name: decimal_0
  }
  
  measure: unique_contacts {
    type: sum
    sql: ${TABLE}.unique_contacts ;;
    label: "Unique Contacts Reached"
    description: "Total unique contacts reached via this channel"
    value_format_name: decimal_0
  }
  
  # Calculated Rates
  
  measure: response_rate {
    type: number
    sql: CASE 
      WHEN ${total_activities} > 0 
      THEN 100.0 * ${responded_activities} / NULLIF(${total_activities}, 0)
      ELSE 0 
    END ;;
    label: "Response Rate %"
    description: "Percentage of activities that received a response (Email & Phone only)"
    value_format_name: decimal_1
    html: 
      {% if value >= 20 %}
        <div style="color: #0f9d58; font-weight: bold;">{{ rendered_value }}%</div>
      {% elsif value >= 10 %}
        <div style="color: #f4b400; font-weight: bold;">{{ rendered_value }}%</div>
      {% else %}
        <div style="color: #db4437;">{{ rendered_value }}%</div>
      {% endif %} ;;
  }
  
  measure: meeting_conversion_rate {
    type: number
    sql: CASE 
      WHEN ${responded_contacts} > 0 
      THEN 100.0 * ${meeting_booked_contacts} / NULLIF(${responded_contacts}, 0)
      ELSE 0 
    END ;;
    label: "Meeting Conversion Rate %"
    description: "Percentage of responding contacts who booked meetings"
    value_format_name: decimal_1
    html: 
      {% if value >= 15 %}
        <div style="color: #0f9d58; font-weight: bold;">{{ rendered_value }}%</div>
      {% elsif value >= 8 %}
        <div style="color: #f4b400; font-weight: bold;">{{ rendered_value }}%</div>
      {% else %}
        <div style="color: #db4437;">{{ rendered_value }}%</div>
      {% endif %} ;;
  }
  
  measure: overall_meeting_rate {
    type: number
    sql: CASE 
      WHEN ${total_activities} > 0 
      THEN 100.0 * ${meeting_booked_contacts} / NULLIF(${unique_contacts}, 0)
      ELSE 0 
    END ;;
    label: "Overall Meeting Rate %"
    description: "Percentage of all contacts reached who booked meetings"
    value_format_name: decimal_1
  }
}

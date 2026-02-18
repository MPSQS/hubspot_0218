view: activity_metrics {
  derived_table: {
    sql: SELECT
      DATE(a.activity_timestamp) as summary_date,
      a.channel::text as channel,
      a.hubspot_owner_id,
      COUNT(DISTINCT CASE WHEN a.channel::text = 'call' THEN a.id END) as call_count,
      COUNT(DISTINCT CASE WHEN a.channel::text = 'email' THEN a.id END) as email_count,
      COUNT(DISTINCT CASE WHEN a.channel::text = 'linkedin_message' THEN a.id END) as linkedin_count
    FROM public.activities a
    WHERE a.channel::text IN ('email', 'call', 'linkedin_message')
    GROUP BY 1, 2, 3 ;;
  }
  
  parameter: time_period_selector {
    type: unquoted
    allowed_value: { label: "Daily" value: "day" }
    allowed_value: { label: "Weekly" value: "week" }
    allowed_value: { label: "Monthly" value: "month" }
    default_value: "day"
  }
  
  parameter: daily_call_target {
    type: number
    default_value: "50"
  }
  
  parameter: daily_email_target {
    type: number
    default_value: "200"
  }
  
  parameter: daily_linkedin_target {
    type: number
    default_value: "75"
  }
  
  dimension: summary_date {
    type: date
    sql: ${TABLE}.summary_date ;;
  }
  
  dimension: channel {
    type: string
    sql: ${TABLE}.channel ;;
  }
  
  dimension: hubspot_owner_id {
    type: number
    sql: ${TABLE}.hubspot_owner_id ;;
  }
  
  dimension: time_period {
    type: string
    label_from_parameter: time_period_selector
    sql:
      {% if time_period_selector._parameter_value == 'day' %}
        TO_CHAR(${TABLE}.summary_date, 'YYYY-MM-DD')
      {% elsif time_period_selector._parameter_value == 'week' %}
        TO_CHAR(DATE_TRUNC('week', ${TABLE}.summary_date), 'YYYY-MM-DD') || ' (Week)'
      {% elsif time_period_selector._parameter_value == 'month' %}
        TO_CHAR(DATE_TRUNC('month', ${TABLE}.summary_date), 'YYYY-Mon')
      {% endif %} ;;
  }
  
  measure: calls_actual {
    type: sum
    sql: ${TABLE}.call_count ;;
    drill_fields: [summary_date, hubspot_owner_id, calls_actual]
  }
  
  measure: calls_target {
    type: number
    sql:
      {% if time_period_selector._parameter_value == 'day' %}
        {% parameter daily_call_target %}
      {% elsif time_period_selector._parameter_value == 'week' %}
        {% parameter daily_call_target %} * 5
      {% elsif time_period_selector._parameter_value == 'month' %}
        {% parameter daily_call_target %} * 20
      {% endif %} ;;
  }
  
  measure: calls_percent_to_target {
    type: number
    sql: CASE WHEN ${calls_target} > 0
      THEN 100.0 * ${calls_actual} / NULLIF(${calls_target}, 0)
      ELSE NULL END ;;
    value_format_name: decimal_1
    html:
      {% if value >= 80 %}
        <div style="color: #27AE60; font-weight: bold;">✓ {{ rendered_value }}%</div>
      {% elsif value >= 50 %}
        <div style="color: #E67E22; font-weight: bold;">⚠ {{ rendered_value }}%</div>
      {% else %}
        <div style="color: #C0392B; font-weight: bold;">✗ {{ rendered_value }}%</div>
      {% endif %} ;;
  }
  
  measure: emails_actual {
    type: sum
    sql: ${TABLE}.email_count ;;
    drill_fields: [summary_date, hubspot_owner_id, emails_actual]
  }
  
  measure: emails_target {
    type: number
    sql:
      {% if time_period_selector._parameter_value == 'day' %}
        {% parameter daily_email_target %}
      {% elsif time_period_selector._parameter_value == 'week' %}
        {% parameter daily_email_target %} * 5
      {% elsif time_period_selector._parameter_value == 'month' %}
        {% parameter daily_email_target %} * 20
      {% endif %} ;;
  }
  
  measure: emails_percent_to_target {
    type: number
    sql: CASE WHEN ${emails_target} > 0
      THEN 100.0 * ${emails_actual} / NULLIF(${emails_target}, 0)
      ELSE NULL END ;;
    value_format_name: decimal_1
    html:
      {% if value >= 80 %}
        <div style="color: #27AE60; font-weight: bold;">✓ {{ rendered_value }}%</div>
      {% elsif value >= 50 %}
        <div style="color: #E67E22; font-weight: bold;">⚠ {{ rendered_value }}%</div>
      {% else %}
        <div style="color: #C0392B; font-weight: bold;">✗ {{ rendered_value }}%</div>
      {% endif %} ;;
  }
  
  measure: linkedin_actual {
    type: sum
    sql: ${TABLE}.linkedin_count ;;
    drill_fields: [summary_date, hubspot_owner_id, linkedin_actual]
  }
  
  measure: linkedin_target {
    type: number
    sql:
      {% if time_period_selector._parameter_value == 'day' %}
        {% parameter daily_linkedin_target %}
      {% elsif time_period_selector._parameter_value == 'week' %}
        {% parameter daily_linkedin_target %} * 5
      {% elsif time_period_selector._parameter_value == 'month' %}
        {% parameter daily_linkedin_target %} * 20
      {% endif %} ;;
  }
  
  measure: linkedin_percent_to_target {
    type: number
    sql: CASE WHEN ${linkedin_target} > 0
      THEN 100.0 * ${linkedin_actual} / NULLIF(${linkedin_target}, 0)
      ELSE NULL END ;;
    value_format_name: decimal_1
    html:
      {% if value >= 80 %}
        <div style="color: #27AE60; font-weight: bold;">✓ {{ rendered_value }}%</div>
      {% elsif value >= 50 %}
        <div style="color: #E67E22; font-weight: bold;">⚠ {{ rendered_value }}%</div>
      {% else %}
        <div style="color: #C0392B; font-weight: bold;">✗ {{ rendered_value }}%</div>
      {% endif %} ;;
  }
}

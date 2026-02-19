connection: "cloud_sql"

include: "/views/*.view.lkml"

datagroup: hubspot_updated_default_datagroup {
  sql_trigger: SELECT MAX(created_at) FROM public.activities ;;
  max_cache_age: "1 hour"
}

persist_with: hubspot_updated_default_datagroup

# Main explore for contacts with all related data
explore: contacts {
  label: "Contacts"
  
  join: activities {
    type: left_outer
    relationship: one_to_many
    sql_on: ${contacts.hubspot_id} = ${activities.contact_id} ;;
  }
  
  join: sequence_enrollments {
    type: left_outer
    relationship: one_to_many
    sql_on: ${contacts.hubspot_id} = ${sequence_enrollments.contact_id} ;;
  }
  
  join: sequences {
    type: left_outer
    relationship: many_to_one
    sql_on: ${sequence_enrollments.sequence_id} = ${sequences.sequence_id} ;;
  }
  
  join: deal_contacts {
    type: left_outer
    relationship: one_to_many
    sql_on: ${contacts.hubspot_id} = ${deal_contacts.contact_id} ;;
  }
  
  join: deals {
    type: left_outer
    relationship: many_to_one
    sql_on: ${deal_contacts.deal_id} = ${deals.deal_id} ;;
  }
}

# Activity metrics with time period toggle (Section A)
explore: activity_metrics {
  label: "Activity Engine Metrics"
}

# Touch depth distribution (Section B)
explore: contact_touch_depth {
  label: "Contact Touch Depth Distribution"
}

# Lead generation funnel (Section C)
explore: lead_funnel {
  label: "Lead Gen Funnel"
}

# SIMPLIFIED Lead Gen Funnel (Section C) - 7 progressive stages
explore: lead_funnel_updated {
  label: "Lead Gen Funnel - Progressive Stages"
  description: "7-stage lead generation funnel with conversion rates: Total List → Qualified → In Sequence → Engaged → Interested → Meeting Booked → Sales Funnel"
}

# Channel performance metrics (Section D)
explore: channel_metrics {
  label: "Channel Performance"
}

# SIMPLIFIED Channel Performance (Section D) - Easy to understand
explore: channel_performance_updated {
  label: "Channel Performance - Simplified"
  description: "Clear view of Email, Phone, and LinkedIn performance with response rates and meeting conversions"
}

# Stale contacts alert (Section E)
explore: stale_contacts {
  label: "Stale Contacts Alert"
}

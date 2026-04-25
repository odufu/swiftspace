-- ============================================================
-- Add Price Term (Payment Plan) Filter to match_properties
-- ============================================================

drop function if exists public.match_properties(
  vector(768), float, int, float, float, int, text, float, float, float, text, text, bool
);

create function public.match_properties (
  query_embedding    vector(768),
  match_threshold    float,
  match_count        int,
  filter_min_price   float   default 0,
  filter_max_price   float   default 999999999,
  filter_beds        int     default null,
  filter_type        text    default null,
  filter_near_lat    float   default null,
  filter_near_lng    float   default null,
  filter_radius_km   float   default null,
  filter_lister_name  text    default null,
  filter_company_name text    default null,
  filter_is_premium   bool    default null,
  -- NEW: Payment plan / price term filter
  filter_price_term   text    default null
)
returns table (
  id                              uuid,
  title                           text,
  location_name                   text,
  price                           numeric,
  price_term                      text,
  latitude                        double precision,
  longitude                       double precision,
  type                            text,
  beds                            int,
  baths                           int,
  image_url                       text,
  description                     text,
  images_gallery                  text[],
  plan_image_url                  text,
  has_360_view                    bool,
  has_video                       bool,
  video_url                       text,
  panorama_url                    text,
  amenities                       text[],
  lister_name                     text,
  lister_type                     text,
  company_name                    text,
  lister_logo_url                 text,
  agent_phone                     text,
  lister_id                       uuid,
  is_verified                     bool,
  is_active                       bool,
  is_test                         bool,
  is_premium                      bool,
  views_count                     int,
  favorites_count                 int,
  video_views_count               int,
  proximity_to_road_meters        int,
  electricity_supply_hours        double precision,
  has_running_water               bool,
  proximity_to_hospital_km        double precision,
  year_built                      int,
  total_square_footage            double precision,
  flooding_history                bool,
  foundation_type                 text,
  has_certificate_of_occupancy    bool,
  has_governors_consent           bool,
  has_survey_plan                 bool,
  has_deed_of_assignment          bool,
  has_building_plan_approval      bool,
  has_soil_test_report            bool,
  has_structural_integrity_report bool,
  due_diligence_notes             text,
  has_lawyer_verified_terms       bool,
  terms_and_conditions            text,
  verification_status             text,
  applies_caution_fee             bool,
  applies_agency_fee              bool,
  applies_legal_fee               bool,
  applies_service_fee             bool,
  co_of_o_url                     text,
  governors_consent_url           text,
  survey_plan_url                 text,
  deed_of_assignment_url          text,
  building_plan_approval_url      text,
  soil_test_report_url            text,
  structural_integrity_report_url text,
  similarity                      float,
  distance_km                     float
)
language sql stable
security definer
set search_path = public
as $$
  select
    p.id, p.title, p.location_name, p.price, p.price_term, p.latitude, p.longitude, p.type, p.beds, p.baths, p.image_url, p.description, p.images_gallery, p.plan_image_url, p.has_360_view, p.has_video, p.video_url, p.panorama_url, p.amenities, p.lister_name, p.lister_type, p.company_name, p.lister_logo_url, p.agent_phone, p.lister_id, p.is_verified, p.is_active, p.is_test, p.is_premium, p.views_count, p.favorites_count, p.video_views_count, p.proximity_to_road_meters, p.electricity_supply_hours, p.has_running_water, p.proximity_to_hospital_km, p.year_built, p.total_square_footage, p.flooding_history, p.foundation_type, p.has_certificate_of_occupancy, p.has_governors_consent, p.has_survey_plan, p.has_deed_of_assignment, p.has_building_plan_approval, p.has_soil_test_report, p.has_structural_integrity_report, p.due_diligence_notes, p.has_lawyer_verified_terms, p.terms_and_conditions, p.verification_status, p.applies_caution_fee, p.applies_agency_fee, p.applies_legal_fee, p.applies_service_fee, p.co_of_o_url, p.governors_consent_url, p.survey_plan_url, p.deed_of_assignment_url, p.building_plan_approval_url, p.soil_test_report_url, p.structural_integrity_report_url,
    1 - (p.embedding <=> query_embedding) as similarity,
    case
      when filter_near_lat is not null and filter_near_lng is not null and filter_radius_km is not null
      then 6371.0 * 2.0 * asin(sqrt(power(sin(radians((p.latitude - filter_near_lat) / 2.0)), 2) + cos(radians(filter_near_lat)) * cos(radians(p.latitude)) * power(sin(radians((p.longitude - filter_near_lng) / 2.0)), 2)))
      else null
    end as distance_km
  from properties p
  where
    1 - (p.embedding <=> query_embedding) > match_threshold
    and p.price >= filter_min_price
    and p.price <= filter_max_price
    and (filter_beds is null or p.beds = filter_beds)
    and (filter_type is null or p.type = filter_type)
    and (filter_lister_name is null or p.lister_name ilike '%' || filter_lister_name || '%')
    and (filter_company_name is null or p.company_name ilike '%' || filter_company_name || '%')
    and (filter_is_premium is null or p.is_premium = filter_is_premium)
    and (filter_price_term is null or p.price_term = filter_price_term)
    and p.is_active = true
    and (
      filter_near_lat is null or filter_near_lng is null or filter_radius_km is null
      or (p.latitude is not null and p.longitude is not null and 6371.0 * 2.0 * asin(sqrt(power(sin(radians((p.latitude - filter_near_lat) / 2.0)), 2) + cos(radians(filter_near_lat)) * cos(radians(p.latitude)) * power(sin(radians((p.longitude - filter_near_lng) / 2.0)), 2))) <= filter_radius_km)
    )
  order by
    case when filter_near_lat is not null then
      6371.0 * 2.0 * asin(sqrt(power(sin(radians((p.latitude - filter_near_lat) / 2.0)), 2) + cos(radians(filter_near_lat)) * cos(radians(p.latitude)) * power(sin(radians((p.longitude - filter_near_lng) / 2.0)), 2)))
    else null end asc nulls last,
    p.embedding <=> query_embedding asc
  limit match_count;
$$;

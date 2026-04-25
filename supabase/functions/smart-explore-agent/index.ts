import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

// Service role key bypasses RLS — safe for trusted server-side search
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
)

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ── Geocode a place name to lat/lng using Nominatim (OpenStreetMap) ──
// Free, no API key required. Focused on Nigeria via countrycodes=ng.
async function geocodeLocation(place: string): Promise<{ lat: number; lng: number } | null> {
  try {
    const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(place)}&format=json&limit=1&countrycodes=ng`
    const res = await fetch(url, {
      headers: {
        // Nominatim requires a descriptive User-Agent
        'User-Agent': 'SwiftSpace/1.0 (property-search-app)',
        'Accept-Language': 'en',
      },
    })
    const results = await res.json()
    if (!results || results.length === 0) return null
    return { lat: parseFloat(results[0].lat), lng: parseFloat(results[0].lon) }
  } catch (e) {
    console.warn('[geocode] Failed to geocode:', place, e.message)
    return null
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { query } = await req.json()
    if (!query) throw new Error('Query is required')

    // ── Step 1: Generate embedding for the user's query ────────────────
    const embedResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'models/gemini-embedding-001',
          content: { parts: [{ text: query }] },
          outputDimensionality: 768,
        }),
      }
    )
    const embedData = await embedResponse.json()
    const query_embedding = embedData.embedding?.values
    if (!query_embedding) {
      throw new Error('Failed to generate embedding: ' + JSON.stringify(embedData))
    }

    // ── Step 2: Extract hard filters AND proximity intent via Gemini ───
    const prompt = `
      Extract structured filters from this Nigerian real estate search query: "${query}".
      Return ONLY a valid JSON object with these exact keys:

      {
        "min_budget": <number, minimum price in Naira, default 0>,
        "max_budget": <number, max price in Naira, default 999999999. Note: '5m' = 5000000, '500k' = 500000>,
        "beds": <number or null, exact bedrooms requested, null if not mentioned>,
        "property_type": <string or null — must be exactly one of: shops, officeSpace, flatsAndApartments, lands, house, semiDetachedBungalows, semiDetachedDuplex, detachedBungalows, detachedDuplex, terracedBungalows, terracedDuplex, coWorkingSpace, warehouse, shopInAMall, commercialProperties — or null if unclear>,
        "reference_location": <string or null — a specific place name, landmark, or area the user wants to be NEAR, e.g. "Jabi Lake Mall", "Wuse Market", "Lekki Phase 1". null if no proximity intent>,
        "radius_km": <number or null — search radius in km around the reference location. Default to 5 if a reference location is mentioned but no radius given. null if no reference_location>,
        "lister_name": <string or null, exact agent or owner name if the user specifically asks for properties by someone, e.g. "John Doe">,
        "company_name": <string or null, exact real estate company name if mentioned, e.g. "Swift Homes", "Julius Berger">,
        "is_premium": <boolean or null, true if they specifically ask for "premium", "luxury", "vip" properties. false if they explicitly ask for "regular", "normal", "non-premium" properties. null if they don't specify.>,
        "price_term": <string or null, exact price term if mentioned. Must be exactly one of: "day" (shortlets/daily), "wk" (weekly), "mo" (monthly), "yr" (yearly), "buy" (for sale/buying). null if not specified.>
      }

      Examples:
      "2 bedroom flat under 4m in Wuse 2" -> reference_location: null, lister_name: null, company_name: null, is_premium: null, price_term: null
      "flat within 3km of Jabi Lake Mall" -> reference_location: "Jabi Lake Mall, Abuja", radius_km: 3
      "premium houses from Swift Properties" -> company_name: "Swift Properties", is_premium: true
      "shortlet flats in Lekki" -> price_term: "day"
      "houses for rent yearly" -> price_term: "yr"
      "flats paying monthly" -> price_term: "mo"
      "buy a detached duplex" -> price_term: "buy"
    `

    const filterResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: 'application/json' },
        }),
      }
    )
    const filterData = await filterResponse.json()
    const jsonString = filterData.candidates?.[0]?.content?.parts?.[0]?.text

    let filters: Record<string, unknown> = {}
    try {
      filters = jsonString ? JSON.parse(jsonString) : {}
    } catch {
      console.warn('[smart-explore] Could not parse filters from Gemini, using defaults.')
    }

    console.log(`[smart-explore] Query: "${query}" | Filters:`, JSON.stringify(filters))

    // ── Step 3: Geocode reference_location if present ─────────────────
    let nearLat: number | null = null
    let nearLng: number | null = null
    let radiusKm: number | null = null

    const refLocation = filters.reference_location as string | null
    if (refLocation) {
      const coords = await geocodeLocation(refLocation)
      if (coords) {
        nearLat = coords.lat
        nearLng = coords.lng
        radiusKm = (filters.radius_km as number | null) ?? 5
        console.log(`[smart-explore] Geocoded "${refLocation}" → lat:${nearLat}, lng:${nearLng}, radius:${radiusKm}km`)
      } else {
        console.warn(`[smart-explore] Could not geocode "${refLocation}" — proximity filter skipped`)
      }
    }

    // ── Step 4: Semantic + proximity search via match_properties RPC ───
    const { data: properties, error } = await supabaseAdmin.rpc('match_properties', {
      query_embedding,
      match_threshold: 0.2,
      match_count: 10,
      filter_min_price:  filters.min_budget  ?? 0,
      filter_max_price:  filters.max_budget  ?? 999999999,
      filter_beds:       filters.beds        ?? null,
      filter_type:       filters.property_type ?? null,
      filter_near_lat:   nearLat,
      filter_near_lng:   nearLng,
      filter_radius_km:  radiusKm,
      filter_lister_name: filters.lister_name ?? null,
      filter_company_name: filters.company_name ?? null,
      filter_is_premium: filters.is_premium ?? null,
      filter_price_term: filters.price_term ?? null,
    })

    if (error) {
      console.error('[smart-explore] RPC error:', JSON.stringify(error))
      throw error
    }

    const count = (properties ?? []).length
    console.log(`[smart-explore] Returned ${count} properties.`)

    return new Response(
      JSON.stringify({
        properties: properties ?? [],
        filters,
        proximity: nearLat !== null
          ? { lat: nearLat, lng: nearLng, radius_km: radiusKm, resolved_place: refLocation }
          : null,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('[smart-explore] Error:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
    )
  }
})

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

serve(async (req) => {
  try {
    const payload = await req.json()
    
    // The payload comes from a Supabase Database Webhook
    // Expecting payload.record to contain the new/updated property
    const property = payload.record

    if (!property) {
      return new Response("No property found in payload", { status: 400 })
    }

    // 1. Construct a semantic text block describing the property
    const textToEmbed = `
      Title: ${property.title}
      Location: ${property.location_name}
      Description: ${property.description}
      Type: ${property.type}
      Bedrooms: ${property.beds}
      Bathrooms: ${property.baths}
      Amenities: ${(property.amenities || []).join(', ')}
      Listed By: ${property.lister_name} ${property.company_name ? `(${property.company_name})` : ''}
    `.trim()

    // 2. Call Gemini API to generate the embedding
    // Using gemini-embedding-001 (text-embedding-004 is deprecated).
    // outputDimensionality=768 keeps us compatible with the existing vector(768) column.
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'models/gemini-embedding-001',
          content: {
            parts: [{ text: textToEmbed }]
          },
          outputDimensionality: 768
        })
      }
    )

    const data = await response.json()
    const embedding = data.embedding?.values

    if (!embedding) {
      throw new Error(`Failed to generate embedding: ${JSON.stringify(data)}`)
    }

    // 3. Update the property record with the new embedding
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { error } = await supabaseClient
      .from('properties')
      .update({ embedding })
      .eq('id', property.id)

    if (error) throw error

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    })
  }
})

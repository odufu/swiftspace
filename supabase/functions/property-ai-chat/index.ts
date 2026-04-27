import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { query, property } = await req.json()

    if (!query || !property) {
      throw new Error('Missing query or property context')
    }

    const prompt = `
      You are an expert real estate AI assistant for "Swift Space", a premium property platform.
      You are helping a potential tenant/buyer evaluate a specific property.
      
      PROPERTY CONTEXT:
      Title: ${property.title}
      Price: ${property.price} ${property.price_term}
      Location: ${property.location_name}
      Type: ${property.type}
      Amenities: ${property.amenities?.join(', ')}
      Description: ${property.description}
      Flooding History: ${property.flooding_history ? 'Has history of flooding' : 'No reported flooding'}
      Electricity: ${property.electricity_supply_hours} hours/day
      Water: ${property.has_running_water ? 'Has running water' : 'No running water'}
      Verified: ${property.is_verified ? 'Yes' : 'No'}
      Legal Documents: ${property.has_certificate_of_occupancy ? 'C of O' : ''} ${property.has_governors_consent ? "Governor's Consent" : ''}
      Lister: ${property.lister_name}
      
      USER QUESTION:
      "${query}"
      
      INSTRUCTIONS:
      - Be concise, professional, and helpful.
      - Use ONLY the information provided above to answer.
      - If you don't know the answer based on the context, suggest the user contact the agent (${property.lister_name} at ${property.agent_phone}).
      - Format your response in clean Markdown.
    `

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 500,
          },
        }),
      }
    )

    const data = await response.json()
    
    if (data.error) {
      if (data.error.code === 429) {
        return new Response(
          JSON.stringify({ response: "I'm a bit overwhelmed right now. Please wait a minute and try again!" }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      throw new Error(data.error.message)
    }

    const aiResponse = data.candidates?.[0]?.content?.parts?.[0]?.text
    
    if (!aiResponse) {
      throw new Error('No response generated')
    }

    return new Response(
      JSON.stringify({ response: aiResponse }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('[property-ai-chat] Error:', error)
    return new Response(
      JSON.stringify({ response: `Oops! I had a hiccup: ${error.message}` }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Track engagement to Supabase
const { createClient } = require('@supabase/supabase-js');

exports.handler = async function(event) {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  // Get Supabase credentials from environment
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    console.log('Supabase not configured, skipping tracking');
    return { statusCode: 200, body: JSON.stringify({ status: 'skipped' }) };
  }

  try {
    const data = JSON.parse(event.body);
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { error } = await supabase
      .from('sb36_engagement')
      .insert({
        district: data.district || 0,
        bill_number: data.bill_number || 'SB 36',
        stance: data.stance || 'oppose',
        template_name: data.template_name,
        action_type: data.action_type,
        legislator_name: data.legislator_name,
        legislator_chamber: data.legislator_chamber,
        contact_mode: data.contact_mode,
        agency: data.agency
      });

    if (error) {
      console.error('Supabase error:', error);
      return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
    }

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({ status: 'tracked' })
    };
  } catch (err) {
    console.error('Tracking error:', err);
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};

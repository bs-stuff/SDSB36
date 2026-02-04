// Proxy to Census Geocoder API (avoids CORS issues)
exports.handler = async function(event) {
  const address = event.queryStringParameters?.address;

  if (!address) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Missing address parameter" })
    };
  }

  const url = `https://geocoding.geo.census.gov/geocoder/geographies/onelineaddress?` +
    `address=${encodeURIComponent(address)}&` +
    `benchmark=Public_AR_Current&` +
    `vintage=Current_Current&` +
    `layers=2024%20State%20Legislative%20Districts%20-%20Upper,2024%20State%20Legislative%20Districts%20-%20Lower&` +
    `format=json`;

  try {
    const response = await fetch(url);
    const data = await response.json();

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify(data)
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Census API request failed", details: err.message })
    };
  }
};

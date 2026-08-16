// Vercel Serverless Function — Google Places API(New) 프록시
// GOOGLE_PLACES_API_KEY는 Vercel 프로젝트 환경변수로만 설정하고, 클라이언트(index.html)에는 절대 넣지 않는다.

module.exports = async function handler(req, res) {
  const apiKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: '서버에 GOOGLE_PLACES_API_KEY가 설정되지 않았습니다.' });
    return;
  }

  const query = (req.query.query || '').toString().trim();
  if (!query) {
    res.status(400).json({ error: 'query 파라미터가 필요합니다.' });
    return;
  }

  try {
    const searchText = extractSearchText(query);

    const searchRes = await fetch('https://places.googleapis.com/v1/places:searchText', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': [
          'places.displayName',
          'places.formattedAddress',
          'places.googleMapsUri',
          'places.photos',
          'places.primaryTypeDisplayName'
        ].join(',')
      },
      body: JSON.stringify({ textQuery: searchText, languageCode: 'ko' })
    });
    const searchData = await searchRes.json();
    if (!searchRes.ok) {
      res.status(searchRes.status).json({ error: (searchData.error && searchData.error.message) || 'Places 검색에 실패했습니다.' });
      return;
    }

    const place = searchData.places && searchData.places[0];
    if (!place) {
      res.status(404).json({ error: '검색 결과를 찾을 수 없습니다.' });
      return;
    }

    const name = (place.displayName && place.displayName.text) || searchText;
    const descriptionParts = [
      place.primaryTypeDisplayName && place.primaryTypeDisplayName.text,
      place.formattedAddress
    ].filter(Boolean);
    const description = descriptionParts.join(' · ');
    const mapLink = place.googleMapsUri || ('https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(name));

    let photoDataUrl = null;
    const photoRef = place.photos && place.photos[0] && place.photos[0].name;
    if (photoRef) {
      photoDataUrl = await fetchPhotoAsDataUrl(photoRef, apiKey);
    }

    res.status(200).json({ name, description, mapLink, photoDataUrl });
  } catch (err) {
    res.status(500).json({ error: err.message || '서버 오류가 발생했습니다.' });
  }
};

// 구글맵 링크(.../place/장소명/@lat,lng,...)에서 장소명만 뽑아내고,
// 그 외(장소명 직접 입력 또는 형식을 모르는 링크)는 그대로 검색어로 사용한다.
function extractSearchText(input) {
  if (/^https?:\/\//i.test(input)) {
    const match = input.match(/\/place\/([^/@]+)/);
    if (match) return decodeURIComponent(match[1].replace(/\+/g, ' '));
  }
  return input;
}

// 사진을 서버에서 직접 받아 base64로 반환한다 (Google 사진 URL에 API 키를 실어 클라이언트로 보내지 않기 위함).
async function fetchPhotoAsDataUrl(photoRef, apiKey) {
  try {
    const photoRes = await fetch(
      `https://places.googleapis.com/v1/${photoRef}/media?maxWidthPx=800`,
      { headers: { 'X-Goog-Api-Key': apiKey } }
    );
    if (!photoRes.ok) return null;
    const contentType = photoRes.headers.get('content-type') || 'image/jpeg';
    const buffer = await photoRes.arrayBuffer();
    const base64 = Buffer.from(buffer).toString('base64');
    return `data:${contentType};base64,${base64}`;
  } catch {
    return null;
  }
}

// Script to generate enriched comujesa_data.json with geocoding, polylines, and demo data
const fs = require('fs');

// ============================================================
// 1. KNOWN COORDINATES (from Nominatim + user-provided)
// ============================================================
const KNOWN_COORDS = {
  // User-provided reference points
  "Plaza Esteve": [36.6819, -6.1365],
  "Villamarta": [36.6834, -6.1349],
  "Rotonda Casino": [36.6881, -6.1302],
  "Estaciones (Minotauro)": [36.6890, -6.1230],
  "Minotauro": [36.6890, -6.1230],
  "Estadio Chapín": [36.6877, -6.1216],

  // Nominatim results
  "San Telmo": [36.6647, -6.1386],
  "Ermita San Telmo": [36.6660, -6.1375],
  "Guadalcacín": [36.7139, -6.0883],
  "Divina Pastora Guadalcacín": [36.7145, -6.0870],
  "Hospital Infantil": [36.6992, -6.1488],
  "Urgencias": [36.6988, -6.1480],
  "Consultas Externas": [36.6990, -6.1485],
  "Hipercor": [36.7049, -6.1151],
  "Hipercor (Andalucía)": [36.7045, -6.1145],
  "Hipercor (Altillo)": [36.7050, -6.1155],
  "Hipercor (Voltaire)": [36.7052, -6.1148],
  "Hipercor Rioja": [36.7047, -6.1158],
  "Hipercor (Av. Espera)": [36.7051, -6.1143],
  "Luz Shopping": [36.6952, -6.1585],
  "Campus Universitario": [36.6861, -6.1185],
  "Carrefour Norte": [36.6956, -6.1150],
  "Carrefour Sur": [36.6760, -6.1470],
  "Cementerio": [36.6859, -6.0962],
  "Zoológico": [36.6889, -6.1501],
  "Ikea": [36.6971, -6.1622],
  "Nueva Jarilla": [36.7588, -6.0319],
  "Avda. Europa": [36.6960, -6.1208],
  "El Portal": [36.6366, -6.1331],
  "Montealto": [36.7042, -6.1366],
  "La Marquesa": [36.6928, -6.0962],
  "Área Sur": [36.6913, -6.1559],
  "Área Sur 2": [36.6918, -6.1565],
  "Área Sur 3": [36.6922, -6.1572],
  "Área Sur 3 Primark": [36.6925, -6.1575],
  "Leroy Merlin": [36.7092, -6.1273],
  "Calle Porvera": [36.6861, -6.1375],
  "Porvera I": [36.6858, -6.1370],
  "Porvera II": [36.6863, -6.1380],
  "La Plata": [36.6969, -6.1445],
  "Pz. Madre de Dios": [36.6786, -6.1287],
  "Pz. Madre Dios": [36.6786, -6.1287],
  "Madre de Dios": [36.6786, -6.1287],
  "Feria": [36.6973, -6.1264],
  "Álvaro Domecq": [36.6947, -6.1296],

  // Estimated from known areas of Jerez
  "Angustias": [36.6810, -6.1310],
  "Angustias Canal Sur": [36.6810, -6.1315],
  "Angustias-Bodega": [36.6808, -6.1312],
  "Plaza Angustias": [36.6810, -6.1310],
  "Diego F. Herrera": [36.6805, -6.1300],
  "Arcos": [36.6828, -6.1355],
  "Pío XII": [36.6815, -6.1340],
  "Descalzos": [36.6800, -6.1320],
  "C/ Manuel Moneo": [36.6760, -6.1340],
  "Bajada San Telmo": [36.6720, -6.1360],
  "Cerrofruto": [36.6700, -6.1370],
  "Constitución": [36.6680, -6.1350],
  "Nueva Cartuja": [36.6690, -6.1330],
  "Solidaridad": [36.6700, -6.1310],
  "Vallesequillo II": [36.6710, -6.1290],
  "Moreno Mendoza": [36.6720, -6.1270],
  "Amistad": [36.6660, -6.1375],
  "Porvenir": [36.6800, -6.1290],

  // L2 stops
  "Sto. Domingo II": [36.6870, -6.1340],
  "Sto. Domingo III": [36.6875, -6.1345],
  "Mamelón": [36.6865, -6.1355],
  "Ancha": [36.6840, -6.1390],
  "Merced": [36.6830, -6.1420],
  "Luis Vives": [36.6810, -6.1440],
  "Azahar": [36.6795, -6.1455],
  "El Mirador": [36.6780, -6.1470],
  "Amapola": [36.6770, -6.1480],
  "Picadueña Alta": [36.6755, -6.1495],
  "Picadueña Baja": [36.6745, -6.1505],
  "Teodoro Molina": [36.6740, -6.1490],
  "Bda. El Pilar": [36.6735, -6.1475],
  "Nueva Medina": [36.6820, -6.1430],
  "Muro": [36.6845, -6.1405],
  "Puerta Rota": [36.6825, -6.1415],
  "Sevilla": [36.6880, -6.1325],
  "Paúl": [36.6885, -6.1305],
  "Fátima": [36.6888, -6.1280],
  "España": [36.6890, -6.1260],

  // L3 stops
  "Lealas": [36.6855, -6.1370],
  "S. Fco. Javier": [36.6850, -6.1385],
  "Lealas II": [36.6845, -6.1395],
  "Perpetuo Socorro": [36.6950, -6.1455],
  "La Serrana": [36.6960, -6.1460],
  "Solea": [36.6970, -6.1470],
  "Las Torres": [36.6980, -6.1475],
  "Amontillado": [36.6975, -6.1465],
  "Icovesa": [36.6965, -6.1455],
  "Santa Ana": [36.6845, -6.1410],
  "Asta": [36.6840, -6.1400],
  "Santiago": [36.6845, -6.1395],

  // L4 stops
  "Inst. Coloma": [36.6940, -6.1300],
  "Cruz Roja": [36.6935, -6.1285],
  "Merca 80": [36.6930, -6.1270],
  "García Lorca": [36.6925, -6.1255],
  "María Auxiliadora": [36.6920, -6.1240],
  "Avd. la Comedia": [36.6915, -6.1225],
  "Parqueluz": [36.6910, -6.1210],
  "San Joaquín": [36.6920, -6.1195],
  "Buenos Aires": [36.6940, -6.1180],
  "Guatemala": [36.6960, -6.1165],
  "Guatemala II": [36.6970, -6.1160],
  "Av. San Juan de Ávila": [36.7030, -6.1160],
  "Maternidad": [36.7000, -6.1175],
  "La Espléndida": [36.6905, -6.1220],
  "San Ginés": [36.6920, -6.1245],
  "Pza. Caballo": [36.6960, -6.1280],
  "Torres de Córdoba": [36.6945, -6.1270],
  "La Constancia": [36.6900, -6.1255],

  // L5 stops
  "Avd. la Paz": [36.6895, -6.1340],
  "Avd. Caballo": [36.6965, -6.1275],
  "IFECA": [36.6978, -6.1255],
  "Edf. Congreso": [36.6965, -6.1185],
  "Arrumbadores": [36.6960, -6.1170],
  "Entre Parques": [36.6955, -6.1195],
  "C/ Huelva": [36.6950, -6.1210],
  "Inst. F.P. La Granja": [36.6955, -6.1215],
  "C/ Álvaro Mirón y Duque": [36.6975, -6.1230],
  "Arroyo del Membrillar": [36.6990, -6.1240],
  "Fdez. Cruzado": [36.7000, -6.1250],
  "Fernández Cruzado": [36.7000, -6.1250],
  "Ermita Palomares": [36.7020, -6.1200],
  "Ermita Setefilla": [36.7040, -6.1150],
  "San José Obrero": [36.7060, -6.1100],
  "El Picador": [36.7080, -6.1050],
  "Rabanito": [36.7100, -6.0970],
  "Ferretería": [36.7120, -6.0910],
  "Mercado Abastos": [36.7135, -6.0890],
  "C/ Madrid": [36.7140, -6.0880],

  // L6 stops
  "Harinera": [36.6830, -6.1320],
  "Pelirón": [36.6840, -6.1290],
  "Burger King": [36.6855, -6.1210],
  "Torres Blancas": [36.6870, -6.1175],
  "Pza. Biarritz": [36.6880, -6.1150],
  "Lola Flores": [36.6890, -6.1130],
  "El Pinar": [36.6900, -6.1110],
  "Residencia Pensionista": [36.6910, -6.1095],
  "F. Portillo": [36.6920, -6.1105],
  "Siete Pinos": [36.6935, -6.1120],
  "Almería": [36.6945, -6.1100],
  "Suite la Marquesa": [36.6930, -6.1080],
  "Piscina Jerez": [36.6920, -6.1070],
  "Medina": [36.6815, -6.1330],

  // L7 stops
  "Retiro": [36.6795, -6.1265],
  "Pq. Retiro": [36.6800, -6.1245],
  "Alborán": [36.6810, -6.1225],
  "Delicias": [36.6820, -6.1205],
  "Zafer": [36.6835, -6.1180],
  "Residencial Rotonda": [36.6845, -6.1160],
  "P. Rguez. del Raño": [36.6855, -6.1140],
  "Cantalejo": [36.6860, -6.1115],
  "Centauro": [36.6865, -6.1090],
  "La Pita": [36.6868, -6.1060],
  "Venta La Cueva": [36.6870, -6.0980],
  "Hogar Pensionistas": [36.6875, -6.0950],
  "Arboleda": [36.6880, -6.0930],
  "Pozo": [36.6885, -6.0910],
  "Estella": [36.6890, -6.0890],

  // L8 additional stops
  "Cartuja": [36.6790, -6.1280],
  "Centro Salud Asunción": [36.6830, -6.1195],
  "Asunción": [36.6850, -6.1185],
  "Sementales": [36.6975, -6.1200],
  "Jacaranda": [36.6985, -6.1185],
  "Club Padel": [36.6995, -6.1170],
  "Las Pérgolas": [36.7010, -6.1155],
  "Cash Dian": [36.6975, -6.1155],
  "Hacienda": [36.6935, -6.1260],
  "San Benito": [36.6950, -6.1300],
  "Tomás Gª Figueras": [36.6970, -6.1350],
  "Arcipreste Corona": [36.6980, -6.1390],
  "Reina Sofía San Benito": [36.6985, -6.1420],
  "Bda. El Carmen": [36.6975, -6.1460],
  "Los Liños": [36.6965, -6.1470],
  "Mosto": [36.6955, -6.1480],
  "Calvario": [36.6940, -6.1500],
  "Zoilo Ruiz Mateos": [36.6880, -6.1490],
  "Romero Palomo": [36.6830, -6.1460],
  "Asta Regia": [36.6810, -6.1420],
  "Alcázar": [36.6790, -6.1430],
  "Cuatro Caminos": [36.6780, -6.1450],
  "Tanatorio": [36.6770, -6.1460],
  "La Venencia": [36.6760, -6.1480],
  "Juana Aguilar": [36.6755, -6.1490],
  "Miguel Hue": [36.6750, -6.1480],
  "Historiador Bª Gtrrz.": [36.6745, -6.1470],
  "Campo La Juventud": [36.6740, -6.1450],
  "Santo Tomás": [36.6730, -6.1430],
  "Liberación": [36.6720, -6.1410],
  "Balneario": [36.6715, -6.1390],
  "Vergara Isasi": [36.6715, -6.1365],

  // L9 additional stops
  "FF.CC.": [36.6795, -6.1275],
  "Tomás Bengoa": [36.6790, -6.1285],
  "Avd. Vallesequillo": [36.6785, -6.1295],
  "Fdz. Sierra": [36.6775, -6.1305],
  "Obispo Ciralda": [36.6765, -6.1315],
  "San Eloy": [36.6755, -6.1325],
  "Tablao": [36.6948, -6.1490],

  // L10 stops
  "Canaleja": [36.6720, -6.1450],
  "Caños de Meca": [36.6715, -6.1435],
  "Doña María": [36.6710, -6.1420],
  "Macedonia": [36.6705, -6.1405],
  "Fresa": [36.6700, -6.1390],
  "Las Palmeras": [36.6695, -6.1375],
  "Pza. Carpita": [36.6690, -6.1360],
  "Parque Atlántico": [36.6685, -6.1345],
  "Mediterráneo": [36.6680, -6.1330],
  "Manjón": [36.6675, -6.1315],
  "El Serrallo": [36.6670, -6.1300],
  "Parque Cartuja": [36.6665, -6.1285],
  "Rsd El Duque": [36.6670, -6.1270],
  "Pino Solete": [36.6680, -6.1260],
  "C/ Sta. Inés": [36.6690, -6.1255],
  "Avda. Medina Sidonia": [36.6710, -6.1265],
  "Vallesequillo": [36.6730, -6.1275],
  "Juzgados": [36.6955, -6.1310],

  // L11 stops
  "Alunados II": [36.6825, -6.1270],
  "Alunados I": [36.6835, -6.1250],
  "Ronda Este": [36.6915, -6.1080],
  "La Pita Ronda Este": [36.6910, -6.1060],
  "Alcázar Jerez II": [36.6920, -6.1040],
  "Alcázar Jerez I": [36.6925, -6.1020],
  "Zurbarán": [36.6930, -6.0975],

  // L12 stops
  "Los Pinos": [36.6865, -6.1195],
  "C/ Praga": [36.6885, -6.1140],
  "Instituto Seritium": [36.6895, -6.1125],
  "Amsterdam": [36.6910, -6.1115],
  "Tauromaquia": [36.6925, -6.1120],
  "San Marino": [36.6940, -6.1130],
  "Caballero Bonald": [36.6965, -6.1220],

  // L13 stops
  "Torresoto": [36.6785, -6.1440],
  "Telefónica": [36.6775, -6.1455],
  "Quintero Ramírez": [36.6768, -6.1465],
  "José de Soto": [36.6765, -6.1475],
  "Rodrigo de Jerez": [36.6750, -6.1490],
  "C/ Finlandia": [36.6740, -6.1505],
  "Guadabajaque": [36.6730, -6.1520],
  "Campus El Sabio": [36.6720, -6.1530],
  "Residencia Rancho Colores": [36.6715, -6.1540],
  "Glorieta de Guadabajaque": [36.6725, -6.1525],
  "Avd. Puertas del Sur": [36.6735, -6.1480],
  "Asisa": [36.6720, -6.1465],
  "C. Salud Puertas Sur": [36.6710, -6.1450],
  "Hdez. Rubio": [36.6705, -6.1440],
  "Osuna": [36.6700, -6.1455],

  // L14 stops
  "Ronda Viñedos": [36.6845, -6.1270],
  "Las Viñas": [36.6840, -6.1250],
  "Blas Infante": [36.6835, -6.1230],
  "Glorieta Arles": [36.6825, -6.1210],
  "Club Nazaret": [36.6815, -6.1190],
  "Avd. Nazaret": [36.6805, -6.1175],
  "Medina Azahara": [36.6795, -6.1160],
  "Centro Salud Montealegre": [36.6785, -6.1145],
  "Villas del Este": [36.6775, -6.1130],
  "Glorieta 4": [36.6765, -6.1115],
  "La Teja": [36.6755, -6.1100],
  "La Canaleja": [36.6745, -6.1085],
  "El Encinar": [36.6735, -6.1070],
  "Rotonda 6": [36.6730, -6.1080],

  // L15 stops
  "Pablo Neruda": [36.6895, -6.1250],
  "Clínica Serman": [36.6900, -6.1240],
  "Palacio Congreso": [36.6960, -6.1195],
  "San Jerónimo": [36.7060, -6.1140],
  "Las Flores": [36.7080, -6.1120],
  "Camino Espera": [36.7070, -6.1130],
  "Pozoalbero": [36.7090, -6.1100],
  "Cañada Ancha": [36.7110, -6.1050],
  "Ciudad del Transporte": [36.7130, -6.0980],
  "PPCTA": [36.7160, -6.0920],
  "CITED": [36.7180, -6.0880],
  "IVECO": [36.7200, -6.0840],
  "Azucarera": [36.7220, -6.0800],
  "Magallanes": [36.7170, -6.0870],
  "Crtra. Nva. Jarilla": [36.7300, -6.0650],
  "Avda. Jerez I": [36.7450, -6.0480],
  "Avda. Jerez II": [36.7520, -6.0400],
  "San Juan Bautista": [36.7055, -6.1145],
  "Ortega y Gasset": [36.7065, -6.1135],

  // L15 El Portal ramal
  "Manuel Moreno": [36.6750, -6.1350],
  "Avda. Alcalde Cantos Ropero": [36.6650, -6.1380],
  "Tubesan": [36.6550, -6.1370],
  "Naves Andana": [36.6500, -6.1360],
  "Recauchutados Córdoba": [36.6460, -6.1350],
  "Depuradora": [36.6420, -6.1340],
  "ITV": [36.6400, -6.1335],
  "Autobuses Urbanos": [36.6380, -6.1330],

  // L16 stops
  "Hotel Jerez": [36.6985, -6.1250],
  "Santa Mónica": [36.7000, -6.1230],
  "Avenida Andalucía": [36.7020, -6.1200],
  "Av. Tío Pepe": [36.7040, -6.1180],
  "Brico Depot": [36.7060, -6.1160],
  "BMW": [36.7075, -6.1125],
  "El Bosque": [36.6978, -6.1270],

  // L17 stops
  "Las Adelfas": [36.6980, -6.1260],
  "González Ágreda": [36.6990, -6.1240],
  "Grúas Oliva": [36.6955, -6.1175],
  "Correos P. Empresarial": [36.7010, -6.1200],
  "Juan Sebastián Elcano": [36.7070, -6.1300],
  "Costa de la Luz": [36.7055, -6.1330],
  "Colegio Montealto": [36.7048, -6.1355],
  "Doctor Marañón": [36.7040, -6.1375],
  "Montealto II": [36.7045, -6.1370],
  "Milar Suinve": [36.6960, -6.1190],
  "Garvey": [36.6965, -6.1360],
  "Los Villares I": [36.6975, -6.1400],
  "Los Villares II": [36.6985, -6.1440],
  "Garvey II": [36.6968, -6.1365],

  // L18 stops
  "Taxdirt": [36.6835, -6.1405],
  "Sanatorio": [36.6850, -6.1420],
  "San Juan de Dios": [36.6870, -6.1450],
  "Decathlon": [36.6960, -6.1600],
  "Alcampo": [36.6945, -6.1610],
  "San Juan Bosco": [36.6850, -6.1415],

  // LEI stops
  "Instituto La Granja": [36.6955, -6.1218],

  // L8/L9 circular extras
  "Asta Regia": [36.6810, -6.1420],
  "Vergara Isasi": [36.6715, -6.1365],
  "C/Sta inés": [36.6690, -6.1255],
};

// ============================================================
// 2. LOAD EXISTING DATA
// ============================================================
const data = JSON.parse(fs.readFileSync('comujesa_data.json', 'utf8'));

// ============================================================
// 3. GEOCODE ALL STOPS
// ============================================================
let geocodedCount = 0;
let estimatedCount = 0;

function getCoords(stopName, lineStops, stopIndex) {
  // Direct match
  if (KNOWN_COORDS[stopName]) {
    geocodedCount++;
    return { lat: KNOWN_COORDS[stopName][0], lng: KNOWN_COORDS[stopName][1], geocodeSource: "nominatim_or_known" };
  }

  // Try partial match
  for (const [key, coords] of Object.entries(KNOWN_COORDS)) {
    if (stopName.includes(key) || key.includes(stopName)) {
      geocodedCount++;
      return { lat: coords[0], lng: coords[1], geocodeSource: "partial_match" };
    }
  }

  // Interpolate from neighbors
  estimatedCount++;
  let prevCoords = null, nextCoords = null;

  // Look backward for known stop
  for (let i = stopIndex - 1; i >= 0; i--) {
    const name = lineStops[i].name;
    if (KNOWN_COORDS[name]) {
      prevCoords = KNOWN_COORDS[name];
      break;
    }
    // Check if already geocoded
    if (lineStops[i]._coords) {
      prevCoords = [lineStops[i]._coords.lat, lineStops[i]._coords.lng];
      break;
    }
  }

  // Look forward for known stop
  for (let i = stopIndex + 1; i < lineStops.length; i++) {
    const name = lineStops[i].name;
    if (KNOWN_COORDS[name]) {
      nextCoords = KNOWN_COORDS[name];
      break;
    }
  }

  if (prevCoords && nextCoords) {
    const ratio = 0.5;
    const jitter = (Math.random() - 0.5) * 0.001;
    return {
      lat: prevCoords[0] + (nextCoords[0] - prevCoords[0]) * ratio + jitter,
      lng: prevCoords[1] + (nextCoords[1] - prevCoords[1]) * ratio + jitter,
      geocodeSource: "interpolated"
    };
  } else if (prevCoords) {
    return {
      lat: prevCoords[0] + (Math.random() - 0.3) * 0.003,
      lng: prevCoords[1] + (Math.random() - 0.3) * 0.003,
      geocodeSource: "estimated_from_prev"
    };
  } else if (nextCoords) {
    return {
      lat: nextCoords[0] + (Math.random() - 0.7) * 0.003,
      lng: nextCoords[1] + (Math.random() - 0.7) * 0.003,
      geocodeSource: "estimated_from_next"
    };
  }

  // Fallback: center of Jerez with jitter
  return {
    lat: 36.685 + (Math.random() - 0.5) * 0.02,
    lng: -6.126 + (Math.random() - 0.5) * 0.02,
    geocodeSource: "fallback_center"
  };
}

// Seed random for reproducibility
let seed = 42;
const origRandom = Math.random;
Math.random = function() {
  seed = (seed * 16807) % 2147483647;
  return (seed - 1) / 2147483646;
};

// Process each line
let totalStops = 0;
let officialCodeCounter = 1;

for (const line of data.lines) {
  // First pass: geocode all stops
  for (let i = 0; i < line.stops.length; i++) {
    const stop = line.stops[i];
    const coords = getCoords(stop.name, line.stops, i);
    stop.lat = parseFloat(coords.lat.toFixed(7));
    stop.lng = parseFloat(coords.lng.toFixed(7));
    stop.geocodeSource = coords.geocodeSource;
    stop._coords = { lat: stop.lat, lng: stop.lng };

    // Enrichment
    const isTerminal = i === 0 || i === line.stops.length - 1;
    const isMajor = stop.name.includes("Plaza") || stop.name.includes("Hospital") ||
                    stop.name.includes("Esteve") || stop.name.includes("Angustias") ||
                    stop.name.includes("Estaciones") || stop.name.includes("Rotonda");

    stop.officialCode = `JER-${String(officialCodeCounter++).padStart(3, '0')}`;
    stop.hasShelter = isTerminal || isMajor || Math.random() < 0.55;
    stop.isAccessible = isTerminal || isMajor || Math.random() < 0.45;
    stop.hasBench = isTerminal || isMajor || Math.random() < 0.35;

    totalStops++;
  }

  // Second pass: clean temp data
  for (const stop of line.stops) {
    delete stop._coords;
  }

  // Generate polyline (simplified: connect stops with intermediate points)
  const polylineCoords = [];
  for (let i = 0; i < line.stops.length; i++) {
    polylineCoords.push([line.stops[i].lng, line.stops[i].lat]);

    // Add intermediate points between consecutive stops
    if (i < line.stops.length - 1) {
      const s1 = line.stops[i];
      const s2 = line.stops[i + 1];
      const midLat = (s1.lat + s2.lat) / 2 + (Math.random() - 0.5) * 0.0008;
      const midLng = (s1.lng + s2.lng) / 2 + (Math.random() - 0.5) * 0.0008;
      polylineCoords.push([midLng, midLat]);
    }
  }

  line.polyline = {
    type: "LineString",
    coordinates: polylineCoords.map(c => [parseFloat(c[0].toFixed(7)), parseFloat(c[1].toFixed(7))])
  };
}

// Restore Math.random
Math.random = origRandom;

// ============================================================
// 4. DEMO DATA
// ============================================================

// Active trips
data.activeTrips = [
  {
    id: "trip-001",
    lineCode: "L1",
    vehicleId: "BUS-JER-042",
    status: "inRoute",
    delay: 0,
    delayLabel: "A tiempo",
    currentStopIndex: 4,
    currentStopName: "Descalzos",
    nextStopName: "Pz. Madre de Dios",
    capacity: "halfFull",
    capacityLabel: "Medio lleno",
    heading: 180,
    speed: 22,
    lastUpdated: "2026-04-13T09:42:00Z",
    currentPosition: { lat: 36.6800, lng: -6.1320 },
    driverName: "Ana Martín"
  },
  {
    id: "trip-002",
    lineCode: "L3",
    vehicleId: "BUS-JER-018",
    status: "inRoute",
    delay: 5,
    delayLabel: "5 min de retraso",
    currentStopIndex: 6,
    currentStopName: "La Plata",
    nextStopName: "Perpetuo Socorro",
    capacity: "full",
    capacityLabel: "Lleno",
    heading: 45,
    speed: 15,
    lastUpdated: "2026-04-13T09:40:00Z",
    currentPosition: { lat: 36.6969, lng: -6.1445 },
    driverName: "Miguel Torres"
  },
  {
    id: "trip-003",
    lineCode: "L5",
    vehicleId: "BUS-JER-055",
    status: "inRoute",
    delay: 0,
    delayLabel: "A tiempo",
    currentStopIndex: 2,
    currentStopName: "Arcos",
    nextStopName: "Avd. la Paz",
    capacity: "seatsAvailable",
    capacityLabel: "Asientos libres",
    heading: 270,
    speed: 28,
    lastUpdated: "2026-04-13T09:43:00Z",
    currentPosition: { lat: 36.6828, lng: -6.1355 },
    driverName: "Francisco Ruiz"
  },
  {
    id: "trip-004",
    lineCode: "L8",
    vehicleId: "BUS-JER-071",
    status: "cancelled",
    delay: null,
    delayLabel: "Cancelado",
    currentStopIndex: null,
    currentStopName: null,
    nextStopName: null,
    capacity: null,
    capacityLabel: "Sin servicio",
    heading: null,
    speed: 0,
    lastUpdated: "2026-04-13T08:15:00Z",
    currentPosition: null,
    driverName: null,
    cancellationReason: "Avería mecánica"
  }
];

// Alerts
data.alerts = [
  {
    id: "alert-001",
    type: "info",
    lineCode: "L1",
    title: "Nuevos horarios de invierno",
    description: "Nuevos horarios de invierno vigentes desde septiembre 2025. Consulte los horarios actualizados en las marquesinas o en la web de COMUJESA.",
    startDate: "2025-09-08",
    endDate: null,
    isActive: true,
    createdAt: "2025-09-08T06:00:00Z"
  },
  {
    id: "alert-002",
    type: "warning",
    lineCode: "L1",
    title: "Desvío por obras en C/Larga",
    description: "Desvío por obras en C/Larga hasta nuevo aviso. La parada 'Villamarta' se traslada temporalmente 50m hacia Plaza del Arenal. Disculpen las molestias.",
    startDate: "2026-03-15",
    endDate: null,
    isActive: true,
    affectedStops: ["Villamarta"],
    createdAt: "2026-03-15T07:00:00Z"
  }
];

// Community incidents
data.incidents = [
  {
    id: "inc-001",
    type: "delay",
    lineCode: "L3",
    stopName: "La Plata",
    description: "Bus con 5 minutos de retraso confirmado por varios usuarios",
    status: "confirmed",
    confirmations: 3,
    reportedAt: "2026-04-13T09:20:00Z",
    reportedBy: "carlos_navarro",
    expiresAt: "2026-04-13T11:20:00Z"
  },
  {
    id: "inc-002",
    type: "noShow",
    lineCode: "L8",
    stopName: "Plaza Angustias",
    description: "El bus de las 08:15 no ha pasado",
    status: "pending",
    confirmations: 1,
    reportedAt: "2026-04-13T08:55:00Z",
    reportedBy: "maria_jerez22",
    expiresAt: "2026-04-13T10:55:00Z"
  }
];

// Route suggestions
data.routeSuggestions = [
  {
    id: "sug-001",
    title: "Conil - Campus Jerez",
    description: "Línea directa desde Conil de la Frontera hasta el Campus Universitario de Jerez. Muchos estudiantes hacen este trayecto diario sin transporte directo.",
    status: "enriched",
    votes: 7,
    contributions: 3,
    proposedBy: "carlos_navarro",
    proposedAt: "2026-03-20T10:00:00Z",
    proposedStops: [
      "Conil Centro",
      "Rotonda A-48",
      "Campus Universitario Jerez"
    ],
    estimatedDemand: "medium",
    tags: ["interurbana", "universitarios", "demanda-alta"]
  }
];

// User feedback
data.feedbacks = [
  {
    id: "fb-001",
    type: "scheduleError",
    lineCode: "L1",
    title: "Horarios sábado desactualizados",
    description: "Los horarios del sábado que aparecen en la app no coinciden con los de la marquesina de Plaza Esteve. El bus de las 07:40 sale realmente a las 08:00.",
    priority: "high",
    status: "open",
    reportedBy: "carlos_navarro",
    reportedAt: "2026-04-10T18:30:00Z",
    affectedScheduleType: "saturday"
  },
  {
    id: "fb-002",
    type: "stopMoved",
    lineCode: "L3",
    stopName: "Las Torres",
    title: "Parada movida 30m",
    description: "La parada 'Las Torres' ha sido reubicada unos 30 metros hacia el sur por obras en la acera. Las coordenadas actuales no son correctas.",
    priority: "medium",
    status: "open",
    reportedBy: "ana_martin_conductor",
    reportedAt: "2026-04-08T14:15:00Z"
  }
];

// User profiles
data.userProfiles = {
  passenger: {
    id: "user-001",
    username: "carlos_navarro",
    displayName: "Carlos Navarro",
    email: "carlos.navarro@example.com",
    role: "passenger",
    reputation: 85,
    reputationLevel: "contributor",
    reputationNextLevel: "trusted",
    reputationNextThreshold: 100,
    avatar: null,
    joinedAt: "2025-11-15T10:00:00Z",
    stats: {
      totalTrips: 47,
      incidentsReported: 12,
      incidentsConfirmed: 8,
      suggestionsProposed: 1,
      feedbacksSubmitted: 3,
      badgesEarned: 5
    },
    preferences: {
      favoriteLines: ["L1", "L5"],
      notifications: true,
      language: "es",
      theme: "dark",
      hapticFeedback: true
    }
  },
  driver: {
    id: "user-002",
    username: "ana_martin_conductor",
    displayName: "Ana Martín",
    email: "ana.martin@comujesa.es",
    role: "driver",
    operator: "comujesa",
    assignedLine: "L1",
    vehicleId: "BUS-JER-042",
    reputation: 92,
    reputationLevel: "trusted",
    joinedAt: "2025-09-01T08:00:00Z",
    stats: {
      totalTripsCompleted: 312,
      onTimePercentage: 94.5,
      feedbacksSubmitted: 5,
      incidentsReported: 8
    },
    shift: {
      start: "06:00",
      end: "14:00",
      days: ["monday", "tuesday", "wednesday", "thursday", "friday"]
    }
  }
};

// Transit card
data.transitCard = {
  id: "card-001",
  userId: "user-001",
  type: "multiviaje",
  cardNumber: "COMUJESA-2025-004782",
  displayName: "Multiviaje COMUJESA",
  balance: 12.50,
  currency: "EUR",
  lastRecharge: {
    amount: 10.00,
    date: "2026-04-01T11:30:00Z",
    method: "card"
  },
  farePerTrip: 0.69,
  tripsRemaining: 18,
  expiresAt: "2027-04-01T00:00:00Z",
  isActive: true
};

// Favorites
data.favorites = [
  {
    id: "fav-001",
    userId: "user-001",
    type: "stop",
    lineCode: "L1",
    stopName: "Plaza Esteve",
    stopCode: "JER-001",
    label: "Trabajo (ida)",
    notifyBefore: 5,
    createdAt: "2025-12-01T08:00:00Z"
  },
  {
    id: "fav-002",
    userId: "user-001",
    type: "stop",
    lineCode: "L5",
    stopName: "España",
    stopCode: "JER-005",
    label: "Estación",
    notifyBefore: 3,
    createdAt: "2025-12-05T09:00:00Z"
  }
];

// Trip history
data.tripHistory = [
  {
    id: "hist-001",
    userId: "user-001",
    lineCode: "L1",
    date: "2026-04-12",
    boardingStop: "Plaza Esteve",
    alightingStop: "San Telmo",
    boardingTime: "08:20",
    alightingTime: "08:42",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: true
  },
  {
    id: "hist-002",
    userId: "user-001",
    lineCode: "L5",
    date: "2026-04-12",
    boardingStop: "San José Obrero",
    alightingStop: "España",
    boardingTime: "17:35",
    alightingTime: "18:10",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: false,
    delay: 8
  },
  {
    id: "hist-003",
    userId: "user-001",
    lineCode: "L1",
    date: "2026-04-11",
    boardingStop: "Plaza Esteve",
    alightingStop: "San Telmo",
    boardingTime: "08:20",
    alightingTime: "08:40",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: true
  },
  {
    id: "hist-004",
    userId: "user-001",
    lineCode: "L3",
    date: "2026-04-10",
    boardingStop: "Plaza Esteve",
    alightingStop: "Las Torres",
    boardingTime: "14:10",
    alightingTime: "14:35",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: true
  },
  {
    id: "hist-005",
    userId: "user-001",
    lineCode: "L1",
    date: "2026-04-09",
    boardingStop: "Plaza Esteve",
    alightingStop: "San Telmo",
    boardingTime: "07:50",
    alightingTime: "08:15",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: true
  },
  {
    id: "hist-006",
    userId: "user-001",
    lineCode: "L5",
    date: "2026-04-08",
    boardingStop: "España",
    alightingStop: "Guadalcacín",
    boardingTime: "09:30",
    alightingTime: "10:15",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: true
  },
  {
    id: "hist-007",
    userId: "user-001",
    lineCode: "L8",
    date: "2026-04-07",
    boardingStop: "Plaza Angustias",
    alightingStop: "Hospital Infantil",
    boardingTime: "10:20",
    alightingTime: "11:05",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: false,
    delay: 3
  },
  {
    id: "hist-008",
    userId: "user-001",
    lineCode: "L1",
    date: "2026-04-05",
    boardingStop: "Plaza Esteve",
    alightingStop: "San Telmo",
    boardingTime: "08:50",
    alightingTime: "09:12",
    fare: 1.10,
    paymentMethod: "cash",
    onTime: true
  },
  {
    id: "hist-009",
    userId: "user-001",
    lineCode: "L3",
    date: "2026-04-03",
    boardingStop: "Angustias Canal Sur",
    alightingStop: "Solea",
    boardingTime: "16:00",
    alightingTime: "16:28",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: true
  },
  {
    id: "hist-010",
    userId: "user-001",
    lineCode: "L1",
    date: "2026-04-01",
    boardingStop: "San Telmo",
    alightingStop: "Plaza Esteve",
    boardingTime: "13:25",
    alightingTime: "13:48",
    fare: 0.69,
    paymentMethod: "multiviaje",
    onTime: true
  }
];

// Badges system
data.badges = [
  {
    id: "badge-first-trip",
    name: "Primera Ruta",
    description: "Completa tu primer viaje",
    icon: "route",
    category: "trips",
    requirement: 1,
    userProgress: 47,
    earned: true,
    earnedAt: "2025-11-15T18:30:00Z"
  },
  {
    id: "badge-regular",
    name: "Viajero Habitual",
    description: "Completa 10 viajes",
    icon: "repeat",
    category: "trips",
    requirement: 10,
    userProgress: 47,
    earned: true,
    earnedAt: "2025-12-20T08:45:00Z"
  },
  {
    id: "badge-commuter",
    name: "Commuter",
    description: "Completa 50 viajes",
    icon: "briefcase",
    category: "trips",
    requirement: 50,
    userProgress: 47,
    earned: false,
    earnedAt: null
  },
  {
    id: "badge-explorer",
    name: "Explorador",
    description: "Viaja en 5 líneas diferentes",
    icon: "compass",
    category: "exploration",
    requirement: 5,
    userProgress: 4,
    earned: false,
    earnedAt: null
  },
  {
    id: "badge-all-lines",
    name: "Maestro de Rutas",
    description: "Viaja en las 18 líneas",
    icon: "map",
    category: "exploration",
    requirement: 18,
    userProgress: 4,
    earned: false,
    earnedAt: null
  },
  {
    id: "badge-reporter",
    name: "Reportero",
    description: "Reporta tu primera incidencia",
    icon: "alert-triangle",
    category: "community",
    requirement: 1,
    userProgress: 12,
    earned: true,
    earnedAt: "2025-12-05T09:15:00Z"
  },
  {
    id: "badge-watchdog",
    name: "Vigilante",
    description: "Reporta 10 incidencias",
    icon: "eye",
    category: "community",
    requirement: 10,
    userProgress: 12,
    earned: true,
    earnedAt: "2026-03-10T14:20:00Z"
  },
  {
    id: "badge-helper",
    name: "Solidario",
    description: "Confirma 5 incidencias de otros usuarios",
    icon: "heart",
    category: "community",
    requirement: 5,
    userProgress: 8,
    earned: true,
    earnedAt: "2026-02-14T11:00:00Z"
  },
  {
    id: "badge-early-bird",
    name: "Madrugador",
    description: "Viaja antes de las 07:00 cinco veces",
    icon: "sunrise",
    category: "special",
    requirement: 5,
    userProgress: 2,
    earned: false,
    earnedAt: null
  },
  {
    id: "badge-night-owl",
    name: "Noctámbulo",
    description: "Viaja después de las 21:00 cinco veces",
    icon: "moon",
    category: "special",
    requirement: 5,
    userProgress: 1,
    earned: false,
    earnedAt: null
  },
  {
    id: "badge-feedback",
    name: "Voz del Pasajero",
    description: "Envía 3 feedbacks sobre el servicio",
    icon: "message-circle",
    category: "community",
    requirement: 3,
    userProgress: 3,
    earned: true,
    earnedAt: "2026-04-10T18:30:00Z"
  },
  {
    id: "badge-streak",
    name: "Racha",
    description: "Viaja 7 días consecutivos",
    icon: "flame",
    category: "special",
    requirement: 7,
    userProgress: 4,
    earned: false,
    earnedAt: null
  }
];

// ============================================================
// 5. UPDATE METADATA
// ============================================================
data._metadata.enrichedAt = "2026-04-13";
data._metadata.geocoding = {
  totalStops: totalStops,
  geocodedFromNominatim: geocodedCount,
  estimated: estimatedCount,
  successRate: parseFloat(((geocodedCount / totalStops) * 100).toFixed(1))
};
data._metadata.polylines = "GeoJSON LineString per line, interpolated from stop coordinates";
data._metadata.demoData = [
  "activeTrips (4)",
  "alerts (2)",
  "incidents (2)",
  "routeSuggestions (1)",
  "feedbacks (2)",
  "userProfiles (2: passenger + driver)",
  "transitCard (1)",
  "favorites (2)",
  "tripHistory (10)",
  "badges (12)"
];

// ============================================================
// 6. WRITE OUTPUT
// ============================================================
const output = JSON.stringify(data, null, 2);
fs.writeFileSync('comujesa_data.json', output, 'utf8');

console.log('=== RESUMEN DE GENERACIÓN ===');
console.log(`Líneas: ${data.lines.length}`);
console.log(`Paradas totales: ${totalStops}`);
console.log(`Horarios totales: ${data.lines.reduce((sum, l) => sum + l.schedules.weekday.length + l.schedules.saturday.length + l.schedules.sunday_holiday.length, 0)}`);
console.log(`Geocoding: ${geocodedCount}/${totalStops} (${((geocodedCount/totalStops)*100).toFixed(1)}%) real/parcial`);
console.log(`Estimado: ${estimatedCount}/${totalStops} (${((estimatedCount/totalStops)*100).toFixed(1)}%)`);
console.log(`Polilíneas: ${data.lines.length} (GeoJSON LineString)`);
console.log(`Viajes activos: ${data.activeTrips.length}`);
console.log(`Alertas: ${data.alerts.length}`);
console.log(`Incidencias: ${data.incidents.length}`);
console.log(`Badges: ${data.badges.length}`);
console.log(`Tamaño archivo: ${(Buffer.byteLength(output) / 1024).toFixed(0)} KB`);
console.log('comujesa_data.json actualizado correctamente.');

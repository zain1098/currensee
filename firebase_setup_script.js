// 🔥 CurrenSee Firebase Setup Script
// Run this script to initialize your Firebase database

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://currensee-f1718.firebaseio.com"
});

const db = admin.firestore();
const { importantCurrencies, importantWorldCities } = require('./important_countries_data');

// Flag API base URLs
const FLAG_API_BASE = 'https://flagcdn.com/w40/';
const FLAG_API_HIGH_RES = 'https://flagcdn.com/w80/';

// Helper function to get flag URL from API
function getFlagUrl(countryCode, size = 'medium') {
  if (countryCode === 'btc' || countryCode === 'eth' || countryCode === 'ltc' || 
      countryCode === 'xrp' || countryCode === 'ada') {
    // For cryptocurrencies, use a placeholder or custom icon
    return 'https://via.placeholder.com/40x30/6366f1/ffffff?text=' + countryCode.toUpperCase();
  }
  
  const baseUrl = size === 'high' ? FLAG_API_HIGH_RES : FLAG_API_BASE;
  return `${baseUrl}${countryCode}.png`;
}

async function setupCurrencies() {
  console.log('🚀 Setting up currencies collection...');
  
  for (const currency of importantCurrencies) {
    try {
      const currencyData = {
        id: currency.code,
        code: currency.code,
        name: currency.name,
        symbol: currency.symbol,
        flag_url: getFlagUrl(currency.flag, 'medium'),
        flag_url_high_res: getFlagUrl(currency.flag, 'high'),
        country: currency.country,
        status: 'active',
        display_order: importantCurrencies.indexOf(currency) + 1,
        is_base_currency: currency.code === 'USD',
        is_featured: ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'PKR', 'INR'].includes(currency.code),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        last_modified_by: 'system',
        metadata: {
          description: `${currency.name} (${currency.code})`,
          iso_code: currency.code,
          decimal_places: currency.code === 'JPY' ? 0 : 2,
          symbol_position: 'before'
        }
      };
      
      await db.collection('currencies').doc(currency.code).set(currencyData);
      console.log(`✅ Added currency: ${currency.code} - ${currency.name}`);
    } catch (error) {
      console.error(`❌ Error adding currency ${currency.code}:`, error);
    }
  }
  
  console.log('✅ Currencies setup completed!');
}

async function setupWorldClockCities() {
  console.log('🌍 Setting up world clock cities collection...');
  
  for (const city of importantWorldCities) {
    try {
      const cityData = {
        id: `${city.city.toLowerCase().replace(/\s+/g, '_')}_${city.country.toLowerCase().replace(/\s+/g, '_')}`,
        city: city.city,
        country: city.country,
        timezone: city.timezone,
        flag_url: getFlagUrl(city.flag, 'medium'),
        flag_url_high_res: getFlagUrl(city.flag, 'high'),
        gmt_offset: city.gmt,
        status: 'active',
        display_order: importantWorldCities.indexOf(city) + 1,
        is_featured: ['New York', 'London', 'Tokyo', 'Hong Kong', 'Singapore', 'Dubai', 'Sydney'].includes(city.city),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        last_modified_by: 'system',
        metadata: {
          description: `${city.city}, ${city.country}`,
          region: getRegionFromTimezone(city.timezone),
          population: 'N/A', // Can be updated later
          coordinates: 'N/A' // Can be updated later
        }
      };
      
      await db.collection('world_clock_cities').doc(cityData.id).set(cityData);
      console.log(`✅ Added city: ${city.city}, ${city.country}`);
    } catch (error) {
      console.error(`❌ Error adding city ${city.city}:`, error);
    }
  }
  
  console.log('✅ World clock cities setup completed!');
}

function getRegionFromTimezone(timezone) {
  if (timezone.startsWith('America/')) return 'Americas';
  if (timezone.startsWith('Europe/')) return 'Europe';
  if (timezone.startsWith('Asia/')) return 'Asia';
  if (timezone.startsWith('Africa/')) return 'Africa';
  if (timezone.startsWith('Australia/') || timezone.startsWith('Pacific/')) return 'Oceania';
  if (timezone.startsWith('Atlantic/')) return 'Atlantic';
  if (timezone.startsWith('Indian/')) return 'Indian Ocean';
  return 'Other';
}

async function setupAppSettings() {
  console.log('⚙️ Setting up app settings collection...');
  
  const appSettings = [
    {
      id: 'default_base_currency',
      key: 'default_base_currency',
      value: 'USD',
      type: 'string',
      description: 'Default base currency for the app',
      category: 'currency',
      is_editable: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: 'auto_refresh_interval',
      key: 'auto_refresh_interval',
      value: '300', // 5 minutes in seconds
      type: 'number',
      description: 'Auto refresh interval for currency rates in seconds',
      category: 'performance',
      is_editable: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: 'max_decimal_places',
      key: 'max_decimal_places',
      value: '4',
      type: 'number',
      description: 'Maximum decimal places for currency display',
      category: 'display',
      is_editable: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: 'enable_push_notifications',
      key: 'enable_push_notifications',
      value: 'true',
      type: 'boolean',
      description: 'Enable push notifications for currency alerts',
      category: 'notifications',
      is_editable: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: 'maintenance_mode',
      key: 'maintenance_mode',
      value: 'false',
      type: 'boolean',
      description: 'Enable maintenance mode for the app',
      category: 'system',
      is_editable: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: 'flag_api_base_url',
      key: 'flag_api_base_url',
      value: 'https://flagcdn.com/w40/',
      type: 'string',
      description: 'Base URL for flag API',
      category: 'api',
      is_editable: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: 'flag_api_high_res_url',
      key: 'flag_api_high_res_url',
      value: 'https://flagcdn.com/w80/',
      type: 'string',
      description: 'High resolution flag API URL',
      category: 'api',
      is_editable: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }
  ];
  
  for (const setting of appSettings) {
    try {
      await db.collection('app_settings').doc(setting.id).set(setting);
      console.log(`✅ Added setting: ${setting.key}`);
    } catch (error) {
      console.error(`❌ Error adding setting ${setting.key}:`, error);
    }
  }
  
  console.log('✅ App settings setup completed!');
}

async function setupDatabase() {
  console.log('🔥 Starting CurrenSee Firebase Database Setup...\n');
  console.log(`📊 Total currencies to add: ${importantCurrencies.length}`);
  console.log(`🌍 Total world clock cities to add: ${importantWorldCities.length}\n`);
  
  try {
    await setupCurrencies();
    await setupWorldClockCities();
    await setupAppSettings();
    
    console.log('\n🎉 Database setup completed successfully!');
    console.log(`\n📈 Summary:`);
    console.log(`   • Currencies: ${importantCurrencies.length} countries`);
    console.log(`   • World Clock Cities: ${importantWorldCities.length} cities`);
    console.log(`   • App Settings: 7 configurations`);
    console.log(`   • Flags: All fetched from API (flagcdn.com)`);
    console.log(`\n🔗 Flag API URLs:`);
    console.log(`   • Medium: ${FLAG_API_BASE}`);
    console.log(`   • High Res: ${FLAG_API_HIGH_RES}`);
    
  } catch (error) {
    console.error('❌ Database setup failed:', error);
  }
}

if (require.main === module) {
  setupDatabase();
}

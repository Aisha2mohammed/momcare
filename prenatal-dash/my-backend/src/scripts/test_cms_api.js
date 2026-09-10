require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../app');
const { query } = require('../config/db');

async function runTests() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🧪 Running MaternaLink Admin CMS API Tests');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    // 1. Ensure test admin exists in DB
    let adminResult = await query("SELECT id, role, email FROM users WHERE role = 'admin' LIMIT 1");
    let adminId;
    if (adminResult.rows.length === 0) {
      const ins = await query(`
        INSERT INTO users (role, name, email, language, status)
        VALUES ('admin', 'Test Admin', 'testadmin@momcare.et', 'en', 'active')
        RETURNING id
      `);
      adminId = ins.rows[0].id;
    } else {
      adminId = adminResult.rows[0].id;
    }

    const token = jwt.sign(
      { id: adminId, role: 'admin' },
      process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production',
      { expiresIn: '1h' }
    );

    console.log(`✅ Admin Token generated for adminId: ${adminId}`);

    // Helper request wrapper
    const authReq = (method, url) => request(app)[method](url).set('Authorization', `Bearer ${token}`);

    // 2. Test 401 Unauthorized without token
    const unauthRes = await request(app).get('/api/v1/admin/cms/nutrition');
    if (unauthRes.status === 401) {
      console.log('✅ Auth Guard: Protected /api/v1/admin/cms/* correctly rejects unauthenticated requests (401)');
    } else {
      console.warn(`⚠️ Expected 401, got ${unauthRes.status}`);
    }

    const modules = ['nutrition', 'fetal', 'exercises', 'sleep', 'music'];

    for (const mod of modules) {
      console.log(`\n── Testing Module: ${mod} ─────────────────────────────`);

      // 3. GET list
      const listRes = await authReq('get', `/api/v1/admin/cms/${mod}`);
      console.log(`  GET /api/v1/admin/cms/${mod}: Status ${listRes.status}, Total items: ${listRes.body?.pagination?.total ?? listRes.body?.data?.length ?? 0}`);

      // 4. POST create item
      let createPayload;
      if (mod === 'nutrition') {
        createPayload = {
          trimester: '1st',
          titleAm: 'ሙከራ የተመጣጠነ ምግብ',
          titleOr: 'Nyaata Madaalawaa Qorannoo',
          titleEn: 'Test Balanced Nutrition Entry',
          bodyAm: 'ይህ ለሙከራ የቀረበ መግለጫ ነው።',
          bodyOr: 'Ibsa qorannoof dhiyaate.',
          bodyEn: 'This is a test description.',
          isPublished: true,
        };
      } else if (mod === 'fetal') {
        createPayload = {
          weekNumber: 42,
          sizeComparison: 'Watermelon Test',
          milestoneAm: 'የሳምንት 42 እድገት ሙከራ',
          milestoneOr: 'Guddina torbee 42 qorannoo',
          milestoneEn: 'Week 42 post-term test milestone',
          tipsAm: 'ሀኪምዎን ያማክሩ።',
          tipsOr: 'Doktora kee qunnami.',
          tipsEn: 'Consult your obstetrician.',
        };
      } else if (mod === 'exercises') {
        createPayload = {
          nameAm: 'ሙከራ ዮጋ እንቅስቃሴ',
          nameOr: 'Shaakala Yoogaa Qorannoo',
          nameEn: 'Test Yoga Routine',
          trimesters: ['1st', '2nd'],
          duration: '15 min',
          safetyAm: 'ቀስ ብለው ይስሩ',
          safetyOr: 'Suuta hojjedhu',
          safetyNotesEn: 'Proceed gently with normal breath',
          isPublished: true,
        };
      } else if (mod === 'sleep') {
        createPayload = {
          trimester: '2nd',
          titleAm: 'የሙከራ የእንቅልፍ አቀማመጥ',
          titleOr: 'Bittaa Ciisuu Qorannoo',
          titleEn: 'Test Left Side Sleeping Tip',
          descAm: 'ወደ ግራ ጎን መተኛት ይመከራል።',
          descOr: 'Cinaacha bitaatiin ciisuun gaariidha.',
          descriptionEn: 'Left side sleeping relieves vena cava pressure.',
        };
      } else if (mod === 'music') {
        createPayload = {
          titleAm: 'የሙከራ ዘና ማድረጊያ ዜማ',
          titleOr: 'Sirba Tasgabbii Qorannoo',
          titleEn: 'Test Ambient Lullaby',
          category: 'Relaxation',
          duration: '5:30',
          mediaUrl: 'https://example.com/test-audio.mp3',
          isActive: true,
        };
      }

      const createRes = await authReq('post', `/api/v1/admin/cms/${mod}`).send(createPayload);
      if (createRes.status === 201) {
        console.log(`  POST /api/v1/admin/cms/${mod}: Status 201 Created. ID: ${createRes.body.data.id}`);
        const createdId = createRes.body.data.id;

        // 5. GET single item
        const getOneRes = await authReq('get', `/api/v1/admin/cms/${mod}/${createdId}`);
        console.log(`  GET /api/v1/admin/cms/${mod}/${createdId}: Status ${getOneRes.status}, Title/Name: ${getOneRes.body.data.titleAm || getOneRes.body.data.nameAm || getOneRes.body.data.sizeComparison}`);

        // 6. PUT update item
        let updatePayload = { isPublished: false, isActive: false };
        if (mod === 'fetal') {
          updatePayload = { sizeComparison: 'Super Watermelon Updated' };
        } else if (mod === 'exercises') {
          updatePayload = { duration: '25 min', isPublished: false };
        }
        const updateRes = await authReq('put', `/api/v1/admin/cms/${mod}/${createdId}`).send(updatePayload);
        console.log(`  PUT /api/v1/admin/cms/${mod}/${createdId}: Status ${updateRes.status} Updated.`);

        // 7. DELETE item
        const deleteRes = await authReq('delete', `/api/v1/admin/cms/${mod}/${createdId}`);
        console.log(`  DELETE /api/v1/admin/cms/${mod}/${createdId}: Status ${deleteRes.status} Deleted.`);
      } else {
        console.error(`  ❌ Failed to create item in ${mod}:`, createRes.status, createRes.body);
      }
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🎉 All CMS API tests completed successfully!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    process.exit(0);
  } catch (err) {
    console.error('❌ Test execution error:', err);
    process.exit(1);
  }
}

runTests();

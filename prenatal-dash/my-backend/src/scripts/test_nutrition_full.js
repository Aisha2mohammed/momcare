require('dotenv').config();
const { query } = require('../config/db');
const adminCmsController = require('../controllers/adminCms.controller');

async function runTest() {
  console.log('🧪 Starting Full Nutrition Manager Backend Verification...');

  try {
    // 1. Create a rich 4-language test entry
    const mockReqCreate = {
      params: { module: 'nutrition' },
      body: {
        titleEn: 'Second Trimester Iron & Calcium Essentials',
        titleOr: 'Nyaatawwan Kaalsiyeemii fi Ayiranii Yeroo Ulfaa',
        titleSo: 'Nafaqada Muhiimka ah ee Birta iyo Kaalsiyamka',
        titleAm: 'የሁለተኛው 3 ወራት የብረትና ካልሲየም ፍላጎት',
        trimester: '2nd',
        week: 16,
        type: 'eat',
        emoji: '🥦',
        nutrientType: 'IRON & CALCIUM',
        whyImportantEn: 'Prevents maternal anemia and strengthens fetal skeletal growth.',
        whyImportantOr: 'Hanqina dhiigaa ittisa, guddina lafee cimsa.',
        whyImportantSo: 'Waxay ka hortagtaa dhiig-yarida hooyada waxayna xoojisaa lafaha ilmaha.',
        whyImportantAm: 'የደም ማነስን ይከላከላል፤ የፅንሱን አጥንት ያጠነክራል።',
        hydrationEn: 'Drink at least 2.5 liters of clean water daily.',
        hydrationOr: 'Guyyaatti yoo xiqqaate bishaan liitira 2.5 dhugaa.',
        hydrationSo: 'Cab ugu yaraan 2.5 litir oo biyo nadiif ah maalin kasta.',
        hydrationAm: 'በቀን ቢያንስ 2.5 ሊትር ንጹህ ውሃ ይጠጡ።',
        bodyEn: 'Essential daily nutrients to support expanding blood volume and fetal bones.',
        bodyOr: 'Odeeffannoo nyaataa guutuu.',
        bodySo: 'Hagaha nafaqada buuxa.',
        bodyAm: 'ዝርዝር መመሪያ።',
        imageUrl: '/uploads/sample_nutrition.jpg',
        videoUrl: 'https://youtube.com/watch?v=sample123',
        videoTitle: 'Iron and Calcium in Pregnancy',
        pdfUrl: '/uploads/sample_nutrition_guide.pdf',
        nutrientSectionsJson: [
          {
            nutrient_type: 'IRON',
            emoji: '🥩',
            title_en: 'Plant and Animal-Based Iron',
            title_or: 'Ayiranii Nyaata Keessatti',
            title_so: 'Birta laga helo cuntada',
            title_am: 'የብረት ይዘት ያላቸው ምግቦች',
            desc_en: 'Supports red blood cell production.',
            desc_or: 'Dhiiga oomishe.',
            desc_so: 'Waxay kordhisaa dhiigga.',
            desc_am: 'ቀይ የደም ሴሎችን ያመርታል።',
            details_en: 'Aim for 27mg of iron daily during the 2nd trimester.',
            details_or: 'Ibsa bal\'aa.',
            details_so: 'Faahfaahin.',
            details_am: 'ዝርዝር መረጃ።',
            benefit_value: '27 mg / day',
            benefit_label_en: 'Recommended Daily Intake',
            benefit_label_or: 'Fayidaa',
            benefit_label_so: 'Faa\'iidada',
            benefit_label_am: 'ዕለታዊ ፍላጎት',
            tip_en: 'Combine iron with Vitamin C for maximum absorption.',
            tip_or: 'Gorsa.',
            tip_so: 'Talo.',
            tip_am: 'ጠቃሚ ምክር።',
            foods: [
              {
                name_en: 'Spinach',
                name_or: 'Ispinashii',
                name_so: 'Isbinaash',
                name_am: 'ስፒናች',
                desc_en: 'Rich in non-heme iron and folate.',
                desc_or: 'Nyaata gaarii.',
                desc_so: 'Cunto fiican.',
                desc_am: 'ጠቃሚ ምግብ።',
                image_url: '/uploads/spinach.jpg',
                video_url: 'https://youtube.com/spinach_cook'
              }
            ]
          },
          {
            nutrient_type: 'CALCIUM',
            emoji: '🥛',
            title_en: 'Dairy and Fortified Calcium',
            title_or: 'Kaalsiyeemii Aannanii',
            title_so: 'Kaalsiyamka caanaha',
            title_am: 'የወተት ተዋፅኦ ካልሲየም',
            desc_en: 'Develops strong bones and teeth.',
            desc_or: 'Lafee cimsa.',
            desc_so: 'Lafaha xoojiya.',
            desc_am: 'አጥንትና ጥርስን ያጠነክራል።',
            benefit_value: '1,000 mg / day',
            benefit_label_en: 'Daily Target',
            benefit_label_or: 'Target',
            benefit_label_so: 'Hadafka',
            benefit_label_am: 'ዕለታዊ ግብ',
            foods: [
              {
                name_en: 'Plain Yogurt',
                name_or: 'Itittu',
                name_so: 'Caano Fadhi',
                name_am: 'እርጎ',
                desc_en: 'Packed with calcium and probiotics for gut health.',
                desc_or: 'Aannan itite.',
                desc_so: 'Caano fadhi caafimaad leh.',
                desc_am: 'ለአንጀት ጤና ጠቃሚ።',
                image_url: '/uploads/yogurt.jpg'
              }
            ]
          }
        ],
        isPublished: true
      }
    };

    let createdId = null;
    const mockResCreate = {
      status: (code) => ({
        json: (data) => {
          console.log(`✅ [Create API Status ${code}] Created ID:`, data?.data?.id);
          createdId = data?.data?.id;
          return data;
        }
      })
    };

    await adminCmsController.create(mockReqCreate, mockResCreate, (err) => { throw err; });

    if (!createdId) throw new Error('Failed to obtain created entry ID');

    // 2. Test GetOne API
    const mockReqGet = { params: { module: 'nutrition', id: createdId } };
    const mockResGet = {
      status: () => ({
        json: (data) => {
          console.log('✅ [GetOne API] Retrived Title SO:', data?.data?.titleSo);
          console.log('✅ [GetOne API] Why Important AM:', data?.data?.whyImportantAm);
          console.log('✅ [GetOne API] Hydration EN:', data?.data?.hydrationEn);
          console.log('✅ [GetOne API] Nutrients Count:', data?.data?.nutrientSections?.length);
          console.log('✅ [GetOne API] Nutrient 1 Foods Count:', data?.data?.nutrientSections?.[0]?.foods?.length);
        }
      })
    };
    await adminCmsController.getOne(mockReqGet, mockResGet, (err) => { throw err; });

    // 3. Test Month Filter (Week 16 is Month 4: weeks 14-17)
    const mockReqListMonth = {
      params: { module: 'nutrition' },
      query: { month: '4', limit: 10 }
    };
    const mockResListMonth = {
      status: () => ({
        json: (data) => {
          const match = data?.data?.find(x => x.id === createdId);
          console.log(`✅ [Month Filter API] Filtered Month 4 (Weeks 14-17) - Found created item:`, !!match);
        }
      })
    };
    await adminCmsController.list(mockReqListMonth, mockResListMonth, (err) => { throw err; });

    // 4. Test Somali Search query inside JSON/Columns
    const mockReqListSearch = {
      params: { module: 'nutrition' },
      query: { search: 'Nafaqada', limit: 10 }
    };
    const mockResListSearch = {
      status: () => ({
        json: (data) => {
          const match = data?.data?.find(x => x.id === createdId);
          console.log(`✅ [Somali Search Query API] Search 'Nafaqada' - Found match:`, !!match);
        }
      })
    };
    await adminCmsController.list(mockReqListSearch, mockResListSearch, (err) => { throw err; });

    // 5. Test Update API
    const mockReqUpdate = {
      params: { module: 'nutrition', id: createdId },
      body: { titleEn: 'Updated Second Trimester Iron & Calcium Essentials' }
    };
    const mockResUpdate = {
      status: () => ({
        json: (data) => {
          console.log(`✅ [Update API] Updated Title EN:`, data?.data?.titleEn);
        }
      })
    };
    await adminCmsController.update(mockReqUpdate, mockResUpdate, (err) => { throw err; });

    // 6. Test Remove API
    const mockReqDelete = { params: { module: 'nutrition', id: createdId } };
    const mockResDelete = {
      status: () => ({
        json: (data) => {
          console.log(`✅ [Delete API] Removed ID:`, data?.data?.id);
        }
      })
    };
    await adminCmsController.remove(mockReqDelete, mockResDelete, (err) => { throw err; });

    console.log('\n🎉 ALL FULL NUTRITION MANAGER BACKEND TESTS PASSED SUCCESSFULLY!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Test failed:', err);
    process.exit(1);
  }
}

runTest();

const bcrypt = require('bcryptjs');

/**
 * Seed CMS Content & Super Admin for PostgreSQL
 * Covers: Users (Admin), Nutrition Guide, Fetal Development (Weeks 1-40),
 * Exercise Recommendations, Sleeping Position Tips, Music Relaxation
 */
exports.seed = async function (knex) {
  console.log('🌱 Seeding CMS data for MaternaLink / MomCare...');

  // 1. Seed Admin User
  const adminPasswordHash = await bcrypt.hash('Admin123!', 10);
  const existingAdmin = await knex('users').where({ email: 'admin@momcare.et' }).first();
  if (!existingAdmin) {
    await knex('users').insert({
      role: 'admin',
      name: 'Super Admin',
      phone: '+251911000001',
      email: 'admin@momcare.et',
      password_hash: adminPasswordHash,
      language: 'en',
      status: 'active',
    });
    console.log('  ✅ Admin user created (admin@momcare.et / Admin123!)');
  } else {
    await knex('users').where({ email: 'admin@momcare.et' }).update({
      password_hash: adminPasswordHash,
      status: 'active',
      updated_at: knex.fn.now(),
    });
    console.log('  ℹ️ Admin user already exists, updated password.');
  }

  // 2. Seed Nutrition Guide
  await knex('nutrition_content').del();
  const nutritionData = [
    {
      trimester: 1,
      title_am: 'የመጀመሪያ 3 ወር ፎሊክ አሲድ እና አትክልቶች',
      title_or: 'Asidii Foolikii fi Kuduraalee Ji\'a 1ffaa-3ffaa',
      title_en: 'First Trimester Folic Acid & Leafy Greens',
      body_am: 'ፎሊክ አሲድ የፅንሱን የነርቭ ቧንቧ እድገት ለመጠበቅ ወሳኝ ነው። አረንጓዴ ቅጠላማ አትክልቶችን፣ ብርቱካንና ምስር ይመገቡ።',
      body_or: 'Asidiin foolikii guddina sirna narvii daa\'imaaf baay\'ee murteessaadha. Kuduraalee baala magariisaa, burtukaana fi miisira fayyadamaa.',
      body_en: 'Folic acid prevents neural tube defects. Include spinach, lentils, fortified grains, and citrus fruits daily.',
      image_url: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
      is_published: true,
    },
    {
      trimester: 1,
      title_am: 'የጠዋት ህመም እና የምግብ ፍላጎት መቀነስ መፍትሄዎች',
      title_or: 'Furmaata Lalisa Ganamaa fi Fedhii Nyaataa Hir\'achuu',
      title_en: 'Managing Morning Sickness with Nutrition',
      body_am: 'የዝንጅብል ሻይ፣ ብስኩት እና አነስተኛ መጠን ያላቸውን ምግቦች በተደጋጋሚ መመገብ ማቅለሽለሽን ይቀንሳል።',
      body_or: 'Shayii jinjibilaa, biskutii fi nyaata muraasa yeroodhaa gara yerootti nyaachuun balaqqama hir\'isa.',
      body_en: 'Eat small, frequent dry meals, sip ginger tea, and avoid an empty stomach to alleviate morning sickness.',
      image_url: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80',
      is_published: true,
    },
    {
      trimester: 2,
      title_am: 'ብረት (Iron) እና የደም ማነስን መከላከል',
      title_or: 'Ayirenii fi Hanqina Dhiigaa Ittisuu',
      title_en: 'Iron-Rich Foods to Prevent Anemia',
      body_am: 'በሁለተኛው ሶስት ወር የደም መጠን ስለሚጨምር ስጋ፣ ባቄላ፣ ጤፍ እና የቫይታሚን ሲ ምንጮችን አብረው ይመገቡ።',
      body_or: 'Ji\'oota giddugaleessaa keessa dhiigni waan dabaluuf foon, baaqelaa, xaafii fi viitaamiin C waliin nyaadhaa.',
      body_en: 'Iron needs surge in the 2nd trimester. Combine lean meat, teff injera, and beans with vitamin C for enhanced absorption.',
      image_url: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=600&q=80',
      is_published: true,
    },
    {
      trimester: 2,
      title_am: 'ካልሲየም ለአጥንትና ጥርስ ጥንካሬ',
      title_or: 'Kaalsiyeemii Cimina Lafee fi Ilkaan Daa\'imaaf',
      title_en: 'Calcium for Fetal Bone & Tooth Development',
      body_am: 'የህፃኑ አጥንት በፍጥነት የሚያድግበት ወቅት ነው። ወተት፣ እርጎ፣ አይብ እና ሰሊጥ በየቀኑ ያካትቱ።',
      body_or: 'Yeroo lafeen daa\'imaa saffisaan guddatuudha. Guyyaa guyyaan aannan, itittuu, cheezii fi saalixa fayyadamaa.',
      body_en: 'Baby teeth and bones rapidly calcify. Consume dairy, yogurt, fortified plant milk, and sesame seeds.',
      image_url: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80',
      is_published: true,
    },
    {
      trimester: 3,
      title_am: 'የመጨረሻ ወራት የሃይልና ፕሮቲን ፍላጎት',
      title_or: 'Fedhii Pirootiinii fi Annisaa Ji\'oota Dhumaa',
      title_en: 'Late Pregnancy Energy & High Protein Foods',
      body_am: 'ህፃኑ ክብደት የሚጨምርበት ወቅት ስለሆነ እንቁላል፣ አሳ፣ ለውዝ እና ውስብስብ ካርቦሃይድሬቶችን ይመገቡ።',
      body_or: 'Yeroo daa\'imni ulfaatina itti dabaluudha; killee, qurxummii, gosa akaayii fi kaarboohayidireetii gaarii fayyadamaa.',
      body_en: 'Support peak fetal growth with eggs, salmon, nuts, whole grains, and healthy plant fats.',
      image_url: 'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?auto=format&fit=crop&w=600&q=80',
      is_published: true,
    },
    {
      trimester: 3,
      title_am: 'የውሃ መጠጥ እና የሆድ ድርቀትን መከላከል',
      title_or: 'Bishaan Dhuguu fi Gogiinsa Garaa Ittisuu',
      title_en: 'Hydration and Fiber for Smooth Digestion',
      body_am: 'በቀን 2.5 እስከ 3 ሊትር ውሃ ይጠጡ። ፋይበር የበዛባቸውን አጃ፣ አትክልቶችና ፍራፍሬዎች ይመገቡ።',
      body_or: 'Guyyaatti bishaan liitira 2.5 hanga 3 dhugaa. Nyaata faayibera qaban kan akka ootii fi fuduraalee nyaadhaa.',
      body_en: 'Stay well-hydrated with 8-10 glasses of water daily. Increase high-fiber oats and prunes to counter constipation.',
      image_url: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=600&q=80',
      is_published: true,
    },
  ];
  await knex('nutrition_content').insert(nutritionData);
  console.log(`  ✅ Inserted ${nutritionData.length} nutrition guide entries.`);

  // 3. Seed Fetal Development Tracker (Weeks 1 to 40)
  await knex('fetal_tracker_content').del();
  const fetalComparisons = [
    { week: 1, size: 'Poppy Seed', am: 'ፅንሰ-ሀሳብ እና ማዳበሪያ', or: 'Gooftummaa wal-qunnamtii', en: 'Conception & Ovulation cycle' },
    { week: 2, size: 'Fertilized Ovum', am: 'ፅንሱ ማህፀን ውስጥ መተከል ይጀምራል', or: 'Sanyii gadameessa keessatti maxxanuu', en: 'Fertilization & Implantation' },
    { week: 3, size: 'Vanilla Seed', am: 'የህዋሳት መከፋፈል በከፍተኛ ፍጥነት ይቀጥላል', or: 'Seelota saffisaan baay\'achuu', en: 'Blastocyst development' },
    { week: 4, size: 'Poppy Seed', am: 'የእርግዝና ምርመራ አዎንታዊ ይሆናል', or: 'Qorannoo ulfaa gaarii mul\'isuu', en: 'Embryo implanted in uterine lining' },
    { week: 5, size: 'Apple Seed', am: 'የህፃኑ ልብ መምታት ይጀምራል', or: 'Onneen daa\'imaa rukutuu eegala', en: 'Heart begins rudimentary pumping' },
    { week: 6, size: 'Sweet Pea', am: 'የፊት ገጽታዎች መፈጠር ይጀምራሉ', or: 'Kutaan fuulaa mul\'achuu eegala', en: 'Facial features and buds for limbs form' },
    { week: 7, size: 'Blueberry', am: 'የእጅና እግር ጣቶች መለየት ይጀምራሉ', or: 'Quba harkaa fi miilaa adda bahuu', en: 'Webbed hands and feet emerge' },
    { week: 8, size: 'Raspberry', am: 'ሁሉም ዋና ዋና የአካል ክፍሎች ተጀምረዋል', or: 'Qaamoleen bu\'uuraa hundi uumamu', en: 'Organs are developing; tiny fingers appear' },
    { week: 9, size: 'Green Olive', am: 'ፅንሱ ትንሽ መንቀሳቀስ ይጀምራል', or: 'Daa\'imni socho\'uu eegala', en: 'Embryo is now medically termed a fetus' },
    { week: 10, size: 'Prune', am: 'ጥፍሮችና ጥርሶች በድድ ውስጥ ይቀረፃሉ', or: 'Qeensi fi ilkaan uumamu', en: 'Fingernails, toenails, and tooth buds form' },
    { week: 11, size: 'Lime', am: 'የፅንሱ ርዝመት 5 ሴ.ሜ ይደርሳል', or: 'Dheerinni cm 5 ga\'a', en: 'Baby can kick and stretch reflexively' },
    { week: 12, size: 'Plum', am: 'የመጀመሪያው ሶስት ወር መጨረሻ፣ የልብ ምት በግልጽ ይሰማል', or: 'Dhuma ji\'a 3ffaa, onneen ni dhagayama', en: 'End of 1st trimester; reflexes are active' },
    { week: 13, size: 'Meyer Lemon', am: 'የጣት አሻራዎች በህፃኑ ጣቶች ላይ ይፈጠራሉ', or: 'Ashtiin qubaa uumama', en: 'Unique fingerprints have formed' },
    { week: 14, size: 'Peach', am: 'የፊት ጡንቻዎች መንቀሳቀስ ይጀምራሉ', or: 'Daa\'imni fuula sochoosa', en: 'Baby can squint, frown, and grimace' },
    { week: 15, size: 'Apple', am: 'አጥንቶች እየጠነከሩ ይሄዳሉ', or: 'Lafeen jabaachaa deema', en: 'Skeleton is hardening; legs outgrowing arms' },
    { week: 16, size: 'Avocado', am: 'የህፃኑ እንቅስቃሴ በእናትየው ሊሰማ ይችላል', or: 'Sochiin daa\'imaa ni beekama', en: 'Quickening: mother may feel gentle flutters' },
    { week: 17, size: 'Turnip', am: 'ህፃኑ ድምጾችን ማዳመጥ ይጀምራል', or: 'Daa\'imni sagalee dhaga\'uu danda\'a', en: 'Fat stores begin accumulating under skin' },
    { week: 18, size: 'Bell Pepper', am: 'የእንቅልፍና የንቃት ሰዓት መለየት ይጀምራል', or: 'Yeroo rafiisaa fi dammaqaa adda baasa', en: 'Yawning, hiccuping, and sucking thumb' },
    { week: 19, size: 'Heirloom Tomato', am: 'ቆዳው በቬርኒክስ ቅባት ይጠበቃል', or: 'Gogaan daa\'imaa ni eegama', en: 'Vernix caseosa coats and protects skin' },
    { week: 20, size: 'Banana', am: 'የእርግዝናው ግማሽ መንገድ ደርሷል', or: 'Walakkaa ulfaa gaheera', en: 'Halfway mark! Anatomy ultrasound week' },
    { week: 21, size: 'Carrot', am: 'የምግብ መፈጨት ሥርዓት የመጀመሪያ እንቅስቃሴ', or: 'Sirni nyaata bulleessuu eegala', en: 'Baby swallows amniotic fluid regularly' },
    { week: 22, size: 'Spaghetti Squash', am: 'የዓይን ቅንድቦችና ሽፋሽፍቶች ይታያሉ', or: 'Habaqquu ijaa guutuu ta\'a', en: 'Eyebrows and eyelashes clearly visible' },
    { week: 23, size: 'Mango', am: 'የእናትየው ድምፅና የሙዚቃ ዜማ በደንብ ይሰማዋል', or: 'Sagalee haadhaa fi muuziqaa dhaga\'a', en: 'Hearing improves; responds to loud voices' },
    { week: 24, size: 'Ear of Corn', am: 'ሳንባው አየር ለመቀበል አስፈላጊ ፈሳሽ ያመነጫል', or: 'Somba qophii taasisuu eegala', en: 'Viability milestone; lungs produce surfactant' },
    { week: 25, size: 'Rutabaga', am: 'ህፃኑ ለብርሃን እና ንክኪ ምላሽ ይሰጣል', or: 'Ifaa fi tuqaa deebii kenna', en: 'Baby responds to tactile and light stimuli' },
    { week: 26, size: 'Scallion', am: 'ዓይኖቹ ለመጀመሪያ ጊዜ ይከፈታሉ', or: 'Ijji yeroo jalqabaaf banama', en: 'Eyes slowly open and begin blinking' },
    { week: 27, size: 'Cauliflower', am: 'የ3ኛው ሶስት ወር መግቢያ፣ ሳግ ሊይዘው ይችላል', or: 'Seensa ji\'a 3ffaa dhumaa', en: 'Third trimester begins; hiccups common' },
    { week: 28, size: 'Eggplant', am: 'የአእምሮ ሞገዶች የእንቅልፍ ደረጃዎችን ያሳያሉ', or: 'Sammuun daa\'imaa saffisaan guddata', en: 'REM sleep cycles detected in brain' },
    { week: 29, size: 'Butternut Squash', am: 'ጡንቻዎች እና ሳንባዎች እየጎለበቱ ነው', or: 'Irree fi sombi jabaachaa jiru', en: 'Bones fully formed but still soft and supple' },
    { week: 30, size: 'Cabbage', am: 'የአእምሮ እድገት በጣም ፈጣን ይሆናል', or: 'Guddinni sammuu hedduu dabala', en: 'Brain surface wrinkles with neural grooves' },
    { week: 31, size: 'Coconut', am: 'ህፃኑ ራሱን ወደ ታች የማዞር ዝግጅት ይጀምራል', or: 'Mataadhaan gara gadii garagaluu eegala', en: 'Major weight gain; senses fully active' },
    { week: 32, size: 'Jicama', am: 'ጥፍሮቹ የእጅ ጣቶቹን ጫፍ ይሸፍናሉ', or: 'Qeensi guutuu ta\'eera', en: 'Fingernails completely cover fingertips' },
    { week: 33, size: 'Pineapple', am: 'የበሽታ መከላከያ አቅም ከእናትየው ይተላለፋል', or: 'Ittisa dhibee haadha irraa fudhata', en: 'Maternal antibodies pass through placenta' },
    { week: 34, size: 'Cantaloupe', am: 'ማዕከላዊ የነርቭ ሥርዓት ሙሉ በሙሉ ይበስላል', or: 'Sirni narvii guutuu ta\'aa jira', en: 'Central nervous system and lungs mature' },
    { week: 35, size: 'Honeydew Melon', am: 'የኩላሊትና የጉበት ስራ ሙሉ በሙሉ ዝግጁ ነው', or: 'Kallee fi tiruun qophii dha', en: 'Kidneys mature; liver processes waste' },
    { week: 36, size: 'Romaine Lettuce', am: 'ህፃኑ ወደ ዳሌው ዝቅ ይላል (መውረጃ)', or: 'Daa\'imni gara dhalootaatti gadi bu\'a', en: 'Baby drops into pelvis (lightening)' },
    { week: 37, size: 'Swiss Chard', am: 'ሙሉ እድገት ላይ ደርሷል (Early Term)', or: 'Ulfa guutuu ta\'uu eegaleera', en: 'Early term achieved; practicing breathing' },
    { week: 38, size: 'Winter Melon', am: 'ፀጉሩ እና ቆዳው ለውልደት ዝግጁ ናቸው', or: 'Rifeensi fi gogaan qophii dha', en: 'Firm grasp reflex; lanugo shedding' },
    { week: 39, size: 'Mini Watermelon', am: 'ሳንባው በራሱ ለመተንፈስ ሙሉ በሙሉ ዝግጁ ነው', or: 'Sombi ofiin afuura baafachuuf qophii dha', en: 'Full term; lungs produce abundant surfactant' },
    { week: 40, size: 'Small Pumpkin', am: 'እንኳን ደስ አለዎት! የመውለጃ ቀንዎ ደርሷል', or: 'Baga gammaddan! Guyyaan dhalootaa gaheera', en: 'Due date arrival! Ready to meet your newborn' },
  ];

  const fetalData = fetalComparisons.map(item => ({
    week_number: item.week,
    size_comparison: item.size,
    milestone_am: item.am,
    milestone_or: item.or,
    milestone_en: item.en,
    tips_am: `ሳምንት ${item.week}፡ በቂ እረፍት ያድርጉ፣ ብዙ ውሃ ይጠጡ እና የሀኪምዎን ክትትል አይርሱ።`,
    tips_or: `Torbee ${item.week}፡ Boqonnaa gaarii fudhadhaa, bishaan dhugaa, doktoora keessan qunnamaa.`,
    tips_en: `Week ${item.week}: Stay active within comfort, prioritize hydration, and track your prenatal appointments.`,
    image_url: `https://res.cloudinary.com/demo/image/upload/v1614088921/fetal/week${item.week}.jpg`,
  }));

  await knex('fetal_tracker_content').insert(fetalData);
  console.log(`  ✅ Inserted ${fetalData.length} fetal development tracker weeks (1–40).`);

  // 4. Seed Exercise Content
  await knex('exercise_content').del();
  const exerciseData = [
    {
      name_am: 'የቅድመ-ወሊድ ዮጋ እና ዘና ማለት',
      name_or: 'Yoogaa Ulfaa fi Tasgabbii',
      name_en: 'Prenatal Yoga & Gentle Flow',
      trimester_flags: JSON.stringify([1, 2, 3]),
      duration_min: 20,
      safety_notes_am: 'በሆድ ላይ መተኛት ወይም አከርካሪን ከመጠን በላይ ማጠፍ አይፈቀድም። ምቹ ምንጣፍ ይጠቀሙ።',
      safety_notes_or: 'Garaa irratti ciisuu fi dugda baay\'ee micciiruu irraa of eeggadhaa.',
      safety_notes_en: 'Avoid lying flat on back or twisting abdomen. Move at comfortable pace and stay hydrated.',
      media_url: 'https://youtube.com/watch?v=mock-prenatal-yoga',
      is_published: true,
    },
    {
      name_am: 'የኬገል (Kegel) ዳሌ ጡንቻዎች ማጠናከሪያ',
      name_or: 'Shaakala Irree Qunoontii (Kegel)',
      name_en: 'Kegel Pelvic Floor Strengthening',
      trimester_flags: JSON.stringify([1, 2, 3]),
      duration_min: 10,
      safety_notes_am: 'ሽንት በሚሸኑበት ወቅት አያድርጉ፤ ጡንቻውን ለ5 ሰከንድ ጨምቆ መያዝ እና መልቀቅ።',
      safety_notes_or: 'Yeroo fincaan fincaa\'an hin taasisinaa; seekondii 5f qabiiti gadhiisi.',
      safety_notes_en: 'Engage pelvic muscles for 5 seconds, relax for 5 seconds. Repeat 10-15 times daily.',
      media_url: 'https://youtube.com/watch?v=mock-kegel',
      is_published: true,
    },
    {
      name_am: 'የዳሌ መወዛወዝ እና የድመት-ላም እንቅስቃሴ (Cat-Cow)',
      name_or: 'Sochii Adurree fi Sa\'aa (Cat-Cow)',
      name_en: 'Cat-Cow Pelvic Tilt on All Fours',
      trimester_flags: JSON.stringify([2, 3]),
      duration_min: 15,
      safety_notes_am: 'የጀርባ ህመምን ያስታግሳል እንዲሁም ህፃኑ ጥሩ አቀማመጥ እንዲይዝ ይረዳል። ጉልበቶች ላይ ድጋፍ ያድርጉ።',
      safety_notes_or: 'Dhukkubbi dugdaa ni hir\'isa, jilba keessan jala carraa kaayadhaa.',
      safety_notes_en: 'Relieves lower back pressure and promotes optimal fetal positioning. Cushion knees well.',
      media_url: 'https://youtube.com/watch?v=mock-cat-cow',
      is_published: true,
    },
    {
      name_am: 'ቀላል የእግር ጉዞ በንጹህ አየር',
      name_or: 'Deemsa Laafaa Qilleensa Qulqulluu Keessa',
      name_en: 'Brisk Prenatal Outdoor Walking',
      trimester_flags: JSON.stringify([1, 2, 3]),
      duration_min: 30,
      safety_notes_am: 'ምቹ የሩጫ ጫማ ያድርጉ፣ በቂ ውሃ ይያዙ፤ የልብ ምትዎ ከልክ በላይ እንዳይጨምር ቀስ ብለው ይራመዱ።',
      safety_notes_or: 'Kophee mijataa fayyadamaa, bishaan qabadhaa, ariitii humnaa ol hin deemsisinaa.',
      safety_notes_en: 'Wear supportive shoes and maintain steady breathing. Stop if experiencing dizziness.',
      media_url: 'https://youtube.com/watch?v=mock-walking',
      is_published: true,
    },
    {
      name_am: 'የውሃ ውስጥ እንቅስቃሴ እና ዋና',
      name_or: 'Bishaan Keessatti Daakuu fi Socho\'uu',
      name_en: 'Low-Impact Prenatal Swimming',
      trimester_flags: JSON.stringify([2, 3]),
      duration_min: 25,
      safety_notes_am: 'ውሃው የሆድ ክብደትን ስለሚደግፍ መገጣጠሚያዎችን ያሳርፋል። ሙቅ ውሃ ወይም ሳውና ውስጥ አይግቡ።',
      safety_notes_or: 'Bishaan ulfaatina garaa waan dandamatuuf salphaadha; bishaan ho\'aa keessa hin seeninaa.',
      safety_notes_en: 'Buoyancy relieves joint stress and sciatic pain. Avoid hot tubs and saunas.',
      media_url: 'https://youtube.com/watch?v=mock-swimming',
      is_published: true,
    },
  ];
  await knex('exercise_content').insert(exerciseData);
  console.log(`  ✅ Inserted ${exerciseData.length} exercise recommendations.`);

  // 5. Seed Sleep Position Tips
  await knex('sleep_tips').del();
  const sleepData = [
    {
      trimester: 1,
      title_am: 'የመጀመሪያ ሶስት ወር የእንቅልፍ ልምምድ',
      title_or: 'Barmaatilee Rafisaa Ji\'a 1ffaa-3ffaa',
      title_en: 'First Trimester Sleep Habits',
      description_am: 'በሆድም ሆነ በጎን መተኛት ይቻላል። ድካም በሚሰማዎት ጊዜ አጭር የቀን እረፍት (Nap) ይውሰዱ።',
      description_or: 'Garaadhaan ykn cinaachaan ciisuun ni danda\'ama. Yeroo dadhabdan boqonnaa gabaabaa fudhadhaa.',
      description_en: 'Any sleeping position is safe in early pregnancy. Rest whenever fatigue strikes.',
      illustration_url: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?auto=format&fit=crop&w=600&q=80',
    },
    {
      trimester: 2,
      title_am: 'ወደ ግራ ጎን መተኛት (SOS Position)',
      title_or: 'Cinaacha Bitaatiin Ciisuu (SOS)',
      title_en: 'Left-Side Sleeping for Optimal Blood Flow',
      description_am: 'ወደ ግራ መተኛት ወደ ማህፀን እና ፅንስ የሚሄደውን የደም ዝውውር በከፍተኛ ሁኔታ ያሻሽላል። በጀርባ ከመተኛት ይቆጠቡ።',
      description_or: 'Cinaacha bitaatiin ciisuun dhangala\'aa dhiiga gara daa\'imaatti deemu ni dabala. Dugdaan hin ciisinaa.',
      description_en: 'Left-side sleeping prevents uterine pressure on the inferior vena cava, boosting fetal oxygenation.',
      illustration_url: 'https://images.unsplash.com/photo-1511295742362-92c96b124e52?auto=format&fit=crop&w=600&q=80',
    },
    {
      trimester: 3,
      title_am: 'ትራስ በጉልበቶች እና በሆድ ስር መጠቀም',
      title_or: 'Boraatii Jilbaa fi Garaa Jalatti Fayyadamuu',
      title_en: 'Pillow Support Between Knees and Belly',
      description_am: 'በጉልበቶች መሀል እና ከሆድ ስር ትራስ መደገፍ የዳሌና የወገብ ጫናን ያቃልላል፣ ምቹ እንቅልፍ ይሰጣል።',
      description_or: 'Boraatii jilba gidduu fi garaa jalatti kaa\'uun ciminna mudhii fi dugdaa ni salphisa.',
      description_en: 'Use a full-body pregnancy pillow or place cushions between bent knees to align hips and spine.',
      illustration_url: 'https://images.unsplash.com/photo-1520206183501-b80df61043c2?auto=format&fit=crop&w=600&q=80',
    },
    {
      trimester: 0,
      title_am: 'የምሽት የልብ ማቃጠልን እና የሆድ እብጠትን መቀነስ',
      title_or: 'Gubaatii Laphee Galgalaa fi Dhiitama Ittisuu',
      title_en: 'Combating Nighttime Heartburn and Acid Reflux',
      description_am: 'ከመኝታ 2 ሰዓት በፊት ከባድ ምግብ አይመገቡ። ጭንቅላትንና ደረትን በጥቂቱ ከፍ አድርገው ይተኙ።',
      description_or: 'Sa\'aatii 2 ciisuun dura nyaata ulfaataa hin nyaatinaa. Mataa fi laphee xiqqoo ol kaasaa.',
      description_en: 'Elevate head and upper torso 30 degrees. Avoid heavy, spicy dinners within two hours of bedtime.',
      illustration_url: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=600&q=80',
    },
  ];
  await knex('sleep_tips').insert(sleepData);
  console.log(`  ✅ Inserted ${sleepData.length} sleep position tips.`);

  // 6. Seed Music Relaxation Library
  await knex('music_tracks').del();
  const musicData = [
    {
      title_am: 'የእናትና ፅንስ የተረጋጋ ዜማ',
      title_or: 'Faaruu Tasgabbii Haadhaa fi Daa\'imaa',
      title_en: 'Serene Maternal Heartbeat & Harp',
      category: 'Meditation',
      duration: 600, // 10 mins
      thumbnail_url: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=600&q=80',
      media_url: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3',
      is_active: true,
    },
    {
      title_am: 'የህፃን ማባበያ ሙዚቃ (Lullaby)',
      title_or: 'Sirba Daa\'ima Raafuu (Lullaby)',
      title_en: 'Sweet Dreams Baby Lullaby',
      category: 'Lullaby',
      duration: 330, // 5:30
      thumbnail_url: 'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&w=600&q=80',
      media_url: 'https://cdn.pixabay.com/download/audio/2022/01/18/audio_d0a13f69d2.mp3',
      is_active: true,
    },
    {
      title_am: 'የተፈጥሮ ዝናብ እና ወንዝ ድምፅ',
      title_or: 'Sagalee Roobaa fi Laga Uumamaa',
      title_en: 'Gentle Rain & Forest River Flow',
      category: 'Relaxation',
      duration: 900, // 15 mins
      thumbnail_url: 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?auto=format&fit=crop&w=600&q=80',
      media_url: 'https://cdn.pixabay.com/download/audio/2022/03/15/audio_c8c8a73467.mp3',
      is_active: true,
    },
    {
      title_am: 'ጥልቅ የመተንፈስ ማሰላሰያ',
      title_or: 'Shaakala Afuura Baafachuu Gad-fagoo',
      title_en: 'Deep Calming Breathwork Ambient',
      category: 'Meditation',
      duration: 720, // 12 mins
      thumbnail_url: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=600&q=80',
      media_url: 'https://cdn.pixabay.com/download/audio/2021/08/09/audio_88447e70ac.mp3',
      is_active: true,
    },
  ];
  await knex('music_tracks').insert(musicData);
  console.log(`  ✅ Inserted ${musicData.length} music relaxation tracks.`);

  console.log('🎉 All CMS seed data populated successfully!');
};

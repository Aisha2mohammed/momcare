/**
 * Seed for the NEW structured content tables (added after the admin-CMS merge):
 *   - nutrition_weeks / nutrition_tips
 *   - exercise_weeks / exercises
 *   - sleep_weeks
 *   - fetal_weekly_content / fetal_development_items / fetal_checklist_items
 *
 * Language suffix convention: _om is canonical for Oromo (ISO 639-1).
 * Runs AFTER 02_cms_content.js (which owns the legacy flat tables).
 */
exports.seed = async function (knex) {
  console.log('🌱 Seeding structured content tables (03_content_tables)...');

  // ── Cleanup ──────────────────────────────────────────────────────────
  await knex('nutrition_tips').del();
  await knex('nutrition_weeks').del();
  await knex('exercises').del();
  await knex('exercise_weeks').del();
  await knex('sleep_weeks').del();
  await knex('fetal_checklist_items').del();
  await knex('fetal_development_items').del();
  await knex('fetal_weekly_content').del();

  // ── Wide translations ────────────────────────────────────────────────
  const L = {
    en: 'English',
    am: 'አማርኛ',
    om: 'Afaan Oromoo',
    so: 'Soomaali',
  };

  const HYD = {
    en: 'Drink 8–10 glasses of water daily. Staying hydrated supports blood volume, amniotic fluid and digestion.',
    am: 'በየቀኑ ከ8 እስከ 10 ብርጭቆ ውሃ ይጠጡ።',
    om: 'Guyyaatti bishaan galaana 8–10 dhugaa. Bishaan dhuguun dhiiga fi bishaan daa’imaa ni deeggara.',
    so: 'Cab 8-10 koob oo biyo ah maalin kasta.',
  };

  const WHY_NUT = {
    en: 'Eating a balanced, iron- and protein-rich diet now gives your baby the building blocks for healthy growth.',
    am: 'በብረት እና ፕሮቲን የበለፀገ የተመጣጠነ ምግብ መመገብ ለልጅዎ ጤናማ እድገት መሰረት ነው።',
    om: 'Nyaata sirnaa, sibiila fi pirootiinii qabu nyaachuun daa’ima kee guddina fayyaa qabaachuuf bu’uura dha.',
    so: 'Cunida cunto dheellis ah oo qani ah ayaa ku siisa ilmagaguaga koritaanka caafimaadka.',
  };

  const WHY_EX = {
    en: 'Regular gentle movement improves circulation, eases back pain and helps you sleep better.',
    am: 'መደበኛ ቀላል እንቅስቃሴ የደም ዝውውርን ያሻሽላል፣ የወገብ ህመምን ያቃልላል።',
    om: 'Sochii salphaa yeroo yerootiin hojjechuun dhiiga sochoodhaa, cinaacha dugdaa hir’isa.',
    so: 'Dhaqdhaqaaq fudud oo joogto ah waxa uu horumariyaa wareega dhiigga.',
  };

  const WHY_SLEEP = {
    en: 'Sleeping on your left side improves blood flow to your baby and reduces swelling.',
    am: 'በግራ ጎን መተኛት ወደ ልጅዎ የሚሄደውን የደም ዝውውር ያሻሽላል።',
    om: 'Cinaacha bitaatiin ciisuun dhangala’aa dhiigaa daa’imaaf ni dabala.',
    so: 'Seexashada dhinaca bidix waxa ay hagaajisaa socodka dhiigga ee ilmaha.',
  };

  const TIPS_NUT = {
    en: 'Eat iron-rich foods like lentils and spinach with vitamin C to boost absorption. Aim for 3 balanced meals and healthy snacks.',
    am: 'ብረት የበዛባቸውን እንደ ምስር እና ስፒናች ከቫይታሚን ሲ ጋር ይመገቡ።',
    om: 'Nyaata sibiila qabu akka misiraa fi fooffaatti vaitaamin C waliin nyaadhaa.',
    so: 'Cun cuntooyinka sida misir iyo isbinish oo leh Fitamiin C.',
  };

  // ── Nutrition weeks ──────────────────────────────────────────────────
  const nutritionWeeks = [
    { trimester: 1, month: 2, week: 6 },
    { trimester: 1, month: 3, week: 12 },
    { trimester: 2, month: 4, week: 16 },
    { trimester: 2, month: 6, week: 24 },
    { trimester: 3, month: 7, week: 30 },
    { trimester: 3, month: 9, week: 36 },
  ];

  const nutritionIds = [];
  for (const nw of nutritionWeeks) {
    const [row] = await knex('nutrition_weeks')
      .insert({
        trimester: nw.trimester,
        month: nw.month,
        week: nw.week,
        why_important_en: WHY_NUT.en,
        why_important_am: WHY_NUT.am,
        why_important_om: WHY_NUT.om,
        why_important_so: WHY_NUT.so,
        hydration_en: HYD.en,
        hydration_am: HYD.am,
        hydration_om: HYD.om,
        hydration_so: HYD.so,
        is_published: true,
      })
      .returning('id');
    nutritionIds.push({ ...nw, id: row.id });
  }

  const foods = [
    {
      en: 'Lentils & Legumes', am: 'ምስር እና ጥራጥሬ', om: 'Misiraa fi Soya', so: 'Misir iyo digir',
      whyEn: 'Rich in iron, protein and folate for baby’s blood and brain.', whyAm: 'በብረት፣ ፕሮቲን እና ፎሌት የበለፀገ ነው።', whyOm: 'Sibiila, pirootiinii fi foolateen badhaadhe.', whySo: 'Qani ku yahay birta, borotiinka iyo foolate.',
    },
    {
      en: 'Spinach & Leafy Greens', am: 'ስፒናች እና ቅጠላ ቅጠል', om: 'Fooffaa fi Kuduraa Baala', so: 'Isbinish iyo khudrada cagaaran',
      whyEn: 'Folate and calcium that support neural tube and bone growth.', whyAm: 'ፎሌት እና ካልሲየም ይዟል።', whyOm: 'Foolate fi kaalisiyeemii qaba.', whySo: 'Waxay leedahay foolate iyo calcium.',
    },
    {
      en: 'Eggs & Lean Protein', am: 'እንቁላል እና የተመረጠ ፕሮቲን', om: 'Hanqaaqa fi Pirootiinii', so: 'Ukun iyo borotiin',
      whyEn: 'High-quality protein and choline for brain development.', whyAm: 'ለአእምሮ እድገት ጠቃሚ ፕሮቲን ይዟል።', whyOm: 'Pirootiinii fi kooliiniif guddisa sammuu.', whySo: 'Boruotiin tayo sare leh oo horumarinta maskaxda.',
    },
    {
      en: 'Whole Grains & Folic Acid', am: 'ሙሉ እህል እና ፎሊክ አሲድ', om: 'Midhaa fi Foolik Asiid', so: 'Badarka iyo foolka',
      whyEn: 'Sustained energy and folic acid to prevent birth defects.', whyAm: 'ሃይል እና ፎሊክ አሲድ ይሰጣል።', whyOm: 'Humna fi asiidfoolka kennu', whySo: 'Tamarta joogtada ah iyo folik asid.',
    },
  ];

  const NUT_TIPS = [
    {
      type: 'eat',
      title: { en: 'Folate-Rich Foods', am: 'ፎሌት የበዛባቸው ምግቦች', om: 'Nyaata Foolate-qabeessa', so: 'Cuntooyinka foolate' },
      desc: { en: 'Choose dark leafy greens, beans and fortified cereals every day.', am: 'በየቀኑ ቅጠላ ቅጠልና ጥራጥሬ ይምረጡ።', om: 'Guyyaa guyyaan baala, baaqelii fi midhaan filadhaa.', so: 'Dooro cagaar iyo digir maalin kasta.' },
      why: WHY_NUT,
      foods: [foods[0], foods[1]],
    },
    {
      type: 'avoid',
      title: { en: 'Limit Caffeine & Sugar', am: 'ካፌይን እና ስኳርን ይቀንሱ', om: 'Kaafiiniinii fi Sukkara Hir’isaa', so: 'Xaddid kafeeinta iyo sonkorta' },
      desc: { en: 'Stick to one small coffee daily and avoid sugary drinks.', am: 'በቀን አንድ ትንሽ ቡና ይጠጡ።', om: 'Guyyaatti kubbaa tokko qofa dhugaa.', so: 'Hal koob oo qaxwo ah maalintii.' },
      why: WHY_NUT,
      foods: [],
    },
    {
      type: 'eat',
      title: { en: 'Iron & Protein Boost', am: 'ብረት እና ፕሮቲን', om: 'Sibiilaa fi Pirootiinii', so: 'Birit iyo borotiin' },
      desc: { en: 'Pair iron-rich legumes with vitamin C rich fruits.', am: 'ብረት የበዛባቸውን ከቫይታሚን ሲ ጋር ይመገቡ።', om: 'Misiraa waliin fuduraa vaitaamin C qabu nyaadhaa.', so: 'Isku dar digirta iyo khudrada fitamiin C.' },
      why: WHY_NUT,
      foods: [foods[0], foods[2]],
    },
    {
      type: 'eat',
      title: { en: 'Calcium for Bones', am: 'ካልሲየም ለአጥንት', om: 'Kaalisiyeemii Lafee', so: 'Calcium lafaha' },
      desc: { en: 'Include dairy, yogurt and fortified plant milk daily.', am: 'ወተት እና እርጎ ይመገቡ።', om: 'Aannan fi itittuu guyyaa guyyaan nyaadhaa.', so: 'Cun caano, casito iyo caano geedo.' },
      why: WHY_NUT,
      foods: [foods[1], foods[3]],
    },
  ];

  for (let i = 0; i < nutritionIds.length; i++) {
    const nw = nutritionIds[i];
    const tip = NUT_TIPS[i % NUT_TIPS.length];
    const list_food = tip.foods.map((f, fi) => ({
      type: tip.type,
      name: { en: f.en, am: f.am, om: f.om, so: f.so },
      description: { en: f.whyEn, am: f.whyAm, om: f.whyOm, so: f.whySo },
      label: { en: 'Why include', am: 'ለምን ይጠቅማል', om: 'Maaliif', so: 'Maxaa ugu daray' },
      image: { type: 'url', url: `https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=400&q=80` },
      video: null,
    }));
    await knex('nutrition_tips').insert({
      type: tip.type,
      nutrition_week_id: nw.id,
      title_en: tip.title.en,
      title_am: tip.title.am,
      title_om: tip.title.om,
      title_so: tip.title.so,
      description_en: tip.desc.en,
      description_am: tip.desc.am,
      description_om: tip.desc.om,
      description_so: tip.desc.so,
      description_label_en: 'Nutrition Focus', description_label_am: 'የአመጋገብ ትኩረት', description_label_om: 'Xiyyeeffannaa Nyaataa', description_label_so: 'Diidmada Cuntada',
      description_value_en: tip.title.en, description_value_am: tip.title.am, description_value_om: tip.title.om, description_value_so: tip.title.so,
      why_important_en: tip.why.en, why_important_am: tip.why.am, why_important_om: tip.why.om, why_important_so: tip.why.so,
      health_tips: JSON.stringify([{ label: { en: 'Stay hydrated', am: 'ውሃ ይጠጡ', om: 'Bishaan dhugaa', so: 'Cab biyo' } }]),
      list_food: JSON.stringify(list_food),
      is_published: true,
    });
  }

  // ── Exercise weeks ───────────────────────────────────────────────────
  const exerciseWeeks = [
    { trimester: 1, month: 2, week: 6 },
    { trimester: 1, month: 3, week: 12 },
    { trimester: 2, month: 4, week: 16 },
    { trimester: 2, month: 6, week: 24 },
    { trimester: 3, month: 7, week: 30 },
    { trimester: 3, month: 9, week: 36 },
  ];

  for (const ew of exerciseWeeks) {
    await knex('exercise_weeks').insert({
      trimester: ew.trimester,
      month: ew.month,
      week: ew.week,
      why_important_en: WHY_EX.en,
      why_important_am: WHY_EX.am,
      why_important_om: WHY_EX.om,
      why_important_so: WHY_EX.so,
      exercise_tips_en: TIPS_NUT.en,
      exercise_tips_am: TIPS_NUT.am,
      exercise_tips_om: TIPS_NUT.om,
      exercise_tips_so: TIPS_NUT.so,
      is_published: true,
    });
  }

  // ── Exercises ────────────────────────────────────────────────────────
  const exercises = [
    {
      t: 1, cat: 'stretching', dur: 15, name: { en: 'Gentle Pregnancy Stretch', am: 'ቀላል የመወጠር ልምምድ', om: 'Diriirsa Salphaa', so: 'Jilicsan oo dheereeya' },
      desc: { en: 'Slow shoulder and hip openers to ease first-trimester tension.', am: 'የትከፍቶችን እና የዳሌን ጫና የሚያቃልል።', om: 'Ciminna gatiittaa fi mudhii salphisuuf.', so: 'Nasasho fudud oo lafaha.' },
    },
    {
      t: 1, cat: 'pelvic-floor', dur: 10, name: { en: 'Kegel Basics', am: 'የኬጅል መሰረታዊ ልምምድ', om: 'Bu’uura Kegiil', so: 'Aasaaska Kegel' },
      desc: { en: 'Activate and release pelvic floor muscles 3 sets of 10.', am: 'የዳሌ ጡንቻዎችን ያጠናክሩ።', om: 'Hiicsa mudhii ciminaa.', so: 'Xooji muruqa hoose.' },
    },
    {
      t: 2, cat: 'cardio', dur: 20, name: { en: 'Brisk Walking', am: 'ፈጣን የእግር ጉዞ', om: 'Deduub Deemuu', so: 'Socod degdeg ah' },
      desc: { en: '20 minutes most days keeps your heart and baby healthy.', am: 'ለልብ ጤና የሚረዳ የእግር ጉዞ።', om: 'Onaannisa onnee kee.', so: 'Waxay ilaalisaa wadnahaaga.' },
    },
    {
      t: 2, cat: 'strength', dur: 15, name: { en: 'Squats for Strength', am: 'የመቀመጥና የመነሳት ልምምድ', om: 'Shaakala Kuusuu', so: 'Squads' },
      desc: { en: 'Bodyweight squats strengthen legs for labor preparation.', am: 'ለወሊድ የሚያዘጋጅ ልምምድ።', om: 'Qaawwa miillaaf.', so: 'Xooji lugahaaga.' },
    },
    {
      t: 3, cat: 'relaxation', dur: 10, name: { en: 'Side-Lying Breathing', am: 'የመተንፈስ ልምምድ', om: 'Afuura Baafachuu', so: 'Neefsasho' },
      desc: { en: 'Deep breathing in left-side lying calms you before birth.', am: 'ጥልቅ የመተንፈስ ልምምድ።', om: 'Qalbi ittisaa.', so: 'Qalbi degdego.' },
    },
    {
      t: 3, cat: 'mobility', dur: 12, name: { en: 'Cat-Cow Mobility', am: 'የተንቀሳቃሽ የጀርባ ልምምድ', om: 'Sochii Dugdaa', so: 'Dhaqaaq' },
      desc: { en: 'Gentle spine mobility eases back and hip pressure.', am: 'የጀርባ ጫናን ያቃልላል።', om: 'Cinaacha dugdaa salphisaa.', so: 'Yaree cadaadiska.' },
    },
  ];

  for (const ex of exercises) {
    await knex('exercises').insert({
      trimester: ex.t,
      category: ex.cat,
      duration_minutes: ex.dur,
      image_url: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=400&q=80',
      video_url: 'https://www.youtube.com/watch?v=VpC1o5bQy-g',
      title_en: ex.name.en,
      title_am: ex.name.am,
      title_om: ex.name.om,
      title_so: ex.name.so,
      description_en: ex.desc.en,
      description_am: ex.desc.am,
      description_om: ex.desc.om,
      description_so: ex.desc.so,
      why_important_en: WHY_EX.en,
      why_important_am: WHY_EX.am,
      why_important_om: WHY_EX.om,
      why_important_so: WHY_EX.so,
      is_published: true,
    });
  }

  // ── Sleep weeks ──────────────────────────────────────────────────────
  const sleepWeeks = [
    { trimester: 1, month: 2, week: 6 },
    { trimester: 1, month: 3, week: 12 },
    { trimester: 2, month: 4, week: 16 },
    { trimester: 2, month: 6, week: 24 },
    { trimester: 3, month: 7, week: 30 },
    { trimester: 3, month: 9, week: 36 },
  ];

  for (const sw of sleepWeeks) {
    await knex('sleep_weeks').insert({
      trimester: sw.trimester,
      month: sw.month,
      week: sw.week,
      why_important_en: WHY_SLEEP.en,
      why_important_am: WHY_SLEEP.am,
      why_important_om: WHY_SLEEP.om,
      why_important_so: WHY_SLEEP.so,
      sleeping_tips_en: 'Sleep on your left side with a pillow between your knees.',
      sleeping_tips_am: 'በግራ ጎን ትራስ በጉልበቶች መሀል አድርገው ይተኙ።',
      sleeping_tips_om: 'Cinaacha bitaatiin boraatii jilba gidduu kaa’uun ciisaa.',
      sleeping_tips_so: 'Sii dhincaca bidix oo barkimo lugaha dhexdeeda saar.',
      is_published: true,
    });
  }

  // ── Fetal weekly content (weeks 1–40) ────────────────────────────────
  const weekData = [];
  const SIZE = [
    { len: 0.0, wgt: 0, cm: 'a poppy seed', }, { len: 0.6, wgt: 1, cm: 'a sesame seed' },
    { len: 1.0, wgt: 2, cm: 'a raspberry' }, { len: 1.2, wgt: 4, cm: 'a poppy seed' },
    { len: 1.5, wgt: 9, cm: 'an apple seed' }, { len: 2.0, wgt: 17, cm: 'a sweet pea' },
    { len: 2.5, wgt: 30, cm: 'a blueberry' }, { len: 3.2, wgt: 50, cm: 'a kidney bean' },
    { len: 3.8, wgt: 80, cm: 'a cherry' }, { len: 4.4, wgt: 100, cm: 'a strawberry' },
    { len: 5.0, wgt: 150, cm: 'a lime' }, { len: 6.0, wgt: 220, cm: 'a plum' },
    { len: 7.0, wgt: 300, cm: 'a peach' }, { len: 8.5, wgt: 400, cm: 'a lemon' },
    { len: 10.0, wgt: 500, cm: 'an apple' }, { len: 11.0, wgt: 600, cm: 'an avocado' },
    { len: 12.5, wgt: 700, cm: 'a pear' }, { len: 13.5, wgt: 800, cm: 'a mango' },
    { len: 14.5, wgt: 900, cm: 'a cucumber' }, { len: 15.5, wgt: 1000, cm: 'a banana' },
    { len: 16.5, wgt: 1150, cm: 'a carrot' }, { len: 17.5, wgt: 1300, cm: 'a papaya' },
    { len: 18.5, wgt: 1450, cm: 'a sweet potato' }, { len: 20.0, wgt: 1600, cm: 'a corn cob' },
    { len: 21.0, wgt: 1750, cm: 'an ear of corn' }, { len: 22.5, wgt: 1900, cm: 'a zucchini' },
    { len: 24.0, wgt: 2100, cm: 'a cauliflower' }, { len: 25.0, wgt: 2300, cm: 'a head of cabbage' },
    { len: 26.0, wgt: 2500, cm: 'a butternut squash' }, { len: 27.0, wgt: 2700, cm: 'a small pumpkin' },
    { len: 28.0, wgt: 2900, cm: 'a large romaine' }, { len: 29.5, wgt: 3100, cm: 'a coconut' },
    { len: 30.0, wgt: 3300, cm: 'a honeydew melon' }, { len: 31.0, wgt: 3500, cm: 'a pineapple' },
    { len: 32.0, wgt: 3700, cm: 'a large mango' }, { len: 33.0, wgt: 3900, cm: 'a cantaloupe' },
    { len: 34.0, wgt: 4000, cm: 'a small jackfruit' }, { len: 35.0, wgt: 4100, cm: 'a bunch of kale' },
    { len: 36.0, wgt: 4200, cm: 'a Swiss chard' }, { len: 37.0, wgt: 4300, cm: 'a pumpkin' },
  ];

  const TITLE_TMPL = {
    en: (w) => `Week ${w}: Your Baby’s Journey`,
    am: (w) => `ሳምንት ${w}፡ የልጅዎ እድገት`,
    om: (w) => `Torban ${w}: Guddina Daa’imaa Keetii`,
    so: (w) => `Toddobaadka ${w}: Safarka Ilmahaaga`,
  };
  const SUMMARY_TMPL = {
    en: (s, cm) => `Your baby is about ${s} long — the size of ${cm}. Every day brings new growth.`,
    am: (s, cm) => `ልጅዎ በግምት ${s} ርዝመት አለው።`,
    om: (s, cm) => `Daa’imni kee kuni ${s} dheerinaqaba.`,
    so: (s, cm) => `Ilmahaagu waxa uu dhan yahay ${s}.`,
  };
  const DEV_TMPL = {
    en: 'Key organs and systems form and mature this week.',
    am: 'ዋና ዋና አካላት እየተፈጠሩ ያድጋሉ።',
    om: 'Qaamolee ijoonni asii uumamu.',
    so: 'Xubnaha ugu muhiimsan.',
  };

  const fetalRows = [];
  for (let w = 1; w <= 40; w++) {
    const s = SIZE[w - 1];
    fetalRows.push({
      week_number: w,
      title_en: TITLE_TMPL.en(w),
      title_am: TITLE_TMPL.am(w),
      title_om: TITLE_TMPL.om(w),
      title_so: TITLE_TMPL.so(w),
      image_url: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=600&q=80',
      image_alt_en: 'Baby development illustration', image_alt_am: 'የፅንስ እድገት', image_alt_om: 'Guddina daa’imaa', image_alt_so: 'Koritaanka ilmaha',
      summary_en: SUMMARY_TMPL.en(s.len, s.cm),
      summary_am: SUMMARY_TMPL.am(s.len, s.cm),
      summary_om: SUMMARY_TMPL.om(s.len, s.cm),
      summary_so: SUMMARY_TMPL.so(s.len, s.cm),
      baby_length_cm: s.len,
      baby_weight_g: s.wgt,
      days_remaining: 280 - (w * 7),
      heart_rate: 140,
      size_comparison_en: s.cm, size_comparison_am: s.cm, size_comparison_om: s.cm, size_comparison_so: s.cm,
      milestone_en: DEV_TMPL.en, milestone_am: DEV_TMPL.am, milestone_om: DEV_TMPL.om, milestone_so: DEV_TMPL.so,
      physical_development_en: DEV_TMPL.en, physical_development_am: DEV_TMPL.am, physical_development_om: DEV_TMPL.om, physical_development_so: DEV_TMPL.so,
      brain_dev_en: DEV_TMPL.en, brain_dev_am: DEV_TMPL.am, brain_dev_om: DEV_TMPL.om, brain_dev_so: DEV_TMPL.so,
      heart_dev_en: DEV_TMPL.en, heart_dev_am: DEV_TMPL.am, heart_dev_om: DEV_TMPL.om, heart_dev_so: DEV_TMPL.so,
      organ_dev_en: DEV_TMPL.en, organ_dev_am: DEV_TMPL.am, organ_dev_om: DEV_TMPL.om, organ_dev_so: DEV_TMPL.so,
      bone_muscle_dev_en: DEV_TMPL.en, bone_muscle_dev_am: DEV_TMPL.am, bone_muscle_dev_om: DEV_TMPL.om, bone_muscle_dev_so: DEV_TMPL.so,
      movement_en: DEV_TMPL.en, movement_am: DEV_TMPL.am, movement_om: DEV_TMPL.om, movement_so: DEV_TMPL.so,
      senses: JSON.stringify([
        { key: 'hearing', labelAm: 'የመስማት', labelEn: 'Hearing', labelOm: 'Dhagaachuu', labelSo: 'Maqal' },
        { key: 'touch', labelAm: 'የመነካካት', labelEn: 'Touch', labelOm: 'Tuquu', labelSo: 'Taabasho' },
      ]),
      maternal_changes_en: 'Mild aches and fatigue are normal; rest often.', maternal_changes_am: 'መጠነኛ ድካም የተለመደ ነው።', maternal_changes_om: 'Dadhabni salphaan kan waggoota. Boqonnaa argadhu.', maternal_changes_so: 'Daal iyo dhib fudud waa caadi.',
      common_symptoms_en: 'Nausea, fatigue and tender breasts in early weeks.', common_symptoms_am: 'የማስታወክ ስሜት፣ ድካም።', common_symptoms_om: 'Rifaatii, dadhabuu, qomaa.', common_symptoms_so: 'Lallabbo, daal iyo naaso godan.',
      health_tip_en: TIPS_NUT.en, health_tip_am: TIPS_NUT.am, health_tip_om: TIPS_NUT.om, health_tip_so: TIPS_NUT.so,
      antenatal_care_en: 'Attend all check-ups and tell your provider any concerns.', antenatal_care_am: 'ሁሉንም የጤና ምርመራ ይከታተሉ።', antenatal_care_om: 'Qoramtii fayyaa hunda hin dhiisinaa.', antenatal_care_so: 'Tag xannaanada dhammaan.',
      is_active: true,
    });
  }

  for (const fr of fetalRows) {
    const [row] = await knex('fetal_weekly_content').insert(fr).returning('id');
    await knex('fetal_development_items').insert([
      { week_id: row.id, category: 'brain', display_order: 1,
        title_en: 'Nervous system forming', title_am: 'የነርቭ ስርዓት እየተፈጠረ ነው', title_om: 'Sistimii narvii uumamaa jira', title_so: 'Nidaamka neerfaha' },
      { week_id: row.id, category: 'heart', display_order: 2,
        title_en: 'Heart begins to beat', title_am: 'ልብ መምታት ይጀምራል', title_om: 'Onneen dha’uu jalqaba', title_so: 'Wadnaha wuxuu bilaabaa' },
    ]);
    await knex('fetal_checklist_items').insert([
      { week_id: row.id, display_order: 1,
        title_en: 'Take prenatal vitamins', title_am: 'የእርግዝና ቫይታሚን ይውሰዱ', title_om: 'Vaayitamiinii waliinisaa', title_so: 'Qaado fitamiin' },
      { week_id: row.id, display_order: 2,
        title_en: 'Drink plenty of water', title_am: 'ብዙ ውሃ ይጠጡ', title_om: 'Bishaan baay’ee dhugaa', title_so: 'Cabo biyo badan' },
    ]);
  }

  console.log(`  ✅ Seeded ${nutritionWeeks.length} nutrition weeks, ${nutritionIds.length} nutrition tips`);
  console.log(`  ✅ Seeded ${exerciseWeeks.length} exercise weeks, ${exercises.length} exercises`);
  console.log(`  ✅ Seeded ${sleepWeeks.length} sleep weeks`);
  console.log(`  ✅ Seeded ${fetalRows.length} fetal weeks (+dev/checklist items)`);
};
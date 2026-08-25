require('dotenv').config();
const mongoose = require('mongoose');
const FetalDevelopment = require('../models/FetalDevelopment');
const NutritionGuide = require('../models/NutritionGuide');
const Admin = require('../models/Admin');
const connectDB = require('../config/db');

// Sample Fetal Data for 42 weeks
const fetalData = Array.from({ length: 42 }, (_, i) => {
    const week = i + 1;
    return {
        week,
        sizeComparison: { am: `ስለ ሳምንት ${week} የህፃን መጠን`, or: `Waa'ee torbee ${week} hanga mucaa` },
        weightGrams: week * 15,
        lengthCm: week * 0.8,
        milestones: { am: `በሳምንት ${week} እድገት`, or: `Guddina torbee ${week}` },
        tipsForMother: { am: `ለሳምንት ${week} ምክር`, or: `Gorsa torbee ${week}` },
        imageUrl: `https://res.cloudinary.com/demo/image/upload/v1614088921/fetal/week${week}.jpg`
    };
});

// Sample Nutrition Data (10 guides)
const nutritionData = [
    { trimester: 1, title: { am: 'የመጀመሪያ 3 ወር አመጋገብ', or: 'Nyaata ji\'a 3ffaa' }, body: { am: 'ፎሊክ አሲድ አስፈላጊ ነው', or: 'Folic acid baay\'ee barbaachisaadha' }, isPublished: true },
    { trimester: 1, title: { am: 'የውሃ አስፈላጊነት', or: 'Barbaachisummaa bishaan' }, body: { am: 'በቀን 3 ሊትር ውሃ ይጠጡ', or: 'Guyyaatti bishaan liitira 3 dhugaa' }, isPublished: true },
    { trimester: 1, title: { am: 'ፍራፍሬዎች', or: 'Fuduraalee' }, body: { am: 'ቫይታሚን ሲ ያላቸውን ይመገቡ', or: 'Vitamin C kan qaban nyaadhaa' }, isPublished: true },
    { trimester: 2, title: { am: 'የፕሮቲን ጥቅም', or: 'Faayidaa Pirootiinii' }, body: { am: 'ስጋ እና እንቁላል', or: 'Foon fi killee' }, isPublished: true },
    { trimester: 2, title: { am: 'ብረት (Iron)', or: 'Ayirenii' }, body: { am: 'የደም ማነስን ይከላከላል', or: 'Hanqina dhiigaa ittisa' }, isPublished: true },
    { trimester: 2, title: { am: 'ካልሲየም', or: 'Kaalsiyeemii' }, body: { am: 'ለአጥንት ጥንካሬ', or: 'Cimina lafeef' }, isPublished: true },
    { trimester: 2, title: { am: 'አትክልቶች', or: 'Kuduraalee' }, body: { am: 'አረንጓዴ ቅጠል ያላቸው አትክልቶች ይጠቅማሉ', or: 'Kuduraalee baala magariisa qaban' }, isPublished: true },
    { trimester: 3, title: { am: 'የመጨረሻ ወራት አመጋገብ', or: 'Nyaata ji\'oota dhumaa' }, body: { am: 'ቀለል ያሉ ምግቦች', or: 'Nyaata salphaa' }, isPublished: true },
    { trimester: 3, title: { am: 'ኦሜጋ-3', or: 'Omega-3' }, body: { am: 'ለህፃኑ አእምሮ እድገት', or: 'Guddina sammuu mucaatif' }, isPublished: true },
    { trimester: 3, title: { am: 'ቅባት እና ጨው', or: 'Zayitii fi soogidda' }, body: { am: 'መቀነስ', or: 'Hir\'isuu' }, isPublished: true },
];

const seedDB = async () => {
    try {
        await connectDB();
        console.log('Clearing existing data...');
        await FetalDevelopment.deleteMany();
        await NutritionGuide.deleteMany();
        await Admin.deleteMany();

        console.log('Inserting Admin...');
        await Admin.create({
            name: 'Super Admin',
            email: 'admin@smartpregnancy.com',
            password: 'password123',
            role: 'superadmin',
            isActive: true
        });

        console.log('Inserting Fetal Development Data...');
        await FetalDevelopment.insertMany(fetalData);

        console.log('Inserting Nutrition Guides...');
        await NutritionGuide.insertMany(nutritionData);

        console.log('✅ Seeding completed effectively!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Seeding failed:', error);
        process.exit(1);
    }
};

seedDB();

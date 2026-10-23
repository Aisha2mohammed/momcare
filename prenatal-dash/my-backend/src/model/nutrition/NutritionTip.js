const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class NutritionTip extends Model {}

  NutritionTip.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    type: {
      type: DataTypes.STRING(20),
      defaultValue: 'eat'
    },
    nutrition_week_id: {
      type: DataTypes.UUID
    },
    image_url: {
      type: DataTypes.STRING(500)
    },
    title_en: {
      type: DataTypes.STRING(500)
    },
    title_am: {
      type: DataTypes.STRING(500)
    },
    title_om: {
      type: DataTypes.STRING(500)
    },
    title_so: {
      type: DataTypes.STRING(500)
    },
    description_en: {
      type: DataTypes.TEXT
    },
    description_am: {
      type: DataTypes.TEXT
    },
    description_om: {
      type: DataTypes.TEXT
    },
    description_so: {
      type: DataTypes.TEXT
    },
    description_label_en: {
      type: DataTypes.STRING(500)
    },
    description_label_am: {
      type: DataTypes.STRING(500)
    },
    description_label_om: {
      type: DataTypes.STRING(500)
    },
    description_label_so: {
      type: DataTypes.STRING(500)
    },
    description_value_en: {
      type: DataTypes.STRING(500)
    },
    description_value_am: {
      type: DataTypes.STRING(500)
    },
    description_value_om: {
      type: DataTypes.STRING(500)
    },
    description_value_so: {
      type: DataTypes.STRING(500)
    },
    why_important_en: {
      type: DataTypes.TEXT
    },
    why_important_am: {
      type: DataTypes.TEXT
    },
    why_important_om: {
      type: DataTypes.TEXT
    },
    why_important_so: {
      type: DataTypes.TEXT
    },
    health_tips: {
      type: DataTypes.JSONB,
      defaultValue: []
    },
    list_food: {
      type: DataTypes.JSONB,
      defaultValue: []
    },
    is_published: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    sequelize,
    modelName: 'NutritionTip',
    tableName: 'nutrition_tips',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  NutritionTip.associate = (models) => {
    NutritionTip.belongsTo(models.NutritionWeek, {
      foreignKey: 'nutrition_week_id',
      as: 'nutritionWeek'
    });
  };

  return NutritionTip;
};

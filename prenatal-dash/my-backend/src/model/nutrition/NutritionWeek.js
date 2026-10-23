const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class NutritionWeek extends Model {}

  NutritionWeek.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    trimester: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    month: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    week: {
      type: DataTypes.INTEGER,
      allowNull: false
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
    hydration_en: {
      type: DataTypes.TEXT
    },
    hydration_am: {
      type: DataTypes.TEXT
    },
    hydration_om: {
      type: DataTypes.TEXT
    },
    hydration_so: {
      type: DataTypes.TEXT
    },
    is_published: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    sequelize,
    modelName: 'NutritionWeek',
    tableName: 'nutrition_weeks',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  NutritionWeek.associate = (models) => {
    NutritionWeek.hasMany(models.NutritionTip, {
      foreignKey: 'nutrition_week_id',
      as: 'tips'
    });
  };

  return NutritionWeek;
};

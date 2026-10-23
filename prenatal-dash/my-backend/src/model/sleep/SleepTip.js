const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class SleepTip extends Model {}

  SleepTip.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    trimester: {
      type: DataTypes.INTEGER
    },
    title_am: {
      type: DataTypes.STRING(500)
    },
    title_om: {
      type: DataTypes.STRING(500)
    },
    title_en: {
      type: DataTypes.STRING(500)
    },
    title_so: {
      type: DataTypes.STRING(500)
    },
    description_am: {
      type: DataTypes.TEXT
    },
    description_om: {
      type: DataTypes.TEXT
    },
    description_en: {
      type: DataTypes.TEXT
    },
    description_so: {
      type: DataTypes.TEXT
    },
    illustration_url: {
      type: DataTypes.STRING(500)
    },
    week: {
      type: DataTypes.INTEGER
    },
    month: {
      type: DataTypes.INTEGER
    },
    type: {
      type: DataTypes.STRING(50),
      defaultValue: 'generic'
    },
    why_important_am: {
      type: DataTypes.TEXT
    },
    why_important_om: {
      type: DataTypes.TEXT
    },
    why_important_en: {
      type: DataTypes.TEXT
    },
    why_important_so: {
      type: DataTypes.TEXT
    },
    tips_am: {
      type: DataTypes.TEXT
    },
    tips_om: {
      type: DataTypes.TEXT
    },
    tips_en: {
      type: DataTypes.TEXT
    },
    tips_so: {
      type: DataTypes.TEXT
    },
    sections_json: {
      type: DataTypes.JSONB
    }
  }, {
    sequelize,
    modelName: 'SleepTip',
    tableName: 'sleep_tips',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return SleepTip;
};

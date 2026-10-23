const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class SleepWeek extends Model {}

  SleepWeek.init({
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
    sleeping_tips_en: {
      type: DataTypes.TEXT
    },
    sleeping_tips_am: {
      type: DataTypes.TEXT
    },
    sleeping_tips_om: {
      type: DataTypes.TEXT
    },
    sleeping_tips_so: {
      type: DataTypes.TEXT
    },
    is_published: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    sequelize,
    modelName: 'SleepWeek',
    tableName: 'sleep_weeks',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  return SleepWeek;
};

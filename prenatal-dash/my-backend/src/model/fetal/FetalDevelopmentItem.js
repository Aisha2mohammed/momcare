const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class FetalDevelopmentItem extends Model {}

  FetalDevelopmentItem.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    week_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    category: {
      type: DataTypes.STRING(100)
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
    display_order: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'FetalDevelopmentItem',
    tableName: 'fetal_development_items',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  FetalDevelopmentItem.associate = (models) => {
    FetalDevelopmentItem.belongsTo(models.FetalWeeklyContent, {
      foreignKey: 'week_id',
      as: 'weeklyContent'
    });
  };

  return FetalDevelopmentItem;
};

const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class CommunityRule extends Model {}

  CommunityRule.init({
    id: {
      type: DataTypes.STRING(50),
      defaultValue: 'default',
      primaryKey: true
    },
    content: {
      type: DataTypes.TEXT,
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'CommunityRule',
    tableName: 'community_rules',
    timestamps: true,
    createdAt: false,
    updatedAt: 'updated_at'
  });

  return CommunityRule;
};

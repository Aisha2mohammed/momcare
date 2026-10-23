const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class CommunityGroup extends Model {}

  CommunityGroup.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    trimester_group: {
      type: DataTypes.INTEGER
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'CommunityGroup',
    tableName: 'community_groups',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  CommunityGroup.associate = (models) => {
    CommunityGroup.hasMany(models.CommunityPost, {
      foreignKey: 'group_id',
      as: 'posts'
    });
  };

  return CommunityGroup;
};

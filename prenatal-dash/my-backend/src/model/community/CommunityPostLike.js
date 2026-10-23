const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class CommunityPostLike extends Model {}

  CommunityPostLike.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    post_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'CommunityPostLike',
    tableName: 'community_post_likes',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  CommunityPostLike.associate = (models) => {
    CommunityPostLike.belongsTo(models.CommunityPost, {
      foreignKey: 'post_id',
      as: 'post'
    });
    CommunityPostLike.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user'
    });
  };

  return CommunityPostLike;
};

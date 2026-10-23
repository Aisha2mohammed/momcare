const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class CommunityComment extends Model {}

  CommunityComment.init({
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
    },
    content: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    is_deleted: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  }, {
    sequelize,
    modelName: 'CommunityComment',
    tableName: 'community_comments',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  CommunityComment.associate = (models) => {
    CommunityComment.belongsTo(models.CommunityPost, {
      foreignKey: 'post_id',
      as: 'post'
    });
    CommunityComment.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'author'
    });
  };

  return CommunityComment;
};

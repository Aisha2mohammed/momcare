const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class CommunityPost extends Model {}

  CommunityPost.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    group_id: {
      type: DataTypes.UUID
    },
    content: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    is_anonymous: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    is_deleted: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    deleted_by_admin_id: {
      type: DataTypes.UUID
    },
    is_flagged: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    report_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0
    },
    report_reason: {
      type: DataTypes.TEXT
    }
  }, {
    sequelize,
    modelName: 'CommunityPost',
    tableName: 'community_posts',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  CommunityPost.associate = (models) => {
    CommunityPost.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'author'
    });
    CommunityPost.belongsTo(models.CommunityGroup, {
      foreignKey: 'group_id',
      as: 'group'
    });
    CommunityPost.belongsTo(models.User, {
      foreignKey: 'deleted_by_admin_id',
      as: 'deletedByAdmin'
    });
    CommunityPost.hasMany(models.CommunityComment, {
      foreignKey: 'post_id',
      as: 'comments'
    });
    CommunityPost.hasMany(models.CommunityPostLike, {
      foreignKey: 'post_id',
      as: 'likes'
    });
  };

  return CommunityPost;
};

const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class AuditLog extends Model {}

  AuditLog.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    admin_id: {
      type: DataTypes.UUID
    },
    action_type: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    target_table: {
      type: DataTypes.STRING(100)
    },
    target_id: {
      type: DataTypes.UUID
    },
    details_json: {
      type: DataTypes.JSONB
    }
  }, {
    sequelize,
    modelName: 'AuditLog',
    tableName: 'audit_logs',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  AuditLog.associate = (models) => {
    AuditLog.belongsTo(models.User, {
      foreignKey: 'admin_id',
      as: 'admin'
    });
  };

  return AuditLog;
};

const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class UserHealthLog extends Model {}

  UserHealthLog.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    mother_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    log_date: {
      type: DataTypes.DATEONLY,
      allowNull: false
    },
    weight_kg: {
      type: DataTypes.DECIMAL(5, 2)
    },
    mood: {
      type: DataTypes.STRING(50)
    },
    symptoms_json: {
      type: DataTypes.JSONB
    },
    symptom_severity: {
      type: DataTypes.INTEGER
    },
    blood_pressure_systolic: {
      type: DataTypes.INTEGER
    },
    blood_pressure_diastolic: {
      type: DataTypes.INTEGER
    },
    kick_count: {
      type: DataTypes.INTEGER
    },
    notes: {
      type: DataTypes.TEXT
    }
  }, {
    sequelize,
    modelName: 'UserHealthLog',
    tableName: 'user_health_logs',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  UserHealthLog.associate = (models) => {
    UserHealthLog.belongsTo(models.User, {
      foreignKey: 'mother_id',
      as: 'mother'
    });
  };

  return UserHealthLog;
};
